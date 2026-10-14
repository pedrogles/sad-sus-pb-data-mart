# SAD/SUS-PB F4 D2: guarded COM pre-dispatch selection experiment.
# This is a RESTRICTED proof of an external wrapper. It does NOT implement a
# QlikView user-interface hook, Set Analysis, physical indicator, facts, or QVDs.
# Runs on a disposable copy of an existing E5 experimental QVW. No Save/Reload.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SourceQvw,
    [Parameter(Mandatory=$true)][string]$F4Dir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath($SourceQvw)
$reference = [IO.Path]::GetFullPath($F4Dir)
$casesPath = Join-Path $reference 'F4_d2_cenarios_temporais.csv'
$manifestPath = Join-Path $reference 'manifest_F4.json'

foreach ($path in @($source, $casesPath, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "INPUT_MISSING=$path"
    }
}
if ([IO.Path]::GetFileName($source) -notmatch '^(P6_E5_POP_DENOMINATOR_IN_MEMORY|SAD_P6_E5_POP_SEMANTICS_COPY(?:_[0-9a-f]{32})?)\.qvw$') {
    throw 'BLOCKED_UNEXPECTED_QVW_SOURCE_NAME'
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$expectedCsvHash = [string]$manifest.output_sha256.'F4_d2_cenarios_temporais.csv'
$actualCsvHash = (Get-FileHash -LiteralPath $casesPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($expectedCsvHash -cne $actualCsvHash) {
    throw 'BLOCKED_F4_D2_REFERENCE_SHA256_MISMATCH'
}
$rows = @(Import-Csv -LiteralPath $casesPath -Delimiter ';' -Encoding UTF8)
if ($rows.Count -ne 13) { throw 'BLOCKED_F4_D2_REFERENCE_COUNT' }
$known = @{
    'ANO_2019_PROPOR_MES_201809' = 'PREVENT_CONFLICT_BEFORE_SELECTION'
    'MES_201809_PROPOR_ANO_2019' = 'PREVENT_CONFLICT_BEFORE_SELECTION'
    'ANO_2019_PROPOR_MES_201909' = 'PARTIAL_MONTHS_EXPLICIT_ANNUAL_POP_REFERENCE'
    'MES_201809_PROPOR_ANO_2018' = 'PARTIAL_MONTHS_EXPLICIT_ANNUAL_POP_REFERENCE'
}
$selected = @{}
foreach ($row in $rows) {
    if ($selected.ContainsKey([string]$row.caso)) {
        throw "BLOCKED_DUPLICATE_F4_CASE=$($row.caso)"
    }
    $selected[[string]$row.caso] = $row
}
foreach ($name in $known.Keys) {
    if (-not $selected.ContainsKey($name) -or
        [string]$selected[$name].resultado_esperado -cne $known[$name]) {
        throw "BLOCKED_F4_REFERENCE_CHANGED=$name"
    }
}

$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$dir = Join-Path ([IO.Path]::GetTempPath()) ('SAD_F4_D2_COM_'+[Guid]::NewGuid().ToString('N'))
New-Item -Path $dir -ItemType Directory -ErrorAction Stop | Out-Null
$copy = Join-Path $dir 'P6_F4_D2_DISPOSABLE.qvw'
Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
if ((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash) {
    throw 'BLOCKED_DISPOSABLE_COPY_HASH'
}

$qv = $null
$doc = $null
$failure = $null
function Value([string]$expression) {
    return [string]($script:doc.Evaluate($expression))
}
function AssertValue([string]$name,[string]$expr,[string]$expected) {
    $actual = Value $expr
    if ($actual -cne $expected) {
        throw "BLOCKED_$name EXPECTED=$expected ACTUAL=$actual"
    }
}
function SelectOne([string]$name,[string]$selectedValue) {
    $field = $null
    try {
        $field = $script:doc.GetField($name)
        if ($null -eq $field) {throw "FIELD_NOT_FOUND=$name"}
        $null = $field.Select($selectedValue)
    } finally {
        if ($null -ne $field -and [Runtime.InteropServices.Marshal]::IsComObject($field)) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($field)
        }
    }
}
function ResetScenario {
    $null = $script:doc.ClearAll()
    AssertValue 'RESET_YEAR' 'GetSelectedCount(P6_ANO_ANO)' '0'
    AssertValue 'RESET_MONTH' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '0'
}
# Decision is evaluated on the PREVIOUS state, before the proposal can be sent
# to COM. It deliberately accepts ONLY one selected year/month for this gate.
function Guard([string]$kind,[string]$proposed) {
    $ny = Value 'GetSelectedCount(P6_ANO_ANO)'
    $nm = Value 'GetSelectedCount(P6_COMP_COMPETENCIA)'
    if ($ny -notin @('0','1') -or $nm -notin @('0','1')) {
        throw 'BLOCKED_MULTI_SELECTION_OUTSIDE_F4_D2_GATE'
    }
    $oldYear = if ($ny -ceq '1') { Value 'GetFieldSelections(P6_ANO_ANO)' } else { '' }
    $oldMonth = if ($nm -ceq '1') { Value 'GetFieldSelections(P6_COMP_COMPETENCIA)' } else { '' }
    if ($kind -ceq 'ANO') {
        if ($proposed -notmatch '^20(17|18|19)$') { throw 'INVALID_PROPOSED_YEAR' }
        if ($oldMonth -and -not $oldMonth.StartsWith($proposed)) {
            return 'PREVENT_CONFLICT_BEFORE_SELECTION'
        }
        if ($oldYear -and $oldYear -cne $proposed) {
            return 'PREVENT_CONFLICT_BEFORE_SELECTION'
        }
        return 'ALLOW'
    }
    if ($kind -ceq 'COMPETENCIA') {
        if ($proposed -notmatch '^20(17|18|19)(0[1-9]|1[0-2])$') {
            throw 'INVALID_PROPOSED_MONTH'
        }
        if ($oldYear -and $oldYear -cne $proposed.Substring(0,4)) {
            return 'PREVENT_CONFLICT_BEFORE_SELECTION'
        }
        if ($oldMonth -and $oldMonth -cne $proposed) {
            throw 'MONTH_CHANGE_NOT_UNDER_TEST'
        }
        return 'ALLOW'
    }
    throw 'INVALID_PROPOSAL_KIND'
}
try {
    Write-Output 'MODE=F4_D2_GUARDED_COM_PRESELECTION_DISPOSABLE'
    Write-Output ('SOURCE_SHA256_BEFORE='+$sourceHash)
    Write-Output 'REFERENCE_HASH_PASS=True'
    Write-Output ('DISPOSABLE_QVW='+$copy)
    $qv = New-Object -ComObject 'QlikTech.QlikView'
    $doc = $qv.OpenDoc($copy,'','')
    if ($null -eq $doc) {throw 'COM_OPEN_DOC_NULL'}
    ResetScenario
    AssertValue 'BASELINE_POP_ROWS' 'Count(P6_POP_ROW_DEBUG)' '669'
    AssertValue 'BASELINE_POP_SUM' 'Sum(P6_POP_HABITANTES_E5)' '12040181'
    foreach ($name in @(
        'ANO_2019_PROPOR_MES_201809',
        'MES_201809_PROPOR_ANO_2019',
        'ANO_2019_PROPOR_MES_201909',
        'MES_201809_PROPOR_ANO_2018'
    )) {
        $row = $selected[$name]
        ResetScenario
        SelectOne 'P6_SERV_DATASUS_6' '250750'
        if ($row.anos_anteriores) {
            SelectOne 'P6_ANO_ANO' ([string]$row.anos_anteriores)
        }
        if ($row.competencias_anteriores) {
            SelectOne 'P6_COMP_COMPETENCIA' ([string]$row.competencias_anteriores)
        }
        $beforeYear = Value 'GetFieldSelections(P6_ANO_ANO)'
        $beforeMonth = Value 'GetFieldSelections(P6_COMP_COMPETENCIA)'
        $beforeYearCount = Value 'GetSelectedCount(P6_ANO_ANO)'
        $beforeMonthCount = Value 'GetSelectedCount(P6_COMP_COMPETENCIA)'
        $decision = Guard ([string]$row.proposta_tipo) ([string]$row.proposta_valor)
        $expectedDecision = if ($row.resultado_esperado -ceq 'PREVENT_CONFLICT_BEFORE_SELECTION') {
            'PREVENT_CONFLICT_BEFORE_SELECTION'
        } else { 'ALLOW' }
        if ($decision -cne $expectedDecision) {
            throw "GUARD_DISAGREES_WITH_F4_CASE=$name"
        }
        $dispatched = $false
        if ($decision -ceq 'ALLOW') {
            $field = if ($row.proposta_tipo -ceq 'ANO') { 'P6_ANO_ANO' } else { 'P6_COMP_COMPETENCIA' }
            SelectOne $field ([string]$row.proposta_valor)
            $dispatched = $true
            AssertValue 'ALLOWED_YEAR_COUNT' 'GetSelectedCount(P6_ANO_ANO)' '1'
            AssertValue 'ALLOWED_MONTH_COUNT' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '1'
            AssertValue 'ALLOWED_YEAR_VALUE' 'GetFieldSelections(P6_ANO_ANO)' ([string]$row.proposta_valor.Substring(0,4))
            $populationExpected = if ($name -ceq 'ANO_2019_PROPOR_MES_201909') {'809015'} else {'800323'}
            $e10='If(GetSelectedCount(P6_COMP_COMPETENCIA)>0 and Left(Text(MinString(P6_COMP_COMPETENCIA)),4)=Left(Text(MaxString(P6_COMP_COMPETENCIA)),4),Sum({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={$(=Left(Text(MinString(P6_COMP_COMPETENCIA)),4))}>} P6_POP_HABITANTES_E5),''SEM_ANO_UNICO'')'
            AssertValue 'ALLOWED_POP_REFERENCE' $e10 $populationExpected
        } else {
            AssertValue 'GUARD_YEAR_COUNT_PRESERVED' 'GetSelectedCount(P6_ANO_ANO)' $beforeYearCount
            AssertValue 'GUARD_MONTH_COUNT_PRESERVED' 'GetSelectedCount(P6_COMP_COMPETENCIA)' $beforeMonthCount
            AssertValue 'GUARD_YEAR_VALUES_PRESERVED' 'GetFieldSelections(P6_ANO_ANO)' $beforeYear
            AssertValue 'GUARD_MONTH_VALUES_PRESERVED' 'GetFieldSelections(P6_COMP_COMPETENCIA)' $beforeMonth
        }
        AssertValue 'SERVICE_ROLE_PRESERVED' 'GetFieldSelections(P6_SERV_DATASUS_6)' '250750'
        Write-Output ("F4_D2_$name=$decision DISPATCHED=$dispatched")
    }
    Write-Output 'F4_D2_FOUR_CASES=PASS_RESTRICTED_WRAPPER_ONLY'
} catch {
    $failure = $_.Exception.Message
    Write-Output ('F4_D2_GATE=FAIL_CLOSED_'+$failure)
} finally {
    if ($null -ne $doc) {
        try { [void]$doc.CloseDoc() } catch { Write-Output ('CLOSE_WARNING='+$_.Exception.Message) }
        if ([Runtime.InteropServices.Marshal]::IsComObject($doc)) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc)
        }
    }
    if ($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
    }
    $afterHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    Write-Output ('SOURCE_SHA256_UNCHANGED='+($afterHash -ceq $sourceHash))
    Write-Output 'SAVE_EXECUTED=False'
    Write-Output 'RELOAD_EXECUTED=False'
    Write-Output 'QVD_WRITES=0'
    Write-Output 'F4_P5_PHYSICAL_FILTERS=NOT_TESTED'
    Write-Output 'UI_INTERCEPTION=NOT_IMPLEMENTED'
    Write-Output ('TEMP_DIAGNOSTIC_DIR='+$dir)
    if ($afterHash -cne $sourceHash) {$failure='SOURCE_QVW_CHANGED'}
}
if ($null -ne $failure) {
    Write-Output ('VERDICT=FAIL_CLOSED_'+$failure)
    exit 1
}
Write-Output 'VERDICT=PASS_F4_D2_WRAPPER_PREDISPATCH_ONLY_PHYSICAL_CONTRACT_NOT_APPROVED'
