#!/usr/bin/env python3
"""III-C4.2b.3 — compara linhas de tabela dos 5 HTMLs CNES já capturados.

Somente read-only das entradas. Sem requisições HTTP, downloads, QVD ou T29.
A diferença entre tabelas de indicadores não prova, isoladamente,
vigência normativa de códigos/descrições.

Entradas: BASE/REFERENCIAS/cnes_leito_history_probe/probe_summary.json
          CNES_Leitos_Indicadores_{YYYYMM}_UF00.html (5 arquivos).
Saída local ignorada: cnes_leito_history_probe/table_row_diff_summary.json.
"""

from __future__ import annotations

import difflib
import hashlib
import json
import re
from collections import Counter
from datetime import datetime, timezone
from html import unescape
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path("BASE/REFERENCIAS/cnes_leito_history_probe")
INPUT = ROOT / "probe_summary.json"
OUTPUT = ROOT / "table_row_diff_summary.json"
MONTHS = ("201712", "201801", "201805", "201806", "201912")
PAIRS = tuple(zip(MONTHS, MONTHS[1:]))
MONTH_PATTERN = re.compile(r"\b(?:201712|201801|201805|201806|201912)\b")


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", unescape(text)).strip()


def digest(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


class TableRows(HTMLParser):
    """Captura textos de tr/td/th, mesmo em páginas HTML legadas."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[dict] = []
        self.ignore_depth = 0
        self.rows: list[tuple[str, ...]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        if tag in ("script", "style"):
            self.ignore_depth += 1
        if tag == "tr":
            self.stack.append({"cells": [], "current": None})
        elif tag in ("th", "td") and self.stack:
            self.stack[-1]["current"] = []

    def handle_data(self, data: str) -> None:
        if self.ignore_depth == 0 and self.stack:
            current = self.stack[-1]["current"]
            if current is not None:
                current.append(data)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag in ("script", "style") and self.ignore_depth > 0:
            self.ignore_depth -= 1
        elif tag in ("td", "th") and self.stack:
            row = self.stack[-1]
            if row["current"] is not None:
                row["cells"].append(normalize(" ".join(row["current"])))
                row["current"] = None
        elif tag == "tr" and self.stack:
            row = self.stack.pop()
            if len(row["cells"]) >= 2:
                self.rows.append(tuple(row["cells"]))


def short_row(row: tuple[str, ...]) -> list[str]:
    return [cell[:180] for cell in row[:9]]


def row_diff(
    left: list[tuple[str, ...]],
    right: list[tuple[str, ...]],
) -> dict:
    matcher = difflib.SequenceMatcher(a=left, b=right, autojunk=False)
    changes: list[dict] = []
    counts: Counter[str] = Counter()
    for tag, a0, a1, b0, b1 in matcher.get_opcodes():
        counts[tag] += max(a1 - a0, b1 - b0)
        if tag == "equal":
            continue
        if len(changes) < 12:
            changes.append({
                "operation": tag,
                "from_rows_index": [a0, a1],
                "to_rows_index": [b0, b1],
                "from_example": [short_row(r) for r in left[a0:min(a1, a0 + 2)]],
                "to_example": [short_row(r) for r in right[b0:min(b1, b0 + 2)]],
            })
    return {
        "equal_rows": counts["equal"],
        "replace_rows": counts["replace"],
        "insert_rows": counts["insert"],
        "delete_rows": counts["delete"],
        "diff_examples": changes,
        "diff_examples_truncated": sum(
            tag != "equal" for tag, *_ in matcher.get_opcodes()
        ) > len(changes),
    }


def month_neutral(row: tuple[str, ...]) -> tuple[str, ...]:
    """Segundo confronto apenas exploratório, retira ecos dos meses sondados."""
    return tuple(MONTH_PATTERN.sub("[MONTH]", cell) for cell in row)


def classification_candidates(rows: list[tuple[str, ...]]) -> list[tuple[str, str]]:
    """Somente código (2 dígitos) e segunda célula; tipo/grupo NÃO inferido."""
    return [
        (row[0], row[1])
        for row in rows
        if len(row) >= 2 and re.fullmatch(r"[0-9]{2}", row[0]) and bool(row[1])
    ]


def counter_examples(values: Counter[tuple[str, str]], limit: int = 12) -> list[dict]:
    return [
        {"code": code, "description": desc, "occurrences": count}
        for (code, desc), count in sorted(values.items())[:limit]
    ]


def main() -> int:
    if not INPUT.is_file():
        raise RuntimeError(f"Manifesto da captura ausente: {INPUT}")
    manifest = json.loads(INPUT.read_text(encoding="utf-8"))
    items = manifest.get("sources") or []
    if len(items) != 5 or set(
        item.get("requested_competence") for item in items
    ) != set(MONTHS):
        raise RuntimeError("Manifesto não contém exatamente as cinco competências")

    tables: dict[str, list[tuple[str, ...]]] = {}
    classifications: dict[str, list[tuple[str, str]]] = {}
    captures: list[dict] = []
    for item in sorted(items, key=lambda x: x["requested_competence"]):
        month = item["requested_competence"]
        expected = ROOT / f"CNES_Leitos_Indicadores_{month}_UF00.html"
        if (
            item.get("status") != "HTTP_HTML_CAPTURED_REVIEW_REQUIRED"
            or not expected.is_file()
        ):
            raise RuntimeError(f"Captura ausente ou inválida: {month}")
        raw = expected.read_bytes()
        if digest(raw) != item.get("sha256") or len(raw) != item.get("bytes"):
            raise RuntimeError(f"Falha de integridade SHA/tamanho: {month}")
        encoding = item.get("decoded_using") or "cp1252"
        html = raw.decode(encoding, errors="strict")
        parsed = TableRows()
        parsed.feed(html)
        rows = parsed.rows
        tables[month] = rows
        classification = classification_candidates(rows)
        classifications[month] = classification
        code_occurrences = Counter(code for code, _ in classification)
        bed70_rows = [
            short_row(row) for row in rows
            if any(re.search(r"\b70\s+FIBROSE\s+CISTICA\b", c, re.I) for c in row)
            or (
                any(re.fullmatch("70", c) for c in row)
                and any("FIBROSE" in c.upper() for c in row)
            )
        ]
        info = {
            "competence_requested": month,
            "manifest_integrity": "PASS",
            "table_rows": len(rows),
            "code_description_candidates": len(classification),
            "code_description_distinct_pairs": len(set(classification)),
            "duplicate_code_values_in_table": sum(1 for count in code_occurrences.values() if count > 1),
            "code_description_multiset_sha256": digest(
                json.dumps(sorted(classification), ensure_ascii=False).encode("utf-8")
            ),
            "table_row_sha256": digest(
                json.dumps(rows, ensure_ascii=False).encode("utf-8")
            ),
            "month_mentions_in_html": {
                m: len(re.findall(re.escape(m), html)) for m in MONTHS
            },
            "code70_table_row_examples": bed70_rows[:2],
            "code70_row_count": len(bed70_rows),
        }
        captures.append(info)
        print(
            f"[{month}] INTEGRITY=PASS TABLE_ROWS={len(rows)} "
            f"CODE70_ROWS={len(bed70_rows)}"
        )

    comparisons: list[dict] = []
    for previous, current in PAIRS:
        left, right = tables[previous], tables[current]
        raw_diff = row_diff(left, right)
        neutral_diff = row_diff(
            [month_neutral(row) for row in left],
            [month_neutral(row) for row in right],
        )
        left_class = Counter(classifications[previous])
        right_class = Counter(classifications[current])
        removed_class = left_class - right_class
        added_class = right_class - left_class
        aligned = [(a, b) for a, b in zip(left, right) if a[:2] == b[:2]]
        quantitative_changes_on_same_labels = sum(
            a[2:] != b[2:] for a, b in aligned
        )
        label_positions_changed = sum(
            a[:2] != b[:2] for a, b in zip(left, right)
        )
        comparisons.append({
            "from_competence_requested": previous,
            "classification_code_description_diff": {
                "label_pairs_from": len(classifications[previous]),
                "label_pairs_to": len(classifications[current]),
                "removed_occurrences": sum(removed_class.values()),
                "added_occurrences": sum(added_class.values()),
                "removed_examples": counter_examples(removed_class),
                "added_examples": counter_examples(added_class),
                "same_labels_at_same_row_positions": len(aligned),
                "different_labels_at_aligned_positions": label_positions_changed,
                "numeric_or_other_cells_changed_at_same_label_positions": quantitative_changes_on_same_labels,
                "note": "Examina apenas as primeiras duas células; sem tipo/grupo oficial ou validade mensal comprovados.",
            },
            "to_competence_requested": current,
            "raw_table_diff": raw_diff,
            "month_echo_neutralized_exploratory_diff": neutral_diff,
        })
        print(
            f"[{previous}->{current}] "
            f"RAW_CHANGED={raw_diff['replace_rows'] + raw_diff['insert_rows'] + raw_diff['delete_rows']} "
            f"MONTH_NEUTRAL_CHANGED={neutral_diff['replace_rows'] + neutral_diff['insert_rows'] + neutral_diff['delete_rows']} "
            f"EQUAL={raw_diff['equal_rows']} "
            f"LABEL_ADD={sum(added_class.values())} LABEL_REMOVE={sum(removed_class.values())} "
            f"NUMERIC_OR_REST_CHANGE_SAME_LABEL={quantitative_changes_on_same_labels}"
        )

    result = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C4_2B3_OFFLINE_TABLE_ROW_COMPARISON",
        "status": "SEMANTIC_INSPECTION_REQUIRED",
        "mode": "LOCAL_CAPTURE_READ_ONLY",
        "capture_integrity": "PASS",
        "captured_htmls": captures,
        "comparisons": comparisons,
        "limitations": {
            "table_html_rows_are_normative_domain": False,
            "first_two_cells_capture_parent_type_group": False,
            "code_description_stability_proves_historical_validity": False,
            "capture_competence_explicitly_verified": False,
            "request_month_neutralization_is_validated_semantics": False,
            "historical_full_domain_confirmed": False,
            "t29_coverage_evaluated": False,
            "qvd_created": False,
        },
    }
    OUTPUT.write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"RESULT={OUTPUT}")
    print("OFFICIAL_DOMAIN=NOT_APPROVED")
    print("T29_COVERAGE=NOT_EVALUATED")
    print("VERDICT=SEMANTIC_INSPECTION_REQUIRED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
