# SAD-C2-P12-EVOLUTION-2019-01: protected TEMP copy for one guided visual test.
# Windows PowerShell 5.1. No QlikView launch, COM, reload, object editing or QVW Save.
# The operator performs the approved single GUI scenario on the TEMP copy.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$Root,
 [Parameter(Mandatory=$true)][string]$SourceQvw,
 [Parameter(Mandatory=$true)][string]$QlikExe,
 [Parameter(Mandatory=$true)][string]$RuntimeRoot,
 [Parameter(Mandatory=$true)][string]$EvidenceRoot,
 [switch]$Prepare,
 [switch]$Verify,
 [string]$RunDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$gate='SAD-C2-P12-EVOLUTION-2019-01'
$rel='tools/Invoke-SadC2P12Evolution2019Copy01.ps1'
$requiredBranch='test/sad-c2-p12-evolucao-2019-20261030'
$base='843e8f4fea74a8d8ab60ebbab2033c4d181dd961'
$sourceName='SAD_P11P12_VISUAL_POLISH_COPY.qvw'
$sourcePin='B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C'
$copyName='SAD_C2_P12_EVOLUTION_2019_TEMP.qvw'
function Resolve-SadPath([string]$p) {
 if (-not [IO.Path]::IsPathRooted($p)) {throw 'BLOCKED_ABSOLUTE_PATH_REQUIRED'}
 return [IO.Path]::GetFullPath($p).TrimEnd('\','/')
}
function Test-SadUnder([string]$child,[string]$parent) {
 return ($child -ieq $parent -or $child.StartsWith($parent+'\',[StringComparison]::OrdinalIgnoreCase))
}
function Get-SadSha([string]$p) {
 return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Get-SadProtected([string]$repo) {
 $e=Join-Path $repo 'EXTRACAO\QVD'
 $t=Join-Path $repo 'TRANSFORMACAO\QVD'
 if (-not (Test-Path -LiteralPath $e -PathType Container) -or
     -not (Test-Path -LiteralPath $t -PathType Container)) {throw 'BLOCKED_QVD_DIR_MISSING'}
 $a=@(Get-ChildItem -LiteralPath $e -Filter '*.qvd' -File)
 $b=@(Get-ChildItem -LiteralPath $t -Filter '*.qvd' -File)
 if ($a.Count -ne 10 -or $b.Count -ne 12) {throw 'BLOCKED_EXPECTED_10_12_QVDS'}
 $files=@($a)+@($b)
 foreach ($r in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
  $p=Join-Path $repo $r
  if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {throw 'BLOCKED_MISSING_CANONICAL_QVW'}
  $files+=@(Get-Item -LiteralPath $p)
 }
 if ($files.Count -ne 25) {throw 'BLOCKED_25_PROTECTED_COUNT'}
 return @($files | Sort-Object FullName | ForEach-Object {
  '{0}|{1}|{2}' -f $_.FullName,([long]$_.Length),(Get-SadSha $_.FullName)
 })
}
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {throw 'BLOCKED_WINDOWS_REQUIRED'}
if ($Prepare.IsPresent -eq $Verify.IsPresent) {throw 'BLOCKED_SELECT_PREPARE_OR_VERIFY'}
$repo=Resolve-SadPath $Root
$source=Resolve-SadPath $SourceQvw
$qlik=Resolve-SadPath $QlikExe
$runtime=Resolve-SadPath $RuntimeRoot
$evidence=Resolve-SadPath $EvidenceRoot
$self=Resolve-SadPath (Join-Path $repo $rel)
if ($self -ine (Resolve-SadPath $PSCommandPath)) {throw 'BLOCKED_RUN_VERSIONED_SCRIPT_ONLY'}
if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {throw 'BLOCKED_REPO_ROOT'}
foreach ($p in @($source,$runtime,$evidence)) {
 if (Test-SadUnder $p $repo) {throw 'BLOCKED_INPUT_OUTPUT_INSIDE_GIT'}
}
if (Test-SadUnder $runtime $evidence) {throw 'BLOCKED_RUNTIME_INSIDE_EVIDENCE'}
if (Test-SadUnder $evidence $runtime) {throw 'BLOCKED_EVIDENCE_INSIDE_RUNTIME'}
if (Test-SadUnder $source $runtime) {throw 'BLOCKED_SOURCE_INSIDE_RUNTIME'}
if (Test-SadUnder $source $evidence) {throw 'BLOCKED_SOURCE_INSIDE_EVIDENCE'}
foreach ($p in @($runtime,$evidence)) {
 if (-not (Test-Path -LiteralPath $p -PathType Container)) {throw 'BLOCKED_OUTPUT_ROOT_MUST_PREEXIST'}
}
if ([IO.Path]::GetFileName($source) -cne $sourceName -or
    -not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_QVW_MISSING'}
if ([IO.Path]::GetFileName($qlik) -ine 'Qv.exe' -or
    -not (Test-Path -LiteralPath $qlik -PathType Leaf)) {throw 'BLOCKED_QV_EXE_MISSING'}
$qvVersion=[string](Get-Item -LiteralPath $qlik).VersionInfo.ProductVersion
if ($qvVersion -notmatch '^12(\.|$)') {throw 'BLOCKED_QV12_VERSION_UNCONFIRMED'}
$running=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(qv|qlikview)$'})
if ($running.Count -gt 0) {throw 'BLOCKED_CLOSE_QLIKVIEW_FIRST'}
$head=([string](& git -C $repo rev-parse --verify HEAD)).Trim()
if ($LASTEXITCODE -ne 0 -or $head -notmatch '^[0-9a-f]{40}$') {throw 'BLOCKED_HEAD'}
$branch=([string](& git -C $repo branch --show-current)).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne $requiredBranch) {throw 'BLOCKED_BRANCH'}
& git -C $repo merge-base --is-ancestor $base HEAD
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_BASE'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
if ($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1) {throw 'BLOCKED_RUNNER_NOT_TRACKED'}
$dirty=@(& git -C $repo status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {throw 'BLOCKED_DIRTY_WORKTREE'}
$sourceSha=Get-SadSha $source
if ($sourceSha -cne $sourcePin) {throw 'HARD_STOP_SOURCE_SHA_DRIFT'}
$runnerSha=Get-SadSha $self
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$runnerSha)
Write-Output ('SOURCE_SHA256='+$sourceSha)
Write-Output ('QV_PRODUCT_VERSION='+$qvVersion)
Write-Output 'QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0'

if ($Prepare) {
 if ($RunDir) {throw 'BLOCKED_RUNDIR_ONLY_FOR_VERIFY'}
 $before=@(Get-SadProtected $repo)
 $id='SAD_C2_P12_2019_'+[guid]::NewGuid().ToString('N')
 $work=Join-Path $runtime $id
 $ev=Join-Path $evidence $id
 $copy=Join-Path $work $copyName
 $null=New-Item -ItemType Directory -Path $work -ErrorAction Stop
 $null=New-Item -ItemType Directory -Path $ev -ErrorAction Stop
 try {
  Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
  if ((Get-SadSha $copy) -cne $sourcePin) {throw 'HARD_STOP_COPY_HASH_DRIFT'}
  [ordered]@{
   Gate=$gate; GitHead=$head; GitBranch=$branch; RunnerSha256=$runnerSha
   SourceQvw=$source; SourceSha256=$sourcePin
   QlikExe=$qlik; QlikProductVersion=$qvVersion
   RuntimeRoot=$runtime; EvidenceRoot=$evidence; CopyQvw=$copy; CopyBeforeSha256=$sourcePin
   ProtectedBefore=$before; Gui2019='NOT_TESTED'; QvwSaved=$false; ProductionApproved=$false
  } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $ev 'p12_2019_prepare.json') -Encoding UTF8
 } finally {
  $after=@(Get-SadProtected $repo)
  if (($before -join [Environment]::NewLine) -cne ($after -join [Environment]::NewLine) -or
      (Get-SadSha $source) -cne $sourcePin) {throw 'HARD_STOP_PREPARE_INTEGRITY'}
 }
 Write-Output ('RUNTIME_COPY='+$copy)
 Write-Output ('EVIDENCE_DIR='+$ev)
 Write-Output 'VERDICT=PASS_PROTECTED_COPY_PREPARED_ONLY_NO_GUI'
 return
}

if (-not $RunDir) {throw 'BLOCKED_RUNDIR_REQUIRED_FOR_VERIFY'}
$ev=Resolve-SadPath $RunDir
if (-not (Test-SadUnder $ev $evidence) -or $ev -ieq $evidence) {throw 'BLOCKED_INVALID_EVIDENCE_DIR'}
$manifest=Join-Path $ev 'p12_2019_prepare.json'
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {throw 'BLOCKED_PREPARE_MANIFEST_MISSING'}
$m=Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
if ($m.Gate -cne $gate -or $m.GitHead -cne $head -or $m.GitBranch -cne $branch -or
    $m.RunnerSha256 -cne $runnerSha -or $m.SourceQvw -ine $source -or
    $m.SourceSha256 -cne $sourcePin -or $m.QlikExe -ine $qlik -or
    $m.RuntimeRoot -ine $runtime -or $m.EvidenceRoot -ine $evidence) {
 throw 'BLOCKED_PREPARE_PROVENANCE_MISMATCH'
}
$copy=Resolve-SadPath ([string]$m.CopyQvw)
if (-not (Test-SadUnder $copy $runtime) -or $copy -ieq $runtime -or
    [IO.Path]::GetFileName($copy) -cne $copyName -or
    -not (Test-Path -LiteralPath $copy -PathType Leaf)) {throw 'BLOCKED_COPY_INVALID'}
if ((Split-Path -Parent $copy) -ine (Join-Path $runtime (Split-Path -Leaf $ev))) {
 throw 'BLOCKED_RUNTIME_EVIDENCE_RUN_ID_MISMATCH'
}
$old=@($m.ProtectedBefore | ForEach-Object {[string]$_})
$now=@(Get-SadProtected $repo)
$protectedOk=(($old -join [Environment]::NewLine) -ceq ($now -join [Environment]::NewLine))
$sourceAfter=Get-SadSha $source
$copyAfter=Get-SadSha $copy
$sourceOk=($sourceAfter -ceq $sourcePin)
$copyOk=($copyAfter -ceq $sourcePin)
Write-Output ('PROTECTED_25_UNCHANGED='+$protectedOk)
Write-Output ('SOURCE_UNCHANGED='+$sourceOk)
Write-Output ('COPY_NOT_SAVED='+$copyOk)
Write-Output ('COPY_SHA256='+$copyAfter)
if (-not $protectedOk -or -not $sourceOk) {throw 'HARD_STOP_INPUT_INTEGRITY'}
if (-not $copyOk) {throw 'BLOCKED_COPY_CHANGED_DURING_GUI'}
$verify=Join-Path $ev 'p12_2019_verify.json'
if (Test-Path -LiteralPath $verify -PathType Leaf) {throw 'BLOCKED_VERIFY_ALREADY_RECORDED'}
[ordered]@{
 Gate=$gate; GitHead=$head; RunnerSha256=$runnerSha
 Protected25Unchanged=$protectedOk; SourceUnchanged=$sourceOk; CopyNotSaved=$copyOk
 CopySha256=$copyAfter; GuidedSelection='NOT_ASSESSED_BY_RUNNER'
 Verdict='PASS_PROTECTED_COPY_INTEGRITY_ONLY_NOT_GUI'
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $verify -Encoding UTF8
Write-Output ('EVIDENCE_DIR='+$ev)
Write-Output 'VERDICT=PASS_PROTECTED_COPY_INTEGRITY_ONLY_NOT_GUI'
