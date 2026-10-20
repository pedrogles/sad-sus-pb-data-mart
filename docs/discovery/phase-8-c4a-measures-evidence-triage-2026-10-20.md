# Fase VIII — C4-A | Triagem READ-ONLY das medidas/denominadores já testados (20/10/2026)

**Estado desta triagem:** `C4_A_EVIDENCE_REVIEW=COMPLETED_WITH_ONE_BOUNDED_CANDIDATE`; `C4_B1_REGIONAL_T25=PROPOSED_NOT_AUTHORIZED`; `C4_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`. **PASS exclusivamente documental** para classificação de evidências; nenhum novo PASS físico nem autorização de realizar o caso candidato.

**Fonte Git:** `main@949e6e96b6e0f4e530672d52808ad178080bce28` (C3-B2 [PR #137](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/137) e correção de estado [#138](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/138) integrados). O readiness preparatório está no **[PR #139](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/139), Draft**, não na `main`. Esta triagem é um segundo documento/PR independente para não transformar o readiness em execução física ou expandir seu objetivo.

## 1. Escopo autorizado e método de qualificação

**Objetivo único:** comparar o contrato semântico V2 §62 (T24/RES, T25/LEI, T26/REL, FLU; temporalidade, papéis, filtros P5 e cobertura) com os **resultados efetivamente documentados** nas branches Draft dos PRs [#110](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/110)–[#114](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/114), as evidências [C3-B1](phase-8-c3b1-physical-closeout-2026-10-20.md)/[C3-B2](phase-8-c3b2-physical-closeout-2026-10-20.md), [C2](phase-8-c2-evidence-closeout-readonly-2026-10-20.md), [VI-P5](phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md) e a ordem do [Boundary 7](boundary-7-implementation-plan.md). Consultados primeiro: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`.

**Origem das provas:** os relatórios `docs/discovery/phase-8-b-t24-annual-pilot-2026-10-18.md` (#110), `phase-8-b-t24-monthly-predispatch-2026-10-18.md` (#111), `phase-8-b-t24-edge-cases-2026-10-18.md` (#112), `phase-8-b-t25-observed-lt-2018-2026-10-18.md` (#113), `phase-8-b-t26-observed-lt-2018-2026-10-18.md` (#114) lidos **nas respectivas branches, seção final de execução**, não nas declarações iniciais históricas `NOT_RUN`. Seus scripts e stdout foram reportados em Windows/QlikView 12, mas **os CSVs originais desses cinco pilotos, os respectivos QVWs binários e os logs nativos não foram reabertos/auditados independentemente nesta triagem**. A prova C3-B2 tem ZIP de 12 arquivos auditado em relação aos CSVs exportados; esse nível de prova **não é transferível** a T24–T26.

**Restrições:** sem Git merge, QlikView/COM/GUI, PowerShell, download/geração de datasets, alterações de QVD/QVW/QVS, reexecução dos pilotos, mudança de V2, escopo hospitalar ou Fase IX. Somente leitura de documentos/geradores e produção deste Markdown.

## 2. Matriz C4-A — o que existe e o que não existe

| Família/recorte | Resultado documentado | Nível e limitações | Classificação C4 |
| --- | --- | --- | --- |
| **T24 RES anual** PB 2017–2019, JP/CG 2018 | #110: 5/5 componentes elegíveis/POP/taxa com `PASS_LOCAL_T24_ANNUAL_5_CASES_CANDIDATE_ONLY`; commit Windows `c35302aec6a4a5e91d1837dc9aac0e0cd626c2d7` | Execução local reportada, sem auditoria independente de CSV/QVW; razão de residência/POP anual no universo RD processado PB | **Coberto restrito**; não repetir |
| **T24 RES parcial** JP 201801, JP 201801+201803 (descontíguos), PB 201801 | #111: 3/3 e POP anual recuperada com Set Analysis candidato; `PASS_LOCAL_T24_PARTIAL_3_AND_WRAPPER_GUARDS_4_CANDIDATE_ONLY`; commit executado `23f27473dea28f5cda17aea5221c4b736640d741` | Wrapper evita dois conflitos D2 e dois filtros P5, mas **não** comprova proteção na UI; CSVs não auditados nesta triagem | **Coberto restrito**; D2/P5 global bloqueados |
| **T24 RES regional / indisponibilidade** | #112: JP+CG 2018 `N=61.616`, `POP=1.207.795`, razão candidata; guardas de KPI sem ano, multi-ano e externo; commit `4a9ff588355b6de654ea9f426f0d588d670120b4` | Regional testado no papel **RES**; externo demonstrado no oráculo sem seleção COM; guardas temporais são do wrapper, não do painel | **Coberto restrito**, não generaliza a `SERV` nem UI |
| **T25 LEI anual** JP/CG, 2018, papel `SERV` | #113: dois anos-municípios e 24 componentes mensais (12 por município) reconciliados; 1 parcial JP 201801. F2 sum-snapshots: JP `28.106`, CG `16.592`; F3 POP: `800.323`, `407.472`; commit `2c8c182d009d94de69784502e6e40668ed75054a` | Apenas `LT_TODOS_REGISTROS_VALIDOS_RN21` observado e 12/12 **meses com linhas**, não cobertura hospitalar comprovada, zero real, nem seleção **conjunta** de municípios `SERV` | **Coberto individualmente**; **lacuna regional conjunta** |
| **T26 REL anual/parcial** JP/CG 2018, serviço | #114: dois casos anuais + JP 201801 parcial; F1 elegíveis JP `73.105`, CG `46.752`; F2 mesmos `28.106`/`16.592`; commit físico `59ab936bf9dfaf0fde7b857540074bbf258a5b16` | Também apenas LT observado; **não** taxa de ocupação; os resultados foram reportados, sem auditoria independente dos CSVs desta execução | **Coberto individualmente**, regional de serviço não validado |
| **FLU / associações** R≠S e R=S | C3-B1: R=250180/S=250750, 2018; C3-B2: R=S=250750, 2018 com `40.033` RD, `39.060` elegíveis, `973` IDENT5 e POP `800.323` em 1 linha, LT 0 alcançáveis | Duas seleções físicas associativas candidatas; não representam indicador RES com `SERV` (filtro **B**), nem aprovação global da chave | **Coberto para dois casos**; contrato geral não aprovado |
| **Temporal/P5/D2/cobertura** | V2 §62.3–62.7; C2 encerrou `NO_GO`, com provas de wrapper/objetos limitadas; CNES histórico ainda não comprovado | Série de múltiplos anos, todas as rotas D2, matriz C/R/I/B sob filtros simultâneos, cobertura por município/competência/escopo e tratamento integral de indisponibilidade **não estão homologados** | **Bloqueios externos/globais**; não remediar com novo teste numérico isolado |

**Leitura dos pilotos:** o cabeçalho `VERSIONED_NOT_RUN` de #110 e declarações preliminares similares em #111–#114 são snapshots escritos antes dos fechamentos no **mesmo documento**. A seção final de cada documento registra os PASS locais candidatos posteriores. Não reescrever estes históricos nem afirmar que foram integrados na `main`; a `main` contém apenas o relato canônico e os closeouts C3.

## 3. Oráculos e contexto técnico para possível recorte realmente novo

O gerador **histórico** `tools/preflight_f3_denominadores_ibge.py` do commit `26369052bd3f96de5f3eccf873c390053c20b561` foi inspecionado em modo leitura. **Fato verificado no código:** `F3_cenarios_multimunicipais.csv` tem explicitamente um cenário por `ano × papel (RES/SERV) × selecao (PB_223/JP_CG_2)`, incluindo `2018 / SERV / JP_CG_2` com os municípios `250400,250750`; soma POP uma única vez por município e, **somente se houver 12 competências LT para cada município**, calcula `capacidade_media_sus_numerador_candidato` como soma de 24 snapshots, `divisor_candidato=12`, `capacidade_estado=CANDIDATO_RN21_SEM_ESCOPO_HOSPITALAR`. O CSV original não foi inspecionado aqui, apenas o contrato do gerador.

**Valores derivados matematicamente da documentação de #113** — **hipóteses de comparação sujeitas a readback de F2/F3, não oráculo físico reconferido**:

| Componente para `2018 / SERV / {250400,250750}` | Cálculo a partir de #113 | Referência derivada |
| --- | --- | ---: |
| F2: soma auditável de 12 snapshots JP + CG | `28.106 + 16.592` | `44.698` |
| Média de leitos observados no ano | `44.698 / 12` | `3.724,833333…` |
| F3: POP anual única por serviço | `800.323 + 407.472` | `1.207.795` |
| Razão T25 regional candidata por 1.000 | `1000 × (44.698/12) / 1.207.795` | `≈ 3,08399466245` |

O agregador deve **somar os valores municipais de cada competência primeiro**, validar 12 meses e somente então tirar a média, em vez de tirar média simples de duas razões municipais. Dois municípios selecionados por `SERV` exigem confirmar que a POP anual não foi multiplicada ou perdida; o sucesso RES regional de #112 não prova essa seleção no outro papel.

## 4. Decisão C4-A — UMA lacuna física mínima, ainda sem autorização

**`C4_A_DECISION=ONE_NEW_REGIONAL_SERVICE_T25_CASE_JUSTIFIED`**. Os pilotos já reconcilam T24 residência anual, mensal e regional; T25/T26 em um município de serviço por vez. A lacuna de maior valor incremental isolável de P5/UI é o **T25 anual regional no papel de serviço com dois municípios simultâneos**, usando **exatamente** o universo observacional RN21 e as mesmas fontes congeladas, sem introduzir novo campo, modelo, competência ou escopo hospitalar.

**C4-B1 somente PROPOSTO (não implementado, não autorizado):**
1. **Contexto único:** QVW T24 TEMP já existente (SHA conhecido, pré-verificar), `PERIODO_ANO=2018`, `SERV_COD_DATASUS_6={250400,250750}`, `PERIODO_COMPETENCIA` sem seleção; `RES_COD_DATASUS_6` sem seleção; demais filtros potencialmente incompatíveis ausentes. Não aplicar filtro RES para T25 (V2 classifica como `B`).
2. **Antes de qualquer COM:** readback READ-ONLY de `manifest_F1_F2.json`, `F2_lt_municipio_competencia_observado.csv`, `manifest_F3.json`, `F3_pop_municipio_ano.csv` e `F3_cenarios_multimunicipais.csv` com hashes efetivamente conferidos. Recalcular os **12 totais regionais** (2 cidades por mês), verificar `12/12` meses em cada cidade, `universo=LT_TODOS_REGISTROS_VALIDOS_RN21`, `hospitalar_historico_validado=NAO`, POP de duas linhas únicas com mesmo ano/território e confronto com o cenário `F3 SERV JP_CG_2`. Incompatibilidade ou falta de arquivo: **BLOCKED**, não gerar substitutos.
3. **Hipótese física delimitada:** COM/Evaluate sobre cópia descartável verificaria `Sum(QTD_LEITOS_SUS)=44.698` como **soma de snapshots para auditoria**, `Count(POPULACAO_ESTIMADA)=2`, `Sum(POPULACAO_ESTIMADA)=1.207.795`, e razão T25 candidata `1000 × (44.698/12) / 1.207.795` com tolerância absoluta `≤ 1e-6` por mil, além dos 12 totais regionais F2. **Os valores são derivados dos pilotos**, ainda não aferidos fisicamente para o contexto conjunto.
4. **Guardas:** código PowerShell/QVS de qualquer gate físico deve estar **commitado em branch antes da execução** e identificar commit/SHA; 22 QVDs/3 QVWs canônicos e QVW TEMP de origem com snapshots SHA antes/depois; não usar `Reload`, `Save` ou `STORE` canônico. Evidências locais em TEMP, stdout/CSV/manifesto, auditoria externa posteriormente. Exigir autorização independente para `-RunQlik`, sem retentativas automáticas.
5. **PASS restrito futuro:** reconciliação completa de um cenário `2018 SERV JP+CG T25 RN21 OBSERVED ONLY`, com preservação de hashes. Nenhum PASS regional T26, cobertura hospitalar, filtro P5, contrato global da `%LINK_KEY`, ou denominador geral pode ser inferido.

**Não iniciar C4-B1 nesta triagem.** Os resultados regionais de T26, a matriz de filtros simultâneos e UI D2 continuam pendentes **em seus próprios escopos**, sem autorização para somar vários testes a C4-B1.

## 5. Critério de encerramento e handoff

**PASS READ-ONLY alcançado:** a matriz discrimina cobertura de T24/T25/T26/FLU, temporalidade, papéis e bloqueios. Há uma hipótese física nova **delimitada e não redundante**, condicionada à pré-verificação dos CSVs F2/F3 já produzidos. **Não representa `MEASURES_AND_DENOMINATOR_CONTRACT=APPROVED`** nem permite ultrapassar `C2_FULL=NO_GO_NOT_APPROVED`.

**Drift documental:** [PR #139](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/139) foi revisto estaticamente; seu texto registra corretamente `C4_A_EVIDENCE_REVIEW=PROPOSED_NOT_RUN` **como snapshot de readiness**. Este documento registra a revisão posterior; como ambos permanecem Draft, **não alterar `docs/project/current-state.md` na `main` para fingir que uma decisão de C4-A não integrada já é canônica**. PRs #110–#114 são fontes históricas em suas próprias branches e têm `NOT_RUN` preliminares preservados e conclusões locais posteriores, sem drift operacional na `main` a corrigir neste gate.

**Estado final do escopo:** `C4_A_EVIDENCE_REVIEW=COMPLETED_WITH_ONE_BOUNDED_CANDIDATE` **nesta branch apenas**; `C4_B1_REGIONAL_T25=PROPOSED_NOT_AUTHORIZED`; `C4_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `C2_FULL=NO_GO_NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP:** documento/PR Draft publicado. Próxima decisão do responsável: se desejar avanço, autorizar **somente** a verificação READ-ONLY dos oráculos F2/F3 do cenário `SERV JP_CG_2` como entrada de possível C4-B1; **não** autorizar COM por esta decisão.
