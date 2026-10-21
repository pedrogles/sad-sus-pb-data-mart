# Fase VIII — C2-G | Decisão técnica candidata de controle temporal D2 (READ-ONLY)

> **Atualização de integração (21/10/2026):** a proposta C2-G foi integrada pelo [PR #147](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/147); a **autorização pontual subsequente** de C2-H permitiu modificar somente `LB01/LB04` na cópia TEMP, encerrada com evidências limitadas e integrada pelo [PR #148](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/148). `C2H_PHYSICAL_MUTATION=NOT_AUTHORIZED` e `NOT_RUN` abaixo são **estados históricos da redação**. A proposta de superfície temporal completa (opção A) **continua não homologada**. Estado vigente: `docs/project/current-state.md`.

**Data:** 21/10/2026. **Fonte operacional verificada:** `main@f49c3d7c66127d9b9f38372ec778019c9d4d5469`.  
**Escopo:** decisão de engenharia e protocolo do próximo teste; **nenhuma mutação em QVW, QVD, UI, scripts QVS/PowerShell ou modelagem**.  
**Estado:** `C2G_READONLY_DESIGN=COMPLETED_WITH_PROPOSAL`; `C2G_OPTION_A=RECOMMENDED_NOT_APPROVED`; `C2H_PHYSICAL_MUTATION=NOT_AUTHORIZED`; `C2_FULL=NO_GO_NOT_APPROVED`.

## 1. Fonte, prova disponível e regra contratual

Ordem lida em `main`: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → Boundary 7 → V2 §62 → C2-E → C2-F integrado pelo PR #146 → C2-D e encerramento de C2. A documentação QlikView (links na seção 6) fundamenta *capacidades gerais* da ferramenta; o comportamento exato nesta instalação só é demonstrado quando executado e capturado.

**FATOS VERIFICADOS em artefatos:** o C2-F inspecionou uma folha `SH01` com 13 objetos (2 botões, 4 listas, 1 tabela simples, 6 textos). Capturas independentes comprovaram que `LB01/PERIODO_ANO` e `LB04/PERIODO_COMPETENCIA` estão **visíveis** e com `Apenas leitura` **desmarcado**. Os arquivos .tab não carregam as propriedades de ação dos botões nem configuram proteção de campo. **Não houve clique conflitante em C2-F:** rota potencial de seleção fora de BU01/BU02 não é sinônimo de bypass funcional testado. Os ensaios C2-D1 anteriores sustentam apenas evidências visuais restritas em dois pares pré/pós e dois casos com captura única e relato. Os testes de wrapper do PR #111 permanecem fora da UI.

**CONTRATO SEMÂNTICO INALTERADO:** V2 §62.3 determina evitar conflito entre `PERIODO_ANO` e `PERIODO_COMPETENCIA` **antes** da alteração da seleção. D2 requer preservar a intenção/seleção coerente; não satisfaz por si só ocultar um KPI depois da seleção ou desfazê-la por trigger. P5 §62.6 continua independente, com classes `C/R/I/B` por indicador; não presumir que bloquear D2 aprove filtros P5.

## 2. Critérios de segurança dos mecanismos QlikView

| Mecanismo | Comportamento sustentado pelas fontes | Classificação para D2 |
| --- | --- | --- |
| Marcar `Apenas leitura` em `LB01`/`LB04` | Impede seleção **naquela lista**, ainda reflete seleção feita em outro lugar | Mitigação local candidata, insuficiente globalmente |
| Botão único com condição de habilitação e ação `Select in Field` | Permite controlar uma rota de proposta, se a propriedade existir/funcionar na instalação | Candidato restrito, exigindo prova física da condição e da ação |
| Busca, seleção nativa, objetos adicionais, menus, bookmarks | QlikView dispõe desses mecanismos; a presença/uso concreto de cada rota no QVW alvo deve ser inventariada | Bloqueio de cobertura desconhecida, nunca presumir ausência |
| Triggers `OnAnySelect` / `OnSelect` / `OnChange` | Executam a partir de eventos de seleção/alteração, **não** comprovam interceptação antes do despacho | NO-GO como prevenção primária |
| Bloqueio do KPI via `Calculation Condition` / aviso | Restringe exibição no contexto já selecionado | Não satisfaz sozinho o requisito D2 |
| `Always One Selected Value` ou locks de campo | Têm efeitos próprios sobre modelo, seleção e desbloqueio; não há aprovação semântica para usá-los como atalho | Não adotar neste gate |

**Atenção a bookmarks:** a ajuda oficial informa que aplicar um bookmark restaura seleções capturadas. Isso torna o mecanismo uma *rota possível*, mas **não prova que existam bookmarks configurados nesta cópia**. Igualmente, não se deve afirmar que marcar duas listas como somente leitura bloqueie menus/ações sobre os mesmos campos.

## 3. Opções de decisão — sem escolha implícita

**Opção A — interface temporal controlada, RECOMENDADA COMO HIPÓTESE (ainda sem aprovação):** em nova cópia descartável do QVW existente, usar `LB01` e `LB04` apenas como visualização (candidatas a `Apenas leitura=True`); manter as propostas temporais por controles explícitos que validem a compatibilidade **antes** de executar uma única ação de seleção. `BU01`/`BU02` existentes têm valores fixos (`201801`/`2019`), portanto **não são solução geral escalável** para os 36 meses sem desenho adicional. Uma entrada de proposta em variável + controle de aplicação pode ser investigada como **hipótese técnica**; existência, persistência, ações e expressões concretas precisam ser aferidas no QlikView 12, sem criar novos campos, fatos ou dimensões. Mensagem de incompatibilidade visível e preservação do estado anterior são condições necessárias.

**Limite inegociável de A:** os controles de proposta só satisfazem D2 para as **rotas efetivamente contidas**. Se menu Seleções, busca global, bookmarks, outras ações de objeto, seleção em gráfico ou outra porta alcançável no contexto alvo puder alterar o período sem a guarda, **D2 global permanece NO-GO**, mesmo com ambas as listboxes somente leitura. Não presumir capacidade de desabilitar menus nativos ou COM via propriedades sem prova. Qualquer redução do escopo semântico (por exemplo, 'D2 vale apenas no caminho de botões') depende de aprovação explícita do responsável e não pode ser silenciosa.

**Opção B — manutenção de bloqueio formal de D2:** não modificar a interface temporal; preservar pilotos acadêmicos sob avisos e limitações; prosseguir apenas com gates documentais/contratuais independentes em ordem C2 → C3 → C4 conforme Boundary 7, sem homologar painel definitivo.

## 4. Menor teste físico admissível após aprovação independente (proposta C2-H)

**Gate proposto:** `C2-H — prova restrita de mitigação de rotas LB01/LB04 em cópia QVW`, NÃO INICIADO. Objetivo limitado: verificar se, ao tornar `LB01` e `LB04` somente leitura **somente em uma cópia nova**, a seleção direta por essas duas listas deixa de ser possível, enquanto propostas de botão **já contratadas** continuam alcançáveis. Isso é prova da mitigação local de duas rotas, não homologação D2 global, nem implementação de UX para todos os períodos.

**Condições antes de qualquer alteração:**
1. Receber autorização específica **para mudar apenas as duas flags de Read Only em QVW TEMP**, mantendo dados/código/fatos inalterados, sem mexer nas cópias de evidência originais.
2. Conferir `main@SHA`, branch/commit e `SHA256` do QVW fonte, fechar a fonte, criar **uma cópia nova** em `%TEMP%`, preservar manifesto/hashes de 22 QVDs e três QVWs canônicos, e criar pasta de evidência **persistente fora do Git**.
3. Registrar antes/depois em propriedades de `LB01/LB04`; salvar **apenas** a nova cópia de teste se explicitamente autorizado. Não chamar `Reload`, não mudar dados, Set Analysis, modelo, controles originais ou outros filtros.
4. Inspecionar objetos pela UI/COM somente se esses métodos estiverem de fato disponíveis e contratados; a sonda antiga UIAutomation/Win32 C2-D3 terminou com NO-GO e **não deve ser repetida**. Se necessário, operador humano é fallback.
5. Testar um cenário **somente das duas listas alteradas**, com seleção coerente e incompatível conforme protocolo novo, documentando pré/pós com screenshots e seleção observada. Uma única rodada; erro ou escrita fora de escopo = STOP. Testes históricos D2-1/D2-3 **não devem ser repetidos** salvo mudança material nos controles ou necessidade de isolar regressão diretamente introduzida pelo novo QVW.
6. Auditar hashes finais de fontes QVW, 22 QVDs e 3 QVWs canônicos; preservar os CSV/PNG/log/manifestos sem versionar binários ou dados.

**Veredito máximo permitido para C2-H:** `PASS_LOCAL_LISTBOX_MITIGATION_CANDIDATE_ONLY`, **não** `P5_D2_UI=APPROVED`. Se a seleção continuar possível pela lista, `BLOCKED`. Se a lista estiver protegida, mas as rotas restantes não estiverem inventariadas, `C2_FULL=NO_GO_NOT_APPROVED`.

**Trabalho futuro distinto:** somente se C2-H passar e opção A for formalizada, investigar inventário/controle de outras rotas relevantes da UI **sem cadeia interminável**. Caso a superfície nativa do Desktop não seja isolável, registrar impossibilidade de comprovação de D2 global sob o contrato atual e retornar para decisão semântica do responsável.

## 5. Encerramento e encaminhamento

`C2G_READONLY_DESIGN=COMPLETED_WITH_PROPOSAL`; `C2G_OPTION_A=RECOMMENDED_NOT_APPROVED`; `C2H_PHYSICAL_MUTATION=NOT_AUTHORIZED`; `C2F_ROUTE_INVENTORY=STOPPED_WITH_BOUNDED_EVIDENCE_AND_UNKNOWN_ROUTES`. `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**Roteamento:** agente primário ChatGPT GPT-6 + GitHub, consulta documentação oficial; esforço não selecionado explicitamente. Fallback para execução local: Codex Local Windows ou operador QlikView 12 sob autorização separada. Este gate não acessou Windows, QVW, COM nem artefatos protegidos; `RUNTIME_TEMP/EVIDENCE_ROOT` não se aplicam. `PASS` deste gate é **somente documental**; `BLOCKED` físico permanece até autorização. **STOP:** documento de decisão e checklist C2-H produzidos; não implementar, abrir QVW, mudar lista, executar COM ou entrar na Fase IX por inferência.

## 6. Referências

- [C2-F — relatório integrado](phase-8-c2f-physical-selection-route-inventory-2026-10-21.md), PR #146, evidência visual das duas listas.
- [C2-E — inventário documental de rotas](phase-8-c2e-d2-p5-selection-route-inventory-2026-10-21.md).
- [V2 §62.3 e §62.6](phase-6-semantic-v2-approved-2026-10-14.md).
- [QlikView — Lista / Read Only](https://help.qlik.com/pt-BR/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/List_Box.htm).
- [QlikView — Triggers](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Document_Properties_Triggers.htm).
- [QlikView — Button / Enable Condition](https://help.qlik.com/en-US/qlikview/September2025/Subsystems/Client/Content/QV_QlikView/Button2.htm).
- [QlikView — Selecting Field Values](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Select_field_values.htm).
- [QlikView — Bookmarks](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Bookmarks.htm).
