# SAD VI-LINK — isolated File.Move non-overwrite check, Windows PowerShell 5.1 / .NET.
# Creates ONLY small disposable .txt files below a unique %TEMP% directory.
# Does not access QVDs, QVWs, QlikView COM, database or transformed data.
# PASS here does NOT authorize LINK_ANALISE.qvd materialization.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = [IO.Path]::GetFullPath($Root)
$relative = 'tools/Test-SadViLinkNoClobber.ps1'
$expectedPath = [IO.Path]::GetFullPath((Join-Path $repo $relative))
if ([IO.Path]::GetFullPath($PSCommandPath) -ine $expectedPath) {
    throw 'BLOCKED: run only the versioned script inside the supplied repository'
}
$head = @(& git -C $repo rev-parse --verify HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or $head.Count -ne 1 -or $head[0] -notmatch '^[0-9a-f]{40}$') {
    throw 'BLOCKED: repository HEAD is not available'
}
$tracked = @(& git -C $repo ls-files --error-unmatch -- $relative 2>$null)
if ($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1) {
    throw 'BLOCKED: test script is not tracked by Git'
}
$dirty = @(& git -C $repo status --porcelain -- $relative)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) {
    throw 'BLOCKED: test script is modified/uncommitted'
}

$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$work = Join-Path $tempRoot ('SAD_VI_MOVE_NO_CLOBBER_' + [Guid]::NewGuid().ToString('N'))
if (Test-Path -LiteralPath $work) {
    throw 'BLOCKED: unexpected existing scratch directory'
}
$null = New-Item -Path $work -ItemType Directory -ErrorAction Stop
Write-Output ('EVIDENCE_DIR=' + $work)
Write-Output ('VERSIONED_GIT_HEAD=' + $head[0])
Write-Output ('SCRIPT_SHA256=' + (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash)
Write-Output 'MODE=TEMP_TXT_ONLY NO_QLIK=True NO_QVD_ACCESS=True'
Write-Output 'LINK_ANALISE_QVD_GENERATED=False PRODUCTION_APPROVED=False'
Write-Output 'SCRATCH_FILES_PRESERVED=True'

function Assert-SameSHA([string]$file, [string]$expected, [string]$name) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "BLOCKED: missing $name"
    }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash
    if ($actual -cne $expected) {
        throw "BLOCKED: contents changed for $name"
    }
}

function Test-RejectedMove([string]$caseName, [bool]$createAfterCheck) {
    # Both source and destination are in one unique directory and the same volume.
    $dir = Join-Path $work $caseName
    $null = New-Item -Path $dir -ItemType Directory -ErrorAction Stop
    $source = Join-Path $dir 'stage.txt'
    $destination = Join-Path $dir 'final.txt'
    $sourceBytes = [Text.Encoding]::UTF8.GetBytes(('STAGE|' + $caseName + '|SAD_TEST'))
    $destinationBytes = [Text.Encoding]::UTF8.GetBytes(('DESTINATION|' + $caseName + '|PROTECTED'))
    [IO.File]::WriteAllBytes($source, $sourceBytes)
    $sourceSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash

    if ($createAfterCheck) {
        if (Test-Path -LiteralPath $destination) {
            throw "BLOCKED: case $caseName expected absent destination at first check"
        }
        # Controlled TOCTOU simulation: a second actor creates the destination
        # between a prior existence check and File.Move, all inside %TEMP%.
        [IO.File]::WriteAllBytes($destination, $destinationBytes)
    } else {
        [IO.File]::WriteAllBytes($destination, $destinationBytes)
    }
    $destinationSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
    $rejected = $false
    try {
        [IO.File]::Move($source, $destination)
    } catch [IO.IOException] {
        $rejected = $true
        Write-Output ('EXPECTED_EXCEPTION=' + $caseName + '|System.IO.IOException|HResult=' + $_.Exception.HResult)
    }
    if (-not $rejected) {
        throw "BLOCKED: File.Move overwrote existing destination in $caseName"
    }
    Assert-SameSHA $source $sourceSha ($caseName + '_source')
    Assert-SameSHA $destination $destinationSha ($caseName + '_destination')
    Write-Output ('CASE=' + $caseName + ' RESULT=PASS_DESTINATION_PROTECTED_SOURCE_PRESERVED')
}

try {
    Test-RejectedMove 'EXISTING_DESTINATION' $false
    Test-RejectedMove 'CREATED_AFTER_CHECK' $true

    $dir = Join-Path $work 'EMPTY_DESTINATION'
    $null = New-Item -Path $dir -ItemType Directory -ErrorAction Stop
    $source = Join-Path $dir 'stage.txt'
    $destination = Join-Path $dir 'final.txt'
    [IO.File]::WriteAllBytes($source, [Text.Encoding]::UTF8.GetBytes('SAD_TEST_SUCCESSFUL_MOVE'))
    $expectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash
    if (Test-Path -LiteralPath $destination) {
        throw 'BLOCKED: successful-move scenario unexpectedly has destination'
    }
    [IO.File]::Move($source, $destination)
    if (Test-Path -LiteralPath $source) {
        throw 'BLOCKED: stage still present after successful move'
    }
    Assert-SameSHA $destination $expectedHash 'EMPTY_DESTINATION_final'
    Write-Output 'CASE=EMPTY_DESTINATION RESULT=PASS_STAGE_MOVED_CONTENT_IDENTICAL'
    Write-Output 'VERDICT=PASS_VI_LINK_FILE_MOVE_TEMP_ONLY_NOT_QVD_APPROVAL'
} catch {
    Write-Output ('VERDICT=BLOCKED_VI_LINK_FILE_MOVE_TEMP_ONLY ' + $_.Exception.Message)
    throw
}
