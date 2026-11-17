#requires -Version 5.1
<#
Post-interruption read-only closeout for the pinned VIS-05 manual session.
No COM/OpenDoc/Reload/Save. Never edits the interrupted inspection.json.
Historical finally/cleanup cannot be certified retroactively.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ReportPath,
  [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{40}$')][string]$ExpectedCommit
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Get-SadSha([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()}
function Get-SadFileComparison($Expected){
  $actual=Get-Item -LiteralPath ([string]$Expected.path) -ErrorAction Stop
  if($actual.PSIsContainer){throw 'Expected a file'}
  $sha=Get-SadSha $actual.FullName
  return [ordered]@{
    path=$actual.FullName;expected_sha256=$Expected.sha256;actual_sha256=$sha
    expected_bytes=[long]$Expected.bytes;actual_bytes=$actual.Length
    matches=($sha -ieq [string]$Expected.sha256 -and $actual.Length -eq [long]$Expected.bytes)
  }
}
$locks=[Collections.Generic.List[object]]::new()
$out=[ordered]@{
  gate='SAD_VIS05_INTERRUPTED_HASH_CLOSEOUT_01';started=(Get-Date).ToString('o')
  status='BLOCKED_PRECHECK';historical_cleanup_certified=$false
  original_cleanup_status='NOT_RECORDED_IN_INTERRUPTED_REPORT'
  current_integrity_verified=$false;current_qv_absent=$false;current_locks_released=$false
  protected_comparisons=@();copy_comparison=$null
  numerical_tests_repeated=$false;qlikview_opened=$false;original_report_modified=$false
}
$code=2;$outputFile=$null
try{
  if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows required'}
  $rootFull=[IO.Path]::GetFullPath($Root)
  $head=(& git -C $rootFull rev-parse HEAD | Out-String).Trim()
  if($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit.ToLowerInvariant()){throw 'Git commit mismatch'}
  $rel='tools/Verify-SadVis05InterruptedSession.ps1'
  $expectedBlob=(& git -C $rootFull rev-parse ('HEAD:'+$rel) | Out-String).Trim()
  $actualBlob=(& git -C $rootFull hash-object -- $PSCommandPath | Out-String).Trim()
  if($LASTEXITCODE -ne 0 -or $actualBlob -cne $expectedBlob -or
    [IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath((Join-Path $rootFull $rel))){throw 'Run the committed verifier from Root'}
  $out.git_head=$head;$out.script_sha256=Get-SadSha $PSCommandPath
  $inputFull=[IO.Path]::GetFullPath($ReportPath)
  $session=[IO.Path]::GetDirectoryName($inputFull)
  if([IO.Path]::GetFileName($inputFull) -cne 'inspection.json' -or
    [IO.Path]::GetFileName($session) -cne 'VIS05_INSPECT_20261115_235407_3c3df8cbbcc6'){throw 'Wrong interrupted report/session'}
  $out.input_report=$inputFull
  $out.input_report_sha256=Get-SadSha $inputFull
  if($out.input_report_sha256 -cne '370C8F65AD42934DCB2A8E0385C075AEF439CA35E7A571DB10FB334F0CC63427'){throw 'Interrupted JSON hash mismatch; do not change the pin'}
  $inputReport=Get-Content -LiteralPath $inputFull -Raw -Encoding UTF8 | ConvertFrom-Json
  if($inputReport.mode -cne 'ManualVisual' -or $inputReport.git_head -cne 'fb1799a340c383b592ba331467eae9daca8a27fc' -or
    $inputReport.active_visual_step -cne 'V1_SORT'){throw 'Unexpected interrupted session'}
  $before=@($inputReport.protected_before)
  if($before.Count -ne 26 -or @($before | Group-Object { [IO.Path]::GetFullPath([string]$_.path).ToUpperInvariant() }).Count -ne 26){throw 'Need 26 unique protected paths'}
  if(@($before | Where-Object { [IO.Path]::GetExtension([string]$_.path) -ieq '.qvd' }).Count -ne 22 -or
    @($before | Where-Object { [IO.Path]::GetExtension([string]$_.path) -ieq '.qvw' }).Count -ne 4){throw 'Wrong protected file classes'}
  if(@(Get-Process -Name Qv -ErrorAction SilentlyContinue).Count -gt 0){throw 'Close QlikView WITHOUT SAVING before this read-only check'}
  $copy=[IO.Path]::GetFullPath([string]$inputReport.inspection_copy_path)
  if($copy -ine (Join-Path $session 'SAD_VIS05_INSPECTION_COPY.qvw')){throw 'Unexpected copy path'}
  foreach($row in $before){
    $locks.Add([IO.File]::Open([string]$row.path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read))
  }
  $locks.Add([IO.File]::Open($copy,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read))
  $rows=@()
  foreach($row in $before){$rows+=Get-SadFileComparison $row}
  $out.protected_comparisons=$rows
  $source=@($before | Where-Object {$_.sha256 -ceq $inputReport.source_sha256 -and [IO.Path]::GetExtension([string]$_.path) -ieq '.qvw'})
  if($source.Count -ne 1 -or $inputReport.source_sha256 -cne 'B56D0A8550AB7EEE68D45DB0249F273DED05C4ADEE88DBE3FC7A20B162084DBB'){throw 'Source pin mismatch'}
  $out.copy_comparison=Get-SadFileComparison ([pscustomobject]@{path=$copy;sha256=$source[0].sha256;bytes=$source[0].bytes})
  $out.current_qv_absent=(@(Get-Process -Name Qv -ErrorAction SilentlyContinue).Count -eq 0)
  $out.input_report_unchanged=((Get-SadSha $inputFull) -ceq $out.input_report_sha256)
  $out.current_integrity_verified=(@($rows | Where-Object {-not $_.matches}).Count -eq 0 -and $out.copy_comparison.matches -and $out.input_report_unchanged)
  $out.manual_png_files=@(Get-ChildItem -LiteralPath $session -Filter '*.png' -File | ForEach-Object {
    @{file=$_.Name;bytes=$_.Length;sha256=(Get-SadSha $_.FullName)}
  })
  $baseline=@($inputReport.manual_visual_steps | Where-Object {$_.id -ceq 'V1_BASELINE'})
  $baselinePath=Join-Path $session 'V1_BASELINE.png'
  $out.baseline_capture_matches_checkpoint=($baseline.Count -eq 1 -and (Test-Path -LiteralPath $baselinePath -PathType Leaf) -and
    (Get-SadSha $baselinePath) -ceq $baseline[0].capture.sha256)
  if(-not $out.current_integrity_verified){throw 'Current file comparison failed; no QlikView restart'}
  if(-not $out.current_qv_absent){throw 'QlikView appeared during verification'}
  if(-not $out.baseline_capture_matches_checkpoint){throw 'Original baseline PNG differs from checkpoint'}
  $out.status='PASS_CURRENT_HASHES_HISTORICAL_CLEANUP_UNVERIFIED'
  $code=0
}catch{
  $out.failure=$_.Exception.Message
  $out.status='BLOCKED_OR_INCONCLUSIVE_POST_INTERRUPTION'
}finally{
  $releaseErrors=@()
  foreach($handle in $locks){try{$handle.Dispose()}catch{$releaseErrors+=$_.Exception.Message}}
  $out.current_locks_released=($releaseErrors.Count -eq 0)
  $out.current_release_errors=$releaseErrors
  if(-not $out.current_locks_released){$out.status='BLOCKED_CURRENT_LOCK_RELEASE';$code=2}
  $out.finished=(Get-Date).ToString('o')
  if($out.Contains('input_report') -and (Test-Path -LiteralPath $session -PathType Container)){
    $outputFile=Join-Path $session ('interruption_closeout_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.json')
    $stream=[IO.File]::Open($outputFile,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try{
      $bytes=[Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-Json -InputObject $out -Depth 12))
      $stream.Write($bytes,0,$bytes.Length)
    }finally{$stream.Dispose()}
    Write-Output ('REPORT='+$outputFile)
  }
  Write-Output ('VERDICT='+$out.status)
  if($out.Contains('failure')){Write-Output ('DETAIL='+$out.failure)}
  Write-Output 'STOP=True QLIKVIEW_OPENED=False RELOAD=False SAVE=False HISTORICAL_CLEANUP_CERTIFIED=False'
}
exit $code
