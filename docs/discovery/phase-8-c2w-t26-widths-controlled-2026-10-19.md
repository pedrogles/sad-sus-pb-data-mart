# Fase VIII — C2-W: correção controlada de largura T26, com Size to Data manual (19/10/2026)

**Status atual:** `C2W_COLUMNS_AND_FRAMES_COM=PASS_LOCAL_CANDIDATE_ONLY`; `C2W_SIZE_TO_DATA_GUI=UNCHECKED_VISIBLE`; `C2W_S0_S1_VISUAL_BEHAVIOR=PASS_RESTRICTED`; `C2W_VISUAL_ACCEPTANCE=BLOCKED_COLUMN_HEADERS` (ver seção 6); `PRODUCTION_APPROVED=False`. PR Draft em branch originada de `main@337943d5c5b77067f842902fc679dbb68db87020`; execução Windows reportada, imagens auditadas independentemente, binário QVW não aberto pelo agente.

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

## 5. Execução C2-W no Windows — PASS COM candidato; conclusão GUI/visual pendente

**Origem:** stdout PowerShell/QlikView 12 **fornecido pelo responsável**, não execução independente do agente nem inspeção binária do QVW local. Após `git fetch origin` e `git switch --track`, o wrapper comparou o HEAD completo `2483b38f9e6a809dcd4ca849bf9e25470d4d3929` e confirmou `PARSER=PASS`; executou o script versionado uma vez.

- **HEAD executado:** `2483b38f9e6a809dcd4ca849bf9e25470d4d3929`.
- **SHA-256 do script executado (reportado):** `1691D75184E98C9FBE6C77FCFFE8772088FA70814C496D999F25A3254E5FC001`.
- **SHA-256 da origem TEMP C2-V, registrado no preflight:** `12F2FB851E5309C4874BC881EE22FBA2917D9B81BCB6A5FF8FEC1424BC3A5E7A`. O executor comprovou **o mesmo hash ao final**, mas não existia baseline publicada antes do preflight para esse QVW; não inferir retroativamente que uma edição GUI anterior foi ou não gravada.
- **SHA-256 da fonte T24:** `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`; preservado no final.
- **Diretório da evidência:** `C:\\Users\\pedro\\AppData\\Local\\Temp\\SAD_VIII_C2W_04f58b85152b4794b0bf4809b4e10f3c`, não acessado diretamente nesta sessão.
- **Único QVW novo salvo:** `C:\\Users\\pedro\\AppData\\Local\\Temp\\SAD_VIII_C2W_04f58b85152b4794b0bf4809b4e10f3c\\SAD_C2W_T26_LAYOUT_TEST.qvw`; `COPY_SAVED_WITH_COLUMNS_AND_FRAMES=True`.

**Propriedades COM com readback local reportado:**
- `C2W_CHART_COLUMN_WIDTHS_COM=PASS_DIM_155_EXPR_285`, no CH01 (`Dimensions.Item(0).ColWidth=155`, `Expressions.Item(0).Item(0).Data.ExpressionVisual.ColWidth=285`).
- `FRAME_READBACK_PASS` para exatamente **10 objetos**: `CH01` (`300,116,865,320`), `LB01` (`16,120,250,143`), `LB02` (`16,280,250,143`), `LB03` (`16,440,250,143`) e `TX01` a `TX06` (largura 865).
- `C2W_S0_SMOKE=PASS_DISPLAY_31,21_CONDITION_1` com `PERIODO_ANO=2018`, município de serviço `250750` e sem incompatibilidades selecionadas no smoke do runner.
- `MODE=TEMP_DISPOSABLE_NO_RELOAD_NO_QVD_WRITES`. A cópia foi salva; **o executor não alterou `Size to Data`**, pois a propriedade COM não foi inventada.

**Integridade reportada depois do Save/Close da cópia:** `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`, `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`, `C2V_EVIDENCE_QVW_SHA256_UNCHANGED=True` e `T24_SOURCE_QVW_SHA256_UNCHANGED=True`. O runner **não fez um segundo readback independente reabrindo o novo QVW**; o resultado COM e a cópia são candidatos até inspeção da GUI.

**Veredito literal do runner:** `VERDICT=PASS_LOCAL_C2W_COM_COLUMNS_AND_FRAMES_GUI_SIZE_TO_DATA_STILL_PENDING`. Não afirmar `PASS_VISUAL`, nem que a checkbox esteja desmarcada na nova cópia, nem que as larguras das colunas sejam visualmente suficientes.

### Ação única seguinte — GUI SOMENTE NA CÓPIA C2-W

1. Abrir exclusivamente `SAD_C2W_T26_LAYOUT_TEST.qvw` a partir do caminho `COPY_FOR_GUI` acima; conferir no título da janela que **não é** `SAD_C2V_T26_DISPOSABLE.qvw`. Se a origem C2-V estiver aberta, fechá-la sem salvar.
2. CH01 → botão direito → Propriedades → **Layout** → desmarcar **Ajustar o tamanho aos dados**; aplicar e **salvar somente o QVW C2-W**. Se já estiver desmarcado, relatar esse estado; não declarar desativação por COM.
3. Limpar todas as seleções; selecionar somente `PERIODO_ANO=2018` e `SERV_COD_DATASUS_6=250750`; tirar o **primeiro PNG, S0**, mostrando o frame largo e `31,21`, cabeçalhos completos, nenhuma mensagem de bloqueio.
4. Selecionar **um único valor de `COD_PROCEDIMENTO`**, mantendo o ano e município de serviço; tirar o **segundo PNG, S1**, com condição indisponível e **aviso P5 de procedimento completo**. Não gerar novamente S2/S3/S4, não reexecutar o PowerShell.
5. Encaminhar os **dois PNGs** para auditoria independente. Preferir encerrar a interface sem salvar seleções experimentais adicionais. Se houve erro de QlikView, screenshot vazio, valor incorreto, truncamento ou `Size to Data` permanecendo ativo, anotar e **STOP**.

**Condição de parada:** após duas capturas e auditoria, `C2W_VISUAL_ACCEPTANCE` será `PASS_RESTRICTED` apenas se todas as evidências estiverem legíveis, ou `BLOCKED/INCONCLUSIVE` caso contrário. A configuração não é adotada automaticamente no dashboard final.

**Estados mantidos:** `C2W_COLUMNS_AND_FRAMES_COM=PASS_LOCAL_CANDIDATE_ONLY`; `C2W_SIZE_TO_DATA_GUI=PENDING`; `C2W_VISUAL_REVIEW=PENDING`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `T26_GENERAL=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. PR #120 Draft, sem merge, main inalterada.

## 6. Auditoria independente da apresentação C2-W — S0/S1 funcionais, cabeçalhos BLOQUEADOS

**Fonte da evidência:** três capturas enviadas diretamente nesta conversa pelo responsável, referentes ao novo arquivo `SAD_C2W_T26_LAYOUT_TEST.qvw` sob `%TEMP%/SAD_VIII_C2W_04f58b85152b4794b0bf4809b4e10f3c`. Imagens efetivamente inspecionadas, com metadados e SHA-256 recalculados sobre **seus próprios bytes**; não houve leitura do QVW binário nem recarga independente:

| Evidência enviada | Dimensões (pixels) | SHA-256 independente | Observação |
| --- | --- | --- | --- |
| `image(20261019-125138).png` — S0 permitido | 1272×747 | `441D716FC42A678447187A867C8F5A5AE362584675011E3A693277081488A4D4` | Ano `2018` + serviço `250750` selecionados; `31,21` e linha 2018 visíveis, sem `#####`; objeto continua largo; cabeçalhos de colunas ainda mostram `...` e `Internacoes ...` |
| `image(20261019-125156).png` — propriedade | 1299×768 | `3488E8CAFC11DB2E01E98572944B22B884964A7608ACC845BB365D2F329DFCBD` | Aba Layout/Opções do gráfico com `Ajustar o tamanho aos dados` **desmarcado** na cópia C2-W; título exibe `*`, indicando alterações em memória quando fotografado |
| `image(20261019-125346).png` — S1 bloqueado | 1277×750 | `40EDE78AA884C106E620297F951EFC99725BA793B4F74B28938B98207DC61BD0` | Ano `2018`, serviço `250750` e um procedimento em verde; condição não satisfeita; aviso **completo** de filtro P5 B; gráfico largo |

**FATO VISUAL VERIFICADO:** o gráfico **não encolheu no S0**, exibiu `31,21` e deixou de calcular corretamente no S1, com aviso integral. A caixa `Ajustar o tamanho aos dados` está visualmente desmarcada **na cópia C2-W**, confirmada por screenshot. O título do QVW em S1 não apresenta o `*`; isso é **compatível** com a aplicação/salvamento da alteração, mas **não substitui SHA/readback em disco após intervenção manual**, nem prova configuração de qualquer QVW canônico.

**PENDÊNCIA DE APRESENTAÇÃO REPRODUZÍVEL:** na linha de cabeçalhos da Straight Table S0, o campo de tempo continua `...` e a medida aparece como `Internacoes ...`, mesmo tendo sido atribuído `ColWidth=155` e `ColWidth=285` com `PASS_COM_READBACK` no executor local. O resultado COM não equivale à **largura efetiva/renderizada** de cada coluna no QlikView. A lista de procedimento está legível como `COD_PROCEDIMENTO`, mas o nome do município de serviço permanece truncado (`SERV_COD_DATASUS...`). **Não afirmar que as larguras de colunas foram visualmente homologadas**, ainda que a largura externa do gráfico tenha sido corrigida.

**Classificação por capacidade:**
- `C2W_SIZE_TO_DATA_GUI=UNCHECKED_VISIBLE` — checkbox desmarcada verificada por screenshot em cópia separada.
- `C2W_S0_FUNCTIONAL_VISUAL=PASS_RESTRICTED` — ano/serviço, 31,21, largura do objeto estável.
- `C2W_S1_BLOCK_WARNING_VISUAL=PASS_RESTRICTED` — filtro P5 B procedimento bloqueia com mensagem integral.
- **`C2W_VISUAL_ACCEPTANCE=BLOCKED_COLUMN_HEADERS`** — sem aprovação integral do layout, devido aos cabeçalhos truncados em S0 e título incompleto da lista de município.
- `C2_FULL=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`; os outros cenários P5 já ensaiados não são reaprovados globalmente por estas duas capturas.

**STOP do gate C2-W atingido:** o objetivo deste gate incluía uma execução COM, uma edição manual em **nova cópia** e evidência visual de S0/S1. As evidências chegaram e a auditoria foi concluída **com apresentação bloqueada**; não reexecutar PowerShell/QlikView nem abrir um novo gate de modo automático. Uma eventual correção futura deve ter escopo independente e **verificar largura efetiva/rotulagem das colunas** em vez de assumir que a propriedade `ColWidth` foi aplicada visualmente; opção possível a examinar em outra Discovery restrita é largura na GUI ou rótulos menores, sem alterar a medida. Não editar modelos, QVDs, QVWs canônicos nem mudar regras P5.

**Estados finais preservados:** `C2W_COLUMNS_AND_FRAMES_COM=PASS_LOCAL_CANDIDATE_ONLY`; `C2W_VISUAL_ACCEPTANCE=BLOCKED_COLUMN_HEADERS`; `C2_FULL=NOT_APPROVED`; `T26_GENERAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. PR #120 Draft, sem merge, `main` inalterada.
