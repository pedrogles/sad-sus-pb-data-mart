# Current State — SAD Data Mart SUS PB

**Snapshot operacional:** 18/10/2026. **`main` conferida após integração do PR #106:** `875a7b72ff1ba87dfc49b55472b8e1e058837cbb`. O código efetivamente executado no Windows/QlikView 12 para o gate VII foi `973a2ad2ac245841ff9e56c591ab269754cdc450` (mesmos QVS/runner; commits subsequentes somente documentais). **Fase VII encerrada como `GATE_PASS_CANDIDATE_ONLY`**: inventário/reload locais reportados e inspeção visual de captura do Table Viewer; o log nativo integral e binário de teste não foram auditados independentemente. [Evidências Fase VII](../discovery/phase-7-technical-panel-controlled-gate-2026-10-18.md). O histórico CREATE/READBACK de `LINK_ANALISE.qvd` permanece em [Fase VI](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md).

## Inventário documental main × Draft (revisão G0 — 20/10/2026)

| Fonte | Situação | Limite |
| --- | --- | --- |
| `main@337943d5c5b77067f842902fc679dbb68db87020` | Integrações até PR #106; Fase VII candidata, Fase VIII ainda sem contrato físico geral aprovado | Este é o estado integrado; preservar snapshot e evidências acima |
| [PR #90](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90) e [PRs #108–#114](https://github.com/pedrogles/sad-sus-pb-data-mart/pulls) | Drafts de CNES/LT, Discovery/readiness e pilotos T24–T26 | Provas locais restritas e documentação em branches, sem promoção à `main` |
| [PRs #115–#124](https://github.com/pedrogles/sad-sus-pb-data-mart/pulls) e [PR #125](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/125) | Drafts de fechamento C1, testes C2/D2, UIA/Win32 e C3-B1 | O NO-GO de identificação UIA/Win32 não autoriza cliques; C3-B1 não tinha PASS físico ao fim da auditoria |
| Governança G0 | Política de agentes proposta em branch de revisão, **não integrada na `main`** | Não altera gates, contratos, QVS, QVD/QVW nem autoriza G1 |

**Atualização apenas documental:** a situação dos Drafts deve ser reconsultada por número/HEAD antes do próximo gate. Não somar os resultados experimentais à homologação da `main`. Permanecem `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `P5_D2_UI=NOT_TESTED_FULLY`, `PRODUCTION_APPROVED=False` e Fase IX não autorizada.

## Contrato acadêmico preservado

Data Mart SUS Paraíba, 2017–2019, com SIH/SUS RD, CNES/LT e IBGE/SIDRA; **QlikView 12 obrigatório**. Fluxo: `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`. **Star Schema por processo factual**, constelação com três fatos e oito dimensões aprovadas. Capítulos 1 e 2 entregues conforme relato de 13/10/2026; avaliação do professor pendente. Ver [requisitos](../academic/requirements.md), [modelagem](../academic/chapter-1-2-modeling.md) e [Boundary 7](../discovery/boundary-7-implementation-plan.md).

## Estado dos gates

| Etapa | Estado | Evidência |
| --- | --- | --- |
| Extração | 108/108 DBC convertidos, 10 QVDs de extração/referência, **PASS local reportado** | [Extração](../discovery/phase-3-final-extraction-gate-2026-10-08.md) |
| Oito dimensões | 8 scripts na `main`, com testes locais reportados | [Dimensões](../discovery/phase-4-dim-tipo-leito-discovery-2026-10-09.md) |
| `FATO_INTERNACAO` | QVD físico, CREATE + READBACK **PASS local reportado**: 566.672 linhas, 17 campos, 36 competências; código MERGED #88 | [Evidência](../discovery/phase-5-fato-internacao-implementation-2026-10-15.md) |
| `FATO_CAPACIDADE_LEITO` | QVD físico, CREATE + READBACK **PASS local reportado**: 35.518 linhas, 11 campos, 36 competências; código MERGED #91/#92 | [Evidência](../discovery/phase-5-fato-capacidade-leito-qvd-materialization-2026-10-15.md) |
| `FATO_POPULACAO` | **QVD físico criado e reaberto**, CREATE + READBACK **PASS local reportado**: 669 linhas, 7 campos, 223 municípios × 3 anos, 669 pares SK distintos, zero erros. Código **MERGED #96**; preflight e RAM nos #93/#94 | [Evidência física](../discovery/phase-5-fato-populacao-qvd-materialization-2026-10-16.md) |
| Inventário | **22 QVDs reportados localmente preservados**, sendo 21 originais + `LINK_ANALISE.qvd` adicional. Gate VII reportou hashes e headers inalterados antes/depois, com QVWs canônicos preservados. | [Fase VII](../discovery/phase-7-technical-panel-controlled-gate-2026-10-18.md); binários não versionados |
| CNES/LT complementar | Preflight PASS local reportado, PR #90 ainda Draft e não integrado | [PR #90](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90) |
| Fase VI — Link Table | **`PASS_LOCAL_CREATE_READBACK_AND_ATOMIC_PUBLISH_CANDIDATE_ONLY`** na tentativa R2 do QlikView 12, conforme stdout local reportado; revisão de publicação via #101/#102 e correção QVS R1 via [PR #103](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/103), todos integrados. Verificações físicas T17–T19 realizadas pelo runner em READBACK candidato, sem aceite independente do modelo final. **`LINK_KEY_CONTRACT=NOT_APPROVED`**, `PANEL_NOT_TESTED=True`, `PRODUCTION_APPROVED=False`. | [Evidência física R1/R2](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md) |
| Fase VII — Painel técnico | **PR #106 MERGED**; 16 tabelas/15 associações no Table Viewer, sem `$Syn` ou loops visíveis. T17–T19/T22–T23 PASS locais reportados; T20/T21 PASS visual restrito. **`GATE_PASS_CANDIDATE_ONLY`**, sem homologação de indicadores ou produção. | [PR #106](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/106); [evidência VII](../discovery/phase-7-technical-panel-controlled-gate-2026-10-18.md) |
| Fases VIII–IX | **VIII — próximo gate:** Discovery READ-ONLY de T24–T26, seguida de teste controlado QVW descartável somente sob gates; ainda sem expressões reconciliadas. **IX — dashboards:** não iniciada. | [Bootstrap Fase VIII](../discovery/bootstrap-phase-8-indicators-2026-10-18.md); [V2 semântico](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) |

**Qualificação:** PASS de execução física significa **resultado local Windows/QlikView 12 reportado pelo responsável**. A captura do Table Viewer do QVW temporário foi inspecionada e indica o grafo esperado, mas QVDs, QVWs e logs nativos completos não foram auditados independentemente. O modelo técnico candidato **não** é o `PAINEL.qvw` definitivo, não homologa expressões V2, `%LINK_KEY` definitivo ou produção: `PRODUCTION_APPROVED=False`.

## Bloqueios e invariantes

- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`: não antecipar integração física, denominadores ou dashboards. VI-P5 aprovou apenas o *modo de projeção POP em memória*, sem aceite do contrato físico final.
- População anual e leitos mensais são **semi-aditivos no tempo**; não multiplicar população por competências nem somar snapshots de anos diferentes como população total. `internações/leito` não equivale automaticamente a taxa de ocupação.
- `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`: evitar legenda CNES retroativa e exclusão de LT válido por escopo não comprovado.
- SIH/RD: `IDENT=1` (555.089) e `IDENT=5` (11.583) não significam o mesmo; `IDENT=5` não é internação nova. Há 5.202 residentes fora da PB sem denominador municipal PB apropriado. Ponte IBGE7↔DATASUS6 comprovada somente no escopo da PB.
- **Preservar os 22 QVDs (21 originais + `LINK_ANALISE.qvd`), QVWs e logs locais VI-R1/R2 e VII.** Não reexecutar CREATE, Fase VII ou sobrescrever dados; não alterar modelagem entregue sem autorização.

## Próximo gate — Fase VIII

**Encerramento confirmado:** Fase VII `GATE_PASS_CANDIDATE_ONLY` e [PR #106 MERGED](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/106). Gate de modelo associativo técnico encerrado; não repetir os preflights. PR #90 CNES/LT permanece Draft e independente.

**Objetivo delimitado:** iniciar **Fase VIII — Discovery READ-ONLY e execução controlada de indicadores**, conforme [bootstrap VIII](../discovery/bootstrap-phase-8-indicators-2026-10-18.md), [Boundary 7](../discovery/boundary-7-implementation-plan.md) e [V2 semântico](../discovery/phase-6-semantic-v2-approved-2026-10-14.md). Reconciliar T24–T26 com oráculos independentes, testar política P5 C/R/I/B, POP anual, cobertura CNES, roles municipais, temporalidade e motivos de indisponibilidade. Toda nova execução deve usar scripts previamente commitados e QVW temporário, com SHA dos 22 QVDs antes/depois e revisão do resultado.

**Pendências NÃO resolvidas pela Fase VII:** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `PRODUCTION_APPROVED=False`. Descoberta e testes não aprovam produção automaticamente. **Fase IX não autorizada** até reconciliação dos indicadores e novo gate.

**Fontes de verdade:** usar o HEAD real da `main` e scripts integrados; relatórios passados com `PR_MERGED=False` descrevem a situação no momento da tentativa, não o estado vigente.
