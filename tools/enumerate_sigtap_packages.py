#!/usr/bin/env python3
"""Enumera pacotes oficiais SIGTAP 2017-2019 sem realizar download.

Fonte oficial operacional:
ftp://ftp2.datasus.gov.br/pub/sistemas/tup/downloads/

Checkpoint III-C2 — inventário read-only dos pacotes que poderão conter
`tb_cid.txt` e `tb_cid_layout.txt`.

Saídas locais (ignoradas pelo Git):
- BASE/REFERENCIAS/sigtap_package_inventory_2017_2019.csv
- BASE/REFERENCIAS/sigtap_package_inventory_2017_2019.json
"""

from __future__ import annotations

import argparse
import csv
import ftplib
import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

FTP_HOST = "ftp2.datasus.gov.br"
FTP_DIR = "/pub/sistemas/tup/downloads"
EXPECTED_COMPETENCES = {
    f"{year}{month:02d}"
    for year in (2017, 2018, 2019)
    for month in range(1, 13)
}
PATTERN = re.compile(
    r"^TabelaUnificada_(?P<competence>20(?:17|18|19)(?:0[1-9]|1[0-2]))"
    r"(?P<suffix>.*)\.zip$",
    re.IGNORECASE,
)

OUTPUT_DIR = Path("BASE/REFERENCIAS")
CSV_PATH = OUTPUT_DIR / "sigtap_package_inventory_2017_2019.csv"
JSON_PATH = OUTPUT_DIR / "sigtap_package_inventory_2017_2019.json"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default=FTP_HOST)
    parser.add_argument("--remote-dir", default=FTP_DIR)
    parser.add_argument("--timeout", type=int, default=60)
    args = parser.parse_args()

    print(f"FTP_HOST={args.host}")
    print(f"FTP_DIR={args.remote_dir}")
    print("MODE=READ_ONLY_ENUMERATION")

    with ftplib.FTP(timeout=args.timeout) as ftp:
        ftp.connect(args.host)
        ftp.login()
        ftp.cwd(args.remote_dir)
        names = ftp.nlst()

        matches: list[dict[str, object]] = []
        by_competence: defaultdict[str, list[str]] = defaultdict(list)

        for name in names:
            base = Path(name).name
            match = PATTERN.match(base)
            if not match:
                continue

            competence = match.group("competence")
            by_competence[competence].append(base)

            size: int | None
            try:
                size = ftp.size(base)
            except ftplib.all_errors:
                size = None

            matches.append(
                {
                    "competence": competence,
                    "filename": base,
                    "remote_path": f"{args.remote_dir.rstrip('/')}/{base}",
                    "size_bytes": size,
                }
            )

    matches.sort(key=lambda item: (str(item["competence"]), str(item["filename"])))

    found_competences = set(by_competence)
    missing = sorted(EXPECTED_COMPETENCES - found_competences)
    unexpected = sorted(found_competences - EXPECTED_COMPETENCES)
    duplicate_competences = {
        competence: sorted(files)
        for competence, files in sorted(by_competence.items())
        if len(files) > 1
    }

    status = (
        "PASS"
        if found_competences == EXPECTED_COMPETENCES and not duplicate_competences
        else "REVIEW"
    )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with CSV_PATH.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["competence", "filename", "remote_path", "size_bytes"],
            delimiter=";",
        )
        writer.writeheader()
        writer.writerows(matches)

    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C2_SIGTAP_PACKAGE_INVENTORY",
        "status": status,
        "mode": "READ_ONLY_ENUMERATION",
        "source": {
            "protocol": "ftp",
            "host": args.host,
            "directory": args.remote_dir,
        },
        "period": {
            "start": "201701",
            "end": "201912",
            "expected_competences": 36,
        },
        "inventory": {
            "matched_files": len(matches),
            "found_competences": len(found_competences),
            "missing_competences": missing,
            "unexpected_competences": unexpected,
            "duplicate_competences": duplicate_competences,
        },
        "outputs": {
            "csv": str(CSV_PATH),
            "json": str(JSON_PATH),
        },
    }

    JSON_PATH.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"MATCHED_FILES={len(matches)}")
    print(f"FOUND_COMPETENCES={len(found_competences)}")
    print(f"MISSING_COMPETENCES={','.join(missing) if missing else 'NONE'}")
    print(
        "DUPLICATE_COMPETENCES="
        + (json.dumps(duplicate_competences, ensure_ascii=False) if duplicate_competences else "NONE")
    )
    print(f"CSV={CSV_PATH}")
    print(f"SUMMARY={JSON_PATH}")
    print(f"VERDICT={status}")

    return 0 if status == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
