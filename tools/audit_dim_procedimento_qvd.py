#!/usr/bin/env python3
"""Auditoria independente READ-ONLY do QVD DIM_PROCEDIMENTO e checkpoint.

Reconcilia o SHA-256 do CSV de staging já auditado, metadados do cabeçalho
QvdTableHeader e contadores do checkpoint Qlik. NÃO decodifica o corpo
binário QVD registro a registro; o reload do QlikView faz os testes de dados.
Não escreve arquivos.
"""
from __future__ import annotations

import csv
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

CSV = Path("BASE/REFERENCIAS/sigtap_procedimento_hierarquia_staging_candidate.csv")
MANIFEST = Path("BASE/REFERENCIAS/sigtap_procedimento_hierarquia_staging_candidate_manifest.json")
QVD = Path("TRANSFORMACAO/QVD/DIM_PROCEDIMENTO.qvd")
CHECKPOINT = Path("TRANSFORMACAO/QVD/_CHECKPOINT_DIM_PROCEDIMENTO.csv")
EXPECTED_SOURCE_SHA = "cf75e51400c09896fe0e296bd3a4d448353de4c196bbb40985a58f24012b6db7"
EXPECTED_QVD_FIELDS = [
    "%SK_PROCEDIMENTO",
    "COD_PROCEDIMENTO",
    "COMPETENCIA_REFERENCIA",
    "NOME_PROCEDIMENTO",
    "DESCRICAO_OFICIAL",
    "DESCRICAO_OFICIAL_STATUS",
    "CO_GRUPO",
    "NO_GRUPO",
    "CO_SUB_GRUPO",
    "NO_SUB_GRUPO",
    "CO_FORMA_ORGANIZACAO",
    "NO_FORMA_ORGANIZACAO",
]
EXPECTED_CHECKPOINT = {
    "stage": "TRANSFORMACAO_DIM_PROCEDIMENTO",
    "status": "PASS_PARTIAL_DIM_PROCEDIMENTO_ONLY",
    "dimension_rows": "165203",
    "dimension_fields": "12",
    "distinct_competences": "36",
    "unique_surrogate_keys": "165203",
    "unique_procedure_month_versions": "165203",
    "invalid_dimension_rows": "0",
    "rd_rows": "566672",
    "rd_procedure_unmatched": "0",
    "hierarchy_source_policy": "CSV_10_FIELDS_36_MONTHS_PYTHON_SHA_AND_ROW_RECONCILED",
    "description_encoding_policy": "OPERATIONAL_CP1252_EQUIVALENT_ISO_8859_1_ON_CORPUS",
    "detailed_description_policy": "NULL_NO_DETAILED_DESCRIPTION_SOURCE",
    "provenance_caveat": "RETROSPECTIVE_ZIP_V2102261143_FOR_201808",
    "t29_historical": "NOT_APPROVED",
    "facts_and_link_table": "NOT_STARTED",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for data in iter(lambda: stream.read(1 << 20), b""):
            digest.update(data)
    return digest.hexdigest()


def qvd_header(path: Path) -> ET.Element:
    # QVD possui cabeçalho XML e corpo proprietário. Inspecionar apenas XML.
    with path.open("rb") as f:
        chunks = bytearray()
        end = b"</QvdTableHeader>"
        while True:
            block = f.read(65536)
            if not block:
                raise RuntimeError("QvdTableHeader nao localizado")
            chunks.extend(block)
            pos = chunks.find(end)
            if pos >= 0:
                chunks = chunks[:pos + len(end)]
                break
            if len(chunks) > 2 * 1024 * 1024:
                raise RuntimeError("Cabecalho QVD maior que o esperado")
    return ET.fromstring(chunks)


def nodes(root: ET.Element, localname: str) -> list[str]:
    return [
        (item.text or "")
        for item in root.iter()
        if item.tag.rsplit("}", 1)[-1] == localname
    ]


def main() -> int:
    for path in (CSV, MANIFEST, QVD, CHECKPOINT):
        if not path.is_file():
            raise RuntimeError(f"Arquivo obrigatorio ausente: {path}")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if (
        manifest.get("stage") != "IV_PROCEDIMENTO_SIGTAP_HIERARCHY_STAGING_CANDIDATE"
        or manifest.get("status") != "PASS_CANDIDATE_ONLY"
        or manifest.get("competences") != 36
        or manifest.get("rows") != 165203
        or manifest.get("distinct_keys") != 165203
        or manifest.get("csv_sha256") != EXPECTED_SOURCE_SHA
        or manifest.get("t29_historical") != "NOT_APPROVED"
        or manifest.get("qvd_generated") is not False
        or manifest.get("fact_tables_generated") is not False
        or sha256(CSV) != EXPECTED_SOURCE_SHA
    ):
        raise RuntimeError("CSV SIGTAP hierarquico e manifesto nao reconciliados")

    root = qvd_header(QVD)
    counts = nodes(root, "NoOfRecords")
    fields = nodes(root, "FieldName")
    if len(counts) != 1 or counts[0] != "165203":
        raise RuntimeError(f"QVD registros invalidos: {counts}")
    if fields != EXPECTED_QVD_FIELDS:
        raise RuntimeError(f"QVD schema inesperado: {fields}")
    with CHECKPOINT.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream, delimiter=";")
        rows = list(reader)
        if len(rows) != 1 or reader.fieldnames is None:
            raise RuntimeError("Checkpoint deve ter exatamente uma linha")
        payload = rows[0]
        if any(key not in payload for key in EXPECTED_CHECKPOINT):
            raise RuntimeError("Checkpoint com schema incompleto")
        for key, expected in EXPECTED_CHECKPOINT.items():
            if payload[key] != expected:
                raise RuntimeError(
                    f"Checkpoint divergiu em {key}: esperado={expected}, real={payload[key]}"
                )

    # Previne aprovação de QVD/checkpoint herdados de um CSV mais recente.
    if QVD.stat().st_mtime < CSV.stat().st_mtime:
        raise RuntimeError("QVD anterior ao CSV de staging auditado")
    if CHECKPOINT.stat().st_mtime < QVD.stat().st_mtime - 5:
        raise RuntimeError("Checkpoint mais antigo que o QVD")

    print("SOURCE_CSV_SHA256=" + sha256(CSV))
    print("QVD_SHA256=" + sha256(QVD))
    print("CHECKPOINT_SHA256=" + sha256(CHECKPOINT))
    print("QVD_ROWS=165203")
    print("QVD_FIELDS=12")
    print("QVD_SCHEMA=" + repr(fields))
    print("CHECKPOINT_STATUS=PASS_PARTIAL_DIM_PROCEDIMENTO_ONLY")
    print("RD_ROWS=566672")
    print("RD_PROCEDURE_UNMATCHED=0")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("FACTS_AND_LINK_TABLE=NOT_STARTED")
    print("VERDICT=PASS_LOCAL_DIM_PROCEDIMENTO_QVD_HEADER_CHECKPOINT_RECONCILED")
    print("LIMIT=QVD_BINARY_ROWS_NOT_INDEPENDENTLY_DECODED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
