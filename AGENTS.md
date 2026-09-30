# AGENTS.md

## Objetivo

Este arquivo é o ponto de entrada obrigatório para agentes que trabalhem no projeto **SAD — Data Mart SUS PB**.

## Ordem de leitura

Antes de executar tarefas estruturais:

1. `AGENTS.md`;
2. `docs/project/current-state.md`;
3. `docs/academic/requirements.md`;
4. documentação específica da tarefa.

## Fontes de verdade

Ordem de autoridade:

1. material oficial da disciplina e instruções do professor;
2. documentação oficial das fontes de dados, especialmente Ministério da Saúde/DATASUS/CNES e IBGE;
3. dados reais inspecionados;
4. documentação versionada neste repositório;
5. chats e memória do ChatGPT como contexto auxiliar.

Chats não substituem documentação persistente.

## Regras de evidência

Separar sempre:

### FATO VERIFICADO

Informação confirmada por material acadêmico, documentação oficial ou inspeção dos dados.

### HIPÓTESE DE MODELAGEM

Interpretação candidata que ainda depende de validação.

### DECISÃO PENDENTE

Questão que ainda não possui evidência suficiente para definição.

Não inventar:

- campos;
- granularidades;
- chaves;
- cardinalidades;
- medidas;
- dimensões;
- regras de negócio;
- relacionamentos entre fontes.

## Preservação de decisões

Antes de propor mudança significativa:

1. verificar `docs/project/current-state.md`;
2. verificar se já existe decisão documentada;
3. evitar regressões ou alterações silenciosas de arquitetura;
4. registrar mudanças relevantes em documentação persistente.

## Prioridade acadêmica atual

A prioridade do projeto é produzir uma modelagem defensável para a **primeira entrega impressa**.

Essa entrega cobre:

- Capítulo 1 — Regras de Negócio;
- Capítulo 2 — Modelagem Dimensional.

Implementação no QlikView e dashboards não devem antecipar nem distorcer decisões de modelagem ainda não validadas.

## QlikView

Ferramenta obrigatória do projeto:

**QlikView 12**

Quando a implementação começar, privilegiar lógica versionável em arquivos de texto sempre que tecnicamente possível.

O arquivo `.qvw` não deve ser tratado como única fonte de verdade da lógica do projeto.

## Dados

Dados brutos e artefatos derivados não devem ser versionados automaticamente.

Antes de adicionar datasets ao Git:

1. avaliar tamanho;
2. avaliar licença/redistribuição;
3. distinguir fonte original de artefato derivado;
4. preferir versionar scripts, metadados e documentação de aquisição.

## Escopo atual

Discovery de viabilidade concluída.

Próxima etapa:

**Dataset Validation / Modeling Discovery**

Ainda não implementar:

- banco;
- ETL definitivo;
- dashboards;
- modelo dimensional definitivo;
- SQL;
- trabalho final.
