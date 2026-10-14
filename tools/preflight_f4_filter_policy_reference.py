#!/usr/bin/env python3
"""F4 Discovery: derive test expectations from approved P5 matrix and D2 semantics.

Read only the canonical Discovery VI Markdown. No QlikView/COM, QVD, fact or
indicator creation. Output test *expectations*, never a Qlik physical PASS.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

DOC = Path('docs/discovery/phase-6-link-key-cross-fact-discovery-2026-10-10.md')
EXPECTED_FILTERS = (
    'Ano analitico', 'Competencia mensal', 'Municipio de residencia',
    'Municipio de servico', 'Estabelecimento CNES',
    'Procedimento realizado PROC_REA', 'Diagnostico principal DIAG_PRINC',
    'Carater do atendimento', 'Motivo de saida/permanencia',
    'Tipo/codigo de leito', 'Data clinica de internacao',
    'Data clinica de saida',
)
ROLES = ('RES', 'LEI', 'REL', 'FLU')
CODES = {'C', 'R', 'I', 'B'}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def matrix_from_doc(source: str) -> dict[str, tuple[str, ...]]:
    heading = '### 62.6 Matriz de filtros P5'
    next_heading = '### 62.7 Zero e indisponibilidade'
    require(source.count(heading) == 1 and source.count(next_heading) == 1,
            'Secoes canonicas P5 esperadas nao encontradas unicamente')
    body = source.split(heading, 1)[1].split(next_heading, 1)[0]
    lines = [line.strip() for line in body.splitlines() if line.strip().startswith('|')]
    require(len(lines) == len(EXPECTED_FILTERS) + 2,
            'Matriz P5 nao possui as doze categorias aprovadas')
    require([x.strip() for x in lines[0].strip('|').split('|')] == ['Filtro', *ROLES],
            'Cabeçalho P5 divergente')
    got = {}
    for row in lines[2:]:
        parts = [x.strip() for x in row.strip('|').split('|')]
        require(len(parts) == 5, f'Colunas da matriz inesperadas: {parts}')
        name, *codes = parts
        require(name not in got, f'Filtro duplicado: {name}')
        require(set(codes) <= CODES, f'Estado P5 não reconhecido: {name}')
        got[name] = tuple(codes)
    require(tuple(got) == EXPECTED_FILTERS, 'Categorias/ordem divergentes do contrato §62.6')
    require(all(got['Ano analitico'][i] == 'C' and got['Competencia mensal'][i] == 'C'
                for i in range(4)), 'Ano/competência alterados sem aprovação')
    return got


def temporal(years: tuple[str, ...] = (), months: tuple[str, ...] = (),
             context: str = 'PONTUAL', proposal: tuple[str, str] | None = None) -> str:
    years_set, months_set = set(years), set(months)
    require(all(re.fullmatch(r'20(?:17|18|19)', y) for y in years_set), 'Ano fora do período')
    require(all(re.fullmatch(r'20(?:17|18|19)(?:0[1-9]|1[0-2])', m) for m in months_set),
            'Competência fora do período')
    require(context in {'PONTUAL', 'SERIE_POR_ANO'}, 'Contexto inválido')
    # Only this side sees the user's PROPOSED selection; Qlik's final state may
    # already have dropped previous intent (E14/E15), so a post-hoc expression
    # cannot substitute this preselection guard.
    if proposal is not None:
        kind, value = proposal
        require(kind in {'ANO', 'COMPETENCIA'}, 'Proposta inesperada')
        if kind == 'ANO':
            require(re.fullmatch(r'20(?:17|18|19)', value) is not None, 'Ano inválido')
            if months_set and any(m[:4] != value for m in months_set):
                return 'PREVENT_CONFLICT_BEFORE_SELECTION'
            years_set.add(value)
        else:
            require(re.fullmatch(r'20(?:17|18|19)(?:0[1-9]|1[0-2])', value) is not None,
                    'Competência inválida')
            if years_set and any(year != value[:4] for year in years_set):
                return 'PREVENT_CONFLICT_BEFORE_SELECTION'
            months_set.add(value)
    from_months = {m[:4] for m in months_set}
    if years_set and from_months and not from_months <= years_set:
        return 'BLOCKED_YEAR_MONTH_INCONSISTENT'
    selected_years = years_set | from_months
    if context == 'SERIE_POR_ANO':
        return 'SERIE_SEGMENTADA_ANO_REQUER_VALIDACAO_FISICA'
    if len(selected_years) != 1:
        return 'UNAVAILABLE_YEAR_NOT_UNIQUE'
    if months_set:
        return 'PARTIAL_MONTHS_EXPLICIT_ANNUAL_POP_REFERENCE'
    return 'ANNUAL_YEAR_SINGLE_POP_REFERENCE'


def policy(codes: tuple[str, ...]) -> str:
    require(bool(codes) and set(codes) <= CODES, 'Código P5 inválido')
    if 'B' in codes:
        return 'BLOCK_GENERAL_INDICATOR'
    if 'R' in codes and 'I' in codes:
        return 'REQUIRES_SCOPED_ANALYSIS_AND_EXPLICIT_ISOLATION'
    if 'R' in codes:
        return 'REQUIRES_SEPARATE_SCOPED_ANALYSIS'
    if 'I' in codes:
        return 'REQUIRES_EXPLICIT_ISOLATION_AND_WARNING'
    return 'COMPATIBLE_CONDITIONAL_OTHER_GATES'


def csv_write(path: Path, fields: tuple[str, ...], rows: list[dict[str, str]]) -> None:
    with path.open('x', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fields, delimiter=';', lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)


def create(matrix: dict[str, tuple[str, ...]]) -> dict[str, tuple[tuple[str, ...], list[dict[str, str]]]]:
    single = []
    for name, states in matrix.items():
        for role, state in zip(ROLES, states):
            single.append(dict(filtro=name, indicador=role, politica_p5=state,
                               expectativa=policy((state,)),
                               status='REFERENCIA_SEMANTICA_NAO_TESTE_QLIK'))
    pair_cases = (
        ('RES', 'Municipio de servico', 'Ano analitico'),
        ('LEI', 'Municipio de residencia', 'Tipo/codigo de leito'),
        ('REL', 'Procedimento realizado PROC_REA', 'Ano analitico'),
        ('FLU', 'Municipio de residencia', 'Municipio de servico'),
        ('FLU', 'Tipo/codigo de leito', 'Ano analitico'),
        ('RES', 'Estabelecimento CNES', 'Municipio de residencia'),
        ('LEI', 'Diagnostico principal DIAG_PRINC', 'Municipio de servico'),
        ('RES', 'Tipo/codigo de leito', 'Ano analitico'),
    )
    pairs = []
    for role, f1, f2 in pair_cases:
        ix = ROLES.index(role)
        states = (matrix[f1][ix], matrix[f2][ix])
        pairs.append(dict(indicador=role, filtro_a=f1, politica_a=states[0],
                          filtro_b=f2, politica_b=states[1], expectativa=policy(states),
                          status='REFERENCIA_SEMANTICA_NAO_TESTE_QLIK'))
    cases = (
        ('SEM_PERIODO_PONTUAL', (), (), 'PONTUAL', None),
        ('ANO_2017', ('2017',), (), 'PONTUAL', None),
        ('MES_201709', (), ('201709',), 'PONTUAL', None),
        ('MESES_201808_201809', (), ('201808', '201809'), 'PONTUAL', None),
        ('MESES_NAO_CONTIGUOS_201801_201803', (), ('201801', '201803'), 'PONTUAL', None),
        ('MESES_201809_201909', (), ('201809', '201909'), 'PONTUAL', None),
        ('DOIS_ANOS_KPI', ('2018', '2019'), (), 'PONTUAL', None),
        ('DOIS_ANOS_SERIE', ('2018', '2019'), (), 'SERIE_POR_ANO', None),
        ('ANO_2019_PROPOR_MES_201809', ('2019',), (), 'PONTUAL', ('COMPETENCIA', '201809')),
        ('MES_201809_PROPOR_ANO_2019', (), ('201809',), 'PONTUAL', ('ANO', '2019')),
        ('ANO_2019_PROPOR_MES_201909', ('2019',), (), 'PONTUAL', ('COMPETENCIA', '201909')),
        ('MES_201809_PROPOR_ANO_2018', (), ('201809',), 'PONTUAL', ('ANO', '2018')),
        ('SEM_PERIODO_SERIE', (), (), 'SERIE_POR_ANO', None),
    )
    temporal_rows = []
    for name, years, months, context, proposal in cases:
        temporal_rows.append(dict(caso=name, anos_anteriores=','.join(years),
                                  competencias_anteriores=','.join(months), contexto=context,
                                  proposta_tipo=proposal[0] if proposal else '',
                                  proposta_valor=proposal[1] if proposal else '',
                                  resultado_esperado=temporal(years, months, context, proposal),
                                  origem='D2_P5_SEMANTIC_V2_PRESELECTION_REFERENCE_NOT_QLIK'))
    require(len(single) == 48 and len(pairs) == 8 and len(temporal_rows) == 13,
            'Contagem de casos F4 inválida')
    return {
        'F4_p5_filtros_isolados.csv': (
            ('filtro', 'indicador', 'politica_p5', 'expectativa', 'status'), single),
        'F4_p5_filtros_combinados.csv': (
            ('indicador', 'filtro_a', 'politica_a', 'filtro_b', 'politica_b', 'expectativa', 'status'), pairs),
        'F4_d2_cenarios_temporais.csv': (
            ('caso', 'anos_anteriores', 'competencias_anteriores', 'contexto', 'proposta_tipo',
             'proposta_valor', 'resultado_esperado', 'origem'), temporal_rows),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    root, out = args.root.resolve(strict=True), args.out.expanduser().resolve(strict=False)
    require(out != root and root not in out.parents and not out.exists(),
            'Saída deve ser nova e fora do repositório')
    require(out.parent.is_dir(), 'Diretório pai ausente')
    doc = root / DOC
    source = doc.read_text(encoding='utf-8')
    matrix = matrix_from_doc(source)
    results = create(matrix)
    before = sha(doc)
    print('MODE=F4_REFERENCE_CASES_SEMANTIC_ONLY')
    print('P5_MATRIX=12_FILTERS_X_4_INDICATORS')
    print('D2_CASES=13 FILTER_COMBINATIONS=8')
    staging = Path(tempfile.mkdtemp(prefix=f'.{out.name}-stage-', dir=out.parent))
    published = False
    try:
        for name, (fields, rows) in results.items():
            csv_write(staging / name, fields, rows)
        manifest = {
            'mode': 'F4_EXPECTATIONS_FROM_APPROVED_SEMANTIC_V2_NOT_PHYSICAL_VALIDATION',
            'created_utc': datetime.now(timezone.utc).isoformat(),
            'input_doc': DOC.as_posix(),
            'input_sha256': before,
            'script_sha256': sha(Path(__file__).resolve()),
            'output_sha256': {name: sha(staging / name) for name in results},
            'limits': ['No QlikView run', 'No UI preselection interception proven',
                       'No Set Analysis or indicator validation', 'No QVD or factual write',
                       'Semantic P5/D2 case catalogue only', 'Physical contracts NOT_APPROVED'],
        }
        with (staging / 'manifest_F4.json').open('x', encoding='utf-8') as f:
            json.dump(manifest, f, indent=2, sort_keys=True, ensure_ascii=False)
            f.write('\n')
        require(sha(doc) == before, 'Contrato semântico mudou durante o ensaio')
        require(not out.exists(), 'Diretório destino surgiu durante o ensaio')
        os.rename(staging, out)
        published = True
    finally:
        if not published:
            shutil.rmtree(staging, ignore_errors=True)
    print('OUTPUT_FILES_COUNT=4')
    print('VERDICT=PASS_F4_SEMANTIC_REFERENCE_GENERATION_ONLY_NOT_QV_TESTED')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, ValueError, UnicodeError, csv.Error) as exc:
        print(f'VERDICT=BLOCKED_F4_REFERENCE {type(exc).__name__}: {exc}', file=sys.stderr)
        raise SystemExit(1)
