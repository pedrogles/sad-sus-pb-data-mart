# C2-D2: native UI Automation + QlikView COM, fail-closed.
# Probe is READ-ONLY. Pilot covers D2-2. Complete covers D2-1/D2-3/D2-4 after pilot evidence.
# Never reload, store QVD, save source QVW, or write canonical QVWs.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [ValidateSet('Probe','Pilot','Complete')][string]$Stage='Probe',
  [string]$PilotManifest=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$rel='tools/Invoke-SadPhaseViiiC2d2UiAutomation.ps1'
$branch='test/phase-viii-c2d2-ui-automation-pilot-20261019'
$self=Join-Path $repo $rel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'BLOCKED_SELF_PATH'}
$b=[string](& git -C $repo branch --show-current)
$head=[string](& git -C $repo rev-parse HEAD)
if($LASTEXITCODE -ne 0 -or $b -cne $branch -or $head -notmatch '^[0-9a-f]{40}$'){throw 'BLOCKED_GIT_IDENTITY'}
& git -C $repo merge-base --is-ancestor '337943d5c5b77067f842902fc679dbb68db87020' HEAD
if($LASTEXITCODE -ne 0){throw 'BLOCKED_BASE_COMMIT'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $rel)
if($tracked.Count -ne 1 -or $dirty.Count -ne 0){throw 'BLOCKED_RUNNER_NOT_COMMITTED_CLEAN'}

$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
$source=Join-Path $tmp 'SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw'
if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw 'BLOCKED_D2_SOURCE_NOT_PRESENT'}
$sourceHash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$scriptHash=(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash
$work=Join-Path $tmp ('SAD_VIII_C2D2_'+$Stage.ToUpperInvariant()+'_'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('SCRIPT_SHA256='+$scriptHash)
Write-Output ('D2_SOURCE_QVW_SHA256='+$sourceHash)
Write-Output ('STAGE='+$Stage+' NO_RELOAD=True QVD_WRITES=0')
function Snapshot([string]$type){
  $files=@()
  if($type -ceq 'QVD'){
    $a=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -File -Filter '*.qvd')
    $c=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -File -Filter '*.qvd')
    if($a.Count -ne 10 -or $c.Count -ne 12){throw 'BLOCKED_EXPECTED_22_QVD'}
    $files=@($a)+@($c)
  }else{
    foreach($dir in @('EXTRACAO','TRANSFORMACAO','PAINEL')){
      $path=Join-Path $repo $dir
      if(Test-Path -LiteralPath $path -PathType Container){
        $files+=@(Get-ChildItem -LiteralPath $path -File -Filter '*.qvw')
      }
    }
  }
  $out=@()
  foreach($f in $files){$out+=('{0}|{1}|{2}' -f $f.FullName,$f.Length,(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)}
  return @($out | Sort-Object)
}
$qvds=@(Snapshot 'QVD')
$qvws=@(Snapshot 'QVW')
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes,System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SadD2Win {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint x, uint y, uint data, UIntPtr extra);
}
'@
[void][SadD2Win]::SetProcessDPIAware()

function GetWindow([string]$fileName){
  $windows=@(Get-Process | Where-Object {
    $_.MainWindowHandle -ne [IntPtr]::Zero -and
    $_.ProcessName -match '^(qv|qlikview)$' -and
    $_.MainWindowTitle.IndexOf($fileName,[StringComparison]::OrdinalIgnoreCase) -ge 0
  })
  if($windows.Count -ne 1){throw ('BLOCKED_EXACT_QVW_WINDOW_NOT_UNIQUE_'+$fileName+'_'+$windows.Count)}
  if($windows[0].MainWindowTitle -match '\.qvw\*\]'){throw 'BLOCKED_QVW_UNSAVED_GUI_CHANGES'}
  return $windows[0]
}
function WindowForeground($proc){
  $hwnd=$proc.MainWindowHandle
  [void][SadD2Win]::SetForegroundWindow($hwnd)
  Start-Sleep -Milliseconds 400
  if([SadD2Win]::GetForegroundWindow() -ne $hwnd){throw 'BLOCKED_FOREGROUND_IS_NOT_TARGET_QVW'}
  return $hwnd
}
function AccessibleButtons([IntPtr]$window){
  $root=[System.Windows.Automation.AutomationElement]::FromHandle($window)
  if($null -eq $root){throw 'BLOCKED_UIA_WINDOW_ROOT_NOT_FOUND'}
  $nodes=$root.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition)
  $result=@{}
  foreach($n in $nodes){
    $name=[string]$n.Current.Name
    if($n.Current.ControlType -ne [System.Windows.Automation.ControlType]::Button){continue}
    foreach($id in @('BU01','BU02')){
      $needle=if($id -eq 'BU01'){'Propor competência 201801'}else{'Propor ano 2019'}
      if($name.IndexOf($needle,[StringComparison]::OrdinalIgnoreCase) -ge 0){
        if($result.ContainsKey($id)){throw ('BLOCKED_UIA_BUTTON_NOT_UNIQUE_'+$id)}
        $result[$id]=$n
      }
    }
  }
  if($result.Count -ne 2){throw ('BLOCKED_UIA_EXACT_BUTTONS_NOT_EXPOSED_FOUND_'+$result.Count)}
  return $result
}
function ConfirmButton($proc,[string]$id,[bool]$expectedEnabled){
  $window=WindowForeground $proc
  $buttons=AccessibleButtons $window
  $b=$buttons[$id]
  if([bool]$b.Current.IsEnabled -ne $expectedEnabled){
    throw ('BLOCKED_UIA_ENABLED_'+$id+'_EXPECTED_'+$expectedEnabled+'_OBSERVED_'+$b.Current.IsEnabled)
  }
  $br=$b.Current.BoundingRectangle
  $wr=New-Object SadD2Win+RECT
  if(-not [SadD2Win]::GetWindowRect($window,[ref]$wr)){throw 'BLOCKED_WINDOW_BOUNDS'}
  $x=[int][Math]::Floor($br.X+$br.Width/2)
  $y=[int][Math]::Floor($br.Y+$br.Height/2)
  if($br.IsEmpty -or $br.Width -lt 85 -or $br.Height -lt 14 -or
      $x -lt ($wr.Left+8) -or $x -gt ($wr.Right-8) -or
      $y -lt ($wr.Top+70) -or $y -gt ($wr.Bottom-8)){
    throw ('BLOCKED_UIA_BUTTON_RECT_'+$id)
  }
  Write-Output ('UIA_BUTTON='+$id+' ENABLED='+$expectedEnabled+' NAME='+$b.Current.Name+
    ' CENTER='+$x+','+$y+' RECT='+[int]$br.Width+'x'+[int]$br.Height)
  return [pscustomobject]@{X=$x;Y=$y;Enabled=$expectedEnabled}
}
function Capture($proc,[string]$name){
  $hwnd=WindowForeground $proc
  $rect=New-Object SadD2Win+RECT
  if(-not [SadD2Win]::GetWindowRect($hwnd,[ref]$rect)){throw 'BLOCKED_SCREENSHOT_RECT'}
  $w=$rect.Right-$rect.Left;$h=$rect.Bottom-$rect.Top
  if($w -lt 850 -or $h -lt 600 -or $w -gt 5000 -or $h -gt 3500){throw 'BLOCKED_SCREENSHOT_DIMENSIONS'}
  $bmp=[System.Drawing.Bitmap]::new($w,$h)
  try{
    $g=[System.Drawing.Graphics]::FromImage($bmp)
    try{$g.CopyFromScreen($rect.Left,$rect.Top,0,0,([System.Drawing.Size]::new($w,$h)))}
    finally{$g.Dispose()}
    $file=Join-Path $work ($name+'.png')
    $bmp.Save($file,[System.Drawing.Imaging.ImageFormat]::Png)
  }finally{$bmp.Dispose()}
  Write-Output ('SCREENSHOT='+$name+' SHA256='+(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash+' VISUAL_AUDIT=PENDING')
}
function PhysicalClick($proc,$button){
  [void](WindowForeground $proc)
  if(-not [SadD2Win]::SetCursorPos($button.X,$button.Y)){throw 'BLOCKED_POINTER_SET'}
  Start-Sleep -Milliseconds 200
  [SadD2Win]::mouse_event(0x0002,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
  [SadD2Win]::mouse_event(0x0004,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 650
}
function Numeric([string]$expression){
  $v=[string]$script:doc.Evaluate($expression)
  if($v -notmatch '^[0-9]+$'){throw ('BLOCKED_NUMERIC_COM_VALUE_'+$expression+'_'+$v)}
  return [int]$v
}
function CurrentSelection([string]$name){
  $c=Numeric ('GetSelectedCount('+$name+')')
  $v=if($c -eq 1){[string]$script:doc.Evaluate('GetFieldSelections('+$name+')')}else{''}
  return [pscustomobject]@{Count=$c;Value=$v}
}
function AssertState([int]$yearCount,[string]$year,[int]$monthCount,[string]$month){
  $a=CurrentSelection 'PERIODO_ANO'
  $m=CurrentSelection 'PERIODO_COMPETENCIA'
  if($a.Count -ne $yearCount -or $m.Count -ne $monthCount -or
    ($yearCount -eq 1 -and $a.Value -cne $year) -or
    ($monthCount -eq 1 -and $m.Value -cne $month)){
    throw ('BLOCKED_COM_SELECTION_YEAR='+$a.Count+':'+$a.Value+'_MONTH='+$m.Count+':'+$m.Value)
  }
}
function SetState([string]$field,[string]$value){
  [void]$script:doc.ClearAll()
  $f=$script:doc.GetField($field)
  if($null -eq $f){throw ('BLOCKED_MISSING_FIELD_'+$field)}
  [void]$f.Select($value)
  if($field -ceq 'PERIODO_ANO'){AssertState 1 $value 0 ''}
  else{AssertState 0 '' 1 $value}
}
function RunCase([string]$code,[string]$initialField,[string]$initialValue,
  [string]$buttonId,[bool]$expectedEnabled,[int]$resultYear,[string]$year,
  [int]$resultMonth,[string]$month){
  SetState $initialField $initialValue
  $proc=GetWindow 'SAD_C2D2_BUTTON_AUTOMATION.qvw'
  $anchor=ConfirmButton $proc $buttonId $expectedEnabled
  Capture $proc ($code+'_before')
  Write-Output ('CASE='+$code+' BEFORE_VALIDATED=True BUTTON_ENABLED='+$expectedEnabled)
  # Recheck the very same button/geometry immediately before actual mouse input.
  $fresh=ConfirmButton $proc $buttonId $expectedEnabled
  if($fresh.X -ne $anchor.X -or $fresh.Y -ne $anchor.Y){throw 'BLOCKED_MOVING_BUTTON_COORDINATES'}
  PhysicalClick $proc $fresh
  AssertState $resultYear $year $resultMonth $month
  [void](ConfirmButton $proc $buttonId $expectedEnabled)
  Capture $proc ($code+'_after')
  Write-Output ('CASE='+$code+' POST_STATE=PASS_CANDIDATE_CLICK_PERFORMED=True')
}
$script:doc=$null;$app=$null;$issue='';$passed=@()
try{
  if($Stage -ceq 'Probe'){
    $proc=GetWindow 'SAD_C2D1_D2_BUTTON_TEST.qvw'
    $hwnd=WindowForeground $proc
    $buttons=AccessibleButtons $hwnd
    foreach($id in @('BU01','BU02')){
      $bb=$buttons[$id].Current.BoundingRectangle
      Write-Output ('PROBE_BUTTON='+$id+' NAME='+$buttons[$id].Current.Name+
        ' ENABLED='+$buttons[$id].Current.IsEnabled+
        ' RECT='+[int]$bb.Width+'x'+[int]$bb.Height)
    }
    Capture $proc 'probe'
    Write-Output 'VERDICT=PASS_READONLY_C2D2_UIA_BUTTON_DISCOVERY_CANDIDATE'
  }else{
    if(@(Get-Process | Where-Object {
      $_.MainWindowTitle -like '*SAD_C2D1_D2_BUTTON_TEST.qvw*'
    }).Count -gt 0){throw 'BLOCKED_CLOSE_SOURCE_D2_QVW_WITHOUT_SAVING_FIRST'}
    if($Stage -ceq 'Complete'){
      if(-not(Test-Path -LiteralPath $PilotManifest -PathType Leaf)){throw 'BLOCKED_PILOT_MANIFEST_REQUIRED'}
      $pilot=Get-Content -LiteralPath $PilotManifest -Raw -Encoding UTF8 | ConvertFrom-Json
      if($pilot.Stage -cne 'Pilot' -or $pilot.Verdict -cne 'PASS_LOCAL_D2_2_BUTTON_ROUTE_CANDIDATE_ONLY' -or
        $pilot.SourceSha256 -cne $sourceHash -or $pilot.ScriptSha256 -cne $scriptHash){
        throw 'BLOCKED_PILOT_EVIDENCE_MISMATCH'
      }
    }
    $copy=Join-Path $work 'SAD_C2D2_BUTTON_AUTOMATION.qvw'
    Copy-Item -LiteralPath $source -Destination $copy
    if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash){throw 'BLOCKED_DISPOSABLE_COPY_HASH'}
    $app=New-Object -ComObject 'QlikTech.QlikView'
    $script:doc=$app.OpenDoc($copy,'','')
    if($null -eq $script:doc){throw 'BLOCKED_COM_OPEN_NEW_COPY'}
    foreach($id in @('BU01','BU02')){
      if($null -eq $script:doc.GetSheetObject($id)){throw ('BLOCKED_COM_BUTTON_MISSING_'+$id)}
    }
    Start-Sleep -Milliseconds 1100
    if($Stage -ceq 'Pilot'){
      # Reverse D2-2: selected month 201801 must reject button proposing year 2019.
      RunCase 'D2_2' 'PERIODO_COMPETENCIA' '201801' 'BU02' $false 0 '' 1 '201801'
      $passed+= 'D2_2'
    }else{
      RunCase 'D2_1' 'PERIODO_ANO' '2019' 'BU01' $false 1 '2019' 0 ''
      $passed+= 'D2_1'
      RunCase 'D2_3' 'PERIODO_ANO' '2018' 'BU01' $true 1 '2018' 1 '201801'
      $passed+= 'D2_3'
      RunCase 'D2_4' 'PERIODO_COMPETENCIA' '201901' 'BU02' $true 1 '2019' 1 '201901'
      $passed+= 'D2_4'
    }
    Write-Output 'UIA_BUTTON_ROUTE_COM_ASSERTIONS=PASS_CANDIDATE_SCREENSHOTS_PENDING_VISUAL_REVIEW'
  }
}catch{
  $issue=$_.Exception.Message
  Write-Output ('EXECUTION_BLOCKED='+$issue)
}finally{
  if($null -ne $script:doc){try{[void]$script:doc.CloseDoc()}catch{Write-Output ('WARN_CLOSE_COPY='+$_.Exception.Message)}}
  if($null -ne $app -and [Runtime.InteropServices.Marshal]::IsComObject($app)){
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($app)
  }
  $immutable=$true
  if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $sourceHash){$immutable=$false;Write-Output 'CRITICAL_SOURCE_QVW_CHANGED'}
  if((@((Snapshot 'QVD')) -join [Environment]::NewLine) -cne ($qvds -join [Environment]::NewLine)){$immutable=$false;Write-Output 'CRITICAL_QVDS_CHANGED'}
  if((@((Snapshot 'QVW')) -join [Environment]::NewLine) -cne ($qvws -join [Environment]::NewLine)){$immutable=$false;Write-Output 'CRITICAL_CANONICAL_QVWS_CHANGED'}
  if(-not $immutable){$issue='CRITICAL_SOURCE_INTEGRITY_DRIFT'}
  Write-Output ('ORIGINAL_SOURCES_INTEGRITY=' + $(if($immutable){'PASS'}else{'FAILED'}))
}
$verdict=if($issue -ne ''){'BLOCKED_OR_INCONCLUSIVE'}elseif($Stage -ceq 'Probe'){'PASS_READONLY_C2D2_UIA_BUTTON_DISCOVERY_CANDIDATE'}elseif($Stage -ceq 'Pilot'){'PASS_LOCAL_D2_2_BUTTON_ROUTE_CANDIDATE_ONLY'}else{'PASS_LOCAL_C2D1_REMAINING_BUTTON_ROUTES_CANDIDATE_ONLY'}
$manifest=[ordered]@{
  Stage=$Stage;Verdict=$verdict;SourceSha256=$sourceHash;ScriptSha256=$scriptHash;
  GitHead=$head;CompletedCases=@($passed);Failure=$issue;
  ArtifactDirectory=$work;UiClick='WIN32_MOUSE_ON_UIA_EXACT_BUTTON_ONLY';
  VisualAudit='PENDING';PreDispatchInternalInstrumentation='NOT_IMPLEMENTED';
  P5_D2_UI='NOT_TESTED';ProductionApproved=$false
}
$manifestPath=Join-Path $work 'result_manifest.json'
$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Output ('EVIDENCE_MANIFEST='+$manifestPath)
if($issue -ne ''){throw ('C2D2_BLOCKED_'+$issue)}
Write-Output ('VERDICT='+$verdict)
Write-Output 'P5_D2_UI=NOT_TESTED C2_FULL=NOT_APPROVED PRODUCTION_APPROVED=False'