# Fase V — ONE-SHOT CREATE + independent population QVD readback (QlikView 12).
# Authorized target: only TRANSFORMACAO/QVD/FATO_POPULACAO.qvd (not yet authorized to run).
# No TRANSF.qvw, no rewrite of 20 preexisting QVDs, no deletion/overwrite.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)

$branchExpected = 'feat/phase-v-fato-populacao-qvd-materialization-20261015'
$factQvs = Join-Path $Root 'TRANSFORMACAO\transf_fato_populacao_inmemory.qvs'
$storeQvs = Join-Path $Root 'TRANSFORMACAO\phase_v_populacao_qvd_create.qvs'
$auditQvs = Join-Path $Root 'TRANSFORMACAO\phase_v_populacao_qvd_readback.qvs'
$previousLog = Join-Path $Root 'TRANSFORMACAO\V5_IBGE_FATO_POP_IMPL_PREFLIGHT.qvw.log'
$createQvw = Join-Path $Root 'TRANSFORMACAO\V5_IBGE_FATO_POP_CREATE.qvw'
$auditQvw = Join-Path $Root 'TRANSFORMACAO\V5_IBGE_FATO_POP_QVD_READBACK.qvw'
$createLog = "$createQvw.log"
$auditLog = "$auditQvw.log"
$target = Join-Path $Root 'TRANSFORMACAO\QVD\FATO_POPULACAO.qvd'
$fourInputs = @(
    (Join-Path $Root 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd'),
    (Join-Path $Root 'EXTRACAO\QVD\REF_MUNICIPIO_PB_DERIVADA.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd')
)
$linkTarget = Join-Path $Root 'TRANSFORMACAO\QVD\LINK_ANALISE.qvd'
$required = @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    (Join-Path $Root 'docs\academic\requirements.md'),
    $factQvs,$storeQvs,$auditQvs,$previousLog,
    (Join-Path $Root 'TRANSFORMACAO\QVD\FATO_INTERNACAO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\FATO_CAPACIDADE_LEITO.qvd')
) + $fourInputs
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "VERDICT=BLOCKED_REQUIRED_INPUT_MISSING path=$path"
    }
}
# Absolutely no overwrite, even if a prior attempt left only a partial QVD.
foreach ($path in @($target,$linkTarget,$createQvw,$auditQvw,$createLog,$auditLog)) {
    if (Test-Path -LiteralPath $path) {
        throw "VERDICT=BLOCKED_OUTPUT_ALREADY_EXISTS_NO_OVERWRITE path=$path"
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'VERDICT=BLOCKED_GIT_UNAVAILABLE'
}
$branch = (& git -C $Root branch --show-current 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne $branchExpected) {
    throw "VERDICT=BLOCKED_BRANCH expected=$branchExpected actual=$branch"
}
$dirty = @(& git -C $Root status --porcelain --untracked-files=no 2>$null)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) {
    throw 'VERDICT=BLOCKED_TRACKED_WORKTREE_DIRTY'
}

$factScript = [IO.File]::ReadAllText($factQvs,[Text.Encoding]::UTF8)
$storeScript = [IO.File]::ReadAllText($storeQvs,[Text.Encoding]::UTF8)
$auditScript = [IO.File]::ReadAllText($auditQvs,[Text.Encoding]::UTF8)
$factSha = (Get-FileHash -LiteralPath $factQvs -Algorithm SHA256).Hash
$storeSha = (Get-FileHash -LiteralPath $storeQvs -Algorithm SHA256).Hash
$auditSha = (Get-FileHash -LiteralPath $auditQvs -Algorithm SHA256).Hash
# Pinned to the previously PASS-tested population QVS SHA-256, reported in PR #94.
$validatedFactSha = '3E28DECB7539E90E5314A77E7DD4E2057FDE499899AB0B943A432F117D885ADE'
if ($factSha -cne $validatedFactSha) {
    throw "VERDICT=BLOCKED_VALIDATED_FACT_SCRIPT_SHA_CHANGED actual=$factSha"
}
if (-not $factScript.Contains('IF ''$(vP5PopImplMode)'' <> ''PREFLIGHT'' THEN') -or
    -not $factScript.Contains('VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_QVD_APPROVED') -or
    -not $factScript.Contains('FATO_POPULACAO:') -or
    @([regex]::Matches($factScript,'(?im)^\s*STORE\s+')).Count -ne 0 -or
    @([regex]::Matches($factScript,'(?im)\bFROM\s+\[[^\]]+\.qvd\]')).Count -ne 4 -or
    $factScript -match '(?im)^\s*(EXECUTE|BINARY|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN)\b' -or
    $factScript -match '\$\((Must_Include|Include)' -or
    $factScript -match '(?im)\bAS\s+\[%LINK_KEY\]') {
    throw 'VERDICT=BLOCKED_FACT_QVS_POLICY_MISMATCH'
}
if (-not $storeScript.Contains('AUTHORIZED_ONE_SHOT_CREATE_POPULACAO_20261015') -or
    -not $storeScript.Contains('VERDICT=WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT') -or
    -not $storeScript.Contains('VERDICT=BLOCKED_TARGET_EXISTS_NO_OVERWRITE') -or
    @([regex]::Matches($storeScript,'(?im)^\s*STORE\s+')).Count -ne 1 -or
    -not $storeScript.Contains('STORE FATO_POPULACAO INTO [QVD\FATO_POPULACAO.qvd] (qvd);') -or
    $storeScript -match '(?im)^\s*(EXECUTE|BINARY|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN)\b') {
    throw 'VERDICT=BLOCKED_STORE_QVS_POLICY_MISMATCH'
}
if (-not $auditScript.Contains('VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY') -or
    -not $auditScript.Contains('FROM [QVD\FATO_POPULACAO.qvd] (qvd);') -or
    $auditScript -match '(?im)^\s*(STORE|EXECUTE|BINARY|JOIN|CONCATENATE)\b' -or
    $auditScript -match '\$\((Must_Include|Include)') {
    throw 'VERDICT=BLOCKED_READBACK_QVS_NOT_READ_ONLY'
}
# Check previous local native Qlik PASS from the exact validated candidate.
$previousLines = @(Get-Content -LiteralPath $previousLog -ErrorAction Stop |
    Where-Object { $_.Contains('[V5-POP-FACT]') -and $_ -notmatch '\bTRACE\b' })
foreach ($marker in @(
    '[V5-POP-FACT] START MODE=PREFLIGHT FACT_IN_MEMORY_ONLY=True',
    '[V5-POP-FACT] OUTPUT ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 FIELDS=7',
    '[V5-POP-FACT] ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127',
    '[V5-POP-FACT] VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_QVD_APPROVED'
)) {
    if (@($previousLines | Where-Object { $_.Contains($marker) }).Count -ne 1) {
        throw "VERDICT=BLOCKED_PREVIOUS_LOCAL_PREFLIGHT_MISSING marker=$marker"
    }
}
$qvdDirs = @((Join-Path $Root 'EXTRACAO\QVD'),(Join-Path $Root 'TRANSFORMACAO\QVD'))
$baseline = @{}
foreach ($dir in $qvdDirs) {
    foreach ($f in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
        $baseline[$f.FullName] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    }
}
if ($baseline.Count -ne 20 -or $baseline.ContainsKey($target)) {
    throw "VERDICT=BLOCKED_UNEXPECTED_FROZEN_QVD_BASELINE actual=$($baseline.Count)"
}
$inputHashes = @{}
foreach ($file in $fourInputs) { $inputHashes[$file] = $baseline[$file] }
if (@($inputHashes.Values | Where-Object { -not $_ }).Count -gt 0) {
    throw 'VERDICT=BLOCKED_MISSING_INPUT_HASH'
}
Write-Output "EXISTING_QVD_INVENTORY_COUNT=$($baseline.Count)"

function Verify-Inventory([string]$stage) {
    $seen=@{}
    foreach ($dir in $qvdDirs) {
        foreach ($f in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
            $name=$f.FullName
            $seen[$name]=1
            if ($baseline.ContainsKey($name)) {
                if ($baseline[$name] -cne (Get-FileHash -LiteralPath $name -Algorithm SHA256).Hash) {
                    throw "VERDICT=BLOCKED_EXISTING_QVD_SHA_CHANGED stage=$stage file=$name"
                }
            } elseif ($name -cne $target) {
                throw "VERDICT=BLOCKED_UNEXPECTED_NEW_QVD stage=$stage file=$name"
            }
        }
    }
    foreach ($name in $baseline.Keys) {
        if (-not $seen.ContainsKey($name)) {
            throw "VERDICT=BLOCKED_EXISTING_QVD_REMOVED stage=$stage file=$name"
        }
    }
    if (-not $seen.ContainsKey($target) -or $seen.Count -ne ($baseline.Count+1)) {
        throw "VERDICT=BLOCKED_TARGET_NOT_ONLY_NEW_QVD stage=$stage"
    }
    foreach ($name in $fourInputs) {
        if ($inputHashes[$name] -cne (Get-FileHash -LiteralPath $name -Algorithm SHA256).Hash) {
            throw "VERDICT=BLOCKED_SOURCE_QVD_SHA_CHANGED stage=$stage file=$name"
        }
    }
    Write-Output "ALL_4_INPUT_QVD_SHA256_UNCHANGED=$stage"
    Write-Output "ALL_PREEXISTING_QVD_SHA256_UNCHANGED=$stage"
    Write-Output "ONLY_NEW_QVD_IS_FATO_POPULACAO=$stage"
}
function Same-QlikScript([string]$a,[string]$b) {
    return ($a.Replace([string][char]13,'').TrimEnd() -ceq
            $b.Replace([string][char]13,'').TrimEnd())
}
function Create-TestDoc($qv,[string]$path,[string]$text) {
    if (Test-Path -LiteralPath $path) {
        throw "VERDICT=BLOCKED_DIAGNOSTIC_QVW_ALREADY_EXISTS path=$path"
    }
    $doc=$qv.CreateDoc()
    if ($null -eq $doc) { throw 'VERDICT=BLOCKED_QLIK_CREATE_DOC' }
    $props=$doc.GetProperties()
    $props.Script=$text
    $props.GenerateLogfile=$true
    $null=$doc.SetProperties($props)
    if (-not (Same-QlikScript ([string]$doc.GetProperties().Script) $text) -or
        -not [bool]$doc.GetProperties().GenerateLogfile) {
        throw 'VERDICT=BLOCKED_QLIK_SCRIPT_OR_LOG_SETTING'
    }
    $null=$doc.SaveAs($path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "VERDICT=BLOCKED_DIAGNOSTIC_QVW_SAVE path=$path"
    }
    return $doc
}
function Require-Markers([string]$path,[DateTime]$started,[string]$prefix,[string[]]$markers) {
    $lines=@()
    $fresh=$false
    for($i=0;$i -lt 20;$i++) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $fresh=(Get-Item -LiteralPath $path).LastWriteTimeUtc -ge $started.AddSeconds(-2)
            if($fresh) {
                $lines=@(Get-Content -LiteralPath $path -ErrorAction Stop |
                    Where-Object { $_.Contains($prefix) -and $_ -notmatch '\bTRACE\b' })
                if (@($lines | Where-Object { $_ -match 'VERDICT=(PASS|WRITTEN|BLOCKED)' }).Count -gt 0) {
                    break
                }
            }
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $fresh) { throw "VERDICT=BLOCKED_NATIVE_LOG_NOT_FRESH path=$path" }
    foreach($marker in $markers) {
        if (@($lines | Where-Object { $_.Contains($marker) }).Count -ne 1) {
            throw "VERDICT=BLOCKED_NATIVE_MARKER_MISSING_OR_DUPLICATED marker=$marker path=$path"
        }
    }
    if (@($lines | Where-Object { $_ -match 'VERDICT=BLOCKED' }).Count -gt 0) {
        throw "VERDICT=BLOCKED_NATIVE_QV_RELOAD path=$path"
    }
    foreach($line in $lines) { Write-Output $line }
}

$qv=$null; $docCreate=$null; $docAudit=$null; $targetSha=$null
$phase='INIT'
try {
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    Write-Output 'MODE=PHASE_V_POPULACAO_ONE_SHOT_CREATE_AND_READBACK'
    Write-Output "BRANCH=$branch"
    Write-Output "FACT_QVS_SHA256=$factSha"
    Write-Output "STORE_QVS_SHA256=$storeSha"
    Write-Output "AUDIT_QVS_SHA256=$auditSha"
    Write-Output "FACT_TARGET=$target"
    Write-Output 'SOURCE_QVDS_READ_ONLY=True TRANSF_MAIN_NOT_EXECUTED=True'

    $phase='CREATE'
    # Reuse the exact validated source QVS, THEN run the guarded STORE suffix.
    # The predecessor ends with an in-memory verdict; it has NO EXIT on success.
    $scriptCreate='SET ErrorMode=0;' + [Environment]::NewLine +
        'SET vP5PopImplMode=PREFLIGHT;' + [Environment]::NewLine +
        'SET vP5PopCreateAuthorization=AUTHORIZED_ONE_SHOT_CREATE_POPULACAO_20261015;' +
        [Environment]::NewLine + $factScript + [Environment]::NewLine + $storeScript
    $docCreate=Create-TestDoc $qv $createQvw $scriptCreate
    $startedCreate=[DateTime]::UtcNow
    Write-Output 'CREATE_RELOAD_STARTED=True'
    $ret=$docCreate.Reload()
    Write-Output 'CREATE_RELOAD_RETURNED=True'
    Write-Output "CREATE_RELOAD_API_RETURN=$ret"

    if (-not (Test-Path -LiteralPath $target -PathType Leaf) -or
        (Get-Item -LiteralPath $target).Length -le 0 -or
        (Get-Item -LiteralPath $target).LastWriteTimeUtc -lt $startedCreate.AddSeconds(-2)) {
        throw 'VERDICT=BLOCKED_NEW_QVD_MISSING_EMPTY_OR_NOT_CONTEMPORANEOUS'
    }
    Verify-Inventory 'AFTER_CREATE'
    Require-Markers $createLog $startedCreate '[V5-POP-FACT]' @(
        '[V5-POP-FACT] SOURCE ROWS=669 GRAIN=669 MUNICIPIOS=223 YEARS=3 FILES=3 MISS=0 BAD_DOMAIN=0 BAD_MEASURE=0 BAD_SK=0',
        '[V5-POP-FACT] OUTPUT ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 FIELDS=7',
        '[V5-POP-FACT] ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127',
        '[V5-POP-FACT] VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_QVD_APPROVED'
    )
    Require-Markers $createLog $startedCreate '[V5-POP-STORE]' @(
        '[V5-POP-STORE] START_ONE_SHOT_ONLY',
        '[V5-POP-STORE] ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 FIELDS=7',
        '[V5-POP-STORE] VERDICT=WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT'
    )
    $targetSha=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    Write-Output "FACT_QVD_SHA256_AFTER_CREATE=$targetSha"
    Write-Output "FACT_QVD_SIZE_BYTES=$((Get-Item -LiteralPath $target).Length)"
    $null=$docCreate.CloseDoc();$docCreate=$null

    $phase='AUDIT_READBACK'
    $docAudit=Create-TestDoc $qv $auditQvw $auditScript
    $startedAudit=[DateTime]::UtcNow
    Write-Output 'AUDIT_RELOAD_STARTED=True'
    $retAudit=$docAudit.Reload()
    Write-Output 'AUDIT_RELOAD_RETURNED=True'
    Write-Output "AUDIT_RELOAD_API_RETURN=$retAudit"
    Verify-Inventory 'AFTER_AUDIT'
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -cne $targetSha) {
        throw 'VERDICT=BLOCKED_CREATED_QVD_CHANGED_DURING_AUDIT'
    }
    Require-Markers $auditLog $startedAudit '[V5-POP-QVD-AUDIT]' @(
        '[V5-POP-QVD-AUDIT] START_INDEPENDENT_QVD_REOPEN',
        '[V5-POP-QVD-AUDIT] HEADER ROWS=669 FIELDS=7',
        '[V5-POP-QVD-AUDIT] SCHEMA_EXACT_7=True',
        '[V5-POP-QVD-AUDIT] TOTAL ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 BAD_DOMAIN=0 BAD_MEASURE=0',
        '[V5-POP-QVD-AUDIT] ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127',
        '[V5-POP-QVD-AUDIT] VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY'
    )
    Write-Output "FACT_QVD_SHA256_VERIFIED=$targetSha"
    Write-Output 'VERDICT=PASS_QV_POPULACAO_QVD_MATERIALIZED_AND_REOPENED_CANDIDATE_ONLY'
    Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
    Write-Output 'PRODUCTION_APPROVED=False'
}
catch {
    Write-Output "VERDICT=BLOCKED_CREATE_OR_AUDIT phase=$phase"
    Write-Output "RUNNER_FAILURE=$($_.Exception.Message)"
    foreach($file in @($createLog,$auditLog)) {
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            Write-Output "NATIVE_ERROR_CONTEXT_BEGIN path=$file"
            Get-Content -LiteralPath $file -Tail 85 -ErrorAction SilentlyContinue |
                ForEach-Object { Write-Output $_ }
            Write-Output 'NATIVE_ERROR_CONTEXT_END'
        }
    }
    Write-Output "FACT_TARGET_RETAINED_IF_PRESENT=$target"
    throw
}
finally {
    if ($null -ne $docAudit) {
        try {$null=$docAudit.CloseDoc()} catch {Write-Warning 'Feche manualmente QVW de auditoria.'}
    }
    if ($null -ne $docCreate) {
        try {$null=$docCreate.CloseDoc()} catch {Write-Warning 'Feche manualmente QVW de criacao.'}
    }
    # No auto-delete, no overwrite, no Quit(): may share the user's Qlik Desktop.
    # If execution partially fails, preserve all physical evidence for review.
    foreach($name in $baseline.Keys) {
        if (Test-Path -LiteralPath $name -PathType Leaf) {
            try {
                if ((Get-FileHash -LiteralPath $name -Algorithm SHA256).Hash -cne $baseline[$name]) {
                    Write-Warning "BLOCKED_QVD_CHANGED_AT_FINALLY file=$name"
                }
            } catch {Write-Warning "BLOCKED_QVD_HASH_UNAVAILABLE_AT_FINALLY file=$name"}
        } else {
            Write-Warning "BLOCKED_QVD_MISSING_AT_FINALLY file=$name"
        }
    }
}
