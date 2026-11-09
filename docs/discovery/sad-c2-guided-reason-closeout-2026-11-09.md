# Closeout — SAD-C2-GUIDED-PREDISPATCH-REASON-01 (09/11/2026)

**Escopo:** integração de um único texto de indisponibilidade de proposta mensal guiada, `TX18`, em QVW temporária derivada da linhagem #225. **Resultado:** `PASS_RESTRICTED_GUIDED_REASON_UI` (evidência visual fornecida pelo operador) + `PASS_PROTECTED_AND_PERSISTED_BYTES_ONLY_NOT_GUIDED_BEHAVIOR` (saída do runner PowerShell 5.1 fornecida pelo operador). **Não equivale a C2 global, produção, merge ou autorização da Fase IX.**

## Fonte e execução delimitada

- **PR:** #229 Draft. Branch `test/sad-c2-guided-reason-integration-20261109`. **HEAD físico do Prepare e Verify:** `1192879a2bec594c0d5b007e3cd6cb28f9a04845` (deixar inalterado na evidência local). A documentação da branch recebeu commits posteriores ao Prepare; não reexecutar runner ou assumir que o HEAD mais recente reproduziu o gate.
- **Runner:** `tools/Invoke-SadC2GuidedReason01.ps1`. **SHA-256 executado:** `58348A454AC9059B84CCF8C701848CB3D52B6F2AABE82D80657BB1FC665A823D`. QlikView Desktop `12.0.20000.0`.
- **Origem pinada:** `SAD_C2_R2_TX17_PERSISTENCE_TEMP.qvw`, SHA-256 `7EF5D85C235F625F0C6F10C94FCC0B3B764888A6948AE6D128A3C00138016005`.
- **Cópia editada e reaberta:** `C:\Users\pedro\Documents\SAD_C2_GUIDED_REASON_RUNTIME_20261109\SAD_C2_GUIDED_REASON_0a749d61bd474ee39816552a9df328a9\SAD_C2_GUIDED_REASON_TEMP.qvw`. SHA-256 após Save, conforme Verify local reportado: `3B7AF41F8D9A1BA4F750FFC47926C7BEB577C20DB96F8F04D3F9104435821ECA`.
- **Evidências locais:** `C:\Users\pedro\Documents\SAD_C2_GUIDED_REASON_EVIDENCE_20261109\SAD_C2_GUIDED_REASON_0a749d61bd474ee39816552a9df328a9`. O pacote de nove capturas foi importado com hashes conferidos e reportado como `PASS_IMAGE_IMPORT_ONLY_NOT_PERSISTENCE_OR_C2_GLOBAL`. O operador posteriormente gerou `reason_after_reopen.png` e `gui_notes.txt` na mesma pasta.

## Observação visual e política semântica

Em capturas **fornecidas pelo operador**, na QVW TEMP:

- A configuração do `BU16` foi inspecionada, sem alteração do botão: fórmula de habilitação `Expression OK` e uma ação `Selecionar no Campo(PERIODO_COMPETENCIA)`. BU15, CH02, CH03 e TX17 foram vistos nas capturas da mesma linhagem; isso não equivale a reteste de cada função.
- No cenário negativo havia uma seleção real `PERIODO_ANO=2019`, competência real explicitamente **não** selecionada e proposta `vSAD_POC_Mode=MENSAL`, `vSAD_POC_Year=2018`, `vSAD_POC_Month=1`. A interface exibiu o aviso `TX18` (ano proposto diferente do selecionado), com BU16 desabilitado. Nenhum clique de BU16 foi demonstrado; operador afirmou `BU16_CLICKED=False`.
- Após operador informar **um Save na TEMP** e reabertura do mesmo QVW, a captura anexada à conversa `image(20261109-184210).png` mostra `TX18` ainda existente, ID em Propriedades, expressão completa no editor e `Expression OK`. **SHA-256 dessa imagem recebida independentemente no atendimento:** `15AF56EEBCCCF9DC478FDF7F5806435B60EE95454D9237A0434892B7CA37E5A8` (PNG 1907×1068). Esta imagem enviada ao chat é **distinta** do arquivo local `reason_after_reopen.png`: não se verificou igualdade binária entre as duas.
- O arquivo `gui_notes.txt` foi criado no Windows mediante confirmação explícita `CONFIRMO` do operador, declarando `SAVE_COUNT=1`, `TX18_PERSISTED_AFTER_REOPEN=True`, `BU16_CLICKED=False`. A veracidade operacional é **declaração do operador**, complementada por captura. O runner valida presença/tamanho/mtime dos arquivos, mas **não lê ou interpreta** essas declarações nem comprova sozinho uma única operação Save.

## Verify — saída reportada em 09/11/2026

```text
GATE=SAD-C2-GUIDED-PREDISPATCH-REASON-01
GIT_HEAD=1192879a2bec594c0d5b007e3cd6cb28f9a04845
RUNNER_SHA256=58348A454AC9059B84CCF8C701848CB3D52B6F2AABE82D80657BB1FC665A823D
SOURCE_SHA256=7EF5D85C235F625F0C6F10C94FCC0B3B764888A6948AE6D128A3C00138016005
QV_PRODUCT_VERSION=12.0.20000.0
QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0
PROTECTED_25_UNCHANGED=True
SOURCE_UNCHANGED=True
COPY_CHANGED_FROM_SOURCE=True
COPY_SHA256=3B7AF41F8D9A1BA4F750FFC47926C7BEB577C20DB96F8F04D3F9104435821ECA
GUI_EVIDENCE_MISSING=
EVIDENCE_INVENTORY_COMPLETE=True
VERDICT=PASS_PROTECTED_AND_PERSISTED_BYTES_ONLY_NOT_GUIDED_BEHAVIOR
```

**Validação de proveniência:** essa saída veio do PowerShell compartilhado pelo operador. O atendimento **não executou** QlikView, PowerShell Windows, leitura da QVW local nem conferiu os hashes canônicos independentemente. A captura de reabertura foi visualmente inspecionada diretamente a partir da imagem enviada. Nenhum comando de verificação adicional foi executado nesta consolidação.

## Encerramento deste escopo

| Camada | Estado |
| --- | --- |
| `GUIDED_NEGATIVE_REASON_UI` | `PASS_RESTRICTED_OPERATOR_SCREENSHOT` |
| `TX18_SAVE_REOPEN` | `PASS_RESTRICTED_OPERATOR_SCREENSHOT_AND_CONFIRMATION` |
| `PROTECTED_ORIGIN_QVD_QVW` | `PASS_REPORTED_BY_LOCAL_RUNNER` |
| `EVIDENCE_INVENTORY` | `COMPLETE_REPORTED_BY_LOCAL_RUNNER` |
| `C2_GUIDED_R2` | `PARTIALLY_TESTED_NOT_APPROVED_GLOBAL` |
| `C2_MICROTEST_WORKSTREAM` | `FROZEN_NO_NEW_RUNS` |
| `LINK_KEY_CONTRACT` | `NOT_APPROVED` |
| `MEASURES_AND_DENOMINATOR_CONTRACT` | `NOT_APPROVED` |
| `PHASE_IX` | `NOT_AUTHORIZED` |
| `PRODUCTION_APPROVED` | `False` |

**STOP cumprido:** não repetir Prepare/Verify, não reabrir testes nativos, não criar testes adicionais por automatismo. Continuar com o planejamento aprovado da Boundary 7 em escopo futuro explicitamente autorizado. PR #229 permanece Draft; sem merge. Para homologar C2 global ainda seriam necessárias verificações por indicador e rotas nativas conforme o contrato D2-R2/V3; esta execução não as forneceu.
