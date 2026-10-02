# SAD — Data Mart SUS PB

Projeto acadêmico da disciplina **Sistemas de Apoio à Decisão (SAD)** — curso de Sistemas de Informação, semestre 2026.2.

## Objetivo

Construir um Data Mart para análise descritiva e comparativa da relação entre:

- demanda hospitalar processada pelo SIH/SUS;
- capacidade de leitos cadastrada no CNES;
- população municipal estimada pelo IBGE;

com foco na Paraíba e período analítico de **2017–2019**.

## Ferramenta obrigatória

A implementação acadêmica será realizada no **QlikView 12**.

## Fontes confirmadas

- SIH/SUS — arquivos RD / AIH Reduzida;
- CNES — LT / Leitos;
- CNES — ST / Estabelecimentos;
- IBGE — estimativas populacionais municipais.

## Estado atual

A Feasibility Discovery e a Dataset Validation / Modeling Discovery foram concluídas.

A primeira entrega acadêmica, correspondente aos **Capítulos 1 e 2**, está:

**FECHADA — PRONTA PARA IMPRESSÃO/ENTREGA**

Modelagem aprovada:

- 3 tabelas fato;
- 8 dimensões;
- Star Schema por processo factual;
- constelação de esquemas estrela com dimensões conformadas;
- DER e modelo lógico relacional normalizado concluídos.

## Próxima etapa

**SAD — SUS PB — DATA ACQUISITION / QLIKVIEW IMPLEMENTATION DISCOVERY**

A implementação deve começar pela aquisição e validação dos 36 meses completos e pelo fechamento da arquitetura física no QlikView 12, preservando o fluxo didático:

`BASE → EXTRAÇÃO/QVD → TRANSFORMAÇÃO/QVD → PAINEL/QVW`.

## Documentação principal

- `AGENTS.md`
- `docs/project/current-state.md`
- `docs/academic/requirements.md`
- `docs/discovery/dataset-validation.md`
- `docs/academic/chapter-1-2-modeling.md`
- `docs/academic/first-delivery-review.md`
