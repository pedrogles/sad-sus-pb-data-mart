# SAD P6/E12 - DISCOVERY READ ONLY of QlikView 12 COM surface.
# No selections, no reload, no Save, no QVD or repository mutation.
# Use a closed and SAVED COPY of the experimental E5 QVW, outside %TEMP% and the repository.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Qvw
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resolved = [IO.Path]::GetFullPath($Qvw)
if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "QVW_NOT_FOUND=$resolved"
}
if ([IO.Path]::GetExtension($resolved) -ine '.qvw') {
    throw 'BLOCKED_NOT_QVW'
}
if ([IO.Path]::GetFileName($resolved) -notmatch '^SAD_P6_E5_POP_.*\.qvw$') {
    throw 'BLOCKED_EXPECTED_SAVED_E5_EXPERIMENTAL_COPY'
}
if ($resolved.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)) {
    throw 'BLOCKED_USE_SAVED_COPY_OUTSIDE_TEMP'
}
$hashBefore = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
$qv = $null
$doc = $null
$fields = @('P6_COMP_COMPETENCIA','P6_ANO_ANO','P6_SERV_DATASUS_6','P6_RES_DATASUS_6')
function ShowComMembers([string]$label, [object]$obj) {
    if ($null -eq $obj) { Write-Output "$label=OBJECT_NULL"; return }
    try {
        $methodNames = @($obj | Get-Member -MemberType Method -Force |
            ForEach-Object { $_.Name } | Sort-Object -Unique)
        $propertyNames = @($obj | Get-Member -MemberType Property -Force |
            ForEach-Object { $_.Name } | Sort-Object -Unique)
        Write-Output ("$label.METHODS=" + ($methodNames -join ','))
        Write-Output ("$label.PROPERTIES=" + ($propertyNames -join ','))
    } catch {
        Write-Output ("$label.INTROSPECTION_ERROR=" + $_.Exception.Message)
    }
}
try {
    Write-Output 'MODE=QLIK_COM_SELECTION_DISCOVERY_READ_ONLY'
    Write-Output ('QVW_SHA256_BEFORE='+$hashBefore)
    $qv=New-Object -ComObject 'QlikTech.QlikView'
    ShowComMembers 'APP' $qv
    $doc=$qv.OpenDoc($resolved,'','')
    if ($null -eq $doc) {throw 'BLOCKED_OPENDOC_NULL'}
    ShowComMembers 'DOC' $doc
    try {
        $tableCount = [int]$doc.GetTableCount()
        Write-Output ("DOC_TABLE_COUNT=$tableCount")
    } catch {
        Write-Output ('DOC_TABLE_COUNT_METHOD_UNAVAILABLE='+$_.Exception.Message)
    }
    foreach ($name in $fields) {
        $fieldObj=$null
        try {
            $fieldObj=$doc.GetField($name)
            if ($null -eq $fieldObj) {
                Write-Output ("FIELD_$name=NOT_FOUND")
            } else {
                Write-Output ("FIELD_$name=FOUND")
                ShowComMembers "FIELD_$name" $fieldObj
            }
        } catch {
            Write-Output ("FIELD_$name.API_ERROR="+$_.Exception.Message)
        } finally {
            if ($null -ne $fieldObj -and [Runtime.InteropServices.Marshal]::IsComObject($fieldObj)) {
                [void][Runtime.InteropServices.Marshal]::ReleaseComObject($fieldObj)
            }
        }
    }
    Write-Output 'SELECT_OPERATIONS_EXECUTED=0'
    Write-Output 'RELOAD_EXECUTED=False'
    Write-Output 'SAVE_EXECUTED=False'
    Write-Output 'QVD_WRITES=0'
    Write-Output 'VERDICT=COM_CAPABILITIES_ENUMERATED_REVIEW_REQUIRED'
} catch {
    Write-Output ('VERDICT=FAIL_CLOSED_'+$_.Exception.Message)
    exit 1
} finally {
    if ($null -ne $doc) {
        try {[void]$doc.CloseDoc()} catch {Write-Warning ('CloseDoc: '+$_.Exception.Message)}
        if ([Runtime.InteropServices.Marshal]::IsComObject($doc)) {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($doc)
        }
    }
    if ($null -ne $qv -and [Runtime.InteropServices.Marshal]::IsComObject($qv)) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($qv)
    }
    $hashAfter=(Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
    Write-Output ('QVW_SHA256_AFTER='+$hashAfter)
    Write-Output ('QVW_SHA256_UNCHANGED='+($hashBefore -ceq $hashAfter))
    if ($hashBefore -cne $hashAfter) {throw 'VERDICT=FAIL_SOURCE_QVW_CHANGED'}
}
