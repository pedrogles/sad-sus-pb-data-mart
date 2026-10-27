# SAD — Preparação documental do gate A0 de validação de consumo (27/10/2026)

**Gate:** SAD-A0-CONSUMPTION-VALIDATION-01  
**Estado:** DOCUMENTATION_PREPARED_ONLY / EXECUTION_NOT_AUTHORIZED / PHYSICAL_NOT_RUN.  
**Autorização:** responsável aprovou expressamente em conversa em 27/10/2026 **somente a preparação documental**, para P1.2, P2.2 e P3.1. Não autorizou desenvolvimento de runner/QVS, teste físico, QlikView/COM/GUI, reload, criação de QVW TEMP, alteração de QVD/QVW, merge, Fase IX ou produção.  
**Fonte de verdade da preparação:** main@db5d6e6e23371422ca1d2d77a8576150aaf63d03, verificada antes de criar esta branch. A versão aqui registrada está em PR Draft; não é contrato físico vigente na main sem integração autorizada.  
**Agente/ambiente da preparação:** ChatGPT GPT-6 + GitHub; esforço não configurado nesta sessão; análise documental, sem Windows/COM. **Executor futuro candidato (não acionado):** Codex Local em Windows com QlikView 12, ou operador autorizado; só após aprovações separadas.

## 1. Objetivo único e condição de parada

Preparar, sem executar, **três casos de validação de consumo A0**, dentro da Fase VIII e da ordem do Boundary 7, para verificar no futuro se um objeto isolado recupera, com semântica correta, medidas das fatos persistidas, dimensões por papel e filtros delimitados:

1. **P1.2** — série mensal de internações SIH/RD.
2. **P2.2** — série mensal de snapshots de leitos CNES/LT observados.
3. **P3.1** — matriz de fluxo SIH/RD residência → serviço.

**PASS documental:** fontes versionadas, campos/grãos reais, oráculos e recortes mínimos, critérios de não duplicação, regras de filtro, limites, bloqueios, STOP e handoff definidos. **Não é PASS físico.**  
**STOP:** dois documentos Markdown de preparação revisados em branch/PR Draft; não estender para os outros 12 visuais, P2.1, T24/T25/T26, KPIs de Fase IX ou novos testes.

## 2. Entradas e hierarquia verificadas

- Na **main**, nesta ordem: AGENTS.md; docs/project/current-state.md; docs/academic/requirements.md; docs/project/agent-model-routing.md.
- Docs acadêmicos e físicos na main: docs/academic/chapter-1-2-modeling.md; docs/discovery/boundary-5-historization-role-playing.md; docs/discovery/boundary-6-qlikview-physical-architecture.md; docs/discovery/boundary-7-implementation-plan.md; docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md.
- Decisão estratégica integrada na main: docs/project/analytical-direction-2026-10-27.md; inventário docs/discovery/analytical-question-inventory-2026-10-27.md; plano docs/discovery/analytical-sufficiency-plan-2026-10-27.md.
- **PR #162 OPEN/DRAFT** (HEAD 56f992ad92f607fb9a34fb9244f9ffcd1251004e): contrato e matriz de consumo analítico, **propostos e não integrados**. Esta preparação não promove A1/A2 nem o PR #162 ao status de arquitetura aprovada.
- **PR #160 OPEN/DRAFT**, AE01 executado localmente no commit 8633f12a910f422f6b2e9af5e0d06d622ff13497; **Issue #161** registra exportação/reconciliação restrita dos quatro CSVs E1–E4 da tentativa 02. Manifesto auditado relatado com SHA-256 0B1AA7DA6EF10A08B0F698250F199666525672DC763D6774CA4498B2A3C488D2. Não reexecutar AE01.
- Artefatos de implementação já versionados: TRANSFORMACAO/transf_fato_internacao.qvs; TRANSFORMACAO/transf_fato_capacidade_leito.qvs; TRANSFORMACAO/transf_fato_populacao_inmemory.qvs; PAINEL/phase_vii_technical_model.qvs. Evidência Fase VII técnica de 16 tabelas e 15 associações em QVW experimental, sem $Syn/loop visível; isso não homologa comportamento global de seleções.
- Referências históricas adicionais: docs/discovery/phase-8-c3b1-physical-closeout-2026-10-20.md; docs/discovery/phase-8-c3b2-physical-closeout-2026-10-20.md; C4-F e Issue #157. Nenhum QVD/QVW/CSV foi aberto ou produzido **nesta preparação**.

## 3. Invariantes e fronteira de permissão

**A0:** constelação Star acadêmica inalterada, três fatos e oito dimensões; LINK_ANALISE e aliases por papel existentes no modelo técnico. **Não** criar fatos agregadas, A1, A2, dimensão, join de conveniência, campo compartilhado novo ou Link Key alternativa.  
**Fases:** Fases I–VI materializadas com provas locais restritas; Fase VII técnica candidata; avaliação futura de consumo somente em escopo de Fase VIII, sem objeto de dashboard definitivo. Ordem C2 → C3 → C4 e Boundary 7 preservada.  
**SIH:** 566.672 registros administrativos, 555.089 novas internações, 11.583 continuidades; IDENT=5 implica QTD_INTERNACAO=0; N_AIH não é PK. Competência administrativa distinta de datas clínicas.  
**LT:** 35.518 linhas em 36 competências; capacidade semi-aditiva, não somar snapshots mensais como estoque anual; ausência de linha ≠ zero; não afirmar oferta hospitalar integral ou leitos operacionais. T29_HISTORICAL=NOT_APPROVED.  
**POP:** 669 município×ano continuam materializados e protegidos, mas **não participam dos três testes**. Nenhum denominador POP ou associação cross-fact é solicitado.  
**Proteção futura (não executada):** antes de qualquer execução autorizada, conferir 22 QVDs, três QVWs canônicos, referência C5.2 e SHA pré/pós; QVW de teste exclusivamente descartável, evidências persistentes fora de Git/TEMP e scripts versionados antes de rodar.  
**Status inalterados:** C2_FULL=NO_GO_NOT_APPROVED; P5_D2_UI=NOT_TESTED_GLOBAL; F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY; LINK_KEY_CONTRACT=NOT_APPROVED; MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False.

## 4. Matriz de contrato dos três visuais

| Caso | Origem quantitativa no consumo A0 | Campos de apresentação existentes no modelo técnico | Oráculo independente já produzido | Semântica permitida |
| --- | --- | --- | --- | --- |
| P1.2 | FATO_INTERNACAO.QTD_INTERNACAO, 1 RD por linha | DIM_TEMPO_COMPETENCIA.PERIODO_COMPETENCIA via LINK_ANALISE e %LINK_KEY; FATO_RD_COMPETENCIA_ORIGEM é rastreabilidade, não novo eixo associativo | E1 sih_fluxo_competencia.csv: competencia e qtd_internacao, somando todos os pares RES/SERV por competência | Novas internações processadas **por competência administrativa**; série de 36 meses |
| P2.2 | FATO_CAPACIDADE_LEITO.QTD_LEITOS_EXISTENTES, QTD_LEITOS_SUS, QTD_LEITOS_NAO_SUS; 1 linha por CNES × competência × CODLEITO | DIM_TEMPO_COMPETENCIA.PERIODO_COMPETENCIA via LINK_ANALISE; FATO_LT_COMPETENCIA_ORIGEM apenas campo factual de rastreabilidade | E4 lt_cnes_leito_competencia.csv: competencia, qt_exist, qt_sus, qt_nsus; somar grupos dentro de **cada competência**, jamais todos os meses como capacidade | Três snapshots mensais observados por ponto; sem inferir cobertura hospitalar ou zeros reais para meses/recortes sem linha |
| P3.1 | FATO_INTERNACAO.QTD_INTERNACAO, mesma fato SIH do P1.2 | DIM_MUNICIPIO_RESIDENCIA.RES_COD_DATASUS_6 + DIM_MUNICIPIO_SERVICO.SERV_COD_DATASUS_6; ambos via LINK_ANALISE/%LINK_KEY; ano PERIODO_ANO | E1: competencia/ano/municipio_res/municipio_serv/qtd_internacao; controle histórico C3-B1/C3-B2 para dois pares 2018 | Distribuição **administrativa** RES→SERV de novas internações processadas na PB; sem pacientes únicos, viagem inferida ou denominador POP |

**Proveniência física:** os campos E1/E4 vêm de SRC_SIH_RD.qvd/SRC_CNES_LT.qvd e **não** devem ser projetados como colunas diretas das fatos. Na FATO_INTERNACAO, municípios e competência de associação estão na coordenada de %LINK_KEY; na FATO_CAPACIDADE_LEITO, município de localização idem. Somente %LINK_KEY conecta as fatos à LINK_ANALISE no modelo técnico. Não presumir aceitação global da chave.

## 5. Casos mínimos para uma futura tentativa física separadamente autorizada

### P1.2 — SIH mensal

- **Cenário positivo:** série 201701 a 201912, agrupada por PERIODO_COMPETENCIA; um ponto por competência; uma medida por ponto, soma de QTD_INTERNACAO da fato SIH.
- **Oráculo:** agrupar E1 por competencia e comparar **36 pares competência → total**, sem apenas conferir total geral. Soma de controle 555.089 e controles anuais 183.532 / 183.311 / 188.246, sem transformar soma trianual em KPI anual.
- **Controle negativo:** uma eventual seleção de data clínica não pode ser tratada silenciosamente como competência. O caso não homologa rotas D2/C2; documentar a seleção aplicada ou declarar cenário não testado.
- **PASS do objeto:** 36 pontos numericamente iguais ao E1, sem duplicação por RES/SERV, competência correta e status de qualquer filtro registrado.

### P2.2 — LT mensal observado

- **Cenário positivo:** 36 competências 201701–201912, com três quantidades mensais derivadas da fato de capacidade. Se houver seleção de competência única, apresentar **somente o snapshot desse mês**.
- **Oráculo:** agrupar E4 por competencia e somar QT_EXIST/QT_SUS/QT_NSUS dentro de cada mês; comparar mensalmente às medidas factuais. Os totais históricos 337.147/270.076/67.071 ao somar linhas de todos os meses são **checksums administrativos**, jamais capacidade anual/trianual de apresentação.
- **Controle negativo:** não converter ausência de linha no recorte selecionado em zero; não preencher série histórica artificial; um valor observado zero permanece descrito como registro zero observado, sem atestar ausência real de leito.
- **PASS do objeto:** resultados por competência coincidem com E4, e rótulos/expressões não somam snapshots temporalmente para apresentar capacidade anual. Nenhum aceite científico T25/T26.

### P3.1 — fluxo RES→SERV

- **Cenário positivo:** matriz 2018 por códigos RES_COD_DATASUS_6 e SERV_COD_DATASUS_6, com soma de QTD_INTERNACAO por par; conferir linhas selecionadas e total correspondente contra E1 no mesmo recorte temporal. Não inferir nomes de municípios externos sem referência.
- **Controles históricos delimitados:** 2018, RES=250180 / SERV=250750: 3.806 novas internações (C3-B1); 2018, RES=250750 / SERV=250750: 39.060 (C3-B2). Esses resultados são provas locais históricas restritas, não reexecuções nem demonstração da matriz global. Confrontar a linha correspondente E1 na futura validação.
- **Controle negativo:** nenhuma POP/LT é numerador ou denominador deste visual; eventuais linhas não alcançáveis de outras fatos no grafo não são prova de POP/LT zero. A simultaneidade RES+SERV é válida como **recorte do fluxo SIH**, sem generalizar o contrato global de Link Key ou a matriz de filtros P5.
- **PASS do objeto:** números por par no recorte especificado iguais ao E1, preservando os dois papéis e sem fan-out/cross-fact; nulos/externos explicitamente qualificados.

## 6. Riscos e controles prévios

| Risco material | Como este gate deve limitar |
| --- | --- |
| Soma duplicada por múltiplos extratos SIH | **Nunca carregar E1, E2 ou E3 como segunda fato com QTD_INTERNACAO.** E1 é somente oráculo fora do modelo A0 de consumo |
| Associatividade indevida | Usar aliases e Link Table existentes; documentar quais seleções estavam aplicadas; comparar resultado com oráculo externo |
| Agrupar LT como estoque de três anos | Proibir soma de snapshots entre competências como medida de capacidade de período |
| Achar que qualquer ausência LT é zero | Registrar INDISPONIVEL_SEM_LINHA quando aplicável; não transformar em 0 |
| Conflito RES/SERV ou ano/competência | Nomear papéis e cenário; **não** afirmar que C2_FULL/D2/P5 globais estão aprovados |
| Refazer trabalho encerrado | Reutilizar AE01, F5, VII, C3 e C4; não repetir T24–T26, VI-P4 nem C2-J/K |

## 7. Critérios de avaliação futura, bloqueios e STOP

**Gate físico proposto e NÃO AUTORIZADO:** no máximo **uma tentativa delimitada** após (a) autorização expressa para desenvolver/versionar eventual executor; (b) revisão dos scripts e identidade branch@SHA; (c) autorização expressa distinta de **execução física** no Windows com escopo, artefatos, host e destino de evidência definidos. A aprovação deste Markdown **não satisfaz** nenhuma dessas permissões.

**PASS_RESTRICTED futuro:** três objetos reconciliados no recorte, oráculos mensais/territoriais correspondentes, seleção/filtros evidenciados, schema e papéis coerentes, ausência de duplicação, integridade 22 QVD/3 QVW/crosswalk pré/pós, log nativo/manifesto com commit e SHA dos scripts. Não promover PASS a aceite de indicadores, visual final, Link Key global, Fase IX ou produção.

**BLOCKED_INPUT / INCONCLUSIVE:** E1/E4 ou QVDs locais não acessíveis, hash/conteúdo divergente, contrato de ambiente/filtros incerto, ausência de log ou objeto não reproduzível. Registrar a evidência exata faltante; não inventar resultado.

**HARD_STOP:** qualquer tentativa de alteração QVD/QVW canônico, scripts não versionados usados para sustentar PASS, acesso sem autorização, mudança de RN21/V2/Link Key/modelo, múltiplos testes automáticos fora do contrato ou divergência de hashes. Preservar evidências e interromper sem retry.

**Parada desta preparação:** somente Markdown em branch Draft e handoff; status final desta etapa DOCUMENTATION_PREPARED_ONLY, sem COM/GUI/STORE/execução.

## 8. Dependências externas e handoff

- **G1 / Issue #157** continua OPEN_UNRESOLVED e **independente** para T25/T26; os três objetos descritivos **não** calculam T24, T25 ou T26. A validação A0 restrita não substitui G1, G2–G5, nem autoriza G6.
- **C2_FULL, P5/D2, LINK_KEY_CONTRACT e MEASURES_AND_DENOMINATOR_CONTRACT** permanecem não aprovados globalmente. As validações unitárias não resolverão automaticamente estes contratos.
- **P2.1** (grade completa de ausência/zero/positivo) e os outros 11 visuais não pertencem a este gate.
- **Próxima decisão separada:** revisar/aceitar este contrato documental e, somente se desejado, autorizar em novo escopo o desenvolvimento **versionado** de executor/oráculo para estes três visuais. A execução física permanece especificamente NÃO AUTORIZADA até nova decisão explícita.
