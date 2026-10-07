#!/usr/bin/env python3
"""Inspeciona estrutura física e diff da amostra CID-10 materializada.

Checkpoint III-C2 — C2.5.
Não altera nem normaliza os arquivos oficiais. O objetivo é revelar:
- encoding(s) decodificáveis;
- conteúdo físico do layout;
- comprimentos de linha;
- diferenças exatas entre 201901 e 201912.

Saída local (ignorada pelo Git):
- BASE/REFERENCIAS/cid10_sigtap_structure_diff.json
"""

from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

COMPETENCES = ["201701", "201801", "201901", "201912"]
ROOT = Path("BASE/REFERENCIAS/SIGTAP/CID10")
OUTPUT = Path("BASE/REFERENCIAS/cid10_sigtap_structure_diff.json")
ENCODING_CANDIDATES = ["utf-8", "cp1252", "latin-1"]


def sha256_bytes(data: bytes) -> str:
    import hashlib

    return hashlib.sha256(data).hexdigest()


def split_lines_bytes(data: bytes) -> list[bytes]:
    return data.splitlines()


def successful_decodings(data: bytes) -> list[str]:
    successful: list[str] = []
    for encoding in ENCODING_CANDIDATES:
        try:
            data.decode(encoding, errors="strict")
        except UnicodeDecodeError:
            continue
        successful.append(encoding)
    return successful


def choose_display_encoding(data: bytes) -> str:
    successful = successful_decodings(data)
    if not successful:
        return "latin-1"
    return successful[0]


def escaped_text(raw: bytes, encoding: str) -> str:
    text = raw.decode(encoding, errors="replace")
    return (
        text.replace("\\", "\\\\")
        .replace("\t", "\\t")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace(" ", "␠")
    )


def inspect_file(path: Path) -> dict[str, object]:
    data = path.read_bytes()
    lines = split_lines_bytes(data)
    encoding = choose_display_encoding(data)
    return {
        "path": str(path),
        "size_bytes": len(data),
        "sha256": sha256_bytes(data),
        "line_count": len(lines),
        "line_length_bytes": {
            str(length): count
            for length, count in sorted(Counter(len(line) for line in lines).items())
        },
        "line_endings": {
            "crlf_count": data.count(b"\r\n"),
            "lf_count": data.count(b"\n"),
            "cr_count": data.count(b"\r"),
        },
        "successful_decodings": successful_decodings(data),
        "display_encoding": encoding,
        "first_lines_escaped": [
            escaped_text(line, encoding)
            for line in lines[:10]
        ],
    }


def compare_lines(left_path: Path, right_path: Path) -> dict[str, object]:
    left_data = left_path.read_bytes()
    right_data = right_path.read_bytes()
    left_lines = split_lines_bytes(left_data)
    right_lines = split_lines_bytes(right_data)

    left_counter = Counter(left_lines)
    right_counter = Counter(right_lines)

    added_counter = right_counter - left_counter
    removed_counter = left_counter - right_counter

    display_encoding = choose_display_encoding(right_data + b"\n" + left_data)

    added_lines: list[bytes] = []
    for line, count in added_counter.items():
        added_lines.extend([line] * count)

    removed_lines: list[bytes] = []
    for line, count in removed_counter.items():
        removed_lines.extend([line] * count)

    return {
        "left": str(left_path),
        "right": str(right_path),
        "identical_bytes": left_data == right_data,
        "left_line_count": len(left_lines),
        "right_line_count": len(right_lines),
        "added_line_instances": sum(added_counter.values()),
        "removed_line_instances": sum(removed_counter.values()),
        "added_distinct_lines": len(added_counter),
        "removed_distinct_lines": len(removed_counter),
        "display_encoding": display_encoding,
        "added_examples_escaped": [
            escaped_text(line, display_encoding)
            for line in added_lines[:20]
        ],
        "removed_examples_escaped": [
            escaped_text(line, display_encoding)
            for line in removed_lines[:20]
        ],
    }


def main() -> int:
    missing: list[str] = []
    files: dict[str, dict[str, Path]] = {}

    for competence in COMPETENCES:
        cid = ROOT / competence / "tb_cid.txt"
        layout = ROOT / competence / "tb_cid_layout.txt"
        if not cid.exists():
            missing.append(str(cid))
        if not layout.exists():
            missing.append(str(layout))
        files[competence] = {"cid": cid, "layout": layout}

    if missing:
        raise RuntimeError(
            "Arquivos materializados ausentes:\n- " + "\n- ".join(missing)
        )

    inspection: dict[str, object] = {}
    for competence in COMPETENCES:
        inspection[competence] = {
            "tb_cid": inspect_file(files[competence]["cid"]),
            "tb_cid_layout": inspect_file(files[competence]["layout"]),
        }

    layout_data = files["201701"]["layout"].read_bytes()
    layout_encoding = choose_display_encoding(layout_data)
    layout_lines = split_lines_bytes(layout_data)

    comparisons = {
        "201701_vs_201801": compare_lines(
            files["201701"]["cid"], files["201801"]["cid"]
        ),
        "201801_vs_201901": compare_lines(
            files["201801"]["cid"], files["201901"]["cid"]
        ),
        "201901_vs_201912": compare_lines(
            files["201901"]["cid"], files["201912"]["cid"]
        ),
    }

    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C2_CID10_STRUCTURE_DIFF",
        "status": "PASS",
        "mode": "READ_ONLY_LOCAL_INSPECTION",
        "competences": COMPETENCES,
        "inspection": inspection,
        "layout": {
            "display_encoding": layout_encoding,
            "successful_decodings": successful_decodings(layout_data),
            "lines_escaped": [
                escaped_text(line, layout_encoding)
                for line in layout_lines
            ],
        },
        "comparisons": comparisons,
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("MODE=READ_ONLY_LOCAL_INSPECTION")
    for competence in COMPETENCES:
        cid = inspection[competence]["tb_cid"]  # type: ignore[index]
        layout = inspection[competence]["tb_cid_layout"]  # type: ignore[index]
        print(
            f"[{competence}] CID_LINES={cid['line_count']} "
            f"CID_ENCODINGS={','.join(cid['successful_decodings'])} "
            f"CID_LINE_LENGTHS={json.dumps(cid['line_length_bytes'], ensure_ascii=False)}"
        )
        print(
            f"[{competence}] LAYOUT_LINES={layout['line_count']} "
            f"LAYOUT_ENCODINGS={','.join(layout['successful_decodings'])}"
        )

    print("LAYOUT_CONTENT_ESCAPED=")
    for index, line in enumerate(summary["layout"]["lines_escaped"], start=1):
        print(f"  {index}: {line}")

    diff = comparisons["201901_vs_201912"]
    print(f"DIFF_201901_201912_ADDED={diff['added_line_instances']}")
    print(f"DIFF_201901_201912_REMOVED={diff['removed_line_instances']}")
    print(f"DIFF_201901_201912_ADDED_DISTINCT={diff['added_distinct_lines']}")
    print(f"DIFF_201901_201912_REMOVED_DISTINCT={diff['removed_distinct_lines']}")
    print("DIFF_ADDED_EXAMPLES=")
    for line in diff["added_examples_escaped"]:
        print(f"  + {line}")
    print("DIFF_REMOVED_EXAMPLES=")
    for line in diff["removed_examples_escaped"]:
        print(f"  - {line}")

    print(f"SUMMARY={OUTPUT}")
    print("VERDICT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
