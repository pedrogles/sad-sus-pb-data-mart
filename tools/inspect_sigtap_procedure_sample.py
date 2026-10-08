#!/usr/bin/env python3
"""C3.2: inspeciona ZIPs oficiais SIGTAP em amostra controlada.

Lê exclusivamente o inventário C2.3; não extrai datasets nem baixa os 36 meses.
Registra todos os membros ZIP e prévias limitadas dos candidatos a procedimentos.
Saídas locais ignoradas pelo Git, em BASE/REFERENCIAS.
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
from pathlib import Path, PurePosixPath

FTP_HOST = "ftp2.datasus.gov.br"
FTP_DIRECTORY = "/pub/sistemas/tup/downloads"
INVENTORY = Path("BASE/REFERENCIAS/sigtap_package_inventory_2017_2019.csv")
OUTPUT_DIR = Path("BASE/REFERENCIAS")
MEMBERS_CSV = OUTPUT_DIR / "sigtap_procedure_sample_members.csv"
CANDIDATES_CSV = OUTPUT_DIR / "sigtap_procedure_sample_candidates.csv"
SUMMARY_JSON = OUTPUT_DIR / "sigtap_procedure_sample_summary.json"
SAMPLE_COMPETENCES = ("201701", "201801", "201901", "201912")
MAX_ZIP_BYTES = 250 * 1024 * 1024
MAX_PREVIEW_LINE_BYTES = 250
PREVIEW_LINES = 3


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_inventory(path: Path, selected: tuple[str, ...]) -> dict[str, dict[str, str]]:
    if not path.is_file():
        raise RuntimeError("Inventário C2.3 ausente: " + str(path))
    grouped: dict[str, list[dict[str, str]]] = {}
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        mandatory = {"competence", "filename", "remote_path", "size_bytes"}
        if reader.fieldnames is None or not mandatory.issubset(reader.fieldnames):
            raise RuntimeError("Cabeçalho inesperado no inventário C2.3")
        for row in reader:
            competence = row["competence"]
            if competence in selected:
                grouped.setdefault(competence, []).append(row)
    result: dict[str, dict[str, str]] = {}
    for competence in selected:
        rows = grouped.get(competence, [])
        if len(rows) != 1:
            raise RuntimeError(
                f"Inventário: competência {competence}, pacotes encontrados={len(rows)}"
            )
        item = rows[0]
        expected_name = item["filename"]
        expected_path = f"{FTP_DIRECTORY}/{expected_name}"
        if (
            not expected_name.startswith(f"TabelaUnificada_{competence}")
            or not expected_name.lower().endswith(".zip")
            or "/" in expected_name
            or "\\" in expected_name
            or item["remote_path"] != expected_path
        ):
            raise RuntimeError(f"Caminho remoto fora do contrato: {item}")
        size = item["size_bytes"]
        if size and size.isdecimal() and int(size) > MAX_ZIP_BYTES:
            raise RuntimeError(
                f"Pacote {expected_name} excede limite de amostra: {size}"
            )
        result[competence] = item
    return result


def receive_zip(ftp: ftplib.FTP, name: str, target: Path) -> int:
    total = 0
    with target.open("wb") as handle:
        def receive(block: bytes) -> None:
            nonlocal total
            total += len(block)
            if total > MAX_ZIP_BYTES:
                raise RuntimeError(
                    f"Download limitado a {MAX_ZIP_BYTES} bytes: {name}"
                )
            handle.write(block)
        ftp.retrbinary(f"RETR {name}", receive, blocksize=131072)
    return total


def preview_member(archive: zipfile.ZipFile, member: zipfile.ZipInfo) -> list[str]:
    previews: list[str] = []
    if member.is_dir():
        return previews
    with archive.open(member) as handle:
        for _ in range(PREVIEW_LINES):
            raw = handle.readline(MAX_PREVIEW_LINE_BYTES + 1)
            if not raw:
                break
            clipped = len(raw) > MAX_PREVIEW_LINE_BYTES
            raw = raw[:MAX_PREVIEW_LINE_BYTES]
            # Apenas prévia; encoding definitivo será validado em C3.3.
            decoded = raw.rstrip(b"\r\n").decode("cp1252", errors="replace")
            previews.append(decoded + (" [TRUNCATED]" if clipped else ""))
    return previews


def write_csv(path: Path, fields: list[str], rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=fields, delimiter=";", lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--competences", nargs="+", default=list(SAMPLE_COMPETENCES)
    )
    parser.add_argument("--inventory", type=Path, default=INVENTORY)
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()
    selected = tuple(args.competences)
    if (
        not selected
        or len(selected) > len(SAMPLE_COMPETENCES)
        or len(set(selected)) != len(selected)
        or any(item not in SAMPLE_COMPETENCES for item in selected)
    ):
        raise RuntimeError(
            "C3.2 permite somente amostra sem duplicatas: "
            + ", ".join(SAMPLE_COMPETENCES)
        )

    inventory = read_inventory(args.inventory, selected)
    member_rows: list[dict[str, object]] = []
    candidate_rows: list[dict[str, object]] = []
    packages: list[dict[str, object]] = []

    print("MODE=CONTROLLED_SAMPLE_INSPECTION")
    print("COMPETENCES=" + ",".join(selected))
    print("DOWNLOAD_CAP_BYTES_PER_PACKAGE=" + str(MAX_ZIP_BYTES))
    with ftplib.FTP(timeout=args.timeout) as ftp:
        ftp.connect(FTP_HOST)
        ftp.login()
        ftp.cwd(FTP_DIRECTORY)
        for competence in selected:
            item = inventory[competence]
            name = item["filename"]
            print(f"[{competence}] DOWNLOAD={name}")
            with tempfile.TemporaryDirectory(prefix=f"sigtap_proc_{competence}_") as tmp:
                temp_zip = Path(tmp) / name
                received = receive_zip(ftp, name, temp_zip)
                zip_hash = sha256_file(temp_zip)
                with zipfile.ZipFile(temp_zip) as archive:
                    corrupted = archive.testzip()
                    if corrupted is not None:
                        raise RuntimeError(
                            f"CRC inválido em {competence}: {corrupted}"
                        )
                    infos = archive.infolist()
                    current_candidates: list[dict[str, object]] = []
                    for entry in infos:
                        basename = PurePosixPath(entry.filename.replace("\\", "/")).name
                        is_candidate = "proced" in basename.lower()
                        role = (
                            "LAYOUT" if "layout" in basename.lower()
                            else "DATA"
                        ) if is_candidate and not entry.is_dir() else ""
                        member_rows.append(
                            {
                                "competence": competence,
                                "zip_member": entry.filename,
                                "basename": basename,
                                "uncompressed_size": entry.file_size,
                                "compressed_size": entry.compress_size,
                                "crc32": f"{entry.CRC:08x}",
                                "procedure_candidate": int(bool(role)),
                                "candidate_role": role,
                            }
                        )
                        if role:
                            previews = preview_member(archive, entry)
                            record: dict[str, object] = {
                                "competence": competence,
                                "zip_member": entry.filename,
                                "basename": basename,
                                "role": role,
                                "uncompressed_size": entry.file_size,
                                "crc32": f"{entry.CRC:08x}",
                                "preview_1_cp1252": previews[0] if len(previews) > 0 else "",
                                "preview_2_cp1252": previews[1] if len(previews) > 1 else "",
                                "preview_3_cp1252": previews[2] if len(previews) > 2 else "",
                            }
                            current_candidates.append(record)
                            candidate_rows.append(record)
                data_count = sum(r["role"] == "DATA" for r in current_candidates)
                layout_count = sum(r["role"] == "LAYOUT" for r in current_candidates)
                packages.append(
                    {
                        "competence": competence,
                        "package_filename": name,
                        "package_sha256": zip_hash,
                        "package_size_bytes": received,
                        "members": len(infos),
                        "procedure_candidates": len(current_candidates),
                        "procedure_data_candidates": data_count,
                        "procedure_layout_candidates": layout_count,
                    }
                )
                print(
                    f"[{competence}] MEMBERS={len(infos)} "
                    f"PROCEDURE_DATA_CANDIDATES={data_count} "
                    f"PROCEDURE_LAYOUT_CANDIDATES={layout_count}"
                )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    write_csv(
        MEMBERS_CSV,
        [
            "competence", "zip_member", "basename", "uncompressed_size",
            "compressed_size", "crc32", "procedure_candidate", "candidate_role",
        ],
        member_rows,
    )
    write_csv(
        CANDIDATES_CSV,
        [
            "competence", "zip_member", "basename", "role",
            "uncompressed_size", "crc32", "preview_1_cp1252",
            "preview_2_cp1252", "preview_3_cp1252",
        ],
        candidate_rows,
    )
    # PASS significa somente que a amostra contém arquivos candidatos,
    # não que o layout/campos ou a cobertura temporal foram confirmados.
    status = (
        "PASS"
        if all(
            p["procedure_data_candidates"] > 0
            and p["procedure_layout_candidates"] > 0
            for p in packages
        )
        else "REVIEW"
    )
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C3_2_SIGTAP_PROCEDURE_SAMPLE_INSPECTION",
        "status": status,
        "mode": "CONTROLLED_SAMPLE_INSPECTION",
        "source": {"ftp_host": FTP_HOST, "remote_dir": FTP_DIRECTORY},
        "sample_competences": list(selected),
        "packages": packages,
        "totals": {
            "packages": len(packages),
            "members": len(member_rows),
            "procedure_candidates": len(candidate_rows),
        },
        "outputs": {
            "members": {
                "path": str(MEMBERS_CSV),
                "sha256": sha256_file(MEMBERS_CSV),
                "rows": len(member_rows),
            },
            "candidates": {
                "path": str(CANDIDATES_CSV),
                "sha256": sha256_file(CANDIDATES_CSV),
                "rows": len(candidate_rows),
            },
            "summary": str(SUMMARY_JSON),
        },
        "scope": {
            "full_36_packages_downloaded": False,
            "procedure_reference_materialized": False,
            "t27_coverage_evaluated": False,
            "column_layout_validated": False,
        },
    }
    SUMMARY_JSON.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("PACKAGE_COUNT=" + str(len(packages)))
    print("PROCEDURE_CANDIDATE_COUNT=" + str(len(candidate_rows)))
    print("MEMBERS_CSV=" + str(MEMBERS_CSV))
    print("CANDIDATES_CSV=" + str(CANDIDATES_CSV))
    print("SUMMARY=" + str(SUMMARY_JSON))
    print("T27_COVERAGE=NOT_EVALUATED")
    print("VERDICT=" + status)
    return 0 if status == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
