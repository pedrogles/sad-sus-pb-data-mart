#!/usr/bin/env python3
"""SAD SUS PB — Fase V / FATO_INTERNACAO — preflight READ-ONLY.

Execute from the repository root on the user's Windows environment. Reads:
- 36 converted RD CSVs (BASE/CONVERTIDA/RD/RDPB*.csv)
- header XML of EXTRACAO/QVD/SRC_SIH_RD.qvd
- header XML of seven dimension QVDs (not QVD binary records)

Does NOT modify or create any data, QVD, checkpoints, scripts, documentation, or
repository files. SHA-256 projection test is a *candidate* only: the QlikView
Text() representation must be validated in Qlik before approving an SK.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path

RD_FIELDS = (
    "ANO_CMPT", "MES_CMPT", "N_AIH", "IDENT", "MUNIC_RES", "MUNIC_MOV",
    "CNES", "PROC_SOLIC", "PROC_REA", "DIAG_PRINC", "CAR_INT", "COBRANCA",
    "DT_INTER", "DT_SAIDA", "DIAS_PERM", "VAL_TOT", "MORTE",
)
STAGING_FIELDS = [*RD_FIELDS, "_META_SOURCE_FILE", "_META_SOURCE_FAMILY",
                  "_META_SOURCE_COMPETENCE", "_META_SOURCE_PATH"]
EXPECTED_ROWS = 566672
EXPECTED_YEARS = {"2017": 187726, "2018": 187293, "2019": 191653}
EXPECTED_COMPETENCES = {f"20{y}{m:02d}" for y in (17, 18, 19) for m in range(1, 13)}
EXPECTED_IDENT5 = 11583
EXPECTED_AIH_MONTHLY_EXTRA_ROWS = 880
EXPECTED_EXTERNAL_RESIDENCE = 5202
NAME_RE = re.compile(r"RDPB(17|18|19)(0[1-9]|1[0-2])\.csv$", re.IGNORECASE)
QVD_DIM_SK = {
    "DIM_TEMPO": "%SK_TEMPO_DATA",
    "DIM_MUNICIPIO": "%SK_MUNICIPIO",
    "DIM_ESTABELECIMENTO": "%SK_ESTABELECIMENTO",
    "DIM_PROCEDIMENTO": "%SK_PROCEDIMENTO",
    "DIM_DIAGNOSTICO": "%SK_DIAGNOSTICO",
    "DIM_CARATER_ATENDIMENTO": "%SK_CARATER_ATENDIMENTO",
    "DIM_MOTIVO_SAIDA_PERMANENCIA": "%SK_MOTIVO_SAIDA",
}


def qvd_header(path: Path) -> tuple[int, list[str]]:
    closing = b"</QvdTableHeader>"
    data = bytearray()
    with path.open("rb") as source:
        while closing not in data:
            block = source.read(65536)
            if not block:
                raise RuntimeError(f"QVD header not found: {path}")
            data.extend(block)
            if len(data) > 2 * 1024 * 1024:
                raise RuntimeError(f"QVD header too long: {path}")
    root = ET.fromstring(data[:data.index(closing) + len(closing)])
    def nodes(label: str) -> list[str]:
        return [(el.text or "") for el in root.iter()
                if el.tag.rsplit("}", 1)[-1] == label]
    counts = nodes("NoOfRecords")
    if len(counts) != 1 or not counts[0].isdigit():
        raise RuntimeError(f"Invalid QVD NoOfRecords: {path}: {counts!r}")
    return int(counts[0]), nodes("FieldName")


def digest_projection(filename: str, row: dict[str, str]) -> bytes:
    # Unambiguous length-prefixed encoding: no special delimiter may collide.
    h = hashlib.sha256()
    for value in (filename, *(row[name] for name in RD_FIELDS)):
        encoded = value.encode("utf-8")
        h.update(len(encoded).to_bytes(4, "big"))
        h.update(encoded)
    return h.digest()


def decimal_nonnegative(value: str) -> bool:
    try:
        n = Decimal(value.strip())
    except (InvalidOperation, ValueError):
        return False
    return n.is_finite() and n >= 0


def valid_date(value: str) -> bool:
    if not re.fullmatch(r"\d{8}", value):
        return False
    try:
        datetime.strptime(value, "%Y%m%d")
        return True
    except ValueError:
        return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd(),
                        help="SAD project repository root; defaults to current directory")
    args = parser.parse_args()
    root = args.root.resolve()
    csvs = sorted((root / "BASE" / "CONVERTIDA" / "RD").glob("RDPB*.csv"))
    print("MODE=PHASE_V_FATO_INTERNACAO_CSV_QVD_HEADER_READ_ONLY_PREFLIGHT")
    print("OUTPUT_FILES_WRITTEN=0")
    print("FACT_QVD_GENERATED=False")
    print("QLIK_HASH128_EXECUTED=False")
    if len(csvs) != 36:
        raise RuntimeError(f"Expected 36 RD files, found {len(csvs)}")
    months_seen: set[str] = set()
    per_year = Counter()
    count = Counter()
    seen_projection: dict[bytes, tuple[str, int]] = {}
    seen_monthly_aih: set[tuple[str, str]] = set()
    projected_duplicates: list[tuple[str, int, str, int]] = []
    external_residence = 0
    for path in csvs:
        m = NAME_RE.fullmatch(path.name)
        if not m:
            raise RuntimeError(f"Unexpected RD filename: {path.name}")
        competence = f"20{m.group(1)}{m.group(2)}"
        if competence in months_seen:
            raise RuntimeError(f"Repeated monthly input: {competence}")
        months_seen.add(competence)
        with path.open("r", encoding="utf-8-sig", newline="") as source:
            reader = csv.DictReader(source, delimiter=";")
            if reader.fieldnames is None or any(name not in reader.fieldnames for name in RD_FIELDS):
                raise RuntimeError(f"Missing RD fields in {path.name}: {reader.fieldnames}")
            if len(reader.fieldnames) != len(set(reader.fieldnames)):
                raise RuntimeError(f"Repeated CSV field name in {path.name}")
            for line_number, row in enumerate(reader, 2):
                if None in row or any(row[name] is None for name in RD_FIELDS):
                    raise RuntimeError(f"Malformed CSV row in {path.name}:{line_number}")
                count["total"] += 1
                per_year[competence[:4]] += 1
                count[f"month_{competence}"] += 1
                ident = row["IDENT"].strip()
                if ident == "5":
                    count["ident5"] += 1
                elif ident != "1":
                    count["invalid_ident"] += 1
                if row["MORTE"].strip() not in {"0", "1"}:
                    count["invalid_morte"] += 1
                if row["CAR_INT"].strip() not in {"01", "02", "05", "06"}:
                    count["invalid_car"] += 1
                if not (row["ANO_CMPT"].strip() == competence[:4]
                        and row["MES_CMPT"].strip().zfill(2) == competence[4:]):
                    count["invalid_competence"] += 1
                if not (valid_date(row["DT_INTER"].strip())
                        and valid_date(row["DT_SAIDA"].strip())):
                    count["invalid_dates"] += 1
                if not (decimal_nonnegative(row["DIAS_PERM"])
                        and decimal_nonnegative(row["VAL_TOT"])):
                    count["invalid_measures"] += 1
                if not row["MUNIC_RES"].strip().startswith("25"):
                    external_residence += 1
                ai = (competence, row["N_AIH"])
                if ai in seen_monthly_aih:
                    count["monthly_aih_extra_rows"] += 1
                else:
                    seen_monthly_aih.add(ai)
                fingerprint = digest_projection(path.name, row)
                if fingerprint in seen_projection:
                    count["projected_duplicate_fingerprints"] += 1
                    if len(projected_duplicates) < 5:
                        first = seen_projection[fingerprint]
                        projected_duplicates.append((first[0], first[1], path.name, line_number))
                else:
                    seen_projection[fingerprint] = (path.name, line_number)
    print("RD_FILES=" + str(len(csvs)))
    print("RD_COMPETENCES=" + str(len(months_seen)))
    print("RD_ROWS=" + str(count["total"]))
    print("RD_YEAR_ROWS=" + str(sorted(per_year.items())))
    print("IDENT5_ROWS=" + str(count["ident5"]))
    print("IDENT1_ROWS=" + str(count["total"] - count["ident5"] - count["invalid_ident"]))
    print("RD_RESIDENCE_EXTERNAL_ROWS=" + str(external_residence))
    print("N_AIH_MONTHLY_EXTRA_ROWS=" + str(count["monthly_aih_extra_rows"]))
    print("PROJECTED_COLUMNS=" + str(len(RD_FIELDS)) + "+SOURCE_FILENAME")
    print("PROJECTED_SHA256_DISTINCT=" + str(len(seen_projection)))
    print("PROJECTED_SHA256_DUPLICATE_ROWS=" + str(count["projected_duplicate_fingerprints"]))
    print("PROJECTED_DUPLICATE_EXAMPLES=" + str(projected_duplicates))
    for label in ("invalid_ident", "invalid_morte", "invalid_car", "invalid_competence",
                  "invalid_dates", "invalid_measures"):
        print(label.upper() + "=" + str(count[label]))
    if months_seen != EXPECTED_COMPETENCES or count["total"] != EXPECTED_ROWS:
        raise RuntimeError("RD coverage/count differs from approved Phase III")
    if dict(per_year) != EXPECTED_YEARS:
        raise RuntimeError("RD per-year counts differ from approved Phase IV")
    if count["ident5"] != EXPECTED_IDENT5 or external_residence != EXPECTED_EXTERNAL_RESIDENCE:
        raise RuntimeError("RD identity/residence count differs from approved discovery")
    if count["monthly_aih_extra_rows"] != EXPECTED_AIH_MONTHLY_EXTRA_ROWS:
        raise RuntimeError("RD duplicate N_AIH monthly surplus differs from approved discovery")
    for label in ("invalid_ident", "invalid_morte", "invalid_car", "invalid_competence",
                  "invalid_dates", "invalid_measures"):
        if count[label]:
            raise RuntimeError(f"Invalid data found: {label}={count[label]}")
    source_qvd = root / "EXTRACAO" / "QVD" / "SRC_SIH_RD.qvd"
    source_rows, source_fields = qvd_header(source_qvd)
    print("RD_QVD_ROWS=" + str(source_rows))
    print("RD_QVD_FIELDS=" + str(source_fields))
    if source_rows != EXPECTED_ROWS or source_fields != STAGING_FIELDS:
        raise RuntimeError("RD staging QVD header does not match the documented extraction projection")
    for dim, sk in QVD_DIM_SK.items():
        rows, fields = qvd_header(root / "TRANSFORMACAO" / "QVD" / (dim + ".qvd"))
        if sk not in fields or rows < 1:
            raise RuntimeError(f"Dimension header mismatch: {dim} needs {sk}")
        print("DIMENSION_HEADER_" + dim + "=PASS")
    if count["projected_duplicate_fingerprints"]:
        print("SK_FROM_STAGING_PROJECTION=BLOCKED_POTENTIAL_DUPLICATE_CONTENT")
        print("VERDICT=BLOCKED_PROJECTED_ROWS_NOT_UNIQUE")
        return 2
    print("SK_FROM_STAGING_PROJECTION=CANDIDATE_ONLY_QVD_TEXT_NORMALIZATION_UNTESTED")
    print("SK_REGISTRO_INTERNACAO_APPROVED=False")
    print("VERDICT=PASS_READ_ONLY_CSV_QVD_HEADER_SK_DECISION_PENDING")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"VERDICT=FAIL_CLOSED {type(exc).__name__}: {exc}", file=sys.stderr)
        sys.exit(1)