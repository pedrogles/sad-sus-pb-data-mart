# SAD-P1-P11-P12-PHYSICAL-POC-01. Copy/verify ONLY; no COM, reload or UI mutation.
# Adapted from the committed C2-K protected-copy pattern. Windows PowerShell 5.1.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$SourceQvw,
    [Parameter(Mandatory=$true)][string]$RuntimeRoot,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [Parameter(Mandatory=$true)][string]$ExpectedCommit,
    [switch]$Prepare,
    [switch]$Verify,
    [string]$RunDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rel = 'tools/Invoke-SadP11P12VisualCopy01.ps1'
$requiredBranch = 'test/sad-p11-p12-physical-poc-01-20261028'
$requiredBase = '9070806f26a1568948b0ce2b87c597beb7ec2d9e'
$pinName = 'SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw'
# Historical C2-K -Verify evidence, NOT independently rehashed in this cloud session.
$pinHash = '9896D55ED7F98CFA480A0626484A04C3A937E2F64EBF238011D3CDEF4E1E21FA'
$copyName = 'SAD_P11_P12_VISUAL_POC_COPY.qvw'

function Full([string]$p) { return [IO.Path]::GetFullPath($p).TrimEnd([char[]]@('\','/')) }
function Inside([string]$child, [string]$parent) {
    return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
        $child.StartsWith(($parent+[IO.Path]::DirectorySeparatorChar),[StringComparison]::OrdinalIgnoreCase)
}
function Hash([string]$p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }
function ProtectedSnapshot {
    $ext = Join-Path $repo 'EXTRACAO\QVD'
    $trans = Join-Path $repo 'TRANSFORMACAO\QVD'
    if (-not (Test-Path -LiteralPath $ext -PathType Container) -or
        -not (Test-Path -LiteralPath $trans -PathType Container)) { throw 'BLOCKED_QVD_FOLDERS' }
    $a = @(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)
    $b = @(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File)
    if ($a.Count -ne 10 -or $b.Count -ne 12) { throw 'BLOCKED_EXPECTED_10_PLUS_12_QVD' }
    $files = @($a)+@($b)
    foreach ($p in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
        $f = Join-Path $repo $p
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { throw ('BLOCKED_MISSING_'+$p) }
        $files += @(Get-Item -LiteralPath $f)
    }
    return @($files | ForEach-Object {
        '{0}|{1}|{2}' -f $_.FullName,$_.Length,(Hash $_.FullName)
    } | Sort-Object)
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'BLOCKED_WINDOWS_REQUIRED' }
if ($Prepare.IsPresent -eq $Verify.IsPresent) { throw 'BLOCKED_SELECT_EXACTLY_ONE_MODE' }
if ($ExpectedCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'BLOCKED_EXPECTED_COMMIT_SHA40' }
foreach ($value in @($Root,$SourceQvw,$RuntimeRoot,$EvidenceRoot)) {
    if (-not [IO.Path]::IsPathRooted($value)) { throw 'BLOCKED_ABSOLUTE_PATHS_REQUIRED' }
}
$repo = Full $Root
$source = Full $SourceQvw
$runtime = Full $RuntimeRoot
$evidence = Full $EvidenceRoot
$self = Full (Join-Path $repo $rel)
if ($self -ine (Full $PSCommandPath)) { throw 'BLOCKED_RUN_COMMITTED_SCRIPT_ONLY' }
if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {
    throw 'BLOCKED_REPOSITORY_ROOT'
}
foreach ($p in @($source,$runtime,$evidence)) {
    if (Inside $p $repo) { throw 'BLOCKED_SOURCE_OR_OUTPUT_INSIDE_REPO' }
}
if ((Inside $runtime $evidence) -or (Inside $evidence $runtime) -or
    (Inside $source $runtime) -or (Inside $source $evidence)) {
    throw 'BLOCKED_OUTPUT_SOURCE_OVERLAP'
}
if ([IO.Path]::GetFileName($source) -cne $pinName) { throw 'BLOCKED_UNEXPECTED_SOURCE_NAME' }
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'RECOVERABLE_BLOCK_PINNED_SOURCE_MISSING' }
$sourceHash = Hash $source
if ($sourceHash -cne $pinHash) { throw 'HARD_STOP_PINNED_SOURCE_SHA_MISMATCH' }

# Reusing a previously saved QVW is safe only with its exact, verified binary.
$active = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match '^(qv|qlikview)$' -and
    $_.MainWindowTitle -like ('*'+$pinName+'*')
})
if ($active.Count -gt 0) { throw 'BLOCKED_CLOSE_SOURCE_QVW_FIRST' }

$branch = [string](& git -C $repo branch --show-current)
$head = [string](& git -C $repo rev-parse HEAD)
if ($LASTEXITCODE -ne 0 -or $branch -cne $requiredBranch -or $head -cne $ExpectedCommit) {
    throw 'BLOCKED_BRANCH_OR_PINNED_HEAD'
}
& git -C $repo merge-base --is-ancestor $requiredBase HEAD
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_BASELINE_ANCESTRY' }
$tracked = @(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty = @(& git -C $repo status --porcelain --untracked-files=no)
if ($tracked.Count -ne 1 -or $dirty.Count -gt 0) { throw 'BLOCKED_VERSIONING_OR_DIRTY_TRACKED_FILES' }
$runnerHash = Hash $self
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$runnerHash)
Write-Output ('SOURCE_SHA256='+$sourceHash)
Write-Output 'COM=0 RELOAD=0 STORE=0 AUTOMATED_GUI=0'

if ($Prepare) {
    if ($RunDir) { throw 'BLOCKED_RUNDIR_ONLY_FOR_VERIFY' }
    if (-not (Test-Path -LiteralPath $runtime -PathType Container) -or
        -not (Test-Path -LiteralPath $evidence -PathType Container)) {
        throw 'BLOCKED_OUTPUT_ROOTS_MUST_PREEXIST'
    }
    $before = @(ProtectedSnapshot)
    $runId = 'SAD_P11P12_'+[guid]::NewGuid().ToString('N')
    $runRuntime = Join-Path $runtime $runId
    $runEvidence = Join-Path $evidence $runId
    $copy = Join-Path $runRuntime $copyName
    $failure = $null
    try {
        $null = New-Item -ItemType Directory -Path $runRuntime -ErrorAction Stop
        $null = New-Item -ItemType Directory -Path $runEvidence -ErrorAction Stop
        Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
        $beforeCopy = Hash $copy
        if ($beforeCopy -cne $sourceHash) { throw 'HARD_STOP_COPY_HASH_DIFFERENT' }
        [ordered]@{
            Gate='SAD-P1-P11-P12-PHYSICAL-POC-01'; GitHead=$head
            RunnerSha256=$runnerHash; Source=$source; SourceSha256=$sourceHash
            RuntimeRoot=$runtime; EvidenceRoot=$evidence
            Copy=$copy; CopyBeforeSha256=$beforeCopy; ProtectedBefore=$before
            QlikView='NOT_EXECUTED'; UI='NOT_EXECUTED'; Oracle='NOT_REEVALUATED'
            PhaseIX='NOT_AUTHORIZED'; ProductionApproved=$false
        } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $runEvidence 'p11p12_manifest.json') -Encoding UTF8
    } catch { $failure = $_.Exception.Message }
    finally {
        $after = @(ProtectedSnapshot)
        $intact = (($before -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine)) -and
            ((Hash $source) -ceq $sourceHash)
        Write-Output ('PROTECTED_AND_SOURCE_UNCHANGED='+$intact)
        if (-not $intact) { throw 'HARD_STOP_PROTECTED_INTEGRITY' }
    }
    if ($failure) { throw ('BLOCKED_PREPARE_'+$failure) }
    Write-Output ('RUNTIME_COPY='+$copy)
    Write-Output ('EVIDENCE_DIR='+$runEvidence)
    Write-Output 'VERDICT=PASS_COPY_PREPARATION_ONLY_UI_NOT_TESTED'
    return
}

if (-not $RunDir -or -not [IO.Path]::IsPathRooted($RunDir)) {
    throw 'BLOCKED_ABSOLUTE_RUN_DIR_REQUIRED'
}
$runEvidence = Full $RunDir
if (-not $runEvidence.StartsWith(($evidence+[IO.Path]::DirectorySeparatorChar),
    [StringComparison]::OrdinalIgnoreCase)) { throw 'BLOCKED_RUN_DIR_OUTSIDE_EVIDENCE' }
$manifest = Join-Path $runEvidence 'p11p12_manifest.json'
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw 'BLOCKED_MANIFEST_NOT_FOUND' }
$m = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
if ($m.Gate -cne 'SAD-P1-P11-P12-PHYSICAL-POC-01' -or
    $m.GitHead -cne $head -or $m.RunnerSha256 -cne $runnerHash -or
    $m.Source -ine $source -or $m.SourceSha256 -cne $sourceHash -or
    $m.RuntimeRoot -ine $runtime -or $m.EvidenceRoot -ine $evidence) {
    throw 'BLOCKED_MANIFEST_PROVENANCE'
}
$copy = Full ([string]$m.Copy)
if ([IO.Path]::GetFileName($copy) -cne $copyName -or
    -not $copy.StartsWith(($runtime+[IO.Path]::DirectorySeparatorChar),
        [StringComparison]::OrdinalIgnoreCase) -or
    -not (Test-Path -LiteralPath $copy -PathType Leaf)) {
    throw 'BLOCKED_TEST_COPY_NOT_FOUND'
}
$activeCopy = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -match '^(qv|qlikview)$' -and
    $_.MainWindowTitle -like ('*'+$copyName+'*')
})
if ($activeCopy.Count -gt 0) { throw 'BLOCKED_CLOSE_TEST_COPY_BEFORE_VERIFY' }
$after = @(ProtectedSnapshot)
$prev = @($m.ProtectedBefore | ForEach-Object { [string]$_ })
$protectedOk = (($prev -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine))
$sourceOk = ((Hash $source) -ceq $sourceHash)
$copyHash = Hash $copy
$copyChanged = ($copyHash -cne $m.CopyBeforeSha256)
Write-Output ('PROTECTED_25_UNCHANGED='+$protectedOk)
Write-Output ('SOURCE_UNCHANGED='+$sourceOk)
Write-Output ('COPY_CHANGED='+$copyChanged)
Write-Output ('COPY_SHA256='+$copyHash)
if (-not $protectedOk -or -not $sourceOk) { throw 'HARD_STOP_SOURCE_OR_PROTECTED_DRIFT' }
if (-not $copyChanged) { throw 'BLOCKED_NO_SAVED_CHANGES_TO_TEST_COPY' }
[ordered]@{
    Gate='SAD-P1-P11-P12-PHYSICAL-POC-01'; GitHead=$head
    RunnerSha256=$runnerHash; Protected25Unchanged=$protectedOk
    SourceUnchanged=$sourceOk; CopyChanged=$copyChanged
    CopySha256=$copyHash; Ui='NOT_PROVEN_BY_HASH'
    Verdict='PASS_HASH_INTEGRITY_ONLY'
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runEvidence 'p11p12_hash_verify.json') -Encoding UTF8
Write-Output ('EVIDENCE_DIR='+$runEvidence)
Write-Output 'VERDICT=PASS_HASH_INTEGRITY_ONLY_UI_NOT_PROVEN'
