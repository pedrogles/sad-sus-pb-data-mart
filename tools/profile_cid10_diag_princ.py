#!/usr/bin/env python3
"""Perfila DIAG_PRINC do SIH/RD antes da materialização da referência CID-10.

Checkpoint III-C2 — modo diagnóstico/read-only sobre as fontes convertidas.
Não baixa CID-10, não normaliza códigos e não altera os CSVs RD.

Saídas locais (ignoradas pelo Git):
- BASE/REFERENCIAS/cid10_diag_princ_profile.csv
- BASE/REFERENCIAS/cid10_diag_princ_summary.json
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
PROFILE_PATH = OUTPUT_DIR / "cid10_diag_princ_profile.csv"
SUMMARY_PATH = OUTPUT_DIR / "cid10_diag_princ_summary.json"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def source_competence(path: str) -> str:
    stem = Path(path).stem
    # RDPBYYMM -> 20YYMM
    if len(stem) != 8 or not stem.startswith("RDPB") or not stem[4:].isdigit():
        raise RuntimeError(f"Nome de arquivo RD inesperado: {stem}")
    return "20" + stem[4:]


def main() -> int:
    files = sorted(glob.glob(INPUT_GLOB))
    if len(files) != EXPECTED_FILES:
        raise RuntimeError(
            f"Quantidade de arquivos RD divergente: esperado={EXPECTED_FILES} atual={len(files)}"
        )

    counts: Counter[str] = Counter()
    first_competence: dict[str, str] = {}
    last_competence: dict[str, str] = {}
    length_counts: Counter[int] = Counter()
    char_shape_counts: Counter[str] = Counter()
    files_by_code: defaultdict[str, set[str]] = defaultdict(set)

    total_rows = 0
    blank_rows = 0

    for path in files:
        competence = source_competence(path)

        with open(path, "r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle, delimiter=";")
            if reader.fieldnames is None or "DIAG_PRINC" not in reader.fieldnames:
                raise RuntimeError(f"Campo DIAG_PRINC ausente em {path}")

            for row in reader:
                total_rows += 1
                raw = row["DIAG_PRINC"]
                if raw is None:
                    raw = ""

                counts[raw] += 1
                length_counts[len(raw)] += 1
                files_by_code[raw].add(Path(path).name)

                if raw == "":
                    blank_rows += 1

                if raw.isalnum() and raw.upper() == raw:
                    shape = "UPPER_ALNUM"
                elif raw.isalnum():
                    shape = "ALNUM_OTHER_CASE"
                elif "." in raw:
                    shape = "HAS_DOT"
                elif any(ch.isspace() for ch in raw):
                    shape = "HAS_WHITESPACE"
                else:
                    shape = "OTHER"
                char_shape_counts[shape] += 1

                previous_first = first_competence.get(raw)
                if previous_first is None or competence < previous_first:
                    first_competence[raw] = competence

                previous_last = last_competence.get(raw)
                if previous_last is None or competence > previous_last:
                    last_competence[raw] = competence

    if total_rows != EXPECTED_ROWS:
        raise RuntimeError(
            f"Quantidade de linhas RD divergente: esperado={EXPECTED_ROWS} atual={total_rows}"
        )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with PROFILE_PATH.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "diag_princ_raw",
                "occurrences",
                "raw_length",
                "character_shape",
                "first_competence",
                "last_competence",
                "source_file_count",
            ],
            delimiter=";",
        )
        writer.writeheader()

        for code in sorted(counts):
            if code.isalnum() and code.upper() == code:
                shape = "UPPER_ALNUM"
            elif code.isalnum():
                shape = "ALNUM_OTHER_CASE"
            elif "." in code:
                shape = "HAS_DOT"
            elif any(ch.isspace() for ch in code):
                shape = "HAS_WHITESPACE"
            else:
                shape = "OTHER"

            writer.writerow(
                {
                    "diag_princ_raw": code,
                    "occurrences": counts[code],
                    "raw_length": len(code),
                    "character_shape": shape,
                    "first_competence": first_competence[code],
                    "last_competence": last_competence[code],
                    "source_file_count": len(files_by_code[code]),
                }
            )

    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C2_CID10_INPUT_PROFILE",
        "status": "PASS",
        "input": {
            "file_glob": INPUT_GLOB,
            "files": len(files),
            "rows": total_rows,
            "expected_files": EXPECTED_FILES,
            "expected_rows": EXPECTED_ROWS,
        },
        "diag_princ": {
            "distinct_raw_codes": len(counts),
            "blank_rows": blank_rows,
            "length_counts": {str(k): v for k, v in sorted(length_counts.items())},
            "character_shape_counts": dict(sorted(char_shape_counts.items())),
        },
        "profile": {
            "path": str(PROFILE_PATH),
            "sha256": sha256_file(PROFILE_PATH),
        },
    }

    SUMMARY_PATH.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"RD_FILES={len(files)}")
    print(f"RD_ROWS={total_rows}")
    print(f"DIAG_PRINC_DISTINCT_RAW={len(counts)}")
    print(f"DIAG_PRINC_BLANK_ROWS={blank_rows}")
    print("DIAG_PRINC_LENGTH_COUNTS=" + json.dumps(summary["diag_princ"]["length_counts"], ensure_ascii=False))
    print("DIAG_PRINC_SHAPE_COUNTS=" + json.dumps(summary["diag_princ"]["character_shape_counts"], ensure_ascii=False))
    print(f"PROFILE={PROFILE_PATH}")
    print(f"PROFILE_SHA256={summary['profile']['sha256']}")
    print(f"SUMMARY={SUMMARY_PATH}")
    print("VERDICT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
