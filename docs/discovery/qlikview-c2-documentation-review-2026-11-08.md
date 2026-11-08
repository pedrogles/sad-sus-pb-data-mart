# Discovery documental — QlikView 12 e controle temporal C2 (D2-R2)

**Data:** 2026-11-08  
**Natureza:** estudo documental de escopo fechado, sem execução no Windows/QlikView.  
**Baseline da `main` consultada:** `0549e1dba71aaa8bbab9d6755aecb8465f8bea83` (PR #214 integrado).  
**Classificação:** `DOCUMENTARY_REVIEW_COMPLETE`; `C2_GUIDED_R2=NOT_TESTED`; `PRODUCTION_APPROVED=False`.

## 1. Objetivo e limite

Identificar comportamentos oficialmente documentados do QlikView que afetam o D2-R2 e convertê-los em **perguntas de validação física**, sem alterar arquitetura, regras de negócio, QVW, QVD, QVS, executores ou status de gates.

Fontes internas consultadas na ordem obrigatória:
1. [AGENTS.md](../../AGENTS.md);
2. [Current state](../project/current-state.md);
3. [Requisitos acadêmicos](../academic/requirements.md);
4. [Boundary 7](boundary-7-implementation-plan.md);
5. [Adendo semântico D2-R2 V3](phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md);
6. [Automação PowerShell / QlikView](../project/qlikview-powershell-automation.md).

O contrato vigente diferencia **prevenção antes de ações guiadas** e **revalidação de indicadores após seleções nativas**. Não promete prevenção universal.

## 2. Conclusões verificadas em fonte oficial Qlik

| ID | Fato documentado | Consequência para C2 | Fonte |
| --- | --- | --- | --- |
| DOC-C2-01 | Os parâmetros de entrada de ações de um botão são avaliados antes da execução da primeira ação; mudanças posteriores não são automaticamente incorporadas à cadeia. | Não projetar a guarda como sequência que assume reavaliação dos parâmetros após cada ação. A ordem e o mecanismo de despacho precisam de teste. | [Botões / Ações](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm) |
| DOC-C2-02 | Um botão oferece *Enable Condition* para habilitá-lo ou desabilitá-lo com base em expressão. | Recurso candidato para controles guiados; NÃO prova que caminhos nativos também ficam bloqueados ou que o estado anterior é preservado. | [Button (September 2025)](https://help.qlik.com/en-US/qlikview/September2025/Subsystems/Client/Content/QV_QlikView/Button2.htm) |
| DOC-C2-03 | A propriedade *Calculation Condition* de um gráfico controla se ele é mostrado/calculado; em condição não atendida há mensagem própria. *Read Only* impede selecionar pelo próprio gráfico. | Mecanismo candidato de fail-closed **por gráfico**; não equivale a interceptar seleção nativa nem aprova a mensagem final. | [Propriedades do gráfico](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartProperties.htm) |
| DOC-C2-04 | Marcadores salvam e restauram seleções em todos os estados definidos. O menu permite importar marcadores. | A restauração de bookmark é uma rota nativa que demanda revalidação posterior por indicador. | [Marcadores](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Bookmarks.htm) · [Menu](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Bookmarks%20menu.htm) |
| DOC-C2-05 | Estados alternativos mantêm seleções separadas por estado, mas Clear, Back/Forward e Lock/Unlock podem atingir todos os estados; objetos não identificam visualmente o estado de forma automática. | Preservar A0 padrão e ilha A1 só em P2.3; exigir rótulo claro e testes de seleção/limpeza envolvendo ambos os estados. | [Alternate States](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Alternate%20States.htm) |
| DOC-C2-06 | O menu Selections inclui Back, Forward, Clear, Clear All e Unlock and Clear All, com efeitos distintos. | Não considerar apenas os botões customizados como superfície de seleção. | [Selections menu](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Selections_menu.htm) |
| DOC-C2-07 | GetSelectedCount() e GetFieldSelections() permitem observar contagens/valores selecionados; Set Analysis pode alterar o conjunto usado por uma expressão. | São possíveis insumos de diagnóstico do contexto **efetivamente aplicado**, mas isoladamente NÃO provam cobertura temporal, validade P5 ou semântica dos indicadores. | [Field functions](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/FieldFunctions/field-functions-charts.htm) · [Set analysis](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-analysis-expressions.htm) |
| DOC-C2-08 | A interface Automation/COM é oficialmente suportada, mas pode manipular internamente objetos e causar erros se mal utilizada. | Reutilizar executores existentes, somente com cópia TEMP e hashes. Propriedades/COM não substituem evidência semântica nem aprovação visual. | [Automation e COM](https://help.qlik.com/en-US/qlikview-developer/September2026/Subsystems/Automation/Content/QV_Automation/automation-introduction.htm) |

**Atenção à compatibilidade:** os links principais são da edição *September 2026*. A especificação candidata do gate cita `12.0.20000.0`; isso não é confirmação atual da instalação. Nenhuma propriedade, sintaxe de expressão, método COM ou comportamento de UI foi homologado na build local por este estudo. Não classificar diferenças entre versões como comprovadas sem comparação de release e teste local.

## 3. Aplicação ao contrato D2-R2 — hipóteses, não implementação

### A. Ação guiada (antes da mutação)

**Decisão semântica já aprovada:** validar proposta, domínio, período, cobertura conhecida e política P5 antes de despachar seleção. Em caso de incompatibilidade, preservar seleção anterior e explicar o motivo.

**Hipótese técnica a verificar:** o controle guiado poderá usar condição de habilitação, texto de motivo e um caminho de ação no qual a guarda seja avaliada antes do despacho. A propriedade Enable Condition não prova atomicidade nem impede ações nativas. Não recomendar cascata com parâmetros que precisariam ser recalculados após ação anterior sem validar o comportamento descrito em DOC-C2-01.

### B. Ação nativa (após a mutação)

**Decisão semântica já aprovada:** não prometer prevenção global. Cada indicador deve interpretar o contexto real, e não uma variável proposta ou valor anterior, para decidir entre resultado disponível ou mensagem de indisponibilidade.

**Hipótese técnica a verificar:** condições de cálculo por gráfico, avisos e expressões dependentes da seleção podem impedir que um número inválido continue aparecendo como válido. Isso requer avaliação explícita de estado A0/A1, filtros P5, ano, competências e cobertura, e não somente uma expressão genérica que conta seleções.

### C. Estado alternativo A1

**Invariante:** manter A0 como padrão e A1 apenas em P2.3. Clear, Back/Forward, bookmarks e ações específicas de estado devem ser testados para evitar efeitos inesperados. Não ampliar a ilha A1 por conveniência.

## 4. Matriz mínima proposta para a especificação física C2

| Cenário | Resultado semântico esperado | O que o teste deverá demonstrar | Situação documental |
| --- | --- | --- | --- |
| Proposta guiada válida | Seleção efetiva aplicada e confirmada | Pré-validação e reconciliação do estado real | Mecanismos candidatos identificados; **NÃO TESTADO** |
| Proposta guiada conflitante com ano real | Nenhuma mutação; aviso de motivo | Valor anterior permanece; botão/ação não dispara antes da guarda | **NÃO TESTADO** |
| Proposta guiada fora do domínio ou cobertura | Nenhuma mutação; causa explícita | Impedir despacho inclusive com múltiplas ações | **NÃO TESTADO** |
| Mudar de anual para evolução no mesmo ano | Não fabricar mudança de seleção | Diferenciar estado proposto do aplicado e exibir série correta | **NÃO TESTADO** |
| Seleção nativa deixa KPI anual pontual com múltiplos anos | KPI pontual indisponível; série anual dimensionada pode continuar válida | Revalidação **por indicador**, não veto genérico a multi-ano | **NÃO TESTADO** |
| Seleção nativa de meses não consecutivos | Período parcial reconhecido e descrito | Não apresentar período parcial como ano completo | **NÃO TESTADO** |
| Menu Clear/Back/Forward; busca; listas; gráficos | Revalidar indicadores segundo estado efetivo | Nenhum resultado inválido/obsoleto continua rotulado como válido | **NÃO TESTADO** |
| Importar/restaurar bookmark | Revalidar contexto após seleção | Checar impacto em todos os estados aplicáveis | **NÃO TESTADO** |
| A0 com ilha A1 em P2.3 | Isolamento conforme blueprint | Mostrar estados, selecionar e limpar sem contaminação inesperada | **NÃO TESTADO** |
| Cobertura CNES/LT, POP e P5 | Indisponível quando falta comprovação; nunca zero artificial | Respeitar contratos científicos C3/C4 e T25/T26 | **DEPENDENTE DE OUTROS GATES** |

Esta matriz é **proposta documental** para um ensaio futuro e não autorização para executá-lo.

## 5. Pendências objetivas, sem repetir PoCs anteriores

1. Verificar versão exata do QlikView Desktop instalado e registrar a evidência do binário. Comparar docs da build antes de escolher propriedade ou método COM.
2. Preparar, **sob autorização específica**, um único contrato físico mínimo `C2_GUIDED_R2`, reutilizando oráculos e provas dos PRs #201, #205, #208 e #210. Não reproduzir indiscriminadamente os testes já concluídos.
3. Definir como inspecionar os resultados após seleção nativa por indicador, incluindo mensagem explícita de indisponibilidade. Um resultado `COM_PASS` não é aceitação de KPI.
4. Após C2 apropriado, prosseguir na ordem **C3 → C4 → GO formal IX → três painéis**, sem adiantar contratos cross-fact ou produção.
5. Manter controle de proveniência e anotar se algum link de setembro de 2026 não corresponder à build efetiva; nesse caso, a conclusão associada será `VERSION_UNVERIFIED`.

## 6. Critérios de encerramento da Discovery documental

- **PASS documental:** fontes oficiais por comportamento, impacto específico D2-R2, hipóteses separadas e matriz de testes futuros definida.
- **BLOCKED físico:** ausência de build local verificável ou comportamento não testado; não promove contrato a homologado.
- **STOP:** este documento e PR são **somente documentação**. Não alterar regras D1/D3-D8, P1-P5, três fatos/oito dimensões, `DIM_TEMPO`, `LINK_ANALISE`, scripts, QVDs, QVWs, executores, gates ou `current-state.md`. Não mergear sem autorização.

**Veredito:** `DOCUMENTARY_REVIEW_COMPLETE` / `PHYSICAL_PROOF_NOT_PROVIDED`.