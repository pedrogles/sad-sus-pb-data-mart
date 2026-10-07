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
- a estratégia física multi-fato será fechada no Boundary 6.

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

- medir cobertura real `PROC_REA × SIGTAP`;
- medir cobertura real `DIAG_PRINC × CID-10`;
- materializar/comparar a referência histórica de `TP_LEITO/CODLEITO`;
- resolver ou manter explicitamente sem preenchimento a lacuna de nome fantasia/razão social para 2017-01 a 2017-05;
- definir a arquitetura física multi-fato no QlikView;
- definir a estratégia física de tolerância a schema para CNES/ST;
- definir convenções de chaves, aliases role-playing, QVD e QVW;
- definir testes de reconciliação e prevenção de synthetic keys/circular references;
- implementar as dimensões;
- implementar as fatos;
- construir e validar no mínimo 3 painéis;
- preparar Capítulos 3–5 e anexos para a entrega final.

---

## Próxima fase

**SAD — SUS PB — DATA ACQUISITION / QLIKVIEW IMPLEMENTATION DISCOVERY**

### Próximo boundary

**BOUNDARY 6 — Arquitetura física QlikView**

Objetivos imediatos:

1. comparar formalmente fato concatenada vs Link Table;
2. definir chaves associativas e convenções de nomes;
3. prevenir synthetic keys e circular references;
4. definir a organização física de QVD/QVW preservando o fluxo BASE → EXTRAÇÃO → TRANSFORMAÇÃO → PAINEL;
5. fechar a estratégia física para o drift de schema CNES/ST em 2019-12;
6. definir testes de reconciliação;
7. manter os três fatos e as oito dimensões acadêmicas sem alteração silenciosa.

Depois do Boundary 6:

1. BOUNDARY 7 — Plano de implementação;
2. BOUNDARY 8 — Readiness;
3. somente então iniciar implementação definitiva.

### Boundary de conversa

A primeira entrega está documentalmente encerrada.

Os Boundaries 3, 4 e 5 estão concluídos e persistidos.

O Boundary 6 deve começar lendo:

- `AGENTS.md`;
- este arquivo;
- `docs/discovery/boundary-3-full-dataset-validation.md`;
- `docs/discovery/boundary-4-auxiliary-references.md`;
- `docs/discovery/boundary-5-historization-role-playing.md`;
- documentação acadêmica aplicável.

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
