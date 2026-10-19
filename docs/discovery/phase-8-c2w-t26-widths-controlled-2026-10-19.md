# Fase VIII — C2-W: correção controlada de largura T26, com Size to Data manual (19/10/2026)

**Status:** `C2W_VERSIONED_NOT_EXECUTED`; `C2W_SIZE_TO_DATA_GUI=PENDING`; `C2W_VISUAL_REVIEW=PENDING`; `PRODUCTION_APPROVED=False`. PR Draft em branch específica originada de `main@337943d5c5b77067f842902fc679dbb68db87020`.

## 1. Evidências e objetivo delimitado

**Fontes operacionais verificadas antes do desenvolvimento:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md` da `main`; depois `docs/project/qlikview-powershell-automation.md`, C2-V [PR #118](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/118) e C2-S [PR #119](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/119), ambos Draft. Não presumir que alterações de PR Draft integram a main.

**FATO VERIFICADO por capturas GUI C2-S:** no QlikView 12 Desktop, a opção `Ajustar o tamanho aos dados` (Size to Data) da Straight Table CH01 estava **marcada**. Depois de desmarcar e selecionar `PERIODO_ANO=2018` e `SERV_COD_DATASUS_6=250750`, o gráfico conservou a área ampla e exibiu **31,21**. Portanto, `C2S_SIZE_TO_DATA_CAUSAL_EFFECT_ALLOWED_S0=CONFIRMED_GUI_EXPERIMENTAL`. Ainda havia cabeçalhos de colunas e títulos de listboxes truncados. A GUI mostrava um `*` no arquivo evidencial C2-V; não há prova de alteração gravada. Preservar esse arquivo: fechar sem salvar.

**FATO DOCUMENTADO externamente:** [QlikView Straight Table — Layout / Size to Data e Fit Columns to Data](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Straight_Table.htm) distingue contração das bordas versus largura das colunas. Uma [solução aceita na Qlik Community para largura de colunas](https://community.qlik.com/t5/QlikView/Straight-Table-macro-will-only-adjust-First-Column-s-Width/td-p/27805) utiliza `GetProperties().Dimensions(i).ColWidth` e `GetProperties().Expressions.Item(i).Item(0).Data.ExpressionVisual.ColWidth`, seguida de `SetProperties`.

**HIPÓTESE FÍSICA A TESTAR:** essas propriedades COM também são suportadas no QlikView 12 Desktop do responsável e permitem colunas de 155 e 285 unidades (valores candidatos). As unidades de `ColWidth` não foram calibradas por screenshot; o readback e o visual devem comprovar utilidade.

**DECISÃO DE ESCOPO:** o nome COM **exato** de `Ajustar o tamanho aos dados` **não foi confirmado por documentação nem inspeção física**. Não inventar `p.Layout.SizeToData` ou similar. O script prepara um **novo QVW descartável** com larguras/posições de objetos; a checkbox será **desmarcada manualmente e salva exclusivamente nessa nova cópia** pelo responsável, uma vez. Isso é uma limitação deliberada da automação, não homologação da propriedade via COM.

## 2. Arquivos, mutações e invariantes

**Executável versionado:** `tools/Invoke-SadPhaseViiiC2wT26Widths.ps1`. Uma única execução Windows depois de `Parser.ParseFile` PASS e verificação de HEAD; não rodar o runner anterior C2-V nem repetir os gates T24–T26.

**Origem exclusiva autorizada:** `%TEMP%\SAD_VIII_C2V_83cc8d984d9e438eb76a71d1ff8f6d0f\SAD_C2V_T26_DISPOSABLE.qvw`, arquivo de **evidência anterior**. O script recusa a operação se a janela original ainda estiver aberta; fecha-la **sem salvar** antes de executar. O SHA-256 dessa origem será capturado e preservado antes/depois; **não há SHA-256 canônico pré-publicado da cópia C2-V**, portanto não afirmar identidade bit-a-bit histórica antes da inspeção. O QVW T24 anterior também é verificado pelo hash fixo `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`.

**Destino único:** `%TEMP%\SAD_VIII_C2W_<GUID>\SAD_C2W_T26_LAYOUT_TEST.qvw`, criado exclusivamente no teste, nunca um QVW original/canônico. **Nenhuma recarga, STORE, escrita de QVD ou alteração do esquema.** Inventário pré/pós dos **22 QVDs**, QVWs canônicos, QVW TEMP de evidência C2-V e QVW TEMP de fonte T24; discrepância => erro crítico.

**Mudança na cópia via COM (candidata):**
- Gráfico CH01, somente `Dimensions.Item(0).ColWidth=155` e `Expressions.Item(0).Item(0).Data.ExpressionVisual.ColWidth=285`, com SetProperties e leitura de volta. Qualquer ausência/falha COM => STOP.
- Reposicionamento/comprimento físico CH01 `x=300,y=116,w=865,h=320`, listboxes LB01–LB03 `x=16,w=250`, textos TX01–TX06 `x=300,w=865`, usando `SetFrame` e readback (escala interna `2,5`, demonstrada antes somente para posições/propriedades).
- Apenas smoke do estado `PERIODO_ANO=2018`, `SERV_COD_DATASUS_6=250750`, sem filtros B; conferir `Num(...,'0,00',',','.')='31,21'` e condição `EvaluationCondition=1`. Não refazer oráculos F1/F2 completos. Salvamento permitido somente na cópia C2-W.

## 3. Execução e verificação visual **fora** do script

**Se stdout emitir `VERDICT=PASS_LOCAL_C2W_COM_COLUMNS_AND_FRAMES_GUI_SIZE_TO_DATA_STILL_PENDING`:**
1. Abrir **somente** a nova cópia identificada por `COPY_FOR_GUI=`, no QlikView 12 interativo. Confirmar que no título **NÃO** aparece `SAD_C2V_T26_DISPOSABLE.qvw`. Antes de abrir, fechar o QVW de evidência C2-V com **Não salvar**.
2. No CH01, botão direito → Propriedades → Layout → **desmarcar `Ajustar o tamanho aos dados`**. **Salvar somente o QVW C2-W novo**. Essa única alteração manual é permitida nesta cópia. Se a opção já estiver desmarcada, registrar e **não fingir que o script a configurou**.
3. Limpar seleções prévias; selecionar somente `PERIODO_ANO=2018`, `SERV_COD_DATASUS_6=250750`. Capturar **S0 (permitido)** com 31,21 e frame largo, sem `#####`, sem cabeçalhos truncados nas duas colunas, sem aviso P5 indevido.
4. Acrescentar **um único procedimento** na lista existente e capturar **S1 (bloqueio)** com indisponibilidade e aviso completo; não testar novamente S2, S3, S4, wrapper D2, outras cidades ou período parcial.
5. **Salvar a correção da checkbox somente na cópia**, nunca na origem C2-V; preservar os dois PNGs e enviar aqui para auditoria. Os PNGs devem mostrar a folha inteira, a seleção no listbox e ausência de sobreposição, considerando sua resolução real. A auditoria visual da seleção não equivale a aprovação geral P5.

**Se runner emitir BLOCKED:** registrar primeira causa e STOP — não remover asserts, não tentar múltiplos nomes COM nem converter erro em PASS. Não prosseguir para edição GUI da cópia antes de resolver a falha em novo objetivo autorizado.

**PASS documental/teórico:** script versionado e PR Draft, não executado. **PASS local candidato:** executado no Windows, colunas+frames com readback, smoke 31,21, cópia salva, QVD/QVW original intacto. **PASS visual restrito:** possível somente se a checkbox desmarcada na cópia e S0/S1 inspecionados independentemente com colunas legíveis, sem truncamento e bloqueio funcional. **Sem aprovação de produção.**

## 4. STOP e fronteiras

**GATE C2-W termina** após uma tentativa COM e, se PASS, uma edição GUI controlada e análise de dois PNGs. Não desenvolver novos executores ou expandir painel automaticamente. Não converter falha de layout em nova revisão de modelagem.

`C2A_COM_AND_SCREENSHOTS=PASS_LOCAL_CANDIDATE_ONLY`; `C2V_COM_GEOMETRY_LABEL_FORMAT_AND_CAPTURE=PASS_LOCAL_CANDIDATE_ONLY`; `C2V_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION` (artefato anterior); `C2S_SIZE_TO_DATA_CAUSAL_EFFECT_ALLOWED_S0=CONFIRMED_GUI_EXPERIMENTAL`. Mantidos: `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `T26_GENERAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.