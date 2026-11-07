# SAD MVP — F04-U1: guarda de incompatibilidade temporal em M2-02 (CH05)

**Data:** 07/11/2026. **Gate:** `SAD-MVP-F04-U1-LT-201912-CONTEXTUAL-GUARD-01`. **Estado:** `DESIGN_AND_SAFE_TEMP_COPY_SCRIPT_VERSIONED_NOT_EXECUTED`. **Origem:** [F04 encerrado `BLOCKED_UI_CONTEXT`](mvp-f04-2018-versus-fixed-lt-201912-gui-protocol-2026-11-07.md), após seleção nativa `PERIODO_ANO=2018` produzir vazio genérico no gráfico M2-02 com mês fixo 201912. [F03-U1](mvp-f03-lt-guard-ui-temp-2026-11-07.md) já validou aviso RES em CH04/CH05 na cópia TEMP anterior. **Objetivo único:** demonstrar um aviso temporal distinto no **CH05/M2-02**, preservando a guarda de RES já aprovada e expressão de leitos original, em **nova QVW TEMP**, sem Reload/QVD/COM ou alteração da `main`.

## 1. Autoridade e design

Leituras na `main` em ordem: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`; [V2 §62](../discovery/phase-6-semantic-v2-approved-2026-10-14.md), [V3 D2-R2](../discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md). [Decisão C2-MVP B1](mvp-c2-native-acceptance-owner-approved-2026-11-07.md) foi aprovada **somente para a superfície nativa** do protótipo em PR #226. Sem promoção a C2 físico, C3/C4, P5 global ou GO IX.

**Evidência documental externa específica:** [QlikView September 2026 — Custom Error Messages](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Custom_Error_Messages.htm) permite **mensagem personalizada calculada** para `Calculation condition unfulfilled`. [GetSelectedCount](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/FieldFunctions/getselectedcount.htm) observa seleções explícitas e `True()` inclui selecionados excluídos. É **capacidade suportada pela documentação**, não prova de funcionamento deste texto/condição na QVW atual até screenshots locais.

**Objetos preservados:** CH04/M2-01 (sem alterações); CH05/M2-02 (único objeto editável); M2-03/P23 (não editar); outros seis visuais intactos. A expressão de CH05 continua **literalmente**:

```qlik
Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)
```

Não alterar título `Leitos SUS observados — município, 201912`, dimensões, medidas, Link Table, QVS, cor, posição, dataset nem construção de 9 visuais.

## 2. Cópia segura

Script versionado: `tools/New-SadMvpF04TemporalGuardCopy.ps1`. No Windows/PowerShell 5.1, requer `-Root`, `-ExpectedCommit`, `-EvidenceRoot` e `-Prepare`. Pina a branch, exige worktree limpa e origem conhecida **exclusivamente** na QVW TEMP manual com F03 guard:
`%USERPROFILE%\SAD_M1_EVIDENCIAS\SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8\SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`.

Gera novo diretório `SAD_F04_TEMPORAL_GUARD_<GUID>`, arquivo `SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw`, verifica SHA-256 fonte antes/depois e cópia igual, grava `prepare_receipt.txt`. **Não verifica propriedades COM dentro do QVW**; como pré-condição visual, confirmar que a cópia abre e CH04/CH05 ainda possuem o aviso RES de F03. Se a origem F03 estiver aberta com edição `*`, encerrar **sem gravar mudanças não aprovadas** antes de copiar; não reutilizar a QVW de M2 sem guardas.

**STOP de preflight:** parser PowerShell, HEAD, source hash ou cópia falhar ⇒ não editar gráfico e não repetir em loop. Não tocar QVWs canônicos, M1, M2-base nem 22 QVDs/3 QVWs originais.

## 3. Alteração manual no QlikView Desktop 12 — somente CH05

1. Abrir **apenas** `TARGET_QVW` gerado pelo script; `Seleções → Limpar`. Folha **Leitos Cadastrais Observados**. Com botão direito no gráfico **inferior esquerdo** `Leitos SUS observados — município, 201912` (`CH05`), abrir **Propriedades → Geral**. Não editar o gráfico grande superior (`CH04`).
2. Em **Condição de cálculo**, substituir exclusivamente a antiga condição RES por **uma condição combinada** (sem mudar a medida):

   ```qlik
   =GetSelectedCount(RES_COD_DATASUS_6,True())=0 And (GetSelectedCount(PERIODO_ANO,True())=0 Or (GetSelectedCount(PERIODO_ANO,True())=1 And Only(PERIODO_ANO)=2019)) And (GetSelectedCount(PERIODO_COMPETENCIA,True())=0 Or (GetSelectedCount(PERIODO_COMPETENCIA,True())=1 And Only(PERIODO_COMPETENCIA)=201912))
   ```

   **Intenção:** sem RES + sem ano/mês explícito → renderização normal; `PERIODO_ANO=2018` ou competência explícita diferente de 201912 → condição falsa; `RES=251370` → condição falsa; `PERIODO_ANO=2019` compatível em princípio. A fórmula cobre **seleções explícitas** RES/ano/competência, não promete tratar todas as reduções associativas implícitas por filtros SERV, nem é validação global P5.
3. Ainda nas propriedades **Geral → Mensagens de erro**, selecionar exclusivamente **`Condição de cálculo não satisfeita`**. O campo de mensagem personalizada pode ser **calculado**; inserir **uma expressão iniciada em `=`**, usando `If()` para manter exatamente o aviso original de RES e apresentar um aviso temporal no outro caso:

   ```qlik
   =If(GetSelectedCount(RES_COD_DATASUS_6,True())>0,'Indisponível nesta seleção: o filtro de residência não define a localização dos leitos. Ausência de dados associados não significa zero leitos.','Indisponível nesta seleção: este gráfico mostra somente dezembro de 2019 (201912). O período selecionado é incompatível. A ausência de dados não significa zero leitos.')
   ```

   **Prioridade de motivo:** se RES e tempo forem simultaneamente incompatíveis, a mensagem de RES tem precedência **somente neste protótipo**; isso não indica aprovação de filtros simultâneos. Evitar `Aplicar a Tudo`/`Limpar Todas`, alterar `Padrão` ou a opção `Não há dados para mostrar`. Se a mensagem aparecer literalmente como fórmula ou com erro de expressão, **STOP** e fotografar; não tentar múltiplas correções.
4. Fechar propriedades, **salvar somente a QVW F04 TEMP** em estado neutro. Não fazer `Reload`. Não salvar a QVW F03 anterior. Se algum dos outros oito objetos for alterado, STOP.

## 4. Testes GUI delimitados (sem scripts ou recarga)

| Evidência | Seleção real | Resultado esperado | Falha/STOP |
|---|---|---|---|
| `S_OK` | Caixa Seleções Atuais vazia | M2-02 volta a mostrar barras SUS por SERV/201912; CH04 linhas SUS/existentes; M2-03 três categorias | CH05 permanece indisponível ou erro de expressão |
| `S_TIME` | Apenas `PERIODO_ANO=2018` via barra M1-01 | M2-02 **não publica barras**; exibe aviso específico de `201912` incompatível com a seleção; `Seleções Atuais` confirma 2018; CH04 mantém série 2018 | Texto genérico sem motivo, fórmula literal, ou 201912 publicado como se fosse 2018 |
| `S_RES` | Limpar 2018; apenas `RES_COD_DATASUS_6=251370` pela M3-03 | M2-02 preserva **o texto original de RES**, CH04 mantém seu aviso RES, M2-03 visível; Seleções Atuais confirma 251370 | Aviso temporal aparece sob RES puro, CH04 regrediu, M2-03 desapareceu |

**Ordem proposta:** salvar/registrar `S_OK` → escolher 2018 e `S_TIME` → limpar → escolher RES 251370 e `S_RES` → limpar, sem salvar novamente. Capturas com **folha 2 inteira e janela Seleções Atuais visível**; em `S_TIME` opcionalmente uma imagem da folha 1 se valor 2018 estiver ilegível, sem criar segunda seleção. Reutilizar F03/F04 anteriores como oráculos, **não repetir a bateria integral**.

**Veredito somente após capturas reais:** `F04_U1=PASS_GUI_RESTRICTED`, `BLOCKED` ou `INCONCLUSIVE`. A documentação suporta a possibilidade de fórmula dinâmica, **não a homologa nesta QVW**. Reabertura posterior/validação de hash da QVW modificada é gate de persistência separado; não afirmar produção.

## 5. Encerramento

`F04_U1_PLAN=VERSIONED`; `F04_U1_TEMP_QVW=NOT_CREATED_BY_OPERATOR`; `F04_U1_FORMULA=NOT_PHYSICALLY_APPLIED`; `F04_U1_GUI=NOT_TESTED`; `F03_UI_GUARD=PASS_GUI_RESTRICTED_ON_F03_TEMP`; `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `C2_GUIDED_R2/C3/C4/P5_GLOBAL/IX/PRODUCTION=NOT_APPROVED`.

**STOP:** uma cópia, uma alteração CH05, três estados de GUI, sem loops, QVD, QVW canônico, COM, Reload, merge ou atualização da `main`. Se falhar, capturar erro e decidir rota alternativa separada; não usar novas intervenções para contornar o bloqueio automaticamente.


## 6. Resultado físico local — cinco capturas e veredito F04-U1

**Data:** 07/11/2026. **Fonte:** cinco capturas PNG do QlikView x64 Personal Edition fornecidas pelo operador e analisadas diretamente; hashes calculados dos bytes dos anexos da conversa. Nenhum QVW/QVD real foi aberto/analisado neste agente, nenhum script/COM/Reload executado nesta revisão. O documento carregado nos screenshots é a cópia **F04 TEMP** em `SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1/SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE` (título QlikView; extensão `.qvw` esperada pelo script, mas não inspecionada no disco Windows). Não versionar os PNGs/QVWs binários.

| Captura anexada | Dimensão | Bytes | SHA-256 | Evidência verificada |
|---|---:|---:|---|---|
| `image(20261107-175220).png` | 1907×1068 | 259478 | `6EB797012B8B8933224B8888A92552F419382882242B02E1DDE826AB6B9B0D0C` | Editor de condição de cálculo no **CH05** exibe `Expressão OK`, `GetSelectedCount(RES_COD_DATASUS_6,True())=0`, guarda `PERIODO_ANO=2019` e competência `201912`, com OR para ausência de seleção explícita |
| `image(20261107-175344).png` | 1907×1068 | 249639 | `87AAFC2AD5FFA2DF539CD20339D09359A7746AC48C4470922D9EFD8EFB184073` | Editor da mensagem dinâmica no CH05 exibe `Expressão OK`, com `If(GetSelectedCount(RES_COD_DATASUS_6,True())>0,...)`, texto anterior de residência e alternativa temporal 201912 |
| `image(20261107-175410).png` | 1907×1068 | 268002 | `62ABEA2C2A0F1D5F9CA3D44E75881BCE110D10D050557DA2A4EA39864344A9C9` | **S_OK**: `Seleções Atuais` sem itens, CH04 com duas séries, CH05 com barras, ilha P23 com três barras |
| `image(20261107-175428).png` | 1907×1068 | 234475 | `D43D70CF52B81569312353B29CB4FD3638E731DCEC3B1BDBB4B44F45D538A7EE` | **S_TIME**: `Seleções Atuais` mostra campo temporal truncado e valor `2018`, CH04 com meses `201801..201812`, CH05 exibe **aviso específico** “este gráfico mostra somente dezembro de 2019 (201912). O período selecionado é incompatível. A ausência de dados não significa zero leitos.”; sem barras publicadas em CH05 |
| `image(20261107-175515).png` | 1907×1068 | 215029 | `1D5922E961198320312C1C57EEC7C2AABAB3D8AB4B47AD0A24290A89C39C841B` | **S_RES**: `Seleções Atuais` mostra campo RES truncado, com valor `251370`; CH04 e CH05 exibem ambos o texto **original de residência**, P23 preserva três barras |

**PASS restrito comprovado pela GUI:** a nova condição CH05 revalida o contexto de filtro nativo observado em `S_TIME` e `S_RES`. No recorte de 2018 ela **não apresenta 201912 como resultado válido nem como zero**; explica especificamente a indisponibilidade temporal. No recorte RES=251370, preserva a mensagem de residência da F03-U1, sem regressão visual no CH04. Ao limpar todas as seleções, CH05 reapresenta as barras e CH04 suas séries. As três barras da P23 permanecem qualitativamente estáveis nos três estados, **sem validação numérica independente dos valores de cada barra**.

**Limites:** `Expressão OK` confirma sintaxe reconhecida pelo editor, **não** aprovação semântica completa da regra; a renderização das mensagens nos estados testados é a evidência funcional. O título QVW sem `*` nas três capturas de gráficos é compatível com ausência de mudanças pendentes, **não** prova reabertura do QVW persistido após encerrar o processo. Não foram inspecionados hash do QVW F04 pós-salvamento, propriedades COM reabertas, comportamento sob `PERIODO_ANO=2019` combinado com competências explícitas, múltiplas seleções, ou seleção SERV. O teste não substitui C2 guiado R2, C3, C4, P5 global ou Link Key físico. O título e a expressão de dezembro de 2019 devem permanecer fixos, sem alteração silenciosa da medida.

**Veredito:**
- `MVP_F04_U1=PASS_GUI_RESTRICTED`;
- `F04_U1_CH05_CONDITION_AND_DYNAMIC_MESSAGE=GUI_CONFIRMED`;
- `F04_U1_S_OK_UNFILTERED=PASS_GUI`;
- `F04_U1_S_TIME_2018=PASS_GUI_WITH_SPECIFIC_REASON`;
- `F04_U1_S_RES_251370=PASS_GUI_PRESERVES_F03_REASON`;
- `F04_U1_CH04_NO_REGRESSION=PASS_GUI_RESTRICTED`;
- `F04_U1_P23_NO_REGRESSION=PASS_GUI_VISUAL_RESTRICTED`;
- `F04_U1_QVW_REOPEN_AND_PERSISTENCE=NOT_VERIFIED`;
- `F04_U1_BUILDER_REPRODUCIBLE=NOT_IMPLEMENTED`;
- `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`;
- `C2_GUIDED_R2/C3/C4/LINK_KEY_CONTRACT/P5_GLOBAL/PHASE_IX/PRODUCTION=NOT_APPROVED`.

**STOP F04-U1 atingido:** não repetir os três cenários, não fazer novas edições automáticas, não versionar QVW/QVD, nem tocar `main`. **Próxima pendência operacional, em gate separado:** verificar reabertura/persistência do QVW F04 TEMP se for escolhido como fonte para demonstração, e definir como incorporar de modo reprodutível as guardas F03/F04 ao build sem sobrescrever a evidência. A validação de associações C3 continua atrás do gate C2 apropriado conforme Boundary 7. PR #226 permanece Draft e sem merge.
