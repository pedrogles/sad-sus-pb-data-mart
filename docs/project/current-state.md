# Current State — SAD Data Mart SUS PB

**Snapshot operacional:** 20/10/2026. **Baseline integrada consultada para SAD-STABILIZATION-01:** `22845ece37ccefe16d53febf101034395290425d` (PR #126 integrado). O SHA abaixo descreve o fechamento histórico da Fase VII. **`main` conferida após integração do PR #106:** `875a7b72ff1ba87dfc49b55472b8e1e058837cbb`. O código efetivamente executado no Windows/QlikView 12 para o gate VII foi `973a2ad2ac245841ff9e56c591ab269754cdc450` (mesmos QVS/runner; commits subsequentes somente documentais). **Fase VII encerrada como `GATE_PASS_CANDIDATE_ONLY`**: inventário/reload locais reportados e inspeção visual de captura do Table Viewer; o log nativo integral e binário de teste não foram auditados independentemente. [Evidências Fase VII](../discovery/phase-7-technical-panel-controlled-gate-2026-10-18.md). O histórico CREATE/READBACK de `LINK_ANALISE.qvd` permanece em [Fase VI](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md).

## Estabilização operacional e evidências VIII — 20/10/2026

**Git — B1 concluído:** 10/10 branches remotas do lote de PRs integrados (#88, #91, #92, #96, #101, #102, #103, #106, #107 e #126) excluídas e ausência das refs conferida no GitHub; 57 branches remotas imediatamente após B1/H1. Bundle com restauração 10/10 e `git fsck` PASS **reportado pelo operador local**, não inspecionado nesta sessão. Nenhuma limpeza adicional autorizada.

**Git — H1 concluído:** 11 PRs históricos (#90, #108, #109, #115, #117–#120, #122, #123 e #127) fechados **sem merge**; as 11 branches correspondentes permaneceram no GitHub. Restaram 9 PRs Draft antes desta consolidação: #110–#114, #116, #121, #124 e #125. O [PR #83](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/83) segue fechado sem merge e sua branch histórica foi preservada. Contagens são fotografia datada, não invariantes.

**Artefatos QlikView:** preservação local de 22 QVDs (10 de extração, 12 de transformação) e 3 QVWs canônicos com cópias/hashes 25/25 **reportados pelo executor local**. A cópia dos binários permanece `LOCAL_COPY_ONLY` (mesmo disco); **não** é `DISASTER_RECOVERY_VERIFIED`. [Política de recuperação](artifact-recovery-policy.md). Não houve nova recarga, STORE, salvamento canônico ou verificação física neste trabalho documental.

**Integração documental seletiva (proveniência histórica preservada):**

- [C1 — escopo/cobertura CNES/LT](../discovery/phase-8-c1-cnes-coverage-readonly-2026-10-18.md), originalmente no PR #116: 24 pares município×competência com presença de LT *reportada/inferida*, não cobertura hospitalar historicamente comprovada. `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `C1_HOSPITAL_SCOPE=NO_GO_NOT_VERIFIED`.
- [C2-D — prevenção D2 na UI](../discovery/phase-8-c2d-d2-ui-predispatch-feasibility-2026-10-19.md), originalmente no PR #121: `OnSelect`/`OnAnySelect` atuam após seleção e não provam bloqueio anterior; botões condicionais são candidatos restritos, não garantia global. `P5_D2_UI=NOT_TESTED`.
- [C2-D3 — UIAutomation/Win32](../discovery/phase-8-c2d3-rawview-win32-discovery-2026-10-19.md), originalmente no PR #124: sondagem Windows **reportada** resultou em `NO_GO_STABLE_BU01_BU02_IDENTIFIERS_NOT_FOUND_IN_THIS_PROBE`; somente identificação por nome/ID nessas duas rotas foi rejeitada. **Não** autoriza `Pilot`/`Complete`, cliques estimados ou afirmação de impossibilidade absoluta de automação.

A integração destes **três documentos históricos** não integra os PRs de origem nem seus scripts de teste, não reproduz execução Windows e não promove aceitação visual, científica ou de produção. Referências internas dos documentos a `main@337943d5` ou ao estado Draft descrevem suas datas originais.

**Fronteiras ainda fechadas:** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `T29_HISTORICAL=NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `PRODUCTION_APPROVED=False`. Fase IX não autorizada.

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
| CNES/LT complementar | Preflight PASS local reportado, PR #90 **fechado sem merge** no lote H1; evidência histórica preservada em branch. Classificação hospitalar histórica segue não verificada. | [PR #90](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90) |
| Fase VI — Link Table | **`PASS_LOCAL_CREATE_READBACK_AND_ATOMIC_PUBLISH_CANDIDATE_ONLY`** na tentativa R2 do QlikView 12, conforme stdout local reportado; revisão de publicação via #101/#102 e correção QVS R1 via [PR #103](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/103), todos integrados. Verificações físicas T17–T19 realizadas pelo runner em READBACK candidato, sem aceite independente do modelo final. **`LINK_KEY_CONTRACT=NOT_APPROVED`**, `PANEL_NOT_TESTED=True`, `PRODUCTION_APPROVED=False`. | [Evidência física R1/R2](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md) |
| Fase VII — Painel técnico | **PR #106 MERGED**; 16 tabelas/15 associações no Table Viewer, sem `$Syn` ou loops visíveis. T17–T19/T22–T23 PASS locais reportados; T20/T21 PASS visual restrito. **`GATE_PASS_CANDIDATE_ONLY`**, sem homologação de indicadores ou produção. | [PR #106](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/106); [evidência VII](../discovery/phase-7-technical-panel-controlled-gate-2026-10-18.md) |
| Fases VIII–IX | **VIII:** testes candidatos T24–T26 ainda em PRs Draft #110–#114; documentos C1/C2-D/C2-D3 consolidados nesta árvore; C3-B1 (#125) permanece Draft/sem autorização de gate físico; sem homologação geral. **IX:** dashboards não iniciados/não autorizados. | [Documentos C1/C2](../discovery/phase-8-c1-cnes-coverage-readonly-2026-10-18.md); [V2 semântico](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) |

**Qualificação:** PASS de execução física significa **resultado local Windows/QlikView 12 reportado pelo responsável**. A captura do Table Viewer do QVW temporário foi inspecionada e indica o grafo esperado, mas QVDs, QVWs e logs nativos completos não foram auditados independentemente. O modelo técnico candidato **não** é o `PAINEL.qvw` definitivo, não homologa expressões V2, `%LINK_KEY` definitivo ou produção: `PRODUCTION_APPROVED=False`.

## Bloqueios e invariantes

- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`: não antecipar integração física, denominadores ou dashboards. VI-P5 aprovou apenas o *modo de projeção POP em memória*, sem aceite do contrato físico final.
- População anual e leitos mensais são **semi-aditivos no tempo**; não multiplicar população por competências nem somar snapshots de anos diferentes como população total. `internações/leito` não equivale automaticamente a taxa de ocupação.
- `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`: evitar legenda CNES retroativa e exclusão de LT válido por escopo não comprovado.
- SIH/RD: `IDENT=1` (555.089) e `IDENT=5` (11.583) não significam o mesmo; `IDENT=5` não é internação nova. Há 5.202 residentes fora da PB sem denominador municipal PB apropriado. Ponte IBGE7↔DATASUS6 comprovada somente no escopo da PB.
- **Preservar os 22 QVDs (21 originais + `LINK_ANALISE.qvd`), QVWs e logs locais VI-R1/R2 e VII.** Não reexecutar CREATE, Fase VII ou sobrescrever dados; não alterar modelagem entregue sem autorização.

## Próximo passo operacional — contrato de indicadores (Fase VIII)

**Handoff da estabilização:** B1 e H1 encerrados. Esta consolidação de documentos não resolve os contratos semânticos nem exige novo ciclo de higiene, QlikView ou testes de UIA/Win32. Preservar os PRs Draft físicos #110–#114 e #125 até decisão específica; nenhum merge ou fechamento implícito.

**Objetivo mínimo seguinte, após revisão e integração documental autorizada:** decidir formalmente o universo apresentável dos indicadores CNES/LT (observado versus hospitalar histórico), mantendo ressalvas de temporalidade e cobertura; avaliar, com oráculos já disponíveis, os casos realmente faltantes de chaves, filtros e denominadores. Não repetir as provas físicas aprovadas apenas de modo restrito, nem liberar Fase IX sem aceite científico e visual próprio. O [Boundary 7](../discovery/boundary-7-implementation-plan.md) segue vinculante.

**Pendências:** `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `T29_HISTORICAL=NOT_APPROVED`; `PRODUCTION_APPROVED=False`. Fase IX não autorizada.

**Fontes de verdade:** usar o HEAD real da `main` e scripts integrados; relatórios passados com `PR_MERGED=False` descrevem a situação no momento da tentativa, não o estado vigente.
