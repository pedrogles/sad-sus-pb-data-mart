# Phase VI — exact Link Hash128 sets; two independent QlikView 12 reloads.
# Builds only temporary QVW/log/txt files under %TEMP%, removed after verified PASS.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$qvs = Join-Path $Root 'TRANSFORMACAO\phase_vi_link_key_cross_fact_preflight.qvs'
$original = Join-Path $Root 'TRANSFORMACAO\P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw'
$comparator = Join-Path $Root 'tools\comparar_conjuntos_link_key_qlik.py'
$python = Join-Path $Root '.venv\Scripts\python.exe'
$map = [ordered]@{
 '[..\EXTRACAO\QVD\SRC_SIH_RD.qvd]' = (Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd')
 '[..\EXTRACAO\QVD\SRC_CNES_LT.qvd]' = (Join-Path $Root 'EXTRACAO\QVD\SRC_CNES_LT.qvd')
 '[..\EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd]' = (Join-Path $Root 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd')
 '[QVD\DIM_TEMPO.qvd]' = (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd')
 '[QVD\DIM_MUNICIPIO.qvd]' = (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd')
 '[QVD\DIM_ESTABELECIMENTO.qvd]' = (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd')
}
if ($map.Count -ne 6) { throw 'Exatamente 6 QVDs de entrada sao requeridos' }
foreach ($path in (@((Join-Path $Root 'AGENTS.md'),(Join-Path $Root 'docs\project\current-state.md'),$qvs,$original,$comparator,$python) + @($map.Values))) {
 if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Entrada ausente: $path" }
}
function SameScript([string]$a,[string]$b) {
 return ($a.Replace([string][char]13,'').TrimEnd() -ceq $b.Replace([string][char]13,'').TrimEnd())
}
$source = [IO.File]::ReadAllText($qvs,[Text.Encoding]::UTF8)
if (-not $source.Contains('[P6-LINK] START READ_ONLY_CROSS_FACT_SERIALIZATION') -or
 -not $source.Contains('VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED') -or
 -not $source.Contains('DROP TABLE P6_LINK_PROC;') -or
 $source -match '(?im)^\s*(STORE|JOIN|BINARY|EXECUTE)\b') {
 throw 'Preflight original nao corresponde ao contrato'
}
$before = @{}
foreach ($path in (@($qvs,$original,$comparator) + @($map.Values))) {
 $before[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$work = Join-Path ([IO.Path]::GetTempPath()) ('SAD_P6_LINK_EXACT_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -ErrorAction Stop | Out-Null
$testQvw = Join-Path $work 'P6_LINK_KEY_EXACT_RELOADS.qvw'
$log = "$testQvw.log"
$export = Join-Path $work 'keys.txt'
$a = Join-Path $work 'run_a.txt'
$b = Join-Path $work 'run_b.txt'
$qv=$null
$doc=$null
$passed=$false

function Invoke-ExactReload([int]$run,[string]$destination) {
 if (Test-Path -LiteralPath $export) { throw 'Export antigo presente' }
 if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force }
 $script:doc=$null
 try {
  $script:doc = $qv.OpenDoc($testQvw,'','')
  if ($null -eq $script:doc -or -not (SameScript ([string]$script:doc.GetProperties().Script) $isolated)) {
   throw 'QVW temporario nao corresponde ao QVS derivado'
  }
  $started=[DateTime]::UtcNow
  Write-Output ("RUN_{0}_RELOAD_STARTED=True" -f $run)
  $null=$script:doc.Reload()
  Write-Output ("RUN_{0}_RELOAD_RETURNED=True" -f $run)
  $null=$script:doc.CloseDoc()
  $script:doc=$null
  if (-not (Test-Path -LiteralPath $log -PathType Leaf) -or
   (Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $started.AddSeconds(-2)) {
   throw 'Log Qlik nao contemporaneo'
  }
  $lines=@(Get-Content -LiteralPath $log | Where-Object { $_ -notmatch '\bTRACE\b' })
  foreach ($expected in @(
   'TOTAL ROWS=602859 RD=566672 LT=35518 POP=669 BAD_COORD=0 NULL_KEY=0 DISTINCT_SERIAL=85705 DISTINCT_HASH=85705',
   '[P6-LINK] SYNTHETIC_TABLES=0',
   '[P6-LINK] VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED',
   '[P6-EXACT] EXPORT_COMPLETE')) {
   if (@($lines | Where-Object { $_.Contains($expected) }).Count -ne 1) {
    throw ("Gate Qlik ausente/duplicado run {0}: {1}" -f $run,$expected)
   }
  }
  if (@($lines | Where-Object { $_ -match '\[(P6-LINK|P6-EXACT)\] (VERDICT=BLOCKED|FAIL)' }).Count -gt 0) {
   throw 'Qlik reportou bloqueio'
  }
  if (-not (Test-Path -LiteralPath $export -PathType Leaf)) { throw 'Export nao existe' }
  $f=Get-Item -LiteralPath $export
  if ($f.Length -lt 10000000 -or $f.LastWriteTimeUtc -lt $started.AddSeconds(-2)) {
   throw 'Export incompleto ou desatualizado'
  }
  Move-Item -LiteralPath $export -Destination $destination -ErrorAction Stop
  Write-Output ("RUN_{0}_PROFILE_PASS=True" -f $run)
  Write-Output ("RUN_{0}_EXPORTED_HASH_BYTES={1}" -f $run,$f.Length)
 } finally {
  if ($null -ne $script:doc) { try { $null=$script:doc.CloseDoc() } catch {} }
  $script:doc=$null
 }
}

try {
 $qv=New-Object -ComObject 'QlikTech.QlikView'
 $doc=$qv.OpenDoc($original,'','')
 if ($null -eq $doc -or -not (SameScript ([string]$doc.GetProperties().Script) $source) -or
  -not [bool]$doc.GetProperties().GenerateLogfile) {
  throw 'Original R2 QVW nao corresponde ao QVS versionado'
 }
 $null=$doc.CloseDoc()
 $doc=$null
 $isolated=$source
 foreach ($token in $map.Keys) {
  if (-not $isolated.Contains($token)) { throw ("Caminho QVD ausente: " + $token) }
  $isolated=$isolated.Replace($token,('[' + $map[$token] + ']'))
 }
 $anchor='DROP TABLE P6_LINK_PROC;'
 if ($isolated.IndexOf($anchor) -lt 0 -or $isolated.IndexOf($anchor) -ne $isolated.LastIndexOf($anchor)) {
  throw 'Anchor nao unico'
 }
 $block=@'
TRACE [P6-EXACT] EXPORT_BEGIN;
STORE _P6_HASH FROM P6_LINK_TEST INTO [__EXPORT__] (txt);
IF ScriptErrorCount > $(vP6StartErr) THEN
 TRACE [P6-EXACT] VERDICT=BLOCKED_EXPORT;
 EXIT SCRIPT;
ENDIF
TRACE [P6-EXACT] EXPORT_COMPLETE;
'@
 $block=$block.Replace('__EXPORT__',$export)
 $isolated=$isolated.Replace($anchor,($block + [Environment]::NewLine + $anchor))
 $doc=$qv.CreateDoc()
 if ($null -eq $doc) { throw 'CreateDoc Qlik falhou' }
 $p=$doc.GetProperties()
 $p.Script=$isolated
 $p.GenerateLogfile=$true
 $null=$doc.SetProperties($p)
 if (-not (SameScript ([string]$doc.GetProperties().Script) $isolated)) {
  throw 'Script nao persistiu no QVW temporario'
 }
 $null=$doc.SaveAs($testQvw)
 if (-not (Test-Path -LiteralPath $testQvw -PathType Leaf)) { throw 'QVW temporario nao foi criado' }
 $null=$doc.CloseDoc()
 $doc=$null
 Write-Output 'MODE=PHASE_VI_LINK_KEY_EXACT_SET_TWO_INDEPENDENT_RELOADS'
 Write-Output 'ORIGINAL_QVW_MODIFIED=False'
 Write-Output 'ONLY_TEMPORARY_HASH_EXPORTS=True'
 Write-Output 'FACT_QVD_GENERATED=False'
 Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
 Write-Output "TEMP_DIAGNOSTIC_DIR=$work"
 Invoke-ExactReload -run 1 -destination $a
 Invoke-ExactReload -run 2 -destination $b
 & $python $comparator $a $b
 if ($LASTEXITCODE -ne 0) { throw 'Comparacao exata Python bloqueou' }
 foreach ($path in $before.Keys) {
  if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $before[$path]) {
   throw ("Arquivo de entrada alterado: " + $path)
  }
 }
 Write-Output 'SOURCE_R2_QVW_SHA256_UNCHANGED=True'
 Write-Output 'VERSIONED_QVS_SHA256_UNCHANGED=True'
 Write-Output 'ALL_6_INPUT_QVD_SHA256_UNCHANGED=True'
 Write-Output 'VERDICT=PASS_2_RELOADS_EXACT_85705_LINK_KEY_SET_MATCH_NOT_APPROVED'
 Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
 Write-Output 'PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED'
 $passed=$true
} catch {
 Write-Output ('VERDICT=FAIL_CLOSED_' + $_.Exception.Message)
 Write-Output "TEMP_DIAGNOSTIC_DIR_RETAINED=$work"
 exit 1
} finally {
 if ($null -ne $doc) { try { $null=$doc.CloseDoc() } catch {} }
 if ($passed) {
  try { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction Stop
   Write-Output 'TEMPORARY_HASH_EXPORTS_REMOVED=True'
  } catch { Write-Warning ("Artefatos temporarios restantes: " + $work) }
 }
}
