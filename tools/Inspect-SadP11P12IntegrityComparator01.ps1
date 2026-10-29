# SAD-P11-P12-INTEGRITY-COMPARATOR-01: read-only, one-shot forensic inspector.
# Windows PowerShell 5.1. Does NOT execute QlikView, modify QVD/QVW, or rerun -Verify.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ExpectedCommit,
  [string]$ManifestPath,
  [switch]$SelfTest
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptRel = 'tools/Inspect-SadP11P12IntegrityComparator01.ps1'
$requiredBranch = 'diagnostics/sad-p11-p12-integrity-comparator-01-20261028'
$originalCommit = 'd901df16ae78dc0c7ff2a2d05c439353e7219793'
$originalRunnerSha = 'D0B4091F4ABB44CA0B474FF34A4E0F1525E40D5EADABFE8629139639D2AA81ED'

function New-Record([string]$path,[long]$size,[string]$sha,[string]$errorName,[bool]$unstable) {
  return [pscustomobject]@{
    Path=$path; Size=$size; Sha=$sha.ToUpperInvariant(); ErrorName=$errorName; Unstable=$unstable
  }
}
function Parse-Entry([string]$line) {
  $m=[regex]::Match($line,'^(?<p>[^|]+)\|(?<n>[0-9]+)\|(?<h>[a-fA-F0-9]{64})$')
  if (-not $m.Success) { throw 'BLOCKED_MANIFEST_ENTRY_FORMAT' }
  return (New-Record $m.Groups['p'].Value ([long]$m.Groups['n'].Value) $m.Groups['h'].Value '' $false)
}
function Compare-Records([object[]]$before,[object[]]$after) {
  $a=@{}; $b=@{}
  foreach ($x in $before) {
    if ($a.ContainsKey([string]$x.Path)) { throw 'BLOCKED_DUPLICATE_BEFORE_PATH' }
    $a[[string]$x.Path]=$x
  }
  foreach ($x in $after) {
    if ($b.ContainsKey([string]$x.Path)) { throw 'BLOCKED_DUPLICATE_AFTER_PATH' }
    $b[[string]$x.Path]=$x
  }
  foreach ($x in $before) {
    $path=[string]$x.Path
    if (-not $b.ContainsKey($path)) {
      [pscustomobject]@{Kind='MISSING';Path=$path;ExpectedSize=$x.Size;NowSize=$null;ExpectedSha=$x.Sha;NowSha=$null}
      continue
    }
    $y=$b[$path]
    if ($y.ErrorName) {
      [pscustomobject]@{Kind='UNREADABLE';Path=$path;ExpectedSize=$x.Size;NowSize=$null;ExpectedSha=$x.Sha;NowSha=$null}
      continue
    }
    $kinds=@()
    if ($y.Unstable) { $kinds+='UNSTABLE_DURING_READ' }
    if ([long]$x.Size -ne [long]$y.Size) { $kinds+='SIZE_CHANGED' }
    if ([string]$x.Sha -cne [string]$y.Sha) { $kinds+='SHA256_CHANGED' }
    if ([string]$x.Path -cne [string]$y.Path) { $kinds+='PATH_TEXT_DIFFERENCE' }
    foreach ($kind in $kinds) {
      [pscustomobject]@{Kind=$kind;Path=$path;ExpectedSize=$x.Size;NowSize=$y.Size;ExpectedSha=$x.Sha;NowSha=$y.Sha}
    }
  }
  foreach ($y in $after) {
    if (-not $a.ContainsKey([string]$y.Path)) {
      [pscustomobject]@{Kind='EXTRA';Path=$y.Path;ExpectedSize=$null;NowSize=$y.Size;ExpectedSha=$null;NowSha=$y.Sha}
    }
  }
}
function Assert-Case([string]$name,[object[]]$old,[object[]]$new,[string]$expectedKinds) {
  $actual=@(Compare-Records $old $new | ForEach-Object { $_.Kind } | Sort-Object)
  if (($actual -join ',') -cne $expectedKinds) {
    throw ('SELFTEST_FAILED_'+$name+'_FOUND_'+($actual -join ','))
  }
  Write-Output ('SYNTHETIC_'+$name+'=PASS')
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'BLOCKED_WINDOWS_REQUIRED' }
if ($PSVersionTable.PSVersion.Major -ne 5) { throw 'BLOCKED_PS51_REQUIRED' }
if ($ExpectedCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'BLOCKED_EXPECTED_COMMIT' }
if (-not [IO.Path]::IsPathRooted($Root)) { throw 'BLOCKED_ABSOLUTE_REPO_PATH' }
$repo=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))
$self=[IO.Path]::GetFullPath((Join-Path $repo $scriptRel))
if ($self -ine [IO.Path]::GetFullPath($PSCommandPath)) { throw 'BLOCKED_EXECUTOR_PATH' }
if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) { throw 'BLOCKED_REPO_ROOT' }
$head=([string](& git -C $repo rev-parse HEAD)).Trim()
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_GIT_HEAD' }
$branch=([string](& git -C $repo branch --show-current)).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit -or $branch -cne $requiredBranch) {
  throw 'BLOCKED_BRANCH_OR_HEAD'
}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $scriptRel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $scriptRel)
if ($tracked.Count -ne 1 -or $dirty.Count -gt 0) { throw 'BLOCKED_SCRIPT_NOT_CLEAN_AND_VERSIONED' }
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('SCRIPT_SHA256='+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output 'MODE=READ_ONLY NO_WRITES=TRUE QLIKVIEW_COM=0 RELOAD=0'

if ($SelfTest) {
  if ($ManifestPath) { throw 'BLOCKED_SELFTEST_WITH_MANIFEST' }
  $hA='A'*64; $hB='B'*64
  $old=@((New-Record 'C:\fixture\a.qvd' 10 $hA '' $false),(New-Record 'C:\fixture\b.qvd' 20 $hB '' $false))
  Assert-Case 'IDENTICAL' $old $old ''
  Assert-Case 'ORDER' $old @($old[1],$old[0]) ''
  Assert-Case 'HASH' $old @((New-Record 'C:\fixture\a.qvd' 10 $hB '' $false),$old[1]) 'SHA256_CHANGED'
  Assert-Case 'SIZE' $old @((New-Record 'C:\fixture\a.qvd' 11 $hA '' $false),$old[1]) 'SIZE_CHANGED'
  Assert-Case 'MISSING' $old @($old[0]) 'MISSING'
  Assert-Case 'EXTRA' $old @($old[0],$old[1],(New-Record 'C:\fixture\c.qvd' 10 $hA '' $false)) 'EXTRA'
  Assert-Case 'PATH_TEXT' $old @((New-Record 'c:\fixture\a.qvd' 10 $hA '' $false),$old[1]) 'PATH_TEXT_DIFFERENCE'
  Assert-Case 'UNSTABLE' $old @((New-Record 'C:\fixture\a.qvd' 10 $hA '' $true),$old[1]) 'UNSTABLE_DURING_READ'
  Assert-Case 'UNREADABLE' $old @((New-Record 'C:\fixture\a.qvd' 0 '' 'UNREADABLE' $false),$old[1]) 'UNREADABLE'
  Write-Output 'VERDICT=PASS_9_SYNTHETIC_CASES_ONLY'
  return
}

if (-not $ManifestPath -or -not [IO.Path]::IsPathRooted($ManifestPath)) { throw 'BLOCKED_MANIFEST_ABSOLUTE_PATH' }
$manifest=[IO.Path]::GetFullPath($ManifestPath)
if ($manifest.StartsWith($repo+'\', [StringComparison]::OrdinalIgnoreCase)) { throw 'BLOCKED_MANIFEST_INSIDE_REPO' }
if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw 'BLOCKED_MANIFEST_NOT_FOUND' }
$m=Get-Content -LiteralPath $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
if ($m.Gate -cne 'SAD-P1-P11-P12-PHYSICAL-POC-01' -or
    $m.GitHead -cne $originalCommit -or $m.RunnerSha256 -cne $originalRunnerSha) {
  throw 'BLOCKED_MANIFEST_PROVENANCE'
}
$raw=@($m.ProtectedBefore | ForEach-Object { [string]$_ })
if ($raw.Count -ne 25) { throw 'BLOCKED_MANIFEST_COUNT_NOT_25' }
$before=@($raw | ForEach-Object { Parse-Entry $_ })
$seen=@{}; $ext=0; $trans=0; $qvw=0
$qvwExpected=@('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')
foreach ($r in $before) {
  if ($seen.ContainsKey($r.Path)) { throw 'BLOCKED_MANIFEST_DUPLICATED_PATH' }
  $seen[$r.Path]=$true
  if (-not $r.Path.StartsWith($repo+'\', [StringComparison]::OrdinalIgnoreCase)) { throw 'BLOCKED_PROTECTED_OUTSIDE_REPO' }
  $rel=$r.Path.Substring($repo.Length+1)
  if ($rel -match '^EXTRACAO\\QVD\\[^\\]+\.qvd$') { $ext++ }
  elseif ($rel -match '^TRANSFORMACAO\\QVD\\[^\\]+\.qvd$') { $trans++ }
  elseif ($qvwExpected -icontains $rel) { $qvw++ }
  else { throw ('BLOCKED_UNEXPECTED_PROTECTED_PATH='+$rel) }
}
if ($ext -ne 10 -or $trans -ne 12 -or $qvw -ne 3) { throw 'BLOCKED_PROTECTED_GROUP_COUNTS' }
foreach ($rel in $qvwExpected) {
  if (-not $seen.ContainsKey((Join-Path $repo $rel))) { throw ('BLOCKED_MISSING_QVW_'+$rel) }
}

# Exactly one read of each manifest-listed file, with before/after file metadata.
$now=@(
  foreach ($r in $before) {
    try {
      $f1=Get-Item -LiteralPath $r.Path -ErrorAction Stop
      if ($f1.PSIsContainer) { throw 'PATH_IS_DIRECTORY' }
      $size1=[long]$f1.Length; $ticks1=$f1.LastWriteTimeUtc.Ticks
      $hash=(Get-FileHash -LiteralPath $r.Path -Algorithm SHA256 -ErrorAction Stop).Hash
      $f2=Get-Item -LiteralPath $r.Path -ErrorAction Stop
      $unstable=($size1 -ne [long]$f2.Length -or $ticks1 -ne $f2.LastWriteTimeUtc.Ticks)
      New-Record $f2.FullName ([long]$f2.Length) $hash '' $unstable
    }
    catch {
      New-Record $r.Path 0 '' 'UNREADABLE' $false
    }
  }
)
$diffs=@(Compare-Records $before $now)
$nowLines=@($now | Where-Object { -not $_.ErrorName } | ForEach-Object {
  '{0}|{1}|{2}' -f $_.Path,$_.Size,$_.Sha
} | Sort-Object)
$strict=(($raw -join [Environment]::NewLine) -ceq ($nowLines -join [Environment]::NewLine))
Write-Output ('FILES_CHECKED='+$now.Count)
Write-Output ('PAIRWISE_ISSUES='+$diffs.Count)
Write-Output ('LEGACY_STRICT_SNAPSHOT_EQUAL='+$strict)
foreach ($d in $diffs) {
  Write-Output ('DIFF_KIND='+$d.Kind+' PATH='+$d.Path)
  Write-Output ('BEFORE_SIZE='+$d.ExpectedSize+' AFTER_SIZE='+$d.NowSize)
  Write-Output ('BEFORE_SHA256='+$d.ExpectedSha+' AFTER_SHA256='+$d.NowSha)
}
if ($diffs.Count -eq 0 -and $strict) {
  Write-Output 'VERDICT=CURRENT_25_MATCH_PREVIOUS_HARD_STOP_UNEXPLAINED'
}
elseif ($diffs.Count -eq 0) {
  Write-Output 'VERDICT=LEGACY_ORDER_OR_FORMAT_DIFFERENCE'
}
else {
  Write-Output 'VERDICT=DIFFERENCE_OBSERVED_NO_AUTOMATIC_REPAIR'
}
