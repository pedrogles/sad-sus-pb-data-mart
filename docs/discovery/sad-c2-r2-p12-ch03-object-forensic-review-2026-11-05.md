# SAD — Revisão independente do inventário QVW CH03/H1 — 05/11/2026

**Objetivo:** auditar o artefato `OBJECT_AUDIT_4ff6ccf267bd43bcb55a86649a1efb40.zip` da inspeção local `SAD-C2-R2-P12-CH03-OBJECT-FORENSIC-READONLY-01`, **sem executar novamente QlikView/Verify**.
**Escopo:** complemento documental do [PR #222](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/222), sem alteração de semântica, de QVD/QVW canônicos ou da `main`.
**Runner local reportado:** `57114032fc1284e7b98415aa4539d0fc69e63236`; `AUDIT_EXIT_CODE=0`; resultados de preservação `PROTECTED_25_UNCHANGED=True` e `ORIGINAL_AND_AUDIT_COPIES_UNCHANGED=True`.
**ZIP inspecionado nesta sessão:** SHA-256 `A0B624FF7599C9074B7BC7EE32297DFB4453A892C49F684731B4599862DA49FD`; **CRC OK**; contém `source_objects.csv`, `target_objects.csv`, `object_audit_report.json`, `source_layout.xml` e `target_layout.xml`. SHAs declarados dos XMLs coincidem com o conteúdo do ZIP.

## Achados efetivamente conferidos

1. **Objetos:** origem 37, destino 38; **um objeto adicionado**, `Document\TX17` (tipo COM 6, Text Object), em folha de índice 2 (`SH03` no XML). Nenhum objeto removido.
2. **Texto de TX17:** expressão `=If(...)` conferida no relatório de objetos, usando modo proposto `EVOLUCAO`, ano selecionado compatível e seleção de `PERIODO_COMPETENCIA>0` para apresentar `Indisponível nesta evolução guiada — existe seleção mensal aplicada.` — mesma hipótese visual do closeout.
3. **Propriedades de objetos existentes:** comparados estruturalmente, por Object ID e árvore XML normalizada (ignorando apenas indentação/whitespace interelemento). **37 de 37 permanecem idênticos no `DocInternals/ObjectPool`**, inclusive `CH02`, `CH03`, todos os cartões `TX10`–`TX13`, botões e Text Objects existentes. `VariableProperties` e `FieldProperties` também idênticos. Zero diferenças nas propriedades intrínsecas anteriores.
4. **Geometria do layout:** após comparar `FrameParentDef` por Object ID, removendo apenas o campo operacional `InternalCtlNo`, **nenhum frame preexistente mudou** de posição, tamanho, ZedLevel ou restante do conteúdo. O `InternalCtlNo` foi renumerado para **17 frames** (16 na folha guiada `SH02`, 1 para `CH02` em `SH03`).
5. **Diferença relevante que não deve ser ocultada:** `LegacyObjectZOrder` da folha guiada `SH02` mudou de ordem, sem adicionar nem excluir objetos; em `SH03`, a lista incorporou `TX17` e foi reordenada. Logo, **não é correto afirmar identidade integral dos metadados de apresentação**, embora IDs, conteúdo e geometria dos objetos históricos estejam preservados. A alteração da ordem de empilhamento pode ter efeito visual em objetos sobrepostos; **não foi feita homologação visual pós-save dessa alteração** nesta auditoria.
6. `DocProperties/FileName` difere pelo nome das cópias de inspeção; `BinaryAlternateStateStates` e `TextualAlternateStateStates` também diferem (estado serializado). Esta análise **não infere** significado semântico adicional desses blocos nem os apresenta como alteração de dados modelados.

## Correção da interpretação do runner sem reexecução

O `object_audit_report.json` traz `ch03PresentInTarget=0` e `INCONCLUSIVE_OR_DRIFT_OBJECT_INVENTORY` apesar de listar `Document\CH03` nos dois CSVs. O runner compara `ObjectID -eq 'CH03'`, enquanto a API retornou `Document\CH03`. Isso é **falso negativo da condição de presença**, não evidência de ausência de CH03. Não se precisa nem se deve reexecutar o runner para corrigir retroativamente o resultado literal do log; preservar a saída como foi gerada.

## Vereditos por nível

| Nível | Veredito | Base |
|---|---|---|
| ZIP/CRC/manifesto de layout | `PASS_OFFLINE_INDEPENDENT_REVIEW` | Conteúdo do ZIP e hashes dos XMLs inspecionados |
| Inventário e propriedades intrínsecas | `PASS_RESTRICTED_OBJECT_POOL_37_UNCHANGED_ONE_TX17_ADDED` | Diff por ID e árvore XML normalizada |
| Geometria dos frames preexistentes | `PASS_RESTRICTED_GEOMETRY` | Diff por ID ignorando só `InternalCtlNo` |
| Metadados de empilhamento | `CHANGED_ZORDER_NEEDS_VISUAL_SCOPE_REVIEW` | `SH02` reordenada; `SH03` incorpora TX17 e reordena |
| Preservação dos 25 protegidos / originais | `PASS_LOCAL_REPORTED` | stdout local; neste ambiente não foram lidos os binários QVW |
| GUI funcional de H1 | `PASS_VISUAL_RESTRICTED_CHAT_EVIDENCE` | Capturas da rodada já examinadas; proveniência registrada |
| **Aceite estrito do gate** | **`INCONCLUSIVE_PRESENTATION_ZORDER_AND_UNVERIFIED_SAVE_COUNT_EVIDENCE_TIMING`** | O diff de objetos não prova 1 Save, nem captura originalmente persistida no EVIDENCE_DIR, nem ausência de efeito visual da mudança de ordem |

**Importante:** o aceite estrito é **inconclusivo por suficiência documental**, não há erro funcional CH03 nem alteração demonstrada nas propriedades intrínsecas dos objetos históricos. O objeto `TX17` foi identificado inequivocamente. Não interpretar o `INCONCLUSIVE` literal do runner como drift material em CH03.

**Condição de parada:** revisão independente finalizada. Sem novo teste, nova execução COM, GUI, Save, Verify, alteração de QVW/QVD ou merge. Somente evidências **já existentes** de Save único e de apresentação pós-save poderiam sustentar decisão documental posterior, sem promoção automática. `C2_GUIDED_R2=NOT_APPROVED_GLOBAL`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `C3/C4=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.
