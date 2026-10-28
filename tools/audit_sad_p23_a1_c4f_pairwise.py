#!/usr/bin/env python3
"""SAD-P2.3-A1 R2: read-only, pinned C4-F ZIP vs P23_A1 export evidence.

Run after Git commit on the authorized input files; never reads/writes QVD/QVW.
Only creates a new JSON report in the operator-selected evidence directory.
A PASS is pairwise-export evidence, not a QlikView COM or production approval.
"""
from __future__ import annotations

import argparse
from collections import Counter
import csv
import hashlib
import io
import json
from pathlib import Path
import sys
import zipfile

C4F_SHA = "f79e66584f1b6bcf146861781b318f36820b62e89c335368a3785411f9a4d527"
C4F_FILES = {
    "municipio_mes_observabilidade.txt": "1cbf654d6fe0cd45e77abb97f1f42f1545a2ca9106eae2cf1a6f3afe42a44796",
    "municipio_ano_observabilidade.txt": "ac0b9ac42406ea3c59dfb8ba6230de8d3c9f1abafbef2125843a50621fb7c57e",
    "competencia_observabilidade.txt": "564c011ddeb67e2f1d7254029b2b18df74aa984108e58133a323764c8926f93c",
}
MAPPING = {
    "MUNICIPIO": "P23_MUNICIPIO_6",
    "COMPETENCIA": "P23_COMPETENCIA",
    "LINHAS_LT": "P23_LINHAS_LT",
    "QT_SUS_OBSERVADO": "P23_QT_SUS_OBSERVADO",
    "QT_EXIST_OBSERVADO": "P23_QT_EXIST_OBSERVADO",
    "ESTADO_OBSERVADO": "P23_ESTADO_OBSERVADO",
}
CLASSES = {
    "ABSENT_NOT_ZERO_PROVEN": 4467,
    "OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED": 97,
    "OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED": 3464,
}
EXPECTED_TOTALS = {"LINHAS_LT": 35518, "QT_SUS_OBSERVADO": 270076, "QT_EXIST_OBSERVADO": 337147}
WITNESSES = {
    ("251740", "201701"): ("ABSENT_NOT_ZERO_PROVEN", "", "", ""),
    ("250460", "201701"): ("OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED", "1", "0", "40"),
    ("250010", "201701"): ("OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED", "3", "20", "20"),
}


def digest(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def read_delimited(content: bytes, delimiter: str) -> list[dict[str, str]]:
    stream = io.StringIO(content.decode("utf-8-sig"), newline="")
    reader = csv.DictReader(stream, delimiter=delimiter)
    if reader.fieldnames is None:
        raise ValueError("Missing tabular header")
    rows = list(reader)
    if any(None in row or None in row.values() for row in rows):
        raise ValueError("Inconsistent field count or missing source fields")
    return rows


def index_pairs(rows: list[dict[str, str]], mun: str, comp: str):
    keys = [(r[mun], r[comp]) for r in rows]
    duplicated = sum(v - 1 for v in Counter(keys).values() if v > 1)
    return dict(zip(keys, rows)), duplicated


def compare(c4f_zip: Path, r2_export: Path) -> dict:
    zbytes = c4f_zip.read_bytes()
    rbytes = r2_export.read_bytes()
    archive_hash = digest(zbytes)
    source_hashes = {}
    with zipfile.ZipFile(io.BytesIO(zbytes)) as z:
        if sorted(z.namelist()) != sorted(C4F_FILES):
            raise ValueError("Archive members differ from three documented C4-F TXT files")
        payloads = {n: z.read(n) for n in C4F_FILES}
    for name, content in payloads.items():
        source_hashes[name] = digest(content)
    old = read_delimited(payloads["municipio_mes_observabilidade.txt"], "|")
    ann = read_delimited(payloads["municipio_ano_observabilidade.txt"], "|")
    monthly = read_delimited(payloads["competencia_observabilidade.txt"], "|")
    new = read_delimited(rbytes, "\t")
    old_columns = set(old[0]) if old else set()
    new_columns = set(new[0]) if new else set()
    if not set(MAPPING).issubset(old_columns) or set(MAPPING.values()) != new_columns:
        raise ValueError("Source or target six-field contract mismatch")
    old_index, old_dups = index_pairs(old, "MUNICIPIO", "COMPETENCIA")
    new_index, new_dups = index_pairs(new, "P23_MUNICIPIO_6", "P23_COMPETENCIA")
    old_keys = set(old_index)
    new_keys = set(new_index)
    mismatches = {field: 0 for field in MAPPING}
    samples = []
    for key in sorted(old_keys & new_keys):
        o, n = old_index[key], new_index[key]
        for source_field, target_field in MAPPING.items():
            if o[source_field] != n[target_field]:
                mismatches[source_field] += 1
                if len(samples) < 10:
                    samples.append({"pair": list(key), "field": source_field,
                                    "c4f": o[source_field], "r2": n[target_field]})
    old_classes = Counter(r["ESTADO_OBSERVADO"] for r in old)
    new_classes = Counter(r["P23_ESTADO_OBSERVADO"] for r in new)
    months = sorted({r["COMPETENCIA"] for r in old})
    munis = {r["MUNICIPIO"] for r in old}
    flag_counts = {
        f: dict(Counter(r[f] for r in old))
        for f in ("ZERO_REAL_COMPROVADO", "COBERTURA_HOSPITALAR")
    }
    totals = {}
    for f, target in MAPPING.items():
        if f in EXPECTED_TOTALS:
            totals[f] = {"c4f": sum(int(r[f]) for r in old if r[f]),
                         "r2": sum(int(r[target]) for r in new if r[target])}
    monthly_index = {r["COMPETENCIA"]: r for r in monthly}
    monthly_errors = []
    for comp in months:
        bucket = [r for r in old if r["COMPETENCIA"] == comp]
        expected = {
            "MUNICIPIOS_NO_UNIVERSO": len(bucket),
            "MUNICIPIOS_SEM_LINHAS": sum(not r["LINHAS_LT"] for r in bucket),
            "MUNICIPIOS_COM_ZERO_OBSERVADO": sum(r["ESTADO_OBSERVADO"] == "OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED" for r in bucket),
            "MUNICIPIOS_COM_POSITIVO": sum(r["ESTADO_OBSERVADO"] == "OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED" for r in bucket),
            "LINHAS_LT_TOTAL": sum(int(r["LINHAS_LT"]) for r in bucket if r["LINHAS_LT"]),
            "SUS_TOTAL_SNAPSHOT": sum(int(r["QT_SUS_OBSERVADO"]) for r in bucket if r["QT_SUS_OBSERVADO"]),
        }
        found = monthly_index.get(comp, {})
        for field, value in expected.items():
            if found.get(field) != str(value):
                monthly_errors.append([comp, field, value, found.get(field)])
    annual_index = {(r["MUNICIPIO"], r["ANO"]): r for r in ann}
    annual_errors = []
    for mun in sorted(munis):
        for year in ("2017", "2018", "2019"):
            bucket = [r for r in old if r["MUNICIPIO"] == mun and r["COMPETENCIA"].startswith(year)]
            expected = {
                "MESES_COM_LINHAS": sum(bool(r["LINHAS_LT"]) for r in bucket),
                "MESES_SEM_LINHAS": sum(not r["LINHAS_LT"] for r in bucket),
                "MESES_QT_SUS_ZERO_OBSERVADO": sum(r["ESTADO_OBSERVADO"] == "OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED" for r in bucket),
                "MESES_UNIVERSO": len(bucket),
            }
            found = annual_index.get((mun, year), {})
            for field, value in expected.items():
                if found.get(field) != str(value):
                    annual_errors.append([mun, year, field, value, found.get(field)])
    witness_errors = []
    for key, value in WITNESSES.items():
        found = old_index.get(key, {})
        actual = tuple(found.get(f) for f in ("ESTADO_OBSERVADO", "LINHAS_LT", "QT_SUS_OBSERVADO", "QT_EXIST_OBSERVADO"))
        if actual != value:
            witness_errors.append([list(key), value, actual])
    issues = []
    if archive_hash != C4F_SHA:
        issues.append("C4-F archive SHA mismatch")
    if source_hashes != C4F_FILES:
        issues.append("C4-F TXT member SHA mismatch")
    if len(old) != 8028 or len(new) != 8028 or len(old_index) != 8028 or len(new_index) != 8028:
        issues.append("8,028 rows or uniqueness mismatch")
    if len(ann) != 669 or len(monthly) != 36 or len(months) != 36 or len(munis) != 223:
        issues.append("population/month/annual universe mismatch")
    if any(Counter(r["COMPETENCIA"] for r in old)[m] != 223 for m in months):
        issues.append("monthly universe mismatch")
    if any(Counter(r["MUNICIPIO"] for r in old)[m] != 36 for m in munis):
        issues.append("municipality yearly coverage mismatch")
    if old_dups or new_dups or old_keys != new_keys or any(mismatches.values()):
        issues.append("pairwise six-field comparison mismatch")
    if dict(old_classes) != CLASSES or dict(new_classes) != CLASSES:
        issues.append("class counts mismatch")
    if flag_counts != {"ZERO_REAL_COMPROVADO": {"NOT_PROVEN": 8028},
                       "COBERTURA_HOSPITALAR": {"NOT_VERIFIED": 8028}}:
        issues.append("C4-F methodology flags mismatch")
    if any(v["r2"] != EXPECTED_TOTALS[f] or v["c4f"] != EXPECTED_TOTALS[f] for f, v in totals.items()):
        issues.append("snapshot control totals mismatch")
    if monthly_errors or annual_errors or witness_errors:
        issues.append("C4-F month/annual/witness internal inconsistency")
    return {
        "gate": "SAD-P2.3-A1-PHYSICAL-GATE-01",
        "subgate": "R2_C4F_PAIRWISE_EXPORT_READBACK",
        "verdict": "PASS_PAIRWISE_EXPORT_C4F_R2_CANDIDATE_ONLY" if not issues else "BLOCKED_PAIRWISE_EXPORT",
        "issues": issues,
        "inputs": {
            "c4f_zip": {"file": c4f_zip.name, "bytes": len(zbytes), "sha256": archive_hash},
            "r2_export": {"file": r2_export.name, "bytes": len(rbytes), "sha256": digest(rbytes)},
            "c4f_member_sha256": source_hashes,
        },
        "row_counts": {"c4f_month": len(old), "r2": len(new), "c4f_annual": len(ann), "c4f_competence": len(monthly)},
        "pairs": {"unique_c4f": len(old_index), "unique_r2": len(new_index),
                  "duplicates_c4f": old_dups, "duplicates_r2": new_dups,
                  "missing_in_r2": len(old_keys - new_keys), "extra_in_r2": len(new_keys - old_keys),
                  "compared": len(old_keys & new_keys)},
        "field_mapping": MAPPING,
        "field_mismatches": mismatches,
        "mismatch_samples": samples,
        "classes_c4f": dict(old_classes),
        "classes_r2": dict(new_classes),
        "flags_c4f": flag_counts,
        "totals": totals,
        "monthly_internal_errors": len(monthly_errors),
        "annual_internal_errors": len(annual_errors),
        "witness_errors": len(witness_errors),
        "methodological_limits": [
            "Comparison is between exported artifacts, not two independent source systems.",
            "C4-F ZIP/member hashes confirm archived evidence per 2026-10-21 document but do not replay its source COM.",
            "QlikView R2 physical execution/26-artifact hashes are reported separately by operator, not checked by this auditor.",
            "Missing LT is not a proven real zero; historical hospital universe is not verified.",
            "No global UX/production approval; snapshots must not be interpreted as annual beds.",
        ],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--c4f-zip", type=Path, required=True)
    ap.add_argument("--r2-export", type=Path, required=True)
    ap.add_argument("--report", type=Path, required=True)
    args = ap.parse_args()
    if args.report.exists():
        ap.error("Refusing to overwrite report")
    if not args.report.parent.is_dir():
        ap.error("Report parent directory must exist")
    if args.report.resolve().is_relative_to(Path.cwd().resolve()):
        ap.error("Report cannot be written under current repository/workdir")
    try:
        result = compare(args.c4f_zip, args.r2_export)
    except (OSError, ValueError, zipfile.BadZipFile, UnicodeError, KeyError) as exc:
        print(f"BLOCKED: {exc}", file=sys.stderr)
        return 2
    args.report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("R2_C4F_PAIRWISE_VERDICT=" + result["verdict"])
    print("REPORT=" + str(args.report))
    return 0 if result["verdict"].startswith("PASS") else 1


if __name__ == "__main__":
    sys.exit(main())
