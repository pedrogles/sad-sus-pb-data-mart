# G1-LOCAL-READONLY — inventário Windows sem mudança de checkout

**Estado:** `VERSIONED_NOT_EXECUTED`. **Escopo:** G1 do bootstrap `bootstrap_g1_local_readonly_sad_2026-10-20.md`. Não integra G1 à main, não autoriza G1 COM, C3-B1, G2, Fase IX nem higiene B1.

## Roteamento do gate
- **Agente:** Codex Local no Windows; fallback operador humano. Modelo/esforço: o realmente disponível no Codex, Medium como preferência inicial; escalar só com causa concreta registrada.
- **Base documental:** `main@22845ece37ccefe16d53febf101034395290425d`; `AGENTS.md`, `current-state.md`, `requirements.md`, política v0.2, Boundary 7 e automação QlikView.
- **Permissões:** somente leitura Git/arquivos/dados; criar **novos** arquivos sob `EVIDENCE_ROOT` previamente escolhido, fora do Git e de TEMP. Não executar checkout, worktree add, stash, limpeza, merge, COM, QlikView, Reload, STORE ou write QVD/QVW.
- **STOP:** uma execução controlada do inventário, ou primeira falha/inconclusão; sem rerun automático.
- **Fontes:** 22 QVDs (10 EXTRAÇÃO + 12 TRANSFORMAÇÃO), três caminhos QVW canônicos (registrando ausência), CSV histórico `qvd_22_before.csv`, referência F1/F2 (8 CSVs e manifesto), F3 (5 CSVs e manifesto) e QVW T24 TEMP original de SHA congelado.
- **Proveniência:** script `tools/Invoke-SadG1LocalReadOnlyInventory.ps1`, commit exato congelado antes da execução; cópia local deve corresponder ao **Git blob SHA** indicado no GitHub. Não aceitar versões avulsas como prova do gate.

## Correção versionada após bloqueio local de preflight

**Evidência reportada pelo operador (20/10/2026):** com PowerShell 5.1 e `$ErrorActionPreference='Stop'`, a execução foi interrompida na checagem `git -C <EVIDENCE_ROOT> rev-parse --show-toplevel 2>$null` porque o diretório de evidências está corretamente **fora** do Git. O stderr nativo gerou `NativeCommandError` terminante. O script parou **antes** de criar `SAD_G1_...`, sem inventário QVD, nenhuma recarga nem evidência persistente de execução.

**Correção:** commit `e8168f33798646e64efcba051c0d21bc85348cf0` substitui a tentativa Git por verificação apenas de caminhos `.git` no diretório de evidências e seus ancestrais; passa a aceitar diretórios de evidências fora do Git, sem mascarar stderr. **Blob SHA exigido para o novo runner:** `e1fe85daf8f807beea1adb49e3276b19955f3c69`. O SHA e parser **da revisão anterior** não comprovam a revisão nova. A mudança não foi executada no Windows nesta sessão: `PATCH_VERSIONED_NOT_EXECUTED`.

**Regra de rerun:** requer inspeção da cópia atualizada, `git hash-object` igual ao blob novo, parser real 5.1 com 0 erros e autorização específica de **uma** tentativa de inventário parcial. Não rodar a revisão antiga, não iniciar Codex, não abrir QlikView. Salvar stdout do novo ensaio no diretório de evidências sem versionar QVD/QVW.

## Modo de uso no Windows — somente após preflight de destino

1. Identificar `Root` existente, `EvidenceRoot` **já existente** e escolhido pelo responsável, fora de `Root`, fora de `%TEMP%` e fora de qualquer outro Git. Não criar/reorganizar diretórios do projeto, não fazer checkout.
2. Obter **somente** a cópia byte a byte do script versionado por URL raw ancorada no commit de seu PR, salvar diretamente dentro do `EvidenceRoot`, conferir o `git hash-object` contra o blob SHA que GitHub informa. Na divergência, STOP.
3. Validar o parser com `[System.Management.Automation.Language.Parser]::ParseFile()` no Windows PowerShell 5.1, exigindo 0 erros. Esse parser não roda o script.
4. Passar `-Root`, `-EvidenceRoot` e, quando localizados, `-BaselineCsv`, `-F1F2Dir`, `-F3Dir` e `-ReferenceQvw` (não inventar caminhos). Invocar uma vez apenas; não tentar reconstruir insumos faltantes.
5. Anexar o stdout, `qvd_22_inventory.csv`, `qvw_canonical_inventory.csv`, `git_status.txt` e `git_worktrees.txt` do novo `EVIDENCE_DIR` privado. Não publicar QVD, QVW, dados brutos ou caminhos sensíveis desnecessários.

**Bootstrap da cópia verificada, sem checkout (executar após escolher um EVIDENCE_ROOT existente):**

```powershell
$evidenceRoot = '<diretorio-existente-e-persistente-fora-do-git-e-temp>'
$ps1 = Join-Path $evidenceRoot 'Invoke-SadG1LocalReadOnlyInventory.ps1'
$raw = 'https://raw.githubusercontent.com/pedrogles/sad-sus-pb-data-mart/e8168f33798646e64efcba051c0d21bc85348cf0/tools/Invoke-SadG1LocalReadOnlyInventory.ps1'
Invoke-WebRequest -Uri $raw -OutFile $ps1
$actualBlob = [string](& git hash-object -- $ps1)
if($actualBlob.Trim() -cne 'e1fe85daf8f807beea1adb49e3276b19955f3c69'){
    throw 'BLOCKED_SCRIPT_BLOB_SHA_MISMATCH'
}
```

O comando acima **grava apenas a cópia** do script dentro do diretório de evidências escolhido. O blob Git é SHA-1 do objeto versionado, **não** o SHA-256 de execução; o executor registrará seu SHA-256 local separadamente. Não execute o script antes da confirmação de origem e do parser.

**Comando lógico (substituir apenas caminhos existentes; nunca inventar):**

```powershell
$ps1 = '<copia-verificada-do-script-g1.ps1>'
$repo = '<raiz-existente-do-repositorio-no-windows>'
$evidenceRoot = '<diretorio-existente-e-persistente-fora-do-git-e-temp>'
$baseline = '<qvd_22_before.csv-historico-existente>'
$f1f2 = '<diretorio-existente-f1-f2>'
$f3 = '<diretorio-existente-f3>'
$qvw = '<qvw-t24-temp-historico-com-sha-congelado>'

$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($ps1,[ref]$tokens,[ref]$errors)
if (@($errors).Count -ne 0) { $errors; throw 'PARSER=BLOCKED' }
Write-Output 'PARSER=PASS'
powershell.exe -NoProfile -File $ps1 -Root $repo -EvidenceRoot $evidenceRoot -BaselineCsv $baseline -F1F2Dir $f1f2 -F3Dir $f3 -ReferenceQvw $qvw
```

**Importante:** há escrita **somente** em `EVIDENCE_ROOT` (um subdiretório novo, CSVs e dois registros de Git) e na cópia do script dentro desse mesmo destino; o executor não opera QlikView. O `git status` usa `GIT_OPTIONAL_LOCKS=0` para evitar atualização oportunista do índice. Não tratar a ausência de uma referência opcional como PASS.

## Aceitação restrita
- `PASS_LOCAL_G1_READONLY_INVENTORY_CANDIDATE_ONLY`: 22 QVDs enumerados/cabeçalhos/hash, baseline 22/22 idêntica, F1/F2 8/8, F3 5/5 e crosslink 9/9, QVW T24 SHA congelado, worktree/status registrados e evidência persistente.
- `INCONCLUSIVE_G1_INCOMPLETE_REFERENCES`: ausência de baseline, diretório F1/F2/F3 ou QVW TEMP de referência informados.
- `BLOCKED_READONLY_PREFLIGHT`: erro/violação de invariantes ou discrepância; STOP sem corrigir automaticamente.
- Mesmo em PASS: `PHYSICAL_INDICATORS=NOT_TESTED`, `P5_D2_UI=NOT_APPROVED`, `BRANCH_HYGIENE_APPLY=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## Fronteiras
O executor lê e faz hashes; **não houve parser/execução Windows neste PR**. A análise estática e revisão de diff não equivalem a prova de compatibilidade PowerShell 5.1. Antes de reutilizar um runner histórico para novo gate, verificar a origem do SHA e os parâmetros, sem repetir V–VIII automaticamente.

**Handoff:** após obter provas locais, enviar apenas inventário/manifests/logs e resumo; decidir em etapa separada higiene B1 com nova confirmação dos PRs/SHA e aprovação explícita do lote.
