# Fase V: FATO_CAPACIDADE_LEITO in-memory candidate, isolated QlikView Desktop 12.
# Authorized: new diagnostic QVW + .log only. Never run TRANSF.qvw or STORE QVD.
# On failure retain diagnostics and all QVDs; do not delete or retry blindly.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$branchExpected = 'feat/phase-v-fato-capacidade-implementation'
$qvs = Join-Path $Root 'TRANSFORMACAO\transf_fato_capacidade_leito.qvs'
$qvw = Join-Path $Root 'TRANSFORMACAO\V5_LT_FATO_CAPACIDADE_IMPL_PREFLIGHT.qvw'
$log = "$qvw.log"
$factTarget = Join-Path $Root 'TRANSFORMACAO\QVD\FATO_CAPACIDADE_LEITO.qvd'
$sourceInputs = @(
    (Join-Path $Root 'EXTRACAO\QVD\SRC_CNES_LT.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TIPO_LEITO.qvd')
)
$required = @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    (Join-Path $Root 'docs\academic\requirements.md'),
    $qvs
) + $sourceInputs
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "VERDICT=BLOCKED_MISSING_REQUIRED_INPUT path=$path"
    }
}
foreach ($path in @($qvw,$log,$factTarget)) {
    if (Test-Path -LiteralPath $path) {
        throw "VERDICT=BLOCKED_OUTPUT_OR_FACT_ALREADY_EXISTS path=$path"
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'VERDICT=BLOCKED_GIT_MISSING'
}
$branch = (& git -C $Root branch --show-current 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne $branchExpected) {
    throw "VERDICT=BLOCKED_GIT_BRANCH actual=$branch expected=$branchExpected"
}
$dirty = @(& git -C $Root status --porcelain --untracked-files=no 2>$null)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
    throw 'VERDICT=BLOCKED_TRACKED_WORKTREE_DIRTY'
}
$source = [IO.File]::ReadAllText($qvs,[Text.Encoding]::UTF8)
$sourceSha = (Get-FileHash -LiteralPath $qvs -Algorithm SHA256).Hash
if (-not $source.Contains('[V5-CAP-FACT] VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_PHYSICAL_APPROVAL') -or
    -not $source.Contains('IF ''$(vP5CapacidadeMode)'' <> ''PREFLIGHT'' THEN') -or
    -not $source.Contains("FROM [..\EXTRACAO\QVD\SRC_CNES_LT.qvd] (qvd);") -or
    -not $source.Contains("Hash128('SAD-LINK-V1',") -or
    @([regex]::Matches($source,'(?im)^\s*STORE\s+')).Count -ne 0 -or
    $source -match '(?im)^\s*(EXECUTE|BINARY|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN)\b' -or
    $source -match '\$\((Must_Include|Include)') {
    throw 'VERDICT=BLOCKED_QVS_NOT_ISOLATED_NO_STORE_PREFLIGHT'
}
$qvdDirectories = @((Join-Path $Root 'EXTRACAO\QVD'),(Join-Path $Root 'TRANSFORMACAO\QVD'))
$existingQvds = @{}
foreach ($dir in $qvdDirectories) {
    foreach ($f in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
        $existingQvds[$f.FullName] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    }
}
$inputSha = @{}
foreach ($path in $sourceInputs) { $inputSha[$path] = $existingQvds[$path] }
if ($existingQvds.Count -lt $sourceInputs.Count -or @($inputSha.Values | Where-Object { -not $_ }).Count -gt 0) {
    throw 'VERDICT=BLOCKED_INPUT_QVD_INVENTORY_INCOMPLETE'
}
function Assert-QvdPreserved([string]$stage) {
    $seen = @{}
    foreach ($dir in $qvdDirectories) {
        foreach ($f in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
            $name=$f.FullName
            $seen[$name]=1
            if (-not $existingQvds.ContainsKey($name)) {
                throw "VERDICT=BLOCKED_NEW_QVD stage=$stage path=$name"
            }
            if ($existingQvds[$name] -cne (Get-FileHash -LiteralPath $name -Algorithm SHA256).Hash) {
                throw "VERDICT=BLOCKED_MODIFIED_QVD stage=$stage path=$name"
            }
        }
    }
    foreach ($path in $existingQvds.Keys) {
        if (-not $seen.ContainsKey($path)) {
            throw "VERDICT=BLOCKED_MISSING_QVD stage=$stage path=$path"
        }
    }
    foreach ($path in $sourceInputs) {
        if ($inputSha[$path] -cne (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash) {
            throw "VERDICT=BLOCKED_INPUT_SHA_CHANGED stage=$stage path=$path"
        }
    }
    Write-Output "ALL_5_INPUT_QVD_SHA256_UNCHANGED=$stage"
    Write-Output "ALL_PREEXISTING_QVD_SHA256_UNCHANGED=$stage COUNT=$($existingQvds.Count)"
    Write-Output "NO_NEW_QVD_GENERATED=$stage"
}
$qv=$null
$doc=$null
try {
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $doc=$qv.CreateDoc()
    if ($null -eq $doc) { throw 'VERDICT=BLOCKED_COM_CREATEDOC' }
    $runScript='SET ErrorMode=0;' + [Environment]::NewLine +
        'SET vP5CapacidadeMode=PREFLIGHT;' + [Environment]::NewLine + $source
    $p=$doc.GetProperties()
    $p.Script=$runScript
    $p.GenerateLogfile=$true
    $null=$doc.SetProperties($p)
    $actual=([string]$doc.GetProperties().Script).Replace([string][char]13,'').TrimEnd()
    $expected=$runScript.Replace([string][char]13,'').TrimEnd()
    if ($actual -cne $expected -or -not [bool]$doc.GetProperties().GenerateLogfile) {
        throw 'VERDICT=BLOCKED_QVW_SCRIPT_LOG_MISMATCH'
    }
    $null=$doc.SaveAs($qvw)
    if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {
        throw 'VERDICT=BLOCKED_QVW_SAVE'
    }
    Write-Output 'MODE=PHASE_V_FATO_CAPACIDADE_LEITO_ISOLATED_IN_MEMORY_PREFLIGHT'
    Write-Output "BRANCH=$branch"
    Write-Output "SCRIPT_SHA256=$sourceSha"
    Write-Output "QVD_INVENTORY_BEFORE=$($existingQvds.Count)"
    Write-Output "DIAGNOSTIC_QVW=$qvw"
    Write-Output 'TRANSF_MAIN_NOT_EXECUTED=True'
    Write-Output 'FACT_QVD_STORE_REQUESTED=False'
    $started=[DateTime]::UtcNow
    Write-Output 'RELOAD_STARTED=True'
    $retval=$doc.Reload()
    Write-Output 'RELOAD_RETURNED=True'
    Write-Output "RELOAD_API_RETURN=$retval"
    Assert-QvdPreserved 'AFTER_RELOAD'
    if (Test-Path -LiteralPath $factTarget) {
        throw 'VERDICT=BLOCKED_FACT_QVD_CREATED_UNEXPECTEDLY'
    }
    $lines=@()
    $fresh=$false
    for($tryCount=0;$tryCount -lt 20;$tryCount++) {
        if (Test-Path -LiteralPath $log -PathType Leaf) {
            $fresh=(Get-Item -LiteralPath $log).LastWriteTimeUtc -ge $started.AddSeconds(-2)
            if($fresh) {
                $lines=@(Get-Content -LiteralPath $log -ErrorAction Stop |
                    Where-Object { $_.Contains('[V5-CAP-FACT]') -and $_ -notmatch '\bTRACE\b' })
                if (@($lines | Where-Object { $_.Contains('VERDICT=') }).Count -gt 0) {break}
            }
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $fresh) {throw 'VERDICT=BLOCKED_NO_CONTEMPORANEOUS_NATIVE_LOG'}
    $expectedMarkers=@(
        '[V5-CAP-FACT] START MODE=PREFLIGHT',
        '[V5-CAP-FACT] SOURCE ROWS=35518 UNIQUE=35518 MONTHS=36 FILES=36 PAIRS=57 PAIR_MONTHS=2021 TYPE3_BED66=1480 TYPE7_BED70=5 NULL=0 BAD_DOMAIN=0 BAD_MEASURE=0',
        '[V5-CAP-FACT] ROLES COMP=0 ANO=0 MUNICIPIO_SERVICO=0 ESTABELECIMENTO=0 TIPO_LEITO=0',
        '[V5-CAP-FACT] SNAPSHOT_SUMS_UNSAFE_AS_PERIOD_TOTAL EXIST=337147 SUS=270076 NSUS=67071',
        '[V5-CAP-FACT] YEARS=3 YEAR_BAD=0',
        '[V5-CAP-FACT] VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_PHYSICAL_APPROVAL',
        '[V5-CAP-FACT] FACT_QVD_GENERATED=False LINK_TABLE_NOT_TESTED=True PRODUCTION_APPROVED=False'
    )
    foreach($m in $expectedMarkers) {
        if (@($lines | Where-Object { $_.Contains($m) }).Count -ne 1) {
            throw "VERDICT=BLOCKED_NATIVE_MARKER_MISSING_OR_DUPLICATE marker=$m"
        }
    }
    if (@($lines | Where-Object { $_ -match '\[V5-CAP-FACT\] VERDICT=BLOCKED' }).Count -gt 0 -or
        @($lines | Where-Object {
            $_ -match '\[V5-CAP-FACT\] OUTPUT ROWS=35518 UNIQUE=35518 LINKS=[1-9][0-9]* NULL=0 EXIST=337147 SUS=270076 NSUS=67071 INVALID=0'
        }).Count -ne 1) {
        throw 'VERDICT=BLOCKED_NATIVE_OUTPUT_OR_ERROR'
    }
    Write-Output "LOG=$log"
    foreach($line in $lines) { Write-Output $line }
    Write-Output 'VERDICT=PASS_ISOLATED_CAPACIDADE_FACT_PREFLIGHT_CANDIDATE_ONLY'
    Write-Output 'FACT_CAPACIDADE_LEITO_QVD_GENERATED=False'
    Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
    Write-Output 'PRODUCTION_APPROVED=False'
}
catch {
    Write-Output "RUNNER_FAILURE=$($_.Exception.Message)"
    if (Test-Path -LiteralPath $log -PathType Leaf) {
        Write-Output 'NATIVE_LOG_TAIL_BEGIN'
        Get-Content -LiteralPath $log -Tail 80 -ErrorAction SilentlyContinue |
            ForEach-Object {Write-Output $_}
        Write-Output 'NATIVE_LOG_TAIL_END'
    }
    throw
}
finally {
    if ($null -ne $doc) {
        try {$null=$doc.CloseDoc()} catch { Write-Warning 'Feche manualmente o QVW de teste, se necessario.' }
    }
    # QlikView COM may share the interactive session. Do not call Quit().
    try {Assert-QvdPreserved 'AT_END'} catch {Write-Warning $_.Exception.Message}
}
