# VIII-B: T24 edge cases: annual two-municipality ratio and unavailable KPI guards.
# Input: previously PASSed TEMP T24 QVW. Only a new TEMP copy is opened.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$SourceQvw,
  [Parameter(Mandatory=$true)][string]$F3Dir,
  [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$branch='test/phase-viii-t24-edge-cases-20261018'
$selfRel='tools/Invoke-SadPhaseViiiT24EdgeCases.ps1'
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
$work=Join-Path $tmp ('SAD_VIII_T24_EDGE_'+[Guid]::NewGuid().ToString('N'))
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
$regionExpected=$null
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
  $componentsPath=Oracle $F3Dir 'F3_componentes_residencia_ano.csv' 'manifest_F3.json'
  $scenariosPath=Oracle $F3Dir 'F3_cenarios_multimunicipais.csv' 'manifest_F3.json'
  $externalPath=Oracle $F3Dir 'F3_residentes_externos_ano.csv' 'manifest_F3.json'
  $annual=@(Import-Csv -LiteralPath $componentsPath -Delimiter ';' -Encoding UTF8)
  $scenarios=@(Import-Csv -LiteralPath $scenariosPath -Delimiter ';' -Encoding UTF8)
  $external=@(Import-Csv -LiteralPath $externalPath -Delimiter ';' -Encoding UTF8)
  if($annual.Count -ne 669 -or $scenarios.Count -ne 12 -or $external.Count -lt 1){
    throw 'BLOCKED: unexpected F3 reference cardinalities'
  }
  $region=@($scenarios | Where-Object {
    $_.ano -ceq '2018' -and $_.papel -ceq 'RES' -and $_.selecao -ceq 'JP_CG_2'
  })
  if($region.Count -ne 1 -or $region[0].codigos_municipios -cne '250400,250750' -or
     $region[0].municipios_distintos -cne '2'){throw 'BLOCKED: F3 region context absent'}
  $members=@($annual | Where-Object {
    $_.ano -ceq '2018' -and $_.municipio_residencia -in @('250400','250750')
  })
  if($members.Count -ne 2){throw 'BLOCKED: F3 region members missing'}
  [long]$wantN=0
  [long]$wantPop=0
  foreach($item in $members){
    $wantN += [long]$item.internacoes_elegiveis
    $wantPop += [long]$item.denominador_populacao
  }
  if($wantN -ne 61616 -or $wantPop -ne 1207795 -or
     [long]$region[0].numerador_internacoes_elegiveis -ne $wantN -or
     [long]$region[0].denominador_pop_somado_uma_vez -ne $wantPop){
    throw 'BLOCKED: independent F3 regional reference differs from frozen expectation'
  }
  [long]$extN=0
  foreach($item in $external){
    if(-not [string]::IsNullOrEmpty([string]$item.denominador_populacao) -or
       $item.estado -cne 'FORA_DA_REFERENCIA_PB_INDISPONIVEL' -or
       [string]$item.ano -notin @('2017','2018','2019')){
      throw 'BLOCKED: F3 external no-POP semantics changed'
    }
    $extN += [long]$item.internacoes_elegiveis
  }
  if($extN -ne 5067){throw 'BLOCKED: F3 external eligible total changed'}
  Write-Output ('REFERENCE_F3_REGION_2018=PASS N='+$wantN+' POP='+$wantPop)
  Write-Output ('REFERENCE_F3_EXTERNAL_NO_PB_POP=PASS ELIGIBLE='+$extN)
  if(-not $RunQlik){
    Write-Output 'VERDICT=PASS_REFERENCE_READONLY_ONLY_COM_NOT_RUN'
  }else{
    if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'BLOCKED: native Windows required'}
    $copy=Join-Path $work 'T24_MONTHLY_DISPOSABLE.qvw'
    Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
    if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash){throw 'BLOCKED: QVW TEMP copy SHA drift'}
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $script:doc=$qv.OpenDoc($copy,'','')
    if($null -eq $script:doc){throw 'BLOCKED: QlikView COM OpenDoc returned null'}
    if(-not ([string]($script:doc.GetProperties().Script)).Contains('[VIII-B-T24] VERDICT=PASS_RELOAD_STRUCTURE_ONLY_NOT_T24')){
      throw 'BLOCKED: QVW script not from the phase VIII-B T24 pilot'
    }
    # D6: one year, two residence municipalities; aggregate N and POP before division.
    $null=$script:doc.ClearAll()
    SelectOne 'PERIODO_ANO' '2018'
    SelectOne 'RES_COD_DATASUS_6' '250750'
    $null=$script:doc.GetField('RES_COD_DATASUS_6').ToggleSelect('250400')
    if((CountSelected 'RES_COD_DATASUS_6') -ne 2 -or
       (CountSelected 'PERIODO_ANO') -ne 1 -or
       (CountSelected 'PERIODO_COMPETENCIA') -ne 0){
      throw 'BLOCKED: regional selection year and municipality state not preserved'
    }
    $actualN=Numeric 'Sum(QTD_INTERNACAO)'
    $actualPop=Numeric 'Sum(POPULACAO_ESTIMADA)'
    $actualRate=Numeric '1000*Sum(QTD_INTERNACAO)/Sum(POPULACAO_ESTIMADA)'
    $wantRate=[decimal]1000*[decimal]$wantN/[decimal]$wantPop
    $delta=[Math]::Abs([decimal]($actualRate-$wantRate))
    $ok=($actualN -eq $wantN -and $actualPop -eq $wantPop -and $delta -le [decimal]0.000001)
    $casesOut += [pscustomobject]@{
      Case='JP_CG_RES_2018';Year=2018;Role='RES'
      OracleAdmissions=$wantN;QlikAdmissions=$actualN
      OracleAnnualPopulation=$wantPop;QlikAnnualPopulation=$actualPop
      OracleRate=$wantRate;QlikRate=$actualRate;AbsoluteError=$delta
      Status=$(if($ok){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})
    }
    $casesOut | Export-Csv -LiteralPath (Join-Path $work 't24_edge_region.csv') -Encoding UTF8 -NoTypeInformation
    Write-Output ('T24_REGION_CASE=JP_CG_RES_2018 RESULT='+$casesOut[-1].Status+
                  ' ORACLE_N='+$wantN+' QLIK_N='+$actualN+
                  ' ORACLE_POP='+$wantPop+' QLIK_POP='+$actualPop)
    if(-not $ok){throw 'BLOCKED: F3 regional aggregate and Qlik do not reconcile'}

    # A KPI with no chosen year is unavailable; avoid evaluating a misleading global ratio.
    $null=$script:doc.ClearAll()
    if((CountSelected 'PERIODO_ANO') -ne 0 -or
       (CountSelected 'PERIODO_COMPETENCIA') -ne 0){
      throw 'BLOCKED: no-period scenario not clean'
    }
    $guardsOut += [pscustomobject]@{
      Case='NO_PERIOD_POINT_KPI';Status='UNAVAILABLE_NO_REFERENCE_PERIOD';KpiEvaluated=$false
    }
    Write-Output 'T24_GUARD=NO_PERIOD_POINT_KPI RESULT=UNAVAILABLE_NO_REFERENCE_PERIOD KPI_EVALUATED=False'

    # A point KPI cannot combine 2018 and 2019 population. Preserve both selections.
    SelectOne 'PERIODO_ANO' '2018'
    $null=$script:doc.GetField('PERIODO_ANO').ToggleSelect('2019')
    if((CountSelected 'PERIODO_ANO') -ne 2 -or
       (CountSelected 'PERIODO_COMPETENCIA') -ne 0){
      throw 'BLOCKED: two-year selection not preserved'
    }
    $guardsOut += [pscustomobject]@{
      Case='MULTI_YEAR_POINT_KPI';Status='UNAVAILABLE_MULTI_YEAR';KpiEvaluated=$false
    }
    Write-Output 'T24_GUARD=MULTI_YEAR_POINT_KPI RESULT=UNAVAILABLE_MULTI_YEAR KPI_EVALUATED=False'

    # F3 external-resident oracle demonstrates that outside-PB numerator has no PB denominator.
    # This is a semantic/reference guard only, NOT a COM external-municipality selection.
    $guardsOut += [pscustomobject]@{
      Case='EXTERNAL_RESIDENT_F3';Status='UNAVAILABLE_POP_EXTERNAL_PB';KpiEvaluated=$false
    }
    Write-Output ('T24_GUARD=EXTERNAL_RESIDENT_F3 RESULT=UNAVAILABLE_POP_EXTERNAL_PB ELIGIBLE='+$extN+' KPI_EVALUATED=False')
    $guardsOut | Export-Csv -LiteralPath (Join-Path $work 't24_edge_guards.csv') -Encoding UTF8 -NoTypeInformation
    $pass=$true
    Write-Output 'T24_REGION_1_CASE=PASS_NUMERIC_CANDIDATE_PENDING_SHA'
    Write-Output 'T24_EDGE_UNAVAILABLE_3_CASES=PASS_RESTRICTED_GUARDS_PENDING_SHA'
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
  Write-Output 'VERDICT=PASS_LOCAL_T24_EDGE_REGION_1_AND_UNAVAILABLE_3_CANDIDATE_ONLY'
  Write-Output 'EXTERNAL_COM=NOT_TESTED P5_D2_UI=NOT_TESTED T24_GENERAL=NOT_APPROVED T25_T26=NOT_TESTED PRODUCTION_APPROVED=False'
}
