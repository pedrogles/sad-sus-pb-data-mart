# Fase VIII — C3 | Revisão READ-ONLY de lacunas associativas (20/10/2026)

**Estado:** `C3_REMAINING_GAP_REVIEW=COMPLETED_WITH_ONE_JUSTIFIED_GAP`; `C3_B2_PROPOSAL=NOT_AUTHORIZED_PHYSICAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PRODUCTION_APPROVED=False`.

**Objetivo delimitado:** após a integração documental restrita do C2 ([PR #135](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/135)) e a integração das provas C3-B1 ([PR #125](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/125)), revisar somente as evidências já existentes para verificar se há um **único** teste associativo físico ainda justificável antes do contrato de medidas C4. Nenhum PowerShell, COM, QlikView, QVD/QVW, nova execução ou código de teste foi utilizado/criado nesta revisão. O ato de integração Git não reproduz provas físicas.

**Base Git revisada:** `main@93314786df2d668a1b23f1fc08695c72681f247a` após os merges #135 (`d6e3cf12`) e #125 (`93314786`). A prova C3-B1 executada no Windows pertence ao **commit anterior** `91679378c507e2208e284e973bf8249036c0bb72`, não ao squash merge nem a este documento.

## 1. Fontes consultadas

- [AGENTS.md](../../AGENTS.md), [estado operacional](../project/current-state.md), [requisitos](../academic/requirements.md), [Boundary 6](boundary-6-qlikview-physical-architecture.md), [Boundary 7](boundary-7-implementation-plan.md), [VI-P5 / SAD-LINK-V1](phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md), [semântica V2 §62](phase-6-semantic-v2-approved-2026-10-14.md).
- [VI-R2](phase-6-link-analise-physical-r2-2026-10-18.md), [Fase VII / T17–T23](phase-7-technical-panel-controlled-gate-2026-10-18.md), [C2 encerramento](phase-8-c2-evidence-closeout-readonly-2026-10-20.md), [C3-B1 encerramento](phase-8-c3b1-physical-closeout-2026-10-20.md).
- Documentos históricos dos PRs Draft [#110](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/110), [#111](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/111), [#112](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/112), [#113](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/113) e [#114](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/114), lidos nas branches correspondentes. Evidências locais neles descritas **não** foram reproduzidas nesta revisão.

## 2. Matriz de cobertura estritamente física/associativa

| Tema | Evidência já disponível | Lacuna ou limite | Encaminhamento |
| --- | --- | --- | --- |
| Unicidade/serialização e cobertura da `%LINK_KEY` em três fatos | VI-R2, T17–T19: `LINK_ANALISE` com 85.705 chaves únicas, sem órfãos reportados; coordenadas não aplicáveis nulas, POP projetada em memória | PASS local de runner/READBACK **candidato**, sem homologação do contrato global | Reutilizar provas, **não** recriar a Link |
| Grafo físico e papéis/conformadas | Fase VII: 16 tabelas, zero `$Syn` reportadas e Table Viewer inspecionado, T20–T23 PASS local/visual restrito | QVW temporário e captura, não painel final nem prova independente do binário | Reutilizar; **não** reexecutar Fase VII |
| Residência sem serviço combinado | T24 anual #110 (5 casos), mensal #111 (3 casos), regional/indisponibilidade #112; testes candidatos locais com F1/F3 | Não prova seleção **conjunta** `R=S` | Cobertura parcial |
| Serviço sem residência combinada | T25 #113, T26 #114: JP/CG 2018 e janelas parciais, F1/F2/F3, leitos observados RN21 | Não prova seleção conjunta de dois papéis; escopo hospitalar histórico não certificado | Cobertura parcial; T25/T26 seguem candidatos observacionais |
| Seleção conjunta com papéis distintos `R!=S` | C3-B1: 2018, R=250180, S=250750; 4.027 RD, 3.806 elegíveis, 221 IDENT5; zero linhas POP/LT alcançáveis, com inventários SHA preservados | **Um** par, ano 2018, execução Windows reportada e evidências CSV auditadas; não generaliza todos os pares | `C3B1_CLOSEOUT=COMPLETED_WITH_LIMITS`; **não repetir** |
| Seleção conjunta `R=S` e projeção POP anual positiva | Contrato VI-P5 prevê POP com mesma SK nos dois papéis e LT com R fisicamente `NULL`; T24 confirma POP positiva **sem** os dois papéis selecionados | **Não localizada prova física isolada** verificando simultaneamente `PERIODO_ANO`, `RES_COD_DATASUS_6` e `SERV_COD_DATASUS_6` com `R=S`, presença POP esperada e LT não alcançável | **Um caso C3-B2 candidato, apenas proposto** |
| Filtros V2 `C/R/I/B` simultâneos e prevenção D2 antes da seleção | C2 e wrappers candidatos documentados | C2 global permanece NO-GO; não confundir com a prova associativa C3 | Gate C2/P5 separado, não cobrir via C3-B2 |
| Medidas/denominadores e capacidade histórica hospitalar | V2 semântica aprovada, T24–T26 locais restritos | Aceites físicos globais e cobertura histórica pendentes | C4 e escopo CNES separados, só após decisão C3 |

**FATO VERIFICADO DOCUMENTAL:** nenhum dos relatórios revisados descreve uma prova física isolada de **associação positiva da linha POP sob dois papéis municipais iguais selecionados ao mesmo tempo**. Não é afirmação de defeito da Link Table.

## 3. Decisão da triagem

**`C3_ADDITIONAL_PHYSICAL_TEST=JUSTIFIED_ONE_CASE_PROPOSED`**. Um C3-B2 **poderia** fechar uma lacuna distinta de C3-B1:

1. Usar **somente após autorização específica** um QVW TEMP preexistente SHA-verificado, aberto em cópia descartável, sem reload/save/STORE; script executor novo deve ser **versionado antes** de qualquer execução local conforme AGENTS.md.
2. Selecionar um único ano de referência e `RES_COD_DATASUS_6=SERV_COD_DATASUS_6` para **um município PB comprovado** simultaneamente no F1 de fluxos internos e no oráculo de POP anual F3, com valores de referência obtidos de arquivos reais e manifestos SHA. **Não inventar par, resultado ou contagem.** Fixar só depois de inspeção dos dados e da compatibilidade das seleções.
3. Reconciliar contagens RD/elegíveis com o F1, comprovar **associação POP anual positiva e não multiplicada** contra F3/linhas de fato sob o contexto conjunto, e verificar ausência de LT alcançável sob filtro de residência quando tal comportamento for o esperado pelo contrato de nulos. A interpretação é **de alcançabilidade associativa**, não um indicador RES/LEI/REL com filtros P5 `B`.
4. Guardas de `PERIODO_ANO` e ausência de `PERIODO_COMPETENCIA`, preservação SHA dos 22 QVDs, QVWs canônicos e origem TEMP; logs/CSVs persistentes auditáveis. Falha/incompatibilidade é `BLOCKED/INCONCLUSIVE`, **sem retry automático**.
5. **STOP** após esse único cenário. C3-B2 eventualmente positivo não aprova sozinho `LINK_KEY_CONTRACT` integral, P5 ou C4; exigir decisão de aceite separada.

**Status desta execução:** `C3_REMAINING_GAP_REVIEW=COMPLETED_WITH_ONE_JUSTIFIED_GAP`, `C3_B2_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`. Não implementar C3-B2 nesta branch e não começar C4. A arquitetura acadêmica aprovada permanece intocada.

## 4. Fronteiras

`C2_FULL=NO_GO_NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**GO somente para proposta/documentação do próximo gate; NO-GO para nova execução física sem autorização.** Nenhum merge de #110–#114, execução QlikView ou alteração de binários foi realizado nesta revisão.
