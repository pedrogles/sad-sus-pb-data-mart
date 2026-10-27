# SAD — Data Mart SUS PB

Projeto acadêmico de **Sistemas de Apoio à Decisão (SAD)** — Sistemas de Informação, semestre 2026.2.

## Objetivo e fontes

Construir um Data Mart no **QlikView 12**, para 2017–2019, integrando SIH/SUS RD (internações processadas), CNES LT/ST (leitos e estabelecimentos) e IBGE/SIDRA (população municipal), sem atribuir causalidade ou demanda reprimida aos registros. Fluxo obrigatório: `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.

Arquitetura acadêmica preservada: **Star Schema por processo e constelação de três fatos com oito dimensões conformadas**. Primeira entrega (Capítulos 1–2) reportada como realizada em **13/10/2026**, com avaliação do professor pendente.

## Estado operacional — referência de 27/10/2026

**Fonte de verdade viva:** [current-state.md](docs/project/current-state.md), que prevalece sobre este resumo. Na revisão documental, a `main` estava em `9f4fc0ea43dfe8b6f20f7b6254bc7f965f6a9c04`. Relatórios de execução local indicam Fases III–V (10 QVDs de extração, oito dimensões e três fatos), `LINK_ANALISE.qvd` candidato e Fase VII com painel **técnico** experimental (não painel acadêmico aprovado). A Fase VIII contém pilotos limitados, sem homologação global; Fase IX segue `NOT_AUTHORIZED`. **22 QVDs e três QVWs canônicos** foram reportados preservados localmente, não auditados diretamente nesta revisão.

**Direção aprovada no chat em 27/10/2026:** antes de implementar os três painéis finais, validar resultados reais que podem ser obtidos sem novos datasets. O novo objetivo é verificar **12 perguntas** e uma proposta de **3 painéis** (produção hospitalar, leitos CNES/LT observados e fluxos residência→atendimento). O gate candidato é `EXTRATOS-ANALITICOS-READONLY-01`, de exploração e reconciliação dos dados existentes, inicialmente sem alteração física.

Essa frente **não substitui nem resolve** G1 / [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) para T25/T26. Não interpretar o uso analítico isolado das fatos como aprovação de Link Key, contratos físicos, filtros, cobertura hospitalar ou produção.

**Invariantes:** `C2_FULL=NO_GO_NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## Orientação e documentação principal

- [AGENTS.md](AGENTS.md) — regras duradouras do projeto.
- [Current state](docs/project/current-state.md) — roteamento operacional vigente.
- [Requisitos acadêmicos](docs/academic/requirements.md) e [modelagem entregue](docs/academic/chapter-1-2-modeling.md).
- [Direcionamento analítico](docs/project/analytical-direction-2026-10-27.md) — revisão de prioridade e invariantes.
- [Inventário analítico](docs/discovery/analytical-question-inventory-2026-10-27.md) — 12 perguntas e três painéis candidatos.
- [Plano de suficiência](docs/discovery/analytical-sufficiency-plan-2026-10-27.md) e [bootstrap para novo chat](docs/discovery/bootstrap-extratos-analiticos-readonly-2026-10-27.md).
- [Caminho crítico físico/acadêmico](docs/project/final-delivery-critical-path.md), [V2 §62](docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md) e [Boundary 7](docs/discovery/boundary-7-implementation-plan.md).

**Proveniência:** o direcionamento e os quatro registros documentais foram submetidos no [PR #159](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/159); considerar o estado de integração indicado pelo GitHub e pela `main` consultada, não presumir que a branch permanece Draft.
