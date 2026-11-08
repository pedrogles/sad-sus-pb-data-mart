# SAD — C2 guiado R2 | especificação física mínima e decisão de entrada

**Data:** 08/11/2026. **Gate documental:** `SAD-C2-GUIDED-R2-PHYSICAL-SPEC-01`. **Estado:** `SPEC_PROPOSED_NOT_EXECUTED`. **Branch própria, originada da `main`:** `proposal/sad-c2-guided-r2-physical-gate-2026-11-08`. Este documento **não** modifica o MVP B1, não aprova execução física nem concede `C2_GUIDED_R2=PASS`.

## 1. Objetivo, autoridade e fronteira

**Objetivo único desta entrega:** delimitar **qual prova física residual** é necessária para avaliar a prevenção *antes do despacho guiado* e a mensagem de motivo segundo D2-R2 V3, escolhendo uma fonte QVW experimental verificável e sem repetir PoCs concluídas. Não implementar botão, reabrir PoCs, executar testes, criar executor, nem alterar modelo/medida/visual.

**Fontes lidas na `main`, na ordem obrigatória:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`; em seguida `docs/discovery/boundary-7-implementation-plan.md`, `docs/discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md` (adendo D2-R2 vigente segundo current-state), [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196), e evidências dos PRs [#201](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201), [#205](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205), [#208](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/208) e [#210](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/210).

**Fronteira crucial:** o MVP B1 aprovado, descrito no [PR #226 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226), tem **3 folhas, 9 visuais e apenas filtros nativos**, sem BU15/BU16. Sua guarda nativa pós-seleção e os PASS GUI F03/F04 **não** homologam despacho guiado. **Não inserir BU15/BU16 na QVW do MVP B1** para tentar fechar C2 sem decisão explícita de produto/escopo. Reciprocamente, o D2-R2 V3 da `main` continua vigente quando uma aplicação realmente disponibiliza despacho guiado.

## 2. Reutilização e lacunas comprovadas

| Evidência de origem | Resultado reutilizável | Limite que impede homologação |
|---|---|---|
| #201, merged | `BU15` aplicou `EVOLUCAO/2019` com seleção real do ano em cenário sem seleção temporal anterior | Somente despacho positivo restrito; não prova conflito bloqueado |
| #205, Draft | Gráfico guiado separado apresentou 12 competências `201901..201912`, total **188.246**, 12/12 coerentes com oráculo arquivado | Não repetir o gráfico; nenhuma prevenção universal comprovada |
| #208, Draft, [closeout físico](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/test/sad-c2-integrated-predispatch-negative-20261103/docs/discovery/sad-c2-integrated-predispatch-negative-physical-gate-2026-11-03.md) | QVW TEMP `SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw` com SHA-256 **reportado** `A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517`; `BU16` com seleção real `PERIODO_ANO=2019`, competência sem seleção; proposta `MENSAL/2019/01` habilitada e `MENSAL/2018/01` desabilitada no retorno | Sequência estrita `0→1→0` inconclusiva; **BU16 nunca foi clicado** segundo operador; motivo UX não comprovado; `Verify` confirmou integridade local e presença de capturas, não despachos |
| #210, Draft, [inventário de rotas](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/test/sad-c2-single-qvw-routes-readonly-20261103/docs/discovery/sad-c2-single-qvw-routes-readonly-gate-2026-11-03.md) | Na cópia TEMP de #208, três folhas, `BU15/BU16`, `CH02/CH03` e `LB01/LB04` somente leitura observados; menus/busca/bookmarks acessíveis; QVW fonte com SHA reportado igual ao #208 | Inventário visual **não prova prevenção** de rotas nativas, nem ocorrência de bypass; não comprova que `CH03` ou KPI relacionado revalide após seleção nativa conflitante |
| #226, Draft MVP B1 | F03/F04 guardas em `CH04/CH05` de **outra QVW TEMP** com PASS GUI restrito e persistência SHA local | **Não é a mesma QVW** de #208; não transplantar objetos, hashes, resultados ou garantia guiada |

**Ponto de decisão de entrada:** a única fonte experimental guiada efetivamente identificada nas evidências é a QVW de **#208** com o hash acima. O **caminho absoluto do arquivo de origem atual no Windows deve ser inspecionado e confirmado pelo operador**, não inferido da pasta de evidências e não substituído pela QVW F04 do MVP. A cópia de inventário de #210 também é histórica, não fonte canônica. Sem arquivo exato e hash atual íntegro, `BLOCKED_NO_PINNED_GUIDED_QVW`.

## 3. Contrato normativo mínimo C2 guiado R2

1. **Despacho guiado — regra anterior:** diante da proposta de competência `MENSAL/2018/01` quando o **ano real aplicado permanece 2019** e competência real não está selecionada, a interface deve identificar o conflito **antes** da ação `Select in Field`, **não** substituir/limpar o ano aplicado nem selecionar `201801`, e explicar o motivo. Uma variável proposta não constitui seleção real.
2. **Proposta válida — contraste:** `MENSAL/2019/01` com ano real `2019` pode habilitar o botão dentro de domínio e compatibilidade, mas **o positivo de 2019 dos PRs anteriores não será repetido** como ritual. Habilitação observada não equivale a despacho bem-sucedido, e vice-versa.
3. **Seleção nativa — regra posterior:** se uma rota nativa alterar estado temporal efetivo, os **indicadores expostos naquela QVW** devem distinguir `VALID`, `UNAVAILABLE_WITH_REASON` e `INCONCLUSIVE`, sem publicar valores incompatíveis como válidos. O escopo físico de objetos/medidas e filtros precisa ser identificado *antes* de projetar um teste. Não usar a guarda das CH04/CH05 de outra QVW como prova.
4. **Relação com P5:** preservar a matriz C/R/I/B aprovada, papéis RES/SERV e disponibilidade por medida. Não construir KPI, taxa ou denominador apenas para “fechar C2”, pois C3/C4 continuam não aprovados. Não converter ausência CNES em zero.
5. **Garantia explicitamente limitada:** `GUIDED_PRE_DISPATCH_PREVENTION` aplica-se só às ações de controles guiados aprovados; `NATIVE_POST_SELECTION_VALIDATION` aplica-se **após** operações nativas, não há `D2_GLOBAL_PREVENTION` homologado.

## 4. Próximo gate executável proposto, ainda SEM autorização de execução

**Nome provisório:** `SAD-C2-GUIDED-R2-PHYSICAL-PREFLIGHT-01`. **Uma rodada de preflight read-only, antes de qualquer tentativa de despacho ou GUI editável.**

1. Confirmar no Windows a **existência**, caminho real e SHA-256 da QVW guiada #208 `SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw` esperada `A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517`, sem abri-la para gravação; conferir o inventário protegido 10+12 QVDs/3 QVWs em evidência existente, sem rehash em massa por rotina.
2. Fazer inventário **somente de metadados/descrições já disponíveis** dos controles `BU16`, `BU15`, `CH03`, suas variáveis e mensagem de UX, evitando repetir inspeções de menus/buscas/bookmarks concluídas em #210. Verificar se **uma mesma QVW** possui de fato (i) condição de habilitação, (ii) mecanismo claro de motivo e (iii) indicador cuja revalidação temporal possa ser comprovada, sem inventar nenhum desses objetos.
3. Classificar `READY_FOR_SINGLE_PHYSICAL_TEST` **somente** se a origem e escopo forem confirmados, o teste puder ocorrer em **nova cópia isolada** e o responsável autorizar explicitamente o ato físico. Se o mecanismo de razão de bloqueio não existir, ou a QVW não oferecer indicador adequado, registrar lacuna `BLOCKED_SAME_QVW_UI_CONTRACT`, **sem adicionar objetos/controls silenciosamente**.
4. Não executar ainda a proposta inválida. Uma eventual prova de despacho negativo deve especificar previamente como observar **não alteração do estado aplicado** e mensagem de motivo, sem presumir que botão cinza impede todas as rotas nativas. Qualquer ação de clique/configuração requer protocolo/runner versionado, cópia hash-pinned e autorização própria.

**Oráculos já reutilizados:** `PERIODO_ANO=2019` / um selecionado; `PERIODO_COMPETENCIA` / zero selecionados no cenário negativo #208; `EVOLUCAO/2019` gráfico 12/12 = `188246` em #205, **somente quando a mesma semântica e janela forem aplicáveis**. **Não** somar leitos/pessoas, não reconstruir dados para este gate.

## 5. Critérios e STOP

| Resultado | Critério |
|---|---|
| `SPEC_PASS_DOCUMENTAL` | Fontes e invariantes confirmadas, lacunas físicas isoladas, entrada/saída descritas, sem alterar aplicação |
| `PREFLIGHT_READY` futuro | Fonte exata pinada e íntegra, escopo de controle/indicador demonstrado **na mesma QVW**, ausência de risco aos 25 artefatos canônicos e autorização física explícita |
| `BLOCKED` | Origem QVW não disponível/hash divergente, não há UI de motivo, controle/indicador incompatível, intento de modificar MVP B1 ou QVW canônica |
| `INCONCLUSIVE` | Metadados ou evidência não permitem decidir qual controle/indicador cobrir |
| `STOP` | Após **esta especificação documental**, sem scripts, testes Windows, clicks/dispatch, novas QVW/QVD, rebuild, mudanças de semântica, merge ou expansão para C3/C4 |

**Permissões desta execução:** **apenas** este Markdown em branch própria, aberto como PR Draft para revisão. O MVP B1 no PR #226 não é alterado. Nenhum merge, force push, branch deletion, Qlik/COM, Reload, Save, QVS, QVD, QVW ou `main` é permitido.

**Estados finais:** `C2_GUIDED_R2_SPEC=DOCUMENTED_PENDING_REVIEW`, `C2_GUIDED_R2_PHYSICAL=NOT_APPROVED`, `GUIDED_QVW_SOURCE_PIN_VERIFIED_NOW=False`, `C2_MVP_NATIVE=SEPARATE_BRANCH_EXPERIMENTAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `P5_D2_UI=NOT_APPROVED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.
