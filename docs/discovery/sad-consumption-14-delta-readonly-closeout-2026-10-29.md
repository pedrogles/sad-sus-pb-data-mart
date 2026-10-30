# SAD — Auditoria incremental de consumo dos 14 visuais (closeout READ-ONLY)

**Gate:** `SAD-CONSUMPTION-14-DELTA-READONLY-01`  
**Resultado:** `DELTA_AUDIT_DOCUMENTED_READONLY` — **auditoria documental**, não homologação QlikView.  
**Base verificada:** `main@b11fea4f610144f83ba7f38fdfef23105f3c0da3` (29/10/2026).  
**Modo de execução:** ChatGPT GPT-6 + conector GitHub; inspeção estática de documentos e QVS versionados. **Sem** COM, Windows, QlikView, recarga, escrita em QVD/QVW/QVS, recálculo de dados, novos experimentos ou testes físicos. Esforço exato do modelo não exposto para verificação.  
**Persistência:** este relatório e atualização mínima do estado operacional são propostas documentais em branch/PR separado; até o merge, não fazem parte da `main`.  
**Autoridade:** autorização posterior do responsável para prosseguir com a persistência documental, após entrega da auditoria em chat; **não** constitui autorização de merge ou execução física do próximo gate.

## 1. Limites de decisão

Reusadas as decisões D1–D3: **14 visuais candidatos** (P1=5, P2=5, P3=4), I06/I07 opcionais e I12/T24 fora do núcleo inicial. **A0 é padrão documental** de consumo, com **A1 ilhada condicional apenas para P2.3**; A2 não autorizada. Preservados QlikView 12, 2017–2019, RN21/V2, arquitetura Star/constelação com três fatos e oito dimensões, e ordem física C2→C3→C4 do Boundary 7. Não reabrir A0×A1 nem recálculos já encerrados.

**Fontes lidas na ordem de governo:** [AGENTS](../../AGENTS.md), [current-state](../project/current-state.md), [requirements](../academic/requirements.md), [agent routing](../project/agent-model-routing.md), [auditoria de drift 29/10](sad-operational-documentation-drift-audit-2026-10-29.md). Depois: [aceite D1–D3](sad-analytical-scope-acceptance-01-2026-10-27.md), [matriz de fontes](sad-analytical-consumption-source-matrix-2026-10-27.md), [decisão A0/A1](../project/analytical-consumption-architecture-approval-2026-10-27.md), [P2.3 R2](sad-p23-a1-physical-gate-protocol-2026-10-28.md), [caminho crítico](../project/final-delivery-critical-path.md), [Boundary 7](boundary-7-implementation-plan.md), closeouts P1–P3 e QVS pertinentes.

**Fontes físicas de implementação conferidas estaticamente:** [FI](../../TRANSFORMACAO/transf_fato_internacao.qvs), [FL](../../TRANSFORMACAO/transf_fato_capacidade_leito.qvs), [modelo técnico VII](../../PAINEL/phase_vii_technical_model.qvs), [A1 P2.3](../../PAINEL/sad_p23_a1_island_physical_gate.qvs). E1–E4 são **extratos AE01 agregados/oráculos**; seus nomes de coluna não são automaticamente campos diretos das fatos QVD.

**Camadas de prova (não intercambiáveis):** N = número/agregação de fonte; F = campo, carga e expressão física Qlik; A = associação/papéis/seleção; V = renderização/UX. Campo identificado estaticamente ≠ prova F completa; screenshot/COM pontual ≠ aceite V global.

**Estados de linha:** `SUPPORTED_BY_EXISTING_EVIDENCE` significa contrato documental do recorte definido, **não** painel aceito; `CONDITIONAL` significa prova de consumo ainda necessária; `BLOCKED` seria falta objetiva que impede definir o consumo mínimo. A matriz usa somente os três estados do contrato.

## 2. Matriz única — 14/14

### P1: demanda SIH/RD

| Visual | Fonte/fato e medida | Grão visual | Filtros/papéis necessários | Evidência existente N/F/A/V | Lacuna residual | Estado | Próxima prova mínima |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **P1.1** — KPIs anuais | FI.`QTD_INTERNACAO`; oráculo E1.`qtd_internacao` | Ano administrativo; total trienal separado | `PERIODO_ANO`; não exige POP/LT | **N:** 183.532/183.311/188.246, total 555.089; **F/V:** PoC de 4 cartões restrita [closeout](sad-p11-p12-physical-closeout-2026-10-29.md); **A:** global pendente | Resposta a transição temporal guiada ainda não homologada; não adicionar I06/I07 automaticamente | `SUPPORTED_BY_EXISTING_EVIDENCE` | Somente cenário temporal ainda não comprovado, preservando 4 valores e contexto |
| **P1.2** — série mensal | FI.`QTD_INTERNACAO`; E1 | 36 competências `201701–201912`; histórico completo ≠ C2 EVOLUCAO de 12 meses | `PERIODO_COMPETENCIA` e ano administrativo | **N:** A0 R1 36/36, export final idêntico; **F/V:** linha renderizada em QVW TEMP, [closeout](sad-p11-p12-physical-closeout-2026-10-29.md); **A:** seleção global não homologada | Expressão do objeto baseada em estado `$` e fixação de anos ainda não provada sob seleções contraditórias | `SUPPORTED_BY_EXISTING_EVIDENCE` | Cenário de troca temporal e visibilidade do estado aplicado; não repetir 36/36 |
| **P1.3** — ranking SERV | FI.`QTD_INTERNACAO`; E1 | `municipio_serv` × período; 65 SERV no triênio | Somente papel SERV; RES opcional se comprovado | **N:** ranking fechado 555.089/65 códigos [P1.3](sad-p13-serv-ranking-readonly-closeout-2026-10-29.md); **F:** alias `SERV_COD_DATASUS_6` no VII; **A/V:** pendentes | Paridade de agregação pela rota física FI→Link→SERV, sem confundir residência | `CONDITIONAL` | Confronto de uma rota SERV e ranking com CSV P1.3 já fechado |
| **P1.4** — top procedimentos realizados | FI.`QTD_INTERNACAO`, `[%SK_PROCEDIMENTO]`→`COD_PROCEDIMENTO`; E2 | Código realizado `PROC_REA` × competência/ano | Código + tempo; E2 não autoriza filtro municipal | **N:** 1.249 códigos, 555.089, [P1.4](sad-p14-proc-ranking-readonly-closeout-2026-10-29.md); **F:** SK/código no VII; **A/V:** pendentes | Medida e dimensão exclusivas ainda sem confronto de ranking Qlik; nomes SIGTAP históricos não provados | `CONDITIONAL` | Confronto Qlik por códigos, sem nova auditoria E2 |
| **P1.5** — top diagnósticos | FI.`QTD_INTERNACAO`, `[%SK_DIAGNOSTICO]`→`COD_DIAGNOSTICO`; E3 | Código `DIAG_PRINC` × competência/ano | Código + tempo; E3 não autoriza filtro PROC/RES/SERV | **N:** 5.473 códigos, 555.089, [P1.5](sad-p15-diag-ranking-readonly-closeout-2026-10-29.md); **F:** SK/código no VII; **A/V:** pendentes | Agrupamento por dimensão CID física ainda não confrontado; não interpretar como prevalência | `CONDITIONAL` | Confronto Qlik por códigos CID contra oráculo arquivado |

### P2: CNES/LT cadastral observado

| Visual | Fonte/fato e medida | Grão visual | Filtros/papéis necessários | Evidência existente N/F/A/V | Lacuna residual | Estado | Próxima prova mínima |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **P2.1** — snapshots mensais | FL.`QTD_LEITOS_EXISTENTES`/`QTD_LEITOS_SUS`/`QTD_LEITOS_NAO_SUS`; E4 | Um snapshot por competência | `PERIODO_COMPETENCIA`; nunca soma anual de snapshots | **N:** 108/108 mensais por E4/oráculo, [P2.1](sad-p21-lt-monthly-readonly-closeout-2026-10-29.md); **F:** medidas no QVS; **A/V:** pendentes | Objeto temporal Qlik e estado de seleção não homologados | `SUPPORTED_BY_EXISTING_EVIDENCE` | Renderização pontual dos snapshots, sem recalcular os 108 valores |
| **P2.2** — composição SUS × não SUS | Mesmas medidas FL; E4 | Competência única explícita, referência `201912` | Competência; não precisa POP/RES | **N:** 7.140 SUS + 1.925 não SUS = 9.065 existentes, [P2.2](sad-p22-lt-composition-201912-readonly-closeout-2026-10-29.md); **F:** medidas; **A/V:** composição não testada | Propriedade/denominador visual e troca segura da competência ainda não verificados | `SUPPORTED_BY_EXISTING_EVIDENCE` | Um objeto de composição com as três medidas e período fixados |
| **P2.3** — grade de observabilidade | E4 + C5.2/C4-F; projeção `P23_A1_ISLAND` ilhada | 223 PB × 36 competências = 8.028 células | Filtros **locais** `P23_MUNICIPIO_6` e `P23_COMPETENCIA`; não sincronizar por presunção | **N:** 3.464 positivos / 97 zeros com linha / 4.467 ausentes [P2.3](sad-p23-lt-municipal-observability-readonly-closeout-2026-10-29.md); **F:** A1 R2 candidata, 8.028/8.028 readback [protocolo](sad-p23-a1-physical-gate-protocol-2026-10-28.md); **A/V:** três amostras e duas interações restritas | UX ampla e notas metodológicas; ausência de LT deve continuar NULL. R1 A0 `A0_NOT_VALIDATED` só para recorte P2.3 | `CONDITIONAL` | Inspeção focal da UI da ilha já existente, **sem** novo R2/VI-P4 |
| **P2.4** — ranking municipal SUS | FL.`QTD_LEITOS_SUS`; E4 | Município SERV/localização × competência `201912` | `SERV_COD_DATASUS_6` e competência única | **N:** 95 municípios com linha, 7.140 SUS, [P2.4](sad-p24-lt-municipal-ranking-201912-readonly-closeout-2026-10-29.md); **F:** papel SERV no VII; **A/V:** pendentes | Link→SERV e ranking Qlik sob competência única ainda não demonstrados | `CONDITIONAL` | Comparar ranking Qlik à evidência P2.4, preservar 128 sem linha como indisponíveis |
| **P2.5** — CNES × tipo × código | FL.`QTD_LEITOS_*` e `FATO_LT_CNES_ORIGEM`, `[%SK_TIPO_LEITO]`→`COD_TIPO_LEITO`/`COD_LEITO`; E4 | CNES × tipo × código em `201912` | Estabelecimento/CNES, códigos de leito e competência única | **N:** 964 linhas e 56 pares tipo×código [P2.5](sad-p25-lt-cnes-type-code-201912-readonly-closeout-2026-10-29.md); **F:** SK/códigos versionados; **A/V:** pendentes | Associação física e apresentação apenas por códigos; rótulos históricos T29 não aprovados | `CONDITIONAL` | Paridade por CNES/tipo/código na competência, mais ressalva visível |

### P3: fluxos RES→SERV em FI

| Visual | Fonte/fato e medida | Grão visual | Filtros/papéis necessários | Evidência existente N/F/A/V | Lacuna residual | Estado | Próxima prova mínima |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **P3.1** — matriz dirigida RES→SERV | FI.`QTD_INTERNACAO`; E1 | Par direcionado × ano/competência | `RES_COD_DATASUS_6` e `SERV_COD_DATASUS_6` | **N:** 1.944 pares observados de 2018, 183.311 novas, [P3.1](sad-p31-res-serv-matrix-2018-readonly-2026-10-29.md); **F:** dois papéis no VII; **A/V:** pendentes | Matriz física associada por ambos os papéis sem imputação de pares inexistentes | `CONDITIONAL` | Um confronto físico orientado com oráculo P3.1 já fechado |
| **P3.2** — RES=SERV versus RES≠SERV | FI.`QTD_INTERNACAO`; E1 | Classe de igualdade de códigos × ano | Comparação RES/SERV do mesmo registro; ano de competência | **N:** 294.635 iguais, 260.454 diferentes, [P3.2](sad-p32-res-serv-equality-annual-closeout-2026-10-29.md); **F:** campos dos papéis no VII, classe derivada ainda não validada como expressão Qlik; **A/V:** pendentes | Expressão física da igualdade e efeito de seleções por papel | `CONDITIONAL` | Classificação Qlik num recorte anual contra seis linhas arquivadas |
| **P3.3** — ranking pares RES≠SERV | FI.`QTD_INTERNACAO`; E1 | Par distinto dirigido agregado 2017–2019 | Excluir igualdade RES=SERV, manter direção e universo | **N:** 3.108 pares, Top 10=55.353, [P3.3](sad-p33-res-ne-serv-pair-ranking-closeout-2026-10-29.md); **F:** papéis disponíveis; **A/V:** pendentes | Condição de desigualdade e ranking Qlik não demonstrados | `CONDITIONAL` | Confronto de ranking físico com CSV P3.3, sem repetir E1 |
| **P3.4** — residentes externos à C5.2 PB | FI.`QTD_REGISTRO_AIH` e `QTD_INTERNACAO`; E1+C5.2 | Classe externa × ano | Papel RES, pertença à referência C5.2 PB; sem POP PB para externos | **N:** 5.202 AIH, 5.067 novas, 135 continuidades, [P3.4](sad-p34-external-residence-annual-closeout-2026-10-29.md); **F:** `RES_COBERTURA` no VII; **A/V:** pendentes | Equivalência do filtro físico de cobertura com classificação derivada C5.2 no Qlik | `CONDITIONAL` | Conferir classe externa e ambas medidas por ano, sem novo processamento E1 |

**Totais de classificação:** `SUPPORTED_BY_EXISTING_EVIDENCE=4` (P1.1, P1.2, P2.1, P2.2); `CONDITIONAL=10`; `BLOCKED=0` na **definição documental mínima**. Os dez condicionais não estão liberados para painel físico final. Não foram testados filtros novos nesta execução.

## 3. Interpretações técnicas que não podem se perder

1. **Aliases de versão:** A0 R1 denominado P2.2 (série LT) = **P2.1 atual**; P2.2 atual é composição distinta. A0 R1 P3.1 cobriu dois testemunhos, não a matriz integral; P3.1 numérico posterior ampliou o **oráculo E1**, não o aceite visual Qlik.
2. **Sem necessidade universal de integração entre fatos:** P1 e P3 utilizam FI; P2 utiliza FL/observabilidade; `FATO_POPULACAO` é preservada na arquitetura, mas não compõe numerador/denominador dos 14 candidatos centrais. Não impor filtros cross-fact aos visuais sem justificativa individual.
3. **Temporalidade:** competência administrativa SIH/RD ≠ `DT_INTER`; histórico P1.2 de 36 pontos ≠ modo guiado C2 `EVOLUCAO` de 12 pontos de um ano. Leitos e população são semi-aditivos no tempo.
4. **Observabilidade:** `ABSENT_NOT_ZERO_PROVEN` exige medidas NULL; `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` só vale com linha; disponibilidade operacional e zero real não foram comprovados. Zero de Qlik por seleção incompatível não equivale à ausência de linha CNES/LT.
5. **Descrições:** preferir códigos de municípios/procedimentos/CID/leitos onde rótulos históricos específicos não estiverem validados. Aviso T29 junto aos visuais de leitos, sobretudo por tipo e descrição.
6. **Prova graduada:** 146 reconciliações A0 R1 e passes P1–P3 não são `LINK_KEY_CONTRACT=APPROVED`, `P5_D2_UI=APPROVED` nem `VISUAL_ACCEPTED_GLOBAL`.

## 4. Até três bloqueios materiais para o avanço físico (não para a suficiência numérica)

| Problema | Visuais afetados | Evidência existente | Evidência faltante | Risco específico | Decisor | Critério de liberação |
| --- | --- | --- | --- | --- | --- | --- |
| **B1 — contrato temporal e UX aplicado** | P1.1/P1.2; P2.1/P2.2 quando houver troca de competência; P2.3 somente filtros próprios | PoC P1.1/P1.2, A0 R1, C2-J/K, P2.3 R2 | Comportamento real nas transições ainda não cobertas, estado aplicado/visível e prevenção de contexto incompatível | Exibir números corretos sob filtro/período errado; somar snapshots; confundir seleção global com ilha | Responsável funcional/UX e mantenedor | Cenários mínimos definidos em gate C2 separado; PASS físico restrito e autorização formal para ampliar |
| **B2 — rotas por papel RES/SERV** | P1.3, P2.4, P3.1–P3.4 | Papel duplicado em `DIM_MUNICIPIO` no VII; E1/E4, ranking e C3-B1/B2 restritos | Confrontos físicos de cada seleção/expressão por papel aplicável, inclusive classificação externa | Contar residência como serviço, quebrar pares dirigidos ou rotular externos incorretamente | Responsável técnico do modelo, com decisão do mantenedor se mudança semântica | Prova focada C3 e confronto aos oráculos já versionados; não exigir cross-fact por padrão |
| **B3 — associação de dimensões exclusivas** | P1.4/P1.5/P2.5 | SKs/códigos nos QVS e rankings de E2/E3/E4 já encerrados | Paridade dos rankings consumidos na FI/FL e respectivas dimensões | Chave/descrição/hierarquia gerar agregação incorreta, sobretudo SIGTAP/CID/T29 | Responsável técnico do modelo | Confronto físico por códigos no recorte e aceite das ressalvas, sem inventar descrições históricas |

Os bloqueios acima incidem na **ampliação do aceite físico/visual**. Não transformam os oráculos encerrados em resultados inválidos.

**Fronteiras preservadas**, não novas causas para reexecução: `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `ZERO_REAL_COMPROVADO=NOT_PROVEN`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) permanece **OPEN** apenas para suficiência científica T25/T26 e os respectivos indicadores condicionados.

## 5. Um único próximo gate — proposta, NÃO iniciado

**ID:** `SAD-C2-VISUAL-TEMPORAL-CONSUMPTION-01`  
**Objetivo delimitado:** demonstrar, **sem refazer os cálculos**, o consumo temporal fisicamente coerente de P1.1/P1.2 numa cópia QVW descartável, usando controles P2.1/P2.2 existentes somente onde a comparação temporal de snapshot for necessária. A ilha P2.3 permanece independente; sua R2 não será reexecutada.

**Ordem:** o próximo trabalho físico é **C2**; trabalhos de mapeamento documental C3/B2 e dimensões B3 podem ser preparados em paralelo, sem executar/homologar seus testes antes de suas dependências. C3 e C4 físicos seguem a sequência Boundary 7. A Issue #157/G1 pode continuar em trilha científica paralela, mas sem aprovar T25/T26 nem bloquear P1/P2/P3 descritivos.

**Pré-condições:** autorização **específica** de teste físico; Windows/QlikView 12 comprovados; script/runner previamente commitado se utilizado (reutilizar existentes antes de criar outro); commit e hashes dos insumos fixados; QVW temporário isolado; originais QVD/QVW protegidos por inventário SHA, evidência persistente fora do Git/TEMP; seleção de **poucos cenários não cobertos** por C2-J/K e PoC, com oráculos já disponíveis. Não executar QlikView por decorrência deste relatório.

**Critério `PASS_RESTRICTED`:** demonstrar estado real do período selecionado, incompatibilidade temporal impedida ou explicitamente classificada sem número enganoso, P1.1 anual e P1.2 histórico/evolução rotulados de forma distinta, valores comparados aos **oráculos já arquivados** (não reexecutar validadores numéricos), nenhuma mutação em protegidos, evidência de UI efetivamente examinada. Não converter sucesso restrito em C2 global ou Fase IX.

**Critério `BLOCKED`:** escolha temporal incompatível aplicável sem bloqueio, divergência verificável de valor, perda de integridade, ausência do ambiente/permissão, ou impossibilidade de leitura do estado aplicado. `INCONCLUSIVE` se as capturas/propriedades não sustentarem o comportamento; registrar o cenário e STOP, sem retry automático.

**Decisor de liberação física:** mantenedor/responsável, mediante autorização nova; execução por Codex Local/operador no Windows. ChatGPT+GitHub pode preparar contrato/read-only, não simular teste COM.

**STOP do próximo gate:** uma bateria mínima autorizada de seleção temporal e confronto com evidência existente; não iniciar C3/C4, criar novas provas R2/R3, dashboards definitivos, merge, Fase IX ou produção automaticamente.

## 6. Fechamento desta auditoria

- **Matriz:** P1.1–P3.4, **14/14**; campos, fontes, grãos, filtros/papéis, N/F/A/V, lacunas, estados e provas mínimas.
- **Priorização:** B1/B2/B3, **3/3**, sem novo teste de indicadores.
- **Handoff:** um único gate subsequente com PASS/BLOCKED/STOP e dependências.
- **Sem reexecução:** AE01, 146 A0 R1, P1.1–P3.4, VI-P4/C4-F, P2.3 A1 R2, Qlik/COM e qualquer QVD/QVW.
- **Resultado:** `DELTA_AUDIT_DOCUMENTED_READONLY` (somente conclusão documental). `VISUAL_ACCEPTED_GLOBAL=False` e `PRODUCTION_APPROVED=False`.

**Persistência documental não é aceite de implementação.** O fechamento permanece sujeito à revisão/integração deste PR; merges, execução física e mudanças estruturais requerem permissões próprias.
