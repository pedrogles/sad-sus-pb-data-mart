#!/usr/bin/env python3
"""IV-PROCEDIMENTO — diagnóstico read-only da codificação e nomes temporais.

- Exige auditoria SHA anterior (216 TXT SIGTAP + manifesto).
- Perfila bytes de descricao 0x80..0x9f para distinguir cp1252/Latin-1.
- Identifica exatamente as chaves cujos nomes mudaram, COM competência.
- Não altera, renomeia, corrige ou grava atributos/documentos/QVD.
"""
from __future__ import annotations

import json
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

from audit_sigtap_hierarchy_history import main as audit_sha_main
from audit_sigtap_hierarchy_descriptions import layout_fields
from inspect_sigtap_hierarchy_sample import LEVEL_FILES
from materialize_sigtap_procedure_history import COMPETENCES
from validate_sigtap_hierarchy_relational_pilot import KEY_FIELDS, DESCRIPTION_FIELDS

ROOT = Path("BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO")
MANIFEST = Path("BASE/REFERENCIAS/sigtap_hierarchy_history_manifest.json")
EXPECTED = {
    "tb_grupo": (288, 0),
    "tb_sub_grupo": (2124, 3),
    "tb_forma_organizacao": (13835, 3),
}
FIELDS_COUNT = {
    "tb_grupo": "groups",
    "tb_sub_grupo": "subgroups",
    "tb_forma_organizacao": "forms",
}


def main() -> int:
    if audit_sha_main() != 0:
        raise RuntimeError("Auditoria da origem fisica 216/216 nao passou")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    rows_by_month = {r["competence"]: r for r in manifest["records_by_month"]}
    if set(rows_by_month) != set(COMPETENCES):
        raise RuntimeError("Competencias de origem do manifesto divergentes")

    monthly_versions: dict[str, dict[str, list[tuple[str, str]]]] = {
        level: defaultdict(list) for level in LEVEL_FILES
    }
    byte_counts: Counter[int] = Counter()
    description_rows = Counter()
    c1_rows = Counter()

    for month in COMPETENCES:
        for level in LEVEL_FILES:
            fields, width = layout_fields(month, level)
            columns = {col["field"]: col for col in fields}
            path = ROOT / month / f"{level}.txt"
            data = path.read_bytes().splitlines()
            if len(data) != int(rows_by_month[month][FIELDS_COUNT[level]]):
                raise RuntimeError(f"Contagem em {month}/{level} difere do manifesto")

            seen: set[str] = set()
            for index, raw in enumerate(data, 1):
                if len(raw) != width:
                    raise RuntimeError(f"Largura de linha invalida: {month}/{level}/{index}")
                keys = []
                for field in KEY_FIELDS[level]:
                    region = columns[field]
                    part = raw[region["start"]:region["end"]]
                    if not part or not all(48 <= b <= 57 for b in part):
                        raise RuntimeError(f"Codigo invalido: {month}/{level}/{field}/{index}")
                    keys.append(part.decode("ascii"))
                key = "".join(keys)
                if key in seen:
                    raise RuntimeError(f"Chave duplicada: {month}/{level}/{key}")
                seen.add(key)
                cmpt = columns["DT_COMPETENCIA"]
                if raw[cmpt["start"]:cmpt["end"]] != month.encode("ascii"):
                    raise RuntimeError(f"Competencia divergente: {month}/{level}/{index}")

                region = columns[DESCRIPTION_FIELDS[level]]
                name_bytes = raw[region["start"]:region["end"]].rstrip(b" ")
                if not name_bytes:
                    raise RuntimeError(f"Descricao vazia: {month}/{level}/{key}")
                try:
                    text = name_bytes.decode("cp1252", errors="strict")
                except UnicodeDecodeError as exc:
                    raise RuntimeError(
                        f"Byte nao definido em cp1252: {month}/{level}/{key}"
                    ) from exc
                if not text.strip() or any(
                    unicodedata.category(ch).startswith("C") for ch in text
                ):
                    raise RuntimeError(f"Texto invalido/control: {month}/{level}/{key}")

                description_rows[level] += 1
                has_c1 = False
                for b in name_bytes:
                    if 0x80 <= b <= 0x9F:
                        byte_counts[b] += 1
                        has_c1 = True
                if has_c1:
                    c1_rows[level] += 1
                monthly_versions[level][key].append((month, text))

    print("MODE=SIGTAP_HIERARCHY_LABEL_TRANSITIONS_AND_BYTE_DIFFERENTIAL")
    print("COMPETENCES=36")
    print("FILES_AUDITED=216")
    print("DESCRIPTION_ENCODING_APPROVAL=NOT_APPROVED")
    for level in LEVEL_FILES:
        records = description_rows[level]
        changed_keys = {
            key: seq
            for key, seq in monthly_versions[level].items()
            if len({text for _, text in seq}) > 1
        }
        expected_records, expected_changes = EXPECTED[level]
        if records != expected_records or len(changed_keys) != expected_changes:
            raise RuntimeError(
                f"Contagem/chaves alteradas divergentes em {level}: "
                f"records={records}, changed_keys={len(changed_keys)}"
            )
        print(
            f"LEVEL={level} DESCRIPTION_ROWS={records} "
            f"CHANGED_KEYS={len(changed_keys)} ROWS_WITH_C1_BYTES={c1_rows[level]}"
        )
        for key, seq in sorted(changed_keys.items()):
            print(f"CHANGED_KEY={level}/{key} DISTINCT_LABELS={len({name for _, name in seq})}")
            previous_label = None
            for month, label in seq:
                if label != previous_label:
                    print(f"  LABEL_FROM_OBSERVED_MONTH={month} TEXT={label!r}")
                previous_label = label

    print("TOTAL_DESCRIPTION_ROWS=" + str(sum(description_rows.values())))
    print("C1_0X80_TO_0X9F_BYTE_OCCURRENCES=" + str(sum(byte_counts.values())))
    for byte, n in sorted(byte_counts.items()):
        latin1 = chr(byte)
        cp1252 = bytes([byte]).decode("cp1252", errors="strict")
        print(
            f"C1_BYTE=0x{byte:02X} COUNT={n} "
            f"CP1252={cp1252!r} ISO_8859_1={latin1.encode('unicode_escape').decode()}"
        )
    if byte_counts:
        print("CP1252_VS_ISO88591=DIFFERENCE_OBSERVED_HUMAN_REVIEW_REQUIRED")
    else:
        print("CP1252_VS_ISO88591=NOT_DISTINGUISHABLE_WITH_OBSERVED_TEXT_BYTES")
    print("STAGING_FILES_WRITTEN=0")
    print("QVD_GENERATED=False")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("VERDICT=PASS_SIGTAP_LABEL_VERSION_AND_BYTE_PROFILE_REVIEW_ONLY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
