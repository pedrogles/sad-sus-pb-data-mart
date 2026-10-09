# Fase IV — Checkpoint IV-MUNICIPIO — DIM_MUNICIPIO (QlikView 12)

**Data:** 08/10/2026 (UTC-03)  
**Branch:** \`feat/phase-4-dim-municipio\`  
**Estado:** CODE READY / RELOAD QLIKVIEW 12 LOCAL PENDENTE; PR DRAFT ATE PASS FISICO.

## Fontes e decisões preservadas

- \`AGENTS.md\`, \`docs/project/current-state.md\`, \`docs/academic/requirements.md\`.
- \`docs/discovery/boundary-5-historization-role-playing.md\`, \`boundary-6-qlikview-physical-architecture.md\`, \`boundary-7-implementation-plan.md\`.
- \`docs/discovery/phase-3-municipal-crosswalk-materialization-2026-10-08.md\` — III-C5.2 PASS local, ponte **DERIVADA** do projeto com **223 códigos DATASUS6 / 223 IBGE7 oficiais / zero unmatched PB**.
- \`docs/discovery/phase-3-ibge-staging-implementation-2026-10-07.md\` — \`SRC_IBGE_POPULACAO.qvd\` com **669 município×ano** e campo real \`NOME_MUNICIPIO\`.
- \`docs/discovery/phase-4-dim-tempo-implementation-2026-10-08.md\` — IV-TEMPO PASS local, PR #74 integrado à main via squash \`1e750341621ca11f1fdb89708ded626cf9c632a1\`.

**Recorte:** 2017–2019 por competência, universo PB para dados populacionais; preservar os **5.202 registros SIH/RD de residência externa**, sem inventar população, IBGE7, UF ou nome externo. Não modificar as decisões dos Capítulos 1–2, fatos, Link Table, T29 ou staging.

## Escopo do código nesta branch

- Arquivo novo externo e versionável: \`TRANSFORMACAO/transf_dim_municipio.qvs\`.
- Alteração mínima: ao fim de \`TRANSFORMACAO/transf_main.qvs\`, \`$(Must_Include=transf_dim_municipio.qvs);\` para executar *depois* do IV-TEMPO.
- Entradas de referência somente leitura, em \`EXTRACAO/QVD/\`:
  - \`REF_MUNICIPIO_PB_DERIVADA.qvd\` (223 pares e metadados);
  - \`SRC_IBGE_POPULACAO.qvd\` (nome descritivo *proveniente do ano 2019*, sem inferir invariância histórica);
  - \`SRC_SIH_RD.qvd\` (residência, atendimento e externos);
  - \`SRC_CNES_ST.qvd\` e \`SRC_CNES_LT.qvd\` (cobertura).
- Único QVD canônico: \`TRANSFORMACAO/QVD/DIM_MUNICIPIO.qvd\`, com:
  - \`%SK_MUNICIPIO=Hash128('MUN',COD_DATASUS_6)\`;
  - \`COD_DATASUS_6\`, \`COD_IBGE_7\`, \`NOME_MUNICIPIO\`, \`UF\`;
  - \`MUNICIPIO_COBERTURA\`, \`NOME_MUNICIPIO_ANO_REFERENCIA\`, \`MUNICIPIO_NATUREZA_REFERENCIA\`.
- Cada código PB (223) recebe IBGE7 e nome **do XLS 2019**, com natureza derivada explicitada; não se trata de nomenclatura histórica garantida para 2017/2018.
- Códigos distintos das **residências RD fora PB** entram na dimensão com **SK e código DATASUS6 preservados**, \`COD_IBGE_7\`, \`NOME_MUNICIPIO\` e \`UF\` nulos; status \`RESIDENCIA_EXTERNA_SEM_REFERENCIA_IBGE\`. Quantos códigos distintos existem depende da execução real: **não presumir contagem antes do reload**.
- Bloqueio *fail-closed* se os códigos externos reais não forem todos seis dígitos, se a ponte PB tiver desvios, se faltar nome 2019 em PB, se ocorrer duplicidade de códigos/SK, ou se SIH RD, CNES ST/LT tiverem municípios fora da dimensão.
- Saída parcial **apenas após QVD válido**: \`TRANSFORMACAO/QVD/_CHECKPOINT_DIM_MUNICIPIO.csv\`, com status \`PASS_PARTIAL_DIM_MUNICIPIO_ONLY\` e controles 223 PB, 5.202 RD externos, domínios zero unmatched.
- **Não gerar \`_SUCCESS_TRANSFORMACAO.csv\`**, não criar fatos, \`LINK_ANALISE\`, aliases de painel ou dados de população para fora da PB.

### Ponto de atenção antes de aceitar

A III-C5.1 classificou 5.202 RD como residência não-PB, **sem comprovar individualmente o formato de cada código externo**. O IV-MUNICIPIO agora faz a verificação estrita de seis dígitos. Se algum registro não passar, **não corrigir inventando código**, nem eliminar registro; retornar ao diagnóstico e definir exceção documentada.

## Gate local — PowerShell

**Pré-condição:** repositório local com trabalho salvo, árvore limpa e QlikView 12 instalado. O operador possui \`TRANSFORMACAO/TRANSF.qvw\` local com \`Must_Include=transf_main.qvs\` e os QVDs da extração Fase III.

\`\`\`powershell
git status --short
git fetch origin
git switch --track origin/feat/phase-4-dim-municipio

# Apagar exclusivamente o checkpoint municipal anterior (se houver).
Remove-Item .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_MUNICIPIO.csv -ErrorAction SilentlyContinue

$inicio = Get-Date
& "$env:ProgramFiles\QlikView\Qv.exe" /r "$((Get-Location).Path)\TRANSFORMACAO\TRANSF.qvw"
"QLIK_EXIT=$LASTEXITCODE"

$cp = ".\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_MUNICIPIO.csv"
if (-not (Test-Path $cp)) { throw "IV-MUNICIPIO checkpoint ausente" }
if ((Get-Item $cp).LastWriteTime -lt $inicio) { throw "IV-MUNICIPIO checkpoint antigo" }

$r = @(Import-Csv -LiteralPath $cp -Delimiter ';')
if ($r.Count -ne 1) { throw "Checkpoint deve ter uma linha" }
$r[0] | Format-List
if ($r[0].status -ne "PASS_PARTIAL_DIM_MUNICIPIO_ONLY") { throw "IV-MUNICIPIO sem PASS" }
if ([int]$r[0].municipalities_pb -ne 223 -or
    [int]$r[0].external_rd_rows -ne 5202 -or
    [int]$r[0].dimension_rows -ne
       (223 + [int]$r[0].external_distinct_codes)) { throw "Cardinalidade municipal divergente" }

Get-Item .\TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd |
    Select-Object Name,Length,LastWriteTime
Get-FileHash .\TRANSFORMACAO\QVD\DIM_MUNICIPIO.qvd -Algorithm SHA256

$log = Get-ChildItem .\TRANSFORMACAO -Filter 'TRANSF.qvw*.log' -File |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($log) { Get-Content $log.FullName -Tail 55 }

"FULL_SUCCESS_MARKER_EXISTS=$(
    Test-Path .\TRANSFORMACAO\QVD\_SUCCESS_TRANSFORMACAO.csv
)"
\`\`\`

Se a branch ja existir localmente, \`git switch feat/phase-4-dim-municipio\` e \`git pull --ff-only\` em vez de recria-la.

**Não basta \`QLIK_EXIT=0\`**. O gate requer checkpoint novo, 223 PB, 5.202 RD externos, número de códigos externos distintos, zero inválidos, zero unmatched RD/ST/LT, SK distintas para cada linha, QVD novo cujo cabeçalho confirme a contagem, e log contemporâneo finalizado normalmente.

**Em caso de falha:** enviar log e resultado; não marcar PASS, não fazer merge nem apagar QVDs de staging. A investigação deve ser limitada ao checkpoint municipal; IV-TEMPO e Fase III continuam historicamente PASS.

## Veredito da execução remota

\`IV-TEMPO=PASS_LOCAL_QV_CSV_QVD_RECONCILED\` (já integrado);
\`IV-MUNICIPIO=CODE_READY_LOCAL_QV_GATE_PENDING\`;
\`T29_HISTORICAL=NOT_APPROVED\`;
\`PHASE_IV=IN_PROGRESS\`.
