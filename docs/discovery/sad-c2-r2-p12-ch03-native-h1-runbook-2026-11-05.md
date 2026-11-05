# SAD C2 D2-R2 — P1.2 CH03 / pós-seleção nativa H1

**Gate:** `SAD-C2-R2-P12-CH03-NATIVE-H1-01`  
**Situação:** `RUNBOOK_VERSIONED_PHYSICAL_NOT_RUN`; autorização de prosseguir no gate em 05/11/2026, **sem merge e sem autorização de modificar QVW/QVD canônicos**.  
**Base documental:** `main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83`; V3 D2-R2 (somente D2); V2 para P5 e demais contratos; Boundary 7 (C2 → C3 → C4 → GO IX).  
**Branch:** `test/sad-c2-r2-p12-ch03-native-h1-20261105`.  
**Único objeto sob avaliação funcional:** `CH03` (P1.2 evolução guiada); `TX16` não substitui prova de CH03. Não repetir P1.1, CH02, BU16, 12/12, H0/H1/H2 do #221 nem oráculos.

## 1. Estado de entrada / origem local pinada

O comentário de closeout do [PR #221](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/221#issuecomment-6661655641) registra `PASS_RESTRICTED_P11_H0_H1_H2`, limitado a quatro cartões, e a **cópia TEMP salva**, não um QVW canônico. Origem candidata para este gate:

- `C:\Users\pedro\Documents\SAD_C2_P11_H1_RUNTIME\SAD_C2_P11_H1_d6723bea5c7b43928e324b773c51a409\SAD_C2_R2_P11_HISTORICAL_CARDS_H1_TEMP.qvw`
- SHA-256 esperado: `E38C41B3F9CEECC3E4964CB91E5FE8C17FD608FA32CB5612DC2907E82348296E`.
- QlikView Desktop esperado: `12.0.20000.0`; 10 QVDs de extração + 12 QVDs de transformação + 3 QVWs canônicos protegidos.
- A cópia foi salva no cenário H2 e **pode manter** seleção de `SERV_COD_DATASUS_6=250750` além de `PERIODO_ANO=2019` / `PERIODO_COMPETENCIA=201901`. Tratar estado persistido como **não verificado até abrir a nova cópia**; não assumir que o H1 está pronto.
- A existência do arquivo e seu hash só podem ser confirmados no Windows do operador. Se ausente, divergente ou inacessível, `BLOCKED_SOURCE` e STOP. Não substituir por outra QVW sem novo contrato.

**Invariantes:** Star/3 fatos/8 dimensões e grãos, QVDs, QVW de origem, 3 QVWs canônicos, Blueprint, V3/V2, P5, C3/C4, produção e `main` intactos. Sem COM, reload, novas fontes ou objetos finais.

## 2. Objetivo e hipótese única

Com **seleções reais nativas** `PERIODO_ANO=2019` e `PERIODO_COMPETENCIA=201901`, sem filtro de serviço, e com proposta `vSAD_POC_Mode=EVOLUCAO` / `vSAD_POC_Year=2019`, o gráfico `CH03` deve ficar **sem série publicada como válida** e possuir **motivo visível associado à própria visualização**, reconhecendo a competência mensal explicitamente selecionada.

A condição de cálculo de `CH03` identificada no inventário do [PR #219](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/219) rejeita `GetSelectedCount(PERIODO_COMPETENCIA)>0`, mas a mensagem genérica “Condição de cálculo não satisfeita” **não satisfaz sozinha** o contrato V3. Não reexecutar o 12/12 do CH03 em cenário positivo.

**Hipótese física única se faltar motivo:** adicionar exatamente **um novo Text Object diagnóstico** próximo de CH03, somente na QVW TEMP, com o texto calculado pelo estado real; não alterar o Chart, a condição de cálculo, títulos, dados, expressões existentes ou objetos históricos. Confirmar antes que o novo Object ID não colide com outro. A mensagem deve ser clara ao lado do gráfico e legível no PNG. Exemplo candidato a inserir em Text Object (a validar no QlikView 12; não declarar expressão homologada por inspeção):

```qlik
=If(
  '$(vSAD_POC_Mode)'='EVOLUCAO'
  and GetSelectedCount(PERIODO_ANO)=1
  and Only(PERIODO_ANO)=Num($(vSAD_POC_Year))
  and GetSelectedCount(PERIODO_COMPETENCIA)>0,
  'Indisponível nesta evolução guiada — existe seleção mensal aplicada.',
  'CH03/H1: contexto fora do escopo desta prova.'
)
```

Este texto **não homologa** outros estados nem a matriz P5. Se a hipótese falhar, STOP; não tentar alterar CH03 ou criar segunda expressão.

## 3. Preflight Windows PowerShell 5.1 — sem operação de GUI

Executar somente na raiz local do repositório, com QlikView fechado. O `git fetch/switch` abaixo **não faz merge na main**. Se worktree suja, conflito local, drift de HEAD ou arquivo preexistente, STOP sem `reset/clean/stash`.

```powershell
$ErrorActionPreference = 'Stop'
$branch = 'test/sad-c2-r2-p12-ch03-native-h1-20261105'
if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
git fetch origin "refs/heads/$($branch):refs/remotes/origin/$branch"
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_FETCH' }
git show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) { git switch $branch } else { git switch --track "origin/$branch" }
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_SWITCH' }
$head = ([string](git rev-parse HEAD)).Trim()
$remote = ([string](git rev-parse "origin/$branch")).Trim()
if ($head -cne $remote) { throw 'BLOCKED_HEAD_DRIFT' }
if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_AFTER_SWITCH' }
$repo = (Get-Location).Path
$runner = Join-Path $repo 'tools\Invoke-SadC2R2P12CH03NativeH101.ps1'
$tokens=$null; $errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
if (@($errors).Count -gt 0) { $errors; throw 'BLOCKED_POWERSHELL_PARSER' }
Write-Host "GIT_HEAD=$head"
Write-Host "RUNNER_SHA256=$((Get-FileHash -LiteralPath $runner -Algorithm SHA256).Hash)"

$source = Join-Path $env:USERPROFILE 'Documents\SAD_C2_P11_H1_RUNTIME\SAD_C2_P11_H1_d6723bea5c7b43928e324b773c51a409\SAD_C2_R2_P11_HISTORICAL_CARDS_H1_TEMP.qvw'
$qvExe = 'C:\Program Files\QlikView\Qv.exe'
$runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_CH03_H1_RUNTIME'
$evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_CH03_H1_EVIDENCE'
foreach ($p in @($runtime,$evidence)) {
    if (Test-Path -LiteralPath $p) { throw "BLOCKED_EXISTING_ROOT: $p" }
    New-Item -ItemType Directory -Path $p | Out-Null
}
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
Write-Host "PREPARE_EXIT_CODE=$LASTEXITCODE"
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_PREPARE' }
```

Exigir `PREPARE_EXIT_CODE=0`, `VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI`, `SOURCE_SHA256=E38C41B3F9CEECC3E4964CB91E5FE8C17FD608FA32CB5612DC2907E82348296E`; guardar os caminhos **impressos** `RUNTIME_COPY`, `EVIDENCE_DIR`, commit e SHA do runner. Preparar uma vez, no máximo uma QVW TEMP.

## 4. Uma rodada GUI — somente RUNTIME_COPY

1. Abrir exclusivamente a QVW indicada por `RUNTIME_COPY`. Observar `CH03`, seleção atual, modo/ano propostos e filtros não temporais. Salvar `initial_state.png` em `EVIDENCE_DIR`. **Não** abrir/salvar a fonte ou QVW canônico.
2. Se `SERV_COD_DATASUS_6=250750` estiver selecionado por persistência do H2 anterior, retirar **somente este filtro** por rota nativa em uma lista transitória; não usar Limpar Tudo. Nenhum outro filtro não temporal pode permanecer. Se não for possível obter H1 sem afetar ano/competência, `INCONCLUSIVE_SETUP`, STOP. Não retestar P1.1 nem CH02.
3. Confirmar seleção **real** exata `PERIODO_ANO=2019` (um) e `PERIODO_COMPETENCIA=201901` (um). Se seleção estiver ausente, somente configurar esses dois campos por listas temporárias, sem clicar BU16; caso algum campo/valor não exista, STOP. Ajustar **apenas variáveis de proposta** pelos Input Boxes já existentes para `EVOLUCAO` e `2019`, se necessário. Proposta não substitui a seleção real. Verificar os quatro valores (dois campos reais, modo e ano propostos) em screenshot `h1_real_state.png`. Não utilizar seleção em CH02/gráficos como atalho.
4. Observar CH03 **antes de editar**, capturar `ch03_before.png`: deve não publicar série incompatível; registrar texto/motivo efetivo. Se já houver **motivo específico legível**, marcar `NO_EDIT_REQUIRED`; não salvar TEMP. Se exibir número/série stale como válida, `BLOCKED_STALE_CH03`, STOP.
5. Se estiver apenas com mensagem genérica, adicionar **um único Text Object** de diagnóstico com a expressão candidata §2. Confirmar seu ID exclusivo, expressão literal, mensagem específica, ausência de série stale e proximidade/legibilidade junto a CH03. Capturar `ch03_diagnostic_expression.png` e `ch03_after.png`. Se expressão, contexto ou mensagem divergirem, `BLOCKED_DIAGNOSTIC`, STOP sem segunda hipótese.
6. Remover todas as listboxes criadas **nesta rodada**, sem limpar seleção temporal. Conferir que o gráfico CH03 e os objetos existentes não foram modificados; capturar `transient_objects_removed.png` quando houver Save. Gerar `gui_notes.txt` em `EVIDENCE_DIR`: RunId/HEAD/SHA da fonte; estado antes/depois (real versus proposto); filtros; texto antes/depois; ID diagnóstico e fórmula; objetos transitórios removidos; decisão de salvar; veredito; nomes dos PNGs e qualquer limitação.
7. Salvar **uma única vez** apenas a QVW TEMP, exclusivamente se o novo Text Object funcionar e todos os critérios acima forem cumpridos. Se `NO_EDIT_REQUIRED`, fechar **sem salvar**. Se `BLOCKED/INCONCLUSIVE`, fechar **sem salvar**. Nenhuma outra edição, reload, COM ou arquivo do projeto.

## 5. Verify único após fechar QlikView

Na mesma sessão PowerShell, após fechamento do Desktop. Não executar Verify novamente para reparar manifestos históricos, nem repetir GUI/cenas.

```powershell
$runDir = Read-Host 'Cole EVIDENCE_DIR impresso pelo Prepare'
if (-not (Test-Path (Join-Path $runDir 'c2_p12_ch03_h1_prepare.json'))) { throw 'BLOCKED_WRONG_RUN_DIR' }
if (Test-Path (Join-Path $runDir 'c2_p12_ch03_h1_verify.json')) { throw 'BLOCKED_VERIFY_ALREADY_RECORDED' }
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
Write-Host "VERIFY_EXIT_CODE=$LASTEXITCODE"
```

O Verify exige SHA da fonte e 25 canônicos preservados, grava SHA da TEMP e inventaria `initial_state.png`, `h1_real_state.png`, `ch03_before.png`, `gui_notes.txt`; se houve Save, exige ainda `ch03_after.png`, `ch03_diagnostic_expression.png`, `transient_objects_removed.png`. Seu `PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI` **não valida semanticamente** imagens nem prova que apenas um objeto foi editado. As capturas e notas devem ser examinadas separadamente antes do veredito funcional.

## 6. Veredito e STOP

- `PASS_RESTRICTED_CH03_NATIVE_H1` **somente** com seleção temporal real e proposta demonstradas, CH03 sem série válida obsoleta, mensagem mensal específica junto ao CH03, proteção de fonte/25 canônicos, origem e cópia identificadas, evidências GUI revisadas e nenhum objeto histórico editado.
- `BLOCKED`: dado stale apresentado como válido; erro na hipótese única, objeto existente modificado, fonte/canônicos alterados, SHA incoerente.
- `INCONCLUSIVE`: origem indisponível, seleção real/proposta não comprovada, filtro extra que não pode ser removido, screenshots insuficientes ou execução Windows ausente.
- **STOP** após 1 Prepare, 1 QVW TEMP, 1 contexto H1, no máximo 1 Text Object novo, 1 Save opcional e 1 Verify, ou na primeira falha crítica. Sem nova tentativa automática.

**Governança:** `C2_GUIDED_R2=NOT_APPROVED_GLOBAL`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `C3/C4=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Este gate não faz merge nem altera `main`.

### Roteamento operacional

- **Agente:** preparação ChatGPT GPT-6 + GitHub (esforço efetivo não exposto); execução físico-visual: operador Windows/QlikView 12, fallback Codex Local/Work Local apenas se acesso e interação demonstrarem disponibilidade.
- **Permissão:** scripts e runbook em nova branch Draft; único arquivo editável na GUI é QVW TEMP externa, para um Text Object novo; hashes de origem e canônicos apenas leitura.
- **Evidência:** PREPARE/VERIFY stdout, SHA-256, manifests JSON, capturas PNG e `gui_notes.txt` fora do Git; `main` inalterada.
- **Escalonamento:** só por falha concreta de parser, execução, seleção, mensagem ou segurança; nenhum teste novo automático.
