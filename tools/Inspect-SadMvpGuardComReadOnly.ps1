#requires -Version 5.1
<#
 SAD MVP F03/F04 COM property discovery, read-only and pinned to validated TEMP QVW.
 This does not apply guards or test the builder.
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
if(-not $Probe){throw 'Explicit -Probe switch required'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows/QlikView Desktop 12 required'}
if($ExpectedCommit -notmatch '^[0-9a-fA-F]{40}$'){throw 'ExpectedCommit must be 40 hex characters'}
function Full([string]$p){return [IO.Path]::GetFullPath($p).TrimEnd([char[]]@('\','/'))}
function Under([string]$child,[string]$parent){
  return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
    $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
$repo=Full $Root
$evidence=Full $EvidenceRoot
if((Under $evidence $repo) -or (Under $repo $evidence) -or
   (Under $evidence (Full ([IO.Path]::GetTempPath())))){
  throw 'EvidenceRoot must be outside repo and Windows TEMP'
}
if(-not(Test-Path -LiteralPath $repo -PathType Container)){throw 'Repository root missing'}
if(-not(Test-Path -LiteralPath $evidence -PathType Container)){throw 'EvidenceRoot missing'}
$branch=(& git -C $repo branch --show-current 2>$null | Out-String).Trim()
$head=(& git -C $repo rev-parse HEAD 2>$null | Out-String).Trim()
if($LASTEXITCODE -ne 0 -or $branch -cne 'proposal/sad-mvp-rebaseline-2026-11-07' -or
   $head -cne $ExpectedCommit.ToLowerInvariant()){throw 'Wrong branch or HEAD'}
$dirty=@(& git -C $repo status --porcelain 2>$null)
if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw 'Working tree must be clean'}
$contractRel='PAINEL/sad_mvp_native_guard_contract.json'
$scriptRel='tools/Inspect-SadMvpGuardComReadOnly.ps1'
foreach($rel in @($contractRel,$scriptRel)){
  if(-not(Test-Path -LiteralPath (Join-Path $repo $rel) -PathType Leaf)){throw "Missing $rel"}
  $tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
  if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1){throw "Untracked file: $rel"}
}
$contractPath=Join-Path $repo $contractRel
$contract=([IO.File]::ReadAllText($contractPath,[Text.Encoding]::UTF8) | ConvertFrom-Json)
if([int]$contract.version -ne 1 -or
   [string]$contract.status -cne 'DRAFT_COM_MAPPING_UNVERIFIED' -or
   @($contract.objects).Count -ne 2){throw 'Unexpected guard manifest version/scope'}
if([string]$contract.objects[0].objectId -cne 'CH04' -or
   [string]$contract.objects[1].objectId -cne 'CH05'){throw 'Unexpected chart IDs'}
$qvw=Join-Path $evidence 'SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1\SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw'
if(-not(Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'Exact F04 TEMP source missing'}
$pinnedSha='4AF2C4BE17336AB729CF0CD70D75B7481B41AC003958EDB543584A1484047F92'
$before=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
if($before -cne $pinnedSha){throw 'Pinned source SHA mismatch: STOP before opening'}
$running=@(Get-Process -Name 'Qv','QlikView','QlikViewDesktop' -ErrorAction SilentlyContinue)
if($running.Count -gt 0){throw 'Close QlikView Desktop before read-only COM inspection'}
Write-Output "GIT_HEAD=$head"
Write-Output "CONTRACT_SHA256=$((Get-FileHash -LiteralPath $contractPath -Algorithm SHA256).Hash)"
Write-Output "SOURCE_QVW_SHA256=$before"
Write-Output 'NO_QVD_ACCESS=True NO_RELOAD=True NO_SETPROPERTIES=True NO_SAVE=True'
function Members([object]$obj,[string]$label){
  if($null -eq $obj){Write-Output "MEMBERS_$($label)=NULL";return}
  $names=@()
  try{
    $names=@(Get-Member -InputObject $obj -MemberType Property -ErrorAction Stop |
      Select-Object -ExpandProperty Name | Sort-Object -Unique)
  }catch{Write-Output "MEMBERS_$($label)=UNAVAILABLE";return}
  $relevant=@($names | Where-Object {$_ -match '(?i)calc|cond|error|message|graph|layout|title|frame|show|text|def|expr'})
  Write-Output "MEMBERS_$($label)_COUNT=$($names.Count)"
  Write-Output "MEMBERS_$($label)_RELEVANT=$($relevant -join '|')"
}
function ReadPath([object]$obj,[string]$path){
  $value=$obj
  foreach($part in ($path -split '\.')){
    if($null -eq $value){return $null}
    try{$value=$value.$part}catch{return $null}
  }
  return ,$value
}
$paths=@(
 'GraphLayout.WindowTitle.v','GraphLayout.CalcCondition.v',
 'GraphLayout.CalculationCondition.v','GraphLayout.CalcCond.v',
 'GraphLayout.CalcCondition','GraphLayout.CalculationCondition',
 'GraphLayout.CalcCond','GraphLayout.ErrorMessages',
 'GraphLayout.CustomErrorMessages','GraphLayout.ErrorMessage',
 'GraphLayout.CalculationConditionErrorMessage','GraphLayout.CalcCondErrorMsg',
 'CalcCondition.v','CalculationCondition.v','CalcCond.v',
 'ErrorMessages','CustomErrorMessages','CalcCondition',
 'CalculationCondition','CalcCond'
)
$app=$null
$doc=$null
$failure=$null
try{
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$app.OpenDoc($qvw)
  if($null -eq $doc){throw 'OpenDoc returned null'}
  if([int]$doc.NoOfSheets() -ne 3){throw 'Expected three sheets in TEMP source'}
  foreach($spec in @($contract.objects)){
    $id=[string]$spec.objectId
    $chart=$doc.GetSheetObject($id)
    if($null -eq $chart){throw "GetSheetObject failed for $id"}
    $props=$chart.GetProperties()
    if($null -eq $props){throw "GetProperties failed for $id"}
    $title=[string]$props.GraphLayout.WindowTitle.v
    if($title -cne [string]$spec.title){throw "Unexpected chart title for $id"}
    Write-Output "CHART=$id VIEW=$($spec.viewId) TITLE_MATCH=True"
    Members $props "$($id)_PROPERTIES"
    Members $props.GraphLayout "$($id)_GRAPHLAYOUT"
    foreach($path in $paths){
      $value=ReadPath $props $path
      if($null -eq $value){continue}
      if($value -is [string] -or $value -is [ValueType]){
        $display=[string]$value
        if($display.Length -gt 1800){$display=$display.Substring(0,1800)+'[TRUNCATED]'}
        $display=$display.Replace([char]13,' ').Replace([char]10,' ')
        Write-Output "COM_PATH_CHART=$id PATH=$path TYPE=SCALAR VALUE=$display"
      } else {
        Write-Output "COM_PATH_CHART=$id PATH=$path TYPE=$($value.GetType().FullName)"
        Members $value "$($id)_$($path.Replace('.','_'))"
      }
    }
  }
  # Targeted F05/R1B readback. R1 surfaced EvaluationCondition and
  # GraphLayout.ErrorMessageOverrides, so inspect only those two members.
  # This reads no chart data and never invokes a setter.
  function ShowTargetValue([object]$value,[string]$label,[int]$depth){
    if($null -eq $value){
      Write-Output "TARGET_$($label)=NULL"
      return
    }
    if($value -is [string] -or $value -is [ValueType]){
      $v=[string]$value
      $v=$v.Replace([char]13,' ').Replace([char]10,' ')
      if($v.Length -gt 2400){$v=$v.Substring(0,2400)+'[TRUNCATED]'}
      Write-Output "TARGET_$($label)_VALUE=$v"
      return
    }
    Write-Output "TARGET_$($label)_TYPE=$($value.GetType().FullName)"
    $propertyNames=@()
    $methodNames=@()
    try{
      $propertyNames=@(Get-Member -InputObject $value -MemberType Property -ErrorAction Stop |
        Select-Object -ExpandProperty Name | Sort-Object -Unique)
      $methodNames=@(Get-Member -InputObject $value -MemberType Method -ErrorAction Stop |
        Select-Object -ExpandProperty Name | Sort-Object -Unique)
    }catch{
      Write-Output "TARGET_$($label)_MEMBERS_UNAVAILABLE=True"
      return
    }
    Write-Output "TARGET_$($label)_PROPERTIES=$($propertyNames -join '|')"
    Write-Output "TARGET_$($label)_METHODS=$(@($methodNames | Where-Object {$_ -match '^(Item|GetItem|Count|GetCount)
}catch{
  $failure=$_.Exception.Message
  Write-Output "COM_MAPPING_PROBE=BLOCKED_OR_INCONCLUSIVE $failure"
}finally{
  if($null -ne $doc){
    try{$null=$doc.CloseDoc()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}
  }
  if($null -ne $app){
    try{$null=$app.Quit()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}
  }
  $after=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
  if($before -cne $after){throw 'CRITICAL_SOURCE_QVW_SHA_CHANGED: STOP'}
  Write-Output 'SOURCE_TEMP_QVW_SHA256_UNCHANGED=True'
}
if($null -ne $failure){throw "COM_MAPPING_STOP: $failure"}
}) -join '|')"
    if($depth -ge 2){return}
    $allowed=@('v','text','Text','Value','Expression','ExpressionData','Enabled',
               'Count','Condition','ErrorCode','ErrorId','ErrorMessage','Message','Default')
    foreach($name in $allowed){
      if(-not ($propertyNames -ccontains $name)){continue}
      try{
        $child=$value.$name
        ShowTargetValue $child "$($label)_$name" ($depth+1)
      }catch{
        Write-Output "TARGET_$($label)_$($name)_READ=UNAVAILABLE"
      }
    }
    # Collections are accessed only when an exposed Count and Item exist.
    if(($propertyNames -contains 'Count') -and ($methodNames -contains 'Item')){
      $n=0
      try{$n=[int]$value.Count}catch{}
      if($n -ge 0 -and $n -le 24){
        Write-Output "TARGET_$($label)_ITEM_COUNT=$n"
        for($j=0;$j -lt $n;$j++){
          try{
            $child=$value.Item($j)
            ShowTargetValue $child "$($label)_ITEM_$j" ($depth+1)
          }catch{
            Write-Output "TARGET_$($label)_ITEM_$($j)_READ=UNAVAILABLE"
          }
        }
      }else{
        Write-Output "TARGET_$($label)_ITEM_COUNT_OUTSIDE_LIMIT=$n"
      }
    }
  }
  foreach($spec in @($contract.objects)){
    $id=[string]$spec.objectId
    $chart=$doc.GetSheetObject($id)
    if($null -eq $chart){throw "Target chart missing for $id"}
    $properties=$chart.GetProperties()
    if($null -eq $properties){throw "Target GetProperties failed for $id"}
    ShowTargetValue $properties.EvaluationCondition "$($id)_EVALUATIONCONDITION" 0
    ShowTargetValue $properties.GraphLayout.ErrorMessageOverrides "$($id)_ERRORMESSAGEOVERRIDES" 0
  }
  Write-Output 'TARGETED_MAPPING_VERDICT=READ_ONLY_EXAMINED_AWAITING_MANUAL_RECONCILIATION'
  Write-Output 'COM_MAPPING_PROBE=INSPECTED_READ_ONLY_NOT_IMPLEMENTED'
}catch{
  $failure=$_.Exception.Message
  Write-Output "COM_MAPPING_PROBE=BLOCKED_OR_INCONCLUSIVE $failure"
}finally{
  if($null -ne $doc){
    try{$null=$doc.CloseDoc()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}
  }
  if($null -ne $app){
    try{$null=$app.Quit()}catch{}
    try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}
  }
  $after=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
  if($before -cne $after){throw 'CRITICAL_SOURCE_QVW_SHA_CHANGED: STOP'}
  Write-Output 'SOURCE_TEMP_QVW_SHA256_UNCHANGED=True'
}
if($null -ne $failure){throw "COM_MAPPING_STOP: $failure"}
