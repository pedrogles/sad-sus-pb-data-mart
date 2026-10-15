# SAD SUS PB — F4-P5 UI-guard feasibility: disposable QVW only.
# PREPARE copies a previously verified experimental QVW. VERIFY audits hashes only.
# No COM, Reload, Save, QVD writing, KPI evaluation or UI PASS in this script.
[CmdletBinding(DefaultParameterSetName='Prepare')]
param(
    [Parameter(Mandatory=$true,ParameterSetName='Prepare')][string]$SourceQvw,
    [Parameter(Mandatory=$true,ParameterSetName='Prepare')][string]$F4Dir,
    [Parameter(Mandatory=$true,ParameterSetName='Verify')][string]$TrialDir,
    [string]$Root = (Get-Location).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Full([string]$p) { return [IO.Path]::GetFullPath($p) }
function Sha([string]$p) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw "REQUIRED_INPUT_MISSING=$p" }
    return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()
}
function CheckTempSource([string]$p) {
    $tmp = (Full ([IO.Path]::GetTempPath())).TrimEnd('\') + '\'
    if (-not $p.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($p) -cne 'F4_P5_SOURCE_PROJECTION_DISPOSABLE.qvw' -or
        [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($p)) -cnotmatch '^SAD_F4_P5_PROJECTION_[0-9a-f]{32}$') {
        throw 'BLOCKED_SOURCE_NOT_EXISTING_TEMP_F4_P5_PROJECTION'
    }
}
function CheckTrialDirectory([string]$p) {
    $tmp = (Full ([IO.Path]::GetTempPath())).TrimEnd('\') + '\'
    if (-not $p.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($p.TrimEnd('\')) -cnotmatch '^SAD_F4_P5_UI_GUARD_[0-9a-f]{32}$' -or
        -not (Test-Path -LiteralPath $p -PathType Container)) {
        throw 'BLOCKED_TRIAL_MUST_BE_TEMP_UI_GUARD'
    }
}
function CheckAssets($assets) {
    foreach ($a in $assets) {
        $actual = Sha ([string]$a.path)
        if ($actual -cne [string]$a.sha256) {
            throw ('BLOCKED_ASSET_SHA256_CHANGED=' + [string]$a.path)
        }
    }
}
if ($PSCmdlet.ParameterSetName -eq 'Prepare') {
    $src = Full $SourceQvw
    CheckTempSource $src
    $rootDir = Full $Root
    $f4 = Full $F4Dir
    $csv = Join-Path $f4 'F4_p5_filtros_isolados.csv'
    $pairs = Join-Path $f4 'F4_p5_filtros_combinados.csv'
    $catalog = Join-Path $f4 'manifest_F4.json'
    $m = Get-Content -LiteralPath $catalog -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($f in @($csv,$pairs)) {
        $name = [IO.Path]::GetFileName($f)
        if ((Sha $f).ToLowerInvariant() -cne [string]$m.output_sha256.$name) {
            throw "BLOCKED_F4_CATALOG_HASH_DRIFT=$name"
        }
    }
    $singles = @(Import-Csv -LiteralPath $csv -Delimiter ';' -Encoding UTF8)
    $combos = @(Import-Csv -LiteralPath $pairs -Delimiter ';' -Encoding UTF8)
    if ($singles.Count -ne 48 -or $combos.Count -ne 8) {
        throw 'BLOCKED_F4_EXPECTED_48_SINGLES_8_PAIRS'
    }
    $observed = @{}
    foreach ($r in $singles) {
        $key = [string]$r.filtro + '|' + [string]$r.indicador
        if ($observed.ContainsKey($key)) { throw "BLOCKED_F4_DUPLICATE=$key" }
        $observed[$key] = [string]$r.politica_p5
    }
    $expected = @{
        'Procedimento realizado PROC_REA|RES' = 'R'
        'Procedimento realizado PROC_REA|LEI' = 'I'
        'Procedimento realizado PROC_REA|REL' = 'B'
        'Procedimento realizado PROC_REA|FLU' = 'R'
        'Municipio de servico|RES' = 'B'
    }
    foreach ($key in $expected.Keys) {
        if ($observed[$key] -cne $expected[$key]) {
            throw "BLOCKED_F4_POLICY_DRIFT=$key"
        }
    }
    $assets = @()
    foreach ($path in @(
        $src,$csv,$pairs,$catalog,
        (Join-Path $rootDir 'EXTRACAO\QVD\SRC_SIH_RD.qvd'),
        (Join-Path $rootDir 'EXTRACAO\QVD\SRC_CNES_LT.qvd'),
        (Join-Path $rootDir 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd')
    )) {
        $p = Full $path
        $assets += [pscustomobject]@{ path = $p; sha256 = (Sha $p) }
    }
    $trial = Join-Path ([IO.Path]::GetTempPath()) ('SAD_F4_P5_UI_GUARD_'+[Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $trial -ErrorAction Stop | Out-Null
    $copy = Join-Path $trial 'F4_P5_UI_GUARD_DISPOSABLE.qvw'
    Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
    if ((Sha $copy) -cne (Sha $src)) { throw 'BLOCKED_INITIAL_QVW_COPY_HASH' }
    $record = [pscustomobject]@{
        experiment = 'F4_P5_UI_GUARD_ONLY'
        source_qvw = $src
        source_sha256 = (Sha $src)
        test_qvw = $copy
        initial_test_sha256 = (Sha $copy)
        assets = $assets
    }
    $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $trial 'audit_manifest.json') -Encoding UTF8
    Write-Output 'CATALOG_SHA256_PASS=2_OF_2'
    Write-Output 'EXPECTED_POLICY_PROBES=R_I_B_R_AND_SERVICE_B'
    Write-Output 'ORIGINAL_AND_3_SOURCE_QVDS_SHA256_GUARDED=True'
    Write-Output ('SOURCE_QVW_SHA256=' + $record.source_sha256)
    Write-Output ('TRIAL_DIR=' + $trial)
    Write-Output ('TRIAL_QVW=' + $copy)
    Write-Output 'RELOAD_EXECUTED=False SAVE_EXECUTED=False QVD_WRITES=0'
    Write-Output 'FINAL_VERDICT=PREPARED_UI_COPY_NOT_EXECUTED'
} else {
    $trial = Full $TrialDir
    CheckTrialDirectory $trial
    $record = Get-Content -LiteralPath (Join-Path $trial 'audit_manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $copy = Join-Path $trial 'F4_P5_UI_GUARD_DISPOSABLE.qvw'
    if ([string]$record.experiment -cne 'F4_P5_UI_GUARD_ONLY' -or
        (Full ([string]$record.test_qvw)) -cne (Full $copy)) {
        throw 'BLOCKED_TRIAL_MANIFEST_MISMATCH'
    }
    CheckTempSource (Full ([string]$record.source_qvw))
    CheckAssets $record.assets
    if ((Sha $copy) -ceq [string]$record.initial_test_sha256) {
        throw 'BLOCKED_TRIAL_QVW_NOT_SAVED_WITH_UI_OBJECTS'
    }
    Write-Output 'ORIGINAL_QVW_SHA256_UNCHANGED=True'
    Write-Output 'ALL_3_INPUT_QVD_SHA256_UNCHANGED=True'
    Write-Output 'F4_CATALOG_SHA256_UNCHANGED=True'
    Write-Output 'TRIAL_QVW_CHANGED_FROM_INITIAL_COPY=True'
    Write-Output ('TRIAL_QVW=' + $copy)
    Write-Output ('TRIAL_QVW_FINAL_SHA256=' + (Sha $copy))
    Write-Output 'UI_VISIBILITY_AND_ISOLATION=NOT_AUTOMATICALLY_VERIFIED'
    Write-Output 'KPI_OR_PHYSICAL_P5_CONTRACT=NOT_APPROVED'
    Write-Output 'FINAL_VERDICT=PASS_ARTIFACT_INTEGRITY_ONLY_UI_SCREENSHOTS_PENDING'
}
