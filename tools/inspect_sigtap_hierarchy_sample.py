#!/usr/bin/env python3
"""Fase IV — inspeção da hierarquia SIGTAP em QUATRO pacotes já inventariados.

Download temporário dos ZIPs oficiais da amostra C3.2, com hash SHA-256,
tamanho e CRC reconciliados; leitura de 6 membros por pacote, apenas em
memória. NÃO gera CSV/QVD, não persiste extrações, não interpreta joins,
não baixa as 36 competências e não altera o staging existente.
"""
from __future__ import annotations

import argparse
import csv
import ftplib
import hashlib
import io
import tempfile
import zipfile
from collections import Counter
from pathlib import Path

from inspect_sigtap_procedure_sample import (
    FTP_DIRECTORY, FTP_HOST, INVENTORY, MEMBERS_CSV,
    SAMPLE_COMPETENCES, read_inventory, receive_zip, sha256_file,
)
from materialize_sigtap_procedure_sample import (
    find_exact_member, load_previous_sample,
)

C3_2_SUMMARY = Path("BASE/REFERENCIAS/sigtap_procedure_sample_summary.json")
MEMBERS_SHA256 = "110e9c22ed79cbab47e5c7726b9d19f9f2fe7117f7519e81d1319fca5583d0ad"
LEVEL_FILES = (
    "tb_grupo",
    "tb_sub_grupo",
    "tb_forma_organizacao",
)
LAYOUT_HEADER = ["Coluna", "Tamanho", "Inicio", "Fim", "Tipo"]
MAX_HIERARCHY_FILE_BYTES = 8 * 1024 * 1024
PREVIEW_ROWS = 2


def inspect_inventory() -> dict[tuple[str, str], dict[str, str]]:
    if sha256_file(MEMBERS_CSV) != MEMBERS_SHA256:
        raise RuntimeError("C3.2 membros: SHA-256 divergente")
    with MEMBERS_CSV.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        if reader.fieldnames is None or not {
            "competence", "basename", "zip_member", "uncompressed_size", "crc32"
        }.issubset(reader.fieldnames):
            raise RuntimeError("Inventario C3.2: cabecalho inesperado")
        rows = list(reader)
    counts = Counter(r["competence"] for r in rows)
    if len(rows) != 348 or counts != Counter({
        "201701": 87, "201801": 87, "201901": 87, "201912": 87
    }):
        raise RuntimeError("Inventario C3.2: contagem de membros incorreta")
    result = {}
    expected_names = {
        level + suffix
        for level in LEVEL_FILES
        for suffix in (".txt", "_layout.txt")
    }
    for row in rows:
        key = (row["competence"], row["basename"].lower())
        # O inventario pode ter nomes repetidos de OUTROS arquivos em
        # diretorios diferentes. Exigir unicidade somente para os 6 membros
        # exatos que serao de fato utilizados.
        if key[1] not in expected_names:
            continue
        if key in result:
            raise RuntimeError(f"Membro de hierarquia duplicado: {key}")
        result[key] = row
    for month in SAMPLE_COMPETENCES:
        for level in LEVEL_FILES:
            for suffix in (".txt", "_layout.txt"):
                if (month, level + suffix) not in result:
                    raise RuntimeError(
                        f"Membro oficial esperado ausente: {month}/{level + suffix}"
                    )
    print("INVENTORY_SHA_MATCH=True")
    print("INVENTORY_MEMBERS=348")
    return result


def read_layout(data: bytes, month: str, level: str) -> list[dict[str, object]]:
    # Header/layout CSV candidato cp1252 conforme padrão já observado em tb_procedimento.
    # Se divergir, falhar e registrar o problema; NÃO fabricar posições.
    reader = csv.DictReader(io.StringIO(data.decode("cp1252")), delimiter=",")
    print(f"[{month}][{level}] RAW_LAYOUT_HEADER={reader.fieldnames}")
    if reader.fieldnames != LAYOUT_HEADER:
        raise RuntimeError(f"Layout hierarquia inesperado {month}/{level}")
    columns: list[dict[str, object]] = []
    previous_end = 0
    seen: set[str] = set()
    for raw in reader:
        if None in raw or any(x is None for x in raw.values()):
            raise RuntimeError(f"Layout invalido: {month}/{level}")
        name = raw["Coluna"].strip()
        width = int(raw["Tamanho"])
        start = int(raw["Inicio"])
        end = int(raw["Fim"])
        if (not name or name in seen or width < 1
                or start != previous_end + 1 or end != start + width - 1):
            raise RuntimeError(f"Posicoes nao contiguas: {month}/{level}/{raw}")
        seen.add(name)
        columns.append({
            "field": name, "start": start, "end": end,
            "width": width, "type": raw["Tipo"].strip(),
        })
        previous_end = end
    if not columns:
        raise RuntimeError(f"Layout vazio: {month}/{level}")
    return columns


def inspect_data(
    data: bytes, columns: list[dict[str, object]], month: str, level: str
) -> dict[str, object]:
    width = int(columns[-1]["end"])
    lines = data.splitlines()
    lengths = Counter(len(line) for line in lines)
    blank_code_fields = 0
    samples: list[dict[str, str]] = []
    code_columns = [
        c for c in columns if str(c["field"]).startswith("CO_")
    ]
    for index, line in enumerate(lines):
        if len(line) != width:
            continue  # registra todas as divergencias no contador de comprimento
        row: dict[str, str] = {}
        for col in columns:
            name = str(col["field"])
            start, end = int(col["start"]) - 1, int(col["end"])
            raw = line[start:end]
            # cp1252 APENAS para visualizacao da amostra; encoding nao aprovado aqui.
            row[name] = raw.decode("cp1252", errors="replace").rstrip(" ")
        if any(not row[str(col["field"])].strip() for col in code_columns):
            blank_code_fields += 1
        if len(samples) < PREVIEW_ROWS:
            samples.append(row)
    invalid_lengths = sum(n for length, n in lengths.items() if length != width)
    print(
        f"[{month}][{level}] DATA_ROWS={len(lines)} WIDTH={width} "
        f"INVALID_LENGTHS={invalid_lengths} BLANK_CODE_ROWS={blank_code_fields}"
    )
    print(f"[{month}][{level}] FIELDS={[c['field'] for c in columns]}")
    for col in columns:
        print(
            f"[{month}][{level}] LAYOUT_FIELD={col['field']} "
            f"START={col['start']} END={col['end']} "
            f"WIDTH={col['width']} TYPE={col['type']}"
        )
    for sample in samples:
        print(f"[{month}][{level}] SAMPLE_CP1252_CANDIDATE={sample}")
    return {
        "rows": len(lines), "invalid_lengths": invalid_lengths,
        "blank_code_rows": blank_code_fields,
        "layout_signature": tuple(
            (str(c["field"]), int(c["start"]), int(c["end"]), str(c["type"]))
            for c in columns
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()
    indexed = inspect_inventory()
    packages = read_inventory(INVENTORY, SAMPLE_COMPETENCES)
    previous = load_previous_sample(C3_2_SUMMARY, SAMPLE_COMPETENCES)
    signatures: dict[str, set[tuple]] = {name: set() for name in LEVEL_FILES}
    total_files = 0
    integrity_errors = 0

    print("MODE=CONTROLLED_SIGTAP_HIERARCHY_SAMPLE")
    print("SAMPLE_COMPETENCES=" + ",".join(SAMPLE_COMPETENCES))
    print("PERSISTENT_OUTPUTS=NONE")
    print("FULL_36_PACKAGES_DOWNLOADED=False")
    with ftplib.FTP(timeout=args.timeout) as ftp:
        ftp.connect(FTP_HOST)
        ftp.login()
        ftp.cwd(FTP_DIRECTORY)
        for month in SAMPLE_COMPETENCES:
            pkg = packages[month]
            before = previous[month]
            name = pkg["filename"]
            if name != before["package_filename"]:
                raise RuntimeError(f"Inventario/pacote C3.2 divergente: {month}")
            print(f"[{month}] FETCH_TEMPORARY={name}")
            with tempfile.TemporaryDirectory(
                prefix=f"sigtap_hierarchy_{month}_"
            ) as tmp:
                archive_path = Path(tmp) / name
                received = receive_zip(ftp, name, archive_path)
                if (
                    received != int(before["package_size_bytes"])
                    or sha256_file(archive_path) != before["package_sha256"]
                ):
                    raise RuntimeError(f"Pacote alterado desde C3.2: {month}")
                with zipfile.ZipFile(archive_path, "r") as zf:
                    corrupted = zf.testzip()
                    if corrupted:
                        raise RuntimeError(f"CRC invalido: {month}/{corrupted}")
                    for level in LEVEL_FILES:
                        blobs = {}
                        for suffix in (".txt", "_layout.txt"):
                            base = level + suffix
                            member = find_exact_member(zf, base)
                            recorded = indexed[(month, base)]
                            if (member.filename != recorded["zip_member"]
                                    or member.file_size != int(recorded["uncompressed_size"])
                                    or f"{member.CRC:08x}".lower() != recorded["crc32"].lower()
                                    or member.file_size > MAX_HIERARCHY_FILE_BYTES):
                                raise RuntimeError(
                                    f"Metadados inesperados: {month}/{base}"
                                )
                            blobs[base] = zf.read(member)
                            print(
                                f"[{month}][{level}] MEMBER={base} "
                                f"BYTES={len(blobs[base])} "
                                f"SHA256={hashlib.sha256(blobs[base]).hexdigest()}"
                            )
                            total_files += 1
                        cols = read_layout(blobs[level + "_layout.txt"], month, level)
                        result = inspect_data(blobs[level + ".txt"], cols, month, level)
                        signatures[level].add(result["layout_signature"])
                        if (not result["rows"] or result["invalid_lengths"]
                                or result["blank_code_rows"]):
                            integrity_errors += 1

    for level in LEVEL_FILES:
        print(f"LEVEL={level} LAYOUT_SIGNATURES={len(signatures[level])}")
    print(f"MEMBERS_INSPECTED={total_files}")
    print(f"INTEGRITY_ERRORS={integrity_errors}")
    if total_files != 24 or integrity_errors:
        print("VERDICT=REVIEW_PHYSICAL_SOURCE")
        return 2
    print("VERDICT=PASS_SAMPLE_STRUCTURE_ONLY")
    print("RELATIONAL_JOINS_AND_ENCODING=NOT_APPROVED")
    print("T27_HISTORICAL_GATE=PREVIOUS_PASS_NOT_RETESTED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
