#requires -Version 5.1
<# Pure geometry boundary tests; no COM, Windows DLL calls or runner body. #>
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunnerPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$tokens=$null;$errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($RunnerPath,[ref]$tokens,[ref]$errors)
if(@($errors).Count -gt 0){$errors;throw 'Runner parser failed'}
$function=$ast.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Test-CaptureGeometry'},$true)
if($null -eq $function){throw 'Missing geometry function'}
. ([ScriptBlock]::Create($function.Extent.Text))
$desktop=@{left=0;top=0;width=1920;height=1080}
$cases=@(
 @{name='exact_minimum';window=@{left=0;top=0;width=700;height=500};desktop=$desktop;minimized=$false;reasons=@()},
 @{name='exact_screen';window=@{left=0;top=0;width=1920;height=1080};desktop=$desktop;minimized=$false;reasons=@()},
 @{name='width';window=@{left=0;top=0;width=699;height=500};desktop=$desktop;minimized=$false;reasons=@('WIDTH_BELOW_700')},
 @{name='height';window=@{left=0;top=0;width=700;height=499};desktop=$desktop;minimized=$false;reasons=@('HEIGHT_BELOW_500')},
 @{name='negative_border';window=@{left=-8;top=-8;width=1936;height=1096};desktop=$desktop;minimized=$false;reasons=@('OUTSIDE_VIRTUAL_SCREEN')},
 @{name='right_overflow';window=@{left=1221;top=0;width=700;height=500};desktop=$desktop;minimized=$false;reasons=@('OUTSIDE_VIRTUAL_SCREEN')},
 @{name='negative_monitor_valid';window=@{left=-1920;top=0;width=1920;height=1080};desktop=@{left=-1920;top=0;width=3840;height=1080};minimized=$false;reasons=@()},
 @{name='minimized';window=@{left=0;top=0;width=700;height=500};desktop=$desktop;minimized=$true;reasons=@('MINIMIZED')}
)
foreach($case in $cases){
 $actual=Test-CaptureGeometry $case.window $case.desktop $case.minimized
 if($actual.eligible -ne ($case.reasons.Count -eq 0) -or ($actual.reasons -join '|') -cne ($case.reasons -join '|')){throw ('GEOMETRY_TEST_FAILED='+$case.name)}
}
# Verify that the diagnostic branch has no selection/probe call and the scenario
# result is appended before CaptureSheet, so a geometry error cannot erase it.
$source=$ast.Extent.Text
$diagnosticStart=$source.IndexOf("if(`$Mode -ceq 'WindowDiagnostic'){")
$diagnosticEnd=$source.IndexOf('}else{',$diagnosticStart)
if($diagnosticStart -lt 0 -or $diagnosticEnd -lt 0){throw 'Diagnostic branch not found'}
$diagnostic=$source.Substring($diagnosticStart,$diagnosticEnd-$diagnosticStart)
if($diagnostic -match 'SelectState|EngineProbes|ClearAll|\.Select\('){throw 'Diagnostic must not select or run probes'}
$checkpoint=$source.IndexOf('$results.Add($item);$report.scenarios=')
$capture=$source.IndexOf('if($Capture){foreach($index', $checkpoint)
if($checkpoint -lt 0 -or $capture -le $checkpoint){throw 'Scenario checkpoint must precede capture'}
Write-Output ('SYNTHETIC_WINDOW_GEOMETRY_TESTS_PASS='+$cases.Count)
Write-Output 'DIAGNOSTIC_BRANCH_AND_CHECKPOINT_STATIC_CHECKS=PASS'
Write-Output 'WINDOWS_GEOMETRY_AND_CAPTURE=NOT_EXECUTED'
