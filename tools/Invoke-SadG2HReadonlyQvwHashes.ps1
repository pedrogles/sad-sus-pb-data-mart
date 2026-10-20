# G2-H: 14 QVW hash/dependency audit. READ ONLY except new EvidenceRoot output.
# This script NEVER deletes, moves, saves QVW, runs QlikView/COM, or mutates Git.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$RepoRoot,
 [Parameter(Mandatory=$true)][string]$TempRoot,
 [Parameter(Mandatory=$true)][string]$G2InventoryCsv,
 [Parameter(Mandatory=$true)][string]$EvidenceRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'Windows PowerShell 5.1 required.' }

function Root([string]$path) {
 $i=Get-Item -LiteralPath $path -Force -ErrorAction Stop
 if (-not $i.PSIsContainer -or ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
  throw "Directory unavailable or reparse point: $path"
 }
 return $i.FullName.TrimEnd('\')
}
function Within([string]$path,[string]$parent) {
 return $path.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
        $path.StartsWith($parent+'\',[StringComparison]::OrdinalIgnoreCase)
}
$RepoRoot=Root $RepoRoot
$TempRoot=Root $TempRoot
$EvidenceRoot=Root $EvidenceRoot
if ((Within $EvidenceRoot $RepoRoot) -or (Within $EvidenceRoot $TempRoot) -or
    (Within $RepoRoot $EvidenceRoot) -or (Within $TempRoot $EvidenceRoot) -or
    (Within $RepoRoot $TempRoot) -or (Within $TempRoot $RepoRoot)) { throw 'Roots overlap.' }
if ($TempRoot.Equals([IO.Path]::GetPathRoot($TempRoot),[StringComparison]::OrdinalIgnoreCase)) {
 throw 'Refusing to inspect a drive root as TempRoot.'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git.exe unavailable.' }
$env:GIT_OPTIONAL_LOCKS='0'
$top=@(& git -C $RepoRoot rev-parse --show-toplevel 2>&1)
if ($LASTEXITCODE -ne 0 -or $top.Count -ne 1 -or
    -not ([IO.Path]::GetFullPath([string]$top[0])).TrimEnd('\').Replace('/','\').Equals($RepoRoot,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'RepoRoot is not Git top-level.'
}
$gitHead=@(& git -C $RepoRoot rev-parse HEAD 2>&1)
if ($LASTEXITCODE -ne 0 -or $gitHead.Count -ne 1) { throw 'Git HEAD unavailable.' }
$worktrees=@(& git -C $RepoRoot worktree list --porcelain 2>&1)
if ($LASTEXITCODE -ne 0) { throw 'Git worktrees unavailable.' }
$worktreePaths=New-Object 'System.Collections.Generic.List[string]'
foreach ($line in $worktrees) {
 if ($line -match '^worktree (.+)$') {
  $worktreePaths.Add(([IO.Path]::GetFullPath($Matches[1])).TrimEnd('\').Replace('/','\'))
 }
}
$g2file=Get-Item -LiteralPath $G2InventoryCsv -Force -ErrorAction Stop
if ($g2file.PSIsContainer -or $g2file.Extension -ine '.csv' -or
    (Within $g2file.FullName $RepoRoot) -or (Within $g2file.FullName $TempRoot)) {
 throw 'G2 inventory must be a persistent CSV outside inspected roots.'
}
$g2manifest=Get-Content -LiteralPath (Join-Path $g2file.DirectoryName 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($g2manifest.Gate -ne 'G2' -or $g2manifest.Verdict -ne 'G2_INVENTORY_READONLY_COMPLETE_SCOPE_LIMITED' -or
    [int]$g2manifest.ScanErrors -ne 0 -or
    -not ([string]$g2manifest.RepoRoot).TrimEnd('\').Equals($RepoRoot,[StringComparison]::OrdinalIgnoreCase) -or
    -not ([string]$g2manifest.TempRoot).TrimEnd('\').Equals($TempRoot,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'G2 baseline manifest invalid or roots drifted.'
}

# Immutable target ID / size selection from G2 file_inventory.csv of 2026-10-20.
$targets=@(
 'P6|2263693f848c4d24a4ac287f28d2b849|8609536'
 'P6|236f13c6364a4efab1d73f5b4817022e|8609536'
 'P6|23a408983dde4074921fe1f0279d6a74|8609536'
 'P6|3d98811e808d4fddaf703573d9aba70e|8609536'
 'P6|a27cb0583df444f6aa49da9b36c78827|8609536'
 'P6|a4478dcfd1134998acd9f02c35aa9d08|8609536'
 'P6|cf9a00663fa240ef888f68fd6926cc59|8609536'
 'P6|d3d0060b3f9542598d61567cb89b4395|8609536'
 'P6|da1fa322ccd04b1ca807e16bc5748d45|8609536'
 'P6|dac7d57791524a44a49bde1e32a63f19|8609536'
 'F4|0df1cb260ded4e8f993b18c805b45d3b|10189824'
 'F4|0e78a50bf37d455b8031125c3b32ef27|10195968'
 'F4|298e911087904f029d6f488b6d6579aa|10193408'
 'F4|4b10a021771c4301b9cfc30d9109ca38|10196736'
)
if ($targets.Count -ne 14) { throw 'Unexpected frozen target count.' }
$old=@(Import-Csv -LiteralPath $g2file.FullName -Encoding UTF8)
$inventory=@{}
foreach ($r in $old) {
 if ($r.Source -eq 'TEMP_SAD') {
  if ($inventory.ContainsKey([string]$r.FullPath)) { throw 'Duplicated G2 TEMP inventory path.' }
  $inventory[[string]$r.FullPath]=$r
 }
}
$selected=New-Object 'System.Collections.Generic.List[object]'
foreach ($t in $targets) {
 $parts=$t.Split('|');$kind=$parts[0];$id=$parts[1];$bytes=[int64]$parts[2]
 $folder=if ($kind -eq 'P6') { 'SAD_P6_E13_COM_'+$id } else { 'SAD_F4_P5_UI_GUARD_'+$id }
 $leaf=if ($kind -eq 'P6') { 'P6_E13_DISPOSABLE.qvw' } else { 'F4_P5_UI_GUARD_DISPOSABLE.qvw' }
 $relative=Join-Path $folder $leaf
 $parent=Get-Item -LiteralPath (Join-Path $TempRoot $folder) -Force -ErrorAction Stop
 if (-not $parent.PSIsContainer -or ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
  throw "Target folder link or absent: $relative"
 }
 $path=Join-Path $TempRoot $relative
 $file=Get-Item -LiteralPath $path -Force -ErrorAction Stop
 if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
  throw "Target link or non-file: $relative"
 }
 if (-not $inventory.ContainsKey($path)) { throw "Target absent from G2: $relative" }
 $ref=$inventory[$path]
 if ([int64]$file.Length -ne $bytes -or [int64]$ref.Bytes -ne $bytes -or
     $file.LastWriteTimeUtc.ToString('o') -cne [string]$ref.LastWriteUtc) {
  throw "Target changed since G2: $relative"
 }
 foreach ($wt in $worktreePaths) {
  if (Within $path $wt) { throw "Target belongs to registered Git worktree: $relative" }
 }
 $selected.Add([pscustomobject]@{Family=$kind;Folder=$folder;RelativePath=$relative;Path=$path;File=$file})
}
if (@(Get-Process -Name Qv -ErrorAction SilentlyContinue).Count -gt 0) {
 throw 'Qv.exe is running. STOP without hashing.'
}
$hashes=New-Object 'System.Collections.Generic.List[object]'
foreach ($s in $selected) {
 $preLength=[int64]$s.File.Length;$preDate=$s.File.LastWriteTimeUtc.ToString('o')
 $sha=(Get-FileHash -LiteralPath $s.Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
 $post=Get-Item -LiteralPath $s.Path -Force -ErrorAction Stop
 if ([int64]$post.Length -ne $preLength -or $post.LastWriteTimeUtc.ToString('o') -cne $preDate) {
  throw "File changed while hashing: $($s.RelativePath)"
 }
 $hashes.Add([pscustomobject]@{
  Family=$s.Family;RelativePath=$s.RelativePath;Bytes=$preLength;SHA256=$sha
 })
}
# Static literal references only. Dynamic runtime references remain UNKNOWN.
$needles=@('P6_E13_DISPOSABLE.qvw','F4_P5_UI_GUARD_DISPOSABLE.qvw','SAD_P6_E13_COM_','SAD_F4_P5_UI_GUARD_')
foreach ($s in $selected) { $needles+= $s.Folder }
$hits=New-Object 'System.Collections.Generic.List[object]'
$skips=New-Object 'System.Collections.Generic.List[object]'
$stack=New-Object 'System.Collections.Generic.Stack[string]'
foreach ($r in @('docs','tools','PAINEL','TRANSFORMACAO','EXTRACAO')) {
 $folder=Join-Path $RepoRoot $r
 if (Test-Path -LiteralPath $folder -PathType Container) { $stack.Push($folder) }
}
$readFiles=0
while ($stack.Count -gt 0) {
 foreach ($item in @(Get-ChildItem -LiteralPath ($stack.Pop()) -Force -ErrorAction Stop)) {
  if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
   $skips.Add([pscustomobject]@{Path=$item.FullName;Reason='REPARSE_NOT_FOLLOWED'});continue
  }
  if ($item.PSIsContainer) {
   if ($item.Name -ine 'QVD' -and $item.Name -ine '.git') { $stack.Push($item.FullName) }
   continue
  }
  if (@('.ps1','.qvs','.md','.json','.txt') -notcontains $item.Extension.ToLowerInvariant()) { continue }
  if ($item.Length -gt 1048576) {
   $skips.Add([pscustomobject]@{Path=$item.FullName;Reason='TEXT_OVER_1_MIB'});continue
  }
  $readFiles++
  if ($readFiles -gt 1500) { throw 'Reference scan ceiling exceeded. STOP.' }
  $content=[IO.File]::ReadAllText($item.FullName)
  foreach ($token in $needles) {
   if ($content.IndexOf($token,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
    $hits.Add([pscustomobject]@{SourceRelative=$item.FullName.Substring($RepoRoot.Length).TrimStart('\');Token=$token})
   }
  }
 }
}
# Preserve and list accessory evidence in G2 baseline; do not inspect or remove ZIP/PNG.
$sidecars=New-Object 'System.Collections.Generic.List[object]'
foreach ($s in $selected) {
 if ($s.Family -ne 'F4') { continue }
 $rootPath=(Join-Path $TempRoot $s.Folder)+'\'
 foreach ($r in $old) {
  if ($r.Source -eq 'TEMP_SAD' -and $r.FullPath.StartsWith($rootPath,[StringComparison]::OrdinalIgnoreCase) -and
      -not $r.FullPath.Equals($s.Path,[StringComparison]::OrdinalIgnoreCase)) {
   $sidecars.Add([pscustomobject]@{RelativePath=$r.FullPath.Substring($TempRoot.Length).TrimStart('\');Bytes=[int64]$r.Bytes;Disposition='PRESERVE_UNTIL_REVIEW'})
  }
 }
}
$dups=New-Object 'System.Collections.Generic.List[object]'
foreach ($grp in @($hashes | Group-Object SHA256)) {
 if ($grp.Count -lt 2) { continue }
 foreach ($row in $grp.Group) {
  $dups.Add([pscustomobject]@{SHA256=$grp.Name;Count=$grp.Count;Family=$row.Family;RelativePath=$row.RelativePath;Bytes=$row.Bytes})
 }
}
# The only writes: new private evidence directory under an existing EvidenceRoot.
$output=Join-Path $EvidenceRoot ('G2_H_HASH_'+(Get-Date -Format yyyyMMdd_HHmmss)+'_'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $output -ErrorAction Stop | Out-Null
$hashes.ToArray() | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $output 'qvw_hashes.csv')
$sidecars.ToArray() | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $output 'f4_sidecars_preserve.csv')
if ($dups.Count -gt 0) {
 $dups.ToArray() | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $output 'identical_sha_groups.csv')
} else { 'SHA256,Count,Family,RelativePath,Bytes' | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $output 'identical_sha_groups.csv') }
if ($hits.Count -gt 0) {
 $hits.ToArray() | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $output 'static_references.csv')
} else { 'SourceRelative,Token' | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $output 'static_references.csv') }
if ($skips.Count -gt 0) {
 $skips.ToArray() | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $output 'static_scan_skipped.csv')
} else { 'Path,Reason' | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $output 'static_scan_skipped.csv') }
$manifest=[ordered]@{
 Gate='G2-H';Verdict='G2_H_HASHES_COMPLETE_DEPENDENCIES_NOT_PROVEN';
 GitHead=[string]$gitHead[0];TimeUtc=(Get-Date).ToUniversalTime().ToString('o');
 RepoRoot=$RepoRoot;TempRoot=$TempRoot;G2Inventory=$g2file.FullName;EvidenceDirectory=$output;
 ScriptSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash;
 HashedQVWs=$hashes.Count;IdenticalGroupCount=(@($dups | Select-Object -ExpandProperty SHA256 -Unique)).Count;
 ReferenceFilesRead=$readFiles;LiteralReferenceRows=$hits.Count;ReferenceScanSkips=$skips.Count;
 F4SidecarsMarkedPreserve=$sidecars.Count;DeletionApproved=$false;
 Notes=@('Bytewise equal SHA256 is not deletion approval.','Search for literal references is non-exhaustive.','All evidence, QVWs, worktrees and backups remain preserved.')
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $output 'manifest.json')
Write-Output "VERDICT=$($manifest.Verdict)"
Write-Output "HASHED_QVWS=$($hashes.Count) IDENTICAL_SHA_GROUPS=$($manifest.IdenticalGroupCount) STATIC_REFERENCES=$($hits.Count)"
Write-Output "EVIDENCE_DIR=$output"
