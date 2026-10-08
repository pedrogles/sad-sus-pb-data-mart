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

## Estado de implementação — 08/10/2026

- **Fase I — infraestrutura QlikView 12:** concluída.
- **Fase II — conversão DBC:** concluída, 108/108 arquivos reconciliados.
- **Fase III — EXTRAÇÃO / staging:** em andamento; RD/LT/ST, IBGE, referências normativas, CID-10 e SIGTAP aprovados nos checkpoints locais.
- **CNES leitos / T29:** a Nota Técnica oficial de setembro/2019 cobre 57/57 pares e 35.518/35.518 ocorrências LT; **vigência de 2017–2019 não comprovada**, T29 integral não aprovado. Aprofundamento normativo suspenso até necessidade analítica/academica demonstrada.
- **Transformação e painéis:** ainda não iniciados; não antecipar fases.

Próxima ação: revisar o fechamento controlado de III-C4/T29 com a ressalva temporal explicitada e verificar os gates restantes da Fase III antes de iniciar `TRANSFORMACAO`.

Fluxo físico preservado:
`BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.

Consulte `docs/project/current-state.md` para o estado atual, sem reconstruir decisões pelos chats.

## Documentação principal

- `AGENTS.md`
- `docs/project/current-state.md`
- `docs/academic/requirements.md`
- `docs/discovery/dataset-validation.md`
- `docs/academic/chapter-1-2-modeling.md`
- `docs/academic/first-delivery-review.md`
