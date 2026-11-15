#requires -Version 5.1
<# Synthetic reset-verifier tests only; no runner body, QlikView or COM. #>
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunnerPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$tokens=$null;$parseErrors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($RunnerPath,[ref]$tokens,[ref]$parseErrors)
if(@($parseErrors).Count -gt 0){$parseErrors;throw 'Runner parser failed'}
$function=$ast.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Test-SelectionReset'},$true)
if($null -eq $function){throw 'Missing pure reset verifier'}
. ([ScriptBlock]::Create($function.Extent.Text))
$fields=@('PERIODO_ANO','PERIODO_COMPETENCIA','RES_COD_DATASUS_6','SERV_COD_DATASUS_6','MVP_FI_RES_SERV_CLASS')
$zero=@{};foreach($name in $fields){$zero[$name]='0'}
$residual=$zero.Clone();$residual['PERIODO_ANO']='1'
$missing=$zero.Clone();$missing.Remove('PERIODO_ANO')
$unreadable=$zero.Clone();$unreadable['PERIODO_ANO']='-'
$cases=@(
 @{name='empty_numeric_zero';summary='';records='0';counts=$zero;expected=$true},
 @{name='dash_independently_verified';summary='-';records='0';counts=$zero;expected=$true},
 @{name='dash_not_enough_residual_field';summary='-';records='0';counts=$residual;expected=$false},
 @{name='dash_not_enough_global_record';summary='-';records='1';counts=$zero;expected=$false},
 @{name='dash_not_enough_unreadable_record_count';summary='-';records='-';counts=$zero;expected=$false},
 @{name='missing_field_not_zero';summary='-';records='0';counts=$missing;expected=$false},
 @{name='selection_text_not_empty';summary='PERIODO_ANO=2018';records='0';counts=$zero;expected=$false},
 @{name='unreadable_field_not_zero';summary='';records='0';counts=$unreadable;expected=$false}
)
foreach($case in $cases){
 $actual=Test-SelectionReset $case.summary $case.records $case.counts $fields
 if($actual -ne $case.expected){throw ('RESET_TEST_FAILED='+$case.name)}
}
Write-Output ('SYNTHETIC_SELECTION_RESET_TESTS_PASS='+$cases.Count)
Write-Output 'QLIKVIEW_SELECTION_RESET=NOT_EXECUTED'
