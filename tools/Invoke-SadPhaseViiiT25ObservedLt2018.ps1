# VIII-B: T25 LT observed 2018 pilot. Mean of twelve monthly LT snapshots / annual service POP.
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
$branch='test/phase-viii-b-t25-observed-lt-2018-20261018'
$selfRel='tools/Invoke-SadPhaseViiiT25ObservedLt2018.ps1'
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
$work=Join-Path $tmp ('SAD_VIII_T25_OBS_'+[Guid]::NewGuid().ToString('N'))
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
$monthlyResults=@()
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
  $f2Month=Oracle $F1F2Dir 'F2_lt_municipio_competencia_observado.csv' 'manifest_F1_F2.json'
  $f2Year=Oracle $F1F2Dir 'F2_lt_municipio_ano_cobertura_candidata.csv' 'manifest_F1_F2.json'
  $f3Service=Oracle $F3Dir 'F3_componentes_servico_ano.csv' 'manifest_F3.json'
  $observed=@(Import-Csv -LiteralPath $f2Month -Delimiter ';' -Encoding UTF8)
  $coverage=@(Import-Csv -LiteralPath $f2Year -Delimiter ';' -Encoding UTF8)
  $population=@(Import-Csv -LiteralPath $f3Service -Delimiter ';' -Encoding UTF8)
  if($observed.Count -lt 24 -or $coverage.Count -ne 669 -or $population.Count -ne 669){
    throw 'BLOCKED: unexpected F2/F3 reference coverage'
  }
  $pilot=@()
  foreach($mun in @('250750','250400')){
    $cells=@($observed | Where-Object {
      $_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun
    })
    $annual=@($coverage | Where-Object {
      $_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun
    })
    $pop=@($population | Where-Object {
      $_.ano -ceq '2018' -and $_.municipio_servico -ceq $mun
    })
    if($cells.Count -ne 12 -or $annual.Count -ne 1 -or $pop.Count -ne 1){
      throw ('BLOCKED: not twelve observed months and 1 annual POP for '+$mun)
    }
    if($annual[0].meses_observados -cne '12' -or
       $annual[0].meses_esperados -cne '12' -or
       $annual[0].competencias_sem_linhas_lt -cne '' -or
       $annual[0].cobertura_presenca_linhas -cne '12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED' -or
       $annual[0].universo -cne 'LT_TODOS_REGISTROS_VALIDOS_RN21' -or
       $annual[0].hospitalar_historico_validado -cne 'NAO' -or
       $pop[0].estado_capacidade -cne '12_MESES_LINHAS_ESCOPO_NAO_VERIFICADO' -or
       $pop[0].meses_lt_com_linhas -cne '12' -or
       $pop[0].media_qt_sus_divisor_candidato -cne '12'){
      throw ('BLOCKED: F2/F3 coverage policy not observed/appropriately caveated '+$mun)
    }
    [long]$total=0
    [long]$popAnnual=[long]$pop[0].denominador_populacao
    if($popAnnual -le 0){throw ('BLOCKED: invalid F3 annual service POP '+$mun)}
    $byComp=@{}
    foreach($row in $cells){
      $period=[string]$row.competencia
      if($period -notmatch '^2018(0[1-9]|1[0-2])$' -or $byComp.ContainsKey($period) -or
         $row.estado -cne 'LINHAS_OBSERVADAS_NUMEROS_RECONCILIADOS' -or
         $row.universo -cne 'LT_TODOS_REGISTROS_VALIDOS_RN21' -or
         [long]$row.linhas_lt -le 0 -or [long]$row.qt_sus -lt 0){
         throw ('BLOCKED: invalid/duplicate F2 monthly observation '+$mun+'/'+$period)
      }
      $value=[long]$row.qt_sus
      $byComp[$period]=$value
      $total += $value
    }
    for($i=1;$i -le 12;$i++){
      $month=('2018'+'{0:D2}' -f $i)
      if(-not $byComp.ContainsKey($month)){throw ('BLOCKED: missing monthly LT observation '+$mun+'/'+$month)}
    }
    if($total -le 0 -or
       [long]$annual[0].qt_sus_soma_snapshots_auditoria -ne $total -or
       [long]$annual[0].media_sus_numerador_exato -ne $total -or
       $annual[0].media_sus_divisor_exato -cne '12' -or
       [long]$pop[0].soma_qt_sus_snapshots_auditoria -ne $total -or
       [long]$pop[0].media_qt_sus_numerador_candidato -ne $total){
      throw ('BLOCKED: independent annual F2/F3 snapshot sum mismatch '+$mun)
    }
    $pilot += [pscustomobject]@{
      Municipality=$mun;AnnualPOP=$popAnnual;MonthTotal=$byComp;AnnualSnapshotSum=$total
    }
    Write-Output ('F2_F3_OBSERVED_2018='+$mun+' MONTHS=12 POP='+$popAnnual+' LT_SUM_AUDIT='+$total+
       ' HOSPITAL_SCOPE=NOT_VERIFIED')
  }
  if(-not $RunQlik){
    Write-Output 'VERDICT=PASS_REFERENCE_READONLY_ONLY_COM_NOT_RUN'
  }else{
    if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'BLOCKED: native Windows required'}
    $copy=Join-Path $work 'T25_OBSERVED_DISPOSABLE.qvw'
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
      if((CountSelected 'PERIODO_COMPETENCIA') -ne 0){
        throw ('BLOCKED: no-month annual selection expected '+$mun)
      }
      $yearSum=Numeric 'Sum(QTD_LEITOS_SUS)'
      $yearPop=Numeric 'Sum(POPULACAO_ESTIMADA)'
      $yearRate=Numeric '1000*Sum(QTD_LEITOS_SUS)/12/Sum(POPULACAO_ESTIMADA)'
      $expectedRate=[decimal]1000*[decimal]$c.AnnualSnapshotSum/[decimal]12/[decimal]$c.AnnualPOP
      $rateError=[Math]::Abs([decimal]($yearRate-$expectedRate))
      if($yearSum -ne $c.AnnualSnapshotSum -or
         $yearPop -ne $c.AnnualPOP -or $rateError -gt [decimal]0.000001){
        $casesOut += [pscustomobject]@{Municipality=$mun;Case='ANNUAL_T25_OBSERVED';
          F2SnapshotSum=$c.AnnualSnapshotSum;QlikSnapshotSum=$yearSum;
          F3AnnualPop=$c.AnnualPOP;QlikAnnualPop=$yearPop;
          F2F3Rate=$expectedRate;QlikRate=$yearRate;Error=$rateError;Status='BLOCKED_MISMATCH'}
        $casesOut|Export-Csv -LiteralPath (Join-Path $work 't25_annual.csv') -Encoding UTF8 -NoTypeInformation
        throw ('BLOCKED: T25 annual components differ '+$mun)
      }
      $casesOut += [pscustomobject]@{Municipality=$mun;Case='ANNUAL_T25_OBSERVED';
        F2SnapshotSum=$c.AnnualSnapshotSum;QlikSnapshotSum=$yearSum;
        F3AnnualPop=$c.AnnualPOP;QlikAnnualPop=$yearPop;
        F2F3Rate=$expectedRate;QlikRate=$yearRate;Error=$rateError;Status='PASS_CANDIDATE'}
      $casesOut|Export-Csv -LiteralPath (Join-Path $work 't25_annual.csv') -Encoding UTF8 -NoTypeInformation
      Write-Output ('T25_ANNUAL_CASE='+$mun+' RESULT=PASS_CANDIDATE SUM_12_F2='+$c.AnnualSnapshotSum+
        ' SUM_12_QLIK='+$yearSum+' POP_F3='+$c.AnnualPOP+
        ' POP_QLIK='+$yearPop+' AVG_DIVISOR=12 UNIVERSE=LT_OBSERVED_ONLY')
      [long]$checkedSum=0
      for($i=1;$i -le 12;$i++){
        $period=('2018'+'{0:D2}' -f $i)
        # Restore year and service for each month, preventing state carry-over.
        $null=$script:doc.ClearAll()
        SelectOne 'PERIODO_ANO' '2018'
        SelectOne 'SERV_COD_DATASUS_6' $mun
        SelectOne 'PERIODO_COMPETENCIA' $period
        if((CountSelected 'PERIODO_ANO') -ne 1 -or
           (CountSelected 'SERV_COD_DATASUS_6') -ne 1 -or
           (CountSelected 'PERIODO_COMPETENCIA') -ne 1){
          throw ('BLOCKED: monthly selection lost '+mun+'/'+$period)
        }
        $actual=Numeric 'Sum(QTD_LEITOS_SUS)'
        $expected=[decimal]$c.MonthTotal[$period]
        $monthlyResults += [pscustomobject]@{
          Municipality=$mun;Month=$period;F2SUS=$expected;QlikSUS=$actual;
          Status=$(if($expected -eq $actual){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})
        }
        $monthlyResults | Export-Csv -LiteralPath (Join-Path $work 't25_monthly_components.csv') -Encoding UTF8 -NoTypeInformation
        if($expected -ne $actual){
          Write-Output ('T25_MONTH='+mun+'/'+$period+' RESULT=BLOCKED_MISMATCH F2='+$expected+' QLIK='+$actual)
          throw ('BLOCKED: monthly LT component mismatch '+mun+'/'+$period)
        }
        $checkedSum += [long]$actual
      }
      if($checkedSum -ne $c.AnnualSnapshotSum){throw ('BLOCKED: 12 Qlik snapshots differ from annual sum '+$mun)}
      Write-Output ('T25_MONTHLY_RECONCILED='+$mun+' MONTHS=12_OF_12 MONTH_SUM_AUDIT='+$checkedSum)
    }
    # A single month is a partial-window ratio, not an annual or 12-month mean.
    $j=@($pilot|Where-Object {$_.Municipality -ceq '250750'})
    if($j.Count -ne 1){throw 'BLOCKED: missing JP for partial month'}
    $null=$script:doc.ClearAll()
    SelectOne 'PERIODO_ANO' '2018'
    SelectOne 'SERV_COD_DATASUS_6' '250750'
    SelectOne 'PERIODO_COMPETENCIA' '201801'
    $partialSUS=Numeric 'Sum(QTD_LEITOS_SUS)'
    $partialPop=Numeric 'Sum({$<PERIODO_COMPETENCIA=>} POPULACAO_ESTIMADA)'
    $partialRate=Numeric '1000*Sum(QTD_LEITOS_SUS)/Sum({$<PERIODO_COMPETENCIA=>} POPULACAO_ESTIMADA)'
    $partialExpected=[decimal]1000*[decimal]$j[0].MonthTotal['201801']/[decimal]$j[0].AnnualPOP
    $partialError=[Math]::Abs([decimal]($partialRate-$partialExpected))
    $partialPass=($partialSUS -eq $j[0].MonthTotal['201801'] -and
      $partialPop -eq $j[0].AnnualPOP -and $partialError -le [decimal]0.000001)
    $partialResult=[pscustomobject]@{Case='JP_201801_PARTIAL_T25';Period='201801';
      F2SUS=$j[0].MonthTotal['201801'];QlikSUS=$partialSUS;
      F3AnnualPop=$j[0].AnnualPOP;QlikAnnualPop=$partialPop;
      F2F3PartialRate=$partialExpected;QlikPartialRate=$partialRate;Error=$partialError;
      Label='PARTIAL_SINGLE_MONTH_NOT_ANNUAL';Status=$(if($partialPass){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})}
    $partialResult|Export-Csv -LiteralPath (Join-Path $work 't25_partial_jp.csv') -Encoding UTF8 -NoTypeInformation
    Write-Output ('T25_PARTIAL_CASE=JP_201801 RESULT='+$partialResult.Status+
       ' F2_SUS='+$partialResult.F2SUS+' QLIK_SUS='+$partialSUS+
       ' POP_F3='+$partialResult.F3AnnualPop+' POP_QLIK='+$partialPop)
    if(-not $partialPass){throw 'BLOCKED: T25 partial-month discrepancy'}
    $pass=$true
    Write-Output 'T25_ANNUAL_2_CASES=PASS_CANDIDATE_PENDING_SHA'
    Write-Output 'T25_MONTHLY_24_COMPONENTS=PASS_CANDIDATE_PENDING_SHA'
    Write-Output 'T25_PARTIAL_1_CASE=PASS_CANDIDATE_PENDING_SHA'
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
  Write-Output 'VERDICT=PASS_LOCAL_T25_OBSERVED_LT_2_ANNUAL_24_MONTHS_1_PARTIAL_CANDIDATE_ONLY'
  Write-Output 'T25_HOSPITAL_SCOPE=NOT_VERIFIED P5_D2_UI=NOT_TESTED T25_GENERAL=NOT_APPROVED T26=NOT_TESTED PRODUCTION_APPROVED=False'
}
