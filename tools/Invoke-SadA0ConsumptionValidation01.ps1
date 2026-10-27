# SAD-A0-CONSUMPTION-VALIDATION-01 -- DEVELOPMENT ONLY / PHYSICAL NOT AUTHORIZED.
# Builds on the previously versioned phase_vii_technical_model.qvs (unchanged).
# The future execution needs separately documented approval and a pinned commit.
# No QVD STORE, no original QVW save, no phase-IX objects or cross-fact KPI.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$ExpectedCommit,
    [Parameter(Mandatory=$true)][string]$AE01Dir,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [Parameter(Mandatory=$true)][string]$ExecutionAuthorizationRef,
    [switch]$RunQlik,
    [string]$PythonExe='py'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not $RunQlik){throw 'EXECUTION_NOT_AUTHORIZED: -RunQlik missing. Development approval is not physical approval.'}
if([string]::IsNullOrWhiteSpace($ExecutionAuthorizationRef)){
    throw 'EXECUTION_NOT_AUTHORIZED: explicit future authorization reference required'
}
if($ExpectedCommit -notmatch '^[0-9a-fA-F]{40}$'){throw 'ExpectedCommit must be full SHA-1'}
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){
    throw 'QlikView COM future execution requires Windows'
}
$repo=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))
$ae=[IO.Path]::GetFullPath($AE01Dir).TrimEnd([char[]]@('\','/'))
$evidence=[IO.Path]::GetFullPath($EvidenceRoot).TrimEnd([char[]]@('\','/'))
$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]@('\','/'))
function Inside([string]$child,[string]$parent){
    return $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase) -or
        $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)
}
if((Inside $evidence $repo) -or (Inside $evidence $temp) -or (Inside $evidence $ae)){
    throw 'EvidenceRoot must be outside repo, AE01, and TEMP'
}
if(Test-Path -LiteralPath $evidence){throw 'EvidenceRoot already exists: refuse overwrite'}
if(-not(Test-Path -LiteralPath (Split-Path $evidence -Parent) -PathType Container)){
    throw 'EvidenceRoot parent must preexist on persistent storage'
}
if(-not(Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)){
    throw 'Not a canonical SAD checkout'
}
$selfRel='tools/Invoke-SadA0ConsumptionValidation01.ps1'
$oracleRel='tools/prepare_sad_a0_consumption_oracle01.py'
$modelRel='PAINEL/phase_vii_technical_model.qvs'
$self=Join-Path $repo $selfRel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){
    throw 'Run the committed runner in the canonical repository'
}
$head=(& git -C $repo rev-parse --verify HEAD 2>$null).Trim()
$branch=(& git -C $repo branch --show-current 2>$null).Trim()
if($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit.ToLowerInvariant() -or
   [string]::IsNullOrWhiteSpace($branch) -or $branch -eq 'main'){
    throw 'Branch/HEAD mismatch; non-main pinned commit required'
}
$scriptHashes=[ordered]@{}
foreach($rel in @($selfRel,$oracleRel,$modelRel)){
    $p=Join-Path $repo $rel
    if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing versioned source: $rel"}
    $tracked=@(& git -C $repo ls-files --error-unmatch -- $rel 2>$null)
    if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1){throw "Source must be committed: $rel"}
    $dirty=@(& git -C $repo status --porcelain -- $rel)
    if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw "Source dirty: $rel"}
    $scriptHashes[$rel]=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
}
$expectedCSV=@(
    (Join-Path $ae 'sih_fluxo_competencia.csv'),
    (Join-Path $ae 'lt_cnes_leito_competencia.csv')
)
$expectedHash=@(
    'F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615',
    'BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88'
)
for($i=0;$i -lt 2;$i++){
    if(-not(Test-Path -LiteralPath $expectedCSV[$i] -PathType Leaf)){
        throw "AE01 oracle CSV missing: $($expectedCSV[$i])"
    }
    if((Get-FileHash -LiteralPath $expectedCSV[$i] -Algorithm SHA256).Hash -cne $expectedHash[$i]){
        throw "AE01 CSV SHA mismatch: $($expectedCSV[$i])"
    }
}
$ext=Join-Path $repo 'EXTRACAO\QVD'
$trans=Join-Path $repo 'TRANSFORMACAO\QVD'
$qvds=@(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)+
      @(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File)
if(@(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File).Count -ne 10 -or
   @(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File).Count -ne 12){
    throw 'Expected exactly 10+12 protected QVD files'
}
$crosswalk=Join-Path $ext 'REF_MUNICIPIO_PB_DERIVADA.csv'
$originals=@(
    (Join-Path $repo 'EXTRACAO\EXT.qvw'),
    (Join-Path $repo 'TRANSFORMACAO\TRANSF.qvw'),
    (Join-Path $repo 'PAINEL\PAINEL.qvw')
)
$protected=@($qvds | ForEach-Object {$_.FullName})+$originals+@($crosswalk)+$expectedCSV
foreach($p in $protected){
    if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing protected artifact: $p"}
}
$pinLink=Join-Path $trans 'LINK_ANALISE.qvd'
if((Get-FileHash -LiteralPath $pinLink -Algorithm SHA256).Hash -cne
   '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB'){
    throw 'Frozen Link QVD mismatch; HARD_STOP'
}
function Snapshot{
    return @($protected | Sort-Object | ForEach-Object {
        $f=Get-Item -LiteralPath $_
        [pscustomobject]@{
            path=$f.FullName
            bytes=[long]$f.Length
            sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        }
    })
}
function Same($a,$b){
    return ((ConvertTo-Json -InputObject @($a) -Depth 5 -Compress) -ceq
            (ConvertTo-Json -InputObject @($b) -Depth 5 -Compress))
}
$replacements=[ordered]@{
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
$qvs=[IO.File]::ReadAllText((Join-Path $repo $modelRel),[Text.Encoding]::UTF8)
if($qvs -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DIRECT\s+QUERY|DROP\s+FILE)\b' -or
   $qvs -notmatch '\[VII\] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY'){
    throw 'Reused VII model script violates no-STORE or pass-marker rule'
}
foreach($item in $replacements.GetEnumerator()){
    if(-not(Test-Path -LiteralPath $item.Value -PathType Leaf)){throw "QVD not found: $($item.Key)"}
    if($item.Value -match '[\]\r\n]'){throw "Unsupported path character: $($item.Key)"}
    if(-not $qvs.Contains($item.Key)){throw "Missing placeholder: $($item.Key)"}
    $qvs=$qvs.Replace($item.Key,$item.Value)
}
if($qvs -match '__[A-Z_]+__'){throw 'Unresolved model placeholder'}
# Scope restriction: only a future separate authorization may reach here.
$before=@(Snapshot)
[void][IO.Directory]::CreateDirectory($evidence)
$before | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath
    (Join-Path $evidence 'protected_before.json') -Encoding UTF8
$runtime=Join-Path $temp ('SAD_A0_01_'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($runtime)
$app=$null;$doc=$null;$problem=$null
try{
    $oraclePath=Join-Path $evidence 'a0_oracle.json'
    & $PythonExe (Join-Path $repo $oracleRel) --ae01-dir $ae --output $oraclePath
    if($LASTEXITCODE -ne 0 -or -not(Test-Path -LiteralPath $oraclePath)){
        throw 'Independent E1/E4 oracle failed; no Qlik launch'
    }
    $oracle=Get-Content -LiteralPath $oraclePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if($oracle.status -cne 'ORACLE_READY_NOT_QLIK_PASS'){throw 'Oracle status invalid'}
    $qvw=Join-Path $runtime 'A0_CONSUMPTION_DISPOSABLE.qvw'
    $app=New-Object -ComObject 'QlikTech.QlikView'
    $doc=$app.CreateDoc()
    if($null -eq $doc){throw 'Qlik COM CreateDoc returned null'}
    $props=$doc.GetProperties()
    $props.Script=$qvs
    $props.GenerateLogfile=$true
    $null=$doc.SetProperties($props)
    $null=$doc.SaveAs($qvw)
    if(-not(Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'Disposable QVW not created'}
    $started=[DateTime]::UtcNow
    $null=$doc.Reload()
    $nativeLog=$qvw+'.log'
    if(-not(Test-Path -LiteralPath $nativeLog -PathType Leaf)){throw 'Qlik native log absent'}
    Copy-Item -LiteralPath $nativeLog -Destination (Join-Path $evidence 'qlik_reload.log')
    if((Get-Item -LiteralPath $nativeLog).LastWriteTimeUtc -lt $started.AddSeconds(-3)){
        throw 'Qlik native log stale'
    }
    $log=Get-Content -LiteralPath $nativeLog -Raw
    if($log -notmatch '\[VII\] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY' -or
       $log -match '\[VII\] VERDICT=BLOCKED' -or
       $log -match '(?i)circular reference|loosely coupled|synthetic key'){
        throw 'Fase VII model reload did not prove restricted candidate'
    }
    function ReadUInt([string]$expression,[string]$label){
        $raw=[string]$doc.Evaluate($expression)
        if($raw -notmatch '^(0|[1-9][0-9]*)$'){
            throw "Qlik Evaluate unexpected numeric result for $label : $raw"
        }
        return [long]::Parse($raw,[Globalization.CultureInfo]::InvariantCulture)
    }
    $results=New-Object System.Collections.Generic.List[object]
    foreach($m in @($oracle.p1_2.PSObject.Properties.Name | Sort-Object)){
        $exp="Num(Sum({<PERIODO_COMPETENCIA={'$m'}>} QTD_INTERNACAO),'0','.',',')"
        $got=ReadUInt $exp "P1.2 $m"
        $want=[long]$oracle.p1_2.$m
        $results.Add([pscustomobject]@{case='P1.2';key=$m;measure='internacoes';expected=$want;actual=$got;pass=($got -eq $want)})
    }
    foreach($m in @($oracle.p2_2.PSObject.Properties.Name | Sort-Object)){
        $fields=@{exist='QTD_LEITOS_EXISTENTES';sus='QTD_LEITOS_SUS';nsus='QTD_LEITOS_NAO_SUS'}
        foreach($kind in @('exist','sus','nsus')){
            $expr="Num(Sum({<PERIODO_COMPETENCIA={'$m'}>} $($fields[$kind])),'0','.',',')"
            $got=ReadUInt $expr "P2.2 $m $kind"
            $want=[long]$oracle.p2_2.$m.$kind
            $results.Add([pscustomobject]@{case='P2.2';key=$m;measure=$kind;expected=$want;actual=$got;pass=($got -eq $want)})
        }
    }
    foreach($pair in @($oracle.p3_1)){
        $res=[string]$pair.res;$serv=[string]$pair.serv;$year=[string]$pair.ano
        if($year -cne '2018' -or $res -notmatch '^25[0-9]{4}$' -or $serv -notmatch '^25[0-9]{4}$'){
            throw 'Unapproved P3.1 sample parameter'
        }
        $expr="Num(Sum({<PERIODO_ANO={$year},RES_COD_DATASUS_6={'$res'},SERV_COD_DATASUS_6={'$serv'}>} QTD_INTERNACAO),'0','.',',')"
        $got=ReadUInt $expr "P3.1 $year $res $serv"
        $want=[long]$pair.qtd_internacao
        $results.Add([pscustomobject]@{case='P3.1';key="$year/$res/$serv";measure='internacoes';expected=$want;actual=$got;pass=($got -eq $want)})
    }
    $results | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath
        (Join-Path $evidence 'qlik_evaluations.json') -Encoding UTF8
    if($results.Count -ne 146 -or @($results | Where-Object {-not $_.pass}).Count -ne 0){
        throw 'Restricted A0 result mismatch (36 SIH + 108 LT + 2 pairs)'
    }
    [pscustomobject]@{
        gate='SAD-A0-CONSUMPTION-VALIDATION-01'
        status='PASS_LOCAL_CANDIDATE_ONLY'
        p1_2_months=36;p2_2_month_measure_checks=108;p3_1_sample_pairs=2
        p3_1_full_matrix='NOT_TESTED'
        link_key_contract='NOT_APPROVED'
        phase_ix='NOT_AUTHORIZED'
        authorization_ref=$ExecutionAuthorizationRef
        git_commit=$head
        git_branch=$branch
        scripts_sha256=$scriptHashes
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath
        (Join-Path $evidence 'execution_metadata.json') -Encoding UTF8
    Write-Output 'VERDICT=PASS_LOCAL_CANDIDATE_ONLY_NOT_FINAL_VISUAL'
}catch{
    $problem=$_.Exception.Message
    Write-Output ('VERDICT=BLOCKED_OR_INCONCLUSIVE '+$problem)
}finally{
    if($null -ne $doc){try{$null=$doc.CloseDoc()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}}
    if($null -ne $app){try{$app.Quit()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}}
    $after=@(Snapshot)
    $after | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath
        (Join-Path $evidence 'protected_after.json') -Encoding UTF8
    if(-not(Same $before $after)){throw 'HARD_STOP: protected QVD/QVW/AE01/crosswalk hash drift'}
    Write-Output 'PROTECTED_SOURCES_SHA256_UNCHANGED=True'
}
if($null -ne $problem){throw $problem}
