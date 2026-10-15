# SAD PB — CNES ST/LT in-memory empirical body audit for coverage; QlikView 12.
# Strictly read-only for QVDs; no JOIN, STORE, original QVW, fact creation or approvals.
[CmdletBinding()]
param([string]$Root=(Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$rootDir=[IO.Path]::GetFullPath($Root)
$qvs=Join-Path $rootDir 'TRANSFORMACAO\cnes_st_lt_historical_scope_empirical_preflight.qvs'
$st=Join-Path $rootDir 'EXTRACAO\QVD\SRC_CNES_ST.qvd'
$lt=Join-Path $rootDir 'EXTRACAO\QVD\SRC_CNES_LT.qvd'
$header=Join-Path $rootDir 'tools\inventariar_cnes_st_lt_qvd_headers.ps1'
$required=@($qvs,$st,$lt,$header,
 (Join-Path $rootDir 'AGENTS.md'),
 (Join-Path $rootDir 'docs\project\current-state.md'),
 (Join-Path $rootDir 'docs\academic\requirements.md'))
foreach($p in $required){
 if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('REQUIRED_SOURCE_MISSING='+$p)}
}
$expectedHashes=@{
 ST='531F43ACD34B880357191EEA21F4EC942EC8B14528E4BDC18127EBF2037B2312'
 LT='9FADF5CD8592EFEF38E6AFA8E3E9CD020ED281883DED5D8F4F06C546F2F0C360'
}
$before=@{}
foreach($k in @('ST','LT')){
 $p=if($k -eq 'ST'){$st}else{$lt}
 $hash=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
 if($hash -cne $expectedHashes[$k]){throw ('BLOCKED_QVD_SOURCE_HASH_DRIFT='+$k)}
 $before[$p]=$hash
}
$before[$qvs]=(Get-FileHash -LiteralPath $qvs -Algorithm SHA256).Hash
$before[$header]=(Get-FileHash -LiteralPath $header -Algorithm SHA256).Hash
# Reuse the canonical metadata gate before reading QVD records.
$headers=@(& $header -Root $rootDir)
if($headers -notcontains 'FINAL_VERDICT=PASS_HEADER_INVENTORY_ONLY_NOT_HOSPITAL_SCOPE'){
 throw 'HEADER_GATE_NOT_PASSED'
}
$body=[IO.File]::ReadAllText($qvs,[Text.Encoding]::UTF8)
foreach($token in @('__ST_QVD_ABSOLUTE__','__LT_QVD_ABSOLUTE__',
 'PASS_IN_MEMORY_EMPIRICAL_KEY_AND_TP_DISTRIBUTION_NOT_HOSPITAL_CLASSIFICATION',
 'CNES_ST_PAIR_GROUP:','CNES_LT_PAIR_GROUP:','CNES_ST_TP_DISTRIBUTION:',
 'CNES_LT_PAIR_MATCH:','CNES_ST_PAIR_MATCH:')){
 if(-not $body.Contains($token)){throw ('BLOCKED_QVS_FINGERPRINT_MISSING='+$token)}
}
if($body -match '(?im)^\s*(STORE|JOIN|BINARY|EXECUTE|INNER JOIN|LEFT JOIN|RIGHT JOIN|OUTER JOIN)\b'){
 throw 'BLOCKED_QVS_HAS_FORBIDDEN_DATA_OPERATION'
}
foreach($p in @($st,$lt)){
 if($p.Contains(']') -or $p.Contains([string][char]10) -or $p.Contains([string][char]13)){
  throw ('INVALID_QVD_PATH_FOR_BRACKET_LOAD='+$p)
 }
}
$scriptText=$body.Replace('__ST_QVD_ABSOLUTE__',$st).Replace('__LT_QVD_ABSOLUTE__',$lt)
if($scriptText.Contains('__ST_QVD_ABSOLUTE__') -or $scriptText.Contains('__LT_QVD_ABSOLUTE__')){
 throw 'QVS_PATH_REPLACEMENT_FAILED'
}
function Same([string]$a,[string]$b){
 return ($a.Replace([string][char]13,'').TrimEnd() -ceq
         $b.Replace([string][char]13,'').TrimEnd())
}
$dir=Join-Path ([IO.Path]::GetTempPath()) ('SAD_CNES_ST_LT_BODY_'+[guid]::NewGuid().ToString('N'))
New-Item -Path $dir -ItemType Directory -ErrorAction Stop|Out-Null
$copy=Join-Path $dir 'CNES_ST_LT_BODY_PREFLIGHT.qvw'
$native="$copy.log"
$report=Join-Path $dir 'empirical_audit.json'
$qv=$null;$doc=$null;$failure=$null
$summary=[ordered]@{}
try{
 Write-Output 'MODE=CNES_ST_LT_BODY_READ_ONLY_QV_IN_MEMORY'
 Write-Output ('TRIAL_DIR='+$dir)
 Write-Output ('SOURCE_ST_SHA256='+$before[$st])
 Write-Output ('SOURCE_LT_SHA256='+$before[$lt])
 $qv=New-Object -ComObject 'QlikTech.QlikView'
 $doc=$qv.CreateDoc()
 if($null -eq $doc){throw 'QV_COM_CREATEDOC_NULL'}
 $properties=$doc.GetProperties()
 $properties.Script=$scriptText
 $properties.GenerateLogfile=$true
 [void]$doc.SetProperties($properties)
 if(-not(Same ([string]$doc.GetProperties().Script) $scriptText) -or
    -not [bool]$doc.GetProperties().GenerateLogfile){
  throw 'QV_SCRIPT_OR_LOG_FLAG_NOT_RETAINED'
 }
 [void]$doc.SaveAs($copy)
 if(-not(Test-Path -LiteralPath $copy -PathType Leaf)){throw 'DISPOSABLE_QVW_CREATE_FAILED'}
 [void]$doc.CloseDoc()
 $doc=$qv.OpenDoc($copy,'','')
 if($null -eq $doc){throw 'QV_COM_OPENDOC_NULL'}
 $start=[DateTime]::UtcNow
 Write-Output 'TEMPORARY_QVW_RELOAD_STARTED=True'
 [void]$doc.Reload()
 Write-Output 'TEMPORARY_QVW_RELOAD_RETURNED=True'
 if(-not(Test-Path -LiteralPath $native -PathType Leaf) -or
   (Get-Item -LiteralPath $native).LastWriteTimeUtc -lt $start.AddSeconds(-2)){
  throw 'NATIVE_QLIK_LOG_MISSING_OR_STALE'
 }
 $lines=@(Get-Content -LiteralPath $native | Where-Object{$_ -notmatch '\bTRACE\b'})
 foreach($must in @(
  '[CNES-KEY] ST_ROWS=220390 LT_ROWS=35518 ST_PAIR_KEYS=',
  '[CNES-KEY] ST_MONTHS=36 LT_MONTHS=36 ST_TP_DOMAIN_COUNT=',
  '[CNES-KEY] VERDICT=PASS_IN_MEMORY_EMPIRICAL_KEY_AND_TP_DISTRIBUTION_NOT_HOSPITAL_CLASSIFICATION'
 )){
  if(@($lines|Where-Object{$_.Contains($must)}).Count -ne 1){
   throw ('NATIVE_QLIK_REQUIRED_MARKER_ABSENT_OR_DUPLICATE='+$must)
  }
 }
 if(@($lines|Where-Object{
  $_ -match '\[CNES-KEY\] VERDICT=BLOCKED' -or
  $_ -match '(?i)syntax error|unknown statement|circular reference|loosely coupled|referência circular'
 }).Count -gt 0){throw 'NATIVE_QLIK_ERROR_OR_CIRCULAR_WARNING'}
 $byST=@($lines|Where-Object{$_ -match '\[CNES-KEY\] ST_COMPETEN='})
 $byLT=@($lines|Where-Object{$_ -match '\[CNES-KEY\] LT_COMPETEN='})
 $byTP=@($lines|Where-Object{$_ -match '\[CNES-KEY\] TP_UNID_RAW_LABEL='})
 if($byST.Count -ne 36 -or $byLT.Count -ne 36 -or $byTP.Count -lt 1){
  throw ('BLOCKED_NATIVE_DOMAIN_COUNTS_ST_'+$byST.Count+'_LT_'+$byLT.Count+'_TP_'+$byTP.Count)
 }
 function E([string]$formula){return [string]$script:doc.Evaluate($formula)}
 $summary=[ordered]@{
  st_records=(E "Count(ST_CNES)")
  lt_records=(E "Count(LT_CNES)")
  st_distinct_pairs=(E "Count(DISTINCT ST_GROUP_PAIR)")
  lt_distinct_pairs=(E "Count(DISTINCT LT_GROUP_PAIR)")
  st_pairs_with_multiple_rows=(E "Sum(If(ST_GROUP_ROWS>1,1,0))")
  st_pairs_with_multiple_nonnull_tp_values=(E "Sum(If(ST_GROUP_TP_VARIANTS>1,1,0))")
  lt_pairs_with_multiple_rows=(E "Sum(If(LT_GROUP_ROWS>1,1,0))")
  lt_distinct_pairs_without_st=(E "Sum(If(LT_GROUP_ST_EXISTS=0,1,0))")
  st_distinct_pairs_without_lt=(E "Sum(If(ST_GROUP_LT_EXISTS=0,1,0))")
  st_missing_cnes_or_competen=(E "Sum(If(IsNull(ST_CNES) or Len(Trim(ST_CNES))=0 or IsNull(ST_COMPETEN) or Len(Trim(ST_COMPETEN))=0,1,0))")
  lt_missing_cnes_or_competen=(E "Sum(If(IsNull(LT_CNES) or Len(Trim(LT_CNES))=0 or IsNull(LT_COMPETEN) or Len(Trim(LT_COMPETEN))=0,1,0))")
  st_tp_unid_missing=(E "Sum(If(IsNull(ST_TP_UNID) or Len(Trim(ST_TP_UNID))=0,1,0))")
  st_distinct_months=(E "Count(DISTINCT ST_MONTH)")
  lt_distinct_months=(E "Count(DISTINCT LT_MONTH)")
 }
 if($summary.st_records -cne '220390' -or $summary.lt_records -cne '35518' -or
   $summary.st_distinct_months -cne '36' -or $summary.lt_distinct_months -cne '36'){
  throw ('BLOCKED_COM_EVALUATE_BASELINE_DRIFT='+($summary|ConvertTo-Json -Compress))
 }
 foreach($key in $summary.Keys){Write-Output ('EMPIRICAL_'+$key.ToUpperInvariant()+'='+$summary[$key])}
 $markers=@($lines|Where-Object{$_ -match '\[CNES-KEY\]'})
 $obj=[ordered]@{
  mode='CNES_ST_LT_BODY_IN_MEMORY_READ_ONLY'
  sourceST=$before[$st];sourceLT=$before[$lt];sourceQvs=$before[$qvs]
  empirical=$summary
  trace_markers=$markers
  assumptions=@('CNES+COMPETEN is a candidate coordination key only','TP_UNID is raw; no code interpreted as hospital','no historical coverage approval')
  verdict='PASS_EMPIRICAL_SOURCE_PROFILING_ONLY_NOT_HOSPITAL_SCOPE'
 }
 $obj|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $report -Encoding UTF8
 Write-Output ('EMPIRICAL_REPORT='+$report)
 Write-Output ('EMPIRICAL_REPORT_SHA256='+(Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash)
 Write-Output ('NATIVE_QV_LOG='+$native)
 foreach($p in $before.Keys){
  if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -cne $before[$p]){
   throw ('IMMUTABLE_INPUT_CHANGED='+$p)
  }
 }
 Write-Output 'IMMUTABLE_INPUTS_SHA256_UNCHANGED=True'
 Write-Output 'SOURCE_QVD_WRITES=0'
 Write-Output 'TEMP_QVW_SAVED_AFTER_RELOAD=False'
 Write-Output 'CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED'
 Write-Output 'T29_HISTORICAL=NOT_APPROVED'
 Write-Output 'FACT_QVDS=NOT_STARTED LINK_ANALISE_QVD=NOT_STARTED PAINEL=NOT_STARTED'
}catch{
 $failure=$_.Exception.Message
 Write-Output ('GATE=FAIL_CLOSED_'+$failure)
}finally{
 if($null -ne $doc){try{[void]$doc.CloseDoc()}catch{}}
 foreach($p in $before.Keys){
  if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -cne $before[$p]){
   $failure='IMMUTABLE_INPUT_CHANGED='+$p
  }
 }
 Write-Output ('TEMP_DIAGNOSTIC_DIR='+$dir)
}
if($failure){Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$failure);exit 1}
Write-Output 'FINAL_VERDICT=PASS_EMPIRICAL_SOURCE_PROFILING_ONLY_NOT_HOSPITAL_SCOPE'
