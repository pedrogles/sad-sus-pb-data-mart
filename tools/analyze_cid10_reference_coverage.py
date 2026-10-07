#!/usr/bin/env python3
"""Analisa cobertura real de DIAG_PRINC contra tb_cid SIGTAP.

Checkpoint III-C2 — C2.6.

Base empírica já confirmada:
- layout fixo com CO_CID nas posições 1-4 e NO_CID nas posições 5-104;
- 201901 possui 12.450 linhas;
- 201912 possui 14.230 linhas;
- 201912 adiciona 1.780 linhas e não remove nenhuma linha física;
- DIAG_PRINC usa largura 4 e parte dos códigos possui padding ASCII à direita.

Este diagnóstico:
- interpreta o layout físico confirmado;
- compara 201901 x 201912 por chave CID;
- mede cobertura dos 566.672 registros RD por código bruto e por rstrip(' ');
- verifica colisões da chave normalizada;
- caracteriza as chaves que só passam a existir em 201912.

Não altera arquivos fonte nem gera QVD.
"""

from __future__ import annotations

import csv
import glob
import json
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

RD_GLOB = r"BASE\CONVERTIDA\RD\RDPB*.csv"
EXPECTED_RD_FILES = 36
EXPECTED_RD_ROWS = 566_672

CID_ROOT = Path("BASE/REFERENCIAS/SIGTAP/CID10")
OLD_COMPETENCE = "201901"
NEW_COMPETENCE = "201912"

OUTPUT_JSON = Path("BASE/REFERENCIAS/cid10_coverage_analysis.json")
OUTPUT_CSV = Path("BASE/REFERENCIAS/cid10_coverage_unmatched.csv")


def parse_layout(path: Path) -> list[dict[str, object]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        required = {"Coluna", "Tamanho", "Inicio", "Fim", "Tipo"}
        if reader.fieldnames is None or set(reader.fieldnames) != required:
            raise RuntimeError(
                f"Layout inesperado em {path}: {reader.fieldnames}"
            )

        fields: list[dict[str, object]] = []
        for row in reader:
            fields.append(
                {
                    "name": row["Coluna"],
                    "size": int(row["Tamanho"]),
                    "start": int(row["Inicio"]),
                    "end": int(row["Fim"]),
                    "type": row["Tipo"],
                }
            )

    expected = [
        ("CO_CID", 4, 1, 4),
        ("NO_CID", 100, 5, 104),
        ("TP_AGRAVO", 1, 105, 105),
        ("TP_SEXO", 1, 106, 106),
        ("TP_ESTADIO", 1, 107, 107),
        ("VL_CAMPOS_IRRADIADOS", 4, 108, 111),
    ]
    actual = [
        (str(f["name"]), int(f["size"]), int(f["start"]), int(f["end"]))
        for f in fields
    ]
    if actual != expected:
        raise RuntimeError(f"Layout físico divergente do esperado: {actual}")

    return fields


def parse_cid_file(path: Path, layout: list[dict[str, object]]) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []

    with path.open("r", encoding="cp1252", newline="") as handle:
        for line_number, raw_line in enumerate(handle, start=1):
            line = raw_line.rstrip("\r\n")
            if len(line) != 111:
                raise RuntimeError(
                    f"Linha {line_number} de {path} possui comprimento {len(line)}, esperado=111"
                )

            record: dict[str, str] = {}
            for field in layout:
                start = int(field["start"]) - 1
                end = int(field["end"])
                record[str(field["name"])] = line[start:end]

            records.append(record)

    return records


def index_reference(records: list[dict[str, str]], label: str) -> dict[str, dict[str, str]]:
    by_raw: dict[str, dict[str, str]] = {}
    for record in records:
        key = record["CO_CID"]
        if key in by_raw:
            raise RuntimeError(f"Chave CO_CID duplicada em {label}: {key!r}")
        by_raw[key] = record
    return by_raw


def normalized_index(
    by_raw: dict[str, dict[str, str]], label: str
) -> tuple[dict[str, dict[str, str]], dict[str, list[str]]]:
    normalized: dict[str, dict[str, str]] = {}
    variants: defaultdict[str, list[str]] = defaultdict(list)

    for raw_key, record in by_raw.items():
        key = raw_key.rstrip(" ")
        variants[key].append(raw_key)
        if key not in normalized:
            normalized[key] = record

    collisions = {
        key: sorted(raw_values)
        for key, raw_values in variants.items()
        if len(raw_values) > 1
    }
    if collisions:
        raise RuntimeError(
            f"Colisões após rstrip(' ') na referência {label}: "
            + json.dumps(collisions, ensure_ascii=False)
        )

    return normalized, {}


def rd_competence(path: str) -> str:
    stem = Path(path).stem
    if len(stem) != 8 or not stem.startswith("RDPB") or not stem[4:].isdigit():
        raise RuntimeError(f"Nome RD inesperado: {stem}")
    return "20" + stem[4:]


def main() -> int:
    layout_path = CID_ROOT / OLD_COMPETENCE / "tb_cid_layout.txt"
    old_path = CID_ROOT / OLD_COMPETENCE / "tb_cid.txt"
    new_path = CID_ROOT / NEW_COMPETENCE / "tb_cid.txt"

    for path in (layout_path, old_path, new_path):
        if not path.exists():
            raise RuntimeError(f"Arquivo necessário ausente: {path}")

    layout = parse_layout(layout_path)
    old_records = parse_cid_file(old_path, layout)
    new_records = parse_cid_file(new_path, layout)

    old_raw = index_reference(old_records, OLD_COMPETENCE)
    new_raw = index_reference(new_records, NEW_COMPETENCE)
    old_norm, _ = normalized_index(old_raw, OLD_COMPETENCE)
    new_norm, _ = normalized_index(new_raw, NEW_COMPETENCE)

    old_keys = set(old_raw)
    new_keys = set(new_raw)

    added_raw = sorted(new_keys - old_keys)
    removed_raw = sorted(old_keys - new_keys)
    shared_raw = sorted(old_keys & new_keys)

    shared_changed_description = []
    shared_changed_payload = []

    for key in shared_raw:
        old_record = old_raw[key]
        new_record = new_raw[key]

        if old_record["NO_CID"] != new_record["NO_CID"]:
            shared_changed_description.append(key)

        if old_record != new_record:
            shared_changed_payload.append(key)

    added_trimmed_length_counts = Counter(len(key.rstrip(" ")) for key in added_raw)
    added_trailing_space_count = sum(1 for key in added_raw if key.endswith(" "))

    rd_files = sorted(glob.glob(RD_GLOB))
    if len(rd_files) != EXPECTED_RD_FILES:
        raise RuntimeError(
            f"Quantidade RD divergente: esperado={EXPECTED_RD_FILES} atual={len(rd_files)}"
        )

    overall = Counter()
    by_year: defaultdict[str, Counter[str]] = defaultdict(Counter)
    by_competence: defaultdict[str, Counter[str]] = defaultdict(Counter)
    unmatched_norm_counts: Counter[str] = Counter()
    unmatched_raw_counts: Counter[str] = Counter()

    total_rows = 0

    for path in rd_files:
        competence = rd_competence(path)
        year = competence[:4]

        with open(path, "r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle, delimiter=";")
            if reader.fieldnames is None or "DIAG_PRINC" not in reader.fieldnames:
                raise RuntimeError(f"DIAG_PRINC ausente em {path}")

            for row in reader:
                total_rows += 1
                raw = row["DIAG_PRINC"] or ""
                norm = raw.rstrip(" ")

                metrics = {
                    "raw_in_201901": raw in old_raw,
                    "raw_in_201912": raw in new_raw,
                    "norm_in_201901": norm in old_norm,
                    "norm_in_201912": norm in new_norm,
                }

                for metric, matched in metrics.items():
                    overall[metric + ("_matched" if matched else "_unmatched")] += 1
                    by_year[year][metric + ("_matched" if matched else "_unmatched")] += 1
                    by_competence[competence][metric + ("_matched" if matched else "_unmatched")] += 1

                if norm not in old_norm:
                    unmatched_norm_counts[norm] += 1
                if raw not in old_raw:
                    unmatched_raw_counts[raw] += 1

    if total_rows != EXPECTED_RD_ROWS:
        raise RuntimeError(
            f"Linhas RD divergentes: esperado={EXPECTED_RD_ROWS} atual={total_rows}"
        )

    unmatched_norm_keys = set(unmatched_norm_counts)
    unmatched_raw_keys = set(unmatched_raw_counts)

    unmatched_norm_all_in_201912 = unmatched_norm_keys.issubset(set(new_norm))
    unmatched_raw_all_in_201912 = unmatched_raw_keys.issubset(set(new_raw))

    unmatched_norm_length_counts = Counter(len(key) for key in unmatched_norm_keys)
    unmatched_raw_length_counts = Counter(len(key) for key in unmatched_raw_keys)

    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "diag_princ_normalized",
                "occurrences",
                "normalized_length",
                "present_201901",
                "present_201912",
                "description_201912",
            ],
            delimiter=";",
        )
        writer.writeheader()

        for key, count in sorted(
            unmatched_norm_counts.items(),
            key=lambda item: (-item[1], item[0]),
        ):
            ref_201912 = new_norm.get(key)
            writer.writerow(
                {
                    "diag_princ_normalized": key,
                    "occurrences": count,
                    "normalized_length": len(key),
                    "present_201901": key in old_norm,
                    "present_201912": key in new_norm,
                    "description_201912": (
                        ref_201912["NO_CID"].rstrip(" ")
                        if ref_201912 is not None
                        else ""
                    ),
                }
            )

    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C2_CID10_COVERAGE_ANALYSIS",
        "status": "PASS",
        "layout": [
            {
                "name": field["name"],
                "size": field["size"],
                "start": field["start"],
                "end": field["end"],
                "type": field["type"],
            }
            for field in layout
        ],
        "references": {
            OLD_COMPETENCE: {
                "rows": len(old_records),
                "raw_distinct_keys": len(old_raw),
                "normalized_distinct_keys": len(old_norm),
            },
            NEW_COMPETENCE: {
                "rows": len(new_records),
                "raw_distinct_keys": len(new_raw),
                "normalized_distinct_keys": len(new_norm),
            },
            "diff": {
                "added_raw_keys": len(added_raw),
                "removed_raw_keys": len(removed_raw),
                "shared_raw_keys": len(shared_raw),
                "shared_changed_description": len(shared_changed_description),
                "shared_changed_payload": len(shared_changed_payload),
                "added_trailing_space_count": added_trailing_space_count,
                "added_trimmed_length_counts": {
                    str(k): v for k, v in sorted(added_trimmed_length_counts.items())
                },
            },
        },
        "rd": {
            "files": len(rd_files),
            "rows": total_rows,
            "overall": dict(sorted(overall.items())),
            "by_year": {
                year: dict(sorted(metrics.items()))
                for year, metrics in sorted(by_year.items())
            },
            "by_competence": {
                competence: dict(sorted(metrics.items()))
                for competence, metrics in sorted(by_competence.items())
            },
        },
        "unmatched_against_201901": {
            "normalized_distinct_keys": len(unmatched_norm_keys),
            "raw_distinct_keys": len(unmatched_raw_keys),
            "normalized_length_counts": {
                str(k): v for k, v in sorted(unmatched_norm_length_counts.items())
            },
            "raw_length_counts": {
                str(k): v for k, v in sorted(unmatched_raw_length_counts.items())
            },
            "normalized_all_present_in_201912": unmatched_norm_all_in_201912,
            "raw_all_present_in_201912": unmatched_raw_all_in_201912,
        },
        "outputs": {
            "unmatched_csv": str(OUTPUT_CSV),
            "summary_json": str(OUTPUT_JSON),
        },
    }

    OUTPUT_JSON.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("MODE=READ_ONLY_COVERAGE_ANALYSIS")
    print(f"LAYOUT_FIELDS={len(layout)}")
    print(f"REF_201901_ROWS={len(old_records)}")
    print(f"REF_201912_ROWS={len(new_records)}")
    print(f"REF_ADDED_RAW_KEYS={len(added_raw)}")
    print(f"REF_REMOVED_RAW_KEYS={len(removed_raw)}")
    print(f"REF_SHARED_CHANGED_DESCRIPTION={len(shared_changed_description)}")
    print(f"REF_SHARED_CHANGED_PAYLOAD={len(shared_changed_payload)}")
    print(
        "REF_ADDED_TRIMMED_LENGTH_COUNTS="
        + json.dumps(
            {str(k): v for k, v in sorted(added_trimmed_length_counts.items())},
            ensure_ascii=False,
        )
    )
    print(f"RD_ROWS={total_rows}")
    print(
        f"RD_RAW_201901_UNMATCHED={overall['raw_in_201901_unmatched']}"
    )
    print(
        f"RD_RAW_201912_UNMATCHED={overall['raw_in_201912_unmatched']}"
    )
    print(
        f"RD_NORM_201901_UNMATCHED={overall['norm_in_201901_unmatched']}"
    )
    print(
        f"RD_NORM_201912_UNMATCHED={overall['norm_in_201912_unmatched']}"
    )
    print(f"UNMATCHED_NORM_KEYS_201901={len(unmatched_norm_keys)}")
    print(
        "UNMATCHED_NORM_LENGTH_COUNTS="
        + json.dumps(
            {str(k): v for k, v in sorted(unmatched_norm_length_counts.items())},
            ensure_ascii=False,
        )
    )
    print(
        "UNMATCHED_NORM_ALL_PRESENT_201912="
        + str(unmatched_norm_all_in_201912)
    )
    print(f"UNMATCHED_CSV={OUTPUT_CSV}")
    print(f"SUMMARY={OUTPUT_JSON}")
    print("VERDICT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
