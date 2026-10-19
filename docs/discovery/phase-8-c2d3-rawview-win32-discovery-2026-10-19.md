# Fase VIII — C2-D3: Discovery READ-ONLY de acessibilidade RawView/Win32 (19/10/2026)

**Status:** `C2D3_READONLY_PROBE=VERSIONED_NOT_EXECUTED`; `C2D3_RAWVIEW_IDENTIFIERS=UNKNOWN`; `C2D3_WIN32_IDENTIFIERS=UNKNOWN`; `C2D3_UI_CLICK_GO=NOT_APPROVED`; `P5_D2_UI=NOT_TESTED`; `PRODUCTION_APPROVED=False`. Gate novo e independente; PR Draft, sem merge.

## 1. Objetivo, baseline e evidência de entrada

**Objetivo único:** em **uma execução READ-ONLY**, diagnosticar se `BU01` (proposta competência `201801`) e `BU02` (proposta ano `2019`) possuem identificadores de interface estáveis fora do filtro muito restrito usado pelo Probe anterior. A investigação deve fornecer **GO candidato ou NO-GO com limite de evidência**, sem efetuar clique, selecionar campos ou reexecutar o teste D2.

**Fonte operacional conferida nesta ordem:** `main@337943d5c5b77067f842902fc679dbb68db87020`: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, depois `docs/project/qlikview-powershell-automation.md`, `docs/discovery/boundary-7-implementation-plan.md`, PR #122 C2-D1 e PR #123 C2-D2. A `main` ainda possui snapshot `current-state.md` anterior à série de Drafts; nenhum PASS de Draft integra a `main` automaticamente.

**Fato reportado e documentado no PR #123:** executor C2-D2 foi executado em Windows/QlikView 12 a partir do commit `5a7d1eccc4d8fabe063ce9a043c14fe9c3f99bcf` e devolveu `BLOCKED_UIA_EXACT_BUTTONS_NOT_EXPOSED_FOUND_0`, `ORIGINAL_SOURCES_INTEGRITY=PASS`, sem piloto. O algoritmo anterior (`AccessibleButtons`) inspecionava elementos `UIAutomation` e aceitava **apenas** `ControlType.Button` com `Current.Name` contendo os nomes visíveis dos botões. **Zero correspondências a esse predicado não significa zero elementos na RawView**, nem ausência de botões no documento QVW, que já foram visualmente observados na UI.

**Fontes oficiais Microsoft consultadas em modo READ-ONLY:**
- [UI Automation Tree Overview](https://learn.microsoft.com/en-us/windows/win32/winauto/uiauto-treeoverview): `Raw View` é a visão mais abrangente e fundamenta `TreeWalker.RawViewWalker`; estruturas variam conforme o framework/provedor.
- [TreeWalker.RawViewWalker](https://learn.microsoft.com/en-us/dotnet/api/system.windows.automation.treewalker.rawviewwalker?view=windowsdesktop-10.0): mecanismo .NET Framework para percorrer Raw View; percorrer **somente** a janela QlikView, **nunca** Desktop inteiro.
- [MSAA e UI Automation](https://learn.microsoft.com/en-us/windows/win32/winauto/active-accessibility-and-ui-automation): provedor para controles padrão não garante exposição completa de controles customizados.
- [WM_GETOBJECT](https://learn.microsoft.com/en-us/windows/win32/winauto/wm-getobject): acessibilidade de objetos depende da implementação/proxy; o script **não envia manualmente** `WM_GETOBJECT` ou mensagens à aplicação.
- [QlikView Automation/COM](https://help.qlik.com/en-US/qlikview-developer/May2024/Subsystems/Automation/Content/QV_Automation/automation-introduction.htm): existe API COM para documentos/objetos, **mas essa API não prova que um objeto é clicável de maneira identificável pela UI Automation**.

## 2. Escopo permitido e executor

**Arquivo versionado:** `tools/Inspect-SadPhaseViiiC2d3QlikAccessibility.ps1`, branch `docs/phase-viii-c2d3-rawview-win32-discovery-20261019`. Executar **somente uma vez** no Windows, com QlikView Desktop 12 aberto na folha Principal do **QVW salvo**: `%TEMP%\SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw`.

**Pré-condições fail-closed:**
- Git branch correto, arquivo script commitado e sem alterações locais; SHA-256 do script e HEAD exibidos.
- Exatamente **uma** janela do processo QlikView com **caminho completo do QVW C2-D1 no título**; recusar QVW com `*` de alterações ainda não salvas.
- Origem QVW existente, sem alteração; 10+12 QVDs e QVWs canônicos inventariados e hasheados antes/depois.
- Não recarregar QVW, não abrir outro QVW, não executar COM, não fazer seleção, não usar cursor/mouse/teclas, não enviar mensagens/macro ao QlikView.

**Duas observações passivas separadas por aproximadamente 1,2 s:**

1. **UIA RawView** — percorrer `AutomationElement.FromHandle(hwnd)` com `TreeWalker.RawViewWalker`, a partir da janela do QlikView, em largura, com teto **320 elementos**, profundidade máxima **8** e máximo **96 filhos por nó**. Registrar profundidade, `Name`, `AutomationId`, `ControlType`, `ClassName`, `FrameworkId`, `NativeWindowHandle`, `IsEnabled`, `IsOffscreen` e retângulo, sem exigir `ControlType.Button`. A árvore **pode estar incompleta** se alcançar limites.
2. **Win32 Child Windows** — `EnumChildWindows` **somente** da janela QlikView alvo e do mesmo PID, teto **260 HWNDs**; registrar handle, classe, texto, visibilidade, habilitação e retângulo. Um botão desenhado dentro de outro HWND pode não ter `GetWindowText` próprio; vazio é dado diagnóstico, não negação da existência visual.

**Saídas locais:** `%TEMP%\SAD_VIII_C2D3_<GUID>\rawview_1.csv`, `rawview_2.csv`, `win32_1.csv`, `win32_2.csv`, `discovery_manifest.json`, mais stdout. Os CSVs contêm identificadores locais de interface, **não devem ir para o Git**. Se houver elementos faltantes pode não haver linhas no CSV respectivo; considerar contagens no stdout como autoridade. Arquivos do Windows ainda **não foram acessados independentemente**.

## 3. Regras objetivas de classificação

| Resultado do script | Interpretação | Conduta |
| --- | --- | --- |
| `GO_CANDIDATE_RAW_UIA_IDENTIFIERS_TWO_SNAPSHOTS` | BU01/BU02 identificados **cada um de forma única e estável** nas duas leituras UIA por nome/id, com retângulo e visibilidade | **Candidato** de automação, **não habilita clique**. Primeiro revisar CSV/identificadores e variação de estado selecionado em objetivo separado |
| `GO_CANDIDATE_WIN32_CHILD_IDENTIFIERS_TWO_SNAPSHOTS` | Mesmo critério na lista de janelas-filhas Win32, na ausência do par estável RawView | **Candidato** apenas; requer prova de que cada HWND corresponde ao botão exato antes de qualquer tentativa de clique |
| `NO_GO_STABLE_BU01_BU02_IDENTIFIERS_NOT_FOUND_IN_THIS_PROBE` | Duas leituras completas **não identificaram os dois** com nomes/IDs correspondentes | **NO-GO para essas duas rotas automáticas**, não para toda automação Windows; parar sem adivinhar coordenadas |
| `INCONCLUSIVE_ENUMERATION_LIMIT` | Limite da RawView ou Win32 atingido | Não transformar enumeração truncada em ausência de botões; STOP neste gate |
| `BLOCKED_OR_INCONCLUSIVE` ou erro | Falha técnica de coleta ou preflight | Reportar primeira causa, preservar evidência; sem execução de clique nem reiterações automáticas |

O `GO_CANDIDATE` requer identificadores coincidentes nas duas leituras **do mesmo estado**, mas **não prova estabilidade depois de alternar seleção, escala/posição ou reiniciar QlikView**. A decisão de eventual clique exige novo gate com verificação cruzada COM (objeto BU01/BU02), coordenadas relativas à janela e lógica de habilitação, não apenas matching visual. Não permitir fallback por coordenadas extraídas de screenshots, OCR ou mouse cego.

**Detalhe importante:** se o QlikView desenhar botões dentro do próprio canvas, tanto a RawView quanto Win32 poderão mostrar apenas um contêiner. Nesse caso a saída correta é NO-GO para os identificadores investigados. Pode-se continuar parte da validação **por COM somente** (`COM_ONLY_NOT_UI_CLICK`) ou concluir D2-2/3/4 manualmente, sem prometer automação visual completa.

## 4. Critérios de aceitação, STOP e gates preservados

**Aceite do gate:** um **único script PowerShell versionado**, revisão estática e uma execução Windows com parser PASS e SHA/HEAD. O objetivo é **classificar identificadores**, não executar quatro cenários de seleção. O script pode retornar NO-GO e ainda assim **a Discovery ter sido concluída com evidência**. Se não houver execução local, o estado é `C2D3_READONLY_PROBE=VERSIONED_NOT_EXECUTED`, nunca PASS.

**STOP:** uma sondagem bem delimitada, nenhum rerun da mesma árvore sob parâmetros crescentes, nenhuma edição nos QVWs originais, e nenhum merge sem autorização. Revisar stdout/manifesto/CSV uma vez para classificar; não iniciar automaticamente novo executor UIA, MSAA ou COM.

**Ainda pendente:** `C2D1_D2_1_BUTTON_ROUTE=PASS_VISUAL_RESTRICTED` (anterior), `D2_2=NOT_TESTED`, `D2_3=NOT_TESTED`, `D2_4=NOT_TESTED`, `C2_FULL=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.