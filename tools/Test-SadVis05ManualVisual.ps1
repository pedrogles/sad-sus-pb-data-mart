#requires -Version 5.1
<# Synthetic protocol/file tests. No runner body, QlikView, COM or Windows API. #>
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunnerPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($RunnerPath,[ref]$tokens,[ref]$errors)
if(@($errors).Count -gt 0){throw 'Runner parser failed'}
foreach($name in @('Sha','Json','Read-ManualPng','Get-ManualVisualPlan','Invoke-ManualVisualReview')){
  $fn=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true)
  if($null -eq $fn){throw ('Missing function: '+$name)}
  . ([scriptblock]::Create($fn.Extent.Text))
}
$plan=@(Get-ManualVisualPlan)
if(($plan.id -join ',') -cne 'V1_BASELINE,V1_SORT,V2_EQ,V3_NE,V4_YEAR_2018,V5_SERV_250750'){throw 'Wrong bounded visual plan'}
if($plan[2].selections.MVP_FI_RES_SERV_CLASS -cne 'RES_EQ_SERV' -or
   $plan[3].selections.MVP_FI_RES_SERV_CLASS -cne 'RES_NE_SERV' -or
   $plan[4].selections.PERIODO_ANO -cne '2018' -or
   $plan[5].selections.SERV_COD_DATASUS_6 -cne '250750'){throw 'Wrong selected states'}
$fn=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Invoke-ManualVisualReview'},$true)
if($fn.Extent.Text -match 'EngineProbes|ChartRecord|CaptureSheet|\bGuard\b|SetProperties|\.Save|\.Reload'){throw 'Manual review must not invoke old gates or mutations'}
$branch=$ast.Find({param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Clauses[0].Item1.Extent.Text -ceq '$Mode -ceq ''ManualVisual'''},$true)
if($null -eq $branch){throw 'Manual dispatch missing'}
if($branch.Clauses[0].Item2.Extent.Text -match 'EngineProbes|ChartRecord|CaptureSheet|GetSheetObjects|GetProperties'){throw 'Manual dispatch must skip inventory/probes/capture'}
$tmp=Join-Path ([IO.Path]::GetTempPath()) ('sad-manual-unit-'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $tmp
try{
  # A header fixture checks only identification, not PNG decoding/visual validity.
  [byte[]]$header=@(137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,3,32,0,0,2,88)
  $png=Join-Path $tmp 'header.png'
  [IO.File]::WriteAllBytes($png,$header)
  $meta=Read-ManualPng $png
  if($meta.status -cne 'MANUAL_PNG_PENDING_PIXEL_AND_IDENTITY_REVIEW'){throw 'No automatic visual acceptance allowed'}
  foreach($bad in @([byte[]]@(1,2,3),[byte[]](0..23))){
    [IO.File]::WriteAllBytes($png,$bad)
    $rejected=$false
    try{$null=Read-ManualPng $png}catch{$rejected=$true}
    if(-not $rejected){throw 'Invalid evidence accepted'}
  }
  # Test one step with mocked session/console; never instantiate a COM object.
  function Get-ManualVisualPlan {return @(@{id='UNIT';sheet=2;selections=[pscustomobject]@{};token='CAPTURED';instruction='Synthetic only'})}
  function SelectState($scenario,$contract){return '-'}
  $sheet=[pscustomobject]@{}
  $sheet | Add-Member ScriptMethod Activate {return $null}
  $script:doc=[pscustomobject]@{}
  $script:doc | Add-Member ScriptMethod GetSheet {param($index) return $sheet}
  $script:doc | Add-Member ScriptMethod Evaluate {param($expression) return $script:selectionAfter}
  function Read-Host($Prompt){
    if($script:withPng){[IO.File]::WriteAllBytes((Join-Path $script:caseDir 'UNIT.png'),$header)}
    return $script:response
  }
  $cases=@(
    @{name='collected';response='CAPTURED';image=$true;selection='-';status='COLLECTED_PENDING_VISUAL_REVIEW';throws=$false},
    @{name='missing_png';response='CAPTURED';image=$false;selection='-';status='INCONCLUSIVE_MISSING_PNG';throws=$true},
    @{name='selection_changed';response='CAPTURED';image=$true;selection='PERIODO_ANO=2018';status='BLOCKED_SELECTION_CHANGED';throws=$true},
    @{name='operator_stop';response='STOP';image=$true;selection='-';status='STOPPED_BY_OPERATOR';throws=$true}
  )
  foreach($case in $cases){
    $script:caseDir=Join-Path $tmp $case.name
    $null=New-Item -ItemType Directory -Path $script:caseDir
    $script:copy=Join-Path $script:caseDir 'FAKE_COPY_NOT_A_QVW'
    $script:report=[ordered]@{manual_visual_steps=@()}
    $script:withPng=$case.image;$script:response=$case.response;$script:selectionAfter=$case.selection
    $threw=$false
    try{Invoke-ManualVisualReview ([pscustomobject]@{}) $script:caseDir}catch{$threw=$true}
    $row=$script:report.manual_visual_steps[0]
    if($threw -ne $case.throws -or $row.status -cne $case.status -or $row.visual_accepted){throw ('Protocol test failed: '+$case.name)}
    if($case.image -and -not $row.Contains('capture')){throw 'Evidence lost on stop/failure'}
  }
  Write-Output 'MANUAL_VISUAL_SYNTHETIC_PROTOCOL=PASS (4 cases, invalid PNG rejection, bounded plan, static isolation)'
  Write-Output 'WINDOWS_COM_MANUAL_CAPTURE_AND_PIXEL_REVIEW=NOT_RUN'
}finally{
  Remove-Item -LiteralPath $tmp -Recurse -Force
}
