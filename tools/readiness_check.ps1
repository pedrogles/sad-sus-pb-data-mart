param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [string]$DataRoot = "",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

function New-Check {
    param(
        [string]$Id,
        [string]$Name,
        [string]$Status,
        [string]$Detail
    )
    [PSCustomObject]@{
        id = $Id
        name = $Name
        status = $Status
        detail = $Detail
    }
}

function Find-Python {
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        return [PSCustomObject]@{ exe = $py.Source; args = @("-3") }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return [PSCustomObject]@{ exe = $python.Source; args = @() }
    }

    return $null
}

function Invoke-Python {
    param(
        [Parameter(Mandatory=$true)]$Python,
        [string[]]$Arguments
    )
    & $Python.exe @($Python.args + $Arguments) 2>&1
}

if ([string]::IsNullOrWhiteSpace($DataRoot)) {
    $DataRoot = Join-Path $RepoRoot "BASE"
}

$checks = New-Object System.Collections.Generic.List[object]

# R01 — Windows
$isWindowsHost = ($env:OS -eq "Windows_NT")
$checks.Add((New-Check "R01" "Windows host" ($(if ($isWindowsHost) {"PASS"} else {"FAIL"})) "QlikView Desktop readiness requires Windows."))

# R02 — Python
$python = Find-Python
if ($null -eq $python) {
    $checks.Add((New-Check "R02" "Python 3 available" "FAIL" "Neither 'py -3' nor 'python' was found in PATH."))
} else {
    $versionText = (Invoke-Python $python @("--version") | Out-String).Trim()
    $versionOk = $false
    if ($versionText -match "Python\s+(\d+)\.(\d+)") {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $versionOk = ($major -gt 3) -or (($major -eq 3) -and ($minor -ge 7))
    }
    $checks.Add((New-Check "R02" "Python 3 available" ($(if ($versionOk) {"PASS"} else {"FAIL"})) $versionText))
}

# R03 — virtual environment
$venvPython = Join-Path $RepoRoot ".venv\Scripts\python.exe"
if (Test-Path $venvPython) {
    $checks.Add((New-Check "R03" "Project virtualenv" "PASS" $venvPython))
    $packagePython = [PSCustomObject]@{ exe = $venvPython; args = @() }
} else {
    $checks.Add((New-Check "R03" "Project virtualenv" "FAIL" "Expected .venv\Scripts\python.exe was not found."))
    $packagePython = $python
}

# R04/R05 — Python packages and imports
if ($null -ne $packagePython) {
    $dbcShow = (Invoke-Python $packagePython @("-m","pip","show","dbc-to-dbf") | Out-String)
    $dbcInstalled = ($LASTEXITCODE -eq 0) -and ($dbcShow -match "Version:\s*1\.0\.1")
    $checks.Add((New-Check "R04" "dbc-to-dbf==1.0.1 installed" ($(if ($dbcInstalled) {"PASS"} else {"FAIL"})) ($(if ($dbcInstalled) {"Version 1.0.1 found."} else {"Run: python -m pip install dbc-to-dbf==1.0.1"}))))

    $dbfShow = (Invoke-Python $packagePython @("-m","pip","show","dbfread") | Out-String)
    $dbfInstalled = ($LASTEXITCODE -eq 0) -and ($dbfShow -match "Version:\s*2\.0\.7")
    $checks.Add((New-Check "R05" "dbfread==2.0.7 installed" ($(if ($dbfInstalled) {"PASS"} else {"FAIL"})) ($(if ($dbfInstalled) {"Version 2.0.7 found."} else {"Run: python -m pip install dbfread==2.0.7"}))))

    if ($dbcInstalled -and $dbfInstalled) {
        $importOut = (Invoke-Python $packagePython @("-c","from dbctodbf import DBCDecompress; from dbfread import DBF; print('IMPORT_OK')") | Out-String).Trim()
        $checks.Add((New-Check "R06" "Python package imports" ($(if (($LASTEXITCODE -eq 0) -and ($importOut -match "IMPORT_OK")) {"PASS"} else {"FAIL"})) $importOut))
    } else {
        $checks.Add((New-Check "R06" "Python package imports" "BLOCKED" "Install pinned packages first."))
    }
} else {
    $checks.Add((New-Check "R04" "dbc-to-dbf==1.0.1 installed" "BLOCKED" "Python not available."))
    $checks.Add((New-Check "R05" "dbfread==2.0.7 installed" "BLOCKED" "Python not available."))
    $checks.Add((New-Check "R06" "Python package imports" "BLOCKED" "Python not available."))
}

# R07 — QlikView executable
$candidateQlik = New-Object System.Collections.Generic.List[string]
if (-not [string]::IsNullOrWhiteSpace($env:QLIKVIEW_EXE)) {
    $candidateQlik.Add($env:QLIKVIEW_EXE)
}
$qvCommand = Get-Command Qv.exe -ErrorAction SilentlyContinue
if ($qvCommand) {
    $candidateQlik.Add($qvCommand.Source)
}
$candidateQlik.Add("C:\Program Files\QlikView\Qv.exe")
$candidateQlik.Add("C:\Program Files (x86)\QlikView\Qv.exe")

$qlikExe = $candidateQlik | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if ($qlikExe) {
    $checks.Add((New-Check "R07" "QlikView Qv.exe" "PASS" $qlikExe))
} else {
    $checks.Add((New-Check "R07" "QlikView Qv.exe" "FAIL" "Set QLIKVIEW_EXE or install QlikView 12."))
}

# R08 — Data root
if (Test-Path $DataRoot) {
    $checks.Add((New-Check "R08" "BASE directory available" "PASS" $DataRoot))
} else {
    $checks.Add((New-Check "R08" "BASE directory available" "FAIL" "Directory not found: $DataRoot"))
}

# R09-R11 — DBC inventory
if (Test-Path $DataRoot) {
    $rd = @(Get-ChildItem -Path $DataRoot -Recurse -File -Filter "RDPB*.dbc" -ErrorAction SilentlyContinue)
    $lt = @(Get-ChildItem -Path $DataRoot -Recurse -File -Filter "LTPB*.dbc" -ErrorAction SilentlyContinue)
    $st = @(Get-ChildItem -Path $DataRoot -Recurse -File -Filter "STPB*.dbc" -ErrorAction SilentlyContinue)

    $checks.Add((New-Check "R09" "RD inventory" ($(if ($rd.Count -eq 36) {"PASS"} else {"FAIL"})) "$($rd.Count)/36 files"))
    $checks.Add((New-Check "R10" "LT inventory" ($(if ($lt.Count -eq 36) {"PASS"} else {"FAIL"})) "$($lt.Count)/36 files"))
    $checks.Add((New-Check "R11" "ST inventory" ($(if ($st.Count -eq 36) {"PASS"} else {"FAIL"})) "$($st.Count)/36 files"))
} else {
    $checks.Add((New-Check "R09" "RD inventory" "BLOCKED" "BASE unavailable."))
    $checks.Add((New-Check "R10" "LT inventory" "BLOCKED" "BASE unavailable."))
    $checks.Add((New-Check "R11" "ST inventory" "BLOCKED" "BASE unavailable."))
}

# R12 — IBGE annual source presence
if (Test-Path $DataRoot) {
    $ibge2017 = @(Get-ChildItem -Path $DataRoot -Recurse -File -Include "*2017*.xls","*2017*.xlsx" -ErrorAction SilentlyContinue)
    $ibge2018 = @(Get-ChildItem -Path $DataRoot -Recurse -File -Include "*2018*.xls","*2018*.xlsx" -ErrorAction SilentlyContinue)
    $ibge2019 = @(Get-ChildItem -Path $DataRoot -Recurse -File -Include "*2019*.xls","*2019*.xlsx" -ErrorAction SilentlyContinue)
    $ibgeOk = ($ibge2017.Count -ge 1) -and ($ibge2018.Count -ge 1) -and ($ibge2019.Count -ge 1)
    $checks.Add((New-Check "R12" "IBGE 2017-2019 files" ($(if ($ibgeOk) {"PASS"} else {"FAIL"})) "2017=$($ibge2017.Count); 2018=$($ibge2018.Count); 2019=$($ibge2019.Count)"))
} else {
    $checks.Add((New-Check "R12" "IBGE 2017-2019 files" "BLOCKED" "BASE unavailable."))
}

# R13 — Free disk (informational)
try {
    $rootPath = [System.IO.Path]::GetPathRoot($RepoRoot)
    $drive = Get-PSDrive -Name $rootPath.Substring(0,1)
    $freeGb = [Math]::Round($drive.Free / 1GB, 2)
    $checks.Add((New-Check "R13" "Free disk space" "INFO" "$freeGb GB free on $rootPath"))
} catch {
    $checks.Add((New-Check "R13" "Free disk space" "INFO" "Could not determine free disk space."))
}

# R14 — gitignore protection
$gitignore = Join-Path $RepoRoot ".gitignore"
if (Test-Path $gitignore) {
    $gitText = Get-Content $gitignore -Raw
    $patterns = @("BASE/DBC/","BASE/IBGE/","BASE/REFERENCIAS/","BASE/CONVERTIDA/","EXTRACAO/QVD/","TRANSFORMACAO/QVD/","*.qvd")
    $missing = @($patterns | Where-Object { $gitText -notmatch [regex]::Escape($_) })
    $checks.Add((New-Check "R14" ".gitignore data/QVD protection" ($(if ($missing.Count -eq 0) {"PASS"} else {"FAIL"})) ($(if ($missing.Count -eq 0) {"Required patterns present."} else {"Missing: " + ($missing -join ", ")}))))
} else {
    $checks.Add((New-Check "R14" ".gitignore data/QVD protection" "FAIL" ".gitignore not found."))
}

$blocking = @($checks | Where-Object { $_.status -in @("FAIL","BLOCKED") })
$verdict = if ($blocking.Count -eq 0) { "LOCAL_PREFLIGHT_PASS" } else { "LOCAL_PREFLIGHT_FAIL" }

$result = [PSCustomObject]@{
    generated_at = (Get-Date).ToString("o")
    repo_root = $RepoRoot
    data_root = $DataRoot
    qlikview_exe = $qlikExe
    verdict = $verdict
    blocking_count = $blocking.Count
    checks = $checks
}

$json = $result | ConvertTo-Json -Depth 6
$json

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $json | Set-Content -Path $OutputPath -Encoding UTF8
}

if ($blocking.Count -gt 0) {
    exit 1
}
exit 0
