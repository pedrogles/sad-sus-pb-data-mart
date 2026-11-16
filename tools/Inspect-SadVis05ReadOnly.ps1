#requires -Version 5.1
<#
VIS-05: pinned-byte inventory and bounded in-memory scenarios on a read-only copy.
No Reload/Save/SetProperties/CreateDoc. Select/ClearAll/Activate affect only the copy's session.
Reuses historical GetSheet/GetSheetObjects enumeration and EvaluationCondition.v readback.
ErrorMessageOverrides is not indexed: its COM item mapping remains unverified.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [string]$ArtifactRoot,
  [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{40}$')][string]$ExpectedCommit,
  [string]$SourceQvw = (Join-Path $env:USERPROFILE 'SAD_VIS05_EVIDENCIAS\VIS05_20261112_171721_950990d1\SAD_MVP_VIS05_UX_WORK_TEMP.qvw'),
  [string]$EvidenceRoot = (Join-Path $env:USERPROFILE 'SAD_VIS05_INSPECTION_EVIDENCIAS'),
  [ValidateSet('Inventory','Scenarios','WindowDiagnostic')][string]$Mode='Inventory',
  [switch]$Capture,
  [ValidateRange(2,30)][int]$CaptureFocusSeconds=8,
  [switch]$ManualSortReview,
  [Parameter(Mandatory=$true)][switch]$Inspect
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Full([string]$p){return [IO.Path]::GetFullPath($p).TrimEnd([char[]]@('\','/'))}
function Under([string]$a,[string]$b){
  return $a.Equals($b,[StringComparison]::OrdinalIgnoreCase) -or $a.StartsWith($b+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
function Sha([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()}
function Json([string]$p,$v){
  [IO.File]::WriteAllText($p,(ConvertTo-Json -InputObject $v -Depth 24),[Text.UTF8Encoding]::new($false))
}
function Scalar($v){return ($null -eq $v -or $v -is [string] -or $v -is [ValueType])}
function Node($obj,[int]$depth=0){
  if(Scalar $obj){return $obj}
  if($script:nodeBudget -le 0){return @{read_status='INCONCLUSIVE_METADATA_BUDGET_REACHED'}}
  $script:nodeBudget--
  $out=[ordered]@{type=$obj.GetType().FullName;properties=[ordered]@{}}
  $names=@(Get-Member -InputObject $obj -MemberType Property -ErrorAction Stop | Select-Object -ExpandProperty Name | Sort-Object -Unique)
  $out.members=$names
  if($depth -ge 3){return $out}
  foreach($name in @($names | Select-Object -First 40)){
    # Do not call default/indexed properties or enumerate unknown COM collections.
    if($name -in @('Default','Item')){continue}
    try{$child=$obj.$name;$out.properties[$name]=Node $child ($depth+1)}
    catch{$out.properties[$name]=@{read_status='UNAVAILABLE';detail=$_.Exception.Message}}
  }
  return $out
}
function ReadPath($obj,[string]$path){
  try{foreach($part in ($path -split '\.')){$obj=$obj.$part};if(Scalar $obj){return $obj};return $null}catch{return $null}
}
function ChartRecord($obj,[string]$id,[int]$sheet){
  $p=$obj.GetProperties()
  if($null -eq $p){throw "GetProperties unavailable: $id"}
  $script:nodeBudget=128
  $r=[ordered]@{id=$id;sheet=$sheet;title=(ReadPath $p 'GraphLayout.WindowTitle.v');condition=(ReadPath $p 'EvaluationCondition.v');properties=(Node $p);first_expression_data=$null;expression_read_status='INCONCLUSIVE'}
  # Exactly the 0-based expression access already exercised by the main builder.
  try{$data=$p.Expressions.Item(0).Item(0).Data.ExpressionData;$script:nodeBudget=32;$r.first_expression_data=Node $data;$r.expression_read_status='READ_BACK'}
  catch{$r.expression_read_detail=$_.Exception.Message}
  return $r
}
function EvaluateRecord([string]$expr){
  $raw=[string]$script:doc.Evaluate($expr)
  return @{expression=$expr;raw=$raw}
}
function EngineProbes($contract){
  $out=[ordered]@{}
  foreach($p in $contract.probes.PSObject.Properties){
    $out[$p.Name]=EvaluateRecord ("Num(("+[string]$p.Value+"),'0','.',',')")
  }
  return $out
}
function Guard($obj){
  $condition=ReadPath ($obj.GetProperties()) 'EvaluationCondition.v'
  if($null -eq $condition){return @{status='INCONCLUSIVE';expression=$null;raw=$null}}
  if([string]::IsNullOrWhiteSpace([string]$condition)){return @{status='READ_BACK';expression=$condition;raw='1';empty_means_unconditional=$true}}
  $expr=([string]$condition).Trim()
  if($expr.StartsWith('=')){$expr=$expr.Substring(1)}
  $answer=EvaluateRecord $expr
  return @{status='READ_BACK';expression=$condition;raw=$answer.raw}
}
function Test-SelectionReset([string]$Summary,[string]$RecordCount,[hashtable]$FieldCounts,[string[]]$RequiredFields){
  # A display dash alone proves nothing: require independent numeric observations.
  if($Summary.Trim() -notin @('','-') -or $RecordCount.Trim() -cne '0'){return $false}
  if($RequiredFields.Count -eq 0){return $false}
  foreach($field in $RequiredFields){
    if(-not $FieldCounts.ContainsKey($field) -or ([string]$FieldCounts[$field]).Trim() -cne '0'){return $false}
  }
  return $true
}
function SelectState($scenario,$contract){
  $null=$script:doc.ClearAll()
  $empty=[string]$script:doc.Evaluate("GetCurrentSelections('|','=',',',1000)")
  # Every nonempty selection record uses the explicit '=' tag separator.
  # Num/RangeSum yields an integer for a null/empty summary; errors remain nonnumeric.
  $records=[string]$script:doc.Evaluate("Num(RangeSum(0,SubStringCount(GetCurrentSelections('|','=',',',1000),'=')),'0','.',',')")
  $counts=@{}
  foreach($field in @($contract.field_allowlist)){
    $counts[$field]=[string]$script:doc.Evaluate(("Num(GetSelectedCount([{0}],True()),'0','.',',')" -f $field))
  }
  $reset=Test-SelectionReset $empty $records $counts @($contract.field_allowlist)
  $script:report.selection_reset_checks+=@{scenario=$scenario.id;raw_summary=$empty;selection_record_count=$records;selected_counts=$counts;verified=$reset}
  if(-not $reset){throw "Selection reset not verified: summary='$empty' record_count='$records'"}
  foreach($p in $scenario.selections.PSObject.Properties){
    if(@($contract.field_allowlist) -cnotcontains $p.Name){throw 'Field not authorized'}
    $null=$script:doc.GetField($p.Name).Select([string]$p.Value)
    $count=[string]$script:doc.Evaluate(('GetSelectedCount(['+$p.Name+'],True())'))
    $value=[string]$script:doc.Evaluate(('GetFieldSelections(['+$p.Name+'])'))
    if($count.Trim() -cne '1' -or $value.Trim() -cne [string]$p.Value){throw "Selection mismatch: $($p.Name)"}
  }
  return [string]$script:doc.Evaluate("GetCurrentSelections('|','=',',',1000)")
}
function Test-CaptureIdentity([uint32]$ObservedProcess,[uint32]$ExpectedProcess,[string]$WindowTitle,[string]$ExpectedCopy){
  return $ExpectedProcess -gt 0 -and $ObservedProcess -eq $ExpectedProcess -and
    -not [string]::IsNullOrWhiteSpace($ExpectedCopy) -and
    -not [string]::IsNullOrWhiteSpace($WindowTitle) -and
    $WindowTitle.IndexOf($ExpectedCopy,[StringComparison]::OrdinalIgnoreCase) -ge 0
}
function Test-CaptureGeometry([hashtable]$Window,[hashtable]$Desktop,[bool]$Minimized){
  $reasons=@()
  if($Minimized){$reasons+='MINIMIZED'}
  if($Window.width -lt 700){$reasons+='WIDTH_BELOW_700'}
  if($Window.height -lt 500){$reasons+='HEIGHT_BELOW_500'}
  if($Window.left -lt $Desktop.left -or $Window.top -lt $Desktop.top -or
    ($Window.left+$Window.width) -gt ($Desktop.left+$Desktop.width) -or
    ($Window.top+$Window.height) -gt ($Desktop.top+$Desktop.height)){$reasons+='OUTSIDE_VIRTUAL_SCREEN'}
  return @{eligible=($reasons.Count -eq 0);reasons=@($reasons)}
}
function CaptureSheet([int]$index,[string]$path,[switch]$Diagnostic){
  $null=$script:doc.GetSheet($index).Activate()
  if(-not ('SadVis05Window' -as [type])){
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class SadVis05Window {
 [StructLayout(LayoutKind.Sequential)] public struct RECT {public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);
 [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h,int attribute,out RECT r,int size);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
}
'@
  }
  $processes=@(Get-Process -Name Qv -ErrorAction Stop)
  if($processes.Count -ne 1){throw 'Capture requires one Qv process'}
  [uint32]$expectedProcess=$processes[0].Id
  function ForegroundSnapshot {
    $handle=[SadVis05Window]::GetForegroundWindow()
    [uint32]$observedProcess=0
    $caption=[Text.StringBuilder]::new(2048)
    if($handle -ne [IntPtr]::Zero){
      $null=[SadVis05Window]::GetWindowThreadProcessId($handle,[ref]$observedProcess)
      $null=[SadVis05Window]::GetWindowText($handle,$caption,2048)
    }
    return @{handle=$handle;process=$observedProcess;title=$caption.ToString();valid=(Test-CaptureIdentity $observedProcess $expectedProcess $caption.ToString() $copy)}
  }
  # Windows may deny focus; MainWindowHandle is only a focus hint, never the identity proof.
  $hint=$processes[0].MainWindowHandle
  $requested=$false
  if($hint -ne [IntPtr]::Zero){$requested=[SadVis05Window]::SetForegroundWindow($hint)}
  Start-Sleep -Milliseconds 800
  $initial=ForegroundSnapshot
  $observed=$initial
  $waited=$false
  if(-not $initial.valid){
    Write-Host ("FOCUS_REQUIRED: click the QlikView INSPECTION COPY now; do not click this console. Capture in "+$CaptureFocusSeconds+" seconds.")
    Start-Sleep -Seconds $CaptureFocusSeconds
    $waited=$true
    $observed=ForegroundSnapshot
  }
  $script:report.capture_focus_events+=@{sheet=$index;set_foreground_return=$requested;initial_copy_verified=$initial.valid;operator_wait_used=$waited;expected_process=$expectedProcess;observed_process=$observed.process;final_copy_verified=$observed.valid}
  if(-not $observed.valid){throw 'Capture focus timeout: foreground PID and full inspection-copy path were not both verified'}
  $h=$observed.handle
  $title=[string]$observed.title
  $rect=[SadVis05Window+RECT]::new()
  if(-not [SadVis05Window]::GetWindowRect($h,[ref]$rect)){throw 'No window rectangle'}
  Add-Type -AssemblyName System.Drawing
  Add-Type -AssemblyName System.Windows.Forms
  $area=[Drawing.Rectangle]::new($rect.Left,$rect.Top,$rect.Right-$rect.Left,$rect.Bottom-$rect.Top)
  $virtual=[Windows.Forms.SystemInformation]::VirtualScreen
  $window=@{left=$area.Left;top=$area.Top;width=$area.Width;height=$area.Height}
  $desktop=@{left=$virtual.Left;top=$virtual.Top;width=$virtual.Width;height=$virtual.Height}
  $minimized=[SadVis05Window]::IsIconic($h)
  $geometry=Test-CaptureGeometry $window $desktop $minimized
  $dpi=@{status='UNAVAILABLE'}
  try{$value=[SadVis05Window]::GetDpiForWindow($h);if($value -gt 0){$dpi=@{status='OBSERVED_WINDOW_EFFECTIVE_DPI';value=$value}}}catch{}
  $frame=@{status='UNAVAILABLE'}
  try{
    $dwm=[SadVis05Window+RECT]::new()
    $hr=[SadVis05Window]::DwmGetWindowAttribute($h,9,[ref]$dwm,[Runtime.InteropServices.Marshal]::SizeOf($dwm))
    if($hr -eq 0){$frame=@{status='OBSERVED_NOT_DPI_ADJUSTED';left=$dwm.Left;top=$dwm.Top;width=($dwm.Right-$dwm.Left);height=($dwm.Bottom-$dwm.Top)}}
  }catch{}
  $screens=@([Windows.Forms.Screen]::AllScreens | ForEach-Object {
    @{primary=$_.Primary;bounds=@{left=$_.Bounds.Left;top=$_.Bounds.Top;width=$_.Bounds.Width;height=$_.Bounds.Height};working_area=@{left=$_.WorkingArea.Left;top=$_.WorkingArea.Top;width=$_.WorkingArea.Width;height=$_.WorkingArea.Height}}
  })
  $observation=@{sheet=$index;window=$window;virtual_screen=$desktop;screens=$screens;minimized=$minimized;maximized=[SadVis05Window]::IsZoomed($h);dpi=$dpi;dwm_visible_frame=$frame;geometry=$geometry;coordinate_caveat='GetWindowRect and DWM may use different DPI coordinate spaces; no automatic substitution';capture_performed=$false}
  $script:report.window_diagnostics+=@($observation)
  if($Diagnostic){return $observation}
  if(-not $geometry.eligible){throw ('Capture geometry blocked: '+($geometry.reasons -join ','))}
  $bitmap=[Drawing.Bitmap]::new($area.Width,$area.Height)
  $graphics=[Drawing.Graphics]::FromImage($bitmap)
  try{$graphics.CopyFromScreen($area.X,$area.Y,0,0,$area.Size);$bitmap.Save($path,[Drawing.Imaging.ImageFormat]::Png)}
  finally{$graphics.Dispose();$bitmap.Dispose()}
  $observation.capture_performed=$true
  return @{status='CAPTURED_PENDING_VISUAL_REVIEW';file=[IO.Path]::GetFileName($path);sha256=(Sha $path);sheet=$index;window_title=$title}
}

$script:doc=$null;$app=$null;$run=$null;$copy=$null
$locks=[Collections.Generic.List[object]]::new()
$before=@();$results=[Collections.Generic.List[object]]::new()
$report=[ordered]@{gate='SAD_VIS05_READONLY_INSPECTION_01';mode=$Mode;started=(Get-Date).ToString('o');status='BLOCKED_PRECHECK';objects=@();scenarios=@();capture_focus_events=@();selection_reset_checks=@();window_diagnostics=@();integrity_verified=$false;cleanup_ok=$false;manual_sort_status='NOT_RUN';global_approval=$false}
$exitCode=2
try{
  if(-not $Inspect){throw 'Explicit -Inspect required'}
  if($Mode -ceq 'WindowDiagnostic' -and $Capture){throw 'WindowDiagnostic does not capture; omit -Capture'}
  if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows required'}
  if($ManualSortReview -and ($Mode -cne 'Scenarios' -or -not $Capture)){throw 'ManualSortReview requires Scenarios and Capture'}
  $repo=Full $Root;$source=Full $SourceQvw;$evidence=Full $EvidenceRoot
  $artifacts=$repo
  if(-not [string]::IsNullOrWhiteSpace($ArtifactRoot)){$artifacts=Full $ArtifactRoot}
  if(-not (Test-Path -LiteralPath (Join-Path $artifacts 'AGENTS.md') -PathType Leaf)){throw 'ArtifactRoot must be the existing SAD clone'}
  $contractRel='PAINEL/sad_vis05_readonly_inspection_contract.json'
  $selfRel='tools/Inspect-SadVis05ReadOnly.ps1'
  if((Full $PSCommandPath) -ine (Full (Join-Path $repo $selfRel))){throw 'Run the committed repository script'}
  $contractPath=Join-Path $repo $contractRel
  $contract=Get-Content -LiteralPath $contractPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if($contract.gate -cne $report.gate -or [int]$contract.version -ne 1){throw 'Wrong contract'}
  $branch=(& git -C $repo branch --show-current | Out-String).Trim()
  $head=(& git -C $repo rev-parse HEAD | Out-String).Trim()
  if($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit.ToLowerInvariant() -or $branch -cne $contract.branch){throw 'Git branch/commit mismatch'}
  foreach($rel in @($selfRel,$contractRel,'tools/review_sad_vis05_inspection.py','tools/test_review_sad_vis05_inspection.py')){
    $expected=(& git -C $repo rev-parse ("HEAD:"+$rel) | Out-String).Trim()
    $actual=(& git -C $repo hash-object -- (Join-Path $repo $rel) | Out-String).Trim()
    if($LASTEXITCODE -ne 0 -or $expected -cne $actual){throw "Uncommitted source bytes: $rel"}
  }
  $dirty=@(& git -C $repo status --porcelain --untracked-files=no)
  if($dirty.Count -ne 0){throw 'Tracked working tree must be clean'}
  if((Under $source $repo) -or (Under $source $artifacts) -or [IO.Path]::GetFileName($source) -cne $contract.source_name){throw 'Only external VIS-05 source accepted'}
  if((Under $evidence $repo) -or (Under $repo $evidence) -or (Under $evidence $artifacts) -or (Under $artifacts $evidence) -or (Under $evidence (Full ([IO.Path]::GetTempPath()))) -or (Under $source $evidence)){throw 'Unsafe evidence root'}
  if(@(Get-Process -Name Qv -ErrorAction SilentlyContinue).Count -gt 0){throw 'Close QlikView before starting'}
  if((Sha $source) -cne $contract.source_sha256){throw 'VIS-05 source SHA mismatch; do not replace the pin'}
  $protected=[Collections.Generic.List[string]]::new();$protected.Add($source)
  foreach($folder in @('EXTRACAO/QVD','TRANSFORMACAO/QVD')){
    $files=@(Get-ChildItem -LiteralPath (Join-Path $artifacts $folder) -Filter '*.qvd' -File)
    $n=if($folder -ceq 'EXTRACAO/QVD'){10}else{12}
    if($files.Count -ne $n){throw "Expected $n QVDs in $folder"}
    foreach($file in $files){$protected.Add($file.FullName)}
  }
  foreach($rel in @('EXTRACAO/EXT.qvw','TRANSFORMACAO/TRANSF.qvw','PAINEL/PAINEL.qvw')){$protected.Add((Join-Path $artifacts $rel))}
  foreach($path in $protected){
    # Read locks deny writes while COM opens only the disposable copy.
    $locks.Add([IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read))
    $before+=@{path=$path;sha256=(Sha $path);bytes=(Get-Item -LiteralPath $path).Length}
  }
  $null=New-Item -ItemType Directory -Path $evidence -Force
  $run=Join-Path $evidence ('VIS05_INSPECT_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,12))
  $null=New-Item -ItemType Directory -Path $run
  $copy=Join-Path $run 'SAD_VIS05_INSPECTION_COPY.qvw'
  [IO.File]::Copy($source,$copy,$false)
  (Get-Item -LiteralPath $copy).IsReadOnly=$true
  if((Sha $copy) -cne $contract.source_sha256){throw 'Copy SHA mismatch'}
  $report.git_head=$head;$report.contract_sha256=Sha $contractPath;$report.script_sha256=Sha $PSCommandPath
  $report.artifact_root=$artifacts
  $report.source_sha256=Sha $source;$report.protected_before=$before
  Json (Join-Path $run 'contract.json') $contract
  Json (Join-Path $run 'inspection.json') $report
  Write-Host "EVIDENCE_DIR=$run"
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $script:doc=$app.OpenDoc($copy)
  if($null -eq $script:doc){throw 'OpenDoc returned null'}
  if([int]$script:doc.NoOfSheets() -ne 3){throw 'Expected three sheets'}
  if($Mode -ceq 'WindowDiagnostic'){
    $null=CaptureSheet 0 '' -Diagnostic
    $report.status='WINDOW_DIAGNOSTIC_COLLECTED_NOT_CAPTURE_APPROVAL'
    $exitCode=0
  }else{
  $charts=@{};$chartSheets=@{};$inventory=[Collections.Generic.List[object]]::new()
  for($sheetIndex=0;$sheetIndex -lt 3;$sheetIndex++){
    foreach($obj in @($script:doc.GetSheet($sheetIndex).GetSheetObjects())){
      if($null -eq $obj){continue}
      $raw=[string]$obj.GetObjectID();$id=$raw -replace '^Document\\',''
      $inventory.Add(@{id=$id;raw_id=$raw;sheet=$sheetIndex})
      if($id -cmatch '^CH0[1-9]$'){
        if($charts.ContainsKey($id)){throw "Duplicate chart: $id"}
        $charts[$id]=$obj;$chartSheets[$id]=$sheetIndex
      }
    }
  }
  if($charts.Count -ne 9){throw 'Nine CH01-CH09 charts were not found'}
  $extraCharts=@($inventory.ToArray() | Where-Object {$_.id -cmatch '^CH[0-9]+$' -and -not $charts.ContainsKey($_.id)})
  if($extraCharts.Count -gt 0){throw 'Unexpected additional chart IDs; scope requires nine'}
  $report.sheet_objects=@($inventory.ToArray())
  $objects=@()
  foreach($spec in @($contract.objects)){
    if($chartSheets[$spec.id] -ne [int]$spec.sheet){throw "Chart on unexpected sheet: $($spec.id)"}
    $objects+=ChartRecord $charts[$spec.id] $spec.id $chartSheets[$spec.id]
    $report.objects=$objects
  }
  $report.objects=$objects
  # No unsupported NoOfTables()/TableName() chart expressions: script presence is not a live table audit.
  $report.live_table_structure_status='INCONCLUSIVE_NO_VERIFIED_COM_TABLE_ENUMERATOR'
  $report.error_message_text_status='INCONCLUSIVE_COM_OVERRIDE_ITEM_MAPPING_NOT_VERIFIED'
  $report.chart_cell_data_status='NOT_EXPORTED_ENGINE_PROBES_ONLY'
  if($Mode -ceq 'Scenarios'){
    foreach($scenario in @($contract.scenarios)){
      $report.active_scenario=$scenario.id
      $state=SelectState $scenario $contract
      $item=[ordered]@{id=$scenario.id;selections=$scenario.selections;selection_verified=$true;current_selections=$state;probes=(EngineProbes $contract);guards=[ordered]@{};captures=@();status='OBSERVED'}
      foreach($id in @('CH04','CH05','CH09')){$item.guards[$id]=Guard $charts[$id]}
      foreach($property in $scenario.expected.PSObject.Properties){
        $raw=[string]$item.probes[$property.Name].raw
        if($raw -notmatch '^-?[0-9]+$' -or [decimal]$raw -ne [decimal]$property.Value){$item.status='FAIL_ENGINE_ORACLE';$results.Add($item);throw "Oracle mismatch: $($scenario.id)/$($property.Name)=$raw"}
      }
      foreach($property in $scenario.guards.PSObject.Properties){
        $g=$item.guards[$property.Name];$raw=[string]$g.raw
        if($g.status -cne 'READ_BACK' -or $raw -notmatch '^(0|-1|1)$'){$item.status='INCONCLUSIVE_GUARD';$results.Add($item);throw "Guard not readable: $($scenario.id)/$($property.Name)"}
        if(($raw -ne '0') -ne [bool]$property.Value){$item.status='FAIL_GUARD';$results.Add($item);throw "Guard mismatch: $($scenario.id)/$($property.Name)"}
      }
      $results.Add($item);$report.scenarios=@($results.ToArray())
      Json (Join-Path $run 'inspection.json') $report
      if($Capture){foreach($index in @($scenario.capture_sheets)){$item.captures+=CaptureSheet ([int]$index) (Join-Path $run ($scenario.id+'_sheet'+$index+'.png'))}}
      Json (Join-Path $run 'inspection.json') $report
    }
    if($ManualSortReview){
      $null=$script:doc.ClearAll()
      $report.manual_sort_properties_before=ChartRecord $charts['CH07'] 'CH07' 2
      $report.manual_sort_before=CaptureSheet 2 (Join-Path $run 'SORT_before_sheet2.png')
      Write-Host 'On the READ-ONLY COPY only: reverse CH07 sort via QlikView GUI. Do not save, reload, rename labels or change its expression. Then return to this console.'
      $answer=Read-Host 'Type SORT_CHANGED after the action, or SKIP'
      if($answer -ceq 'SORT_CHANGED'){
        $report.manual_sort_after=CaptureSheet 2 (Join-Path $run 'SORT_after_sheet2.png')
        $report.manual_sort_properties=ChartRecord $charts['CH07'] 'CH07' 2
        $report.manual_sort_status='OPERATOR_REPORTED_SORT_CHANGED_PENDING_VISUAL_REVIEW'
      }else{$report.manual_sort_status='SKIPPED_NOT_APPROVED'}
    }
  }elseif($Capture){foreach($i in 0..2){$report['inventory_capture_'+$i]=CaptureSheet $i (Join-Path $run ('INVENTORY_sheet'+$i+'.png'))}}
  $report.status=if($Mode -ceq 'Inventory'){'INVENTORY_COLLECTED_NOT_FUNCTIONAL_PASS'}else{'SCENARIOS_ENGINE_CHECKED_VISUAL_REVIEW_PENDING'}
  $exitCode=0
  }
}catch{
  $report.failure=$_.Exception.Message
  $report.status='BLOCKED_OR_INCONCLUSIVE'
  Write-Host ('DETAIL='+$report.failure)
}finally{
  $cleanupErrors=@()
  if($null -ne $script:doc){
    try{$null=$script:doc.CloseDoc()}catch{$cleanupErrors+=$_.Exception.Message}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($script:doc)}catch{$cleanupErrors+=$_.Exception.Message}
  }
  if($null -ne $app){
    try{$null=$app.Quit()}catch{$cleanupErrors+=$_.Exception.Message}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{$cleanupErrors+=$_.Exception.Message}
  }
  try{
    $after=@();foreach($row in $before){$after+=@{path=$row.path;sha256=(Sha $row.path);bytes=(Get-Item -LiteralPath $row.path).Length}}
    $report.protected_after=$after
    $changed=@($before | Where-Object {
      $original=$_
      $matches=@($after | Where-Object {$_.path -ceq $original.path -and $_.sha256 -ceq $original.sha256 -and $_.bytes -eq $original.bytes})
      $matches.Count -ne 1
    })
    $report.integrity_verified=($before.Count -eq 26 -and $after.Count -eq 26 -and $changed.Count -eq 0)
    if($null -ne $copy){$report.copy_sha256_after=Sha $copy;if($report.copy_sha256_after -cne $contract.source_sha256){throw 'READ_ONLY_COPY_BYTES_CHANGED'}}
    if($before.Count -eq 26 -and -not $report.integrity_verified){throw 'PROTECTED_HASH_SET_CHANGED'}
  }catch{$report.integrity_failure=$_.Exception.Message;$report.status='BLOCKED_INTEGRITY';$exitCode=2}
  foreach($handle in $locks){$handle.Dispose()}
  $report.cleanup_ok=($cleanupErrors.Count -eq 0);$report.cleanup_errors=$cleanupErrors
  if(-not $report.cleanup_ok){$report.status='BLOCKED_CLEANUP';$exitCode=2}
  $report.scenarios=@($results.ToArray());$report.finished=(Get-Date).ToString('o')
  if($null -ne $run){
    Json (Join-Path $run 'inspection.json') $report
    @($report.scenarios | ForEach-Object {[pscustomobject]@{Scenario=$_.id;Status=$_.status;Selections=$_.current_selections;VisualReview='PENDING'}}) | Export-Csv -LiteralPath (Join-Path $run 'scenario_summary.csv') -NoTypeInformation -Encoding UTF8
    $manifest=@(Get-ChildItem -LiteralPath $run -File | ForEach-Object {@{file=$_.Name;sha256=(Sha $_.FullName);bytes=$_.Length}})
    Json (Join-Path $run 'sha256_manifest.json') $manifest
    Write-Host ('REPORT='+(Join-Path $run 'inspection.json'))
  }
  Write-Host ('VERDICT='+$report.status)
  Write-Host 'STOP=True RELOAD_CALLED=False SAVE_CALLED=False GLOBAL_APPROVAL=False'
}
exit $exitCode
