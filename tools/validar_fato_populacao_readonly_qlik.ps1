# Fase V population: isolated READ-ONLY QlikView Desktop 12 gate, once.
# Creates ONLY a new diagnostic QVW/log; no QVD, TRANSF.qvw, STORE or merge.
# Preserve all existing diagnostic QVWs (including untracked) and source QVDs.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$expectedBranch = 'feat/phase-v-fato-populacao-readonly-preflight-20261015'
$qvs = Join-Path $Root 'TRANSFORMACAO\phase_v_fato_populacao_readonly_preflight.qvs'
$qvw = Join-Path $Root 'TRANSFORMACAO\V5_IBGE_FATO_POP_READONLY_PREFLIGHT.qvw'
$log = "$qvw.log"
$inputs = @(
    (Join-Path $Root 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd'),
    (Join-Path $Root 'EXTRACAO\QVD\REF_MUNICIPIO_PB_DERIVADA.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd')
)
$factTarget = Join-Path $Root 'TRANSFORMACAO\QVD\FATO_POPULACAO.qvd'
$linkTarget = Join-Path $Root 'TRANSFORMACAO\QVD\LINK_ANALISE.qvd'
$existingFact = @(
    (Join-Path $Root 'TRANSFORMACAO\QVD\FATO_INTERNACAO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\FATO_CAPACIDADE_LEITO.qvd')
)
$required = @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    (Join-Path $Root 'docs\academic\requirements.md'),
    $qvs
) + $inputs + $existingFact
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "VERDICT=BLOCKED_MISSING_REQUIRED_INPUT path=$path"
    }
}
foreach ($path in @($qvw,$log,$factTarget,$linkTarget)) {
    if (Test-Path -LiteralPath $path) {
        throw "VERDICT=BLOCKED_PREEXISTING_OUTPUT_NO_OVERWRITE path=$path"
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'VERDICT=BLOCKED_GIT_NOT_FOUND'
}
$branch = (& git -C $Root branch --show-current 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne $expectedBranch) {
    throw "VERDICT=BLOCKED_WRONG_BRANCH expected=$expectedBranch actual=$branch"
}
$dirty = @(& git -C $Root status --porcelain --untracked-files=no 2>$null)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
    throw 'VERDICT=BLOCKED_TRACKED_WORKTREE_DIRTY'
}
$source = [IO.File]::ReadAllText($qvs,[Text.Encoding]::UTF8)
$sourceSha = (Get-FileHash -LiteralPath $qvs -Algorithm SHA256).Hash
if (-not $source.Contains("FROM [..\EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd] (qvd);") -or
    -not $source.Contains("FROM [..\EXTRACAO\QVD\REF_MUNICIPIO_PB_DERIVADA.qvd] (qvd);") -or
    -not $source.Contains("FROM [QVD\DIM_MUNICIPIO.qvd] (qvd)") -or
    -not $source.Contains("FROM [QVD\DIM_TEMPO.qvd] (qvd)") -or
    -not $source.Contains('IF ''$(vP5PopMode)'' <> ''PREFLIGHT'' THEN') -or
    -not $source.Contains('VERDICT=PASS_SOURCE_ROLES_ONLY_NOT_FACT_APPROVAL') -or
    @([regex]::Matches($source,'(?im)^\s*STORE\s+')).Count -ne 0 -or
    $source -match '(?im)^\s*(EXECUTE|BINARY|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN|RENAME)\b' -or
    $source -match '\$\((Must_Include|Include)') {
    throw 'VERDICT=BLOCKED_QVS_POLICY_NOT_READ_ONLY'
}
$qvdDirectories=@(
    (Join-Path $Root 'EXTRACAO\QVD'),
    (Join-Path $Root 'TRANSFORMACAO\QVD')
)
$baseline=@{}
foreach ($dir in $qvdDirectories) {
    foreach ($file in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
        $baseline[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
}
# Expected after the two earlier, validated fact QVDs: 10 extraction + 8 dims + 2 facts.
if ($baseline.Count -ne 20) {
    throw "VERDICT=BLOCKED_UNEXPECTED_QVD_INVENTORY expected=20 actual=$($baseline.Count)"
}
foreach ($file in $inputs + $existingFact) {
    if (-not $baseline.ContainsKey($file)) {
        throw "VERDICT=BLOCKED_QVD_NOT_IN_FROZEN_INVENTORY path=$file"
    }
}
function Assert-QvdInventory([string]$stage) {
    $seen=@{}
    foreach($dir in $qvdDirectories) {
        foreach($file in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
            $path=$file.FullName
            if (-not $baseline.ContainsKey($path)) {
                throw "VERDICT=BLOCKED_UNEXPECTED_NEW_QVD stage=$stage path=$path"
            }
            $seen[$path]=1
            if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $baseline[$path]) {
                throw "VERDICT=BLOCKED_QVD_SHA_CHANGED stage=$stage path=$path"
            }
        }
    }
    foreach($path in $baseline.Keys) {
        if (-not $seen.ContainsKey($path)) {
            throw "VERDICT=BLOCKED_QVD_DISAPPEARED stage=$stage path=$path"
        }
    }
    if ($seen.Count -ne $baseline.Count) {
        throw "VERDICT=BLOCKED_QVD_COUNT_CHANGED stage=$stage"
    }
    Write-Output "ALL_4_SOURCE_QVD_SHA256_UNCHANGED=$stage"
    Write-Output "ALL_20_PREEXISTING_QVD_SHA256_UNCHANGED=$stage"
    Write-Output "NO_NEW_QVD_GENERATED=$stage"
}
Write-Output 'MODE=PHASE_V_POPULATION_READ_ONLY_PREFLIGHT'
Write-Output "BRANCH=$branch"
Write-Output "SCRIPT_SHA256=$sourceSha"
Write-Output "QVD_INVENTORY_BEFORE=$($baseline.Count)"
Write-Output 'TRANSF_MAIN_NOT_EXECUTED=True'
Write-Output 'FACT_POP_QVD_STORE_REQUESTED=False'
Write-Output "DIAGNOSTIC_QVW=$qvw"
$qv=$null;$doc=$null
try {
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $doc=$qv.CreateDoc()
    if ($null -eq $doc) {throw 'VERDICT=BLOCKED_COM_CREATEDOC'}
    $runScript='SET ErrorMode=0;' + [Environment]::NewLine +
        'SET vP5PopMode=PREFLIGHT;' + [Environment]::NewLine + $source
    $props=$doc.GetProperties()
    $props.Script=$runScript
    $props.GenerateLogfile=$true
    $null=$doc.SetProperties($props)
    $actual=([string]$doc.GetProperties().Script).Replace([string][char]13,'').TrimEnd()
    $expected=$runScript.Replace([string][char]13,'').TrimEnd()
    if ($actual -cne $expected -or -not [bool]$doc.GetProperties().GenerateLogfile) {
        throw 'VERDICT=BLOCKED_QVW_SCRIPT_OR_LOG_SETTINGS'
    }
    $null=$doc.SaveAs($qvw)
    if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {
        throw 'VERDICT=BLOCKED_QVW_NOT_SAVED'
    }
    $start=[DateTime]::UtcNow
    Write-Output 'RELOAD_STARTED=True'
    $retval=$doc.Reload()
    Write-Output 'RELOAD_RETURNED=True'
    Write-Output "RELOAD_API_RETURN=$retval"
    Assert-QvdInventory 'AFTER_RELOAD'
    foreach($path in @($factTarget,$linkTarget)) {
        if (Test-Path -LiteralPath $path) {
            throw "VERDICT=BLOCKED_UNAUTHORIZED_TARGET_CREATED path=$path"
        }
    }
    $lines=@();$fresh=$false
    for ($i=0;$i -lt 20;$i++) {
        if (Test-Path -LiteralPath $log -PathType Leaf) {
            $fresh=(Get-Item -LiteralPath $log).LastWriteTimeUtc -ge $start.AddSeconds(-2)
            if($fresh) {
                $lines=@(Get-Content -LiteralPath $log -ErrorAction Stop |
                    Where-Object { $_.Contains('[V5-POP-PREFLIGHT]') -and $_ -notmatch '\bTRACE\b' })
                if(@($lines | Where-Object { $_.Contains('VERDICT=') }).Count -gt 0){break}
            }
        }
        Start-Sleep -Milliseconds 500
    }
    if(-not $fresh){throw 'VERDICT=BLOCKED_NO_FRESH_NATIVE_LOG'}
    $markers=@(
        '[V5-POP-PREFLIGHT] START MODE=PREFLIGHT READ_ONLY=True',
        '[V5-POP-PREFLIGHT] REFERENCES BRIDGE=223 BRIDGE_U7=223 BRIDGE_U6=223 BRIDGE_BAD=0 DIM_MUN=223 DIM_U7=223 DIM_U6=223 DIM_USK=223 DIM_BAD=0 YEAR=3 YEAR_U=3 YEAR_SK=3 YEAR_BAD=0',
        '[V5-POP-PREFLIGHT] SOURCE ROWS=669 GRAIN=669 IBGE7=223 YEARS=3 FILES=3 BAD_DOMAIN=0 BAD_MEASURE=0',
        '[V5-POP-PREFLIGHT] ROLES BRIDGE_MISS=0 DIM6_MISS=0 DIM7_MISS=0 YEAR_MISS=0 SK_BAD=0',
        '[V5-POP-PREFLIGHT] ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127',
        '[V5-POP-PREFLIGHT] VERDICT=PASS_SOURCE_ROLES_ONLY_NOT_FACT_APPROVAL',
        '[V5-POP-PREFLIGHT] FACT_POPULACAO_QVD_GENERATED=False LINK_TABLE_NOT_TESTED=True PRODUCTION_APPROVED=False'
    )
    foreach($m in $markers) {
        if(@($lines | Where-Object { $_.Contains($m) }).Count -ne 1){
            throw "VERDICT=BLOCKED_EXPECTED_NATIVE_MARKER_MISSING_OR_DUPLICATED marker=$m"
        }
    }
    if(@($lines | Where-Object { $_ -match '\[V5-POP-PREFLIGHT\] VERDICT=BLOCKED' }).Count -gt 0) {
        throw 'VERDICT=BLOCKED_NATIVE_SCRIPT_ERROR'
    }
    Write-Output "LOG=$log"
    foreach($line in $lines){Write-Output $line}
    Write-Output 'VERDICT=PASS_LOCAL_POPULATION_SOURCE_ROLES_READ_ONLY_PREFLIGHT_ONLY'
    Write-Output 'FACT_POPULACAO_QVD_GENERATED=False'
    Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
    Write-Output 'PRODUCTION_APPROVED=False'
}
catch {
    Write-Output "RUNNER_FAILURE=$($_.Exception.Message)"
    if(Test-Path -LiteralPath $log -PathType Leaf){
        Write-Output 'NATIVE_LOG_TAIL_BEGIN'
        Get-Content -LiteralPath $log -Tail 100 -ErrorAction SilentlyContinue |
            ForEach-Object {Write-Output $_}
        Write-Output 'NATIVE_LOG_TAIL_END'
    }
    Write-Output 'PRESERVE_ALL_QVWS_LOGS_QVDS_DO_NOT_RETRY=True'
    throw
}
finally {
    if($null -ne $doc){
        try{$null=$doc.CloseDoc()}catch{Write-Warning 'Feche o QVW diagnostico manualmente se necessario.'}
    }
    # Qlik COM desktop may be shared. Do not call Quit(), cleanup or overwrite.
    try{Assert-QvdInventory 'AT_END'}catch{Write-Warning $_.Exception.Message}
}
