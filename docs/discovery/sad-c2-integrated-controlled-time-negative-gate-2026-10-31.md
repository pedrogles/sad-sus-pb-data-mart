# SAD C2 — Interface temporal controlada A e menor gate negativo pré-despacho

**ID documental:** `SAD-C2-INTEGRATED-CONTROLLED-TIME-DESIGN-01`  
**Gate físico FUTURO (não executado):** `SAD-C2-INTEGRATED-PREDISPATCH-NEGATIVE-POC-01`  
**Estado:** `OPTION_A_EXPERIMENTAL_DIRECTION_ACCEPTED_IN_CHAT / DESIGN_READY_FOR_REVIEW / PHYSICAL_NOT_AUTHORIZED / GLOBAL_NO_GO`.  
**Base lida:** `main@2cc197d5310f5fbd65585df9084346fcd4f402a0`, depois do merge específico do PR #206.  
**Autorização:** o responsável respondeu "prossiga" à recomendação de escolher A como **desenho experimental integrado** e preparar o menor gate físico, **não** aprovou alteração de QVW canônico, execução física, merge, redução de D2/P5 ou uso em produção.  
**Agente / ambiente:** GPT-6 + GitHub para revisão e documentação; para implementação futura, Codex Local Windows com QlikView 12, se realmente disponível, ou operador humano (fallback). A ajuda oficial do QlikView Setembro/2026 foi consultada; não há leitura de GUI/COM ou QVW/JSON físico nesta Discovery.

## 1. Objetivo, problema e STOP

**Objetivo único:** projetar **uma interface de proposta temporal controlada** para MENSAL/ANUAL/EVOLUCAO e **uma prova negativa mínima** de que uma proposta `MENSAL/201801` é bloqueada **antes** de qualquer `Select in Field` quando `PERIODO_ANO=2019` já está aplicado, preservando o estado real. A futura prova é **apenas da rota por um botão** e da consistência da QVW de destino; não homologa D2 global.

**STOP deste documento:** decisão A **para experimento**, matriz de evidência/lacuna, contrato de comportamento e protocolo do futuro único ensaio. Não criar runner, não copiar/abrir QVW, não executar verificação de Windows, não escrever QVD/QVW/QVS, não mudar `current-state.md`, não avançar C3/C4/IX, não fazer merge nem encerrar issue. O próprio piloto físico exigirá aprovação específica com preflight/pins.

## 2. Autoridades e provas aproveitadas sem reexecução

- [AGENTS](../../AGENTS.md) → [current-state](../project/current-state.md) → [requisitos](../academic/requirements.md) → [Boundary 7](boundary-7-implementation-plan.md), [V2 §62.3 e §62.6](phase-6-semantic-v2-approved-2026-10-14.md).
- [C2-D](phase-8-c2d-d2-ui-predispatch-feasibility-2026-10-19.md), [C2-F](phase-8-c2f-physical-selection-route-inventory-2026-10-21.md), [C2-G](phase-8-c2g-temporal-selection-design-decision-2026-10-21.md), [C2-H](phase-8-c2h-readonly-listbox-physical-pilot-2026-10-21.md), [C2-I](phase-8-c2i-residual-temporal-selection-closure-2026-10-21.md), [C2-J](phase-8-c2j-guided-real-selection-p5-2026-10-22.md), [C2-K](phase-8-c2k-guided-annual-evolution-pilot-2026-10-22.md) e [desenho dinâmico](sad-c2-guided-dynamic-control-design-2026-10-30.md).
- [PR #201, BU15 (MERGED)](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201), [PR #203, observação CH02 (Draft)](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/203), [PR #204, proposta de visual separado (Draft)](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/204), [PR #205, gráfico guiado 12/12 (Draft)](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205) e [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196).
- Documentação oficial QlikView Setembro/2026: [Read Only em List Box](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/List_Box.htm), [Button — Enable Condition](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm), [Actions / Select in Field](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Ajax/WebView_Button.htm), [Selections menu](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Selections_menu.htm) e [Bookmarks](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Bookmarks.htm). **Capacidades gerais da aplicação não provam que cada rota existe/funciona na QVW concreta.**

### Evidência com proveniência separada

| Evidência | Resultado válido | Limite |
| --- | --- | --- |
| #201 | BU15 aplicou ano real 2019 (1), competência explicitamente selecionada (0) | Única rota e execução Windows reportada |
| #205 | NOVO gráfico exibe `201901..201912`, 12/12 valores iguais ao oráculo de P1.2, total 188.246; runner Verify reportou fonte + 25 canônicos preservados | Visual/valor restritos; não prova D2 pré-despacho |
| C2-H | Mitigação local em listas `LB01`/`LB04` com `Read Only` e prova limitada | A cópia **do C2-H é diferente** da QVW do #205. Não assumir propriedades transplantadas |
| C2-I | Menus Seleções, Marcadores, busca e outras entradas foram documentados como superfícies visíveis/efeito desconhecido | Nenhum bypass específico comprovado, nenhuma proteção global |
| C2-K | MENSAL/201801 → ANUAL/2019 e EVOLUCAO/2019, preservando contexto, num QVW histórico | Não prova estado/ações da QVW do #205 |
| V2 §62.3 | **Previne conflito entre ano e competência antes do despacho** e preserva intenção | Guarda de cálculo que oculta KPI após conflito NÃO satisfaz D2 |
| V2 §62.6 | Matriz P5 de classes C/R/I/B por indicador | KPI P5 global NÃO testado; depende também de medidas C4 |

## 3. Decisão de produto e arquitetura: alternativa A, SÓ experimental

**Aceito como direção de protótipo:** uma superfície visível de *proposta* e um botão de *aplicação* que validam antes de despachar alterações nos campos reais; seleção efetiva é lida do estado associativo QlikView, **não** derivada de variáveis de proposta. Manter MENSAL (uma competência `AAAAMM`), ANUAL (um ano real e zero competência explícita) e EVOLUCAO (mesmo ano real e visual de 12 competências), conforme [desenho de C2](sad-c2-guided-dynamic-control-design-2026-10-30.md). O modo de proposta não converte sozinho a seleção real.

**Trade-off:** controlar um botão é implementável e mensurável, porém **não** intercepta por si só menús nativos, bookmarks, busca, outros objetos ou ações de terceiros. A Qlik confirma que `Read Only` impede seleção **naquela lista** mas aceita seleções feitas em outro ponto, que `Selections → Back/Forward/Clear` altera contexto, e que bookmarks restauram seleções. Portanto, **nenhuma prova de uma rota habilita `D2_GLOBAL=PASS`** sem o mapa final de entradas e sua política de controle.

**Não aprovados neste gate:** novos campos/dimensões, mudança de V2, uso de triggers/rollback pós-seleção como prevenção, limpeza em cascata, `Always One Selected Value`, locks de campo como atalho, conversão de todas as seleções Qlik para "pré-despacho", exclusão de funções nativas sem prova, ou suposição de capacidade de suprimir menus.

## 4. Contrato funcional mínimo da superfície controlada

| Condição | Resultado exigido |
| --- | --- |
| `PERIODO_ANO=2019` real (Qtd 1); competência real Qtd 0; modo `MENSAL`; ano proposto `2018`; mês `1` | **Bloquear antes da ação**, não disparar seleção `201801`, manter `PERIODO_ANO=2019` e demais seleções reais, exibir motivo incompatibilidade entre proposta e ano já aplicado |
| Mesmo estado real, modo `MENSAL`, proposta `2019/01` | **Condição do botão candidata deve habilitar** (sanity check) sem executar o clique; isto evita aceitar botão permanentemente desabilitado como "guarda" |
| Ano real não único, seleção de competência residual, proposta inválida ou estado real desconhecido | **Falhar fechado**; não substituir intenção nem fabricar zero; documentar o motivo |
| Seleção via outro menu/bookmark/lista | `UNKNOWN/BLOCKED` até inventário/isolamento demonstrado na **mesma QVW**, não generalizar a prova por botão |
| Indicador sob filtros P5 conflitantes | **Não exibir como aprovado** sem guarda e contrato específico do indicador; problema separado de C2 pré-despacho |

**Condição de habilitação de estudo** — limitada à prova com **um ano real explícito**, sem seleção explícita de competência e `vSAD_POC_Year`/`vSAD_POC_Month` numéricos. Não é a condição definitiva para MENSAL a partir de estado vazio, múltiplos anos ou classes P5. Deve ser confirmada como `Expressão OK` e avaliada **0 → 1** na GUI, com propriedade e diagnóstico visíveis:

~~~qlik
=If(
  '$(vSAD_POC_Mode)'='MENSAL'
  and GetSelectedCount(PERIODO_ANO)=1
  and GetSelectedCount(PERIODO_COMPETENCIA)=0
  and Only(PERIODO_ANO)=Num($(vSAD_POC_Year))
  and Num($(vSAD_POC_Year))>=2017
  and Num($(vSAD_POC_Year))<=2019
  and Num($(vSAD_POC_Month))>=1
  and Num($(vSAD_POC_Month))<=12,
  1,0)
~~~

**Riscos:** se variáveis não numéricas, nulas ou incompatíveis forem introduzidas, a expansão `$(...)` pode gerar expressão inválida. O piloto predefine `2018/01` e `2019/01`, ambos valores conhecidos; **não** promove esta expressão à regra global sem uma validação explícita de entrada/domain/existência da competência. Não assumir que `And` evita avaliação de expressões com expansão malformada. A condição também não substitui P5.

**Ação de estudo**, **nunca executada no cenário negativo**: botão novo, exclusivamente na nova TEMP, com **uma** ação `Selecionar no Campo` no campo **existente** `PERIODO_COMPETENCIA`, proposta numérica `=Num($(vSAD_POC_Year))*100+Num($(vSAD_POC_Month))` (syntax/value a confirmar no editor QlikView). O botão não deve clicar automaticamente, disparar `Clear Field`, mudar ano real, associar bookmark ou apagar filtros. A ação precisa ser **inspecionada**, mas **não disparada** neste gate.

**Mensagem candidata:** `Período não aplicado: a competência 201801 pertence a 2018, mas o ano 2019 está selecionado. Ajuste a proposta ou solicite nova transição controlada.` A estratégia de exibir a mensagem (objeto de texto, condição, formatação) é **decisão física pendente**. Se exigir um segundo objeto no piloto, não adicioná-lo automaticamente; neste gate é suficiente registrar uma **nota de motivo visível no diagnóstico** ou classificar aviso `INCONCLUSIVE`, sem atribuir PASS de UX completa.

## 5. Protocolo físico mínimo futuro — não autorizado automaticamente

**Fonte sugerida, sem assumir compatibilidade real:** QVW TEMP do #205, que **já contém** BU15 e o gráfico P1.2:
- `C:\Users\pedro\Documents\SAD_C2_P12_CHART_RUNTIME\SAD_C2_P12_CHART_4d1f6da0544749b5bb92b4346300c025\SAD_C2_P12_GUIDED_CHART_TEMP.qvw`
- SHA-256 **relatado pelo Verify local**: `C8C3F24DAB56ABEEC0ABD0194A691FD78536BF8F550410E3C609262141A5B917`.
- O candidato deve ser examinado em **READ-ONLY** para confirmar seu estado, controles, variáveis, listboxes e integração. **Não assumir** que as flags C2-H `Read Only` estão nela.

**Preflight/guardas exigidos antes de executar:**
1. Revalidar `main@SHA`, branch dedicada do gate físico, contrato deste documento e autorização específica do responsável; QlikView Desktop 12 no Windows.
2. Verificar SHA de **fonte**, inventário de 22 QVDs + 3 QVWs canônicos, original nunca aberto para salvar, data/estado real ao abrir, worktree limpa e proveniência dos scripts versionados.
3. Preparar **uma cópia completamente nova** da fonte pinada, com manifesto externo ao Git, sem sobrescrever nem reutilizar TEMP #205. **Não usar diretamente runner #205**, pois seus branch/base/sourceSHA foram pinados ao experimento anterior; qualquer executor de preparo/Verify futuro deve ser versão nova previamente commitada e testada, reaproveitando guardas dos existentes sem se declarar genericamente homologado.
4. Se qualquer campo, variável, propriedade/ID/seleção inicial ou condição necessária for incompatível, `BLOCKED`, STOP. Não editar `CH02`, gráfico 12/12, BU15, KPIs, campos, scripts, associações ou canônicos.

**Uma rodada GUI, somente na NOVA TEMP:**
1. Capturar *antes* modo, ano proposto, `ANO REAL`=2019 Qtd 1, `COMPETENCIA REAL`=0, propriedades do novo botão/condição e lista de rotas. Se não houver ano 2019 já persistido, STOP **sem clicar BU15 nem limpar automaticamente**.
2. Propor `MENSAL/2018/01` **somente pelas variáveis existentes**; inserir **um único botão novo** de aplicação de competência com a guarda candidata e a ação única, sem executar a ação. Capturar `Expressão OK`, habilitação **0**, estado real antes/depois idêntico e mensagem/motivo. Se a mensagem não puder ser implementada no limite de um objeto, não alegar UX de bloqueio aprovada.
3. Sem despachar, trocar apenas a proposta de ano para `2019` (mês `01`), confirmar condição **1**; restaurar proposta 2018 e confirmar condição **0**, sem clique no botão em estado habilitado. Isso testa que o bloqueio não é um `disabled` incondicional, mantendo o estado real 2019 inalterado.
4. Salvar **somente nova TEMP** uma vez, fechar QlikView e executar **um único Verify** de integridade; capturas e notas/manifesto externos ao Git. Sem export de gráfico ou reconciliação 12/12 novamente.
5. Se surgir prompt de seleção inesperado, ação disparada ou mudança de campo real, STOP antes de novo click, registrando o problema. Não corrigir neste gate.

**Aceite do piloto:**
- `PASS_RESTRICTED_PREDISPATCH_BUTTON_DISABLE` somente se estado real preservado, propostas 2018/2019 levarem a condição 0/1/0 coerente, botão desabilitado na proposta conflitante, propriedades/única ação inspecionadas, integridade fonte/25 protegidos demonstrada e evidência suficiente.
- `INCONCLUSIVE` se não se consegue afirmar se uma ação foi disparada, se o botão ficou disabled permanentemente, se a proposta não foi explicitada ou se faltarem imagem/manifesto/estado.
- `BLOCKED` no primeiro efeito colateral, campo/variável faltante ou condição inválida; `HARD_STOP_INTEGRITY` em hash/proveniência divergente.
- **Veredito máximo:** `PASS_RESTRICTED_PREDISPATCH_ONE_BUTTON`, **NÃO** `D2_GLOBAL=PASS`, `P5_D2_UI=APPROVED` ou `C2_FULL=APPROVED`.

**Custo/benefício:** uma rodada de condição negativa/positiva *sem novo despacho* é mais barata e segura que uma bateria de menus/bookmarks antes de aprovar a superfície final. **Contudo**, não prova cobertura de rotas nativas: a decisão posterior precisa escolher explicitamente a superfície realmente suportada e a política de acesso a essas rotas, sem reduzir D2 silenciosamente.

## 6. Handoff e estados preservados

1. **Próxima decisão:** revisar/autorizar especificamente o gate físico restrito proposto, com fonte QVW #205/guardas que devem ser revalidadas localmente. A aprovação documental não autoriza o `-Prepare`.
2. **Risco técnico conhecido:** fontes QVW C2-H e #205 são diferentes, embora cada experimento tenha PASS limitado. Nenhum merge visual de seus objetos pode ser presumido; não transplantar flags/ações sem prova.
3. **Risco de escopo:** C2 residual, P5/D2 global, associação Link Key, medidas/denominadores e CNES histórico são contratos distintos; manter ordem física Boundary 7 C2→C3→C4, GO antes da IX.
4. **Evidências:** futuros logs/hashes/QVW/PNG permanecem fora do Git; closeout referencia SHA do executor real. Não inserir oráculos/datasets nos commits.

**Estados finais desta Discovery:** `OPTION_A=EXPERIMENTAL_DIRECTION_ACCEPTED`; `PROPOSED_NEGATIVE_POC=READY_FOR_REVIEW_NOT_EXECUTED`; `C2_P12_2019_12_OF_12=PASS_RESTRICTED`; `C2_PREDISPATCH_GLOBAL=NO_GO_NOT_PROVEN`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
