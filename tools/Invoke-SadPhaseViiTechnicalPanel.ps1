# SAD Phase VII — 22-QVD inventory and isolated QlikView 12 technical-model test.
# Only writes under %TEMP%; never reloads EXT/TRANSF/PAINEL original QVWs.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$branch='feat/phase-vii-technical-panel-gate-20261018'
$selfRel='tools/Invoke-SadPhaseViiTechnicalPanel.ps1'
$qvsRel='PAINEL/phase_vii_technical_model.qvs'
$self=Join-Path $repo $selfRel
$qvsFile=Join-Path $repo $qvsRel
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath($self)){
    throw 'Use the committed repository executor; copies are not gate evidence'
}
$gitBranch=@(& git -C $repo branch --show-current 2>$null)
$gitHead=@(& git -C $repo rev-parse --verify HEAD 2>$null)
if($LASTEXITCODE -ne 0 -or $gitBranch.Count -ne 1 -or $gitBranch[0] -cne $branch -or
   $gitHead.Count -ne 1 -or $gitHead[0] -notmatch '^[0-9a-f]{40}$'){
    throw 'Expected the specific phase-VII branch and a versioned Git HEAD'
}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $selfRel $qvsRel 2>$null)
if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 2){throw 'Runner and QVS must both be committed'}
$dirty=@(& git -C $repo status --porcelain -- $selfRel $qvsRel)
if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw 'Runner or QVS is dirty; commit first'}
if(-not(Test-Path -LiteralPath $qvsFile -PathType Leaf)){throw 'Missing committed QVS'}
$qvs=[IO.File]::ReadAllText($qvsFile,[Text.Encoding]::UTF8)
if($qvs -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DROP\s+FILE|RENAME\s+FILE)\b' -or
   $qvs -match '(?i)\$\(\s*Must_Include' -or
   $qvs -notmatch '\[VII\] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY'){
    throw 'Unexpected QVS operation or missing success marker'
}
$work=Join-Path ([IO.Path]::GetTempPath()) ('SAD_VII_PANEL_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work -ErrorAction Stop
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('VERSIONED_GIT_HEAD='+$gitHead[0])
Write-Output ('BRANCH='+$gitBranch[0])
Write-Output ('SCRIPT_SHA256='+$qvsRel+'|'+(Get-FileHash -LiteralPath $qvsFile -Algorithm SHA256).Hash)
Write-Output ('RUNNER_SHA256='+$selfRel+'|'+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('MODE='+$(if($RunQlik){'QLIK_DISPOSABLE_TEMP'}else{'INVENTORY_READ_ONLY'}))
Write-Output 'ORIGINAL_QVD_QVW_WRITE=False FASES_VIII_IX=False PRODUCTION_APPROVED=False'

$trans=Join-Path $repo 'TRANSFORMACAO/QVD'
$ext=Join-Path $repo 'EXTRACAO/QVD'
$expectedTrans=@(
    'DIM_TEMPO.qvd','DIM_MUNICIPIO.qvd','DIM_ESTABELECIMENTO.qvd',
    'DIM_PROCEDIMENTO.qvd','DIM_DIAGNOSTICO.qvd',
    'DIM_CARATER_ATENDIMENTO.qvd','DIM_MOTIVO_SAIDA_PERMANENCIA.qvd',
    'DIM_TIPO_LEITO.qvd','FATO_INTERNACAO.qvd',
    'FATO_CAPACIDADE_LEITO.qvd','FATO_POPULACAO.qvd','LINK_ANALISE.qvd'
)
$paths=[ordered]@{
    '__LINK__'     = Join-Path $trans 'LINK_ANALISE.qvd'
    '__FI__'       = Join-Path $trans 'FATO_INTERNACAO.qvd'
    '__LT_FACT__'  = Join-Path $trans 'FATO_CAPACIDADE_LEITO.qvd'
    '__POP__'      = Join-Path $trans 'FATO_POPULACAO.qvd'
    '__TEMPO__'    = Join-Path $trans 'DIM_TEMPO.qvd'
    '__MUN__'      = Join-Path $trans 'DIM_MUNICIPIO.qvd'
    '__EST__'      = Join-Path $trans 'DIM_ESTABELECIMENTO.qvd'
    '__PROC__'     = Join-Path $trans 'DIM_PROCEDIMENTO.qvd'
    '__DIAG__'     = Join-Path $trans 'DIM_DIAGNOSTICO.qvd'
    '__CAR__'      = Join-Path $trans 'DIM_CARATER_ATENDIMENTO.qvd'
    '__MOT__'      = Join-Path $trans 'DIM_MOTIVO_SAIDA_PERMANENCIA.qvd'
    '__BED__'      = Join-Path $trans 'DIM_TIPO_LEITO.qvd'
    '__RD_STAGE__' = Join-Path $ext 'SRC_SIH_RD.qvd'
    '__LT_STAGE__' = Join-Path $ext 'SRC_CNES_LT.qvd'
}
foreach($entry in $paths.GetEnumerator()){
    if(-not(Test-Path -LiteralPath $entry.Value -PathType Leaf)){throw ('Missing QVD: '+$entry.Value)}
    if($entry.Value.Contains(']') -or $entry.Value.Contains([char]10) -or
       $entry.Value.Contains([char]13)){throw 'Unsupported QVD path characters'}
    if(-not $qvs.Contains($entry.Key)){throw ('Missing QVS placeholder: '+$entry.Key)}
}
function Read-QvdHeader([string]$file){
    $f=[IO.File]::Open($file,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try {
        $n=[int][Math]::Min(4194304,$f.Length)
        $bytes=New-Object byte[] $n
        $got=$f.Read($bytes,0,$n)
        $raw=[Text.Encoding]::UTF8.GetString($bytes,0,$got)
        $end='</QvdTableHeader>'
        $i=$raw.IndexOf($end,[StringComparison]::Ordinal)
        if($i -lt 0){throw ('QVD header missing: '+$file)}
        [xml]$xml=$raw.Substring(0,$i+$end.Length)
        $node=$xml.DocumentElement
        if($null -eq $node -or $node.LocalName -ne 'QvdTableHeader'){throw 'Invalid QVD header root'}
        $num=$node.SelectSingleNode('./NoOfRecords')
        $fields=@($node.SelectNodes('./Fields/QvdFieldHeader/FieldName') | ForEach-Object {$_.InnerText})
        if($null -eq $num -or $fields.Count -eq 0){throw 'QVD row/field metadata missing'}
        return [pscustomobject]@{Rows=[long]$num.InnerText;Fields=$fields}
    } finally {$f.Dispose()}
}
function Snapshot-Qvds {
    foreach($folder in @($ext,$trans)){
        if(-not(Test-Path -LiteralPath $folder -PathType Container)){throw ('Missing directory: '+$folder)}
    }
    $e=@(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)
    $t=@(Get-ChildItem -LiteralPath $trans -Filter '*.qvd' -File)
    if($e.Count -ne 10 -or $t.Count -ne 12){throw ('Expected 10+12 QVDs; found '+$e.Count+'+'+$t.Count)}
    foreach($name in $expectedTrans){
        if(@($t | Where-Object {$_.Name -ceq $name}).Count -ne 1){throw ('Missing/nonunique transformed QVD: '+$name)}
    }
    $rows=@()
    foreach($file in @($e)+@($t)){
        if($file.Length -le 0){throw ('Empty QVD: '+$file.FullName)}
        $header=Read-QvdHeader $file.FullName
        $rows += [pscustomobject]@{
            Path=$file.FullName
            Rows=$header.Rows
            Fields=($header.Fields -join '|')
            Bytes=[long]$file.Length
            SHA256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    return @($rows | Sort-Object Path)
}
function Snapshot-OriginalQvws {
    $rows=@()
    foreach($rel in @('EXTRACAO/EXT.qvw','TRANSFORMACAO/TRANSF.qvw','PAINEL/PAINEL.qvw')){
        $p=Join-Path $repo $rel
        if(Test-Path -LiteralPath $p -PathType Leaf){
            $f=Get-Item -LiteralPath $p
            $rows += [pscustomobject]@{
                Path=$f.FullName; Bytes=[long]$f.Length
                SHA256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
            }
        }
    }
    return @($rows | Sort-Object Path)
}
function Same-Snapshot($a,$b){
    return ((ConvertTo-Json -InputObject @($a) -Depth 5 -Compress) -ceq
            (ConvertTo-Json -InputObject @($b) -Depth 5 -Compress))
}
$before=$null
$qvwBefore=$null
try{
    $before=@(Snapshot-Qvds)
    $qvwBefore=@(Snapshot-OriginalQvws)
    $before | Export-Csv -LiteralPath (Join-Path $work 'qvd_22_before.csv') -NoTypeInformation -Encoding UTF8
    $qvwBefore | Export-Csv -LiteralPath (Join-Path $work 'original_qvw_before.csv') -NoTypeInformation -Encoding UTF8
    $link=@($before | Where-Object {$_.Path -ieq $paths['__LINK__']})
    if($link.Count -ne 1 -or $link[0].Rows -ne 85705 -or
       $link[0].Fields -cne '%LINK_KEY|%SK_TEMPO_COMPETENCIA|%SK_TEMPO_ANO|%SK_MUNICIPIO_RESIDENCIA|%SK_MUNICIPIO_SERVICO|%SK_ESTABELECIMENTO' -or
       $link[0].SHA256 -cne '78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB'){
        throw 'LINK_ANALISE header or frozen R2 SHA-256 mismatch'
    }
    $rules=@{
        'FATO_INTERNACAO.qvd'=@{Rows=566672;N=17;Fields=@('SK_REGISTRO_INTERNACAO','%LINK_KEY','%SK_PROCEDIMENTO','QTD_INTERNACAO')}
        'FATO_CAPACIDADE_LEITO.qvd'=@{Rows=35518;N=11;Fields=@('SK_REGISTRO_CAPACIDADE_LEITO','%LINK_KEY','%SK_TIPO_LEITO','QTD_LEITOS_SUS')}
        'FATO_POPULACAO.qvd'=@{Rows=669;N=7;Fields=@('%SK_MUNICIPIO','%SK_TEMPO_ANO','POPULACAO_ESTIMADA')}
    }
    foreach($entry in $rules.GetEnumerator()){
        $p=Join-Path $trans $entry.Key
        $v=@($before | Where-Object {$_.Path -ieq $p})
        if($v.Count -ne 1 -or $v[0].Rows -ne $entry.Value.Rows){throw ('Fact row drift: '+$entry.Key)}
        $fieldNames=@($v[0].Fields.Split('|'))
        if($fieldNames.Count -ne $entry.Value.N){throw ('Fact field-count drift: '+$entry.Key)}
        foreach($field in $entry.Value.Fields){
            if($fieldNames -cnotcontains $field){throw ('Fact missing field '+$field+' in '+$entry.Key)}
        }
    }
    Write-Output 'INVENTORY_22_QVD=PASS_READ_ONLY'
    Write-Output 'QVD_SOURCE_SHA256_BEFORE_CAPTURED=True'
    if(-not $RunQlik){
        Write-Output 'VERDICT=PASS_INVENTORY_ONLY_NOT_PHYSICAL_MODEL'
    }else{
        if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){
            throw 'Native QlikView Desktop 12 requires Windows'
        }
        foreach($entry in $paths.GetEnumerator()){$qvs=$qvs.Replace($entry.Key,$entry.Value)}
        if($qvs -match '__[A-Z_]+__'){throw 'Unresolved QVD placeholder in QVS'}
        $testQvw=Join-Path $work 'SAD_VII_TECHNICAL_PANEL_TEST.qvw'
        $testLog=$testQvw+'.log'
        if(Test-Path -LiteralPath $testQvw){throw 'Temporary QVW name unexpectedly occupied'}
        $app=$null
        $doc=$null
        try{
            $app=New-Object -ComObject 'QlikTech.QlikView'
            $doc=$app.CreateDoc()
            if($null -eq $doc){throw 'QlikView COM CreateDoc failed'}
            $properties=$doc.GetProperties()
            $properties.Script=$qvs
            $properties.GenerateLogfile=$true
            $null=$doc.SetProperties($properties)
            if(-not [bool]$doc.GetProperties().GenerateLogfile){throw 'Native log disabled'}
            $null=$doc.SaveAs($testQvw)
            if(-not(Test-Path -LiteralPath $testQvw -PathType Leaf)){throw 'Temporary QVW missing'}
            $start=[DateTime]::UtcNow
            $null=$doc.Reload()
            if(-not(Test-Path -LiteralPath $testLog -PathType Leaf)){throw 'Native log missing'}
            if((Get-Item -LiteralPath $testLog).LastWriteTimeUtc -lt $start.AddSeconds(-3)){
                throw 'Stale QlikView native log'
            }
            $events=@(Get-Content -LiteralPath $testLog | Where-Object {$_ -notmatch '\bTRACE\b'})
            $pass=@($events | Where-Object {$_.Contains('[VII] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY')})
            $blocked=@($events | Where-Object {$_.Contains('[VII] VERDICT=BLOCKED')})
            if($pass.Count -ne 1 -or $blocked.Count -gt 0){throw 'Missing unique VII PASS or BLOCKED detected'}
            $rawLog=Get-Content -LiteralPath $testLog -Raw
            if($rawLog -match '(?i)circular reference|loosely coupled|synthetic key'){
                throw 'Possible loop/synthetic association in native QlikView log; inspect before proceeding'
            }
            $null=$doc.Save()
            Write-Output ('TEMP_QVW='+$testQvw)
            Write-Output ('NATIVE_LOG='+$testLog)
            Write-Output 'T17_T18_T19_T20_T22_T23=SCRIPT_CHECKED T21=NO_LOG_WARNING_TABLE_VIEWER_PENDING'
            Write-Output 'TABLE_VIEWER_REVIEW=PENDING'
            Write-Output 'VERDICT=PASS_LOCAL_ASSOCIATIVE_CANDIDATE_PENDING_TABLE_VIEWER'
        }finally{
            if($null -ne $doc){try{$null=$doc.CloseDoc()}catch{}}
        }
    }
}catch{
    Write-Output ('VERDICT=BLOCKED_OR_INCONCLUSIVE '+$_.Exception.Message)
    throw
}finally{
    if($null -ne $before){
        $after=@(Snapshot-Qvds)
        $after | Export-Csv -LiteralPath (Join-Path $work 'qvd_22_after.csv') -NoTypeInformation -Encoding UTF8
        if(-not(Same-Snapshot $before $after)){
            throw 'CRITICAL: protected QVD hash/header drift; preserve evidence and stop'
        }
        Write-Output 'ORIGINAL_22_QVD_SHA256_AND_HEADERS_UNCHANGED=True'
    }
    if($null -ne $qvwBefore){
        $qvwAfter=@(Snapshot-OriginalQvws)
        $qvwAfter | Export-Csv -LiteralPath (Join-Path $work 'original_qvw_after.csv') -NoTypeInformation -Encoding UTF8
        if(-not(Same-Snapshot $qvwBefore $qvwAfter)){
            throw 'CRITICAL: original QVW hash drift; preserve evidence and stop'
        }
        Write-Output 'ORIGINAL_CANONICAL_QVWS_UNCHANGED=True'
    }
}
