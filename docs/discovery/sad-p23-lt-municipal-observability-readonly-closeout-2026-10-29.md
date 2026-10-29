# SAD — P2.3 | Matriz municipal de observabilidade CNES/LT (201701–201912)

**Gate:** `SAD-P23-LT-MUNICIPAL-OBSERVABILITY-READONLY-01`  
**Modo:** READ-ONLY / NUMERIC EVIDENCE REUSE  
**Data:** 29/10/2026  
**Parecer restrito:** `PASS_E4_P23_OBSERVABILITY_RECONCILED_RESTRICTED_REUSE` — **reconciliação documental de evidência numérica preexistente e auditada por código versionado**, não nova execução do E4 ou da exportação R2.  
**Baseline verificada:** `main@0fdd68f2913253e1075ef01f0feb07f74fc03f9c` após merge squash do [PR #186](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/186).

## 1. Contrato delimitado, fontes e execução

**Objetivo único:** confirmar as três classes observacionais de pares município PB × competência nos 36 meses, usando a grade derivada C5.2/C4-F e o LT E4 já reconciliados. Sem avaliar hospitais efetivamente operantes, ocupação, proporção anual de capacidade ou filtro QlikView.

**Fontes:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, [escopo analítico D1–D3](sad-analytical-scope-acceptance-01-2026-10-27.md) (P2.3), [P2.1/E4](sad-p21-lt-monthly-readonly-closeout-2026-10-29.md), [C5.2 crosswalk derivado](phase-3-municipal-crosswalk-materialization-2026-10-08.md), [C4-F readback](phase-8-c4f-vi-p4-export-readback-2026-10-21.md), [A1 R2 closeout](sad-p23-a1-physical-gate-protocol-2026-10-28.md), [Boundary 7](boundary-7-implementation-plan.md).

**Integridade/execução previamente estabelecidas:**
- E4 `lt_cnes_leito_competencia(1).csv`: SHA-256 `BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88`, 35.518 linhas/grãos LT únicos, 36 competências. P2.1 executou `tools/validate_sad_p21_lt_monthly01.py` **versionado antes** em `0a2019a0f11dd1f118ef9b82b57774338d2c362a`, com hash E4 antes/depois. **Não se refez a verificação dos bytes nesta sessão.**
- C5.2: 223 códigos DATASUS6/IBGE7 distintos, referência PB derivada de fontes IBGE e auditoria local, `III-C5.2=PASS_LOCAL_QV_AND_SHA_AUDIT`. Não é crosswalk nacional nem referência autônoma publicada pelo IBGE/MS.
- C4-F: `VI-P4-evidencias.zip` (31.217 bytes, SHA-256 `f79e66584f1b6bcf146861781b318f36820b62e89c335368a3785411f9a4d527`); `municipio_mes_observabilidade.txt` SHA `1cbf654d6fe0cd45e77abb97f1f42f1545a2ca9106eae2cf1a6f3afe42a44796`, 8.028 linhas.
- A1 R2 (mesma linhagem CNES/LT): exportação `P23_A1_R2_export.tsv.txt` SHA-256 `593b8812eaed2df9c3e6ca49f84b8c750a133966af36724963d8de2815636c42`. Auditor pré-existente `tools/audit_sad_p23_a1_c4f_pairwise.py` **commitado antes da execução pelo operador** em `94f7edf272be089701c81f4e6f575714d3696cee`. Relatório original `P23_A1_R2_C4F_pairwise_versioned.json` (3.084 bytes; SHA-256 reportado `240159a22a1aa2f7cf88fc5b097025eb27d8cea63e67939835e97bff4091b98a`), disponibilizado no acervo e **conteúdo lido nesta revisão**. O hash deste JSON foi reportado no closeout R2, **não recalculado aqui**.
- Resultado explícito do JSON: `verdict=PASS_PAIRWISE_EXPORT_C4F_R2_CANDIDATE_ONLY`, `issues=[]`; 8.028 chaves comparadas com zero ausentes/extras/duplicatas, **zero divergências em seis campos** (`MUNICIPIO`, `COMPETENCIA`, `LINHAS_LT`, `QT_SUS_OBSERVADO`, `QT_EXIST_OBSERVADO`, `ESTADO_OBSERVADO`); 0 `monthly_internal_errors`, 0 `annual_internal_errors`, 0 `witness_errors`. Trata-se de confronto de duas exportações da mesma linhagem, não validação independente de universo hospitalar.
- Nenhum script novo foi escrito/executado para este gate: **o exame material necessário dos 8.028 pares foi feito anteriormente pelo auditor já versionado**. Aqui foram conferidos Git, closeouts e conteúdo do JSON de prova, e aplicado apenas fechamento aritmético de seus controles. Não há alegação de novo Python, SHA binário, COM, QlikView ou leitura integral da grade.

## 2. Reconciliação do universo e classes

| Controle | Observado via evidências reconciliadas | Verificação |
|---|---:|---|
| Municípios PB (grade C5.2 derivada) | 223 | Referência aprovada no recorte PB |
| Competências | 36 | 201701 a 201912 |
| Universo município×competência | **8.028** | `223 × 36` |
| `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED` | **3.464** | Linha LT e SUS positivo |
| `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` | **97** | Linha LT e SUS igual a 0 observado |
| `ABSENT_NOT_ZERO_PROVEN` | **4.467** | **Sem linha LT; medidas vazias/NULL, nunca zero imputado** |
| Pares com linha LT | **3.561** | `3.464 + 97` |
| Fechamento de todas as classes | **8.028** | `3.464 + 97 + 4.467` |
| Ausências derivadas da grade | **4.467** | `8.028 − 3.561` |
| Linhas LT em pares com linha | 35.518 | Concorda com E4 P2.1 |
| `SUM(qt_sus)` em todas as competências | 270.076 | **Somente controle de linhas, não estoque temporal** |
| `SUM(qt_exist)` em todas as competências | 337.147 | **Somente controle de linhas, não estoque temporal** |

**Testemunhos reais C4-F/A1 R2, `201701`:** `251740` ausente (medidas NULL); `250460` com LT=1, SUS=0, existentes=40; `250010` com LT=3, SUS=20, existentes=20. Esses casos ilustram as três classes; não validam todas as condições hospitalares.

**Semântica rigorosa:** 4.467 ausências **não são** 4.467 zeros SUS; em ausência de linha, `QT_SUS`, `QT_EXIST` e `LINHAS_LT` não têm valor observado. 97 zeros referem-se exclusivamente a `qt_sus` de pares com linha, sem comprovar zero real/completude. Todos os 8.028 pares mantêm `ZERO_REAL_COMPROVADO=NOT_PROVEN` e `COBERTURA_HOSPITALAR=NOT_VERIFIED`. Quantidades no tempo são semi-aditivas; as somas globais acima servem apenas à reconciliação, nunca à inferência de estoque anual.

## 3. Qualidade da prova, limitações e veredito

**FATO VERIFICADO:** o JSON do auditor versionado já executado descreve pares completos e concordantes 8.028/8.028 entre C4-F e A1 R2, sem divergências de seis campos e com as três classes exatamente reconciliadas. O P2.1 confirmou separadamente os controles agregados no E4 pinado. A grade temporal PB foi previamente documentada em C5.2/C4-F.

**Parecer de suficiência:** `PASS_E4_P23_OBSERVABILITY_RECONCILED_RESTRICTED_REUSE`. O gate P2.3 **numérico/observacional** fica fechado por reuso rastreável, sem novo processamento ou extrapolação de aprovação. O confronto não prova independência de fontes (ambas são derivadas CNES/LT), execução física atual, todo o alcance UX dos painéis, cobertura hospital-only nem zero real. Não se promove `PASS_LOCAL_A1_P23_CANDIDATE_ONLY` da R2 a `VISUAL_ACCEPTED_GLOBAL` ou `PRODUCTION_APPROVED`.

**DECISÕES PENDENTES, preservadas:** `ZERO_REAL_COMPROVADO=NOT_PROVEN`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**STOP:** sem ampliar para P2.4/P2.5, sem recarga ou teste COM, sem alteração de QVD/QVW/QVS, sem novas referências municipais, sem merge automático ou implantação. PR Draft documental apenas, aguardando revisão/autorização de integração.
