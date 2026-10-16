# Fase V: capacity/LT preflight in isolated QlikView Desktop 12 document.
# READ-ONLY regarding all existing QVDs. Creates only a diagnostic QVW/log.
# No TRANSF.qvw reload, STORE, FATO_CAPACIDADE_LEITO.qvd or Link Table.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$expectedBranch = 'feat/phase-v-capacidade-leito-preflight-20261015'
$qvs = Join-Path $Root 'TRANSFORMACAO\phase_v_capacidade_leito_preflight.qvs'
$qvw = Join-Path $Root 'TRANSFORMACAO\V5_LT_CAPACIDADE_PREFLIGHT.qvw'
$log = "$qvw.log"
$factQvd = Join-Path $Root 'TRANSFORMACAO\QVD\FATO_CAPACIDADE_LEITO.qvd'
$inputQvds = @(
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
) + $inputQvds
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "VERDICT=BLOCKED_MISSING_REQUIRED_INPUT path=$path"
    }
}
foreach ($path in @($qvw,$log,$factQvd)) {
    if (Test-Path -LiteralPath $path) {
        throw "VERDICT=BLOCKED_PREEXISTING_OUTPUT_OR_FACT path=$path"
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'VERDICT=BLOCKED_GIT_NOT_AVAILABLE'
}
$branch = (& git -C $Root branch --show-current 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne $expectedBranch) {
    throw "VERDICT=BLOCKED_WRONG_BRANCH actual=$branch expected=$expectedBranch"
}
$dirty = @(& git -C $Root status --porcelain --untracked-files=no 2>$null)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
    throw 'VERDICT=BLOCKED_TRACKED_WORKTREE_NOT_CLEAN'
}
$script = [IO.File]::ReadAllText($qvs, [Text.Encoding]::UTF8)
if (-not $script.Contains('[V5-CAP] VERDICT=PASS_QV_CNES_LT_READ_ONLY_PREFLIGHT_CANDIDATE_ONLY') -or
    -not $script.Contains('FROM [..\EXTRACAO\QVD\SRC_CNES_LT.qvd] (qvd);') -or
    @([regex]::Matches($script,'(?im)^\s*STORE\s+')).Count -ne 0 -or
    $script -match '(?im)^\s*(BINARY|EXECUTE|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN)\b' -or
    $script -match '\$\((Must_Include|Include)') {
    throw 'VERDICT=BLOCKED_QVS_READ_ONLY_POLICY_MISMATCH'
}
$qvdDirs = @((Join-Path $Root 'EXTRACAO\QVD'),(Join-Path $Root 'TRANSFORMACAO\QVD'))
$originalQvds = @{}
foreach ($dir in $qvdDirs) {
    foreach ($f in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
        $originalQvds[$f.FullName] = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    }
}
$scriptSha = (Get-FileHash -LiteralPath $qvs -Algorithm SHA256).Hash
function Assert-QvdInventory {
    $seen = @{}
    foreach ($dir in $qvdDirs) {
        foreach ($f in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
            $seen[$f.FullName] = 1
            if (-not $originalQvds.ContainsKey($f.FullName)) {
                throw "VERDICT=BLOCKED_UNEXPECTED_QVD_CREATED path=$($f.FullName)"
            }
            if ($originalQvds[$f.FullName] -cne (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash) {
                throw "VERDICT=BLOCKED_EXISTING_QVD_SHA_CHANGED path=$($f.FullName)"
            }
        }
    }
    foreach ($name in $originalQvds.Keys) {
        if (-not $seen.ContainsKey($name)) {
            throw "VERDICT=BLOCKED_EXISTING_QVD_MISSING path=$name"
        }
    }
    Write-Output "ALL_EXISTING_QVDS_SHA256_UNCHANGED=True COUNT=$($originalQvds.Count)"
}
$qv = $null
$doc = $null
try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    $doc = $qv.CreateDoc()
    if ($null -eq $doc) { throw 'VERDICT=BLOCKED_CREATE_QVW_DOC' }
    $props = $doc.GetProperties()
    $props.Script = $script
    $props.GenerateLogfile = $true
    $null = $doc.SetProperties($props)
    $actualScript = ([string]$doc.GetProperties().Script).Replace([string][char]13,'').TrimEnd()
    $expectedScript = $script.Replace([string][char]13,'').TrimEnd()
    if ($actualScript -cne $expectedScript -or -not [bool]$doc.GetProperties().GenerateLogfile) {
        throw 'VERDICT=BLOCKED_QVW_SCRIPT_OR_LOG_POLICY'
    }
    $null = $doc.SaveAs($qvw)
    if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {
        throw 'VERDICT=BLOCKED_QVW_NOT_SAVED'
    }
    Write-Output 'MODE=PHASE_V_CAPACIDADE_LT_READ_ONLY_PREFLIGHT'
    Write-Output "BRANCH=$branch"
    Write-Output "SCRIPT_SHA256=$scriptSha"
    Write-Output "QVD_INVENTORY_BEFORE=$($originalQvds.Count)"
    Write-Output 'TRANSF_MAIN_NOT_EXECUTED=True FACT_QVD_STORE_REQUESTED=False'
    Write-Output "QVW=$qvw"
    $started=[DateTime]::UtcNow
    Write-Output 'RELOAD_STARTED=True'
    $api=$doc.Reload()
    Write-Output 'RELOAD_RETURNED=True'
    Write-Output "RELOAD_API_RETURN=$api"
    Assert-QvdInventory
    if (Test-Path -LiteralPath $factQvd) {
        throw 'VERDICT=BLOCKED_FACT_QVD_CREATED_UNEXPECTEDLY'
    }
    Write-Output 'FACT_CAPACIDADE_QVD_GENERATED=False'
    $fresh=$false
    $lines=@()
    for($i=0;$i -lt 20;$i++) {
        if(Test-Path -LiteralPath $log -PathType Leaf) {
            $fresh=(Get-Item -LiteralPath $log).LastWriteTimeUtc -ge $started.AddSeconds(-2)
            if($fresh) {
                $lines=@(Get-Content -LiteralPath $log -ErrorAction Stop |
                    Where-Object { $_ -match '\[V5-CAP\]' -and $_ -notmatch '\bTRACE\b' })
                if(@($lines | Where-Object { $_.Contains('VERDICT=') }).Count -gt 0) { break }
            }
        }
        Start-Sleep -Milliseconds 500
    }
    if(-not $fresh) { throw 'VERDICT=BLOCKED_NO_FRESH_NATIVE_LOG' }
    $expected=@(
        '[V5-CAP] START MODE=READ_ONLY_PREFLIGHT',
        '[V5-CAP] SOURCE ROWS=35518 UNIQUE_GRAIN=35518 MONTHS=36 FILES=36 PAIRS=57 PAIR_MONTHS=2021 TYPE3_BED66=1480 TYPE7_BED70=5 DOMAIN_BAD=0 MEASURE_BAD=0',
        '[V5-CAP] ROLES COMP=0 ANO=0 MUNICIPIO_SERVICO=0 ESTABELECIMENTO=0 TIPO_LEITO=0',
        '[V5-CAP] VERDICT=PASS_QV_CNES_LT_READ_ONLY_PREFLIGHT_CANDIDATE_ONLY',
        '[V5-CAP] FACT_QVD_GENERATED=False LINK_TABLE_NOT_TESTED=True PRODUCTION_APPROVED=False'
    )
    foreach($marker in $expected) {
        if(@($lines | Where-Object { $_.Contains($marker) }).Count -ne 1) {
            throw "VERDICT=BLOCKED_NATIVE_MARKER_MISSING_OR_DUPLICATED marker=$marker"
        }
    }
    if(@($lines | Where-Object { $_ -match '\[V5-CAP\] VERDICT=BLOCKED' }).Count -gt 0 -or
       @($lines | Where-Object { $_ -match '\[V5-CAP\] SNAPSHOT_SUMS_UNSAFE_AS_PERIOD_TOTAL EXIST=.* SUS=.* NSUS=.*' }).Count -ne 1) {
        throw 'VERDICT=BLOCKED_NATIVE_RESULT_OR_MISSING_MEASURE_SUMS'
    }
    Write-Output "LOG=$log"
    foreach($line in $lines) { Write-Output $line }
    Write-Output 'VERDICT=PASS_LOCAL_QV_CAPACIDADE_LT_PREFLIGHT_ONLY_NOT_QVD_APPROVAL'
}
catch {
    Write-Output "RUNNER_FAILURE=$($_.Exception.Message)"
    if(Test-Path -LiteralPath $log -PathType Leaf) {
        Write-Output 'NATIVE_LOG_TAIL_BEGIN'
        Get-Content -LiteralPath $log -Tail 85 -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_ }
        Write-Output 'NATIVE_LOG_TAIL_END'
    }
    throw
}
finally {
    if($null -ne $doc) {
        try {$null=$doc.CloseDoc()} catch {Write-Warning 'Fechar QVW de preflight manualmente.'}
    }
    # No Quit(): COM may share QlikView Desktop user session.
    try { Assert-QvdInventory } catch { Write-Warning $_.Exception.Message }
}
