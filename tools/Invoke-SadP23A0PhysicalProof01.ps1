# P2.3 A0 physical-proof candidate: prepares ONE disposable 16-table QVW for a manual pivot test.
# Does not create charts, declare visual PASS, STORE QVDs or touch canonical QVWs.
# This script is not physically tested until it is run on an authorized Windows/QlikView 12 host.
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
if([bool]$Prepare -eq [bool]$Verify){throw 'Select exactly one of -Prepare or -Verify'}
if($ExpectedCommit -notmatch '^[0-9a-fA-F]{40}$'){throw 'ExpectedCommit must be full SHA'}
if([string]::IsNullOrWhiteSpace($ExecutionAuthorizationRef)){throw 'Explicit gate authorization reference required'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw 'QlikView Desktop 12/COM requires Windows'}
$repo=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))
$evidence=[IO.Path]::GetFullPath($EvidenceRoot).TrimEnd([char[]]@('\','/'))
$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]@('\','/'))
function Inside([string]$child,[string]$parent){
  return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
    $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
if((Inside $evidence $repo) -or (Inside $evidence $temp)){throw 'EvidenceRoot cannot be inside repo or TEMP'}
if(-not(Test-Path -LiteralPath (Split-Path $evidence -Parent) -PathType Container)){throw 'EvidenceRoot parent must already exist on persistent storage'}
$selfRel='tools/Invoke-SadP23A0PhysicalProof01.ps1'
$modelRel='PAINEL/phase_vii_technical_model.qvs'
$self=Join-Path $repo $selfRel
$model=Join-Path $repo $modelRel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){throw 'Execute the versioned script from the repository'}
$head=([string](& git -C $repo rev-parse --verify HEAD 2>$null)).Trim()
$branch=([string](& git -C $repo branch --show-current 2>$null)).Trim()
if($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit.ToLowerInvariant() -or $branch -cne 'feat/sad-p23-a0-physical-proof-01'){
  throw 'Checkout/HEAD not pinned to approved P2.3 branch and commit'
}
foreach($rel in @($selfRel,$modelRel)){
  $tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
  if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1){throw "Not tracked in Git: $rel"}
  $dirty=@(& git -C $repo status --porcelain -- $rel)
  if($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0){throw "Uncommitted source change: $rel"}
}
$ext=Join-Path $repo 'EXTRACAO\QVD'
$trans=Join-Path $repo 'TRANSFORMACAO\QVD'
$eqvds=@(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)
$tqvds=@(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File)
if($eqvds.Count -ne 10 -or $tqvds.Count -ne 12){throw 'Protected QVD inventory drift: expected 10+12'}
$originals=@(
  (Join-Path $repo 'EXTRACAO\EXT.qvw'),
  (Join-Path $repo 'TRANSFORMACAO\TRANSF.qvw'),
  (Join-Path $repo 'PAINEL\PAINEL.qvw'),
  (Join-Path $ext 'REF_MUNICIPIO_PB_DERIVADA.csv')
)
$protected=@($eqvds+$tqvds | ForEach-Object {$_.FullName})+$originals
foreach($path in $protected){if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw "Protected input missing: $path"}}
$pinLink=Join-Path $trans 'LINK_ANALISE.qvd'
if((Get-FileHash -LiteralPath $pinLink -Algorithm SHA256).Hash -cne '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB'){
  throw 'HARD_STOP: frozen LINK_ANALISE.qvd SHA mismatch'
}
function Snapshot {
  return @($protected | Sort-Object | ForEach-Object {
    $f=Get-Item -LiteralPath $_
    [pscustomobject]@{path=$f.FullName;bytes=[long]$f.Length;sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash}
  })
}
function Same($a,$b){
  return ((ConvertTo-Json -InputObject @($a) -Depth 6 -Compress) -ceq
    (ConvertTo-Json -InputObject @($b) -Depth 6 -Compress))
}
if($Verify){
  if(-not(Test-Path -LiteralPath $evidence -PathType Container)){throw 'EvidenceRoot not found'}
  $beforePath=Join-Path $evidence 'protected_before.json'
  $metadataPath=Join-Path $evidence 'preparation_metadata.json'
  if(-not(Test-Path -LiteralPath $beforePath) -or -not(Test-Path -LiteralPath $metadataPath)){throw 'Missing preparation evidence'}
  $metadata=Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
  if($metadata.git_commit -cne $head -or $metadata.authorization_ref -cne $ExecutionAuthorizationRef){throw 'Metadata/authorization mismatch'}
  $before=@(Get-Content -LiteralPath $beforePath -Raw | ConvertFrom-Json)
  $after=@(Snapshot)
  $after | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'protected_after.json') -Encoding UTF8
  if(-not(Same $before $after)){throw 'HARD_STOP: protected QVD/QVW/crosswalk SHA drift'}
  Write-Output 'VERDICT=PROTECTED_ARTIFACTS_UNCHANGED_VISUAL_EVIDENCE_REVIEW_PENDING'
  Write-Output ('TEMP_QVW='+$metadata.temp_qvw)
  return
}
if(Test-Path -LiteralPath $evidence){throw 'EvidenceRoot already exists: refuse overwrite'}
$qvs=[IO.File]::ReadAllText($model,[Text.Encoding]::UTF8)
if($qvs -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DIRECT\s+QUERY|DROP\s+FILE)\b' -or
   $qvs -notmatch '\[VII\] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY'){
  throw 'Unexpected QVS operation or missing technical model marker'
}
$replace=[ordered]@{
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
}
foreach($entry in $replace.GetEnumerator()){
  if(-not(Test-Path -LiteralPath $entry.Value -PathType Leaf)){throw "Missing QVD for $($entry.Key)"}
  if($entry.Value -match '[\]\r\n]'){throw 'Unsupported QVD path characters'}
  if(-not $qvs.Contains($entry.Key)){throw "Model missing expected token $($entry.Key)"}
  $qvs=$qvs.Replace($entry.Key,$entry.Value)
}
if($qvs -match '__[A-Z_]+__'){throw 'Unresolved QVS placeholder'}
[void][IO.Directory]::CreateDirectory($evidence)
$before=@(Snapshot)
$before | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'protected_before.json') -Encoding UTF8
$runtime=Join-Path $temp ('SAD_P23_A0_'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($runtime)
$qvw=Join-Path $runtime 'SAD_P23_A0_DISPOSABLE.qvw'
$nativeLog=$qvw+'.log'
$app=$null;$doc=$null;$problem=$null;$logError=$null;$started=[DateTime]::UtcNow
try{
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$app.CreateDoc()
  if($null -eq $doc){throw 'Qlik COM CreateDoc returned null'}
  $props=$doc.GetProperties()
  $props.Script=$qvs
  $props.GenerateLogfile=$true
  $null=$doc.SetProperties($props)
  $null=$doc.SaveAs($qvw)
  if(-not(Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'Temporary QVW was not saved'}
  $started=[DateTime]::UtcNow
  $null=$doc.Reload()
  if(-not(Test-Path -LiteralPath $nativeLog -PathType Leaf)){throw 'Missing Qlik native log'}
  if((Get-Item -LiteralPath $nativeLog).LastWriteTimeUtc -lt $started.AddSeconds(-3)){throw 'Stale Qlik native log'}
  $rawLog=Get-Content -LiteralPath $nativeLog -Raw
  $events=@(Get-Content -LiteralPath $nativeLog | Where-Object {$_ -notmatch '\bTRACE\b'})
  if(@($events | Where-Object {$_.Contains('[VII] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY')}).Count -ne 1 -or
     @($events | Where-Object {$_.Contains('[VII] VERDICT=BLOCKED')}).Count -ne 0 -or
     $rawLog -match '(?i)circular reference|loosely coupled|synthetic key'){
    throw 'Model technical reload is BLOCKED or association warnings found'
  }
  $null=$doc.Save()
}catch{
  $problem=$_.Exception.Message
}finally{
  if($null -ne $doc){try{$null=$doc.CloseDoc()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}}
  if($null -ne $app){try{$app.Quit()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}}
  if(Test-Path -LiteralPath $nativeLog -PathType Leaf){
    try{Copy-Item -LiteralPath $nativeLog -Destination (Join-Path $evidence 'qlik_reload.log') -ErrorAction Stop}
    catch{$logError=$_.Exception.Message}
  }else{$logError='Native log was not created'}
  $after=@(Snapshot)
  $after | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'protected_after_preparation.json') -Encoding UTF8
  if(-not(Same $before $after)){throw 'HARD_STOP: protected QVD/QVW/crosswalk SHA drift'}
}
if($null -ne $problem){throw "PREPARATION_BLOCKED: $problem"}
if($null -ne $logError){throw "PREPARATION_BLOCKED: $logError"}
if(-not(Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'PREPARATION_BLOCKED: temporary QVW absent'}
[pscustomobject]@{
  gate='SAD-P2.3-A0-PHYSICAL-PROOF-01'
  status='TEMP_MODEL_PREPARED_VISUAL_NOT_TESTED'
  git_commit=$head
  branch=$branch
  authorization_ref=$ExecutionAuthorizationRef
  temp_qvw=$qvw
  temp_qvw_sha256=(Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
  model_script_sha256=(Get-FileHash -LiteralPath $model -Algorithm SHA256).Hash
  runner_sha256=(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash
  source_qvd_count=22
  source_qvw_count=3
  phase_ix='NOT_AUTHORIZED'
  production_approved=$false
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'preparation_metadata.json') -Encoding UTF8
Write-Output ('TEMP_QVW='+$qvw)
Write-Output ('EVIDENCE_ROOT='+$evidence)
Write-Output 'VERDICT=TEMP_MODEL_PREPARED_P23_VISUAL_NOT_TESTED'
