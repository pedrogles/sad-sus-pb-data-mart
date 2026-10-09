# Fase IV — Checkpoint IV-MUNICIPIO — DIM_MUNICIPIO (QlikView 12)

**Data:** 08/10/2026 (UTC-03)  
**Branch:** `feat/phase-4-dim-municipio`  
**Estado:** CODE READY / RELOAD QLIKVIEW 12 LOCAL PENDENTE; PR DRAFT ATE PASS FISICO.

## Fontes e decisões preservadas

- `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`.
- `docs/discovery/boundary-5-historization-role-playing.md`, `boundary-6-qlikview-physical-architecture.md`, `boundary-7-implementation-plan.md`.
- `docs/discovery/phase-3-municipal-crosswalk-materialization-2026-10-08.md` — III-C5.2 PASS local, ponte **DERIVADA** do projeto com **223 códigos DATASUS6 / 223 IBGE7 oficiais / zero unmatched PB**.
- `docs/discovery/phase-3-ibge-staging-implementation-2026-10-07.md` — `SRC_IBGE_POPULACAO.qvd` com **669 município×ano** e campo real `NOME_MUNICIPIO`.
- `docs/discovery/phase-4-dim-tempo-implementation-2026-10-08.md` — IV-TEMPO PASS local, PR #74 integrado à main via squash `1e750341621ca11f1fdb89708ded626cf9c632a1`.

**Recorte:** 2017–2019 por competência, universo PB para dados populacionais; preservar os **5.202 registros SIH/RD de residência externa**, sem inventar população, IBGE7, UF ou nome externo. Não modificar as decisões dos Capítulos 1–2, fatos, Link Table, T29 ou staging.

## Escopo do código nesta branch

- Arquivo novo externo e versionável: `TRANSFORMACAO/transf_dim_municipio.qvs`.
- Alteração mínima: ao fim de `TRANSFORMACAO/transf_main.qvs`, `$(Must_Include=transf_dim_municipio.qvs);` para executar *depois* do IV-TEMPO.
- Entradas de referência somente leitura, em `EXTRACAO/QVD/`:
  - `REF_MUNICIPIO_PB_DERIVADA.qvd` (223 pares e metadados);
  - `SRC_IBGE_POPULACAO.qvd` (nome descritivo *proveniente do ano 2019*, sem inferir invariância histórica);
  - `SRC_SIH_RD.qvd` (residência, atendimento e externos);
  - `SRC_CNES_ST.qvd` e `SRC_CNES_LT.qvd` (cobertura).
- Único QVD canônico: `TRANSFORMACAO/QVD/DIM_MUNICIPIO.qvd`, com:
  - `%SK_MUNICIPIO=Hash128('MUN',COD_DATASUS_6)`;
  - `COD_DATASUS_6`, `COD_IBGE_7`, `NOME_MUNICIPIO`, `UF`;
  - `MUNICIPIO_COBERTURA`, `NOME_MUNICIPIO_ANO_REFERENCIA`, `MUNICIPIO_NATUREZA_REFERENCIA`.
- Cada código PB (223) recebe IBGE7 e nome **do XLS 2019**, com natureza derivada explicitada; não se trata de nomenclatura histórica garantida para 2017/2018.
- Códigos distintos das **residências RD fora PB** entram na dimensão com **SK e código DATASUS6 preservados**, `COD_IBGE_7`, `NOME_MUNICIPIO` e `UF` nulos; status `RESIDENCIA_EXTERNA_SEM_REFERENCIA_IBGE`. Quantos códigos distintos existem depende da execução real: **não presumir contagem antes do reload**.
- Bloqueio *fail-closed* se os códigos externos reais não forem todos seis dígitos, se a ponte PB tiver desvios, se faltar nome 2019 em PB, se ocorrer duplicidade de códigos/SK, ou se SIH RD, CNES ST/LT tiverem municípios fora da dimensão.
- Saída parcial **apenas após QVD válido**: `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_MUNICIPIO.csv`, com status `PASS_PARTIAL_DIM_MUNICIPIO_ONLY` e controles 223 PB, 5.202 RD externos, domínios zero unmatched.
- **Não gerar `_SUCCESS_TRANSFORMACAO.csv`**, não criar fatos, `LINK_ANALISE`, aliases de painel ou dados de população para fora da PB.

### Ponto de atenção antes de aceitar

A III-C5.1 classificou 5.202 RD como residência não-PB, **sem comprovar individualmente o formato de cada código externo**. O IV-MUNICIPIO agora faz a verificação estrita de seis dígitos. Se algum registro não passar, **não corrigir inventando código**, nem eliminar registro; retornar ao diagnóstico e definir exceção documentada.

## Gate local — PowerShell

**Pré-condição:** repositório local com trabalho salvo, árvore limpa e QlikView 12 instalado. O operador possui `TRANSFORMACAO/TRANSF.qvw` local com `Must_Include=transf_main.qvs` e os QVDs da extração Fase III.

```powershell
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
```

Se a branch ja existir localmente, `git switch feat/phase-4-dim-municipio` e `git pull --ff-only` em vez de recria-la.

**Não basta `QLIK_EXIT=0`**. O gate requer checkpoint novo, 223 PB, 5.202 RD externos, número de códigos externos distintos, zero inválidos, zero unmatched RD/ST/LT, SK distintas para cada linha, QVD novo cujo cabeçalho confirme a contagem, e log contemporâneo finalizado normalmente.

**Em caso de falha:** enviar log e resultado; não marcar PASS, não fazer merge nem apagar QVDs de staging. A investigação deve ser limitada ao checkpoint municipal; IV-TEMPO e Fase III continuam historicamente PASS.

## Veredito da execução remota

`IV-TEMPO=PASS_LOCAL_QV_CSV_QVD_RECONCILED` (já integrado);
`IV-MUNICIPIO=CODE_READY_LOCAL_QV_GATE_PENDING`;
`T29_HISTORICAL=NOT_APPROVED`;
`PHASE_IV=IN_PROGRESS`.

## Primeiro acionamento local IV-MUNICIPIO — sem evidência de reload novo

**FATO VERIFICADO — PowerShell fornecido pelo responsável do projeto:** no checkout `feat/phase-4-dim-municipio`, `git status --short` vazio e `git switch --track` concluído. `Qv.exe /r TRANSFORMACAO/TRANSF.qvw` retornou `QLIK_EXIT=0`, mas imediatamente após:

- `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_MUNICIPIO.csv` **não foi encontrado**.
- `DIM_MUNICIPIO.qvd` **não foi encontrado**.
- `DIM_TEMPO.qvd` e `_CHECKPOINT_DIM_TEMPO.csv` permaneciam com timestamp anterior `08/10/2026 22:40:12`.
- A busca do log mais recente retornou `TRANSF.qvw.*.log` **antigo, de 08/10/2026 22:40:12**, que termina na etapa IV-TEMPO e `Execution finished`, sem mostrar linha `[TRANSFORMACAO][IV-MUNICIPIO]`.

**Interpretação:** `QLIK_EXIT=0` isolado **não é PASS do reload**; não há evidência de que o `Must_Include=transf_dim_municipio.qvs` tenha executado nesta tentativa. O log consultado é histórico, não testemunha a nova execução. **Não atribuir causa ao script municipal, ao dataset externo ou ao filesystem** com base nisso. Possibilidades incluem processo GUI existente ou saída antes de observar artefatos; ambas exigem diagnóstico.

**Próximo gate:** verificar `Get-Process Qv`, existência e atualização de `TRANSF.qvw`, presença do include no `transf_main.qvs` local e timestamps dos logs; se QlikView estiver aberto, fechá-lo normalmente antes de novo teste controlado. Para nova tentativa, usar `Start-Process -Wait -PassThru` com `/r` e caminho absoluto para esperar a conclusão, e **exigir** log contemporâneo e novo checkpoint. **Não apagar QVD de extração ou alterar scripts durante diagnóstico.**

**Estado:** `IV-MUNICIPIO=RELOAD_NOT_OBSERVED / PHYSICAL_GATE_PENDING`; `IV-TEMPO=MERGED_PASS`; `PR_75=DRAFT`; `T29_HISTORICAL=NOT_APPROVED`.

## Segundo reload IV-MUNICIPIO — falha de cobertura no self-map (08/10/2026 23:55)

**FATO VERIFICADO — resultado PowerShell enviado pelo responsavel:**

- `git pull --ff-only` atualizou a branch local, `Start-Process -Wait -PassThru` aguardou `Qv.exe /r TRANSFORMACAO/TRANSF.qvw`; `QLIK_EXIT=0`.
- Log **novo** `TRANSF.qvw.2026_10_08_23_55_04.log` (`LOG_NOVO=True`), portanto o include `transf_dim_municipio.qvs` executou fisicamente.
- Perfil de `DIM_MUNICIPIO` em memoria: **937 linhas**, **937 chaves SK distintas**, **937 DATASUS6 distintos**, **223 PB**, **714 codigos externos distintos**, **0 linhas invalidas**. A verificacao `937 <> 223 + 714` passou.
- `MAP_P4M_DIM_CODE` estava definido como `MAPPING LOAD COD_DATASUS_6, COD_DATASUS_6 RESIDENT DIM_MUNICIPIO`, 937 linhas carregadas conforme log.
- No gate de dominio, `ApplyMap('MAP_P4M_DIM_CODE', ... , '#MISSING#')` registrou **566672 RD residencia sem match, 566672 RD atendimento sem match, 220390 ST sem match e 35518 LT sem match**. Essas quatro contagens equivalem precisamente aos totais de cada fonte; nao se trata de 4 familias realmente sem municipio reconhecido.
- O log encerrou em `[TRANSFORMACAO][IV-MUNICIPIO] FAIL RD/ST/LT domain coverage` e `EXIT SCRIPT`, apesar do codigo de saida 0. **Nenhum** `DIM_MUNICIPIO.qvd` nem `_CHECKPOINT_DIM_MUNICIPIO.csv` foi gravado; fail-closed funcionou.
- O preflight III-C5.1 ja havia comprovado **zero** unmatched para os codigos PB em RD/ST/LT; 5.202 registros de residencia nao PB, preservados.

**Diagnostico:** o conjunto da dimensao foi construido coerentemente, mas **a verificacao por `ApplyMap` falhou sistematicamente**. A causa de baixo nivel do retorno de todos os defaults na expressao de agregacao ainda nao foi demonstrada. Nao imputar o problema aos dados oficiais, nao modificar 223 pares, nao inventar identificadores externos.

**Correcao pontual em branch PR #75 (codigo, nao validada fisicamente):** a tabela de mapeamento auto-referente (mesmo campo em suas duas colunas) foi retirada **somente do gate de dominio**. As quatro verificacoes agora usam `Not Exists(COD_DATASUS_6, Trim(Text(<campo_fonte>)))`, sobre a coluna `COD_DATASUS_6` ja carregada e verificada unica na propria `DIM_MUNICIPIO`. Segundo a documentacao QlikView, `Exists(field_name,expr)` retorna verdadeiro se esse valor ja foi carregado para `field_name`. Referencia: https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/InterRecordFunctions/Exists.htm.

**Controles preservados:** 223 PB; 714 externos apenas como cardinalidade **observada no reload anterior** (nao hardcode); 5.202 linhas RD externas; unicidade SK/COD_DATASUS6; codigo IBGE7 e nome 2019 somente PB; nulos externos; coverage zero unmatched esperado; scripts versionados; QVD/checkpoint gravados apenas apos gate PASS.

**Estado atualizado:** `IV-MUNICIPIO=FIX_CODE_READY_RELOAD_REQUIRED`, `PR_75=DRAFT`, `PHASE_IV=IN_PROGRESS`. O `QLIK_EXIT=0` de 23:55 nao e PASS. A correcao com `Exists` ainda exige **outro reload controlado** e auditoria de QVD/CSV/log antes de merge.

### Proxima execucao local

Na branch `feat/phase-4-dim-municipio` atualizada via `git pull --ff-only`, manter o QlikView fechado antes de `Start-Process -Wait`. Executar `TRANSFORMACAO/TRANSF.qvw` e exigir log novo, `_CHECKPOINT_DIM_MUNICIPIO.csv` novo com `PASS_PARTIAL_DIM_MUNICIPIO_ONLY`, 223 PB, 5.202 RD residentes externos, 714 codigos externos se mantido mesmo staging, `dimension_rows=937`, zero invalidos e zero unmatched, `DIM_MUNICIPIO.qvd` novo. Os 714/937 sao expectativas **reconciliadas na memoria do reload de 23:55**, a revisar se staging alterar. Nunca aprovar so por ExitCode 0.

## Terceiro reload IV-MUNICIPIO — Exists tambem falhou no controle agregado (08/10/2026 23:59)

**FATO VERIFICADO — saida PowerShell fornecida pelo responsavel:**
- `git pull --ff-only` atualizou a branch para a versao com `Not Exists(COD_DATASUS_6, Trim(Text(...)))` nos quatro testes; `Select-String` confirmou quatro expressoes nas linhas 237–251.
- `Start-Process ... -Wait` aguardou o reload, `QLIK_EXIT=0` e `LOG_NOVO=True`.
- O log Qlik de 23:59 confirmou leitura de RD/ST/LT e novo encerramento `FAIL RD/ST/LT domain coverage`. Valores testados: **566.672 RD residencia sem match, 566.672 RD atendimento sem match, 220.390 ST sem match e 35.518 LT sem match**, com os quatro totais das fontes inalterados.
- Nem `DIM_MUNICIPIO.qvd` nem `_CHECKPOINT_DIM_MUNICIPIO.csv` foram gerados.
- **Conclusao**: a substituicao de `ApplyMap` por `Exists` **NAO resolveu** o problema. O ultimo reload nao constitui PASS. Nao afirmar incompatibilidade entre os codigos sem teste do valor real e do contexto de avaliacao do Qlik.

**Proximo diagnostico, ainda sem alterar contrato do modelo ou tratar dados originais:** instrumentacao temporaria versionada no mesmo `transf_dim_municipio.qvs`, executada somente depois do teste de integridade 223+714=937 e antes da verificacao final. Ela:
1. carrega mapa auxiliar `P4M_DIAG_MAP` com `COD_DATASUS_6 → 1`, em vez de codigo → ele proprio;
2. calcula `Exists` e `ApplyMap` com um codigo da propria DIM;
3. le apenas os **5 primeiros registros** RD e ST em tabelas temporarias em memoria, compara residencia, atendimento e localizacao com esse mapa, e emite `TRACE DIAG_...`;
4. elimina amostras temporarias e **mantem inalterado o gate fail-closed** RD/ST/LT e a regra de nao gerar QVD/checkpoint se houver unmatched;
5. **nao gera arquivo diagnostico nem modifica fontes**; so loga codigos municipais e flags, sem identificadores de pacientes.

Documentacao de semantica:
- QlikView `Exists(field_name,expr)`: https://help.qlik.com/pt-BR/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/InterRecordFunctions/Exists.htm
- QlikView `Mapping` exige duas colunas — comparacao e retorno: https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/ScriptPrefixes/Mapping.htm
- QlikView `First n` limita numero de registros carregados: https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/ScriptPrefixes/First.htm

**Status:** `IV-MUNICIPIO=FAIL_CLOSED_2_RELOADS`; `ROOT_CAUSE=UNVERIFIED`; `DIAGNOSTIC_TRACE_CODE_READY`; `PR_75=DRAFT`; `PHASE_IV=IN_PROGRESS`. Antes de outra tentativa de mudar regra ou associações, coletar `TRACE [TRANSFORMACAO][IV-MUNICIPIO] DIAG_...` do log do novo reload. Nenhum outro conjunto de dados foi alterado.
