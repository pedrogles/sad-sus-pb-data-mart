# SAD C2 — handoff físico controlado: despacho temporal dinâmico

**Gate:** `SAD-C2-GUIDED-DYNAMIC-DISPATCH-POC-01`  
**Baseline:** `main@238d4f70c5cf4576808fdd43af4a3d72b4e0b7cc` (PR #200 integrado).  
**Estado desta preparação:** `SCRIPT_VERSIONED_BRANCH_ONLY / WINDOWS_NOT_RUN / PHYSICAL_NOT_AUTHORIZED_BY_THIS_DOCUMENT`.  
**Agente:** Codex Local no Windows (PowerShell 5.1 + QlikView 12); fallback: operador humano. Registrar modelo/esforço realmente disponíveis na execução. GPT-6/GitHub elaborou este protocolo, sem acesso à GUI local.

## Objetivo único e STOP

Verificar em **nova cópia TEMP** se um controle candidato com guarda genérica no recorte 2017–2019 permite **uma única seleção real** `PERIODO_ANO=2019` com proposta `EVOLUCAO/2019`, quando inicialmente não existem seleções temporais explícitas. Conferir `PERIODO_COMPETENCIA` sem seleção explícita e preservar os demais filtros. **Não** validar gráfico de 12 competências, alterar `CH02`, P5, D2 global, outros anos, fatos, chaves ou Fase IX.

**Autorização:** gerar/commitar runner e roteiro **não é permissão para executá-los**. Antes de executar fisicamente, obter autorização específica do responsável e revisar este PR. Se algum pré-requisito não se confirmar, STOP sem ampliar tentativas.

**Fonte de verdade:** [AGENTS](../../AGENTS.md) → [current-state](../project/current-state.md) → [requirements](../academic/requirements.md) → [contrato integrado](sad-c2-guided-dynamic-control-design-2026-10-30.md) → [automação](../project/qlikview-powershell-automation.md) → [PR #199 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/199) (apenas prova anterior, não código adotado). Preservar V2 §62.3/§62.6 e C2→C3→C4 do Boundary 7.

## Runner versionado e fronteira

[`tools/Invoke-SadC2GuidedDynamicDispatchPoc01.ps1`](../../tools/Invoke-SadC2GuidedDynamicDispatchPoc01.ps1), Windows PowerShell 5.1, dois modos:
- `-Prepare`: **uma** cópia de `SAD_P11P12_VISUAL_POLISH_COPY.qvw` (SHA-256 esperado `B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C`), manifesto e inventário/hashes dos **25 protegidos** (10 QVDs EXTRACAO + 12 QVDs TRANSFORMACAO + 3 QVWs canônicos).
- `-Verify`: mesmo manifest/HEAD/runner, hashes da origem e protegidos depois da sessão. A cópia TEMP **pode mudar** porque nela será salvo um botão experimental. O runner não lê propriedades da GUI e **nunca** declara PASS funcional por si só.

A origem deve estar fora do Git, com nome e SHA exigidos. Runtime e evidências **externos ao Git**, distintos e preexistentes. O runner exige branch exata, base ancestral, commit do runner, checkout limpo, QlikView fechado no Prepare e no Verify, caminho absoluto de Qv.exe e versão 12. Não roda COM, clique, reload, macro ou Save de QVW.

**Proibido:** salvar a origem, reabrir/modificar os três QVWs canônicos, regenerar QVDs, limpar seleções silenciosamente, alterar BU13/CH02, reaproveitar o manifesto do #199, criar novas tentativas automaticamente ou executar sem autorização física.

## Procedimento PowerShell local — após autorização

Abrir **Windows PowerShell 5.1** na raiz do repo local. Conferir que a branch deste PR já está em checkout limpo; **não** fazer `git clean`, `reset --hard`, `stash` ou checkout forçado. As pastas externas indicadas são **exemplos da instalação já documentada**, não caminhos garantidos: validar com `Test-Path` antes.

~~~powershell
$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$source = Join-Path $env:USERPROFILE 'Documents\SAD_P11P12_VISUAL_POLISH_RUNTIME\SAD_P11P12_VISUAL_f673cac03dea40f292fb202ff903521a\SAD_P11P12_VISUAL_POLISH_COPY.qvw'
$qlik = 'C:\Program Files\QlikView\Qv.exe'
$runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_DYNAMIC_RUNTIME'
$evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_DYNAMIC_EVIDENCIAS'
$runner = Join-Path $repo 'tools\Invoke-SadC2GuidedDynamicDispatchPoc01.ps1'
git rev-parse HEAD
git branch --show-current
git status --short
Get-FileHash -LiteralPath $source -Algorithm SHA256
Test-Path -LiteralPath $qlik -PathType Leaf
New-Item -ItemType Directory -Force -Path $runtime,$evidence | Out-Null
$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
if ($parseErrors.Count -gt 0) { $parseErrors; throw 'BLOCKED_POWERSHELL_PARSER' }
~~~

Não continuar se a branch/HEAD não corresponder ao commit versionado deste PR, se o SHA da fonte divergir ou se o parser retornar erro. Registrar `git rev-parse HEAD` e SHA-256 do runner.

**Prepare — executar uma vez:**

~~~powershell
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_PREPARE_STOP' }
~~~

Copiar exatamente o `RUNTIME_COPY` e o `EVIDENCE_DIR` impressos pelo runner. Não reutilizar o diretório do PR #199. Um caminho diferente de fonte requer novo preflight, não substituição arbitrária.

## GUI em TEMP — uma tentativa

1. **Abrir somente `RUNTIME_COPY`** no QlikView 12 e confirmar documento certo (nome, folhas, origem de cópia). Parar diante de restauração/conversão/licença ou seleção prévia temporal; nunca clicar `Limpar Tudo` para fabricar estado inicial. Estado de entrada: `vSAD_POC_Mode=EVOLUCAO`, `vSAD_POC_Year=2019`, `GetSelectedCount(PERIODO_ANO)=0` e `GetSelectedCount(PERIODO_COMPETENCIA)=0`; outros filtros devem ser capturados e avaliados, sem presumir compatibilidade.
2. Na folha `POC - Interface Guiada`, **criar um botão candidato distinto de `BU13`, exclusivamente nesta cópia TEMP**. Registrar novo ID e uma única ação do tipo `Seleção → Selecionar no Campo`, campo `PERIODO_ANO`, pesquisa `=Num($(vSAD_POC_Year))`. Não adicionar Clear, macro, trigger, bookmark, sequência de ações ou seleção de competência.
3. Propor **somente como expressão de habilitação candidata** (não é fórmula homologada):

~~~qlik
=If(
 Match('$(vSAD_POC_Mode)','ANUAL','EVOLUCAO')>0
 and Match('$(vSAD_POC_Year)','2017','2018','2019')>0
 and GetSelectedCount(PERIODO_ANO)=0
 and GetSelectedCount(PERIODO_COMPETENCIA)=0,
 1,0)
~~~

Esse predicado é genérico apenas dentro dos anos e dos modos indicados. **Não certifica** proteção contra outras rotas, conflito com filtros não temporais ou atomicidade do QlikView. Se a condição não for avaliada/habilitada sem erro, STOP e documentar.
4. **Salvar apenas a TEMP** depois de configurar o botão, antes do teste, para manter a prova do objeto candidato. Capturar propriedades/condição/ação em `gui_condition_action.png` e o estado anterior em `gui_before.png`. Não alterar o gráfico `CH02`.
5. Pressionar **uma vez** o novo botão. Capturar `gui_after.png` com o diagnóstico real: `ANO REAL=2019 / Qtd 1` e `COMPETENCIA REAL=SEM SELECAO / Qtd 0`; registrar filtros não temporais pré/pós. Caso haja divergência, STOP; não limpar nem fazer segundo clique.
6. Registrar em `gui_notes.txt`: hora local, QVW TEMP, ID, expressão e ação literais, filtros pré/pós, observação de estado, problema/resultado, operador e modelo/esforço efetivos (quando aplicáveis). Fechar QVW **sem salvar as seleções pós-clique**. Conservar a TEMP modificada somente pela configuração experimental.

Salve capturas e notas **dentro do `EVIDENCE_DIR`**, não no Git. Se faltar screenshot, descrever a falta; não inventar PASS.

**Verify — depois de fechar QlikView, uma vez, na mesma branch e HEAD:**

~~~powershell
$runDir = '<COLE_AQUI_O_EVIDENCE_DIR_DE_PREPARE>'
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_VERIFY_STOP' }
~~~

**Não converter** `PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI` em PASS funcional. O `COPY_CHANGED_FROM_SOURCE=True` sozinho comprova apenas alteração binária da cópia, não que as propriedades ou seleções estejam corretas. Se `COPY_CHANGED_FROM_SOURCE=False`, verificar no material do gate por que não houve salvamento de configuração; não repetir sem decisão.

## Critérios de aceite e encerramento

| Resultado | Critério |
| --- | --- |
| `PASS_VISUAL_RESTRICTED_SINGLE_NO_SELECTION_TO_EVOLUTION_2019` | Uma ação real, `PERIODO_ANO=2019` explícito, competência sem seleção explícita, filtros não temporais preservados, propriedades e PNGs pré/pós completos, fonte + 25 protegidos íntegros e origem/HEAD/runner rastreados. É classificação posterior da revisão das evidências, **não** do script. |
| `BLOCKED` | Controle desabilitado, GUI indisponível, estado incompatível, problema de licenciamento, alteração indevida, script bloqueado ou falta de autorização. |
| `INCONCLUSIVE` | Ausência de captura, HASH, manifesto, transcrição literal ou comparação de seleções. |
| `HARD_STOP` | SHA da fonte ou dos protegidos divergente, escrita em canônico, novo escopo, mudança de semântica. |

**STOP:** exatamente uma cópia, um botão candidato, uma ação temporal e um `Verify`; sem repetir gates antigos, validar 12 meses, recalcular fatos, alterar C2→C3→C4 ou promover produção.

**Estados preservados:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.
