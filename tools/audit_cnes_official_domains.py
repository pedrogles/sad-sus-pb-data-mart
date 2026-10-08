#!/usr/bin/env python3
"""III-C4.2c: auditoria read-only do arquivo oficial SCNES_DOMINIOS.XLS.

O arquivo entregue tem extensao .XLS, mas estrutura OOXML/ZIP (Excel 2007+).
Utiliza apenas a biblioteca padrao Python; nao converte/reescreve a planilha.

Compara os codigos e tipos de duas abas separadas com o perfil CNES/LT
observado em PB, sem supor que essas abas definem relacao tipo -> leito
ou que a planilha de 2019 possua vigencia comprovada em 2017-2019.

T29 nao pode ser declarado PASS por este script.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import posixpath
import re
import xml.etree.ElementTree as ET
import zipfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
DEFAULT_DIR = Path("BASE/REFERENCIAS")


def hash_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def xml_text(element: ET.Element | None) -> str:
    if element is None:
        return ""
    return "".join(element.itertext())


def sheet_rows(z: zipfile.ZipFile, shared: list[str], sheet_path: str) -> list[dict[str, str]]:
    root = ET.fromstring(z.read(sheet_path))
    result: list[dict[str, str]] = []
    for row in root.findall(".//m:sheetData/m:row", NS):
        cells: dict[str, str] = {}
        for c in row.findall("m:c", NS):
            addr = c.get("r", "")
            col = re.match(r"^[A-Z]+", addr)
            if not col:
                continue
            cell_type = c.get("t")
            value = c.find("m:v", NS)
            if value is not None:
                raw = value.text or ""
                if cell_type == "s":
                    raw = shared[int(raw)]
            else:
                raw = xml_text(c.find("m:is", NS))
            cells[col.group()] = raw
        if any(value != "" for value in cells.values()):
            result.append(cells)
    return result


def load_domains(path: Path) -> tuple[dict[str, str], dict[str, str], dict]:
    if not zipfile.is_zipfile(path):
        raise ValueError("O arquivo nao e OOXML/ZIP: verificar versao e formato XLS.")
    with zipfile.ZipFile(path) as z:
        shared_root = ET.fromstring(z.read("xl/sharedStrings.xml"))
        shared = [xml_text(si) for si in shared_root.findall("m:si", NS)]
        workbook = ET.fromstring(z.read("xl/workbook.xml"))
        rels = ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
        targets = {item.get("Id"): item.get("Target") for item in rels}
        names: dict[str, str] = {}
        for sheet in workbook.findall(".//m:sheet", NS):
            target = targets[sheet.get(f"{{{REL_NS}}}id")]
            if target.startswith("/"):
                target_path = target.lstrip("/")
            else:
                target_path = posixpath.normpath(posixpath.join("xl", target))
            names[sheet.get("name", "")] = target_path

        necessary = {"LEITOS", "TIPOS DE LEITOS"}
        if not necessary.issubset(names):
            raise ValueError(f"Abas ausentes: {sorted(necessary - set(names))}")

        def values(name: str, expected_header: str) -> dict[str, str]:
            rows = sheet_rows(z, shared, names[name])
            if not rows or rows[0].get("A") != expected_header or rows[0].get("B") != "DESCRIÇÃO":
                raise ValueError(f"Cabecalho inesperado na aba {name}: {rows[:1]}")
            mapping: dict[str, str] = {}
            for row in rows[1:]:
                code, label = row.get("A", ""), row.get("B", "")
                if not code or not label:
                    raise ValueError(f"Codigo ou descricao vazio em {name}: {row}")
                if code in mapping:
                    raise ValueError(f"Codigo duplicado em {name}: {code!r}")
                mapping[code] = label
            return mapping

        leitos = values("LEITOS", "LEITO")
        tipos = values("TIPOS DE LEITOS", "TIPO DE LEITO")

        core = z.read("docProps/core.xml").decode("utf-8", errors="replace")
        created_match = re.search(r"<dcterms:created[^>]*>([^<]+)", core)
        modified_match = re.search(r"<dcterms:modified[^>]*>([^<]+)", core)
        metadata = {
            "sheet_count": len(names),
            "created_metadata_utc": created_match.group(1) if created_match else None,
            "modified_metadata_utc": modified_match.group(1) if modified_match else None,
            "format": "OOXML_ZIP_COM_EXTENSAO_XLS",
        }
    return leitos, tipos, metadata


def load_profile(path: Path) -> tuple[list[dict[str, str]], str]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        required = {"tp_leito_raw", "codleito_raw", "occurrences"}
        if not required.issubset(reader.fieldnames or []):
            raise ValueError(f"Colunas ausentes no perfil CNES/LT: {sorted(required-set(reader.fieldnames or []))}")
        data = list(reader)
    if len({(x["tp_leito_raw"], x["codleito_raw"]) for x in data}) != len(data):
        raise ValueError("Pares duplicados no perfil CNES/LT")
    return data, hash_file(path)


def main() -> int:
    cli = argparse.ArgumentParser()
    cli.add_argument("--dominios", type=Path, default=DEFAULT_DIR / "SCNES_DOMINIOS.XLS")
    cli.add_argument("--perfil", type=Path, default=DEFAULT_DIR / "cnes_lt_bed_code_pair_profile.csv")
    cli.add_argument("--saida", type=Path, default=DEFAULT_DIR / "cnes_domain_code_coverage_audit.json")
    args = cli.parse_args()
    for input_path in (args.dominios, args.perfil):
        if not input_path.is_file():
            cli.error(f"Arquivo local ausente: {input_path}")

    leitos, tipos, metadata = load_domains(args.dominios)
    rows, profile_hash = load_profile(args.perfil)
    code_shapes_ok = all(re.fullmatch(r"[0-9]{2}", c) for c in leitos)
    type_shapes_ok = all(re.fullmatch(r"[0-9]", c) for c in tipos)
    all_types_raw_ok = all(
        re.fullmatch(r"[0-9] ", row["tp_leito_raw"]) for row in rows
    )
    exceptions = []
    match_count = 0
    match_rows = 0
    total_rows = 0
    observed_codes = set()
    observed_types = set()
    code_types = {}
    for row in rows:
        code = row["codleito_raw"]
        kind_raw = row["tp_leito_raw"]
        kind = kind_raw.rstrip(" ")  # somente comparacao; valor original mantido
        occurrences = int(row["occurrences"])
        if occurrences <= 0:
            raise ValueError(f"Contagem nao positiva no perfil: {row}")
        total_rows += occurrences
        observed_codes.add(code)
        observed_types.add(kind)
        code_types.setdefault(code, set()).add(kind_raw)
        missing = []
        if code not in leitos:
            missing.append("CODLEITO_AUSENTE")
        if kind not in tipos:
            missing.append("TP_LEITO_AUSENTE")
        if missing:
            exceptions.append({
                "tp_leito_raw": kind_raw,
                "codleito_raw": code,
                "ocorrencias": occurrences,
                "motivos": missing,
            })
        else:
            match_count += 1
            match_rows += occurrences

    source_structure_ok = (
        len(leitos) == 66 and len(tipos) == 7
        and code_shapes_ok and type_shapes_ok
    )
    profile_structure_ok = (
        len(rows) == 57 and total_rows == 35518
        and all_types_raw_ok
    )
    status = (
        "CODE_AND_TYPE_COVERAGE_PROVISIONAL"
        if source_structure_ok and profile_structure_ok and not exceptions
        else "REVIEW_REQUIRED"
    )
    result = {
        "stage": "III_C4_2C_CN_ES_DOMAIN_CODE_COVERAGE",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": status,
        "domain_source": {
            "path": str(args.dominios),
            "sha256": hash_file(args.dominios),
            **metadata,
            "leitos_codes": len(leitos),
            "tipos_codes": len(tipos),
            "all_leitos_two_ascii_digits": code_shapes_ok,
            "all_tipos_single_ascii_digit": type_shapes_ok,
            "code_70_label": leitos.get("70"),
            "type_7_label": tipos.get("7"),
        },
        "observed_profile": {
            "path": str(args.perfil),
            "sha256": profile_hash,
            "pairs": len(rows),
            "occurrences_total": total_rows,
            "distinct_codleito": len(observed_codes),
            "distinct_tp_leito": len(observed_types),
            "all_tp_leito_one_digit_plus_trailing_ascii_space": all_types_raw_ok,
            "codes_associated_to_multiple_raw_types": sum(
                len(v) > 1 for v in code_types.values()
            ),
        },
        "coverage_observed_against_uploaded_current_domains": {
            "matched_pairs_code_and_type_independently": match_count,
            "matched_source_rows": match_rows,
            "unmatched_pairs": len(exceptions),
            "unmatched_source_rows": total_rows - match_rows,
            "exceptions": exceptions,
            "codes_present_in_catalog_not_observed": sorted(set(leitos) - observed_codes),
        },
        "limits": {
            "domain_sheet_contains_code_to_type_relationship": False,
            "association_of_tp_leito_with_codleito_officially_verified": False,
            "effective_normative_validity_2017_2019_verified": False,
            "full_T29_approved": False,
            "new_qvd_created": False,
            "source_files_modified": False,
        },
    }
    args.saida.parent.mkdir(parents=True, exist_ok=True)
    args.saida.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("DOMAIN_LEITOS_CODES=", len(leitos))
    print("DOMAIN_TIPO_LEITO_CODES=", len(tipos))
    print("DOMAIN_CODE_70=", leitos.get("70"))
    print("DOMAIN_TIPO_7=", tipos.get("7"))
    print("OBSERVED_PAIRS=", len(rows))
    print("OBSERVED_LT_ROWS=", total_rows)
    print("MATCHED_PAIRS_IN_INDEPENDENT_LISTS=", match_count)
    print("MATCHED_LT_ROWS_IN_INDEPENDENT_LISTS=", match_rows)
    print("UNMATCHED_PAIRS=", len(exceptions))
    print("UNMATCHED_LT_ROWS=", total_rows - match_rows)
    print("AUDIT_SUMMARY=", args.saida)
    print("HISTORICAL_TYPE_CODE_RELATION=NOT_VERIFIED")
    print("T29_COVERAGE=NOT_APPROVED")
    print("VERDICT=", status)
    return 0 if status == "CODE_AND_TYPE_COVERAGE_PROVISIONAL" else 2


if __name__ == "__main__":
    raise SystemExit(main())
