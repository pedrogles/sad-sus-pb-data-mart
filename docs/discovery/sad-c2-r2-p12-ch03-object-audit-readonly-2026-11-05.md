# SAD — Auditoria somente leitura de objetos QVW CH03/H1

**ID:** SAD-C2-R2-P12-CH03-OBJECT-FORENSIC-READONLY-01.
**PR:** #222, Draft e sem merge.
**Base canônica:** main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83.
**Fontes:** AGENTS.md → docs/project/current-state.md → docs/academic/requirements.md → Boundary 7 → V3 D2-R2 → closeout CH03/H1.
**Agente:** GPT-6/GitHub para preparação; operador Windows/QlikView 12 para única execução física. Esforço efetivo não exposto.
**Natureza:** complemento read-only pós-Verify; não reexecutar o gate nem promover evidências retroativas.

## Objetivo

Inventariar via COM todos os Object IDs e tipos, comparando QVW fonte #221 versus QVW TEMP salva #222. Registrar exatamente o novo Text Object, qualquer objeto removido ou diferença de tipos; tentar exportar XML de layout em pasta externa para eventual conferência de propriedades. Preservar os QVWs originais e todos os 25 artefatos canônicos por hashes.

### Fonte

C:\Users\pedro\Documents\SAD_C2_P11_H1_RUNTIME\SAD_C2_P11_H1_d6723bea5c7b43928e324b773c51a409\SAD_C2_R2_P11_HISTORICAL_CARDS_H1_TEMP.qvw

SHA-256: E38C41B3F9CEECC3E4964CB91E5FE8C17FD608FA32CB5612DC2907E82348296E

### Alvo

C:\Users\pedro\Documents\SAD_C2_P12_CH03_H1_RUNTIME\SAD_C2_P12_CH03_H1_c70f6c392ca44f53900a92c0cc601073\SAD_C2_R2_P12_CH03_NATIVE_H1_TEMP.qvw

SHA-256: C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D

### Evidência gerada

Sob a pasta EVIDENCE_DIR já existente, o script cria OBJECT_AUDIT_<GUID> contendo duas COPIAS somente leitura, CSVs fonte/alvo, relatório JSON e, se API disponível, dois XML de layout. O ZIP final contém apenas metadados, nunca QVWs ou QVDs. Não renomear nem substituir manifests do Prepare/Verify.

## Comando de operação

Windows PowerShell 5.1, na raiz do repositório local, com QlikView fechado. O script já deve estar commitado e a worktree limpa. Atualização fast-forward só na branch de teste, sem merge de PR ou de main.

~~~powershell
$ErrorActionPreference='Stop'
$branch='test/sad-c2-r2-p12-ch03-native-h1-20261105'
if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
git fetch origin "refs/heads/$($branch):refs/remotes/origin/$branch"
if($LASTEXITCODE -ne 0){throw 'BLOCKED_FETCH'}
git switch $branch
if($LASTEXITCODE -ne 0){throw 'BLOCKED_SWITCH'}
git merge --ff-only "origin/$branch"
if($LASTEXITCODE -ne 0){throw 'BLOCKED_NOT_FAST_FORWARD'}
if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_AFTER_UPDATE' }
$repo=(git rev-parse --show-toplevel).Trim()
$runner=Join-Path $repo 'tools\Inspect-SadC2R2CH03ObjectDiffReadOnly.ps1'
$tokens=$null; $errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
if (@($errors).Count -gt 0) { $errors; throw 'BLOCKED_PARSER' }
& powershell.exe -NoProfile -File $runner -Root $repo
Write-Host "AUDIT_EXIT_CODE=$LASTEXITCODE"
~~~

## Limites e vereditos

- O runner utiliza QlikView COM em **COPIAS read-only**, sem chamadas Save/SaveAs/Reload, sem alteração de seleções nem escrita em objetos. ExportLayoutFile é usado apenas para escrever XML na pasta de evidências. Se a API de exportação não estiver disponível, isso não vira PASS de propriedades.
- Exige SHA de ambas as QVWs originais antes/depois, hash das cópias antes/depois e integridade dos 25 protegidos. Se o hash divergir, HARD_STOP.
- PASS_OBJECT_ID_TYPE_INVENTORY_ONLY_REVIEW_LAYOUT_XML atesta só delta de IDs e tipos. Não prova automaticamente expressão CH03, propriedade de todos os objetos ou contagem de Save.
- BLOCKED para QVW/hash diferente, COM incompatível ou proteção comprometida. INCONCLUSIVE se apenas inventário parcial for possível.
- Apresentar a saída completa e o AUDIT_METADATA_ZIP no chat para revisão final; **não enviar QVWs**.
- STOP após uma rodada read-only ou primeira falha. Sem reexecução de H1, sem novo Verify, sem merge, C3/C4, IX ou produção.
