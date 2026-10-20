# VIII-B: T26 candidate. Annual eligible service RD admissions / mean LT SUS observed 12 snapshots.
# Input: previously PASSed TEMP T24 QVW. Only a new TEMP copy is opened.
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
$branch='test/phase-viii-c3b1-asymmetric-roles-20261019'
$selfRel='tools/Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1'
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
$work=Join-Path $tmp ('SAD_VIII_C3B1_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('VERSIONED_GIT_HEAD='+$h[0])
Write-Output ('SCRIPT_SHA256='+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('SOURCE_QVW_SHA256='+$sourceHash)
Write-Output 'MODE=C3B1_TEMP_COPY_NO_RELOAD QVD_WRITES=0 CANONICAL_QVW_WRITES=0'
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

# A single previously generated, SHA-verified independent F1 annual asymmetric flow.
# Never turn zero reachable LT/POP fact rows into zero capacity/population.
$oldQvd=$null
$oldQvw=$null
$script:doc=$null
$passed=$false
try{
  $oldQvd=@(Snapshot 'QVD')
  $oldQvw=@(Snapshot 'QVW')
  $oldQvd|Export-Csv -LiteralPath (Join-Path $work 'qvd_before.csv') -NoTypeInformation -Encoding UTF8
  $oldQvw|Export-Csv -LiteralPath (Join-Path $work 'canonical_qvw_before.csv') -NoTypeInformation -Encoding UTF8
  $link=Join-Path $repo 'TRANSFORMACAO/QVD/LINK_ANALISE.qvd'
  $matched=@($oldQvd|Where-Object {$_.Path -ieq $link})
  if($matched.Count -ne 1 -or $matched[0].SHA256 -cne '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB'){
    throw 'BLOCKED: LINK_ANALISE baseline hash drift'
  }
  $oracle=Oracle $F1F2Dir 'F1_fluxo_ano.csv' 'manifest_F1_F2.json'
  $rows=@(Import-Csv -LiteralPath $oracle -Delimiter ';' -Encoding UTF8)
  if($rows.Count -eq 0){throw 'BLOCKED: empty F1 annual flow oracle'}
  foreach($field in @('ano','municipio_residencia','municipio_servico','registros_rd','internacoes_elegiveis','continuidades_ident5')){
    if($rows[0].PSObject.Properties.Name -cnotcontains $field){throw ('BLOCKED: missing F1 column '+$field)}
  }
  # Deterministic maximum-eligible 2018 PB->PB flow with R != S.
  $candidates=@($rows|Where-Object {
    $_.ano -ceq '2018' -and
    $_.municipio_residencia -match '^25[0-9]{4}$' -and
    $_.municipio_servico -match '^25[0-9]{4}$' -and
    $_.municipio_residencia -cne $_.municipio_servico -and
    $_.internacoes_elegiveis -match '^[1-9][0-9]*$' -and
    $_.registros_rd -match '^[1-9][0-9]*$' -and
    $_.continuidades_ident5 -match '^[0-9]+$'
  })
  if($candidates.Count -eq 0){throw 'BLOCKED_MISSING_INDEPENDENT_ROLE_ORACLE: no eligible 2018 PB pair R != S'}
  $ordered=@($candidates|Sort-Object -Property @{Expression={[long]$_.internacoes_elegiveis};Descending=$true},@{Expression={$_.municipio_residencia};Descending=$false},@{Expression={$_.municipio_servico};Descending=$false})
  $chosen=$ordered[0]
  [long]$expectedRecords=[long]::Parse([string]$chosen.registros_rd)
  [long]$expectedEligible=[long]::Parse([string]$chosen.internacoes_elegiveis)
  [long]$expectedIdent5=[long]::Parse([string]$chosen.continuidades_ident5)
  if($expectedRecords -ne ($expectedEligible+$expectedIdent5) -or $expectedEligible -le 0){
    throw 'BLOCKED: F1 group totals violate expected IDENT 1/5 decomposition'
  }
  $year=[string]$chosen.ano
  $res=[string]$chosen.municipio_residencia
  $serv=[string]$chosen.municipio_servico
  [pscustomobject]@{
    Case='C3_B1_R_NE_S';Year=$year;Residence=$res;Service=$serv
    F1RD=$expectedRecords;F1Eligible=$expectedEligible;F1Ident5=$expectedIdent5
    Universe='SIH_RD_PROCESSED_PB';Oracle='F1_fluxo_ano.csv'
  }|Export-Csv -LiteralPath (Join-Path $work 'c3b1_oracle_pair.csv') -NoTypeInformation -Encoding UTF8
  Write-Output ('C3B1_ORACLE_PAIR=YEAR_'+$year+'_R_'+$res+'_S_'+$serv+
    ' F1_RD='+$expectedRecords+' F1_ELIGIBLE='+$expectedEligible+' F1_IDENT5='+$expectedIdent5)
  if(-not $RunQlik){
    Write-Output 'VERDICT=PASS_REFERENCE_PRECHECK_ONLY_C3B1_QV_NOT_RUN'
  }else{
    if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'BLOCKED: Windows/QlikView 12 required'}
    $copy=Join-Path $work 'SAD_C3B1_ASYMMETRIC_ROLES_TEST.qvw'
    Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
    if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash){throw 'BLOCKED: copied QVW differs'}
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $script:doc=$qv.OpenDoc($copy,'','')
    if($null -eq $script:doc){throw 'BLOCKED: QlikView COM OpenDoc returned null'}
    if(-not ([string]($script:doc.GetProperties().Script)).Contains('[VIII-B-T24] VERDICT=PASS_RELOAD_STRUCTURE_ONLY_NOT_T24')){
      throw 'BLOCKED: QVW has unexpected source model'
    }
    $null=$script:doc.ClearAll()
    foreach($f in @('PERIODO_ANO','PERIODO_COMPETENCIA','RES_COD_DATASUS_6','SERV_COD_DATASUS_6')){
      if((CountSelected $f) -ne 0){throw ('BLOCKED: ClearAll failed '+$f)}
    }
    SelectOne 'PERIODO_ANO' $year
    SelectOne 'RES_COD_DATASUS_6' $res
    SelectOne 'SERV_COD_DATASUS_6' $serv
    if((CountSelected 'PERIODO_ANO') -ne 1 -or
       (CountSelected 'RES_COD_DATASUS_6') -ne 1 -or
       (CountSelected 'SERV_COD_DATASUS_6') -ne 1 -or
       (CountSelected 'PERIODO_COMPETENCIA') -ne 0){
      throw 'BLOCKED: role/temporal selection count wrong'
    }
    $readYear=[string]$script:doc.Evaluate('GetFieldSelections(PERIODO_ANO)')
    $readRes=[string]$script:doc.Evaluate('GetFieldSelections(RES_COD_DATASUS_6)')
    $readServ=[string]$script:doc.Evaluate('GetFieldSelections(SERV_COD_DATASUS_6)')
    if($readYear.Trim() -cne $year -or $readRes.Trim() -cne $res -or $readServ.Trim() -cne $serv){
      throw ('BLOCKED: COM selection values mismatch '+$readYear+' '+$readRes+' '+$readServ)
    }
    $actualRD=Numeric 'Sum(QTD_REGISTRO_AIH)'
    $actualEligible=Numeric 'Sum(QTD_INTERNACAO)'
    $actualIdent5=$actualRD-$actualEligible
    $reachablePOP=Numeric 'Count(POPULACAO_ESTIMADA)'
    $reachableLT=Numeric 'Count(QTD_LEITOS_SUS)'
    $ok=($actualRD -eq $expectedRecords -and $actualEligible -eq $expectedEligible -and
         $actualIdent5 -eq $expectedIdent5 -and $reachablePOP -eq 0 -and $reachableLT -eq 0)
    $result=[pscustomobject]@{
      Case='C3_B1_R_NE_S';Year=$year;Residence=$res;Service=$serv
      F1RD=$expectedRecords;QlikRD=$actualRD
      F1Eligible=$expectedEligible;QlikEligible=$actualEligible
      F1Ident5=$expectedIdent5;QlikIdent5=$actualIdent5
      ReachablePOPRows=$reachablePOP;ReachableLTRows=$reachableLT
      NoPOPMeans='NOT_APPLICABLE';NoLTMeans='NOT_APPLICABLE'
      Status=$(if($ok){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})
    }
    $result|Export-Csv -LiteralPath (Join-Path $work 'c3b1_reconciliation.csv') -NoTypeInformation -Encoding UTF8
    Write-Output ('C3B1_RESULT='+$result.Status+' QLIK_RD='+$actualRD+' QLIK_ELIGIBLE='+$actualEligible+
      ' QLIK_IDENT5='+$actualIdent5+' REACHABLE_POP_ROWS='+$reachablePOP+' REACHABLE_LT_ROWS='+$reachableLT)
    if(-not $ok){throw 'BLOCKED: F1/Qlik mismatch or spurious POP/LT association'}
    $passed=$true
    Write-Output 'C3B1_FLOW=PASS_CANDIDATE_PENDING_FINAL_HASHES'
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
  if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -cne $sourceHash){throw 'CRITICAL: source QVW SHA changed'}
  Write-Output 'SOURCE_T24_QVW_SHA256_UNCHANGED=True'
}
if($RunQlik -and $passed){
  Write-Output 'VERDICT=PASS_LOCAL_C3B1_ASYMMETRIC_ROLE_FLOW_CANDIDATE_ONLY'
  Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED P5_D2_UI=NOT_TESTED PHASE_IX=NOT_AUTHORIZED PRODUCTION_APPROVED=False'
}
