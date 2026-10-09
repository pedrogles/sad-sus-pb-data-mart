# Current State — SAD Data Mart SUS PB

**Atualização de higiene:** 08/10/2026  
**Fonte de verdade operacional resumida.** A cronologia integral anterior foi preservada, sem perda do conteúdo original, em [current-state-chronology-2026-10-08.md](current-state-chronology-2026-10-08.md). Evidências pormenorizadas continuam nos documentos `docs/discovery/`.

## 1. Projeto, entrega e prioridade

- Disciplina **Sistemas de Apoio à Decisão**, Sistemas de Informação, 2026.2; **QlikView 12 obrigatório**.
- Objetivo: Data Mart da **demanda de internações SIH/SUS, capacidade de leitos CNES e população IBGE** na Paraíba, **2017–2019**.
- Primeira entrega acadêmica (**Capítulos 1 e 2**, relatório impresso em **13/10/2026**): modelagem **FECHADA — PRONTA PARA IMPRESSÃO/ENTREGA** desde 02/10; não reabrir por causa de ajustes de staging.
- A origem baseada em arquivos está sujeita à **avaliação caso a caso pelo professor**, conforme os requisitos oficiais.
- Próxima prioridade operacional: **Fase IV — próxima `DIM_DIAGNOSTICO`**, após integração da `DIM_PROCEDIMENTO` pelo PR [#77](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/77) via squash `4ecd27fc3cfa96ffd8c784128650323b197d5892`, com autorização explícita, em 09/10/2026. Estado integrado da `main`: **4/8 dimensões** (`DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`). Evidência do quarto checkpoint local: reload QlikView 12 concluído 09:24:48 (165203 procedimentos SIGTAP × competência, 36 meses, 0 inválidos, RD 566672/0 unmatched), QVD 165203 linhas/12 campos SHA-256 `620b3f9d4d1babdf25b2d1f2f5653ad7089e4003986048bdb746b5662f2de56b`, checkpoint parcial SHA-256 `b6180cecb7b91b93d2fd5906ed7034549ce38105cde4d6d0eb0f03b4a7639543`; auditor independente local PASS de QVD cabeçalho/checkpoint (limite: QVD binário não decodificado). SIGTAP staging CSV enriquecido 10 campos/165203 linhas e 216 membros físicos auditados, sem gravar datasets grandes no Git. **Próximo gate somente descoberta read-only de CID-10 para DIM_DIAGNOSTICO**, conforme `docs/discovery/phase-3-cid10-reference-implementation-2026-10-07.md`, T28 e Boundary 7; nenhuma transformação antes de inspecionar dados/chaves. Não alterar relatório impresso Capítulos 1–2; `DESCRICAO_OFICIAL` detalhada da dimensão de procedimento permanece NULL/status sem campo fonte; SIGTAP 201808 versão retrospectiva, `T29_HISTORICAL=NOT_APPROVED`, fatos/Link Table/PAINEL NOT_STARTED. Evidências de procedimento em `docs/discovery/phase-4-dim-procedimento-preflight-2026-10-09.md`.

Referências: [requirements.md](../academic/requirements.md), [chapter-1-2-modeling.md](../academic/chapter-1-2-modeling.md), [first-delivery-review.md](../academic/first-delivery-review.md).

## 2. Arquitetura e modelagem aprovadas — preservar

**Três fatos:**
`FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`.

**Oito dimensões:**
`DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`, `DIM_DIAGNOSTICO`, `DIM_CARATER_ATENDIMENTO`, `DIM_MOTIVO_SAIDA_PERMANENCIA`, `DIM_TIPO_LEITO`.

**Estrutura:** Star Schema por fato, compondo constelação de estrelas com dimensões conformadas.

**Grãos confirmados:**
- internação: **uma linha por registro administrativo SIH/RD (AIH processada)**; `IDENT=5` representa continuidade, não nova internação; `N_AIH` não é PK;
- capacidade: **estabelecimento × competência × código de leito**; chave operacional `CNES + COMPETEN + CODLEITO`; medida **semi-aditiva no tempo**;
- população: **município × ano**; medida **semi-aditiva no tempo**.

**Integrações e ressalvas:** `SIH.CNES ↔ ST.CNES ↔ LT.CNES` e `SIH.MUNIC_MOV ↔ CNES.CODUFMUN` foram observadas com 100% de cobertura na validação integral. `MUNIC_RES` pode representar residentes de fora da PB (5.202 RD observados); município de residência e município de atendimento têm papéis distintos. Não fabricar dígito IBGE; não equiparar `internações/leito` a **taxa de ocupação**. Para capacidade anual usar **média de snapshots mensais**, não soma de leitos. Preservar todos os LT válidos; recorte hospitalar é analítico. A série populacional de 2017 e 2018 inclui diferença de base metodológica/projecional entre publicações, sem inferir crescimento observado da simples diferença.

**Fluxo QlikView obrigatório:**

```text
BASE → EXTRACAO / EXT.qvw → QVD → TRANSFORMACAO / TRANSF.qvw
     → QVD → PAINEL / PAINEL.qvw
```

Scripts externos versionáveis: `EXTRACAO/ext_main.qvs`, `TRANSFORMACAO/transf_main.qvs`, `PAINEL/painel_main.qvs`. QVWs, QVDs e grandes bases permanecem locais e ignorados pelo Git. Não implementar fatos, dimensões ou Link Table antes do gate de transformação.

Decisões detalhadas em [boundary-5](../discovery/boundary-5-historization-role-playing.md), [boundary-6](../discovery/boundary-6-qlikview-physical-architecture.md) e [boundary-7](../discovery/boundary-7-implementation-plan.md).

## 3. Estado de execução

| Etapa | Estado verificado | Evidência |
|---|---|---|
| Feasibility / Dataset Discovery e Boundaries 3–7 | **CONCLUÍDOS** | `docs/discovery/` |
| Boundary 8 — Readiness QlikView 12 | **GO / PASS** | [Readiness](../discovery/boundary-8-readiness.md) |
| Fase I — infraestrutura mínima | **PASS** | QVW e includes recarregados |
| Fase II — conversão DBC → CSV | **PASS** | 108/108 arquivos, T01–T06 |
| Fase III — extração / staging | **PASS — EXTRACTION RECONCILED** | Reload QlikView 12 em 08/10/2026 21:46:48: 10/10 QVDs, 107/107 campos T08, T07 3×36, novo `_SUCCESS_EXTRACAO.csv`, runner SHA-256 PASS |
| Fase IV — Dimensões | **IN PROGRESS — 4/8 INTEGRADAS NA MAIN; IV-PROCEDIMENTO MERGED PR #77 / IV-DIAGNOSTICO DISCOVERY NEXT** | Integração `DIM_PROCEDIMENTO` por squash `4ecd27fc3cfa96ffd8c784128650323b197d5892` (PR #77) em 09/10/2026. Local QlikView 12: 165203 versões em 36 meses, 12 campos/165203 SK únicas, QVD SHA `620b3f9d4d1babdf25b2d1f2f5653ad7089e4003986048bdb746b5662f2de56b`, RD 566672/0 unmatched e checkpoint PASS parcial SHA `b6180cecb7b91b93d2fd5906ed7034549ce38105cde4d6d0eb0f03b4a7639543`. 216 arquivos SIGTAP de hierarquia e staging enriquecido independentes reconciliados. Limitações: `DESCRICAO_OFICIAL=NULL` sem campo detalhado, cp1252 apenas operacional, SIGTAP 201808 versão retrospectiva, `T29_HISTORICAL=NOT_APPROVED`. Próximo gate `DIM_DIAGNOSTICO` CID-10/T28 read-only; fatos/Link Table/PAINEL NOT_STARTED. Ver `docs/discovery/phase-4-dim-procedimento-preflight-2026-10-09.md` |
| Fatos, Link Table e PAINEL | **NÃO INICIADOS** | Boundaries seguintes; sem implementação antecipada |

### Fase III — checkpoints

| ID | Situação | Resultado local confirmado |
|---|---|---|
| III-A — Saúde RD/LT/ST | **PASS** | 36 competências por família; 566.672 RD, 35.518 LT, 220.390 ST, QVDs `SRC_*` |
| III-B — IBGE | **PASS** | 669 linhas; 223 municípios × 3 anos; QVD `SRC_IBGE_POPULACAO` |
| III-C1 — Caráter e Motivo de Saída | **PASS** | 6 e 28 registros de referência; 0 RD unmatched; QVDs de referência |
| III-C2 — CID-10 / T28 | **PASS** | Referência descritiva `201912` de 14.230 códigos; 566.672 RD cobertos, 0 unmatched; QVD |
| III-C3 — SIGTAP / T27 | **PASS** | Referência por 36 competências, 165.203 procedimentos/linhas e 566.672 RD cobertos, 0 unmatched; QVD |
| III-C4 — Legenda CNES set/2019 | **PASS LOCAL — STAGING DESCRITIVO DATADO** | Python + QlikView 12 executados em 08/10/2026; 65 pares na legenda, 57/57 pares PB, 35.518/35.518 LT, 36 competências, 0 unmatched; checkpoint `PASS_PARTIAL_SNAPSHOT_ONLY` |
| III-C5 — Piloto municipal DATASUS↔IBGE | **PASS LOCAL — CANDIDATO 1:1 PB** | Reload QlikView 12 em 08/10/2026 20:46:59; 223 IBGE7 distintos e 223 prefixos6 únicos; 0 unmatched ST/LT/atendimento/residência PB; 5.202 RD fora PB separados. Piloto não materializou a ponte, que foi materializada no checkpoint III-C5.2 seguinte |
| III-C5.2 — Referência municipal PB derivada | **PASS LOCAL — QLIKVIEW 12 + AUDITORIA SHA-256** | Reload em 08/10/2026 21:03:53; 669 registros IBGE, 223 pares DATASUS6↔IBGE7 únicos, zero inválidos/unmatched PB, 5.202 RD não-PB preservados, referência QVD e CSV gerados. Python `VERDICT=PASS_LOCAL_REFERENCE_AUDIT`; hashes dos 3 XLS e QVDs no manifesto local |
| III-FINAL — Reconciliação T07/T08 e marcador | **PASS LOCAL — QLIKVIEW 12 + RUNNER SHA-256** | Em 08/10/2026 21:46:48: `PASS_FINAL_RECONCILED`, 10 QVDs novos, 107 campos T08, 3×36 T07, referências C1–C5 compatíveis; Python `VERDICT=PASS_LOCAL_QV_AND_SHA_RECONCILIATION`, exit 0, SHA-256 marcador `f4a8304e41236802be030061698e77fc32ed5eee2bcc8cdbc28b70bf32cd600f`; log atual sem os erros de sintaxe anteriores |
| T29 — validade normativa histórica integral | **NÃO APROVADO** | Vigência de todos os pares para cada competência `201701–201912` não demonstrada |

**Conflito de fonte CNES:** indicador agregado CNESNet apresentou `2/66`, mas o perfil PB, a Nota Técnica MS de setembro/2019 e outras fontes registram `3/66 — UNIDADE ISOLAMENTO / COMPLEMENTAR`. Não reclassificar automaticamente os dados. O RTS só exibiu Leitos a partir de `10/2019A` no ensaio manual; isso não significa criação de códigos nessa data.

**DECISÃO APROVADA PELO RESPONSÁVEL DO PROJETO (08/10/2026):** utilizar a tabela da Nota Técnica MS 32/2019 como **legenda auxiliar com competência de referência 201909**, sem inferir classificação, descrição ou status normativamente válidos nos meses anteriores/posteriores. Preservar `TP_LEITO`/`CODLEITO`/competência e quantidades originais; não realizar JOIN retroativo da legenda na LT. O contrato de chave competência-aware do Boundary 7 permanece. **T29 histórico segue NÃO APROVADO.** A materialização Python e o reload QlikView 12 foram executados localmente em 08/10/2026, com `LEGEND_SHA256=dddb261e754f2f3bb82a462c94ae8219b84cd77c1fce3204cd6f3867c3d3bd5e` e checkpoint `EXTRACAO_CNES_LEITO_201909;PASS_PARTIAL_SNAPSHOT_ONLY;65;35518;57;36;0;201909;NOT_VERIFIED;NOT_APPROVED`. O arquivo QVD não foi inspecionado independentemente neste chat.

**Ressalva de ST:** evitar imputar versões futuras a estabelecimentos históricos; lacuna de razão social/nome fantasia em `201701–201705` permanece quando não houver fonte comprovada. `STPB1912.dbc` apresenta drift técnico de schema de 2019-12; preservar seleção por nomes e tolerância verificada.

Evidências específicas: [Saúde](../discovery/phase-3-health-staging-implementation-2026-10-07.md), [IBGE](../discovery/phase-3-ibge-staging-implementation-2026-10-07.md), [Referências normativas](../discovery/phase-3-normative-references-implementation-2026-10-07.md), [CID-10](../discovery/phase-3-cid10-reference-implementation-2026-10-07.md), [SIGTAP](../discovery/phase-3-sigtap-proc-rea-implementation-2026-10-08.md), [CNES leitos](../discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md).

## 4. Higiene do repositório — concluída

**PASS em 08/10/2026:** PR #69 de higiene documental integrado à `main`; o usuário executou o executor de branch hygiene v3 após dry-run completo. Registro de aplicação: `POSTCHECK=PASS REMOTE_BRANCHES=8 DELETED=70 PROTECTED=8`. Consulta remota independente confirmou oito branches (a `main`, `chore/repository-hygiene-2026-10-08` e seis branches `HOLD`). Nenhuma outra exclusão está autorizada. Manifesto e log de rollback permanecem locais em `BASE/REFERENCIAS`.

Detalhes: [repository-hygiene-review-2026-10-08.md](repository-hygiene-review-2026-10-08.md).

## 5. Sequência segura — histórico da Fase III e transição para Fase IV

1. **Checkpoint III-C4.3 ENCERRADO — PASS de snapshot datado:** manter o CSV local e `REF_TIPO_LEITO.qvd` exclusivamente como legenda de `201909`, sem associar descrições automaticamente aos 36 meses. `T29_HISTORICAL=NOT_APPROVED`.
2. **Checkpoint III-C5.1 — PASS local:** o piloto QlikView 12 comprovou correspondência candidata 1:1 em todos os 223 municípios da PB, sem unmatched de municípios PB nas fontes. A literatura técnica IBGE descreve a retirada do dígito verificador para padronizar códigos de sete dígitos com bases do Ministério da Saúde; o piloto específico deste projeto testou a compatibilidade SIH/CNES. **DECISÃO APROVADA em 08/10/2026:** materializar ponte **derivada do projeto** para os 223 municípios PB, composta por IBGE7 oficial dos XLS + prefixo6 validado contra DATASUS/CNES, com 1:1 e zero unmatched PB. Não chamar de tabela externa oficial publicada. Exigir fonte, SHA-256, contagem, unicidade e exceções. Preservar 5.202 RD de residentes externos sem relação artificial com população PB. **III-C5.2 PASS LOCAL (08/10/2026):** a referência foi materializada em QVD e CSV no ambiente QlikView 12, com 223 pares únicos e 0 unmatched PB, seguida por auditoria Python com veredito `PASS_LOCAL_REFERENCE_AUDIT`. SHA-256 QVD derivado `93143c1124eac4dbab0822db610f9de86448752fb7994c8402b3e001849ae38e` e CSV derivado `fdf016e4eaf7a7b8b396d3908da2ec6737944bc9aaf3e6018badb763725c257d`; hashes individuais dos 3 XLS constam no manifesto **local**, não transcritos. Referência derivada pelo projeto, não tabela externa publicada pelo IBGE/MS. **Fase III obteve PASS final posteriormente em 08/10/2026 21:46:48.** Discovery: [phase-3-municipal-crosswalk-preflight-2026-10-08.md](../discovery/phase-3-municipal-crosswalk-preflight-2026-10-08.md).
3. **Fase III — PASS da extração/staging em 08/10/2026 21:46:48:** o runner de `EXTRACAO/EXT.qvw` retornou `RUNNER_EXIT=0`, `VERDICT=PASS_LOCAL_QV_AND_SHA_RECONCILIATION` e marcador novo `PASS_FINAL_RECONCILED`. Os dez QVDs estão reconciliados, 107/107 campos T08 presentes, T07 36/36 competências RD/LT/ST e referências C1–C5 validadas. A falha anterior de três `Unknown statement` em `TRACE` foi corrigida, e o log `EXT.qvw.2026_10_08_21_46_26.log` concluiu sem `Unknown statement`/`Syntax Error` identificados na busca. Manifesto SHA-256 ficou local e não versionado. Evidência: [phase-3-final-extraction-gate-2026-10-08.md](../discovery/phase-3-final-extraction-gate-2026-10-08.md). **T29 validade normativa histórica permanece NOT_APPROVED**, sem JOIN retroativo de legenda CNES. PR #73 integrado à `main` pelo squash `5644bdafa5fe4e437ce3417b5368113639468267`.\n
4. **PR #73, PR #74 e PR #75 integrados na `main`; DIM_TEMPO e DIM_MUNICIPIO aprovadas localmente e integradas.** Próximo gate: investigar nomes históricos e variações de esquema de `SRC_CNES_ST` em modo read-only, na branch `feat/phase-4-dim-estabelecimento`, sem implementar fatos ou dimensões antes da validação. QVD com 937 registros/8 campos, 0 unmatched e SHA auditado; veja `docs/discovery/phase-4-dim-municipio-implementation-2026-10-08.md`. Seis dimensões restantes, depois Fase V fatos e Fase VI Link Table. Preservar 3 fatos, 8 dimensões, granularidades e os Capítulos 1–2 aprovados.

**Histórico completo anterior à consolidação:** [current-state-chronology-2026-10-08.md](current-state-chronology-2026-10-08.md). Este resumo substitui a cronologia como rota operacional; os documentos originais e o histórico Git seguem consultáveis.
