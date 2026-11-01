# SAD — Data Mart SUS PB

Projeto acadêmico de **Sistemas de Apoio à Decisão (SAD)** — Sistemas de Informação, 2026.2.

## Objetivo e arquitetura preservados

Construir no **QlikView 12** um Data Mart para 2017–2019 com SIH/SUS RD, CNES LT/ST e IBGE/SIDRA, incluindo produção de internações, capacidade de leitos observados e população municipal. Fluxo obrigatório: `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.

Modelo acadêmico entregue: **três fatos e oito dimensões** em Star Schema por processo, compondo constelação com dimensões conformadas. Capítulos 1–2 entregues em 13/10/2026 conforme relato; parecer docente pendente. Não alterar o modelo nem a promessa acadêmica sem aprovação.

## Situação operacional — 31/10/2026

**Fonte viva após integração documental:** [current-state](docs/project/current-state.md); em branch Draft, esse snapshot ainda não substitui a versão da `main`. Auditoria de origem: `main@2d205d52ab96eca565e85a9db5cfde14d9d3025c`. [Consolidação de governança e aceleração](docs/project/governance-c2-p12-consolidation-2026-10-31.md) distingue provas físicas locais, oráculos analisados e integração de PRs.

- **Dados/modelo:** 108/108 DBCs convertidos; 22 QVDs (10 extração + 12 transformação) e três QVWs canônicos, conforme evidências locais; três fatos/oito dimensões preservados, sem auditoria independente dos binários neste gate.
- **Consumo:** auditoria de 14 visuais e oráculos P1–P3 em escopos delimitados; nenhum painel final homologado. A0 padrão e A1 condicional somente P2.3.
- **C2:** [PR #201 integrado](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201) comprovou despacho temporal BU15 em um cenário. [PR #203 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/203) observou que CH02 histórico não atende ao recorte guiado; [PR #204 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/204) propõe separar visuais; [PR #205 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205) encerrou **PASS restrito de 12/12 competências 201901–201912, total 188.246**, com integridade de fonte e 25 protegidos reportada pelo Verify local. O QVW TEMP não está integrado à main nem constitui painel final.
- **Gate residual:** a [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196) permanece aberta para estados incompatíveis/rotas temporais e definição de aceitação C2; a [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) permanece aberta especificamente para suficiência científica CNES/LT dos indicadores condicionados.
- **Nenhum GO implícito:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**Sequência curta recomendada:** (1) consolidar provas documentalmente, sem integrar runners experimentais; (2) decidir/validar apenas a lacuna residual de C2; (3) C3→C4 por dependência e por indicador, em ordem do Boundary 7; (4) GO formal para três painéis QlikView 12; (5) relatório Capítulos 3–5/anexos e entrega. A data da segunda avaliação precisa ser confirmada. Não remover população/IBGE da promessa acadêmica sem aprovação do responsável e, conforme o impacto, do professor.

## Navegação para agentes e entrega final

- [AGENTS.md](AGENTS.md) e [roteamento de agentes/modelos](docs/project/agent-model-routing.md): decisões duradouras, ambientes, evidência e STOP.
- [Current state](docs/project/current-state.md): próximo gate e bloqueios reais, condicionado ao estado da `main` e de PRs Draft.
- [Requisitos](docs/academic/requirements.md) e [modelagem entregue](docs/academic/chapter-1-2-modeling.md): contrato acadêmico.
- [Direção analítica](docs/project/analytical-direction-2026-10-27.md), [inventário de questões](docs/discovery/analytical-question-inventory-2026-10-27.md) e [matriz dos 14 visuais](docs/discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md): escopo e evidências reutilizáveis.
- [Caminho crítico](docs/project/final-delivery-critical-path.md), [Boundary 7](docs/discovery/boundary-7-implementation-plan.md), [V2](docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md) e [auditoria de governança](docs/project/governance-audit-2026-10-31.md): ordem dos gates, bloqueios e entrega.

A conclusão exige pelo menos três painéis funcionais no QlikView 12, indicadores defendidos por dados, filtros/UX validados e relatório acadêmico final (Capítulos 3–5, referências e anexos); **não** equivale ao número de PRs ou de testes executados.
