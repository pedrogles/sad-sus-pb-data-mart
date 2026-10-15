# SAD SUS PB — F4-P5 chart Calculation Condition: TEMP-only neutral expression.
# Does not implement KPI, physical P5, a fact/link QVD, or a permanent panel.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$SourceQvw,
 [Parameter(Mandatory=$true)][string]$F4Dir,
 [string]$Root=(Get-Location).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$preparer=Join-Path $repo 'tools\preparar_f4_p5_ui_guardas_qlik.ps1'
if(-not(Test-Path -LiteralPath $preparer -PathType Leaf)){throw 'PREPARER_NOT_FOUND'}
$prepared=@(& $preparer -SourceQvw $SourceQvw -F4Dir $F4Dir -Root $repo)
if($prepared -notcontains 'FINAL_VERDICT=PREPARED_UI_COPY_NOT_EXECUTED'){
 throw 'BLOCKED_PREPARE_GATE_FAILED'
}
$trialLines=@($prepared|Where-Object{$_ -like 'TRIAL_DIR=*'})
if($trialLines.Count -ne 1){throw 'BLOCKED_TEMP_TRIAL_DIR_MISSING'}
$trial=$trialLines[0].Substring('TRIAL_DIR='.Length)
$copy=Join-Path $trial 'F4_P5_UI_GUARD_DISPOSABLE.qvw'
$evidence=Join-Path $trial 'chart_evidence'
New-Item -ItemType Directory -Path $evidence -ErrorAction Stop|Out-Null
$condition='=If(GetSelectedCount(F4_RD_PROC_REA)=0,1,0)'
$qv=$null;$doc=$null;$sheet=$null;$chart=$null
$failure=$null;$saved=$false
$states=[System.Collections.Generic.List[object]]::new()
$items=[System.Collections.Generic.List[object]]::new()
function ReadQ([string]$expression){return [string]$script:doc.Evaluate($expression)}
function AssertQ([string]$label,[string]$expression,[string]$want){
 $actual=ReadQ $expression
 if($actual -cne $want){throw ("BLOCKED_"+$label+"_EXPECTED_"+$want+"_ACTUAL_"+$actual)}
 Write-Output ("CHECK "+$label+"="+$actual)
}
function Place($obj,[int]$x,[int]$y,[int]$w,[int]$h){
 $f=$obj.GetFrameDef();$r=$f.Rect
 $r.Left=$x;$r.Top=$y;$r.Width=$w;$r.Height=$h
 [void]$obj.SetFrameDef($f)
}
function AddText([string]$key,[string]$content,[string]$when,[int]$top){
 $obj=$script:sheet.CreateTextObject()
 if($null -eq $obj){throw "TEXT_CREATE_NULL=$key"}
 $p=$obj.GetProperties();$p.Layout.Text.v=$content
 if($when -eq ''){$p.Layout.Frame.Show.Always=$true}
 else{$p.Layout.Frame.Show.Always=$false;$p.Layout.Frame.Show.Expression.v=$when}
 [void]$obj.SetProperties($p)
 Place $obj 245 $top 875 57
 $back=$obj.GetProperties()
 if([string]$back.Layout.Text.v -cne $content -or
  [bool]$back.Layout.Frame.Show.Always -ne ($when -eq '') -or
  ($when -ne '' -and [string]$back.Layout.Frame.Show.Expression.v -cne $when)){
   throw "TEXT_READBACK_FAILED=$key"
 }
 [void]$script:items.Add([pscustomobject]@{name=$key;id=[string]$obj.GetObjectID();content=$content;show=$when;readback='PASS_COM_ONLY'})
 Write-Output ("TEXT_OBJECT=$key READBACK=PASS_COM_ONLY")
}
function AddList([string]$field,[int]$top){
 $obj=$script:sheet.CreateListBox()
 if($null -eq $obj){throw "LIST_CREATE_NULL=$field"}
 $p=$obj.GetProperties();$p.Def.Name=$field
 [void]$obj.SetProperties($p)
 Place $obj 12 $top 210 215
 if([string]$obj.GetProperties().Def.Name -cne $field){throw "LIST_READBACK_FAILED=$field"}
 Write-Output ("LIST_BOX=$field READBACK=PASS_COM_ONLY")
}
function SelectValue([string]$field,[string]$value){
 $f=$null
 try{
  $f=$script:doc.GetField($field)
  if($null -eq $f){throw "FIELD_MISSING=$field"}
  [void]$f.Select($value)
 }finally{
  if($null -ne $f -and [Runtime.InteropServices.Marshal]::IsComObject($f)){
   [void][Runtime.InteropServices.Marshal]::ReleaseComObject($f)
  }
 }
}
function VerifyChartCondition {
 $p=$script:chart.GetProperties()
 if($null -eq $p -or $null -eq $p.EvaluationCondition){throw 'EVALUATION_CONDITION_PROPERTY_MISSING'}
 $actual=[string]$p.EvaluationCondition.v
 if($actual -cne $script:condition){throw "EVALUATION_CONDITION_READBACK_FAILED=$actual"}
}
function Scenario([string]$label,[string]$proc,[string]$service,[string]$allow){
 AssertQ ($label+'_PROC') 'GetSelectedCount(F4_RD_PROC_REA)' $proc
 AssertQ ($label+'_SERVICE') 'GetSelectedCount(P6_SERV_DATASUS_6)' $service
 AssertQ ($label+'_CALC') ($script:condition.Substring(1)) $allow
 VerifyChartCondition
 $rows='UNAVAILABLE_DIAGNOSTIC_ONLY'
 try{$rows=[string]$script:chart.GetNoOfRows()}catch{}
 [void]$script:states.Add([pscustomobject]@{
  state=$label;proc=$proc;service=$service;calc_expression=$allow;
  chart_rows_diagnostic=$rows;
  screenshot='PENDING';visual_audit='NOT_PERFORMED'
 })
 Write-Output ("SCENARIO=$label COM_CONDITION=$allow CHART_ROW_DIAGNOSTIC=$rows")
}
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SadP5ChartWin {
 [StructLayout(LayoutKind.Sequential)]
 public struct RECT {public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr handle);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr handle,out RECT value);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr handle,out uint pid);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr handle);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr handle,int cmd);
}
'@
function Capture([string]$state){
 $process=@(Get-Process|Where-Object{
   $_.MainWindowHandle -ne [IntPtr]::Zero -and
   $_.ProcessName -match '^(qv|qlikview)$' -and
   $_.MainWindowTitle -like '*F4_P5_UI_GUARD_DISPOSABLE*'
 })
 if($process.Count -ne 1){throw ("BLOCKED_QV_WINDOW_COUNT="+$process.Count)}
 $win=$process[0].MainWindowHandle
 if([SadP5ChartWin]::IsIconic($win)){[void][SadP5ChartWin]::ShowWindow($win,9)}
 [void][SadP5ChartWin]::SetForegroundWindow($win)
 Start-Sleep -Milliseconds 900
 $front=[SadP5ChartWin]::GetForegroundWindow()
 $pidValue=[uint32]0
 [void][SadP5ChartWin]::GetWindowThreadProcessId($front,[ref]$pidValue)
 if($front -ne $win -or $pidValue -ne [uint32]$process[0].Id){
   throw 'BLOCKED_SCREENSHOT_WRONG_FOREGROUND_WINDOW'
 }
 $rect=New-Object SadP5ChartWin+RECT
 if(-not [SadP5ChartWin]::GetWindowRect($win,[ref]$rect)){throw 'SCREENSHOT_RECT_FAILED'}
 $w=$rect.Right-$rect.Left;$h=$rect.Bottom-$rect.Top
 if($w -lt 650 -or $h -lt 590 -or $w -gt 5000 -or $h -gt 3500){
   throw ("SCREENSHOT_DIMENSIONS_INVALID_"+$w+"x"+$h)
 }
 $bmp=[System.Drawing.Bitmap]::new($w,$h)
 $file=Join-Path $script:evidence ($state+'.png')
 try{
  $graphics=[System.Drawing.Graphics]::FromImage($bmp)
  try{
   $graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,([System.Drawing.Size]::new($w,$h)))
  }finally{$graphics.Dispose()}
  $bmp.Save($file,[System.Drawing.Imaging.ImageFormat]::Png)
 }finally{$bmp.Dispose()}
 $script:states[$script:states.Count-1].screenshot=$file
 Write-Output ("SCREENSHOT=$state SHA256="+(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash)
}
try{
 foreach($line in $prepared){Write-Output $line}
 $qv=New-Object -ComObject 'QlikTech.QlikView'
 $doc=$qv.OpenDoc($copy,'','')
 if($null -eq $doc){throw 'COM_OPEN_TEMP_COPY_NULL'}
 $sheet=$doc.GetSheet(0)
 if($null -eq $sheet -or -not [Runtime.InteropServices.Marshal]::IsComObject($sheet)){
   throw 'COM_SHEET_NOT_AVAILABLE'
 }
 $methods=@($sheet|Get-Member -MemberType Method|Select-Object -ExpandProperty Name)
 foreach($need in @('CreateStraightTable','CreateListBox','CreateTextObject')){
   if($methods -cnotcontains $need){throw ("COM_SHEET_METHOD_MISSING="+$need)}
 }
 [void]$doc.ClearAll()
 AssertQ 'RD_BASE' 'Count(F4_RD_IDENT)' '566672'
 AssertQ 'POP_BASE' 'Count(P6_POP_ROW_DEBUG)' '669'
 AddList 'F4_RD_PROC_REA' 125
 AddList 'P6_SERV_DATASUS_6' 350
 AddText 'HEADER' 'F4-P5: GATE DE CALCULO EM GRAFICO - PROVA TEMPORARIA' '' 6
 AddText 'CAVEAT' 'SEM KPI APROVADO; CONDICAO TESTADA SOMENTE COM EXPRESSAO 1' '' 70
 AddText 'WARNING' 'B/REL: FILTRO PROC_ATIVO, CALCULO DO GRAFICO NEGADO' '=If(GetSelectedCount(F4_RD_PROC_REA)>0,1,0)' 535
 $chart=$sheet.CreateStraightTable()
 if($null -eq $chart){throw 'CHART_CREATE_NULL'}
 [void]$chart.AddDimension('P6_ANO_ANO')
 [void]$chart.AddExpression('1')
 $cp=$chart.GetProperties()
 if($null -eq $cp -or $null -eq $cp.EvaluationCondition){
   throw 'CHART_EVALUATION_CONDITION_MISSING'
 }
 $ecMembers=@($cp.EvaluationCondition|Get-Member -MemberType Property,NoteProperty|Select-Object -ExpandProperty Name)
 if($ecMembers -cnotcontains 'v'){throw 'CHART_EVALUATION_CONDITION_V_MISSING'}
 $cp.EvaluationCondition.v=$condition
 [void]$chart.SetProperties($cp)
 VerifyChartCondition
 Place $chart 245 145 870 376
 $readback=$chart.GetProperties()
 Write-Output ('CHART_CALC_CONDITION_READBACK='+[string]$readback.EvaluationCondition.v)
 [void]$doc.Save()
 $saved=$true
 Write-Output 'TEMP_CHART_SAVED=True'
 Scenario 'S0_BASELINE' '0' '0' '1'
 Capture 'S0_BASELINE'
 SelectValue 'F4_RD_PROC_REA' '0201010038'
 Scenario 'S1_PROCEDURE_BLOCK' '1' '0' '0'
 Capture 'S1_PROCEDURE_BLOCK'
 [void]$doc.ClearAll()
 Scenario 'S2_CLEAR' '0' '0' '1'
 Capture 'S2_CLEAR'
 SelectValue 'P6_SERV_DATASUS_6' '250750'
 Scenario 'S3_SERVICE_COMPATIBLE_WITH_REL' '0' '1' '1'
 Capture 'S3_SERVICE_COMPATIBLE_WITH_REL'
 [void]$doc.ClearAll()
 Scenario 'S4_RESTORE' '0' '0' '1'
 Capture 'S4_RESTORE'
 $h0=(Get-FileHash (Join-Path $evidence 'S0_BASELINE.png') -Algorithm SHA256).Hash
 $h1=(Get-FileHash (Join-Path $evidence 'S1_PROCEDURE_BLOCK.png') -Algorithm SHA256).Hash
 if($h0 -ceq $h1){throw 'SCREEN_PIXELS_UNCHANGED_BETWEEN_ALLOWED_AND_BLOCKED'}
 Write-Output 'SCREEN_PIXELS_DIFFER_ALLOWED_VS_BLOCKED=True_NOT_VISUAL_VERIFICATION'
}catch{
 $failure=$_.Exception.Message
 Write-Output ('GATE=FAIL_CLOSED_'+$failure)
}finally{
 if($null -ne $doc){try{[void]$doc.CloseDoc()}catch{Write-Output ('CLOSE_WARNING='+$_.Exception.Message)}}
 if($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)){
  [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
 }
 $result=[pscustomobject]@{
  trial_qvw=$copy;source_qvw=$SourceQvw;
  condition=$condition;error=$failure;temp_saved=$saved;
  chart_neutral_expression='1';chart_dimension='P6_ANO_ANO';
  objects=@($items.ToArray());scenarios=@($states.ToArray());
  claims='COM_CHECKS_AND_SCREENSHOTS_ONLY_NOT_A_VISUAL_PASS'
 }
 $result|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $evidence 'audit.json') -Encoding UTF8
 if($saved){
  try{
   $verified=@(& $preparer -TrialDir $trial)
   foreach($line in $verified){Write-Output $line}
   if($verified -notcontains 'FINAL_VERDICT=PASS_ARTIFACT_INTEGRITY_ONLY_UI_SCREENSHOTS_PENDING'){
    if(-not $failure){$failure='ARTIFACT_IMMUTABILITY_FAILED'}
   }
  }catch{if(-not $failure){$failure='POST_SAVE_VERIFY_ERROR_'+$_.Exception.Message}}
 }
 try{
  $zip=Join-Path $trial 'F4_P5_CHART_CONDITION_EVIDENCE.zip'
  Compress-Archive -Path (Join-Path $evidence '*') -DestinationPath $zip -ErrorAction Stop
  Write-Output ('EVIDENCE_ZIP='+$zip)
  Write-Output ('EVIDENCE_SHA256='+(Get-FileHash $zip -Algorithm SHA256).Hash)
 }catch{if(-not $failure){$failure='ZIP_EVIDENCE_ERROR_'+$_.Exception.Message}}
 Write-Output 'RELOAD_EXECUTED=False QVD_WRITES=0'
 Write-Output 'F4_P5_PHYSICAL_FILTERS=NOT_TESTED'
 Write-Output 'CHART_RENDERING=SCREENSHOTS_PENDING_INDEPENDENT_VISUAL_AUDIT'
}
if($failure){Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$failure);exit 1}
Write-Output 'FINAL_VERDICT=PASS_CHART_CALC_CONDITION_COM_AND_SCREENSHOTS_VISUAL_AUDIT_PENDING'
