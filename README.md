# SAD — Data Mart SUS PB

Projeto acadêmico de **Sistemas de Apoio à Decisão (SAD)** — Sistemas de Informação, 2026.2.

## Objetivo e arquitetura preservados

Construir no **QlikView 12** um Data Mart para 2017–2019 com SIH/SUS RD, CNES LT/ST e IBGE/SIDRA, incluindo produção de internações, capacidade de leitos observados e população municipal. Fluxo obrigatório: `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.

Modelo acadêmico entregue: **três fatos e oito dimensões** em Star Schema por processo, compondo constelação com dimensões conformadas. Capítulos 1–2 entregues em 13/10/2026 conforme relato; parecer docente pendente. Não alterar o modelo nem a promessa acadêmica sem aprovação.

## Situação operacional — 03/11/2026

**Roteamento obrigatório:** [current-state](docs/project/current-state.md) e [adendo semântico V3 D2-R2](docs/discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md), integrados semanticamente em `main@06300a57042082667000f01969c8e184b8409452` pelo [PR #213](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/213). O presente estado documental só substitui o snapshot anterior na `main` **após o merge deste PR de reconciliação**; não confundir branch com main.

- **Dados/modelo:** 108 DBC convertidos, 22 QVDs (10 extração + 12 transformação) e três QVWs canônicos conforme provas **locais reportadas**, não auditados independentemente por GitHub; três fatos/oito dimensões e grãos preservados.
- **Consumo/UX:** [blueprint P1/P2/P3 integrado no PR #209](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/209): três folhas, 14 visuais, **somente layout aprovado**. A0 padrão; ilha A1 restrita a P2.3. Nenhum painel final homologado.
- **C2 histórico restrito:** [PR #201 MERGED](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201) comprovou BU15/2019 em um cenário; [PR #205 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205) reportou gráfico guiado 2019, 12/12 competências, total 188.246, em QVW TEMP. [PRs #208/#210](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/210) registraram guardas/inventário de rotas e Verify de **integridade somente**, com limites de UI.
- **D2 vigente:** o [adendo V3 aprovado/integrado](docs/discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md) exige **prevenção pré-despacho no fluxo guiado** e **validação de indicadores após seleções nativas**, sem alegar prevenção global. A V2 é histórica quanto a D2 e segue vigente nas demais decisões; `C2_GUIDED_R2=NOT_TESTED`. [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196) permanece aberta.
- **Dependências:** [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) aberta para suficiência científica CNES/LT T25/T26 condicionados, não para visuais independentes. POP/IBGE continua no compromisso do Data Mart; associações Link Key, medidas e denominadores ainda não aprovados.
- **Sem GO físico:** `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Próximo gate proposto, não autorizado fisicamente:** especificar/testar somente lacunas de `SAD-C2-GUIDED-R2-PHYSICAL-ACCEPTANCE-01` com uma cópia TEMP protegida, sem repetir PoCs. Ordem preservada: **C2 guiado R2 → C3 → C4 → GO específico IX → três painéis QlikView 12**. Capítulos 3–5/anexos podem ser preparados documentalmente; confirmar data da segunda avaliação. Não reduzir compromisso IBGE nem modificar a modelagem acadêmica silenciosamente.

## Navegação para agentes e entrega final

- [AGENTS.md](AGENTS.md) e [roteamento de agentes/modelos](docs/project/agent-model-routing.md): decisões duradouras, ambientes, evidência e STOP.
- [Current state](docs/project/current-state.md): próximo gate e bloqueios reais, condicionado ao estado da `main` e de PRs Draft.
- [Requisitos](docs/academic/requirements.md) e [modelagem entregue](docs/academic/chapter-1-2-modeling.md): contrato acadêmico.
- [Direção analítica](docs/project/analytical-direction-2026-10-27.md), [inventário de questões](docs/discovery/analytical-question-inventory-2026-10-27.md) e [matriz dos 14 visuais](docs/discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md): escopo e evidências reutilizáveis.
- [Caminho crítico](docs/project/final-delivery-critical-path.md), [Boundary 7](docs/discovery/boundary-7-implementation-plan.md), [V3 D2-R2 vigente](docs/discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md), [V2 histórica](docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md) e [auditoria de governança de 31/10](docs/project/governance-audit-2026-10-31.md): ordem dos gates, decisões e evidências de seus respectivos períodos.

A conclusão exige pelo menos três painéis funcionais no QlikView 12, indicadores defendidos por dados, filtros/UX validados e relatório acadêmico final (Capítulos 3–5, referências e anexos); **não** equivale ao número de PRs ou de testes executados.
