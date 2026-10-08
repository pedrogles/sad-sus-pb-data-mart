# Current State

## Projeto

**SAD — Data Mart SUS PB**

Disciplina: Sistemas de Apoio à Decisão — 2026.2  
Ferramenta obrigatória: QlikView 12

---

## Estado atual

### Primeira entrega acadêmica

**FECHADA — PRONTA PARA IMPRESSÃO/ENTREGA**

Data de fechamento documental:

**02/10/2026**

Escopo:

- Capítulo 1 — Regras de Negócio;
- DER / modelo conceitual;
- cardinalidades mínima e máxima;
- modelo lógico relacional normalizado;
- Capítulo 2 — Modelagem Dimensional;
- escolha e justificativa Star x Snowflake;
- modelo dimensional.

Revisão final:

`docs/academic/first-delivery-review.md`

Veredito:

**NENHUM ITEM OBRIGATÓRIO FALTANTE IDENTIFICADO PARA O ESCOPO DA PRIMEIRA ENTREGA.**

O relatório final utiliza:

**Pedro Gabriel Lima e Silva**

como integrante e **João Pessoa - PB** como local.

---

## Etapas concluídas

### Feasibility Discovery

**CONCLUÍDA**

Veredito histórico:

**APROVADO COM AJUSTES**

Documento:

`docs/discovery/feasibility.md`

### Dataset Validation / Modeling Discovery

**CONCLUÍDA**

Documento:

`docs/discovery/dataset-validation.md`

### Academic Modeling / Chapters 1–2

**CONCLUÍDA**

Documento canônico:

`docs/academic/chapter-1-2-modeling.md`

Redação utilizada na primeira entrega:

- `docs/academic/chapter-1-draft.md`;
- `docs/academic/chapter-2-draft.md`.

### BOUNDARY 3 — Full Dataset Validation

**CONCLUÍDO**

Período validado integralmente:

**2017-01 a 2019-12**

Cobertura:

- SIH/RD: 36/36 competências;
- CNES/LT: 36/36 competências;
- CNES/ST: 36/36 competências;
- total: 108/108 arquivos DBC esperados.

Documento canônico:

`docs/discovery/boundary-3-full-dataset-validation.md`

Veredito:

**APROVADO PARA PROSSEGUIR COM AJUSTES**

Principais evidências:

- RD manteve schema de 113 campos em 36/36 competências;
- LT manteve schema de 28 campos em 36/36 competências;
- ST manteve 201 campos em 35/36 competências e apresentou drift real em `STPB1912.dbc`, com 208 campos;
- o drift de `STPB1912.dbc` não altera os campos atualmente usados pela modelagem de estabelecimento, mas exige extração futura por nome de campo, não por posição fixa;
- `N_AIH` permaneceu não único em 36/36 competências e as duplicidades mensais observadas estão associadas a grupos contendo `IDENT=5`;
- `CNES + COMPETEN + CODLEITO` permaneceu único em 36/36 competências de LT;
- `CNES` permaneceu único por competência em 36/36 meses de ST;
- as integrações `SIH.CNES ↔ ST.CNES`, `SIH.CNES ↔ LT.CNES`, `LT.CNES ↔ ST.CNES` e `SIH.MUNIC_MOV ↔ ST.CODUFMUN` apresentaram 100% de cobertura nas 36 competências;
- foi observado `COBRANCA=24`, ausente nos checkpoints originais, cuja descrição oficial deve ser fechada no Boundary 4.

Nenhuma decisão estrutural aprovada para fatos, dimensões, granularidades ou Star Schema precisou ser alterada.

### BOUNDARY 4 — Referências Auxiliares

**CONCLUÍDO**

Documento canônico:

`docs/discovery/boundary-4-auxiliary-references.md`

Veredito:

**APROVADO PARA PROSSEGUIR COM AJUSTES**

Principais resultados:

- SIGTAP confirmado como referência oficial de `PROC_REA`, com tratamento por competência;
- CID-10 confirmada como referência de `DIAG_PRINC`;
- domínio oficial de `CAR_INT` fechado em `01`–`06`;
- `COBRANCA=24` resolvido oficialmente como código normativo `2.4`, “Por Processo de doação de órgãos, tecidos e células — doador vivo”;
- referências oficiais de `TP_LEITO` / `CODLEITO` localizadas e mantidas como competência-aware;
- fonte histórica de estabelecimento localizada, com lacuna ainda não comprovada para nome fantasia / razão social em 2017-01 a 2017-05;
- nenhuma decisão estrutural de fatos, dimensões, granularidades ou Star Schema foi alterada.

Ajustes ainda pendentes de implementação:

- medir cobertura real `PROC_REA × SIGTAP`;
- medir cobertura real `DIAG_PRINC × CID-10`;
- materializar/comparar a referência histórica de `TP_LEITO/CODLEITO`;
- manter explícita a lacuna de nomes históricos de estabelecimento no início de 2017.

### BOUNDARY 5 — Historização / Role-playing

**CONCLUÍDO**

Documento canônico:

`docs/discovery/boundary-5-historization-role-playing.md`

Veredito:

**APROVADO PARA PROSSEGUIR**

Decisões confirmadas:

- `DIM_ESTABELECIMENTO` será versionada por snapshot mensal;
- grão histórico: `CNES × competência`;
- `SK_ESTABELECIMENTO` identifica a versão histórica; `CNES` permanece a identidade natural;
- SCD Type 1 e Type 3 foram rejeitados;
- SCD Type 2 comprimido por intervalos não será usado na V1;
- nomes históricos sem fonte comprovada não serão preenchidos por forward fill, backfill ou uso retroativo do nome atual;
- `DIM_TEMPO` permanece dimensão conformada única, com aliases físicos por papel no QlikView;
- `DIM_MUNICIPIO` permanece dimensão conformada única, com aliases físicos por papel no QlikView;
- a fonte física canônica de Tempo/Município não será duplicada por papel;
- a estratégia física multi-fato foi encaminhada ao Boundary 6.

### BOUNDARY 6 — Arquitetura física QlikView

**CONCLUÍDO**

Documento canônico:

`docs/discovery/boundary-6-qlikview-physical-architecture.md`

Veredito:

**APROVADO PARA PLANO DE IMPLEMENTAÇÃO**

Decisões confirmadas:

- fato concatenada foi rejeitada como arquitetura física principal para preservar a separação acadêmica das três fatos;
- `LINK_ANALISE` foi aprovada como ponte física do modelo associativo;
- `LINK_ANALISE` não constitui nova fato ou dimensão de negócio;
- município de residência será eixo compartilhado entre Internação e População;
- município de serviço será eixo compartilhado entre Internação, Capacidade e População;
- competência será eixo compartilhado entre Internação e Capacidade;
- ano analítico será compartilhado pelas três fatos;
- estabelecimento histórico será compartilhado entre Internação e Capacidade via Link Table;
- chaves persistidas em QVD devem ser determinísticas, preferencialmente `Hash128`;
- campos técnicos de associação utilizarão prefixo `%`;
- scripts `.qvs` externos e versionáveis serão chamados pelos QVW com `Must_Include`;
- staging será consolidado por família de fonte;
- CNES/ST será extraído por nomes explícitos de campos, sem depender da posição ordinal;
- o modelo final terá como critério 0 circular references e 0 synthetic keys não justificadas.

### BOUNDARY 7 — Plano de implementação

**CONCLUÍDO**

Documento canônico:

`docs/discovery/boundary-7-implementation-plan.md`

Veredito:

**APROVADO PARA READINESS**

Decisões confirmadas:

- a implementação seguirá BASE → EXTRAÇÃO → TRANSFORMAÇÃO → PAINEL;
- DBC será pré-processado por Python para CSV UTF-8 antes da extração QlikView;
- baseline de ferramentas para readiness: `dbc-to-dbf==1.0.1` + `dbfread==2.0.7`;
- o conversor deverá gerar manifesto com hashes, contagens e assinatura de schema;
- os 108 DBCs deverão reconciliar com os resultados do Boundary 3 antes de qualquer carga QlikView;
- a V1 será full rebuild, sem incremental;
- `EXT.qvw` gerará QVDs de staging;
- `TRANSF.qvw` gerará 3 fatos, 8 dimensões e `LINK_ANALISE`;
- `PAINEL.qvw` carregará apenas QVDs transformados e aliases role-playing;
- chaves persistidas usarão representação determinística;
- para batch, o baseline foi corrigido no Boundary 8 para `ErrorMode=0` + checagem explícita das variáveis de erro;
- a execução local poderá ser orquestrada por `run_pipeline.cmd`;
- o modelo terá marcadores de sucesso e reconciliação entre estágios;
- nenhum dashboard será iniciado antes do GO do Boundary 8.

### BOUNDARY 8 — Readiness

**CONCLUÍDO — GO PARA IMPLEMENTAÇÃO**

Documento canônico:

`docs/discovery/boundary-8-readiness.md`

Evidência local adicional:

`docs/discovery/boundary-8-local-preflight-2026-10-07.md`

Preflight local executado em 07/10/2026:

- veredito: **LOCAL_PREFLIGHT_PASS**;
- blockers automáticos: **0**;
- Windows: PASS;
- Python: **3.14.8**;
- `.venv`: PASS;
- `dbc-to-dbf==1.0.1`: PASS;
- `dbfread==2.0.7`: PASS;
- imports Python: PASS;
- QlikView localizado em `C:\Program Files\QlikView\Qv.exe`;
- BASE: PASS;
- RD: **36/36**;
- LT: **36/36**;
- ST: **36/36**;
- IBGE: **1 arquivo para 2017, 2018 e 2019**;
- `.gitignore`: PASS;
- espaço livre observado: **74,07 GB**.

Ferramentas de readiness:

- `tools/readiness_check.ps1`;
- `tools/readiness_dbc_smoke.py`;
- `tools/readiness_smoke.qvs`.

Evidência adicional:

- `docs/discovery/boundary-8-dbc-smoke-2026-10-07.md`;
- DBC → DBF → CSV UTF-8: **PASS**;
- `RDPB1702`: 13.912 registros / 113 campos;
- `LTPB1712`: 1.033 registros / 28 campos;
- `STPB1701`: 5.692 registros / 201 campos;
- `STPB1912`: 6.438 registros / 208 campos.

Evidência QlikView adicional:

- `docs/discovery/boundary-8-qlikview-smoke-2026-10-07.md`;
- CSV → QlikView: **PASS** — 13.912 linhas;
- `Must_Include`: **PASS**;
- include aninhado: **PASS**;
- QVD STORE: **PASS**;
- `Qv.exe /r`: **PASS**;
- Link Table smoke: **PASS**;
- synthetic keys: **0 visíveis no protótipo**;
- circular references: **0 visíveis no protótipo**;
- residência e serviço permanecem como papéis separados.

Evidência adicional:

- `docs/discovery/boundary-8-qlikview-version-2026-10-07.md`;
- R15 — QlikView major version: **PASS**;
- versão observada: **12.0.20000.0**.

Evidência adicional:

- `docs/discovery/boundary-8-acquisition-manifest-structure-2026-10-07.md`;
- `manifesto-execucao.json` confirmado como fonte dos `size_bytes` e `sha256` por DBC;
- `tools/readiness_reconcile_hashes.py` adicionado para comparação 108/108.

Evidência adicional:

- reconciliação de hashes/tamanhos: **PASS — 108/108**;
- 0 ausentes, 0 duplicados, 0 divergentes, 0 extras;
- smoke de falha de batch: **PASS**;
- `ScriptErrorCount`: 0 → 1 na falha proposital;
- marcador `PASS_EXPECTED_ERROR_CAUGHT` gerado;
- marcador inesperado não gerado;
- `docs/discovery/boundary-8-batch-failure-smoke-2026-10-07.md`.

Decisão final sobre referências auxiliares:

- SIGTAP / `PROC_REA`: materialização por competência durante a implementação; cobertura medida em T27;
- CID-10 / `DIAG_PRINC`: referência oficial materializada durante a implementação; cobertura medida em T28; sem historização mensal sem evidência;
- CNES `TP_LEITO` / `CODLEITO`: referência por competência; comparação histórica 2017–2019 e cobertura em T29;
- nomes históricos de estabelecimento em 2017-01 a 2017-05: ausência explícita quando não comprovados, sem forward fill/backfill;
- referências não resolvidas: preservar código factual, registrar exceção e não fabricar descrição.

Os testes T27–T29 permanecem gates de implementação e não bloqueiam o início da Fase I.

Blockers remanescentes do Boundary 8:

**NENHUM.**

Próxima etapa autorizada:

**FASE I — INFRAESTRUTURA MÍNIMA**.

---

## Tema confirmado

Data Mart para análise descritiva e comparativa da demanda hospitalar processada pelo SUS, capacidade de leitos cadastrada e população municipal na Paraíba.

---

## Período confirmado

**2017–2019**

Justificativa:

- três anos completos e consecutivos;
- compatibilidade estrutural validada entre SIH/SUS, CNES e IBGE;
- volume compatível com o escopo acadêmico;
- recorte anterior à pandemia de COVID-19.

Os checkpoints de janeiro de 2017, 2018 e 2019 validaram inicialmente estrutura, granularidade, chaves e integração.

O Boundary 3 posteriormente validou integralmente as 36 competências de RD, LT e ST e confirmou as decisões estruturais atuais, com ajustes técnicos documentados.

Ressalva:

a série populacional possui mudança metodológica/projecional entre as publicações de 2017 e 2018; a diferença entre esses anos não deve ser interpretada automaticamente como variação demográfica observada.

---

## Fontes confirmadas

- SIH/SUS — RD / AIH Reduzida;
- CNES — LT / Leitos;
- CNES — ST / Estabelecimentos;
- IBGE — estimativas populacionais municipais.

### Dependência acadêmica

Como a origem é composta por arquivos públicos e não por um banco relacional de origem, aplica-se a regra do roteiro do professor de **avaliação caso a caso** para fontes baseadas em arquivos.

Não há ação técnica capaz de substituir essa avaliação acadêmica.

---

## Arquitetura dimensional aprovada

### Fatos

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`.

### Dimensões

- `DIM_TEMPO`;
- `DIM_MUNICIPIO`;
- `DIM_ESTABELECIMENTO`;
- `DIM_PROCEDIMENTO`;
- `DIM_DIAGNOSTICO`;
- `DIM_CARATER_ATENDIMENTO`;
- `DIM_MOTIVO_SAIDA_PERMANENCIA`;
- `DIM_TIPO_LEITO`.

### Estrutura

**Star Schema em cada processo factual, com dimensões conformadas compartilhadas.**

O conjunto completo é uma **constelação de esquemas estrela**.

---

## Granularidades aprovadas

### FATO_INTERNACAO

**1 linha = 1 registro administrativo RD / AIH processada.**

`IDENT=5` representa continuidade e não conta como nova internação.

A carga integral confirmou essa granularidade em 36/36 competências.

### FATO_CAPACIDADE_LEITO

**1 linha = estabelecimento × competência mensal × código/detalhamento de leito.**

Capacidade é semi-aditiva no tempo.

A chave de grão `CNES + COMPETEN + CODLEITO` permaneceu única em 36/36 competências.

### FATO_POPULACAO

**1 linha = município × ano.**

População é semi-aditiva no tempo.

---

## Chaves de integração validadas

### Estabelecimento

`SIH.CNES ↔ CNES/ST.CNES ↔ CNES/LT.CNES`

Cobertura observada na validação integral:

**100% em todas as 36 competências.**

### Município de atendimento/localização

`SIH.MUNIC_MOV ↔ CNES.CODUFMUN`

Cobertura observada na validação integral:

**100% em todas as 36 competências.**

### Município de residência

`SIH.MUNIC_RES` pode apontar para municípios fora da Paraíba.

O Boundary 3 observou 5.202 registros RD de residentes fora da Paraíba; esses registros permanecem semanticamente válidos.

### DATASUS ↔ IBGE

A integração municipal utilizará correspondência validada anteriormente.

Não fabricar o sétimo dígito do código IBGE.

O Boundary 3 não refez byte a byte essa validação porque os três arquivos anuais do IBGE não estavam nos ZIPs da execução; não foi encontrada evidência que contradiga a compatibilidade previamente estabelecida.

---

## Regras analíticas preservadas

- `N_AIH` não é PK da fato;
- chave técnica deve preservar rastreabilidade;
- residência e atendimento são papéis municipais distintos;
- `PROC_REA` é o procedimento principal da primeira versão;
- `DIAG_PRINC` é o diagnóstico da primeira versão;
- diagnósticos secundários ficam fora do escopo inicial;
- competência, internação e saída são papéis temporais distintos;
- leitos e população são semi-aditivos no tempo;
- indicadores anuais de capacidade utilizam média dos snapshots mensais;
- internações/leito é relação descritiva, não taxa de ocupação;
- todos os registros LT válidos são preservados e o recorte hospitalar é analítico;
- extração futura de CNES/ST deve selecionar campos por nome e ser tolerante ao drift observado em `STPB1912.dbc`.

---

## Pendências de implementação

Estas pendências **não reabrem a primeira entrega** e devem ser tratadas nas fases correspondentes do Boundary 7:

- materializar as referências auxiliares no estágio correspondente da implementação;
- medir cobertura real `PROC_REA × SIGTAP` em T27;
- medir cobertura real `DIAG_PRINC × CID-10` em T28;
- materializar/comparar a referência histórica de `TP_LEITO/CODLEITO` e medir cobertura em T29;
- manter explícita, sem imputação, a lacuna de nome fantasia/razão social para 2017-01 a 2017-05 quando não houver fonte comprovada;
- executar as fases de conversão, extração, transformação, Link Table, indicadores e painéis somente na ordem do Boundary 7;
- construir e validar no mínimo 3 painéis na fase apropriada;
- preparar Capítulos 3–5 e anexos para a entrega final.

---

## Fase I — Infraestrutura mínima

Status:

**CONCLUÍDA**

### Implementado no repositório

- `tools/requirements-tools.txt` com `dbc-to-dbf==1.0.1` e `dbfread==2.0.7`;
- `tools/dbc_to_csv.py` conforme o contrato DBC → DBF temporário → CSV UTF-8 e manifesto operacional;
- `EXTRACAO/ext_main.qvs`;
- `TRANSFORMACAO/transf_main.qvs`;
- `PAINEL/painel_main.qvs`;
- diretórios versionáveis `EXTRACAO/QVD` e `TRANSFORMACAO/QVD` por `.gitkeep`;
- `.gitignore` alinhado à estrutura BASE/EXTRACAO/TRANSFORMACAO;
- QVWs binários locais protegidos contra versionamento acidental enquanto a política de versionamento dos binários permanecer pendente.

### Evidência local de fechamento — 07/10/2026

No ambiente Windows/QlikView 12 foram criados:

- `EXTRACAO/EXT.qvw` com `$(Must_Include=ext_main.qvs);`;
- `TRANSFORMACAO/TRANSF.qvw` com `$(Must_Include=transf_main.qvs);`;
- `PAINEL/PAINEL.qvw` com `$(Must_Include=painel_main.qvs);`.

Os três documentos foram recarregados localmente após sincronização da `main` e os três reloads foram confirmados como **PASS**, sem erro de `Must_Include`.

O marcador local `tools/readiness_link_table_success.csv` foi identificado como artefato derivado do Boundary 8 e passou a ser explicitamente ignorado pelo Git.

Nenhuma conversão integral, dimensão, fato, Link Table definitiva, indicador ou dashboard foi iniciada durante a Fase I.

---

## Fase II — Conversão

Status:

**CONCLUÍDA — T01–T06 PASS**

### Evidência local do smoke — 07/10/2026

Arquivos localizados de forma única sob `BASE`:

- `RDPB1702.dbc`;
- `LTPB1712.dbc`;
- `STPB1912.dbc`.

Resultados do conversor definitivo:

- `RDPB1702.dbc`: **PASS — 13.912 registros / 113 campos**;
- `LTPB1712.dbc`: **PASS — 1.033 registros / 28 campos**;
- `STPB1912.dbc`: **PASS — 6.438 registros / 208 campos**.

Manifesto do smoke:

- 3 linhas;
- 3/3 com `status=PASS`;
- 3/3 hashes SHA-256 de entrada válidos;
- 3/3 hashes SHA-256 de saída válidos;
- 3/3 assinaturas de schema SHA-256 válidas;
- hashes de entrada recalculados: **3/3 MATCH**;
- hashes de saída recalculados: **3/3 MATCH**.

O layout local real mantém os DBCs em uma raiz compartilhada `BASE/DBC`. O conversor foi ajustado para selecionar recursivamente apenas a família indicada por `--source-family`, permitindo executar RD, LT e ST diretamente dessa raiz sem duplicar os 108 arquivos. Para a carga integral será usado `--expected-files 36` como proteção contra lote incompleto.

### Conversão integral — evidência local de 07/10/2026

Documento de evidência:

`docs/discovery/phase-2-conversion-evidence-2026-10-07.md`

Resultado:

- RD: **36/36 PASS — 566.672 registros — 113 campos em 36/36**;
- LT: **36/36 PASS — 35.518 registros — 28 campos em 36/36**;
- ST: **36/36 PASS — 220.390 registros**;
- ST: **201 campos em 35/36**;
- `STPB1912.dbc`: **208 campos**;
- manifesto de conversão: **108 linhas / 108 PASS**.

Gates reconciliados:

- T01: **PASS**;
- T03: **PASS**;
- T04: **PASS**;
- T05: **PASS**;
- T06: **PASS**.

### Fechamento de T02 — evidência local de 07/10/2026

A reconciliação final foi executada com `tools/readiness_reconcile_hashes.py` contra o manifesto de aquisição validado.

Resultado:

- itens no manifesto: **108**;
- DBCs locais: **108**;
- matched: **108**;
- missing: **0**;
- duplicates: **0**;
- hash mismatch: **0**;
- size mismatch: **0**;
- extras: **0**;
- manifest issues: **0**;
- `VERDICT=PASS`.

Com isso, T01–T06 estão **PASS** e a Fase II está encerrada.

---

## Fase atual

**FASE III — EXTRAÇÃO**

Status:

**IN PROGRESS — III-A/III-B/III-C1/III-C2 PASS; CID-10 T28 PASS; REFERÊNCIAS RESTANTES PENDENTES**

Documento operacional:

`docs/discovery/phase-3-health-staging-implementation-2026-10-07.md`

Implementado no repositório:

1. carga explícita dos 36 CSVs SIH/RD para `SRC_SIH_RD.qvd`;
2. carga explícita dos 36 CSVs CNES/LT para `SRC_CNES_LT.qvd`;
3. carga explícita dos 36 CSVs CNES/ST para `SRC_CNES_ST.qvd`;
4. metadados técnicos de arquivo, família, competência e caminho;
5. reconciliação de quantidade de arquivos, linhas, 36 competências e competência interna × nome do arquivo;
6. checkpoint parcial `_CHECKPOINT_EXTRACAO_SAUDE.csv` emitido somente após PASS das três famílias.

Critérios embutidos no script:

- RD = 36 arquivos / 566.672 registros;
- LT = 36 arquivos / 35.518 registros;
- ST = 36 arquivos / 220.390 registros;
- 36 competências distintas por família;
- 0 divergências de competência.

Primeira execução local do III-A: RD carregou 36/36 arquivos e 566.672 registros, mas a checagem técnica de competência marcou 566.672 divergências e interrompeu o script antes do primeiro QVD. O log demonstrou que a falha estava na comparação numérica aplicada a campos carregados com `Text(...)`, não nos dados nem nas contagens. A checagem foi corrigida para comparação textual normalizada.

Segunda execução local: **PASS**. Foram gerados `SRC_SIH_RD.qvd`, `SRC_CNES_LT.qvd`, `SRC_CNES_ST.qvd` e `_CHECKPOINT_EXTRACAO_SAUDE.csv`, com `PASS_PARTIAL`, RD=566.672, LT=35.518 e ST=220.390.

A inspeção física dos arquivos IBGE 2017–2019 foi concluída. Os três arquivos usam a planilha `Municípios`, título na linha 1, cabeçalho na linha 2 e as cinco primeiras colunas úteis `UF`, `COD. UF`, `COD. MUNIC`, `NOME DO MUNICÍPIO` e `POPULAÇÃO ESTIMADA`. O Checkpoint III-B foi implementado em `EXTRACAO/ext_main.qvs` para gerar `SRC_IBGE_POPULACAO.qvd` e `_CHECKPOINT_EXTRACAO_IBGE.csv`.

Primeiro reload local do III-B: o Checkpoint III-A permaneceu PASS, mas o carregamento IBGE 2017 falhou em `Table Not Found`. O log registrou a tabela como `MunicÃ­pios$`, embora a inspeção física tenha confirmado `Municípios`. A falha foi isolada na interpretação de literal UTF-8 acentuado do include `.qvs` pelo QlikView 12. O script foi corrigido para construir em runtime, com `Chr(...)`, o nome da planilha e os cabeçalhos acentuados usados na validação.

Segundo reload local do III-B: o BIFF passou a abrir corretamente, 223 registros PB foram carregados, mas o total 2017 ficou em 4.229.525. Inspeção do XLS encontrou `Livramento=7386(4)` e `Taperoá=15276(5)`; a normalização anterior incorporava os dígitos das notas. Considerando somente o valor anterior ao primeiro parêntese, o total reconciliou exatamente em 4.025.558. O script foi corrigido para remover a anotação parentética antes da conversão numérica.

Terceiro reload local do III-B: **PASS**. Foram gerados `SRC_IBGE_POPULACAO.qvd` e `_CHECKPOINT_EXTRACAO_IBGE.csv`, com `PASS_PARTIAL`, 669 linhas, 223 municípios em 2017/2018/2019 e totais 4.025.558 / 3.996.496 / 4.018.127.

O inventário local de `BASE/REFERENCIAS` confirmou diretório existente e sem arquivos. O Checkpoint III-C1 materializou de forma reproduzível os domínios normativos de Caráter de Atendimento e Motivo de Saída/Permanência. A execução local retornou 6 e 21 linhas, respectivamente, `VERDICT=PASS`, leitura UTF-8 correta e os dois hashes SHA-256 reconciliados com `MATCH=True`.

A integração Qlik do III-C1 foi implementada em `EXTRACAO/ext_main.qvs`. No primeiro reload, Caráter de Atendimento passou integralmente e gerou `REF_CARATER_ATENDIMENTO.qvd`, com cobertura 566.672/566.672 e 0 unmatched. Motivo de Saída/Permanência carregou a referência de 21 linhas, mas encontrou 124.233 linhas RD sem referência e interrompeu controladamente.

A inspeção integral do RD encontrou 26 códigos `COBRANCA` distintos. A Portaria SAS/MS nº 384/2010 demonstra que a referência aplicável pós-2010 exclui `1.3` e `1.7`, mantém `1.9`, altera internação domiciliar para `3.2` e inclui `6.1`–`6.7`. O materializador e o Qlik foram corrigidos para o domínio oficial completo de 28 códigos; `32` e `67` permanecem na referência embora não tenham sido observados no período.

A rematerialização corrigida retornou `CARATER_ROWS=6`, `MOTIVO_ROWS=28`, `VERDICT=PASS` e hashes 2/2 `MATCH=True`. O reload subsequente do `EXT.qvw` gerou `REF_CARATER_ATENDIMENTO.qvd`, `REF_MOTIVO_SAIDA.qvd` e `_CHECKPOINT_EXTRACAO_REFERENCIAS_NORMATIVAS.csv`. O checkpoint registrou `PASS_PARTIAL`, Caráter=6 com 0 unmatched e Motivo=28 com 0 unmatched.

**CHECKPOINT III-C1: PASS.**

O Checkpoint III-C2 — CID-10 foi aberto com `tools/profile_cid10_diag_princ.py`. O C2.1 executou **PASS** sobre os 36 CSVs RD / 566.672 linhas: 5.480 códigos brutos distintos, 0 vazios e largura física 4 em todas as linhas. Foram observadas 506.249 linhas alfanuméricas uppercase e 60.423 linhas com whitespace, correspondendo a 4.954 e 526 códigos distintos, respectivamente. O perfil foi persistido localmente com SHA-256 `1d185cd4780d4c688a8ceeaf8b14cdaa359f040a1590b710a8d9daeaf4870dbc`.

A documentação oficial CMD/DATASUS também define o código de diagnóstico CID-10 como alfanumérico de tamanho 4. O C2.2 executou **PASS**: as 60.423 linhas com whitespace usam exclusivamente um espaço ASCII `U+0020` no final; não há whitespace inicial/interno; `strip()` mantém 5.480 códigos distintos e gera 0 colisões. Isso sustenta `Trim(DIAG_PRINC)` como candidato de remoção de padding técnico, mas a regra permanece pendente até o lookup oficial.

O C2.3 executou **PASS**: foram encontrados 36 pacotes `TabelaUnificada_*.zip`, um para cada competência entre 2017-01 e 2019-12, sem lacunas nem versões duplicadas.

A documentação oficial do CMD registra CID-10 versão 2008, enquanto a validação operacional considera competência. O C2.4 executou **PASS** com materialização de 201701, 201801, 201901 e 201912. O `tb_cid_layout.txt` permaneceu idêntico nas quatro competências. Já `tb_cid.txt` apresentou dois hashes: 201701/201801/201901 idênticos com 12.450 linhas, enquanto 201912 possui 14.230 linhas e hash distinto. Logo, conteúdo CID mudou dentro de 2019 e não é seguro assumir uma referência física única para todo o período.

O C2.5 executou **PASS**. O `tb_cid.txt` possui linhas fixas de 111 bytes, decodificáveis em `cp1252`; o layout estável define `CO_CID` nas posições 1–4 e `NO_CID` nas posições 5–104. Entre 201901 e 201912 foram adicionadas 1.780 linhas e removidas 0. Os exemplos adicionados incluem categorias CID de 3 caracteres com espaço ASCII de padding na quarta posição, como `A00 `, `A01 ` e `A02 `, coexistindo com subcategorias de 4 caracteres. Essa evidência conecta a expansão de 201912 aos 60.423 registros RD com padding já medidos no C2.2.

O C2.6 executou **PASS**. A referência 201901 possui 12.450 chaves; 201912 possui 14.230. Foram adicionadas 1.780 chaves, removidas 0 e não houve alteração de descrição ou payload nas 12.450 compartilhadas. 201901 deixa 1.901 linhas RD / 349 códigos normalizados sem cobertura; todos são códigos de 3 caracteres e todos existem em 201912. A referência 201912 cobre 566.672/566.672 registros RD, tanto na chave física quanto após remoção exclusiva do padding à direita.

Foi confirmada a decisão de usar **201912 como referência CID-10 descritiva estática/superset** no Data Mart inicial. Essa decisão fornece código/descrição e não afirma vigência mensal. A normalização aprovada remove somente espaço ASCII `U+0020` à direita.

O C2.7 foi reexecutado com **PASS**: `REFERENCE_COMPETENCE=201912`, 14.230 linhas, 14.230 códigos distintos, distribuição 2.042/12.188, cobertura-evidência de 566.672 RD e decisão `STATIC_DESCRIPTIVE_SUPERSET`. O CSV final `cid10_referencia.csv` foi reconciliado contra o manifesto com `MATCH=True` e SHA-256 `da541adc1efbdb4ac04c555cf1e008967fd053fb6368ff443fb10a476757025f`.

O C2.8 foi implementado em `EXTRACAO/ext_main.qvs`: carga da referência final, validação estrutural, `RTrim(DIAG_PRINC)` como remoção do padding técnico aprovado, reconciliação contra 566.672 RD, geração de `REF_CID10.qvd` e checkpoint parcial.

O primeiro reload C2.8 passou todos os gates estruturais da referência, mas encontrou 9.093 linhas RD sem match no QVD e interrompeu controladamente. O C2.8b confirmou que os 128 códigos distintos envolvidos eram texto no QVD (`IsNum=0`, `IsText=-1`). O diagnóstico C2.8c, executado em 08/10/2026, comprovou que os mesmos 128 códigos / 9.093 registros encontram a referência tanto por `Text(DIAG_PRINC)` quanto por `Text(RTrim(Text(DIAG_PRINC)))`, enquanto a expressão original `RTrim(Text(DIAG_PRINC))` falha. A correção C2.8d altera somente a expressão da comparação para `Text(RTrim(Text(DIAG_PRINC)))`, mantendo a normalização aprovada e os gates fail-closed. O reload local de **08/10/2026 10:44:15** confirmou o **C2.8d PASS**: `REF_CID10.qvd` gerado (945.638 bytes) e `_CHECKPOINT_EXTRACAO_CID10.csv` gerado com `stage=EXTRACAO_CID10`, `status=PASS_PARTIAL`, `cid10_rows=14230`, `cid10_distinct_codes=14230`, `cid10_length_3=2042`, `cid10_length_4=12188`, `rd_rows=566672` e `cid10_unmatched_rd_rows=0`. O **Checkpoint III-C2 — CID-10** está **CONCLUÍDO — PASS**; a reconciliação de cobertura `DIAG_PRINC × CID-10` atende ao gate T28 (0 exceções observadas). A Fase III permanece **IN PROGRESS**, sem marcador de conclusão final. O trabalho avançou posteriormente para **SIGTAP / PROC_REA por competência (T27)**, já registrado como PASS no checkpoint III-C3 abaixo; CNES tipo/leito (T29), ponte municipal e estabelecimento histórico permanecem pendentes.

O **Checkpoint III-C3 — SIGTAP / PROC_REA** foi aberto em 08/10/2026, com escopo inicial **C3.1 — perfil empírico dos 36 CSVs SIH/RD**. Foi implementado `tools/profile_proc_rea.py`, com validação fail-closed de 36 arquivos/competências, 566.672 linhas, análise textual dos códigos brutos de `PROC_REA`, comprimentos, formatos, zeros iniciais e distribuição mensal. O script gera dois perfis CSV locais e um resumo JSON com hashes em `BASE/REFERENCIAS` (não versionados). **C3.1 PASS em 08/10/2026:** 36 arquivos, 566.672 RD e 36 competências; 1.249 códigos `PROC_REA` distintos, 0 vazios, 0 formatos inválidos, 566.672 códigos com 10 dígitos ASCII e com zero inicial. Saídas: `proc_rea_raw_profile.csv` (1.249 linhas; SHA-256 `24b41c3819e1eb704eeb03d54f882879190fe64886a9f1088de99279c61dac80`) e `proc_rea_monthly_profile.csv` (36 linhas; SHA-256 `1ba3ced5c99b185bdf3c70d3eb5f64c08214a9e623487923b157d8856170572d`), ambos `HashMatch=True`. **Naquele checkpoint, T27 ainda não havia sido avaliado.** O C3.2 foi implementado em `tools/inspect_sigtap_procedure_sample.py` para inspecionar uma amostra restrita (201701, 201801, 201901, 201912), baixar ZIPs apenas temporariamente, validar CRC, enumerar membros e identificar candidatos a dados/layout de procedimento sem presumir campos ou cobertura. **C3.2 PASS em 08/10/2026**: os quatro ZIPs oficiais foram inspecionados com verificação ZIP/CRC, contendo 87 arquivos cada, 18 DATA e 17 LAYOUT candidatos por pacote (348 membros/140 candidatos no total). Nas quatro competências, `tb_procedimento.txt` e `tb_procedimento_layout.txt` foram identificados; a prévia do layout mostra `CO_PROCEDIMENTO` nas posições 1–10 (10 caracteres). CSVs locais do inventário: 348 e 140 linhas, com hashes SHA-256 registrados em `sigtap_procedure_sample_summary.json`; reconciliação externa desses hashes ainda não apresentada. **C3.3a PASS em 08/10/2026**: 201701/201801/201901/201912 apresentaram respectivamente 4.542/4.587/4.609/4.624 procedimentos físicos e chaves distintas; 16 campos, largura de 330 bytes, 0 chaves inválidas, 0 comprimentos inválidos, 0 duplicidades e layout idêntico na amostra (`LAYOUT_DISTINCT_HASHES=1`). Campos físicos confirmados em `tb_procedimento_layout.txt`: `CO_PROCEDIMENTO` 1–10, `NO_PROCEDIMENTO` 11–260 e `DT_COMPETENCIA` 325–330; as descrições de grupo/subgrupo/forma de organização requerem fonte oficial adicional. **C3.3a.1 PASS em 08/10/2026**: piloto `PROC_REA + competência` contra `CO_PROCEDIMENTO + DT_COMPETENCIA` nas quatro competências 201701/201801/201901/201912 cobriu **59.365/59.365 RD**, com 0 unmatched e 0 pares código/mês sem referência. Distribuição mensal: 14.726 / 14.501 / 15.155 / 14.983 registros, todos cobertos. **C3.3b.1 PASS em 08/10/2026**: 36 competências SIGTAP materializadas, 4 amostras reutilizadas, 32 pacotes oficiais adicionais, 165.203 registros de procedimentos somados por mês e layout físico idêntico de 16 campos/330 bytes (SHA-256 `75641d897c8205d3d2e94ddb96431d51bf7a9ed5871ba0645484715cffffb88a`). `sigtap_procedure_history_inventory.csv` (36 linhas) conferido com SHA-256 `23eb6942d69c8c81f30bde5eded896cad2881b64c77cacd1b80b3bb57ad2af8a`, `HISTORY_INVENTORY_SHA_MATCH=True`. Nenhum código duplicado ou competência interna inválida foi reportado. **C3.3b.2 PASS e T27 CONCLUÍDO em 08/10/2026**: os 566.672/566.672 registros RD encontraram `PROC_REA` na referência SIGTAP da competência correspondente (36 meses), com 0 unmatched, 0 pares código/competência não encontrados e 21.031 pares código+competência observados no RD. Os CSVs de cobertura mensal (36 linhas) e exceções (0 linhas) foram reconciliados com `HashMatch=True`, e o manifesto final registrou `T27_GATE=PASS`. **C3.4a ESTRUTURA/HASH PASS em 08/10/2026**: os 36 meses geraram CSV intermediário com 165.203 registros e 165.203 chaves operacionais textuais únicas `YYYYMM|CO_PROCEDIMENTO`; hash SHA-256 `75237997a26bea243b101af1bd19e04e3f4905fb237ac9d227db860cbd14b482` confirmado com `CSV_SHA_MATCH=True`. Existem 48.749 descrições com caracteres não ASCII. O manifesto permaneceu corretamente em `STRUCTURE_PASS_ENCODING_REVIEW`: o primeiro conjunto de 12 amostras revelou apenas dois nomes repetidos com acentos legíveis (`ORIENTAÇÃO`, `ATENÇÃO BÁSICA`), evidência insuficiente para validação textual diversificada. **C3.4a.1 PASS em 08/10/2026**: auditoria read-only confirmou 165.203 referências, 36 competências, 165.203 chaves distintas, 48.749 descrições não ASCII, CSV SHA-256 reconciliado e `SUSPECT_MOJIBAKE_MARKERS=0`. Foram apresentados 16 nomes diversificados e legíveis com cedilha, til, acento agudo e circunflexo em 201701/201801/201901/201912. **Decisão operacional:** `cp1252` aprovado para a decodificação local de `NO_PROCEDIMENTO`, sem atribuir ao DATASUS uma declaração oficial de encoding. **C3.4b IMPLEMENTADO / RELOAD QLIK LOCAL PENDENTE**: o script versionado `EXTRACAO/ext_main.qvs` agora carrega o CSV SIGTAP, verifica 165.203 registros e chaves código+competência, 36 meses, campos textuais válidos e cobertura 566.672/566.672 RD, exigindo 0 unmatched para gerar `REF_SIGTAP.qvd` e `_CHECKPOINT_EXTRACAO_SIGTAP.csv` com `PASS_PARTIAL`. **Nenhum PASS de C3.4b ou criação do QVD foi observado ainda; Fase III permanece parcial.** Documento operacional: `docs/discovery/phase-3-sigtap-proc-rea-implementation-2026-10-08.md`.


**Diagnóstico C3.4b.1 — 08/10/2026 12:38:44:** o reload QlikView 12 carregou 165.203 linhas da referência SIGTAP e confirmou 165.203 chaves compostas, 36 competências e 0 casos de competência/código/chave/descrição inválidos. O log `EXT.qvw.2026_10_08_12_38_28.log` mostrou interrupção na linha 1243 com `OR 0 <> 0` / `Comando desconhecido`: o `IF` que agrega os quatro contadores em `EXTRACAO/ext_main.qvs` foi quebrado em linhas, e o QlikView 12 interpretou `OR` isoladamente. A correção C3.4b.1 unificou a condição `IF ... THEN` em uma única linha, preservando os mesmos quatro testes e os gates fail-closed. **Correção implementada, aguardando reload local.** O passo ainda não chegou à validação dos 566.672 RD no QlikView nem produziu `REF_SIGTAP.qvd` ou `_CHECKPOINT_EXTRACAO_SIGTAP.csv`; não declarar C3.4b PASS ou Fase III concluída. T27 Python permanece PASS.


**Fechamento C3.4b — PASS em 08/10/2026 12:44:24:** após o merge da correção C3.4b.1 no `IF` do QlikView 12 (`PR #58`, commit `97cee2b62d39d5e28fe356a38ef29c4def64d057`), o reload local de `EXTRACAO/EXT.qvw` gerou `EXTRACAO/QVD/REF_SIGTAP.qvd` (**4.606.958 bytes**) e `EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_SIGTAP.csv` (**202 bytes**), ambos datados de 08/10/2026 12:44. O checkpoint exibido foi `08/10/2026 12:44:24;EXTRACAO_SIGTAP;PASS_PARTIAL;165203;165203;36;566672;0`. **C3.4b / III-C3 PASS** com 165.203 chaves SIGTAP por mês, 36 competências e nenhuma das 566.672 linhas RD sem correspondência no Qlik. O T27 Python continua PASS. Os dados/QVDs locais permanecem fora do Git.

**Próximo checkpoint III-C4 — CNES tipo/leito (T29):** o Boundary 4 mantém pendente materialização e comparação histórica das referências oficiais de `TP_LEITO` e `CODLEITO` para 2017–2019; o Boundary 7 exige medir cobertura `CODLEITO ↔ referência oficial` e registrar exceções (T29). Para iniciar sem inventar código, chave, descrição ou classificação, foi implementado `tools/profile_cnes_lt_bed_codes.py` como **C4.1 READ-ONLY / EXECUÇÃO LOCAL PENDENTE**. O script perfila os 36 CSVs CNES/LT, com 35.518 registros esperados, mantendo os códigos textuais brutos, inventariando pares tipo/código e competências, sem download externo, QVD, dimensão ou cobertura T29. A Fase III permanece `IN PROGRESS`.

**III-C4.1 — CNES/LT: PASS em 08/10/2026:** o perfil read-only local `tools/profile_cnes_lt_bed_codes.py` validou 36/36 CSVs e 35.518 registros CNES/LT, com 7 valores distintos de `TP_LEITO`, 57 de `CODLEITO` e 57 pares distintos. Ocorreram 0 campos exatamente vazios, 0 competências divergentes e 0 códigos `CODLEITO` associados a múltiplos valores observados de `TP_LEITO`. Em todas as 35.518 linhas, `CODLEITO` tem 2 dígitos ASCII; `TP_LEITO` tem comprimento 2 e foi classificado como contendo `WHITESPACE`. Essa classificação não autoriza descartar espaços nem deduzir hierarquia oficial. Janeiro–maio/2018 apresentaram 57 códigos por mês, enquanto os demais meses apresentaram 56; o código específico e sua dinâmica de presença ainda precisam ser inspecionados. Saídas: `cnes_lt_bed_code_monthly_profile.csv` (36 linhas, SHA-256 `73ddcfd5cc73342f7c2d75d4565f798b95c92e2fec0edb3f92b5d225fd698c34`) e `cnes_lt_bed_code_pair_profile.csv` (57 linhas, SHA-256 `4afe0741b1bf43434192e467a043a0bcb7f2a96e25214f92f47557531e238449`), ambos `HashMatch=True`. **III-C4.1a pendente**: conferir os valores brutos dos sete tipos, posição dos espaços e diferenças entre competências relevantes; **T29 NÃO AVALIADO**. A Fase III segue parcial e nenhuma referência CNES oficial/QVD novo foi gerado neste checkpoint.

**III-C4.1a — PASS na inspeção física restrita (08/10/2026):** os sete valores brutos de `TP_LEITO` são `"1 "`, `"2 "`, `"3 "`, `"4 "`, `"5 "`, `"6 "`, `"7 "`, cada um com espaço ASCII 32 no segundo caractere. Os sete tipos agrupam 15/13/16/2/2/5/4 códigos distintos `CODLEITO`, respectivamente. A comparação 201712→201801 mostrou `CODLEITO=70` adicionado; 201805→201806 mostrou `70` removido dos códigos observados. Isso é evidência de presença nos arquivos, **não vigência normativa**. O Portal CNES lista Dicionário de Dados e Tabelas de Domínio; Wiki CNES informa bases por competência a partir de 06/2017; ElastiCNES documenta distinção entre tipo, código e especialidade. **C4.2 fonte oficial histórica ainda não validada e T29 NÃO AVALIADO**. Próxima inspeção restrita: identificar `TP_LEITO` do `70` e meses de ocorrência, antes de definir chave de lookup ou alterar QVD.

**III-C4.2a — correspondência oficial pontual do código 70 (08/10/2026):** o `cnes_lt_bed_code_pair_profile.csv` local exibiu `TP_LEITO="7 "`, `CODLEITO=70`, primeira competência `201801`, última `201805`, cinco competências e cinco ocorrências, ou seja, uma por mês no intervalo. Na consulta histórica primária DATASUS/CNES `https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VComp=201712&VEstado=35&VMun=` consta, para São Paulo (UF 35) e competência **201712**, `HOSPITAL DIA → 70 FIBROSE CISTICA`. Consulta oficial adicional `201512` registra o mesmo par. Isso confirma a nomenclatura já antes de 2018, e **não** comprova criação/extinção do código na transição mensal da PB. CONASS apresenta nomenclatura equivalente como evidência secundária. **C4.2b PENDENTE:** validar série histórica/referência oficial completa de 57 códigos; **T29 NÃO AVALIADO**. Não modificar CSV LT, regra de chave, dimensões, QVD ou Fase III.

**III-C4.2b.1 — piloto de sondagem histórica oficial IMPLEMENTADO / EXECUÇÃO LOCAL PENDENTE:** a pesquisa web encontrou consulta CNES/DATASUS de indicadores de leitos por competência e catálogos de domínio anunciados no Portal CNES (downloads com templates JavaScript, sem versão histórica de arquivo estático verificada). Uma consulta de indicador apresenta somente tipos/códigos com registros, não necessariamente o universo de códigos válidos. A tabela secundária CONASS enumera pares de `codleito` repetidos sob tipos distintos, alertando contra a suposição de unicidade global de `CODLEITO` feita a partir do perfil PB. Foi adicionado `tools/probe_cnes_leito_historical_indicators.py` para sondagem restrita de 5 HTMLs do indicador oficial nacional em 201712, 201801, 201805, 201806 e 201912, com SHA-256 de bytes brutos, sinais de conteúdo, competência selecionada e auditoria de falhas. Os resultados só serão considerados após execução/inspeção local e **não constituem referência normativa histórica**. **C4.2b domínio histórico de 57 códigos / T29 continuam PENDENTES**, sem criação de QVD, fatos ou dimensões.

**III-C4.2b.1 — captura local concluída / REVIEW (08/10/2026):** a sonda oficial consultou cinco competências (201712/201801/201805/201806/201912), capturou 5/5 HTMLs CNES, byte sizes 53.009/53.008/53.007/53.006/53.008 e decodificação `cp1252`. Todos possuem conteúdo indicativo de CNES/leitos, Hospital Dia e descrição do código 70; em todos `COMPETENCE_SELECTED=False`. Essa falha do sinal heurístico **não comprova** que o servidor ignorou `VComp`, nem que mudou historicamente. O script retornou `SOURCE_INSPECTION_REQUIRED`, `HISTORICAL_DOMAIN_REFERENCE=NOT_APPROVED` e `T29_COVERAGE=NOT_EVALUATED`. Foi implementado **C4.2b.2 / execução local pendente** em `tools/audit_cnes_leito_historical_html.py`: auditoria read-only dos cinco HTMLs com verificação de SHA/tamanho, inspeção de controle `VComp` e fingerprints independentes de HTML/texto/tabela de leitos. Nenhum QVD nem domínio oficial criado; Fase III continua parcial.

**III-C4.2b.2 — auditoria offline executada (08/10/2026):** 5/5 HTMLs com hashes e tamanhos reconciliados (`INTEGRITY_FAILURES=0`), cinco SHA-256 distintos de bytes, cinco de texto visível e cinco de conteúdo textual heurístico iniciado em `CIRÚRGICO`. O mês solicitado aparece no HTML de cada página, mas não como competência selecionada de forma explícita (`EXPLICIT_COMPETENCES=0`). **Captura íntegra PASS; validade temporal, significado semântico dos diffs e domínio normativo REVIEW**. Para investigar as diferenças sem baixar novos arquivos, foi implementado C4.2b.3 em `tools/compare_cnes_leito_html_table_rows.py` (execução local pendente), que relê os cinco HTMLs e compara linhas de tabela, células, ecos dos meses e exemplos de alterações. A Fase III permanece parcial; **T29 NÃO AVALIADO**, sem QVDs ou modelagem novos.

**III-C4.2b.3 — comparação estrutural executada (08/10/2026):** o usuário executou o script offline com sucesso: 5/5 HTMLs íntegros, **77 linhas tabulares e 1 linha do código `70`** em cada consulta. Linhas diferentes por transição solicitada 201712→201801:65, 201801→201805:67, 201805→201806:61, 201806→201912:68, sem redução após neutralizar ecos `YYYYMM`. Nos exemplos fornecidos, códigos/descrições não mudaram; mudaram as células de quantidades dos indicadores. Isso é compatível com variação operacional, **não** prova estabilidade do domínio histórico nem aplicação de `VComp` (`EXPLICIT_COMPETENCES` anteriormente 0/5). **C4.2b.3a implementado, reexecução local pendente:** o mesmo script de comparação agora distingue mudanças dos pares código/descrição (duas primeiras células) e mudanças de outras células, verificando multiconjuntos de rótulos em cinco amostras; não preserva cabeçalhos de tipo, não mede T29 e não cria QVD. Fase III continua parcial.

**III-C4.2b.3a — PASS AMOSTRAL na comparação de rótulos (08/10/2026):** o usuário executou novamente o comparador offline de cinco HTMLs CNES, todos íntegros. Cada um apresentou 77 linhas de tabela, 65 pares distintos de `(código, descrição)` nos `<tr>` filtrados e zero códigos duplicados nesse subconjunto. Nas quatro transições 201712→201801, 201801→201805, 201805→201806 e 201806→201912, ocorreram **0 pares adicionados / 0 removidos**; porém 61, 63, 58 e 64 linhas com rótulos iguais tiveram alterações nas outras células (compatíveis com variações de quantitativos). **Não** conclui que o portal aplicou as competências (0/5 controles explícitos), que a nomenclatura permaneceu normativa nos 36 meses ou que o tipo/grupo foi preservado: o extrator descarta cabeçalhos de tipo. **C4.2c agora prioriza obter e inspecionar `Tabelas de Domínio` e `Dicionário de Dados do SCNES` no Portal CNES oficial** (link de download/versionamento 2017–2019 ainda não demonstrado; página pública usa placeholders JS), sem mais scripts de indicadores nesta rodada. **T29 NÃO AVALIADO**, nenhum QVD/modelagem alterado, Fase III parcial.

**III-C4.2c (08/10/2026):** recebidos e inspecionados dois arquivos CNES: `SCNES_DOMINIOS.XLS` (SHA-256 `ae3f678f1f2307d759412c735f79bf1ace5a91410261f4050dc6e86c671c2af4`; 56 abas; `LEITOS` = 66 códigos únicos; `TIPOS DE LEITOS` = 7 tipos únicos) e `DICIONARIO_DE_DADOS.docx` (SHA-256 `086bfcbdbf47ea13d89542a21128c691367c0560a9f6bf8a2319e8a6eadb973b`). O dicionário define `NFCES001/TB_LEITO` com `CO_LEITO`, `DS_LEITO`, `TP_LEITO` e `NFCES028/TB_ATRIBUTO` com indicador `006`. As abas XLS fornecem listas independentes, sem associação por registro entre código e tipo, e não provam vigência histórica em 2017–2019. `tools/audit_cnes_official_domains.py` implementado para checar cobertura de códigos/tipos de 57 pares / 35.518 LT. Em 08/10/2026, sua execução local foi comprovada (C4.2c.1 PASS de cobertura independente: 57/57 pares, 35.518/35.518 registros, 0 exceções, `CODE_AND_TYPE_COVERAGE_PROVISIONAL`, exit code 0, três hashes originais reconciliados). **A associação normativa `TP_LEITO↔CODLEITO` e a vigência 2017–2019 NÃO foram comprovadas.** C4.2c.2 passa a ser o próximo checkpoint; `T29` permanece NÃO APROVADO e nenhuma referência QVD foi gerada. Evidência detalhada em `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`. **C4.2c.2a — descoberta oficial (08/10/2026):** documentação CNESNet confirmou que a consulta pública de leitos apresenta tipo, código e descrição por competência; página oficial agregada apresentou sete cabeçalhos de tipo com códigos/descrições agrupados, mas sem comprovação da competência efetivamente aplicada no conjunto histórico. A Base de Dados por competência começa em 06/2017, conforme Portal CNES; a existência de `NFCES001/TB_LEITO` em pacote público e a cobertura 201701–201705 ainda não foram verificadas. Próximo passo: inspeção de **um dos cinco HTMLs já capturados** para preservar vínculo cabeçalho→código antes de qualquer parser/carga. **T29 segue não aprovado**, nenhum QVD ou arquitetura alterados. **C4.2c.2b (08/10/2026):** a inspeção de `CNES_Leitos_Indicadores_201712_UF00.html` (53.009 bytes, SHA-256 `bc674e4e244701aa0f919ddac889290d937767cf10c7a1f58e40577134a62617`) comprovou 65 links de detalhe com `VCod_Leito+VTipo_Leito+VComp`, sete cabeçalhos de grupos e 65 pares únicos, 0 divergências entre código da linha e link; grupo `HOSPITAL DIA`, `70`, tipo `7` está explícito. Os 65 links ecoam `VComp=201712`, mas o seletor não confirma a competência aplicada. Novo auditor offline `tools/audit_cnes_grouped_leito_links.py` versionado na `main` para confrontar cinco HTMLs existentes e 57 pares PB. **Execução local em 08/10/2026: REVIEW_REQUIRED** (exit 2): cinco HTMLs com 65 pares cada; apenas **56/57 pares PB** coincidiram por captura; o par PB **tipo 3/código 66** está ausente nas cinco, enquanto o HTML coloca `66 — UNIDADE ISOLAMENTO` sob CLÍNICO, com `VTipo_Leito=2`. A tabela secundária CONASS classifica 66 sob tipo 3/COMPLEMENTAR; divergência entre fontes segue sem resolução normativa histórica. O auditor emitiu 25 ocorrências de erro repetidas (1 HEADERS_MISMATCH + 4 discrepâncias por nome de grupo por captura); a causa exata das quatro discrepâncias nominais exige inspeção dos rótulos originais antes de ajuste de parser. **T29 continua NÃO APROVADO**, sem QVDs, alteração dimensional nem edição das fontes. A evidência detalhada está em `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`. **C4.2c.2c (08/10/2026):** diagnóstico local esclareceu que as 25 ocorrências de erro foram diferenças nominais em duas categorias (`SCNES: OBSTETRICOS/PEDIATRICOS` vs `HTML: OBSTETRICO/PEDIATRICO`) repetidas cinco vezes. O par da PB `TP_LEITO=3 + CODLEITO=66` corresponde a **1.480 linhas em 36/36 competências (201701–201912)**. Outras páginas do próprio CNESNet exibem `66 — UNIDADE ISOLAMENTO` em COMPLEMENTAR, enquanto o indicador agregado o apresenta em CLÍNICO; a classificação histórica normativa permanece não resolvida. O auditor `tools/audit_cnes_grouped_leito_links.py` foi corrigido com somente dois aliases de nome, condicionados ao tipo e ao rótulo exato, e aprimorado para quantificar linhas de PB afetadas. **Nova execução local pendente; REVIEW_REQUIRED e T29 NÃO APROVADO**, sem transformação, QVD ou mudança de modelagem.

**III-C4.2c.2c/d — reexecução local e evidência histórica do código 66 (08/10/2026):** auditor `tools/audit_cnes_grouped_leito_links.py` após ajuste de aliases retornou cinco capturas com `65/65` links/pares, `issues=0`, `PB_MATCHED=56/57` e **1.480/35.518 registros PB no único par não correspondido `TP_LEITO=3/CODLEITO=66`**. Como efeito, 34.038/35.518 registros estão nos 56 pares coincidentes com os indicadores, mas T29 permanece `REVIEW_REQUIRED`. Pesquisa externa identificou **documentação municipal oficial com fonte SCNES 2017** agrupando `66 — UNIDADE ISOLAMENTO` em **COMPLEMENTAR**, e **Nota Técnica SEI/MS 0012300247, impressa 02/12/2019**, cujo texto indexado lista `66 | UNIDADE ISOLAMENTO | Complementar | Portaria SAS/MS 511/2000 | Ativo`. A Nota Técnica **ainda não teve seus bytes originais obtidos/inspecionados** (timeout no portal); registrar URL e ressalva antes de aceitação. Módulo CNESNet de estabelecimento também lista 66 em COMPLEMENTAR, em conflito com o indicador agregado que exibe `VTipo_Leito=2`. Não há prova de classificação normativa completa para 57 pares × 36 competências, nem de aplicação efetiva do mês do link. **Sem alteração de dados, modelo ou QVD; Fase III IN PROGRESS, T29 NÃO APROVADO.** Próximo gate: obter a Nota Técnica integral ou outra referência oficial versionada contendo os 57 pares, conferir assinaturas/proveniência/data e medir cobertura por competência quando justificável. Evidências e URLs: `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`.


**III-C4.2c.2e — Nota Técnica nº 32/2019 integral recebida e referência textual implementada (08/10/2026):** PDF original `Nota Técnica  32-2019 Leitos.pdf`, 8 páginas, 193.268 bytes, SHA-256 `43de32e91b9ed2611bacde8f4cea60576cb162017fa4db69797dd177c4f7632e`. Trata-se da **Tabela de Leitos Setembro/2019** anexa à Nota Técnica CGSI/DRAC/SAES/MS, SEI `0012300247`, assinada eletronicamente conforme declarado em 29/11/2019 (código CRC `25B0C110`, autenticação SEI online não efetuada). O anexo apresenta **65 códigos/leitos distintos**, todos `Ativo`, associados textualmente aos sete tipos: 17/15/18/2/2/5/6; o cruzamento dos nomes com `SCNES_DOMINIOS.XLS` fundamenta a codificação de tipos `1–7`. O par **`3/66 — UNIDADE ISOLAMENTO / COMPLEMENTAR`** consta na página 5, assim como **`7/70 — FIBROSE CISTICA / HOSPITAL-DIA`**. Comparado aos 65 links do HTML agregado CNESNet, há **somente um par exclusivo de cada lado (`3/66` no PDF, `2/66` no HTML)**, com os mesmos 65 códigos distintos; a aderência aos 57 pares da PB ainda é **inferida e requer execução local**. Transcrição controlada versionada como `docs/discovery/cnes-nt32-2019-codigos-leito.csv` (65 linhas, SHA-256 `c44d1075ed4b628106587f11cb38eab794d3573986e2079844738ad8c4b3f2c6`), com origem por página, **não constituindo domínio original oficial**. Implementado `tools/audit_cnes_nt32_2019_pairs.py` para verificação offline de três hashes e comparação composta `(TP_LEITO,CODLEITO)` com o perfil real da PB; **execução local pendente**. A Nota Técnica fornece apenas retrato de setembro/2019 e não prova vigência contínua em 2017–2019; **T29 integral NÃO APROVADO**, sem QVD ou mudança de modelagem. Registro analítico em `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`.

**III-C4.2c.2e.1 — auditor da Nota Técnica corrigido para checkout Windows (08/10/2026):** PDF original SHA-256 confirmado no PowerShell, mas primeira tentativa local parou ANTES da comparação de pares porque o CSV versionado no Git (LF, SHA-256 `c44d1075ed4b628106587f11cb38eab794d3573986e2079844738ad8c4b3f2c6`) sofreu conversão para CRLF no checkout Windows (SHA-256 `f9cc289b0a27557dd92b04bcfb558ac33d528900e6937549e71b373f36ccc363`, idêntico ao erro local). Script `tools/audit_cnes_nt32_2019_pairs.py` ajustado para aceitar **apenas ambos os hashes exatos do CSV textual** e manter hashes estritos únicos para PDF e perfil LT; registra no JSON o hash efetivo e os finais de linha. **Nenhum resultado de cobertura da Nota Técnica foi obtido nessa tentativa; reexecução local pendente.** T29 completo continua NÃO APROVADO e referência setembro/2019 não implica vigência normativa 2017–2019. Registro detalhado no relatório Fase III-C4.


**III-C4.2c.2e.2 — PASS da cobertura dos pares CNES/LT PB contra Nota Técnica nº 32/2019, anexo Setembro/2019 (08/10/2026):** após `git pull --ff-only origin main`, o usuário executou `tools/audit_cnes_nt32_2019_pairs.py` localmente com `AUDIT_EXIT_CODE=0`. **PDF, transcrição e perfil LT: INTEGRITY=PASS; 65 pares na Nota Técnica; 57/57 pares PB e 35.518/35.518 ocorrências LT correspondem à referência; 0 exceções**. `VERDICT=PASS_201909_SNAPSHOT_PAIR_COVERAGE_ONLY`. Checkout Windows CRLF da transcrição teve SHA-256 `f9cc289b0a27557dd92b04bcfb558ac33d528900e6937549e71b373f36ccc363` aprovado explicitamente pelo auditor. `3/66 — UNIDADE ISOLAMENTO / COMPLEMENTAR` está coberto; **não** corrige para `2/66` do indicador agregado CNESNet. **Limite: tabela retrato de setembro de 2019; vigência normativa e estabilidade de classificação/descrições para cada competência 201701–201912 NÃO VERIFICADAS**. Próxima descoberta C4.2c.3 restrita à referência histórica oficial `NFCES001/TB_LEITO`, atos de alteração e lacuna de disponibilidade antes de 06/2017. **T29 completo NÃO APROVADO**, Fase III `IN PROGRESS`; sem novo QVD/modelagem. Detalhes em `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`.


**III-C4.2c.3a — rota histórica de terminologia Leitos oficialmente documentada no RTS (08/10/2026):** a documentação do Ministério da Saúde em [Wiki RTS/Terminologias](https://wiki.saude.gov.br/RTS/index.php/Terminologias) lista **Leitos** em **Estabelecimento de Saúde**; [RTS_Portal](https://wiki.saude.gov.br/RTS/index.php/RTS_Portal) documenta **competências de exibição desde 01/2017**, versões independentes `MM/AAAA/letra` para terminologias que só mudam com ativação/inativação/alteração de termos, mantendo a última versão quando nada mudou. [Consultar_terminologias](https://wiki.saude.gov.br/RTS/index.php/Consultar_terminologias) menciona código/nome/status/vigência; [Download](https://wiki.saude.gov.br/RTS/index.php/Download) documenta **Nota Técnica por competência**, rebatizada como Relatório de Competência só em 08/2020. **O portal RTS `https://rts.saude.gov.br` retornou timeout no ambiente de pesquisa; ainda NÃO foi visualizada/baixada versão histórica concreta de Leitos, não foi provada a existência de `TB_LEITO` versionada em pacote nem validade mensal 2017–2019**. **Próximo gate C4.2c.3b: piloto manual READ-ONLY no RTS público** em 01/2017, seguido condicionalmente por 12/2017, 09/2019 e 12/2019, registrando nomes/versões reais da terminologia, códigos 66 e 70, campos/status/vigência e links autênticos. Não criar crawler nem download em massa antes de identificar a estrutura real; a cobertura 57/57 da Nota Técnica set/2019 continua **PASS limitado ao snapshot** e **T29 integral NÃO APROVADO**. Evidência operacional e protocolo: `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`.

**III-C4.2c.3b.1 — consulta visual RTS Leito 01/2017 (08/10/2026):** screenshot enviada pelo usuário mostra portal RTS acessível, competência **01/2017**, menu **Estabelecimentos de Saúde → Leitos**, título **LEITO** e resultado literal **`Nenhum resultado encontrado.`**, sem versão de terminologia, códigos ou vigência visíveis. Isto NÃO prova ausência da terminologia ou de leitos históricos; apenas consulta vazia na interface naquele contexto. **Próximo teste controlado: selecionar 09/2019 no mesmo portal e reabrir Leitos, confrontando com a Nota Técnica 32/2019 de setembro.** T29 integral segue NOT_APPROVED. Detalhes em `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`.



**III-C4.2c.3b.2 — limite real do RTS Leitos no ensaio manual (08/10/2026):** o usuário informou consultas anteriores a 10/2019 sem resultados. Captura em PDF de 2 páginas, 916.695 bytes, SHA-256 `a0fbe0a2dec3353e175ee74481ca872aa3d9ac1e2d944c6cd046bc38a31f6ba9`, comprova no portal RTS `COMPETÊNCIA 10/2019` e `LEITO - VERSÃO 10/2019A`, com status `ATIVO`, `Competência Inicial 10/2019` nas linhas, inclusive códigos 66 e 70; **não fornece tipo numérico explícito do código 66**. A disponibilidade desde 10/2019 no ensaio **não comprova criação dos códigos em 10/2019 nem vigência anterior**. A Portaria SAS/MS nº 298/2019 prevê reclassificação `77→94`, `74→95`, mas os efeitos dependem de versão do DATASUS (art. 8º). A Portaria SAES/MS nº 3.511/2025 dispõe sobre exclusão final e revoga a norma de 2019, portanto não declarar execução imediata em 03/2019. Próximo gate C4.2c.4 é investigação restrita de atos e implementação real de códigos/tipos da PB; **não repetir consultas RTS anteriores como se fossem prova temporal**. Mantidos `57/57 PASS_201909_SNAPSHOT_PAIR_COVERAGE_ONLY`, **T29 histórico NOT_APPROVED** e Fase III `IN_PROGRESS`. Documento técnico em `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`.

Fora de escopo nesta fase:

- dimensões;
- fatos;
- `LINK_ANALISE`;
- indicadores;
- dashboards.

O fluxo acadêmico permanece `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.

### Boundary de conversa

A primeira entrega está documentalmente encerrada.

Os Boundaries 3, 4, 5, 6, 7 e 8 estão concluídos e persistidos.

O fechamento do Boundary 8 está em:

`docs/discovery/boundary-8-readiness.md`

---

## Fluxo QlikView preservado

```text
BASE
  ↓
EXTRACAO / EXT.qvw
  ↓
QVD
  ↓
TRANSFORMACAO
  ↓
QVD
  ↓
PAINEL / QVW
```

Não substituir silenciosamente esse fluxo.
