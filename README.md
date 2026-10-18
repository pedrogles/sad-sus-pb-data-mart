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

## Estado acadêmico e implementação — resumo de 18/10/2026

A primeira entrega acadêmica dos **Capítulos 1 e 2** foi **reportada como realizada em 13/10/2026**. A avaliação do professor permanece pendente. A modelagem acadêmica entregue não foi alterada: **três fatos, oito dimensões**, Star Schema por processo factual e constelação de estrelas com dimensões conformadas.

O projeto já ultrapassou a Fase III:
- **Fases I–III:** infraestrutura e conversão (108/108 DBC); extração/staging com dez QVDs locais reportados.
- **Fase IV:** oito dimensões implementadas conforme evidências de gate locais.
- **Fase V:** três fatos físicas com CREATE + READBACK local reportado.
- **Fase VI:** `TRANSFORMACAO/QVD/LINK_ANALISE.qvd` materializado em execução QlikView 12 **local reportada**, com 85.705 chaves, seis campos e publicação candidata sem sobrescrita. **Não** há homologação semântica da chave nem aprovação de produção.
- **Fase VII — Painel técnico:** ainda não implementada; primeiro passo proposto é **Discovery READ-ONLY** do contrato associativo e dos critérios de aceitação. As Fases VIII (indicadores) e IX (dashboards) permanecem pendentes.

**Invariantes:** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `T29_HISTORICAL=NOT_APPROVED`, `PRODUCTION_APPROVED=False`. A legenda CNES de setembro/2019 **não** está validada retroativamente em 2017–2019.

Fluxo físico preservado: `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.

**Fonte de verdade do estado vigente:** [`docs/project/current-state.md`](docs/project/current-state.md). Para detalhes físicos da Fase VI, consulte [evidência R1/R2](docs/discovery/phase-6-link-analise-physical-r2-2026-10-18.md). Os registros antigos de fases anteriores permanecem históricos.

## Documentação principal

- `AGENTS.md`
- `docs/project/current-state.md`
- `docs/academic/requirements.md`
- `docs/discovery/dataset-validation.md`
- `docs/academic/chapter-1-2-modeling.md`
- `docs/academic/first-delivery-review.md`
