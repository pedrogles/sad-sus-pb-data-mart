# SAD — C2-R2 | Closeout do microgate de persistência TX17

**Gate:** `SAD-C2-R2-TX17-PERSISTENCE-01`  
**Data:** 06/11/2026  
**Classificação:** `GATE_EXECUTED_STOP / PHYSICAL_INTEGRITY_PASS_REPORTED / POST_REOPEN_EXPRESSION_PASS_VISUAL_RESTRICTED`  
**Fronteira:** a QVW TEMP foi executada manualmente no Windows/QlikView; o agente não acessou diretamente os binários locais. Evidências primárias desta rodada são stdout PowerShell enviado pelo operador, capturas enviadas ao chat e confirmação expressa do momento da captura pós-reabertura.

## 1. Escopo autorizado e fonte

- PR Draft [#225](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/225), branch `test/sad-c2-r2-tx17-persistence-20261106`; script executado em `GIT_HEAD=19aec90a9bfca95b9ae05fca24c9f11f1913031a`.
- Runner: `tools/Invoke-SadC2R2TX17Persistence01.ps1`; SHA-256 executado `1101DE1AAA9DE9864CB2DB54CB64C20A4B2C47A8BDA58991CA5FD5C74FDD8437`.
- QlikView `12.0.20000.0`, GUI manual; script somente Prepare/Verify, `QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0`.
- **Origem imutável** (cópia consolidada F1/F2): `C:\Users\pedro\Documents\SAD_C2_FINAL_RUNTIME_20261105\SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321\SAD_C2_R2_FINAL_CONSOLIDATION_TEMP.qvw`.
- Origem SHA-256 `6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58`.
- **Nova TEMP auditada:** `C:\Users\pedro\Documents\SAD_C2_TX17_PERSIST_RUNTIME_20261106\SAD_C2_TX17_PERSIST_6c3d1061bc2a4c489f6a6737cb652487\SAD_C2_R2_TX17_PERSISTENCE_TEMP.qvw`.
- Evidência local: `C:\Users\pedro\Documents\SAD_C2_TX17_PERSIST_EVIDENCE_20261106\SAD_C2_TX17_PERSIST_6c3d1061bc2a4c489f6a6737cb652487`.
- O gate testa **somente persistência manual** da expressão contextual de TX17; não repete `Seleções → Limpar`, F1/F2 nem oráculos. O ensaio pós-Limpar do PR #224 fica `PASS_VISUAL_RESTRICTED`, mas foi encerrado `INCONCLUSIVE_NOT_PERSISTED` pela falta de Save demonstrado naquela TEMP.

## 2. Prepare — execução local reportada

O operador executou uma rodada Prepare na branch versionada, com parser PowerShell aprovado, origem por hash e QlikView 12 confirmados.

```text
GATE=SAD-C2-R2-TX17-PERSISTENCE-01
GIT_HEAD=19aec90a9bfca95b9ae05fca24c9f11f1913031a
RUNNER_SHA256=1101DE1AAA9DE9864CB2DB54CB64C20A4B2C47A8BDA58991CA5FD5C74FDD8437
SOURCE_SHA256=6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58
QV_PRODUCT_VERSION=12.0.20000.0
VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI
PREPARE_EXIT_CODE=0
```

## 3. Modificação manual e reabertura

- Na folha SH03, o objeto **TX17** foi confirmado visualmente. A expressão antiga (aviso de seleção mensal e diagnóstico `contexto fora da validação F1/F2`) aparece na captura anterior.
- Uma segunda captura registra a **expressão candidata contextual** `If(...GetSelectedCount(PERIODO_ANO)=0, 'CH03 indisponível: nenhum ano real selecionado.', ...)` com `Expression OK`.
- O responsável confirmou expressamente que a captura da expressão corrigida foi feita **depois de fechar e reabrir a nova QVW TEMP**. Portanto, há evidência visual de expressão persistida, qualificada pela declaração do operador e pela captura correspondente.
- No estado visível pós-reabertura, havia `PERIODO_ANO=2019` e `PERIODO_COMPETENCIA=201901` selecionados, com proposta `EVOLUCAO/2019`; o texto de seleção mensal é adequado a esse contexto. CH03 não exibe série incompatível e CH02/cartões históricos permanecem visíveis. **Não** inferir novo teste de pós-Limpar ou cobertura de outros estados.
- O SHA-256 da cópia após Save foi recalculado pelo operador e **difere** da fonte: `7EF5D85C235F625F0C6F10C94FCC0B3B764888A6948AE6D128A3C00138016005`. Mudança de bytes **não prova isoladamente** exclusividade da modificação em TX17.
- **Ressalva de proveniência:** a captura nomeada `tx17_before_save.png` documenta a **expressão antiga**, não a nova antes do Save. Não classificar a sequência de capturas como cumprimento literal perfeito da exigência de antes/depois. Os arquivos foram organizados com imagens originalmente enviadas na conversa, não com inspeção local do QVW pelo agente.
- Quantidade exata de chamadas Save e ausência de outras alterações intrínsecas: **não auditadas independentemente**.

## 4. Verify único — stdout local reportado em 06/11/2026

```text
GATE=SAD-C2-R2-TX17-PERSISTENCE-01
GIT_HEAD=19aec90a9bfca95b9ae05fca24c9f11f1913031a
RUNNER_SHA256=1101DE1AAA9DE9864CB2DB54CB64C20A4B2C47A8BDA58991CA5FD5C74FDD8437
SOURCE_SHA256=6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58
QV_PRODUCT_VERSION=12.0.20000.0
QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0
PROTECTED_25_UNCHANGED=True
SOURCE_UNCHANGED=True
COPY_CHANGED_FROM_SOURCE=True
COPY_SHA256=7EF5D85C235F625F0C6F10C94FCC0B3B764888A6948AE6D128A3C00138016005
GUI_EVIDENCE_MISSING=
EVIDENCE_INVENTORY_COMPLETE=True
VERDICT=PASS_PROTECTED_AND_PERSISTED_BYTES_ONLY_NOT_TX17_SEMANTIC
VERIFY_EXIT_CODE=0
```

**Interpretação rigorosa:** o runner verifica bytes, 25 artefatos protegidos, QVW fonte, presença/timing dos arquivos e mudança de hash na cópia. `PASS_PROTECTED_AND_PERSISTED_BYTES_ONLY_NOT_TX17_SEMANTIC` **não é auditoria XML do objeto**, comparação de propriedades de CH02/CH03, aceitação automática da GUI nem homologação C2. O conjunto de screenshots e a declaração explícita de reabertura sustentam **somente persistência visual restrita**.

## 5. Veredito, limitações e STOP

| Controle | Estado |
| --- | --- |
| Runner versionado antes do Prepare | `PASS` |
| Prepare local, origem/ambiente | `PASS_LOCAL_REPORTED` |
| QVW TEMP com bytes persistidos (SHA distinto) | `PASS_LOCAL_REPORTED` |
| Fonte e 25 protegidos após Verify | `PASS_LOCAL_REPORTED` |
| Captura pós-reabertura com expressão TX17 corrigida | `PASS_VISUAL_RESTRICTED_OPERATOR_ATTESTED` |
| Captura corrigida pré-Save | `MISSING_AS_SPECIFIED` (captura existente retrata expressão original) |
| Auditoria independente das propriedades intrínsecas somente TX17 | `NOT_PERFORMED` |
| Gate de persistência | **`PASS_RESTRICTED_WITH_EVIDENCE_CAVEAT`** |
| C2 global, C3, C4, Fase IX, produção | **`NOT_APPROVED`** |

**STOP alcançado para este objetivo.** Não executar novamente Prepare, Save, `Limpar`, Verify, F1/F2 ou teste BU16. PR #225 permanece **Draft**, sem merge, e a Issue #196 permanece aberta para cobertura residual de C2. Nenhuma mudança de arquitetura, semântica D2, modelo, QVD/QVW canônico ou `current-state.md` foi autorizada por este resultado. O status `C2_GUIDED_R2=NOT_TESTED` na `main` está defasado frente às provas reportadas, mas deve ser reconciliado em tarefa documental **separada**, não neste microgate.
