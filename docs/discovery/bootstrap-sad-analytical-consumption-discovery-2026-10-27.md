# Bootstrap — novo chat: SAD-ANALYTICAL-CONSUMPTION-DISCOVERY-01

**Agente primário:** ChatGPT com GitHub conectado; **modo:** READ-ONLY; **esforço:** Medium se disponível, escalar apenas se contradição semântica material. **Fallback:** documentação GitHub e arquivos fornecidos; Windows/QlikView indisponível neste gate. 

Você está trabalhando no projeto acadêmico SAD — Data Mart SUS PB, repositório **pedrogles/sad-sus-pb-data-mart**, QlikView 12 obrigatório, semestre 2026.2.

## Leitura obrigatória antes de iniciar

Na branch **main** atual, sempre nesta ordem:

1. AGENTS.md
2. docs/project/current-state.md
3. docs/academic/requirements.md
4. docs/project/agent-model-routing.md

Depois verificar **o PR Draft que preparou esta Discovery**: sua existência/integracão e os arquivos:
- docs/project/analytical-source-and-architecture-decision-2026-10-27.md
- docs/discovery/sad-analytical-consumption-source-matrix-2026-10-27.md
- docs/discovery/sad-analytical-consumption-discovery-2026-10-27.md

Consultar ainda:
- docs/discovery/analytical-question-inventory-2026-10-27.md
- docs/discovery/analytical-sufficiency-plan-2026-10-27.md
- docs/academic/chapter-1-2-modeling.md
- docs/discovery/boundary-5-historization-role-playing.md
- docs/discovery/boundary-6-qlikview-physical-architecture.md
- docs/discovery/boundary-7-implementation-plan.md
- docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md
- PR #160, Issue #161 (AE01), Issue #157 (T25/T26).

**Baseline histórico de elaboração (não confiar sem revalidar):** main@db5d6e6e23371422ca1d2d77a8576150aaf63d03. AE01 execução local observada no commit 8633f12a910f422f6b2e9af5e0d06d622ff13497, PR #160 Draft e PASS de exportação/reconciliação **restrito**. Manifesto anexado SHA-256 0B1AA7DA6EF10A08B0F698250F199666525672DC763D6774CA4498B2A3C488D2. Quatro CSVs E1–E4 de SIH/RD e CNES/LT foram anexados e auditados; 9 das 12 perguntas descritivas sustentadas, I06/I07 históricos sem reauditoria com AE01, I12 condicionado a POP/contratos. A análise adicional é EXPERIMENTAL_NOT_GATE_EVIDENCE; não transformar em homologação física.

## Objetivo único

Executar **SAD-ANALYTICAL-CONSUMPTION-DISCOVERY-01** para comparar A0 (constelação atual com consultas/filtros independentes) e A1 (camada de consumo/projeções candidatas sem materialização) e indicar o desenho mínimo para três painéis descritivos, **preservando a modelagem acadêmica**.

Responder com evidências:

1. Quais fontes são obrigatórias, enriquecimento opcional ou dependências condicionadas, para cada I01–I12 e T24/T25/T26/FLU?
2. Para cada visual dos três painéis, quais campos existem realmente no staging, nas fatos e dimensões, e quais exigem SK/%LINK_KEY ainda não homologada globalmente?
3. Que filtros/tempo/território/observabilidade tornam os resultados sustentados, condicionados ou indisponíveis?
4. A0 é suficiente? A1 agrega valor sem criar duplicações, novos fatos ou violar a semântica? Sob que prova A2 (remodelagem) seria justificável?

## Fronteira de execução e proibições

**READ-ONLY estrito.** Não fazer QlikView/COM/GUI, reload/STORE, editar QVD/QVW/CSV originais, executar scripts novos, download de bases, criar objetos de painel, fazer merge, modificar arquitetura, RN21/V2/Capítulos 1–2 ou liberar Fase IX. Não repetir testes de pilotos fechados; não presumir que extratos com PROC_REA/DIAG_PRINC/RES/SERV sejam a estrutura física das fatos. Persistência do Data Mart ≠ camada analítica.

**Status físicos preservados:** LINK_KEY_CONTRACT=NOT_APPROVED, MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED, C2_FULL=NO_GO_NOT_APPROVED, CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED, T29_HISTORICAL=NOT_APPROVED, PHASE_IX=NOT_AUTHORIZED, PRODUCTION_APPROVED=False. Três fatos, oito dimensões, 22 QVDs e 3 QVWs protegidos.

## Entrega e STOP

Entregar: (a) matriz completa I01–I12 por fonte/fato/grão/campo/filtro/prova; (b) especificação de 3 painéis com 3–5 visuais cada; (c) comparação A0×A1 (A2 só hipótese se evidência); (d) até três bloqueios concretos; (e) recomendação e handoff com próximo gate separado.

Usar veredito DISCOVERY_DOCUMENTED_READONLY, BLOCKED_MISSING_EVIDENCE ou ESCALATE_ARCH_DECISION. Parar nesses entregáveis. Qualquer implementação, merge ou execução física requer aprovação **separada** do responsável.