# Phase VIII-B T24 annual residence pilot: disposable QVW and independent F3 oracle.
# Only writes under %TEMP%; never reloads EXT/TRANSF/PAINEL original QVWs.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$F3Dir,
    [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$branch='feat/phase-viii-b-t24-annual-pilot-20261018'
$selfRel='tools/Invoke-SadPhaseViiiT24AnnualPilot.ps1'
$qvsRel='PAINEL/phase_viii_t24_annual_pilot.qvs'
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
$null=& git -C $repo merge-base --is-ancestor 337943d5c5b77067f842902fc679dbb68db87020 HEAD 2>$null
if($LASTEXITCODE -ne 0){throw 'Branch does not descend from frozen main baseline'}
$tracked=@(& git -C $repo ls-files --error-unmatch -- $selfRel $qvsRel 2>$null)
if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 2){throw 'Runner and QVS must both be committed'}
$dirty=@(& git -C $repo status --porcelain -- $selfRel $qvsRel)
if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw 'Runner or QVS is dirty; commit first'}
if(-not(Test-Path -LiteralPath $qvsFile -PathType Leaf)){throw 'Missing committed QVS'}
$qvs=[IO.File]::ReadAllText($qvsFile,[Text.Encoding]::UTF8)
if($qvs -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DROP\s+FILE|RENAME\s+FILE)\b' -or
   $qvs -match '(?i)\$\(\s*Must_Include' -or
   $qvs -notmatch '\[VIII-B-T24\] VERDICT=PASS_RELOAD_STRUCTURE_ONLY_NOT_T24'){
    throw 'Unexpected QVS operation or missing success marker'
}
$work=Join-Path ([IO.Path]::GetTempPath()) ('SAD_VIII_T24_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work -ErrorAction Stop
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('VERSIONED_GIT_HEAD='+$gitHead[0])
Write-Output ('BRANCH='+$gitBranch[0])
Write-Output ('SCRIPT_SHA256='+$qvsRel+'|'+(Get-FileHash -LiteralPath $qvsFile -Algorithm SHA256).Hash)
Write-Output ('RUNNER_SHA256='+$selfRel+'|'+(Get-FileHash -LiteralPath $self -Algorithm SHA256).Hash)
Write-Output ('MODE='+$(if($RunQlik){'QLIK_DISPOSABLE_TEMP'}else{'INVENTORY_READ_ONLY'}))
Write-Output 'ORIGINAL_QVD_QVW_WRITE=False T24_ANNUAL_PILOT=True T25_T26_P5_D2=NOT_TESTED PRODUCTION_APPROVED=False'

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
$allCasesPassed=$false
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
        Write-Output 'VERDICT=PASS_INVENTORY_ONLY_T24_NOT_EXECUTED'
    }else{
        if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){
            throw 'Native QlikView Desktop 12 requires Windows'
        }
        foreach($entry in $paths.GetEnumerator()){$qvs=$qvs.Replace($entry.Key,$entry.Value)}
        if($qvs -match '__[A-Z_]+__'){throw 'Unresolved QVD placeholder in QVS'}
        $testQvw=Join-Path $work 'SAD_VIII_T24_ANNUAL_TEST.qvw'
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
            $pass=@($events | Where-Object {$_.Contains('[VIII-B-T24] VERDICT=PASS_RELOAD_STRUCTURE_ONLY_NOT_T24')})
            $blocked=@($events | Where-Object {$_.Contains('[VIII-B-T24] VERDICT=BLOCKED')})
            if($pass.Count -ne 1 -or $blocked.Count -gt 0){throw 'Missing unique T24 structural PASS or BLOCKED detected'}
            $rawLog=Get-Content -LiteralPath $testLog -Raw
            if($rawLog -match '(?i)circular reference|loosely coupled|synthetic key'){
                throw 'Possible loop/synthetic association in native QlikView log; inspect before proceeding'
            }
            # [T24] numerical reconciliation is performed on the fresh TEMP QVW.
            
            $oracleCsv=Join-Path $F3Dir 'F3_componentes_residencia_ano.csv'
            $oracleManifest=Join-Path $F3Dir 'manifest_F3.json'
            if(-not(Test-Path -LiteralPath $oracleCsv -PathType Leaf) -or
               -not(Test-Path -LiteralPath $oracleManifest -PathType Leaf)){
                throw 'Missing independent F3 CSV/manifest'
            }
            $m=Get-Content -LiteralPath $oracleManifest -Raw -Encoding UTF8 | ConvertFrom-Json
            $hash=[string]$m.output_sha256.'F3_componentes_residencia_ano.csv'
            if($hash -notmatch '^[a-fA-F0-9]{64}$' -or
               (Get-FileHash -LiteralPath $oracleCsv -Algorithm SHA256).Hash -cne $hash.ToUpperInvariant()){
                throw 'Independent F3 CSV SHA differs from manifest'
            }
            $ref=@(Import-Csv -LiteralPath $oracleCsv -Delimiter ';' -Encoding UTF8)
            if($ref.Count -ne 669){throw 'F3 annual reference must contain 669 rows'}
            Write-Output ('F3_ORACLE_SHA256='+$hash.ToUpperInvariant())
            $cases=@(
                @{Name='PB_2017'; Year='2017'; Mun=''},
                @{Name='PB_2018'; Year='2018'; Mun=''},
                @{Name='PB_2019'; Year='2019'; Mun=''},
                @{Name='JP_2018'; Year='2018'; Mun='250750'},
                @{Name='CG_2018'; Year='2018'; Mun='250400'}
            )
            $culture=[Globalization.CultureInfo]::InvariantCulture
            $resultRows=@()
            foreach($c in $cases){
                $refRows=@($ref | Where-Object {
                    $_.ano -ceq $c.Year -and
                    ($c.Mun -ceq '' -or $_.municipio_residencia -ceq $c.Mun)
                })
                $needed=if($c.Mun -ceq ''){223}else{1}
                if($refRows.Count -ne $needed){throw ('Missing F3 territory '+$c.Name)}
                [long]$expectedN=0
                [long]$expectedP=0
                foreach($r in $refRows){
                    $expectedN += [long]::Parse([string]$r.internacoes_elegiveis,$culture)
                    $expectedP += [long]::Parse([string]$r.denominador_populacao,$culture)
                }
                if($expectedP -le 0 -or $expectedN -lt 0){throw ('Invalid F3 denominator '+$c.Name)}
                if($c.Mun -ceq ''){
                    $historical=@{ '2017'=@(182069,4025558); '2018'=@(181673,3996496); '2019'=@(186280,4018127) }
                    if($expectedN -ne $historical[$c.Year][0] -or $expectedP -ne $historical[$c.Year][1]){
                        throw ('F3 state totals differ from historical independent reference '+$c.Name)
                    }
                }
                $null=$doc.ClearAll()
                $null=$doc.GetField('PERIODO_ANO').Select($c.Year)
                if($c.Mun -ceq ''){
                    $role='RES_UF'
                    $null=$doc.GetField($role).Select('PB')
                }else{
                    $role='RES_COD_DATASUS_6'
                    $null=$doc.GetField($role).Select($c.Mun)
                }
                $sy=[string]$doc.Evaluate('GetSelectedCount(PERIODO_ANO)')
                $sr=[string]$doc.Evaluate(('GetSelectedCount('+$role+')'))
                $sm=[string]$doc.Evaluate('GetSelectedCount(PERIODO_COMPETENCIA)')
                $available=[string]$doc.Evaluate('Count(DISTINCT PERIODO_COMPETENCIA)')
                if($sy -ne '1' -or $sr -ne '1' -or $sm -ne '0' -or $available -ne '12'){
                    throw ('Temporal/role selection mismatch for '+$c.Name)
                }
                $rawN=[string]$doc.Evaluate("Num(Sum(QTD_INTERNACAO),'0','.','')")
                $rawP=[string]$doc.Evaluate("Num(Sum(POPULACAO_ESTIMADA),'0','.','')")
                # Num() is a locale-dependent dual formatting function. Do not format a rate before COM evaluation.
                # Preserve the raw Qlik numeric expression; normalize only a single decimal separator.
                $rawRate=[string]$doc.Evaluate('1000*Sum(QTD_INTERNACAO)/Sum(POPULACAO_ESTIMADA)')
                Write-Output ('T24_RAW_QLIK_RATE_CASE='+$c.Name+' RAW='+$rawRate)
                if($rawN -notmatch '^\d+$' -or $rawP -notmatch '^\d+$' -or
                   $rawRate.Trim() -notmatch '^\d+([.,]\d+)?$'){
                    throw ('Ambiguous Qlik number/POP denominator for '+$c.Name+
                        ' NUM='+$rawN+' POP='+$rawP+' RAW_RATE='+$rawRate)
                }
                $actualN=[long]::Parse($rawN,$culture)
                $actualP=[long]::Parse($rawP,$culture)
                $normalizedRate=$rawRate.Trim().Replace(',','.')
                $actualRate=[decimal]::Parse($normalizedRate,[Globalization.NumberStyles]::AllowDecimalPoint,$culture)
                $expectedRate=[decimal]1000*[decimal]$expectedN/[decimal]$expectedP
                $delta=[Math]::Abs([decimal]($actualRate-$expectedRate))
                $ok=($actualN -eq $expectedN -and $actualP -eq $expectedP -and
                    $delta -le [decimal]0.000001)
                $resultRows += [pscustomobject]@{
                    Case=$c.Name; Year=$c.Year; Residence=$c.Mun
                    OracleAdmissions=$expectedN; QlikAdmissions=$actualN
                    OraclePop=$expectedP; QlikPop=$actualP
                    OracleRate=$expectedRate.ToString($culture)
                    QlikRateRaw=$rawRate
                    QlikRate=$actualRate.ToString($culture)
                    Error=$delta.ToString($culture)
                    Status=$(if($ok){'PASS_CANDIDATE'}else{'BLOCKED_MISMATCH'})
                }
                $resultRows | Export-Csv -LiteralPath (Join-Path $work 't24_reconciliation.csv') -NoTypeInformation -Encoding UTF8
                Write-Output ('T24_CASE='+$c.Name+' RESULT='+$resultRows[-1].Status+
                    ' ORACLE_N='+$expectedN+' QLIK_N='+$actualN+
                    ' ORACLE_POP='+$expectedP+' QLIK_POP='+$actualP)
                if(-not $ok){throw ('Numeric mismatch in independent F3 vs Qlik '+$c.Name)}
            }
            $allCasesPassed=$true
            Write-Output 'T24_ANNUAL_5_CASES=PASS_NUMERIC_CANDIDATE_PENDING_SHA_RECHECK'
            $null=$doc.Save()
            Write-Output ('TEMP_QVW='+$testQvw)
            Write-Output ('NATIVE_LOG='+$testLog)
            Write-Output 'T24_PILOT_QVW_TEST=COMPLETE_PENDING_FINAL_HASHES'
            Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED'
            Write-Output 'P5_D2_T25_T26=NOT_TESTED CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED'
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
if($RunQlik -and $allCasesPassed){
    Write-Output 'VERDICT=PASS_LOCAL_T24_ANNUAL_5_CASES_CANDIDATE_ONLY'
}
