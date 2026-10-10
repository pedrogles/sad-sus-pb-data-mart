# Fase V — Contrato de medidas e associações da FATO_INTERNACAO — Discovery

**Data:** 09/10/2026  
**Modo:** `DISCOVERY / READ-ONLY CONTRACT / NO FACT IMPLEMENTATION`  
**Branch:** `feat/phase-5-fato-internacao-contract-discovery`  
**Repositório:** `pedrogles/sad-sus-pb-data-mart`  
**Situação:** `CONTRACT_DRAFT_PENDING_PHYSICAL_MEASURE_AND_ASSOCIATION_GATES`

Este documento não modifica o modelo acadêmico nem reabre os Capítulos 1 e 2. Nenhum QVD de fato, Link Table, PAINEL ou sucesso global de transformação foi gerado por esta Discovery.

## 1. Hierarquia e decisões preservadas

- Requisitos e modelagem: `docs/academic/requirements.md`, `docs/academic/chapter-1-2-modeling.md`, especialmente RN03–RN06, RN14, RN17–RN20, capítulos de `FATO_INTERNACAO`.
- Decisão física: `docs/discovery/boundary-5-historization-role-playing.md`, `docs/discovery/boundary-6-qlikview-physical-architecture.md`, `docs/discovery/boundary-7-implementation-plan.md`.
- Fonte: `EXTRACAO/ext_main.qvs` grava `EXTRACAO/QVD/SRC_SIH_RD.qvd` a partir de 36 CSVs RD; 17 campos do registro e quatro campos de proveniência.
- Fase IV: oito dimensões em `TRANSFORMACAO/QVD`. Scripts dimensionais existentes definem as expressões de SK e não devem ser alterados para viabilizar a fato.
- SK da fato já validada no teste local de 2 recargas e aprovada **com restrições**: `docs/discovery/phase-5-fato-internacao-sk-preflight-2026-10-09.md`. PR #82 integrado em `ceacef87a6a5a77299a87743133ec9b86aca9b24`.

## 2. FATO VERIFICADO — grão, volume e identidade

- **Grão:** exatamente uma linha para cada registro administrativo SIH/RD (AIH processada), mesmo quando `IDENT=5` identifica continuidade; não tratar linha como pessoa única ou episódio único.
- **Volume de controle:** 566.672 registros distribuídos em 36 competências (201701–201912): 2017=187.726, 2018=187.293, 2019=191.653.
- **Unicidade SK técnica:** `Hash128('RD', Text(_META_SOURCE_FILE), Text(ANO_CMPT), ..., Text(MORTE))` em ordem integral registrada no preflight versionado; 566.672 distintos/0 nulos em QlikView 12, e **duas recargas com conjuntos exatos idênticos** (`ONLY_A_KEYS=0`, `ONLY_B_KEYS=0`). A identidade técnica é conteúdo+arquivo, **não** identidade permanente perante correção da AIH; exigência de fonte 2017–2019 congelada.
- `N_AIH` não é PK: foram 880 linhas excedentes em grupos de `N_AIH` repetidos dentro das competências.
- `IDENT=5`: 11.583 registros. `IDENT=1`: 555.089 registros. Residência fora da PB: 5.202 registros, preservados sem atribuir população da PB.

## 3. Matriz de medidas (contrato acadêmico aprovado; reconciliação física pendente)

| Campo de saída acadêmico | Fonte RD no staging | Regra aplicável | Teste exigido |
|---|---|---|---|
| `QTD_REGISTRO_AIH` | uma linha física RD | 1 por registro | soma **566.672** |
| `QTD_INTERNACAO` | `IDENT` | 0 quando `IDENT='5'`; 1 para `IDENT='1'` observado | soma **555.089**; `IDENT5` conta somente como registro |
| `DIAS_PERMANENCIA` | `DIAS_PERM` | preservar a medida numérica por linha, sem negativar nem multiplicar em joins | total geral e anual devem coincidir com o **preflight fonte independente** |
| `VALOR_TOTAL` | `VAL_TOT` | preservar valor numérico por linha, sem juntar ou somar campos homônimos de outras fatos | total geral e anual conforme fonte; interpretar decimal/escala no QlikView antes de comparar |
| `INDICADOR_OBITO` | `MORTE` | preservar indicador 0/1 do registro | contagem de linhas `MORTE=1` por ano/total igual ao preflight; **não assumir número de pacientes distintos** |

**FATO VERIFICADO pelo preflight da fonte (execução local relatada em 09/10/2026):** os totais reais por ano e agregado foram obtidos com `Decimal` nos CSVs. **DECISÃO PENDENTE:** confirmar as cinco medidas no QVD staging por reload independente no QlikView 12; `VAL_TOT`/`DIAS_PERM` são lidos numericamente no staging, mas diferenças de tipo, escala ou parsing ainda precisam ser descartadas. Não inferir PASS do Qlik pelo PASS da fonte.

**Ferramenta adicionada ao repositório:** `tools/preflight_fato_internacao_medidas.py` — percorre 36 CSVs, compara competências/ano/IDENT/linhas/repetição de N_AIH/residência externa, calcula dias e valores com `decimal.Decimal`, soma flags de morte, apresenta totais anuais e gerais; **não escreve arquivo**. **EXECUTADA no Windows** no conjunto integral real em 09/10/2026, com `VERDICT=PASS_RD_MEASURES_SOURCE_ONLY_QLIK_RECONCILIATION_PENDING`. Não contém novos campos nem muda as regras acadêmicas.

## 4. Associações previstas — chaves e semânticas

### 4.1 Conformadas que pertencem à LINK_ANALISE (não duplicar no modelo associativo factual final)

| Papel lógico | Fonte da fato | Referência física já versionada | Estado |
|---|---|---|---|
| Tempo competência | `_META_SOURCE_COMPETENCE`/`ANO_CMPT+MES_CMPT` | `DIM_TEMPO`: `Hash128('MES', AAAAMM)` | fórmula de dimensão verificada; associação da fato **a testar** |
| Tempo ano analítico | ano da competência SIH/RD | `DIM_TEMPO`: `Hash128('ANO', Year(...))` | cuidar da representação numérica/dual de Year no Qlik |
| Município residência | `MUNIC_RES` | `DIM_MUNICIPIO`: `Hash128('MUN', COD_DATASUS_6)` | deve abranger inclusive 714 códigos externos, sem IBGE7 imputado |
| Município serviço/atendimento | `MUNIC_MOV` | `DIM_MUNICIPIO`: `Hash128('MUN', COD_DATASUS_6)` | atende à correspondência PB da validação integral |
| Estabelecimento em competência | `CNES` + competência mensal SIH | `DIM_ESTABELECIMENTO`: `Hash128('ESTAB', CNES, COMPETENCIA)` | **não** usar versão de ST posterior |

Essas coordenadas fazem parte da **Link Table aprovada no Boundary 6**; na fato final, compartilhar somente `%LINK_KEY` com `LINK_ANALISE`, sem carregar chaves conformadas homônimas como associações paralelas. Os valores técnicos utilizados para gerar a Link Table podem existir em tabelas de trabalho e controles, mas não podem criar caminhos físicos extras no modelo publicado.

### 4.2 Exclusivas diretamente ligadas à FATO_INTERNACAO

| Papel | Origem RD | Chave prevista, conforme script dimensional |
|---|---|---|
| Data internação | `DT_INTER` | `%SK_TEMPO_INTERNACAO` derivada de `Hash128('DATA', AAAAMMDD)`, validada contra `DIM_TEMPO.qvd` |
| Data saída | `DT_SAIDA` | `%SK_TEMPO_SAIDA` derivada de `Hash128('DATA', AAAAMMDD)` |
| Procedimento realizado | `PROC_REA` + competência | `%SK_PROCEDIMENTO = Hash128('PROC', PROC_REA, COMPETENCIA)`; a mesma competência do SIGTAP |
| Diagnóstico principal | `DIAG_PRINC` | `%SK_DIAGNOSTICO = Hash128('CID10', codigo_normalizado)`; alinhar exatamente normalização da fase IV (`Text(RTrim(Text(DIAG_PRINC)))`) |
| Caráter do atendimento | `CAR_INT` | `%SK_CARATER_ATENDIMENTO = Hash128('CAR', codigo_2_caracteres)`; preservar zeros |
| Motivo de saída | `COBRANCA` | **nome físico já aprovado**: `%SK_MOTIVO_SAIDA = Hash128('MOT', codigo_2_caracteres)`, conforme `transf_dim_motivo_saida_permanencia.qvs`. Não inventar segunda chave física divergente |

**Status da cobertura:** nos Boundaries 3/4 e nos gates das dimensões, foram registrados `0` unmatched para o estabelecimento mensal, município, procedimento realizado, diagnóstico e domínios relevantes. **Não assumir automaticamente** `0` no QVD factual novo: testes devem verificar chaves e mapeamentos após conversões exatas, com 566.672 linhas preservadas.

## 5. Gate de implementação ainda aberto — %LINK_KEY

**FATO VERIFICADO:** Boundary 6 escolheu `LINK_ANALISE`, não fato concatenada. Boundary 7 fixou coordenadas compartilhadas de internação: competência, ano, município de residência, município serviço e versão de estabelecimento.

**DECISÃO PENDENTE:** a serialização física final (ordem, tipagem/texto, nulos explícitos, separadores e prevenção de colisão semântica) de `%LINK_KEY` **ainda é um contrato a validar em conjunto com as outras duas fatos**. Não gerar uma chave isolada que depois mude de sentido para `FATO_CAPACIDADE_LEITO` e `FATO_POPULACAO`. A Link Table será construída na Fase VI; a fato deve seguir o contrato que venha a ser aprovado para todos os processos.

Assim, a sequência segura é: (1) medir e reconciliar a fonte RD; (2) testar fisicamente as chaves dimensionais e cardinalidades em documento Qlik isolado; (3) fechar a serialização canônica da Link Table com as três fatos; (4) somente então implementar/gravar `FATO_INTERNACAO.qvd` em `TRANSF.qvw` sob gate expresso. Não criar sucesso global parcial.

## 6. Gates objetivos antes da implementação factual

- [x] Executar `tools/preflight_fato_internacao_medidas.py` no Windows e registrar os totais anuais e gerais de `DIAS_PERM`, `VAL_TOT` e mortes. **PASS sobre os 36 CSVs**, com saída informada pelo responsável; SHA individual dos arquivos não foi emitido por este preflight e deve permanecer associado aos manifestos existentes.
- [ ] Validar no QlikView 12 (documento isolado) as cinco medidas contra a fonte, com atenção a zeros, casas decimais e eventuais diferenças de arredondamento. QVS versionado: `TRANSFORMACAO/phase_v_fato_internacao_qlik_measures_preflight.qvs`; executor: `tools/validar_fato_internacao_medidas_qlik.ps1`. **A versão Qlik ainda não foi executada**.
- [ ] Testar **566.672 linhas** preservadas, 36 competências, **566.672 SK técnicas únicas**, `IDENT5=11583`, `QTD_INTERNACAO=555089`, `QTD_REGISTRO_AIH=566672`, **0 órfãos** em cada dimensão obrigatória, 5.202 residências externas preservadas.
- [ ] Garantir `Hash128('ANO', numeric_year)` idêntico às versões de `DIM_TEMPO`; data (competência, internação e saída) e procedimentos devem usar tipos/normalização da mesma dimensão.
- [ ] Projetar `%LINK_KEY` de modo compatível com as três fatos e sem `$Syn` ou loops; testes T17/T18 dependem do contrato compartilhado e da Fase VI.
- [ ] Não salvar QVD factual, marcador global de transformação, Link Table ou objetos de painel antes de resolver os gates aplicáveis.
- [ ] `T29_HISTORICAL=NOT_APPROVED` preservado; a ausência de nomes CNES históricos não elimina leitos nem dispensa ressalva visível futura (1.965/2.021 **pares-mês** sem rótulo histórico comprovado, não percentual de leitos).

**Veredito desta Discovery após o Python PASS:** `FATO_INTERNACAO_MEASURES_SOURCE=PASS`, `FATO_INTERNACAO_MEASURES_QV=NOT_EXECUTED`, `FATO_INTERNACAO_CONTRACT=DOCUMENTED_PENDING_PHYSICAL_QV_AND_LINK_KEY_GATES`, `FACT_QVD=NOT_STARTED`.

## 7. Evidência física — medidas SIH/RD (Python READ-ONLY, 09/10/2026)

O responsável executou na branch do PR #83:

```powershell
.\.venv\Scripts\python.exe tools\preflight_fato_internacao_medidas.py --root .
```

O script concluiu com `VERDICT=PASS_RD_MEASURES_SOURCE_ONLY_QLIK_RECONCILIATION_PENDING`, **36 arquivos / 36 competências / 566.672 registros** e `OUTPUT_FILES_WRITTEN=0`. Houve apenas `SyntaxWarning` no docstring devido a barras invertidas no exemplo PowerShell; corrigido em `tools/preflight_fato_internacao_medidas.py` com docstring raw nesta branch. O aviso não afetou as medidas.

| Ano | Registros AIH | Internações contadas | `IDENT=5` | `MORTE=1` | Dias de permanência | Valor total (R$) |
|---|---:|---:|---:|---:|---:|---:|
| 2017 | 187.726 | 183.532 | 4.194 | 8.626 | 1.039.396 | 208.882.120,74 |
| 2018 | 187.293 | 183.311 | 3.982 | 8.649 | 1.038.921 | 218.267.536,76 |
| 2019 | 191.653 | 188.246 | 3.407 | 9.336 | 1.055.261 | 232.234.991,55 |
| **Total** | **566.672** | **555.089** | **11.583** | **26.611** | **3.133.578** | **659.384.649,05** |

- `RD_RESIDENCE_EXTERNAL_ROWS=5202`; `N_AIH_MONTHLY_EXTRA_ROWS=880`.
- `QVD_BINARY_BODY_INSPECTED=False` e `QLIK_MEASURES_TEST_EXECUTED=False` na execução Python.
- `DIAS_PERMANENCIA` e `VALOR_TOTAL` somados em escala original com `decimal.Decimal` nos CSVs; representam controles, **não totais de QVD transformado**.
- `INDICADOR_OBITO_TOTAL=26611` é a soma das flags administrativas `MORTE=1`, **não quantidade de pessoas únicas**.
- `tools/validar_fato_internacao_medidas_qlik.ps1` cria/reabre apenas o QVW isolado `TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT.qvw` para executar o QVS versionado; o QVS valida contagens anuais e totais, somando valores em **centavos inteiros** (`65938464905`) para minimizar diferenças de apresentação decimal. Sem `STORE`, `JOIN`, fato nem QVD gerado; o COM runner foi somente preparado e **não recebeu execução no Windows** até esta revisão.
- Após PASS do Qlik, avançar à validação física das SKs dimensionais, papéis temporais/municipais e ao contrato conjunto da `%LINK_KEY`; **não gerar FATO_INTERNACAO** por inferência deste PASS de fonte.

## 8. Falha QlikView — GROUP BY anual (bloqueio em 09/10/2026)

O responsável executou o executor versionado `tools/validar_fato_internacao_medidas_qlik.ps1` no Windows, após fast-forward local para `c64d05b`, com o QVS SHA-256 `08EB5932288A23A09C97EF88B10B4B081BC61EDD207A1FC3390C0062CDFC9E5F`.

```text
DOCUMENT_REUSED=False
MODE=PHASE_V_QV_STAGING_MEASURES_READ_ONLY
FACT_QVD_GENERATED=False
OUTPUT_DATA_FILES_WRITTEN=0
RELOAD_STARTED=True
RELOAD_RETURNED=True
STAGING_QVD_SHA256_UNCHANGED=True
LOG=TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT.qvw.log
2026-10-09 23:40:47 0008 [V5-RD-MEAS] START QVD_STAGING_READ_ONLY
2026-10-09 23:40:47 0056 [V5-RD-MEAS] VERDICT=BLOCKED_YEAR_AGGREGATION_ERROR
VERDICT=BLOCKED_OR_INCONCLUSIVE_CHECK_QLIK_LOG
```

**FATO VERIFICADO:** a leitura do QVD e a conferência inicial de `NoOfRows('V5_RD_MEASURE_INPUT')=566672` prosseguiram além dos respectivos gates, e houve elevação de `ScriptErrorCount` após executar o bloco `V5_RD_MEASURE_YEAR ... RESIDENT V5_RD_MEASURE_INPUT GROUP BY _V5_YEAR`. QVD de staging SHA-256 inalterado. O log filtrado **não mostrou a mensagem diagnóstica original do QlikView** (e.g. `Invalid expression`, `Field not found`, `Syntax Error`); **não supor causa** nem dizer que medidas numéricas divergiram. A falha independe do `SyntaxWarning` Python do docstring, já corrigido.

**DECISÃO PENDENTE — investigação mínima antes de editar o QVS:** consultar as linhas completas de `TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT.qvw.log` ao redor da linha 0053 e dos eventos `Error`/mensagens de erro. Se for comprovado defeito de expressão, corrigir somente o preflight isolado na branch, versionar a alteração, e ter em conta que o QVW isolado anterior contém o script antigo: **não sobrescrever silenciosamente** um QVW existente. Corrigir ou recriar de forma controlada apenas o documento temporário isolado, preservando staging e script de produção.

**Estado:** `MEASURES_SOURCE_RD=PASS`; `MEASURES_QV_STAGING=BLOCKED_YEAR_AGGREGATION_ERROR`; `FACT_QVD=NOT_STARTED`; `LINK_ANALISE=NOT_STARTED`; PR #83 permanece Draft, sem merge.

## 9. Causa raiz confirmada e correção versionada do preflight Qlik (09/10/2026)

**FATO VERIFICADO:** o responsável compartilhou as últimas 90 linhas **completas** de `TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT.qvw.log`. QlikView Desktop **12.0.20000.0 x64**, ambiente pt-BR, leu `SRC_SIH_RD.qvd` com **6 campos projetados / 566.672 registros**, passou nos dois gates iniciais e falhou na instrução `V5_RD_MEASURE_YEAR:` (linha 53 do QVS), com mensagem inequívoca:

```text
2026-10-09 23:40:47 0053 GROUP BY _V5_YEAR
2026-10-09 23:40:47 Erro: Error in expression:
2026-10-09 23:40:47 ABS is not a valid function
2026-10-09 23:40:47 0056 [V5-RD-MEAS] VERDICT=BLOCKED_YEAR_AGGREGATION_ERROR
```

**Causa raiz:** `Abs(...)` não é a função disponível para valor absoluto na expressão do QlikView. A documentação oficial da QlikView define `Fabs(x)` como função de valor absoluto, utilizável em expressões de script: <https://help.qlik.com/pt-BR/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/ChartFunctions/GeneralNumericFunctions/fabs.htm> e <https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/ChartFunctions/GeneralNumericFunctions/general-numeric-functions-charts.htm>.

**Correção mínima aplicada somente na branch do PR #83:**

```diff
- OR Abs(_V5_VALUE*100-Round(_V5_VALUE*100,1))>0.001
+ OR Fabs(_V5_VALUE*100-Round(_V5_VALUE*100,1))>0.001
```

Alterações relacionadas:
- `TRANSFORMACAO/phase_v_fato_internacao_qlik_measures_preflight.qvs`: substituição **exata de uma função**, preservando contagens, regras, totais e formatação de centavos.
- `tools/validar_fato_internacao_medidas_qlik.ps1`: novo destino de teste `TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT_R2.qvw`; não sobrescrever `V5_RD_MEASURE_PREFLIGHT.qvw` original nem seu log. O guard contra scripts divergentes e comparação de SHA-256 do staging permanecem ativos.

**Estado:** `SOURCE_RD=PASS`, `QLIK_R1=BLOCKED_INVALID_ABS_FUNCTION`, `QLIK_R2=FIXED_IN_BRANCH_PENDING_PHYSICAL_RELOAD`. Esta correção foi baseada na mensagem real do log e na documentação do fabricante; **não equivale a PASS de execução QlikView**. A tabela fato, `LINK_ANALISE` e `PAINEL` continuam `NOT_STARTED`, e a `main` permanece intocada por este PR Draft.

## 10. R2 — measures numericamente parciais; interpretação monetária R3 pendente

**FATO VERIFICADO (QlikView 12, recarga local R2 em 09/10/2026 23:47:07):** após substituir `Abs` por `Fabs` na branch, o `TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT_R2.qvw` produziu a seguinte evidência:

```text
YEAR=2017 ROWS=187726 NEW=183532 CONT=4194 DEATHS=8626 DAYS=1039396 VALUE_CENTS=0 BAD=1
YEAR=2018 ROWS=187293 NEW=183311 CONT=3982 DEATHS=8649 DAYS=1038921 VALUE_CENTS=0 BAD=1
YEAR=2019 ROWS=191653 NEW=188246 CONT=3407 DEATHS=9336 DAYS=1055261 VALUE_CENTS=0 BAD=1
TOTAL ROWS=566672 NEW=555089 CONT=11583 DEATHS=26611 DAYS=3133578 VALUE_CENTS=0 MONTHS=36 INVALID=566672 BAD=3
VERDICT=BLOCKED_QVD_STAGING_MEASURES_MISMATCH
STAGING_QVD_SHA256_UNCHANGED=True
FACT_QVD_GENERATED=False
OUTPUT_DATA_FILES_WRITTEN=0
```

Os totais de registros, `IDENT`, `MORTE`, dias e competências **correspondem à fonte**; `VALUE_CENTS=0` e as 566.672 flags `INVALID` **não correspondem**. A falha não é prova de valores zero reais. O QVS anterior usava `Num(VAL_TOT)` sobre o QVD. O script de extração `EXTRACAO/ext_main.qvs` carrega `VAL_TOT` do CSV **sem conversão explícita**, em ambiente local QlikView pt-BR.

**HIPÓTESE TÉCNICA para teste (não aprovada como regra produtiva):** `VAL_TOT` do QVD tem representação textual de número com **ponto decimal** e não recebeu valor numérico válido no `Num()` do preflight R2. A documentação da QlikView diferencia `Num()` (formatação de número) e `Num#()` (interpretação numérica explícita): [Num# — QlikView Help](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/InterpretationFunctions/num_hash.htm), [Num — QlikView Help](https://help.qlik.com/pt-BR/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/FormattingFunctions/Num.htm).

**R3 — correção experimental isolada, ainda não executada fisicamente:**

```qlik
Num#(Trim(Text(VAL_TOT)), '#', '.', ',') AS _V5_VALUE,
Text(VAL_TOT) AS _V5_VALUE_RAW,
If(IsNum(VAL_TOT),1,0) AS _V5_VALUE_NATIVE_NUM,
```

O QVS de teste também emite, por ano e total, `NATIVE_NUM`, `PARSE_BAD` e `RAW_BLANK`. O gate exige **566.672** linhas monetárias não vazias e interpretáveis (`PARSE_BAD=0`, `RAW_BLANK=0`), soma em centavos exatamente `65938464905`, resultados anuais idênticos ao Python e `INVALID=0`; não aprova implicitamente qualquer arredondamento, coercão ou descarte de registros. `Num#` **não foi aplicado** aos QVDs de extração nem à fato de produção.

**Preservação de evidências:** `tools/validar_fato_internacao_medidas_qlik.ps1` agora usa `TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT_R3.qvw`, guardando `R1` e `R2` intactos. Veredito atual: `MEASURES_SOURCE=PASS`, `MEASURES_QV_R1=BLOCKED_ABS`, `MEASURES_QV_R2=BLOCKED_NUMERIC_VALUE`, `MEASURES_QV_R3=PREPARED_PENDING_RUN`, `FACT_QVD=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`.

**DECISÃO PENDENTE:** confirmar com a próxima saída do QlikView se a hipótese de separador decimal explica a divergência. Se R3 falhar, **não** implementar conversão na fato; investigar os valores textuais reais no QVD e o parser antes de qualquer mudança de produção.

## 11. R3 — PASS de reconciliação das cinco medidas no QVD de staging

**FATO VERIFICADO pelas saídas de execução fornecidas pelo responsável (09/10/2026 23:52:31–23:52:32):** a branch do PR #83 foi atualizada via `git pull --ff-only` até `65231f0`. O QlikView 12 recarregou **novo documento isolado** `TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT_R3.qvw`, com o QVS `phase_v_fato_internacao_qlik_measures_preflight.qvs` de SHA-256 **`91D9A40ACFFE840902B1B05ACFFC64D62A55CAFD6831AF4A55F2403E8A3EB254`**.

```text
DOCUMENT_REUSED=False
MODE=PHASE_V_QV_STAGING_MEASURES_READ_ONLY
FACT_QVD_GENERATED=False
OUTPUT_DATA_FILES_WRITTEN=0
RELOAD_STARTED=True
RELOAD_RETURNED=True
STAGING_QVD_SHA256_UNCHANGED=True
YEAR=2017 ROWS=187726 NEW=183532 CONT=4194 DEATHS=8626 DAYS=1039396 VALUE_CENTS=20888212074 BAD=0 NATIVE_NUM=0 PARSE_BAD=0 RAW_BLANK=0
YEAR=2018 ROWS=187293 NEW=183311 CONT=3982 DEATHS=8649 DAYS=1038921 VALUE_CENTS=21826753676 BAD=0 NATIVE_NUM=0 PARSE_BAD=0 RAW_BLANK=0
YEAR=2019 ROWS=191653 NEW=188246 CONT=3407 DEATHS=9336 DAYS=1055261 VALUE_CENTS=23223499155 BAD=0 NATIVE_NUM=0 PARSE_BAD=0 RAW_BLANK=0
TOTAL ROWS=566672 NEW=555089 CONT=11583 DEATHS=26611 DAYS=3133578 VALUE_CENTS=65938464905 MONTHS=36 INVALID=0 BAD=0 NATIVE_NUM=0 PARSE_BAD=0 RAW_BLANK=0
VERDICT=PASS_QVD_STAGING_FIVE_MEASURES_RECONCILED
DIMENSION_ASSOCIATION_GATE=NOT_EXECUTED
LINK_KEY_GATE=NOT_EXECUTED
```

**Conclusão estrita:** no **QVD de staging**, `QTD_REGISTRO_AIH`, `QTD_INTERNACAO`, `INDICADOR_OBITO`, `DIAS_PERMANENCIA` e `VALOR_TOTAL` coincidiram com as somas independentes dos CSVs para cada ano e o período completo. `NATIVE_NUM=0` confirma que `VAL_TOT` não era reconhecido numericamente pelo Qlik na leitura direta; `Num#(Trim(Text(VAL_TOT)), '#', '.', ',')` interpretou todas as 566.672 linhas, sem nulos/blank, com soma monetária correta aos centavos. **Esta conversão está validada no preflight isolado, ainda não inserida/validada no script factual de produção**. O valor agregado `65938464905` é centavos de R$ 659.384.649,05; não confundir com um valor monetário em reais.

**Gate encerrado:** `FATO_INTERNACAO_MEASURES_SOURCE=PASS`, `FATO_INTERNACAO_MEASURES_STAGING_QV=PASS`. **Gates abertos:** integridade física das SKs dimensionais e papéis role-playing; serialização única de `%LINK_KEY` para três processos; produção de `FATO_INTERNACAO.qvd` ainda `NOT_STARTED`. Não há CI nem inspeção binária independente do QVD nesta execução. `T29_HISTORICAL=NOT_APPROVED` preservado.

## 12. Próximo gate — cobertura física de 11 papéis dimensionais (preparado, não executado)

Scripts de teste **somente leitura** adicionados ao Draft PR #83:

- `TRANSFORMACAO/phase_v_fato_internacao_qlik_dim_roles_preflight.qvs`: constrói nove **mapeamentos de domínio em memória** a partir dos sete QVDs dimensionais relevantes (`DIM_TEMPO` em três papéis físicos: dia, competência e ano; `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`, `DIM_DIAGNOSTICO`, `DIM_CARATER_ATENDIMENTO`, `DIM_MOTIVO_SAIDA_PERMANENCIA`). `DIM_TIPO_LEITO` pertence à fato de capacidade, não à internação. Consulta o QVD `SRC_SIH_RD.qvd`, produz somente **flags de cobertura** e totais em memória; não produz dimensões nem fato.
- `tools/validar_fato_internacao_dim_roles_qlik.ps1`: cria/reabre exclusivamente `TRANSFORMACAO/V5_RD_DIM_ROLES_PREFLIGHT.qvw`, com log Qlik nativo, guarda da identidade exata do QVS versionado e **SHA-256 dos oito arquivos QVD de entrada** (staging + sete dimensões) antes/depois da recarga. Não sobrescreve `TRANSF.qvw`, R1/R2/R3 nem seus logs.

Os **11 papéis de chave** examinados, com seus contratos já existentes:

| Papel | Origem SIH/RD | Compatibilidade de chave avaliada |
| --- | --- | --- |
| COMP | `_META_SOURCE_COMPETENCE` | `Hash128('MES', AAAAMM)` → `DIM_TEMPO.%SK_TEMPO_COMPETENCIA` |
| ANO | `ANO_CMPT` | `Hash128('ANO', ano_numérico)` → `DIM_TEMPO.%SK_TEMPO_ANO` |
| INTER | `DT_INTER` | `Hash128('DATA', AAAAMMDD)` → `DIM_TEMPO.%SK_TEMPO_DATA` |
| SAIDA | `DT_SAIDA` | `Hash128('DATA', AAAAMMDD)` → `DIM_TEMPO.%SK_TEMPO_DATA` |
| RES | `MUNIC_RES` | `Hash128('MUN', DATASUS6)` → `DIM_MUNICIPIO.%SK_MUNICIPIO` |
| SERV | `MUNIC_MOV` | `Hash128('MUN', DATASUS6)` → `DIM_MUNICIPIO.%SK_MUNICIPIO` |
| ESTAB | `CNES` + `_META_SOURCE_COMPETENCE` | `Hash128('ESTAB', CNES, competência)` → `DIM_ESTABELECIMENTO.%SK_ESTABELECIMENTO` |
| PROC | `PROC_REA` + competência | `Hash128('PROC', código, competência)` → `DIM_PROCEDIMENTO.%SK_PROCEDIMENTO` |
| DIAG | `DIAG_PRINC` | `Hash128('CID10', Text(RTrim(Text(DIAG_PRINC))))` → `DIM_DIAGNOSTICO.%SK_DIAGNOSTICO` |
| CAR | `CAR_INT` normalizado em 2 dígitos | `Hash128('CAR', código)` → `DIM_CARATER_ATENDIMENTO.%SK_CARATER_ATENDIMENTO` |
| MOT | `COBRANCA` normalizado em 2 dígitos | `Hash128('MOT', código)` → `DIM_MOTIVO_SAIDA_PERMANENCIA.%SK_MOTIVO_SAIDA` |

O teste exige `ROWS=566672`, `MONTHS=36`, `EXTERNAL=5202` e **zero chaves órfãs por papel**. Também exige que os oito QVDs de entrada mantenham seus SHA-256. O uso de mapas em memória verifica cobertura sem fazer `JOIN` físico sobre os 566.672 registros — técnica descrita pela [QlikView Help: ApplyMap](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/MappingFunctions/ApplyMap.htm) e [Mapping](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/ScriptPrefixes/Mapping.htm).

**Limites:** este diagnóstico NÃO testa a materialização dos aliases físicos role-playing no `PAINEL`, não valida ausência de loops/$Syn em um modelo multi-fato, não cria `%LINK_KEY` e não prova o contrato de `LINK_ANALISE`. O mapeamento de `ANO_CMPT` como número via `Num#` e a compatibilidade exata dos 11 hashes **ainda dependem do reload físico**. Eventuais órfãos devem ser investigados sem preencher nulos, mudar as dimensões aprovadas ou relaxar o gate automaticamente.

**Status atual:** `MEASURES_CSV=PASS`, `MEASURES_STAGING_QV=PASS`, `DIMENSION_ROLE_SK_CHECK=PREPARED_NOT_EXECUTED`, `LINK_KEY=UNRESOLVED`, `FACT_QVD=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`.

## 13. Primeiro teste físico de SK por papel (10/10/2026 00:02:40) — BLOCKED

**FATO VERIFICADO pela saída do QlikView 12 fornecida pelo responsável:** após `git pull --ff-only` para `9c15b39`, o QVW isolado `TRANSFORMACAO/V5_RD_DIM_ROLES_PREFLIGHT.qvw` executou com QVS SHA-256 `84795435D6AC7B46C336A484AF16FC1ACBBE3B477E15276324900625778A74C4`. O runner devolveu:

```text
DOCUMENT_REUSED=False
RELOAD_STARTED=True
RELOAD_RETURNED=True
ALL_8_INPUT_QVD_SHA256_UNCHANGED=True
[V5-RD-DIM] TOTAL ROWS=566672 MONTHS=36 EXTERNAL=5202 MISS_COMP=566672 MISS_ANO=0 MISS_INTER=566672 MISS_SAIDA=566672 MISS_RES=0 MISS_SERV=0 MISS_ESTAB=0 MISS_PROC=0 MISS_DIAG=0 MISS_CAR=0 MISS_MOT=1
[V5-RD-DIM] VERDICT=BLOCKED_DIMENSION_ROLE_SK_UNMATCHED
FACT_QVD_GENERATED=False
OUTPUT_DATA_FILES_WRITTEN=0
```

**Interpretação limitada:** sete dos 11 papéis de cobertura de SK bateram integralmente (**ANO, RES, SERV, ESTAB, PROC, DIAG, CAR**); **COMP, INTER, SAIDA** falharam em todos os 566.672 registros e **MOT** falhou em um registro. Cobertura parcial **não** equivale à integridade física aprovada. SHA-256 dos oito QVDs de entrada permaneceu inalterado e a contagem/grão da entrada foi preservada. Os `566672` unmatched das datas **não comprovam** ausência de meses/dias em `DIM_TEMPO` sem distinguir valores dos atributos e serialização usada na expressão `Hash128`; o `MOT=1` não pode ser descartado nem imputado.

**DECISÃO PENDENTE:** comparar (somente leitura) cobertura por **valores naturais** das datas/competências e de `COBRANCA` contra os atributos dimensionais, juntamente com chaves calculadas por expressões alternativas derivadas estritamente do script dimensional. Investigar a ocorrência de MOT por **código normalizado e frequência**, sem publicar dados individualmente identificáveis (`N_AIH` não deve ser exibido). Preservar dimensões da Fase IV e as fontes físicas até evidenciar causa exata. Contrato `%LINK_KEY` permanece bloqueado; `FATO_INTERNACAO.qvd` não criada.

## 14. Diagnóstico R2 de temporalidade e motivo (preparado; sem execução Qlik)

**FATO VERIFICADO no repositório canônico:** `TRANSFORMACAO/transf_main.qvs` constrói as SKs temporais com `Hash128('DATA', Text(Date(serial, 'YYYYMMDD')))`, `Hash128('MES', Text(Date(serial, 'YYYYMM')))` e `Hash128('ANO', Year(serial))`. `DIM_TEMPO` também guarda os atributos `TEMPO_DATA_YYYYMMDD` e `TEMPO_COMPETENCIA`. Em contraste, o primeiro preflight R1 derivou `Hash128('DATA'|'MES', Trim(Text(campo RD)))`. A semelhança visual dos textos não comprova equivalência binária da expressão/dualidade: verificar antes de propor mudança nas dimensões. `TRANSFORMACAO/transf_dim_motivo_saida_permanencia.qvs` validou previamente todos os 566.672 `COBRANCA` **por código natural** (26 códigos observados, zero códigos sem referência), enquanto o preflight de SK R1 encontrou **1** registro sem correspondência por `Hash128('MOT', codigo_normalizado)`. Isto precisa de diagnóstico específico, sem mascarar a exceção.

**Scripts diagnósticos adicionados à branch do PR #83:**

- `TRANSFORMACAO/phase_v_fato_internacao_qlik_dim_roles_diagnostic_r2.qvs`, read-only. Compara a cobertura da competência e de ambas as datas por (1) SK **original** `DIM_TEMPO`; (2) texto natural `TEMPO_COMPETENCIA`/`TEMPO_DATA_YYYYMMDD`; (3) SK **recalculada** a partir do atributo da própria dimensão; (4) SK gerada por interpretação `Date#(..., 'YYYYMM'|'YYYYMMDD')` e formatação explícita `Text(Date(...))`. Na própria dimensão registra quantidade de linhas cujas SKs persistidas diferem da re-hash feita sobre seus atributos. Para `MOT`, verifica a correspondência por SK original, código natural e SK recalculada da dimensão. Reporta exclusivamente **código normalizado de dois dígitos e frequência** dos grupos de exceção, sem `N_AIH` ou demais identificadores pessoais/administrativos.
- `tools/diagnosticar_fato_internacao_dim_roles_r2_qlik.ps1`, executor COM do QVS acima em **novo** `TRANSFORMACAO/V5_RD_DIM_ROLES_DIAGNOSTIC_R2.qvw`. O primeiro QVW `V5_RD_DIM_ROLES_PREFLIGHT.qvw` e log permanecem inalterados. Guarda equivalência de script, log atual e SHA-256 dos **mesmos oito QVDs de entrada**. Não faz `JOIN`, `STORE`, concatenação de fatos ou `PAINEL`.

**Critério de encerramento desta execução:** `VERDICT=DIAG_CAPTURED_NOT_APPROVED` significa exclusivamente que foram computados os contadores de diagnóstico sobre `566672` linhas/36 meses e que erros de script conhecidos não ocorreram. **Não é PASS de SK**, não exige que hashes alternativos deem zero, não altera a modelagem e não permite criar `FATO_INTERNACAO.qvd`. Resultado esperado é uma comparação entre misses de texto natural, SK original e SK recomposta capaz de separar (a) ausência de dado na dimensão, (b) divergência de representação/Hash128 e (c) erro pontual de normalização do motivo.

**Estado:** sete papéis com cobertura SK integral confirmada em R1; `COMP/INTER/SAIDA` 100% unmatched e `MOT` um unmatched aguardando diagnóstico R2; PR #83 Draft sem merge, `FACT_QVD=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`.

## 15. Diagnóstico R2 executado — saída do runner inconclusiva por filtro de log (10/10/2026)

**FATO VERIFICADO (saída PowerShell do responsável):** após atualizar a branch até `0b37f60`, criou-se `TRANSFORMACAO/V5_RD_DIM_ROLES_DIAGNOSTIC_R2.qvw` (novo, `DOCUMENT_REUSED=False`); o QVS tinha SHA-256 `CFA41178C0F009BCCF9131989860BFF8E0972F2ABED119FBE40C95A02A2F5D18`. O `Reload()` retornou ao executor sem valor explícito de API, `ALL_8_INPUT_QVD_SHA256_UNCHANGED=True`, `FACT_QVD_GENERATED=False`, `OUTPUT_DATA_FILES_WRITTEN=0`, mas a saída concluiu `VERDICT=BLOCKED_OR_INCONCLUSIVE_CHECK_QLIK_DIMENSION_LOG`, **sem linha diagnóstica** exibida. **Não inferir** que o QVS executou com sucesso ou falhou; este veredito é do executor, não do QlikView.

**Defeito de observabilidade comprovado no código versionado:** `tools/diagnosticar_fato_internacao_dim_roles_r2_qlik.ps1` foi copiado do executor dimensional R1 e manteve `[V5-RD-DIM]` no filtro `Where-Object` e no detector de `BLOCKED`; o script R2 escreve **`[V5-RD-DIAG]`**. A espera do PowerShell também procurava `VERDICT=(PASS|BLOCKED)` e não reconhecia o sucesso diagnóstico `VERDICT=DIAG_CAPTURED_NOT_APPROVED`. Essas diferenças são suficientes para explicar a **ausência das linhas no stdout**, mesmo que o Qlik tenha produzido log válido. **Não comprovam que o QVS não tenha erro interno.**

**Correção versionada somente no PR #83:** o runner agora filtra `[V5-RD-DIAG]`, detecta `VERDICT=(DIAG_CAPTURED_NOT_APPROVED|BLOCKED)`, distingue erro e imprime as 75 linhas finais do log nativo quando a validação não fecha. O runner preserva o mesmo QVW de diagnóstico e as verificações SHA-256 de oito QVDs, não muda o QVS, os dados ou os checkpoints aprovados. **Esta alteração do runner ainda não foi executada no Windows.**

**Próxima evidência mínima antes de novo reload:** consultar `Get-Content -LiteralPath '.\TRANSFORMACAO\V5_RD_DIM_ROLES_DIAGNOSTIC_R2.qvw.log' | Select-Object -Last 120`. A extração do log atual é **read-only** e informa se o QVS R2 concluiu com `DIAG_CAPTURED_NOT_APPROVED`, produziu os contadores de `CALENDAR`/`RD`/`MOT_EXCEPTION` ou sofreu falha de script. **Nenhum gate de integridade dimensional foi fechado.**

## 16. R2 nativo confirmado: causas temporais, motivo e preflight R3 (10/10/2026)

**FATO VERIFICADO pelo log QlikView 12 entregue pelo responsável (10/10/2026 00:10:41–00:10:43):** o diagnóstico em `V5_RD_DIM_ROLES_DIAGNOSTIC_R2.qvw`, originalmente marcado como inconclusivo **apenas pelo leitor PowerShell**, foi executado até o final pelo QlikView. O log contém `VERDICT=DIAG_CAPTURED_NOT_APPROVED`, `FACT_QVD_GENERATED=False`, `OUTPUT_DATA_FILES_WRITTEN=0`; o executor já havia confirmado `ALL_8_INPUT_QVD_SHA256_UNCHANGED=True`. O QVS executado tinha SHA-256 `CFA41178C0F009BCCF9131989860BFF8E0972F2ABED119FBE40C95A02A2F5D18`.

```text
CALENDAR ROWS=4383 DIM_MONTH_REHASH_MISS=0 DIM_DAY_REHASH_MISS=0 MOT_DIM_ROWS=28 DIM_MOT_REHASH_MISS=0
RD ROWS=566672 MONTHS=36 MONTH_ORIG=566672 MONTH_NAT=566672 MONTH_REHASH=566672 MONTH_DATEFORM=0 INTER_ORIG=566672 INTER_NAT=566672 INTER_REHASH=566672 INTER_DATEFORM=0 SAIDA_ORIG=566672 SAIDA_NAT=566672 SAIDA_REHASH=566672 SAIDA_DATEFORM=0 MOT_ORIG=0 MOT_NAT=0 MOT_REHASH=0
MOT_EXCEPTION_GROUPS=0
VERDICT=DIAG_CAPTURED_NOT_APPROVED
```

**Interpretação comprovada (limitada aos 566.672 registros):** os **4383 registros da DIM_TEMPO** e as **28 linhas de DIM_MOTIVO_SAIDA_PERMANENCIA** não apresentaram SK divergente quando os hashes foram refeitos usando os atributos da própria dimensão. Ao derivar as SKs temporais da fonte com `Hash128('MES', Text(Date(Date#(texto,'YYYYMM'),'YYYYMM')))` e `Hash128('DATA', Text(Date(Date#(texto,'YYYYMMDD'),'YYYYMMDD')))`, **os três papéis ficaram com zero chaves órfãs**. Os hashes diretos de texto e as comparações naturais no R2 indicaram 566.672 misses; portanto, **não** são expressões equivalentes às SKs originais nesse QlikView 12, embora a representação visual sugira que sejam. Não excluir datas nem reescrever `DIM_TEMPO`.

**Motivo de saída — resultado conflitante ainda pendente:** R1 apresentou `MISS_MOT=1`, mas R2 apresentou **`MOT_ORIG=0, MOT_NAT=0, MOT_REHASH=0, MOT_EXCEPTION_GROUPS=0`** usando a mesma lógica normalizada de `COBRANCA` e as SKs persistidas. Isso refuta a hipótese de órfão permanente **nesta recarga**, porém uma única execução divergente não autoriza assumir estabilidade. **Não remover a ocorrência do registro nem alterar a dimensão ou critério de aceite para acomodar o resultado.** Atribuir causa de R1 (ex.: materialização de hash, cache, efeito da carga ou não determinismo) depende de reprodução — nenhuma dessas hipóteses foi demonstrada.

**R3 — preflight completo de 11 papéis preparado, NÃO EXECUTADO:**

- `TRANSFORMACAO/phase_v_fato_internacao_qlik_dim_roles_preflight_r3.qvs` deriva somente as **três SKs temporais** com a expressão `Date#() + Date() + Text()` comprovada em R2; mantém sem modificação as outras oito expressões, incluindo `MOT`. Reaproveita o baseline estrito dos **11 papéis**, `ROWS=566672`, `MONTHS=36`, `EXTERNAL=5202` e **zero unmatched em todos os 11 campos**.
- `tools/validar_fato_internacao_dim_roles_r3_qlik.ps1` gera exclusivamente `V5_RD_DIM_ROLES_PREFLIGHT_R3.qvw`, preservando os QVWs/logs anteriores; lê os oito QVDs de entrada e confere SHA-256 de todos, log nativo contemporâneo, totais e marcador `PASS_QV_STAGING_11_DIMENSION_ROLES_NO_ORPHANS`; em falha mostra o trecho final do log.
- Se `MISS_MOT=1` retornar, **não declarar PASS**; avaliar comparação da mesma lógica nos diferentes QVWs sob o mesmo snapshot e, se necessário, repetir a investigação pontual por código e frequência antes de criar fato.

**Estado:** `TEMPORAL_SK_R2_CONVERSION_COVERAGE=PASS`; `MOT_R1_R2_DISCREPANCY=OPEN`; `FULL_11_ROLE_SK_R3=PREPARED_NOT_RUN`; `FACT_QVD=NOT_STARTED`; `LINK_ANALISE=NOT_STARTED`; `ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED`; `T29_HISTORICAL=NOT_APPROVED`. A política aprovada da SK de registro e as cinco medidas reconciliadas continuam válidas; nenhuma implementação de fato, Link Table ou dashboard é inferida deste diagnóstico.

## 17. R3 de integridade dos 11 papéis — PASS físico em 10/10/2026 00:21:17

**FATO VERIFICADO por saída PowerShell/QlikView 12 fornecida pelo responsável:** após `git pull --ff-only` da branch do PR #83 até `d291f5a`, `tools/validar_fato_internacao_dim_roles_r3_qlik.ps1` criou novo QVW isolado `TRANSFORMACAO/V5_RD_DIM_ROLES_PREFLIGHT_R3.qvw` (`DOCUMENT_REUSED=False`). A expressão temporal R3 está no `phase_v_fato_internacao_qlik_dim_roles_preflight_r3.qvs`, SHA-256 **`541A67D244D41FEEA955C9DD0252A86A67EA1F427FE677398A288B97B8840610`**. Execução local entre 00:21:14 e 00:21:17:

```text
MODE=PHASE_V_QV_DIMENSION_ROLES_READ_ONLY
RELOAD_STARTED=True
RELOAD_RETURNED=True
ALL_8_INPUT_QVD_SHA256_UNCHANGED=True
[V5-RD-DIM3] TOTAL ROWS=566672 MONTHS=36 EXTERNAL=5202 MISS_COMP=0 MISS_ANO=0 MISS_INTER=0 MISS_SAIDA=0 MISS_RES=0 MISS_SERV=0 MISS_ESTAB=0 MISS_PROC=0 MISS_DIAG=0 MISS_CAR=0 MISS_MOT=0
[V5-RD-DIM3] VERDICT=PASS_QV_STAGING_11_DIMENSION_ROLES_NO_ORPHANS
[V5-RD-DIM3] FACT_QVD_GENERATED=False LINK_ANALISE_GENERATED=False OUTPUT_DATA_FILES_WRITTEN=0
[V5-RD-DIM3] ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED LINK_KEY_GATE=NOT_EXECUTED
VERDICT=PASS_QV_STAGING_11_DIMENSION_ROLES_NO_ORPHANS
```

**Gate de cobertura encerrado para este snapshot:** os **11 de 11 papéis dimensionais** possuem cobertura integral por `ApplyMap` contra as 7 dimensões participantes, preservando **566.672 registros, 36 competências e 5.202 residentes externos**, sem alteração de bytes nos **8 QVDs de entrada**. Competência, internação e saída usam o `Date# + Date + Text` testado em R2; as oito outras expressões permanecem idênticas às de R1. **Não afirmar** que este teste materializou ou validou as FKs da fato, o modelo associativo, cardinalidades em joins ou `%LINK_KEY`.

**Exceção histórica MOT ainda sem causa demonstrada:** a expressão `_P5_MISS_MOT` de R1 e de R3 foi **comparada estaticamente e é byte a byte idêntica** nos QVS versionados:

```qlik
If(ApplyMap('P5MAP_MOT', Hash128('MOT',Text(Right('00' & KeepChar(Text(COBRANCA),'0123456789'),2))), 0)=1,0,1) AS _P5_MISS_MOT
```

Apesar disso, `R1=1` unmatched, `R2=0` e `R3=0` sob snapshots imutáveis nos testes. Não atribuir causa, tratar como dado inválido nem relaxar a exigência de `0` órfãos. **Verificação adicional recomendada (pendente):** executar **uma nova recarga independente** do **mesmo QVW R3 já criado** com o runner versionado (deve indicar `DOCUMENT_REUSED=True`), sem alteração de script ou de QVD; confirmar novamente `MISS_MOT=0`, todos os onze zeros e oito SHA-256 inalterados. É reprodução adicional, não cria outro gate estrutural nem prova causa raiz. Em nova divergência, reabrir investigação específica, sem merge.

**Status detalhado após R3:** `MEASURES_CSV=PASS`, `MEASURES_QVD_QV=PASS`, `SK_REGISTRO=APPROVED_WITH_IMMUTABLE_SOURCE_RESTRICTIONS`, `DIM_ROLE_COVERAGE_R3=PASS`, `MOT_R1_ANOMALY_ROOT_CAUSE=UNKNOWN`, `MOT_R3_RELOAD_STABILITY=PENDING`; `ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED`, `LINK_KEY_GATE=NOT_EXECUTED`, `FACT_QVD=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`, `PAINEL=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`. PR #83 continua Draft, sem merge, antes da revisão final do contrato.

## 18. Repetição independente R3 — cobertura e estabilidade confirmadas (10/10/2026 00:24:41)

**FATO VERIFICADO pela saída de execução fornecida pelo responsável:** após `git pull --ff-only` até `0009abe`, nova execução de `tools/validar_fato_internacao_dim_roles_r3_qlik.ps1` reutilizou **o mesmo** `TRANSFORMACAO/V5_RD_DIM_ROLES_PREFLIGHT_R3.qvw` (`DOCUMENT_REUSED=True`), com QVS de SHA-256 `541A67D244D41FEEA955C9DD0252A86A67EA1F427FE677398A288B97B8840610`, idêntico ao primeiro PASS R3. O runner confirmou `ALL_8_INPUT_QVD_SHA256_UNCHANGED=True`, `FACT_QVD_GENERATED=False`, `OUTPUT_DATA_FILES_WRITTEN=0`.

```text
2026-10-10 00:24:41 [V5-RD-DIM3] TOTAL ROWS=566672 MONTHS=36 EXTERNAL=5202 MISS_COMP=0 MISS_ANO=0 MISS_INTER=0 MISS_SAIDA=0 MISS_RES=0 MISS_SERV=0 MISS_ESTAB=0 MISS_PROC=0 MISS_DIAG=0 MISS_CAR=0 MISS_MOT=0
2026-10-10 00:24:41 [V5-RD-DIM3] VERDICT=PASS_QV_STAGING_11_DIMENSION_ROLES_NO_ORPHANS
2026-10-10 00:24:41 [V5-RD-DIM3] FACT_QVD_GENERATED=False LINK_ANALISE_GENERATED=False OUTPUT_DATA_FILES_WRITTEN=0
2026-10-10 00:24:41 [V5-RD-DIM3] ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED LINK_KEY_GATE=NOT_EXECUTED
VERDICT=PASS_QV_STAGING_11_DIMENSION_ROLES_NO_ORPHANS
```

**Resultado:** a cobertura integral dos 11 papéis por SK **PASS** foi reproduzida em duas recargas consecutivas do R3, às **00:21:17** (QVW novo) e **00:24:41** (QVW existente) sobre os oito QVDs de entrada imutáveis. O motivo de saída teve `MISS_MOT=0` nas recargas R2 (diagnóstico) e nas duas R3. O resultado anômalo de `MISS_MOT=1` no R1 **não tem causa identificada** e continua registrado, sem supor desaparecimento de uma linha, alteração de fonte ou correção da dimensão.

**Gates da FASE V encerrados para o snapshot RD 2017–2019:** `SK_REGISTRO_INTERNACAO=APPROVED_WITH_RESTRICTIONS`; `FIVE_MEASURES_CSV=PASS`; `FIVE_MEASURES_QVD=PASS`; `DIMENSION_ROLE_COVERAGE_11_OF_11=PASS_REPRODUCED`.

**DECISÕES PENDENTES:** `LINK_KEY_CONTRACT=NOT_VALIDATED_ACROSS_THREE_FACTS`; `ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED`; `FACT_QVD=NOT_STARTED`. O primeiro PASS R3 e sua repetição demonstram correspondência das chaves calculadas com as dimensões existentes, **não** integridade física de uma tabela fato futura ou ausência de loops/$Syn no modelo associativo.

## 19. Próximo gate — contrato de %LINK_KEY comum aos três processos (sem implementação)

**FATO VERIFICADO — decisões anteriores que devem ser preservadas:**

- `docs/discovery/boundary-6-qlikview-physical-architecture.md`, seções 6 a 10, escolheu `LINK_ANALISE` e cinco coordenadas compartilhadas, com associação **exclusiva** das três fatos pela `%LINK_KEY`; dimensões exclusivas continuam ligadas diretamente às respectivas fatos.
- `docs/discovery/boundary-7-implementation-plan.md`, seção 22, definiu os papéis válidos e os nulos não aplicáveis: internação usa competência+ano+residência+serviço+estabelecimento; capacidade usa competência+ano+serviço+estabelecimento e residência nula; população usa ano+residência+serviço (mesmo município), com competência/estabelecimento nulos.
- A seção 22 também exige serialização explícita dos nulos e separadores antes do `Hash128`, Link Table deduplicada por coordenadas. O exemplo `'LINK', COMPETENCIA|<NULL>, ANO|<NULL>, ...` é **conceitual**; não constitui um script final aprovado.
- `docs/discovery/boundary-6-qlikview-physical-architecture.md`, seção 22.5/22.6, exige exatamente uma `%LINK_KEY` por linha factual, cobertura de toda chave na Link Table, preservação dos totais e das linhas por fato, zero loops e zero chaves sintéticas não justificadas.

**HIPÓTESE DE IMPLEMENTAÇÃO a testar (não aprovada):** uma única função/contrato versionável para serializar as **cinco** SKs compartilhadas na mesma ordem, representação homogênea e tratamento inequívoco de nulos, evitando confundir `Null()` não aplicável com string literal ou campo vazio. É necessário testar se argumentos diretos do `Hash128` com marcador inequívoco por coordenada são suficientes, ou se uma serialização explícita revisada traz menor risco; **não criar chave somente para a internação nem codificar uma escolha antes do teste conjunto**.

**Próxima Discovery READ-ONLY:** verificar nos QVDs `SRC_SIH_RD.qvd`, `SRC_CNES_LT.qvd` e `SRC_IBGE_POP.qvd` os nomes/campos/grãos de staging reais versionados, o contrato das dimensões e os requisitos nulos de cada fato; produzir uma matriz de coordenadas com origem, normalização, semântica e compatibilidade. Em seguida testar cenários de colisão, unicidade, cobertura e preservação de grão em documento Qlik isolado **sem gravar `%LINK_KEY` factual, `LINK_ANALISE.qvd` ou alterar a transformação principal**. O nome físico real de cada QVD e campo deve ser confirmado em `ext_main.qvs` e nos gates prévios antes de gerar qualquer script.

**Estado após duas R3:** `FASE_V_SOURCE_MEASURES_AND_11_SK_COVERAGE=PASS`, `MOT_R1_ROOT_CAUSE=UNKNOWN`, `LINK_KEY_DESIGN=DISCOVERY_PENDING`, `ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED`, `FACT_QVD=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`, `PAINEL=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft, sem merge.

