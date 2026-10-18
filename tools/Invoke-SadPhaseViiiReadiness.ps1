# Fase VIII — READ-ONLY readiness preflight. No Qlik reload, STORE or QVW creation.
# Scope: inspect 22 existing QVDs and canonical QVW hashes; probe Windows/QlikView presence.
# This does NOT validate indicator T24/T25/T26, D2/P5, CNES coverage or production.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [string]$F1F2Dir,
    [string]$F3Dir
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath($Root)
$scriptRel = 'tools/Invoke-SadPhaseViiiReadiness.ps1'
$self = Join-Path $repo $scriptRel
$branchRequired = 'feat/phase-viii-readiness-20261018'
$mainBase = '337943d5c5b77067f842902fc679dbb68db87020'

if ([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)) {
    throw 'BLOCKED: execute the committed script directly from this repository, not a copy'
}
$gitBranch = @(& git -C $repo branch --show-current 2>$null)
$gitHead = @(& git -C $repo rev-parse --verify HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or $gitBranch.Count -ne 1 -or $gitBranch[0] -cne $branchRequired -or
    $gitHead.Count -ne 1 -or $gitHead[0] -notmatch '^[0-9a-f]{40}$') {
    throw 'BLOCKED: unexpected branch or Git HEAD'
}
$null = & git -C $repo merge-base --is-ancestor $mainBase HEAD 2>$null
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED: branch does not descend from frozen main baseline' }
$tracked = @(& git -C $repo ls-files --error-unmatch -- $scriptRel 2>$null)
if ($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1) { throw 'BLOCKED: preflight script not tracked' }
$dirty = @(& git -C $repo status --porcelain -- $scriptRel)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) { throw 'BLOCKED: commit preflight changes before running' }

$evidence = Join-Path ([IO.Path]::GetTempPath()) ('SAD_VIII_READINESS_' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $evidence -ErrorAction Stop
Write-Output ('EVIDENCE_DIR=' + $evidence)
Write-Output ('BRANCH=' + $gitBranch[0])
Write-Output ('VERSIONED_GIT_HEAD=' + $gitHead[0])
Write-Output ('RUNNER_SHA256=' + (Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output 'MODE=READ_ONLY_NO_QVW_NO_RELOAD_NO_STORE'
Write-Output 'T24_T25_T26=NOT_EXECUTED PRODUCTION_APPROVED=False'

$ext = Join-Path $repo 'EXTRACAO/QVD'
$trans = Join-Path $repo 'TRANSFORMACAO/QVD'
$expectedTrans = @(
    'DIM_TEMPO.qvd', 'DIM_MUNICIPIO.qvd', 'DIM_ESTABELECIMENTO.qvd',
    'DIM_PROCEDIMENTO.qvd', 'DIM_DIAGNOSTICO.qvd',
    'DIM_CARATER_ATENDIMENTO.qvd', 'DIM_MOTIVO_SAIDA_PERMANENCIA.qvd',
    'DIM_TIPO_LEITO.qvd', 'FATO_INTERNACAO.qvd',
    'FATO_CAPACIDADE_LEITO.qvd', 'FATO_POPULACAO.qvd', 'LINK_ANALISE.qvd'
)

function Read-SadQvdHeader([string]$file) {
    $stream = [IO.File]::Open($file, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        $bytes = New-Object byte[] ([int][Math]::Min(4194304, $stream.Length))
        $received = $stream.Read($bytes, 0, $bytes.Length)
        $raw = [Text.Encoding]::UTF8.GetString($bytes, 0, $received)
        $terminator = '</QvdTableHeader>'
        $end = $raw.IndexOf($terminator, [StringComparison]::Ordinal)
        if ($end -lt 0) { throw ('BLOCKED: no QVD header in ' + $file) }
        [xml]$xml = $raw.Substring(0, $end + $terminator.Length)
        $node = $xml.DocumentElement
        if ($null -eq $node -or $node.LocalName -ne 'QvdTableHeader') {
            throw ('BLOCKED: invalid QVD root ' + $file)
        }
        $count = $node.SelectSingleNode('./NoOfRecords')
        $names = @($node.SelectNodes('./Fields/QvdFieldHeader/FieldName') | ForEach-Object { $_.InnerText })
        if ($null -eq $count -or $names.Count -eq 0) {
            throw ('BLOCKED: missing QVD count/fields ' + $file)
        }
        return [pscustomobject]@{ Rows = [long]$count.InnerText; Fields = $names }
    } finally { $stream.Dispose() }
}

function Get-SadQvdSnapshot {
    foreach ($folder in @($ext, $trans)) {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
            throw ('BLOCKED: missing QVD folder ' + $folder)
        }
    }
    $e = @(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)
    $t = @(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File)
    if ($e.Count -ne 10 -or $t.Count -ne 12) {
        throw ('BLOCKED: expected 10+12 QVDs; found ' + $e.Count + '+' + $t.Count)
    }
    foreach ($name in $expectedTrans) {
        if (@($t | Where-Object { $_.Name -ceq $name }).Count -ne 1) {
            throw ('BLOCKED: transformed QVD missing or repeated ' + $name)
        }
    }
    $records = @()
    foreach ($f in (@($e) + @($t))) {
        if ($f.Length -le 0) { throw ('BLOCKED: empty QVD ' + $f.FullName) }
        $h = Read-SadQvdHeader $f.FullName
        $records += [pscustomobject]@{
            Path = $f.FullName
            Bytes = [long]$f.Length
            Rows = $h.Rows
            Fields = ($h.Fields -join '|')
            SHA256 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        }
    }
    return @($records | Sort-Object Path)
}

function Get-SadCanonicalQvwSnapshot {
    $records = @()
    foreach ($rel in @('EXTRACAO/EXT.qvw', 'TRANSFORMACAO/TRANSF.qvw', 'PAINEL/PAINEL.qvw')) {
        $p = Join-Path $repo $rel
        if (Test-Path -LiteralPath $p -PathType Leaf) {
            $f = Get-Item -LiteralPath $p
            $records += [pscustomobject]@{
                Path = $f.FullName
                Bytes = [long]$f.Length
                SHA256 = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
            }
        }
    }
    return @($records | Sort-Object Path)
}

function Same-SadSnapshot($a, $b) {
    return ((ConvertTo-Json -InputObject @($a) -Depth 4 -Compress) -ceq
            (ConvertTo-Json -InputObject @($b) -Depth 4 -Compress))
}

function Get-ReferenceFolderStatus([string]$path, [string]$label) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        Write-Host ($label + '=NOT_PROVIDED')
        return $false
    }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        Write-Host ($label + '=MISSING_DIRECTORY')
        return $false
    }
    $expectedNames = if ($label -eq 'F1F2') {
        @('F1_fluxo_ano.csv', 'F1_fluxo_competencia.csv',
          'F1_residencia_ano.csv', 'F1_residencia_competencia.csv',
          'F1_servico_ano.csv', 'F1_servico_competencia.csv',
          'F2_lt_municipio_ano_cobertura_candidata.csv',
          'F2_lt_municipio_competencia_observado.csv')
    } else {
        @('F3_pop_municipio_ano.csv',
          'F3_componentes_residencia_ano.csv',
          'F3_componentes_servico_ano.csv',
          'F3_residentes_externos_ano.csv',
          'F3_cenarios_multimunicipais.csv')
    }
    $manifestName = if ($label -eq 'F1F2') { 'manifest_F1_F2.json' } else { 'manifest_F3.json' }
    $manifestPath = Join-Path $path $manifestName
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw ($label + ': missing expected manifest ' + $manifestName)
    }
    $files = @(Get-ChildItem -LiteralPath $path -File)
    $csvs = @($files | Where-Object { $_.Extension -ieq '.csv' })
    if ($csvs.Count -ne $expectedNames.Count) {
        throw ($label + ': CSV count mismatch, expected ' + $expectedNames.Count + ', found ' + $csvs.Count)
    }
    foreach ($name in $expectedNames) {
        if (@($csvs | Where-Object { $_.Name -ceq $name }).Count -ne 1) {
            throw ($label + ': missing or nonunique source reference ' + $name)
        }
    }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $manifest -or $null -eq $manifest.output_sha256) {
        throw ($label + ': malformed reference manifest')
    }
    $declared = @($manifest.output_sha256.PSObject.Properties)
    if ($declared.Count -ne $expectedNames.Count) {
        throw ($label + ': manifest output SHA count mismatch')
    }
    $results = @()
    foreach ($name in $expectedNames) {
        $match = @($declared | Where-Object { $_.Name -ceq $name })
        if ($match.Count -ne 1 -or [string]$match[0].Value -notmatch '^[A-Fa-f0-9]{64}$') {
            throw ($label + ': invalid manifest checksum declaration for ' + $name)
        }
        $file = Join-Path $path $name
        $actual = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
        if ($actual -cne ([string]$match[0].Value).ToUpperInvariant()) {
            throw ($label + ': manifest SHA256 mismatch for ' + $name)
        }
        $results += [pscustomobject]@{ Group=$label; Name=$name; SHA256=$actual }
    }
    $results += [pscustomobject]@{
        Group=$label; Name=$manifestName
        SHA256=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash
    }
    $results | Export-Csv -LiteralPath (Join-Path $evidence ($label + '_file_hashes.csv')) -NoTypeInformation -Encoding UTF8
    Write-Host ($label + '=PASS_MANIFEST_SHA256_MATCH_' + $expectedNames.Count + '_OF_' + $expectedNames.Count)
    return $true
}
$before = $null
$qvwBefore = $null
try {
    $before = @(Get-SadQvdSnapshot)
    $qvwBefore = @(Get-SadCanonicalQvwSnapshot)
    $before | Export-Csv -LiteralPath (Join-Path $evidence 'qvd_22_before.csv') -NoTypeInformation -Encoding UTF8
    $qvwBefore | Export-Csv -LiteralPath (Join-Path $evidence 'canonical_qvw_before.csv') -NoTypeInformation -Encoding UTF8
    $linkPath = Join-Path $trans 'LINK_ANALISE.qvd'
    $link = @($before | Where-Object { $_.Path -ieq $linkPath })
    if ($link.Count -ne 1 -or $link[0].Rows -ne 85705 -or
        $link[0].Fields -cne '%LINK_KEY|%SK_TEMPO_COMPETENCIA|%SK_TEMPO_ANO|%SK_MUNICIPIO_RESIDENCIA|%SK_MUNICIPIO_SERVICO|%SK_ESTABELECIMENTO' -or
        $link[0].SHA256 -cne '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB') {
        throw 'BLOCKED: LINK_ANALISE does not match frozen VI-R2 physical baseline'
    }
    $factExpect = @(
        @{ Name = 'FATO_INTERNACAO.qvd'; Rows = 566672; Fields = @('QTD_INTERNACAO', '%LINK_KEY', 'FATO_RD_COMPETENCIA_ORIGEM') },
        @{ Name = 'FATO_CAPACIDADE_LEITO.qvd'; Rows = 35518; Fields = @('QTD_LEITOS_SUS', '%LINK_KEY', 'FATO_LT_COMPETENCIA_ORIGEM') },
        @{ Name = 'FATO_POPULACAO.qvd'; Rows = 669; Fields = @('POPULACAO_ESTIMADA', '%SK_TEMPO_ANO', '%SK_MUNICIPIO') }
    )
    foreach ($f in $factExpect) {
        $path = Join-Path $trans $f.Name
        $row = @($before | Where-Object { $_.Path -ieq $path })
        if ($row.Count -ne 1 -or $row[0].Rows -ne $f.Rows) {
            throw ('BLOCKED: fact QVD rows drift ' + $f.Name)
        }
        $fields = @($row[0].Fields.Split('|'))
        foreach ($n in $f.Fields) {
            if ($fields -cnotcontains $n) { throw ('BLOCKED: missing fact field ' + $n) }
        }
    }
    Write-Output 'INVENTORY_22_QVD=PASS_READ_ONLY_HEADERS_AND_HASHES'
    $f1Present = Get-ReferenceFolderStatus -path $F1F2Dir -label 'F1F2'
    $f3Present = Get-ReferenceFolderStatus -path $F3Dir -label 'F3'

    if ($f1Present -and $f3Present) {
        $f3Manifest = Get-Content -LiteralPath (Join-Path $F3Dir 'manifest_F3.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -eq $f3Manifest.input_sha256) {
            throw 'F3 manifest missing input_sha256'
        }
        $inputs = @($f3Manifest.input_sha256.PSObject.Properties)
        $f1ActualFiles = @(Get-ChildItem -LiteralPath $F1F2Dir -File |
            Where-Object { $_.Extension -ieq '.csv' -or $_.Name -ceq 'manifest_F1_F2.json' })
        if ($f1ActualFiles.Count -ne 9) { throw 'F1F2 input cross-check expects exactly 9 files' }
        foreach ($f in $f1ActualFiles) {
            $matching = @($inputs | Where-Object { [IO.Path]::GetFileName($_.Name) -ceq $f.Name })
            if ($matching.Count -ne 1 -or [string]$matching[0].Value -notmatch '^[A-Fa-f0-9]{64}

    $windows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    $qvCandidates = @()
    if ($env:QLIKVIEW_EXE) { $qvCandidates += $env:QLIKVIEW_EXE }
    $cmd = Get-Command 'Qv.exe' -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { $qvCandidates += $cmd.Source }
    foreach ($base in @([Environment]::GetFolderPath('ProgramFiles'), [Environment]::GetFolderPath('ProgramFilesX86'))) {
        if ($base) { $qvCandidates += (Join-Path $base 'QlikView/Qv.exe') }
    }
    $qv = @($qvCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -Unique)
    $comType = $null
    if ($windows) {
        try { $comType = [Type]::GetTypeFromProgID('QlikTech.QlikView') } catch { $comType = $null }
    }
    Write-Output ('WINDOWS=' + $windows)
    Write-Output ('QLIKVIEW_EXE_PRESENT=' + ($qv.Count -gt 0))
    if ($qv.Count -gt 0) {
        $info = (Get-Item -LiteralPath $qv[0]).VersionInfo
        Write-Output ('QLIKVIEW_EXE_VERSION=' + $info.FileVersion)
    }
    Write-Output ('QLIKVIEW_COM_REGISTERED=' + ($null -ne $comType))
    Write-Output 'QLIKVIEW_RELOAD=False COM_INSTANTIATION=False QVD_WRITES=0 QVW_WRITES=0'
    if (-not $windows -or $qv.Count -eq 0 -or $null -eq $comType -or -not $f1Present -or -not $f3Present) {
        throw 'READINESS_ENVIRONMENT_OR_REFERENCES_NOT_READY'
    } else {
        Write-Output 'VERDICT=PASS_READONLY_ENTRY_INVENTORY_CANDIDATE_ONLY_NOT_INDICATOR_APPROVAL'
    }
} catch {
    Write-Output ('VERDICT=BLOCKED_READONLY_PREFLIGHT ' + $_.Exception.Message)
    throw
} finally {
    if ($null -ne $before) {
        $after = @(Get-SadQvdSnapshot)
        $after | Export-Csv -LiteralPath (Join-Path $evidence 'qvd_22_after.csv') -NoTypeInformation -Encoding UTF8
        if (-not (Same-SadSnapshot $before $after)) {
            throw 'CRITICAL: protected QVD metadata/hash drift; stop and preserve evidence'
        }
        Write-Output 'ORIGINAL_22_QVD_SHA256_AND_HEADERS_UNCHANGED=True'
    }
    if ($null -ne $qvwBefore) {
        $qvwAfter = @(Get-SadCanonicalQvwSnapshot)
        $qvwAfter | Export-Csv -LiteralPath (Join-Path $evidence 'canonical_qvw_after.csv') -NoTypeInformation -Encoding UTF8
        if (-not (Same-SadSnapshot $qvwBefore $qvwAfter)) {
            throw 'CRITICAL: canonical QVW hash drift; stop and preserve evidence'
        }
        Write-Output 'ORIGINAL_CANONICAL_QVWS_UNCHANGED=True'
    }
}
) {
                throw ('F3 manifest does not link uniquely to F1F2 file ' + $f.Name)
            }
            $actual = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
            if ($actual -cne ([string]$matching[0].Value).ToUpperInvariant()) {
                throw ('F3 input SHA256 differs from F1F2 source for ' + $f.Name)
            }
        }
        Write-Output 'F3_F1F2_CROSS_MANIFEST_LINK=PASS_9_OF_9'
    }

    $windows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
    $qvCandidates = @()
    if ($env:QLIKVIEW_EXE) { $qvCandidates += $env:QLIKVIEW_EXE }
    $cmd = Get-Command 'Qv.exe' -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { $qvCandidates += $cmd.Source }
    foreach ($base in @([Environment]::GetFolderPath('ProgramFiles'), [Environment]::GetFolderPath('ProgramFilesX86'))) {
        if ($base) { $qvCandidates += (Join-Path $base 'QlikView/Qv.exe') }
    }
    $qv = @($qvCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -Unique)
    $comType = $null
    if ($windows) {
        try { $comType = [Type]::GetTypeFromProgID('QlikTech.QlikView') } catch { $comType = $null }
    }
    Write-Output ('WINDOWS=' + $windows)
    Write-Output ('QLIKVIEW_EXE_PRESENT=' + ($qv.Count -gt 0))
    if ($qv.Count -gt 0) {
        $info = (Get-Item -LiteralPath $qv[0]).VersionInfo
        Write-Output ('QLIKVIEW_EXE_VERSION=' + $info.FileVersion)
    }
    Write-Output ('QLIKVIEW_COM_REGISTERED=' + ($null -ne $comType))
    Write-Output 'QLIKVIEW_RELOAD=False COM_INSTANTIATION=False QVD_WRITES=0 QVW_WRITES=0'
    if (-not $windows -or $qv.Count -eq 0 -or $null -eq $comType -or -not $f1Present -or -not $f3Present) {
        throw 'READINESS_ENVIRONMENT_OR_REFERENCES_NOT_READY'
    } else {
        Write-Output 'VERDICT=PASS_READONLY_ENTRY_INVENTORY_CANDIDATE_ONLY_NOT_INDICATOR_APPROVAL'
    }
} catch {
    Write-Output ('VERDICT=BLOCKED_READONLY_PREFLIGHT ' + $_.Exception.Message)
    throw
} finally {
    if ($null -ne $before) {
        $after = @(Get-SadQvdSnapshot)
        $after | Export-Csv -LiteralPath (Join-Path $evidence 'qvd_22_after.csv') -NoTypeInformation -Encoding UTF8
        if (-not (Same-SadSnapshot $before $after)) {
            throw 'CRITICAL: protected QVD metadata/hash drift; stop and preserve evidence'
        }
        Write-Output 'ORIGINAL_22_QVD_SHA256_AND_HEADERS_UNCHANGED=True'
    }
    if ($null -ne $qvwBefore) {
        $qvwAfter = @(Get-SadCanonicalQvwSnapshot)
        $qvwAfter | Export-Csv -LiteralPath (Join-Path $evidence 'canonical_qvw_after.csv') -NoTypeInformation -Encoding UTF8
        if (-not (Same-SadSnapshot $qvwBefore $qvwAfter)) {
            throw 'CRITICAL: canonical QVW hash drift; stop and preserve evidence'
        }
        Write-Output 'ORIGINAL_CANONICAL_QVWS_UNCHANGED=True'
    }
}
