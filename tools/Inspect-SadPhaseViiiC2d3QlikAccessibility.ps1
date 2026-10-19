# C2-D3: ONE bounded READ-ONLY discovery of UIA RawView and Win32 child windows.
# Never clicks, sends keys, moves mouse, uses QlikView COM, reloads, or saves QVW/QVD.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Root,[switch]$Inspect)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$rel='tools/Inspect-SadPhaseViiiC2d3QlikAccessibility.ps1'
$branch='docs/phase-viii-c2d3-rawview-win32-discovery-20261019'
$self=Join-Path $repo $rel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'BLOCKED_RUNNER_PATH'}
$b=[string](& git -C $repo branch --show-current)
$h=[string](& git -C $repo rev-parse HEAD)
if($LASTEXITCODE -ne 0 -or $b -cne $branch -or $h -notmatch '^[a-f0-9]{40}$'){throw 'BLOCKED_GIT_BRANCH_OR_HEAD'}
& git -C $repo merge-base --is-ancestor '337943d5c5b77067f842902fc679dbb68db87020' HEAD
if($LASTEXITCODE -ne 0){throw 'BLOCKED_MAIN_BASE_NOT_ANCESTOR'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $rel)
if($tracked.Count -ne 1 -or $dirty.Count -ne 0){throw 'BLOCKED_RUNNER_NOT_COMMITTED_CLEAN'}
$scriptSha=(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash
Write-Output ('VERSIONED_GIT_HEAD='+$h)
Write-Output ('SCRIPT_SHA256='+$scriptSha)
Write-Output 'MODE=READ_ONLY_UIA_RAWVIEW_WIN32_NO_COM_NO_MOUSE_NO_KEYBOARD'
if(-not $Inspect){Write-Output 'VERDICT=NOT_EXECUTED_REQUIRES_INSPECT';return}

$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
$source=Join-Path $tmp 'SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw'
if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw 'BLOCKED_SOURCE_QVW_NOT_FOUND'}
$sourceSha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
function Snapshot([string]$kind){
  $files=@()
  if($kind -ceq 'QVD'){
    $ext=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -File -Filter '*.qvd')
    $tr=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -File -Filter '*.qvd')
    if($ext.Count -ne 10 -or $tr.Count -ne 12){throw 'BLOCKED_EXPECTED_22_QVD'}
    $files=@($ext)+@($tr)
  }else{
    foreach($sub in @('EXTRACAO','TRANSFORMACAO','PAINEL')){
      $dir=Join-Path $repo $sub
      if(Test-Path -LiteralPath $dir -PathType Container){
        $files+=@(Get-ChildItem -LiteralPath $dir -File -Filter '*.qvw')
      }
    }
  }
  $r=@()
  foreach($f in $files){
    $r+=('{0}|{1}|{2}' -f $f.FullName,$f.Length,(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)
  }
  return @($r|Sort-Object)
}
$qvdBefore=@(Snapshot 'QVD');$qvwBefore=@(Snapshot 'QVW')
$win=@(Get-Process | Where-Object {
  $_.MainWindowHandle -ne [IntPtr]::Zero -and
  $_.ProcessName -match '^(qv|qlikview)$' -and
  $_.MainWindowTitle.IndexOf($source,[StringComparison]::OrdinalIgnoreCase) -ge 0
})
if($win.Count -ne 1){throw ('BLOCKED_SOURCE_QVW_WINDOW_NOT_UNIQUE_'+$win.Count)}
if($win[0].MainWindowTitle -match '\.qvw\*\]'){throw 'BLOCKED_QVW_HAS_UNSAVED_CHANGES'}
$target=$win[0]
$work=Join-Path $tmp ('SAD_VIII_C2D3_'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('SOURCE_QVW_SHA256='+$sourceSha)
Write-Output ('WINDOW_PID='+$target.Id)
Write-Output 'INPUT_EVENTS=0 QVD_WRITES=0 QVW_WRITES=0'
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;
public static class SadC2D3Win32 {
  public sealed class Child {
    public string ClassName {get;set;}
    public string Text {get;set;}
    public long Handle {get;set;}
    public int X {get;set;}
    public int Y {get;set;}
    public int Width {get;set;}
    public int Height {get;set;}
    public bool Visible {get;set;}
    public bool Enabled {get;set;}
  }
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT { public int Left,Top,Right,Bottom; }
  private delegate bool EnumChild(IntPtr hwnd, IntPtr state);
  [DllImport("user32.dll")] private static extern bool EnumChildWindows(IntPtr h,EnumChild callback,IntPtr state);
  [DllImport("user32.dll",CharSet=CharSet.Unicode)] private static extern int GetClassName(IntPtr h,StringBuilder b,int max);
  [DllImport("user32.dll",CharSet=CharSet.Unicode)] private static extern int GetWindowText(IntPtr h,StringBuilder b,int max);
  [DllImport("user32.dll")] private static extern bool GetWindowRect(IntPtr h,out RECT r);
  [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] private static extern bool IsWindowEnabled(IntPtr h);
  [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr h,out uint id);
  public static List<Child> ListChildren(IntPtr root,uint expectedPid,int limit) {
    var result=new List<Child>();
    EnumChildWindows(root,(h,unused)=>{
      if(result.Count>=limit)return false;
      uint pid;
      GetWindowThreadProcessId(h,out pid);
      if(pid!=expectedPid)return true;
      var c=new StringBuilder(256);var t=new StringBuilder(256);
      GetClassName(h,c,c.Capacity);GetWindowText(h,t,t.Capacity);
      RECT r;
      if(!GetWindowRect(h,out r))return true;
      result.Add(new Child{
        ClassName=c.ToString(),Text=t.ToString(),Handle=h.ToInt64(),
        X=r.Left,Y=r.Top,Width=r.Right-r.Left,Height=r.Bottom-r.Top,
        Visible=IsWindowVisible(h),Enabled=IsWindowEnabled(h)
      });
      return result.Count<limit;
    },IntPtr.Zero);
    return result;
  }
}
'@
# Bounded breadth-first traversal of RawView, never the desktop root.
function RawSnapshot([IntPtr]$hwnd){
  $root=[System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
  if($null -eq $root){throw 'BLOCKED_UIA_QVW_ROOT_NULL'}
  $walker=[System.Windows.Automation.TreeWalker]::RawViewWalker
  $queue=[System.Collections.Generic.Queue[object]]::new()
  $queue.Enqueue([pscustomobject]@{Element=$root;Depth=0})
  $limit=320;$maxDepth=8;$childLimit=96;$rows=@();$truncated=$false
  while($queue.Count -gt 0){
    if($rows.Count -ge $limit){$truncated=$true;break}
    $next=$queue.Dequeue()
    $n=$next.Element;$depth=[int]$next.Depth
    try{
      $c=$n.Current
      $rect=$c.BoundingRectangle
      $rows += [pscustomobject]@{
        Depth=$depth;Name=[string]$c.Name;AutomationId=[string]$c.AutomationId
        ControlType=[string]$c.ControlType.ProgrammaticName;ClassName=[string]$c.ClassName
        FrameworkId=[string]$c.FrameworkId;NativeHandle=[int64]$c.NativeWindowHandle
        Enabled=[bool]$c.IsEnabled;Offscreen=[bool]$c.IsOffscreen
        X=[int][Math]::Round($rect.X);Y=[int][Math]::Round($rect.Y)
        Width=[int][Math]::Round($rect.Width);Height=[int][Math]::Round($rect.Height)
      }
    }catch{
      $rows += [pscustomobject]@{Depth=$depth;Name='<ELEMENT_UNAVAILABLE>';AutomationId='';ControlType=''
        ClassName='';FrameworkId='';NativeHandle=0;Enabled=$false;Offscreen=$true;X=0;Y=0;Width=0;Height=0}
      continue
    }
    if($depth -ge $maxDepth){continue}
    try{
      $child=$walker.GetFirstChild($n);$number=0
      while($null -ne $child){
        if($number -ge $childLimit){$truncated=$true;break}
        $queue.Enqueue([pscustomobject]@{Element=$child;Depth=$depth+1})
        $number++
        $child=$walker.GetNextSibling($child)
      }
    }catch{$truncated=$true}
  }
  return [pscustomobject]@{Rows=@($rows);Truncated=$truncated}
}
function Match([string]$name,[string]$id,[string]$which){
  $phrase=if($which -ceq 'BU01'){'Propor competência 201801'}else{'Propor ano 2019'}
  return (($id -ceq $which) -or
    ($name.IndexOf($phrase,[StringComparison]::OrdinalIgnoreCase) -ge 0))
}
function RawCandidate($snap,[string]$which){
  $matches=@($snap.Rows | Where-Object { (Match ([string]$_.Name) ([string]$_.AutomationId) $which) -and
    (-not $_.Offscreen) -and $_.Width -gt 60 -and $_.Height -gt 12 })
  return $matches
}
function WinCandidate($children,[string]$which){
  return @($children | Where-Object { (Match ([string]$_.Text) '' $which) -and $_.Visible -and
    $_.Width -gt 60 -and $_.Height -gt 12 })
}
function Stable($a,$b){
  if(@($a).Count -ne 1 -or @($b).Count -ne 1){return $false}
  $x=@($a)[0];$y=@($b)[0]
  foreach($field in @('Name','AutomationId','ControlType','ClassName','NativeHandle','Text','Handle')){
    $p=$x.PSObject.Properties[$field];$q=$y.PSObject.Properties[$field]
    if($null -ne $p -and $null -ne $q -and [string]$p.Value -cne [string]$q.Value){return $false}
  }
  foreach($field in @('X','Y','Width','Height')){
    if([Math]::Abs([int]$x.$field - [int]$y.$field) -gt 3){return $false}
  }
  return $true
}
$errorText=''
$classification='BLOCKED_OR_INCONCLUSIVE'
$raw1=$null;$raw2=$null;$children1=@();$children2=@()
try{
  $raw1=RawSnapshot $target.MainWindowHandle
  $children1=@([SadC2D3Win32]::ListChildren($target.MainWindowHandle,[uint32]$target.Id,260))
  Start-Sleep -Milliseconds 1200
  $raw2=RawSnapshot $target.MainWindowHandle
  $children2=@([SadC2D3Win32]::ListChildren($target.MainWindowHandle,[uint32]$target.Id,260))
  @($raw1.Rows)|Export-Csv -LiteralPath (Join-Path $work 'rawview_1.csv') -NoTypeInformation -Encoding UTF8
  @($raw2.Rows)|Export-Csv -LiteralPath (Join-Path $work 'rawview_2.csv') -NoTypeInformation -Encoding UTF8
  @($children1)|Export-Csv -LiteralPath (Join-Path $work 'win32_1.csv') -NoTypeInformation -Encoding UTF8
  @($children2)|Export-Csv -LiteralPath (Join-Path $work 'win32_2.csv') -NoTypeInformation -Encoding UTF8
  Write-Output ('RAW_VIEW_COUNTS='+$raw1.Rows.Count+','+$raw2.Rows.Count)
  Write-Output ('RAW_VIEW_TRUNCATED='+$raw1.Truncated+','+$raw2.Truncated)
  Write-Output ('WIN32_CHILD_COUNTS='+$children1.Count+','+$children2.Count)
  $rawBoth=$true;$winBoth=$true
  foreach($which in @('BU01','BU02')){
    $a=@(RawCandidate $raw1 $which);$b=@(RawCandidate $raw2 $which)
    $wa=@(WinCandidate $children1 $which);$wb=@(WinCandidate $children2 $which)
    $rs=Stable $a $b;$ws=Stable $wa $wb
    if(-not $rs){$rawBoth=$false}
    if(-not $ws){$winBoth=$false}
    Write-Output ('IDENTIFIER='+$which+' RAW_MATCHES='+$a.Count+','+$b.Count+
      ' RAW_STABLE='+$rs+' WIN32_MATCHES='+$wa.Count+','+$wb.Count+' WIN32_STABLE='+$ws)
  }
  if($raw1.Truncated -or $raw2.Truncated -or $children1.Count -ge 260 -or $children2.Count -ge 260){
    $classification='INCONCLUSIVE_ENUMERATION_LIMIT'
  }elseif($rawBoth){$classification='GO_CANDIDATE_RAW_UIA_IDENTIFIERS_TWO_SNAPSHOTS'}
  elseif($winBoth){$classification='GO_CANDIDATE_WIN32_CHILD_IDENTIFIERS_TWO_SNAPSHOTS'}
  else{$classification='NO_GO_STABLE_BU01_BU02_IDENTIFIERS_NOT_FOUND_IN_THIS_PROBE'}
}catch{
  $errorText=$_.Exception.Message
  Write-Output ('DISCOVERY_ERROR='+$errorText)
}finally{
  $integrity=$true
  if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $sourceSha){$integrity=$false}
  if((@((Snapshot 'QVD')) -join [Environment]::NewLine) -cne ($qvdBefore -join [Environment]::NewLine)){$integrity=$false}
  if((@((Snapshot 'QVW')) -join [Environment]::NewLine) -cne ($qvwBefore -join [Environment]::NewLine)){$integrity=$false}
  Write-Output ('ORIGINAL_22_QVD_AND_QVWS_AND_SOURCE_SHA256_UNCHANGED='+$integrity)
  if(-not $integrity){$errorText='CRITICAL_SOURCE_INTEGRITY_DRIFT';$classification='BLOCKED_INTEGRITY'}
}
$report=[ordered]@{
  Gate='C2-D3';Classification=$classification;Error=$errorText
  MainBaseline='337943d5c5b77067f842902fc679dbb68db87020'
  GitHead=$h;ScriptSha256=$scriptSha;SourceQvwSha256=$sourceSha
  RawCounts=if($null -ne $raw1){@($raw1.Rows.Count,$raw2.Rows.Count)}else{@()}
  Win32Counts=@($children1.Count,$children2.Count)
  EvidenceDir=$work;InputEvents=0;ComCalls=0
  ApprovesClickAutomation=$false;P5D2UI='NOT_TESTED';ProductionApproved=$false
}
$report|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $work 'discovery_manifest.json') -Encoding UTF8
Write-Output ('EVIDENCE_MANIFEST='+(Join-Path $work 'discovery_manifest.json'))
Write-Output ('DISCOVERY_VERDICT='+$classification)
Write-Output 'UI_CLICK_AUTOMATION=NOT_AUTHORIZED P5_D2_UI=NOT_TESTED PRODUCTION_APPROVED=False'
if($errorText -ne ''){throw ('C2D3_BLOCKED_'+$errorText)}
