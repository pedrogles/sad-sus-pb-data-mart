# C2-H: single bounded protected TEMP QVW copy for manual two-listbox Read Only pilot.
# This script NEVER opens QlikView, calls COM, performs clicks, Reload or Save.
# -Prepare creates one disposable copy; -Verify checks original hashes after manual test.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$SourceQvw,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [switch]$Prepare,
    [switch]$Verify,
    [string]$RunDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {throw 'BLOCKED_WINDOWS_REQUIRED'}
if ([int]$Prepare + [int]$Verify -ne 1) {throw 'BLOCKED_CHOOSE_EXACTLY_ONE_MODE'}
$repo=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')
$source=[IO.Path]::GetFullPath($SourceQvw)
$evRoot=[IO.Path]::GetFullPath($EvidenceRoot).TrimEnd('\','/')
$rel='tools/Invoke-SadPhaseViiiC2hReadonlyListboxPilot.ps1'
$expectedBranch='test/phase-viii-c2h-listbox-readonly-pilot-20261021'
$expectedBase='3ca9c50a98c429ddb880ad6ea877fdf89a33a3fa'
$expectedSourceSha='31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087'
$self=[IO.Path]::GetFullPath((Join-Path $repo $rel))
if ([IO.Path]::GetFullPath($PSCommandPath) -ine $self) {throw 'BLOCKED_SCRIPT_NOT_AT_VERSIONED_PATH'}
if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {throw 'BLOCKED_ROOT_NOT_SAD_REPO'}
$branch=[string](& git -C $repo branch --show-current)
$head=[string](& git -C $repo rev-parse HEAD)
if ($LASTEXITCODE -ne 0 -or $branch -cne $expectedBranch -or $head -notmatch '^[a-f0-9]{40}$') {throw 'BLOCKED_GIT_BRANCH_OR_HEAD'}
& git -C $repo merge-base --is-ancestor $expectedBase HEAD
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_MAIN_BASE_NOT_ANCESTOR'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $rel)
if ($tracked.Count -ne 1 -or $dirty.Count -gt 0) {throw 'BLOCKED_RUNNER_NOT_VERSIONED_AND_CLEAN'}
$repoPrefix=$repo+[IO.Path]::DirectorySeparatorChar
if ($source.StartsWith($repoPrefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_SOURCE_INSIDE_REPO'}
if ($evRoot -ieq $repo -or $evRoot.StartsWith($repoPrefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_EVIDENCE_INSIDE_REPO'}
if ([IO.Path]::GetFileName($source) -cne 'SAD_C2F_ROUTE_INVENTORY_COPY.qvw') {throw 'BLOCKED_SOURCE_NOT_C2F_COPY'}
$tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
$tempPrefix=$tempRoot+[IO.Path]::DirectorySeparatorChar
if (-not $source.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_SOURCE_OUTSIDE_TEMP'}
if ([IO.Path]::GetFileName([IO.Path]::GetDirectoryName($source)) -notmatch '^SAD_VIII_C2F_[a-f0-9]{32}$') {throw 'BLOCKED_SOURCE_NOT_IN_C2F_RUN'}
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_QVW_MISSING'}
$sourceSha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if ($sourceSha -cne $expectedSourceSha) {throw 'BLOCKED_C2F_SOURCE_SHA_DRIFT'}
function ProtectedSnapshot {
    $ext=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -Filter '*.qvd' -File)
    $trans=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -Filter '*.qvd' -File)
    if ($ext.Count -ne 10 -or $trans.Count -ne 12) {throw 'BLOCKED_EXPECTED_10_EXT_12_TRANS_QVDS'}
    $files=@($ext)+@($trans)
    foreach ($p in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
        $canonical=Join-Path $repo $p
        if (-not (Test-Path -LiteralPath $canonical -PathType Leaf)) {throw ('BLOCKED_CANONICAL_QVW_MISSING_'+$p)}
        $files+=@(Get-Item -LiteralPath $canonical)
    }
    return @($files | ForEach-Object {
        '{0}|{1}|{2}' -f $_.FullName,$_.Length,(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    } | Sort-Object)
}
function IsQlikWindowOpen([string]$titlePart) {
    return @((Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match '^(qv|qlikview)$' -and $_.MainWindowTitle -like ('*'+$titlePart+'*')
    })).Count -gt 0
}
$scriptSha=(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('SCRIPT_SHA256='+$scriptSha)
Write-Output ('SOURCE_C2F_QVW_SHA256='+$sourceSha)
Write-Output 'INPUT_EVENTS=0 QLIK_COM_CALLS=0 AUTOMATED_QVW_MODIFICATIONS=0'
if ($Prepare) {
    if ($RunDir) {throw 'BLOCKED_RUN_DIR_ONLY_FOR_VERIFY'}
    if (IsQlikWindowOpen 'SAD_C2F_ROUTE_INVENTORY_COPY') {throw 'BLOCKED_CLOSE_C2F_SOURCE_WINDOW_FIRST'}
    $before=@(ProtectedSnapshot)
    $runId='SAD_VIII_C2H_'+[guid]::NewGuid().ToString('N')
    $tmpDir=Join-Path $tempRoot $runId
    $evidenceDir=Join-Path $evRoot $runId
    $copy=Join-Path $tmpDir 'SAD_C2H_READONLY_PILOT_COPY.qvw'
    $errorText=''
    try {
        $null=New-Item -ItemType Directory -Path $tmpDir -ErrorAction Stop
        $null=New-Item -ItemType Directory -Path $evidenceDir -ErrorAction Stop
        Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
        $copySha=(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
        if ($copySha -cne $sourceSha) {throw 'BLOCKED_COPY_SHA256_MISMATCH'}
        $manifest=[ordered]@{
            Gate='C2-H';Mode='TEMP_COPY_PREPARATION_ONLY'
            VersionedGitHead=$head;ScriptSha256=$scriptSha
            SourceQvw=$source;SourceSha256=$sourceSha
            TestCopy=$copy;TestCopyBeforeSha256=$copySha
            BeforeProtectedFiles=$before
            AuthorizedChange='LB01_LB04_READ_ONLY_ONLY_IN_TEST_COPY'
            UiTest='NOT_RUN';P5D2UI='NOT_TESTED';C2Full='NO_GO_NOT_APPROVED';ProductionApproved=$false
        }
        $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidenceDir 'c2h_manifest.json') -Encoding UTF8
    } catch {$errorText=$_.Exception.Message}
    finally {
        $after=@(ProtectedSnapshot)
        $safe=($sourceSha -ceq (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash) -and
            (($before -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine))
        Write-Output ('ORIGINAL_22_QVD_3_QVW_AND_SOURCE_UNCHANGED='+$safe)
        if (-not $safe) {throw 'HARD_STOP_PROTECTED_ARTIFACT_DRIFT'}
    }
    if ($errorText) {throw ('BLOCKED_PREPARATION_'+$errorText)}
    Write-Output ('RUNTIME_TEMP_COPY='+$copy)
    Write-Output ('EVIDENCE_DIR='+$evidenceDir)
    Write-Output ('BEFORE_TEST_COPY_SHA256='+$copySha)
    Write-Output 'VERDICT=PASS_LOCAL_PREPARATION_ONLY_C2H_UI_NOT_EXECUTED'
    Write-Output 'NEXT=MANUAL_LB01_LB04_READ_ONLY_CHANGE_ONLY_ON_NEW_TEMP_COPY'
    return
}
if (-not $RunDir) {throw 'BLOCKED_VERIFY_RUN_DIR_REQUIRED'}
$evidenceDir=[IO.Path]::GetFullPath($RunDir).TrimEnd('\','/')
if (-not $evidenceDir.StartsWith($evRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'BLOCKED_EVIDENCE_DIR_OUTSIDE_ROOT'
}
$manifestPath=Join-Path $evidenceDir 'c2h_manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {throw 'BLOCKED_MANIFEST_NOT_FOUND'}
$m=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($m.Gate -cne 'C2-H' -or $m.VersionedGitHead -cne $head -or $m.ScriptSha256 -cne $scriptSha -or
    $m.SourceQvw -ine $source -or $m.SourceSha256 -cne $expectedSourceSha) {throw 'BLOCKED_MANIFEST_PROVENANCE_MISMATCH'}
$copy=[IO.Path]::GetFullPath([string]$m.TestCopy)
if ([IO.Path]::GetFileName($copy) -cne 'SAD_C2H_READONLY_PILOT_COPY.qvw' -or
    -not $copy.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_TEST_COPY_NOT_IN_TEMP'}
if (-not (Test-Path -LiteralPath $copy -PathType Leaf)) {throw 'BLOCKED_TEST_COPY_MISSING'}
if (IsQlikWindowOpen 'SAD_C2H_READONLY_PILOT_COPY') {throw 'BLOCKED_CLOSE_TEST_QVW_BEFORE_VERIFY'}
$after=@(ProtectedSnapshot)
$before=@($m.BeforeProtectedFiles | ForEach-Object {[string]$_})
$unchanged=(($before -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine))
$sourceUnchanged=((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $m.SourceSha256)
$afterCopySha=(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
$copyChanged=($afterCopySha -cne $m.TestCopyBeforeSha256)
Write-Output ('PROTECTED_25_FILES_UNCHANGED='+$unchanged)
Write-Output ('SOURCE_QVW_UNCHANGED='+$sourceUnchanged)
Write-Output ('TEST_COPY_CHANGED_FROM_BASELINE='+$copyChanged)
Write-Output ('AFTER_TEST_COPY_SHA256='+$afterCopySha)
if (-not $unchanged -or -not $sourceUnchanged) {throw 'HARD_STOP_PROTECTED_OR_SOURCE_HASH_DRIFT'}
if (-not $copyChanged) {throw 'BLOCKED_TEST_COPY_NOT_SAVED_OR_UNCHANGED'}
$report=[ordered]@{
    Gate='C2-H';Verification='HASH_INTEGRITY_ONLY'
    ScriptSha256=$scriptSha;VersionedGitHead=$head
    SourceUnchanged=$sourceUnchanged;Protected25Unchanged=$unchanged
    TestCopyChanged=$copyChanged;TestCopyAfterSha256=$afterCopySha
    UiBehavior='NOT_VALIDATED_BY_THIS_SCRIPT';P5D2UI='NOT_TESTED';C2Full='NO_GO_NOT_APPROVED'
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidenceDir 'c2h_hash_verification.json') -Encoding UTF8
Write-Output ('EVIDENCE_DIR='+$evidenceDir)
Write-Output 'VERDICT=PASS_HASH_INTEGRITY_ONLY_UI_VISUAL_REVIEW_PENDING'
Write-Output 'C2_FULL=NO_GO_NOT_APPROVED P5_D2_UI=NOT_TESTED PRODUCTION_APPROVED=False'
