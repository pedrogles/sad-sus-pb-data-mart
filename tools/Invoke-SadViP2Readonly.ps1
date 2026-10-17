# SAD VI-P2 — temporal/municipal denominator candidate, using verified VI-P1 QVS unchanged.
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
$work = Join-Path ([IO.Path]::GetTempPath()) ('SAD_VI_P2_READONLY_' + $stamp + '_' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -Path $work -ItemType Directory -ErrorAction Stop
Write-Output ('EVIDENCE_DIR=' + $work)
Write-Output ('PHASE=VI-P2 MODE=' + $(if ($RunQlik) {'DENOMINATOR_CANDIDATE_QVD_PLUS_QLIK_COM'} else {'QVD_HEADER_AND_HASH_ONLY'}))
Write-Output 'EXISTING_QVD_READ_ONLY=True'
Write-Output 'TRANSF_QVW_NOT_RELOADED=True'
Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
Write-Output 'PRODUCTION_APPROVED=False'
# VI-GOV: only committed tracked version of this runner + QVS may be executed.
$viRunnerRel='tools/Invoke-SadViP2Readonly.ps1'
$viQvsRel='TRANSFORMACAO/vi_p1_readonly.qvs'
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
    $scriptFile = Join-Path $repo 'TRANSFORMACAO\vi_p1_readonly.qvs'
    if (-not (Test-Path -LiteralPath $scriptFile -PathType Leaf)) {throw "Missing QVS alongside runner: $scriptFile"}
    $scriptText=[IO.File]::ReadAllText($scriptFile,[Text.Encoding]::UTF8)
    # Reject direct write/operational commands at the start of script lines.
    if ($scriptText -match '(?im)^\s*(STORE|BINARY|EXECUTE|SQL|DIRECT\s+QUERY)\b') {throw 'QVS contains forbidden data-write command'}
    if ($scriptText -notmatch '\[P1\] VERDICT=PASS_PHYSICAL_KEYS_AND_TEMPORARY_MODEL_NOT_FINAL') {throw 'QVS marker mismatch'}
    $qvsHash=(Get-FileHash -Algorithm SHA256 -LiteralPath $scriptFile).Hash
    Write-Output ('QVS_SHA256=' + $qvsHash)
    if ($qvsHash -cne '80E80770C59FBCC48142DA8E4CE6BF87D3CD6113FCACE977E0DACEA0CA78558B') {throw 'QVS differs from successful VI-P1 R2; fail closed'}

    if ($RunQlik) {
      foreach($pair in $inputs.GetEnumerator()) {
        $full=Join-Path $repo $pair.Value
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {throw "Missing required QVD: $full"}
        if ($full.Contains(']') -or $full.Contains("`n") -or $full.Contains("`r")) {throw 'Unsupported special character in QVD path'}
        $scriptText=$scriptText.Replace(('__'+$pair.Key+'__'),$full)
      }
      if ($scriptText -match '__[A-Z_]+__') {throw 'Unresolved QVD placeholder'}
      $qvw=Join-Path $work 'SAD_VI_P1_DISPOSABLE.qvw'
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

      # VI-P2: no official KPI or approved Set Analysis expressions are installed.
      # Evaluate candidate POP temporal escape ONLY against a contemporaneous year/role baseline.
      function EvalQ([string]$expression) { return [string]($doc.Evaluate($expression)) }
      function CheckQ([string]$case,[string]$expression,[string]$expected) {
        $actual=EvalQ $expression
        Write-Output ('CASE=' + $case + ' ACTUAL=' + $actual + ' EXPECTED=' + $expected)
        if ($actual.Trim() -cne $expected.Trim()) {throw "VI-P2 Qlik COM mismatch: $case"}
      }
      function ResetQ { $null=$doc.ClearAll() }
      function SelectQ([string]$field,[string]$value) {
        $f=$doc.GetField($field)
        if ($null -eq $f) {throw "Missing Qlik field: $field"}
        $null=$f.Select($value)
        CheckQ ('SELECT_'+$field+'_'+$value) ('GetSelectedCount('+ $field +')') '1'
      }
      function ToggleQ([string]$field,[string]$value) {
        $f=$doc.GetField($field)
        if ($null -eq $f) {throw "Missing Qlik field: $field"}
        $null=$f.ToggleSelect($value)
      }
      function PosPop([string]$label) {
        $v=(EvalQ 'Sum(P1_POPULACAO)').Trim()
        $num=0.0
        if (-not [double]::TryParse($v,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$num) -or $num -le 0) {
          throw "Missing/invalid positive POP baseline: $label '$v'"
        }
        Write-Host ('BASELINE=' + $label + ' POP=' + $v)
        return $v
      }
      $restore='Sum({$<P1_COMPETENCIA=>} P1_POPULACAO)'
      $restoreCount='Count({$<P1_COMPETENCIA=>} P1_POP_CODE)'
      $yearFromMonth='If(Left(Text(MinString(P1_COMPETENCIA)),4)=Left(Text(MaxString(P1_COMPETENCIA)),4),''SINGLE_YEAR'',''MULTI_YEAR'')'
      $singleMonthYearPop='Sum({$<P1_COMPETENCIA=,P1_ANO={$(=Left(Text(MinString(P1_COMPETENCIA)),4))}>} P1_POPULACAO)'

      # A: year-wide POP must not be multiplied or lost when a month is selected.
      ResetQ; SelectQ 'P1_ANO' '2018'
      CheckQ 'PB_2018_POP_TOTAL' 'Sum(P1_POPULACAO)' '3996496'
      $pbPop=PosPop 'PB_2018'
      SelectQ 'P1_COMPETENCIA' '201809'
      CheckQ 'PB_MONTH_RAW_POP_MISSING' 'Count(P1_POP_CODE)' '0'
      CheckQ 'PB_MONTH_CANDIDATE_RECOVERY' $restore $pbPop
      CheckQ 'PB_MONTH_CANDIDATE_ROWCOUNT' $restoreCount '223'

      # B: municipality-residence role and 1 vs 2 monthly selections, with annual POP kept once.
      ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_RES_CODE' '250750'
      CheckQ 'RES_2018_ROWCOUNT' 'Count(P1_POP_CODE)' '1'
      $resPop=PosPop 'RES_2018_JP'
      SelectQ 'P1_COMPETENCIA' '201809'
      CheckQ 'RES_MONTH_RAW_POP_MISSING' 'Count(P1_POP_CODE)' '0'
      CheckQ 'RES_MONTH_RECOVERY' $restore $resPop
      CheckQ 'RES_MONTH_ROWCOUNT' $restoreCount '1'
      ToggleQ 'P1_COMPETENCIA' '201808'
      CheckQ 'RES_TWO_MONTHS_SELECTED' 'GetSelectedCount(P1_COMPETENCIA)' '2'
      CheckQ 'RES_TWO_MONTHS_POP_ONCE' $restore $resPop
      CheckQ 'RES_TWO_MONTHS_ROWCOUNT' $restoreCount '1'

      # C: municipality-service role. Tests POP role match, not clinical bed coverage.
      ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_SERV_CODE' '250750'
      CheckQ 'SERV_2018_ROWCOUNT' 'Count(P1_POP_CODE)' '1'
      $servPop=PosPop 'SERV_2018_JP'
      if ($servPop -cne $resPop) {throw 'Same PB municipality/year produces different POP for RES and SERV roles'}
      SelectQ 'P1_COMPETENCIA' '201809'
      CheckQ 'SERV_MONTH_RAW_POP_MISSING' 'Count(P1_POP_CODE)' '0'
      CheckQ 'SERV_MONTH_RECOVERY' $restore $servPop
      CheckQ 'SERV_MONTH_ROWCOUNT' $restoreCount '1'

      # D: month-only (no explicit year) must establish an unambiguous year before recovery.
      ResetQ; SelectQ 'P1_COMPETENCIA' '201809'
      CheckQ 'MONTH_ONLY_NO_EXPLICIT_YEAR' 'GetSelectedCount(P1_ANO)' '0'
      CheckQ 'MONTH_ONLY_SINGLE_YEAR' $yearFromMonth 'SINGLE_YEAR'
      CheckQ 'MONTH_ONLY_NO_RAW_POP' 'Count(P1_POP_CODE)' '0'
      CheckQ 'MONTH_ONLY_YEAR_DERIVED_POP_CANDIDATE' $singleMonthYearPop $pbPop
      ToggleQ 'P1_COMPETENCIA' '201808'
      CheckQ 'MONTH_ONLY_TWO_MONTHS' 'GetSelectedCount(P1_COMPETENCIA)' '2'
      CheckQ 'MONTH_ONLY_TWO_MONTHS_SINGLE_YEAR' $yearFromMonth 'SINGLE_YEAR'
      CheckQ 'MONTH_ONLY_TWO_MONTHS_YEAR_DERIVED_POP' $singleMonthYearPop $pbPop

      # E: across years, the policy guard stops KPI evaluation rather than summing populations.
      ResetQ; SelectQ 'P1_COMPETENCIA' '201809'
      ToggleQ 'P1_COMPETENCIA' '201909'
      CheckQ 'MULTIYEAR_SELECTED_MONTH_COUNT' 'GetSelectedCount(P1_COMPETENCIA)' '2'
      CheckQ 'MULTIYEAR_GUARD' $yearFromMonth 'MULTI_YEAR'
      Write-Output 'MULTIYEAR_UNDIMENSIONED_KPI=BLOCKED_BY_POLICY_NO_POP_EVALUATION'

      # F: approved P5 B cases must be pre-emptively blocked, never calculated as general KPIs.
      ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_SERV_CODE' '250750'
      CheckQ 'P5_SERVICE_FILTER_BLOCKS_RES' "If(GetSelectedCount(P1_SERV_CODE)>0,'BLOCKED','ALLOW')" 'BLOCKED'
      ResetQ; SelectQ 'P1_ANO' '2018'; SelectQ 'P1_RES_CODE' '250750'
      CheckQ 'P5_RES_FILTER_BLOCKS_LEI_REL' "If(GetSelectedCount(P1_RES_CODE)>0,'BLOCKED','ALLOW')" 'BLOCKED'
      ResetQ
      Write-Output 'VI_P2_TEMPORAL_POP_CANDIDATE=PASS_LOCAL_RESTRICTED'
      Write-Output 'VI_P2_P5_B_GUARD_PROBES=PASS_RESTRICTED_NOT_UI_ENFORCEMENT'
      Write-Output 'MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED'
      Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
      Write-Output 'PRODUCTION_APPROVED=False'
      $candidateVerdict='PASS_VI_P2_LOCAL_READONLY_TEMPORAL_POP_CANDIDATE_RESTRICTED'
    } else {
      Write-Output 'QLIK_ASSOCIATION=NOT_RUN_USE_RUNQLIK'
      $candidateVerdict='PASS_HEADER_AND_HASH_INVENTORY_ONLY_NOT_VI_P2_COMPLETE'
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
