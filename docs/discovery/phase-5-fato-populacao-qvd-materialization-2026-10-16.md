# Fase V — FATO_POPULACAO: CREATE físico + READBACK (preparação; NÃO EXECUTADO)

**Data de preparação:** 16/10/2026. **Branch:** `feat/phase-v-fato-populacao-qvd-materialization-20261015`. **Base canônica:** `main=2f7bfe63efe1ab3602ae89695de032584c6f6e9c`.

**Gate autorizado nesta execução:** somente **preparar código/documentação** de materialização candidata em branch e abrir PR Draft. **Não existe autorização de executar** `STORE`, criar qualquer QVD/QVW no Windows, rodar QlikView, fazer merge, alterar scripts anteriores ou excluir branches. **Estado:** `POP_QVD_CREATE_READBACK=READY_STATIC_ONLY_NOT_EXECUTED`.

## Fontes, contratos e justificativa

- Hierarquia: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md`, [modelagem entregue](../academic/chapter-1-2-modeling.md), [Boundary 7](boundary-7-implementation-plan.md), [automação QlikView](../project/qlikview-powershell-automation.md), [PASS em memória do PR #94](phase-5-fato-populacao-inmemory-2026-10-15.md), [preflight do PR #93](phase-5-fato-populacao-readonly-preflight-2026-10-15.md).
- **Fato verificado no repositório:** `TRANSFORMACAO/transf_fato_populacao_inmemory.qvs` da `main`, com grão **município da PB × ano**, medida `POPULACAO_ESTIMADA`, **7 campos candidatos**, 669 linhas esperadas e **nenhum STORE**. Código da ponte PB IBGE7↔DATASUS6 e das SKs municipal/anual já existe na `main`; não derivar novos códigos IBGE7, nem gerar `%LINK_KEY`.
- **Evidência física local reportada pelo responsável no PR #94**, sem inspeção independente do QVW/log binário: `SCRIPT_SHA256=3E28DECB7539E90E5314A77E7DD4E2057FDE499899AB0B943A432F117D885ADE`; `OUTPUT ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 FIELDS=7`; anuais **2017 4.025.558, 2018 3.996.496, 2019 4.018.127**. A execução in-memory **já ocorreu uma vez; não a repetir**.
- **Inventário físico local reportado:** **20 QVDs preexistentes** (10 extração/referência, 8 dimensões, 2 fatos físicas). `FATO_POPULACAO.qvd` e `LINK_ANALISE.qvd` devem estar **ausentes** antes de uma futura criação. QVDs e QVWs originais são protegidos; arquivos locais não são enviados ao GitHub.
- **Medida semi-aditiva no tempo:** uma população por município e ano; **não replicar por competência mensal nem somar anos como população de período**. Sem mudanças no Star Schema acadêmico.

## Arquivos versionáveis deste gate

| Arquivo | Papel e guarda |
| --- | --- |
| `TRANSFORMACAO/phase_v_populacao_qvd_create.qvs` | Sufixo de STORE, executável somente após o QVS in-memory aprovado, via runner com token específico datado de 16/10/2026; verifica erro, 669 linhas/7 campos, 669 pares de SK, 3 anos, nenhum nulo e destino inexistente; **único STORE** em `TRANSFORMACAO/QVD/FATO_POPULACAO.qvd`; emite `WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT` |
| `TRANSFORMACAO/phase_v_populacao_qvd_readback.qvs` | READBACK isolado: lê **apenas `QVD/FATO_POPULACAO.qvd`**, zero STORE, esquema/ordem exatos de 7 campos, 669 linhas, 669 combinações município×ano/SK, 223 municípios, 3 anos, 3 arquivos, domínio/SKs/medidas e totais anuais reconciliados |
| `tools/materializar_fato_populacao_qlik.ps1` | Adapta executor CREATE+READBACK CNES/LT já comprovado em Windows; exige `-AuthorizeCreate` somente após autorização futura; recusa branch errada/árvore rastreada suja, ausência de inputs/log PASS prévio, hash diferente do QVS previamente testado, destinos/QVWs/logs existentes e inventário diferente de 20; cria **dois QVWs novos exclusivos**, compara SHA-256 de todos os QVDs antigos e do novo QVD após READBACK; preserva arquivos em qualquer falha |
| `.gitignore` | Ignora somente os dois novos QVWs de CREATE/READBACK; QVDs e logs continuam fora do Git conforme política existente |
| Este documento | Escopo, aceitação, fontes, níveis de evidência, decisão futura e condição de parada |

O executor verifica no computador do responsável o log original `TRANSFORMACAO/V5_IBGE_FATO_POP_IMPL_PREFLIGHT.qvw.log`, que deve comprovar a execução única anterior com o mesmo perfil. **Não apagar ou reexecutar** os QVWs/logs do PR #94. `TRANSFORMACAO/transf_main.qvs` e `TRANSFORMACAO/TRANSF.qvw` não são executados/modificados.

## Critérios físicos — AINDA NÃO EXECUTADOS

**Pré-condições futuras obrigatórias:** autorização específica do responsável; execução do PowerShell com opt-in obrigatório `-AuthorizeCreate` (sem a flag, o runner encerra antes de criar QVW ou QVD); branch de execução isolada correspondente; Git clean para rastreados; 20 QVDs anteriores presentes e congelados por SHA-256; quatro entradas da população válidas; fatos `FATO_INTERNACAO.qvd` e `FATO_CAPACIDADE_LEITO.qvd` presentes; `FATO_POPULACAO.qvd`, `LINK_ANALISE.qvd` e os dois novos QVWs/logs **inexistentes**; QVS de memória com SHA-256 idêntico ao PASS do PR #94.

**CREATE esperado quando futuramente autorizado:** `V5_IBGE_FATO_POP_CREATE.qvw` carrega a candidata de memória com quatro QVDs somente leitura, valida marcadores `[V5-POP-FACT]` e executa um único `STORE` em destino novo mediante token. Só `FATO_POPULACAO.qvd` pode ser adicionada ao inventário (passando a **21 QVDs**); os 20 QVDs anteriores devem manter SHA-256. Log fresco deve conter:

```text
[V5-POP-STORE] ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 FIELDS=7
[V5-POP-STORE] VERDICT=WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT
```

**READBACK esperado quando futuramente autorizado:** um **segundo** QVW `V5_IBGE_FATO_POP_QVD_READBACK.qvw` lê só o QVD recém-gravado; confere 7 campos **em ordem**: `%SK_MUNICIPIO`, `%SK_TEMPO_ANO`, `POPULACAO_ESTIMADA`, `FATO_POP_IBGE7_ORIGEM`, `FATO_POP_DATASUS6_REFERENCIA_PB`, `FATO_POP_ANO_ORIGEM`, `FATO_POP_ARQUIVO_ORIGEM`. Grão, SKs recomputadas, domínio, unicidade e soma por ano devem ser revalidados sem usar a projeção em RAM nem reler a origem IBGE. Novo QVD deve manter **o mesmo SHA-256** entre CREATE e READBACK; todos os 20 QVDs anteriores invariantes. Marcadores previstos:

```text
[V5-POP-QVD-AUDIT] HEADER ROWS=669 FIELDS=7
[V5-POP-QVD-AUDIT] SCHEMA_EXACT_7=True
[V5-POP-QVD-AUDIT] TOTAL ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 BAD_DOMAIN=0 BAD_MEASURE=0
[V5-POP-QVD-AUDIT] ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127
[V5-POP-QVD-AUDIT] VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY
```

**PASS somente no futuro:** `VERDICT=PASS_QV_POPULACAO_QVD_MATERIALIZED_AND_REOPENED_CANDIDATE_ONLY` no PowerShell **após execução REAL** e conferência do log, com `PRODUCTION_APPROVED=False`, `LINK_ANALISE_QVD_GENERATED=False`.

**BLOCKED/INCONCLUSIVE:** sem autorização, QlikView indisponível, erro de script/log, qualquer diferença de schema/linhas/SK/medidas/hash, arquivo anterior modificado, novo QVD fora do destino, artefato já existente ou ausência do log anterior. Em erro, **não repetir o CREATE, não sobrescrever/renomear/excluir QVD parcial ou QVW/log**, preservar contexto e parar para análise; não criar R2 automaticamente.

## Encerramento da preparação

**Estado ao encerrar:** `POP_QVD_CREATE_READBACK=READY_STATIC_ONLY_NOT_EXECUTED`; evidência **estática GitHub apenas**, **nenhum QVD físico gerado ou auditado** neste gate. PR Draft **sem merge**. **Próxima decisão separada:** aprovação/revisão pré-execução e autorização expressa para o one-shot em Windows/QlikView 12. Não iniciar Fase VI (`LINK_KEY_CONTRACT=NOT_APPROVED`), PAINEL, indicadores nem produção (`PRODUCTION_APPROVED=False`).
