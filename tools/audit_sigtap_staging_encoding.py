#!/usr/bin/env python3
"""C3.4a — auditoria read-only das descrições no CSV SIGTAP candidato.

Confere integridade/hash do CSV UTF-8 gerado e exibe amostra diversificada
de nomes com diacríticos, preservando códigos e competência textuais.

Não aprova automaticamente o encoding, não reescreve CSV e não gera QVD.
"""

from __future__ import annotations

import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

from materialize_sigtap_procedure_sample import sha256_file

ROOT = Path("BASE/REFERENCIAS")
MANIFEST = ROOT / "sigtap_procedimento_staging_candidate_manifest.json"
CSV_PATH = ROOT / "sigtap_procedimento_staging_candidate.csv"
SAMPLE_MONTHS = ("201701", "201801", "201901", "201912")
DIACRITICS = {
    "CEDILHA": "Çç",
    "TIL": "ÃÕãõ",
    "AGUDO": "ÁÉÍÓÚáéíóú",
    "CIRCUNFLEXO": "ÂÊÔâêô",
}
BAD_MARKERS = ("\ufffd", "Ãƒ", "Ã‡", "Ã‰", "Ã‚", "Ã“", "Ãš")
EXPECTED_FIELDS = [
    "SIGTAP_COMPETENCIA",
    "SIGTAP_CO_PROCEDIMENTO",
    "SIGTAP_NO_PROCEDIMENTO",
    "SIGTAP_COMPETENCIA_CODIGO",
]


def main() -> int:
    if not MANIFEST.is_file() or not CSV_PATH.is_file():
        raise RuntimeError("C3.4a: CSV e/ou manifesto local ausente")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if (
        manifest.get("stage") != "PHASE_III_C3_4A_SIGTAP_CSV_STAGE_PREPARATION"
        or manifest.get("status") != "STRUCTURE_PASS_ENCODING_REVIEW"
        or manifest.get("rows") != 165203
        or manifest.get("distinct_code_month_keys") != 165203
        or manifest.get("competences") != 36
        or manifest.get("description_encoding", {}).get("candidate") != "cp1252"
        or Path(manifest.get("outputs", {}).get("csv", "")) != CSV_PATH
    ):
        raise RuntimeError("Manifesto C3.4a não atende ao contrato")

    sha = sha256_file(CSV_PATH)
    if sha != manifest["outputs"]["sha256"]:
        raise RuntimeError("CSV foi modificado: hash SHA-256 divergente")

    candidates: dict[tuple[str, str], list[tuple[str, str]]] = defaultdict(list)
    first_descriptions: dict[tuple[str, str], set[str]] = defaultdict(set)
    marker_examples: list[tuple[str, str, str]] = []
    markers: Counter[str] = Counter()
    per_month: Counter[str] = Counter()
    nonascii = 0
    rows = 0
    unique_keys: set[str] = set()
    with CSV_PATH.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        if reader.fieldnames != EXPECTED_FIELDS:
            raise RuntimeError(f"Cabeçalho de CSV alterado: {reader.fieldnames}")
        for row in reader:
            month = row["SIGTAP_COMPETENCIA"]
            code = row["SIGTAP_CO_PROCEDIMENTO"]
            name = row["SIGTAP_NO_PROCEDIMENTO"]
            key = row["SIGTAP_COMPETENCIA_CODIGO"]
            if (
                not re.fullmatch(r"20(?:17|18|19)(?:0[1-9]|1[0-2])", month)
                or not re.fullmatch(r"[0-9]{10}", code)
                or key != f"{month}|{code}"
                or not name
            ):
                raise RuntimeError(f"Chave/descrição inválida na linha {reader.line_num}")
            if key in unique_keys:
                raise RuntimeError(f"Chave duplicada: {key}")
            unique_keys.add(key)
            rows += 1
            per_month[month] += 1
            if any(ord(c) > 127 for c in name):
                nonascii += 1
            for marker in BAD_MARKERS:
                if marker in name:
                    markers[marker] += 1
                    if len(marker_examples) < 12:
                        marker_examples.append((month, code, name))
            if month in SAMPLE_MONTHS:
                for group, chars in DIACRITICS.items():
                    target = (month, group)
                    if (
                        any(char in name for char in chars)
                        and name not in first_descriptions[target]
                        and len(candidates[target]) < 80
                    ):
                        candidates[target].append((code, name))
                        first_descriptions[target].add(name)

    expected_nonascii = manifest["description_encoding"]["non_ascii_description_rows"]
    if (
        rows != manifest["rows"]
        or len(unique_keys) != manifest["distinct_code_month_keys"]
        or len(per_month) != 36
        or nonascii != expected_nonascii
        or any(per_month[month] <= 0 for month in per_month)
    ):
        raise RuntimeError("Contagens do CSV e manifesto não reconciliadas")

    print("MODE=READ_ONLY_SIGTAP_ENCODING_REVIEW")
    print(f"ROWS={rows}")
    print(f"COMPETENCES={len(per_month)}")
    print(f"DISTINCT_CODE_MONTH_KEYS={len(unique_keys)}")
    print(f"NON_ASCII_DESCRIPTION_ROWS={nonascii}")
    print("CSV_SHA_MATCH=True")
    print("SUSPECT_MOJIBAKE_MARKERS=" + str(sum(markers.values())))
    if markers:
        print("MARKER_COUNTS=" + json.dumps(markers, ensure_ascii=False))
        for month, code, name in marker_examples:
            print(f"MARKER_EXAMPLE {month}|{code} {name}")

    selected_names: set[str] = set()
    for month in SAMPLE_MONTHS:
        print(f"=== {month} ===")
        for group in DIACRITICS:
            group_rows = candidates[(month, group)]
            options = [
                item for item in group_rows if item[1] not in selected_names
            ] or group_rows
            if options:
                code, name = options[0]
                selected_names.add(name)
                print(f"{group}: {code} | {name}")
            else:
                print(f"{group}: SEM_EXEMPLO_NA_AMOSTRA")
    print("ENCODING_FINAL_APPROVAL=AWAITING_HUMAN_VISUAL_REVIEW")
    print("QLIK_QVD=NOT_GENERATED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
