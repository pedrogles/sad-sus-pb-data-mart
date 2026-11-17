#requires -Version 5.1
<#
Imports the eight received VIS-05 PNGs only. Run from the extracted package.
No QlikView/COM, Reload, Save or inspection.json changes.
Existing differing evidence is preserved; a new evidence copy is created beside it.
#>
[CmdletBinding()]
param(
  [string]$PackageDirectory=$PSScriptRoot,
  [string]$Destination=(Join-Path $env:USERPROFILE 'SAD_VIS05_INSPECTION_EVIDENCIAS\VIS05_INSPECT_20261115_235407_3c3df8cbbcc6')
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$expected=[ordered]@{
  'V1_BASELINE.png'='92453a1f951ed890e46489387961039abeffba536bf9247d50bc7bde184b186a'
  'V1_BASELINE_EQ_detalhe.png'='7e03e5114ef4b21e61b0e9b0acda3fb8d43a5cc0c22a92618ccf411558af4865'
  'V1_BASELINE_NE_detalhe.png'='fc7f397eec9ba2f70827c44645effbc4b417617cbc39fac8fe536f9b541c4bf9'
  'V1_SORT.png'='cccce882b5a44184afa4ec4f2c6e5ff5a1cce8c5cfb92fedb0051c8ac7a1e1ac'
  'V1_SORT_EQ_detalhe.png'='418bd2d37d376b058ec22122b826215931b1b6b9c312e3b7eec139ae8a4772c8'
  'V1_SORT_NE_detalhe.png'='21ff391c5f3cdd39f90b08433f0d8f3d4ef8f44acafa97d286488161573d2a1c'
  'V1_SORT_propriedades_ascendente.png'='169c50ede26559379ec001592c235d69e5f07037d8f8d8bb43dee7c0e8c88102'
  'V1_SORT_propriedades_original.png'='e8e406bb467c9e8f92fcd931830774fa40421bbd97332f7465f7de196ecf85dc'
}
if(-not (Test-Path -LiteralPath $Destination -PathType Container)){throw 'Session folder missing. Do not create a different inspection session.'}
if((Split-Path -Leaf ([IO.Path]::GetFullPath($Destination).TrimEnd([char[]]@('\','/')))) -cne 'VIS05_INSPECT_20261115_235407_3c3df8cbbcc6'){throw 'Wrong session folder'}
# Validate every image before any destination write.
foreach($name in $expected.Keys){
  $src=Join-Path $PackageDirectory $name
  if(-not (Test-Path -LiteralPath $src -PathType Leaf)){throw ('Missing PNG: '+$name)}
  if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -ine $expected[$name]){throw ('PNG hash mismatch: '+$name)}
}
foreach($name in $expected.Keys){
  $src=Join-Path $PackageDirectory $name
  $dst=Join-Path $Destination $name
  if(Test-Path -LiteralPath $dst){
    if((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash -ieq $expected[$name]){
      Write-Output ('ALREADY_IDENTICAL='+$name)
      continue
    }
    # Never replace earlier evidence referenced by the running inspector.
    $suffix=$expected[$name].Substring(0,12)
    $dst=Join-Path $Destination (([IO.Path]::GetFileNameWithoutExtension($name))+'_received_'+$suffix+'.png')
    if(Test-Path -LiteralPath $dst){
      if((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash -ine $expected[$name]){throw ('Conflict in received evidence: '+$dst)}
      Write-Output ('EXISTING_PRESERVED_RECEIVED_ALREADY_PRESENT='+$name)
      continue
    }
    Write-Output ('EXISTING_PRESERVED='+$name)
  }
  [IO.File]::Copy($src,$dst,$false)
  if((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash -ine $expected[$name]){throw ('Destination hash mismatch: '+$dst)}
  Write-Output ('IMPORTED='+$dst)
}
Write-Output 'IMPORT_COMPLETE_IMAGES_ONLY_NO_QVW_OR_JSON_CHANGED'
Write-Output ('DESTINATION='+$Destination)
