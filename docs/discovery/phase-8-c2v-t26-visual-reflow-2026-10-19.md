# Fase VIII — C2-V: correção visual restrita do gráfico T26 após BLOCKED_PRESENTATION (19/10/2026)

**Estado atual:** `C2V_COM_GEOMETRY_LABEL_FORMAT_AND_CAPTURE=PASS_LOCAL_CANDIDATE_ONLY`; `C2V_VISUAL_AUDIT=COMPLETED_WITH_BLOCKED_BASELINE_LAYOUT` (ver seção 8); `C2V_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION`. **PR Draft; nenhuma aprovação visual completa de C2-V, C2/P5/D2, de indicador geral ou de produção.** Branch originada de `main@337943d5c5b77067f842902fc679dbb68db87020`. **PR Draft, sem merge ou alteração de dados e dashboards canônicos**.

## 1. Problema comprovado e objetivo limitado

Na auditoria independente das cinco capturas originais do PR #117 (ver `docs/discovery/phase-8-c2a-t26-chart-guards-2026-10-19.md`, seção 7) houve `C2A_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION`: textos e alertas P5 truncados, cabeçalho técnico, célula `#####`, e objetos concentrados no canto superior esquerdo apesar de `SetFrameDef()` invocado no script. Cinco PNGs de 1260×731 pixels tiveram SHA-256 conferido.

**Objetivo único:** reconstruir somente os objetos experimentais no **novo QVW descartável**, corrigir geometria/rótulo/formato da expressão T26 de serviço para João Pessoa 2018, repetir os mesmos **cinco contextos visuais** da auditoria para produzir screenshots de comparação. **Não repetir** os ensaios T24–T26, o gate F1/F2/F3 completo, o wrapper D2, T17–T23, carregamentos ou testes estruturais já encerrados.

Este não é o `PAINEL.qvw` final nem um novo indicador. `T26` = admissões elegíveis de atendimento no serviço / (soma dos 12 snapshots `QT_SUS` observados / 12), **não taxa de ocupação hospitalar**. Escopo `LT_TODOS_REGISTROS_VALIDOS_RN21`, **sem cobertura hospitalar comprovada**, conforme C1 PR #116 e V2 §62.

## 2. Evidência técnica para a tentativa de correção

**FATO**: no C2-A, o código usou `GetFrameDef().Rect` seguido de `SetFrameDef(frame)` com posições e larguras desejadas, mas a auditoria visual demonstrou que o layout real ficou compacto. A explicação exata de baixo nível **não foi diagnosticada no COM local**.

**HIPÓTESE DE IMPLEMENTAÇÃO testável, não homologada:** documentações e exemplos QlikView sobre macro mostram `SetFrame(frame, true, "")` e fatores de conversão de unidades internas. O ensaio C2-V tentará `SetFrame(...)` com fator candidato **2,5 unidades internas por pixel** e **lerá novamente o `Rect`**; se `SetFrame` não estiver disponível, retornar valores incompatíveis ou a captura mostrar objetos ainda compactos, marcar BLOCKED sem presumir sucesso. Referências externas de técnica, não fonte do requisito acadêmico:
- [Qlik Community — SetFrame, posição e tamanho por macro](https://community.qlik.com/t5/QlikView/How-do-I-change-the-width-and-height-of-an-object-with-a-macro/td-p/1354942);
- [Qlik Community — rótulo da expressão no COM](https://community.qlik.com/t5/QlikView/set-label-in-graph-expression-in-macro/m-p/457790);
- [Manual QlikView — `Num()` preserva componente numérico e define exibição](https://help.qlik.com/en-US/qlikview/May2024/pdf/Working%2520with%2520QlikView.pdf).

**Hipótese para o cabeçalho:** QlikView COM `GetProperties().ExpressionVisuals(0).Label.v` poderá ajustar o rótulo para `Internacoes por leito SUS medio`; o runner exige `SetProperties` e **readback do rótulo**. O gráfico passa a exibir `Num(12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS),'0.00',',','.')`, mantendo **o mesmo valor numérico interno** (função dual) e exibindo duas casas decimais. A reconciliação de componentes e **razão bruta anterior** permanece no runner apenas como smoke de regressão, não novo gate T26; o formato visual esperado para 2018/JP é `31,21`. Não alterar regras de negócios, associatividade, universo nem médias.

## 3. Executor, proteção e critérios

**Único executável novo:** `tools/Invoke-SadPhaseViiiC2vT26VisualReflow.ps1` na branch independente deste gate, **commitado antes de executar**. Inspirado no C2-A, substitui apenas a API de geometria, tamanho/posicionamento, textos e rótulo/formato; **omite os dois casos D2 wrapper anteriormente aprovados**, não implementa interceptação de interface.

**Origem:** QVW já reconciliado em `%TEMP%\SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac\SAD_VIII_T24_ANNUAL_TEST.qvw`, SHA-256 exigido `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`. Escrever/salvar **somente** uma cópia nova `%TEMP%\SAD_VIII_C2V_<GUID>\SAD_C2V_T26_DISPOSABLE.qvw`. Sem `Reload()`, `STORE`, mutação dos 22 QVDs ou QVWs originais. Hash de QVDs/QVWs/origem antes e após; F1 serviço anual e F2 anual de LT verificados contra manifesto original local.

**Matriz de cinco evidências e expectativas:**

| Captura | Seleção QlikView | Verificação visual exigida |
| --- | --- | --- |
| `S0_ALLOWED.png` | Ano 2018, serviço JP `250750`; nenhum P5 incompatível | Título, ressalva, cabeçalho legível; **valor 31,21** formatado; sem `#####`, sem fórmula técnica aparecendo como rótulo |
| `S1_BLOCK_PROCEDURE.png` | Base + procedimento selecionado | Condição de cálculo indisponível; **aviso completo** de procedimento |
| `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE.png` | Base + procedimento + município de residência | Condição indisponível; **dois avisos completos**, sem sobreposição |
| `S3_BLOCK_BED_TYPE.png` | Base + tipo de leito | Condição indisponível; aviso completo de tipo de leito |
| `S4_PARTIAL_NOT_ANNUAL.png` | Base + competência `201801` | Gráfico anual indisponível; aviso **completo** de janela parcial |

`S5_RESTORED` deve avaliar condição `1` e não requer sexta captura; já foi COM PASS no C2-A. A propriedade `EvaluationCondition` será relida e os contextos selecionados verificados, apenas como **regressão da apresentação**.

**PASS local candidato da execução:** parser Windows sem erro; COM SetFrame/label com readback válido; smoke T26 preservado; cinco estados 1/0, cinco PNGs com SHA e mudanças de pixels; 22 QVDs e QVWs originais preservados. **Veredito terminal esperado, caso tudo execute:** `VERDICT=PASS_LOCAL_C2V_GEOMETRY_LABEL_COM_5_SCREENSHOTS_VISUAL_PENDING`. Isto **não** é aceitação visual: fotos deverão ser efetivamente inspecionadas após envio.

**BLOQUEIO:** falha de COM, `Rect` incompatível, rótulo ausente, valor formatado incorreto, erro de contexto, screenshot de janela errada, textos ainda truncados, `#####` ou qualquer hash alterado => `BLOCKED_OR_INCONCLUSIVE`, registrar e **STOP**, não iniciar repetição automática. Não inferir sucesso de `SetFrame` sem imagem. Não versionar PNGs binários, QVW ou dados no Git.

**Ambiente:** Windows PowerShell + QlikView Desktop 12 em sessão interativa com janela realmente visível e desobstruída, preferencialmente mesma geometria **1260×731** da referência. Se diferente, reportar dimensão ao avaliar imagens e evitar extrapolação de layout. Não abrir ou salvar QVWs canônicos.

## 4. Fim do gate e fronteiras preservadas

**Condição de parada:** uma tentativa Windows após parser PASS, seguida de inspeção visual independente dos cinco PNGs se o executor concluir. **Se não houver evidência, manter `C2V=NOT_EXECUTED` ou `BLOCKED`, jamais `PASS_VISUAL`**. Em caso de êxito visual restrito, fechar somente C2-V e propor continuação C2/P5 em tarefa própria. Não expandir para todos os filtros C/R/I/B, outras cidades, D2 UI, fase IX ou produção.

`C2A_COM_AND_SCREENSHOTS=PASS_LOCAL_CANDIDATE_ONLY` permanece histórico; `C2A_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION` não é reclassificado retroativamente. `C2_FULL=NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `T26_GENERAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## 5. Primeira execução C2-V no Windows — bloqueada no acesso ao rótulo

**Proveniência:** stdout da primeira execução PowerShell/QlikView 12 **reportado pelo responsável** (sem auditoria de binário QVW). Branch `test/phase-viii-c2v-t26-visual-reflow-20261019`; **HEAD executado** `1da6554f028e8856835bc516016d1e2aa315be90`; SHA-256 do runner `FF256EF1C93846EE4159960BEB4B92B920649F06F84A863BD408C85A717B1436`; fonte T24 QVW `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`; `PARSER=PASS` real emitido pelo wrapper após HEAD conferido.

**Diretório local da tentativa, não acessado nesta revisão:** `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2V_e4ce8f012fe5427c84eafb2ef8158ab9`.

**Preflight preservado:** oráculos hashados `F1_servico_ano.csv` `EDE0F700887262B47A510D931A459C6B712AC6B8464C777C387029FDABC12A00` e `F2_lt_municipio_ano_cobertura_candidata.csv` `97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D` corresponderam às referências congeladas. `ORACLES_F1_F2_JP_2018=PASS_RD_73105_LT_SNAPSHOT_SUM_28106_HOSPITAL_NOT_VERIFIED`. **Não houve nova reconciliação gráfica do T26 nesta tentativa**, pois o script foi interrompido durante a criação das propriedades de chart.

**Resultado positivo estritamente COM de geometria:** 9 objetos receberam `FRAME_SET_READBACK=PASS_COM_ONLY`, 3 listboxes e 6 textos. Exemplo de leitura de volta: `Document\LB01 TARGET_PIXELS=16,120,192,143 QLIK_RECT=40,300,480,358`; `Document\TX01 TARGET_PIXELS=235,10,950,42 QLIK_RECT=588,25,2375,105`; `Document\TX06 TARGET_PIXELS=235,465,950,42 QLIK_RECT=588,1162,2375,105`. A existência desses valores **não comprova** largura/posição **visual** na janela. Todos os 6 textos informaram `PROPERTY_READBACK=PASS_COM_ONLY`.

**Falha principal inequívoca:** `VERDICT=BLOCKED_OR_INCONCLUSIVE BLOCKED_EXPRESSION_VISUAL_COM_Falha na invocação do método porque [System.__ComObject] não contém um método denominado 'ExpressionVisuals'.`. Linha 267 da versão executada: `$p.ExpressionVisuals(0)`. O stdout terminou também com prefixo legado `C2A_EXECUTION_BLOCKED_...` dentro do runner e `C2V_EXECUTION=BLOCKED` no wrapper. **Este foi um bloqueio de acesso ao rótulo de gráfico, não evidência de incompatibilidade da fórmula T26.** O erro impediu `TEMP_QVW_SAVED_ONLY_DISPOSABLE=True`, as capturas S0–S4 e qualquer aprovação visual do reflow.

**Integridade física reportada após falha:** `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`, `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`, `SOURCE_T24_QVW_SHA256_UNCHANGED=True`. `MODE=TEMP_COPY_NO_RELOAD_CANONICAL_WRITE QVD_WRITES=0` e nenhuma evidência de escrita nas fontes canônicas; cópia TEMP pode ter sido criada/aberta.

**Diagnóstico e correção mínima versionada:** no COM QlikView 12, a invocação direta `ExpressionVisuals(0)` no objeto retornado por `GetProperties()` não é suportada na instalação testada. Exemplo específico publicado na [Qlik Community](https://community.qlik.com/t5/QlikView/Expression-label-change-in-Module/m-p/361023/highlight/true), incluindo observação sobre QlikView 12, acessa `Expressions.Item(0).Item(0).Data.ExpressionVisual`, atribui `Label.v` e usa `SetProperties`. **É uma hipótese técnica com fonte externa, não um PASS no Windows do responsável.**

Ajuste exclusivo no commit `1935a641ae5aca3afe49aa5676e114d750d6ad91`:
- Substituído `$p.ExpressionVisuals(0)` por `$p.Expressions.Item(0).Item(0).Data.ExpressionVisual` para a atribuição do label;
- a **mesma rota** é usada para leitura de volta após `SetProperties`, com mensagens de falha identificáveis e checagem de `Label`;
- corrigido prefixo residual `C2A_EXECUTION_BLOCKED_` para `C2V_EXECUTION_BLOCKED_`, sem mudar seleção, medidas, formato, geometria ou proteção SHA.

**Próximo passo delimitado:** `git pull --ff-only` na mesma branch, conferir o novo HEAD documental, executar `Parser.ParseFile()` no próprio Windows e, somente se `PARSER=PASS`, uma única tentativa do runner com QVW T24 TEMP original e oráculos F1/F2 existentes. Qualquer erro `Expressions.Item`, `LabelAdjust`, `Num()`, screenshot, geometria ou hash => **STOP e preservar log**, sem propor testes ilimitados. Se cinco PNGs forem realmente gerados, enviar só as imagens para **inspeção visual independente**. Não repetir C2-A/D2/T24–T26.

**Estado desta revisão:** `C2V_VISUAL_REFLOW=FIX_VERSIONED_PENDING_WINDOWS_RETEST`, `C2V_VISUAL_ACCEPTANCE=NOT_APPROVED`, `C2_FULL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. PR #118 Draft, sem merge.

## 6. Segunda execução C2-V no Windows — rótulo/geometria COM PASS; máscara numérica BLOQUEADA (19/10/2026)

**Fonte:** stdout Windows PowerShell + QlikView Desktop 12 **reportado pelo responsável**. O wrapper fez `git pull --ff-only`, comparou o HEAD completo `3a2e9d68de9aacaead213b626d0f26ac807f1431`, emitiu `PARSER=PASS` antes de invocar o runner. SHA-256 do executor rodado: `65B644D72F71F135E3F812DF914A38A80C91434A636B7CB9D18470784B33A085`. Fonte QVW TEMP SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`. Evidências locais (não reabertas nesta revisão): `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2V_39729fd0176143479fa1886781883285`.

**Preflight/oráculos:** `F1_servico_ano.csv` SHA-256 `EDE0F700887262B47A510D931A459C6B712AC6B8464C777C387029FDABC12A00` e `F2_lt_municipio_ano_cobertura_candidata.csv` SHA-256 `97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D`. Referências João Pessoa/serviço/2018 conferidas: `RD_ELIGIBLE=73105` e `LT_SNAPSHOT_SUM_12_AUDIT=28106`, `HOSPITAL_NOT_VERIFIED`. **Não interpretar o agregado dos snapshots como estoque anual**.

**Evidência COM positiva delimitada:** os 9 objetos reportaram `FRAME_SET_READBACK=PASS_COM_ONLY` (LB01–LB03, TX01–TX06), o gráfico CH01 retornou `FRAME_SET_READBACK=PASS_COM_ONLY ID=Document\CH01 TARGET_PIXELS=235,116,950,320 QLIK_RECT=588,290,2375,800`. O rótulo por `Expressions.Item(0).Item(0).Data.ExpressionVisual` funcionou no Windows: `CHART_EXPRESSION_LABEL_READBACK=PASS_COM_ONLY`. `TEMP_QVW_SAVED_ONLY_DISPOSABLE=True`. **Esses resultados não provam que a área útil, textos ou valor numérico foram renderizados adequadamente**, pois nenhuma nova captura S0–S4 foi produzida nesta tentativa.

**Bloqueio subsequente:** após o `Save()` do QVW descartável, a comparação do valor de apresentação falhou em `BLOCKED_DISPLAY_FORMAT_QV_VIEW=0.31`. O script usava `Num(12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS),'0.00',',','.')`, máscara contendo `.` enquanto o separador decimal explícito é `,`. A [documentação oficial QlikView, função Num](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Scripting/FormattingFunctions/Num.htm) mostra o formato `Num(A,'0,00',',')` para exibição decimal com vírgula; o padrão com ponto não é intercambiável quando o separador decimal é vírgula. O retorno observado `0.31` demonstra **incompatibilidade de formatação**; a hipótese causal é especificamente a máscara `'0.00'` inadequada para `dec_sep=','`.

**Correção mínima versionada:** commit `e79e57c7412ac36abdd3922ca2220ff3b5073e3f`, substitui **somente as duas ocorrências** da máscara na expressão do objeto e na verificação do valor formatado por `Num(12*Sum(QTD_INTERNACAO)/Sum(QTD_LEITOS_SUS),'0,00',',','.')`. Numerador, soma auditável LT, divisor 12, checagem numérica bruta de T26, seleção, objeto, rótulo, geometria, oráculos F1/F2 e SHA dos QVDs/QVWs **não alterados**. O formato esperado `31,21` continua **uma hipótese a confirmar no QlikView 12 local**, não há PASS desse novo commit.

**Integridade reportada após segundo bloqueio:** `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`, `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`, `SOURCE_T24_QVW_SHA256_UNCHANGED=True`, `MODE=TEMP_COPY_NO_RELOAD_CANONICAL_WRITE QVD_WRITES=0`. Saída `C2V_EXECUTION=BLOCKED` é definitiva para o commit `3a2e9d6`; não substituí-la por PASS posterior retroativo.

**STOP e revalidação futura:** na mesma branch, obter HEAD atualizado, executar parser Windows em bloco fail-closed; uma **única execução** do runner corrigido usando QVW TEMP fonte original e mesmos oráculos. Se novo erro de valor `Num()`, COM, captura ou geometria, STOP e registrar; não afrouxar asserções automaticamente nem repetir outros gates. **Se** produzir cinco PNGs, solicitar inspeção visual independente de todos os avisos e do valor formatado antes de qualquer aceite de layout.

**Estado:** `C2V_VISUAL_REFLOW=MASK_FIX_VERSIONED_PENDING_WINDOWS_RETEST`; `C2V_VISUAL_ACCEPTANCE=NOT_APPROVED`; `C2_FULL=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `T26_GENERAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. PR #118 permanece Draft, `main` inalterada, nenhuma recarga ou merge.

## 7. Terceira execução C2-V — PASS técnico candidato, cinco PNGs aguardam auditoria visual (19/10/2026)

**Origem da evidência:** stdout PowerShell e QlikView 12 fornecido pelo responsável. A execução fez `git pull --ff-only`, HEAD completo conferido, `PARSER=PASS` e uma chamada `-RunQlik` no **commit realmente testado** `02215f687160a6c9cf90a238a4d62023e0e36330`. SHA-256 **do executor testado** `C81CD88F36A536550337D5865A2EED44430FE04AD0192AFD4E42DAA03D65F547`. O documento agora atualizado num commit posterior **não é o commit executado** e não altera o runner.

**Diretório da evidência local (não aberto nesta sessão):** `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2V_83cc8d984d9e438eb76a71d1ff8f6d0f`. QVW de origem T24 SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`. Modo declarado pelo runner `TEMP_COPY_NO_RELOAD_CANONICAL_WRITE QVD_WRITES=0`; somente `SAD_C2V_T26_DISPOSABLE.qvw` salvo no diretório TEMP (`TEMP_QVW_SAVED_ONLY_DISPOSABLE=True`).

**Oráculos F1/F2 já congelados e checados por SHA no runner:**
- `F1_servico_ano.csv` = `EDE0F700887262B47A510D931A459C6B712AC6B8464C777C387029FDABC12A00`.
- `F2_lt_municipio_ano_cobertura_candidata.csv` = `97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D`.

**Provas numéricas locais reportadas, limitadas ao mesmo recorte anterior:** `ORACLES_F1_F2_JP_2018=PASS_RD_73105_LT_SNAPSHOT_SUM_28106_HOSPITAL_NOT_VERIFIED`. `T26_BASELINE_F1=73105 QLIK=73105 LT_F2_SUM12=28106 QLIK=28106 RATE=PASS_CANDIDATE`. Essa soma dos 12 snapshots LT serve apenas para média anual, **não é estoque anual**; internações por leito SUS médio **não equivalem a taxa de ocupação**. Máscara corrigida `'0,00'` confirmou no QlikView local `C2V_DISPLAY_FORMAT_QV=PASS_DISPLAY_31,21`. O PASS do número/mascara **não garante que esse texto apareça completo na célula visual**.

**Propriedades COM:** três listboxes, seis objetos de texto e um gráfico retornaram `FRAME_SET_READBACK=PASS_COM_ONLY`. Gráfico `Document\CH01 TARGET_PIXELS=235,116,950,320 QLIK_RECT=588,290,2375,800`; rótulo `CHART_EXPRESSION_LABEL_READBACK=PASS_COM_ONLY`. Os resultados comprovam leitura de volta de propriedades, mas **não são evidência de posicionamento e visibilidade real dos objetos em pixels**.

| Cenário | Estado de condição no QlikView COM | SHA-256 PNG reportado pelo executor, não recalculado neste documento |
| --- | --- | --- |
| `S0_ALLOWED.png` | `EVAL=1 EXPECTED=1` | `2B1FC055F25D589EE1BEE1ACDB2DD2BAB180FC722E5ED227A381FE4A2566AFC2` |
| `S1_BLOCK_PROCEDURE.png` | `EVAL=0 EXPECTED=0` | `4A36DE0A78A6D4E4A8599CB81EF360136128D0615965BA12F06D1CE8CB9814B1` |
| `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE.png` | `EVAL=0 EXPECTED=0` | `414E2BDF4B251259292E0D5022E91A49C651D899DC5E8ADDD7E52E0BB44C23CC` |
| `S3_BLOCK_BED_TYPE.png` | `EVAL=0 EXPECTED=0` | `7D33164123F6671C1ADA9974A5DB1B80E589986DB51AEC1EA9170E14A47F0DC5` |
| `S4_PARTIAL_NOT_ANNUAL.png` | `EVAL=0 EXPECTED=0` | `941AD81A1F2E71208DE0EFBC580F9DA43B625F03878D2AD72E706E37E20337EB` |
| `S5_RESTORED` | `EVAL=1 EXPECTED=1` | Não há sexto PNG; restauração aferida via COM |

**Resumo experimental:** `C2V_SCREENSHOTS_5_CAPTURED_GEOMETRY_COM_CHECKED_VISUAL_AUDIT_PENDING`; `VERDICT=PASS_LOCAL_C2V_GEOMETRY_LABEL_COM_5_SCREENSHOTS_VISUAL_PENDING`. O valor de condição e os hashes de tela são resultados reportados do executor; **não** houve inspeção independentemente das cinco imagens nesta etapa documental. `D2_PREDISPATCH=ALREADY_PASSED_IN_C2A_NOT_REPEATED C2V_SCOPE=PRESENTATION_ONLY`; **D2_UI_INTERCEPTION=NOT_TESTED** e P5 total não homologado.

**Imutabilidade reportada após execução:** `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`; `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`; `SOURCE_T24_QVW_SHA256_UNCHANGED=True`. Nenhum QVD/QVW original foi acessado diretamente por esta revisão no Git, nem houve aprovação de produção.

**STOP técnico atingido; próximo passo exclusivamente de evidência:** não repetir execução QlikView. Receber somente `S0_ALLOWED.png`, `S1_BLOCK_PROCEDURE.png`, `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE.png`, `S3_BLOCK_BED_TYPE.png`, `S4_PARTIAL_NOT_ANNUAL.png` do diretório TEMP em ZIP; conferir **os cinco hashes** e inspecionar efetivamente todos os painéis: cabeçalho/caveat íntegros, ratio 31,21 legível sem `#####`, mensagens B de procedimento, residência e leito completas, indisponibilidade anual sob mês parcial e ausências de recorte/sobreposição. Se visual ainda inadequado, `C2V_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION` sem alterar PASS técnico. Não versionar binários no repositório.

**Fronteiras mantidas:** `C2V_COM_GEOMETRY_LABEL_FORMAT_AND_CAPTURE=PASS_LOCAL_CANDIDATE_ONLY`, `C2V_VISUAL_AUDIT=PENDING_PNG_INSPECTION`, `C2_FULL=NOT_APPROVED`, `T26_GENERAL=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. PR #118 permanece Draft, sem merge.

## 8. Auditoria independente do ZIP de cinco screenshots — apresentação parcialmente melhorada, S0 BLOQUEADO (19/10/2026)

**Fonte efetivamente inspecionada:** anexo `C2V_VISUAL_EVIDENCE.zip` fornecido pelo responsável nesta conversa. O arquivo ZIP foi aberto diretamente, continha **exatamente os cinco PNGs esperados**, nenhum item adicional; cada PNG tinha resolução **1260 × 731 pixels, RGBA**. SHA-256 **recalculado sobre bytes de cada PNG** concorda com os cinco hashes do runner registrados na seção 7:

| Arquivo inspecionado | SHA-256 recalculado | Veredito de integridade |
| --- | --- | --- |
| `S0_ALLOWED.png` | `2B1FC055F25D589EE1BEE1ACDB2DD2BAB180FC722E5ED227A381FE4A2566AFC2` | `MATCH` |
| `S1_BLOCK_PROCEDURE.png` | `4A36DE0A78A6D4E4A8599CB81EF360136128D0615965BA12F06D1CE8CB9814B1` | `MATCH` |
| `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE.png` | `414E2BDF4B251259292E0D5022E91A49C651D899DC5E8ADDD7E52E0BB44C23CC` | `MATCH` |
| `S3_BLOCK_BED_TYPE.png` | `7D33164123F6671C1ADA9974A5DB1B80E589986DB51AEC1EA9170E14A47F0DC5` | `MATCH` |
| `S4_PARTIAL_NOT_ANNUAL.png` | `941AD81A1F2E71208DE0EFBC580F9DA43B625F03878D2AD72E706E37E20337EB` | `MATCH` |

**Observação visual direta dos cinco arquivos, separada dos resultados COM reportados:**

| Estado | Evidência visual | Decisão restrita |
| --- | --- | --- |
| `S0_ALLOWED` | A linha 2018 e **31,21** estão legíveis; nenhuma célula `#####`; título geral e aviso sobre escopo CNES/LT, não ocupação, estão íntegros. **Entretanto a tabela/gráfico aparece pequena, aproximadamente x=198..393, enquanto os estados bloqueados mostram tabela/gráfico até x≈958.** O título da tabela `Internacoes p...`, cabeçalhos `PERIODO...` e `Internacoes...` aparecem cortados, apesar do rótulo COM haver passado | `BLOCKED_BASELINE_LAYOUT` — não aceitar visual do objeto no contexto permitido |
| `S1_BLOCK_PROCEDURE` | Gráfico ocupa área ampla; texto nativo `Condição de cálculo não satisfeita` aparece, com faixa P5 sobre procedimento **totalmente legível**. Procedimento selecionado aparece em verde | `PASS_VISUAL_RESTRICTED_BLOCK_WARNING` |
| `S2_BLOCK_PROCEDURE_PLUS_RESIDENCE` | Mesma indisponibilidade visível; **duas** faixas completas de aviso P5, procedimento + residência, sem sobreposição; procedimento selecionado visível. O campo de residência selecionado não aparece em lista própria nesta captura; o estado combinado é atestado pelo COM reportado e pelo texto condicional | `PASS_VISUAL_RESTRICTED_BLOCK_WARNINGS` |
| `S3_BLOCK_BED_TYPE` | Gráfico amplo com indisponibilidade e aviso completo de tipo de leito | `PASS_VISUAL_RESTRICTED_BLOCK_WARNING`; filtro tipo de leito em si não exibido na folha |
| `S4_PARTIAL_NOT_ANNUAL` | Gráfico amplo com indisponibilidade e aviso integral sobre competência `201801` incompatível com o **gráfico anual** | `PASS_VISUAL_RESTRICTED_PARTIAL_WARNING`; lista de competência não aparece nesta folha |

**Comparação com C2-A:** rótulo/aviso da parte superior, barras condicionais e formato **31,21** melhoraram e estão legíveis. **Persistem cabeçalhos de campos dos listboxes truncados** (por exemplo `SERV_COD_DA...` e `COD_PROCEDI...`). A principal falha material é a **diferença de geometria do gráfico entre estado permitido S0 e os quatro estados bloqueados**. O teste COM `FRAME_SET_READBACK=PASS_COM_ONLY` não explica por si só o comportamento renderizado; **nenhuma causa de baixo nível pode ser inferida com certeza apenas das imagens**. A comparação ocorreu em mesma resolução 1260×731. Não afirmar que o QVW está globalmente legível nem aprovado visualmente.

**Veredito da auditoria dos arquivos (não do dashboard final):**
- `C2V_PNG_SHA256=5_OF_5_MATCH_INDEPENDENT`.
- `C2V_BLOCKING_VISUAL_STATES=4_OF_4_PASS_RESTRICTED` — visual das mensagens e indisponibilidade, **não prova interceptação de UI nem semântica P5 global**.
- `C2V_ALLOWED_VALUE=31,21_VISIBLE_NO_HASHES`; `C2V_ALLOWED_LAYOUT=BLOCKED_SMALL_CHART_AND_TRUNCATED_HEADERS`.
- **`C2V_VISUAL_AUDIT=COMPLETED_WITH_BLOCKED_BASELINE_LAYOUT`**; **`C2V_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION`**. O `PASS_LOCAL_C2V_GEOMETRY_LABEL_COM_5_SCREENSHOTS_VISUAL_PENDING` da seção 7 continua histórico e válido exclusivamente como **PASS técnico local candidato**; não é convertido em PASS visual geral.

**STOP alcançado para este gate de auditoria visual.** Não repetir a execução já realizada nem abrir novo script automaticamente. Se houver novo objetivo autorizado, propor **uma única correção de renderização restrita ao objeto permitido** (preservar largura efetiva ao avaliar a expressão, cabeçalho da tabela e títulos das listas) em **outro QVW descartável** com capturas comparativas S0 permitido versus S1 bloqueado. Não alterar formula, LT, F1/F2, denominador ou modelo. Antes de testar, investigar tecnicamente por que CH01 parece variar de largura ao passar de uma linha calculada para indisponibilidade, sem inventar solução. Uma correção de UI não pode avançar `P5_D2_UI=APPROVED` nem `PHASE_IX`.

**Proteções/limites não alterados:** `C2_FULL=NOT_APPROVED`, `T26_GENERAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Nenhum QVD, QVW ou dado foi modificado por esta auditoria de PNG. PR #118 Draft; nenhum merge ou edição na `main`.
