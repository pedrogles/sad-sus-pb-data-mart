#!/usr/bin/env python3
"""Fase III-C4.2b — sonda pequena das consultas históricas oficiais de leitos CNES.

Consulta somente cinco competências pré-selecionadas em indicadores CNES
(não baixa bases CNES, não cria referência de domínio, não calcula T29).
Conserva o HTML de resposta bruto, com SHA-256, para inspeção humana.

Saídas não versionadas: BASE/REFERENCIAS/cnes_leito_history_probe/
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from html import unescape
from html.parser import HTMLParser
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, urlopen

HOST = "cnes2.datasus.gov.br"
URL = f"https://{HOST}/Mod_Ind_Tipo_Leito.asp"
COMPETENCES = ("201712", "201801", "201805", "201806", "201912")
OUTPUT_DIR = Path("BASE/REFERENCIAS/cnes_leito_history_probe")
MANIFEST = OUTPUT_DIR / "probe_summary.json"
TIMEOUT_SECONDS = 18
MAX_RESPONSE_BYTES = 2_000_000


class TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._ignore_depth = 0

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.lower() in ("script", "style"):
            self._ignore_depth += 1

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() in ("script", "style") and self._ignore_depth > 0:
            self._ignore_depth -= 1

    def handle_data(self, data: str) -> None:
        if self._ignore_depth == 0 and data.strip():
            self.parts.append(data.strip())


def decode_html(raw: bytes, declared_charset: str | None) -> tuple[str, str]:
    candidates: list[str] = []
    if declared_charset:
        candidates.append(declared_charset)
    head = raw[:8_192].decode("ascii", errors="ignore")
    matched = re.search(
        r"""<meta[^>]+charset\s*=\s*["']?([\w\-]+)""",
        head,
        re.IGNORECASE,
    )
    if matched:
        candidates.append(matched.group(1))
    candidates.extend(["utf-8", "cp1252"])
    for encoding in dict.fromkeys(candidates):
        try:
            return raw.decode(encoding, errors="strict"), encoding
        except (LookupError, UnicodeDecodeError):
            continue
    return raw.decode("utf-8", errors="replace"), "utf-8-replacement"


def selected_option_values(html: str) -> list[str]:
    # Apenas evidência auxiliar: não assume estrutura ou nome de <select>.
    result: list[str] = []
    for attrs in re.findall(r"<option\b([^>]*)>", html, re.IGNORECASE):
        if re.search(r"\bselected\b", attrs, re.IGNORECASE):
            value = re.search(r"""\bvalue\s*=\s*["']?([\w\-]+)""", attrs, re.IGNORECASE)
            if value:
                result.append(value.group(1))
    return result


def inspect_response(html: str, competence: str) -> dict:
    parser = TextExtractor()
    try:
        parser.feed(html)
        visible = unescape(" ".join(parser.parts))
        parse_error: str | None = None
    except Exception as exc:
        visible = ""
        parse_error = f"{type(exc).__name__}: {exc}"
    normal = re.sub(r"\s+", " ", visible).upper()
    selected = selected_option_values(html)
    signals = {
        "indicadores": "INDICADORES" in normal,
        "leitos": "LEITOS" in normal,
        "grupo_hospital_dia": "HOSPITAL DIA" in normal,
        "grupo_complementar": "COMPLEMENTAR" in normal,
        "codigo_70_texto": bool(re.search(r"\b70\s+FIBROSE\s+CISTICA\b", normal)),
        "requested_competence_selected": competence in selected,
    }
    return {
        "selected_option_values": selected[:15],
        "page_signals": signals,
        "html_parse_error": parse_error,
        "visible_text_head": visible[:360],
        "visible_text_tail": visible[-360:],
        "visible_text_length": len(visible),
        "competence_echo_in_visible_text": competence in visible,
        "html_title": (
            unescape(re.search(r"<title[^>]*>(.*?)</title>", html, re.I | re.S).group(1)).strip()
            if re.search(r"<title[^>]*>(.*?)</title>", html, re.I | re.S)
            else None
        ),
    }


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print("MODE=OFFICIAL_CNES_HISTORICAL_INDICATOR_PROBE_ONLY")
    outcomes: list[dict] = []

    for competence in COMPETENCES:
        query = urlencode(
            {"VComp": competence, "VEstado": "00", "VMun": ""}
        )
        url = f"{URL}?{query}"
        item: dict = {
            "requested_competence": competence,
            "requested_uf": "00",
            "url": url,
            "status": "FETCH_FAILED",
        }
        try:
            req = Request(
                url,
                headers={
                    "User-Agent": "SAD-SUS-PB-Academic-ReadOnly-SourceDiscovery/1.0",
                    "Accept": "text/html,application/xhtml+xml",
                },
            )
            with urlopen(req, timeout=TIMEOUT_SECONDS) as response:
                final_url = response.geturl()
                http_status = response.status
                mime = response.headers.get_content_type()
                charset = response.headers.get_content_charset()
                raw = response.read(MAX_RESPONSE_BYTES + 1)

            if (
                http_status != 200
                or (urlsplit(final_url).hostname or "").lower() != HOST
                or not mime.startswith("text/html")
                or len(raw) > MAX_RESPONSE_BYTES
            ):
                raise ValueError(
                    f"Resposta inesperada HTTP={http_status} "
                    f"mime={mime} final_host={urlsplit(final_url).hostname} "
                    f"tamanho={len(raw)}"
                )

            html, encoding = decode_html(raw, charset)
            name = f"CNES_Leitos_Indicadores_{competence}_UF00.html"
            path = OUTPUT_DIR / name
            path.write_bytes(raw)

            item.update({
                "status": "HTTP_HTML_CAPTURED_REVIEW_REQUIRED",
                "response_url": final_url,
                "http_status": http_status,
                "content_type": mime,
                "declared_charset": charset,
                "decoded_using": encoding,
                "html_file": str(path),
                "bytes": len(raw),
                "sha256": hashlib.sha256(raw).hexdigest(),
                "inspection": inspect_response(html, competence),
            })
        except (HTTPError, URLError, TimeoutError, OSError, ValueError) as exc:
            item["error"] = f"{type(exc).__name__}: {exc}"

        outcomes.append(item)
        sig = item.get("inspection", {}).get("page_signals", {})
        print(
            f"[{competence}] STATUS={item['status']} "
            f"BYTES={item.get('bytes', 'NA')} "
            f"CNES_PAGE={sig.get('indicadores', False) and sig.get('leitos', False)} "
            f"COMPETENCE_SELECTED={sig.get('requested_competence_selected', False)} "
            f"CODE70_DESCRIPTION_VISIBLE={sig.get('codigo_70_texto', False)}"
        )
        if item.get("error"):
            print(f"[{competence}] ERROR={item['error']}")

    content = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C4_2B_OFFICIAL_CNES_INDICATOR_SAMPLE_PROBE",
        "mode": "CONTROLLED_SMALL_PUBLIC_SOURCE_ENUMERATION",
        "status": "SOURCE_INSPECTION_PENDING",
        "requested_samples": len(COMPETENCES),
        "captured_samples": sum(x["status"] == "HTTP_HTML_CAPTURED_REVIEW_REQUIRED" for x in outcomes),
        "sources": outcomes,
        "limits": {
            "national_indicator_is_not_full_domain": True,
            "historical_domain_version_not_verified": True,
            "t29_coverage_measured": False,
            "lt_csv_unchanged": True,
            "qlik_qvd_created": False,
            "official_description_key_approved": False,
        },
    }
    MANIFEST.write_text(
        json.dumps(content, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"REQUESTED_SAMPLES={len(COMPETENCES)}")
    print(f"CAPTURED_SAMPLES={content['captured_samples']}")
    print(f"SUMMARY_PATH={MANIFEST}")
    print("HISTORICAL_DOMAIN_REFERENCE=NOT_APPROVED")
    print("T29_COVERAGE=NOT_EVALUATED")
    print("VERDICT=SOURCE_INSPECTION_REQUIRED")
    return 0 if content["captured_samples"] == len(COMPETENCES) else 2


if __name__ == "__main__":
    sys.exit(main())
