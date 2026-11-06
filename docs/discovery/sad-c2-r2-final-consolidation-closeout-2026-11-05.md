# SAD — C2-R2 | Consolidação F1/F2 — closeout documental de execução

**Gate:** `SAD-C2-R2-FINAL-CONSOLIDATION-01`
**Data da execução reportada:** 05/11/2026 (horário local do operador)
**Estado:** `EXECUTION_COMPLETE / PHYSICAL_INTEGRITY_PASS / VISUAL_PASS_RESTRICTED / FINAL_ACCEPTANCE_INCONCLUSIVE`
**Natureza:** closeout baseado nos logs PowerShell transcritos pelo operador e nas capturas enviadas na conversa. Não é auditoria local independente nem homologação de produção. Será versionado apenas na branch de teste, não na `main`, até merge autorizado.

## 1. Identificação da execução

| Campo | Evidência |
|---|---|
| Repositório | `pedrogles/sad-sus-pb-data-mart` |
| Baseline `main` | `0549e1dba71aaa8bbab9d6755aecb8465f8bea83` |
| Branch local reportada | `test/sad-c2-r2-final-consolidation-20261105` |
| Commit do runner executado | `98f063abb68f3935b51349f979da009a441ce43f` |
| Runner | `tools/Invoke-SadC2R2FinalConsolidation01.ps1` |
| SHA-256 do runner | `119CF55F91CB03413EA0B46423F666F3865633C680D80799FD0A263438BAEBA2` |
| QlikView | `12.0.20000.0` |
| Run ID | `SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321` |
| SHA-256 da origem #222 | `C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D` |
| SHA-256 da TEMP após Save | `6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58` |
| Verify local reportado | `VERIFY_EXIT_CODE=0` |
| Veredito literal do runner | `PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI` |

**QVW TEMP (não versionar):**

`C:\Users\pedro\Documents\SAD_C2_FINAL_RUNTIME_20261105\SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321\SAD_C2_R2_FINAL_CONSOLIDATION_TEMP.qvw`

**Evidências (não versionar os PNGs/QVWs):**

`C:\Users\pedro\Documents\SAD_C2_FINAL_EVIDENCE_20261105\SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321`

Arquivos de autoridade local: `c2_r2_final_prepare.json`, `c2_r2_final_verify.json`, `gui_notes.txt`, `recovered_visual_manifest_final.json`, `evidence_reconciliation_log.json`, `evidence_manifest_v2.json`, 10 PNGs por papel e arquivo de versões anteriores. Não foram inspecionados diretamente neste ambiente: os resultados desses arquivos são derivados do log reportado e dos pacotes preparados/enviados na conversa.

## 2. F1 — Mensal real 2019/201901

**Estado real reportado nas capturas:** `PERIODO_ANO=2019` e `PERIODO_COMPETENCIA=201901`, sem seleção de município de serviço. **Proposta guiada:** `EVOLUCAO / 2019`.

- Cartões P1.1 exibem 183.532, 183.311, 188.246 e 555.089.
- `CH02` após alteração de medida exibe a série histórica 2017–2019, sem truncamento visual pelo filtro mensal real.
- `CH03` não exibe série mensal incompatível como válida; o diagnóstico `TX17` exibe “Indisponível nesta evolução guiada — existe seleção mensal aplicada.”.
- Expressão candidata aplicada em `CH02` na TEMP: `=Sum({$<PERIODO_ANO={2017,2018,2019},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)`.

**Veredito:** `F1=PASS_VISUAL_RESTRICTED`. A contagem exata dos 36 pontos e seus valores individualizados **não foram comprovados por exportação tabular independente nesta rodada**.

## 3. F2 — Anual real 2018 sem competência selecionada

**Estado real reportado nas capturas:** `PERIODO_ANO=2018`, nenhuma seleção explícita em `PERIODO_COMPETENCIA`, sem seleção de município de serviço. **Proposta guiada:** `EVOLUCAO / 2018`.

- Cartões históricos preservados; `CH02` mantém o histórico 2017–2019.
- `CH03` exibe competências visíveis de 201801 a 201812, título dinâmico referindo 2018, total anual 183.311.
- `TX17` deixa de apresentar o aviso de mês selecionado quando não há mês explicitamente selecionado.
- Ajustes visuais reportados: título de janela e título visível de `CH03`; texto de diagnóstico de `TX17`. A medida de `CH03` não foi alterada segundo notas do operador.

**Veredito:** `F2=PASS_VISUAL_RESTRICTED`. Os 12 valores mensais **não foram exportados/reconciliados individualmente** nesta execução.

## 4. Reabertura e evidência visual

As capturas enviadas na conversa após instrução de salvar, fechar e reabrir a TEMP mostram:

- `post_save_sh02.png`: interface guiada e contexto real/proposto F1, com geometria aparentemente preservada.
- `post_save_sh03.png`: quatro cartões, `CH02` histórico, `CH03` indisponível e `TX17` com aviso mensal; sem deslocamento evidente dos componentes da folha.

O pacote local foi reportado como reconciliado (`CAPTURES_VERIFIED=8`, `PREVIOUS_VERSIONS_ARCHIVED=3`, `FINAL_FILES_INSTALLED=8`), depois atualizado com 2 PNGs pós-reabertura e `gui_notes.txt` (`EVIDENCE_UPDATE=PASS`). O Verify listou `EVIDENCE_FILES=11`: **10 imagens e 1 arquivo de notas**. As imagens foram recuperadas de anexos ao chat e mantidas com seus hashes/proveniência. A data de cópia/mtime **não prova a data exata de captura nem o número de Saves**.

**Veredito:** `POST_REOPEN=PASS_VISUAL_RESTRICTED`, não auditoria forense de todos os objetos/da ordem de empilhamento.

## 5. Integridade física — Verify

Saída do operador:

```text
PREVERIFY=PASS
TEMP_SHA256=6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58
EVIDENCE_FILES=11
GIT_HEAD=98f063abb68f3935b51349f979da009a441ce43f
RUNNER_SHA256=119CF55F91CB03413EA0B46423F666F3865633C680D80799FD0A263438BAEBA2
SOURCE_SHA256=C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D
QV_PRODUCT_VERSION=12.0.20000.0
PROTECTED_25_UNCHANGED=True
SOURCE_UNCHANGED=True
COPY_CHANGED_FROM_SOURCE=True
COPY_SHA256=6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58
GUI_EVIDENCE_MISSING=
EVIDENCE_INVENTORY_COMPLETE=True
VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI
VERIFY_EXIT_CODE=0
```

**Interpretação:** `PHYSICAL_HASH_INTEGRITY=PASS_LOCAL_REPORTED`. O runner não executou COM, reload, ações GUI automáticas, diff semântico de objetos ou avaliação da qualidade dos screenshots. O hash alterado demonstra que a cópia TEMP difere da origem, **não demonstra que somente os objetos esperados mudaram**.

## 6. Lacunas e limites sem novo escopo automático

| Lacuna | Estado | Implicação |
|---|---|---|
| Contagem exata de um Save | `UNVERIFIED` nas notas disponíveis | Não declarar `SAVE_COUNT=1` como provado |
| Auditoria física dos objetos após consolidação (`37+TX17`, mudanças efetivas CH02/CH03/TX17) | `NOT_RUN` | Não declarar diff restrito com certeza |
| `LegacyObjectZOrder` / geometria pós-Save | Revisão apenas visual em SH02/SH03 | Não homologar apresentação global |
| CH02 36 valores e CH03 12 valores mês a mês | Sem exportação tabular desta rodada | Não declarar reconciliação independente completa |
| Mensagem adicional de indisponibilidade em outro bloco de SH02 | Escopo do indicador desconhecido | Não declarar validação geral D2/P5 |
| Matriz física completa `C2-A/B/C`, rotas nativas e demais indicadores | Fora do recorte F1/F2 | `C2_GUIDED_R2` geral não aprovado |

Nenhuma dessas lacunas autoriza repetir o gate, inventar evidências ou avançar automaticamente a C3/C4.

## 7. Veredito e STOP

- `RUNNER_COMMITTED=YES_LOCAL_REPORTED`
- `PREPARE=PASS_LOCAL_REPORTED`
- `F1=PASS_VISUAL_RESTRICTED`
- `F2=PASS_VISUAL_RESTRICTED`
- `POST_REOPEN=PASS_VISUAL_RESTRICTED`
- `PROTECTED_25_HASH=PASS_LOCAL_REPORTED`
- `SOURCE_HASH=PASS_LOCAL_REPORTED`
- `TEMP_SAVED_BYTES_DIFFER_FROM_SOURCE=TRUE`
- `EVIDENCE_INVENTORY_COMPLETE=TRUE_LOCAL_REPORTED`
- `GATE_EXECUTION=COMPLETE_STOP`
- **`GATE_FINAL_ACCEPTANCE=INCONCLUSIVE`** (suficiência documental/forense pendente, não falha física demonstrada)
- `C2_GUIDED_R2=NOT_APPROVED_GLOBAL`
- `READY_FOR_C3=NO`
- `PHASE_IX=NOT_AUTHORIZED`
- `PRODUCTION_APPROVED=False`

**Próximo gate autorizado pelo responsável em 05/11/2026:** preservar o Verify (não reexecutá-lo), executar uma única auditoria forense read-only das propriedades/objetos da TEMP final (fonte #222 pinada e hash final pinado) com runner novo versionado, depois avaliar metadados exportados e decidir se o aceite C2 ainda requer teste nativo residual. Não alterar `current-state.md`, fazer merge, mudar QVD/QVW canônicos ou iniciar C3/C4 automaticamente.

**Referências:** [PR #220](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/220), [PR #221](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/221), [PR #222](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/222), [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196), `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md` e `docs/discovery/sad-c2-r2-final-consolidation-runbook-2026-11-05.md`.
