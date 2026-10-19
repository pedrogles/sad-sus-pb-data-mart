# C2-D1: stage a single disposable QVW for manual four-case D2 button-route proof.
# This script NEVER opens QlikView through COM; never reloads or writes QVDs.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Root,[switch]$Prepare)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$rel='tools/Prepare-SadPhaseViiiC2d1D2ButtonRoute.ps1'
$branch='test/phase-viii-c2d1-d2-button-route-20261019'
$self=Join-Path $repo $rel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'BLOCKED_SCRIPT_NOT_CANONICAL_PATH'}
$actualBranch=(& git -C $repo branch --show-current)
$head=(& git -C $repo rev-parse HEAD)
if($LASTEXITCODE -ne 0 -or $actualBranch -cne $branch -or $head -notmatch '^[0-9a-f]{40}$'){throw 'BLOCKED_GIT_BRANCH_OR_HEAD'}
& git -C $repo merge-base --is-ancestor '337943d5c5b77067f842902fc679dbb68db87020' HEAD
if($LASTEXITCODE -ne 0){throw 'BLOCKED_MAIN_BASE_NOT_ANCESTOR'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
$dirty=@(& git -C $repo status --porcelain -- $rel)
if($tracked.Count -ne 1 -or $dirty.Count -gt 0){throw 'BLOCKED_SCRIPT_NOT_COMMITTED_AND_CLEAN'}
$tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
$sourcePath=Join-Path $tempRoot 'SAD_VIII_C2W_04f58b85152b4794b0bf4809b4e10f3c\SAD_C2W_T26_COLUNAS_AJUSTADAS_WRAP.qvw'
if(-not(Test-Path -LiteralPath $sourcePath -PathType Leaf)){throw 'BLOCKED_SOURCE_WRAP_QVW_NOT_FOUND'}
$open=@(Get-Process | Where-Object {
  $_.ProcessName -match '^(qv|qlikview)$' -and
  $_.MainWindowTitle -like '*SAD_C2W_T26_COLUNAS_AJUSTADAS_WRAP*'
})
if($open.Count -gt 0){throw 'BLOCKED_CLOSE_ORIGINAL_WRAP_QVW_BEFORE_COPY'}
function GetSnapshot([string]$kind){
  $items=@()
  if($kind -ceq 'QVD'){
    $a=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -File -Filter '*.qvd')
    $b=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -File -Filter '*.qvd')
    if($a.Count -ne 10 -or $b.Count -ne 12){throw 'BLOCKED_EXPECTED_10_PLUS_12_QVDS'}
    $items=@($a)+@($b)
  }else{
    foreach($sub in @('EXTRACAO','TRANSFORMACAO','PAINEL')){
      $dir=Join-Path $repo $sub
      if(Test-Path -LiteralPath $dir -PathType Container){
        $items+=@(Get-ChildItem -LiteralPath $dir -File -Filter '*.qvw')
      }
    }
  }
  $result=@()
  foreach($f in $items){
    $result+=('{0}|{1}|{2}' -f $f.FullName,$f.Length,(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash)
  }
  return @($result | Sort-Object)
}
$qvdBefore=@(GetSnapshot 'QVD')
$qvwBefore=@(GetSnapshot 'QVW')
$sourceHash=(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
$work=Join-Path $tempRoot ('SAD_VIII_C2D1_'+[guid]::NewGuid().ToString('N'))
$dest=Join-Path $work 'SAD_C2D1_D2_BUTTON_TEST.qvw'
Write-Output ('VERSIONED_GIT_HEAD='+$head)
Write-Output ('SCRIPT_SHA256='+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('SOURCE_WRAP_QVW_SHA256='+$sourceHash)
Write-Output 'MODE=TEMP_COPY_NO_COM_NO_RELOAD_NO_QVD_WRITE'
if(-not $Prepare){Write-Output 'VERDICT=PREPARED_SCRIPT_NOT_EXECUTED_PASS_PRECHECKS_ONLY';exit 0}
$null=New-Item -ItemType Directory -Path $work -ErrorAction Stop
$problem=$null
try{
  Copy-Item -LiteralPath $sourcePath -Destination $dest -ErrorAction Stop
  if((Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash -cne $sourceHash){throw 'BLOCKED_QVW_COPY_SHA256_MISMATCH'}
  $manifest=[ordered]@{
    Gate='C2-D1';GitHead=$head;ScriptSha256=(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash;
    SourceQvw=$sourcePath;SourceSha256=$sourceHash;DestinationQvw=$dest;
    BeforeQvdSha256=@($qvdBefore);BeforeCanonicalQvwSha256=@($qvwBefore);
    Mode='TEMP_COPY_ONLY_NO_RELOAD_NO_COM'
  }
  $manifest|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $work 'prepare_manifest.json') -Encoding UTF8
}catch{$problem=$_.Exception.Message}finally{
  if((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash -cne $sourceHash){throw 'CRITICAL_SOURCE_WRAP_QVW_CHANGED'}
  if((@((GetSnapshot 'QVD')) -join [Environment]::NewLine) -cne ($qvdBefore -join [Environment]::NewLine)){throw 'CRITICAL_22_QVD_SHA256_CHANGED'}
  if((@((GetSnapshot 'QVW')) -join [Environment]::NewLine) -cne ($qvwBefore -join [Environment]::NewLine)){throw 'CRITICAL_CANONICAL_QVW_SHA256_CHANGED'}
  Write-Output 'SOURCE_WRAP_QVW_SHA256_UNCHANGED=True'
  Write-Output 'ORIGINAL_22_QVD_SHA256_UNCHANGED=True'
  Write-Output 'ORIGINAL_CANONICAL_QVWS_UNCHANGED=True'
}
if($null -ne $problem){throw ('C2D1_PREP_BLOCKED_'+$problem)}
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('COPY_FOR_GUI='+$dest)
Write-Output 'VERDICT=PASS_LOCAL_C2D1_QVW_COPY_ONLY_UI_BUTTONS_NOT_CONFIGURED'
Write-Output 'NEXT_ACTION=CONFIGURE_TWO_NATIVE_BUTTONS_ON_DISPOSABLE_COPY_AND_TEST_FOUR_D2_CASES'
Write-Output 'P5_D2_UI=NOT_TESTED C2_FULL=NOT_APPROVED PRODUCTION_APPROVED=False'