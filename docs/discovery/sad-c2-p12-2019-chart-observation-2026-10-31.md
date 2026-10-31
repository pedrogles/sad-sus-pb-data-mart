# SAD C2 — observação controlada do gráfico P1.2 sob ano real 2019

**Gate:** `SAD-C2-P12-2019-CHART-OBSERVATION-01`  
**Baseline:** `main@2d205d52ab96eca565e85a9db5cfde14d9d3025c` (PRs #201 e #202 integrados); [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196).  
**Estado de fechamento (31/10/2026):** `CLOSED_BLOCKED_INITIAL_STATE_PERSISTED_AND_CH02_NOT_GUIDED_12_WITH_HASH_PASS_RESTRICTED_LOCAL_REPORTED`; texto de preparação abaixo é histórico e **não deve ser reexecutado**.  
**Agente primário:** operador humano ou Codex Local no Windows com QlikView Desktop 12 e PowerShell 5.1; ChatGPT/GitHub prepara protocolo sem acesso ao Windows/GUI. Usar esforço realmente disponível; não requer Work.  
**Autorização contextual:** o responsável pediu prosseguir com gates delimitados; isso autoriza preparar artefatos em branch e o próximo teste observacional **somente sobre cópia isolada após preflight**. Não concede merge, correção do gráfico, reload, mutação de QVD/QVW canônicos, produção ou outro gate.

## 1. Hipótese e recorte único

**Pergunta a responder:** depois de acionar **uma vez o BU15 já configurado** no novo clone da QVW temporária de #201, com `vSAD_POC_Mode=EVOLUCAO`, `vSAD_POC_Year=2019`, `PERIODO_ANO=2019` explícito e nenhuma competência explicitamente selecionada, o gráfico **existente `CH02`** exibe exatamente `201901..201912` e 12 valores reconciliáveis?

A QVW fonte `SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw` foi **salva antes do clique na sessão #201**, com BU15 candidato, e possui hash reportado após `Verify`: `D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B`. Isso **não garante** disponibilidade/estado atual no disco: validar hash antes. Não abrir/salvar novamente a origem. O teste acontece em **nova cópia TEMP** apenas.

**Risco já comprovado por leitura documental:** `CH02` histórico usa `=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)`, enquanto o contrato guiado é de **12 competências de um único ano**. O efeito físico do modificador sob seleção aplicada ainda é **hipótese**. **Não mudar CH02, expressão, objeto, botão, variáveis, filtros ou carga nesta rodada.** Se continuar 36 meses, evidenciar e STOP; não propor correção operacional no mesmo gate.

**Não repetir:** `-Prepare`/`-Verify` do #201 ou #199, análise 36/36 do P1.2, cálculos AE01/P1–P3, C2-J/K, P2.3 R1/R2, reinicialização de filtros para fabricar estado ou testes globais D2/P5.

## 2. Por que há runner específico

O [runner #201](../../tools/Invoke-SadC2GuidedDynamicDispatchPoc01.ps1) foi validado apenas na branch/manifesto/entrada **anteriores** e copia a QVW P1.1/P1.2 **sem BU15**; seu `-Verify` não pode ser reutilizado como se o cenário fosse idêntico. O [runner histórico #199](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/test/sad-c2-p12-evolucao-2019-20261030/tools/Invoke-SadC2P12Evolution2019Copy01.ps1) trabalha igualmente com origem antiga e encerrou com `GUI_2019=BLOCKED`; não reexecutar.

O arquivo **derivado** `tools/Invoke-SadC2P12ChartObservation01.ps1` reutiliza as proteções do #201 com **nova identidade de fonte pinada, branch e diretórios distintos**. O runner não usa COM/reload, não inicia QlikView nem manipula o gráfico. `-Verify` **exige que a NOVA TEMP permaneça byte a byte idêntica** à origem, pois a GUI é exclusivamente observacional (sem salvar). A origem e 25 protegidos (22 QVD, três QVW) também devem preservar hashes. Ainda não há parser real Windows para este novo runner.

## 3. Pré-requisitos e STOP antes do Prepare

1. No Windows, confirmar a branch `test/sad-c2-p12-2019-chart-observation-20261031`, HEAD remoto aprovado e *worktree* limpa. Não usar `reset --hard`, `git clean`, checkout forçado ou `stash` sem decisão.
2. QlikView totalmente **fechado**; `Qv.exe` versão 12; 10 QVDs de extração, 12 QVDs de transformação e três QVWs canônicos presentes.
3. Origem fora Git, caminho previamente documentado do gate #201:
   `$env:USERPROFILE\Documents\SAD_C2_DYNAMIC_RUNTIME\SAD_C2_DYNAMIC_e474426fc30c473c83019c4cdfaad080\SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw`.
   Exigir **SHA256 exato `D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B`**. Uma divergência é `HARD_STOP_SOURCE_HASH_DRIFT`; não restaurar nem editar para forçar compatibilidade.
4. Runtime e evidências NOVOS, separados e fora do Git: `Documents\SAD_C2_P12_OBSERVE_RUNTIME` e `Documents\SAD_C2_P12_OBSERVE_EVIDENCIAS`. Não reutilizar manifesto ou diretório de #201 ou #199.
5. Parser PS5.1 do novo runner sem erro. Se qualquer condição falhar, **STOP**; não iniciar QlikView ou criar nova cópia.

### Preflight local somente leitura — PowerShell 5.1

Executar a partir da raiz do repo, em checkout limpo na branch correta:

~~~powershell
$ErrorActionPreference = 'Stop'
$repo=(Get-Location).Path
$expectedBranch='test/sad-c2-p12-2019-chart-observation-20261031'
$branch=(git branch --show-current).Trim()
$head=(git rev-parse HEAD).Trim()
$dirty=@(git status --porcelain --untracked-files=all)
if ($branch -cne $expectedBranch -or $dirty.Count -gt 0) {throw 'BLOCKED_GIT_BRANCH_OR_WORKTREE'}
$source=Join-Path $env:USERPROFILE 'Documents\SAD_C2_DYNAMIC_RUNTIME\SAD_C2_DYNAMIC_e474426fc30c473c83019c4cdfaad080\SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw'
$sourcePin='D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_NOT_FOUND'}
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if ($sourceHash -cne $sourcePin) {throw 'HARD_STOP_SOURCE_HASH_DRIFT'}
$qlik='C:\Program Files\QlikView\Qv.exe'
$runner=Join-Path $repo 'tools\Invoke-SadC2P12ChartObservation01.ps1'
if (-not (Test-Path -LiteralPath $qlik -PathType Leaf)) {throw 'BLOCKED_QLIK_EXE'}
if (@(Get-Process -Name qv,qlikview -ErrorAction SilentlyContinue).Count -gt 0) {throw 'BLOCKED_CLOSE_QLIKVIEW'}
$tokens=$null; $errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
if ($errors.Count -ne 0) {$errors; throw 'BLOCKED_PS51_PARSER'}
Write-Host "PREFLIGHT=PASS_READONLY_NOT_PREPARE HEAD=$head SOURCE_SHA256=$sourceHash"
~~~

Não usar `PREFLIGHT=PASS` para alegar que a cópia/GUI foi testada.

## 4. Prepare único (após preflight)

~~~powershell
$runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_OBSERVE_RUNTIME'
$evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_OBSERVE_EVIDENCIAS'
New-Item -ItemType Directory -Force -Path $runtime,$evidence | Out-Null

& powershell.exe -NoProfile -File $runner `
  -Root $repo -SourceQvw $source -QlikExe $qlik `
  -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_PREPARE_STOP_NO_RETRY'}
~~~

Conservar **literalmente** `RUNTIME_COPY` e `EVIDENCE_DIR` da saída. A chamada deve terminar `PASS_COPY_PREPARED_ONLY_NO_GUI`. **Nenhum caminho de cópia é antecipadamente conhecido** (GUID é gerado pelo runner). O novo `p12_observe_prepare.json` registra `GitHead`, `RunnerSha256`, `SourceSha256`, `ProtectedBefore` e a cópia.

## 5. GUI QlikView 12 — uma observação, sem salvar

1. Abrir **somente** a NOVA `RUNTIME_COPY`. Conferir nome e folhas `POC - Interface Guiada` e `POC P1.1-P1.2 - Internações`. Não clicar em limpar seleções. Registrar quadro anterior `gui_before.png`. Se surgir restauração/conversão ou seleção temporal residual, STOP.
2. Verificar `vSAD_POC_Mode=EVOLUCAO`, `vSAD_POC_Year=2019`; `GetSelectedCount(PERIODO_ANO)=0`, `GetSelectedCount(PERIODO_COMPETENCIA)=0`; filtros não temporais, especialmente serviço, sem contradição. Se diferente, STOP sem alterar o modo/ano.
3. Clicar **uma vez** no `BU15` já existente, **sem recriar nem editar o botão**. Capturar `gui_selected_2019.png`. É uma interação instrumental para inspecionar o gráfico, **não** revalidação do gate de despacho #201. Se `ANO REAL` diferente de `2019 / Qtd 1` ou competência explicitamente selecionada, STOP e registrar `BLOCKED_TIME_CONTEXT`.
4. Na aba `POC P1.1-P1.2 - Internações`, observar o **CH02 existente**, sem abrir propriedades/editar expressão; capturar `p12_chart_observed.png`. Registrar número e domínio de competências reais visíveis. Se **36 meses**, STOP `BLOCKED_HISTORICAL_CH02_NOT_GUIDED_12`. Se **12 meses 201901..201912**, exportar somente a tabela subjacente desse gráfico para `p12_2019_export.tsv` no `EVIDENCE_DIR`, sem modificar objeto ou dados. Se não for possível identificar as 12 competências, `INCONCLUSIVE_CHART_CANNOT_BE_READ`.
5. O oráculo existente é o TSV histórico com SHA-256 `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`. **Não presumir localização**. Se export houver e o oráculo estiver acessível e verificado, reconciliar exatamente as 12 linhas `201901..201912`, sem recálculo: soma anual **188246**, testemunha `201905=17292`; comparação ponto a ponto obrigatória. Se indisponível, `INCONCLUSIVE_ORACLE_UNAVAILABLE`, não PASS. Não publicar CSVs/TSVs no Git.
6. Registrar em `gui_notes.txt` em `EVIDENCE_DIR`: data/hora, HEAD, operador/ambiente, novo RunId, estado antes/depois, serviço e demais filtros, quantidade de competências visíveis, existência de export, caminho/hash do oráculo, observação `PASS/BLOCKED/INCONCLUSIVE`, problema e prints realmente presentes. **Fechar QlikView SEM SALVAR** a nova cópia. Se o Qlik solicitar salvamento, escolher Não.

Se a GUI bloquear, **não** criar novo botão/condição, alterar CH02 ou repetir clique; registrar e executar apenas o Verify da integridade.

## 6. Verify único (QlikView fechado)

No mesmo checkout e commit do Prepare, e com `$runDir` preenchido pelo `EVIDENCE_DIR` **da saída real**:

~~~powershell
$runDir='<COLE_O_EVIDENCE_DIR_REPORTADO_PELO_RUNNER>'
& powershell.exe -NoProfile -File $runner `
  -Root $repo -SourceQvw $source -QlikExe $qlik `
  -RuntimeRoot $runtime -EvidenceRoot $evidence `
  -Verify -RunDir $runDir
$exit=$LASTEXITCODE
Write-Host "VERIFY_EXIT_CODE=$exit"
if ($exit -ne 0) {throw 'BLOCKED_VERIFY_STOP_NO_RETRY'}
~~~

Critérios de integridade do runner: `PROTECTED_25_UNCHANGED=True`, `SOURCE_UNCHANGED=True`, `COPY_UNCHANGED=True`, `GUI_EVIDENCE_MISSING=`, `VERDICT=PASS_PROTECTED_COPY_INTEGRITY_ONLY_NOT_GUI` e exit 0. O runner **não inspeciona as imagens nem prova valores do gráfico**. Mesmo com integridade PASS, a prova funcional pode ser `BLOCKED` ou `INCONCLUSIVE`.

## 7. Aceite / condição de parada

| Resultado | Condição |
| --- | --- |
| `PASS_VISUAL_RESTRICTED_P12_2019_12_OF_12` | uma seleção de ano 2019 explícita, competência Qtd 0, filtros preservados, CH02 exibe exatamente 12 competências ordenadas 201901–201912, export 12/12 reconciliado com TSV pinado, fonte+25+TEMP íntegros, capturas e notas presentes |
| `BLOCKED_HISTORICAL_CH02_NOT_GUIDED_12` | CH02 continua exibindo 36 meses após ano real aplicado; documentar e decidir **novo gate de objeto guiado**. |
| `BLOCKED_TIME_CONTEXT` | seleção aplicada difere da proposta / competência residual / filtro incompatível. |
| `INCONCLUSIVE` | falta de export, oráculo, imagens, propriedades de domínio ou reconciliação. |
| `HARD_STOP` | hash da fonte/protegidos/cópia divergente, checkout errado ou necessidade de mudança semântica. |

**STOP:** exatamente uma cópia, uma interação instrumental no BU15, uma inspeção CH02, uma exportação somente se aplicável e um Verify. Sem repetição automática nem correção. Evidências em diretório persistente **fora do Git**. Não fazer merge nem excluir branch automaticamente. Retornar à [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196) com HEAD/SHA, status, print de seleção e gráfico, export/oráculo quando disponíveis e `p12_observe_verify.json`. A revisão documental classifica o gate em seguida.

**Estados preservados:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Somente após fechar este objetivo um novo gate para C2 guiado será proposto, conforme C2→C3→C4 do Boundary 7.


---

## 8. Closeout da única tentativa Windows — 31/10/2026

**Veredito delimitado:** `CLOSED_BLOCKED_INITIAL_STATE_PERSISTED_AND_CH02_NOT_GUIDED_12_WITH_HASH_PASS_RESTRICTED_LOCAL_REPORTED`. A observação física foi realizada e interrompida sem atingir o PASS visual de 12 competências; a verificação de integridade foi posteriormente concluída. **O teste de despacho BU15 não foi executado novamente neste gate.**

### Identidade e proveniência

- **Branch/HEAD efetivamente executado no Windows (preflight, Prepare, Verify):** `test/sad-c2-p12-2019-chart-observation-20261031@d4b4f0fb68e52869051978273136321f5046ea2b`.
- **Runner SHA-256 reportado localmente:** `0D3C91647ACD5C4364EC47B68D483C04E2E4F270A5E37751CCB1840AA96F049C`, QlikView `12.0.20000.0`.
- **Fonte:** `SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw`, SHA-256 `D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B`.
- **RunId exclusivo:** `SAD_C2_P12_OBSERVE_89c60aac5d9b4986a01c01e23fb2c13e`. Evidências e manifestos externos ao Git: `C:\Users\pedro\Documents\SAD_C2_P12_OBSERVE_EVIDENCIAS\SAD_C2_P12_OBSERVE_89c60aac5d9b4986a01c01e23fb2c13e`.
- **Origem da prova:** capturas de tela e transcripts completos de PowerShell fornecidos pelo operador em conversa. **Não recebidos/abertos independentemente os binários QVW/QVD ou o arquivo `p12_observe_verify.json`**. O transcript comprova a saída declarada pelo runner, não uma auditoria direta dos bytes pelo agente GitHub.

### Observações na interface

1. **Estado inicial divergente:** ao abrir a NOVA QVW TEMP preparada (sem clicar nenhum botão nesta tentativa), o diagnóstico já indicava `Modo=EVOLUCAO`, `Ano proposto=2019`, `ANO REAL=2019 / Qtd 1`, `COMPETENCIA REAL=SEM SELECAO / Qtd 0`, `SERVICO=SEM SELECAO / Qtd 0`. O operador confirmou que **não clicou no BU15 na nova cópia**; a seleção real persistia do documento-fonte salvo na tentativa anterior. Portanto, os passos `gui_before.png` (sem seleção) e `gui_selected_2019.png` (nova ação) não ocorreram. Não preencher retroativamente.
2. **Achado do gráfico:** na aba P1.1/P1.2, o `CH02` continuou exibindo curva e rótulos abrangendo `2017–2019`, com os quatro cartões históricos `183.532 / 183.311 / 188.246 / 555.089`, embora o diagnóstico mostrado na captura anterior indicasse ano real 2019. Isso **refuta visualmente a alegação de que a superfície atual já é uma evolução guiada exclusivamente dos 12 meses de 2019**; as capturas não enumeram formalmente os 36 pares e não fornecem export da nova sessão. A expressão histórica fixa `PERIODO_ANO={2017,2018,2019}` é **hipótese técnica plausível**, não causa exclusiva demonstrada.
3. **Oráculo:** nenhum TSV novo de 12 meses foi exportado/comparado. O oráculo histórico SHA-256 `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F` permanece preservado; `P12_2019_12_OF_12=NOT_VALIDATED`.
4. **Capturas obrigatórias:** `GUI_EVIDENCE_MISSING=gui_before.png,gui_selected_2019.png` no Verify final. Essa ausência é consistente com o estado inicial já aplicado; a captura de diagnóstico e a do gráfico foram compartilhadas na conversa, mas a presença física e conteúdo de cada imagem no diretório local não foram auditados independentemente aqui. Não inventar screenshots para satisfazer checklist.

### Verificação de integridade — saída local reportada

O primeiro comando `-Verify` foi bloqueado por `BLOCKED_CLOSE_QLIKVIEW_FIRST` enquanto a aplicação estava aberta; um bloco PowerShell anterior também foi colado em partes e produziu erro de sintaxe `elseif/else` sem chamar o runner. **Nenhum desses eventos é prova de modificação de artefatos ou de hash PASS.** Após fechar QlikView, houve um Verify bem-sucedido **uma única vez** no mesmo HEAD/runner:

~~~text
PREFLIGHT_VERIFY=PASS
GATE=SAD-C2-P12-2019-CHART-OBSERVATION-01
GIT_HEAD=d4b4f0fb68e52869051978273136321f5046ea2b
RUNNER_SHA256=0D3C91647ACD5C4364EC47B68D483C04E2E4F270A5E37751CCB1840AA96F049C
SOURCE_SHA256=D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B
QV_PRODUCT_VERSION=12.0.20000.0
QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0
PROTECTED_25_UNCHANGED=True
SOURCE_UNCHANGED=True
COPY_UNCHANGED=True
COPY_SHA256=D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B
GUI_EVIDENCE_MISSING=gui_before.png,gui_selected_2019.png
VERDICT=PASS_PROTECTED_COPY_INTEGRITY_ONLY_NOT_GUI
VERIFY_EXIT_CODE=0
~~~

**Três classificações distintas:** `INTEGRITY=PASS_LOCAL_REPORTED`; `OBSERVATION=HISTORICAL_2017_2019_STILL_VISIBLE_WITH_YEAR_REAL_2019`; `GUIDED_12_MONTHS=BLOCKED_NOT_VALIDATED`. Não atribuir `PASS_VISUAL_RESTRICTED_P12_2019_12_OF_12` nem `C2_FULL=PASS`.

### STOP e próximo gate independente

Esta tentativa está consumida e encerrada. **Não repetir Prepare, Verify, clique BU15, limpeza de filtros, extração de oráculo nem o teste histórico CH02**. Os `p12_observe_prepare.json`, `p12_observe_verify.json`, capturas e notas devem permanecer no EVIDENCE_DIR local. Uma atualização posterior deste runbook altera o HEAD do PR, **não** o commit/runner executado; nenhum PASS físico é herdado por novo código.

**Handoff recomendado, a autorizar e versionar separadamente:** `SAD-C2-P12-GUIDED-CHART-DESIGN-01` — discovery **READ-ONLY** para definir o objeto guiado separado do `CH02` histórico, sua condição de exibição, expressão candidata, filtros reais e critérios de 12 competências; revisar os riscos de set analysis, estados associativos e disponibilidade do oráculo sem editar QVW ou modelagem. Só depois, com decisão aprovada, planejar implementação em **nova cópia TEMP** e reconciliação de `201901..201912`. Essa discovery não deve ser confundida com confirmação de causa raiz.

**Invariantes:** `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
