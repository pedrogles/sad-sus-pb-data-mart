# SAD — Resultado local reportado do backup Git de branches (11/11/2026)

**Status de evidência:** `PASS_LOCAL_OPERATOR_REPORTED`. Este documento transcreve as saídas textuais do PowerShell fornecidas pelo responsável. Os arquivos locais `*.json`, `*.csv`, mirror, clone de restauração e bundle **não foram materializados nem inspecionados independentemente pelo agente** nesta etapa. Não classificar como perícia independente dos bytes.

## 1. Contexto e versão executada

- Repositório: `pedrogles/sad-sus-pb-data-mart`.
- `main` remoto conferido pelo conector GitHub antes deste registro: `e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9`.
- PR de preparação: [#239](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/239), branch `chore/sad-branch-backup-readonly-2026-11-11`.
- O operador executou um clone isolado da branch e dois executores versionados: `tools/Get-SadBranchCleanupDryRun.ps1` e `tools/Invoke-SadGitBranchBackup.ps1`, este último com `-BackupVerify`.
- Snapshot anterior à branch: [161 refs](repository-branch-inventory-2026-11-11.json), 102 de PRs merged, 53 de PRs fechados sem merge, 5 órfãs e `main`.

## 2. Resultado do dry-run read-only

```text
VERDICT=PASS_READ_ONLY_PROVISIONAL
LIVE_BRANCHES=162
PRELIMINARY_MERGED_CANDIDATES=102
NEW_REFS_HELD=1
DRIFTED_REFS=0
NO_REMOTE_MUTATIONS=True
```

Manifesto local reportado (fora do Git): `$env:USERPROFILE\SAD_REPO_HYGIENE_EVIDENCIAS\dryrun_20261111_215816_1c791a97\dryrun_manifest.json`.

## 3. Resultado do backup Git e restauração

```text
VERDICT=PASS_LOCAL_BUNDLE_AND_INDEPENDENT_RESTORE
BACKED_UP_REFS=162
RESTORED_REFS=162
MERGED_ANCESTOR_CANDIDATES=4
MERGED_NOT_ANCESTOR=98
NEW_REFS_HELD=1
BUNDLE_SHA256=1DC499D992C0414664FFC59298770767DCA40E872070ED314E300AFD045CB21A
NO_REMOTE_MUTATIONS=True
```

Artefatos locais reportados, fora do repositório:

- `$env:USERPROFILE\SAD_REPO_HYGIENE_EVIDENCIAS\backup_20261111_215818_69d0f0b9\backup_manifest.json`
- `$env:USERPROFILE\SAD_REPO_HYGIENE_EVIDENCIAS\backup_20261111_215818_69d0f0b9\sad-all-refs.bundle`
- `$env:USERPROFILE\SAD_REPO_HYGIENE_EVIDENCIAS\backup_20261111_215818_69d0f0b9\verified_branch_decisions.csv`

**Interpretação restrita:** a saída reporta recuperação dos 162 refs e igualdade de seus SHAs na restauração; o SHA-256 reportado identifica o bundle gerado. O agente **não leu esse arquivo binário nem recalculou seu hash**. Backup e clone restaurado coexistem no **mesmo ambiente local**: ainda não há prova de uma cópia independente em outro dispositivo/armazenamento; manter a pasta intacta e criar outra cópia verificada antes de futuras exclusões.

## 4. Decisão de segurança: 4 candidatas, 98 bloqueadas

As 102 branches de PRs merged **não** podem ser excluídas como lote único: o resultado de `git merge-base --is-ancestor <branch HEAD> <main HEAD>` foi `true` apenas para **4**. Essas quatro possuem prova de ancestralidade **reportada**, mas não há autorização para excluí-las. É necessário ler o CSV para identificar **nomes e SHAs exatos** antes de propor um lote nominal.

As outras **98** não são ancestrais do HEAD da `main`. Isso **não significa** que suas alterações estejam ausentes da `main`: squash merges e rebases geram commits com SHA diferente, assim como pode haver conteúdo posteriormente superado ou divergente. Entretanto, a ausência de ancestralidade bloqueia exclusão automatizada neste procedimento. Exigir uma classificação adicional por PR, commits/diff e equivalência de conteúdo ou uma decisão explícita de arquivamento com recuperação comprovada, **sem promover equivalência presumida a fato**.

As **53 refs de PRs fechados sem merge**, **5 órfãs**, **`main`** e **1 ref nova da própria #239** permanecem `HOLD`/protegidas. Os 24 arquivos exclusivos de PRs acadêmicos e sua proveniência seguem documentados na [auditoria de cobertura](academic-pr-coverage-audit-2026-11-11.md); nenhuma perda de material é autorizada.

## 5. Gates e STOP

| Gate | Estado |
| --- | --- |
| `DRYRUN_162_REFS` | `PASS_LOCAL_OPERATOR_REPORTED` |
| `BACKUP_BUNDLE_AND_RESTORE_162_REFS` | `PASS_LOCAL_OPERATOR_REPORTED` |
| `BACKUP_MANIFEST_INDEPENDENTLY_INSPECTED` | `NO` |
| `OFF_DEVICE_BACKUP_VERIFIED` | `NO_EVIDENCE` |
| `MERGED_BRANCH_ANCESTRY` | `4_POTENTIAL_CANDIDATES_98_HOLD` |
| `DELETE_BRANCHES_APPROVED` | `FALSE` |
| `DELETE_BRANCHES_EXECUTED` | `0` |
| `C2_C3_C4_GLOBAL` | `NOT_APPROVED` |

**Próxima ação delimitada:** preservar o bundle (preferencialmente em segunda mídia), revisar `verified_branch_decisions.csv` e classificar as quatro candidatas nominais e as 98 não ancestrais. Para auditoria independente, o operador pode anexar os manifestos/CSV. **Não repetir o backup que já produziu PASS sem falha concreta.**

**STOP:** nenhum merge da #239, deleção, `git push`, alteração de dados/QVW/QVD/PDF ou mudança de modelagem foi autorizado ou executado nesta etapa.

## 6. Preview conservador reportado em 12/11/2026

**Proveniência:** transcrição do PowerShell 5.1 fornecida diretamente pelo responsável, após clone isolado da PR #239. A saída foi conferida textualmente, **mas os CSV/JSON locais e os arquivos do bundle não foram montados ou inspecionados independentemente**.

```text
VERDICT=PASS_PREVIEW_ONLY
MODE=Preview
CANDIDATE_MERGED=102
HELD_UNMERGED_OR_ORPHAN=58
DELETED=0
REMAINING_REMOTE_BRANCHES=163
```

Artefatos locais reportados em `SAD_REPO_HYGIENE_EVIDENCIAS/cleanup_20261112_135652_11d9fbbb/`: `candidate_manifest.csv` e `cleanup_report.json`.

**Conferência independente limitada pelo GitHub connector após a execução:** 163 referências vivas, a `main` permaneceu em `e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9`, PR #239 permaneceu aberta/Draft/não merged e PR #240 permaneceu aberta/Draft. A checagem de inventário remoto anterior já havia retornado 161/161 SHAs iguais e as duas branches novas protegidas.

**Interpretação:** `WINDOWS_CONSERVATIVE_PREVIEW=PASS_LOCAL_OPERATOR_REPORTED`. O modo Preview **não faz push**; confirma aceitação dos parâmetros, classificação e precondições que o script valida nesse modo. NÃO prova que os gates exclusivos de exclusão foram satisfeitos: a segunda cópia independente ainda não foi verificada, o bundle original segue sob hash reportado, a PR #239 não está merged, o resultado do Preview não atesta teste da execução destrutiva nem autoriza a exclusão.

| Gate após o novo Preview | Estado |
| --- | --- |
| `CONSERVATIVE_POLICY_102` | `OWNER_APPROVED_SCOPE_ONLY` |
| `WINDOWS_CONSERVATIVE_PREVIEW` | `PASS_LOCAL_OPERATOR_REPORTED` |
| `LIVE_GITHUB_BRANCH_COUNT` | `163_CONFIRMED_REMOTE` |
| `OFF_DEVICE_SECOND_BUNDLE` | `NOT_VERIFIED` |
| `PR239_MERGE_APPROVAL` | `NOT_GIVEN` |
| `PR239_MERGED` | `FALSE` |
| `BRANCHES_DELETED` | `0` |

**Próxima ação única:** preservar uma **segunda cópia do bundle fora do dispositivo de origem**, conferir SHA-256 igual a `1DC499D992C0414664FFC59298770767DCA40E872070ED314E300AFD045CB21A` e confirmar que o armazenamento está realmente independente. Depois, obter autorização específica para merge da PR #239; o executor de exclusão conservadora já está versionado mas não foi autorizado a rodar no modo destrutivo.

**STOP:** não executar `DeleteMerged102` ou merge da PR sem satisfazer seus gates separados; não reexecutar Preview sem drift ou mudança concreta.

## 7. Preview da revisão com backup único — 12/11/2026

**Fonte:** transcrição de console PowerShell 5.1 do responsável nesta conversa. Após `git -C $runner pull --ff-only`, o clone isolado `runner-pr239-20261112135647` avançou de `44088a6` para **`1f95fd71`**, que era o HEAD da PR #239 imediatamente antes da execução. O Preview foi executado a partir do script revisionado **após a retirada da exigência de cópia redundante**. A conferência de SHA dos arquivos locais e a leitura de `candidate_manifest.csv` / `cleanup_report.json` não foram realizadas independentemente pelo agente.

```text
VERDICT=PASS_PREVIEW_ONLY
MODE=Preview
CANDIDATE_MERGED=102
HELD_UNMERGED_OR_ORPHAN=58
DELETED=0
REMAINING_REMOTE_BRANCHES=163
MANIFEST=C:\Users\pedro\SAD_REPO_HYGIENE_EVIDENCIAS\cleanup_20261112_140331_ec1c5d89\candidate_manifest.csv
REPORT=C:\Users\pedro\SAD_REPO_HYGIENE_EVIDENCIAS\cleanup_20261112_140331_ec1c5d89\cleanup_report.json
```

**Qualificação:** `WINDOWS_CONSERVATIVE_SINGLE_BACKUP_PREVIEW=PASS_LOCAL_OPERATOR_REPORTED`. GitHub remoto consultado após a saída: a PR #239 seguia Draft/open/unmerged em `1f95fd71c2c1ad44abbb82cdf6b6d854ff65876e`, a `main` em `e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9`, a PR #240 permanecia aberta. **Não houve prova de execução de `DeleteMerged102`, nem exclusões.**

**Importante:** `-Mode Preview` valida hash do bundle e presença das refs e não entra nas guardas exclusivas do modo destrutivo, como `-SingleLocalBackupRiskAccepted` e `-ApprovalCode`. O aceite explícito de risco de **um único bundle local** está registrado no runbook, mas o hash real do bundle continua sendo verificado em tempo de execução.

| Gate | Estado |
| --- | --- |
| `CONSERVATIVE_102_OWNER_SCOPE` | `APPROVED` |
| `ONE_LOCAL_BACKUP_RISK` | `OWNER_ACCEPTED` |
| `WINDOWS_PREVIEW_UPDATED_RUNNER` | `PASS_LOCAL_OPERATOR_REPORTED` |
| `PR239_MERGE_AUTHORIZATION` | `PENDING_SPECIFIC_APPROVAL` |
| `PR239_MERGED` | `FALSE` |
| `BRANCHES_DELETED` | `0` |

**STOP:** a revisão do executor e o Preview reportado encerram o gate pré-merge. Próximo gate: autorização específica do responsável para integrar a PR #239; só depois, novo snapshot pós-merge e decisão de executar o lote de 102 exclusões usando lease SHA. Não pedir novamente backup redundante, pois o responsável optou expressamente por um único bundle.
