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
