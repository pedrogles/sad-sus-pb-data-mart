# SAD — C2 D2-R2 | Execução residual em QlikView 12

**Gate:** SAD-C2-R2-RESIDUAL-CONTEXT-ACCEPTANCE-01  
**Baseline:** main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83; V3 D2-R2 integrada (#213), V2 temporal/P5 preservada.  
**Estado atualizado:** primeira rodada local `SAD_C2_R2_RESIDUAL_09c1337f8c4e43c3806be8f355a8d51b` encerrada como `INCONCLUSIVE_BASE_STATE` (ano real 0, competência real 0); `Prepare=PASS`, `Verify=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI`, `SOURCE_UNCHANGED=True`, `PROTECTED_25_UNCHANGED=True`, `COPY_CHANGED_FROM_SOURCE=False`, `VERIFY_EXIT_CODE=0`. Screenshot de baseline recebido em conversa, **não persistido** no EVIDENCE_DIR; não declarar PNG presente. Esta revisão documental prepara **nova rodada** com baseline explícito, ainda `NOT_RUN`. Autorização restrita a cópia descartável, sem merge/COM/reload/canônicos.  
**Runner:** tools/Invoke-SadC2R2ResidualContext01.ps1 (derivado do guard #216, Prepare/Verify de SHA e cópia, **não** inicia o QlikView).  
**Origem:** cópia TEMP salva do #216, não QVW canônico. RunId anterior SAD_C2_R2_8dd311086a7a436f8545c8b867d5884b, SHA-256 reportado 648107FB45E61C6D5AA16EBA0959C58FAD579529DEC93CF42F74A9C9D957F9DD. Existência e hash **a confirmar no Windows**.

## 1. Reutilizar provas anteriores (não repetir)

- #201 BU15: ano real 2019 aplicado, apenas rota testada.
- #205 P1.2 12/12 competências 2019, total 188246; CH02 de 36 competências distinto.
- #208/#210: BU16 e rotas inventariadas; menus/busca não recebem prevenção global.
- #215/#216 e Issue #196: T1 conflito de ano com BU16 desabilitado e motivo; T2 após Seleções > Limpar com TX16 de 188246 para Indisponível, proposta pré-limpeza MENSAL/2019/01 (desvio de ANUAL/2019); protocolo integral INCONCLUSIVE. PNGs T2 recuperados após Verify não alteram JSON.

**Lacunas factuais:** (i) a expressão TX15 do runbook #216 só explica incompatibilidade de ANO, não MÊS 13; o ensaio ajusta **apenas TX15 na nova cópia** para apresentar motivo no caso do domínio, sem editar BU16 ou canário TX16; (ii) a QVW #216 abriu na primeira rodada **sem ano real selecionado**, embora a proposta visual já indique 2019. A nova rodada faz preparação explícita de baseline em `PERIODO_ANO`, **fora do conjunto de casos de aceitação**, com uma list box temporária criada e removida **antes de salvar a TEMP**. Isso não homologa domínio completo nem P5, e a preparação não é reaproveitamento de PASS de BU15.

## 2. PowerShell 5.1 — checkout seguro, parser e Prepare

Com QlikView completamente fechado, abrir **Windows PowerShell 5.1**, acessar a raiz local do repositório e executar:

~~~powershell
$ErrorActionPreference='Stop'
$branch='test/sad-c2-r2-residual-context-20261103'
if (@(git status --porcelain --untracked-files=all).Count -gt 0) {throw 'BLOCKED_DIRTY_WORKTREE'}
git fetch origin "refs/heads/test/sad-c2-r2-residual-context-20261103:refs/remotes/origin/test/sad-c2-r2-residual-context-20261103"
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_FETCH'}
git show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) { git switch $branch } else { git switch --track "origin/$branch" }
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_SWITCH'}
# A branch já existe no Windows e a nova documentação está no remoto: atualizar APENAS em fast-forward.
git pull --ff-only origin $branch
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_NON_FAST_FORWARD_OR_PULL'}
$head=([string](git rev-parse HEAD)).Trim()
$remote=([string](git rev-parse "origin/$branch")).Trim()
if ($head -cne $remote) {throw 'BLOCKED_HEAD_DRIFT'}
if (@(git status --porcelain --untracked-files=all).Count -gt 0) {throw 'BLOCKED_DIRTY_AFTER_SWITCH'}
$repo=(Get-Location).Path
$runner=Join-Path $repo 'tools\Invoke-SadC2R2ResidualContext01.ps1'
$tokens=$null; $parseErrors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
if (@($parseErrors).Count -gt 0) {$parseErrors;throw 'BLOCKED_PARSER'}
Write-Host "PARSER=PASS GIT_HEAD=$head"
Write-Host "RUNNER_SHA256=$((Get-FileHash -LiteralPath $runner -Algorithm SHA256).Hash)"
$source=Join-Path $env:USERPROFILE 'Documents\SAD_C2_R2_RUNTIME\SAD_C2_R2_8dd311086a7a436f8545c8b867d5884b\SAD_C2_GUIDED_R2_TEMP.qvw'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_MISSING'}
$expected='648107FB45E61C6D5AA16EBA0959C58FAD579529DEC93CF42F74A9C9D957F9DD'
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $expected) {throw 'HARD_STOP_SOURCE_HASH'}
$qlik='C:\Program Files\QlikView\Qv.exe'
$runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2_R2_RESIDUAL_RUNTIME'
$evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2_R2_RESIDUAL_EVIDENCE'
New-Item -ItemType Directory -Force -Path $runtime,$evidence | Out-Null
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_PREPARE_NO_RETRY'}
~~~

**Condição para prosseguir:** VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI e PREPARE sem erro. Guardar GIT_HEAD, RUNNER_SHA256, **RUNTIME_COPY** e **EVIDENCE_DIR** impressos. O runner confere QlikView 12.0.20000.0, fonte, branch e inventário SHA de 10+12 QVDs e 3 QVWs canônicos. Se caminho ou SHA divergirem, **STOP**. Nunca remover guardas ou trocar a fonte automaticamente.

## 3. GUI — QlikView Desktop 12

Todas as capturas abaixo devem ser salvas no **EVIDENCE_DIR real**, indicado pelo Prepare, e mostrar **proposta e seleção real separadas**. Não presumir que a variável proposta altera o campo.

**3.1 Preparação explícita do baseline (NÃO é caso de aceite funcional)**

O primeiro ensaio abriu a fonte #216 com ano real **SEM SELEÇÃO**, apesar de `vSAD_POC_Year=2019`. Na nova cópia, **não presumir** que a proposta selecione o campo. Não repetir tentativa de abrir a QVW original ou importar seleções salvas.

1. Arquivo > Abrir > escolher **somente RUNTIME_COPY** gerado na nova rodada; confirmar no título `SAD_C2_R2_RESIDUAL_TEMP.qvw`. Nunca abrir a origem para editar.
2. Na folha **POC - Interface Guiada**, observar e fotografar o **estado exatamente como abriu**: campos reais, modo/ano/mês propostos, BU16, TX15, TX16, filtros RES/SERV e quaisquer seleções adicionais. Salvar `initial_unselected.png` (evidência **opcional** ao checker mas recomendada). Estado esperado da fonte #216: `PERIODO_ANO` sem seleção explícita e `PERIODO_COMPETENCIA` sem seleção; se divergir, registrar estado efetivo e **STOP** para não criar pré-condição ambígua.
3. Para selecionar **um valor real de campo**, usar **Layout > Selecionar Campos...** (a tradução na instalação pode aparecer como `Select Fields...`). Abrir as propriedades da folha/campos e adicionar **somente** `PERIODO_ANO` à lista dos campos apresentados, gerando uma caixa de listagem **temporária**. Não selecionar a variável da proposta `Ano=2019`, não trocar filtros RES/SERV, não abrir editor de script nem criar botão novo. Se o comando não existir, estiver bloqueado ou o campo não estiver disponível: `INCONCLUSIVE_BASELINE_SETUP`/STOP; não improvisar COM/macro/trigger.
4. Na **caixa de listagem recém-criada de `PERIODO_ANO`**, selecionar **2019** com um clique; confirmar o valor selecionado no próprio campo e no diagnóstico: `ANO REAL: 2019 | Qtd: 1`, `COMPETENCIA REAL: SEM SELECAO | Qtd: 0`, nenhum filtro RES/SERV selecionado, demais filtros preexistentes preservados. **Não** usar o botão desabilitado "Aplicar Ano 2019", nem `Seleções > Limpar`. Esta ação é **somente setup**, não PASS do controle guiado.
5. Capturar `baseline_setup_2019.png`, mostrando o valor 2019 selecionado na caixa, a seleção real e filtros. Remover **apenas a caixa temporária** pela opção de remoção do objeto, sem limpar a seleção de `PERIODO_ANO`; **reconferir imediatamente** que o ano continua 2019/Qtd 1 e a competência sem seleção/Qtd 0. Se a remoção apagar a seleção real ou alterar filtros, `INCONCLUSIVE_BASELINE_SETUP`/STOP — não repetir ações.
6. Ir à aba **POC P1.1-P1.2 - Internações** para identificar cartões, CH02 e gráfico guiado, sem clicar em valores; voltar à folha guiada. Salvar `baseline.png` mostrando o estado **após a preparação e remoção da caixa temporária**, antes da edição de TX15. Registrar em `gui_notes.txt` que `PERIODO_ANO=2019` foi obtido por **seleção nativa manual** durante SETUP e que nenhuma seleção foi recriada por ação testada. Não chamar esta preparação de PASS D2 guiado. Se houver outras seleções/filtros não inventariados ou a mudança de aba interferir no estado: STOP.

A seleção nativa por list box é suportada pelo QlikView, assim como a inclusão de campos na folha pelo menu Layout. **Apenas TX15 poderá ser salvo como alteração persistente da TEMP**; a caixa de listagem de preparação deve ter sido removida antes do único `Ctrl+S`. Um `Verify` com SHA diferente não prova sozinho que só TX15 mudou.

**3.2 Alterar somente a mensagem TX15 na cópia**

7. Retornar à folha guiada; clicar com botão direito no Text Object **TX15** > Propriedades. Conferir que o ID físico é TX15 e que a expressão atual é a condição de conflito de ano do runbook #216. Se o objeto/expressão não coincidir, STOP.
8. No campo de texto/expressão de TX15, colocar a expressão candidata abaixo. Abrir o editor e confirmar que foi aceita sem erro. Não modificar mais nenhum objeto, expressão ou script:

~~~qlik
=If(
  '$(vSAD_POC_Mode)'='MENSAL'
  and (Num($(vSAD_POC_Month))<1
       or Num($(vSAD_POC_Month))>12),
  'Não aplicado: mês fora do domínio 01 a 12',
  If(
    '$(vSAD_POC_Mode)'='MENSAL'
    and GetSelectedCount(PERIODO_ANO)=1
    and Num(Only(PERIODO_ANO))<>Num($(vSAD_POC_Year)),
    'Não aplicado: ano proposto difere do ano real',
    'Sem conflito desta classe'
  )
)
~~~

9. Capturar tx15_properties.png com ID e expressão. Salvar **somente a nova TEMP** com Ctrl+S **uma vez**, antes dos testes de seleções. A mensagem é específica de valores numéricos do mês e conflito de ano, não cobre mês ausente, disponibilidade de competência nem P5.

**3.3 Negativo: mês fora do domínio**

10. Nos controles de **proposta** existentes, definir Modo=MENSAL, Ano=2019, Mês=13. Não editar campos de seleção real. Se o controle impedir 13, registrar INPUT_NOT_EXPOSED/INCONCLUSIVE para esta prova e não contornar via script.
11. Exigir BU16 **desabilitado**, TX15 com “Não aplicado: mês fora do domínio 01 a 12”, ANO REAL=2019 Qtd 1, COMPETENCIA REAL sem seleção Qtd 0. Capturar invalid_13.png. Não clicar no botão desabilitado. Se mensagem faltar, botão habilitar ou seleção mudar: BLOCKED/STOP.

**3.4 Positivo: aplicar 201901**

12. Alterar **somente a proposta do mês** para 01; manter MENSAL/2019 e as seleções reais anteriores. BU16 deve habilitar. Capturar valid_before.png.
13. Clicar **uma única vez** no BU16 habilitado. Esperado: PERIODO_COMPETENCIA=201901 selecionado (Qtd 1), ano coerente com 2019, demais seleções preservadas. Capturar valid_after.png. Se não aplicar, aplicar diferente ou apagar filtros: BLOCKED/STOP, sem segundo clique.

**3.5 Nativo: Voltar / Adiante**

14. **Somente após PASS do despacho**, menu **Seleções > Voltar** uma vez. Verificar se restaura o estado anual anterior (ano 2019 selecionado, competência sem seleção explícita). Capturar native_back.png. O TX16 pode exibir 188246 **somente** com contexto FI anual e filtros neutros; observar visualizações existentes. Se a transição não for verificável: INCONCLUSIVE_HISTORY_TRANSITION/STOP.
15. Menu **Seleções > Adiante** uma vez. Verificar retorno a 201901, capturar native_forward.png. TX16 anual pontual deve ficar indisponível diante de competência explícita; um visual mensal pode continuar válido. Observar P1.1/P1.2 e registrar quais valores são fixos versus dinâmicos.
16. CH02 e cartões históricos de 2017–2019 podem permanecer visíveis **quando rotulados como histórico fixo**. Não exigir que desapareçam, nem que CH03 apresente 12 pontos em modo MENSAL. Não repetir o oráculo 12/12.

**3.6 Encerrar GUI**

17. Criar gui_notes.txt no EVIDENCE_DIR com RunId, HEAD, runner SHA, QlikView build, Object IDs, expressão TX15, proposta/estado real/filtros antes e depois, ações efetivamente executadas, capturas e motivos de STOP. Omitir capturas de passos não executados; jamais fabricá-las.
18. Fechar o QlikView **sem salvar novamente**; se perguntar, selecionar **Não salvar**. Fonte e 25 protegidos jamais devem ser abertos para edição.

## 4. Verify — uma única vez, QlikView fechado

Na **mesma sessão PowerShell** do Prepare, preencher o **EVIDENCE_DIR efetivamente emitido pelo runner**:

~~~powershell
$runDir='<COLE_EVIDENCE_DIR_REAL_DO_PREPARE>'
if (@(Get-Process -Name qv,qlikview -ErrorAction SilentlyContinue).Count -gt 0) {throw 'BLOCKED_CLOSE_QLIKVIEW_FIRST'}
if (Test-Path -LiteralPath (Join-Path $runDir 'c2_r2_residual_verify.json')) {throw 'BLOCKED_VERIFY_ALREADY_RECORDED'}
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
$verifyExit=$LASTEXITCODE
Write-Host "VERIFY_EXIT_CODE=$verifyExit"
if ($verifyExit -ne 0) {throw 'BLOCKED_VERIFY_STOP_NO_RETRY'}
~~~

Verificar PROTECTED_25_UNCHANGED=True, SOURCE_UNCHANGED=True e VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI. A TEMP pode ter COPY_CHANGED_FROM_SOURCE=True pelo único ajuste TX15. **SHA diferente não comprova diff interno da QVW**. O runner verifica **presença**, não conteúdo/semântica das capturas; GUI_EVIDENCE_MISSING precisa ser interpretado considerando STOP anterior. Não reexecutar Verify, não alterar JSON histórico.

## 5. Critérios e STOP

- **PASS_RESTRICTED:** baseline preparado por seleção nativa de `PERIODO_ANO=2019` explicitamente marcado **SETUP_NOT_ACCEPTANCE**, temporária list box removida antes do único save; rejeição da proposta inválida com motivo e preservação; despacho mensal único aplica 201901 real; operação nativa restaura/reaplica estado com apresentação correta dos objetos afetados; hashes de origem+25 protegidos inalterados, capturas e propriedades inspecionáveis. Apenas cenários testados, **não C2 global**.
- **BLOCKED:** botão aceita mês inválido, motivo de rejeição falha, ação real incorreta, valor dinâmico obsoleto publicado como válido, alteração inesperada de filtros, expressão não aceita ou deriva SHA de protegido.
- **INCONCLUSIVE:** fonte diferente do estado inicial identificado, preparação de baseline não realizada por UI documentada, seleção 2019 não persistir após remoção da caixa temporária, mês inválido inacessível, histórico Voltar/Adiante não restaura seleção inferível, objeto/visual não identificado ou evidências insuficientes.
- **STOP:** primeira rodada anterior está ENCERRADA e não será reaberta; autoriza-se apenas uma **nova rodada** preparada com o mesmo runner versionado e uma RUNTIME_COPY nova, seguida de um Verify elegível. Sem repetição T0/T1/T2, #201/#205, novos QVW/COM/recargas, segunda correção de expressão, runners R2/R3, merge, C3/C4 ou GO IX automático. C2_GUIDED_R2=NOT_APPROVED_GLOBAL, PRODUCTION_APPROVED=False até aceite separado.

**Handoff:** devolver stdout completo de Prepare/Verify, capturas e gui_notes.txt ao revisor para classificação física. O Gate PASS, PR merge e aprovação de produção são decisões distintas.
