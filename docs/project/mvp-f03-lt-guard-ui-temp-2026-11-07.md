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
