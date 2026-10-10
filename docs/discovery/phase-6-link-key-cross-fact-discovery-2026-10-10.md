# Fase VI — Discovery READ-ONLY do contrato `%LINK_KEY` multífato

**Data:** 10/10/2026  
**Escopo:** SIH/RD + CNES/LT + IBGE/população para PB, 2017–2019  
**Situação:** `SERIALIZATION_CANDIDATE_PREPARED_NOT_TESTED`  
**Trilha:** Draft PR #83 / `feat/phase-5-fato-internacao-contract-discovery`

Nenhum QVD factual, `LINK_ANALISE.qvd`, `PAINEL.qvw` ou contrato final foi criado ou aprovado por este documento.

## 1. Fontes verificadas e decisões preservadas

**FATO VERIFICADO (repositório canônico):**

- `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`; Capítulos 1–2 acadêmicos permanecem fechados.
- `docs/discovery/boundary-6-qlikview-physical-architecture.md`, §§5–10, 13 e 22.5–22.6: as três fatos se conectam à `LINK_ANALISE` exclusivamente por `%LINK_KEY`; cinco coordenadas; aliases role-playing e ausência de $Syn/loops serão testados depois.
- `docs/discovery/boundary-7-implementation-plan.md`, §22: origem de cada coordenada, residência nula na capacidade, competência e estabelecimento nulos na população, deduplicação de combinações.
- `EXTRACAO/ext_main.qvs`: `EXTRACAO/QVD/SRC_SIH_RD.qvd`, `SRC_CNES_LT.qvd`, `SRC_IBGE_POPULACAO.qvd`. **O nome correto é `SRC_IBGE_POPULACAO.qvd`.**
- `TRANSFORMACAO/transf_dim_municipio.qvs`: `DIM_MUNICIPIO` contém `COD_IBGE_7`, `COD_DATASUS_6` e `%SK_MUNICIPIO`; apenas 223 municípios PB recebem o `COD_IBGE_7`, derivado dos dados oficiais com a regra validada no projeto. Os 714 códigos externos da RD não recebem associação IBGE7 inventada.
- `TRANSFORMACAO/transf_dim_estabelecimento.qvs`: `%SK_ESTABELECIMENTO = Hash128('ESTAB', CNES, COMPETENCIA)` por versão mensal.
- Resultado anterior: `FATO_INTERNACAO` — chave técnica de registro aprovada com restrições; cinco medidas CSV/QVD reconciliadas; 11 papéis dimensionais sem órfãos em duas recargas R3. Não inferir disso aprovação da Link Table.

## 2. Matriz física de coordenadas (contrato aprovado; serialização candidata)

| Coordenada em LINK_ANALISE | RD (566.672) | LT (35.518) | IBGE POP (669) |
| --- | --- | --- | --- |
| `%SK_TEMPO_COMPETENCIA` | `_META_SOURCE_COMPETENCE` → `Hash128('MES', Text(Date(Date#(...,'YYYYMM'),'YYYYMM')))` | mesmo campo e expressão, com `COMPETEN` inspecionado na extração | **Null()** (não aplicável) |
| `%SK_TEMPO_ANO` | `ANO_CMPT` → `Hash128('ANO',Num#(...))` | ano de `_META_SOURCE_COMPETENCE` → `Hash128('ANO',Num#(...))` | `ANO_REFERENCIA` → `Hash128('ANO',Num#(...))` |
| `%SK_MUNICIPIO_RESIDENCIA` | `MUNIC_RES` → `Hash128('MUN', DATASUS6)` | **Null()** (não aplicável) | `COD_IBGE_7` → `DIM_MUNICIPIO.%SK_MUNICIPIO` |
| `%SK_MUNICIPIO_SERVICO` | `MUNIC_MOV` → `Hash128('MUN', DATASUS6)` | `CODUFMUN` do **próprio LT** → `Hash128('MUN',DATASUS6)` | mesma SK da população no papel serviço |
| `%SK_ESTABELECIMENTO` | `CNES` + `_META_SOURCE_COMPETENCE` | `CNES` + `_META_SOURCE_COMPETENCE` | **Null()** (não aplicável) |

**FATO VERIFICADO:** o LT de extração possui `CODUFMUN`, portanto não é necessário adotar join ST→LT para descobrir o município de serviço nesta etapa. As 35.518 linhas LT e as 669 linhas populacionais são expectativas de staging documentadas, **não novas inspeções binárias QVD nesta execução**. A granularidade do LT continua `CNES × COMPETEN × CODLEITO`; a tabela população é `COD_IBGE_7 × ANO_REFERENCIA`.

**DECISÃO PENDENTE:** compatibilidade exata das cinco SKs para **todos** os registros LT/POP — ainda não há reload físico da candidata. A ponte de código de população usa `DIM_MUNICIPIO` versionada; **não** truncar o código IBGE7 diretamente como regra nova de fato.

## 3. HIPÓTESE DE IMPLEMENTAÇÃO — serializador versionado `SAD-LINK-V1`

O Boundary 7 traz um **exemplo conceitual**, não a fórmula final. O preflight desta Discovery avalia um candidato determinístico e tipado com a ordem fixa:

```text
COMP, ANO, MUN_RES, MUN_SERV, ESTAB
```

Cada coordenada já é uma SK de dimensão. Antes de aplicar `Hash128`:

- `Null()` verdadeiro é serializado como token `N` **somente para o papel não aplicável**;
- uma SK presente é serializada como `V` + comprimento do texto + `:` + `Text(SK)`, por exemplo, uma SK de 32 caracteres terá token `V32:<hash>`;
- cada token possui etiqueta de coordenada `C=`, `Y=`, `R=`, `S=`, `E=`; os argumentos do `Hash128` são separados, em ordem fixa, com primeiro argumento `SAD-LINK-V1`.

Assim, nulo e texto vazio não se confundem **dentro da hipótese de serialização**. A versão `V1` define apenas *candidato*. Alterar a ordem, os prefixos, a conversão de SKs ou os nulos altera todas as chaves; antes de qualquer produção, o contrato deve ser aprovado para os **três processos**.

A tag de processo (`RD`, `LT`, `POP`) serve apenas para diagnóstico por origem, **não** faz parte do hash compartilhado. Não incluir medidas nem dimensões exclusivas na chave. Eventuais colisões de hashes são detectáveis nos valores realmente observados comparando `Count(DISTINCT SERIAL)` com `Count(DISTINCT HASH)` (não é prova matemática absoluta para todos os dados futuros).

## 4. Preflight QlikView 12 somente leitura — preparado, NÃO EXECUTADO

**Arquivos versionados no Draft PR #83:**

- `TRANSFORMACAO/phase_vi_link_key_cross_fact_preflight.qvs` — leitura de **seis** QVDs, mapas em memória, união **temporária** das três fontes para conferir os 602.859 registros originais, serialização em memória (não publicada), contagens individuais e distintas. `CONCATENATE` aqui é exclusivamente o método de construir a população de teste, **não a arquitetura da Data Mart**.
- `tools/validar_link_key_cross_fact_qlik.ps1` — executor COM que cria somente `TRANSFORMACAO/P6_LINK_KEY_CROSS_FACT_PREFLIGHT.qvw`; confere os SHA-256 dos seis QVDs de entrada antes/depois, log nativo e totais por processo; não sobrescreve `TRANSF.qvw` nem escreve CSV/QVD.

**Gates objetivos de teste (hipóteses a validar):**

1. `RD=566672`, `LT=35518`, `POP=669`, total `602859`: nenhuma linha duplicada, eliminada ou descartada pela serialização;
2. todas as cinco coordenadas obrigatórias de cada processo não nulas, suas SKs existentes nos mapas dimensionais, e **null real somente nos papéis não aplicáveis**;
3. `BAD_COORD=0`, `NULL_KEY=0`, `DISTINCT_SERIAL=DISTINCT_HASH` e ao menos uma combinação distinta; se não passar, **BLOCKED**, não corrigir fonte/dimensão silenciosamente;
4. hashes SHA-256 dos seis QVDs de entrada inalterados, `FACT_QVD_GENERATED=False`, `LINK_ANALISE_QVD_GENERATED=False`;
5. veredito do script `PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED`, mesmo quando passar, **não** aprova serialização final, a Link Table nem as análises associativas do painel.

**Riscos e escopo não coberto:** não testa persistência/reload independente da `%LINK_KEY` entre fatos/QVDs, tabela `LINK_ANALISE` final deduplicada, relações role-playing em painéis, circular references ou $Syn. Também não valida agregação cruzada com leitos/população nem o problema semântico de usar simultaneamente eixos de residência e serviço. Tudo isso permanece um gate posterior.

## 5. Próxima decisão após a execução

Se houver **PASS experimental**, revisar a evidência linha a linha, decidir se a serialização candidata precisa de teste de estabilidade entre reloads (como feito com a SK RD), e submeter aprovação física explícita antes de qualquer script factual. Se houver `BLOCKED`, diagnosticar a fonte, o papel ou o token sem descartar linhas e sem substituir nulos reais por sentinelas nos campos dimensionais.

**Estado final desta Discovery:** `LINK_KEY_SERIALIZER=HYPOTHESIS_PREPARED_NOT_RUN`; `THREE_FACT_STAGING_COMPATIBILITY=NOT_TESTED`; `LINK_ANALISE=NOT_STARTED`; `FACT_QVDS=NOT_STARTED`; `PAINEL=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. A Discovery e scripts ainda pertencem a PR **Draft / sem merge**.
