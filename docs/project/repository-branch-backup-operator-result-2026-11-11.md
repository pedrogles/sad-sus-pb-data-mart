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
