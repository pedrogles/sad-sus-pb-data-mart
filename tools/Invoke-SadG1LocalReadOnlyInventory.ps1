# SAD G1 — Windows inventory only. Does NOT call QlikView/COM or mutate data/Git.
# This script must be executed only after the operator verifies its source commit and selects EvidenceRoot.
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Root,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [string]$BaselineCsv,
    [string]$F1F2Dir,
    [string]$F3Dir,
    [string]$ReferenceQvw
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Inside([string]$child, [string]$parent) {
    $a=[IO.Path]::GetFullPath($child).TrimEnd('\','/')+'\'
    $b=[IO.Path]::GetFullPath($parent).TrimEnd('\','/')+'\'
    return $a.StartsWith($b,[StringComparison]::OrdinalIgnoreCase)
}
function SHA([string]$path) {
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
function QvdHeader([string]$path) {
    $f=[IO.File]::Open($path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try {
        $n=[int][Math]::Min(4194304,$f.Length)
        $buf=New-Object byte[] $n
        $got=$f.Read($buf,0,$n)
        $raw=[Text.Encoding]::UTF8.GetString($buf,0,$got)
        $stop='</QvdTableHeader>'
        $i=$raw.IndexOf($stop,[StringComparison]::Ordinal)
        if($i -lt 0){throw ('BLOCKED_QVD_HEADER_MISSING: '+$path)}
        [xml]$xml=$raw.Substring(0,$i+$stop.Length)
        $node=$xml.DocumentElement
        if($null -eq $node -or $node.LocalName -cne 'QvdTableHeader'){
            throw ('BLOCKED_QVD_HEADER_INVALID: '+$path)
        }
        $nr=$node.SelectSingleNode('./NoOfRecords')
        $fields=@($node.SelectNodes('./Fields/QvdFieldHeader/FieldName') | ForEach-Object { $_.InnerText })
        if($null -eq $nr -or $fields.Count -eq 0){throw ('BLOCKED_QVD_METADATA_MISSING: '+$path)}
        return [pscustomobject]@{Rows=[long]$nr.InnerText;Fields=($fields -join '|')}
    } finally { $f.Dispose() }
}
function Check-References([string]$folder, [string]$name, [string[]]$expected) {
    if([string]::IsNullOrWhiteSpace($folder)) {
        Write-Output ($name+'=NOT_PROVIDED')
        return $false
    }
    if(-not(Test-Path -LiteralPath $folder -PathType Container)){throw ($name+'_DIR_MISSING')}
    $manifestFile=if($name -ceq 'F1F2'){'manifest_F1_F2.json'}else{'manifest_F3.json'}
    $manifestPath=Join-Path $folder $manifestFile
    if(-not(Test-Path -LiteralPath $manifestPath -PathType Leaf)){throw ($name+'_MANIFEST_MISSING')}
    $files=@(Get-ChildItem -LiteralPath $folder -File -Filter '*.csv')
    if($files.Count -ne $expected.Count){throw ($name+'_CSV_COUNT_MISMATCH')}
    $manifest=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if($null -eq $manifest.output_sha256){throw ($name+'_MANIFEST_MALFORMED')}
    $props=@($manifest.output_sha256.PSObject.Properties)
    if($props.Count -ne $expected.Count){throw ($name+'_OUTPUT_SHA_COUNT_MISMATCH')}
    foreach($n in $expected){
        if(@($files | Where-Object { $_.Name -ceq $n }).Count -ne 1){throw ($name+'_CSV_MISSING_'+$n)}
        $h=@($props | Where-Object { $_.Name -ceq $n })
        if($h.Count -ne 1 -or [string]$h[0].Value -notmatch '^[A-Fa-f0-9]{64}$'){
            throw ($name+'_SHA_DECLARATION_INVALID_'+$n)
        }
        $actual=SHA (Join-Path $folder $n)
        if($actual -cne ([string]$h[0].Value).ToUpperInvariant()){
            throw ($name+'_SHA_MISMATCH_'+$n)
        }
    }
    Write-Output ($name+'=PASS_MANIFEST_'+$expected.Count+'_FILES')
    return $true
}

$root=[IO.Path]::GetFullPath($Root)
$evidence=[IO.Path]::GetFullPath($EvidenceRoot)
if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'BLOCKED_ROOT_MISSING'}
if(-not(Test-Path -LiteralPath $evidence -PathType Container)){throw 'BLOCKED_EVIDENCE_ROOT_NOT_PREEXISTING'}
$evItem=Get-Item -LiteralPath $evidence
if(($evItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'BLOCKED_EVIDENCE_ROOT_REPARSE_POINT'}
if(Inside $evidence $root){throw 'BLOCKED_EVIDENCE_INSIDE_DATA_REPOSITORY'}
if(Inside $root $evidence){throw 'BLOCKED_DATA_REPOSITORY_INSIDE_EVIDENCE'}
$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
if(Inside $evidence $temp){throw 'BLOCKED_EVIDENCE_IN_TEMP'}
$work=Join-Path $evidence ('SAD_G1_'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $work -ErrorAction Stop
Write-Output ('EVIDENCE_DIR='+$work)
Write-Output ('SCRIPT_SHA256='+(SHA $PSCommandPath))
Write-Output 'MODE=READ_ONLY_G1_NO_CHECKOUT_NO_COM_NO_RELOAD_NO_STORE'
try {
    $gitRoot=@(& git -C $root rev-parse --show-toplevel 2>$null)
    if($LASTEXITCODE -ne 0 -or $gitRoot.Count -ne 1){throw 'BLOCKED_GIT_ROOT'}
    if([IO.Path]::GetFullPath($gitRoot[0]) -ine $root){throw 'BLOCKED_ROOT_NOT_GIT_TOPLEVEL'}
    $head=@(& git -C $root rev-parse HEAD 2>$null)
    if($LASTEXITCODE -ne 0 -or $head.Count -ne 1 -or $head[0] -notmatch '^[a-f0-9]{40}$'){
        throw 'BLOCKED_GIT_HEAD'
    }
    $branch=@(& git -C $root branch --show-current 2>$null)
    $status=@(& git -C $root status --porcelain=v1 --untracked-files=all)
    if($LASTEXITCODE -ne 0){throw 'BLOCKED_GIT_STATUS'}
    $trees=@(& git -C $root worktree list --porcelain)
    if($LASTEXITCODE -ne 0){throw 'BLOCKED_GIT_WORKTREES'}
    $status | Set-Content -LiteralPath (Join-Path $work 'git_status.txt') -Encoding UTF8
    $trees | Set-Content -LiteralPath (Join-Path $work 'git_worktrees.txt') -Encoding UTF8
    Write-Output ('DATA_GIT_HEAD='+$head[0])
    Write-Output ('DATA_GIT_BRANCH='+[string]($branch -join ''))
    Write-Output ('GIT_DIRTY_LINES='+$status.Count)

    $ext=Join-Path $root 'EXTRACAO/QVD'
    $trans=Join-Path $root 'TRANSFORMACAO/QVD'
    if(-not(Test-Path -LiteralPath $ext -PathType Container) -or
       -not(Test-Path -LiteralPath $trans -PathType Container)){
        throw 'BLOCKED_QVD_DIRECTORIES_MISSING'
    }
    $e=@(Get-ChildItem -LiteralPath $ext -File -Filter '*.qvd')
    $t=@(Get-ChildItem -LiteralPath $trans -File -Filter '*.qvd')
    if($e.Count -ne 10 -or $t.Count -ne 12){throw ('BLOCKED_QVD_COUNT_'+$e.Count+'_'+$t.Count)}
    $names=@(
        'DIM_TEMPO.qvd','DIM_MUNICIPIO.qvd','DIM_ESTABELECIMENTO.qvd',
        'DIM_PROCEDIMENTO.qvd','DIM_DIAGNOSTICO.qvd','DIM_CARATER_ATENDIMENTO.qvd',
        'DIM_MOTIVO_SAIDA_PERMANENCIA.qvd','DIM_TIPO_LEITO.qvd',
        'FATO_INTERNACAO.qvd','FATO_CAPACIDADE_LEITO.qvd','FATO_POPULACAO.qvd','LINK_ANALISE.qvd'
    )
    foreach($name in $names){
        if(@($t | Where-Object { $_.Name -ceq $name }).Count -ne 1){
            throw ('BLOCKED_QVD_TRANSFORM_NAME_'+$name)
        }
    }
    $rows=@()
    foreach($file in @($e)+@($t)){
        if($file.Length -le 0){throw ('BLOCKED_QVD_EMPTY_'+$file.Name)}
        $header=QvdHeader $file.FullName
        $rows += [pscustomobject]@{
            Path=$file.FullName;Rows=$header.Rows;Fields=$header.Fields;
            Bytes=[long]$file.Length;SHA256=(SHA $file.FullName)
        }
    }
    $rows=@($rows | Sort-Object Path)
    $rows | Export-Csv -LiteralPath (Join-Path $work 'qvd_22_inventory.csv') -NoTypeInformation -Encoding UTF8
    Write-Output 'QVD_22=PASS_READ_ONLY_INVENTORY'

    $baselineVerified=$false
    if(-not [string]::IsNullOrWhiteSpace($BaselineCsv)){
        if(-not(Test-Path -LiteralPath $BaselineCsv -PathType Leaf)){throw 'BLOCKED_BASELINE_CSV_MISSING'}
        $baseline=@(Import-Csv -LiteralPath $BaselineCsv)
        if($baseline.Count -ne 22){throw 'BLOCKED_BASELINE_NOT_22_ROWS'}
        foreach($row in $rows){
            $prior=@($baseline | Where-Object { $_.Path -ieq $row.Path })
            if($prior.Count -ne 1 -or $prior[0].SHA256 -cne $row.SHA256 -or
               [string]$prior[0].Rows -cne [string]$row.Rows -or
               [string]$prior[0].Fields -cne [string]$row.Fields){
                throw ('BLOCKED_FROZEN_QVD_BASELINE_MISMATCH_'+[IO.Path]::GetFileName($row.Path))
            }
        }
        $baselineVerified=$true
        Write-Output 'FROZEN_QVD_BASELINE=PASS_22_OF_22'
    } else { Write-Output 'FROZEN_QVD_BASELINE=NOT_PROVIDED_INCONCLUSIVE' }

    $qvws=@()
    foreach($rel in @('EXTRACAO/EXT.qvw','TRANSFORMACAO/TRANSF.qvw','PAINEL/PAINEL.qvw')){
        $p=Join-Path $root $rel
        $exists=Test-Path -LiteralPath $p -PathType Leaf
        $qvws += [pscustomobject]@{
            Relative=$rel;Exists=[bool]$exists;
            SHA256=$(if($exists){SHA $p}else{''})
        }
    }
    $qvws | Export-Csv -LiteralPath (Join-Path $work 'qvw_canonical_inventory.csv') -NoTypeInformation -Encoding UTF8
    Write-Output ('CANONICAL_QVW_PRESENT='+@($qvws | Where-Object { $_.Exists }).Count+'_OF_3')

    $f1Names=@('F1_fluxo_ano.csv','F1_fluxo_competencia.csv','F1_residencia_ano.csv',
               'F1_residencia_competencia.csv','F1_servico_ano.csv','F1_servico_competencia.csv',
               'F2_lt_municipio_ano_cobertura_candidata.csv','F2_lt_municipio_competencia_observado.csv')
    $f3Names=@('F3_pop_municipio_ano.csv','F3_componentes_residencia_ano.csv',
               'F3_componentes_servico_ano.csv','F3_residentes_externos_ano.csv',
               'F3_cenarios_multimunicipais.csv')
    $f1ok=Check-References $F1F2Dir 'F1F2' $f1Names
    $f3ok=Check-References $F3Dir 'F3' $f3Names
    if($f1ok -and $f3ok){
        $m3=Get-Content -LiteralPath (Join-Path $F3Dir 'manifest_F3.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        if($null -eq $m3.input_sha256){throw 'BLOCKED_F3_INPUT_LINKS_MISSING'}
        $inputs=@($m3.input_sha256.PSObject.Properties)
        foreach($file in @($f1Names)+@('manifest_F1_F2.json')){
            $p=@($inputs | Where-Object { [IO.Path]::GetFileName($_.Name) -ceq $file })
            if($p.Count -ne 1 -or [string]$p[0].Value -notmatch '^[A-Fa-f0-9]{64}$'){
                throw ('BLOCKED_F3_LINK_DECLARATION_'+$file)
            }
            if((SHA (Join-Path $F1F2Dir $file)) -cne ([string]$p[0].Value).ToUpperInvariant()){
                throw ('BLOCKED_F3_CROSS_LINK_SHA_'+$file)
            }
        }
        Write-Output 'F3_F1F2_CROSS_MANIFEST_LINK=PASS_9_OF_9'
    }

    $qvwVerified=$false
    if(-not [string]::IsNullOrWhiteSpace($ReferenceQvw)){
        if(-not(Test-Path -LiteralPath $ReferenceQvw -PathType Leaf)){throw 'BLOCKED_REFERENCE_QVW_MISSING'}
        $refHash=SHA $ReferenceQvw
        if($refHash -cne '7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E'){
            throw 'BLOCKED_REFERENCE_T24_QVW_SHA_MISMATCH'
        }
        $qvwVerified=$true
        Write-Output 'REFERENCE_T24_QVW=PASS_FROZEN_SHA'
    } else { Write-Output 'REFERENCE_T24_QVW=NOT_PROVIDED_INCONCLUSIVE' }

    $complete=$baselineVerified -and $f1ok -and $f3ok -and $qvwVerified
    $result=if($complete){'PASS_LOCAL_G1_READONLY_INVENTORY_CANDIDATE_ONLY'}else{'INCONCLUSIVE_G1_INCOMPLETE_REFERENCES'}
    Write-Output ('VERDICT='+$result)
    Write-Output 'QVD_WRITES=0 QVW_WRITES=0 GIT_WRITES=0 COM_INSTANTIATION=False'
} catch {
    Write-Output ('VERDICT=BLOCKED_READONLY_PREFLIGHT '+$_.Exception.Message)
    throw
}
