# Bootstrap — SAD | VIS-01 — Design System QlikView 12

**Continuar em novo chat do Project `SAD — Data Mart SUS PB`.** Este é um handoff de trabalho, não autorização para editar QVW. Fonte do plano: [sad-academic-visual-delivery-plan-2026-11-09.md](sad-academic-visual-delivery-plan-2026-11-09.md) na branch `docs/sad-academic-visual-readiness-2026-11-09`; ainda não integrada na main.

## Objetivo desta execução

Criar e aprovar uma **especificação visual aplicável às três folhas atuais** do MVP acadêmico (9 visuais), com **plano de fundo original**, padrão dos cards/KPIs existentes, gráficos, tabelas, cabeçalhos, espaçamentos, hierarquia e estados de aviso. **Não editar a QVW neste gate.**

## Fontes de verdade e leitura obrigatória

1. `main:AGENTS.md`
2. `main:docs/project/current-state.md`
3. `main:docs/academic/requirements.md`
4. Plano desta branch: `docs/project/sad-academic-visual-delivery-plan-2026-11-09.md`
5. Handoff candidato no Draft #226: `docs/project/sad-academic-delivery-handoff-2026-11-09.md`; `docs/project/mvp-evidence-and-contract-gates-consolidation-2026-11-07.md`.
6. `main:docs/project/qlikview-powershell-automation.md` **apenas se** uma capacidade real do QlikView precisar de verificação. Não acionar COM por padrão.

O conteúdo oficial da disciplina prevalece quando divergir da documentação operacional. Dados e evidências locais já coletadas não devem ser reinventados.

## Baselines protegidas

- QVW original: `C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw`.
- SHA-256 reportado e conferido pelo operador: `27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13`.
- Relatório de recuperação: `SAD_A4_Relatorio_Consolidado_R2_Editorial.pdf`, 98 páginas, capítulos 1–5 e anexos; fora do Git. Preservar R2 como fallback até DOC-R3.
- A1–A4 ocorreram; A2/A4 geradores locais ainda requerem regularização prospectiva se utilizados como evidência formal.
- Data comunicada da avaliação: **08/12/2026**; online no **Google Classroom**; envio do documento em **PDF**; três folhas satisfazem o requisito de três painéis conforme confirmação do operador.

## Escopo autorizado hoje: planejamento de design, sem execução física

**Folha 1 — Produção Hospitalar:** 3 objetos `M1-01..M1-03` (internações por ano, evolução mensal, ranking de município de atendimento).

**Folha 2 — Leitos Cadastrais Observados:** 3 objetos `M2-01..M2-03` (leitos por competência, leitos SUS no recorte 201912, observabilidade município × competência).

**Folha 3 — Fluxos e Contexto Territorial:** 3 objetos `M3-01..M3-03` (RES vs SERV, pares dirigidos, população municipal anual).

Propor estética institucional leve e profissional, preferencialmente fundo claro/off-white e azul petróleo/teal. Evitar cor como único canal de distinção e testar legibilidade em compartilhamento de tela. A escolha da paleta final é **decisão VIS-01 a aprovar**, não mudança já autorizada.

## Workflow VIS-01

1. Inspecionar as **capturas reais** das três folhas de C4 já existentes, recuperando dos anexos/Files quando possível. Se indisponíveis, pedir apenas as capturas, não novos testes.
2. Inventariar restrições dos objetos e funções de estilo disponíveis no QlikView 12, separando **suporte confirmado** de hipótese; sem executar COM, Reload ou Save.
3. Propor uma identidade visual **única** com quadro de cores/tipografia, grid, fundo estático original, cards/KPIs, tabelas, gráficos, avisos de seleção e adaptação a resolução compartilhada. Quando a criação de imagem custar geração, avaliar se uma imagem é mesmo necessária e informar custo/alternativa de fundo simples.
4. Criar mockups **propostos**, explicitamente não capturas do QVW real; em geral um para cada folha.
5. Redigir plano objeto-a-objeto para futura aplicação no VIS-02, com critério de aceitação e rollback.
6. Solicitar **aprovação da direção visual** antes de abrir VIS-02. Encerrar o gate VIS-01.

## Invariantes e bloqueios

- **NÃO** modificar `main`, QVW C4 original, QVDs, dados, scripts de carga, 3 fatos, 8 dimensões, granularidades ou contratos globais C2/C3/C4.
- **NÃO** alterar expressões, filtros, significados das medidas nem inventar KPIs novos. Se usuário desejar novos objetos, abrir decisão separada.
- **NÃO** tratar visual B1 de 9 objetos como alteração aprovada do blueprint de 14 objetos na main.
- **NÃO** declarar homologação de produção; `C2_C3_C4_GLOBAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`.
- **NÃO** repetir testes encerrados M1–M3, F01–F03 ou o diagnóstico COM de CH09.
- A execução Windows e edição de **cópia controlada** da QVW pertencem a VIS-02 e precisam de autorização específica; nenhum merge automático.

## Saída esperada e STOP

**PASS:** design system com proposta principal, especificações e mockups legíveis das 3 folhas, compatibilidades verificadas ou limitações identificadas, aceitação visual do responsável, VIS-02 definido com fronteira segura. **BLOCKED:** artefatos de captura indispensáveis ausentes. **INCONCLUSIVE:** dúvida técnica sobre configuração visual no QlikView ainda não comprovada; registrar consulta necessária, não supor compatibilidade.

**Ambiente:** novo chat ChatGPT no mesmo Project; GitHub para documentação; capturas por Files; Windows PowerShell 5.1/QlikView Desktop 12 **somente** em gate posterior autorizado. **Agente primário:** ChatGPT GPT-6, esforço médio/alto se disponível; fallback: análise textual + mockups estáticos sem abrir Work ou COM. **Escalonar** para Work/Codex apenas se a edição repetitiva/automação exigir e houver ganho real; confirmar disponibilidade e limites antes. Não depende de um chat longo.

## Texto de abertura sugerido para o novo chat

> Estamos no projeto SAD — Data Mart SUS PB. Execute **somente VIS-01 — Design System QlikView 12** conforme `docs/project/sad-vis-01-bootstrap-2026-11-09.md` na branch `docs/sad-academic-visual-readiness-2026-11-09`. Leia `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md` da main, nessa ordem, e então o plano/bootstraps. Use as capturas da QVW C4 de três folhas e nove objetos já aprovados como MVP restrito. Produza identidade visual, fundo original e mockups de cards/tabelas/gráficos respeitando limitações reais do QlikView 12. Não editar QVW/QVD, não executar COM/Reload/Save nem criar novos indicadores. Apresente uma proposta principal com trade-offs e finalize com critérios de aceitação VIS-01 e plano para VIS-02.