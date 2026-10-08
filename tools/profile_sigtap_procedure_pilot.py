#!/usr/bin/env python3
"""C3.3a.1 — piloto de cobertura mensal PROC_REA x CO_PROCEDIMENTO.

Inspeciona apenas os quatro meses previamente materializados do SIGTAP.
Nenhum download, alteração de fontes/QVD ou cobertura T27 integral é realizada.

Saídas locais ignoradas:
- BASE/REFERENCIAS/sigtap_procedure_pilot_coverage.csv
- BASE/REFERENCIAS/sigtap_procedure_pilot_unmatched.csv
- BASE/REFERENCIAS/sigtap_procedure_pilot_summary.json
"""

from __future__ import annotations

import csv
import hashlib
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from materialize_sigtap_procedure_sample import parse_layout, sha256_file

COMPETENCES = ("201701", "201801", "201901", "201912")
ROOT = Path("BASE/REFERENCIAS")
INPUT_ROOT = ROOT / "SIGTAP/PROCEDIMENTO"
RD_ROOT = Path("BASE/CONVERTIDA/RD")
MANIFEST_PATH = ROOT / "sigtap_procedure_sample_manifest.json"
RD_PROFILE_PATH = ROOT / "proc_rea_profile_summary.json"
COVERAGE_PATH = ROOT / "sigtap_procedure_pilot_coverage.csv"
UNMATCHED_PATH = ROOT / "sigtap_procedure_pilot_unmatched.csv"
SUMMARY_PATH = ROOT / "sigtap_procedure_pilot_summary.json"
PROCEDURE_FILE = "tb_procedimento.txt"
LAYOUT_FILE = "tb_procedimento_layout.txt"


def checked_file(path: Path, expected_sha: str) -> bytes:
    if not path.is_file():
        raise RuntimeError(f"Arquivo ausente: {path}")
    if sha256_file(path) != expected_sha:
        raise RuntimeError(f"SHA-256 não corresponde ao manifesto: {path}")
    return path.read_bytes()


def required_column(columns: list[dict], name: str, width: int) -> dict:
    matches = [column for column in columns if column["field"] == name]
    if len(matches) != 1 or matches[0]["width"] != width:
        raise RuntimeError(f"Coluna {name} ausente, duplicada ou com largura inesperada")
    return matches[0]


def field_value(raw: bytes, column: dict) -> bytes:
    return raw[int(column["start"]) - 1:int(column["end"])]


def index_reference(
    competence: str,
    evidence: dict,
) -> tuple[set[str], dict[str, int]]:
    paths = evidence["files"]
    layout_path = INPUT_ROOT / competence / LAYOUT_FILE
    data_path = INPUT_ROOT / competence / PROCEDURE_FILE
    layout = checked_file(layout_path, paths[LAYOUT_FILE]["sha256"])
    data = checked_file(data_path, paths[PROCEDURE_FILE]["sha256"])
    columns = parse_layout(layout, competence)
    co = required_column(columns, "CO_PROCEDIMENTO", 10)
    dt = required_column(columns, "DT_COMPETENCIA", 6)
    expected_width = int(columns[-1]["end"])
    if expected_width != evidence["layout"]["record_width"]:
        raise RuntimeError(f"Largura alterada em {competence}")

    keys: set[str] = set()
    invalid_keys = 0
    bad_lengths = 0
    bad_competence = 0
    duplicates = 0
    rows = 0
    for raw in data.splitlines():
        rows += 1
        if len(raw) != expected_width:
            bad_lengths += 1
            continue
        code_bytes = field_value(raw, co)
        if len(code_bytes) != 10 or not all(48 <= b <= 57 for b in code_bytes):
            invalid_keys += 1
            continue
        value = field_value(raw, dt)
        if value != competence.encode("ascii"):
            bad_competence += 1
            continue
        key = code_bytes.decode("ascii")
        if key in keys:
            duplicates += 1
        else:
            keys.add(key)

    if (
        rows != evidence["data_inspection"]["rows"]
        or len(keys) != evidence["data_inspection"]["distinct_raw_keys"]
        or any((invalid_keys, bad_lengths, bad_competence, duplicates))
    ):
        raise RuntimeError(
            f"Integridade referência {competence}: rows={rows}, "
            f"keys={len(keys)}, bad_length={bad_lengths}, "
            f"bad_key={invalid_keys}, bad_competence={bad_competence}, "
            f"duplicates={duplicates}"
        )
    return keys, {"reference_rows": rows, "reference_distinct": len(keys)}


def profile_rd(competence: str, valid_codes: set[str], expected_rows: int) -> tuple[dict, Counter[str]]:
    path = RD_ROOT / f"RDPB{competence[2:]}.csv"
    if not path.is_file():
        raise RuntimeError(f"CSV RD ausente: {path}")
    total = 0
    matches = 0
    rd_codes: set[str] = set()
    missing: Counter[str] = Counter()

    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        if reader.fieldnames is None or "PROC_REA" not in reader.fieldnames:
            raise RuntimeError(f"Campo PROC_REA não encontrado: {path}")
        for row in reader:
            value = row["PROC_REA"]
            if value is None or len(value) != 10 or not value.isascii() or not value.isdecimal():
                raise RuntimeError(
                    f"Chave PROC_REA inesperada em {path} linha {reader.line_num}: {value!r}"
                )
            total += 1
            rd_codes.add(value)
            if value in valid_codes:
                matches += 1
            else:
                missing[value] += 1

    if total != expected_rows:
        raise RuntimeError(f"RD {competence} diverge do C3.1: {total} vs {expected_rows}")
    return (
        {
            "competence": competence,
            "rd_rows": total,
            "rd_distinct_codes": len(rd_codes),
            "matched_rows": matches,
            "unmatched_rows": total - matches,
            "unmatched_distinct": len(missing),
            "coverage_pct": f"{100 * matches / total:.6f}" if total else "0",
        },
        missing,
    )


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=fields, delimiter=";", lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    if not MANIFEST_PATH.is_file() or not RD_PROFILE_PATH.is_file():
        raise RuntimeError("Manifestos C3.3a e/ou C3.1 não encontrados")
    sample = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    rd_profile = json.loads(RD_PROFILE_PATH.read_text(encoding="utf-8"))
    if (
        sample.get("status") != "PASS"
        or sample.get("stage") != "PHASE_III_C3_3A_PROCEDURE_SAMPLE_LAYOUT_INSPECTION"
        or sample.get("mode") != "CONTROLLED_PROCEDURE_SAMPLE_MATERIALIZATION"
        or sorted(sample.get("selection", [])) != sorted(COMPETENCES)
        or rd_profile.get("status") != "PASS"
        or rd_profile.get("input", {}).get("files") != 36
        or rd_profile.get("input", {}).get("rows") != 566672
    ):
        raise RuntimeError("Manifestos de entrada não estão em PASS ou seleção não esperada")

    monthly_counts = rd_profile["monthly"]["rows_by_competence"]
    grouped: dict[str, list[dict]] = {}
    for item in sample["materialized"]:
        grouped.setdefault(item["competence"], []).append(item)

    coverage_rows: list[dict] = []
    missing_rows: list[dict] = []
    print("MODE=LOCAL_FOUR_COMPETENCE_MATCH_PILOT")
    print("COMPETENCES=" + ",".join(COMPETENCES))
    for competence in COMPETENCES:
        evidence = grouped.get(competence, [])
        if len(evidence) != 1:
            raise RuntimeError(f"Referência ambígua/ausente: {competence}")
        reference_keys, counts = index_reference(competence, evidence[0])
        rd_result, missing = profile_rd(
            competence, reference_keys, int(monthly_counts[competence])
        )
        rd_result.update(counts)
        coverage_rows.append(rd_result)
        for code, occurrences in sorted(missing.items()):
            missing_rows.append(
                {
                    "competence": competence,
                    "proc_rea_raw": code,
                    "unmatched_occurrences": occurrences,
                }
            )
        print(
            f"[{competence}] RD_ROWS={rd_result['rd_rows']} "
            f"MATCHED={rd_result['matched_rows']} "
            f"UNMATCHED={rd_result['unmatched_rows']} "
            f"UNMATCHED_CODES={rd_result['unmatched_distinct']} "
            f"REFERENCE_CODES={counts['reference_distinct']}"
        )

    ROOT.mkdir(parents=True, exist_ok=True)
    write_csv(
        COVERAGE_PATH,
        [
            "competence", "rd_rows", "rd_distinct_codes", "matched_rows",
            "unmatched_rows", "unmatched_distinct", "coverage_pct",
            "reference_rows", "reference_distinct",
        ],
        coverage_rows,
    )
    write_csv(
        UNMATCHED_PATH,
        ["competence", "proc_rea_raw", "unmatched_occurrences"],
        missing_rows,
    )
    total_rd = sum(row["rd_rows"] for row in coverage_rows)
    total_match = sum(row["matched_rows"] for row in coverage_rows)
    total_missing = sum(row["unmatched_rows"] for row in coverage_rows)
    status = "PASS" if total_missing == 0 else "REVIEW"
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C3_3A1_PROCEDURE_FOUR_MONTH_COVERAGE_PILOT",
        "status": status,
        "mode": "LOCAL_FOUR_COMPETENCE_MATCH_PILOT",
        "sample_competences": list(COMPETENCES),
        "totals": {
            "rd_rows": total_rd,
            "matched_rd_rows": total_match,
            "unmatched_rd_rows": total_missing,
            "unmatched_code_competence_pairs": len(missing_rows),
        },
        "monthly": coverage_rows,
        "outputs": {
            "coverage": {
                "path": str(COVERAGE_PATH),
                "sha256": sha256_file(COVERAGE_PATH),
                "rows": len(coverage_rows),
            },
            "unmatched": {
                "path": str(UNMATCHED_PATH),
                "sha256": sha256_file(UNMATCHED_PATH),
                "rows": len(missing_rows),
            },
            "summary": str(SUMMARY_PATH),
        },
        "scope": {
            "full_36_months_checked": False,
            "t27_full_coverage_verified": False,
            "reference_36_months_materialized": False,
            "qvd_written": False,
        },
    }
    SUMMARY_PATH.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("SAMPLE_RD_ROWS=" + str(total_rd))
    print("SAMPLE_MATCHED_RD_ROWS=" + str(total_match))
    print("SAMPLE_UNMATCHED_RD_ROWS=" + str(total_missing))
    print("SAMPLE_UNMATCHED_CODE_MONTH_PAIRS=" + str(len(missing_rows)))
    print("COVERAGE_CSV=" + str(COVERAGE_PATH))
    print("UNMATCHED_CSV=" + str(UNMATCHED_PATH))
    print("SUMMARY=" + str(SUMMARY_PATH))
    print("T27_COVERAGE=PARTIAL_SAMPLE_ONLY")
    print("VERDICT=" + status)
    return 0 if status == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
