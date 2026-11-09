# SAD C2-R2 — mensagem explicativa de bloqueio guiado

**Gate:** SAD-C2-GUIDED-PREDISPATCH-REASON-01. **Data:** 09/11/2026. **Status:** SCRIPT_VERSIONED / WINDOWS_NOT_RUN / GUI_NOT_RUN.
**Autorização:** usuário autorizou a integração guiada restrita numa nova TEMP, sem mexer no MVP B1, QVWs/QVDs canônicos, main, medidas ou modelo. Não há autorização de merge, C2 global, C3/C4 novo ou produção.
**Execução:** GPT-6/GitHub preparou código e protocolo; operador Windows PowerShell 5.1 / QlikView Desktop 12.0.20000.0 executa a única rodada. Fallback manual, sem acesso remoto COM/GUI neste atendimento.

## Fonte e decisão

Consultadas na main, em ordem: AGENTS.md, docs/project/current-state.md, docs/academic/requirements.md; depois Boundary 7, D2-R2/V3 e provas dos PRs #208, #210, #223, #225, #227 e Issue #196.

**Fato documentado:** a TEMP de #223 manteve BU16 no inventário de 38 objetos; #225 deriva dessa linhagem, com mudança restrita reportada no TX17 e SHA final local. **Pendente de confirmação GUI:** BU16, as variáveis propostas, condição de habilitação, única ação e TX17 coexistem realmente na fonte #225. Nenhum byte dessa QVW foi inspecionado neste ambiente.

Fonte imutável, a confirmar no Windows:

~~~text
C:\Users\pedro\Documents\SAD_C2_TX17_PERSIST_RUNTIME_20261106\SAD_C2_TX17_PERSIST_6c3d1061bc2a4c489f6a6737cb652487\SAD_C2_R2_TX17_PERSISTENCE_TEMP.qvw
~~~

SHA-256 esperado: **7EF5D85C235F625F0C6F10C94FCC0B3B764888A6948AE6D128A3C00138016005**.

Apenas a nova cópia denominada SAD_C2_GUIDED_REASON_TEMP.qvw pode ser editada. O runner versionado tools/Invoke-SadC2GuidedReason01.ps1 faz somente Prepare/Verify, sem COM, Reload, Save, seleção ou mudança em dados. Protege por hash a origem e os 25 canônicos (10+12 QVDs e 3 QVWs).

## Alteração mínima na interface

Na folha guiada SH02, manter BU15/BU16/CH02/CH03/TX17 intactos. Adicionar **somente um novo Objeto de Texto** ao lado do BU16, em espaço sem sobreposição, com esta expressão candidata:

~~~qlik
=If(
    '$(vSAD_POC_Mode)'='MENSAL'
    and GetSelectedCount(PERIODO_ANO,True())=1
    and GetSelectedCount(PERIODO_COMPETENCIA,True())=0
    and Only(PERIODO_ANO)<>Num($(vSAD_POC_Year)),
    'Proposta mensal incompatível: o ano proposto difere do ano selecionado. Ajuste a proposta antes de aplicar.',
    ''
)
~~~

O editor deve indicar Expression OK. Registrar o ID realmente atribuído (não presumir TX18). Objeto de Texto aceita fórmula calculada: https://help.qlik.com/pt-BR/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Text%20Object.htm. A opção True() de GetSelectedCount inclui seleções explicitamente feitas e excluídas por outros filtros: https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/ChartFunctions/FieldFunctions/getselectedcount.htm.

**Limite:** a mensagem cobre somente o conflito de ano mensal no estado testado. Texto vazio não comprova validade de outros estados, P5, domínio, filtros, indicadores, nem prevenção nativa global. Não alterar a condição ou a ação do BU16; verificar que sua condição já bloqueia o ano divergente antes de qualquer despacho.

## Prepare, com QlikView fechado

No PowerShell na raiz do repositório, executar este único bloco. Não usar reset, clean ou force. Se a branch estiver desatualizada, parar e investigar, sem reinterpretar o contrato.

~~~powershell
& {
  $ErrorActionPreference = 'Stop'
  $branch = 'test/sad-c2-guided-reason-integration-20261109'
  if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
  git fetch origin
  if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_FETCH' }
  $local = @(git branch --list $branch)
  if ($local.Count -gt 0) { git switch $branch } else { git switch --track "origin/$branch" }
  if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_SWITCH' }
  $head = (git rev-parse HEAD).Trim()
  if ($head -cne (git rev-parse "origin/$branch").Trim()) { throw 'BLOCKED_LOCAL_REMOTE_DRIFT' }
  if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_AFTER_SWITCH' }
  if (Get-Process qv,qlikview -ErrorAction SilentlyContinue) { throw 'BLOCKED_CLOSE_QLIKVIEW' }

  $repo = (git rev-parse --show-toplevel).Trim()
  $runner = Join-Path $repo 'tools\Invoke-SadC2GuidedReason01.ps1'
  $tokens = $null; $errors = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
  if (@($errors).Count -gt 0) { $errors; throw 'BLOCKED_PARSER' }

  $source = Join-Path $env:USERPROFILE 'Documents\SAD_C2_TX17_PERSIST_RUNTIME_20261106\SAD_C2_TX17_PERSIST_6c3d1061bc2a4c489f6a6737cb652487\SAD_C2_R2_TX17_PERSISTENCE_TEMP.qvw'
  $pin = '7EF5D85C235F625F0C6F10C94FCC0B3B764888A6948AE6D128A3C00138016005'
  if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'BLOCKED_SOURCE_MISSING' }
  if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $pin) { throw 'HARD_STOP_SOURCE_HASH_DRIFT' }

  $qvExe = 'C:\Program Files\QlikView\Qv.exe'
  $runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_GUIDED_REASON_RUNTIME_20261109'
  $evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_GUIDED_REASON_EVIDENCE_20261109'
  foreach ($d in @($runtime,$evidence)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
  }
  & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
  "PREPARE_EXIT_CODE=$LASTEXITCODE"
  if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_PREPARE_STOP' }
}
~~~

Copiar da saída real: GIT_HEAD, RUNNER_SHA256, QV_PRODUCT_VERSION, SOURCE_SHA256, RUNTIME_COPY, EVIDENCE_DIR e VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI. Se falhar, STOP; nunca repetir Prepare automaticamente.

## Uma única edição e um cenário negativo

1. Abrir exclusivamente a **RUNTIME_COPY** impressa. Na SH02 verificar visualmente BU15/BU16, TX17, variáveis vSAD_POC_Mode/Year/Month e campos reais. Se objeto, variável ou folha faltarem, fechar sem salvar: BLOCKED_SOURCE_CONTRACT.
2. Inspecionar BU16, sem editar. A guarda deve exigir modo MENSAL, exatamente um PERIODO_ANO real igual ao proposto, nenhuma competência real selecionada, ano no intervalo 2017–2019 e mês entre 1–12. A única ação deve ser Selecionar no Campo(PERIODO_COMPETENCIA). Guardar capturas bu16_enable.png e bu16_action.png na EVIDENCE_DIR. Divergência: STOP.
3. Preparar o cenário: seleção real PERIODO_ANO=2019 (exatamente uma) e PERIODO_COMPETENCIA sem seleção explícita; proposta MENSAL/2018/01 nas **variáveis**, não nos campos reais. Se o arquivo abrir em outro estado, permitir somente a menor alteração **manual de fixture na própria cópia**, registrando o que foi alterado; não executar Limpar Tudo, novo teste nativo, restore bookmark ou outro roteiro. Se não puder obter fixture simples e inequívoca, STOP/INCONCLUSIVE_FIXTURE. Não atribuir PASS à configuração da fixture.
4. Adicionar um único Objeto de Texto na SH02 com a expressão acima; representação Texto, Expression OK, novo ID documentado. Salvar captura reason_expression.png.
5. Conferir na mesma tela: BU16 desabilitado, aviso específico visível, Seleções Atuais mostrando 2019 e ausência de competência selecionada, proposta 2018/01. Salvar blocked_2018.png. **Não clicar BU16.** Se o botão estiver habilitado ou qualquer seleção for modificada pelo próprio controle, BLOCKED e STOP.
6. Se o cenário passou: Ctrl+S uma vez somente na nova TEMP. Fechar, reabrir **essa mesma TEMP**, reinspecionar ID e expressão do objeto de texto (sem mudar propriedades), fotografar reason_after_reopen.png. Estado de seleção após reabrir pode diferir; isso não constitui segundo cenário. Fechar sem segundo Save.
7. Registrar gui_notes.txt na EVIDENCE_DIR: HEAD/runner, origem/cópia/ID, condição e única ação BU16, seleção real antes/depois, variáveis propostas, eventuais ajustes de fixture, mensagem vista, confirmação de que BU16 não foi clicado, único Save, reabertura e anomalias. Todas as imagens devem ser desta nova execução; não copiar PNGs antigos.

**Limite probatório:** botão desabilitado e seleção preservada sustentam observação negativa restrita, não provam sozinhos ausência absoluta de dispatch ou proteção de menus, busca, bookmarks e outras rotas.

## Verify único (após fechar QlikView)

Usar mesmas variáveis $repo, $runner, $source, $qvExe, $runtime e $evidence definidas no bloco acima; se a sessão PowerShell mudou, restabelecê-las manualmente com os mesmos valores, **sem repetir Prepare**. Substituir o RunDir pelo EVIDENCE_DIR exato impresso.

~~~powershell
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -RunDir '<EVIDENCE_DIR_EXATO_DO_PREPARE>' -Verify
"VERIFY_EXIT_CODE=$LASTEXITCODE"
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_VERIFY_STOP' }
~~~

Verify confere hash origem/25 protegidos, mudança de bytes na TEMP, HEAD, SHA runner, e seis evidências não vazias com mtime posterior ao Prepare. **Não avalia conteúdo de PNG, semântica do aviso nem dispatch.**

## Critérios e encerramento

- PASS_COPY_PREPARED_ONLY_NO_GUI: cópia íntegra, 25 protegidos e origem preservados.
- PASS_RESTRICTED_GUIDED_REASON_UI: inspeção humana confirma mesma QVW com BU16/variáveis, BU16 intacto, texto novo com Expression OK, motivo exibido na proposta conflitante, BU16 desabilitado, seleção real não substituída pelo controle; evidências contemporâneas.
- PASS_PROTECTED_AND_PERSISTED_BYTES_ONLY_NOT_GUIDED_BEHAVIOR: Verify confirma só integridade e persistência física.
- INCONCLUSIVE: QVW não observada, fixture inalcançável, screenshots inconclusivos, falta de prova contextual.
- BLOCKED: hash/protegidos alterados, objeto ausente, guarda incompatível, texto inválido/ausente, BU16 habilitado no conflito, Save incorreto.
- STOP: um Prepare, uma observação negativa, um Save, uma reabertura, um Verify. Falha crítica encerra tentativa; sem R2/R3, sem retestes F1/F2, 0→1→0 ou Limpar.

**Não autorizado:** modificação BU15/BU16/CH02/CH03/TX17, MVP do PR #226, main, modelo, QVD/QVW canônicos, P5, C3/C4 novos, Fase IX, merge ou produção.
**Estado máximo:** C2_GUIDED_R2=PARTIALLY_TESTED_NOT_APPROVED_GLOBAL; C2_MICROTEST_WORKSTREAM=FROZEN_EXCEPT_THIS_AUTHORIZED_SCOPE; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False. Issue #196 permanece OPEN.
