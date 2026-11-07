#requires -Version 5.1
<#
  SAD MVP F04-U1: make ONE isolated copy of the manually guarded F03 TEMP QVW.
  No QlikView automation, no Reload, no QVD reads/writes, no source edits.
  The owner will set M2-02 (CH05) properties only in the new TEMP copy.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ExpectedCommit,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][switch]$Prepare
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not $Prepare){throw 'Explicit -Prepare required'}
if($ExpectedCommit -notmatch '^[0-9a-fA-F]{40}$'){throw 'ExpectedCommit must be a 40-character SHA'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows PowerShell required'}
$repo=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))
$evidence=[IO.Path]::GetFullPath($EvidenceRoot).TrimEnd([char[]]@('\','/'))
function InPath([string]$child,[string]$parent){
  return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
    $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
if((InPath $evidence $repo) -or (InPath $repo $evidence) -or
  (InPath $evidence ([IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]@('\','/'))))){
  throw 'EvidenceRoot must be outside repository and Windows TEMP'
}
if(-not(Test-Path -LiteralPath $evidence -PathType Container)){throw 'EvidenceRoot missing'}
$head=(& git -C $repo rev-parse HEAD 2>$null | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit.ToLowerInvariant()){throw 'HEAD differs from ExpectedCommit'}
$branch=(& git -C $repo branch --show-current 2>$null | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $branch -cne 'proposal/sad-mvp-rebaseline-2026-11-07'){throw 'Wrong branch'}
$dirty=@(& git -C $repo status --porcelain 2>$null)
if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw 'Working tree not clean'}
$self=Join-Path $repo 'tools/New-SadMvpF04TemporalGuardCopy.ps1'
if(-not(Test-Path -LiteralPath $self -PathType Leaf)){throw 'F04 copy runner missing'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- 'tools/New-SadMvpF04TemporalGuardCopy.ps1' 2>$null)
if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1){throw 'Copy runner must be tracked'}
$source=Join-Path $evidence 'SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8\SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw'
if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw 'Approved F03 TEMP source missing; no fallback to unguarded M2'}
$sourceShaBefore=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$targetDir=Join-Path $evidence ('SAD_F04_TEMPORAL_GUARD_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -Path $targetDir -ItemType Directory -ErrorAction Stop
$target=Join-Path $targetDir 'SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw'
Copy-Item -LiteralPath $source -Destination $target -ErrorAction Stop
$targetSha=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
$sourceShaAfter=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if($sourceShaBefore -cne $sourceShaAfter -or $sourceShaBefore -cne $targetSha){
  throw 'STOP: source hash drift or target copy mismatch'
}
$receipt=@(
  "GIT_HEAD=$head",
  "SOURCE_QVW=$source",
  "SOURCE_SHA256_BEFORE=$sourceShaBefore",
  "SOURCE_SHA256_AFTER=$sourceShaAfter",
  "TARGET_QVW=$target",
  "TARGET_SHA256_INITIAL=$targetSha",
  'F03_GUARD_IN_SOURCE=GUI_REPORTED_NOT_INDEPENDENTLY_READ_FROM_BINARY',
  'SOURCE_QVW_UNCHANGED=True',
  'NO_QVD_READS_OR_WRITES=True',
  'NO_QVW_RELOAD=True',
  'M2_02_TEMPORAL_GUARD=NOT_CONFIGURED',
  'PRODUCTION_APPROVED=False'
)
[IO.File]::WriteAllLines((Join-Path $targetDir 'prepare_receipt.txt'),$receipt,[Text.Encoding]::UTF8)
Write-Output "GIT_HEAD=$head"
Write-Output "SOURCE_SHA256=$sourceShaBefore"
Write-Output "TARGET_QVW=$target"
Write-Output "TARGET_SHA256_INITIAL=$targetSha"
Write-Output 'SOURCE_QVW_UNCHANGED=True'
Write-Output 'NO_QVD_READS_OR_WRITES=True NO_QVW_RELOAD=True'
Write-Output 'F04_UI_TEMP_COPY=PREPARED_GUARD_NOT_CONFIGURED'
