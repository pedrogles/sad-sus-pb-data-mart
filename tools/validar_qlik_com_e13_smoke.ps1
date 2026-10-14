# SAD / Phase VI E13: first COM selection/evaluation smoke on disposable copy.
# Not production: no Save, Reload, QVD writes, changes to source QVW or repository.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SourceQvw,
    [switch]$TemporalDiscovery,
    [switch]$AnnualRoleDiscovery,
    [switch]$GeographicDiscovery,
    [switch]$CrossRoleDiscovery,
    [string]$OtherMunicipality = '250400'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$src=[IO.Path]::GetFullPath($SourceQvw)
if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {throw "SOURCE_QVW_NOT_FOUND=$src"}
if ([IO.Path]::GetFileName($src) -notmatch '^(P6_E5_POP_DENOMINATOR_IN_MEMORY|SAD_P6_E5_POP_SEMANTICS_COPY(?:_[0-9a-f]{32})?)\.qvw$') {
    throw 'BLOCKED_UNEXPECTED_E5_SOURCE_NAME'
}
$srcHash=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
$dir=Join-Path ([IO.Path]::GetTempPath()) ('SAD_P6_E13_COM_'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dir -ErrorAction Stop | Out-Null
$copy=Join-Path $dir 'P6_E13_DISPOSABLE.qvw'
Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
if ((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $srcHash) {throw 'BLOCKED_COPY_HASH_MISMATCH'}
$qv=$null
$doc=$null
$failure=$null
# Formula E10 identical to the previously tested text object. Use single-quoted PS text to preserve dollar expansion.
$e10='If(GetSelectedCount(P6_COMP_COMPETENCIA)>0 and Left(Text(MinString(P6_COMP_COMPETENCIA)),4)=Left(Text(MaxString(P6_COMP_COMPETENCIA)),4),Sum({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={$(=Left(Text(MinString(P6_COMP_COMPETENCIA)),4))}>} P6_POP_HABITANTES_E5),''SEM_ANO_UNICO'')'
function CheckValue([string]$label,[string]$expression,[string]$expected) {
    $actual=[string]($script:doc.Evaluate($expression))
    Write-Output ("E13_"+$label+"="+$actual)
    if ($actual -cne $expected) {
        throw ("BLOCKED_"+$label+"_EXPECTED_"+$expected+"_GOT_"+$actual)
    }
}
function SelectValue([string]$fieldName,[string]$value,[bool]$toggle=$false) {
    $f=$null
    try {
        $f=$script:doc.GetField($fieldName)
        if ($null -eq $f) {throw "BLOCKED_FIELD_MISSING=$fieldName"}
        if ($toggle) {
            $null=$f.ToggleSelect($value)
        } else {
            $null=$f.Select($value)
        }
    } finally {
        if ($null -ne $f -and [Runtime.InteropServices.Marshal]::IsComObject($f)) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($f)
        }
    }
}
function ResetCase {
    $null=$script:doc.ClearAll()
    CheckValue 'CLEAR_MONTH' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '0'
    CheckValue 'CLEAR_YEAR' 'GetSelectedCount(P6_ANO_ANO)' '0'
    CheckValue 'CLEAR_SERVICE' 'GetSelectedCount(P6_SERV_DATASUS_6)' '0'
    CheckValue 'CLEAR_RES' 'GetSelectedCount(P6_RES_DATASUS_6)' '0'
}
try {
    Write-Output 'MODE=E13_COM_REGRESSION_SMOKE_DISPOSABLE'
    Write-Output ('SOURCE_SHA256_BEFORE='+$srcHash)
    Write-Output ('DISPOSABLE_COPY='+$copy)
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $doc=$qv.OpenDoc($copy,'','')
    if ($null -eq $doc) {throw 'BLOCKED_COM_OPENDOC_NULL'}
    # COM GetTableCount (12 previously) differs from NoOfTables() at reload (9); capture names, do not reinterpret topology.
    try {
        $n=[int]$doc.GetTableCount()
        Write-Output ('E13_COM_TABLE_COUNT='+$n)
        for($i=0;$i -lt $n;$i++) {
            try {Write-Output ('E13_COM_TABLE_'+$i+'='+[string]($doc.GetTableName($i)))}
            catch {Write-Output ('E13_COM_TABLE_NAME_ERROR_'+$i+'='+$_.Exception.Message)}
        }
    } catch {Write-Output ('E13_TABLE_ENUMERATION_UNAVAILABLE='+$_.Exception.Message)}
    # Diagnostic: an on-disk QVW can reopen with selections; gather facts before touching state.
    # Keep the original baseline guard but diagnose each input separately.
    $diagnostics = @(
        @{Name='PRE_CLEAR_COMP_COUNT';Expr='GetSelectedCount(P6_COMP_COMPETENCIA)'},
        @{Name='PRE_CLEAR_YEAR_COUNT';Expr='GetSelectedCount(P6_ANO_ANO)'},
        @{Name='PRE_CLEAR_SERVICE_COUNT';Expr='GetSelectedCount(P6_SERV_DATASUS_6)'},
        @{Name='PRE_CLEAR_RES_COUNT';Expr='GetSelectedCount(P6_RES_DATASUS_6)'}
    )
    foreach ($item in $diagnostics) {
        try { Write-Output ('E13_DIAG_'+$item.Name+'='+[string]($doc.Evaluate($item.Expr))) }
        catch { Write-Output ('E13_DIAG_'+$item.Name+'_ERROR='+$_.Exception.Message) }
    }
    # Clear selections in DISPOSABLE copy before baseline, then verify clear occurred.
    ResetCase
    foreach ($item in @(
        @{Name='POST_CLEAR_POP_COUNT';Expr='Count(P6_POP_ROW_DEBUG)'},
        @{Name='POST_CLEAR_POP_HABITANTES';Expr='Sum(P6_POP_HABITANTES_E5)'},
        @{Name='POST_CLEAR_COUNT_MATCH';Expr='Count(P6_POP_ROW_DEBUG)=669'},
        @{Name='POST_CLEAR_SUM_MATCH';Expr='Sum(P6_POP_HABITANTES_E5)=12040181'},
        @{Name='POST_CLEAR_AND_MATCH';Expr='(Count(P6_POP_ROW_DEBUG)=669) and (Sum(P6_POP_HABITANTES_E5)=12040181)'},
        @{Name='POST_CLEAR_IF';Expr="If(Count(P6_POP_ROW_DEBUG)=669 and Sum(P6_POP_HABITANTES_E5)=12040181,'PASS','FAIL')"}
    )) {
        try { Write-Output ('E13_DIAG_'+$item.Name+'='+[string]($doc.Evaluate($item.Expr))) }
        catch { Write-Output ('E13_DIAG_'+$item.Name+'_ERROR='+$_.Exception.Message) }
    }
    # Strict unchanged baseline gate: no selection scenario is permitted if it fails.
    CheckValue 'BASELINE' "If(Count(P6_POP_ROW_DEBUG)=669 and Sum(P6_POP_HABITANTES_E5)=12040181,'PASS','FAIL')" 'PASS'
    # A: Single selected competence: 201809 -> JP 2018.
    ResetCase
    SelectValue 'P6_SERV_DATASUS_6' '250750'
    SelectValue 'P6_COMP_COMPETENCIA' '201809'
    CheckValue 'SINGLE_MONTH_COUNT' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '1'
    CheckValue 'SINGLE_YEAR_COUNT' 'GetSelectedCount(P6_ANO_ANO)' '0'
    CheckValue 'SINGLE_E10' $e10 '800323'
    Write-Output 'E13_SINGLE_MONTH=PASS'
    # B: Two selected competences in same year, annual population must not double.
    ResetCase
    SelectValue 'P6_SERV_DATASUS_6' '250750'
    SelectValue 'P6_COMP_COMPETENCIA' '201808'
    SelectValue 'P6_COMP_COMPETENCIA' '201809' $true
    CheckValue 'SAME_YEAR_MONTH_COUNT' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '2'
    CheckValue 'SAME_YEAR_YEAR_COUNT' 'GetSelectedCount(P6_ANO_ANO)' '0'
    CheckValue 'SAME_YEAR_E10' $e10 '800323'
    Write-Output 'E13_SAME_YEAR=PASS'
    # C: Two different years must reject denominator.
    ResetCase
    SelectValue 'P6_SERV_DATASUS_6' '250750'
    SelectValue 'P6_COMP_COMPETENCIA' '201809'
    SelectValue 'P6_COMP_COMPETENCIA' '201909' $true
    CheckValue 'CROSS_YEAR_MONTH_COUNT' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '2'
    CheckValue 'CROSS_YEAR_E10' $e10 'SEM_ANO_UNICO'
    Write-Output 'E13_CROSS_YEAR=PASS'

    # E14: optional, diagnostic-only temporal selection matrix.
    # These are observation cases; they do NOT approve a denominator contract.
    if ($TemporalDiscovery) {
        Write-Output 'E14_TEMPORAL_DISCOVERY=STARTED'
        # No explicit month or year: the E10 candidate has no uniquely defined annual reference.
        ResetCase
        CheckValue 'E14_NO_COMP_COUNT' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '0'
        CheckValue 'E14_NO_COMP_E10' $e10 'SEM_ANO_UNICO'
        Write-Output 'E14_NO_COMP=BEHAVIOR_OBSERVED_NOT_CONTRACT'
        # Only a year is selected; E10 was designed for month-derived annual selection.
        ResetCase
        SelectValue 'P6_SERV_DATASUS_6' '250750'
        SelectValue 'P6_ANO_ANO' '2018'
        CheckValue 'E14_YEAR_ONLY_YEAR_COUNT' 'GetSelectedCount(P6_ANO_ANO)' '1'
        CheckValue 'E14_YEAR_ONLY_COMP_COUNT' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '0'
        $yearOnly=[string]($doc.Evaluate($e10))
        Write-Output ('E14_YEAR_ONLY_E10=' + $yearOnly)
        Write-Output 'E14_YEAR_ONLY=BEHAVIOR_OBSERVED_NOT_CONTRACT'
        # Explicitly consistent year+month: observed behavior must match IBGE reference.
        ResetCase
        SelectValue 'P6_SERV_DATASUS_6' '250750'
        SelectValue 'P6_ANO_ANO' '2018'
        SelectValue 'P6_COMP_COMPETENCIA' '201809'
        CheckValue 'E14_COMPAT_YEAR_COUNT' 'GetSelectedCount(P6_ANO_ANO)' '1'
        CheckValue 'E14_COMPAT_COMP_COUNT' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '1'
        CheckValue 'E14_COMPAT_E10' $e10 '800323'
        Write-Output 'E14_COMPATIBLE_EXPLICIT_YEAR=PASS_RESTRICTED'
        # Conflicting year+month: Qlik may reject a selection or change associative state.
        # Capture outcomes without treating any of them as an approved denominator.
        ResetCase
        SelectValue 'P6_SERV_DATASUS_6' '250750'
        SelectValue 'P6_ANO_ANO' '2019'
        Write-Output ('E14_CONFLICT_PRE_MONTH_SELECTED_YEAR=' + [string]($doc.Evaluate('GetSelectedCount(P6_ANO_ANO)')))
        SelectValue 'P6_COMP_COMPETENCIA' '201809'
        foreach ($case in @(
            @{Label='CONFLICT_YEAR_COUNT';Expression='GetSelectedCount(P6_ANO_ANO)'},
            @{Label='CONFLICT_YEAR_VALUES';Expression='GetFieldSelections(P6_ANO_ANO)'},
            @{Label='CONFLICT_COMP_COUNT';Expression='GetSelectedCount(P6_COMP_COMPETENCIA)'},
            @{Label='CONFLICT_COMP_VALUES';Expression='GetFieldSelections(P6_COMP_COMPETENCIA)'},
            @{Label='CONFLICT_SERV_COUNT';Expression='GetSelectedCount(P6_SERV_DATASUS_6)'}
        )) {
            $result = [string]($doc.Evaluate($case.Expression))
            Write-Output ('E14_' + $case.Label + '=' + $result)
        }
        $conflictValue=[string]($doc.Evaluate($e10))
        Write-Output ('E14_CONFLICT_E10=' + $conflictValue)
        $yearCountAfterConflict = [string]($doc.Evaluate('GetSelectedCount(P6_ANO_ANO)'))
        if ($yearCountAfterConflict -ceq '0' -and $conflictValue -ceq '800323') {
            Write-Output 'E14_CONFLICT_SAFETY=ORIGINAL_2019_SELECTION_DROPPED_NOT_APPROVED'
        } else {
            Write-Output 'E14_CONFLICT_SAFETY=UNCLASSIFIED_PENDING_REVIEW'
        }
        Write-Output 'E14_YEAR_MONTH_CONFLICT=OBSERVED_NOT_APPROVED'
        Write-Output 'E14_TEMPORAL_DISCOVERY=OBSERVED_PENDING_SEMANTIC_REVIEW'
        # E15: reverse temporal selection order (month 201809, then explicit year 2019).
        # Diagnostic ONLY. Selection may clear an earlier incompatible selection.
        # No expectation for COM-selected values or denominator until physical run.
        ResetCase
        SelectValue 'P6_SERV_DATASUS_6' '250750'
        SelectValue 'P6_COMP_COMPETENCIA' '201809'
        CheckValue 'E15_PRE_YEAR_COMP_COUNT' 'GetSelectedCount(P6_COMP_COMPETENCIA)' '1'
        Write-Output ('E15_PRE_YEAR_COMP_VALUES=' + [string]($doc.Evaluate('GetFieldSelections(P6_COMP_COMPETENCIA)')))
        SelectValue 'P6_ANO_ANO' '2019'
        foreach ($case in @(
            @{Label='YEAR_COUNT';Expression='GetSelectedCount(P6_ANO_ANO)'},
            @{Label='YEAR_VALUES';Expression='GetFieldSelections(P6_ANO_ANO)'},
            @{Label='COMP_COUNT';Expression='GetSelectedCount(P6_COMP_COMPETENCIA)'},
            @{Label='COMP_VALUES';Expression='GetFieldSelections(P6_COMP_COMPETENCIA)'},
            @{Label='SERV_COUNT';Expression='GetSelectedCount(P6_SERV_DATASUS_6)'}
        )) {
            $value = [string]($doc.Evaluate($case.Expression))
            Write-Output ('E15_REVERSE_' + $case.Label + '=' + $value)
        }
        Write-Output ('E15_REVERSE_E10=' + [string]($doc.Evaluate($e10)))

        Write-Output 'E15_REVERSE_ORDER=OBSERVED_NOT_APPROVED'
    }
    # E16: annual-only population by municipality role. Observation, not approval.
    # Do not assume annual population sums are suitable for every analytical measure.
    if ($AnnualRoleDiscovery) {
        Write-Output 'E16_ANNUAL_ROLE_DISCOVERY=STARTED'
        $annualCandidate = 'Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5)'
        foreach ($role in @('P6_SERV_DATASUS_6','P6_RES_DATASUS_6')) {
            $roleLabel = if ($role -ceq 'P6_SERV_DATASUS_6') { 'SERV' } else { 'RES' }
            foreach ($year in @('2018','2019')) {
                ResetCase
                SelectValue $role '250750'
                SelectValue 'P6_ANO_ANO' $year
                CheckValue ('E16_'+$roleLabel+'_'+$year+'_YEAR_COUNT') 'GetSelectedCount(P6_ANO_ANO)' '1'
                CheckValue ('E16_'+$roleLabel+'_'+$year+'_MONTH_COUNT') 'GetSelectedCount(P6_COMP_COMPETENCIA)' '0'
                CheckValue ('E16_'+$roleLabel+'_'+$year+'_ROLE_COUNT') ('GetSelectedCount('+ $role +')') '1'
                Write-Output ('E16_'+$roleLabel+'_'+$year+'_COUNT_POP=' + [string]($doc.Evaluate('Count(P6_POP_ROW_DEBUG)')))
                Write-Output ('E16_'+$roleLabel+'_'+$year+'_NORMAL_POP=' + [string]($doc.Evaluate('Sum(P6_POP_HABITANTES_E5)')))
                Write-Output ('E16_'+$roleLabel+'_'+$year+'_ANNUAL_POP=' + [string]($doc.Evaluate($annualCandidate)))
                Write-Output ('E16_'+$roleLabel+'_'+$year+'_E10=' + [string]($doc.Evaluate($e10)))
                Write-Output ('E16_'+$roleLabel+'_'+$year+'=OBSERVED_NOT_APPROVED')
            }
        }
        Write-Output 'E16_ANNUAL_ROLE_DISCOVERY=OBSERVED_PENDING_SEMANTIC_REVIEW'

    }
    # E17: role/competence association, diagnostic only. No declared output is a measure contract.
    if ($GeographicDiscovery) {
        Write-Output 'E17_GEOGRAPHIC_DISCOVERY=STARTED'
        foreach ($role in @('P6_SERV_DATASUS_6','P6_RES_DATASUS_6')) {
            $roleLabel = if ($role -ceq 'P6_SERV_DATASUS_6') {'SERV'} else {'RES'}
            ResetCase
            SelectValue $role '250750'
            SelectValue 'P6_COMP_COMPETENCIA' '201809'
            CheckValue ('E17_'+$roleLabel+'_MONTH_COUNT') 'GetSelectedCount(P6_COMP_COMPETENCIA)' '1'
            CheckValue ('E17_'+$roleLabel+'_YEAR_COUNT') 'GetSelectedCount(P6_ANO_ANO)' '0'
            CheckValue ('E17_'+$roleLabel+'_ROLE_COUNT') ('GetSelectedCount('+$role+')') '1'
            foreach ($metric in @(
                @{Name='ROLE_VALUES';Expr='GetFieldSelections('+$role+')'},
                @{Name='COUNT_POP';Expr='Count(P6_POP_ROW_DEBUG)'},
                @{Name='NORMAL_POP';Expr='Sum(P6_POP_HABITANTES_E5)'},
                @{Name='ANNUAL_CLEAR_COMP_POP';Expr='Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5)'}
            )) {
                Write-Output ('E17_'+$roleLabel+'_'+$metric.Name+'='+[string]($doc.Evaluate($metric.Expr)))
            }
            Write-Output ('E17_'+$roleLabel+'_E10='+[string]($doc.Evaluate($e10)))
            Write-Output ('E17_'+$roleLabel+'_MONTH=OBSERVED_NOT_CONTRACT')
        }
        # Both roles selected to the SAME municipality: this is not a residence-to-service flow analysis.
        ResetCase
        SelectValue 'P6_SERV_DATASUS_6' '250750'
        SelectValue 'P6_RES_DATASUS_6' '250750'
        SelectValue 'P6_COMP_COMPETENCIA' '201809'
        foreach ($probe in @(
            @{Name='SERV_COUNT';Expr='GetSelectedCount(P6_SERV_DATASUS_6)'},
            @{Name='RES_COUNT';Expr='GetSelectedCount(P6_RES_DATASUS_6)'},
            @{Name='MONTH_COUNT';Expr='GetSelectedCount(P6_COMP_COMPETENCIA)'},
            @{Name='YEAR_COUNT';Expr='GetSelectedCount(P6_ANO_ANO)'},
            @{Name='SERV_VALUES';Expr='GetFieldSelections(P6_SERV_DATASUS_6)'},
            @{Name='RES_VALUES';Expr='GetFieldSelections(P6_RES_DATASUS_6)'},
            @{Name='COUNT_POP';Expr='Count(P6_POP_ROW_DEBUG)'},
            @{Name='NORMAL_POP';Expr='Sum(P6_POP_HABITANTES_E5)'},
            @{Name='ANNUAL_CLEAR_COMP_POP';Expr='Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5)'}
        )) {
            Write-Output ('E17_BOTH_JP_'+$probe.Name+'='+[string]($doc.Evaluate($probe.Expr)))
        }
        Write-Output ('E17_BOTH_JP_E10='+[string]($doc.Evaluate($e10)))
        Write-Output 'E17_BOTH_JP_MONTH=OBSERVED_NOT_CONTRACT'

        Write-Output 'E17_GEOGRAPHIC_DISCOVERY=OBSERVED_PENDING_SEMANTIC_REVIEW'
    }
    # E18: cross-role coordinates are intentionally DIFFERENT. Diagnostic, not a denominator rule.
    if ($CrossRoleDiscovery) {
        Write-Output 'E18_DIFFERENT_MUNICIPALITY_DISCOVERY=STARTED'
        if ($OtherMunicipality -notmatch '^[0-9]{6}$' -or $OtherMunicipality -ceq '250750') {
            throw 'BLOCKED_E18_OTHER_MUNICIPALITY_MUST_BE_DIFFERENT_VALID_6_DIGITS'
        }
        # Verify municipality value exists in each genuine in-memory role field before using it.
        foreach ($role in @('P6_RES_DATASUS_6','P6_SERV_DATASUS_6')) {
            $existExpr = "Count({1<" + $role + "={'" + $OtherMunicipality + "'}>} DISTINCT " + $role + ")"
            CheckValue ('E18_OTHER_IN_'+$role) $existExpr '1'
        }
        # Three application orders of service/residence filters and temporal context.
        foreach ($scenario in @(
            @{Label='SERV_FIRST_MONTH';Order=@('P6_SERV_DATASUS_6','P6_RES_DATASUS_6');Competence='201809';Year=''},
            @{Label='RES_FIRST_MONTH';Order=@('P6_RES_DATASUS_6','P6_SERV_DATASUS_6');Competence='201809';Year=''},
            @{Label='SERV_FIRST_YEAR';Order=@('P6_SERV_DATASUS_6','P6_RES_DATASUS_6');Competence='';Year='2018'}
        )) {
            ResetCase
            foreach ($role in $scenario.Order) {
                if ($role -ceq 'P6_SERV_DATASUS_6') {
                    SelectValue $role '250750'
                } else {
                    SelectValue $role $OtherMunicipality
                }
            }
            if ($scenario.Competence -ne '') {
                SelectValue 'P6_COMP_COMPETENCIA' $scenario.Competence
            } else {
                SelectValue 'P6_ANO_ANO' $scenario.Year
            }
            Write-Output ('E18_SCENARIO=' + $scenario.Label)
            foreach ($probe in @(
                @{Name='SERV_COUNT';Expr='GetSelectedCount(P6_SERV_DATASUS_6)'},
                @{Name='SERV_VALUES';Expr='GetFieldSelections(P6_SERV_DATASUS_6)'},
                @{Name='RES_COUNT';Expr='GetSelectedCount(P6_RES_DATASUS_6)'},
                @{Name='RES_VALUES';Expr='GetFieldSelections(P6_RES_DATASUS_6)'},
                @{Name='COMP_COUNT';Expr='GetSelectedCount(P6_COMP_COMPETENCIA)'},
                @{Name='COMP_VALUES';Expr='GetFieldSelections(P6_COMP_COMPETENCIA)'},
                @{Name='YEAR_COUNT';Expr='GetSelectedCount(P6_ANO_ANO)'},
                @{Name='YEAR_VALUES';Expr='GetFieldSelections(P6_ANO_ANO)'},
                @{Name='COUNT_POP';Expr='Count(P6_POP_ROW_DEBUG)'},
                @{Name='NORMAL_POP';Expr='Sum(P6_POP_HABITANTES_E5)'},
                @{Name='ANNUAL_CLEAR_COMP_POP';Expr='Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5)'}
            )) {
                Write-Output ('E18_'+$scenario.Label+'_'+$probe.Name+'='+[string]($doc.Evaluate($probe.Expr)))
            }
            Write-Output ('E18_'+$scenario.Label+'_E10='+[string]($doc.Evaluate($e10)))
            $svcState = [string]($doc.Evaluate('GetFieldSelections(P6_SERV_DATASUS_6)'))
            $resState = [string]($doc.Evaluate('GetFieldSelections(P6_RES_DATASUS_6)'))
            $intact=($svcState -ceq '250750' -and $resState -ceq $OtherMunicipality)
            Write-Output ('E18_'+$scenario.Label+'_BOTH_INTENDED_ROLE_FILTERS_SURVIVED='+$intact)
            Write-Output ('E18_'+$scenario.Label+'=OBSERVED_NOT_CONTRACT')
        }
        Write-Output 'E18_DIFFERENT_MUNICIPALITY_DISCOVERY=OBSERVED_PENDING_SEMANTIC_REVIEW'
    }
} catch {
    $failure=$_.Exception.Message
    Write-Output ('E13_GATE=FAIL_CLOSED_'+$failure)
} finally {
    if ($null -ne $doc) {
        try {[void]$doc.CloseDoc()} catch {Write-Output ('E13_CLOSE_WARNING='+$_.Exception.Message)}
        if ([Runtime.InteropServices.Marshal]::IsComObject($doc)) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc)
        }
    }
    if ($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
    }
    $after=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
    Write-Output ('SOURCE_SHA256_UNCHANGED='+($after -ceq $srcHash))
    Write-Output 'SAVE_EXECUTED=False'
    Write-Output 'RELOAD_EXECUTED=False'
    Write-Output 'QVD_WRITES=0'
    Write-Output ('DISPOSABLE_DIAGNOSTIC_DIR='+$dir)
    if ($after -cne $srcHash) {$failure='SOURCE_CHANGED'}
}
if ($null -ne $failure) {
    Write-Output ('VERDICT=FAIL_CLOSED_'+$failure)
    exit 1
}
Write-Output 'VERDICT=PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED'
