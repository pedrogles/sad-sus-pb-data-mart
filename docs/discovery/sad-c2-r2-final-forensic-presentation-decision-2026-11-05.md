# SAD — C2-R2 | Decisão formal de aceite visual restrito após auditoria forense

**Gate documental:** `SAD-C2-R2-FINAL-FORENSIC-PRESENTATION-DECISION-01`
**Data de referência:** 05/11/2026
**Repositório:** `pedrogles/sad-sus-pb-data-mart`
**Baseline `main` conferida:** `0549e1dba71aaa8bbab9d6755aecb8465f8bea83`
**Branch local da prova:** `test/sad-c2-r2-final-consolidation-20261105`, `HEAD=265d55a0cea84588f2bfddb8b2c27fb71ca83b83` **reportado pelo operador; publicação no remoto ainda não confirmada**.
**Estado da decisão:** `OWNER_RESTRICTED_PRESENTATION_ACCEPTANCE=GRANTED` em 05/11/2026, com confirmação registrada na [Issue #196, comentário 6675608613](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6675608613). **Escopo estritamente visual F1/F2; C2 global não aprovado.**

## 1. Escopo e fontes

Decidir exclusivamente se as diferenças residuais de apresentação da TEMP consolidada podem ser **aceitas para as capturas F1/F2 e pós-reabertura já disponíveis**, sem editar a QVW nem repetir os ensaios concluídos. Não aprova `C2_GUIDED_R2` global, interações nativas não ensaiadas, regra P5/C4, Link Key/C3, dashboards finais ou produção.

- Fonte #222: SHA-256 `C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D`.
- TEMP consolidada: SHA-256 `6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58`.
- ZIP forense local auditado: SHA-256 `3B713B71F6FC214A4BBADD3BF3626ED7026BD320DCD5E88886D3268B7CE5F335`.
- Relatório técnico independente: `docs/discovery/sad-c2-r2-final-forensic-independent-review-2026-11-05.md` (preparado para versionamento com este registro).
- Screenshots pós-reabertura `post_save_sh02.png` (interface guiada) e `post_save_sh03.png` (cartões e gráficos), recuperados da conversa e organizados no `EVIDENCE_DIR`; **não são evidência de todos os estados da UI nem da exata quantidade de Saves**.
- Confirmação Windows reportada: `PROTECTED_25_UNCHANGED=True`, `ORIGINAL_AND_AUDIT_COPIES_UNCHANGED=True`, `AUDIT_EXIT_CODE=0`, 38/38 objetos, sem inclusões/exclusões/tipos alterados.

## 2. Avaliação técnica com limites

| Item | Verificação sustentada | Limitação |
|---|---|---|
| Inventário | 38 objetos antes/depois; 35 propriedades intrínsecas idênticas; deltas apenas em CH02, CH03 e TX17 | Não demonstra automaticamente equivalência de todos os estados calculados |
| Geometria | Posição/tamanho e `ZedLevel` de 38 frames preservados | `LegacyObjectZOrder` não é idêntico |
| Moldura CH03 | `PrimaryCol` RGB (4,108,193) → (232,232,232); `SecondaryCol` RGB (0,0,0) → (200,200,200) | Mudança visual/metadado não demandada pela correção de título; efeito em todos os estados não verificado |
| Empilhamento | SH02: 9 pares com interseção e ordem invertida; SH03: 7 pares; listagem completa no relatório independente | Captura estática não demonstra click-through nem estados de sobreposição alternativos |
| Pós-reabertura | SH02 e SH03 legíveis no contexto real 2019/201901; cartões corretos, CH02 histórico visível, CH03 indisponível e TX17 explicativo | Só esse contexto possui screenshots pós-save; F2 foi fotografado antes do Save |
| Integridade | 25 protegidos e QVW fonte preservados, segundo logs locais; TEMP alterada com SHA final pinado | Contagem de Saves e reconciliação mensal por exportação continuam sem prova independente |

**Achado de escopo distinto:** em SH02 há outro texto de indisponibilidade relativo a contexto temporal. Seu indicador e a lógica completa não foram homologados neste recorte; não converter ausência de regressão visual em PASS de D2/P5 global.

## 3. Decisão formal do responsável — alternativa A aprovada

**Manifestação expressa em 05/11/2026**, preservada integralmente na [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6675608613):

> Aprovo formalmente a alternativa A: aceite visual restrito da consolidação C2-R2 F1/F2, reconhecendo a alteração de cor de CH03 e as 16 inversões de Z-order documentadas, sem aprovar C2 global, C3 ou produção. Prossiga com o registro documental da decisão.

**Decisão executada no plano documental:** alternativa A, `PRESENTATION_DELTA_ACCEPTED_RESTRICTED`. Os estados visuais F1/F2 e as capturas pós-reabertura SH02/SH03 são aceitos **somente como evidência de apresentação restrita** para a TEMP auditada, SHA-256 `6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58`.

O responsável **reconheceu expressamente** a cor modificada da moldura de CH03 e as 16 inversões documentadas de empilhamento (`LegacyObjectZOrder`, 9 pares SH02, 7 pares SH03). Essa aceitação **não** comprova que a mudança é visualmente irrelevante em outros estados, que não há alteração de click-through ou que todos os visuais estão homologados.

## 4. Limitações preservadas e fronteiras de aprovação

- A contagem exata de Saves permanece **não verificada independentemente**; não corrigir retrospectivamente esse item como PASS.
- Os valores mensais individuais das séries CH02 (36 competências) e CH03 (12 competências) **não foram todos reconciliados tabularmente na TEMP consolidada** neste gate; oráculos anteriores continuam evidência restrita reutilizável.
- Operações nativas como limpar, voltar/adiantar, bookmarks, selecionar pelo gráfico e contextos multi-ano/competência parcial **não receberam aceite de cobertura integral por indicador**; aplicar D2-R2/V3 conforme o tipo de indicador e contexto real.
- Não aprova `C2_GUIDED_R2` global, P5/D2 UI global, C3, C4, Link Key, Fase IX, dashboards finais, produção, merge nem alteração de QVW/QVD canônicos.
- O estado correto é `OWNER_RESTRICTED_PRESENTATION_ACCEPTANCE=GRANTED` e `C2_GUIDED_R2=PARTIALLY_TESTED_NOT_APPROVED_GLOBAL`. A Issue #196 permanece aberta para cobertura residual.

## 5. Encerramento e próximo trabalho

- **Concluído:** comparação independente ZIP/CSV/XML, inventário de objetos, diagnóstico de Z-order/cores; nenhuma falha evidente nos dois screenshots pós-reabertura.
- **Decidido:** aceite visual restrito concedido, com reconhecimento expresso do delta de apresentação; a pendência **de decisão visual** do microgate está encerrada. A auditoria forense estrita permanece qualificada pelas limitações de prova, e não reclassificada retroativamente como PASS integral.
- **Fora deste gate:** reconciliação mensal 36/12 contra oráculos; contagem de Saves; validação física pós-seleção nativa por indicador; reconciliação posterior de `current-state.md`, que ainda descreve C2 como não testado.
- **STOP:** versionar a atualização desta decisão na mesma branch de teste, sem alterar outros arquivos. Não editar QVW/QVD, não rodar COM/GUI/Reload/Verify, não abrir nova rodada F1/F2, não fazer merge ou declarar `READY_FOR_C3`.

`FORENSIC_OBJECT_AND_LAYOUT_REVIEW=COMPLETE`
`RESTRICTED_POST_REOPEN_VISUAL_REVIEW=PASS_RESTRICTED`
`PRESENTATION_DELTA_ACCEPTED_RESTRICTED=True`
`OWNER_RESTRICTED_PRESENTATION_ACCEPTANCE=GRANTED`
`C2_GUIDED_R2=PARTIALLY_TESTED_NOT_APPROVED_GLOBAL`
`READY_FOR_C3=NO`
`PRODUCTION_APPROVED=False`
