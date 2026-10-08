#!/usr/bin/env python3
"""III-C3.3b.1: materializa a referência SIGTAP histórica de procedimentos.

Usa os quatro meses já verificados no C3.3a e baixa SOMENTE os 32 ZIPs
restantes, enumerados no inventário C2.3 oficial. Materializa exclusivamente
tb_procedimento.txt e tb_procedimento_layout.txt de cada ZIP.

Valida formato físico, competência interna, integridade dos códigos, hashes
de proveniência e estabilidade do layout. Não faz lookup RD/T27, QVD ou
modelagem dimensional. Saídas em BASE/REFERENCIAS (ignoradas pelo Git).
"""

from __future__ import annotations

import argparse
import csv
import ftplib
import hashlib
import json
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from inspect_sigtap_procedure_sample import (
    FTP_DIRECTORY,
    FTP_HOST,
    INVENTORY,
    read_inventory,
    receive_zip,
    sha256_file,
)
from materialize_sigtap_procedure_sample import (
    EXPECTED_FILES,
    OUTPUT_ROOT,
    parse_layout,
    inspect_lines,
    find_exact_member,
)

ROOT = Path("BASE/REFERENCIAS")
SAMPLE_MANIFEST = ROOT / "sigtap_procedure_sample_manifest.json"
PILOT_SUMMARY = ROOT / "sigtap_procedure_pilot_summary.json"
RD_PROFILE = ROOT / "proc_rea_profile_summary.json"
HISTORY_MANIFEST = ROOT / "sigtap_procedure_history_manifest.json"
HISTORY_INVENTORY = ROOT / "sigtap_procedure_history_inventory.csv"
SAMPLE_MONTHS = ("201701", "201801", "201901", "201912")
COMPETENCES = tuple(
    f"{year}{month:02d}"
    for year in (2017, 2018, 2019)
    for month in range(1, 13)
)


def read_json(path: Path) -> dict:
    if not path.is_file():
        raise RuntimeError(f"Manifesto anterior ausente: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def validate_previous_gates() -> tuple[dict[str, dict], str, list[dict]]:
    sample = read_json(SAMPLE_MANIFEST)
    pilot = read_json(PILOT_SUMMARY)
    rd_profile = read_json(RD_PROFILE)
    if (
        sample.get("status") != "PASS"
        or sample.get("stage") != "PHASE_III_C3_3A_PROCEDURE_SAMPLE_LAYOUT_INSPECTION"
        or sorted(sample.get("selection", [])) != sorted(SAMPLE_MONTHS)
    ):
        raise RuntimeError("C3.3a não está comprovado para os quatro meses")
    if (
        pilot.get("status") != "PASS"
        or pilot.get("stage") != "PHASE_III_C3_3A1_PROCEDURE_FOUR_MONTH_COVERAGE_PILOT"
        or sorted(pilot.get("sample_competences", [])) != sorted(SAMPLE_MONTHS)
        or pilot.get("totals", {}).get("rd_rows") != 59365
        or pilot.get("totals", {}).get("unmatched_rd_rows") != 0
        or pilot.get("totals", {}).get("matched_rd_rows") != 59365
    ):
        raise RuntimeError("C3.3a.1 piloto não comprovado como PASS")
    if (
        rd_profile.get("status") != "PASS"
        or rd_profile.get("input", {}).get("rows") != 566672
        or rd_profile.get("input", {}).get("files") != 36
        or rd_profile.get("input", {}).get("competences") != 36
    ):
        raise RuntimeError("C3.1 perfil RD não comprovado como PASS")

    # Confere evidência do piloto antes de iniciar aquisição histórica.
    for name in ("coverage", "unmatched"):
        item = pilot.get("outputs", {}).get(name)
        if not item or sha256_file(Path(item["path"])) != item["sha256"]:
            raise RuntimeError(f"Saída do piloto alterada ou ausente: {name}")

    grouped: dict[str, list[dict]] = {}
    for row in sample.get("materialized", []):
        grouped.setdefault(row["competence"], []).append(row)
    by_month: dict[str, dict] = {}
    hashes: set[str] = set()
    fields: list[dict] | None = None
    for competence in SAMPLE_MONTHS:
        candidates = grouped.get(competence, [])
        if len(candidates) != 1:
            raise RuntimeError(f"C3.3a ambíguo em {competence}")
        record = candidates[0]
        layout_path = OUTPUT_ROOT / competence / "tb_procedimento_layout.txt"
        procedure_path = OUTPUT_ROOT / competence / "tb_procedimento.txt"
        for filename, path in (
            ("tb_procedimento_layout.txt", layout_path),
            ("tb_procedimento.txt", procedure_path),
        ):
            expected = record["files"][filename]["sha256"]
            if not path.is_file() or sha256_file(path) != expected:
                raise RuntimeError(
                    f"TXT da amostra ausente/divergente: {competence}/{filename}"
                )
        columns = parse_layout(layout_path.read_bytes(), competence)
        normalized = [
            (c["field"], c["width"], c["start"], c["end"], c["type"])
            for c in columns
        ]
        if fields is None:
            fields = normalized
        elif fields != normalized:
            raise RuntimeError(f"Layout de campos mudou dentro da amostra: {competence}")
        hashes.add(sha256_file(layout_path))
        by_month[competence] = record

    if len(hashes) != 1 or fields is None or len(fields) != 16 or fields[-1][3] != 330:
        raise RuntimeError("Layout de referência C3.3a inconsistente com a amostra")
    return by_month, next(iter(hashes)), fields


def verify_table(
    competence: str, layout_bytes: bytes, data_bytes: bytes,
    expected_hash: str, expected_fields: list[tuple],
) -> dict:
    if hashlib.sha256(layout_bytes).hexdigest() != expected_hash:
        raise RuntimeError(
            f"Layout SIGTAP mudou em {competence}; parar e inspecionar mudança oficial"
        )
    fields = parse_layout(layout_bytes, competence)
    signature = [
        (x["field"], x["width"], x["start"], x["end"], x["type"])
        for x in fields
    ]
    if signature != expected_fields:
        raise RuntimeError(f"Campos SIGTAP diferentes da amostra em {competence}")
    status = inspect_lines(data_bytes, fields)
    if (
        status["rows"] <= 0
        or status["invalid_key_rows"] != 0
        or status["line_length_mismatch_rows"] != 0
        or status["duplicate_key_count"] != 0
        or status["rows"] != status["distinct_raw_keys"]
    ):
        raise RuntimeError(f"Falha de integridade física em {competence}: {status}")

    dt = [x for x in fields if x["field"] == "DT_COMPETENCIA"]
    if len(dt) != 1 or dt[0]["width"] != 6:
        raise RuntimeError(f"DT_COMPETENCIA não confirmado em {competence}")
    offset, end = int(dt[0]["start"]) - 1, int(dt[0]["end"])
    mismatch = sum(
        1 for line in data_bytes.splitlines()
        if line[offset:end] != competence.encode("ascii")
    )
    if mismatch != 0:
        raise RuntimeError(
            f"DT_COMPETENCIA divergente de {competence}: {mismatch} linhas"
        )
    status["wrong_competence_rows"] = mismatch
    return status


def safe_materialize(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        if path.read_bytes() != data:
            raise RuntimeError(
                f"Arquivo local existente diverge do pacote oficial: {path}"
            )
        return
    path.write_bytes(data)


def write_inventory(rows: list[dict]) -> None:
    fields = [
        "competence", "source_kind", "package_filename", "package_sha256",
        "package_size_bytes", "layout_sha256", "procedure_sha256",
        "procedure_rows", "distinct_procedures", "layout_width",
        "invalid_key_rows", "invalid_length_rows", "duplicate_keys",
        "wrong_competence_rows",
    ]
    with HISTORY_INVENTORY.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=fields, delimiter=";", lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()

    sample, layout_hash, field_signature = validate_previous_gates()
    inventory = read_inventory(INVENTORY, COMPETENCES)
    if len(inventory) != len(COMPETENCES):
        raise RuntimeError("Inventário SIGTAP não cobre 36 competências únicas")

    records: list[dict] = []
    summary_rows: list[dict] = []
    downloads = 0
    reused = 0
    print("MODE=CONTROLLED_36_MONTH_SIGTAP_PROCEDURE_ACQUISITION")
    print("SAMPLE_MONTHS_REUSED=" + ",".join(SAMPLE_MONTHS))
    print("REFERENCE_LAYOUT_SHA256=" + layout_hash)
    print("T27_COVERAGE=NOT_EVALUATED")

    # Uma única sessão FTP para os 32 meses não presentes na amostra.
    with ftplib.FTP(timeout=args.timeout) as ftp:
        ftp.connect(FTP_HOST)
        ftp.login()
        ftp.cwd(FTP_DIRECTORY)
        for competence in COMPETENCES:
            package = inventory[competence]
            name = package["filename"]
            if competence in sample:
                evidence = sample[competence]
                if name != evidence["package_filename"]:
                    raise RuntimeError(f"Pacote da amostra diverge do inventário: {competence}")
                layout_path = OUTPUT_ROOT / competence / "tb_procedimento_layout.txt"
                data_path = OUTPUT_ROOT / competence / "tb_procedimento.txt"
                layout_bytes = layout_path.read_bytes()
                data_bytes = data_path.read_bytes()
                zip_sha = evidence["package_sha256"]
                zip_size = int(evidence["package_size_bytes"])
                source = "REUSED_VALIDATED_SAMPLE"
                reused += 1
            else:
                print(f"[{competence}] DOWNLOAD={name}")
                with tempfile.TemporaryDirectory(
                    prefix=f"sigtap_history_{competence}_"
                ) as directory:
                    zip_path = Path(directory) / name
                    received = receive_zip(ftp, name, zip_path)
                    zip_sha = sha256_file(zip_path)
                    zip_size = received
                    reported_size = package.get("size_bytes", "")
                    if reported_size.isdecimal() and received != int(reported_size):
                        raise RuntimeError(
                            f"Tamanho ZIP mudou face ao inventário: {competence}"
                        )
                    with zipfile.ZipFile(zip_path, "r") as archive:
                        bad = archive.testzip()
                        if bad is not None:
                            raise RuntimeError(f"ZIP corrompido: {competence}/{bad}")
                        layout_bytes = archive.read(
                            find_exact_member(archive, "tb_procedimento_layout.txt")
                        )
                        data_bytes = archive.read(
                            find_exact_member(archive, "tb_procedimento.txt")
                        )
                source = "DOWNLOADED_NEW"
                downloads += 1

            status = verify_table(
                competence, layout_bytes, data_bytes,
                layout_hash, field_signature
            )
            layout_path = OUTPUT_ROOT / competence / "tb_procedimento_layout.txt"
            data_path = OUTPUT_ROOT / competence / "tb_procedimento.txt"
            if competence not in sample:
                safe_materialize(layout_path, layout_bytes)
                safe_materialize(data_path, data_bytes)

            record = {
                "competence": competence,
                "source_kind": source,
                "package_filename": name,
                "package_sha256": zip_sha,
                "package_size_bytes": zip_size,
                "layout_sha256": hashlib.sha256(layout_bytes).hexdigest(),
                "procedure_sha256": hashlib.sha256(data_bytes).hexdigest(),
                "procedure_rows": status["rows"],
                "distinct_procedures": status["distinct_raw_keys"],
                "layout_width": status["layout_record_width"],
                "invalid_key_rows": status["invalid_key_rows"],
                "invalid_length_rows": status["line_length_mismatch_rows"],
                "duplicate_keys": status["duplicate_key_count"],
                "wrong_competence_rows": status["wrong_competence_rows"],
            }
            records.append(record)
            summary_rows.append(
                {
                    **record,
                    "layout_path": str(layout_path),
                    "procedure_path": str(data_path),
                }
            )
            print(
                f"[{competence}] SOURCE={source} "
                f"ROWS={status['rows']} CODES={status['distinct_raw_keys']} "
                f"INVALID=0"
            )

    if len(records) != 36 or reused != 4 or downloads != 32:
        raise RuntimeError(
            f"Contagem de aquisições incoerente: {len(records)}, "
            f"reused={reused}, downloaded={downloads}"
        )
    ROOT.mkdir(parents=True, exist_ok=True)
    write_inventory(records)
    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C3_3B1_SIGTAP_PROCEDURE_HISTORY_ACQUISITION",
        "status": "PASS",
        "mode": "CONTROLLED_HISTORICAL_PROCEDURE_ACQUISITION",
        "source": {"ftp_host": FTP_HOST, "ftp_directory": FTP_DIRECTORY},
        "input_manifests": {
            "sample": str(SAMPLE_MANIFEST),
            "pilot": str(PILOT_SUMMARY),
            "rd_profile": str(RD_PROFILE),
            "inventory": str(INVENTORY),
        },
        "competences": list(COMPETENCES),
        "counts": {
            "competences": len(records),
            "sample_months_reused": reused,
            "new_packages_downloaded": downloads,
            "total_procedure_rows": sum(r["procedure_rows"] for r in records),
        },
        "layout": {
            "sha256": layout_hash,
            "field_count": len(field_signature),
            "record_width": field_signature[-1][3],
            "identical_all_36_months": True,
        },
        "materialized": summary_rows,
        "outputs": {
            "inventory": {
                "path": str(HISTORY_INVENTORY),
                "sha256": sha256_file(HISTORY_INVENTORY),
                "rows": len(records),
            },
            "manifest": str(HISTORY_MANIFEST),
        },
        "scope": {
            "rd_procedure_coverage_evaluated": False,
            "t27_gate_closed": False,
            "qvd_generated": False,
        },
    }
    HISTORY_MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("COMPETENCES_VALIDATED=36")
    print("SAMPLE_MONTHS_REUSED=" + str(reused))
    print("NEW_PACKAGES_DOWNLOADED=" + str(downloads))
    print("TOTAL_PROCEDURE_ROWS=" + str(manifest["counts"]["total_procedure_rows"]))
    print("LAYOUT_SHA256=" + layout_hash)
    print("HISTORY_INVENTORY=" + str(HISTORY_INVENTORY))
    print("HISTORY_INVENTORY_SHA256=" + sha256_file(HISTORY_INVENTORY))
    print("MANIFEST=" + str(HISTORY_MANIFEST))
    print("T27_COVERAGE=NOT_EVALUATED")
    print("VERDICT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
