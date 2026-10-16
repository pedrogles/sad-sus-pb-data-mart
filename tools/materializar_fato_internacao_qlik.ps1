# FASE V — ONE-SHOT CREATE + independent physical QVD readback, QlikView Desktop 12.
# Authorized scope: only TRANSFORMACAO/QVD/FATO_INTERNACAO.qvd (must not exist).
# Do not invoke TRANSF.qvw or transf_main.qvs: phase IV would rewrite dimensions.
# No deletes, overwrites, renames, merges or writes to source/dimension QVDs.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)

$branchRequired = 'feat/phase-5-fato-internacao-implementation'
$factQvs = Join-Path $Root 'TRANSFORMACAO\transf_fato_internacao.qvs'
$auditQvs = Join-Path $Root 'TRANSFORMACAO\phase_v_fato_internacao_qvd_readback.qvs'
$createQvw = Join-Path $Root 'TRANSFORMACAO\V5_RD_FATO_INTERNACAO_CREATE.qvw'
$auditQvw = Join-Path $Root 'TRANSFORMACAO\V5_RD_FATO_INTERNACAO_QVD_AUDIT.qvw'
$createLog = "$createQvw.log"
$auditLog = "$auditQvw.log"
$preflightLog = Join-Path $Root 'TRANSFORMACAO\V5_RD_FATO_INTERNACAO_PREFLIGHT.qvw.log'
$factQvd = Join-Path $Root 'TRANSFORMACAO\QVD\FATO_INTERNACAO.qvd'
$inputQvds = @(
    (Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_PROCEDIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_DIAGNOSTICO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_CARATER_ATENDIMENTO.qvd'),
    (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MOTIVO_SAIDA_PERMANENCIA.qvd')
)

# Guard all outputs before any QVW creation/reload. Never replace a partial
# or completed QVD; on failure preserve it for manual inspection.
$requiredFiles = @(
    (Join-Path $Root 'AGENTS.md'),
    (Join-Path $Root 'docs\project\current-state.md'),
    (Join-Path $Root 'docs\academic\requirements.md'),
    $factQvs, $auditQvs, $preflightLog
) + $inputQvds
foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "VERDICT=BLOCKED_MISSING_REQUIRED_INPUT path=$path"
    }
}
foreach ($path in @($factQvd,$createQvw,$auditQvw,$createLog,$auditLog)) {
    if (Test-Path -LiteralPath $path) {
        throw "VERDICT=BLOCKED_OUTPUT_ALREADY_EXISTS_NO_OVERWRITE path=$path"
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'VERDICT=BLOCKED_GIT_MISSING'
}
$actualBranch = (& git -C $Root branch --show-current 2>$null | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $actualBranch -cne $branchRequired) {
    throw "VERDICT=BLOCKED_GIT_BRANCH actual=$actualBranch expected=$branchRequired"
}
$dirtyTracked = @(& git -C $Root status --porcelain --untracked-files=no 2>$null)
if ($LASTEXITCODE -ne 0 -or $dirtyTracked.Count -gt 0) {
    throw 'VERDICT=BLOCKED_TRACKED_WORKTREE_DIRTY'
}

$sourceQvs = [IO.File]::ReadAllText($factQvs, [Text.Encoding]::UTF8)
$auditSource = [IO.File]::ReadAllText($auditQvs, [Text.Encoding]::UTF8)
$sourceSha = (Get-FileHash -LiteralPath $factQvs -Algorithm SHA256).Hash
$auditSha = (Get-FileHash -LiteralPath $auditQvs -Algorithm SHA256).Hash
# Pin to the exact source QVS SHA-256 used by the owner's successful local
# PREFLIGHT. If changed, a new explicit preflight is required before CREATE.
$preflightQvsSha = '5C599F1FCBF54E823A3FF82FAF14EA2176EE2BFAC7D5ABE33743CB4CEC9CC65D'
if ($sourceSha -cne $preflightQvsSha) {
    throw "VERDICT=BLOCKED_FACT_QVS_CHANGED_SINCE_PREFLIGHT actual=$sourceSha"
}
if (-not $sourceQvs.Contains("Hash128('SAD-LINK-V1',") -or
    -not $sourceQvs.Contains('VERDICT=WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT') -or
    -not $sourceQvs.Contains('VERDICT=BLOCKED_EXISTING_FACT_QVD') -or
    -not $sourceQvs.Contains('STORE FATO_INTERNACAO INTO [QVD\FATO_INTERNACAO.qvd] (qvd);') -or
    @([regex]::Matches($sourceQvs, '(?im)^\s*STORE\s+')).Count -ne 1 -or
    $sourceQvs -match '(?im)^\s*(EXECUTE|BINARY|JOIN|LEFT\s+JOIN|RIGHT\s+JOIN)\b') {
    throw 'VERDICT=BLOCKED_FACT_QVS_CREATE_POLICY_MISMATCH'
}
if (-not $auditSource.Contains('VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY') -or
    -not $auditSource.Contains('FROM [QVD\FATO_INTERNACAO.qvd] (qvd);') -or
    $auditSource -match '(?im)^\s*(STORE|EXECUTE|BINARY|JOIN|CONCATENATE)\b') {
    throw 'VERDICT=BLOCKED_AUDIT_QVS_IS_NOT_READ_ONLY'
}
$preflightLines = @(Get-Content -LiteralPath $preflightLog -ErrorAction Stop |
    Where-Object { $_ -match '\[V5-FACT\]' -and $_ -notmatch '\bTRACE\b' })
if (@($preflightLines | Where-Object {
    $_.Contains('[V5-FACT] VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_PHYSICAL_APPROVAL')
}).Count -ne 1 -or
    @($preflightLines | Where-Object {
        $_.Contains('[V5-FACT] SOURCE ROWS=566672 UNIQUE=566672 MONTHS=36 FILES=36 EXTERNAL=5202')
    }).Count -ne 1) {
    throw 'VERDICT=BLOCKED_PREVIOUS_QV_PREFLIGHT_NOT_CONFIRMED'
}
$inputHashes = @{}
foreach ($path in $inputQvds) {
    $inputHashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
# Snapshot every existing QVD in both physical directories, not only the eight
# inputs. The ONLY allowed inventory addition is FATO_INTERNACAO.qvd.
$qvdDirs = @(
    (Join-Path $Root 'EXTRACAO\QVD'),
    (Join-Path $Root 'TRANSFORMACAO\QVD')
)
$initialQvdSha = @{}
foreach ($dir in $qvdDirs) {
    foreach ($qvd in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
        $initialQvdSha[$qvd.FullName] = (Get-FileHash -LiteralPath $qvd.FullName -Algorithm SHA256).Hash
    }
}
Write-Output "EXISTING_QVD_INVENTORY_COUNT=$($initialQvdSha.Count)"

function Same-QlikScript([string]$actual,[string]$expected) {
    return ($actual.Replace([string][char]13,'').TrimEnd() -ceq
            $expected.Replace([string][char]13,'').TrimEnd())
}
function Create-IsolatedDocument($qv,[string]$path,[string]$scriptText) {
    if (Test-Path -LiteralPath $path) { throw "VERDICT=BLOCKED_QVW_EXISTS path=$path" }
    $d = $qv.CreateDoc()
    if ($null -eq $d) { throw "VERDICT=BLOCKED_QVW_CREATE_DOC path=$path" }
    $props = $d.GetProperties()
    $props.Script = $scriptText
    $props.GenerateLogfile = $true
    $null = $d.SetProperties($props)
    if (-not (Same-QlikScript ([string]$d.GetProperties().Script) $scriptText) -or
        -not [bool]$d.GetProperties().GenerateLogfile) {
        throw "VERDICT=BLOCKED_QVW_SCRIPT_OR_LOG_MISMATCH path=$path"
    }
    $null = $d.SaveAs($path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "VERDICT=BLOCKED_QVW_SAVE path=$path"
    }
    return $d
}
function Read-NativeMarkers([string]$path,[DateTime]$after,[string]$prefix,
                            [string[]]$mandatory) {
    $lines = @()
    $fresh = $false
    for ($attempt=0; $attempt -lt 20; $attempt++) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $fresh = (Get-Item -LiteralPath $path).LastWriteTimeUtc -ge $after.AddSeconds(-2)
            if ($fresh) {
                $lines = @(Get-Content -LiteralPath $path -ErrorAction Stop |
                    Where-Object { $_.Contains($prefix) -and $_ -notmatch '\bTRACE\b' })
                if (@($lines | Where-Object { $_ -match 'VERDICT=(PASS|BLOCKED|WRITTEN)' }).Count -gt 0) {
                    break
                }
            }
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $fresh) { throw "VERDICT=BLOCKED_NO_FRESH_QLIK_LOG path=$path" }
    foreach ($marker in $mandatory) {
        if (@($lines | Where-Object { $_.Contains($marker) }).Count -ne 1) {
            throw "VERDICT=BLOCKED_NATIVE_LOG_MISSING_OR_DUPLICATE path=$path marker=$marker"
        }
    }
    if (@($lines | Where-Object { $_ -match 'VERDICT=BLOCKED' }).Count -gt 0) {
        throw "VERDICT=BLOCKED_QLIK_NATIVE_FAILURE path=$path"
    }
    foreach ($line in $lines) { Write-Output $line }
}
function Assert-SourceHashes([string]$stage) {
    foreach ($path in $inputQvds) {
        $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        if ($actual -cne $inputHashes[$path]) {
            throw "VERDICT=BLOCKED_INPUT_QVD_CHANGED stage=$stage path=$path"
        }
    }
    Write-Output "ALL_8_INPUT_QVD_SHA256_UNCHANGED=$stage"
}
function Assert-QvdInventory([string]$stage) {
    $seen = @{}
    foreach ($dir in $qvdDirs) {
        foreach ($qvd in @(Get-ChildItem -LiteralPath $dir -Filter '*.qvd' -File -ErrorAction Stop)) {
            $name = $qvd.FullName
            $seen[$name] = 1
            if ($initialQvdSha.ContainsKey($name)) {
                if ($initialQvdSha[$name] -cne
                    (Get-FileHash -LiteralPath $name -Algorithm SHA256).Hash) {
                    throw "VERDICT=BLOCKED_PREEXISTING_QVD_SHA_CHANGED stage=$stage path=$name"
                }
            } elseif ($name -cne $factQvd) {
                throw "VERDICT=BLOCKED_UNEXPECTED_NEW_QVD stage=$stage path=$name"
            }
        }
    }
    foreach ($name in $initialQvdSha.Keys) {
        if (-not $seen.ContainsKey($name)) {
            throw "VERDICT=BLOCKED_EXISTING_QVD_MISSING stage=$stage path=$name"
        }
    }
    if (-not $seen.ContainsKey($factQvd)) {
        throw "VERDICT=BLOCKED_CREATED_FACT_QVD_NOT_IN_INVENTORY stage=$stage"
    }
    Write-Output "ALL_PREEXISTING_QVD_SHA256_UNCHANGED=$stage"
    Write-Output "ONLY_NEW_QVD_IS_FATO_INTERNACAO=$stage"
}

$qv = $null
$createDoc = $null
$auditDoc = $null
$factShaAfterCreate = $null
$phase = 'INIT'
try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    Write-Output 'MODE=PHASE_V_FATO_INTERNACAO_ONE_SHOT_CREATE_AND_READBACK'
    Write-Output "BRANCH=$actualBranch"
    Write-Output "FACT_QVS_SHA256=$sourceSha"
    Write-Output "AUDIT_QVS_SHA256=$auditSha"
    Write-Output "FACT_TARGET=$factQvd"
    Write-Output 'SOURCE_QVDS_READ_ONLY=True TRANSF_MAIN_NOT_EXECUTED=True'

    $phase = 'CREATE'
    $createScript = 'SET ErrorMode=0;' + [Environment]::NewLine +
        'SET vP5FatoInternacaoMode=CREATE;' + [Environment]::NewLine + $sourceQvs
    $createDoc = Create-IsolatedDocument $qv $createQvw $createScript
    $createStart = [DateTime]::UtcNow
    Write-Output 'CREATE_RELOAD_STARTED=True'
    $createApi = $createDoc.Reload()
    Write-Output 'CREATE_RELOAD_RETURNED=True'
    Write-Output "CREATE_RELOAD_API_RETURN=$createApi"

    if (-not (Test-Path -LiteralPath $factQvd -PathType Leaf) -or
        (Get-Item -LiteralPath $factQvd).Length -le 0 -or
        (Get-Item -LiteralPath $factQvd).LastWriteTimeUtc -lt $createStart.AddSeconds(-2)) {
        throw 'VERDICT=BLOCKED_NEW_QVD_MISSING_EMPTY_OR_NOT_CONTEMPORANEOUS'
    }
    Assert-SourceHashes 'AFTER_CREATE'
    Assert-QvdInventory 'AFTER_CREATE'
    Read-NativeMarkers $createLog $createStart '[V5-FACT]' @(
        '[V5-FACT] ROLES COMP=0 ANO=0 INTER=0 SAIDA=0 RES=0 SERV=0 EST=0 PROC=0 DIAG=0 CAR=0 MOT=0',
        '[V5-FACT] SOURCE ROWS=566672 UNIQUE=566672 MONTHS=36 FILES=36 EXTERNAL=5202 NULL=0 REG=566672 NEW=555089 CONT=11583 DAYS=3133578 DEATHS=26611 CENTS=65938464905 INVALID=0',
        '[V5-FACT] YEARS=3 YEAR_BAD=0',
        '[V5-FACT] VERDICT=WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT'
    )
    $factShaAfterCreate = (Get-FileHash -LiteralPath $factQvd -Algorithm SHA256).Hash
    Write-Output "FACT_QVD_SHA256_AFTER_CREATE=$factShaAfterCreate"
    Write-Output "FACT_QVD_SIZE_BYTES=$((Get-Item -LiteralPath $factQvd).Length)"
    $null = $createDoc.CloseDoc()
    $createDoc = $null

    $phase = 'READBACK'
    $auditDoc = Create-IsolatedDocument $qv $auditQvw $auditSource
    $auditStart = [DateTime]::UtcNow
    Write-Output 'AUDIT_RELOAD_STARTED=True'
    $auditApi = $auditDoc.Reload()
    Write-Output 'AUDIT_RELOAD_RETURNED=True'
    Write-Output "AUDIT_RELOAD_API_RETURN=$auditApi"
    Assert-SourceHashes 'AFTER_AUDIT'
    Assert-QvdInventory 'AFTER_AUDIT'
    if ($factShaAfterCreate -cne (Get-FileHash -LiteralPath $factQvd -Algorithm SHA256).Hash) {
        throw 'VERDICT=BLOCKED_FACT_QVD_SHA_CHANGED_DURING_READBACK'
    }
    Read-NativeMarkers $auditLog $auditStart '[V5-FACT-AUDIT]' @(
        '[V5-FACT-AUDIT] HEADER ROWS=566672 FIELDS=17',
        '[V5-FACT-AUDIT] SCHEMA_EXACT_17=True',
        '[V5-FACT-AUDIT] TOTAL ROWS=566672 UNIQUE=566672 LINKS=77550 MONTHS=36 FILES=36 NULL=0 REG=566672 NEW=555089 CONT=11583 DEATHS=26611 DAYS=3133578 CENTS=65938464905 INVALID=0',
        '[V5-FACT-AUDIT] ANNUAL YEARS=3 BAD=0',
        '[V5-FACT-AUDIT] VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY'
    )
    Write-Output "FACT_QVD_SHA256_VERIFIED=$factShaAfterCreate"
    Write-Output 'VERDICT=PASS_QV_FACT_QVD_MATERIALIZED_AND_REOPENED_CANDIDATE_ONLY'
    Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
    Write-Output 'PRODUCTION_APPROVED=False'
}
catch {
    Write-Output "VERDICT=BLOCKED_CREATE_OR_AUDIT phase=$phase"
    Write-Output "RUNNER_FAILURE=$($_.Exception.Message)"
    foreach ($path in @($createLog,$auditLog)) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Write-Output "NATIVE_ERROR_CONTEXT_BEGIN path=$path"
            Get-Content -LiteralPath $path -Tail 70 -ErrorAction SilentlyContinue |
                ForEach-Object { Write-Output $_ }
            Write-Output 'NATIVE_ERROR_CONTEXT_END'
        }
    }
    Write-Output "FACT_TARGET_RETAINED_IF_PRESENT=$factQvd"
    throw
}
finally {
    if ($null -ne $auditDoc) {
        try { $null = $auditDoc.CloseDoc() }
        catch { Write-Warning 'Feche manualmente QVW de auditoria.' }
    }
    if ($null -ne $createDoc) {
        try { $null = $createDoc.CloseDoc() }
        catch { Write-Warning 'Feche manualmente QVW de criacao.' }
    }
    # Even after error, compare the eight source hashes; never restore/write
    # them automatically. A preexisting/partial fact QVD is never deleted.
    foreach ($path in $inputQvds) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $nowHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            if ($nowHash -cne $inputHashes[$path]) {
                Write-Warning "BLOCKED_INPUT_QVD_CHANGED_AT_FINALLY path=$path"
            }
        }
    }
    # QlikView COM can reuse an existing session: do not invoke Quit().
}
