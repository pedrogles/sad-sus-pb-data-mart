# Fase VIII — C2-V: correção visual restrita do gráfico T26 após BLOCKED_PRESENTATION (19/10/2026)

**Estado:** `C2V_VISUAL_REFLOW=VERSIONED_NOT_EXECUTED`; **nenhuma execução Windows deste novo script**. Branch originada de `main@337943d5c5b77067f842902fc679dbb68db87020`. **PR Draft, sem merge ou alteração de dados e dashboards canônicos**.

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
