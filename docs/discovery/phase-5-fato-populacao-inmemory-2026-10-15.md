# Fase V — FATO_POPULACAO: implementação candidata exclusivamente em memória

**Preparação:** 15/10/2026. **Main de origem:** \`ff161025773798d893e7c02c60631e4059d0b234\`. **Branch:** \`feat/phase-v-fato-populacao-inmemory-20261015\`.

**Estado:** \`POP_FACT_INMEMORY=READY_STATIC_ONLY_NOT_EXECUTED\`; PR Draft sem merge. Autorização do responsável: próximo gate Fase V, construir/testar a candidata em memória no QlikView 12, **sem QVD, sem Link Table, sem alteração da main nem merge automático**. Este documento é Discovery/evidência de preparação, não comprovação de PASS nativo.

## Contratos, fontes e invariantes

1. Autoridade: [AGENTS.md](../../AGENTS.md) → [current-state](../project/current-state.md) → [requisitos](../academic/requirements.md) → [Boundary 7](boundary-7-implementation-plan.md), [modelagem entregue](../academic/chapter-1-2-modeling.md) e [preflight populacional R2 integrado (#93)](phase-5-fato-populacao-readonly-preflight-2026-10-15.md).
2. O **PASS local reportado** da R2/#93 verificou fonte IBGE 669 linhas, 223 municípios, 3 anos (2017–2019), ponte projeto IBGE7↔DATASUS6 com 223 pares, SK de município \`Hash128('MUN', DATASUS6)\`, SK anual \`Hash128('ANO',ano)\`, ausência de órfãos, população inteira positiva e totais estaduais anuais. **Não refazer R1/R2**.
3. A candidata é **uma linha por município da PB × ano**, sem replicação por mês: \`POPULACAO_ESTIMADA\` é snapshot anual semiaditivo. Não somar 2017+2018+2019 como população do período. Não imputar residentes externos à população da PB.
4. Fontes reais QVD existentes, **somente leitura**: \`EXTRACAO/QVD/SRC_IBGE_POPULACAO.qvd\`, \`EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.qvd\`, \`TRANSFORMACAO/QVD/DIM_MUNICIPIO.qvd\`, \`TRANSFORMACAO/QVD/DIM_TEMPO.qvd\`. A ponte foi derivada **apenas** do projeto PB em III-C5.2; nenhum dígito de IBGE7 é inventado por este gate.
5. Preservar os **20 QVDs existentes** (10 staging/referência, 8 dimensões, 2 fatos), todos os QVWs/logs diagnósticos prévios e \`TRANSFORMACAO/TRANSF.qvw\`. Não executar \`transf_main.qvs\`. Não executar \`STORE\`, gerar \`FATO_POPULACAO.qvd\`, \`LINK_ANALISE.qvd\`, \`PAINEL.qvw\`, nem aprovar contrato \`%LINK_KEY\`.

## Projeção candidata proposta (NÃO aprovada fisicamente)

O script \`TRANSFORMACAO/transf_fato_populacao_inmemory.qvs\` cria **somente tabela residente temporária no QVW diagnóstico**, nome \`FATO_POPULACAO\`, com **sete colunas candidatas**:

| Campo candidato | Origem e papel |
| --- | --- |
| \`[%SK_MUNICIPIO]\` | lookup do \`DIM_MUNICIPIO.qvd\` pelo código DATASUS6 resolvido pela ponte PB (não inferido) |
| \`[%SK_TEMPO_ANO]\` | lookup de \`DIM_TEMPO.qvd\` pelo ano, sem granularidade mensal |
| \`POPULACAO_ESTIMADA\` | medida observada em \`SRC_IBGE_POPULACAO.qvd\`; sem agregação na linha |
| \`FATO_POP_IBGE7_ORIGEM\` | código IBGE7 observado no staging (rastreabilidade) |
| \`FATO_POP_DATASUS6_REFERENCIA_PB\` | código DATASUS6 vindo da referência derivada PB (rastreabilidade) |
| \`FATO_POP_ANO_ORIGEM\` | ano observado na linha original |
| \`FATO_POP_ARQUIVO_ORIGEM\` | arquivo-fonte do staging |

Os quatro últimos campos são **auxiliares candidatos de auditoria**, não alteração aprovada da modelagem acadêmica nem proposta de nova dimensão ou grão. \`[%SK_MUNICIPIO]\` e \`[%SK_TEMPO_ANO]\` são apenas validação de papel dentro deste QVW isolado. A Fase VI exigirá decisão separada sobre a representação via \`%LINK_KEY\` e \`LINK_ANALISE\`; **não foi criada serialização/hashing de link cross-fact**.

## Teste físico local autorizado (a executar uma única vez)

\`tools/validar_fato_populacao_inmemory_qlik.ps1\` reutiliza o padrão comprovado de executor COM do PR #93, com **novo QVW diagnóstico** \`TRANSFORMACAO/V5_IBGE_FATO_POP_IMPL_PREFLIGHT.qvw\` e \`.qvw.log\`, ignorados no Git. Recusa QVW/log já existentes, branch divergente, arquivos rastreados modificados, fonte ausente, QVD factual populacional/Link Table preexistente, sintaxe de IF multiline, \`STORE\`, carga fora dos quatro QVDs, includes, \`JOIN\`, BINARY/EXECUTE ou \`%LINK_KEY\` candidata, com inventário congelado/SHAs dos 20 QVDs antes/depois/encerramento.

**Critério estrito para \`PASS_LOCAL_REPORTED\`:**
- QlikView 12 faz \`Reload()\` de QVW diagnóstico isolado e gera log contemporâneo com marcadores \`[V5-POP-FACT]\`, sem erros, em modo \`PREFLIGHT\`.
- \`SOURCE ROWS=669 GRAIN=669 MUNICIPIOS=223 YEARS=3 FILES=3 MISS=0 BAD_DOMAIN=0 BAD_MEASURE=0 BAD_SK=0\`.
- \`OUTPUT ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 FIELDS=7\`.
- \`ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127\` (totais já reconciliados na extração e no preflight).
- \`VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_QVD_APPROVED\` no log e \`VERDICT=PASS_LOCAL_POPULATION_IN_MEMORY_CANDIDATE_ONLY\` no console, **apenas quando efetivamente executados**.
- \`ALL_20_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_RELOAD/AT_END\`, \`NO_NEW_QVD_GENERATED=AFTER_RELOAD/AT_END\`, \`FACT_POPULACAO_QVD_GENERATED=False\` e \`LINK_ANALISE_QVD_GENERATED=False\`.

**Critério BLOCKED:** qualquer divergência, ausência de log fresco, diferença de SHA/contagem/medidas/chaves ou QVW já existente. Preservar arquivos/logs, não repetir automaticamente nem alterar dados. Revisão de binários independente não foi realizada nesta etapa.

Execução local na raiz do repositório, **após revisar o PR Draft**:

\`\`\`powershell
git fetch origin
git switch feat/phase-v-fato-populacao-inmemory-20261015
git pull --ff-only
git status

powershell.exe -NoProfile -File .\tools\validar_fato_populacao_inmemory_qlik.ps1 -Root (Get-Location).Path
\`\`\`

**Parada:** assim que o stdout do **primeiro teste local** for recebido e o veredito do gate for qualificado. Não efetuar mais recargas, R2/R3 preventivas ou materialização QVD, sem autorização expressa em novo escopo. \`LINK_KEY_CONTRACT=NOT_APPROVED\`, \`PRODUCTION_APPROVED=False\`. A \`main\` e o \`current-state.md\` não são alterados neste PR.
