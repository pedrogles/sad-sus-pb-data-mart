#requires -Version 5.1
[CmdletBinding()]
param(
  [string]$ArtifactRoot=(Join-Path $env:USERPROFILE 'documents\programming\sad-sus-pb-data-mart'),
  [string]$SourceQvw=(Join-Path $env:USERPROFILE 'SAD_VIS05_EVIDENCIAS\VIS05_20261112_171721_950990d1\SAD_MVP_VIS05_UX_WORK_TEMP.qvw'),
  [switch]$SelfTest
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$expectedSource='B56D0A8550AB7EEE68D45DB0249F273DED05C4ADEE88DBE3FC7A20B162084DBB'
$oldLabel='Ano da Internação'
$newLabel='Ano de competência'
function Sha([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()}
function WriteJson([string]$Path,$Value){[IO.File]::WriteAllText($Path,(ConvertTo-Json -InputObject $Value -Depth 90),[Text.UTF8Encoding]::new($false))}
function Json($Value){return ConvertTo-Json -InputObject $Value -Depth 90 -Compress}
function ReadNode($Value,[int]$Depth=0){
  if($null -eq $Value -or $Value -is [string] -or $Value -is [ValueType]){return $Value}
  if($Depth -gt 16){throw 'PROPERTY_SNAPSHOT_DEPTH_LIMIT'}
  $script:budget--
  if($script:budget -lt 0){throw 'PROPERTY_SNAPSHOT_BUDGET_LIMIT'}
  $names=@(Get-Member -InputObject $Value -MemberType Property | Select-Object -ExpandProperty Name | Sort-Object -Unique)
  if($names -contains 'Count'){
    $count=[int]$Value.Count
    if($count -lt 0 -or $count -gt 1000){throw 'PROPERTY_COLLECTION_LIMIT'}
    $items=@()
    for($n=0;$n -lt $count;$n++){$items+=,(ReadNode ($Value.Item($n)) ($Depth+1))}
    return [ordered]@{items=$items}
  }
  if($names.Count -eq 0){throw 'UNREADABLE_PROPERTY_NODE'}
  $result=[ordered]@{}
  foreach($name in $names){
    if($name -in @('Item','Default','_NewEnum')){continue}
    $result[$name]=ReadNode $Value.$name ($Depth+1)
  }
  return $result
}
function GetCharts($Doc){
  $charts=@{}
  for($s=0;$s -lt 3;$s++){
    foreach($chart in @($Doc.GetSheet($s).GetSheetObjects())){
      if($null -eq $chart){continue}
      $id=([string]$chart.GetObjectID()) -replace '^Document\\',''
      if($id -cmatch '^CH[0-9]+$'){
        if($charts.ContainsKey($id)){throw 'DUPLICATE_CHART'}
        $charts[$id]=@{object=$chart;sheet=$s}
      }
    }
  }
  if($charts.Count -ne 9){throw 'EXPECTED_NINE_CHARTS'}
  foreach($i in 1..9){if(-not $charts.ContainsKey(('CH{0:00}' -f $i))){throw 'CHART_ID_MISSING'}}
  if($charts.CH01.sheet -ne 0){throw 'CH01_SHEET_MISMATCH'}
  return $charts
}
function ChartState($Charts){
  $out=[ordered]@{}
  foreach($id in @($Charts.Keys | Sort-Object)){
    $p=$Charts[$id].object.GetProperties();$script:budget=100000
    $dimensions=ReadNode $p.Dimensions
    $expressions=ReadNode $p.Expressions
    if($id -ceq 'CH01'){
      if([int]$p.Dimensions.Count -ne 1){throw 'CH01_EXPECTED_ONE_DIMENSION'}
      $dimensions.items[0].Title.v='__AUTHORIZED_LABEL__'
    }
    $out[$id]=[ordered]@{sheet=$Charts[$id].sheet;title=[string]$p.GraphLayout.WindowTitle.v;condition=[string]$p.EvaluationCondition.v;dimensions=$dimensions;expressions=$expressions}
  }
  return $out
}
function ApplyLabel($Chart){
  $p=$Chart.GetProperties()
  if([int]$p.Dimensions.Count -ne 1){throw 'CH01_EXPECTED_ONE_DIMENSION'}
  $title=[string]$p.Dimensions.Item(0).Title.v
  if($title -cne $oldLabel){throw ('UNEXPECTED_OLD_LABEL: '+$title)}
  $p.Dimensions.Item(0).Title.v=$newLabel
  $null=$Chart.SetProperties($p)
  if([string]$Chart.GetProperties().Dimensions.Item(0).Title.v -cne $newLabel){throw 'LABEL_READBACK_FAILED'}
}
if($SelfTest){
  $collection=[pscustomobject]@{Count=1;data=@([pscustomobject]@{Title=[pscustomobject]@{v=$oldLabel};Definition='PERIODO_ANO'})}
  $collection | Add-Member ScriptMethod Item {param($i) return $this.data[$i]}
  $mock=[pscustomobject]@{props=[pscustomobject]@{Dimensions=$collection};writes=0}
  $mock | Add-Member ScriptMethod GetProperties {return $this.props}
  $mock | Add-Member ScriptMethod SetProperties {param($p) $this.writes++;$this.props=$p}
  ApplyLabel $mock
  if($mock.writes -ne 1 -or $collection.Item(0).Definition -cne 'PERIODO_ANO'){throw 'MOCK_MUTATION_FAILED'}
  $collection.Item(0).Title.v='Outro eixo';$mock.writes=0;$blocked=$false
  try{ApplyLabel $mock}catch{$blocked=$true}
  if(-not $blocked -or $mock.writes -ne 0){throw 'UNEXPECTED_LABEL_NOT_BLOCKED'}
  $collection.Count=2;$mock.writes=0;$blocked=$false
  try{ApplyLabel $mock}catch{$blocked=$true}
  if(-not $blocked -or $mock.writes -ne 0){throw 'DIMENSION_COUNT_NOT_BLOCKED'}
  Write-Output 'SELF_TEST=PASS_MOCK_ONLY_NO_WINDOWS_OR_QLIKVIEW_EXECUTION'
  exit 0
}
$run=$null;$doc=$null;$app=$null;$locks=@();$before=@();$target=$null;$success=$false
$report=[ordered]@{status='PREPARING';started=(Get-Date).ToString('o');old_label=$oldLabel;new_label=$newLabel;target_object='CH01';target_sheet='Produção Hospitalar';property='Dimensions.Item(0).Title.v';save_called=$false;reload_called=$false;reopened_label_verified=$false;checked_chart_properties_preserved=$false;integrity_verified=$false;visual_review='PENDING_USER';cleanup_errors=@()}
try{
  if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'WINDOWS_QLIKVIEW_REQUIRED'}
  if(Get-Process -Name Qv -ErrorAction SilentlyContinue){throw 'Feche o QlikView antes de executar; nenhum processo foi encerrado.'}
  $manifestPath=Join-Path $PSScriptRoot 'package.json'
  if(-not(Test-Path -LiteralPath $manifestPath -PathType Leaf)){throw 'PACKAGE_MANIFEST_MISSING'}
  $manifest=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if([string]$manifest.commit -notmatch '^[0-9a-f]{40}$' -or (Sha $PSCommandPath) -cne [string]$manifest.script_sha256){throw 'PACKAGE_SCRIPT_HASH_MISMATCH'}
  $report.script_commit=[string]$manifest.commit;$report.script_sha256=Sha $PSCommandPath
  if((Sha $SourceQvw) -cne $expectedSource){throw 'O QVW de origem difere da versão conferida; nenhuma alteração foi aplicada.'}
  $qvds=@(Get-ChildItem -LiteralPath (Join-Path $ArtifactRoot 'EXTRACAO\QVD') -Filter '*.qvd' -File)
  if($qvds.Count -ne 10){throw 'EXPECTED_TEN_EXTRACTION_QVDS'}
  $trans=@(Get-ChildItem -LiteralPath (Join-Path $ArtifactRoot 'TRANSFORMACAO\QVD') -Filter '*.qvd' -File)
  if($trans.Count -ne 12){throw 'EXPECTED_TWELVE_TRANSFORMATION_QVDS'}
  $paths=@($qvds.FullName)+@($trans.FullName)+@('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw' | ForEach-Object {Join-Path $ArtifactRoot $_})+@($SourceQvw)
  $paths=@($paths | ForEach-Object {[IO.Path]::GetFullPath($_)} | Sort-Object -Unique)
  if($paths.Count -ne 26){throw 'EXPECTED_26_PROTECTED_FILES'}
  foreach($path in $paths){
    $locks+=,[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    $before+=@{path=$path;sha256=(Sha $path);bytes=(Get-Item -LiteralPath $path).Length}
  }
  $root=Join-Path $env:USERPROFILE 'SAD_FINAL_EVIDENCIAS'
  $run=Join-Path $root ('M1_ROTULO_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,10))
  $null=New-Item -ItemType Directory -Path $run
  $target=Join-Path $run 'SAD_PB_ANO_COMPETENCIA_CONFERIR.qvw'
  [IO.File]::Copy($SourceQvw,$target,$false)
  (Get-Item -LiteralPath $target).IsReadOnly=$false
  if((Sha $target) -cne $expectedSource){throw 'COPY_HASH_MISMATCH'}
  $report.source_qvw=$SourceQvw;$report.work_qvw=$target;$report.protected_before=$before
  WriteJson (Join-Path $run 'alteracao.json') $report
  Write-Host 'Conferindo as propriedades. Nenhuma recarga será executada.'
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$app.OpenDoc($target)
  if($null -eq $doc){throw 'COPY_OPEN_FAILED'}
  $charts=GetCharts $doc
  $state=ChartState $charts
  WriteJson (Join-Path $run 'chart_properties_before.json') $state
  ApplyLabel $charts.CH01.object
  $after=ChartState (GetCharts $doc)
  if((Json $state) -cne (Json $after)){throw 'CHART_PROPERTY_DIFFERENCE_BEYOND_AUTHORIZED_LABEL'}
  $report.checked_chart_properties_preserved=$true
  $null=$doc.GetSheet(0).Activate()
  $report.save_called=$true;$null=$doc.Save()
  $null=$doc.CloseDoc();$doc=$null
  $doc=$app.OpenDoc($target)
  if($null -eq $doc){throw 'SAVED_COPY_REOPEN_FAILED'}
  $charts=GetCharts $doc
  if([string]$charts.CH01.object.GetProperties().Dimensions.Item(0).Title.v -cne $newLabel){throw 'SAVED_LABEL_NOT_PERSISTED'}
  $final=ChartState $charts
  WriteJson (Join-Path $run 'chart_properties_reopened.json') $final
  if((Json $state) -cne (Json $final)){throw 'REOPENED_CHART_PROPERTY_DIFFERENCE'}
  $report.reopened_label_verified=$true
  $success=$true
}catch{
  $report.status='BLOCKED';$report.failure=$_.Exception.Message
  Write-Host ('Não concluído: '+$report.failure)
}finally{
  if($null -ne $doc){try{$null=$doc.CloseDoc()}catch{$report.cleanup_errors+=@($_.Exception.Message)}}
  if($null -ne $app){try{$app.Quit()}catch{$report.cleanup_errors+=@($_.Exception.Message)}}
  if($before.Count -eq 26){
    try{
      $afterFiles=@(foreach($p in $paths){@{path=$p;sha256=(Sha $p);bytes=(Get-Item -LiteralPath $p).Length}})
      $report.protected_after=$afterFiles
      $report.integrity_verified=((Json $before) -ceq (Json $afterFiles))
      if(-not $report.integrity_verified){throw 'PROTECTED_FILE_CHANGED'}
    }catch{$success=$false;$report.status='BLOCKED_INTEGRITY';$report.integrity_error=$_.Exception.Message}
  }
  foreach($lock in $locks){$lock.Dispose()}
  if($report.cleanup_errors.Count -gt 0){$success=$false;$report.status='BLOCKED_CLEANUP'}
  if($success -and $report.integrity_verified){$report.status='LABEL_SAVED_REOPENED_PROPERTIES_CHECKED_VISUAL_PENDING';$report.work_sha256=Sha $target}
  $report.finished=(Get-Date).ToString('o')
  if($null -ne $run){
    WriteJson (Join-Path $run 'alteracao.json') $report
    Write-Host ('RELATORIO='+ (Join-Path $run 'alteracao.json'))
  }
}
if(-not $success){exit 1}
Write-Host ('ARQUIVO_CORRIGIDO='+$target)
Write-Host 'Alterado: Ano da Internação -> Ano de competência. Confira o eixo do gráfico anual.'
Write-Host 'Envie alteracao.json e uma captura da folha Produção Hospitalar para a conferência final.'
Invoke-Item -LiteralPath $target
exit 0
