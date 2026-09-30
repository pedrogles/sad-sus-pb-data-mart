# Current State

## Projeto

**SAD — Data Mart SUS PB**

Disciplina: Sistemas de Apoio à Decisão — 2026.2  
Ferramenta obrigatória: QlikView 12

## Etapa atual

**Feasibility Discovery concluída.**

Veredito:

**APROVADO COM AJUSTES**

Próxima etapa planejada:

**SAD — SUS PB — DATASET VALIDATION / MODELING DISCOVERY**

## Tema

Data Mart para análise descritiva e comparativa da demanda hospitalar, capacidade hospitalar e população do SUS na Paraíba.

## Fontes candidatas

- SIH/SUS — demanda hospitalar;
- CNES — hospitais e leitos;
- IBGE/SIDRA — população e códigos municipais.

Status:

**CANDIDATAS — requerem inspeção concreta dos datasets.**

## Período candidato

**2017–2019**

Status:

**HIPÓTESE DE MODELAGEM**

O intervalo ainda não é definitivo e depende da validação dos arquivos reais e da compatibilidade entre as fontes.

## Arquitetura candidata

### Fatos candidatas

- `FATO_INTERNACAO`
- `FATO_CAPACIDADE_LEITO`
- `FATO_POPULACAO`

Status:

**HIPÓTESE DE MODELAGEM**

Nenhuma granularidade deve ser tratada como definitiva antes da próxima Discovery.

## Dimensões candidatas

- `DIM_TEMPO`
- `DIM_MUNICIPIO`
- `DIM_ESTABELECIMENTO`
- `DIM_PROCEDIMENTO`
- `DIM_DIAGNOSTICO`
- `DIM_CARATER_ATENDIMENTO`
- `DIM_MOTIVO_SAIDA`
- `DIM_TIPO_LEITO`

Status:

**HIPÓTESE DE MODELAGEM**

## Orientações acadêmicas verificadas

### Star x Snowflake

Aula 6 confirma:

- Star: dimensões desnormalizadas;
- Snowflake: dimensões normalizadas;
- Snowflake reduz redundância/volume em determinadas estruturas, mas aumenta joins e complexidade de entendimento/manutenção.

**DECISÃO PENDENTE:** Star Schema ou Snowflake Schema para o Data Mart final.

Aula 7 usa Star Schema em um exercício específico, sem eliminar a exigência geral de justificar a escolha do projeto.

### Fluxo QlikView ensinado

Aula 7 apresenta o fluxo didático:

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

Esse fluxo passa a ser a referência inicial para a futura implementação no QlikView 12.

A arquitetura concreta ainda não será criada antes da validação dos datasets.

## Decisões confirmadas

- O projeto será desenvolvido para a disciplina SAD 2026.2.
- A ferramenta obrigatória de implementação será QlikView 12.
- A primeira entrega é impressa e vai até o Capítulo 2.
- O repositório é a fonte persistente de contexto técnico e decisões do projeto.
- Material do professor e documentação oficial das fontes possuem autoridade superior a hipóteses de chats.
- O fluxo QlikView ensinado pelo professor (Base → Extração/QVD → Transformação/QVD → Painel) será a referência inicial de implementação.

## Decisões pendentes

- período definitivo;
- datasets exatos;
- granularidade definitiva das fatos;
- chaves de integração;
- cardinalidades;
- medidas definitivas;
- dimensões definitivas;
- Star Schema ou Snowflake Schema;
- forma final de integração entre internações, leitos e população;
- estrutura concreta de pastas/arquivos QlikView após validação dos datasets.

## Próximo passo

Executar a **Dataset Validation / Modeling Discovery**:

1. inspecionar amostra real do SIH/RD da Paraíba;
2. inspecionar histórico de leitos do CNES;
3. inspecionar população municipal do IBGE;
4. validar códigos municipais;
5. confirmar granularidades;
6. confirmar medidas e dimensões;
7. iniciar regras de negócio;
8. preparar base factual para Capítulo 1 e Capítulo 2.

Não implementar o Data Mart antes dessa validação.
