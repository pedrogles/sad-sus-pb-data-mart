# Current State

## Projeto

**SAD — Data Mart SUS PB**

Disciplina: Sistemas de Apoio à Decisão — 2026.2  
Ferramenta obrigatória: QlikView 12

## Etapa atual

**Dataset Validation / Modeling Discovery concluída.**

Veredito:

**APROVADO PARA MODELAGEM ACADÊMICA, COM RESSALVAS DOCUMENTADAS**

Documento canônico da etapa:

`docs/discovery/dataset-validation.md`

Próxima etapa:

**SAD — SUS PB — ACADEMIC MODELING / CHAPTERS 1–2**

A implementação definitiva no QlikView ainda não deve começar.

---

## Tema confirmado

Data Mart para análise descritiva e comparativa da demanda hospitalar, capacidade hospitalar e população do SUS na Paraíba.

---

## Fontes confirmadas

### SIH/SUS

Fonte de demanda hospitalar:

- arquivos RD / AIH Reduzida.

Checkpoints validados:

- `RDPB1701.dbc`;
- `RDPB1801.dbc`;
- `RDPB1901.dbc`.

### CNES

Fontes de capacidade e estabelecimento:

- LT / Leitos;
- ST / Estabelecimentos.

Checkpoints validados:

- `LTPB1701.dbc`;
- `LTPB1801.dbc`;
- `LTPB1901.dbc`;
- `STPB1701.dbc`;
- `STPB1801.dbc`;
- `STPB1901.dbc`.

### IBGE

Fonte populacional:

- estimativas populacionais municipais anuais.

Arquivos validados:

- 2017;
- 2018;
- 2019.

---

## Período confirmado

**2017–2019**

### RESSALVA

A série populacional possui mudança metodológica/projecional entre as publicações de 2017 e 2018.

Isso não impede o uso das estimativas anuais como denominadores dos indicadores de cada ano, mas a variação 2017→2018 não deve ser interpretada automaticamente como variação demográfica observada.

---

## Arquitetura dimensional aprovada

### Fatos

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`.

### Granularidades

#### FATO_INTERNACAO

**1 linha = 1 registro administrativo RD / AIH processada.**

Uma linha não equivale automaticamente a paciente ou episódio clínico único.

`IDENT=5` representa continuidade e não deve ser contado como nova internação.

#### FATO_CAPACIDADE_LEITO

**1 linha = estabelecimento × competência mensal × código/detalhamento de leito.**

Medidas de capacidade são semi-aditivas no tempo.

#### FATO_POPULACAO

**1 linha = município × ano.**

População é semi-aditiva no tempo.

---

## Dimensões aprovadas para o desenho acadêmico

- `DIM_TEMPO`;
- `DIM_MUNICIPIO`;
- `DIM_ESTABELECIMENTO`;
- `DIM_PROCEDIMENTO`;
- `DIM_DIAGNOSTICO`;
- `DIM_CARATER_ATENDIMENTO`;
- `DIM_MOTIVO_SAIDA_PERMANENCIA`;
- `DIM_TIPO_LEITO`.

As oito dimensões possuem justificativa analítica e evidência nas fontes inspecionadas.

---

## Chaves de integração validadas

### Estabelecimento

`SIH.CNES ↔ CNES/ST.CNES ↔ CNES/LT.CNES`

Cobertura observada nos checkpoints de janeiro de 2017, 2018 e 2019:

**100% dos CNES do SIH encontrados no LT e 100% dos CNES do LT encontrados no ST.**

### Município de atendimento/localização

`SIH.MUNIC_MOV ↔ CNES.CODUFMUN`

compatível nos checkpoints analisados.

### Município de residência

`SIH.MUNIC_RES` pode apontar para município fora da Paraíba.

A dimensão Município deve suportar esses municípios no papel de residência.

### DATASUS ↔ IBGE

A integração municipal utilizará correspondência validada entre código DATASUS e código IBGE.

Não calcular artificialmente o sétimo dígito do código IBGE.

---

## Decisão Star x Snowflake

### DECISÃO CONFIRMADA

**Star Schema em cada processo factual, com dimensões conformadas compartilhadas.**

O conjunto completo possui múltiplas fatos e pode ser descrito como uma **constelação de esquemas estrela**, sem normalização Snowflake das dimensões.

Justificativa resumida:

- dimensões relativamente pequenas;
- melhor simplicidade analítica;
- menor número de joins;
- hierarquias podem ser desnormalizadas nas dimensões;
- adequado ao uso no QlikView;
- o modelo lógico normalizado do Capítulo 1 permanece separado do modelo dimensional do Capítulo 2.

---

## Capacidade hospitalar

### DECISÃO CONFIRMADA

Preservar todos os registros LT válidos na `FATO_CAPACIDADE_LEITO`.

O recorte estritamente hospitalar deverá ser representado por classificação do estabelecimento, em vez de descartar antecipadamente registros válidos como Hospital/Dia ou outros tipos presentes no LT.

Para indicadores anuais de capacidade, utilizar regra compatível com snapshots mensais, preferencialmente a média dos 12 meses, e nunca a soma das capacidades mensais.

---

## Regras analíticas confirmadas

- `N_AIH` não será usado isoladamente como PK da fato de internação;
- criar chave técnica para o registro RD preservando rastreabilidade;
- município de residência e município de atendimento são papéis distintos;
- `PROC_REA` é o procedimento principal da primeira versão;
- `DIAG_PRINC` é o diagnóstico utilizado na primeira versão;
- diagnósticos secundários ficam fora do escopo inicial;
- competência, data de internação e data de saída são papéis temporais distintos;
- leitos existentes e leitos SUS são medidas diferentes;
- internações/leito é relação descritiva de demanda/capacidade e não taxa de ocupação;
- internações por 1.000 habitantes devem usar internações de residentes e população do mesmo município/ano;
- leitos SUS por 1.000 habitantes devem usar capacidade no município de localização e população compatível.

---

## Modelo conceitual/lógico consolidado para revisão

Entidades atualmente sustentadas:

- UF;
- MUNICIPIO;
- ESTABELECIMENTO;
- ESTABELECIMENTO_COMPETENCIA;
- REGISTRO_AIH;
- PROCEDIMENTO;
- DIAGNOSTICO;
- CARATER_ATENDIMENTO;
- MOTIVO_SAIDA_PERMANENCIA;
- TIPO_LEITO;
- LEITO;
- CAPACIDADE_LEITO;
- POPULACAO_MUNICIPAL.

A tabela/entidade `ESTABELECIMENTO_COMPETENCIA` é necessária para representar atributos históricos do estabelecimento observados no ST.

Especificação acadêmica canônica atual:

`docs/academic/chapter-1-2-modeling.md`

---

## Fechamento semântico

### FATO VERIFICADO

Os domínios necessários ao desenho acadêmico foram validados em documentação oficial:

- procedimento: SIGTAP;
- diagnóstico principal: CID-10;
- caráter de atendimento: domínio oficial SIH/SIA;
- motivo de saída/permanência: Tabela Auxiliar de Encerramento;
- tipo/detalhamento de leito: CNES.

A cardinalidade entre `REGISTRO_AIH` e `MOTIVO_SAIDA_PERMANENCIA` foi fechada como obrigatória `(1,1)` no lado do registro, sustentada pelo layout oficial do SISAIH01 e pelo preenchimento integral nos checkpoints analisados.

Status:

- DER conceitual: **DIAGRAMADO E REVISADO**;
- modelo lógico normalizado: **DIAGRAMADO E REVISADO**, com PK/FK e cardinalidades mínima/máxima explícitas;
- modelo dimensional: **DIAGRAMADO E REVISADO** em visão de constelação e estrelas separadas para Internação, Capacidade e População.

Os artefatos gráficos derivados permanecem fora do Git por enquanto; a fonte canônica da modelagem continua em `docs/academic/chapter-1-2-modeling.md`.

---

## Pendências que não bloqueiam a primeira entrega

- adquirir e validar os 36 meses completos durante a implementação;
- materializar as tabelas oficiais de referência por competência no ETL;
- definir fonte histórica de nome fantasia/razão social do estabelecimento;
- fechar a técnica concreta de historização de `DIM_ESTABELECIMENTO`;
- validar na carga integral médias/razões afetadas por registros de continuidade;
- definir estrutura concreta de scripts, QVDs e QVWs quando começar a implementação QlikView.

---

## Orientações acadêmicas

A primeira entrega continua com prazo em **13/10/2026**, formato impresso, até o Capítulo 2.

### Capítulo 1

Deve conter:

- regras de negócio;
- entidades;
- relacionamentos;
- cardinalidades mínima e máxima;
- modelo conceitual / DER;
- modelo lógico relacional normalizado.

### Capítulo 2

Deve conter:

- descrição da estrutura dimensional;
- escolha e justificativa Star x Snowflake;
- modelo dimensional.

A decisão atual é **Star Schema**.

---

## Fluxo QlikView preservado

Quando a implementação começar, a referência didática continua:

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

Não substituir esse fluxo silenciosamente.

---

## Redação acadêmica

Rascunhos canônicos criados:

- `docs/academic/chapter-1-draft.md` — Regras de Negócio, entidades, relacionamentos, cardinalidades, modelo conceitual e modelo lógico;
- `docs/academic/chapter-2-draft.md` — escolha e justificativa do Star Schema, fatos, dimensões, granularidades, matriz fato × dimensão e indicadores.

Status:

**CAPÍTULOS 1 E 2 — RASCUNHO COMPLETO PARA REVISÃO EDITORIAL E MONTAGEM DO RELATÓRIO.**

---

## Próximo passo

1. revisar editorialmente os Capítulos 1 e 2;
2. inserir os diagramas revisados nas posições indicadas;
3. montar o relatório impresso com capa e sumário conforme o roteiro do professor;
4. conferir nomenclatura e numeração de figuras/tabelas;
5. realizar uma revisão final de aderência ao roteiro acadêmico;
6. somente depois iniciar a implementação no QlikView 12.
