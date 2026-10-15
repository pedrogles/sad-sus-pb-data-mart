# SAD PB — CNES ST/LT R3 empirical TP_UNID at LT-paired competence keys.
# Strictly read-only for sources; QVW only in new TEMP. No COM Evaluate()/JSON serialization.
[CmdletBinding()]
param([string]$Root=(Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath($Root)
$qvs=Join-Path $root 'TRANSFORMACAO\cnes_st_lt_tp_unid_paired_preflight.qvs'
$st=Join-Path $root 'EXTRACAO\QVD\SRC_CNES_ST.qvd'
$lt=Join-Path $root 'EXTRACAO\QVD\SRC_CNES_LT.qvd'
$required=@($qvs,$st,$lt,
 (Join-Path $root 'AGENTS.md'),
 (Join-Path $root 'docs\project\current-state.md'),
 (Join-Path $root 'docs\academic\requirements.md'))
foreach($p in $required){
 if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('REQUIRED_INPUT_MISSING='+$p)}
}
$fixed=@{
 ST='531F43ACD34B880357191EEA21F4EC942EC8B14528E4BDC18127EBF2037B2312'
 LT='9FADF5CD8592EFEF38E6AFA8E3E9CD020ED281883DED5D8F4F06C546F2F0C360'
}
$before=@{}
foreach($p in @($qvs,$st,$lt)){$before[$p]=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash}
if($before[$st] -cne $fixed.ST -or $before[$lt] -cne $fixed.LT){
 throw 'BLOCKED_ST_LT_QVD_BASELINE_HASH_DRIFT'
}
$script=[IO.File]::ReadAllText($qvs,[Text.Encoding]::UTF8)
foreach($token in @('__ST_QVD_ABSOLUTE__','__LT_QVD_ABSOLUTE__',
 'R3_ST_TP_MAP:','R3_LT_TYPED:','R3_TP_GROUP:','R3_MONTH_TP_GROUP:',
 'PASS_LT_PAIRED_TP_RAW_EMPIRICAL_PROFILING_NOT_HOSPITAL_SCOPE')){
 if(-not $script.Contains($token)){throw ('BLOCKED_QVS_ANCHOR_MISSING='+$token)}
}
if($script -match '(?im)^\s*(STORE|JOIN|BINARY|EXECUTE|LEFT JOIN|RIGHT JOIN|INNER JOIN|OUTER JOIN)\b'){
 throw 'BLOCKED_NON_READONLY_QVS'
}
$ifs=@($script -split '\r?\n'|Where-Object{$_ -match '^\s*IF\s+' -and $_ -notmatch '\bTHEN\b'})
if($ifs.Count -gt 0){throw 'BLOCKED_QVS_IF_MISSING_SAME_LINE_THEN'}
foreach($p in @($st,$lt)){
 if($p.Contains(']') -or $p.Contains([string][char]13) -or $p.Contains([string][char]10)){
  throw ('BLOCKED_PATH_UNSAFE_FOR_QLIK='+$p)
 }
}
$script=$script.Replace('__ST_QVD_ABSOLUTE__',$st).Replace('__LT_QVD_ABSOLUTE__',$lt)
if($script.Contains('__ST_QVD_ABSOLUTE__') -or $script.Contains('__LT_QVD_ABSOLUTE__')){
 throw 'BLOCKED_QVD_PATH_SUBSTITUTION'
}
function ScriptEquivalent([string]$x,[string]$y){
 return ($x.Replace([string][char]13,'').TrimEnd() -ceq
         $y.Replace([string][char]13,'').TrimEnd())
}
Write-Output 'R3_STATIC_SCRIPT_AND_QVD_HASH_GATES=PASS'
$dir=Join-Path ([IO.Path]::GetTempPath()) ('SAD_CNES_ST_LT_TP_PAIRED_'+[Guid]::NewGuid().ToString('N'))
New-Item -Path $dir -ItemType Directory -ErrorAction Stop|Out-Null
$qvw=Join-Path $dir 'CNES_ST_LT_TP_PAIRED_PREFLIGHT.qvw'
$native="$qvw.log"
$app=$null;$doc=$null;$problem=$null
try{
 Write-Output ('R3_TEMP_DIR='+$dir)
 Write-Output ('SOURCE_ST_SHA256='+$before[$st])
 Write-Output ('SOURCE_LT_SHA256='+$before[$lt])
 $app=New-Object -ComObject 'QlikTech.QlikView'
 $doc=$app.CreateDoc()
 if($null -eq $doc){throw 'QV_CREATE_DOC_FAILED'}
 $properties=$doc.GetProperties()
 $properties.Script=$script
 $properties.GenerateLogfile=$true
 [void]$doc.SetProperties($properties)
 if(-not(ScriptEquivalent ([string]$doc.GetProperties().Script) $script) -or
    -not [bool]$doc.GetProperties().GenerateLogfile){
  throw 'QV_SCRIPT_LOG_FLAG_MISMATCH'
 }
 [void]$doc.SaveAs($qvw)
 if(-not(Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'QV_DISPOSABLE_MISSING'}
 [void]$doc.CloseDoc()
 $doc=$null
 $doc=$app.OpenDoc($qvw,'','')
 if($null -eq $doc){throw 'QV_OPEN_TEMP_DOC_FAILED'}
 $begin=[datetime]::UtcNow
 Write-Output 'R3_TEMP_QVW_RELOAD_STARTED=True'
 [void]$doc.Reload()
 Write-Output 'R3_TEMP_QVW_RELOAD_RETURNED=True'
 [void]$doc.CloseDoc()
 $doc=$null
 Write-Output 'R3_QV_DOC_CLOSED_BEFORE_LOG_CHECK=True'
 if(-not(Test-Path -LiteralPath $native -PathType Leaf) -or
  (Get-Item -LiteralPath $native).LastWriteTimeUtc -lt $begin.AddSeconds(-2)){
  throw 'BLOCKED_NATIVE_QV_LOG_MISSING_STALE'
 }
 $lines=@(Get-Content -LiteralPath $native)
 $trace=@($lines|Where-Object{
  $_ -match '^\d{4}-\d\d-\d\d\s+\d\d:\d\d:\d\d\s+\d+\s+\[CNES-R3\]\s+'
 }|ForEach-Object{$_ -replace '^.*?\[CNES-R3\]\s+','[CNES-R3] '})
 $final='[CNES-R3] VERDICT=PASS_LT_PAIRED_TP_RAW_EMPIRICAL_PROFILING_NOT_HOSPITAL_SCOPE'
 $total=@($trace|Where-Object{$_.StartsWith('[CNES-R3] TOTAL ')})
 if(@($trace|Where-Object{$_ -ceq $final}).Count -ne 1 -or $total.Count -ne 1){
  throw 'BLOCKED_R3_NATIVE_VERDICT_OR_TOTAL_MISSING'
 }
 if($total[0] -notmatch 'LT_ROWS=35518 GROUP_ROWS=35518 PAIRS=7486 MONTH_ROWS=35518 MONTH_PAIRS=7486 UNMATCHED_ROWS=0 CODES=\d+ MONTH_CODES=\d+$'){
  throw ('BLOCKED_R3_TOTALS='+$total[0])
 }
 $byType=@($trace|Where-Object{$_.StartsWith('[CNES-R3] TP_RAW=')})
 $byMonth=@($trace|Where-Object{$_.StartsWith('[CNES-R3] MONTH=')})
 if($byType.Count -lt 1 -or $byMonth.Count -lt 36){
  throw 'BLOCKED_R3_CODE_OR_MONTH_TRACE_MISSING'
 }
 if(@($trace|Where-Object{$_.Contains('VERDICT=BLOCKED')}).Count -gt 0 -or
  @($lines|Where-Object{$_ -match '(?i)Erro na linha do script|Syntax Error|Unknown statement'}).Count -gt 0){
  throw 'BLOCKED_R3_NATIVE_ERROR'
 }
 foreach($p in $before.Keys){
  if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -cne $before[$p]){
   throw ('BLOCKED_IMMUTABLE_HASH_DRIFT='+$p)
  }
 }
 Write-Output ('R3_ACTUAL_TYPE_GROUPS='+$byType.Count)
 Write-Output ('R3_ACTUAL_MONTH_TYPE_GROUPS='+$byMonth.Count)
 Write-Output ('R3_ACTUAL_NATIVE_TRACES='+$trace.Count)
 Write-Output ('R3_NATIVE_QV_LOG='+$native)
 Write-Output ('R3_NATIVE_QV_LOG_SHA256='+(Get-FileHash -LiteralPath $native -Algorithm SHA256).Hash)
 Write-Output 'IMMUTABLE_SOURCE_HASHES_UNCHANGED=True'
 Write-Output 'SOURCE_QVD_WRITES=0 TEMP_QVW_SAVED_AFTER_RELOAD=False'
 Write-Output 'CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED'
 Write-Output 'T29_HISTORICAL=NOT_APPROVED'
}catch{
 $problem=$_.Exception.Message
 Write-Output ('R3_GATE_FAIL_CLOSED='+$problem)
}finally{
 if($null -ne $doc){try{[void]$doc.CloseDoc()}catch{}}
 foreach($p in $before.Keys){
  if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -cne $before[$p]){
   $problem='IMMUTABLE_SOURCE_HASH_DRIFT='+$p
  }
 }
 Write-Output ('R3_TEMP_DIR_FINAL='+$dir)
}
if($problem){Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$problem);exit 1}
Write-Output 'FINAL_VERDICT=PASS_R3_LT_PAIRED_TP_EMPIRICAL_NOT_HOSPITAL_SCOPE'
