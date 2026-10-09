#!/usr/bin/env python3
"""READ-ONLY: conferir metadados do cabecalho XML dos QVDs contra o gate III-FINAL.

Nao usa QlikView, nao altera arquivos, nao considera XML como prova completa
de carga: identifica apenas contagens/campos divergentes. Se 10/10 PASS,
continuar diagnostico pelo log QlikView real, sem assumir gate aprovado.
"""
from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GATE = ROOT / "EXTRACAO" / "ext_phase3_final_gate.qvs"
QVDS = ROOT / "EXTRACAO" / "QVD"
HEADER_END = b"</QvdTableHeader>"
HEADER_LIMIT = 8 * 1024 * 1024


def parse_contracts(path: Path) -> list[tuple[str, int, tuple[str, ...]]]:
    script = path.read_text(encoding="utf-8-sig")
    match = re.search(r"P3_GATE_CONTRACTS:\s*LOAD\s+\*\s+INLINE\s*\[\s*"
                      r"qvd_name,expected_rows,required_fields\s*\n(.*?)\n\];",
                      script, flags=re.IGNORECASE | re.DOTALL)
    if match is None:
        raise ValueError(f"Bloco de contratos nao localizado: {path}")
    result = []
    for line in match.group(1).splitlines():
        columns = line.strip().split(",")
        if len(columns) != 3:
            raise ValueError(f"Linha do contrato mal formada: {line!r}")
        name, expected_rows, fields = columns
        if not re.fullmatch(r"[A-Z_][A-Z0-9_]*", name):
            raise ValueError(f"Nome de QVD inesperado: {name!r}")
        result.append((name, int(expected_rows), tuple(fields.split("|"))))
    if len(result) != 10:
        raise ValueError(f"Esperados 10 contratos: {len(result)}")
    return result


def tagname(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def qvd_header(path: Path) -> tuple[int, tuple[str, ...]]:
    if not path.is_file():
        raise ValueError(f"QVD ausente: {path}")
    with path.open("rb") as data:
        header = data.read(HEADER_LIMIT)
    end = header.find(HEADER_END)
    if end < 0:
        raise ValueError(f"QVD sem fechamento de cabecalho XML nos primeiros {HEADER_LIMIT} bytes: {path}")
    root = ET.fromstring(header[:end + len(HEADER_END)])
    if tagname(root.tag) != "QvdTableHeader":
        raise ValueError(f"Tag XML nao reconhecida: {root.tag}")
    numbers = [
        (element.text or "").strip()
        for element in root.iter()
        if tagname(element.tag) == "NoOfRecords"
    ]
    if len(numbers) != 1 or not numbers[0].isdigit():
        raise ValueError(f"NoOfRecords ausente/ambiguo: {path}")
    field_headers = [node for node in root.iter() if tagname(node.tag) == "QvdFieldHeader"]
    fields = []
    for node in field_headers:
        names = [
            (el.text or "")
            for el in node.iter()
            if tagname(el.tag) == "FieldName"
        ]
        if len(names) != 1:
            raise ValueError(f"QvdFieldHeader com FieldName ausente/ambiguo: {path}")
        fields.append(names[0])
    if not fields:
        raise ValueError(f"Sem campos XML reconhecidos no QVD: {path}")
    return int(numbers[0]), tuple(fields)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gate", type=Path, default=GATE)
    parser.add_argument("--qvd-dir", type=Path, default=QVDS)
    args = parser.parse_args()
    try:
        contracts = parse_contracts(args.gate)
    except (OSError, ValueError) as error:
        print(f"CONTRACT_ERROR={error}")
        return 2

    discrepancies = 0
    total_fields = 0
    for name, expected_rows, required in contracts:
        path = args.qvd_dir / (name + ".qvd")
        try:
            actual_rows, physical = qvd_header(path)
        except (OSError, ValueError, ET.ParseError) as error:
            discrepancies += 1
            print(f"QVD={name} HEADER_UNREADABLE={error}")
            continue

        absent = [field for field in required if field not in physical]
        duplicate_fields = len(physical) != len(set(physical))
        different_rows = actual_rows != expected_rows
        if absent or duplicate_fields or different_rows:
            discrepancies += 1
            print(f"QVD={name} MISMATCH expected_rows={expected_rows} actual_rows={actual_rows} "
                  f"physical_fields={len(physical)} required_fields={len(required)}")
            if absent:
                print("  MISSING_REQUIRED=" + "|".join(absent))
            if duplicate_fields:
                print("  DUPLICATE_FIELD_NAMES=YES")
        else:
            total_fields += len(required)
            print(f"QVD={name} HEADER_OK rows={actual_rows} "
                  f"physical_fields={len(physical)} required_fields={len(required)}")

    print(f"HEADER_CONTRACTS={len(contracts)} PROBLEM_QVDS={discrepancies} "
          f"FIELDS_IN_MATCHING_QVDS={total_fields}")
    if discrepancies:
        print("VERDICT=QVD_HEADER_CONTRACT_REVIEW_REQUIRED")
        return 2
    print("VERDICT=QVD_HEADERS_MATCH_EXPECTATIONS_ONLY")
    print("NOTE=Resultado nao comprova T07/T08 no Qlik nem fecha Fase III.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
