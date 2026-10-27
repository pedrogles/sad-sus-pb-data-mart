#!/usr/bin/env python3
"""Offline AE01 regression tests: synthetic fixtures only, never QVD/QVW/COM.

Run: python -m unittest discover -s tools -p test_sad_analytical_export_local01.py -v
"""
from __future__ import annotations

import csv
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import validate_sad_analytical_export_local01 as validator

QVS = TOOLS.parent / 'TRANSFORMACAO' / 'sad_analytical_export_local01.qvs'


def write_groups(root: Path) -> None:
    """Build 36 synthetic months matching approved administrative oracles."""
    series = {}
    for year, count in validator.RD_YEAR.items():
        for month in range(1, 13):
            comp = f'{year}{month:02d}'
            eligible = count - 11 if month == 1 else 1
            continuity = 11448 if comp == '201701' else 0
            series[comp] = [eligible, continuity]
    # Exactly 5,202 external records / 5,067 eligible / 135 continuations.
    series['201701'][0] -= 5067
    f1 = []
    f2 = []
    f3 = []
    for month in sorted(series):
        eligible, continuation = series[month]
        records = eligible + continuation
        groups = [(eligible, continuation, '250010')]
        if month == '201701':
            groups.append((5067, 135, '260010'))
        for new, cont, res in groups:
            f1.append({'competencia': month, 'ano': month[:4],
                       'municipio_res': res, 'municipio_serv': '250010',
                       'qtd_registro_aih': new + cont,
                       'qtd_internacao': new, 'qtd_continuidade': cont})
        common = {'competencia': month, 'ano': month[:4],
                  'qtd_registro_aih': sum(a+b for a,b,_ in groups),
                  'qtd_internacao': sum(a for a,_,_ in groups),
                  'qtd_continuidade': sum(b for _,b,_ in groups)}
        f2.append({**common, 'proc_rea': '0301010012'})
        f3.append({**common, 'diag_princ': 'A00'})
    for filename, values in zip(list(validator.EXPECTED)[:3], (f1,f2,f3)):
        with (root / filename).open('w', encoding='utf-8', newline='') as out:
            w = csv.DictWriter(out, fieldnames=validator.EXPECTED[filename],delimiter=';')
            w.writeheader()
            w.writerows(values)


def load_rows(path: Path):
    with path.open(encoding='utf-8', newline='') as f:
        rdr = csv.DictReader(f, delimiter=';')
        return rdr.fieldnames, list(rdr)


def store_rows(path: Path,fields,rows):
    with path.open('w', encoding='utf-8', newline='') as f:
        w = csv.DictWriter(f,fieldnames=fields,delimiter=';')
        w.writeheader()
        w.writerows(rows)


def check_qvs_prefix_isolation(src: str) -> None:
    """Static contract; not a substitute for Qlik's actual NoOfTables probe."""
    all_fields = set()
    for i in range(1,5):
        block = re.search(rf'(?ms)^AE_PRE_E{i}:\nNOCONCATENATE LOAD\n(.*?)\nRESIDENT ',src)
        if not block:
            raise ValueError(f'AE_PRE_E{i} missing')
        aliases = re.findall(r'\bAS\s+(\w+)',block.group(1))
        if not aliases or any(not f.startswith(f'AE{i}_') for f in aliases):
            raise ValueError(f'AE_PRE_E{i} has unqualified internal alias')
        if all_fields.intersection(aliases):
            raise ValueError('two temporary tables share fields')
        all_fields.update(aliases)
    starts=[]
    for i in range(1,5):
        start=src.index(f'\nAE_E{i}:\n')
        store=src.index(f'STORE AE_E{i} INTO [__E{i}_CSV__]',start)
        drop_match=re.search(rf'(?m)^DROP TABLE AE_E{i};$',src[store:])
        if not drop_match:
            raise ValueError(f'missing active DROP for AE_E{i}')
        drop=store+drop_match.start()
        starts.append((start,store,drop))
    if not all(starts[i][2]<starts[i+1][0] for i in range(3)):
        raise ValueError('overlapping public-shaped export tables')
    allowed_store = r"(?m)^STORE AE_E[1-4] INTO \[__E[1-4]_CSV__\] \(txt, delimiter is ';'\);$"
    if len(re.findall(allowed_store, src)) != 4 or len(re.findall(r'(?m)^STORE\s+',src)) != 4 or re.search(r'(?im)^STORE.+\(qvd\)',src):
        raise ValueError('STORE allowlist violated')
    if 'VERDICT=BLOCKED_SYNTHETIC_KEYS' not in src:
        raise ValueError('runtime synthetic-key guard absent')


class AE01NegativeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='AE01_SYNTHETIC_')
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        write_groups(self.root)

    def test_all_36_months_positive_synthetic_reference(self):
        result=validator.audit_rd(self.root,{'250010'})
        self.assertEqual(len(result),3)
        self.assertEqual(result['sih_fluxo_competencia.csv']['sums']['rows'],566672)

    def test_e2_month_shift_preserving_annual_totals_must_block(self):
        p=self.root/'sih_procedimento_competencia.csv'
        fields,rows=load_rows(p)
        jan=next(x for x in rows if x['competencia']=='201701')
        feb=next(x for x in rows if x['competencia']=='201702')
        for k in ('qtd_registro_aih','qtd_internacao'):
            jan[k]=str(int(jan[k])-1)
            feb[k]=str(int(feb[k])+1)
        store_rows(p,fields,rows)
        with self.assertRaisesRegex(ValueError,r'divergencia mensal .*201701'):
            validator.audit_rd(self.root,{'250010'})

    def test_e3_continuation_month_shift_must_block(self):
        p=self.root/'sih_diagnostico_competencia.csv'
        fields,rows=load_rows(p)
        jan=next(x for x in rows if x['competencia']=='201701')
        feb=next(x for x in rows if x['competencia']=='201702')
        for k in ('qtd_registro_aih','qtd_continuidade'):
            jan[k]=str(int(jan[k])-1)
            feb[k]=str(int(feb[k])+1)
        store_rows(p,fields,rows)
        with self.assertRaisesRegex(ValueError,r'divergencia mensal .*201701'):
            validator.audit_rd(self.root,{'250010'})

    def test_powershell51_json_with_bom_is_accepted(self):
        p=self.root/'run_metadata.json'
        sample={'gate':'SAD-ANALYTICAL-EXPORT-LOCAL-01','commit':'a'*40,
                'protection_unchanged':True}
        p.write_bytes(b'\xef\xbb\xbf'+json.dumps(sample).encode('utf-8'))
        parsed=validator.read_metadata(p)
        self.assertEqual(parsed,sample)
        with self.assertRaises(json.JSONDecodeError):
            json.loads(p.read_text(encoding='utf-8'))

    def test_qvs_prefixes_and_serial_store_static_positive(self):
        check_qvs_prefix_isolation(QVS.read_text(encoding='utf-8'))

    def test_duplicate_prefix_mutation_must_block(self):
        src=QVS.read_text(encoding='utf-8').replace('AS AE2_competencia','AS AE1_competencia',1)
        with self.assertRaisesRegex(ValueError,'unqualified internal alias'):
            check_qvs_prefix_isolation(src)

    def test_public_table_overlap_mutation_must_block(self):
        src=QVS.read_text(encoding='utf-8').replace('DROP TABLE AE_E1;','// DROP TABLE AE_E1;',1)
        with self.assertRaisesRegex(ValueError,'missing active DROP'):
            check_qvs_prefix_isolation(src)


if __name__=='__main__':
    unittest.main()
