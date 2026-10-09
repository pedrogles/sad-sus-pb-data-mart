# SAD — Fase V / FATO_INTERNACAO: igualdade EXATA do conjunto de SK entre 2 reloads QlikView 12.
# READ-ONLY para repositorio, staging, QVDs e documentos existentes.
# Cria somente artefatos TEMPORARIOS sob %TEMP%, apagados em caso de PASS.
# Reutiliza diretamente o script do QVW original ja validado, com a MESMA expressao Hash128.
# Requer: QlikView Desktop 12 COM, Python 3 no .venv e arquivo V5_RD_SK_PREFLIGHT.qvw.
# Uso: powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME\Downloads\validar_estabilidade_sk_fato_internacao.ps1" -Root (Get-Location).Path
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath($Root)
$originalDoc = Join-Path $Root 'TRANSFORMACAO\V5_RD_SK_PREFLIGHT.qvw'
$sourceQvd = Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd'
$python = Join-Path $Root '.venv\Scripts\python.exe'

foreach ($p in @((Join-Path $Root 'AGENTS.md'), (Join-Path $Root 'docs\project\current-state.md'), $originalDoc, $sourceQvd, $python)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw "Arquivo requerido ausente: $p" }
}
if (-not $sourceQvd.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) { throw 'Origem fora da raiz esperada' }

$work = Join-Path ([System.IO.Path]::GetTempPath()) ('SAD_V5_RD_STABILITY_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -ErrorAction Stop | Out-Null
$testDoc = Join-Path $work 'V5_RD_SK_STABILITY.qvw'
$log = "$testDoc.log"
$export = Join-Path $work 'keys.txt'
$runA = Join-Path $work 'run_a.txt'
$runB = Join-Path $work 'run_b.txt'
$pyFile = Join-Path $work 'compare_keys.py'
$qv = $null
$original = $null
$doc = $null
$verified = $false

# A comparacao e de CONJUNTOS EXATOS, nao apenas de contagem ou checksums de totais.
# Hash de conjunto ordenado e emitido apenas como indicador auditable adicional.
$py = @'
import hashlib
import sys
from pathlib import Path

EXPECTED = 566672
HEADER = '_V5_SK_CANDIDATE'


def load(path):
    seen = set()
    dup = 0
    count = 0
    with Path(path).open('r', encoding='utf-8-sig', newline='') as f:
        for line_number, raw in enumerate(f, 1):
            value = raw.rstrip('\r\n')
            if line_number == 1 and value.strip('"') == HEADER:
                continue
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1].replace('""', '"')
            if len(value) != 22 or not value.isascii() or not value.isprintable():
                raise ValueError(f'{path}: chave invalida na linha {line_number}, len={len(value)}')
            count += 1
            if value in seen:
                dup += 1
            seen.add(value)
    if count != EXPECTED or len(seen) != EXPECTED or dup != 0:
        raise ValueError(f'{path}: rows={count} unique={len(seen)} duplicate={dup}; esperado {EXPECTED}/0')
    fingerprint = hashlib.sha256(('\n'.join(sorted(seen)) + '\n').encode('ascii')).hexdigest()
    return seen, fingerprint, count


def main():
    s1, h1, n1 = load(sys.argv[1])
    s2, h2, n2 = load(sys.argv[2])
    print('MODE=PHASE_V_SK_STABILITY_EXACT_SET_COMPARE')
    print(f'RUN_A_ROWS={n1} RUN_B_ROWS={n2}')
    print(f'RUN_A_UNIQUE_SK={len(s1)} RUN_B_UNIQUE_SK={len(s2)}')
    print(f'RUN_A_SORTED_SET_SHA256={h1}')
    print(f'RUN_B_SORTED_SET_SHA256={h2}')
    print(f'ONLY_A_KEYS={len(s1 - s2)} ONLY_B_KEYS={len(s2 - s1)}')
    if s1 == s2 and h1 == h2:
        print('VERDICT=PASS_2_RELOADS_EXACT_566672_SK_SET_MATCH')
        print('KEY_SCOPE=IMMUTABLE_2017_2019_SOURCE_SNAPSHOT_ONLY')
        return 0
    print('VERDICT=FAIL_CLOSED_SK_SET_DIFF')
    return 3


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except Exception as e:
        print(f'VERDICT=FAIL_CLOSED_COMPARATOR_{type(e).__name__}: {e}')
        raise SystemExit(2)
'@

function Invoke-ReadOnlyReload([int]$number, [string]$moveTo) {
    # Reload por OpenDoc/CloseDoc separados: nao reutiliza tabela carregada em memoria.
    if (Test-Path -LiteralPath $export) { throw "Export anterior ainda presente: $export" }
    if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force -ErrorAction Stop }
    $local:doc = $null
    try {
        $local:doc = $qv.OpenDoc($testDoc, '', '')
        if ($null -eq $local:doc) { throw "Falha OpenDoc da recarga $number" }
        $s = [string]$local:doc.GetProperties().Script
        if (-not $s.Contains('[V5-RD-STABILITY] EXPORT_COMPLETE') -or -not $s.Contains('PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY')) {
            throw 'Script da copia de teste mudou inesperadamente'
        }
        $started = [DateTime]::UtcNow
        Write-Output "RUN_${number}_RELOAD_STARTED=True"
        $null = $local:doc.Reload()
        Write-Output "RUN_${number}_RELOAD_RETURNED=True"
        $local:doc.CloseDoc() | Out-Null
        $local:doc = $null

        if (-not (Test-Path -LiteralPath $log -PathType Leaf)) { throw "Log Qlik ausente na recarga $number" }
        $lf = Get-Item -LiteralPath $log
        if ($lf.LastWriteTimeUtc -lt $started.AddSeconds(-2)) { throw "Log Qlik nao contemporaneo na recarga $number" }
        $lines = @(Get-Content -LiteralPath $log -ErrorAction Stop | Where-Object { $_ -notmatch '\bTRACE\b' })
        $profile = 'ROWS=566672 DISTINCT_SK=566672 NULL_SK=0 IDENT5=11583 IDENT1=555089 MONTHS=36 SOURCE_FILES=36'
        if (-not (@($lines | Where-Object { $_.Contains($profile) }).Count -gt 0)) { throw "Metrias Qlik divergentes na recarga $number" }
        if (-not (@($lines | Where-Object { $_.Contains('[V5-RD-SK] VERDICT=PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY') }).Count -gt 0)) { throw "Veredito Qlik nao executado na recarga $number" }
        if (-not (@($lines | Where-Object { $_.Contains('[V5-RD-STABILITY] EXPORT_COMPLETE') }).Count -gt 0)) { throw "Export nao confirmado no log $number" }
        if (@($lines | Where-Object { $_ -match '\[V5-RD-(SK|STABILITY)\] (FAIL|VERDICT=BLOCKED)' }).Count -gt 0) { throw "Qlik reportou falha na recarga $number" }
        if (-not (Test-Path -LiteralPath $export -PathType Leaf)) { throw "Export fisico de chaves ausente na recarga $number" }
        $f = Get-Item -LiteralPath $export
        if ($f.Length -lt 5000000 -or $f.LastWriteTimeUtc -lt $started.AddSeconds(-2)) { throw "Export invalido ou anterior na recarga $number" }
        Move-Item -LiteralPath $export -Destination $moveTo -ErrorAction Stop
        Write-Output "RUN_${number}_PASS_QV_PROFILE=True"
        Write-Output "RUN_${number}_EXPORTED_KEY_BYTES=$($f.Length)"
    } finally {
        if ($null -ne $local:doc) { try { $local:doc.CloseDoc() | Out-Null } catch { Write-Warning 'Feche o documento temporario se permanecer aberto.' } }
    }
}

try {
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    $originalHashBefore = (Get-FileHash -LiteralPath $originalDoc -Algorithm SHA256).Hash
    $qvdHashBefore = (Get-FileHash -LiteralPath $sourceQvd -Algorithm SHA256).Hash
    $original = $qv.OpenDoc($originalDoc, '', '')
    if ($null -eq $original) { throw 'Nao foi possivel abrir o QVW original validado.' }
    $s = [string]$original.GetProperties().Script
    if (-not $s.Contains('[V5-RD-SK] START READ_ONLY STAGING QVD PROJECTION') -or
        -not $s.Contains('PASS_QV_HASH128_STAGING_PROJECTION_UNIQUE_CANDIDATE_ONLY') -or
        -not $s.Contains('DROP TABLE V5_RD_SK_PROFILE;') -or
        -not $s.Contains('DROP TABLE V5_RD_SK_PROBE;') -or
        $s -match '(?im)^\s*STORE\s+') {
        throw 'O QVW original nao corresponde ao preflight isolado aprovado.'
    }
    $original.CloseDoc() | Out-Null
    $original = $null

    $sourceOld = '[..\EXTRACAO\QVD\SRC_SIH_RD.qvd]'
    if (-not $s.Contains($sourceOld)) { throw 'Caminho de staging esperado nao foi localizado no QVW aprovado.' }
    $s = $s.Replace($sourceOld, "[$sourceQvd]")
    $exportBlock = @"
TRACE [V5-RD-STABILITY] EXPORT_BEGIN;
STORE _V5_SK_CANDIDATE FROM V5_RD_SK_PROBE INTO [$export] (txt);
IF ScriptErrorCount > `$(vV5SkErrorBefore) THEN
    TRACE [V5-RD-STABILITY] FAIL EXPORT;
    EXIT SCRIPT;
ENDIF
TRACE [V5-RD-STABILITY] EXPORT_COMPLETE;
"@
    $s = $s.Replace('DROP TABLE V5_RD_SK_PROFILE;', ($exportBlock + "`r`nDROP TABLE V5_RD_SK_PROFILE;"))
    if (-not $s.Contains('STORE _V5_SK_CANDIDATE FROM V5_RD_SK_PROBE INTO') -or
        -not $s.Contains('IF ScriptErrorCount > $(vV5SkErrorBefore) THEN')) {
        throw 'Injecao do STORE temporario nao foi confirmada'
    }

    $doc = $qv.CreateDoc()
    if ($null -eq $doc) { throw 'QlikView CreateDoc falhou.' }
    $props = $doc.GetProperties()
    $props.Script = $s
    $props.GenerateLogfile = $true
    $null = $doc.SetProperties($props)
    if (-not [bool]$doc.GetProperties().GenerateLogfile) { throw 'Qlik nao confirmou GenerateLogfile' }
    $null = $doc.SaveAs($testDoc)
    if (-not (Test-Path -LiteralPath $testDoc -PathType Leaf)) { throw 'QVW de teste temporario nao foi gravado' }
    $doc.CloseDoc() | Out-Null
    $doc = $null

    [System.IO.File]::WriteAllText($pyFile, $py, [System.Text.UTF8Encoding]::new($false))
    Write-Output 'MODE=PHASE_V_SK_2_INDEPENDENT_QLIKVIEW_RELOADS'
    Write-Output 'SOURCE_SCRIPT=EXISTING_VALIDATED_V5_RD_SK_PREFLIGHT_QVW'
    Write-Output 'ORIGINAL_QVW_MODIFIED=False'
    Write-Output 'FACT_QVD_GENERATED=False'
    Write-Output 'ONLY_TEMPORARY_KEY_EXPORTS=True'
    Write-Output 'EXPECTED_SK_COUNT=566672'
    Write-Output "TEMP_DIAGNOSTIC_DIR=$work"

    Invoke-ReadOnlyReload -number 1 -moveTo $runA
    Invoke-ReadOnlyReload -number 2 -moveTo $runB

    & $python $pyFile $runA $runB
    $code = $LASTEXITCODE
    if ($code -ne 0) { throw "Comparacao exata de conjuntos falhou: python exit $code" }
    if ((Get-FileHash -LiteralPath $originalDoc -Algorithm SHA256).Hash -ne $originalHashBefore) { throw 'QVW original mudou: ABORT' }
    if ((Get-FileHash -LiteralPath $sourceQvd -Algorithm SHA256).Hash -ne $qvdHashBefore) { throw 'SRC_SIH_RD.qvd mudou: ABORT' }
    Write-Output 'ORIGINAL_QVW_SHA256_UNCHANGED=True'
    Write-Output 'STAGING_QVD_SHA256_UNCHANGED=True'
    Write-Output 'KEY_POLICY=APPROVED_WITH_IMMUTABLE_SOURCE_AND_EXPRESSION_RESTRICTIONS'
    Write-Output 'FACT_IMPLEMENTATION=NOT_STARTED'
    $verified = $true
}
catch {
    Write-Output ('VERDICT=FAIL_CLOSED_' + $_.Exception.Message)
    Write-Output "DIAGNOSTIC_DIR_RETAINED=$work"
    exit 1
}
finally {
    if ($null -ne $original) { try { $original.CloseDoc() | Out-Null } catch {} }
    if ($null -ne $doc) { try { $doc.CloseDoc() | Out-Null } catch {} }
    if ($verified) {
        try {
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction Stop
            Write-Output 'TEMPORARY_DIAGNOSTICS_REMOVED=True'
        } catch {
            Write-Warning "O teste passou, mas arquivos temporarios permaneceram em: $work"
        }
    }
}