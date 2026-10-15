# SAD SUS PB — forensic recovery of a completed CNES ST/LT Qlik reload.
# This script does NOT load or start QlikView. It audits the native QV log and R2 console log.
# Produces a distinct TEMP recovery report. Does NOT certify the previous runner as completed.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$TrialDir,
 [Parameter(Mandatory=$true)][string]$ConsoleLog,
 [string]$Root=(Get-Location).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$dir=[IO.Path]::GetFullPath($TrialDir)
$console=[IO.Path]::GetFullPath($ConsoleLog)
$native=Join-Path $dir 'CNES_ST_LT_BODY_PREFLIGHT.qvw.log'
$sourceQvs=Join-Path $repo 'TRANSFORMACAO\cnes_st_lt_historical_scope_empirical_preflight.qvs'
$st=Join-Path $repo 'EXTRACAO\QVD\SRC_CNES_ST.qvd'
$lt=Join-Path $repo 'EXTRACAO\QVD\SRC_CNES_LT.qvd'
$expected=@{
 ST='531F43ACD34B880357191EEA21F4EC942EC8B14528E4BDC18127EBF2037B2312'
 LT='9FADF5CD8592EFEF38E6AFA8E3E9CD020ED281883DED5D8F4F06C546F2F0C360'
}
if(-not [IO.Path]::GetFileName($dir).StartsWith('SAD_CNES_ST_LT_BODY_')){
 throw 'BLOCKED_TRIAL_DIR_NAME_NOT_ALLOWED'
}
if(-not [IO.Path]::GetFileName($console).StartsWith('SAD_CNES_ST_LT_BODY_R2_')){
 throw 'BLOCKED_CONSOLE_LOG_NAME_NOT_R2'
}
foreach($file in @($native,$console,$sourceQvs,$st,$lt,
 (Join-Path $repo 'AGENTS.md'),
 (Join-Path $repo 'docs\project\current-state.md'),
 (Join-Path $repo 'docs\academic\requirements.md'))){
 if(-not(Test-Path -LiteralPath $file -PathType Leaf)){
  throw ('BLOCKED_REQUIRED_FILE_MISSING='+$file)
 }
}
$stSha=(Get-FileHash -LiteralPath $st -Algorithm SHA256).Hash
$ltSha=(Get-FileHash -LiteralPath $lt -Algorithm SHA256).Hash
if($stSha -cne $expected.ST -or $ltSha -cne $expected.LT){
 throw 'BLOCKED_QVD_HASH_DRIFT'
}
$consoleLines=@(Get-Content -LiteralPath $console -ErrorAction Stop)
$nativeLines=@(Get-Content -LiteralPath $native -ErrorAction Stop)
if($consoleLines -notcontains ('TRIAL_DIR='+$dir) -or
   $consoleLines -notcontains ('SOURCE_ST_SHA256='+$expected.ST) -or
   $consoleLines -notcontains ('SOURCE_LT_SHA256='+$expected.LT) -or
   $consoleLines -notcontains 'TEMPORARY_QVW_RELOAD_RETURNED=True'){
 throw 'BLOCKED_R2_CONSOLE_TRIAL_OR_SHA_OR_RELOAD_MISMATCH'
}
if(@($consoleLines|Where-Object{$_ -like 'FINAL_VERDICT=*'}).Count -gt 0){
 throw 'BLOCKED_CONSOLE_FINAL_VERDICT_PRESENT_REVIEW_SEPARATELY'
}
Write-Output 'RECOVERY_INPUTS=PASS_R2_LOG_AND_QVD_SHA256'
$metrics=[ordered]@{}
foreach($line in $consoleLines){
 if($line -match '^EMPIRICAL_([A-Z0-9_]+)=([0-9]+)$'){
  $key=$Matches[1]
  if($metrics.Contains($key)){throw ('BLOCKED_DUPLICATE_CONSOLE_METRIC='+$key)}
  $metrics[$key]=[int64]$Matches[2]
 }
}
$required=@(
 'ST_RECORDS','LT_RECORDS','ST_DISTINCT_PAIRS','LT_DISTINCT_PAIRS',
 'ST_PAIRS_WITH_MULTIPLE_ROWS','ST_PAIRS_WITH_MULTIPLE_NONNULL_TP_VALUES',
 'LT_PAIRS_WITH_MULTIPLE_ROWS','LT_DISTINCT_PAIRS_WITHOUT_ST',
 'ST_DISTINCT_PAIRS_WITHOUT_LT','ST_MISSING_CNES_OR_COMPETEN',
 'LT_MISSING_CNES_OR_COMPETEN','ST_TP_UNID_MISSING',
 'ST_DISTINCT_MONTHS','LT_DISTINCT_MONTHS'
)
foreach($key in $required){
 if(-not $metrics.Contains($key)){throw ('BLOCKED_CONSOLE_METRIC_MISSING='+$key)}
}
if($metrics.Count -ne $required.Count){throw 'BLOCKED_UNEXPECTED_EXTRA_METRICS'}
if($metrics.ST_RECORDS -ne 220390 -or $metrics.LT_RECORDS -ne 35518 -or
   $metrics.ST_DISTINCT_MONTHS -ne 36 -or $metrics.LT_DISTINCT_MONTHS -ne 36 -or
   $metrics.ST_DISTINCT_PAIRS -ne $metrics.ST_RECORDS -or
   $metrics.ST_PAIRS_WITH_MULTIPLE_ROWS -ne 0 -or
   $metrics.LT_DISTINCT_PAIRS -le 0 -or
   $metrics.LT_DISTINCT_PAIRS -gt $metrics.LT_RECORDS -or
   $metrics.LT_DISTINCT_PAIRS_WITHOUT_ST -ne 0 -or
   ($metrics.ST_DISTINCT_PAIRS - $metrics.LT_DISTINCT_PAIRS) -ne $metrics.ST_DISTINCT_PAIRS_WITHOUT_LT){
 throw 'BLOCKED_METRIC_ARITHMETIC_OR_BASELINE_RECONCILIATION'
}
Write-Output 'RECOVERY_CONSOLE_METRICS=14_OF_14_RECONCILED'
# Qlik log records TRACE statements twice: script statements and actual output.
# Keep only actual timestamped output: ... <lineNo> [CNES-KEY] ...
$actual=@($nativeLines|Where-Object{
 $_ -match '^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+\d+\s+\[CNES-KEY\]\s+'
}|ForEach-Object{
 $_ -replace '^.*?\[CNES-KEY\]\s+','[CNES-KEY] '
})
if(@($actual|Where-Object{$_ -eq '[CNES-KEY] VERDICT=PASS_IN_MEMORY_EMPIRICAL_KEY_AND_TP_DISTRIBUTION_NOT_HOSPITAL_CLASSIFICATION'}).Count -ne 1 -or
  @($nativeLines|Where-Object{$_ -match '\bErro: Erro na linha do script:|\bSyntax Error\b|\bUnknown statement\b'}).Count -gt 0){
 throw 'BLOCKED_NATIVE_QLIK_PASS_OR_ERRORS'
}
$pairLine=@($actual|Where-Object{$_ -match '^\[CNES-KEY\] ST_ROWS=\d+ LT_ROWS=\d+ ST_PAIR_KEYS=\d+ LT_PAIR_KEYS=\d+$'})
if($pairLine.Count -ne 1 -or
   $pairLine[0] -cne ('[CNES-KEY] ST_ROWS='+$metrics.ST_RECORDS+' LT_ROWS='+$metrics.LT_RECORDS+
                    ' ST_PAIR_KEYS='+$metrics.ST_DISTINCT_PAIRS+' LT_PAIR_KEYS='+$metrics.LT_DISTINCT_PAIRS)){
 throw 'BLOCKED_NATIVE_PAIRS_DONT_MATCH_CONSOLE'
}
$domainHeader=@($actual|Where-Object{$_ -match '^\[CNES-KEY\] ST_MONTHS=36 LT_MONTHS=36 ST_TP_DOMAIN_COUNT=(\d+)$'})
if($domainHeader.Count -ne 1){throw 'BLOCKED_NATIVE_MONTHS_OR_TP_HEADER'}
$domainCount=[int]([regex]::Match($domainHeader[0],'ST_TP_DOMAIN_COUNT=(\d+)$').Groups[1].Value)
if($domainCount -lt 1 -or $domainCount -gt 500){throw 'BLOCKED_INVALID_TP_DOMAIN_COUNT'}
$stMonths=@()
$ltMonths=@()
$types=@()
foreach($line in $actual){
 if($line -match '^\[CNES-KEY\] ST_COMPETEN=(\d{6}) ROWS=(\d+) DISTINCT_CNES=(\d+)$'){
  $stMonths+=([pscustomobject]@{competence=$Matches[1];rows=[int64]$Matches[2];distinct_cnes=[int64]$Matches[3]})
 }elseif($line -match '^\[CNES-KEY\] LT_COMPETEN=(\d{6}) ROWS=(\d+) DISTINCT_CNES=(\d+)$'){
  $ltMonths+=([pscustomobject]@{competence=$Matches[1];rows=[int64]$Matches[2];distinct_cnes=[int64]$Matches[3]})
 }elseif($line -match '^\[CNES-KEY\] TP_UNID_RAW_LABEL=(.*?) ST_ROWS=(\d+)$'){
  $types+=([pscustomobject]@{raw_label=$Matches[1];st_rows=[int64]$Matches[2]})
 }
}
$expectedMonths=@(foreach($year in 2017..2019){foreach($month in 1..12){'{0}{1:00}' -f $year,$month}})
foreach($kind in @('ST','LT')){
 $rows=if($kind -eq 'ST'){$stMonths}else{$ltMonths}
 $names=@($rows|ForEach-Object{$_.competence}|Sort-Object)
 if($names.Count -ne 36 -or (@(Compare-Object -ReferenceObject $expectedMonths -DifferenceObject $names).Count -ne 0)){
  throw ('BLOCKED_MISSING_DUPLICATE_OR_EXTRA_COMPETENCE_'+$kind)
 }
}
if($types.Count -ne $domainCount -or
   @($types|Group-Object -Property raw_label|Where-Object{$_.Count -ne 1}).Count -gt 0 -or
   [int64](($types|Measure-Object -Property st_rows -Sum).Sum) -ne 220390 -or
   [int64](($stMonths|Measure-Object -Property rows -Sum).Sum) -ne 220390 -or
   [int64](($ltMonths|Measure-Object -Property rows -Sum).Sum) -ne 35518){
 throw 'BLOCKED_TP_DISTRIBUTION_OR_MONTH_SUM_RECONCILIATION'
}
Write-Output ('RECOVERY_NATIVE_TRACES=PASS ST_MONTHS=36 LT_MONTHS=36 TP_RAW_CODES='+$domainCount)
foreach($entry in @(@{path=$st;sha=$stSha},@{path=$lt;sha=$ltSha})){
 if((Get-FileHash -LiteralPath $entry.path -Algorithm SHA256).Hash -cne $entry.sha){
  throw ('BLOCKED_QVD_HASH_CHANGED='+$entry.path)
 }
}
$evidence=Join-Path ([IO.Path]::GetTempPath()) ('SAD_CNES_ST_LT_R2_RECOVERY_'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $evidence -ErrorAction Stop|Out-Null
$tpCsv=Join-Path $evidence 'tp_unid_raw_distribution.csv'
$stCsv=Join-Path $evidence 'st_monthly_rows.csv'
$ltCsv=Join-Path $evidence 'lt_monthly_rows.csv'
$summaryFile=Join-Path $evidence 'recovery_summary.txt'
$types|Export-Csv -LiteralPath $tpCsv -NoTypeInformation -Encoding UTF8
$stMonths|Export-Csv -LiteralPath $stCsv -NoTypeInformation -Encoding UTF8
$ltMonths|Export-Csv -LiteralPath $ltCsv -NoTypeInformation -Encoding UTF8
$summaryLines=@(
 'MODE=CNES_ST_LT_R2_LOG_FORENSIC_RECONCILIATION_NO_RELOAD',
 'R2_ORIGINAL_RUNNER_FINAL_VERDICT=NOT_RECEIVED',
 'LOG_NATIVE_SHA256='+(Get-FileHash -LiteralPath $native -Algorithm SHA256).Hash,
 'CONSOLE_LOG_SHA256='+(Get-FileHash -LiteralPath $console -Algorithm SHA256).Hash,
 'ST_QVD_SHA256='+$stSha,
 'LT_QVD_SHA256='+$ltSha,
 'QVS_SHA256='+(Get-FileHash -LiteralPath $sourceQvs -Algorithm SHA256).Hash,
 'RAW_TP_CODES='+$domainCount
)
foreach($key in $required){$summaryLines+=('EMPIRICAL_'+$key+'='+$metrics[$key])}
$summaryLines+=@(
 'ST_COMPETENCES=36',
 'LT_COMPETENCES=36',
 'TP_DISTRIBUTION_CSV_SHA256='+(Get-FileHash -LiteralPath $tpCsv -Algorithm SHA256).Hash,
 'ST_MONTHLY_CSV_SHA256='+(Get-FileHash -LiteralPath $stCsv -Algorithm SHA256).Hash,
 'LT_MONTHLY_CSV_SHA256='+(Get-FileHash -LiteralPath $ltCsv -Algorithm SHA256).Hash,
 'CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED',
 'T29_HISTORICAL=NOT_APPROVED',
 'ORIGINAL_RUNNER_INTEGRITY_GATE=NOT_COMPLETED',
 'FINAL_VERDICT=PASS_R2_FORENSIC_LOG_RECONCILIATION_RESTRICTED_NOT_ORIGINAL_RUNNER_GATE'
)
$summaryLines|Set-Content -LiteralPath $summaryFile -Encoding UTF8
Write-Output ('FORENSIC_EVIDENCE_DIR='+$evidence)
Write-Output ('FORENSIC_SUMMARY='+$summaryFile)
Write-Output ('FORENSIC_SUMMARY_SHA256='+(Get-FileHash -LiteralPath $summaryFile -Algorithm SHA256).Hash)
Write-Output ('FORENSIC_TP_CSV='+$tpCsv)
Write-Output ('FORENSIC_ST_MONTH_CSV='+$stCsv)
Write-Output ('FORENSIC_LT_MONTH_CSV='+$ltCsv)
Write-Output 'QV_COM_NOT_USED=True RELOAD_EXECUTED=False SOURCE_QVD_WRITES=0'
Write-Output 'CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED'
Write-Output 'T29_HISTORICAL=NOT_APPROVED'
Write-Output 'FINAL_VERDICT=PASS_R2_FORENSIC_LOG_RECONCILIATION_RESTRICTED_NOT_ORIGINAL_RUNNER_GATE'
