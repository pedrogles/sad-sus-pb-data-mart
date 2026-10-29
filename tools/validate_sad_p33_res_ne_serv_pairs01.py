#!/usr/bin/env python3
"""P3.3: rank observed RES!=SERV pairs using pinned SIH/RD E1, 2017-2019.

Validates E1 as a whole, writes only derived evidence to a NEW external
directory, and never modifies inputs, QVD, QVW, or QVS. No QlikView/COM.
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

from validate_sad_p13_serv_ranking01 import (
    E1_SHA256, EXPECTED_GROUPS, FIELDS, MONTHS, TOTAL, YEARS,
    require, sha256, share, uint,
)

GATE = "SAD-P33-SIH-RES-NE-SERV-PAIR-RANKING-READONLY-01"
MEASURES = FIELDS[4:]
EXPECTED_NE_NEW = 260454  # Restricted P3.2 annual-class control.
WITNESS = ("251370", "250750", 12176)  # Historical exploratory triannual pair.


def validate(source: Path) -> tuple[dict, list[dict], list[dict]]:
    require(source.is_file() and source.stat().st_size > 0, "E1_SOURCE_UNAVAILABLE")
    before = sha256(source)
    require(before == E1_SHA256, "E1_SHA256_MISMATCH")
    raw = source.read_bytes()
    require(hashlib.sha256(raw).hexdigest().upper() == before,
            "SOURCE_CHANGED_DURING_READ")
    reader = csv.DictReader(io.StringIO(raw.decode("utf-8-sig"), newline=""),
                            delimiter=";", restkey="__EXTRA__")
    require(tuple(reader.fieldnames or ()) == FIELDS, "E1_SCHEMA_MISMATCH")

    seen, months = set(), set()
    totals, annual_totals = Counter(), {}
    by_pair, by_pair_year = {}, {}
    ne_year_totals, ne_month_totals = {}, {}
    ne_rows = 0
    for line, row in enumerate(reader, 2):
        require("__EXTRA__" not in row and None not in row and
                all(row[k] is not None and row[k].strip() != "" for k in FIELDS),
                f"MALFORMED_ROW:{line}")
        month, year, res, serv = (row[k] for k in FIELDS[:4])
        require(month in MONTHS and year == month[:4], f"PERIOD_MISMATCH:{line}")
        require(re.fullmatch(r"[0-9]{6}", res) is not None, f"RES_CODE:{line}")
        require(re.fullmatch(r"25[0-9]{4}", serv) is not None, f"SERV_CODE:{line}")
        grain = (month, res, serv)
        require(grain not in seen, f"DUPLICATE_GRAIN:{line}")
        seen.add(grain)
        months.add(month)
        values = {key: uint(row[key], f"{line}:{key}") for key in MEASURES}
        require(values["qtd_registro_aih"] > 0 and
                values["qtd_registro_aih"] ==
                values["qtd_internacao"] + values["qtd_continuidade"],
                f"AIH_DECOMPOSITION:{line}")
        totals.update(values)
        annual_totals.setdefault(year, Counter()).update(values)
        if res == serv:
            continue
        ne_rows += 1
        pair = (res, serv)
        by_pair.setdefault(pair, Counter()).update(values)
        by_pair_year.setdefault((year, res, serv), Counter()).update(values)
        ne_year_totals.setdefault(year, Counter()).update(values)
        ne_month_totals.setdefault(month, Counter()).update(values)

    require(len(seen) == EXPECTED_GROUPS, "SOURCE_GRAIN_COUNT_MISMATCH")
    require(months == MONTHS, "SOURCE_COMPETENCIES_INCOMPLETE")
    require({y: annual_totals[y]["qtd_internacao"] for y in YEARS} == YEARS,
            "ANNUAL_SOURCE_CONTROL_MISMATCH")
    require(dict(totals) == {
        "qtd_registro_aih": TOTAL["registros"],
        "qtd_internacao": TOTAL["internacoes"],
        "qtd_continuidade": TOTAL["continuidades"],
    }, "SOURCE_TOTAL_CONTROL_MISMATCH")
    require(sum(v["qtd_internacao"] for v in by_pair.values()) == EXPECTED_NE_NEW,
            "P32_NON_EQUAL_CONTROL_MISMATCH")
    require(by_pair.get(WITNESS[:2], Counter())["qtd_internacao"] == WITNESS[2],
            "DIRECTED_PAIR_WITNESS_MISMATCH")
    require(by_pair and all(res != serv for res, serv in by_pair),
            "NON_EQUAL_PAIR_ONLY_INVARIANT")

    for field in MEASURES:
        total_pairs = sum(v[field] for v in by_pair.values())
        require(total_pairs == sum(v[field] for v in by_pair_year.values()) ==
                sum(v[field] for v in ne_year_totals.values()) ==
                sum(v[field] for v in ne_month_totals.values()),
                f"PAIR_ANNUAL_MONTHLY_RECONCILIATION:{field}")
        for year in YEARS:
            require(sum(v[field] for (y, _, _), v in by_pair_year.items()
                        if y == year) == ne_year_totals[year][field],
                    f"YEAR_PAIR_RECONCILIATION:{year}:{field}")
            require(sum(ne_month_totals.get(f"{year}{m:02d}", Counter())[field]
                        for m in range(1, 13)) == ne_year_totals[year][field],
                    f"YEAR_MONTH_RECONCILIATION:{year}:{field}")
            require(ne_year_totals[year][field] <= annual_totals[year][field],
                    f"NON_EQUAL_OVER_SOURCE_YEAR:{year}:{field}")
    after = sha256(source)
    require(before == after, "SOURCE_CHANGED_AFTER_READ")

    ordered = sorted(by_pair.items(),
                     key=lambda item: (-item[1]["qtd_internacao"], item[0][0],
                                       item[0][1]))
    ranking = [
        {
            "posicao": i, "municipio_res": pair[0], "municipio_serv": pair[1],
            **{f"{field}_trienio": values[field] for field in MEASURES},
            "participacao_ne_percentual": share(
                values["qtd_internacao"], EXPECTED_NE_NEW),
        }
        for i, (pair, values) in enumerate(ordered, 1)
    ]
    annual = [
        {"ano": year, "municipio_res": res, "municipio_serv": serv,
         **{field: by_pair_year[(year, res, serv)][field] for field in MEASURES}}
        for year, res, serv in sorted(by_pair_year)
    ]
    top10 = sum(r["qtd_internacao_trienio"] for r in ranking[:10])
    rest = sum(r["qtd_internacao_trienio"] for r in ranking[10:])
    require(top10 + rest == EXPECTED_NE_NEW, "TOP10_REST_MISMATCH")
    audit = {
        "source": {"path": str(source), "size_bytes": len(raw),
                   "sha256_before": before, "sha256_after": after},
        "schema": list(FIELDS), "source_unique_grains": len(seen),
        "source_competencies": len(months), "source_duplicate_grains": 0,
        "source_new_by_year": {y: annual_totals[y]["qtd_internacao"]
                               for y in YEARS},
        "source_total": dict(totals),
        "non_equal_rows_source": ne_rows,
        "non_equal_observed_pairs": len(by_pair),
        "non_equal_observed_pair_years": len(by_pair_year),
        "non_equal_new_by_year": {y: ne_year_totals[y]["qtd_internacao"]
                                  for y in YEARS},
        "non_equal_new_total": EXPECTED_NE_NEW,
        "zero_new_pairs_observed": sum(
            v["qtd_internacao"] == 0 for v in by_pair.values()),
        "witness": {"municipio_res": WITNESS[0], "municipio_serv": WITNESS[1],
                    "expected": WITNESS[2],
                    "actual": by_pair[WITNESS[:2]]["qtd_internacao"]},
        "ranking_rows": len(ranking), "annual_observed_rows": len(annual),
        "top10_new": top10, "remaining_new": rest,
        "top10_share_percent": share(top10, EXPECTED_NE_NEW),
        "divergences": [],
        "limitations": [
            "Observed RES!=SERV codes only; no Cartesian product or zero imputation",
            "Absent pair-year rows are not encoded as annual zero",
            "RES!=SERV does not prove travel of an individual",
            "No distances or municipal labels; no historical crosswalk revalidation",
            "IDENT=5 not counted as new; no new raw IDENT audit",
            "No QlikView, association, visual or production acceptance",
        ],
    }
    return audit, ranking, annual


def write_and_verify(path: Path, rows: list[dict], fields: tuple[str, ...]) -> str:
    with path.open("x", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter=";")
        writer.writeheader()
        writer.writerows(rows)
    with path.open("r", encoding="utf-8", newline="") as stream:
        readback = list(csv.DictReader(stream, delimiter=";"))
    expected = [{k: str(v) for k, v in row.items()} for row in rows]
    require(readback == expected, f"CSV_READBACK_MISMATCH:{path.name}")
    return sha256(path)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--e1", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--source-commit", required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    source, out = args.e1.resolve(), args.output_dir.resolve()
    require(out != source and out != source.parent and source.parent not in out.parents
            and out != repo and repo not in out.parents,
            "EVIDENCE_OUTPUT_MUST_BE_EXTERNAL_TO_SOURCE_AND_GIT")
    require(re.fullmatch(r"[0-9a-f]{40}", args.source_commit) is not None,
            "INVALID_SOURCE_COMMIT")
    scripts = ["tools/validate_sad_p33_res_ne_serv_pairs01.py",
               "tools/validate_sad_p13_serv_ranking01.py"]
    for script in scripts:
        subprocess.run(["git", "cat-file", "-e", f"{args.source_commit}:{script}"],
                       cwd=repo, check=True)
    subprocess.run(["git", "diff", "--exit-code", args.source_commit, "--", *scripts],
                   cwd=repo, check=True)
    require(not out.exists(), "EVIDENCE_OUTPUT_ALREADY_EXISTS")
    out.mkdir(parents=True, exist_ok=False)
    audit = {
        "gate": GATE, "verdict": "INCONCLUSIVE", "GATE_PASS": False,
        "PR_MERGED": False, "PRODUCTION_APPROVED": False,
        "execution": {
            "source_commit": args.source_commit, "python": sys.version,
            "utc": datetime.now(timezone.utc).isoformat(),
            "script_sha256": {s: sha256(repo / s) for s in scripts},
        },
    }
    code = 2
    try:
        result, ranking, annual = validate(source)
        audit.update(result)
        rank_fields = (
            "posicao", "municipio_res", "municipio_serv",
            *(f"{key}_trienio" for key in MEASURES),
            "participacao_ne_percentual",
        )
        year_fields = ("ano", "municipio_res", "municipio_serv", *MEASURES)
        audit["ranking_sha256"] = write_and_verify(
            out / "p33_ranking_res_ne_serv_trienio.csv", ranking, rank_fields)
        audit["annual_sha256"] = write_and_verify(
            out / "p33_pairs_annual_observed.csv", annual, year_fields)
        negative = out / "negative_e1_altered.csv"
        negative.write_bytes(source.read_bytes() + b"\n")
        rejected = False
        try:
            validate(negative)
        except ValueError as error:
            rejected = str(error) == "E1_SHA256_MISMATCH"
            audit["negative_test"] = {
                "mutation": "append LF to a copy", "error": str(error),
                "rejected": rejected, "copy_sha256": sha256(negative),
            }
        require(rejected, "NEGATIVE_COPY_NOT_REJECTED")
        require(sha256(source) == E1_SHA256, "SOURCE_CHANGED_AFTER_NEGATIVE")
        audit.update(verdict="PASS_RESTRICTED", GATE_PASS=True)
        code = 0
    except (OSError, UnicodeError, csv.Error) as error:
        audit.update(verdict="BLOCKED", error=str(error))
    except ValueError as error:
        audit.update(verdict="INCONCLUSIVE_HARD_STOP", error=str(error))
    audit["exit_code"] = code
    payload = json.dumps(audit, ensure_ascii=False, indent=2) + "\n"
    (out / "p33_audit.json").write_text(payload, encoding="utf-8")
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
