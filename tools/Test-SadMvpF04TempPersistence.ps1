#requires -Version 5.1
<#
  SAD MVP F04-U1 persistence verification, read-only.
  BEFORE: after QlikView has closed the saved F04 TEMP QVW, record SHA-256.
  AFTER: after reopening the same file, observing GUI states and closing WITHOUT SAVE,
         prove the QVW bytes stayed unchanged.
  No COM, reload, copy, save, new data, QVD or canonical QVW writes.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ExpectedCommit,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][ValidateSet('Before','After')][string]$Stage,
  [string]$BaselineSha256
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Windows required' }
if ($ExpectedCommit -notmatch '^[a-fA-F0-9]{40}$') { throw 'ExpectedCommit must be full 40-character SHA' }
if ($Stage -ceq 'After' -and $BaselineSha256 -notmatch '^[a-fA-F0-9]{64}$') {
  throw 'After requires -BaselineSha256 from the Before execution'
}
function NormalizePath([string]$path) {
  return [IO.Path]::GetFullPath($path).TrimEnd([char[]]@('\','/'))
}
function IsWithin([string]$path, [string]$parent) {
  return $path.Equals($parent, [StringComparison]::OrdinalIgnoreCase) -or
    $path.StartsWith($parent + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}
$root = NormalizePath $Root
$evidence = NormalizePath $EvidenceRoot
$temp = NormalizePath ([IO.Path]::GetTempPath())
if ((IsWithin $evidence $root) -or (IsWithin $root $evidence) -or (IsWithin $evidence $temp)) {
  throw 'EvidenceRoot must be outside repository and Windows TEMP'
}
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw 'Root directory missing' }
if (-not (Test-Path -LiteralPath $evidence -PathType Container)) { throw 'EvidenceRoot directory missing' }
$head = (& git -C $root rev-parse HEAD 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit.ToLowerInvariant()) {
  throw 'Wrong HEAD; do not use evidence from a different commit'
}
$branch = (& git -C $root branch --show-current 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne 'proposal/sad-mvp-rebaseline-2026-11-07') {
  throw 'Wrong branch'
}
$dirty = @(& git -C $root status --porcelain 2>$null)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) { throw 'Worktree not clean' }
$self = 'tools/Test-SadMvpF04TempPersistence.ps1'
$tracked = @(& git -C $root ls-files --error-unmatch -- $self 2>$null)
if ($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1) { throw 'Versioned verifier missing' }
$relativeQvw = 'SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1\SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw'
$qvw = Join-Path $evidence $relativeQvw
if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {
  throw 'Exact F04 TEMP QVW missing; do not substitute a different file'
}
$sha = (Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
Write-Output "GIT_HEAD=$head"
Write-Output "STAGE=$Stage"
Write-Output "F04_TEMP_QVW=$qvw"
Write-Output "F04_TEMP_QVW_SHA256=$sha"
Write-Output 'NO_QVW_QVD_WRITE=True'
Write-Output 'NO_RELOAD_OR_COM=True'
if ($Stage -ceq 'Before') {
  Write-Output 'PERSISTENCE_VERDICT=BASELINE_CAPTURED_REOPEN_PENDING'
} else {
  if ($sha -cne $BaselineSha256.ToUpperInvariant()) {
    Write-Output 'PERSISTENCE_VERDICT=BLOCKED_QVW_HASH_CHANGED'
    throw 'STOP: QVW changed between Before and After; preserve original evidence'
  }
  Write-Output 'PERSISTENCE_VERDICT=HASH_UNCHANGED_GUI_REVIEW_PENDING'
}
