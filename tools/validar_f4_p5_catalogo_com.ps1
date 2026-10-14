# SAD SUS PB — F4 P5 catalogue coverage via QlikView 12 COM, wrapper-only.
# Exercises 48 single filter x indicator cases and 8 pairs; NEVER emits a KPI.
# UI controls and actual object-level C/R/I/B behavior are NOT implemented here.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SourceQvw,
    [Parameter(Mandatory=$true)][string]$F4Dir
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$src=[IO.Path]::GetFullPath($SourceQvw)
$tmp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
if (-not $src.StartsWith($tmp,[StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($src) -cne 'F4_P5_SOURCE_PROJECTION_DISPOSABLE.qvw' -or
    [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($src)) -notmatch '^SAD_F4_P5_PROJECTION_[0-9a-f]{32}$') {
    throw 'BLOCKED_NOT_A_DISPOSABLE_F4_P5_QVW'
}
$manifestPath=Join-Path $F4Dir 'manifest_F4.json'
$singlePath=Join-Path $F4Dir 'F4_p5_filtros_isolados.csv'
$pairPath=Join-Path $F4Dir 'F4_p5_filtros_combinados.csv'
foreach($path in @($src,$manifestPath,$singlePath,$pairPath)){
    if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw "MISSING_REQUIRED_INPUT=$path"}
}
$m=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
foreach($path in @($singlePath,$pairPath)){
    $name=[IO.Path]::GetFileName($path)
    $real=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    $recorded=[string]$m.output_sha256.$name
    if($real -cne $recorded){throw "F4_CATALOG_HASH_INVALID=$name"}
}
$singles=@(Import-Csv -LiteralPath $singlePath -Delimiter ';' -Encoding UTF8)
$pairs=@(Import-Csv -LiteralPath $pairPath -Delimiter ';' -Encoding UTF8)
if($singles.Count -ne 48 -or $pairs.Count -ne 8){throw 'F4_CATALOG_CARDINALITY_INVALID'}

$roles=@('RES','LEI','REL','FLU')
# P5 V2 from Discovery VI sec 62.6; hardcoded here as an independent drift guard.
# The expected single letters deliberately do NOT derive from the F4 CSV alone.
$map=[ordered]@{
    'Ano analitico' = @('P6_ANO_ANO','CCCC')
    'Competencia mensal' = @('P6_COMP_COMPETENCIA','CCCC')
    'Municipio de residencia' = @('P6_RES_DATASUS_6','CBBC')
    'Municipio de servico' = @('P6_SERV_DATASUS_6','BCCC')
    'Estabelecimento CNES' = @('P6_EST_CNES','RRRR')
    'Procedimento realizado PROC_REA' = @('F4_RD_PROC_REA','RIBR')
    'Diagnostico principal DIAG_PRINC' = @('F4_RD_DIAG_PRINC','RIBR')
    'Carater do atendimento' = @('F4_RD_CAR_INT','RIBR')
    'Motivo de saida/permanencia' = @('F4_RD_COBRANCA','RIBR')
    'Tipo/codigo de leito' = @('F4_LT_CODLEITO','IRBI')
    'Data clinica de internacao' = @('F4_RD_DT_INTER','RIBR')
    'Data clinica de saida' = @('F4_RD_DT_SAIDA','RIBR')
}
# The only authorized combined catalog is the 8-case set in the F4 generator.
$expectedPairs=@(
    'RES|Municipio de servico|Ano analitico',
    'LEI|Municipio de residencia|Tipo/codigo de leito',
    'REL|Procedimento realizado PROC_REA|Ano analitico',
    'FLU|Municipio de residencia|Municipio de servico',
    'FLU|Tipo/codigo de leito|Ano analitico',
    'RES|Estabelecimento CNES|Municipio de residencia',
    'LEI|Diagnostico principal DIAG_PRINC|Municipio de servico',
    'RES|Tipo/codigo de leito|Ano analitico'
)
function Combine([string[]]$codes) {
    if($codes -ccontains 'B') {return 'BLOCK_GENERAL_INDICATOR'}
    if($codes -ccontains 'R' -and $codes -ccontains 'I') {
        return 'REQUIRES_SCOPED_ANALYSIS_AND_EXPLICIT_ISOLATION'
    }
    if($codes -ccontains 'R') {return 'REQUIRES_SEPARATE_SCOPED_ANALYSIS'}
    if($codes -ccontains 'I') {return 'REQUIRES_EXPLICIT_ISOLATION_AND_WARNING'}
    return 'COMPATIBLE_CONDITIONAL_OTHER_GATES'
}
$seen=@{}
$frequencies=@{C=0;R=0;I=0;B=0}
foreach($r in $singles) {
    $filter=[string]$r.filtro;$role=[string]$r.indicador;$code=[string]$r.politica_p5
    if(-not $map.Contains($filter) -or $role -cnotin $roles){throw "P5_UNKNOWN_FILTER_OR_ROLE=$filter|$role"}
    $key=$filter+'|'+$role
    if($seen.ContainsKey($key)){throw "P5_SINGLE_DUPLICATE=$key"}
    $ordinal=[array]::IndexOf($roles,$role)
    $expectedCode=[string]$map[$filter][1][$ordinal]
    if($code -cne $expectedCode -or [string]$r.expectativa -cne (Combine @($code))){
        throw "P5_SINGLE_DRIFT=$key"
    }
    $seen[$key]=$code
    $frequencies[$code]=[int]$frequencies[$code]+1
}
foreach($filter in $map.Keys){foreach($role in $roles) {
    if(-not $seen.ContainsKey($filter+'|'+$role)){throw "P5_SINGLE_MISSING=$filter|$role"}
}}
if($frequencies.C -ne 13 -or $frequencies.R -ne 17 -or
   $frequencies.I -ne 8 -or $frequencies.B -ne 10){throw 'P5_SINGLE_COUNTS_DRIFT'}
$pairSeen=@{}
foreach($r in $pairs){
    $name=[string]$r.indicador+'|'+[string]$r.filtro_a+'|'+[string]$r.filtro_b
    if($pairSeen.ContainsKey($name) -or $name -cnotin $expectedPairs) {
        throw "P5_PAIR_UNEXPECTED=$name"
    }
    $key1=[string]$r.filtro_a+'|'+[string]$r.indicador
    $key2=[string]$r.filtro_b+'|'+[string]$r.indicador
    $a=$seen[$key1];$b=$seen[$key2]
    if([string]$r.politica_a -cne $a -or [string]$r.politica_b -cne $b -or
       [string]$r.expectativa -cne (Combine @($a,$b))) {
        throw "P5_PAIR_DRIFT=$name"
    }
    $pairSeen[$name]=$r
}
foreach($k in $expectedPairs){if(-not $pairSeen.ContainsKey($k)){throw "P5_PAIR_MISSING=$k"}}
$sourceHash=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
$dir=Join-Path ([IO.Path]::GetTempPath()) ('SAD_F4_P5_FULL_POLICY_'+[Guid]::NewGuid().ToString('N'))
New-Item -Path $dir -ItemType Directory -ErrorAction Stop | Out-Null
$copy=Join-Path $dir 'F4_P5_FULL_POLICY_DISPOSABLE.qvw'
Copy-Item -LiteralPath $src -Destination $copy -ErrorAction Stop
if((Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash -cne $sourceHash){
    throw 'F4_P5_COPY_SHA256_INVALID'
}
$qv=$null;$doc=$null;$problem=$null
function Q([string]$e){return [string]($script:doc.Evaluate($e))}
function RequireQ([string]$name,[string]$e,[string]$want){
    $got=Q $e
    if($got -cne $want){throw "BLOCKED_$name EXPECTED=$want ACTUAL=$got"}
}
function SelectQ([string]$fieldName,[string]$value){
    $f=$null
    try {
        $f=$script:doc.GetField($fieldName)
        if($null -eq $f){throw "QV_FIELD_ABSENT=$fieldName"}
        $null=$f.Select($value)
    } finally {
        if($null -ne $f -and [Runtime.InteropServices.Marshal]::IsComObject($f)){
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($f)
        }
    }
}
function ResetQ {$null=$script:doc.ClearAll()}
try {
    Write-Output 'MODE=F4_P5_48_SINGLE_8_PAIR_POLICY_WRAPPER_COM'
    Write-Output 'CATALOG_SHA256_PASS=2_OF_2'
    Write-Output ('SOURCE_SHA256_BEFORE='+$sourceHash)
    Write-Output ('DISPOSABLE_COPY='+$copy)
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    $doc=$qv.OpenDoc($copy,'','')
    if($null -eq $doc){throw 'QVW_COM_OPEN_FAILED'}
    ResetQ
    RequireQ 'BASE_RD' 'Sum(F4_RD_QTD_INTERNACAO)' '555089'
    RequireQ 'BASE_LT_ROWS' 'Count(F4_LT_QT_SUS)' '35518'
    RequireQ 'BASE_POP' 'Count(P6_POP_ROW_DEBUG)' '669'
    Write-Output 'BASELINE_COMPONENTS=PASS'

    $samples=@{}
    foreach($filter in $map.Keys) {
        $fieldName=[string]$map[$filter][0]
        # Probe in the baseline state. These samples come from Qlik, not invented source values.
        ResetQ
        $value=Q ('MinString('+ $fieldName +')')
        if(-not $value){throw "QV_FIELD_WITHOUT_SAMPLE=$fieldName"}
        $samples[$filter]=$value
    }
    $runSingles=0
    foreach($r in $singles) {
        $filter=[string]$r.filtro;$role=[string]$r.indicador
        $fieldName=[string]$map[$filter][0]
        ResetQ
        SelectQ $fieldName ([string]$samples[$filter])
        RequireQ 'SINGLE_SELECTED' ('GetSelectedCount('+ $fieldName +')') '1'
        $decision=Combine @([string]$r.politica_p5)
        # Even for C, additional time/scope/denominator gates are unresolved.
        # Never evaluate a general KPI under this runner.
        Write-Output ("SINGLE FILTER=$filter ROLE=$role CODE=$($r.politica_p5) GUARD=$decision COM_SELECT=PASS KPI_EVALUATED=False")
        $runSingles++
    }
    if($runSingles -ne 48){throw 'SINGLE_EXECUTION_COUNT_INCORRECT'}
    Write-Output 'SINGLES_48_OF_48=PASS_COM_SELECT_AND_WRAPPER_POLICY_ONLY'

    $runPairs=0;$blockedPairs=0;$compatiblePairs=0
    foreach($r in $pairs){
        ResetQ
        $policyA=[string]$r.politica_a;$policyB=[string]$r.politica_b
        $decision=Combine @($policyA,$policyB)
        if($decision -cne 'COMPATIBLE_CONDITIONAL_OTHER_GATES'){
            $blockedPairs++
            $fieldA=[string]$map[[string]$r.filtro_a][0]
            $fieldB=[string]$map[[string]$r.filtro_b][0]
            RequireQ 'DENIED_PAIR_LEFT_UNSELECTED_A' ('GetSelectedCount('+ $fieldA +')') '0'
            RequireQ 'DENIED_PAIR_LEFT_UNSELECTED_B' ('GetSelectedCount('+ $fieldB +')') '0'
            Write-Output ("PAIR ROLE=$($r.indicador) FILTER_A=$($r.filtro_a) FILTER_B=$($r.filtro_b) GUARD=$decision COM_DISPATCH=False KPI_EVALUATED=False")
        } else {
            # Only C/C pair in catalogue: FLU residence and service. Use same
            # grounded JP code to avoid inadvertent conflicting municipality selection.
            if([string]$r.indicador -cne 'FLU' -or
               [string]$r.filtro_a -cne 'Municipio de residencia' -or
               [string]$r.filtro_b -cne 'Municipio de servico'){
                throw 'UNEXPECTED_C_C_PAIR'
            }
            SelectQ 'P6_ANO_ANO' '2018'
            SelectQ 'P6_RES_DATASUS_6' '250750'
            SelectQ 'P6_SERV_DATASUS_6' '250750'
            RequireQ 'CC_2018' 'GetFieldSelections(P6_ANO_ANO)' '2018'
            RequireQ 'CC_RES' 'GetFieldSelections(P6_RES_DATASUS_6)' '250750'
            RequireQ 'CC_SERV' 'GetFieldSelections(P6_SERV_DATASUS_6)' '250750'
            $compatiblePairs++
            Write-Output 'PAIR ROLE=FLU FILTER_A=Municipio de residencia FILTER_B=Municipio de servico GUARD=COMPATIBLE_CONDITIONAL_OTHER_GATES COM_DISPATCH=True KPI_EVALUATED=False'
        }
        $runPairs++
    }
    if($runPairs -ne 8 -or $blockedPairs -ne 7 -or $compatiblePairs -ne 1){
        throw 'PAIR_EXECUTION_COUNTS_INCORRECT'
    }
    Write-Output 'PAIRS_8_OF_8=PASS_PRE_DISPATCH_POLICY_ONLY'
    Write-Output 'P5_FULL_CATALOG_WRAPPER=PASS_RESTRICTED_NOT_UI_NOT_KPI'
} catch {
    $problem=$_.Exception.Message
    Write-Output ('GATE=FAIL_CLOSED_'+$problem)
} finally {
    if($null -ne $doc){
        try{[void]$doc.CloseDoc()}catch{Write-Output ('CLOSE_WARNING='+$_.Exception.Message)}
        if([Runtime.InteropServices.Marshal]::IsComObject($doc)){
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc)
        }
    }
    if($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)){
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
    }
    $after=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
    Write-Output ('SOURCE_SHA256_UNCHANGED='+($sourceHash -ceq $after))
    Write-Output 'SAVE_EXECUTED=False'
    Write-Output 'RELOAD_EXECUTED=False'
    Write-Output 'QVD_WRITES=0'
    Write-Output 'PHYSICAL_P5_UI_ENFORCEMENT=NOT_IMPLEMENTED'
    Write-Output 'T24_T26_AND_LINK_CONTRACT=NOT_APPROVED'
    Write-Output ('TEMP_DIAGNOSTIC_DIR='+$dir)
    if($sourceHash -cne $after){$problem='ORIGINAL_QVW_CHANGED'}
}
if($null -ne $problem){
    Write-Output ('FINAL_VERDICT=FAIL_CLOSED_'+$problem)
    exit 1
}
Write-Output 'FINAL_VERDICT=PASS_P5_48_8_WRAPPER_COM_ONLY_PHYSICAL_P5_NOT_APPROVED'
