#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$VerifierPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$t=$null;$e=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($VerifierPath,[ref]$t,[ref]$e)
if(@($e).Count){throw 'Verifier parser failed'}
foreach($name in @('Get-SadSha','Get-SadFileComparison')){
  $fn=$ast.Find({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$true)
  if($null -eq $fn){throw 'Missing read-only comparison function'}
  . ([scriptblock]::Create($fn.Extent.Text))
}
if($ast.Extent.Text -match 'New-Object -ComObject|OpenDoc\(|Reload\(|SaveAs\(|CloseDoc\(|Stop-Process|Remove-Item'){throw 'Unexpected application/mutation operation'}
$dir=Join-Path ([IO.Path]::GetTempPath()) ('sad-closeout-fixture-'+[guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $dir
try{
  $path=Join-Path $dir 'fixture.bin'
  [IO.File]::WriteAllBytes($path,[byte[]]@(1,2,3))
  $expected=[pscustomobject]@{path=$path;sha256=(Get-SadSha $path);bytes=3}
  if(-not (Get-SadFileComparison $expected).matches){throw 'Identical fixture rejected'}
  [IO.File]::WriteAllBytes($path,[byte[]]@(3,2,1))
  if((Get-SadFileComparison $expected).matches){throw 'Same-size changed fixture accepted'}
  [IO.File]::WriteAllBytes($path,[byte[]]@(1,2,3,4))
  if((Get-SadFileComparison $expected).matches){throw 'Changed-size fixture accepted'}
  $missing=[pscustomobject]@{path=(Join-Path $dir 'missing.bin');sha256=$expected.sha256;bytes=3}
  $rejected=$false
  try{$null=Get-SadFileComparison $missing}catch{$rejected=$true}
  if(-not $rejected){throw 'Missing file accepted'}
  Write-Output 'POST_INTERRUPTION_PARSER_STATIC_AND_FILE_COMPARISON_TESTS=PASS (4 fixtures)'
  Write-Output 'REAL_26_FILES_WINDOWS_PROCESS_AND_COPY_CHECKS=NOT_RUN'
}finally{Remove-Item -LiteralPath $dir -Recurse -Force}
