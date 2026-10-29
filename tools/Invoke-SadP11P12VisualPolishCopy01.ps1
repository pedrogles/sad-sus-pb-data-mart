# SAD-P11-P12-VISUAL-POLISH-COPY-01: guarded copy and hash closeout, Windows PowerShell 5.1.
# Only -Prepare writes to new runtime/evidence directories OUTSIDE the repo; -Verify writes a JSON in its own evidence directory.
# No QlikView COM, reload, STORE or GUI automation. Never touches original QVD/QVW.
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
$scriptRel='tools\Invoke-SadP11P12VisualPolishCopy01.ps1'
$requiredBranch='test/sad-p11-p12-visual-polish-copy-01-20261029'
$parentGate='SAD-P12-PHYSICAL-CORRECTIVE-01'
$parentHead='d2bd31f0959db76156bc4dcaa50d525df2371db4'
$parentRunnerSha='5C3F6263A82BDC05AC79DDF432C4ABAC1DC80BDBB04F275DFD2BD883EA7B1C86'
$parentSourceSha='603464EB5AD5696DA001D5431194EF37D509448695DBBBB9EA1B7252F96EC791'
$visualSourceSha='8E2096D42602D7B84239AE30498EE45FA3ED6B060B9EEC6A4C003B0B3A2B7DE4'
$copyName='SAD_P11P12_VISUAL_POLISH_COPY.qvw'
$manifestName='p11p12_visual_polish_manifest.json'

function Get-SadFullPath([string]$path) {
 return [IO.Path]::GetFullPath($path).TrimEnd([char[]]@('\','/'))
}
function Get-SadHash([string]$path) {
 return (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
}
function Test-SadInside([string]$child,[string]$parent) {
 return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
        $child.StartsWith(($parent+'\'),[StringComparison]::OrdinalIgnoreCase)
}
function ConvertFrom-SadProtectedLine([string]$text) {
 $m=[regex]::Match($text,'^(?<p>[^|]+)\|(?<n>[0-9]+)\|(?<s>[0-9A-Fa-f]{64})$')
 if (-not $m.Success) { throw 'BLOCKED_BAD_PROTECTED_MANIFEST_LINE' }
 return [pscustomobject]@{
  Path=$m.Groups['p'].Value
  Length=[long]::Parse($m.Groups['n'].Value)
  Sha=$m.Groups['s'].Value.ToUpperInvariant()
 }
}
function Get-SadProtectedInventory {
 $extract=Join-Path $repo 'EXTRACAO\QVD'
 $transform=Join-Path $repo 'TRANSFORMACAO\QVD'
 $e=@(Get-ChildItem -LiteralPath $extract -File -Filter '*.qvd' -ErrorAction Stop)
 $t=@(Get-ChildItem -LiteralPath $transform -File -Filter '*.qvd' -ErrorAction Stop)
 if ($e.Count -ne 10 -or $t.Count -ne 12) { throw 'HARD_STOP_QVD_SCOPE_NOT_10_12' }
 $all=@($e)+@($t)
 foreach($rel in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
  $file=Join-Path $repo $rel
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw ('HARD_STOP_QVW_MISSING='+$rel) }
  $all+=@(Get-Item -LiteralPath $file -ErrorAction Stop)
 }
 return @($all | ForEach-Object {
   [pscustomobject]@{ Path=$_.FullName; Length=[long]$_.Length; Sha=(Get-SadHash $_.FullName) }
 })
}
function Assert-SadProtected([object[]]$baseline) {
 if ($baseline.Count -ne 25) { throw 'BLOCKED_BASELINE_NOT_25' }
 $now=@(Get-SadProtectedInventory)
 if ($now.Count -ne 25) { throw 'HARD_STOP_INVENTORY_NOT_25' }
 $index=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($x in $now) {
  if ($index.ContainsKey([string]$x.Path)) { throw 'HARD_STOP_DUPLICATE_CURRENT_PATH' }
  $index.Add([string]$x.Path,$x)
 }
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $issues=[Collections.Generic.List[string]]::new()
 $caseCount=0
 foreach($old in $baseline) {
  $p=[string]$old.Path
  if (-not $seen.Add($p)) { throw 'BLOCKED_DUPLICATE_BASELINE_PATH' }
  if (-not (Test-SadInside $p $repo)) { throw ('BLOCKED_BASELINE_PATH_OUTSIDE_REPO='+$p) }
  if (-not $index.ContainsKey($p)) { $issues.Add('MISSING='+$p); continue }
  $current=$index[$p]
  if ($p -cne [string]$current.Path) { $caseCount++ }
  if ([long]$old.Length -ne [long]$current.Length) { $issues.Add('SIZE_CHANGED='+$p) }
  if ([string]$old.Sha -cne [string]$current.Sha) { $issues.Add('SHA256_CHANGED='+$p) }
 }
 foreach($x in $now) {
  if (-not $seen.Contains([string]$x.Path)) { $issues.Add('EXTRA='+$x.Path) }
 }
 foreach($issue in $issues) { Write-Output ('PROTECTED_DIFF='+$issue) }
 if ($issues.Count -gt 0) { throw 'HARD_STOP_PROTECTED_CONTENT_DRIFT' }
 Write-Output ('PROTECTED_25_UNCHANGED=True PATH_CASE_VARIATIONS='+$caseCount)
}
function Assert-SadClosed([string]$name) {
 $open=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
   $_.ProcessName -match '^(qv|qlikview)$' -and $_.MainWindowTitle -like ('*'+$name+'*')
 })
 if ($open.Count -gt 0) { throw ('BLOCKED_QVW_OPEN='+$name) }
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or
    $PSVersionTable.PSVersion.Major -ne 5) { throw 'BLOCKED_WINDOWS_PS51_REQUIRED' }
if ($Prepare.IsPresent -eq $Verify.IsPresent) { throw 'BLOCKED_SELECT_PREPARE_OR_VERIFY' }
if ($ExpectedCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'BLOCKED_EXPECTED_COMMIT_SHA40' }
foreach($path in @($Root,$ParentManifestPath,$RuntimeRoot,$EvidenceRoot)) {
 if (-not [IO.Path]::IsPathRooted($path)) { throw 'BLOCKED_ALL_PATHS_ABSOLUTE' }
}
$repo=Get-SadFullPath $Root
$parentPath=Get-SadFullPath $ParentManifestPath
$runtime=Get-SadFullPath $RuntimeRoot
$evidence=Get-SadFullPath $EvidenceRoot
$self=Get-SadFullPath (Join-Path $repo $scriptRel)
if ($self -ine (Get-SadFullPath $PSCommandPath) -or
    -not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {
 throw 'BLOCKED_SCRIPT_OR_REPO_ROOT'
}
if ((Test-SadInside $runtime $repo) -or (Test-SadInside $evidence $repo) -or
    (Test-SadInside $parentPath $repo)) { throw 'BLOCKED_EVIDENCE_OR_RUNTIME_INSIDE_REPO' }
$head=([string](& git -C $repo rev-parse HEAD)).Trim()
$branch=([string](& git -C $repo branch --show-current)).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit -or
    $branch -cne $requiredBranch) { throw 'BLOCKED_BRANCH_OR_HEAD' }
$dirty=@(& git -C $repo status --porcelain)
if ($dirty.Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
$scriptSha=Get-SadHash $self
Write-Output ('GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$scriptSha)
Write-Output 'COM=0 RELOAD=0 STORE=0 AUTOMATED_GUI=0'

if (-not (Test-Path -LiteralPath $parentPath -PathType Leaf)) {
 throw 'BLOCKED_PARENT_MANIFEST_MISSING'
}
$p=Get-Content -LiteralPath $parentPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($p.Gate -cne $parentGate -or $p.GitHead -cne $parentHead -or
    $p.RunnerSha256 -cne $parentRunnerSha -or
    $p.SourceSha256 -cne $parentSourceSha -or
    $p.CopyBeforeSha256 -cne $parentSourceSha) {
 throw 'BLOCKED_PARENT_PROVENANCE_MISMATCH'
}
$source=Get-SadFullPath ([string]$p.Copy)
if ([IO.Path]::GetFileName($source) -cne 'SAD_P12_CORRECTIVE_COPY.qvw' -or
    (Test-SadInside $source $repo) -or
    -not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'BLOCKED_SOURCE_QVW' }
if (-not $source.StartsWith('C:\Users\pedro\Documents\SAD_P12_CORRECTIVE_RUNTIME\',[StringComparison]::OrdinalIgnoreCase)) {
 throw 'BLOCKED_SOURCE_NOT_KNOWN_RUNTIME'
}
Assert-SadClosed 'SAD_P12_CORRECTIVE_COPY.qvw'
$sourceSha=Get-SadHash $source
Write-Output ('SOURCE_SHA256='+$sourceSha)
if ($sourceSha -cne $visualSourceSha) { throw 'HARD_STOP_VISUAL_SOURCE_SHA_DRIFT' }
$baseline=@($p.ProtectedBefore | ForEach-Object { ConvertFrom-SadProtectedLine ([string]$_) })
Assert-SadProtected $baseline

if ($Prepare) {
 if ($RunDir) { throw 'BLOCKED_RUNDIR_NOT_ALLOWED_IN_PREPARE' }
 if (-not (Test-Path -LiteralPath $runtime -PathType Container) -or
     -not (Test-Path -LiteralPath $evidence -PathType Container)) {
  throw 'BLOCKED_CREATE_ROOT_DIRS_BEFORE_PREPARE'
 }
 $id='SAD_P11P12_VISUAL_'+[guid]::NewGuid().ToString('N')
 $runRuntime=Join-Path $runtime $id
 $runEvidence=Join-Path $evidence $id
 $copy=Join-Path $runRuntime $copyName
 $null=New-Item -ItemType Directory -Path $runRuntime -ErrorAction Stop
 $null=New-Item -ItemType Directory -Path $runEvidence -ErrorAction Stop
 Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
 $copySha=Get-SadHash $copy
 if ($copySha -cne $visualSourceSha) { throw 'HARD_STOP_NEW_COPY_SHA_CHANGED' }
 Assert-SadProtected $baseline
 if ((Get-SadHash $source) -cne $visualSourceSha) { throw 'HARD_STOP_SOURCE_CHANGED_DURING_PREPARE' }
 [ordered]@{
  Gate='SAD-P11-P12-VISUAL-POLISH-COPY-01'
  GitHead=$head;RunnerSha256=$scriptSha;ParentManifest=$parentPath
  Source=$source;SourceSha256=$sourceSha
  RuntimeRoot=$runtime;EvidenceRoot=$evidence
  Copy=$copy;CopyBeforeSha256=$copySha
  ProtectedBefore=@($p.ProtectedBefore)
  QvwUi='NOT_TESTED';OracleAfter='NOT_TESTED';ProductionApproved=$false
 } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runEvidence $manifestName) -Encoding UTF8
 Write-Output ('RUNTIME_COPY='+$copy)
 Write-Output ('EVIDENCE_DIR='+$runEvidence)
 Write-Output 'VERDICT=PASS_PREPARE_COPY_ONLY_UI_NOT_TESTED'
 return
}

if (-not $RunDir -or -not [IO.Path]::IsPathRooted($RunDir)) { throw 'BLOCKED_VERIFY_RUNDIR_ABSOLUTE' }
$runEvidence=Get-SadFullPath $RunDir
if (-not $runEvidence.StartsWith(($evidence+'\'),[StringComparison]::OrdinalIgnoreCase)) {
 throw 'BLOCKED_VERIFY_RUNDIR_OUTSIDE_EVIDENCE'
}
$manifestPath=Join-Path $runEvidence $manifestName
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'BLOCKED_VISUAL_MANIFEST_MISSING' }
$m=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($m.Gate -cne 'SAD-P11-P12-VISUAL-POLISH-COPY-01' -or
    $m.GitHead -cne $head -or $m.RunnerSha256 -cne $scriptSha -or
    $m.ParentManifest -ine $parentPath -or $m.Source -ine $source -or
    $m.SourceSha256 -cne $sourceSha -or
    $m.CopyBeforeSha256 -cne $visualSourceSha) {
 throw 'BLOCKED_VISUAL_MANIFEST_PROVENANCE'
}
$copy=Get-SadFullPath ([string]$m.Copy)
if ([IO.Path]::GetFileName($copy) -cne $copyName -or
    -not $copy.StartsWith(($runtime+'\'),[StringComparison]::OrdinalIgnoreCase)) {
 throw 'BLOCKED_COPY_OUTSIDE_RUNTIME'
}
Assert-SadClosed $copyName
if (-not (Test-Path -LiteralPath $copy -PathType Leaf)) { throw 'BLOCKED_COPY_MISSING' }
$after=Get-SadHash $copy
Assert-SadProtected $baseline
if ((Get-SadHash $source) -cne $visualSourceSha) { throw 'HARD_STOP_SOURCE_CHANGED' }
Write-Output 'SOURCE_UNCHANGED=True'
Write-Output ('COPY_SHA256='+$after)
if ($after -ceq $visualSourceSha) { throw 'BLOCKED_NO_VISUAL_COPY_CHANGE_SAVED' }
Write-Output 'COPY_CHANGED=True'
[ordered]@{
 Gate=$m.Gate;GitHead=$head;RunnerSha256=$scriptSha
 Protected25Unchanged=$true;SourceUnchanged=$true
 CopyChanged=$true;CopySha256=$after;UI='NOT_PROVEN_BY_HASH'
 Verdict='PASS_HASH_CLOSEOUT_ONLY'
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runEvidence 'p11p12_visual_polish_verify.json') -Encoding UTF8
Write-Output ('EVIDENCE_DIR='+$runEvidence)
Write-Output 'VERDICT=PASS_HASH_INTEGRITY_ONLY_VISUAL_REQUIRES_REVIEW'
