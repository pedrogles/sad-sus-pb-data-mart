# Fase VIII — C2-D: viabilidade de prevenção D2 antes da seleção na UI QlikView 12 (19/10/2026)

> **Nota de integração documental (20/10/2026):** cópia seletiva do documento produzido no [PR #121](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/121) (`a83a0d079d88`). Status, baseline e referências à condição Draft abaixo são **históricos**. Esta publicação não integra o runner do PR, não reedita os testes e não homologa contratos, interface ou produção.

**Estado:** `C2D_READONLY_FEASIBILITY=COMPLETED_WITH_LIMITED_CANDIDATE`; `C2D_NATIVE_POST_SELECT_TRIGGERS=NO_GO_FOR_PREDISPATCH`; `C2D_CONTROLLED_BUTTON_UI=CANDIDATE_NOT_TESTED`; `P5_D2_UI=NOT_TESTED`; `C2_FULL=NOT_APPROVED`; `PRODUCTION_APPROVED=False`. **Somente revisão documental, PR Draft. Sem QVW/QVD, script ou merge alterado.**

## 1. Objetivo, fontes e baseline

**Objetivo único:** encontrar uma implementação física defensável do requisito **D2**: impedir que uma proposta de seleção de ano incompatível com a competência (ou competência incompatível com ano) altere ou descarte silenciosamente a seleção atual, **antes do despacho da proposta**. Distinguir o comportamento de triggers pós-seleção, objetos de lista e controles nativos, sem executar um novo QVW nesta revisão.

**Fonte de verdade:** `main@337943d5c5b77067f842902fc679dbb68db87020`, lidos em ordem `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → `docs/discovery/boundary-7-implementation-plan.md` → `docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md` (§62.2, §62.4, §62.6) → `docs/project/qlikview-powershell-automation.md` → closeout VIII PR #115 e evidências Draft C1/C2 (#116–#120).

**Evidência técnica anterior reutilizada:** o preflight D2 `tools/validar_f4_preselecao_d2_qlik.ps1` do commit histórico congelado `26369052bd3f96de5f3eccf873c390053c20b561`, o runner T24 `tools/Invoke-SadPhaseViiiT24MonthlyPredispatch.ps1` no PR #111 Draft e o runner C2-A no PR #117 Draft. Seus cenários de conflito tinham **`DISPATCHED=False` no wrapper**, não um bloqueio nos cliques do usuário. Não repetir os quatro casos do wrapper nem inferir que o QVW passou D2.

**Fontes oficiais QlikView utilizadas na revisão READ-ONLY (documentação geral das versões May 2024 / 2025 para QlikView 12; a instalação específica não foi testada nesta etapa):**

1. [QlikView — Document Properties: Triggers](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Document_Properties_Triggers.htm): `OnAnySelect` executa depois que uma seleção foi feita no documento; `OnSelect` depois da seleção no campo. `OnChange` reage ao estado lógico; **não há prova de trigger pre-select cancelável** nessas definições. A página alerta que ações encadeadas são não suportadas e que macros apresentam limitações em QlikView Server.
2. [QlikView — Invoking macros](https://help.qlik.com/en-US/qlikview-developer/May2024/Subsystems/Automation/Content/QV_Automation/automation-invoke-macro.htm): documenta disparo de macros nos eventos `OnAnySelect`, `OnSelect` e `OnChange` **depois** dos eventos de seleção. Prefere `Actions` a macros quando ações são suficientes.
3. [QlikView — List Box](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/List_Box.htm): `Read Only` impede selecionar **naquele objeto** de lista, mas o objeto continua refletindo seleções feitas em outro lugar; `Always One Selected Value` modifica o modelo de dados e pode afetar bookmarks — não adotá-lo inadvertidamente.
4. [QlikView — Button Properties / Enable Condition](https://help.qlik.com/en-US/qlikview/September2025/Subsystems/Client/Content/QV_QlikView/Button2.htm): a expressão `Enable Condition` habilita (`1`) ou desabilita (`0`) o botão. Verificar no QlikView Desktop local a disponibilidade dessa propriedade antes de implementar.
5. [QlikView — Button / Actions](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Ajax/WebView_Button.htm) e [QlikView — Actions](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Actions.htm): `Select in Field` permite ações explícitas de seleção disparadas por botão. Ações múltiplas podem ser tratadas por threads separadas, sem garantia de ordem de conclusão; não construir proteção D2 dependente de duas ações concorrentes `Clear Field` + `Select in Field`.

## 2. Matriz de decisão — fato, capacidade e limite

| Mecanismo | Evidência | Conclusão restrita |
| --- | --- | --- |
| `OnAnySelect`, `OnSelect`, `OnChange` | Documentação Qlik: eventos observam seleção já efetuada/estado mudado | **NO-GO** como prova de prevenção **antes** da seleção; limpar/voltar após o evento não preserva necessariamente a intenção e histórico |
| `Read Only` na lista `PERIODO_ANO` ou `PERIODO_COMPETENCIA` | Bloqueia clique nessa listbox específica; seleções de outros objetos continuam sendo refletidas | **Controle local de acesso à listbox** candidato; **não** bloqueio de campo universal (search, ações, outros objetos, bookmarks) |
| Botão com `Enable Condition=0/1` | Documentação oficial descreve estado desabilitado/habilitado; ação de seleção disponível | **CANDIDATE_ONLY** para um **único caminho controlado** de proposta, desde que bloqueio seja exibido antes de clicar, sem `Select in Field` despachado |
| `Always One Selected Value` | Pode alterar data model e bookmarks, não codifica incompatibilidade entre dois campos | **NO-GO neste gate**, não alterar modelo |
| `Calculation Condition` / Set Analysis em T24–T26 | Protege exibição depois de um contexto existente | **Insuficiente** para D2: pode ocultar um conflito já aplicado |
| Macro de rollback acionada por trigger | Executada após seleção e sujeita a limitações | **NO-GO** para cumprir literalmente requisito D2; não testar sem novo contrato |

**FATO VERIFICADO:** o contrato V2 `D2=B` exige `prevenir conflito ano/competencia antes de descartar a intencao de selecao`. Nenhum dos PRs #110–#120 contém evidência de interceptação real da proposta pelo usuário na UI. O projeto não pode ser declarado `P5_D2_UI=APPROVED` por PASS de PowerShell wrapper, eventos após seleção, COM `EvaluationCondition` ou screenshots estáticos de KPI bloqueado.

**HIPÓTESE DE ENGENHARIA:** um **objeto de proposta** (botão de seleção único com `Enable Condition` calculada a partir do estado corrente) **pode** impedir o clique *nesse botão* quando `PERIODO_COMPETENCIA` já pertence a outro ano, sem precisar implementar macro pós-seleção. Um botão análogo para competência pode bloquear mês de ano diferente quando um ano está selecionado. Um texto condicional independente deve explicar explicitamente o motivo, sem substituir a ação por `Clear All`.

**LIMITAÇÃO CRÍTICA:** desabilitar dois botões não prova que o **campo inteiro** está protegido. A UI QlikView possui seleções por listas, buscas, bookmarks e demais ações. O gate seguinte deve demonstrar que **todas as rotas de alteração expostas no protótipo estão sob controle** — ou terminar com `C2D_COMPLETE_UI=NO_GO`; não afirmar isolamento total porque duas ações passaram.

## 3. Menor próximo gate físico viável (NÃO INICIADO)

**Proposta C2-D1 — uma cópia QVW de prova, não novo painel:**

- **Entradas**: congelar o SHA-256 de um QVW TEMP *previamente salvo* como `SAD_C2W_T26_COLUNAS_AJUSTADAS_WRAP.qvw` no computador do responsável, sem expor seu binário no Git; reutilizar apenas dados já carregados. Usar **nova cópia** sob `%TEMP%`, sem recarga e sem tocar nos 22 QVDs/canônicos. **Ainda não foram inspecionadas as propriedades reais de Buttons via COM**, portanto só versionar script após confirmar mecanismo com evidência específica/contrato delimitado.
- **Controle mínimo**: criar no QVW de prova uma forma visível de propor **ano 2019** e outra de propor **competência 201801**. Quando a proposta for incompatível com a seleção temporal atual, o controle deve aparecer indisponível **antes de clicar**, com mensagem visível descrevendo o conflito e o estado anterior; a ação `Select in Field` não pode disparar.
- **Estados de teste permitidos** (somente quatro, nunca extrapolar para P5 global):
  - **D2-1:** ano atual `2019`, proposta mês `201801` → botão mês desabilitado, seleção ano 2019 preservada, nenhum `Select in Field` disparado.
  - **D2-2:** mês atual `201801`, proposta ano `2019` → botão ano desabilitado, mês 201801 preservado.
  - **D2-3:** ano atual `2018`, proposta mês `201801` → botão habilitado, seleção mês admissível e ano 2018 preservado.
  - **D2-4:** mês atual `201901`, proposta ano `2019` → botão habilitado, ano 2019 admissível sem descarte do mês.
- **Integridade**: SHA pré/pós de QVW origem, QVDs 22 e QVWs canônicos; captura antes/depois da proposta; registrar seleção através de `GetFieldSelections()`/contagem e, quando possível, log do despacho. Não repetir C2-W, C2-V, T24–T26, oráculos F1/F2, CNES.
- **Critério de aceitação restrito**: `C2D_BUTTON_ROUTE_PRESELECTION=PASS_CANDIDATE_ONLY` só se o próprio controle **desabilitar antes do clique**, preservar seleção sem chamar action nos dois conflitos, e executar seleção nos dois casos permitidos, com **revisão real de imagens e COM**. Se propriedades não existirem, ações ainda puderem ser disparadas, ou houver rotas diretas não controladas, `C2D_UI=BLOCKED/INCOMPLETE`, não reinventar mecanismos em loop.
- **Mesmo um PASS desses quatro cenários** aprova no máximo o caminho **controlado por botão**, **não** o UI completo, porque é necessário revisar o acesso a filtros nativos e fluxos alternativos; `P5_D2_UI=NOT_TESTED` / `C2_FULL=NOT_APPROVED` não mudam automaticamente.

**Não executar manualmente um clique contraditório na listbox ano/mês do QVW de evidência anterior** para tentar "ver o que acontece"; o risco semântico já foi documentado no wrapper e o objetivo seguinte é provar uma proposta controlada *antes* do efeito.

## 4. STOP desta Discovery e dependências

**Entrega realizada:** leitura da `main`, V2, Boundary 7, closeout C1/C2, PRs de C2-W e os executores de D2 anteriores; pesquisa oficial dos mecanismos nativos e uma decisão explícita:
- `C2D_NATIVE_POST_SELECT_TRIGGERS=NO_GO_FOR_PREDISPATCH`;
- `C2D_CONTROLLED_BUTTON_UI=CANDIDATE_NOT_TESTED`;
- `C2D_READONLY_FEASIBILITY=COMPLETED_WITH_LIMITED_CANDIDATE`.

**Próximo trabalho admissível exige gate físico versionado separado**, idealmente após disponibilizar no local o SHA da cópia `WRAP` e confirmar a API de botões/condições da versão instalada. **Não** implementar por tentativa e erro com COM e não promover PRs Draft para a main. **C3 (Link Table contratual) e C4 (medidas/readiness)** seguem a ordem aprovada depois de resolver/documentar limites reais de C2; Fase IX não autorizada.

Permanecem: `C2W_S0_VISUAL_ACCEPTANCE=PASS_RESTRICTED_AFTER_MANUAL_ADJUSTMENTS`; `C2W_S1_WRAP_COPY=NOT_TESTED`; `C2_FULL=NOT_APPROVED`; `P5_D2_UI=NOT_TESTED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `T26_GENERAL=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.