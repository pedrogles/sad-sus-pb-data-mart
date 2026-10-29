# SAD-P12-PATH-CASE-CLOSEOUT-01. Read-only; does not rerun original -Prepare/-Verify.
# Windows PowerShell 5.1 only. No COM, reload, STORE, UI, copy, or file writes.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ExpectedCommit,
  [string]$CorrectiveManifestPath,
  [switch]$SelfTest
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$relScript = 'tools/Inspect-SadP12PathCaseCloseout01.ps1'
$requiredBranch = 'diagnostics/sad-p12-path-case-closeout-01-20261029'
$correctiveGate = 'SAD-P12-PHYSICAL-CORRECTIVE-01'
$correctiveHead = 'd2bd31f0959db76156bc4dcaa50d525df2371db4'
$correctiveRunnerSha = '5C3F6263A82BDC05AC79DDF432C4ABAC1DC80BDBB04F275DFD2BD883EA7B1C86'
$parentGate = 'SAD-P1-P11-P12-PHYSICAL-POC-01'
$parentHead = 'd901df16ae78dc0c7ff2a2d05c439353e7219793'
$parentRunnerSha = 'D0B4091F4ABB44CA0B474FF34A4E0F1525E40D5EADABFE8629139639D2AA81ED'
$oldCopySha = '603464EB5AD5696DA001D5431194EF37D509448695DBBBB9EA1B7252F96EC791'

function Full([string]$path) {
  return [IO.Path]::GetFullPath($path).TrimEnd([char[]]@('\','/'))
}
function Inside([string]$child,[string]$parent) {
  return $child.StartsWith(($parent+'\'),[StringComparison]::OrdinalIgnoreCase)
}
function Hash([string]$path) {
  return (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
}
function Entry([string]$path,[long]$bytes,[string]$sha,[string]$errorLabel,[bool]$unstable) {
  return [pscustomobject]@{
    Path=$path; Bytes=$bytes; Sha=$sha.ToUpperInvariant(); ErrorLabel=$errorLabel; Unstable=$unstable
  }
}
function ParseEntry([string]$line) {
  $m=[regex]::Match($line,'^(?<path>[^|]+)\|(?<bytes>[0-9]+)\|(?<sha>[A-Fa-f0-9]{64})$')
  if (-not $m.Success) { throw 'BLOCKED_BAD_MANIFEST_ENTRY' }
  return (Entry $m.Groups['path'].Value ([long]::Parse($m.Groups['bytes'].Value)) $m.Groups['sha'].Value '' $false)
}
# Path identity is OrdinalIgnoreCase on Windows; content size and SHA remain strict.
function Compare-SadP12Records([object[]]$before,[object[]]$after) {
  $a=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
  $b=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach($r in $before) {
    if ($a.ContainsKey($r.Path)) { throw 'HARD_STOP_DUPLICATE_BASELINE_PATH' }
    $a.Add([string]$r.Path,$r)
  }
  foreach($r in $after) {
    if ($b.ContainsKey($r.Path)) { throw 'HARD_STOP_DUPLICATE_CURRENT_PATH' }
    $b.Add([string]$r.Path,$r)
  }
  $issues=@(); $caseOnly=@()
  foreach($old in $before) {
    $p=[string]$old.Path
    if (-not $b.ContainsKey($p)) { $issues+=('MISSING='+$p); continue }
    $now=$b[$p]
    if ($now.ErrorLabel) { $issues+=('UNREADABLE='+$p); continue }
    if ($now.Unstable) { $issues+=('UNSTABLE_DURING_READ='+$p) }
    if ($p -cne [string]$now.Path) { $caseOnly+=('PATH_CASE_ONLY='+$p) }
    if ([long]$old.Bytes -ne [long]$now.Bytes) { $issues+=('SIZE_CHANGED='+$p) }
    if ([string]$old.Sha -cne [string]$now.Sha) { $issues+=('SHA256_CHANGED='+$p) }
  }
  foreach($now in $after) {
    if (-not $a.ContainsKey([string]$now.Path)) { $issues+=('EXTRA='+$now.Path) }
  }
  return [pscustomobject]@{ Issues=@($issues); CaseOnly=@($caseOnly) }
}
function Expect([string]$name,[object[]]$old,[object[]]$now,[int]$blocking,[int]$caseCount) {
  $res=Compare-SadP12Records $old $now
  if ($res.Issues.Count -ne $blocking -or $res.CaseOnly.Count -ne $caseCount) {
    throw ('SELFTEST_FAIL_'+$name+'_ISSUES='+$res.Issues.Count+'_CASE='+$res.CaseOnly.Count)
  }
  Write-Output ('SYNTHETIC_'+$name+'=PASS')
}
function Scan([string]$path) {
  try {
    $first=Get-Item -LiteralPath $path -ErrorAction Stop
    if ($first.PSIsContainer) { throw 'PATH_IS_DIRECTORY' }
    $bytes=[long]$first.Length
    $stamp=$first.LastWriteTimeUtc.Ticks
    $digest=Hash $path
    $second=Get-Item -LiteralPath $path -ErrorAction Stop
    $unstable=($bytes -ne [long]$second.Length -or $stamp -ne $second.LastWriteTimeUtc.Ticks)
    return (Entry $second.FullName ([long]$second.Length) $digest '' $unstable)
  } catch {
    return (Entry $path 0 '' 'READ_FAILURE' $false)
  }
}
function Inventory([string]$repo) {
  $e=Join-Path $repo 'EXTRACAO\QVD'
  $t=Join-Path $repo 'TRANSFORMACAO\QVD'
  $a=@(Get-ChildItem -LiteralPath $e -Filter '*.qvd' -File -ErrorAction Stop)
  $b=@(Get-ChildItem -LiteralPath $t -Filter '*.qvd' -File -ErrorAction Stop)
  if ($a.Count -ne 10 -or $b.Count -ne 12) { throw 'HARD_STOP_QVD_SCOPE_NOT_10_PLUS_12' }
  $paths=@($a | ForEach-Object { $_.FullName })+@($b | ForEach-Object { $_.FullName })
  foreach($rel in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
    $p=Join-Path $repo $rel
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw ('HARD_STOP_MISSING_QVW='+$rel) }
    $paths+=@( $p )
  }
  return @($paths | ForEach-Object { Scan $_ })
}
function Assert-Baseline([object[]]$base,[string]$repo) {
  if ($base.Count -ne 25) { throw 'BLOCKED_BASELINE_COUNT_NOT_25' }
  $countE=0;$countT=0;$countQ=0
  foreach($r in $base) {
    if (-not (Inside $r.Path $repo)) { throw 'BLOCKED_BASELINE_OUTSIDE_REPO' }
    $rel=$r.Path.Substring($repo.Length+1)
    if ($rel -match '^EXTRACAO\\QVD\\[^\\]+\.qvd$') { $countE++ }
    elseif ($rel -match '^TRANSFORMACAO\\QVD\\[^\\]+\.qvd$') { $countT++ }
    elseif (@('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw') -icontains $rel) { $countQ++ }
    else { throw ('BLOCKED_UNEXPECTED_PROTECTED_PATH='+$rel) }
  }
  if ($countE -ne 10 -or $countT -ne 12 -or $countQ -ne 3) { throw 'BLOCKED_BASELINE_SCOPE_NOT_10_12_3' }
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or $PSVersionTable.PSVersion.Major -ne 5) {
  throw 'BLOCKED_WINDOWS_PS51_REQUIRED'
}
if ($ExpectedCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'BLOCKED_EXPECTED_SHA40' }
if (-not [IO.Path]::IsPathRooted($Root)) { throw 'BLOCKED_ABSOLUTE_ROOT' }
$repo=Full $Root
$self=Full (Join-Path $repo $relScript)
if ($self -ine (Full $PSCommandPath) -or -not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {
  throw 'BLOCKED_COMMITTED_SCRIPT_PATH'
}
$head=([string](& git -C $repo rev-parse HEAD)).Trim()
$branch=([string](& git -C $repo branch --show-current)).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit -or $branch -cne $requiredBranch) {
  throw 'BLOCKED_BRANCH_OR_COMMIT'
}
$dirty=@(& git -C $repo status --porcelain)
if ($dirty.Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
Write-Output ('GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+(Hash $self))
Write-Output 'MODE=READ_ONLY QLIKVIEW_COM=0 RELOAD=0 STORE=0 WRITE=0'

if ($SelfTest) {
  if ($CorrectiveManifestPath) { throw 'BLOCKED_SELFTEST_NO_MANIFEST' }
  $h1='A'*64; $h2='B'*64
  $old=@((Entry 'C:\Fixture\one.qvd' 10 $h1 '' $false),(Entry 'C:\Fixture\two.qvd' 20 $h2 '' $false))
  Expect 'IDENTICAL' $old $old 0 0
  Expect 'REORDER' $old @($old[1],$old[0]) 0 0
  Expect 'PATH_CASE' $old @((Entry 'c:\fixture\one.qvd' 10 $h1 '' $false),$old[1]) 0 1
  Expect 'HASH_DRIFT' $old @((Entry 'C:\Fixture\one.qvd' 10 $h2 '' $false),$old[1]) 1 0
  Expect 'SIZE_DRIFT' $old @((Entry 'C:\Fixture\one.qvd' 11 $h1 '' $false),$old[1]) 1 0
  Expect 'CASE_WITH_HASH_DRIFT' $old @((Entry 'c:\fixture\one.qvd' 10 $h2 '' $false),$old[1]) 1 1
  Expect 'MISSING' $old @($old[0]) 1 0
  Expect 'EXTRA' $old @($old[0],$old[1],(Entry 'C:\Fixture\three.qvd' 3 $h1 '' $false)) 1 0
  Expect 'UNSTABLE' $old @((Entry 'C:\Fixture\one.qvd' 10 $h1 '' $true),$old[1]) 1 0
  Expect 'UNREADABLE' $old @((Entry 'C:\Fixture\one.qvd' 0 '' 'READ_FAILURE' $false),$old[1]) 1 0
  Write-Output 'VERDICT=PASS_10_SYNTHETIC_CASES_ONLY'
  return
}

if (-not $CorrectiveManifestPath -or -not [IO.Path]::IsPathRooted($CorrectiveManifestPath)) {
  throw 'BLOCKED_CORRECTIVE_MANIFEST_ABSOLUTE'
}
$manifestPath=Full $CorrectiveManifestPath
if ((Inside $manifestPath $repo) -or -not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
  throw 'BLOCKED_CORRECTIVE_MANIFEST_LOCATION'
}
$m=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($m.Gate -cne $correctiveGate -or $m.GitHead -cne $correctiveHead -or
    $m.RunnerSha256 -cne $correctiveRunnerSha -or $m.CopyBeforeSha256 -cne $oldCopySha -or
    $m.SourceSha256 -cne $oldCopySha) {
  throw 'BLOCKED_CORRECTIVE_PROVENANCE'
}
$parentPath=Full ([string]$m.ParentManifest)
if ((Inside $parentPath $repo) -or -not (Test-Path -LiteralPath $parentPath -PathType Leaf)) {
  throw 'BLOCKED_PARENT_MANIFEST_LOCATION'
}
$p=Get-Content -LiteralPath $parentPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($p.Gate -cne $parentGate -or $p.GitHead -cne $parentHead -or $p.RunnerSha256 -cne $parentRunnerSha) {
  throw 'BLOCKED_PARENT_PROVENANCE'
}
$parentCopy=Full ([string]$p.Copy)
$source=Full ([string]$m.Source)
if (-not $source.Equals($parentCopy,[StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($source) -cne 'SAD_P11_P12_VISUAL_POC_COPY.qvw') {
  throw 'BLOCKED_SOURCE_NOT_PARENT_COPY'
}
$runtime=Full ([string]$m.RuntimeRoot)
$evidence=Full ([string]$m.EvidenceRoot)
$copy=Full ([string]$m.Copy)
if ((Inside $runtime $repo) -or (Inside $evidence $repo) -or
    -not (Inside $manifestPath $evidence) -or -not (Inside $copy $runtime) -or
    [IO.Path]::GetFileName($copy) -cne 'SAD_P12_CORRECTIVE_COPY.qvw') {
  throw 'BLOCKED_RUNTIME_EVIDENCE_SCOPE'
}
$oldBase=@($p.ProtectedBefore | ForEach-Object { ParseEntry ([string]$_) })
$newBase=@($m.ProtectedBefore | ForEach-Object { ParseEntry ([string]$_) })
Assert-Baseline $oldBase $repo
Assert-Baseline $newBase $repo
$between=Compare-SadP12Records $oldBase $newBase
if ($between.Issues.Count -gt 0) { throw 'HARD_STOP_MANIFEST_BASELINES_DIVERGE' }
Write-Output ('MANIFEST_PATH_CASE_VARIATIONS='+$between.CaseOnly.Count)

# Exactly one current scan of the 25 protected originals. No source or test-copy mutation.
$current=@(Inventory $repo)
$result=Compare-SadP12Records $oldBase $current
Write-Output ('PROTECTED_FILES_CHECKED='+$current.Count)
Write-Output ('PROTECTED_PATH_CASE_ONLY='+$result.CaseOnly.Count)
Write-Output ('PROTECTED_BLOCKING_ISSUES='+$result.Issues.Count)
foreach($issue in $result.Issues) { Write-Output ('PROTECTED_DIFF='+$issue) }
foreach($caseItem in @($result.CaseOnly | Select-Object -First 3)) {
  Write-Output ('PATH_CASE_EXAMPLE='+$caseItem)
}
if ($current.Count -ne 25 -or $result.Issues.Count -gt 0) { throw 'HARD_STOP_PROTECTED_CONTENT_OR_SCOPE_DRIFT' }
Write-Output 'PROTECTED_25_CONTENT_UNCHANGED=True'

if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or -not (Test-Path -LiteralPath $copy -PathType Leaf)) {
  throw 'HARD_STOP_SOURCE_OR_COPY_MISSING'
}
$sourceState=Scan $source
$copyState=Scan $copy
if ($sourceState.ErrorLabel -or $sourceState.Unstable -or $copyState.ErrorLabel -or $copyState.Unstable) {
  throw 'HARD_STOP_SOURCE_OR_COPY_UNSTABLE'
}
Write-Output ('SOURCE_SHA256='+$sourceState.Sha)
Write-Output ('COPY_SHA256='+$copyState.Sha)
if ($sourceState.Sha -cne $oldCopySha) { throw 'HARD_STOP_PREVIOUS_SOURCE_SHA_DRIFT' }
if ($copyState.Sha -ceq $oldCopySha) { throw 'BLOCKED_SAVED_TEST_COPY_UNCHANGED' }
Write-Output 'SOURCE_UNCHANGED=True'
Write-Output 'COPY_CHANGED=True'
Write-Output 'VERDICT=PASS_READ_ONLY_CURRENT_HASH_CLOSEOUT_ONLY_UI_NOT_RETESTED'
