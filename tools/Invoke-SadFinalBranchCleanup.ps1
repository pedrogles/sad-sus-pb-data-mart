#requires -Version 5.1
<#
SAD: final, SHA-leased cleanup of remote historical branches.
DEFAULT: Preview (no remote mutations). Actual deletion is an independent,
destructive, explicitly approved gate. Requires a verified backup bundle.
Conservative mode only: delete up to 102 refs tied to merged PRs.
The 53 closed-unmerged and 5 orphan refs, plus newer PR refs, are HELD.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$InventoryPath,
  [Parameter(Mandatory=$true)][string]$BundlePath,
  [string]$ExpectedMainSha,
  [string]$ExpectedRunnerSha,
  [string]$ExpectedHold240Sha,
  [string]$SecondBundlePath,
  [switch]$IndependentStorageConfirmed,
  [ValidateSet('Preview','DeleteMerged102')]
  [string]$Mode='Preview',
  [string]$ApprovalCode='',
  [string]$OutputRoot=(Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repository='pedrogles/sad-sus-pb-data-mart'
$runnerBranch='chore/sad-branch-backup-readonly-2026-11-11'
$holdBranch='docs/sad-classificacao-testes-artefatos-2026-11-12'
$bundleSha='1DC499D992C0414664FFC59298770767DCA40E872070ED314E300AFD045CB21A'
$runDir=$null
$completed=@()
function Fail([string]$reason){throw $reason}
function RemoteRefs([string]$root) {
  $lines=@(& git -C $root ls-remote --heads origin)
  if($LASTEXITCODE -ne 0){Fail 'LS_REMOTE_FAILED'}
  $map=@{}
  foreach($line in $lines){
    if($line -notmatch '^([0-9a-fA-F]{40})\s+refs/heads/(.+)$'){Fail 'BAD_REMOTE_REF'}
    $name=$Matches[2];$sha=$Matches[1].ToLowerInvariant()
    if($map.ContainsKey($name)){Fail 'DUPLICATE_REMOTE_REF'}
    $map[$name]=$sha
  }
  return ,$map
}
function Outside([string]$root,[string]$out){
  $a=[IO.Path]::GetFullPath($root).TrimEnd([char[]]@('\','/'))
  $b=[IO.Path]::GetFullPath($out).TrimEnd([char[]]@('\','/'))
  if($a.Equals($b,[StringComparison]::OrdinalIgnoreCase) -or
     $b.StartsWith($a+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){
     Fail 'OUTPUT_INSIDE_REPO'
  }
  return $b
}
try{
  $root=[IO.Path]::GetFullPath($RepoRoot)
  $inventory=[IO.Path]::GetFullPath($InventoryPath)
  $bundle=[IO.Path]::GetFullPath($BundlePath)
  $out=Outside $root $OutputRoot
  if(-not (Test-Path -LiteralPath (Join-Path $root '.git'))){Fail 'INVALID_REPO'}
  if(-not (Test-Path -LiteralPath $inventory -PathType Leaf)){Fail 'INVENTORY_MISSING'}
  if(-not (Test-Path -LiteralPath $bundle -PathType Leaf)){Fail 'BUNDLE_MISSING'}
  $url=((& git -C $root remote get-url origin)|Out-String).Trim()
  if($LASTEXITCODE -ne 0 -or $url -notmatch '(?i)^(https://(?:[^/@]+@)?github\.com/|git@github\.com:|ssh://git@github\.com/)(pedrogles/sad-sus-pb-data-mart)(?:\.git)?/?$'){
    Fail 'NOT_CANONICAL_ORIGIN'
  }
  $j=Get-Content -LiteralPath $inventory -Raw -Encoding UTF8|ConvertFrom-Json
  if($j.schema -cne 'sad-github-hygiene-branch-inventory-v2' -or
     $j.repository -cne $repository -or
     $j.branch_count -ne 161 -or @($j.branches).Count -ne 161){Fail 'BAD_INVENTORY'}
  $hash=(Get-FileHash -LiteralPath $bundle -Algorithm SHA256).Hash
  if($hash -cne $bundleSha){Fail 'BACKUP_HASH_MISMATCH'}
  $bundleLines=@(& git bundle list-heads $bundle)
  if($LASTEXITCODE -ne 0){Fail 'BUNDLE_LIST_HEADS_FAILED'}
  $backup=@{}
  foreach($line in $bundleLines){
    if($line -match '^([0-9a-fA-F]{40})\s+refs/heads/(.+)$'){
      $backup[$Matches[2]]=$Matches[1].ToLowerInvariant()
    }
  }
  $live=RemoteRefs $root
  $snap=@{}
  $merged=@();$archived=@()
  foreach($b in $j.branches){
    $name=[string]$b.name
    $sha=([string]$b.sha).ToLowerInvariant()
    if($snap.ContainsKey($name)){Fail 'INVENTORY_DUPLICATE'}
    if($sha -notmatch '^[0-9a-f]{40}$'){Fail 'BAD_SHA'}
    $snap[$name]=$sha
    if(-not $backup.ContainsKey($name) -or $backup[$name] -cne $sha){Fail ('BACKUP_MISSING_REF '+$name)}
    if($name -ceq 'main'){continue}
    if(-not $live.ContainsKey($name) -or $live[$name] -cne $sha){Fail ('REMOTE_SHA_DRIFT '+$name)}
    if($b.protected -eq $true){Fail ('PROTECTED_REF '+$name)}
    $entry=[pscustomobject]@{
      Branch=$name;Sha=$sha;Group=[string]$b.classification;Pr=$b.pr_number
      Policy=if($b.classification -ceq 'MERGED_PR'){'MERGED_CONFIRMED'}else{'ARCHIVE_ONLY_UNMERGED_OR_ORPHAN'}
    }
    if($b.classification -ceq 'MERGED_PR'){
      if(-not $b.pr_merged_at -or $b.pr_sha_matches -ne $true -or
         ([string]$b.pr_head_sha).ToLowerInvariant() -cne $sha){Fail ('MERGED_CONTRACT_FAIL '+$name)}
      $merged+= $entry
    } elseif($b.classification -ceq 'CLOSED_UNMERGED_PR' -or $b.classification -ceq 'NO_PR'){
      $archived+= $entry
    } else {Fail ('UNKNOWN_CLASS '+$name)}
  }
  if($merged.Count -ne 102 -or $archived.Count -ne 58){Fail 'CLASSIFICATION_COUNT_MISMATCH'}
  if(-not $live.ContainsKey('main')){Fail 'MAIN_REF_MISSING'}
  $main=$live['main']
  if($ExpectedMainSha -and $main -cne $ExpectedMainSha.ToLowerInvariant()){Fail 'MAIN_HEAD_MISMATCH'}
  if(-not $live.ContainsKey($runnerBranch)){Fail 'RUNNER_BRANCH_MISSING'}
  # Two deliberately protected post-snapshot refs: this runner and PR #240.
  # Any other new ref, or drift in a pinned ref, stops the operation.
  if(-not $live.ContainsKey($holdBranch)){Fail 'PR240_HOLD_REF_MISSING'}
  $new=@($live.Keys|Where-Object { -not $snap.ContainsKey($_) })
  if($new.Count -ne 2 -or -not ($new -ccontains $runnerBranch) -or
     -not ($new -ccontains $holdBranch)){Fail 'UNEXPECTED_REMOTE_BRANCHES'}
  if($ExpectedHold240Sha){
    if($ExpectedHold240Sha -notmatch '^[0-9a-fA-F]{40}$'){Fail 'BAD_PR240_HOLD_SHA'}
    if($live[$holdBranch] -cne $ExpectedHold240Sha.ToLowerInvariant()){
      Fail 'PR240_HOLD_SHA_DRIFT'
    }
  }
  $plan=@()
  if($Mode -eq 'DeleteMerged102'){$plan=@($merged)}
  if($Mode -ne 'Preview'){
    if(-not $ExpectedMainSha -or -not $ExpectedRunnerSha -or -not $ExpectedHold240Sha){
      Fail 'PINNED_MAIN_RUNNER_AND_PR240_REQUIRED'
    }
    # A post-merge main SHA is required. A mere main change is NOT proof
    # that PR #239 was merged; the operator must verify its merged_at first.
    if($main -ceq ([string]$j.main_sha).ToLowerInvariant()){Fail 'MERGE_PR239_FIRST'}
    if($ApprovalCode -cne 'APPROVE_DELETE_MERGED_102'){Fail 'EXPLICIT_BATCH_APPROVAL_CODE_REQUIRED'}
    if(-not $SecondBundlePath -or -not $IndependentStorageConfirmed){
      Fail 'SECOND_INDEPENDENT_BACKUP_REQUIRED'
    }
    $secondBundle=[IO.Path]::GetFullPath($SecondBundlePath)
    if(-not (Test-Path -LiteralPath $secondBundle -PathType Leaf)){Fail 'SECOND_BACKUP_MISSING'}
    if($secondBundle.Equals($bundle,[StringComparison]::OrdinalIgnoreCase)){
      Fail 'SECOND_BACKUP_SAME_PATH'
    }
    $secondHash=(Get-FileHash -LiteralPath $secondBundle -Algorithm SHA256).Hash
    if($secondHash -cne $bundleSha){Fail 'SECOND_BACKUP_HASH_MISMATCH'}
    # Do not delete the live PR #239/#240 refs in the conservative batch.
    if(@($plan|Where-Object { $_.Branch -eq $runnerBranch -or $_.Branch -eq $holdBranch }).Count -gt 0){
      Fail 'PROTECTED_REF_IN_DELETE_PLAN'
    }
  }
  if(-not (Test-Path -LiteralPath $out)){
    New-Item -ItemType Directory -Path $out -ErrorAction Stop|Out-Null
  }
  $runDir=Join-Path $out ('cleanup_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N').Substring(0,8))
  New-Item -ItemType Directory -Path $runDir -ErrorAction Stop|Out-Null
  $planCsv=Join-Path $runDir 'candidate_manifest.csv'
  $logCsv=Join-Path $runDir 'executed_operations.csv'
  $reportJson=Join-Path $runDir 'cleanup_report.json'
  $all=@($merged)+@($archived)
  $all | Sort-Object Group,Branch | Export-Csv -LiteralPath $planCsv -Encoding UTF8 -NoTypeInformation
  $completed=@()
  foreach($x in $plan){
    if($x.Branch -eq 'main'){Fail 'MAIN_IN_PLAN'}
    # Git force-with-lease rechecks the exact expected remote SHA atomically.
    # Do not issue one extra ls-remote per branch (160 unnecessary round trips).
    $lease='--force-with-lease=refs/heads/'+$x.Branch+':'+$x.Sha
    $refspec=':refs/heads/'+$x.Branch
    # PowerShell 5.1 can surface normal Git stderr as a terminating error.
    $previousPolicy=$ErrorActionPreference
    try {
      $ErrorActionPreference='Continue'
      $output=@(& git -C $root push --porcelain $lease origin $refspec 2>&1)
      $exitCode=$LASTEXITCODE
    } finally {
      $ErrorActionPreference=$previousPolicy
    }
    $completed+= [pscustomobject]@{
      Branch=$x.Branch;Sha=$x.Sha;Pr=$x.Pr;ExitCode=$exitCode
      Result=if($exitCode -eq 0){'DELETED'}else{'FAILED'}
    }
    if($exitCode -ne 0){Fail ('PUSH_DELETE_REJECTED '+$x.Branch)}
  }
  $after=RemoteRefs $root
  $remaining=if($Mode -eq 'Preview'){$live.Count}else{$after.Count}
  if($Mode -ne 'Preview'){
    if($after['main'] -cne $main){Fail 'MAIN_MOVED_DURING_DELETE'}
    foreach($x in $plan){if($after.ContainsKey($x.Branch)){Fail ('DELETE_NOT_APPLIED '+$x.Branch)}}
  }
  $completed|Export-Csv -LiteralPath $logCsv -NoTypeInformation -Encoding UTF8
  $report=[ordered]@{
    verdict=if($Mode -eq 'Preview'){'PASS_PREVIEW_ONLY'}else{'PASS_DELETE_LEASED'}
    mode=$Mode;main_sha=$main;bundle_sha256=$hash
    merged_branches=102;held_unmerged_or_orphan=58
    held_runner_branch=$runnerBranch;held_pr240_branch=$holdBranch;held_pr240_sha=$live[$holdBranch]
    planned_deletions=$plan.Count;actual_deletions=@($completed|Where-Object {$_.Result -eq 'DELETED'}).Count
    before_refs=$live.Count;after_refs=$remaining
    manifest=$planCsv;operation_log=$logCsv;no_changes_to_main=$true
  }
  $report|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $reportJson -Encoding UTF8
  Write-Output ('VERDICT='+$report.verdict)
  Write-Output ('MODE='+$Mode)
  Write-Output ('CANDIDATE_MERGED=102')
  Write-Output ('HELD_UNMERGED_OR_ORPHAN=58')
  Write-Output ('DELETED='+$report.actual_deletions)
  Write-Output ('REMAINING_REMOTE_BRANCHES='+$report.after_refs)
  Write-Output ('MANIFEST='+$planCsv)
  Write-Output ('REPORT='+$reportJson)
} catch{
  Write-Output 'VERDICT=BLOCKED'
  Write-Output ('DETAIL='+$_.Exception.Message)
  if($runDir){
    Write-Output ('PARTIAL_EVIDENCE_DIR='+$runDir)
    if($null -ne $completed -and @($completed).Count -gt 0){
      $completed | Export-Csv -LiteralPath (Join-Path $runDir 'partial_operations.csv') -NoTypeInformation -Encoding UTF8
      Write-Output ('PARTIAL_DELETIONS_LOG='+(Join-Path $runDir 'partial_operations.csv'))
    }
  }
  exit 2
}
