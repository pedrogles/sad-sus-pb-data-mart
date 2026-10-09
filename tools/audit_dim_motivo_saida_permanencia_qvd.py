#!/usr/bin/env python3
"""Auditoria read-only QVD/checkpoint da sétima dimensão SIH (MOTIVO).

Revalida os CSVs normativos C1, o manifesto com SHA, 36 CSV RD e os
headers QVDs da extração. Inspeciona só header XML do QVD dimensional
e checkpoint parcial. Não decodifica o corpo binário do QVD nem escreve.
"""
from __future__ import annotations

import csv
from pathlib import Path

from preflight_dim_motivo_saida_permanencia import (
    CSV, QVD as REF_QVD,
    check_manifest, check_reference, check_staging, check_rd,
    qvd_header, sha256,
)

DIM_QVD = Path("TRANSFORMACAO/QVD/DIM_MOTIVO_SAIDA_PERMANENCIA.qvd")
DIM_CHECKPOINT = Path("TRANSFORMACAO/QVD/_CHECKPOINT_DIM_MOTIVO_SAIDA_PERMANENCIA.csv")
EXPECTED_C1_CSV_SHA256 = "dea572f8b04acd06ea214711ac1c56d5f494e2fa7e0713883881c65fa850bdac"
EXPECTED_DIM_FIELDS = [
    "%SK_MOTIVO_SAIDA",
    "COD_MOTIVO_SAIDA_FONTE",
    "COD_MOTIVO_SAIDA_NORMATIVO",
    "DESCRICAO_OFICIAL_MOTIVO_SAIDA",
    "CATEGORIA_ENCERRAMENTO",
    "MOTIVO_FONTE_OFICIAL_BASE",
    "MOTIVO_FONTE_OFICIAL_ATUALIZACAO",
]
EXPECTED_CHECKPOINT = {
    "stage": "TRANSFORMACAO_DIM_MOTIVO_SAIDA_PERMANENCIA",
    "status": "PASS_PARTIAL_DIM_MOTIVO_SAIDA_ONLY",
    "reference_rows": "28",
    "reference_fields": "7",
    "reference_distinct_codes": "28",
    "reference_distinct_normative": "28",
    "reference_distinct_groups": "6",
    "reference_mapping_24": "1",
    "dimension_rows": "28",
    "dimension_fields": "7",
    "unique_surrogate_keys": "28",
    "invalid_dimension_rows": "0",
    "rd_rows": "566672",
    "rd_distinct_codes": "26",
    "rd_unmatched": "0",
    "rd_invalid": "0",
    "rd_code_24_rows": "6",
    "rd_frequency_groups": "26",
    "rd_frequency_mismatches": "0",
    "domain_policy": "FULL_NORMATIVE_28_C1",
    "code_policy": "COBRANCA_2_DIGIT_NORMATIVE_DOTTED",
    "historical_individual_validity": "NO_MONTHLY_CODE_VALIDITY_ESTABLISHED",
    "t29_historical": "NOT_APPROVED",
    "facts_and_link_table": "NOT_STARTED",
}


def main() -> int:
    for path in (DIM_QVD, DIM_CHECKPOINT):
        if not path.is_file():
            raise RuntimeError(f"QVD/checkpoint da sétima DIM ausente: {path}")

    sha = check_manifest()
    if sha != EXPECTED_C1_CSV_SHA256 or sha256(CSV) != EXPECTED_C1_CSV_SHA256:
        raise RuntimeError("Referência corrigida de 28 códigos mudou de SHA-256")
    codes = check_reference()
    check_staging()
    check_rd(codes)

    qvd_rows, fields = qvd_header(DIM_QVD)
    if qvd_rows != 28 or fields != EXPECTED_DIM_FIELDS:
        raise RuntimeError(f"QVD DIM_MOTIVO inválido: {qvd_rows} linhas, campos {fields}")

    with DIM_CHECKPOINT.open("r", encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh, delimiter=";")
        items = list(reader)
        if reader.fieldnames is None or len(items) != 1:
            raise RuntimeError("Checkpoint DIM exige exatamente uma linha")
        if len(reader.fieldnames) != len(set(reader.fieldnames)):
            raise RuntimeError("Cabeçalho do checkpoint contém nomes duplicados")
        if set(reader.fieldnames) != {"generated_at", *EXPECTED_CHECKPOINT}:
            raise RuntimeError(f"Colunas inesperadas no checkpoint: {reader.fieldnames}")
        row = items[0]
        if None in row or any(v is None for v in row.values()):
            raise RuntimeError("Checkpoint DIM contém estrutura malformada")
        if not row.get("generated_at"):
            raise RuntimeError("Checkpoint DIM sem horário")
        for key, expected in EXPECTED_CHECKPOINT.items():
            if row.get(key) != expected:
                raise RuntimeError(f"Checkpoint diverge {key}: {row.get(key)!r} != {expected!r}")

    if DIM_QVD.stat().st_mtime < REF_QVD.stat().st_mtime:
        raise RuntimeError("DIM_MOTIVO mais antiga que referência QVD C1")
    if DIM_CHECKPOINT.stat().st_mtime < DIM_QVD.stat().st_mtime - 5:
        raise RuntimeError("Checkpoint DIM_MOTIVO anterior ao QVD")

    print("MODE=IV_DIM_MOTIVO_QVD_CHECKPOINT_READ_ONLY_AUDIT")
    print("NORMATIVE_C1_CSV_SHA256=" + sha)
    print("DIM_MOTIVO_QVD_SHA256=" + sha256(DIM_QVD))
    print("DIM_MOTIVO_QVD_BYTES=" + str(DIM_QVD.stat().st_size))
    print("DIM_MOTIVO_CHECKPOINT_SHA256=" + sha256(DIM_CHECKPOINT))
    print("DIM_MOTIVO_CHECKPOINT_BYTES=" + str(DIM_CHECKPOINT.stat().st_size))
    print("DIM_ROWS=28")
    print("DIM_FIELDS=7")
    print("DIM_UNIQUE_SK_CHECKPOINT=28")
    print("NORMATIVE_CODE_24=2.4")
    print("RD_ROWS=566672")
    print("RD_DISTINCT_CODES=26")
    print("RD_CODE_24_ROWS=6")
    print("RD_FREQUENCY_MISMATCHES=0")
    print("RD_UNMATCHED=0")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("FACTS_AND_LINK_TABLE=NOT_STARTED")
    print("LIMIT=QVD_BINARY_BODY_NOT_INDEPENDENTLY_DECODED")
    print("VERDICT=PASS_LOCAL_DIM_MOTIVO_QVD_HEADER_CHECKPOINT_RECONCILED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
