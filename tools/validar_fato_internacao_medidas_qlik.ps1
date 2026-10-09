# Fase V — run isolated QlikView 12 fact-measures preflight from versioned .qvs.
# Reads only SRC_SIH_RD.qvd and creates/opens one isolated ignored .qvw.
# No fact QVD, output dataset, checkpoint, Link Table or production .qvw writes.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$qvs = Join-Path $Root 'TRANSFORMACAO\phase_v_fato_internacao_qlik_measures_preflight.qvs'
$qvw = Join-Path $Root 'TRANSFORMACAO\V5_RD_MEASURE_PREFLIGHT.qvw'
$staging = Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'
$log = "$qvw.log"
foreach ($item in @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    $qvs, $staging
)) {
    if (-not (Test-Path -LiteralPath $item -PathType Leaf)) {
        throw "Arquivo requerido ausente: $item"
    }
}
$script = [IO.File]::ReadAllText($qvs, [Text.Encoding]::UTF8)
if (-not $script.Contains('[V5-RD-MEAS] START QVD_STAGING_READ_ONLY') -or
    -not $script.Contains('VERDICT=PASS_QVD_STAGING_FIVE_MEASURES_RECONCILED') -or
    -not $script.Contains('FROM [..\EXTRACAO\QVD\SRC_SIH_RD.qvd] (qvd);') -or
    $script -match '(?im)^\s*(STORE|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN|CONCATENATE|BINARY|EXECUTE)\b') {
    throw 'QVS versionado nao atende ao contrato isolado, sem STORE/JOIN'
}

$sourceShaBefore = (Get-FileHash -LiteralPath $staging -Algorithm SHA256).Hash
$scriptSha = (Get-FileHash -LiteralPath $qvs -Algorithm SHA256).Hash
$qv = $null
$doc = $null
try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    if (Test-Path -LiteralPath $qvw -PathType Leaf) {
        $doc = $qv.OpenDoc($qvw, '', '')
        if ($null -eq $doc) { throw "Nao foi possivel abrir o QVW: $qvw" }
        if ([string]$doc.GetProperties().Script -cne $script) {
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
        if ([string]$doc.GetProperties().Script -cne $script -or
            -not [bool]$doc.GetProperties().GenerateLogfile) {
            throw 'QlikView nao confirmou script ou GenerateLogfile'
        }
        $null = $doc.SaveAs($qvw)
        if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {
            throw 'SaveAs nao criou QVW de teste'
        }
        Write-Output 'DOCUMENT_REUSED=False'
    }

    Write-Output 'MODE=PHASE_V_QV_STAGING_MEASURES_READ_ONLY'
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

    $currentSha = (Get-FileHash -LiteralPath $staging -Algorithm SHA256).Hash
    if ($sourceShaBefore -cne $currentSha) {
        throw 'Staging QVD SHA256 mudou; interromper e investigar'
    }
    Write-Output 'STAGING_QVD_SHA256_UNCHANGED=True'

    $lines = @()
    $freshLog = $false
    for ($attempt = 0; $attempt -lt 16; $attempt++) {
        if (Test-Path -LiteralPath $log -PathType Leaf) {
            $file = Get-Item -LiteralPath $log
            $freshLog = $file.LastWriteTimeUtc -ge $started.AddSeconds(-2)
            if ($freshLog) {
                $lines = @(Get-Content -LiteralPath $log -ErrorAction Stop |
                    Where-Object { $_ -match '\[V5-RD-MEAS\]' -and $_ -notmatch '\bTRACE\b' })
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
        $_.Contains('[V5-RD-MEAS] VERDICT=PASS_QVD_STAGING_FIVE_MEASURES_RECONCILED')
    }).Count -eq 1
    $failed = @($lines | Where-Object {
        $_ -match '\[V5-RD-MEAS\] VERDICT=BLOCKED'
    }).Count -gt 0
    $total = @($lines | Where-Object {
        $_ -match 'TOTAL ROWS=566672 NEW=555089 CONT=11583 DEATHS=26611 DAYS=3133578 VALUE_CENTS=65938464905 MONTHS=36 INVALID=0 BAD=0'
    }).Count -eq 1
    $byYear = @('2017', '2018', '2019') | ForEach-Object {
        $target = "YEAR=$_ "
        @($lines | Where-Object {
            $_.Contains($target) -and $_.Contains(' BAD=0')
        }).Count -eq 1
    }
    if (-not $success -or $failed -or -not $total -or
        @($byYear | Where-Object { -not $_ }).Count -gt 0) {
        throw 'VERDICT=BLOCKED_OR_INCONCLUSIVE_CHECK_QLIK_LOG'
    }

    Write-Output 'VERDICT=PASS_QVD_STAGING_FIVE_MEASURES_RECONCILED'
    Write-Output 'DIMENSION_ASSOCIATION_GATE=NOT_EXECUTED'
    Write-Output 'LINK_KEY_GATE=NOT_EXECUTED'
} finally {
    if ($null -ne $doc) {
        try { $null = $doc.CloseDoc() }
        catch { Write-Warning 'Feche manualmente o QVW isolado, se estiver aberto' }
    }
    # Nao invocar Quit: COM pode reutilizar sessao existente do usuario.
}
