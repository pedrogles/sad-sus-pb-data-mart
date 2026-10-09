#!/usr/bin/env python3
"""DIM_TIPO_LEITO — validação READ-ONLY da hipótese temporal A.

Usa os 36 CSVs CNES/LT reais (COMPETEN) e a referência 201909 apenas
como identificador de pares, sem carregar descrições retrospectivas.
Valida grão candidato TP_LEITO + CODLEITO + COMPETEN e a unicidade
proposta ao fato CNES + COMPETEN + CODLEITO. NÃO gera dimensão, SK
Hash128, arquivo, QVD, label histórico, alteração do Boundary 7 ou T29.
"""
from __future__ import annotations

import csv
from collections import Counter, defaultdict

from preflight_dim_tipo_leito_snapshot_201909 import (
    BASE,
    EXPECTED_MONTHS,
    EXPECTED_SRC_FIELDS,
    check_snapshot,
    check_qvd_and_checkpoint,
)

EXPECTED_LT_ROWS = 35518
EXPECTED_ANNUAL = {"2017": 12254, "2018": 11616, "2019": 11648}
EXPECTED_PAIR_COUNT = 57
EXPECTED_SOURCE_PAIRS_BY_MONTH = {
    month: 57 if month in {"201801", "201802", "201803", "201804", "201805"} else 56
    for month in EXPECTED_MONTHS
}
EXPECTED_NATURAL_DIM_KEYS = sum(EXPECTED_SOURCE_PAIRS_BY_MONTH.values())  # 2021
EXPECTED_CODE_70_MONTHS = {"201801", "201802", "201803", "201804", "201805"}


def main() -> int:
    print("MODE=IV_TIPO_LEITO_OPTION_A_READ_ONLY_GRAIN_PREFLIGHT")
    print("OUTPUT_FILES_WRITTEN=0")
    print("DIM_TIPO_LEITO_QVD_GENERATED=False")
    print("QLIK_HASH128_EXECUTED=False")

    # Fase III-C4.3: catálogo e QVD como snapshot datado, nunca vigência.
    snapshot_pairs = check_snapshot()
    check_qvd_and_checkpoint()

    files = sorted(BASE.glob("LTPB*.csv"))
    if len(files) != 36:
        raise RuntimeError(f"Esperados 36 arquivos CNES/LT, encontrados {len(files)}")

    dimensions: set[tuple[str, str, str]] = set()
    source_pairs: set[tuple[str, str]] = set()
    month_pairs: dict[str, set[tuple[str, str]]] = defaultdict(set)
    raw_pairs_by_normalized: dict[tuple[str, str], set[tuple[str, str]]] = defaultdict(set)
    fact_keys: set[tuple[str, str, str]] = set()
    years: Counter[str] = Counter()
    months: set[str] = set()
    observed_code70_months: set[str] = set()
    counts = Counter()
    rows = 0
    duplicate_fact_keys = 0
    source_invalid = 0
    for path in files:
        stem = path.stem
        if (
            len(stem) != 8 or not stem.startswith("LTPB")
            or not stem[4:].isascii() or not stem[4:].isdecimal()
        ):
            raise RuntimeError(f"Nome de arquivo LT inesperado: {path}")
        competence = "20" + stem[4:]
        if competence in months or competence not in EXPECTED_MONTHS:
            raise RuntimeError(f"Competência LT inesperada: {competence}")
        months.add(competence)
        file_rows = 0
        with path.open("r", newline="", encoding="utf-8-sig") as stream:
            reader = csv.DictReader(stream, delimiter=";")
            if not reader.fieldnames or not EXPECTED_SRC_FIELDS.issubset(reader.fieldnames):
                raise RuntimeError(f"Schema LT incompleto: {path}")
            for lineno, record in enumerate(reader, 2):
                if None in record or any(v is None for v in record.values()):
                    raise RuntimeError(f"Registro LT malformado: {path}:{lineno}")
                raw_type = record["TP_LEITO"]
                code = record["CODLEITO"]
                actual_competence = record["COMPETEN"]
                establishment = record["CNES"]
                # O tipo foi comprovado em "N " (espaço final ASCII), não "N".
                if (
                    len(raw_type) != 2 or raw_type[0] not in "1234567" or raw_type[1] != " "
                    or len(code) != 2 or not code.isascii() or not code.isdecimal()
                    or actual_competence != competence or not establishment.strip()
                ):
                    source_invalid += 1
                    raise RuntimeError(
                        f"Chave LT inválida: {path}:{lineno} "
                        f"{raw_type!r}/{code!r}/{actual_competence!r}/{establishment!r}"
                    )

                normalized_type = raw_type.rstrip(" ")  # apenas padding ASCII
                pair = (normalized_type, code)
                if pair not in snapshot_pairs:
                    raise RuntimeError(
                        f"Par LT ausente no snapshot datado: {path}:{lineno}: {pair!r}"
                    )
                raw_pairs_by_normalized[pair].add((raw_type, code))
                source_pairs.add(pair)
                month_pairs[competence].add(pair)
                dimensions.add((normalized_type, code, competence))

                # Verificação de cardinalidade proposta para a futura FATO,
                # SEM criar fato nem atribuir SK/descrição.
                fact_key = (establishment, competence, code)
                if fact_key in fact_keys:
                    duplicate_fact_keys += 1
                else:
                    fact_keys.add(fact_key)

                if pair == ("7", "70"):
                    observed_code70_months.add(competence)
                    counts["code70_rows"] += 1
                if pair == ("3", "66"):
                    counts["pair3_66_rows"] += 1

                years[competence[:4]] += 1
                rows += 1
                file_rows += 1
        if file_rows <= 0:
            raise RuntimeError(f"Arquivo LT vazio: {path}")

    if months != EXPECTED_MONTHS or rows != EXPECTED_LT_ROWS:
        raise RuntimeError(f"LT divergiu: {len(months)} competências / {rows} registros")
    if dict(years) != EXPECTED_ANNUAL:
        raise RuntimeError(f"Totais anuais LT divergentes: {dict(years)}")
    if len(source_pairs) != EXPECTED_PAIR_COUNT:
        raise RuntimeError(f"Pares LT divergentes: {len(source_pairs)}")
    if {
        k: len(v) for k, v in month_pairs.items()
    } != EXPECTED_SOURCE_PAIRS_BY_MONTH:
        raise RuntimeError("Contagem mensal de pares LT diverge de C4.1")
    if len(dimensions) != EXPECTED_NATURAL_DIM_KEYS:
        raise RuntimeError(f"Chaves naturais mensais divergentes: {len(dimensions)}")
    if any(len(pairs) != 1 for pairs in raw_pairs_by_normalized.values()):
        raise RuntimeError("RTrim ASCII produziu colisão ou múltiplos formatos físicos")
    if duplicate_fact_keys:
        raise RuntimeError(
            f"Chave de grão de fato CNES+COMPETEN+CODLEITO duplicada: {duplicate_fact_keys}"
        )
    if len(fact_keys) != EXPECTED_LT_ROWS:
        raise RuntimeError("Cobertura fact-to-dim inesperada")
    if (
        observed_code70_months != EXPECTED_CODE_70_MONTHS
        or counts["code70_rows"] != 5
        or counts["pair3_66_rows"] != 1480
    ):
        raise RuntimeError(f"Pares excepcionais divergentes: {dict(counts)}")

    current_month_pairs = month_pairs["201909"]
    if not current_month_pairs.issubset(snapshot_pairs):
        raise RuntimeError("Par(es) 201909 sem referência contemporânea")
    labels_supported = len(current_month_pairs)
    labels_unknown = len(dimensions) - labels_supported
    if labels_supported != 56 or labels_unknown != 1965:
        raise RuntimeError(
            f"Partição de atributos descritivos divergente: {labels_supported}/{labels_unknown}"
        )

    print("LT_FILES=36")
    print("LT_COMPETENCES=36")
    print("LT_ROWS=35518")
    print("LT_YEARS=" + repr(sorted(years.items())))
    print("PAIRS_TOTAL_DISTINCT=57")
    print("PAIRS_PER_COMPETENCE=" + repr(sorted(
        (month, len(pairs)) for month, pairs in month_pairs.items()
    )))
    print("TEMPORAL_NATURAL_KEY=(TP_LEITO_RTRIM_ASCII,CODLEITO_TEXT,COMPETEN)")
    print("TEMPORAL_NATURAL_DIM_KEYS=" + str(len(dimensions)))
    print("TEMPORAL_NATURAL_KEY_DUPLICATES=0")
    print("TYPE_ASCII_RTRIM_COLLISIONS=0")
    print("FACT_CANDIDATE_KEY=(CNES,COMPETEN,CODLEITO)")
    print("FACT_CANDIDATE_KEY_DUPLICATES=" + str(duplicate_fact_keys))
    print("FACT_ROWS_WITH_CANDIDATE_DIM_KEY=" + str(len(fact_keys)))
    print("LT_PAIR_3_66_ROWS=" + str(counts["pair3_66_rows"]))
    print("LT_CODE_7_70_ROWS=" + str(counts["code70_rows"]))
    print("LT_CODE_7_70_MONTHS=" + ",".join(sorted(observed_code70_months)))
    print("REFERENCE_201909_LABEL_ELIGIBLE_NATURAL_KEYS=" + str(labels_supported))
    print("HISTORICAL_LABEL_UNVERIFIED_NATURAL_KEYS=" + str(labels_unknown))
    print("LEGEND_201909_USED_AS_HISTORICAL_LABEL_JOIN=False")
    print("CANDIDATE_KEY_IS_NOT_AN_APPROVED_HASH128_IMPLEMENTATION=True")
    print("COMPETENCIA_REFERENCIA_SEMANTICS=DECISION_PENDING")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("FACT_AND_DIM_QVD_GENERATED=False")
    print("VERDICT=PASS_OPTION_A_TEMPORAL_GRAIN_PREFLIGHT_ONLY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
