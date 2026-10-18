# VIII-B: T26 candidate. Annual eligible service RD admissions / mean LT SUS observed 12 snapshots.
# Input: previously PASSed TEMP T24 QVW. Only a new TEMP copy is opened.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$SourceQvw,
  [Parameter(Mandatory=$true)][string]$F1F2Dir,
  [Parameter(Mandatory=$true)][string]$F3Dir,
  [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$branch='test/phase-viii-b-t26-observed-lt-2018-20261018'
$selfRel='tools/Invoke-SadPhaseViiiT26ObservedLt2018.ps1'
$self=Join-Path $repo $selfRel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'BLOCKED: runner must run from repo'}
$b=@(& git -C $repo branch --show-current 2>$null)
$h=@(& git -C $repo rev-parse HEAD 2>$null)
if($LASTEXITCODE -ne 0 -or $b.Count -ne 1 -or $h.Count -ne 1 -or
   $b[0] -cne $branch -or $h[0] -notmatch '^[a-f0-9]{40}$'){throw 'BLOCKED: Git branch/HEAD'}
$null=& git -C $repo merge-base --is-ancestor 337943d5c5b77067f842902fc679dbb68db87020 HEAD 2>$null
if($LASTEXITCODE -ne 0){throw 'BLOCKED: not based on frozen main'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $selfRel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $selfRel)
if($tracked.Count -ne 1 -or $dirty.Count -ne 0){throw 'BLOCKED: runner not committed/clean'}
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
$work=Join-Path $tmp ('SAD_VIII_T26_OBS_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('VERSIONED_GIT_HEAD='+$h[0])
Write-Output ('SCRIPT_SHA256='+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('SOURCE_QVW_SHA256='+$sourceHash)
Write-Output 'MODE=TEMP_COPY_NO_RELOAD QVD_WRITES=0 CANONICAL_QVW_WRITES=0'
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
$pass=$false
$casesOut=@()
$guardsOut=@()
try{
  $oldQvd=@(Snapshot 'QVD')
  $oldQvw=@(Snapshot 'QVW')
  $oldQvd|Export-Csv -LiteralPath (Join-Path $work 'qvd_before.csv') -NoTypeInformation -Encoding UTF8
  $oldQvw|Export-Csv -LiteralPath (Join-Path $work 'canonical_qvw_before.csv') -NoTypeInformation -Encoding UTF8
  $link=Join-Path $repo 'TRANSFORMACAO/QVD/LINK_ANALISE.qvd'
  $matched=@($oldQvd|Where-Object {$_.Path -ieq $link})
  if($matched.Count -ne 1 -or $matched[0].SHA256 -cne '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB'){
    throw 'BLOCKED: LINK_ANALISE physical baseline drift'
  }
  $f1Month=Oracle $F1F2Dir 'F1_servico_competencia.csv' 'manifest_F1_F2.json'
  $f1Year=Oracle $F1F2Dir 'F1_servico_ano.csv' 'manifest_F1_F2.json'
  $f2Month=Oracle $F1F2Dir 'F2_lt_municipio_competencia_observado.csv' 'manifest_F1_F2.json'
  $f2Year=Oracle $F1F2Dir 'F2_lt_municipio_ano_cobertura_candidata.csv' 'manifest_F1_F2.json'
  $f3Service=Oracle $F3Dir 'F3_componentes_servico_ano.csv' 'manifest_F3.json'
  $rdMonthly=@(Import-Csv -LiteralPath $f1Month -Delimiter ';' -Encoding UTF8)
  $rdAnnual=@(Import-Csv -LiteralPath $f1Year -Delimiter ';' -Encoding UTF8)
  $ltMonthly=@(Import-Csv -LiteralPath $f2Month -Delimiter ';' -Encoding UTF8)
  $ltAnnual=@(Import-Csv -LiteralPath $f2Year -Delimiter ';' -Encoding UTF8)
  $f3=@(Import-Csv -LiteralPath $f3Service -Delimiter ';' -Encoding UTF8)
  if($rdMonthly.Count -lt 24 -or $rdAnnual.Count -lt 2 -or
     $ltMonthly.Count -lt 24 -or $ltAnnual.Count -ne 669 -or $f3.Count -ne 669){
    throw 'BLOCKED: F1/F2/F3 oracle cardinalities outside expected baseline'
  }
  $pilot=@()
  foreach($mun in @('250750','250400')){
    $admMonths=@($rdMonthly | Where-Object { $_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun })
    $admYear=@($rdAnnual | Where-Object { $_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun })
    $susMonths=@($ltMonthly | Where-Object { $_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun })
    $susYear=@($ltAnnual | Where-Object { $_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun })
    $f3Year=@($f3 | Where-Object { $_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun })
    if($admMonths.Count -ne 12 -or $susMonths.Count -ne 12 -or
       $admYear.Count -ne 1 -or $susYear.Count -ne 1 -or $f3Year.Count -ne 1){
      throw ('BLOCKED: incomplete RD/LT month coverage '+$mun)
    }
    if($susYear[0].meses_observados -cne '12' -or
       $susYear[0].meses_esperados -cne '12' -or
       $susYear[0].competencias_sem_linhas_lt -cne '' -or
       $susYear[0].cobertura_presenca_linhas -cne '12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED' -or
       $susYear[0].universo -cne 'LT_TODOS_REGISTROS_VALIDOS_RN21' -or
       $susYear[0].hospitalar_historico_validado -cne 'NAO' -or
       $f3Year[0].estado_capacidade -cne '12_MESES_LINHAS_ESCOPO_NAO_VERIFICADO' -or
       $f3Year[0].meses_lt_com_linhas -cne '12'){
      throw ('BLOCKED: CNES/LT observed scope not explicitly caveated '+$mun)
    }
    $rdByMonth=@{}
    $ltByMonth=@{}
    [long]$rdSum=0
    [long]$ltSum=0
    foreach($r in $admMonths){
      $period=[string]$r.competencia
      if($period -notmatch '^2018(0[1-9]|1[0-2])$' -or $rdByMonth.ContainsKey($period)){
        throw ('BLOCKED: invalid/duplicate RD month '+$mun+'/'+$period)
      }
      [long]$new=[long]$r.internacoes_elegiveis
      [long]$cont=[long]$r.continuidades_ident5
      [long]$rows=[long]$r.registros_rd
      if($new -lt 0 -or $cont -lt 0 -or $rows -ne ($new+$cont)){
        throw ('BLOCKED: RD IDENT components invalid '+$mun+'/'+$period)
      }
      $rdByMonth[$period]=$new
      $rdSum+=$new
    }
    foreach($r in $susMonths){
      $period=[string]$r.competencia
      if($period -notmatch '^2018(0[1-9]|1[0-2])$' -or $ltByMonth.ContainsKey($period) -or
         $r.estado -cne 'LINHAS_OBSERVADAS_NUMEROS_RECONCILIADOS' -or
         $r.universo -cne 'LT_TODOS_REGISTROS_VALIDOS_RN21' -or
         [long]$r.linhas_lt -le 0 -or [long]$r.qt_sus -lt 0){
        throw ('BLOCKED: invalid LT observed snapshot '+$mun+'/'+$period)
      }
      $ltByMonth[$period]=[long]$r.qt_sus
      $ltSum += [long]$r.qt_sus
    }
    for($i=1;$i -le 12;$i++){
      $period=('2018'+'{0:D2}' -f $i)
      if(-not $rdByMonth.ContainsKey($period) -or -not $ltByMonth.ContainsKey($period)){
        throw ('BLOCKED: missing RD/LT month '+$mun+'/'+$period)
      }
    }
    if($rdSum -ne [long]$admYear[0].internacoes_elegiveis -or
       [long]$admYear[0].registros_rd -ne
         ([long]$admYear[0].internacoes_elegiveis + [long]$admYear[0].continuidades_ident5) -or
       $rdSum -ne [long]$f3Year[0].internacoes_elegiveis -or
       $ltSum -ne [long]$susYear[0].qt_sus_soma_snapshots_auditoria -or
       $ltSum -ne [long]$susYear[0].media_sus_numerador_exato -or
       $susYear[0].media_sus_divisor_exato -cne '12' -or
       $ltSum -ne [long]$f3Year[0].soma_qt_sus_snapshots_auditoria -or
       $f3Year[0].media_qt_sus_divisor_candidato -cne '12' -or
       $ltSum -ne [long]$f3Year[0].media_qt_sus_numerador_candidato -or
       $ltSum -le 0){
      throw ('BLOCKED: F1/F2/F3 service annual evidence mismatch '+$mun)
    }
    $pilot += [pscustomobject]@{
      Municipality=$mun;Admissions=$rdSum;SusAuditSum=$ltSum;
      RDMonth=$rdByMonth;LTMonth=$ltByMonth
    }
    Write-Output ('ORACLE_T26='+$mun+' YEAR=2018 RD_ELIGIBLE='+$rdSum+
      ' LT_SUM_12_AUDIT='+$ltSum+' LT_DIVISOR=12 HOSPITAL_SCOPE=NOT_VERIFIED')
  }
  if(-not $RunQlik){
    Write-Output 'VERDICT=PASS_REFERENCE_READONLY_ONLY_COM_NOT_RUN'
  }else{
    if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'BLOCKED: native Windows required'}
    $copy=Join-Path $work 'T26_OBSERVED_DISPOSABLE.qvw'
    Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
    if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash){throw 'BLOCKED: QVW TEMP copy SHA drift'}
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $script:doc=$qv.OpenDoc($copy,'','')
    if($null -eq $script:doc){throw 'BLOCKED: QlikView COM OpenDoc returned null'}
    if(-not ([string]($script:doc.GetProperties().Script)).Contains('[VIII-B-T24] VERDICT=PASS_RELOAD_STRUCTURE_ONLY_NOT_T24')){
      throw 'BLOCKED: QVW script not from the phase VIII-B T24 pilot'
    }
    foreach($c in $pilot){
      $mun=[string]$c.Municipality
      $null=$script:doc.ClearAll()
      SelectOne 'PERIODO_ANO' '2018'
      SelectOne 'SERV_COD_DATASUS_6' $mun
      if((CountSelected 'PERIODO_COMPETENCIA') -ne 0 -or
         (CountSelected 'RES_COD_DATASUS_6') -ne 0 -or
         (CountSelected 'COD_PROCEDIMENTO') -ne 0 -or
         (CountSelected 'COD_TIPO_LEITO') -ne 0){
        throw ('BLOCKED: wrong/incompatible selection for T26 service '+$mun)
      }
      $actualRD=Numeric 'Sum(QTD_INTERNACAO)'
      $actualLT=Numeric 'Sum(QTD_LEITOS_SUS)'
      # Only audited twelve-month LT; never treat the snapshot sum as beds per year.
      $actualRatio=Numeric '12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS)'
      $expectRatio=[decimal]12*[decimal]$c.Admissions/[decimal]$c.SusAuditSum
      $error=[Math]::Abs([decimal]($actualRatio-$expectRatio))
      $passAnnual=($actualRD -eq $c.Admissions -and
                   $actualLT -eq $c.SusAuditSum -and
                   $error -le [decimal]0.000001)
      $casesOut += [pscustomobject]@{
        Case='T26_ANNUAL_SERVICE_2018';Municipality=$mun;Year=2018;Role='SERVICE'
        F1Eligible=$c.Admissions;QlikEligible=$actualRD
        F2SUSMonthlyAuditSum=$c.SusAuditSum;QlikSUSMonthlyAuditSum=$actualLT
        MeanSUSDenominator=([decimal]$c.SusAuditSum/[decimal]12)
        OracleRatio=$expectRatio;QlikRatio=$actualRatio;AbsoluteError=$error
        Status=$(if($passAnnual){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})
      }
      $casesOut | Export-Csv -LiteralPath (Join-Path $work 't26_annual.csv') -NoTypeInformation -Encoding UTF8
      Write-Output ('T26_ANNUAL_CASE='+$mun+' RESULT='+$casesOut[-1].Status+
        ' RD_F1='+$c.Admissions+' RD_QLIK='+$actualRD+
        ' LT_F2_SUM12='+$c.SusAuditSum+' LT_QLIK_SUM12='+$actualLT+' MEAN_DIVISOR=12')
      if(-not $passAnnual){throw ('BLOCKED: T26 annual cross-fact mismatch '+$mun)}
    }
    # Validate one partial month without dividing an already selected month by twelve.
    $jp=@($pilot | Where-Object {$_.Municipality -ceq '250750'})
    if($jp.Count -ne 1){throw 'BLOCKED: JP oracle unavailable'}
    $null=$script:doc.ClearAll()
    SelectOne 'PERIODO_ANO' '2018'
    SelectOne 'SERV_COD_DATASUS_6' '250750'
    SelectOne 'PERIODO_COMPETENCIA' '201801'
    if((CountSelected 'PERIODO_ANO') -ne 1 -or
       (CountSelected 'PERIODO_COMPETENCIA') -ne 1 -or
       (CountSelected 'SERV_COD_DATASUS_6') -ne 1){
      throw 'BLOCKED: January 2018 selection not preserved'
    }
    [long]$wantRD=[long]$jp[0].RDMonth['201801']
    [long]$wantLT=[long]$jp[0].LTMonth['201801']
    if($wantLT -le 0){throw 'BLOCKED: January SUS denominator not positive'}
    $gotRD=Numeric 'Sum(QTD_INTERNACAO)'
    $gotLT=Numeric 'Sum(QTD_LEITOS_SUS)'
    $gotRatio=Numeric 'Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS)'
    $wantRatio=[decimal]$wantRD/[decimal]$wantLT
    $delta=[Math]::Abs([decimal]($gotRatio-$wantRatio))
    $passPartial=($gotRD -eq $wantRD -and $gotLT -eq $wantLT -and $delta -le [decimal]0.000001)
    $partial=[pscustomobject]@{
      Case='T26_JP_201801_PARTIAL';Window='MONTH_201801_NOT_ANNUAL'
      F1Eligible=$wantRD;QlikEligible=$gotRD
      F2ObservedSUS=$wantLT;QlikObservedSUS=$gotLT
      OracleRatio=$wantRatio;QlikRatio=$gotRatio;AbsoluteError=$delta
      Status=$(if($passPartial){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})
    }
    $partial | Export-Csv -LiteralPath (Join-Path $work 't26_partial_jp.csv') -NoTypeInformation -Encoding UTF8
    Write-Output ('T26_PARTIAL_CASE=JP_201801 RESULT='+$partial.Status+
      ' RD_F1='+$wantRD+' RD_QLIK='+$gotRD+' LT_F2='+$wantLT+' LT_QLIK='+$gotLT)
    if(-not $passPartial){throw 'BLOCKED: T26 partial Jan2018 cross-fact mismatch'}
    $pass=$true
    Write-Output 'T26_ANNUAL_2_CASES=PASS_CANDIDATE_PENDING_SHA'
    Write-Output 'T26_PARTIAL_1_CASE=PASS_CANDIDATE_PENDING_SHA'
  }
}catch{
  Write-Output ('VERDICT=BLOCKED_OR_INCONCLUSIVE '+$_.Exception.Message)
  throw
}finally{
  if($null -ne $script:doc){try{$null=$script:doc.CloseDoc()}catch{}}
  if($null -ne $oldQvd){
    $now=@(Snapshot 'QVD')
    $now|Export-Csv -LiteralPath (Join-Path $work 'qvd_after.csv') -NoTypeInformation -Encoding UTF8
    if(-not(Same $oldQvd $now)){throw 'CRITICAL: 22 QVD SHA changes'}
    Write-Output 'ORIGINAL_22_QVD_SHA256_UNCHANGED=True'
  }
  if($null -ne $oldQvw){
    $now=@(Snapshot 'QVW')
    $now|Export-Csv -LiteralPath (Join-Path $work 'canonical_qvw_after.csv') -NoTypeInformation -Encoding UTF8
    if(-not(Same $oldQvw $now)){throw 'CRITICAL: canonical QVW SHA changes'}
    Write-Output 'ORIGINAL_CANONICAL_QVWS_UNCHANGED=True'
  }
  if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -cne $sourceHash){
    throw 'CRITICAL: source T24 QVW SHA changed'
  }
  Write-Output 'SOURCE_T24_QVW_SHA256_UNCHANGED=True'
}
if($RunQlik -and $pass){
  Write-Output 'VERDICT=PASS_LOCAL_T26_OBSERVED_LT_2_ANNUAL_1_PARTIAL_CANDIDATE_ONLY'
  Write-Output 'T26_HOSPITAL_SCOPE=NOT_VERIFIED T26_GENERAL=NOT_APPROVED P5_D2_UI=NOT_TESTED PRODUCTION_APPROVED=False'
}
