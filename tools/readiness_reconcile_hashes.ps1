param(
    [Parameter(Mandatory=$true)]
    [string]$ZipPath,

    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,

    [string]$DataRoot = "",

    [string]$ManifestEntry = "manifesto-execucao.json",

    [string]$OutputJson = "",

    [string]$OutputCsv = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($DataRoot)) {
    $DataRoot = Join-Path $RepoRoot "BASE"
}

if ([string]::IsNullOrWhiteSpace($OutputJson)) {
    $OutputJson = Join-Path $RepoRoot "BASE\CONVERTIDA\readiness-hash-reconciliation.json"
}

if ([string]::IsNullOrWhiteSpace($OutputCsv)) {
    $OutputCsv = Join-Path $RepoRoot "BASE\CONVERTIDA\readiness-hash-reconciliation.csv"
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
    throw "Acquisition ZIP not found: $ZipPath"
}

if (-not (Test-Path -LiteralPath $DataRoot)) {
    throw "Data root not found: $DataRoot"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Read-ZipEntryText {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ArchivePath,
        [Parameter(Mandatory=$true)]
        [string]$EntryName
    )

    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $entry = $archive.GetEntry($EntryName)
        if ($null -eq $entry) {
            throw "Entry '$EntryName' not found in '$ArchivePath'."
        }

        $reader = New-Object IO.StreamReader($entry.Open())
        try {
            return $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $archive.Dispose()
    }
}

$manifestText = Read-ZipEntryText -ArchivePath $ZipPath -EntryName $ManifestEntry
$manifest = $manifestText | ConvertFrom-Json

if ($null -eq $manifest.items) {
    throw "Manifest has no 'items' object."
}

$manifestProperties = @($manifest.items.PSObject.Properties)

$dbcNamePattern = '^(RD|LT|ST)PB(17|18|19)(0[1-9]|1[0-2])\.dbc$'
$manifestNames = @($manifestProperties.Name)

$invalidManifestNames = @(
    $manifestNames | Where-Object { $_ -notmatch $dbcNamePattern }
)

$manifestMissingHash = New-Object System.Collections.Generic.List[string]
$manifestInvalidHash = New-Object System.Collections.Generic.List[string]
$manifestMissingSize = New-Object System.Collections.Generic.List[string]

foreach ($property in $manifestProperties) {
    $item = $property.Value
    $name = $property.Name

    if ([string]::IsNullOrWhiteSpace([string]$item.sha256)) {
        $manifestMissingHash.Add($name)
    } elseif ([string]$item.sha256 -notmatch '^[0-9A-Fa-f]{64}$') {
        $manifestInvalidHash.Add($name)
    }

    if ($null -eq $item.size_bytes) {
        $manifestMissingSize.Add($name)
    }
}

$localFiles = @(
    Get-ChildItem -LiteralPath $DataRoot -Recurse -File -Filter "*.dbc" -ErrorAction Stop |
    Where-Object { $_.Name -match $dbcNamePattern }
)

$filesByName = @{}
foreach ($file in $localFiles) {
    $key = $file.Name.ToUpperInvariant()
    if (-not $filesByName.ContainsKey($key)) {
        $filesByName[$key] = New-Object System.Collections.Generic.List[object]
    }
    $filesByName[$key].Add($file)
}

$details = New-Object System.Collections.Generic.List[object]

foreach ($property in ($manifestProperties | Sort-Object Name)) {
    $name = $property.Name
    $item = $property.Value
    $key = $name.ToUpperInvariant()
    $matches = @()

    if ($filesByName.ContainsKey($key)) {
        $matches = @($filesByName[$key])
    }

    $expectedHash = if ($null -eq $item.sha256) { $null } else { ([string]$item.sha256).ToLowerInvariant() }
    $expectedSize = if ($null -eq $item.size_bytes) { $null } else { [int64]$item.size_bytes }

    $actualPath = $null
    $actualHash = $null
    $actualSize = $null
    $hashMatch = $false
    $sizeMatch = $false
    $status = $null

    if ($matches.Count -eq 0) {
        $status = "MISSING"
    }
    elseif ($matches.Count -gt 1) {
        $status = "DUPLICATE_LOCAL"
    }
    else {
        $file = $matches[0]
        $actualPath = $file.FullName
        $actualSize = [int64]$file.Length
        $actualHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()

        $hashMatch = ($null -ne $expectedHash) -and ($actualHash -eq $expectedHash)
        $sizeMatch = ($null -ne $expectedSize) -and ($actualSize -eq $expectedSize)

        if ($hashMatch -and $sizeMatch) {
            $status = "MATCH"
        }
        elseif (-not $hashMatch -and -not $sizeMatch) {
            $status = "HASH_AND_SIZE_MISMATCH"
        }
        elseif (-not $hashMatch) {
            $status = "HASH_MISMATCH"
        }
        else {
            $status = "SIZE_MISMATCH"
        }
    }

    $details.Add([PSCustomObject]@{
        file = $name
        fonte = [string]$item.fonte
        competencia = [string]$item.competencia
        acquisition_status = [string]$item.status
        expected_size_bytes = $expectedSize
        actual_size_bytes = $actualSize
        size_match = $sizeMatch
        expected_sha256 = $expectedHash
        actual_sha256 = $actualHash
        hash_match = $hashMatch
        local_path = $actualPath
        status = $status
    })
}

$manifestSet = @{}
foreach ($name in $manifestNames) {
    $manifestSet[$name.ToUpperInvariant()] = $true
}

$extras = @(
    $localFiles |
    Where-Object { -not $manifestSet.ContainsKey($_.Name.ToUpperInvariant()) } |
    Sort-Object FullName
)

$matchCount = @($details | Where-Object status -eq "MATCH").Count
$missingCount = @($details | Where-Object status -eq "MISSING").Count
$duplicateCount = @($details | Where-Object status -eq "DUPLICATE_LOCAL").Count
$hashMismatchCount = @(
    $details | Where-Object { $_.status -in @("HASH_MISMATCH","HASH_AND_SIZE_MISMATCH") }
).Count
$sizeMismatchCount = @(
    $details | Where-Object { $_.status -in @("SIZE_MISMATCH","HASH_AND_SIZE_MISMATCH") }
).Count

$expectedCount = $manifestProperties.Count
$localCount = $localFiles.Count

$verdict = if (
    $expectedCount -eq 108 -and
    $localCount -eq 108 -and
    $invalidManifestNames.Count -eq 0 -and
    $manifestMissingHash.Count -eq 0 -and
    $manifestInvalidHash.Count -eq 0 -and
    $manifestMissingSize.Count -eq 0 -and
    $matchCount -eq 108 -and
    $missingCount -eq 0 -and
    $duplicateCount -eq 0 -and
    $hashMismatchCount -eq 0 -and
    $sizeMismatchCount -eq 0 -and
    $extras.Count -eq 0
) {
    "PASS"
} else {
    "FAIL"
}

$result = [PSCustomObject]@{
    generated_at = (Get-Date).ToString("o")
    zip_path = (Resolve-Path -LiteralPath $ZipPath).Path
    manifest_entry = $ManifestEntry
    manifest_started_at_utc = $manifest.started_at_utc
    manifest_finished_at_utc = $manifest.finished_at_utc
    manifest_mode = $manifest.mode
    manifest_status = $manifest.status
    data_root = (Resolve-Path -LiteralPath $DataRoot).Path
    verdict = $verdict
    summary = [PSCustomObject]@{
        expected_manifest_items = $expectedCount
        local_dbc_files = $localCount
        matched = $matchCount
        missing = $missingCount
        duplicate_local = $duplicateCount
        hash_mismatch = $hashMismatchCount
        size_mismatch = $sizeMismatchCount
        extras = $extras.Count
        invalid_manifest_names = $invalidManifestNames.Count
        missing_manifest_hash = $manifestMissingHash.Count
        invalid_manifest_hash = $manifestInvalidHash.Count
        missing_manifest_size = $manifestMissingSize.Count
    }
    manifest_issues = [PSCustomObject]@{
        invalid_names = $invalidManifestNames
        missing_hash = @($manifestMissingHash)
        invalid_hash = @($manifestInvalidHash)
        missing_size = @($manifestMissingSize)
    }
    extras = @(
        $extras | ForEach-Object {
            [PSCustomObject]@{
                file = $_.Name
                path = $_.FullName
                size_bytes = $_.Length
            }
        }
    )
    details = $details
}

$parentJson = Split-Path -Parent $OutputJson
if ($parentJson -and -not (Test-Path -LiteralPath $parentJson)) {
    New-Item -ItemType Directory -Path $parentJson -Force | Out-Null
}

$parentCsv = Split-Path -Parent $OutputCsv
if ($parentCsv -and -not (Test-Path -LiteralPath $parentCsv)) {
    New-Item -ItemType Directory -Path $parentCsv -Force | Out-Null
}

$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputJson -Encoding UTF8
$details | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "=== BOUNDARY 8 - HASH RECONCILIATION ==="
Write-Host "Manifest items : $expectedCount"
Write-Host "Local DBCs     : $localCount"
Write-Host "Matched         : $matchCount"
Write-Host "Missing         : $missingCount"
Write-Host "Duplicates      : $duplicateCount"
Write-Host "Hash mismatch   : $hashMismatchCount"
Write-Host "Size mismatch   : $sizeMismatchCount"
Write-Host "Extras          : $($extras.Count)"
Write-Host "Manifest issues : $($invalidManifestNames.Count + $manifestMissingHash.Count + $manifestInvalidHash.Count + $manifestMissingSize.Count)"
Write-Host "JSON report     : $OutputJson"
Write-Host "CSV report      : $OutputCsv"
Write-Host "VERDICT=$verdict"

if ($verdict -ne "PASS") {
    Write-Host ""
    Write-Host "Non-matching items:"
    $details |
        Where-Object status -ne "MATCH" |
        Select-Object file, status, expected_size_bytes, actual_size_bytes, expected_sha256, actual_sha256 |
        Format-Table -AutoSize

    if ($extras.Count -gt 0) {
        Write-Host ""
        Write-Host "Extra local DBC files:"
        $extras | Select-Object Name, FullName | Format-Table -AutoSize
    }

    exit 1
}

exit 0
