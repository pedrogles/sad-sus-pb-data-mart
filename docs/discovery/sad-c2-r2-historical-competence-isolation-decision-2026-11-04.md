# SAD C2 — Isolamento histórico e observabilidade sob D2-R2 (minuta)

**Gate documental:** SAD-C2-R2-HISTORICAL-COMPETENCE-ISOLATION-DECISION-01  
**Data:** 04/11/2026  
**Status:** DOCUMENTED_CANDIDATE_NOT_OWNER_APPROVED. Não constitui alteração de semântica aprovada, implementação física, teste de interface ou GO de C2.  
**Main de referência:** 0549e1dba71aaa8bbab9d6755aecb8465f8bea83.

## 1. Objetivo e fontes

**Objetivo estrito:** propor uma regra de isolamento temporal verificável para os quatro cartões históricos P1.1 e o gráfico histórico CH02; especificar comunicação de indisponibilidade e título correto do CH03 dinâmico; decidir qual comportamento deve ser aprovado **antes** de qualquer edição de QVW/expressão.

**Fontes lidas na ordem canônica:** AGENTS.md; docs/project/current-state.md; docs/academic/requirements.md; docs/discovery/boundary-7-implementation-plan.md; docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md; docs/discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md; docs/discovery/sad-p1-p11-p12-ux-contract-2026-10-28.md; docs/project/three-panels-blueprint-approved-2026-11-03.md. Evidências: Issue #196, PRs #201/#205/#208/#210/#213/#215/#216/#217/#218 e capturas do QlikView 12 enviadas pelo responsável em 04/11/2026.

**Regra vigente:** D2-R2 (PR #213 integrado) exige prevenção no despacho guiado e, para operações nativas sem prevenção global garantida, revalidação posterior por indicador conforme seleção real. V2 §62.3 preserva a semântica de períodos parciais, meses não consecutivos, múltiplos anos como série dimensionada e indisponibilidade do KPI anual pontual sem ano único. A referência temporal FI é a competência administrativa SIH/RD, não DT_INTER. P5, modelos de dados, C3 e C4 não são alterados.

**Invariantes:** QlikView 12; três fatos/oito dimensões; Boundary 7; não modificar QVD/QVW/QVS/código/dados; não reaproveitar PASS restrito como aprovação global; não editar a main; não fazer merge; não repetir meses 13, BU16, 12/12 ou os Verify encerrados.

## 2. Inventário físico comprovado na TEMP, não em QVW de produção

**Proveniência:** 15 capturas de propriedades, disponíveis nesta conversa, da QVW TEMP:
C:\Users\pedro\Documents\SAD_C2_BU16_POSITIVE_RUNTIME\SAD_C2_BU16_POSITIVE_a0ea234ecdde48579e5ae05f27ced98c\SAD_C2_R2_BU16_POSITIVE_TEMP.qvw

O SHA-256 648107FB45E61C6D5AA16EBA0959C58FAD579529DEC93CF42F74A9C9D957F9DD foi reportado pelo Verify prévio do PR #218; não foi recalculado por esta minuta. O agente **não leu os bytes da QVW** e as capturas **não foram versionadas** no GitHub.

| Indicador | ID do objeto (visto em captura) | Expressão/definição visível | Apresentação |
|---|---|---|---|
| P1.1 — 2017 | TX13 | Sum com set modifier PERIODO_ANO={2017} sobre QTD_INTERNACAO | Cartão 183.532 |
| P1.1 — 2018 | TX11 | Sum com PERIODO_ANO={2018} | Cartão 183.311 |
| P1.1 — 2019 | TX12 | Sum com PERIODO_ANO={2019} | Cartão 188.246 |
| P1.1 — triênio | TX10 | Sum com PERIODO_ANO={2017,2018,2019} | Total do triênio 555.089 |
| P1.2 — histórico | CH02 | Dimensão PERIODO_COMPETENCIA; Sum com PERIODO_ANO={2017,2018,2019}; condição de cálculo vazia | Linha de 2017 a 2019 |
| P1.2 — evolução guiada | CH03 | Dimensão PERIODO_COMPETENCIA; medida Sum(QTD_INTERNACAO); condição abaixo | Título literal contém 2019; fora da condição aparece mensagem genérica |

**Condição efetiva vista no editor CH03:**

~~~qlik
=If(
  '$(vSAD_POC_Mode)'='EVOLUCAO'
  and GetSelectedCount(PERIODO_ANO)=1
  and GetSelectedCount(PERIODO_COMPETENCIA)=0
  and Only(PERIODO_ANO)=Num($(vSAD_POC_Year)),
  1,0
)
~~~

A interface mostrou quatro números históricos e CH02 de 36 meses; CH03 exibia “Condição de cálculo não satisfeita”. Não deduzir, sem estado real concomitante, a causa exata daquela indisponibilidade. Não confundir TX16 (canário anual pontual que ficou indisponível após BU16 positivo) com um dos quatro cartões históricos.

## 3. Decisão de produto candidata — aprovação expressa PENDENTE

**Alternativa A — RECOMENDADA: referência histórica fixa no tempo; filtros não temporais condicionados.**

1. TX10/TX11/TX12/TX13 e CH02 representam o **período administrativo de referência 2017–2019**. A seleção real de um mês ou ano para uma análise guiada não deve truncar silenciosamente os totais históricos mantendo rótulos anuais/triênio. O intervalo histórico deve continuar fixo **temporalmente** mesmo que o usuário selecione uma competência em outras superfícies.
2. Aviso textual obrigatório: “Histórico de referência — 2017–2019. O filtro temporal aplicado não altera este histórico.” Para cartão anual, ano próprio; para TX10, “Total do triênio”, nunca “KPI anual”.
3. Filtros **não temporais** válidos podem permanecer ativos nas expressões históricas, se aprovados pela política do indicador. O número deverá refletir o recorte e o título/aviso informá-lo. Não ignorar filtros incompatíveis, papéis RES/SERV ou P5 silenciosamente. Os números 183532/183311/188246/555089 são oráculos do contexto **sem filtros adicionais**.
4. Se o período completo não puder ser mantido sob alguma seleção, exibir indisponibilidade explícita com motivo; não exibir valor parcial como histórico completo. Garantia operacional só após teste físico com meses e oráculos, não por uma expressão parecer correta.
5. CH03 continua separado: é evolução **guiada de um ano aplicado**. Outras visões podem lidar legitimamente com meses parciais/multianuais (V2 §62.3), ainda que CH03, nessa configuração, não atenda às condições específicas da sua visualização.

**Alternativa B — não recomendada sem novo aceite:** referência ignorando **todas** as seleções, inclusive não temporais. Usar o identificador de conjunto 1 em Qlik pode manter números constantes, mas apagaria analiticamente filtros e poderia violar observabilidade/P5.

**Alternativa C — não autorizada:** ilha/estado alternativo ou reestruturação de associações. Eleva complexidade arquitetural e requer decisão separada; não derivar de uma limitação visual sem prova.

**DECISÃO PENDENTE:** aprovação explícita da alternativa A pelo responsável para que se possa posteriormente especificar alterações físicas. “Prosseguir” autoriza produzir esta minuta, **não merge, produção ou mudança silenciosa de política**.

## 4. Técnica candidata QlikView — NÃO executar nesta etapa

A documentação oficial QlikView September 2026 diferencia:
- Identificador $ = seleção atual; 1 = todos os registros, independentemente das seleções;
- Um modificador com atribuição vazia remove a seleção do campo especificado, preservando os demais campos do estado de referência.

Fontes:
- https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-analysis-expressions.htm
- https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-modifiers.htm

**Hipótese mínima de implementação, não validada, não colar na QVW neste gate:**

~~~qlik
// Cartão de 2017 — apenas corpo numérico; preservar Num e sua formatação atual:
Sum({$<PERIODO_ANO={2017},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)

// Triênio:
Sum({$<PERIODO_ANO={2017,2018,2019},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)

// CH02 — medida, sem alterar dimensão PERIODO_COMPETENCIA:
Sum({$<PERIODO_ANO={2017,2018,2019},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)
~~~

**Riscos e limites:**
- Remover PERIODO_COMPETENCIA em uma medida **não garante**, por si, que o eixo/dimensão do CH02 renderize 36 competências sob seleção explícita do mês; verificar **36/36 pontos** e 36 valores, não somente o total.
- Associações temporais indiretas e outros campos da QVW podem ainda reduzir o conjunto mesmo após esse modificador. Não inventar correção de %SK_* ou criar campo novo sem inspeção/modelagem aprovada.
- Manter $ preserva **outros filtros**, cuja compatibilidade depende do contrato; 1 não seria um substituto neutro.
- Se a hipótese não proteger a série histórica, registrar BLOCKED_HISTORIC_AXIS; não migrar para estado alternativo nem limpar campos automaticamente como workaround.
- A semântica de Set Analysis é documentada pela Qlik, mas **seu comportamento no modelo físico específico não foi testado**.

## 5. Observabilidade e rótulos CH03 — contrato UX candidato

A condição física do CH03 é **prova de guarda de cálculo**, não prova de mensagem de indisponibilidade específica. O título atual “Evolução mensal guiada — 2019 (PoC)” é literal e pode ficar incorreto em 2017 ou 2018.

**Comportamento proposto:**

| Situação real observada | Reação de CH03 |
|---|---|
| Um ano real selecionado, igual ao proposto; modo EVOLUCAO; nenhuma competência explicitamente selecionada; dados/cobertura compatíveis | Exibir série do ano real; título mostrar **ano efetivamente aplicado**, e não 2019 literal |
| Nenhum ano real selecionado | “Indisponível — selecione um ano para a evolução guiada.” |
| Dois ou mais anos reais selecionados | “Indisponível nesta evolução guiada — esta visão requer ano único.” Não considerar séries multianuais de outros visuais inválidas |
| Competência explícita selecionada | “Indisponível nesta visão de evolução anual guiada — existe seleção mensal aplicada.” Não declarar seleção mensal globalmente inválida |
| Ano proposto diferente do ano real | “Não aplicado — ano proposto difere do ano real.” |
| Outro modo proposto, com seleção real preservada | “Evolução anual guiada não ativa neste modo.” |
| Filtro não temporal incompatível / ausência de registros / cobertura incerta | Mensagem **distinta para cada causa**, sem tratar ausência como zero e sem homologar P5 por herança |

**Hipótese de UI:** título dinâmico baseado no ano **real** para CH03 e objeto de texto complementar de motivo. Propriedades e formulação ainda precisam de prova no QlikView 12; **nenhum novo objeto foi comprovado ou criado nesta etapa**. Não usar apenas cor ou mensagem técnica genérica. Se a guarda não permite distinguir motivos, adicionar diagnóstico de leitura do estado real em gate próprio, não com múltiplas mutações nesta minuta.

## 6. Casos de aceite candidatos, sem nova execução

| Caso | Estado real | Histórico P1.1/CH02 (se A aprovada e implementada) | CH03 |
|---|---|---|---|
| H0 | Nenhum filtro temporal, sem outros filtros | 4 valores oraculares + 36 competências CH02 | Sem ano real: aviso adequado |
| H1 | Ano real 2019 e competência real **201901** após despacho mensal | Os mesmos históricos e 36/36, com rótulo fixo que explicita independência temporal | Indisponível por mês explícito, não mensagem genérica; nenhum valor stale |
| H2 | Nativo Seleções > Limpar, sem ano real | Histórico fixo pode permanecer, mas deve informar regra; não confundir com KPI anual pontual | Motivo “ano não selecionado” |
| H3 | EVOLUCAO com ano real 2017 ou 2018, sem competência explícita | Mesmo histórico sob ausência de outros filtros | 12 competências do ano efetivo, título correspondente; não herdar automaticamente PASS de 2019 |
| H4 | Meses não consecutivos ou ano múltiplo via rota nativa | Manter referência histórica temporal se viável; validar 36/36, sem filtrar silenciosamente | Elegibilidade própria; outras séries por ano podem ser válidas |
| H5 | Filtro não temporal válido/incompatível | Aplicar apenas se semanticamente permitido, divulgar recorte ou Indisponível; não usar totais incondicionais como oráculo | Revalidar individualmente; deferir política P5 final para C4 |

**PASS documental deste gate:** mapa de 6 IDs/expressões a partir das capturas, opções com trade-off, proposta padrão, riscos e casos H0–H5, nenhuma mudança de arquivo de dados/objetos, STOP definido.

**Próximo gate físico SOMENTE após aprovação da decisão:** teste estrito H1 em nova QVW TEMP protegida, com alteração mínima e evidência dos cinco históricos/CH03 em 201901, sem repetir BU16 no mesmo arquivo já encerrado; hashes de fonte + 25 protegidos; bloqueio se a dimensão CH02 não mostrar 36 pontos, se algum cartão publicar total mensal com rótulo anual, se filtro não temporal for descartado, ou se o motivo de CH03 não for específico. Scripts PowerShell/QVS utilizados no teste devem estar versionados antes da execução, conforme AGENTS.md. Não multiplicar testes H0–H5 automaticamente.

**STOP:** uma decisão documental; nada de Windows/GUI/COM/reload, QVW/QVD/QVS, refazer oráculo, alterações de main, merge, C3/C4/IX ou produção. Estado: SPEC_DRAFT_READY_OWNER_DECISION; C2_GUIDED_R2=NOT_APPROVED_GLOBAL; P5_D2_UI=NOT_TESTED_GLOBAL; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False. O drift de current-state.md sobre NOT_TESTED será tratado separadamente, sem reclassificação por esta minuta.
