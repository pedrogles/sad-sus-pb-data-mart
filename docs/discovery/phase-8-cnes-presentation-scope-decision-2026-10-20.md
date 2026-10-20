# Fase VIII — Decisão de escopo de apresentação CNES/LT observado (VIII-CNES-PRESENTATION-SCOPE)

**Data:** 20/10/2026  
**Base documental:** `main@e4fdba706a2e22420e9c52d3ea62280461291734`  
**Resultado da preparação documental (20/10/2026):** `PRESENTATION_SCOPE_DOCUMENTED_RESTRICTED`  
**Proveniência da publicação:** originalmente registrado somente em branch; revisão e eventual integração rastreadas no [PR #133](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/133). O estado vigente do merge deve ser consultado no GitHub, não inferido deste cabeçalho.  
**Natureza:** decisão **restrita de nomenclatura e escopo de apresentação experimental/acadêmica**, não homologação física, hospitalar, visual ou de produção.

## 1. Objetivo, autorização e fronteira

O responsável autorizou em 20/10/2026 **preparar em branch esta decisão documental** sobre a apresentação de T25 e T26 no universo observado CNES/LT, nos termos do gate `VIII-CNES-PRESENTATION-SCOPE`: preservar a semântica V2, registrar limites de cobertura e temporalidade, sem merge, execução física, alteração da modelagem acadêmica ou início de dashboards.

**Escopo tocável:** somente este arquivo Markdown novo, em branch exclusiva originada da `main`. A decisão não altera `AGENTS.md`, `current-state.md`, requisitos, Boundaries, `.qvs`, PowerShell, fatos/dimensões, `LINK_ANALISE`, QVDs ou QVWs. A eventual integração deste registro é uma aprovação separada.

**Fontes consultadas em ordem:** [AGENTS](../../AGENTS.md), [estado operacional](../project/current-state.md), [requisitos acadêmicos](../academic/requirements.md), [Boundary 7](boundary-7-implementation-plan.md), [V2 semântico](phase-6-semantic-v2-approved-2026-10-14.md), [C1 CNES/LT](phase-8-c1-cnes-coverage-readonly-2026-10-18.md), [piloto T25 — PR #113](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/113) e [piloto T26 — PR #114](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/114).

## 2. Decisão documental restrita

**APROVADO PARA DESCRIÇÃO EXPERIMENTAL RESTRITA:** utilizar nos materiais de análise, **somente para recortes efetivamente reconciliados**, o universo com identificação literal:

- `LT_TODOS_REGISTROS_VALIDOS_RN21` — **CNES/LT observado**, preservando todos os registros LT válidos, sem filtro hospitalar retroativo.
- **T25:** **“Leitos SUS por 1.000 habitantes — CNES/LT observado”**.
- **T26:** **“Internações processadas por leito SUS médio observado”**.

A palavra **observado** qualifica o universo de registros e não equivale a cobertura integral da oferta de leitos, cadastro hospitalar completo ou uso efetivo de leitos pelas internações. A finalidade do trabalho (“demanda e capacidade hospitalar”) não converte a fonte observada em universo hospitalar comprovado.

**NÃO APROVADO:** apresentar os resultados como “leitos hospitalares históricos comprovados”, “capacidade hospitalar integral da PB”, “taxa de ocupação hospitalar”, indicador estadual/2017–2019 integralmente homologado, ou como resultados do painel definitivo. A C1 mantém `C1_HOSPITAL_SCOPE=NO_GO_NOT_VERIFIED` e `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`. Não classificar retroativamente estabelecimentos por `TP_UNID` ou pelos rótulos datados de `201909`; não excluir LT válida nem fabricar zeros.

A presente autorização formaliza a **escolha documental do escopo experimental**; **não é aprovação pelo professor**, nem aceite científico da cobertura, de todos os recortes, da apresentação visual ou de produção.

## 3. Contratos que cada apresentação deve preservar

| Elemento | T25 — oferta observada | T26 — relação demanda/capacidade observada |
|---|---|---|
| Fonte de capacidade | `FATO_CAPACIDADE_LEITO` / CNES-LT observado | Mesma capacidade observada, em território e período compatíveis com SIH/RD |
| Numerador | Média dos totais mensais de `QTD_LEITOS_SUS` | Soma elegível de `QTD_INTERNACAO` por **município de serviço** |
| Denominador | `POPULACAO_ESTIMADA` anual do **município de serviço** | Média dos totais mensais de `QTD_LEITOS_SUS` no mesmo município/período; **não usar população** |
| Unidade | Leitos SUS médios observados por 1.000 habitantes de referência | Internações administrativas processadas por leito SUS médio observado; **não mede ocupação** |
| Ano completo | Exigir 12 competências válidas; média mensal = soma dos 12 totais / 12 | Mesma exigência de cobertura, com internações elegíveis do período / média mensal |
| Período parcial | Exibir competências e relação do total mensal/média do período com POP anual de referência, **sem anualização** | Internações do período / média da capacidade nos meses válidos selecionados, **sem anualização** |
| Território | Município de **serviço/localização** | Município de **serviço**, para numerador e capacidade; não confundir com residência |
| Ausência/zero | Linha LT ausente não representa zero; denominador POP deve ser válido/positivo | Sem capacidade observada válida/positiva no período: razão indisponível; ausência não é zero |

**Fórmulas anuais de referência no universo e recortes válidos:**

- `T25 = 1.000 × (soma dos 12 totais mensais QTD_LEITOS_SUS / 12) / POP_anual_serviço`.
- `T26 = internações SIH/RD elegíveis processadas no serviço no ano / (soma dos 12 totais mensais QTD_LEITOS_SUS / 12)`.

Para os períodos parciais, aplicar as definições V2 ao conjunto de competências efetivamente selecionadas e válidas. Sem seleção temporal inequívoca em KPI pontual, com múltiplos anos num único KPI anual, com filtro P5 incompatível, população ausente ou denominador não válido, apresentar **indisponibilidade com motivo**; não mascarar por zero ou filtrar silenciosamente. A política P5 `C/R/I/B` e o requisito D2 de prevenção de seleção conflitante permanecem **não homologados fisicamente**.

## 4. Evidência disponível e alcance comprovado

| Elemento | Evidência existente | Interpretação autorizada |
|---|---|---|
| CNES/LT C1 | João Pessoa `250750` e Campina Grande `250400`, 2018: 12/12 meses com linhas LT observadas, 24 componentes confrontados com F2 no piloto T25; cobertura hospitalar histórica `NÃO` | `C1_LT_OBSERVED_JP_CG_2018=GO_RESTRICTED_CANDIDATE_ONLY` |
| T25 — PR #113 Draft | 2 cenários anuais, 24 componentes mensais e 1 parcial de janeiro/2018 reconciliados no runner local reportado; JP soma de snapshots 28.106 / 12 e POP 800.323; CG soma 16.592 / 12 e POP 407.472 | `PASS_LOCAL_CANDIDATE_ONLY` apenas nesses recortes, sem tratar somas de snapshots como estoque anual |
| T26 — PR #114 Draft | 2 cenários anuais e 1 parcial reportados como reconciliados; internações elegíveis serviço JP 73.105 e CG 46.752 em 2018; no parcial JP/201801, 5.741 internações e 2.386 leitos SUS observados | `PASS_LOCAL_CANDIDATE_ONLY` apenas nesses recortes, sem denominar taxa de ocupação |
| ST↔LT, T29 | Pareamento por CNES×competência observado; classificação hospitalar histórica não demonstrada; legenda descritiva 201909 apenas datada | Não sustenta um recorte exclusivamente hospitalar 2017–2019 |

**Nível de prova:** os PASS físicos de T25/T26, seus componentes e as checagens SHA de 22 QVDs/QVWs são **execuções locais Windows/QlikView 12 reportadas pelo responsável e documentadas nas branches Draft**. CSVs detalhados, logs nativos integrais e QVWs temporários **não foram auditados independentemente neste gate**. O F3 é controle derivado de F1/F2, não uma segunda fonte completamente independente. Nenhum teste foi repetido.

A C1 registra ainda lacunas de município×competência sem linha LT e observações de `QT_SUS=0` com linha: não estender o aceite experimental dos dois municípios a todos os municípios/competências. A existência de 36 arquivos mensais LT não comprova cobertura integral por recorte.

## 5. Textos e avisos obrigatórios em eventual apresentação

**Identificação mínima junto ao resultado:** fonte “SIH/SUS RD, CNES/LT observado e, quando usado, IBGE/SIDRA”; município de **serviço**; ano ou competências; natureza de snapshot mensal e denominador; universo `LT_TODOS_REGISTROS_VALIDOS_RN21`; condição `cobertura/classificação hospitalar histórica não verificada`; nível `ensaio reconciliado local restrito`. Para T26, acrescentar **“não é taxa de ocupação hospitalar”**.

**Nota metodológica de cobertura, visível junto a T25/T26 (texto de apresentação proposto, não nova regra de negócio):**

> “CNES/LT observado: valores reconciliados somente para os municípios e competências indicados. A cobertura completa dos estabelecimentos hospitalares e sua classificação histórica em 2017–2019 não foram comprovadas. A ausência de linha LT não demonstra zero. Leitos são observações mensais; séries anuais utilizam média, não soma dos estoques.”

**Ressalva histórica de nomenclaturas de leito:** cumprir o adendo de apresentação **já aprovado no Boundary 7**, sem substituir seu texto canônico nem a exigência de visibilidade. A nota concisa aprovada nele é:

> “CNES/LT 2017–2019: descrições históricas não verificadas em 1.965/2.021 pares código×competência (97,2%). Nomes disponíveis apenas para set/2019; dados quantitativos por código mantidos. Fonte: CNES/LT e NT 32/2019. T29 histórico não aprovado.”

O percentual **97,2% refere-se a combinações distintas tipo×leito×competência da dimensão, não a percentual de leitos, registros, internações ou estabelecimentos**, e não deve ser reaplicado a subconjuntos filtrados como se fosse percentual local. Para visualizações por nomes, tipo/especialidade ou comparação temporal, respeitar o **aviso completo e legível** da seção “Adendo de apresentação” do Boundary 7, em folha/gráfico e captura/exportação. Não preencher descrições `NULL` nos QVDs nem transportar rótulos de setembro/2019 a outros meses.

**Este arquivo especifica apenas o texto e critérios futuros; não cria gráficos, capturas, elementos de interface nem aprovação visual.**

## 6. Condições de aceite e STOP

**PASS documental restrito da etapa original de preparação** quando: (1) terminologias T25/T26 e universo observado ficam explícitos; (2) fórmulas, papéis territoriais, temporalidade e ausência/zero seguem V2; (3) C1 `GO_RESTRICTED` e `NO_GO_HOSPITAL` não são promovidos; (4) avisos de cobertura e T29 são preservados; (5) evidências são qualificadas como locais reportadas; (6) a alteração no Git é exclusivamente este Markdown em branch isolada. **STOP da preparação original** após commit e conferência do diff. Naquela etapa, não executar gates físicos, criar PR/merge, alterar código, atualizar estado de produção ou iniciar Fase IX. A abertura posterior do PR #133 e sua eventual integração são ações separadas, rastreáveis no GitHub.

**Pendências preservadas:**

- `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `C1_HOSPITAL_SCOPE=NO_GO_NOT_VERIFIED`.
- `T29_HISTORICAL=NOT_APPROVED` e `PRESENTATION_CNES_HISTORICAL_CAVEAT=REQUIRED_NOT_IMPLEMENTED`.
- `T25_GENERAL=NOT_APPROVED`; `T26_GENERAL=NOT_APPROVED`.
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`.
- `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`.
- `PRODUCTION_APPROVED=False`; `PHASE_IX=NOT_AUTHORIZED`.

**Handoff definido ao encerrar a preparação original:** revisão e eventual integração **documental** específica; depois gates separados para associações/medidas/filtros e aceite visual, seguindo a ordem aprovada no Boundary 7, antes de qualquer dashboard definitivo.

## 7. Roteamento e evidências desta execução

- **Agente/ambiente:** ChatGPT GPT-6 + conector GitHub; nível de esforço não verificável nesta integração. Sem acesso assumido ao Windows, QlikView COM ou GUI.
- **Permissões da preparação original:** leitura do repositório e escrita **apenas deste Markdown em branch dedicada**. Sem PR ou merge naquela etapa; sem execução física, alterações de dados ou limpeza.
- **Evidência versionada:** link do arquivo e commit no GitHub. `RUNTIME_TEMP` e `EVIDENCE_ROOT`: não aplicáveis.
- **PASS:** commit contém só o documento; `main` não modificada; decisão limitada.
- **BLOCKED/INCONCLUSIVE:** documento/branch conflitante, base divergente ou ausência de fonte obrigatória — parar sem contornar.
- **STOP da preparação original:** confirmar commit, diff e integridade de escopo; aguardar nova autorização.
