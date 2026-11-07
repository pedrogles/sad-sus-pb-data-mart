# SAD SUS PB — Consolidação de evidências MVP e fronteiras C2/C3/C4

**Data da revisão:** 07/11/2026. **Natureza:** síntese documental **read-only** de fontes existentes e planejamento de gate; **sem execução de QlikView, COM, PowerShell, Reload, scripts, QVD, QVW ou merge** nesta tarefa. **Branch experimental:** `proposal/sad-mvp-rebaseline-2026-11-07`, PR [#226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226) **Draft**; nenhuma evidência do PR altera a `main` automaticamente. **Objetivo:** reconhecer os PASS restritos já conquistados, apontar lacunas reais para os nove visuais e selecionar **um próximo gate de decisão**, sem reabrir F01–F03.

## 1. Autoridade e baseline

1. Consultados na `main`, nessa ordem: `AGENTS.md`; `docs/project/current-state.md`; `docs/academic/requirements.md`; posteriormente [Boundary 7](../discovery/boundary-7-implementation-plan.md), [V2 §62](../discovery/phase-6-semantic-v2-approved-2026-10-14.md), [V3 D2-R2](../discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md).
2. [M0 B1 aprovado pelo responsável **na branch**](mvp-scope-owner-approved-2026-11-07.md): manter três fatos, oito dimensões, fluxo acadêmico e QlikView 12; MVP **três folhas, nove visualizações**, filtros nativos simples, POP descritiva e ausência de T24/T25/T26. Não confundir aprovação de **escopo** com GO de implementação definitiva.
3. Fontes de prova em #226: [readiness M1 e deltas](mvp-contract-deltas-and-m1-readiness-2026-11-07.md), [M2 três folhas](mvp-three-sheets-implementation-2026-11-07.md), [revisão de GUI M2/M3](mvp-three-sheets-visual-review-2026-11-07.md), [F01](mvp-native-filter-smoke-protocol-2026-11-07.md), [F02](mvp-native-filter-residence-f02-protocol-2026-11-07.md), [F03 diagnóstico](mvp-native-filter-residence-leitos-f03-protocol-2026-11-07.md) e [F03-U1 correção de UI](mvp-f03-lt-guard-ui-temp-2026-11-07.md).
4. Os logs/saídas dos scripts foram **reportados pelo operador local**; a análise de GUI incluiu screenshots reais enviadas na conversa e hashes registrados nos relatórios. O agente **não** abriu/validou o QVW binário nem acessou o QlikView Desktop Windows remotamente. A documentação versionada e o PR **não** são evidência de persistência do último QVW após reabertura.
5. `main:docs/project/current-state.md` é um snapshot de 03/11 com C2 físico pendente e o antigo blueprint de 14 visuais; o escopo B1 aprovado e as evidências F01–F03 estão apenas no Draft #226. **DRIFT DE FONTE PARA CONSULTA:** ler a `main` como autoridade vigente e este documento como estado **proposto/experimental**. Revisar o snapshot e o delta 14→9 **somente por decisão de integração separada**, não editar `main` agora. Certas seções iniciais de M0/M1/M2 ainda dizem `NOT_RUN`; são históricas e foram complementadas por seções posteriores. Não usar apenas cabeçalho antigo como status atual.

## 2. Inventário de resultados com nível de evidência

| Gate/superfície | Evidência obtida | Estado QUALIFICADO | Lacuna sem repetir o gate |
|---|---|---|---|
| M0 — produto B1 | Responsável aprovou 3 fatos, 8 dimensões, 3 folhas e 9 análises, nativas; sem T24–26 | `OWNER_MVP_SCOPE_APPROVED=YES_BRANCH_ONLY` | Merge/alteração formal da `main` pendente de autorização própria |
| M1 — artefatos | 10 QVDs de extração + 12 QVDs de transformação + 3 QVWs canônicos; 25/25 SHA iguais ao backup local | `M1_INVENTORY=PASS_LOCAL_REPORTED` | Integridade SHA local não é restore test de desastre |
| M1 — consumo | QVW TEMP três fatos; dez oráculos por fato reportados conformes | `M1_FACT_ORACLES=10_OF_10_PASS_LOCAL_REPORTED` | Não é teste global de UI nem Link Key final |
| M2 — protótipo | Em QVW TEMP, três folhas, 9 eventos `M2_CREATED`, três fatos, ilha P23, 25 originais e QVW M1 preservados; `M2_VERDICT=BUILT_CANDIDATE_ONLY_NOT_HOMOLOGATED` | `M2_NATIVE_BUILD=PASS_LOCAL_REPORTED_CANDIDATE_ONLY` | A configuração manual posterior da guarda LT **não** está incorporada ao builder |
| M3-01 — fluxo | R=S **294635**, R≠S **260454**, total SIH/RD **555089**, 0 unmatched; screenshot duas barras | `M3_FLOW=PASS_ORACLES_LOCAL_AND_GUI_RESTRICTED` | Partição por seleção 2019 não tem oráculo independente nas barras |
| M3-03 — POP | Qlik COM `UsePartialSum=False`; sem total trianual visível; POP ano 2019 = **4018127** na validação de campo | `M3_POP=PASS_COM_AND_GUI_RESTRICTED` | POP×ano×município completo, total/rodapé e P5 sob outros filtros pendentes |
| F01 — 2019 nativo | `Seleções Atuais=2019`; M3-02 **188246**; M3-03 somente linhas 2019 no trecho capturado | `F01_NATIVE_2019=PASS_PROPAGATION_RESTRICTED` | Eixo de competências 201901..201912 fora do print; `F01_FULL_ACCEPTANCE=INCONCLUSIVE` |
| F02 — residência única | `RES_COD_DATASUS_6=251370`; par dirigido `251370→250750=12176` (P3.3); total RES 24616; POP anual por RES | `F02_RES_ROLE=PASS_GUI_RESTRICTED` | Seleção SERV inversa e combinações multi-filtro não verificadas; C3 global pendente |
| F03 — diagnóstico LT | Com RES=251370, M2-01/M2-02 mostraram “Não há dados para mostrar”, M2-03 permaneceu com três barras | `F03_INITIAL_UI=BLOCKED_FOR_USER_USE` | Bloqueio **local** resolvido na cópia F03-U1, não no QVW M2 de origem |
| F03-U1 — guarda LT | Na **cópia TEMP** `SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8/SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`, M2-01 e M2-02 configurados manualmente com `=GetSelectedCount(RES_COD_DATASUS_6, True())=0`; screenshots mostram S_BAD RES=251370 e texto de indisponibilidade, S_OK sem seleção e duas séries/ranking recuperados; P23 permanece três barras | `MVP_F03_UI_GUARD=PASS_GUI_RESTRICTED` | QVW após fechar/reabrir e SHA pós-salvamento não validados; regra não incorporada ao builder, não vale para todas as rotas P5 |

**Sem alteração de modelo aprovada por este inventário:** `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`, oito dimensões conformadas, `LINK_ANALISE/%LINK_KEY` e grãos permanecem conforme documentação acadêmica. A classificação M3 é projeção adicional **in-memory TEMP**, não uma fato nova.

## 3. Matriz de nove visuais — prontidão de uso

| Objeto | Estado funcional neste MVP | Limite que importa para o uso |
|---|---|---|
| M1-01 SIH ano | Total 2017–19 e clique 2019 coerentes no gate restrito | Escopo nativo de um ano comprovado; não afirmar cobertura de todas as seleções temporais |
| M1-02 SIH competência | Linha 36 meses sem filtro e recálculo visual após 2019 | Captura F01 cortou eixo mensal; verificação 12 competências no **mesmo visual** pendente |
| M1-03 ranking SERV | Barras renderizadas e recalculadas em 2019 | Eixo X ilegível; ranking/ordenação e compatibilidade do papel SERV ainda não homologados |
| M2-01 LT snapshots | Séries SUS/existentes reaparecem em S_OK; aviso sob RES em S_BAD | Guardas somente na cópia TEMP configurada manualmente; snapshot mensal, sem soma de meses |
| M2-02 LT municipio 201912 | Barras voltam em S_OK; aviso sob RES em S_BAD | **Risco temporal não testado:** expressão fixa `PERIODO_COMPETENCIA={'201912'}` enquanto seleção nativa pode indicar outro ano/competência; não declarar validade sem cenário específico |
| M2-03 observabilidade | Três categorias P23 visíveis mesmo sob filtro RES | Independência provada **visualmente nesse cenário**; rótulos truncados e contagens por filtro não auditadas em GUI |
| M3-01 RES=SERV | Duas classes em estado neutro e sob 2019/RES, totais triênio reconciliados | Barras sem valores impressos; agregação por outros filtros pendente |
| M3-02 pares dirigidos | Total triênio 555089, ano 2019 = 188246, testemunho 251370→250750=12176 | Usabilidade: tabela estreita, cabeçalhos truncados, muitos pares; sem validação global das chaves |
| M3-03 POP por ano | Com 2019 e RES=251370, linhas anuais coerentes, sem total trianual visível | Prova populacional pontual, não cobertura de todos recortes ou adequação de denominadores |

**Critério de prontidão:** `MVP_AS_ACADEMIC_FINAL=NOT_APPROVED`, apesar de a estrutura física com três folhas/nove objetos existir; o uso em demonstração deve manter avisos metodológicos, explicitar que a QVW é TEMP e evitar resultados sob filtros ainda sem prova.

## 4. Conciliação C2 → C3 → C4 sem aprovação implícita

| Contrato da `main` | Fato já demonstrado no MVP | O que falta decidir/provar | Status |
|---|---|---|---|
| **C2 / D2-R2 V3** | F01: uma seleção nativa 2019 propagou corretamente. F03-U1: aviso contextual nativo pós-seleção RES **apenas para dois gráficos LT**. | A V3 exige **prevenção pré-despacho quando existirem controles guiados aprovados** e **revalidação por indicador após rotas nativas**. O B1 removeu os controles guiados **da superfície do MVP**, não revogou o contrato V3 na `main`. **DECISÃO PENDENTE:** aceitar como `NOT_APPLICABLE_TO_MVP_SURFACE` a parte guiada ausente, com evidência de que não há controles guiados no MVP, e definir uma **matriz reduzida por indicador/seleção nativa**; não chamar isso `C2_GUIDED_R2=PASS`. | `C2_MVP_REBASELINE=NEEDS_APPROVED_GATE_DEFINITION`; `C2_GUIDED_R2=NOT_TESTED` |
| **C3 / Link e role-playing** | F02: direção RES→SERV e uma contagem dirigida acertaram; link carregada no modelo técnico sem multiplicação de FI no oráculo M3 | Auditoria física de associações/keys/nulos/cardinalidade e cenário de SERV inverso; P23 isolado somente em teste de RES; POP não pode virar residência de paciente externo | `LINK_KEY_CONTRACT=NOT_APPROVED`; `C3=NOT_APPROVED` |
| **C4 / medidas e compatibilidade** | Totais separados FI, LT 201912, POP 2019 e estados P23 observados; no F03-U1 supressão em **dois** objetos para RES. Nenhuma razão T24–26 exibida | Contratos físicos por medida/filtro, tempo parcial e seleção incompatível, ausência versus zero observado e cobertura CNES; validar Set Analysis de 201912 sob ano/competência conflitantes; não inventar POP mensal | `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `P5_D2_UI=NOT_APPROVED_GLOBAL`; `C4=NOT_APPROVED` |
| **GO IX / QVW final** | QlikView 12 TEMP de 3 folhas/9 objetos existe; capturas visuais da montagem e dos filtros restritos | Após gates aprovados e autorização formal própria, incorporar guardas à rota de build/entrega, persistência/reabertura, legibilidade, notas metodológicas, testes de regressão | `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False` |

### Observação de risco e fonte a revisar

- **DRIFT DE ESCOPO** entre `main` e Draft #226: blueprint de 14 visuais continua formal na `main`, enquanto B1 9 visuais aprovado pelo responsável **vale apenas para o protótipo branch**. **Risco:** professor/revisor abrir `main` ou o QVW canônico esperando o produto que só existe em TEMP. **Ação:** manter delta explícito e preparar decisão formal de integração documental separada, sem fazer merge por arrasto.
- **DRIFT DE IMPLEMENTAÇÃO:** F03-U1 salvou manualmente uma guarda no QVW TEMP, enquanto `tools/Build-SadMvpThreeSheetsTemp.ps1` ainda constrói os nove gráficos **sem essa guarda**. **Risco:** uma nova construção elimina a proteção. **Ação:** antes de qualquer entrega/reconstrução, decidir e versionar implementação reprodutível da guarda com prova real (sem tentar COM não testada).
- **DRIFT DE REGISTRO:** cabeçalhos anteriores em `docs/project/mvp-contract-deltas-and-m1-readiness-2026-11-07.md` e `docs/project/mvp-three-sheets-implementation-2026-11-07.md` ainda descrevem fases `NOT_RUN`, embora seções subsequentes tenham evidências de PASS restrito. **Ação:** usar esta síntese como índice, não reescrever retrospectivamente logs originais sem revisão documental deliberada.
- **RISCO DE INTERPRETAÇÃO:** no recorte RES, “sem linhas LT” foi corrigido para indisponibilidade com motivo; zero observado da P23 não comprova cobertura hospitalar. Não afirmar produção ou taxa de ocupação por confusão com snapshots.

## 5. Próximo gate único proposto — decisão documental de aceitação C2-MVP (sem executar ainda)

**Nome sugerido:** `SAD-MVP-C2-NATIVE-POST-SELECTION-ACCEPTANCE-SCOPE-01`. É **proposta**, não um substituto aprovado do contrato V3.

**Objetivo:** fechar o critério de aceitação **especificamente para os nove objetos com filtros nativos B1** antes de executar novo teste físico, sem reintroduzir por default BU15/BU16/modes guiados retirados do MVP e **sem declarar a prevenção guiada global como PASS**.

**Entrada reutilizável:** F01 2019, F02 RES=251370, F03-U1 avisos LT, M3 valores FI e POP, #201/#205/#208/#210 como evidências históricas **se relevantes**. Não repetir nenhum desses testes por rotina.

**Decisões que dependem de aprovação explícita do responsável:**
1. Confirmar que `GUIDED_PRE_DISPATCH_PREVENTION=NOT_APPLICABLE_TO_B1_MVP_SURFACE` por **ausência real** de controles guiados nos nove objetos, **sem** alterar D2-R2 V3 aplicável a fluxos guiados quando existirem.
2. Aprovar uma matriz mínima pós-seleção, por **medida e filtro**, separando estados `VALID`, `UNAVAILABLE_WITH_REASON` e `INCONCLUSIVE`. Não permitir indicadores incoerentes se o ano/competência não corresponder ao título/expressão.
3. Autorizar **mais adiante**, sob um gate físico separado e com STOP no primeiro desvio, **um único cenário prioritário ainda não comprovado**: selecionar `PERIODO_ANO=2018` de forma nativa e inspecionar o objeto **M2-02 fixo em 201912**. **Critério:** não apresentar leitos de 201912 como se fossem capacidade de 2018; resultado pode ser indisponível com motivo. Simultaneamente conferir somente se M1-01 reflete 2018 sem inventar novo oráculo de CNES.
4. Decidir se o indicador M2-02 permanece fixado no mês 201912 com aviso contextual, ou se a UI deve exigir competência válida/explicitar que a medida fixa ignora o filtro temporal — **sem trocar a medida silenciosamente**. Caso a seleção seja conflitante, não usar Set Analysis para ignorar o contexto e publicar número como atual.

**PASS documental esperado:** matriz de aceitação do MVP aprovada **apenas para a superfície B1**, com teste físico futuro nomeado e limites explícitos. **BLOCKED:** tentativa de reclassificar o C2 global como PASS, mudança de D2-R2 sem autorização ou presunção de segurança do Set Analysis fixo. **STOP:** finalizar esta consolidação e aguardar a decisão própria; **não executar agora F04, CLI, COM ou Reload**.

## 6. Encerramento

`MVP_EVIDENCE_CONSOLIDATION=DOC_REVIEW_COMPLETE`. `MVP_F03_UI_GUARD=PASS_GUI_RESTRICTED`. `MVP_C2_C3_C4=OPEN`. `OWNER_C2_MVP_ACCEPTANCE_SCOPE=DECISION_PENDING`. `MVP_READY_FOR_FINAL_ACADEMIC_PRESENTATION=NO` sem ressalvas/aceites adicionais. `PR226=DRAFT_NOT_MERGED`. `PHASE_IX=NOT_AUTHORIZED`. `PRODUCTION_APPROVED=False`.

**Escopo efetivamente tocado nesta tarefa:** somente este Markdown e sumário do PR Draft #226. Nenhuma mudança em `main`, `AGENTS.md`, `current-state.md`, `requirements.md`, Boundary 7, V2/V3, scripts, fatos, QVD/QVW ou desenho de nove visuais. Nenhuma exclusão/merge/force push.
