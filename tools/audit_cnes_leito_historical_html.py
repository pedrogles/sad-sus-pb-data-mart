#!/usr/bin/env python3
"""C4.2b.2 — auditoria offline de cinco HTMLs históricos CNES já capturados.

Não efetua requisições de rede, não altera os HTMLs/manifesto original e não
cria tabelas de domínio, cobertura T29 ou QVDs.

Entrada: BASE/REFERENCIAS/cnes_leito_history_probe/probe_summary.json
Saída: BASE/REFERENCIAS/cnes_leito_history_probe/html_diff_audit_summary.json
"""

from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from html import unescape
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path("BASE/REFERENCIAS/cnes_leito_history_probe")
MANIFEST = ROOT / "probe_summary.json"
OUTPUT = ROOT / "html_diff_audit_summary.json"
EXPECTED = ("201712", "201801", "201805", "201806", "201912")


def sha256(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


class CNESHtmlInspection(HTMLParser):
    """Inspeciona somente sinais explícitos de competência e texto visível."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.ignore_depth = 0
        self.is_competence_select = False
        self.selected_values: list[str] = []
        self.select_options: list[str] = []
        self.competence_inputs: list[str] = []
        self.visible_parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        tag = tag.lower()
        attr = {k.lower(): v for k, v in attrs}
        if tag in ("script", "style"):
            self.ignore_depth += 1
        elif tag == "select":
            label = (attr.get("name") or "") + " " + (attr.get("id") or "")
            self.is_competence_select = "comp" in label.lower()
        elif tag == "option" and self.is_competence_select:
            value = attr.get("value") or ""
            if value:
                self.select_options.append(value)
                if "selected" in attr:
                    self.selected_values.append(value)
        elif tag == "input":
            label = (attr.get("name") or "") + " " + (attr.get("id") or "")
            if "comp" in label.lower():
                value = attr.get("value")
                if value:
                    self.competence_inputs.append(value)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag in ("script", "style") and self.ignore_depth > 0:
            self.ignore_depth -= 1
        elif tag == "select":
            self.is_competence_select = False

    def handle_data(self, data: str) -> None:
        if not self.ignore_depth and data.strip():
            self.visible_parts.append(data.strip())


def parse_html(raw: bytes, encoding: str) -> tuple[CNESHtmlInspection, str]:
    html = raw.decode(encoding, errors="strict")
    parsed = CNESHtmlInspection()
    parsed.feed(html)
    visible = re.sub(r"\s+", " ", unescape(" ".join(parsed.visible_parts))).strip()
    return parsed, visible


def main() -> int:
    if not MANIFEST.is_file():
        raise RuntimeError(f"Manifesto ausente: {MANIFEST}")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    sources = manifest.get("sources", [])
    found = [item.get("requested_competence") for item in sources]
    if len(found) != len(EXPECTED) or set(found) != set(EXPECTED):
        raise RuntimeError(
            f"Competências da captura divergentes: {found}; esperado={EXPECTED}"
        )

    rows: list[dict] = []
    integrity_failures = 0
    for source in sorted(sources, key=lambda item: item["requested_competence"]):
        competence = source["requested_competence"]
        expected_name = f"CNES_Leitos_Indicadores_{competence}_UF00.html"
        path = ROOT / expected_name
        report: dict = {
            "competence": competence,
            "html_file": str(path),
            "status": "NOT_EVALUATED",
        }
        if source.get("status") != "HTTP_HTML_CAPTURED_REVIEW_REQUIRED":
            report["status"] = "INVALID_SOURCE_STATUS"
            integrity_failures += 1
            rows.append(report)
            continue
        if not path.is_file():
            report["status"] = "MISSING_HTML"
            integrity_failures += 1
            rows.append(report)
            continue

        raw = path.read_bytes()
        actual_sha = sha256(raw)
        hash_match = actual_sha == source.get("sha256")
        size_match = len(raw) == source.get("bytes")
        report.update({
            "html_sha256": actual_sha,
            "bytes": len(raw),
            "manifest_hash_match": hash_match,
            "manifest_size_match": size_match,
        })
        if not hash_match or not size_match:
            report["status"] = "CAPTURE_INTEGRITY_FAILED"
            integrity_failures += 1
            rows.append(report)
            continue

        encoding = source.get("decoded_using") or "cp1252"
        try:
            parser, visible = parse_html(raw, encoding)
        except (UnicodeError, LookupError, ValueError) as exc:
            report["status"] = "DECODE_FAILED"
            report["error"] = f"{type(exc).__name__}: {exc}"
            integrity_failures += 1
            rows.append(report)
            continue

        selected = parser.selected_values
        input_values = parser.competence_inputs
        # Não usar presença simples no HTML; pode constar em opções não selecionadas.
        explicit = sorted(set(selected + input_values))
        confirmed = explicit == [competence]
        # Assinatura do conteúdo visível a partir do primeiro grupo de leitos.
        upper = visible.upper()
        offsets = [upper.find(word) for word in ("CIRÚRGICO", "CIRURGICO")]
        start = next((x for x in offsets if x >= 0), -1)
        bed_content = visible[start:] if start >= 0 else ""
        bed_sha = sha256(bed_content.encode("utf-8")) if bed_content else None
        report.update({
            "status": "CAPTURE_VALID_SOURCE_INTERPRETATION_PENDING",
            "encoding": encoding,
            "selected_competence_values": selected[:12],
            "competence_input_values": input_values[:12],
            "comp_options_count": len(parser.select_options),
            "requested_competence_present_in_html": (
                competence in raw.decode(encoding, errors="replace")
            ),
            "competence_explicitly_confirmed": confirmed,
            "visible_text_length": len(visible),
            "visible_text_sha256": sha256(visible.encode("utf-8")),
            "bed_content_start_found": start >= 0,
            "bed_content_sha256": bed_sha,
            "bed_content_length": len(bed_content),
            "code70_description_in_bed_content": bool(
                re.search(r"\b70\s+FIBROSE\s+CISTICA\b", bed_content, re.I)
            ),
        })
        rows.append(report)
        print(
            f"[{competence}] HASH_OK=True "
            f"EXPLICIT_COMPETENCE={confirmed} "
            f"SELECTED={selected[:3]} INPUT={input_values[:3]} "
            f"HTML_SHA={actual_sha[:12]} TEXT_SHA={report['visible_text_sha256'][:12]} "
            f"BED_SHA={bed_sha[:12] if bed_sha else 'NOT_FOUND'}"
        )

    good = [row for row in rows if row.get("status") ==
            "CAPTURE_VALID_SOURCE_INTERPRETATION_PENDING"]
    distinct_html = len({x["html_sha256"] for x in good})
    distinct_text = len({x["visible_text_sha256"] for x in good})
    distinct_bed = len({x["bed_content_sha256"] for x in good
                        if x["bed_content_sha256"]})
    result = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C4_2B2_OFFLINE_HTML_DIFFERENTIAL_AUDIT",
        "mode": "READ_ONLY_LOCAL_CAPTURE_ANALYSIS",
        "status": (
            "CAPTURE_INTEGRITY_FAILED" if integrity_failures
            else "HTML_COMPARISON_REVIEW_REQUIRED"
        ),
        "captured_samples_expected": len(EXPECTED),
        "captured_samples_verified": len(good),
        "integrity_failures": integrity_failures,
        "distinct_html_hashes": distinct_html,
        "distinct_visible_text_hashes": distinct_text,
        "distinct_bed_content_hashes": distinct_bed,
        "competences_explicitly_confirmed": sum(
            x.get("competence_explicitly_confirmed", False) for x in good
        ),
        "records": rows,
        "limits": {
            "hash_differences_prove_historical_content": False,
            "selected_competence_missing_is_ignored_parameter_proof": False,
            "official_complete_domain_verified": False,
            "t29_coverage_evaluated": False,
            "qvd_created": False,
        },
    }
    OUTPUT.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"VERIFIED_HTML={len(good)}")
    print(f"DISTINCT_HTML_HASHES={distinct_html}")
    print(f"DISTINCT_VISIBLE_TEXT_HASHES={distinct_text}")
    print(f"DISTINCT_BED_CONTENT_HASHES={distinct_bed}")
    print(f"EXPLICIT_COMPETENCES={result['competences_explicitly_confirmed']}")
    print(f"INTEGRITY_FAILURES={integrity_failures}")
    print(f"SUMMARY={OUTPUT}")
    print(f"VERDICT={result['status']}")
    print("T29_COVERAGE=NOT_EVALUATED")
    return 2 if integrity_failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
