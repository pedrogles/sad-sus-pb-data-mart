#!/usr/bin/env python3
"""P3.4: annual external-PB-residence counts from pinned E1 and C5.2 reference.

External means RES code absent from the 223 validated PB DATASUS6 codes.
This is an observational classification, not a nationwide location lookup.
Input files are read-only; all derived outputs live outside source and Git.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from audit_municipal_pb_crosswalk import COLUMNS, rows_from_csv, validate_pairs
from validate_sad_p13_serv_ranking01 import (
    E1_SHA256, EXPECTED_GROUPS, FIELDS, MONTHS, TOTAL, YEARS,
    require, sha256, share, uint,
)

GATE = "SAD-P34-SIH-EXTERNAL-RESIDENCE-ANNUAL-READONLY-01"
C52_SHA256 = "FDF016E4EAF7A7B8B396D3908DA2EC6737944BC9AAF3E6018BADB763725C257D"
MEASURES = FIELDS[4:]
CLASSES = ("RES_PB_C52", "RES_FORA_PB_C52")
EXPECTED_EXTERNAL = {
    "qtd_registro_aih": 5202,
    "qtd_internacao": 5067,
    "qtd_continuidade": 135,
}


def validate(e1: Path, reference: Path) -> tuple[dict, list[dict], list[dict]]:
    require(e1.is_file() and e1.stat().st_size > 0, "E1_SOURCE_UNAVAILABLE")
    require(reference.is_file() and reference.stat().st_size > 0,
            "C52_REFERENCE_UNAVAILABLE")
    e1_before, c52_before = sha256(e1), sha256(reference)
    require(e1_before == E1_SHA256, "E1_SHA256_MISMATCH")
    require(c52_before == C52_SHA256, "C52_SHA256_MISMATCH")
    source_raw, c52_raw = e1.read_bytes(), reference.read_bytes()
    require(hashlib.sha256(source_raw).hexdigest().upper() == e1_before,
            "E1_CHANGED_DURING_READ")
    require(hashlib.sha256(c52_raw).hexdigest().upper() == c52_before,
            "C52_CHANGED_DURING_READ")

    # Reuse the approved C5.2 column/metadata and unique-pair validator.
    c52_rows = rows_from_csv(reference, COLUMNS)
    validate_pairs(c52_rows)
    pb_codes = {row["COD_DATASUS_6"] for row in c52_rows}
    require(len(pb_codes) == 223, "C52_EXPECTED_223_CODES")

    reader = csv.DictReader(
        io.StringIO(source_raw.decode("utf-8-sig"), newline=""),
        delimiter=";", restkey="__EXTRA__",
    )
    require(tuple(reader.fieldnames or ()) == FIELDS, "E1_SCHEMA_MISMATCH")
    seen, months = set(), set()
    source_totals, source_years = Counter(), {}
    by_year_class, by_class, class_rows = {}, {}, Counter()
    external_res_codes = set()
    for line, row in enumerate(reader, 2):
        require("__EXTRA__" not in row and None not in row and
                all(row[f] is not None and row[f].strip() != "" for f in FIELDS),
                f"MALFORMED_E1_ROW:{line}")
        month, year, res, serv = (row[k] for k in FIELDS[:4])
        require(month in MONTHS and year == month[:4],
                f"PERIOD_MISMATCH:{line}")
        require(re.fullmatch(r"[0-9]{6}", res) is not None,
                f"RES_CODE_FORMAT:{line}")
        require(re.fullmatch(r"25[0-9]{4}", serv) is not None,
                f"SERV_CODE_FORMAT:{line}")
        grain = (month, res, serv)
        require(grain not in seen, f"DUPLICATE_E1_GRAIN:{line}")
        seen.add(grain)
        months.add(month)

        values = {k: uint(row[k], f"{line}:{k}") for k in MEASURES}
        require(values["qtd_registro_aih"] > 0 and
                values["qtd_registro_aih"] ==
                values["qtd_internacao"] + values["qtd_continuidade"],
                f"AIH_DECOMPOSITION:{line}")
        if res.startswith("25"):
            require(res in pb_codes, f"PB_RES_NOT_COVERED_BY_C52:{line}")
        cls = CLASSES[0] if res in pb_codes else CLASSES[1]
        if cls == CLASSES[1]:
            external_res_codes.add(res)
        source_totals.update(values)
        source_years.setdefault(year, Counter()).update(values)
        by_class.setdefault(cls, Counter()).update(values)
        by_year_class.setdefault((year, cls), Counter()).update(values)
        class_rows[cls] += 1

    require(len(seen) == EXPECTED_GROUPS, "E1_GRAIN_COUNT_MISMATCH")
    require(months == MONTHS, "E1_36_COMPETENCIES_INCOMPLETE")
    require({y: source_years[y]["qtd_internacao"] for y in YEARS} == YEARS,
            "E1_ANNUAL_NEW_MISMATCH")
    require(dict(source_totals) == {
        "qtd_registro_aih": TOTAL["registros"],
        "qtd_internacao": TOTAL["internacoes"],
        "qtd_continuidade": TOTAL["continuidades"],
    }, "E1_TOTALS_MISMATCH")
    require(set(by_year_class) == {(y, cls) for y in YEARS for cls in CLASSES},
            "ANNUAL_RESIDENCE_CLASS_INCOMPLETE")
    require(dict(by_class[CLASSES[1]]) == EXPECTED_EXTERNAL,
            "C52_EXTERNAL_TOTALS_MISMATCH")

    for field in MEASURES:
        require(sum(by_class[c][field] for c in CLASSES) == source_totals[field],
                f"CLASS_TOTAL_RECONCILIATION:{field}")
        for y in YEARS:
            require(sum(by_year_class[(y, c)][field] for c in CLASSES)
                    == source_years[y][field],
                    f"YEAR_CLASS_RECONCILIATION:{y}:{field}")
        require(sum(by_year_class[(y, CLASSES[1])][field] for y in YEARS)
                == EXPECTED_EXTERNAL[field],
                f"EXTERNAL_TRIENNIAL_RECONCILIATION:{field}")

    e1_after, c52_after = sha256(e1), sha256(reference)
    require(e1_after == e1_before, "E1_CHANGED_AFTER_READ")
    require(c52_after == c52_before, "C52_CHANGED_AFTER_READ")

    all_annual = [
        {
            "ano": y, "classe_residencia": cls,
            **{k: by_year_class[(y, cls)][k] for k in MEASURES},
            "participacao_novas_no_ano_percentual":
                share(by_year_class[(y, cls)]["qtd_internacao"],
                      source_years[y]["qtd_internacao"]),
        }
        for y in YEARS for cls in CLASSES
    ]
    external_annual = [
        {"ano": y,
         **{k: by_year_class[(y, CLASSES[1])][k] for k in MEASURES},
         "participacao_novas_no_ano_percentual": share(
             by_year_class[(y, CLASSES[1])]["qtd_internacao"],
             source_years[y]["qtd_internacao"]),
        }
        for y in YEARS
    ]
    audit = {
        "e1": {"path": str(e1), "sha256_before": e1_before,
               "sha256_after": e1_after, "size_bytes": len(source_raw)},
        "c52": {"path": str(reference), "sha256_before": c52_before,
                "sha256_after": c52_after, "size_bytes": len(c52_raw),
                "rows": len(c52_rows), "distinct_datasus6": len(pb_codes),
                "reference_scope": "PB_ONLY_PROJECT_DERIVED_FROM_OFFICIAL_IBGE"},
        "source_grains": len(seen), "competencies": len(months),
        "source_new_by_year": {y: source_years[y]["qtd_internacao"] for y in YEARS},
        "source_total": dict(source_totals),
        "external_new_by_year": {
            y: by_year_class[(y, CLASSES[1])]["qtd_internacao"] for y in YEARS
        },
        "external_record_by_year": {
            y: by_year_class[(y, CLASSES[1])]["qtd_registro_aih"] for y in YEARS
        },
        "external_total": dict(by_class[CLASSES[1]]),
        "pb_total": dict(by_class[CLASSES[0]]),
        "source_e1_rows_by_class": dict(class_rows),
        "distinct_external_res_codes": len(external_res_codes),
        "class_annual_rows": len(all_annual),
        "external_annual_rows": len(external_annual),
        "divergences": [],
        "limitations": [
            "External means RES code absent from validated C5.2 PB-only reference",
            "Not a national municipality-reference validation",
            "E1 stores aggregated administrative records, not unique patients",
            "External residents have no PB municipal population denominator",
            "Neither occupancy rate nor unmet-demand measure",
            "No QlikView, UI, cross-fact, historical label or production acceptance",
        ],
    }
    return audit, all_annual, external_annual


def write_and_readback(path: Path, rows: list[dict], fields: tuple[str, ...]) -> str:
    with path.open("x", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields, delimiter=";")
        writer.writeheader()
        writer.writerows(rows)
    with path.open("r", encoding="utf-8", newline="") as f:
        readback = list(csv.DictReader(f, delimiter=";"))
    require(readback == [{k: str(v) for k, v in row.items()} for row in rows],
            f"CSV_READBACK_MISMATCH:{path.name}")
    return sha256(path)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--e1", required=True, type=Path)
    p.add_argument("--c52", required=True, type=Path)
    p.add_argument("--output-dir", required=True, type=Path)
    p.add_argument("--source-commit", required=True)
    args = p.parse_args()
    repo = Path(__file__).resolve().parent.parent
    source, ref, out = (args.e1.resolve(), args.c52.resolve(),
                        args.output_dir.resolve())
    require(source != ref, "SOURCE_REFERENCE_MUST_DIFFER")
    require(out not in (source, ref, source.parent, ref.parent, repo) and
            source.parent not in out.parents and
            ref.parent not in out.parents and repo not in out.parents,
            "OUTPUT_MUST_BE_NEW_OUTSIDE_SOURCE_AND_GIT")
    require(re.fullmatch(r"[0-9a-f]{40}", args.source_commit) is not None,
            "SOURCE_COMMIT_FORMAT")
    scripts = [
        "tools/validate_sad_p34_external_residence01.py",
        "tools/audit_municipal_pb_crosswalk.py",
        "tools/validate_sad_p13_serv_ranking01.py",
    ]
    for s in scripts:
        subprocess.run(["git", "cat-file", "-e", f"{args.source_commit}:{s}"],
                       cwd=repo, check=True)
    subprocess.run(["git", "diff", "--exit-code", args.source_commit, "--", *scripts],
                   cwd=repo, check=True)
    require(not out.exists(), "EVIDENCE_DIR_ALREADY_EXISTS")
    out.mkdir(parents=True, exist_ok=False)
    audit = {
        "gate": GATE, "verdict": "INCONCLUSIVE", "GATE_PASS": False,
        "PR_MERGED": False, "PRODUCTION_APPROVED": False,
        "execution": {"source_commit": args.source_commit,
                      "python": sys.version,
                      "utc": datetime.now(timezone.utc).isoformat(),
                      "script_sha256": {s: sha256(repo / s) for s in scripts}},
    }
    code = 2
    try:
        details, annual, outside = validate(source, ref)
        audit.update(details)
        fields = ("ano", "classe_residencia", *MEASURES,
                  "participacao_novas_no_ano_percentual")
        ext_fields = ("ano", *MEASURES,
                      "participacao_novas_no_ano_percentual")
        audit["class_csv_sha256"] = write_and_readback(
            out / "p34_residence_class_annual.csv", annual, fields)
        audit["external_csv_sha256"] = write_and_readback(
            out / "p34_external_residents_annual.csv", outside, ext_fields)

        neg_e1 = out / "negative_e1_altered.csv"
        neg_e1.write_bytes(source.read_bytes() + b"\n")
        try:
            validate(neg_e1, ref)
            rejected_e1 = False
        except ValueError as e:
            rejected_e1 = str(e) == "E1_SHA256_MISMATCH"
        require(rejected_e1, "NEGATIVE_E1_NOT_REJECTED")

        neg_c52 = out / "negative_c52_altered.csv"
        neg_c52.write_bytes(ref.read_bytes() + b"\n")
        try:
            validate(source, neg_c52)
            rejected_c52 = False
        except ValueError as e:
            rejected_c52 = str(e) == "C52_SHA256_MISMATCH"
        require(rejected_c52, "NEGATIVE_C52_NOT_REJECTED")
        audit["negative_test"] = {
            "e1_rejected": rejected_e1, "c52_rejected": rejected_c52,
            "mutation": "append LF to input copies",
            "e1_copy_sha256": sha256(neg_e1),
            "c52_copy_sha256": sha256(neg_c52),
        }
        require(sha256(source) == E1_SHA256 and sha256(ref) == C52_SHA256,
                "SOURCE_OR_REFERENCE_CHANGED_AFTER_NEGATIVES")
        audit.update(verdict="PASS_RESTRICTED", GATE_PASS=True)
        code = 0
    except (OSError, UnicodeError, csv.Error) as e:
        audit.update(verdict="BLOCKED", error=str(e))
    except ValueError as e:
        audit.update(verdict="INCONCLUSIVE_HARD_STOP", error=str(e))
    audit["exit_code"] = code
    payload = json.dumps(audit, ensure_ascii=False, indent=2) + "\n"
    (out / "p34_audit.json").write_text(payload, encoding="utf-8")
    (out / "execution.log").write_text(payload, encoding="utf-8")
    manifest = {p.name: sha256(p) for p in sorted(out.iterdir()) if p.is_file()}
    (out / "sha256_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(payload)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
