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
