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
