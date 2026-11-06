# SAD C2-R2 — Preflight de indicador após ação nativa

**Gate:** SAD-C2-R2-NATIVE-INDICATOR-RESIDUAL-PREFLIGHT-01.
**Data:** 06/11/2026.
**Status:** COMPLETE_READONLY / PHYSICAL_NOT_RUN.
**Origem:** main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83; AGENTS.md, current-state.md, requirements.md; D2-R2 V3, Boundary 7, Issue #196 e PR #223.

## Evidência reutilizada

- QVW consolidada de origem: SHA-256 reportado 6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58.
- ZIP forense auditado: SHA-256 3B713B71F6FC214A4BBADD3BF3626ED7026BD320DCD5E88886D3268B7CE5F335. XML exportado; não se leu a QVW binária no GitHub.
- F1/F2 da origem: PASS_VISUAL_RESTRICTED e aceite explícito limitado à apresentação na Issue #196; integridade dos 25 protegidos reportada, sem homologação C2 global.
- TX16 já reagiu a Seleções → Limpar em teste restrito anterior. **TX16 é canário, não comprova CH03.** Não repetir TX16, BU16, F1/F2 ou Verify anterior.

## Inventário efetivamente fundamentado em XML

| Objeto | Regra efetiva | Lacuna real |
| --- | --- | --- |
| CH03 | Dimensão PERIODO_COMPETENCIA; medida Sum(QTD_INTERNACAO); condição exige proposta EVOLUCAO, ano real único igual ao proposto e nenhuma competência real explicitamente selecionada. | A condição sugere ocultação após Clear, mas o resultado nativo não foi testado em CH03. |
| TX17 | Para ano real/proposto compatível, informa seleção mensal; nos demais contextos retorna mensagem genérica de fora de F1/F2. | **Falta motivo explícito de ausência de ano real** após Clear, ou de mais de um ano. |
| TX08 | Mostra estado real dos campos temporais. | É necessário distinguir ano selecionado da variável de proposta. |
| CH02 | Medida histórica com anos fixos e PERIODO_COMPETENCIA limpo no Set Analysis. | Preservação do gráfico na nova ação nativa não comprovada. |
| TX10–TX13 | Cartões históricos por ano e triênio. | Devem permanecer referências históricas; não trocar por KPI anual pontual. |

## Matriz mínima por cenário

| Cenário | Situação |
| --- | --- |
| F1 2019/201901, proposta EVOLUCAO/2019 | PASS visual restrito existente; não repetir |
| F2 2018 sem mês, proposta EVOLUCAO/2018 | PASS visual restrito existente; reutilizar só como setup de novo cenário |
| **Nativo Limpar após F2 na nova TEMP** | **NOT_TESTED** em CH03/TX17; um único cenário elegível |
| Multi-ano e competência parcial | NOT_TESTED; **não incluir neste microgate** |

**Decisão técnica candidata, não produção:** uma única mudança manual na expressão TX17, em nova cópia TEMP protegida, para comunicar ausência de ano e evitar erro de interpretação; comparar apenas um antes/depois de Seleções → Limpar, sem alterar CH03, CH02, cartões ou fontes. O microgate não prova prevenção global de rotas nativas nem cobertura P5.

**Critérios:** PASS visual restrito apenas com estado real comprovado, CH03 indisponível sem série obsoleta, aviso TX17 específico, histórico preservado e hashes protegidos inalterados. BLOCKED se QVW/origem divergirem, indicador apresentar número inválido ou motivo faltar. INCONCLUSIVE se evidência nativa for insuficiente.

**Fronteiras:** C2_GUIDED_R2=PARTIALLY_TESTED_NOT_APPROVED_GLOBAL; P5_D2_UI=NOT_TESTED_GLOBAL; READY_FOR_C3=NO; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False. A main/current-state.md ainda tem drift de status; corrigir em atividade documental separada.

**STOP preflight:** nenhuma ação QlikView/COM/Reload/Save executada para esta análise. O runbook do gate físico define a intervenção isolada futura.
