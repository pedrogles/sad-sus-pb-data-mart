#!/usr/bin/env python3
"""Pre-Qlik H2 oracle from the immutable AE01 E1 export. Read-only input; new JSON only."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import re

GATE = "SAD-C2-R2-P11-HISTORICAL-CARDS-H1-01"
E1_SHA256 = "F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615"
HEADERS = ["competencia", "ano", "municipio_res", "municipio_serv", "qtd_registro_aih",
           "qtd_internacao", "qtd_continuidade"]
GLOBAL_ANNUAL = {"2017": 183532, "2018": 183311, "2019": 188246}
GLOBAL_TRIENNIUM = 555089
SERVICE_CODE = "250750"
SERVICE_TRIENNIUM = 225785
E1_ROWS = 30255


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--e1", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--repo-root", required=True, type=Path)
    args = p.parse_args()
    source = args.e1.resolve(strict=True)
    output = args.output.resolve()
    root = args.repo_root.resolve(strict=True)
    if source.name != "sih_fluxo_competencia.csv":
        raise SystemExit("BLOCKED_E1_FILENAME")
    if source == output or source.is_relative_to(root) or output.is_relative_to(root):
        raise SystemExit("BLOCKED_SOURCE_OR_OUTPUT_INSIDE_REPO")
    if not output.parent.is_dir() or output.exists():
        raise SystemExit("BLOCKED_OUTPUT_DIRECTORY_OR_COLLISION")
    if sha256(source) != E1_SHA256:
        raise SystemExit("HARD_STOP_E1_SHA256_MISMATCH")

    annual = {year: 0 for year in GLOBAL_ANNUAL}
    svc_annual = {year: 0 for year in GLOBAL_ANNUAL}
    count, jan2019 = 0, 0
    months = set()
    with source.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream, delimiter=";")
        if reader.fieldnames != HEADERS:
            raise SystemExit("BLOCKED_E1_HEADER")
        for row in reader:
            count += 1
            year, month = row["ano"], row["competencia"]
            if year not in annual or not re.fullmatch(r"201[789](0[1-9]|1[0-2])", month):
                raise SystemExit("BLOCKED_E1_TIME_DOMAIN")
            if month[:4] != year:
                raise SystemExit("BLOCKED_E1_YEAR_COMPETENCE_CONFLICT")
            try:
                qty = int(row["qtd_internacao"])
            except (TypeError, ValueError) as e:
                raise SystemExit("BLOCKED_E1_QTY_PARSE") from e
            if qty < 0:
                raise SystemExit("BLOCKED_E1_NEGATIVE")
            annual[year] += qty
            months.add(month)
            if row["municipio_serv"] == SERVICE_CODE:
                svc_annual[year] += qty
                if month == "201901":
                    jan2019 += qty

    if count != E1_ROWS or len(months) != 36:
        raise SystemExit("BLOCKED_E1_ROWS_OR_MONTHS")
    if annual != GLOBAL_ANNUAL or sum(annual.values()) != GLOBAL_TRIENNIUM:
        raise SystemExit("BLOCKED_E1_GLOBAL_TOTALS")
    if sum(svc_annual.values()) != SERVICE_TRIENNIUM or jan2019 <= 0:
        raise SystemExit("BLOCKED_E1_SERVICE_TOTAL_OR_COMPETENCE")
    if sha256(source) != E1_SHA256:
        raise SystemExit("HARD_STOP_E1_CHANGED_DURING_READ")

    result = {
        "gate": GATE,
        "status": "H2_ORACLE_ESTABLISHED_BEFORE_PHYSICAL_TEST",
        "e1_source": str(source),
        "e1_sha256": E1_SHA256,
        "e1_rows": count,
        "e1_competencies": len(months),
        "filter_field": "SERV_COD_DATASUS_6",
        "filter_value": SERVICE_CODE,
        "source_field": "municipio_serv",
        "expected": {
            "TX13": svc_annual["2017"],
            "TX11": svc_annual["2018"],
            "TX12": svc_annual["2019"],
            "TX10": SERVICE_TRIENNIUM,
        },
        "h0_reference": {
            "TX13": GLOBAL_ANNUAL["2017"],
            "TX11": GLOBAL_ANNUAL["2018"],
            "TX12": GLOBAL_ANNUAL["2019"],
            "TX10": GLOBAL_TRIENNIUM,
        },
        "service_value_201901": jan2019,
        "qlik_physical_compatibility": "NOT_TESTED",
        "cross_fact_p5_global": "NOT_APPROVED",
        "provenance": "AE01 E1 independently hashed and aggregated; no QlikView result used",
    }
    with output.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print(json.dumps({
        "verdict": "PASS_H2_ORACLE_PREFLIGHT_ONLY_NOT_QLIK",
        "oracle_path": str(output),
        "oracle_sha256": sha256(output),
        "expected": result["expected"],
        "e1_unchanged": sha256(source) == E1_SHA256,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
