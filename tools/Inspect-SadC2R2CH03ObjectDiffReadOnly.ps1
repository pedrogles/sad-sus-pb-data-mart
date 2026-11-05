# SAD C2 R2 CH03/H1 — post-Verify object inventory. Read-only QVW analysis.
# No Save/SaveAs, Reload, ClearAll, Select, SetProperties, creation or mutation of document objects.
# Runs only against verified copies outside the repository; verifies SHA-256 of originals and copies before/after.
# Versioned in PR #222. Uses QlikView COM methods already used in the project's experimental scripts.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gate = 'SAD-C2-R2-P12-CH03-OBJECT-FORENSIC-READONLY-01'
$branchExpected = 'test/sad-c2-r2-p12-ch03-native-h1-20261105'
$scriptRel = 'tools/Inspect-SadC2R2CH03ObjectDiffReadOnly.ps1'
$sourceShaExpected = 'E38C41B3F9CEECC3E4964CB91E5FE8C17FD608FA32CB5612DC2907E82348296E'
$targetShaExpected = 'C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D'
$runId = 'SAD_C2_P12_CH03_H1_c70f6c392ca44f53900a92c0cc601073'
$source = Join-Path $env:USERPROFILE 'Documents\SAD_C2_P11_H1_RUNTIME\SAD_C2_P11_H1_d6723bea5c7b43928e324b773c51a409\SAD_C2_R2_P11_HISTORICAL_CARDS_H1_TEMP.qvw'
$target = Join-Path $env:USERPROFILE ('Documents\SAD_C2_P12_CH03_H1_RUNTIME\' + $runId + '\SAD_C2_R2_P12_CH03_NATIVE_H1_TEMP.qvw')
$evidence = Join-Path $env:USERPROFILE ('Documents\SAD_C2_P12_CH03_H1_EVIDENCE\' + $runId)

function Assert-Sad([bool]$ok, [string]$reason) {
    if (-not $ok) { throw $reason }
}
function Sha256([string]$path) {
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Absolute([string]$path) {
    Assert-Sad ([IO.Path]::IsPathRooted($path)) 'BLOCKED_ABSOLUTE_PATH_REQUIRED'
    return [IO.Path]::GetFullPath($path).TrimEnd('\','/')
}
function Under([string]$child,[string]$parent) {
    $sep = [string][IO.Path]::DirectorySeparatorChar
    return $child.StartsWith($parent+$sep, [StringComparison]::OrdinalIgnoreCase)
}
function Get-SadProtected([string]$repoPath) {
    $extr = Join-Path $repoPath 'EXTRACAO\QVD'
    $trans = Join-Path $repoPath 'TRANSFORMACAO\QVD'
    Assert-Sad (Test-Path -LiteralPath $extr -PathType Container) 'BLOCKED_EXTR_QVD_FOLDER'
    Assert-Sad (Test-Path -LiteralPath $trans -PathType Container) 'BLOCKED_TRANS_QVD_FOLDER'
    $a=@(Get-ChildItem -LiteralPath $extr -File -Filter '*.qvd')
    $b=@(Get-ChildItem -LiteralPath $trans -File -Filter '*.qvd')
    Assert-Sad ($a.Count -eq 10 -and $b.Count -eq 12) 'BLOCKED_PROTECTED_QVD_COUNT'
    $all=@($a)+@($b)
    foreach($rel in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
        $p=Join-Path $repoPath $rel
        Assert-Sad (Test-Path -LiteralPath $p -PathType Leaf) 'BLOCKED_PROTECTED_QVW_MISSING'
        $all+=@(Get-Item -LiteralPath $p)
    }
    Assert-Sad ($all.Count -eq 25) 'BLOCKED_PROTECTED_25_COUNT'
    return @($all|Sort-Object FullName|ForEach-Object {
        $_.FullName+'|'+$_.Length+'|'+(Sha256 $_.FullName)
    })
}
function Release-SadCom($obj) {
    if ($null -ne $obj -and [Runtime.InteropServices.Marshal]::IsComObject($obj)) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($obj)
    }
}

Assert-Sad ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) 'BLOCKED_WINDOWS_REQUIRED'
$repo = Absolute $Root
$source = Absolute $source
$target = Absolute $target
$evidence = Absolute $evidence
$actualScript = Absolute (Join-Path $repo $scriptRel)
Assert-Sad ($actualScript -ieq (Absolute $PSCommandPath)) 'BLOCKED_USE_VERSIONED_SCRIPT_IN_REPO'
Assert-Sad (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf) 'BLOCKED_REPO_ROOT_REQUIRED'
Assert-Sad (Test-Path -LiteralPath (Join-Path $evidence 'c2_p12_ch03_h1_verify.json') -PathType Leaf) 'BLOCKED_PREVIOUS_VERIFY_REQUIRED'
Assert-Sad (-not (Under $source $repo) -and -not (Under $target $repo) -and -not (Under $evidence $repo)) 'BLOCKED_QVW_OR_EVIDENCE_INSIDE_REPO'
Assert-Sad ($source -ine $target) 'BLOCKED_SAME_QVW_SOURCE_TARGET'
Assert-Sad (@(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(qv|qlikview)$'}).Count -eq 0) 'BLOCKED_CLOSE_QLIKVIEW_FIRST'
$gitBranch = ([string](& git -C $repo branch --show-current)).Trim()
Assert-Sad ($LASTEXITCODE -eq 0 -and $gitBranch -ceq $branchExpected) 'BLOCKED_WRONG_GIT_BRANCH'
$head = ([string](& git -C $repo rev-parse HEAD)).Trim()
Assert-Sad ($LASTEXITCODE -eq 0 -and $head -match '^[0-9a-f]{40}$') 'BLOCKED_GIT_HEAD'
$tracked = @(& git -C $repo ls-files --error-unmatch -- $scriptRel 2>$null)
Assert-Sad ($LASTEXITCODE -eq 0 -and $tracked.Count -eq 1) 'BLOCKED_SCRIPT_MUST_BE_COMMITTED'
Assert-Sad (@(& git -C $repo status --porcelain --untracked-files=all).Count -eq 0) 'BLOCKED_DIRTY_WORKTREE'
foreach ($path in @($source,$target)) {
    Assert-Sad (Test-Path -LiteralPath $path -PathType Leaf) 'BLOCKED_ORIGINAL_QVW_MISSING'
}
Assert-Sad ((Sha256 $source) -ceq $sourceShaExpected) 'HARD_STOP_SOURCE_HASH_DRIFT'
Assert-Sad ((Sha256 $target) -ceq $targetShaExpected) 'HARD_STOP_TARGET_HASH_DRIFT'
$protectedBefore = @(Get-SadProtected $repo)

# Evidence-only directory. Fail rather than overwrite or reuse an existing output.
$folder = Join-Path $evidence ('OBJECT_AUDIT_' + [guid]::NewGuid().ToString('N'))
Assert-Sad (-not (Test-Path -LiteralPath $folder)) 'BLOCKED_AUDIT_FOLDER_COLLISION'
$null = New-Item -ItemType Directory -Path $folder -ErrorAction Stop
$srcCopy = Join-Path $folder 'audit_source_readonly.qvw'
$dstCopy = Join-Path $folder 'audit_target_readonly.qvw'
Copy-Item -LiteralPath $source -Destination $srcCopy -ErrorAction Stop
Copy-Item -LiteralPath $target -Destination $dstCopy -ErrorAction Stop
Assert-Sad ((Sha256 $srcCopy) -ceq $sourceShaExpected) 'HARD_STOP_SOURCE_AUDIT_COPY_HASH'
Assert-Sad ((Sha256 $dstCopy) -ceq $targetShaExpected) 'HARD_STOP_TARGET_AUDIT_COPY_HASH'
(Get-Item -LiteralPath $srcCopy).IsReadOnly = $true
(Get-Item -LiteralPath $dstCopy).IsReadOnly = $true

function Read-SadInventory([object]$qv,[string]$qvw,[string]$label,[string]$dir) {
    $doc = $null
    $rows = New-Object 'System.Collections.Generic.List[object]'
    $exportInfo = [ordered]@{ attempted=$false;status='NOT_ATTEMPTED';path=$null;sha256=$null }
    try {
        $doc = $qv.OpenDoc($qvw,'','')
        Assert-Sad ($null -ne $doc) ('BLOCKED_COM_OPEN_DOC_'+$label)
        $sheets = [int]$doc.NoOfSheets()
        Assert-Sad ($sheets -gt 0 -and $sheets -le 50) ('BLOCKED_SHEET_COUNT_'+$label)
        for ($i=0; $i -lt $sheets; $i++) {
            $sheet = $null
            try {
                $sheet = $doc.GetSheet($i)
                Assert-Sad ($null -ne $sheet) ('BLOCKED_GETSHEET_'+$i)
                $sheetId = 'INDEX_'+$i
                try { $sheetId = [string]$sheet.GetObjectID() } catch { }
                $n = [int]$sheet.NoOfSheetObjects()
                Assert-Sad ($n -ge 0 -and $n -le 2000) ('BLOCKED_OBJECT_COUNT_'+$label+'_'+$i)
                for ($j=0; $j -lt $n; $j++) {
                    $obj = $null
                    try {
                        try { $obj = $sheet.SheetObjects($j) }
                        catch { throw ('BLOCKED_SHEETOBJECTS_API_'+$label+'_'+$i+'_'+$j+'_'+$_.Exception.Message) }
                        Assert-Sad ($null -ne $obj) ('BLOCKED_NULL_OBJECT_'+$label+'_'+$i+'_'+$j)
                        $id = [string]$obj.GetObjectID()
                        $typ = [int]$obj.GetObjectType()
                        Assert-Sad (-not [string]::IsNullOrWhiteSpace($id)) ('BLOCKED_OBJECT_ID_EMPTY_'+$label)
                        $text = $null
                        if ($typ -eq 6) {  # QlikView Automation: Text Object
                            try { $text = [string]$obj.GetProperties().Layout.Text.v } catch { }
                        }
                        [void]$rows.Add([pscustomobject][ordered]@{
                            SheetIndex=$i;SheetID=$sheetId;ObjectID=$id;ObjectType=$typ
                            TextExpression=$text
                        })
                    } finally { Release-SadCom $obj }
                }
            } finally { Release-SadCom $sheet }
        }
        # Metadata export, without Save/SaveAs. QlikView API availability can vary by build.
        # Failure does not invalidate the object inventory; it limits full-property audit.
        $layout = Join-Path $dir ($label+'_layout.xml')
        try {
            $exportInfo.attempted=$true
            [void]$doc.ExportLayoutFile($layout)
            if (Test-Path -LiteralPath $layout -PathType Leaf) {
                $exportInfo.status='EXPORTED';$exportInfo.path=$layout
                $exportInfo.sha256=Sha256 $layout
            } else { $exportInfo.status='NO_FILE_RETURNED' }
        } catch { $exportInfo.status='API_ERROR: '+$_.Exception.Message }
        Assert-Sad ($rows.Count -gt 0) ('BLOCKED_NO_SHEET_OBJECTS_'+$label)
        return [pscustomobject]@{rows=@($rows.ToArray());layout=$exportInfo}
    } finally {
        if ($null -ne $doc) {
            try { [void]$doc.CloseDoc() } catch { Write-Warning ('CLOSE_DOC_'+$label+': '+$_.Exception.Message) }
            Release-SadCom $doc
        }
    }
}

$app=$null
$left=$null
$right=$null
$fail=$null
try {
    $app=New-Object -ComObject 'QlikTech.QlikView'
    $left=Read-SadInventory $app $srcCopy 'source' $folder
    $right=Read-SadInventory $app $dstCopy 'target' $folder
} catch {
    $fail=$_.Exception.Message
} finally {
    Release-SadCom $app
    $safe = ((Sha256 $source) -ceq $sourceShaExpected) -and
            ((Sha256 $target) -ceq $targetShaExpected) -and
            ((Sha256 $srcCopy) -ceq $sourceShaExpected) -and
            ((Sha256 $dstCopy) -ceq $targetShaExpected)
    $protectedAfter = @(Get-SadProtected $repo)
    $protectedOk = (($protectedBefore -join [Environment]::NewLine) -ceq ($protectedAfter -join [Environment]::NewLine))
    Write-Output ('PROTECTED_25_UNCHANGED='+$protectedOk)
    Assert-Sad $protectedOk 'HARD_STOP_PROTECTED_25_CHANGED'
    Write-Output ('ORIGINAL_AND_AUDIT_COPIES_UNCHANGED='+$safe)
    if (-not $safe) { throw 'HARD_STOP_QVW_HASH_CHANGED' }
}
if ($null -ne $fail) { throw ('BLOCKED_COM_INVENTORY_'+$fail) }
$src = @($left.rows)
$dst = @($right.rows)
$src | Export-Csv -LiteralPath (Join-Path $folder 'source_objects.csv') -NoTypeInformation -Encoding UTF8
$dst | Export-Csv -LiteralPath (Join-Path $folder 'target_objects.csv') -NoTypeInformation -Encoding UTF8
$base = @{}
$after = @{}
foreach ($x in $src) {
    $key = ('{0}|{1}' -f $x.SheetIndex,$x.ObjectID)
    Assert-Sad (-not $base.ContainsKey($key)) ('BLOCKED_DUPLICATE_SOURCE_ID_'+$key)
    $base[$key]=$x
}
foreach ($x in $dst) {
    $key = ('{0}|{1}' -f $x.SheetIndex,$x.ObjectID)
    Assert-Sad (-not $after.ContainsKey($key)) ('BLOCKED_DUPLICATE_TARGET_ID_'+$key)
    $after[$key]=$x
}
$added=@($after.Keys|Where-Object {-not $base.ContainsKey($_)}|Sort-Object|ForEach-Object {$after[$_]})
$removed=@($base.Keys|Where-Object {-not $after.ContainsKey($_)}|Sort-Object|ForEach-Object {$base[$_]})
$typeChanged=@($base.Keys|Where-Object {$after.ContainsKey($_) -and $base[$_].ObjectType -ne $after[$_].ObjectType}|Sort-Object|ForEach-Object {
    [pscustomobject]@{key=$_;old=$base[$_].ObjectType;new=$after[$_].ObjectType}
})
$textChanged=@($base.Keys|Where-Object {
    $after.ContainsKey($_) -and $base[$_].ObjectType -eq 6 -and
    $null -ne $base[$_].TextExpression -and $null -ne $after[$_].TextExpression -and
    $base[$_].TextExpression -cne $after[$_].TextExpression
}|Sort-Object|ForEach-Object {$_})
$ch03 = @($dst | Where-Object {$_.ObjectID -eq 'CH03'})
$structuralPass = $added.Count -eq 1 -and $added[0].ObjectType -eq 6 -and
                  $removed.Count -eq 0 -and $typeChanged.Count -eq 0 -and
                  $textChanged.Count -eq 0 -and $ch03.Count -gt 0
$verdict = if($structuralPass){'PASS_OBJECT_ID_TYPE_INVENTORY_ONLY_REVIEW_LAYOUT_XML'} else {'INCONCLUSIVE_OR_DRIFT_OBJECT_INVENTORY'}
$report=[ordered]@{
    gate=$gate;protected25Unchanged=$protectedOk;timestamp_utc=[DateTime]::UtcNow.ToString('o');repoHead=$head
    scriptSha256=Sha256 $actualScript;sourceSha256=$sourceShaExpected;targetSha256=$targetShaExpected
    sourceCount=$src.Count;targetCount=$dst.Count
    added=@($added);removed=@($removed);typeChanged=@($typeChanged)
    existingTextExpressionChangedKeys=@($textChanged)
    ch03PresentInTarget=$ch03.Count
    exportSource=$left.layout;exportTarget=$right.layout
    verdict=$verdict
    caveat='Inventory confirms ID/type deltas only. Does not certify unchanged all chart expressions/metadata, save count or contemporaneous GUI capture.'
}
$report|ConvertTo-Json -Depth 15|Set-Content -LiteralPath (Join-Path $folder 'object_audit_report.json') -Encoding UTF8
Write-Output ('SOURCE_OBJECT_COUNT='+$src.Count)
Write-Output ('TARGET_OBJECT_COUNT='+$dst.Count)
Write-Output ('ADDED_OBJECT_IDS='+(@($added|ForEach-Object {$_.ObjectID}) -join ','))
Write-Output ('REMOVED_OBJECT_IDS='+(@($removed|ForEach-Object {$_.ObjectID}) -join ','))
Write-Output ('TYPE_CHANGED_COUNT='+$typeChanged.Count)
Write-Output ('EXISTING_TEXT_CHANGED_COUNT='+$textChanged.Count)
Write-Output ('LAYOUT_SOURCE_EXPORT='+$left.layout.status)
Write-Output ('LAYOUT_TARGET_EXPORT='+$right.layout.status)
Write-Output ('OBJECT_AUDIT_VERDICT='+$verdict)
Write-Output ('OBJECT_AUDIT_DIR='+$folder)
# QVW copies remain in evidence folder, not included in ZIP.
$zip=Join-Path $evidence ((Split-Path -Leaf $folder)+'.zip')
$attachments=@('source_objects.csv','target_objects.csv','object_audit_report.json')
foreach($candidate in @('source_layout.xml','target_layout.xml')) {
    if(Test-Path -LiteralPath (Join-Path $folder $candidate) -PathType Leaf){$attachments+= $candidate}
}
Compress-Archive -LiteralPath @($attachments|ForEach-Object {Join-Path $folder $_}) -DestinationPath $zip -ErrorAction Stop
Write-Output ('AUDIT_METADATA_ZIP='+$zip)
Write-Output ('AUDIT_METADATA_ZIP_SHA256='+(Sha256 $zip))
Write-Output 'SAVE_CALLS=0 RELOAD_CALLS=0 SELECT_CALLS=0 SETPROPERTIES_CALLS=0'
Write-Output 'GATE_STRICT_ACCEPTANCE=NOT_EVALUATED_BY_THIS_SCRIPT'
