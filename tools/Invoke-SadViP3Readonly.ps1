# SAD VI-P3 — temporal/municipal denominator candidate, using verified VI-P1 QVS unchanged.
# Reads all existing QVDs; writes evidence and a disposable QVW/log ONLY to %TEMP%.
# Does NOT reload TRANSF.qvw; no STORE, QVD overwrite, git changes, or production approvals.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [switch]$RunQlik
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath($Root)
$stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
$work = Join-Path ([IO.Path]::GetTempPath()) ('SAD_VI_P3_READONLY_' + $stamp + '_' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -Path $work -ItemType Directory -ErrorAction Stop
Write-Output ('EVIDENCE_DIR=' + $work)
Write-Output ('PHASE=VI-P3 MODE=' + $(if ($RunQlik) {'PHYSICAL_INDICATOR_SOURCE_REFERENCE_PLUS_QLIK_COM'} else {'QVD_HEADER_AND_HASH_ONLY'}))
Write-Output 'EXISTING_QVD_READ_ONLY=True'
Write-Output 'TRANSF_QVW_NOT_RELOADED=True'
Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
Write-Output 'PRODUCTION_APPROVED=False'
# VI-GOV: only committed tracked version of this runner + QVS may be executed.
$viRunnerRel='tools/Invoke-SadViP3Readonly.ps1'
$viQvsRel='TRANSFORMACAO/vi_p3_source_reference.qvs'
if ([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath((Join-Path $repo $viRunnerRel))) {throw 'Run the versioned runner from the repository tools directory'}
$viHead=@(& git -C $repo rev-parse --verify HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or $viHead.Count -ne 1 -or $viHead[0] -notmatch '^[0-9a-f]{40}$') {throw 'Git HEAD is unavailable; versioned execution is mandatory'}
$viTracked=@(& git -C $repo ls-files --error-unmatch -- $viRunnerRel $viQvsRel 2>$null)
if ($LASTEXITCODE -ne 0 -or $viTracked.Count -ne 2) {throw 'Runner/QVS are not both tracked by Git'}
$viDirty=@(& git -C $repo status --porcelain -- $viRunnerRel $viQvsRel)
if ($LASTEXITCODE -ne 0 -or $viDirty.Count -gt 0) {throw 'Runner/QVS differ from committed Git state; commit changes before execution'}
Write-Output ('VERSIONED_GIT_HEAD=' + $viHead[0])


$inputs = [ordered]@{
  'FI_QVD'       = 'TRANSFORMACAO\QVD\FATO_INTERNACAO.qvd'
  'LT_FACT_QVD'  = 'TRANSFORMACAO\QVD\FATO_CAPACIDADE_LEITO.qvd'
  'POP_QVD'      = 'TRANSFORMACAO\QVD\FATO_POPULACAO.qvd'
  'RD_QVD'       = 'EXTRACAO\QVD\SRC_SIH_RD.qvd'
  'LT_STAGE_QVD' = 'EXTRACAO\QVD\SRC_CNES_LT.qvd'
  'TEMPO_QVD'    = 'TRANSFORMACAO\QVD\DIM_TEMPO.qvd'
  'MUN_QVD'      = 'TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd'
  'EST_QVD'      = 'TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd'
}
$factChecks = @{
 'FATO_INTERNACAO.qvd'=@{rows=566672;fields=17;required=@('SK_REGISTRO_INTERNACAO','%LINK_KEY','QTD_INTERNACAO','FATO_RD_COMPETENCIA_ORIGEM')}
 'FATO_CAPACIDADE_LEITO.qvd'=@{rows=35518;fields=11;required=@('SK_REGISTRO_CAPACIDADE_LEITO','%LINK_KEY','%SK_TIPO_LEITO','QTD_LEITOS_SUS')}
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
$candidateVerdict='INCONCLUSIVE'
$doc=$null
$app=$null
try {
    $before = @(Snapshot-Qvds)
    $before | Export-Csv -LiteralPath (Join-Path $work 'qvd_manifest_before.csv') -NoTypeInformation -Encoding UTF8
    Write-Output 'HEADER_AND_SHA256_INVENTORY=PASS 10_EXTRACAO 11_TRANSFORMACAO'
    $scriptFile = Join-Path $repo 'TRANSFORMACAO\vi_p3_source_reference.qvs'
    if (-not (Test-Path -LiteralPath $scriptFile -PathType Leaf)) {throw "Missing QVS alongside runner: $scriptFile"}
    $scriptText=[IO.File]::ReadAllText($scriptFile,[Text.Encoding]::UTF8)
    # Reject direct write/operational commands at the start of script lines.
    if ($scriptText -match '(?im)^\s*(STORE|BINARY|EXECUTE|SQL|DIRECT\s+QUERY)\b') {throw 'QVS contains forbidden data-write command'}
    if ($scriptText -notmatch '\[P1\] VERDICT=PASS_PHYSICAL_KEYS_AND_TEMPORARY_MODEL_NOT_FINAL' -or $scriptText -notmatch '\[P3\] VERDICT=PASS_SOURCE_REFERENCE_RESTRICTED_NOT_INDICATOR_APPROVAL') {throw 'QVS marker mismatch'}
    $qvsHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $scriptFile).Hash
    Write-Output ('QVS_SHA256=' + $qvsHash)
    if ($qvsHash -cne 'FA0F0D4E263CC9793AA6ED2403BF3849BE47D8F095A59E3BB9FA234708071BEF') {throw 'VI-P3 QVS content differs from reviewed package; fail closed'}

    if ($RunQlik) {
      foreach($pair in $inputs.GetEnumerator()) {
        $full=Join-Path $repo $pair.Value
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {throw "Missing required QVD: $full"}
        if ($full.Contains(']') -or $full.Contains("`n") -or $full.Contains("`r")) {throw 'Unsupported special character in QVD path'}
        $scriptText=$scriptText.Replace(('__'+$pair.Key+'__'),$full)
      }
      if ($scriptText -match '__[A-Z_]+__') {throw 'Unresolved QVD placeholder'}
      $qvw=Join-Path $work 'SAD_VI_P3_DISPOSABLE.qvw'
      $log=$qvw+'.log'
      $app=New-Object -ComObject 'QlikTech.QlikView'
      $doc=$app.CreateDoc()
      if ($null -eq $doc) {throw 'QlikView COM CreateDoc returned null'}
      $props=$doc.GetProperties()
      $props.Script=$scriptText
      $props.GenerateLogfile=$true
      $null=$doc.SetProperties($props)
      if (-not [bool]$doc.GetProperties().GenerateLogfile) {throw 'Cannot enable QlikView native log'}
      $null=$doc.SaveAs($qvw)
      if (-not (Test-Path -LiteralPath $qvw -PathType Leaf)) {throw 'Disposable QVW was not saved'}
      $reloadStarted=[DateTime]::UtcNow
      $null=$doc.Reload()
      if (-not (Test-Path -LiteralPath $log -PathType Leaf)) {throw 'QlikView native log missing'}
      if ((Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $reloadStarted.AddSeconds(-3)) {throw 'QlikView log is not contemporaneous'}
      # Qlik logs contain script-source TRACE statements as well as executed traces.
      # Exclude script-source lines to avoid false positives/false BLOCKED markers.
      $executedLines=@(Get-Content -LiteralPath $log | Where-Object {$_ -notmatch '\bTRACE\b'})
      $passed=@($executedLines | Where-Object {$_.Contains('[P1] VERDICT=PASS_PHYSICAL_KEYS_AND_TEMPORARY_MODEL_NOT_FINAL')})
      $blocked=@($executedLines | Where-Object {$_ -match '\[P1\] VERDICT=BLOCKED'})
      $topology=@($executedLines | Where-Object {$_.Contains('[P1] FINAL_MODEL TABLES=9 SYNTHETIC=0')})
      if ($passed.Count -ne 1 -or $blocked.Count -gt 0) {throw 'QlikView executed PASS missing/blocked — inspect native QVW log'}
      if ($topology.Count -ne 1) {throw 'Executed Qlik table topology evidence missing'}
      Write-Output 'PHYSICAL_KEYS_QVD_VS_STAGING=PASS_LOCAL_CANDIDATE_ONLY'
      Write-Output 'TEMP_MODEL=9_TABLES_0_SYNTHETIC'

      # VI-P3: independent source aggregates were computed in the Qlik reload (separate
      # scratch loads from staging RD/LT and persisted POP, dropped before finishing).
      $sourcePass=@($executedLines | Where-Object {$_.Contains('[P3] VERDICT=PASS_SOURCE_REFERENCE_RESTRICTED_NOT_INDICATOR_APPROVAL')})
      $sourceBlock=@($executedLines | Where-Object {$_ -match '\[P3\] VERDICT=BLOCKED'})
      if ($sourcePass.Count -ne 1 -or $sourceBlock.Count -gt 0) {throw 'P3 source reference trace missing/blocked; inspect native QVW log'}
      function RefLine([string]$pattern) {
        $hits=@($executedLines | Where-Object {$_ -match $pattern})
        if ($hits.Count -ne 1) {throw "Expected exactly one executed reference trace matching: $pattern; found $($hits.Count)"}
        return [string]$hits[0]
      }
      $rdLine=RefLine '\[P3\] REF_RD_PB_YEAR='
      $popLine=RefLine '\[P3\] REF_POP_PB_2018='
      $covLine=RefLine '\[P3\] REF_LT_JP_2018_MONTHS_OBSERVED='
      function MatchNamed([string]$line,[string]$label) {
        $m=[regex]::Match($line,([regex]::Escape($label) + '=([0-9]+)'))
        if (-not $m.Success) {throw "Cannot parse $label in source trace"}
        return [decimal]::Parse($m.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
      }
      $ref=[ordered]@{
        PbRD=MatchNamed $rdLine 'REF_RD_PB_YEAR'
        ResJpYear=MatchNamed $rdLine 'RES_JP_YEAR'
        ResJpMonth=MatchNamed $rdLine 'RES_JP_201809'
        ServJpYear=MatchNamed $rdLine 'SERV_JP_YEAR'
        ServJpMonth=MatchNamed $rdLine 'SERV_JP_201809'
        PbPop=MatchNamed $popLine 'REF_POP_PB_2018'
        JpPop=MatchNamed $popLine 'REF_POP_JP_2018'
      }
      if ($ref.PbRD -ne 183311 -or $ref.PbPop -ne 3996496 -or $ref.JpPop -ne 800323) {throw 'Source reference anchors differ from Phase V/VI-P2'}
      $monthsObserved=[int](MatchNamed $covLine 'REF_LT_JP_2018_MONTHS_OBSERVED')
      $invalid=[int](MatchNamed $covLine 'INVALID_VALUES')
      if ($invalid -ne 0) {throw 'Invalid/non-numeric/negative JP LT quantity in 2018'}
      $ltByMonth=@{}
      $ltLines=@($executedLines | Where-Object {$_ -match '\[P3\] REF_LT_JP_MONTH='})
      foreach($ln in $ltLines) {
        $m=[regex]::Match($ln,'REF_LT_JP_MONTH=(2018\d{2}) ROWS=([0-9]+) SUS=([0-9]+)')
        if (-not $m.Success) {throw "Bad LT month reference: $ln"}
        $month=$m.Groups[1].Value
        if ($ltByMonth.ContainsKey($month)) {throw "Duplicate LT source reference month: $month"}
        $ltByMonth[$month]=[pscustomobject]@{Rows=[decimal]::Parse($m.Groups[2].Value);Sus=[decimal]::Parse($m.Groups[3].Value)}
      }
      if ($monthsObserved -ne $ltByMonth.Count) {throw 'LT observed month count differs from traces'}
      $ref | ConvertTo-Json -Depth 4 | Out-File -LiteralPath (Join-Path $work 'source_reference_sample.json') -Encoding UTF8
      Write-Output ('P3_SOURCE_REFERENCE=PASS_REFERENCE_QVD_AND_STAGING_NUMERIC_ANCHORS months_observed=' + $monthsObserved)
      function EvalQ([string]$expression) {return [string]($doc.Evaluate($expression))}
      function NumQ([string]$expr,[string]$case) {
        $v=(EvalQ $expr).Trim()
        if ($v -notmatch '^-?\d+(\.\d+)?$') {throw "Qlik returned non-invariant numeric expression for ${case}: '$v'"}
        return [decimal]::Parse($v,[Globalization.CultureInfo]::InvariantCulture)
      }
      function AssertInteger([string]$case,[string]$expression,[decimal]$expected) {
        $actual=NumQ $expression $case
        Write-Output ('CASE='+$case+' ACTUAL='+$actual+' EXPECTED='+$expected)
        if ($actual -ne $expected) {throw "VI-P3 source vs association mismatch: $case"}
      }
      function AssertRatio([string]$case,[string]$expression,[decimal]$numerator,[decimal]$denominator,[decimal]$scale) {
        if ($denominator -le 0) {throw "Nonpositive or unavailable denominator: $case"}
        $expected=[decimal]::Round(($scale*$numerator/$denominator),6,[MidpointRounding]::AwayFromZero)
        # QlikView 12 COM returns decimal comma in this verified Windows locale.
        # Use the format confirmed by VI-P3 R2: "49,191389" (not Num's dot-mask).
        # Parse explicitly using pt-BR, not the Windows PowerShell process locale.
        $formatted=(EvalQ ("Num("+$expression+",'0,000000',',','.')")).Trim()
        $culture=[Globalization.CultureInfo]::GetCultureInfo('pt-BR')
        $numberStyle=([Globalization.NumberStyles]::AllowLeadingSign -bor [Globalization.NumberStyles]::AllowDecimalPoint -bor [Globalization.NumberStyles]::AllowThousands)
        if ($formatted -notmatch '^-?(?:\d+|\d{1,3}(?:\.\d{3})+),\d{6}$') {
            throw "Unexpected explicit pt-BR Qlik ratio output for ${case}: '$formatted'"
        }
        $actual=[decimal]::Parse($formatted,$numberStyle,$culture)
        # Guard against a formatted result that differs from the raw numeric
        # expression, so changing presentation cannot conceal a wrong KPI.
        $raw=(EvalQ $expression).Trim()
        if ($raw -notmatch '^-?(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d+)?$') {
            throw "Unexpected raw Qlik numeric value for ${case}: '$raw'"
        }
        $rawValue=[decimal]::Parse($raw,$numberStyle,$culture)
        Write-Output ('CASE='+$case+' QLIK='+$actual+' SOURCE_REFERENCE_CALC='+$expected+' TOLERANCE=0.000002 RAW_QLIK='+$raw+' FORMAT=EXPLICIT_PT_BR')
        if (([Math]::Abs([decimal]($actual-$expected)) -gt [decimal]0.000002) -or ([Math]::Abs([decimal]($rawValue-$expected)) -gt [decimal]0.000002)) {
          # Restricted, read-only diagnostic on the very first mismatch.
          # Do not normalize away a discrepancy or grant PASS from an alternate format.
          Write-Output ('RATIO_DIAG_CASE=' + $case)
          Write-Output ('RATIO_DIAG_EXPRESSION=' + $expression)
          function ProbeQ([string]$name,[string]$qExpression) {
            try { $value=EvalQ $qExpression; Write-Output ('RATIO_DIAG_' + $name + '=' + $value) }
            catch { Write-Output ('RATIO_DIAG_' + $name + '=ERROR_' + $_.Exception.Message) }
          }
          ProbeQ 'RAW_EXPRESSION' $expression
          ProbeQ 'RAW_NUMERATOR' 'Sum(P1_QTD_INTERNACAO)'
          ProbeQ 'RAW_DENOMINATOR' 'Sum(P1_POPULACAO)'
          ProbeQ 'REFERENCE_LITERAL' '1000*39369/800323'
          ProbeQ 'REFERENCE_LITERAL_NUM_DOT' "Num(1000*39369/800323,'0.000000','.','')"
          ProbeQ 'REFERENCE_LITERAL_NUM_COMMA' "Num(1000*39369/800323,'0,000000',',','.')"
          ProbeQ 'SAMPLE_RAW_DIVISION' '39369/800323'
          throw "VI-P3 numeric or display mismatch at $case. Preserve the diagnostics, no approval."
        }
      }
      function ResetQ {$null=$doc.ClearAll()}
      function SelectQ([string]$field,[string]$value) {
        $f=$doc.GetField($field)
        if ($null -eq $f) {throw "Missing Qlik field: $field"}
        $null=$f.Select($value)
        if ((EvalQ ('GetSelectedCount('+$field+')')) -cne '1') {throw "Cannot select $field=$value"}
      }
      $popRecover='Sum({$<P1_COMPETENCIA=>} P1_POPULACAO)'
      # Legacy Aggr() candidate was observed as 2162 (28106/13),
      # whereas 12 independent monthly LT snapshots sum to 28106.
      # VI-P3 R4 tests an ALTERNATIVE CANDIDATE, not an official KPI formula.
      $bedAverageLegacy='Avg(Aggr(Sum(P1_QTD_LEITOS_SUS),P1_COMPETENCIA))'
      $bedAverage='(Sum(P1_QTD_LEITOS_SUS)/Count(DISTINCT P1_COMPETENCIA))'
      # T24 control: RD resident year and partial-month rate, from raw SIH/RD + fact POP.
      ResetQ; SelectQ 'P1_ANO' '2018'
      AssertInteger 'PB_YEAR_2018_RD_ADMIN_ALL_RESIDENCES' 'Sum(P1_QTD_INTERNACAO)' $ref.PbRD
      AssertInteger 'PB_YEAR_2018_POP_REFERENCE' 'Sum(P1_POPULACAO)' $ref.PbPop
      Write-Output 'PB_YEAR_RATE=NOT_EVALUATED_RD_INCLUDES_RESIDENTS_OUTSIDE_PB'
      ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_RES_CODE' '250750'
      AssertInteger 'T24_JP_RES_YEAR_RD' 'Sum(P1_QTD_INTERNACAO)' $ref.ResJpYear
      AssertInteger 'T24_JP_RES_YEAR_POP' 'Sum(P1_POPULACAO)' $ref.JpPop
      AssertRatio 'T24_JP_RES_YEAR_RATE' '1000*Sum(P1_QTD_INTERNACAO)/Sum(P1_POPULACAO)' $ref.ResJpYear $ref.JpPop 1000
      SelectQ 'P1_COMPETENCIA' '201809'
      AssertInteger 'T24_JP_RES_201809_RD' 'Sum(P1_QTD_INTERNACAO)' $ref.ResJpMonth
      AssertInteger 'T24_JP_RES_201809_POP_RECOVERED' $popRecover $ref.JpPop
      AssertRatio 'T24_JP_RES_201809_PARTIAL_RATE' ('1000*Sum(P1_QTD_INTERNACAO)/'+$popRecover) $ref.ResJpMonth $ref.JpPop 1000
      # T25/T26 control: service-year and month. Source reference: CNES/LT month totals.
      ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_SERV_CODE' '250750'
      AssertInteger 'T26_JP_SERV_YEAR_RD' 'Sum(P1_QTD_INTERNACAO)' $ref.ServJpYear
      AssertInteger 'T25_JP_SERV_YEAR_POP' 'Sum(P1_POPULACAO)' $ref.JpPop
      $sumBedYear=[decimal]0
      $missing=@()
      $bedRows=0
      foreach ($i in 1..12) {
        $month='2018'+('{0:D2}' -f $i)
        if (-not $ltByMonth.ContainsKey($month)) {
          $missing+= $month
          Write-Output ('MONTH='+$month+' LT_ROWS=ABSENT_ZERO_NOT_PROVEN COVERAGE=UNVERIFIED')
          continue
        }
        ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_SERV_CODE' '250750'; SelectQ 'P1_COMPETENCIA' $month
        AssertInteger ('T25_LT_'+$month+'_ROWS') 'Count(P1_LT_ID)' $ltByMonth[$month].Rows
        AssertInteger ('T25_LT_'+$month+'_QTD_SUS') 'Sum(P1_QTD_LEITOS_SUS)' $ltByMonth[$month].Sus
        $sumBedYear += $ltByMonth[$month].Sus
        $bedRows += 1
      }
      Write-Output ('LT_2018_JP_OBSERVED_MONTHS='+$bedRows+'/12')
      if ($missing.Count -gt 0) {Write-Output ('LT_2018_JP_MISSING_MONTHS='+($missing -join ','))}
      Write-Output 'LT_OBSERVED_ROWS_DO_NOT_ESTABLISH_HOSPITAL_SCOPE_OR_ZERO_COVERAGE=True'
      if ($bedRows -eq 12 -and $sumBedYear -gt 0) {
        $meanBed=$sumBedYear/[decimal]12
        ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_SERV_CODE' '250750'
        # Explicit safeguards: validated source month count, selected Qlik month count,
        # and selected Qlik yearly bed sum must ALL reconcile before denominator use.
        # Diagnostic ONLY: determine how the historical Avg(Aggr(...)) arrived at /13.
        # No verdict is based on the legacy expression, and we do not suppress zeros.
        foreach($probe in @(
          @{Name='LEGACY_AGGR_AVG';Expr=$bedAverageLegacy},
          @{Name='LEGACY_AGGR_NON_NULL_COUNT';Expr='Count(Aggr(Sum(P1_QTD_LEITOS_SUS),P1_COMPETENCIA))'},
          @{Name='DISTINCT_SELECTED_COMPETENCIAS';Expr='Count(DISTINCT P1_COMPETENCIA)'},
          @{Name='SELECTED_COMPETENCIAS';Expr="Concat(DISTINCT P1_COMPETENCIA, '|')"},
          @{Name='LEGACY_AGGR_BY_COMPETENCIA';Expr="Concat(Aggr(P1_COMPETENCIA & ':' & Sum(P1_QTD_LEITOS_SUS),P1_COMPETENCIA),' | ')"}
        )) {
          try { Write-Output ('T25_DIAG_' + $probe.Name + '=' + (EvalQ $probe.Expr)) }
          catch { Write-Output ('T25_DIAG_' + $probe.Name + '=ERROR_' + $_.Exception.Message) }
        }
        AssertInteger 'T25_JP_SERV_YEAR_OBSERVED_LT_MONTHS' 'Count(DISTINCT P1_COMPETENCIA)' 12
        AssertInteger 'T25_JP_SERV_YEAR_SUM_BEDS' 'Sum(P1_QTD_LEITOS_SUS)' $sumBedYear
        AssertRatio 'T25_JP_SERV_YEAR_BED_AVG_CANDIDATE' $bedAverage $sumBedYear 12 1
        AssertRatio 'T25_JP_SERV_YEAR_BEDS_PER_1000_CANDIDATE' ('1000*'+$bedAverage+'/Sum(P1_POPULACAO)') $sumBedYear ($ref.JpPop*12) 1000
        AssertRatio 'T26_JP_SERV_YEAR_RD_PER_BED_CANDIDATE' ('Sum(P1_QTD_INTERNACAO)/'+$bedAverage) ($ref.ServJpYear*12) $sumBedYear 1
      } else {
        Write-Output 'ANNUAL_BED_KPIS=NOT_EVALUATED_MISSING_MONTHLY_ROWS_OR_NONPOSITIVE_DENOMINATOR'
      }
      if ($ltByMonth.ContainsKey('201809')) {
        if ($ltByMonth['201809'].Sus -le 0) {Write-Output 'MONTH_201809_BED_KPIS=NOT_EVALUATED_NONPOSITIVE_DENOMINATOR'}
        if ($ltByMonth['201809'].Sus -gt 0) {
        ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_SERV_CODE' '250750'; SelectQ 'P1_COMPETENCIA' '201809'
        AssertInteger 'T26_JP_SERV_201809_RD' 'Sum(P1_QTD_INTERNACAO)' $ref.ServJpMonth
        AssertInteger 'T25_JP_SERV_201809_RECOVERED_POP' $popRecover $ref.JpPop
        AssertRatio 'T25_JP_SERV_201809_BEDS_PER_1000_PARTIAL' ('1000*Sum(P1_QTD_LEITOS_SUS)/'+$popRecover) $ltByMonth['201809'].Sus $ref.JpPop 1000
        AssertRatio 'T26_JP_SERV_201809_RD_PER_BED_PARTIAL' 'Sum(P1_QTD_INTERNACAO)/Sum(P1_QTD_LEITOS_SUS)' $ref.ServJpMonth $ltByMonth['201809'].Sus 1
        }
      } else {Write-Output 'MONTH_201809_BED_KPIS=NOT_EVALUATED_NO_LT_ROWS'}
      ResetQ
      if ($bedRows -eq 12 -and $sumBedYear -gt 0 -and $ltByMonth.ContainsKey('201809') -and $ltByMonth['201809'].Sus -gt 0) {
        Write-Output 'VI_P3_T24_T25_T26_SAMPLE=PASS_LOCAL_RESTRICTED_NUMERIC_CANDIDATE_ONLY'
        Write-Output 'T25_AGGR_LEGACY=REJECTED_UNDER_JP_2018_SAMPLE_PENDING_MECHANISM_CONFIRMATION'
        Write-Output 'T25_COUNT_DISTINCT_CANDIDATE=REQUIRES_PROVEN_COVERAGE_NO_AUTO_ZERO_IMPUTATION'
      } else {
        Write-Output 'VI_P3_T24_T25_T26_SAMPLE=PASS_OBSERVABLE_NUMERIC_CASES_ONLY_BED_COVERAGE_OR_DENOMINATOR_BLOCKED'
      }
      Write-Output 'CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED'
      Write-Output 'MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED'
      Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
      Write-Output 'F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY'
      Write-Output 'PRODUCTION_APPROVED=False'
      $candidateVerdict=$(if ($bedRows -eq 12 -and $sumBedYear -gt 0 -and $ltByMonth.ContainsKey('201809') -and $ltByMonth['201809'].Sus -gt 0) {'PASS_VI_P3_LOCAL_READONLY_SAMPLE_NUMERIC_CANDIDATES_RESTRICTED'} else {'PASS_VI_P3_PARTIAL_SAMPLES_BED_COVERAGE_BLOCKED'})
    } else {
      Write-Output 'QLIK_ASSOCIATION=NOT_RUN_USE_RUNQLIK'
      $candidateVerdict='PASS_HEADER_AND_HASH_INVENTORY_ONLY_NOT_VI_P3_COMPLETE'
    }
} catch {
    Write-Output ('VERDICT=BLOCKED_OR_INCONCLUSIVE_' + $_.Exception.Message)
    throw
} finally {
    if ($null -ne $doc) {try {$null=$doc.CloseDoc()}catch{}}
    if ($null -ne $before) {
      try {
        $after = @(Snapshot-Qvds)
        $after | Export-Csv -LiteralPath (Join-Path $work 'qvd_manifest_after.csv') -NoTypeInformation -Encoding UTF8
        $prior=ConvertTo-Json -InputObject $before -Depth 4 -Compress
        $later=ConvertTo-Json -InputObject $after -Depth 4 -Compress
        if ($prior -cne $later) {
          Write-Output 'ALL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=False'
          Write-Output 'VERDICT=BLOCKED_QVD_CHANGED'
          throw 'CRITICAL: QVD manifest changed; preserve all evidence and investigate. No automatic rollback.'
        } else {Write-Output 'ALL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True'}
      } catch {
        Write-Output ('VERDICT=BLOCKED_FINAL_QVD_MANIFEST_'+$_.Exception.Message)
        throw
      }
    }
    Write-Output ('EVIDENCE_DIR_FINAL=' + $work)
    if ($candidateVerdict -like 'PASS_*') {Write-Output ('VERDICT=' + $candidateVerdict)}
}
