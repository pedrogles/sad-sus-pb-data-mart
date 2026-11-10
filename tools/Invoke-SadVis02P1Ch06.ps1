#requires -Version 5.1
<#
.SYNOPSIS
  VIS-02-P1 CH06: prepara copia QVW, abre para edicao GUI e verifica hashes/captura.
.DESCRIPTION
  Sem COM, Reload, Save automatizado, QVS ou QVD. O ajuste do grafico CH06
  permanece GUI manual ate existir writer verificado para a propriedade.
  Executar APENAS a versao commitada no PR #233; evidencias fora do repo.
.EXAMPLE
  powershell.exe -NoProfile -File .\Invoke-SadVis02P1Ch06.ps1 -Mode Prepare
.EXAMPLE
  powershell.exe -NoProfile -File .\Invoke-SadVis02P1Ch06.ps1 -Mode Verify -ManifestPath '...\vis02_p1_manifest.json' -Capture
#>
[CmdletBinding()]
param(
  [ValidateSet('Prepare','Verify')][string]$Mode = 'Prepare',
  [string]$ManifestPath,
  [string]$SourceQvw = 'C:\Users\pedro\SAD_VIS02_EVIDENCIAS\VIS02_20261109_230246_40a7da274f784973ab11175e4387a736\SAD_MVP_C4_VIS02_WORK.qvw',
  [string]$ProtectedC4 = 'C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw',
  [string]$EvidenceRoot = "$env:USERPROFILE\SAD_VIS02_P1_EVIDENCIAS",
  [switch]$NoLaunch,
  [switch]$Capture,
  [ValidateRange(2,30)][int]$CaptureDelaySeconds = 6
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedVis02 = 'BA0A7DDCF3F064D3EDC38AD5B0F4D7A79A00CEA0841234D21C0EA4D127C8C704'
$expectedC4 = '27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13'
$workName = 'SAD_MVP_CH06_LABEL_FIX_TEMP.qvw'
$scriptSha = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToUpperInvariant()

function Sha([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {throw "FILE_MISSING: $Path"}
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Full([string]$Path) {
  return [IO.Path]::GetFullPath($Path).TrimEnd('\','/')
}
function IsInside([string]$Path,[string]$Folder) {
  $a=Full $Path
  $b=Full $Folder
  return ($a.Equals($b,[StringComparison]::OrdinalIgnoreCase) -or
    $a.StartsWith(($b+'\'),[StringComparison]::OrdinalIgnoreCase))
}
function ExpectHash([string]$Path,[string]$Expected,[string]$Code) {
  $got=Sha $Path
  if ($got -cne $Expected) {throw "$Code expected=$Expected actual=$got path=$Path"}
  return $got
}
function WriteJsonNew([object]$Data,[string]$Path) {
  if (Test-Path -LiteralPath $Path) {throw "REFUSE_OVERWRITE $Path"}
  $json=$Data | ConvertTo-Json -Depth 8
  [IO.File]::WriteAllText($Path,$json,[Text.UTF8Encoding]::new($false))
}
function CaptureForeground([string]$Folder,[string]$ExpectedFile,[int]$DelaySeconds) {
  if (-not ('SadVisP1Foreground' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class SadVisP1Foreground {
    [StructLayout(LayoutKind.Sequential)]
    private struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder str, int maxCount);
    [DllImport("user32.dll")] private static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
    public static bool Describe(out string title, out int x, out int y, out int w, out int h) {
        title = ""; x=0; y=0; w=0; h=0;
        IntPtr handle=GetForegroundWindow();
        if (handle == IntPtr.Zero) return false;
        StringBuilder sb=new StringBuilder(2048);
        GetWindowText(handle,sb,sb.Capacity);
        RECT r;
        if (!GetWindowRect(handle,out r)) return false;
        title=sb.ToString(); x=r.Left; y=r.Top; w=r.Right-r.Left; h=r.Bottom-r.Top;
        return w>0 && h>0;
    }
}
'@ -ErrorAction Stop
  }
  Write-Host ("FOCUS_QLIKVIEW_NOW seconds="+$DelaySeconds)
  Start-Sleep -Seconds $DelaySeconds
  $title='';$x=0;$y=0;$w=0;$h=0
  $valid=[SadVisP1Foreground]::Describe([ref]$title,[ref]$x,[ref]$y,[ref]$w,[ref]$h)
  if (-not $valid -or $title.IndexOf($ExpectedFile,[StringComparison]::OrdinalIgnoreCase) -lt 0) {
    throw "WRONG_FOREGROUND_WINDOW title=$title"
  }
  if ($title -match '\.qvw\*') {throw 'WINDOW_HAS_UNSAVED_ASTERISK_CLOSE_AND_REOPEN_COPY'}
  if ($w -lt 700 -or $h -lt 500 -or $w -gt 8000 -or $h -gt 8000) {
    throw "UNEXPECTED_WINDOW_SIZE width=$w height=$h"
  }
  Add-Type -AssemblyName System.Drawing
  $png=Join-Path $Folder ("ch06_post_reopen_"+(Get-Date -Format 'yyyyMMdd_HHmmss')+"_"+[guid]::NewGuid().ToString('N').Substring(0,8)+'.png')
  $bmp=New-Object System.Drawing.Bitmap($w,$h)
  $g=[System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.CopyFromScreen($x,$y,0,0,[System.Drawing.Size]::new($w,$h))
    $bmp.Save($png,[System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $g.Dispose()
    $bmp.Dispose()
  }
  if ((Get-Item -LiteralPath $png).Length -lt 10000) {
    throw 'SCREENSHOT_TOO_SMALL'
  }
  return @{ Path=$png; Sha256=(Sha $png); WindowTitle=$title; Width=$w; Height=$h }
}

try {
  if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'WINDOWS_REQUIRED'
  }
  if ($Mode -eq 'Prepare') {
    if ($Capture) {throw 'CAPTURE_ONLY_WITH_VERIFY'}
    if (-not [string]::IsNullOrWhiteSpace($ManifestPath)) {throw 'MANIFEST_ONLY_WITH_VERIFY'}
    $source=Full $SourceQvw
    $protected=Full $ProtectedC4
    $root=Full $EvidenceRoot
    if ([IO.Path]::GetFileName($source) -cne 'SAD_MVP_C4_VIS02_WORK.qvw') {throw 'SOURCE_NAME_MISMATCH'}
    if ([IO.Path]::GetFileName($protected) -cne 'SAD_MVP_C4_PRESENTATION_TEMP.qvw') {throw 'PROTECTED_NAME_MISMATCH'}
    if ($source -ieq $protected) {throw 'SOURCE_IS_PROTECTED'}
    if (IsInside $root ([IO.Path]::GetDirectoryName($source))) {throw 'EVIDENCE_ROOT_INSIDE_VIS02_SOURCE'}
    if (IsInside $root ([IO.Path]::GetDirectoryName($protected))) {throw 'EVIDENCE_ROOT_INSIDE_C4_SOURCE'}
    if ((Get-Process -Name 'Qv' -ErrorAction SilentlyContinue)) {
      throw 'CLOSE_QLIKVIEW_WITHOUT_SAVING_BEFORE_PREPARE'
    }
    $c4Before=ExpectHash $protected $expectedC4 'PROTECTED_C4_HASH_MISMATCH'
    $sourceBefore=ExpectHash $source $expectedVis02 'VIS02_SOURCE_HASH_MISMATCH'
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
      New-Item -ItemType Directory -Path $root -ErrorAction Stop | Out-Null
    }
    $folder=Join-Path $root ("CH06_"+(Get-Date -Format 'yyyyMMdd_HHmmss')+"_"+[guid]::NewGuid().ToString('N').Substring(0,12))
    New-Item -ItemType Directory -Path $folder -ErrorAction Stop | Out-Null
    $work=Join-Path $folder $workName
    [IO.File]::Copy($source,$work,$false)
    $copyHash=ExpectHash $work $expectedVis02 'COPY_HASH_MISMATCH'
    $sourceAfter=ExpectHash $source $expectedVis02 'VIS02_SOURCE_CHANGED_DURING_COPY'
    $c4After=ExpectHash $protected $expectedC4 'PROTECTED_C4_CHANGED_DURING_COPY'
    $manifest=[ordered]@{
      Gate='VIS02_P1_CH06'
      Stage='PREPARED_COPY_ONLY'
      Created=(Get-Date).ToString('o')
      ScriptPath=$PSCommandPath
      ScriptSha256=$scriptSha
      SourceQvw=$source
      SourceHashBefore=$sourceBefore
      SourceHashAfter=$sourceAfter
      ProtectedC4=$protected
      ProtectedC4HashBefore=$c4Before
      ProtectedC4HashAfter=$c4After
      WorkQvw=$work
      WorkInitialHash=$copyHash
      GUIEditAutomated=$false
      QlikReloadExecuted=$false
      QlikSaveExecuted=$false
      ProductionApproved=$false
    }
    $manifestFile=Join-Path $folder 'vis02_p1_manifest.json'
    WriteJsonNew $manifest $manifestFile
    Write-Output 'VERDICT=PASS_COPY_HASHES_ONLY'
    Write-Output ('SOURCE_SHA256='+$sourceAfter)
    Write-Output ('PROTECTED_C4_SHA256='+$c4After)
    Write-Output ('WORK_QVW='+$work)
    Write-Output ('MANIFEST='+$manifestFile)
    Write-Output ('SCRIPT_SHA256='+$scriptSha)
    if (-not $NoLaunch) {
      Invoke-Item -LiteralPath $work -ErrorAction Stop
      Write-Output 'OPEN_REQUESTED=WORK_COPY_ONLY'
    }
    Write-Output 'STOP=EDIT_ONLY_CH06_USING_QLIKVIEW_GUI_THEN_SAVE_COPY_CLOSE_REOPEN'
  } else {
    if ([string]::IsNullOrWhiteSpace($ManifestPath)) {throw 'MANIFEST_REQUIRED_FOR_VERIFY'}
    if ($NoLaunch) {throw 'NOLAUNCH_ONLY_WITH_PREPARE'}
    $manifestFile=Full $ManifestPath
    $m=Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($m.Gate -cne 'VIS02_P1_CH06' -or $m.Stage -cne 'PREPARED_COPY_ONLY') {
      throw 'UNEXPECTED_MANIFEST'
    }
    $work=Full ([string]$m.WorkQvw)
    $folder=[IO.Path]::GetDirectoryName($work)
    if (-not (IsInside $manifestFile $folder)) {throw 'MANIFEST_NOT_IN_WORK_FOLDER'}
    if ([IO.Path]::GetFileName($work) -cne $workName) {throw 'WORK_NAME_MISMATCH'}
    if ((Sha ([string]$m.ScriptPath)) -cne [string]$m.ScriptSha256 -or
        $scriptSha -cne [string]$m.ScriptSha256) {throw 'SCRIPT_HASH_CHANGED'}
    $c4=ExpectHash ([string]$m.ProtectedC4) $expectedC4 'PROTECTED_C4_CHANGED'
    $source=ExpectHash ([string]$m.SourceQvw) $expectedVis02 'VIS02_SOURCE_CHANGED'
    if ([string]$m.WorkInitialHash -cne $expectedVis02) {throw 'MANIFEST_INITIAL_HASH_MISMATCH'}
    $current=Sha $work
    $changed=($current -cne $expectedVis02)
    $screen=$null
    if ($Capture) {
      $screen=CaptureForeground $folder $workName $CaptureDelaySeconds
    }
    $report=[ordered]@{
      Gate='VIS02_P1_CH06'
      Stage='POST_GUI_HASH_AUDIT_ONLY'
      Created=(Get-Date).ToString('o')
      Manifest=$manifestFile
      ScriptSha256=$scriptSha
      SourceHash=$source
      ProtectedC4Hash=$c4
      WorkInitialHash=[string]$m.WorkInitialHash
      WorkCurrentHash=$current
      CopyChanged=$changed
      Screenshot=$screen
      GuiEditIndependentlyVerified=$false
      SavedAndReopenedIndependentlyVerified=$false
      VisualReadabilityNeedsReview=$true
      QlikReloadExecuted=$false
      ProductionApproved=$false
      Verdict=$(if($changed){'PASS_HASH_PROVENANCE_ONLY'}else{'INCONCLUSIVE_COPY_UNCHANGED'})
    }
    $reportPath=Join-Path $folder ("vis02_p1_verify_"+(Get-Date -Format 'yyyyMMdd_HHmmss')+"_"+[guid]::NewGuid().ToString('N').Substring(0,8)+'.json')
    WriteJsonNew $report $reportPath
    Write-Output ('VERDICT='+$report.Verdict)
    Write-Output ('SOURCE_UNCHANGED='+($source -ceq $expectedVis02))
    Write-Output ('PROTECTED_C4_UNCHANGED='+($c4 -ceq $expectedC4))
    Write-Output ('WORK_SHA256='+$current)
    Write-Output ('REPORT='+$reportPath)
    if ($null -ne $screen) {
      Write-Output ('SCREENSHOT='+$screen.Path)
      Write-Output ('SCREENSHOT_SHA256='+$screen.Sha256)
    }
    Write-Output 'STOP=VISUAL_REVIEW_OF_CH06_REQUIRED_NO_AUTOMATIC_GUI_PASS'
  }
} catch {
  Write-Output 'VERDICT=BLOCKED'
  Write-Output ('DETAIL='+$_.Exception.Message)
  exit 2
}
