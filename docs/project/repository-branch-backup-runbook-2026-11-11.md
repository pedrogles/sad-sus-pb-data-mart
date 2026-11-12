# SAD — Backup e dry-run auditável de branches Git (11/11/2026)

**Status:** `PASS_LOCAL_OPERATOR_REPORTED_BACKUP_AND_RESTORE` (ver [resultado local de 11/11](repository-branch-backup-operator-result-2026-11-11.md)). Os comandos abaixo são o procedimento histórico já executado, **não um pedido de nova execução**. A prova permanece restrita ao texto do PowerShell do operador; nenhum manifesto local foi inspecionado independentemente. Não autoriza excluir branches.

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
- Este runbook e o snapshot canônico; `tools/Invoke-SadFinalBranchCleanup.ps1` foi **adicionado posteriormente** como executor de limpeza com `Mode=Preview` por padrão e com travas explícitas para qualquer exclusão. **Não foi executado no Windows, não representa autorização de exclusão.**

**Testes:** o encadeamento Git `clone --mirror → bundle create --all → bundle verify → clone --mirror do bundle → comparação de refs` foi reproduzido separadamente em **fixture sintética local Linux**, demonstrando preservação dos refs de teste. **O teste no Windows foi posteriormente executado pelo responsável**, que reportou `PASS_READ_ONLY_PROVISIONAL` com 162 refs e `PASS_LOCAL_BUNDLE_AND_INDEPENDENT_RESTORE` também com 162 refs; `4` branches merged ancestrais e `98` não ancestrais. Consulte o [closeout reportado](repository-branch-backup-operator-result-2026-11-11.md); o agente **não examinou diretamente o bundle ou manifestos locais**.

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
if (-not (Test-Path -LiteralPath $evidence)) {
  New-Item -ItemType Directory -Path $evidence -ErrorAction Stop | Out-Null
}
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

**O executor de remoção agora existe somente na branch desta PR, em modo PREVIEW por padrão; não foi executado.** O bundle foi gerado antes de novas atualizações documentais nesta branch; portanto o SHA atual da branch de preparação pode diferir do HEAD dela incluído no bundle. Ela só pode ser removida **após merge confirmado da PR #239**. Não repetir automaticamente o backup sem falha concreta; o bundle original mantém as 160 branches antigas com SHA pinado. `C2_C3_C4_GLOBAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## 7. Lote final preparado — decisão única pendente (sem execução)

O responsável pediu encerrar rapidamente a higiene das branches; a triagem remota nominal e o snapshot de 161 refs foram revalidados. O executor [Invoke-SadFinalBranchCleanup.ps1](../../tools/Invoke-SadFinalBranchCleanup.ps1) foi incluído **sem acionamento automático**. Ele confere os 161 nomes/SHAs originais com GitHub e com o bundle (`SHA256=1DC499D992C0414664FFC59298770767DCA40E872070ED314E300AFD045CB21A`), verifica a `main` e a branch #239, bloqueia refs novas e usa `git push --force-with-lease` SHA a SHA.

### Opções de limpeza oferecidas ao responsável

| Modo | Branches removíveis sob aprovação específica | Semântica |
| --- | ---: | --- |
| `Preview` (default) | **0** | apenas CSV/JSON com 102 merged, 53 closed-unmerged e 5 órfãs |
| `DeleteMerged102` | **102** | exclui referências de PRs formalmente merged com HEAD inalterado; `98` podem ser não ancestrais devido a squash/rebase, mas o GitHub confirma os PRs integrados e o bundle preserva as árvores originais |
| `DeleteAllArchived160PlusRunner` | **161** | após merge #239, remove as **160 refs antigas** e a branch de preparação. Das 160, **53 closed-unmerged e 5 órfãs são arquivadas intencionalmente fora da main**, não promovidas a conteúdo integrado. Preserva apenas `main` |

**Decisão pendente:** integrar #239 na `main` e aprovar nominalmente um único lote. O responsável deve compreender que os commits exclusivos das 58 refs não integradas permanecerão apenas no bundle e no histórico acessível, e que a remoção das refs do remoto afetará a facilidade de recuperação. Não chamar isto de merge. **Nenhuma exclusão foi feita neste gate.**

### Procedimento após autorização e merge separados, no Windows

1. Confirmar a integração da PR #239 e o SHA exato da nova `main` e do HEAD da branch de preparação.
2. Fazer clone limpo da `main` integrada em uma pasta externa ao repo. Manter o bundle anterior e não sobrescrevê-lo.
3. Executar `Invoke-SadFinalBranchCleanup.ps1` com `Mode Preview`, `-ExpectedMainSha`, `-ExpectedRunnerSha` e caminhos do repositório, inventário e bundle; revisar CSV de todas as 160 refs.
4. Só com aprovação explícita do lote, executar `-Mode DeleteAllArchived160PlusRunner -ApprovalCode APPROVE_ARCHIVE_AND_DELETE_161_ALL_NON_MAIN` (ou `-Mode DeleteMerged102 -ApprovalCode APPROVE_DELETE_MERGED_102`). Os parâmetros de SHA continuam obrigatórios; qualquer drift bloqueia a ação. Usar clone isolado como runtime, não alterar QlikView.
5. Conferir saída `PASS_DELETE_LEASED`, `after_refs=1` no modo integral, preservar `cleanup_report.json` e `executed_operations.csv` em armazenamento externo, consultar GitHub para validar `main` e ausência das refs.

**Observação temporal:** o bundle local reportado foi criado antes de commits recentes na branch #239; esses commits entrarão na `main` apenas com a integração autorizada e conferida. Não eliminar #239 sem essa condição.

**Estado:** `FINAL_DELETE_SCRIPT_STATIC_REVIEW_ONLY`, `DELETIONS_AUTHORIZED=False`, `DELETIONS_EXECUTED=0`. Não há prova de execução PowerShell deste novo executor.

## 8. Política conservadora aprovada em 12/11/2026 — substitui o modo integral da seção 7

**Decisão do responsável:** prosseguir com o lote **conservador** de 102 branches associadas a PRs já merged. **NÃO** autoriza exclusão das outras 58 refs históricas, da branch da PR #239, da PR #240 ou da `main`. A seção 7 permanece como registro histórico das opções apresentadas, **não** como permissão vigente: o executor foi limitado a `Preview` e `DeleteMerged102`, removendo o modo de limpeza integral.

**Nova fotografia remota inspecionada por GitHub (12/11/2026):** `main@e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9`; **163 branches**. As **161/161** refs do snapshot original permanecem presentes e com o mesmo SHA; duas refs foram criadas depois: `chore/sad-branch-backup-readonly-2026-11-11` (PR #239) e `docs/sad-classificacao-testes-artefatos-2026-11-12` (PR #240). **0 drift** na comparação remota. As 102 são candidatas confirmadas por metadados de PR; **98 não são ancestrais diretas da main**, portanto a existência do backup e a retenção do histórico dos PRs seguem fundamentais.

### Proteções do executor revisado

- Mantém as **58 refs não merged/órfãs**, `main`, #239 e #240. Se surgir outra ref nova sem autorização, bloqueia.
- No modo de exclusão, exige `ExpectedMainSha`, `ExpectedRunnerSha` e `ExpectedHold240Sha` pinados, compara hashes da referência e exige o código `APPROVE_DELETE_MERGED_102`.
- Exige segunda cópia do bundle, caminho distinto, mesmo SHA-256, com `-SecondBundlePath` e declaração `-IndependentStorageConfirmed`. **Essa declaração não prova independência física sozinha**: conferir que é outra mídia ou armazenamento remoto persistente, e não só outra pasta no mesmo disco.
- Confere o bundle original contra SHA-256 `1DC499D992C0414664FFC59298770767DCA40E872070ED314E300AFD045CB21A`, a lista exata de refs, a identidade da origem e o lease SHA atômico em cada `git push`.
- `-Mode Preview` continua o padrão sem mutações remotas. **Nenhuma execução Windows do executor revisado** foi realizada nesta etapa; revisão estática e inventário remoto não homologam a exclusão.

### Comandos de pré-validação, sem exclusão

No Windows, executar a partir de **cópia isolada atualizada da branch #239**; nunca usar versão anterior do executor. `$repo` é o clone com origem canônica e `$runner` é o clone/caminho isolado que contém o script revisado. `$bundle` é o bundle preservado do relatório já executado. Conferir os caminhos antes de rodar:

```powershell
$repo = "$env:USERPROFILE\documents\programming\sad-sus-pb-data-mart"
$runner = Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS\runner-pr239-readonly'
$bundle = Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS\backup_20261111_215818_69d0f0b9\sad-all-refs.bundle'
$inventory = Join-Path $runner 'docs\project\repository-branch-inventory-2026-11-11.json'
$cleanup = Join-Path $runner 'tools\Invoke-SadFinalBranchCleanup.ps1'
# Antes, atualizar APENAS a cópia isolada do runner para o HEAD atual da PR #239.
powershell.exe -NoProfile -File $cleanup -RepoRoot $repo -InventoryPath $inventory `
  -BundlePath $bundle -Mode Preview `
  -ExpectedHold240Sha 'b8d0108884e2f0f9b738d403e03daa9aaf4bffc1'
```

**Critério de PASS do preview:** `VERDICT=PASS_PREVIEW_ONLY`, `CANDIDATE_MERGED=102`, `HELD_UNMERGED_OR_ORPHAN=58`, `DELETED=0`, `REMAINING_REMOTE_BRANCHES=163` enquanto não houver novos merges/deleções. Divergência de hash, erro de acesso ou outra alteração de referências é `BLOCKED`. Inspecionar `candidate_manifest.csv` e `cleanup_report.json` fora do Git.

### Handoff para a exclusão (ainda não executada)

Após aprovação específica de **merge da PR #239** (independente da escolha do lote), conferir o status `merged_at` da PR, a `main` avançada, os HEADs remotos da #239 e #240 e a integridade das duas cópias do bundle em armazenamento independente. Executar **novo Preview** com os três HEADs pinados; revisar o CSV. Só então usar `-Mode DeleteMerged102 -ApprovalCode APPROVE_DELETE_MERGED_102 -SecondBundlePath <caminho-da-copia-independente> -IndependentStorageConfirmed` com os mesmos `-Expected*Sha`. A aprovação do usuário é **restrita às 102 refs de PRs merged**, não à exclusão integral.

**Estado ao fechar este addendum:** `CONSERVATIVE_POLICY_APPROVED=True`; `REMOTE_INVENTORY_161_OF_161_SHA_MATCH=True`; `PR239_MERGED=False`; `OFF_DEVICE_COPY_VERIFIED=False`; `REVISED_RUNNER_WINDOWS_PREVIEW=NOT_RUN`; `BRANCHES_DELETED=0`. Se as 102 refs forem excluídas sem qualquer outra mudança, **61 refs remotas** permanecerão (58 históricas, main, PR #239, PR #240).

**STOP:** não executar exclusão enquanto o preview revisado, a cópia independente e a confirmação de merge estiverem pendentes. Não misturar com a reorganização da PR #240.
