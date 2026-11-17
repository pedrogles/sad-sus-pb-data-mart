"""Synthetic evidence tests, never physical acceptance of QlikView/VIS-05."""
import copy
import json
from pathlib import Path
import unittest

from review_sad_vis05_inspection import assess, normalize


CONTRACT = json.loads((Path(__file__).resolve().parents[1] / "PAINEL/sad_vis05_readonly_inspection_contract.json").read_text(encoding="utf-8"))


def evidence():
    protected = [{"path": f"protected_{i}", "sha256": "A" * 64, "bytes": i + 1} for i in range(26)]
    return {
        "gate": CONTRACT["gate"], "mode": "Scenarios", "status": "SCENARIOS_ENGINE_CHECKED_VISUAL_REVIEW_PENDING",
        "source_sha256": CONTRACT["source_sha256"], "copy_sha256_after": CONTRACT["source_sha256"],
        "integrity_verified": True, "cleanup_ok": True,
        "protected_before": protected, "protected_after": copy.deepcopy(protected),
        "objects": [{"id": x["id"], "sheet": x["sheet"], "first_expression_data": {"properties": {"Definition": {"properties": {"v": x["expression"]}}}}} for x in CONTRACT["objects"]],
        "scenarios": [{"id": x["id"], "selections": x["selections"], "selection_verified": True,
                       "probes": {k: {"raw": str(v)} for k, v in x["expected"].items()},
                       "guards": {k: {"status": "READ_BACK", "raw": "-1" if v else "0"} for k, v in x["guards"].items()}} for x in CONTRACT["scenarios"]],
    }


class ReviewTests(unittest.TestCase):
    def test_reconciled_numbers_do_not_approve_visual_or_global(self):
        result = assess(evidence(), CONTRACT)
        self.assertEqual(result["failures"], [])
        self.assertFalse(result["visual_approved"])
        self.assertFalse(result["global_approved"])
        self.assertIn("VISUAL_LABEL_CATEGORY_VALUE_REVIEW_PENDING", result["inconclusive"])

    def test_changed_bytes_override_success_flags(self):
        report = evidence()
        report["protected_after"][0]["sha256"] = "B" * 64
        self.assertIn("PROTECTED_BYTES_CHANGED", assess(report, CONTRACT)["failures"])

    def test_duplicate_identity_cannot_mask_missing_chart(self):
        report = evidence()
        report["objects"][-1] = report["objects"][0]
        self.assertIn("NINE_OBJECT_IDENTITIES_NOT_VERIFIED", assess(report, CONTRACT)["failures"])

    def test_numeric_zero_and_missing_are_not_interchangeable(self):
        report = evidence()
        report["scenarios"][0]["probes"]["fi"]["raw"] = "-"
        self.assertTrue(any("ENGINE_ORACLE_MISMATCH" in f for f in assess(report, CONTRACT)["failures"]))

    def test_wrong_effective_guard_is_failure(self):
        report = evidence()
        report["scenarios"][1]["guards"]["CH05"]["raw"] = "-1"
        self.assertIn("GUARD_MISMATCH:YEAR_2018/CH05", assess(report, CONTRACT)["failures"])

    def test_missing_com_readback_is_not_pass(self):
        report = evidence()
        report["objects"][0]["first_expression_data"] = None
        result = assess(report, CONTRACT)
        self.assertIn("EXPRESSION_READBACK_INCONCLUSIVE:CH01", result["inconclusive"])
        self.assertNotIn("FIRST_EXPRESSION:CH01", result["checks_verified"])

    def test_selection_values_must_match_not_just_count(self):
        report = evidence()
        report["scenarios"][1]["selections"] = {"PERIODO_ANO": "2019"}
        self.assertIn("SELECTION_NOT_VERIFIED:YEAR_2018", assess(report, CONTRACT)["failures"])

    def test_missing_case_is_inconclusive(self):
        report = evidence()
        report["scenarios"].pop()
        result = assess(report, CONTRACT)
        self.assertIn("MISSING_SCENARIO:SERV_250750", result["inconclusive"])
        self.assertEqual(result["verdict"], "INCONCLUSIVE_INCOMPLETE_EXECUTION")

    def test_expression_change_is_not_hidden_by_correct_probe(self):
        report = evidence()
        report["objects"][0]["first_expression_data"]["properties"]["Definition"]["properties"]["v"] = "Count(N_AIH)"
        self.assertIn("EXPRESSION_DIFFERS_FROM_CONTRACT:CH01", assess(report, CONTRACT)["failures"])

    def test_qlik_literal_whitespace_is_preserved(self):
        self.assertEqual(normalize(" = Sum( X ) "), "Sum(X)")
        self.assertNotEqual(normalize("Sum({<A={'A B'}>}X)"), normalize("Sum({<A={'AB'}>}X)"))


if __name__ == "__main__":
    unittest.main()
