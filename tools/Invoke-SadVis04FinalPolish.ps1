#requires -Version 5.1
<#
.SYNOPSIS
  VIS-04 final presentation: protected QVW copy preflight and post-edit hash audit.
.DESCRIPTION
  Windows PowerShell; NO QlikView COM, Reload, scripted Save, object changes or screenshot.
  GUI alterations are performed by the operator only on the new work copy.
  Keep output manifest for Verify; never replace an original QVW.
#>
[CmdletBinding()]
param(
  [ValidateSet('Prepare','Verify')][string]$Mode = 'Prepare',
  [string]$ManifestPath,
  [switch]$NoLaunch
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$root=Join-Path $env:USERPROFILE 'SAD_VIS04_EVIDENCIAS'
$source=Join-Path $env:USERPROFILE 'SAD_VIS02_P1_EVIDENCIAS\CH06_20261110_163018_870df719340c\SAD_MVP_CH06_LABEL_FIX_TEMP.qvw'
$vis02=Join-Path $env:USERPROFILE 'SAD_VIS02_EVIDENCIAS\VIS02_20261109_230246_40a7da274f784973ab11175e4387a736\SAD_MVP_C4_VIS02_WORK.qvw'
$c4=Join-Path $env:USERPROFILE 'SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw'
$sourceHash='6ED9CC1FAA5AFD592D1D4CECC8D6FC5DE2AB84D4DCE2D4E6D3E6A25E59D7BE37'
$vis02Hash='BA0A7DDCF3F064D3EDC38AD5B0F4D7A79A00CEA0841234D21C0EA4D127C8C704'
$c4Hash='27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13'
$workName='SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw'

function Sha([string]$p) {
  if (-not(Test-Path -LiteralPath $p -PathType Leaf)) {throw "FILE_MISSING: $p"}
  return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Expect([string]$p,[string]$expected,[string]$label) {
  $actual=Sha $p
  if ($actual -cne $expected) {throw "$label HASH_MISMATCH: actual=$actual expected=$expected"}
  return $actual
}
function Full([string]$p) {return [IO.Path]::GetFullPath($p).TrimEnd([char[]]@('\','/'))}
function Under([string]$child,[string]$parent) {
  $a=Full $child
  $b=Full $parent
  return ($a.Equals($b,[StringComparison]::OrdinalIgnoreCase) -or
     $a.StartsWith(($b+'\'),[StringComparison]::OrdinalIgnoreCase))
}
function NewJson([string]$p,[object]$o) {
  if (Test-Path -LiteralPath $p) {throw "REFUSE_OVERWRITE: $p"}
  $json=$o|ConvertTo-Json -Depth 7
  $enc=New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($p,$json,$enc)
}

try {
  if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'WINDOWS_REQUIRED'}
  $scriptPath=Full $PSCommandPath
  $scriptSha=Sha $scriptPath
  $repoRoot=Join-Path $env:USERPROFILE 'documents\programming\sad-sus-pb-data-mart'
  if ((Under $root $repoRoot) -or (Under $root ([IO.Path]::GetDirectoryName($source))) -or
      (Under $root ([IO.Path]::GetDirectoryName($vis02))) -or (Under $root ([IO.Path]::GetDirectoryName($c4)))) {
    throw 'EVIDENCE_ROOT_UNSAFE'
  }
  if ($Mode -eq 'Prepare') {
    if (-not [string]::IsNullOrEmpty($ManifestPath)){throw 'MANIFEST_ONLY_FOR_VERIFY'}
    if (Get-Process -Name Qv -ErrorAction SilentlyContinue) {
      throw 'QLIKVIEW_OPEN_CLOSE_WITHOUT_SAVING_BEFORE_PREPARE'
    }
    $srcBefore=Expect $source $sourceHash 'VIS04_SOURCE'
    $vBefore=Expect $vis02 $vis02Hash 'VIS02_PROTECTED'
    $cBefore=Expect $c4 $c4Hash 'C4_PROTECTED'
    if (-not(Test-Path -LiteralPath $root -PathType Container)) {
      $null=New-Item -ItemType Directory -Path $root -ErrorAction Stop
    }
    $name="VIS04_"+(Get-Date -Format 'yyyyMMdd_HHmmss')+"_"+[Guid]::NewGuid().ToString('N').Substring(0,12)
    $dir=Join-Path $root $name
    $null=New-Item -ItemType Directory -Path $dir -ErrorAction Stop
    $work=Join-Path $dir $workName
    [IO.File]::Copy($source,$work,$false)
    $copyBefore=Expect $work $sourceHash 'WORK_COPY'
    $srcAfter=Expect $source $sourceHash 'VIS04_SOURCE_AFTER_COPY'
    $vAfter=Expect $vis02 $vis02Hash 'VIS02_AFTER_COPY'
    $cAfter=Expect $c4 $c4Hash 'C4_AFTER_COPY'
    $manifest=[ordered]@{
      Gate='VIS04_FINAL_PRESENTATION_STYLE'
      Stage='PREPARED_COPY_ONLY'
      Created=(Get-Date).ToString('o')
      ScriptPath=$scriptPath
      ScriptSha256=$scriptSha
      SourceQvw=(Full $source)
      SourceHash=$srcAfter
      ProtectedVis02=(Full $vis02)
      ProtectedVis02Hash=$vAfter
      ProtectedC4=(Full $c4)
      ProtectedC4Hash=$cAfter
      WorkQvw=(Full $work)
      WorkInitialHash=$copyBefore
      ReloadExecuted=$false
      COMExecuted=$false
      GUIChangesAppliedAutomatically=$false
      ProductionApproved=$false
    }
    $manifestFile=Join-Path $dir 'vis04_manifest.json'
    NewJson $manifestFile $manifest
    Write-Output 'VERDICT=PASS_COPY_HASHES_ONLY'
    Write-Output ('WORK_QVW='+(Full $work))
    Write-Output ('MANIFEST='+(Full $manifestFile))
    Write-Output ('SOURCE_SHA256='+$srcBefore)
    Write-Output ('SCRIPT_SHA256='+$scriptSha)
    if (-not $NoLaunch) {
      Invoke-Item -LiteralPath $work
      Write-Output 'OPEN_REQUESTED=WORK_COPY_ONLY'
    }
    Write-Output 'STOP=EDIT_GUI_ONLY_NO_RELOAD_NO_ORIGINAL_SAVE'
  } else {
    if ($NoLaunch){throw 'NOLAUNCH_ONLY_FOR_PREPARE'}
    if ([string]::IsNullOrWhiteSpace($ManifestPath)){throw 'MANIFEST_REQUIRED'}
    $manifestFull=Full $ManifestPath
    $m=Get-Content -LiteralPath $manifestFull -Raw -Encoding UTF8|ConvertFrom-Json
    if ($m.Gate -cne 'VIS04_FINAL_PRESENTATION_STYLE' -or $m.Stage -cne 'PREPARED_COPY_ONLY') {
      throw 'UNKNOWN_MANIFEST'
    }
    $work=Full ([string]$m.WorkQvw)
    $dir=Full ([IO.Path]::GetDirectoryName($work))
    if (-not (Under $work $root) -or -not (Under $manifestFull $dir) -or
        [IO.Path]::GetFileName($work) -cne $workName) {throw 'WORK_PATH_NOT_AUTHORIZED'}
    if ((Full ([string]$m.ScriptPath)) -cne $scriptPath -or
        ([string]$m.ScriptSha256) -cne $scriptSha) {throw 'SCRIPT_VERSION_CHANGED'}
    if (([string]$m.SourceQvw) -cne (Full $source) -or
        ([string]$m.ProtectedC4) -cne (Full $c4) -or
        ([string]$m.ProtectedVis02) -cne (Full $vis02) -or
        ([string]$m.WorkInitialHash) -cne $sourceHash) {throw 'MANIFEST_PROVENANCE_MISMATCH'}
    $null=Expect $source $sourceHash 'VIS04_SOURCE_POST_EDIT'
    $null=Expect $vis02 $vis02Hash 'VIS02_POST_EDIT'
    $null=Expect $c4 $c4Hash 'C4_POST_EDIT'
    $workAfter=Sha $work
    $changed=($workAfter -cne $sourceHash)
    $report=[ordered]@{
      Gate='VIS04_FINAL_PRESENTATION_STYLE'
      Stage='POST_GUI_HASH_PROVENANCE_ONLY'
      Created=(Get-Date).ToString('o')
      WorkQvw=$work
      WorkInitialHash=$sourceHash
      WorkCurrentHash=$workAfter
      WorkChanged=$changed
      OriginalSourcesPreserved=$true
      GuiVisualResult='NOT_AUDITED_BY_THIS_SCRIPT'
      QlikViewPersistence='NOT_AUDITED_BY_THIS_SCRIPT'
      Verdict=$(if($changed){'PASS_HASH_PROVENANCE_ONLY'}else{'INCONCLUSIVE_COPY_UNCHANGED'})
    }
    $reportFile=Join-Path $dir ("vis04_verify_"+(Get-Date -Format 'yyyyMMdd_HHmmss')+"_"+[Guid]::NewGuid().ToString('N').Substring(0,8)+'.json')
    NewJson $reportFile $report
    Write-Output ('VERDICT='+$report.Verdict)
    Write-Output ('SOURCE_UNCHANGED=True')
    Write-Output ('PROTECTED_VIS02_UNCHANGED=True')
    Write-Output ('PROTECTED_C4_UNCHANGED=True')
    Write-Output ('WORK_SHA256='+$workAfter)
    Write-Output ('REPORT='+(Full $reportFile))
    Write-Output 'STOP=VISUAL_SCREENSHOTS_AND_REOPEN_REQUIRED_FOR_GUI_GATE'
  }
} catch {
  Write-Output 'VERDICT=BLOCKED'
  Write-Output ('DETAIL='+$_.Exception.Message)
  exit 2
}
