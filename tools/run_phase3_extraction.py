#!/usr/bin/env python3
"""Executa somente a extracao QlikView 12 com marcador fresco e auditoria SHA.

Contrato Boundary 7: apaga apenas _SUCCESS_EXTRACAO.csv antigo antes do
reload; nao considera exit code 0 como PASS. Valida marcador e QVDs novos.
Nao executa Transformacao/PAINEL, nao altera QVDs manualmente.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXTRACTION = ROOT / "EXTRACAO"
QVD_DIR = EXTRACTION / "QVD"
MARKER = QVD_DIR / "_SUCCESS_EXTRACAO.csv"
MANIFEST = ROOT / "BASE" / "REFERENCIAS" / "phase3_extraction_final_manifest.json"

EXPECTED_QVDS = {
    "SRC_SIH_RD.qvd": 566672,
    "SRC_CNES_LT.qvd": 35518,
    "SRC_CNES_ST.qvd": 220390,
    "SRC_IBGE_POPULACAO.qvd": 669,
    "REF_CARATER_ATENDIMENTO.qvd": 6,
    "REF_MOTIVO_SAIDA.qvd": 28,
    "REF_CID10.qvd": 14230,
    "REF_SIGTAP.qvd": 165203,
    "REF_TIPO_LEITO.qvd": 65,
    "REF_MUNICIPIO_PB_DERIVADA.qvd": 223,
}
EXPECTED_MARKER = {
    "stage": "EXTRACAO",
    "status": "PASS_FINAL_RECONCILED",
    "pipeline_version": "PHASE_III_V1_2017_2019",
    "qvd_count": "10",
    "required_fields_verified": "107",
    "t07_families": "3",
    "t07_competences_per_family": "36",
    "t08_required_fields": "PASS",
    "rd_rows": "566672",
    "lt_rows": "35518",
    "st_rows": "220390",
    "ibge_rows": "669",
    "carater_reference_rows": "6",
    "motivo_reference_rows": "28",
    "cid10_reference_rows": "14230",
    "sigtap_reference_rows": "165203",
    "cnes_leito_snapshot_reference_rows": "65",
    "municipal_pb_derived_reference_rows": "223",
    "rd_residence_external_rows": "5202",
    "leito_reference_scope": "201909_SNAPSHOT_ONLY",
    "t29_historical_validity": "NOT_APPROVED",
    "municipality_reference_nature": "NOT_A_STANDALONE_OFFICIAL_BRIDGE",
    "establishment_historical_name_policy": "BOUNDARY5_NULL_NOT_RETROFILL",
    "dimensional_transformation": "NOT_STARTED",
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def fresh_file(path: Path, started_timestamp: float) -> None:
    if not path.is_file() or path.stat().st_size == 0:
        raise ValueError(f"Arquivo ausente/vazio apos reload: {path}")
    if path.stat().st_mtime < started_timestamp - 2:
        raise ValueError(f"Arquivo anterior a este reload: {path}")


def read_marker() -> dict[str, str]:
    with MARKER.open("r", encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source, delimiter=";")
        actual = list(reader)
    if len(actual) != 1 or any(v is None for v in actual[0].values()):
        raise ValueError("Marcador deve conter exatamente uma linha sem campos faltantes")
    return actual[0]


def verify(started_timestamp: float, started_utc: str) -> None:
    fresh_file(MARKER, started_timestamp)
    marker = read_marker()
    for key, expected in EXPECTED_MARKER.items():
        if marker.get(key) != expected:
            raise ValueError(
                f"Marcador invalido: {key} esperado={expected!r} atual={marker.get(key)!r}"
            )
    if not marker.get("generated_at"):
        raise ValueError("Marcador sem timestamp")
    if marker.get("phase_iii_status") == "IN_PROGRESS":
        raise ValueError("Marcador final nao deve usar status parcial")

    qvds = []
    for name, expected_records in EXPECTED_QVDS.items():
        path = QVD_DIR / name
        fresh_file(path, started_timestamp)
        qvds.append({
            "file": name,
            "expected_records_verified_by_qv_script": expected_records,
            "sha256": sha256_file(path),
            "bytes": path.stat().st_size,
            "mtime_utc": datetime.fromtimestamp(
                path.stat().st_mtime, tz=timezone.utc
            ).isoformat(),
        })

    # QVDs sao auditados por QvdNoOfRecords/QvdFieldName dentro do QlikView,
    # nao por parser de QVD inventado em Python. Hash confirma bytes fisicos.
    report = {
        "checkpoint": "PHASE_III_EXTRACTION_FINAL",
        "status": "PASS_LOCAL_QV_AND_SHA_RECONCILIATION",
        "pipeline": "EXTRACAO_ONLY",
        "reload_started_utc": started_utc,
        "audited_at_utc": datetime.now(timezone.utc).isoformat(),
        "success_marker": {
            "file": str(MARKER.relative_to(ROOT)),
            "sha256": sha256_file(MARKER),
            "content": marker,
        },
        "qvds": qvds,
        "qvd_count": len(qvds),
        "t07": "PASS_3_FAMILIES_36_MONTHS",
        "t08": "PASS_107_REQUIRED_FIELDS",
        "leito_cnes_historical_validity": "NOT_APPROVED",
        "cnes_leito_snapshot_scope": "201909_ONLY",
        "municipality_reference": "DERIVED_PB_ONLY",
        "rd_external_residence_records": 5202,
        "historical_establishment_names": "NO_BACKFILL_AS_BOUNDARY5",
        "transformation_started": False,
    }

    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    temp = MANIFEST.with_suffix(".json.tmp")
    try:
        temp.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        os.replace(temp, MANIFEST)
    finally:
        if temp.exists():
            temp.unlink()

    print("QVD_COUNT=10 FRESH_QVD_FILES=10")
    print("T07=PASS_3_FAMILIES_36_MONTHS")
    print("T08=PASS_107_REQUIRED_FIELDS")
    print("RD=566672 LT=35518 ST=220390 IBGE=669")
    print("PB_MUNICIPAL_REFERENCE=223 RD_EXTERNAL_RESIDENCES=5202")
    print("T29_HISTORICAL=NOT_APPROVED")
    print("TRANSFORMATION=NOT_STARTED")
    print(f"SUCCESS_MARKER_SHA256={sha256_file(MARKER)}")
    print(f"MANIFEST={MANIFEST}")
    print("VERDICT=PASS_LOCAL_QV_AND_SHA_RECONCILIATION")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--qlikview-exe", type=Path,
        default=Path(os.environ["QLIKVIEW_EXE"]) if os.environ.get("QLIKVIEW_EXE") else None,
        help="Caminho local de Qv.exe ou variavel QLIKVIEW_EXE",
    )
    parser.add_argument(
        "--timeout-seconds", type=int, default=2400,
        help="Tempo maximo do reload QlikView (padrao: 2400s)",
    )
    args = parser.parse_args()
    if args.qlikview_exe is None:
        print("ERROR=Informe --qlikview-exe ou defina QLIKVIEW_EXE")
        return 2
    if not args.qlikview_exe.is_file():
        print(f"ERROR=QlikView nao localizado: {args.qlikview_exe}")
        return 2
    qvw = EXTRACTION / "EXT.qvw"
    if not qvw.is_file():
        print(f"ERROR=Documento QVW nao localizado: {qvw}")
        return 2
    if args.timeout_seconds < 60:
        print("ERROR=Timeout menor que 60 segundos")
        return 2

    # Remove somente os artefatos finais de sucesso ANTES de tentar reload.
    # Artefatos parciais/QVDs antigos ficam intactos para diagnostico.
    MARKER.unlink(missing_ok=True)
    MANIFEST.unlink(missing_ok=True)
    started = datetime.now(timezone.utc)
    print(f"RELOAD_STARTED_UTC={started.isoformat()}")
    print("OLD_SUCCESS_MARKER=INVALIDATED")
    print("QLIK_RELOAD_STAGE=EXTRACAO_ONLY")
    sys.stdout.flush()
    try:
        process = subprocess.run(
            [str(args.qlikview_exe), "/r", str(qvw)],
            cwd=str(EXTRACTION),
            timeout=args.timeout_seconds,
            check=False,
        )
        if process.returncode != 0:
            raise ValueError(f"QlikView retornou codigo de erro {process.returncode}")
        verify(started.timestamp(), started.isoformat())
        return 0
    except (ValueError, OSError, UnicodeError, csv.Error, subprocess.TimeoutExpired) as exc:
        # Nunca deixar marcador de sucesso com auditoria externa falha.
        MARKER.unlink(missing_ok=True)
        MANIFEST.unlink(missing_ok=True)
        print(f"VERDICT=FAIL_CLOSED ERROR={exc}")
        print("PHASE_III=IN_PROGRESS")
        return 3


if __name__ == "__main__":
    raise SystemExit(main())
