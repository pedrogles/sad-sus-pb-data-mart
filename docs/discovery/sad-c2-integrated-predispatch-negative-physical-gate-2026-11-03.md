# SAD — C2: gate físico de bloqueio pré-despacho (botão único)

**Gate:** `SAD-C2-INTEGRATED-PREDISPATCH-NEGATIVE-POC-01`.  
**Autorização recebida:** em 03/11/2026, o responsável respondeu "certo, prossiga" à proposta de **preparação e execução restrita de um teste físico** em nova QVW TEMP, seguindo a alternativa A. Não inclui merge, edição de arquivos canônicos, produção, P5/D2 global ou mudança da semântica V2.
**Baseline documental:** `main@2cc197d5310f5fbd65585df9084346fcd4f402a0`; [desenho anterior #207 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/207) (não é `main`).  
**Estado nesta publicação:** `SCRIPT_VERSIONED / WINDOWS_NOT_RUN / QLIKVIEW_NOT_RUN / GATE_PASS_NOT_CLAIMED`.  
**Agente:** GPT-6 + GitHub apenas para preparação e revisão; **execução física pertence ao operador Windows/QlikView 12** ou Codex Local no Windows efetivamente conectado. Não há execução Windows/COM/GUI remota neste atendimento.  
**Fonte de verdade:** [AGENTS](../../AGENTS.md) → [current-state](../project/current-state.md) → [requirements](../academic/requirements.md) → [Boundary 7](boundary-7-implementation-plan.md) → [V2 §62.3/62.6](phase-6-semantic-v2-approved-2026-10-14.md) → [desenho #207 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/207) → [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196) → [closeout #205](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205). Preservar a ordem C2→C3→C4→IX.

## 1. Fronteira exata

**Uma única nova cópia** da QVW TEMP salva e verificada no #205:
- `C:\Users\pedro\Documents\SAD_C2_P12_CHART_RUNTIME\SAD_C2_P12_CHART_4d1f6da0544749b5bb92b4346300c025\SAD_C2_P12_GUIDED_CHART_TEMP.qvw`
- **SHA-256 esperado:** `C8C3F24DAB56ABEEC0ABD0194A691FD78536BF8F550410E3C609262141A5B917` (reportado pelo Verify Windows #205; deve ser revalidado localmente antes de copiar).
- Origem é **protegida**, não editar/salvar. O novo artefato terá nome `SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw` sob `Documents\SAD_C2_PREDISPATCH_RUNTIME\<RunId>`.
- **25 canônicos protegidos:** 10 QVDs extração, 12 transformação, 3 QVWs `EXT.qvw`, `TRANSF.qvw`, `PAINEL.qvw`. Nunca recarregar/alterar esses arquivos.

**Única mutação autorizada na nova TEMP:** criar **um novo botão** (ID atribuído pelo QlikView), com **uma** condição de habilitação candidata e **uma única ação configurada mas nunca clicada**. Alterar somente as três variáveis de proposta já existentes (`vSAD_POC_Mode`, `vSAD_POC_Year`, `vSAD_POC_Month`), observando a condição `0→1→0`. Não tocar BU15, CH02, gráfico P1.2, seus objetos anteriores, demais botões, filtros, listas, QVS, associações ou dados. Não adicionar objeto de texto/segundo botão/trigger/macro. **Não clicar no botão novo**, mesmo quando habilitado.

Se a mensagem de motivo não puder ser observada sem adicionar um segundo objeto, registrar `UX_REASON_NOT_IMPLEMENTED` e limitar o resultado à guarda técnica; **não** inventar aprovação de UX. Não declarar que bloqueio por botão contém pesquisa, marcadores ou menu Seleções.

## 2. Preflight único (PowerShell 5.1, Windows)

Usar clone local **limpo** na raiz do repositório, QlikView fechado. Buscar a branch de teste e fixar seu HEAD antes de executar. Não usar `git clean`, `reset --hard` ou editar script local; arquivos QVD/QVW ignorados pelo Git continuam protegidos.

~~~powershell
& {
  $ErrorActionPreference='Stop'
  $branch='test/sad-c2-integrated-predispatch-negative-20261103'
  if (@(git status --porcelain --untracked-files=all).Count -gt 0) {throw 'BLOCKED_DIRTY_WORKTREE'}
  git fetch origin
  if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_FETCH'}
  git show-ref --verify --quiet "refs/heads/$branch"
  if ($LASTEXITCODE -eq 0) {git switch $branch} else {git switch --track "origin/$branch"}
  if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_SWITCH'}
  $head=([string](git rev-parse HEAD)).Trim()
  $remote=([string](git rev-parse "origin/$branch")).Trim()
  if ($head -cne $remote) {throw 'BLOCKED_LOCAL_REMOTE_HEAD_DRIFT'}
  if (@(git status --porcelain --untracked-files=all).Count -gt 0) {throw 'BLOCKED_DIRTY_AFTER_SWITCH'}
  if (@(Get-Process -Name qv,qlikview -ErrorAction SilentlyContinue).Count -gt 0) {throw 'BLOCKED_CLOSE_QLIKVIEW'}
  $runner=Join-Path (Get-Location).Path 'tools\Invoke-SadC2PredispatchNegativePoc01.ps1'
  $tokens=$null; $errors=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
  if (@($errors).Count -gt 0) {$errors;throw 'BLOCKED_PARSER'}
  $source=Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_CHART_RUNTIME\SAD_C2_P12_CHART_4d1f6da0544749b5bb92b4346300c025\SAD_C2_P12_GUIDED_CHART_TEMP.qvw'
  $pin='C8C3F24DAB56ABEEC0ABD0194A691FD78536BF8F550410E3C609262141A5B917'
  if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_MISSING'}
  if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $pin) {throw 'HARD_STOP_SOURCE_HASH_DRIFT'}
  $qlik='C:\Program Files\QlikView\Qv.exe'
  if (-not (Test-Path -LiteralPath $qlik -PathType Leaf)) {throw 'BLOCKED_QLIK_EXE'}
  Write-Host "PREFLIGHT=PASS HEAD=$head SOURCE_SHA256=$pin"
}
~~~

**Conferir que `HEAD` corresponde ao commit do PR deste gate antes do Prepare**; se a branch se mover depois de preparar, não executar o Verify com outra revisão. Parser validado no Windows ≠ GUI validada.

## 3. Prepare único com script versionado

O runner [`Invoke-SadC2PredispatchNegativePoc01.ps1`](../../tools/Invoke-SadC2PredispatchNegativePoc01.ps1) é derivado do guard do #205 e pinado à origem **nova**. Ele NÃO abre QlikView, não usa COM, não executa `Reload()`, não seleciona campos nem automatiza GUI. No PowerShell, após preflight:

~~~powershell
$repo=(Get-Location).Path
$source=Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_CHART_RUNTIME\SAD_C2_P12_CHART_4d1f6da0544749b5bb92b4346300c025\SAD_C2_P12_GUIDED_CHART_TEMP.qvw'
$runner=Join-Path $repo 'tools\Invoke-SadC2PredispatchNegativePoc01.ps1'
$qlik='C:\Program Files\QlikView\Qv.exe'
$runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2_PREDISPATCH_RUNTIME'
$evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2_PREDISPATCH_EVIDENCIAS'
New-Item -ItemType Directory -Force -Path $runtime,$evidence | Out-Null
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
$prepareExit=$LASTEXITCODE
Write-Host "PREPARE_EXIT_CODE=$prepareExit"
if ($prepareExit -ne 0) {throw 'BLOCKED_PREPARE_NO_RETRY'}
~~~

**Aceite do Prepare somente:** `VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI`, `PREPARE_EXIT_CODE=0`; guardar `GIT_HEAD`, `RUNNER_SHA256`, `RUNTIME_COPY`, `EVIDENCE_DIR`. Se falhar, STOP. O caminho da nova TEMP deve vir da saída real, nunca ser inventado. **Nenhum PASS visual/funcional foi obtido pelo Prepare.**

## 4. QlikView Desktop 12 — sequência única sem dispatch

**Ponto de controle antes de editar:** abrir **exclusivamente** a `RUNTIME_COPY` gerada. Verificar com captura `gui_before.png`: (a) ano real selecionado `2019`, `GetSelectedCount(PERIODO_ANO)=1`; (b) competência real sem seleção explícita, `GetSelectedCount(PERIODO_COMPETENCIA)=0`; (c) gráfico P1.2 2019 e CH02 histórico permanecem separados; (d) variáveis `vSAD_POC_Mode/Year/Month` realmente existentes; (e) ausência de mutações inesperadas e botões/eventos suspeitos. **Se qualquer item essencial divergir, fechar sem salvar e STOP; não clicar BU15 nem limpar filtros para "consertar".**

1. Somente na cópia nova, ajustar `vSAD_POC_Mode='MENSAL'`, `vSAD_POC_Year=2018`, `vSAD_POC_Month=1` pelas propriedades já existentes. Confirmar que **campos reais** continuam `2019/Qtd1` e competência `Qtd0`.
2. Criar **um botão novo** numa área vazia da interface guiada, legenda `POC — Aplicar competência (não clicar)`. Registrar o novo **Object ID** real; não reutilizar `BU15` nem editar botões antigos.
3. Propriedade `Condição para Habilitar` / `Enable Condition`, expressão de **estudo** abaixo. Confirmar `Expressão OK`; se o editor não permitir ou o resultado for ambíguo, STOP sem tentar outra fórmula:
   ~~~qlik
   =If(
     '$(vSAD_POC_Mode)'='MENSAL'
     and GetSelectedCount(PERIODO_ANO)=1
     and GetSelectedCount(PERIODO_COMPETENCIA)=0
     and Only(PERIODO_ANO)=Num($(vSAD_POC_Year))
     and Num($(vSAD_POC_Year))>=2017
     and Num($(vSAD_POC_Year))<=2019
     and Num($(vSAD_POC_Month))>=1
     and Num($(vSAD_POC_Month))<=12,
     1,0)
   ~~~
4. Propriedade Ações: configurar **somente uma** ação `Seleção → Selecionar no Campo`, no campo `PERIODO_COMPETENCIA`, com pesquisa candidata `=Num($(vSAD_POC_Year))*100+Num($(vSAD_POC_Month))`. Confirmar na GUI se o QlikView interpreta a expressão como esperada; **não clicar** para experimentar. Capturar `guard_properties.png` mostrando ID, condição, ação e campo; se precisar de mais de uma ação ou mudar o modelo para configurar, STOP.
5. Observar **botão desabilitado, condição 0, estado real 2019 preservado** com proposta `2018/01`; capturar `guard_blocked_2018.png`.
6. Sem clicar no botão, alterar **apenas** `vSAD_POC_Year=2019`; manter modo `MENSAL` e mês `1`. Condição deve retornar **1**, botão habilitado; ano real deve continuar `2019/Qtd1`, competência `Qtd0`; capturar `guard_enabled_2019.png`. Se não habilitar, `INCONCLUSIVE/BLOCKED`, STOP, **não substituir expressão**.
7. Alterar **somente** `vSAD_POC_Year=2018` e confirmar **0**, desabilitado novamente, campos reais intactos; capturar `guard_restored_2018.png`. Não clicar ou efetuar seleção temporal em nenhum estado.
8. Registrar `gui_notes.txt` no `EVIDENCE_DIR`: RunId, HEAD, runner SHA, novo botão ID, modo e ano/mês propostos, valores 0/1/0 observados, estado real antes/depois, ação não disparada, ressalva sobre mensagem e rotas nativas, eventual falha. **Uma única gravação (Ctrl+S) exclusivamente da nova TEMP**, fechar QlikView sem segundo salvamento. Em falha antes de completar o teste, fechar sem salvar salvo se necessário para preservar evidência de bug; jamais inventar PASS.

**Observação metodológica:** mostrar botão desabilitado **não prova sozinho** ausência de action dispatch. Guardar a configuração de ação e campos reais antes/depois; sem evidência suficiente, classificar `INCONCLUSIVE`. No cenário negativo, a proposta é incompatível com ano real 2019. Não usar triggers/rollback nem tentar corrigir conflito depois de aplicar seleção.

## 5. Verify uma vez, só depois de fechar QlikView

Apenas após concluir a rodada e guardar PNGs+notas. Usar **os caminhos reais** `RUNTIME_COPY` e `EVIDENCE_DIR` retornados, os mesmos argumentos e checkout/runner do Prepare:

~~~powershell
$runDir='<COLE_EVIDENCE_DIR_REAL_DO_PREPARE>'
if (@(Get-Process -Name qv,qlikview -ErrorAction SilentlyContinue).Count -gt 0) {throw 'BLOCKED_CLOSE_QLIKVIEW_FIRST'}
if (Test-Path -LiteralPath (Join-Path $runDir 'predispatch_verify.json')) {throw 'BLOCKED_VERIFY_ALREADY_RECORDED'}
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
$verifyExit=$LASTEXITCODE
Write-Host "VERIFY_EXIT_CODE=$verifyExit"
if ($verifyExit -ne 0) {throw 'BLOCKED_VERIFY_STOP_NO_RETRY'}
~~~

O Verify confere hash de origem, inventário de **25 canônicos**, SHA da cópia, manifesto do mesmo HEAD/runner e **presença**, não conteúdo, de `gui_before.png`, `guard_properties.png`, `guard_blocked_2018.png`, `guard_enabled_2019.png`, `guard_restored_2018.png` e `gui_notes.txt`. Sua saída `PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI` **não** comprova 0/1/0, o ID do objeto, nem que somente um botão mudou. Veredito GUI exige inspeção humana das capturas e notas.

## 6. Critérios de aceite e estado final máximo

| Classe | Critério |
| --- | --- |
| `PASS_RESTRICTED_PREDISPATCH_ONE_BUTTON` | 0/1/0 realmente observado no botão novo, seleção real 2019/competência sem seleção preservada, uma ação apenas configurada **não disparada**, fonte+25 protegidos intactos, nova TEMP salva e evidências legíveis |
| `INCONCLUSIVE_GUI_OR_REASON` | guarda ou variáveis não verificáveis, capturas/nota ausentes, mensagem de bloqueio não comprovada, estado real ambíguo |
| `BLOCKED` | guarda com erro, botão habilita na proposta conflitante, efeito colateral inesperado, QVW incorreta, ausência de variável/campo |
| `HARD_STOP_INTEGRITY` | SHA origem/25 protegidos/branch/runner divergente ou saída fora do escopo |
| `NOT_RUN` | runner e protocolo versionados sem execução Windows |

**Sem homologação implícita:** `C2_FULL=NO_GO_NOT_APPROVED`; `D2_GLOBAL=NO_GO_NOT_PROVEN`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. Não refazer PR #201/#203/#205, não criar segunda PoC/runner automático, não expandir para menu/bookmark ou C3/C4. Depois do veredito restrito, retornar a Issue #196 para decidir a cobertura final de rotas de seleção, **não** encerrar automaticamente C2.

---

## 7. Closeout físico reportado — 03/11/2026

**Resultado do gate de execução:** `CLOSED_WITH_LIMITS / VERIFY_INTEGRITY_PASS_LOCAL_REPORTED / GUI_BEHAVIOR_PARTIAL`. A prova máxima de `PASS_RESTRICTED_PREDISPATCH_ONE_BUTTON` **NÃO foi atribuída** porque a primeira observação do botão desabilitado, imediatamente após a criação, não teve captura com o objeto já presente; a sequência estrita cronológica `0→1→0` não está inteiramente documentada. O operador **confirmou explicitamente em 03/11/2026 que não clicou no botão `BU16`** durante todo o experimento. Trata-se de relato humano, não de log independente; prints e o runner não conseguem atestar isoladamente o despacho.

### 7.1 Identidade imutável da execução

| Elemento | Valor / proveniência |
| --- | --- |
| Branch e commit EXECUTADO no Windows | `test/sad-c2-integrated-predispatch-negative-20261103@8e977467676ee998998057316c6fad3112c92016` |
| SHA-256 do runner executado | `F19991D6D43EF267EC8ADA3364A127F49916F34588EC46394039352CF83E342E` |
| QlikView ProductVersion | `12.0.20000.0` |
| RunId | `SAD_C2_PREDISPATCH_d6f8664aac094bbe9e13a85ca79367c4` |
| QVW de origem | `SAD_C2_P12_GUIDED_CHART_TEMP.qvw`; SHA-256 `C8C3F24DAB56ABEEC0ABD0194A691FD78536BF8F550410E3C609262141A5B917` |
| QVW nova salva e verificada localmente | `SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw`; SHA-256 final `A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517` |
| Arquivos de evidência local | `C:\Users\pedro\Documents\SAD_C2_PREDISPATCH_EVIDENCIAS\SAD_C2_PREDISPATCH_d6f8664aac094bbe9e13a85ca79367c4` |

**Nota:** este closeout foi acrescentado **depois** da execução. O SHA/HEAD do PR após esta edição documental não substitui o commit e o hash do runner efetivamente executados; **não reexecutar Prepare/Verify** para "atualizar" o HEAD.

### 7.2 Verificação de integridade — transcrição do operador

~~~text
PREFLIGHT_VERIFY=PASS
GATE=SAD-C2-INTEGRATED-PREDISPATCH-NEGATIVE-POC-01
GIT_HEAD=8e977467676ee998998057316c6fad3112c92016
RUNNER_SHA256=F19991D6D43EF267EC8ADA3364A127F49916F34588EC46394039352CF83E342E
SOURCE_SHA256=C8C3F24DAB56ABEEC0ABD0194A691FD78536BF8F550410E3C609262141A5B917
QV_PRODUCT_VERSION=12.0.20000.0
QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0
PROTECTED_25_UNCHANGED=True
SOURCE_UNCHANGED=True
COPY_CHANGED_FROM_SOURCE=True
COPY_SHA256=A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517
GUI_EVIDENCE_MISSING=
EVIDENCE_DIR=C:\Users\pedro\Documents\SAD_C2_PREDISPATCH_EVIDENCIAS\SAD_C2_PREDISPATCH_d6f8664aac094bbe9e13a85ca79367c4
VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI
VERIFY_EXIT_CODE=0
~~~

**Veredicto de integridade:** `PASS_LOCAL_REPORTED` para fonte e 25 protegidos; `PASS_LOCAL_REPORTED` para presença de evidências e mudança binária da nova TEMP. O agente não abriu os bytes da QVW nem o JSON do Verify. O executor apenas examina **existência** dos arquivos PNG, não seu significado. SHA distinto da TEMP não demonstra sozinho quais objetos internos foram modificados. A primeira tentativa de Verify foi **bloqueada pelo preflight** por `gui_before.png` ausente no diretório correto; posteriormente o operador copiou 6/6 arquivos, conferiu menção a `BU16` e RunId em `gui_notes.txt`, e só então executou **um Verify válido**. Não houve segundo Verify.

### 7.3 GUI observada, fatos e limites

- Capturas examinadas na conversa registram o botão novo **`BU16`**, uma condição candidata com editor `Expressão OK`, uma ação configurada `Selecionar no Campo` para `PERIODO_COMPETENCIA` e expressão de pesquisa com `Expressão OK`. `Expressão OK` prova sintaxe aceita, não execução da ação.
- Proposta `MENSAL/2019/01`: botão azul, aparentemente **habilitado**. Ao retornar à proposta `MENSAL/2018/01`: botão cinza, **desabilitado**; captura sem diálogo mostra `ANO REAL=2019` (Qtd 1), `COMPETENCIA REAL` sem seleção explícita (Qtd 0).
- Proposta inicial `MENSAL/2018/01` foi capturada **antes** da criação do objeto; não existe captura inequívoca do primeiro `0` com `BU16` criado. `GUI_RESTRICTED_1_TO_0=SUPPORTED`; `STRICT_0_1_0=INCONCLUSIVE`.
- Em resposta à pergunta explícita se havia clicado em `BU16` mesmo quando habilitado, o operador respondeu **“não”** em 03/11/2026. `BUTTON_NEVER_CLICKED=OPERATOR_ATTESTED`. Esta evidência é **declaração do operador**, não validação técnica independente da ausência de ação; não altera `STRICT_0_1_0=INCONCLUSIVE`.
- Não há evidência de mensagem UX de incompatibilidade, nem de bloqueio global por menus nativos, busca, bookmarks, listas de outras QVWs e eventuais ações automatizadas. `UX_REASON=NOT_PROVEN`; `D2_GLOBAL=NO_GO_NOT_PROVEN`.

### 7.4 STOP e handoff

**Encerrar a execução física** sem nova GUI, Prepare, Verify, exportação, alteração de variáveis, segundo botão ou captura retroativa. Preservar o QVW novo e a origem com seus hashes e as evidências locais; PR #208 continua **Draft sem merge**, Issue #196 continua **OPEN**. **Confirmação de não clique recebida e registrada**. Não há pendência de proveniência do operador neste gate; permanecem apenas limitações probatórias e de escopo, sem reabrir execução física.

**Estados finais:** `WINDOWS_VERIFY_INTEGRITY=PASS_LOCAL_REPORTED`; `GUI_ENABLED_2019_DISABLED_2018=PASS_VISUAL_RESTRICTED`; `GUI_STRICT_0_1_0=INCONCLUSIVE`; `BUTTON_NEVER_CLICKED=OPERATOR_ATTESTED_NOT_INDEPENDENTLY_LOGGED`; `GATE_EXECUTION=CLOSED_WITH_LIMITS`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.


### 7.5 Adendo de proveniência — confirmação do operador

Em 03/11/2026, após o `Verify` (exit 0), o operador respondeu **“não”** à pergunta explícita: “Durante todo o experimento, você chegou a clicar no botão `BU16 — POC Aplicar competência`, mesmo quando ele estava habilitado?”. Registro: `BUTTON_NEVER_CLICKED=OPERATOR_ATTESTED`. Essa confirmação encerra a pendência de declaração do operador, **sem provar ausência de dispatch por log automático**. Mantêm-se `GUI_STRICT_0_1_0=INCONCLUSIVE`, `GATE_EXECUTION=CLOSED_WITH_LIMITS` e `C2_FULL=NO_GO_NOT_APPROVED`. Não repetir nem reexecutar `-Verify`.
