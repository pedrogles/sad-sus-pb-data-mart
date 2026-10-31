# SAD-C2-GUIDED-DYNAMIC-DISPATCH-POC-01
# Windows PowerShell 5.1; safety wrapper for ONE TEMP QVW, no QlikView launch/COM/reload/GUI automation.
# Prepare copies a pinned input; Verify audits source and protected files after operator interaction.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$SourceQvw,
    [Parameter(Mandatory=$true)][string]$QlikExe,
    [Parameter(Mandatory=$true)][string]$RuntimeRoot,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [switch]$Prepare,
    [switch]$Verify,
    [string]$RunDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gate = 'SAD-C2-GUIDED-DYNAMIC-DISPATCH-POC-01'
$relativeScript = 'tools/Invoke-SadC2GuidedDynamicDispatchPoc01.ps1'
$requiredBranch = 'test/sad-c2-guided-dynamic-dispatch-poc-20261031'
$requiredBase = '238d4f70c5cf4576808fdd43af4a3d72b4e0b7cc'
$sourceFileName = 'SAD_P11P12_VISUAL_POLISH_COPY.qvw'
$expectedSourceSha = 'B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C'
$copyFileName = 'SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw'

function Assert-Sad([bool]$condition, [string]$failure) {
    if (-not $condition) { throw $failure }
}
function Resolve-SadAbsolute([string]$path) {
    Assert-Sad ([IO.Path]::IsPathRooted($path)) 'BLOCKED_ABSOLUTE_PATH_REQUIRED'
    return [IO.Path]::GetFullPath($path).TrimEnd('\','/')
}
function Test-SadInside([string]$child,[string]$parent) {
    $separator = [string][IO.Path]::DirectorySeparatorChar
    return ($child -ieq $parent -or $child.StartsWith($parent+$separator,[StringComparison]::OrdinalIgnoreCase))
}
function Get-SadHash([string]$path) {
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Get-SadProtected([string]$repoPath) {
    $extractQvd = Join-Path $repoPath 'EXTRACAO\QVD'
    $transformQvd = Join-Path $repoPath 'TRANSFORMACAO\QVD'
    Assert-Sad (Test-Path -LiteralPath $extractQvd -PathType Container) 'BLOCKED_EXTRACTION_QVD_DIR_MISSING'
    Assert-Sad (Test-Path -LiteralPath $transformQvd -PathType Container) 'BLOCKED_TRANSFORMATION_QVD_DIR_MISSING'
    $a = @(Get-ChildItem -LiteralPath $extractQvd -File -Filter '*.qvd')
    $b = @(Get-ChildItem -LiteralPath $transformQvd -File -Filter '*.qvd')
    Assert-Sad ($a.Count -eq 10 -and $b.Count -eq 12) 'BLOCKED_EXPECTED_10_12_QVDS'
    $protected = @($a) + @($b)
    foreach ($rel in @('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')) {
        $full = Join-Path $repoPath $rel
        Assert-Sad (Test-Path -LiteralPath $full -PathType Leaf) 'BLOCKED_CANONICAL_QVW_MISSING'
        $protected += @(Get-Item -LiteralPath $full)
    }
    Assert-Sad ($protected.Count -eq 25) 'BLOCKED_PROTECTED_COUNT_NOT_25'
    return @($protected | Sort-Object FullName | ForEach-Object {
        '{0}|{1}|{2}' -f $_.FullName,([long]$_.Length),(Get-SadHash $_.FullName)
    })
}

Assert-Sad ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) 'BLOCKED_WINDOWS_REQUIRED'
Assert-Sad ($Prepare.IsPresent -ne $Verify.IsPresent) 'BLOCKED_SELECT_ONE_MODE'
$repo = Resolve-SadAbsolute $Root
$source = Resolve-SadAbsolute $SourceQvw
$qlik = Resolve-SadAbsolute $QlikExe
$runtime = Resolve-SadAbsolute $RuntimeRoot
$evidence = Resolve-SadAbsolute $EvidenceRoot
$self = Resolve-SadAbsolute (Join-Path $repo $relativeScript)
Assert-Sad ($self -ieq (Resolve-SadAbsolute $PSCommandPath)) 'BLOCKED_USE_VERSIONED_REPO_SCRIPT'
Assert-Sad (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf) 'BLOCKED_NOT_REPO_ROOT'
foreach ($external in @($source,$runtime,$evidence)) {
    Assert-Sad (-not (Test-SadInside $external $repo)) 'BLOCKED_INPUT_OR_OUTPUT_INSIDE_REPO'
    Assert-Sad (-not (Test-SadInside $repo $external)) 'BLOCKED_REPO_INSIDE_INPUT_OR_OUTPUT'
}
Assert-Sad (-not (Test-SadInside $runtime $evidence) -and -not (Test-SadInside $evidence $runtime)) 'BLOCKED_RUNTIME_EVIDENCE_OVERLAP'
Assert-Sad (-not (Test-SadInside $source $runtime) -and -not (Test-SadInside $source $evidence)) 'BLOCKED_SOURCE_INSIDE_OUTPUT'
foreach ($folder in @($runtime,$evidence)) {
    Assert-Sad (Test-Path -LiteralPath $folder -PathType Container) 'BLOCKED_OUTPUT_ROOT_MUST_EXIST'
}
Assert-Sad (Test-Path -LiteralPath $source -PathType Leaf) 'BLOCKED_SOURCE_NOT_FOUND'
Assert-Sad ([IO.Path]::GetFileName($source) -ceq $sourceFileName) 'BLOCKED_WRONG_SOURCE_FILENAME'
Assert-Sad (Test-Path -LiteralPath $qlik -PathType Leaf) 'BLOCKED_QLIK_EXE_MISSING'
Assert-Sad ([IO.Path]::GetFileName($qlik) -ieq 'Qv.exe') 'BLOCKED_WRONG_EXE_NAME'
$qvVersion = [string](Get-Item -LiteralPath $qlik).VersionInfo.ProductVersion
Assert-Sad ($qvVersion -match '^12(\.|$)') 'BLOCKED_QLIKVIEW_12_NOT_CONFIRMED'
$running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -match '^(qv|qlikview)$'})
Assert-Sad ($running.Count -eq 0) 'BLOCKED_CLOSE_QLIKVIEW_FIRST'
$head = ([string](& git -C $repo rev-parse --verify HEAD)).Trim()
Assert-Sad ($LASTEXITCODE -eq 0 -and $head -match '^[0-9a-f]{40}$') 'BLOCKED_GIT_HEAD'
$branch = ([string](& git -C $repo branch --show-current)).Trim()
Assert-Sad ($LASTEXITCODE -eq 0 -and $branch -ceq $requiredBranch) 'BLOCKED_WRONG_BRANCH'
& git -C $repo merge-base --is-ancestor $requiredBase HEAD
Assert-Sad ($LASTEXITCODE -eq 0) 'BLOCKED_BASE_NOT_ANCESTOR'
$tracked = @(& git -C $repo ls-files --error-unmatch -- $relativeScript 2>$null)
Assert-Sad ($LASTEXITCODE -eq 0 -and $tracked.Count -eq 1) 'BLOCKED_SCRIPT_NOT_COMMITTED'
$dirty = @(& git -C $repo status --porcelain --untracked-files=all)
Assert-Sad ($LASTEXITCODE -eq 0 -and $dirty.Count -eq 0) 'BLOCKED_WORKTREE_NOT_CLEAN'
$sourceSha = Get-SadHash $source
Assert-Sad ($sourceSha -ceq $expectedSourceSha) 'HARD_STOP_SOURCE_HASH_DRIFT'
$runnerSha = Get-SadHash $self
Write-Output ('GATE=' + $gate)
Write-Output ('GIT_HEAD=' + $head)
Write-Output ('RUNNER_SHA256=' + $runnerSha)
Write-Output ('SOURCE_SHA256=' + $sourceSha)
Write-Output ('QV_PRODUCT_VERSION=' + $qvVersion)
Write-Output 'QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0'

if ($Prepare.IsPresent) {
    Assert-Sad ([string]::IsNullOrWhiteSpace($RunDir)) 'BLOCKED_RUNDIR_ONLY_FOR_VERIFY'
    $before = @(Get-SadProtected $repo)
    $runId = 'SAD_C2_DYNAMIC_' + [guid]::NewGuid().ToString('N')
    $runRuntime = Join-Path $runtime $runId
    $runEvidence = Join-Path $evidence $runId
    $copy = Join-Path $runRuntime $copyFileName
    Assert-Sad (-not (Test-Path -LiteralPath $runRuntime)) 'BLOCKED_RUNTIME_COLLISION'
    Assert-Sad (-not (Test-Path -LiteralPath $runEvidence)) 'BLOCKED_EVIDENCE_COLLISION'
    $null = New-Item -ItemType Directory -Path $runRuntime -ErrorAction Stop
    $null = New-Item -ItemType Directory -Path $runEvidence -ErrorAction Stop
    try {
        Copy-Item -LiteralPath $source -Destination $copy -ErrorAction Stop
        Assert-Sad ((Get-SadHash $copy) -ceq $expectedSourceSha) 'HARD_STOP_TEMP_COPY_HASH'
        $manifestPath = Join-Path $runEvidence 'dispatch_prepare.json'
        [ordered]@{
            Gate=$gate; RunId=$runId; GitHead=$head; GitBranch=$branch; RunnerSha256=$runnerSha
            SourceQvw=$source; SourceSha256=$sourceSha; QlikExe=$qlik; QlikProductVersion=$qvVersion
            RuntimeRoot=$runtime; EvidenceRoot=$evidence; CopyQvw=$copy; CopyBeforeSha256=$sourceSha
            ProtectedBefore=$before; PhysicalScenario='NOT_RUN'; ProductionApproved=$false
        } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    }
    finally {
        $after = @(Get-SadProtected $repo)
        Assert-Sad (($before -join [Environment]::NewLine) -ceq ($after -join [Environment]::NewLine)) 'HARD_STOP_PROTECTED_FILES_CHANGED_IN_PREPARE'
        Assert-Sad ((Get-SadHash $source) -ceq $expectedSourceSha) 'HARD_STOP_SOURCE_CHANGED_IN_PREPARE'
    }
    Write-Output ('RUNTIME_COPY=' + $copy)
    Write-Output ('EVIDENCE_DIR=' + $runEvidence)
    Write-Output 'VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI'
    return
}

Assert-Sad (-not [string]::IsNullOrWhiteSpace($RunDir)) 'BLOCKED_RUNDIR_REQUIRED'
$runEvidence = Resolve-SadAbsolute $RunDir
Assert-Sad ((Test-SadInside $runEvidence $evidence) -and $runEvidence -ine $evidence) 'BLOCKED_INVALID_EVIDENCE_RUN_DIR'
Assert-Sad (Test-Path -LiteralPath $runEvidence -PathType Container) 'BLOCKED_EVIDENCE_RUN_DIR_MISSING'
$manifestPath = Join-Path $runEvidence 'dispatch_prepare.json'
Assert-Sad (Test-Path -LiteralPath $manifestPath -PathType Leaf) 'BLOCKED_PREPARE_MANIFEST_MISSING'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
Assert-Sad ($manifest.Gate -ceq $gate -and $manifest.GitHead -ceq $head -and
    $manifest.GitBranch -ceq $branch -and $manifest.RunnerSha256 -ceq $runnerSha) 'BLOCKED_MANIFEST_GIT_OR_RUNNER_MISMATCH'
Assert-Sad ($manifest.SourceQvw -ieq $source -and $manifest.SourceSha256 -ceq $expectedSourceSha -and
    $manifest.QlikExe -ieq $qlik -and $manifest.RuntimeRoot -ieq $runtime -and
    $manifest.EvidenceRoot -ieq $evidence) 'BLOCKED_MANIFEST_INPUT_MISMATCH'
Assert-Sad ($manifest.RunId -ceq [IO.Path]::GetFileName($runEvidence)) 'BLOCKED_RUN_ID_MISMATCH'
$copy = Resolve-SadAbsolute ([string]$manifest.CopyQvw)
Assert-Sad ((Test-SadInside $copy $runtime) -and
    ([IO.Path]::GetFileName($copy) -ceq $copyFileName) -and
    ((Split-Path -Parent $copy) -ieq (Join-Path $runtime ([string]$manifest.RunId))) -and
    (Test-Path -LiteralPath $copy -PathType Leaf)) 'BLOCKED_TEMP_COPY_INVALID'
Assert-Sad ($manifest.CopyBeforeSha256 -ceq $expectedSourceSha) 'BLOCKED_COPY_BEFORE_HASH_MISMATCH'
$verifyEvidencePath = Join-Path $runEvidence 'dispatch_verify.json'
Assert-Sad (-not (Test-Path -LiteralPath $verifyEvidencePath)) 'BLOCKED_VERIFY_ALREADY_RECORDED'
$protectedBefore = @($manifest.ProtectedBefore | ForEach-Object { [string]$_ })
$protectedAfter = @(Get-SadProtected $repo)
$protectedOk = (($protectedBefore -join [Environment]::NewLine) -ceq ($protectedAfter -join [Environment]::NewLine))
$sourceOk = ((Get-SadHash $source) -ceq $expectedSourceSha)
$copyAfterSha = Get-SadHash $copy
$copyChanged = ($copyAfterSha -cne $expectedSourceSha) # Expected only if the TEMP candidate was edited/saved.
Write-Output ('PROTECTED_25_UNCHANGED=' + $protectedOk)
Write-Output ('SOURCE_UNCHANGED=' + $sourceOk)
Write-Output ('COPY_CHANGED_FROM_SOURCE=' + $copyChanged)
Write-Output ('COPY_SHA256=' + $copyAfterSha)
Assert-Sad ($protectedOk -and $sourceOk) 'HARD_STOP_PROTECTED_OR_SOURCE_CHANGED'
$guiEvidence = @('gui_before.png','gui_condition_action.png','gui_after.png','gui_notes.txt')
$missing = @($guiEvidence | Where-Object {-not (Test-Path -LiteralPath (Join-Path $runEvidence $_) -PathType Leaf)})
[ordered]@{
    Gate=$gate; RunId=$manifest.RunId; GitHead=$head; RunnerSha256=$runnerSha
    Protected25Unchanged=$protectedOk; SourceUnchanged=$sourceOk
    CopyBeforeSha256=$expectedSourceSha; CopyAfterSha256=$copyAfterSha; TempCopyChanged=$copyChanged
    GuiEvidenceMissing=$missing; GuiVerdict='NOT_ASSESSED_BY_RUNNER'
    Verdict='PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI'
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $verifyEvidencePath -Encoding UTF8
Write-Output ('GUI_EVIDENCE_MISSING=' + ($missing -join ','))
Write-Output ('EVIDENCE_DIR=' + $runEvidence)
Write-Output 'VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI'
