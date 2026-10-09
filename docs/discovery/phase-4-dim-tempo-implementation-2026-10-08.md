# Fase IV — Checkpoint IV-TEMPO — DIM_TEMPO (QlikView 12)

**Data:** 08/10/2026 (UTC-03)  
**Branch:** `feat/phase-4-dim-tempo`  
**Status:** **RELOAD + CHECKPOINT + CABECALHO QVD PASS LOCAL; EXTREMOS DE DATAS E LOG PENDENTES**. Nao declarar aceite integral nem merge ate conferencia da nova execucao.

## 1. Precondicoes comprovadas documentalmente

- PR #73 integrado em `main`: squash SHA `5644bdafa5fe4e437ce3417b5368113639468267`.
- Fase III: `PASS_FINAL_RECONCILED` no QlikView 12 em 08/10/2026 21:46:48, com 10 QVDs, 107 campos exigidos, RD=566672, LT=35518, ST=220390 e IBGE=669.
- Boundary 3: 0 datas invalidas em `DT_INTER`/`DT_SAIDA` e 0 `DT_SAIDA < DT_INTER` nos RD inspecionados. Isto **nao** substitui o teste no QVD do ambiente atual.
- Boundaries 5–7: dimensao Tempo conceitualmente unica, chaves reproduziveis `Hash128` com prefixos DATA/MES/ANO, projecoes role-playing por dia/competencia/ano no painel; 3 fatos e Link Table ficam para fases posteriores.

Referencias:
- `AGENTS.md`; `docs/project/current-state.md`; `docs/academic/requirements.md`
- `docs/discovery/boundary-3-full-dataset-validation.md`
- `docs/discovery/boundary-5-historization-role-playing.md`
- `docs/discovery/boundary-6-qlikview-physical-architecture.md`
- `docs/discovery/boundary-7-implementation-plan.md`
- `docs/discovery/phase-3-final-extraction-gate-2026-10-08.md`

## 2. Escopo implementado (ainda sem teste fisico)

Arquivo externo existente modificado: `TRANSFORMACAO/transf_main.qvs`, carregado por `TRANSFORMACAO/TRANSF.qvw` via `Must_Include` da Fase I.

O script:

1. Le `EXTRACAO/QVD/_SUCCESS_EXTRACAO.csv` e exige uma linha com `EXTRACAO;PASS_FINAL_RECONCILED` e as contagens/contratos da Fase III. Preserva `T29_HISTORICAL=NOT_APPROVED`.
2. Le somente `DT_INTER` e `DT_SAIDA` de `SRC_SIH_RD.qvd`, exigindo 566.672 linhas por papel, formato `YYYYMMDD`, parse valido e roundtrip fiel.
3. Determina dinamicamente limites de dia observados no RD, sempre cobrindo pelo menos `2017-01-01..2019-12-31`. Se limites exigirem mais de 36.525 dias, **para para revisao**; nao exclui silenciosamente datas.
4. Gera `DIM_TEMPO` com um registro por dia, `%SK_TEMPO_DATA`, `%SK_TEMPO_COMPETENCIA` e `%SK_TEMPO_ANO` via `Hash128`, e atributos data, YYYYMMDD, competencia, ano, mes e dia.
5. Valida cardinalidade diaria e chave de dia unica, 36 competencias no periodo 2017–2019, tres anos, zero chaves vazias.
6. Somente depois grava `TRANSFORMACAO/QVD/DIM_TEMPO.qvd` e o marcador `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_TEMPO.csv` com `PASS_PARTIAL_DIM_TEMPO_ONLY`.

**Nao ha** `_SUCCESS_TRANSFORMACAO.csv`, fatos, Link Table, alias de PAINEL, indicadores ou alteracoes nos QVDs de staging. Um QVD de calendario diario tem repeticao intencional das SKs mensais/anuais: no futuro `PAINEL.qvw` deve usar projecoes `LOAD DISTINCT` na granularidade correspondente, conforme Boundary 7.

## 3. Procedimento de teste local (WINDOWS / QlikView 12)

Executar somente com a arvore Git limpa e `EXTRACAO/QVD/_SUCCESS_EXTRACAO.csv` do PASS de 08/10/2026 fisicamente presente:

```powershell
git status --short
git fetch origin
git switch --track origin/feat/phase-4-dim-tempo
# Se branch local ja existir, fazer checkout sem recria-la e atualizar por fast-forward.
git status --short

# Invalidar apenas o checkpoint IV-TEMPO antigo; nao apagar QVDs de staging.
Remove-Item .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_TEMPO.csv -ErrorAction SilentlyContinue

$started = Get-Date
& "$env:ProgramFiles\QlikView\Qv.exe" /r "$((Get-Location).Path)\TRANSFORMACAO\TRANSF.qvw"
$reloadExit = $LASTEXITCODE
"QLIK_EXIT=$reloadExit"

Get-Item .\TRANSFORMACAO\QVD\DIM_TEMPO.qvd, .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_TEMPO.csv | Select-Object Name, Length, LastWriteTime
Get-Content .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_TEMPO.csv
Get-FileHash .\TRANSFORMACAO\QVD\DIM_TEMPO.qvd -Algorithm SHA256
Get-ChildItem .\TRANSFORMACAO -Filter "TRANSF.qvw*.log" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

**Nao interpretar so a existencia de arquivos como PASS.** Exigir:

- `QLIK_EXIT=0` e log do reload contemporaneo encerrado sem erros `Unknown statement`/`Syntax Error` ou `ScriptErrorCount` acumulado.
- `_CHECKPOINT_DIM_TEMPO.csv` criado **depois** do inicio do reload, `stage=TRANSFORMACAO_DIM_TEMPO`, `status=PASS_PARTIAL_DIM_TEMPO_ONLY`, `invalid_date_rows=0`, `rd_inter_rows=566672`, `rd_total_date_rows=1133344`, `months_2017_2019=36`, `years_2017_2019=3`.
- `DIM_TEMPO.qvd` com data de atualizacao posterior ao inicio, cabecalho QVD inspecionado localmente, grão diário e chaves corretas. Registrar SHA-256 e contagem de linhas reais.
- Conferir nas amostras chave/dia e transicoes de mes/ano; cobrir 2017–2019, inclusive o intervalo entre as datas RD observadas e o baseline.
- Confirmar que **nenhum** `_SUCCESS_TRANSFORMACAO.csv` foi criado por este checkpoint e que QVDs da extracao nao foram alterados.

Se `QLIK_EXIT` for diferente de zero, marcador ausente ou campos/contagens divergentes, registrar `IV-TEMPO=FAIL_CLOSED` e investigar o novo log; nao fazer merge ou chamar Fase IV de PASS.

## 4. Pendencias para depois do teste

- Confirmar como o `PAINEL` projetara `DIM_TEMPO.qvd` para `DIM_TEMPO_COMPETENCIA`, `DIM_TEMPO_ANO`, `DIM_TEMPO_INTERNACAO` e `DIM_TEMPO_SAIDA` sem duplicidade de chaves mensais/anuais. Essa montagem pertence a fase posterior do PAINEL.
- Prosseguir, apos gate fisico de IV-TEMPO, para `DIM_MUNICIPIO`, preservando 5.202 RD de residencia externa sem atribuir populacao PB.
- Manter sem mudancas `T29_HISTORICAL=NOT_APPROVED`, legendas CNES exclusivamente 201909 e nomes historicos de estabelecimento nao comprovados como NULL.

## 5. Veredito inicial (antes dos testes locais)

**CHECKPOINT IV-TEMPO: CODE READY / LOCAL QLIKVIEW VALIDATION REQUIRED.** Nao ha evidencia nesta execucao remota de que `TRANSF.qvw` tenha rodado no Windows/QlikView 12. A primeira entrega academica permanece fechada e nao foi alterada.

## 6. Primeira execucao local IV-TEMPO — Qlik reload + checkpoint PASS (08/10/2026 22:17:20 UTC-03)

**FATO VERIFICADO — saida PowerShell apresentada pelo responsavel:**

- `git fetch origin` atualizou a branch remota `feat/phase-4-dim-tempo`, e `git switch --track origin/feat/phase-4-dim-tempo` criou o tracking local com sucesso.
- O marcador parcial anterior foi removido antes da execucao.
- `Qv.exe /r .../TRANSFORMACAO/TRANSF.qvw` retornou `QLIK_EXIT=0`.
- O novo checkpoint foi lido em PowerShell com o conteudo:

```csv
generated_at;stage;status;calendar_day_rows;months_2017_2019;years_2017_2019;rd_inter_rows;rd_total_date_rows;invalid_date_rows;t29_historical;facts_and_link_table
08/10/2026 22:17:20;TRANSFORMACAO_DIM_TEMPO;PASS_PARTIAL_DIM_TEMPO_ONLY;4383;36;3;566672;1133344;0;NOT_APPROVED;NOT_STARTED
```

**Interpretacao:** o script QlikView 12 concluiu e o checkpoint parcial da dimensao retornou os controles esperados: 36 competencias (2017–2019), 3 anos, 566.672 datas de admissao, 1.133.344 datas totais, zero invalidas; T29 historico continua NOT_APPROVED e fatos/Link Table nao iniciados. `IV-TEMPO=PASS_LOCAL_RELOAD_AND_CHECKPOINT_ONLY`.

**Atencao ao dominio de datas:** 4.383 dias excedem os 1.095 dias do recorte de competencias 2017–2019. O script expande os limites de calendario para abranger `DT_INTER` e `DT_SAIDA` reais; o valor pode ser legitimo, mas **as datas extremas observadas ainda nao foram fornecidas**. Nao tratar a contagem estendida como erro nem assumir suas causas sem inspecao.

**Evidencias adicionais ainda necessarias antes de merge:**
1. `Get-Item` e SHA-256 de `TRANSFORMACAO/QVD/DIM_TEMPO.qvd`, com LastWriteTime contemporaneo ao reload e `QvdNoOfRecords`/cabecalho reconciliando 4383 linhas.
2. Log contemporaneo de `TRANSF.qvw`, com final normal, sem `Unknown statement`, `Syntax Error` ou erros ocultos.
3. Confirmar min/max reais do calendario ou de `DT_INTER`/`DT_SAIDA`, para explicar os 4.383 dias, preservando historico sem truncamento.
4. Confirmar que `_SUCCESS_TRANSFORMACAO.csv` nao foi gerado e que QVDs da extracao nao foram alterados.

**Veredito vigente:** `IV-TEMPO=PASS_LOCAL_RELOAD_AND_CHECKPOINT_ONLY`, `DIM_TEMPO_QVD_AUDIT=PENDING`, `PR_74=DRAFT`, `PHASE_IV=IN_PROGRESS`. Nenhuma evidencia remota autoriza declarar Fase IV completa.

## 7. Segunda auditoria local — QVD fisico e ausencia do marcador final

**FATO VERIFICADO — saida PowerShell apresentada pelo responsavel, 08/10/2026:**

| Evidencia | Resultado |
|---|---|
| `TRANSFORMACAO/QVD/DIM_TEMPO.qvd` | Existe; tamanho **269.347 bytes** |
| `LastWriteTime` | **08/10/2026 22:17:20**, alinhado ao checkpoint |
| SHA-256 QVD | `2D26A5D789A6484D3DBFE82DAED6F917496E224A8B1821C7DA2A6302B90D8885` |
| Cabecalho QVD `NoOfRecords` | **4.383** |
| Cabecalho QVD `Fields` | **9 de 9 campos esperados**, na ordem: `%SK_TEMPO_DATA`, `%SK_TEMPO_COMPETENCIA`, `%SK_TEMPO_ANO`, `TEMPO_DATA`, `TEMPO_DATA_YYYYMMDD`, `TEMPO_COMPETENCIA`, `TEMPO_ANO`, `TEMPO_MES`, `TEMPO_DIA` |
| `_SUCCESS_TRANSFORMACAO.csv` | **NAO EXISTE**, coerente com checkpoint parcial |
| Busca por `TRANSFORMACAO/TRANSF.qvw*.log` | **NENHUM ARQUIVO ENCONTRADO** no diretorio consultado |

**Classificacao da evidencia:** `IV-TEMPO=PASS_LOCAL_RELOAD_CHECKPOINT_QVD_HEADER`. A inspecao do cabecalho demonstra cardinalidade e schema fisico, mas nao substitui a auditoria de todos os valores dos registros. A ausencia do log na busca feita **nao** implica automaticamente que o reload falhou; pode nao ter sido habilitada a opcao de log no documento QVW, ou o log estar em outro local. Nao inferir configuracao sem inspecao.

**Nao verificado:** min/max real das datas RD/calendario, ausencia de erros no log, ausencia de alteracao em QVDs de staging. A Fase IV inteira permanece **IN PROGRESS**; PR #74 em Draft.

### Pequeno ajuste de observabilidade versionado apos esta evidencia

`TRANSFORMACAO/transf_main.qvs` agora acrescenta **quatro colunas ao CSV parcial**: `rd_min_date`, `rd_max_date`, `calendar_min_date`, `calendar_max_date`, derivadas de variaveis que ja existiam no script. **O QVD e suas nove colunas permanecem inalterados pelo ajuste de codigo.** Como o ajuste ocorreu **apos o primeiro reload**, necessita **novo reload local** para ser validado. Nao atribuir ao checkpoint anterior esses campos.

Para gerar log no QlikView Desktop, abrir `TRANSFORMACAO/TRANSF.qvw` e habilitar **Settings > Document Properties > General > Generate Logfile**, preferencialmente junto de **Timestamp in Logfile Name**; salvar o QVW local. Fonte oficial: https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Document_Properties_General.htm.

### Proximo gate

1. `git pull --ff-only` na branch `feat/phase-4-dim-tempo`.
2. Habilitar log no documento QVW local e salvar (o QVW nao e versionado).
3. Apagar **apenas** `_CHECKPOINT_DIM_TEMPO.csv`, anotar hora, recarregar `TRANSF.qvw` e verificar `QLIK_EXIT=0`.
4. Conferir as quatro datas novas e checar que o intervalo em dias, inclusivo, corresponde a 4.383 registros do cabecalho QVD. Investigar datas extremas sem truncar registros da origem.
5. Localizar log contemporaneo e verificar final normal; reconfirmar QVD/marcador parcial. Se algo divergente, manter PR #74 Draft e classificar `IV-TEMPO=FAIL_CLOSED` ate diagnostico.

## 8. Terceiro reload local — arquivo de checkpoint ausente (08/10/2026 22:40:12)

**FATO VERIFICADO — saida de console apresentada pelo responsavel:**
- `git pull --ff-only` sincronizou `feat/phase-4-dim-tempo` de `ac923fd` para `75a8e3f`, trazendo os quatro campos de data no checkpoint.
- Antes do reload, o operador removeu apenas `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_TEMPO.csv` com `-ErrorAction SilentlyContinue`.
- `Qv.exe /r TRANSFORMACAO/TRANSF.qvw` devolveu `QLIK_EXIT=0`.
- `Import-Csv TRANSFORMACAO/QVD/_CHECKPOINT_DIM_TEMPO.csv` retornou **FileNotFoundException**. Os `ParseExact` subsequentes falharam por falta do objeto `$r`. O `DIAS_CALCULADOS=-739895` impresso com variaveis nulas/inexistentes **nao e um indicador valido**.
- O trecho de log das 22:40:12 mostra `P4_DIM_TEMPO_CHECKPOINT` com **15 campos**, `1 lines fetched`, `STORE P4_DIM_TEMPO_CHECKPOINT INTO [QVD\\_CHECKPOINT_DIM_TEMPO.csv]`, mensagem `DIM_TEMPO_QVD_STORED_AND_PARTIAL_CHECKPOINT_WRITTEN` e `Execution finished`.
- No log, `vP4ObservedMinDay=39448`, `vP4ObservedMaxDay=43830`, tambem limites do calendario. **43830 - 39448 + 1 = 4383 dias**. Pela origem serial de datas QlikView, esses extremos correspondem a **2008-01-01 e 2019-12-31**, sujeito a confirmacao independente a partir do QVD.

**Interpretação cautelosa:** o trecho do log comprova **execucao do comando STORE**, mas **nao comprova persistencia do CSV no diretorio examinado**. Possibilidades a investigar: resolucao do caminho relativo, gravacao em outro local, falha de escrita nao propagada, ou outra causa de I/O. Nao assumir causa sem inventario de arquivos. O QVD gerado nesta terceira execucao tampouco teve timestamp/hash novamente conferidos.

**Veredito atualizado:** `IV-TEMPO=BLOCKED_CHECKPOINT_PATH_OR_WRITE_DIAGNOSTIC`; `PR_74=DRAFT`; `PHASE_IV=IN_PROGRESS`. O **PASS parcial do primeiro reload** e a auditoria do QVD de 22:17 permanecem historicamente registrados, mas **o reload mais recente nao passou no critério de arquivo checkpoint encontrado**.

**Proximo diagnostico estritamente read-only:**
1. Procurar `_CHECKPOINT_DIM_TEMPO.csv` sob a raiz do repositório, inclusive outras pastas `QVD`; listar os arquivos e timestamps de `TRANSFORMACAO/QVD` e do diretório de execução efetivo.
2. Conferir `LastWriteTime` e SHA-256 de `TRANSFORMACAO/QVD/DIM_TEMPO.qvd` apos o reload recente.
3. Inspecionar todo o log contemporâneo para `Error`, `Failed`, `Cannot`, `Access`, `STORE`, `ScriptError`, alem do fechamento normal.
4. Somente apos localizar a causa corrigir caminho/gravacao, se necessario. Nao apagar QVDs da extração, nem alterar fatos, chaves ou modelo acadêmico.

## 9. Diagnostico posterior — persistencia e log confirmados (08/10/2026 22:40:12)

**FATO VERIFICADO — nova saida PowerShell do responsavel:**
- Busca recursiva no repositorio local encontrou **exatamente uma ocorrencia reportada de cada arquivo** no caminho esperado: `TRANSFORMACAO/QVD/DIM_TEMPO.qvd` e `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_TEMPO.csv`.
- `DIM_TEMPO.qvd`: **269.347 bytes**, `LastWriteTime=08/10/2026 22:40:12`, `SHA256=2E38647C8DBA58ED823D5E6D19DF427E78C8D41FA3A0315EBE54176AC7A5C828`.
- `_CHECKPOINT_DIM_TEMPO.csv`: **397 bytes**, `LastWriteTime=08/10/2026 22:40:12`. Existencia fisica no destino correto confirmada. **O conteudo do CSV novo ainda nao foi lido com sucesso nesta evidencia.**
- Log contemporaneo `TRANSFORMACAO/TRANSF.qvw.2026_10_08_22_40_08.log`: comandos `STORE` para QVD e checkpoint, `TRACE DIM_TEMPO_QVD_STORED_AND_PARTIAL_CHECKPOINT_WRITTEN` e `Execution finished`. A pesquisa no log apresentada encontrou somente essas linhas e mencoes em `IF ScriptErrorCount > 0` / `SET ErrorMode=0`, sem linha de falha concreta no trecho pesquisado.
- Conversao independente em PowerShell dos seriais Qlik **39448 e 43830**, com origem `1899-12-30`: `2008-01-01` e `2019-12-31`. Intervalo calendario inclusivo **4383 dias**, coerente com o checkpoint e cabecalho QVD anterior. Os limites foram derivados pelo script de `DT_INTER`/`DT_SAIDA` RD e baseline 2017–2019, mas **a causa dos registros RD com data em 2008 ainda depende de inspecao de registros da origem**.

**Correcao do diagnostico anterior:** o bloqueio `BLOCKED_CHECKPOINT_PATH_OR_WRITE_DIAGNOSTIC` foi **resolvido quanto a existencia do arquivo**, sem alteracao de codigo ou caminho. A falha anterior de `Import-Csv` ocorreu em uma consulta anterior; **nao ha causa comprovada para a falha pontual**. Nao diagnosticar automaticamente problema de filesystem, sincronizacao, concorrencia ou Qlik.

**Veredito atual:** `IV-TEMPO=PASS_LOCAL_RELOAD_AND_PHYSICAL_PERSISTENCE`; `CSV_CONTENT_VALIDATION=PENDING`; `PRE_2017_RD_DATE_INVESTIGATION=PENDING`; `PR_74=DRAFT`; `PHASE_IV=IN_PROGRESS`. Nenhuma aprovacao de T29 nem implementacao dos fatos/Link Table.

**Proxima verificacao read-only, sem novo reload:** importar agora o CSV encontrado, conferir os 15 campos e os limites `rd_min_date`, `rd_max_date`, `calendar_min_date`, `calendar_max_date`; calcular dias inclusivos com falha explicita se arquivo ou colunas estiverem ausentes. Se PASS, investigar em separado registros RD anteriores a 2017 (validade semantica, cardinalidade e papel temporal) antes de merge.

## 10. Quarto checkpoint — CSV lido e limites reconciliados (08/10/2026 22:40:12)

**FATO VERIFICADO — nova saida PowerShell do responsavel:**
- `Import-Csv -LiteralPath .\\TRANSFORMACAO\\QVD\\_CHECKPOINT_DIM_TEMPO.csv -Delimiter ';'` retornou exatamente **uma linha** e os 15 campos esperados; as quatro colunas novas de limites existem.
- `generated_at=08/10/2026 22:40:12`, `stage=TRANSFORMACAO_DIM_TEMPO`, `status=PASS_PARTIAL_DIM_TEMPO_ONLY`.
- `calendar_day_rows=4383`, `months_2017_2019=36`, `years_2017_2019=3`, `rd_inter_rows=566672`, `rd_total_date_rows=1133344`, `invalid_date_rows=0`.
- `rd_min_date=2008-01-01`, `rd_max_date=2019-12-31`, `calendar_min_date=2008-01-01`, `calendar_max_date=2019-12-31`.
- Cálculo independente de intervalo inclusivo `(calendar_max_date - calendar_min_date).Days + 1 = 4383`, igual ao checkpoint. A verificação PowerShell de divergência de cardinalidade **não lançou erro**.
- `t29_historical=NOT_APPROVED`, `facts_and_link_table=NOT_STARTED` preservados.
- Verificação anterior da mesma execução: log contemporâneo finalizou normalmente; QVD físico e CSV contemporâneos; QVD SHA-256 `2E38647C8DBA58ED823D5E6D19DF427E78C8D41FA3A0315EBE54176AC7A5C828`.

**Veredito do gate físico da dimensão:** `IV-TEMPO=PASS_LOCAL_QV_CSV_QVD_RECONCILED`. **Fase IV completa NÃO aprovada**, pois outras sete dimensões estão pendentes. **PR #74 continua Draft** até esclarecer a pertinência semântica do extremo `DT_INTER/DT_SAIDA=2008-01-01` observado nos RD de competências 2017–2019.

### Investigacao semântica read-only proposta

O extremo de 2008 é **dado real observado na origem serial do QlikView**, mas ainda não foi determinada sua frequencia, qual dos dois campos de datas o contém, a distribuição de `IDENT` e em quais competências ocorre. Não caracterizar como erro, placeholder ou internação prolongada sem inspeção de registros.

Analisar os 36 CSVs SIH/RD que alimentaram `SRC_SIH_RD.qvd`, no padrão **`BASE/CONVERTIDA/RD/RDPB*.csv`** (contrato confirmado em `EXTRACAO/ext_main.qvs`), em modo somente leitura. Reconciliar `566672` linhas e produzir **somente agregados**, sem expor `N_AIH` ou identificadores individuais: frequência por ano de `DT_INTER` anterior a 2017, frequência do dia `2008-01-01` nos campos `DT_INTER`/`DT_SAIDA`, distribuição por `IDENT`, competência de processamento e eventuais datas de saída discordantes. Não alterar origem, staging, script, chaves nem intervalos por suposição.

**Estado operativo:** `DIM_TEMPO_GATE=PASS_LOCAL`; `PRE_2017_DATE_PROVENANCE=PENDING_READ_ONLY_AUDIT`; `PR_74=DRAFT`.

## 11. Auditoria read-only dos 36 CSVs RD — proveniência do limite de 2008

**FATO VERIFICADO — saida Python local apresentada pelo responsavel:**

- Leitura somente leitura de `BASE/CONVERTIDA/RD/RDPB*.csv`, exatamente **36 arquivos**, total **566.672 linhas**, igual ao staging reconciliado. Resultado `AUDITORIA_READ_ONLY_CONCLUIDA`.
- Datas `DT_INTER`: minimo `2008-01-01`, maximo `2019-12-31`; **10.112 registros** com `DT_INTER < 2017-01-01`.
- Datas `DT_SAIDA`: minimo `2016-08-11`, maximo `2019-12-31`; **7.540 registros** com `DT_SAIDA < 2017-01-01`.
- **0 registros** com `DT_SAIDA < DT_INTER`. As contagens anteriores a 2017 são **por campo**, nao conjuntos mutuamente exclusivos nem contagem de pacientes.
- Exatamente **70 linhas com `DT_INTER=2008-01-01`**, distribuidas nas 27 competencias consecutivas `201701..201903`, todas com `IDENT='5'`. A auditoria nao reportou ocorrencia de `DT_SAIDA=2008-01-01`; todas as saidas minimas estao em 2016 ou depois. A contagem 70 refere-se a **registros administrativos**, nao individuos/internacoes unicas.
- Entre as datas antigas mais frequentes, o resultado apontou diversas datas de dezembro/2016 para ambos os papeis, compatíveis com datas reais distintas da competencia de processamento.
- O Boundary 3 ja confirma `IDENT=5` como **continuidade administrativa, nao nova internacao**, e `N_AIH` nao e chave primaria; o projeto **nao** pode converter automaticamente as 70 linhas em novas internacoes.

**HIPOTESE DE MODELAGEM / interpretacao permitida:** a continuidade administrativa `IDENT=5` e uma explicacao **compativel** com datas de admissao bem anteriores à competencia de processamento, inclusive 2008; entretanto, esta auditoria nao demonstra quantos pacientes distintos, episodios clinicos ou duracoes efetivas estão envolvidos, nem prova autenticidade clinica individual da admissao em 2008.

**DECISAO OPERACIONAL PARA O CHECKPOINT, SEM ALTERAR O MODELO ACADEMICO:** manter o calendario diario `2008-01-01..2019-12-31` (4.383 dias) e os valores originais; o recorte analitico `2017-2019` sera definido por competencia da respectiva fato, nao por corte arbitrario de `DT_INTER`/`DT_SAIDA`. Nao excluir `IDENT=5`, nao antecipar fatos, nao supor 70 novas internacoes e nao alterar a chave da dimensao. Preservar a ressalva clinica sobre a origem exata do dia `2008-01-01`.

**Veredito consolidado:** `IV-TEMPO=PASS_LOCAL_QV_CSV_QVD_RECONCILED` e `PRE_2017_RD_DATE_QA=DOCUMENTED_CONTINUITY_CONSISTENT`. Nao resta bloqueio demonstrado **na construcao tecnica da DIM_TEMPO**. A verificacao clinica individual nao faz parte do gate da dimensao. O PR #74 permanece em **Draft / ainda nao integrado**, aguardando revisao e autorizacao explicita de merge. Fase IV continua **IN PROGRESS** (7 dimensoes pendentes); `T29_HISTORICAL=NOT_APPROVED`.
