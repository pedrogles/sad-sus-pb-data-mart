# SAD-C2-VISUAL-COMPATIBILITY-01. PowerShell 5.1 native.
# Only protected copies and hash manifest; no COM, reload, GUI edits, or QVW launch.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$Root,
 [Parameter(Mandatory=$true)][string]$P11P12Qvw,
 [Parameter(Mandatory=$true)][string]$C2kQvw,
 [Parameter(Mandatory=$true)][string]$RuntimeRoot,
 [Parameter(Mandatory=$true)][string]$EvidenceRoot,
 [switch]$Prepare,[switch]$Verify,[string]$RunDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$gate='SAD-C2-VISUAL-COMPATIBILITY-01'
$rel='tools/Invoke-SadC2VisualCompatibilityCopy01.ps1'
$requiredBranch='test/sad-c2-visual-compatibility-20261029'
$requiredBase='7827300c8772a1cdebef2238a7dd8064c13592d2'
$p11Name='SAD_P11P12_VISUAL_POLISH_COPY.qvw'
$c2kName='SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw'
$p11Sha='B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C'
$c2kSha='9896D55ED7F98CFA480A0626484A04C3A937E2F64EBF238011D3CDEF4E1E21FA'
$copyP11Name='SAD_C2_COMPAT_P11P12_COPY.qvw'
$copyC2kName='SAD_C2_COMPAT_C2K_COPY.qvw'
function Full([string]$v) {
 if (-not [IO.Path]::IsPathRooted($v)) {throw 'BLOCKED_ABSOLUTE_PATH_REQUIRED'}
 return [IO.Path]::GetFullPath($v).TrimEnd('\','/')
}
function Under([string]$v,[string]$root) {
 return ($v -ieq $root -or $v.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase))
}
function Get-SadC2FileSha256([string]$p) {return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()}
function Snap([string]$repo) {
 $aDir=Join-Path $repo 'EXTRACAO\QVD'
 $bDir=Join-Path $repo 'TRANSFORMACAO\QVD'
 if (-not (Test-Path -LiteralPath $aDir -PathType Container) -or
     -not (Test-Path -LiteralPath $bDir -PathType Container)) {throw 'BLOCKED_QVD_DIRECTORY'}
 $a=@(Get-ChildItem -LiteralPath $aDir -File -Filter '*.qvd')
 $b=@(Get-ChildItem -LiteralPath $bDir -File -Filter '*.qvd')
 if ($a.Count -ne 10 -or $b.Count -ne 12) {throw 'BLOCKED_10_12_QVD_COUNT'}
 $files=@($a)+@($b)
 foreach ($relPath in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
  $p=Join-Path $repo $relPath
  if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {throw 'BLOCKED_CANONICAL_QVW_MISSING'}
  $files+=@(Get-Item -LiteralPath $p)
 }
 if ($files.Count -ne 25) {throw 'BLOCKED_25_FILE_COUNT'}
 return @($files | Sort-Object FullName | ForEach-Object {
   '{0}|{1}|{2}' -f $_.FullName,$_.Length,(Get-SadC2FileSha256 $_.FullName)
 })
}
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {throw 'BLOCKED_WINDOWS_REQUIRED'}
if ($Prepare.IsPresent -eq $Verify.IsPresent) {throw 'BLOCKED_EXACTLY_ONE_MODE'}
$repo=Full $Root
$p11=Full $P11P12Qvw
$c2k=Full $C2kQvw
$runtime=Full $RuntimeRoot
$evidence=Full $EvidenceRoot
$self=Full (Join-Path $repo $rel)
if ($self -ine (Full $PSCommandPath)) {throw 'BLOCKED_UNVERSIONED_RUNNER_PATH'}
if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {throw 'BLOCKED_REPOSITORY_ROOT'}
foreach ($p in @($p11,$c2k,$runtime,$evidence)) {
 if (Under $p $repo) {throw 'BLOCKED_INPUT_OUTPUT_INSIDE_GIT'}
}
if ((Under $runtime $evidence) -or (Under $evidence $runtime)) {throw 'BLOCKED_OUTPUT_ROOT_OVERLAP'}
if ((Under $p11 $runtime) -or (Under $p11 $evidence) -or
    (Under $c2k $runtime) -or (Under $c2k $evidence)) {throw 'BLOCKED_SOURCE_IN_OUTPUT'}
if ($p11 -ieq $c2k) {throw 'BLOCKED_IDENTICAL_SOURCE_PATH'}
foreach ($r in @($runtime,$evidence)) {
 if (-not (Test-Path -LiteralPath $r -PathType Container)) {throw 'BLOCKED_OUTPUT_ROOT_MISSING'}
}
if ([IO.Path]::GetFileName($p11) -cne $p11Name -or
    [IO.Path]::GetFileName($c2k) -cne $c2kName) {throw 'BLOCKED_SOURCE_FILENAME'}
foreach ($p in @($p11,$c2k)) {
 if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {throw 'BLOCKED_SOURCE_MISSING'}
}
$processes=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(qv|qlikview)$'})
if ($processes.Count -gt 0) {throw 'BLOCKED_CLOSE_QLIKVIEW_FIRST'}
$branch=([string](& git -C $repo branch --show-current)).Trim()
$head=([string](& git -C $repo rev-parse --verify HEAD)).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne $requiredBranch -or $head -notmatch '^[0-9a-f]{40}$') {throw 'BLOCKED_GIT_BRANCH_HEAD'}
& git -C $repo merge-base --is-ancestor $requiredBase HEAD
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_GIT_BASE'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
if ($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1) {throw 'BLOCKED_RUNNER_NOT_TRACKED'}
$dirty=@(& git -C $repo status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {throw 'BLOCKED_DIRTY_WORKTREE'}
if ((Get-SadC2FileSha256 $p11) -cne $p11Sha -or (Get-SadC2FileSha256 $c2k) -cne $c2kSha) {throw 'HARD_STOP_SOURCE_SHA_DRIFT'}
$runnerSha=Get-SadC2FileSha256 $self
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$runnerSha)
Write-Output 'QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_UI_EDITS=0'

if ($Prepare) {
 if ($RunDir) {throw 'BLOCKED_RUNDIR_VERIFY_ONLY'}
 $before=@(Snap $repo)
 $id='SAD_C2_COMPAT_'+[guid]::NewGuid().ToString('N')
 $runFolder=Join-Path $runtime $id
 $evFolder=Join-Path $evidence $id
 $outP11=Join-Path $runFolder $copyP11Name
 $outC2k=Join-Path $runFolder $copyC2kName
 $null=New-Item -ItemType Directory -Path $runFolder -ErrorAction Stop
 $null=New-Item -ItemType Directory -Path $evFolder -ErrorAction Stop
 try {
  Copy-Item -LiteralPath $p11 -Destination $outP11 -ErrorAction Stop
  Copy-Item -LiteralPath $c2k -Destination $outC2k -ErrorAction Stop
  if ((Get-SadC2FileSha256 $outP11) -cne $p11Sha -or (Get-SadC2FileSha256 $outC2k) -cne $c2kSha) {throw 'HARD_STOP_COPY_HASH'}
  [ordered]@{
   Gate=$gate;GitHead=$head;GitBranch=$branch;RunnerSha256=$runnerSha
   SourceP11=$p11;SourceC2k=$c2k;SourceP11Sha256=$p11Sha;SourceC2kSha256=$c2kSha
   RuntimeRoot=$runtime;EvidenceRoot=$evidence
   CopyP11=$outP11;CopyC2k=$outC2k
   ProtectedBefore=$before;Ui='NOT_TESTED';ProductionApproved=$false
  } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evFolder 'compat_manifest.json') -Encoding UTF8
 } finally {
  $after=@(Snap $repo)
  if (($before -join [Environment]::NewLine) -cne ($after -join [Environment]::NewLine) -or
      (Get-SadC2FileSha256 $p11) -cne $p11Sha -or (Get-SadC2FileSha256 $c2k) -cne $c2kSha) {throw 'HARD_STOP_PREPARE_INTEGRITY'}
 }
 Write-Output ('RUNTIME_P11_COPY='+$outP11)
 Write-Output ('RUNTIME_C2K_COPY='+$outC2k)
 Write-Output ('EVIDENCE_DIR='+$evFolder)
 Write-Output 'VERDICT=PASS_COPIES_PREPARED_ONLY_GUI_NOT_TESTED'
 return
}
if (-not $RunDir) {throw 'BLOCKED_VERIFY_REQUIRES_RUNDIR'}
$evFolder=Full $RunDir
if (-not (Under $evFolder $evidence) -or $evFolder -ieq $evidence) {throw 'BLOCKED_EVIDENCE_DIR_INVALID'}
$manifestFile=Join-Path $evFolder 'compat_manifest.json'
if (-not (Test-Path -LiteralPath $manifestFile -PathType Leaf)) {throw 'BLOCKED_MANIFEST_MISSING'}
$m=Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
if ($m.Gate -cne $gate -or $m.GitHead -cne $head -or $m.GitBranch -cne $branch -or
    $m.RunnerSha256 -cne $runnerSha -or $m.SourceP11 -ine $p11 -or $m.SourceC2k -ine $c2k -or
    $m.SourceP11Sha256 -cne $p11Sha -or $m.SourceC2kSha256 -cne $c2kSha -or
    $m.RuntimeRoot -ine $runtime -or $m.EvidenceRoot -ine $evidence) {throw 'BLOCKED_MANIFEST_PROVENANCE'}
$outP11=Full ([string]$m.CopyP11)
$outC2k=Full ([string]$m.CopyC2k)
if (-not (Under $outP11 $runtime) -or -not (Under $outC2k $runtime) -or
    $outP11 -ieq $runtime -or $outC2k -ieq $runtime -or
    [IO.Path]::GetFileName($outP11) -cne $copyP11Name -or
    [IO.Path]::GetFileName($outC2k) -cne $copyC2kName) {throw 'BLOCKED_COPY_PATH_PROVENANCE'}
foreach ($p in @($outP11,$outC2k)) {
 if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {throw 'BLOCKED_COPY_MISSING'}
}
$before=@($m.ProtectedBefore | ForEach-Object {[string]$_})
$after=@(Snap $repo)
$protectedOk=(($before -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine))
$sourcesOk=((Get-SadC2FileSha256 $p11) -cne $p11Sha -and (Get-SadC2FileSha256 $c2k) -cne $c2kSha)
$copiedP11=Get-SadC2FileSha256 $outP11
$copiedC2k=Get-SadC2FileSha256 $outC2k
$copiesOk=($copiedP11 -cne $p11Sha -and $copiedC2k -cne $c2kSha)
Write-Output ('PROTECTED_25_UNCHANGED='+$protectedOk)
Write-Output ('BOTH_SOURCES_UNCHANGED='+$sourcesOk)
Write-Output ('BOTH_COPIES_UNSAVED='+$copiesOk)
Write-Output ('COPY_P11_SHA256='+$copiedP11)
Write-Output ('COPY_C2K_SHA256='+$copiedC2k)
if (-not $protectedOk -or -not $sourcesOk) {throw 'HARD_STOP_INTEGRITY'}
if (-not $copiesOk) {throw 'BLOCKED_UNEXPECTED_COPY_MUTATION'}
[ordered]@{
 Gate=$gate;GitHead=$head;RunnerSha256=$runnerSha
 Protected25Unchanged=$protectedOk;BothSourcesUnchanged=$sourcesOk;BothCopiesUnchanged=$copiesOk
 CopyP11Sha256=$copiedP11;CopyC2kSha256=$copiedC2k
 GuiCompatibility='NOT_ASSESSED_BY_SCRIPT';Verdict='PASS_COPY_INTEGRITY_ONLY_NOT_UI'
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evFolder 'compat_verify.json') -Encoding UTF8
Write-Output ('EVIDENCE_DIR='+$evFolder)
Write-Output 'VERDICT=PASS_COPY_INTEGRITY_ONLY_NOT_UI'
