# C2 Guided UI: one protected native Windows copy, no COM, no Reload.
# Based on C2-H's established inventory/hash/manifest pattern.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$Root,
 [Parameter(Mandatory=$true)][string]$SourceQvw,
 [Parameter(Mandatory=$true)][string]$RuntimeRoot,
 [Parameter(Mandatory=$true)][string]$EvidenceRoot,
 [switch]$Prepare,[switch]$Verify,[string]$RunDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$rel='tools/Invoke-SadPhaseViiiC2GuidedUiPilot.ps1'
$expectedBranch='test/phase-viii-c2-guided-hybrid-ui-physical-prep-20261022'
$base='a16539e10499d0346bf5574f3142f568a5073d02'
$pinName='SAD_C2H_READONLY_PILOT_COPY.qvw'
$pinHash='1724C785442F4FBA8C59E4D908C711AADC546C3AEB958208EA3FDC0F35CF180B'
$copyName='SAD_C2_GUIDED_HYBRID_POC_COPY.qvw'
function Full([string]$p) { return [IO.Path]::GetFullPath($p).TrimEnd('\','/') }
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {throw 'BLOCKED_WINDOWS_REQUIRED'}
if ($Prepare.IsPresent -eq $Verify.IsPresent) {throw 'BLOCKED_SELECT_ONE_MODE'}
# All paths must be explicit Windows roots; never silently resolve under Codex sandbox CWD.
foreach ($given in @($Root,$SourceQvw,$RuntimeRoot,$EvidenceRoot)) {
 if (-not [IO.Path]::IsPathRooted($given)) {throw 'BLOCKED_EXPLICIT_ROOTED_PATH_REQUIRED'}
}
$repo=Full $Root
$source=Full $SourceQvw
$runtime=Full $RuntimeRoot
$evidence=Full $EvidenceRoot
$self=Full (Join-Path $repo $rel)
if ($self -ine (Full $PSCommandPath)) {throw 'BLOCKED_RUNNER_PATH'}
if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {throw 'BLOCKED_REPO_ROOT'}
foreach ($p in @($source,$runtime,$evidence)) {
 if ($p -ieq $repo -or $p.StartsWith($repo+'\',[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_PATH_INSIDE_REPO'}
}
if ($runtime -ieq $evidence -or $runtime.StartsWith($evidence+'\',[StringComparison]::OrdinalIgnoreCase) -or $evidence.StartsWith($runtime+'\',[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_OUTPUT_OVERLAP'}
if ($source.StartsWith($runtime+'\',[StringComparison]::OrdinalIgnoreCase) -or $source.StartsWith($evidence+'\',[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_SOURCE_IS_OUTPUT'}
if ([IO.Path]::GetFileName($source) -cne $pinName) {throw 'BLOCKED_UNEXPECTED_SOURCE_NAME'}
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_PINNED_SOURCE_NOT_FOUND'}
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if ($sourceHash -cne $pinHash) {throw 'HARD_STOP_PINNED_SOURCE_SHA_MISMATCH'}
# Do not copy an open/unsaved source QVW; a hash alone cannot prove GUI state is saved.
$sourceWindows=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
 $_.ProcessName -match '^(qv|qlikview)[string](& git -C $repo branch --show-current)
$head=[string](& git -C $repo rev-parse HEAD)
if ($LASTEXITCODE -ne 0 -or $branch -cne $expectedBranch -or $head -notmatch '^[a-f0-9]{40}$') {throw 'BLOCKED_BRANCH_OR_COMMIT'}
& git -C $repo merge-base --is-ancestor $base HEAD
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_BASE_COMMIT'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $rel)
if ($tracked.Count -ne 1 -or $dirty.Count -gt 0) {throw 'BLOCKED_RUNNER_NOT_CLEAN_VERSIONED'}
$runnerSha=(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash
function ProtectedSnapshot {
 $a=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -Filter '*.qvd' -File)
 $b=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -Filter '*.qvd' -File)
 if ($a.Count -ne 10 -or $b.Count -ne 12) {throw 'BLOCKED_EXPECTED_22_QVDS'}
 $files=@($a)+@($b)
 foreach ($name in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
  $p=Join-Path $repo $name
  if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {throw ('BLOCKED_MISSING_'+$name)}
  $files+=@(Get-Item -LiteralPath $p)
 }
 return @($files | ForEach-Object {
  '{0}|{1}|{2}' -f $_.FullName,$_.Length,(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
 } | Sort-Object)
}
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$runnerSha)
Write-Output ('SOURCE_SHA256='+$sourceHash)
Write-Output 'QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_UI_EDITS=0'
if ($Prepare) {
 if ($RunDir) {throw 'BLOCKED_RUNDIR_ONLY_VERIFY'}
 if (-not (Test-Path -LiteralPath $runtime -PathType Container) -or -not (Test-Path -LiteralPath $evidence -PathType Container)) {throw 'BLOCKED_OUTPUT_ROOTS_MUST_PREEXIST'}
 $before=@(ProtectedSnapshot)
 $id='SAD_VIII_C2_GUIDED_'+[guid]::NewGuid().ToString('N')
 $runtimeDir=Join-Path $runtime $id
 $evidenceDir=Join-Path $evidence $id
 $copy=Join-Path $runtimeDir $copyName
 $failed=$null
 try {
  $null=New-Item -ItemType Directory -Path $runtimeDir -ErrorAction Stop
  $null=New-Item -ItemType Directory -Path $evidenceDir -ErrorAction Stop
  Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
  $copyHash=(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
  if ($copyHash -cne $sourceHash) {throw 'HARD_STOP_COPY_HASH'}
  [ordered]@{
   Gate='VIII-C2-GUIDED-HYBRID-UI-POC-PHYSICAL';GitHead=$head;RunnerSha256=$runnerSha
   Source=$source;SourceSha256=$sourceHash;RuntimeRoot=$runtime;EvidenceRoot=$evidence
   Copy=$copy;CopyBeforeSha256=$copyHash;ProtectedBefore=$before
   Ui='NOT_TESTED';C2Full='NO_GO_NOT_APPROVED';P5D2Ui='NOT_TESTED';ProductionApproved=$false
  } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidenceDir 'guided_manifest.json') -Encoding UTF8
 } catch {$failed=$_.Exception.Message}
 finally {
  $after=@(ProtectedSnapshot)
  $ok=(($before -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine)) -and
    ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $sourceHash)
  Write-Output ('PROTECTED_AND_SOURCE_UNCHANGED='+$ok)
  if (-not $ok) {throw 'HARD_STOP_PROTECTED_DRIFT'}
 }
 if ($failed) {throw ('BLOCKED_PREPARE_'+$failed)}
 Write-Output ('RUNTIME_COPY='+$copy)
 Write-Output ('EVIDENCE_DIR='+$evidenceDir)
 Write-Output 'VERDICT=PASS_COPY_PREPARATION_ONLY_NOT_PHYSICAL_UI'
 return
}
if (-not $RunDir) {throw 'BLOCKED_RUN_DIR_REQUIRED'}
$evidenceDir=Full $RunDir
if (-not $evidenceDir.StartsWith($evidence+'\',[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_RUN_DIR_PATH'}
$manifest=Join-Path $evidenceDir 'guided_manifest.json'
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {throw 'BLOCKED_MANIFEST_MISSING'}
$m=Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
if ($m.Gate -cne 'VIII-C2-GUIDED-HYBRID-UI-POC-PHYSICAL' -or
 $m.GitHead -cne $head -or $m.RunnerSha256 -cne $runnerSha -or
 $m.Source -ine $source -or $m.SourceSha256 -cne $sourceHash -or
 $m.RuntimeRoot -ine $runtime -or $m.EvidenceRoot -ine $evidence) {throw 'BLOCKED_MANIFEST_PROVENANCE'}
$copy=Full ([string]$m.Copy)
if ([IO.Path]::GetFileName($copy) -cne $copyName -or -not $copy.StartsWith($runtime+'\',[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $copy -PathType Leaf)) {throw 'BLOCKED_INVALID_TEST_COPY'}
$windows=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
 $_.ProcessName -match '^(qv|qlikview)$' -and $_.MainWindowTitle -like ('*'+$copyName+'*')
})
if ($windows.Count -gt 0) {throw 'BLOCKED_CLOSE_COPY_IN_QLIKVIEW'}
$after=@(ProtectedSnapshot)
$prev=@($m.ProtectedBefore | ForEach-Object {[string]$_})
$protectedOk=(($prev -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine))
$sourceOk=((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $sourceHash)
$copySha=(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
$copyChanged=($copySha -cne $m.CopyBeforeSha256)
Write-Output ('PROTECTED_25_UNCHANGED='+$protectedOk)
Write-Output ('SOURCE_UNCHANGED='+$sourceOk)
Write-Output ('COPY_CHANGED='+$copyChanged)
Write-Output ('COPY_SHA256='+$copySha)
if (-not $protectedOk -or -not $sourceOk) {throw 'HARD_STOP_INPUT_INTEGRITY'}
if (-not $copyChanged) {throw 'BLOCKED_NO_SAVED_UI_COPY_CHANGES'}
[ordered]@{
 Gate='VIII-C2-GUIDED-HYBRID-UI-POC-PHYSICAL';GitHead=$head;RunnerSha256=$runnerSha
 Protected25Unchanged=$protectedOk;SourceUnchanged=$sourceOk;CopyChanged=$copyChanged
 CopySha256=$copySha;UiTest='NOT_APPROVED_BY_HASH';Verdict='PASS_HASH_INTEGRITY_ONLY'
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidenceDir 'guided_hash_verify.json') -Encoding UTF8
Write-Output ('EVIDENCE_DIR='+$evidenceDir)
Write-Output 'VERDICT=PASS_HASH_INTEGRITY_ONLY_UI_NOT_PROVEN'
 -and $_.MainWindowTitle -like ('*'+$pinName+'*')
})
if ($sourceWindows.Count -gt 0) {throw 'BLOCKED_CLOSE_PINNED_SOURCE_QVW_FIRST'}
$branch=[string](& git -C $repo branch --show-current)
$head=[string](& git -C $repo rev-parse HEAD)
if ($LASTEXITCODE -ne 0 -or $branch -cne $expectedBranch -or $head -notmatch '^[a-f0-9]{40}$') {throw 'BLOCKED_BRANCH_OR_COMMIT'}
& git -C $repo merge-base --is-ancestor $base HEAD
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_BASE_COMMIT'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $rel)
if ($tracked.Count -ne 1 -or $dirty.Count -gt 0) {throw 'BLOCKED_RUNNER_NOT_CLEAN_VERSIONED'}
$runnerSha=(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash
function ProtectedSnapshot {
 $a=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -Filter '*.qvd' -File)
 $b=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -Filter '*.qvd' -File)
 if ($a.Count -ne 10 -or $b.Count -ne 12) {throw 'BLOCKED_EXPECTED_22_QVDS'}
 $files=@($a)+@($b)
 foreach ($name in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
  $p=Join-Path $repo $name
  if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {throw ('BLOCKED_MISSING_'+$name)}
  $files+=@(Get-Item -LiteralPath $p)
 }
 return @($files | ForEach-Object {
  '{0}|{1}|{2}' -f $_.FullName,$_.Length,(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
 } | Sort-Object)
}
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$runnerSha)
Write-Output ('SOURCE_SHA256='+$sourceHash)
Write-Output 'QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_UI_EDITS=0'
if ($Prepare) {
 if ($RunDir) {throw 'BLOCKED_RUNDIR_ONLY_VERIFY'}
 if (-not (Test-Path -LiteralPath $runtime -PathType Container) -or -not (Test-Path -LiteralPath $evidence -PathType Container)) {throw 'BLOCKED_OUTPUT_ROOTS_MUST_PREEXIST'}
 $before=@(ProtectedSnapshot)
 $id='SAD_VIII_C2_GUIDED_'+[guid]::NewGuid().ToString('N')
 $runtimeDir=Join-Path $runtime $id
 $evidenceDir=Join-Path $evidence $id
 $copy=Join-Path $runtimeDir $copyName
 $failed=$null
 try {
  $null=New-Item -ItemType Directory -Path $runtimeDir -ErrorAction Stop
  $null=New-Item -ItemType Directory -Path $evidenceDir -ErrorAction Stop
  Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
  $copyHash=(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
  if ($copyHash -cne $sourceHash) {throw 'HARD_STOP_COPY_HASH'}
  [ordered]@{
   Gate='VIII-C2-GUIDED-HYBRID-UI-POC-PHYSICAL';GitHead=$head;RunnerSha256=$runnerSha
   Source=$source;SourceSha256=$sourceHash;RuntimeRoot=$runtime;EvidenceRoot=$evidence
   Copy=$copy;CopyBeforeSha256=$copyHash;ProtectedBefore=$before
   Ui='NOT_TESTED';C2Full='NO_GO_NOT_APPROVED';P5D2Ui='NOT_TESTED';ProductionApproved=$false
  } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidenceDir 'guided_manifest.json') -Encoding UTF8
 } catch {$failed=$_.Exception.Message}
 finally {
  $after=@(ProtectedSnapshot)
  $ok=(($before -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine)) -and
    ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $sourceHash)
  Write-Output ('PROTECTED_AND_SOURCE_UNCHANGED='+$ok)
  if (-not $ok) {throw 'HARD_STOP_PROTECTED_DRIFT'}
 }
 if ($failed) {throw ('BLOCKED_PREPARE_'+$failed)}
 Write-Output ('RUNTIME_COPY='+$copy)
 Write-Output ('EVIDENCE_DIR='+$evidenceDir)
 Write-Output 'VERDICT=PASS_COPY_PREPARATION_ONLY_NOT_PHYSICAL_UI'
 return
}
if (-not $RunDir) {throw 'BLOCKED_RUN_DIR_REQUIRED'}
$evidenceDir=Full $RunDir
if (-not $evidenceDir.StartsWith($evidence+'\',[StringComparison]::OrdinalIgnoreCase)) {throw 'BLOCKED_RUN_DIR_PATH'}
$manifest=Join-Path $evidenceDir 'guided_manifest.json'
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {throw 'BLOCKED_MANIFEST_MISSING'}
$m=Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
if ($m.Gate -cne 'VIII-C2-GUIDED-HYBRID-UI-POC-PHYSICAL' -or
 $m.GitHead -cne $head -or $m.RunnerSha256 -cne $runnerSha -or
 $m.Source -ine $source -or $m.SourceSha256 -cne $sourceHash -or
 $m.RuntimeRoot -ine $runtime -or $m.EvidenceRoot -ine $evidence) {throw 'BLOCKED_MANIFEST_PROVENANCE'}
$copy=Full ([string]$m.Copy)
if ([IO.Path]::GetFileName($copy) -cne $copyName -or -not $copy.StartsWith($runtime+'\',[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $copy -PathType Leaf)) {throw 'BLOCKED_INVALID_TEST_COPY'}
$windows=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
 $_.ProcessName -match '^(qv|qlikview)$' -and $_.MainWindowTitle -like ('*'+$copyName+'*')
})
if ($windows.Count -gt 0) {throw 'BLOCKED_CLOSE_COPY_IN_QLIKVIEW'}
$after=@(ProtectedSnapshot)
$prev=@($m.ProtectedBefore | ForEach-Object {[string]$_})
$protectedOk=(($prev -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine))
$sourceOk=((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $sourceHash)
$copySha=(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
$copyChanged=($copySha -cne $m.CopyBeforeSha256)
Write-Output ('PROTECTED_25_UNCHANGED='+$protectedOk)
Write-Output ('SOURCE_UNCHANGED='+$sourceOk)
Write-Output ('COPY_CHANGED='+$copyChanged)
Write-Output ('COPY_SHA256='+$copySha)
if (-not $protectedOk -or -not $sourceOk) {throw 'HARD_STOP_INPUT_INTEGRITY'}
if (-not $copyChanged) {throw 'BLOCKED_NO_SAVED_UI_COPY_CHANGES'}
[ordered]@{
 Gate='VIII-C2-GUIDED-HYBRID-UI-POC-PHYSICAL';GitHead=$head;RunnerSha256=$runnerSha
 Protected25Unchanged=$protectedOk;SourceUnchanged=$sourceOk;CopyChanged=$copyChanged
 CopySha256=$copySha;UiTest='NOT_APPROVED_BY_HASH';Verdict='PASS_HASH_INTEGRITY_ONLY'
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidenceDir 'guided_hash_verify.json') -Encoding UTF8
Write-Output ('EVIDENCE_DIR='+$evidenceDir)
Write-Output 'VERDICT=PASS_HASH_INTEGRITY_ONLY_UI_NOT_PROVEN'
