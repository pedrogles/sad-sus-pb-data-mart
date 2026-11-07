#requires -Version 5.1
<#
.SYNOPSIS
  M1 read-only inventory of the 25 canonical SAD artifacts.
.DESCRIPTION
  Never opens QlikView, changes QVD/QVW files, calls COM, reloads, restores, or
  runs CREATE. Writes only a CSV and a TXT report inside the explicit EvidenceRoot,
  which must be outside the repository and outside the backup directory.
  An optional BackupRoot enables SHA-256 byte comparison to the preserved backup.
  This cannot validate QVD semantics, source lineage or UI.
.EXAMPLE
  powershell.exe -NoProfile -File tools\m1-inventario-artefatos-readonly.ps1 `
    -RepoRoot (Get-Location).Path -EvidenceRoot "D:\SAD_EVIDENCIAS" `
    -BackupRoot "D:\SAD_STABILIZATION_01_20261020\backup"
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [string]$BackupRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingDirectory([string]$PathValue, [string]$Role) {
  $item = Get-Item -LiteralPath $PathValue -ErrorAction Stop
  if (-not $item.PSIsContainer) { throw "$Role must be a directory: $PathValue" }
  return [System.IO.Path]::GetFullPath($item.FullName).TrimEnd('\', '/')
}
function Is-UnderPath([string]$Candidate, [string]$Parent) {
  $parentNormalized = $Parent.TrimEnd('\', '/')
  $prefix = $parentNormalized + [System.IO.Path]::DirectorySeparatorChar
  return $Candidate.Equals($parentNormalized,[StringComparison]::OrdinalIgnoreCase) -or
    $Candidate.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)
}

$root = Resolve-ExistingDirectory $RepoRoot 'RepoRoot'
$evidence = [System.IO.Path]::GetFullPath($EvidenceRoot).TrimEnd('\', '/')
if (Is-UnderPath $evidence $root) {
  throw 'EvidenceRoot must not be inside RepoRoot.'
}
$backup = $null
if (-not [string]::IsNullOrWhiteSpace($BackupRoot)) {
  $backup = Resolve-ExistingDirectory $BackupRoot 'BackupRoot'
  if ((Is-UnderPath $evidence $backup) -or (Is-UnderPath $backup $root) -or
      (Is-UnderPath $backup $evidence)) {
    throw 'BackupRoot and EvidenceRoot must be separate from each other and RepoRoot.'
  }
}
if (-not (Test-Path -LiteralPath (Join-Path $root 'AGENTS.md') -PathType Leaf)) {
  throw 'Missing AGENTS.md: RepoRoot is not the expected repository.'
}

$entries = @(
  'EXTRACAO/QVD/SRC_SIH_RD.qvd',
  'EXTRACAO/QVD/SRC_CNES_LT.qvd',
  'EXTRACAO/QVD/SRC_CNES_ST.qvd',
  'EXTRACAO/QVD/SRC_IBGE_POPULACAO.qvd',
  'EXTRACAO/QVD/REF_CARATER_ATENDIMENTO.qvd',
  'EXTRACAO/QVD/REF_MOTIVO_SAIDA.qvd',
  'EXTRACAO/QVD/REF_CID10.qvd',
  'EXTRACAO/QVD/REF_SIGTAP.qvd',
  'EXTRACAO/QVD/REF_TIPO_LEITO.qvd',
  'EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.qvd',
  'TRANSFORMACAO/QVD/DIM_TEMPO.qvd',
  'TRANSFORMACAO/QVD/DIM_MUNICIPIO.qvd',
  'TRANSFORMACAO/QVD/DIM_ESTABELECIMENTO.qvd',
  'TRANSFORMACAO/QVD/DIM_PROCEDIMENTO.qvd',
  'TRANSFORMACAO/QVD/DIM_DIAGNOSTICO.qvd',
  'TRANSFORMACAO/QVD/DIM_CARATER_ATENDIMENTO.qvd',
  'TRANSFORMACAO/QVD/DIM_MOTIVO_SAIDA_PERMANENCIA.qvd',
  'TRANSFORMACAO/QVD/DIM_TIPO_LEITO.qvd',
  'TRANSFORMACAO/QVD/FATO_INTERNACAO.qvd',
  'TRANSFORMACAO/QVD/FATO_CAPACIDADE_LEITO.qvd',
  'TRANSFORMACAO/QVD/FATO_POPULACAO.qvd',
  'TRANSFORMACAO/QVD/LINK_ANALISE.qvd',
  'EXTRACAO/EXT.qvw',
  'TRANSFORMACAO/TRANSF.qvw',
  'PAINEL/PAINEL.qvw'
)
if ($entries.Count -ne 25 -or @($entries | Select-Object -Unique).Count -ne 25) {
  throw 'Invalid embedded inventory contract: expected 25 distinct paths.'
}
$items = New-Object System.Collections.Generic.List[object]
foreach ($relative in $entries) {
  $sourcePath = Join-Path $root ($relative.Replace('/',[System.IO.Path]::DirectorySeparatorChar))
  $exists = Test-Path -LiteralPath $sourcePath -PathType Leaf
  $sha = ''
  $bytes = $null
  $backupSha = ''
  $backupExists = $false
  $status = 'MISSING'
  if ($exists) {
    try {
      $file = Get-Item -LiteralPath $sourcePath -ErrorAction Stop
      $bytes = [long]$file.Length
      $sha = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
      $status = 'PRESENT_UNVERIFIED'
    } catch {
      $status = 'READ_ERROR'
    }
  }
  if ($null -ne $backup) {
    $copyPath = Join-Path $backup ($relative.Replace('/',[System.IO.Path]::DirectorySeparatorChar))
    $backupExists = Test-Path -LiteralPath $copyPath -PathType Leaf
    if ($backupExists) {
      try {
        $backupSha = (Get-FileHash -LiteralPath $copyPath -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()
        if ($status -eq 'PRESENT_UNVERIFIED') {
          if ($sha -eq $backupSha) { $status = 'MATCH_BACKUP_BYTES' }
          else { $status = 'HASH_MISMATCH' }
        }
      } catch {
        $status = 'BACKUP_READ_ERROR'
      }
    } elseif ($status -eq 'PRESENT_UNVERIFIED') {
      $status = 'BACKUP_MISSING'
    }
  }
  $items.Add([pscustomobject]@{
    RelativePath=$relative
    SourceExists=[bool]$exists
    SourceBytes=$bytes
    SourceSha256=$sha
    BackupExists=[bool]$backupExists
    BackupSha256=$backupSha
    Status=$status
  })
}

$missing = @($items | Where-Object { $_.Status -in @('MISSING','READ_ERROR','BACKUP_READ_ERROR','BACKUP_MISSING','HASH_MISMATCH') })
$matched = @($items | Where-Object { $_.Status -eq 'MATCH_BACKUP_BYTES' }).Count
$present = @($items | Where-Object { $_.SourceExists }).Count
$verdict = if ($missing.Count -gt 0) { 'BLOCKED_OR_INCONCLUSIVE_ARTIFACTS' }
  elseif ($null -eq $backup) { 'PRESENT_25_NOT_COMPARED_TO_BACKUP' }
  elseif ($matched -eq 25) { 'MATCHED_25_BACKUP_BYTES_NOT_QVD_SEMANTIC' }
  else { 'INCONCLUSIVE_BACKUP_COMPARISON' }

# Write evidence only *after* all source/backup reads. Never write into the repo.
if (-not (Test-Path -LiteralPath $evidence -PathType Container)) {
  $null = New-Item -ItemType Directory -Path $evidence -Force
}
$runName = 'SAD_M1_ARTIFACTS_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)
$output = Join-Path $evidence $runName
$null = New-Item -ItemType Directory -Path $output -ErrorAction Stop
$csv = Join-Path $output 'artifact-inventory.csv'
$txt = Join-Path $output 'summary.txt'
$items | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8

$scriptHash = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToUpperInvariant()
$head = 'NOT_VERIFIED'
if (Get-Command git -ErrorAction SilentlyContinue) {
  try {
    $value = (& git -C $root rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $value) { $head = [string]$value }
  } catch { $head = 'NOT_VERIFIED' }
}
$summary = @(
  "VERDICT=$verdict",
  "EXPECTED=25",
  "PRESENT=$present",
  "MATCHING_BACKUP_BYTES=$matched",
  "ISSUES=$($missing.Count)",
  "GIT_HEAD=$head",
  "SCRIPT_SHA256=$scriptHash",
  "BACKUP_COMPARISON=$([bool]($null -ne $backup))",
  "CSV=$csv",
  "LIMITATION=FILE_PRESENCE_AND_HASHES_ONLY_NOT_QVD_RELOAD_ASSOCIATIONS_OR_UI"
)
$summary | Set-Content -LiteralPath $txt -Encoding UTF8
$summary | ForEach-Object { Write-Output $_ }
if ($missing.Count -gt 0) { exit 2 }
if ($null -eq $backup) { exit 3 }
if ($matched -ne 25) { exit 4 }
exit 0
