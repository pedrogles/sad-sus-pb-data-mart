#!/usr/bin/env python3
"""Materializa uma amostra controlada de tb_cid/tb_cid_layout do SIGTAP.

Checkpoint III-C2 — C2.4.
Baixa somente competências estratégicas do inventário oficial já gerado,
extrai apenas os arquivos CID necessários e descarta os ZIPs temporários.

Saídas locais (ignoradas pelo Git):
- BASE/REFERENCIAS/SIGTAP/CID10/<competencia>/tb_cid.txt
- BASE/REFERENCIAS/SIGTAP/CID10/<competencia>/tb_cid_layout.txt
- BASE/REFERENCIAS/cid10_sigtap_sample_manifest.json
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

DEFAULT_COMPETENCES = ["201701", "201801", "201901", "201912"]
INVENTORY_PATH = Path("BASE/REFERENCIAS/sigtap_package_inventory_2017_2019.csv")
OUTPUT_ROOT = Path("BASE/REFERENCIAS/SIGTAP/CID10")
MANIFEST_PATH = Path("BASE/REFERENCIAS/cid10_sigtap_sample_manifest.json")
FTP_HOST = "ftp2.datasus.gov.br"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def count_lines_bytes(path: Path) -> int:
    with path.open("rb") as handle:
        data = handle.read()
    if not data:
        return 0
    return data.count(b"\n") + (0 if data.endswith(b"\n") else 1)


def load_inventory(path: Path) -> dict[str, dict[str, str]]:
    if not path.exists():
        raise RuntimeError(
            f"Inventário não encontrado: {path}. Execute primeiro enumerate_sigtap_packages.py."
        )

    by_competence: dict[str, list[dict[str, str]]] = {}

    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        required = {"competence", "filename", "remote_path", "size_bytes"}
        if reader.fieldnames is None or not required.issubset(set(reader.fieldnames)):
            raise RuntimeError(
                f"Schema inesperado no inventário. Esperado conter: {sorted(required)}"
            )

        for row in reader:
            competence = row["competence"]
            by_competence.setdefault(competence, []).append(row)

    result: dict[str, dict[str, str]] = {}
    for competence, rows in by_competence.items():
        if len(rows) != 1:
            raise RuntimeError(
                f"Competência {competence} possui {len(rows)} pacotes no inventário; "
                "seleção automática bloqueada."
            )
        result[competence] = rows[0]

    return result


def find_member(zf: zipfile.ZipFile, expected_basename: str) -> str:
    matches = [
        name
        for name in zf.namelist()
        if Path(name).name.lower() == expected_basename.lower()
    ]
    if len(matches) != 1:
        cid_candidates = [
            name
            for name in zf.namelist()
            if "cid" in Path(name).name.lower()
        ]
        raise RuntimeError(
            f"Esperado exatamente 1 arquivo {expected_basename}; encontrados={matches}. "
            f"Candidatos com 'cid'={cid_candidates[:50]}"
        )
    return matches[0]


def download_file(ftp: ftplib.FTP, remote_path: str, local_path: Path) -> None:
    parent = str(Path(remote_path).parent).replace("\\", "/")
    filename = Path(remote_path).name

    ftp.cwd("/")
    ftp.cwd(parent)

    with local_path.open("wb") as handle:
        ftp.retrbinary(f"RETR {filename}", handle.write)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--competences",
        nargs="+",
        default=DEFAULT_COMPETENCES,
        help="Competências SIGTAP a materializar (default: 201701 201801 201901 201912)",
    )
    parser.add_argument("--inventory", type=Path, default=INVENTORY_PATH)
    parser.add_argument("--output-root", type=Path, default=OUTPUT_ROOT)
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()

    competences = args.competences
    if len(set(competences)) != len(competences):
        raise RuntimeError("Lista de competências contém duplicatas.")

    inventory = load_inventory(args.inventory)

    missing_inventory = [c for c in competences if c not in inventory]
    if missing_inventory:
        raise RuntimeError(
            "Competências ausentes no inventário: " + ", ".join(missing_inventory)
        )

    args.output_root.mkdir(parents=True, exist_ok=True)

    materialized: list[dict[str, object]] = []

    print("MODE=CONTROLLED_SAMPLE_DOWNLOAD")
    print("COMPETENCES=" + ",".join(competences))

    with ftplib.FTP(timeout=args.timeout) as ftp:
        ftp.connect(FTP_HOST)
        ftp.login()

        for competence in competences:
            item = inventory[competence]
            remote_path = item["remote_path"]
            filename = item["filename"]

            print(f"[{competence}] DOWNLOAD={filename}")

            with tempfile.TemporaryDirectory(prefix=f"sigtap_{competence}_") as tmp_dir:
                zip_path = Path(tmp_dir) / filename
                download_file(ftp, remote_path, zip_path)

                zip_sha256 = sha256_file(zip_path)
                zip_size = zip_path.stat().st_size

                with zipfile.ZipFile(zip_path, "r") as zf:
                    bad_member = zf.testzip()
                    if bad_member is not None:
                        raise RuntimeError(
                            f"ZIP inválido em {competence}; primeiro membro corrompido={bad_member}"
                        )

                    cid_member = find_member(zf, "tb_cid.txt")
                    layout_member = find_member(zf, "tb_cid_layout.txt")

                    target_dir = args.output_root / competence
                    target_dir.mkdir(parents=True, exist_ok=True)

                    cid_path = target_dir / "tb_cid.txt"
                    layout_path = target_dir / "tb_cid_layout.txt"

                    cid_path.write_bytes(zf.read(cid_member))
                    layout_path.write_bytes(zf.read(layout_member))

            record = {
                "competence": competence,
                "package_filename": filename,
                "remote_path": remote_path,
                "package_size_bytes": zip_size,
                "package_sha256": zip_sha256,
                "tb_cid": {
                    "zip_member": cid_member,
                    "path": str(cid_path),
                    "size_bytes": cid_path.stat().st_size,
                    "line_count_bytes": count_lines_bytes(cid_path),
                    "sha256": sha256_file(cid_path),
                },
                "tb_cid_layout": {
                    "zip_member": layout_member,
                    "path": str(layout_path),
                    "size_bytes": layout_path.stat().st_size,
                    "line_count_bytes": count_lines_bytes(layout_path),
                    "sha256": sha256_file(layout_path),
                },
            }
            materialized.append(record)

            print(
                f"[{competence}] TB_CID_SHA256={record['tb_cid']['sha256']} "
                f"LINES={record['tb_cid']['line_count_bytes']}"
            )
            print(
                f"[{competence}] LAYOUT_SHA256={record['tb_cid_layout']['sha256']} "
                f"LINES={record['tb_cid_layout']['line_count_bytes']}"
            )

    cid_hashes = sorted({str(item["tb_cid"]["sha256"]) for item in materialized})
    layout_hashes = sorted(
        {str(item["tb_cid_layout"]["sha256"]) for item in materialized}
    )

    stability = {
        "tb_cid_identical_across_sample": len(cid_hashes) == 1,
        "tb_cid_distinct_hashes": len(cid_hashes),
        "tb_cid_layout_identical_across_sample": len(layout_hashes) == 1,
        "tb_cid_layout_distinct_hashes": len(layout_hashes),
    }

    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C2_CID10_SAMPLE_MATERIALIZATION",
        "status": "PASS",
        "mode": "CONTROLLED_SAMPLE_DOWNLOAD",
        "source": {
            "host": FTP_HOST,
            "inventory": str(args.inventory),
        },
        "selection": {
            "competences": competences,
            "rationale": (
                "Primeira competência de cada ano e última competência do período "
                "para testar estabilidade antes de ampliar downloads."
            ),
        },
        "materialized": materialized,
        "stability": stability,
    }

    MANIFEST_PATH.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"MATERIALIZED_COMPETENCES={len(materialized)}")
    print(f"TB_CID_DISTINCT_HASHES={stability['tb_cid_distinct_hashes']}")
    print(
        "TB_CID_IDENTICAL_ACROSS_SAMPLE="
        + str(stability["tb_cid_identical_across_sample"])
    )
    print(
        f"TB_CID_LAYOUT_DISTINCT_HASHES={stability['tb_cid_layout_distinct_hashes']}"
    )
    print(
        "TB_CID_LAYOUT_IDENTICAL_ACROSS_SAMPLE="
        + str(stability["tb_cid_layout_identical_across_sample"])
    )
    print(f"MANIFEST={MANIFEST_PATH}")
    print("VERDICT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
