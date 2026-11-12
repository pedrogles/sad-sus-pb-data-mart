# Closeout — limpeza conservadora de branches remotas (12/11/2026)

## Objetivo e limite

Registrar o encerramento do **único lote autorizado**: excluir as **102 refs remotas vinculadas a PRs merged** do inventário v2, preservando a `main`, as **53** refs de PRs closed-unmerged, as **5** órfãs e as refs das PRs **#239** e **#240**. Não abrange migração, aprovação física do QlikView, produção, nova modelagem acadêmica ou exclusão das refs históricas retidas.

**Fontes:** [PR #239](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/239) (merge aprovado), [inventário v2](repository-branch-inventory-2026-11-11.json), [runbook](repository-branch-backup-runbook-2026-11-11.md), [preflight remoto](repository-conservative-remote-preflight-2026-11-12.md), saída do executor PowerShell 5.1 enviada pelo responsável e inspeção independente dos metadados GitHub após o lote.

## Execução local reportada

**Ambiente:** Windows PowerShell 5.1, executor versionado `tools/Invoke-SadFinalBranchCleanup.ps1` da PR #239; `Mode=DeleteMerged102`, pinagem SHA e `--force-with-lease` por referência. A PR #239 estava merged na `main@dc05bf1fb5fa22b837777565d06506001c6eddf7`.

```text
VERDICT=PASS_DELETE_LEASED
MODE=DeleteMerged102
CANDIDATE_MERGED=102
HELD_UNMERGED_OR_ORPHAN=58
DELETED=102
REMAINING_REMOTE_BRANCHES=61
MANIFEST=C:\Users\pedro\SAD_REPO_HYGIENE_EVIDENCIAS\cleanup_20261112_141330_a647919a\candidate_manifest.csv
REPORT=C:\Users\pedro\SAD_REPO_HYGIENE_EVIDENCIAS\cleanup_20261112_141330_a647919a\cleanup_report.json
```

**Qualificação da evidência:** `PASS_LOCAL_OPERATOR_REPORTED` para o resultado do PowerShell; `PASS_REMOTE_INDEPENDENT_GITHUB_METADATA` para a ausência/preservação dos HEADs remotos. Os CSV/JSON locais e os 102 resultados individuais de push não foram abertos pelo agente; não atribuir-lhes inspeção independente. O log/CSV precisa continuar guardado fora do Git.

## Verificação remota independente, antes de criar esta branch de closeout

| Invariante | Observado |
| --- | --- |
| Branches remotas após exclusão | **61** |
| Candidatas `MERGED_PR` do inventário ainda presentes | **0 de 102** |
| Candidatas `MERGED_PR` removidas | **102 de 102** |
| `CLOSED_UNMERGED_PR` preservadas no SHA inventariado | **53 de 53** |
| `NO_PR` preservadas no SHA inventariado | **5 de 5** |
| `main` preservada | `dc05bf1fb5fa22b837777565d06506001c6eddf7` |
| Branch #239 preservada | `824f81707e1540a8ed3cc8756b963dff6e1ae0c5` |
| Branch #240 preservada | `b8d0108884e2f0f9b738d403e03daa9aaf4bffc1` |
| Ausências/diferenças SHA nas 58 refs históricas | **0** |

**Contagem:** 53 + 5 + 1 `main` + 1 branch #239 + 1 branch #240 = **61 refs**. **Após** a conferência, foi criada a branch separada `docs/sad-branch-cleanup-closeout-2026-11-12`, que adiciona **uma** ref documental. Assim, **62 refs** passam a ser esperadas enquanto esta PR de closeout existir, sem representar regressão da limpeza.

## Risco de recuperação aceito

O responsável escolheu explicitamente **um único backup Git local**. O executor verificou em execução o bundle contra o hash constante `1DC499D992C0414664FFC59298770767DCA40E872070ED314E300AFD045CB21A` e validou refs conforme resultado local reportado. O agente **não recalculou independentemente** esse hash. O bundle foi criado antes de commits adicionais da PR #239 (que já estão na main) e antes da branch da PR #240 (que permanece remota). **Não apagar, substituir nem mover o bundle, manifestos ou logs sem inventário prévio.** Se o dispositivo local falhar, commits de branches removidas (inclusive 98 HEADs não ancestrais da main no levantamento anterior) podem não ser recuperáveis. A decisão de não ter segunda cópia não elimina esse risco.

## Classificação e condição de parada

- `PR239_MERGED=True` — verificado no GitHub.
- `CONSERVATIVE_BRANCH_DELETE=PASS_LOCAL_OPERATOR_REPORTED_AND_REMOTE_VERIFIED`.
- `DELETED_MERGED_PR_REFS=102/102` — conferido no GitHub.
- `HISTORICAL_REFS_HELD=58/58` — nome e SHA conferidos no GitHub.
- `BRANCHES_AT_VERIFICATION=61` — antes da branch documental adicional.
- `PR240_DRAFT_OPEN=True` — frente independente de classificação de arquivos; **não** equivale a migração concluída.
- `GIT_HYGIENE_DELETE_GATE=CLOSED` e `PRODUCTION_APPROVED=False`.

**STOP:** não repetir `DeleteMerged102`: o inventário congelado de 161 refs não descreve mais o remoto e o executor deve bloquear por drift. Não executar limpeza integral, nova exclusão, encerramento da PR #240, QlikView, merge adicional ou mudança estrutural como consequência deste closeout. O estado deste documento só passa a canônico após merge **autorizado** desta PR documental.