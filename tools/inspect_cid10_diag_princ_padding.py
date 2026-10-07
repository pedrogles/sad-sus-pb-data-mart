#!/usr/bin/env python3
"""Caracteriza whitespace/padding observado em DIAG_PRINC.

Checkpoint III-C2 — diagnóstico de chave antes do lookup CID-10.
Não altera os dados e não decide automaticamente a normalização.

Saídas locais (ignoradas pelo Git):
- BASE/REFERENCIAS/cid10_diag_princ_padding.csv
- BASE/REFERENCIAS/cid10_diag_princ_padding_summary.json
"""

from __future__ import annotations

import csv
import glob
import hashlib
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

EXPECTED_FILES = 36
EXPECTED_ROWS = 566_672
INPUT_GLOB = r"BASE\CONVERTIDA\RD\RDPB*.csv"
OUTPUT_DIR = Path("BASE/REFERENCIAS")
DETAIL_PATH = OUTPUT_DIR / "cid10_diag_princ_padding.csv"
SUMMARY_PATH = OUTPUT_DIR / "cid10_diag_princ_padding_summary.json"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def classify_whitespace(value: str) -> str:
    if not any(ch.isspace() for ch in value):
        return "NONE"

    leading = bool(value) and value[0].isspace()
    trailing = bool(value) and value[-1].isspace()
    internal = any(ch.isspace() for ch in value[1:-1])

    parts = []
    if leading:
        parts.append("LEADING")
    if internal:
        parts.append("INTERNAL")
    if trailing:
        parts.append("TRAILING")

    return "+".join(parts) if parts else "WHITESPACE_OTHER"


def escape_value(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("\t", "\\t")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace(" ", "␠")
    )


def main() -> int:
    files = sorted(glob.glob(INPUT_GLOB))
    if len(files) != EXPECTED_FILES:
        raise RuntimeError(
            f"Quantidade de arquivos RD divergente: esperado={EXPECTED_FILES} atual={len(files)}"
        )

    raw_counts: Counter[str] = Counter()
    whitespace_position_rows: Counter[str] = Counter()
    whitespace_char_rows: Counter[str] = Counter()
    trim_length_rows: Counter[int] = Counter()
    trim_to_raw: defaultdict[str, set[str]] = defaultdict(set)

    total_rows = 0

    for path in files:
        with open(path, "r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle, delimiter=";")
            if reader.fieldnames is None or "DIAG_PRINC" not in reader.fieldnames:
                raise RuntimeError(f"Campo DIAG_PRINC ausente em {path}")

            for row in reader:
                total_rows += 1
                raw = row["DIAG_PRINC"]
                if raw is None:
                    raw = ""

                raw_counts[raw] += 1

                position = classify_whitespace(raw)
                whitespace_position_rows[position] += 1

                whitespace_chars = {ch for ch in raw if ch.isspace()}
                if not whitespace_chars:
                    whitespace_char_rows["NONE"] += 1
                else:
                    for ch in sorted(whitespace_chars):
                        if ch == " ":
                            key = "SPACE_U+0020"
                        elif ch == "\t":
                            key = "TAB_U+0009"
                        elif ch == "\r":
                            key = "CR_U+000D"
                        elif ch == "\n":
                            key = "LF_U+000A"
                        else:
                            key = f"U+{ord(ch):04X}"
                        whitespace_char_rows[key] += 1

                trimmed = raw.strip()
                trim_length_rows[len(trimmed)] += 1
                trim_to_raw[trimmed].add(raw)

    if total_rows != EXPECTED_ROWS:
        raise RuntimeError(
            f"Quantidade de linhas RD divergente: esperado={EXPECTED_ROWS} atual={total_rows}"
        )

    whitespace_codes = {
        raw: count
        for raw, count in raw_counts.items()
        if any(ch.isspace() for ch in raw)
    }

    trim_collisions = {
        trimmed: sorted(values)
        for trimmed, values in trim_to_raw.items()
        if len(values) > 1
    }

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with DETAIL_PATH.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "diag_princ_raw_escaped",
                "diag_princ_trimmed",
                "occurrences",
                "raw_length",
                "trimmed_length",
                "whitespace_position",
                "trim_collision_raw_variant_count",
            ],
            delimiter=";",
        )
        writer.writeheader()

        for raw in sorted(whitespace_codes):
            trimmed = raw.strip()
            writer.writerow(
                {
                    "diag_princ_raw_escaped": escape_value(raw),
                    "diag_princ_trimmed": trimmed,
                    "occurrences": whitespace_codes[raw],
                    "raw_length": len(raw),
                    "trimmed_length": len(trimmed),
                    "whitespace_position": classify_whitespace(raw),
                    "trim_collision_raw_variant_count": len(trim_to_raw[trimmed]),
                }
            )

    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C2_CID10_PADDING_DIAGNOSTIC",
        "status": "PASS",
        "input": {
            "files": len(files),
            "rows": total_rows,
            "expected_files": EXPECTED_FILES,
            "expected_rows": EXPECTED_ROWS,
        },
        "raw": {
            "distinct_codes": len(raw_counts),
            "whitespace_rows": sum(whitespace_codes.values()),
            "whitespace_distinct_codes": len(whitespace_codes),
            "whitespace_position_rows": dict(sorted(whitespace_position_rows.items())),
            "whitespace_character_rows": dict(sorted(whitespace_char_rows.items())),
        },
        "trim_candidate": {
            "distinct_codes_after_trim": len(trim_to_raw),
            "trimmed_length_rows": {str(k): v for k, v in sorted(trim_length_rows.items())},
            "collision_count": len(trim_collisions),
            "collision_examples": [
                {
                    "trimmed": trimmed,
                    "raw_variants_escaped": [escape_value(v) for v in variants],
                }
                for trimmed, variants in list(sorted(trim_collisions.items()))[:20]
            ],
        },
        "detail": {
            "path": str(DETAIL_PATH),
            "sha256": sha256_file(DETAIL_PATH),
        },
    }

    SUMMARY_PATH.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"RD_FILES={len(files)}")
    print(f"RD_ROWS={total_rows}")
    print(f"RAW_DISTINCT_CODES={len(raw_counts)}")
    print(f"WHITESPACE_ROWS={sum(whitespace_codes.values())}")
    print(f"WHITESPACE_DISTINCT_CODES={len(whitespace_codes)}")
    print(
        "WHITESPACE_POSITION_ROWS="
        + json.dumps(summary["raw"]["whitespace_position_rows"], ensure_ascii=False)
    )
    print(
        "WHITESPACE_CHARACTER_ROWS="
        + json.dumps(summary["raw"]["whitespace_character_rows"], ensure_ascii=False)
    )
    print(f"DISTINCT_CODES_AFTER_TRIM={len(trim_to_raw)}")
    print(
        "TRIMMED_LENGTH_ROWS="
        + json.dumps(summary["trim_candidate"]["trimmed_length_rows"], ensure_ascii=False)
    )
    print(f"TRIM_COLLISION_COUNT={len(trim_collisions)}")
    print(f"DETAIL={DETAIL_PATH}")
    print(f"DETAIL_SHA256={summary['detail']['sha256']}")
    print(f"SUMMARY={SUMMARY_PATH}")
    print("VERDICT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
