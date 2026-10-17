# Fase VI — fail-closed LINK_ANALISE executor. Default is inventory-only.
# Physical use needs a separate authorized gate. NEVER overwrite QVD or reload TRANSF.qvw.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$Root,
 [switch]$ExecutePhysical,
 [switch]$ConfirmPhysicalWrite,
 [string]$AuthorizedCommit
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath($Root)
$runner='tools/Invoke-SadViLinkAnalise.ps1'
$base='TRANSFORMACAO/vi_p1_readonly.qvs'
$tail='TRANSFORMACAO/vi_link_analise_create_tail.qvs'
$rb='TRANSFORMACAO/vi_link_analise_readback.qvs'
$trackedPaths=@($runner,$base,$tail,$rb)
$dest=Join-Path $repo 'TRANSFORMACAO/QVD/LINK_ANALISE.qvd'
$work=Join-Path ([IO.Path]::GetTempPath()) ('SAD_VI_LINK_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -Path $work -ItemType Directory -ErrorAction Stop
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('MODE='+$(if($ExecutePhysical){'PHYSICAL_EXPLICIT'}else{'INVENTORY_ONLY'}))
Write-Output 'PRODUCTION_APPROVED=False TRANSF_QVW_NOT_RELOADED=True'
if([IO.Path]::GetFullPath($PSCommandPath) -ine [IO.Path]::GetFullPath((Join-Path $repo $runner))){throw 'Run the versioned runner at tools/'}
$head=@(& git -C $repo rev-parse --verify HEAD 2>$null)
if($LASTEXITCODE -ne 0 -or $head.Count -ne 1 -or $head[0] -notmatch '^[0-9a-f]{40}$'){throw 'Git HEAD required'}
$found=@(& git -C $repo ls-files --error-unmatch -- $trackedPaths 2>$null)
if($LASTEXITCODE -ne 0 -or $found.Count -ne 4){throw 'All 4 scripts must be tracked'}
$dirty=@(& git -C $repo status --porcelain -- $trackedPaths)
if($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0){throw 'Scripts dirty; commit before execution'}
Write-Output ('VERSIONED_GIT_HEAD='+$head[0])
foreach($rel in $trackedPaths){
 $p=Join-Path $repo $rel
 if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing script: $p"}
 Write-Output ('SCRIPT_SHA256='+$rel+'|'+(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash)
}
if($ExecutePhysical){
 if(-not $ConfirmPhysicalWrite -or $AuthorizedCommit -cne $head[0]){
  throw 'Explicit -ConfirmPhysicalWrite and reviewed -AuthorizedCommit required'
 }
} elseif($ConfirmPhysicalWrite -or $AuthorizedCommit){throw 'Physical switches require -ExecutePhysical'}
function QvdHeader([string]$p){
 $f=[IO.File]::Open($p,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 try{
  $n=[int][Math]::Min(4194304,$f.Length)
  $bytes=New-Object byte[] $n
  $got=$f.Read($bytes,0,$n)
  $raw=[Text.Encoding]::UTF8.GetString($bytes,0,$got)
  $end='</QvdTableHeader>'
  $i=$raw.IndexOf($end,[StringComparison]::Ordinal)
  if($i -lt 0){throw "QVD header missing: $p"}
  [xml]$xml=$raw.Substring(0,$i+$end.Length)
  $root=$xml.DocumentElement
  if($null -eq $root -or $root.LocalName -ne 'QvdTableHeader'){throw "QVD root invalid: $p"}
  $records=$root.SelectSingleNode('./NoOfRecords')
  $fields=@($root.SelectNodes('./Fields/QvdFieldHeader/FieldName') | ForEach-Object {$_.InnerText})
  if($null -eq $records -or $fields.Count -eq 0){throw "QVD fields missing: $p"}
  return [pscustomobject]@{Rows=[long]$records.InnerText;Fields=$fields}
 } finally {$f.Dispose()}
}
$rules=@{
 'FATO_INTERNACAO.qvd'=@{n=566672;f=17;fields=@('SK_REGISTRO_INTERNACAO','%LINK_KEY')}
 'FATO_CAPACIDADE_LEITO.qvd'=@{n=35518;f=11;fields=@('SK_REGISTRO_CAPACIDADE_LEITO','%LINK_KEY')}
 'FATO_POPULACAO.qvd'=@{n=669;f=7;fields=@('%SK_MUNICIPIO','%SK_TEMPO_ANO')}
}
function SnapshotOriginals{
 $ext=Join-Path $repo 'EXTRACAO/QVD'
 $trans=Join-Path $repo 'TRANSFORMACAO/QVD'
 $a=@(Get-ChildItem -LiteralPath $ext -File -Filter '*.qvd')
 $b=@(Get-ChildItem -LiteralPath $trans -File -Filter '*.qvd' | Where-Object {$_.Name -ine 'LINK_ANALISE.qvd'})
 if($a.Count -ne 10 -or $b.Count -ne 11){throw "Unexpected QVD inventory: $($a.Count) + $($b.Count)"}
 $rows=@()
 foreach($f in @($a)+@($b)){
  $h=QvdHeader $f.FullName
  if($rules.ContainsKey($f.Name)){
   $rule=$rules[$f.Name]
   if($h.Rows -ne $rule.n -or $h.Fields.Count -ne $rule.f){throw "Fact schema drift: $($f.Name)"}
   foreach($s in $rule.fields){if($h.Fields -cnotcontains $s){throw "Missing fact field $s"}}
  }
  $rows += [pscustomobject]@{
   File=$f.FullName;Rows=$h.Rows;Fields=($h.Fields -join '|');
   Bytes=[long]$f.Length;SHA256=(Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash
  }
 }
 return @($rows | Sort-Object File)
}
function WithPaths([string]$body,[hashtable]$paths){
 foreach($key in $paths.Keys){
  $p=$paths[$key]
  if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "Input missing: $p"}
  if($p.Contains(']') -or $p.Contains("'") -or $p.Contains([char]10) -or $p.Contains([char]13)){throw 'Invalid QVD path'}
  $body=$body.Replace($key,$p)
 }
 if($body -match '__[A-Z_]+__'){throw 'Unresolved QVS placeholder'}
 return $body
}
function ReloadTemporary([string]$body,[string]$name,[string]$success,[string]$failure){
 $file=Join-Path $work ($name+'.qvw')
 $log=$file+'.log'
 $app=$null; $doc=$null
 try{
  $app=New-Object -ComObject 'QlikTech.QlikView'
  $doc=$app.CreateDoc()
  if($null -eq $doc){throw "Cannot CreateDoc: $name"}
  $props=$doc.GetProperties()
  $props.Script=$body
  $props.GenerateLogfile=$true
  $null=$doc.SetProperties($props)
  if(-not [bool]$doc.GetProperties().GenerateLogfile){throw 'Native logging disabled'}
  $null=$doc.SaveAs($file)
  if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw 'Disposable QVW missing'}
  $started=[DateTime]::UtcNow
  $null=$doc.Reload()
  if(-not(Test-Path -LiteralPath $log -PathType Leaf)){throw 'Native reload log missing'}
  if((Get-Item -LiteralPath $log).LastWriteTimeUtc -lt $started.AddSeconds(-3)){throw 'Stale native reload log'}
  $events=@(Get-Content -LiteralPath $log | Where-Object {$_ -notmatch '\bTRACE\b'})
  $pass=@($events | Where-Object {$_.Contains($success)})
  $blocked=@($events | Where-Object {$_.Contains($failure)})
  if($pass.Count -ne 1 -or $blocked.Count -gt 0){
   Write-Output ('NATIVE_BLOCKED_'+$name+'='+($blocked -join ' | '))
   throw "No unique PASS or BLOCKED in $name (preserve raw native log)"
  }
  Write-Output ('NATIVE_PASS_'+$name+'='+$success)
 } finally {if($null -ne $doc){try{$null=$doc.CloseDoc()}catch{}}}
}
$before=$null
try{
 $before=@(SnapshotOriginals)
 $before | Export-Csv -LiteralPath (Join-Path $work 'original_21_before.csv') -NoTypeInformation -Encoding UTF8
 if(Test-Path -LiteralPath $dest){throw 'LINK_ANALISE.qvd exists; overwrite prohibited'}
 $p1=[IO.File]::ReadAllText((Join-Path $repo $base),[Text.Encoding]::UTF8)
 $producer=[IO.File]::ReadAllText((Join-Path $repo $tail),[Text.Encoding]::UTF8)
 $audit=[IO.File]::ReadAllText((Join-Path $repo $rb),[Text.Encoding]::UTF8)
 $p1Sha=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $repo $base)).Hash
 if($p1Sha -cne '80E80770C59FBCC48142DA8E4CE6BF87D3CD6113FCACE977E0DACEA0CA78558B'){throw 'Frozen P1 QVS SHA256 mismatch'}
 if($p1 -match '(?im)^\s*STORE\b'){throw 'P1 preflight contains a data write'}
 $storeLines=@($producer -split '\r?\n' | Where-Object {$_ -match '^\s*STORE\b'})
 if($storeLines.Count -ne 1 -or $storeLines[0] -cne 'STORE P1_LINK_SIMULADA INTO [__LINK_DEST__] (qvd);'){throw 'CREATE QVS STORE not whitelisted'}
 if($audit -match '(?im)^\s*(STORE|EXECUTE|BINARY|SQL|DROP\s+FILE)\b'){throw 'READBACK QVS writes data'}
 if($p1 -notmatch 'VERDICT=PASS_PHYSICAL_KEYS_AND_TEMPORARY_MODEL_NOT_FINAL'){throw 'P1 marker missing'}
 Write-Output 'STATIC_PRECHECK=PASS'
 if(-not $ExecutePhysical){
  Write-Output 'VERDICT=PASS_INVENTORY_ONLY_NOT_PHYSICAL'
  Write-Output 'LINK_ANALISE_QVD_GENERATED=False'
 }else{
  $paths=@{
   '__FI_QVD__'=(Join-Path $repo 'TRANSFORMACAO/QVD/FATO_INTERNACAO.qvd')
   '__LT_FACT_QVD__'=(Join-Path $repo 'TRANSFORMACAO/QVD/FATO_CAPACIDADE_LEITO.qvd')
   '__POP_QVD__'=(Join-Path $repo 'TRANSFORMACAO/QVD/FATO_POPULACAO.qvd')
   '__RD_QVD__'=(Join-Path $repo 'EXTRACAO/QVD/SRC_SIH_RD.qvd')
   '__LT_STAGE_QVD__'=(Join-Path $repo 'EXTRACAO/QVD/SRC_CNES_LT.qvd')
   '__TEMPO_QVD__'=(Join-Path $repo 'TRANSFORMACAO/QVD/DIM_TEMPO.qvd')
   '__MUN_QVD__'=(Join-Path $repo 'TRANSFORMACAO/QVD/DIM_MUNICIPIO.qvd')
   '__EST_QVD__'=(Join-Path $repo 'TRANSFORMACAO/QVD/DIM_ESTABELECIMENTO.qvd')
  }
  if($dest.Contains(']') -or $dest.Contains("'") -or $dest.Contains([char]10) -or $dest.Contains([char]13)){throw 'Invalid output path'}
  $body=WithPaths ($p1+[Environment]::NewLine+$producer.Replace('__LINK_DEST__',$dest)) $paths
  if(Test-Path -LiteralPath $dest){throw 'Output appeared before reload; stop'}
  ReloadTemporary $body 'VI_LINK_CREATE' '[VI-LINK] VERDICT=PASS_STORE_ONLY_READBACK_REQUIRED' '[VI-LINK] VERDICT=BLOCKED'
  if(-not(Test-Path -LiteralPath $dest -PathType Leaf)){throw 'STORE returned PASS but QVD missing'}
  $new=QvdHeader $dest
  $schema=@('%LINK_KEY','%SK_TEMPO_COMPETENCIA','%SK_TEMPO_ANO',
    '%SK_MUNICIPIO_RESIDENCIA','%SK_MUNICIPIO_SERVICO','%SK_ESTABELECIMENTO')
  if($new.Rows -ne 85705 -or ($new.Fields -join '|') -cne ($schema -join '|')){throw 'QVD physical header unexpected'}
  Write-Output ('LINK_QVD_SHA256='+(Get-FileHash -Algorithm SHA256 -LiteralPath $dest).Hash)
  $rbPaths=@{
   '__LINK_DEST__'=$dest
   '__FI_QVD__'=$paths['__FI_QVD__']
   '__LT_FACT_QVD__'=$paths['__LT_FACT_QVD__']
   '__POP_QVD__'=$paths['__POP_QVD__']
  }
  $audit=WithPaths $audit $rbPaths
  ReloadTemporary $audit 'VI_LINK_READBACK' '[VI-LINK-RB] VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY' '[VI-LINK-RB] VERDICT=BLOCKED'
  Write-Output 'VERDICT=PASS_LOCAL_CREATE_AND_READBACK_CANDIDATE_ONLY'
  Write-Output 'LINK_KEY_CONTRACT=NOT_APPROVED PANEL_NOT_TESTED=True'
 }
} catch {
 Write-Output ('VERDICT=BLOCKED_OR_INCONCLUSIVE '+$_.Exception.Message)
 throw
} finally {
 if($null -ne $before){
  $after=@(SnapshotOriginals)
  $after | Export-Csv -LiteralPath (Join-Path $work 'original_21_after.csv') -NoTypeInformation -Encoding UTF8
  $a=ConvertTo-Json -InputObject $before -Depth 4 -Compress
  $b=ConvertTo-Json -InputObject $after -Depth 4 -Compress
  if($a -cne $b){throw 'CRITICAL: original 21 QVDs changed; preserve evidence, stop'}
  Write-Output 'ORIGINAL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True'
 }
}
