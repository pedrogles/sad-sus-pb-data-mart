#requires -Version 5.1
<#
  SAD M3 / QlikView Desktop 12 isolated COM property probe.
  Tests ONLY the zero-based expression property access for a straight table.
  Creates synthetic 1-row QVW in external evidence dir, never reads SIH/LT/IBGE
  or changes a canonical QVD/QVW. Not a physical MVP/visual acceptance gate.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ExpectedCommit,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][switch]$Probe
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not $Probe){throw 'Explicit -Probe required'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows QlikView Desktop required'}
if($ExpectedCommit -notmatch '^[a-fA-F0-9]{40}$'){throw 'ExpectedCommit must be a full Git SHA'}
function Full([string]$p){return [IO.Path]::GetFullPath($p).TrimEnd([char[]]@('\','/'))}
function Under([string]$child,[string]$parent){
  return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
    $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
$repo=Full $Root
$evidence=Full $EvidenceRoot
if((Under $evidence $repo) -or (Under $repo $evidence) -or
  (Under $evidence (Full ([IO.Path]::GetTempPath())))){throw 'EvidenceRoot cannot be repo or TEMP'}
if(-not(Test-Path -LiteralPath $evidence -PathType Container)){throw 'EvidenceRoot must exist'}
$self='tools/Test-SadM3NoTotalsComProbe.ps1'
if(-not(Test-Path -LiteralPath (Join-Path $repo $self) -PathType Leaf)){throw 'Probe not found in repo'}
$head=(& git -C $repo rev-parse HEAD 2>$null | Out-String).Trim()
$branch=(& git -C $repo branch --show-current 2>$null | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $branch -cne 'proposal/sad-mvp-rebaseline-2026-11-07' -or
  $head -cne $ExpectedCommit.ToLowerInvariant()){throw 'Wrong branch or commit'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $self 2>$null)
$dirty=@(& git -C $repo status --porcelain --untracked-files=no 2>$null)
if($tracked.Count -ne 1 -or $dirty.Count -ne 0){throw 'Tracked probe or working tree is dirty'}
$run=Join-Path $evidence ('SAD_M3_TOTAL_COM_PROBE_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $run -ErrorAction Stop
$testQvw=Join-Path $run 'M3_TOTAL_ONLY_SYNTHETIC.qvw'
Write-Output "EVIDENCE_DIR=$run"
Write-Output "HEAD=$head"
Write-Output ('SCRIPT_SHA256='+(Get-FileHash -LiteralPath (Join-Path $repo $self) -Algorithm SHA256).Hash)
Write-Output 'DATASET=SYNTHETIC_ONE_ROW_NO_SUS_QVDS'
$app=$null
$doc=$null
$stage='CREATE_SYNTHETIC_DOC'
try{
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$app.CreateDoc()
  if($null -eq $doc){throw 'CreateDoc failed'}
  $null=$doc.SaveAs($testQvw)
  $props=$doc.GetProperties()
  $props.Script="M3_COM_PROBE: LOAD * INLINE [DIM, VAL`nA, 1];"
  $null=$doc.SetProperties($props)
  $stage='RELOAD_SYNTHETIC_SINGLE_ROW'
  $null=$doc.Reload()
  $stage='CREATE_SYNTHETIC_STRAIGHT'
  $sheet=$doc.GetSheet(0)
  if($null -eq $sheet){throw 'No initial sheet'}
  $table=$sheet.CreateStraightTable()
  if($null -eq $table){throw 'CreateStraightTable failed'}
  $null=$table.AddDimension('DIM')
  $null=$table.AddExpression('Sum(VAL)')
  $stage='READ_FIRST_EXPRESSION_INDEX_ZERO'
  $cp=$table.GetProperties()
  $expressionData=$cp.Expressions.Item(0).Item(0).Data.ExpressionData
  if($null -eq $expressionData){throw 'ExpressionData missing at index 0'}
  $stage='SET_AND_READBACK_NO_TOTALS'
  $expressionData.UsePartialSum=$false
  $null=$table.SetProperties($cp)
  $readback=$table.GetProperties().Expressions.Item(0).Item(0).Data.ExpressionData
  if($null -eq $readback){throw 'Readback expression missing at index 0'}
  if([bool]$readback.UsePartialSum){throw 'UsePartialSum remains enabled after SetProperties'}
  $null=$doc.Save()
  Write-Output 'M3_COM_EXPRESSION_INDEX=0'
  Write-Output 'M3_COM_NO_TOTALS_PROPERTY_READBACK=False'
  Write-Output 'M3_COM_PROBE=PASS_SYNTHETIC_LOCAL_ONLY'
  Write-Output "PROBE_QVW=$testQvw"
}catch{
  Write-Output "M3_COM_FAILED_STAGE=$stage"
  Write-Output "M3_COM_FAILED_LINE=$($_.InvocationInfo.ScriptLineNumber)"
  Write-Output "M3_COM_PROBE=BLOCKED $($_.Exception.Message)"
  throw
}finally{
  if($null -ne $doc){
    try{$null=$doc.CloseDoc()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}
  }
  if($null -ne $app){
    try{$app.Quit()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}
  }
}
