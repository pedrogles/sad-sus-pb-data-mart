#!/usr/bin/env python3
"""
Boundary 8 readiness smoke test for DATASUS DBC files.

Converts a small, known set of DBC files to DBF and UTF-8 CSV, then
reconciles record/schema expectations documented in Boundary 3.

This is a readiness utility, not the definitive production converter.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sys
from pathlib import Path

from dbctodbf import DBCDecompress
from dbfread import DBF


SAMPLES = [
    {"file": "RDPB1702.dbc", "expected_records": 13912, "expected_fields": 113},
    {"file": "LTPB1712.dbc", "expected_records": 1033, "expected_fields": 28},
    {"file": "STPB1701.dbc", "expected_records": 5692, "expected_fields": 201},
    {"file": "STPB1912.dbc", "expected_records": None, "expected_fields": 208},
]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def find_exact(root: Path, filename: str) -> Path:
    matches = list(root.rglob(filename))
    if len(matches) != 1:
        raise RuntimeError(
            f"Expected exactly one {filename} under {root}, found {len(matches)}."
        )
    return matches[0]


def raw_to_text(value):
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("latin1")
    return str(value)


def convert_sample(dbc_path: Path, out_dir: Path, expected_records, expected_fields):
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = dbc_path.stem

    dbf_path = out_dir / f"{stem}.dbf"
    csv_path = out_dir / f"{stem}.csv"

    DBCDecompress().decompressFile(str(dbc_path), str(dbf_path))

    table = DBF(
        str(dbf_path),
        raw=True,
        encoding="latin1",
        char_decode_errors="strict",
        load=False,
    )

    field_names = list(table.field_names)
    field_count = len(field_names)
    field_signature = hashlib.sha256(
        "|".join(field_names).encode("utf-8")
    ).hexdigest()

    record_count = 0
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(
            f,
            delimiter=";",
            quotechar='"',
            quoting=csv.QUOTE_MINIMAL,
            lineterminator="\n",
        )
        writer.writerow(field_names)

        for record in table:
            writer.writerow([raw_to_text(record[name]) for name in field_names])
            record_count += 1

    checks = {
        "field_count": field_count == expected_fields,
        "record_count": (
            True if expected_records is None else record_count == expected_records
        ),
    }

    return {
        "input_file": dbc_path.name,
        "input_path": str(dbc_path),
        "input_sha256": sha256_file(dbc_path),
        "dbf_file": str(dbf_path),
        "csv_file": str(csv_path),
        "csv_sha256": sha256_file(csv_path),
        "record_count": record_count,
        "expected_records": expected_records,
        "field_count": field_count,
        "expected_fields": expected_fields,
        "field_names_signature": field_signature,
        "checks": checks,
        "status": "PASS" if all(checks.values()) else "FAIL",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    repo_root = Path(__file__).resolve().parent.parent

    parser.add_argument(
        "--data-root",
        type=Path,
        default=repo_root / "BASE",
        help="Root containing the DBC files.",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=repo_root / "BASE" / "CONVERTIDA" / "readiness-smoke",
        help="Output directory for temporary DBF/CSV/report artifacts.",
    )
    args = parser.parse_args()

    results = []
    try:
        for spec in SAMPLES:
            dbc = find_exact(args.data_root, spec["file"])
            result = convert_sample(
                dbc,
                args.out_dir,
                spec["expected_records"],
                spec["expected_fields"],
            )
            results.append(result)
            print(
                f"{result['input_file']}: {result['status']} "
                f"records={result['record_count']} "
                f"fields={result['field_count']}"
            )
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    overall = "PASS" if all(r["status"] == "PASS" for r in results) else "FAIL"
    report = {
        "boundary": "8",
        "test": "DBC_SMOKE",
        "verdict": overall,
        "results": results,
    }

    args.out_dir.mkdir(parents=True, exist_ok=True)
    report_path = args.out_dir / "readiness-dbc-smoke-report.json"
    report_path.write_text(
        json.dumps(report, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"Report: {report_path}")
    print(f"VERDICT={overall}")
    return 0 if overall == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
