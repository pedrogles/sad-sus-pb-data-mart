#requires -Version 5.1
<#
SAD VIS-05: copia QVW protegida, capturas de tela e pacote de evidencias.
Sem COM, Reload, Save automatizado, edicao de QVW/QVD/QVS ou envio automatico.
Execucao local Windows. Capturas exigem sessao grafica e navegacao manual entre folhas.
#>
[CmdletBinding()]
param(
 [ValidateSet('Prepare','CaptureAll','CaptureHover','Verify','Package')][string]$Mode='Prepare',
 [string]$ManifestPath,
 [string]$HoverLabel,
 [ValidateRange(4,30)][int]$DelaySeconds=7,
 [switch]$NoLaunch
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$source=Join-Path $env:USERPROFILE 'SAD_VIS04_EVIDENCIAS\VIS04_20261110_201240_0d9818e4ab0c\SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw'
$expected='BE8CB39B59F92F2F173DB309A60EA5FF373CDF87CBFCBC333F5583A21FF539C6'
$root=Join-Path $env:USERPROFILE 'SAD_VIS05_EVIDENCIAS'
$workName='SAD_MVP_VIS05_UX_WORK_TEMP.qvw'
function Full([string]$p){[IO.Path]::GetFullPath($p).TrimEnd([char[]]@('\','/'))}
function Hash([string]$p){
 if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "FILE_MISSING $p"}
 (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Check([string]$p,[string]$sha,[string]$label){
 $h=Hash $p
 if($h -cne $sha){throw "$label HASH_MISMATCH actual=$h expected=$sha"}
}
function Under([string]$p,[string]$dir){
 $p=Full $p;$dir=Full $dir
 $p.Equals($dir,[StringComparison]::OrdinalIgnoreCase) -or
 $p.StartsWith(($dir+'\'),[StringComparison]::OrdinalIgnoreCase)
}
function Fresh([string]$prefix,[string]$ext){
 $prefix+'_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)+$ext
}
function JsonNew([string]$p,$o){
 if(Test-Path -LiteralPath $p){throw "NO_OVERWRITE $p"}
 [IO.File]::WriteAllText($p,(ConvertTo-Json -InputObject $o -Depth 8),(New-Object Text.UTF8Encoding($false)))
}
function OpenManifest {
 if(-not $ManifestPath){throw 'MANIFEST_REQUIRED'}
 $mf=Full $ManifestPath
 $m=Get-Content -LiteralPath $mf -Raw -Encoding UTF8|ConvertFrom-Json
 if($m.Gate -cne 'VIS05_SHELL' -or $m.Stage -cne 'PREPARED_COPY_ONLY'){throw 'INVALID_MANIFEST'}
 if((Full ([string]$m.Source)) -cne (Full $source) -or [string]$m.SourceSha -cne $expected){throw 'MANIFEST_SOURCE_MISMATCH'}
 if((Full ([string]$m.Script)) -cne (Full $PSCommandPath) -or [string]$m.ScriptSha -cne (Hash $PSCommandPath)){throw 'SCRIPT_VERSION_CHANGED'}
 $work=Full ([string]$m.Work)
 if(-not(Under $work $root) -or [IO.Path]::GetFileName($work) -cne $workName -or
    (Full ([IO.Path]::GetDirectoryName($mf))) -cne (Full ([IO.Path]::GetDirectoryName($work)))){throw 'INVALID_WORK_PATH'}
 Check $source $expected 'SOURCE_PROTECTION'
 if(-not(Test-Path -LiteralPath $work -PathType Leaf)){throw 'WORK_MISSING'}
 $m
}
function Screenshot([string]$dir,[string]$label){
 if(-not('Vis05Win' -as [type])){
 Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class Vis05Win {
 [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]
 private static extern int GetWindowText(IntPtr h, StringBuilder b,int len);
 public static string Title() {
  IntPtr w=GetForegroundWindow(); StringBuilder b=new StringBuilder(2048);
  if(w==IntPtr.Zero)return "";GetWindowText(w,b,b.Capacity);return b.ToString();
 }
}
'@ -ErrorAction Stop
 }
 Write-Output "SELECT_IN_QLIKVIEW=$label DELAY=$DelaySeconds"
 Start-Sleep -Seconds $DelaySeconds
 $t=[Vis05Win]::Title()
 if($t.IndexOf($workName,[StringComparison]::OrdinalIgnoreCase) -lt 0){throw "WRONG_FOREGROUND_WINDOW $t"}
 if($t -match '(?i)\.qvw\s*\*'){throw 'UNSAVED_QVW_CLOSE_AND_REOPEN_COPY'}
 Add-Type -AssemblyName System.Drawing
 Add-Type -AssemblyName System.Windows.Forms
 $screen=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
 if($screen.Width -lt 800 -or $screen.Height -lt 600){throw 'SCREEN_TOO_SMALL'}
 $png=Join-Path $dir (Fresh $label '.png')
 $bmp=New-Object Drawing.Bitmap($screen.Width,$screen.Height)
 $g=[Drawing.Graphics]::FromImage($bmp)
 try{
  $g.CopyFromScreen($screen.Left,$screen.Top,0,0,(New-Object Drawing.Size($screen.Width,$screen.Height)))
  $bmp.Save($png,[Drawing.Imaging.ImageFormat]::Png)
 }finally{$g.Dispose();$bmp.Dispose()}
 if((Get-Item -LiteralPath $png).Length -lt 10000){throw 'CAPTURE_TOO_SMALL'}
 Write-Output ('PNG='+$png)
 Write-Output ('PNG_SHA256='+(Hash $png))
}
try{
 if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'WINDOWS_REQUIRED'}
 $scriptSha=Hash $PSCommandPath
 if($Mode -eq 'Prepare'){
  if($ManifestPath -or $HoverLabel){throw 'UNEXPECTED_PREPARE_ARGUMENT'}
  if(Get-Process Qv -ErrorAction SilentlyContinue){throw 'CLOSE_QLIKVIEW_WITHOUT_SAVING_FIRST'}
  if((Under $root ([IO.Path]::GetDirectoryName($source))) -or (Under $source $root)){throw 'UNSAFE_FOLDER'}
  Check $source $expected 'VIS04_SOURCE'
  if(-not(Test-Path -LiteralPath $root -PathType Container)){$null=New-Item -ItemType Directory -Path $root}
  $dir=Join-Path $root (Fresh 'VIS05' '')
  $null=New-Item -ItemType Directory -Path $dir
  $work=Join-Path $dir $workName
  [IO.File]::Copy($source,$work,$false)
  Check $work $expected 'VIS05_COPY'
  Check $source $expected 'VIS04_AFTER_COPY'
  $mf=Join-Path $dir 'vis05_manifest.json'
  JsonNew $mf ([ordered]@{
   Gate='VIS05_SHELL';Stage='PREPARED_COPY_ONLY';Created=(Get-Date).ToString('o')
   Script=(Full $PSCommandPath);ScriptSha=$scriptSha
   Source=(Full $source);SourceSha=$expected
   Work=(Full $work);WorkInitialSha=$expected
   COMExecuted=$false;ReloadExecuted=$false;ProductionApproved=$false
  })
  Write-Output 'VERDICT=PASS_COPY_HASHES_ONLY'
  Write-Output ('MANIFEST='+$mf)
  Write-Output ('WORK_QVW='+$work)
  Write-Output ('SCRIPT_SHA256='+$scriptSha)
  if(-not $NoLaunch){Invoke-Item -LiteralPath $work;Write-Output 'OPEN_REQUESTED=WORK_COPY_ONLY'}
 }else{
  if($NoLaunch){throw 'NOLAUNCH_ONLY_FOR_PREPARE'}
  $m=OpenManifest
  $dir=Full ([IO.Path]::GetDirectoryName([string]$m.Work))
  if($Mode -in @('CaptureAll','CaptureHover')){
   $captures=Join-Path $dir 'capturas'
   if(-not(Test-Path -LiteralPath $captures -PathType Container)){$null=New-Item -ItemType Directory -Path $captures}
   if($Mode -eq 'CaptureAll'){
    foreach($s in @(
     @{Id='sheet01_producao';Name='Producao Hospitalar'},
     @{Id='sheet02_leitos';Name='Leitos Cadastrais Observados'},
     @{Id='sheet03_fluxos';Name='Fluxos e Contexto Territorial'}
    )){
     $null=Read-Host ("Abra '"+$s.Name+"' na copia, volte ao terminal e pressione Enter")
     Screenshot $captures $s.Id
    }
    Write-Output 'VERDICT=THREE_CAPTURES_COLLECTED_UNREVIEWED'
   }else{
    if($HoverLabel -cnotmatch '^[A-Za-z0-9_-]{1,40}$'){throw 'HOVER_LABEL_REQUIRED'}
    $null=Read-Host 'Posicione o mouse no hover desejado apos pressionar Enter'
    Screenshot $captures ('hover_'+$HoverLabel)
    Write-Output 'VERDICT=HOVER_CAPTURED_UNREVIEWED'
   }
  }elseif($Mode -in @('Verify','Package')){
   $workHash=Hash ([string]$m.Work)
   $capturesDir=Join-Path $dir 'capturas'
   $shots=@(Get-ChildItem -LiteralPath $capturesDir -Filter '*.png' -File -ErrorAction SilentlyContinue)
   $items=@($shots|ForEach-Object{[ordered]@{File=$_.Name;Bytes=$_.Length;Sha256=(Hash $_.FullName)}})
   $r=Join-Path $dir (Fresh 'vis05_verify' '.json')
   JsonNew $r ([ordered]@{
    Gate='VIS05_SHELL';Created=(Get-Date).ToString('o')
    SourcePreserved=$true;WorkSha256=$workHash
    WorkChanged=($workHash -cne $expected);ScreenshotCount=$shots.Count;Screenshots=$items
    GuiContent='NOT_REVIEWED';ReopenPersistence='NOT_AUDITED';Verdict='PASS_HASH_PROVENANCE_ONLY'
   })
   Write-Output 'VERDICT=PASS_HASH_PROVENANCE_ONLY'
   Write-Output 'SOURCE_UNCHANGED=True'
   Write-Output ('WORK_SHA256='+$workHash)
   Write-Output ('REPORT='+$r)
   if($Mode -eq 'Package'){
    foreach($p in @('sheet01_producao_*.png','sheet02_leitos_*.png','sheet03_fluxos_*.png')){
     if(@(Get-ChildItem -LiteralPath $capturesDir -File -Filter $p -ErrorAction SilentlyContinue).Count -lt 1){throw "MISSING_CAPTURE $p"}
    }
    $files=@(Get-ChildItem -LiteralPath $dir -Filter '*.json' -File)+$shots
    $zip=Join-Path $dir (Fresh 'VIS05_EVIDENCIAS_SEM_QVW' '.zip')
    Compress-Archive -LiteralPath @($files|ForEach-Object{$_.FullName}) -DestinationPath $zip -CompressionLevel Optimal
    if((Get-Item -LiteralPath $zip).Length -lt 10000){throw 'ZIP_TOO_SMALL'}
    Write-Output ('ZIP_TO_UPLOAD='+$zip)
    Write-Output ('ZIP_SHA256='+(Hash $zip))
    Write-Output 'QVW_INCLUDED=False'
   }
   Write-Output 'STOP=INDEPENDENT_VISUAL_REVIEW_REQUIRED'
  }
 }
}catch{
 Write-Output 'VERDICT=BLOCKED'
 Write-Output ('DETAIL='+$_.Exception.Message)
 exit 2
}