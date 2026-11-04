# SAD C2 D2-R2 — execução positiva do BU16

**Gate:** SAD-C2-R2-BU16-POSITIVE-DISPATCH-01.
**Estado:** preparado no GitHub, Windows/GUI/Verify ainda NOT_RUN nesta execução.
**Autoridade:** main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83; D2-R2 V3 aprovado semanticamente (#213); demais decisões V2/P5 e Boundary 7 preservadas.
**Objetivo:** uma QVW TEMP nova, seleção nativa de ano real 2019 para SETUP, **um clique no BU16**, comprovação da seleção efetiva de 201901 e integridade física. **Sem salvar QVW**, sem alterar scripts/dados/objetos, sem COM/Reload, sem Voltar/Adiante, sem merge.

## 1. Provas preexistentes e escopo limitado

- #201: BU15 2019 positivo restrito; #205: evolução 2019 12/12, total 188246; nenhum destes será reexecutado.
- #215/#216, #217 e Issue #196: provas negativas/pós-limpeza restritas, mês 13 relatado e capturado com protocolo desviado; já encerrados; não repetir.
- Capturas do operador: **BU14** = botão cinza “Aplicar período — POC dinâmica”, modo ANUAL/EVOLUCAO, seleciona PERIODO_ANO; **BU16** = botão azul “POC — Aplicar competência (não clicar)”, modo MENSAL, um ano real selecionado igual à proposta, competência real sem seleção, ano 2017–2019, mês 1–12; ação **Selecionar no Campo → PERIODO_COMPETENCIA → =Num($(vSAD_POC_Year))*100+Num($(vSAD_POC_Month))**. A expressão produz 201901 para ano 2019, mês 1, mas a ação ainda não foi clicada em gate aceito.
- Nenhuma evidência estática comprova compatibilidade universal P5, cobertura de dados, todos os objetos FI ou a seleção efetivamente aplicada. O rótulo histórico “não clicar” é superado **somente nesta nova cópia TEMP**, com uma execução positiva explicitamente limitada.

## 2. Origem e invariantes

**Fonte experimental e imutável:** C:\Users\pedro\Documents\SAD_C2_R2_RUNTIME\SAD_C2_R2_8dd311086a7a436f8545c8b867d5884b\SAD_C2_GUIDED_R2_TEMP.qvw

SHA-256 esperado: **648107FB45E61C6D5AA16EBA0959C58FAD579529DEC93CF42F74A9C9D957F9DD**. Arquivo já protegido e verificado localmente nos gates prévios. Não usar a TEMP modificada do PR #217 como fonte.

**Runner versionado:** tools/Invoke-SadC2R2BU16Positive01.ps1, branch test/sad-c2-r2-bu16-positive-dispatch-20261103. Prepare/Verify exclusivamente; não chama QlikView, COM, Reload ou GUI. Exige Windows/QlikView 12.0.20000.0, SHA de origem, branch/HEAD/worktree íntegros, hashes de 10 QVDs extração + 12 QVDs transformação + 3 QVWs canônicos.

Neste gate **nem a cópia TEMP pode ser salva**; o Verify trata mudança de seu hash como BLOCKED.

## 3. PowerShell 5.1 — Prepare

Fechar QlikView. Abrir Windows PowerShell 5.1 na raiz do clone local. Reusar o repositório existente, não apagar a branch anterior e não modificar main.

~~~powershell
$ErrorActionPreference = 'Stop'
$branch = 'test/sad-c2-r2-bu16-positive-dispatch-20261103'
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
$runner = Join-Path $repo 'tools\Invoke-SadC2R2BU16Positive01.ps1'
$tokens = $null; $parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
if (@($parseErrors).Count -gt 0) { $parseErrors; throw 'BLOCKED_PARSER' }
Write-Host "PARSER=PASS GIT_HEAD=$head"
Write-Host "RUNNER_SHA256=$((Get-FileHash -LiteralPath $runner -Algorithm SHA256).Hash)"

$source = Join-Path $env:USERPROFILE 'Documents\SAD_C2_R2_RUNTIME\SAD_C2_R2_8dd311086a7a436f8545c8b867d5884b\SAD_C2_GUIDED_R2_TEMP.qvw'
$qlik = 'C:\Program Files\QlikView\Qv.exe'
$runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_BU16_POSITIVE_RUNTIME'
$evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_BU16_POSITIVE_EVIDENCE'
New-Item -ItemType Directory -Force -Path $runtime,$evidence | Out-Null
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
$prepareExit = $LASTEXITCODE
Write-Host "PREPARE_EXIT_CODE=$prepareExit"
if ($prepareExit -ne 0) { throw 'BLOCKED_PREPARE_STOP' }
~~~

Condição para ir à GUI: VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI, código zero, SOURCE_SHA256 exato, RUNTIME_COPY e EVIDENCE_DIR emitidos. **Copiar literalmente os caminhos**; nunca inferir RunId.

## 4. QlikView 12 — sequência fechada

### 4.1 Setup (não é prova do BU16)

1. Abrir **somente a RUNTIME_COPY nova** informada pelo Prepare. Título esperado: SAD_C2_R2_BU16_POSITIVE_TEMP.qvw. Não abrir QVW original, PAINEL.qvw ou TEMP da rodada encerrada.
2. Folha POC - Interface Guiada: confirmar proposta MENSAL / 2019 / mês 1 / análise RES, competência real sem seleção e SERV sem seleção. A fonte #216 pode abrir com ANO REAL SEM SELEÇÃO. Se estado inesperado em outros filtros, STOP; não usar Limpar.
3. Para construir **somente baseline**, usar Layout > Selecionar Campos... e inserir uma **list box temporária PERIODO_ANO**. Selecionar valor **2019** nessa lista, sem clicar em BU14/BU15. Confirmar ANO REAL: 2019 | Qtd 1; COMPETENCIA REAL: SEM SELECAO | Qtd 0; outros filtros preservados. Registrar screenshot baseline_2019.png na EVIDENCE_DIR antes de remover a lista.
4. **Remover somente a list box temporária**, sem limpar a seleção nem salvar a QVW. Conferir imediatamente que ANO REAL continua 2019/Qtd 1 e competência sem seleção. Se falhar, INCONCLUSIVE_BASELINE_SETUP/STOP; não reconstruir por outro controle.

### 4.2 Único clique positivo

5. Identificar o botão **azul “POC — Aplicar competência (não clicar)” = BU16**, pelas capturas de propriedades já arquivadas. **Não** usar o cinza “Aplicar período — POC dinâmica” (BU14). Com proposta MENSAL/2019/01, ano real 2019 selecionado e competência real sem seleção, confirmar BU16 habilitado. Capturar positive_before.png, incluindo estado real/proposto, TX16 e RES/SERV. Se desabilitado, BLOCKED/STOP; não clicar.
6. **Clicar uma única vez no BU16 azul**, autorização limitada a esta TEMP e a este gate. Não fazer segundo clique.
7. Capturar positive_after.png. Esperado: **PERIODO_COMPETENCIA=201901 | Qtd 1**, **PERIODO_ANO=2019 | Qtd 1**, filtros não temporais preservados. TX16, canário pontual anual, deve ficar **Indisponível** por haver competência explicitamente selecionada. Confirmar que o campo real mostra 201901, não apenas uma variável proposta. Se houver seleção errada, ausência de mudança ou filtro inesperado, BLOCKED/INCONCLUSIVE, STOP. Não tentar limpar ou consertar.
8. Não usar Voltar/Adiante neste gate, não repetir mês 13 ou 12/12, não abrir gráficos para clicar e não mudar BU16/TX15. Não salvar a QVW.

### 4.3 Encerramento

9. Criar arquivo gui_notes.txt na EVIDENCE_DIR com RunId, HEAD, script SHA e build, seleção real antes/depois, outros filtros, se houve exatamente um clique, nomes dos PNGs e causa de STOP se houver. Não fabricar arquivos de etapas não executadas.
10. Fechar QlikView **sem salvar** (se perguntar, escolher Não). A cópia TEM QUE continuar com SHA de origem.

## 5. PowerShell — Verify único

Na mesma sessão PowerShell do Prepare, com QlikView fechado:

~~~powershell
$runDir = Read-Host 'Cole o EVIDENCE_DIR real emitido pelo Prepare'
if (-not (Test-Path -LiteralPath (Join-Path $runDir 'c2_bu16_prepare.json'))) { throw 'BLOCKED_WRONG_RUN_DIR' }
if (Test-Path -LiteralPath (Join-Path $runDir 'c2_bu16_verify.json')) { throw 'BLOCKED_ALREADY_VERIFIED' }
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
$verifyExit = $LASTEXITCODE
Write-Host "VERIFY_EXIT_CODE=$verifyExit"
if ($verifyExit -ne 0) { throw 'BLOCKED_VERIFY_STOP' }
~~~

Integridade requerida: PROTECTED_25_UNCHANGED=True; SOURCE_UNCHANGED=True; COPY_CHANGED_FROM_SOURCE=False; VERDICT=PASS_HASH_INTEGRITY_ONLY_NOT_GUI; exit code 0. O runner apenas enumera screenshots que faltam, não julga visualmente as evidências. Nada de reexecutar Verify.

## 6. Critérios de aceite, STOP e handoff

**PASS_RESTRICTED_BU16_POSITIVE:** baseline 2019 produzido por seleção nativa explicitamente classificada como SETUP_NOT_ACCEPTANCE; um clique BU16 efetivamente aplica PERIODO_COMPETENCIA=201901 com ano 2019; filtros preservados; TX16 não publica total anual pontual sob competência mensal; screenshots e notes contemporâneos; fonte, TEMP e 25 protegidos byte-idênticos conforme Verify local reportado.

**BLOCKED:** BU16 desabilitado no contexto esperado, seleção incorreta/ineficaz, filtros removidos ou alterados, canário anual incorretamente válido, hash da TEMP/fonte/protegidos alterado ou qualquer tentativa de gravar documento.

**INCONCLUSIVE:** campo real não legível, baseline não reproduzido, histórico de filtros insuficiente, screenshot não produzido, UI sem comportamento comprovável.

**STOP:** um Prepare, um setup, um clique BU16 no máximo, um Verify elegível. Sem alteração de modelagem, TX15, input month, runner anterior, COM, QVS/QVD, PRs encerrados, C3/C4, Fase IX, merge nem produção.

Handoff: enviar stdout Prepare/Verify, baseline_2019.png, positive_before.png, positive_after.png, gui_notes.txt. C2_GUIDED_R2 e P5_D2_UI permanecem NOT_APPROVED_GLOBAL até aceite separado.
