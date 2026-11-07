# SAD MVP — F03-U1: aviso contextual de LT sob seleção de município RES

**Data de preparação:** 07/11/2026. **Gatilho:** `F03=BLOCKED_FOR_USER_USE` com M2-01 e M2-02 exibindo “Não há dados para mostrar” sob `RES_COD_DATASUS_6=251370`, apesar de M2-03 permanecer visualmente ilhado. **Objetivo único:** substituir o estado genérico de M2-01 e M2-02, nesse filtro, por **mensagem explícita de indisponibilidade**, sem mudar as nove expressões, QVS de modelo, QVDs ou QVWs canônicos.

## 1. Fonte de verdade, decisão e fronteira

- Leitura de base na `main`: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, V2 §62.6 e V3 D2-R2; no PR #226: [M0 B1 aprovado](mvp-scope-owner-approved-2026-11-07.md), [F03 bloqueado](mvp-native-filter-residence-leitos-f03-protocol-2026-11-07.md).
- Objetos afetados e **somente** eles: M2-01 (linhas SUS/existentes por competência), M2-02 (barras SUS por SERV, com 201912). M2-03/P23 é independente e **não deve ser alterado**.
- **Diferença semântica:** matriz P5 V2 classifica RES como B para **LEI/REL** (razões), que não estão expostas. O aviso aqui protege a interpretação de **quantidades descritivas** CNES/LT sob seleção RES, não aprova/implementa LEI/REL nem um bloqueio global de UI.
- **Rota de menor risco:** usar propriedades **nativas** do QlikView 12: **Chart Properties → General → Calculation Condition** e **Error Messages → Calculation condition unfulfilled → Custom Message**. A [ajuda oficial](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/ChartProperties.htm) descreve a condição e a [personalização da mensagem](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Custom_Error_Messages.htm). Evitar automatizar o caminho COM não demonstrado; não herdar homologação dos testes COM de No Totals.
- QlikView 12 [GetSelectedCount](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/FieldFunctions/getselectedcount.htm): conta valores explicitamente selecionados. O argumento `True()` inclui selecionados excluídos por outros filtros; **não confundir ausência de seleção com disponibilidade de dados**.

## 2. Preparação de cópia controlada — script versionado, sem COM

Script: `tools/New-SadMvpF03UiGuardCopy.ps1`, obrigatório `-Prepare`, `-ExpectedCommit` e raiz externa de evidências. Exige branch correta e worktree limpa; confirma manifesto de 9 objetos e expressões inalteradas de M2-01/M2-02; copia **somente** o QVW candidato bem-sucedido `SAD_M2_MVP_TEMP_0f6b3b19ce714295ba80e5c27856c08e/SAD_MVP_THREE_SHEETS_CANDIDATE.qvw` para pasta externa nova `SAD_F03_UI_GUARD_TEMP_<GUID>/SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`; verifica SHA-256 idêntico fonte/cópia e da fonte antes/depois. Emite `TARGET_QVW` e comprovante. Não acessa QVDs, nem usa Qlik/COM/Reload/Save.

**STOP:** falha de branch/HEAD, manifesto, hash ou path → não editar nem reexecutar até investigar. Essa preparação é `COPY_PREPARED`, **não** `UI_GUARD_PASS`. Os 25 canônicos e a QVW M1 não são tocados pelo script. Reproduzir apenas em cópia; nunca salvar a QVW de inspeção de F01/F02/F03 nem a original bem-sucedida.

## 3. Configuração manual no QlikView 12, somente QVW TEMP da seção 2

1. Abrir **somente** `TARGET_QVW` produzido pelo script, sem `Reload`; na abertura limpar seleções nativas para estado neutro. Confirmar visualmente 3 abas e a folha 2 com os três gráficos.
2. No gráfico **M2-01 — Leitos cadastrados por competência**, abrir **Propriedades** (menu de contexto ou `Objeto → Propriedades`). Na aba **Geral**, no campo **Condição de cálculo / Calculation Condition**, inserir literalmente:

   ```qlik
   =GetSelectedCount(RES_COD_DATASUS_6, True())=0
   ```

   Na mesma aba, clicar **Mensagens de erro / Error Messages**; escolher **Condição de cálculo não atendida / Calculation condition unfulfilled** (não `Default` ou `No data to display`) e informar **exatamente**:
   ```text
   Indisponível nesta seleção: o filtro de residência não define a localização dos leitos. Ausência de dados associados não significa zero leitos.
   ```
   Aplicar/OK, sem alterar dimensões, expressões, tipo de gráfico, posição ou título.
3. Repetir **exatamente** a condição e a mensagem no gráfico **M2-02 — Leitos SUS observados — município, 201912**. **Não** aplicar a todos os objetos e **não** editar M2-03. Salvar **somente** `TARGET_QVW`; este é artefato TEMP que pode receber o salvamento explícito, não a QVW canônica.
4. Cenário incompatível: na folha 3, selecionar **apenas** `RES_COD_DATASUS_6=251370` pela primeira coluna da tabela POP; observar `Seleções Atuais`; abrir folha 2. **PASS** exige M2-01 e M2-02 mostrando o aviso específico e **nenhum número de leitos como se fosse válido**. M2-03 deve continuar com três categorias sem se comportar como filtro global. Captura `S_BAD` da folha 2 com Seleções Atuais.
5. Cenário compatível: `Seleções → Limpar`, sem adicionar SERV/tempo. Na folha 2, M2-01 deverá voltar a mostrar as duas séries para 36 competências; M2-02 deve voltar ao ranking fixo 201912, com o dado total SUS **7.140** (do runner anterior, não necessariamente rótulo numérico visível). M2-03 deve permanecer legível. Captura `S_OK`; um gráfico vazio ou aviso que persiste indica bloqueio.
6. Enviar capturas `S_BAD` e `S_OK`, e o receipt `prepare_receipt.txt` ou stdout do script. **Não repetir combinações de filtros**, não criar novos objetos, não salvar o original e não fazer Reload. Encerrar a sessão após evidências; se houver erro de GUI, STOP sem contornar por COM ou nova carga.

## 4. Critérios estritos de aceite

| Condição | Evidência requerida | Estado se divergente |
|---|---|---|
| Cópia TEMP segura | `SOURCE_QVW_UNCHANGED=True`, hashes iguais e manifesto 9 visuais | `BLOCKED_PREPARE` |
| Guardas condicionais M2-01 e M2-02 | `RES=251370` efetivo, **mensagem contextual exata** no lugar de números/vazio genérico | `BLOCKED_UI_CONTEXT` |
| Reversibilidade | `RES` limpo, ambos voltam a apresentar séries/ranking normalmente | `BLOCKED_GUARD_STUCK` |
| Ilha A1 | M2-03 continua ilhada/qualitativamente não alterada | `INCONCLUSIVE_OR_BLOCKED_ISLAND` |
| Não regressão | Nove visuais permanecem, nenhum QVS/expressão/medida substituído; sem QVD/QVW canônico alterado | `BLOCKED_REGRESSION` |

**Veredito futuro possível:** `MVP_F03_UI_GUARD=PASS_GUI_RESTRICTED`, `BLOCKED` ou `INCONCLUSIVE`, somente após duas capturas reais. **Nesta preparação:** `COPY_RUNNER=STATIC_VERSIONED_NOT_EXECUTED`, `TEMP_QVW=NOT_CREATED_BY_OPERATOR`, `UI_GUARD=NOT_CONFIGURED`, `GUI_ACCEPTANCE=NOT_TESTED`. A decisão de incluir guardas em outro filtro, automação COM das propriedades, B2 ou indicador cross-fact está fora deste gate.

**STOP e autoridades:** sem merge, sem alteração de `main`, sem autorização da Fase IX; `C2_GUIDED_R2/P5_D2_UI/LINK_KEY_CONTRACT/MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PRODUCTION_APPROVED=False`.


## 5. Evidência GUI recebida — configuração CH04/CH05 e aviso exibido

**Data:** 07/11/2026. **Origem:** cinco imagens reais da janela QlikView x64 Personal Edition, fornecidas pelo operador nesta conversa e inspecionadas visualmente. Todas mostram o **novo QVW TEMP isolado** `SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8/SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`. O título possui **asterisco `*`** nas capturas, indicando alterações ainda **não comprovadas como salvas** na versão fotografada. Não confundir com o QVW `_INSPECAO` anterior ou canônicos.

| Anexo da conversa | Resolução | SHA-256 dos bytes PNG | Conteúdo comprovado |
|---|---|---|---|
| `image(20261107-171735).png` | 1904×1068 | `EA3A7A7337F218F09B3CD64DB5C7FBA7A1007B7F062D6EB8968D3DBFA2745A75` | Propriedades CH04 / M2-01: `=GetSelectedCount(RES_COD_DATASUS_6, True())=0` |
| `image(20261107-171745).png` | 1907×1068 | `A6BE2693531C3E9373D66164E02ED564EBDF0572DE3F0A59F188E14E2C1713BC` | Mensagens de erro CH04: `Condição de cálculo não satisfeita` com texto contextual personalizado |
| `image(20261107-171802).png` | 1906×1068 | `24953D5B07465AB059DDC1E7C4B7C5409BCDD50A3AF2949C649712366CFB69FB` | Propriedades CH05 / M2-02: mesma condição de cálculo |
| `image(20261107-171815).png` | 1907×1068 | `E295C74901A42D95951D8FCD7F14CC88F20092D77356396BDD431EB9834A84E2` | Mensagens CH05: mesma mensagem configurada na categoria específica |
| `image(20261107-171825).png` | 1907×1068 | `25D1834AABFF7329BAF5883802ACDFDFDC18E756DE8B83CFB4196D7EA9959C4B` | Com a janela de propriedades fechada, **M2-01 e M2-02 exibem o aviso textual**; M2-03 ainda mostra suas três barras observacionais |

**Texto exibido nas duas superfícies:** “Indisponível nesta seleção: o filtro de residência não define a localização dos leitos. Ausência de dados associados não significa zero leitos.”

**Classificação precisa:**
- `F03_CH04_CH05_CALC_CONDITION=CONFIGURED_GUI_CONFIRMED`.
- `F03_CH04_CH05_CUSTOM_MESSAGE=CONFIGURED_AND_RENDERED_GUI_CONFIRMED`.
- `F03_P23_ISLAND=THREE_BARS_RENDERED_VISUAL_RESTRICTED`.
- `F03_S_BAD_RES_251370_EXACT=INCONCLUSIVE`: **não há janela `Seleções Atuais` na última captura**; a renderização do aviso indica condição não atendida, mas não certifica qual valor de RES estava selecionado. Não inventar seleção 251370 a partir de mensagem.
- `F03_S_OK_CLEARED=NOT_RECEIVED`: falta captura **sem** seleção RES com os gráficos novamente exibindo dados, necessária para afirmar reversibilidade.
- `F03_TEMP_QVW_PERSISTENCE=NOT_EVIDENCED`: asterisco no título não demonstra que a configuração foi salva.
- `MVP_F03_UI_GUARD=PARTIAL_GUI_PASS_PENDING_STATE_AND_REVERSIBILITY`; `P5_UI/C2/C3/C4/IX/PRODUCTION=NOT_APPROVED`.

**Próximo ato mínimo, sem script/COM/reload:** fechar as janelas de propriedades; limpar as seleções, conferir retorno M2-01/M2-02 e salvar **apenas** `SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw` na pasta `SAD_F03_UI_GUARD_TEMP_<GUID>` após confirmar estado neutro. Capturar `S_OK` com janela `Seleções Atuais` legível. Selecionar exclusivamente `RES_COD_DATASUS_6=251370` pela tabela POP, navegar à folha 2, capturar `S_BAD` com o valor visível na caixa `Seleções Atuais`, confirmar os dois avisos e P23; limpar a seleção novamente, sem mais gravações/edições. Parar no primeiro erro de UI. Se o operador já possui `S_OK`/`S_BAD` com estado legível, reutilizar e não repetir.

**STOP:** não mexer em `main`, QVDs, QVW base de nove objetos, QVW M1 ou canônicos; não concluir que função validou toda P5, não declarar `C2_GUIDED_R2` aprovado.


## 6. Capturas S_OK — reversibilidade após limpar RES

**Data:** 07/11/2026. Duas capturas reais da folha `Leitos Cadastrais Observados` da QVW TEMP `SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8/SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`, recebidas nesta conversa e inspecionadas visualmente. **Não** inclui nova execução de script/COM ou alteração da QVW canônica.

| Captura | Dimensão | Bytes | SHA-256 do PNG recebido | Observação |
|---|---|---:|---|---|
| `image(20261107-172143).png` | 1907 × 1068 | 261636 | `EE93F73D54DB8AE26B4A2E3EC4B6E6798EE27B9AA76AE78525D7CF6087C55927` | M2-01 e M2-02 com séries/barras novamente desenhadas; título QVW ainda com `*` (pendências de salvamento) |
| `image(20261107-172212).png` | 1907 × 1068 | 268023 | `34BDF7E45816A9A8AFF65FDE586269BE4C3CA2E8FC9D4C4AA36236F48E72870C` | **Seleções Atuais vazia**, M2-01 e M2-02 renderizados, M2-03 com três barras; título QVW **sem `*`** |

**Verificação visual direta:** a guarda `GetSelectedCount(RES_COD_DATASUS_6, True())=0` não ficou presa em estado indisponível. Ao retirar o filtro, **M2-01 apresenta duas séries de snapshots** e **M2-02 apresenta barras de leitos SUS por município/competência fixa**. A ilha P23 (M2-03) permanece visível com suas três categorias. A segunda screenshot mostra a janela `Seleções Atuais` sem linhas, condição suficiente para demonstrar estado inicial neutro na GUI.

**Persistência:** o QVW com `*` na primeira captura e **sem** `*` na segunda sugere que a versão em memória deixou de ter alterações pendentes, compatível com `Save` realizado pelo operador. Todavia **não foi feito re-open do QVW salvo nem verificação de hash posterior**; portanto `F03_TEMP_SAVE_VISUAL=NO_UNSAVED_MARKER`, **não** `F03_TEMP_QVW_REOPEN_PERSISTENCE=PASS`.

**Vereditos parciais atualizados:**
- `F03_S_OK_CLEARED=PASS_GUI_NO_SELECTION`
- `F03_CH04_CH05_RECOVERY=PASS_GUI_RESTRICTED`
- `F03_P23_3_CATEGORIES=PASS_GUI_VISUAL_RESTRICTED`
- `F03_TEMP_QVW_NO_UNSAVED_MARKER=CONFIRMED_GUI`
- `F03_S_BAD_RES_251370_EXACT=PENDING`, pois as cinco primeiras capturas da sessão anterior demonstraram o aviso, mas **não** a seleção explicitamente exibida na mesma imagem.
- `MVP_F03_UI_GUARD=PARTIAL_GUI_PASS_PENDING_S_BAD_WITH_SELECTION_STATE`. C2/C3/C4/P5/IX e produção permanecem não aprovados.

**Única ação restante no gate:** sem alterar objetos ou salvar novo QVW, selecionar **somente `RES_COD_DATASUS_6=251370`** na folha 3, voltar à folha 2 e capturar **uma única screenshot** `S_BAD` com **Seleções Atuais visível, o valor 251370, dois avisos e três barras P23**. Depois limpar a seleção e STOP. Não repetir S_OK, não recarregar e não rodar scripts.


## 7. S_BAD com seleção real comprovada — encerramento do F03-U1

**Data:** 07/11/2026. Última captura real `image(20261107-172512).png` fornecida pelo responsável nesta conversa e inspecionada diretamente. **1907×1068 px**, **215871 bytes**; SHA-256 dos bytes PNG montados `1BE20A8E027B915EEB2BE4AFB7030B4D203EBA71AEC861D340ED3427E5094D6C`. Janela QlikView x64 Personal Edition exibe exclusivamente a QVW TEMP de correção `SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8/SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`, não a QVW de inspeção anterior nem a canônica; screenshot **não prova** reabertura de arquivo persistido.

**Evidência GUI S_BAD:**
- Caixa **Seleções Atuais** exibe uma única linha com campo municipal RES visualmente truncado (`RES_COD_DATAS...`, coerente com `RES_COD_DATASUS_6` documentado nas capturas anteriores), marcador verde e **valor 251370**; nenhum ano ou SERV explicitamente selecionado na lista.
- **M2-01/CH04** apresenta texto completo de indisponibilidade: “Indisponível nesta seleção: o filtro de residência não define a localização dos leitos. Ausência de dados associados não significa zero leitos.” **Sem publicar números de capacidade nem confundir ausência com zero**.
- **M2-02/CH05** apresenta **o mesmo texto** no lugar de barras/valores sob RES selecionado.
- **M2-03/P23** mantém três barras observacionais qualitativamente compatíveis com as capturas anteriores; não apresenta as mesmas mensagens dos dois objetos LT, mas seus rótulos continuam truncados. **Não** é comprovação quantitativa de 4.467/97/3.464 na tela.
- Título da QVW TEMP **sem `*`**. Isso somente demonstra ausência de alteração pendente no estado visual daquela captura; **não** equivale a inspeção independente do QVW salvo/reaberto ou auditoria de SHA do arquivo Windows.

**Evidência GUI S_OK reutilizada (sem repetir testes):** `image(20261107-172212).png` na seção 6 mostra Seleções Atuais **vazia**, M2-01 com as duas séries LT e M2-02 com barras SUS por SERV/201912 novamente exibidas; M2-03 preservada. É prova de reversibilidade visual do aviso na mesma sessão/cópia de trabalho.

**Conclusão restrita do gate:**
- `MVP_F03_UI_GUARD=PASS_GUI_RESTRICTED`.
- `F03_S_BAD_RES_251370_EXACT=PASS_SCREENSHOT`.
- `F03_S_OK_CLEARED=PASS_SCREENSHOT`.
- `F03_CH04_CH05_CUSTOM_CONDITION_AND_MESSAGE=PASS_GUI_RESTRICTED`.
- `F03_P23_ISLAND=PASS_VISUAL_RESTRICTED_THREE_CATEGORIES`.
- `F03_TEMP_QVW_PERSISTENCE=NO_ASTERISK_VISIBLE_REOPEN_NOT_VERIFIED`.
- `MVP_F03_USER_USE_FOR_THIS_SELECTION=NO_FALSE_ZERO_MESSAGE`; não declarar que toda seleção P5 recebeu guarda.
- `C2_GUIDED_R2/C3/C4/P5_D2_UI/LINK_KEY_CONTRACT/PHASE_IX/PRODUCTION_APPROVED=NOT_APPROVED`.

**STOP F03-U1 atingido:** não solicitar novas capturas/repetições deste cenário, nem reconstruir/alterar os QVDs, QVWs canônicos, `main` ou o QVW candidato base de nove visuais. A configuração manual **reside apenas na cópia TEMP externa**, não está incorporada ao construtor versionado e **não foi provada após reabrir o QVW salvo**; documentar esse fato como limite de entrega/automação, não como erro de GUI. Qualquer nova frente (reabertura persistida, layout/legibilidade, filtros SERV ou contratos C2–C4) exige objetivo e gate próprios; PR #226 permanece Draft sem merge.
