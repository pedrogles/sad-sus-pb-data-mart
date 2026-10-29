#!/usr/bin/env python3
"""P3.2: pinned E1, annual RES=SERV versus RES!=SERV (2017-2019).

Source read-only. Evidence output must be a new directory outside the source
folder and must not be committed. No QlikView, population or cross-fact joins.
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from validate_sad_p13_serv_ranking01 import (
    E1_SHA256, EXPECTED_GROUPS, FIELDS, MONTHS, TOTAL, YEARS,
    require, sha256, share, uint,
)

GATE = "SAD-P32-SIH-RES-SERV-EQUALITY-ANNUAL-READONLY-01"
CLASSES = ("RES_EQ_SERV", "RES_NE_SERV")
EXPECTED_CLASS_NEW = {"RES_EQ_SERV": 294635, "RES_NE_SERV": 260454}
MEASURES = FIELDS[4:]


def validate(source: Path) -> tuple[dict, list[dict]]:
    require(source.is_file() and source.stat().st_size > 0, "E1_SOURCE_UNAVAILABLE")
    before = sha256(source)
    require(before == E1_SHA256, "E1_SHA256_MISMATCH")
    raw = source.read_bytes()
    import hashlib
    require(hashlib.sha256(raw).hexdigest().upper() == before, "SOURCE_CHANGED_ON_READ")

    reader = csv.DictReader(io.StringIO(raw.decode("utf-8-sig"), newline=""),
                            delimiter=";", restkey="__EXTRA__")
    require(tuple(reader.fieldnames or ()) == FIELDS, "E1_SCHEMA_MISMATCH")
    seen, months = set(), set()
    by_year_class, by_month_class = {}, {}
    by_year, by_class, totals = {}, {}, Counter()

    for lineno, row in enumerate(reader, 2):
        require("__EXTRA__" not in row and None not in row and
                all(row[f] is not None and row[f].strip() != "" for f in FIELDS),
                f"MALFORMED_E1_ROW:{lineno}")
        month, year, res, serv = (row[f] for f in FIELDS[:4])
        require(month in MONTHS and year == month[:4], f"PERIOD_MISMATCH:{lineno}")
        require(re.fullmatch(r"[0-9]{6}", res) is not None,
                f"RES_FORMAT:{lineno}")
        require(re.fullmatch(r"25[0-9]{4}", serv) is not None,
                f"SERV_FORMAT:{lineno}")
        grain = (month, res, serv)
        require(grain not in seen, f"DUPLICATE_E1_GRAIN:{lineno}")
        seen.add(grain)
        months.add(month)
        values = {field: uint(row[field], f"{lineno}:{field}")
                  for field in MEASURES}
        require(values["qtd_registro_aih"] > 0 and
                values["qtd_registro_aih"] ==
                values["qtd_internacao"] + values["qtd_continuidade"],
                f"AIH_DECOMPOSITION:{lineno}")
        cls = CLASSES[0] if res == serv else CLASSES[1]
        by_year_class.setdefault((year, cls), Counter()).update(values)
        by_month_class.setdefault((month, cls), Counter()).update(values)
        by_year.setdefault(year, Counter()).update(values)
        by_class.setdefault(cls, Counter()).update(values)
        totals.update(values)

    require(len(seen) == EXPECTED_GROUPS, "SOURCE_GRAIN_COUNT_MISMATCH")
    require(months == MONTHS, "SOURCE_COMPETENCIES_INCOMPLETE")
    require(set(by_year_class) == {(year, cls) for year in YEARS for cls in CLASSES},
            "YEAR_CLASS_COVERAGE_MISMATCH")
    require({year: by_year[year]["qtd_internacao"] for year in YEARS} == YEARS,
            "YEAR_NEW_ADMISSIONS_MISMATCH")
    expected_total = {"qtd_registro_aih": TOTAL["registros"],
                      "qtd_internacao": TOTAL["internacoes"],
                      "qtd_continuidade": TOTAL["continuidades"]}
    require(dict(totals) == expected_total, "TRIENNIAL_TOTALS_MISMATCH")
    require({cls: by_class[cls]["qtd_internacao"] for cls in CLASSES}
            == EXPECTED_CLASS_NEW, "TRIENNIAL_EQUALITY_SPLIT_MISMATCH")
    for field in MEASURES:
        require(sum(by_year[year][field] for year in YEARS) == totals[field],
                f"YEAR_RECONCILIATION:{field}")
        require(sum(by_class[cls][field] for cls in CLASSES) == totals[field],
                f"CLASS_RECONCILIATION:{field}")
        for year in YEARS:
            require(sum(by_year_class[(year, cls)][field] for cls in CLASSES)
                    == by_year[year][field], f"YEAR_CLASS_SUM:{year}:{field}")
            require(sum(by_month_class.get((f"{year}{m:02d}", cls), Counter())[field]
                        for m in range(1, 13) for cls in CLASSES)
                    == by_year[year][field], f"MONTHLY_SUM:{year}:{field}")
    require(share(by_class[CLASSES[1]]["qtd_internacao"],
                  totals["qtd_internacao"], places=2) == "46.92",
            "TRIENNIAL_SHARE_MISMATCH")

    after = sha256(source)
    require(before == after, "SOURCE_CHANGED_AFTER_READ")
    records = [
        {"ano": year, "classe_res_serv": cls,
         **{field: by_year_class[(year, cls)][field] for field in MEASURES},
         "participacao_ano_percentual": share(
             by_year_class[(year, cls)]["qtd_internacao"],
             by_year[year]["qtd_internacao"])}
        for year in YEARS for cls in CLASSES
    ]
    audit = {
        "source": {"path": str(source), "sha256_before": before,
                   "sha256_after": after, "size_bytes": len(raw)},
        "schema": list(FIELDS), "source_unique_grains": len(seen),
        "duplicate_grains": 0, "competencies": len(months),
        "annual_new_admissions": {y: by_year[y]["qtd_internacao"] for y in YEARS},
        "class_new_admissions": {c: by_class[c]["qtd_internacao"] for c in CLASSES},
        "triennial_res_ne_serv_percent": share(
            by_class[CLASSES[1]]["qtd_internacao"], totals["qtd_internacao"]),
        "totals": dict(totals),
        "annual_rows": len(records),
        "limitations": [
            "Classification compares raw municipality codes, without geographic labels",
            "RES!=SERV is not proof of an individual's physical travel",
            "Residents outside PB remain included; no PB population denominator",
            "IDENT=5 continuation not counted in qtd_internacao",
            "SIH/RD administrative production is not unique patients or unmet demand",
            "No QlikView UI, cross-fact filters, or production validation",
        ],
        "divergences": [],
    }
    return audit, records


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--e1", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--source-commit", required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    source, out = args.e1.resolve(), args.output_dir.resolve()
    require(out != source and out != source.parent and source.parent not in out.parents,
            "EVIDENCE_MUST_BE_OUTSIDE_SOURCE_DIRECTORY")
    require(re.fullmatch(r"[0-9a-f]{40}", args.source_commit) is not None,
            "SOURCE_COMMIT_FORMAT")
    scripts = ["tools/validate_sad_p32_res_serv_equality01.py",
               "tools/validate_sad_p13_serv_ranking01.py"]
    for script in scripts:
        subprocess.run(["git", "cat-file", "-e", f"{args.source_commit}:{script}"],
                       cwd=repo, check=True)
    subprocess.run(["git", "diff", "--exit-code", args.source_commit, "--", *scripts],
                   cwd=repo, check=True)
    out.mkdir(parents=True, exist_ok=False)
    audit = {
        "gate": GATE, "verdict": "INCONCLUSIVE", "GATE_PASS": False,
        "PR_MERGED": False, "PRODUCTION_APPROVED": False,
        "execution": {
            "source_commit": args.source_commit, "python": sys.version,
            "utc": datetime.now(timezone.utc).isoformat(),
            "script_sha256": {script: sha256(repo / script) for script in scripts},
        },
    }
    exit_code = 2
    try:
        detail, records = validate(source)
        audit.update(detail)
        matrix = out / "p32_res_serv_annual.csv"
        fields = ("ano", "classe_res_serv", *MEASURES, "participacao_ano_percentual")
        with matrix.open("x", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields, delimiter=";")
            writer.writeheader()
            writer.writerows(records)
        with matrix.open("r", encoding="utf-8", newline="") as stream:
            readback = list(csv.DictReader(stream, delimiter=";"))
        require(readback == [{k: str(v) for k, v in record.items()}
                             for record in records], "CSV_READBACK_MISMATCH")
        negative = out / "negative_e1_altered.csv"
        negative.write_bytes(source.read_bytes() + b"\n")
        rejected = False
        try:
            validate(negative)
        except ValueError as error:
            rejected = str(error) == "E1_SHA256_MISMATCH"
            audit["negative_test"] = {
                "mutation": "append LF to a copy", "error": str(error),
                "rejected": rejected, "copy_sha256": sha256(negative)}
        require(rejected, "NEGATIVE_COPY_NOT_REJECTED")
        require(sha256(source) == E1_SHA256, "SOURCE_CHANGED_AFTER_NEGATIVE")
        audit.update(verdict="PASS_RESTRICTED", GATE_PASS=True,
                     csv_sha256=sha256(matrix))
        exit_code = 0
    except (OSError, UnicodeError, csv.Error) as error:
        audit.update(verdict="BLOCKED", error=str(error))
    except ValueError as error:
        audit.update(verdict="INCONCLUSIVE_HARD_STOP", error=str(error))
    audit["exit_code"] = exit_code
    encoded = json.dumps(audit, indent=2, ensure_ascii=False) + "\n"
    (out / "p32_audit.json").write_text(encoded, encoding="utf-8")
    (out / "execution.log").write_text(encoded, encoding="utf-8")
    manifest = {p.name: sha256(p) for p in sorted(out.iterdir()) if p.is_file()}
    (out / "sha256_manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(encoded)
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
