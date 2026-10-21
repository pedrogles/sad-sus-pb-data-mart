# Fase VIII — C2-I | Fechamento READ-ONLY da suficiência residual de rotas D2/P5

**Data:** 21/10/2026. **Baseline verificada:** `main@329a765bfaa27583b09bc24f8734db1301e2d752` após os merges [#148](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/148) (C2-H) e [#149](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/149) (reconciliação).

**Estado:** `C2I_RESIDUAL_ROUTE_CLOSEOUT=COMPLETED_READONLY_WITH_LIMITS`; `C2I_GLOBAL_PREDISPATCH_SUFFICIENCY=NO_GO_NOT_PROVEN`; `C2I_NEW_PHYSICAL_PROBES=ZERO`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED`.

## 1. Objetivo, fontes, escopo, STOP

**Objetivo único:** após a mitigação local observada no C2-H, reconciliar apenas quais rotas alternativas ao botão ainda aparecem no **mesmo QVW experimental** ou são meras capacidades gerais do QlikView, e determinar se a suficiência de **pré-despacho D2 global** é demonstrável com as evidências existentes. **Não** reinventariar o QVW por UIAutomation/Win32 ou iniciar novos testes de botão, GUI, COM, QVD ou scripts.

**Leitura e precedência:** `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → Boundary 7 → semântica V2 §62.3/62.6 → C2-E, C2-F, C2-G, C2-H e encerramento C2; referências oficiais QlikView abaixo. Prova real local: imagens e TSVs descritos em C2-F/C2-H; referências oficiais são **capacidades gerais**, não confirmação de uso efetivo numa instância específica.

**Permissão:** leitura de código/documentos/evidências já compartilhadas, produção deste documento e roteamento curto no `current-state.md`. **Proibido:** chamar COM, abrir/editar QVW, clicar em menu/bookmark, executar PowerShell, criar/fazer reload de QVD, alterar 3 fatos/8 dimensões, migrar painel, executar T24–T26/C2-D3, implementar Fase IX. STOP quando a matriz e uma decisão de suficiência estiverem registradas.

## 2. Matriz de rotas após C2-H — distinção de evidências

| Superfície de seleção | O que está comprovado neste protótipo | O que NÃO está comprovado | Status restrito |
| --- | --- | --- | --- |
| `LB01/PERIODO_ANO`, `LB04/PERIODO_COMPETENCIA` | Capturas de flags **Apenas leitura** marcadas; operador reportou bloqueio de cliques diretos, com uma captura final sem seleção; `-Verify` local reportou QVW experimental mudado, originais preservados | Pares independentes pré/pós de cada clique, proteção universal dos campos contra seleção de outra origem | `LOCAL_MITIGATION_SUPPORTED_WITH_LIMITS` |
| `BU01` (proposta `201801`) | Par visual antes/depois em C2-H é compatível com clique reportado e competência `201801` destacada na lista `Read Only` | Registro interno da ação/dispatch e proteção de todos os valores temporais | `PASS_VISUAL_RESTRICTED_ONE_ROUTE` |
| `BU02` (proposta `2019`) | Botão visualmente desabilitado no estado pós-BU01; histórico C2-D1 contém testes de caminho por botão qualificados | Teste novo de BU02 em C2-H, cobertura global de conflitos por outras rotas | `HISTORICAL_PARTIAL_NOT_RETESTED` |
| Menu nativo **Seleções** + ações **Limpar/Voltar/Adiante** | A barra de menu e toolbar aparecem na captura C2-H; demonstram **superfície visível**, não resultado de despacho sob conflito | Se e como a instância permite propostas temporais incompatíveis, interceptação pré-seleção | `VISIBLE_ENTRY_POINTS_EFFECT_UNKNOWN` |
| Menu nativo **Marcadores** / bookmarks | Nome do menu aparece na captura C2-H; a ajuda Qlik informa que bookmarks aplicados podem restaurar seleções em todos os estados | Existência de bookmark específico salvo no QVW, conteúdo dos bookmarks ou se seu uso altera ano/competência neste documento | `VISIBLE_MENU_BOOKMARK_CONTENT_UNKNOWN` |
| Pesquisa dos valores | Ícones de lupa/área de pesquisa aparecem nos objetos; ajuda oficial registra seleções por busca | Busca efetiva no modo `Read Only` destes objetos; pesquisa global disponível e seu resultado neste QVW | `VISIBLE_SEARCH_AFFORDANCE_DISPATCH_UNKNOWN` |
| Demais objetos `LB02`, `LB03`, `CH01` | Estrutura exportada: duas listas não temporais e uma tabela; as listas de serviço e procedimento aparecem na folha | Se ações associadas ou filtros induzem seleções temporais; conformidade simultânea com a matriz P5 dos quatro indicadores | `OBJECTS_PRESENT_ASSOCIATED_EFFECT_UNKNOWN` |
| Outras ações programáticas COM e triggers | Provas históricas de wrapper pré-COM e documentação dos eventos após seleção; não houve nova execução | Alcance de COM por usuários, triggers efetivos configurados nesta cópia e guarda em todos os chamadores | `CAPABILITY_OR_CONFIG_UNKNOWN_NOT_UI_GUARDED` |

**Regra de classificação:** `VISIBLE` não significa que uma ação tenha sido executada. `UNKNOWN` não significa que a rota inexista. `Read Only` não é bloqueio global do campo: a ajuda oficial confirma que a listbox ainda reflete seleções feitas em outros pontos do documento. Portanto, a seleção `201801` produzida por BU01 **não contradiz** a mitigação local, mas demonstra que a flag não é uma trava do campo.

## 3. Contrato técnico sem extensão semântica

- **D2 V2 §62.3:** evitar seleção incoerente ano×competência **antes** do despacho. O botão BU01 preservado e duas listas Read Only são **mitigações parciais**, não cobertura de menus, buscas e ações alternativas.
- **Triggers Qlik:** `OnAnySelect` / `OnSelect` executam quando a seleção já foi feita. Não homologá-los como prevenção pré-despacho; rollback após selecionar também pode perder a intenção anterior.
- **Bookmark:** documentação Qlik diz que recuperar bookmark aplica suas seleções; **não** inferir bookmark existente ou funcional no QVW só porque há menu Marcadores.
- **P5 V2 §62.6:** por indicador `RES/LEI/REL/FLU`, classes `C/R/I/B` exigem conformidade inclusive em filtros simultâneos. `Calculation Condition`, Set Analysis e aviso de bloqueio são guardas de **exibição após seleção**, não prova D2 nem aprovação P5 global.
- **Temporalidade:** BU01=`201801` e BU02=`2019` são valores fixos de prova experimental; não cobrem automaticamente os 36 meses e todos os anos nem garantem experiência de seleção escalável.

## 4. Veredito e próxima decisão útil

**NO-GO fundamentado (suficiência, não bypass comprovado):** a prova disponível NÃO demonstra controle pré-despacho **sobre todas as rotas acessíveis** no QVW Desktop. Logo, `C2I_GLOBAL_PREDISPATCH_SUFFICIENCY=NO_GO_NOT_PROVEN`, preservando `C2_FULL=NO_GO_NOT_APPROVED` e `P5_D2_UI=NOT_TESTED`. Isso **não** é uma demonstração de que menu ou bookmark específico conseguiu contornar D2; nenhum deles foi acionado. A interface experimental não deve ser anunciada como homologada.

**STOP C2-I:** sem novas sondagens de UIA/Win32, cliques de busca/bookmark ou mais runners. C2-F/G/H já delimitam adequadamente o risco; multiplicar screenshots/testes da mesma configuração sem solução arquitetural aprovada seria expansão improdutiva.

**Uma decisão arquitetural futura, fora deste gate:** aprovar explicitamente uma superfície de seleção temporal com conjunto de rotas suportadas, política de acesso aos mecanismos nativos e critério de prova para o **contexto real de uso** do painel; caso isolamento de menus/bookmarks/ações não seja demonstrável, manter D2 global em NO-GO. Não assumir que esconder duas listas, desabilitar duas ações ou usar triggers resolva essa fronteira.

**Próximo trabalho quantitativo independente sugerido:** priorizar a **lacuna de cobertura CNES/LT por município×competência** na política de denominadores C4, por revisão de evidências já disponíveis e sem repetir C4-B1. No estado atual, ausência de linha LT não pode virar zero SUS e a cobertura hospitalar histórica não está demonstrada. A execução/teste físico de qualquer novo gate C4 requer escopo e autorização próprios; estudos anteriores T25/T26 permanecem observacionais restritos.

**Invariantes:** `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

## 5. Referências auditáveis

- [C2-H — evidência local e closeout](phase-8-c2h-readonly-listbox-physical-pilot-2026-10-21.md), [C2-F — objetos](phase-8-c2f-physical-selection-route-inventory-2026-10-21.md), [C2-G — hipótese de controle](phase-8-c2g-temporal-selection-design-decision-2026-10-21.md), [C2-E — riscos gerais](phase-8-c2e-d2-p5-selection-route-inventory-2026-10-21.md).
- [QlikView List Box — Read Only](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/List_Box.htm): bloqueia seleção no objeto, reflete seleção externa.
- [QlikView Selecting Field Values](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Select_field_values.htm): seleções em objetos/busca e efeito de valores excluídos.
- [QlikView Bookmarks](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Bookmarks.htm): reaplicação de seleção armazenada.
- [QlikView Document Properties: Triggers](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Document_Properties_Triggers.htm): OnAnySelect/OnSelect após seleção.

**Roteamento:** GPT-6 com GitHub e documentação oficial, READ-ONLY no QlikView; modelo/esforço de operador Windows não aplicável; `RUNTIME_TEMP/EVIDENCE_ROOT` não criados. Evidências anteriores referenciadas, sem novos bytes/arquivos locais. `PASS` somente documental na classificação; `BLOCKED` se fonte ou limite não verificável; `INCONCLUSIVE` para presença funcional de rota não testada; `STOP` ao registrar o NO-GO de suficiência.
