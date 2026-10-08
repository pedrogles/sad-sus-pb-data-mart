#!/usr/bin/env python3
"""C3.4a: prepara CSV candidato SIGTAP por competência para staging QlikView.

Lê somente arquivos locais já validados em C3.3b.1/C3.3b.2.
Preserva código/competência como texto, cria chave operacional alfanumérica
YYYYMM|CO_PROCEDIMENTO e usa NO_PROCEDIMENTO físico para descrição.

A decodificação cp1252 de NO_PROCEDIMENTO permanece HIPÓTESE e exige
revisão visual de acentos antes de implementar o Qlik C3.4b.

Saídas locais ignoradas:
- BASE/REFERENCIAS/sigtap_procedimento_staging_candidate.csv
- BASE/REFERENCIAS/sigtap_procedimento_staging_candidate_manifest.json
"""

from __future__ import annotations

import csv
import hashlib
import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from materialize_sigtap_procedure_sample import parse_layout, sha256_file

ROOT = Path("BASE/REFERENCIAS")
TABLE_ROOT = ROOT / "SIGTAP/PROCEDIMENTO"
HISTORY_PATH = ROOT / "sigtap_procedure_history_manifest.json"
COVERAGE_PATH = ROOT / "sigtap_procedure_full_coverage_summary.json"
OUTPUT_CSV = ROOT / "sigtap_procedimento_staging_candidate.csv"
OUTPUT_MANIFEST = ROOT / "sigtap_procedimento_staging_candidate_manifest.json"
EXPECTED_MONTHS = tuple(
    f"{year}{month:02d}"
    for year in (2017, 2018, 2019)
    for month in range(1, 13)
)
EXPECTED_REFERENCE_ROWS = 165_203
EXPECTED_RD_ROWS = 566_672
EXPECTED_LAYOUT_HASH = (
    "75641d897c8205d3d2e94ddb96431d51bf7a9ed5871ba0645484715cffffb88a"
)
FIELDS = [
    "SIGTAP_COMPETENCIA",
    "SIGTAP_CO_PROCEDIMENTO",
    "SIGTAP_NO_PROCEDIMENTO",
    "SIGTAP_COMPETENCIA_CODIGO",
]


def load_json(path: Path) -> dict:
    if not path.is_file():
        raise RuntimeError(f"Manifesto obrigatório ausente: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def verify_inputs() -> tuple[dict[str, dict], dict[str, dict]]:
    history = load_json(HISTORY_PATH)
    coverage = load_json(COVERAGE_PATH)
    if (
        history.get("stage")
        != "PHASE_III_C3_3B1_SIGTAP_PROCEDURE_HISTORY_ACQUISITION"
        or history.get("status") != "PASS"
        or history.get("counts", {}).get("competences") != 36
        or history.get("counts", {}).get("total_procedure_rows")
        != EXPECTED_REFERENCE_ROWS
        or history.get("layout", {}).get("sha256") != EXPECTED_LAYOUT_HASH
        or history.get("layout", {}).get("record_width") != 330
    ):
        raise RuntimeError("Aquisição histórica C3.3b.1 não comprovada")

    inventory = history.get("outputs", {}).get("inventory", {})
    inventory_path = ROOT / "sigtap_procedure_history_inventory.csv"
    if (
        Path(inventory.get("path", "")) != inventory_path
        or inventory.get("rows") != 36
        or sha256_file(inventory_path) != inventory["sha256"]
    ):
        raise RuntimeError("Inventário histórico SIGTAP ausente/divergente")

    totals = coverage.get("totals", {})
    if (
        coverage.get("stage")
        != "PHASE_III_C3_3B2_SIGTAP_PROCEDURE_FULL_COVERAGE"
        or coverage.get("status") != "PASS"
        or coverage.get("t27", {}).get("gate") != "PASS"
        or totals.get("competences") != 36
        or totals.get("rd_rows") != EXPECTED_RD_ROWS
        or totals.get("matched_rd_rows") != EXPECTED_RD_ROWS
        or totals.get("unmatched_rd_rows") != 0
        or totals.get("reference_procedure_month_rows")
        != EXPECTED_REFERENCE_ROWS
    ):
        raise RuntimeError("T27 integral C3.3b.2 não comprovado")
    for kind, name in (
        ("coverage", "sigtap_procedure_full_coverage.csv"),
        ("unmatched", "sigtap_procedure_full_unmatched.csv"),
    ):
        record = coverage.get("outputs", {}).get(kind, {})
        path = ROOT / name
        if (
            Path(record.get("path", "")) != path
            or not path.is_file()
            or sha256_file(path) != record.get("sha256")
        ):
            raise RuntimeError(f"Saída C3.3b.2 divergente: {kind}")

    by_month = {}
    for item in history.get("materialized", []):
        competence = str(item["competence"])
        if competence in by_month:
            raise RuntimeError(f"Competência duplicada: {competence}")
        by_month[competence] = item
    if set(by_month) != set(EXPECTED_MONTHS):
        raise RuntimeError("Histórico SIGTAP sem as 36 competências esperadas")

    monthly = {}
    for item in coverage.get("monthly", []):
        competence = str(item["competence"])
        if competence in monthly:
            raise RuntimeError(f"Competência duplicada no T27: {competence}")
        monthly[competence] = item
    if set(monthly) != set(EXPECTED_MONTHS):
        raise RuntimeError("Relatório T27 não abrange os 36 meses")
    return by_month, monthly


def column(columns: list[dict], name: str, width: int, start: int, end: int) -> dict:
    found = [item for item in columns if item["field"] == name]
    if (
        len(found) != 1
        or int(found[0]["width"]) != width
        or int(found[0]["start"]) != start
        or int(found[0]["end"]) != end
    ):
        raise RuntimeError(f"Layout físico inesperado para {name}")
    return found[0]


def main() -> int:
    by_month, monthly = verify_inputs()
    ROOT.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(
        prefix="_sigtap_stage_", suffix=".csv", dir=ROOT
    )
    os.close(fd)
    temp_path = Path(temp_name)
    unique_keys: set[str] = set()
    counts = []
    review_examples: list[dict[str, str]] = []
    total = 0
    non_ascii_names = 0
    try:
        with temp_path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(
                handle, fieldnames=FIELDS, delimiter=";", lineterminator="\n"
            )
            writer.writeheader()
            for competence in EXPECTED_MONTHS:
                evidence = by_month[competence]
                folder = TABLE_ROOT / competence
                layout_path = folder / "tb_procedimento_layout.txt"
                source_path = folder / "tb_procedimento.txt"
                if (
                    Path(evidence["layout_path"]) != layout_path
                    or Path(evidence["procedure_path"]) != source_path
                    or not layout_path.is_file() or not source_path.is_file()
                    or sha256_file(layout_path) != evidence["layout_sha256"]
                    or sha256_file(source_path) != evidence["procedure_sha256"]
                ):
                    raise RuntimeError(f"Referência local diverge do manifesto: {competence}")
                columns = parse_layout(layout_path.read_bytes(), competence)
                column(columns, "CO_PROCEDIMENTO", 10, 1, 10)
                column(columns, "NO_PROCEDIMENTO", 250, 11, 260)
                column(columns, "DT_COMPETENCIA", 6, 325, 330)
                if len(columns) != 16 or int(columns[-1]["end"]) != 330:
                    raise RuntimeError(f"Layout divergente em {competence}")
                month_rows = 0
                description_examples = 0
                with source_path.open("rb") as source:
                    for lineno, original in enumerate(source, start=1):
                        raw = original.rstrip(b"\r\n")
                        if len(raw) != 330:
                            raise RuntimeError(
                                f"Comprimento inválido: {competence}:{lineno}"
                            )
                        code_raw = raw[:10]
                        if not all(48 <= value <= 57 for value in code_raw):
                            raise RuntimeError(
                                f"Procedimento inválido: {competence}:{lineno}"
                            )
                        if raw[324:330] != competence.encode("ascii"):
                            raise RuntimeError(
                                f"Competência divergente: {competence}:{lineno}"
                            )
                        code = code_raw.decode("ascii")
                        key = f"{competence}|{code}"
                        if key in unique_keys:
                            raise RuntimeError(f"Chave código/competência duplicada: {key}")
                        unique_keys.add(key)
                        description = raw[10:260].decode("cp1252").rstrip(" ")
                        if not description or any(
                            ord(c) < 32 or 127 <= ord(c) <= 159
                            for c in description
                        ):
                            raise RuntimeError(
                                f"Descrição vazia/com controle: {competence}:{lineno}"
                            )
                        if any(ord(c) > 127 for c in description):
                            non_ascii_names += 1
                            if description_examples < 2:
                                review_examples.append({
                                    "competence": competence,
                                    "code": code,
                                    "description_cp1252": description,
                                })
                                description_examples += 1
                        writer.writerow({
                            "SIGTAP_COMPETENCIA": competence,
                            "SIGTAP_CO_PROCEDIMENTO": code,
                            "SIGTAP_NO_PROCEDIMENTO": description,
                            "SIGTAP_COMPETENCIA_CODIGO": key,
                        })
                        month_rows += 1
                        total += 1
                if (
                    month_rows != int(evidence["procedure_rows"])
                    or month_rows != int(monthly[competence]["reference_rows"])
                ):
                    raise RuntimeError(
                        f"Contagem mensal divergente: {competence}, "
                        f"contado={month_rows}"
                    )
                counts.append({
                    "competence": competence,
                    "rows": month_rows,
                })
                print(f"[{competence}] REFERENCE_ROWS={month_rows} STRUCTURE_PASS")

        if total != EXPECTED_REFERENCE_ROWS or len(unique_keys) != total:
            raise RuntimeError("Reconciliação final SIGTAP divergente")

        os.replace(temp_path, OUTPUT_CSV)
        manifest = {
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "stage": "PHASE_III_C3_4A_SIGTAP_CSV_STAGE_PREPARATION",
            "status": "STRUCTURE_PASS_ENCODING_REVIEW",
            "source": "OFFICIAL_SIGTAP_36_COMPETENCES_VALIDATED_T27_PASS",
            "physical_fields": [
                "DT_COMPETENCIA",
                "CO_PROCEDIMENTO",
                "NO_PROCEDIMENTO",
            ],
            "lookup_key": "SIGTAP_COMPETENCIA|SIGTAP_CO_PROCEDIMENTO",
            "rows": total,
            "distinct_code_month_keys": len(unique_keys),
            "competences": len(counts),
            "monthly": counts,
            "description_encoding": {
                "candidate": "cp1252",
                "visually_approved": False,
                "non_ascii_description_rows": non_ascii_names,
                "sample": review_examples,
            },
            "outputs": {
                "csv": str(OUTPUT_CSV),
                "sha256": sha256_file(OUTPUT_CSV),
                "rows": total,
            },
            "scope": {
                "t27_pass_verified_as_prerequisite": True,
                "qvd_generated": False,
                "full_qlik_staging_gate_passed": False,
                "dimensional_model_created": False,
            },
        }
        OUTPUT_MANIFEST.write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
    finally:
        if temp_path.exists():
            temp_path.unlink()

    print(f"REFERENCE_ROWS={total}")
    print(f"COMPETENCES={len(counts)}")
    print(f"CODE_MONTH_KEYS={len(unique_keys)}")
    print(f"NON_ASCII_DESCRIPTIONS={non_ascii_names}")
    print(f"CSV={OUTPUT_CSV}")
    print(f"CSV_SHA256={sha256_file(OUTPUT_CSV)}")
    print(f"MANIFEST={OUTPUT_MANIFEST}")
    print("ENCODING_VISUAL_REVIEW=PENDING")
    print("QLIK_QVD=NOT_GENERATED")
    print("VERDICT=STRUCTURE_PASS_ENCODING_REVIEW")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
