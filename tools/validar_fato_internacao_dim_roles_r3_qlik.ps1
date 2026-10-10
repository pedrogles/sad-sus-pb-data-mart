# Fase V — run R3 isolated QlikView 12 11-dimensional-role coverage from versioned QVS.
# Reads 1 RD staging QVD and 7 dimension QVDs; creates isolated ignored QVW only.
# R3 creates new QVW; preserves dimensional R1 and R2, plus all measure preflights.
# No fact QVD, output dataset, checkpoint, Link Table or production .qvw writes.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$qvs = Join-Path $Root 'TRANSFORMACAO\phase_v_fato_internacao_qlik_dim_roles_preflight_r3.qvs'
$qvw = Join-Path $Root 'TRANSFORMACAO\V5_RD_DIM_ROLES_PREFLIGHT_R3.qvw'
$staging = Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'
$log = "$qvw.log"
foreach ($item in @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    $qvs, $staging,
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_PROCEDIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_DIAGNOSTICO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_CARATER_ATENDIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MOTIVO_SAIDA_PERMANENCIA.qvd')
)) {
    if (-not (Test-Path -LiteralPath $item -PathType Leaf)) {
        throw "Arquivo requerido ausente: $item"
    }
}
$script = [IO.File]::ReadAllText($qvs, [Text.Encoding]::UTF8)
if (-not $script.Contains('[V5-RD-DIM3] START ONLY_READ_STAGING_AND_DIM_QVDS') -or
    -not $script.Contains('VERDICT=PASS_QV_STAGING_11_DIMENSION_ROLES_NO_ORPHANS') -or
    -not $script.Contains('FROM [..\EXTRACAO\QVD\SRC_SIH_RD.qvd] (qvd);') -or
    $script -match '(?im)^\s*(STORE|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN|CONCATENATE|BINARY|EXECUTE)\b') {
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
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_PROCEDIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_DIAGNOSTICO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_CARATER_ATENDIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MOTIVO_SAIDA_PERMANENCIA.qvd')
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

    Write-Output 'MODE=PHASE_V_QV_DIMENSION_ROLES_READ_ONLY'
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
    Write-Output 'ALL_8_INPUT_QVD_SHA256_UNCHANGED=True'

    $lines = @()
    $freshLog = $false
    for ($attempt = 0; $attempt -lt 16; $attempt++) {
        if (Test-Path -LiteralPath $log -PathType Leaf) {
            $file = Get-Item -LiteralPath $log
            $freshLog = $file.LastWriteTimeUtc -ge $started.AddSeconds(-2)
            if ($freshLog) {
                $lines = @(Get-Content -LiteralPath $log -ErrorAction Stop |
                    Where-Object { $_ -match '\[V5-RD-DIM3\]' -and $_ -notmatch '\bTRACE\b' })
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
        $_.Contains('[V5-RD-DIM3] VERDICT=PASS_QV_STAGING_11_DIMENSION_ROLES_NO_ORPHANS')
    }).Count -eq 1
    $failed = @($lines | Where-Object {
        $_ -match '\[V5-RD-DIM3\] VERDICT=BLOCKED'
    }).Count -gt 0
    $total = @($lines | Where-Object {
        $_.Contains('TOTAL ROWS=566672 MONTHS=36 EXTERNAL=5202 MISS_COMP=0 MISS_ANO=0 MISS_INTER=0 MISS_SAIDA=0 MISS_RES=0 MISS_SERV=0 MISS_ESTAB=0 MISS_PROC=0 MISS_DIAG=0 MISS_CAR=0 MISS_MOT=0')
    }).Count -eq 1
    if (-not $success -or $failed -or -not $total) {
        Write-Output 'QLIK_NATIVE_ERROR_CONTEXT_BEGIN'
        Get-Content -LiteralPath $log -Tail 85 -ErrorAction Stop | ForEach-Object { Write-Output $_ }
        Write-Output 'QLIK_NATIVE_ERROR_CONTEXT_END'
        throw 'VERDICT=BLOCKED_OR_INCONCLUSIVE_CHECK_QLIK_DIMENSION_LOG'
    }

    Write-Output 'VERDICT=PASS_QV_STAGING_11_DIMENSION_ROLES_NO_ORPHANS'
    Write-Output 'ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED'
    Write-Output 'LINK_KEY_GATE=NOT_EXECUTED'
    Write-Output 'FACT_QVD_GENERATED=False'

} finally {
    if ($null -ne $doc) {
        try { $null = $doc.CloseDoc() }
        catch { Write-Warning 'Feche manualmente o QVW isolado, se estiver aberto' }
    }
    # Nao invocar Quit: COM pode reutilizar sessao existente do usuario.
}
