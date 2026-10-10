"""Compare exact QlikView Hash128 LINK candidate key sets from independent reloads.

Exports are TEMPORARY, generated from the physically tested P6 preflight.
No source/QVD writes and no external dependencies.
"""
from __future__ import annotations

import hashlib
import sys
from pathlib import Path

EXPECTED_ROWS = 602859
EXPECTED_UNIQUE_KEYS = 85705
HEADER = "_P6_HASH"


def load_exact_set(path: Path) -> tuple[set[str], str, int]:
    seen: set[str] = set()
    n = 0
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        for line_no, raw in enumerate(handle, 1):
            value = raw.rstrip("\r\n")
            if line_no == 1 and value.strip('"') == HEADER:
                continue
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1].replace('""', '"')
            if len(value) != 22 or not value.isascii() or not value.isprintable():
                raise ValueError(
                    f"{path.name}: invalid Qlik hash at line {line_no}, length {len(value)}"
                )
            n += 1
            seen.add(value)
    if n != EXPECTED_ROWS or len(seen) != EXPECTED_UNIQUE_KEYS:
        raise ValueError(
            f"{path.name}: rows={n} unique={len(seen)};"
            f" expected={EXPECTED_ROWS}/{EXPECTED_UNIQUE_KEYS}"
        )
    ordered = ("\n".join(sorted(seen)) + "\n").encode("ascii")
    digest = hashlib.sha256(ordered).hexdigest()
    return seen, digest, n


def main(a: Path, b: Path) -> int:
    s1, h1, n1 = load_exact_set(a)
    s2, h2, n2 = load_exact_set(b)
    print("MODE=PHASE_VI_LINK_KEY_EXACT_SET_TWO_RELOADS_READ_ONLY")
    print(f"RUN_A_ROWS={n1} RUN_B_ROWS={n2}")
    print(f"RUN_A_UNIQUE_KEYS={len(s1)} RUN_B_UNIQUE_KEYS={len(s2)}")
    print(f"RUN_A_SORTED_SET_SHA256={h1}")
    print(f"RUN_B_SORTED_SET_SHA256={h2}")
    print(f"ONLY_A_KEYS={len(s1 - s2)} ONLY_B_KEYS={len(s2 - s1)}")
    if s1 == s2 and h1 == h2:
        print("COMPARISON=EXACT_85705_LINK_KEY_SET_MATCH")
        print("LINK_KEY_CONTRACT=NOT_APPROVED")
        return 0
    print("VERDICT=BLOCKED_LINK_KEY_EXACT_SET_DIFFERENCE")
    return 3


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise ValueError("Expected two exported key paths")
        raise SystemExit(main(Path(sys.argv[1]), Path(sys.argv[2])))
    except Exception as exc:
        print(f"VERDICT=BLOCKED_LINK_KEY_COMPARATOR_{type(exc).__name__}: {exc}")
        raise SystemExit(2)
