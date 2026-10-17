# SAD VI-P1 — physical QVD inventory and OPTIONAL isolated QlikView 12 preflight.
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
$work = Join-Path ([IO.Path]::GetTempPath()) ('SAD_VI_P1_READONLY_' + $stamp + '_' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -Path $work -ItemType Directory -ErrorAction Stop
Write-Output ('EVIDENCE_DIR=' + $work)
Write-Output ('PHASE=VI-P1 MODE=' + $(if ($RunQlik) {'PHYSICAL_QVD_PLUS_QLIK_COM'} else {'QVD_HEADER_AND_HASH_ONLY'}))
Write-Output 'EXISTING_QVD_READ_ONLY=True'
Write-Output 'TRANSF_QVW_NOT_RELOADED=True'
Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
Write-Output 'PRODUCTION_APPROVED=False'
# VI-GOV: only committed tracked version of this runner + QVS may be executed.
$viRunnerRel='tools/Invoke-SadViP1Readonly.ps1'
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

      function EvalQ([string]$expression) { return [string]($doc.Evaluate($expression)) }
      function RequireQ([string]$label,[string]$expression,[string]$expected) {
        $actual=EvalQ $expression
        Write-Output ("CASE=$label EXPR=$expression ACTUAL=$actual EXPECTED=$expected")
        if ($actual.Trim() -cne $expected) {throw "Qlik COM mismatch: $label got '$actual' expected '$expected'"}
      }
      function SelectQ([string]$field,[string]$value) {
        $f=$doc.GetField($field)
        if ($null -eq $f) {throw "Qlik field unavailable: $field"}
        $null=$f.Select($value)
        RequireQ ('SELECT_'+$field) ('GetSelectedCount('+ $field +')') '1'
      }
      $null=$doc.ClearAll()
      SelectQ 'P1_ANO' '2018'
      RequireQ 'YEAR_2018_POP_ROWS' 'Count(P1_POP_CODE)' '223'
      RequireQ 'YEAR_2018_POP_TOTAL' 'Sum(P1_POPULACAO)' '3996496'
      RequireQ 'YEAR_2018_RD_NEW' 'Sum(P1_QTD_INTERNACAO)' '183311'
      $null=$doc.ClearAll()
      SelectQ 'P1_ANO' '2018'
      SelectQ 'P1_SERV_CODE' '250750'
      RequireQ 'YEAR_SERVICE_POP_ROW' 'Count(P1_POP_CODE)' '1'
      $null=$doc.ClearAll()
      SelectQ 'P1_ANO' '2018'
      SelectQ 'P1_RES_CODE' '250750'
      RequireQ 'YEAR_RESIDENCE_POP_ROW' 'Count(P1_POP_CODE)' '1'
      $null=$doc.ClearAll()
      SelectQ 'P1_ANO' '2018'
      SelectQ 'P1_COMPETENCIA' '201809'
      RequireQ 'MONTH_POP_EXCLUSION' 'Count(P1_POP_CODE)' '0'
      Write-Output 'MONTHLY_POPULATION_DIRECT_ASSOCIATION=EXCLUDED_BY_NULL_COMPETENCE_GUARD_REQUIRED'
      $null=$doc.ClearAll()
      Write-Output 'COM_REFERENCE_SELECTIONS=PASS_RESTRICTED'
      $candidateVerdict='PASS_VI_P1_LOCAL_READONLY_PREFLIGHT_RESTRICTED_WITH_MONTHLY_DENOMINATOR_BLOCKER'
      Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED'
    } else {
      Write-Output 'QLIK_ASSOCIATION=NOT_RUN_USE_RUNQLIK'
      $candidateVerdict='PASS_HEADER_AND_HASH_INVENTORY_ONLY_NOT_VI_P1_COMPLETE'
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
