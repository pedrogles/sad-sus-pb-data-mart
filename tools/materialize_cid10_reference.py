#!/usr/bin/env python3
"""Materializa a referência CID-10 final para o Data Mart.

Checkpoint III-C2 — C2.7.

A decisão de usar a competência 201912 como referência descritiva superset
é condicionada à evidência persistida do C2.6:
- 566.672/566.672 registros RD cobertos por 201912;
- 0 descrições/payload compartilhados alterados entre 201901 e 201912;
- 1.780 chaves adicionadas e 0 removidas;
- todos os 349 códigos normalizados não cobertos por 201901 presentes em 201912.

A referência final é descritiva. Ela NÃO afirma validade histórica mensal
de cada CID e não deve ser usada para inferir vigência por competência.

Saídas locais (ignoradas pelo Git):
- BASE/REFERENCIAS/cid10_referencia.csv
- BASE/REFERENCIAS/cid10_referencia_manifest.json
"""

from __future__ import annotations

import csv
import hashlib
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path("BASE/REFERENCIAS")
CID_COMPETENCE = "201912"
CID_PATH = ROOT / "SIGTAP" / "CID10" / CID_COMPETENCE / "tb_cid.txt"
LAYOUT_PATH = ROOT / "SIGTAP" / "CID10" / CID_COMPETENCE / "tb_cid_layout.txt"
SAMPLE_MANIFEST_PATH = ROOT / "cid10_sigtap_sample_manifest.json"
COVERAGE_PATH = ROOT / "cid10_coverage_analysis.json"
OUTPUT_CSV = ROOT / "cid10_referencia.csv"
OUTPUT_MANIFEST = ROOT / "cid10_referencia_manifest.json"

EXPECTED_ROWS = 14_230
EXPECTED_RD_ROWS = 566_672
EXPECTED_ADDED_KEYS = 1_780
EXPECTED_REMOVED_KEYS = 0
EXPECTED_SHARED_CHANGED_DESCRIPTION = 0
EXPECTED_SHARED_CHANGED_PAYLOAD = 0
EXPECTED_UNMATCHED_201901_KEYS = 349
EXPECTED_CODE_LENGTH_COUNTS = Counter({3: 2_042, 4: 12_188})


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json(path: Path) -> dict:
    if not path.exists():
        raise RuntimeError(f"Arquivo de evidência ausente: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def verify_prior_evidence() -> tuple[dict, dict]:
    sample = load_json(SAMPLE_MANIFEST_PATH)
    coverage = load_json(COVERAGE_PATH)

    if sample.get("status") != "PASS":
        raise RuntimeError("Manifesto da amostra CID-10 não está PASS.")

    if coverage.get("status") != "PASS":
        raise RuntimeError("Análise de cobertura CID-10 não está PASS.")

    ref_diff = coverage["references"]["diff"]
    rd = coverage["rd"]
    overall = rd["overall"]
    unmatched = coverage["unmatched_against_201901"]

    checks = {
        "coverage_rd_rows": rd["rows"] == EXPECTED_RD_ROWS,
        "added_keys": ref_diff["added_raw_keys"] == EXPECTED_ADDED_KEYS,
        "removed_keys": ref_diff["removed_raw_keys"] == EXPECTED_REMOVED_KEYS,
        "shared_changed_description": (
            ref_diff["shared_changed_description"]
            == EXPECTED_SHARED_CHANGED_DESCRIPTION
        ),
        "shared_changed_payload": (
            ref_diff["shared_changed_payload"]
            == EXPECTED_SHARED_CHANGED_PAYLOAD
        ),
        "raw_201912_full_coverage": (
            overall.get("raw_in_201912_matched", 0) == EXPECTED_RD_ROWS
            and overall.get("raw_in_201912_unmatched", 0) == 0
        ),
        "norm_201912_full_coverage": (
            overall.get("norm_in_201912_matched", 0) == EXPECTED_RD_ROWS
            and overall.get("norm_in_201912_unmatched", 0) == 0
        ),
        "unmatched_201901_keys": (
            unmatched["normalized_distinct_keys"] == EXPECTED_UNMATCHED_201901_KEYS
        ),
        "unmatched_all_present_201912": (
            unmatched["normalized_all_present_in_201912"] is True
        ),
    }

    failed = [name for name, ok in checks.items() if not ok]
    if failed:
        raise RuntimeError(
            "Gate C2.6 não sustenta materialização superset. Falhas: "
            + ", ".join(failed)
        )

    return sample, coverage


def parse_layout(path: Path) -> list[dict[str, object]]:
    if not path.exists():
        raise RuntimeError(f"Layout CID ausente: {path}")

    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        fields = [
            {
                "name": row["Coluna"],
                "size": int(row["Tamanho"]),
                "start": int(row["Inicio"]),
                "end": int(row["Fim"]),
                "type": row["Tipo"],
            }
            for row in reader
        ]

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
        raise RuntimeError(f"Layout CID inesperado: {actual}")

    return fields


def verify_sample_hash(sample: dict) -> None:
    materialized = {
        item["competence"]: item
        for item in sample.get("materialized", [])
    }
    if CID_COMPETENCE not in materialized:
        raise RuntimeError(
            f"Competência {CID_COMPETENCE} ausente no manifesto da amostra."
        )

    item = materialized[CID_COMPETENCE]
    expected_cid_hash = item["tb_cid"]["sha256"]
    expected_layout_hash = item["tb_cid_layout"]["sha256"]

    actual_cid_hash = sha256_file(CID_PATH)
    actual_layout_hash = sha256_file(LAYOUT_PATH)

    if actual_cid_hash != expected_cid_hash:
        raise RuntimeError(
            "Hash local de tb_cid.txt diverge do manifesto C2.4. "
            f"esperado={expected_cid_hash} atual={actual_cid_hash}"
        )

    if actual_layout_hash != expected_layout_hash:
        raise RuntimeError(
            "Hash local de tb_cid_layout.txt diverge do manifesto C2.4. "
            f"esperado={expected_layout_hash} atual={actual_layout_hash}"
        )


def materialize(layout: list[dict[str, object]]) -> tuple[list[dict[str, str]], Counter[int]]:
    if not CID_PATH.exists():
        raise RuntimeError(f"Referência CID ausente: {CID_PATH}")

    rows: list[dict[str, str]] = []
    seen_codes: set[str] = set()
    length_counts: Counter[int] = Counter()

    with CID_PATH.open("r", encoding="cp1252", newline="") as handle:
        for line_number, raw_line in enumerate(handle, start=1):
            line = raw_line.rstrip("\r\n")
            if len(line) != 111:
                raise RuntimeError(
                    f"Linha {line_number} possui comprimento {len(line)}, esperado=111"
                )

            parsed: dict[str, str] = {}
            for field in layout:
                start = int(field["start"]) - 1
                end = int(field["end"])
                parsed[str(field["name"])] = line[start:end]

            raw_code = parsed["CO_CID"]
            code = raw_code.rstrip(" ")
            description = parsed["NO_CID"].rstrip(" ")

            if len(code) not in (3, 4):
                raise RuntimeError(
                    f"CO_CID normalizado com tamanho inesperado na linha {line_number}: {code!r}"
                )
            if not code.isalnum() or code.upper() != code:
                raise RuntimeError(
                    f"CO_CID normalizado inválido na linha {line_number}: {code!r}"
                )
            if code in seen_codes:
                raise RuntimeError(f"CO_CID normalizado duplicado: {code}")
            if not description:
                raise RuntimeError(f"NO_CID vazio para {code}")

            seen_codes.add(code)
            length_counts[len(code)] += 1

            rows.append(
                {
                    "codigo_cid10": code,
                    "descricao": description,
                    "competencia_referencia": CID_COMPETENCE,
                    "fonte_arquivo": "tb_cid.txt",
                }
            )

    if len(rows) != EXPECTED_ROWS:
        raise RuntimeError(
            f"Quantidade CID divergente: esperado={EXPECTED_ROWS} atual={len(rows)}"
        )

    if len(seen_codes) != EXPECTED_ROWS:
        raise RuntimeError(
            f"Cardinalidade CID divergente: esperado={EXPECTED_ROWS} atual={len(seen_codes)}"
        )

    if length_counts != EXPECTED_CODE_LENGTH_COUNTS:
        raise RuntimeError(
            "Distribuição de tamanho CID inesperada após remoção do padding: "
            + json.dumps(
                {str(k): v for k, v in sorted(length_counts.items())},
                ensure_ascii=False,
            )
            + " esperado="
            + json.dumps(
                {
                    str(k): v
                    for k, v in sorted(EXPECTED_CODE_LENGTH_COUNTS.items())
                },
                ensure_ascii=False,
            )
        )

    return rows, length_counts


def write_csv(rows: list[dict[str, str]]) -> None:
    with OUTPUT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "codigo_cid10",
                "descricao",
                "competencia_referencia",
                "fonte_arquivo",
            ],
            delimiter=";",
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    sample, coverage = verify_prior_evidence()
    verify_sample_hash(sample)
    layout = parse_layout(LAYOUT_PATH)
    rows, length_counts = materialize(layout)
    write_csv(rows)

    source_cid_hash = sha256_file(CID_PATH)
    source_layout_hash = sha256_file(LAYOUT_PATH)
    output_hash = sha256_file(OUTPUT_CSV)

    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C2_CID10_FINAL_MATERIALIZATION",
        "status": "PASS",
        "decision": {
            "type": "STATIC_DESCRIPTIVE_SUPERSET",
            "reference_competence": CID_COMPETENCE,
            "scope": "descricao de DIAG_PRINC para o Data Mart 2017-2019",
            "does_not_assert": "vigencia historica mensal de cada codigo CID-10",
            "evidence": {
                "rd_rows_covered_201912": EXPECTED_RD_ROWS,
                "shared_changed_description": 0,
                "shared_changed_payload": 0,
                "added_keys_201912_vs_201901": EXPECTED_ADDED_KEYS,
                "removed_keys_201912_vs_201901": 0,
                "unmatched_201901_distinct_normalized_keys": (
                    coverage["unmatched_against_201901"]["normalized_distinct_keys"]
                ),
                "unmatched_201901_all_present_201912": (
                    coverage["unmatched_against_201901"][
                        "normalized_all_present_in_201912"
                    ]
                ),
            },
        },
        "source": {
            "competence": CID_COMPETENCE,
            "tb_cid_path": str(CID_PATH),
            "tb_cid_sha256": source_cid_hash,
            "tb_cid_layout_path": str(LAYOUT_PATH),
            "tb_cid_layout_sha256": source_layout_hash,
            "encoding": "cp1252",
            "line_length": 111,
            "code_field": {
                "name": "CO_CID",
                "start": 1,
                "end": 4,
                "normalization": "rstrip ASCII SPACE U+0020 only",
            },
            "description_field": {
                "name": "NO_CID",
                "start": 5,
                "end": 104,
                "normalization": "rstrip ASCII SPACE U+0020",
            },
        },
        "output": {
            "path": str(OUTPUT_CSV),
            "rows": len(rows),
            "distinct_codes": len(rows),
            "normalized_code_length_counts": {
                str(k): v for k, v in sorted(length_counts.items())
            },
            "sha256": output_hash,
        },
    }

    OUTPUT_MANIFEST.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"REFERENCE_COMPETENCE={CID_COMPETENCE}")
    print(f"CID_ROWS={len(rows)}")
    print(f"CID_DISTINCT_CODES={len(rows)}")
    print(
        "CID_CODE_LENGTH_COUNTS="
        + json.dumps(
            {str(k): v for k, v in sorted(length_counts.items())},
            ensure_ascii=False,
        )
    )
    print(f"RD_COVERAGE_EVIDENCE_ROWS={EXPECTED_RD_ROWS}")
    print(f"SHARED_CHANGED_DESCRIPTION=0")
    print(f"SHARED_CHANGED_PAYLOAD=0")
    print(f"OUTPUT={OUTPUT_CSV}")
    print(f"OUTPUT_SHA256={output_hash}")
    print(f"MANIFEST={OUTPUT_MANIFEST}")
    print("DECISION=STATIC_DESCRIPTIVE_SUPERSET")
    print("VERDICT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
