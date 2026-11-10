#requires -Version 5.1
<#
 VIS02 preflight: copies C4 and extracts ONLY 3 approved background images.
 No QlikView/COM, Reload, Save, QVS or QVD operations.
 Executable must be committed; use the exact current HEAD as ExpectedCommit.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$SourceQvw,
  [Parameter(Mandatory=$true)][string]$AssetsZip,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-fA-F]{40}$')][string]$ExpectedCommit
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sourceExpected = '27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13'
$assets = @(
  @{Entry='VIS01/VIS01_fundo_1_producao_1920x1080.png';Name='VIS01_fundo_1_producao_1920x1080.png';Sha='D7EDABF2C8CD92F70217426A17B56912909C662B618A3D1D26699C90A02B7849'},
  @{Entry='VIS01/VIS01_fundo_2_leitos_1920x1080.png';Name='VIS01_fundo_2_leitos_1920x1080.png';Sha='7C8E8BF2A08CCF80E8AE4F40C7E92377A8AB672E61598BFEADAB5D1872A07391'},
  @{Entry='VIS01/VIS01_fundo_3_fluxos_1920x1080.png';Name='VIS01_fundo_3_fluxos_1920x1080.png';Sha='FC6CAA445CC4F23396EFEA24C9D69F01CDAFC91A6477C8A8A4E11D3462EAFB70'}
)
function Hash([string]$p) {
  return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()
}
$workDir=$null
try {
  $repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
  if(-not (Test-Path -LiteralPath $SourceQvw -PathType Leaf)){throw 'SOURCE_MISSING'}
  if(-not (Test-Path -LiteralPath $AssetsZip -PathType Leaf)){throw 'ZIP_MISSING'}
  if(-not (Test-Path -LiteralPath $EvidenceRoot -PathType Container)){throw 'EVIDENCE_ROOT_MUST_EXIST'}
  if([IO.Path]::GetFileName($SourceQvw) -cne 'SAD_MVP_C4_PRESENTATION_TEMP.qvw'){throw 'UNEXPECTED_SOURCE_NAME'}
  $sourceFull=[IO.Path]::GetFullPath($SourceQvw)
  $rootFull=[IO.Path]::GetFullPath($EvidenceRoot)
  $sourceParent=[IO.Path]::GetDirectoryName($sourceFull).TrimEnd('\')+'\'
  $repoParent=$repo.TrimEnd('\')+'\'
  if($rootFull.StartsWith($sourceParent,[StringComparison]::OrdinalIgnoreCase) -or $rootFull.StartsWith($repoParent,[StringComparison]::OrdinalIgnoreCase)){
    throw 'EVIDENCE_ROOT_INSIDE_SOURCE_OR_REPOSITORY'
  }
  $head=([string](& git -C $repo rev-parse HEAD)).Trim()
  if($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit){throw "COMMIT_MISMATCH actual=$head"}
  $status=@(& git -C $repo status --porcelain -- tools/Prepare-SadVis02WorkCopy.ps1)
  if($LASTEXITCODE -ne 0 -or $status.Count -gt 0){throw 'SCRIPT_UNCOMMITTED_OR_DIRTY'}
  $scriptSha=Hash $PSCommandPath
  $sourceBefore=Hash $sourceFull
  if($sourceBefore -cne $sourceExpected){throw "SOURCE_HASH_MISMATCH actual=$sourceBefore"}
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip=[IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($AssetsZip))
  try {
    foreach($a in $assets){
      $entry=$zip.GetEntry($a.Entry)
      if($null -eq $entry -or $entry.Length -le 0 -or $entry.Length -gt 10000000){throw "MISSING_OR_OVERSIZED_ASSET $($a.Entry)"}
    }
    $workDir=Join-Path $rootFull ("VIS02_"+(Get-Date -Format 'yyyyMMdd_HHmmss')+"_"+[guid]::NewGuid().ToString('N'))
    $null=New-Item -ItemType Directory -Path $workDir
    $assetDir=Join-Path $workDir 'assets'
    $null=New-Item -ItemType Directory -Path $assetDir
    $copy=Join-Path $workDir 'SAD_MVP_C4_VIS02_WORK.qvw'
    Copy-Item -LiteralPath $sourceFull -Destination $copy
    $copySha=Hash $copy
    if($copySha -cne $sourceExpected){throw "COPY_HASH_MISMATCH actual=$copySha"}
    $assetEvidence=@()
    foreach($a in $assets){
      $dest=Join-Path $assetDir $a.Name
      $stream=$zip.GetEntry($a.Entry).Open()
      $output=[IO.File]::Open($dest,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
      try {$stream.CopyTo($output)} finally {$output.Dispose();$stream.Dispose()}
      $sha=Hash $dest
      if($sha -cne $a.Sha){throw "ASSET_HASH_MISMATCH $($a.Name)"}
      $assetEvidence+=@{File=$a.Name;Sha256=$sha}
    }
  } finally {$zip.Dispose()}
  $sourceAfter=Hash $sourceFull
  if($sourceAfter -cne $sourceExpected){throw 'SOURCE_CHANGED_DURING_PREFLIGHT'}
  $manifest=[ordered]@{
    Gate='VIS02_PREFLIGHT'
    Verdict='PASS_COPY_AND_ASSET_HASHES_ONLY'
    RepositoryCommit=$head
    ScriptSha256=$scriptSha
    Timestamp=(Get-Date).ToString('o')
    SourceQvw=$sourceFull
    SourceHashBefore=$sourceBefore
    SourceHashAfter=$sourceAfter
    WorkQvw=$copy
    WorkCopyInitialHash=$copySha
    Assets=$assetEvidence
    QlikViewExecuted=$false
    ReloadExecuted=$false
    SaveExecuted=$false
  }
  $manifestPath=Join-Path $workDir 'vis02_preflight_manifest.json'
  $manifest|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $manifestPath -Encoding UTF8
  Write-Output 'VERDICT=PASS_COPY_AND_ASSET_HASHES_ONLY'
  Write-Output 'SOURCE_UNCHANGED=True'
  Write-Output ('WORK_QVW='+$copy)
  Write-Output ('MANIFEST='+$manifestPath)
  Write-Output 'STOP=OPEN_WORK_COPY_IN_QLIKVIEW_FOR_MANUAL_STYLE_ONLY'
} catch {
  Write-Output 'VERDICT=BLOCKED'
  Write-Output ('DETAIL='+$_.Exception.Message)
  if($null -ne $workDir){Write-Output ('INCOMPLETE_WORK_DIR='+$workDir)}
  exit 2
}