# SAD-C2-VISUAL-TEMPORAL-CONSUMPTION-01: identity/integrity preflight ONLY.
# Windows PowerShell 5.1. No QlikView process, COM, reload, QVW copy, or data modification.
# This script does not establish that the two experimental QVWs are mutually compatible.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$P11P12Qvw,
    [Parameter(Mandatory=$true)][string]$C2kQvw,
    [Parameter(Mandatory=$true)][string]$QlikExe,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gate = 'SAD-C2-VISUAL-TEMPORAL-CONSUMPTION-01'
$scriptRelativePath = 'tools/Invoke-SadC2VisualTemporalPreflight01.ps1'
$requiredBranch = 'test/sad-c2-visual-temporal-preflight-20261029'
$requiredBase = '7827300c8772a1cdebef2238a7dd8064c13592d2'
$expectedP11P12 = 'B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C'
$expectedC2K = '9896D55ED7F98CFA480A0626484A04C3A937E2F64EBF238011D3CDEF4E1E21FA'

function FullPath([string]$value) {
    if (-not [IO.Path]::IsPathRooted($value)) { throw 'BLOCKED_ABSOLUTE_PATH_REQUIRED' }
    return [IO.Path]::GetFullPath($value).TrimEnd('\', '/')
}
function IsUnder([string]$child, [string]$parent) {
    return ($child -ieq $parent -or
        $child.StartsWith($parent + '\', [StringComparison]::OrdinalIgnoreCase))
}
function FileSha([string]$path) {
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function ProtectedSnapshot([string]$repo) {
    $ext = Join-Path $repo 'EXTRACAO\QVD'
    $transf = Join-Path $repo 'TRANSFORMACAO\QVD'
    if (-not (Test-Path -LiteralPath $ext -PathType Container) -or
        -not (Test-Path -LiteralPath $transf -PathType Container)) {
        throw 'BLOCKED_PROTECTED_QVD_DIRECTORIES_MISSING'
    }
    $a = @(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)
    $b = @(Get-ChildItem -LiteralPath $transf -Filter '*.qvd' -File)
    if ($a.Count -ne 10 -or $b.Count -ne 12) {
        throw ('BLOCKED_EXPECTED_22_QVDS_FOUND_{0}_AND_{1}' -f $a.Count,$b.Count)
    }
    $files = @($a) + @($b)
    foreach ($rel in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
        $p = Join-Path $repo $rel
        if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
            throw ('BLOCKED_MISSING_PROTECTED_QVW_' + $rel)
        }
        $files += @(Get-Item -LiteralPath $p)
    }
    return @($files | Sort-Object FullName | ForEach-Object {
        [pscustomobject]@{
            Path = [string]$_.FullName
            Length = [long]$_.Length
            Sha256 = FileSha $_.FullName
        }
    })
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'BLOCKED_WINDOWS_REQUIRED'
}
$repo = FullPath $Root
$p11 = FullPath $P11P12Qvw
$c2k = FullPath $C2kQvw
$qlik = FullPath $QlikExe
$evidence = FullPath $EvidenceRoot

if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {
    throw 'BLOCKED_CANONICAL_REPO_ROOT'
}
$self = FullPath (Join-Path $repo $scriptRelativePath)
if ($self -ine (FullPath $PSCommandPath)) {
    throw 'BLOCKED_EXECUTOR_MUST_RUN_FROM_VERSIONED_REPO'
}
foreach ($p in @($p11,$c2k,$evidence)) {
    if (IsUnder $p $repo) {throw 'BLOCKED_SOURCE_OR_EVIDENCE_INSIDE_REPO'}
}
if ((IsUnder $p11 $evidence) -or (IsUnder $c2k $evidence)) {
    throw 'BLOCKED_SOURCE_INSIDE_EVIDENCE_ROOT'
}
if ($p11 -ieq $c2k) {throw 'BLOCKED_CANDIDATES_MUST_BE_DISTINCT'}
if (-not (Test-Path -LiteralPath $evidence -PathType Container)) {
    throw 'BLOCKED_EVIDENCE_ROOT_MUST_PREEXIST'
}
if (-not (Test-Path -LiteralPath $qlik -PathType Leaf) -or
    [IO.Path]::GetFileName($qlik) -ine 'Qv.exe') {
    throw 'BLOCKED_QV_EXE_NOT_VERIFIED'
}
$qlikVersion = [string](Get-Item -LiteralPath $qlik).VersionInfo.ProductVersion
if ($qlikVersion -notmatch '^12(\\.|$)') {
    throw 'BLOCKED_QLIKVIEW_12_VERSION_UNCONFIRMED'
}
foreach ($p in @($p11,$c2k)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf) -or
        [IO.Path]::GetExtension($p) -ine '.qvw') {
        throw ('BLOCKED_CANDIDATE_QVW_NOT_FOUND_' + $p)
    }
}
$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match '^(qv|qlikview)$'
})
if ($running.Count -gt 0) {
    throw 'BLOCKED_CLOSE_QLIKVIEW_BEFORE_PREFLIGHT'
}

$head = [string](& git -C $repo rev-parse --verify HEAD)
if ($LASTEXITCODE -ne 0 -or $head -notmatch '^[0-9a-f]{40}$') {
    throw 'BLOCKED_GIT_HEAD_UNAVAILABLE'
}
$branch = [string](& git -C $repo branch --show-current)
if ($LASTEXITCODE -ne 0 -or $branch -cne $requiredBranch) {
    throw 'BLOCKED_WRONG_GIT_BRANCH'
}
& git -C $repo merge-base --is-ancestor $requiredBase HEAD
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_GIT_BASE_MISMATCH'}
$tracked = @(& git -C $repo ls-files --error-unmatch -- $scriptRelativePath 2>$null)
if ($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1) {
    throw 'BLOCKED_EXECUTOR_NOT_TRACKED'
}
$dirty = @(& git -C $repo status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
    throw 'BLOCKED_DIRTY_WORKTREE'
}

$sourceHashP11 = FileSha $p11
$sourceHashC2k = FileSha $c2k
if ($sourceHashP11 -cne $expectedP11P12) {
    throw 'HARD_STOP_P11P12_SOURCE_SHA_DRIFT'
}
if ($sourceHashC2k -cne $expectedC2K) {
    throw 'HARD_STOP_C2K_SOURCE_SHA_DRIFT'
}
$before = @(ProtectedSnapshot $repo)
if ($before.Count -ne 25) {throw 'BLOCKED_PROTECTED_COUNT_NOT_25'}
$after = @(ProtectedSnapshot $repo)
$beforeJson = ConvertTo-Json -InputObject $before -Depth 4 -Compress
$afterJson = ConvertTo-Json -InputObject $after -Depth 4 -Compress
if ($beforeJson -cne $afterJson -or
    (FileSha $p11) -cne $sourceHashP11 -or
    (FileSha $c2k) -cne $sourceHashC2k) {
    throw 'HARD_STOP_PREFLIGHT_HASH_DRIFT'
}

$runnerSha = FileSha $self
$evidenceDir = Join-Path $evidence ('SAD_C2_TEMP_PREFLIGHT_' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $evidenceDir -ErrorAction Stop
$manifest = [ordered]@{
    Gate = $gate
    Verdict = 'PASS_IDENTITY_AND_HASH_INVENTORY_ONLY_NOT_UI'
    GitHead = $head
    GitBranch = $branch
    RunnerSha256 = $runnerSha
    QlikExe = $qlik
    QlikExeProductVersion = $qlikVersion
    P11P12Qvw = $p11
    P11P12Sha256 = $sourceHashP11
    C2kQvw = $c2k
    C2kSha256 = $sourceHashC2k
    Protected25 = $before
    Protected25UnchangedDuringPreflight = $true
    CombinedQvwCompatibility = 'NOT_TESTED'
    QlikProcessCalled = $false
    QlikUiTested = $false
    CopyCreated = $false
    CanonicalFilesWritten = $false
    C2Full = 'NO_GO_NOT_APPROVED'
    PhaseIX = 'NOT_AUTHORIZED'
    ProductionApproved = $false
}
$manifestPath = Join-Path $evidenceDir 'preflight_manifest.json'
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Output ('VERSIONED_GIT_HEAD=' + $head)
Write-Output ('RUNNER_SHA256=' + $runnerSha)
Write-Output ('P11P12_SOURCE_SHA256=' + $sourceHashP11)
Write-Output ('C2K_SOURCE_SHA256=' + $sourceHashC2k)
Write-Output 'PROTECTED_25_UNCHANGED_DURING_PREFLIGHT=True'
Write-Output 'QLIK_COM_CALLS=0 RELOAD_CALLS=0 QVW_COPIES=0'
Write-Output 'COMBINED_QVW_COMPATIBILITY=NOT_TESTED'
Write-Output ('EVIDENCE_DIR=' + $evidenceDir)
Write-Output 'VERDICT=PASS_IDENTITY_AND_HASH_INVENTORY_ONLY_NOT_UI'
