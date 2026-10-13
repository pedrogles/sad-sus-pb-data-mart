# SAD P6: temporary QlikView 12 associative projection, strictly no STORE/QVD writes.
[CmdletBinding()]
param(
 [string]$Root = (Get-Location).Path,
 [switch]$RetainForVisualReview
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$baseQvs=Join-Path $Root 'TRANSFORMACAO\phase_vi_link_key_cross_fact_preflight.qvs'
$assocQvs=Join-Path $Root 'TRANSFORMACAO\phase_vi_link_associative_projection_preflight.qvs'
$originalQvw=Join-Path $Root 'TRANSFORMACAO\P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw'
$inputs=[ordered]@{
 '[..\EXTRACAO\QVD\SRC_SIH_RD.qvd]'=(Join-Path $Root 'EXTRACAO\QVD\SRC_SIH_RD.qvd')
 '[..\EXTRACAO\QVD\SRC_CNES_LT.qvd]'=(Join-Path $Root 'EXTRACAO\QVD\SRC_CNES_LT.qvd')
 '[..\EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd]'=(Join-Path $Root 'EXTRACAO\QVD\SRC_IBGE_POPULACAO.qvd')
 '[QVD\DIM_TEMPO.qvd]'=(Join-Path $Root 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd')
 '[QVD\DIM_MUNICIPIO.qvd]'=(Join-Path $Root 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd')
 '[QVD\DIM_ESTABELECIMENTO.qvd]'=(Join-Path $Root 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd')
}
if ($inputs.Count -ne 6) { throw 'Required exactly six source QVDs' }
$required=@(
 (Join-Path $Root 'AGENTS.md'),
 (Join-Path $Root 'docs\project\current-state.md'),
 (Join-Path $Root 'docs\academic\requirements.md'),
 $baseQvs,$assocQvs,$originalQvw
)+@($inputs.Values)
foreach($path in $required) {
 if(-not (Test-Path -LiteralPath $path -PathType Leaf)) {throw "Missing immutable input: $path"}
}
function SameScript([string]$a,[string]$b) {
 return ($a.Replace([string][char]13,'').TrimEnd() -ceq $b.Replace([string][char]13,'').TrimEnd())
}
$base=[IO.File]::ReadAllText($baseQvs,[Text.Encoding]::UTF8)
$assoc=[IO.File]::ReadAllText($assocQvs,[Text.Encoding]::UTF8)
$anchor='DROP TABLE P6_LINK_PROC;'
$marker='// P6_ASSOC_FINAL_GATE_BEGIN'
if(-not $base.Contains('VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED') -or
 $base.IndexOf($anchor) -lt 0 -or $base.IndexOf($anchor) -ne $base.LastIndexOf($anchor) -or
 $assoc.IndexOf($marker) -lt 0 -or $assoc.IndexOf($marker) -ne $assoc.LastIndexOf($marker) -or
 -not $assoc.Contains('P6_LINK_SIMULADA:') -or
 -not $assoc.Contains('PASS_IN_MEMORY_85705_LINK_AND_3_FACT_COVERAGE_NOT_FINAL') -or
 $base -match '(?im)^\s*(STORE|JOIN|BINARY|EXECUTE)\b' -or
 $assoc -match '(?im)^\s*(STORE|JOIN|BINARY|EXECUTE)\b') {
 throw 'Unrecognized or non-read-only base/injection QVS'
}
$begin=$assoc.Substring(0,$assoc.IndexOf($marker))
$end=$assoc.Substring($assoc.IndexOf($marker)+$marker.Length)
$sha=@{}
foreach($path in (@($baseQvs,$assocQvs,$originalQvw)+@($inputs.Values))) {
 $sha[$path]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$temp=Join-Path ([IO.Path]::GetTempPath()) ('SAD_P6_ASSOC_PREFLIGHT_'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp -ErrorAction Stop | Out-Null
$qvw=Join-Path $temp 'P6_ASSOC_LINK_IN_MEMORY.qvw'
$log="$qvw.log"
$qv=$null
$doc=$null
$pass=$false
try {
 $qv=New-Object -ComObject 'QlikTech.QlikView'
 $doc=$qv.OpenDoc($originalQvw,'','')
 if($null -eq $doc -or -not (SameScript ([string]$doc.GetProperties().Script) $base) -or
  -not [bool]$doc.GetProperties().GenerateLogfile) {
  throw 'Original R2 QVW does not match approved source script/logging'
 }
 $null=$doc.CloseDoc()
 $doc=$null
 $script=$base.Replace($anchor,($begin+[Environment]::NewLine+$anchor))+[Environment]::NewLine+$end
 foreach($ref in $inputs.Keys) {
  if(-not $script.Contains($ref)) {throw ("Expected relative QVD reference absent: "+$ref)}
  $script=$script.Replace($ref,('['+$inputs[$ref]+']'))
 }
 foreach($ref in $inputs.Keys) {
  if($script.Contains($ref)) {throw ("QVD reference was not replaced: "+$ref)}
 }
 if($script -match '(?im)^\s*(STORE|JOIN|BINARY|EXECUTE)\b') {
  throw 'Injected script unexpectedly writes or joins'
 }
 $doc=$qv.CreateDoc()
 if($null -eq $doc) {throw 'Could not create temporary QVW'}
 $props=$doc.GetProperties()
 $props.Script=$script
 $props.GenerateLogfile=$true
 $null=$doc.SetProperties($props)
 if(-not (SameScript ([string]$doc.GetProperties().Script) $script) -or
  -not [bool]$doc.GetProperties().GenerateLogfile) {
  throw 'Temporary QVW did not retain script/log flags'
 }
 $null=$doc.SaveAs($qvw)
 if(-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {throw 'Temporary QVW not saved'}
 $null=$doc.CloseDoc()
 $doc=$null
 Write-Output 'MODE=PHASE_VI_ASSOCIATIVE_LINK_TABLE_PREFLIGHT_READ_ONLY'
 Write-Output 'FACT_QVD_GENERATED=False'
 Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
 Write-Output 'OUTPUT_DATA_FILES_WRITTEN=0'
 Write-Output "TEMP_DIAGNOSTIC_DIR=$temp"
 $doc=$qv.OpenDoc($qvw,'','')
 if($null -eq $doc -or -not (SameScript ([string]$doc.GetProperties().Script) $script)) {
  throw 'Temporary QVW contents differ from expected script'
 }
 $start=[DateTime]::UtcNow
 Write-Output 'RELOAD_STARTED=True'
 $null=$doc.Reload()
 Write-Output 'RELOAD_RETURNED=True'
 if ($RetainForVisualReview) {
  # Save loaded model ONLY in a GUID-named QVW under %TEMP%, never in the repository.
  $null=$doc.Save()
  Write-Output 'TEMPORARY_ASSOC_QVW_SAVED_WITH_LOADED_DATA=True'
 }
 $null=$doc.CloseDoc()
 $doc=$null
 if($RetainForVisualReview) {
  if(-not (Test-Path -LiteralPath $qvw -PathType Leaf) -or
    (Get-Item -LiteralPath $qvw).LastWriteTimeUtc -lt $start.AddSeconds(-2)) {
    throw 'Visual-review QVW not saved with contemporary loaded data'
  }
 }
 if(-not (Test-Path -LiteralPath $log -PathType Leaf) -or
  (Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $start.AddSeconds(-2)) {
  throw 'Qlik native log absent or stale'
 }
 $lines=@(Get-Content -LiteralPath $log | Where-Object {$_ -notmatch '\bTRACE\b'})
 foreach($expected in @(
  '[P6-LINK] VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED',
  '[P6-ASSOC] LINK_ROWS=85705 LINK_DISTINCT=85705 LINK_ORPHAN_BASE=0 REQUIRED_NULL=0',
  '[P6-ASSOC] FACT_ROWS RD=566672 LT=35518 POP=669',
  '[P6-ASSOC] FACT_ORPHANS RD=0 LT=0 POP=0',
  '[P6-ASSOC] FACT_NULL RD=0 LT=0 POP=0',
  '[P6-ASSOC] PROJECTION_READY=TRUE',
  '[P6-ASSOC] FINAL_MODEL TABLES=9 SYNTHETIC=0',
  '[P6-ASSOC] VERDICT=PASS_IN_MEMORY_85705_LINK_AND_3_FACT_COVERAGE_NOT_FINAL',
  '[P6-ASSOC] TABLE_VIEWER_ROLE_SELECTION=NOT_TESTED CIRCULAR_LINKS_VISUAL_REVIEW=REQUIRED'
 )) {
  if(@($lines | Where-Object {$_.Contains($expected)}).Count -ne 1) {
   throw ("Qlik PASS/profile marker missing/duplicated: "+$expected)
  }
 }
 if(@($lines | Where-Object {
  $_ -match '\[(P6-LINK|P6-ASSOC)\] VERDICT=(BLOCKED|FAIL)' -or
  $_ -match '(?i)circular reference|loosely coupled|refer[eê]ncia[s]? circular(es)?'
 }).Count -gt 0) {throw 'Native log contains blocked or circular model warning'}
 $lines | Where-Object {
  $_ -match '\[P6-ASSOC\] (LINK_ROWS|FACT_ROWS|FACT_ORPHANS|FACT_NULL|FINAL_MODEL|VERDICT=PASS|TABLE_VIEWER)'
 } | ForEach-Object { Write-Output $_ }
 foreach($path in $sha.Keys) {
  if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sha[$path]) {
   throw ("Immutable input SHA-256 changed: "+$path)
  }
 }
 Write-Output 'ALL_6_INPUT_QVD_SHA256_UNCHANGED=True'
 Write-Output 'SOURCE_R2_QVW_SHA256_UNCHANGED=True'
 Write-Output 'BASE_AND_PROJECTION_QVS_SHA256_UNCHANGED=True'
 Write-Output 'VERDICT=PASS_IN_MEMORY_LINK_COVERAGE_9_TABLE_PROJECTION_NOT_FINAL'
 if($RetainForVisualReview) {
  Write-Output ('VISUAL_REVIEW_QVW='+$qvw)
  Write-Output ('VISUAL_REVIEW_OPEN_IN_QLIKVIEW_DESKTOP=True')
  Write-Output ('VISUAL_REVIEW_TABLE_VIEWER=NOT_TESTED')
  Write-Output ('VISUAL_REVIEW_FILTER_SEMANTICS=NOT_TESTED')
 }
 Write-Output 'TABLE_VIEWER_ROLE_SELECTION=NOT_TESTED'
 Write-Output 'PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY'
 Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
 $pass=$true
} catch {
 Write-Output ('VERDICT=FAIL_CLOSED_'+$_.Exception.Message)
 Write-Output ("TEMP_DIAGNOSTIC_DIR_RETAINED="+$temp)
 exit 1
} finally {
 if($null -ne $doc) {try {$null=$doc.CloseDoc()} catch {}}
 if($pass -and $RetainForVisualReview) {
  Write-Output ('TEMPORARY_ASSOC_QVW_RETAINED_FOR_VISUAL_REVIEW='+$qvw)
  Write-Output 'TEMPORARY_ASSOC_QVW_REMOVED=False'
 } elseif($pass) {
  try {
   Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction Stop
   Write-Output 'TEMPORARY_ASSOC_QVW_REMOVED=True'
  } catch {
   Write-Warning ("Temporary QVW retained after PASS: "+$temp)
  }
 }
}
