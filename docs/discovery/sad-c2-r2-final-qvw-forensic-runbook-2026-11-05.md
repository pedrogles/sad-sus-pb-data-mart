# SAD C2-R2 — Auditoria forense read-only da QVW TEMP final

**Gate:** `SAD-C2-R2-FINAL-QVW-FORENSIC-READONLY-01`
**Baseline main:** `0549e1dba71aaa8bbab9d6755aecb8465f8bea83`.
**Branch local:** `test/sad-c2-r2-final-consolidation-20261105`, commit inicial conhecido `98f063abb68f3935b51349f979da009a441ce43f`.
**Origem:** [PR #222](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/222) QVW TEMP, SHA-256 `C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D`.
**Destino:** QVW consolidada salva, SHA-256 `6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58`.
**Motivo:** o Verify F1/F2 já encerrou (`PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI`) e não deve ser repetido. Resta apurar o delta interno dos objetos em relação à fonte #222.

## Autorizações e escopo

Autorizado: versionar o closeout e preparar/executar uma rodada de inspeção somente leitura usando QlikView COM **em cópias read-only isoladas**, com preservação por SHA-256 dos 25 protegidos e das duas QVWs originais. Nenhuma chamada de Save, SaveAs, Reload, Select, ClearAll ou SetProperties.

Proibido: qualquer edição no QVW consolidado, original ou canônico; novo Save; repetição F1/F2 ou Verify; dados/QVDs versionados; merge; C3/C4/IX. O script cria somente arquivos de evidência fora do Git.

**Agente:** GPT-6/GitHub prepara e revisa resultados; operador executa em PowerShell 5.1 / Windows QlikView 12.0.20000.0. Sem acesso direto do agente ao desktop Windows.

## Preparação e execução

1. Fazer commit dos três arquivos (closeout, este runbook, runner) **antes** de executar.
2. No PowerShell na raiz do repositório, QlikView totalmente fechado, verificar que branch e worktree estão corretas.
3. Executar uma única vez:

```powershell
$ErrorActionPreference = 'Stop'
$repo = (git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_REPO' }
$script = Join-Path $repo 'tools\Inspect-SadC2R2FinalQvwReadOnly.ps1'
$tokens = $null; $errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $script,[ref]$tokens,[ref]$errors)
if (@($errors).Count -gt 0) { $errors; throw 'BLOCKED_PS_PARSER' }
& powershell.exe -NoProfile -File $script -Root $repo
Write-Host "AUDIT_EXIT_CODE=$LASTEXITCODE"
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_AUDIT' }
```

## Saídas e veredito

- Uma subpasta `FINAL_FORENSIC_<GUID>` dentro da pasta local de evidências F1/F2 com **cópias read-only** dos QVWs, inventários CSV, relatório JSON e dois XMLs de layout (se a API os disponibilizar).
- Um ZIP adjacente `FINAL_FORENSIC_<RUN_ID>_metadata.zip` contém **apenas metadados**, sem QVWs ou QVDs. O operador pode enviar **esse ZIP e a saída do PowerShell**, não os binários QVW.
- `PASS_ID_TYPE_INVENTORY_ONLY` requer 38 objetos preservados em cada QVW, zero adições/remoções/mudanças de tipo, presença normalizada de `CH02`, `CH03`, `TX17`. Não aprova expressões, ordem Z, geometria ou contagem de Saves.
- Para avaliação de delta em objetos e layout, comparar depois os XMLs `DocInternals/ObjectPool`, `FrameParentDef`, `LegacyObjectZOrder` e estados serializados, interpretando explicitamente diferenças cosméticas e operacionais. Caso falte export XML, `INCONCLUSIVE_FULL_PROPERTY_AUDIT`.
- `BLOCKED` se hash divergir, script/branch não versionados, worktree suja, QlikView aberto, QVDs/QVWs protegidos alterados ou COM falhar.
- STOP após primeira execução ou falha; nenhum segundo intento sem nova decisão registrada.

## Estado e handoff

A análise forense não equivale ao aceite C2 total. Posteriormente haverá avaliação separada da reconciliação tabular por competência e da cobertura residual das rotas nativas exigidas em D2-R2 V3. O `current-state.md` da main ainda está desatualizado, mas não deve ser alterado neste gate. `READY_FOR_C3=NO`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
