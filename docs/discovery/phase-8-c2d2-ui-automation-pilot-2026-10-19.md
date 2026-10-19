# Fase VIII — C2-D2: automação restrita de botões nativos D2 (QlikView 12)

**Status inicial:** `C2D2_RUNNER=VERSIONED_NOT_EXECUTED`, `C2D2_UIA_EXPOSURE=NOT_TESTED`, `C2D2_PILOT=NOT_TESTED`, `C2D2_COMPLETE=NOT_TESTED`, `P5_D2_UI=NOT_TESTED`, `C2_FULL=NOT_APPROVED`, `PRODUCTION_APPROVED=False`. PR Draft, sem merge.

## 1. Objetivo, fundamento e estado anterior

**Objetivo único:** substituir a preparação manual de estados e cliques na rota dos botões `BU01` e `BU02` por um executor fail-closed PowerShell/COM/UIAutomation, com **sondagem READ-ONLY obrigatória**, **D2-2 como piloto**, e os **D2-1, D2-3 e D2-4** restantes somente depois de relatório piloto verificável. Não alterar semântica, scripts QVS, QVDs, QVWs canônicos, filtros globais nem dashboard final.

**Hierarquia lida na `main@337943d5c5b77067f842902fc679dbb68db87020`:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, depois `docs/project/qlikview-powershell-automation.md`, a semântica V2, PR #121 C2-D de viabilidade e PR #122 C2-D1 (em Draft). Esses PRs não integram a main.

**Prova existente reutilizada:** `C2D1_D2_1_BUTTON_ROUTE=PASS_VISUAL_RESTRICTED` (pré e pós-clique observados); D2-2/3/4 não concluídos. Dois botões configurados manualmente e fotografados, ID COM `BU01` propõe competência `201801` e `BU02` propõe ano `2019`. A cópia QVW do teste fica exclusivamente no TEMP Windows. A evidência de configuração não comprova acessibilidade do botão para UIAutomation.

**Fontes externas documentais:** [QlikView Developer — interface de Automation/COM](https://help.qlik.com/en-US/qlikview-developer/May2024/Subsystems/Automation/Content/QV_Automation/automation-introduction.htm) e [Microsoft — UI Automation de botões](https://learn.microsoft.com/en-us/windows/win32/winauto/uiauto-supportbuttoncontroltype). A Qlik documenta COM; isso **não comprova que BU01/BU02 sejam expostos na árvore UIAutomation de QlikView Desktop**, especialmente se desenhados customizados. **DECISÃO CONSERVADORA:** não utilizar coordenadas presumidas, OCR, identificadores genéricos ou mouse click sem encontrar **exatamente dois botões acessíveis**, pelo nome e `ControlType.Button`, em janela QlikView única e visível.

## 2. Runner versionado e três estágios

**Script:** `tools/Invoke-SadPhaseViiiC2d2UiAutomation.ps1`. Windows PowerShell 5.1 interativo, QlikView 12 COM `QlikTech.QlikView` e assembly .NET Framework `UIAutomationClient/UIAutomationTypes`, `System.Drawing`. O operador **não deve interagir com mouse/teclado durante `-Stage Pilot` ou `-Stage Complete`**. Não há aprovação de execução headless.

**Origem aprovada:** `%TEMP%\SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw` — deve estar salva, com os dois botões. A cada estágio ativo, origem **fechada** e clonada com SHA-256 conferido em pasta `%TEMP%\SAD_VIII_C2D2_<STAGE>_<GUID>\SAD_C2D2_BUTTON_AUTOMATION.qvw`. O script não salva alteração alguma no QVW copiado e, ao terminar, fecha o documento COM. Não se presume estabilidade de funções customizadas sem executar na instalação real.

- **`-Stage Probe` — primeiro, READ-ONLY:** exige QVW C2-D1 original **aberto/salvo** na UI, janela única e em foco; localiza BU01/BU02 por **nome acessível exato parcial** e `ControlType.Button`, reporta `IsEnabled` e retângulo e salva uma captura. **Não abre COM, não seleciona campos, não clica, não salva.** Se os botões não estiverem na árvore acessível, `BLOCKED_UIA_EXACT_BUTTONS_NOT_EXPOSED`; manter `P5_D2_UI=NOT_TESTED`, sem fallback automático arriscado.
- **`-Stage Pilot` — somente após Probe positivo:** fechar o QVW de origem com as configurações salvas; clonar a origem, abrir só clone via COM, `ClearAll`, selecionar competência `201801`, verificar que nenhum `PERIODO_ANO` foi selecionado; localizar `BU02` na UIA, exigir `IsEnabled=False`, screenshot `D2_2_before.png`, clique físico com `mouse_event` **apenas dentro do retângulo acessível BU02** após revalidação de foco/retângulo; verificar que mês `201801` permaneceu e ano não foi selecionado; screenshot `D2_2_after.png`, hashes/manifesto. Se qualquer bloqueio => **STOP**. `VERDICT=PASS_LOCAL_D2_2_BUTTON_ROUTE_CANDIDATE_ONLY` não é aprovação visual independente nem instrumentação de dispatch interno.
- **`-Stage Complete -PilotManifest <path>` — opcional somente após revisão do piloto:** valida manifesto e SHAs de script/origem do piloto; nova cópia, executa D2-1 (ano `2019`, BU01 desabilitado), D2-3 (ano `2018`, BU01 habilitado, mês `201801` aplicado), D2-4 (mês `201901`, BU02 habilitado, ano `2019` aplicado). Em cada caso: seleção inicial por COM, leitura `GetSelectedCount` + `GetFieldSelections`, confirmação de botão UIA, screenshot antes, **clique físico exato**, leitura de seleções finais, screenshot depois. **Primeira divergência interrompe os casos restantes.**

**Risco explicitado:** o UIAutomation do QlikView pode não reconhecer os botões, mesmo visíveis na captura. Um `BLOCKED` nessa sondagem é resultado útil de compatibilidade; **não** autoriza tentar cliques por coordenadas fixas como reparo imediato. O caminho alternativo exigiria uma Discovery independente e contrato próprio.

## 3. Proteção de dados, escopo e aceitação

Invariantes de cada execução:
- Conferir branch específica, commit e script versionado **limpo no git**; saída imprime SHA-256 do script, HEAD real e da origem.
- Os **22 QVDs** (10 extração e 12 transformação), os QVWs canônicos encontrados, o QVW de origem C2-D1 devem manter exatamente os mesmos hashes pré e pós. Só criar novos QVW/clipes PNG/manifestos sob `%TEMP%`.
- Sem `Reload()`, `STORE`, `Save()` em QVW original/canônico, nem escrita SQL. Seleções por COM são exclusivamente para **montar o estado inicial no clone**; a proposta testada ocorre **somente por clique real no botão da janela identificada**.
- Capturas são feitas da janela alvo realmente em foreground. Nenhum PASS sem duas capturas por caso e asserções de seleções. A geração automática de capturas **não equivale a auditoria visual independente**.
- `PRODUCTION_APPROVED=False`, `P5_D2_UI=NOT_TESTED` continuam até gates separados; mesmo sucesso da rota BU01/BU02 não protege listas, bookmarks, busca ou outros controles.

**Vereditos previstos, NÃO confirmados:** `PASS_READONLY_C2D2_UIA_BUTTON_DISCOVERY_CANDIDATE`, `PASS_LOCAL_D2_2_BUTTON_ROUTE_CANDIDATE_ONLY` e `PASS_LOCAL_C2D1_REMAINING_BUTTON_ROUTES_CANDIDATE_ONLY`. Outros resultados: `BLOCKED_OR_INCONCLUSIVE`. Testes são locais Windows e dependem de foco, escala de tela, janela única e acessibilidade UIA.

**Evidências esperadas:** `EVIDENCE_DIR`, `EVIDENCE_MANIFEST` (JSON), `D2_*_before.png`, `D2_*_after.png`, SHA-256 de cada PNG, log stdout, SHA fontes, etiqueta de estágio. Nunca versionar QVW/PNG/dados no Git.

**STOP/ordem:** 1) **Probe**, registrar resultado; 2) após PASS, **Pilot** D2-2; 3) analisar saída e as duas capturas; 4) somente depois avaliar Complete. Não disparar os três estágios automaticamente na mesma invocação; não repetir etapas anteriores do C2-W/C2-A. Se Probe falhar, **encerrar gate físico com incompatibilidade UIA documentada**, sem 5 tentativas alternativas.

## 4. Referências acadêmicas e gates mantidos

Preservar `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `T26_GENERAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `C2_FULL=NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `PRODUCTION_APPROVED=False`.

Este gate **não** integra Phase IX, não reabre modelagem e não representa implantação homologada da interface de prevenção D2.