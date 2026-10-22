# C2-K — Seleção anual/evolução guiada com ação única

**Data:** 22/10/2026. **Estado:** piloto planejado e runner versionado; **sem execução QlikView/Windows neste gate ainda**. Base da `main`: `a16539e10499d0346bf5574f3142f568a5073d02`.

## Autoridade e escopo

Em ordem: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, V2 `docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md` (§62.3, §62.6), `docs/project/qlikview-powershell-automation.md`, fechamento `docs/discovery/phase-8-c2j-guided-real-selection-p5-2026-10-22.md` no PR #154, este roteiro.

**Objetivo delimitado:** testar uma única transição real MENSAL/201801 → ANUAL/2019 por **uma única ação** `Selecionar no Campo(PERIODO_ANO, 2019)`; observar se o QlikView cancela, por associação, a seleção incompatível 201801. Após um eventual PASS, o modo EVOLUCAO/2019 poderá usar o **mesmo ano selecionado**, sem exigir nova seleção de competência. Só se observará equivalência de contexto anual, **não** se certificará gráfico, medidas ou taxa.

**Justificativa para a hipótese:** a documentação oficial de QlikView descreve que selecionar um **valor excluído** em uma lista pode cancelar seleções conflitantes; porém NÃO garante que a ação `Selecionar no Campo` do botão reproduza isso. Não assumir êxito, nem criar sequências `Limpar Campo + Selecionar no Campo`. Ações podem ter parâmetros pré-calculados e cadeias não são automaticamente transações. Fonte: https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Select_field_values.htm e https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm.

**Fronteira:** só nova cópia QVW descartável; originais 22 QVDs, 3 QVWs canônicos e cópia fonte de C2-J protegidos por hash. Sem Reload, COM, macros, QVS, mudanças de modelo, KPI, dados, CNES, P5 numérico, merge, produção ou Fase IX. Não repetir C2-J, D2 C2-H/I, nem `-Prepare` anterior. Codex Local pode ajudar com scripts; PowerShell nativo Windows 5.1 para arquivos fora do sandbox. STOP ao primeiro bloqueio.

## Fonte e novo executor

**Origem pinada (cópia final C2-J, `-Verify` reportado):**

`C:\Users\pedro\Documents\SAD_C2J_REAL_RUNTIME\SAD_VIII_C2J_REAL_6a2ba43f62a9435abf506f99dc6470a9\SAD_C2J_GUIDED_REAL_SELECTION_COPY.qvw`

**SHA-256 obrigatório:** `E4DA93675F93302AD2C954D7C8C21320042CC244957B370059EFB028403B3985`.

**Executor Git:** `tools/Invoke-SadPhaseViiiC2kAnnualEvolutionPilot.ps1` (somente `-Prepare/-Verify`, sem execução QlikView). Derivado de runner C2-J já executado com preservação de estrutura; trocar somente branch, nomes, gate e pin SHA. O parser nativo do novo arquivo **ainda não foi executado**. Runtime e evidências fora de `%TEMP%` e fora do Git.

## Preflight Windows — executar uma vez

Não usar um SHA de exemplo: substituir `EXPECTED_HEAD_DO_PR_155` pelo SHA do PR após versionamento final. Na raiz do clone real com Windows PowerShell 5.1:

~~~powershell
$ErrorActionPreference='Stop'
$branch='test/phase-viii-c2k-guided-annual-evolution-20261022'
$expected='EXPECTED_HEAD_DO_PR_155'
$dirty=@(git status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {throw 'BLOCKED_LOCAL_CHANGES'}
git fetch origin "refs/heads/${branch}:refs/remotes/origin/${branch}"
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_FETCH'}
if ((git rev-parse "refs/remotes/origin/$branch").Trim() -ne $expected) {throw 'BLOCKED_REMOTE_HEAD_DRIFT'}
git show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) {git switch $branch} else {git switch --track "origin/$branch"}
if ($LASTEXITCODE -ne 0 -or (git rev-parse HEAD).Trim() -ne $expected) {throw 'BLOCKED_CHECKOUT'}
$root=(Get-Location).Path
$source='C:\Users\pedro\Documents\SAD_C2J_REAL_RUNTIME\SAD_VIII_C2J_REAL_6a2ba43f62a9435abf506f99dc6470a9\SAD_C2J_GUIDED_REAL_SELECTION_COPY.qvw'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_MISSING'}
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne 'E4DA93675F93302AD2C954D7C8C21320042CC244957B370059EFB028403B3985') {throw 'HARD_STOP_SOURCE_HASH'}
$runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2K_ANNUAL_RUNTIME'
$evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2K_ANNUAL_EVIDENCIAS'
New-Item -ItemType Directory -Path $runtime,$evidence -Force | Out-Null
$runner=(Resolve-Path '.\tools\Invoke-SadPhaseViiiC2kAnnualEvolutionPilot.ps1').Path
$tokens=$null; $parseErrors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
if ($parseErrors.Count -gt 0) {$parseErrors | ForEach-Object {$_.ToString()};throw 'BLOCKED_PARSER'}
'PARSER=PASS'
powershell.exe -NoProfile -File $runner -Root $root -SourceQvw $source -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
~~~

Guardar `RUNTIME_COPY`, `EVIDENCE_DIR`, `RUNNER_SHA256`, `VERSIONED_GIT_HEAD`. **Uma preparação somente**, qualquer BLOCKED/STOP encerra sem procurar outra fonte. A origem não deve estar aberta no QlikView.

## Rodada única no QlikView 12, após PREPARE=PASS

1. Abrir **somente** a nova cópia com título `SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw`; conferir ausência de edição nos outros QVW.
2. Ler diagnóstico existente `ANO REAL`, `COMPETENCIA REAL`, `Qtd`; estado esperado do QVW C2-J final: ano 2018 selecionado, competência 201801 selecionada, município serviço 250750 ainda selecionado (confirmar, não pressupor que seleção persistiu no salvamento). Se não houver estado esperado, STOP INCONCLUSIVE sem limpar.
3. No controle variável `Ano`, propor **2019**; clicar no botão antigo `Anual` para alterar `vSAD_POC_Mode`. A seleção real deve continuar 2018/201801 até o novo botão — capturar ANTES. Não alterar município.
4. Criar **um novo botão** `POC — Aplicar Ano 2019` com **somente uma ação** de tipo `Seleção → Selecionar no Campo`, campo `PERIODO_ANO`, caracteres de busca `=Num($(vSAD_POC_Year))`. Não adicionar `Limpar Campo`, `Limpar Tudo`, macros, triggers, aplicar marcador ou outra ação.
5. Na aba `Geral` → `Condição para Habilitar`, configurar exatamente esta guarda **restrita ao piloto**:

~~~qlik
=If(
 '$(vSAD_POC_Mode)'='ANUAL'
 and $(vSAD_POC_Year)=2019
 and GetSelectedCount(PERIODO_ANO)=1
 and Only(PERIODO_ANO)=2018
 and GetSelectedCount(PERIODO_COMPETENCIA)=1
 and Only(PERIODO_COMPETENCIA)=201801,
 1,0)
~~~

6. Antes de clicar, capturar `Geral`, `Ações` e o diagnóstico; confirmar expressão avaliada/sem erro. Se a seleção requerida estiver indisponível ou botão desabilitado, STOP. Uma única tentativa de clique.
7. **PASS somente se** depois do clique `ANO REAL=2019, Qtd=1` **e** `COMPETENCIA REAL=SEM SELECAO, Qtd=0`, com filtro serviço/250750 preservado; botão ficou desabilitado. Se Qlik cancelar apenas parcialmente ou não reagir, STOP e classificar FAIL/INCONCLUSIVE, sem reclick/clear manual. Não mascarar mudança de proposta como seleção real.
8. Só após PASS, clicar no botão `Evolução` (apenas variável) e confirmar que os campos temporais **permanecem** `ANO REAL=2019, COMPETENCIA REAL=SEM SELECAO`, sem outra ação. Isso testa identidade do período anual e da série; **não** certifica que gráfico de 12 meses, denominadores anuais ou cobertura LT estejam corretos.

Se o QlikView cancelar a competência ao selecionar 2019 por meio da ação única, classificar **somente esta rota testada** como candidata a navegação simples. Os botões finais ainda precisam contrato de UX e guarda para contextos gerais; D2 global permanece NO-GO. Não assumir que QlikView cancela seleções como na operação manual.

## Verify — só após salvar uma vez e fechar a nova cópia

~~~powershell
powershell.exe -NoProfile -File $runner -Root $root -SourceQvw $source -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir 'EVIDENCE_DIR_REAL_EXATO_DO_PREPARE'
~~~

Esperado: `PROTECTED_25_UNCHANGED=True`, `SOURCE_UNCHANGED=True`, `COPY_CHANGED=True`; saída `PASS_HASH_INTEGRITY_ONLY_UI_NOT_PROVEN` **não prova seleção Qlik**. Usar o **mesmo checkout SHA e runner** do Prepare, sem fetch/checkout para documentação alterada até concluir Verify.

## Classificações finais e STOP

| Gate | Critério |
|---|---|
| `C2K_TEMPORAL_ANNUAL_ACTION` | PASS restrito a 201801→2019 quando campo real 2019 e competência sem seleção foram observados |
| `C2K_EVOLUTION_SAME_PERIOD` | PASS restrito se modo EVOLUCAO mantém ano real 2019 e não reintroduz competência |
| `C2K_HASH_INTEGRITY` | PASS LOCAL REPORTED somente com SHA antes/depois dos 25 arquivos + fonte |
| `C2K_FULL_YEARLY_PANEL` | NOT_TESTED (nenhum KPI/gráfico numérico validado) |
| `C2_FULL`, `P5_D2_UI`, `MEASURES_AND_DENOMINATOR_CONTRACT` | NO_GO/NOT_TESTED_GLOBAL/NOT_APPROVED |
| `PHASE_IX`, `PRODUCTION_APPROVED` | NOT_AUTHORIZED / False |

**STOP:** uma cópia, uma tentativa de clique, uma verificação. Não implementar automaticamente o fallback em cadeia, não repetir esta fase por curiosidade e não alterar os campos ou QVWs originais.