#!/usr/bin/env python3
"""SAD P1.5: pinned AE01 E3 diagnosis ranking; source read-only, evidence outside Git."""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import re
from collections import Counter
from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

GATE = 'SAD-P15-PROC-RANKING-READONLY-01'
PIN = '3FC6C78746D74F815EBED62F1AF88D950F6BFB303343FBD199AA436E2AE7D230'
FIELDS = ('competencia', 'ano', 'diag_princ', 'qtd_registro_aih', 'qtd_internacao', 'qtd_continuidade')
MONTHS = {f'{y}{m:02}' for y in range(2017, 2020) for m in range(1, 13)}
YEARS = {'2017': 183532, '2018': 183311, '2019': 188246}
TOTAL = {'qtd_registro_aih': 566672, 'qtd_internacao': 555089, 'qtd_continuidade': 11583}
GROUPS = 56703
EXPLORATORY_CODE, EXPLORATORY_COUNT = 'O800', 28747
EXPLORATORY_OTHER_CODE, EXPLORATORY_OTHER_COUNT = 'O809', 21530


def require(ok: bool, message: str) -> None:
    if not ok:
        raise ValueError(message)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest().upper()


def integer(raw: str, line: int, field: str) -> int:
    require(re.fullmatch(r'0|[1-9][0-9]*', raw) is not None,
            f'line {line}: invalid nonnegative integer {field}={raw!r}')
    return int(raw)


def percent(value: int, denominator: int) -> str:
    return str((Decimal(value) * Decimal(100) / Decimal(denominator)).quantize(
        Decimal('0.0001'), rounding=ROUND_HALF_UP))


def validate(source: Path) -> dict:
    require(source.is_file() and source.stat().st_size > 0, 'E3 is missing or empty')
    before = sha256(source)
    require(before == PIN, 'E3 SHA-256 does not match the pinned AE01 export')
    keys, periods = set(), set()
    annual, diagnosis, totals = Counter(), Counter(), Counter()
    rows = 0
    with source.open('r', encoding='utf-8-sig', newline='') as fh:
        reader = csv.DictReader(fh, delimiter=';', restkey='__extra__')
        require(tuple(reader.fieldnames or ()) == FIELDS, 'E3 schema/order mismatch')
        for number, row in enumerate(reader, start=2):
            rows += 1
            require('__extra__' not in row and all(row.get(k) is not None for k in FIELDS),
                    f'line {number}: malformed CSV')
            require(all(row[k] and row[k].strip() == row[k] for k in FIELDS),
                    f'line {number}: empty/padded required field')
            month, year, code = row['competencia'], row['ano'], row['diag_princ']
            require(month in MONTHS and year == month[:4], f'line {number}: invalid competency/year')
            require(re.fullmatch(r'[A-Z][0-9]{2}[A-Z0-9]?', code) is not None,
                    f'line {number}: invalid diagnosis code {code!r}')
            key = (month, code)
            require(key not in keys, f'line {number}: duplicate competency/diagnosis {key}')
            keys.add(key)
            periods.add(month)
            reg, new, cont = (integer(row[f], number, f) for f in FIELDS[3:])
            require(reg > 0 and reg == new + cont, f'line {number}: invalid AIH decomposition')
            totals['qtd_registro_aih'] += reg
            totals['qtd_internacao'] += new
            totals['qtd_continuidade'] += cont
            annual[year] += new
            diagnosis[code] += new
    require(rows == GROUPS, f'group count mismatch {rows} != {GROUPS}')
    require(periods == MONTHS, f'competencies missing={sorted(MONTHS - periods)}')
    require(dict(sorted(annual.items())) == YEARS, f'annual totals mismatch {dict(annual)}')
    require(dict(totals) == TOTAL, f'overall totals mismatch {dict(totals)}')
    after = sha256(source)
    require(after == before, 'E3 changed while being validated')
    ranked = sorted(diagnosis.items(), key=lambda item: (-item[1], item[0]))
    require(len(ranked) > 10 and sum(value for _, value in ranked) == TOTAL['qtd_internacao'],
            'ranking/denominator mismatch')
    ranking = [{'posicao': i, 'diag_princ': code, 'qtd_internacao': value,
                'participacao_percentual': percent(value, TOTAL['qtd_internacao'])}
               for i, (code, value) in enumerate(ranked, start=1)]
    first_ten = sum(item['qtd_internacao'] for item in ranking[:10])
    others = sum(item['qtd_internacao'] for item in ranking[10:])
    require(first_ten + others == TOTAL['qtd_internacao'], 'top10/remainder reconciliation error')
    return {'gate': GATE, 'verdict': 'PASS_E3_P15_RECONCILED_RESTRICTED',
            'source': {'name': source.name, 'sha256': after, 'size_bytes': source.stat().st_size},
            'schema': list(FIELDS), 'groups': rows, 'unique_grain': len(keys),
            'competencies': len(periods), 'first_competency': min(periods), 'last_competency': max(periods),
            'annual_new': dict(sorted(annual.items())), 'totals': dict(totals),
            'distinct_diag_princ': len(ranking), 'ranking': ranking,
            'top10': {'count': first_ten, 'codes': 10, 'share_percent': percent(first_ten, TOTAL['qtd_internacao'])},
            'remainder': {'count': others, 'codes': len(ranking) - 10,
                          'share_percent': percent(others, TOTAL['qtd_internacao'])},
            'exploratory_comparison': {
                'diag_princ': EXPLORATORY_CODE, 'historical_unverified_count': EXPLORATORY_COUNT,
                'observed_count': diagnosis.get(EXPLORATORY_CODE, 0),
                'matches': diagnosis.get(EXPLORATORY_CODE, 0) == EXPLORATORY_COUNT,
                'secondary': {'diag_princ': EXPLORATORY_OTHER_CODE,
                    'historical_unverified_count': EXPLORATORY_OTHER_COUNT,
                    'observed_count': diagnosis.get(EXPLORATORY_OTHER_CODE, 0),
                    'matches': diagnosis.get(EXPLORATORY_OTHER_CODE, 0) == EXPLORATORY_OTHER_COUNT}},
            'limitations': ['E3 aggregates are not patients or clinical admissions',
                            'Only codes, no historical SIGTAP labels', 'No E3 RES/SERV dimension',
                            'No QlikView, UX, cross-fact, or production approval']}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--e3', required=True, type=Path)
    parser.add_argument('--source-commit', required=True)
    parser.add_argument('--script-sha256', required=True)
    parser.add_argument('--output-dir', required=True, type=Path)
    args = parser.parse_args()
    try:
        require(re.fullmatch(r'[a-fA-F0-9]{40}', args.source_commit) is not None,
                'source commit must be a 40-character SHA')
        script_hash = sha256(Path(__file__))
        require(script_hash == args.script_sha256.upper(), 'versioned script hash mismatch')
        source = args.e3.resolve()
        output = args.output_dir.resolve()
        require(output != source.parent and source not in output.parents,
                'output must be outside source directory')
        report = validate(source)
        report['execution'] = {'source_commit': args.source_commit, 'script_sha256': script_hash,
                               'utc': datetime.now(timezone.utc).isoformat()}
        output.mkdir(parents=True, exist_ok=True)
        with (output / 'p15_diag_ranking.csv').open('w', encoding='utf-8', newline='') as fh:
            writer = csv.DictWriter(fh, delimiter=';', fieldnames=tuple(report['ranking'][0]))
            writer.writeheader()
            writer.writerows(report['ranking'])
        (output / 'p15_diag_audit.json').write_text(
            json.dumps(report, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
        print(json.dumps({k: v for k, v in report.items() if k != 'ranking'}, indent=2, ensure_ascii=False))
        return 0
    except (ValueError, OSError, UnicodeError, csv.Error) as exc:
        print(f'VERDICT=FAIL_HARD_STOP: {exc}')
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
