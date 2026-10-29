#!/usr/bin/env python3
"""P3.1: pinned E1, full observed RES->SERV matrix for competence year 2018.

Writes evidence only to a new directory; never writes the source. No QlikView.
Reuses E1 primitives, not the P1.3 ranking or its execution.
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
    E1_SHA256, EXPECTED_GROUPS, FIELDS, MONTHS, YEARS, require, sha256, uint,
)

GATE = "SAD-P31-SIH-RES-SERV-MATRIX-2018-READONLY-01"
WITNESSES = {("250180", "250750"): 3806, ("250750", "250750"): 39060}
MEASURES = FIELDS[4:]


def validate(source: Path) -> tuple[dict, list[dict]]:
    before = sha256(source)
    require(before == E1_SHA256, "E1_SHA256_MISMATCH")
    # Parse the same bytes whose digest is checked; also check original after reading.
    raw = source.read_bytes()
    import hashlib
    require(hashlib.sha256(raw).hexdigest().upper() == before, "SOURCE_CHANGED_ON_READ")
    reader = csv.DictReader(io.StringIO(raw.decode("utf-8-sig"), newline=""), delimiter=";")
    require(tuple(reader.fieldnames or ()) == FIELDS, "SCHEMA_MISMATCH")
    seen, months, selected_pairs = set(), set(), set()
    matrix, monthly = {}, {}
    totals = Counter()
    rows_2018 = 0
    for line, row in enumerate(reader, 2):
        require(None not in row and all(row[f] is not None for f in FIELDS),
                f"MALFORMED_ROW:{line}")
        month, year, res, serv = (row[f] for f in FIELDS[:4])
        require(month in MONTHS and year == month[:4], f"PERIOD_MISMATCH:{line}")
        require(re.fullmatch(r"[0-9]{6}", res) is not None, f"RES_FORMAT:{line}")
        require(re.fullmatch(r"25[0-9]{4}", serv) is not None, f"SERV_FORMAT:{line}")
        grain = (month, year, res, serv)
        require(grain not in seen, f"DUPLICATE_GRAIN:{line}:{grain}")
        seen.add(grain)
        values = {f: uint(row[f], f"{line}:{f}") for f in MEASURES}
        require(values[MEASURES[0]] > 0 and
                values[MEASURES[0]] == values[MEASURES[1]] + values[MEASURES[2]],
                f"AIH_DECOMPOSITION:{line}")
        if year != "2018":
            continue
        rows_2018 += 1
        months.add(month)
        pair = (res, serv)
        selected_pairs.add(pair)
        matrix.setdefault(pair, Counter()).update(values)
        monthly.setdefault(month, Counter()).update(values)
        totals.update(values)
    require(len(seen) == EXPECTED_GROUPS, "SOURCE_GRAIN_COUNT_MISMATCH")
    require(months == {f"2018{m:02d}" for m in range(1, 13)}, "2018_MONTHS_INCOMPLETE")
    require(set(matrix) == selected_pairs, "PAIR_COVERAGE_MISMATCH")
    require(totals["qtd_internacao"] == YEARS["2018"], "ANNUAL_CONTROL_MISMATCH")
    for field in MEASURES:
        require(sum(v[field] for v in matrix.values()) == totals[field] ==
                sum(v[field] for v in monthly.values()), f"SUM_MISMATCH:{field}")
    witnesses = []
    for pair, expected in WITNESSES.items():
        actual = matrix.get(pair, {}).get("qtd_internacao")
        require(actual == expected, f"WITNESS_MISMATCH:{pair}:{actual}")
        witnesses.append({"municipio_res": pair[0], "municipio_serv": pair[1],
                          "expected": expected, "actual": actual})
    after = sha256(source)
    require(before == after, "SOURCE_CHANGED_AFTER_READ")
    records = [{"ano": "2018", "municipio_res": pair[0], "municipio_serv": pair[1],
                **dict(values)} for pair, values in sorted(matrix.items())]
    return {"source": {"path": str(source), "sha256_before": before,
                       "sha256_after": after, "size_bytes": len(raw)},
            "schema": list(FIELDS), "source_unique_grains": len(seen),
            "selected_rows_2018": rows_2018, "duplicate_grains": 0,
            "pairs": len(records), "all_observed_pairs_processed": True,
            "zero_new_admission_pairs_preserved": sum(r["qtd_internacao"] == 0 for r in records),
            "totals": dict(totals), "monthly": dict(sorted(monthly.items())),
            "witnesses": witnesses, "divergences": [],
            "limitations": ["Observed pairs only; absent combinations are not imputed as zero",
                            "Codes only; no municipal labels or new crosswalk validation",
                            "IDENT=5 excluded through E1 qtd_internacao; no raw IDENT re-audit",
                            "Local numeric validation; no UI, cross-fact or production approval"]}, records


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--e1", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--source-commit", required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    source, out = args.e1.resolve(), args.output_dir.resolve()
    require(out != source.parent and source.parent not in out.parents,
            "Output must be separate from the original source directory")
    require(re.fullmatch(r"[0-9a-f]{40}", args.source_commit) is not None, "Invalid commit")
    scripts = ["tools/validate_sad_p31_res_serv_matrix01.py", "tools/validate_sad_p13_serv_ranking01.py"]
    for script in scripts:
        subprocess.run(["git", "cat-file", "-e", f"{args.source_commit}:{script}"], cwd=repo, check=True)
    subprocess.run(["git", "diff", "--exit-code", args.source_commit, "--", *scripts], cwd=repo, check=True)
    out.mkdir(parents=True, exist_ok=False)
    audit = {"gate": GATE, "verdict": "INCONCLUSIVE", "GATE_PASS": False,
             "PR_MERGED": False, "PRODUCTION_APPROVED": False,
             "execution": {"source_commit": args.source_commit, "python": sys.version,
                           "utc": datetime.now(timezone.utc).isoformat(),
                           "argv": sys.argv, "scripts": {s: sha256(repo / s) for s in scripts}}}
    code = 2
    try:
        result, records = validate(source)
        audit.update(result)
        matrix_path = out / "p31_matrix_2018.csv"
        with matrix_path.open("x", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=("ano", "municipio_res", "municipio_serv", *MEASURES), delimiter=";")
            writer.writeheader()
            writer.writerows(records)
        # Read back the entire serialized matrix, including zero-valued observed pairs.
        with matrix_path.open(encoding="utf-8", newline="") as stream:
            reread = list(csv.DictReader(stream, delimiter=";"))
        require(reread == [{k: str(v) for k, v in row.items()} for row in records], "MATRIX_READBACK_MISMATCH")
        negative = out / "negative_e1_altered.csv"
        negative.write_bytes(source.read_bytes() + b"\n")
        rejected = False
        try:
            validate(negative)
        except ValueError as error:
            rejected = str(error) == "E1_SHA256_MISMATCH"
            audit["negative_test"] = {"mutation": "append LF to copy", "error": str(error),
                                      "rejected": rejected, "sha256": sha256(negative)}
        require(rejected, "NEGATIVE_TEST_NOT_REJECTED_BY_PIN")
        require(sha256(source) == E1_SHA256, "ORIGINAL_CHANGED_AFTER_NEGATIVE")
        audit.update(verdict="PASS_RESTRICTED", GATE_PASS=True, matrix_sha256=sha256(matrix_path))
        code = 0
    except (OSError, UnicodeError, csv.Error) as error:
        audit.update(verdict="BLOCKED", error=str(error))
    except ValueError as error:
        audit.update(verdict="INCONCLUSIVE_HARD_STOP", error=str(error))
    audit["exit_code"] = code
    encoded = json.dumps(audit, ensure_ascii=False, indent=2) + "\n"
    (out / "p31_audit.json").write_text(encoded, encoding="utf-8")
    (out / "execution.log").write_text(encoded, encoding="utf-8")
    manifest = {p.name: sha256(p) for p in sorted(out.iterdir()) if p.is_file()}
    (out / "sha256_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(encoded)
    return code


if __name__ == "__main__":
    raise SystemExit(main())
