# SAD PB F4-P5: create an IN-MEMORY measurement/filter projection in disposable QVW.
# No original QVW save/reload, no STORE, no fact/Link QVD, no P5 approval.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SourceQvw,
    [string]$Root = (Get-Location).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$src = [IO.Path]::GetFullPath($SourceQvw)
if ([IO.Path]::GetFileName($src) -notmatch '^(P6_E5_POP_DENOMINATOR_IN_MEMORY|SAD_P6_E5_POP_SEMANTICS_COPY(?:_[0-9a-f]{32})?)\.qvw$') {
    throw 'BLOCKED_UNEXPECTED_E5_QVW_SOURCE'
}
$qvs = Join-Path $Root 'TRANSFORMACAO\phase_vi_f4_p5_source_projection_preflight.qvs'
$rd = Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'
$lt = Join-Path $Root 'EXTRACAO\QVD\SRC_CNES_LT.qvd'
$required = @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    (Join-Path $Root 'docs\academic\requirements.md'),
    $src,$qvs,$rd,$lt
)
foreach ($file in $required) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "REQUIRED_INPUT_ABSENT=$file"
    }
}
foreach ($file in @($src,$rd,$lt)) {
    if ($file.Contains(']') -or $file.Contains([string][char]10) -or $file.Contains([string][char]13)) {
        throw "BINARY_OR_QVD_PATH_INVALID=$file"
    }
}
$body = [IO.File]::ReadAllText($qvs,[Text.Encoding]::UTF8)
$rdRel = '[..\EXTRACAO\QVD\SRC_SIH_RD.qvd]'
$ltRel = '[..\EXTRACAO\QVD\SRC_CNES_LT.qvd]'
if ($body.IndexOf($rdRel) -lt 0 -or $body.IndexOf($ltRel) -lt 0 -or
    -not $body.Contains('VERDICT=PASS_IN_MEMORY_SOURCE_MEASURES_AND_LINK_MEMBERSHIP_ONLY_NOT_P5') -or
    -not $body.Contains('DROP TABLE P6_FATO_RD_SIMULADA;') -or
    -not $body.Contains('DROP TABLE P6_FATO_LT_SIMULADA;') -or
    -not $body.Contains('F4_P5_MAP_LINK:') -or
    -not $body.Contains('F4_P5_RD_FACT_TEST:') -or
    -not $body.Contains('F4_P5_LT_FACT_TEST:')) {
    throw 'F4_P5_SOURCE_QVS_FINGERPRINT_FAILED'
}
if ($body -match '(?im)^\s*(STORE|EXECUTE|BINARY|JOIN|INNER JOIN|LEFT JOIN|RIGHT JOIN|OUTER JOIN)\b' -or
    [regex]::Matches($body,'(?im)^\s*DROP TABLE\s+P6_FATO_').Count -ne 2) {
    throw 'FORBIDDEN_QVD_WRITE_OR_UNEXPECTED_FACT_REPLACEMENT'
}
$body = $body.Replace($rdRel,('['+$rd+']')).Replace($ltRel,('['+$lt+']'))
if ($body.Contains($rdRel) -or $body.Contains($ltRel)) { throw 'QVD_PATH_REPLACEMENT_FAILED' }
$scriptText = 'BINARY [' + $src + '];' + [Environment]::NewLine + $body
function SameScript([string]$a,[string]$b) {
    return ($a.Replace([string][char]13,'').TrimEnd() -ceq $b.Replace([string][char]13,'').TrimEnd())
}
$sha = @{}
foreach ($file in @($src,$qvs,$rd,$lt)) {
    $sha[$file] = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ('SAD_F4_P5_PROJECTION_'+[Guid]::NewGuid().ToString('N'))
New-Item -Path $temp -ItemType Directory -ErrorAction Stop | Out-Null
$qvw = Join-Path $temp 'F4_P5_SOURCE_PROJECTION_DISPOSABLE.qvw'
$log = "$qvw.log"
$qv = $null
$doc = $null
$failure = $null
try {
    Write-Output 'MODE=F4_P5_SOURCE_MEASURES_ASSOCIATIVE_PROJECTION_DISPOSABLE'
    Write-Output ('SOURCE_QVW_SHA256_BEFORE='+$sha[$src])
    Write-Output ('F4_P5_QVS_SHA256='+$sha[$qvs])
    Write-Output ('TEMP_QVW='+$qvw)
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    $doc = $qv.CreateDoc()
    if ($null -eq $doc) { throw 'COM_CREATEDOC_NULL' }
    $props = $doc.GetProperties()
    $props.Script = $scriptText
    $props.GenerateLogfile = $true
    $null = $doc.SetProperties($props)
    if (-not (SameScript ([string]$doc.GetProperties().Script) $scriptText)) {
        throw 'SCRIPT_NOT_RETAINED_BY_QVW'
    }
    $null = $doc.SaveAs($qvw)
    if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) { throw 'TEMP_QVW_CREATION_FAILED' }
    $null = $doc.CloseDoc()
    $doc = $qv.OpenDoc($qvw,'','')
    if ($null -eq $doc) {throw 'TEMP_QVW_OPENDOC_FAILED'}
    $start = [DateTime]::UtcNow
    Write-Output 'DISPOSABLE_RELOAD_STARTED=True'
    $null = $doc.Reload()
    Write-Output 'DISPOSABLE_RELOAD_RETURNED=True'
    $null = $doc.Save()
    $null = $doc.CloseDoc()
    $doc = $null
    if (-not (Test-Path -LiteralPath $log -PathType Leaf) -or
        (Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $start.AddSeconds(-2)) {
        throw 'NATIVE_QLIK_LOG_MISSING_OR_STALE'
    }
    $lines = @(Get-Content -LiteralPath $log | Where-Object { $_ -notmatch '\bTRACE\b' })
    $expected = @(
        '[F4-P5] BASELINE_9_TABLES_PASS',
        '[F4-P5] RD_ROWS=566672 ELIGIBLE=555089 IDENT5=11583 UNMATCHED=0',
        '[F4-P5] LT_ROWS=35518 DISTINCT_GRAIN=35518 SUS_SNAPSHOT_SUM_AUDIT=270076 INVALID_QT=0 UNMATCHED=0',
        '[F4-P5] FINAL_TABLES=9 RD=566672 LT=35518 POP=669 SYN=0',
        '[F4-P5] VERDICT=PASS_IN_MEMORY_SOURCE_MEASURES_AND_LINK_MEMBERSHIP_ONLY_NOT_P5',
        '[F4-P5] P5_FILTER_EFFECTS=NOT_TESTED T24_T26=NOT_APPROVED T29_HISTORICAL=NOT_APPROVED'
    )
    foreach ($marker in $expected) {
        if (@($lines | Where-Object { $_.Contains($marker) }).Count -ne 1) {
            throw "NATIVE_QLIK_MARKER_ABSENT_OR_DUPLICATE=$marker"
        }
    }
    if (@($lines | Where-Object {
        $_ -match '\[F4-P5\] VERDICT=BLOCKED' -or
        $_ -match '(?i)syntax error|unknown statement|circular reference|loosely coupled|refer[eê]ncia[s]? circular(es)?'
    }).Count -gt 0) {throw 'QLIK_LOG_CONTAINS_ERROR_OR_CIRCULAR_ASSOCIATION'}
    foreach ($file in $sha.Keys) {
        if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -cne $sha[$file]) {
            throw "IMMUTABLE_SOURCE_CHANGED=$file"
        }
    }
    $lines | Where-Object { $_ -match '\[F4-P5\] (RD_ROWS|LT_ROWS|FINAL_TABLES|VERDICT=PASS|P5_FILTER_EFFECTS)' } |
        ForEach-Object {Write-Output $_}
    Write-Output 'ALL_SOURCE_SHA256_UNCHANGED=True'
    Write-Output 'SAVE_EXECUTED_ONLY_ON_DISPOSABLE=True'
    Write-Output 'QVD_WRITES=0'
    Write-Output 'FACT_QVDS_GENERATED=False'
    Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
    Write-Output 'F4_P5_FILTER_BEHAVIOR=NOT_TESTED'
    Write-Output 'MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED'
    Write-Output 'VERDICT=PASS_F4_P5_PROJECTION_SOURCE_MEASURES_ONLY_FILTERS_NOT_TESTED'
    Write-Output ('VISUAL_REVIEW_DISPOSABLE_QVW='+$qvw)
} catch {
    $failure = $_.Exception.Message
    Write-Output ('VERDICT=FAIL_CLOSED_'+$failure)
    Write-Output ('TEMP_DIAGNOSTIC_DIR='+$temp)
} finally {
    if ($null -ne $doc) { try {[void]$doc.CloseDoc()} catch {} }
    foreach ($file in $sha.Keys) {
        if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -cne $sha[$file]) {
            $failure="IMMUTABLE_SOURCE_CHANGED=$file"
        }
    }
    if ($null -eq $failure) {
        Write-Output 'SOURCE_IMMUTABILITY_FINAL=True'
    }
}
if ($null -ne $failure) {
    Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$failure)
    exit 1
}
Write-Output 'FINAL_VERDICT=PASS_PROJECTION_READINESS_ONLY'
