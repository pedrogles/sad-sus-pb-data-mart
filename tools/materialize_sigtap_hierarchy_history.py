#!/usr/bin/env python3
"""Fase IV: aquisição CONTROLADA e validação SIGTAP hierárquica, 36 competências.

Pré-requisitos: T27 PASS, C3.3b.1 procedimento histórico PASS e piloto hierárquico
amostral 4 meses PASS. Cada ZIP oficial é confrontado com SHA-256 e tamanho
da aquisição C3.3b.1; 6 membros (3 tabelas + layouts) são testados por mês.

Somente depois de TODOS os 36 meses passarem, grava 216 TXT originais ao lado
do procedimento existente em BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM,
e um manifesto de proveniência em BASE/REFERENCIAS. Não gera QVD, não
modifica arquivos de procedimento já validados, fatos nem esquema acadêmico.
"""
from __future__ import annotations

import argparse
import ftplib
import hashlib
import json
import os
import tempfile
import zipfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from inspect_sigtap_hierarchy_sample import (
    LEVEL_FILES, MAX_HIERARCHY_FILE_BYTES, read_layout,
)
from inspect_sigtap_procedure_sample import (
    FTP_HOST, FTP_DIRECTORY, INVENTORY, read_inventory, receive_zip, sha256_file,
)
from materialize_sigtap_procedure_sample import find_exact_member
from materialize_sigtap_procedure_history import COMPETENCES
from validate_sigtap_hierarchy_relational_pilot import (
    HISTORY, PROCEDURES, LAYOUT_HASHES, load_procedures, parse_table,
)

OUTPUT_MANIFEST = Path("BASE/REFERENCIAS/sigtap_hierarchy_history_manifest.json")
MEMBER_NAMES = tuple(
    name + extension
    for name in LEVEL_FILES
    for extension in (".txt", "_layout.txt")
)
EXPECTED_LAYOUT_HASHES = LAYOUT_HASHES
HISTORIC_PROCEDURE_ROWS = 165203


def load_historical_sources() -> tuple[dict[str, dict], dict[str, dict]]:
    if not HISTORY.is_file():
        raise RuntimeError("Manifesto C3.3b.1 historico SIGTAP ausente")
    manifest = json.loads(HISTORY.read_text(encoding="utf-8"))
    if manifest.get("status") != "PASS":
        raise RuntimeError("C3.3b.1 procedimento historico nao tem PASS")
    records = manifest.get("materialized", [])
    if len(records) != 36:
        raise RuntimeError("Manifesto SIGTAP historico nao possui 36 registros")
    by_month = {}
    for row in records:
        month = row.get("competence")
        if month in by_month or month not in COMPETENCES:
            raise RuntimeError(f"Competencia repetida/desconhecida: {month}")
        if (not row.get("package_sha256") or
            not row.get("package_filename") or
            int(row.get("package_size_bytes", 0)) < 1):
            raise RuntimeError(f"Proveniencia do pacote incompleta: {month}")
        by_month[month] = row
    if set(by_month) != set(COMPETENCES):
        raise RuntimeError("Manifesto de procedimento sem 36 meses consecutivos")
    inventoried = read_inventory(INVENTORY, COMPETENCES)
    codes = {}
    for month in COMPETENCES:
        record = by_month[month]
        package = inventoried[month]
        if (record["package_filename"] != package["filename"]
            or int(record["package_size_bytes"]) != int(package["size_bytes"])):
            raise RuntimeError(f"Inventario/pacote divergente: {month}")
        codes[month] = load_procedures(month, record)
    if sum(len(x) for x in codes.values()) != HISTORIC_PROCEDURE_ROWS:
        raise RuntimeError("Contagem dos 165203 procedimentos historicos divergente")
    print("PROCEDURE_HISTORY_SHA_AND_MONTH_CHECK=PASS")
    print("PROCEDURE_HISTORY_ROWS=" + str(HISTORIC_PROCEDURE_ROWS))
    return by_month, codes


def evaluate_month(month: str, blobs: dict[str, bytes], codes: list[str]) -> dict:
    tables = {}
    rows = {}
    for level in LEVEL_FILES:
        layout_bytes = blobs[level + "_layout.txt"]
        sha = hashlib.sha256(layout_bytes).hexdigest()
        if sha != EXPECTED_LAYOUT_HASHES[level]:
            raise RuntimeError(f"Layout hierarquico mudou: {month}/{level}")
        layout = read_layout(layout_bytes, month, level)
        tables[level] = parse_table(blobs[level + ".txt"], layout, month, level)
        rows[level] = len(tables[level])

    group = tables["tb_grupo"]
    subgroup = tables["tb_sub_grupo"]
    form = tables["tb_forma_organizacao"]

    missing_parents = Counter()
    for subkey in subgroup:
        if subkey[:2] not in group:
            missing_parents["subgroup_group"] += 1
    for formkey in form:
        if formkey[:2] not in group:
            missing_parents["form_group"] += 1
        if formkey[:4] not in subgroup:
            missing_parents["form_subgroup"] += 1

    missing_proc = Counter()
    examples = []
    for code in codes:
        for level, key, ref in (
            ("group", code[:2], group),
            ("subgroup", code[:4], subgroup),
            ("form", code[:6], form),
        ):
            if key not in ref:
                missing_proc[level] += 1
                if len(examples) < 5:
                    examples.append(f"{code}:{level}:{key}")

    if missing_parents or missing_proc:
        raise RuntimeError(
            f"Cobertura historica hierarquica nao passou em {month}: "
            f"orfaos={dict(missing_parents)}, nao_encontrados={dict(missing_proc)}, "
            f"exemplos={examples}"
        )
    print(
        f"[{month}] GROUP={rows['tb_grupo']} SUBGROUP={rows['tb_sub_grupo']} "
        f"FORM={rows['tb_forma_organizacao']} PROCEDURES={len(codes)} "
        f"UNMATCHED_GROUP=0 UNMATCHED_SUBGROUP=0 UNMATCHED_FORM=0 PARENTS=0"
    )
    return {
        "competence": month,
        "groups": rows["tb_grupo"],
        "subgroups": rows["tb_sub_grupo"],
        "forms": rows["tb_forma_organizacao"],
        "procedure_rows": len(codes),
        "unmatched_group": 0,
        "unmatched_subgroup": 0,
        "unmatched_form": 0,
        "missing_parents": 0,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=int, default=120)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument(
        "--validate-only", action="store_true",
        help="Inspeciona 36 meses SEM gravar TXT nem manifesto (mas baixa ZIPs temporarios).",
    )
    mode.add_argument(
        "--materialize", action="store_true",
        help="Apos todas as validacoes, preservar os 216 TXT originais e manifesto local.",
    )
    args = parser.parse_args()

    history, codes_by_month = load_historical_sources()
    staged: dict[tuple[str, str], bytes] = {}
    monthly: list[dict] = []
    packages: list[dict] = []

    print("MODE=CONTROLLED_SIGTAP_HIERARCHY_36_MONTH_HISTORY")
    print("COMPETENCES=36")
    print("ONLY_6_FILES_PER_PACKAGE=True")
    print("VALIDATE_ONLY=" + str(args.validate_only))
    print("T29_HISTORICAL=NOT_APPROVED")

    with ftplib.FTP(timeout=args.timeout) as ftp:
        ftp.connect(FTP_HOST)
        ftp.login()
        ftp.cwd(FTP_DIRECTORY)
        for month in COMPETENCES:
            info = history[month]
            name = info["package_filename"]
            print(f"[{month}] FETCH_TEMPORARY={name}")
            with tempfile.TemporaryDirectory(prefix=f"sigtap_hier_{month}_") as tmp:
                zpath = Path(tmp) / name
                size = receive_zip(ftp, name, zpath)
                sha = sha256_file(zpath)
                if (size != int(info["package_size_bytes"])
                    or sha != info["package_sha256"]):
                    raise RuntimeError(f"Pacote alterado em relacao a C3.3b.1: {month}")
                with zipfile.ZipFile(zpath) as zipfile_obj:
                    bad = zipfile_obj.testzip()
                    if bad is not None:
                        raise RuntimeError(f"Erro de CRC no pacote: {month}/{bad}")
                    blobs = {}
                    for basename in MEMBER_NAMES:
                        member = find_exact_member(zipfile_obj, basename)
                        if member.file_size > MAX_HIERARCHY_FILE_BYTES:
                            raise RuntimeError(f"Membro excede limite: {month}/{basename}")
                        content = zipfile_obj.read(member)
                        if len(content) != member.file_size:
                            raise RuntimeError(f"Leitura incompleta: {month}/{basename}")
                        blobs[basename] = content
                        staged[month, basename] = content
                monthly.append(evaluate_month(month, blobs, codes_by_month[month]))
                packages.append({
                    "competence": month,
                    "filename": name,
                    "package_sha256": sha,
                    "package_size_bytes": size,
                })

    if len(monthly) != 36 or len(staged) != 36 * 6:
        raise RuntimeError("Historico de hierarquia incompleto: esperado 36x6")
    if sum(m["procedure_rows"] for m in monthly) != HISTORIC_PROCEDURE_ROWS:
        raise RuntimeError("Total de procedimentos historicos nao conciliado")

    outputs = []
    for (month, filename), content in sorted(staged.items()):
        target = PROCEDURES / month / filename
        if not target.parent.is_dir():
            raise RuntimeError(f"Diretorio historico ja existente ausente: {target.parent}")
        digest = hashlib.sha256(content).hexdigest()
        if target.exists() and sha256_file(target) != digest:
            raise RuntimeError(f"Recusa sobrescrever arquivo divergente: {target}")
        outputs.append({
            "competence": month, "filename": filename, "path": str(target),
            "sha256": digest, "size_bytes": len(content),
        })

    # Se existe manifesto anterior contraditorio, bloquear ANTES da escrita.
    if OUTPUT_MANIFEST.exists() and not args.validate_only:
        previous = json.loads(OUTPUT_MANIFEST.read_text(encoding="utf-8"))
        if previous.get("status") != "PASS" or previous.get("files") != outputs:
            raise RuntimeError("Manifesto historico existente divergente; sem escrita")

    if args.validate_only:
        print("MONTHS_VALIDATED=36")
        print("MEMBERS_VALIDATED=216")
        print("PROCEDURES_COVERED=165203")
        print("UNMATCHED_ALL_LEVELS=0")
        print("PERSISTENT_OUTPUTS=NONE")
        print("VERDICT=PASS_36_MONTH_RELATIONAL_VALIDATION_ONLY")
        return 0

    # Nenhum arquivo persistente foi modificado ate este ponto.
    # Nunca sobrescrever membros anteriores com conteudo diferente.
    written = 0
    for (month, filename), content in sorted(staged.items()):
        target = PROCEDURES / month / filename
        if not target.exists():
            with target.open("xb") as handle:
                handle.write(content)
            written += 1
        if sha256_file(target) != hashlib.sha256(content).hexdigest():
            raise RuntimeError(f"Arquivo persistido divergente: {target}")

    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": "PASS",
        "stage": "IV_PROCEDIMENTO_SIGTAP_HIERARCHY_36_MONTH_RELATIONAL_GATE",
        "source_procedure_history_manifest": str(HISTORY),
        "source_package_provenance": packages,
        "competences": 36,
        "procedure_rows": HISTORIC_PROCEDURE_ROWS,
        "members": 216,
        "records_by_month": monthly,
        "files": outputs,
        "historical_joins": "PASS_36_MONTH_SAME_COMPETENCE_2_4_6",
        "description_encoding": "CP1252_CANDIDATE_AWAITING_DESCRIPTIVE_AUDIT",
        "qvd_generated": False,
        "t27_retested": False,
        "t29_historical": "NOT_APPROVED",
        "facts_and_link_table": "NOT_STARTED",
    }
    # Manifesto derivado fica fora do controle de versao; substituicao atomica.
    # Compatibilidade de um manifesto anterior ja foi verificada ANTES dos writes.
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", newline="\n", suffix=".tmp",
        prefix=".sigtap_hierarchy_", dir=OUTPUT_MANIFEST.parent,
        delete=False,
    ) as handle:
        tmp_name = handle.name
        json.dump(manifest, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    os.replace(tmp_name, OUTPUT_MANIFEST)

    print("MONTHS_VALIDATED=36")
    print("MEMBERS_VALIDATED=216")
    print("PROCEDURES_COVERED=165203")
    print("UNMATCHED_ALL_LEVELS=0")
    print("NEW_MEMBERS_MATERIALIZED=" + str(written))
    print("MANIFEST=" + str(OUTPUT_MANIFEST))
    print("MANIFEST_SHA256=" + sha256_file(OUTPUT_MANIFEST))
    print("DESCRIPTION_ENCODING=REVIEW_PENDING")
    print("VERDICT=PASS_36_MONTH_HIERARCHY_PHYSICAL_AND_RELATIONAL")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
