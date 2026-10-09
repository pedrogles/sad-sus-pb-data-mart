#!/usr/bin/env python3
"""IV-CARATER_ATENDIMENTO — auditoria READ-ONLY do QVD e checkpoint Qlik 12.

Reexecuta preflight físico C1 (CSV/manifesto SHA, labels, 36 RD, QVDs
da EXTRAÇÃO por cabeçalho). Confere apenas XML do header do novo QVD,
hash de seus bytes, checkpoint, política de domínio, distribuição RD
observada e frescor. NÃO decodifica as linhas binárias do QVD.
"""
from __future__ import annotations

import csv
from pathlib import Path

from preflight_dim_carater_atendimento import (
    QVD as REF_QVD,
    check_manifest,
    check_reference,
    check_existing_qvd,
    check_rd,
    qvd_header,
    sha256,
)

DIM_QVD = Path("TRANSFORMACAO/QVD/DIM_CARATER_ATENDIMENTO.qvd")
DIM_CHECKPOINT = Path("TRANSFORMACAO/QVD/_CHECKPOINT_DIM_CARATER_ATENDIMENTO.csv")
EXPECTED_DIM_FIELDS = [
    "%SK_CARATER_ATENDIMENTO",
    "COD_CARATER_ATENDIMENTO",
    "DESCRICAO_OFICIAL_CARATER_ATENDIMENTO",
    "CARATER_ATENDIMENTO_FONTE_OFICIAL",
]
EXPECTED_CHECKPOINT = {
    "stage": "TRANSFORMACAO_DIM_CARATER_ATENDIMENTO",
    "status": "PASS_PARTIAL_DIM_CARATER_ATENDIMENTO_ONLY",
    "reference_rows": "6",
    "reference_fields": "4",
    "dimension_rows": "6",
    "dimension_fields": "4",
    "reference_distinct_codes": "6",
    "unique_surrogate_keys": "6",
    "invalid_dimension_rows": "0",
    "rd_rows": "566672",
    "rd_distinct_codes": "4",
    "rd_unmatched": "0",
    "rd_invalid": "0",
    "rd_01": "80167",
    "rd_02": "470512",
    "rd_03": "0",
    "rd_04": "0",
    "rd_05": "1670",
    "rd_06": "14323",
    "domain_policy": "COMPLETE_01_TO_06",
    "label_policy": "EXACT_SOURCE_C1_LABELS",
    "t29_historical": "NOT_APPROVED",
    "facts_and_link_table": "NOT_STARTED",
}


def main() -> int:
    for path in (DIM_QVD, DIM_CHECKPOINT):
        if not path.is_file():
            raise RuntimeError(f"QVD/checkpoint da dimensão não existe: {path}")

    # Preflight independente da saída do próprio QlikView e de seu checkpoint.
    check_manifest()
    codes = check_reference()
    check_existing_qvd()
    check_rd(codes)

    row_count, fields = qvd_header(DIM_QVD)
    if row_count != 6 or fields != EXPECTED_DIM_FIELDS:
        raise RuntimeError(f"QVD da dimensão divergente: {row_count}/{fields}")

    with DIM_CHECKPOINT.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        rows = list(reader)
        if len(rows) != 1 or reader.fieldnames is None:
            raise RuntimeError("Checkpoint dimensional exige uma linha única")
        row = rows[0]
        if None in row or any(v is None for v in row.values()):
            raise RuntimeError("Checkpoint dimensional CSV malformado")
        if set(reader.fieldnames) != {"generated_at", *EXPECTED_CHECKPOINT}:
            raise RuntimeError(f"Campos de checkpoint divergentes: {reader.fieldnames}")
        for field, expected in EXPECTED_CHECKPOINT.items():
            if row.get(field) != expected:
                raise RuntimeError(f"Checkpoint {field} divergiu: {row.get(field)!r} != {expected!r}")

    if DIM_QVD.stat().st_mtime < REF_QVD.stat().st_mtime:
        raise RuntimeError("QVD dimensional mais antigo que a referência C1")
    if DIM_CHECKPOINT.stat().st_mtime < DIM_QVD.stat().st_mtime - 5:
        raise RuntimeError("Checkpoint dimensional mais antigo que o QVD")

    print("MODE=IV_DIM_CARATER_QVD_CHECKPOINT_READ_ONLY_AUDIT")
    print("DIM_CARATER_QVD_SHA256=" + sha256(DIM_QVD))
    print("DIM_CARATER_QVD_BYTES=" + str(DIM_QVD.stat().st_size))
    print("DIM_CARATER_CHECKPOINT_SHA256=" + sha256(DIM_CHECKPOINT))
    print("DIM_CARATER_CHECKPOINT_BYTES=" + str(DIM_CHECKPOINT.stat().st_size))
    print("DIM_ROWS=6")
    print("DIM_FIELDS=4")
    print("DIM_UNIQUE_SK_CHECKPOINT=6")
    print("DIM_CODES=01,02,03,04,05,06")
    print("RD_ROWS=566672")
    print("RD_NORMALIZED_DISTINCT=4")
    print("RD_UNMATCHED=0")
    print("RD_01=80167 RD_02=470512 RD_03=0 RD_04=0 RD_05=1670 RD_06=14323")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("FACTS_AND_LINK_TABLE=NOT_STARTED")
    print("LIMIT=QVD_BINARY_BODY_NOT_INDEPENDENTLY_DECODED")
    print("VERDICT=PASS_LOCAL_DIM_CARATER_QVD_HEADER_CHECKPOINT_RECONCILED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
