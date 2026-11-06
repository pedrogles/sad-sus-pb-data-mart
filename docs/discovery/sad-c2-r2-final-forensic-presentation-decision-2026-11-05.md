# SAD — C2-R2 | Proposta de decisão de apresentação após auditoria forense

**Gate documental:** `SAD-C2-R2-FINAL-FORENSIC-PRESENTATION-DECISION-01`
**Data de referência:** 05/11/2026
**Repositório:** `pedrogles/sad-sus-pb-data-mart`
**Baseline `main` conferida:** `0549e1dba71aaa8bbab9d6755aecb8465f8bea83`
**Branch local da prova:** `test/sad-c2-r2-final-consolidation-20261105`, `HEAD=c821e92bb5dd95d97e5b708a251b82b39679f256` **reportado pelo operador; ainda não confirmado no remoto**.
**Estado da decisão:** `RECOMMENDED_RESTRICTED_VISUAL_ACCEPTANCE / OWNER_DECISION_PENDING`. **Este documento não registra autorização ou aceite humano.**

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

## 3. Decisão proposta (não executada)

**Alternativa A — recomendada:** aceitar **exclusivamente** o delta de apresentação no estado visual capturado de SH02/SH03, com as duas diferenças (cores CH03 e empilhamento SH02/SH03) explicitamente registradas; preservar a TEMP auditada. O estado do microgate será `PRESENTATION_DELTA_ACCEPTED_RESTRICTED`, condicionado ao aceite expresso do responsável; os demais limites permanecem `INCONCLUSIVE`/pendentes. **Não significa que as diferenças sejam visualmente irrelevantes em qualquer seleção ou interação.**

**Alternativa B:** não aceitar o delta; abrir uma correção independente em nova TEMP protegida, com escopo apenas de moldura/ordem e evidência específica de regressão. Não sobrescrever a TEMP consolidada, não reexecutar Prepare/Verify antigos e não alterar produção por arrasto.

**Fundamento da recomendação A:** as capturas pós-reabertura disponíveis não revelam perda de legibilidade ou deslocamento grosseiro, a geometria é idêntica por objeto e a diferença funcional está circunscrita a CH02, CH03 e TX17. É um aceite **visual restrito**, não certificação de identidade da serialização.

## 4. Registro de decisão humana — pendente

**Não preencher automaticamente.** Um aceite válido deve fazer referência às duas diferenças materiais, ao escopo e às limitações. Texto sugerido ao responsável:

> Aprovo, apenas para as evidências F1/F2 e pós-reabertura da TEMP de SHA `6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58`, o delta de apresentação registrado: cores da moldura CH03 e reordenação de empilhamento SH02/SH03, sem regressão evidente nas capturas inspecionadas. Reconheço que a contagem de Saves, reconciliação tabular mensal, interações sobrepostas e cobertura nativa integral continuam pendentes. Esta decisão **não aprova C2 global nem autoriza C3/C4, Fase IX, produção ou merge**.

Somente após aceite explícito registrar data, evidência da manifestação e estado `OWNER_RESTRICTED_PRESENTATION_ACCEPTANCE=GRANTED`. Até lá, `OWNER_RESTRICTED_PRESENTATION_ACCEPTANCE=PENDING`.

## 5. Encerramento e próximo trabalho

- **Concluído:** comparação independente ZIP/CSV/XML, inventário de objetos, diagnóstico de Z-order/cores; nenhuma falha evidente nos dois screenshots pós-reabertura.
- **Pendente, sem reexecutar o microgate:** decisão humana sobre o delta de apresentação; após isso, classificar a pendência forense como aceita com restrições ou bloqueada por correção.
- **Fora deste gate:** reconciliação mensal 36/12 contra oráculos; contagem de Saves; validação física pós-seleção nativa por indicador; histórico `current-state.md` que ainda descreve C2 como não testado.
- **STOP:** versionar somente este documento e o relatório independente na branch local de teste. Não editar QVW/QVD, não rodar COM/GUI/Reload/Verify, não abrir nova rodada F1/F2, não fazer merge ou declarar `READY_FOR_C3`.

`FORENSIC_OBJECT_AND_LAYOUT_REVIEW=COMPLETE`
`RESTRICTED_POST_REOPEN_VISUAL_REVIEW=PASS_RESTRICTED`
`OWNER_RESTRICTED_PRESENTATION_ACCEPTANCE=PENDING`
`C2_GUIDED_R2=PARTIALLY_TESTED_NOT_APPROVED_GLOBAL`
`READY_FOR_C3=NO`
`PRODUCTION_APPROVED=False`
