#requires -Version 5.1
<#
SAD M2 experimental nine-view UI build. New QVW outside Git only.
Source: locally validated M1 QVW; model is reloaded in a COPIED QVW
to include the already versioned P23 observability island.
Never use a canonical QVW as source or destination.
No physical contract/IX/production approval.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ExpectedCommit,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][string]$M1SourceQvw,
  [Parameter(Mandatory=$true)][switch]$Build
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if(-not $Build){throw 'Explicit -Build required for the authorized TEMP copy'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows/QlikView 12 required'}
if($ExpectedCommit -notmatch '^[0-9a-fA-F]{40}$'){throw 'ExpectedCommit must be full Git SHA'}
function Full([string]$p){return [IO.Path]::GetFullPath($p).TrimEnd([char[]]@('\','/'))}
function Under([string]$child,[string]$parent){
  return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
    $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
$repo=Full $Root
$evidence=Full $EvidenceRoot
$source=Full $M1SourceQvw
if((Under $evidence $repo) -or (Under $repo $evidence) -or
   (Under $evidence (Full ([IO.Path]::GetTempPath())))){
  throw 'EvidenceRoot must be separate from repository and Windows TEMP'
}
if(-not(Test-Path -LiteralPath $evidence -PathType Container)){throw 'EvidenceRoot missing'}
if(-not(Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)){throw 'Incorrect repository'}
if(-not (Under $source $evidence)){throw 'M1SourceQvw must be inside the existing external EvidenceRoot'}
if((Split-Path $source -Leaf) -cne 'SAD_M1_INTEGRATED_TEMP.qvw'){throw 'Use exactly the previously validated M1 TEMP QVW'}
if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw 'M1SourceQvw not found'}
$expectedM1Sha='F55FB113D5E03DB1E7A746F665277E5F84AD5BECBE25D6FD1C85DDED0C2BEC60'
if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $expectedM1Sha){
  throw 'Pinned M1 source SHA-256 mismatch; stop without constructing QVW'
}
$branch=(& git -C $repo branch --show-current 2>$null).Trim()
$head=(& git -C $repo rev-parse HEAD 2>$null).Trim()
if($LASTEXITCODE -ne 0 -or $branch -cne 'proposal/sad-mvp-rebaseline-2026-11-07' -or
   $head -cne $ExpectedCommit.ToLowerInvariant()){throw 'Branch/commit mismatch: refuse build'}
$rel=@(
  'tools/Build-SadMvpThreeSheetsTemp.ps1',
  'PAINEL/phase_vii_technical_model.qvs',
  'PAINEL/sad_p23_a1_island_physical_gate.qvs',
  'PAINEL/sad_mvp_m3_flow_classification.qvs'
)
foreach($r in $rel){
  $f=Join-Path $repo $r
  if(-not(Test-Path -LiteralPath $f -PathType Leaf)){throw "Required versioned file missing: $r"}
  $tracked=@(& git -C $repo ls-files --error-unmatch -- $r 2>$null)
  if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1){throw "Not tracked: $r"}
  $dirty=@(& git -C $repo status --porcelain -- $r)
  if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw "Dirty tracked file: $r"}
}
$ext=Join-Path $repo 'EXTRACAO/QVD'
$trans=Join-Path $repo 'TRANSFORMACAO/QVD'
$qvds=@(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)+
      @(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File)
if(@(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File).Count -ne 10 -or
   @(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File).Count -ne 12){
  throw 'Expected exactly 10 extraction and 12 transformation QVDs'
}
$canonical=@('EXTRACAO/EXT.qvw','TRANSFORMACAO/TRANSF.qvw','PAINEL/PAINEL.qvw') |
  ForEach-Object {Join-Path $repo $_}
$protected=@($qvds|ForEach-Object{$_.FullName})+@($canonical)+@($source)
foreach($p in $protected){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Protected file missing: $p"}}
function Snapshot {
  return @($protected | Sort-Object | ForEach-Object {
    $x=Get-Item -LiteralPath $_
    [pscustomobject]@{path=$x.FullName;bytes=[long]$x.Length;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash}
  })
}
function EqualsSnap($one,$two){
  return (ConvertTo-Json -InputObject @($one) -Compress -Depth 4) -ceq
         (ConvertTo-Json -InputObject @($two) -Compress -Depth 4)
}
$before=@(Snapshot)
$run=Join-Path $evidence ('SAD_M2_MVP_TEMP_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $run -ErrorAction Stop
$before | Export-Csv -LiteralPath (Join-Path $run 'protected_before.csv') -NoTypeInformation -Encoding UTF8
$target=Join-Path $run 'SAD_MVP_THREE_SHEETS_CANDIDATE.qvw'
Copy-Item -LiteralPath $source -Destination $target -ErrorAction Stop
$sourceSha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
Write-Output "EVIDENCE_DIR=$run"
Write-Output "SOURCE_M1_SHA256=$sourceSha"
Write-Output "GIT_HEAD=$head"
Write-Output "BUILD_TARGET=$target"
Write-Output 'CANONICAL_QVD_QVW_WRITES=False PHASE_IX=NOT_AUTHORIZED PRODUCTION_APPROVED=False'

$island=[IO.File]::ReadAllText((Join-Path $repo $rel[2]),[Text.Encoding]::UTF8)
if($island -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DIRECT\s+QUERY|DROP\s+FILE)\b' -or
   $island -match '(?i)\$\(\s*Must_Include' -or
   $island -notmatch '\[P23A1\] VERDICT=PASS_SCRIPT_CANDIDATE_ONLY'){
  throw 'P23 island file violates read-only/no-STORE contract'
}
$placeholders=@{
  '__P23_FACT__'=(Join-Path $trans 'FATO_CAPACIDADE_LEITO.qvd')
  '__P23_POP__'=(Join-Path $trans 'FATO_POPULACAO.qvd')
  '__P23_LT__'=(Join-Path $ext 'SRC_CNES_LT.qvd')
}
foreach($kv in $placeholders.GetEnumerator()){
  if(-not $island.Contains($kv.Key)){throw "P23 placeholder missing: $($kv.Key)"}
  if($kv.Value -match '[\]\r\n]'){throw "Unsupported path for $($kv.Key)"}
  $island=$island.Replace($kv.Key,$kv.Value)
}
if($island -match '__P23_[A-Z_]+__'){throw 'Unresolved P23 placeholders'}
$flowSource=Join-Path $repo $rel[3]
$flow=[IO.File]::ReadAllText($flowSource,[Text.Encoding]::UTF8)
if($flow -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DIRECT\s+QUERY|DROP\s+FILE)\b' -or
   $flow -match '(?i)\$\(\s*Must_Include' -or
   $flow -notmatch '\[MVP_FLOW\] VERDICT=PASS_SCRIPT_RESTRICTED_CANDIDATE_ONLY'){
  throw 'MVP flow source violates read-only or success-marker contract'
}
$mvpFIQvd=Join-Path $trans 'FATO_INTERNACAO.qvd'
if($mvpFIQvd -match '[\]\r\n]'){throw 'Unsupported FI QVD path'}
if(-not $flow.Contains('__MVP_FI_QVD__')){throw 'Flow QVS missing explicit FI QVD placeholder'}
$flow=$flow.Replace('__MVP_FI_QVD__',$mvpFIQvd)
if($flow -match '__MVP_[A-Z_]+__'){throw 'Unresolved MVP flow source placeholder'}
Write-Output ('FLOW_QVS_SHA256='+(Get-FileHash -LiteralPath $flowSource -Algorithm SHA256).Hash)
function ReadInt($doc,[string]$exp,[string]$label){
  $raw=[string]$doc.Evaluate($exp)
  if($raw -notmatch '^(0|[1-9][0-9]*)$'){throw "Bad Qlik value for $label : $raw"}
  return [long]::Parse($raw,[Globalization.CultureInfo]::InvariantCulture)
}
function AssertValue($doc,[string]$exp,[long]$expected,[string]$label){
  $got=ReadInt $doc $exp $label
  if($got -ne $expected){throw "BLOCKED_$label expected=$expected actual=$got"}
  Write-Output "CHECK_$label=$got"
}
function Chart($sheet,[string]$viewId,[string]$type,[string]$title,[string[]]$dims,[string[]]$expressions){
  $o=$null
  switch($type){
    'Bar' {$o=$sheet.CreateBarChart();break}
    'Line' {$o=$sheet.CreateLineChart();break}
    'Straight' {$o=$sheet.CreateStraightTable();break}
    default {throw "Unsupported chart type $type"}
  }
  if($null -eq $o){throw "CreateChart returned null: $title"}
  foreach($d in $dims){$null=$o.AddDimension($d)}
  foreach($e in $expressions){$null=$o.AddExpression($e)}
  $cp=$o.GetProperties()
  $cp.GraphLayout.WindowTitle.v=$title
  # QlikView Classic COM (Qlik Community, accepted property path):
  # UsePartialSum=false sets "No Totals" on the expression of a straight table.
  # This is essential for POP (annual, semi-additive). No other chart is changed.
  if($viewId -ceq 'M3-03'){
    $exprData=$cp.Expressions.Item(1).Item(0).Data.ExpressionData
    if($null -eq $exprData){throw 'No M3-03 ExpressionData found in Qlik COM properties'}
    $exprData.UsePartialSum=$false
  }
  $null=$o.SetProperties($cp)
  if($viewId -ceq 'M3-03'){
    $verify=$o.GetProperties().Expressions.Item(1).Item(0).Data.ExpressionData
    if([bool]$verify.UsePartialSum){throw 'M3-03 total still enabled; refuse misleading POP table'}
    Write-Output 'M3_03_TOTAL_MODE=NO_TOTALS_PERSISTED_IN_COM_CANDIDATE'
  }
  return $o
}
$objects=@(
  [pscustomobject]@{Sheet=1;Id='M1-01';Type='Bar';Title='Novas internações por ano (SIH/RD)';Dims=@('PERIODO_ANO');Expr=@('Sum(QTD_INTERNACAO)')},
  [pscustomobject]@{Sheet=1;Id='M1-02';Type='Line';Title='Novas internações por competência (2017–2019)';Dims=@('PERIODO_COMPETENCIA');Expr=@('Sum(QTD_INTERNACAO)')},
  [pscustomobject]@{Sheet=1;Id='M1-03';Type='Bar';Title='Novas internações por município de atendimento — SERV';Dims=@('SERV_COD_DATASUS_6');Expr=@('Sum(QTD_INTERNACAO)')},
  [pscustomobject]@{Sheet=2;Id='M2-01';Type='Line';Title='Leitos cadastrados por competência — snapshots';Dims=@('PERIODO_COMPETENCIA');Expr=@('Sum(QTD_LEITOS_SUS)','Sum(QTD_LEITOS_EXISTENTES)')},
  [pscustomobject]@{Sheet=2;Id='M2-02';Type='Bar';Title='Leitos SUS observados — município, 201912';Dims=@('SERV_COD_DATASUS_6');Expr=@("Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)")},
  [pscustomobject]@{Sheet=2;Id='M2-03';Type='Bar';Title='Observabilidade LT — células município × competência';Dims=@('P23_ESTADO_OBSERVADO');Expr=@('Count(P23_MUNICIPIO_6)')},
  [pscustomobject]@{Sheet=3;Id='M3-01';Type='Bar';Title='RES=SERV versus RES diferente de SERV';Dims=@('MVP_FI_RES_SERV_CLASS');Expr=@('Sum(QTD_INTERNACAO)')},
  [pscustomobject]@{Sheet=3;Id='M3-02';Type='Straight';Title='Pares residência → atendimento (novas internações)';Dims=@('RES_COD_DATASUS_6','SERV_COD_DATASUS_6');Expr=@('Sum(QTD_INTERNACAO)')},
  [pscustomobject]@{Sheet=3;Id='M3-03';Type='Straight';Title='População municipal por ano — IBGE (candidato)';Dims=@('RES_COD_DATASUS_6','PERIODO_ANO');Expr=@('Sum(POPULACAO_ESTIMADA)')}
)
if($objects.Count -ne 9 -or @($objects|Select-Object -ExpandProperty Id -Unique).Count -ne 9){
  throw 'Manifest has not exactly nine unique view IDs'
}
$created=New-Object System.Collections.Generic.List[object]
$app=$null
$doc=$null
$errorMessage=$null
$stage='OPEN_TEMP_COPY'
try{
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$app.OpenDoc($target)
  if($null -eq $doc){throw 'OpenDoc of disposable copy failed'}
  $stage='READ_MODEL_SCRIPT'
  $props=$doc.GetProperties()
  $script=[string]$props.Script
  if($script -notmatch '\[VII\] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY' -or
     $script -match '__LINK__|__FI__|__LT_FACT__'){
    throw 'Source TEMP script does not match the loaded M1 VII model'
  }
  if($script -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DIRECT\s+QUERY|DROP\s+FILE)\b'){
    throw 'Source M1 QVW contains forbidden script command'
  }
  $props.Script=$script+[Environment]::NewLine+$island+[Environment]::NewLine+$flow
  $props.GenerateLogfile=$true
  $null=$doc.SetProperties($props)
  $null=$doc.Save()
  $stage='RELOAD_P23_IN_TEMP'
  $null=$doc.Reload()
  $nativeLog=$target+'.log'
  if(-not(Test-Path -LiteralPath $nativeLog -PathType Leaf)){throw 'Native reload log missing'}
  $log=Get-Content -LiteralPath $nativeLog -Raw
  $emitted=@($log -split '\r?\n' | Where-Object {$_ -notmatch '\bTRACE\b'})
  if(@($emitted|Where-Object{$_.Contains('[VII] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY')}).Count -ne 1 -or
     @($emitted|Where-Object{$_.Contains('[P23A1] VERDICT=PASS_SCRIPT_CANDIDATE_ONLY')}).Count -ne 1 -or
     @($emitted|Where-Object{$_.Contains('[MVP_FLOW] VERDICT=PASS_SCRIPT_RESTRICTED_CANDIDATE_ONLY')}).Count -ne 1 -or
     @($emitted|Where-Object{$_.Contains('[P23A1] VERDICT=BLOCKED')}).Count -gt 0 -or
     @($emitted|Where-Object{$_.Contains('[MVP_FLOW] VERDICT=BLOCKED')}).Count -gt 0 -or
     $log -match '(?i)circular reference|loosely coupled|synthetic key'){
    throw 'P23 native reload PASS absent, BLOCKED emitted or association warning'
  }
  $stage='ORACLES_3_FACTS_AND_P23'
  AssertValue $doc "Num(Sum(QTD_INTERNACAO),'0','.',',')" 555089 'RD_ALL'
  AssertValue $doc "Num(Sum({<MVP_FI_RES_SERV_CLASS={'RES_EQ_SERV'}>} QTD_INTERNACAO),'0','.',',')" 294635 'M3_01_RES_EQ_SERV'
  AssertValue $doc "Num(Sum({<MVP_FI_RES_SERV_CLASS={'RES_NE_SERV'}>} QTD_INTERNACAO),'0','.',',')" 260454 'M3_01_RES_NE_SERV'
  AssertValue $doc "Num(Count({<MVP_FI_RES_SERV_CLASS={'MVP_UNMATCHED'}>} SK_REGISTRO_INTERNACAO),'0','.',',')" 0 'M3_01_UNMATCHED_FI_RECORDS'
  AssertValue $doc "Num(Count(DISTINCT MVP_FI_RES_SERV_CLASS),'0','.',',')" 2 'M3_01_CATEGORIES'
  AssertValue $doc "Num(Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS),'0','.',',')" 7140 'LT_201912'
  AssertValue $doc "Num(Sum({<PERIODO_ANO={2019}>} POPULACAO_ESTIMADA),'0','.',',')" 4018127 'POP_2019'
  AssertValue $doc 'Count(P23_MUNICIPIO_6)' 8028 'P23_CELLS'
  foreach($k in @(
    @{Code='ABSENT_NOT_ZERO_PROVEN';Expected=4467;Label='P23_ABSENT'},
    @{Code='OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED';Expected=97;Label='P23_ZERO_OBS'},
    @{Code='OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED';Expected=3464;Label='P23_POSITIVE'}
  )){
    $exp="Num(Count({<P23_ESTADO_OBSERVADO={'$($k.Code)'}>} P23_MUNICIPIO_6),'0','.',',')"
    AssertValue $doc $exp $k.Expected $k.Label
  }
  $stage='SHEET_COUNT_AND_CREATION'
  $nSheets=[int]$doc.NoOfSheets()
  Write-Output "M2_SOURCE_SHEET_COUNT=$nSheets"
  if($nSheets -gt 1){throw "Source M1 QVW contains $nSheets sheets; expected 0 or 1"}
  $titles=@('Produção Hospitalar','Leitos Cadastrais Observados','Fluxos e Contexto Territorial')
  $sheets=@()
  for($i=0;$i -lt 3;$i++){
    if($i -eq 0 -and $nSheets -eq 1){$sheet=$doc.GetSheet(0)}
    else {$sheet=$doc.CreateSheet()}
    if($null -eq $sheet){throw "Create/GetSheet failed: $i"}
    $sp=$sheet.GetProperties()
    $sp.Name=$titles[$i]
    $null=$sheet.SetProperties($sp)
    $sheets+=,$sheet
  }
  if([int]$doc.NoOfSheets() -ne 3){throw 'Not exactly three QlikView sheets'}
  foreach($spec in $objects){
    $stage='CREATE_OBJECT_'+$spec.Id
    $sheet=$sheets[$spec.Sheet-1]
    $null=$sheet.Activate()
    $chart=Chart $sheet $spec.Id $spec.Type $spec.Title $spec.Dims $spec.Expr
    if($null -eq $chart.GetProperties()){throw "Object lacks properties: $($spec.Id)"}
    # Desktop-layout candidate, visible and non-overlapping at 1280+ px.
    # These rectangles are provisional until a real QlikView GUI screenshot.
    $rects=@{
      'M1-01'=@(24,90,360,270); 'M1-02'=@(24,380,1096,355)
      'M1-03'=@(406,90,714,270)
      'M2-01'=@(24,90,1096,280); 'M2-02'=@(24,393,520,340)
      'M2-03'=@(566,393,554,340)
      'M3-01'=@(24,90,450,300); 'M3-02'=@(24,412,1096,340)
      'M3-03'=@(496,90,624,300)
    }
    $pos=$chart.GetRect()
    $dims=$rects[$spec.Id]
    $pos.Left=$dims[0];$pos.Top=$dims[1]
    $pos.Width=$dims[2];$pos.Height=$dims[3]
    $null=$chart.SetRect($pos)
    $created.Add([pscustomobject]@{
      ViewId=$spec.Id;Sheet=$titles[$spec.Sheet-1];Type=$spec.Type
      Title=$spec.Title;Dimensions=($spec.Dims -join ' | ')
      Expressions=($spec.Expr -join ' | ');Status='BUILT_UNVERIFIED_VISUAL'
    })
    Write-Output "M2_CREATED=$($spec.Id) Type=$($spec.Type)"
  }
  if($created.Count -ne 9){throw 'Nine native objects not created'}
  $stage='SAVE_COMPLETED_TEMP_QVW'
  $null=$doc.Save()
  $created | Export-Csv -LiteralPath (Join-Path $run 'm2_objects_manifest.csv') -NoTypeInformation -Encoding UTF8
  Write-Output 'M2_NATIVE_CANDIDATE=3_SHEETS_9_OBJECTS_BUILT_PENDING_GUI_AND_FILTER_VALIDATION'
  Write-Output 'P5_D2_UI=NOT_APPROVED LINK_KEY_CONTRACT=NOT_APPROVED'
}catch{
  $errorMessage=$_.Exception.Message
  $line=$_.InvocationInfo.ScriptLineNumber
  Write-Output "M2_FAILED_STAGE=$stage"
  Write-Output "M2_FAILED_LINE=$line"
  Write-Output "M2_VERDICT=BLOCKED_OR_INCONCLUSIVE $errorMessage"
}finally{
  if($null -ne $doc){
    try{$null=$doc.CloseDoc()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}
  }
  if($null -ne $app){
    try{$app.Quit()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}
  }
  $after=@(Snapshot)
  $after | Export-Csv -LiteralPath (Join-Path $run 'protected_after.csv') -NoTypeInformation -Encoding UTF8
  if(-not (EqualsSnap $before $after)){
    throw 'CRITICAL_PROTECTED_QVD_QVW_OR_M1_HASH_CHANGED: STOP'
  }
  Write-Output 'PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED=True'
}
if($null -ne $errorMessage){throw "M2_STOP: $errorMessage"}
Write-Output "CANDIDATE_QVW=$target"
Write-Output 'M2_VERDICT=BUILT_CANDIDATE_ONLY_NOT_HOMOLOGATED'
