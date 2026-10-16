# Current State — SAD Data Mart SUS PB

**Snapshot operacional revisado em 15/10/2026 após integração do PR #88.** Este documento é um resumo de **estado atual**, não uma cronologia nem aprovação de código. Consulte evidências específicas antes de implementar. O histórico anterior permanece no [Git da versão antes da higiene](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/cf83eb3c32153d21227d6a04c80604c87b1a9319/docs/project/current-state.md) e nos `docs/discovery/`.

## 1. Objetivo e decisão acadêmica

Data Mart de demanda hospitalar SIH/SUS, capacidade de leitos CNES e população IBGE/SIDRA da Paraíba, período **2017–2019**, implementado obrigatoriamente em **QlikView 12**.

**Primeira entrega:** Capítulos 1–2, relatório impresso, informada como entregue em **13/10/2026**; avaliação/nota do professor pendente. Preservar DER, lógico normalizado, regras de negócio, grãos, Star Schema por fato e constelação com dimensões conformadas (3 fatos, 8 dimensões); não remodelar sem evidência nova e aprovação.

**Fatos previstos:** `FATO_INTERNACAO` (registro administrativo SIH/RD); `FATO_CAPACIDADE_LEITO` (estabelecimento × competência × código de leito); `FATO_POPULACAO` (município × ano).

**Dimensões aprovadas (8/8 na `main`):** `DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`, `DIM_DIAGNOSTICO`, `DIM_CARATER_ATENDIMENTO`, `DIM_MOTIVO_SAIDA_PERMANENCIA`, `DIM_TIPO_LEITO`.

Fonte: [requisitos](../academic/requirements.md), [modelagem](../academic/chapter-1-2-modeling.md), [revisão da primeira entrega](../academic/first-delivery-review.md) e [Boundary 6](../discovery/boundary-6-qlikview-physical-architecture.md)/[7](../discovery/boundary-7-implementation-plan.md).

## 2. Status por gate — não confundir PASS local com implementação

| Etapa/gate | Situação operacional em 15/10 | Referência |
|---|---|---|
| Boundaries 3–8 | **Concluídos; Boundary 8 GO** | `docs/discovery/` |
| Fases I/II — infraestrutura e conversão | **PASS local, 108/108 DBC** | `docs/discovery/boundary-8-readiness.md` e evidências da Fase II |
| Fase III — extração/staging | **PASS FINAL RECONCILED local** (10 QVDs, 107 campos, 36 competências RD/LT/ST; recarga 08/10) | [gate final](../discovery/phase-3-final-extraction-gate-2026-10-08.md) |
| Fase IV — dimensões | **8/8 integradas na main**, PR #81 merge 09/10, testes QlikView locais | [DIM_TIPO_LEITO](../discovery/phase-4-dim-tipo-leito-discovery-2026-10-09.md) |
| Fase V — SK do registro RD | **Aprovada com restrições de conteúdo+arquivo imutável**, PR #82 integrado | [pré-validação SK](../discovery/phase-5-fato-internacao-sk-preflight-2026-10-09.md) |
| Fase V — FATO_INTERNACAO (SIH/RD) | **CÓDIGO INTEGRADO À `main` pelo PR #88**; `PREFLIGHT` e `CREATE+READBACK` em dois QVWs isolados **PASS LOCAL REPORTADO** (566.672 SKs/linhas, 17 campos, 77.550 `%LINK_KEY` distintas somente RD). QVD criado na máquina do responsável, não versionado. `transf_main.qvs` mantém execução opt-in `OFF` por padrão. | [PR #88 MERGED](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/88), [evidência detalhada](../discovery/phase-5-fato-internacao-implementation-2026-10-15.md) |
| Fase V — FATO_CAPACIDADE_LEITO (CNES/LT) | **PREFLIGHT isolado PASS LOCAL REPORTADO** no QlikView 12 (35.518 LT, grão único, 36 meses, 5 papéis sem órfãos, 0 falhas de medidas, 19 QVDs preservados); script/evidência **somente no PR #90 Draft**, sem QVD factual gerado ou merge. | [PR #90 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90) |
| Fase V — FATO_POPULACAO | **IMPLEMENTAÇÃO PENDENTE**; somente após capacidade, conforme Boundary 7. | [Boundary 7](../discovery/boundary-7-implementation-plan.md) |
| Fase VI — `SAD-LINK-V1` / projeção associativa | **PASS experimental restrito; contrato final NÃO APROVADO** | [Discovery original do PR #83, §15 e posteriores](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/26369052bd3f96de5f3eccf873c390053c20b561/docs/discovery/phase-6-link-key-cross-fact-discovery-2026-10-10.md) |
| Contrato semântico de indicadores V2 | **Aprovado SOMENTE semanticamente pelo responsável em 14/10; documento INTEGRADO À MAIN** | [PR #85 MERGED](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/85) |
| Constelação completa, `LINK_ANALISE.qvd` e PAINEL | **NÃO IMPLEMENTADOS / NÃO APROVADOS em produção**; o único QVD factual gerado foi `FATO_INTERNACAO.qvd` em gate local controlado. | [Boundary 7](../discovery/boundary-7-implementation-plan.md) |

**Limites preservados:** `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED`, `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`. Testes F4/P5 e visualização em QVW descartável **não** aprovam indicadores e painéis definitivos.

## 3. Restrições de domínio e dados

- SIH/RD: **566.672** linhas, 36 competências, das quais **555.089** marcadas como novas internações (`IDENT=1`) e **11.583** continuidades (`IDENT=5`); `N_AIH` não é PK. **5.202** registros de residentes fora PB preservados, sem população PB atribuída.
- CNES/LT: **35.518** linhas nas 36 competências; capacidade anual exige média de snapshots por competência, não soma temporal. Recorte hospitalar não exclui os LT válidos da fato.
- IBGE: **669** linhas município×ano; população é semi-aditiva. O dado populacional anual não vira mensal por replicação silenciosa.
- Referência CNES **09/2019** é legenda sem vigência histórica demonstrada. Não usar descrições retroativamente; aviso explícito no futuro painel (1.965/2.021 pares-código-mês sem descrições históricas comprovadas, **não** 97,2% dos leitos).
- `TP_UNID` 2017–2019: ST/LT R2 teve auditoria independente **restrita** de logs/CSVs; R3 local reportou dez grupos em LT, mas o **log/stdout R3 ainda precisa de revisão**. Não presumir identificação de hospitais nem classificar `TP_UNID` histórico sem fonte por competência.
- Filtros ano/competência e residência/serviço na projeção Qlik causaram exclusões associativas observadas; ausência de registros sob um filtro incompatível não significa leitos ou habitantes zero. Distinguir denominador por papel e ano, conforme semântica V2 apenas.

## 4. PRs relevantes e roteiro imediato

- [PR #83](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/83) — **CLOSED WITHOUT MERGE em 15/10/2026** (209 commits/45 arquivos). A branch histórica `feat/phase-5-fato-internacao-contract-discovery` continua preservada no SHA `26369052bd3f96de5f3eccf873c390053c20b561`; recuperar protótipos seletivamente, nunca promover todos à produção.
- [PR #84](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/84) — **MERGED via squash em `6e38594c205074d012a1704986338fc9f1959608`** (15/10/2026). Scripts e evidência Fase V versionados na `main`; nenhum novo teste nativo, CI ou QVD factual produzido.
- [PR #85](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/85) — **MERGED via squash em `e8b4e848a6dfd2c9be1f93faa61c04f245cf2867`** (15/10/2026). Semântica V2 versionada na `main`, [documento específico](../discovery/phase-6-semantic-v2-approved-2026-10-14.md); expressões Qlik/denominadores físicos não aprovados.
- [PR #86](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/86) — **MERGED via squash `511957eba6129de21408bb42eeb66c87cbc3bb33`** (15/10/2026). Instruções dos agentes e snapshot operacional integrados.
- [PR #88](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/88) — **MERGED via squash `7abd1dc50c092e4235fc811fa63e4dd3a30344ac`** (15/10/2026). Script, runner de criação protegida/auditoria e evidência SIH/RD integrados à `main`; QVD local criado/reaberto com PASS reportado, sem homologação de produção.

**Próximo gate delimitado:** após `CAPACIDADE_PREFLIGHT=PASS_LOCAL_REPORTED` (evidência de stdout/log do responsável no PR #90 Draft), revisar contrato factual e **propor implementação isolada** de `FATO_CAPACIDADE_LEITO` (CNES/LT), sem STORE nem QVD factual até aprovação separada do gate CREATE. Reutilizar as validações já concluídas; preservar semiaditividade temporal, T29 e classificação hospitalar pendentes. Não repetir a pré-validação CNES/LT aprovada. Na sequência: `FATO_POPULACAO` → Fase VI Link Table → PAINEL → indicadores → dashboards. [Plano](../discovery/boundary-7-implementation-plan.md).

**Sem autorização automática:** não aprovar fisicamente a Link Table ou indicadores, não declarar `PROD_APPROVED`, não regravar o `FATO_INTERNACAO.qvd` existente, nem gerar `FATO_CAPACIDADE_LEITO.qvd`, `FATO_POPULACAO.qvd`, `LINK_ANALISE.qvd` ou `PAINEL.qvw` sem gate/autorização separados. Não realizar merges/exclusões de branches sem aceite explícito.
