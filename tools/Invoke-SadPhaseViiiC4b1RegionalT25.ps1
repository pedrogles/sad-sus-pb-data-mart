# C4-B1: regional 2018 service JP+CG T25 observational candidate, prepared only.
# Default reference-only; -RunQlik requires separate explicit approval.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$SourceQvw,
  [Parameter(Mandatory=$true)][string]$F1F2Dir,
  [Parameter(Mandatory=$true)][string]$F3Dir,
  [Parameter(Mandatory=$true)][string]$ExpectedHead,
  [string]$PhysicalAuthorization='',
  [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$branch='test/phase-viii-c4b1-regional-t25-runner-20261020'
$selfRel='tools/Invoke-SadPhaseViiiC4b1RegionalT25.ps1'
$self=Join-Path $repo $selfRel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'BLOCKED: runner must run from repo'}
$b=@(& git -C $repo branch --show-current 2>$null)
$h=@(& git -C $repo rev-parse HEAD 2>$null)
if($LASTEXITCODE -ne 0 -or $b.Count -ne 1 -or $h.Count -ne 1 -or
   $b[0] -cne $branch -or $h[0] -notmatch '^[a-f0-9]{40}$' -or
   $ExpectedHead -cne $h[0]){throw 'BLOCKED: Git branch/HEAD pinned mismatch'}
$null=& git -C $repo merge-base --is-ancestor 949e6e96b6e0f4e530672d52808ad178080bce28 HEAD 2>$null
if($LASTEXITCODE -ne 0){throw 'BLOCKED: not based on frozen main'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $selfRel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $selfRel)
if($tracked.Count -ne 1 -or $dirty.Count -ne 0){throw 'BLOCKED: runner not committed/clean'}
$blob=(& git -C $repo rev-parse ('HEAD:'+$selfRel)).Trim()
$live=(& git -C $repo hash-object --path=$selfRel -- $self).Trim()
if($LASTEXITCODE -ne 0 -or $blob -cne $live){throw 'BLOCKED: runner differs from committed blob'}
if($RunQlik -and $PhysicalAuthorization -cne 'C4B1_ONE_REGIONAL_TEST_ONLY'){throw 'BLOCKED: physical authorization token missing'}
$src=[IO.Path]::GetFullPath($SourceQvw)
$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
if(-not $src.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
   [IO.Path]::GetFileName($src) -cne 'SAD_VIII_T24_ANNUAL_TEST.qvw' -or
   [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($src)) -notmatch '^SAD_VIII_T24_[a-f0-9]{32}$' -or
   -not(Test-Path -LiteralPath $src -PathType Leaf)){throw 'BLOCKED: not a prior T24 TEMP QVW'}
$sourceHash=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
if($sourceHash -cne '7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E'){
  throw 'BLOCKED: source QVW differs from successfully reconciled T24 baseline'
}
$work=Join-Path $tmp ('SAD_VIII_C4B1_T25_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('VERSIONED_GIT_HEAD='+$h[0])
Write-Output ('SCRIPT_SHA256='+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('SOURCE_QVW_SHA256='+$sourceHash)
Write-Output 'MODE=C4B1_TEMP_COPY_NO_RELOAD QVD_WRITES=0 CANONICAL_QVW_WRITES=0'
function Snapshot([string]$kind){
  $items=@()
  if($kind -ceq 'QVD'){
    $ext=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO/QVD') -File -Filter '*.qvd')
    $trans=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO/QVD') -File -Filter '*.qvd')
    if($ext.Count -ne 10 -or $trans.Count -ne 12){throw 'BLOCKED: expected 10+12 QVDs'}
    $items=@($ext)+@($trans)
  }else{
    foreach($r in @('EXTRACAO/EXT.qvw','TRANSFORMACAO/TRANSF.qvw','PAINEL/PAINEL.qvw')){
      $p=Join-Path $repo $r
      if(Test-Path -LiteralPath $p -PathType Leaf){$items+=Get-Item -LiteralPath $p}
    }
  }
  $out=@()
  foreach($i in $items){
    $out += [pscustomobject]@{Path=$i.FullName;Length=$i.Length;SHA256=(Get-FileHash -LiteralPath $i.FullName -Algorithm SHA256).Hash}
  }
  return @($out|Sort-Object Path)
}
function Same($a,$b){
  return ((ConvertTo-Json -InputObject @($a) -Compress -Depth 3) -ceq
          (ConvertTo-Json -InputObject @($b) -Compress -Depth 3))
}
function Oracle([string]$folder,[string]$file,[string]$manifest){
  $csv=Join-Path $folder $file
  $mf=Join-Path $folder $manifest
  if(-not(Test-Path -LiteralPath $csv -PathType Leaf) -or
     -not(Test-Path -LiteralPath $mf -PathType Leaf)){throw ('BLOCKED: missing '+$file)}
  $m=Get-Content -LiteralPath $mf -Raw -Encoding UTF8|ConvertFrom-Json
  $v=[string]$m.output_sha256.$file
  $hash=(Get-FileHash -LiteralPath $csv -Algorithm SHA256).Hash
  if($v -notmatch '^[a-fA-F0-9]{64}$' -or $hash -cne $v.ToUpperInvariant()){throw ('BLOCKED: SHA oracle '+$file)}
  Write-Host ('ORACLE_'+$file+'_SHA256='+$hash)
  return $csv
}
function CountSelected([string]$field){
  $s=[string]$script:doc.Evaluate(('GetSelectedCount('+$field+')'))
  if($s -notmatch '^\d+$'){throw ('BLOCKED: selection count invalid '+$field+' -> '+$s)}
  return [int]$s
}
function SelectOne([string]$field,[string]$value){
  $null=$script:doc.GetField($field).Select($value)
  if((CountSelected $field) -ne 1){throw ('BLOCKED: selection failed '+$field)}
}
function Numeric([string]$expr){
  $s=[string]$script:doc.Evaluate($expr)
  if($s.Trim() -notmatch '^\d+([.,]\d+)?$'){throw ('BLOCKED: numeric result invalid '+$expr+' => '+$s)}
  return [decimal]::Parse($s.Trim().Replace(',','.'),[Globalization.NumberStyles]::AllowDecimalPoint,[Globalization.CultureInfo]::InvariantCulture)
}
$oldQvd=$null
$oldQvw=$null
$script:doc=$null
$passed=$false
try{
  $oldQvd=@(Snapshot 'QVD'); $oldQvw=@(Snapshot 'QVW')
  if($oldQvd.Count -ne 22 -or $oldQvw.Count -ne 3){throw 'BLOCKED: inventory requires 22 QVD and 3 QVW'}
  $oldQvd|Export-Csv -LiteralPath (Join-Path $work 'qvd_before.csv') -NoTypeInformation -Encoding UTF8
  $oldQvw|Export-Csv -LiteralPath (Join-Path $work 'canonical_qvw_before.csv') -NoTypeInformation -Encoding UTF8
  $link=Join-Path $repo 'TRANSFORMACAO/QVD/LINK_ANALISE.qvd'
  $match=@($oldQvd|Where-Object {$_.Path -ieq $link})
  if($match.Count -ne 1 -or $match[0].SHA256 -cne '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB'){
    throw 'BLOCKED: LINK_ANALISE baseline drift'
  }
  $mf1=Join-Path $F1F2Dir 'manifest_F1_F2.json'
  $mf3=Join-Path $F3Dir 'manifest_F3.json'
  if(-not(Test-Path -LiteralPath $mf1 -PathType Leaf) -or -not(Test-Path -LiteralPath $mf3 -PathType Leaf)){throw 'BLOCKED: manifest missing'}
  if((Get-FileHash -LiteralPath $mf1 -Algorithm SHA256).Hash -cne '926D5EE06373D6B30C3617501A9E81F2F0E6C16CFEF98A9EF1AAF25113EF025B' -or
     (Get-FileHash -LiteralPath $mf3 -Algorithm SHA256).Hash -cne '9FE3543374870878915A2ABAE6A88DFDB07778FDDA9D506A3B87A2DD2D98DA08'){
     throw 'BLOCKED: frozen manifest SHA mismatch'
  }
  $p2m=Oracle $F1F2Dir 'F2_lt_municipio_competencia_observado.csv' 'manifest_F1_F2.json'
  $p2a=Oracle $F1F2Dir 'F2_lt_municipio_ano_cobertura_candidata.csv' 'manifest_F1_F2.json'
  $p3s=Oracle $F3Dir 'F3_cenarios_multimunicipais.csv' 'manifest_F3.json'
  $p3p=Oracle $F3Dir 'F3_pop_municipio_ano.csv' 'manifest_F3.json'
  $pins=@{
    'F2_lt_municipio_competencia_observado.csv'='DC0FAE8646F6570F5DEEAF8A1597EA5ED90A5BD9A881A40B4DCA0E30380E953D'
    'F2_lt_municipio_ano_cobertura_candidata.csv'='97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D'
    'F3_cenarios_multimunicipais.csv'='3B7315A564666D43A43E60700B5ACC4E255FEF6535F53219EC3D8A08C74CBFF9'
    'F3_pop_municipio_ano.csv'='4AC341479A63EEA3FAA1FC2C20A3C2447C94294B940BDAFDFD9799BD555A7699'
  }
  foreach($p in @($p2m,$p2a,$p3s,$p3p)){
    if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -cne $pins[[IO.Path]::GetFileName($p)]){
      throw ('BLOCKED: frozen CSV SHA mismatch '+$p)
    }
  }
  $month=@(Import-Csv -LiteralPath $p2m -Delimiter ';' -Encoding UTF8)
  $annual=@(Import-Csv -LiteralPath $p2a -Delimiter ';' -Encoding UTF8)
  $scenario=@(Import-Csv -LiteralPath $p3s -Delimiter ';' -Encoding UTF8)
  $pop=@(Import-Csv -LiteralPath $p3p -Delimiter ';' -Encoding UTF8)
  if($month.Count -ne 3561 -or $annual.Count -ne 669 -or $scenario.Count -ne 12 -or $pop.Count -ne 669){throw 'BLOCKED: unexpected CSV counts'}
  $reg=@($scenario|Where-Object {$_.ano -ceq '2018' -and $_.papel -ceq 'SERV' -and $_.selecao -ceq 'JP_CG_2'})
  if($reg.Count -ne 1 -or $reg[0].codigos_municipios -cne '250400,250750' -or $reg[0].municipios_distintos -cne '2' -or
     $reg[0].capacidade_estado -cne 'CANDIDATO_RN21_SEM_ESCOPO_HOSPITALAR' -or
     $reg[0].capacidade_media_sus_divisor_candidato -cne '12'){throw 'BLOCKED: F3 regional scope/key mismatch'}
  $sumCity=@{}
  $sumMonth=@{}
  $oracleRows=@()
  [long]$sus=0; [long]$people=0
  foreach($mun in @('250400','250750')){
    $mc=@($month|Where-Object {$_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun})
    $ac=@($annual|Where-Object {$_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun})
    $pc=@($pop|Where-Object {$_.ano -ceq '2018' -and $_.cod_datasus_6 -ceq $mun})
    if($mc.Count -ne 12 -or $ac.Count -ne 1 -or $pc.Count -ne 1){throw ('BLOCKED: expected 12 F2 and one annual F2/F3 for '+$mun)}
    if($ac[0].meses_observados -cne '12' -or $ac[0].meses_esperados -cne '12' -or
       $ac[0].competencias_sem_linhas_lt -cne '' -or $ac[0].media_sus_divisor_exato -cne '12' -or
       $ac[0].cobertura_presenca_linhas -cne '12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED' -or
       $ac[0].universo -cne 'LT_TODOS_REGISTROS_VALIDOS_RN21' -or
       $ac[0].hospitalar_historico_validado -cne 'NAO'){throw ('BLOCKED: F2 annual coverage invalid '+$mun)}
    $set=@{}
    [long]$cityTotal=0
    foreach($r in $mc){
      $period=[string]$r.competencia
      if($period -notmatch '^2018(0[1-9]|1[0-2])$' -or $set.ContainsKey($period) -or
         $r.estado -cne 'LINHAS_OBSERVADAS_NUMEROS_RECONCILIADOS' -or
         $r.universo -cne 'LT_TODOS_REGISTROS_VALIDOS_RN21' -or
         [long]$r.linhas_lt -le 0 -or [long]$r.qt_sus -lt 0 -or
         [long]$r.qt_nsus -lt 0 -or [long]$r.qt_exist -ne ([long]$r.qt_sus+[long]$r.qt_nsus)){
        throw ('BLOCKED: invalid F2 city/month '+$mun+'/'+$period)
      }
      $set[$period]=$true
      $val=[long]$r.qt_sus
      $cityTotal+=$val
      if(-not $sumMonth.ContainsKey($period)){$sumMonth[$period]=[long]0}
      $sumMonth[$period]+=$val
      $oracleRows += [pscustomobject]@{City=$mun;Month=$period;F2SUS=$val;Status='OBSERVED_RN21_NOT_HOSPITAL_VERIFIED'}
    }
    for($i=1;$i -le 12;$i++){
      $p='2018'+('{0:D2}' -f $i)
      if(-not $set.ContainsKey($p)){throw ('BLOCKED: missing '+$mun+'/'+$p)}
    }
    if($cityTotal -ne [long]$ac[0].qt_sus_soma_snapshots_auditoria -or
       $cityTotal -ne [long]$ac[0].media_sus_numerador_exato){throw ('BLOCKED: annual/month F2 mismatch '+$mun)}
    $sumCity[$mun]=$cityTotal
    $sus+=$cityTotal
    $people += [long]$pc[0].populacao_estimada
    Write-Output ('C4B1_CITY='+$mun+' MONTHS=12 SUS_AUDIT='+$cityTotal+' POP='+$pc[0].populacao_estimada)
  }
  if($oracleRows.Count -ne 24 -or $sumMonth.Count -ne 12 -or
     $sumCity['250400'] -ne 16592 -or $sumCity['250750'] -ne 28106 -or
     $sus -ne 44698 -or $people -ne 1207795 -or
     $sus -ne [long]$reg[0].capacidade_media_sus_numerador_candidato -or
     $people -ne [long]$reg[0].denominador_pop_somado_uma_vez -or
     [long]$reg[0].numerador_internacoes_elegiveis -ne 119857){throw 'BLOCKED: F2/F3 regional totals mismatch'}
  $rate=[decimal]1000*[decimal]$sus/[decimal]12/[decimal]$people
  $oracleRows|Sort-Object Month,City|
    Export-Csv -LiteralPath (Join-Path $work 'c4b1_f2_24_rows.csv') -Encoding UTF8 -NoTypeInformation
  [pscustomobject]@{Case='2018_SERV_JP_CG_2';F2SUSSnapshotAudit=$sus;F3POPOneYear=$people;
    T25CandidatePer1000=$rate;Universe='LT_TODOS_REGISTROS_VALIDOS_RN21';HospitalScope='NOT_VERIFIED'}|
    Export-Csv -LiteralPath (Join-Path $work 'c4b1_oracle_summary.csv') -Encoding UTF8 -NoTypeInformation
  Write-Output ('C4B1_ORACLE=PASS_24 F2_SNAPSHOT_AUDIT='+$sus+' POP='+$people+' T25_CANDIDATE_PER_1000='+$rate)
  if(-not $RunQlik){
    Write-Output 'VERDICT=PASS_REFERENCE_ONLY_C4B1_COM_NOT_RUN'
  }else{
    if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'BLOCKED: Windows required'}
    $copy=Join-Path $work 'C4B1_T25_DISPOSABLE.qvw'
    Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
    if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash){throw 'BLOCKED: TEMP copy SHA changed'}
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $script:doc=$qv.OpenDoc($copy,'','')
    if($null -eq $script:doc){throw 'BLOCKED: QlikView OpenDoc failed'}
    if(-not ([string]($script:doc.GetProperties().Script)).Contains('[VIII-B-T24] VERDICT=PASS_RELOAD_STRUCTURE_ONLY_NOT_T24')){
      throw 'BLOCKED: QVW model marker mismatch'
    }
    function SelectRegion(){
      $null=$script:doc.GetField('SERV_COD_DATASUS_6').Select('250750')
      $null=$script:doc.GetField('SERV_COD_DATASUS_6').ToggleSelect('250400')
      if((CountSelected 'SERV_COD_DATASUS_6') -ne 2 -or
         (CountSelected 'RES_COD_DATASUS_6') -ne 0 -or
         (CountSelected 'COD_PROCEDIMENTO') -ne 0){throw 'BLOCKED: incompatible regional service state'}
    }
    $null=$script:doc.ClearAll()
    SelectOne 'PERIODO_ANO' '2018'
    SelectRegion
    if((CountSelected 'PERIODO_ANO') -ne 1 -or (CountSelected 'PERIODO_COMPETENCIA') -ne 0){
      throw 'BLOCKED: annual year/month selection drift'
    }
    $actualSUS=Numeric 'Sum(QTD_LEITOS_SUS)'
    $actualPopRows=Numeric 'Count(POPULACAO_ESTIMADA)'
    $actualPop=Numeric 'Sum(POPULACAO_ESTIMADA)'
    $actualRate=Numeric '1000*Sum(QTD_LEITOS_SUS)/12/Sum(POPULACAO_ESTIMADA)'
    $delta=[Math]::Abs([decimal]($actualRate-$rate))
    $isPass=($actualSUS -eq $sus -and $actualPopRows -eq 2 -and
             $actualPop -eq $people -and $delta -le [decimal]0.000001)
    $annualResult=[pscustomobject]@{Case='2018_SERV_JP_CG_2';F2SnapshotSum=$sus;QlikSnapshotSum=$actualSUS;
      F3POP=$people;QlikPOP=$actualPop;QlikPOPRows=$actualPopRows;ExpectedRate=$rate;
      QlikRate=$actualRate;Error=$delta;Status=$(if($isPass){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})}
    $annualResult|Export-Csv -LiteralPath (Join-Path $work 'c4b1_annual_reconciliation.csv') -NoTypeInformation -Encoding UTF8
    Write-Output ('C4B1_ANNUAL='+$annualResult.Status+' F2='+$sus+' QLIK='+$actualSUS+' F3POP='+$people+
                  ' QLIKPOP='+$actualPop+' POP_ROWS='+$actualPopRows)
    if(-not $isPass){throw 'BLOCKED: annual candidate ratio/POP/bed mismatch'}
    [long]$sumQlik=0
    $monthResults=@()
    for($i=1;$i -le 12;$i++){
      $period='2018'+('{0:D2}' -f $i)
      $null=$script:doc.ClearAll()
      SelectOne 'PERIODO_ANO' '2018'
      SelectRegion
      SelectOne 'PERIODO_COMPETENCIA' $period
      if((CountSelected 'PERIODO_ANO') -ne 1 -or
         (CountSelected 'SERV_COD_DATASUS_6') -ne 2 -or
         (CountSelected 'PERIODO_COMPETENCIA') -ne 1 -or
         (CountSelected 'RES_COD_DATASUS_6') -ne 0){throw ('BLOCKED: month selection drift '+$period)}
      $want=[decimal]$sumMonth[$period]; $actual=Numeric 'Sum(QTD_LEITOS_SUS)'
      $monthResults += [pscustomobject]@{Period=$period;F2Regional=$want;QlikRegional=$actual;
        Status=$(if($want -eq $actual){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})}
      $monthResults|Export-Csv -LiteralPath (Join-Path $work 'c4b1_monthly_reconciliation.csv') -NoTypeInformation -Encoding UTF8
      if($want -ne $actual){throw ('BLOCKED: month regional LT mismatch '+$period)}
      $sumQlik += [long]$actual
    }
    if($sumQlik -ne $sus){throw 'BLOCKED: annual/month sum inconsistent'}
    $passed=$true
    Write-Output 'C4B1_ANNUAL_AND_12_MONTH_COMPONENTS=PASS_CANDIDATE_PENDING_FINAL_HASHES'
  }
}catch{
  Write-Output ('VERDICT=BLOCKED_OR_INCONCLUSIVE '+$_.Exception.Message)
  throw
}finally{
  if($null -ne $script:doc){try{$null=$script:doc.CloseDoc()}catch{}}
  if($null -ne $oldQvd){
    $after=@(Snapshot 'QVD')
    $after|Export-Csv -LiteralPath (Join-Path $work 'qvd_after.csv') -NoTypeInformation -Encoding UTF8
    if(-not(Same $oldQvd $after)){throw 'STOP_CRITICAL_PRESERVATION: QVD hashes changed'}
    Write-Output 'ORIGINAL_22_QVD_SHA256_UNCHANGED=True'
  }
  if($null -ne $oldQvw){
    $after=@(Snapshot 'QVW')
    $after|Export-Csv -LiteralPath (Join-Path $work 'canonical_qvw_after.csv') -NoTypeInformation -Encoding UTF8
    if(-not(Same $oldQvw $after)){throw 'STOP_CRITICAL_PRESERVATION: QVW hashes changed'}
    Write-Output 'ORIGINAL_CANONICAL_QVWS_UNCHANGED=True'
  }
  if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -cne $sourceHash){
    throw 'STOP_CRITICAL_PRESERVATION: original TEMP QVW changed'
  }
  Write-Output 'SOURCE_T24_QVW_SHA256_UNCHANGED=True'
}
if($RunQlik -and $passed){
  Write-Output 'VERDICT=PASS_LOCAL_C4B1_REGIONAL_SERVICE_T25_OBSERVED_CANDIDATE_ONLY'
  Write-Output 'HOSPITAL_SCOPE=NOT_VERIFIED LINK_KEY_CONTRACT=NOT_APPROVED MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED PRODUCTION_APPROVED=False'
}
