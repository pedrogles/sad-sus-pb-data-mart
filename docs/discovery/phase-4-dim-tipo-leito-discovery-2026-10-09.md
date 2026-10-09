# Fase IV — DIM_TIPO_LEITO — Discovery e preflight técnico estritamente READ-ONLY (09/10/2026)

## Estado do projeto e escopo autorizado

**FATO VERIFICADO NO GITHUB:** PR [#80](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/80) da `DIM_MOTIVO_SAIDA_PERMANENCIA` integrado à `main` por squash autorizado, commit **`14bea0336d79a015ecd11127d98a00db31a55dfe`**. Fase IV **7/8 dimensões integradas**: `DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`, `DIM_DIAGNOSTICO`, `DIM_CARATER_ATENDIMENTO`, `DIM_MOTIVO_SAIDA_PERMANENCIA`.

**LIMITE OBRIGATÓRIO:** `T29_HISTORICAL=NOT_APPROVED`. Esta Discovery **não** implementa `DIM_TIPO_LEITO`, **não** enriquece `SRC_CNES_LT` com descrições de setembro/2019 nos meses 2017–2019, **não** gera QVD dimensional ou checkpoint de sucesso global e não inicia fatos, Link Table ou PAINEL. Capítulos 1–2 acadêmicos fechados e intocados.

## Fontes canônicas verificadas

- `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/academic/chapter-1-2-modeling.md` e `docs/discovery/boundary-7-implementation-plan.md`.
- `docs/discovery/dataset-validation.md`: campos CNES/LT reais `CNES`, `CODUFMUN`, `COMPETEN`, `TP_LEITO`, `CODLEITO`, `QT_EXIST`, `QT_SUS`, `QT_NSUS`.
- `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`: Discovery C4.1–C4.3, conflitos de nomenclatura, Nota Técnica MS nº 32/2019, perfil LT físico, domínio do retrato e limites temporais.
- `docs/discovery/cnes-nt32-2019-codigos-leito.csv`: transcrição rastreada da Nota Técnica, **65 pares** com campos `codleito;tp_leito;nome_cnes;tipo_cnes;status;pdf_page`.
- `tools/materialize_cnes_201909_legend.py`, `EXTRACAO/ext_c4_cnes_leitos.qvs` e `EXTRACAO/ext_main.qvs`: materialização local da legenda datada e `STORE` de `REF_TIPO_LEITO.qvd`, sem JOIN histórico.

## Fatos verificados previamente na Fase III

1. **CNES/LT:** 36 competências de `201701` a `201912`, **35.518 linhas**, **57 pares `TP_LEITO` + `CODLEITO`** observados, 7 valores brutos `TP_LEITO` (`"1 "` a `"7 "`, cada um com espaço ASCII final). `CODLEITO` é textual de dois algarismos. Não remover padding na fonte original nem tratar código sem o par correspondente.
2. **Temporalidade observada:** `CODLEITO=70`, tipo fonte `"7 "`, ocorreu na PB uma vez por competência entre `201801` e `201805` (5 ocorrências), mas a fonte oficial já mostrava o código em outra UF antes desse período. A ausência no LT PB de outros meses **não** equivale a revogação, criação ou falta de vigência nacional.
3. **Legenda autorizada:** Nota Técnica MS 32/2019, anexo *Tabela de Leitos Setembro/2019*, estruturado com **65 pares**; cobertura técnica do retrato **57/57 pares e 35.518/35.518 registros LT**, sem unmatched. CSV local gerado `BASE/REFERENCIAS/cnes_leitos_legenda_201909.csv`, SHA-256 previamente verificado **`dddb261e754f2f3bb82a462c94ae8219b84cd77c1fce3204cd6f3867c3d3bd5e`**, manifesto `cnes_leitos_legenda_201909_manifest.json`. Referência QVD `EXTRACAO/QVD/REF_TIPO_LEITO.qvd` é **somente** legenda descritiva do retrato `201909`.
4. **Checkpoint da extração C4.3:** `_CHECKPOINT_EXTRACAO_CNES_LEITO_201909.csv` marcou `EXTRACAO_CNES_LEITO_201909;PASS_PARTIAL_SNAPSHOT_ONLY;65;35518;57;36;0;201909;NOT_VERIFIED;NOT_APPROVED`. Na Fase III foi reportado QlikView 12 local com `STORE` executado, **mas o corpo binário de QVD não foi auditado independentemente**.
5. **Conflito substantivo:** os registros PB e a Nota Técnica MS 2019 documentam `TP_LEITO="3 "` / `CODLEITO="66"`, enquanto um indicador agregado CNESNet apresentou `2/66`. **Não reclassificar** `3/66` como `2/66`; preservar origem e registrar divergência.
6. **Decisão acadêmica aprovada:** `DIM_TIPO_LEITO` desnormaliza `TIPO_LEITO` → `LEITO` e apresenta **SK, código do tipo/descrição, código de leito/descrição-especialidade**. A chave física aprovada no Boundary 7, enquanto a invariância histórica não for comprovada, é **`%SK_TIPO_LEITO=Hash128('LEITO', TP_LEITO, CODLEITO, COMPETENCIA_REFERENCIA)`**, *competência-aware*; não substituí-la por chave atemporal nem assumir descrição válida para toda a série.

### Separação entre provas

**FATO VERIFICADO:** cobertura técnica de pares CNES/LT pelos pares constantes na tabela de **setembro/2019**; os códigos físicos e quantidades podem ser analisados dentro das competências reais.

**NÃO VERIFICADO / T29 INTEGRAL:** que nomes, classificação `TP_LEITO`→tipo, `CODLEITO`→especialidade, estado do catálogo e quaisquer descrições do snapshot de setembro/2019 permaneçam normativamente válidos **em todas as 36 competências entre 201701 e 201912**. Histórico da consulta RTS e lista de portarias do anexo **não** estabelecem isso.

**DECISÃO PENDENTE:** contrato físico definitivo da dimensão quanto ao preenchimento dos atributos descritivos em cada competência, sem contradizer os Capítulos 1–2. Uma **hipótese de modelagem** para avaliação futura é materializar códigos com SK por competência e registrar descrições como ausentes fora da competência da legenda, mantendo a referência 201909 separada e datada. **Não implementada nem aprovada**, e carece de validação do impacto analítico/acadêmico. Alternativa: obter domínio oficial versionado por competência antes de enriquecer a dimensão. Não escolher silenciosamente entre as alternativas.

## Gate IV-TIPO_LEITO — preflight técnico READ-ONLY preparado

Novo script `tools/preflight_dim_tipo_leito_snapshot_201909.py` nesta branch:

- Verifica **apenas metadados e estrutura**, sem modificar qualquer entrada: SHA-256 da legenda local igual ao valor previamente documentado e ao manifesto, `reference_competence=201909`, 65 códigos compostos únicos, proveniência e sinalizador explícito `vigencia_historica_verificada=NAO`.
- Verifica somente **cabeçalho XML de QVD**: `EXTRACAO/QVD/SRC_CNES_LT.qvd` com 35.518 linhas e campos da origem e `REF_TIPO_LEITO.qvd` com 65 linhas/13 campos; **não** decodifica corpo binário.
- Verifica uma linha do checkpoint III-C4.3 `PASS_PARTIAL_SNAPSHOT_ONLY`, `201909`, 57 pares e 35.518 linhas confrontadas, `NOT_VERIFIED` e `NOT_APPROVED`.
- Relê as 36 fontes `BASE/CONVERTIDA/LT/LTPB*.csv`: valida campos, competência por arquivo, a literalidade de `TP_LEITO="N "` (espaço final ASCII), `CODLEITO` com 2 dígitos; reconta **57 pares/35.518 registros** e mede cobertura dos pares contra a legenda **unicamente como comparação técnica de pares**. Imprime distribuição física de tipos, anos e ocorrências do par `3/66`.
- **Não** associa nomes em cada competência, não compara normativas históricas como se fossem fixas, não recalcula T29 e não gera `DIM_TIPO_LEITO.qvd`. Não escreve arquivos, não baixa dados, não reexecuta QlikView.

**ESTADO DO GATE:** `IV-TIPO_LEITO=TECHNICAL_READ_ONLY_PREFLIGHT_CODE_READY_NOT_RUN`; qualquer `PASS` futuro do script significará **somente** `PASS_LT_SNAPSHOT_TECHNICAL_PREFLIGHT_ONLY`, **não** `T29_HISTORICAL=APPROVED`.

### Comando local, na raiz do repositório

```powershell
git fetch origin
git switch feat/phase-4-dim-tipo-leito-discovery
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar branch TIPO_LEITO" }

.\.venv\Scripts\python.exe .\tools\preflight_dim_tipo_leito_snapshot_201909.py
if ($LASTEXITCODE -ne 0) { throw "Preflight técnico TIPO_LEITO falhou" }
```

Veredito esperado **somente se os arquivos físicos forem compatíveis**: `VERDICT=PASS_LT_SNAPSHOT_TECHNICAL_PREFLIGHT_ONLY`. Também deve emitir `HISTORICAL_MONTHLY_VALIDITY=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `HISTORICAL_LABEL_JOIN_PERFORMED=False` e `DIM_TIPO_LEITO_QVD_GENERATED=False`.

## Gate posterior — decisão explícita sobre representação descritiva

Após inspecionar a saída física, decidir **sem editar o modelo acadêmico aprovado** como conciliar a descrição da dimensão com a ausência de fonte histórica por competência. **Não criar include Qlik, QVD dimensional, PR de integração, fatos, Link Table ou painéis antes da decisão apropriada.**

`main = 7/8`; `T29_HISTORICAL=NOT_APPROVED`; `FACTS_AND_LINK_TABLE=NOT_STARTED`.

## Gate IV-TIPO_LEITO — preflight técnico PASS local (09/10/2026)

**FATO VERIFICADO — resultado PowerShell enviado pelo responsável**, executando localmente `tools/preflight_dim_tipo_leito_snapshot_201909.py` depois de `git fetch origin` / `git switch feat/phase-4-dim-tipo-leito-discovery` / `git pull --ff-only`:

```text
MODE=IV_DIM_TIPO_LEITO_READ_ONLY_TECHNICAL_PREFLIGHT
OUTPUT_FILES_WRITTEN=0
DIM_TIPO_LEITO_QVD_GENERATED=False
SNAPSHOT_201909_SHA256=dddb261e754f2f3bb82a462c94ae8219b84cd77c1fce3204cd6f3867c3d3bd5e
SNAPSHOT_PAIRS=65
SNAPSHOT_REFERENCE_COMPETENCE=201909
SNAPSHOT_HISTORICAL_VALIDITY=NOT_VERIFIED
LT_STAGING_QVD_ROWS=35518
SNAPSHOT_QVD_ROWS=65
SNAPSHOT_QVD_FIELDS=13
CHECKPOINT_C4_3=PASS_PARTIAL_SNAPSHOT_ONLY
LT_FILES=36
LT_COMPETENCES=36
LT_ROWS=35518
LT_TYPES_RAW_DISTINCT=7
LT_PAIRS_OBSERVED=57
LT_PAIRS_MATCHING_201909_SNAPSHOT=57
LT_ROWS_MATCHING_201909_SNAPSHOT=35518
LT_UNMATCHED_SNAPSHOT_PAIRS=0
LT_RAW_TP_VALUES=['1 ', '2 ', '3 ', '4 ', '5 ', '6 ', '7 ']
LT_YEAR_ROWS=[('2017', 12254), ('2018', 11616), ('2019', 11648)]
LT_PB_PAIR_3_66_ROWS=1480
SOURCE_TP_LEITO_TRAILING_ASCII_SPACE=PRESERVED
SOURCE_PAIR_COVERAGE_VS_201909_SNAPSHOT=PASS_DESCRIPTIVE_ONLY
HISTORICAL_LABEL_JOIN_PERFORMED=False
HISTORICAL_MONTHLY_VALIDITY=NOT_VERIFIED
T29_HISTORICAL=NOT_APPROVED
VERDICT=PASS_LT_SNAPSHOT_TECHNICAL_PREFLIGHT_ONLY
```

**Interpretação dos controles físicos:** o snapshot datado de 201909 mantém 65 pares e SHA de referência conhecida. O QVD de staging CNES/LT mantém cabeçalho com 35.518 linhas; o QVD da legenda contém 65 linhas/13 campos; o checkpoint parcial C4.3 é coerente. Os 36 arquivos LT físicos contêm 35.518 registros (2017=12.254, 2018=11.616, 2019=11.648), com 57 pares observados e sete valores literais `TP_LEITO` com espaço ASCII final. **Todos os pares e registros são cobertos tecnicamente pelos códigos do snapshot 201909**, não pela validade histórica de sua nomenclatura. O par PB `3/66` ocorre **1.480 vezes**; não remapear para `2/66` do indicador agregado divergente. Nenhum QVD da oitava dimensão ou JOIN histórico foi produzido.

**Limite de validade e leitura:** o QVD só foi inspecionado pelo cabeçalho XML; não houve decodificação independente dos 35.518 ou 65 registros binários. O mesmo arquivo de setembro/2019 cobre pares de 2017–2019, mas não prova validade temporal de descrições, grupos ou status. `T29_HISTORICAL=NOT_APPROVED` permanece **inalterado**, e a primeira entrega acadêmica (Capítulos 1–2) continua fechada.

**VEREDITO OPERACIONAL:** `IV-TIPO_LEITO=LOCAL_SNAPSHOT_TECHNICAL_PREFLIGHT_PASS / HISTORICAL_DESCRIPTION_MODEL_DECISION_PENDING`. **Não é PASS de modelagem dimensional**, não cria `DIM_TIPO_LEITO.qvd`, não habilita fatos/Link Table/PAINEL e não aumenta as dimensões integradas, que permanecem **7/8**.

## Avaliação das alternativas para a oitava dimensão — decisão ainda pendente

**Contrato já aprovado e que não deve ser reescrito por conveniência:** a dimensão desnormaliza `TIPO_LEITO → LEITO`, contendo SK, código/descrição do tipo, código/descrição da especialidade. Boundary 7 preserva a SK física **`Hash128('LEITO', TP_LEITO, CODLEITO, COMPETENCIA_REFERENCIA)`**, sensível à competência da referência enquanto não houver prova de invariância. O projeto **aprovou a legenda datada 201909 sem JOIN descritivo retroativo**. Qualquer hipótese abaixo que mude o significado de `COMPETENCIA_REFERENCIA` deve ser submetida a decisão explícita antes de código.

| Alternativa | Potencial benefício | Limite e risco | Estado |
|---|---|---|---|
| **A — Distinguir códigos observados por competência, sem atribuir rótulos históricos desconhecidos** | Permite análise quantitativa por `TP_LEITO/CODLEITO` em sua competência real; só exibe descrição quando sustentada por fonte aplicável | Requer fechar o contrato exato de SK/competência de observação versus `COMPETENCIA_REFERENCIA`, política `NULL`/rótulo não validado e tratamento da legenda 201909 isolada; risco de dimensão incompleta para atributos acadêmicos | **HIPÓTESE DE MODELAGEM — NÃO APROVADA** |
| **B — Aguardar fonte oficial/versionada de domínio por competência** | Permite potencialmente atribuir descrições históricas e validar T29 com evidência temporal | Pode atrasar a oitava dimensão, sem garantia de publicação de 36 versões nem necessidade da disciplina | **PENDENTE DE ESCOLHA** |
| **C — Copiar a legenda de 201909 para 2017–2019 como rótulo histórico** | Preencheria rapidamente todos os atributos visuais | **Contradiz a decisão aprovada**, induz falsa validade temporal, não possui evidência de vigência; **não permitido** | **REJEITADA PELAS RESTRIÇÕES ATUAIS** |

**Recomendação técnica para decisão do responsável:** avaliar a alternativa **A apenas como hipótese** de viabilização de análise por código/competência, mantendo a legenda de setembro/2019 como referência independente e datada, com **descrições históricas desconhecidas explicitamente ausentes**. Antes de autorizar a implementação, elaborar/validar contrato de SK, grão, relação com o fato e tratamento da competência de referência, sem criar novas entidades arbitrárias. Caso o requisito acadêmico de descrição integral seja obrigatório também para todos os meses, preferir **B** em vez de completar descrições por suposição. Como o mínimo acadêmico de seis dimensões já está atendido por sete dimensões integradas, **não há motivo para forçar a oitava** sem decisão fundamentada.

**DECISÃO PENDENTE:** escolher seguir Discovery da alternativa A ou buscar referência histórica (B). Nenhuma alteração de modelagem aprovada ou implementação QlikView está autorizada por este preflight.

## Alternativa A — proposta de contrato lógico/físico para validação (Discovery autorizada)

**AUTORIZAÇÃO RECEBIDA:** o responsável autorizou **seguir pela alternativa A somente para fechar e validar o contrato**, sem implementar a dimensão. Esta autorização **não** aprova reinterpretar a SK do Boundary 7, preencher descrições históricas, alterar o capítulo acadêmico ou liberar `T29_HISTORICAL`.

### 1. Contratos que não podem ser alterados

**FATO VERIFICADO nos documentos acadêmicos:** `DIM_TIPO_LEITO` é uma dimensão desnormalizada `TIPO_LEITO → LEITO`, com SK, código e descrição de tipo, código e descrição/especialidade de leito, associada a `FATO_CAPACIDADE_LEITO`.

**FATO VERIFICADO no Boundary 7:** grão de `FATO_CAPACIDADE_LEITO` preservado em **`CNES × COMPETEN × CODLEITO`**; fato deve ter chave exclusiva de tipo/leito. A SK de dimensão está aprovada **literalmente** como `%SK_TIPO_LEITO = Hash128('LEITO', TP_LEITO, CODLEITO, COMPETENCIA_REFERENCIA)` enquanto não há prova de invariância histórica. A expressão não define na íntegra como mapear `COMPETENCIA_REFERENCIA` para cada registro histórico de LT, e a fonte de 201909 **não** é suficiente para inferir uma referência histórica diferente em cada mês.

**FATO VERIFICADO nos dados CNES/LT:** 36 competências (2017–2019), 35.518 registros, 57 pares `TP_LEITO+CODLEITO`, tipos brutos `"1 "`–`"7 "` e `CODLEITO` ASCII de dois algarismos, com o par `3/66` preservado (1.480 ocorrências), sem correção silenciosa para o `2/66` de um indicador agregado. A referência do anexo da Nota Técnica MS 32/2019 é **datada apenas de 201909** (65 pares).

### 2. Modelo A proposto, ainda NÃO aprovado para implementação

| Aspecto | Contrato técnico CANDIDATO (não implementado) | Evidência / risco |
|---|---|---|
| Grão natural da dimensão | **1 par de códigos fonte `TP_LEITO,CODLEITO` por competência LT `COMPETEN`**, sem multiplicar por estabelecimento | Evita assumir estabilidade temporal não demonstrada; distinto do grão da fato |
| Código do tipo | Preservar `TP_LEITO` bruto `"N "` para rastreabilidade e derivar **código técnico normalizado `RTrim` de espaço ASCII** para comparação com o snapshot `201909`. Não usar `Trim` ou conversão numérica silenciosamente | Normalização só passa após auditar ausência de colisões por toda a série; usar `Text()` no QlikView para controlar dupla representação |
| Código do leito | Preservar **dois dígitos textuais `CODLEITO`**; nunca usar `CODLEITO` isolado como chave global de descrição | Chave composta reconhecida na Discovery C4 |
| Competência de observação | `COMPETEN` do LT `YYYYMM`, **campo real**, sem inferência do nome do arquivo | 36 competências validadas; teste novo confrontará todos os registros com o arquivo |
| Competência da legenda descritiva | `201909` **somente** como proveniência do catálogo oficial existente, não como competência de todos os LT | Snapshot C4.3 PASS apenas descritivo, histórico T29 não aprovado |
| Atributos de descrição do tipo e leito | **Descrição só candidata para os pares observados em `COMPETEN=201909`**; em outras competências sem fonte mensal comprobatória, **`NULL` de informação não verificada**, não nome retroativo e não string falsa de descrição | Diminui utilidade da dimensão para agrupamentos históricos; não cumpre automaticamente eventual exigência de descrição integral |
| Relacionamento com a futura fato | Para cada linha LT, projeção para **uma** chave natural dimensional `(TP_LEITO_normalizado,CODLEITO,COMPETEN)`; avaliar unicidade da chave de fato `(CNES,COMPETEN,CODLEITO)` sem construí-la | A Cardinalidade real completa e o mapeamento precisam ser conferidos por teste sobre os 35.518 LT |
| Proveniência e status | Se futura modelagem for aprovada, reter distinção entre descrição comprovada em 201909 e descrição `NULL` fora dessa competência; sem tratar a referência como catálogo SCD2 histórico | Política física exata de campos de rastreio ainda requer aprovação; não inventar atributos acadêmicos nem domínio histórico |

**QUESTÃO DE SEMÂNTICA QUE IMPEDE APROVAR A SK AGORA:** no Boundary 7, o último argumento da expressão é `COMPETENCIA_REFERENCIA`, enquanto **`COMPETEN` representa a competência da linha observada**. Substituir implicitamente `COMPETENCIA_REFERENCIA` por `COMPETEN` no `Hash128` para criar chaves por mês **seria alteração material da decisão vigente**, e aplicar `201909` indiscriminadamente também seria inadequado (apaga sensibilidade mensal). É necessário **definir formalmente o significado do quarto argumento**: competência de observação/versão da chave ou competência de validade da descrição, antes de criar a SK QlikView. A alternativa A foi autorizada **para investigar**, não para modificar isso.

**HIPÓTESE DE MODELAGEM (sujeita a aprovação do responsável):** se a dimensão for versionada por mês observado, a chave natural única do grão seria `(TP_LEITO_normalizado,CODLEITO,COMPETEN)`; após prova física, submeter eventual contrato que distingua explicitamente `COMPETENCIA_OBSERVACAO` de `COMPETENCIA_LEGENDA`, alinhando ou **atualizando com aprovação explícita** o uso de `COMPETENCIA_REFERENCIA` na SK aprovada. Isso não altera o capítulo impresso.

### 3. Validação física READ-ONLY para fechar as quantidades e as chaves naturais

Script novo: `tools/preflight_dim_tipo_leito_contrato_a.py` (branch `feat/phase-4-dim-tipo-leito-discovery`). Não gera QVD, SK Hash128, fato, dimensão, script QlikView nem altera quaisquer arquivos.

O script verificará diretamente em todos os **36 CSVs LT**:

- integridade do snapshot e cabeçalhos de QVD/CKPT já validados, preservando `T29=NOT_APPROVED`;
- formato `"N "` (ASCII trailing space), `CODLEITO` de dois dígitos e competência `COMPETEN` física igual à do arquivo, com validação de colisões de `RTrim` ASCII;
- unicidade das chaves naturais candidatas **`(tipo normalizado,codleito,COMPETEN)`** na dimensão deduplicada;
- existência de chave dimensional candidata para cada linha do futuro fato LT (sem produzir o fato);
- unicidade física potencial da chave de fato **`(CNES,COMPETEN,CODLEITO)`** sobre as **35.518** linhas, antes validada apenas em checkpoints amostrais;
- contagem de pares por mês (perfil C4.1 reportou 56 por competência, **exceto 201801–201805 com 57**), presença mensal do par `7/70` e preservação das 1.480 ocorrências de `3/66`;
- separação **somente virtual** das chaves de dimensão cuja competência de observação é 201909 (potencialmente elegíveis a usar a legenda contemporânea) das chaves de 2017–2019 sem evidência descritiva histórica. Não atribui nomes.

**HIPÓTESE NUMÉRICA PARA O TESTE, derivada dos perfis mensais documentados (não ainda reexecutada):** `31 × 56 + 5 × 57 = 2021` chaves naturais compostas mensais; `56` chaves elegíveis a rótulos `201909`, `1965` sem prova descritiva para sua própria competência. O script **exige essa partição** como regressão e imprimirá totais observados; estes números ainda **não constituem PASS novo** até a execução local.

### Execução local solicitada

```powershell
git fetch origin
git switch feat/phase-4-dim-tipo-leito-discovery
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar branch de Discovery tipo leito" }

.\.venv\Scripts\python.exe .\tools\preflight_dim_tipo_leito_contrato_a.py
if ($LASTEXITCODE -ne 0) { throw "Validação física temporal do contrato A falhou" }
```

Somente se tudo passar: `TEMPORAL_NATURAL_DIM_KEYS=2021`, `FACT_CANDIDATE_KEY_DUPLICATES=0`, `TYPE_ASCII_RTRIM_COLLISIONS=0`, `REFERENCE_201909_LABEL_ELIGIBLE_NATURAL_KEYS=56`, `HISTORICAL_LABEL_UNVERIFIED_NATURAL_KEYS=1965`, `VERDICT=PASS_OPTION_A_TEMPORAL_GRAIN_PREFLIGHT_ONLY`; obrigatoriamente também `COMPETENCIA_REFERENCIA_SEMANTICS=DECISION_PENDING`, `T29_HISTORICAL=NOT_APPROVED`, `DIM_TIPO_LEITO_QVD_GENERATED=False`. Os números são **esperados, não verificados por esta nova execução ainda**.

### 4. Próximos gates sem implementação

1. Obter o PASS físico das chaves naturais e cardinalidades com o novo preflight; qualquer desvio reabre a hipótese A e **não** será corrigido por suposição.
2. Decidir explicitamente o significado de `COMPETENCIA_REFERENCIA` no `Hash128` frente à `COMPETEN` física, bem como a política de campos `NULL` e rastreabilidade para descrição não comprovada.
3. Conferir conformidade da proposta com o **modelo dimensional acadêmico fechado** (descrições são atributos aprovados, mas podem ficar `NULL` fora da competência justificada?) e, se necessário, buscar confirmação do professor sem reescrever silenciosamente Capítulos 1 e 2.
4. **Somente depois de decisão aprovada e documentada** considerar construir a oitava dimensão e definir gates QlikView 12. Manter `T29_HISTORICAL=NOT_APPROVED` até evidência histórica própria; nenhuma implementação de fatos/Link Table/painéis.

**ESTADO:** `OPTION_A=DISCOVERY_AUTHORIZED_CONTRACT_CANDIDATE_READ_ONLY_PREFLIGHT_NOT_RUN`. `MAIN=7/8`. Nenhuma alteração na SK aprovada do Boundary 7, modelo acadêmico, arquivos de dados ou QVDs.

## Gate A1 — validação física de granularidade temporal PASS local (09/10/2026)

**FATO VERIFICADO — saída PowerShell entregue pelo responsável:** depois de `git pull --ff-only` na branch `feat/phase-4-dim-tipo-leito-discovery`, executou `tools/preflight_dim_tipo_leito_contrato_a.py` e obteve:

```text
MODE=IV_TIPO_LEITO_OPTION_A_READ_ONLY_GRAIN_PREFLIGHT
OUTPUT_FILES_WRITTEN=0
DIM_TIPO_LEITO_QVD_GENERATED=False
QLIK_HASH128_EXECUTED=False
SNAPSHOT_201909_SHA256=dddb261e754f2f3bb82a462c94ae8219b84cd77c1fce3204cd6f3867c3d3bd5e
SNAPSHOT_PAIRS=65
SNAPSHOT_REFERENCE_COMPETENCE=201909
SNAPSHOT_HISTORICAL_VALIDITY=NOT_VERIFIED
LT_STAGING_QVD_ROWS=35518
SNAPSHOT_QVD_ROWS=65
SNAPSHOT_QVD_FIELDS=13
CHECKPOINT_C4_3=PASS_PARTIAL_SNAPSHOT_ONLY
LT_FILES=36
LT_COMPETENCES=36
LT_ROWS=35518
LT_YEARS=[('2017', 12254), ('2018', 11616), ('2019', 11648)]
PAIRS_TOTAL_DISTINCT=57
TEMPORAL_NATURAL_KEY=(TP_LEITO_RTRIM_ASCII,CODLEITO_TEXT,COMPETEN)
TEMPORAL_NATURAL_DIM_KEYS=2021
TEMPORAL_NATURAL_KEY_DUPLICATES=0
TYPE_ASCII_RTRIM_COLLISIONS=0
FACT_CANDIDATE_KEY=(CNES,COMPETEN,CODLEITO)
FACT_CANDIDATE_KEY_DUPLICATES=0
FACT_ROWS_WITH_CANDIDATE_DIM_KEY=35518
LT_PAIR_3_66_ROWS=1480
LT_CODE_7_70_ROWS=5
LT_CODE_7_70_MONTHS=201801,201802,201803,201804,201805
REFERENCE_201909_LABEL_ELIGIBLE_NATURAL_KEYS=56
HISTORICAL_LABEL_UNVERIFIED_NATURAL_KEYS=1965
LEGEND_201909_USED_AS_HISTORICAL_LABEL_JOIN=False
CANDIDATE_KEY_IS_NOT_AN_APPROVED_HASH128_IMPLEMENTATION=True
COMPETENCIA_REFERENCIA_SEMANTICS=DECISION_PENDING
T29_HISTORICAL=NOT_APPROVED
FACT_AND_DIM_QVD_GENERATED=False
VERDICT=PASS_OPTION_A_TEMPORAL_GRAIN_PREFLIGHT_ONLY
```

**Evidência complementar:** a saída listou os 36 meses: **56 pares por competência**, salvo **201801–201805 com 57**, totalizando `31×56 + 5×57 = 2021` pares-mês. Os dados anuais são `2017=12254`, `2018=11616`, `2019=11648` e `35518` no total. O par `3/66` foi observado `1480` vezes e deve permanecer nessa classificação de origem, sem imputar o tipo `2` de indicador divergente.

**Leitura correta dos controles:**

- **PASS FÍSICO de grão candidato:** toda linha LT tem `(TP_LEITO_RTrim_ASCII,CODLEITO,COMPETEN)`; os conjuntos reais contêm 2021 chaves naturais únicas por construção da deduplicação; o perfil mensal validado permite interpretar o grão. **`TEMPORAL_NATURAL_KEY_DUPLICATES=0` é rótulo emitido após inserção em `set`; não é auditoria independente de duplicatas em linhas brutas.** Repetição da mesma combinação entre diferentes estabelecimentos é esperada e não viola o grão da dimensão.
- **PASS de não colisão observada:** cada par normalizado tem uma única representação bruta `"N "` de `TP_LEITO`; o teste não mostrou colisões introduzidas por `rstrip(" ")`.
- **PASS de unicidade física da futura chave de fato:** `(CNES,COMPETEN,CODLEITO)` teve **0 duplicatas** entre as 35.518 linhas; esse controle não cria nem aprova a implementação de `FATO_CAPACIDADE_LEITO`.
- **Cobertura por projeção de chave natural:** 35.518/35.518 linhas podem apontar para um par-mês de seus próprios registros. Isto **não valida um JOIN de SK QlikView**, porque `Hash128` não foi executado.
- **Escopo limitado de descrições:** em `COMPETEN=201909`, há 56 combinações observadas **potencialmente elegíveis** ao retrato datado daquele mês. As outras **1965 combinações** (97,2% das 2021) **não têm descrição histórica temporalmente comprovada por essa fonte**. Não atribuir valores da legenda 201909 a essas combinações, nem afirmar que todas as demais estão incorretas ou que os códigos eram inválidos.
- **T29 permanece `NOT_APPROVED`**, sem evidência normativa mensal completa; `DIM_TIPO_LEITO_QVD_GENERATED=False` e `OUTPUT_FILES_WRITTEN=0`.

**VEREDITO:** `IV_TIPO_LEITO_OPTION_A_GRAIN_PREFLIGHT=PASS_LOCAL_READ_ONLY`. Isto encerra a medição física das chaves naturais da alternativa A, **não aprova o contrato da chave substituta nem a dimensão**.

## Gate A2 — proposta de decisão arquitetural, NÃO APROVADA

**HIPÓTESE DE MODELAGEM recomendada para decisão do responsável:** formalizar duas competências com significados distintos:

1. **`COMPETEN` = competência observada do registro CNES/LT**, determinando a versão da combinação técnica de códigos que se relacionaria à futura capacidade hospitalar. Para a alternativa A, a dimensão candidata teria uma linha por `(TP_LEITO_textual_normalizado,CODLEITO_textual,COMPETEN)`, com cardinalidade física observada de **2021** linhas.
2. **`competencia_referencia` da legenda = `201909`**, metadado de procedência temporal do **catálogo descritivo**. Não representa validade da legenda em meses anteriores/posteriores e não substituiria a competência observada.

**CONFLITO COM DECISÃO VIGENTE:** Boundary 7 aprovou textualmente `%SK_TIPO_LEITO=Hash128('LEITO',TP_LEITO,CODLEITO,COMPETENCIA_REFERENCIA)` sem fechar se `COMPETENCIA_REFERENCIA` é competência de observação ou referência normativa. A proposta A requer **aprovação expressa** de semântica para o quarto argumento, mantendo o desenho competência-aware. Uma mudança de significado não pode ser registrada como simples correção factual.

**Política descritiva candidata (não aprovada):** atributos de descrição do tipo e do leito **nulos** nos 1965 pares-mês sem fonte descritiva aplicável por competência; para as 56 combinações de `201909`, permitir rótulos **apenas identificados explicitamente como da legenda de setembro/2019**. Revisar necessidade de distinguir descrição textual de proveniência e de impedir agrupamento analítico indevido por rótulos ausentes. A dimensão assim construída teria utilidade primária em análises quantitativas por códigos e competência; descrições históricas completas continuariam pendentes.

**Aderência acadêmica:** os Capítulos 1–2 fechados **exigem os atributos** descrição do tipo e descrição/especialidade do leito; o contrato acadêmico **não demonstra se atributos nulos na maior parte da série são aceitáveis ao professor**. Como o requisito mínimo de seis dimensões já está satisfeito por **sete** integradas, não presumir autorização acadêmica para completar a oitava de forma parcial. Considerar confirmação do professor se essas descrições forem obrigatórias para o período completo.

**DECISÃO PENDENTE DO RESPONSÁVEL:** ratificar ou rejeitar o princípio do contrato A — distinção explícita de competências, granularidade por par-mês e `NULL` descritivo quando a fonte histórica é insuficiente — **antes** de pedir alteração documentada do Boundary 7 e antes de escrever scripts `transf_dim_tipo_leito.qvs`, QVD/checkpoint, fato, Link Table, painel ou PR de implementação. Se rejeitado, manter alternativa B (obter domínio histórico oficial) como caminho aberto.

**Estado persistente:** `A1=PASS_LOCAL`; `A2=DECISION_PENDING`; `T29_HISTORICAL=NOT_APPROVED`; `main=7/8`. A primeira entrega acadêmica permanece intocada.

## C4.2c.4 — Discovery histórica oficial delimitada, READ-ONLY (09/10/2026)

**OBJETIVO DA RODADA:** após o responsável pedir aprofundamento da Discovery em vez de ratificar o contrato A2, investigar as **fontes normativas históricas** de `TP_LEITO + CODLEITO` para 201701–201912, sem converter código observado em prova de vigência, sem downloads em massa e sem modificar arquitetura.

### Fontes primárias consultadas nesta rodada

1. **RTS — [Terminologias](https://wiki.saude.gov.br/RTS/index.php/Terminologias):** identifica expressamente **Leitos** no grupo Estabelecimento de Saúde. **[RTS — Portal](https://wiki.saude.gov.br/RTS/index.php/RTS_Portal):** distingue **competência RTS** `MM/AAAA` de **versão da terminologia** `MM/AAAA/letra`; a terminologia só recebe nova versão quando há alterações de termos. O portal documenta troca de competências exibidas desde **01/2017**. **[RTS — Download](https://wiki.saude.gov.br/RTS/index.php/Download):** documenta pacotes por competência e suas Notas Técnicas/relatórios, **mas não demonstra que o subdomínio Leitos esteja presente/historicamente completo em cada pacote**. [Consulta de terminologias](https://wiki.saude.gov.br/RTS/index.php/Consultar_terminologias) descreve status/vigência para termos de exemplo, **não comprova essas propriedades para Leitos 2017–2019**.
2. **RTS — [Documentos](https://wiki.saude.gov.br/RTS/index.php/Documentos):** a documentação informa que alterações das terminologias estão relacionadas a documentos, e descreve a pesquisa de portarias e atos por data/tipo/número/ementa. A tabela ilustrativa das portarias de 2019 **não deve ser interpretada como inventário exaustivo e específico de todas as alterações da terminologia Leitos**; não se obteve catálogo Leitos versionado nesta pesquisa.
3. **CNES — [download da Base Nacional](https://wiki.saude.gov.br/cnes/index.php/Categoria:Consumo_de_informações_da_Base_Nacional_do_CNES_via_webservice_e_Download_da_Base_de_Dados):** o canal oficial documenta acesso por competência **a partir de 06/2017**. **[Portal CNES](https://wiki.saude.gov.br/cnes/index.php/Portal_CNES)** descreve em `Downloads → Aplicativos` versões **anteriores** do SCNES, completas e atualizações, e `Downloads → Base de Dados` por competência. **[Guia de Instalação SCNES](https://wiki.saude.gov.br/cnes/index.php/Guia_de_Instalação_dos_Sistemas)** diferencia instalação completa (tabelas do sistema) de atualizações que em geral implementam regras de negócio de uma competência. **NÃO foi obtido nenhum arquivo histórico identificável como `NFCES001/TB_LEITO`, nem comprovado que as bases públicas por competência ou instaladores versionados contenham o histórico daquela tabela de domínio.** Também não se encontrou aqui fonte cobrindo 201701–201705.
4. **PORTARIA SAS/MS nº 298 de 01/03/2019 (DOU 06/03/2019), fonte ministerial:** [BVS/MS](https://bvs.saude.gov.br/bvs/saudelegis/sas/2019/prt0298_06_03_2019.html), com [publicação original no DOU, p. 78](https://pesquisa.in.gov.br/imprensa/servlet/INPDFViewer?captchafield=firstAccess&data=06%2F03%2F2019&jornal=515&pagina=78). O ato prevê **`77 → 94` (UTI Pediátrica Tipo I → UCI Pediátrica)** e **`74 → 95` (UTI Adulto Tipo I → UCI Adulto)**, com exclusão dos códigos anteriores segundo seus termos. Seu **artigo 8º condiciona os efeitos à disponibilização das versões dos sistemas do DATASUS que contemplem as modificações**. Portanto, **a publicação em 06/03/2019 NÃO estabelece competência operacional efetiva da migração**. É um caso concreto de possível mudança durante 2017–2019; também não prova alteração dos demais 53 pares observados.
5. **Nota Técnica 32/2019, transcrição canônica:** `docs/discovery/cnes-nt32-2019-codigos-leito.csv` tem no retrato **201909** as linhas `66;3;UNIDADE ISOLAMENTO;Complementar`, `70;7;FIBROSE CISTICA;Hospital-Dia`, `74;3;UTI ADULTO - TIPO I;Complementar`, `77;3;UTI PEDIATRICA - TIPO I;Complementar`, `94;3;UNIDADE DE CUIDADOS INTERMEDIARIOS PEDIATRICO;Complementar` e `95;3;UNIDADE DE CUIDADOS INTERMEDIARIOS ADULTO;Complementar`, todas com status `Ativo` no anexo. **FATO DA TRANSCRIÇÃO / NÃO PROVA DE VIGÊNCIA:** não inferir automaticamente data de migração ou inconsistência normativa a partir dessa coexistência, pois o artigo 8º condiciona efeitos à implementação e a legenda possui recorte e semântica próprios.

**Revisão da trilha anterior:** a Discovery III-C4.2c.3b já registrou que no RTS a versão **`LEITO 10/2019A`** foi visível em captura de 10/2019; para competências anteriores o responsável relatou resultados vazios e exibiu captura de 01/2017 sem dados. Esses fatos **não** provam ausência de códigos históricos nem a validade de todo o catálogo em 2017–2019. O RTS acessível na Wiki não substitui os **dados de domínio históricos**. A abertura direta de `https://rts.saude.gov.br` neste ambiente de pesquisa **não retornou conteúdo utilizável nesta rodada**; nenhum endpoint profundo/arquivo não inspecionado foi inventado.

### Síntese da triagem — graus de comprovação

| Questão | Evidência encontrada | Resultado |
|---|---|---|
| Existência de canais oficiais de versionamento | Wiki RTS e CNES documentam versões, competências e downloads | **FATO VERIFICADO — CANAL DOCUMENTADO**, não catálogo obtido |
| Documento oficial que determina mudança de código em 2019 | Portaria SAS/MS nº 298/2019, pares de migração `77→94` e `74→95` | **FATO VERIFICADO — ATO IDENTIFICADO**, mês de efeito **NÃO DEMONSTRADO** |
| Lista composta oficial datada de 201909 | Nota Técnica MS 32/2019; 65 pares; 57/57 PB e 35.518/35.518 LT em cobertura técnica | **FATO VERIFICADO — SNAPSHOT**, sem extrapolação normativa mensal |
| Tabela federal histórica `NFCES001/TB_LEITO` com associação tipo, código, descrição e data | Esquema documentado no dicionário SCNES, nenhum dataset versionado inspecionado nesta rodada | **PENDENTE** |
| Mudanças efetivas dos 57 pares em cada competência entre 201701–201912 | Nenhuma sequência temporal completa de versões oficiais obtida | **PENDENTE / T29 NOT_APPROVED** |
| Conflito `3/66` LT/Nota Técnica vs `2/66` indicador CNESNet | Confronto já documentado III-C4; sem evidência de correção retrospectiva | **DIVERGÊNCIA PRESERVADA** |

### Próximo checkpoint C4.2c.4a — triagem empírica DIRECIONADA, sem normatização

**Novo script read-only:** `tools/triage_cnes_lt_portaria_298_2019.py` na branch atual. Lê **apenas os 36 CSVs LT** e valida **35518 linhas/57 pares** já conhecidos; imprime, para `CODLEITO` **74, 77, 94 e 95**, o número real de registros na PB, sua distribuição por competência mensal e os tipos `TP_LEITO` brutos observados. Também conserva os controles `66`/`70` e não troca o tipo `3` por `2` no conflito 66.

- **NÃO** compara códigos como se a transição observada provasse eficácia normativa, **NÃO** determina `effective_month`, **NÃO** produz versão histórica de domínio, não altera `T29` e não cria dimensão/QVD/CSV/JSON.
- Se todos os quatro códigos forem ausentes nos LT da PB, o ato segue importante como prova de **mudança possível no domínio nacional**, mas seu impacto quantitativo no recorte PB será **não observado**. Se presentes, priorizar **metadados da versão SCNES implementadora** e a data de início de aplicação operacional específica antes de rotular a série.
- Inspecionar metadados, **sem download em massa**, de cinco pontos de controle do portal CNES/SCNES (`201701`, `201712`, `201903`, `201909` e `201912`, ajustando para o início público **201706**) e registrar o **nome/versão/data/URL real do arquivo existente, se exibido**, formato e indício de conter `TB_LEITO`; **não presumir** conteúdo por nome de pacote ou calendário. Se necessário obter um único artefato histórico para prova, pedir autorização de aquisição mínima com hash e licença, sem massa de dados.
- A investigação normativa restante dos **57 pares** exigiria versão oficial de domínio ou atos específicos que cubram **toda alteração relevante e data efetiva**, confrontados com a fonte; não bastam ausência de mudança nos códigos LT nem estabilidade textual dos indicadores.

### Como executar a triagem local (sem QlikView nem escrita)

```powershell
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar branch de Discovery" }
.\.venv\Scripts\python.exe .\tools\triage_cnes_lt_portaria_298_2019.py
if ($LASTEXITCODE -ne 0) { throw "Falha na triagem histórica LT" }
```

**Estado após esta rodada:** `C4.2c.4=OFFICIAL_SOURCE_CHANNELS_AND_NORMATIVE_CHANGE_IDENTIFIED / 2017_2019_FULL_DOMAIN_UNVERIFIED`; `C4.2c.4a=LOCAL_READ_ONLY_CODE_TRIAGE_NOT_RUN`; `A1_TEMPORAL_GRAIN_PREFLIGHT=PASS_LOCAL`; `A2_MODEL_CONTRACT_DECISION=PENDING`; `T29_HISTORICAL=NOT_APPROVED`; `main=7/8`. Sem aprovação da 8ª dimensão, sem mudança de Boundary 7, sem QVD nem dados baixados.

## C4.2c.4a — triagem dos códigos da Portaria 298/2019 PASS local (09/10/2026)

**FATO VERIFICADO — execução PowerShell entregue pelo responsável** após `git pull --ff-only` na branch `feat/phase-4-dim-tipo-leito-discovery`, rodando `tools/triage_cnes_lt_portaria_298_2019.py`:

```text
MODE=C4_T29_HISTORICAL_CHANGE_ACT_298_READ_ONLY_TRIAGE
OUTPUT_FILES_WRITTEN=0
LT_FILES=36
LT_ROWS=35518
LT_PAIRS=57
ACT_298_TRANSITIONS=77_TO_94;74_TO_95
ACT_298_EFFECTIVE_MONTH=NOT_ESTABLISHED
PROFILED_298_CODES=74,77,94,95
CODE_74_OBSERVED_ROWS=208
CODE_74_OBSERVED_RAW_TYPES=[('3', 208)]
CODE_77_OBSERVED_ROWS=158
CODE_77_OBSERVED_RAW_TYPES=[('3', 158)]
CODE_94_OBSERVED_ROWS=0
CODE_94_OBSERVED_RAW_TYPES=[]
CODE_94_OBSERVED_MONTHS=[]
CODE_95_OBSERVED_ROWS=220
CODE_95_OBSERVED_RAW_TYPES=[('3', 220)]
CODE_66_OBSERVED_ROWS=1480
CODE_66_OBSERVED_RAW_TYPES=[('3', 1480)]
CODE_70_OBSERVED_ROWS=5
CODE_70_OBSERVED_RAW_TYPES=[('7', 5)]
PB_PAIR_3_66_ROWS=1480
PB_PAIR_7_70_ROWS=5
CODE_PRESENCE_IS_NOT_LEGAL_EFFECTIVE_VALIDITY=True
NO_CODE_RECLASSIFICATION_PERFORMED=True
NO_NORMATIVE_HISTORICAL_LABELS_ASSIGNED=True
NO_QVD_OR_DIM_CREATED=True
T29_HISTORICAL=NOT_APPROVED
VERDICT=PASS_OBSERVED_LT_CODE_CHANGE_TRIAGE_ONLY
```

**As distribuições integrais por mês foram apresentadas no terminal e não foram persistidas como artefato adicional.** Síntese comprovada do perfil físico CNES/LT PB:

| `CODLEITO` | `TP_LEITO` fonte | Linhas LT observadas | Competências observadas | Interpretação estrita |
|---|---:|---:|---|---|
| `74` | `"3 "` | 208 | **36/36**, `201701–201912` | Há registros do código depois da publicação da Portaria 298/2019 |
| `77` | `"3 "` | 158 | **36/36**, `201701–201912` | Há registros do código depois da publicação da Portaria 298/2019 |
| `94` | — | 0 | **0/36** | Código não observado nos LT da PB; não se conclui inexistência nacional ou normativa |
| `95` | `"3 "` | 220 | **36/36**, `201701–201912` | **Código 95 observado já em `201701`, antes da Portaria 298/2019 e mesmo antes da Portaria 895/2017** |
| `66` | `"3 "` | 1.480 | **36/36** | Manter par de origem `3/66`; indicador CNESNet `2/66` continua divergente |
| `70` | `"7 "` | 5 | `201801–201805` | Presença PB pontual, não prova introdução/retirada normativa nacional |

**Nota metodológica:** as contagens são de **linhas administrativas da base LT**, **não valores de `QT_EXIST`/`QT_SUS`, nem número de leitos físicos**. Presença/ausência de `CODLEITO` não certifica vigência, elegibilidade, qualidade normativa da classificação, efetivação de migração nem total da capacidade instalada.

### Contraprova à interpretação simplificada "os códigos novos nasceram em 2019"

O `CODLEITO=95` já aparece em **cada uma das 36 competências físicas**, incluindo `201701`. Portanto, **a Portaria 298/2019 não pode ser interpretada como evidência suficiente de que o código numérico 95 nasceu em 2019**, tampouco de que todos os estabelecimentos tiveram seus registros `74` convertidos em `95` naquele ano. Os códigos `74` e `77` também continuam presentes em `201912`. Não inferir que isso prove descumprimento, atraso operacional específico ou erro nos LT: pode envolver regras de transição e/ou de classificação cujo calendário e aplicabilidade ainda não estão fechados.

### Novos atos oficiais confrontados após o PASS do perfil

1. **[Portaria GM/MS nº 895/2017, de 31/03/2017](https://bvsms.saude.gov.br/bvs/saudelegis/gm/2017/prt0895_26_04_2017.html)**, com matriz de consolidação [GM/MS nº 3/2017](https://bvsms.saude.gov.br/bvs/saudelegis/gm/2017/MatrizesConsolidacao/comum/237884.html): **já em 2017** estabelece a reorganização de habilitações UTI tipo I em UCI Adulto/Pediátrica e prevê exclusão/substituição dos tipos de leitos correspondentes no SCNES, atribuindo a operacionalização ao DATASUS. **CUIDADO:** códigos de *habilitação* `26.96`/`26.98` não são intercambiáveis com `CODLEITO=74`/`77`; o ato de 2017 não comprova, por si só, criação/codificação operacional de `94`/`95` ou sua tabela histórica.
2. **[Portaria SAS/MS nº 298/2019, de 01/03/2019](https://bvs.saude.gov.br/bvs/saudelegis/sas/2019/prt0298_06_03_2019.html)**: art. 2º dispõe explicitamente da migração `77 → 94` e `74 → 95`; art. 3º e 4º modificam regras de contabilização/habilitações; art. 8º condiciona os efeitos à disponibilização das versões dos sistemas do DATASUS. **Nenhuma competência mensal efetiva foi provada apenas pelo texto.**
3. **[Portaria SAES/MS nº 3.511/2025, de 24/11/2025](https://bvs.saude.gov.br/bvs/saudelegis/Saes/2025/prt3511_05_12_2025.html)** — **fora do período estudado**, consultada somente como alerta contra inferência temporal falsa: art. 2º §1º trata expressamente da exclusão de `74` e `77` considerando prazo de reclassificação da Portaria SAES/MS `1.202/2023`, e art. 9º revoga formalmente a Portaria 298/2019. A mudança normativa **não deve ser interpretada como exclusão operacional universal já concluída em 2019**. **Não aplicar uma norma de 2025 retroativamente a dados 2017–2019**.

**Conclusão causal provisória, não decisão normativa definitiva:** a regra de reclassificação começou a ser discutida/regulamentada antes da Portaria 298/2019 e passou por diferentes atos de operacionalização e vigência. A ocorrência `95` antes de 2019, a persistência `74`/`77` depois e a exclusão tratada novamente em 2025 **demonstram que uma simples fronteira `201903` não é defensável**. Não se sabe quais versões efetivamente introduziram, ativaram ou alteraram cada par e qual documento rege a descrição em cada uma das 36 competências.

**DECISÃO SOBRE GATE C4.2c.4a:** `PASS_OBSERVED_LT_CODE_CHANGE_TRIAGE_ONLY`, sem alteração de `A2`/Boundary 7 e **`T29_HISTORICAL=NOT_APPROVED`**. A triagem valida apenas os códigos efetivamente armazenados nos LT da PB.

### Próximo gate C4.2c.4b — inventário de VERSIONAMENTO SCNES, sem aquisição em massa

**Prioridade mais alta:** identificar **um artefato oficial histórico verificável** contendo `NFCES001/TB_LEITO` ou referência equivalente com `TP_LEITO,CODLEITO,descrição`, mais metadados de **versão/data de disponibilização**. Verificar separadamente se o formato e o pacote guardam validade de cada par e se houve mudanças aplicáveis à PB.

**Amostra inicial de descoberta (metadados e links reais, sem descarregar bases):**

- marco **201701**: anterior à Portaria 895/2017; verificar existência de versão SCNES e caminho alternativo porque download de base pública só foi documentado a partir 201706;
- marco **201703–201706**: Portaria 895/2017 e primeiras bases públicas por competência; identificar versão do **sistema**, não confundi-la com mês de dados;
- marco **201903**: Portaria 298/2019, mas art. 8º impede usar março como data efetiva;
- marcos **201909** e **201912**: catálogo Nota Técnica 32/2019 e encerramento do recorte, com códigos `74`, `77`, `95` ainda observados.

**Para cada evidência encontrada registrar:** URL oficial real, data, versão literal do aplicativo/RTS ou do arquivo, extensão/formato, SHA se bytes obtidos, indicação efetiva do conteúdo `TB_LEITO` (sem adivinhar pelo nome), se contém pares tipo+código+descrição e competência/eficácia normativa, e **limitação de comparabilidade entre versões**. **Não baixar instaladores históricos extensos sem autorização adicional nem inferir tabela `NFCES001` dentro do pacote apenas pela descrição da página.**

**Critério de encerramento desta Discovery restrita:** (a) descobrir versão(s) normativas suficientes para modelar descrições com intervalos comprováveis; **ou** (b) registrar que as rotas documentadas não forneceram evidência histórica no escopo, apresentando ao responsável a alternativa A incompleta ou a postergação da oitava dimensão. Não exigir busca indefinida para concluir que **não há prova encontrada**, o que não significa afirmar que as referências históricas não existem.

**Estado:** `C4.2c.4a=PASS_LOCAL_OBSERVED_LT_CODES`, `C4.2c.4b=SCNES_VERSIONED_DOMAIN_INVENTORY_PENDING`, `T29_HISTORICAL=NOT_APPROVED`, `A2=CONTRACT_DECISION_PENDING`, `main=7/8`.

## C4.2c.4b — inventário metadata-only de versões históricas SCNES (09/10/2026)

**MODO EXECUTADO:** consulta HTTP/texto em páginas oficiais do CNES/DATASUS e Wiki CNES. **Nenhum instalador, arquivo compactado, banco histórico, QVD ou dataset foi baixado, extraído ou modificado.** Não se utilizou navegador gráfico com JavaScript nem se inspecionou o conteúdo binário `NFCES001/TB_LEITO`.

### 1. Entradas oficiais e URLs reais verificadas

| Canal | URL **observada** e função | Resultado da inspeção remota |
|---|---|---|
| Portal CNES — aplicativos | https://cnes.datasus.gov.br/pages/downloads/aplicativos.jsp | Página HTTP acessível; seções `VERSÃO SCNES` completa/atualização e `VERSÕES SCNES ANTERIORES` completa/atualização **existem**. Lista de versões anteriores e seus respectivos arquivos **não são renderizados no HTML estático**; a versão atual aparece como expressão Angular literal `{{scnesCompleta.versao...}}`. Sem JS interativo, **não foram extraídos itens nem URL binária individual de 2017–2019**. |
| Portal CNES — bases de dados | https://cnes.datasus.gov.br/pages/downloads/arquivosBaseDados.jsp | Página HTTP acessível; seção `BASE DE DADOS` apresenta apenas `SELECIONE` no HTML estático. **Nenhuma lista real de arquivos por competência, metadados, tamanho, conteúdo ou SHA observáveis neste modo.** A Wiki explica a disponibilidade por competência a partir de **201706**, sem provar que esses pacotes contenham `TB_LEITO`. |
| Portal CNES — outros sistemas | https://cnes.datasus.gov.br/pages/downloads/arquivosOutros.jsp | Página HTTP acessível; seção **`LEITOS 65`** exibe **link denominado `LFCES002_201301_65.ZIP`**. É um **nome literal visível**, não arquivo baixado, tamanho conhecido ou estrutura examinada. **Não equivale automaticamente** a `NFCES001/TB_LEITO` ou catálogo mensal 2017–2019; etiqueta `201301` não autoriza inferir conteúdo/vigência. Não foi seguido o link de download. |
| Wiki CNES — Portal | https://wiki.saude.gov.br/cnes/index.php/Portal_CNES | Confirma formalmente a existência de versões anteriores do SCNES, completa/atualização, arquivos para outros sistemas (`LEITOS 65`) e base por competência desde **06/2017**. É **documentação da rota**, não manifesto de binários históricos. |
| Wiki CNES — Guia instalação | https://wiki.saude.gov.br/cnes/index.php/Guia_de_Instala%C3%A7%C3%A3o_dos_Sistemas | Diferencia **SCNES COMPLETO** (instala tabelas e arquivos) de **ATUALIZAÇÃO** (conserva dados locais e pode implementar regras). Define modelo de nomes `SCNESXXXX-COMPLETA.ZIP` e `SCNESXXXX-ATUALIZACAO.ZIP` **como convenção genérica**, não prova que existam arquivos desses nomes para versões específicas nem que tragam histórico de `TB_LEITO`. |
| Informes históricos oficiais do CNES | https://cnes2.datasus.gov.br/Mod_Mensagem_Abertura1.asp | Página pública acessível, com informes textuais datados que mencionam **versões literais** em alguns marcos. Nenhum item dessa página fornece aqui a composição/hashes do instalador histórico. |
| RTS, conforme gate anterior | https://wiki.saude.gov.br/RTS/index.php/RTS_Portal | Canal versionado documentado, mas ensaio visual anterior encontrou `LEITO 10/2019A` para competência 201910 e resultados vazios nos testes anteriores. Não houve novo dump/versionamento das tabelas 2017–2019 nesta rodada. |

**URL funcional corrigida e confirmada:** a página de base de dados é `/pages/downloads/arquivosBaseDados.jsp`, **não** `/pages/downloads/baseDados.jsp`; esta última tentativa não forneceu página utilizável. Nunca registrar o caminho tentado como link comprovado de download.

### 2. Identificadores de release visíveis em informes datados — sem atribuição de competência exata

| Data do **informe** | Evidência textual literal | O que não foi comprovado |
|---|---|---|
| **13/12/2017** | Informe sobre municípios-satélites do DF menciona **SCNES 4.0.20** e alteração que seria realizada **a partir de sua disponibilização**; **não** é aviso explícito de disponibilidade naquele dia | Não provar `COMPETEN=201712` para essa versão, nem mudança da tabela de leitos. |
| **13/04/2018** | Informe **`VERSÃO SCNES 4.0.30`** declara versão **obrigatória e disponibilizada**, informa correção de credenciais e compatibilidade de importação com bases `4.0.20`/`4.0.21` | Não associar release a uma versão de `TB_LEITO` ou a mudanças no domínio hospitalar. |
| **22/11/2019** | Informe **`Instalador VERSÃO SCNES 4.1.50`** declara versão disponibilizada para correção da seleção de pasta no instalador | Não provar que versão `4.1.50` era usada em `201909` ou `201912`, nem que seu conteúdo alterou leitos. |
| **16/01/2020** (controle posterior, fora do recorte) | Informe anuncia **`SCNES 4.1.70`** atualização/completa, obrigatória | Não aplicar retroativamente ao recorte 2017–2019. |

**Proveniência:** todas as quatro referências acima são do mesmo histórico oficial de informes CNES/DATASUS. **Versão do software não equivale a versão da terminologia RTS, competência administrativa do LT ou período de validade dos códigos de leito.** Os informes não fornecem lista exaustiva das versões; a ausência de linha no período não prova inexistência de release.

### 3. Matriz dos checkpoints solicitados vs evidência realmente encontrada

| Marco | Evidência metadata-only | `TB_LEITO` e pares versionados | Situação |
|---|---|---|---|
| `201701` | Canal histórico de apps e arquivo de texto CNES; **nenhuma versão plena/arquivo SCNES identificada para este mês** | Não inspecionado | `VERSION_NOT_RESOLVED`; bases públicas CNES documentadas somente desde 201706 |
| `201703–201706` | Disponibilidade de bases públicas **a partir de 201706** declarada na Wiki, não inventariadas por competência | Não inspecionado | `PUBLIC_BASE_CHANNEL_DOCUMENTED_ONLY` |
| `201712` | Informe `13/12/2017` menciona `SCNES 4.0.20` como implantação futura; sem data de entrega comprovada | Não inspecionado | `VERSION_NAME_MENTIONED_NOT_DATED_RELEASE` |
| `201804` (controle suplementar) | Informe de 13/04/2018 comprova disponibilidade de **SCNES 4.0.30** | Não inspecionado | `DATED_RELEASE_NOTICE_FOUND` |
| `201903` | Fonte normativa Portaria SAS/MS 298/2019, efeitos **condicionados** à disponibilização DATASUS | Não inspecionado | `VERSION_NOT_RESOLVED` |
| `201909` | Snapshot oficial NT32/2019 já auditado e datado de setembro; **não foi encontrada nesta triagem a versão SCNES deste mês** | Referência de setembro conhecida, **não** versão binária `TB_LEITO` | `DATED_LEGEND_ONLY` |
| `201911` (controle suplementar) | Informe 22/11/2019 confirma instalador **SCNES 4.1.50**, sem listar bancos/tabelas | Não inspecionado | `DATED_RELEASE_NOTICE_FOUND` |
| `201912` | Download por competência documentado, **sem versão/arquivo específico 201912 identificado** | Não inspecionado | `VERSION_NOT_RESOLVED` |

### 4. Nova evidência complementar — arquivo `LEITOS 65`

O Portal CNES **exibe realmente** `LFCES002_201301_65.ZIP` em **Downloads → Arquivos para outros sistemas → LEITOS 65**, diferente da trilha **Aplicativos → Versões anteriores SCNES**. Esse achado pode ser útil numa futura consulta **minimamente direcionada**, mas o nome `201301` e o termo `LEITOS 65` **não demonstram** ser tabela normativa CNES de 2017–2019, não demonstram associação `TP_LEITO/CODLEITO`, nem relação com `TB_LEITO`.

**HIPÓTESE INVESTIGATIVA — NÃO VALIDADA:** se vier a ser autorizada aquisição mínima de um único arquivo, sua documentação e conteúdo poderão dizer se ele é apenas um arquivo auxiliar de processamento ou se fornece referência historicamente relevante. **Nenhum download foi executado, logo não há SHA, conteúdo, tamanho nem link direto de bytes verificados.**

### 5. Resultado do gate e próxima ação limitada

**Resultado da Discovery C4.2c.4b:** `SCNES_OFFICIAL_ENTRYPOINTS_AND_RELEASE_NOTICES_VERIFIED / HISTORICAL_TB_LEITO_BINARY_INVENTORY_NOT_RESOLVED`.

- **FATO VERIFICADO:** URLs oficiais de **aplicativos, bases por competência e arquivos para outros sistemas** foram abertas; há arquivos SCNES históricos descritos na documentação e releases nomeados/datados em informes (ex.: `4.0.30` em 201804 e `4.1.50` em 201911).
- **DECISÃO PENDENTE / BLOQUEIO:** o HTML sem execução de JavaScript **não enumerou arquivos individuais de versões antigas**. Nenhuma versão de `NFCES001/TB_LEITO` foi obtida, comparada ou ligada a um mês LT; `T29_HISTORICAL=NOT_APPROVED`.
- **PRÓXIMO GATE C4.2c.4c — MANUAL ENUMERATION ONLY, SEM DOWNLOAD:** com navegador local no [Portal CNES — Aplicativos](https://cnes.datasus.gov.br/pages/downloads/aplicativos.jsp), inspecionar a seção **`VERSÕES SCNES ANTERIORES`**, registrar em captura/tabela apenas **nome literal da versão, rótulo completa/atualização, eventuais datas e detalhes/links exibidos** para amostras 2017, 2019; não clicar em binários. Na página [Base de Dados](https://cnes.datasus.gov.br/pages/downloads/arquivosBaseDados.jsp), verificar se o seletor de competência mostra `201706`, `201903`, `201909`, `201912`, **sem iniciar download**. Marcar `JS_NOT_ENUMERABLE` ou `ACCESS_BLOCKED` se a interface não apresentar a lista. Registrar ausência de datas sem inventar versão/mês.
- **ESCALONAMENTO:** se a enumeração encontrar um candidato **cuja descrição pública afirme conter domínio de leitos**, propor posteriormente uma única aquisição técnica controlada (bytes, hash, lista interna e contrato do arquivo) **somente com autorização específica**. Não instalar executáveis por padrão; priorizar documento/layout/listagem acessível sem execução.

**ESTADO:** `C4.2c.4a=PASS_LOCAL`, `C4.2c.4b=METADATA_ONLY_PARTIAL_CHANNELS_IDENTIFIED_BINARY_NOT_ENUMERATED`, `C4.2c.4c=LOCAL_BROWSER_ENUMERATION_PENDING`, `A2=CONTRACT_DECISION_PENDING`, `T29_HISTORICAL=NOT_APPROVED`, `main=7/8`. Nenhum `DIM_TIPO_LEITO.qvd`, fato, Link Table ou painel gerado.

## C4.2c.4c–d — Reconciliação do inventário visual e metadados da documentação CNES (09/10/2026)

**Escopo:** correção exclusivamente documental, baseada nas capturas do portal CNES com JavaScript disponibilizadas pelo responsável em 09/10/2026. Nenhum ZIP, executável ou conjunto de dados foi baixado/inspecionado; nenhuma dimensão, QVD, fato, Link Table, script de modelagem ou capítulo acadêmico foi alterado. Este adendo **complementa** o retrato metadata-only anterior (§ C4.2c.4b); afirmações antigas sobre listas não enumeráveis descreviam apenas o HTML estático e **não representam mais um bloqueio para a enumeração visual**.

### Evidência 1 — listas de aplicativos SCNES anteriores

- Duas capturas do portal oficial `https://cnes.datasus.gov.br/pages/downloads/aplicativos.jsp` mostram as listas expandidas de versões completas e atualizações anteriores.
- Nomes visíveis relevantes: `SCNES4020-COMPLETA.ZIP`, `SCNES4020-ATUALIZACAO.ZIP`, `SCNES4030-COMPLETA.ZIP`, `SCNES4030-ATUALIZACAO.ZIP`, `SCNES4150-COMPLETA.ZIP` e `SCNES4150-ATUALIZACAO.ZIP`.
- Os informes oficiais anteriormente registrados continuam sendo **marcos de menção/disponibilização de software**, não evidência de competência de processamento, conteúdo de `TB_LEITO` nem início de vigência normativa.

### Evidência 2 — ZIPs de base CNES por competência

- Captura da lista expandida em `https://cnes.datasus.gov.br/pages/downloads/arquivosBaseDados.jsp`, nome de arquivo de evidência fornecido: `screencapture-cnes-datasus-gov-br-pages-downloads-arquivosBaseDados-jsp-2026-10-09-13_20_55.pdf`.
- **FATO VISUAL VERIFICADO:** os 36 itens de `201701` a `201912` aparecem em sequência, sob padrão `BASE_DE_DADOS_CNES_AAAAMM.ZIP` (por exemplo `BASE_DE_DADOS_CNES_201701.ZIP`, `BASE_DE_DADOS_CNES_201706.ZIP`, `BASE_DE_DADOS_CNES_201903.ZIP`, `BASE_DE_DADOS_CNES_201909.ZIP`, `BASE_DE_DADOS_CNES_201912.ZIP`). Não foram observadas lacunas **na lista**, sem concluir que os 36 arquivos estejam íntegros ou possam ser efetivamente baixados.
- **DIVERGÊNCIA DOCUMENTAL A RECONCILIAR:** a Wiki CNES consultada na rodada anterior descreve disponibilização de bases por competência **a partir de 06/2017**, mas o seletor observado atualmente também lista `201701–201705`. A listagem contemporânea não demonstra se a Wiki está desatualizada, se os arquivos antigos foram acrescentados posteriormente ou se seus links são funcionais. Não reescrever o histórico da Wiki por inferência.

### Evidência 3 — arquivo oficial da seção Tabelas de Domínio

- **FATO VISUAL VERIFICADO:** na captura fornecida da página oficial `https://cnes.datasus.gov.br/pages/downloads/documentacao.jsp`, a linha **Tabelas de Domínio** apresenta **`18/10/2019` na coluna `ÚLTIMA ATUALIZAÇÃO`**. A linha **Dicionário de Dados do SCNES** apresenta **`26/06/2026`** (não confundir com edição normativa histórica).
- **URL literal fornecida pelo responsável a partir do item de download:** `https://cnes.datasus.gov.br/EstatisticasServlet?path=SCNES_DOMINIOS.ZIP`; nome do arquivo indicado pela URL: `SCNES_DOMINIOS.ZIP`. Este é um **link de download identificado**, mas não houve acesso aos bytes do ZIP, verificação HTTP do binário, SHA-256, tamanho, inspeção de entradas internas ou obtenção de versões anteriores.
- O HTML estático do portal conserva o placeholder `{{scnesTabelasDominio.dtAtualizacao}}`; a data acima deriva **da captura do navegador com JavaScript**, e não de uma data extraída do HTML estático.
- **NÃO VERIFICADO:** se o ZIP contém `NFCES001/TB_LEITO` e `NFCES028/TB_ATRIBUTO`, quais pares `TP_LEITO+CODLEITO` contém, qual versão de cada tabela, ou quaisquer datas de aplicabilidade 2017–2019. **18/10/2019 é a data exibida de atualização do download, não uma competência normativa da legenda ou prova de validade retroativa.** Nem sequer prova preservação da versão 2019 para download hoje.

### Inventário mínimo corrigido

| Fonte | Nome/identificador | Temporalidade observada | URL oficial | Conteúdo interno | Potencial para T29 | Limitação |
|---|---|---|---|---|---|---|
| SCNES aplicativos | `SCNES4020`, `SCNES4030`, `SCNES4150` (completo/atualização) | Releases informados na documentação histórica, não competências LT | [Aplicativos](https://cnes.datasus.gov.br/pages/downloads/aplicativos.jsp) | Não inspecionado | Indeterminado | Identidade da versão do software não equivale à vigência do domínio |
| CNES bases mensais | `BASE_DE_DADOS_CNES_AAAAMM.ZIP` | Itens exibidos `201701–201912` (36/36) | [Base de dados](https://cnes.datasus.gov.br/pages/downloads/arquivosBaseDados.jsp) | Não inspecionado | Indeterminado | Links individuais, disponibilidade efetiva e presença de `TB_LEITO` não demonstrados |
| CNES documentação | `SCNES_DOMINIOS.ZIP` | Atualização exibida `18/10/2019` | [Link do item de domínio](https://cnes.datasus.gov.br/EstatisticasServlet?path=SCNES_DOMINIOS.ZIP) | Não inspecionado | **Alto como candidato a inspeção**, não como prova | Estrutura, tamanho, SHA, versões internas e vigência desconhecidos |
| CNES documentação | Dicionário de Dados do SCNES | Atualização exibida `26/06/2026` | [Documentação](https://cnes.datasus.gov.br/pages/downloads/documentacao.jsp) | Esquema conhecido de inspeções anteriores, arquivo atual não baixado | Médio, como documentação de layout | Não implica histórico de registros ou validade mensal |

### Gate e limites

- **C4.2c.4c = PASS_METADATA_INVENTORY_ONLY** para a **enumeração visual** das listas; não é PASS de disponibilidade física dos ZIPs.
- **C4.2c.4d = OFFICIAL_DOMAIN_ZIP_LINK_AND_DISPLAYED_UPDATE_IDENTIFIED / CONTENT_UNVERIFIED**.
- **A2_SK_CONTRACT = DECISION_PENDING** e **T29_HISTORICAL = NOT_APPROVED** permanecem inalterados.
- **NEXT DECISION GATE:** antes de qualquer download, obter aprovação específica para a inspeção mínima **somente** de `SCNES_DOMINIOS.ZIP` (se tecnicamente disponível), com tamanho/hash, lista de entradas, formato, versões e comparação do domínio com os 57 pares LT da PB. Inspeção física, por si, não aprova vigência mensal. Se o arquivo não trouxer metadados históricos, comparar com referência datada e manter lacuna explícita. Não antecipar instalação SCNES, aquisição dos 36 ZIPs, revisão de `Hash128`/Boundary 7, geração de `DIM_TIPO_LEITO` ou fatos.

## C4.2c.4e — Tentativa de aquisição mínima autorizada de SCNES_DOMINIOS.ZIP (09/10/2026)

**Autorização:** o responsável aprovou explicitamente a aquisição e inspeção mínima exclusivamente de `SCNES_DOMINIOS.ZIP` a partir do link oficial `https://cnes.datasus.gov.br/EstatisticasServlet?path=SCNES_DOMINIOS.ZIP`. Não foi autorizada instalação de aplicativo, aquisição em massa, mudança dimensional ou reinterpretação de `T29`.

### Resultado físico do acesso

1. Consulta ao URL oficial usando o navegador de pesquisa: respondeu com erro do **conversor de páginas**, informando literalmente `Unsupported content-type: application/zip` (HTTP 400 do leitor); isto **não** é evidência de erro HTTP 400 do próprio portal nem informa o tamanho/integridade do arquivo.
2. Tentativa de `curl -I` no container: falha local `Could not resolve host: cnes.datasus.gov.br` (restrição de resolução DNS do ambiente).
3. Tentativa de aquisição por ferramenta de download no mesmo ambiente: `download failed`; nenhum arquivo ZIP utilizável foi produzido.
4. Não há hash físico SHA-256, comprimento, lista de entradas, dados de `NFCES001/TB_LEITO` ou `NFCES028/TB_ATRIBUTO` efetivamente inspecionados.

**VEREDITO DESTA AQUISIÇÃO:** `ACCESS_BLOCKED_IN_EXECUTION_ENVIRONMENT` (não concluir indisponibilidade do arquivo no servidor). **C4.2c.4c visual permanece PASS_METADATA_INVENTORY_ONLY**, **C4.2c.4d identifica URL/data exibida mas não o conteúdo**, **A2=DECISION_PENDING**, **T29_HISTORICAL=NOT_APPROVED**.

### Menor próximo passo, sem ampliar a autorização

O responsável pode baixar **somente esse ZIP** pelo link oficial no navegador local e anexá-lo a este chat. No ambiente com acesso aos bytes, fazer inventário de entradas sem executar instaladores/macros; calcular SHA-256/tamanho; identificar formato e versões das tabelas de domínio; confrontar os pares `TP_LEITO+CODLEITO` com os **57 pares observados**; documentar explicitamente qualquer ausência de comprovação normativa mensal 2017–2019. Não transferir o ZIP ao Git nem assumir que a data exibida `18/10/2019` é competência normativa da estrutura interna. Não iniciar implementação sem o gate A2 separado.

## C4.2c.4e — inspeção física concluída do ZIP de domínios (09/10/2026)

**Evidência superveniente ao bloqueio ambiental anterior:** o responsável anexou `SCNES_DOMINIOS.ZIP` obtido pelo navegador a partir da URL já inventariada (`https://cnes.datasus.gov.br/EstatisticasServlet?path=SCNES_DOMINIOS.ZIP`). A inspeção foi **READ-ONLY**, sem execução de binários/macros, instalação, download em massa, alteração dos dados ou versionamento do ZIP. O estado anterior `ACCESS_BLOCKED_IN_EXECUTION_ENVIRONMENT` registra somente a tentativa anterior e **foi superado para este artefato por anexo do responsável**.

### Integridade e estrutura realmente inspecionadas

| Item | Resultado físico |
|---|---|
| ZIP anexado | `SCNES_DOMINIOS.ZIP`, 1.030.982 bytes |
| SHA-256 ZIP | `a3232cc737e3e9b44fb2ef80d44cfd0c30d549b22e15ec8b0888c3dc6644b3b0` |
| Teste CRC ZIP | PASS, 1 entrada, não criptografada |
| Membro único | `SCNES_DOMINIOS.XLS`, 1.339.918 bytes |
| SHA-256 do membro | `ae3f678f1f2307d759412c735f79bf1ace5a91410261f4050dc6e86c671c2af4` |
| Formato real do membro | Office Open XML (`PK` e partes `xl/worksheets/*.xml`), **apesar** da extensão `.XLS` |
| Estrutura interna | 67 entradas no pacote OOXML, 56 abas, CRC interno PASS |
| Metadados do documento | `docProps/core.xml`: criação `2019-10-15T20:05:02Z`; modificação `2019-10-15T20:06:58Z`. Não são datas de vigência normativa |
| Macros/links externos | Nenhum componente `vbaProject` ou `externalLinks` identificado por nome no pacote |

### Abas e conteúdo relevante à DIM_TIPO_LEITO

- **`LEITOS`, `A1:B67`: 66 linhas de domínio, 66 códigos distintos**; apenas colunas `LEITO` e `DESCRIÇÃO`. Exemplo adicional: **`64 = UNIDADE INTERMEDIARIA`**.
- **`TIPOS DE LEITOS`, `A1:B8`: 7 linhas, códigos `1..7`**, apenas `TIPO DE LEITO` e `DESCRIÇÃO`. Rótulos encontrados: `1 CIRURGICO`, `2 CLINICO`, `3 COMPLEMENTAR`, `4 OBSTETRICOS`, `5 PEDIATRICOS`, `6 OUTRAS ESPECIALIDADES`, `7 HOSPITAL DIA`.
- **Ausência estrutural nas duas abas:** não há `TP_LEITO` ou chave associativa leito→tipo no mesmo registro; não há competência de referência, início/fim de vigência ou status do código. Também não há tabela literal `NFCES001/TB_LEITO` ou `NFCES028/TB_ATRIBUTO` identificada por nome neste pacote. As duas abas são **domínios descritivos**, não prova física de equivalência integral às tabelas do dicionário SCNES.

### Confronto com fonte de verdade do projeto

Comparação de códigos contra `docs/discovery/cnes-nt32-2019-codigos-leito.csv` da própria branch (`65` registros e `65` códigos únicos, referência `201909`):

| Checagem | Resultado |
|---|---|
| Códigos do CSV canônico presentes no ZIP | **65/65** |
| Códigos ausentes | **0** |
| Código extra no ZIP | **`64`** (`UNIDADE INTERMEDIARIA`) |
| Códigos distintos de tipos na aba `TIPOS DE LEITOS` | **7/7** |
| Pareamento `TP_LEITO+CODLEITO` atestado fisicamente pelo ZIP | **NÃO** |
| Vigência histórica 201701–201912 atestada | **NÃO** |

**Limites críticos:** o gate anterior que comparou **57/57 pares da PB** à Nota Técnica 32/2019 é independente; nesta execução não foram reabertos os **35.518 registros LT** nem realizado JOIN por par. Não confundir `65/65 códigos` com `57/57 pares`. Pelo menos o rótulo literal do código `08` difere entre referências: no ZIP `NEFROLOGIAUROLOGIA`; no CSV da NT32/2019 `NEFROLOGIA/UROLOGIA`; **não harmonizar automaticamente**. Código `64` extra não demonstra inclusão normativa nem presença no LT PB. A data da planilha em outubro/2019 e a atualização exibida no portal em 18/10/2019 não comprovam vigência em janeiro/2017 nem continuidade até dezembro/2019.

### Veredito e gate seguinte

**`C4.2c.4e=PASS_PHYSICAL_DOMAIN_CODE_INVENTORY_ONLY`** — aquisição mínima autorizada e inspeção de conteúdo concluídas. **Não** aprova domínio temporal ou relacionamento leito→tipo.

**`T29_HISTORICAL=NOT_APPROVED`**, **`A2_SK_CONTRACT=DECISION_PENDING`**, **`DIM_TIPO_LEITO_QVD_GENERATED=False`**, **`MAIN=7/8`** e fatos/Link Table/PAINEL NOT_STARTED.

**Recomendação:** encerrar esta tentativa de aquisição e decidir separadamente **A2 (contrato dimensional conservador)**, especificando competência observada versus competência/versão da fonte descritiva, comportamento `NULL` para descrição histórica não comprovada e o significado vigente de `COMPETENCIA_REFERENCIA` antes de alterar a SK do Boundary 7. Manter bloqueio da oitava dimensão até aprovação; não é necessário buscar indefinidamente versões sem novos indícios. O ZIP e XLS não foram adicionados ao GitHub.

## Gate A2 — contrato conservador ratificado e reconciliado com Boundary 7 (09/10/2026)

**DECISÃO APROVADA PELO RESPONSÁVEL:** após concluir o inventário físico C4.2c.4e, o responsável ratificou **prosseguir com o fechamento do contrato A2 conservador** (alternativa A) conforme proposto neste documento. Esta ratificação **substitui exclusivamente o status `A2=DECISION_PENDING` dos relatos anteriores**, sem apagá-los da cronologia e sem autorizar inferências de vigência. Atualização explícita incorporada ao `docs/discovery/boundary-7-implementation-plan.md`, § 14, adendo A2 (decisão semântica; não mudança silenciosa da SK).

### Contrato de modelagem ratificado (não é PASS de QlikView)

1. **Identidade/grão da dimensão:** `(TP_LEITO_normalizado,CODLEITO_textual,COMPETEN)`, uma linha por combinação fonte e competência observada; A1 local: **2.021 pares-mês** em 36 competências.
2. **`TP_LEITO`** para computar a SK: normalização textual limitada à remoção de **espaços ASCII finais** de `"N "`, mantendo o campo bruto rastreável; `CODLEITO` continua dois dígitos textuais. Conduta `3/66` permanece sem correção; não usar `CODLEITO` sozinho como chave.
3. **Esclarecimento autorizado do quarto argumento do Boundary 7:** **`COMPETENCIA_REFERENCIA` da expressão `%SK_TIPO_LEITO=Hash128('LEITO',TP_LEITO,CODLEITO,COMPETENCIA_REFERENCIA)` receberá `COMPETEN` observada no LT exclusivamente para esta chave.** Fórmula e temporalidade são preservadas; outros usos do nome em referências históricas/PROCEDIMENTO não são reinterpretados.
4. **Descrição e proveniência:** o snapshot `201909` continua catálogo **descritivo independente**, jamais substituto da competência observada da SK. Para **56** combinações do mês `201909` (após validar associação por par), usar apenas rótulos explicitamente identificados como provenientes daquele mês; as **1.965** combinações fora dessa competência **mantêm ambas as descrições `NULL`** por ausência de fonte mensal aplicável. Proibição de descrição retroativa, sentinela textual que pareça descrição verdadeira ou propagação pelo código entre meses.
5. **Fato/relacionamentos:** `FATO_CAPACIDADE_LEITO` continua `CNES × COMPETEN × CODLEITO`, medida de leitos semi-aditiva. Cada registro LT deverá mapear-se a **uma única SK**, com cobertura integral `35.518/35.518` e sem multiplicações, a validar em QlikView.
6. **Limite acadêmico:** modelo dimensional e atributos descritivos do relatório impresso mantidos **sem alteração**. A aprovação técnica de campos `NULL` não comprova aceitação pelo professor; preservar a ressalva e solicitar orientação acadêmica se houver exigência de descrição histórica plena.

### Gatilhos, testes e mudanças permitidas

**Status do contrato:** `A2_CONTRACT=APPROVED_DOCUMENTED_NOT_IMPLEMENTED`; `T29_HISTORICAL=NOT_APPROVED`; `IV_TIPO_LEITO_QV_PHYSICAL_GATE=NOT_RUN`; `MAIN_DIMENSIONS=7/8`.

**Próxima atividade permitida:** pré-gate de **planejamento/implementação isolada** de `DIM_TIPO_LEITO` no QlikView 12, após conferir os nomes reais dos campos no staging e as aliases associativas do Qlik (evitar accidental synthetic keys). Nenhuma mudança em fatos/Link Table/PAINEL faz parte desta autorização de decisão A2. O código, QVD e checkpoint da oitava dimensão continuam **não produzidos**.

**Critérios mínimos a demonstrar posteriormente:** `2.021` chaves dimensionais de Hash128 únicas (sem colisões), nenhuma representação de tipo fora do normalizador auditado, `35.518/35.518` vínculos unívocos com LT, `0` unmatched e `0` multiplicações de linhas, `56` pares-mês `201909` com descrição datada validada, `1.965` sem descrições históricas indevidamente imputadas, e regressões `3/66=1.480`, `7/70=5`. Diferenciar **validação dos códigos** de **aprovação de validade histórica**. Sem redefinir T29; sem promover a `main` por mera aprovação documental.

## Fase IV — DIM_TIPO_LEITO — implementação isolada preparada; aviso obrigatório em análises (09/10/2026)

**DECISÃO DE APRESENTAÇÃO APROVADA:** além da preservação do contrato A2, o responsável exige que a ressalva de **1.965/2.021 (97,2%) pares tipo+leito+competência sem descrição histórica comprovada** seja **explicitamente apresentada nos gráficos de leitos e nas análises escritas**. O denominador é **combinações distintas código×competência**, não leitos físicos, quantidade `QT_EXIST`/`QT_SUS`, estabelecimentos ou 35.518 linhas LT. A regra canônica, texto completo/curto, comportamento sob filtros e critério de aceite de capturas/exportações foram registrados no adendo de apresentação de `docs/discovery/boundary-7-implementation-plan.md`. Fatos e PAINEL ainda não foram criados, portanto o aviso **ainda não está renderizado em nenhum gráfico**.

**Implementação de código preparada exclusivamente para DIM_TIPO_LEITO (não executada nesta sessão):**

- `TRANSFORMACAO/transf_dim_tipo_leito.qvs` (novo), carregado **após** `transf_dim_motivo_saida_permanencia.qvs` via `$(Must_Include=transf_dim_tipo_leito.qvs);` em `TRANSFORMACAO/transf_main.qvs`.
- Fontes: `SRC_CNES_LT.qvd` e `REF_TIPO_LEITO.qvd` de staging; **não** altera a EXTRAÇÃO nem usa diretamente o ZIP de domínio. A referência NT32 é aplicada por par **somente em `COMPETEN=201909`**. Nos outros meses mantém `NULL` real para `DESCRICAO_TIPO_LEITO`, `DESCRICAO_ESPECIALIDADE_LEITO` e `COMPETENCIA_LEGENDA_LEITO`.
- Dimensão candidata preserva `TP_LEITO_BRUTO` com trailing space, `COD_TIPO_LEITO` normalizado por remoção do único espaço ASCII final observado, `COD_LEITO` textual de 2 dígitos, `COMPETENCIA_OBSERVACAO_LEITO`, Hash128 temporal `%SK_TIPO_LEITO`, nomes (possivelmente `NULL`), `STATUS_DESCRICAO_LEITO` e `LEITO_TEM_LEGENDA_DATADA` para apoiar apresentação responsável. `STATUS_DESCRICAO_LEITO` e o flag **marcam cobertura de legenda, não validade normativa T29**.
- Gate de script exige 2.021 chaves temporais/2.021 SK distintas, 35.518/35.518 linhas LT com SK aplicável (nenhum unmatched), 36 meses, 57 pares globais, 56 nomes contemporâneos, 1.965 pares-mês com `NULL` descritivo, ocorrência do par `3/66` em 1.480 linhas, par `7/70` em cinco linhas e nenhuma duplicata em `CNES+COMPETEN+CODLEITO`.
- Somente após todos os controles, o script pode gerar `TRANSFORMACAO/QVD/DIM_TIPO_LEITO.qvd` e `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_TIPO_LEITO.csv` **parciais**. Não cria `_SUCCESS_TRANSFORMACAO.csv`, FATO, Link Table, PAINEL ou QVDs de outras dimensões.
- `tools/audit_dim_tipo_leito_qvd.py` (novo, read-only): após o reload QlikView 12, reexecuta A1, verifica **apenas header XML** do novo QVD (2.021 registros, 10 campos) e checkpoint, SHA-256, frescor do arquivo, 56/1.965 e limites. **Não decodifica conteúdo binário QVD**. A inspeção independente de nomes/códigos por registro ainda dependerá do QlikView e/ou outro mecanismo aprovado.

**Teste estático de código executado na sessão:** `PASS_STATIC_SOURCE_CONTRACT_ONLY`. Inclui verificação de nomes reais de campos em `ext_main.qvs` e `ext_c4_cnes_leitos.qvs`, inclusão uma única vez e ao fim da sequência, mapeamento descritivo restrito a `201909`, política `NULL`, controles numéricos, ausência de `STORE FATO`/marcador global e contrato do aviso visual. **NÃO HOUVE RELOAD QlikView 12, execução local do novo auditor, emissão de QVD ou prova física de Hash128 nesta sessão.**

### Gate local obrigatório — ainda não realizado

1. Atualizar a branch no Windows (árvore local limpa/sem sobrescrever mudanças locais); executar no diretório raiz:
   ```powershell
   git fetch origin
   git switch feat/phase-4-dim-tipo-leito-discovery
   git pull --ff-only
   .\.venv\Scripts\python.exe .\tools\preflight_dim_tipo_leito_contrato_a.py
   ```
2. Abrir `TRANSFORMACAO/TRANSF.qvw` no **QlikView 12** e executar reload explícito; guardar o log correspondente. Procurar `[TRANSFORMACAO][IV-LEITO]` com `START`, `PARTIAL_ONLY`, `QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`, ausência de `FAIL`, `Unknown statement` e `Syntax Error`. `TRACE` dentro do script pode aparecer no log como linha de código: conferir **execução real** e finalização, não apenas ocorrência textual.
3. Verificar que `DIM_TIPO_LEITO.qvd` e `_CHECKPOINT_DIM_TIPO_LEITO.csv` são **novos/frescos** (sem aceitar resíduos de execuções antigas) e rodar:
   ```powershell
   .\.venv\Scripts\python.exe .\tools\audit_dim_tipo_leito_qvd.py
   ```
4. Trazer log QlikView (ou trechos com horário inequívoco), checkpoint e saída completa do auditor para revisão independente. **Não abrir PR/merge nem iniciar fatos/PAINEL com base apenas no teste estático**. Regressão em outras sete dimensões ou qualquer desvio numérico resulta em `REVIEW_REQUIRED`.

**STATUS:** `A2_CONTRACT=APPROVED`; `IV_TIPO_LEITO=CODE_READY_QV12_NOT_RUN`; `PRESENTATION_CNES_HISTORICAL_CAVEAT=REQUIRED_NOT_RENDERED`; `T29_HISTORICAL=NOT_APPROVED`; `MAIN_DIMENSIONS=7/8`; `FACTS_LINK_TABLE_PANEL=NOT_STARTED`.
