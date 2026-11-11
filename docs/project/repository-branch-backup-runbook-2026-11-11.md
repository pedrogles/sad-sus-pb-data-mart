# SAD — Backup e dry-run auditável de branches Git (11/11/2026)

**Status:** `DRAFT_PREPARED_NOT_LOCAL_EXECUTED`. Não constitui permissão de excluir qualquer branch.

## 1. Objetivo e fonte de verdade

Preparar uma cópia restaurável de **todas as referências remotas de branches** do repositório `pedrogles/sad-sus-pb-data-mart`, sem modificar a `main`, as branches existentes ou arquivos QVW/QVD/PDF. Documentar, por SHA e grau de risco, quais refs poderiam ser propostas para exclusão futura.

Base remota inspecionada pelo conector GitHub antes de criar a branch desta PR: `main@e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9`, **161 refs**, **0 PRs abertos** e **0 issues abertas**, das quais:

| Classe pela associação a PR (snapshot) | Quantidade | Ação neste gate |
| --- | ---: | --- |
| `MERGED_PR` | **102** | Apenas candidatura preliminar; exigir `git merge-base --is-ancestor` contra main após backup |
| `CLOSED_UNMERGED_PR` | **53** | `HOLD`; histórico com commits potencialmente exclusivos |
| `NO_PR` | **5** | `HOLD`; correções órfãs exigem avaliação separada |
| `MAIN` | **1** | `PROTECT`; jamais excluir |
| **Total** | **161** | Nenhuma exclusão nesta etapa |

**Snapshot imutável:** [repository-branch-inventory-2026-11-11.json](repository-branch-inventory-2026-11-11.json), com nome/SHA/status de PR/ref. A criação da branch `chore/sad-branch-backup-readonly-2026-11-11` **após o snapshot** significa que consultas remotas posteriores devem encontrar pelo menos uma ref `NEW_SINCE_SNAPSHOT`. Ela **deve ser retida, mesmo se também estiver no backup**.

A correspondência de HEAD entre PR merged e branch atual é **necessária, mas não suficiente** para concluir que a branch é ancestral da main: merges squash/rebase e branches divergentes podem conter commits exclusivos. Não excluir sem prova de ancestralidade ou decisão deliberada de arquivamento.

## 2. Artefatos versionados nesta PR

- `tools/Get-SadBranchCleanupDryRun.ps1` — **atualização do executor existente**, agora com contrato do snapshot v2 de 161 refs. Executa somente `git remote get-url` e `git ls-remote --heads` sobre `origin`, sem fetch/push/delete/merge; escreve CSV+JSON **fora do repo**.
- `tools/Invoke-SadGitBranchBackup.ps1` — executor **novo** de backup local em área isolada, com `-BackupVerify` explícito. Cria clone bare `--mirror`, bundle `--all`, verifica o bundle, **restaura em outro clone bare**, confere 1:1 os HEADs das branches (antes, mirror, restore, depois) e executa teste de ancestralidade somente no mirror. Nenhuma mutação remota.
- Este runbook e o snapshot canônico. Não incluímos um executor de exclusão.

**Testes:** o encadeamento Git `clone --mirror → bundle create --all → bundle verify → clone --mirror do bundle → comparação de refs` foi reproduzido separadamente em **fixture sintética local Linux**, demonstrando preservação dos refs de teste. **O PowerShell 5.1 e a autenticação GitHub do Windows do responsável não foram executados/validados aqui**. O PASS físico do backup depende da saída real e dos relatórios de execução do operador.

## 3. Pré-condições no Windows

- Git para Windows funcionando, com acesso autorizado à origem `https://github.com/pedrogles/sad-sus-pb-data-mart.git`; se a autenticação for exigida, utilizar mecanismo de credenciais instalado, **sem inserir token em URLs ou logs**.
- PowerShell 5.1 ou superior; repositório local `C:\Users\pedro\documents\programming\sad-sus-pb-data-mart` com `origin` apontando exclusivamente ao repositório canônico.
- Antes de executar, **obter os scripts do commit versionado desta PR**. Nunca executar uma cópia desatualizada do executor antigo que exige inventário de 159 refs. Não é necessário fazer checkout de uma branch de experimento QlikView.
- Pasta externa de evidência (padrão `C:\Users\pedro\SAD_REPO_HYGIENE_EVIDENCIAS`) com espaço para **um mirror, um bundle completo e um clone bare restaurado**. Não guardar artefatos na árvore versionada.
- **Nenhum merge desta PR antes da execução local ou sem autorização separada.** A `main` pinada no snapshot deve continuar em `e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9`; se avançar, `BLOCKED` e atualizar snapshot mediante novo gate.

## 4. Execução controlada — sem exclusão

**Preferência: testar ANTES do merge desta PR.** O snapshot fixa o SHA da `main` anterior à PR. Se a PR for integrada primeiro, o HEAD da `main` mudará e os scripts bloquearão a execução como drift (comportamento intencional). Em vez de mudar de branch no checkout principal, obtenha os scripts versionados numa cópia externa isolada:

```powershell
$repo = "$env:USERPROFILE\documents\programming\sad-sus-pb-data-mart"
$evidence = Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS'
$runner = Join-Path $evidence 'runner-pr239-readonly'

# Clone separado: não altera o checkout principal nem arquivos QlikView.
# Falha em vez de sobrescrever se runner já existir.
git clone --single-branch --branch chore/sad-branch-backup-readonly-2026-11-11 `
  https://github.com/pedrogles/sad-sus-pb-data-mart.git $runner
if ($LASTEXITCODE -ne 0) { throw 'CLONE_RUNNER_FAILED' }

$snapshot = Join-Path $runner 'docs\project\repository-branch-inventory-2026-11-11.json'

# Etapa 1: apenas compara SHAs do snapshot com o GitHub
powershell.exe -NoProfile -File (Join-Path $runner 'tools\Get-SadBranchCleanupDryRun.ps1') `
  -RepoRoot $repo -InventoryPath $snapshot -EvidenceRoot $evidence
if ($LASTEXITCODE -ne 0) { throw 'DRY_RUN_BLOCKED' }

# Etapa 2: cria mirror+bundle+restore SOMENTE no EvidenceRoot externo
powershell.exe -NoProfile -File (Join-Path $runner 'tools\Invoke-SadGitBranchBackup.ps1') `
  -RepoRoot $repo -InventoryPath $snapshot -EvidenceRoot $evidence -BackupVerify
if ($LASTEXITCODE -ne 0) { throw 'BACKUP_VERIFY_BLOCKED' }
```

O Git clone do runner e a criação do mirror/bundle escrevem **apenas na pasta externa**. A execução não altera `main` nem o checkout de trabalho principal, embora use a sua configuração local de `origin` para conferir SHAs. Confirme que há espaço em disco para todos os clones e bundle antes da segunda etapa. **Não executar operações de remoção.**

No estado esperado **antes de novo merge ou commits de branches antigas**, o dry-run deve mostrar `PRELIMINARY_MERGED_CANDIDATES=102`, `NEW_REFS_HELD>=1`, `DRIFTED_REFS=0`, e `NO_REMOTE_MUTATIONS=True`. Isso é previsão, **não saída já observada**. O backup deve recuperar todas as refs vivas, inclusive a branch criada depois do snapshot. A contagem exata atual deve vir dos relatórios, não de uma suposição.

**Atenção:** `-BackupVerify` grava dados locais externos (mirror, bundle e restore). Não roda no QlikView e não recarrega dados. Não é backup dos QVD/QVW/PDF armazenados fora do Git.

## 5. PASS, BLOCKED e STOP

**`PASS_READ_ONLY_PROVISIONAL`** exige: nenhum SHA das 161 refs pinadas divergente, `main` idêntica, CSV/JSON auditáveis, nenhuma exclusão. Classe `MERGED_PR` continua apenas candidata.

**`PASS_LOCAL_BUNDLE_AND_INDEPENDENT_RESTORE`** exige: clone mirror 1:1 com refs remotas de início, bundle completo com `bundle verify` PASS, novo clone bare restaurado com as **mesmas refs e SHAs**, refs remotas estáveis antes/depois, SHA-256 do bundle registrado, CSV com ancestralidade e `remote_mutations=false`.

**`BLOCKED`** se houver SHA diferente, branch ausente, origem inesperada, falta de acesso Git, erro no bundle/restore, divergência de refs, ambiente PowerShell indisponível ou artefatos salvos dentro do repositório. Não suprimir o erro e não repetir indefinidamente; corrigir causa única.

**STOP deste gate:** gerar os relatórios locais, inspecionar o resumo e **não executar qualquer exclusão**. Proteção extra para os 24 blobs não integrados dos oito PRs acadêmicos (21 da #226, 2 da #230 e 1 da #234): as branches associadas entram em `HOLD`, mesmo com bundle, até verificar retenção e decisão explícita.

## 6. Decisão futura separada

Apenas depois de prova física de backup/restauração, atualizar a matriz de risco dos 102 candidatos merged com o resultado real do `merge-base`. Excluir no máximo o lote nominal com SHAs aprovados expressamente, após rever proteção e HEAD imediatamente antes da remoção. `53 CLOSED_UNMERGED_PR` e `5 NO_PR` continuam em `HOLD`.

**Nenhum executor de remoção está presente nesta PR.** `C2_C3_C4_GLOBAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.
