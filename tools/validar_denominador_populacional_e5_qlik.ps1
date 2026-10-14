# SAD PB / Phase VI / E5: QlikView 12 read-only population measure preflight.
# Uses a SAVED associative QVW (9 tables), never writes QVDs or changes inputs.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$AssocQvw,
    [string]$Root = (Get-Location).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$AssocQvw = [IO.Path]::GetFullPath($AssocQvw)
$qvsPath = Join-Path $Root 'TRANSFORMACAO\phase_vi_e5_population_denominator_preflight.qvs'
$municipioQvd = Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'
$popQvd = Join-Path $Root 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd'
$required = @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    (Join-Path $Root 'docs\academic\requirements.md'),
    $AssocQvw,$qvsPath,$municipioQvd,$popQvd
)
foreach ($file in $required) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Input not found: $file"
    }
}
if ([IO.Path]::GetExtension($AssocQvw).ToLowerInvariant() -ne '.qvw') {
    throw 'AssocQvw must be a .qvw document'
}
if ($AssocQvw.Contains(']') -or $AssocQvw.Contains([string][char]10) -or $AssocQvw.Contains([string][char]13)) {
    throw 'Invalid characters in QVW BINARY path'
}
$body = [IO.File]::ReadAllText($qvsPath,[Text.Encoding]::UTF8)
$refMunicipio = '[QVD\DIM_MUNICIPIO.qvd]'
$refPop = '[..\EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd]'
if (-not $body.Contains('SOURCE_QVW_9_TABLES_PASS') -or
    -not $body.Contains('VERDICT=PASS_IN_MEMORY_POP_VALUES_PRESELECTION_NOT_APPROVED') -or
    -not $body.Contains('LEFT JOIN (P6_FATO_POP_SIMULADA)') -or
    -not $body.Contains($refMunicipio) -or -not $body.Contains($refPop)) {
    throw 'E5 QVS fingerprint failed'
}
if ($body -match '(?im)^\s*(STORE|BINARY|EXECUTE|JOIN|INNER JOIN|RIGHT JOIN|OUTER JOIN)\b' -or
    [regex]::Matches($body,'(?im)^\s*LEFT JOIN\s*\(').Count -ne 1 -or
    $body -match '(?im)^\s*LEFT JOIN\s*\((?!P6_FATO_POP_SIMULADA\))') {
    throw 'Forbidden or unrecognized QVS data mutation operation'
}
$body = $body.Replace($refMunicipio,('['+$municipioQvd+']'))
$body = $body.Replace($refPop,('['+$popQvd+']'))
# BINARY is first script instruction and points to the validated saved model.
$script = 'BINARY [' + $AssocQvw + '];' + [Environment]::NewLine + $body
function SameScript([string]$a,[string]$b) {
    return ($a.Replace([string][char]13,'').TrimEnd() -ceq $b.Replace([string][char]13,'').TrimEnd())
}
$sha = @{}
foreach ($path in @($AssocQvw,$qvsPath,$municipioQvd,$popQvd)) {
    $sha[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ('SAD_P6_E5_DENOMINATOR_'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -ErrorAction Stop | Out-Null
$qvw = Join-Path $temp 'P6_E5_POP_DENOMINATOR_IN_MEMORY.qvw'
$log = "$qvw.log"
$qv = $null
$doc = $null
try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    $doc = $qv.CreateDoc()
    if ($null -eq $doc) { throw 'QlikView COM CreateDoc returned null' }
    $props = $doc.GetProperties()
    $props.Script = $script
    $props.GenerateLogfile = $true
    $null = $doc.SetProperties($props)
    if (-not (SameScript ([string]$doc.GetProperties().Script) $script)) {
        throw 'QlikView did not retain expected script'
    }
    $null = $doc.SaveAs($qvw)
    if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {
        throw 'Temporary QVW was not created'
    }
    $null = $doc.CloseDoc()
    $doc = $qv.OpenDoc($qvw,'','')
    if ($null -eq $doc) { throw 'Could not open temporary E5 document' }
    $start = [DateTime]::UtcNow
    Write-Output 'MODE=PHASE_VI_POP_DENOMINATOR_READ_ONLY_PREFLIGHT'
    Write-Output ('SOURCE_ASSOC_QVW_SHA256='+$sha[$AssocQvw])
    Write-Output 'RELOAD_STARTED=True'
    $null = $doc.Reload()
    Write-Output 'RELOAD_RETURNED=True'
    $null = $doc.Save() # ONLY the disposable QVW, for visual review
    $null = $doc.CloseDoc()
    $doc = $null
    if (-not (Test-Path -LiteralPath $log -PathType Leaf) -or
        (Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $start.AddSeconds(-2)) {
        throw 'Fresh native QlikView reload log missing'
    }
    $lines = @(Get-Content -LiteralPath $log | Where-Object { $_ -notmatch '\bTRACE\b' })
    $requiredMarkers = @(
        '[P6-E5] SOURCE_QVW_9_TABLES_PASS',
        '[P6-E5] ROWS=669 KEYS=669 INVALID=0',
        '[P6-E5] PB_2017=4025558 PB_2018=3996496 PB_2019=4018127',
        '[P6-E5] JP_2017=811598 JP_2018=800323 JP_2019=809015',
        '[P6-E5] TABLES=9 SYNTHETIC=0',
        '[P6-E5] VERDICT=PASS_IN_MEMORY_POP_VALUES_PRESELECTION_NOT_APPROVED',
        '[P6-E5] MONTHLY_DENOMINATOR_SELECTION=NOT_TESTED'
    )
    foreach ($marker in $requiredMarkers) {
        if (@($lines | Where-Object { $_.Contains($marker) }).Count -ne 1) {
            throw "Native QlikView PASS marker absent/duplicated: $marker"
        }
    }
    if (@($lines | Where-Object {
        $_ -match '\[P6-E5\] VERDICT=BLOCKED' -or
        $_ -match '(?i)circular reference|loosely coupled|comando desconhecido|unknown statement|syntax error'
    }).Count -ne 0) { throw 'Native QlikView log shows error or circular association' }
    foreach ($path in $sha.Keys) {
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sha[$path]) {
            throw "Immutable input changed during test: $path"
        }
    }
    Write-Output 'ALL_INPUT_SHA256_UNCHANGED=True'
    $lines | Where-Object { $_ -match '\[P6-E5\] (ROWS|PB_|JP_|TABLES|VERDICT=PASS|MONTHLY_DENOMINATOR)' } |
        ForEach-Object { Write-Output $_ }
    Write-Output 'OUTPUT_QVDS_WRITTEN=0'
    Write-Output 'FACT_QVDS_GENERATED=False'
    Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
    Write-Output 'MONTHLY_DENOMINATOR_SELECTION=NOT_TESTED'
    Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
    Write-Output 'VERDICT=PASS_IN_MEMORY_POP_VALUES_PRESELECTION_NOT_APPROVED'
    Write-Output ('VISUAL_REVIEW_QVW='+$qvw)
} catch {
    Write-Output ('VERDICT=FAIL_CLOSED_'+$_.Exception.Message)
    Write-Output ('TEMP_DIAGNOSTIC_DIR_RETAINED='+$temp)
    exit 1
} finally {
    if ($null -ne $doc) { try { $null = $doc.CloseDoc() } catch {} }
}
