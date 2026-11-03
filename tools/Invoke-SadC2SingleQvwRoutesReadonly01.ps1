# Gate SAD-C2-SINGLE-QVW-ACCESSIBLE-ROUTES-READONLY-01.
# Versioned shell helper: copy only / SHA-256 checks. NO COM, GUI clicks, reload or save.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [ValidateSet('Prepare','Verify')][string]$Mode = 'Prepare',
    [string]$SourceQvw,
    [string]$ManifestPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedBranch = 'test/sad-c2-single-qvw-routes-readonly-20261103'
$expectedBase = '59dc80a4db24f8ada257e9354e464f3393bfcab6'
$expectedQvwHash = 'A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517'
$expectedQvwName = 'SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw'
$relativeRunner = 'tools/Invoke-SadC2SingleQvwRoutesReadonly01.ps1'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'BLOCKED_WINDOWS_REQUIRED' }
$repo = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\','/')
$self = Join-Path $repo $relativeRunner
if ([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)) {
    throw 'BLOCKED_RUNNER_NOT_AT_VERSIONED_PATH'
}
$branch = ([string](& git -C $repo branch --show-current)).Trim()
$head = ([string](& git -C $repo rev-parse HEAD)).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne $expectedBranch -or $head -notmatch '^[0-9a-f]{40}$') {
    throw 'BLOCKED_WRONG_BRANCH_OR_HEAD'
}
& git -C $repo merge-base --is-ancestor $expectedBase $head
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_WRONG_GIT_ANCESTRY' }
$dirty = @(& git -C $repo status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
$runnerTracked = @(& git -C $repo ls-files --error-unmatch -- $relativeRunner 2>$null)
if ($runnerTracked.Count -ne 1) { throw 'BLOCKED_RUNNER_NOT_VERSIONED' }
$runnerSha = (Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash
$qlikExe = 'C:\Program Files\QlikView\Qv.exe'
if (-not (Test-Path -LiteralPath $qlikExe -PathType Leaf)) { throw 'BLOCKED_QLIKVIEW_NOT_FOUND' }
$qlikVersion = (Get-Item -LiteralPath $qlikExe).VersionInfo.FileVersion
if ($qlikVersion -cne '12.0.20000.0') { throw 'BLOCKED_UNEXPECTED_QLIKVIEW_VERSION' }
if (@(Get-Process -Name qv,qlikview -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'BLOCKED_CLOSE_QLIKVIEW_FIRST'
}

function AssertOutsideRepo([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if ($full -ieq $repo -or $full.StartsWith(($repo+'\'),[StringComparison]::OrdinalIgnoreCase)) {
        throw 'BLOCKED_PATH_INSIDE_REPOSITORY'
    }
    return $full
}
function ProtectedSnapshot {
    $extract = @(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -Filter '*.qvd' -File)
    $transform = @(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -Filter '*.qvd' -File)
    if ($extract.Count -ne 10 -or $transform.Count -ne 12) { throw 'BLOCKED_EXPECTED_22_QVDS' }
    $files = @($extract) + @($transform)
    foreach ($relative in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
        $path = Join-Path $repo $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ('BLOCKED_CANONICAL_MISSING_'+$relative) }
        $files += @(Get-Item -LiteralPath $path)
    }
    $rows = foreach ($file in ($files | Sort-Object FullName)) {
        [PSCustomObject]@{
            Path = $file.FullName.Substring($repo.Length+1).Replace('\','/')
            Size = $file.Length
            SHA256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    return $rows
}
function ProtectedFingerprint {
    $snapshot = @(ProtectedSnapshot)
    if ($snapshot.Count -ne 25) { throw 'BLOCKED_EXPECTED_25_PROTECTED' }
    return (ConvertTo-Json -InputObject $snapshot -Depth 4 -Compress)
}
function AssertIdentity([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'BLOCKED_SOURCE_QVW_NOT_FOUND' }
    if ([IO.Path]::GetFileName($Path) -cne $expectedQvwName) { throw 'BLOCKED_WRONG_SOURCE_FILENAME' }
    $full = AssertOutsideRepo $Path
    $sha = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash
    if ($sha -cne $expectedQvwHash) { throw 'HARD_STOP_SOURCE_HASH_MISMATCH' }
    return $full
}

Write-Output ('GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$runnerSha)
Write-Output ('QLIKVIEW_VERSION='+$qlikVersion)

if ($Mode -ceq 'Prepare') {
    if ([string]::IsNullOrWhiteSpace($SourceQvw)) { throw 'BLOCKED_SOURCE_ARGUMENT_REQUIRED' }
    $source = AssertIdentity $SourceQvw
    $before = ProtectedFingerprint
    $id = 'SAD_C2_ROUTES_'+[guid]::NewGuid().ToString('N')
    $runtimeBase = AssertOutsideRepo (Join-Path $env:USERPROFILE 'Documents\SAD_C2_ROUTE_INVENTORY_RUNTIME')
    $evidenceBase = AssertOutsideRepo (Join-Path $env:USERPROFILE 'Documents\SAD_C2_ROUTE_INVENTORY_EVIDENCE')
    $runtimeDir = Join-Path $runtimeBase $id
    $evidenceDir = Join-Path $evidenceBase $id
    $copy = Join-Path $runtimeDir 'SAD_C2_ROUTE_INVENTORY_COPY.qvw'
    $manifestFile = Join-Path $evidenceDir 'c2_route_inventory_manifest.json'
    $after = $null
    try {
        [void](New-Item -ItemType Directory -Path $runtimeDir -Force -ErrorAction Stop)
        [void](New-Item -ItemType Directory -Path $evidenceDir -Force -ErrorAction Stop)
        [IO.File]::Copy($source,$copy,$false)
        $copyHash = (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
        if ($copyHash -cne $expectedQvwHash) { throw 'HARD_STOP_COPY_HASH_MISMATCH' }
        $manifest = [ordered]@{
            Gate = 'SAD-C2-SINGLE-QVW-ACCESSIBLE-ROUTES-READONLY-01'
            Mode = 'READONLY_COPY_PREPARE'
            GitHead = $head
            RunnerSha256 = $runnerSha
            QlikVersion = $qlikVersion
            SourceQvw = $source
            SourceSha256 = $expectedQvwHash
            TempCopy = $copy
            TempCopySha256 = $copyHash
            ProtectedFingerprint = $before
            GuiInventory = 'NOT_RUN'
            C2Full = 'NO_GO_NOT_APPROVED'
            ProductionApproved = $false
        }
        $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestFile -Encoding UTF8
    }
    finally {
        $after = ProtectedFingerprint
        $sourceAfter = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        if ($before -cne $after -or $sourceAfter -cne $expectedQvwHash) {
            throw 'HARD_STOP_SOURCE_OR_PROTECTED_HASH_DRIFT'
        }
    }
    Write-Output ('RUNTIME_COPY='+$copy)
    Write-Output ('MANIFEST='+$manifestFile)
    Write-Output 'PROTECTED_25_UNCHANGED=True'
    Write-Output 'SOURCE_UNCHANGED=True'
    Write-Output 'VERDICT=PASS_COPY_AND_INTEGRITY_ONLY_NOT_ROUTE_INVENTORY'
    return
}

if ([string]::IsNullOrWhiteSpace($ManifestPath)) { throw 'BLOCKED_MANIFEST_ARGUMENT_REQUIRED' }
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) { throw 'BLOCKED_MANIFEST_NOT_FOUND' }
$manifestPathFull = AssertOutsideRepo $ManifestPath
$m = Get-Content -LiteralPath $manifestPathFull -Raw | ConvertFrom-Json
if ($m.Gate -cne 'SAD-C2-SINGLE-QVW-ACCESSIBLE-ROUTES-READONLY-01' -or
    $m.GitHead -cne $head -or $m.RunnerSha256 -cne $runnerSha -or
    $m.QlikVersion -cne $qlikVersion -or $m.SourceSha256 -cne $expectedQvwHash) {
    throw 'BLOCKED_MANIFEST_RUNNER_OR_HEAD_MISMATCH'
}
$source = AssertIdentity ([string]$m.SourceQvw)
$copy = AssertOutsideRepo ([string]$m.TempCopy)
if (-not (Test-Path -LiteralPath $copy -PathType Leaf)) { throw 'BLOCKED_COPY_NOT_FOUND' }
$copyHash = (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
if ($copyHash -cne $m.TempCopySha256) { throw 'BLOCKED_INSPECTION_COPY_CHANGED' }
$protectedAfter = ProtectedFingerprint
if ($protectedAfter -cne $m.ProtectedFingerprint) { throw 'HARD_STOP_PROTECTED_25_CHANGED' }
Write-Output ('SOURCE_QVW='+$source)
Write-Output ('RUNTIME_COPY='+$copy)
Write-Output ('COPY_SHA256='+$copyHash)
Write-Output 'SOURCE_AND_PROTECTED_25_UNCHANGED=True'
Write-Output 'VERDICT=PASS_HASH_INTEGRITY_ONLY_NOT_UI_ROUTES'
