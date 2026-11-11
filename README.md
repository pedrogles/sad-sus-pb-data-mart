# SAD — Data Mart SUS PB

Projeto acadêmico de **Sistemas de Apoio à Decisão**, curso de Sistemas de Informação, semestre **2026.2**. Fontes: **SIH/SUS RD**, **CNES/LT** e **IBGE/SIDRA**, período **2017–2019**, Paraíba.

## Arquitetura e primeira entrega

- Ferramenta obrigatória: **QlikView 12**.
- Pipeline: `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`.
- Modelagem aprovada: **3 fatos e 8 dimensões**, Star Schema por processo, formando uma constelação com dimensões conformadas.
- Capítulos 1–2 entregues impressos em **13/10/2026**, conforme operador; parecer docente ainda não registrado.
- O blueprint documentado de **14 visuais** segue como proposta formal de layout na `main`, não como 14 indicadores implementados/homologados.

## Resultado acadêmico da segunda entrega

O responsável delimitou a implementação final acadêmica em **3 folhas com 9 objetos** numa **QVW temporária protegida**, sem intenção de acrescentar indicadores após a segunda entrega:

| Folha | Conteúdo |
| --- | --- |
| **Produção Hospitalar** | Internações anuais, 36 competências administrativas e ranking municipal SERV |
| **Leitos Cadastrais Observados** | Séries de snapshots CNES, ranking SUS fixo em dezembro/2019 e ilha de observabilidade |
| **Fluxos e Contexto Territorial** | RES=SERV versus RES≠SERV, pares dirigidos e população municipal anual |

O acabamento **VIS-04** teve `PASS_GUI_VISUAL_RESTRICTED` por imagens pós-save/reabertura e hashes de fontes preservados **reportados pelo operador**. A implementação **não tem aceite global de C2/C3/C4**, não habilita Fase IX e **não é uma aplicação de produção homologada**. A tabela `P23_A1_ISLAND` é uma estrutura auxiliar intencionalmente desconectada, não uma quarta tabela fato.

O relatório **DOC-R3 final** foi gerado com **98 páginas**, Figuras 7–9 atualizadas e justificativa explícita dos indicadores não apresentados. O PDF e os QVWs/QVDs originais **não são versionados aqui**; cópias persistentes e verificação por SHA ficam sob responsabilidade do operador. O relatório **não foi submetido** e o ensaio online **não foi realizado** segundo as evidências atuais.

**Detalhes do produto, arquivos, hashes e limites:** [registro da entrega acadêmica](docs/academic/final-delivery-record-2026-11-10.md).

## Documentação canônica

- [Regras para agentes e invariantes](AGENTS.md)
- [Estado operacional e próximos passos](docs/project/current-state.md)
- [Requisitos oficiais traduzidos para o projeto](docs/academic/requirements.md)
- [Modelagem da primeira entrega](docs/academic/chapter-1-2-modeling.md)
- [Manifesto da segunda entrega](docs/academic/final-delivery-record-2026-11-10.md)
- [Revisão editorial do DOC-R3](docs/academic/doc-r3-editorial-patch-2026-11-10.md)
- [Matriz dos indicadores, usos e roteiro de apresentação](docs/academic/final-coverage-redundancy-review-and-online-rehearsal-2026-11-10.md)
- [VIS-04: evidência visual e persistência](docs/project/sad-vis-04-final-presentation-polish-runbook-2026-11-10.md)
- [Inventário de branches e PRs](docs/project/repository-final-hygiene-inventory-2026-11-10.json) e [plano de limpeza](docs/project/repository-final-hygiene-plan-2026-11-10.md)

## Pendências antes do encerramento acadêmico

1. Revisar/confirmar com o professor se as três **folhas** satisfazem o requisito de três **painéis** e verificar a avaliação comunicada para **08/12/2026**.
2. Executar **uma simulação de compartilhamento de tela** com QlikView e PDF de fallback.
3. Conferir hash e backup persistente dos artefatos, submeter o PDF e registrar o comprovante.
4. Após aprovação específica, integrar a consolidação documental e executar limpeza de PRs, issues e branches em lotes com verificação de SHA, sem apagar evidências.

**Importante:** insuficiências científicas e físicas (CNES histórico, indicadores cruzados, C2/C3/C4) são **limites explicitados do trabalho acadêmico**, não promessas de novos desenvolvimentos nem alegações de PASS de produção.
