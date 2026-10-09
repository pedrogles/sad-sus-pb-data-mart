#!/usr/bin/env python3
"""C4/T29: perfil READ-ONLY dos codigos atingidos pela Portaria 298/2019.

A Portaria SAS/MS 298/2019 relaciona 77 -> 94 e 74 -> 95, mas seu
art. 8 condiciona efeitos a versoes DATASUS. Este script NAO atribui
vigencia, mapeamento por mes ou tipo normativo a nenhum codigo:
inspeciona apenas ocorrencia fisica CNES/LT na Paraiba, 2017-2019.
Nao baixa nem escreve arquivo, nao importa Hash128, nao cria QVD.
"""
from __future__ import annotations

import csv
from collections import Counter, defaultdict
from pathlib import Path

from preflight_dim_tipo_leito_snapshot_201909 import (
    BASE, EXPECTED_MONTHS, EXPECTED_SRC_FIELDS,
)

CODES_298 = ("74", "77", "94", "95")
CONTROLS = ("66", "70")
WATCH = (*CODES_298, *CONTROLS)
EXPECTED_YEAR_ROWS = {"2017": 12254, "2018": 11616, "2019": 11648}
EXPECTED_ROWS = 35518
EXPECTED_SOURCE_PAIR_COUNT = 57


def main() -> int:
    print("MODE=C4_T29_HISTORICAL_CHANGE_ACT_298_READ_ONLY_TRIAGE")
    print("OUTPUT_FILES_WRITTEN=0")
    paths = sorted(BASE.glob("LTPB*.csv"))
    if len(paths) != 36:
        raise RuntimeError(f"Esperados 36 arquivos LT, encontrados {len(paths)}")
    months: set[str] = set()
    yearly: Counter[str] = Counter()
    code_counts: Counter[str] = Counter()
    month_counts: dict[str, Counter[str]] = defaultdict(Counter)
    code_types: dict[str, Counter[str]] = defaultdict(Counter)
    pair_counts: Counter[tuple[str, str]] = Counter()
    rows = 0
    for path in paths:
        name = path.stem
        if (
            len(name) != 8 or not name.startswith("LTPB")
            or not name[4:].isascii() or not name[4:].isdecimal()
        ):
            raise RuntimeError(f"Nome LT inesperado: {path}")
        comp = "20" + name[4:]
        if comp not in EXPECTED_MONTHS or comp in months:
            raise RuntimeError(f"Competencia LT duplicada ou fora de escopo: {comp}")
        months.add(comp)
        with path.open("r", encoding="utf-8-sig", newline="") as fh:
            reader = csv.DictReader(fh, delimiter=";")
            if not reader.fieldnames or not EXPECTED_SRC_FIELDS.issubset(reader.fieldnames):
                raise RuntimeError(f"Schema LT incompleto: {path}")
            for lineno, rec in enumerate(reader, 2):
                if None in rec or any(value is None for value in rec.values()):
                    raise RuntimeError(f"CSV LT malformado: {path}:{lineno}")
                code = rec["CODLEITO"]
                raw_type = rec["TP_LEITO"]
                if (
                    rec["COMPETEN"] != comp or len(raw_type) != 2
                    or raw_type[0] not in "1234567" or raw_type[1] != " "
                    or len(code) != 2 or not code.isascii() or not code.isdecimal()
                ):
                    raise RuntimeError(f"Registro LT codigo/competencia invalido: {path}:{lineno}")
                typ = raw_type[0]
                pair_counts[(typ, code)] += 1
                yearly[comp[:4]] += 1
                rows += 1
                if code in WATCH:
                    code_counts[code] += 1
                    month_counts[code][comp] += 1
                    code_types[code][typ] += 1
    if months != EXPECTED_MONTHS or rows != EXPECTED_ROWS:
        raise RuntimeError(f"Esperadas 36 competencias/35518 linhas: {len(months)}/{rows}")
    if dict(yearly) != EXPECTED_YEAR_ROWS or len(pair_counts) != EXPECTED_SOURCE_PAIR_COUNT:
        raise RuntimeError(f"Perfil LT divergiu: anos={dict(yearly)} pares={len(pair_counts)}")
    if pair_counts[("3", "66")] != 1480 or pair_counts[("7", "70")] != 5:
        raise RuntimeError("Pares-controle PB 3/66 e 7/70 divergentes")
    print("LT_FILES=36")
    print("LT_ROWS=35518")
    print("LT_PAIRS=57")
    print("ACT_298_TRANSITIONS=77_TO_94;74_TO_95")
    print("ACT_298_EFFECTIVE_MONTH=NOT_ESTABLISHED")
    print("PROFILED_298_CODES=" + ",".join(CODES_298))
    for code in WATCH:
        month_profile = sorted(month_counts[code].items())
        print(f"CODE_{code}_OBSERVED_ROWS={code_counts[code]}")
        print(f"CODE_{code}_OBSERVED_RAW_TYPES=" + repr(sorted(code_types[code].items())))
        print(f"CODE_{code}_OBSERVED_MONTHS=" + repr(month_profile))
    print("PB_PAIR_3_66_ROWS=" + str(pair_counts[("3", "66")]))
    print("PB_PAIR_7_70_ROWS=" + str(pair_counts[("7", "70")]))
    print("CODE_PRESENCE_IS_NOT_LEGAL_EFFECTIVE_VALIDITY=True")
    print("NO_CODE_RECLASSIFICATION_PERFORMED=True")
    print("NO_NORMATIVE_HISTORICAL_LABELS_ASSIGNED=True")
    print("NO_QVD_OR_DIM_CREATED=True")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("VERDICT=PASS_OBSERVED_LT_CODE_CHANGE_TRIAGE_ONLY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
