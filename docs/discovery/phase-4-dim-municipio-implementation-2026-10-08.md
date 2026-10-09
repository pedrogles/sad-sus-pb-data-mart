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

## Quarto reload IV-MUNICIPIO — instrumentacao interrompida apos MAPPING LOAD (09/10/2026 00:03)

**FATO VERIFICADO — saida PowerShell do responsavel:**
- `git pull --ff-only` atualizou a branch até `539c2ae`, contendo 50 linhas de instrumentacao em `transf_dim_municipio.qvs`.
- `Qv.exe /r` com `Start-Process -Wait` retornou `QLIK_EXIT=0`; log contemporaneo `TRANSF.qvw.2026_10_09_00_03_45.log`.
- A busca `Select-String DIAG_|FAIL RD/ST/LT|...|Execution finished` retornou apenas `P4M_DIAG_MAP: MAPPING LOAD COD_DATASUS_6, 1 AS _P4M_DIAG_PRESENT`, seguido de `Execution finished`; nenhum dos `TRACE DIAG_...` foi emitido.
- `_CHECKPOINT_DIM_MUNICIPIO.csv` nao existe; `DIM_MUNICIPIO.qvd` nao teve nova evidencia de gravacao.
- Esta saida filtrada **nao inclui o erro detalhado** das ultimas linhas do log, portanto nao atribuir um codigo ou mensagem de erro nao observado.

**Causa plausivel da instrumentacao (código inspecionado):** imediatamente apos o mapping, o codigo tentava `LET vP4MDiagDimSelfExists = Exists(COD_DATASUS_6, ...)`. `Exists` e uma funcao de script para avaliacao de registros carregados em `LOAD`, nao uma verificacao confiavel via `LET` de script. Discussao tecnica Qlik de `Exists outside of LOAD`: https://community.qlik.com/t5/QlikView/Using-EXISTS-outside-of-a-LOAD/m-p/153215/highlight/true. Fonte oficial de semantica: https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/InterRecordFunctions/Exists.htm. **Sem log integral, a atribuição especifica do encerramento a essa linha segue HIPOTESE, nao FATO.**

**Correcao versionada (ainda NAO executada):** mover `Exists` e `ApplyMap` dos `LET` para expressoes de `LOAD` de auto-geracao/primeiras cinco linhas de RD/ST; usar `Peek()` nos `LET` apenas para recuperar colunas previamente calculadas. Manter a tabela diagnostica apenas em memoria e descartá-la; **nenhum dado de origem, dimensão, chave, QVD, contagem, gate fail-closed RD/ST/LT ou checkpoint foi alterado**.

**Estado:** `IV-MUNICIPIO=FAIL_CLOSED_DIAG_NOT_COMPLETED`, `PR_75=DRAFT`, `DIAG_CODE_FIXED_LOCAL_TEST_PENDING`, `PHASE_IV=IN_PROGRESS`.

**Proxima acao:** executar novo reload sincronizado e mostrar `Get-Content $log.FullName -Tail 75` em adicao a `Select-String 'DIAG_|FAIL|Execution finished'`. **Nao reexecutar se o Qlik estiver aberto**, nem declarar sucesso apenas por exit 0. Se `TRACE DIAG_` aparecer, usar amostras para isolar eventual falha agregada antes de nova alteracao.

## Quinto reload — self-lookup confirmou desencontro representacional (09/10/2026 00:06)

**FATO VERIFICADO — novo log enviado pelo responsável:**
- Branch local atualizada por `git pull --ff-only`; QlikView 12 executado de forma síncrona, `QLIK_EXIT=0`, log novo `TRANSF.qvw.2026_10_09_00_06_39.log`.
- `P4M_DIAG_MAP: MAPPING LOAD COD_DATASUS_6, 1 RESIDENT DIM_MUNICIPIO` carregou **937 linhas**.
- `P4M_DIAG_SELF` executou `Exists(COD_DATASUS_6, '250010')` e `ApplyMap('P4M_DIAG_MAP', '250010', 0)`. Ambos retornaram **0**.
- Amostras de RD residência, RD atendimento e CNES/ST exibiram exatamente a representação textual `250010`, mas `MAP=0` e `EXISTS=0` em todas.
- O script chegou ao `DIAG_SELF_LOOKUP_FAILED` e encerrou antes do gate agregado. `CHECKPOINT_EXISTS=False`; nenhum novo PASS de `DIM_MUNICIPIO`.
- Isso comprova **falha no lookup com os valores Qlik dessa execução, inclusive self-lookup**. Não comprova inexistência do município `250010` nem corrupção dos datasets.

**HIPÓTESE DE MODELAGEM TÉCNICA, ainda não confirmada pelo novo teste:** divergência entre representação numérica e textual `dual` na comparação de chaves. A documentação oficial descreve as representações dual e `Text()`: https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/data-types.htm e https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/InterpretationFunctions/Text.htm. Discussão na comunidade Qlik recomenda prefixo não-numérico uniforme quando códigos aparentam ser iguais, mas não associam: https://community.qlik.com/t5/QlikView/ApplyMap-with-LOAD-INLINE-not-working/m-p/1006302/highlight/true. **Não declarar a causa raiz comprovada apenas por este indício.**

**Correção experimental controlada, versionada no PR #75 e aguardando teste local:**
- **Apenas o gate técnico de associação**, no `TRANSFORMACAO/transf_dim_municipio.qvs`, foi substituído. A `DIM_MUNICIPIO` e seus campos/chaves continuam intocados.
- Mapa auxiliar, não persistido, `P4M_DOMAIN_TEXT_MAP`: `'M|' & Trim(Text(COD_DATASUS_6)) → 1`. O prefixo `M|` elimina interpretação como número para fins da correspondência interna.
- **Autoverificação fail-closed**: calcular flags de associação para cada uma das linhas da própria `DIM_MUNICIPIO`, agregar e exigir `self_rows = dimension_rows` e `self_missing=0` antes de carregar qualquer domínio RD/ST/LT. Emitir `TRACE PREFIXED_SELF_CHECK Rows=... Missing=...`.
- Para RD residência/atendimento, CNES ST e LT, calcular `ApplyMap('P4M_DOMAIN_TEXT_MAP','M|' & Trim(Text(campo)),0)` **linha a linha** e somente depois somar flags 0/1 em tabelas residentes, para dissociar o lookup do contexto agregado. O **gate original** ainda exige RD=566672, ST=220390, LT=35518, externas=5202 e quatro contadores unmatched=0.
- Na falha de self-check ou coverage, `EXIT SCRIPT` antes do `STORE`. Não criar QVD/checkpoint indevidos; não alterar nem inferir códigos IBGE de externos; sem fatos/Link Table.
- O prefixo **não é gravado** em `DIM_MUNICIPIO.qvd`, nem usado para alterar `Hash128('MUN',COD_DATASUS_6)`.

**Status:** `IV-MUNICIPIO=PREFIXED_LOOKUP_CODE_READY_PHYSICAL_GATE_PENDING`; `PR_75=DRAFT`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IV=IN_PROGRESS`.

**Próximo gate:** recarregar localmente após `git pull --ff-only`, Qlik fechado e `Start-Process -Wait`; exigir `PREFIXED_SELF_CHECK Rows=937 Missing=0` e, depois, checkpoint `PASS_PARTIAL_DIM_MUNICIPIO_ONLY` com `dimension_rows=937`, `municipalities_pb=223`, `external_distinct_codes=714`, `external_rd_rows=5202`, quatro unmatched=0, QVD físico novo e log contemporâneo. Os 937/714 são expectativas do último staging conhecido, não regras universais.

## Sexto reload — IV-MUNICIPIO PASS LOCAL QLIK / CHECKPOINT (09/10/2026 00:10:51)

**FATO VERIFICADO — saida PowerShell do responsavel do projeto:**

- `git pull --ff-only` atualizou a branch para `e5ef19f`; `Qv.exe /r TRANSFORMACAO/TRANSF.qvw` via `Start-Process -Wait` retornou `QLIK_EXIT=0`.
- Log contemporaneo `TRANSF.qvw.2026_10_09_00_10_46.log` com `[TRANSFORMACAO][IV-MUNICIPIO] PREFIXED_SELF_CHECK Rows=937 Missing=0`, `DIM_MUNICIPIO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`, e `Execution finished`. Nenhum `FAIL` reportado na pesquisa do log.
- CSV de checkpoint realmente presente e importado: `generated_at=09/10/2026 00:10:51`, `stage=TRANSFORMACAO_DIM_MUNICIPIO`, `status=PASS_PARTIAL_DIM_MUNICIPIO_ONLY`, **18 campos**, exatamente 1 registro.
- Campos de resultado: `dimension_rows=937`, `municipalities_pb=223`, `external_distinct_codes=714`, `external_rd_rows=5202`, `unique_surrogate_keys=937`, `invalid_dimension_rows=0`, `unmatched_ibge_2019_names=0`, `rd_residence_unmatched=0`, `rd_attendance_unmatched=0`, `st_unmatched=0`, `lt_unmatched=0`.
- `pb_name_reference_year=2019`, `source_limit=PB_ONLY_DERIVED_IBGE7_NO_EXTERNAL_IBGE_INFERENCE`, `t29_historical=NOT_APPROVED`, `facts_and_link_table=NOT_STARTED`.
- `TRANSFORMACAO/QVD/DIM_MUNICIPIO.qvd` existe fisicamente, tamanho **45.750 bytes**, `LastWriteTime=09/10/2026 00:10:51`.

**Conclusao limitada pelo escopo das evidencias:** o checkpoint interno e o artefato QVD novo foram emitidos no QlikView 12 e os controles de cobertura foram reconciliados. O teste do prefixo `M|` resolveu a falha operacional *para o conjunto presente*, mas o motivo preciso do lookup fracassado no formato numerico/dual continua **HIPOTESE**, nao uma conclusao definitiva. Nenhum dado de origem, campo da dimensao, SK academica, fato ou Link Table foi modificado pela chave auxiliar, utilizada exclusivamente no gate temporario.

**Gate ainda pendente antes do aceite final / merge PR #75:** analisar **cabecalho fisico** do QVD (quantidade de registros e 8 nomes de campos), SHA-256 de QVD e CSV e reconciliar os valores importados com a estrutura. A saida do usuario comprova a existencia/tamanho, **mas nao** contem o cabecalho nem o hash, portanto `IV-MUNICIPIO=PASS_LOCAL_QV_CHECKPOINT_PHYSICAL_FILE`, `QVD_HEADER_AND_HASH=PENDING`, `PR_75=DRAFT`, `PHASE_IV=IN_PROGRESS`. Nao declarar PASS FINAL da Fase IV; ainda restam outras seis dimensoes.

**Proximo teste local (read-only, sem reload):** abrir os primeiros bytes do QVD ate `</QvdTableHeader>`, inspecionar `NoOfRecords=937`, listar os 8 `FieldName`, conferir `SHA256` e `LastWriteTime` do QVD e CSV e comparar status e contadores. Se divergencia, bloquear merge e investigar sem apagar artefatos.
