# SAD MVP — GUI smoke nativo F01 | ano 2019 sem Reload/Save

**Data do protocolo:** 07/11/2026. **Gate delimitado:** `MVP-F01-GUI-2019-NATIVE-READONLY-01`. **Estado:** `PROTOCOL_VERSIONED_NOT_EXECUTED`. **Objetivo único:** observar seleção temporal nativa válida `PERIODO_ANO=2019` na QVW TEMP corrigida, sua propagação para as visões FI e a tabela POP, com estado aplicado visível. Não homologar o contrato global C2, C3, C4, filtros P5 ou produção.

## Autoridade e invariantes

1. Ordem: `main:AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md`; [V2 §62.3/§62.6](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) e [D2-R2 V3](../discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md); [B1 MVP aprovado](mvp-scope-owner-approved-2026-11-07.md); [visualização M3 corrigida](mvp-three-sheets-visual-review-2026-11-07.md).
2. Origem operacional local: somente **cópia de inspeção** em `%USERPROFILE%\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_0f6b3b19ce714295ba80e5c27856c08e\SAD_MVP_THREE_SHEETS_CANDIDATE_INSPECAO.qvw`. O candidato `SAD_MVP_THREE_SHEETS_CANDIDATE.qvw`, a QVW M1 e os 22 QVDs+3 QVWs canônicos **não** devem ser salvos/alterados.
3. Sem COM, script, edição de propriedades, criação de objetos, `Reload`, `Save`, `Set Clear State`, bookmarks, múltiplas seleções, ou substituição do modelo. Não acionar mudanças na `main`. Apenas **uma seleção gráfica 2019**, navegar entre abas, capturar telas e desfazer/limpar.
4. Esta é uma **inspeção experimental da interação nativa**, não a prova do mecanismo de prevenção guiada D2-R2 (controles guiados excluídos do MVP), nem equivalência à aprovação C2. A validade se avalia pelo estado **efetivamente selecionado**, nunca pelo QVW anterior.
5. Oráculos existentes: 2019 SIH/RD `188246` novas internações e 12 competências `201901..201912`; POP 2019 `4018127` no universo PB — **não** somar populações de anos, e a tabela M3-03 oculta o total por desenho. M3-01 triênio `294635+260454=555089` é **referência sem filtro**, não deve ser reutilizado como esperado para 2019. O fluxo 2019 deve reconcil iar apenas com 188246, sem inventar partições anuais. P23 tem isolamento próprio e não deve ser interpretado como medida de FI.

## Passos executáveis pelo responsável no QlikView Desktop 12

1. Se a cópia acima já estiver aberta, mantê-la. Caso contrário, abrir **somente** ela. Em **Seleções → Limpar**, retornar ao estado inicial; abrir **Exibir → Seleções Atuais** (janela flutuante da seleção aplicada). Confirmar que não há valor temporal previamente selecionado ou bloqueado. **Se houver seleção inesperada/lock não removível, STOP `INCONCLUSIVE_PRESTATE`**.
2. Ir a **Produção Hospitalar**, clicar **uma vez** na barra `2019` do objeto **M1-01 — Novas internações por ano**. Conferir na janela Seleções Atuais o campo **`PERIODO_ANO` = `2019`**. Se a seleção não for aplicada ou selecionar outro campo, **STOP `BLOCKED_SELECTION_ROUTE`**, sem tentar outros menus/atalhos.
3. Sem alterar seleção, capturar **screenshot S1 da folha 1** com a janela Seleções Atuais aberta. Conferir o recorte M1-01 (2019 = 188246) e M1-02 (somente meses `201901..201912` como competências ativas; não exibir 2017/18 como período corrente). A tela por si pode não exibir o número exato: anotar apenas o que for visível, não inferir por altura de barras.
4. Sem alterar seleção, ir a **Fluxos e Contexto Territorial** e capturar **screenshot S2 da folha 3** também com a janela Seleções Atuais aberta. Critérios: M3-02 total FI = **188246**; M3-01 com duas categorias classificadas, cujo total, se visível/apurável, também é **188246**; M3-03 preserva linhas de município por **2019** e não apresenta `2017/2018` como linhas ativas nem o total trianual `12040181`. Pode usar como sentinela a linha municipal `250010`/2019/`10234` da captura anterior, se a linha estiver visível; sua ausência visual por rolagem **não** é falha.
5. Após as duas capturas, **Seleções → Limpar** e conferir retorno ao estado sem seleção temporal. Não salvar o QVW. Enviar S1 e S2 ao agente para classificação; **não executar outros filtros neste gate**.

## Matriz de decisão e condição de parada

| Critério | PASS restrito | BLOCKED/INCONCLUSIVE |
|---|---|---|
| Seleção nativa aplicada | `PERIODO_ANO=2019` em Seleções Atuais | Nenhuma/indefinida/valor diferente → BLOCKED |
| SIH/RD recorte temporal | 188246 novas internações em 2019; série mensal respeita 12 meses reais | Exibe 555089 como total de um ano, ou publica meses excluídos como ativos → BLOCKED |
| Propagação FI→M3 | M3-02 soma 188246; M3-01 categorização continua condizente | Soma 555089 como se fosse recorte 2019, ou classificação errada → BLOCKED |
| POP descritiva | Linhas 2019 apenas, por município; sem total de múltiplos anos | Exibe população de outros anos como se fosse 2019, total trianual ou resultado enganoso → BLOCKED |
| Prova visual | Capturas S1/S2 e estado aplicado legível | Estado ilegível/ausência de célula de referência necessária → INCONCLUSIVE |
| Segurança operacional | Apenas cópia GUI, sem Reload/Save | Qualquer alteração, erro crítico ou sugestão de mudar esquema → STOP |

**Veredito futuro possível:** `MVP_F01=PASS_RESTRICTED_NATIVE_2019`, `BLOCKED` ou `INCONCLUSIVE`, **somente após captura e revisão reais**. Sem promoção automática a `C2_GUIDED_R2`, `LINK_KEY_CONTRACT`, `MEASURES_AND_DENOMINATOR_CONTRACT`, `P5_D2_UI`, `PHASE_IX` ou `PRODUCTION_APPROVED`.

**Condição STOP:** encerrar ao enviar S1/S2 ou no primeiro erro crítico. Testes de município RES/SERV e isolamento P23 são **gates separados** (não iniciar automaticamente). Após sucesso, não repetir F01; prosseguir para menor cenário de papel territorial com oráculo específico.


## Evidência GUI F01 — capturas reais após seleção nativa de 2019

**Data:** 07/11/2026, QlikView x64 Personal Edition no QVW de inspeção `SAD_M2_MVP_TEMP_0f6b3b19ce714295ba80e5c27856c08e/SAD_MVP_THREE_SHEETS_CANDIDATE_INSPECAO.qvw`. **Fonte:** duas capturas de tela recebidas e inspecionadas diretamente pelo agente nesta conversa; a execução GUI foi realizada pelo responsável. As imagens não são versionadas no Git; os hashes abaixo foram calculados dos bytes PNG recebidos.

| Captura | Arquivo fornecido no chat | Tamanho | SHA-256 |
|---|---|---|---|
| **S1 — Produção Hospitalar** | `image(20261107-160729).png` | 1907×1068 | `739D5E768A498222A8CEB2F659236F1596A93B17426BF56724EA734D63AE91D8` |
| **S2 — Fluxos e Contexto Territorial** | `image(20261107-160745).png` | 1907×1068 | `9F612EB42BD72E92F319DA9EA5EF86ED9C93B6D8941328AF7C0045AD772E1D1A` |

### Matriz de verificação pelo que está visível

| Critério F01 | Observação direta | Veredito |
|---|---|---|
| Estado aplicado | Janela `Seleções Atuais` mostra campo temporal `PERIODO_ANO` visualmente truncado e valor **2019**, marcador verde nas duas folhas | `PASS_GUI_2019_SELECTED` |
| M1-01 | Gráfico anual exibe somente categoria `2019`; barra perto de 188 mil, **sem rótulo numérico exato** | `PASS_GUI_FILTERED_ANNUAL; VALUE_INFERRED_FROM_M3_NOT_PIXELS` |
| M1-02 | Linha mensal reconfigurada para uma série anual aparente; **eixo X/valores das competências não aparecem na captura porque a parte inferior do gráfico está fora da janela visível**. Não é possível comprovar 12 competências `201901..201912` individualmente pela imagem | `INCONCLUSIVE_MONTH_LABELS` |
| M1-03 | Ranking SERV recalculado, mas eixo X muito denso e legibilidade pendente; não foi fornecido ranking esperado deste recorte | `RENDERED_ONLY` |
| M3-01 | As duas categorias `RES_EQ_SERV` e `RES_NE_SERV` persistem sob o estado selecionado, com barras reduzidas; sem números impressos nos retângulos, **não** é possível verificar as duas partes em 2019 | `PASS_GUI_CLASSES; ANNUAL_PARTITION_NUMBERS_UNVERIFIED` |
| M3-02 | Cabeçalho da tabela de pares RES→SERV exibe total **188246** exatamente, coerente com o oráculo FI para 2019 | `PASS_NUMERIC_2019_FLOW_TOTAL` |
| M3-03 | Linhas visíveis exibem exclusivamente `2019`; sentinela município `250010` / ano `2019` / população `10234`; o total trianual 12040181 **não aparece no trecho visível** | `PASS_GUI_2019_POP_ROWS_RESTRICTED` |

**Interpretação:** as duas capturas demonstram com confiança a propagação da seleção de 2019 ao menos entre o gráfico anual M1-01, a tabela de fluxo M3-02 e as linhas POP da M3-03. Não há prova da soma das partições de M3-01 por ano, 12 rótulos de competência ou inspeção da tabela POP até o rodapé. Também não há imagem posterior à ação de limpar; não presumir o retorno do estado inicial como validado.

**Veredito estrito:** `MVP_F01_SELECTION_PROPAGATION=PASS_RESTRICTED_NATIVE_2019_SCREENSHOTS`; `MVP_F01_MONTH_AXIS=INCONCLUSIVE_NOT_VISIBLE`; `MVP_F01_FULL_ACCEPTANCE=INCONCLUSIVE`; `MVP_F01_RESTORE_AFTER_CLEAR=NOT_EVIDENCED`; `MVP_P5_FI_POP_ASSOCIATION=NOT_APPROVED`.

**STOP deste gate:** encerrar F01 como **prova parcial suficiente de um estado válido**, sem repetir o teste integral por padrão. A ausência de eixo temporal visível e a impossibilidade de conferir os dois subtotais por captura são lacunas de visualização/prova, não autorização para alterar o modelo ou afirmar um erro quantitativo. Se for exigido PASS integral deste roteiro, adicionar prova pontual de competências (sem reconstruir QVW e sem reproduzir todas as etapas). Para o próximo gate, avaliar separadamente **um cenário municipal RES/SERV** com oráculo previamente estabelecido e critério de parada; não confundir com autorização para C3 global ou uso final. Sem COM, Reload, Save, merge, dados canônicos, produção, C2/C3/C4/P5/IX.
