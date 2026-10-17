# SAD VI-P4: municipality x month CNES/LT observability ONLY. QVDs read-only.
# Three TXT audit exports are permitted strictly under a unique %TEMP% folder.
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo=[IO.Path]::GetFullPath($Root)
$work=Join-Path ([IO.Path]::GetTempPath()) ('SAD_VI_P4_READONLY_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')+'_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -Path $work -ItemType Directory -ErrorAction Stop
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('PHASE=VI-P4 MODE='+$(if($RunQlik){'PHYSICAL_MUNICIPAL_MONTH_OBSERVABILITY'}else{'QVD_HEADER_AND_HASH_ONLY'}))
Write-Output 'EXISTING_QVD_READ_ONLY=True'
Write-Output 'EVIDENCE_ONLY_TXT_EXPORTS_TO_TEMP=True'
Write-Output 'TRANSF_QVW_NOT_RELOADED=True'
Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
Write-Output 'PRODUCTION_APPROVED=False'
# VI-GOV: only committed tracked version of this runner + QVS may be executed.
$viRunnerRel='tools/Invoke-SadViP4Readonly.ps1'
$viQvsRel='TRANSFORMACAO/vi_p4_municipal_coverage.qvs'
if ([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath((Join-Path $repo $viRunnerRel))) {throw 'Run the versioned runner from the repository tools directory'}
$viHead=@(& git -C $repo rev-parse --verify HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or $viHead.Count -ne 1 -or $viHead[0] -notmatch '^[0-9a-f]{40}$') {throw 'Git HEAD is unavailable; versioned execution is mandatory'}
$viTracked=@(& git -C $repo ls-files --error-unmatch -- $viRunnerRel $viQvsRel 2>$null)
if ($LASTEXITCODE -ne 0 -or $viTracked.Count -ne 2) {throw 'Runner/QVS are not both tracked by Git'}
$viDirty=@(& git -C $repo status --porcelain -- $viRunnerRel $viQvsRel)
if ($LASTEXITCODE -ne 0 -or $viDirty.Count -gt 0) {throw 'Runner/QVS differ from committed Git state; commit changes before execution'}
Write-Output ('VERSIONED_GIT_HEAD=' + $viHead[0])


$factChecks=@{
 'FATO_INTERNACAO.qvd'=@{rows=566672;fields=17;required=@('SK_REGISTRO_INTERNACAO','%LINK_KEY','QTD_INTERNACAO')}
 'FATO_CAPACIDADE_LEITO.qvd'=@{rows=35518;fields=11;required=@('SK_REGISTRO_CAPACIDADE_LEITO','%LINK_KEY','QTD_LEITOS_SUS','QTD_LEITOS_EXISTENTES','QTD_LEITOS_NAO_SUS')}
 'FATO_POPULACAO.qvd'=@{rows=669;fields=7;required=@('%SK_MUNICIPIO','%SK_TEMPO_ANO','POPULACAO_ESTIMADA','FATO_POP_DATASUS6_REFERENCIA_PB')}
}

function Read-QvdHeader([string]$file) {
    # The header of a QVD is XML, followed by binary data. Read only the bounded prefix.
    $stream = [IO.File]::Open($file, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        $size = [int][Math]::Min(4194304, $stream.Length)
        $bytes = New-Object byte[] $size
        $count = $stream.Read($bytes, 0, $size)
        $prefix = [Text.Encoding]::UTF8.GetString($bytes, 0, $count)
        $closing = '</QvdTableHeader>'
        $i = $prefix.IndexOf($closing, [StringComparison]::Ordinal)
        if ($i -lt 0) { throw "QVD XML header terminator not found in first 4MB: $file" }
        [xml]$xml = $prefix.Substring(0, $i + $closing.Length)
        $node = $xml.DocumentElement
        if ($null -eq $node -or $node.LocalName -ne 'QvdTableHeader') {throw "Unexpected QVD XML root: $file"}
        $rowsNode = $node.SelectSingleNode('./NoOfRecords')
        if ($null -eq $rowsNode) {throw "NoOfRecords missing in QVD: $file"}
        $fields = @($node.SelectNodes('./Fields/QvdFieldHeader/FieldName') | ForEach-Object {$_.InnerText})
        if ($fields.Count -lt 1) {throw "Missing QVD fields: $file"}
        return [pscustomobject]@{Rows=[long]$rowsNode.InnerText;Fields=@($fields)}
    } finally {$stream.Dispose()}
}
function Snapshot-Qvds {
    $ext = Join-Path $repo 'EXTRACAO\QVD'
    $transf = Join-Path $repo 'TRANSFORMACAO\QVD'
    foreach($folder in @($ext,$transf)) {
      if (-not (Test-Path -LiteralPath $folder -PathType Container)) {throw "Missing folder: $folder"}
    }
    $a=@(Get-ChildItem -LiteralPath $ext -Filter '*.qvd' -File)
    $b=@(Get-ChildItem -LiteralPath $transf -Filter '*.qvd' -File)
    if ($a.Count -ne 10 -or $b.Count -ne 11) {throw "Expected 10 extraction and 11 transformation QVDs; found $($a.Count) and $($b.Count)"}
    $all=@($a)+@($b)
    if ($all.Count -ne 21) {throw 'QVD inventory count mismatch'}
    if (@($all | Where-Object {$_.Name -ieq 'LINK_ANALISE.qvd'}).Count -gt 0) {throw 'LINK_ANALISE already exists; stop and review'}
    $list = @()
    foreach ($file in $all) {
        if ($file.Length -le 0) {throw "Empty QVD: $($file.FullName)"}
        $h = Read-QvdHeader $file.FullName
        if ($factChecks.ContainsKey($file.Name)) {
            $rule=$factChecks[$file.Name]
            if ($h.Rows -ne $rule.rows -or $h.Fields.Count -ne $rule.fields) {
                throw "Unexpected fact schema/rows: $($file.Name): $($h.Rows) rows, $($h.Fields.Count) fields"
            }
            foreach ($required in $rule.required) {
                if ($h.Fields -cnotcontains $required) {throw "Missing required fact field '$required': $($file.Name)"}
            }
        }
        $hash=(Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
        $list += [pscustomobject]@{
            Path=$file.FullName;Name=$file.Name;Bytes=[long]$file.Length;
            Rows=$h.Rows;FieldCount=$h.Fields.Count;
            FieldNames=($h.Fields -join '|');SHA256=$hash
        }
    }
    return @($list | Sort-Object Path)
}

$before=$null
$app=$null
$doc=$null
$verdict='INCONCLUSIVE'
$problem=$null
try {
  $before=@(Snapshot-Qvds)
  $before | Export-Csv -LiteralPath (Join-Path $work 'qvd_manifest_before.csv') -NoTypeInformation -Encoding UTF8
  Write-Output 'HEADER_AND_SHA256_INVENTORY=PASS 10_EXTRACAO 11_TRANSFORMACAO'
  $qvs=Join-Path $repo 'TRANSFORMACAO\vi_p4_municipal_coverage.qvs'
  if(-not (Test-Path -LiteralPath $qvs -PathType Leaf)){throw "Missing QVS: $qvs"}
  $qvsSha=(Get-FileHash -Algorithm SHA256 -LiteralPath $qvs).Hash
  Write-Output ('QVS_SHA256='+$qvsSha)
  if($qvsSha -cne 'CA3CA2EDA0101D3E09471738B5B1C8281A2E25691B563D44FE157256535C3AC4'){throw 'QVS differs from reviewed VI-P4 text'}
  $src=[IO.File]::ReadAllText($qvs,[Text.Encoding]::UTF8)
  if([regex]::Matches($src,'(?im)^\s*STORE\s+\*\s+FROM\s+P4_\w+\s+INTO\s+\[__\w+__\]\s+\(txt, delimiter is ''\|''\);').Count -ne 3){throw 'Audit TXT STORE whitelist mismatch'}
  if([regex]::Matches($src,'(?im)^\s*STORE\b').Count -ne 3){throw 'Unexpected STORE command detected'}
  if($src -match '(?im)^\s*(EXECUTE|BINARY|SQL|DIRECT\s+QUERY|DROP\s+FILE)\b'){throw 'Forbidden QVS operation'}
  if($src -notmatch '\[P4\] VERDICT=PASS_MUNICIPAL_MONTH_OBSERVABILITY_ONLY'){throw 'Required verdict marker missing'}
  if($RunQlik){
    $paths=@{
      '__FACT_QVD__'='TRANSFORMACAO\QVD\FATO_CAPACIDADE_LEITO.qvd'
      '__POP_QVD__'='TRANSFORMACAO\QVD\FATO_POPULACAO.qvd'
      '__LT_STAGE_QVD__'='EXTRACAO\QVD\SRC_CNES_LT.qvd'
    }
    foreach($name in $paths.Keys){
      $full=Join-Path $repo $paths[$name]
      if(-not (Test-Path -LiteralPath $full -PathType Leaf)){throw "Missing QVD input: $full"}
      if($full -match '[\]\r\n]'){throw "Unsupported QVD path: $full"}
      $src=$src.Replace($name,$full)
    }
    $exportNames=@{
      '__MATRIX_TXT__'='municipio_mes_observabilidade.txt'
      '__YEARS_TXT__'='municipio_ano_observabilidade.txt'
      '__MONTHS_TXT__'='competencia_observabilidade.txt'
    }
    foreach($name in $exportNames.Keys){
      $path=Join-Path $work $exportNames[$name]
      if($path -match '[\]\r\n]'){throw 'Unsupported temporary evidence path'}
      if(Test-Path -LiteralPath $path){throw "Evidence destination already exists: $path"}
      $src=$src.Replace($name,$path)
    }
    if($src -match '__[A-Z_]+__'){throw 'Unresolved QVS placeholder'}
    $qvw=Join-Path $work 'SAD_VI_P4_DISPOSABLE.qvw'
    $log=$qvw+'.log'
    $app=New-Object -ComObject 'QlikTech.QlikView'
    $doc=$app.CreateDoc()
    if($null -eq $doc){throw 'QlikView COM did not create a document'}
    $properties=$doc.GetProperties()
    $properties.Script=$src
    $properties.GenerateLogfile=$true
    $null=$doc.SetProperties($properties)
    if(-not [bool]$doc.GetProperties().GenerateLogfile){throw 'Cannot enable native reload log'}
    $null=$doc.SaveAs($qvw)
    if(-not (Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'Disposable QVW was not saved'}
    $start=[DateTime]::UtcNow
    $null=$doc.Reload()
    if(-not (Test-Path -LiteralPath $log -PathType Leaf)){throw 'Native QlikView log missing'}
    if((Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $start.AddSeconds(-3)){throw 'Native log timestamp predates reload'}
    $executed=@(Get-Content -LiteralPath $log | Where-Object {$_ -notmatch '\bTRACE\b'})
    $pass=@($executed | Where-Object {$_.Contains('[P4] VERDICT=PASS_MUNICIPAL_MONTH_OBSERVABILITY_ONLY')})
    $block=@($executed | Where-Object {$_ -match '\[P4\] VERDICT=BLOCKED'})
    if($pass.Count -ne 1 -or $block.Count -gt 0){
      foreach($line in @($executed | Where-Object {$_.Contains('[P4] PREJOIN ') -or $_.Contains('[P4] VERDICT=BLOCKED_')})){
        Write-Output ('P4_NATIVE_DIAG='+([string]$line).Trim())
      }
      throw 'P4 Qlik native PASS missing or blocked; inspect QVW log before retry'
    }
    $reference=@($executed | Where-Object {$_.Contains('[P4] GRID_ROWS=8028')})
    if($reference.Count -ne 1){throw 'P4 executed grid summary missing'}
    Write-Output ('P4_NATIVE_SUMMARY='+([string]$reference[0]).Trim())
    function Read-Evidence([string]$filename,[int]$expected,[string[]]$required){
      $path=Join-Path $work $filename
      if(-not (Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing audit TXT: $path"}
      if((Get-Item -LiteralPath $path).Length -le 40){throw "Empty audit TXT: $path"}
      $result=@(Import-Csv -LiteralPath $path -Delimiter '|' -Encoding UTF8)
      if($result.Count -ne $expected){throw "Unexpected TXT evidence rows in $filename expected=$expected actual=$($result.Count)"}
      $columns=@($result[0].PSObject.Properties.Name)
      foreach($column in $required){if($columns -cnotcontains $column){throw "Missing column $column in $filename (header: $($columns -join '|'))"}}
      return $result
    }
    $matrix=@(Read-Evidence 'municipio_mes_observabilidade.txt' 8028 @('MUNICIPIO','COMPETENCIA','LINHAS_LT','QT_SUS_OBSERVADO','QT_EXIST_OBSERVADO','ESTADO_OBSERVADO','ZERO_REAL_COMPROVADO','COBERTURA_HOSPITALAR'))
    $years=@(Read-Evidence 'municipio_ano_observabilidade.txt' 669 @('MUNICIPIO','ANO','MESES_COM_LINHAS','MESES_SEM_LINHAS','MESES_UNIVERSO'))
    $months=@(Read-Evidence 'competencia_observabilidade.txt' 36 @('COMPETENCIA','MUNICIPIOS_NO_UNIVERSO','MUNICIPIOS_SEM_LINHAS','MUNICIPIOS_COM_ZERO_OBSERVADO','MUNICIPIOS_COM_POSITIVO','LINHAS_LT_TOTAL','SUS_TOTAL_SNAPSHOT'))
    $distinct=[Collections.Generic.HashSet[string]]::new()
    $mun=[Collections.Generic.HashSet[string]]::new()
    $comp=[Collections.Generic.HashSet[string]]::new()
    [long]$absence=0;[long]$zero=0;[long]$positive=0;[long]$rows=0;[long]$sus=0;[long]$exist=0
    foreach($r in $matrix){
      $code=[string]$r.MUNICIPIO; $period=[string]$r.COMPETENCIA; $status=[string]$r.ESTADO_OBSERVADO
      if($code -notmatch '^25\d{4}$' -or $period -notmatch '^201[789](0[1-9]|1[012])$'){throw "Out-of-universe municipality/competence: $code $period"}
      if(-not $distinct.Add($code+'|'+$period)){throw "Duplicate municipality x month in audit TXT: $code $period"}
      $null=$mun.Add($code);$null=$comp.Add($period)
      if($r.ZERO_REAL_COMPROVADO -ne 'NOT_PROVEN' -or $r.COBERTURA_HOSPITALAR -ne 'NOT_VERIFIED'){throw "False zero or scope proof in audit TXT: $code $period"}
      if($status -eq 'ABSENT_NOT_ZERO_PROVEN'){
        $absence++
        if(-not [string]::IsNullOrWhiteSpace([string]$r.LINHAS_LT) -or -not [string]::IsNullOrWhiteSpace([string]$r.QT_SUS_OBSERVADO)){throw "Absent row has numeric values: $code $period"}
      }elseif($status -eq 'OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED' -or $status -eq 'OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED'){
        $n=[long]::Parse([string]$r.LINHAS_LT,[Globalization.CultureInfo]::InvariantCulture)
        $s=[long]::Parse([string]$r.QT_SUS_OBSERVADO,[Globalization.CultureInfo]::InvariantCulture)
        $e=[long]::Parse([string]$r.QT_EXIST_OBSERVADO,[Globalization.CultureInfo]::InvariantCulture)
        if($n -le 0 -or $s -lt 0 -or $e -lt $s){throw "Invalid recorded LT subtotal: $code $period"}
        $rows+=$n;$sus+=$s;$exist+=$e
        if($status -eq 'OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED'){
          if($s -ne 0){throw "Expected observed zero: $code $period"};$zero++
        }else{
          if($s -le 0){throw "Expected observed positive: $code $period"};$positive++
        }
      }else{throw "Unknown observed status: $status"}
    }
    if($mun.Count -ne 223 -or $comp.Count -ne 36 -or $distinct.Count -ne 8028){throw 'Incomplete 223 x 36 evidence universe'}
    if($absence+$zero+$positive -ne 8028 -or $rows -ne 35518 -or $sus -ne 270076 -or $exist -ne 337147){throw "Audit TXT totals do not reconcile: absent=$absence zero=$zero positive=$positive rows=$rows sus=$sus exist=$exist"}
    $yearUnique=[Collections.Generic.HashSet[string]]::new()
    [long]$fullObservationYears=0
    foreach($r in $years){
      if(-not $yearUnique.Add([string]$r.MUNICIPIO+'|'+[string]$r.ANO)){throw 'Duplicate municipal-year audit row'}
      $observed=[int]$r.MESES_COM_LINHAS;$absent=[int]$r.MESES_SEM_LINHAS;$universe=[int]$r.MESES_UNIVERSO
      if($observed+$absent -ne 12 -or $universe -ne 12){throw "Broken municipal-year counts: $($r.MUNICIPIO) $($r.ANO)"}
      if($observed -eq 12){$fullObservationYears++}
    }
    $monthlyComp=[Collections.Generic.HashSet[string]]::new()
    [long]$monthRows=0;[long]$monthSus=0
    foreach($r in $months){
      if(-not $monthlyComp.Add([string]$r.COMPETENCIA)){throw 'Duplicate monthly summary'}
      $parts=([int]$r.MUNICIPIOS_SEM_LINHAS)+([int]$r.MUNICIPIOS_COM_ZERO_OBSERVADO)+([int]$r.MUNICIPIOS_COM_POSITIVO)
      if([int]$r.MUNICIPIOS_NO_UNIVERSO -ne 223 -or $parts -ne 223){throw "Unexpected monthly totals: $($r.COMPETENCIA)"}
      $monthRows+=[long]$r.LINHAS_LT_TOTAL;$monthSus+=[long]$r.SUS_TOTAL_SNAPSHOT
    }
    if($monthRows -ne 35518 -or $monthSus -ne 270076){throw 'Monthly CSV totals do not reconcile'}
    Write-Output ('VI_P4_GRID=PASS_LOCAL 223_MUNICIPIOS 36_COMPETENCIAS 8028_CELLS')
    Write-Output ('VI_P4_CLASSIFICATION ABSENT_NOT_ZERO_PROVEN='+$absence+' OBSERVED_ZERO_QT_SUS='+$zero+' OBSERVED_POSITIVE_QT_SUS='+$positive)
    Write-Output ('VI_P4_LT_RECONCILIATION ROWS='+$rows+' SUS_SNAPSHOT_SUM='+$sus+' EXIST_SNAPSHOT_SUM='+$exist)
    Write-Output ('VI_P4_MUNICIPAL_YEARS_OBSERVED_12_OF_12='+$fullObservationYears+' OF_669_NO_COVERAGE_APPROVAL')
    Write-Output ('VI_P4_EVIDENCE_MATRIX='+ (Join-Path $work 'municipio_mes_observabilidade.txt'))
    Write-Output ('VI_P4_EVIDENCE_YEARS='+ (Join-Path $work 'municipio_ano_observabilidade.txt'))
    Write-Output ('VI_P4_EVIDENCE_MONTHS='+ (Join-Path $work 'competencia_observabilidade.txt'))
    Write-Output 'CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED'
    Write-Output 'ZERO_PROOF=NOT_PROVEN'
    Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
    Write-Output 'MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED'
    Write-Output 'F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY'
    $verdict='PASS_VI_P4_LOCAL_OBSERVABILITY_ONLY_NOT_COVERAGE_APPROVAL'
  }else{
    $verdict='PASS_HEADER_AND_HASH_ONLY_NOT_VI_P4_COMPLETE'
  }
}catch{
  $problem=$_
  $verdict='BLOCKED_OR_INCONCLUSIVE'
}finally{
  if($null -ne $doc){try{$null=$doc.CloseDoc()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}}
  if($null -ne $app){try{$app.Quit()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}}
  if($null -ne $before){
    try{
      $after=@(Snapshot-Qvds)
      $after | Export-Csv -LiteralPath (Join-Path $work 'qvd_manifest_after.csv') -NoTypeInformation -Encoding UTF8
      $map=@{};foreach($item in $before){$map[$item.Path]=$item}
      if($after.Count -ne $before.Count){throw 'QVD inventory changed'}
      foreach($item in $after){
        if(-not $map.ContainsKey($item.Path)){throw "Added QVD: $($item.Path)"}
        $old=$map[$item.Path]
        if($item.SHA256 -cne $old.SHA256 -or $item.Rows -ne $old.Rows -or $item.FieldNames -cne $old.FieldNames){throw "QVD changed: $($item.Path)"}
      }
      Write-Output 'ALL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True'
    }catch{
      Write-Output ('QVD_INTEGRITY_VERIFICATION_FAILED='+$_.Exception.Message)
      if($null -eq $problem){$problem=$_}
      $verdict='BLOCKED_OR_INCONCLUSIVE'
    }
  }
  Write-Output ('EVIDENCE_DIR_FINAL='+$work)
  Write-Output ('VERDICT='+$verdict)
}
if($null -ne $problem){throw $problem}
