#requires -Version 5.1
<#
  F03 localized UI guard setup, NO Qlik/COM/Reload.
  Makes one protected copy of the existing successful 9-object TEMP QVW
  for manual configuration and screenshot validation in QlikView 12.
  No QVD access or mutation; no change to source/canonical QVW.
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
if($ExpectedCommit -notmatch '^[a-fA-F0-9]{40}$'){throw 'ExpectedCommit must be a full 40-character SHA'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows required'}
$repo=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')
$evidence=[IO.Path]::GetFullPath($EvidenceRoot).TrimEnd('\','/')
function IsUnder([string]$p,[string]$parent) {
  return $p.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
    $p.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
if((IsUnder $evidence $repo) -or (IsUnder $repo $evidence) -or
   (IsUnder $evidence ([IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')))) {
  throw 'EvidenceRoot must be outside repo and Windows TEMP'
}
if(-not (Test-Path -LiteralPath $evidence -PathType Container)){throw 'EvidenceRoot not found'}
$head=(& git -C $repo rev-parse HEAD 2>$null | Out-String).Trim()
$branch=(& git -C $repo branch --show-current 2>$null | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or
  $head -cne $ExpectedCommit.ToLowerInvariant() -or
  $branch -cne 'proposal/sad-mvp-rebaseline-2026-11-07'){throw 'Wrong branch or HEAD'}
$dirty=@(& git -C $repo status --porcelain 2>$null)
if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw 'Working tree not clean'}
$self='tools/New-SadMvpF03UiGuardCopy.ps1'
$tracked=@(& git -C $repo ls-files --error-unmatch -- $self 2>$null)
if($tracked.Count -ne 1){throw 'Copy runner not tracked in this commit'}
$runFolder='SAD_M2_MVP_TEMP_0f6b3b19ce714295ba80e5c27856c08e'
$sourceDir=Join-Path $evidence $runFolder
$source=Join-Path $sourceDir 'SAD_MVP_THREE_SHEETS_CANDIDATE.qvw'
$manifest=Join-Path $sourceDir 'm2_objects_manifest.csv'
if(-not (Test-Path -LiteralPath $source -PathType Leaf)){throw 'Successful M2 candidate QVW missing'}
if(-not (Test-Path -LiteralPath $manifest -PathType Leaf)){throw 'Nine-view manifest missing'}
$rows=@(Import-Csv -LiteralPath $manifest)
$ids=@('M1-01','M1-02','M1-03','M2-01','M2-02','M2-03','M3-01','M3-02','M3-03')
if($rows.Count -ne 9 -or (@($rows|Select-Object -ExpandProperty ViewId -Unique).Count -ne 9)){throw 'Unexpected MVP object count'}
foreach($id in $ids){if(@($rows|Where-Object{$_.ViewId -ceq $id}).Count -ne 1){throw "Missing or duplicate manifest view: $id"}}
$lt1=@($rows|Where-Object{$_.ViewId -ceq 'M2-01'})[0]
$lt2=@($rows|Where-Object{$_.ViewId -ceq 'M2-02'})[0]
if($lt1.Type -cne 'Line' -or $lt1.Dimensions -cne 'PERIODO_COMPETENCIA' -or
   $lt1.Expressions -cne 'Sum(QTD_LEITOS_SUS) | Sum(QTD_LEITOS_EXISTENTES)' -or
   $lt2.Type -cne 'Bar' -or $lt2.Dimensions -cne 'SERV_COD_DATASUS_6' -or
   $lt2.Expressions -cne "Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)") {
  throw 'CNES/LT M2-01 or M2-02 manifest contract mismatch'
}
$sourceSha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$manifestSha=(Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash
$newDir=Join-Path $evidence ('SAD_F03_UI_GUARD_TEMP_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $newDir -ErrorAction Stop
$target=Join-Path $newDir 'SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw'
Copy-Item -LiteralPath $source -Destination $target -ErrorAction Stop
$targetSha=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
$sourceShaAfter=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if($targetSha -cne $sourceSha -or $sourceShaAfter -cne $sourceSha){
  throw 'CRITICAL: source/copy hash mismatch'
}
$receipt=@(
  "GIT_HEAD=$head",
  "GIT_BRANCH=$branch",
  "SOURCE_QVW=$source",
  "SOURCE_SHA256=$sourceSha",
  "SOURCE_MANIFEST_SHA256=$manifestSha",
  "TARGET_QVW=$target",
  "TARGET_SHA256_INITIAL=$targetSha",
  'SOURCE_QVW_UNCHANGED=True',
  'NO_QVD_READS_OR_WRITES=True',
  'NO_QVW_RELOAD=True',
  'GUARD_CONFIGURED=False',
  'GUARD_GUI_VERIFIED=False',
  'PRODUCTION_APPROVED=False'
)
[IO.File]::WriteAllLines((Join-Path $newDir 'prepare_receipt.txt'),$receipt,[Text.Encoding]::UTF8)
Write-Output "GIT_HEAD=$head"
Write-Output "SOURCE_SHA256=$sourceSha"
Write-Output "SOURCE_MANIFEST_SHA256=$manifestSha"
Write-Output "TARGET_QVW=$target"
Write-Output "TARGET_SHA256_INITIAL=$targetSha"
Write-Output 'SOURCE_QVW_UNCHANGED=True'
Write-Output 'NO_QVD_READS_OR_WRITES=True NO_QVW_RELOAD=True'
Write-Output 'F03_UI_GUARD=TEMP_COPY_PREPARED_NOT_CONFIGURED'
