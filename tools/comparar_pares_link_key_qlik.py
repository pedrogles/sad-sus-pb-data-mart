"""Exact hash+serialization pair audit of temporary QlikView CSV exports.

No source QVDs or project datasets are read or modified; only two temp CSVs.
"""
from __future__ import annotations

import csv
import hashlib
import json
import sys
from pathlib import Path

EXPECTED_UNIQUE = 85705
EXPECTED_HEADER = ["_P6_CHECK_HASH", "_P6_CHECK_SERIAL", "_P6_CHECK_LEN"]
SERIAL_PREFIX = "SAD-LINK-V1|C="


def read_pairs(path: Path) -> tuple[set[tuple[str, str]], str]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        first = stream.readline()
        delim = next((item for item in (",", ";", "\t") if first.count(item) == 2), None)
        if delim is None:
            raise ValueError(f"{path.name}: invalid three-column header")
        stream.seek(0)
        reader = csv.reader(stream, delimiter=delim)
        header = next(reader, None)
        if header != EXPECTED_HEADER:
            raise ValueError(f"{path.name}: unexpected header {header!r}")
        pairs: set[tuple[str, str]] = set()
        hash_to_serial: dict[str, str] = {}
        serial_to_hash: dict[str, str] = {}
        rows = 0
        for record in reader:
            if len(record) != 3:
                raise ValueError(f"{path.name}: invalid field count at row {rows + 2}")
            hash_value, serial, reported_len = record
            if (
                len(hash_value) != 22
                or not hash_value.isascii()
                or not hash_value.isprintable()
                or not serial.startswith(SERIAL_PREFIX)
                or reported_len != "22"
            ):
                raise ValueError(f"{path.name}: invalid key/serial or length at row {rows + 2}")
            previous_serial = hash_to_serial.setdefault(hash_value, serial)
            previous_hash = serial_to_hash.setdefault(serial, hash_value)
            if previous_serial != serial or previous_hash != hash_value:
                raise ValueError(f"{path.name}: hash/serial mapping inconsistent at row {rows + 2}")
            pair = (hash_value, serial)
            if pair in pairs:
                raise ValueError(f"{path.name}: duplicate hash+serial pair at row {rows + 2}")
            pairs.add(pair)
            rows += 1

    if rows != EXPECTED_UNIQUE or len(pairs) != EXPECTED_UNIQUE:
        raise ValueError(f"{path.name}: {rows} rows / {len(pairs)} unique pairs, expected {EXPECTED_UNIQUE}")
    if len(hash_to_serial) != EXPECTED_UNIQUE or len(serial_to_hash) != EXPECTED_UNIQUE:
        raise ValueError(f"{path.name}: non-bijective hash/serial counts")

    digest = hashlib.sha256()
    for pair in sorted(pairs):
        digest.update(json.dumps(pair, ensure_ascii=True, separators=(",", ":")).encode("ascii"))
        digest.update(b"\n")
    print(f"{path.name.upper().replace('.TXT', '')}_ROWS={rows}")
    print(f"{path.name.upper().replace('.TXT', '')}_DISTINCT_HASH={len(hash_to_serial)}")
    print(f"{path.name.upper().replace('.TXT', '')}_DISTINCT_SERIAL={len(serial_to_hash)}")
    return pairs, digest.hexdigest()


def main(path_a: Path, path_b: Path) -> int:
    pairs_a, digest_a = read_pairs(path_a)
    pairs_b, digest_b = read_pairs(path_b)
    print("MODE=PHASE_VI_LINK_KEY_EXACT_HASH_SERIAL_PAIR_COMPARE")
    print(f"RUN_A_SORTED_PAIR_SHA256={digest_a}")
    print(f"RUN_B_SORTED_PAIR_SHA256={digest_b}")
    print(f"ONLY_A_PAIRS={len(pairs_a - pairs_b)} ONLY_B_PAIRS={len(pairs_b - pairs_a)}")
    if pairs_a != pairs_b or digest_a != digest_b:
        print("VERDICT=BLOCKED_EXACT_HASH_SERIAL_PAIR_SET_DIFF")
        return 3
    print("COMPARISON=EXACT_85705_HASH_SERIAL_PAIRS_MATCH")
    print("LINK_KEY_CONTRACT=NOT_APPROVED")
    return 0


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise ValueError("Expected two temporary QlikView CSV paths")
        raise SystemExit(main(Path(sys.argv[1]), Path(sys.argv[2])))
    except Exception as exc:
        print(f"VERDICT=BLOCKED_PAIR_COMPARATOR_{type(exc).__name__}: {exc}")
        raise SystemExit(2)
