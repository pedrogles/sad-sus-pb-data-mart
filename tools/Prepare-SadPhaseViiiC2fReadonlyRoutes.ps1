# C2-F: prepare one immutable source QVW for manual/visual READ-ONLY route inventory.
# NO COM, UIA, Win32 probe, input events, selections, Reload, Save, STORE or QVD mutations.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$SourceQvw,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [switch]$Prepare
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not [Environment]::OSVersion.Platform.ToString().Equals('Win32NT')){throw 'BLOCKED_WINDOWS_REQUIRED'}
$repo=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')
$source=[IO.Path]::GetFullPath($SourceQvw)
$evidence=[IO.Path]::GetFullPath($EvidenceRoot).TrimEnd('\','/')
$rel='tools/Prepare-SadPhaseViiiC2fReadonlyRoutes.ps1'
$expectedBranch='test/phase-viii-c2f-readonly-route-inventory-20261021'
$expectedBase='9dbdef8e3f20b076cc1a07d0c273a981b3ac45e1'
$expectedSourceSha='31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087'
$self=Join-Path $repo $rel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'BLOCKED_RUNNER_NOT_AT_VERSIONED_PATH'}
$branch=[string](& git -C $repo branch --show-current)
$head=[string](& git -C $repo rev-parse HEAD)
if($LASTEXITCODE -ne 0 -or $branch -cne $expectedBranch -or $head -notmatch '^[0-9a-f]{40}$'){throw 'BLOCKED_WRONG_BRANCH_OR_HEAD'}
& git -C $repo merge-base --is-ancestor $expectedBase HEAD
if($LASTEXITCODE -ne 0){throw 'BLOCKED_UNEXPECTED_GIT_BASE'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $rel)
if($tracked.Count -ne 1 -or $dirty.Count -ne 0){throw 'BLOCKED_RUNNER_NOT_COMMITTED_CLEAN'}
if(-not(Test-Path -LiteralPath $source -PathType Leaf)){throw 'BLOCKED_C2D1_SOURCE_QVW_NOT_FOUND'}
if([IO.Path]::GetFileName($source) -cne 'SAD_C2D1_D2_BUTTON_TEST.qvw'){throw 'BLOCKED_WRONG_SOURCE_QVW_NAME'}
$prefix=$repo+[IO.Path]::DirectorySeparatorChar
if($source.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'BLOCKED_SOURCE_INSIDE_REPOSITORY'}
if($evidence -ieq $repo -or $evidence.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)){throw 'BLOCKED_EVIDENCE_INSIDE_REPOSITORY'}
$sourceSha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('SOURCE_QVW_SHA256='+$sourceSha)
if($sourceSha -cne $expectedSourceSha){throw 'BLOCKED_SOURCE_QVW_SHA256_DIFFERS_FROM_C2D3_PIN'}
function Get-ProtectedSnapshot {
  $ext=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -Filter '*.qvd' -File)
  $trans=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -Filter '*.qvd' -File)
  if($ext.Count -ne 10 -or $trans.Count -ne 12){throw 'BLOCKED_EXPECTED_22_QVD'}
  $canon=@('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')
  $all=@($ext)+@($trans)
  foreach($p in $canon) {
    $fp=Join-Path $repo $p
    if(-not (Test-Path -LiteralPath $fp -PathType Leaf)){throw ('BLOCKED_CANONICAL_QVW_NOT_FOUND_'+$p)}
    $all+=@(Get-Item -LiteralPath $fp)
  }
  $r=@(foreach($f in $all){
    [pscustomobject]@{Path=$f.FullName;Length=$f.Length;SHA256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash}
  })
  return @($r|Sort-Object -Property Path)
}
$before=@(Get-ProtectedSnapshot)
$beforeJson=ConvertTo-Json -InputObject $before -Depth 5 -Compress
Write-Output 'PROTECTED_INVENTORY=PASS_22_QVD_3_CANONICAL_QVW'
Write-Output 'INPUT_EVENTS=0 QLIK_COM_CALLS=0 NO_RELOAD_NO_SAVE_NO_STORE=True'
if(-not $Prepare){
  Write-Output 'VERDICT=PREFLIGHT_ONLY_NO_QVW_COPY_NO_UI_INVENTORY'
  return
}
$opened=@(Get-Process -ErrorAction SilentlyContinue | Where-Object {
  $_.ProcessName -match '^(qv|qlikview)$' -and
  $_.MainWindowTitle -like '*SAD_C2D1_D2_BUTTON_TEST*'
})
if($opened.Count -gt 0){throw 'BLOCKED_CLOSE_SOURCE_QVW_BEFORE_COPY'}
$tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tag='SAD_VIII_C2F_'+[Guid]::NewGuid().ToString('N')
$work=Join-Path $tempRoot $tag
$evidenceDir=Join-Path $evidence $tag
$copy=Join-Path $work 'SAD_C2F_ROUTE_INVENTORY_COPY.qvw'
$problem=''
try {
  $null=New-Item -ItemType Directory -Path $work -ErrorAction Stop
  $null=New-Item -ItemType Directory -Path $evidenceDir -Force -ErrorAction Stop
  Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
  $copySha=(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
  if($copySha -cne $sourceSha){throw 'BLOCKED_COPY_HASH_MISMATCH'}
  $manifest=[ordered]@{
    Gate='C2-F';Mode='READ_ONLY_PREPARATION_NO_COM'
    VersionedGitHead=$head
    ScriptSha256=(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash
    SourceQvw=$source;SourceQvwSha256=$sourceSha
    TempCopy=$copy;TempCopySha256=$copySha
    ProtectedFiles=$before
    UIInventory='NOT_EXECUTED'
    P5D2UI='NOT_TESTED';C2Full='NO_GO_NOT_APPROVED';ProductionApproved=$false
  }
  $manifest|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $evidenceDir 'c2f_prepare_manifest.json') -Encoding UTF8
} catch {$problem=$_.Exception.Message}
finally {
  $after=@(Get-ProtectedSnapshot)
  $afterJson=ConvertTo-Json -InputObject $after -Depth 5 -Compress
  $afterSourceSha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
  $integrity=($beforeJson -ceq $afterJson -and $sourceSha -ceq $afterSourceSha)
  Write-Output ('ORIGINAL_22_QVD_3_CANONICAL_QVW_AND_SOURCE_SHA256_UNCHANGED='+$integrity)
  if(-not $integrity){throw 'HARD_STOP_PROTECTED_OR_SOURCE_HASH_DRIFT'}
}
if($problem -ne ''){throw ('BLOCKED_PREPARE_'+$problem)}
Write-Output ('RUNTIME_TEMP_COPY='+$copy)
Write-Output ('EVIDENCE_ROOT='+$evidenceDir)
Write-Output 'VERDICT=PASS_LOCAL_PREPARATION_ONLY_NOT_C2F_PHYSICAL_INVENTORY'
Write-Output 'NEXT=MANUAL_READ_ONLY_OBJECT_PROPERTIES_AND_SCREENSHOTS_ON_TEMP_COPY_ONLY'
Write-Output 'C2_FULL=NO_GO_NOT_APPROVED P5_D2_UI=NOT_TESTED PRODUCTION_APPROVED=False'
