#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
import zipfile
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DBC_RE = re.compile(r"^(RD|LT|ST)PB(17|18|19)(0[1-9]|1[0-2])\.dbc$", re.IGNORECASE)


@dataclass
class Detail:
    file: str
    fonte: str
    competencia: str
    acquisition_status: str
    expected_size_bytes: int | None
    actual_size_bytes: int | None
    size_match: bool
    expected_sha256: str | None
    actual_sha256: str | None
    hash_match: bool
    local_path: str | None
    status: str


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_repo = script_path.parent.parent

    parser = argparse.ArgumentParser(
        description="Reconcile the 108 local DATASUS DBC files against the acquisition manifest."
    )
    parser.add_argument("--zip-path", required=True, help="Path to resultado-aquisicao.zip")
    parser.add_argument("--repo-root", default=str(default_repo), help="Repository root")
    parser.add_argument("--data-root", default=None, help="BASE directory; defaults to <repo-root>/BASE")
    parser.add_argument("--manifest-entry", default="manifesto-execucao.json")
    parser.add_argument("--output-json", default=None)
    parser.add_argument("--output-csv", default=None)
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    repo_root = Path(args.repo_root).resolve()
    zip_path = Path(args.zip_path).resolve()
    data_root = Path(args.data_root).resolve() if args.data_root else repo_root / "BASE"
    output_json = (
        Path(args.output_json).resolve()
        if args.output_json
        else data_root / "CONVERTIDA" / "readiness-hash-reconciliation.json"
    )
    output_csv = (
        Path(args.output_csv).resolve()
        if args.output_csv
        else data_root / "CONVERTIDA" / "readiness-hash-reconciliation.csv"
    )

    if not zip_path.is_file():
        raise FileNotFoundError(f"Acquisition ZIP not found: {zip_path}")
    if not data_root.is_dir():
        raise FileNotFoundError(f"Data root not found: {data_root}")

    with zipfile.ZipFile(zip_path, "r") as zf:
        try:
            raw = zf.read(args.manifest_entry)
        except KeyError as exc:
            raise RuntimeError(
                f"Entry '{args.manifest_entry}' not found in '{zip_path}'."
            ) from exc

    manifest = json.loads(raw.decode("utf-8-sig"))
    items = manifest.get("items")
    if not isinstance(items, dict):
        raise RuntimeError("Manifest has no object field 'items'.")

    manifest_names = sorted(str(name) for name in items.keys())

    invalid_manifest_names = [n for n in manifest_names if not DBC_RE.fullmatch(n)]
    missing_manifest_hash: list[str] = []
    invalid_manifest_hash: list[str] = []
    missing_manifest_size: list[str] = []

    for name in manifest_names:
        item = items[name]
        if not isinstance(item, dict):
            raise RuntimeError(f"Manifest item is not an object: {name}")

        expected_hash = item.get("sha256")
        if expected_hash is None or not str(expected_hash).strip():
            missing_manifest_hash.append(name)
        elif not re.fullmatch(r"[0-9A-Fa-f]{64}", str(expected_hash)):
            invalid_manifest_hash.append(name)

        if item.get("size_bytes") is None:
            missing_manifest_size.append(name)

    local_files = sorted(
        (
            p
            for p in data_root.rglob("*")
            if p.is_file() and p.suffix.lower() == ".dbc" and DBC_RE.fullmatch(p.name)
        ),
        key=lambda p: (p.name.lower(), str(p).lower()),
    )

    by_name: dict[str, list[Path]] = {}
    for path in local_files:
        by_name.setdefault(path.name.lower(), []).append(path)

    details: list[Detail] = []

    for name in manifest_names:
        item: dict[str, Any] = items[name]
        matches = by_name.get(name.lower(), [])

        expected_hash_raw = item.get("sha256")
        expected_hash = (
            str(expected_hash_raw).lower() if expected_hash_raw is not None else None
        )
        expected_size = (
            int(item["size_bytes"]) if item.get("size_bytes") is not None else None
        )

        actual_path: str | None = None
        actual_hash: str | None = None
        actual_size: int | None = None
        hash_match = False
        size_match = False

        if len(matches) == 0:
            status = "MISSING"
        elif len(matches) > 1:
            status = "DUPLICATE_LOCAL"
        else:
            file_path = matches[0]
            actual_path = str(file_path)
            actual_size = file_path.stat().st_size
            actual_hash = sha256_file(file_path)
            hash_match = expected_hash is not None and actual_hash == expected_hash
            size_match = expected_size is not None and actual_size == expected_size

            if hash_match and size_match:
                status = "MATCH"
            elif not hash_match and not size_match:
                status = "HASH_AND_SIZE_MISMATCH"
            elif not hash_match:
                status = "HASH_MISMATCH"
            else:
                status = "SIZE_MISMATCH"

        details.append(
            Detail(
                file=name,
                fonte=str(item.get("fonte", "")),
                competencia=str(item.get("competencia", "")),
                acquisition_status=str(item.get("status", "")),
                expected_size_bytes=expected_size,
                actual_size_bytes=actual_size,
                size_match=size_match,
                expected_sha256=expected_hash,
                actual_sha256=actual_hash,
                hash_match=hash_match,
                local_path=actual_path,
                status=status,
            )
        )

    manifest_name_set = {n.lower() for n in manifest_names}
    extras = [p for p in local_files if p.name.lower() not in manifest_name_set]

    matched = sum(d.status == "MATCH" for d in details)
    missing = sum(d.status == "MISSING" for d in details)
    duplicates = sum(d.status == "DUPLICATE_LOCAL" for d in details)
    hash_mismatch = sum(
        d.status in {"HASH_MISMATCH", "HASH_AND_SIZE_MISMATCH"} for d in details
    )
    size_mismatch = sum(
        d.status in {"SIZE_MISMATCH", "HASH_AND_SIZE_MISMATCH"} for d in details
    )

    expected_count = len(manifest_names)
    local_count = len(local_files)
    manifest_issue_count = (
        len(invalid_manifest_names)
        + len(missing_manifest_hash)
        + len(invalid_manifest_hash)
        + len(missing_manifest_size)
    )

    verdict = (
        "PASS"
        if (
            expected_count == 108
            and local_count == 108
            and matched == 108
            and missing == 0
            and duplicates == 0
            and hash_mismatch == 0
            and size_mismatch == 0
            and len(extras) == 0
            and manifest_issue_count == 0
        )
        else "FAIL"
    )

    report = {
        "generated_at": datetime.now(timezone.utc).astimezone().isoformat(),
        "zip_path": str(zip_path),
        "manifest_entry": args.manifest_entry,
        "manifest_started_at_utc": manifest.get("started_at_utc"),
        "manifest_finished_at_utc": manifest.get("finished_at_utc"),
        "manifest_mode": manifest.get("mode"),
        "manifest_status": manifest.get("status"),
        "data_root": str(data_root.resolve()),
        "verdict": verdict,
        "summary": {
            "expected_manifest_items": expected_count,
            "local_dbc_files": local_count,
            "matched": matched,
            "missing": missing,
            "duplicate_local": duplicates,
            "hash_mismatch": hash_mismatch,
            "size_mismatch": size_mismatch,
            "extras": len(extras),
            "invalid_manifest_names": len(invalid_manifest_names),
            "missing_manifest_hash": len(missing_manifest_hash),
            "invalid_manifest_hash": len(invalid_manifest_hash),
            "missing_manifest_size": len(missing_manifest_size),
        },
        "manifest_issues": {
            "invalid_names": invalid_manifest_names,
            "missing_hash": missing_manifest_hash,
            "invalid_hash": invalid_manifest_hash,
            "missing_size": missing_manifest_size,
        },
        "extras": [
            {
                "file": p.name,
                "path": str(p),
                "size_bytes": p.stat().st_size,
            }
            for p in extras
        ],
        "details": [asdict(d) for d in details],
    }

    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_csv.parent.mkdir(parents=True, exist_ok=True)

    output_json.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    fieldnames = list(asdict(details[0]).keys()) if details else []
    with output_csv.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        if fieldnames:
            writer.writeheader()
            for detail in details:
                writer.writerow(asdict(detail))

    print()
    print("=== BOUNDARY 8 - HASH RECONCILIATION ===")
    print(f"Manifest items : {expected_count}")
    print(f"Local DBCs     : {local_count}")
    print(f"Matched        : {matched}")
    print(f"Missing        : {missing}")
    print(f"Duplicates     : {duplicates}")
    print(f"Hash mismatch  : {hash_mismatch}")
    print(f"Size mismatch  : {size_mismatch}")
    print(f"Extras         : {len(extras)}")
    print(f"Manifest issues: {manifest_issue_count}")
    print(f"JSON report    : {output_json}")
    print(f"CSV report     : {output_csv}")
    print(f"VERDICT={verdict}")

    if verdict != "PASS":
        bad = [d for d in details if d.status != "MATCH"]
        if bad:
            print()
            print("Non-matching items:")
            for d in bad:
                print(
                    f"- {d.file}: {d.status}; "
                    f"expected_size={d.expected_size_bytes}; actual_size={d.actual_size_bytes}; "
                    f"expected_sha256={d.expected_sha256}; actual_sha256={d.actual_sha256}"
                )

        if extras:
            print()
            print("Extra local DBC files:")
            for p in extras:
                print(f"- {p}")

        return 1

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print()
        print("READINESS_HASH_RECONCILIATION_ERROR")
        print(f"ERROR_TYPE={type(exc).__name__}")
        print(f"ERROR_MESSAGE={exc}")
        raise SystemExit(1)
