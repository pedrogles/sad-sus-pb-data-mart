#requires -Version 5.1
<#
SAD: final, SHA-leased cleanup of remote historical branches.
DEFAULT: Preview (no remote mutations). Actual deletion is an independent,
destructive, explicitly approved gate. Requires a verified backup bundle.
The 53 unmerged PR branches and 5 orphan branches are ARCHIVED ONLY,
not silently classified as integrated into main.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$InventoryPath,
  [Parameter(Mandatory=$true)][string]$BundlePath,
  [string]$ExpectedMainSha,
  [string]$ExpectedRunnerSha,
  [ValidateSet('Preview','DeleteMerged102','DeleteAllArchived160PlusRunner')]
  [string]$Mode='Preview',
  [string]$ApprovalCode='',
  [string]$OutputRoot=(Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repository='pedrogles/sad-sus-pb-data-mart'
$runnerBranch='chore/sad-branch-backup-readonly-2026-11-11'
$bundleSha='1DC499D992C0414664FFC59298770767DCA40E872070ED314E300AFD045CB21A'
$runDir=$null
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
  $new=@($live.Keys|Where-Object { -not $snap.ContainsKey($_) })
  if($new.Count -ne 1 -or $new[0] -cne $runnerBranch){Fail 'UNEXPECTED_REMOTE_BRANCHES'}
  if($ExpectedRunnerSha -and $live[$runnerBranch] -cne $ExpectedRunnerSha.ToLowerInvariant()){
    Fail 'RUNNER_HEAD_MISMATCH'
  }
  $plan=@()
  if($Mode -eq 'DeleteMerged102'){$plan=@($merged)}
  if($Mode -eq 'DeleteAllArchived160PlusRunner'){
    $plan=@($merged)+@($archived)
    $plan+= [pscustomobject]@{
      Branch=$runnerBranch;Sha=$live[$runnerBranch];Group='MERGED_PREPARATION_PR'
      Pr=239;Policy='MERGED_ONLY_AFTER_PR239_REVIEW'
    }
  }
  if($Mode -ne 'Preview'){
    if(-not $ExpectedMainSha -or -not $ExpectedRunnerSha){Fail 'PINNED_MAIN_AND_RUNNER_REQUIRED'}
    if($main -ceq ([string]$j.main_sha).ToLowerInvariant()){Fail 'MERGE_PR239_FIRST'}
    $approval=if($Mode -eq 'DeleteMerged102'){'APPROVE_DELETE_MERGED_102'}else{'APPROVE_ARCHIVE_AND_DELETE_161_ALL_NON_MAIN'}
    if($ApprovalCode -cne $approval){Fail 'EXPLICIT_BATCH_APPROVAL_CODE_REQUIRED'}
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
    $remoteNow=RemoteRefs $root
    if(-not $remoteNow.ContainsKey($x.Branch) -or $remoteNow[$x.Branch] -cne $x.Sha){
      Fail ('REF_CHANGED_DURING_CLEANUP '+$x.Branch)
    }
    if($Mode -eq 'Preview'){continue}
    $lease='--force-with-lease=refs/heads/'+$x.Branch+':'+$x.Sha
    $refspec=':refs/heads/'+$x.Branch
    $output=@(& git -C $root push --porcelain $lease origin $refspec 2>&1)
    $exitCode=$LASTEXITCODE
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
    merged_branches=102;archived_unmerged_or_orphan=58
    planned_deletions=$plan.Count;actual_deletions=@($completed|Where-Object {$_.Result -eq 'DELETED'}).Count
    before_refs=$live.Count;after_refs=$remaining
    manifest=$planCsv;operation_log=$logCsv;no_changes_to_main=$true
  }
  $report|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $reportJson -Encoding UTF8
  Write-Output ('VERDICT='+$report.verdict)
  Write-Output ('MODE='+$Mode)
  Write-Output ('CANDIDATE_MERGED=102')
  Write-Output ('ARCHIVE_ONLY_UNMERGED_OR_ORPHAN=58')
  Write-Output ('DELETED='+$report.actual_deletions)
  Write-Output ('REMAINING_REMOTE_BRANCHES='+$report.after_refs)
  Write-Output ('MANIFEST='+$planCsv)
  Write-Output ('REPORT='+$reportJson)
} catch{
  Write-Output 'VERDICT=BLOCKED'
  Write-Output ('DETAIL='+$_.Exception.Message)
  if($runDir){Write-Output ('PARTIAL_EVIDENCE_DIR='+$runDir)}
  exit 2
}
