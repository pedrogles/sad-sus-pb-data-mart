# SAD SUS PB — Direcionamento analítico e controle de escopo (27/10/2026)

**Estado:** DIRECIONAMENTO_APROVADO_PELO_RESPONSAVEL_EM_CHAT; **registro nesta branch é proposta para integração**, não aceite formal da `main`, do professor, de contratos físicos ou de produção.
**Baseline de elaboração:** `main@9f4fc0ea43dfe8b6f20f7b6254bc7f965f6a9c04`.
**Fontes superiores:** roteiro do professor, `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, Capítulos 1–2, V2 §62 e Boundary 7.

## 1. Por que ajustar a prioridade

Há resultados locais reportados para SIH/RD, CNES/LT e população 2017–2019; a estratégia anterior concentrava o caminho crítico no fechamento global dos indicadores T25/T26, escopo hospitalar CNES, chaves e UX. Esses contratos ainda possuem lacunas reais, **mas não bloqueiam perguntas descritivas independentes** feitas diretamente às fatos. A nova ordem de *trabalho analítico* não modifica a ordem de *implementação física* do Boundary 7.

## 2. Direção aprovada e objetivo candidato

Priorizar **análises quantitativas concretas, rastreáveis e cientificamente limitadas** dos datasets existentes. Objetivo analítico candidato:

> Analisar a distribuição territorial e a evolução da produção de internações processadas pelo SUS, da capacidade de leitos cadastrada no CNES e da população residente na Paraíba, no período 2017–2019, com ênfase em concentração de serviços, fluxos entre municípios e limites observacionais das fontes.

A formulação é proposta a confrontar com dados e requisitos: **não substitui automaticamente** o objetivo acadêmico dos Capítulos 1–2 entregues. Três eixos, em ordem de validação preferencial:

1. **Produção hospitalar SIH/RD:** `QTD_INTERNACAO`, competência, município SERV, `PROC_REA`, `DIAG_PRINC`, `DIAS_PERMANENCIA`, `VALOR_TOTAL`, `INDICADOR_OBITO`.
2. **Leitos CNES/LT observados:** `QT_EXIST`, `QT_SUS`, `QT_NSUS` por competência, município SERV, CNES e código de leito, com ausência/zero explicitados.
3. **Fluxos residência → serviço SIH/RD:** R=S, R≠S, pares RES/SERV e residentes externos, exclusivamente dentro de atendimentos realizados na PB.

População IBGE/SIDRA permanece fato/dimensão conformada essencial, com uso direto no indicador T24 quando contrato temporal, territorial, associativo e de denominador permitir; ela não deve ser multiplicada por competência.

## 3. O que permanece sem alteração

- Ferramenta: **QlikView 12**. Pipeline `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.
- Modelo: Star Schema por processo, constelação com `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO` e oito dimensões acadêmicas.
- Grãos, RN21, V2 §62, papéis RES/SERV, `IDENT=5` não contando como internação, `N_AIH` não sendo PK, 2017–2019 e ordem física do Boundary 7.
- Leitos e população semi-aditivos no tempo; `internações/leito médio` **não** é taxa de ocupação; SIH/RD não mede demanda reprimida/pacientes únicos.
- `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; ausência LT ≠ zero de leitos. T25/T26 seguem apenas complementares e condicionados ao universo `LT_TODOS_REGISTROS_VALIDOS_RN21` em recortes reconciliados.
- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Primeira entrega 13/10 permanece fechada, avaliação professor pendente.

## 4. Três painéis candidatos — não implementados

1. **Produção Hospitalar:** evolução anual/mensal, ranking de municípios de atendimento, procedimentos e diagnósticos, medidas administrativas.
2. **Distribuição Observada de Leitos:** snapshots mensais, quantidades SUS/existentes/não SUS, distribuição por município/CNES/código e observabilidade.
3. **Fluxos Territoriais:** origem→destino, concentração de atendimento, R=S versus R≠S e origens externas à PB.

São apenas **candidatos sujeitos à suficiência analítica**. O inventário de 12 perguntas e estados está em `docs/discovery/analytical-question-inventory-2026-10-27.md`.

## 5. Próxima meta, gate e dependências

**Meta:** `SAD-ANALYTICAL-SUFFICIENCY-01` — demonstrar, sobre dados existentes, o que as 12 perguntas conseguem responder numericamente e quais visuais são sustentados. **Primeiro subgate:** `EXTRATOS-ANALITICOS-READONLY-01`, contrato em `docs/discovery/analytical-sufficiency-plan-2026-10-27.md`.

Trilhas distintas:
- **Trilha A — independente (próxima):** inspecionar fontes/QVDs/exportações disponíveis; obter, em modo somente leitura, agregados não extraídos; reconciliar e fechar especificação de 3 painéis **sem implementar o PAINEL.qvw**.
- **Trilha B — condicionada:** G1 / [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) trata da suficiência científica T25/T26; depois G2–G5 fecham contratos físicos, filtros e autorização de IX nos recortes aprovados.
- Não condicionar I01–I11, quando analisados **dentro da própria fato sem vínculo inter-fatos**, ao aceite de T25/T26. Não afirmar que a trilha A homologa Link Key, V2 física, QlikView ou dashboards.

**STOP da mudança documental:** estratégia + inventário + plano + bootstrap e referências atuais sincronizados em branch/PR; nenhum merge, modificação de dados ou decisão de G1. Somente o responsável pode autorizar integração e execução mutante posterior.
