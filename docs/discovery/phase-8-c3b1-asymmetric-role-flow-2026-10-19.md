# Fase VIII — C3-B1 | Fluxo assimétrico residência × serviço (prova candidata)

**Estado:** `C3B1=VERSIONED_NOT_EXECUTED`; `C3B1_PHYSICAL=NOT_RUN`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PRODUCTION_APPROVED=False`.

**Base congelada:** `main@337943d5c5b77067f842902fc679dbb68db87020`. Branch isolada `test/phase-viii-c3b1-asymmetric-roles-20261019`; PR Draft, sem merge. O relatório C3-A READ-ONLY de 19/10 (artefato local não integrado) identificou uma lacuna específica: associação sob seleção conjunta com `municipio_residencia != municipio_servico`. Antes da implementação foram consultados `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, Boundary 6/7, VI-P5, V2 §62 e os QVS reais na `main`.

## 1. Objetivo e critério de parada

Provar **um único** fluxo SIH/RD para ano 2018 com municípios da PB distintos nos papéis de residência e serviço. A fonte independente já existente é `F1_fluxo_ano.csv`, parte dos **8 CSVs F1/F2 e do `manifest_F1_F2.json`**, produzidos do RD original em etapa histórica pelo script `tools/preflight_f1_f2_referencias_independentes.py` (commit histórico do PR #83, `26369052bd3f96de5f3eccf873c390053c20b561`). Não recriar nem editar oráculos nesta fase.

**STOP:** uma prova C3-B1 com PASS candidato e SHA pré/pós, ou BLOCKED/INCONCLUSIVE documentado. Nenhuma extensão para C3-B2, KPI, P5 visual, C4 ou Fase IX.

## 2. Seleção e reconciliação

O executor **não inventa municípios nem contagens**. Após conferir SHA do `F1_fluxo_ano.csv` com o manifesto, identifica linhas com `ano=2018`, `municipio_residencia` e `municipio_servico` com códigos PB de seis dígitos, diferentes entre si, e `internacoes_elegiveis > 0`. Escolhe determinísticamente o par com maior número de elegíveis; desempata pelos códigos. Exige `registros_rd = internacoes_elegiveis + continuidades_ident5`.

Em **cópia descartável** do `SAD_VIII_T24_ANNUAL_TEST.qvw`, seleciona somente:
- `PERIODO_ANO=2018`;
- `RES_COD_DATASUS_6` = município R do oráculo;
- `SERV_COD_DATASUS_6` = município S do oráculo.

Confere via COM o valor e a contagem das três seleções; competência mensal segue livre. Compara `Sum(QTD_REGISTRO_AIH)`, `Sum(QTD_INTERNACAO)` e diferença de ambas às três colunas do F1: `registros_rd`, `internacoes_elegiveis` e `continuidades_ident5`. Exige igualdade exata em inteiros.

**Controle de papéis:** no contexto combinado R≠S, `Count(POPULACAO_ESTIMADA)=0` e `Count(QTD_LEITOS_SUS)=0` significam **zero registros das fatos POP/LT associados a este filtro**; **não** são a afirmação de população municipal zero, ausência real de leitos, nem denominador nulo homologado para KPIs. População possui R=S na projeção, enquanto LT possui R fisicamente `NULL` na Link. Qualquer linha POP/LT alcançável nesse contexto ou desvio RD bloqueia o teste.

Este teste avalia o fluxo FLU sob filtros de papéis C na V2. **Não** autoriza usar T24 com município serviço, T25/T26 com residência, ou ignorar qualquer filtro P5 B.

## 3. Artefato e salvaguardas

**Único script:** `tools/Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1` versionado na branch **antes** de qualquer execução Windows. Reaproveita funções do executor T26 já testado para branch/HEAD limpos, inventário SHA, validação de manifesto, seleções COM e leitura numérica.

O script exige:
- QVW TEMP anual original comprovado pelo SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`; ausência/drift = BLOCKED, sem reconstruir T24;
- 10 QVDs de extração + 12 de transformação preservados por SHA, com `LINK_ANALISE.qvd` no SHA-256 congelado `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB`;
- QVWs canônicos existentes inventariados antes/depois; nenhum `Reload`, `STORE`, `Save`, escrita em QVD, QVW original ou binário do painel final;
- arquivos de evidência **somente** em `%TEMP%\SAD_VIII_C3B1_<GUID>\`: `c3b1_oracle_pair.csv`, `c3b1_reconciliation.csv`, manifestos CSV SHA pré/pós e stdout.

A prova deve ficar associada ao HEAD exato do script, ao SHA do oráculo/manifesto e ao SHA do QVW TEMP. `PASS_REFERENCE_PRECHECK_ONLY_C3B1_QV_NOT_RUN` não equivale a PASS físico.

## 4. Procedimento Windows — ainda NÃO executado

Na pasta raiz do clone, **sem limpar QVWs históricos** e sem modificar dados:

```powershell
git fetch origin test/phase-viii-c3b1-asymmetric-roles-20261019
git switch --track origin/test/phase-viii-c3b1-asymmetric-roles-20261019
git rev-parse HEAD
git status --short

$tokens=$null; $parseErrors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path .\tools\Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1).Path,
  [ref]$tokens, [ref]$parseErrors
)
if($parseErrors.Count -gt 0){
  $parseErrors | ForEach-Object { $_.ToString() }
  throw 'PARSER=BLOCKED'
}
'PARSER=PASS'
```

**Somente com parser real PASS e branch correta**, localizar os insumos anteriores **sem assumir caminhos fixos nem recriá-los**:

```powershell
$t24Candidates=@(Get-ChildItem -LiteralPath $env:TEMP -Directory -Filter 'SAD_VIII_T24_*' -ErrorAction Stop |
  ForEach-Object { Join-Path $_.FullName 'SAD_VIII_T24_ANNUAL_TEST.qvw' } |
  Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
$f1Candidates=@(Get-ChildItem -LiteralPath $env:TEMP -Directory -Filter '*f1*f2*' -ErrorAction Stop |
  Where-Object {
    (Test-Path -LiteralPath (Join-Path $_.FullName 'manifest_F1_F2.json') -PathType Leaf) -and
    (Test-Path -LiteralPath (Join-Path $_.FullName 'F1_fluxo_ano.csv') -PathType Leaf)
  })
$t24Candidates | ForEach-Object { [pscustomobject]@{Path=$_; SHA256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash} }
$f1Candidates | Select-Object FullName,LastWriteTime
```

**Exigir** uma fonte QVW existente com SHA \`7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E\` e um diretório F1/F2 real com manifest + F1. Múltiplos candidatos ou SHA divergente: **BLOCKED** para seleção controlada; não escolher por nome/data sem conferir proveniência. Definir \`$source\` e \`$f1\` com os caminhos **efetivamente observados**, nunca com caminho de exemplo.

No modo **referência sem COM**, sem \`-RunQlik\`, obter o stdout completo e confirmar \`VERDICT=PASS_REFERENCE_PRECHECK_ONLY_C3B1_QV_NOT_RUN\`:

```powershell
$logRef=Join-Path $env:TEMP 'SAD_C3B1_REFERENCE_STDOUT.txt'
& powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1 `
  -Root (Get-Location).Path -SourceQvw $source -F1F2Dir $f1 2>&1 |
  Tee-Object -FilePath $logRef
if($LASTEXITCODE -ne 0){throw 'BLOCKED: C3B1 reference preflight exit code'}
```

Após revisar o stdout, os hashes e o par assimétrico real, executar **uma única sessão física explicitamente autorizada** com o mesmo commit e \`-RunQlik\`. Se o Work não tiver acesso real ao Windows/COM, parar em \`BLOCKED_NO_LOCAL_WINDOWS_ACCESS\`, sem alegar execução:

```powershell
$logCom=Join-Path $env:TEMP 'SAD_C3B1_COM_STDOUT.txt'
& powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1 `
  -Root (Get-Location).Path -SourceQvw $source -F1F2Dir $f1 -RunQlik 2>&1 |
  Tee-Object -FilePath $logCom
if($LASTEXITCODE -ne 0){throw 'BLOCKED: C3B1 physical COM exit code'}
```

Se uma execução falhar, **STOP**. Preservar logs e os CSVs gerados; não ajustar fórmulas, remover verificações, reexecutar T24 nem disparar testes em cascata.

## 5. Estados e níveis de evidência

- `C3B1_SCRIPT=VERSIONED_STATIC_REVIEW_ONLY`: inspeção de código no Git, sem parser real Windows ou COM.
- `C3B1_ORACLE=KNOWN_FILE_GENERATOR_NOT_REOPENED_THIS_GATE`: schema confirmado no gerador histórico; arquivo local F1 e manifestos ainda dependem de preflight.
- `C3B1_QV_COM=NOT_RUN`.
- Somente `VERDICT=PASS_LOCAL_C3B1_ASYMMETRIC_ROLE_FLOW_CANDIDATE_ONLY`, com csv/manifestos, hashes e stdout analisados, habilita **conclusão restrita** do único teste C3-B1.

Permanecem: `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED` e `PRODUCTION_APPROVED=False`.

**Nenhum merge, alteração da main, geração/regravação de QVD/QVW ou início de Fase IX são autorizados por este documento.**
