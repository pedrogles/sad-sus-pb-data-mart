#!/usr/bin/env python3
"""III-C3.3b.2 — cobertura histórica PROC_REA x SIGTAP por competência.

Verifica todos os 36 meses SIH/RD (566672 linhas) contra os 36 arquivos
tb_procedimento.txt do SIGTAP (2017–2019), preservando códigos de 10
dígitos como TEXTO. Confere os manifestos C3.1, C3.3a.1 e C3.3b.1
e os arquivos locais por SHA-256 antes de reconciliar.

Nenhum download, escrita em fontes, QVD, modelo dimensional ou painel.

Saídas locais ignoradas pelo Git em BASE/REFERENCIAS:
- sigtap_procedure_full_coverage.csv
- sigtap_procedure_full_unmatched.csv
- sigtap_procedure_full_coverage_summary.json
"""

from __future__ import annotations

import csv
import hashlib
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from materialize_sigtap_procedure_sample import parse_layout, sha256_file

REFERENCE_ROOT = Path("BASE/REFERENCIAS")
RD_ROOT = Path("BASE/CONVERTIDA/RD")
TABLE_ROOT = REFERENCE_ROOT / "SIGTAP/PROCEDIMENTO"
RD_PROFILE_PATH = REFERENCE_ROOT / "proc_rea_profile_summary.json"
PILOT_SUMMARY_PATH = REFERENCE_ROOT / "sigtap_procedure_pilot_summary.json"
HISTORY_MANIFEST_PATH = REFERENCE_ROOT / "sigtap_procedure_history_manifest.json"
COVERAGE_PATH = REFERENCE_ROOT / "sigtap_procedure_full_coverage.csv"
UNMATCHED_PATH = REFERENCE_ROOT / "sigtap_procedure_full_unmatched.csv"
SUMMARY_PATH = REFERENCE_ROOT / "sigtap_procedure_full_coverage_summary.json"
COMPETENCES = tuple(
    f"{year}{month:02d}"
    for year in (2017, 2018, 2019)
    for month in range(1, 13)
)
EXPECTED_RD_ROWS = 566_672
EXPECTED_SIGTAP_ROWS = 165_203
EXPECTED_PILOT_RD_ROWS = 59_365
SAMPLE_COMPETENCES = ("201701", "201801", "201901", "201912")


def load_json(path: Path) -> dict:
    if not path.is_file():
        raise RuntimeError(f"Manifesto ausente: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def checked_sha(path: Path, sha256: str) -> None:
    if not path.is_file():
        raise RuntimeError(f"Arquivo ausente: {path}")
    actual = sha256_file(path)
    if actual != sha256:
        raise RuntimeError(
            f"SHA-256 divergente: {path}; esperado={sha256} atual={actual}"
        )


def require_month_map(rows: list[dict], key: str, expected: tuple[str, ...]) -> dict[str, dict]:
    by_month: dict[str, dict] = {}
    for row in rows:
        competence = str(row[key])
        if competence in by_month:
            raise RuntimeError(f"Competência duplicada: {competence}")
        by_month[competence] = row
    if set(by_month) != set(expected):
        raise RuntimeError(
            "Competências ausentes/inesperadas: "
            f"missing={sorted(set(expected) - set(by_month))}, "
            f"extra={sorted(set(by_month) - set(expected))}"
        )
    return by_month


def validate_inputs() -> tuple[dict[str, dict], dict[str, int], dict[str, dict]]:
    profile = load_json(RD_PROFILE_PATH)
    pilot = load_json(PILOT_SUMMARY_PATH)
    history = load_json(HISTORY_MANIFEST_PATH)

    if (
        profile.get("stage") != "PHASE_III_C3_1_PROC_REA_INPUT_PROFILE"
        or profile.get("status") != "PASS"
        or profile.get("input", {}).get("files") != 36
        or profile.get("input", {}).get("competences") != 36
        or profile.get("input", {}).get("rows") != EXPECTED_RD_ROWS
    ):
        raise RuntimeError("Gate C3.1 não comprovado")

    profile_outputs = profile.get("outputs", {})
    for name in ("raw_profile", "monthly_profile"):
        record = profile_outputs.get(name, {})
        path = REFERENCE_ROOT / (
            "proc_rea_raw_profile.csv" if name == "raw_profile"
            else "proc_rea_monthly_profile.csv"
        )
        if Path(record.get("path", "")) != path:
            raise RuntimeError(f"Caminho inesperado no C3.1: {name}")
        checked_sha(path, record["sha256"])

    monthly_expected = {
        str(k): int(v)
        for k, v in profile["monthly"]["rows_by_competence"].items()
    }
    distinct_expected = {
        str(k): int(v)
        for k, v in profile["monthly"]["distinct_by_competence"].items()
    }
    if (
        set(monthly_expected) != set(COMPETENCES)
        or set(distinct_expected) != set(COMPETENCES)
        or sum(monthly_expected.values()) != EXPECTED_RD_ROWS
    ):
        raise RuntimeError("Contagens mensais C3.1 não reconciliadas")

    if (
        pilot.get("status") != "PASS"
        or pilot.get("stage")
        != "PHASE_III_C3_3A1_PROCEDURE_FOUR_MONTH_COVERAGE_PILOT"
        or set(pilot.get("sample_competences", [])) != set(SAMPLE_COMPETENCES)
        or pilot.get("totals", {}).get("rd_rows") != EXPECTED_PILOT_RD_ROWS
        or pilot.get("totals", {}).get("matched_rd_rows") != EXPECTED_PILOT_RD_ROWS
        or pilot.get("totals", {}).get("unmatched_rd_rows") != 0
    ):
        raise RuntimeError("Gate C3.3a.1 não comprovado")
    for name, filename in (
        ("coverage", "sigtap_procedure_pilot_coverage.csv"),
        ("unmatched", "sigtap_procedure_pilot_unmatched.csv"),
    ):
        record = pilot.get("outputs", {}).get(name, {})
        path = REFERENCE_ROOT / filename
        if Path(record.get("path", "")) != path:
            raise RuntimeError(f"Caminho piloto divergente: {name}")
        checked_sha(path, record["sha256"])
    pilot_months = require_month_map(
        pilot.get("monthly", []), "competence", SAMPLE_COMPETENCES
    )

    if (
        history.get("status") != "PASS"
        or history.get("stage")
        != "PHASE_III_C3_3B1_SIGTAP_PROCEDURE_HISTORY_ACQUISITION"
        or history.get("mode") != "CONTROLLED_HISTORICAL_PROCEDURE_ACQUISITION"
        or history.get("counts", {}).get("competences") != 36
        or history.get("counts", {}).get("sample_months_reused") != 4
        or history.get("counts", {}).get("new_packages_downloaded") != 32
        or history.get("counts", {}).get("total_procedure_rows")
        != EXPECTED_SIGTAP_ROWS
        or history.get("layout", {}).get("field_count") != 16
        or history.get("layout", {}).get("record_width") != 330
        or history.get("layout", {}).get("identical_all_36_months") is not True
    ):
        raise RuntimeError("Gate C3.3b.1 não comprovado")

    inventory_record = history.get("outputs", {}).get("inventory", {})
    inventory_path = REFERENCE_ROOT / "sigtap_procedure_history_inventory.csv"
    if (
        Path(inventory_record.get("path", "")) != inventory_path
        or inventory_record.get("rows") != 36
    ):
        raise RuntimeError("Inventário histórico divergente")
    checked_sha(inventory_path, inventory_record["sha256"])
    with inventory_path.open("r", encoding="utf-8", newline="") as handle:
        inventory_reader = csv.DictReader(handle, delimiter=";")
        if inventory_reader.fieldnames is None:
            raise RuntimeError("Inventário histórico sem cabeçalho")
        inventory_months = require_month_map(
            list(inventory_reader), "competence", COMPETENCES
        )
    materialized = require_month_map(
        history.get("materialized", []), "competence", COMPETENCES
    )
    for competence in COMPETENCES:
        record = materialized[competence]
        row = inventory_months[competence]
        for name in (
            "package_filename", "package_sha256", "procedure_sha256",
            "layout_sha256", "procedure_rows", "distinct_procedures",
            "layout_width", "invalid_key_rows", "invalid_length_rows",
            "duplicate_keys", "wrong_competence_rows",
        ):
            if str(record[name]) != str(row[name]):
                raise RuntimeError(
                    f"Inventário vs manifesto: {competence} / {name}"
                )
        if record["layout_sha256"] != history["layout"]["sha256"]:
            raise RuntimeError(f"Layout SHA diferente: {competence}")
    return materialized, monthly_expected, distinct_expected, pilot_months


def read_procedure_keys(competence: str, record: dict) -> set[str]:
    directory = TABLE_ROOT / competence
    layout_path = directory / "tb_procedimento_layout.txt"
    procedure_path = directory / "tb_procedimento.txt"
    if (
        Path(record["layout_path"]) != layout_path
        or Path(record["procedure_path"]) != procedure_path
    ):
        raise RuntimeError(f"Paths físicos fora do contrato: {competence}")
    checked_sha(layout_path, record["layout_sha256"])
    checked_sha(procedure_path, record["procedure_sha256"])
    fields = parse_layout(layout_path.read_bytes(), competence)
    if len(fields) != 16 or int(fields[-1]["end"]) != 330:
        raise RuntimeError(f"Layout inesperado: {competence}")

    co = [f for f in fields if f["field"] == "CO_PROCEDIMENTO"]
    dt = [f for f in fields if f["field"] == "DT_COMPETENCIA"]
    if (
        len(co) != 1 or len(dt) != 1
        or co[0]["width"] != 10 or co[0]["start"] != 1
        or dt[0]["width"] != 6 or dt[0]["start"] != 325
    ):
        raise RuntimeError(f"Chaves físicas SIGTAP inesperadas: {competence}")

    codes: set[str] = set()
    lines = 0
    with procedure_path.open("rb") as handle:
        for raw_line in handle:
            raw = raw_line.rstrip(b"\r\n")
            lines += 1
            if len(raw) != 330:
                raise RuntimeError(
                    f"Comprimento SIGTAP inválido: {competence} linha {lines}"
                )
            key_bytes = raw[0:10]
            if len(key_bytes) != 10 or not all(48 <= b <= 57 for b in key_bytes):
                raise RuntimeError(
                    f"CO_PROCEDIMENTO inválido: {competence} linha {lines}"
                )
            if raw[324:330] != competence.encode("ascii"):
                raise RuntimeError(
                    f"DT_COMPETENCIA inválida: {competence} linha {lines}"
                )
            code = key_bytes.decode("ascii")
            if code in codes:
                raise RuntimeError(
                    f"CO_PROCEDIMENTO duplicado: {competence}/{code}"
                )
            codes.add(code)

    if (
        lines != int(record["procedure_rows"])
        or len(codes) != int(record["distinct_procedures"])
        or int(record["invalid_key_rows"]) != 0
        or int(record["invalid_length_rows"]) != 0
        or int(record["duplicate_keys"]) != 0
        or int(record["wrong_competence_rows"]) != 0
    ):
        raise RuntimeError(f"Contagens da referência divergentes: {competence}")

    return codes


def profile_month(
    competence: str, reference_codes: set[str],
    expected_rd_rows: int, expected_rd_distinct: int,
) -> tuple[dict, Counter[str]]:
    rd_path = RD_ROOT / f"RDPB{competence[2:]}.csv"
    if not rd_path.is_file():
        raise RuntimeError(f"CSV RD ausente: {rd_path}")

    occurrences: Counter[str] = Counter()
    unmatched: Counter[str] = Counter()
    rd_rows = 0
    matched_rows = 0
    with rd_path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle, delimiter=";")
        if (
            reader.fieldnames is None
            or reader.fieldnames.count("PROC_REA") != 1
        ):
            raise RuntimeError(f"Campo PROC_REA ausente ou duplicado: {rd_path}")
        for row in reader:
            code = row["PROC_REA"]
            if (
                code is None
                or len(code) != 10
                or not code.isascii()
                or not code.isdecimal()
            ):
                raise RuntimeError(
                    f"PROC_REA inesperado: {rd_path}, linha {reader.line_num}, "
                    f"valor={code!r}"
                )
            rd_rows += 1
            occurrences[code] += 1
            if code in reference_codes:
                matched_rows += 1
            else:
                unmatched[code] += 1

    if rd_rows != expected_rd_rows or len(occurrences) != expected_rd_distinct:
        raise RuntimeError(
            f"RD diferente de C3.1 em {competence}: "
            f"rows={rd_rows}/{expected_rd_rows}, "
            f"distinct={len(occurrences)}/{expected_rd_distinct}"
        )
    return (
        {
            "competence": competence,
            "rd_rows": rd_rows,
            "rd_distinct_codes": len(occurrences),
            "reference_rows": len(reference_codes),
            "matched_rd_rows": matched_rows,
            "unmatched_rd_rows": rd_rows - matched_rows,
            "unmatched_distinct_codes": len(unmatched),
            "coverage_pct": f"{matched_rows * 100 / rd_rows:.6f}",
        },
        unmatched,
    )


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle, fieldnames=fields, delimiter=";", lineterminator="\n"
        )
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    history, monthly_expected, distinct_expected, pilot = validate_inputs()
    monthly: list[dict] = []
    unmatched_rows: list[dict] = []
    unique_codes: set[str] = set()
    observed_code_months = 0
    print("MODE=LOCAL_36_COMPETENCE_SIGTAP_COVERAGE")
    print("COMPETENCES=36")
    for competence in COMPETENCES:
        reference_codes = read_procedure_keys(competence, history[competence])
        row, unmatched = profile_month(
            competence, reference_codes,
            monthly_expected[competence], distinct_expected[competence]
        )
        observed_code_months += row["rd_distinct_codes"]
        # Reconciliar novamente os quatro meses do piloto anterior.
        if competence in pilot:
            expected = pilot[competence]
            if (
                row["rd_rows"] != int(expected["rd_rows"])
                or row["matched_rd_rows"] != int(expected["matched_rows"])
                or row["unmatched_rd_rows"] != int(expected["unmatched_rows"])
            ):
                raise RuntimeError(
                    f"Regressão versus piloto C3.3a.1: {competence}"
                )
        monthly.append(row)
        for code, occurrences in sorted(unmatched.items()):
            unmatched_rows.append(
                {
                    "competence": competence,
                    "proc_rea_raw": code,
                    "unmatched_occurrences": occurrences,
                }
            )
        print(
            f"[{competence}] RD_ROWS={row['rd_rows']} "
            f"MATCHED={row['matched_rd_rows']} "
            f"UNMATCHED={row['unmatched_rd_rows']} "
            f"UNMATCHED_CODES={row['unmatched_distinct_codes']} "
            f"REFERENCE_CODES={row['reference_rows']}"
        )

    total_rd = sum(row["rd_rows"] for row in monthly)
    total_matched = sum(row["matched_rd_rows"] for row in monthly)
    total_unmatched = sum(row["unmatched_rd_rows"] for row in monthly)
    total_reference_rows = sum(row["reference_rows"] for row in monthly)
    if (
        len(monthly) != 36
        or total_rd != EXPECTED_RD_ROWS
        or total_reference_rows != EXPECTED_SIGTAP_ROWS
        or total_matched + total_unmatched != total_rd
        or total_unmatched != sum(
            int(row["unmatched_occurrences"]) for row in unmatched_rows
        )
    ):
        raise RuntimeError("Falha de reconciliação global C3.3b.2")

    verdict = "PASS" if total_unmatched == 0 else "REVIEW"
    REFERENCE_ROOT.mkdir(parents=True, exist_ok=True)
    write_csv(
        COVERAGE_PATH,
        [
            "competence", "rd_rows", "rd_distinct_codes", "reference_rows",
            "matched_rd_rows", "unmatched_rd_rows",
            "unmatched_distinct_codes", "coverage_pct",
        ],
        monthly,
    )
    write_csv(
        UNMATCHED_PATH,
        ["competence", "proc_rea_raw", "unmatched_occurrences"],
        unmatched_rows,
    )
    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C3_3B2_SIGTAP_PROCEDURE_FULL_COVERAGE",
        "status": verdict,
        "mode": "LOCAL_36_COMPETENCE_SIGTAP_COVERAGE",
        "join": "RD(competence, PROC_REA) = SIGTAP(DT_COMPETENCIA, CO_PROCEDIMENTO)",
        "normalization": "NONE; EXACT_RAW_TEN_ASCII_DIGIT_TEXT",
        "inputs": {
            "history_manifest": str(HISTORY_MANIFEST_PATH),
            "rd_profile": str(RD_PROFILE_PATH),
            "pilot_summary": str(PILOT_SUMMARY_PATH),
        },
        "totals": {
            "competences": len(monthly),
            "rd_rows": total_rd,
            "reference_procedure_month_rows": total_reference_rows,
            "rd_code_competence_pairs": observed_code_months,
            "matched_rd_rows": total_matched,
            "unmatched_rd_rows": total_unmatched,
            "unmatched_code_competence_pairs": len(unmatched_rows),
            "coverage_pct": f"{total_matched * 100 / total_rd:.6f}",
        },
        "monthly": monthly,
        "outputs": {
            "coverage": {
                "path": str(COVERAGE_PATH),
                "rows": len(monthly),
                "sha256": sha256_file(COVERAGE_PATH),
            },
            "unmatched": {
                "path": str(UNMATCHED_PATH),
                "rows": len(unmatched_rows),
                "sha256": sha256_file(UNMATCHED_PATH),
            },
            "summary": str(SUMMARY_PATH),
        },
        "scope": {
            "all_36_competences_evaluated": True,
            "qvd_written": False,
            "reference_schema_enrichment_done": False,
            "dimensional_model_implemented": False,
        },
        "t27": {
            "coverage_measured": True,
            "exceptions_recorded": True,
            "gate": verdict,
        },
    }
    SUMMARY_PATH.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("RD_ROWS=" + str(total_rd))
    print("MATCHED_RD_ROWS=" + str(total_matched))
    print("UNMATCHED_RD_ROWS=" + str(total_unmatched))
    print("UNMATCHED_CODE_COMPETENCE_PAIRS=" + str(len(unmatched_rows)))
    print("REFERENCE_PROCEDURE_MONTH_ROWS=" + str(total_reference_rows))
    print("COVERAGE_CSV=" + str(COVERAGE_PATH))
    print("UNMATCHED_CSV=" + str(UNMATCHED_PATH))
    print("SUMMARY=" + str(SUMMARY_PATH))
    print("T27_GATE=" + verdict)
    print("VERDICT=" + verdict)
    return 0 if verdict == "PASS" else 2


if __name__ == "__main__":
    raise SystemExit(main())
