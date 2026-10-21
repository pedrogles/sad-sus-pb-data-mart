# VIII-B: partial-month T24 + narrow D2/P5 pre-dispatch checks.
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
$branch='test/phase-viii-t24-monthly-predispatch-20261018'
$selfRel='tools/Invoke-SadPhaseViiiT24MonthlyPredispatch.ps1'
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
$work=Join-Path $tmp ('SAD_VIII_T24_MONTHLY_'+[Guid]::NewGuid().ToString('N'))
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
  $f1=Oracle $F1F2Dir 'F1_residencia_competencia.csv' 'manifest_F1_F2.json'
  $f3=Oracle $F3Dir 'F3_componentes_residencia_ano.csv' 'manifest_F3.json'
  $monthly=@(Import-Csv -LiteralPath $f1 -Delimiter ';' -Encoding UTF8)
  $annual=@(Import-Csv -LiteralPath $f3 -Delimiter ';' -Encoding UTF8)
  $jp=@($annual|Where-Object {$_.ano -ceq '2018' -and $_.municipio_residencia -ceq '250750'})
  $pb=@($annual|Where-Object {$_.ano -ceq '2018'})
  if($jp.Count -ne 1 -or $pb.Count -ne 223 -or [long]$jp[0].denominador_populacao -ne 800323){
    throw 'BLOCKED: F3 population reference not as expected'
  }
  [long]$pbPop=0
  $pbCodes=@{}
  foreach($r in $pb){
    $pbPop += [long]$r.denominador_populacao
    $pbCodes[[string]$r.municipio_residencia]=$true
  }
  if($pbPop -ne 3996496 -or $monthly.Count -eq 0){throw 'BLOCKED: F1/F3 reference coverage changed'}
  Write-Output 'REFERENCES_F1_F3=PASS_HASH_AND_ANNUAL_POP'
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
    $setPop='Sum({$<PERIODO_COMPETENCIA=>} POPULACAO_ESTIMADA)'
    # The dynamic expression below is assembled without changing the selected monthly window.
    $rate='1000*Sum(QTD_INTERNACAO)/('+$setPop+')'
    foreach($c in @(
      @{Name='JP_201801';Mun='250750';Months=@('201801')},
      @{Name='JP_201801_201803';Mun='250750';Months=@('201801','201803')},
      @{Name='PB_201801';Mun='PB';Months=@('201801')}
    )){
      $null=$script:doc.ClearAll()
      SelectOne 'PERIODO_ANO' '2018'
      if($c.Mun -ceq 'PB'){SelectOne 'RES_UF' 'PB'}
      else{SelectOne 'RES_COD_DATASUS_6' $c.Mun}
      SelectOne 'PERIODO_COMPETENCIA' $c.Months[0]
      if($c.Months.Count -eq 2){$null=$script:doc.GetField('PERIODO_COMPETENCIA').ToggleSelect($c.Months[1])}
      if((CountSelected 'PERIODO_COMPETENCIA') -ne $c.Months.Count -or (CountSelected 'PERIODO_ANO') -ne 1){
        throw ('BLOCKED: month/year selections not preserved '+$c.Name)
      }
      [long]$wantN=0
      foreach($r in $monthly){
        if($r.ano -ceq '2018' -and $c.Months -ccontains [string]$r.competencia -and
           (($c.Mun -ceq 'PB' -and $pbCodes.ContainsKey([string]$r.municipio_residencia)) -or
            ($c.Mun -cne 'PB' -and $r.municipio_residencia -ceq $c.Mun))){
          $wantN += [long]$r.internacoes_elegiveis
        }
      }
      [long]$wantPop=if($c.Mun -ceq 'PB'){$pbPop}else{[long]($jp[0].denominador_populacao)}
      if($wantN -le 0){throw ('BLOCKED: no F1 monthly admissions for '+$c.Name)}
      $observedN=Numeric 'Sum(QTD_INTERNACAO)'
      $observedPop=Numeric $setPop
      $observedRate=Numeric $rate
      $expectRate=[decimal]1000*[decimal]$wantN/[decimal]$wantPop
      $delta=[Math]::Abs([decimal]($observedRate-$expectRate))
      $ok=($observedN -eq $wantN -and $observedPop -eq $wantPop -and $delta -le [decimal]0.000001)
      $casesOut += [pscustomobject]@{
        Case=$c.Name;Months=($c.Months -join ',');Window=$(if($c.Months.Count -eq 2){'DISCONTIGUOUS_PARTIAL_ANNUAL_POP'}else{'PARTIAL_NOT_ANNUALIZED_POP_ANNUAL'})
        F1Admissions=$wantN;QlikAdmissions=$observedN;F3AnnualPop=$wantPop;QlikAnnualPop=$observedPop
        F1F3Rate=$expectRate;QlikRate=$observedRate;AbsoluteError=$delta
        Status=$(if($ok){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})
      }
      $casesOut|Export-Csv -LiteralPath (Join-Path $work 't24_monthly.csv') -NoTypeInformation -Encoding UTF8
      Write-Output ('T24_MONTH_CASE='+$c.Name+' RESULT='+$casesOut[-1].Status+' F1='+$wantN+' QLIK='+$observedN+' POP='+$observedPop)
      if(-not $ok){throw ('BLOCKED: T24 monthly F1/F3 reconciliation '+$c.Name)}
    }
    foreach($spec in @(
      @{Name='D2_YEAR_TO_OLD_MONTH';Prior='PERIODO_ANO';Value='2019';Type='MONTH';Proposed='201809'},
      @{Name='D2_MONTH_TO_OTHER_YEAR';Prior='PERIODO_COMPETENCIA';Value='201809';Type='YEAR';Proposed='2019'}
    )){
      $null=$script:doc.ClearAll()
      SelectOne $spec.Prior $spec.Value
      $prev=[string]$script:doc.Evaluate(('GetFieldSelections('+$spec.Prior+')'))
      $conflict=($spec.Type -ceq 'MONTH' -and $spec.Value -cne $spec.Proposed.Substring(0,4)) -or
                ($spec.Type -ceq 'YEAR' -and $spec.Value.Substring(0,4) -cne $spec.Proposed)
      if(-not $conflict -or [string]$script:doc.Evaluate(('GetFieldSelections('+$spec.Prior+')')) -cne $prev){
        throw ('BLOCKED: D2 pre-dispatch guard inconsistent '+$spec.Name)
      }
      $guardsOut += [pscustomobject]@{Case=$spec.Name;Policy='D2';Decision='PREVENT_CONFLICT_BEFORE_SELECTION';Dispatched=$false}
      Write-Output ('GUARD='+$spec.Name+' RESULT=PREVENT_CONFLICT_BEFORE_SELECTION DISPATCHED=False')
    }
    $null=$script:doc.ClearAll()
    SelectOne 'PERIODO_ANO' '2018'
    SelectOne 'RES_COD_DATASUS_6' '250750'
    foreach($spec in @(
      @{Name='P5_SERVICE_ROLE_RES';Field='SERV_COD_DATASUS_6';Code='B';Result='BLOCK_GENERAL_INDICATOR'},
      @{Name='P5_PROCEDURE_RES';Field='COD_PROCEDIMENTO';Code='R';Result='REQUIRES_SEPARATE_SCOPED_ANALYSIS'}
    )){
      if((CountSelected $spec.Field) -ne 0){throw ('BLOCKED: incompatible preselection already present '+$spec.Field)}
      $guardsOut += [pscustomobject]@{Case=$spec.Name;Policy=$spec.Code;Decision=$spec.Result;Dispatched=$false}
      Write-Output ('GUARD='+$spec.Name+' RESULT='+$spec.Result+' DISPATCHED=False')
    }
    $guardsOut|Export-Csv -LiteralPath (Join-Path $work 'd2_p5_guards.csv') -NoTypeInformation -Encoding UTF8
    $pass=$true
    Write-Output 'T24_PARTIAL_3_CASES=PASS_CANDIDATE_PENDING_SHA'
    Write-Output 'D2_P5_4_CASES=PASS_PREDISPATCH_WRAPPER_ONLY_NOT_UI'
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
  Write-Output 'VERDICT=PASS_LOCAL_T24_PARTIAL_3_AND_WRAPPER_GUARDS_4_CANDIDATE_ONLY'
  Write-Output 'P5_D2_UI=NOT_TESTED T24_GENERAL=NOT_APPROVED T25_T26=NOT_TESTED PRODUCTION_APPROVED=False'
}
