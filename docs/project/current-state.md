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

**IN PROGRESS — CONTROLLED NO-GO**

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
- `tools/readiness_reconcile_hashes.ps1` adicionado para comparação 108/108.

Bloqueios restantes para GO:

- executar a reconciliação de hashes/tamanhos 108/108;
- validar o caminho de falha do tratamento de erro em batch, se mantido como gate;
- materializar/tratar explicitamente as referências auxiliares necessárias.

A implementação definitiva permanece bloqueada até o readiness emitir **GO**.

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

Estas pendências **não reabrem a primeira entrega**:

- concluir Boundary 8 — Readiness;
- executar `tools/readiness_check.ps1` no ambiente Windows real;
- validar a toolchain Python de conversão DBC em smoke test;
- validar leitura do CSV pelo QlikView e caminhos de `Must_Include`;
- validar execução `Qv.exe /r` e o mecanismo de sucesso/falha sem interação;
- reconciliar novamente os 108 DBCs antes do GO;
- validar protótipo mínimo da Link Table sem synthetic keys/circular references;
- medir cobertura real `PROC_REA × SIGTAP`;
- medir cobertura real `DIAG_PRINC × CID-10`;
- materializar/comparar a referência histórica de `TP_LEITO/CODLEITO`;
- resolver ou manter explicitamente sem preenchimento a lacuna de nome fantasia/razão social para 2017-01 a 2017-05;
- somente após GO implementar conversor, scripts, QVDs, fatos, dimensões e Link Table;
- construir e validar no mínimo 3 painéis;
- preparar Capítulos 3–5 e anexos para a entrega final.

---

## Próxima fase

**SAD — SUS PB — DATA ACQUISITION / QLIKVIEW IMPLEMENTATION DISCOVERY**

### Boundary atual

**BOUNDARY 8 — Readiness**

Status:

**IN PROGRESS — CONTROLLED NO-GO**

Próxima ação obrigatória:

1. executar `tools/readiness_check.ps1` no ambiente Windows que executará o QlikView;
2. corrigir os itens FAIL/BLOCKED retornados;
3. executar o smoke test QlikView com `tools/readiness_smoke.qvs`;
4. reconciliar os DBCs locais com o Boundary 3;
5. validar o protótipo mínimo da Link Table;
6. atualizar `docs/discovery/boundary-8-readiness.md`;
7. emitir **GO** ou manter **NO-GO** com blockers explícitos.

Nenhuma implementação definitiva deve começar antes do GO.

### Boundary de conversa

A primeira entrega está documentalmente encerrada.

Os Boundaries 3, 4, 5, 6 e 7 estão concluídos e persistidos.

O Boundary 8 está aberto e persistido em:

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
