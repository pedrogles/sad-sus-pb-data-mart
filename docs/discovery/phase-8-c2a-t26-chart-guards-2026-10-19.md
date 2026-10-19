# Fase VIII — C2-A: condição de cálculo real em gráfico T26, avisos P5 e D2 pré-despacho (19/10/2026)

**Estado atual:** `C2A_COM_AND_SCREENSHOTS=PASS_LOCAL_CANDIDATE_ONLY`; `C2A_VISUAL_AUDIT=BLOCKED_PRESENTATION` (ver seções 6–7); `C2_FULL=NOT_APPROVED`; `P5_D2_UI=NOT_APPROVED`; `PRODUCTION_APPROVED=False`. **PR Draft, não integrado à main.**

## Objetivo / baseline / evidências autorizadas

**Objetivo fechado:** um **único gráfico experimental de T26 anual** no município de serviço João Pessoa (`250750`), ano 2018, em **cópia descartável** do QVW T24 anual, testando `EvaluationCondition`, `Show Conditional`, componentes numericamente reconciliados, filtros P5 incompatíveis (procedimento, residência e tipo de leito) em cenários isolados e combinados, um período parcial que não pode permanecer rotulado anual, e **dois casos D2 pré-despacho exclusivamente no wrapper**. Capturar **cinco PNGs**, a revisar por inspeção humana/assistente após fornecimento. Não implementar Painel IX nem homologar o T26.

**Governança:** ler `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md` na `main@337943d5c5b77067f842902fc679dbb68db87020` e documentos específicos de V2 §62.3–62.7, Boundary 7, `docs/project/qlikview-powershell-automation.md`, C1 do PR #116 Draft e PRs #111/#114. C1 confirmou **NO-GO** para universo hospitalar historicamente classificado, GO apenas **restrito** a LT total válido observado sob RN21. Fonte técnica do COM: executores históricos de `tools/validar_f4_p5_ui_visual_com.ps1` e `tools/validar_f4_p5_chart_calc_condition_visual_com.ps1` no commit congelado #83 (`26369052...`), cujos testes eram neutros/limitados. **Não refazer** esses testes, nem alterar automaticamente a modelagem entregue.

**Oráculos independentes F1/F2** (SHA-256 conferidos em runtime no `manifest_F1_F2.json` original local):
- `F1_servico_ano.csv`: João Pessoa 2018, internações elegíveis `73105`, papel serviço;
- `F2_lt_municipio_ano_cobertura_candidata.csv`: João Pessoa 2018, soma **auditável** de 12 snapshots LT `28106` e `12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED`, `hospitalar_historico_validado=NAO`.
- **Cálculo T26 anual candidato:** `12 * Sum(QTD_INTERNACAO) / Sum(QTD_LEITOS_SUS)`, somente para esse recorte com 12 snapshots LT observados; não representa taxa de ocupação, não usa POP e não generaliza cobertura hospitalar.

## Executor e escopo físico

**Código versionado:** `tools/Invoke-SadPhaseViiiC2aT26ChartGuards.ps1`. A origem precisa ser exatamente o QVW temporário `SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac/SAD_VIII_T24_ANNUAL_TEST.qvw` do gate T24, SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`. Nunca abrir esse QVW como destino de escrita; o executor cria **nova cópia** em `%TEMP%/SAD_VIII_C2A_<GUID>/SAD_C2A_T26_DISPOSABLE.qvw`. **Único `Save()` permitido** é no QVW novo, com gráfico, textos e listas. Não há `Reload()`, `STORE`, edição de QVS, QVD ou QVW canônico. SHA-256 dos **22 QVDs**, dos QVWs canônicos existentes e do QVW TEMP fonte devem permanecer idênticos antes/depois. O `LINK_ANALISE.qvd` exige SHA-256 congelado do gate VI.

**COM utilizado, já experimentado no #83:** `GetSheet(0)`, `CreateStraightTable()`, `AddDimension()`, `AddExpression()`, `EvaluationCondition.v`, `CreateTextObject()`, `Layout.Frame.Show.Expression.v` e `CreateListBox()`. **Nota histórica da preparação:** antes da primeira execução, o runner não havia sido validado no Windows. A execução COM/captura posteriormente reportada está registrada na seção 6; o conteúdo e a legibilidade das capturas permanecem sem inspeção visual nesta revisão. Falha COM de método, mensagem, foco, janela ou hash => STOP.

### Matriz contratada

| Caso | Contexto | Componente físico esperado | Status admissível |
| --- | --- | --- | --- |
| `S0_ALLOWED` | `PERIODO_ANO=2018`, `SERV_COD_DATASUS_6=250750`, nenhum filtro B/R nem competência | Numerador Qlik `73105`; soma 12 LT `28106`; `EvaluationCondition=1`; tabela T26 expressa `12*N/LT` | `COM_CANDIDATE` + PNG; somente auditoria posterior confirma renderização correta |
| `S1_BLOCK_PROCEDURE` | Acrescenta `COD_PROCEDIMENTO` com valor **obtido pelo Qlik**, sem inventar código | `EvaluationCondition=0` e texto P5 B visível proposto | `COM_CANDIDATE` + PNG, não é bloqueio de seleção UI |
| `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE` | Também seleciona `RES_COD_DATASUS_6` obtido pelo Qlik | `EvaluationCondition=0`; incompatibilidades não se cancelam | `COM_CANDIDATE` + PNG |
| `S3_BLOCK_BED_TYPE` | Contexto base + `COD_TIPO_LEITO` obtido pelo Qlik | `EvaluationCondition=0` | `COM_CANDIDATE` + PNG |
| `S4_PARTIAL_NOT_ANNUAL` | Contexto base + `PERIODO_COMPETENCIA=201801` | **Este gráfico é anual**, deve ficar indisponível, condição `0`; não prejudica viabilidade de razão parcial separada | `COM_CANDIDATE` + PNG |
| `S5_RESTORED` | Limpeza e retorno a ano 2018 + serviço JP | `EvaluationCondition=1` | `COM_CANDIDATE`; não há 6ª captura |
| `D2_OLD_MONTH_TO_CONFLICTING_YEAR` | Mês 201801 atual, proposta de ano 2019 | Wrapper **não envia** proposta COM, seleção preservada | `WRAPPER_ONLY_NOT_UI` |
| `D2_OLD_YEAR_TO_CONFLICTING_MONTH` | Ano 2019 atual, proposta de mês 201801 | Wrapper **não envia** proposta COM | `WRAPPER_ONLY_NOT_UI` |

**Abrangência e limites:** condição de cálculo restringe este gráfico anual a *somente* 2018/JP, sem competência parcial, sem papéis incompatíveis e com leitos observados positivos; não é expressão geral de T26 nem solução automática para todos os KPIs. Os quatro códigos P5 C/R/I/B estão **somente no contrato V2**; este subgate cobre algumas instâncias B, contexto C e o veto de KPI anual sob janela parcial. Não autoriza dizer que P5 está implementado integralmente, que filtro I está isolado nem que seleção de lista manual é interceptada antes de alterar o contexto. Os avisos propostos devem ser inspecionados **visualmente** após captura. A opção R por estabelecimento também fica indisponível no gráfico genérico sem uma nova definição de indicador.

## Aceite e condição de parada

- **PASS técnico local candidato:** parser Windows `PARSER=PASS`; script versionado, HEAD e QVW original verificados; hashes de oráculos F1/F2; propriedades COM Set/Get idênticas; cálculos numericamente reconciliados; estados de condição 1/0 conforme matriz; duas decisões D2 no wrapper sem disparar COM; **5 PNGs** com SHA e mudança de pixels entre S0/S1 e S0/S4; integridade final dos 22 QVDs/QVWs originais. Só após todas as condições o runner pode emitir `VERDICT=PASS_LOCAL_C2A_T26_CHART_COM_5_SCREENSHOTS_D2_WRAPPER_2_CANDIDATE_ONLY`.
- **PASS visual restrito depende de revisão posterior:** abrir os cinco PNGs e verificar se gráfico, advertência e bloqueio aparecem, sem corte/ocultação/erro visível. Mesmo isso não constitui homologação visual final dos dashboards.
- **BLOCKED/INCONCLUSIVE:** qualquer erro do parser, COM, código de amostra, screenshot, denominador, contexto, prova SHA ou renderização, com STOP, preservação do diretório TEMP e relatório stdout. **Não repetir automaticamente**. Se faltarem capturas ou evidência visual, `VISUAL_AUDIT=PENDING`.
- **Não automatizar UI que não existe:** D2 continua `UI_INTERCEPTION=NOT_TESTED`. Conclusão dos casos P5 B no chart **não** demonstra aplicação em todos os outros objetos.

### Execução uma única vez no Windows (após parser)

A partir da raiz do clone já atualizada, trocar para a branch Draft desta prova:

```powershell
git fetch origin
git switch --track origin/test/phase-viii-c2a-t26-chart-guards-20261019
git rev-parse HEAD
```

Em um **único bloco fail-closed**: conferir HEAD esperado, usar `[System.Management.Automation.Language.Parser]::ParseFile()` e só emitir `PARSER=PASS` se não houver erros. Depois executar uma vez:

```powershell
$source=Join-Path $env:TEMP 'SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac\SAD_VIII_T24_ANNUAL_TEST.qvw'
$f1=Join-Path $env:TEMP 'sad-f1-f2-20261014-191743'
powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiC2aT26ChartGuards.ps1 -Root (Get-Location).Path -SourceQvw $source -F1F2Dir $f1 -RunQlik
```

**Requisito de visualização:** QlikView Desktop 12 em sessão Windows interativa com janela acessível/visível. Se o desktop estiver bloqueado, remoto sem renderização ou uma janela diferente em primeiro plano, STOP em vez de aceitar captura fictícia. Após executar, enviar o stdout e **as cinco imagens** do diretório TEMP; podem ser reunidas em um ZIP **apenas de evidências**, não contendo QVD/QVW brutos, credenciais nem dados pessoais. Não versionar esses artefatos no Git.

## Estados não modificados

`CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `T26_GENERAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. **PR Draft; nenhum merge, nem modificação na main.**

## 6. Execução local reportada — PASS técnico candidato; auditoria visual pendente (19/10/2026)

**Proveniência:** stdout Windows PowerShell / QlikView Desktop 12 fornecido pelo responsável, **não reprodução independente**. O comando combinado executou `git fetch`, `git switch --track`, comparação de HEAD, parser `PARSER=PASS` e o script em `-RunQlik` (somente uma tentativa). Branch: `test/phase-viii-c2a-t26-chart-guards-20261019`; **commit exatamente executado** `8a71179cba195d4314307858f5045bffb864a6b0`; runner SHA-256 reportado `6B75536D595D52D2D6D2DDEB964D4C2ABB5EA5B9252F3DE6AB9C14332CB640D6`. QVW TEMP de origem SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`.

**Diretório exclusivamente no Windows, não acessado diretamente nesta sessão:** `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2A_a0cfc47061ce412b8bfd6b271204921d`. QVW de teste `SAD_C2A_T26_DISPOSABLE.qvw` foi salvo **somente como cópia descartável**, conforme `TEMP_QVW_SAVED_ONLY_DISPOSABLE=True`; `MODE=TEMP_COPY_NO_RELOAD_CANONICAL_WRITE QVD_WRITES=0`.

**Oráculos com SHA verificado pelo runner:**
- `F1_servico_ano.csv` SHA-256 `EDE0F700887262B47A510D931A459C6B712AC6B8464C777C387029FDABC12A00`.
- `F2_lt_municipio_ano_cobertura_candidata.csv` SHA-256 `97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D`.

**Resultado técnico numérico/COM:** `ORACLES_F1_F2_JP_2018=PASS_RD_73105_LT_SNAPSHOT_SUM_28106_HOSPITAL_NOT_VERIFIED`; `T26_BASELINE_F1=73105 QLIK=73105 LT_F2_SUM12=28106 QLIK=28106 RATE=PASS_CANDIDATE`. Expressão experimental para o **objeto anual restrito**: `12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS)`, com tolerância do teste até `0.000001`; soma LT=28.106 representa **soma auditável de snapshots**, não estoque anual de leitos. O valor da razão não foi transcrito no stdout; seu PASS deriva da asserção executada no código versionado.

**Propriedades criadas e lidas de volta:** `TEXT=HEADER/CAVEAT/BLOCK_PROC/BLOCK_RES/BLOCK_BED/BLOCK_MONTH PROPERTY_READBACK=PASS_COM_ONLY`; gráfico com `EvaluationCondition` igualmente relida em cada cenário. Estado do gráfico (expressão da condição, **não observação visual**):

| Caso | Resultado da condição | Fonte do veredito |
| --- | --- | --- |
| `S0_ALLOWED` | `EVAL=1 EXPECTED=1` | `P5_C_YEAR_AND_SERVICE` |
| `S1_BLOCK_PROCEDURE` | `EVAL=0 EXPECTED=0` | `P5_B_PROCEDURE` |
| `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE` | `EVAL=0 EXPECTED=0` | `P5_B_B_PAIR` |
| `S3_BLOCK_BED_TYPE` | `EVAL=0 EXPECTED=0` | `P5_B_BED_TYPE` |
| `S4_PARTIAL_NOT_ANNUAL` | `EVAL=0 EXPECTED=0` | `D1_PARTIAL_ANNUAL_OBJECT_UNAVAILABLE` |
| `S5_RESTORED` | `EVAL=1 EXPECTED=1` | `P5_C_RESTORED` |

**Cinco capturas realizadas, mas ainda sem auditoria visual de seu conteúdo:** os hashes no stdout são:

| Imagem no EVIDENCE_DIR | SHA-256 |
| --- | --- |
| `S0_ALLOWED.png` | `B16CD8BE50D0852CC077EBAA3CEE6F0A7D7BD7114DCE5FB114F4908B36DC71AA` |
| `S1_BLOCK_PROCEDURE.png` | `128C9AC5220EEA72ADBE23EDDFCF9AB6F96C0C3E70F0E03E63E72D27D6159AAC` |
| `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE.png` | `FC43511DC348E082A9ED86E95883C8E0416C13E82BC2CF07A8B8F040A40E458D` |
| `S3_BLOCK_BED_TYPE.png` | `959D114C177CF5C9056C952EF69D4A24034926AFFB8C67FE3E0102379AA1833A` |
| `S4_PARTIAL_NOT_ANNUAL.png` | `7687AC6476655A15205547DFD1ABC532CC747F8620E17673E4AAAAE04F1CBDC2` |

`SCREENSHOTS_5_CAPTURED_PIXEL_TRANSITION=PASS_NOT_VISUAL_AUDIT` demonstra somente que os arquivos existem, são hashados e ao menos dois contrastes têm pixels diferentes. **Não atesta legibilidade, bloqueio visível, ausência de erro gráfico nem aprovação UX**. A próxima etapa limitada é **receber apenas os cinco PNGs, sem QVW/QVD**, e inspecioná-los contra a matriz contratada. **Não executar outro runner QlikView agora.**

**D2 estritamente externo à UI:** dois casos de contradição ano×competência resultaram em `PREVENT_BEFORE_COM_DISPATCH DISPATCHED=False UI_INTERCEPTION=NOT_TESTED`. Não há interceptação de cliques/seleções manuais implementada no QVW.

**Integridade reportada após a execução:** `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`; `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`; `SOURCE_T24_QVW_SHA256_UNCHANGED=True`. Veredito do executável, **após esses checks**: `VERDICT=PASS_LOCAL_C2A_T26_CHART_COM_5_SCREENSHOTS_D2_WRAPPER_2_CANDIDATE_ONLY`.

**STOP alcançado para o subgate COM/captura:** `C2A_COM_AND_SCREENSHOTS=PASS_LOCAL_CANDIDATE_ONLY`; `C2A_VISUAL_AUDIT=PENDING`; `C2_FULL=NOT_APPROVED`. Não repetir o QlikView nem desenvolver sequencialmente novos gates por esse PASS. `P5_D2_UI=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `T26_GENERAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. **PR #117 permanece Draft, sem merge**, e `main` continua intocada.

## 7. Auditoria independente das cinco capturas — BLOQUEIO DE APRESENTAÇÃO (19/10/2026)

**Material realmente inspecionado neste gate:** arquivo anexado pelo responsável `C2A_VISUAL_EVIDENCE.zip`, extraído e aberto visualmente nesta sessão. Contém **exatamente cinco PNGs**, cada um com dimensões **1260×731 pixels**. Seus SHA-256 foram **recalculados sobre os bytes extraídos** e coincidiram exatamente com os cinco valores do stdout listados na seção 6 (S0–S4). A presente evidência comprova **a integridade dos PNGs recebidos e o conteúdo visual visível neles**; não reabre o QVW binário, o log COM ou os oráculos F1/F2.

### Matriz de observação visual independente

| PNG | Condição visível | Alertas e legibilidade | Veredito visual |
| --- | --- | --- | --- |
| `S0_ALLOWED.png` | Gráfico anual exibe uma linha de 2018 com valor numérico aproximado `31,21...`; não mostra bloqueio | Cabeçalhos técnicos `12*Sum(QTD_...)` truncados, uma célula de resumo/total como `#####`, título e ressalva metodológica cortados | `BLOCKED_PRESENTATION` |
| `S1_BLOCK_PROCEDURE.png` | Gráfico mostra **“Condição de cálculo não satisfeita”** sob procedimento selecionado | Texto visível `P5 B: PROCEDIMENTO - KPI GERAL INDISPO...`, cortado; motivo completo não pode ser lido | `BLOCKED_PRESENTATION` |
| `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE.png` | Mesmo bloqueio visível com procedimento e município de residência selecionados | Duas mensagens P5 B aparecem, mas **ambas estão truncadas**, inclusive `P5 B: RESIDENCIA - KPI DE SERVICO INDISP...` | `BLOCKED_PRESENTATION` |
| `S3_BLOCK_BED_TYPE.png` | Bloqueio visível sob filtro de tipo de leito | `P5 B: TIPO DE LEITO - RELACAO GERAL INDI...` cortado; motivo completo não visível | `BLOCKED_PRESENTATION` |
| `S4_PARTIAL_NOT_ANNUAL.png` | Bloqueio visível sob período parcial `201801` | Alerta `PERIODO PARCIAL: ESTE OBJETO E SOMEN...` truncado; faltam detalhes do vínculo com KPI anual | `BLOCKED_PRESENTATION` |

**Observação adicional consistente nos cinco quadros:** o gráfico e as caixas de texto são muito estreitos e ficam concentrados na região superior esquerda da folha, com grande área vazia. O layout em 1260×731 não aproveita a largura disponível, e títulos/listas apresentam abreviações involuntárias. As capturas suportam **bloqueio visual de cálculo nos quatro casos e restauração numérica apenas reportada via COM no S5 (não capturado)**. Não permitem concluir que todas as mensagens sejam legíveis, que o KPI esteja apresentado adequadamente ou que a interação manual D2 já esteja impedida pela UI.

### Veredito separado e critérios de correção futura

- `C2A_HASHED_PNGS=5_OF_5_VERIFIED_INDEPENDENTLY`.
- `C2A_VISUAL_BLOCK_STATES=4_OF_4_VISIBLE_WITH_DEFAULT_QLIK_CONDITION_MESSAGE` — **efeito de bloqueio demonstrado**, sem conferir interceptação de filtro na interface.
- `C2A_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION` — **não é PASS visual restrito**: textos e cabeçalhos truncados; saída numérica apresenta `#####`.
- `C2A_COM_AND_SCREENSHOTS=PASS_LOCAL_CANDIDATE_ONLY` permanece válido para as asserções já executadas; nenhuma promoção para `C2_FULL=APPROVED`, `P5_D2_UI=APPROVED` ou `PRODUCTION_APPROVED=True`.

**Decisão de STOP:** concluir **esta revisão visual** no bloqueio identificado. **Não repetir** execução C2-A/QlikView sem novo escopo. Correção possível somente em **gate visual delimitado e autorizado**: ajustar largura/posição física das caixas e colunas no **QVW novo descartável**, fornecer cabeçalho legível para o indicador T26 e rótulo/unidade, formatar linha numérica/total sem `#####`, exibir integralmente cada aviso P5 e a indisponibilidade de período parcial e então gerar **novas capturas para reauditoria**. A edição de estilo não altera a regra V2, a fórmula, a capacidade observada nem os oráculos. Se o objeto não permitir posicionamento via COM, marcar `BLOCKED` em vez de assumir que `SetFrameDef` garante pixels renderizados; exigir comprovação na imagem real.

**Gates preservados:** `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. `main` e os 22 QVDs não foram alterados por esta auditoria de arquivos PNG. PR #117 continua Draft, sem merge.
