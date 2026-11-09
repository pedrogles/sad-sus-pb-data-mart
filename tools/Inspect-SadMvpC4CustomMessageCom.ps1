#requires -Version 5.1
<#
Read-only, one-shot inspection of QlikView 12 classic COM chart property names.
Goal: locate the *property path* (not guess it) for CH09's customized
"Calculation condition unfulfilled" message in an operator-tested QVW TEMP.
No Save, Reload, selections, QVS/QVD writes, or QVW modifications.
Output is member-name metadata only, not hospital data or chart values.
This is a diagnostic, NOT a C4 functional or production acceptance.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$SourceQvw,
  [Parameter(Mandatory=$true)][switch]$Inspect
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not $Inspect){throw 'Explicit -Inspect required for read-only COM diagnosis'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows required'}
$repo=[IO.Path]::GetFullPath($Root)
$qvw=[IO.Path]::GetFullPath($SourceQvw)
if(-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)){throw 'Not the SAD repository'}
if((git -C $repo branch --show-current).Trim() -cne 'proposal/sad-mvp-rebaseline-2026-11-07'){
  throw 'STOP: MVP branch required'
}
if(@(git -C $repo status --porcelain --untracked-files=all).Count -gt 0){
  throw 'STOP: Git working tree is dirty'
}
if(Get-Process qv -ErrorAction SilentlyContinue){throw 'STOP: close QlikView first'}
if(-not (Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'STOP: TEMP QVW missing'}
if($qvw.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){
  throw 'STOP: QVW inside repository, refuse to inspect'
}
if((Split-Path $qvw -Leaf) -cne 'SAD_MVP_C4_PRESENTATION_TEMP.qvw'){
  throw 'STOP: only the already saved C4 presentation TEMP is accepted'
}
$expected='27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13'
$before=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
if($before -cne $expected){throw 'STOP: source QVW differs from tested C4 SHA-256'}

function MemberNames($item){
  if($null -eq $item){return @()}
  try{
    return @($item | Get-Member -MemberType Property,NoteProperty -ErrorAction Stop |
      Select-Object -ExpandProperty Name)
  }catch{return @()}
}
function Child($obj,[string]$name){
  try{return $obj.PSObject.Properties[$name].Value}
  catch{return $null}
}
$app=$null
$doc=$null
try{
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$app.OpenDoc($qvw)
  if($null -eq $doc){throw 'COM OpenDoc failed'}
  # GetSheetObject('CH09') can return null for a valid chart. Enumerate sheet
  # objects directly instead (QlikView classic COM: GetSheet/ GetSheetObjects).
  # No Activate, no changes to selections, no Save/Reload.
  $chart=$null
  $hits=New-Object System.Collections.Generic.List[object]
  $ids=New-Object System.Collections.Generic.List[string]
  $sheetCount=[int]$doc.NoOfSheets()
  if($sheetCount -ne 3){throw "STOP: expected 3 MVP sheets; found $sheetCount"}
  for($sheetIndex=0;$sheetIndex -lt $sheetCount;$sheetIndex++){
    $sheet=$doc.GetSheet($sheetIndex)
    if($null -eq $sheet){throw "STOP: GetSheet($sheetIndex) returned null"}
    $sheetObjects=@($sheet.GetSheetObjects())
    foreach($obj in $sheetObjects){
      if($null -eq $obj){continue}
      $objId=[string]$obj.GetObjectID()
      [void]$ids.Add($objId)
      # Classic COM exposes namespaced IDs (e.g. Document\CH09).
      # Match only CH09, optionally with its known Document prefix.
      if($objId -cmatch '^(?:Document\\)?CH09
    }
  }
  Write-Output "C4_SHEET_COUNT=$sheetCount"
  Write-Output ('C4_DISCOVERED_OBJECT_IDS='+($ids -join ','))
  if($hits.Count -ne 1){
    throw "STOP: CH09 enumeration count $($hits.Count); expected exactly one; no properties inspected"
  }
  $chart=$hits[0]
  $p=$chart.GetProperties()
  if($null -eq $p){throw 'CH09 GetProperties failed'}
  Write-Output 'GATE=C4_MVP_CH09_CUSTOM_MESSAGE_COM_METADATA_ONLY'
  Write-Output "SOURCE_SHA256=$before"
  Write-Output "GIT_HEAD=$((git -C $repo rev-parse HEAD).Trim())"
  Write-Output ('CH09_EVALUATION_CONDITION='+[string]$p.EvaluationCondition.v)
  $names=@(MemberNames $p | Sort-Object -Unique)
  Write-Output ('CH09_PROPERTY_NAMES='+($names -join ','))
  $roots=@($names | Where-Object {$_ -match '(?i)error|message|evalu|condition|chart|graph|layout|custom'})
  foreach($name in $roots){
    $node=Child $p $name
    if($null -eq $node){continue}
    $nested=@(MemberNames $node | Sort-Object -Unique)
    Write-Output ("PROPERTY_BRANCH=$name CHILD_MEMBERS="+($nested -join ','))
    foreach($childName in @($nested | Where-Object {$_ -match '(?i)error|message|condition|custom'})){
      $grandChild=Child $node $childName
      if($null -ne $grandChild){
        Write-Output ("PROPERTY_BRANCH=$name.$childName GRANDCHILD_MEMBERS="+((MemberNames $grandChild) -join ','))
      }
    }
  }
  Write-Output 'VERDICT=COM_METADATA_ONLY_NO_CUSTOM_MESSAGE_WRITE'
}
finally{
  if($null -ne $doc){
    try{$null=$doc.CloseDoc()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}
  }
  if($null -ne $app){
    try{$app.Quit()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}
  }
  $after=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
  Write-Output "SOURCE_UNCHANGED=$($after -ceq $before)"
  if($after -cne $before){throw 'STOP: QVW integrity changed; preserve and investigate'}
}
){[void]$hits.Add($obj)}
    }
  }
  Write-Output "C4_SHEET_COUNT=$sheetCount"
  Write-Output ('C4_DISCOVERED_OBJECT_IDS='+($ids -join ','))
  if($hits.Count -ne 1){
    throw "STOP: CH09 enumeration count $($hits.Count); expected exactly one; no properties inspected"
  }
  $chart=$hits[0]
  $p=$chart.GetProperties()
  if($null -eq $p){throw 'CH09 GetProperties failed'}
  Write-Output 'GATE=C4_MVP_CH09_CUSTOM_MESSAGE_COM_METADATA_ONLY'
  Write-Output "SOURCE_SHA256=$before"
  Write-Output "GIT_HEAD=$((git -C $repo rev-parse HEAD).Trim())"
  Write-Output ('CH09_EVALUATION_CONDITION='+[string]$p.EvaluationCondition.v)
  $names=@(MemberNames $p | Sort-Object -Unique)
  Write-Output ('CH09_PROPERTY_NAMES='+($names -join ','))
  $roots=@($names | Where-Object {$_ -match '(?i)error|message|evalu|condition|chart|graph|layout|custom'})
  foreach($name in $roots){
    $node=Child $p $name
    if($null -eq $node){continue}
    $nested=@(MemberNames $node | Sort-Object -Unique)
    Write-Output ("PROPERTY_BRANCH=$name CHILD_MEMBERS="+($nested -join ','))
    foreach($childName in @($nested | Where-Object {$_ -match '(?i)error|message|condition|custom'})){
      $grandChild=Child $node $childName
      if($null -ne $grandChild){
        Write-Output ("PROPERTY_BRANCH=$name.$childName GRANDCHILD_MEMBERS="+((MemberNames $grandChild) -join ','))
      }
    }
  }
  Write-Output 'VERDICT=COM_METADATA_ONLY_NO_CUSTOM_MESSAGE_WRITE'
}
finally{
  if($null -ne $doc){
    try{$null=$doc.CloseDoc()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}
  }
  if($null -ne $app){
    try{$app.Quit()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}
  }
  $after=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
  Write-Output "SOURCE_UNCHANGED=$($after -ceq $before)"
  if($after -cne $before){throw 'STOP: QVW integrity changed; preserve and investigate'}
}
