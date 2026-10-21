#!/usr/bin/env python3
"""Read-only C4-B1 regional F2/F3 oracle verification, no QlikView or source writes."""
import argparse
import csv
import hashlib
import json
from collections import Counter
from decimal import Decimal, getcontext
from pathlib import Path

PINS = {
    'F2_lt_municipio_competencia_observado.csv': 'DC0FAE8646F6570F5DEEAF8A1597EA5ED90A5BD9A881A40B4DCA0E30380E953D',
    'F2_lt_municipio_ano_cobertura_candidata.csv': '97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D',
    'F3_cenarios_multimunicipais.csv': '3B7315A564666D43A43E60700B5ACC4E255FEF6535F53219EC3D8A08C74CBFF9',
}
SCHEMA = {
    'F2_lt_municipio_competencia_observado.csv': ['ano','competencia','municipio_servico','linhas_lt','qt_sus','qt_exist','qt_nsus','estado','universo'],
    'F2_lt_municipio_ano_cobertura_candidata.csv': ['ano','municipio_servico','meses_observados','meses_esperados','competencias_sem_linhas_lt','qt_sus_soma_snapshots_auditoria','media_sus_numerador_exato','media_sus_divisor_exato','cobertura_presenca_linhas','universo','hospitalar_historico_validado'],
    'F3_cenarios_multimunicipais.csv': ['ano','papel','selecao','municipios_distintos','codigos_municipios','denominador_pop_somado_uma_vez','numerador_internacoes_elegiveis','capacidade_media_sus_numerador_candidato','capacidade_media_sus_divisor_candidato','capacidade_estado'],
}
MUNICIPIOS = ['250400','250750']
YEAR='2018'
MONTHS=[YEAR+f'{i:02d}' for i in range(1,13)]


def require(condition, message):
    if not condition:
        raise ValueError('BLOCKED: '+message)


def sha256(path):
    return hashlib.file_digest(path.open('rb'), 'sha256').hexdigest().upper()


def load(path):
    require(path.is_file(), 'input missing: '+str(path))
    require(sha256(path)==PINS[path.name], 'SHA256 mismatch: '+path.name)
    with path.open('r',encoding='utf-8-sig',newline='') as fh:
        reader=csv.DictReader(fh,delimiter=';')
        require(reader.fieldnames==SCHEMA[path.name], 'unexpected CSV schema: '+path.name)
        rows=list(reader)
    require(rows and all(None not in r and all(v is not None for v in r.values()) for r in rows), 'malformed rows: '+path.name)
    return rows


def unique(rows, fields, name):
    keys=[tuple(r[k] for k in fields) for r in rows]
    require(len(keys)==len(set(keys)), 'duplicate grain: '+name)


def run(folder):
    files={name:folder/name for name in PINS}
    rows={name:load(path) for name,path in files.items()}
    mm=rows['F2_lt_municipio_competencia_observado.csv']
    aa=rows['F2_lt_municipio_ano_cobertura_candidata.csv']
    scenarios=rows['F3_cenarios_multimunicipais.csv']
    require((len(mm),len(aa),len(scenarios))==(3561,669,12), 'unexpected input counts')
    unique(mm,['ano','competencia','municipio_servico'],'F2 monthly')
    unique(aa,['ano','municipio_servico'],'F2 annual')
    unique(scenarios,['ano','papel','selecao'],'F3 scenarios')
    require({(r['ano'],r['papel'],r['selecao']) for r in scenarios}=={(y,role,sel) for y in ['2017','2018','2019'] for role in ['RES','SERV'] for sel in ['PB_223','JP_CG_2']},'unexpected F3 scenario set')
    subset=[r for r in mm if r['ano']==YEAR and r['municipio_servico'] in MUNICIPIOS]
    require(len(subset)==24,'expected 24 city-month observed rows')
    require({(r['municipio_servico'],r['competencia']) for r in subset}=={(city,month) for city in MUNICIPIOS for month in MONTHS},'incomplete or unexpected monthly coverage')
    totals=Counter()
    monthly=Counter()
    monthly_lt=Counter()
    for row in subset:
        require(row['competencia'][:4]==row['ano'],'monthly year mismatch')
        require(row['estado']=='LINHAS_OBSERVADAS_NUMEROS_RECONCILIADOS','F2 unverified monthly status')
        require(row['universo']=='LT_TODOS_REGISTROS_VALIDOS_RN21','unapproved F2 universe')
        lt=int(row['linhas_lt']); sus=int(row['qt_sus']); existent=int(row['qt_exist']); nsus=int(row['qt_nsus'])
        require(lt>0 and min(sus,existent,nsus)>=0 and existent==sus+nsus,'invalid monthly LT quantities')
        city=row['municipio_servico']; month=row['competencia']
        totals[city]+=sus; monthly[month]+=sus; monthly_lt[month]+=lt
    annual={r['municipio_servico']:r for r in aa if r['ano']==YEAR and r['municipio_servico'] in MUNICIPIOS}
    require(len(annual)==2,'expected exactly two annual coverage records')
    for city in MUNICIPIOS:
        a=annual[city]
        require(a['meses_observados']=='12' and a['meses_esperados']=='12' and a['competencias_sem_linhas_lt']=='','F2 annual coverage gap '+city)
        require(a['cobertura_presenca_linhas']=='12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED','F2 annual coverage state '+city)
        require(a['universo']=='LT_TODOS_REGISTROS_VALIDOS_RN21' and a['hospitalar_historico_validado']=='NAO','hospital scope falsely validated '+city)
        require(a['media_sus_divisor_exato']=='12' and a['media_sus_numerador_exato']==str(totals[city]) and a['qt_sus_soma_snapshots_auditoria']==str(totals[city]),'F2 monthly to annual mismatch '+city)
    require(totals['250750']==28106 and totals['250400']==16592,'F2 sums differ from #113 baseline')
    s=[r for r in scenarios if r['ano']==YEAR and r['papel']=='SERV' and r['selecao']=='JP_CG_2']
    require(len(s)==1,'F3 regional scenario absent/duplicate')
    s=s[0]
    require(s['municipios_distintos']=='2' and s['codigos_municipios']=='250400,250750','F3 region municipality mismatch')
    require(s['capacidade_estado']=='CANDIDATO_RN21_SEM_ESCOPO_HOSPITALAR','F3 hospital scope not bounded')
    require(s['capacidade_media_sus_divisor_candidato']=='12' and int(s['capacidade_media_sus_numerador_candidato'])==sum(totals.values()),'F3 capacity differs from F2')
    require(s['denominador_pop_somado_uma_vez']=='1207795','F3 population differs from frozen components')
    require(s['numerador_internacoes_elegiveis']=='119857','F3 service eligible differs from #114 baseline')
    getcontext().prec=40
    annual_sus=sum(totals.values())
    pop=int(s['denominador_pop_somado_uma_vez'])
    rate=Decimal(1000)*Decimal(annual_sus)/Decimal(12)/Decimal(pop)
    output={
       'verdict':'PASS_EXPORTED_REFERENCE_READBACK_C4B1_NO_QLIK',
       'scope':'2018 SERV JP_CG_2 LT_TODOS_REGISTROS_VALIDOS_RN21; NOT hospital validated',
       'files':{name:{'sha256':PINS[name], 'rows':len(rows[name])} for name in PINS},
       'municipios':MUNICIPIOS,'year':YEAR,
       'f2_city_sus_sum_12_snapshots':{m:totals[m] for m in MUNICIPIOS},
       'f2_monthly_regional':[{'competencia':m,'qt_sus_region':monthly[m],'lt_rows_region':monthly_lt[m]} for m in MONTHS],
       'observed_city_months':24,
       'f2_regional_sus_sum_12_snapshots_audit_only':annual_sus,
       'f2_regional_mean_sus':str(Decimal(annual_sus)/Decimal(12)),
       'f3_service_population_once':pop,
       'f3_service_eligible_internacoes':int(s['numerador_internacoes_elegiveis']),
       't25_regional_per_1000_candidate':str(rate),
       'hospital_scope_validated':False,
       'qlik_com_executed':False,
       'production_approved':False,
    }
    return output


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inputs',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    require(args.output.parent.is_dir() and not args.output.exists(),'output must be new file under existing external directory')
    require(not args.output.resolve().is_relative_to(args.inputs.resolve()),'output must be outside input directory')
    result=run(args.inputs)
    args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('C4_B1_REFERENCE='+result['verdict'])
    print('C4_B1_F2_SUS_SNAPSHOTS_AUDIT='+str(result['f2_regional_sus_sum_12_snapshots_audit_only']))
    print('C4_B1_F3_POP='+str(result['f3_service_population_once']))
    print('C4_B1_T25_PER_1000='+result['t25_regional_per_1000_candidate'])
    print('C4_B1_EVIDENCE='+str(args.output))
    print('C4_B1_COM=NOT_RUN')


if __name__=='__main__':
    try:
        main()
    except (ValueError, OSError) as exc:
        raise SystemExit(str(exc))
