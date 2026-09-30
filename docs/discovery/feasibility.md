# Feasibility Discovery — Data Mart SUS PB

## Status

**Concluída**

## Veredito

**APROVADO COM AJUSTES**

O tema é viável para o projeto acadêmico de SAD, com dados públicos oficiais suficientes para sustentar análise de demanda hospitalar, capacidade hospitalar e população na Paraíba.

A principal condição é não forçar dados de internações, leitos e população em uma única tabela fato quando suas granularidades não forem compatíveis.

---

# 1. Problema analítico

Construir um Data Mart para apoiar análise descritiva e comparativa da relação entre:

- demanda hospitalar do SUS;
- capacidade hospitalar;
- população;

com foco inicial no estado da Paraíba.

O projeto deve apoiar perguntas como:

- quais municípios apresentam maior volume de internações por habitante;
- quais possuem menor disponibilidade de leitos por habitante;
- como a demanda hospitalar evolui;
- como a capacidade hospitalar evolui;
- como demanda e capacidade se relacionam;
- quais municípios concentram atendimento de residentes de outros municípios.

O projeto não deve inferir causalidade a partir dessas relações.

---

# 2. Fontes candidatas

## 2.1 SIH/SUS

**Papel candidato:** demanda hospitalar.

### FATO VERIFICADO

O SIH/SUS registra informações de internações hospitalares financiadas/processadas pelo SUS por meio da AIH.

A fonte possui histórico e informações relacionadas a:

- estabelecimento;
- município;
- procedimento;
- diagnóstico;
- período;
- permanência;
- valores;
- motivo de saída;
- outras características assistenciais/administrativas.

Há distinção entre tipos de AIH, incluindo continuidade de longa permanência.

Uma AIH não deve ser tratada automaticamente como:

- paciente único;
- episódio clínico único;
- pessoa internada única.

### HIPÓTESE DE MODELAGEM

Usar arquivos RD/AIH reduzida como fonte principal da demanda hospitalar.

### DECISÃO PENDENTE

Validar nos arquivos reais da Paraíba:

- estrutura exata;
- campos disponíveis;
- chave/identificador;
- granularidade real;
- regras para contagem de internações;
- tratamento de AIHs de continuidade.

---

## 2.2 CNES — Hospitais e Leitos

**Papel candidato:** capacidade hospitalar.

### FATO VERIFICADO

O CNES possui informações históricas sobre estabelecimentos e leitos por competência.

A documentação diferencia conceitos como:

- leitos existentes;
- leitos SUS;
- leitos não SUS;
- tipos de leito.

A capacidade registrada pode variar ao longo do tempo.

### HIPÓTESE DE MODELAGEM

Tratar leitos como um snapshot periódico de capacidade hospitalar.

### DECISÃO PENDENTE

Validar nos arquivos reais:

- granularidade;
- competência;
- estabelecimento;
- município;
- tipo/detalhamento de leito;
- regras específicas para leitos complementares;
- estrutura histórica dos arquivos.

---

## 2.3 IBGE / SIDRA

**Papel candidato:** população e referência geográfica.

### FATO VERIFICADO

O IBGE disponibiliza:

- estimativas populacionais municipais;
- códigos oficiais de municípios;
- séries históricas e referências temporais.

### HIPÓTESE DE MODELAGEM

Usar população residente municipal anual como denominador de indicadores.

### DECISÃO PENDENTE

Validar:

- anos escolhidos;
- código municipal usado nos arquivos;
- compatibilidade com SIH e CNES;
- notas/exceções metodológicas.

---

# 3. Compatibilidade entre fontes

## Geografia

### FATO VERIFICADO

SIH, CNES e IBGE possuem informação em nível municipal.

O SIH pode distinguir:

- município de residência;
- município de internação/atendimento.

### HIPÓTESE DE MODELAGEM

Usar uma mesma dimensão conformada de município em papéis diferentes, por exemplo:

- município de residência;
- município de internação.

### DECISÃO PENDENTE

Confirmar nos datasets reais:

- formato dos códigos municipais;
- necessidade de transformação;
- correspondência com código IBGE oficial;
- exceções históricas.

Nenhuma truncagem, concatenação ou preenchimento de código deve ser feita sem validação.

---

## Tempo

### FATO VERIFICADO

As três fontes possuem dimensão temporal:

- SIH: competências/datas relacionadas à internação;
- CNES: competência de cadastro;
- IBGE: ano/data de referência populacional.

### HIPÓTESE DE MODELAGEM

Integrar análises por períodos compatíveis, preferencialmente em recortes anuais quando envolver população e capacidade.

### DECISÃO PENDENTE

Confirmar o período final apenas após inspeção concreta das três fontes.

---

# 4. Arquitetura candidata

## 4.1 Processo principal

**Internações hospitalares registradas no SIH/SUS**

Esse é o processo de negócio candidato a eixo principal do Data Mart.

---

## 4.2 FATO_INTERNACAO

### HIPÓTESE DE MODELAGEM

Granularidade candidata:

**1 linha = 1 registro RD / AIH aprovada**

Essa definição ainda depende de inspeção concreta.

### Medidas candidatas

- quantidade de internações / registros computáveis;
- dias de permanência;
- valor aprovado;
- quantidade de óbitos.

### Dimensões candidatas

- DIM_TEMPO;
- DIM_MUNICIPIO;
- DIM_ESTABELECIMENTO;
- DIM_PROCEDIMENTO;
- DIM_DIAGNOSTICO;
- DIM_CARATER_ATENDIMENTO;
- DIM_MOTIVO_SAIDA.

---

## 4.3 FATO_CAPACIDADE_LEITO

### HIPÓTESE DE MODELAGEM

Granularidade candidata:

**1 linha = estabelecimento × competência × tipo/detalhamento de leito**

### Medidas candidatas

- quantidade de leitos existentes;
- quantidade de leitos SUS.

### Classificação preliminar

Medidas de leitos são candidatas a **semi-aditivas no tempo**.

Exemplo:

30 leitos em janeiro + 30 leitos em fevereiro não representam 60 leitos disponíveis.

### Dimensões candidatas

- DIM_TEMPO;
- DIM_MUNICIPIO;
- DIM_ESTABELECIMENTO;
- DIM_TIPO_LEITO.

---

## 4.4 FATO_POPULACAO

### HIPÓTESE DE MODELAGEM

Granularidade candidata:

**1 linha = município × ano**

### Medida candidata

- população residente.

### Classificação preliminar

População é candidata a medida **semi-aditiva no tempo**.

### Dimensões candidatas

- DIM_TEMPO;
- DIM_MUNICIPIO.

---

# 5. Dimensões candidatas

As seguintes dimensões possuem justificativa analítica inicial e não foram propostas apenas para cumprir o requisito mínimo:

1. DIM_TEMPO;
2. DIM_MUNICIPIO;
3. DIM_ESTABELECIMENTO;
4. DIM_PROCEDIMENTO;
5. DIM_DIAGNOSTICO;
6. DIM_CARATER_ATENDIMENTO;
7. DIM_MOTIVO_SAIDA;
8. DIM_TIPO_LEITO.

## DECISÃO PENDENTE

Confirmar cada dimensão após inspeção dos campos reais.

Não incluir automaticamente:

- DIM_ESPECIALIDADE;
- DIM_REGIAO_SAUDE;
- outras dimensões não verificadas nos dados.

---

# 6. Matriz fato × dimensão candidata

| Dimensão | Internação | Capacidade | População |
|---|:---:|:---:|:---:|
| DIM_TEMPO | ✓ | ✓ | ✓ |
| DIM_MUNICIPIO — residência | ✓ | — | ✓ |
| DIM_MUNICIPIO — internação | ✓ | ✓ | — |
| DIM_ESTABELECIMENTO | ✓ | ✓ | — |
| DIM_PROCEDIMENTO | ✓ | — | — |
| DIM_DIAGNOSTICO | ✓ | — | — |
| DIM_CARATER_ATENDIMENTO | ✓ | — | — |
| DIM_MOTIVO_SAIDA | ✓ | — | — |
| DIM_TIPO_LEITO | — | ✓ | — |

Status:

**HIPÓTESE DE MODELAGEM**

---

# 7. Medidas e indicadores candidatos

## 7.1 Medidas armazenadas

### Internações

- contador de internações/registros válidos;
- dias de permanência;
- valor aprovado;
- indicador/contador de óbito.

### Capacidade

- quantidade de leitos existentes;
- quantidade de leitos SUS.

### População

- população residente.

---

## 7.2 Medidas derivadas

- média de permanência;
- valor médio por internação;
- variação das internações;
- variação da capacidade;
- variação populacional.

Razões e médias não devem ser somadas como medidas brutas.

---

## 7.3 Indicadores candidatos

### Internações por 1.000 habitantes

**VIÁVEL EM PRINCÍPIO**

Requer:

- internações de residentes;
- população residente;
- mesmo município/período.

### Leitos SUS por 1.000 habitantes

**VIÁVEL EM PRINCÍPIO**

Requer:

- leitos SUS;
- população residente;
- mesmo período geográfico;
- regra temporal consistente para leitos.

### Internações por leito

**VIÁVEL COM RESSALVAS**

Pode representar uma relação descritiva entre demanda registrada e capacidade cadastrada.

Não deve ser chamada automaticamente de taxa de ocupação.

### Taxa de ocupação

**NÃO APROVADA NESTA DISCOVERY**

Não há evidência suficiente de que as fontes candidatas permitam calcular uma taxa de ocupação hospitalar metodologicamente correta.

### Fluxo entre municípios

**VIÁVEL EM PRINCÍPIO**

Comparação entre:

- município de residência;
- município de internação.

Pode apoiar análise de concentração regional de atendimento.

---

# 8. Dashboards candidatos

## Painel 1 — Demanda hospitalar

Candidato a apresentar:

- internações ao longo do tempo;
- internações por município;
- internações por população;
- procedimentos;
- diagnósticos;
- permanência;
- desfechos.

**Status:** VIÁVEL EM PRINCÍPIO.

---

## Painel 2 — Capacidade hospitalar

Candidato a apresentar:

- leitos existentes;
- leitos SUS;
- evolução temporal;
- tipo de leito;
- estabelecimento;
- município;
- leitos por 1.000 habitantes.

**Status:** VIÁVEL EM PRINCÍPIO.

---

## Painel 3 — Capacidade × Demanda

Candidato a apresentar:

- internações por 1.000 habitantes;
- leitos SUS por 1.000 habitantes;
- relação internações/leito;
- evolução comparada;
- fluxos residência → atendimento.

**Status:** VIÁVEL COM CONTROLE METODOLÓGICO.

Nenhuma visualização deve sugerir causalidade sem evidência adicional.

---

# 9. Riscos principais

| Risco | Nível |
|---|---|
| Interpretar AIH como paciente único | ALTO |
| Interpretar AIH como episódio clínico único | ALTO |
| Misturar município de residência com município de internação | ALTO |
| Somar snapshots de leitos ao longo do tempo | ALTO |
| Usar população de período diferente do numerador | ALTO |
| Chamar internações/leito de taxa de ocupação | ALTO |
| Tratar leito existente e leito SUS como equivalentes | MÉDIO/ALTO |
| Regras específicas de leitos complementares | MÉDIO/ALTO |
| Transformação de códigos municipais | MÉDIO |
| Formato DBC/DBF do SIH | MÉDIO |
| Interpretação epidemiológica além do escopo | MÉDIO |
| Volume excessivo se usado SIH nacional | BAIXO no escopo PB |

---

# 10. Complexidade preliminar

| Área | Classificação |
|---|---|
| Aquisição | MÉDIA |
| ETL | MÉDIA |
| Modelagem | MÉDIA |
| Domínio | MÉDIA |
| Implementação | MÉDIA |
| Volume no escopo PB | BAIXO/MÉDIO |

A complexidade é considerada compatível com o semestre se:

- o escopo permanecer na Paraíba;
- o período for controlado;
- apenas as fontes necessárias forem utilizadas.

---

# 11. Período candidato

## HIPÓTESE DE MODELAGEM

**2017–2019**

Motivação inicial:

- três anos completos;
- evita introduzir a excepcionalidade da pandemia de COVID-19 na primeira modelagem;
- permite análise de tendência;
- reduz volume;
- tende a possuir cobertura nas três fontes candidatas.

## DECISÃO PENDENTE

O período não deve ser fixado definitivamente antes da inspeção real de:

- SIH;
- CNES;
- IBGE.

---

# 12. Star Schema x Snowflake Schema

## FATO VERIFICADO

O material da disciplina exige escolher e justificar Star Schema ou Snowflake Schema.

A Aula 6 diferencia:

- Star Schema: dimensões desnormalizadas;
- Snowflake Schema: dimensões normalizadas.

## HIPÓTESE DE MODELAGEM

A arquitetura candidata tende a favorecer:

**Star Schema por processo + dimensões conformadas**

com múltiplas fatos compartilhando dimensões comuns.

## DECISÃO PENDENTE

A escolha final só será feita após:

- confirmar entidades;
- confirmar dimensões;
- confirmar hierarquias;
- verificar a estrutura lógica necessária.

Não escolher Star ou Snowflake apenas por preferência.

---

# 13. QlikView

## FATO VERIFICADO

QlikView 12 será a ferramenta obrigatória.

A Aula 7 apresenta como fluxo didático:

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

## DECISÃO CONFIRMADA

Esse fluxo será a referência inicial quando a implementação começar.

A arquitetura concreta de arquivos QlikView continua pendente até a validação dos datasets.

---

# 14. Decisões confirmadas

- Tema: demanda, capacidade hospitalar e população do SUS na Paraíba.
- Fontes prioritárias: SIH/SUS, CNES e IBGE.
- Escopo geográfico inicial: Paraíba.
- QlikView 12 como ferramenta obrigatória.
- Primeira entrega impressa até o Capítulo 2.
- Não tratar internações, leitos e população como uma única fato sem compatibilidade de granularidade.
- Não interpretar correlação como causalidade.
- Não chamar automaticamente internações/leito de taxa de ocupação.
- Repositório como fonte persistente de contexto técnico e decisões.

---

# 15. Hipóteses de modelagem

- FATO_INTERNACAO como fato principal;
- FATO_CAPACIDADE_LEITO como snapshot periódico;
- FATO_POPULACAO como snapshot anual auxiliar;
- período 2017–2019;
- oito dimensões candidatas;
- uso de dimensões conformadas;
- uso da DIM_MUNICIPIO em papéis diferentes;
- tendência preliminar a Star Schema por processo.

Todas permanecem sujeitas à próxima Discovery.

---

# 16. Decisões pendentes

- período definitivo;
- arquivos exatos;
- granularidade real de cada fonte;
- chaves naturais;
- transformação dos códigos municipais;
- dimensões definitivas;
- medidas definitivas;
- cardinalidades;
- regras de negócio;
- modelo conceitual;
- modelo lógico;
- Star Schema ou Snowflake Schema;
- estrutura final do Data Mart;
- estrutura concreta no QlikView.

---

# 17. Próxima Discovery

**SAD — SUS PB — DATASET VALIDATION / MODELING DISCOVERY**

Objetivos principais:

1. inspecionar dados reais do SIH/RD da Paraíba;
2. inspecionar dados históricos de leitos do CNES;
3. inspecionar população municipal do IBGE;
4. validar códigos municipais;
5. confirmar granularidades;
6. confirmar medidas;
7. confirmar dimensões;
8. iniciar regras de negócio;
9. iniciar entidades, relacionamentos e cardinalidades;
10. preparar base factual para Capítulo 1 e Capítulo 2.

Nenhuma implementação definitiva deve começar antes dessa validação.
