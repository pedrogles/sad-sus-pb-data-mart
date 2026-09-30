# Requisitos Acadêmicos — SAD 2026.2

## Fonte canônica

Os requisitos acadêmicos devem ser conferidos no material oficial fornecido pelo professor.

Este arquivo é uma representação operacional para orientar agentes e o desenvolvimento do projeto. Em caso de divergência, prevalece o documento oficial.

## Disciplina

- Curso: Sistemas de Informação
- Disciplina: Sistemas de Apoio à Decisão
- Semestre: 2026.2

## Projeto

Desenvolver um projeto de Data Mart.

## Requisitos gerais relevantes

O trabalho exige:

- regras de negócio;
- entidades;
- relacionamentos;
- cardinalidades mínima e máxima;
- modelo conceitual;
- DER;
- modelo lógico relacional normalizado;
- modelagem dimensional;
- escolha justificada entre Star Schema e Snowflake Schema;
- implementação em solução de BI;
- no mínimo 3 painéis;
- no mínimo 6 dimensões;
- no mínimo 1 tabela fato.

Quando a origem for tratada como banco de dados relacional:

- o banco de origem deve possuir no mínimo 10 tabelas populadas.

Quando a origem for composta por arquivos:

- a avaliação é feita caso a caso pelo professor.

## Primeira entrega

**Data:** 13/10/2026  
**Formato:** relatório impresso.

### Escopo

A primeira entrega vai até o Capítulo 2.

### Capítulo 1 — Regras de Negócio

Deve incluir:

- descrição detalhada das regras de negócio;
- entidades;
- relacionamentos;
- cardinalidades mínima e máxima;
- modelo conceitual;
- DER;
- modelo lógico relacional normalizado.

### Capítulo 2 — Modelagem Dimensional

Deve incluir:

- descrição da estrutura dimensional escolhida;
- escolha entre Star Schema e Snowflake Schema;
- justificativa da escolha;
- modelo dimensional.

## Orientação complementar — Star x Snowflake

A Aula 6 estabelece:

- Star Schema com dimensões desnormalizadas;
- Snowflake Schema com dimensões normalizadas.

Para Snowflake, o material destaca como vantagens potenciais:

- menor espaço ocupado;
- menor tempo de atualização por tabela.

E como desvantagens:

- mais joins;
- maior dificuldade de entendimento pelo usuário;
- manutenção mais complexa.

O material orienta avaliar:

- exigências da ferramenta OLAP;
- características do SGBD;
- características das dimensões.

Portanto, a escolha do projeto deve ser justificada pela estrutura real do Data Mart e não pela preferência genérica por um modelo.

## Orientação complementar — QlikView

A Aula 7 apresenta como referência didática de organização:

- `BASE`;
- `EXTRACAO`, com QVW de extração e QVD;
- `TRANSFORMACAO`, com QVD;
- `PAINEL`, com QVW de apresentação.

O material também apresenta os conceitos:

- análise in-memory;
- AQL / linguagem associativa;
- QVW;
- QVD;
- consolidação de múltiplas fontes;
- análise associativa.

Há um exercício específico da Aula 7 que solicita Star Schema. Isso deve ser tratado como requisito desse exercício, não como substituição automática do requisito geral do projeto de escolher e justificar Star ou Snowflake.

## Prioridade atual do projeto

Até a primeira entrega, decisões de aquisição, modelagem e documentação devem priorizar a capacidade de produzir de forma defensável:

1. regras de negócio;
2. entidades e relacionamentos;
3. cardinalidades;
4. modelo conceitual;
5. modelo lógico;
6. granularidade da(s) tabela(s) fato;
7. dimensões;
8. medidas;
9. modelo dimensional;
10. justificativa Star vs Snowflake.

Dashboards e implementação são importantes para validar viabilidade, mas não devem dominar esta fase.
