#!/usr/bin/env python3
"""P2.1: validate AE01 E4 and 36 observed monthly CNES/LT snapshots, read-only.

An optional second implementation is the committed A0 oracle generated from the
SAME E4 file; its 108-value match is NOT an independent QlikView readback.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

GATE = 'SAD-P21-LT-MONTHLY-OBSERVED-READONLY-01'
PIN = 'BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88'
FIELDS = ('competencia', 'municipio_serv', 'cnes', 'tp_leito', 'codleito',
          'linhas_lt', 'qt_exist', 'qt_sus', 'qt_nsus')
MONTHS = tuple(f'{year}{month:02d}' for year in (2017, 2018, 2019) for month in range(1, 13))
TOTAL = {'linhas_lt': 35518, 'qt_exist': 337147, 'qt_sus': 270076, 'qt_nsus': 67071}
EXPECTED_ROWS = 35518
EXPECTED_PAIRS = 3561
EXPECTED_ZERO_SUS = 97
EXPECTED_POSITIVE_SUS = 3464


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise ValueError(reason)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest().upper()


def uint(value: str, line: int, field: str) -> int:
    require(re.fullmatch(r'(?:0|[1-9][0-9]*)', value) is not None,
            f'line={line} noncanonical integer {field}={value!r}')
    return int(value)


def check_oracle(path: Path, monthly: dict) -> dict:
    require(path.is_file(), 'versioned A0 oracle JSON unavailable')
    with path.open('r', encoding='utf-8-sig') as stream:
        oracle = json.load(stream)
    require(oracle.get('gate') == 'SAD-A0-CONSUMPTION-VALIDATION-01' and
            oracle.get('status') == 'ORACLE_READY_NOT_QLIK_PASS',
            'unexpected A0 oracle kind')
    require(oracle.get('source_sha256', {}).get('E4') == PIN,
            'A0 oracle source SHA differs from E4')
    ref = oracle.get('p2_2')
    require(isinstance(ref, dict) and set(ref) == set(MONTHS),
            'A0 oracle missing or extra months')
    mismatches = []
    for month in MONTHS:
        got = monthly[month]
        expected = ref[month]
        for reference_key, actual_key in [('exist', 'qt_exist'),
                                          ('sus', 'qt_sus'), ('nsus', 'qt_nsus')]:
            require(isinstance(expected.get(reference_key), int),
                    f'A0 oracle invalid value: {month}/{reference_key}')
            if got[actual_key] != expected[reference_key]:
                mismatches.append({'month': month, 'measure': actual_key,
                                   'expected': expected[reference_key],
                                   'observed': got[actual_key]})
    require(not mismatches, f'A0 same-source 108-value comparison mismatches: {mismatches[:4]}')
    return {'status': 'PASS_108_OF_108_SAME_E4_COMMITTED_A0_ORACLE',
            'values_compared': 108, 'oracle_sha256': sha256(path),
            'oracle_origin': 'existing committed tools/prepare_sad_a0_consumption_oracle01.py',
            'scope': 'two committed code paths; same E4 dataset; NOT QlikView export readback'}


def validate(source: Path, oracle: Path) -> dict:
    require(source.is_file() and source.stat().st_size > 0, 'E4 file absent or empty')
    input_before = sha256(source)
    require(input_before == PIN, 'E4 SHA-256 differs from pinned AE01 input')
    grain, months = set(), set()
    municipality_codes, cnes_codes = set(), set()
    monthly = defaultdict(Counter)
    observed_pairs = defaultdict(Counter)
    totals = Counter()
    rows = 0
    with source.open('r', encoding='utf-8-sig', newline='') as stream:
        reader = csv.DictReader(stream, delimiter=';', restkey='__extra__')
        require(tuple(reader.fieldnames or ()) == FIELDS,
                f'E4 schema/order mismatch: {reader.fieldnames}')
        for line, row in enumerate(reader, start=2):
            rows += 1
            require('__extra__' not in row and
                    all(row.get(field) is not None and row[field] != '' for field in FIELDS),
                    f'line {line}: malformed, missing or extra fields')
            require(all(row[field] == row[field].strip() for field in FIELDS),
                    f'line {line}: padded values')
            month, serv, cnes, tp, cod = (row[field] for field in FIELDS[:5])
            require(month in MONTHS, f'line {line}: invalid competency {month}')
            require(re.fullmatch(r'25[0-9]{4}', serv) is not None,
                    f'line {line}: invalid municipality format {serv}')
            require(re.fullmatch(r'[0-9]{7}', cnes) is not None,
                    f'line {line}: invalid CNES format {cnes}')
            require(re.fullmatch(r'[1-7]', tp) is not None and
                    re.fullmatch(r'[0-9]{2}', cod) is not None,
                    f'line {line}: invalid bed type/code')
            key = (month, serv, cnes, tp, cod)
            require(key not in grain, f'line {line}: duplicate grain {key}')
            grain.add(key)
            months.add(month)
            municipality_codes.add(serv)
            cnes_codes.add(cnes)
            n, exist, sus, nsus = (uint(row[field], line, field) for field in FIELDS[5:])
            require(n > 0 and exist == sus + nsus,
                    f'line {line}: LT quantity identity or lines_lt invalid')
            for field, value in zip(FIELDS[5:], (n, exist, sus, nsus)):
                monthly[month][field] += value
                totals[field] += value
                observed_pairs[(month, serv)][field] += value
    require(rows == EXPECTED_ROWS and len(grain) == EXPECTED_ROWS,
            f'row/grain count mismatch: rows={rows} distinct={len(grain)}')
    require(months == set(MONTHS), f'competencies missing/extra: {sorted(set(MONTHS)-months)}')
    require(dict(totals) == TOTAL, f'E4 source totals mismatch: {dict(totals)}')
    positives = sum(data['qt_sus'] > 0 for data in observed_pairs.values())
    zeros = sum(data['qt_sus'] == 0 for data in observed_pairs.values())
    require(len(observed_pairs) == EXPECTED_PAIRS and
            positives == EXPECTED_POSITIVE_SUS and zeros == EXPECTED_ZERO_SUS,
            f'observed-pair split mismatch: {len(observed_pairs)}/{positives}/{zeros}')
    source_after = sha256(source)
    require(source_after == input_before, 'E4 SHA changed during audit')
    ordered_months = [
        {'competencia': month, 'linhas_lt': monthly[month]['linhas_lt'],
         'qt_exist': monthly[month]['qt_exist'], 'qt_sus': monthly[month]['qt_sus'],
         'qt_nsus': monthly[month]['qt_nsus']}
        for month in MONTHS
    ]
    for item in ordered_months:
        require(item['qt_exist'] == item['qt_sus'] + item['qt_nsus'],
                f"monthly LT identity mismatch {item['competencia']}")
    comparison = check_oracle(oracle, monthly)
    return {
        'gate': GATE, 'verdict': 'PASS_E4_P21_MONTHLY_RECONCILED_RESTRICTED',
        'source': {'name': source.name, 'sha256': source_after,
                   'size_bytes': source.stat().st_size},
        'schema': list(FIELDS), 'rows': rows, 'unique_grains': len(grain),
        'competencies': len(months), 'first_competency': MONTHS[0],
        'last_competency': MONTHS[-1],
        'observed_distinct_serv_codes': len(municipality_codes),
        'observed_distinct_cnes_codes': len(cnes_codes),
        'observed_municipality_month_pairs': len(observed_pairs),
        'observed_pairs_sus_positive': positives, 'observed_pairs_sus_zero': zeros,
        'all_months_totals_for_row_reconciliation_only_NOT_STOCK': dict(totals),
        'monthly': ordered_months, 'oracle_comparison': comparison,
        'limits': ['Monthly CNES/LT observed registration snapshots, not occupancy',
                   'No sum of monthly values represents annual bed stock',
                   'No physical 223-municipality crosswalk revalidation in this gate',
                   'Absence of LT row is not observed zero',
                   'No approved hospital-only classification or historical T29',
                   'No independent QlikView export readback or UI/production approval']
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--e4', required=True, type=Path)
    parser.add_argument('--a0-oracle', required=True, type=Path)
    parser.add_argument('--source-commit', required=True)
    parser.add_argument('--script-sha256', required=True)
    parser.add_argument('--output-dir', required=True, type=Path)
    args = parser.parse_args()
    try:
        require(re.fullmatch(r'[0-9a-fA-F]{40}', args.source_commit) is not None,
                'source commit must be full 40-hex SHA')
        validator_sha = sha256(Path(__file__))
        require(validator_sha == args.script_sha256.upper(),
                'validator script SHA does not match committed source')
        source = args.e4.resolve()
        oracle = args.a0_oracle.resolve()
        out = args.output_dir.resolve()
        require(out != source.parent and source not in out.parents and
                out != oracle.parent and oracle not in out.parents,
                'output must be outside original E4 and oracle directories')
        require(not (out / 'p21_lt_monthly.csv').exists() and
                not (out / 'p21_lt_audit.json').exists(),
                'output evidence already exists; refuse overwrite')
        report = validate(source, oracle)
        report['execution'] = {'source_commit': args.source_commit,
                               'script_sha256': validator_sha,
                               'utc': datetime.now(timezone.utc).isoformat()}
        out.mkdir(parents=True, exist_ok=True)
        with (out / 'p21_lt_monthly.csv').open('x', encoding='utf-8', newline='') as stream:
            writer = csv.DictWriter(stream, delimiter=';', fieldnames=tuple(report['monthly'][0]))
            writer.writeheader()
            writer.writerows(report['monthly'])
        with (out / 'p21_lt_audit.json').open('x', encoding='utf-8') as stream:
            json.dump(report, stream, indent=2, ensure_ascii=False)
            stream.write('\n')
        print(json.dumps({k: v for k, v in report.items() if k != 'monthly'},
                         ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, UnicodeError, csv.Error, KeyError, TypeError,
            json.JSONDecodeError) as exc:
        print(f'VERDICT=FAIL_HARD_STOP: {exc}')
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
