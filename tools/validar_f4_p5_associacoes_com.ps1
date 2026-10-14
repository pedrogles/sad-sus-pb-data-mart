# SAD SUS PB / F4-P5: observational COM probe of fact-exclusive filter associations.
# No physical filter contract, KPI approval, UI interception, Save, Reload or QVD writing.
# Only a copy of a disposable F4-P5 projection QVW may be opened and selected.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SourceQvw,
    [Parameter(Mandatory=$true)][string]$F4Dir
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$src = [IO.Path]::GetFullPath($SourceQvw)
$tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
if (-not $src.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($src) -cne 'F4_P5_SOURCE_PROJECTION_DISPOSABLE.qvw' -or
    [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($src)) -notmatch '^SAD_F4_P5_PROJECTION_[0-9a-f]{32}$') {
    throw 'BLOCKED_SOURCE_NOT_F4_P5_TEMP_DISPOSABLE'
}
$referenceDir = [IO.Path]::GetFullPath($F4Dir)
$csv = Join-Path $referenceDir 'F4_p5_filtros_isolados.csv'
$manifestPath = Join-Path $referenceDir 'manifest_F4.json'
foreach ($path in @($src,$csv,$manifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {throw "INPUT_NOT_FOUND=$path"}
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$expectedHash = [string]$manifest.output_sha256.'F4_p5_filtros_isolados.csv'
$actualHash = (Get-FileHash -LiteralPath $csv -Algorithm SHA256).Hash.ToLowerInvariant()
if ($expectedHash -cne $actualHash) {throw 'BLOCKED_F4_P5_REFERENCE_HASH_DRIFT'}
$cases = @(Import-Csv -LiteralPath $csv -Delimiter ';' -Encoding UTF8)
if ($cases.Count -ne 48) {throw 'BLOCKED_F4_P5_48_CASES_REQUIRED'}
# Mappings from confirmed physical staging/experimental QVW fields (not new dimensions).
$map = [ordered]@{
    'Ano analitico' = 'P6_ANO_ANO'
    'Competencia mensal' = 'P6_COMP_COMPETENCIA'
    'Municipio de residencia' = 'P6_RES_DATASUS_6'
    'Municipio de servico' = 'P6_SERV_DATASUS_6'
    'Estabelecimento CNES' = 'P6_EST_CNES'
    'Procedimento realizado PROC_REA' = 'F4_RD_PROC_REA'
    'Diagnostico principal DIAG_PRINC' = 'F4_RD_DIAG_PRINC'
    'Carater do atendimento' = 'F4_RD_CAR_INT'
    'Motivo de saida/permanencia' = 'F4_RD_COBRANCA'
    'Tipo/codigo de leito' = 'F4_LT_CODLEITO'
    'Data clinica de internacao' = 'F4_RD_DT_INTER'
    'Data clinica de saida' = 'F4_RD_DT_SAIDA'
}
$roles = @('RES','LEI','REL','FLU')
$caseKeys = @{}
foreach ($case in $cases) {
    $key = [string]$case.filtro + '|' + [string]$case.indicador
    if ($caseKeys.ContainsKey($key)) {throw "BLOCKED_DUPLICATE_P5_CASE=$key"}
    if (@('C','R','I','B') -cnotcontains ([string]$case.politica_p5)) {
        throw "BLOCKED_INVALID_P5_CODE=$key"
    }
    $caseKeys[$key] = [string]$case.politica_p5
}
foreach ($filter in $map.Keys) {
    foreach ($role in $roles) {
        $key = [string]$filter + '|' + $role
        if (-not $caseKeys.ContainsKey($key)) {throw "BLOCKED_MISSING_P5_CASE=$key"}
    }
}
# Two particularly risky exclusive filters, plus two role filters: fixed approved policies.
$policyGuards = @{
    'Procedimento realizado PROC_REA|RES' = 'R'
    'Procedimento realizado PROC_REA|LEI' = 'I'
    'Procedimento realizado PROC_REA|REL' = 'B'
    'Procedimento realizado PROC_REA|FLU' = 'R'
    'Tipo/codigo de leito|RES' = 'I'
    'Tipo/codigo de leito|LEI' = 'R'
    'Tipo/codigo de leito|REL' = 'B'
    'Tipo/codigo de leito|FLU' = 'I'
    'Municipio de residencia|RES' = 'C'
    'Municipio de residencia|LEI' = 'B'
    'Municipio de servico|RES' = 'B'
    'Municipio de servico|LEI' = 'C'
}
foreach ($key in $policyGuards.Keys) {
    if ($caseKeys[$key] -cne $policyGuards[$key]) {throw "BLOCKED_SEMANTIC_P5_DRIFT=$key"}
}

$sourceHash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
$dir = Join-Path ([IO.Path]::GetTempPath()) ('SAD_F4_P5_ASSOC_PROBE_'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dir -ErrorAction Stop | Out-Null
$copy = Join-Path $dir 'F4_P5_ASSOC_PROBE_DISPOSABLE.qvw'
Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
if ((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash) {
    throw 'BLOCKED_QVW_COPY_MISMATCH'
}

$qv = $null
$doc = $null
$failure = $null
function Evaluate([string]$expression) {
    return [string]($script:doc.Evaluate($expression))
}
function Check([string]$label,[string]$expression,[string]$expected) {
    $actual = Evaluate $expression
    if ($actual -cne $expected) {
        throw "BLOCKED_$label EXPECTED=$expected ACTUAL=$actual"
    }
}
function SelectValue([string]$fieldName,[string]$value) {
    $f = $null
    try {
        $f = $script:doc.GetField($fieldName)
        if ($null -eq $f) {throw "FIELD_NOT_FOUND=$fieldName"}
        $null = $f.Select($value)
    } finally {
        if ($null -ne $f -and [Runtime.InteropServices.Marshal]::IsComObject($f)) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($f)
        }
    }
}
function ResetCase {
    $null = $script:doc.ClearAll()
    foreach ($field in @('P6_ANO_ANO','P6_COMP_COMPETENCIA',
                         'P6_RES_DATASUS_6','P6_SERV_DATASUS_6',
                         'F4_RD_PROC_REA','F4_LT_CODLEITO')) {
        Check ('CLEAR_'+$field) ('GetSelectedCount('+ $field +')') '0'
    }
}
function Observe([string]$label) {
    $rdRows = Evaluate 'Count(F4_RD_IDENT)'
    $rdEligible = Evaluate 'Sum(F4_RD_QTD_INTERNACAO)'
    $ltRows = Evaluate 'Count(F4_LT_QT_SUS)'
    $ltSnapshots = Evaluate 'Sum(F4_LT_QT_SUS)'
    $popRows = Evaluate 'Count(P6_POP_ROW_DEBUG)'
    $popTotal = Evaluate 'Sum(P6_POP_HABITANTES_E5)'
    Write-Output ("OBS_$label RD_ROWS=$rdRows RD_ELIGIBLE=$rdEligible LT_ROWS=$ltRows LT_SNAPSHOT_SUM=$ltSnapshots POP_ROWS=$popRows POP_ANNUAL_COMPONENT_SUM=$popTotal")
}

try {
    Write-Output 'MODE=F4_P5_ASSOCIATIVE_COM_OBSERVATION_DISPOSABLE'
    Write-Output ('SOURCE_SHA256_BEFORE='+$sourceHash)
    Write-Output 'F4_P5_MATRIX_SHA256_PASS=True'
    Write-Output ('COPY_QVW='+$copy)
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    $doc = $qv.OpenDoc($copy,'','')
    if ($null -eq $doc) {throw 'BLOCKED_COM_OPENDOC_NULL'}
    ResetCase
    Check 'BASE_RD_ROWS' 'Count(F4_RD_IDENT)' '566672'
    Check 'BASE_RD_ELIGIBLE' 'Sum(F4_RD_QTD_INTERNACAO)' '555089'
    Check 'BASE_LT_ROWS' 'Count(F4_LT_QT_SUS)' '35518'
    Check 'BASE_LT_SNAPSHOT_SUM' 'Sum(F4_LT_QT_SUS)' '270076'
    Check 'BASE_POP_ROWS' 'Count(P6_POP_ROW_DEBUG)' '669'
    Check 'BASE_POP_SUM' 'Sum(P6_POP_HABITANTES_E5)' '12040181'
    Write-Output 'BASELINE_SOURCE_COUNTS=PASS_RESTRICTED'
    foreach ($entry in $map.GetEnumerator()) {
        $fieldName = [string]$entry.Value
        $f = $null
        try {
            $f = $doc.GetField($fieldName)
            if ($null -eq $f) {throw "P5_FIELD_NOT_FOUND=$fieldName"}
            $n = Evaluate ('Count(DISTINCT '+$fieldName+')')
            if (-not ($n -match '^[0-9]+$') -or [long]$n -le 0) {
                throw "P5_FIELD_HAS_NO_VALUES=$fieldName VALUE=$n"
            }
            Write-Output ("P5_FIELD_READY=$fieldName CATEGORY=$($entry.Key) DISTINCT=$n")
        } finally {
            if ($null -ne $f -and [Runtime.InteropServices.Marshal]::IsComObject($f)) {
                [void][Runtime.InteropServices.Marshal]::ReleaseComObject($f)
            }
        }
    }
    Write-Output 'P5_FIELD_MAP_12_OF_12=PASS_OBSERVATIONAL_ONLY'

    ResetCase
    SelectValue 'P6_ANO_ANO' '2018'
    Check 'YEAR2018_SELECTED' 'GetFieldSelections(P6_ANO_ANO)' '2018'
    Check 'YEAR2018_RD_ELIGIBLE' 'Sum(F4_RD_QTD_INTERNACAO)' '183311'
    Check 'YEAR2018_POP_COMPONENT' 'Sum(P6_POP_HABITANTES_E5)' '3996496'
    Observe 'YEAR_2018'

    ResetCase
    SelectValue 'P6_ANO_ANO' '2018'
    SelectValue 'P6_SERV_DATASUS_6' '250750'
    Check 'SERVICE_SELECTED' 'GetFieldSelections(P6_SERV_DATASUS_6)' '250750'
    Check 'SERVICE_YEAR_SELECTED' 'GetFieldSelections(P6_ANO_ANO)' '2018'
    Check 'SERVICE_POP_COMPONENT' 'Sum(P6_POP_HABITANTES_E5)' '800323'
    Observe 'YEAR2018_SERVICE250750'

    ResetCase
    SelectValue 'P6_ANO_ANO' '2018'
    SelectValue 'P6_SERV_DATASUS_6' '250750'
    SelectValue 'P6_RES_DATASUS_6' '250400'
    Check 'DUAL_SERVICE' 'GetFieldSelections(P6_SERV_DATASUS_6)' '250750'
    Check 'DUAL_RES' 'GetFieldSelections(P6_RES_DATASUS_6)' '250400'
    Check 'DUAL_YEAR' 'GetFieldSelections(P6_ANO_ANO)' '2018'
    Observe 'DUAL_ROLE_2018_DIFFERENT_MUNICIPALITIES'
    Write-Output 'DUAL_ROLE_COUNTS=OBSERVED_NOT_POP_DENOMINATOR_APPROVED'

    ResetCase
    $procedure = Evaluate 'MinString(F4_RD_PROC_REA)'
    if (-not $procedure) {throw 'PROCEDURE_SAMPLE_UNAVAILABLE'}
    Write-Output ('PROCEDURE_SELECTED_SAMPLE='+$procedure)
    SelectValue 'F4_RD_PROC_REA' $procedure
    Check 'PROCEDURE_SELECTED' 'GetSelectedCount(F4_RD_PROC_REA)' '1'
    Observe 'RD_PROCEDURE_EXCLUSIVE'
    Write-Output 'PROCEDURE_GENERAL_INDICATOR_P5=RESTRICT_OR_ISOLATE_OR_BLOCK_NOT_ENFORCED'

    ResetCase
    $bedCode = Evaluate 'MinString(F4_LT_CODLEITO)'
    if (-not $bedCode) {throw 'BED_CODE_SAMPLE_UNAVAILABLE'}
    Write-Output ('BED_CODE_SELECTED_SAMPLE='+$bedCode)
    SelectValue 'F4_LT_CODLEITO' $bedCode
    Check 'BED_SELECTED' 'GetSelectedCount(F4_LT_CODLEITO)' '1'
    Observe 'LT_BED_CODE_EXCLUSIVE'
    Write-Output 'BED_GENERAL_INDICATOR_P5=RESTRICT_OR_ISOLATE_OR_BLOCK_NOT_ENFORCED'
    Write-Output 'F4_P5_ASSOCIATIVE_SIX_SCENARIOS=OBSERVED_REQUIRES_SEMANTIC_REVIEW'
} catch {
    $failure = $_.Exception.Message
    Write-Output ('F4_P5_OBSERVATION=FAIL_CLOSED_'+$failure)
} finally {
    if ($null -ne $doc) {
        try { [void]$doc.CloseDoc() } catch { Write-Output ('QVW_CLOSE_WARNING='+$_.Exception.Message) }
        if ([Runtime.InteropServices.Marshal]::IsComObject($doc)) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc)
        }
    }
    if ($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
    }
    $after = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
    Write-Output ('SOURCE_SHA256_UNCHANGED='+($after -ceq $sourceHash))
    Write-Output 'SAVE_EXECUTED=False'
    Write-Output 'RELOAD_EXECUTED=False'
    Write-Output 'QVD_WRITES=0'
    Write-Output 'P5_POLICY_PHYSICAL_ENFORCEMENT=NOT_TESTED'
    Write-Output 'MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED'
    Write-Output ('TEMP_DIAGNOSTIC_DIR='+$dir)
    if ($after -cne $sourceHash) {$failure = 'SOURCE_QVW_CHANGED'}
}
if ($null -ne $failure) {
    Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$failure)
    exit 1
}
Write-Output 'FINAL_VERDICT=PASS_ASSOCIATIVE_OBSERVATION_ONLY_NOT_P5_COMPLIANCE'
