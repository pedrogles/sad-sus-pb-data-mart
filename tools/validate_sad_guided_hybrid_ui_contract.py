#!/usr/bin/env python3
"""Teste puro do contrato de interface guiada (SEM QlikView/COM/QVW).

Fonte semantica: docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md,
secoes 62.3 e 62.6. Hipotese de INTERFACE, nao aprovacao fisica.
Python 3.10+; stdlib somente. Nao le nem grava arquivos.
Executar: python tools/validate_sad_guided_hybrid_ui_contract.py
"""
from dataclasses import dataclass, replace
import unittest

YEARS = frozenset({2017, 2018, 2019})
MODES = frozenset({"MENSAL", "ANUAL", "EVOLUCAO"})
ANALYSES = frozenset({"RES", "LEI", "REL", "FLU"})

# Matriz V2 P5 literal: C compativel, R recorte, I isolamento, B bloqueio.
# Nunca converter R/I em C sem contrato e validacao fisica proprios.
P5 = {
    "ano": {"RES": "C", "LEI": "C", "REL": "C", "FLU": "C"},
    "competencia": {"RES": "C", "LEI": "C", "REL": "C", "FLU": "C"},
    "municipio_residencia": {"RES": "C", "LEI": "B", "REL": "B", "FLU": "C"},
    "municipio_servico": {"RES": "B", "LEI": "C", "REL": "C", "FLU": "C"},
    "estabelecimento": {"RES": "R", "LEI": "R", "REL": "R", "FLU": "R"},
    "procedimento": {"RES": "R", "LEI": "I", "REL": "B", "FLU": "R"},
    "diagnostico": {"RES": "R", "LEI": "I", "REL": "B", "FLU": "R"},
    "carater": {"RES": "R", "LEI": "I", "REL": "B", "FLU": "R"},
    "motivo_saida": {"RES": "R", "LEI": "I", "REL": "B", "FLU": "R"},
    "tipo_leito": {"RES": "I", "LEI": "R", "REL": "B", "FLU": "I"},
    "data_internacao": {"RES": "R", "LEI": "I", "REL": "B", "FLU": "R"},
    "data_saida": {"RES": "R", "LEI": "I", "REL": "B", "FLU": "R"},
}

@dataclass(frozen=True)
class Context:
    analysis: str = "RES"
    mode: str = "ANUAL"
    year: int = 2018
    month: int | None = None
    competence: int | None = None
    active_filters: frozenset[str] = frozenset()

def propose(context: Context, *, analysis: str | None = None,
            mode: str | None = None, year: int | None = None,
            month: int | None = None, competence: int | None = None) -> Context:
    """Retorna NOVO contexto validado; erro preserva o anterior (pre-dispatch)."""
    analysis = context.analysis if analysis is None else analysis
    mode = context.mode if mode is None else mode
    year = context.year if year is None else year
    if analysis not in ANALYSES or mode not in MODES or year not in YEARS:
        raise ValueError("analise/modo/ano fora do escopo do piloto")
    if mode == "MENSAL":
        if competence is not None:
            if not isinstance(competence, int):
                raise ValueError("competencia invalida")
            cy, cm = divmod(competence, 100)
            if cy != year or not 1 <= cm <= 12:
                raise ValueError("conflito ano x competencia")
            if month is not None and month != cm:
                raise ValueError("conflito mes x competencia")
            month = cm
        elif month is None:
            # Nunca herdar silenciosamente mes de outro modo/ano.
            raise ValueError("modo mensal exige competencia explicita")
        if not isinstance(month, int) or not 1 <= month <= 12:
            raise ValueError("mes invalido")
        return replace(context, analysis=analysis, mode=mode, year=year,
                       month=month, competence=year * 100 + month)
    if month is not None or competence is not None:
        raise ValueError("ANUAL/EVOLUCAO nao recebem mes no seletor guiado")
    return replace(context, analysis=analysis, mode=mode, year=year,
                   month=None, competence=None)

def with_filter(context: Context, filter_name: str) -> Context:
    if filter_name not in P5 or filter_name in ("ano", "competencia"):
        raise ValueError("filtro nao suportado neste piloto")
    return replace(context, active_filters=context.active_filters | {filter_name})

def indicator_availability(context: Context) -> tuple[str, tuple[str, ...]]:
    """Bloqueio conservador: nao ignora silenciosamente I/R nem mascara B."""
    classes = {f: P5[f][context.analysis] for f in context.active_filters}
    if any(v == "B" for v in classes.values()):
        return ("INAVAILABLE_B", tuple(sorted(k for k, v in classes.items() if v == "B")))
    if any(v == "R" for v in classes.values()):
        return ("INAVAILABLE_R_PENDING_CONTRACT", tuple(sorted(k for k, v in classes.items() if v == "R")))
    if any(v == "I" for v in classes.values()):
        return ("INAVAILABLE_I_PENDING_PHYSICAL_ISOLATION", tuple(sorted(k for k, v in classes.items() if v == "I")))
    return ("ELIGIBLE_FOR_DATA_VALIDATION", ())

class GuidedContractTests(unittest.TestCase):
    def test_annual_to_monthly(self):
        s = propose(Context(), mode="MENSAL", year=2018, month=1)
        self.assertEqual((s.year, s.month, s.competence), (2018, 1, 201801))

    def test_monthly_to_annual_discards_month(self):
        s = propose(Context(), mode="MENSAL", year=2018, month=1)
        self.assertEqual((propose(s, mode="ANUAL", year=2019).year,
                          propose(s, mode="ANUAL", year=2019).competence), (2019, None))

    def test_monthly_to_evolution_discards_month(self):
        s = propose(Context(), mode="MENSAL", year=2018, month=1)
        self.assertEqual(propose(s, mode="EVOLUCAO").month, None)

    def test_cross_year_competence_blocked_before_dispatch(self):
        before = Context(year=2019)
        with self.assertRaises(ValueError):
            propose(before, mode="MENSAL", year=2019, competence=201801)
        self.assertEqual(before, Context(year=2019))

    def test_monthly_requires_explicit_month(self):
        with self.assertRaises(ValueError):
            propose(Context(), mode="MENSAL")

    def test_invalid_month(self):
        for m in (0, 13):
            with self.subTest(m=m), self.assertRaises(ValueError):
                propose(Context(), mode="MENSAL", month=m)

    def test_invalid_year_and_mode(self):
        for kwargs in ({"year": 2020}, {"mode": "MULTI_ANUAL"}, {"analysis": "OTHER"}):
            with self.subTest(kwargs=kwargs), self.assertRaises(ValueError):
                propose(Context(), **kwargs)

    def test_nonmatching_month_and_competence(self):
        with self.assertRaises(ValueError):
            propose(Context(), mode="MENSAL", year=2018, month=2, competence=201801)

    def test_years_and_36_months(self):
        for y in YEARS:
            for m in range(1, 13):
                result = propose(Context(), mode="MENSAL", year=y, month=m)
                self.assertEqual(result.competence, y * 100 + m)

    def test_switch_analysis_preserves_filters_for_explanation(self):
        original = with_filter(Context(), "municipio_residencia")
        switched = propose(original, analysis="LEI")
        self.assertEqual(switched.active_filters, original.active_filters)
        self.assertEqual(indicator_availability(switched)[0], "INAVAILABLE_B")

    def test_p5_complete_literal_matrix(self):
        self.assertEqual(len(P5), 12)
        self.assertTrue(all(set(row) == ANALYSES for row in P5.values()))
        self.assertEqual(P5["municipio_residencia"], dict(RES="C", LEI="B", REL="B", FLU="C"))
        self.assertEqual(P5["tipo_leito"], dict(RES="I", LEI="R", REL="B", FLU="I"))

    def test_p5_C(self):
        s = with_filter(Context(analysis="RES"), "municipio_residencia")
        self.assertEqual(indicator_availability(s)[0], "ELIGIBLE_FOR_DATA_VALIDATION")

    def test_p5_B(self):
        s = with_filter(Context(analysis="REL"), "procedimento")
        self.assertEqual(indicator_availability(s)[0], "INAVAILABLE_B")

    def test_p5_R(self):
        s = with_filter(Context(analysis="RES"), "procedimento")
        self.assertEqual(indicator_availability(s)[0], "INAVAILABLE_R_PENDING_CONTRACT")

    def test_p5_I(self):
        s = with_filter(Context(analysis="LEI"), "procedimento")
        self.assertEqual(indicator_availability(s)[0], "INAVAILABLE_I_PENDING_PHYSICAL_ISOLATION")

    def test_simultaneous_block_wins(self):
        s = with_filter(with_filter(Context(analysis="REL"), "estabelecimento"), "procedimento")
        self.assertEqual(indicator_availability(s), ("INAVAILABLE_B", ("procedimento",)))

    def test_unknown_filter_fails_closed(self):
        with self.assertRaises(ValueError):
            with_filter(Context(), "qualquer_outro")

    def test_mode_change_preserves_non_temporal_filters(self):
        s = with_filter(Context(), "municipio_residencia")
        target = propose(s, mode="MENSAL", year=2017, month=6)
        self.assertEqual(target.active_filters, s.active_filters)

if __name__ == "__main__":
    unittest.main(verbosity=2)
