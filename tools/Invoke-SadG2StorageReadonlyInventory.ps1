# SAD G2 - local storage inventory, READ-ONLY to inspected inputs.
# No Delete/Move/Copy/Reload/Store/COM. The sole write is a fresh private evidence subfolder.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [string]$TempRoot = $env:TEMP,
    [ValidateRange(1,500000)][int]$MaxFiles = 200000
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'Windows PowerShell 5.1 or newer required.' }

function Resolve-ExistingDirectory([string]$InputPath, [string]$Purpose) {
    if ([string]::IsNullOrWhiteSpace($InputPath)) { throw "$Purpose missing." }
    $item = Get-Item -LiteralPath $InputPath -Force -ErrorAction Stop
    if (-not $item.PSIsContainer) { throw "$Purpose must be an existing directory." }
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Purpose must not be a link/junction/reparse-point root."
    }
    return $item.FullName.TrimEnd('\')
}
function Is-Within([string]$Candidate, [string]$Parent) {
    return ($Candidate.Equals($Parent,[StringComparison]::OrdinalIgnoreCase) -or
            $Candidate.StartsWith($Parent + '\',[StringComparison]::OrdinalIgnoreCase))
}
$RepoRoot = Resolve-ExistingDirectory $RepoRoot 'RepoRoot'
$TempRoot = Resolve-ExistingDirectory $TempRoot 'TempRoot'
$EvidenceRoot = Resolve-ExistingDirectory $EvidenceRoot 'EvidenceRoot'
if ((Is-Within $EvidenceRoot $RepoRoot) -or (Is-Within $EvidenceRoot $TempRoot) -or
    (Is-Within $RepoRoot $EvidenceRoot) -or (Is-Within $TempRoot $EvidenceRoot)) {
    throw 'EvidenceRoot must be separate from RepoRoot and TempRoot, without overlap.'
}
if ($RepoRoot.Equals($TempRoot,[StringComparison]::OrdinalIgnoreCase) -or
    (Is-Within $RepoRoot $TempRoot) -or (Is-Within $TempRoot $RepoRoot)) {
    throw 'RepoRoot and TempRoot must be separate.'
}
if ($TempRoot.Equals([IO.Path]::GetPathRoot($TempRoot),[StringComparison]::OrdinalIgnoreCase)) {
    throw 'Refusing to enumerate an entire drive root as TempRoot.'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git.exe not available.' }
$env:GIT_OPTIONAL_LOCKS = '0'
$gitTop = @(& git -C $RepoRoot rev-parse --show-toplevel 2>&1)
if ($LASTEXITCODE -ne 0 -or $gitTop.Count -ne 1) { throw 'RepoRoot is not a readable Git worktree.' }
$normalizedGitTop = ([IO.Path]::GetFullPath([string]$gitTop[0])).TrimEnd('\').Replace('/','\')
if (-not $normalizedGitTop.Equals($RepoRoot,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'RepoRoot does not match git rev-parse --show-toplevel.'
}
$gitHead = @(& git -C $RepoRoot rev-parse HEAD 2>&1)
if ($LASTEXITCODE -ne 0 -or $gitHead.Count -ne 1) { throw 'Cannot read local Git HEAD.' }
$worktreeLines = @(& git -C $RepoRoot worktree list --porcelain 2>&1)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read Git worktree list.' }
$gitStatus = @(& git -C $RepoRoot status --porcelain=v1 --untracked-files=all 2>&1)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read Git status.' }
$worktreePaths = New-Object System.Collections.Generic.List[string]
foreach ($line in $worktreeLines) {
    if ($line -match '^worktree (.+)$') {
        $worktreePaths.Add(([IO.Path]::GetFullPath($Matches[1])).TrimEnd('\').Replace('/','\'))
    }
}
$script:Rows = New-Object System.Collections.Generic.List[object]
$script:Skipped = New-Object System.Collections.Generic.List[object]
$script:Problems = New-Object System.Collections.Generic.List[object]
$script:FileCount = 0
function Inspect-File([System.IO.FileInfo]$File, [string]$Base, [string]$Source) {
    $script:FileCount++
    if ($script:FileCount -gt $MaxFiles) { throw "MAX_FILES_EXCEEDED=$MaxFiles; STOP, do not infer completeness." }
    $rel = $File.FullName.Substring($Base.Length).TrimStart('\')
    $group = @($rel -split '\\')[0]
    $category = 'REVIEW_UNCLASSIFIED_NOT_APPROVED_FOR_DELETION'
    $reason = 'Insufficient proof of redundancy or recovery.'
    $isWorktree = $false
    foreach ($wt in $worktreePaths) {
        if ($Source -eq 'TEMP_SAD' -and (Is-Within $File.FullName $wt)) { $isWorktree = $true; break }
    }
    if ($isWorktree) {
        $category = 'PRESERVE_ACTIVE_OR_REGISTERED_WORKTREE'
        $reason = 'Git worktree registered; cleanup requires separate Git-aware review.'
    } elseif ($Source -eq 'TEMP_SAD') {
        $category = 'REVIEW_TEMP_CANDIDATE_NOT_APPROVED'
        $reason = 'SAD-labelled temp file; test/evidence dependencies and duplicates not reconciled.'
    } elseif ($rel -match '^(?i:BASE)\\' -or
              $rel -match '^(?i:EXTRACAO|TRANSFORMACAO)\\(?i:QVD)\\' -or
              $rel -ieq 'EXTRACAO\EXT.qvw' -or
              $rel -ieq 'TRANSFORMACAO\TRANSF.qvw' -or
              $rel -ieq 'PAINEL\PAINEL.qvw' -or
              $File.Extension -ieq '.qvd') {
        $category = 'PRESERVE_SOURCE_OR_CANONICAL'
        $reason = 'Source, canonical QVW/QVD or other QVD: never delete under G2.'
    } elseif ($rel -match '(?i)(evidence|evidenc|manifest|backup|retention|rollback|stabilization|oracle|oraculo|F1_|F2_|F3_)') {
        $category = 'PRESERVE_EVIDENCE_OR_BACKUP'
        $reason = 'Evidence or backup name: preserve until dependency audit.'
    } elseif ($File.Extension -ieq '.qvw' -or $File.Extension -ieq '.dbc' -or
              $File.Extension -ieq '.dbf' -or $File.Extension -ieq '.csv') {
        $category = 'PRESERVE_DATA_OR_TEST_UNTIL_RECONCILED'
        $reason = 'Potential nonreproducible data or test asset.'
    }
    $script:Rows.Add([pscustomobject]@{
        Source=$Source; RelativePath=$rel; Group=$group;
        FullPath=$File.FullName; Bytes=[int64]$File.Length;
        LastWriteUtc=$File.LastWriteTimeUtc.ToString('o');
        Category=$category; Explanation=$reason
    })
}
function Scan-Directory([string]$Base, [string]$Source) {
    $stack = New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push($Base)
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        try { $children = @(Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop) }
        catch {
            $script:Problems.Add([pscustomobject]@{Source=$Source;Path=$current;Error=$_.Exception.Message})
            continue
        }
        foreach ($child in $children) {
            $rel = $child.FullName.Substring($Base.Length).TrimStart('\')
            if ($Source -eq 'REPO' -and ($rel -ieq '.git' -or $rel -ilike '.git\*')) {
                $script:Skipped.Add([pscustomobject]@{Source=$Source;Path=$child.FullName;Reason='Git internals deliberately excluded'})
                continue
            }
            if (($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                $script:Skipped.Add([pscustomobject]@{Source=$Source;Path=$child.FullName;Reason='Link/junction/reparse-point not followed'})
                continue
            }
            if ($child.PSIsContainer) { $stack.Push($child.FullName) }
            elseif ($child -is [System.IO.FileInfo]) { Inspect-File $child $Base $Source }
        }
    }
}
Scan-Directory $RepoRoot 'REPO'
$selectedTemp = New-Object System.Collections.Generic.List[string]
try { $tempEntries = @(Get-ChildItem -LiteralPath $TempRoot -Force -ErrorAction Stop) }
catch { throw "Cannot enumerate TempRoot top level: $($_.Exception.Message)" }
foreach ($entry in $tempEntries) {
    if ($entry.Name -notmatch '^(?i:SAD|SUS[_-]PB)(?:[_-]|$)') { continue }
    if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        $script:Skipped.Add([pscustomobject]@{Source='TEMP_SAD';Path=$entry.FullName;Reason='Top-level reparse-point not followed'})
        continue
    }
    $selectedTemp.Add($entry.FullName)
    if ($entry.PSIsContainer) { Scan-Directory $entry.FullName 'TEMP_SAD' }
    elseif ($entry -is [System.IO.FileInfo]) { Inspect-File $entry $TempRoot 'TEMP_SAD' }
}
# Evidence output is the ONLY filesystem mutation; no operation targets the inspected paths.
$runName = 'G2_INVENTORY_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N')
$out = Join-Path $EvidenceRoot $runName
New-Item -ItemType Directory -Path $out -ErrorAction Stop | Out-Null
$script:Rows | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $out 'file_inventory.csv')
$script:Skipped | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $out 'skipped_paths.csv')
$script:Problems | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $out 'scan_errors.csv')
$gitStatus | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $out 'git_status.txt')
$worktreeLines | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $out 'git_worktrees.txt')
$groups = @($script:Rows | Group-Object Source,Group | ForEach-Object {
    $g = $_.Group
    $sum = [int64]0
    foreach ($item in $g) { $sum += $item.Bytes }
    [pscustomobject]@{Source=$g[0].Source;Group=$g[0].Group;FileCount=$g.Count;Bytes=$sum}
})
$groups | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $out 'directory_summary.csv')
$reviewBytes = [int64]0
foreach ($item in $script:Rows) { if ($item.Category -eq 'REVIEW_TEMP_CANDIDATE_NOT_APPROVED') { $reviewBytes += $item.Bytes } }
$verdict = if ($script:Problems.Count -gt 0) { 'G2_INCONCLUSIVE_SCAN_ERRORS' } else { 'G2_INVENTORY_READONLY_COMPLETE_SCOPE_LIMITED' }
$manifest = [ordered]@{
    Gate='G2'; Verdict=$verdict; TimestampUtc=(Get-Date).ToUniversalTime().ToString('o')
    GitHead=[string]$gitHead[0]; RepoRoot=$RepoRoot; TempRoot=$TempRoot; EvidenceDirectory=$out
    FileCount=$script:FileCount; TempSadRoots=@($selectedTemp.ToArray())
    SkippedCount=$script:Skipped.Count; ScanErrors=$script:Problems.Count
    ReviewTempBytesNotRecoverableEstimate=$reviewBytes
    ScriptSha256=([string](Get-FileHash -Algorithm SHA256 -LiteralPath $PSCommandPath).Hash)
    Notes=@(
        'No deletion, relocation, QlikView COM, reload or Git mutation performed by this script.',
        'Only SAD-named first-level TEMP roots were scanned; unlabelled temp locations excluded.',
        'ReviewTempBytes is an upper-bound metadata total, NOT demonstrated reclaimable space.',
        'Links/junctions skipped; evidence, manifests, QVW/QVD, BASE and registered worktrees retained.'
    )
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $out 'manifest.json')
Write-Output "VERDICT=$verdict"
Write-Output "FILES=$($script:FileCount) TEMP_SAD_ROOTS=$($selectedTemp.Count) SKIPPED=$($script:Skipped.Count) ERRORS=$($script:Problems.Count)"
Write-Output "REVIEW_TEMP_BYTES_NOT_RECOVERABLE_ESTIMATE=$reviewBytes"
Write-Output "EVIDENCE_DIR=$out"
if ($script:Problems.Count -gt 0) { exit 2 }
