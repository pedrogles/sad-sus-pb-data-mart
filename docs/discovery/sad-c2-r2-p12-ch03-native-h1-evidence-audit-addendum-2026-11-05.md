# SAD — Adendo de auditoria das evidências CH03/H1 — 05/11/2026

**Gate:** `SAD-C2-R2-P12-CH03-NATIVE-H1-01`  
**PR de referência:** [#222](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/222) (Draft, sem merge).  
**Base:** `main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83`; branch de execução `test/sad-c2-r2-p12-ch03-native-h1-20261105@12e91e1675e25ff04510cd8eb1b1b2f79f316d6b`.  
**Natureza:** auditoria documental *posterior ao Verify*, exclusivamente sobre evidências já existentes. Não reabre testes, não altera QVW/QVD, não faz reload/COM/GUI, não substitui o [closeout histórico](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/222#issuecomment-6663875789), não concede aceite de produção.
**Autoridade:** `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → Boundary 7 → V3 D2-R2 → runbook do próprio PR #222. A semântica V3 exige validação do contexto real após seleções nativas, por indicador; não homologa C2/P5 pela prova de uma única visualização.

## 1. Evidência examinada e nível de confiança

1. **Saída PowerShell reportada pelo operador na conversa:** depois de uma primeira tentativa rejeitada em `BLOCKED_CLOSE_QLIKVIEW_FIRST` (`exit=1`), o Verify executado com QlikView fechado retornou `exit=0`. Isso é evidência local **reportada**, não acesso independente ao sistema Windows. O comando que encontrou o QlikView aberto não concluiu o Verify, e não é uma segunda rodada funcional.
2. **Capturas QlikView enviadas durante a rodada:** contexto efetivo `PERIODO_ANO=2019`, `PERIODO_COMPETENCIA=201901`, `SERV_COD_DATASUS_6` sem seleção; proposta `vSAD_POC_Mode=EVOLUCAO` e `vSAD_POC_Year=2019` após ajuste de modo **sem novo despacho BU16**. `CH03` não mostra série anual indevida; novo Text Object mostra motivo específico: **“Indisponível nesta evolução guiada — existe seleção mensal aplicada.”**
3. **Pacote de imagens recuperadas do chat:** o ZIP `SAD_C2_CH03_H1_chat_evidence_2026-11-05.zip` foi aberto nesta revisão; teste CRC interno passou; seis PNGs nomeados tiveram SHA-256 conferido contra `manifest_chat_capture_sha256.csv`. Os PNGs foram recuperados **após** a captura, não produzidos originalmente no `EVIDENCE_DIR` por executor ou pelo operador. O Verify apenas confirma a existência de arquivos com os nomes esperados na pasta local, não examina conteúdo nem carimbo temporal.
4. **`gui_notes.txt` que estava disponível para download na conversa, não a eventual cópia local atualizada:** arquivo pré-Verify com campos ainda `VERIFY_VERDICT=NOT_RUN`, `OBJECT_ID_NOVO=NAO_INFORMADO`, `OUTROS_OBJETOS_EDITADOS=NAO_CONFIRMADO_PELO_OPERADOR`, `SAVE_TEMP=NAO_CONFIRMADO`. O operador informou que extraiu e usou as notas no Windows, mas não enviou o conteúdo **efetivo pós-Verify**. Portanto, não se afirma que a cópia local permaneça idêntica à versão acessível aqui.

### 1.1 Mapa verificável dos PNGs recuperados

| Nome do runbook | SHA-256 do PNG recuperado | O que sustenta |
|---|---|---|
| `initial_state.png` | `0147ea1c8b67ce44aea627fd2b6d83f21044e0c6755d6c1d553dd3ad79f4a3f2` | Seleção inicial de serviço 250750 |
| `h1_real_state.png` | `874fc02c197074f2c7763936bd6d922ad686049ace23e3ce9d3b11843c78232a` | Proposta EVOLUCAO/2019 e seleção real 2019/201901 sem SERV |
| `ch03_before.png` | `3ebc146f4b7232d3b1d3abf337533a10a105bae96d092c787a93dddc792589dd` | Mensagem genérica do CH03 antes da hipótese |
| `ch03_diagnostic_expression.png` | `60302a517445c929116a344b8de525f7b8346415a0ec330c19b1f8bf698e4c9a` | Expressão inserida e sinalização "Expressão OK" |
| `ch03_after.png` | `0b267f5d17ef78b4966c354baecc023bf12e56ff153dce7c89c2534222f7377e` | Mensagem específica no Text Object |
| `transient_objects_removed.png` | `13c4e75f32e3f0961af681640947e0a2a230d93d1f7116be223530063428ce65` | Tela final sem List Boxes transitórias aparentes; não prova auditoria de objetos |

**Limite:** SHA vincula o conteúdo ao pacote recuperado nesta revisão, não demonstra que esses bytes foram conferidos na pasta Windows pelo Verify nem que a coleta foi contemporânea ao Save. Os screenshots não são versionados neste repositório.

## 2. Verify local reportado: campos literais

```text
GATE=SAD-C2-R2-P12-CH03-NATIVE-H1-01
GIT_HEAD=12e91e1675e25ff04510cd8eb1b1b2f79f316d6b
RUNNER_SHA256=05666A73A98162910A98F7FEDEB65048D5C371E7C9C12F20DE50BCEF6EE0607B
SOURCE_SHA256=E38C41B3F9CEECC3E4964CB91E5FE8C17FD608FA32CB5612DC2907E82348296E
QV_PRODUCT_VERSION=12.0.20000.0
QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0
PROTECTED_25_UNCHANGED=True
SOURCE_UNCHANGED=True
COPY_CHANGED_FROM_SOURCE=True
COPY_SHA256=C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D
GUI_EVIDENCE_MISSING=
VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI
VERIFY_EXIT_CODE=0
```

RunId reportado: `SAD_C2_P12_CH03_H1_c70f6c392ca44f53900a92c0cc601073`. O `gui_notes.txt` disponível nesta conversa contém esse RunId, mas ainda não fornece o ID físico do novo objeto nem uma descrição auditável de diff de objetos.

## 3. Matriz de requisitos do gate

| Critério | Classificação | Fundamento/limite |
|---|---|---|
| Seleção real e proposta diferentes, porém rastreadas | `PASS_VISUAL_RESTRICTED` | Capturas mostram 2019/201901 aplicado e EVOLUCAO/2019 proposto |
| CH03 sem evolução inválida como válida | `PASS_VISUAL_RESTRICTED` | Gráfico mostra condição não satisfeita |
| Motivo específico legível próximo do CH03 | `PASS_VISUAL_RESTRICTED` | Text Object exibe indisponibilidade pela seleção mensal |
| Fonte e 25 protegidos inalterados | `PASS_LOCAL_REPORTED` | Verify reporta hashes íntegros, não auditoria independente |
| QVW TEMP diferente da origem | `PASS_HASH_DIFFERENCE_ONLY` | Novo SHA identificado, **não** prova quais objetos mudaram |
| PNGs listados no diretório de evidências | `PASS_FILE_PRESENCE_LOCAL_REPORTED` | `GUI_EVIDENCE_MISSING=` vazio; conteúdo/timing não auditados pelo runner |
| Object ID **novo e único** | `NOT_EVIDENCED` | A captura de propriedades não identifica ID exclusivo do objeto novo |
| Apenas um Text Object novo; CH03 e demais objetos intactos | `NOT_EVIDENCED` | Sem diff de Object IDs/expressões da QVW original versus TEMP |
| No máximo um Save na TEMP | `NOT_EVIDENCED_STRICT` | Hash final prova QVW modificada, não conta operações de Save |
| Persistência contemporânea original dos PNGs | `NOT_DEMONSTRATED` | Recuperação posterior do chat explicitamente documentada |

## 4. Veredito e limite de promoção

- `CH03_H1_VISUAL=PASS_VISUAL_RESTRICTED_CHAT_EVIDENCE`.
- `PROTECTED_25_HASH_INTEGRITY=PASS_LOCAL_REPORTED`.
- `EVIDENCE_BUNDLE_CRC_AND_NAMED_HASHES=PASS_OFFLINE_INSPECTION` (somente pacote recuperado do chat).
- **`GATE_STRICT_ACCEPTANCE=INCONCLUSIVE_OBJECT_SCOPE_AND_EVIDENCE_PROVENANCE`**.

Esse INCONCLUSIVE **não** significa que a expressão falhou: a hipótese visual mostrou a mensagem correta no cenário delimitado. Significa que os requisitos de alteração única/ID, Save e rastreabilidade não estão suficientemente provados pelas evidências acessíveis. Não reclassificar como PASS estrito com base apenas no Verify ou no conteúdo de `gui_notes.txt` gerado antes do Verify.

### Encerramento / handoff

**STOP mantido:** não reexecutar CH03/H1, P1.1, CH02, BU16 ou Verify; não modificar QVW/QVD originais, não alterar manifestos históricos, não fazer merge. Caso apareça o `gui_notes.txt` **pós-Verify efetivamente salvo** e uma prova **já existente** do ID/escopo de objetos, pode-se avaliar em nova revisão documental read-only, preservando o histórico do gate e sem prometer promoção automática do veredito.

`C2_GUIDED_R2=NOT_APPROVED_GLOBAL`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `C3/C4=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
