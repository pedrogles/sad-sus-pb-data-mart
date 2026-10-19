# Gate C2-W: one-time layout correction to a COPY of the C2-V evidence QVW.
# No undocumented Size-to-Data COM property is guessed. Final toggle is GUI-only on the NEW copy.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$branch='test/phase-viii-c2w-t26-widths-manual-20261019'
$rel='tools/Invoke-SadPhaseViiiC2wT26Widths.ps1'
$self=Join-Path $repo $rel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'BLOCKED_SELF_PATH'}
$currentBranch=@(& git -C $repo branch --show-current 2>$null)
$gitHead=@(& git -C $repo rev-parse HEAD 2>$null)
if($LASTEXITCODE -ne 0 -or $currentBranch.Count -ne 1 -or $currentBranch[0] -cne $branch -or
   $gitHead.Count -ne 1 -or $gitHead[0] -notmatch '^[0-9a-f]{40}$'){throw 'BLOCKED_GIT_IDENTITY'}
& git -C $repo merge-base --is-ancestor '337943d5c5b77067f842902fc679dbb68db87020' HEAD
if($LASTEXITCODE -ne 0){throw 'BLOCKED_BASE_MAIN_NOT_ANCESTOR'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $rel)
if($tracked.Count -ne 1 -or $dirty.Count -ne 0){throw 'BLOCKED_SCRIPT_NOT_COMMITTED_CLEAN'}

$tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
$src=Join-Path $tempRoot 'SAD_VIII_C2V_83cc8d984d9e438eb76a71d1ff8f6d0f\SAD_C2V_T26_DISPOSABLE.qvw'
$upstream=Join-Path $tempRoot 'SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac\SAD_VIII_T24_ANNUAL_TEST.qvw'
if(-not(Test-Path -LiteralPath $src -PathType Leaf) -or -not(Test-Path -LiteralPath $upstream -PathType Leaf)){throw 'BLOCKED_ORIGINAL_TEMP_QVW_MISSING'}
$sourceHash=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
$upstreamHash=(Get-FileHash -LiteralPath $upstream -Algorithm SHA256).Hash
if($upstreamHash -cne '7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E'){throw 'BLOCKED_UPSTREAM_T24_SHA_DRIFT'}
# Only a TEMP QVW copy will be opened for editing; require original evidence GUI to be closed first.
$openOriginal=@(Get-Process | Where-Object {
  $_.MainWindowHandle -ne [IntPtr]::Zero -and
  $_.ProcessName -match '^(qv|qlikview)$' -and
  $_.MainWindowTitle -like '*SAD_C2V_T26_DISPOSABLE*'
})
if($openOriginal.Count -gt 0){throw 'BLOCKED_CLOSE_C2V_EVIDENCE_QVW_WITHOUT_SAVING_FIRST'}

function Snapshot([string]$kind) {
  $files=@()
  if($kind -ceq 'QVD') {
    $ext=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO/QVD') -File -Filter '*.qvd')
    $tr=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO/QVD') -File -Filter '*.qvd')
    if($ext.Count -ne 10 -or $tr.Count -ne 12){throw 'BLOCKED_EXPECTED_22_QVD_COUNT'}
    $files=@($ext)+@($tr)
  } else {
    foreach($p in @('EXTRACAO/EXT.qvw','TRANSFORMACAO/TRANSF.qvw','PAINEL/PAINEL.qvw')){
      $f=Join-Path $repo $p
      if(Test-Path -LiteralPath $f -PathType Leaf){$files+=Get-Item -LiteralPath $f}
    }
  }
  $data=@()
  foreach($i in $files){$data+=[pscustomobject]@{File=$i.FullName;Bytes=$i.Length;SHA256=(Get-FileHash -LiteralPath $i.FullName -Algorithm SHA256).Hash}}
  return @($data|Sort-Object File)
}
function Same($a,$b){
  return (ConvertTo-Json -InputObject @($a) -Compress -Depth 4) -ceq (ConvertTo-Json -InputObject @($b) -Compress -Depth 4)
}
function Frame($obj,[int]$x,[int]$y,[int]$w,[int]$h){
  $f=$obj.GetFrameDef()
  if($null -eq $f -or $null -eq $f.Rect){throw 'BLOCKED_MISSING_FRAME'}
  $scale=[decimal]2.5
  $want=@([int]($scale*$x),[int]($scale*$y),[int]($scale*$w),[int]($scale*$h))
  $f.Rect.Left=$want[0];$f.Rect.Top=$want[1];$f.Rect.Width=$want[2];$f.Rect.Height=$want[3]
  [void]$obj.SetFrame($f,$true,'')
  $read=$obj.GetFrameDef().Rect
  $got=@([decimal]$read.Left,[decimal]$read.Top,[decimal]$read.Width,[decimal]$read.Height)
  for($i=0;$i -lt 4;$i++){if([Math]::Abs($got[$i]-$want[$i]) -gt 5){throw ('BLOCKED_FRAME_READBACK_'+$obj.GetObjectID())}}
  Write-Output ('FRAME_READBACK_PASS='+$obj.GetObjectID()+' PIXELS='+$x+','+$y+','+$w+','+$h)
}

$qvdBefore=@(Snapshot 'QVD');$qvwBefore=@(Snapshot 'QVW')
$work=Join-Path $tempRoot ('SAD_VIII_C2W_'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work
$dst=Join-Path $work 'SAD_C2W_T26_LAYOUT_TEST.qvw'
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('EXECUTED_HEAD='+$gitHead[0])
Write-Output ('SCRIPT_SHA256='+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('ORIGINAL_C2V_SHA256='+$sourceHash)
Write-Output ('ORIGINAL_T24_SHA256='+$upstreamHash)
Write-Output 'MODE=TEMP_DISPOSABLE_NO_RELOAD_NO_QVD_WRITES'
$qv=$null;$doc=$null;$failure=$null;$succeeded=$false
try {
  $qvdBefore|Export-Csv -LiteralPath (Join-Path $work 'qvd_before.csv') -NoTypeInformation -Encoding UTF8
  $qvwBefore|Export-Csv -LiteralPath (Join-Path $work 'canonical_qvw_before.csv') -NoTypeInformation -Encoding UTF8
  if(-not $RunQlik){
    Write-Output 'VERDICT=PREPARED_NOT_EXECUTED'
  } else {
    Copy-Item -LiteralPath $src -Destination $dst
    if((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash -cne $sourceHash){throw 'BLOCKED_TEMP_COPY_HASH'}
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $doc=$qv.OpenDoc($dst,'','')
    if($null -eq $doc){throw 'BLOCKED_OPEN_TEMP_QVW'}
    if(-not ([string]$doc.GetProperties().Script).Contains('[VIII-B-T24] VERDICT=PASS_RELOAD_STRUCTURE_ONLY_NOT_T24')){throw 'BLOCKED_SOURCE_SCRIPT_MARKER'}
    $chart=$doc.GetSheetObject('CH01')
    if($null -eq $chart -or [string]$chart.GetObjectID() -notlike '*CH01'){throw 'BLOCKED_CHART_CH01_NOT_FOUND'}
    $p=$chart.GetProperties()
    if($null -eq $p -or $null -eq $p.EvaluationCondition -or
      [string]$p.EvaluationCondition.v -notlike '=If(GetSelectedCount(PERIODO_ANO)*'){
      throw 'BLOCKED_EXPECTED_T26_CHART_CONDITION'
    }
    # These EXACT COM paths are documented in a Qlik Community accepted column-width macro.
    $dim=$null;$visual=$null
    try {
      $dim=$p.Dimensions.Item(0)
      $visual=$p.Expressions.Item(0).Item(0).Data.ExpressionVisual
    }catch{throw ('BLOCKED_COM_COLUMN_WIDTH_PATH_'+$_.Exception.Message)}
    if($null -eq $dim -or $null -eq $visual){throw 'BLOCKED_MISSING_DIMENSION_OR_EXPRESSION'}
    $dim.ColWidth=155
    $visual.ColWidth=285
    [void]$chart.SetProperties($p)
    $p2=$chart.GetProperties()
    if([int]$p2.Dimensions.Item(0).ColWidth -ne 155 -or
       [int]$p2.Expressions.Item(0).Item(0).Data.ExpressionVisual.ColWidth -ne 285){
      throw 'BLOCKED_COLUMN_WIDTH_COM_READBACK'
    }
    Write-Output 'C2W_CHART_COLUMN_WIDTHS_COM=PASS_DIM_155_EXPR_285'
    Frame $chart 300 116 865 320
    foreach($pair in @(
      @{Id='LB01';Y=120},@{Id='LB02';Y=280},@{Id='LB03';Y=440}
    )){
      $obj=$doc.GetSheetObject($pair.Id)
      if($null -eq $obj){throw ('BLOCKED_LISTBOX_MISSING_'+$pair.Id)}
      Frame $obj 16 $pair.Y 250 143
    }
    foreach($pair in @(
      @{Id='TX01';Y=10},@{Id='TX02';Y=61},
      @{Id='TX03';Y=465},@{Id='TX04';Y=513},
      @{Id='TX05';Y=465},@{Id='TX06';Y=465}
    )){
      $obj=$doc.GetSheetObject($pair.Id)
      if($null -eq $obj){throw ('BLOCKED_TEXT_MISSING_'+$pair.Id)}
      Frame $obj 300 $pair.Y 865 42
    }
    [void]$doc.ClearAll()
    [void]$doc.GetField('PERIODO_ANO').Select('2018')
    [void]$doc.GetField('SERV_COD_DATASUS_6').Select('250750')
    $n=[string]$doc.Evaluate("Num(12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS),'0,00',',','.')")
    if($n -cne '31,21'){throw ('BLOCKED_T26_DISPLAY_SMOKE_'+$n)}
    $condition=[string]$doc.Evaluate(([string]$p2.EvaluationCondition.v).Substring(1))
    if($condition -cne '1'){throw ('BLOCKED_T26_CONDITION_SMOKE_'+$condition)}
    Write-Output 'C2W_S0_SMOKE=PASS_DISPLAY_31,21_CONDITION_1'
    [void]$doc.Save()
    Write-Output 'COPY_SAVED_WITH_COLUMNS_AND_FRAMES=True'
    $succeeded=$true
  }
}catch{
  $failure=$_.Exception.Message
  Write-Output ('C2W_VERDICT=BLOCKED '+$failure)
}finally{
  if($null -ne $doc){try{[void]$doc.CloseDoc()}catch{Write-Output ('CLOSE_WARNING='+$_.Exception.Message)}}
  if($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)){[void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)}
  if(-not(Same $qvdBefore @(Snapshot 'QVD'))){throw 'CRITICAL_22_QVD_INTEGRITY_CHANGED'}
  if(-not(Same $qvwBefore @(Snapshot 'QVW'))){throw 'CRITICAL_CANONICAL_QVW_INTEGRITY_CHANGED'}
  if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -cne $sourceHash){throw 'CRITICAL_C2V_SOURCE_QVW_CHANGED'}
  if((Get-FileHash -LiteralPath $upstream -Algorithm SHA256).Hash -cne $upstreamHash){throw 'CRITICAL_T24_SOURCE_CHANGED'}
  Write-Output 'ORIGINAL_22_QVD_SHA256_UNCHANGED=True'
  Write-Output 'ORIGINAL_CANONICAL_QVWS_UNCHANGED=True'
  Write-Output 'C2V_EVIDENCE_QVW_SHA256_UNCHANGED=True'
  Write-Output 'T24_SOURCE_QVW_SHA256_UNCHANGED=True'
}
if($null -ne $failure){throw ('C2W_EXECUTION_BLOCKED_'+$failure)}
if($RunQlik -and $succeeded){
  Write-Output ('COPY_FOR_GUI=' + $dst)
  Write-Output 'VERDICT=PASS_LOCAL_C2W_COM_COLUMNS_AND_FRAMES_GUI_SIZE_TO_DATA_STILL_PENDING'
  Write-Output 'NEXT_ACTION=OPEN_NEW_COPY_ONLY_UNCHECK_SIZE_TO_DATA_SAVE_COPY_THEN_SCREENSHOT_S0_AND_S1'
  Write-Output 'VISUAL_ACCEPTANCE=NOT_APPROVED D2_UI=NOT_TESTED P5_FULL=NOT_APPROVED PRODUCTION_APPROVED=False'
}