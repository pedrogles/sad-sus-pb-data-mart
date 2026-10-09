# Fase V — criacao segura de documento isolado QlikView 12 a partir de QVS versionado.
# O script de carga canonico e TRANSFORMACAO/phase_v_fato_internacao_qlik_sk_preflight.qvs.
# Esta versao substitui o bootstrap avulso que EMBUTIA o QVS; fluxo novo ainda nao reexecutado no Windows.
[CmdletBinding()]
param(
    [string]$Root = (Get-Location).Path,
    [switch]$Reload
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$transf = Join-Path $Root 'TRANSFORMACAO'
$source = Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'
$qvs = Join-Path $transf 'phase_v_fato_internacao_qlik_sk_preflight.qvs'
$target = Join-Path $transf 'V5_RD_SK_PREFLIGHT.qvw'
foreach ($path in @((Join-Path $Root 'AGENTS.md'), $source, $qvs)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Pre-requisito ausente: $path"
    }
}
if (Test-Path -LiteralPath $target) {
    throw "Documento ja existe; nao sobrescrever: $target"
}
$script = [IO.File]::ReadAllText($qvs, [Text.Encoding]::UTF8)
if (-not $script.Contains('[V5-RD-SK] START READ_ONLY STAGING QVD PROJECTION') -or
    -not $script.Contains('PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY') -or
    $script -notmatch '\.\.\\EXTRACAO\\QVD\\SRC_SIH_RD\.qvd' -or
    $script -match '(?im)^\s*(STORE|JOIN|CONCATENATE|DROP\s+FIELD)\b') {
    throw 'QVS versionado nao atende contrato de preflight isolado'
}
$sourceShaBefore = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$scriptSha = (Get-FileHash -LiteralPath $qvs -Algorithm SHA256).Hash
$doc = $null
try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    $doc = $qv.CreateDoc()
    if ($null -eq $doc) { throw 'CreateDoc nao retornou documento' }
    $properties = $doc.GetProperties()
    $properties.Script = $script
    $properties.GenerateLogfile = $true
    $null = $doc.SetProperties($properties)
    if (-not ([string]$doc.GetProperties().Script).Contains('[V5-RD-SK] START')) {
        throw 'QlikView nao confirmou o QVS carregado'
    }
    $null = $doc.SaveAs($target)
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        throw 'SaveAs nao criou o QVW'
    }
    Write-Output 'MODE=PHASE_V_QVW_FROM_VERSIONED_QVS'
    Write-Output "SCRIPT_SOURCE=$qvs"
    Write-Output "SCRIPT_SHA256=$scriptSha"
    Write-Output "DOCUMENT_CREATED=$target"
    Write-Output 'FACT_QVD_GENERATED=False'
    if ($Reload) {
        $started = [DateTime]::UtcNow
        Write-Output 'RELOAD_STARTED=True'
        $null = $doc.Reload()
        Write-Output 'RELOAD_RETURNED=True'
        $log = "$target.log"
        if ((Test-Path -LiteralPath $log -PathType Leaf) -and
            (Get-Item -LiteralPath $log).LastWriteTimeUtc -ge $started.AddSeconds(-2)) {
            $lines = @(Get-Content -LiteralPath $log |
                Where-Object { $_ -match '\[V5-RD-SK\]' -and $_ -notmatch '\bTRACE\b' })
            foreach ($line in ($lines | Select-Object -Last 8)) { Write-Output $line }
            if (-not @($lines | Where-Object {
                $_ -match 'VERDICT=PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY'
            }).Count) { throw 'Sem PASS executado no log contemporaneo' }
            Write-Output 'VERDICT=PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY'
        } else {
            Write-Output 'VERDICT=INCONCLUSIVE_NO_CONTEMPORANEOUS_LOG'
            throw 'Log contemporaneo nao encontrado'
        }
    } else { Write-Output 'RELOAD_STARTED=False' }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $sourceShaBefore) {
        throw 'Staging QVD alterado durante a criacao/recarga'
    }
    Write-Output 'STAGING_QVD_SHA256_UNCHANGED=True'
} finally {
    if ($null -ne $doc) {
        try { $null = $doc.CloseDoc() } catch { Write-Warning 'Feche manualmente o QVW de teste' }
    }
    # Nao invocar Quit, pois a instancia COM pode estar compartilhada com o usuario.
}
