# SAD MVP — F04: seleção nativa 2018 × gráfico LT fixo em 201912

**Data:** 07/11/2026. **Gate:** `SAD-MVP-F04-TEMPORAL-CONFLICT-LT-FIXED-201912-GUI-01`. **Status:** `PREPARED_NOT_EXECUTED`. **Autorização:** decisão `OWNER_C2_MVP_ACCEPTANCE_SCOPE=APPROVED_BRANCH_ONLY` em [adendo C2-MVP](mvp-c2-native-acceptance-owner-approved-2026-11-07.md), com continuidade do operador para um teste físico GUI **único e controlado**. A execução/aceite físico ainda dependem das imagens. Não é teste global C2 guiado, C3, C4, P5 ou fase IX.

## 1. Objetivo e oráculos independentes

**Pergunta única:** após selecionar nativamente `PERIODO_ANO=2018`, o objeto **M2-02 — “Leitos SUS observados — município, 201912”** (Set Analysis fixo `Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)`) apresenta leitos de **dezembro/2019** como se fossem resultado do filtro 2018, fica indisponível com **motivo explícito**, ou se comporta de maneira ainda não explicada?

**Oráculo de apoio, não o teste principal:** SIH/RD 2018 = **183.311 novas internações** em M1-01, conforme M1 já reconciliado, não comprovável somente pela altura de barra sem label. **Não inventar valor LT 2018**; total SUS `201912=7140` só é referência do snapshot dezembro/2019 sem conflito, não resultado aceitável automaticamente sob `PERIODO_ANO=2018`. O objeto **M2-01** (séries por competência) pode ser observado para contexto, mas não amplia o gate. A ilha M2-03 P23 continua observação separada.

## 2. Artefato e controles de segurança

Usar **somente a QVW TEMP externa com a guarda F03-U1 já salva**:
`%USERPROFILE%\SAD_M1_EVIDENCIAS\SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8\SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`.

A seleção deve ocorrer em QlikView Desktop 12 **sem Reload, Save, Save As, COM, edição do script, alteração das condições de cálculo, criação de objetos ou mudança dos QVDs**. Nenhum QVW canônico nem o M2 base será aberto para gravação. Os dados e nove expressões continuam os mesmos; a configuração manual de F03 só bloqueia explicitamente **seleções RES** para M2-01/M2-02 — a guarda temporal **não foi implementada**.

**Pré-condição:** nenhuma seleção prévia. `Seleções → Limpar`, abrir `Seleções Atuais` e verificar caixa vazia. Se filtro travado, uma QVW diferente, arquivo não existente, aviso já presente mesmo sem seleções ou qualquer estado incerto, STOP `INCONCLUSIVE_PRESTATE`.

## 3. Execução guiada pelo operador — somente um cenário

1. Na folha **Produção Hospitalar**, com a janela `Seleções Atuais` visível, **clique uma única vez na barra `2018`** do gráfico anual **M1-01**. Não selecione outra barra, município ou competência. Conferir que o único campo explicitamente selecionado é `PERIODO_ANO`, com valor `2018`. Se a seleção for diferente, STOP sem tentar outra rota.
2. Capturar **S1** da primeira folha com `Seleções Atuais` mostrando `2018` e a barra anual correspondente. Um valor exato 183311 que esteja visível pode ser registrado, mas **não** se deve inferir o exato por pixels.
3. Sem limpar nem alterar a seleção, navegar à folha **Leitos Cadastrais Observados**. Capturar **S2** mostrando **M2-02 inteiro**, seu título `201912`, as barras ou mensagem que aparecerem, e a janela `Seleções Atuais=2018`. Se possível, preservar no mesmo frame M2-01 e M2-03, sem clicar neles.
4. **Não tentar corrigir** o comportamento observado, trocar a expressão, selecionar 201912, editar propriedades, nem testar 2017/2019 em sequência.
5. Após as duas capturas, usar **Seleções → Limpar**. **Não salvar**. Enviar as duas imagens. Se o resultado for surpreendente ou vazio, preservar essa observação: é o objetivo do teste.

## 4. Matriz PASS / BLOCKED / INCONCLUSIVE

| Situação observável no M2-02 com `PERIODO_ANO=2018` | Resultado do gate |
|---|---|
| Mostra **indisponibilidade explícita e explicada** (ex.: “este gráfico é exclusivamente 201912; a seleção 2018 é incompatível”) e não publica valor como 2018 | `F04=PASS_GUI_RESTRICTED` para o cenário, ainda sem C2/P5 global |
| Publica barras/valores de `201912` na presença do filtro `2018` sem tratamento contextual aprovado; mesmo título fixo não justifica ignorar silenciosamente a seleção | `F04=BLOCKED_TEMPORAL_MISLEADING` |
| Exibe simplesmente `Não há dados para mostrar` sem razão que diferencie incompatibilidade/ausência de LT | `F04=BLOCKED_UI_CONTEXT` para uso; o dado não é zero |
| Estado aplicado não está legível, objeto não aparece, captura não permite decidir, ou QlikView erro crítico | `F04=INCONCLUSIVE` ou `BLOCKED_CRITICAL`, sem declarar PASS |
| Mantém indicador independente **com aviso inequívoco, justificativa explícita, escopo próprio previamente aprovado e sem rotular como 2018** | No contrato B1 atual, **INCONCLUSIVE_PENDING_CONTRACT**; exige decisão própria, não PASS automático |

**Fora do escopo:** razões LEI/REL/T24–T26, filtro SERV inverso, recortes multi-ano/mês não consecutivo, guarda guiada pré-despacho, performance do Qlik, consistência global P23 e implementação definitiva. O F04 **não** pretende aprovar cross-fact nem inferir cobertura CNES hospitalar a partir de uma célula.

## 5. STOP/handoff

Após S1 e S2, encerrar F04. Se `BLOCKED`, a correção posterior deverá ficar em **uma nova cópia TEMP** e em escopo exclusivo de aviso temporal do M2-02, preservando expressão, título/201912, guardas RES e todos os nove objetos até decisão semântica. Não tentar uma série de recargas ou mudanças COM “até passar”. Se `PASS_RESTRICTED`, avançar na matriz C2-MVP somente por gate próprio, nunca para C3/C4/IX automaticamente.

**Estado atual:** `F04_PROTOCOL=VERSIONED`; `F04_PHYSICAL=NOT_EXECUTED`; `OWNER_C2_MVP_ACCEPTANCE_SCOPE=APPROVED_BRANCH_ONLY`; `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`; `C2_GUIDED_R2=NOT_TESTED`; `PRODUCTION_APPROVED=False`. Documento **não** altera `main`, F03-U1 TEMP, builder, QVD/QVW canônicos ou contratos acadêmicos.


## 6. Resultado físico F04 — capturas reais do QlikView 12

**Data e origem:** 07/11/2026; duas capturas PNG reais do QlikView x64 Personal Edition fornecidas pelo responsável nesta conversa, inspecionadas visualmente pelo agente. Janela da **cópia TEMP com guarda F03-U1** `SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8/SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`; título contém `*`, **não** prova gravação nem alteração efetiva do binário. Não houve análise dos bytes QVW, execução de COM/Reload, nem conferência de propriedade nativa além do que as capturas apresentam.

| Captura | Arquivo PNG no chat | Dimensão real | SHA-256 dos bytes recebidos |
|---|---|---|---|
| **S1 — Produção Hospitalar** | `image(20261107-173948).png` | 1902×1068 | `8AFEBE98060C89B37CB1431ECF10FB46DC8947C30DC8368A776AD12064A58F2E` |
| **S2 — Leitos Cadastrais Observados** | `image(20261107-174020).png` | 1907×1028 | `67F0F626DAE5714109F4EF40B84A4614461161F651F98C1EB374C438DC09C77B` |

### Matriz de evidências do único cenário F04

| Critério | Evidência observada diretamente na imagem | Veredito estrito |
|---|---|---|
| Seleção nativa | Janela `Seleções Atuais` em S1 e S2 exibe somente `PERIODO_ANO=2018` (rótulo do campo truncado, valor 2018 e marcador verde) | `PASS_GUI_EFFECTIVE_SELECTION_2018` |
| M1-01 | Gráfico anual mostra barra única 2018. **Não imprime a soma 183311**; oráculo vem de validações FI anteriores, não da altura de pixels | `PASS_GUI_2018_SCOPE; EXACT_VALUE_NOT_VISIBLE` |
| M1-02 | Eixo X completo legível em S1 contém **`201801` até `201812` (12 competências)** e nenhuma competência de 2017/2019 visível como ativa | `PASS_GUI_2018_MONTH_LABELS`; não substitui prova das 12 competências de **2019** ainda não visíveis no F01 |
| M2-01 | Em S2, duas linhas (SUS/existentes) e eixo X restrito a **`201801..201812`**; nenhuma soma anual de snapshots exibida | `PASS_GUI_2018_SNAPSHOT_SERIES_RESTRICTED`; sem oráculo numérico mensal independente nesta captura |
| **M2-02** | Título explícito `Leitos SUS observados — município, 201912`, **mas no corpo apenas `Não há dados para mostrar`** sob `PERIODO_ANO=2018`; não há barras de dezembro/2019 publicadas | **`F04=BLOCKED_UI_CONTEXT`**: não explica a incompatibilidade `2018 ≠ competência fixa 201912`; não provar zero ou ausência real de capacidade |
| M2-03 | Ilha com as três barras observacionais visíveis em S2, qualitativamente semelhantes à baseline sem seleção. Rótulos densos e sem números impressos | `P23_PASS_VISUAL_RESTRICTED`; não comprova contagens exatas/invariância global |

### Conclusão e classificação

**FATO verificado pela captura:** há estado real selecionado `PERIODO_ANO=2018`, e o M2-02 mostra mensagem genérica de ausência de dados, apesar da expressão fixa `PERIODO_COMPETENCIA={'201912'}` documentada no builder. **NÃO** há evidência de publicação silenciosa de leitos de dezembro/2019 como 2018; **NÃO** há prova de cobertura zero ou ausência de registros CNES de 2018. **Hipótese compatível**: o filtro `PERIODO_ANO=2018` exclui o snapshot fixo de 201912 na associação, produzindo vazio; **a causa física exata não foi demonstrada por log associativo/COM**. O bloqueio é precisamente a falta de explicação da incompatibilidade temporal ao usuário.

`MVP_F04=BLOCKED_UI_CONTEXT`; `F04_TEMPORAL_STALE_VALUE_SHOWN=NO_IN_SCREENSHOT`; `F04_M2_01_2018_SERIES=PASS_GUI_RESTRICTED`; `F04_M1_02_2018_12_MONTHS=PASS_GUI_RESTRICTED`; `F04_P23_ISLAND=PASS_GUI_RESTRICTED`; `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`; `C2_GUIDED_R2=NOT_TESTED`; `C3/C4/LINK_KEY/P5_GLOBAL/IX/PRODUCTION=NOT_APPROVED`.

**STOP F04 atingido:** o teste está **encerrado com bloqueio localizado**, sem repetir ano 2017/2019 nem reconstruir QVW. **Próximo escopo proposto — não implementado nem autorizado como alteração física por esta evidência:** corrigir aviso temporal de **M2-02 apenas**, quando o estado temporal explícito for incompatível com 201912, mantendo `Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)`, título, guarda RES já configurada, o comportamento de M2-01 e ilha M2-03. Testar em **nova cópia TEMP** com captura do cenário conflitante 2018 e cenário compatível sem filtros. A estratégia de coexistência de motivos RES e temporal deve ser definida antes de mexer em `Calculation Condition`/mensagens (não substituir silenciosamente o texto F03-U1). Se a UI não suportar avisos distintos preservando os contratos, STOP e decisão formal de apresentação. Não alterar `main`, fazer merge ou promover C2 físico por esse gate.
