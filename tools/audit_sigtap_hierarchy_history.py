#!/usr/bin/env python3
"""Auditoria independente READ-ONLY de 216 TXT hierarquicos SIGTAP materializados.

Confere manifesto, 36 competencias e os 216 arquivos originais (SHA-256,
tamanho, nomes e paths), sem alterar fontes ou gerar artefatos.
"""
from __future__ import annotations

import hashlib
import json
import re
from collections import Counter
from pathlib import Path

from inspect_sigtap_hierarchy_sample import LEVEL_FILES
from materialize_sigtap_procedure_history import COMPETENCES

ROOT = Path("BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO")
MANIFEST = Path("BASE/REFERENCIAS/sigtap_hierarchy_history_manifest.json")
FILES_EXPECTED = {
    (month, level + suffix)
    for month in COMPETENCES
    for level in LEVEL_FILES
    for suffix in (".txt", "_layout.txt")
}


def sha256_file(path: Path) -> str:
    hash_ = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            hash_.update(chunk)
    return hash_.hexdigest()


def main() -> int:
    if not MANIFEST.is_file():
        raise RuntimeError("Manifesto de hierarquia ausente")
    doc = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if (
        doc.get("status") != "PASS"
        or doc.get("stage") != "IV_PROCEDIMENTO_SIGTAP_HIERARCHY_36_MONTH_RELATIONAL_GATE"
        or doc.get("competences") != 36
        or doc.get("procedure_rows") != 165203
        or doc.get("members") != 216
        or doc.get("historical_joins") != "PASS_36_MONTH_SAME_COMPETENCE_2_4_6"
        or doc.get("qvd_generated") is not False
        or doc.get("t27_retested") is not False
        or doc.get("t29_historical") != "NOT_APPROVED"
        or doc.get("facts_and_link_table") != "NOT_STARTED"
        or doc.get("description_encoding") != "CP1252_CANDIDATE_AWAITING_DESCRIPTIVE_AUDIT"
    ):
        raise RuntimeError("Manifesto nao corresponde ao gate historico parcial esperado")
    if (
        len(doc.get("source_package_provenance", [])) != 36
        or len(doc.get("records_by_month", [])) != 36
    ):
        raise RuntimeError("Proveniencia e perfis mensais incompletos")
    packages = {r.get("competence"): r for r in doc["source_package_provenance"]}
    months = {r.get("competence"): r for r in doc["records_by_month"]}
    if set(packages) != set(COMPETENCES) or set(months) != set(COMPETENCES):
        raise RuntimeError("Competencias de origem/perfil divergentes")
    if sum(int(x["procedure_rows"]) for x in months.values()) != 165203:
        raise RuntimeError("Total de procedimentos do manifesto inconsistente")
    if any(
        any(int(x[key]) != 0 for key in (
            "unmatched_group", "unmatched_subgroup", "unmatched_form",
            "missing_parents",
        ))
        for x in months.values()
    ):
        raise RuntimeError("Manifesto contem correspondencias nao resolvidas")

    files = doc.get("files", [])
    if len(files) != 216:
        raise RuntimeError("Numero de arquivos no manifesto divergente")
    observed: set[tuple[str, str]] = set()
    bytes_total = 0
    for row in files:
        month, filename = row.get("competence"), row.get("filename")
        key = (month, filename)
        if key not in FILES_EXPECTED or key in observed:
            raise RuntimeError(f"Membro inesperado ou duplicado: {key}")
        observed.add(key)
        path = ROOT / month / filename
        if Path(row.get("path", "")) != path:
            raise RuntimeError(f"Caminho manifestado divergente: {key}")
        if not path.is_file() or path.is_symlink():
            raise RuntimeError(f"Arquivo ausente ou link simbolico: {path}")
        digest = row.get("sha256", "")
        if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise RuntimeError(f"SHA-256 malformado: {path}")
        if path.stat().st_size != int(row["size_bytes"]) or sha256_file(path) != digest:
            raise RuntimeError(f"Arquivo alterado/incompleto: {path}")
        bytes_total += path.stat().st_size
    if observed != FILES_EXPECTED:
        raise RuntimeError("Nao existem exatamente os 216 membros esperados")

    print("MANIFEST_SHA256=" + sha256_file(MANIFEST))
    print("COMPETENCES_VERIFIED=36")
    print("FILES_VERIFIED=216")
    print("PROCEDURES_RECONCILED=165203")
    print("UNMATCHED_ALL_LEVELS=0")
    print("FILES_TOTAL_BYTES=" + str(bytes_total))
    print("DESCRIPTION_ENCODING=NOT_APPROVED")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("QVD_GENERATED=False")
    print("VERDICT=PASS_LOCAL_216_HIERARCHY_FILES_SHA_RECONCILED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
