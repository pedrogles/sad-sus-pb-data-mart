# SAD-P12-PHYSICAL-CORRECTIVE-01: protected disposable QVW copy, then hash-only closeout.
# Windows PowerShell 5.1. No QlikView COM, reload, STORE, or GUI automation.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$Root,
 [Parameter(Mandatory=$true)][string]$ExpectedCommit,
 [Parameter(Mandatory=$true)][string]$ParentManifestPath,
 [Parameter(Mandatory=$true)][string]$RuntimeRoot,
 [Parameter(Mandatory=$true)][string]$EvidenceRoot,
 [switch]$Prepare,
 [switch]$Verify,
 [string]$RunDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$scriptRel='tools/Invoke-SadP12CorrectiveCopy01.ps1'
$requiredBranch='test/sad-p12-physical-corrective-01-20261028'
$oldGate='SAD-P1-P11-P12-PHYSICAL-POC-01'
$oldCommit='d901df16ae78dc0c7ff2a2d05c439353e7219793'
$oldRunnerSha='D0B4091F4ABB44CA0B474FF34A4E0F1525E40D5EADABFE8629139639D2AA81ED'
$oldCopyName='SAD_P11_P12_VISUAL_POC_COPY.qvw'
$oldCopySha='603464EB5AD5696DA001D5431194EF37D509448695DBBBB9EA1B7252F96EC791'
$newCopyName='SAD_P12_CORRECTIVE_COPY.qvw'
function Full([string]$v) { return [IO.Path]::GetFullPath($v).TrimEnd([char[]]@('\','/')) }
function Hash([string]$v) { return (Get-FileHash -LiteralPath $v -Algorithm SHA256 -ErrorAction Stop).Hash }
function Inside([string]$child,[string]$parent) {
 return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
        $child.StartsWith(($parent+'\'),[StringComparison]::OrdinalIgnoreCase)
}
function Parse-Line([string]$line) {
 $m=[regex]::Match($line,'^(?<p>[^|]+)\|(?<n>[0-9]+)\|(?<h>[A-Fa-f0-9]{64})$')
 if (-not $m.Success) { throw 'BLOCKED_BAD_PARENT_MANIFEST_ENTRY' }
 return [pscustomobject]@{Path=$m.Groups['p'].Value;Length=[long]$m.Groups['n'].Value;Sha=$m.Groups['h'].Value.ToUpperInvariant()}
}
function Inventory {
 $e=Join-Path $repo 'EXTRACAO\QVD'
 $t=Join-Path $repo 'TRANSFORMACAO\QVD'
 $a=@(Get-ChildItem -LiteralPath $e -Filter '*.qvd' -File)
 $b=@(Get-ChildItem -LiteralPath $t -Filter '*.qvd' -File)
 if ($a.Count -ne 10 -or $b.Count -ne 12) { throw 'HARD_STOP_QVD_COUNT_NOT_10_PLUS_12' }
 $f=@($a)+@($b)
 foreach($p in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
  $target=Join-Path $repo $p
  if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw ('HARD_STOP_MISSING_'+$p) }
  $f+=@(Get-Item -LiteralPath $target)
 }
 return @($f | ForEach-Object {
  [pscustomobject]@{Path=$_.FullName;Length=[long]$_.Length;Sha=(Hash $_.FullName)}
 })
}
function Assert-Protected([object[]]$baseline) {
 $current=@(Inventory)
 $seen=@{}
 foreach($x in $current) {
  if ($seen.ContainsKey($x.Path)) { throw ('HARD_STOP_DUPLICATE_PATH_'+$x.Path) }
  $seen[$x.Path]=$x
 }
 $issues=@(
  foreach($old in $baseline) {
   if (-not $seen.ContainsKey($old.Path)) { 'MISSING_PATH='+$old.Path; continue }
   $now=$seen[$old.Path]
   if ($old.Path -cne $now.Path) { 'PATH_TEXT_CHANGED='+$old.Path }
   if ([long]$old.Length -ne [long]$now.Length) { 'LENGTH_CHANGED='+$old.Path }
   if ([string]$old.Sha -cne [string]$now.Sha) { 'SHA256_CHANGED='+$old.Path }
  }
  foreach($now in $current) {
   if (-not (@($baseline | Where-Object { $_.Path -ieq $now.Path }).Count -gt 0)) {
    'EXTRA_PATH='+$now.Path
   }
  }
 )
 foreach($issue in $issues) { Write-Output ('PROTECTED_DIFF='+$issue) }
 if ($baseline.Count -ne 25 -or $current.Count -ne 25 -or $issues.Count -gt 0) {
  throw 'HARD_STOP_PROTECTED_BASELINE_DRIFT'
 }
 Write-Output 'PROTECTED_25_UNCHANGED=True'
}
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or $PSVersionTable.PSVersion.Major -ne 5) {
 throw 'BLOCKED_WINDOWS_PS51_REQUIRED'
}
if ($Prepare.IsPresent -eq $Verify.IsPresent) { throw 'BLOCKED_SELECT_PREPARE_OR_VERIFY' }
if ($ExpectedCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'BLOCKED_EXPECTED_SHA40' }
foreach($p in @($Root,$ParentManifestPath,$RuntimeRoot,$EvidenceRoot)) {
 if (-not [IO.Path]::IsPathRooted($p)) { throw 'BLOCKED_ABSOLUTE_PATHS' }
}
$repo=Full $Root
$parentPath=Full $ParentManifestPath
$runtime=Full $RuntimeRoot
$evidence=Full $EvidenceRoot
$self=Full (Join-Path $repo $scriptRel)
if ($self -ine (Full $PSCommandPath)) { throw 'BLOCKED_RUN_COMMITTED_SCRIPT' }
if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) { throw 'BLOCKED_ROOT' }
if ((Inside $runtime $repo) -or (Inside $evidence $repo) -or (Inside $parentPath $repo)) { throw 'BLOCKED_OUTPUT_INSIDE_REPO' }
$head=([string](& git -C $repo rev-parse HEAD)).Trim()
$branch=([string](& git -C $repo branch --show-current)).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit -or $branch -cne $requiredBranch) {
 throw 'BLOCKED_BRANCH_OR_HEAD'
}
$dirty=@(& git -C $repo status --porcelain)
if ($dirty.Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
$runnerSha=Hash $self
Write-Output ('GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$runnerSha)
Write-Output 'COM=0 RELOAD=0 STORE=0 AUTOMATED_GUI=0'
if (-not (Test-Path -LiteralPath $parentPath -PathType Leaf)) { throw 'BLOCKED_PARENT_MANIFEST_MISSING' }
$parent=Get-Content -LiteralPath $parentPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($parent.Gate -cne $oldGate -or $parent.GitHead -cne $oldCommit -or $parent.RunnerSha256 -cne $oldRunnerSha) {
 throw 'BLOCKED_PARENT_MANIFEST_PROVENANCE'
}
$source=Full ([string]$parent.Copy)
if ([IO.Path]::GetFileName($source) -cne $oldCopyName -or (Inside $source $repo)) {
 throw 'BLOCKED_EXPECTED_OLD_TEST_COPY'
}
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'BLOCKED_OLD_TEST_COPY_MISSING' }
$sourceSha=Hash $source
Write-Output ('SOURCE_SHA256='+$sourceSha)
if ($sourceSha -cne $oldCopySha) { throw 'HARD_STOP_OLD_TEST_COPY_SHA_MISMATCH' }
$base=@($parent.ProtectedBefore | ForEach-Object { Parse-Line ([string]$_) })
if ($base.Count -ne 25) { throw 'BLOCKED_PARENT_PROTECTED_COUNT' }
Assert-Protected $base
if ($Prepare) {
 if ($RunDir) { throw 'BLOCKED_RUNDIR_ONLY_VERIFY' }
 $open=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
  $_.ProcessName -match '^(qv|qlikview)$' -and $_.MainWindowTitle -like ('*'+$oldCopyName+'*')
 })
 if ($open.Count -gt 0) { throw 'BLOCKED_CLOSE_PARENT_QVW' }
 $id='SAD_P12_CORRECTIVE_'+[guid]::NewGuid().ToString('N')
 $runRuntime=Join-Path $runtime $id
 $runEvidence=Join-Path $evidence $id
 if (-not (Test-Path -LiteralPath $runtime -PathType Container) -or -not (Test-Path -LiteralPath $evidence -PathType Container)) {
  throw 'BLOCKED_CREATE_OUTPUT_ROOTS_SEPARATELY_FIRST'
 }
 $null=New-Item -ItemType Directory -Path $runRuntime -ErrorAction Stop
 $null=New-Item -ItemType Directory -Path $runEvidence -ErrorAction Stop
 $copy=Join-Path $runRuntime $newCopyName
 Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
 $copySha=Hash $copy
 if ($copySha -cne $sourceSha) { throw 'HARD_STOP_COPY_BYTES_CHANGED' }
 $manifest=[ordered]@{
  Gate='SAD-P12-PHYSICAL-CORRECTIVE-01';GitHead=$head;RunnerSha256=$runnerSha
  ParentManifest=$parentPath;Source=$source;SourceSha256=$sourceSha
  RuntimeRoot=$runtime;EvidenceRoot=$evidence;Copy=$copy;CopyBeforeSha256=$copySha
  ProtectedBefore=@($parent.ProtectedBefore)
  UI='NOT_TESTED';Oracle='NOT_TESTED';PhaseIX='NOT_AUTHORIZED';ProductionApproved=$false
 }
 $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runEvidence 'p12_corrective_manifest.json') -Encoding UTF8
 Assert-Protected $base
 if ((Hash $source) -cne $sourceSha) { throw 'HARD_STOP_SOURCE_CHANGED_DURING_COPY' }
 Write-Output ('RUNTIME_COPY='+$copy)
 Write-Output ('EVIDENCE_DIR='+$runEvidence)
 Write-Output 'VERDICT=PASS_PREPARE_ONLY_UI_NOT_TESTED'
 return
}
if (-not $RunDir -or -not [IO.Path]::IsPathRooted($RunDir)) { throw 'BLOCKED_VERIFY_RUNDIR_ABSOLUTE' }
$runEvidence=Full $RunDir
if (-not $runEvidence.StartsWith(($evidence+'\'),[StringComparison]::OrdinalIgnoreCase)) { throw 'BLOCKED_RUNDIR_OUTSIDE_EVIDENCE' }
$manifestPath=Join-Path $runEvidence 'p12_corrective_manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'BLOCKED_NEW_MANIFEST_NOT_FOUND' }
$m=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($m.Gate -cne 'SAD-P12-PHYSICAL-CORRECTIVE-01' -or $m.GitHead -cne $head -or
    $m.RunnerSha256 -cne $runnerSha -or $m.ParentManifest -ine $parentPath -or
    $m.Source -ine $source -or $m.SourceSha256 -cne $sourceSha) { throw 'BLOCKED_NEW_MANIFEST_PROVENANCE' }
$copy=Full ([string]$m.Copy)
if ([IO.Path]::GetFileName($copy) -cne $newCopyName -or
    -not $copy.StartsWith(($runtime+'\'),[StringComparison]::OrdinalIgnoreCase)) {
 throw 'BLOCKED_NEW_COPY_PATH'
}
$open=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
 $_.ProcessName -match '^(qv|qlikview)$' -and $_.MainWindowTitle -like ('*'+$newCopyName+'*')
})
if ($open.Count -gt 0) { throw 'BLOCKED_CLOSE_NEW_TEST_COPY' }
if (-not (Test-Path -LiteralPath $copy -PathType Leaf)) { throw 'BLOCKED_NEW_TEST_COPY_MISSING' }
$afterSha=Hash $copy
$changed=($afterSha -cne [string]$m.CopyBeforeSha256)
Assert-Protected $base
if ((Hash $source) -cne $sourceSha) { throw 'HARD_STOP_SOURCE_DRIFT' }
Write-Output 'SOURCE_UNCHANGED=True'
Write-Output ('COPY_CHANGED='+$changed)
Write-Output ('COPY_SHA256='+$afterSha)
if (-not $changed) { throw 'BLOCKED_NO_SAVED_COPY_CHANGE' }
[ordered]@{
 Gate=$m.Gate;GitHead=$head;RunnerSha256=$runnerSha;Protected25Unchanged=$true
 SourceUnchanged=$true;CopyChanged=$changed;CopySha256=$afterSha
 Verdict='PASS_HASH_INTEGRITY_ONLY';UI='NOT_PROVEN_BY_HASH'
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runEvidence 'p12_corrective_verify.json') -Encoding UTF8
Write-Output ('EVIDENCE_DIR='+$runEvidence)
Write-Output 'VERDICT=PASS_HASH_INTEGRITY_ONLY_UI_NOT_PROVEN'
