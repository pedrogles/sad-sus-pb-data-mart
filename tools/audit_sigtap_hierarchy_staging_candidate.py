#!/usr/bin/env python3
"""IV-PROCEDIMENTO: auditoria read-only do CSV SIGTAP hierarquico candidato.

Reconcilia o CSV UTF-8 e manifesto com o original C3.4a + as 216 fontes
hierarquicas preservadas. Compara cada linha contra o nome e os codigos
hierarquicos da MESMA competencia, sem depender do materializador do CSV.
Nao faz downloads, nao escreve arquivos, QVDs ou checkpoints globais.
"""
from __future__ import annotations

import csv
import hashlib
import json
import re
from collections import Counter
from itertools import zip_longest
from pathlib import Path

from audit_sigtap_hierarchy_history import main as audit_original_sha
from audit_sigtap_hierarchy_descriptions import layout_fields
from materialize_sigtap_procedure_history import COMPETENCES
from validate_sigtap_hierarchy_relational_pilot import (
    DESCRIPTION_FIELDS, KEY_FIELDS,
)
from inspect_sigtap_hierarchy_sample import LEVEL_FILES

ROOT = Path("BASE/REFERENCIAS")
ORIGINAL = ROOT / "sigtap_procedimento_staging_candidate.csv"
ORIGINAL_MANIFEST = ROOT / "sigtap_procedimento_staging_candidate_manifest.json"
HIERARCHY_MANIFEST = ROOT / "sigtap_hierarchy_history_manifest.json"
CANDIDATE = ROOT / "sigtap_procedimento_hierarquia_staging_candidate.csv"
CANDIDATE_MANIFEST = ROOT / "sigtap_procedimento_hierarquia_staging_candidate_manifest.json"
DATA_ROOT = ROOT / "SIGTAP/PROCEDIMENTO"
EXPECTED_FIELDS = [
    "SIGTAP_COMPETENCIA",
    "SIGTAP_CO_PROCEDIMENTO",
    "SIGTAP_NO_PROCEDIMENTO",
    "SIGTAP_COMPETENCIA_CODIGO",
    "SIGTAP_CO_GRUPO",
    "SIGTAP_NO_GRUPO",
    "SIGTAP_CO_SUB_GRUPO",
    "SIGTAP_NO_SUB_GRUPO",
    "SIGTAP_CO_FORMA_ORGANIZACAO",
    "SIGTAP_NO_FORMA_ORGANIZACAO",
]
EXPECTED_HIERARCHY_SHA = (
    "362301077a9823eca5e05362825b31471e0604bc4a9e3d308107252308f09ff5"
)
CODE_REGEX = re.compile(r"[0-9]{10}\Z")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def load_hierarchy(month: str, level: str) -> dict[str, str]:
    cols, width = layout_fields(month, level)
    columns = {x["field"]: x for x in cols}
    found = {}
    path = DATA_ROOT / month / (level + ".txt")
    for line_no, raw in enumerate(path.read_bytes().splitlines(), 1):
        if len(raw) != width:
            raise RuntimeError(f"Largura inesperada: {month}/{level}/{line_no}")
        codes = []
        for field in KEY_FIELDS[level]:
            spec = columns[field]
            cell = raw[spec["start"]:spec["end"]]
            if not cell or not all(48 <= byte <= 57 for byte in cell):
                raise RuntimeError(f"Chave invalida: {month}/{level}/{line_no}")
            codes.append(cell.decode("ascii"))
        code = "".join(codes)
        if code in found:
            raise RuntimeError(f"Duplicidade: {month}/{level}/{code}")
        dt = columns["DT_COMPETENCIA"]
        if raw[dt["start"]:dt["end"]] != month.encode("ascii"):
            raise RuntimeError(f"Competencia fora de origem: {month}/{level}/{code}")
        label_field = columns[DESCRIPTION_FIELDS[level]]
        desc = raw[label_field["start"]:label_field["end"]].decode(
            "cp1252", errors="strict"
        ).rstrip(" ")
        if not desc:
            raise RuntimeError(f"Descricao vazia: {month}/{level}/{code}")
        found[code] = desc
    return found


def main() -> int:
    if audit_original_sha() != 0:
        raise RuntimeError("Os 216 originais nao passaram auditoria de SHA")

    if not all(p.is_file() for p in (
        ORIGINAL, ORIGINAL_MANIFEST, HIERARCHY_MANIFEST,
        CANDIDATE, CANDIDATE_MANIFEST
    )):
        raise RuntimeError("CSV/manifesto candidato ou fontes ausentes")

    old = json.loads(ORIGINAL_MANIFEST.read_text(encoding="utf-8"))
    hier = json.loads(HIERARCHY_MANIFEST.read_text(encoding="utf-8"))
    new = json.loads(CANDIDATE_MANIFEST.read_text(encoding="utf-8"))

    if (
        old.get("stage") != "PHASE_III_C3_4A_SIGTAP_CSV_STAGE_PREPARATION"
        or old.get("rows") != 165203
        or old.get("distinct_code_month_keys") != 165203
        or Path(old.get("outputs", {}).get("csv", "")) != ORIGINAL
        or old.get("outputs", {}).get("sha256") != sha256(ORIGINAL)
        or sha256(HIERARCHY_MANIFEST) != EXPECTED_HIERARCHY_SHA
        or hier.get("status") != "PASS"
    ):
        raise RuntimeError("Fontes de origem nao reconciliadas")
    if (
        new.get("stage") != "IV_PROCEDIMENTO_SIGTAP_HIERARCHY_STAGING_CANDIDATE"
        or new.get("status") != "PASS_CANDIDATE_ONLY"
        or new.get("competences") != 36
        or new.get("rows") != 165203
        or new.get("distinct_keys") != 165203
        or new.get("fields") != EXPECTED_FIELDS
        or new.get("lookup") != "SIGTAP_COMPETENCIA_CODIGO"
        or Path(new.get("csv_path", "")) != CANDIDATE
        or new.get("csv_sha256") != sha256(CANDIDATE)
        or int(new.get("csv_size_bytes", -1)) != CANDIDATE.stat().st_size
        or new.get("base_csv_sha256") != sha256(ORIGINAL)
        or new.get("hierarchy_manifest_sha256") != EXPECTED_HIERARCHY_SHA
        or new.get("description_policy") !=
            "SOURCE_LABEL_BY_SAME_COMPETENCE_NO_NORMALIZATION"
        or new.get("encoding") !=
            "CP1252_OPERATIONAL_CANDIDATE_EQUIVALENT_ISO8859_1_ON_CORPUS"
        or new.get("201808_source_version_caveat") !=
            "TabelaUnificada_201808_v2102261143.zip"
        or new.get("t29_historical") != "NOT_APPROVED"
        or new.get("qvd_generated") is not False
        or new.get("fact_tables_generated") is not False
    ):
        raise RuntimeError("Manifesto do CSV novo divergente")

    # Rele todas as descricoes originais por competencia, independentemente
    # dos dicionarios usados pelo script que materializou o candidato.
    lookups = {}
    profiles = {r["competence"]: r for r in hier["records_by_month"]}
    if set(profiles) != set(COMPETENCES):
        raise RuntimeError("Perfis hierarquicos com competencias incompletas")
    for month in COMPETENCES:
        lookups[month] = {
            level: load_hierarchy(month, level) for level in LEVEL_FILES
        }
        for level, count in (
            ("tb_grupo", "groups"),
            ("tb_sub_grupo", "subgroups"),
            ("tb_forma_organizacao", "forms"),
        ):
            if len(lookups[month][level]) != profiles[month][count]:
                raise RuntimeError(f"Hierarquia incompleta: {month}/{level}")

    months = Counter()
    seen_keys = set()
    expected_counts = {x["competence"]: int(x["rows"])
                       for x in old.get("monthly", [])}
    if set(expected_counts) != set(COMPETENCES):
        raise RuntimeError("Manifesto antigo: competencias incompletas")

    with ORIGINAL.open("r", encoding="utf-8-sig", newline="") as f_old, (
        CANDIDATE.open("r", encoding="utf-8-sig", newline="")
    ) as f_new:
        source = csv.DictReader(f_old, delimiter=";")
        target = csv.DictReader(f_new, delimiter=";")
        if source.fieldnames != EXPECTED_FIELDS[:4]:
            raise RuntimeError("Schema do staging SIGTAP anterior alterado")
        if target.fieldnames != EXPECTED_FIELDS:
            raise RuntimeError("Schema de 10 campos alterado")

        for lineno, (a, b) in enumerate(zip_longest(source, target), 2):
            if a is None or b is None:
                raise RuntimeError("Linhas de origem/candidato diferentes")
            if None in a or None in b or any(
                v is None for v in a.values()
            ) or any(v is None for v in b.values()):
                raise RuntimeError(f"CSV malformado: linha {lineno}")
            if any(a[field] != b[field] for field in EXPECTED_FIELDS[:4]):
                raise RuntimeError(f"Origem alterada pelo enriquecimento: {lineno}")

            month = a["SIGTAP_COMPETENCIA"]
            code = a["SIGTAP_CO_PROCEDIMENTO"]
            key = a["SIGTAP_COMPETENCIA_CODIGO"]
            if (
                month not in lookups
                or CODE_REGEX.fullmatch(code) is None
                or key != f"{month}|{code}"
                or key in seen_keys
            ):
                raise RuntimeError(f"Chave invalida/duplicada: linha {lineno}")
            seen_keys.add(key)
            months[month] += 1
            pairs = [
                ("tb_grupo", code[:2], "SIGTAP_NO_GRUPO"),
                ("tb_sub_grupo", code[:4], "SIGTAP_NO_SUB_GRUPO"),
                ("tb_forma_organizacao", code[:6], "SIGTAP_NO_FORMA_ORGANIZACAO"),
            ]
            if (
                b["SIGTAP_CO_GRUPO"] != code[:2]
                or b["SIGTAP_CO_SUB_GRUPO"] != code[2:4]
                or b["SIGTAP_CO_FORMA_ORGANIZACAO"] != code[4:6]
            ):
                raise RuntimeError(f"Codigo hierarquico incorreto: linha {lineno}")
            for level, full_key, output_field in pairs:
                expected_label = lookups[month][level].get(full_key)
                if not expected_label or b[output_field] != expected_label:
                    raise RuntimeError(
                        f"Texto sem correspondencia historica: "
                        f"{month}/{code}/{level}"
                    )

    if (
        len(seen_keys) != 165203
        or len(months) != 36
        or sum(months.values()) != 165203
        or dict(months) != expected_counts
    ):
        raise RuntimeError(f"Grão, cobertura ou contagem divergente: {months}")

    print("CSV_SHA256=" + sha256(CANDIDATE))
    print("CSV_BYTES=" + str(CANDIDATE.stat().st_size))
    print("SOURCE_C3_4A_SHA256=" + sha256(ORIGINAL))
    print("HIERARCHY_MANIFEST_SHA256=" + sha256(HIERARCHY_MANIFEST))
    print("COMPETENCES_VERIFIED=36")
    print("CSV_FIELDS_VERIFIED=10")
    print("CSV_ROWS_VERIFIED=165203")
    print("CSV_DISTINCT_KEYS=165203")
    print("SOURCE_FIELDS_PRESERVED=True")
    print("HIERARCHY_NAMES_MATCH_SAME_MONTH=165203")
    print("UNMATCHED_ALL_LEVELS=0")
    print("DESCRIPTION_ENCODING=OPERATIONAL_ONLY")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("QVD_GENERATED=False")
    print("VERDICT=PASS_LOCAL_SIGTAP_HIERARCHY_STAGING_CSV_SHA_AND_ROW_RECONCILED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
