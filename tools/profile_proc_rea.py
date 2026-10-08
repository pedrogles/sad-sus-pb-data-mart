#!/usr/bin/env python3
"""Perfil read-only de PROC_REA nos 36 CSVs SIH/RD (2017-2019).

Fase III-C3.1: inventário físico dos códigos observados antes do lookup SIGTAP.
Não baixa SIGTAP, não modifica CSVs e não produz QVDs.

Saídas locais ignoradas pelo Git:
- BASE/REFERENCIAS/proc_rea_raw_profile.csv
- BASE/REFERENCIAS/proc_rea_monthly_profile.csv
- BASE/REFERENCIAS/proc_rea_profile_summary.json
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

INPUT_DIR = Path("BASE/CONVERTIDA/RD")
OUTPUT_DIR = Path("BASE/REFERENCIAS")
RAW_PROFILE_PATH = OUTPUT_DIR / "proc_rea_raw_profile.csv"
MONTHLY_PROFILE_PATH = OUTPUT_DIR / "proc_rea_monthly_profile.csv"
SUMMARY_PATH = OUTPUT_DIR / "proc_rea_profile_summary.json"
EXPECTED_FILES = 36
EXPECTED_ROWS = 566_672
EXPECTED_COMPETENCES = {
    f"{year}{month:02d}"
    for year in (2017, 2018, 2019)
    for month in range(1, 13)
}
RD_PATTERN = re.compile(
    r"^RDPB(?P<year>17|18|19)(?P<month>0[1-9]|1[0-2])\.csv$",
    re.IGNORECASE,
)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def source_competence(path: Path) -> str:
    match = RD_PATTERN.fullmatch(path.name)
    if match is None:
        raise RuntimeError(f"Nome de arquivo RD fora do contrato: {path.name}")
    return f"20{match.group('year')}{match.group('month')}"


def shape_of(raw: str) -> str:
    if raw == "":
        return "EMPTY"
    if len(raw) == 10 and raw.isascii() and raw.isdecimal():
        return "TEN_ASCII_DIGITS"
    if raw.isascii() and raw.isdecimal():
        return "OTHER_LENGTH_ASCII_DIGITS"
    if any(char.isspace() for char in raw):
        return "HAS_WHITESPACE"
    if raw.isascii() and raw.isalnum():
        return "ASCII_ALPHANUMERIC"
    return "OTHER"


def list_rd_files() -> list[tuple[str, Path]]:
    if not INPUT_DIR.is_dir():
        raise RuntimeError(f"Diretório de entrada ausente: {INPUT_DIR}")

    candidates = sorted(
        (
            path
            for path in INPUT_DIR.iterdir()
            if path.is_file() and path.name.upper().startswith("RDPB")
        ),
        key=lambda path: path.name.upper(),
    )
    if len(candidates) != EXPECTED_FILES:
        raise RuntimeError(
            f"Quantidade de arquivos RD inesperada: {len(candidates)}; "
            f"esperado={EXPECTED_FILES}"
        )

    by_competence: dict[str, Path] = {}
    for path in candidates:
        competence = source_competence(path)
        if competence in by_competence:
            raise RuntimeError(
                f"Competência RD duplicada: {competence} "
                f"({by_competence[competence]} e {path})"
            )
        by_competence[competence] = path

    missing = sorted(EXPECTED_COMPETENCES - set(by_competence))
    extra = sorted(set(by_competence) - EXPECTED_COMPETENCES)
    if missing or extra:
        raise RuntimeError(
            f"Competências RD divergentes: missing={missing}, extra={extra}"
        )
    return sorted(by_competence.items())


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=fields, delimiter=";", lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    files = list_rd_files()

    counts: Counter[str] = Counter()
    length_rows: Counter[int] = Counter()
    shape_rows: Counter[str] = Counter()
    first_seen: dict[str, str] = {}
    last_seen: dict[str, str] = {}
    code_competences: defaultdict[str, set[str]] = defaultdict(set)
    monthly_profile: list[dict[str, object]] = []
    total_rows = 0
    zero_prefix_rows = 0

    for competence, path in files:
        month_counts: Counter[str] = Counter()
        month_shapes: Counter[str] = Counter()
        month_rows = 0
        month_zero_prefix = 0

        with path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle, delimiter=";")
            if reader.fieldnames is None or "PROC_REA" not in reader.fieldnames:
                raise RuntimeError(f"Campo PROC_REA ausente: {path}")

            for row in reader:
                raw = row["PROC_REA"]
                if raw is None:
                    raise RuntimeError(
                        f"PROC_REA ausente em registro de {path.name} "
                        f"(linha física aproximada {reader.line_num})"
                    )

                month_rows += 1
                total_rows += 1
                counts[raw] += 1
                month_counts[raw] += 1
                length_rows[len(raw)] += 1

                shape = shape_of(raw)
                shape_rows[shape] += 1
                month_shapes[shape] += 1
                if raw.startswith("0"):
                    zero_prefix_rows += 1
                    month_zero_prefix += 1

                code_competences[raw].add(competence)
                if raw not in first_seen or competence < first_seen[raw]:
                    first_seen[raw] = competence
                if raw not in last_seen or competence > last_seen[raw]:
                    last_seen[raw] = competence

        monthly_profile.append(
            {
                "competence": competence,
                "source_file": path.name,
                "rd_rows": month_rows,
                "proc_rea_distinct_raw": len(month_counts),
                "ten_digit_rows": month_shapes["TEN_ASCII_DIGITS"],
                "nonconforming_rows": (
                    month_rows - month_shapes["TEN_ASCII_DIGITS"]
                ),
                "leading_zero_rows": month_zero_prefix,
            }
        )

    if total_rows != EXPECTED_ROWS:
        raise RuntimeError(
            f"Quantidade de linhas RD divergente: {total_rows}; "
            f"esperado={EXPECTED_ROWS}"
        )

    raw_profile: list[dict[str, object]] = []
    for raw, occurrences in sorted(counts.items()):
        raw_profile.append(
            {
                "proc_rea_raw": raw,
                "occurrences": occurrences,
                "raw_length": len(raw),
                "character_shape": shape_of(raw),
                "first_competence": first_seen[raw],
                "last_competence": last_seen[raw],
                "competences_observed": len(code_competences[raw]),
            }
        )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    write_csv(
        RAW_PROFILE_PATH,
        [
            "proc_rea_raw", "occurrences", "raw_length",
            "character_shape", "first_competence", "last_competence",
            "competences_observed",
        ],
        raw_profile,
    )
    write_csv(
        MONTHLY_PROFILE_PATH,
        [
            "competence", "source_file", "rd_rows",
            "proc_rea_distinct_raw", "ten_digit_rows",
            "nonconforming_rows", "leading_zero_rows",
        ],
        monthly_profile,
    )

    nonconforming_rows = total_rows - shape_rows["TEN_ASCII_DIGITS"]
    verdict = "PASS" if nonconforming_rows == 0 else "REVIEW"
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C3_1_PROC_REA_INPUT_PROFILE",
        "status": verdict,
        "mode": "READ_ONLY_INPUT_PROFILING",
        "input": {
            "directory": str(INPUT_DIR),
            "files": len(files),
            "rows": total_rows,
            "expected_files": EXPECTED_FILES,
            "expected_rows": EXPECTED_ROWS,
            "competences": len(monthly_profile),
            "first_competence": monthly_profile[0]["competence"],
            "last_competence": monthly_profile[-1]["competence"],
        },
        "proc_rea": {
            "distinct_raw_codes": len(counts),
            "blank_rows": shape_rows["EMPTY"],
            "ten_digit_rows": shape_rows["TEN_ASCII_DIGITS"],
            "nonconforming_rows": nonconforming_rows,
            "leading_zero_rows": zero_prefix_rows,
            "length_counts": {
                str(k): v for k, v in sorted(length_rows.items())
            },
            "character_shape_counts": dict(sorted(shape_rows.items())),
        },
        "monthly": {
            "rows_by_competence": {
                str(row["competence"]): row["rd_rows"]
                for row in monthly_profile
            },
            "distinct_by_competence": {
                str(row["competence"]): row["proc_rea_distinct_raw"]
                for row in monthly_profile
            },
        },
        "outputs": {
            "raw_profile": {
                "path": str(RAW_PROFILE_PATH),
                "sha256": sha256_file(RAW_PROFILE_PATH),
                "rows": len(raw_profile),
            },
            "monthly_profile": {
                "path": str(MONTHLY_PROFILE_PATH),
                "sha256": sha256_file(MONTHLY_PROFILE_PATH),
                "rows": len(monthly_profile),
            },
            "summary": str(SUMMARY_PATH),
        },
        "scope": {
            "sigtap_lookup_performed": False,
            "t27_coverage_verified": False,
        },
    }
    SUMMARY_PATH.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("MODE=READ_ONLY_INPUT_PROFILING")
    print(f"RD_FILES={len(files)}")
    print(f"RD_ROWS={total_rows}")
    print(f"RD_COMPETENCES={len(monthly_profile)}")
    print(f"PROC_REA_DISTINCT_RAW={len(counts)}")
    print(f"PROC_REA_BLANK_ROWS={shape_rows['EMPTY']}")
    print(f"PROC_REA_TEN_DIGIT_ROWS={shape_rows['TEN_ASCII_DIGITS']}")
    print(f"PROC_REA_NONCONFORMING_ROWS={nonconforming_rows}")
    print(f"PROC_REA_LEADING_ZERO_ROWS={zero_prefix_rows}")
    print("PROC_REA_LENGTH_COUNTS=" +
          json.dumps(summary["proc_rea"]["length_counts"], ensure_ascii=False))
    print("PROC_REA_SHAPE_COUNTS=" +
          json.dumps(
              summary["proc_rea"]["character_shape_counts"],
              ensure_ascii=False,
          ))
    print(f"RAW_PROFILE={RAW_PROFILE_PATH}")
    print(f"RAW_PROFILE_SHA256={summary['outputs']['raw_profile']['sha256']}")
    print(f"MONTHLY_PROFILE={MONTHLY_PROFILE_PATH}")
    print(f"MONTHLY_PROFILE_SHA256={summary['outputs']['monthly_profile']['sha256']}")
    print(f"SUMMARY={SUMMARY_PATH}")
    print("T27_COVERAGE=NOT_EVALUATED")
    print(f"VERDICT={verdict}")
    return 0 if verdict == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
