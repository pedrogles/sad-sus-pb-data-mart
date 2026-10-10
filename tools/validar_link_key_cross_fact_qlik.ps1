# Phase VI — run isolated QlikView 12 cross-fact Link Key experimental preflight.
# Reads 3 staging QVDs and 3 dimensional QVDs; creates ignored QVW only.
# R2 preserves failed P6_LINK_KEY_CROSS_FACT_PREFLIGHT.qvw + log, plus phase V evidence.
# No fact QVD, output dataset, checkpoint, Link Table or production .qvw writes.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$qvs = Join-Path $Root 'TRANSFORMACAO\phase_vi_link_key_cross_fact_preflight.qvs'
$qvw = Join-Path $Root 'TRANSFORMACAO\P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw'
$staging = Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'
$log = "$qvw.log"
foreach ($item in @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    $qvs, $staging,
    (Join-Path $Root 'EXTRACAO\QVD\SRC_CNES_LT.qvd'),
    (Join-Path $Root 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd')
)) {
    if (-not (Test-Path -LiteralPath $item -PathType Leaf)) {
        throw "Arquivo requerido ausente: $item"
    }
}
$script = [IO.File]::ReadAllText($qvs, [Text.Encoding]::UTF8)
if (-not $script.Contains('[P6-LINK] START READ_ONLY_CROSS_FACT_SERIALIZATION') -or
    -not $script.Contains('VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED') -or
    -not $script.Contains('FROM [..\EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd] (qvd);') -or
    $script -match '(?im)^\s*(STORE|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN|BINARY|EXECUTE)\b') {
    throw 'QVS versionado nao atende ao contrato isolado, sem STORE/JOIN'
}

function Test-SameQlikScript([string]$actual, [string]$expected) {
    # A interface COM pode salvar quebras de linha como CRLF mesmo quando o Git guarda LF.
    return ($actual.Replace("`r`n", "`n").TrimEnd() -ceq
            $expected.Replace("`r`n", "`n").TrimEnd())
}

# SHA every input QVD: abort if any staging/dimension snapshot changes.
$readOnlyQvds = @(
    $staging,
    (Join-Path $Root 'EXTRACAO\QVD\SRC_CNES_LT.qvd'),
    (Join-Path $Root 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd')
)
$originalHashes = @{}
foreach ($path in $readOnlyQvds) {
    $originalHashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$scriptSha = (Get-FileHash -LiteralPath $qvs -Algorithm SHA256).Hash
$qv = $null
$doc = $null
try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    if (Test-Path -LiteralPath $qvw -PathType Leaf) {
        $doc = $qv.OpenDoc($qvw, '', '')
        if ($null -eq $doc) { throw "Nao foi possivel abrir o QVW: $qvw" }
        if (-not (Test-SameQlikScript ([string]$doc.GetProperties().Script) $script)) {
            throw 'QVW preexistente nao corresponde ao QVS versionado; nao sobrescrever'
        }
        if (-not [bool]$doc.GetProperties().GenerateLogfile) {
            throw 'QVW preexistente nao gera log; requer revisao manual antes do teste'
        }
        Write-Output 'DOCUMENT_REUSED=True'
    } else {
        $doc = $qv.CreateDoc()
        if ($null -eq $doc) { throw 'CreateDoc nao retornou documento QlikView' }
        $p = $doc.GetProperties()
        $p.Script = $script
        $p.GenerateLogfile = $true
        $null = $doc.SetProperties($p)
        if (-not (Test-SameQlikScript ([string]$doc.GetProperties().Script) $script) -or
            -not [bool]$doc.GetProperties().GenerateLogfile) {
            throw 'QlikView nao confirmou script ou GenerateLogfile'
        }
        $null = $doc.SaveAs($qvw)
        if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {
            throw 'SaveAs nao criou QVW de teste'
        }
        Write-Output 'DOCUMENT_REUSED=False'
    }

    Write-Output 'MODE=PHASE_VI_LINK_KEY_CROSS_FACT_READ_ONLY'
    Write-Output "SCRIPT=$qvs"
    Write-Output "SCRIPT_SHA256=$scriptSha"
    Write-Output "DOCUMENT=$qvw"
    Write-Output 'FACT_QVD_GENERATED=False'
    Write-Output 'OUTPUT_DATA_FILES_WRITTEN=0'

    $started = [DateTime]::UtcNow
    Write-Output 'RELOAD_STARTED=True'
    $retval = $doc.Reload()
    Write-Output 'RELOAD_RETURNED=True'
    Write-Output "RELOAD_API_RETURN=$retval"

    foreach ($path in $readOnlyQvds) {
        $shaAfter = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        if ($originalHashes[$path] -cne $shaAfter) {
            throw "SHA256 de QVD de entrada mudou durante o teste: $path"
        }
    }
    Write-Output 'ALL_6_INPUT_QVD_SHA256_UNCHANGED=True'

    $lines = @()
    $freshLog = $false
    for ($attempt = 0; $attempt -lt 16; $attempt++) {
        if (Test-Path -LiteralPath $log -PathType Leaf) {
            $file = Get-Item -LiteralPath $log
            $freshLog = $file.LastWriteTimeUtc -ge $started.AddSeconds(-2)
            if ($freshLog) {
                $lines = @(Get-Content -LiteralPath $log -ErrorAction Stop |
                    Where-Object { $_ -match '\[P6-LINK\]' -and $_ -notmatch '\bTRACE\b' })
                if (@($lines | Where-Object {
                    $_ -match 'VERDICT=(PASS|BLOCKED)'
                }).Count -gt 0) { break }
            }
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $freshLog) {
        throw 'VERDICT=INCONCLUSIVE_NO_CONTEMPORANEOUS_LOG'
    }
    Write-Output "LOG=$log"
    foreach ($line in $lines) { Write-Output $line }

    $success = @($lines | Where-Object {
        $_.Contains('[P6-LINK] VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED')
    }).Count -eq 1
    $failed = @($lines | Where-Object {
        $_ -match '\[P6-LINK\] VERDICT=BLOCKED'
    }).Count -gt 0
    $syntheticZero = @($lines | Where-Object {
        $_.Contains('[P6-LINK] SYNTHETIC_TABLES=0')
    }).Count -eq 1
    $expected = @(
        'PROCESS=RD ROWS=566672 BAD_COORD=0',
        'PROCESS=LT ROWS=35518 BAD_COORD=0',
        'PROCESS=POP ROWS=669 BAD_COORD=0'
    )
    $byProcess = @($expected | ForEach-Object {
        $criterion = $_
        @($lines | Where-Object { $_.Contains($criterion) }).Count -eq 1
    })
    $totalLines = @($lines | Where-Object {
        $_.Contains('TOTAL ROWS=602859 RD=566672 LT=35518 POP=669 BAD_COORD=0 NULL_KEY=0 DISTINCT_SERIAL=')
    })
    $equalDistinctCounts = $false
    if ($totalLines.Count -eq 1 -and
        $totalLines[0] -match 'DISTINCT_SERIAL=(\d+) DISTINCT_HASH=(\d+)') {
        $serialCount = [long]$Matches[1]
        $hashCount = [long]$Matches[2]
        $equalDistinctCounts = ($serialCount -gt 0 -and $serialCount -eq $hashCount)
    }
    if (-not $success -or $failed -or -not $syntheticZero -or -not $equalDistinctCounts -or
        @($byProcess | Where-Object { -not $_ }).Count -gt 0) {
        Write-Output 'QLIK_NATIVE_ERROR_CONTEXT_BEGIN'
        Get-Content -LiteralPath $log -Tail 95 -ErrorAction Stop | ForEach-Object { Write-Output $_ }
        Write-Output 'QLIK_NATIVE_ERROR_CONTEXT_END'
        throw 'VERDICT=BLOCKED_OR_INCONCLUSIVE_CROSS_FACT_LINK_PREFLIGHT'
    }
    Write-Output 'VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED'
    Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
    Write-Output 'PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED'
    Write-Output 'FACT_QVD_GENERATED=False'
    Write-Output 'LINK_ANALISE_QVD_GENERATED=False'

} finally {
    if ($null -ne $doc) {
        try { $null = $doc.CloseDoc() }
        catch { Write-Warning 'Feche manualmente o QVW isolado, se estiver aberto' }
    }
    # Nao invocar Quit: COM pode reutilizar sessao existente do usuario.
}
