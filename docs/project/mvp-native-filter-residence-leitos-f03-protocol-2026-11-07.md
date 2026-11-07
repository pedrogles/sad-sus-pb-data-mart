# SAD MVP — F03 | residência selecionada versus leitos e observabilidade

**Data:** 07/11/2026. **Gate:** `MVP-F03-RES-VS-LT-GUI-READONLY-01`. **Status:** `PROTOCOL_VERSIONED_NOT_EXECUTED`. **Objetivo:** inspecionar UMA seleção nativa `RES_COD_DATASUS_6=251370` no contexto dos objetos de CNES/LT (M2-01/M2-02) e observar a independência da ilha P23 (M2-03), sem inferir indicadores ausentes e sem promover C2/C3/C4/P5.

## Fonte de verdade e interpretação do teste

- Leituras na `main`, nesta ordem: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, depois [V2 §62.6](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) e [adendo V3 D2-R2](../discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md). [B1 MVP](mvp-scope-owner-approved-2026-11-07.md) está aprovado **somente na branch do PR #226**.
- **Distinção semântica obrigatória:** a matriz V2 classifica filtro `município de residência` como **B** para **LEI** (leitos SUS/1000 habitantes) e **REL** (internações/leito SUS médio). O MVP **não expõe LEI nem REL**; M2-01 é série de `Sum(QTD_LEITOS_SUS)` e `Sum(QTD_LEITOS_EXISTENTES)` por competência, e M2-02 usa `Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)` por município SERV. Portanto, a regra B **não prova isoladamente** que toda visualização descritiva M2 deve desaparecer. A questão F03 é se a oferta exibida ou sua indisponibilidade é inteligível sob seleção RES e **não se apresenta capacidade real zero com base em exclusão associativa**.
- **Ilha M2-03:** campo `P23_ESTADO_OBSERVADO` com `Count(P23_MUNICIPIO_6)`, produzida por uma ilha de observabilidade física que não compartilha campos globais; total histórico de 8.028 células = 4.467 sem linha LT + 97 zero com linha + 3.464 SUS positivo. Uma seleção global de RES **não deveria alterar os três grupos da ilha**, segundo o modelo candidato. Verificação GUI deste cenário é canário, não homologação A1 completa.
- **F02 encerrado:** seleção `RES=251370` apresentou 24.616 novas internações FI, par `251370→250750=12176`, POP ano por município; **não repetir a validação numérica FI**. Se a seleção F02 já foi limpa, reaplicá-la apenas como pré-condição do F03.

## Artefato e fronteiras operacionais

Usar **somente a cópia de inspeção** já existente no QlikView Desktop 12:
`%USERPROFILE%\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_0f6b3b19ce714295ba80e5c27856c08e\SAD_MVP_THREE_SHEETS_CANDIDATE_INSPECAO.qvw`.

**Proibições:** não abrir para gravação a QVW candidata, original M1 ou QVWs canônicos; não `Reload`, `Save`, `Save As`, alterar propriedades, criar gráficos/listas, editar script ou fazer seleções por clique nos objetos LT. Não rodar automações/COM nem gerar QVDs/arquivos. Não alterar `main`, não realizar merge. A captura é a evidência suficiente de um cenário F03.

## Execução GUI — única sessão

1. Com `Seleções Atuais` visível, conferir o estado. Se já houver **somente** `RES_COD_DATASUS_6=251370`, mantê-lo (não repetir a seleção). Caso contrário, `Seleções → Limpar` e, na folha **Fluxos e Contexto Territorial**, selecionar **apenas** a célula `251370` da coluna RES em M3-03. Confirmar na caixa `Seleções Atuais` que RES é o **único** campo selecionado. Se aparecer outro campo ou seleção bloqueada, **STOP `F03_INCONCLUSIVE_PRESTATE`**; não compensar com filtros adicionais.
2. Sem clicar em gráficos (somente navegar pelas abas), abrir a folha **Leitos Cadastrais Observados**. Manter `Seleções Atuais` aberta e visível, preferencialmente posicionada em área sem cobrir M2-01/M2-02/M2-03.
3. Capturar **uma screenshot da folha 2 inteira**, com os três objetos e o estado `RES=251370` legíveis. Se um objeto aparecer vazio/sem dados, preservar a imagem exatamente assim, sem selecionar período/SERV ou forçar recálculo.
4. Limpar a seleção depois da captura, sem salvar o arquivo. Enviar a imagem ao agente. **Não executar outro cenário de filtro nesta sessão**.

## Critérios de revisão e STOP

| Controle | Observação esperada / PASS limitado | BLOCKED / INCONCLUSIVE |
|---|---|---|
| Estado selecionado | `RES_COD_DATASUS_6=251370` e nenhuma seleção em SERV/ano/competência | Seleção ambígua/incompleta → `INCONCLUSIVE_PRESTATE` |
| M2-01, M2-02 | Interpretáveis como snapshots/descritivos de leitos por COMPETÊNCIA/SERV, com contexto correto, **ou** indisponibilidade identificada explicitamente; nenhuma ausência associativa apresentada como “zero real” | Mostra zero como capacidade real sem prova, apresenta oferta de um município de residência como se fosse oferta localizada por serviço, ou mostra resultados sem contexto/aviso relevante → `BLOCKED_FOR_USER_USE`; objetos vazios sem contexto → `INCONCLUSIVE_OR_UI_GUARD_GAP` conforme captura |
| M2-03 P23 | As três categorias preservam universo de observabilidade da ilha; não devem filtrar segundo RES (sem exigir números legíveis na captura) | Ilha reage à seleção RES (barras/categorias mudam) → `BLOCKED_ISLAND_INDEPENDENCE`; categorias truncadas sem contagens → `INCONCLUSIVE_NUMERIC` |
| LEI/REL | **Não presentes** no conjunto de nove objetos; não inferir PASS de compatibilidade `B` nem taxa de oferta por habitante | Declaração de taxa/indicador LEI/REL onde só há contagens → `BLOCKED_SEMANTIC` |
| Integridade | Apenas navegação e captura em cópia TEMP | `Reload`, `Save`, mudança QVD/QVW, alteração do modelo ou segundo cenário → `STOP` |

**Veredito futuro:** `MVP_F03=PASS_RESTRICTED_PRESENTATION`, `BLOCKED_FOR_USER_USE` ou `INCONCLUSIVE`. **Não transformar** a apresentação em `P5_UI_APPROVED`, `C2_GUIDED_R2`, `LINK_KEY_CONTRACT`, `C3/C4`, `PHASE_IX` ou `PRODUCTION_APPROVED`.

**STOP absoluto:** uma captura e um único cenário. Se houver falha, analisar a imagem e decidir correção separada, **sem nova recarga ou tentativa em série**. Próxima etapa após evidência: registrar conclusão F03; eventual teste de SERV ou outra ilha requer escopo próprio.


## 5. Resultado F03 — evidência GUI do filtro RES sob CNES/LT e ilha P23

**Evidência:** screenshot real `image(20261107-165601).png` fornecida nesta conversa pelo operador, QlikView x64 Personal Edition, documento `SAD_M2_MVP_TEMP_0f6b3b19ce714295ba80e5c27856c08e/SAD_MVP_THREE_SHEETS_CANDIDATE_INSPECAO.qvw`. O agente inspecionou visualmente o anexo; SHA-256 **calculado dos bytes montados** `A535066479DD531CA3A033E0FEEBA95E6D521140F25F84123D90933563FB6DC5`, PNG RGBA de **1907×1068 px**, **205.544 bytes**. Não versionar o binário no Git. Não foi inspecionado o arquivo QVW original, o estado após Clear ou eventuais alterações não salvas; nenhuma recarga/COM foi executada pelo agente.

| Critério | Resultado diretamente visível | Qualificação |
|---|---|---|
| Seleção real | Janela `Seleções Atuais` exibe campo RES truncado (`RES_COD_DATAS...`), com valor **251370** e marcador verde; nenhuma outra seleção aparece | `PASS_GUI_STATE_RESTRICTED` |
| M2-01 | Área do gráfico de snapshots de leitos por competência mostra literalmente **“Não há dados para mostrar”**; nenhum ponto/linha de LT | `NO_ASSOCIATED_DISPLAYED_ROWS` — **não** representa leitos quantitativamente iguais a zero |
| M2-02 | Gráfico municipal SUS fixo `201912` também mostra **“Não há dados para mostrar”** | `NO_ASSOCIATED_DISPLAYED_ROWS` — não prova inexistência de leitos em 251370 |
| Aviso de indisponibilidade | Nem M2-01 nem M2-02 explicam a incompatibilidade entre RES e localização/serviço CNES; apenas mensagem nativa genérica, sem nota de escopo | `UI_CONTEXT_EXPLANATION_MISSING`; **BLOCKED_FOR_USER_USE** sob seleção RES |
| M2-03 | Três barras de observabilidade visíveis, com alturas qualitativamente compatíveis com as capturas base (ausentes > positivos >> zeros observados), apesar do filtro RES | `P23_ISLAND_GUI_INDEPENDENCE=PASS_VISUAL_RESTRICTED`; valores exatos/ausência de influência em outros filtros não comprovados |
| LEI/REL | Nenhuma taxa leitos/habitante nem internações/leito apresentada nesta folha | `NOT_APPLICABLE_TO_NINE_VISUALS`, não promover aceite P5 para razões ausentes |

**Interpretação fundamentada:** a exclusão de LT sob seleção RES coincide com o modelo candidato que distingue papéis territoriais: a fato CNES/LT possui município de **serviço/localização**, e não residência dos pacientes. O resultado visual atual confirma **ausência de dados exibíveis sob a seleção**, mas não prova diretamente a causa técnica em cada associação da Link Table. Não transformar ausência em zero, nem afirmar que `251370` não tem leitos. As duas séries descritivas **não** são os indicadores LEI/REL da matriz P5 V2 (§62.6), embora compartilhem o risco de interpretação sob contexto RES.

**Veredito por superfície:**
- `MVP_F03_LT_ASSOCIATIVE_DISPLAY=NO_DATA_UNDER_RES`;
- `MVP_F03_LT_UI_GUARD=BLOCKED_FOR_USER_USE` **por mensagem insuficiente** — a mensagem “Não há dados para mostrar” não constitui explicação de filtro incompatível nem guia para interpretar ausência associativa;
- `MVP_F03_P23_ISLAND=PASS_VISUAL_RESTRICTED` apenas para permanência de três categorias e alturas compatíveis;
- `MVP_F03_OVERALL=BLOCKED_FOR_USER_USE_PENDING_UI_CONTEXT`; `C2/C3/C4/P5_UI=NOT_APPROVED`.

### STOP e decisão de correção

F03 **encerrado** com bloqueio localizado. Não executar novos testes em cascata, nem recarregar/reconstruir QVW/QVD. Próxima ação correta é **separar o design de comunicação e supressão por indicador** da aprovação do modelo: propor na próxima decisão do responsável (não implementado aqui) estado explícito **“Indisponível nesta seleção: município de residência não corresponde ao papel territorial dos leitos (serviço/localização)”**, preservando o valor descritivo quando seleção for compatível, e **não** transformar vazio em zero. No QlikView, isso requer mecanismo real de contexto/condição por objeto, com prova GUI específica de estado válido e incompatível e sem prometer guarda global de menus. Verificar também que P23 continua ilhada, com rótulos legíveis, em gate separado se necessário.

**Limites:** o PR #226 é Draft; `main`, 22 QVDs, 3 QVWs canônicos, contrato de Link, 3 fatos/8 dimensões, regras P5 e Fase IX permanecem sem alteração. `MVP_USER_READY=False`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
