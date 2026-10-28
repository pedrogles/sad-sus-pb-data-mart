# SAD-P2.3-A1-PHYSICAL-GATE-01
# One disposable QVW; QlikView Desktop 12/Windows only; no original QVW/QVD writes.
# Physical UI acceptance remains manual and separate from this model-preparation runner.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$ExpectedCommit,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [Parameter(Mandatory=$true)][string]$ExecutionAuthorizationRef,
  [switch]$Prepare,
  [switch]$Verify
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if([bool]$Prepare -eq [bool]$Verify){throw 'Choose exactly one of -Prepare or -Verify'}
if($ExpectedCommit -notmatch '^[0-9a-fA-F]{40}$'){throw 'ExpectedCommit requires a full 40-character SHA'}
if([string]::IsNullOrWhiteSpace($ExecutionAuthorizationRef)){throw 'Explicit physical execution reference required'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'Windows QlikView 12/COM required'}
$repo=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))
$evidence=[IO.Path]::GetFullPath($EvidenceRoot).TrimEnd([char[]]@('\','/'))
$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]@('\','/'))
function Inside([string]$child,[string]$parent){
  $child=$child.TrimEnd([char[]]@('\','/'))
  $parent=$parent.TrimEnd([char[]]@('\','/'))
  return ($child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
    $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase))
}
if((Inside $evidence $repo) -or (Inside $evidence $temp)){throw 'EvidenceRoot must be outside repo and TEMP'}
if(-not(Test-Path -LiteralPath (Split-Path $evidence -Parent) -PathType Container)){
  throw 'EvidenceRoot parent must already exist on persistent storage'
}
$selfRel='tools/Invoke-SadP23A1PhysicalGate01.ps1'
$baseRel='PAINEL/phase_vii_technical_model.qvs'
$islandRel='PAINEL/sad_p23_a1_island_physical_gate.qvs'
$contractRel='docs/discovery/sad-p23-a1-logical-design-2026-10-28.md'
$self=Join-Path $repo $selfRel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){
  throw 'Execute committed script in canonical repository checkout'
}
$head=([string](& git -C $repo rev-parse --verify HEAD 2>$null)).Trim()
$branch=([string](& git -C $repo branch --show-current 2>$null)).Trim()
if($LASTEXITCODE -ne 0 -or $branch -cne 'feat/sad-p23-a1-physical-gate-01' -or
   $head -cne $ExpectedCommit.ToLowerInvariant()){
  throw 'Expected approved branch and pinned HEAD; no execution from main'
}
$hashes=[ordered]@{}
foreach($rel in @($selfRel,$baseRel,$islandRel,$contractRel)){
  $p=Join-Path $repo $rel
  if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing source: $rel"}
  $tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
  if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1){throw "Untracked source: $rel"}
  $dirty=@(& git -C $repo status --porcelain -- $rel)
  if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw "Uncommitted modification: $rel"}
  $hashes[$rel]=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
}
$ext=Join-Path $repo 'EXTRACAO\QVD'
$trans=Join-Path $repo 'TRANSFORMACAO\QVD'
$e=@(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)
$t=@(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File)
if($e.Count -ne 10 -or $t.Count -ne 12){throw 'Expected exactly 10+12 protected QVDs'}
$orig=@(
  (Join-Path $repo 'EXTRACAO\EXT.qvw'),
  (Join-Path $repo 'TRANSFORMACAO\TRANSF.qvw'),
  (Join-Path $repo 'PAINEL\PAINEL.qvw'),
  (Join-Path $ext 'REF_MUNICIPIO_PB_DERIVADA.csv')
)
$protected=@($e+$t | ForEach-Object {$_.FullName})+$orig
if($protected.Count -ne 26){throw 'Protected artifact inventory must have 26 paths'}
foreach($p in $protected){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Protected input missing: $p"}}
$pinLink=Join-Path $trans 'LINK_ANALISE.qvd'
if((Get-FileHash -LiteralPath $pinLink -Algorithm SHA256).Hash -cne
   '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB'){
  throw 'HARD_STOP: frozen LINK_ANALISE.qvd hash mismatch'
}
function Snapshot {
  return @($protected | Sort-Object | ForEach-Object {
    $f=Get-Item -LiteralPath $_
    [pscustomobject]@{
      path=$f.FullName;bytes=[long]$f.Length
      sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    }
  })
}
function Same($a,$b){
  $left=@($a | ForEach-Object { $_ })
  $right=@($b | ForEach-Object { $_ })
  if($left.Count -ne 26 -or $right.Count -ne 26){
    throw "HARD_STOP: expected 26 manifest rows, got $($left.Count) and $($right.Count)"
  }
  foreach($side in @('left','right')){
    if($side -ceq 'left'){$set=@($left)}else{$set=@($right)}
    $paths=@($set | ForEach-Object { [string]$_.path })
    if(@($paths | Sort-Object -Unique).Count -ne 26){throw 'HARD_STOP: duplicate protected paths'}
    foreach($v in $set){
      if([string]::IsNullOrWhiteSpace([string]$v.path) -or [long]$v.bytes -lt 0 -or
         [string]$v.sha256 -notmatch '^[0-9A-Fa-f]{64}$'){
        throw 'HARD_STOP: invalid manifest row'
      }
    }
  }
  return (@(Compare-Object -ReferenceObject $left -DifferenceObject $right -Property path,bytes,sha256).Count -eq 0)
}
if($Verify){
  if(-not(Test-Path -LiteralPath $evidence -PathType Container)){throw 'EvidenceRoot missing'}
  $beforePath=Join-Path $evidence 'protected_before.json'
  $metaPath=Join-Path $evidence 'preparation_metadata.json'
  $afterPath=Join-Path $evidence 'protected_after.json'
  if(-not(Test-Path -LiteralPath $beforePath -PathType Leaf) -or
     -not(Test-Path -LiteralPath $metaPath -PathType Leaf)){
    throw 'Preparation manifests missing'
  }
  if(Test-Path -LiteralPath $afterPath){throw 'Already verified; evidence is immutable'}
  $meta=Get-Content -LiteralPath $metaPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if($meta.git_commit -cne $head -or $meta.git_branch -cne $branch -or
     $meta.authorization_ref -cne $ExecutionAuthorizationRef -or
     $meta.status -cne 'A1_TEMP_MODEL_PREPARED_VISUAL_NOT_TESTED'){
    throw 'Evidence not bound to this branch/commit/authorization'
  }
  $qvw=[IO.Path]::GetFullPath([string]$meta.temp_qvw)
  if(-not(Inside $qvw $temp) -or [IO.Path]::GetFileName($qvw) -cne 'SAD_P23_A1_DISPOSABLE.qvw' -or
     -not(Test-Path -LiteralPath $qvw -PathType Leaf)){
    throw 'Temporary QVW missing or not in TEMP'
  }
  $beforeRaw=ConvertFrom-Json -InputObject (Get-Content -LiteralPath $beforePath -Raw -Encoding UTF8)
  $before=@($beforeRaw | ForEach-Object { $_ })
  $after=@(Snapshot)
  $after | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $afterPath -Encoding UTF8
  if(-not(Same $before $after)){throw 'HARD_STOP: protected source SHA drift'}
  [pscustomobject]@{
    git_commit=$head;temp_qvw=$qvw
    temp_qvw_sha256=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
    proof='SHA-only; no evidence of accepted visualization or selection behavior'
  } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidence 'temp_qvw_after.json') -Encoding UTF8
  Write-Output 'PROTECTED_SOURCES_SHA256_UNCHANGED=True'
  Write-Output 'VERDICT=SOURCE_INTEGRITY_CONFIRMED_VISUAL_ACCEPTANCE_PENDING'
  return
}
if(Test-Path -LiteralPath $evidence){throw 'EvidenceRoot already exists; refuse overwrite'}

$model=[IO.File]::ReadAllText((Join-Path $repo $baseRel),[Text.Encoding]::UTF8)
$island=[IO.File]::ReadAllText((Join-Path $repo $islandRel),[Text.Encoding]::UTF8)
foreach($s in @($model,$island)){
  if($s -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DIRECT\s+QUERY|DROP\s+FILE|RENAME\s+FILE)\b'){
    throw 'Unsafe QVS statement in a source script'
  }
}
if($model -notmatch '\[VII\] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY' -or
   $island -notmatch '\[P23A1\] VERDICT=PASS_SCRIPT_CANDIDATE_ONLY'){
  throw 'Missing script-level success markers'
}
$repl=[ordered]@{
  '__LINK__'=(Join-Path $trans 'LINK_ANALISE.qvd')
  '__FI__'=(Join-Path $trans 'FATO_INTERNACAO.qvd')
  '__LT_FACT__'=(Join-Path $trans 'FATO_CAPACIDADE_LEITO.qvd')
  '__POP__'=(Join-Path $trans 'FATO_POPULACAO.qvd')
  '__TEMPO__'=(Join-Path $trans 'DIM_TEMPO.qvd')
  '__MUN__'=(Join-Path $trans 'DIM_MUNICIPIO.qvd')
  '__EST__'=(Join-Path $trans 'DIM_ESTABELECIMENTO.qvd')
  '__PROC__'=(Join-Path $trans 'DIM_PROCEDIMENTO.qvd')
  '__DIAG__'=(Join-Path $trans 'DIM_DIAGNOSTICO.qvd')
  '__CAR__'=(Join-Path $trans 'DIM_CARATER_ATENDIMENTO.qvd')
  '__MOT__'=(Join-Path $trans 'DIM_MOTIVO_SAIDA_PERMANENCIA.qvd')
  '__BED__'=(Join-Path $trans 'DIM_TIPO_LEITO.qvd')
  '__RD_STAGE__'=(Join-Path $ext 'SRC_SIH_RD.qvd')
  '__LT_STAGE__'=(Join-Path $ext 'SRC_CNES_LT.qvd')
  '__P23_FACT__'=(Join-Path $trans 'FATO_CAPACIDADE_LEITO.qvd')
  '__P23_POP__'=(Join-Path $trans 'FATO_POPULACAO.qvd')
  '__P23_LT__'=(Join-Path $ext 'SRC_CNES_LT.qvd')
}
foreach($kv in $repl.GetEnumerator()){
  if(-not(Test-Path -LiteralPath $kv.Value -PathType Leaf)){throw "Missing QVD: $($kv.Key)"}
  if($kv.Value.Contains(']') -or $kv.Value.Contains([char]10) -or
     $kv.Value.Contains([char]13)){throw "Unsupported path: $($kv.Key)"}
  if($model.Contains($kv.Key)){$model=$model.Replace($kv.Key,$kv.Value)}
  elseif($island.Contains($kv.Key)){$island=$island.Replace($kv.Key,$kv.Value)}
  else{throw "Missing QVS token: $($kv.Key)"}
}
if(($model+"\n"+$island) -match '__[A-Z0-9_]+__'){throw 'Unresolved QVD placeholder'}
$script=$model+"\r\n"+$island
$before=@(Snapshot)
[void][IO.Directory]::CreateDirectory($evidence)
$before | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'protected_before.json') -Encoding UTF8
$runtime=Join-Path $temp ('SAD_P23_A1_'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($runtime)
$qvw=Join-Path $runtime 'SAD_P23_A1_DISPOSABLE.qvw'
$nativeLog=$qvw+'.log'
$app=$null;$doc=$null;$problem=$null;$logProblem=$null
try{
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$app.CreateDoc()
  if($null -eq $doc){throw 'Qlik COM CreateDoc returned null'}
  $props=$doc.GetProperties()
  $props.Script=$script
  $props.GenerateLogfile=$true
  $null=$doc.SetProperties($props)
  $null=$doc.SaveAs($qvw)
  if(-not(Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'Temporary QVW missing after SaveAs'}
  $started=[DateTime]::UtcNow
  $null=$doc.Reload()
  if(-not(Test-Path -LiteralPath $nativeLog -PathType Leaf)){throw 'Qlik native log missing'}
  if((Get-Item -LiteralPath $nativeLog).LastWriteTimeUtc -lt $started.AddSeconds(-3)){
    throw 'Stale Qlik native log'
  }
  $log=Get-Content -LiteralPath $nativeLog -Raw
  $events=@(Get-Content -LiteralPath $nativeLog | Where-Object {$_ -notmatch '\bTRACE\b'})
  $viiPass=@($events | Where-Object {$_.Contains('[VII] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY')})
  $a1Pass=@($events | Where-Object {$_.Contains('[P23A1] VERDICT=PASS_SCRIPT_CANDIDATE_ONLY')})
  $bad=@($events | Where-Object {$_.Contains('[P23A1] VERDICT=BLOCKED') -or $_.Contains('[VII] VERDICT=BLOCKED')})
  if($viiPass.Count -ne 1 -or $a1Pass.Count -ne 1 -or $bad.Count -ne 0 -or
     $log -match '(?i)circular reference|loosely coupled|synthetic key'){
    throw 'Qlik log lacks unique PASS markers or reports associativity warning'
  }
  function Evaluate-Exact([string]$expr,[string]$expected,[string]$label){
    $got=[string]$doc.Evaluate($expr)
    if($got -cne $expected){throw "Qlik check '$label': expected '$expected', got '$got'"}
  }
  # Checks on the six-field island, not global facts or snapshots as yearly capacity.
  Evaluate-Exact "Num(Count(P23_ESTADO_OBSERVADO),'0','.',',')" '8028' 'pair count'
  Evaluate-Exact "Num(Count(DISTINCT P23_MUNICIPIO_6),'0','.',',')" '223' 'municipal count'
  Evaluate-Exact "Num(Count(DISTINCT P23_COMPETENCIA),'0','.',',')" '36' 'month count'
  Evaluate-Exact "Num(Count(P23_QT_SUS_OBSERVADO),'0','.',',')" '3561' 'observed value count'
  Evaluate-Exact "Only({<P23_MUNICIPIO_6={'251740'},P23_COMPETENCIA={'201701'}>} P23_ESTADO_OBSERVADO)" 'ABSENT_NOT_ZERO_PROVEN' 'absent case'
  Evaluate-Exact "Num(Count({<P23_MUNICIPIO_6={'251740'},P23_COMPETENCIA={'201701'}>} P23_QT_SUS_OBSERVADO),'0','.',',')" '0' 'absent NULL case'
  Evaluate-Exact "Only({<P23_MUNICIPIO_6={'250460'},P23_COMPETENCIA={'201701'}>} P23_ESTADO_OBSERVADO)" 'OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED' 'observed zero case'
  Evaluate-Exact "Num(Sum({<P23_MUNICIPIO_6={'250460'},P23_COMPETENCIA={'201701'}>} P23_QT_EXIST_OBSERVADO),'0','.',',')" '40' 'existing bed case'
  Evaluate-Exact "Only({<P23_MUNICIPIO_6={'250010'},P23_COMPETENCIA={'201701'}>} P23_ESTADO_OBSERVADO)" 'OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED' 'positive case'
  Evaluate-Exact "Num(Sum({<P23_MUNICIPIO_6={'250010'},P23_COMPETENCIA={'201701'}>} P23_QT_SUS_OBSERVADO),'0','.',',')" '20' 'positive bed case'
  $null=$doc.Save()
}catch{
  $problem=$_.Exception.Message
}finally{
  if($null -ne $doc){try{$null=$doc.CloseDoc()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}}
  if($null -ne $app){try{$app.Quit()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}}
  if(Test-Path -LiteralPath $nativeLog -PathType Leaf){
    try{Copy-Item -LiteralPath $nativeLog -Destination (Join-Path $evidence 'qlik_reload.log') -ErrorAction Stop}
    catch{$logProblem=$_.Exception.Message}
  }else{$logProblem='Qlik native log missing'}
  $after=@(Snapshot)
  $after | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'protected_after_preparation.json') -Encoding UTF8
  if(-not(Same $before $after)){throw 'HARD_STOP: protected QVD/QVW/crosswalk SHA drift'}
}
if($null -ne $problem){throw ('A1_MODEL_PREPARATION_BLOCKED: '+$problem)}
if($null -ne $logProblem){throw ('A1_MODEL_PREPARATION_BLOCKED: '+$logProblem)}
if(-not(Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'Missing temporary QVW'}
[pscustomobject]@{
  gate='SAD-P2.3-A1-PHYSICAL-GATE-01'
  status='A1_TEMP_MODEL_PREPARED_VISUAL_NOT_TESTED'
  git_branch=$branch
  git_commit=$head
  authorization_ref=$ExecutionAuthorizationRef
  temp_qvw=$qvw
  temp_qvw_sha256=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
  source_hashes=$hashes
  model_tables_expected=17
  island_rows_expected=8028
  visual_accepted=$false
  phase_ix='NOT_AUTHORIZED'
  production_approved=$false
} | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $evidence 'preparation_metadata.json') -Encoding UTF8
Write-Output ('TEMP_QVW='+$qvw)
Write-Output ('EVIDENCE_ROOT='+$evidence)
Write-Output 'VERDICT=A1_TEMP_MODEL_PREPARED_VISUAL_NOT_TESTED'
