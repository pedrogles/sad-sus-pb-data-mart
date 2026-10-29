# Current State — SAD Data Mart SUS PB

## Estado operacional vigente — 29/10/2026 | P3.1 fechado localmente; PR #190 Draft

**Git verificado:** `main@6f35f86b1d672949d9921cb948463000e02aacdd` ([PR #189](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/189) integrado). O **[PR #190](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/190)** está **aberto em Draft**, na branch `test/sad-p31-sih-res-serv-matrix-2018-readonly-01`, à frente da `main`; **não integrado**. Validador executado a partir do commit `51c55d8e5576ad665b6ba91fe2811cb268e022e8`; fechamento local no commit `de7772c02002b55d3270be7083e5ea54cf3b3e6e`. Correções documentais posteriores ao fechamento não representam nova execução do validador.

**P3.1 — `PASS_RESTRICTED` LOCAL REPORTADO:** matriz SIH/RD E1 de **2018**, por código de município de residência **RES → SERV** (atendimento), com **1.944 pares direcionados observados**, **12 competências**, **183.311 internações novas** e **2 pares observados com zero novas**. Integridade SHA/schema/grão, fechamento anual, dois testemunhos, readback e rejeição de cópia adulterada foram reportados sem divergências. **Não** é auditoria independente/CI, prova de todos os filtros QlikView ou produção. Evidências externas, hashes, limitações e distinção `qtd_registro_aih`/`qtd_internacao`/`qtd_continuidade`: [closeout P3.1](../discovery/sad-p31-res-serv-matrix-2018-readonly-2026-10-29.md). Não executar novamente este gate.

**Estados separados:** `GATE_PASS=True` **somente no alcance numérico local** · `PR_MERGED=False` · `VISUAL_ACCEPTED_GLOBAL=False` · `PRODUCTION_APPROVED=False`. O estado do PR e da `main` deve ser reconferido no GitHub após qualquer mudança futura.

## Rastreabilidade mínima — não é nova homologação

| Marco | Estado e fonte de prova |
| --- | --- |
| Acadêmico | Capítulos 1–2 entregues em 13/10/2026 conforme relato; **parecer docente pendente**. [Requisitos](../academic/requirements.md), [modelagem](../academic/chapter-1-2-modeling.md), [Boundary 7](../discovery/boundary-7-implementation-plan.md). |
| Extração e fatos | 108/108 DBC convertidos, três fatos QVD com CREATE/READBACK e preservação de **22 QVDs**, conforme **execuções locais reportadas**, não auditoria independente dos binários. [Extração](../discovery/phase-3-final-extraction-gate-2026-10-08.md), [internação](../discovery/phase-5-fato-internacao-implementation-2026-10-15.md), [leitos](../discovery/phase-5-fato-capacidade-leito-qvd-materialization-2026-10-15.md), [população](../discovery/phase-5-fato-populacao-qvd-materialization-2026-10-16.md). |
| P1 — SIH/RD | P1.1/P1.2 PoC/controles restritos; P1.3–P1.5 agregações **numéricas restritas**, integradas documentalmente à `main`, sem aceite visual global. [Fechamento P1.1/P1.2](../discovery/sad-p11-p12-physical-closeout-2026-10-29.md), [P1.3](../discovery/sad-p13-serv-ranking-readonly-closeout-2026-10-29.md), [P1.4](../discovery/sad-p14-proc-ranking-readonly-closeout-2026-10-29.md), [P1.5](../discovery/sad-p15-diag-ranking-readonly-closeout-2026-10-29.md). |
| P2 — CNES/LT | P2.1–P2.5 com escopos **numéricos/observacionais restritos**, PRs [#185](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/185)–[#189](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/189) integrados. [P2.1](../discovery/sad-p21-lt-monthly-readonly-closeout-2026-10-29.md), [P2.3](../discovery/sad-p23-lt-municipal-observability-readonly-closeout-2026-10-29.md), [P2.4](../discovery/sad-p24-lt-municipal-ranking-201912-readonly-closeout-2026-10-29.md), [P2.5](../discovery/sad-p25-lt-cnes-type-code-201912-readonly-closeout-2026-10-29.md). Ausência de linha LT não significa zero. |
| Fases VI–VIII | Testes físicos/associativos **candidatos e limitados** no Windows/QlikView 12; sem aprovação global de chaves, filtros, indicadores ou UI. [VII](../discovery/phase-7-technical-panel-controlled-gate-2026-10-18.md), [C4-B1](../discovery/phase-8-c4b1-regional-t25-physical-closeout-2026-10-21.md), [V2](../discovery/phase-6-semantic-v2-approved-2026-10-14.md). Fase IX não autorizada. |

**Histórico detalhado anterior à compactação:** [snapshot imutável da `main` pré-P3.1](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/6f35f86b1d672949d9921cb948463000e02aacdd/docs/project/current-state.md); decisões e provas continuam em `docs/discovery/`, commits e PRs. Este índice é **navegação histórica**, não substitui relatórios nem restaura estados antigos como vigentes.

## Invariantes, pendências e próximo gate

**Preservar:** QlikView 12; `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`; Star/constelação com **três fatos e oito dimensões**; ordem do Boundary 7, papéis RES/SERV, `IDENT=5` fora de internações novas; leitos e população semi-aditivos no tempo. Nenhuma mudança em QVD/QVW/QVS, modelo acadêmico, associação cross-fact ou Link Key por P3.1.

**Fronteiras abertas:** `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `ZERO_REAL_COMPROVADO=NOT_PROVEN`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Escopo aprovado dos 14 visuais: [D1–D3](../discovery/sad-analytical-scope-acceptance-01-2026-10-27.md); não equivale a implantação.

**Próxima decisão:** revisar o **PR #190 Draft** e autorizar ou não seu merge em ato separado. **Próximo gate candidato, não iniciado:** P3.2 — **RES=SERV versus RES≠SERV por ano**, sobre E1, com `SUM(qtd_internacao)` e sem interpretar códigos distintos como deslocamento físico comprovado. Exige bootstrap/branch/critério próprios, reuso dos controles E1 e nenhuma repetição automática de P3.1/P1/P2. **STOP do P3.1 permanece cumprido.**
