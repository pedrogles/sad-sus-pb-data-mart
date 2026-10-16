# Gate da Fase V: executar apenas a candidata FATO_INTERNACAO em QVW isolado.
# Base do runner: validadores de medidas/papeis R3 ja integrados na main.
# Nao executar transf_main.qvs: seus scripts regravam QVDs dimensionais.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$qvs = Join-Path $Root 'TRANSFORMACAO\transf_fato_internacao.qvs'
$qvw = Join-Path $Root 'TRANSFORMACAO\V5_RD_FATO_INTERNACAO_PREFLIGHT.qvw'
$log = "$qvw.log"
$fact = Join-Path $Root 'TRANSFORMACAO\QVD\FATO_INTERNACAO.qvd'
$inputs = @(
    (Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_PROCEDIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_DIAGNOSTICO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_CARATER_ATENDIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MOTIVO_SAIDA_PERMANENCIA.qvd')
)
$required = @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    $qvs
) + $inputs
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "VERDICT=BLOCKED_MISSING_INPUT path=$path"
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'VERDICT=BLOCKED_GIT_UNAVAILABLE'
}
$branch = (& git -C $Root branch --show-current 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -cne 'feat/phase-5-fato-internacao-implementation') {
    throw "VERDICT=BLOCKED_UNEXPECTED_GIT_BRANCH branch=$branch"
}
$trackedChanges = @(& git -C $Root status --porcelain --untracked-files=no 2>$null)
if ($LASTEXITCODE -ne 0 -or $trackedChanges.Count -gt 0) {
    throw 'VERDICT=BLOCKED_TRACKED_WORKTREE_NOT_CLEAN'
}
$raw = [IO.File]::ReadAllText($qvs, [Text.Encoding]::UTF8)
if (-not $raw.Contains('VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_PHYSICAL_APPROVAL') -or
    -not $raw.Contains('STORE FATO_INTERNACAO INTO [QVD\FATO_INTERNACAO.qvd] (qvd);') -or
    -not $raw.Contains('IF ''$(vP5FatoInternacaoMode)'' = ''PREFLIGHT'' THEN') -or
    -not $raw.Contains("Hash128('SAD-LINK-V1',") -or
    @([regex]::Matches($raw, '(?im)^\s*STORE\s+')).Count -ne 1 -or
    $raw -match '(?im)^\s*(BINARY|EXECUTE|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN)\b') {
    throw 'VERDICT=BLOCKED_QVS_POLICY_MISMATCH'
}
# SET no documento descartavel, sem alterar o QVS versionado.
$script = 'SET ErrorMode=0;' + [Environment]::NewLine +
          'SET vP5FatoInternacaoMode=PREFLIGHT;' + [Environment]::NewLine + $raw
function SameScript([string]$actual, [string]$expected) {
    return ($actual.Replace([string][char]13,'').TrimEnd() -ceq
            $expected.Replace([string][char]13,'').TrimEnd())
}
$hashes = @{}
foreach ($path in $inputs) {
    $hashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$factExisted = Test-Path -LiteralPath $fact -PathType Leaf
$factHash = if ($factExisted) { (Get-FileHash -LiteralPath $fact -Algorithm SHA256).Hash } else { $null }
$scriptHash = (Get-FileHash -LiteralPath $qvs -Algorithm SHA256).Hash
$qv = $null
$doc = $null
try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    if (Test-Path -LiteralPath $qvw -PathType Leaf) {
        $doc = $qv.OpenDoc($qvw, '', '')
        if ($null -eq $doc) { throw 'VERDICT=BLOCKED_OPEN_QVW' }
        if (-not (SameScript ([string]$doc.GetProperties().Script) $script) -or
            -not [bool]$doc.GetProperties().GenerateLogfile) {
            throw 'VERDICT=BLOCKED_PREEXISTING_QVW_SCRIPT_MISMATCH'
        }
        Write-Output 'DOCUMENT_REUSED=True'
    } else {
        $doc = $qv.CreateDoc()
        if ($null -eq $doc) { throw 'VERDICT=BLOCKED_CREATE_DOC' }
        $p = $doc.GetProperties()
        $p.Script = $script
        $p.GenerateLogfile = $true
        $null = $doc.SetProperties($p)
        if (-not (SameScript ([string]$doc.GetProperties().Script) $script) -or
            -not [bool]$doc.GetProperties().GenerateLogfile) {
            throw 'VERDICT=BLOCKED_NEW_QVW_SCRIPT_MISMATCH'
        }
        $null = $doc.SaveAs($qvw)
        if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {
            throw 'VERDICT=BLOCKED_QVW_NOT_SAVED'
        }
        Write-Output 'DOCUMENT_REUSED=False'
    }
    Write-Output 'MODE=PHASE_V_FATO_INTERNACAO_ISOLATED_PREFLIGHT'
    Write-Output "SCRIPT_SHA256=$scriptHash"
    Write-Output "TEST_QVW=$qvw"
    Write-Output 'TRANSF_MAIN_NOT_EXECUTED=True'
    Write-Output 'NO_FACT_QVD_STORE_REQUESTED=True'
    $started = [DateTime]::UtcNow
    Write-Output 'RELOAD_STARTED=True'
    $retval = $doc.Reload()
    Write-Output 'RELOAD_RETURNED=True'
    Write-Output "RELOAD_API_RETURN=$retval"
    foreach ($path in $inputs) {
        if ($hashes[$path] -cne (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash) {
            throw "VERDICT=BLOCKED_SOURCE_QVD_SHA_CHANGED path=$path"
        }
    }
    Write-Output 'ALL_8_INPUT_QVD_SHA256_UNCHANGED=True'
    if ((Test-Path -LiteralPath $fact -PathType Leaf) -ne $factExisted) {
        throw 'VERDICT=BLOCKED_FACT_QVD_PRESENCE_CHANGED'
    }
    if ($factExisted -and $factHash -cne (Get-FileHash -LiteralPath $fact -Algorithm SHA256).Hash) {
        throw 'VERDICT=BLOCKED_PREEXISTING_FACT_QVD_SHA_CHANGED'
    }
    Write-Output 'FACT_QVD_UNCHANGED_OR_ABSENT=True'
    $lines = @()
    $fresh = $false
    for ($n = 0; $n -lt 16; $n++) {
        if (Test-Path -LiteralPath $log -PathType Leaf) {
            $fresh = (Get-Item -LiteralPath $log).LastWriteTimeUtc -ge $started.AddSeconds(-2)
            if ($fresh) {
                $lines = @(Get-Content -LiteralPath $log |
                    Where-Object { $_ -match '\[V5-FACT\]' -and $_ -notmatch '\bTRACE\b' })
                if (@($lines | Where-Object { $_ -match 'VERDICT=(PASS|BLOCKED)' }).Count -gt 0) {
                    break
                }
            }
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $fresh) { throw 'VERDICT=INCONCLUSIVE_NO_FRESH_NATIVE_LOG' }
    Write-Output "LOG=$log"
    $expected = @(
        '[V5-FACT] ROLES COMP=0 ANO=0 INTER=0 SAIDA=0 RES=0 SERV=0 EST=0 PROC=0 DIAG=0 CAR=0 MOT=0',
        '[V5-FACT] SOURCE ROWS=566672 UNIQUE=566672 MONTHS=36 FILES=36 EXTERNAL=5202 NULL=0 REG=566672 NEW=555089 CONT=11583 DAYS=3133578 DEATHS=26611 CENTS=65938464905 INVALID=0',
        '[V5-FACT] YEARS=3 YEAR_BAD=0',
        '[V5-FACT] VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_PHYSICAL_APPROVAL',
        '[V5-FACT] FACT_QVD_GENERATED=False'
    )
    foreach ($marker in $expected) {
        if (@($lines | Where-Object { $_.Contains($marker) }).Count -ne 1) {
            throw "VERDICT=BLOCKED_MISSING_OR_DUPLICATE_NATIVE_MARKER marker=$marker"
        }
    }
    if (@($lines | Where-Object { $_ -match '\[V5-FACT\] VERDICT=BLOCKED' }).Count -gt 0 -or
        -not (@($lines | Where-Object {
            $_ -match '\[V5-FACT\] OUTPUT UNIQUE=566672 NULL=0 LINKS=[1-9][0-9]* ROWS=566672 NEW=555089 DAYS=3133578 DEATHS=26611 CENTS=65938464905'
        }).Count -eq 1)) {
        throw 'VERDICT=BLOCKED_OUTPUT_OR_NATIVE_ERROR'
    }
    foreach ($line in $lines) { Write-Output $line }
    Write-Output 'VERDICT=PASS_ISOLATED_FACT_PREFLIGHT_NOT_QVD_APPROVAL'
    Write-Output 'FACT_QVD_GENERATED=False'
    Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
} catch {
    Write-Output "RUNNER_FAILURE=$($_.Exception.Message)"
    if (Test-Path -LiteralPath $log -PathType Leaf) {
        Write-Output 'QLIK_NATIVE_ERROR_CONTEXT_BEGIN'
        Get-Content -LiteralPath $log -Tail 85 -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_ }
        Write-Output 'QLIK_NATIVE_ERROR_CONTEXT_END'
    }
    throw
} finally {
    if ($null -ne $doc) {
        try { $null = $doc.CloseDoc() }
        catch { Write-Warning 'Feche manualmente o QVW de teste, se necessario.' }
    }
    # Do not Quit: COM can share the interactive QlikView session.
}
