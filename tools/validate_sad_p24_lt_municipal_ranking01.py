#!/usr/bin/env python3
"""P2.4: read-only 201912 LT/SUS municipal ranking with pinned E4 and A1 R2.

The script must be run from the committed version, against original input files.
Both inputs are required. It does not use QlikView/COM, alter datasets or
generate annual bed-stock figures.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

GATE = "SAD-P24-LT-MUNICIPAL-RANKING-201912-READONLY-01"
E4_SHA = "BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88"
R2_SHA = "593b8812eaed2df9c3e6ca49f84b8c750a133966af36724963d8de2815636c42"
E4_FIELDS = ("competencia", "municipio_serv", "cnes", "tp_leito", "codleito",
             "linhas_lt", "qt_exist", "qt_sus", "qt_nsus")
R2_FIELDS = ("P23_COMPETENCIA", "P23_ESTADO_OBSERVADO", "P23_LINHAS_LT",
             "P23_MUNICIPIO_6", "P23_QT_EXIST_OBSERVADO", "P23_QT_SUS_OBSERVADO")
COMP = "201912"
CONTROL = {"linhas_lt": 964, "qt_exist": 9065, "qt_sus": 7140, "qt_nsus": 1925}
CLASSES = {"ABSENT_NOT_ZERO_PROVEN": 128,
           "OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED": 2,
           "OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED": 93}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def uint(raw: str, context: str) -> int:
    require(re.fullmatch(r"0|[1-9][0-9]*", raw) is not None,
            f"invalid integer {context}={raw!r}")
    return int(raw)


def validate(e4: Path, r2: Path) -> dict:
    before_e4, before_r2 = sha256(e4), sha256(r2)
    require(before_e4 == E4_SHA, "E4 SHA-256 differs from pinned source")
    require(before_r2 == R2_SHA, "A1 R2 export SHA-256 differs from pinned source")
    totals = Counter()
    groups = defaultdict(Counter)
    grains = set()
    with e4.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        require(tuple(reader.fieldnames or ()) == E4_FIELDS, "E4 schema mismatch")
        for lineno, row in enumerate(reader, 2):
            require(None not in row and all(v is not None for v in row.values()),
                    f"malformed E4 row {lineno}")
            if row["competencia"] != COMP:
                continue
            mun = row["municipio_serv"]
            require(re.fullmatch(r"25[0-9]{4}", mun) is not None,
                    f"municipality code mismatch {mun}")
            grain = tuple(row[f] for f in E4_FIELDS[:5])
            require(grain not in grains, f"duplicate E4 grain {grain}")
            grains.add(grain)
            vals = {k: uint(row[k], f"E4 line {lineno}/{k}") for k in CONTROL}
            require(vals["linhas_lt"] > 0 and
                    vals["qt_exist"] == vals["qt_sus"] + vals["qt_nsus"],
                    f"E4 quantity identity failed on line {lineno}")
            for key, value in vals.items():
                groups[mun][key] += value
                totals[key] += value
    require(dict(totals) == CONTROL,
            f"E4 201912 totals differ from reconciled P2.1: {dict(totals)}")
    require(len(grains) == 964, "E4 201912 grain count mismatch")

    r2_rows = {}
    classes = Counter()
    total_r2_rows = 0
    with r2.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        require(tuple(reader.fieldnames or ()) == R2_FIELDS, "R2 schema mismatch")
        for lineno, row in enumerate(reader, 2):
            total_r2_rows += 1
            require(None not in row and all(v is not None for v in row.values()),
                    f"malformed R2 row {lineno}")
            if row["P23_COMPETENCIA"] != COMP:
                continue
            mun = row["P23_MUNICIPIO_6"]
            require(re.fullmatch(r"25[0-9]{4}", mun) is not None, "invalid R2 municipality")
            require(mun not in r2_rows, f"duplicate R2 201912 municipality {mun}")
            r2_rows[mun] = row
            classes[row["P23_ESTADO_OBSERVADO"]] += 1
    require(total_r2_rows == 8028, f"R2 full row count mismatch: {total_r2_rows}")
    require(len(r2_rows) == 223, "R2 201912 municipality count mismatch")
    require(dict(classes) == CLASSES, f"R2 201912 classes mismatch: {dict(classes)}")
    require(len(groups) == 95, f"201912 E4 municipalities with LT mismatch: {len(groups)}")

    for mun, row in r2_rows.items():
        data = groups.get(mun)
        state = row["P23_ESTADO_OBSERVADO"]
        if data is None:
            require(state == "ABSENT_NOT_ZERO_PROVEN" and
                    row["P23_LINHAS_LT"] == "" and
                    row["P23_QT_SUS_OBSERVADO"] == "" and
                    row["P23_QT_EXIST_OBSERVADO"] == "",
                    f"missing E4 municipality not kept NULL in R2 {mun}")
        else:
            require(state == ("OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED"
                              if data["qt_sus"] > 0
                              else "OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED"),
                    f"R2 state mismatch {mun}")
            for field, key in (("P23_LINHAS_LT", "linhas_lt"),
                               ("P23_QT_SUS_OBSERVADO", "qt_sus"),
                               ("P23_QT_EXIST_OBSERVADO", "qt_exist")):
                require(uint(row[field], f"R2 {mun}/{field}") == data[key],
                        f"E4-R2 mismatch {mun}/{field}")

    require(sha256(e4) == before_e4 and sha256(r2) == before_r2,
            "input bytes changed during audit")
    ranked = sorted(
        ({"municipio_serv": mun, "qt_sus": v["qt_sus"],
          "qt_exist": v["qt_exist"], "qt_nsus": v["qt_nsus"],
          "linhas_lt": v["linhas_lt"]}
         for mun, v in groups.items()),
        key=lambda a: (-a["qt_sus"], a["municipio_serv"])
    )
    top10_sum = sum(r["qt_sus"] for r in ranked[:10])
    return {
        "gate": GATE,
        "verdict": "PASS_RESTRICTED_E4_R2_201912_RANKING" ,
        "competencia": COMP,
        "inputs": {"E4": {"name": e4.name, "sha256": before_e4},
                   "R2": {"name": r2.name, "sha256": before_r2}},
        "totals": dict(totals),
        "municipalities": {"full_grid": 223, "with_lt": len(groups),
                           "positive_sus": CLASSES["OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED"],
                           "observed_zero_sus": CLASSES["OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED"],
                           "without_lt_not_zero": CLASSES["ABSENT_NOT_ZERO_PROVEN"]},
        "cross_source_month_pairwise": {"matched_present": len(groups), "matched_missing": 128},
        "top10_sus_total": top10_sum,
        "top10_sus_share_percent": round(top10_sum / totals["qt_sus"] * 100, 4),
        "ranking": ranked,
        "limits": ["Only CNES/LT 201912 observed administrative snapshot",
                   "A1 R2 and E4 share source lineage, not independent CNES data",
                   "Rows missing are NULL, not proven zero",
                   "No certified hospital-only historical classification",
                   "No occupancy, no annual stock, no QlikView/UI or production approval"],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--e4", type=Path, required=True)
    ap.add_argument("--r2-export", type=Path, required=True)
    ap.add_argument("--output-dir", type=Path, required=True)
    ap.add_argument("--source-commit", type=str, required=True)
    ap.add_argument("--script-sha256", type=str, required=True)
    args = ap.parse_args()
    try:
        require(re.fullmatch(r"[0-9a-fA-F]{40}", args.source_commit) is not None,
                "expected 40-hex source commit")
        require(sha256(Path(__file__)) == args.script_sha256.upper(),
                "script SHA-256 mismatch against executed file")
        e4, r2 = args.e4.resolve(), args.r2_export.resolve()
        out = args.output_dir.resolve()
        require(e4.is_file() and r2.is_file(), "input source unavailable")
        require(out not in (e4.parent, r2.parent) and
                e4 not in out.parents and r2 not in out.parents,
                "output must be isolated from original input files")
        require(not (out / "p24_ranking_201912.csv").exists() and
                not (out / "p24_audit.json").exists(), "refuse overwrite")
        result = validate(e4, r2)
        result["execution"] = {
            "source_commit": args.source_commit,
            "script_sha256": sha256(Path(__file__)),
            "utc": datetime.now(timezone.utc).isoformat(),
        }
        out.mkdir(parents=True, exist_ok=True)
        with (out / "p24_ranking_201912.csv").open("x", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, delimiter=";", fieldnames=list(result["ranking"][0]))
            writer.writeheader()
            writer.writerows(result["ranking"])
        with (out / "p24_audit.json").open("x", encoding="utf-8") as stream:
            json.dump(result, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
        print(json.dumps({k: v for k, v in result.items() if k != "ranking"},
                         ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, csv.Error, KeyError, TypeError) as exc:
        print(f"VERDICT=FAIL_OR_BLOCKED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
