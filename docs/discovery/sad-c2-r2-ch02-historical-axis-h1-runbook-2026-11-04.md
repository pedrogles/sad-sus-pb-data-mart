# SAD C2 — Teste experimental H1: CH02 com competência aplicada

**Gate:** SAD-C2-R2-CH02-HISTORICAL-AXIS-H1-01.
**Estado:** protocolo e runner preparados em GitHub; parser Windows, Prepare, GUI e Verify ainda NOT_RUN.
**Autoridade:** alternativa A de isolamento histórico aprovada pelo responsável em 04/11/2026 no PR #219, ainda Draft. Main de origem 0549e1dba71aaa8bbab9d6755aecb8465f8bea83; D2-R2 V3 e Boundary 7 preservados.
**Objetivo único:** demonstrar se CH02 consegue exibir o histórico completo de 36 competências quando os campos reais PERIODO_ANO=2019 e PERIODO_COMPETENCIA=201901 estão selecionados simultaneamente. Primeiro observar a fórmula ORIGINAL; somente se falhar, testar UMA mudança de medida do CH02. Não editar cartões TX10–TX13 ou CH03 neste gate.

## Invariantes e técnica candidata

**Fonte experimental intocável:** C:\Users\pedro\Documents\SAD_C2_R2_RUNTIME\SAD_C2_R2_8dd311086a7a436f8545c8b867d5884b\SAD_C2_GUIDED_R2_TEMP.qvw

**Hash SHA-256 da origem, obrigatório:** 648107FB45E61C6D5AA16EBA0959C58FAD579529DEC93CF42F74A9C9D957F9DD.

CH02 original na TEMP, conforme captura QlikView de 04/11: dimensão PERIODO_COMPETENCIA, medida:

~~~qlik
=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)
~~~

**Hipótese de uma mudança de medida em TEMP, NÃO aprovada fisicamente:**

~~~qlik
=Sum({$<PERIODO_ANO={2017,2018,2019},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)
~~~

O conjunto $ mantém a seleção atual dos demais campos; o modificador vazio da competência tenta retirar somente a seleção temporal desse campo. **Não garante 36 pontos da dimensão CH02** ou neutralização de todos os efeitos associativos. Não migrar para o conjunto 1, alternate states, campo novo ou outro workaround no mesmo gate. Fonte técnica:
https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-modifiers.htm
https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-analysis-expressions.htm

**Permitido:** nova QVW TEMP fora do Git, seleção nativa de 2019 e 201901, capturas, uma edição só da expressão CH02 se necessário, no máximo UM salvar da TEMP em caso de resultado positivo, Verify único.
**Proibido:** modificar origem ou 25 protegidos (10 QVDs extração, 12 QVDs transformação e 3 QVWs), reload/COM/script, clicar BU14/BU16, mexer em TX10–TX13/CH03, remover filtros não temporais, refazer oráculos, iniciar C3/C4/IX, efetuar merge ou alteração na main.

## 1. Prepare no Windows PowerShell 5.1 (QlikView fechado)

Abra o PowerShell na raiz do repositório e execute:

~~~powershell
$ErrorActionPreference = 'Stop'
$branch = 'test/sad-c2-r2-ch02-historical-axis-h1-20261104'
if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
git fetch origin "refs/heads/$($branch):refs/remotes/origin/$($branch)"
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_FETCH' }
git show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) { git switch $branch } else { git switch --track "origin/$branch" }
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_SWITCH' }
$head = ([string](git rev-parse HEAD)).Trim()
$remote = ([string](git rev-parse "origin/$branch")).Trim()
if ($head -cne $remote) { throw 'BLOCKED_HEAD_DRIFT' }
if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_AFTER_SWITCH' }
$repo = (Get-Location).Path
$runner = Join-Path $repo 'tools\Invoke-SadC2R2CH02AxisH101.ps1'
$tokens = $null; $parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
if (@($parseErrors).Count -gt 0) { $parseErrors; throw 'BLOCKED_PARSER' }
Write-Host "PARSER=PASS GIT_HEAD=$head"
Write-Host "RUNNER_SHA256=$((Get-FileHash -LiteralPath $runner -Algorithm SHA256).Hash)"
$source = Join-Path $env:USERPROFILE 'Documents\SAD_C2_R2_RUNTIME\SAD_C2_R2_8dd311086a7a436f8545c8b867d5884b\SAD_C2_GUIDED_R2_TEMP.qvw'
$qlik = 'C:\Program Files\QlikView\Qv.exe'
$runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_CH02_H1_RUNTIME'
$evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_CH02_H1_EVIDENCE'
New-Item -ItemType Directory -Force -Path $runtime,$evidence | Out-Null
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
Write-Host "PREPARE_EXIT_CODE=$LASTEXITCODE"
~~~

Só avançar se PREPARE_EXIT_CODE=0 e VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI, com SOURCE_SHA256 correto, RUNTIME_COPY e EVIDENCE_DIR impressos. **Copie os caminhos exatos**. Uma alteração de runner entre Prepare e Verify será bloqueada.

## 2. QlikView 12 — roteiro estrito

**H0: sem seleções, prova inicial.**

1. Abra **somente RUNTIME_COPY** na QVW TEMP cujo nome termina em SAD_C2_R2_CH02_AXIS_H1_TEMP.qvw. Não abra a fonte #216 ou qualquer TEMP encerrada.
2. Folha POC - Interface Guiada: confirme no texto de estado real ANO SEM SELEÇÃO Qtd 0 e COMPETÊNCIA SEM SELEÇÃO Qtd 0; SERV também sem filtro. Se inesperado, INCONCLUSIVE_BASELINE_STATE e STOP; não use Limpar para reconstruir.
3. Folha POC P1.1-P1.2 - Internações: confirme os quatro cartões 183.532 / 183.311 / 188.246 / 555.089, CH02 histórico com início 201701 e fim 201912. Salve **h0_before.png** diretamente na EVIDENCE_DIR. Verificar 36 competências distintas preferencialmente pelo botão de exportação de dados do próprio gráfico (XL, se disponível) para arquivo na EVIDENCE_DIR. Não recalcular oráculos históricos e não criar gráfico extra. Se H0 falhar, STOP.

**H1: aplicar seleção temporal NATIVA, sem BU16.**

4. Volte à folha POC - Interface Guiada e use Layout > Selecionar Campos... para criar temporariamente duas caixas de lista dos campos PERIODO_ANO e PERIODO_COMPETENCIA.
5. Clique 2019 na caixa de ano, depois clique 201901 na caixa de competência. O texto de estado real deve mostrar **ANO 2019 Qtd 1 e COMPETÊNCIA 201901 Qtd 1**, com SERV não selecionado. Caso contrário, STOP, não tente outras rotas.
6. Salve captura **h1_real_state.png**. Remova **somente as duas caixas temporárias criadas**, sem limpar as seleções e sem salvar a QVW; confira que os campos reais continuam Qtd 1.
7. Na folha POC P1.1-P1.2 - Internações, examine CH02. Salve **h1_before.png**. Se conseguir, exporte os dados do gráfico para provar quantas competências distintas realmente aparecem. **Se já mostrar 36/36 meses históricos íntegros**, registre NO_EDIT_REQUIRED; não altere nem salve a TEMP e vá ao encerramento.
8. Se CH02 mostrar 1 ponto ou menos de 36, e a fórmula original for realmente a do contrato, prossiga somente com o teste da hipótese. Se houver divergência não explicada, STOP sem editar.

**ÚNICA alteração experimental, se necessária.**

9. Clique direito no gráfico histórico **superior**, abra Propriedades > Geral e confira ID DO OBJETO = CH02 (não CH03).
10. Abra a aba Expressões, selecione a única medida de internações e o editor da definição. Confira a fórmula original. Se diferente, INCONCLUSIVE_SOURCE_EXPRESSION e STOP.
11. Substitua **apenas a expressão da medida CH02** pela expressão candidata mostrada no início do documento. Exija Expressão OK; feche editor e Propriedades por OK uma vez. Não toque dimensão, título, limites, seleção, opções de gráfico, cartões ou CH03.
12. Sem mudar o estado H1, confira CH02 e salve **h1_after.png**. Verifique **36 competências distintas 201701..201912** e os valores históricos já reconciliados. Se o eixo ainda exibir um único mês, **BLOCKED_HISTORICAL_AXIS**, STOP, sem novo teste/expressão. Se não puder provar 36 meses exatos, INCONCLUSIVE_POINT_COUNT.
13. **Somente se houver resultado positivo na expressão candidata**, salve o documento TEMP **uma única vez**. Se falhou ou ficou inconclusivo, feche SEM salvar. Uma mudança de hash da TEMP é permitida, mas **não prova diff de um único objeto**.

## 3. Evidências, fechamento e Verify

**Antes do Verify**, confira por Explorer que EVIDENCE_DIR contém h0_before.png, h1_real_state.png, h1_before.png e gui_notes.txt; se houve Save da TEMP, também h1_after.png. Não deixe PNGs somente no chat/clipboard. Não crie screenshot retrospectiva.

Em **gui_notes.txt**, descreva: RunId e HEAD; estado H0; estado H1 real; contagem CH02 H0/H1 antes e depois (se aplicável), exportações/prints; fórmula antes/depois; se houve SAVE TEMP; filtros RES/SERV; veredito e STOP. Não declare PASS sem prova de 36 pontos efetivos.

Feche o QlikView sem salvar novamente. Na **mesma sessão PowerShell** usada para Prepare, execute:

~~~powershell
$runDir = Read-Host 'Cole o EVIDENCE_DIR informado pelo Prepare'
if (-not (Test-Path (Join-Path $runDir 'c2_ch02_h1_prepare.json'))) { throw 'BLOCKED_WRONG_RUN_DIR' }
if (Test-Path (Join-Path $runDir 'c2_ch02_h1_verify.json')) { throw 'BLOCKED_VERIFY_ALREADY_RECORDED' }
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
Write-Host "VERIFY_EXIT_CODE=$LASTEXITCODE"
~~~

**Integridade esperada:** PROTECTED_25_UNCHANGED=True; SOURCE_UNCHANGED=True; VERIFY_EXIT_CODE=0; VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI. COPY_CHANGED_FROM_SOURCE=False se não houve Save; True pode ocorrer na TEMP após Save experimental. O runner não avalia QlikView visualmente nem prova que só CH02 mudou. GUI_EVIDENCE_MISSING é um inventário **no instante do Verify**, que não deverá ser manipulado por rerun.

## 4. Decisão e STOP

- **PASS_RESTRICTED_H1_ALREADY_ISOLATED:** CH02 original exibe 36 meses/valores sob H0 e H1, sem editar.
- **PASS_RESTRICTED_H1_CH02_CANDIDATE:** H0 correto, H1 real comprovado, uma edição CH02 em TEMP, 36 meses/valores válidos sob H1, fonte/25 protegidos íntegros, evidências presentes, sem filtros não temporais ignorados.
- **BLOCKED_HISTORICAL_AXIS:** o modificador de medida não preserva a dimensão CH02 ou há números inválidos com título histórico.
- **BLOCKED_INTEGRITY:** fonte ou 25 protegidos mudaram, ou runner não passou.
- **INCONCLUSIVE:** seleção H0/H1, 36 pontos, expressão ou imagens insuficientes.

**STOP:** um Prepare, uma configuração H1, no máximo uma expressão alterada e um Save TEMP, um Verify. Não reexecutar BU16, mês13, 12/12, nem expandir automaticamente TX10–TX13/CH03. Esta execução não autoriza C2 global, P5 global, C3/C4/IX ou produção.
