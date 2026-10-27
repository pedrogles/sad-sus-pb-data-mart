#!/usr/bin/env python3
"""SAD AE01: independently reconcile grouped QlikView CSVs; never read/write QVD/QVW.

This code is a PREPARED PATCH, not a report of physical execution. The caller
must run it only from an authorized, committed Git revision after Qlik export.
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

EXPECTED = {
    'sih_fluxo_competencia.csv': (
        'competencia','ano','municipio_res','municipio_serv',
        'qtd_registro_aih','qtd_internacao','qtd_continuidade'),
    'sih_procedimento_competencia.csv': (
        'competencia','ano','proc_rea','qtd_registro_aih','qtd_internacao','qtd_continuidade'),
    'sih_diagnostico_competencia.csv': (
        'competencia','ano','diag_princ','qtd_registro_aih','qtd_internacao','qtd_continuidade'),
    'lt_cnes_leito_competencia.csv': (
        'competencia','municipio_serv','cnes','tp_leito','codleito',
        'linhas_lt','qt_exist','qt_sus','qt_nsus'),
}
RD_YEAR = {'2017':183532, '2018':183311, '2019':188246}
RD_ALL = (566672,555089,11583)
LT_ALL = (35518,337147,270076,67071)
F2_PIN = 'DC0FAE8646F6570F5DEEAF8A1597EA5ED90A5BD9A881A40B4DCA0E30380E953D'
MONTHS = {f'{y}{m:02d}' for y in range(2017,2020) for m in range(1,13)}


def require(test: bool, message: str):
    if not test:
        raise ValueError(message)


def sha256(path: Path) -> str:
    h=hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024*1024),b''):
            h.update(block)
    return h.hexdigest().upper()


def read_csv(path: Path, schema: tuple[str, ...]):
    require(path.is_file() and path.stat().st_size>0,f'Arquivo ausente/vazio: {path}')
    with path.open('r',encoding='utf-8-sig',newline='') as stream:
        reader=csv.DictReader(stream,delimiter=';')
        require(tuple(reader.fieldnames or ())==schema,f'Schema inesperado: {path.name}: {reader.fieldnames}')
        for line,row in enumerate(reader,start=2):
            require(None not in row and all(v is not None for v in row.values()),f'CSV malformado: {path}:{line}')
            yield line,row


def uint(v: str, label: str) -> int:
    require(bool(re.fullmatch(r'(?:0|[1-9][0-9]*)',v)),f'{label}: inteiro nao canonico {v!r}')
    return int(v)


def valid_month(m: str) -> bool:
    return m in MONTHS


def read_municipios(path: Path) -> set[str]:
    with path.open('r',encoding='utf-8-sig',newline='') as stream:
        reader=csv.DictReader(stream,delimiter=';')
        require(reader.fieldnames is not None and {'COD_DATASUS_6','COD_IBGE_7'} <= set(reader.fieldnames),
                'Crosswalk municipal sem schema C5.2')
        codes=set()
        ibges=set()
        count=0
        for row in reader:
            count+=1
            c,i=row['COD_DATASUS_6'],row['COD_IBGE_7']
            require(bool(re.fullmatch(r'25[0-9]{4}',c)) and bool(re.fullmatch(r'25[0-9]{5}',i))
                    and i.startswith(c) and c not in codes and i not in ibges,'Crosswalk invalido')
            codes.add(c);ibges.add(i)
    require(count==223,'Crosswalk diferente de 223 codigos')
    return codes


def audit_rd(folder: Path, code_pb: set[str]):
    output={}
    monthly_profiles={}
    for filename in list(EXPECTED)[:3]:
        fields=EXPECTED[filename]
        seen=set();byyear=Counter();summary=Counter();by_month=set();outside=Counter()
        by_month_counts=defaultdict(Counter)
        for line,row in read_csv(folder/filename,fields):
            month=row['competencia']
            require(valid_month(month) and row['ano']==month[:4],f'{filename}:{line}: ano/mes')
            k=tuple(row[f] for f in fields if f not in ('qtd_registro_aih','qtd_internacao','qtd_continuidade','ano'))
            require(k not in seen,f'{filename}:{line}: grao duplicado {k}')
            seen.add(k);by_month.add(month)
            reg,intern,cont=[uint(row[f],f'{filename}:{line}:{f}') for f in fields[-3:]]
            require(reg>0 and reg==intern+cont,f'{filename}:{line}: decomposicao RD')
            for name,n in [('rows',reg),('intern',intern),('cont',cont)]:
                summary[name]+=n
                by_month_counts[month][name]+=n
            byyear[row['ano']]+=intern
            if filename=='sih_fluxo_competencia.csv':
                res,serv=row['municipio_res'],row['municipio_serv']
                require(bool(re.fullmatch('[0-9]{6}',res)) and serv in code_pb,
                        f'{filename}:{line}: codigos municipais invalidos/servico externo')
                require(not (res.startswith('25') and res not in code_pb),
                        f'{filename}:{line}: residencia PB fora C5.2')
                if res not in code_pb:outside['rows']+=reg;outside['intern']+=intern
            elif filename=='sih_procedimento_competencia.csv':
                require(bool(row['proc_rea']),f'{filename}:{line}: PROC_REA vazio')
            else:
                require(bool(row['diag_princ']),f'{filename}:{line}: CID principal vazio')
        require(len(by_month)==36 and by_month==MONTHS,f'{filename}: competencias incompletas')
        require(tuple(summary[x] for x in ['rows','intern','cont'])==RD_ALL,
                f'{filename}: totais RD divergentes {dict(summary)}')
        require(dict(byyear)==RD_YEAR,f'{filename}: anos divergentes {dict(byyear)}')
        monthly_profiles[filename]={m:tuple(by_month_counts[m][key] for key in ('rows','intern','cont'))
                                    for m in sorted(MONTHS)}
        if filename=='sih_fluxo_competencia.csv':
            require(outside['rows']==5202 and outside['intern']==5067,
                    f'Residencia externa difere de F1/F3: {dict(outside)}')
        output[filename]={'rows':len(seen),'sha256':sha256(folder/filename),
                          'competencias':len(by_month),'sums':dict(summary),
                          'annual_internacoes':dict(sorted(byyear.items())),
                          'residencia_externa':dict(outside) if outside else None}
    reference=monthly_profiles['sih_fluxo_competencia.csv']
    for filename,profile in monthly_profiles.items():
        for month in sorted(MONTHS):
            require(profile[month]==reference[month],
                    f'{filename}: divergencia mensal E1/E2/E3 em {month}: esperado={reference[month]} observado={profile[month]}')
    return output


def audit_lt(folder: Path, code_pb: set[str]):
    filename='lt_cnes_leito_competencia.csv';seen=set();months=set();counts=Counter()
    observed=defaultdict(lambda: Counter())
    for line,r in read_csv(folder/filename,EXPECTED[filename]):
        month,mun,cnes,tp,cod=(r[x] for x in ['competencia','municipio_serv','cnes','tp_leito','codleito'])
        require(valid_month(month) and mun in code_pb and bool(cnes)
                and bool(re.fullmatch('[1-7]',tp)) and bool(re.fullmatch('[0-9]{2}',cod)),
                f'{filename}:{line}: dominio')
        key=(month,mun,cnes,tp,cod)
        require(key not in seen,f'{filename}:{line}: grao duplicado')
        seen.add(key);months.add(month)
        n,e,s,ns=(uint(r[k],f'{filename}:{line}:{k}') for k in ['linhas_lt','qt_exist','qt_sus','qt_nsus'])
        require(n>0 and e==s+ns,f'{filename}:{line}: identidade LT')
        counts['rows']+=n;counts['exist']+=e;counts['sus']+=s;counts['nsus']+=ns
        pair=observed[(month,mun)]
        pair['rows']+=n;pair['exist']+=e;pair['sus']+=s;pair['nsus']+=ns
    require(months==MONTHS and len(months)==36,'LT competencias incompletas')
    require(tuple(counts[k] for k in ['rows','exist','sus','nsus'])==LT_ALL,
            f'LT totais divergentes {dict(counts)}')
    require(len(observed)==3561,f'LT pares observados divergentes: {len(observed)}')
    zero=sum(p['sus']==0 for p in observed.values())
    positive=sum(p['sus']>0 for p in observed.values())
    require(zero==97 and positive==3464 and 223*36-len(observed)==4467,
            f'LT observabilidade divergente zero={zero} positivo={positive}')
    return {'rows':len(seen),'sha256':sha256(folder/filename),'competencias':36,
            'source_rows':counts['rows'],'sums':dict(counts),'municipio_mes_observados':len(observed),
            'observado_sus_zero':zero,'observado_sus_positivo':positive,
            'municipio_mes_sem_linha_na_grade':4467},observed


def compare_f2(path: Path,observed):
    require(sha256(path)==F2_PIN,'F2 historico sem SHA-256 esperado')
    schema=('ano','competencia','municipio_servico','linhas_lt','qt_sus','qt_exist','qt_nsus','estado','universo')
    refs={}
    for line,r in read_csv(path,schema):
        k=(r['competencia'],r['municipio_servico'])
        require(k not in refs and r['ano']==k[0][:4],f'F2 duplicado/invalido {line}')
        require(r['universo']=='LT_TODOS_REGISTROS_VALIDOS_RN21',f'F2 universo {line}')
        refs[k]=tuple(uint(r[f],f'F2:{line}:{f}') for f in ('linhas_lt','qt_exist','qt_sus','qt_nsus'))
    require(set(refs)==set(observed),'F2 nao possui mesmos pares municipio/mes')
    for k,nums in refs.items():
        require(nums==tuple(observed[k][f] for f in ('rows','exist','sus','nsus')),
                f'E4 versus F2 diverge em {k}')
    return {'file':path.name,'sha256':F2_PIN,'pares_comparados':len(refs)}


def read_metadata(path: Path) -> dict:
    # Windows PowerShell 5.1's Set-Content -Encoding UTF8 emits a UTF-8 BOM.
    return json.loads(path.read_text(encoding='utf-8-sig'))


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--exports',type=Path,required=True)
    p.add_argument('--crosswalk',type=Path,required=True)
    p.add_argument('--manifest',type=Path,required=True)
    p.add_argument('--metadata',type=Path,required=True,help='JSON gerado pelo runner: commit, hashes de scripts/QVD/QVW antes/depois')
    p.add_argument('--f2',type=Path,help='CSV historico C4-B1, SHA pinado; opcional')
    args=p.parse_args()
    folder=args.exports.resolve(strict=True)
    manifest=args.manifest.resolve(strict=False)
    require(manifest.parent==folder and not manifest.exists(), 'Manifesto deve ser novo no diretorio dos CSVs')
    require(args.crosswalk.resolve(strict=True)!=manifest and args.metadata.resolve(strict=True)!=manifest,
            'Entrada colide com saida')
    metadata=read_metadata(args.metadata)
    require(metadata.get('gate')=='SAD-ANALYTICAL-EXPORT-LOCAL-01' and metadata.get('commit')
            and metadata.get('protection_unchanged') is True,'Proveniencia/hash nao validado pelo runner')
    codes=read_municipios(args.crosswalk)
    rd=audit_rd(folder,codes)
    lt,observed=audit_lt(folder,codes)
    export_results=dict(rd)
    export_results['lt_cnes_leito_competencia.csv']=lt
    result={'gate':'SAD-ANALYTICAL-EXPORT-LOCAL-01',
            'status':'EXPORTED_AND_RECONCILED_RESTRICTED',
            'verified_utc':datetime.now(timezone.utc).isoformat(),
            'execution':metadata,'reference_crosswalk_sha256':sha256(args.crosswalk),
            'exports':export_results,
            'f2_comparison':compare_f2(args.f2,observed) if args.f2 else 'NOT_PROVIDED',
            'interpretation':['2017-2019 SIH/RD PB administrative records; IDENT=5 not new',
              'Municipio RES and SERV are distinct; outside-PB means residence outside C5.2',
              'CNES/LT monthly snapshots; no annual stock from summing months',
              'Missing LT line is not zero; no hospital-only classification or historical T29',
              'No inter-fact Link Key, physical indicator, dashboard or production approved']}
    with manifest.open('x',encoding='utf-8',newline='') as stream:
        json.dump(result,stream,ensure_ascii=False,indent=2,sort_keys=True)
        stream.write('\n')
    print('VERDICT=EXPORTED_AND_RECONCILED_RESTRICTED')
    print('MANIFEST_SHA256='+sha256(manifest))


if __name__=='__main__':
    try:
        main()
    except (ValueError,OSError,UnicodeError,csv.Error,KeyError,TypeError,RuntimeError) as e:
        print(f'VERDICT=BLOCKED_EXPORT_RECONCILIATION {type(e).__name__}: {e}',file=sys.stderr)
        sys.exit(1)
