"""Offline-only synthetic tests for A0 oracle. No QlikView or production data."""
import csv
import tempfile
import unittest
from pathlib import Path

import prepare_sad_a0_consumption_oracle01 as target


class TestA0OracleStatic(unittest.TestCase):
    def test_month_domain(self):
        self.assertEqual(len(target.MONTHS), 36)
        self.assertTrue(target.validate_month("201701"))
        self.assertTrue(target.validate_month("201912"))
        self.assertFalse(target.validate_month("201913"))
        self.assertFalse(target.validate_month("202001"))

    def test_uint_canonical(self):
        self.assertEqual(target.uint("0", "x"), 0)
        self.assertEqual(target.uint("3806", "x"), 3806)
        for invalid in ("", "-1", "01", "+1", "1.0", "abc"):
            with self.subTest(invalid=invalid):
                with self.assertRaises(ValueError):
                    target.uint(invalid, "x")

    def test_read_csv_header_and_bom(self):
        with tempfile.TemporaryDirectory() as folder:
            p = Path(folder) / "e1.csv"
            with p.open("w", encoding="utf-8-sig", newline="") as s:
                writer = csv.DictWriter(s, fieldnames=target.E1_FIELDS, delimiter=";")
                writer.writeheader()
                writer.writerow(dict(zip(target.E1_FIELDS, (
                    "201801", "2018", "250180", "250750", "1", "1", "0"
                ))))
            values = list(target.read_rows(p, target.E1_FIELDS))
            self.assertEqual(len(values), 1)
            self.assertEqual(values[0][1]["municipio_serv"], "250750")
            with self.assertRaises(ValueError):
                list(target.read_rows(p, target.E4_FIELDS))

    def test_unapproved_bytes_fail_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            e1 = Path(folder) / "sih_fluxo_competencia.csv"
            e4 = Path(folder) / "lt_cnes_leito_competencia.csv"
            e1.write_bytes(b"untrusted E1")
            e4.write_bytes(b"untrusted E4")
            before = target.sha256(e1)
            with self.assertRaises(ValueError):
                target.build(e1, e4)
            self.assertEqual(target.sha256(e1), before)


if __name__ == "__main__":
    unittest.main()
