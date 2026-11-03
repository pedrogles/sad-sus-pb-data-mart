# SAD — R2 | Avaliação formal de eventual revisão semântica D2

**Gate:** `SAD-C2-D2-R2-SEMANTIC-REVIEW-01`  
**Data:** 03/11/2026  
**Baseline:** `main@59dc80a4db24f8ada257e9354e464f3393bfcab6`  
**Autorização recebida:** **avaliar formalmente a revisão R2**. Não há aprovação para alterar a V2, o modelo, QVW/QVD/QVS, executar testes ou fazer merge.  
**Resultado da avaliação:** `R2_SEMANTIC_EVALUATION=PASS_DOCUMENTAL_WITH_EXPLICIT_DELTA`; `R2_CHANGE_APPROVAL=PENDING_OWNER_EXPLICIT_DECISION`; `D2_V2_B=STILL_EFFECTIVE`; `C2_FULL=NO_GO_NOT_APPROVED`. Este documento é **minuta de decisão**, não contrato aprovado.

## 1. Problema e evidência

### 1.1 D2 vigente e escopo exato de alteração

Em [V2 §62.1](phase-6-semantic-v2-approved-2026-10-14.md), o responsável aprovou `D2=B`: **“Prevenir conflito ano/competência antes de descartar a intenção de seleção”**. Em [§62.3](phase-6-semantic-v2-approved-2026-10-14.md), o texto determina expressamente: **“D2 exige prevenção antes da alteração de seleções”**. Isso não delimita a garantia apenas a botões de uma UI guiada.

A [avaliação R2](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6610288918) e o [estudo B2](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/211) concluíram que, no QlikView Desktop utilizado pelo operador, o controle preventivo global **não foi demonstrado**. A [inspeção da QVW TEMP](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6609988083) comprovou (por capturas) flags `Read Only` em `LB01/LB04` e condições/ações de `BU15/BU16`, mas constatou menus de seleção disponíveis, bookmarks importáveis e demais rotas ainda sem contenção demonstrada. Não houve bypass funcional executado nem teste global.

**O que uma revisão R2 alteraria materialmente:** o nível de garantia de D2, e **não** a semântica temporal dos indicadores. Ela passaria a prevenir conflitos **nas ações guiadas aprovadas**, enquanto **seleções nativas fora dessas ações** seriam aceitas como mutações de contexto que devem ser **revalidadas e sinalizadas**, com supressão de indicadores incompatíveis **depois** da mutação. Logo, não se pode conservar o rótulo `D2=B GLOBAL PASS` ou afirmar que o mecanismo anterior foi tecnicamente solucionado.

### 1.2 Hierarquia, fontes e compatibilidade

Fontes lidas, na ordem: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → [V2 §62](phase-6-semantic-v2-approved-2026-10-14.md) → [C2-G](phase-8-c2g-temporal-selection-design-decision-2026-10-21.md) → [desenho guiado](sad-c2-guided-dynamic-control-design-2026-10-30.md) → [Boundary 6](boundary-6-qlikview-physical-architecture.md) e [Boundary 7](boundary-7-implementation-plan.md) → [blueprint aprovado](../project/three-panels-blueprint-approved-2026-11-03.md) → [B2 do PR #211](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/docs/sad-c2-temporal-physical-redesign-b2-20261103/docs/discovery/sad-c2-temporal-physical-redesign-b2-2026-11-03.md).

O [resumo operacional dos requisitos acadêmicos](../academic/requirements.md) exige QlikView, três painéis e modelagem dimensional, **mas não registra D2 como exigência autônoma atribuída ao professor**. Isso não equivale a uma verificação de todos os materiais e critérios de avaliação do docente; se houver exigência externa de prevenção global, a revisão interna não poderá dispensá-la.

Documentação QlikView oficial [Selections menu](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Selections_menu.htm), [List Box](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/List_Box.htm), [Button](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm) e [Alternate States](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Alternate%20States.htm): comandos nativos de seleção, `Read Only` local, habilitação de botão e operações sobre estados são mecanismos distintos. O QlikView observado foi `12.0.20000.0`, **mais antigo** que os manuais September 2026. Compatibilidade de um detalhe não inspecionado permanece `UNKNOWN`.

## 2. Proposta de redação semântica — NÃO APROVADA

### 2.1 Delta normativo explícito, sem reescrever a V2 original

| Referência | V2 vigente | Minuta R2 sujeita a aprovação |
|---|---|---|
| §62.1 — `D2=B` | Prevenir conflito ano/competência antes de descartar intenção da seleção | **`D2-R2=GUIDED_PREVENTION_PLUS_NATIVE_VALIDATION` (novo contrato, não reclassificado como B):** a aplicação de propostas pelos controles guiados deverá ser validada **antes** de modificar campos; operações nativas fora desse fluxo **não têm garantia de prevenção prévia** e devem acionar reavaliação do contexto realmente selecionado e bloqueio de apresentação incorreta |
| §62.3 — sentença D2 | “D2 exige prevenção antes da alteração de seleções.” | **Substituição proposta, se aprovada:** “No fluxo guiado oficial, conflitos ano/competência devem ser detectados e impedidos antes do despacho de qualquer ação de seleção. Em rotas nativas do QlikView Desktop não cobertas por esse fluxo, a aplicação não garante prevenção anterior à mudança; deve reconhecer imediatamente o contexto real resultante, não considerar proposta como seleção efetiva, sinalizar contexto ambíguo/incompatível e tornar indisponíveis os indicadores para os quais a combinação não é semanticamente válida. Esse tratamento não é equivalente a bloqueio pré-despacho global.” |
| Evidência/aceite | `C2_FULL` exige cobertura global conforme o projeto | Criar **gate distinto** `C2_GUIDED_R2`, com PASS restrito condicionado a testes físicos. Manter `C2_FULL_V2=NO_GO` como registro de não atendimento à garantia V2 original; não falsificar ou apagar as evidências históricas |
| P5 | Matriz `C/R/I/B` já aprovada | **Sem alterações**; um filtro `B` ou `R/I` não aprovado continua impedindo o indicador geral |
| Data Mart | Três fatos, oito dimensões, Link Table/roles, grãos aprovados | **Sem alteração nesta revisão**; qualquer adaptação física exige outro gate/aceite |

**Semântica temporal V2 §62.3 preservada em R2:** período parcial é parcial; meses não consecutivos são enumerados; séries de dois ou mais anos são separadas por ano sem somar POP; KPI pontual anual com múltiplos anos ou sem referência inequívoca é indisponível; `DT_INTER` e `DT_SAIDA` não se tornam competência SIH/RD. Portanto **não** declarar todo contexto nativo com múltiplos anos inválido: ele pode ser válido para *séries por ano*, mas não para *KPI anual único*.

### 2.2 Fronteira de produto proposta

**Fluxo guiado oficial, contrato candidato:** propostas `MENSAL`, `ANUAL` e `EVOLUCAO` editam somente variáveis até a ação explícita de aplicar. Conferir domínio/competência existente, estado real atual e compatibilidade com o indicador e com P5 **antes** de despachar. Em conflito, não despachar nem descartar intenção; comunicar o motivo. Ações `Clear All`, `Unlock and Clear All`, cadeia de `Clear+Select`, bookmarks, trigger ou rollback **não** são substitutos implicitamente autorizados. Uma transição entre períodos já selecionados precisa de UX aprovada que não limpe silenciosamente outros filtros.

**Rotas nativas:** continuam reconhecidas, não falsamente “desabilitadas”. Ações por menu/atalho, busca, seleções de gráfico/lista/tabela, restauração/importação de bookmark, outros botões e estado de seleções podem mudar o contexto. Após qualquer alteração, **cada indicador** deve consultar o contexto **real**, não o valor proposto. Se o contexto for incompatível ou insuficiente para aquele indicador, não exibir um resultado antigo ou calculado ignorando o filtro: exibir **Indisponível** com motivo apropriado. Contextos nativos válidos podem ser exibidos **somente conforme a regra semântica do indicador e filtros P5**.

**Garantia conscientemente não oferecida no R2:** prevenir toda alteração de seleção nativa incompatível antes que o QlikView a efetive. A ausência de atraso ou race condition na atualização de visuais **ainda precisa prova** na versão `12.0.20000.0`; sem essa prova, `C2_GUIDED_R2=NOT_APPROVED`.

**Modalidade acadêmica/usuário:** referência de apresentação proposta é QVW no Desktop 12. O usuário pode interagir diretamente com comandos do cliente; não declarar o documento “sandbox” nem propor controle de acesso inexistente. Se o professor exigir D2 global como teste, preservar `NO_GO` em vez de atribuir ao R2 uma garantia ausente.

## 3. Matriz de aceite futuro — caso o responsável escolha R2 formalmente

Esta matriz é **contrato candidato de teste**, não conjunto de PASS físicos. Reutilizar evidências já válidas e executar somente deltas ainda sem prova em gate futuro autorizado.

| Cenário de consumo | Comportamento exigido na proposta R2 | Estado de prova |
|---|---|---|
| Propor `ANUAL/2019` sem seleção explícita e filtros compatíveis | Validar e aplicar um ano real; apresentar leitura correta de `PERIODO_ANO=2019`, sem competência explícita | `BU15` PASS positivo **restrito** no PR #201; não atesta outras transições |
| Propor `MENSAL/201801` com `PERIODO_ANO=2019` real | **Desabilitar antes da ação**; seleção real anterior não alterada; exibir motivo | `BU16` guarda 1→0 **restrita**, sem clique/sem prova geral |
| Alterar a proposta para ano/mês inexistente, inválido ou incompatível P5 | Não despachar; explicar motivo e preservar seleção real | `NOT_TESTED` |
| Trocar `ANUAL` ↔ `EVOLUCAO` no mesmo ano real | Não simular troca física nem esconder divergência; guiado 12 meses ≠ histórico fixo 36 | `CH02` 36/36 e `CH03` 2019 12/12 restritos; integração/UX pendente |
| Seleção nativa deixa período real sem referência | KPI anual pontual **Indisponível**; série anual sem filtro somente quando dimensão+regras permitirem | `NOT_TESTED` na QVW final |
| Seleção nativa cria ano real ambíguo / múltiplos anos | KPI pontual anual **Indisponível**; série por ano permitida, sem soma de POP | `NOT_TESTED` |
| Seleção nativa de meses não consecutivos no mesmo ano | Identificar competências reais não consecutivas e razão parcial; não anualizar | `NOT_TESTED` |
| Alteração nativa envolvendo filtros P5 `B`, `I`, `R` | Indisponibilidade ou isolamento **explícito e fisicamente validado**, não ignorar filtros | `P5_D2_UI=NOT_TESTED_GLOBAL` |
| Menu `Clear/Back/Forward`, busca e bookmarks | Reavaliar contexto real; qualquer KPI incompatível não pode mostrar valor antigo como válido | `NOT_TESTED`; superfícies observadas/descritas, não validadas funcionalmente |
| Snapshot LT anual / POP anual | Média de snapshots válidos, POP única por município×ano; sem somatórios temporais incorretos | `C3/C4` não aprovados |
| Ilha P2.3 | `P23_MUNICIPIO_6/P23_COMPETENCIA` continuam locais sem confusão com seleção temporal global | `NOT_APPROVED` |
| Três painéis finais | Layout aprovado P1/P2/P3 preservado, mensagens de estado, contexto proposto e aplicado explícitos | Blueprint aprovado, implementação `NOT_AUTHORIZED` |

**Critérios de aceitação de uma futura implementação R2:** guardar estado de seleção real antes/depois para ações guiadas; não despachar quando guardas falham; em eventos nativos relevantes, não publicar números antigos ou semanticamente incorretos; demonstrar texto de indisponibilidade contextualizado; reconciliar o número publicado com oráculos existentes; não esconder filtros incompatíveis com Set Analysis. **PASS somente com QVW e evidência física verificável na versão instalada**, em branch/runner versionados previamente e fonte/cópia protegidas.

**STOP técnico:** não aplicar a proposta via edição da V2 ou botão agora; o exercício R2 está encerrado quando esta matriz e o delta estiverem revisados.

## 4. Trade-off da decisão e riscos residuais explícitos

| Alternativa de decisão do responsável | Benefício | Custo e compromisso |
|---|---|---|
| **R2-A — Aprovar formalmente o contrato D2-R2 guiado + validação nativa** | Fluxo acadêmico potencialmente implementável sem modificar a `LINK_ANALISE`, as fatos e as dimensões | **Redução material de garantia**: não se previne toda seleção nativa antes da mutação; ainda exige prova de apresentação segura, filtros, cobertura e integração. Exige adendo semântico/aceite formal e só depois gate de implementação |
| R2-B — Rejeitar a mudança e manter `D2=B` V2 original | Conserva garantia já aprovada e semântica preventivo-global | `C2_FULL=NO_GO`; Fase IX continua bloqueada; só avançar com novo mecanismo comprovado |
| R2-C — Adiar a decisão para alinhamento acadêmico | Evita divergência com exigência do professor se existir | Não desbloqueia o C2 e posterga a programação da entrega |

**Recomendação técnica:** apresentar **R2-A como proposta de compromisso explícito**, por ser compatível com o comportamento disponível no Desktop sem exigir o redesenho de uma Link Table como falsa solução de navegação. **Não declarar R2-A tecnicamente aprovado:** as provas de validação nativa/indicadores ainda faltam. Se a prevenção global for inegociável, recomendar R2-B, sem prometer que uma nova PoC será suficiente.

**Separação institucional:** a alteração seria uma **decisão do responsável pelo projeto** e deverá ser versionada como **adendo V3 específico de D2** depois do aceite; não deve reescrever a transcrição imutável de 14/10/2026, nem representar um parecer do professor. D1, D3–D8, P1–P5 e RN01–RN21 ficam intactos.

## 5. Requisitos do aceite formal futuro (ainda pendente)

Para um aceite **inequívoco**, exigir manifestação específica do responsável distinguindo **aprovação da revisão semântica R2-A** de simples aprovação de estudo/PR. A minuta de decisão é:

> **“Aprovo a substituição do D2=B da V2, apenas quanto à garantia de prevenção global, por D2-R2: prevenção antes do despacho nos controles guiados e validação/bloqueio de indicadores incompatíveis após mudanças por rotas nativas do QlikView Desktop. Reconheço expressamente que essas rotas nativas não possuem prevenção global comprovada. Não altero D1, D3–D8, P1–P5, modelo dimensional, fatos, grãos ou blueprint; implementação, C3/C4 e Fase IX continuam sujeitos aos próprios gates.”**

Sem esse aceite (ou formulação materialmente equivalente), **não criar V3**, não alterar V2, não fazer merge da minuta em `main` como norma vigente e não promover `C2_FULL`.

Se aprovada, o **próximo trabalho independente** será um PR documental de adendo V3 para D2, com checklist de implementação e indicadores de estado separados:
- `D2_V2_GLOBAL=SUPERSEDED_BY_EXPLICIT_SEMANTIC_DECISION` **somente após aceite e integração do adendo**, não antes;
- `C2_GUIDED_R2=NOT_TESTED` até gate de validação física;
- `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

O fechamento de `Issue #196` deve representar a resolução do **gate revisado**, não apagar o fato de que o gate V2 original não obteve PASS. O PR Draft e sua integração documental são independentes do aceite semântico.

## 6. Resultado deste gate e STOP

**FATO VERIFICADO:** V2 §62.1/62.3 exige prevenção anterior à mutação; `BU15/BU16` e `LB01/LB04` têm provas restritas; o Desktop oferece rotas nativas sem contenção global comprovada; B2 encontrou risco material em alterar modelo sem resolver a fronteira de seleção.

**HIPÓTESE DE DESIGN:** a mudança R2-A pode oferecer UX com navegação guiada segura e supressão explícita de indicadores inválidos após seleção nativa, mantendo o Data Mart inalterado, mas falta comprovação de implementação e confiabilidade visual.

**DECISÃO PENDENTE:** aceitar **formalmente e conscientemente** R2-A (redução de garantia), rejeitar R2-B ou adiar R2-C. Aprovar esta Discovery **não** equivale a aceitar a revisão.

**Estados inalterados:** `R2_SEMANTIC_EVALUATION=PASS_DOCUMENTAL_WITH_EXPLICIT_DELTA`; `R2_CHANGE_APPROVAL=PENDING_OWNER_EXPLICIT_DECISION`; `D2_V2_B=STILL_EFFECTIVE`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP:** um documento novo de proposta formal, PR Draft, registro de decisão na Issue #196; zero QVW/QVD/QVS/QlikView/COM/PowerShell/PoC, zero edições da V2 ou do `current-state.md`, zero merge; **C2 → C3 → C4 → GO Fase IX → três painéis** preservada.
