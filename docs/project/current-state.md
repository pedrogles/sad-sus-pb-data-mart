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

**IN PROGRESS — III-A/III-B/III-C1 PASS; III-C2 C2.1–C2.7 PASS; C2.8 BLOQUEADO POR 9.093 UNMATCHED E EM DIAGNÓSTICO QLIK**

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

O primeiro reload C2.8 passou todos os gates estruturais da referência, mas encontrou 9.093 linhas RD sem match no QVD e interrompeu controladamente. Como o C2.6 sobre os CSVs convertidos havia obtido cobertura 100%, foi implementado um diagnóstico fail-closed que exporta os valores efetivos não cobertos de `SRC_SIH_RD.qvd`, com representação, comprimento, códigos ordinais e teste de `Upper(RTrim())`. Próximo gate: repetir o reload e inspecionar `_DIAGNOSTIC_CID10_QVD_UNMATCHED.csv` antes de alterar qualquer regra de normalização. SIGTAP procedimento, tipo/leito, ponte municipal e estabelecimento histórico permanecem pendentes.

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
