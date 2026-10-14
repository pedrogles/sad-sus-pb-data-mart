# F4-P5 — teste COM restrito de recuperação de componentes (não indicador).
[CmdletBinding()]
param([Parameter(Mandatory)][string]$SourceQvw,[Parameter(Mandatory)][string]$F4Dir)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$src=[IO.Path]::GetFullPath($SourceQvw)
$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
if (-not $src.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
 [IO.Path]::GetFileName($src) -cne 'F4_P5_SOURCE_PROJECTION_DISPOSABLE.qvw' -or
 [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($src)) -notmatch '^SAD_F4_P5_PROJECTION_[0-9a-f]{32}$') {
 throw 'SOURCE_MUST_BE_DISPOSABLE_F4_P5'
}
$csv=Join-Path $F4Dir 'F4_p5_filtros_isolados.csv'
$manifestPath=Join-Path $F4Dir 'manifest_F4.json'
foreach($f in @($src,$csv,$manifestPath)){if(-not(Test-Path -LiteralPath $f -PathType Leaf)){throw "MISSING=$f"}}
$m=Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$hash=(Get-FileHash $csv -Algorithm SHA256).Hash.ToLowerInvariant()
if($hash -cne [string]$m.output_sha256.'F4_p5_filtros_isolados.csv'){throw 'P5_REFERENCE_HASH_MISMATCH'}
$cases=@(Import-Csv $csv -Delimiter ';' -Encoding UTF8)
if($cases.Count -ne 48){throw 'P5_CASE_COUNT_NOT_48'}
$policy=@{}
foreach($c in $cases){
 $key=[string]$c.filtro+'|'+[string]$c.indicador
 if($policy.ContainsKey($key) -or @('C','R','I','B') -cnotcontains [string]$c.politica_p5){throw "P5_CASE_INVALID=$key"}
 $policy[$key]=[string]$c.politica_p5
}
$probe=@{
 'Procedimento realizado PROC_REA'=@('R','I','B','R')
 'Tipo/codigo de leito'=@('I','R','B','I')
}
foreach($filter in $probe.Keys){
 $i=0
 foreach($role in @('RES','LEI','REL','FLU')){
  $k=$filter+'|'+$role
  if($policy[$k] -cne $probe[$filter][$i]){throw "P5_CONTRACT_DRIFT=$k"}
  $i++
 }
}
$before=(Get-FileHash $src -Algorithm SHA256).Hash
$dir=Join-Path ([IO.Path]::GetTempPath()) ('SAD_F4_P5_RECOVERY_'+[Guid]::NewGuid().ToString('N'))
New-Item $dir -ItemType Directory -ErrorAction Stop | Out-Null
$copy=Join-Path $dir 'F4_P5_RECOVERY_DISPOSABLE.qvw'
Copy-Item $src $copy -ErrorAction Stop
if((Get-FileHash $copy -Algorithm SHA256).Hash -cne $before){throw 'COPY_HASH_MISMATCH'}
$qv=$null;$doc=$null;$errorReason=$null
function EvalQ([string]$e){return [string]$script:doc.Evaluate($e)}
function AssertQ([string]$what,[string]$e,[string]$want){
 $actual=EvalQ $e
 if($actual -cne $want){throw "BLOCKED_$what EXPECTED=$want ACTUAL=$actual"}
}
function Sel([string]$name,[string]$value){
 $field=$null
 try {$field=$script:doc.GetField($name);if($null -eq $field){throw "NO_FIELD=$name"};$null=$field.Select($value)}
 finally {if($null -ne $field -and [Runtime.InteropServices.Marshal]::IsComObject($field)){[void][Runtime.InteropServices.Marshal]::ReleaseComObject($field)}}
}
function Reset {$null=$script:doc.ClearAll()}
function DenyGeneral([string]$filter){
 foreach($role in @('RES','LEI','REL','FLU')){
  $code=$script:policy[$filter+'|'+$role]
  if($code -ceq 'C'){throw "UNEXPECTED_COMPATIBLE=$filter|$role"}
  $reason=switch($code){'R'{'REQUIRES_SEPARATE_SCOPED_ANALYSIS'} 'I'{'REQUIRES_EXPLICIT_ISOLATION_AND_WARNING'} 'B'{'BLOCK_GENERAL_INDICATOR'}}
  Write-Output "P5_DENY_GENERAL FILTER=$filter ROLE=$role CODE=$code REASON=$reason"
 }
}
try {
 Write-Output 'MODE=F4_P5_COMPONENT_RECOVERY_AND_P5_DENIAL_RESTRICTED'
 Write-Output 'P5_REFERENCE_HASH_PASS=True'
 $qv=New-Object -ComObject 'QlikTech.QlikView'
 $doc=$qv.OpenDoc($copy,'','')
 if($null -eq $doc){throw 'COM_OPEN_FAILED'}
 Reset
 AssertQ 'BASE_RD' 'Sum(F4_RD_QTD_INTERNACAO)' '555089'
 AssertQ 'BASE_LT' 'Sum(F4_LT_QT_SUS)' '270076'
 AssertQ 'BASE_POP' 'Count(P6_POP_ROW_DEBUG)' '669'
 Write-Output 'BASELINE_PASS'
 Reset;Sel 'P6_ANO_ANO' '2018'
 $proc=EvalQ 'MinString(F4_RD_PROC_REA)'
 if(-not $proc){throw 'NO_2018_PROCEDURE'}
 Sel 'F4_RD_PROC_REA' $proc
 AssertQ 'PROC_DIRECT_LT' 'Count(F4_LT_QT_SUS)' '0'
 AssertQ 'PROC_DIRECT_POP' 'Count(P6_POP_ROW_DEBUG)' '0'
 AssertQ 'PROC_RECOVER_LT' 'Sum({$<F4_RD_PROC_REA=>} F4_LT_QT_SUS)' '89422'
 AssertQ 'PROC_RECOVER_POP' 'Sum({$<F4_RD_PROC_REA=>} P6_POP_HABITANTES_E5)' '3996496'
 Write-Output "PROCEDURE_2018=$proc LT_COMPONENT_RECOVERED=89422 POP_COMPONENT_RECOVERED=3996496 AUDIT_ONLY=True"
 DenyGeneral 'Procedimento realizado PROC_REA'
 Reset;Sel 'P6_ANO_ANO' '2018'
 $bed=EvalQ 'MinString(F4_LT_CODLEITO)'
 if(-not $bed){throw 'NO_2018_BED_CODE'}
 Sel 'F4_LT_CODLEITO' $bed
 AssertQ 'BED_DIRECT_RD' 'Count(F4_RD_IDENT)' '0'
 AssertQ 'BED_DIRECT_POP' 'Count(P6_POP_ROW_DEBUG)' '0'
 AssertQ 'BED_RECOVER_RD' 'Sum({$<F4_LT_CODLEITO=>} F4_RD_QTD_INTERNACAO)' '183311'
 AssertQ 'BED_RECOVER_POP' 'Sum({$<F4_LT_CODLEITO=>} P6_POP_HABITANTES_E5)' '3996496'
 Write-Output "BED_2018=$bed RD_COMPONENT_RECOVERED=183311 POP_COMPONENT_RECOVERED=3996496 AUDIT_ONLY=True"
 DenyGeneral 'Tipo/codigo de leito'
 Reset;Sel 'P6_ANO_ANO' '2018';Sel 'P6_SERV_DATASUS_6' '250750';Sel 'P6_RES_DATASUS_6' '250400'
 AssertQ 'DUAL_DIRECT_POP' 'Count(P6_POP_ROW_DEBUG)' '0'
 AssertQ 'DUAL_SERVICE_POP' 'Sum({$<P6_RES_DATASUS_6=>} P6_POP_HABITANTES_E5)' '800323'
 AssertQ 'DUAL_RES_POP' 'Sum({$<P6_SERV_DATASUS_6=>} P6_POP_HABITANTES_E5)' '407472'
 Write-Output 'DUAL_ROLE_2018 RECOVERED_SERVICE_POP=800323 RECOVERED_RES_POP=407472 AUDIT_ONLY=True'
 Write-Output 'P5_DENIAL_FOR_EXCLUSIVE_FILTERS=PASS_WRAPPER_ONLY'
} catch {$errorReason=$_.Exception.Message;Write-Output ('GATE=FAIL_CLOSED_'+$errorReason)}
finally {
 if($null -ne $doc){try{[void]$doc.CloseDoc()}catch{};if([Runtime.InteropServices.Marshal]::IsComObject($doc)){[void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc)}}
 if($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)){[void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)}
 $after=(Get-FileHash $src -Algorithm SHA256).Hash
 Write-Output ('SOURCE_SHA256_UNCHANGED='+($before -ceq $after))
 Write-Output 'SAVE_EXECUTED=False RELOAD_EXECUTED=False QVD_WRITES=0'
 Write-Output 'P5_UI_FILTER_ENFORCEMENT=NOT_IMPLEMENTED'
 Write-Output 'PHYSICAL_INDICATORS_T24_T26=NOT_APPROVED'
 Write-Output ('TEMP_DIAGNOSTIC_DIR='+$dir)
 if($before -cne $after){$errorReason='SOURCE_CHANGED'}
}
if($null -ne $errorReason){Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$errorReason);exit 1}
Write-Output 'FINAL_VERDICT=PASS_COMPONENT_RECOVERY_WRAPPER_ONLY_P5_NOT_APPROVED'
