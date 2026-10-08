#!/usr/bin/env python3
"""C3.3a: materializa somente tb_procedimento e seu layout em 4 pacotes SIGTAP.

Requer inventário C2.3 e manifesto C3.2 PASS. Compara hashes dos ZIPs
da amostra C3.2 antes de extrair os dois arquivos oficiais por competência.

Não baixa 36 competências, não assume nomes de campos além da chave física
confirmada na prévia e não executa lookup T27 nem altera QVDs.

Saídas locais (ignoradas pelo Git):
- BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM/tb_procedimento.txt
- BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM/tb_procedimento_layout.txt
- BASE/REFERENCIAS/sigtap_procedure_sample_layout_fields.csv
- BASE/REFERENCIAS/sigtap_procedure_sample_manifest.json
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import tempfile
import zipfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath

import ftplib

from inspect_sigtap_procedure_sample import (
    FTP_DIRECTORY,
    FTP_HOST,
    INVENTORY,
    SAMPLE_COMPETENCES,
    read_inventory,
    receive_zip,
    sha256_file,
)

OUTPUT_ROOT = Path("BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO")
C3_2_SUMMARY = Path("BASE/REFERENCIAS/sigtap_procedure_sample_summary.json")
LAYOUT_FIELDS_CSV = Path("BASE/REFERENCIAS/sigtap_procedure_sample_layout_fields.csv")
MANIFEST_JSON = Path("BASE/REFERENCIAS/sigtap_procedure_sample_manifest.json")
EXPECTED_FILES = ("tb_procedimento.txt", "tb_procedimento_layout.txt")
EXPECTED_LAYOUT_HEADER = ["Coluna", "Tamanho", "Inicio", "Fim", "Tipo"]
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def load_previous_sample(path: Path, selected: tuple[str, ...]) -> dict[str, dict]:
    if not path.is_file():
        raise RuntimeError("C3.2 não encontrado: " + str(path))
    summary = json.loads(path.read_text(encoding="utf-8"))
    if (
        summary.get("status") != "PASS"
        or summary.get("mode") != "CONTROLLED_SAMPLE_INSPECTION"
        or summary.get("source", {}).get("ftp_host") != FTP_HOST
        or summary.get("source", {}).get("remote_dir") != FTP_DIRECTORY
    ):
        raise RuntimeError("C3.2 não tem proveniência/estado esperado")
    allowed = set(summary.get("sample_competences", []))
    if not set(selected).issubset(allowed):
        raise RuntimeError("Competência não comprovada no C3.2")
    grouped: dict[str, list[dict]] = {}
    for row in summary.get("packages", []):
        grouped.setdefault(str(row["competence"]), []).append(row)
    result: dict[str, dict] = {}
    for competence in selected:
        rows = grouped.get(competence, [])
        if len(rows) != 1:
            raise RuntimeError(f"Pacote C3.2 ambíguo: {competence}")
        package = rows[0]
        if not HEX64.fullmatch(str(package.get("package_sha256", ""))):
            raise RuntimeError(f"SHA-256 C3.2 ausente/inválido: {competence}")
        result[competence] = package
    return result


def find_exact_member(zf: zipfile.ZipFile, basename: str) -> zipfile.ZipInfo:
    matches = [
        info for info in zf.infolist()
        if not info.is_dir()
        and PurePosixPath(info.filename.replace("\\", "/")).name.lower()
        == basename.lower()
    ]
    if len(matches) != 1:
        raise RuntimeError(
            f"Esperado exatamente um {basename}; encontrados={len(matches)}"
        )
    return matches[0]


def parse_layout(blob: bytes, competence: str) -> list[dict[str, object]]:
    # O cabeçalho é ASCII; cp1252 é apenas interpretação preliminar.
    reader = csv.DictReader(io.StringIO(blob.decode("cp1252")), delimiter=",")
    if reader.fieldnames != EXPECTED_LAYOUT_HEADER:
        raise RuntimeError(
            f"Layout {competence}: cabeçalho inesperado {reader.fieldnames}"
        )
    columns: list[dict[str, object]] = []
    previous_end = 0
    names: set[str] = set()
    for row in reader:
        if None in row or any(value is None for value in row.values()):
            raise RuntimeError(f"Layout {competence}: registro inválido {row}")
        name = row["Coluna"].strip()
        try:
            width = int(row["Tamanho"])
            start = int(row["Inicio"])
            end = int(row["Fim"])
        except ValueError as exc:
            raise RuntimeError(
                f"Layout {competence}: posição/tamanho não numérico {row}"
            ) from exc
        if (
            not name
            or name in names
            or width <= 0
            or start != previous_end + 1
            or end != start + width - 1
        ):
            raise RuntimeError(
                f"Layout {competence}: coluna inconsistente {row}"
            )
        names.add(name)
        columns.append(
            {
                "competence": competence,
                "field": name,
                "width": width,
                "start": start,
                "end": end,
                "type": row["Tipo"].strip(),
            }
        )
        previous_end = end
    if not columns or columns[0]["field"] != "CO_PROCEDIMENTO":
        raise RuntimeError(
            f"Layout {competence}: primeiro campo não é CO_PROCEDIMENTO"
        )
    if columns[0]["width"] != 10 or columns[0]["start"] != 1:
        raise RuntimeError(
            f"Layout {competence}: chave CO_PROCEDIMENTO inesperada"
        )
    return columns


def inspect_lines(blob: bytes, columns: list[dict[str, object]]) -> dict:
    expected_width = int(columns[-1]["end"])
    length_counts: Counter[int] = Counter()
    keys: Counter[str] = Counter()
    invalid_key_rows = 0
    length_mismatch_rows = 0
    sample_rows: list[dict[str, str]] = []
    decoded_lines = blob.splitlines()
    field_names = {str(field["field"]): field for field in columns}
    description_field = field_names.get("NO_PROCEDIMENTO")

    for row_number, raw in enumerate(decoded_lines, start=1):
        length_counts[len(raw)] += 1
        if len(raw) != expected_width:
            length_mismatch_rows += 1
        key_bytes = raw[:10]
        if len(key_bytes) != 10 or not all(48 <= b <= 57 for b in key_bytes):
            invalid_key_rows += 1
        else:
            key = key_bytes.decode("ascii")
            keys[key] += 1

        if len(sample_rows) < 3:
            item = {
                "line_number": str(row_number),
                "raw_key": key_bytes.decode("ascii", errors="replace"),
                "line_length_bytes": str(len(raw)),
            }
            if description_field is not None:
                start = int(description_field["start"]) - 1
                end = int(description_field["end"])
                item["description_preview_cp1252"] = (
                    raw[start:end].decode("cp1252", errors="replace").rstrip(" ")
                )
            sample_rows.append(item)

    return {
        "rows": len(decoded_lines),
        "distinct_raw_keys": len(keys),
        "duplicate_key_count": sum(count - 1 for count in keys.values() if count > 1),
        "invalid_key_rows": invalid_key_rows,
        "line_length_mismatch_rows": length_mismatch_rows,
        "line_length_counts": {
            str(length): count for length, count in sorted(length_counts.items())
        },
        "layout_record_width": expected_width,
        "sample_rows": sample_rows,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--competences", nargs="+", default=list(SAMPLE_COMPETENCES)
    )
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()
    selected = tuple(args.competences)
    if (
        not selected
        or len(selected) > 4
        or len(set(selected)) != len(selected)
        or any(competence not in SAMPLE_COMPETENCES for competence in selected)
    ):
        raise RuntimeError("Amostra permitida: 201701 201801 201901 201912")

    inventory = read_inventory(INVENTORY, selected)
    checked = load_previous_sample(C3_2_SUMMARY, selected)
    results: list[dict] = []
    layout_field_rows: list[dict[str, object]] = []

    print("MODE=CONTROLLED_PROCEDURE_SAMPLE_MATERIALIZATION")
    print("COMPETENCES=" + ",".join(selected))
    with ftplib.FTP(timeout=args.timeout) as ftp:
        ftp.connect(FTP_HOST)
        ftp.login()
        ftp.cwd(FTP_DIRECTORY)

        for competence in selected:
            package = inventory[competence]
            previous = checked[competence]
            name = package["filename"]
            if name != previous["package_filename"]:
                raise RuntimeError(
                    f"C3.2/inventário divergem em {competence}: {name}"
                )
            print(f"[{competence}] DOWNLOAD={name}")

            with tempfile.TemporaryDirectory(
                prefix=f"sigtap_proc_layout_{competence}_"
            ) as directory:
                zip_path = Path(directory) / name
                bytes_received = receive_zip(ftp, name, zip_path)
                zip_sha = sha256_file(zip_path)
                if (
                    zip_sha != previous["package_sha256"]
                    or bytes_received != int(previous["package_size_bytes"])
                ):
                    raise RuntimeError(
                        f"Pacote {competence} divergiu do C3.2 em hash/tamanho"
                    )

                with zipfile.ZipFile(zip_path, "r") as zf:
                    corrupted_member = zf.testzip()
                    if corrupted_member is not None:
                        raise RuntimeError(
                            f"ZIP {competence} com erro CRC: {corrupted_member}"
                        )
                    blobs: dict[str, bytes] = {}
                    provenance: dict[str, dict] = {}
                    for basename in EXPECTED_FILES:
                        info = find_exact_member(zf, basename)
                        content = zf.read(info)
                        blobs[basename] = content
                        provenance[basename] = {
                            "zip_member": info.filename,
                            "size_bytes": len(content),
                            "crc32": f"{info.CRC:08x}",
                            "sha256": hashlib.sha256(content).hexdigest(),
                        }

            columns = parse_layout(
                blobs["tb_procedimento_layout.txt"], competence
            )
            inspection = inspect_lines(blobs["tb_procedimento.txt"], columns)
            layout_field_rows.extend(columns)

            target = OUTPUT_ROOT / competence
            target.mkdir(parents=True, exist_ok=True)
            for basename in EXPECTED_FILES:
                physical_path = target / basename
                physical_path.write_bytes(blobs[basename])
                provenance[basename]["path"] = str(physical_path)

            results.append(
                {
                    "competence": competence,
                    "package_filename": name,
                    "package_size_bytes": bytes_received,
                    "package_sha256": zip_sha,
                    "files": provenance,
                    "layout": {
                        "fields": [
                            {
                                "name": field["field"],
                                "width": field["width"],
                                "start": field["start"],
                                "end": field["end"],
                                "type": field["type"],
                            }
                            for field in columns
                        ],
                        "record_width": int(columns[-1]["end"]),
                    },
                    "data_inspection": inspection,
                }
            )
            print(
                f"[{competence}] LAYOUT_FIELDS={len(columns)} "
                f"WIDTH={inspection['layout_record_width']} "
                f"ROWS={inspection['rows']} "
                f"DISTINCT_CODES={inspection['distinct_raw_keys']} "
                f"INVALID_KEYS={inspection['invalid_key_rows']} "
                f"INVALID_LENGTH={inspection['line_length_mismatch_rows']} "
                f"DUPLICATE_KEYS={inspection['duplicate_key_count']}"
            )

    LAYOUT_FIELDS_CSV.parent.mkdir(parents=True, exist_ok=True)
    with LAYOUT_FIELDS_CSV.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["competence", "field", "width", "start", "end", "type"],
            delimiter=";",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(layout_field_rows)

    layouts_hashes = {
        record["files"]["tb_procedimento_layout.txt"]["sha256"]
        for record in results
    }
    invalid_rows = sum(
        item["data_inspection"]["line_length_mismatch_rows"]
        + item["data_inspection"]["invalid_key_rows"]
        + item["data_inspection"]["duplicate_key_count"]
        for item in results
    )
    verdict = "PASS" if invalid_rows == 0 else "REVIEW"
    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C3_3A_PROCEDURE_SAMPLE_LAYOUT_INSPECTION",
        "status": verdict,
        "mode": "CONTROLLED_PROCEDURE_SAMPLE_MATERIALIZATION",
        "source": {
            "ftp_host": FTP_HOST,
            "remote_dir": FTP_DIRECTORY,
            "previous_c3_2_summary": str(C3_2_SUMMARY),
        },
        "selection": list(selected),
        "materialized": results,
        "stability": {
            "layout_hashes_distinct_in_sample": len(layouts_hashes),
            "layout_identical_in_sample": len(layouts_hashes) == 1,
        },
        "outputs": {
            "layout_fields": {
                "path": str(LAYOUT_FIELDS_CSV),
                "sha256": sha256_file(LAYOUT_FIELDS_CSV),
                "rows": len(layout_field_rows),
            },
            "manifest": str(MANIFEST_JSON),
        },
        "scope": {
            "only_sample_competences": True,
            "full_36_packages_downloaded": False,
            "procedure_reference_36_materialized": False,
            "t27_coverage_evaluated": False,
            "encoding_confirmed": False,
        },
    }
    MANIFEST_JSON.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print("MATERIALIZED_COMPETENCES=" + str(len(results)))
    print("LAYOUT_DISTINCT_HASHES=" + str(len(layouts_hashes)))
    print("LAYOUT_IDENTICAL_IN_SAMPLE=" + str(len(layouts_hashes) == 1))
    print("LAYOUT_FIELDS_CSV=" + str(LAYOUT_FIELDS_CSV))
    print("LAYOUT_FIELDS_SHA256=" + sha256_file(LAYOUT_FIELDS_CSV))
    print("MANIFEST=" + str(MANIFEST_JSON))
    print("T27_COVERAGE=NOT_EVALUATED")
    print("VERDICT=" + verdict)
    return 0 if verdict == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
