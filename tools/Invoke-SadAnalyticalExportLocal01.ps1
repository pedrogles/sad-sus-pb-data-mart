# SAD-ANALYTICAL-EXPORT-LOCAL-01 — prepared, UNEXECUTED Windows/QlikView runner.
# Requires separate authorization, scripts committed in canonical branch and -RunQlik.
# Sources QVD/QVW are read and hashed only. Only four CSVs + evidence are written
# under a NEW persistent EvidenceRoot outside Git; disposable QVW in TEMP only.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$ExpectedCommit,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [Parameter(Mandatory=$true)][switch]$RunQlik,
    [string]$PythonExe='py',
    [string]$F2Reference=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$gate='SAD-ANALYTICAL-EXPORT-LOCAL-01'
$repo=[IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\','/'))
$evidence=[IO.Path]::GetFullPath($EvidenceRoot).TrimEnd([char[]]@('\','/'))
$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]@('\','/'))
function Descendant([string]$child,[string]$parent) {
    return $child.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or $child.Equals($parent,[StringComparison]::OrdinalIgnoreCase)
}
if (-not $RunQlik) { throw 'Physical execution not authorized: -RunQlik explicitly required' }
if ($ExpectedCommit -notmatch '^[0-9a-fA-F]{40}$') {throw 'ExpectedCommit must be complete SHA-1'}
if ((Descendant $evidence $repo) -or (Descendant $evidence $temp)) {throw 'EvidenceRoot must be persistent, outside Git and TEMP'}
if (Test-Path -LiteralPath $evidence) {throw 'EvidenceRoot already exists: refusing overwrite'}
if (-not (Test-Path -LiteralPath (Split-Path $evidence -Parent) -PathType Container)) {throw 'EvidenceRoot parent absent'}
if (-not (Test-Path -LiteralPath (Join-Path $repo 'AGENTS.md') -PathType Leaf)) {throw 'Not canonical repository root'}
$head=(& git -C $repo rev-parse HEAD 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cne $ExpectedCommit.ToLowerInvariant()) {throw "Commit mismatch: expected $ExpectedCommit actual $head"}
$branch=(& git -C $repo branch --show-current 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch) -or $branch -eq 'main') {throw 'Use a committed, explicit non-main branch'}
$critical=@(
    'TRANSFORMACAO/sad_analytical_export_local01.qvs',
    'tools/Invoke-SadAnalyticalExportLocal01.ps1',
    'tools/validate_sad_analytical_export_local01.py'
)
$critHash=@{}
foreach($f in $critical) {
    $abs=Join-Path $repo $f
    if(-not (Test-Path -LiteralPath $abs -PathType Leaf)) {throw "Critical script missing: $f"}
    $tracked=@(& git -C $repo ls-files --error-unmatch -- $f 2>$null)
    if($LASTEXITCODE -ne 0 -or $tracked.Count -ne 1) {throw "Script not committed/tracked: $f"}
    $dirty=@(& git -C $repo status --porcelain -- $f 2>$null)
    if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) {throw "Uncommitted critical script: $f"}
    $critHash[$f]=(Get-FileHash -LiteralPath $abs -Algorithm SHA256).Hash
}
$rd=Join-Path $repo 'EXTRACAO\QVD\SRC_SIH_RD.qvd'
$lt=Join-Path $repo 'EXTRACAO\QVD\SRC_CNES_LT.qvd'
$bridge=Join-Path $repo 'EXTRACAO\QVD\REF_MUNICIPIO_PB_DERIVADA.csv'
foreach($p in @($rd,$lt,$bridge)) {if(-not (Test-Path -LiteralPath $p -PathType Leaf)){throw "Required source missing: $p"}}
if($F2Reference -ne '' -and -not (Test-Path -LiteralPath $F2Reference -PathType Leaf)) {throw 'F2 reference not found'}

function QvdHeader([string]$path) {
    $fs=[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try {
        $b=New-Object byte[] (4*1024*1024)
        $n=$fs.Read($b,0,$b.Length)
        $txt=[Text.Encoding]::UTF8.GetString($b,0,$n)
        $end=$txt.IndexOf('</QvdTableHeader>',[StringComparison]::Ordinal)
        if($end -lt 0){throw "QVD header exceeds bounded prefix: $path"}
        $xml=[xml]$txt.Substring(0,$end+'</QvdTableHeader>'.Length)
        $h=$xml.QvdTableHeader
        $names=@($h.Fields.QvdFieldHeader | ForEach-Object {[string]$_.FieldName})
        return [pscustomobject]@{Rows=[long]$h.NoOfRecords;Fields=$names}
    } finally {$fs.Dispose()}
}
function Inventory {
    $a=@(Get-ChildItem -LiteralPath (Join-Path $repo 'EXTRACAO\QVD') -Filter '*.qvd' -File)
    $b=@(Get-ChildItem -LiteralPath (Join-Path $repo 'TRANSFORMACAO\QVD') -Filter '*.qvd' -File)
    if($a.Count -ne 10 -or $b.Count -ne 12){throw "QVD 10+12 inventory mismatch $($a.Count)+$($b.Count)"}
    if(@($b|Where-Object{$_.Name -ceq 'LINK_ANALISE.qvd'}).Count -ne 1){throw '22-QVD baseline missing LINK_ANALISE.qvd'}
    $qwvs=@('EXTRACAO\EXT.qvw','TRANSFORMACAO\TRANSF.qvw','PAINEL\PAINEL.qvw')
    $paths=@($a+$b | ForEach-Object{$_.FullName}) + @($qwvs|ForEach-Object{Join-Path $repo $_}) + @($bridge)
    foreach($p in $paths){if(-not (Test-Path -LiteralPath $p -PathType Leaf)){throw "Protected file missing: $p"}}
    $items=@()
    foreach($path in ($paths | Sort-Object)) {
        $i=Get-Item -LiteralPath $path
        if($i.Length -le 0){throw "Protected file empty: $path"}
        $entry=[ordered]@{path=$path;bytes=$i.Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}
        if($path.EndsWith('.qvd',[StringComparison]::OrdinalIgnoreCase)) {
            $header=QvdHeader $path
            $entry.rows=$header.Rows
            $entry.fields=@($header.Fields)
            if($path -ieq $rd){
                if($header.Rows -ne 566672 -or @(@('ANO_CMPT','MES_CMPT','MUNIC_RES','MUNIC_MOV','PROC_REA','DIAG_PRINC','IDENT','_META_SOURCE_COMPETENCE') | Where-Object {$_ -notin $header.Fields}).Count -gt 0) {throw 'RD QVD schema/rows mismatch'}
            }
            if($path -ieq $lt){
                if($header.Rows -ne 35518 -or @(@('COMPETEN','CODUFMUN','CNES','TP_LEITO','CODLEITO','QT_EXIST','QT_SUS','QT_NSUS','_META_SOURCE_COMPETENCE') | Where-Object {$_ -notin $header.Fields}).Count -gt 0) {throw 'LT QVD schema/rows mismatch'}
            }
        }
        $items+=([pscustomobject]$entry)
    }
    return $items
}
function SameInventory($left,$right) {
    if($left.Count -ne $right.Count){return $false}
    for($i=0;$i -lt $left.Count;$i++){
        if($left[$i].path -cne $right[$i].path -or $left[$i].sha256 -cne $right[$i].sha256 -or $left[$i].bytes -ne $right[$i].bytes){return $false}
    }
    return $true
}
$pre=@(Inventory)
$source=(Get-Content -LiteralPath (Join-Path $repo $critical[0]) -Raw -Encoding UTF8)
$stores=[regex]::Matches($source,'(?im)^\s*STORE\s+AE_E[1-4]\s+INTO\s+\[__(?:E1|E2|E3|E4)_CSV__\]\s+\(txt, utf8, delimiter is '';'', embedded labels\);')
if($stores.Count -ne 4 -or [regex]::Matches($source,'(?im)^\s*STORE\b').Count -ne 4){throw 'QVS STORE whitelist mismatch'}
if($source -match '(?im)^\s*(EXECUTE|BINARY|SQL|DIRECT\s+QUERY|DROP\s+FILE|MUST_INCLUDE|INCLUDE)\b'){throw 'Forbidden QVS statement'}
if($source -notmatch 'VERDICT=PASS_GROUPED_CSV_EXPORTED_PENDING_INDEPENDENT_VALIDATION'){throw 'Missing QVS marker'}
$paths=@{
    '__RD_QVD__'=$rd; '__LT_QVD__'=$lt;
    '__E1_CSV__'=(Join-Path $evidence 'sih_fluxo_competencia.csv');
    '__E2_CSV__'=(Join-Path $evidence 'sih_procedimento_competencia.csv');
    '__E3_CSV__'=(Join-Path $evidence 'sih_diagnostico_competencia.csv');
    '__E4_CSV__'=(Join-Path $evidence 'lt_cnes_leito_competencia.csv')
}
foreach($key in $paths.Keys){
    $path=[string]$paths[$key]
    if($path -match '[\]\r\n]'){throw "QVS path contains unsupported characters: $key"}
    if($key -like '__E*_CSV__' -and (Test-Path -LiteralPath $path)){throw "Output already exists: $key"}
    $source=$source.Replace($key,$path)
}
if($source -match '__[A-Z0-9_]+__'){throw 'Unresolved QVS placeholder'}

# Input checks completed. This is the only execution attempt; partial exports
# remain in evidence if Qlik fails. Do not retry in this invocation.
[void][IO.Directory]::CreateDirectory($evidence)
$pre | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'protected_before.json') -Encoding UTF8
$runtime=Join-Path $temp ('SAD_AE01_'+[Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($runtime)
$app=$null;$doc=$null;$problem=$null;$post=$null;$unchanged=$false
try {
    $qvw=Join-Path $runtime 'AE01_DISPOSABLE.qvw'
    $app=New-Object -ComObject 'QlikTech.QlikView'
    $doc=$app.CreateDoc()
    if($null -eq $doc){throw 'COM CreateDoc returned null'}
    $props=$doc.GetProperties();$props.Script=$source;$props.GenerateLogfile=$true
    $null=$doc.SetProperties($props)
    if(-not [bool]$doc.GetProperties().GenerateLogfile){throw 'Native logging disabled'}
    $null=$doc.SaveAs($qvw)
    if(-not (Test-Path -LiteralPath $qvw -PathType Leaf)){throw 'Disposable QVW absent'}
    $started=[DateTime]::UtcNow
    $null=$doc.Reload()
    $log=$qvw+'.log'
    if(-not (Test-Path -LiteralPath $log -PathType Leaf)){throw 'No QlikView reload log'}
    Copy-Item -LiteralPath $log -Destination (Join-Path $evidence 'qlik_reload.log')
    if((Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $started.AddSeconds(-3)){throw 'Stale QlikView log'}
    $executed=@(Get-Content -LiteralPath $log | Where-Object {$_ -notmatch '\bTRACE\b'})
    if(@($executed | Where-Object {$_.Contains('[AE01] VERDICT=PASS_GROUPED_CSV_EXPORTED_PENDING_INDEPENDENT_VALIDATION')}).Count -ne 1 -or
       @($executed | Where-Object {$_ -match '\[AE01\] VERDICT=BLOCKED'}).Count -gt 0){
        throw 'AE01 native PASS not proven, inspect qlik_reload.log'
    }
} catch {$problem=$_.Exception.Message} finally {
    $nativeLog=Join-Path $runtime 'AE01_DISPOSABLE.qvw.log'
    if(Test-Path -LiteralPath $nativeLog -PathType Leaf){
        try{Copy-Item -LiteralPath $nativeLog -Destination (Join-Path $evidence 'qlik_reload.log') -Force}catch{}
    }
    if($null -ne $doc){try{$null=$doc.CloseDoc()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)}catch{}}
    if($null -ne $app){try{$app.Quit()}catch{};try{[void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($app)}catch{}}
    try {
        $post=@(Inventory)
        $post | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $evidence 'protected_after.json') -Encoding UTF8
        $unchanged=SameInventory $pre $post
        if(-not $unchanged){$problem='HARD_STOP: protected QVD/QVW/crosswalk inventory changed'}
    } catch {$unchanged=$false;$problem='HARD_STOP: failed protected-file after-snapshot: '+$_.Exception.Message}
}
if($null -ne $problem -or -not $unchanged) {
    ('VERDICT=BLOCKED_OR_HARD_STOP; '+$problem+'; evidence='+$evidence) |
      Set-Content -LiteralPath (Join-Path $evidence 'execution_failure.txt') -Encoding UTF8
    throw "VERDICT=BLOCKED_OR_HARD_STOP; $problem. Evidence=$evidence"
}
$metadata=[ordered]@{
    gate=$gate;commit=$head;branch=$branch;script_sha256=$critHash;
    protection_unchanged=$true;qvd_count=22;canonical_qvw_count=3;
    qlikview_execution='LOCAL_REPORTED_ONLY_PENDING_INDEPENDENT_AUDIT';
    runtime_temp=$runtime;evidence_root=$evidence
}
$metaFile=Join-Path $evidence 'run_metadata.json'
$metadata | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $metaFile -Encoding UTF8
$checker=Join-Path $repo $critical[2]
$argv=@('-3',$checker,'--exports',$evidence,'--crosswalk',$bridge,
    '--manifest',(Join-Path $evidence 'manifest.json'),'--metadata',$metaFile)
if($F2Reference -ne ''){$argv+=@('--f2',$F2Reference)}
$validation=& $PythonExe @argv 2>&1
$validation | Out-File -LiteralPath (Join-Path $evidence 'validator_stdout.txt') -Encoding UTF8
if($LASTEXITCODE -ne 0){throw "VERDICT=BLOCKED_INDEPENDENT_VALIDATOR; Evidence=$evidence"}
Write-Output "VERDICT=EXPORTED_AND_RECONCILED_RESTRICTED Evidence=$evidence Commit=$head"
