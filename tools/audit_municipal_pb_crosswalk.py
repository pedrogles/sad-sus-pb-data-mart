#!/usr/bin/env python3
"""Audita a referencia municipal PB derivada na etapa III-C5.2.

Nao gera municipio, nao complementa digito IBGE e nao modifica fontes.
Confere 223 pares IBGE7 oficiais/DATASUS6 validados pelo QlikView 12,
checkpoint da extracao, metadata de origem, QVD e SHA-256 dos tres XLS IBGE.
A referencia NAO constitui dataset externo de equivalencia oficialmente
publicado e NAO relaciona a residencia externa a populacao da PB.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import re
import tempfile
from datetime import datetime, timezone
from pathlib import Path

SOURCE_FILES = (
    "estimativa_dou_2017.xls",
    "estimativa_dou_2018_20181019.xls",
    "estimativa_dou_2019.xls",
)
COLUMNS = {
    "COD_DATASUS_6",
    "COD_IBGE_7",
    "UF",
    "FONTE_IBGE",
    "ANOS_FONTE_IBGE",
    "NATUREZA_REFERENCIA",
    "METODO_CORRESPONDENCIA",
}
META_EXPECTED = {
    "UF": "PB",
    "FONTE_IBGE": "IBGE_ESTIMATIVAS_MUNICIPAIS_2017_2019",
    "ANOS_FONTE_IBGE": "2017,2018,2019",
    "NATUREZA_REFERENCIA": "DERIVADA_PROJETO_DADOS_OFICIAIS_IBGE",
    "METODO_CORRESPONDENCIA": "PREFIXO_IBGE7_6_VALIDADO_NO_PB",
}
CHECKPOINT = {
    "stage": "EXTRACAO_C5_2_MUNICIPIO_PB",
    "status": "PASS_PARTIAL_REFERENCE_PB_ONLY",
    "ibge_source_rows": "669",
    "bridge_pairs": "223",
    "distinct_datasus6": "223",
    "distinct_ibge7": "223",
    "invalid_pair_rows": "0",
    "st_unmatched_rows": "0",
    "lt_unmatched_rows": "0",
    "rd_attendance_unmatched_rows": "0",
    "rd_residence_pb_unmatched_rows": "0",
    "rd_residence_outside_pb_rows": "5202",
    "reference_nature": "DERIVED_PB_REFERENCE_NOT_OFFICIAL_STANDALONE_TABLE",
    "phase_iii_status": "IN_PROGRESS",
}
PRECHECK = {
    "stage": "EXTRACAO_C5_MUNICIPAL_PREFLIGHT",
    "status": "PASS_CANDIDATE_MAPPING_ONLY",
    "ibge_pb_official_codes7": "223",
    "unique_code6_candidates": "223",
    "st_distinct_codes6": "223",
    "st_unmatched_rows": "0",
    "lt_unmatched_rows": "0",
    "rd_attendance_unmatched_rows": "0",
    "rd_residence_pb_unmatched_rows": "0",
    "rd_residence_outside_pb_rows": "5202",
    "official_bridge_status": "NOT_YET_MATERIALIZED",
}


def digest(path: Path) -> str:
    if not path.is_file():
        raise ValueError(f"Arquivo exigido ausente: {path}")
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def rows_from_csv(path: Path, required_columns: set[str] | None = None) -> list[dict[str, str]]:
    if not path.is_file():
        raise ValueError(f"CSV exigido ausente: {path}")
    raw = path.read_bytes()
    data = raw.decode("utf-8-sig")
    r = csv.DictReader(io.StringIO(data, newline=""), delimiter=";")
    if not r.fieldnames:
        raise ValueError(f"Cabecalho CSV vazio: {path}")
    if required_columns is not None and set(r.fieldnames) != required_columns:
        raise ValueError(f"Cabecalho CSV divergente em {path}: {r.fieldnames}")
    rows = list(r)
    if not rows or any(None in row or any(v is None for v in row.values()) for row in rows):
        raise ValueError(f"CSV vazio ou irregular: {path}")
    return rows


def check_single_checkpoint(path: Path, expected: dict[str, str]) -> dict[str, str]:
    rows = rows_from_csv(path)
    if len(rows) != 1:
        raise ValueError(f"Checkpoint deve conter uma linha: {path}")
    row = rows[0]
    for name, value in expected.items():
        if row.get(name) != value:
            raise ValueError(
                f"Checkpoint {path} divergente: {name}, "
                f"esperado={value!r}, encontrado={row.get(name)!r}"
            )
    if not row.get("generated_at"):
        raise ValueError(f"Checkpoint sem data de geracao: {path}")
    return row


def validate_pairs(rows: list[dict[str, str]]) -> None:
    if len(rows) != 223:
        raise ValueError(f"Esperados 223 pares, encontrados {len(rows)}")
    d6: set[str] = set()
    i7: set[str] = set()
    for index, row in enumerate(rows, start=2):
        code6, code7 = row["COD_DATASUS_6"], row["COD_IBGE_7"]
        if not re.fullmatch(r"25[0-9]{4}", code6):
            raise ValueError(f"Codigo DATASUS6 invalido na linha {index}: {code6!r}")
        if not re.fullmatch(r"25[0-9]{5}", code7):
            raise ValueError(f"Codigo IBGE7 invalido na linha {index}: {code7!r}")
        if code7[:6] != code6:
            raise ValueError(f"Par divergente na linha {index}: {code6!r} x {code7!r}")
        for key, expected in META_EXPECTED.items():
            if row[key] != expected:
                raise ValueError(f"Metadado divergente {key} na linha {index}: {row[key]!r}")
        if code6 in d6 or code7 in i7:
            raise ValueError(f"Par duplicado ou colidido na linha {index}: {code6}/{code7}")
        d6.add(code6)
        i7.add(code7)
    if len(d6) != 223 or len(i7) != 223:
        raise ValueError("Unicidade DATASUS6/IBGE7 insuficiente")


def write_atomic(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", dir=path.parent, prefix=path.name + ".",
            suffix=".tmp", delete=False
        ) as f:
            temp = f.name
            f.write(content)
        os.replace(temp, path)
    finally:
        if temp is not None and os.path.exists(temp):
            os.unlink(temp)


def audit(args: argparse.Namespace) -> int:
    ref_rows = rows_from_csv(args.csv, COLUMNS)
    validate_pairs(ref_rows)
    chk = check_single_checkpoint(args.checkpoint, CHECKPOINT)
    pre = check_single_checkpoint(args.preflight, PRECHECK)

    qvd_sha = digest(args.qvd)
    ibge_qvd_sha = digest(args.ibge_qvd)
    source_files = []
    for name in SOURCE_FILES:
        path = args.source_dir / name
        source_files.append({
            "file": name,
            "path": str(path),
            "sha256": digest(path),
        })
    inputs = [
        ("derived_csv", args.csv),
        ("derived_qvd", args.qvd),
        ("ibge_staging_qvd", args.ibge_qvd),
        ("c5_2_checkpoint", args.checkpoint),
        ("c5_1_preflight", args.preflight),
    ]
    sha_files = {name: {"path": str(path), "sha256": digest(path)} for name, path in inputs}

    # Detectar checkpoints inconsistentes com a ordem declarada do pipeline.
    # Timestamp de armazenamento do arquivo no sistema local, nao "prova" de dado historico.
    if args.checkpoint.stat().st_mtime + 2 < args.qvd.stat().st_mtime:
        raise ValueError("Checkpoint C5.2 parece anterior ao QVD derivado")

    manifest = {
        "checkpoint": "III-C5.2_MUNICIPAL_PB",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": "PASS_LOCAL_REFERENCE_AUDIT",
        "reference_nature": "DERIVED_PB_REFERENCE_NOT_OFFICIAL_STANDALONE_TABLE",
        "source_description": "IBGE XLS estimativas municipais 2017, 2018 e 2019",
        "source_xls": source_files,
        "files": sha_files,
        "pairs": 223,
        "distinct_datasus6": 223,
        "distinct_ibge7": 223,
        "ibge_staging_source_rows": 669,
        "reference_consistency": "COD_IBGE_7 official source, DATASUS6 tested prefix",
        "coverage_unmatched_pb": 0,
        "rd_residence_outside_pb_unmapped": 5202,
        "reference_full_brazil_coverage": False,
        "source_qvd_not_modified_here": True,
        "dimensional_model_created": False,
        "historical_cnes_t29_approved": False,
        "phase_iii_closed": False,
        "local_checkpoint_generated_at": chk["generated_at"],
        "local_preflight_generated_at": pre["generated_at"],
    }
    write_atomic(
        args.manifest,
        (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
    )

    print("IBGE_OFFICIAL_XLS=3 HASHED")
    print(f"IBGE_STAGING_QVD_SHA256={ibge_qvd_sha}")
    print(f"DERIVED_QVD_SHA256={qvd_sha}")
    print(f"DERIVED_CSV_SHA256={sha_files['derived_csv']['sha256']}")
    print("CROSSWALK_PAIRS=223 DISTINCT_DATASUS6=223 DISTINCT_IBGE7=223")
    print("PB_UNMATCHED=0 RD_RESIDENCE_EXTERNAL_PRESERVED=5202")
    print("REFERENCE_NATURE=DERIVED_FROM_OFFICIAL_IBGE_SOURCE_NOT_EXTERNAL_STANDALONE")
    print("PHASE_III=IN_PROGRESS T29_HISTORICAL=NOT_APPROVED")
    print(f"MANIFEST={args.manifest}")
    print("VERDICT=PASS_LOCAL_REFERENCE_AUDIT")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--csv", type=Path, default=Path("EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.csv"))
    p.add_argument("--qvd", type=Path, default=Path("EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.qvd"))
    p.add_argument("--ibge-qvd", type=Path, default=Path("EXTRACAO/QVD/SRC_IBGE_POPULACAO.qvd"))
    p.add_argument("--checkpoint", type=Path, default=Path("EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_C5_2_MUNICIPIO_PB.csv"))
    p.add_argument("--preflight", type=Path, default=Path("EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_MUNICIPAL_PREFLIGHT.csv"))
    p.add_argument("--source-dir", type=Path, default=Path("BASE/IBGE"))
    p.add_argument("--manifest", type=Path, default=Path("BASE/REFERENCIAS/c5_2_municipio_pb_manifest.json"))
    args = p.parse_args()
    try:
        return audit(args)
    except (ValueError, OSError, UnicodeError, csv.Error) as exc:
        print(f"AUDIT_ERROR={exc}")
        print("VERDICT=REVIEW_REQUIRED")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
