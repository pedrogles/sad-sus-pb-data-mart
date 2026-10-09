#!/usr/bin/env python3
"""IV-PROCEDIMENTO — candidato de staging enriquecido, por competência SIGTAP.

Usa somente arquivos locais aprovados C3.4a e 216 hierárquicos com SHA PASS.
Em --validate-only não grava nada; --materialize cria um NOVO CSV UTF-8 +
manifesto sob BASE/REFERENCIAS (ignorado pelo Git). Não altera o QVD vigente.
A leitura cp1252 das hierarquias é operacional e indistinguível de ISO-8859-1
nos bytes observados; não se infere vigência normativa, sobretudo 201808.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import tempfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from audit_sigtap_hierarchy_history import main as audit_hierarchy_sha
from audit_sigtap_hierarchy_descriptions import layout_fields
from materialize_sigtap_procedure_history import COMPETENCES
from validate_sigtap_hierarchy_relational_pilot import KEY_FIELDS, DESCRIPTION_FIELDS
from inspect_sigtap_hierarchy_sample import LEVEL_FILES

ROOT = Path("BASE/REFERENCIAS")
SOURCE = ROOT / "sigtap_procedimento_staging_candidate.csv"
SOURCE_MANIFEST = ROOT / "sigtap_procedimento_staging_candidate_manifest.json"
HIERARCHY_MANIFEST = ROOT / "sigtap_hierarchy_history_manifest.json"
OUT_CSV = ROOT / "sigtap_procedimento_hierarquia_staging_candidate.csv"
OUT_MANIFEST = ROOT / "sigtap_procedimento_hierarquia_staging_candidate_manifest.json"
FILES = [
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
INPUT_FIELDS = FILES[:4]
CODE_PATTERN = re.compile(r"[0-9]{10}\Z")
HIER_FILES = ROOT / "SIGTAP/PROCEDIMENTO"


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def require_inputs() -> tuple[dict, dict]:
    if audit_hierarchy_sha() != 0:
        raise RuntimeError("Gate dos 216 originais nao passou")
    if not SOURCE.is_file() or not SOURCE_MANIFEST.is_file():
        raise RuntimeError("C3.4a SIGTAP CSV/manifesto ausente")
    prior = json.loads(SOURCE_MANIFEST.read_text(encoding="utf-8"))
    if (
        prior.get("stage") != "PHASE_III_C3_4A_SIGTAP_CSV_STAGE_PREPARATION"
        or prior.get("status") != "STRUCTURE_PASS_ENCODING_REVIEW"
        or prior.get("rows") != 165203
        or prior.get("competences") != 36
        or prior.get("distinct_code_month_keys") != 165203
        or prior.get("scope", {}).get("t27_pass_verified_as_prerequisite") is not True
        or Path(prior.get("outputs", {}).get("csv", "")) != SOURCE
        or prior.get("outputs", {}).get("sha256") != digest(SOURCE)
    ):
        raise RuntimeError("C3.4a SIGTAP nao reconciliado")
    hierarchy = json.loads(HIERARCHY_MANIFEST.read_text(encoding="utf-8"))
    by_month = {r["competence"]: r for r in hierarchy["records_by_month"]}
    if set(by_month) != set(COMPETENCES):
        raise RuntimeError("Manifesto hierarquico incompleto")
    return prior, hierarchy


def read_level(month: str, level: str) -> dict[str, str]:
    columns, width = layout_fields(month, level)
    cols = {c["field"]: c for c in columns}
    expected = (*KEY_FIELDS[level], DESCRIPTION_FIELDS[level], "DT_COMPETENCIA")
    if tuple(c["field"] for c in columns) != expected:
        raise RuntimeError(f"Campos hierarquicos divergentes: {month}/{level}")
    source = HIER_FILES / month / (level + ".txt")
    rows: dict[str, str] = {}
    for index, raw in enumerate(source.read_bytes().splitlines(), start=1):
        if len(raw) != width:
            raise RuntimeError(f"Largura fisica: {month}/{level}/{index}")
        parts = []
        for field in KEY_FIELDS[level]:
            col = cols[field]
            part = raw[col["start"]:col["end"]]
            if not part or any(b < 48 or b > 57 for b in part):
                raise RuntimeError(f"Codigo invalido: {month}/{level}/{index}")
            parts.append(part.decode("ascii"))
        key = "".join(parts)
        if key in rows:
            raise RuntimeError(f"Chave duplicada: {month}/{level}/{key}")
        cmpt = cols["DT_COMPETENCIA"]
        if raw[cmpt["start"]:cmpt["end"]] != month.encode("ascii"):
            raise RuntimeError(f"Competencia divergente: {month}/{level}/{key}")
        c = cols[DESCRIPTION_FIELDS[level]]
        label = raw[c["start"]:c["end"]].decode("cp1252", errors="strict").rstrip(" ")
        if not label:
            raise RuntimeError(f"Descricao vazia: {month}/{level}/{key}")
        rows[key] = label
    return rows


def load_hierarchies(manifest: dict) -> dict[str, dict[str, dict[str, str]]]:
    profiles = {r["competence"]: r for r in manifest["records_by_month"]}
    out = {}
    for month in COMPETENCES:
        tables = {level: read_level(month, level) for level in LEVEL_FILES}
        for level, count_field in (
            ("tb_grupo", "groups"), ("tb_sub_grupo", "subgroups"),
            ("tb_forma_organizacao", "forms")
        ):
            if len(tables[level]) != profiles[month][count_field]:
                raise RuntimeError(f"Contagem de hierarquia divergente: {month}/{level}")
        out[month] = tables
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--validate-only", action="store_true")
    mode.add_argument("--materialize", action="store_true")
    args = parser.parse_args()

    prior, hier = require_inputs()
    labels = load_hierarchies(hier)
    by_month = Counter()
    keys = set()
    empty_names = 0
    unmatched = Counter()
    tmp_path = None
    raw_handle = None
    writer = None

    try:
        if args.materialize:
            if OUT_CSV.exists() or OUT_MANIFEST.exists():
                raise RuntimeError(
                    "CSV/manifesto candidato ja existem: nao sobrescrever; auditar primeiro"
                )
            fd, tmp_name = tempfile.mkstemp(
                prefix="_sigtap_hierarchy_stage_", suffix=".tmp", dir=ROOT
            )
            os.close(fd)
            tmp_path = Path(tmp_name)
            raw_handle = tmp_path.open("w", encoding="utf-8", newline="")
            writer = csv.DictWriter(
                raw_handle, fieldnames=FILES, delimiter=";",
                lineterminator="\n", extrasaction="raise"
            )
            writer.writeheader()

        with SOURCE.open("r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f, delimiter=";")
            if reader.fieldnames != INPUT_FIELDS:
                raise RuntimeError(f"Schema origem C3.4a divergente: {reader.fieldnames}")
            for record in reader:
                month = record["SIGTAP_COMPETENCIA"]
                code = record["SIGTAP_CO_PROCEDIMENTO"]
                key = record["SIGTAP_COMPETENCIA_CODIGO"]
                if (
                    month not in labels
                    or not CODE_PATTERN.fullmatch(code)
                    or key != f"{month}|{code}"
                    or not record["SIGTAP_NO_PROCEDIMENTO"]
                ):
                    raise RuntimeError(f"Registro SIGTAP invalido na linha {reader.line_num}")
                if key in keys:
                    raise RuntimeError(f"Chave repetida: {key}")
                keys.add(key)
                by_month[month] += 1
                group = labels[month]["tb_grupo"].get(code[:2])
                subgroup = labels[month]["tb_sub_grupo"].get(code[:4])
                form = labels[month]["tb_forma_organizacao"].get(code[:6])
                if group is None:
                    unmatched["group"] += 1
                if subgroup is None:
                    unmatched["subgroup"] += 1
                if form is None:
                    unmatched["form"] += 1
                if group is None or subgroup is None or form is None:
                    continue
                if not all((group.strip(), subgroup.strip(), form.strip())):
                    empty_names += 1
                if writer:
                    writer.writerow({
                        **record,
                        "SIGTAP_CO_GRUPO": code[:2],
                        "SIGTAP_NO_GRUPO": group,
                        "SIGTAP_CO_SUB_GRUPO": code[2:4],
                        "SIGTAP_NO_SUB_GRUPO": subgroup,
                        "SIGTAP_CO_FORMA_ORGANIZACAO": code[4:6],
                        "SIGTAP_NO_FORMA_ORGANIZACAO": form,
                    })
        if (
            len(keys) != 165203 or len(by_month) != 36
            or sum(by_month.values()) != 165203
            or unmatched or empty_names
        ):
            raise RuntimeError(
                f"Reconciliação falhou: keys={len(keys)} months={len(by_month)} "
                f"unmatched={dict(unmatched)} empty={empty_names}"
            )
        source_months = {x["competence"]: x["rows"] for x in prior["monthly"]}
        hierarchy_months = {x["competence"]: x["procedure_rows"] for x in hier["records_by_month"]}
        if set(source_months) != set(COMPETENCES) or set(hierarchy_months) != set(COMPETENCES):
            raise RuntimeError("Meses em manifesto diferem")
        for month in COMPETENCES:
            if by_month[month] != source_months[month] or by_month[month] != hierarchy_months[month]:
                raise RuntimeError(f"Total mensal divergente: {month}")

        if raw_handle:
            raw_handle.flush()
            raw_handle.close()
            raw_handle = None

        print("MODE=SIGTAP_HIERARCHY_STAGING_CANDIDATE")
        print("COMPETENCES=36")
        print("REFERENCE_ROWS=165203")
        print("DISTINCT_CODE_MONTH_KEYS=165203")
        print("FIELDS=" + str(len(FILES)))
        print("UNMATCHED_GROUP=0 UNMATCHED_SUBGROUP=0 UNMATCHED_FORM=0")
        print("SOURCE_C3_4A_SHA256=" + digest(SOURCE))
        print("HIERARCHY_MANIFEST_SHA256=" + digest(HIERARCHY_MANIFEST))
        print("DESCRIPTION_DECODE=CP1252_OPERATIONAL_CANDIDATE_EQUIVALENT_ISO_8859_1")
        print("T29_HISTORICAL=NOT_APPROVED")
        print("QLIK_QVD=NOT_GENERATED")

        if args.validate_only:
            print("OUTPUT_FILES_WRITTEN=0")
            print("VERDICT=PASS_36_MONTH_HIERARCHY_STAGING_CANDIDATE_VALIDATE_ONLY")
            return 0

        assert tmp_path is not None
        csv_sha = digest(tmp_path)
        csv_size = tmp_path.stat().st_size
        material_manifest = {
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "stage": "IV_PROCEDIMENTO_SIGTAP_HIERARCHY_STAGING_CANDIDATE",
            "status": "PASS_CANDIDATE_ONLY",
            "competences": 36,
            "rows": 165203,
            "distinct_keys": 165203,
            "fields": FILES,
            "lookup": "SIGTAP_COMPETENCIA_CODIGO",
            "base_csv_sha256": digest(SOURCE),
            "hierarchy_manifest_sha256": digest(HIERARCHY_MANIFEST),
            "csv_sha256": csv_sha,
            "csv_size_bytes": csv_size,
            "csv_path": str(OUT_CSV),
            "description_policy": "SOURCE_LABEL_BY_SAME_COMPETENCE_NO_NORMALIZATION",
            "encoding": "CP1252_OPERATIONAL_CANDIDATE_EQUIVALENT_ISO8859_1_ON_CORPUS",
            "201808_source_version_caveat": "TabelaUnificada_201808_v2102261143.zip",
            "t29_historical": "NOT_APPROVED",
            "qvd_generated": False,
            "fact_tables_generated": False,
        }
        # No overwrite; novos artefatos somente apos validação integral.
        with OUT_CSV.open("xb") as target, tmp_path.open("rb") as source:
            for chunk in iter(lambda: source.read(1 << 20), b""):
                target.write(chunk)
        OUT_MANIFEST.write_text(
            json.dumps(material_manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print("NEW_CSV_SHA256=" + csv_sha)
        print("NEW_CSV_BYTES=" + str(csv_size))
        print("OUTPUT_FILES_WRITTEN=2")
        print("VERDICT=PASS_36_MONTH_HIERARCHY_STAGING_CANDIDATE_MATERIALIZED")
        return 0
    finally:
        if raw_handle:
            raw_handle.close()
        if tmp_path and tmp_path.exists():
            tmp_path.unlink()


if __name__ == "__main__":
    raise SystemExit(main())
