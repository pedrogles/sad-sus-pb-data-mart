# SAD — CNES ST/LT: source QVD header inventory, read-only, no historical-scope approval.
[CmdletBinding()]
param([string]$Root=(Get-Location).Path)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$rootDir=[IO.Path]::GetFullPath($Root)
foreach($doc in @('AGENTS.md','docs\project\current-state.md','docs\academic\requirements.md')){
 $file=Join-Path $rootDir $doc
 if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw ('DOC_MISSING='+$doc)}
}
$spec=@(
 [pscustomobject]@{tag='ST';filename='SRC_CNES_ST.qvd';rows=220390;fields=@('CNES','CODUFMUN','COD_CEP','CNPJ_MAN','VINC_SUS','TPGESTAO','TP_UNID','NATUREZA','NAT_JUR','COMPETEN')},
 [pscustomobject]@{tag='LT';filename='SRC_CNES_LT.qvd';rows=35518;fields=@('CNES','CODUFMUN','TP_LEITO','CODLEITO','QT_EXIST','QT_SUS','QT_NSUS','COMPETEN')}
)
function ReadHeader([string]$path){
 $stream=[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 try{
  $bytes=New-Object byte[] (4*1024*1024)
  $total=0;$close='</QvdTableHeader>'
  while($total -lt $bytes.Length){
   $got=$stream.Read($bytes,$total,[Math]::Min(65536,$bytes.Length-$total))
   if($got -eq 0){break}
   $total+=$got
   $s=[Text.Encoding]::UTF8.GetString($bytes,0,$total)
   $end=$s.IndexOf($close,[StringComparison]::Ordinal)
   if($end -ge 0){
    $s=$s.Substring(0,$end+$close.Length)
    $first=$s.IndexOf('<?xml',[StringComparison]::Ordinal)
    if($first -lt 0){$first=$s.IndexOf('<QvdTableHeader',[StringComparison]::Ordinal)}
    if($first -lt 0){throw 'HEADER_START_NOT_FOUND'}
    [xml]$parsed=$s.Substring($first)
    return $parsed.QvdTableHeader
   }
  }
  throw 'QVD_HEADER_END_NOT_FOUND_WITHIN_4MIB'
 }finally{$stream.Dispose()}
}
$before=@{}
foreach($item in $spec){
 $path=Join-Path $rootDir ('EXTRACAO\QVD\'+$item.filename)
 if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw ('INPUT_QVD_MISSING='+$item.filename)}
 $before[$item.tag]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$report=@()
foreach($item in $spec){
 $path=Join-Path $rootDir ('EXTRACAO\QVD\'+$item.filename)
 $head=ReadHeader $path
 $actual=@($head.Fields.QvdFieldHeader|ForEach-Object{[string]$_.FieldName})
 $missing=@($item.fields|Where-Object{$actual -cnotcontains $_})
 $rows=[int64]$head.NoOfRecords
 $dup=@($actual|Group-Object|Where-Object{$_.Count -gt 1})
 Write-Output ('SOURCE='+$item.tag+' FILE='+$item.filename+' SHA256='+$before[$item.tag])
 Write-Output ('HEADER='+$item.tag+' ROWS='+$rows+' FIELDS='+($actual -join ','))
 $good=($rows -eq [int64]$item.rows -and $missing.Count -eq 0 -and $dup.Count -eq 0)
 Write-Output ('HEADER_BASELINE_MATCH_'+$item.tag+'='+$good)
 if(-not $good){throw ('BLOCKED_'+$item.tag+'_QVD_HEADER_MISMATCH')}
 $report+=([pscustomobject]@{
   source=$item.tag;filename=$item.filename;sha256=$before[$item.tag];
   qvd_header_table_name=[string]$head.TableName;
   qvd_header_rows=$rows;qvd_header_fields=$actual;
   expected_rows=$item.rows;required_fields=$item.fields;
   header_only=$true;hospital_classification_not_approved=$true
 })
}
foreach($item in $spec){
 $path=Join-Path $rootDir ('EXTRACAO\QVD\'+$item.filename)
 if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $before[$item.tag]){
   throw ('IMMUTABLE_QVD_CHANGED='+$item.filename)
 }
}
$directory=Join-Path ([IO.Path]::GetTempPath()) ('SAD_CNES_ST_LT_HEADER_'+[Guid]::NewGuid().ToString('N'))
New-Item -Path $directory -ItemType Directory -ErrorAction Stop|Out-Null
$json=Join-Path $directory 'header_audit.json'
[pscustomobject]@{mode='CNES_ST_LT_HEADER_ONLY';inputs=$report;verdict='PASS_HEADER_INVENTORY_ONLY_NOT_HOSPITAL_SCOPE'}|
  ConvertTo-Json -Depth 7|Set-Content -LiteralPath $json -Encoding UTF8
Write-Output ('AUDIT_JSON='+$json)
Write-Output ('AUDIT_JSON_SHA256='+(Get-FileHash -LiteralPath $json -Algorithm SHA256).Hash)
Write-Output 'SOURCE_QVD_HASHES_UNCHANGED=True'
Write-Output 'QVD_BODY_AND_TP_UNID_VALUE_DISTRIBUTION=NOT_INSPECTED'
Write-Output 'CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED'
Write-Output 'T29_HISTORICAL=NOT_APPROVED'
Write-Output 'FACT_QVDS=NOT_STARTED LINK_ANALISE_QVD=NOT_STARTED PAINEL=NOT_STARTED'
Write-Output 'FINAL_VERDICT=PASS_HEADER_INVENTORY_ONLY_NOT_HOSPITAL_SCOPE'
