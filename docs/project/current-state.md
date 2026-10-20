# Current State — SAD Data Mart SUS PB

## Roteamento operacional atualizado — 20/10/2026

**Atualização após [PR #137](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/137) (squash `41c204c1383ae8189c87e95e6dfe2611075d279b`):** `C3B2_CLOSEOUT=COMPLETED_WITH_LIMITS`; `C3B2_PHYSICAL=PASS_LOCAL_C3B2_SAME_ROLE_POP_CANDIDATE_ONLY`; [closeout C3-B2](../discovery/phase-8-c3b2-physical-closeout-2026-10-20.md) e executor integrados à `main`. A execução física Windows/QlikView 12 foi reportada no **commit anterior ao squash** `ceb6c8b74b960e7e30b9dd4ada027e218da92712`; houve auditoria independente de consistência de **12 arquivos exportados**, não dos binários QVD/QVW nem reprodução independente do COM. Município R=S: `250750`, 2018; F1 RD 40.033, elegíveis 39.060, IDENT5 973; F3 POP 800.323, uma linha POP alcançável e nenhuma LT alcançável apenas no contexto associado. **C3-B1 e C3-B2 são PASS restritos**, sem homologação global `LINK_KEY_CONTRACT`.

**Próximo objetivo permitido:** **preparação C4 READ-ONLY** do contrato físico de medidas/denominadores conforme V2 §62 e Boundary 7, reutilizando F1/F2/F3, T24–T26, VI-P2 e as provas C3, sem testes físicos, novos scripts, QVD/QVW ou dashboards neste roteamento. `C4_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. **Preparação de C4 não significa aceite físico C3 global ou execução C4 autorizada.**

**Base Git desta revisão:** `main@93314786df2d668a1b23f1fc08695c72681f247a`, após [PR #135 — C2 READ-ONLY](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/135) (squash `d6e3cf12`) e [PR #125 — C3-B1](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/125) (squash `93314786`), ambos **MERGED**. Integração Git não equivale a homologação física ou de produção.

**C2:** `C2_EXISTING_EVIDENCE_READONLY_REVIEW=COMPLETED_WITH_LIMITS`; `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`. [Closeout](../discovery/phase-8-c2-evidence-closeout-readonly-2026-10-20.md).

**C3-B1:** `C3B1_PHYSICAL=PASS_LOCAL_C3B1_ASYMMETRIC_ROLE_FLOW_CANDIDATE_ONLY` conforme execução Windows/QlikView 12 reportada e pacote CSV/manifesto conferido; **commit realmente executado:** `91679378c507e2208e284e973bf8249036c0bb72`, anterior ao merge. Cobertura: apenas um par R≠S em 2018. [Closeout](../discovery/phase-8-c3b1-physical-closeout-2026-10-20.md).

**C3-B2:** executado e integrado via PR #137; evidência auditada em escopo exportado, `COMPLETED_WITH_LIMITS`. A revisão READ-ONLY de lacunas identificou o teste, que foi realizado **uma única vez**, sem reexecução. Preparar apenas C4 READ-ONLY; **não** liberar execução C4 ou produção por inferência. `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**Seções históricas abaixo** registram os seus respectivos snapshots e datas. Este bloco e a seção "Próximo passo operacional" determinam o roteamento atual; não reinterpretar antigos rótulos Draft/NOT_RUN como estado presente.


**Snapshot operacional:** 20/10/2026. **`main` conferida nesta reconciliação:** `c4219ae080b4c71b1f5b347fe202100b4c47cf4f` ([PR #133](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/133) integrado: escopo de apresentação CNES/LT observado). **Baseline anterior de SAD-STABILIZATION-01:** `22845ece37ccefe16d53febf101034395290425d` (PR #126 integrado). O SHA a seguir descreve o fechamento histórico da Fase VII. **`main` conferida após integração do PR #106:** `875a7b72ff1ba87dfc49b55472b8e1e058837cbb`. O código efetivamente executado no Windows/QlikView 12 para o gate VII foi `973a2ad2ac245841ff9e56c591ab269754cdc450` (mesmos QVS/runner; commits subsequentes somente documentais). **Fase VII encerrada como `GATE_PASS_CANDIDATE_ONLY`**: inventário/reload locais reportados e inspeção visual de captura do Table Viewer; o log nativo integral e binário de teste não foram auditados independentemente. [Evidências Fase VII](../discovery/phase-7-technical-panel-controlled-gate-2026-10-18.md). O histórico CREATE/READBACK de `LINK_ANALISE.qvd` permanece em [Fase VI](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md).

## Estabilização operacional e evidências VIII — 20/10/2026

**Git — B1 concluído:** 10/10 branches remotas do lote de PRs integrados (#88, #91, #92, #96, #101, #102, #103, #106, #107 e #126) excluídas e ausência das refs conferida no GitHub; 57 branches remotas imediatamente após B1/H1. Bundle com restauração 10/10 e `git fsck` PASS **reportado pelo operador local**, não inspecionado nesta sessão. Nenhuma limpeza adicional autorizada.

**Git — H1 concluído:** 11 PRs históricos (#90, #108, #109, #115, #117–#120, #122, #123 e #127) fechados **sem merge**; as 11 branches correspondentes permaneceram no GitHub. Restaram 9 PRs Draft antes desta consolidação: #110–#114, #116, #121, #124 e #125. O [PR #83](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/83) segue fechado sem merge e sua branch histórica foi preservada. Contagens são fotografia datada, não invariantes.

**Artefatos QlikView:** preservação local de 22 QVDs (10 de extração, 12 de transformação) e 3 QVWs canônicos com cópias/hashes 25/25 **reportados pelo executor local**. A cópia dos binários permanece `LOCAL_COPY_ONLY` (mesmo disco); **não** é `DISASTER_RECOVERY_VERIFIED`. [Política de recuperação](artifact-recovery-policy.md). Não houve nova recarga, STORE, salvamento canônico ou verificação física neste trabalho documental.

**Integração documental seletiva (proveniência histórica preservada):**

- [C1 — escopo/cobertura CNES/LT](../discovery/phase-8-c1-cnes-coverage-readonly-2026-10-18.md), originalmente no PR #116: 24 pares município×competência com presença de LT *reportada/inferida*, não cobertura hospitalar historicamente comprovada. `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `C1_HOSPITAL_SCOPE=NO_GO_NOT_VERIFIED`.
- [C2-D — prevenção D2 na UI](../discovery/phase-8-c2d-d2-ui-predispatch-feasibility-2026-10-19.md), originalmente no PR #121: `OnSelect`/`OnAnySelect` atuam após seleção e não provam bloqueio anterior; botões condicionais são candidatos restritos, não garantia global. `P5_D2_UI=NOT_TESTED`.
- [C2-D3 — UIAutomation/Win32](../discovery/phase-8-c2d3-rawview-win32-discovery-2026-10-19.md), originalmente no PR #124: sondagem Windows **reportada** resultou em `NO_GO_STABLE_BU01_BU02_IDENTIFIERS_NOT_FOUND_IN_THIS_PROBE`; somente identificação por nome/ID nessas duas rotas foi rejeitada. **Não** autoriza `Pilot`/`Complete`, cliques estimados ou afirmação de impossibilidade absoluta de automação.
- [Escopo de apresentação CNES/LT observado](../discovery/phase-8-cnes-presentation-scope-decision-2026-10-20.md), **PR #133 integrado à `main`**: T25 e T26 têm nomenclatura documental permitida **apenas no universo experimental reconciliado** `LT_TODOS_REGISTROS_VALIDOS_RN21`; não há aceite de cobertura hospitalar histórica, contrato físico geral, interface visual ou produção.

A integração dos **três documentos históricos C1/C2-D/C2-D3** não integrou os PRs de origem nem scripts de teste e não reproduziu execução Windows. A decisão integrada via **PR #133** formaliza somente a apresentação experimental restrita de T25/T26, sem promover aceitação visual, científica geral ou de produção. Referências históricas a `main@337943d5` ou ao estado Draft descrevem suas datas originais.

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
| Fases VIII–IX | **VIII:** T24 (#110–#112), T25 (#113) e T26 (#114) têm PASS locais candidatos restritos, documentação nos PRs Draft históricos; não são indicadores homologados. C2 segue `C2_FULL=NO_GO_NOT_APPROVED` e `P5_D2_UI=NOT_TESTED`. C3-B1 (#125 MERGED) validou um fluxo R≠S 2018 com PASS restrito; C3-B2 (#137 MERGED) testou 2018 R=S com F1/F3, POP anual positiva não multiplicada e nenhuma LT alcançável, `COMPLETED_WITH_LIMITS` após auditoria do ZIP exportado; nenhum PASS global da `%LINK_KEY`. **C4 só preparado documentalmente**, `C4_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`, medidas/denominadores não aprovados. **IX:** dashboards não iniciados/não autorizados. | [C2](../discovery/phase-8-c2-evidence-closeout-readonly-2026-10-20.md); [C3-B1](../discovery/phase-8-c3b1-physical-closeout-2026-10-20.md); [C3-B2](../discovery/phase-8-c3b2-physical-closeout-2026-10-20.md); [V2](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) |

**Qualificação:** PASS de execução física significa **resultado local Windows/QlikView 12 reportado pelo responsável**. A captura do Table Viewer do QVW temporário foi inspecionada e indica o grafo esperado, mas QVDs, QVWs e logs nativos completos não foram auditados independentemente. O modelo técnico candidato **não** é o `PAINEL.qvw` definitivo, não homologa expressões V2, `%LINK_KEY` definitivo ou produção: `PRODUCTION_APPROVED=False`.

## Bloqueios e invariantes

- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`: não antecipar integração física, denominadores ou dashboards. VI-P5 aprovou apenas o *modo de projeção POP em memória*, sem aceite do contrato físico final.
- População anual e leitos mensais são **semi-aditivos no tempo**; não multiplicar população por competências nem somar snapshots de anos diferentes como população total. `internações/leito` não equivale automaticamente a taxa de ocupação.
- `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`: evitar legenda CNES retroativa e exclusão de LT válido por escopo não comprovado.
- SIH/RD: `IDENT=1` (555.089) e `IDENT=5` (11.583) não significam o mesmo; `IDENT=5` não é internação nova. Há 5.202 residentes fora da PB sem denominador municipal PB apropriado. Ponte IBGE7↔DATASUS6 comprovada somente no escopo da PB.
- **Preservar os 22 QVDs (21 originais + `LINK_ANALISE.qvd`), QVWs e logs locais VI-R1/R2 e VII.** Não reexecutar CREATE, Fase VII ou sobrescrever dados; não alterar modelagem entregue sem autorização.

## Próximo passo operacional — Fase VIII, C3 limitado → C4 preparação (C2 com NO-GO)

**C2 (documentado e integrado):** [PR #135](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/135) encerrou a reconciliação READ-ONLY das evidências com `C2_FULL=NO_GO_NOT_APPROVED`; a UI não foi homologada. Não repetir UIAutomation/Win32 ou cliques D2 para converter prova parcial em PASS global.

**C3-B1 (executado e integrado como teste experimental):** [PR #125](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/125) contém script versionado e closeout do único fluxo assimétrico 2018; `PASS_LOCAL_C3B1_ASYMMETRIC_ROLE_FLOW_CANDIDATE_ONLY` conforme execução local reportada. Não reexecutar COM ou alterar QVD/QVW original. O script mantém guardas da branch histórica; merge não o transforma em executor de produção.

**C3, revisão e teste físico concluídos com limites:** a [matriz de lacunas](../discovery/phase-8-c3-remaining-gap-review-2026-10-20.md) identificou R=S como lacuna no momento da triagem. A execução autorizada de C3-B2 preencheu **esse caso isolado** e o [PR #137](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/137) integrou executor e [closeout](../discovery/phase-8-c3b2-physical-closeout-2026-10-20.md) restritos. `C3B2_CLOSEOUT=COMPLETED_WITH_LIMITS`; `LINK_KEY_CONTRACT=NOT_APPROVED`. **Próximo gate delimitado: C4 READ-ONLY/CONTRACT PREPARATION**, sem expressões oficiais, COM ou aprovação física automática; C4 físico e global exigem autorização/gates próprios.

**Escopo CNES/LT:** decisão observacional do [PR #133](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/133) já integrada; cobertura hospitalar histórica não verificada. PRs Draft #110–#114 preservados como evidências de pilotos, **sem merges adicionais por inferência**. Fase IX continua não autorizada.

**Bloqueios preservados:** `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `T29_HISTORICAL=NOT_APPROVED`; `PRODUCTION_APPROVED=False`; `PHASE_IX=NOT_AUTHORIZED`.

**Fontes de verdade:** usar o HEAD real da `main` e os scripts integrados; resultados em PRs fechados sem merge ou Draft são evidências históricas de branch, não fatos incorporados ao código da `main`. Para provas físicas, exigir commit efetivamente executado, logs e integridade de artefatos.
