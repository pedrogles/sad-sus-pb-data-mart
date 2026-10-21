# Fase VIII — C4 | Readiness READ-ONLY do contrato físico de medidas e denominadores (20/10/2026)

**Status:** `C4_PREPARATION=DOCUMENTED_READ_ONLY`; `C4_A_EVIDENCE_REVIEW=PROPOSED_NOT_RUN`; `C4_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`. Este documento **não é uma expressão QlikView aprovada, execução, aceite de indicadores, nem liberação de Fase IX ou produção**.

**Base Git verificada:** `main@949e6e96b6e0f4e530672d52808ad178080bce28`, após #137 (C3-B2 físico candidato e closeout) e #138 (correção do roteamento operacional). Trabalho em branch documental própria, sem alteração da `main` ou de scripts e binários.

## 1. Objetivo e justificativa de escopo

Preparar o menor gate **READ-ONLY** que permita decidir, com as provas já disponíveis, **quais contratos físicos específicos de medidas e denominadores ainda necessitam de teste**, sem repetir T24–T26, C3-B1/B2, Fase VII, C2-D2/Win32 ou criar novos QVWs.

O Boundary 7 ordena Fase VIII — Indicadores, antes da Fase IX — Dashboards. A V2 §62, semanticamente aprovada em 14/10/2026, define os significados, mas **não** aprova expressões QlikView nem reconciliações físicas globais. O C3 encerrou dois cenários associativos como PASS **candidatos**; `LINK_KEY_CONTRACT=NOT_APPROVED`. Portanto, C4 pode ser **preparado** sem promover C3 a homologação plena. Para eventual aceite físico amplo de C4, riscos residuais de `%LINK_KEY`, D2, P5 e cobertura precisam ser explicitados, nunca superados por inferência.

**Fontes consultadas:** `AGENTS.md`; `docs/project/current-state.md`; `docs/academic/requirements.md`; [Boundary 6](boundary-6-qlikview-physical-architecture.md); [Boundary 7](boundary-7-implementation-plan.md); [contrato semântico V2 §62](phase-6-semantic-v2-approved-2026-10-14.md); [VI-P5](phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md); [VI-R2](phase-6-link-analise-physical-r2-2026-10-18.md); [C2 closeout](phase-8-c2-evidence-closeout-readonly-2026-10-20.md); [C3-B1](phase-8-c3b1-physical-closeout-2026-10-20.md); [C3-B2](phase-8-c3b2-physical-closeout-2026-10-20.md); [automação PowerShell](../project/qlikview-powershell-automation.md). Para os pilotos T24–T26, PRs experimentais [#110](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/110), [#111](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/111), [#112](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/112), [#113](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/113), [#114](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/114); seus relatórios e scripts **permanecem nas respectivas branches Draft** enquanto não houver integração formal.

## 2. Contrato semântico vinculante — não reinterpretar

| Família | Numerador | Denominador correto | Papel territorial | Limite obrigatório |
| --- | --- | --- | --- | --- |
| **T24 / RES**: internações processadas de residentes por 1.000 habitantes | `SUM(QTD_INTERNACAO)` no SIH/RD processado na PB, `IDENT=5` com contribuição zero | POP anual IBGE/F3 por município **de residência**, somada uma vez por município/ano | `RES` | `SERV` filtrado é **B** no indicador geral, embora seja C no FLU |
| **T25 / LEI**: leitos SUS médios por 1.000 habitantes | Média dos totais `QTD_LEITOS_SUS` por competência, apenas em cobertura e universo explicitamente válidos | POP anual por município **de serviço/localização**, uma vez por município/ano | `SERV` | Capacidade é snapshot mensal; 12 competências requeridas para ano completo |
| **T26 / REL**: internações por leito SUS médio | `SUM(QTD_INTERNACAO)` por **serviço** no período | Média dos totais mensais `QTD_LEITOS_SUS` no mesmo território/período e universo validado | `SERV` | **Não é taxa de ocupação**; POP não integra o denominador |
| **FLU**: fluxo residência → serviço | `SUM(QTD_INTERNACAO)` por par R/S | **Nenhum** denominador POP implícito | `RES` e `SERV` | C3 testa associação, não uma razão POP |

**Ano e competência:** ano único para KPI pontual; sem ano ou vários anos num KPI único → indisponível. Janelas parciais usam internações/leitos do período e **POP anual claramente identificada**, sem anualizar taxas parciais ou denominar intervalo descontínuo como contínuo. Em série temporal de múltiplos anos, calcular cada ano separadamente e não somar POP entre anos como se fosse mesmo denominador anual. Aplicar eixo administrativo RD, não datas clínicas como equivalentes. Manter a regra D2 de prevenção de conflito entre ano/competência **antes da seleção**; ainda não há comprovação de UI global.

**Agregação territorial e cobertura:** somar numeradores compatíveis e POP municipal distinta antes de calcular razão; não calcular média simples de razões municipais para expressar razão regional. Para capacidade regional, somar os quantitativos **dentro de cada competência** e então calcular a média dos snapshots; não somar leitos ao longo dos meses como disponibilidade anual. Ausência de LT/POP não implica zero. Apenas numerador comprovadamente zero, denominador positivo e cobertura válida permite indicador zero. A avaliação de cobertura hospitalar histórica CNES continua `NOT_VERIFIED`; os pilotos T25/T26 usaram apenas o universo observacional declarado `LT_TODOS_REGISTROS_VALIDOS_RN21`, não capacidade hospitalar historicamente homologada.

**Filtros P5:** preservar integralmente a matriz V2 §62.6 (classes C, R, I, B para RES/LEI/REL/FLU), inclusive filtros simultâneos. `R` exige análise específica contratada, `I` requer isolamento explícito validado/avisado, `B` bloqueia o indicador geral. Não usar `Set Analysis` para ignorar silenciosamente filtros incompatíveis. `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY` e `P5_D2_UI=NOT_TESTED` bloqueiam homologação geral.

## 3. Matriz de evidências disponíveis a reutilizar antes de propor testes

| Evidência | Cobertura reportada/inspecionada | Ainda não autoriza |
| --- | --- | --- |
| F1: `F1_residencia_ano.csv`, `F1_residencia_competencia.csv`, `F1_servico_ano.csv`, `F1_servico_competencia.csv`, `F1_fluxo_ano.csv`, `F1_fluxo_competencia.csv` | Numeradores SIH/RD por ano/competência/papel, identidades 1 e 5, referência gerada independentemente da expressão Qlik | Campo/papel físico compatível sob **todos** os filtros, generalização das razões |
| F2: `F2_lt_municipio_competencia_observado.csv`, `F2_lt_municipio_ano_cobertura_candidata.csv` | LT observada por município serviço e competência, soma de snapshots como **auditoria** para média, marcações de meses com linhas/ausência | Completude hospitalar, prova de zero real na falta de linhas, população ou denominador válido |
| F3: `F3_pop_municipio_ano.csv`, `F3_componentes_residencia_ano.csv`, `F3_componentes_servico_ano.csv`, `F3_cenarios_multimunicipais.csv`, `F3_residentes_externos_ano.csv` | POP anual PB, componentes locais e regionais de razão candidata e ausência de POP PB para residentes externos; reconciliações de base | Recuperação física geral de POP sob filtros de competência e P5 |
| [#110–#112](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/110) | T24 anual PB/JP/CG, T24 parcial e descontínuo, região e indisponibilidades; execuções locais candidatas **relatadas**, scripts apenas Draft | Conjunto completo de filtros; UI D2; produção |
| [#113](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/113) e [#114](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/114) | T25/T26 anuais JP/CG e parcial JP/201801 no universo LT RN21 observacional; execuções locais candidatas **relatadas** | Cobertura hospitalar histórica, indicador geral, taxa de ocupação |
| VI-P2, VII, C3-B1 e C3-B2 | Grafo técnico, dois cenários associativos R≠S/R=S, POP positiva R=S 2018 e LT não alcançável com residência selecionada | Contrato definitivo `%LINK_KEY`, fórmula de qualquer T24/25/26 sob filtro proibido, POP mensal em geral |
| C2 READ-ONLY | Bloqueios P5 em subconjuntos e provas limitadas de UI, incluindo D2-Win32 inconclusivo | `C2_FULL=APPROVED`, P5 global, D2 pre-dispatch por todas as rotas |

**Proveniência:** o ZIP C3-B2 integrado ao closeout é 12 arquivos exportados e SHA-256 `0CEEBAFD3A632C8F04DC992D7C6438E0271668A974B73CB91D2E80FCD5166264`, auditado sem reabrir binários. A revisão C4-A futura deve localizar manifestos reais para **todos** os oráculos adicionais necessários e conferir hashes antes de aceitar números; não fixar contagens/demais razões de T24–T26 usando somente a descrição de PR.

## 4. Gate C4-A proposto — triagem READ-ONLY, delimitada

**Objetivo:** uma matriz de cobertura de **T24/T25/T26/FLU × anual/parcial × residência/serviço × aplicação temporal/filtros incompatíveis** baseada **somente** em relatórios já versionados e evidências existentes; distinguir (a) número reportado por operador, (b) CSV/log exportado independentemente conferido, (c) teste físico ainda não realizado, (d) cobertura/semântica bloqueada.

**Entradas:** scripts e documentos da `main`, documentação efetiva das branches #110–#114 (sem merges automáticos), V2, F1/F2/F3, inventários de SHA anteriores e provas C2/C3. Preferir documentação e arquivos já disponíveis; não recriar oráculos, nem reexecutar pilotos.

**Critério PASS estritamente documental:** produzir tabela com cada medida e denominador previstos, grão/universo/competência/papel, cobertura de casos já existentes, discrepâncias identificadas com causa/limite, bloqueios globais explícitos, e **decisão fundamentada entre (i) nenhuma prova física adicional justificada ou (ii) um único candidato C4-B mínimo**, acompanhado de critério exato de aceite. Não forçar caso novo quando os já registrados bastarem. C4-A não conclui nem aprova contrato de medidas.

**BLOCKED/INCONCLUSIVE:** falta de manifestação de hash/oráculo, inconsistência entre F1/F2/F3 e output Qlik, caso novo não delimitado, omissão de P5/temporal ou tentativa de inferir cobertura hospitalar. Registrá-lo; não “corrigir” teste histórico nem mudar regra V2.

**STOP:** após uma matriz e uma decisão de necessidade de prova mínima, em PR documental de objetivo único. Não avançar para C4-B, indicadores definitivos, UI, merge de branches experimentais ou Fase IX.

## 5. C4-B eventual — limites para autorização futura (NÃO autorizado)

Caso C4-A encontre lacuna física real, formular **antes** de executar um protocolo de **um** cenário estritamente justificado, usando QVW TEMP com origem e SHA reais e runner PowerShell/QVS **versionado em nova branch antes da execução** (`AGENTS.md`). Reutilizar validadores e F1/F2/F3; nenhuma gravação/reload QVD, nenhuma alteração `EXT.qvw`/`TRANSF.qvw`/`PAINEL.qvw`, nem recarga de pilotos. Confirmar branch/HEAD, QVW, oráculos, 22 QVDs, três QVWs canônicos, inventários SHA pré/pós, logs e CSVs persistentes e posterior auditoria exportada. **Nova autorização específica** para `-RunQlik` e para qualquer merge. Falha: `BLOCKED`, preservar evidências, STOP sem reexecução automática.

**Qualquer PASS C4-B será apenas candidato no caso observado.** A aprovação de `MEASURES_AND_DENOMINATOR_CONTRACT` depende de decisão separada; contrato `%LINK_KEY`, cobertura hospitalar, D2/P5 e interface têm gates próprios. Não tentar contornar C2 bloqueado pela materialização de um KPI.

## 6. Invariantes e situação de encerramento desta preparação

**Escopo tocável:** este documento no PR Draft. Sem novos QVS, PowerShell, Python, QVD, QVW, merges C4, relatórios finais ou alterações na modelagem entregue dos capítulos 1 e 2. Três fatos, oito dimensões, Star/constelação, Link Table física, `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL` e QlikView 12 preservados.

**Estados preservados:** `C4_PREPARATION=DOCUMENTED_READ_ONLY`; `C4_A_EVIDENCE_REVIEW=PROPOSED_NOT_RUN`; `C4_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `C2_FULL=NO_GO_NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Resultado desta execução:** pronto para **revisão/decisão de iniciar C4-A READ-ONLY**, sem alegar C4-A executado ou C4 aprovado. Nenhuma expansão automática de escopo.
