#!/usr/bin/env python3
"""IV-DIAGNOSTICO — auditoria READ-ONLY QVD dimensional e checkpoint Qlik 12.

Exige novamente integridade da fonte CID-10, incluindo os 36 CSVs RD.
Inspeciona somente header XML (nao decodifica corpo binario QVD),
SHA-256 do novo QVD e checkpoint parcial com os contadores do Qlik.
Nenhuma escrita.
"""
from __future__ import annotations

import csv
import hashlib
from pathlib import Path

from preflight_dim_diagnostico_cid10 import (
    CSV, QVD as REF_QVD, RD_QVD, EXPECTED_REF_SHA, sha256,
    source_manifest_gate, reference_gate, qvd_gate, qvd_header, rd_gate,
)

DIM_QVD = Path("TRANSFORMACAO/QVD/DIM_DIAGNOSTICO.qvd")
DIM_CHECKPOINT = Path("TRANSFORMACAO/QVD/_CHECKPOINT_DIM_DIAGNOSTICO.csv")
EXPECTED_DIM_FIELDS = [
    "%SK_DIAGNOSTICO",
    "COD_DIAGNOSTICO",
    "DESCRICAO_OFICIAL_DIAGNOSTICO",
    "CID10_REFERENCIA_COMPETENCIA",
    "CID10_FONTE_ARQUIVO",
]
EXPECTED_CKPT = {
    "stage": "TRANSFORMACAO_DIM_DIAGNOSTICO",
    "status": "PASS_PARTIAL_DIM_DIAGNOSTICO_ONLY",
    "reference_rows": "14230",
    "reference_fields": "4",
    "dimension_rows": "14230",
    "dimension_fields": "5",
    "distinct_codes": "14230",
    "unique_surrogate_keys": "14230",
    "invalid_dimension_rows": "0",
    "code_length_3": "2042",
    "code_length_4": "12188",
    "rd_rows": "566672",
    "rd_distinct_normalized_codes": "5480",
    "rd_unmatched": "0",
    "rd_invalid": "0",
    "reference_competence": "201912",
    "normalization_policy": "ASCII_TRAILING_SPACE_REMOVAL_ONLY",
    "reference_policy": "STATIC_DESCRIPTIVE_SUPERSET_NO_MONTHLY_VALIDITY",
    "t29_historical": "NOT_APPROVED",
    "facts_and_link_table": "NOT_STARTED",
}


def main() -> int:
    for path in (DIM_QVD, DIM_CHECKPOINT):
        if not path.is_file():
            raise RuntimeError(f"Dimensao/checkpoint ainda nao existe: {path}")

    # Repetir checks contra os TXT originais e 36 CSVs RD; o auditor
    # nao confia apenas nos valores produzidos pelo checkpoint Qlik.
    source_manifest_gate()
    cid_codes = reference_gate()
    qvd_gate()
    rd_gate(cid_codes)

    if sha256(CSV) != EXPECTED_REF_SHA:
        raise RuntimeError("Origem CID-10 alterada")

    rows, fields = qvd_header(DIM_QVD)
    if rows != 14230 or fields != EXPECTED_DIM_FIELDS:
        raise RuntimeError(
            f"Dimensao QVD: contagem/schema inesperados: {rows}/{fields}"
        )

    with DIM_CHECKPOINT.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        items = list(reader)
        if len(items) != 1 or reader.fieldnames is None:
            raise RuntimeError("Checkpoint de DIM_DIAGNOSTICO exige unica linha")
        row = items[0]
        if None in row or any(value is None for value in row.values()):
            raise RuntimeError("Checkpoint CSV malformado")
        if set(reader.fieldnames) != {"generated_at", *EXPECTED_CKPT}:
            raise RuntimeError("Checkpoint com campos inesperados")
        for key, required in EXPECTED_CKPT.items():
            if row.get(key) != required:
                raise RuntimeError(
                    f"Checkpoint diverge em {key}: {row.get(key)!r} != {required!r}"
                )

    if DIM_QVD.stat().st_mtime < REF_QVD.stat().st_mtime:
        raise RuntimeError("DIM_DIAGNOSTICO.qvd e anterior a REF_CID10.qvd")
    if DIM_CHECKPOINT.stat().st_mtime < DIM_QVD.stat().st_mtime - 5:
        raise RuntimeError("Checkpoint e anterior ao QVD dimensional")

    print("CID_REFERENCE_SHA256=" + sha256(CSV))
    print("DIM_DIAGNOSTICO_QVD_SHA256=" + sha256(DIM_QVD))
    print("DIM_DIAGNOSTICO_QVD_BYTES=" + str(DIM_QVD.stat().st_size))
    print("DIM_DIAGNOSTICO_CHECKPOINT_SHA256=" + sha256(DIM_CHECKPOINT))
    print("DIM_ROWS=14230")
    print("DIM_FIELDS=5")
    print("DIM_UNIQUE_SK_CHECKPOINT=14230")
    print("RD_ROWS=566672")
    print("RD_DISTINCT_NORMALIZED=5480")
    print("RD_UNMATCHED=0")
    print("CID_REFERENCE_COMPETENCE=201912")
    print("CID_POLICY=STATIC_DESCRIPTIVE_SUPERSET_NOT_MONTHLY_VALIDITY")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("FACTS_AND_LINK_TABLE=NOT_STARTED")
    print("LIMIT=QVD_BINARY_BODY_NOT_INDEPENDENTLY_DECODED")
    print("VERDICT=PASS_LOCAL_DIM_DIAGNOSTICO_QVD_HEADER_CHECKPOINT_RECONCILED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
