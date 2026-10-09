#!/usr/bin/env python3
"""Fase V — controle READ-ONLY de medidas candidatas da FATO_INTERNACAO.

Executar na raiz do projeto:
  .\.venv\Scripts\python.exe tools\preflight_fato_internacao_medidas.py --root .

Leitura apenas dos 36 CSVs SIH/RD historicos em BASE/CONVERTIDA/RD.
Nao cria QVD, QVW, CSV, logs de controle ou indicadores derivados.
Os totais monetarios sao calculados com Decimal a partir do texto do CSV;
a equivalencia numerica de VAL_TOT/DIAS_PERM no QlikView 12 AINDA EXIGE
uma prova fisica separada.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import Counter
from decimal import Decimal, InvalidOperation
from pathlib import Path

from preflight_fase_v_fato_internacao import RD_FIELDS

RD_NAME = re.compile(r"RDPB(17|18|19)(0[1-9]|1[0-2])\.csv\Z", re.IGNORECASE)
EXPECTED_FILES = 36
EXPECTED_ROWS = 566672
EXPECTED_BY_YEAR = {"2017": 187726, "2018": 187293, "2019": 191653}
EXPECTED_IDENT1 = 555089
EXPECTED_IDENT5 = 11583
EXPECTED_EXTERNAL = 5202
EXPECTED_MONTHLY_AIH_EXTRA = 880
EXPECTED_MONTHS = {f"{y}{m:02d}" for y in (2017, 2018, 2019) for m in range(1, 13)}


def decimal_nonnegative(value: str, label: str, path: Path, lineno: int) -> Decimal:
    try:
        parsed = Decimal(value.strip())
    except (InvalidOperation, ValueError) as exc:
        raise ValueError(f"{path.name}:{lineno} {label} nao numerico") from exc
    if not parsed.is_finite() or parsed < 0:
        raise ValueError(f"{path.name}:{lineno} {label} nao finito ou negativo")
    return parsed


def read_source(root: Path) -> dict:
    files = sorted((root / "BASE" / "CONVERTIDA" / "RD").glob("RDPB*.csv"))
    if len(files) != EXPECTED_FILES:
        raise ValueError(f"Expected {EXPECTED_FILES} RD CSV files; found {len(files)}")
    stats = Counter()
    year_rows = Counter()
    year_new = Counter()
    year_cont = Counter()
    year_deaths = Counter()
    year_days = {y: Decimal(0) for y in EXPECTED_BY_YEAR}
    year_values = {y: Decimal(0) for y in EXPECTED_BY_YEAR}
    months = set()
    monthly_aih = set()
    for path in files:
        name = RD_NAME.fullmatch(path.name)
        if name is None:
            raise ValueError(f"Nome nao reconhecido: {path.name}")
        competence = "20" + name.group(1) + name.group(2)
        if competence in months:
            raise ValueError(f"Competencia repetida: {competence}")
        months.add(competence)
        year = competence[:4]
        with path.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream, delimiter=";")
            fields = reader.fieldnames
            if fields is None or any(c not in fields for c in RD_FIELDS):
                raise ValueError(f"Schema insuficiente em {path.name}")
            if len(fields) != len(set(fields)):
                raise ValueError(f"Colunas repetidas em {path.name}")
            for lineno, row in enumerate(reader, 2):
                if None in row or any(row.get(c) is None for c in RD_FIELDS):
                    raise ValueError(f"Linha malformada: {path.name}:{lineno}")
                if row["ANO_CMPT"].strip() != year or row["MES_CMPT"].strip().zfill(2) != competence[4:]:
                    raise ValueError(f"Competencia divergente: {path.name}:{lineno}")
                ident = row["IDENT"].strip()
                if ident not in ("1", "5"):
                    raise ValueError(f"IDENT inesperado: {path.name}:{lineno}")
                death = row["MORTE"].strip()
                if death not in ("0", "1"):
                    raise ValueError(f"MORTE inesperado: {path.name}:{lineno}")
                days = decimal_nonnegative(row["DIAS_PERM"], "DIAS_PERM", path, lineno)
                value = decimal_nonnegative(row["VAL_TOT"], "VAL_TOT", path, lineno)
                stats["rows"] += 1
                year_rows[year] += 1
                stats["ident" + ident] += 1
                if ident == "1":
                    year_new[year] += 1
                else:
                    year_cont[year] += 1
                year_days[year] += days
                year_values[year] += value
                if death == "1":
                    stats["deaths"] += 1
                    year_deaths[year] += 1
                if not row["MUNIC_RES"].strip().startswith("25"):
                    stats["external"] += 1
                ai = (competence, row["N_AIH"])
                if ai in monthly_aih:
                    stats["monthly_aih_extra"] += 1
                else:
                    monthly_aih.add(ai)

    if months != EXPECTED_MONTHS:
        raise ValueError("Cobertura de competencias nao corresponde a 36 meses 201701-201912")
    if (stats["rows"] != EXPECTED_ROWS or
        dict(year_rows) != EXPECTED_BY_YEAR or
        stats["ident1"] != EXPECTED_IDENT1 or
        stats["ident5"] != EXPECTED_IDENT5 or
        stats["external"] != EXPECTED_EXTERNAL or
        stats["monthly_aih_extra"] != EXPECTED_MONTHLY_AIH_EXTRA):
        raise ValueError("Contagens contrariam contrato RD validado no Boundary 3")
    return {
        "stats": stats,
        "rows_by_year": year_rows,
        "new_by_year": year_new,
        "continuations_by_year": year_cont,
        "deaths_by_year": year_deaths,
        "days_by_year": year_days,
        "values_by_year": year_values,
    }


def main() -> int:
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--root", type=Path, default=Path.cwd())
    args = cli.parse_args()
    print("MODE=PHASE_V_RD_MEASURES_SOURCE_READ_ONLY")
    print("OUTPUT_FILES_WRITTEN=0")
    print("QVD_BINARY_BODY_INSPECTED=False")
    print("QLIK_MEASURES_TEST_EXECUTED=False")
    result = read_source(args.root.resolve())
    s = result["stats"]
    print(f"RD_FILES={EXPECTED_FILES} RD_COMPETENCES={len(EXPECTED_MONTHS)} RD_ROWS={s['rows']}")
    print(f"QTD_REGISTRO_AIH_TOTAL={s['rows']}")
    print(f"QTD_INTERNACAO_TOTAL={s['ident1']}")
    print(f"IDENT5_ROWS={s['ident5']}")
    print(f"RD_RESIDENCE_EXTERNAL_ROWS={s['external']}")
    print(f"N_AIH_MONTHLY_EXTRA_ROWS={s['monthly_aih_extra']}")
    print(f"INDICADOR_OBITO_TOTAL={s['deaths']}")
    for year in sorted(EXPECTED_BY_YEAR):
        print(
            f"YEAR={year} ROWS={result['rows_by_year'][year]}"
            f" NEW_INTERNS={result['new_by_year'][year]}"
            f" CONTINUATIONS={result['continuations_by_year'][year]}"
            f" DEATH_FLAGS={result['deaths_by_year'][year]}"
            f" DIAS_PERMANENCIA_TOTAL={result['days_by_year'][year]}"
            f" VALOR_TOTAL={result['values_by_year'][year]}"
        )
    print(f"DIAS_PERMANENCIA_TOTAL={sum(result['days_by_year'].values(), Decimal(0))}")
    print(f"VALOR_TOTAL={sum(result['values_by_year'].values(), Decimal(0))}")
    print("VERDICT=PASS_RD_MEASURES_SOURCE_ONLY_QLIK_RECONCILIATION_PENDING")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, UnicodeError, csv.Error) as exc:
        print(f"VERDICT=FAIL_CLOSED {type(exc).__name__}: {exc}", file=sys.stderr)
        raise SystemExit(1)
