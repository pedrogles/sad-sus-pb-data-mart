#!/usr/bin/env python3
"""Fase IV — preflight READ-ONLY de DIM_MOTIVO_SAIDA_PERMANENCIA.

Fontes locais C1: manifesto, CSV normativo (28 códigos), QVD de extração,
checkpoint e os 36 CSVs RD (campo COBRANCA). Compara as 28 linhas do CSV
com o materializador aprovado, inclusos código normativo 24 -> 2.4,
rótulos, categoria e proveniência. Nenhuma escrita/download/reload.

Limite: lê somente header XML de QVD, não o conteúdo binário.
"""
from __future__ import annotations

import csv
import glob
import hashlib
import json
from collections import Counter
from pathlib import Path

from materialize_normative_references import (
    CARATER_ATENDIMENTO, MOTIVO_SAIDA_PERMANENCIA,
    PORTARIA_719, PORTARIA_384,
)
from preflight_dim_diagnostico_cid10 import qvd_header

ROOT = Path("BASE/REFERENCIAS")
CSV = ROOT / "motivo_saida_permanencia.csv"
CAR_CSV = ROOT / "carater_atendimento.csv"
MANIFEST = ROOT / "manifesto_referencias_normativas.json"
QVD = Path("EXTRACAO/QVD/REF_MOTIVO_SAIDA.qvd")
RD_QVD = Path("EXTRACAO/QVD/SRC_SIH_RD.qvd")
CHECKPOINT = Path("EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_REFERENCIAS_NORMATIVAS.csv")
RD_GLOB = r"BASE\CONVERTIDA\RD\RDPB*.csv"

EXPECTED_REF_FIELDS = [
    "codigo_fonte", "codigo_normativo", "descricao", "grupo",
    "fonte_oficial_base", "fonte_oficial_atualizacao",
]
EXPECTED_QVD_FIELDS = [
    "COBRANCA", "MOTIVO_CODIGO_NORMATIVO", "MOTIVO_DESCRICAO",
    "MOTIVO_GRUPO", "MOTIVO_FONTE_OFICIAL_BASE",
    "MOTIVO_FONTE_OFICIAL_ATUALIZACAO",
    "_META_SOURCE_FILE", "_META_SOURCE_FAMILY", "_META_SOURCE_PATH",
]
EXPECTED_CKPT = {
    "stage": "EXTRACAO_REFERENCIAS_NORMATIVAS",
    "status": "PASS_PARTIAL",
    "carater_rows": "6",
    "carater_unmatched_rd_rows": "0",
    "motivo_rows": "28",
    "motivo_unmatched_rd_rows": "0",
}
EXPECTED_MONTHS = {
    f"{year}{month:02d}" for year in range(2017, 2020)
    for month in range(1, 13)
}
EXPECTED_CODES = {
    "11", "12", "14", "15", "16", "18", "19",
    "21", "22", "23", "24", "25", "26", "27", "28",
    "31", "32", "41", "42", "43", "51",
    "61", "62", "63", "64", "65", "66", "67",
}
EXPECTED_RD_YEAR_ROWS = {"2017": 187726, "2018": 187293, "2019": 191653}
EXPECTED_ABSENT_RD = {"32", "67"}
REVOKED = {"13", "17"}
DIGITS = set("0123456789")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check_manifest() -> str:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if (
        manifest.get("stage") != "PHASE_III_C1_NORMATIVE_REFERENCES"
        or manifest.get("status") != "PASS"
    ):
        raise RuntimeError("Manifesto III-C1 não aprovado")
    sources = manifest.get("sources")
    if not isinstance(sources, list) or {
        x.get("url") for x in sources
    } != {PORTARIA_719, PORTARIA_384}:
        raise RuntimeError("Fontes normativas 719/2007 e 384/2010 divergentes")

    files = manifest.get("files")
    if not isinstance(files, list) or len(files) != 2:
        raise RuntimeError("Manifesto III-C1 deve ter exatamente dois arquivos")
    entries = {x.get("name"): x for x in files}
    motivo = entries.get("motivo_saida_permanencia.csv")
    carater = entries.get("carater_atendimento.csv")
    if (
        len(entries) != 2 or not motivo or not carater
        or motivo.get("rows") != 28 or carater.get("rows") != 6
    ):
        raise RuntimeError("Manifesto deve declarar Motivo 28 / Caráter 6")
    motivo_sha = sha256(CSV)
    if (
        motivo_sha != motivo.get("sha256")
        or sha256(CAR_CSV) != carater.get("sha256")
    ):
        raise RuntimeError("SHA-256 das referências C1 não corresponde ao manifesto")
    print("REFERENCE_CSV_SHA256=" + motivo_sha)
    print("REFERENCE_C1_MANIFEST=PASS")
    return motivo_sha


def check_reference() -> dict[str, str]:
    expected = {
        item[0]: item[1:] for item in MOTIVO_SAIDA_PERMANENCIA
    }
    if len(expected) != 28 or set(expected) != EXPECTED_CODES:
        raise RuntimeError("Lista oficial do materializador C1 mudou")
    if len(CARATER_ATENDIMENTO) != 6:
        raise RuntimeError("Materializador C1 caráter divergente")
    with CSV.open("r", newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream, delimiter=";")
        if reader.fieldnames != EXPECTED_REF_FIELDS:
            raise RuntimeError(f"Schema da referência alterado: {reader.fieldnames}")
        rows = list(reader)
    if len(rows) != 28:
        raise RuntimeError(f"Motivo exige 28 linhas; encontrado {len(rows)}")
    codes: dict[str, str] = {}
    norm_seen: set[str] = set()
    groups = Counter()
    for row in rows:
        if None in row or any(v is None for v in row.values()):
            raise RuntimeError("CSV de motivo malformado")
        code = row["codigo_fonte"]
        if code not in expected or code in codes:
            raise RuntimeError(f"Código ausente/duplicado: {code!r}")
        other = tuple(row[f] for f in EXPECTED_REF_FIELDS[1:])
        if other != expected[code]:
            raise RuntimeError(f"Conteúdo normativo divergente do materializador: {code}")
        norm = row["codigo_normativo"]
        if (
            norm in norm_seen or norm != f"{code[0]}.{code[1]}"
            or not row["descricao"] or not row["grupo"]
        ):
            raise RuntimeError(f"Código normativo ou rótulo inválido: {code}")
        norm_seen.add(norm)
        codes[code] = norm
        groups[row["grupo"]] += 1
    if set(codes) != EXPECTED_CODES or codes.get("24") != "2.4":
        raise RuntimeError("Domínio 28/28 ou equivalência 24 => 2.4 alterados")
    if REVOKED.intersection(codes):
        raise RuntimeError("Códigos revogados 13/17 reintroduzidos")
    print("REFERENCE_ROWS=28")
    print("REFERENCE_DISTINCT_SOURCE_CODES=28")
    print("REFERENCE_DISTINCT_NORMATIVE_CODES=28")
    print("REFERENCE_CODE_24=2.4")
    print("REFERENCE_REVOKED_13_17=ABSENT")
    print("REFERENCE_GROUP_ROWS=" + repr(sorted(groups.items())))
    print("REFERENCE_SOURCE_LABELS=EXACT_MATCH_C1_MATERIALIZER")
    return codes


def check_staging() -> None:
    ref_rows, ref_fields = qvd_header(QVD)
    rd_rows, rd_fields = qvd_header(RD_QVD)
    if ref_rows != 28 or ref_fields != EXPECTED_QVD_FIELDS:
        raise RuntimeError(f"REF_MOTIVO_SAIDA.qvd schema/contagem: {ref_rows}/{ref_fields}")
    if rd_rows != 566672 or "COBRANCA" not in rd_fields:
        raise RuntimeError(f"SRC_SIH_RD.qvd esperado com COBRANCA: {rd_rows}/{rd_fields}")
    with CHECKPOINT.open("r", newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream, delimiter=";")
        rows = list(reader)
    if len(rows) != 1 or None in rows[0] or any(v is None for v in rows[0].values()):
        raise RuntimeError("Checkpoint III-C1 exige CSV com uma linha válida")
    for field, value in EXPECTED_CKPT.items():
        if rows[0].get(field) != value:
            raise RuntimeError(f"Checkpoint III-C1 divergente: {field}")
    print("REFERENCE_QVD_ROWS=28")
    print("REFERENCE_QVD_FIELDS=9")
    print("RD_QVD_ROWS=566672")
    print("CHECKPOINT_C1=PASS_PARTIAL_ZERO_UNMATCHED")


def normalize_raw_code(raw: str, file: Path, lineno: int) -> str:
    # Fail-closed: não usar KeepChar para encobrir caracteres inválidos.
    clean = raw.strip(" ")
    if not 1 <= len(clean) <= 2 or any(ch not in DIGITS for ch in clean):
        raise RuntimeError(f"COBRANCA bruto inválido: {file}:{lineno} {raw!r}")
    return clean.zfill(2)


def check_rd(codes: dict[str, str]) -> None:
    paths = sorted(Path(s) for s in glob.glob(RD_GLOB))
    months: set[str] = set()
    raw = Counter()
    norm = Counter()
    years = Counter()
    rows = 0
    for file in paths:
        name = file.stem
        if len(name) != 8 or not name.startswith("RDPB") or not name[4:].isdigit():
            raise RuntimeError(f"Nome de RD inesperado: {file}")
        month = "20" + name[4:]
        if month not in EXPECTED_MONTHS or month in months:
            raise RuntimeError(f"Competência RD inesperada: {file}")
        months.add(month)
        monthly_rows = 0
        with file.open("r", newline="", encoding="utf-8-sig") as stream:
            reader = csv.DictReader(stream, delimiter=";")
            if not reader.fieldnames or "COBRANCA" not in reader.fieldnames:
                raise RuntimeError(f"Campo COBRANCA ausente: {file}")
            for lineno, record in enumerate(reader, 2):
                cell = record.get("COBRANCA")
                if cell is None or None in record:
                    raise RuntimeError(f"RD malformado: {file}:{lineno}")
                code = normalize_raw_code(cell, file, lineno)
                raw[cell] += 1
                norm[code] += 1
                years[month[:4]] += 1
                rows += 1
                monthly_rows += 1
                if code not in codes:
                    raise RuntimeError(f"COBRANCA sem código normativo: {file}:{lineno}/{code}")
        if not monthly_rows:
            raise RuntimeError(f"Arquivo RD vazio: {file}")
    if months != EXPECTED_MONTHS or rows != 566672:
        raise RuntimeError(f"RD deve ter 36 competências e 566672 linhas: {len(months)} / {rows}")
    if dict(years) != EXPECTED_RD_YEAR_ROWS:
        raise RuntimeError(f"Totais anuais RD divergentes: {dict(years)}")
    if set(norm) != EXPECTED_CODES - EXPECTED_ABSENT_RD:
        raise RuntimeError(f"Domínio RD diferente do C1 observado (26 códigos): {sorted(norm)}")
    if any(v <= 0 for v in norm.values()) or sum(norm.values()) != rows:
        raise RuntimeError("Distribuição RD inválida")
    print("RD_FILES=36")
    print("RD_MONTHS=36")
    print("RD_ROWS=566672")
    print("RD_RAW_DISTINCT=" + str(len(raw)))
    print("RD_NORMALIZED_DISTINCT=" + str(len(norm)))
    print("RD_ABSENT_OFFICIAL_CODES=" + ",".join(sorted(EXPECTED_ABSENT_RD)))
    print("RD_REVOKED_13_17=ABSENT")
    print("RD_CODE_24_ROWS=" + str(norm["24"]))
    print("RD_SOURCE_COUNTS=" + repr(sorted(raw.items())))
    print("RD_NORMALIZED_COUNTS=" + repr(sorted(norm.items())))
    print("RD_YEAR_COUNTS=" + repr(sorted(years.items())))
    print("RD_UNMATCHED=0")


def main() -> int:
    print("MODE=IV_DIM_MOTIVO_SAIDA_READ_ONLY_PREFLIGHT")
    print("OUTPUT_FILES_WRITTEN=0")
    print("QVD_GENERATED=False")
    check_manifest()
    codes = check_reference()
    check_staging()
    check_rd(codes)
    print("SK_RULE_CANDIDATE=Hash128_MOT_AND_COBRANCA_TEXTUAL")
    print("SOURCE_DOMAIN_POLICY=FULL_UPDATED_28_CODES")
    print("HISTORICAL_INDIVIDUAL_VALIDITY=NOT_ESTABLISHED_BY_THIS_TEST")
    print("VERDICT=PASS_MOTIVO_28_CODE_REFERENCE_AND_RD_PREFLIGHT_ONLY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
