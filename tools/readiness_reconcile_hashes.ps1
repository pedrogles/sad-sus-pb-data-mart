param(
    [Parameter(Mandatory=$true)]
    [string]$ZipPath,

    [string]$RepoRoot = "",

    [string]$DataRoot = "",

    [string]$ManifestEntry = "manifesto-execucao.json",

    [string]$OutputJson = "",

    [string]$OutputCsv = ""
)

$ErrorActionPreference = "Stop"

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

        $stream = $entry.Open()
        $reader = New-Object System.IO.StreamReader($stream)

        try {
            return $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
            $stream.Dispose()
        }
    }
    finally {
        $archive.Dispose()
    }
}

function Invoke-HashReconciliation {
    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        $scriptPath = $MyInvocation.ScriptName

        if ([string]::IsNullOrWhiteSpace($scriptPath)) {
            $scriptPath = $PSCommandPath
        }

        if ([string]::IsNullOrWhiteSpace($scriptPath)) {
            throw "Could not determine script path to resolve RepoRoot."
        }

        $scriptDir = Split-Path -Parent $scriptPath
        $resolvedRepoRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..")).Path
    }
    else {
        $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    }

    if ([string]::IsNullOrWhiteSpace($DataRoot)) {
        $resolvedDataRoot = Join-Path $resolvedRepoRoot "BASE"
    }
    else {
        $resolvedDataRoot = $DataRoot
    }

    if ([string]::IsNullOrWhiteSpace($OutputJson)) {
        $resolvedOutputJson = Join-Path $resolvedRepoRoot "BASE\CONVERTIDA\readiness-hash-reconciliation.json"
    }
    else {
        $resolvedOutputJson = $OutputJson
    }

    if ([string]::IsNullOrWhiteSpace($OutputCsv)) {
        $resolvedOutputCsv = Join-Path $resolvedRepoRoot "BASE\CONVERTIDA\readiness-hash-reconciliation.csv"
    }
    else {
        $resolvedOutputCsv = $OutputCsv
    }

    if (-not (Test-Path -LiteralPath $ZipPath)) {
        throw "Acquisition ZIP not found: $ZipPath"
    }

    if (-not (Test-Path -LiteralPath $resolvedDataRoot)) {
        throw "Data root not found: $resolvedDataRoot"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $manifestText = Read-ZipEntryText -ArchivePath $ZipPath -EntryName $ManifestEntry
    $manifest = $manifestText | ConvertFrom-Json

    if ($null -eq $manifest.items) {
        throw "Manifest has no 'items' object."
    }

    # Windows PowerShell 5.1 can be brittle when an adapter-backed
    # PSObject.Properties collection is wrapped directly in @(...).
    # Materialize only property names through the pipeline.
    $manifestNames = @(
        $manifest.items.PSObject.Properties |
        ForEach-Object { [string]$_.Name }
    )

    $dbcNamePattern = '^(RD|LT|ST)PB(17|18|19)(0[1-9]|1[0-2])\.dbc$'

    $invalidManifestNames = @()
    $manifestMissingHash = @()
    $manifestInvalidHash = @()
    $manifestMissingSize = @()

    foreach ($name in $manifestNames) {
        if ($name -notmatch $dbcNamePattern) {
            $invalidManifestNames += $name
        }

        $property = $manifest.items.PSObject.Properties[$name]

        if ($null -eq $property) {
            throw "Manifest property could not be resolved: $name"
        }

        $item = $property.Value

        if ([string]::IsNullOrWhiteSpace([string]$item.sha256)) {
            $manifestMissingHash += $name
        }
        elseif ([string]$item.sha256 -notmatch '^[0-9A-Fa-f]{64}$') {
            $manifestInvalidHash += $name
        }

        if ($null -eq $item.size_bytes) {
            $manifestMissingSize += $name
        }
    }

    $localFiles = @(
        Get-ChildItem -LiteralPath $resolvedDataRoot -Recurse -File -Filter "*.dbc" |
        Where-Object { $_.Name -match $dbcNamePattern }
    )

    $details = @()

    foreach ($name in ($manifestNames | Sort-Object)) {
        $property = $manifest.items.PSObject.Properties[$name]
        $item = $property.Value

        $matches = @(
            $localFiles |
            Where-Object { $_.Name -ieq $name }
        )

        $expectedHash = $null
        if ($null -ne $item.sha256) {
            $expectedHash = ([string]$item.sha256).ToLowerInvariant()
        }

        $expectedSize = $null
        if ($null -ne $item.size_bytes) {
            $expectedSize = [int64]$item.size_bytes
        }

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

            $hashMatch = (($null -ne $expectedHash) -and ($actualHash -eq $expectedHash))
            $sizeMatch = (($null -ne $expectedSize) -and ($actualSize -eq $expectedSize))

            if ($hashMatch -and $sizeMatch) {
                $status = "MATCH"
            }
            elseif ((-not $hashMatch) -and (-not $sizeMatch)) {
                $status = "HASH_AND_SIZE_MISMATCH"
            }
            elseif (-not $hashMatch) {
                $status = "HASH_MISMATCH"
            }
            else {
                $status = "SIZE_MISMATCH"
            }
        }

        $details += [PSCustomObject]@{
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
        }
    }

    $extras = @(
        $localFiles |
        Where-Object {
            $localName = $_.Name
            -not ($manifestNames | Where-Object { $_ -ieq $localName })
        } |
        Sort-Object FullName
    )

    $matchCount = @($details | Where-Object { $_.status -eq "MATCH" }).Count
    $missingCount = @($details | Where-Object { $_.status -eq "MISSING" }).Count
    $duplicateCount = @($details | Where-Object { $_.status -eq "DUPLICATE_LOCAL" }).Count
    $hashMismatchCount = @(
        $details |
        Where-Object {
            ($_.status -eq "HASH_MISMATCH") -or
            ($_.status -eq "HASH_AND_SIZE_MISMATCH")
        }
    ).Count
    $sizeMismatchCount = @(
        $details |
        Where-Object {
            ($_.status -eq "SIZE_MISMATCH") -or
            ($_.status -eq "HASH_AND_SIZE_MISMATCH")
        }
    ).Count

    $expectedCount = $manifestNames.Count
    $localCount = $localFiles.Count

    $verdict = "FAIL"

    if (
        ($expectedCount -eq 108) -and
        ($localCount -eq 108) -and
        ($invalidManifestNames.Count -eq 0) -and
        ($manifestMissingHash.Count -eq 0) -and
        ($manifestInvalidHash.Count -eq 0) -and
        ($manifestMissingSize.Count -eq 0) -and
        ($matchCount -eq 108) -and
        ($missingCount -eq 0) -and
        ($duplicateCount -eq 0) -and
        ($hashMismatchCount -eq 0) -and
        ($sizeMismatchCount -eq 0) -and
        ($extras.Count -eq 0)
    ) {
        $verdict = "PASS"
    }

    $result = [PSCustomObject]@{
        generated_at = (Get-Date).ToString("o")
        zip_path = (Resolve-Path -LiteralPath $ZipPath).Path
        manifest_entry = $ManifestEntry
        manifest_started_at_utc = $manifest.started_at_utc
        manifest_finished_at_utc = $manifest.finished_at_utc
        manifest_mode = $manifest.mode
        manifest_status = $manifest.status
        data_root = (Resolve-Path -LiteralPath $resolvedDataRoot).Path
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
            invalid_names = @($invalidManifestNames)
            missing_hash = @($manifestMissingHash)
            invalid_hash = @($manifestInvalidHash)
            missing_size = @($manifestMissingSize)
        }
        extras = @(
            $extras |
            ForEach-Object {
                [PSCustomObject]@{
                    file = $_.Name
                    path = $_.FullName
                    size_bytes = $_.Length
                }
            }
        )
        details = @($details)
    }

    $parentJson = Split-Path -Parent $resolvedOutputJson
    if ($parentJson -and -not (Test-Path -LiteralPath $parentJson)) {
        New-Item -ItemType Directory -Path $parentJson -Force | Out-Null
    }

    $parentCsv = Split-Path -Parent $resolvedOutputCsv
    if ($parentCsv -and -not (Test-Path -LiteralPath $parentCsv)) {
        New-Item -ItemType Directory -Path $parentCsv -Force | Out-Null
    }

    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resolvedOutputJson -Encoding UTF8
    $details | Export-Csv -LiteralPath $resolvedOutputCsv -NoTypeInformation -Encoding UTF8

    Write-Host ""
    Write-Host "=== BOUNDARY 8 - HASH RECONCILIATION ==="
    Write-Host "Manifest items : $expectedCount"
    Write-Host "Local DBCs     : $localCount"
    Write-Host "Matched        : $matchCount"
    Write-Host "Missing        : $missingCount"
    Write-Host "Duplicates     : $duplicateCount"
    Write-Host "Hash mismatch  : $hashMismatchCount"
    Write-Host "Size mismatch  : $sizeMismatchCount"
    Write-Host "Extras         : $($extras.Count)"
    Write-Host "Manifest issues: $($invalidManifestNames.Count + $manifestMissingHash.Count + $manifestInvalidHash.Count + $manifestMissingSize.Count)"
    Write-Host "JSON report    : $resolvedOutputJson"
    Write-Host "CSV report     : $resolvedOutputCsv"
    Write-Host "VERDICT=$verdict"

    if ($verdict -ne "PASS") {
        Write-Host ""
        Write-Host "Non-matching items:"

        $details |
            Where-Object { $_.status -ne "MATCH" } |
            Select-Object file, status, expected_size_bytes, actual_size_bytes, expected_sha256, actual_sha256 |
            Format-Table -AutoSize

        if ($extras.Count -gt 0) {
            Write-Host ""
            Write-Host "Extra local DBC files:"
            $extras |
                Select-Object Name, FullName |
                Format-Table -AutoSize
        }

        return 1
    }

    return 0
}

try {
    $exitCode = Invoke-HashReconciliation
    exit $exitCode
}
catch {
    Write-Host ""
    Write-Host "READINESS_HASH_RECONCILIATION_ERROR"
    Write-Host "ERROR_TYPE=$($_.Exception.GetType().FullName)"
    Write-Host "ERROR_MESSAGE=$($_.Exception.Message)"

    if ($null -ne $_.InvocationInfo) {
        Write-Host "ERROR_LINE=$($_.InvocationInfo.ScriptLineNumber)"
        Write-Host "ERROR_POSITION=$($_.InvocationInfo.PositionMessage)"
    }

    exit 1
}
