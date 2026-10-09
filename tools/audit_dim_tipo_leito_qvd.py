#!/usr/bin/env python3
"""Auditoria READ-ONLY da oitava dimensão (QVD header + checkpoint).

Executar SOMENTE após reload local de TRANSFORMACAO/TRANSF.qvw.
A validação da fonte LT/legenda é reexecutada com o preflight A1.
Lê header XML do QVD e checkpoint; não decodifica linhas binárias QVD.
O atributo TP_LEITO_TEXTO_STAGING representa o valor QVD, não o ASCII bruto
com espaço final preservado exclusivamente nos CSVs originais e auditado no A1.
Não escreve QVD, CSV ou qualquer outro arquivo.
"""
from __future__ import annotations

import csv
from pathlib import Path

from preflight_dim_tipo_leito_contrato_a import main as grain_preflight
from preflight_dim_tipo_leito_snapshot_201909 import REF_QVD, sha256
from preflight_dim_diagnostico_cid10 import qvd_header

DIM_QVD = Path("TRANSFORMACAO/QVD/DIM_TIPO_LEITO.qvd")
CHECKPOINT = Path("TRANSFORMACAO/QVD/_CHECKPOINT_DIM_TIPO_LEITO.csv")

EXPECTED_FIELDS = [
    "%SK_TIPO_LEITO",
    "COD_TIPO_LEITO",
    "TP_LEITO_TEXTO_STAGING",
    "COD_LEITO",
    "COMPETENCIA_OBSERVACAO_LEITO",
    "DESCRICAO_TIPO_LEITO",
    "DESCRICAO_ESPECIALIDADE_LEITO",
    "COMPETENCIA_LEGENDA_LEITO",
    "STATUS_DESCRICAO_LEITO",
    "LEITO_TEM_LEGENDA_DATADA",
]

EXPECTED_CHECKPOINT = {
    "stage": "TRANSFORMACAO_DIM_TIPO_LEITO",
    "status": "PASS_PARTIAL_DIM_TIPO_LEITO_ONLY",
    "dimension_rows": "2021",
    "unique_surrogate_keys": "2021",
    "distinct_competences": "36",
    "distinct_source_pairs": "57",
    "distinct_source_pairs_month": "2021",
    "lt_rows": "35518",
    "lt_unmatched": "0",
    "dated_201909_descriptions": "56",
    "historical_descriptions_unverified": "1965",
    "no_description_denominator": "PAIR_MONTH_NOT_BED_COUNT",
    "descriptive_legend_competence": "201909_ONLY",
    "descriptive_policy": "NULL_NO_HISTORICAL_LABEL_BACKFILL",
    "t29_historical": "NOT_APPROVED",
    "facts_and_link_table": "NOT_STARTED",
}


def main() -> int:
    # Faz a validação integral dos 36 CSVs LT e do snapshot físico de 201909,
    # reaproveitando o gate A1, sem Hash128 ou escrita.
    if grain_preflight() != 0:
        raise RuntimeError("Preflight A1 de grão mensal não passou")
    for path in (DIM_QVD, CHECKPOINT, REF_QVD):
        if not path.is_file():
            raise RuntimeError(f"Arquivo esperado ausente: {path}")
    dim_rows, fields = qvd_header(DIM_QVD)
    if dim_rows != 2021 or fields != EXPECTED_FIELDS:
        raise RuntimeError(f"Header DIM_TIPO_LEITO divergiu: {dim_rows}, {fields!r}")

    with CHECKPOINT.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file, delimiter=";")
        rows = list(reader)
        expected_columns = {"generated_at", *EXPECTED_CHECKPOINT}
        if reader.fieldnames is None or set(reader.fieldnames) != expected_columns:
            raise RuntimeError(f"Schema de checkpoint divergente: {reader.fieldnames}")
        if len(reader.fieldnames) != len(set(reader.fieldnames)):
            raise RuntimeError("Checkpoint com campos duplicados")
        if len(rows) != 1 or None in rows[0] or any(v is None for v in rows[0].values()):
            raise RuntimeError("Checkpoint deve ter uma linha completa")
        if not rows[0].get("generated_at"):
            raise RuntimeError("Checkpoint sem timestamp")
        for name, expected in EXPECTED_CHECKPOINT.items():
            if rows[0].get(name) != expected:
                raise RuntimeError(
                    f"Checkpoint {name}: {rows[0].get(name)!r} != {expected!r}"
                )

    if DIM_QVD.stat().st_mtime < REF_QVD.stat().st_mtime:
        raise RuntimeError("Dimensão mais antiga que a referência de 201909")
    if CHECKPOINT.stat().st_mtime < DIM_QVD.stat().st_mtime - 5:
        raise RuntimeError("Checkpoint anterior ao QVD recém-gerado")

    print("MODE=IV_TIPO_LEITO_QVD_HEADER_CHECKPOINT_READ_ONLY_AUDIT")
    print("DIM_QVD_SHA256=" + sha256(DIM_QVD))
    print("DIM_QVD_BYTES=" + str(DIM_QVD.stat().st_size))
    print("DIM_CHECKPOINT_SHA256=" + sha256(CHECKPOINT))
    print("DIM_CHECKPOINT_BYTES=" + str(CHECKPOINT.stat().st_size))
    print("DIM_ROWS=2021")
    print("DIM_FIELDS=10")
    print("DIM_UNIQUE_SK_CHECKPOINT=2021")
    print("LT_ROWS=35518")
    print("LT_UNMATCHED=0")
    print("PAIRS_MONTH_UNVERIFIED=1965")
    print("PAIRS_MONTH_TOTAL=2021")
    print("PAIRS_MONTH_UNVERIFIED_PERCENT=97.2")
    print("DENOMINATOR=PAIRS_MONTH_NOT_NUMBER_OF_BEDS")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("LIMIT=QVD_BINARY_BODY_NOT_INDEPENDENTLY_DECODED")
    print("VERDICT=PASS_LOCAL_DIM_TIPO_LEITO_QVD_HEADER_CHECKPOINT_RECONCILED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
