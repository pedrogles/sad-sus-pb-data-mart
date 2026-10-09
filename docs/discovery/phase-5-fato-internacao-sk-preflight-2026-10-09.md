# Fase V — FATO_INTERNACAO — Discovery e gate da SK determinística (09/10/2026)

**Escopo:** evidências e contrato da SK candidata de `FATO_INTERNACAO`, sem implementar fatos, Link Table, PAINEL ou alterar os Capítulos 1–2. **Branch:** `feat/phase-5-fato-internacao-discovery`. **Estado:** `READ_ONLY_SK_PHYSICAL_GATE=PASS_2_RELOADS`; `KEY_POLICY=APPROVED_WITH_IMMUTABLE_SOURCE_AND_EXPRESSION_RESTRICTIONS`; `FACT_QVD=NOT_STARTED`.

## Fontes e decisões anteriores preservadas

1. `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`.
2. `docs/academic/chapter-1-2-modeling.md` — grão 1 registro RD / AIH processada, `N_AIH` **não PK**, `IDENT=5` é continuidade; medidas candidatas `QTD_REGISTRO_AIH`, `QTD_INTERNACAO`, `DIAS_PERMANENCIA`, `VALOR_TOTAL`, `INDICADOR_OBITO`.
3. `docs/discovery/boundary-3-full-dataset-validation.md` — 36 RD, 566.672 registros, 11.583 `IDENT=5`, 880 linhas excedentes em grupos mensais `N_AIH` duplicados, 5.202 residentes externos à PB.
4. `docs/discovery/boundary-6-qlikview-physical-architecture.md` — Link Table **já aprovada** para a etapa VI; fato internação terá apenas `%LINK_KEY` como ligação com `LINK_ANALISE` e manterá dimensões exclusivas por chave intencional. Não criar Link Table nesta etapa.
5. `docs/discovery/boundary-7-implementation-plan.md` — `Hash128` determinística; Fase V fato Internação primeiro, depois Capacidade e População.
6. `EXTRACAO/ext_main.qvs` — staging `SRC_SIH_RD.qvd` com 17 campos de dados e `_META_SOURCE_FILE`, `_META_SOURCE_FAMILY`, `_META_SOURCE_COMPETENCE`, `_META_SOURCE_PATH`.

## Scripts agora versionados

- `tools/preflight_fase_v_fato_internacao.py`: leitura **somente de** 36 CSVs RD e header XML do QVD de staging/dimensões; não decodifica o corpo binário QVD.
- `TRANSFORMACAO/phase_v_fato_internacao_qlik_sk_preflight.qvs`: QlikView 12, LOAD isolado do QVD de staging, contagem e unicidade da `Hash128`; **não incluir em `transf_main.qvs`**.
- `tools/criar_v5_rd_sk_preflight.ps1`: versão para novas instalações que cria QVW de teste lendo o **QVS versionado** (não incorpora segunda cópia do QVS). **Este refactor ainda não foi reexecutado no Windows**; o criador original avulso com script embutido foi usado em 09/10/2026 e criou `V5_RD_SK_PREFLIGHT.qvw` (133.120 bytes). Como o QVW local já existe, não reexecutar o criador.
- `tools/validar_v5_rd_sk_com_log.ps1`: ativa log nativo em QVW isolado e confere reload/contagens/hash de staging.
- `tools/validar_estabilidade_sk_fato_internacao.ps1`: cria **cópia temporária** do script do QVW local validado, realiza duas recargas Qlik independentes, exporta *somente* SKs para TEMP, compara conjuntos completos (não apenas quantidade) e apaga diagnóstico após PASS.

As ferramentas de teste não são scripts de produção e **não são executadas como parte da extração/transformação normal**. Não versionar QVWs, QVDs, CSVs de grandes bases, logs nem exports temporários.

## SK candidata física e política aprovada

Expressão concreta aprovada **somente para origem congelada 2017–2019**:

```qlik
Hash128(
  'RD', Text(_META_SOURCE_FILE), Text(ANO_CMPT), Text(MES_CMPT),
  Text(N_AIH), Text(IDENT), Text(MUNIC_RES), Text(MUNIC_MOV), Text(CNES),
  Text(PROC_SOLIC), Text(PROC_REA), Text(DIAG_PRINC), Text(CAR_INT),
  Text(COBRANCA), Text(DT_INTER), Text(DT_SAIDA),
  Text(DIAS_PERM), Text(VAL_TOT), Text(MORTE)
)
```

- `N_AIH` **não** é PK e não foi assumida unicidade semântica em nenhuma combinação mais curta.
- A SK é uma impressão digital de conteúdo/arquivo, **não identifica imutavelmente a AIH clínica/administrativa quando há correção do conteúdo**. Alterações de campos, formato `Text()`, número de argumentos, ordem ou fonte exigem nova validação, reconciliação e revisão de contrato.
- Para reproduzir SKs, preservar entrada histórica (hashes de artefatos locais/manifestos), versão do script, tipos e normalização/representação textual. Evitar `AutoNumberHash128` para chave persistente.
- Correções futuras no registro podem mudar a chave; manutenção incremental futura **não é automaticamente aprovada**. Chave técnica de fato, não elemento de negócio.
- Separar política de SK da regra `IDENT=5 -> QTD_INTERNACAO=0`; ambos requisitos permanecem distintos.

## Evidência empírica fornecida pelo responsável

**A — Python READ-ONLY sobre CSVs e header QVD (09/10/2026):**

```text
MODE=PHASE_V_FATO_INTERNACAO_CSV_QVD_HEADER_READ_ONLY_PREFLIGHT
RD_FILES=36
RD_COMPETENCES=36
RD_ROWS=566672
RD_YEAR_ROWS=[('2017', 187726), ('2018', 187293), ('2019', 191653)]
IDENT5_ROWS=11583
IDENT1_ROWS=555089
RD_RESIDENCE_EXTERNAL_ROWS=5202
N_AIH_MONTHLY_EXTRA_ROWS=880
PROJECTED_COLUMNS=17+SOURCE_FILENAME
PROJECTED_SHA256_DISTINCT=566672
PROJECTED_SHA256_DUPLICATE_ROWS=0
INVALID_IDENT=0 INVALID_MORTE=0 INVALID_CAR=0
INVALID_COMPETENCE=0 INVALID_DATES=0 INVALID_MEASURES=0
RD_QVD_ROWS=566672
DIMENSION_HEADER_DIM_TEMPO=PASS
DIMENSION_HEADER_DIM_MUNICIPIO=PASS
DIMENSION_HEADER_DIM_ESTABELECIMENTO=PASS
DIMENSION_HEADER_DIM_PROCEDIMENTO=PASS
DIMENSION_HEADER_DIM_DIAGNOSTICO=PASS
DIMENSION_HEADER_DIM_CARATER_ATENDIMENTO=PASS
DIMENSION_HEADER_DIM_MOTIVO_SAIDA_PERMANENCIA=PASS
VERDICT=PASS_READ_ONLY_CSV_QVD_HEADER_SK_DECISION_PENDING
```

**B — QlikView 12, QVW isolado; log contemporâneo às 18:02:14 locais (09/10/2026):**

```text
[V5-RD-SK] ROWS=566672 DISTINCT_SK=566672 NULL_SK=0 IDENT5=11583 IDENT1=555089 MONTHS=36 SOURCE_FILES=36
[V5-RD-SK] VERDICT=PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY
STAGING_QVD_SHA256_UNCHANGED=True
```

**C — comparação exata de 2 recargas independentes do QlikView 12 (09/10/2026):**

```text
MODE=PHASE_V_SK_2_INDEPENDENT_QLIKVIEW_RELOADS
RUN_1_PASS_QV_PROFILE=True
RUN_2_PASS_QV_PROFILE=True
RUN_A_ROWS=566672 RUN_B_ROWS=566672
RUN_A_UNIQUE_SK=566672 RUN_B_UNIQUE_SK=566672
RUN_A_SORTED_SET_SHA256=7e2a28f513d6bb1d7b01ecbc4809d9e97824f3a782ca2e7ed987954005115126
RUN_B_SORTED_SET_SHA256=7e2a28f513d6bb1d7b01ecbc4809d9e97824f3a782ca2e7ed987954005115126
ONLY_A_KEYS=0 ONLY_B_KEYS=0
VERDICT=PASS_2_RELOADS_EXACT_566672_SK_SET_MATCH
KEY_SCOPE=IMMUTABLE_2017_2019_SOURCE_SNAPSHOT_ONLY
ORIGINAL_QVW_SHA256_UNCHANGED=True
STAGING_QVD_SHA256_UNCHANGED=True
KEY_POLICY=APPROVED_WITH_IMMUTABLE_SOURCE_AND_EXPRESSION_RESTRICTIONS
FACT_IMPLEMENTATION=NOT_STARTED
TEMPORARY_DIAGNOSTICS_REMOVED=True
```

**FATO VERIFICADO por saída de execução compartilhada:** as recargas e a comparação exata passaram, com **zero diferença entre conjuntos de SK**. Auditor não acessou diretamente o QVW/QVD binário local nem o log completo; não reinterpretar esse PASS como prova de estabilidade após modificações na fonte. Os SHA-256 acima são das listas ordenadas exportadas, **não** dos arquivos originais RD/QVD.

## Próximos gates

1. Revisar a branch/PR de versionamento de scripts e esta Discovery.
2. Após integração autorizada do contrato, implementar a primeira fato em **branch própria ou continuação controlada da Fase V**, usando exatamente a expressão aprovada e separando **fato** de **Link Table**.
3. Exigir QlikView 12 real: 566.672 linhas/566.672 SK, `IDENT5=11583` sem contabilizar como nova internação, zero dimensional unmatched, medidas contra fonte, 36 competências, `QVD` e checkpoint locais, sem alterar `SRC_SIH_RD.qvd`.
4. A implementação da Link Table, os indicadores e o PAINEL seguem fases VI–IX, sem antecipação.
5. Preservar `T29_HISTORICAL=NOT_APPROVED` e obrigatoriedade de ressalva visível de capacidade CNES (1.965/2.021 pares-mês sem descrição histórica comprovada, **não percentual de leitos**). Capítulos 1–2 fechados.

## Revisão de integração do Draft PR #82 — 09/10/2026

**FATO VERIFICADO (repositório GitHub):** diff com exatamente **7 arquivos** restritos a cinco scripts de preflight/automação e duas documentações, branch **7 commits ahead / 0 behind** de `main`; nenhum QVW, QVD, log, dataset, script de produção `transf_main.qvs`, alteração das oito dimensões, Link Table ou PAINEL. GitHub confirmou PR `open`, `draft=true`, `mergeable=true`, `mergeable_state=clean` e nenhuma revisão/comentário no momento da consulta; no head `5810945fed3b7c264c1aaed8cdeca99b2e1ed517`, **0 check-runs/0 statuses**, não equivalentes a CI PASS.

**Verificações estáticas auxiliares executadas fora do Windows:** compilação sintática do Python sem escrever bytecode no repositório; ensaios básicos de determinismo e diferenciação de arquivo/conteúdo da projeção SHA-256, validação de data e número. QVS possui os 17 campos do contrato mais `_META_SOURCE_FILE`, com `Hash128('RD', ...)`, sem `STORE` ou criação de fato. O QVS embutido no criador COM original (que executou no Windows) foi conferido como idêntico ao QVS do pacote usado nos testes originais; o conteúdo do QVS agora versionado também corresponde à expressão e sequência do preflight registrado. Não foram executados novos reloads no agente.

**Limite de revisão explícito:** o novo `tools/criar_v5_rd_sk_preflight.ps1` foi refatorado para ler o QVS versionado; **não foi executado em Windows/QlikView 12** após a refatoração. Ele é ferramenta auxiliar para criar **um novo documento isolado**, com guarda contra sobrescrita, e não compõe o caminho de produção nem é necessário para validar o gate histórico já obtido. Se usado futuramente, deverá ser testado de forma específica antes de ser considerado PASS. Os scripts `validar_v5_rd_sk_com_log.ps1` e `validar_estabilidade_sk_fato_internacao.ps1` possuem execução local com as saídas documentadas neste arquivo; não é CI.

**Decisão para o PR:** nenhuma alteração estrutural constatada na revisão estática; apto à **promoção e merge controlado sob autorização do responsável**, mantendo a limitação de teste do criador refatorado e a política de fonte imutável. Não iniciar implementação factual automaticamente.

## Integração controlada do PR #82 — 09/10/2026

**FATO VERIFICADO (GitHub):** após revisão estática dos 7 arquivos e autorização para prosseguir, o Draft [PR #82](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/82) foi marcado `ready for review` e integrado à `main` via **squash merge com guarda `expected_head_sha=41bc2a5a5abb40037d6166595119505b749f71f9`**. A confirmação do GitHub retornou `merged=true` e commit de integração `ceacef87a6a5a77299a87743133ec9b86aca9b24` em **2026-10-09T22:12:28Z**. Antes da integração, `base=af3b026ccc0042b798b983cea6c3df16dbb61290`, `head=41bc2a5a5abb40037d6166595119505b749f71f9`, `mergeable_state=clean`, 7 arquivos no diff, nenhum QVW/QVD/CSV/log ou mudança em `transf_main.qvs`, scripts dimensionais, fatos, Link Table, PAINEL ou material acadêmico. Não foram detectadas revisões ou checks no head consultado.

**Ressalva pós-integração:** o refactor em `tools/criar_v5_rd_sk_preflight.ps1` que lê o QVS versionado **não recebeu execução nova no Windows**. O criador original (embutido) e os demais testes locais foram executados pelo responsável; a verificação estática comprovou identidade do QVS do pacote com a versão embutida do criador original. Isso não deve ser apresentado como `PASS` de COM refatorado, CI ou auditoria QVD binária integral. Não executar o criador se o arquivo `V5_RD_SK_PREFLIGHT.qvw` já existir.

**Gate fechado nesta integração:** `FATO_INTERNACAO_SK=APPROVED_WITH_IMMUTABLE_SOURCE_AND_EXPRESSION_RESTRICTIONS`; `PHASE_V_SK_SCRIPTS=VERSIONED_IN_MAIN`. **Gate seguinte separado:** verificar operacionalmente contrato das medidas, chaves conformadas, integridade e esquema da `FATO_INTERNACAO` antes de iniciar o script de produção em branch própria; `FACT_QVD=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`, `PAINEL=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`.
