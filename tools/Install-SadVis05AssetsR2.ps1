#requires -Version 5.1
<#
.SYNOPSIS
  VIS-05 P1 R2: instalar fundo revisado de Producao Hospitalar em pasta privada.
.DESCRIPTION
  Sem COM, Reload, Save QVW, alteracao de folha, screenshot, dados ou QVS.
  Exige ZIP pinado e protege fonte VIS-04 e copia VIS-05 por SHA-256.
  Usar apenas revisao versionada deste script no GitHub.
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$ZipPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$source=Join-Path $env:USERPROFILE 'SAD_VIS04_EVIDENCIAS\VIS04_20261110_201240_0d9818e4ab0c\SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw'
$workDir=Join-Path $env:USERPROFILE 'SAD_VIS05_EVIDENCIAS\VIS05_20261112_171721_950990d1'
$work=Join-Path $workDir 'SAD_MVP_VIS05_UX_WORK_TEMP.qvw'
$baseline='BE8CB39B59F92F2F173DB309A60EA5FF373CDF87CBFCBC333F5583A21FF539C6'
$zipSha='6922BDF002E64207AF2BB50E73A0042DF4C1CAFF94CC91871117C442E5DA19A2'
$assetRel='assets/vis05_sheet01_producao_fundo_r2_1920x1080.png'
$assetSha='C2D8238D62B2FC16F013EFCDDCC14A1AFF0095B27D603057D43A5E96973EA282'
$target=Join-Path $workDir 'VIS05_ASSETS_P1_R2'
function Sha([string]$p){
 if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "FILE_MISSING: $p"}
 return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Expect([string]$p,[string]$hash,[string]$label){
 $actual=Sha $p
 if($actual -cne $hash){throw "$label HASH_MISMATCH expected=$hash actual=$actual"}
}
function JsonNew([string]$p,[object]$o){
 if(Test-Path -LiteralPath $p){throw "NO_OVERWRITE: $p"}
 [IO.File]::WriteAllText($p,(ConvertTo-Json -InputObject $o -Depth 6),(New-Object Text.UTF8Encoding($false)))
}
try{
 if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'WINDOWS_REQUIRED'}
 if(-not(Test-Path -LiteralPath $workDir -PathType Container)){throw 'VIS05_WORK_DIR_NOT_FOUND'}
 if(Test-Path -LiteralPath $target){throw 'ASSET_TARGET_ALREADY_EXISTS_NO_OVERWRITE'}
 $null=Expect $source $baseline 'VIS04_PROTECTED'
 $null=Expect $work $baseline 'VIS05_WORK_BASELINE'
 $null=Expect $ZipPath $zipSha 'ZIP_PACKAGE'
 Add-Type -AssemblyName System.IO.Compression
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $arch=[IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ZipPath).Path)
 try{
  $names=@($arch.Entries|ForEach-Object{$_.FullName})
  $allowed=@($assetRel,'asset-manifest.json','LEIA-ME.md')
  if($names.Count -ne $allowed.Count){throw 'ZIP_ENTRY_COUNT_UNEXPECTED'}
  foreach($entry in $names){
   if($entry -cnotin $allowed){throw "ZIP_UNAUTHORIZED_ENTRY: $entry"}
  }
 }finally{$arch.Dispose()}
 $null=New-Item -ItemType Directory -Path $target -ErrorAction Stop
 Expand-Archive -LiteralPath $ZipPath -DestinationPath $target -ErrorAction Stop
 $asset=Join-Path $target ($assetRel.Replace('/','\'))
 Expect $asset $assetSha 'PNG_ASSET'
 $manifestFile=Join-Path $target 'asset-manifest.json'
 $manifest=Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8|ConvertFrom-Json
 if($manifest.gate -cne 'SAD_VIS05_P1_ASSETS_R2' -or
    $manifest.artifacts.Count -ne 1 -or
    [string]$manifest.artifacts[0].path -cne $assetRel -or
    ([string]$manifest.artifacts[0].sha256).ToUpperInvariant() -cne $assetSha){
    throw 'ASSET_MANIFEST_MISMATCH'
 }
 Expect $source $baseline 'VIS04_PROTECTED_AFTER_INSTALL'
 Expect $work $baseline 'VIS05_WORK_AFTER_INSTALL'
 $report=Join-Path $workDir ('vis05_asset_r2_install_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'.json')
 JsonNew $report ([ordered]@{
   Gate='VIS05_P1_R2_STATIC_ASSETS';Stage='INSTALLED_FILES_ONLY'
   SourceSha256=$baseline;WorkSha256=$baseline;ZipSha256=$zipSha
   AssetPath=$asset;AssetSha256=$assetSha
   QvwModified=$false;QlikComExecuted=$false;ReloadExecuted=$false
   VisualApproval='PENDING_GUI';Verdict='PASS_ASSET_INSTALL_ONLY'
 })
 Write-Output 'VERDICT=PASS_ASSET_INSTALL_ONLY'
 Write-Output ('ASSET_PNG='+$asset)
 Write-Output ('ASSET_SHA256='+$assetSha)
 Write-Output ('REPORT='+$report)
 Write-Output 'VIS04_SOURCE_UNCHANGED=True'
 Write-Output 'VIS05_WORK_UNCHANGED=True'
 Write-Output 'STOP=APPLY_BACKGROUND_GUI_IN_WORK_COPY_ONLY_NO_SAVE_UNTIL_VISUAL_REVIEW'
}catch{
 Write-Output 'VERDICT=BLOCKED'
 Write-Output ('DETAIL='+$_.Exception.Message)
 exit 2
}
