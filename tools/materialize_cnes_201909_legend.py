#!/usr/bin/env python3
"""III-C4: materializa legenda CNES datada, nunca vigencia historica presumida.

Fonte: transcricao controlada do Anexo "Tabela de Leitos Setembro/2019"
da Nota Tecnica 32/2019-CGSI/DRAC/SAES/MS. O auditor existente exige
PDF original, CSV oficial transcrito e perfil empirico PB integros.
A legenda e auxiliar; nao classifica retrospectivamente registros LT.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from audit_cnes_nt32_2019_pairs import (
    PDF_SHA,
    REF_SHA,
    REF_SHA_CRLF,
    PROFILE_SHA,
    read_csv,
    run as audit_snapshot,
    verified_bytes,
)

SOURCE_COLS = {
    "codleito", "tp_leito", "nome_cnes", "tipo_cnes", "status", "pdf_page"
}
OUTPUT_COLS = [
    "tp_leito", "codleito", "nome_cnes", "tipo_cnes", "status", "pdf_page",
    "competencia_referencia", "fonte_documento", "uso_permitido",
    "vigencia_historica_verificada",
]
SOURCE_ID = "NT_32_2019_ANEXO_TABELA_LEITOS_SET_2019"
USE_ID = "LEGENDA_DESCRITIVA_DATADA_SEM_JOIN_HISTORICO"
HISTORICAL = "NAO"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_name = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", dir=path.parent, prefix=path.name + ".", suffix=".tmp",
            delete=False,
        ) as handle:
            temp_name = handle.name
            handle.write(data)
        os.replace(temp_name, path)
    finally:
        if temp_name is not None and os.path.exists(temp_name):
            os.unlink(temp_name)


def materialize(pdf: Path, reference: Path, profile: Path, out: Path,
                manifest: Path, audit_out: Path) -> int:
    # O auditor exige todos os 57 pares e 35.518 linhas com correspondencia
    # no retrato 201909. Nunca confunde isso com validade em 36 meses.
    result = audit_snapshot(pdf, reference, profile, audit_out)
    if result != 0:
        raise RuntimeError("Auditoria original NAO PASS; materializacao bloqueada")

    reference_bytes = verified_bytes(
        reference, REF_SHA, allowed_hashes=(REF_SHA_CRLF,)
    )
    rows = read_csv(reference_bytes, SOURCE_COLS)
    if len(rows) != 65:
        raise RuntimeError("Esperadas 65 linhas de referencia 201909")

    output_rows: list[dict[str, str]] = []
    for item in rows:
        output_rows.append({
            "tp_leito": item["tp_leito"],
            "codleito": item["codleito"],
            "nome_cnes": item["nome_cnes"],
            "tipo_cnes": item["tipo_cnes"],
            "status": item["status"],
            "pdf_page": item["pdf_page"],
            "competencia_referencia": "201909",
            "fonte_documento": SOURCE_ID,
            "uso_permitido": USE_ID,
            "vigencia_historica_verificada": HISTORICAL,
        })

    buff = io.StringIO(newline="")
    writer = csv.DictWriter(
        buff, fieldnames=OUTPUT_COLS, delimiter=";", lineterminator="\n"
    )
    writer.writeheader()
    writer.writerows(output_rows)
    csv_bytes = buff.getvalue().encode("utf-8")
    if len({(r["tp_leito"], r["codleito"]) for r in output_rows}) != 65:
        raise RuntimeError("Chaves compostas de referencia duplicadas")

    # Mantem saídas locais ignoradas; escrita so apos validacoes de entrada.
    atomic_write(out, csv_bytes)
    report = {
        "checkpoint": "III-C4_DESCRIPTIVE_201909_LEGEND",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": "MATERIALIZED_LOCAL_NEEDS_QLIK_RELOAD",
        "source_document": SOURCE_ID,
        "source_original_pdf_sha256": PDF_SHA,
        "source_transcription_lf_sha256": REF_SHA,
        "source_profile_sha256": PROFILE_SHA,
        "reference_competence": "201909",
        "rows": 65,
        "distinct_pairs": 65,
        "observed_pb_pairs_covered_by_prior_audit": 57,
        "observed_pb_lt_rows_covered_by_prior_audit": 35518,
        "local_csv_file": str(out),
        "local_csv_sha256": sha256(csv_bytes),
        "audit_report": str(audit_out),
        "meaning": "201909 snapshot label only, not historical lookup",
        "historical_validity_verified": False,
        "t29_historical_approved": False,
        "original_lt_modified": False,
        "qvd_generated_here": False,
    }
    atomic_write(
        manifest,
        (json.dumps(report, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
    )
    print(f"LEGEND_CSV={out}")
    print(f"LEGEND_SHA256={sha256(csv_bytes)}")
    print("LEGEND_ROWS=65 DISTINCT_PAIRS=65")
    print("PB_SNAPSHOT_COVERAGE=57/57 PAIRS; 35518/35518 LT")
    print("REFERENCE_COMPETENCE=201909")
    print("HISTORICAL_VALIDITY=NOT_VERIFIED")
    print("T29_HISTORICAL=NOT_APPROVED")
    print(f"MANIFEST={manifest}")
    print("VERDICT=PASS_MATERIALIZED_DESCRIPTIVE_SNAPSHOT_ONLY")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--pdf", type=Path,
        default=Path("BASE/REFERENCIAS/Nota Técnica  32-2019 Leitos.pdf"),
    )
    parser.add_argument(
        "--referencia", type=Path,
        default=Path("docs/discovery/cnes-nt32-2019-codigos-leito.csv"),
    )
    parser.add_argument(
        "--perfil", type=Path,
        default=Path("BASE/REFERENCIAS/cnes_lt_bed_code_pair_profile.csv"),
    )
    parser.add_argument(
        "--saida", type=Path,
        default=Path("BASE/REFERENCIAS/cnes_leitos_legenda_201909.csv"),
    )
    parser.add_argument(
        "--manifesto", type=Path,
        default=Path("BASE/REFERENCIAS/cnes_leitos_legenda_201909_manifest.json"),
    )
    parser.add_argument(
        "--auditoria", type=Path,
        default=Path("BASE/REFERENCIAS/cnes_nt32_201909_pair_audit.json"),
    )
    args = parser.parse_args()
    try:
        return materialize(
            args.pdf, args.referencia, args.perfil, args.saida,
            args.manifesto, args.auditoria,
        )
    except (RuntimeError, ValueError, OSError, UnicodeError) as exc:
        print(f"MATERIALIZATION_INPUT_ERROR={exc}")
        print("T29_HISTORICAL=NOT_APPROVED")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
