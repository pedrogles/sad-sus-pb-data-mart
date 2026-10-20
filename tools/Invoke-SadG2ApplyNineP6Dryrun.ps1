# SAD G2-APPLY DRY-RUN ONLY: exact nine P6 E13 QVWs.
# NEVER deletes, moves, copies, renames, overwrites, or opens a QVW in QlikView.
# Only allowed writes: a fresh report directory under a persistent EvidenceRoot.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$RepoRoot,
 [Parameter(Mandatory=$true)][string]$TempRoot,
 [Parameter(Mandatory=$true)][string]$G2HEvidenceDir,
 [Parameter(Mandatory=$true)][string]$EvidenceRoot,
 [string]$RecoveryCopyPath = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 5) { throw 'PowerShell 5.1+ required.' }
function ExistingDir([string]$Path,[string]$Name) {
 $i=Get-Item -LiteralPath $Path -Force -ErrorAction Stop
 if (-not $i.PSIsContainer -or (($i.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
  throw "$Name must be a regular existing directory."
 }
 return $i.FullName.TrimEnd('\')
}
function IsWithin([string]$Path,[string]$Root) {
 return $Path.Equals($Root,[StringComparison]::OrdinalIgnoreCase) -or
        $Path.StartsWith($Root+'\',[StringComparison]::OrdinalIgnoreCase)
}
function RegularFile([string]$Path,[string]$Role) {
 $i=Get-Item -LiteralPath $Path -Force -ErrorAction Stop
 if ($i.PSIsContainer -or (($i.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
  throw "$Role is not a regular file: $Path"
 }
 return $i
}
$RepoRoot=ExistingDir $RepoRoot 'RepoRoot'
$TempRoot=ExistingDir $TempRoot 'TempRoot'
$EvidenceRoot=ExistingDir $EvidenceRoot 'EvidenceRoot'
$G2HEvidenceDir=ExistingDir $G2HEvidenceDir 'G2HEvidenceDir'
if ((IsWithin $RepoRoot $TempRoot) -or (IsWithin $TempRoot $RepoRoot) -or
    (IsWithin $EvidenceRoot $RepoRoot) -or (IsWithin $EvidenceRoot $TempRoot) -or
    (IsWithin $RepoRoot $EvidenceRoot) -or (IsWithin $TempRoot $EvidenceRoot) -or
    -not (IsWithin $G2HEvidenceDir $EvidenceRoot)) {
 throw 'Unexpected root overlap or G2H evidence outside persistent EvidenceRoot.'
}
if ($TempRoot.Equals([IO.Path]::GetPathRoot($TempRoot),[StringComparison]::OrdinalIgnoreCase)) {
 throw 'Refusing drive-root TempRoot.'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git unavailable.' }
$env:GIT_OPTIONAL_LOCKS='0'
$gitTop=@(& git -C $RepoRoot rev-parse --show-toplevel 2>&1)
if ($LASTEXITCODE -ne 0 -or $gitTop.Count -ne 1 -or
    -not ([IO.Path]::GetFullPath([string]$gitTop[0])).TrimEnd('\').Replace('/','\').Equals($RepoRoot,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'RepoRoot does not match Git top-level.'
}
$gitHead=@(& git -C $RepoRoot rev-parse HEAD 2>&1)
if ($LASTEXITCODE -ne 0 -or $gitHead.Count -ne 1) { throw 'Git HEAD unavailable.' }
$wtLines=@(& git -C $RepoRoot worktree list --porcelain 2>&1)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read registered worktrees.' }
$wtPaths=New-Object 'System.Collections.Generic.List[string]'
foreach ($line in $wtLines) {
 if ($line -match '^worktree (.+)$') {
  $wtPaths.Add(([IO.Path]::GetFullPath($Matches[1])).TrimEnd('\').Replace('/','\'))
 }
}
if (@(Get-Process -Name Qv -ErrorAction SilentlyContinue).Count -gt 0) {
 throw 'QlikView Qv.exe is running. Close it and request a new preflight.'
}
$expectedSha='F75786A88E7563B739492F2D2BC7C5CEA50D8C7F8E73F36770AA76960FB668C6'
$expectedBytes=[int64]8609536
$retainedId='2263693f848c4d24a4ac287f28d2b849'
$candidateIds=@(
 '236f13c6364a4efab1d73f5b4817022e'
 '23a408983dde4074921fe1f0279d6a74'
 '3d98811e808d4fddaf703573d9aba70e'
 'a27cb0583df444f6aa49da9b36c78827'
 'a4478dcfd1134998acd9f02c35aa9d08'
 'cf9a00663fa240ef888f68fd6926cc59'
 'd3d0060b3f9542598d61567cb89b4395'
 'da1fa322ccd04b1ca807e16bc5748d45'
 'dac7d57791524a44a49bde1e32a63f19'
)
if ($candidateIds.Count -ne 9 -or @($candidateIds | Select-Object -Unique).Count -ne 9) {
 throw 'Frozen candidate set invalid.'
}
$hmanifest=Get-Content -LiteralPath (Join-Path $G2HEvidenceDir 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($hmanifest.Gate -ne 'G2-H' -or
    $hmanifest.Verdict -ne 'G2_H_HASHES_COMPLETE_DEPENDENCIES_NOT_PROVEN' -or
    [int]$hmanifest.HashedQVWs -ne 14 -or [int]$hmanifest.IdenticalGroupCount -ne 1 -or
    [bool]$hmanifest.DeletionApproved -ne $false -or
    -not ([string]$hmanifest.TempRoot).TrimEnd('\').Equals($TempRoot,[StringComparison]::OrdinalIgnoreCase) -or
    -not ([string]$hmanifest.RepoRoot).TrimEnd('\').Equals($RepoRoot,[StringComparison]::OrdinalIgnoreCase)) {
 throw 'G2-H manifest is not the approved read-only baseline.'
}
$hashFile=RegularFile (Join-Path $G2HEvidenceDir 'qvw_hashes.csv') 'G2-H hashes'
$prior=@(Import-Csv -LiteralPath $hashFile.FullName -Encoding UTF8)
if ($prior.Count -ne 14) { throw 'Expected 14 G2-H hash rows.' }
$lookup=@{}
foreach ($r in $prior) {
 if ($lookup.ContainsKey([string]$r.RelativePath)) { throw 'Duplicate G2-H relative path.' }
 $lookup[[string]$r.RelativePath]=$r
}
function RelativeFor([string]$id) {
 return 'SAD_P6_E13_COM_'+$id+'\P6_E13_DISPOSABLE.qvw'
}
$allIds=@($retainedId)+$candidateIds
if ($allIds.Count -ne 10) { throw 'Expected 10 P6 file identities.' }
foreach ($id in $allIds) {
 $rel=RelativeFor $id
 if (-not $lookup.ContainsKey($rel)) { throw "Missing in G2-H: $rel" }
 $p=$lookup[$rel]
 if ($p.Family -ne 'P6' -or [int64]$p.Bytes -ne $expectedBytes -or
     -not ([string]$p.SHA256).Equals($expectedSha,[StringComparison]::OrdinalIgnoreCase)) {
  throw "G2-H metadata mismatch: $rel"
 }
}
$validated=New-Object 'System.Collections.Generic.List[object]'
foreach ($id in $allIds) {
 $folder='SAD_P6_E13_COM_'+$id
 $dir=ExistingDir (Join-Path $TempRoot $folder) "Target folder $id"
 $rel=RelativeFor $id
 $path=Join-Path $TempRoot $rel
 $i=RegularFile $path 'P6 QVW'
 foreach ($wt in $wtPaths) {
  if (IsWithin $path $wt) { throw "Registered worktree intersects target: $rel" }
 }
 if ([int64]$i.Length -ne $expectedBytes) { throw "Size changed: $rel" }
 # The nine candidate directories must contain EXACTLY one file (even hidden).
 if ($id -ne $retainedId) {
  $items=@(Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop)
  if ($items.Count -ne 1 -or -not $items[0].FullName.Equals($path,[StringComparison]::OrdinalIgnoreCase)) {
   throw "Additional contents or unexpected path in candidate directory: $folder"
  }
 }
 $beforeTime=$i.LastWriteTimeUtc.ToString('o')
 $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
 $after=RegularFile $path 'P6 QVW after hash'
 if ($after.Length -ne $expectedBytes -or $after.LastWriteTimeUtc.ToString('o') -cne $beforeTime -or
     -not $hash.Equals($expectedSha,[StringComparison]::OrdinalIgnoreCase)) {
  throw "Hash/time changed or mismatched: $rel"
 }
 $validated.Add([pscustomobject]@{
  Disposition=$(if ($id -eq $retainedId) {'PRESERVE_RETAINED'} else {'DRYRUN_CANDIDATE_NOT_APPROVED'});
  RelativeToTemp=$rel; FullPath=$path; Bytes=$expectedBytes; SHA256=$hash;
  FreshHashConfirmed=$true; FolderHasOnlyTarget=$(if ($id -eq $retainedId) {'NOT_CHECKED'} else {'YES'})
 })
}
$copyStatus='BACKUP_NOT_SUPPLIED'
$copyPath=''
if (-not [string]::IsNullOrWhiteSpace($RecoveryCopyPath)) {
 $copy=RegularFile $RecoveryCopyPath 'Recovery copy'
 if ((IsWithin $copy.FullName $TempRoot) -or (IsWithin $copy.FullName $RepoRoot)) {
  throw 'Recovery copy must be outside REPO/TEMP.'
 }
 $backupSha=(Get-FileHash -LiteralPath $copy.FullName -Algorithm SHA256).Hash
 if ($copy.Length -ne $expectedBytes -or
     -not $backupSha.Equals($expectedSha,[StringComparison]::OrdinalIgnoreCase)) {
  throw 'Recovery copy content does not match retained P6 QVW.'
 }
 $copyStatus='BACKUP_VERIFIED_BYTEWISE_LOCAL_ONLY'
 $copyPath=$copy.FullName
}
$runDir=Join-Path $EvidenceRoot ('G2_APPLY_DRYRUN_'+(Get-Date -Format 'yyyyMMdd_HHmmss')+'_'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runDir -ErrorAction Stop | Out-Null
$validated.ToArray() | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $runDir 'preflight_10_qvws.csv')
$recoveryRows=foreach ($v in $validated) {
 if ($v.Disposition -eq 'PRESERVE_RETAINED') { continue }
 [pscustomobject]@{
  RestoreTo=$v.FullPath; RestoreFrom=$(if ($copyPath) {$copyPath} else {'PENDING_VERIFIED_PERSISTENT_COPY'});
  RequiredSHA256=$expectedSha; RequiredBytes=$expectedBytes;
  RestoreRule='Future separate approval: empty destination only, never overwrite, verify SHA256; no operation in dry-run'
 }
}
@($recoveryRows) | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath (Join-Path $runDir 'rollback_plan.csv')
$manifest=[ordered]@{
 Gate='G2-APPLY-DRYRUN';Verdict='G2_APPLY_DRYRUN_VERIFIED_NO_DELETION_APPROVAL';
 TimeUtc=(Get-Date).ToUniversalTime().ToString('o');GitHead=[string]$gitHead[0];
 G2HEvidence=$G2HEvidenceDir;EvidenceDirectory=$runDir;
 Candidates=9;Retained=1;PotentialBytesNotGuaranteed=([int64]9*$expectedBytes);
 RequiredSHA256=$expectedSha;BackupStatus=$copyStatus;
 RecoveryCopyPath=$copyPath;DeletionApproved=$false;WritesToSourceOrTemp=$false;
 ScriptSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash;
 Notes=@(
  'Dry-run only. Nothing deleted, moved, copied, restored, renamed or opened in QlikView.',
  'G2-H literal reference scan did not establish absence of dynamic dependencies.',
  'Rollback requires a separately approved verified persistent recovery copy BEFORE any APPLY.',
  'Retained copy and 9 candidates are all preserved by this script.',
  'LOCAL_COPY_ONLY on same disk is not disaster recovery.'
 )
}
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $runDir 'manifest.json')
Write-Output "VERDICT=$($manifest.Verdict)"
Write-Output "CANDIDATES_VERIFIED=9 RETAINED_VERIFIED=1"
Write-Output "BACKUP_STATUS=$copyStatus"
Write-Output "POTENTIAL_BYTES_NOT_GUARANTEED=$($manifest.PotentialBytesNotGuaranteed)"
Write-Output "EVIDENCE_DIR=$runDir"
