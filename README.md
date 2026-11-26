# SAD — Data Mart SUS PB

Projeto acadêmico de Sistemas de Apoio à Decisão (Sistemas de Informação, UNIESP, 2026.2). Analisa registros de internações do SUS, capacidade cadastral de leitos e população residente na Paraíba, de 2017 a 2019, com QlikView 12.

**Fontes:** SIH/SUS (RD), CNES (LT e ST) e IBGE/SIDRA.

## Arquitetura

`BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`

Modelo estrela por processo, formando uma constelação de três fatos e oito dimensões.

| Fato | Granularidade |
| --- | --- |
| `FATO_INTERNACAO` | Registro administrativo de AIH processada |
| `FATO_CAPACIDADE_LEITO` | Estabelecimento × competência mensal × código de leito |
| `FATO_POPULACAO` | Município × ano |

## Estrutura do repositório

| Caminho | Finalidade |
| --- | --- |
| `BASE/` (local) | Dados de origem e referências; não versionados |
| [EXTRACAO/](EXTRACAO/) | Scripts QVS de extração e controles; QVDs locais |
| [TRANSFORMACAO/](TRANSFORMACAO/) | Scripts dimensionais, fatos, verificações e rotinas associativas; QVDs locais |
| [PAINEL/](PAINEL/) | Scripts, protótipos e contratos de apresentação |
| [tools/](tools/) | Automações, diagnósticos e ferramentas de documentação e validação |
| [docs/academic/](docs/academic/) | Requisitos, modelagem e registros da entrega |
| [docs/project/](docs/project/) | Estado atual, decisões e orientações operacionais |
| [docs/discovery/](docs/discovery/) | Evidências, investigações e contratos técnicos históricos |
| [AGENTS.md](AGENTS.md) | Invariantes e regras de trabalho |

Os scripts incluem rotinas experimentais e controles de execução: a existência de um arquivo não implica aprovação física ou autorização para executá-lo.

## Resultado acadêmico

Três painéis, com nove visualizações: **Produção Hospitalar**, **Leitos Cadastrais Observados** e **Fluxos e Contexto Territorial**. Os indicadores cruzados previstos, mas não suficientemente validados, não foram implementados. A solução é acadêmica e descritiva, não homologada para produção.

## Consulta e reprodução

- [Estado atual e pendências](docs/project/current-state.md)
- [Requisitos acadêmicos](docs/academic/requirements.md) e [modelagem](docs/academic/chapter-1-2-modeling.md)
- [Registro da entrega e identificação do PDF/QVW](docs/academic/final-delivery-record-2026-11-10.md)
- [Política de artefatos e limites de reprodução](docs/project/artifact-recovery-policy.md)
- [Automação do QlikView](docs/project/qlikview-powershell-automation.md)

Os QVWs, QVDs, dados brutos e PDF de entrega são preservados fora do Git. Os QVS não reconstituem sozinhos todos os objetos, configurações visuais e associações da aplicação final. Antes de qualquer recarga, consulte os contratos, dependências e limites registrados na documentação.
