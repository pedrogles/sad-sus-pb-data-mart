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
