#!/usr/bin/env python3
"""
Convert DATASUS DBC files to UTF-8 CSV for the SAD — Data Mart SUS PB pipeline.

Contract:
DBC -> temporary DBF -> CSV UTF-8

The converter never modifies input DBCs and records operational metadata in
BASE/CONVERTIDA/manifest/dbc-conversion-manifest.csv by default.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from dbctodbf import DBCDecompress
from dbfread import DBF


SOURCE_FAMILIES = ("RD", "LT", "ST")
DBC_NAME_RE = re.compile(
    r"^(?P<family>RD|LT|ST)PB(?P<year>17|18|19)(?P<month>0[1-9]|1[0-2])\.dbc$",
    re.IGNORECASE,
)
MANIFEST_FIELDS = [
    "source_family",
    "competence",
    "input_file",
    "input_sha256",
    "input_size_bytes",
    "output_file",
    "output_sha256",
    "record_count",
    "field_count",
    "field_names_signature",
    "converted_at",
    "status",
    "error",
]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def raw_to_text(value: object, encoding: str) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode(encoding, errors="strict")
    return str(value)


def parse_competence(filename: str, expected_family: str) -> str:
    match = DBC_NAME_RE.fullmatch(filename)
    if not match:
        raise ValueError(f"Unexpected DBC filename for project scope: {filename}")

    family = match.group("family").upper()
    if family != expected_family:
        raise ValueError(
            f"Source family mismatch for {filename}: expected {expected_family}, got {family}."
        )

    return f"20{match.group('year')}{match.group('month')}"


def field_signature(field_names: list[str]) -> str:
    if not field_names:
        raise ValueError("DBF schema is empty.")
    return hashlib.sha256("|".join(field_names).encode("utf-8")).hexdigest()


def read_existing_manifest(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []

    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        return [
            {field: row.get(field, "") for field in MANIFEST_FIELDS}
            for row in reader
        ]


def write_manifest(
    path: Path,
    source_family: str,
    current_rows: list[dict[str, object]],
) -> None:
    existing = read_existing_manifest(path)
    kept = [
        row
        for row in existing
        if str(row.get("source_family", "")).upper() != source_family
    ]
    merged = kept + [
        {field: row.get(field, "") for field in MANIFEST_FIELDS}
        for row in current_rows
    ]
    merged.sort(
        key=lambda row: (
            str(row.get("source_family", "")),
            str(row.get("input_file", "")),
        )
    )

    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(path.suffix + ".tmp")
    try:
        with temp_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(
                handle,
                fieldnames=MANIFEST_FIELDS,
                delimiter=";",
                quotechar='"',
                quoting=csv.QUOTE_MINIMAL,
                lineterminator="\n",
            )
            writer.writeheader()
            writer.writerows(merged)
        temp_path.replace(path)
    finally:
        if temp_path.exists():
            temp_path.unlink()


def convert_one(
    dbc_path: Path,
    output_dir: Path,
    source_family: str,
    dbf_encoding: str,
) -> dict[str, object]:
    competence = parse_competence(dbc_path.name, source_family)
    input_hash = sha256_file(dbc_path)
    input_size = dbc_path.stat().st_size

    output_dir.mkdir(parents=True, exist_ok=True)
    csv_path = output_dir / f"{dbc_path.stem}.csv"
    csv_temp_path = csv_path.with_suffix(csv_path.suffix + ".tmp")

    converted_at = datetime.now(timezone.utc).isoformat()
    manifest_row: dict[str, object] = {
        "source_family": source_family,
        "competence": competence,
        "input_file": dbc_path.name,
        "input_sha256": input_hash,
        "input_size_bytes": input_size,
        "output_file": str(csv_path),
        "output_sha256": "",
        "record_count": "",
        "field_count": "",
        "field_names_signature": "",
        "converted_at": converted_at,
        "status": "ERROR",
        "error": "",
    }

    if csv_temp_path.exists():
        csv_temp_path.unlink()

    try:
        with tempfile.TemporaryDirectory(prefix="sad-dbc-") as temp_dir:
            dbf_path = Path(temp_dir) / f"{dbc_path.stem}.dbf"
            DBCDecompress().decompressFile(str(dbc_path), str(dbf_path))

            if not dbf_path.is_file():
                raise RuntimeError(
                    f"DBC decompression did not create DBF: {dbc_path.name}"
                )

            table = DBF(
                str(dbf_path),
                raw=True,
                encoding=dbf_encoding,
                char_decode_errors="strict",
                load=False,
            )
            field_names = list(table.field_names)
            signature = field_signature(field_names)

            record_count = 0
            with csv_temp_path.open("w", encoding="utf-8", newline="") as handle:
                writer = csv.writer(
                    handle,
                    delimiter=";",
                    quotechar='"',
                    quoting=csv.QUOTE_MINIMAL,
                    lineterminator="\n",
                )
                writer.writerow(field_names)

                for record in table:
                    writer.writerow(
                        [
                            raw_to_text(record[name], dbf_encoding)
                            for name in field_names
                        ]
                    )
                    record_count += 1

        output_hash = sha256_file(csv_temp_path)
        csv_temp_path.replace(csv_path)

        manifest_row.update(
            {
                "output_sha256": output_hash,
                "record_count": record_count,
                "field_count": len(field_names),
                "field_names_signature": signature,
                "status": "PASS",
            }
        )
        return manifest_row
    except Exception as exc:
        manifest_row["error"] = f"{type(exc).__name__}: {exc}"
        raise ConversionError(manifest_row) from exc
    finally:
        if csv_temp_path.exists():
            csv_temp_path.unlink()


class ConversionError(RuntimeError):
    def __init__(self, manifest_row: dict[str, object]):
        super().__init__(str(manifest_row.get("error", "Conversion failed.")))
        self.manifest_row = manifest_row


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert DATASUS DBC files to UTF-8 semicolon-delimited CSV."
    )
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument(
        "--source-family",
        required=True,
        choices=SOURCE_FAMILIES,
        help="Expected DBC family: RD, LT or ST.",
    )
    parser.add_argument(
        "--expected-files",
        type=int,
        default=None,
        help=(
            "Optional exact number of DBC files expected for the selected family. "
            "Use 36 for the full 2017-2019 batch."
        ),
    )
    parser.add_argument(
        "--manifest-path",
        type=Path,
        default=None,
        help=(
            "Manifest CSV path. Defaults to "
            "<output-dir>/../manifest/dbc-conversion-manifest.csv."
        ),
    )
    parser.add_argument(
        "--dbf-encoding",
        default="latin1",
        help=(
            "Encoding used to map raw DBF character bytes before writing UTF-8. "
            "Default: latin1 (readiness-tested baseline)."
        ),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source_family = args.source_family.upper()
    input_dir = args.input_dir.resolve()
    output_dir = args.output_dir.resolve()
    manifest_path = (
        args.manifest_path.resolve()
        if args.manifest_path
        else output_dir.parent / "manifest" / "dbc-conversion-manifest.csv"
    )

    if not input_dir.is_dir():
        print(f"ERROR: input directory not found: {input_dir}", file=sys.stderr)
        return 2

    dbc_files = sorted(
        [
            path
            for path in input_dir.rglob("*")
            if (
                path.is_file()
                and path.suffix.lower() == ".dbc"
                and path.name.upper().startswith(f"{source_family}PB")
            )
        ],
        key=lambda path: (path.name.upper(), str(path).upper()),
    )
    if not dbc_files:
        print(
            f"ERROR: no {source_family} DBC files found in {input_dir}",
            file=sys.stderr,
        )
        return 2

    if args.expected_files is not None and len(dbc_files) != args.expected_files:
        print(
            f"ERROR: expected {args.expected_files} {source_family} DBC files, "
            f"found {len(dbc_files)} in {input_dir}",
            file=sys.stderr,
        )
        return 2

    rows: list[dict[str, object]] = []

    try:
        for dbc_path in dbc_files:
            row = convert_one(
                dbc_path=dbc_path,
                output_dir=output_dir,
                source_family=source_family,
                dbf_encoding=args.dbf_encoding,
            )
            rows.append(row)
            print(
                f"{dbc_path.name}: PASS "
                f"records={row['record_count']} fields={row['field_count']}"
            )
    except ConversionError as exc:
        rows.append(exc.manifest_row)
        write_manifest(manifest_path, source_family, rows)
        print(f"ERROR: {exc}", file=sys.stderr)
        print(f"Manifest: {manifest_path}", file=sys.stderr)
        return 1
    except Exception as exc:
        write_manifest(manifest_path, source_family, rows)
        print(f"ERROR: {type(exc).__name__}: {exc}", file=sys.stderr)
        print(f"Manifest: {manifest_path}", file=sys.stderr)
        return 1

    write_manifest(manifest_path, source_family, rows)

    print(f"Manifest: {manifest_path}")
    print(
        f"CONVERSION_PASS source={source_family} files={len(rows)} "
        f"records={sum(int(row['record_count']) for row in rows)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
