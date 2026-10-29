# Current State — SAD Data Mart SUS PB

## Estado operacional vigente — 29/10/2026 | P3.1 numérico concluído em branch local

**FATO GIT VERIFICADO:** main remota em `6f35f86b1d672949d9921cb948463000e02aacdd`, com PR #189 integrado. P2.5 permanece PASS numérico restrito, conforme [closeout P2.5](../discovery/sad-p25-lt-cnes-type-code-201912-readonly-closeout-2026-10-29.md). A referência local main estava atrasada; a baseline deste gate foi origin/main conferida por fetch e GitHub.

**Gate P3.1:** `SAD-P31-SIH-RES-SERV-MATRIX-2018-READONLY-01`, **PASS_RESTRICTED em execução local Python**, somente na branch `test/sad-p31-sih-res-serv-matrix-2018-readonly-01`. Matriz integral dos pares observados RES→SERV de 2018 reconciliada com E1 pinado; nenhum dado original alterado. Validador commitado antes da execução, auditoria, CSV, log, hashes e negativo preservados no [relatório P3.1](../discovery/sad-p31-res-serv-matrix-2018-readonly-2026-10-29.md). Não equivale a validação visual, QlikView ou aprovação de produção.

**Estado de entrega:** `GATE_PASS=True`, `PR_MERGED=False`, `PRODUCTION_APPROVED=False`. Push e criação do PR Draft aguardam confirmação específica do responsável; não há bloqueio técnico de P3.1. O histórico e os detalhes de execução permanecem em Discovery/Git.

**Próximo candidato:** P3.2 em gate próprio, não executado. STOP P3.1 cumprido. Não iniciar P3.2/P3.3/P3.4, QlikView/COM ou Fase IX automaticamente.

**Invariantes e impedimentos independentes:** QlikView 12, BASE→EXTRACAO→QVD→TRANSFORMACAO→QVD→PAINEL, Star/constelação, três fatos/oito dimensões e ordem Boundary 7 preservados. Nenhum QVS/QVD/QVW, modelagem acadêmica, cross-fact ou Link Key alterado. `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `ZERO_REAL_COMPROVADO=NOT_PROVEN`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `VISUAL_ACCEPTED_GLOBAL=False`, `PRODUCTION_APPROVED=False`.
