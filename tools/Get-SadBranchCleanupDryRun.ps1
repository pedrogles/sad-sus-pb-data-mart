#requires -Version 5.1
<#
SAD GitHub remote branch cleanup - READ ONLY.
Parses a versioned snapshot; checks all remote refs and writes a dry-run CSV/JSON.
Never runs fetch/push/delete/merge; no remote mutations.
#>
[CmdletBinding()]
param(
  [string]$RepoRoot,
  [string]$InventoryPath,
  [string]$OutputRoot = (Join-Path $env:USERPROFILE 'SAD_REPO_HYGIENE_EVIDENCIAS')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepoRoot) {
  $RepoRoot = Join-Path $env:USERPROFILE 'documents\programming\sad-sus-pb-data-mart'
}
if (-not $InventoryPath) {
  $InventoryPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs\project\repository-final-hygiene-inventory-2026-11-10.json'
}
try {
  $root = [IO.Path]::GetFullPath($RepoRoot)
  $inventory = [IO.Path]::GetFullPath($InventoryPath)
  $out = [IO.Path]::GetFullPath($OutputRoot)
  if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { throw 'NOT_A_GIT_CLONE' }
  if (-not (Test-Path -LiteralPath $inventory -PathType Leaf)) { throw 'INVENTORY_MISSING' }
  if ($out -eq $root -or $out.StartsWith(($root.TrimEnd('\')+'\'),[StringComparison]::OrdinalIgnoreCase)) {
    throw 'OUTPUT_INSIDE_REPOSITORY_NOT_ALLOWED'
  }
  Push-Location $root
  try {
    $remote = ((& git remote get-url origin) | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $remote -notmatch '(?i)github\.com[:/]pedrogles/sad-sus-pb-data-mart(?:\.git)?/?$') {
      throw "UNEXPECTED_ORIGIN: $remote"
    }
    $list = @(& git ls-remote --heads origin)
    if ($LASTEXITCODE -ne 0) { throw 'LS_REMOTE_FAILED' }
  } finally { Pop-Location }
  $heads = @{}
  foreach($line in $list) {
    if ($line -notmatch '^([0-9a-f]{40})\s+refs/heads/(.+)$') { throw "INVALID_REMOTE_REF_LINE: $line" }
    $heads[$Matches[2]] = $Matches[1].ToUpperInvariant()
  }
  $j = Get-Content -LiteralPath $inventory -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($j.schema -cne 'sad-github-hygiene-inventory-v1' -or $j.repo -cne 'pedrogles/sad-sus-pb-data-mart' -or
      @($j.branches).Count -ne 159) { throw 'INVENTORY_SCHEMA_MISMATCH' }
  $rows = @()
  $known = @{}
  foreach($b in $j.branches) {
    $name = [string]$b.branch
    $known[$name] = $true
    $expected = ([string]$b.sha).ToUpperInvariant()
    $actual = $heads[$name]
    $decision='HOLD_REVIEW'
    if ($name -ceq 'main') { $decision='PROTECT_MAIN' }
    elseif (-not $actual) { $decision='HOLD_MISSING_REMOTE' }
    elseif ($actual -cne $expected) { $decision='HOLD_SHA_DRIFT' }
    elseif ($b.group -ceq 'MERGED_PR' -and $b.pr_head_matches_branch -eq $true) {
      $decision='CANDIDATE_AFTER_SPECIFIC_OWNER_APPROVAL'
    } elseif ($b.group -ceq 'OPEN_PR') { $decision='HOLD_OPEN_PR' }
    elseif ($b.group -ceq 'CLOSED_UNMERGED_PR') { $decision='HOLD_CLOSED_UNMERGED' }
    elseif ($b.group -ceq 'ORPHAN_NO_PR') { $decision='HOLD_NO_PR' }
    $rows += [pscustomobject]@{
      Branch=$name; Group=[string]$b.group; LinkedPr=$b.linked_pr
      SnapshotSha=$expected; RemoteSha=$actual
      PrHeadMatches=$b.pr_head_matches_branch; Decision=$decision
    }
  }
  foreach($name in $heads.Keys) {
    if (-not $known.ContainsKey($name)) {
      $rows += [pscustomobject]@{
        Branch=$name; Group='NEW_SINCE_SNAPSHOT'; LinkedPr=$null
        SnapshotSha=$null; RemoteSha=$heads[$name]
        PrHeadMatches=$null; Decision='HOLD_NEW_BRANCH'
      }
    }
  }
  if (-not (Test-Path -LiteralPath $out)) {
    $null = New-Item -ItemType Directory -Path $out -ErrorAction Stop
  }
  $stamp = (Get-Date -Format 'yyyyMMdd_HHmmss')
  $id = [Guid]::NewGuid().ToString('N').Substring(0,8)
  $csv = Join-Path $out ('sad_cleanup_dryrun_'+$stamp+'_'+$id+'.csv')
  $json = Join-Path $out ('sad_cleanup_dryrun_'+$stamp+'_'+$id+'.json')
  $rows | Sort-Object Branch | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8
  $candidates = @($rows | Where-Object {$_.Decision -eq 'CANDIDATE_AFTER_SPECIFIC_OWNER_APPROVAL'}).Count
  $blocked = @($rows | Where-Object {$_.Decision -like 'HOLD*'}).Count
  $report = [ordered]@{
    Mode='READ_ONLY'; Repository='pedrogles/sad-sus-pb-data-mart'
    CreatedAt=(Get-Date).ToString('o'); Origin=$remote
    InventoryPath=$inventory
    InventorySha256=(Get-FileHash -LiteralPath $inventory -Algorithm SHA256).Hash
    SnapshotBranches=159; RemoteBranches=$heads.Count
    MergedCandidates=$candidates; BlockedOrUnreviewed=$blocked
    Csv=$csv; NoRemoteMutations=$true
  }
  $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $json -Encoding UTF8
  Write-Output 'VERDICT=READ_ONLY_INVENTORY_COMPLETE'
  Write-Output ('REMOTE_BRANCHES='+$heads.Count)
  Write-Output ('MERGED_CANDIDATES='+$candidates)
  Write-Output ('BLOCKED_OR_UNREVIEWED='+$blocked)
  Write-Output ('REPORT_CSV='+$csv)
  Write-Output ('REPORT_JSON='+$json)
  Write-Output 'NO_REMOTE_MUTATIONS=True'
} catch {
  Write-Output 'VERDICT=BLOCKED'
  Write-Output ('DETAIL='+$_.Exception.Message)
  exit 2
}
