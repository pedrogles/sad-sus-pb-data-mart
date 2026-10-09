#!/usr/bin/env python3
"""IV-TIPO_LEITO — preflight físico de leitura, SEM JOIN histórico.

Confere os 36 CSVs CNES/LT, o snapshot descritivo de set/2019 (65 pares),
QVDs de EXTRAÇÃO somente pelo cabeçalho XML e checkpoint III-C4.3.
Não constrói DIM_TIPO_LEITO, não reclassifica TP_LEITO/CODLEITO e
NÃO demonstra vigência normativa mensal em 2017–2019 (T29 NOT_APPROVED).
"""
from __future__ import annotations

import csv
import hashlib
import json
from collections import Counter
from pathlib import Path

from preflight_dim_diagnostico_cid10 import qvd_header

BASE = Path("BASE/CONVERTIDA/LT")
REF = Path("BASE/REFERENCIAS/cnes_leitos_legenda_201909.csv")
MANIFEST = Path("BASE/REFERENCIAS/cnes_leitos_legenda_201909_manifest.json")
STAGING = Path("EXTRACAO/QVD/SRC_CNES_LT.qvd")
REF_QVD = Path("EXTRACAO/QVD/REF_TIPO_LEITO.qvd")
CHECKPOINT = Path("EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_CNES_LEITO_201909.csv")

EXPECTED_SNAPSHOT_SHA = "dddb261e754f2f3bb82a462c94ae8219b84cd77c1fce3204cd6f3867c3d3bd5e"
EXPECTED_MONTHS = {f"{y}{m:02d}" for y in (2017, 2018, 2019) for m in range(1, 13)}
EXPECTED_SRC_FIELDS = {
    "CNES", "CODUFMUN", "TP_LEITO", "CODLEITO",
    "QT_EXIST", "QT_SUS", "QT_NSUS", "COMPETEN",
}
EXPECTED_REF_FIELDS = [
    "tp_leito", "codleito", "nome_cnes", "tipo_cnes", "status", "pdf_page",
    "competencia_referencia", "fonte_documento", "uso_permitido",
    "vigencia_historica_verificada",
]
EXPECTED_QVD_FIELDS = [
    "REF_LEITO_TP_LEITO", "REF_LEITO_CODLEITO", "REF_LEITO_NOME_CNES",
    "REF_LEITO_TIPO_CNES", "REF_LEITO_STATUS", "REF_LEITO_PDF_PAGE",
    "REF_LEITO_COMPETENCIA_REFERENCIA", "REF_LEITO_FONTE_DOCUMENTO",
    "REF_LEITO_USO_PERMITIDO", "REF_LEITO_VIGENCIA_HISTORICA_VERIFICADA",
    "_META_SOURCE_FILE", "_META_SOURCE_FAMILY", "_META_SOURCE_PATH",
]
EXPECTED_CHECKPOINT = {
    "stage": "EXTRACAO_CNES_LEITO_201909",
    "status": "PASS_PARTIAL_SNAPSHOT_ONLY",
    "reference_pairs": "65",
    "observed_lt_rows": "35518",
    "observed_lt_pairs": "57",
    "observed_lt_competences": "36",
    "unmatched_snapshot_pair_rows": "0",
    "reference_competence": "201909",
    "historical_validity": "NOT_VERIFIED",
    "t29_historical": "NOT_APPROVED",
}
SOURCE_ID = "NT_32_2019_ANEXO_TABELA_LEITOS_SET_2019"
USE_ID = "LEGENDA_DESCRITIVA_DATADA_SEM_JOIN_HISTORICO"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def check_snapshot() -> set[tuple[str, str]]:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    observed_sha = sha256(REF)
    if (
        observed_sha != EXPECTED_SNAPSHOT_SHA
        or manifest.get("local_csv_sha256") != observed_sha
        or manifest.get("reference_competence") != "201909"
        or manifest.get("rows") != 65
        or manifest.get("distinct_pairs") != 65
        or manifest.get("historical_validity_verified") is not False
        or manifest.get("t29_historical_approved") is not False
    ):
        raise RuntimeError("Manifesto/snapshot CNES 201909 não reconciliado ou alegação histórica inválida")

    with REF.open("r", encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh, delimiter=";")
        if reader.fieldnames != EXPECTED_REF_FIELDS:
            raise RuntimeError(f"Schema da legenda 201909 divergiu: {reader.fieldnames}")
        lines = list(reader)

    if len(lines) != 65:
        raise RuntimeError("A legenda CNES set/2019 exige 65 pares")
    pairs: set[tuple[str, str]] = set()
    for n, rec in enumerate(lines, 2):
        if None in rec or any(v is None for v in rec.values()):
            raise RuntimeError(f"Legenda malformada linha {n}")
        typ, bed = rec["tp_leito"], rec["codleito"]
        key = (typ, bed)
        if (
            key in pairs or typ not in "1234567" or len(typ) != 1
            or len(bed) != 2 or not bed.isascii() or not bed.isdecimal()
            or not rec["nome_cnes"].strip() or not rec["tipo_cnes"].strip()
            or rec["competencia_referencia"] != "201909"
            or rec["fonte_documento"] != SOURCE_ID
            or rec["uso_permitido"] != USE_ID
            or rec["vigencia_historica_verificada"] != "NAO"
            or rec["status"] != "Ativo"
        ):
            raise RuntimeError(f"Chave/campo/limite temporal inválido em legenda: linha {n}: {key}")
        pairs.add(key)

    if len(pairs) != 65 or ("3", "66") not in pairs:
        raise RuntimeError("Legenda incompleta ou falta o par PB 3/66")
    print("SNAPSHOT_201909_SHA256=" + observed_sha)
    print("SNAPSHOT_PAIRS=65")
    print("SNAPSHOT_REFERENCE_COMPETENCE=201909")
    print("SNAPSHOT_HISTORICAL_VALIDITY=NOT_VERIFIED")
    return pairs


def check_qvd_and_checkpoint() -> None:
    rows, fields = qvd_header(STAGING)
    if rows != 35518 or not EXPECTED_SRC_FIELDS.issubset(fields):
        raise RuntimeError(f"QVD SRC_CNES_LT divergente: {rows} / {fields}")
    ref_rows, ref_fields = qvd_header(REF_QVD)
    if ref_rows != 65 or ref_fields != EXPECTED_QVD_FIELDS:
        raise RuntimeError(f"QVD REF_TIPO_LEITO divergente: {ref_rows} / {ref_fields}")

    with CHECKPOINT.open("r", encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh, delimiter=";")
        entries = list(reader)
        if len(entries) != 1 or None in entries[0] or any(v is None for v in entries[0].values()):
            raise RuntimeError("Checkpoint III-C4.3 malformado")
        for field, expected in EXPECTED_CHECKPOINT.items():
            if entries[0].get(field) != expected:
                raise RuntimeError(f"Checkpoint C4.3 divergiu em {field}: {entries[0].get(field)!r}")

    print("LT_STAGING_QVD_ROWS=35518")
    print("SNAPSHOT_QVD_ROWS=65")
    print("SNAPSHOT_QVD_FIELDS=13")
    print("CHECKPOINT_C4_3=PASS_PARTIAL_SNAPSHOT_ONLY")


def check_lt(snapshot_pairs: set[tuple[str, str]]) -> None:
    paths = sorted(BASE.glob("LTPB*.csv"))
    months: set[str] = set()
    pair_counts: Counter[tuple[str, str]] = Counter()
    types: Counter[str] = Counter()
    per_year: Counter[str] = Counter()
    records = 0
    unmatched = 0
    for path in paths:
        stem = path.stem
        if len(stem) != 8 or not stem.startswith("LTPB") or not stem[4:].isascii() or not stem[4:].isdecimal():
            raise RuntimeError(f"Arquivo LT inesperado: {path}")
        month = "20" + stem[4:]
        if month not in EXPECTED_MONTHS or month in months:
            raise RuntimeError(f"Competência LT inválida/duplicada: {path}")
        months.add(month)
        monthly_count = 0
        with path.open("r", newline="", encoding="utf-8-sig") as fh:
            reader = csv.DictReader(fh, delimiter=";")
            if not reader.fieldnames or not EXPECTED_SRC_FIELDS.issubset(reader.fieldnames):
                raise RuntimeError(f"Campos LT incompletos: {path}")
            for n, rec in enumerate(reader, 2):
                if None in rec or any(v is None for v in rec.values()):
                    raise RuntimeError(f"LT malformado: {path}:{n}")
                raw_tp, bed = rec["TP_LEITO"], rec["CODLEITO"]
                comp = rec["COMPETEN"]
                if (
                    len(raw_tp) != 2 or raw_tp[0] not in "1234567" or raw_tp[1] != " "
                    or len(bed) != 2 or not bed.isascii() or not bed.isdecimal()
                    or comp != month
                ):
                    raise RuntimeError(f"Dados LT TP/COD/COMPETEN inválidos: {path}:{n} {raw_tp!r}/{bed!r}/{comp!r}")
                key = (raw_tp[0], bed)
                if key not in snapshot_pairs:
                    unmatched += 1
                pair_counts[key] += 1
                types[raw_tp] += 1
                per_year[month[:4]] += 1
                records += 1
                monthly_count += 1
        if not monthly_count:
            raise RuntimeError(f"LT vazio: {month}")

    if months != EXPECTED_MONTHS or records != 35518 or len(pair_counts) != 57 or unmatched:
        raise RuntimeError(f"Perfil LT divergiu: months={len(months)}, rows={records}, pairs={len(pair_counts)}, unmatched={unmatched}")
    if ("3", "66") not in pair_counts:
        raise RuntimeError("Par PB 3/66 esperado não observado")

    print("LT_FILES=36")
    print("LT_COMPETENCES=36")
    print("LT_ROWS=35518")
    print("LT_TYPES_RAW_DISTINCT=" + str(len(types)))
    print("LT_PAIRS_OBSERVED=57")
    print("LT_PAIRS_MATCHING_201909_SNAPSHOT=57")
    print("LT_ROWS_MATCHING_201909_SNAPSHOT=35518")
    print("LT_UNMATCHED_SNAPSHOT_PAIRS=0")
    print("LT_RAW_TP_VALUES=" + repr(sorted(types)))
    print("LT_YEAR_ROWS=" + repr(sorted(per_year.items())))
    print("LT_PB_PAIR_3_66_ROWS=" + str(pair_counts[("3", "66")]))
    print("SOURCE_TP_LEITO_TRAILING_ASCII_SPACE=PRESERVED")


def main() -> int:
    print("MODE=IV_DIM_TIPO_LEITO_READ_ONLY_TECHNICAL_PREFLIGHT")
    print("OUTPUT_FILES_WRITTEN=0")
    print("DIM_TIPO_LEITO_QVD_GENERATED=False")
    snapshot = check_snapshot()
    check_qvd_and_checkpoint()
    check_lt(snapshot)
    print("SOURCE_PAIR_COVERAGE_VS_201909_SNAPSHOT=PASS_DESCRIPTIVE_ONLY")
    print("HISTORICAL_LABEL_JOIN_PERFORMED=False")
    print("HISTORICAL_MONTHLY_VALIDITY=NOT_VERIFIED")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("VERDICT=PASS_LT_SNAPSHOT_TECHNICAL_PREFLIGHT_ONLY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
