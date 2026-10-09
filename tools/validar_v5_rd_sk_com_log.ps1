# SAD SUS PB: enable the native QlikView reload log for an existing isolated QVW
# and execute the preflight one more time. Does not modify staging QVDs,
# TRANSF.qvw, extracted data or repository scripts.
[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = [System.IO.Path]::GetFullPath($Root)
$folder = Join-Path $Root 'TRANSFORMACAO'
$target = Join-Path $folder 'V5_RD_SK_PREFLIGHT.qvw'
$source = Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'

if (-not (Test-Path -LiteralPath (Join-Path $Root 'AGENTS.md') -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $Root 'docs\project\current-state.md') -PathType Leaf)) {
    throw 'A pasta informada nao parece ser a raiz do repositorio SAD.'
}
if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    throw "Documento de teste ausente: $target"
}
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "QVD de staging ausente: $source"
}

$qv = $null
$doc = $null
try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    $doc = $qv.OpenDoc($target, '', '')
    if ($null -eq $doc) { throw 'OpenDoc nao retornou documento QlikView.' }

    $properties = $doc.GetProperties()
    if ($null -eq $properties) { throw 'GetProperties nao retornou propriedades.' }
    $script = [string]$properties.Script
    if (-not $script.Contains('[V5-RD-SK] START READ_ONLY STAGING QVD PROJECTION') -or
        -not $script.Contains('PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY') -or
        -not $script.Contains('SRC_SIH_RD.qvd') -or
        $script -match '(?im)^\s*STORE\s+') {
        throw 'Documento nao possui o script isolado esperado; nenhuma recarga executada.'
    }

    # QlikView COM DocumentProperties (Qlik Community Automation examples).
    $properties.GenerateLogfile = $true
    $null = $doc.SetProperties($properties)
    if (-not [bool]$doc.GetProperties().GenerateLogfile) {
        throw 'GenerateLogfile nao foi confirmado pelo QlikView.'
    }
    $null = $doc.Save()
    Write-Output 'MODE=PHASE_V_EXISTING_QVW_COM_LOG_RELOAD'
    Write-Output "DOCUMENT=$target"
    Write-Output 'NATIVE_LOG_ENABLED=True'
    Write-Output 'STAGING_QVD_CHANGE_CHECK=SHA256_BEFORE_AFTER_RELOAD'
    Write-Output 'FACT_QVD_GENERATED=False'

    $sourceHashBefore = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    $start = [DateTime]::UtcNow
    Write-Output 'RELOAD_STARTED=True'
    $retval = $doc.Reload()
    Write-Output 'RELOAD_RETURNED=True'
    Write-Output "RELOAD_API_RETURN=$retval"
    $sourceHashAfter = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    if ($sourceHashAfter -ne $sourceHashBefore) {
        throw 'HASH do staging RD mudou durante teste isolado; investigar imediatamente.'
    }
    Write-Output 'STAGING_QVD_SHA256_UNCHANGED=True'

    # Check contemporaneous logs only; do not mistake an old log for this reload.
    $latest = $null
    for ($attempt=0; $attempt -lt 8; $attempt++) {
        $latest = Get-ChildItem -LiteralPath $folder -Filter 'V5_RD_SK_PREFLIGHT.qvw*.log' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTimeUtc -ge $start.AddSeconds(-2) } |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1
        if ($null -ne $latest) { break }
        Start-Sleep -Milliseconds 500
    }

    if ($null -eq $latest) {
        Write-Output 'VERDICT=INCONCLUSIVE_NO_NEW_QLIK_LOG'
        Write-Output 'NEXT=OPEN_THIS_QVW_IN_QLIKVIEW_AND_CHECK_SETTINGS_DOCUMENT_PROPERTIES_GENERAL_GENERATE_LOGFILE'
        exit 2
    }
    Write-Output "LOG=$($latest.FullName)"
    Write-Output "LOG_BYTES=$($latest.Length)"

    $actual = @()
    # The log may appear before QlikView has flushed the final TRACE lines.
    for ($attempt=0; $attempt -lt 12; $attempt++) {
        $actual = @(
            Get-Content -LiteralPath $latest.FullName -ErrorAction Stop |
            Where-Object { $_ -match '\[V5-RD-SK\]' -and $_ -notmatch '\bTRACE\b' }
        )
        if (@($actual | Where-Object { $_ -match '\[V5-RD-SK\] (FAIL|VERDICT=)' }).Count -gt 0) { break }
        Start-Sleep -Milliseconds 500
    }
    foreach ($line in ($actual | Select-Object -Last 12)) {
        Write-Output $line
    }
    $expectedMetrics = 'ROWS=566672 DISTINCT_SK=566672 NULL_SK=0 IDENT5=11583 IDENT1=555089 MONTHS=36 SOURCE_FILES=36'
    $validMetrics = @($actual | Where-Object { $_.Contains($expectedMetrics) }).Count -gt 0
    $pass = @($actual | Where-Object { $_.Contains('VERDICT=PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY') }).Count -gt 0
    $fail = @($actual | Where-Object { $_ -match '\[V5-RD-SK\] (FAIL|VERDICT=BLOCKED)' }).Count -gt 0
    if ($validMetrics -and $pass -and -not $fail) {
        Write-Output 'VERDICT=PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY'
        Write-Output 'KEY_STABILITY_POLICY=STILL_PENDING'
        exit 0
    }
    Write-Output 'VERDICT=INCONCLUSIVE_OR_BLOCKED_INSPECT_FULL_LOG'
    Write-Output 'KEY_STABILITY_POLICY=NOT_APPROVED'
    exit 3
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    if ($null -ne $doc) {
        try { $null = $doc.CloseDoc() } catch { Write-Warning 'Feche o documento isolado no QlikView se permanecer aberto.' }
    }
    # Never call Application.Quit(): it may share an existing user session.
}