#requires -Version 5.1
<#
.SYNOPSIS
  VIS-05 P2 - instala PNG de fundo da folha Leitos Cadastrais Observados.
.DESCRIPTION
  Arquivos exclusivamente na pasta VIS-05. Nao modifica QVW/QVD/QVS.
  Nao usa COM, Reload, Save nem captura de tela automatizada.
  Script versionado: executar do commit informado e registrar evidencia local.
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$ZipPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$source = Join-Path $env:USERPROFILE 'SAD_VIS04_EVIDENCIAS\VIS04_20261110_201240_0d9818e4ab0c\SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw'
$expectedSource = 'BE8CB39B59F92F2F173DB309A60EA5FF373CDF87CBFCBC333F5583A21FF539C6'
$workDir = Join-Path $env:USERPROFILE 'SAD_VIS05_EVIDENCIAS\VIS05_20261112_171721_950990d1'
$work = Join-Path $workDir 'SAD_MVP_VIS05_UX_WORK_TEMP.qvw'
$manifestVis05 = Join-Path $workDir 'vis05_manifest.json'
$target = Join-Path $workDir 'VIS05_ASSETS_P2_LEITOS_R2'
$assetRel = 'assets/vis05_sheet02_leitos_fundo_r2_1920x1080.png'
$expectedAsset = '2FF32A171CA6EA69F5DAD5E56EED1B85EF857DBB1EE03C7D64701747C5A43787'
$expectedZip = '72BD7968842464EC028DDFC777CCED864ABC85C80451E8B05E94DDC0FF25ED3F'

function Hash([string]$path) {
 if(-not(Test-Path -LiteralPath $path -PathType Leaf)) {throw "FILE_MISSING: $path"}
 return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Expect([string]$path, [string]$expected, [string]$label) {
 $actual = Hash $path
 if($actual -cne $expected) {throw "$label HASH_MISMATCH expected=$expected actual=$actual"}
}
function NewJson([string]$path,[object]$value){
 if(Test-Path -LiteralPath $path){throw "NO_OVERWRITE: $path"}
 [IO.File]::WriteAllText(
  $path, (ConvertTo-Json -InputObject $value -Depth 7), (New-Object Text.UTF8Encoding($false))
 )
}

try {
 if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {throw 'WINDOWS_REQUIRED'}
 if(-not(Test-Path -LiteralPath $workDir -PathType Container)) {throw 'VIS05_WORKDIR_MISSING'}
 if(Test-Path -LiteralPath $target) {throw 'TARGET_ALREADY_EXISTS_NO_OVERWRITE'}
 Expect $source $expectedSource 'VIS04_ORIGINAL'
 if(-not(Test-Path -LiteralPath $work -PathType Leaf)){throw 'VIS05_WORK_COPY_MISSING'}
 $workBefore=Hash $work
 if(-not(Test-Path -LiteralPath $manifestVis05 -PathType Leaf)){throw 'VIS05_PREPARE_MANIFEST_MISSING'}
 $visManifest=Get-Content -LiteralPath $manifestVis05 -Raw -Encoding UTF8 | ConvertFrom-Json
 if([string]$visManifest.Gate -cne 'VIS05_SHELL' -or
    [string]$visManifest.Work -cne ([IO.Path]::GetFullPath($work)) -or
    [string]$visManifest.SourceSha -cne $expectedSource) {throw 'VIS05_MANIFEST_PROVENANCE_MISMATCH'}
 Expect $ZipPath $expectedZip 'ASSET_PACKAGE'

 Add-Type -AssemblyName System.IO.Compression
 Add-Type -AssemblyName System.IO.Compression.FileSystem
 $archive=[IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ZipPath).Path)
 try {
   $names=@($archive.Entries | ForEach-Object { $_.FullName })
   $allowed=@($assetRel,'asset-manifest.json','LEIA-ME.md')
   if($names.Count -ne 3 -or @($names | Select-Object -Unique).Count -ne 3){throw 'ZIP_ENTRY_COUNT_INVALID'}
   foreach($n in $names){if($n -cnotin $allowed){throw "ZIP_UNAUTHORIZED_ENTRY: $n"}}
 } finally { $archive.Dispose() }

 $null=New-Item -ItemType Directory -Path $target -ErrorAction Stop
 Expand-Archive -LiteralPath $ZipPath -DestinationPath $target -ErrorAction Stop
 $png=Join-Path $target 'assets\vis05_sheet02_leitos_fundo_r2_1920x1080.png'
 Expect $png $expectedAsset 'LEITOS_BACKGROUND_PNG'
 $am=Get-Content -LiteralPath (Join-Path $target 'asset-manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
 if([string]$am.gate -cne 'SAD_VIS05_P2_ASSETS' -or
    @($am.artifacts).Count -ne 1 -or
    [string]$am.artifacts[0].path -cne $assetRel -or
    ([string]$am.artifacts[0].sha256).ToUpperInvariant() -cne $expectedAsset){
   throw 'ASSET_MANIFEST_MISMATCH'
 }
 Expect $source $expectedSource 'VIS04_AFTER_INSTALL'
 $workAfter=Hash $work
 if($workAfter -cne $workBefore){throw "WORK_CHANGED_DURING_INSTALL before=$workBefore after=$workAfter"}
 $report=Join-Path $workDir ('vis05_p2_leitos_assets_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.json')
 NewJson $report ([ordered]@{
    Gate='VIS05_P2_LEITOS_ASSETS';Stage='FILES_ONLY'
    Created=(Get-Date).ToString('o')
    SourceQvw=$source;SourceSha256=$expectedSource
    WorkQvw=$work;WorkBeforeSha256=$workBefore;WorkAfterSha256=$workAfter
    ZipSha256=$expectedZip;AssetSha256=$expectedAsset;AssetPath=$png
    SourcePreserved=$true;WorkPreserved=$true;QlikCOM=$false
    QvwEdited=$false;ReloadExecuted=$false;ScreenshotCapturedAutomatically=$false
    VisualValidation='PENDING_GUI';ProductionApproved=$false
    Verdict='PASS_FILES_INSTALLED_ONLY'
 })
 Write-Output 'VERDICT=PASS_FILES_INSTALLED_ONLY'
 Write-Output ('ASSET_PNG='+$png)
 Write-Output ('SOURCE_SHA256='+$expectedSource)
 Write-Output ('WORK_SHA256='+$workAfter)
 Write-Output ('REPORT='+$report)
 Write-Output 'STOP=APPLY_BACKGROUND_ONLY_IN_VIS05_GUI_SEND_MANUAL_PRINT'
} catch {
 Write-Output 'VERDICT=BLOCKED'
 Write-Output ('DETAIL='+$_.Exception.Message)
 exit 2
}
