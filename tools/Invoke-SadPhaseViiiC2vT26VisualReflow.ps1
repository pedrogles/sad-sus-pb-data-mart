# C2-V: presentation-only follow-up to C2-A; one T26 candidate chart, same selection scenarios, new QVW TEMP.
# Geometry/label in QlikView COM are hypotheses until actual PNG inspection; not P5/D2 UI certification.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$SourceQvw,
  [Parameter(Mandatory=$true)][string]$F1F2Dir,
  [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$branch='test/phase-viii-c2v-t26-visual-reflow-20261019'
$selfRel='tools/Invoke-SadPhaseViiiC2vT26VisualReflow.ps1'
$self=Join-Path $repo $selfRel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'BLOCKED_SELF_PATH'}
$b=@(& git -C $repo branch --show-current 2>$null)
$h=@(& git -C $repo rev-parse HEAD 2>$null)
if($LASTEXITCODE -ne 0 -or $b.Count -ne 1 -or $h.Count -ne 1 -or $b[0] -cne $branch -or $h[0] -notmatch '^[a-f0-9]{40}$'){throw 'BLOCKED_GIT_BRANCH_OR_HEAD'}
$null=& git -C $repo merge-base --is-ancestor 337943d5c5b77067f842902fc679dbb68db87020 HEAD 2>$null
if($LASTEXITCODE -ne 0){throw 'BLOCKED_NOT_BASED_ON_FROZEN_MAIN'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $selfRel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $selfRel)
if($tracked.Count -ne 1 -or $dirty.Count -ne 0){throw 'BLOCKED_SCRIPT_NOT_COMMITTED_AND_CLEAN'}
$src=[IO.Path]::GetFullPath($SourceQvw)
$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
if(-not $src.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
   [IO.Path]::GetFileName($src) -cne 'SAD_VIII_T24_ANNUAL_TEST.qvw' -or
   [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($src)) -notmatch '^SAD_VIII_T24_[a-f0-9]{32}$' -or
   -not(Test-Path -LiteralPath $src -PathType Leaf)){throw 'BLOCKED_SOURCE_NOT_APPROVED_TEMP_QVW'}
$sourceHash=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
if($sourceHash -cne '7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E'){throw 'BLOCKED_SOURCE_QVW_BASELINE_DRIFT'}
$work=Join-Path $tmp ('SAD_VIII_C2V_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work
$copy=Join-Path $work 'SAD_C2V_T26_DISPOSABLE.qvw'
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('VERSIONED_GIT_HEAD='+$h[0])
Write-Output ('SCRIPT_SHA256='+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('SOURCE_QVW_SHA256='+$sourceHash)
Write-Output 'MODE=TEMP_COPY_NO_RELOAD_CANONICAL_WRITE QVD_WRITES=0'
function Snapshot([string]$kind){
  $items=@()
  if($kind -ceq 'QVD'){
    $ext=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO/QVD') -File -Filter '*.qvd')
    $tr=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO/QVD') -File -Filter '*.qvd')
    if($ext.Count -ne 10 -or $tr.Count -ne 12){throw 'BLOCKED_EXPECTED_10_PLUS_12_QVDS'}
    $items=@($ext)+@($tr)
  }else{
    foreach($p in @('EXTRACAO/EXT.qvw','TRANSFORMACAO/TRANSF.qvw','PAINEL/PAINEL.qvw')){
      $f=Join-Path $repo $p
      if(Test-Path -LiteralPath $f -PathType Leaf){$items+=Get-Item -LiteralPath $f}
    }
  }
  $out=@()
  foreach($i in $items){$out += [pscustomobject]@{Path=$i.FullName;Length=$i.Length;SHA256=(Get-FileHash -LiteralPath $i.FullName -Algorithm SHA256).Hash}}
  return @($out|Sort-Object Path)
}
function Same($a,$b){
  return ((ConvertTo-Json -InputObject @($a) -Compress -Depth 3) -ceq
          (ConvertTo-Json -InputObject @($b) -Compress -Depth 3))
}
function Oracle([string]$name){
  $csv=Join-Path $F1F2Dir $name
  $manifest=Join-Path $F1F2Dir 'manifest_F1_F2.json'
  if(-not(Test-Path -LiteralPath $csv -PathType Leaf) -or -not(Test-Path -LiteralPath $manifest -PathType Leaf)){throw ('BLOCKED_ORACLE_MISSING_'+$name)}
  $m=Get-Content -LiteralPath $manifest -Raw -Encoding UTF8|ConvertFrom-Json
  $expected=[string]$m.output_sha256.$name
  $got=(Get-FileHash -LiteralPath $csv -Algorithm SHA256).Hash
  if($expected -notmatch '^[A-Fa-f0-9]{64}$' -or $got -cne $expected.ToUpperInvariant()){throw ('BLOCKED_ORACLE_SHA_'+$name)}
  Write-Host ('ORACLE_'+$name+'_SHA256='+$got)
  return $csv
}
function Q([string]$expr){return [string]$script:doc.Evaluate($expr)}
function N([string]$expr){
  $v=Q $expr
  if($v.Trim() -notmatch '^\d+([.,]\d+)?$'){throw ('BLOCKED_NUMERIC_EXPRESSION_'+$expr+'_'+$v)}
  return [decimal]::Parse($v.Trim().Replace(',','.'),[Globalization.NumberStyles]::AllowDecimalPoint,[Globalization.CultureInfo]::InvariantCulture)
}
function Selected([string]$field){
  $v=Q ('GetSelectedCount('+$field+')')
  if($v -notmatch '^\d+$'){throw ('BLOCKED_BAD_SELECTED_COUNT_'+$field)}
  return [int]$v
}
function SelectOne([string]$field,[string]$value){
  $f=$script:doc.GetField($field)
  if($null -eq $f){throw ('BLOCKED_FIELD_ABSENT_'+$field)}
  [void]$f.Select($value)
  if((Selected $field) -ne 1){throw ('BLOCKED_SELECTION_NOT_APPLIED_'+$field)}
}
function Base{
  [void]$script:doc.ClearAll()
  SelectOne 'PERIODO_ANO' '2018'
  SelectOne 'SERV_COD_DATASUS_6' '250750'
  if((Selected 'PERIODO_COMPETENCIA') -ne 0){throw 'BLOCKED_BASE_MONTH_SELECTED'}
}
# The C2-A screenshots proved SetFrameDef alone did not yield visible size/position.
# QlikView COM examples use SetFrame(frame, includeRects=true, parts="") and an
# approximate 2.5 internal-units-per-pixel scale. HYPOTHESIS: verify on Windows.
function Place($obj,[int]$x,[int]$y,[int]$w,[int]$height){
  $frame=$obj.GetFrameDef()
  if($null -eq $frame -or $null -eq $frame.Rect){throw 'BLOCKED_FRAME_DEF_MISSING'}
  $rect=$frame.Rect
  [decimal]$scale=2.5
  $wantLeft=[int]([decimal]$x*$scale)
  $wantTop=[int]([decimal]$y*$scale)
  $wantWidth=[int]([decimal]$w*$scale)
  $wantHeight=[int]([decimal]$height*$scale)
  $rect.Left=$wantLeft;$rect.Top=$wantTop
  $rect.Width=$wantWidth;$rect.Height=$wantHeight
  $methods=@($obj|Get-Member -MemberType Method|Select-Object -ExpandProperty Name)
  if($methods -cnotcontains 'SetFrame'){throw 'BLOCKED_COM_SETFRAME_UNAVAILABLE'}
  [void]$obj.SetFrame($frame,$true,'')
  $observed=$obj.GetFrameDef().Rect
  if($null -eq $observed){throw 'BLOCKED_FRAME_READBACK_MISSING'}
  if([Math]::Abs([decimal]$observed.Left-$wantLeft) -gt 5 -or
     [Math]::Abs([decimal]$observed.Top-$wantTop) -gt 5 -or
     [Math]::Abs([decimal]$observed.Width-$wantWidth) -gt 5 -or
     [Math]::Abs([decimal]$observed.Height-$wantHeight) -gt 5){
    throw ('BLOCKED_FRAME_GEOMETRY_READBACK target='+$wantLeft+','+$wantTop+','+$wantWidth+','+$wantHeight+
      ' observed='+$observed.Left+','+$observed.Top+','+$observed.Width+','+$observed.Height)
  }
  Write-Output ('FRAME_SET_READBACK=PASS_COM_ONLY ID='+[string]$obj.GetObjectID()+
    ' TARGET_PIXELS='+$x+','+$y+','+$w+','+$height+
    ' QLIK_RECT='+$observed.Left+','+$observed.Top+','+$observed.Width+','+$observed.Height)
}
function TextObj([string]$key,[string]$label,[string]$when,[int]$top){
  $obj=$script:sheet.CreateTextObject()
  if($null -eq $obj){throw ('BLOCKED_TEXT_CREATION_'+$key)}
  $p=$obj.GetProperties();$p.Layout.Text.v=$label
  if($when -ceq ''){$p.Layout.Frame.Show.Always=$true}
  else{$p.Layout.Frame.Show.Always=$false;$p.Layout.Frame.Show.Expression.v=$when}
  [void]$obj.SetProperties($p)
  Place $obj 235 $top 950 42
  $r=$obj.GetProperties()
  if([string]$r.Layout.Text.v -cne $label -or
     [bool]$r.Layout.Frame.Show.Always -ne ($when -ceq '') -or
     ($when -cne '' -and [string]$r.Layout.Frame.Show.Expression.v -cne $when)){throw ('BLOCKED_TEXT_READBACK_'+$key)}
  Write-Output ('TEXT='+$key+' PROPERTY_READBACK=PASS_COM_ONLY')
}
function ListObj([string]$name,[int]$top){
  $obj=$script:sheet.CreateListBox()
  if($null -eq $obj){throw ('BLOCKED_LISTBOX_CREATION_'+$name)}
  $p=$obj.GetProperties();$p.Def.Name=$name
  [void]$obj.SetProperties($p)
  Place $obj 16 $top 192 143
  if([string]$obj.GetProperties().Def.Name -cne $name){throw ('BLOCKED_LISTBOX_READBACK_'+$name)}
}
function Check([string]$label,[int]$expected,[string]$reason){
  $got=N ($script:calc.Substring(1))
  VerifyChart
  if($got -ne [decimal]$expected){throw ('BLOCKED_CALC_CONDITION_'+$label+'_EXPECTED_'+$expected+'_GOT_'+$got)}
  $script:states += [pscustomobject]@{scenario=$label;expected=$expected;actual=$got;reason=$reason;screenshot='PENDING_VISUAL_REVIEW'}
  Write-Output ('C2V_CASE='+$label+' EVAL='+$got+' EXPECTED='+$expected+' REASON='+$reason+' PROPERTY_READBACK=PASS_COM_ONLY')
}
function VerifyChart {
  $p=$script:chart.GetProperties()
  if($null -eq $p -or $null -eq $p.EvaluationCondition -or [string]$p.EvaluationCondition.v -cne $script:calc){
    throw 'BLOCKED_CHART_CONDITION_READBACK'
  }
}
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class SadC2Capture {
 [StructLayout(LayoutKind.Sequential)] public struct RECT {public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr handle);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr handle,out RECT value);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr handle,out uint pid);
 [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr handle);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr handle,int cmd);
}
'@
function Capture([string]$label){
  $windowCandidates=@(Get-Process | Where-Object {
    $_.MainWindowHandle -ne [IntPtr]::Zero -and
    $_.ProcessName -match '^(qv|qlikview)$' -and
    $_.MainWindowTitle -like '*SAD_C2A_T26_DISPOSABLE*'
  })
  if($windowCandidates.Count -ne 1){throw ('BLOCKED_QVW_WINDOW_NOT_UNIQUE_'+$windowCandidates.Count)}
  $win=$windowCandidates[0].MainWindowHandle
  if([SadC2Capture]::IsIconic($win)){[void][SadC2Capture]::ShowWindow($win,9)}
  [void][SadC2Capture]::SetForegroundWindow($win)
  Start-Sleep -Milliseconds 750
  $front=[SadC2Capture]::GetForegroundWindow()
  $pidValue=[uint32]0
  [void][SadC2Capture]::GetWindowThreadProcessId($front,[ref]$pidValue)
  if($front -ne $win -or $pidValue -ne [uint32]$windowCandidates[0].Id){throw 'BLOCKED_WRONG_FOREGROUND_WINDOW'}
  $rect=New-Object SadC2Capture+RECT
  if(-not [SadC2Capture]::GetWindowRect($win,[ref]$rect)){throw 'BLOCKED_WINDOW_RECT'}
  $width=$rect.Right-$rect.Left;$height=$rect.Bottom-$rect.Top
  if($width -lt 650 -or $height -lt 560 -or $width -gt 5000 -or $height -gt 3500){throw 'BLOCKED_CAPTURE_DIMENSIONS'}
  $bmp=[System.Drawing.Bitmap]::new($width,$height)
  try{
    $graphics=[System.Drawing.Graphics]::FromImage($bmp)
    try{$graphics.CopyFromScreen($rect.Left,$rect.Top,0,0,([System.Drawing.Size]::new($width,$height)))}
    finally{$graphics.Dispose()}
    $png=Join-Path $work ($label+'.png')
    $bmp.Save($png,[System.Drawing.Imaging.ImageFormat]::Png)
  }finally{$bmp.Dispose()}
  $script:states[$script:states.Count-1].screenshot=$png
  Write-Output ('SCREENSHOT='+$label+' SHA256='+(Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash+' NOT_VISUAL_AUDIT=True')
}
$script:calc='=If(GetSelectedCount(PERIODO_ANO)=1 and GetFieldSelections(PERIODO_ANO)=''2018'' and GetSelectedCount(SERV_COD_DATASUS_6)=1 and GetFieldSelections(SERV_COD_DATASUS_6)=''250750'' and GetSelectedCount(PERIODO_COMPETENCIA)=0 and GetSelectedCount(RES_COD_DATASUS_6)=0 and GetSelectedCount(COD_PROCEDIMENTO)=0 and GetSelectedCount(COD_DIAGNOSTICO)=0 and GetSelectedCount(COD_CARATER_ATENDIMENTO)=0 and GetSelectedCount(COD_MOTIVO_SAIDA_FONTE)=0 and GetSelectedCount(COD_TIPO_LEITO)=0 and GetSelectedCount(DATA_INTERNACAO)=0 and GetSelectedCount(DATA_SAIDA)=0 and GetSelectedCount(ESTAB_CNES)=0 and Sum(QTD_LEITOS_SUS)>0,1,0)'
$oldQvd=$null;$oldQvw=$null
$script:doc=$null;$script:sheet=$null;$script:chart=$null;$qv=$null
$script:states=@();$script:success=$false
$hadFailure=$false;$failReason=''
try{
  $oldQvd=@(Snapshot 'QVD');$oldQvw=@(Snapshot 'QVW')
  $oldQvd|Export-Csv -LiteralPath (Join-Path $work 'qvd_before.csv') -NoTypeInformation -Encoding UTF8
  $oldQvw|Export-Csv -LiteralPath (Join-Path $work 'canonical_qvw_before.csv') -NoTypeInformation -Encoding UTF8
  $link=Join-Path $repo 'TRANSFORMACAO/QVD/LINK_ANALISE.qvd'
  $lnk=@($oldQvd|Where-Object {$_.Path -ieq $link})
  if($lnk.Count -ne 1 -or $lnk[0].SHA256 -cne '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB'){
    throw 'BLOCKED_LINK_ANALISE_SHA_DRIFT'
  }
  $yearCsv=Oracle 'F1_servico_ano.csv'
  $bedsCsv=Oracle 'F2_lt_municipio_ano_cobertura_candidata.csv'
  $year=@(Import-Csv -LiteralPath $yearCsv -Delimiter ';' -Encoding UTF8|Where-Object {$_.ano -ceq '2018' -and $_.municipio_servico -ceq '250750'})
  $beds=@(Import-Csv -LiteralPath $bedsCsv -Delimiter ';' -Encoding UTF8|Where-Object {$_.ano -ceq '2018' -and $_.municipio_servico -ceq '250750'})
  if($year.Count -ne 1 -or $beds.Count -ne 1 -or
     [long]$year[0].internacoes_elegiveis -ne 73105 -or
     [long]$beds[0].qt_sus_soma_snapshots_auditoria -ne 28106 -or
     [string]$beds[0].cobertura_presenca_linhas -cne '12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED' -or
     [string]$beds[0].hospitalar_historico_validado -cne 'NAO'){
    throw 'BLOCKED_F1_F2_JP2018_ORACLES_DRIFT'
  }
  Write-Output 'ORACLES_F1_F2_JP_2018=PASS_RD_73105_LT_SNAPSHOT_SUM_28106_HOSPITAL_NOT_VERIFIED'
  if(-not $RunQlik){
    Write-Output 'VERDICT=PREPARED_NOT_EXECUTED_NO_QVW_COPY'
  }else{
    Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
    if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash){throw 'BLOCKED_TEMP_COPY_HASH'}
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $script:doc=$qv.OpenDoc($copy,'','')
    if($null -eq $script:doc){throw 'BLOCKED_QVW_OPEN'}
    if(-not ([string]$script:doc.GetProperties().Script).Contains('[VIII-B-T24] VERDICT=PASS_RELOAD_STRUCTURE_ONLY_NOT_T24')){
      throw 'BLOCKED_EXPECTED_ORIGIN_QVW_SCRIPT_MARKER'
    }
    $script:sheet=$script:doc.GetSheet(0)
    if($null -eq $script:sheet -or -not [Runtime.InteropServices.Marshal]::IsComObject($script:sheet)){throw 'BLOCKED_COM_SHEET_NOT_FOUND'}
    $methods=@($script:sheet|Get-Member -MemberType Method|Select-Object -ExpandProperty Name)
    foreach($needed in @('CreateTextObject','CreateListBox','CreateStraightTable')){
      if($methods -cnotcontains $needed){throw ('BLOCKED_SHEET_METHOD_MISSING_'+$needed)}
    }
    ListObj 'PERIODO_ANO' 120
    ListObj 'SERV_COD_DATASUS_6' 280
    ListObj 'COD_PROCEDIMENTO' 440
    TextObj 'HEADER' 'T26 | Internacoes processadas por leito SUS medio (2018, Joao Pessoa)' '' 10
    TextObj 'CAVEAT' 'CNES/LT observado, escopo hospitalar nao verificado. Nao e taxa de ocupacao.' '' 61
    TextObj 'BLOCK_PROC' 'P5 B: procedimento selecionado. Indicador T26 geral indisponivel neste contexto.' '=If(GetSelectedCount(COD_PROCEDIMENTO)>0,1,0)' 465
    TextObj 'BLOCK_RES' 'P5 B: municipio de residencia selecionado. T26 exige somente municipio de servico.' '=If(GetSelectedCount(RES_COD_DATASUS_6)>0,1,0)' 513
    TextObj 'BLOCK_BED' 'P5 B: tipo de leito selecionado. Razao T26 geral indisponivel neste contexto.' '=If(GetSelectedCount(COD_TIPO_LEITO)>0,1,0)' 465
    TextObj 'BLOCK_MONTH' 'Periodo parcial 201801: este grafico representa somente o ano completo de 2018.' '=If(GetSelectedCount(PERIODO_COMPETENCIA)>0,1,0)' 465
    $script:chart=$script:sheet.CreateStraightTable()
    if($null -eq $script:chart){throw 'BLOCKED_CHART_CREATION'}
    [void]$script:chart.AddDimension('PERIODO_ANO')
    [void]$script:chart.AddExpression("Num(12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS),'0.00',',','.')")
    $p=$script:chart.GetProperties()
    if($null -eq $p -or $null -eq $p.EvaluationCondition){throw 'BLOCKED_CHART_CONDITION_PROPERTY_ABSENT'}
    $p.EvaluationCondition.v=$script:calc
    # QV11/12 COM: label lives under the expression visual, not its raw formula.
    # Fail closed if this API branch is unavailable rather than assuming a title.
    $visual=$null
    try{$visual=$p.ExpressionVisuals(0)}catch{throw ('BLOCKED_EXPRESSION_VISUAL_COM_'+$_.Exception.Message)}
    if($null -eq $visual -or $null -eq $visual.Label){throw 'BLOCKED_EXPRESSION_LABEL_PROPERTY_ABSENT'}
    $visual.Label.v='Internacoes por leito SUS medio'
    $visual.LabelAdjust=2
    [void]$script:chart.SetProperties($p)
    VerifyChart
    $labelBack=$script:chart.GetProperties().ExpressionVisuals(0)
    if([string]$labelBack.Label.v -cne 'Internacoes por leito SUS medio'){
      throw 'BLOCKED_EXPRESSION_LABEL_READBACK'
    }
    Write-Output 'CHART_EXPRESSION_LABEL_READBACK=PASS_COM_ONLY'
    Place $script:chart 235 116 950 320
    [void]$script:doc.Save()
    Write-Output 'TEMP_QVW_SAVED_ONLY_DISPOSABLE=True'
    Base
    $n=N 'Sum(QTD_INTERNACAO)'
    $lt=N 'Sum(QTD_LEITOS_SUS)'
    $ratio=N '12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS)'
    $want=[decimal]12*[decimal]73105/[decimal]28106
    if($n -ne 73105 -or $lt -ne 28106 -or [Math]::Abs([decimal]($ratio-$want)) -gt [decimal]0.000001){throw 'BLOCKED_T26_C2_BASELINE_NUMERIC'}
    $visible=Q "Num(12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS),'0.00',',','.')"
    if($visible -cne '31,21'){throw ('BLOCKED_DISPLAY_FORMAT_QV_VIEW='+$visible)}
    Write-Output ('C2V_DISPLAY_FORMAT_QV=PASS_DISPLAY_'+$visible)
    Write-Output ('T26_BASELINE_F1=73105 QLIK='+$n+' LT_F2_SUM12=28106 QLIK='+$lt+' RATE=PASS_CANDIDATE')
    Check 'S0_ALLOWED' 1 'P5_C_YEAR_AND_SERVICE'; Capture 'S0_ALLOWED'

    $proc=Q 'MinString(COD_PROCEDIMENTO)'
    if([string]::IsNullOrWhiteSpace($proc)){throw 'BLOCKED_NO_PROCEDURE_SAMPLE'}
    SelectOne 'COD_PROCEDIMENTO' $proc
    Check 'S1_BLOCK_PROCEDURE' 0 'P5_B_PROCEDURE'; Capture 'S1_BLOCK_PROCEDURE'
    $res=Q 'MinString(RES_COD_DATASUS_6)'
    if([string]::IsNullOrWhiteSpace($res)){throw 'BLOCKED_NO_RESIDENCE_SAMPLE'}
    SelectOne 'RES_COD_DATASUS_6' $res
    Check 'S2_BLOCK_PROCEDURE_PLUS_RESIDENCE' 0 'P5_B_B_PAIR'; Capture 'S2_BLOCK_PROCEDURE_PLUS_RESIDENCE'

    Base
    $bed=Q 'MinString(COD_TIPO_LEITO)'
    if([string]::IsNullOrWhiteSpace($bed)){throw 'BLOCKED_NO_BED_TYPE_SAMPLE'}
    SelectOne 'COD_TIPO_LEITO' $bed
    Check 'S3_BLOCK_BED_TYPE' 0 'P5_B_BED_TYPE'; Capture 'S3_BLOCK_BED_TYPE'

    Base
    SelectOne 'PERIODO_COMPETENCIA' '201801'
    Check 'S4_PARTIAL_NOT_ANNUAL' 0 'D1_PARTIAL_ANNUAL_OBJECT_UNAVAILABLE'; Capture 'S4_PARTIAL_NOT_ANNUAL'
    Write-Output 'D2_PREDISPATCH=ALREADY_PASSED_IN_C2A_NOT_REPEATED C2V_SCOPE=PRESENTATION_ONLY'
    Base
    Check 'S5_RESTORED' 1 'P5_C_RESTORED'
    $script:states|Export-Csv -LiteralPath (Join-Path $work 'c2v_states.csv') -NoTypeInformation -Encoding UTF8
    $h0=(Get-FileHash -LiteralPath (Join-Path $work 'S0_ALLOWED.png') -Algorithm SHA256).Hash
    $h1=(Get-FileHash -LiteralPath (Join-Path $work 'S1_BLOCK_PROCEDURE.png') -Algorithm SHA256).Hash
    $h4=(Get-FileHash -LiteralPath (Join-Path $work 'S4_PARTIAL_NOT_ANNUAL.png') -Algorithm SHA256).Hash
    if($h0 -ceq $h1 -or $h0 -ceq $h4){throw 'BLOCKED_SCREEN_PIXELS_UNCHANGED'}
    Write-Output 'C2V_SCREENSHOTS_5_CAPTURED_GEOMETRY_COM_CHECKED_VISUAL_AUDIT_PENDING'
    $script:success=$true
  }
}catch{
  $hadFailure=$true;$failReason=$_.Exception.Message
  Write-Output ('VERDICT=BLOCKED_OR_INCONCLUSIVE '+$failReason)
}finally{
  if($null -ne $script:doc){try{[void]$script:doc.CloseDoc()}catch{Write-Output ('QV_CLOSE_WARNING='+$_.Exception.Message)}}
  if($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)){
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
  }
  if($null -ne $oldQvd){
    $post=@(Snapshot 'QVD')
    $post|Export-Csv -LiteralPath (Join-Path $work 'qvd_after.csv') -NoTypeInformation -Encoding UTF8
    if(-not(Same $oldQvd $post)){throw 'CRITICAL_QVD_INTEGRITY_CHANGED'}
    Write-Output 'ORIGINAL_22_QVD_SHA256_UNCHANGED=True'
  }
  if($null -ne $oldQvw){
    $post=@(Snapshot 'QVW')
    $post|Export-Csv -LiteralPath (Join-Path $work 'canonical_qvw_after.csv') -NoTypeInformation -Encoding UTF8
    if(-not(Same $oldQvw $post)){throw 'CRITICAL_CANONICAL_QVW_CHANGED'}
    Write-Output 'ORIGINAL_CANONICAL_QVWS_UNCHANGED=True'
  }
  if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -cne $sourceHash){throw 'CRITICAL_SOURCE_QVW_CHANGED'}
  Write-Output 'SOURCE_T24_QVW_SHA256_UNCHANGED=True'
}
if($hadFailure){throw ('C2A_EXECUTION_BLOCKED_'+$failReason)}
if($RunQlik -and $script:success){
  Write-Output 'VERDICT=PASS_LOCAL_C2V_GEOMETRY_LABEL_COM_5_SCREENSHOTS_VISUAL_PENDING'
  Write-Output 'VISUAL_AUDIT=PENDING_REVIEW PRESENTATION_ACCEPTANCE=NOT_YET_APPROVED D2_UI_INTERCEPTION=NOT_TESTED P5_FULL_UI=NOT_APPROVED T26_GENERAL=NOT_APPROVED PRODUCTION_APPROVED=False'
}
