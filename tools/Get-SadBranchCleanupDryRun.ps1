#requires -Version 5.1
<#
.SYNOPSIS
  SAD branch cleanup: read-only, SHA-pinned remote inventory comparison.
.DESCRIPTION
  No fetch, push, delete, merge, COM, reload or local git working-tree modifications.
  Compares the pinned 161-ref pre-PR snapshot with actual git ls-remote --heads origin.
  A "candidate" status never authorizes deletion. Independent backup + ancestry
  validation and explicit owner approval are required for any future cleanup.
#>
[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$InventoryPath,
  [string]$EvidenceRoot = (Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-OutsideRepo([string]$Folder,[string]$Repository) {
  $f = [IO.Path]::GetFullPath($Folder).TrimEnd([char[]]@('\','/'))
  $r = [IO.Path]::GetFullPath($Repository).TrimEnd([char[]]@('\','/'))
  if ($f.Equals($r,[StringComparison]::OrdinalIgnoreCase) -or
      $f.StartsWith($r + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'EVIDENCE_ROOT_INSIDE_REPOSITORY'
  }
  return $f
}
function Read-RemoteHeads([string]$Repository) {
  $lines = @(& git -C $Repository ls-remote --heads origin)
  if ($LASTEXITCODE -ne 0) { throw 'GIT_LS_REMOTE_FAILED' }
  $result = @{}
  foreach($line in $lines) {
    if ($line -notmatch '^([0-9a-fA-F]{40})\s+refs/heads/(.+)$') { throw "INVALID_REMOTE_REF $line" }
    if ($result.ContainsKey($Matches[2])) { throw 'DUPLICATE_REMOTE_REF' }
    $result[$Matches[2]] = $Matches[1].ToLowerInvariant()
  }
  return ,$result
}

try {
  if (-not $RepoRoot) {
    $RepoRoot = Join-Path $env:USERPROFILE 'documents\programming\sad-sus-pb-data-mart'
  }
  if (-not $InventoryPath) {
    $InventoryPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs\project\repository-branch-inventory-2026-11-11.json'
  }
  $root = [IO.Path]::GetFullPath($RepoRoot)
  $snapshotPath = [IO.Path]::GetFullPath($InventoryPath)
  $out = Ensure-OutsideRepo $EvidenceRoot $root
  if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { throw 'REPO_MISSING_GIT_METADATA' }
  if (-not (Test-Path -LiteralPath $snapshotPath -PathType Leaf)) { throw 'INVENTORY_NOT_FOUND' }
  $source = ((& git -C $root remote get-url origin) | Out-String).Trim()
  if ($LASTEXITCODE -ne 0 -or
      $source -notmatch '(?i)^(https://(?:[^/@]+@)?github\.com/|git@github\.com:|ssh://git@github\.com/)(pedrogles/sad-sus-pb-data-mart)(?:\.git)?/?$') {
    throw 'UNEXPECTED_ORIGIN'
  }
  $snapshot = Get-Content -LiteralPath $snapshotPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($snapshot.schema -cne 'sad-github-hygiene-branch-inventory-v2' -or
      $snapshot.repository -cne 'pedrogles/sad-sus-pb-data-mart' -or
      $snapshot.branch_count -ne 161 -or @($snapshot.branches).Count -ne 161) {
    throw 'INVENTORY_CONTRACT_MISMATCH'
  }
  $remotes = Read-RemoteHeads $root
  $seen = @{}
  $rows = @()
  $drift = 0
  foreach($b in $snapshot.branches) {
    $name = [string]$b.name
    if ($seen.ContainsKey($name)) { throw 'DUPLICATE_INVENTORY_BRANCH' }
    $seen[$name] = $true
    $expected = ([string]$b.sha).ToLowerInvariant()
    if ($expected -notmatch '^[a-f0-9]{40}$') { throw 'INVALID_INVENTORY_SHA' }
    $actual = $null
    if ($remotes.ContainsKey($name)) { $actual = $remotes[$name] }
    $decision = 'HOLD_UNCLASSIFIED'
    if ($name -ceq 'main') {
      if ($actual -ne $expected -or $expected -ne ([string]$snapshot.main_sha)) {
        throw 'MAIN_SHA_DRIFT_REFRESH_INVENTORY'
      }
      $decision = 'PROTECT_MAIN'
    }
    elseif (-not $actual) { $decision='BLOCKED_MISSING_REF'; $drift++ }
    elseif ($actual -cne $expected) { $decision='BLOCKED_SHA_DRIFT'; $drift++ }
    elseif ($b.protected -eq $true) { $decision='HOLD_GITHUB_PROTECTED' }
    elseif ($b.classification -ceq 'MERGED_PR' -and
            $b.pr_merged_at -and $b.pr_sha_matches -eq $true -and
            $b.pr_head_sha -ceq $expected) {
      $decision = 'CANDIDATE_PENDING_BUNDLE_ANCESTRY_AND_OWNER_APPROVAL'
    }
    elseif ($b.classification -ceq 'CLOSED_UNMERGED_PR') { $decision='HOLD_CLOSED_UNMERGED' }
    elseif ($b.classification -ceq 'NO_PR') { $decision='HOLD_ORPHAN' }
    else { $decision='HOLD_OTHER' }
    $rows += [pscustomobject]@{
      Branch=$name;Group=[string]$b.classification;Pr=$b.pr_number
      SnapshotSha=$expected;LiveSha=$actual;Decision=$decision
    }
  }
  foreach($name in $remotes.Keys) {
    if (-not $seen.ContainsKey($name)) {
      $rows += [pscustomobject]@{
        Branch=$name;Group='NEW_SINCE_PINNED_SNAPSHOT';Pr=$null
        SnapshotSha=$null;LiveSha=$remotes[$name];Decision='HOLD_NEW_REF'
      }
    }
  }
  if (-not (Test-Path -LiteralPath $out)) {
    $null = New-Item -ItemType Directory -Path $out -ErrorAction Stop
  }
  $run = Join-Path $out ('dryrun_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [Guid]::NewGuid().ToString('N').Substring(0,8))
  $null = New-Item -ItemType Directory -Path $run -ErrorAction Stop
  $csv = Join-Path $run 'branch_decisions.csv'
  $json = Join-Path $run 'dryrun_manifest.json'
  $rows | Sort-Object Branch | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
  $candidates = @($rows | Where-Object { $_.Decision -eq 'CANDIDATE_PENDING_BUNDLE_ANCESTRY_AND_OWNER_APPROVAL' }).Count
  $extra = @($rows | Where-Object { $_.Decision -eq 'HOLD_NEW_REF' }).Count
  $report = [ordered]@{
    verdict=if($drift -gt 0){'BLOCKED_SNAPSHOT_REF_DRIFT'}else{'PASS_READ_ONLY_PROVISIONAL'}
    repository='pedrogles/sad-sus-pb-data-mart';mode='READ_ONLY'
    inventory_sha256=(Get-FileHash -LiteralPath $snapshotPath -Algorithm SHA256).Hash
    snapshot_branches=161;live_branches=$remotes.Count;extra_new_refs=$extra
    drifted_or_missing_refs=$drift;preliminary_merged_candidates=$candidates
    ancestry_checked=$false;bundle_backup_verified=$false
    deletions_authorized=$false;remote_mutations=$false
    report_csv=$csv
  }
  $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $json -Encoding UTF8
  Write-Output ('VERDICT='+$report.verdict)
  Write-Output ('LIVE_BRANCHES='+$report.live_branches)
  Write-Output ('PRELIMINARY_MERGED_CANDIDATES='+$candidates)
  Write-Output ('NEW_REFS_HELD='+$extra)
  Write-Output ('DRIFTED_REFS='+$drift)
  Write-Output ('REPORT_JSON='+$json)
  Write-Output ('REPORT_CSV='+$csv)
  Write-Output 'NO_REMOTE_MUTATIONS=True'
  if($drift -gt 0){ exit 2 }
} catch {
  Write-Output 'VERDICT=BLOCKED'
  Write-Output ('DETAIL='+$_.Exception.Message)
  exit 2
}
