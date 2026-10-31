# SAD — Data Mart SUS PB

Projeto acadêmico de **Sistemas de Apoio à Decisão (SAD)** — Sistemas de Informação, 2026.2.

## Objetivo e arquitetura preservados

Construir no **QlikView 12** um Data Mart para 2017–2019 com SIH/SUS RD, CNES LT/ST e IBGE/SIDRA, incluindo produção de internações, capacidade de leitos observados e população municipal. Fluxo obrigatório: `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.

Modelo acadêmico entregue: **três fatos e oito dimensões** em Star Schema por processo, compondo constelação com dimensões conformadas. Capítulos 1–2 entregues em 13/10/2026 conforme relato; parecer docente pendente. Não alterar o modelo nem a promessa acadêmica sem aprovação.

## Situação operacional (snapshot de 31/10/2026)

**Fonte viva para próximos trabalhos:** [estado operacional](docs/project/current-state.md), com checagem obrigatória de [AGENTS.md](AGENTS.md), [requisitos](docs/academic/requirements.md) e da `main` antes de qualquer ação. Este resumo é histórico: `main@238d4f70c5cf4576808fdd43af4a3d72b4e0b7cc`, sem antecipar merges de branches Draft.

- **ETL e QVDs:** 108/108 DBC e 22 QVDs (10 extração + 12 transformação) reportados em execuções locais. Três fatos materializados; binários QVW/QVD continuam locais, não versionados e não auditados diretamente nesta revisão.
- **Consumo analítico:** [14 visuais candidatos](docs/discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md) auditados documentalmente; P1–P3 com provas numéricas/observacionais restritas. Isso não é aceite físico/visual global.
- **C2:** desenho temporal [PR #200](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/200) integrado. O [PR #201](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201) permanece **Draft** nesta captura; relatou `PASS_VISUAL_RESTRICTED` de um botão que aplicou ano real 2019 e `-Verify` de integridade local. **A série guiada de 12 meses ainda não foi validada**. [PR #199](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/199) segue Draft com bloqueio anterior.
- **Governança:** [auditoria e higiene de 31/10](docs/project/governance-audit-2026-10-31.md) e [inventário CSV das branches](docs/project/branch-hygiene-snapshot-2026-10-31.csv) são **propostas nesta branch** até merge; sem exclusões.
- **Sem liberação:** `C2_FULL=NO_GO_NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**Próximo trabalho físico candidato (não autorizado automaticamente):** depois da revisão do PR #201, delimitar teste da série `201901–201912` no modo `EVOLUCAO/2019`, reutilizando o oráculo histórico, sem repetir a seleção de ano que já passou restritamente. A ordem física C2→C3→C4→IX segue o [Boundary 7](docs/discovery/boundary-7-implementation-plan.md).

## Navegação para agentes e entrega final

- [AGENTS.md](AGENTS.md) e [roteamento de agentes/modelos](docs/project/agent-model-routing.md): decisões duradouras, ambientes, evidência e STOP.
- [Current state](docs/project/current-state.md): próximo gate e bloqueios reais, condicionado ao estado da `main` e de PRs Draft.
- [Requisitos](docs/academic/requirements.md) e [modelagem entregue](docs/academic/chapter-1-2-modeling.md): contrato acadêmico.
- [Direção analítica](docs/project/analytical-direction-2026-10-27.md), [inventário de questões](docs/discovery/analytical-question-inventory-2026-10-27.md) e [matriz dos 14 visuais](docs/discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md): escopo e evidências reutilizáveis.
- [Caminho crítico](docs/project/final-delivery-critical-path.md), [Boundary 7](docs/discovery/boundary-7-implementation-plan.md), [V2](docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md) e [auditoria de governança](docs/project/governance-audit-2026-10-31.md): ordem dos gates, bloqueios e entrega.

A conclusão exige pelo menos três painéis funcionais no QlikView 12, indicadores defendidos por dados, filtros/UX validados e relatório acadêmico final (Capítulos 3–5, referências e anexos); **não** equivale ao número de PRs ou de testes executados.
