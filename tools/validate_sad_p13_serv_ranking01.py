#!/usr/bin/env python3
"""P1.3: verify pinned E1 and rank new SIH/RD admissions by attendance municipality.

Read-only for source. The optional outputs are derived evidence, outside Git/QVD/QVW.
No QlikView, population denominator, residence ranking, or municipality labels.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import Counter
from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

GATE = "SAD-P13-SERV-RANKING-READONLY-01"
E1_SHA256 = "F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615"
FIELDS = ("competencia", "ano", "municipio_res", "municipio_serv",
          "qtd_registro_aih", "qtd_internacao", "qtd_continuidade")
MONTHS = {f"{year}{month:02d}" for year in range(2017, 2020) for month in range(1, 13)}
YEARS = {"2017": 183532, "2018": 183311, "2019": 188246}
TOTAL = {"registros": 566672, "internacoes": 555089, "continuidades": 11583}
EXPECTED_GROUPS = 30255
EXPLORATORY = {"250750": 225785, "250400": 137396}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def uint(value: str, context: str) -> int:
    require(re.fullmatch(r"(?:0|[1-9][0-9]*)", value) is not None,
            f"{context}: noncanonical unsigned integer {value!r}")
    return int(value)


def share(count: int, total: int, places: int = 4) -> str:
    return str((Decimal(count) * 100 / Decimal(total)).quantize(
        Decimal(1).scaleb(-places), rounding=ROUND_HALF_UP))


def validate(e1: Path, *, enforce_pinned: bool = True) -> dict:
    require(e1.is_file() and e1.stat().st_size > 0, "E1 absent or empty")
    file_hash_before = sha256(e1)
    if enforce_pinned:
        require(file_hash_before == E1_SHA256, "E1 SHA-256 differs from approved AE01 artifact")
    seen = set()
    months = set()
    by_year = Counter()
    by_serv = Counter()
    by_serv_reg = Counter()
    totals = Counter()
    missing = Counter()
    rows = 0
    with e1.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream, delimiter=";", restkey="__EXTRA__")
        require(tuple(reader.fieldnames or ()) == FIELDS, "E1 schema/order differs")
        for line, row in enumerate(reader, start=2):
            rows += 1
            require("__EXTRA__" not in row and all(row[f] is not None for f in FIELDS),
                    f"line {line}: malformed CSV")
            for field in FIELDS:
                require(row[field].strip() != "", f"line {line}: missing {field}")
            month, year = row["competencia"], row["ano"]
            require(month in MONTHS and year == month[:4], f"line {line}: period/year mismatch")
            res, serv = row["municipio_res"], row["municipio_serv"]
            require(re.fullmatch(r"[0-9]{6}", res) is not None, f"line {line}: invalid RES {res!r}")
            require(re.fullmatch(r"25[0-9]{4}", serv) is not None,
                    f"line {line}: missing/non-PB-format SERV {serv!r}")
            grain = (month, res, serv)
            require(grain not in seen, f"line {line}: duplicated grain {grain}")
            seen.add(grain)
            months.add(month)
            reg = uint(row["qtd_registro_aih"], f"line {line}: qtd_registro_aih")
            new = uint(row["qtd_internacao"], f"line {line}: qtd_internacao")
            cont = uint(row["qtd_continuidade"], f"line {line}: qtd_continuidade")
            require(reg > 0 and reg == new + cont, f"line {line}: AIH decomposition mismatch")
            totals["registros"] += reg
            totals["internacoes"] += new
            totals["continuidades"] += cont
            by_year[year] += new
            by_serv[serv] += new
            by_serv_reg[serv] += reg
    require(rows == EXPECTED_GROUPS, f"E1 groups {rows} != {EXPECTED_GROUPS}")
    require(months == MONTHS, f"E1 competencies missing={sorted(MONTHS-months)} extra={sorted(months-MONTHS)}")
    require(dict(sorted(by_year.items())) == YEARS, f"annual controls mismatch: {dict(by_year)}")
    require(dict(totals) == TOTAL, f"triannual controls mismatch: {dict(totals)}")
    require(len(by_serv) > 0 and sum(by_serv.values()) == TOTAL["internacoes"],
            "SERV ranking incomplete or totals diverge")
    require(sum(by_serv_reg.values()) == TOTAL["registros"], "SERV rows omitted")
    file_hash_after = sha256(e1)
    require(file_hash_after == file_hash_before, "E1 changed during audit")
    ranked = sorted(by_serv.items(), key=lambda pair: (-pair[1], pair[0]))
    ranking = [{"posicao": i, "municipio_serv": code, "qtd_internacao": amount,
                "participacao_percentual": share(amount, TOTAL["internacoes"]) }
               for i, (code, amount) in enumerate(ranked, 1)]
    top10 = sum(item["qtd_internacao"] for item in ranking[:10])
    other = sum(item["qtd_internacao"] for item in ranking[10:])
    require(top10 + other == TOTAL["internacoes"], "top10/rest partition mismatch")
    controls = {code: {"expected_exploratory": expected,
                       "calculated": by_serv.get(code, 0),
                       "matches": by_serv.get(code) == expected}
                for code, expected in EXPLORATORY.items()}
    return {
        "gate": GATE, "verdict": "PASS_E1_P13_RECONCILED_RESTRICTED",
        "evidence_level": "committed_validator_run_on_uploaded_pinned_E1_no_qlikview",
        "source": {"name": e1.name, "sha256": file_hash_after,
                   "size_bytes": e1.stat().st_size, "expected_sha256": E1_SHA256,
                   "crosswalk": "C5.2 coverage previously attested by AE01; not re-run here"},
        "schema": list(FIELDS), "groups": rows, "duplicate_grains": 0,
        "period": {"first": min(months), "last": max(months), "competencies": len(months)},
        "annual_internacoes": dict(sorted(by_year.items())), "totals": dict(totals),
        "municipios_serv_distinct": len(by_serv), "serv_codes_missing_or_malformed": sum(missing.values()),
        "ranking": ranking,
        "top10": {"count": top10, "municipios": min(10, len(ranking)),
                  "participacao_percentual": share(top10, TOTAL["internacoes"])},
        "demais": {"count": other, "municipios": max(0, len(ranking)-10),
                   "participacao_percentual": share(other, TOTAL["internacoes"])},
        "sum_shares_exact_percent": "100", "exploratory_secondary_controls": controls,
        "limitations": ["SERV != RES", "not unique patients or clinical admissions",
                        "IDENT=5 excluded by qtd_internacao", "no geography labels independently checked",
                        "no QlikView/UI/production acceptance"]
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--e1", type=Path, required=True)
    parser.add_argument("--source-commit", required=True, help="40-hex Git commit containing this validator")
    parser.add_argument("--script-sha256", help="Expected SHA-256 for this versioned script")
    parser.add_argument("--output-dir", type=Path, help="Optional derived evidence directory outside source folder and Git")
    args = parser.parse_args()
    try:
        require(re.fullmatch(r"[0-9a-fA-F]{40}", args.source_commit) is not None,
                "source commit must be a full 40-character SHA")
        own_hash = sha256(Path(__file__))
        if args.script_sha256:
            require(own_hash == args.script_sha256.upper(), "validator script hash mismatch")
        result = validate(args.e1)
        result["execution"] = {"source_commit": args.source_commit,
                               "script_sha256": own_hash,
                               "verified_utc": datetime.now(timezone.utc).isoformat()}
        if args.output_dir is not None:
            out = args.output_dir.resolve()
            source = args.e1.resolve()
            require(out != source.parent and out != source and source not in out.parents,
                    "evidence output cannot overwrite/occupy E1 source directory")
            out.mkdir(parents=True, exist_ok=True)
            with (out / "p13_serv_ranking.csv").open("w", encoding="utf-8", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=("posicao", "municipio_serv", "qtd_internacao", "participacao_percentual"), delimiter=";")
                writer.writeheader()
                writer.writerows(result["ranking"])
            (out / "p13_serv_audit.json").write_text(
                json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(json.dumps({k: v for k, v in result.items() if k != "ranking"}, ensure_ascii=False, indent=2))
        return 0
    except (ValueError, OSError, UnicodeError, csv.Error) as error:
        print(f"VERDICT=FAIL_HARD_STOP: {error}")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
