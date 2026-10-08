#!/usr/bin/env python3
"""III-C4.2c.2: audita links tipo/leito de 5 HTMLs CNESNet já capturados.

Sem rede; entradas somente leitura; saída JSON local ignorada pelo Git.
Relatórios operacionais NÃO comprovam vigência normativa; T29 segue pendente.
"""
from __future__ import annotations

import csv
import hashlib
import json
import re
import unicodedata
from bisect import bisect_right
from datetime import datetime, timezone
from html import unescape
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

from audit_cnes_official_domains import load_domains

ROOT = Path("BASE/REFERENCIAS")
PROBES = ROOT / "cnes_leito_history_probe"
MANIFEST = PROBES / "probe_summary.json"
PROFILE = ROOT / "cnes_lt_bed_code_pair_profile.csv"
DOMAINS = ROOT / "SCNES_DOMINIOS.XLS"
OUTPUT = PROBES / "grouped_type_code_audit.json"
MONTHS = ("201712", "201801", "201805", "201806", "201912")
HEADERS = re.compile(
    r'<td\s+colspan=["\']?3["\']?\s*>\s*<font[^>]*>([^<]+)</font>\s*</td>', re.I
)
LINKS = re.compile(
    r'<a\s+href="(Mod_Ind_Leitos_Listar\.asp\?[^"]+)">(.*?)</a>', re.I | re.S
)
ROW_CODE = re.compile(
    r'<td\s+align=["\']?center["\']?[^>]*>\s*<font[^>]*>\s*([0-9]{2})\s*</font>', re.I
)


def sha256(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def norm(value: str) -> str:
    value = unescape(re.sub(r"<[^>]*>", "", value))
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    return " ".join(value.upper().split())


# Variantes textuais comprovadas por inspecao de SCNES_DOMINIOS.XLS e CNESNet.
# Chave: (tipo numerico, descricao EXATA da planilha); valor: cabecalho HTML.
# Isto NAO equivale codigos diferentes nem altera tipo/leito dos dados CNES/LT.
GROUP_DISPLAY_ALIASES = {
    ("4", "OBSTETRICOS"): "OBSTETRICO",
    ("5", "PEDIATRICOS"): "PEDIATRICO",
}


def expected_group(kind: str, domain_description: str) -> str:
    official = norm(domain_description)
    return GROUP_DISPLAY_ALIASES.get((kind, official), official)


def extract(html: str, competence: str, leitos: dict, tipos: dict) -> tuple[list[dict], list[dict]]:
    headings = [(m.start(), norm(m.group(1))) for m in HEADERS.finditer(html)]
    allowed_groups = {expected_group(kind, description) for kind, description in tipos.items()}
    issues: list[dict] = []
    if len(headings) != 7 or {v for _, v in headings} != allowed_groups:
        issues.append({"kind": "HEADERS_MISMATCH", "headings": [v for _, v in headings]})
    starts = [pos for pos, _ in headings]
    rows: list[dict] = []
    for match in LINKS.finditer(html):
        params = parse_qs(urlsplit(unescape(match.group(1))).query, keep_blank_values=True)

        def get(name: str) -> str:
            values = params.get(name, [])
            return values[0] if len(values) == 1 else ""

        code, kind, month = get("VCod_Leito"), get("VTipo_Leito"), get("VComp")
        description = " ".join(
            unescape(re.sub(r"<[^>]*>", "", match.group(2))).split()
        )
        idx = bisect_right(starts, match.start()) - 1
        group = headings[idx][1] if idx >= 0 else None
        tr_start = html.rfind("<tr bgcolor=", 0, match.start())
        cell = ROW_CODE.search(html[tr_start:match.start()]) if tr_start >= 0 else None
        displayed = cell.group(1) if cell else None
        item = {"group": group, "type": kind, "code": code, "description": description}
        rows.append(item)
        if (
            not re.fullmatch(r"[0-9]{2}", code)
            or not re.fullmatch(r"[1-7]", kind)
            or displayed != code
            or kind not in tipos
            or code not in leitos
            or group != expected_group(kind, tipos.get(kind, ""))
            or month != competence
            or get("VEstado") != "00"
        ):
            issues.append({
                "kind": "LINK_OR_GROUP_MISMATCH",
                **item, "displayed_code": displayed, "link_competence": month,
            })
    pairs = [(row["type"], row["code"]) for row in rows]
    if len(rows) != 65 or len(set(pairs)) != 65:
        issues.append({
            "kind": "UNEXPECTED_LINK_COUNT_OR_DUPLICATES",
            "links": len(rows), "distinct_pairs": len(set(pairs)),
        })
    return rows, issues


def main() -> int:
    for path in (MANIFEST, PROFILE, DOMAINS):
        if not path.is_file():
            raise RuntimeError(f"Entrada ausente: {path}")
    leitos, tipos, _ = load_domains(DOMAINS)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    sources = {item["requested_competence"]: item for item in manifest["sources"]}
    if len(sources) != 5 or set(sources) != set(MONTHS):
        raise RuntimeError("Manifesto deve conter exatamente as cinco capturas esperadas")
    with PROFILE.open(encoding="utf-8", newline="") as file:
        observed = list(csv.DictReader(file, delimiter=";"))
    expected: set[tuple[str, str]] = set()
    total = 0
    for row in observed:
        kind, code = row["tp_leito_raw"], row["codleito_raw"]
        if not re.fullmatch(r"[1-7] ", kind) or not re.fullmatch(r"[0-9]{2}", code):
            raise RuntimeError(f"Perfil LT com formato inesperado: {row}")
        expected.add((kind[0], code))
        total += int(row["occurrences"])
    if len(observed) != 57 or len(expected) != 57 or total != 35518:
        raise RuntimeError("Perfil LT diverge do checkpoint III-C4.1 validado")

    records: list[dict] = []
    sets: list[set[tuple[str, str]]] = []
    all_rows: list[list[dict]] = []
    issues_total = 0
    for competence in MONTHS:
        src = sources[competence]
        path = PROBES / f"CNES_Leitos_Indicadores_{competence}_UF00.html"
        if src.get("status") != "HTTP_HTML_CAPTURED_REVIEW_REQUIRED" or not path.is_file():
            raise RuntimeError(f"Captura incompleta: {competence}")
        raw = path.read_bytes()
        if sha256(raw) != src.get("sha256") or len(raw) != src.get("bytes"):
            raise RuntimeError(f"Hash/tamanho divergente no HTML: {competence}")
        rows, problems = extract(
            raw.decode(src.get("decoded_using") or "cp1252", errors="strict"),
            competence, leitos, tipos,
        )
        pairs = {(row["type"], row["code"]) for row in rows}
        sets.append(pairs)
        all_rows.append(rows)
        issues_total += len(problems)
        missing = sorted(expected - pairs)
        records.append({
            "requested_competence": competence,
            "html_sha256": sha256(raw),
            "links": len(rows),
            "distinct_pairs": len(pairs),
            "observed_pb_pairs_matched": len(expected & pairs),
            "observed_pb_pairs_missing": [{"type": t, "code": c} for t, c in missing],
            "issues": problems,
        })
        print(
            f"[{competence}] LINKS={len(rows)} PAIRS={len(pairs)} "
            f"PB_MATCHED={len(expected & pairs)}/57 ISSUES={len(problems)}"
        )
    union = set.union(*sets)
    common = set.intersection(*sets)
    changed = sorted({
        pair for pair in union
        if len({row["description"] for rows in all_rows for row in rows
                if (row["type"], row["code"]) == pair}) > 1
    })
    passed = issues_total == 0 and all(expected <= pairs for pairs in sets) and not changed
    status = "OPERATIONAL_GROUPED_LINKS_PROVISIONAL" if passed else "REVIEW_REQUIRED"
    output = {
        "stage": "III_C4_2C_2_CNES_GROUPED_LINK_ASSOCIATIONS",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": status,
        "source": "CNESNet indicator HTML, not a normative domain table",
        "source_files_read_only": True,
        "official_domain_sha256": sha256(DOMAINS.read_bytes()),
        "profile_sha256": sha256(PROFILE.read_bytes()),
        "expected_pb_pairs": len(expected),
        "expected_pb_rows": total,
        "accepted_group_label_aliases": [
            {"type": kind, "domain_label": domain_label, "html_label": html_label}
            for (kind, domain_label), html_label in sorted(GROUP_DISPLAY_ALIASES.items())
        ],
        "records": records,
        "common_pairs_across_captures": len(common),
        "union_pairs_across_captures": len(union),
        "missing_pb_pairs_in_all_captures": [
            {"type": t, "code": c} for t, c in sorted(expected - union)
        ],
        "pairs_with_different_descriptions": [
            {"type": t, "code": c} for t, c in changed
        ],
        "issues_total": issues_total,
        "limits": {
            "competence_selection_actually_applied_verified": False,
            "normative_historical_validity_2017_2019_verified": False,
            "t29_approved": False,
            "qvd_created": False,
        },
    }
    OUTPUT.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("SUMMARY=", OUTPUT)
    print("VERDICT=", status)
    print("T29=NOT_APPROVED")
    return 0 if passed else 2


if __name__ == "__main__":
    raise SystemExit(main())
