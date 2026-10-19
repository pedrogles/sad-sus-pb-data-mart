# Fase VIII — C2-A: condição de cálculo real em gráfico T26, avisos P5 e D2 pré-despacho (19/10/2026)

**Estado:** `C2A_VERSIONED_NOT_EXECUTED`; `C2_FULL=NOT_APPROVED`; `P5_D2_UI=NOT_APPROVED`; `VISUAL_AUDIT=PENDING`; `PRODUCTION_APPROVED=False`. **PR Draft, não integrado à main.**

## Objetivo / baseline / evidências autorizadas

**Objetivo fechado:** um **único gráfico experimental de T26 anual** no município de serviço João Pessoa (`250750`), ano 2018, em **cópia descartável** do QVW T24 anual, testando `EvaluationCondition`, `Show Conditional`, componentes numericamente reconciliados, filtros P5 incompatíveis (procedimento, residência e tipo de leito) em cenários isolados e combinados, um período parcial que não pode permanecer rotulado anual, e **dois casos D2 pré-despacho exclusivamente no wrapper**. Capturar **cinco PNGs**, a revisar por inspeção humana/assistente após fornecimento. Não implementar Painel IX nem homologar o T26.

**Governança:** ler `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md` na `main@337943d5c5b77067f842902fc679dbb68db87020` e documentos específicos de V2 §62.3–62.7, Boundary 7, `docs/project/qlikview-powershell-automation.md`, C1 do PR #116 Draft e PRs #111/#114. C1 confirmou **NO-GO** para universo hospitalar historicamente classificado, GO apenas **restrito** a LT total válido observado sob RN21. Fonte técnica do COM: executores históricos de `tools/validar_f4_p5_ui_visual_com.ps1` e `tools/validar_f4_p5_chart_calc_condition_visual_com.ps1` no commit congelado #83 (`26369052...`), cujos testes eram neutros/limitados. **Não refazer** esses testes, nem alterar automaticamente a modelagem entregue.

**Oráculos independentes F1/F2** (SHA-256 conferidos em runtime no `manifest_F1_F2.json` original local):
- `F1_servico_ano.csv`: João Pessoa 2018, internações elegíveis `73105`, papel serviço;
- `F2_lt_municipio_ano_cobertura_candidata.csv`: João Pessoa 2018, soma **auditável** de 12 snapshots LT `28106` e `12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED`, `hospitalar_historico_validado=NAO`.
- **Cálculo T26 anual candidato:** `12 * Sum(QTD_INTERNACAO) / Sum(QTD_LEITOS_SUS)`, somente para esse recorte com 12 snapshots LT observados; não representa taxa de ocupação, não usa POP e não generaliza cobertura hospitalar.

## Executor e escopo físico

**Código versionado:** `tools/Invoke-SadPhaseViiiC2aT26ChartGuards.ps1`. A origem precisa ser exatamente o QVW temporário `SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac/SAD_VIII_T24_ANNUAL_TEST.qvw` do gate T24, SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`. Nunca abrir esse QVW como destino de escrita; o executor cria **nova cópia** em `%TEMP%/SAD_VIII_C2A_<GUID>/SAD_C2A_T26_DISPOSABLE.qvw`. **Único `Save()` permitido** é no QVW novo, com gráfico, textos e listas. Não há `Reload()`, `STORE`, edição de QVS, QVD ou QVW canônico. SHA-256 dos **22 QVDs**, dos QVWs canônicos existentes e do QVW TEMP fonte devem permanecer idênticos antes/depois. O `LINK_ANALISE.qvd` exige SHA-256 congelado do gate VI.

**COM utilizado, já experimentado no #83:** `GetSheet(0)`, `CreateStraightTable()`, `AddDimension()`, `AddExpression()`, `EvaluationCondition.v`, `CreateTextObject()`, `Layout.Frame.Show.Expression.v` e `CreateListBox()`. **O novo runner não foi validado no Windows**: funcionalidade real, compilação C#, captura de janela e renderização precisam ser medidas, não presumidas. Falha COM de método, mensagem, foco, janela ou hash => STOP.

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
