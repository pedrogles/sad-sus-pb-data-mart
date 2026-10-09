#!/usr/bin/env python3
"""IV-PROCEDIMENTO: auditoria somente leitura de nomes oficiais SIGTAP.

Precondition: SHA-256 dos 216 membros e manifesto PASS (auditor existente).
Valida a interpretação cp1252, sem promovê-la automaticamente a decisão:
- posições de layout oficiais e contagem por competência do manifesto;
- 36 meses × 3 descrições, bytes altos, decode cp1252 estrito;
- rejeita controles, texto vazio e possíveis sequências de mojibake;
- apresenta amostras acentuadas por nível e competência para revisão humana.
Não grava arquivos, não produz QVD nem modifica referências existentes.
"""
from __future__ import annotations

import csv
import hashlib
import io
import re
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

from audit_sigtap_hierarchy_history import main as audit_sha_main
from inspect_sigtap_hierarchy_sample import LEVEL_FILES
from materialize_sigtap_procedure_history import COMPETENCES
from validate_sigtap_hierarchy_relational_pilot import (
    DESCRIPTION_FIELDS, KEY_FIELDS, LAYOUT_HASHES,
)
import json

ROOT = Path("BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO")
MANIFEST = Path("BASE/REFERENCIAS/sigtap_hierarchy_history_manifest.json")
MONTHS_TO_PREVIEW = {"201701", "201801", "201901", "201912"}
PREVIEW_PER_LEVEL = 8
# Sequências típicas de UTF-8 decodificado incorretamente como cp1252;
# contagem de suspeitas é sinal de revisão, não normalização automática.
MOJIBAKE = re.compile(
    r"(?:Ã[\u00a0-\u00bf]|Â[\u00a0-\u00bf]|â€)"
)


def layout_fields(month: str, level: str) -> tuple[list[dict], int]:
    path = ROOT / month / (level + "_layout.txt")
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != LAYOUT_HASHES[level]:
        raise RuntimeError(f"SHA do layout alterado: {month}/{level}")
    reader = csv.DictReader(
        io.StringIO(raw.decode("ascii", errors="strict")), delimiter=","
    )
    if reader.fieldnames != ["Coluna", "Tamanho", "Inicio", "Fim", "Tipo"]:
        raise RuntimeError(f"Cabecalho de layout divergente: {month}/{level}")
    expected = (*KEY_FIELDS[level], DESCRIPTION_FIELDS[level], "DT_COMPETENCIA")
    cols = []
    previous_end = 0
    for row in reader:
        if None in row or any(value is None for value in row.values()):
            raise RuntimeError(f"Layout invalido: {month}/{level}")
        name = row["Coluna"].strip()
        width = int(row["Tamanho"])
        start = int(row["Inicio"])
        end = int(row["Fim"])
        if (width <= 0 or start != previous_end+1 or end != start+width-1):
            raise RuntimeError(f"Posicoes de layout divergentes: {month}/{level}")
        cols.append({"field": name, "start": start-1, "end": end})
        previous_end = end
    if tuple(c["field"] for c in cols) != expected:
        raise RuntimeError(f"Campos oficiais diferentes: {month}/{level}")
    return cols, previous_end


def review_text() -> int:
    # Independente do perfil textual: reconciliar todos os arquivos antes.
    if audit_sha_main() != 0:
        raise RuntimeError("Gate SHA de 216 arquivos nao passou")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    per_month = {x["competence"]: x for x in manifest["records_by_month"]}
    counts = Counter()
    unique_names: dict[str, set[str]] = defaultdict(set)
    preview: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    preview_names: dict[str, set[str]] = defaultdict(set)
    issues: list[str] = []
    versions: dict[str, dict[str, set[str]]] = defaultdict(
        lambda: defaultdict(set)
    )

    for month in COMPETENCES:
        for level in LEVEL_FILES:
            cols, record_width = layout_fields(month, level)
            col_map = {c["field"]: c for c in cols}
            desc_name = DESCRIPTION_FIELDS[level]
            desc = col_map[desc_name]
            path = ROOT / month / (level + ".txt")
            data = path.read_bytes().splitlines()
            count_key = {
                "tb_grupo": "groups",
                "tb_sub_grupo": "subgroups",
                "tb_forma_organizacao": "forms",
            }[level]
            if len(data) != int(per_month[month][count_key]):
                raise RuntimeError(
                    f"Linhas divergentes do manifesto: {month}/{level}"
                )
            seen_keys = set()
            for index, row in enumerate(data, 1):
                if len(row) != record_width:
                    raise RuntimeError(f"Largura invalida: {month}/{level}/{index}")
                parts = []
                for name in KEY_FIELDS[level]:
                    c = col_map[name]
                    code = row[c["start"]:c["end"]]
                    if not code or any(b < 48 or b > 57 for b in code):
                        raise RuntimeError(
                            f"Codigo invalido: {month}/{level}/{index}/{name}"
                        )
                    parts.append(code.decode("ascii"))
                version_key = "".join(parts)
                if version_key in seen_keys:
                    raise RuntimeError(f"Chave duplicada: {month}/{level}/{version_key}")
                seen_keys.add(version_key)
                cmpt = col_map["DT_COMPETENCIA"]
                if row[cmpt["start"]:cmpt["end"]] != month.encode("ascii"):
                    raise RuntimeError(f"Competencia divergente: {month}/{level}/{index}")

                raw_name = row[desc["start"]:desc["end"]].rstrip(b" ")
                counts[level + "_total"] += 1
                if not raw_name:
                    counts[level + "_blank"] += 1
                    issues.append(f"{month}/{level}/{version_key}:EMPTY")
                    continue
                has_high = any(byte >= 128 for byte in raw_name)
                if has_high:
                    counts[level + "_high_bit"] += 1
                    try:
                        raw_name.decode("utf-8", errors="strict")
                        counts[level + "_utf8_strict_compatible_high_bit"] += 1
                    except UnicodeDecodeError:
                        counts[level + "_utf8_invalid_high_bit"] += 1
                try:
                    name_text = raw_name.decode("cp1252", errors="strict")
                except UnicodeDecodeError:
                    counts[level + "_cp1252_decode_error"] += 1
                    issues.append(f"{month}/{level}/{version_key}:CP1252_UNDEFINED_BYTE")
                    continue

                if any(unicodedata.category(c).startswith("C") for c in name_text):
                    counts[level + "_unicode_controls"] += 1
                    issues.append(f"{month}/{level}/{version_key}:CONTROL_CHARACTER")
                if MOJIBAKE.search(name_text):
                    counts[level + "_suspect_mojibake"] += 1
                    issues.append(f"{month}/{level}/{version_key}:SUSPECT_MOJIBAKE")
                if not name_text.strip():
                    counts[level + "_blank"] += 1
                    issues.append(f"{month}/{level}/{version_key}:BLANK_AFTER_DECODE")

                unique_names[level].add(name_text)
                versions[level][version_key].add(name_text)
                # Seleção pequena, determinística e diversificada de textos
                # acentuados dos quatro meses de referência conhecidos.
                if (
                    month in MONTHS_TO_PREVIEW
                    and has_high
                    and name_text not in preview_names[level]
                    and len(preview[level]) < PREVIEW_PER_LEVEL
                ):
                    preview[level].append((month, version_key, name_text))
                    preview_names[level].add(name_text)

    for level in LEVEL_FILES:
        revised = sum(
            len(names) > 1 for names in versions[level].values()
        )
        print(f"LEVEL={level}")
        print(f"  RECORDS={counts[level + '_total']}")
        print(f"  DISTINCT_DESCRIPTIONS={len(unique_names[level])}")
        print(f"  ROWS_WITH_HIGH_BIT_BYTES={counts[level + '_high_bit']}")
        print(f"  HIGH_BIT_UTF8_STRICT_POSSIBLE={counts[level + '_utf8_strict_compatible_high_bit']}")
        print(f"  HIGH_BIT_UTF8_STRICT_INVALID={counts[level + '_utf8_invalid_high_bit']}")
        print(f"  CP1252_DECODE_ERRORS={counts[level + '_cp1252_decode_error']}")
        print(f"  EMPTY_OR_BLANK={counts[level + '_blank']}")
        print(f"  CONTROL_CHARACTERS={counts[level + '_unicode_controls']}")
        print(f"  SUSPECT_MOJIBAKE={counts[level + '_suspect_mojibake']}")
        print(f"  KEYS_WITH_MULTIPLE_DESCRIPTIONS_OVER_TIME={revised}")
        for month, code, example in preview[level]:
            print(f"  ACCENTED_SAMPLE {month}/{code}: {example}")

    print("TOTAL_DESCRIPTION_ROWS=" + str(
        sum(counts[level + "_total"] for level in LEVEL_FILES)
    ))
    print("TEXT_ISSUES_TOTAL=" + str(len(issues)))
    for issue in issues[:15]:
        print("TEXT_ISSUE_SAMPLE=" + issue)
    print("FILES_VERIFIED_BEFORE_TEXT=216")
    print("DESCRIPTION_ENCODING_APPROVAL=NOT_APPROVED")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("OUTPUT_FILES_WRITTEN=0")
    if issues:
        print("VERDICT=REVIEW_SIGTAP_DESCRIPTION_ENCODING_ISSUES")
        return 2
    print("VERDICT=PASS_CP1252_TEXT_SANITY_CANDIDATE_ONLY")
    print("NEXT=MANUAL_REVIEW_ACCENTED_SAMPLES_AND_UTF8_COMPARISON")
    return 0


if __name__ == "__main__":
    raise SystemExit(review_text())
