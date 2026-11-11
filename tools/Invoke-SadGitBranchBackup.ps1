#requires -Version 5.1
<#
.SYNOPSIS
  Create and independently restore-verify a Git bundle containing every live remote branch.
.DESCRIPTION
  This script ONLY writes under an external evidence directory.
  It never fetches into the working clone, pushes, deletes remote refs, merges or
  modifies QlikView/QVD artifacts. It requires an explicit -BackupVerify switch.
  Source: a pinned 161-ref GitHub inventory and live git ls-remote output.
  New remote branches since the snapshot are backed up but HOLD for deletion.
  The resulting manifest is evidence only after a successful LOCAL run.
#>
[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$InventoryPath,
  [string]$EvidenceRoot = (Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS'),
  [switch]$BackupVerify
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Full([string]$x) { return [IO.Path]::GetFullPath($x).TrimEnd([char[]]@('\','/')) }
function Under([string]$child,[string]$parent) {
  return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
         $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
function RefMap([string[]]$lines,[string]$prefix) {
  $map = @{}
  foreach($line in $lines) {
    if ($line -notmatch ('^([0-9a-fA-F]{40})\s+'+[regex]::Escape($prefix)+'(.+)$')) {
      throw 'MALFORMED_GIT_REF_OUTPUT'
    }
    $name=$Matches[2]; $sha=$Matches[1].ToLowerInvariant()
    if ($map.ContainsKey($name)) { throw 'DUPLICATE_GIT_REF' }
    $map[$name]=$sha
  }
  return ,$map
}
function Live([string]$root) {
  $lines = @(& git -C $root ls-remote --heads origin)
  if ($LASTEXITCODE -ne 0) { throw 'GIT_LS_REMOTE_FAILED' }
  return (RefMap $lines 'refs/heads/')
}
function FromMirror([string]$mirror) {
  $lines = @(& git --git-dir=$mirror for-each-ref '--format=%(objectname) %(refname)' refs/heads)
  if ($LASTEXITCODE -ne 0) { throw 'GIT_FOREACH_REF_FAILED' }
  return (RefMap $lines 'refs/heads/')
}
function Same([hashtable]$a,[hashtable]$b) {
  if ($a.Count -ne $b.Count) { return $false }
  foreach($key in $a.Keys) {
    if (-not $b.ContainsKey($key) -or $a[$key] -cne $b[$key]) { return $false }
  }
  return $true
}
function CheckExit([string]$step) {
  if ($LASTEXITCODE -ne 0) { throw ('GIT_FAILED_'+$step+'_CODE_'+$LASTEXITCODE) }
}

$runDir = $null
try {
  if (-not $BackupVerify) { throw 'EXPLICIT_BACKUP_VERIFY_SWITCH_REQUIRED' }
  if (-not $RepoRoot) {
    $RepoRoot=Join-Path $env:USERPROFILE 'documents\programming\sad-sus-pb-data-mart'
  }
  if (-not $InventoryPath) {
    $InventoryPath=Join-Path (Split-Path $PSScriptRoot -Parent) 'docs\project\repository-branch-inventory-2026-11-11.json'
  }
  $root=Full $RepoRoot
  $path=Full $InventoryPath
  $out=Full $EvidenceRoot
  if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { throw 'NOT_A_GIT_CLONE' }
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw 'INVENTORY_MISSING' }
  if ((Under $out $root) -or (Under $root $out)) { throw 'EVIDENCE_ROOT_OVERLAPS_REPOSITORY' }
  $url = ((& git -C $root remote get-url origin) | Out-String).Trim()
  CheckExit 'REMOTE_URL'
  if ($url -notmatch '(?i)^(https://(?:[^/@]+@)?github\.com/|git@github\.com:|ssh://git@github\.com/)(pedrogles/sad-sus-pb-data-mart)(?:\.git)?/?$') {
    throw 'ORIGIN_NOT_CANONICAL_SAD_REPOSITORY'
  }
  $snap = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($snap.schema -cne 'sad-github-hygiene-branch-inventory-v2' -or
      $snap.repository -cne 'pedrogles/sad-sus-pb-data-mart' -or
      $snap.branch_count -ne 161 -or @($snap.branches).Count -ne 161) {
    throw 'INVENTORY_SCHEMA_MISMATCH'
  }
  $before=Live $root
  $snapshotMap=@{}
  foreach($b in $snap.branches) {
    $name=[string]$b.name;$sha=([string]$b.sha).ToLowerInvariant()
    if($snapshotMap.ContainsKey($name)){throw 'INVENTORY_DUPLICATE_REF'}
    $snapshotMap[$name]=$sha
    if (-not $before.ContainsKey($name) -or $before[$name] -cne $sha) {
      throw ('INVENTORY_REF_DRIFT: '+$name)
    }
  }
  if ($before['main'] -cne ([string]$snap.main_sha)) { throw 'MAIN_MOVED_REGENERATE_SNAPSHOT' }
  if (-not (Test-Path -LiteralPath $out)) {
    $null=New-Item -ItemType Directory -Path $out -ErrorAction Stop
  }
  $runDir=Join-Path $out ('backup_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8))
  $null=New-Item -ItemType Directory -Path $runDir -ErrorAction Stop
  $mirror=Join-Path $runDir 'mirror.git'
  $bundle=Join-Path $runDir 'sad-all-refs.bundle'
  $restore=Join-Path $runDir 'restore-test.git'

  # Always use the canonical HTTPS endpoint to avoid copying credential-bearing
  # userinfo from git remote get-url origin into logs or clone configuration.
  & git clone --quiet --mirror 'https://github.com/pedrogles/sad-sus-pb-data-mart.git' $mirror
  CheckExit 'MIRROR_CLONE'
  $mirrored=FromMirror $mirror
  if (-not (Same $before $mirrored)) { throw 'MIRROR_REF_MISMATCH' }

  & git --git-dir=$mirror bundle create $bundle --all
  CheckExit 'BUNDLE_CREATE'
  if (-not (Test-Path -LiteralPath $bundle -PathType Leaf)) { throw 'BUNDLE_MISSING' }
  & git --git-dir=$mirror bundle verify $bundle 2>$null | Out-Null
  CheckExit 'BUNDLE_VERIFY'

  # An independent restore checks actual backup recoverability, not only checksum.
  & git clone --quiet --mirror $bundle $restore
  CheckExit 'RESTORE_CLONE'
  $restored=FromMirror $restore
  if (-not (Same $before $restored)) { throw 'RESTORED_BRANCH_REFS_MISMATCH' }
  $after=Live $root
  if (-not (Same $before $after)) { throw 'REMOTE_MOVED_DURING_BACKUP' }

  # Ancestor relationship must be tested against full mirrored object graph.
  # Merged PR metadata alone is never a deletion authorization.
  $rows=@()
  foreach($b in $snap.branches) {
    $status='HOLD_UNMERGED_OR_ORPHAN'
    if($b.name -ceq 'main') { $status='PROTECT_MAIN' }
    elseif($b.protected -eq $true) { $status='HOLD_PROTECTED' }
    elseif($b.classification -ceq 'MERGED_PR' -and
           $b.pr_sha_matches -eq $true -and $b.pr_merged_at -and
           $b.pr_head_sha -ceq $b.sha) {
      & git --git-dir=$mirror merge-base --is-ancestor ([string]$b.sha) ([string]$snap.main_sha)
      $code=$LASTEXITCODE
      if($code -eq 0) {$status='ANCESTOR_AND_BACKED_UP_PENDING_OWNER_APPROVAL'}
      elseif($code -eq 1) {$status='HOLD_NOT_ANCESTOR_OF_MAIN'}
      else { throw ('ANCESTRY_TEST_ERROR '+$b.name+' '+$code) }
    }
    $rows += [pscustomobject]@{
      Branch=[string]$b.name;Sha=[string]$b.sha;Pr=$b.pr_number
      Group=[string]$b.classification;Decision=$status
    }
  }
  foreach($name in $before.Keys) {
    if (-not $snapshotMap.ContainsKey($name)) {
      $rows += [pscustomobject]@{
        Branch=$name;Sha=$before[$name];Pr=$null
        Group='NEW_SINCE_SNAPSHOT';Decision='HOLD_NEW_REF_BACKED_UP'
      }
    }
  }
  $csv=Join-Path $runDir 'verified_branch_decisions.csv'
  $json=Join-Path $runDir 'backup_manifest.json'
  $rows|Sort-Object Branch|Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
  $bundleSha=(Get-FileHash -LiteralPath $bundle -Algorithm SHA256).Hash
  $candidateCount=@($rows|Where-Object {$_.Decision -eq 'ANCESTOR_AND_BACKED_UP_PENDING_OWNER_APPROVAL'}).Count
  $nonAncestor=@($rows|Where-Object {$_.Decision -eq 'HOLD_NOT_ANCESTOR_OF_MAIN'}).Count
  $extraCount=@($rows|Where-Object {$_.Decision -eq 'HOLD_NEW_REF_BACKED_UP'}).Count
  $manifest=[ordered]@{
    verdict='PASS_LOCAL_BUNDLE_AND_INDEPENDENT_RESTORE'
    repository='pedrogles/sad-sus-pb-data-mart'
    snapshot_sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    main_sha=[string]$snap.main_sha
    branch_count_remote_before=$before.Count
    branch_count_mirror=$mirrored.Count
    branch_count_restored=$restored.Count
    branch_count_remote_after=$after.Count
    branch_heads_match_before_mirror_restore_after=$true
    snapshot_refs=161;new_refs_backed_up_but_held=$extraCount
    merged_refs_with_ancestry_proven=$candidateCount
    merged_refs_not_ancestor=$nonAncestor
    bundle_path=$bundle;bundle_size_bytes=(Get-Item -LiteralPath $bundle).Length
    bundle_sha256=$bundleSha
    restore_path=$restore
    decisions_csv=$csv
    owner_approved_branch_deletions=$false;remote_mutations=$false
  }
  $manifest|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $json -Encoding UTF8
  Write-Output ('VERDICT='+$manifest.verdict)
  Write-Output ('BACKED_UP_REFS='+$before.Count)
  Write-Output ('RESTORED_REFS='+$restored.Count)
  Write-Output ('MERGED_ANCESTOR_CANDIDATES='+$candidateCount)
  Write-Output ('MERGED_NOT_ANCESTOR='+$nonAncestor)
  Write-Output ('NEW_REFS_HELD='+$extraCount)
  Write-Output ('BUNDLE_SHA256='+$bundleSha)
  Write-Output ('REPORT='+$json)
  Write-Output ('BUNDLE='+$bundle)
  Write-Output 'NO_REMOTE_MUTATIONS=True'
} catch {
  Write-Output 'VERDICT=BLOCKED'
  Write-Output ('DETAIL='+$_.Exception.Message)
  if($runDir){Write-Output ('PARTIAL_EVIDENCE_DIR='+$runDir)}
  exit 2
}
