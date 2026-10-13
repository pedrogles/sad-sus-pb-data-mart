# SAD / Phase VI: isolate Hash128 vs Text(Hash128) vs STORE txt in QlikView 12.
# Reads six immutable QVDs, uses a temporary QVW and a <=5000-row temporary CSV only.
# Does not modify the approved R2 QVW, canonical QVS, source QVDs, or any fact.
[CmdletBinding()]
param([string]$Root = (Get-Location).Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$qvs = Join-Path $Root 'TRANSFORMACAO\phase_vi_link_key_cross_fact_preflight.qvs'
$original = Join-Path $Root 'TRANSFORMACAO\P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw'
$python = Join-Path $Root '.venv\Scripts\python.exe'
$map = [ordered]@{
 '[..\EXTRACAO\QVD\SRC_SIH_RD.qvd]' = (Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd')
 '[..\EXTRACAO\QVD\SRC_CNES_LT.qvd]' = (Join-Path $Root 'EXTRACAO\QVD\SRC_CNES_LT.qvd')
 '[..\EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd]' = (Join-Path $Root 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd')
 '[QVD\DIM_TEMPO.qvd]' = (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd')
 '[QVD\DIM_MUNICIPIO.qvd]' = (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd')
 '[QVD\DIM_ESTABELECIMENTO.qvd]' = (Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd')
}
if ($map.Count -ne 6) { throw 'Expected exactly six input QVDs' }
foreach ($path in (@((Join-Path $Root 'AGENTS.md'),$qvs,$original,$python) + @($map.Values))) {
 if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Entrada ausente: $path" }
}
function SameScript([string]$a,[string]$b) {
 return ($a.Replace([string][char]13,'').TrimEnd() -ceq $b.Replace([string][char]13,'').TrimEnd())
}
$script = [IO.File]::ReadAllText($qvs,[Text.Encoding]::UTF8)
if (-not $script.Contains('[P6-LINK] START READ_ONLY_CROSS_FACT_SERIALIZATION') -or
 -not $script.Contains('VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED') -or
 -not $script.Contains('DROP TABLE P6_LINK_PROC;') -or
 -not $script.Contains('P6_LINK_TEST:') -or
 $script -match '(?im)^\s*(STORE|JOIN|BINARY|EXECUTE)\b') {
 throw 'Script canonico nao corresponde ao preflight read-only'
}
$before = @{}
foreach ($path in (@($qvs,$original) + @($map.Values))) {
 $before[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$work=Join-Path ([IO.Path]::GetTempPath()) ('SAD_P6_LINK_TXT_PROBE_' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -ErrorAction Stop | Out-Null
$qvw=Join-Path $work 'P6_LINK_TXT_PROBE.qvw'
$log="$qvw.log"
$export=Join-Path $work 'sample_5000.txt'
$qv=$null
$doc=$null
$success=$false

$py=@'
import csv
import hashlib
import sys
from collections import Counter
from pathlib import Path

path=Path(sys.argv[1])
with path.open('r', encoding='utf-8-sig', newline='') as stream:
    header=stream.readline()
    delimiter=next((s for s in (',',';','\t') if header.count(s)==2), None)
    if delimiter is None:
        raise ValueError("Three-column header delimiter not found: " + repr(header[:180]))
    stream.seek(0)
    records=list(csv.reader(stream, delimiter=delimiter))
print("TXT_SAMPLE_SHA256="+hashlib.sha256(path.read_bytes()).hexdigest())
print("TXT_HEADER="+repr(records[0]))
print("TXT_ROWS="+str(len(records)-1))
if len(records)!=5001 or len(records[0])!=3 or any(len(x)!=3 for x in records[1:]):
    raise ValueError("Expected exactly 5000 CSV rows of three fields")
for col,name in enumerate(("DIRECT_HASH","TEXT_CAST","SERIAL")):
    values=[record[col] for record in records[1:]]
    freq=Counter(values)
    lengths=Counter(map(len,values))
    print("TXT_"+name+"_UNIQUE="+str(len(freq)))
    print("TXT_"+name+"_LENGTHS="+repr(lengths.most_common(4)))
    if name!="SERIAL":
        print("TXT_"+name+"_FIRST_3="+repr(values[:3]))
'@

try {
 $qv=New-Object -ComObject 'QlikTech.QlikView'
 $doc=$qv.OpenDoc($original,'','')
 if ($null -eq $doc -or -not (SameScript ([string]$doc.GetProperties().Script) $script) -or
  -not [bool]$doc.GetProperties().GenerateLogfile) {
  throw 'Original R2 QVW nao corresponde ao QVS versionado'
 }
 $null=$doc.CloseDoc()
 $doc=$null

 $isolated=$script
 foreach ($token in $map.Keys) {
  if (-not $isolated.Contains($token)) { throw ("Source path missing: " + $token) }
  $isolated=$isolated.Replace($token,('['+$map[$token]+']'))
 }
 $anchor='DROP TABLE P6_LINK_PROC;'
 if ($isolated.IndexOf($anchor) -lt 0 -or $isolated.IndexOf($anchor) -ne $isolated.LastIndexOf($anchor)) {
  throw 'Injection anchor non-unique'
 }
 $block=@'
TRACE [P6-TXT] START_ONE_RELOAD_DIAGNOSTIC;
P6_TXT_FULL_PROFILE:
NOCONCATENATE LOAD
 Count(*) AS _P6_TXT_ALL_ROWS,
 Count(DISTINCT _P6_HASH) AS _P6_TXT_DIRECT_UNIQUE,
 Count(DISTINCT Text(_P6_HASH)) AS _P6_TXT_CAST_UNIQUE,
 Count(DISTINCT _P6_SERIAL) AS _P6_TXT_SERIAL_UNIQUE
RESIDENT P6_LINK_TEST;
LET vTxtAll=Peek('_P6_TXT_ALL_ROWS',0,'P6_TXT_FULL_PROFILE');
LET vTxtDirect=Peek('_P6_TXT_DIRECT_UNIQUE',0,'P6_TXT_FULL_PROFILE');
LET vTxtCast=Peek('_P6_TXT_CAST_UNIQUE',0,'P6_TXT_FULL_PROFILE');
LET vTxtSerial=Peek('_P6_TXT_SERIAL_UNIQUE',0,'P6_TXT_FULL_PROFILE');
TRACE [P6-TXT] IN_MEMORY ROWS=$(vTxtAll) DISTINCT_HASH=$(vTxtDirect) DISTINCT_TEXT_CAST=$(vTxtCast) DISTINCT_SERIAL=$(vTxtSerial);
IF $(vTxtAll)<>602859 OR $(vTxtDirect)<>85705 OR $(vTxtSerial)<>85705 THEN
 TRACE [P6-TXT] VERDICT=BLOCKED_IN_MEMORY_BASELINE;
 EXIT SCRIPT;
ENDIF
P6_TXT_SAMPLE:
FIRST 5000 LOAD
 _P6_HASH AS _P6_TXT_DIRECT,
 Text(_P6_HASH) AS _P6_TXT_CAST,
 _P6_SERIAL AS _P6_TXT_SERIAL
RESIDENT P6_LINK_TEST;
IF ScriptErrorCount>$(vP6StartErr) OR NoOfRows('P6_TXT_SAMPLE')<>5000 THEN
 TRACE [P6-TXT] VERDICT=BLOCKED_SAMPLE_ROWS;
 EXIT SCRIPT;
ENDIF
P6_TXT_SAMPLE_PROFILE:
NOCONCATENATE LOAD
 Count(DISTINCT _P6_TXT_DIRECT) AS _P6_SAMPLE_DIRECT_UNIQUE,
 Count(DISTINCT _P6_TXT_CAST) AS _P6_SAMPLE_TEXT_UNIQUE,
 Count(DISTINCT _P6_TXT_SERIAL) AS _P6_SAMPLE_SERIAL_UNIQUE
RESIDENT P6_TXT_SAMPLE;
LET vSampleDirect=Peek('_P6_SAMPLE_DIRECT_UNIQUE',0,'P6_TXT_SAMPLE_PROFILE');
LET vSampleText=Peek('_P6_SAMPLE_TEXT_UNIQUE',0,'P6_TXT_SAMPLE_PROFILE');
LET vSampleSerial=Peek('_P6_SAMPLE_SERIAL_UNIQUE',0,'P6_TXT_SAMPLE_PROFILE');
TRACE [P6-TXT] SAMPLE ROWS=5000 DISTINCT_HASH=$(vSampleDirect) DISTINCT_TEXT_CAST=$(vSampleText) DISTINCT_SERIAL=$(vSampleSerial);
STORE _P6_TXT_DIRECT, _P6_TXT_CAST, _P6_TXT_SERIAL FROM P6_TXT_SAMPLE INTO [__EXPORT__] (txt);
IF ScriptErrorCount>$(vP6StartErr) THEN
 TRACE [P6-TXT] VERDICT=BLOCKED_TXT_EXPORT;
 EXIT SCRIPT;
ENDIF
TRACE [P6-TXT] TXT_SAMPLE_EXPORT_COMPLETE;
DROP TABLE P6_TXT_SAMPLE_PROFILE;
DROP TABLE P6_TXT_SAMPLE;
DROP TABLE P6_TXT_FULL_PROFILE;
'@
 $block=$block.Replace('__EXPORT__',$export)
 $isolated=$isolated.Replace($anchor,($block+[Environment]::NewLine+$anchor))
 $doc=$qv.CreateDoc()
 if ($null -eq $doc) { throw 'Could not create isolated QVW' }
 $p=$doc.GetProperties()
 $p.Script=$isolated
 $p.GenerateLogfile=$true
 $null=$doc.SetProperties($p)
 if (-not (SameScript ([string]$doc.GetProperties().Script) $isolated) -or
  -not [bool]$doc.GetProperties().GenerateLogfile) {
  throw 'QVW failed to retain script or log enabled flag'
 }
 $null=$doc.SaveAs($qvw)
 $null=$doc.CloseDoc()
 $doc=$null
 Write-Output 'MODE=PHASE_VI_HASH128_TXT_STORE_DIAGNOSTIC_READ_ONLY'
 Write-Output 'SOURCE_QVS_MODIFIED=False'
 Write-Output 'SOURCE_R2_QVW_MODIFIED=False'
 Write-Output 'FACT_QVD_GENERATED=False'
 Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
 Write-Output 'ONLY_TEMPORARY_5000_ROW_CSV=True'
 Write-Output "TEMP_DIAGNOSTIC_DIR=$work"

 $doc=$qv.OpenDoc($qvw,'','')
 if ($null -eq $doc -or -not (SameScript ([string]$doc.GetProperties().Script) $isolated)) {
  throw 'Temporary QVW did not preserve diagnostic script'
 }
 $start=[DateTime]::UtcNow
 Write-Output 'RELOAD_STARTED=True'
 $null=$doc.Reload()
 Write-Output 'RELOAD_RETURNED=True'
 $null=$doc.CloseDoc()
 $doc=$null

 if (-not (Test-Path -LiteralPath $log -PathType Leaf) -or
  (Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $start.AddSeconds(-2)) {
  throw 'Qlik log not current'
 }
 $lines=@(Get-Content -LiteralPath $log | Where-Object { $_ -notmatch '\bTRACE\b' })
 foreach ($prefix in @(
  '[P6-TXT] IN_MEMORY ROWS=602859 DISTINCT_HASH=85705',
  '[P6-TXT] SAMPLE ROWS=5000',
  '[P6-TXT] TXT_SAMPLE_EXPORT_COMPLETE',
  '[P6-LINK] VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED'
 )) {
  $selected=@($lines | Where-Object { $_.Contains($prefix) })
  if ($selected.Count -ne 1) { throw ("Missing/duplicate Qlik marker: "+$prefix) }
 }
 $lines | Where-Object { $_ -match '\[P6-TXT\] (IN_MEMORY|SAMPLE|TXT_SAMPLE_EXPORT_COMPLETE)' } | ForEach-Object { Write-Output $_ }
 if (-not (Test-Path -LiteralPath $export -PathType Leaf) -or
  (Get-Item -LiteralPath $export).LastWriteTimeUtc -lt $start.AddSeconds(-2)) {
  throw 'Temporary CSV sample missing or stale'
 }
 $py | & $python - $export
 if ($LASTEXITCODE -ne 0) { throw 'Python CSV sample inspection failed' }

 foreach ($path in $before.Keys) {
  if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $before[$path]) {
   throw ("Input SHA-256 changed: "+$path)
  }
 }
 Write-Output 'ALL_6_INPUT_QVD_SHA256_UNCHANGED=True'
 Write-Output 'SOURCE_R2_QVW_SHA256_UNCHANGED=True'
 Write-Output 'SOURCE_QVS_SHA256_UNCHANGED=True'
 Write-Output 'VERDICT=DIAGNOSTIC_CAPTURED_EXPORT_HASH_BEHAVIOR_NOT_LINK_APPROVED'
 Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
 $success=$true
} catch {
 Write-Output ('VERDICT=BLOCKED_DIAGNOSTIC_'+$_.Exception.Message)
 Write-Output ("TEMP_DIAGNOSTIC_DIR_RETAINED="+$work)
 exit 1
} finally {
 if ($null -ne $doc) { try { $null=$doc.CloseDoc() } catch {} }
 if ($success) {
  try {
   Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction Stop
   Write-Output 'TEMPORARY_SAMPLE_REMOVED=True'
  } catch {
   Write-Warning ("Unable to remove temporary diagnostic: "+$work)
  }
 }
}
