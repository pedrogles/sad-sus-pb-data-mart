#!/usr/bin/env python3
"""Review VIS-05 capture metadata; never connect to QlikView or modify source artifacts.

Engine probes are not chart-cell exports. No possible output grants global/visual approval.
Pure assess() is tested with synthetic evidence; fixture PASS is not a physical Qlik gate.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any


def integer(raw: Any) -> int | None:
    text = str(raw).strip()
    return int(text) if re.fullmatch(r"-?\d+", text) else None


def normalize(text: str) -> str:
    # Do not strip whitespace inside quoted Qlik literals.
    out = []
    quote = None
    for char in text.strip().lstrip("="):
        if char in "'\"":
            if quote == char:
                quote = None
            elif quote is None:
                quote = char
        if quote is not None or not char.isspace():
            out.append(char)
    return "".join(out)


def definition_candidates(node: Any) -> list[str]:
    if not isinstance(node, dict):
        return []
    properties = node.get("properties", {})
    values = []
    for name in ("Definition", "Def", "Expression"):
        value = properties.get(name)
        if isinstance(value, str):
            values.append(value)
        elif isinstance(value, dict):
            scalar = value.get("properties", {}).get("v")
            if isinstance(scalar, str):
                values.append(scalar)
    return list(dict.fromkeys(values))


def assess(report: dict, contract: dict) -> dict:
    failures: list[str] = []
    unknowns: list[str] = []
    checked: list[str] = []
    if report.get("gate") != contract["gate"]:
        failures.append("GATE_ID_MISMATCH")
    pin = contract["source_sha256"]
    if report.get("source_sha256") != pin or report.get("copy_sha256_after") != pin:
        failures.append("SOURCE_OR_COPY_PIN_MISMATCH")
    if not report.get("integrity_verified") or not report.get("cleanup_ok"):
        failures.append("INTEGRITY_OR_CLEANUP_NOT_VERIFIED")
    before = report.get("protected_before", [])
    after = report.get("protected_after", [])
    for label, rows in (("BEFORE", before), ("AFTER", after)):
        paths = [r.get("path") for r in rows]
        if len(rows) != 26 or len(set(paths)) != 26 or any(not p for p in paths):
            failures.append(f"PROTECTED_{label}_COUNT_OR_IDENTITY")
    by_path = lambda rows: {r.get("path"): (r.get("sha256"), r.get("bytes")) for r in rows}
    if by_path(before) != by_path(after):
        failures.append("PROTECTED_BYTES_CHANGED")
    if str(report.get("status", "")).startswith("BLOCKED"):
        failures.append("RUNNER_BLOCKED:" + str(report.get("failure", report.get("status"))))

    expected_objects = {o["id"]: o for o in contract["objects"]}
    objects = report.get("objects", [])
    ids = [o.get("id") for o in objects]
    if len(ids) != 9 or len(set(ids)) != 9 or set(ids) != set(expected_objects):
        failures.append("NINE_OBJECT_IDENTITIES_NOT_VERIFIED")
    for obj in objects:
        spec = expected_objects.get(obj.get("id"))
        if not spec:
            continue
        if obj.get("sheet") != spec["sheet"]:
            failures.append(f"WRONG_SHEET:{obj['id']}")
        candidates = definition_candidates(obj.get("first_expression_data"))
        if len(candidates) != 1:
            unknowns.append(f"EXPRESSION_READBACK_INCONCLUSIVE:{obj['id']}")
        elif normalize(candidates[0]) != normalize(spec["expression"]):
            failures.append(f"EXPRESSION_DIFFERS_FROM_CONTRACT:{obj['id']}")
        else:
            checked.append(f"FIRST_EXPRESSION:{obj['id']}")

    if report.get("mode") == "Scenarios":
        rows = report.get("scenarios", [])
        ids = [r.get("id") for r in rows]
        if len(ids) != len(set(ids)):
            failures.append("DUPLICATE_SCENARIO")
        observed = {r.get("id"): r for r in rows}
        for spec in contract["scenarios"]:
            case = observed.get(spec["id"])
            if case is None:
                unknowns.append("MISSING_SCENARIO:" + spec["id"])
                continue
            if case.get("selections") != spec["selections"] or not case.get("selection_verified"):
                failures.append("SELECTION_NOT_VERIFIED:" + spec["id"])
            for name, expected in spec["expected"].items():
                raw = case.get("probes", {}).get(name, {}).get("raw")
                if integer(raw) != expected:
                    failures.append(f"ENGINE_ORACLE_MISMATCH:{spec['id']}/{name}")
                else:
                    checked.append(f"ENGINE:{spec['id']}/{name}")
            for name, expected in spec["guards"].items():
                guard = case.get("guards", {}).get(name, {})
                number = integer(guard.get("raw"))
                if guard.get("status") != "READ_BACK" or number not in (-1, 0, 1):
                    unknowns.append(f"GUARD_UNREADABLE:{spec['id']}/{name}")
                elif (number != 0) != expected:
                    failures.append(f"GUARD_MISMATCH:{spec['id']}/{name}")
                else:
                    checked.append(f"GUARD:{spec['id']}/{name}")
    else:
        unknowns.append("SCENARIOS_NOT_RUN_INVENTORY_ONLY")

    # Neither captured images nor COM Evaluate certify plotted label/value correspondence.
    unknowns += [
        "VISUAL_LABEL_CATEGORY_VALUE_REVIEW_PENDING",
        "ERROR_MESSAGE_VISIBLE_TEXT_REVIEW_PENDING",
        "ALL_DIMENSIONS_AND_SECOND_EXPRESSION_NOT_CERTIFIED",
        "LIVE_TABLE_STRUCTURE_NOT_CERTIFIED",
        "ALL_NATIVE_SELECTION_ROUTES_NOT_CERTIFIED",
    ]
    incomplete = any(x.startswith(("MISSING_SCENARIO:", "GUARD_UNREADABLE:")) for x in unknowns)
    verdict = "FAIL_RESTRICTED_INSPECTION" if failures else (
        "INVENTORY_ONLY_REVIEW_PENDING" if report.get("mode") != "Scenarios" else
        "INCONCLUSIVE_INCOMPLETE_EXECUTION" if incomplete else
        "ENGINE_CHECKS_RECONCILED_OTHER_PROOFS_PENDING"
    )
    return {
        "gate": contract["gate"], "verdict": verdict,
        "failures": failures, "inconclusive": unknowns, "checks_verified": checked,
        "evidence_origin": "LOCAL_EXECUTOR_REPORT_NOT_INDEPENDENT_QVW_EXECUTION",
        "visual_approved": False, "global_approved": False, "production_approved": False,
        "manual_sort_status": report.get("manual_sort_status", "NOT_RUN"),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", required=True, type=Path)
    parser.add_argument("--contract", type=Path, default=Path(__file__).resolve().parents[1] / "PAINEL/sad_vis05_readonly_inspection_contract.json")
    args = parser.parse_args()
    content = args.report.read_bytes()
    contract_bytes = args.contract.read_bytes()
    report = json.loads(content.decode("utf-8-sig"))
    contract = json.loads(contract_bytes.decode("utf-8-sig"))
    result = assess(report, contract)
    if report.get("contract_sha256") != hashlib.sha256(contract_bytes).hexdigest().upper():
        result["failures"].append("CONTRACT_BYTES_MISMATCH")
        result["verdict"] = "FAIL_RESTRICTED_INSPECTION"
    result["report_sha256"] = hashlib.sha256(content).hexdigest().upper()
    output = args.report.parent / "assessment.json"
    # A review must not overwrite a prior review/evidence.
    with output.open("x", encoding="utf-8") as handle:
        json.dump(result, handle, ensure_ascii=False, indent=2)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 2 if result["failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
