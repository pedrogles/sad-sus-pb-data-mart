#!/usr/bin/env python3
"""IV-PROCEDIMENTO: piloto READ-ONLY de chaves SIGTAP por competência.

Reutiliza amostra oficial C3.2 (4 ZIPs temporários e checks SHA/CRC) e
tb_procedimento.txt já validado no C3.3b.1 (sem baixar procedimentos).
A regra de prefixos 2/4/6 e uma HIPOTESE A TESTAR; PASS piloto não aprova
associação formal em 36 competências nem encoding dos nomes.
"""
from __future__ import annotations

import hashlib
import json
import tempfile
import zipfile
from collections import Counter
from pathlib import Path

import ftplib

from inspect_sigtap_hierarchy_sample import (
    LEVEL_FILES, SAMPLE_COMPETENCES, FTP_HOST, FTP_DIRECTORY,
    INVENTORY, C3_2_SUMMARY, inspect_inventory, read_inventory,
    load_previous_sample, find_exact_member, receive_zip, sha256_file,
    read_layout,
)
from materialize_sigtap_procedure_sample import parse_layout as procedure_layout

HISTORY = Path("BASE/REFERENCIAS/sigtap_procedure_history_manifest.json")
PROCEDURES = Path("BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO")
LAYOUT_HASHES = {
    "tb_grupo": "3bf6a61194eedbb404b091ba966e6f6c97fe0c88b78c59b9a867177289e16c07",
    "tb_sub_grupo": "3eb16c6563481e9823a8dd1fda30ab1fc0f185d2d91ecfa6a2274eeac5179965",
    "tb_forma_organizacao": "87e03373d59641ed3814bf81cb315532aa6edb50a30ee2412f2906cbded63ae5",
}
KEY_FIELDS = {
    "tb_grupo": ("CO_GRUPO",),
    "tb_sub_grupo": ("CO_GRUPO", "CO_SUB_GRUPO"),
    "tb_forma_organizacao": (
        "CO_GRUPO", "CO_SUB_GRUPO", "CO_FORMA_ORGANIZACAO",
    ),
}
DESCRIPTION_FIELDS = {
    "tb_grupo": "NO_GRUPO",
    "tb_sub_grupo": "NO_SUB_GRUPO",
    "tb_forma_organizacao": "NO_FORMA_ORGANIZACAO",
}


def load_procedure_manifest() -> dict[str, dict]:
    data = json.loads(HISTORY.read_text(encoding="utf-8"))
    if data.get("status") != "PASS":
        raise RuntimeError("Manifesto historico de procedimento nao esta PASS")
    rows = [r for r in data.get("materialized", [])
            if r.get("competence") in SAMPLE_COMPETENCES]
    if len(rows) != 4 or len({r["competence"] for r in rows}) != 4:
        raise RuntimeError("Manifesto SIGTAP sem amostra unica de 4 meses")
    return {r["competence"]: r for r in rows}


def parse_table(
    raw: bytes, fields: list[dict], month: str, level: str
) -> dict[str, str]:
    keys = KEY_FIELDS[level]
    expected_columns = (*keys, DESCRIPTION_FIELDS[level], "DT_COMPETENCIA")
    actual_columns = tuple(str(c["field"]) for c in fields)
    if actual_columns != expected_columns:
        raise RuntimeError(f"Schema divergente: {month}/{level}: {actual_columns}")
    width = int(fields[-1]["end"])
    rows: dict[str, str] = {}
    for index, line in enumerate(raw.splitlines(), 1):
        if len(line) != width:
            raise RuntimeError(f"Largura invalida: {month}/{level}/linha{index}")
        parsed = {}
        for col in fields:
            item = str(col["field"])
            chunk = line[int(col["start"])-1:int(col["end"])]
            if item in keys or item == "DT_COMPETENCIA":
                if not chunk or not all(48 <= b <= 57 for b in chunk):
                    raise RuntimeError(f"Codigo nao ASCII: {month}/{level}/{item}")
                parsed[item] = chunk.decode("ascii")
            else:
                # cp1252 apenas hipotese de apresentacao; nenhuma gravacao.
                parsed[item] = chunk.decode("cp1252").rstrip(" ")
        if parsed["DT_COMPETENCIA"] != month:
            raise RuntimeError(f"Competencia divergente: {month}/{level}")
        if not parsed[DESCRIPTION_FIELDS[level]].strip():
            raise RuntimeError(f"Descricao vazia: {month}/{level}")
        key = "".join(parsed[x] for x in keys)
        if key in rows:
            raise RuntimeError(f"Duplicidade de chave: {month}/{level}/{key}")
        rows[key] = parsed[DESCRIPTION_FIELDS[level]]
    if not rows:
        raise RuntimeError(f"Tabela hierarquica vazia: {month}/{level}")
    return rows


def load_procedures(month: str, record: dict) -> list[str]:
    root = PROCEDURES / month
    data_path = root / "tb_procedimento.txt"
    layout_path = root / "tb_procedimento_layout.txt"
    if (not data_path.is_file() or not layout_path.is_file()
        or sha256_file(data_path) != record["procedure_sha256"]
        or sha256_file(layout_path) != record["layout_sha256"]):
        raise RuntimeError(f"TXT procedimento ausente/divergente: {month}")
    layout = procedure_layout(layout_path.read_bytes(), month)
    fields = {c["field"]: c for c in layout}
    if "CO_PROCEDIMENTO" not in fields or "DT_COMPETENCIA" not in fields:
        raise RuntimeError(f"Campos obrigatorios nao achados: {month}")
    if int(fields["CO_PROCEDIMENTO"]["width"]) != 10:
        raise RuntimeError(f"Largura do procedimento inesperada: {month}")
    codes = []
    for i, raw in enumerate(data_path.read_bytes().splitlines(), 1):
        if len(raw) != int(layout[-1]["end"]):
            raise RuntimeError(f"Largura de linha: {month}/procedimento/{i}")
        code_field = fields["CO_PROCEDIMENTO"]
        competence_field = fields["DT_COMPETENCIA"]
        code = raw[int(code_field["start"])-1:int(code_field["end"])]
        reference = raw[int(competence_field["start"])-1:int(competence_field["end"])]
        if (len(code) != 10 or not all(48 <= b <= 57 for b in code)
            or reference != month.encode("ascii")):
            raise RuntimeError(f"Codigo/competencia: {month}/procedimento/{i}")
        codes.append(code.decode("ascii"))
    if len(codes) != int(record["procedure_rows"]) or len(codes) != len(set(codes)):
        raise RuntimeError(f"Contagem/chaves C3.3 divergentes: {month}")
    return codes


def main() -> int:
    indexed = inspect_inventory()
    sources = read_inventory(INVENTORY, SAMPLE_COMPETENCES)
    previous = load_previous_sample(C3_2_SUMMARY, SAMPLE_COMPETENCES)
    procedures = load_procedure_manifest()
    total = 0
    missing = Counter()
    parent_missing = Counter()
    preview_changes = []

    print("MODE=SIGTAP_HIERARCHY_RELATIONAL_PILOT")
    print("COMPETENCES=" + ",".join(SAMPLE_COMPETENCES))
    print("PREFIX_2_4_6=HYPOTHESIS_UNTIL_TEST")
    print("PERSISTENT_OUTPUTS=NONE")
    with ftplib.FTP(timeout=120) as ftp:
        ftp.connect(FTP_HOST)
        ftp.login()
        ftp.cwd(FTP_DIRECTORY)
        for month in SAMPLE_COMPETENCES:
            package = sources[month]
            saved = previous[month]
            if package["filename"] != saved["package_filename"]:
                raise RuntimeError(f"Pacote inventario incorreto: {month}")
            with tempfile.TemporaryDirectory(prefix="sigtap_pilot_"+month+"_") as temp:
                target = Path(temp) / package["filename"]
                nbytes = receive_zip(ftp, package["filename"], target)
                if (nbytes != int(saved["package_size_bytes"])
                    or sha256_file(target) != saved["package_sha256"]):
                    raise RuntimeError(f"SHA ZIP mudou desde C3.2: {month}")
                with zipfile.ZipFile(target) as zf:
                    if zf.testzip() is not None:
                        raise RuntimeError(f"CRC invalido: {month}")
                    hierarchy = {}
                    for level in LEVEL_FILES:
                        blobs = {}
                        for ext in (".txt", "_layout.txt"):
                            name = level + ext
                            info = find_exact_member(zf, name)
                            expected = indexed[(month, name)]
                            if (info.filename != expected["zip_member"]
                                or info.file_size != int(expected["uncompressed_size"])
                                or f"{info.CRC:08x}".lower() != expected["crc32"].lower()):
                                raise RuntimeError(f"Membro divergente: {month}/{name}")
                            blobs[ext] = zf.read(info)
                        digest = hashlib.sha256(blobs["_layout.txt"]).hexdigest()
                        if digest != LAYOUT_HASHES[level]:
                            raise RuntimeError(f"Layout mudou: {month}/{level}")
                        columns = read_layout(blobs["_layout.txt"], month, level)
                        hierarchy[level] = parse_table(blobs[".txt"], columns, month, level)

            group = hierarchy["tb_grupo"]
            subgroup = hierarchy["tb_sub_grupo"]
            form = hierarchy["tb_forma_organizacao"]
            # Checagem de parentesco dentro do MESMO snapshot, sem join temporal futuro.
            for key in subgroup:
                if key[:2] not in group:
                    parent_missing["subgroup_to_group"] += 1
            for key in form:
                if key[:4] not in subgroup:
                    parent_missing["form_to_subgroup"] += 1
                if key[:2] not in group:
                    parent_missing["form_to_group"] += 1

            codes = load_procedures(month, procedures[month])
            total += len(codes)
            examples = []
            for code in codes:
                for level, prefix in (
                    ("group", code[:2]),
                    ("subgroup", code[:4]),
                    ("form", code[:6]),
                ):
                    registry = {"group": group, "subgroup": subgroup, "form": form}[level]
                    if prefix not in registry:
                        missing[level] += 1
                        if len(examples) < 5:
                            examples.append(f"{code}:{level}:{prefix}")
            print(
                f"[{month}] GROUP={len(group)} SUBGROUP={len(subgroup)} "
                f"FORM={len(form)} PROCEDURES={len(codes)} "
                f"UNMATCHED_SAMPLE={examples}"
            )
            preview_changes.append((month, tuple(list(group.items())[:2])))

    print("PILOT_PROCEDURES=" + str(total))
    print("UNMATCHED_PROCEDURE_GROUP=" + str(missing["group"]))
    print("UNMATCHED_PROCEDURE_SUBGROUP=" + str(missing["subgroup"]))
    print("UNMATCHED_PROCEDURE_FORM=" + str(missing["form"]))
    print("PARENT_MISSING=" + str(dict(parent_missing)))
    print("DECODED_NAME_SAMPLES_CP1252_ONLY=" + str(preview_changes))
    if total != 18362 or missing or parent_missing:
        print("VERDICT=REVIEW_HIERARCHY_RELATIONSHIPS")
        return 2
    print("VERDICT=PASS_4_MONTH_HIERARCHY_RELATIONAL_PILOT_ONLY")
    print("FULL_36_MONTH_HIERARCHY_GATE=NOT_EVALUATED")
    print("DESCRIPTION_ENCODING_APPROVAL=NOT_EVALUATED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
