#!/usr/bin/env python3
"""III-C4.1 — perfil read-only dos códigos de leito observados no CNES/LT.

Inspeciona as 36 competências convertidas (2017–2019) antes de obter
referência oficial de TP_LEITO/CODLEITO. Preserva códigos textuais exatos
e registra pares observados sem inferir descrição nem hierarquia normativa.

Entradas não modificadas: BASE/CONVERTIDA/LT/LTPBYYMM.csv.
Saídas locais ignoradas pelo Git:
- BASE/REFERENCIAS/cnes_lt_bed_code_monthly_profile.csv
- BASE/REFERENCIAS/cnes_lt_bed_code_pair_profile.csv
- BASE/REFERENCIAS/cnes_lt_bed_code_profile_summary.json

Não mede cobertura T29, não consulta rede e não escreve QVD.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

INPUT_DIR = Path("BASE/CONVERTIDA/LT")
OUTPUT_DIR = Path("BASE/REFERENCIAS")
MONTHLY_PATH = OUTPUT_DIR / "cnes_lt_bed_code_monthly_profile.csv"
PAIRS_PATH = OUTPUT_DIR / "cnes_lt_bed_code_pair_profile.csv"
SUMMARY_PATH = OUTPUT_DIR / "cnes_lt_bed_code_profile_summary.json"
COMPETENCES = tuple(
    f"{year}{month:02d}"
    for year in (2017, 2018, 2019)
    for month in range(1, 13)
)
FILE_PATTERN = re.compile(
    r"^LTPB(?P<year>17|18|19)(?P<month>0[1-9]|1[0-2])\.csv$",
    re.IGNORECASE,
)
REQUIRED_FIELDS = ("TP_LEITO", "CODLEITO", "COMPETEN")
EXPECTED_ROWS = 35_518


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_csv(path: Path, columns: list[str], rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=columns, delimiter=";", lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)


def discover_files() -> dict[str, Path]:
    if not INPUT_DIR.is_dir():
        raise RuntimeError(f"Diretório CNES/LT ausente: {INPUT_DIR}")
    paths = sorted(
        (p for p in INPUT_DIR.iterdir()
         if p.is_file() and p.name.upper().startswith("LTPB")),
        key=lambda p: p.name.upper(),
    )
    if len(paths) != 36:
        raise RuntimeError(f"CNES/LT: esperados 36 arquivos; encontrados {len(paths)}")
    found: dict[str, Path] = {}
    for path in paths:
        match = FILE_PATTERN.fullmatch(path.name)
        if match is None:
            raise RuntimeError(f"CNES/LT: nome de arquivo inesperado: {path.name}")
        competence = f"20{match['year']}{match['month']}"
        if competence in found:
            raise RuntimeError(f"CNES/LT: competência duplicada: {competence}")
        found[competence] = path
    if set(found) != set(COMPETENCES):
        raise RuntimeError(
            f"CNES/LT: lacunas={sorted(set(COMPETENCES)-set(found))}; "
            f"extras={sorted(set(found)-set(COMPETENCES))}"
        )
    return found


def code_shape(code: str) -> str:
    if code == "":
        return "BLANK"
    if code.isascii() and code.isdecimal():
        return "ASCII_DIGITS"
    if code.isascii() and code.isalnum():
        return "ASCII_ALPHANUMERIC"
    if any(char.isspace() for char in code):
        return "WHITESPACE"
    return "OTHER"


def main() -> int:
    files = discover_files()
    monthly: list[dict] = []
    pair_counts: Counter[tuple[str, str]] = Counter()
    pair_months: defaultdict[tuple[str, str], set[str]] = defaultdict(set)
    pair_first: dict[tuple[str, str], str] = {}
    pair_last: dict[tuple[str, str], str] = {}
    type_counts: Counter[str] = Counter()
    code_counts: Counter[str] = Counter()
    type_lengths: Counter[int] = Counter()
    code_lengths: Counter[int] = Counter()
    type_shapes: Counter[str] = Counter()
    code_shapes: Counter[str] = Counter()
    code_to_types: defaultdict[str, set[str]] = defaultdict(set)
    all_rows = 0
    competence_mismatches = 0

    print("MODE=READ_ONLY_CNES_LT_BED_CODE_PROFILING")
    for competence in COMPETENCES:
        path = files[competence]
        rows = 0
        month_types: set[str] = set()
        month_codes: set[str] = set()
        month_pairs: set[tuple[str, str]] = set()
        month_blank_type = 0
        month_blank_code = 0
        month_bad_competence = 0

        with path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle, delimiter=";")
            fields = reader.fieldnames or []
            if any(fields.count(field) != 1 for field in REQUIRED_FIELDS):
                raise RuntimeError(
                    f"Campos obrigatórios ausentes/duplicados em {path.name}: {fields}"
                )
            for row in reader:
                kind = row["TP_LEITO"]
                code = row["CODLEITO"]
                month_raw = row["COMPETEN"]
                if kind is None or code is None or month_raw is None:
                    raise RuntimeError(
                        f"CNES/LT: registro com coluna ausente: "
                        f"{path.name}:{reader.line_num}"
                    )

                rows += 1
                all_rows += 1
                type_counts[kind] += 1
                code_counts[code] += 1
                type_lengths[len(kind)] += 1
                code_lengths[len(code)] += 1
                type_shapes[code_shape(kind)] += 1
                code_shapes[code_shape(code)] += 1
                if kind == "":
                    month_blank_type += 1
                if code == "":
                    month_blank_code += 1

                # Perfil compara a competência física sem alterar o original.
                trimmed = month_raw.strip()
                if (
                    not trimmed.isascii()
                    or not trimmed.isdecimal()
                    or trimmed.zfill(6) != competence
                ):
                    competence_mismatches += 1
                    month_bad_competence += 1

                pair = (kind, code)
                pair_counts[pair] += 1
                pair_months[pair].add(competence)
                if pair not in pair_first:
                    pair_first[pair] = competence
                pair_last[pair] = competence
                code_to_types[code].add(kind)
                month_types.add(kind)
                month_codes.add(code)
                month_pairs.add(pair)

        monthly.append({
            "competence": competence,
            "source_file": path.name,
            "lt_rows": rows,
            "distinct_tp_leito": len(month_types),
            "distinct_codleito": len(month_codes),
            "distinct_type_code_pairs": len(month_pairs),
            "blank_tp_leito_rows": month_blank_type,
            "blank_codleito_rows": month_blank_code,
            "competence_mismatch_rows": month_bad_competence,
        })
        print(
            f"[{competence}] LT_ROWS={rows} "
            f"TP_LEITO_DISTINCT={len(month_types)} "
            f"CODLEITO_DISTINCT={len(month_codes)} "
            f"PAIR_DISTINCT={len(month_pairs)} "
            f"BLANKS={month_blank_type + month_blank_code} "
            f"COMPETENCE_MISMATCH={month_bad_competence}"
        )

    if all_rows != EXPECTED_ROWS:
        raise RuntimeError(
            f"CNES/LT linhas divergentes: {all_rows}; esperado={EXPECTED_ROWS}"
        )

    pair_rows: list[dict] = []
    for (kind, code), occurrences in sorted(pair_counts.items()):
        pair_rows.append({
            "tp_leito_raw": kind,
            "codleito_raw": code,
            "occurrences": occurrences,
            "first_competence": pair_first[(kind, code)],
            "last_competence": pair_last[(kind, code)],
            "competences_observed": len(pair_months[(kind, code)]),
            "tp_leito_length": len(kind),
            "codleito_length": len(code),
            "tp_leito_shape": code_shape(kind),
            "codleito_shape": code_shape(code),
        })

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    write_csv(
        MONTHLY_PATH,
        [
            "competence", "source_file", "lt_rows",
            "distinct_tp_leito", "distinct_codleito",
            "distinct_type_code_pairs",
            "blank_tp_leito_rows", "blank_codleito_rows",
            "competence_mismatch_rows",
        ],
        monthly,
    )
    write_csv(
        PAIRS_PATH,
        [
            "tp_leito_raw", "codleito_raw", "occurrences",
            "first_competence", "last_competence",
            "competences_observed", "tp_leito_length", "codleito_length",
            "tp_leito_shape", "codleito_shape",
        ],
        pair_rows,
    )

    multiple_type_codes = {
        code: sorted(kinds) for code, kinds in code_to_types.items()
        if len(kinds) > 1
    }
    blank_types = type_shapes["BLANK"]
    blank_codes = code_shapes["BLANK"]
    verdict = "PASS" if (
        blank_types == 0 and blank_codes == 0
        and competence_mismatches == 0
    ) else "REVIEW"
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C4_1_CNES_LT_RAW_BED_CODE_PROFILE",
        "status": verdict,
        "mode": "READ_ONLY_INPUT_PROFILING",
        "input": {
            "directory": str(INPUT_DIR),
            "files": len(files),
            "rows": all_rows,
            "competences": len(monthly),
        },
        "observed_codes": {
            "tp_leito_distinct": len(type_counts),
            "codleito_distinct": len(code_counts),
            "type_code_pairs_distinct": len(pair_counts),
            "blank_tp_leito_rows": blank_types,
            "blank_codleito_rows": blank_codes,
            "competence_mismatch_rows": competence_mismatches,
            "codleito_values_with_multiple_tp_leito": len(multiple_type_codes),
            "multiple_type_examples": [
                {"codleito_raw": code, "tp_leito_values": kinds}
                for code, kinds in sorted(multiple_type_codes.items())[:20]
            ],
            "tp_leito_length_counts": {
                str(k): v for k,v in sorted(type_lengths.items())
            },
            "codleito_length_counts": {
                str(k): v for k,v in sorted(code_lengths.items())
            },
            "tp_leito_shape_counts": dict(sorted(type_shapes.items())),
            "codleito_shape_counts": dict(sorted(code_shapes.items())),
        },
        "outputs": {
            "monthly": {
                "path": str(MONTHLY_PATH),
                "rows": len(monthly),
                "sha256": sha256_file(MONTHLY_PATH),
            },
            "pairs": {
                "path": str(PAIRS_PATH),
                "rows": len(pair_rows),
                "sha256": sha256_file(PAIRS_PATH),
            },
        },
        "scope": {
            "official_cnes_reference_acquired": False,
            "t29_coverage_evaluated": False,
            "qvd_written": False,
            "dimension_implemented": False,
        },
    }
    SUMMARY_PATH.write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print("LT_FILES=" + str(len(files)))
    print("LT_ROWS=" + str(all_rows))
    print("LT_COMPETENCES=" + str(len(monthly)))
    print("TP_LEITO_DISTINCT_RAW=" + str(len(type_counts)))
    print("CODLEITO_DISTINCT_RAW=" + str(len(code_counts)))
    print("TYPE_CODE_PAIRS_DISTINCT=" + str(len(pair_counts)))
    print("CODLEITO_MULTIPLE_TP_LEITO=" + str(len(multiple_type_codes)))
    print("BLANK_TP_LEITO_ROWS=" + str(blank_types))
    print("BLANK_CODLEITO_ROWS=" + str(blank_codes))
    print("COMPETENCE_MISMATCH_ROWS=" + str(competence_mismatches))
    print("MONTHLY_PROFILE=" + str(MONTHLY_PATH))
    print("MONTHLY_PROFILE_SHA256=" + sha256_file(MONTHLY_PATH))
    print("PAIR_PROFILE=" + str(PAIRS_PATH))
    print("PAIR_PROFILE_SHA256=" + sha256_file(PAIRS_PATH))
    print("SUMMARY=" + str(SUMMARY_PATH))
    print("T29_COVERAGE=NOT_EVALUATED")
    print("VERDICT=" + verdict)
    return 0 if verdict == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
