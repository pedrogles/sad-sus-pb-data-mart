# SAD-C2-R2-FINAL-QVW-FORENSIC-READONLY-01
# Read-only forensic inventory for #222 SOURCE -> F1/F2 consolidated TEMP.
# Windows PowerShell 5.1 + QlikView 12.0.20000.0 COM; no Save, SaveAs, Reload,
# Select, ClearAll, SetProperties, or modification of QVD/QVW inputs.
# Must be committed in the project branch before execution; one run only.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Root)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gate = 'SAD-C2-R2-FINAL-QVW-FORENSIC-READONLY-01'
$branch = 'test/sad-c2-r2-final-consolidation-20261105'
$scriptRel = 'tools/Inspect-SadC2R2FinalQvwReadOnly.ps1'
$expectedBase = '98f063abb68f3935b51349f979da009a441ce43f'
$runId = 'SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321'
$shaSrc = 'C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D'
$shaDst = '6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58'
$src = Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_CH03_H1_RUNTIME\SAD_C2_P12_CH03_H1_c70f6c392ca44f53900a92c0cc601073\SAD_C2_R2_P12_CH03_NATIVE_H1_TEMP.qvw'
$dst = Join-Path $env:USERPROFILE ("Documents\SAD_C2_FINAL_RUNTIME_20261105\$runId\SAD_C2_R2_FINAL_CONSOLIDATION_TEMP.qvw")
$ev = Join-Path $env:USERPROFILE ("Documents\SAD_C2_FINAL_EVIDENCE_20261105\$runId")

function Assert-Sad([bool]$ok,[string]$reason) { if(-not $ok) { throw $reason } }
function Full([string]$p) {
    Assert-Sad ([IO.Path]::IsPathRooted($p)) 'BLOCKED_ABSOLUTE_PATH_REQUIRED'
    return [IO.Path]::GetFullPath($p).TrimEnd('\','/')
}
function Under([string]$child,[string]$parent) {
    $sep = [string][IO.Path]::DirectorySeparatorChar
    return $child.StartsWith($parent+$sep,[StringComparison]::OrdinalIgnoreCase)
}
function Hash([string]$p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant() }
function Release-Com([object]$obj) {
    if($null -ne $obj -and [Runtime.InteropServices.Marshal]::IsComObject($obj)) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($obj)
    }
}
function Protected([string]$repo) {
    $extract = Join-Path $repo 'EXTRACAO\QVD'
    $transform = Join-Path $repo 'TRANSFORMACAO\QVD'
    Assert-Sad (Test-Path -LiteralPath $extract -PathType Container) 'BLOCKED_EXTRACAO_QVD_DIR'
    Assert-Sad (Test-Path -LiteralPath $transform -PathType Container) 'BLOCKED_TRANSFORMACAO_QVD_DIR'
    $a = @(Get-ChildItem -LiteralPath $extract -File -Filter '*.qvd')
    $b = @(Get-ChildItem -LiteralPath $transform -File -Filter '*.qvd')
    Assert-Sad ($a.Count -eq 10 -and $b.Count -eq 12) 'BLOCKED_EXPECTED_10_12_QVD'
    $all = @($a) + @($b)
    foreach($rel in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
        $p = Join-Path $repo $rel
        Assert-Sad (Test-Path -LiteralPath $p -PathType Leaf) 'BLOCKED_PROTECTED_QVW_MISSING'
        $all += @(Get-Item -LiteralPath $p)
    }
    Assert-Sad ($all.Count -eq 25) 'BLOCKED_PROTECTED_COUNT'
    return @($all | Sort-Object FullName | ForEach-Object {
        $_.FullName + '|' + [string]$_.Length + '|' + (Hash $_.FullName)
    })
}
function ObjectId([string]$raw) {
    # QlikView COM returns 'Document\CH03' on some builds. Strip that prefix
    # exclusively for comparison; preserve raw IDs in CSV.
    return ($raw -replace '^(?i:Document[\\/])','')
}
function Inventory([object]$app,[string]$p,[string]$label,[string]$auditDir) {
    $doc = $null
    $rows = New-Object 'System.Collections.Generic.List[object]'
    $layoutStatus = 'NOT_ATTEMPTED'
    $layoutSha = $null
    try {
        $doc = $app.OpenDoc($p,'','')
        Assert-Sad ($null -ne $doc) ('BLOCKED_COM_OPENDOC_'+$label)
        $sheets = [int]$doc.NoOfSheets()
        Assert-Sad ($sheets -ge 1 -and $sheets -le 50) ('BLOCKED_SHEET_COUNT_'+$label)
        for($i=0; $i -lt $sheets; $i++) {
            $sheet = $null
            try {
                $sheet = $doc.GetSheet($i)
                Assert-Sad ($null -ne $sheet) ('BLOCKED_SHEET_NULL_'+$label+'_'+$i)
                $sheetId = 'INDEX_'+$i
                try { $sheetId = [string]$sheet.GetObjectID() } catch {}
                $count = [int]$sheet.NoOfSheetObjects()
                Assert-Sad ($count -ge 0 -and $count -le 2000) ('BLOCKED_OBJECT_COUNT_'+$label)
                for($j=0; $j -lt $count; $j++) {
                    $obj = $null
                    try {
                        $obj = $sheet.SheetObjects($j)
                        Assert-Sad ($null -ne $obj) ('BLOCKED_OBJECT_NULL_'+$label)
                        $raw = [string]$obj.GetObjectID()
                        $id = ObjectId $raw
                        $typ = [int]$obj.GetObjectType()
                        Assert-Sad (-not [string]::IsNullOrWhiteSpace($id)) 'BLOCKED_OBJECT_ID_EMPTY'
                        $txt = $null
                        if($typ -eq 6) { try { $txt = [string]$obj.GetProperties().Layout.Text.v } catch {} }
                        [void]$rows.Add([pscustomobject][ordered]@{
                            SheetIndex=$i;SheetID=$sheetId;ObjectID=$id;RawObjectID=$raw
                            ObjectType=$typ;TextExpression=$txt
                        })
                    } finally { Release-Com $obj }
                }
            } finally { Release-Com $sheet }
        }
        $layout = Join-Path $auditDir ($label+'_layout.xml')
        try {
            [void]$doc.ExportLayoutFile($layout)
            if(Test-Path -LiteralPath $layout -PathType Leaf) {
                $layoutStatus = 'EXPORTED'; $layoutSha = Hash $layout
            } else { $layoutStatus = 'EXPORT_RETURNED_NO_FILE' }
        } catch { $layoutStatus = 'API_ERROR: '+$_.Exception.Message }
        Assert-Sad ($rows.Count -gt 0) ('BLOCKED_NO_OBJECTS_'+$label)
        return [pscustomobject]@{Rows=@($rows.ToArray());ExportStatus=$layoutStatus;LayoutSha=$layoutSha}
    } finally {
        if($null -ne $doc) {
            try { [void]$doc.CloseDoc() } catch { Write-Warning ('COM_CLOSEDOC_'+$label+': '+$_.Exception.Message) }
            Release-Com $doc
        }
    }
}

Assert-Sad ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) 'BLOCKED_WINDOWS_REQUIRED'
$repo = Full $Root; $src = Full $src; $dst = Full $dst; $ev = Full $ev
$self = Full (Join-Path $repo $scriptRel)
Assert-Sad ($self -ieq (Full $PSCommandPath)) 'BLOCKED_SCRIPT_LOCATION'
Assert-Sad (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf) 'BLOCKED_REPO_ROOT'
Assert-Sad (-not (Under $src $repo) -and -not (Under $dst $repo) -and -not (Under $ev $repo)) 'BLOCKED_LOCAL_QVW_INSIDE_REPO'
Assert-Sad ($src -ine $dst) 'BLOCKED_SAME_SOURCE_TARGET'
Assert-Sad (Test-Path -LiteralPath $ev -PathType Container) 'BLOCKED_EVIDENCE_DIR'
foreach($p in @($src,$dst)) { Assert-Sad (Test-Path -LiteralPath $p -PathType Leaf) 'BLOCKED_QVW_NOT_FOUND' }
$verifyPath = Join-Path $ev 'c2_r2_final_verify.json'
Assert-Sad (Test-Path -LiteralPath $verifyPath -PathType Leaf) 'BLOCKED_PREVIOUS_VERIFY_REQUIRED'
$verify = Get-Content -LiteralPath $verifyPath -Raw | ConvertFrom-Json
Assert-Sad ($verify.RunId -ceq $runId -and $verify.Protected25Unchanged -and
    $verify.SourceUnchanged -and $verify.TempCopyChanged -and $verify.EvidenceInventoryComplete -and
    $verify.CopyAfterSha256 -ceq $shaDst) 'BLOCKED_PREVIOUS_VERIFY_MISMATCH'
Assert-Sad (@(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(qv|qlikview)$' }).Count -eq 0) 'BLOCKED_CLOSE_QLIKVIEW_FIRST'
$exe = 'C:\Program Files\QlikView\Qv.exe'
Assert-Sad (Test-Path -LiteralPath $exe -PathType Leaf) 'BLOCKED_QLIK_EXE'
Assert-Sad (([string](Get-Item -LiteralPath $exe).VersionInfo.FileVersion) -ceq '12.0.20000.0') 'BLOCKED_QLIK_BUILD_DRIFT'
$head = ([string](& git -C $repo rev-parse --verify HEAD)).Trim()
Assert-Sad ($LASTEXITCODE -eq 0 -and $head -match '^[0-9a-f]{40}$') 'BLOCKED_GIT_HEAD'
$actualBranch = ([string](& git -C $repo branch --show-current)).Trim()
Assert-Sad ($LASTEXITCODE -eq 0 -and $actualBranch -ceq $branch) 'BLOCKED_WRONG_BRANCH'
& git -C $repo merge-base --is-ancestor $expectedBase HEAD
Assert-Sad ($LASTEXITCODE -eq 0) 'BLOCKED_BASE_NOT_ANCESTOR'
$tracked = @(& git -C $repo ls-files --error-unmatch -- $scriptRel 2>$null)
Assert-Sad ($LASTEXITCODE -eq 0 -and $tracked.Count -eq 1) 'BLOCKED_RUNNER_NOT_COMMITTED'
Assert-Sad (@(& git -C $repo status --porcelain --untracked-files=all).Count -eq 0) 'BLOCKED_DIRTY_WORKTREE'
# Require that local executable matches tracked bytes in HEAD, not just a file in working tree.
$scriptSha = Hash $self
$headBlob = ([string](& git -C $repo rev-parse ("HEAD:"+$scriptRel))).Trim()
Assert-Sad ($LASTEXITCODE -eq 0 -and $headBlob -match '^[0-9a-f]{40}$') 'BLOCKED_RUNNER_NOT_IN_HEAD'
Assert-Sad ((Hash $src) -ceq $shaSrc) 'HARD_STOP_SOURCE_HASH_DRIFT'
Assert-Sad ((Hash $dst) -ceq $shaDst) 'HARD_STOP_TARGET_HASH_DRIFT'
$protectedBefore = @(Protected $repo)
$preparePath = Join-Path $ev 'c2_r2_final_prepare.json'
Assert-Sad (Test-Path -LiteralPath $preparePath -PathType Leaf) 'BLOCKED_PREPARE_MANIFEST_REQUIRED'
$prepare = Get-Content -LiteralPath $preparePath -Raw | ConvertFrom-Json
Assert-Sad ($prepare.RunId -ceq $runId -and $prepare.SourceSha256 -ceq $shaSrc) 'BLOCKED_PREPARE_ID_OR_SOURCE_SHA'
$baselineProtected = @($prepare.ProtectedBefore | ForEach-Object { [string]$_ })
Assert-Sad ($baselineProtected.Count -eq 25) 'BLOCKED_PREPARE_PROTECTED_COUNT'
Assert-Sad (($baselineProtected -join [Environment]::NewLine) -ceq
    ($protectedBefore -join [Environment]::NewLine)) 'HARD_STOP_PROTECTED_DRIFT_SINCE_PREPARE'

$audit = Join-Path $ev ('FINAL_FORENSIC_' + [guid]::NewGuid().ToString('N'))
Assert-Sad (@(Get-ChildItem -LiteralPath $ev -Directory -Filter 'FINAL_FORENSIC_*').Count -eq 0) 'BLOCKED_ALREADY_AUDITED_ONCE'
$null = New-Item -Path $audit -ItemType Directory -ErrorAction Stop
$srcCopy = Join-Path $audit 'source_audit_copy_readonly.qvw'
$dstCopy = Join-Path $audit 'target_audit_copy_readonly.qvw'
Copy-Item -LiteralPath $src -Destination $srcCopy -ErrorAction Stop
Copy-Item -LiteralPath $dst -Destination $dstCopy -ErrorAction Stop
Assert-Sad ((Hash $srcCopy) -ceq $shaSrc -and (Hash $dstCopy) -ceq $shaDst) 'HARD_STOP_AUDIT_COPY_HASH_DRIFT'
(Get-Item -LiteralPath $srcCopy).IsReadOnly = $true
(Get-Item -LiteralPath $dstCopy).IsReadOnly = $true

$app=$null; $left=$null; $right=$null; $failure=$null
try {
    $app = New-Object -ComObject 'QlikTech.QlikView'
    $left = Inventory $app $srcCopy 'source' $audit
    $right = Inventory $app $dstCopy 'target' $audit
} catch { $failure = $_.Exception.Message }
finally {
    Release-Com $app
    $safe = ((Hash $src) -ceq $shaSrc) -and ((Hash $dst) -ceq $shaDst) -and
            ((Hash $srcCopy) -ceq $shaSrc) -and ((Hash $dstCopy) -ceq $shaDst)
    $protectedAfter = @(Protected $repo)
    $protectedOk = (($protectedBefore -join [Environment]::NewLine) -ceq ($protectedAfter -join [Environment]::NewLine))
    Write-Output ('PROTECTED_25_UNCHANGED='+$protectedOk)
    Write-Output ('ORIGINAL_AND_AUDIT_COPIES_UNCHANGED='+$safe)
    Assert-Sad $protectedOk 'HARD_STOP_PROTECTED_25_CHANGED'
    Assert-Sad $safe 'HARD_STOP_QVW_INPUT_HASH_CHANGED'
}
if($null -ne $failure) { throw ('BLOCKED_COM_OBJECT_AUDIT_'+$failure) }

$base=@{}; $after=@{}
foreach($x in @($left.Rows)) {
    $key = [string]$x.SheetIndex+'|'+[string]$x.ObjectID
    Assert-Sad (-not $base.ContainsKey($key)) ('BLOCKED_DUPLICATE_SOURCE_ID_'+$key)
    $base[$key]=$x
}
foreach($x in @($right.Rows)) {
    $key = [string]$x.SheetIndex+'|'+[string]$x.ObjectID
    Assert-Sad (-not $after.ContainsKey($key)) ('BLOCKED_DUPLICATE_TARGET_ID_'+$key)
    $after[$key]=$x
}
$added = @($after.Keys | Where-Object {-not $base.ContainsKey($_)} | Sort-Object)
$removed = @($base.Keys | Where-Object {-not $after.ContainsKey($_)} | Sort-Object)
$typeChanged = @($base.Keys | Where-Object {$after.ContainsKey($_) -and $base[$_].ObjectType -ne $after[$_].ObjectType} | Sort-Object)
$textChanged = @($base.Keys | Where-Object {$after.ContainsKey($_) -and $base[$_].TextExpression -cne $after[$_].TextExpression} | Sort-Object)
$sourceCount = @($left.Rows).Count; $targetCount = @($right.Rows).Count
$expectedIds = @('CH02','CH03','TX17')
$targetSet = @($after.Keys | ForEach-Object { ($_ -split '\|',2)[1] })
$present = [ordered]@{}
foreach($id in $expectedIds) { $present[$id] = @($targetSet | Where-Object { $_ -ceq $id }).Count -eq 1 }
$unchangedIdSet = ($added.Count -eq 0 -and $removed.Count -eq 0 -and $typeChanged.Count -eq 0)
$inventoryVerdict = if($unchangedIdSet -and $sourceCount -eq 38 -and $targetCount -eq 38 -and
    $present['CH02'] -and $present['CH03'] -and $present['TX17']) {
    'PASS_ID_TYPE_INVENTORY_ONLY'
} else { 'INCONCLUSIVE_OR_DRIFT_INVENTORY' }
@($left.Rows) | Export-Csv -LiteralPath (Join-Path $audit 'source_objects.csv') -NoTypeInformation -Encoding UTF8
@($right.Rows) | Export-Csv -LiteralPath (Join-Path $audit 'target_objects.csv') -NoTypeInformation -Encoding UTF8
$report = [ordered]@{
    Gate=$gate; RunId=$runId; RepoHead=$head; RunnerSha256=$scriptSha
    SourceSha256=$shaSrc; TargetSha256=$shaDst; Protected25Unchanged=$protectedOk
    SourceObjects=$sourceCount; TargetObjects=$targetCount
    AddedKeys=$added; RemovedKeys=$removed; TypeChangedKeys=$typeChanged; ExistingTextChangedKeys=$textChanged
    RequiredObjectIdsPresent=$present; SourceLayoutExport=$left.ExportStatus; TargetLayoutExport=$right.ExportStatus
    SourceLayoutSha256=$left.LayoutSha; TargetLayoutSha256=$right.LayoutSha
    InventoryVerdict=$inventoryVerdict; FullPropertyComparison='NOT_PERFORMED_BY_RUNNER'
    GeometryAndZOrderVerdict='NOT_ASSESSED_BY_RUNNER'; SaveCount='UNVERIFIED'
    ProductionApproved=$false; RecordedAtUtc=[DateTime]::UtcNow.ToString('o')
}
$report | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath (Join-Path $audit 'final_forensic_report.json') -Encoding UTF8
$names = @('source_objects.csv','target_objects.csv','final_forensic_report.json')
foreach($n in @('source_layout.xml','target_layout.xml')) {
    if(Test-Path -LiteralPath (Join-Path $audit $n) -PathType Leaf) { $names += $n }
}
$zip = Join-Path $ev ('FINAL_FORENSIC_' + $runId + '_metadata.zip')
Assert-Sad (-not (Test-Path -LiteralPath $zip)) 'BLOCKED_ZIP_ALREADY_EXISTS'
Compress-Archive -LiteralPath @($names | ForEach-Object {Join-Path $audit $_}) -DestinationPath $zip -ErrorAction Stop
Write-Output ('GATE='+$gate)
Write-Output ('GIT_HEAD='+$head)
Write-Output ('RUNNER_SHA256='+$scriptSha)
Write-Output ('SOURCE_OBJECT_COUNT='+$sourceCount)
Write-Output ('TARGET_OBJECT_COUNT='+$targetCount)
Write-Output ('ADDED_COUNT='+$added.Count)
Write-Output ('REMOVED_COUNT='+$removed.Count)
Write-Output ('TYPE_CHANGED_COUNT='+$typeChanged.Count)
Write-Output ('TEXT_CHANGED_COUNT='+$textChanged.Count)
Write-Output ('CH02_PRESENT='+$present['CH02'])
Write-Output ('CH03_PRESENT='+$present['CH03'])
Write-Output ('TX17_PRESENT='+$present['TX17'])
Write-Output ('SOURCE_LAYOUT_EXPORT='+$left.ExportStatus)
Write-Output ('TARGET_LAYOUT_EXPORT='+$right.ExportStatus)
Write-Output ('OBJECT_INVENTORY_VERDICT='+$inventoryVerdict)
Write-Output ('AUDIT_METADATA_ZIP='+$zip)
Write-Output ('AUDIT_METADATA_ZIP_SHA256='+(Hash $zip))
Write-Output 'SAVE_CALLS=0 RELOAD_CALLS=0 SELECT_CALLS=0 SETPROPERTIES_CALLS=0'
Write-Output 'GATE_STRICT_ACCEPTANCE=NOT_EVALUATED_BY_THIS_SCRIPT'
