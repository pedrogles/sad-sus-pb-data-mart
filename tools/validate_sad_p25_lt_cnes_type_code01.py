#!/usr/bin/env python3
"""SAD P2.5 read-only CNES×tp_leito×codleito composition, 201912 only.

Execute from committed Git source. The month is a cadastral LT snapshot,
not proof of hospital-only eligibility, occupancy or annual stock.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

GATE = 'SAD-P25-LT-CNES-TYPE-CODE-201912-READONLY-01'
COMP = '201912'
E4_SHA = 'BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88'
P24_SHA = '90058AEAD055B0C7ECF60594E731AB390B5DB609F42FF7A7C62FED4EF95964D7'
E4_COLUMNS = ('competencia','municipio_serv','cnes','tp_leito','codleito','linhas_lt','qt_exist','qt_sus','qt_nsus')
P24_COLUMNS = ('municipio_serv','qt_sus','qt_exist','qt_nsus','linhas_lt')
TOTALS = {'linhas_lt':964,'qt_exist':9065,'qt_sus':7140,'qt_nsus':1925}
MEASURES = ('linhas_lt','qt_exist','qt_sus','qt_nsus')

def require(condition, reason):
    if not condition:
        raise ValueError(reason)

def sha256(path):
    h = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest().upper()

def integer(v, field):
    require(re.fullmatch(r'0|[1-9][0-9]*',v) is not None, f'Nonnegative integer required: {field}={v!r}')
    return int(v)

def read_csv(path, delimiter, expected):
    with path.open(encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f, delimiter=delimiter)
        require(tuple(reader.fieldnames or ()) == expected, f'Schema mismatch: {path.name}')
        for line, row in enumerate(reader, 2):
            require(None not in row and all(x is not None for x in row.values()), f'Malformed row {line}')
            yield row

def audit(e4, p24):
    e4_hash, p24_hash = sha256(e4), sha256(p24)
    require(e4_hash == E4_SHA, 'E4 SHA-256 mismatch')
    require(p24_hash == P24_SHA, 'P2.4 ranking SHA-256 mismatch')
    keys = set()
    rows = []
    totals = Counter()
    municipal = defaultdict(Counter)
    cnes_set = set()
    pair_set = set()
    type_totals = defaultdict(Counter)
    code_totals = defaultdict(Counter)
    for row in read_csv(e4,';',E4_COLUMNS):
        if row['competencia'] != COMP:
            continue
        mun, cnes, tp, code = (row[k] for k in ('municipio_serv','cnes','tp_leito','codleito'))
        require(re.fullmatch(r'25[0-9]{4}',mun) is not None, 'Invalid DATASUS6 municipality')
        require(re.fullmatch(r'[0-9]+',cnes) is not None and
                re.fullmatch(r'[0-9]+',tp) is not None and
                re.fullmatch(r'[0-9]+',code) is not None,
                'Invalid literal CNES/type/code (names and T29 labels forbidden)')
        grain = (cnes,tp,code)
        require(grain not in keys, f'Duplicate CNES/type/code within {COMP}: {grain}')
        keys.add(grain)
        values = {k:integer(row[k],k) for k in MEASURES}
        require(values['linhas_lt'] == 1, 'E4 grain must represent one observed LT line')
        require(values['qt_exist'] == values['qt_sus']+values['qt_nsus'], 'Quantity identity violation')
        for name,value in values.items():
            totals[name]+=value
            municipal[mun][name]+=value
            type_totals[tp][name]+=value
            code_totals[(tp,code)][name]+=value
        cnes_set.add(cnes)
        pair_set.add((tp,code))
        rows.append({'cnes':cnes,'tp_leito':tp,'codleito':code,'municipio_serv':mun,**values})
    require(len(rows)==964 and len(keys)==964, 'Expected 964 distinct LT grains in 201912')
    require(dict(totals)==TOTALS, f'E4 sum mismatch: {dict(totals)}')
    p24_rows = {}
    for item in read_csv(p24,';',P24_COLUMNS):
        mun=item['municipio_serv']
        require(mun not in p24_rows, 'Duplicate municipality in P2.4 ranking')
        p24_rows[mun]={k:integer(item[k],k) for k in MEASURES}
    require(len(municipal)==len(p24_rows)==95, 'P2.4 municipal coverage mismatch')
    require(set(municipal)==set(p24_rows), 'P2.4 municipality key mismatch')
    for mun in municipal:
        require(dict(municipal[mun])==p24_rows[mun], f'P2.4 municipality quantities mismatch for {mun}')
    require(sha256(e4)==e4_hash and sha256(p24)==p24_hash, 'Input changed during the run')

    rows.sort(key=lambda a:(a['cnes'],a['tp_leito'],a['codleito']))
    bytype=[{'tp_leito':tp,**dict(meas)} for tp,meas in sorted(type_totals.items())]
    bycode=[{'tp_leito':tp,'codleito':code,**dict(meas)} for (tp,code),meas in sorted(code_totals.items())]
    for groups in (bytype,bycode):
        require(all(sum(r[k] for r in groups)==TOTALS[k] for k in MEASURES), 'Grouped totals mismatch')
    return {
        'gate':GATE,'verdict':'PASS_RESTRICTED_E4_P25_CNES_TYPE_CODE_201912',
        'competencia':COMP,'sources':{'E4':{'name':e4.name,'sha256':e4_hash},
                                      'P24_ranking':{'name':p24.name,'sha256':p24_hash}},
        'granularity':'one observed CNES×tp_leito×codleito record in competencia 201912',
        'control_totals':dict(totals),'grain_rows':len(rows),'distinct_cnes_identifiers':len(cnes_set),
        'distinct_raw_types':len(type_totals),'distinct_raw_type_code_pairs':len(pair_set),
        'municipal_reconciliation':{'p24_compared':len(municipal),'quantity_mismatches':0},
        'type_totals':bytype,'type_code_totals':bycode,
        'data_rows':rows,
        'limits':['CNES identifiers do not prove operational hospital count',
                  'T29_HISTORICAL=NOT_APPROVED; codes only, no historical descriptions',
                  'CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED',
                  'Snapshot only; no occupancy, availability or annual stock',
                  'No UI, COM, QlikView visual or production approval']
    }

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--e4',required=True,type=Path)
    p.add_argument('--p24-ranking',required=True,type=Path)
    p.add_argument('--output-dir',required=True,type=Path)
    p.add_argument('--source-commit',required=True)
    p.add_argument('--script-sha256',required=True)
    a=p.parse_args()
    try:
        require(re.fullmatch(r'[0-9a-fA-F]{40}',a.source_commit) is not None, 'Invalid source commit')
        require(sha256(Path(__file__))==a.script_sha256.upper(), 'Validator SHA mismatch')
        e4,p24,out=a.e4.resolve(),a.p24_ranking.resolve(),a.output_dir.resolve()
        require(e4.is_file() and p24.is_file(), 'Source files unavailable')
        require(out!=e4.parent and out!=p24.parent, 'Output directory must differ from inputs')
        output_names=('p25_grain_201912.csv','p25_type_201912.csv','p25_type_code_201912.csv','p25_audit.json')
        require(all(not (out/n).exists() for n in output_names), 'Refusing to overwrite evidence')
        result=audit(e4,p24)
        result['execution']={'source_commit':a.source_commit,'script_sha256':sha256(Path(__file__)),
                             'utc':datetime.now(timezone.utc).isoformat()}
        out.mkdir(parents=True,exist_ok=True)
        for name,items,fields in (
            ('p25_grain_201912.csv',result['data_rows'],('cnes','tp_leito','codleito','municipio_serv',*MEASURES)),
            ('p25_type_201912.csv',result['type_totals'],('tp_leito',*MEASURES)),
            ('p25_type_code_201912.csv',result['type_code_totals'],('tp_leito','codleito',*MEASURES)),
        ):
            with (out/name).open('x',encoding='utf-8',newline='') as stream:
                w=csv.DictWriter(stream,fieldnames=fields,delimiter=';')
                w.writeheader()
                w.writerows(items)
        result.pop('data_rows')
        with (out/'p25_audit.json').open('x',encoding='utf-8') as stream:
            json.dump(result,stream,indent=2,ensure_ascii=False)
            stream.write('\n')
        print(json.dumps({'verdict':result['verdict'],'control_totals':result['control_totals'],
                          'grain_rows':result['grain_rows'],
                          'distinct_cnes_identifiers':result['distinct_cnes_identifiers'],
                          'distinct_raw_types':result['distinct_raw_types'],
                          'distinct_raw_type_code_pairs':result['distinct_raw_type_code_pairs'],
                          'municipal_reconciliation':result['municipal_reconciliation'],
                          'execution':result['execution']},ensure_ascii=False,indent=2))
        return 0
    except (ValueError,csv.Error,KeyError,TypeError) as exc:
        print(f'VERDICT=HARD_STOP_VALIDATION_DIVERGENCE: {exc}',file=sys.stderr)
        return 2
    except OSError as exc:
        print(f'VERDICT=BLOCKED_SOURCE_OR_IO: {exc}',file=sys.stderr)
        return 3

if __name__=='__main__':
    raise SystemExit(main())
