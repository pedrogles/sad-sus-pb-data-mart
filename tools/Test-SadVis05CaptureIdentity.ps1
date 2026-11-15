#requires -Version 5.1
<# Synthetic window identity checks only. Does not execute runner/COM or user32. #>
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunnerPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$tokens=$null;$parseErrors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($RunnerPath,[ref]$tokens,[ref]$parseErrors)
if(@($parseErrors).Count -gt 0){$parseErrors;throw 'Runner parser failed'}
$function=$ast.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Test-CaptureIdentity'},$true)
if($null -eq $function){throw 'Missing pure identity function'}
. ([ScriptBlock]::Create($function.Extent.Text))
$path='C:\Evidence\run-123\SAD_VIS05_INSPECTION_COPY.qvw'
$cases=@(
  @{name='exact_pid_and_full_path';process=111;expectedProcess=111;title="QlikView [$path]";path=$path;expected=$true},
  @{name='other_process_same_title';process=222;expectedProcess=111;title="QlikView [$path]";path=$path;expected=$false},
  @{name='same_process_other_run';process=111;expectedProcess=111;title='QlikView [C:\Evidence\run-456\SAD_VIS05_INSPECTION_COPY.qvw]';path=$path;expected=$false},
  @{name='empty_title';process=111;expectedProcess=111;title='';path=$path;expected=$false},
  @{name='zero_process';process=0;expectedProcess=0;title="QlikView [$path]";path=$path;expected=$false},
  @{name='empty_expected_path';process=111;expectedProcess=111;title="QlikView [$path]";path='';expected=$false},
  @{name='windows_path_case';process=111;expectedProcess=111;title=('QlikView ['+$path.ToLowerInvariant()+']');path=$path;expected=$true}
)
foreach($case in $cases){
  $actual=Test-CaptureIdentity ([uint32]$case.process) ([uint32]$case.expectedProcess) $case.title $case.path
  if($actual -ne $case.expected){throw ("IDENTITY_TEST_FAILED="+$case.name)}
}
Write-Output ('SYNTHETIC_CAPTURE_IDENTITY_TESTS_PASS='+$cases.Count)
Write-Output 'WINDOWS_FOCUS_AND_CAPTURE=NOT_EXECUTED'
