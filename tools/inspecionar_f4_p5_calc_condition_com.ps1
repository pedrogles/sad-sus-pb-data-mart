# SAD SUS PB — F4-P5 chart calculation-condition COM API discovery.
# EXPERIMENT: temporary copy only; neutral expression '1', no UI PASS, KPI, reload or QVD.
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
if(-not(Test-Path -LiteralPath $preparer -PathType Leaf)){throw 'PREPARE_RUNNER_MISSING'}
$prepareLines=@(& $preparer -SourceQvw $SourceQvw -F4Dir $F4Dir -Root $repo)
if($prepareLines -notcontains 'FINAL_VERDICT=PREPARED_UI_COPY_NOT_EXECUTED'){throw 'PREPARE_GATE_FAILED'}
$dirLines=@($prepareLines|Where-Object{$_ -like 'TRIAL_DIR=*'})
if($dirLines.Count -ne 1){throw 'TRIAL_DIR_MISSING'}
$trial=$dirLines[0].Substring(10)
$copy=Join-Path $trial 'F4_P5_UI_GUARD_DISPOSABLE.qvw'
$log=Join-Path $trial 'chart_com_api_inventory.txt'
$qv=$null;$doc=$null;$sheet=$null;$chart=$null
$failure=$null;$saved=$false
$lines=[System.Collections.Generic.List[string]]::new()
function Log([string]$msg){
  [void]$script:lines.Add($msg)
  Write-Output $msg
}
function Names($obj){
  if($null -eq $obj){return @()}
  return @( $obj | Get-Member -MemberType Property,NoteProperty -ErrorAction Stop |
    Select-Object -ExpandProperty Name | Sort-Object -Unique )
}
try{
  Log 'MODE=F4_P5_CHART_CALC_CONDITION_COM_API_DISCOVERY_ONLY'
  Log ('TRIAL_DIR='+$trial)
  $qv=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$qv.OpenDoc($copy,'','')
  if($null -eq $doc){throw 'COM_OPEN_TEMP_COPY_FAILED'}
  if([string]$doc.Evaluate('Count(F4_RD_IDENT)') -cne '566672' -or
     [string]$doc.Evaluate('Count(P6_POP_ROW_DEBUG)') -cne '669'){
     throw 'BASELINE_MISMATCH'
  }
  $sheet=$doc.GetSheet(0)
  if($null -eq $sheet -or -not [Runtime.InteropServices.Marshal]::IsComObject($sheet)){
    throw 'SHEET_NOT_COM_DISPATCH'
  }
  $methods=@($sheet | Get-Member -MemberType Method | Select-Object -ExpandProperty Name)
  if($methods -cnotcontains 'CreateStraightTable'){throw 'SHEET_CREATE_STRAIGHT_TABLE_UNAVAILABLE'}
  Log 'SHEET_CREATE_STRAIGHT_TABLE_AVAILABLE=True'
  $chart=$sheet.CreateStraightTable()
  if($null -eq $chart){throw 'CHART_CREATE_RETURNED_NULL'}
  $chartMethods=@($chart | Get-Member -MemberType Method | Select-Object -ExpandProperty Name)
  Log ('CHART_OBJECT_TYPE='+$chart.GetType().FullName)
  Log ('CHART_METHODS='+($chartMethods -join ','))
  if($chartMethods -cnotcontains 'AddExpression' -or $chartMethods -cnotcontains 'AddDimension' -or
     $chartMethods -cnotcontains 'GetProperties' -or $chartMethods -cnotcontains 'SetProperties'){
     throw 'CHART_REQUIRED_METHODS_UNAVAILABLE'
  }
  [void]$chart.AddDimension('F4_RD_PROC_REA')
  [void]$chart.AddExpression('1')
  $props=$chart.GetProperties()
  if($null -eq $props){throw 'CHART_PROPERTIES_NULL'}
  Log ('CHART_TOP_LEVEL_PROPERTIES='+((Names $props) -join ','))
  foreach($key in @('ChartProperties','Layout','General','CalcCondition','CalculationCondition','Expressions')){
    try{
      $item=$props.$key
      if($null -ne $item){
        Log ('CHART_PROPERTY_BRANCH_'+$key+'='+((Names $item) -join ','))
      }else{
        Log ('CHART_PROPERTY_BRANCH_'+$key+'=NULL_OR_NOT_FOUND')
      }
    }catch{
      Log ('CHART_PROPERTY_BRANCH_'+$key+'=UNAVAILABLE')
    }
  }
  [void]$doc.Save()
  $saved=$true
  Log 'DISPOSABLE_CHART_SAVED=True'
  Log 'CHART_CALCULATION_CONDITION=NOT_SET_NOT_TESTED'
}catch{
  $failure=$_.Exception.Message
  Log ('GATE=FAIL_CLOSED_'+$failure)
}finally{
  if($null -ne $doc){try{[void]$doc.CloseDoc()}catch{Log ('CLOSE_WARNING='+$_.Exception.Message)}}
  if($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)){
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
  }
  if($saved){
    try{
      $checks=@(& $preparer -TrialDir $trial)
      foreach($c in $checks){Log $c}
      if($checks -notcontains 'FINAL_VERDICT=PASS_ARTIFACT_INTEGRITY_ONLY_UI_SCREENSHOTS_PENDING'){
        if(-not $failure){$failure='POST_SAVE_IMMUTABILITY_FAIL'}
      }
    }catch{
      if(-not $failure){$failure='POST_SAVE_VERIFY_ERROR_'+$_.Exception.Message}
    }
  }
  Log 'RELOAD_EXECUTED=False'
  Log 'QVD_WRITES=0'
  Log 'KPI_OR_PHYSICAL_P5_CONTRACT=NOT_APPROVED'
  $lines|Set-Content -LiteralPath $log -Encoding UTF8
  Write-Output ('COM_API_INVENTORY_FILE='+$log)
}
if($failure){
  Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$failure)
  exit 1
}
Write-Output 'FINAL_VERDICT=DIAG_COM_CHART_SURFACE_CAPTURED_CALC_CONDITION_NOT_TESTED'
