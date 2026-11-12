# SAD — Preflight remoto conservador da limpeza de branches

**Data:** 12/11/2026. **Escopo:** avaliação read-only pela conexão GitHub; não é execução do PowerShell Windows.  
**PR de execução:** [#239](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/239) (Draft).  
**PR a preservar:** [#240](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/240) (Draft).  
**Fonte de candidatos:** [inventário v2 de 161 refs](repository-branch-inventory-2026-11-11.json) commitado na #239.

## Resultado do confronto remoto

| Critério | Valor observado |
| --- | --- |
| Branches remotas vivas | **163** |
| Branches no inventário original | **161** |
| Ref original ausente | **0** |
| HEAD SHA divergente dos 161 originais | **0** |
| Candidatas `MERGED_PR` do snapshot | **102** |
| Candidatas cujo `pr_merged_at`, `pr_sha_matches` e `pr_head_sha == sha` no inventário são inválidos | **0** |
| Retenção histórica `CLOSED_UNMERGED_PR` | **53** |
| Retenção `NO_PR` | **5** |
| `main` | **1** |
| Ref nova, protegida: PR #239 | `chore/sad-branch-backup-readonly-2026-11-11@d18699c8d345c633d9fb3bd2af95a8e9bc67b89f` |
| Ref nova, protegida: PR #240 | `docs/sad-classificacao-testes-artefatos-2026-11-12@b8d0108884e2f0f9b738d403e03daa9aaf4bffc1` |
| `main` observada | `e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9` |
| Total esperado após remoção conservadora, se nada mudar | **61** |
| Exclusões realizadas neste gate | **0** |

**Qualificação:** `PASS_REMOTE_METADATA_STATIC_ONLY`. O confronto comprova a constância dos SHAs e a coerência do inventário GitHub, **não** a execução do script PowerShell `Invoke-SadFinalBranchCleanup.ps1`, nem a validação independente do bundle ou a segurança semântica de cada commit. Os 98 branches `MERGED_PR` não ancestrais da main, reportados em ensaio Windows anterior, continuam dependentes da preservação do bundle e da comprovação de disponibilidade restaurável.

## Bloqueios conferidos

- O ambiente desta execução não disponibiliza `pwsh` ou `powershell.exe`.
- Tentativa de `git ls-remote --heads https://github.com/pedrogles/sad-sus-pb-data-mart.git` falhou por **DNS: `Could not resolve host: github.com`**. A conexão GitHub forneceu os metadados remotos lidos acima, mas não habilita execução do executor Windows.
- Nenhum arquivo `sad-all-refs.bundle` ou relatórios locais da restauração foi entregue a esta execução. `PASS_LOCAL_OPERATOR_REPORTED` continua a classificação do teste Windows anterior.
- Uma segunda cópia independente de `sad-all-refs.bundle` ainda não foi conferida por SHA-256.
- A PR #239 ainda está Draft/não merged; a #240 permanece Draft.

## Handoff único: Preview real, sem exclusão

No PowerShell Windows, operar em **clone isolado** da branch #239, após obter o HEAD vigente da PR. Executar o modo **Preview** com o bundle já criado, o inventário da mesma branch e `ExpectedHold240Sha`. O script padrão é não destrutivo; sua opção de exclusão `DeleteMerged102` **não deve ser invocada ainda**.

```powershell
$repo = "$env:USERPROFILE\documents\programming\sad-sus-pb-data-mart"
$evidence = Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS'
$runner = Join-Path $evidence 'runner-pr239-readonly'
$bundle = Join-Path $evidence 'backup_20261111_215818_69d0f0b9\sad-all-refs.bundle'

# Runner anterior pode estar desatualizado; sincronizar só a cópia de trabalho
# isolada, sem alterar o checkout principal nem QVW/QVD.
git -C $runner fetch origin chore/sad-branch-backup-readonly-2026-11-11
if ($LASTEXITCODE -ne 0) { throw 'FETCH_RUNNER_FAILED' }
git -C $runner checkout chore/sad-branch-backup-readonly-2026-11-11
if ($LASTEXITCODE -ne 0) { throw 'CHECKOUT_RUNNER_FAILED' }
git -C $runner merge --ff-only origin/chore/sad-branch-backup-readonly-2026-11-11
if ($LASTEXITCODE -ne 0) { throw 'RUNNER_NOT_FAST_FORWARD' }

$inventory = Join-Path $runner 'docs\project\repository-branch-inventory-2026-11-11.json'
$script = Join-Path $runner 'tools\Invoke-SadFinalBranchCleanup.ps1'
powershell.exe -NoProfile -File $script -RepoRoot $repo -InventoryPath $inventory `
  -BundlePath $bundle -Mode Preview `
  -ExpectedMainSha 'e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9' `
  -ExpectedHold240Sha 'b8d0108884e2f0f9b738d403e03daa9aaf4bffc1'
if ($LASTEXITCODE -ne 0) { throw 'PREVIEW_BLOCKED' }
```

**Esperado somente se o remoto estiver inalterado:** `VERDICT=PASS_PREVIEW_ONLY`, `CANDIDATE_MERGED=102`, `HELD_UNMERGED_OR_ORPHAN=58`, `DELETED=0`, `REMAINING_REMOTE_BRANCHES=163`. Conferir os CSV/JSON produzidos em `SAD_REPO_HYGIENE_EVIDENCIAS` e anexar resultados. Se houver `BLOCKED`, **parar**, preservar evidências e não corrigir por força de exclusão.

**Atenção:** `git fetch`, `checkout` e `merge --ff-only` acima agem apenas no clone isolado `$runner`. Se houver alterações locais nesse clone, interromper e inspecionar; não usar `reset --hard`. Após a futura integração da PR #239, o SHA da `main` será diferente e os argumentos deverão ser rechecados com valores vivos.

## Condição de parada

- `REMOTE_INVENTORY=PASS_REMOTE_METADATA_STATIC_ONLY`
- `WINDOWS_REVISED_PREVIEW=NOT_RUN`
- `SECOND_BACKUP_OFF_DEVICE=NOT_VERIFIED`
- `PR239_MERGED=False`
- `BRANCHES_DELETED=0`

**STOP** neste gate. Nenhum merge, exclusão, alteração da `main`, edição QVW/QVD ou ampliação do escopo acadêmico foi realizada.
