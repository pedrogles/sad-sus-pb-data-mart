# M2 — Revisão visual read-only dos três painéis candidatos

**Data:** 07/11/2026. **Origem:** três capturas reais do QlikView x64 Personal Edition enviadas pelo responsável nesta conversa. **QVW aberto:** cópia de inspeção `SAD_MVP_THREE_SHEETS_CANDIDATE_INSPECAO.qvw`, gerada a partir do candidato M2 `SAD_M2_MVP_TEMP_956d51860bf244f5ac2c9ea36b493f20`; não houve recarga/salvamento reportado durante a inspeção.

**Vinculação:** PR #226 Draft, último build M2 no commit `5443db3c139d87ad8f834125f2002ec091e98238`, stdout `M2_NATIVE_CANDIDATE=3_SHEETS_9_OBJECTS_BUILT_PENDING_GUI_AND_FILTER_VALIDATION`, `PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED=True`. **Nível de prova:** screenshot revisada visualmente + stdout operacional local anterior; os bytes do QVW e o log Qlik nativo não foram inspecionados diretamente pelo agente. **Sem merge, sem promoção IX/produção.**

## 1. Evidências de captura

| Folha | Anexo de conversa, sem binário no Git | Resolução | SHA-256 dos bytes recebidos |
|---|---|---|---|
| Produção Hospitalar | `image(20261107-143827).png` | 1670 × 1040 | `F9F7158097418B008A63672627EF27F3C3A394082ABF7E2AD818D64C01614F08` |
| Leitos Cadastrais Observados | `image(20261107-143839).png` | 1670 × 1041 | `44037D554D498F8F5AABD62C0955BC55457085495B5D5CB645ABCADA7D7B6C13` |
| Fluxos e Contexto Territorial | `image(20261107-143852).png` | 1670 × 1041 | `13CED62356C2194F28B3CDE4D9B6B267525BAC426DE0A885796E00AC3E2787A0` |

**FATO VERIFICADO NAS IMAGENS:** a cópia de inspeção abriu no QlikView 12 (janela de título visível); as três abas e os nove objetos planejados existem e estão renderizados. Não há sobreposição estrutural evidente que impeça leitura. Os gráficos possuem preenchimento, linhas e tabelas. Capturas não permitem inferir propriedades internas ou validade dos estados de seleção.

## 2. Matriz de inspeção visual por objeto

| Objeto | Evidência verificável na imagem | Status estrito | Ação necessária |
|---|---|---|---|
| **M1-01** Internações anuais | Três barras 2017/2018/2019 com alturas coerentes com a soma já reconciliada; eixo e títulos visíveis | `RENDERED_CANDIDATE` | Substituir título interno literal `Sum(QTD_INTERNACAO)` por legenda/medida legível; testar seleção anual |
| **M1-02** Série mensal | Linha contínua nas 36 competências, eixo inferior com rótulos em duas linhas e denso | `RENDERED_CANDIDATE` | Melhorar frequência/rotação de rótulos; não confundir com série guiada anual de 12 competências |
| **M1-03** Ranking SERV | Barras verticais por códigos de municípios; eixo X superlotado/ilegível | `READABILITY_BLOCKED` | Barras horizontais, Top N e ordenação/validação P1.3, sem ocultar universo sem aviso |
| **M2-01** Snapshots | Duas linhas SUS/existentes visíveis por 36 competências, com rótulos densos | `RENDERED_CANDIDATE` | Título de snapshot, rótulos e não somar meses |
| **M2-02** Leitos SUS municipais 201912 | Barras verticais de códigos de serviço; eixo X não permite leitura, expressão interna truncada | `READABILITY_BLOCKED` | Ranking horizontal e limites Top N; preservar competência única explícita; zero vs ausência |
| **M2-03** Observabilidade | Três barras qualitativamente compatíveis com valores de 4.467 ausências, 3.464 positivos e 97 zeros observados, conforme stdout | `RENDERED_LABELS_BLOCKED` | Substituir códigos técnicos longos por “Sem linha LT”, “SUS observado positivo”, “SUS observado zero”; declarar que zero não comprova cobertura hospitalar |
| **M3-01** RES=SERV vs RES≠SERV | Uma única barra, sem categoria legível, perto de 555.089; comparação em duas classes **não demonstrada** | `FUNCTIONAL_BLOCKED` | Diagnosticar dimensão calculada `=If(...RES_COD_DATASUS_6...SERV_COD_DATASUS_6...)`; revisar classificação por observação FI elegível, preservando papel RES/SERV sem remodelagem silenciosa |
| **M3-02** Matriz de pares | Tabela de códigos RES e SERV e contagem; total aparente de 555.089, plausível como contagem de triênio | `RENDERED_ASSOCIATION_PENDING` | Validar pares/direção e externos com oráculo P3.1/P3.3, rótulos e ordenação |
| **M3-03** População | Tabela por código municipal×ano; **cabeçalho total `12.040.181`**, igual a 4.025.558 + 3.996.496 + 4.018.127 | `SEMANTIC_PRESENTATION_BLOCKED` | **Suprimir total entre anos**; preservar população ano×município e assegurar que filtros de FI/LT não recortem POP silenciosamente |

**Referência quantitativa independente já existente para M3-01:** [P3.2 closeout numérico de 29/10](../discovery/sad-p32-res-serv-equality-annual-closeout-2026-10-29.md) encontrou **294.635** internações com RES=SERV e **260.454** com RES≠SERV, total 555.089. Esse oráculo **não** equivale ao gráfico correto: exige paridade no QlikView. A captura atual, com uma só barra, **não comprova** essas duas classes. Causa exata é hipótese até investigação das propriedades e do grão da dimensão; não afirmar que a expressão já foi diagnosticada fisicamente.

**Nota de interpretação:** o total `12.040.181` na tabela POP é uma soma aritmética de populações de **anos diferentes** e não tem interpretação como população de um único período. Ainda não foi verificado se o Qlik permite ocultar o total pelo controle nativo do objeto, nem se existe acoplamento inadequado com FI/LT sob seleções.

## 3. Decisão de gate e próxima menor ação

- `M2_NATIVE_BUILD=PASS_LOCAL_REPORTED_CANDIDATE_ONLY` e `M2_GUI_RENDER=CONFIRMED_BY_THREE_SCREENSHOTS`.
- `M2_GUI_FUNCTIONAL_ACCEPTANCE=BLOCKED` **especificamente por M3-01 e M3-03**. Ranking SERV/municipal e observabilidade têm bloqueios de legibilidade para entrega final; os demais objetos são candidatos visuais ainda sem validação de filtros.
- `M2_QVW_REOPEN_ON_COPY=SUPPORTED_BY_SCREENSHOT`, não significa auditoria de todos os objetos/cálculos após reabertura.
- `C2/C3/C4/P5/LINK_KEY_CONTRACT/IX/PRODUCTION=NOT_APPROVED`; a `main` e os contratos acadêmicos não mudaram.
- **STOP:** não repetir `Build-SadMvpThreeSheetsTemp.ps1` nem recarregar dados para confirmar screenshots. Primeiro corrigir a causa da classificação RES/SERV e o agregado indevido de POP **no menor escopo de implementação TEMP**, com verificação em fonte de verdade e um protocolo de teste, sem modificar `PAINEL/PAINEL.qvw` ou scripts canônicos de fatos.
- **Sequência após correção aprovada:** (1) conferir as **duas** classes M3-01 com o P3.2 (294.635 + 260.454), (2) conferir que tabela POP não exibe somatório de três anos e que município×ano está íntegro, (3) revisar legibilidade M1-03/M2-02/M2-03, (4) executar casos limitados de seleção C2/P5/RES/SERV/POP, (5) reavaliar telas. Nenhum PASS automático por desenho ou medição global anterior.

**Decisão pendente:** aprovar contrato técnico específico de correção da classificação sem criar associação inesperada entre fatos, antes de qualquer novo build/teste QVW. **Nenhum script/arquivo QVW foi alterado nesta revisão.**


## 4. Correção candidata M3-01/M3-03 — autorizada e versionada, não executada

**Autorização:** “certo, prossiga” (07/11), em resposta à recomendação explícita de corrigir M3-01 e eliminar total populacional, antes de novos testes de filtros. **Limite:** somente scripts de teste na branch Draft e próximo QVW TEMP em nova pasta privada, com proteção de QVD/QVW e sem merge/produção.

### M3-01 — decisão de implementação B1 delimitada

**Causa provável observada:** dimensão calculada `=If(RES_COD_DATASUS_6=SERV_COD_DATASUS_6,...)` sobre duas dimensões associativas de role-playing, com resultados avaliados no contexto de gráfico, não garantindo classificação pelo grão do SIH/RD. A única barra da captura é o bloqueio **verificado**; a causa exata ainda não é prova experimental independente.

**Remediação versionada:** `PAINEL/sad_mvp_m3_flow_classification.qvs`, em memória **e somente na QVW TEMP**. Este script:

1. Mapeia cada `%LINK_KEY` SIH elegível de `LINK_ANALISE` para `RES_EQ_SERV` ou `RES_NE_SERV`, comparando `%SK_MUNICIPIO_RESIDENCIA` com `%SK_MUNICIPIO_SERVICO` (não compara nomes/descritivos nem confunde RES e SERV).
2. Faz `LEFT JOIN (FATO_INTERNACAO)` por `SK_REGISTRO_INTERNACAO` exclusivo, lendo `FATO_INTERNACAO.qvd` **sem gravá-lo**. Adiciona exclusivamente `MVP_FI_RES_SERV_CLASS` à fato in-memory, preservando `%LINK_KEY` e as 16+1 tabelas aprovadas no modelo de TEMP. A projeção não altera contrato acadêmico ou materialização persistida.
3. Exige `NoOfRows(FI)=566672`, SK únicos `566672`, total elegível `555089`, `RES_EQ_SERV=294635`, `RES_NE_SERV=260454`, unmatched=0, sem rótulos adicionais e 17 tabelas no modelo temporário. Se divergência, `[MVP_FLOW] VERDICT=BLOCKED_FACT_GRAIN_OR_CLASSIFICATION` e STOP.
4. Troca somente a dimensão do objeto `M3-01` para `MVP_FI_RES_SERV_CLASS`, sem alterar sua expressão `Sum(QTD_INTERNACAO)`. O runner ainda confere via Qlik `Evaluate()` as duas somas, categorias=2 e unmatched=0, usando o [oráculo P3.2](../discovery/sad-p32-res-serv-equality-annual-closeout-2026-10-29.md) **sem reprocessar E1**.

### M3-03 — eliminar total indevido sem perder município×ano

O total de 12.040.181 é soma de 2017+2018+2019 e não população de um ano. A opção oficial do QlikView para tabelas simples é **No Totals**, configurada nas propriedades da expressão. O executor `tools/Build-SadMvpThreeSheetsTemp.ps1` agora usa a propriedade COM `Expressions.Item(1).Item(0).Data.ExpressionData.UsePartialSum=$false` **somente em M3-03**, após criar o objeto, seguida de readback com bloqueio se ainda estiver ativada. Não altera `Sum(POPULACAO_ESTIMADA)` no grão município×ano e preserva o total do objeto M3-02 (internações) que é legítimo.

**Referências:** [QlikView September 2026 — Straight Table, No Totals](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Straight_Table.htm); [Qlik Community — UsePartialSum na API COM](https://community.qlik.com/t5/QlikView/Change-the-Total-Mode-default-settng-by-SetProperties/td-p/153410).

### Teste físico único da correção (a executar no Windows)

- **Origem imutável:** QVW M1 `SAD_M1_INTEGRATED_TEMP.qvw` já validado, não cópia M2 ou inspeção. Produzir somente um novo QVW TEMP sob `EvidenceRoot` com GUID; preservar as pastas anteriores, incluindo a inspeção visual.
- **Preflight:** branch correta, `git status --short` limpo, parser PowerShell sem erro, commit `-ExpectedCommit` completo, três QVS/runner rastreados e sem alterações.
- **PASS candidato:** execução de `M3_01_RES_EQ_SERV=294635`, `M3_01_RES_NE_SERV=260454`, `M3_01_UNMATCHED_FI_RECORDS=0`, `M3_01_CATEGORIES=2`; `M3_03_TOTAL_MODE=NO_TOTALS_PERSISTED_IN_COM_CANDIDATE`; outras sete verificações antigas idênticas; nove objetos; integridade SHA dos 25 canônicos e origem M1; reabertura/renderização das duas correções **depois do build**, ainda não homologada.
- **BLOCKED:** divergência numérica, Qlik syntax/COM, alteração de fonte, quadro/população vazio, residual de soma populacional, classificação errada ou `$Syn`. STOP imediato sem iterar; preservar log.
- **Limites:** `M3_FIX_STATIC_VERSIONED=YES`; `M3_FIX_WINDOWS=NOT_RUN`; `B1_CROSS_FACT_FILTERS=NOT_APPROVED`; `MVP_USER_READY=False`; `C2/C3/C4/IX/PROD=NOT_APPROVED`. A estabilidade do chart sob seleção nativa é um gate posterior, não inferível dos checks básicos.


## 5. Tentativa M3 bloqueada no controle de log — 07/11/2026

**Execução local reportada pelo responsável:** branch `proposal/sad-mvp-rebaseline-2026-11-07`, `HEAD=e356bd162484c7aa5fbb65250a3510be6777f032`, worktree limpa e parser `Build-SadMvpThreeSheetsTemp.ps1` sem erros. Fonte M1 declarada com SHA-256 `F55FB113D5E03DB1E7A746F665277E5F84AD5BECBE25D6FD1C85DDED0C2BEC60`. QVS de fluxo com SHA-256 `D6D1BAFF2EA155F192E5C5593CAEF38EEB00A1DBA486E83B7C64E90F97B4ED44`. Pasta de saída isolada identificada por `SAD_M2_MVP_TEMP_62ee4aece2f247fdb5349677046496f2`.

**STOP observado:** `M2_FAILED_STAGE=RELOAD_P23_IN_TEMP`, `M2_FAILED_LINE=214`, `M2_VERDICT=BLOCKED_OR_INCONCLUSIVE P23 native reload PASS absent, BLOCKED emitted or association warning`. Os checks `M3_01_RES_EQ_SERV`, `M3_01_RES_NE_SERV` e `M3_03_TOTAL_MODE` **não foram executados**. Não houve novo `M2_CREATED`. Proteção: `PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED=True`.

**Diagnóstico estático do controle:** o `if` de `tools/Build-SadMvpThreeSheetsTemp.ps1` (linhas 208–214) interrompe se qualquer um ocorrer: ausência de PASS emitido da fase VII; ausência de PASS P23; ausência de PASS MVP_FLOW; presença de BLOCKED P23/MVP_FLOW; ou expressão de aviso `circular reference|loosely coupled|synthetic key` no log nativo. A mensagem agregada **não identifica qual condição foi atendida**. A ausência de um PASS também pode ser efeito de execução QVS interrompida antes de chegar ao marcador. Não atribuir causa ao novo JOIN, à ilha P23 ou à Link Table sem o log.

**Próxima operação apenas leitura, sem alterar scripts ou disparar Qlik:** inspecionar `SAD_MVP_THREE_SHEETS_CANDIDATE.qvw.log` na pasta M3 acima; extrair marcadores realmente emitidos (excluir instruções contendo `TRACE`), erros/avisos com contexto e últimas 35 linhas. Preservar arquivo, diretório de evidências e cópia de inspeção do M2 anterior. **Não reexecutar `Build-SadMvpThreeSheetsTemp.ps1` agora**. Após confirmar a causa pelo log, determinar se é correção de script, regra de modelo ou falso positivo do guarda; um novo ensaio físico dependerá dessa decisão. PR Draft; sem merge, C2/C3/C4, IX ou produção.


## 6. Diagnóstico confirmado pelo log nativo e correção QVS — 07/11/2026

**Evidência primária:** linhas finais do log QlikView Desktop local coladas na conversa pelo operador, com horário do log `2026-11-07 11:52:20–11:52:44`. A análise aqui baseia-se no **texto do log compartilhado**, não na inspeção independente dos bytes do arquivo Windows.

### Resultados verificados no log

- `[VII] VERDICT=PASS_SCRIPT_ASSOCIATIVE_CANDIDATE_ONLY`: 16 tabelas, 0 `$Syn`, 566.672 registros FI, 35.518 LT, 669 POP, Link 85.705.
- `[P23A1] VERDICT=PASS_SCRIPT_CANDIDATE_ONLY`: 17 tabelas, 0 `$Syn`, 8.028 células (4.467 ausências, 97 zeros SUS observados, 3.464 positivas).
- `[MVP_FLOW] ROWS=566672 UNIQUE=566672 EQ=294635 NE=260454 UNMATCHED=0 BAD=0 ALL=555089`. Esses valores correspondem **exatamente ao oráculo P3.2** já validado; o `LEFT JOIN` não elevou a contagem física observada de FI. **Não é um PASS final da rotina**, pois o `IF` e seu veredito terminal não concluíram.
- O log termina com `Erro: Erro na linha do script` na cláusula `IF ScriptErrorCount>0` seguida de `OR ...` em linhas distintas; aparece `Erro: Comando desconhecido` em `TRACE [MVP_FLOW] VERDICT=BLOCKED_FACT_GRAIN_OR_CLASSIFICATION`. Não há evidência de que o oráculo em si tenha falhado.

### Causa raiz e remediação pontual

**FATO verificado por log + código versionado:** o `IF` de `PAINEL/sad_mvp_m3_flow_classification.qvs` foi escrito com `IF` na primeira linha, `OR` nas seguintes e `THEN` somente ao final, em desconformidade com a gramática da instrução de controle QlikView. A [documentação oficial QlikView September 2026 — If..then..end if](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Scripting/ScriptControlStatements/If.htm) declara que a cláusula `if ... then` é encerrada por fim de linha ou `;` e não pode atravessar uma quebra de linha.

**Correção versionada no mesmo PR Draft:** consolidar toda a condição de cardinalidade/oráculos em **uma única linha `IF ... THEN`**; separar a verificação de `NoOfTables()=17` em um `IF ... THEN` independente e igualmente em linha única, com `TRACE` distinto `BLOCKED_ASSOCIATIVE_TABLE_COUNT`. Acrescentar `TRACE [MVP_FLOW] TABLES=...` para evidenciação. **Não modificar** mapa RES/SERV, `JOIN`, medidas, constantes do oráculo, QVD, QVW M1, runner COM de visualização, `LINK_ANALISE` ou regras acadêmicas.

**CLASSIFICAÇÃO:** `M3_P3_2_NUMERIC=PASS_LOCAL_REPORTED_PRE_IF`; `M3_QVS_CONTROL_FLOW_PRE_FIX=BLOCKED_PARSER`; `M3_QVS_PARSER_FIX=STATIC_VERSIONED_NOT_RUN`; `M3_OBJECTS_AND_POP_NO_TOTALS=NOT_TESTED`. Embora os números estejam corretos no log, o novo QVW não chegou a ser construído; o próximo PASS de build requer **nova execução em cópia TEMP**, não reutilização da pasta abortada.

**Limites e STOP:** uma tentativa corretiva **específica para essa falha demonstrada** pode ser realizada em Windows após `git pull --ff-only`, `git status --short` limpo, conferência do SHA e parser do PowerShell. Se houver falha posterior em `No Totals` ou nas propriedades COM, **interromper e inspecionar**, sem nova sequência automática. Proteger 22 QVDs, 3 QVWs canônicos e QVW M1 como na execução anterior. O PR #226 permanece Draft; `C2/C3/C4/P5/IX/PRODUCTION=NOT_APPROVED`.


## 7. Terceira tentativa: fluxo PASS, objeto M3-03 bloqueado em índice COM

**Execução física reportada pelo operador (07/11/2026):** `git status --short` vazio, `git pull --ff-only`, `HEAD=b9afb7252d73fefb2eac8f0114e036e8b9381c42`; runner criou QVW TEMP isolado `SAD_M2_MVP_TEMP_0b97b2f14b7d4060bd9b7f38044f1ea1\SAD_MVP_THREE_SHEETS_CANDIDATE.qvw` a partir do QVW M1 com SHA `F55FB113D5E03DB1E7A746F665277E5F84AD5BECBE25D6FD1C85DDED0C2BEC60`. O stdout foi fornecido diretamente; os bytes do log/QVW desta execução **não** foram lidos pelo agente.

**Resultados observados antes da falha:**
- `CHECK_RD_ALL=555089`.
- `CHECK_M3_01_RES_EQ_SERV=294635`, `CHECK_M3_01_RES_NE_SERV=260454`, `CHECK_M3_01_UNMATCHED_FI_RECORDS=0`, `CHECK_M3_01_CATEGORIES=2`. Resultado consistente com P3.2, sem prova visual das barras no QVW salvo.
- `CHECK_LT_201912=7140`, `CHECK_POP_2019=4018127`, `CHECK_P23_CELLS=8028`, `CHECK_P23_ABSENT=4467`, `CHECK_P23_ZERO_OBS=97`, `CHECK_P23_POSITIVE=3464`.
- `M2_CREATED` para **oito** objetos: M1-01..03, M2-01..03, M3-01, M3-02.
- `M2_FAILED_STAGE=CREATE_OBJECT_M3-03`, `M2_FAILED_LINE=153`, `M2_VERDICT=BLOCKED_OR_INCONCLUSIVE O valor não recai no intervalo esperado.`
- `PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED=True`.

**Diagnóstico:** no script do runner desse commit, a linha 153 usa `$cp.Expressions.Item(1).Item(0).Data.ExpressionData` para a primeira e única expressão da tabela M3-03. A implementação de referência de `CreateStraightTable/Expressions` no `APIGuide.qvw` documentada pela [Qlik Community](https://community.qlik.com/t5/QlikView/Qlikview-show-totals-for-dimensions-in-straight-table-activate/td-p/492133) usa `Item(0).Item(0)` para primeira expressão. **Hipótese técnica forte**: `Item(1)` acessa grupo inexistente e produz erro COM de índice fora do intervalo. A mensagem não identifica subexpressão exata dentro da cadeia, portanto a confirmação exige inspeção COM controlada.

**Correção e mitigação já versionadas:**
- `tools/Build-SadMvpThreeSheetsTemp.ps1`: as duas cadeias de acesso ao primeiro `ExpressionData` passam de `Expressions.Item(1).Item(0)` para `Expressions.Item(0).Item(0)`; nenhuma mudança em QVS/classificação/medidas, nem em QVW/QVD canônicos.
- `tools/Test-SadM3NoTotalsComProbe.ps1`: teste **isolado em QVW de uma linha sintética** criado em pasta externa de evidências, usando COM QlikView Desktop. Adiciona uma `StraightTable`, testa o acesso ao índice 0, configura `UsePartialSum=$false`, confere propriedade de volta e grava somente QVW sintético isolado. **Nenhum dataset SUS lido; nenhuma recarga do Data Mart**. O teste depende de execução física Windows; revisão estática não é PASS.
- Somente se `M3_COM_PROBE=PASS_SYNTHETIC_LOCAL_ONLY`, considerar novo build M3 em QVW TEMP, preservando as evidências das tentativas anteriores. Caso contrário, STOP e investigar COM; não iniciar outra cadeia de reload.

**Classificação de evidência:** `M3_FLOW_NUMERIC=PASS_LOCAL_REPORTED`, `M3_EIGHT_OBJECTS=CREATED_BUT_NOT_SAVED_AS_COMPLETED_MODEL`, `M3_POP_TOTAL=BLOCKED_COM_INDEX`; `NO_TOTALS_ZERO_BASE_FIX=STATIC_VERSIONED_ONLY`; `M3_COM_PROBE_WINDOWS=NOT_RUN`, `M3_FULL_BUILD=NOT_REPEATED`. `C2/C3/C4/IX/PRODUCTION=NOT_APPROVED`; PR #226 Draft; `main` intacta.


## 8. Gate COM No Totals isolado — PASS local reportado em 07/11/2026

**Evidência primária:** stdout integral do PowerShell/QlikView Desktop apresentado pelo responsável nesta conversa, após `git status --short` vazio, `git pull --ff-only` e parser PowerShell sem erros. Executado o `tools/Test-SadM3NoTotalsComProbe.ps1` versionado em `HEAD=e2b2a5647dffac558e2eec8d0139510356356d9b`.

| Sinal | Valor reportado |
|---|---|
| `SCRIPT_SHA256` | `96DA669D916562DB16603A82724F4510D4D319505D73A6A975A335B542E4FC07` |
| `DATASET` | `SYNTHETIC_ONE_ROW_NO_SUS_QVDS` |
| `M3_COM_EXPRESSION_INDEX` | `0` |
| `M3_COM_NO_TOTALS_PROPERTY_READBACK` | `False` |
| `M3_COM_PROBE` | `PASS_SYNTHETIC_LOCAL_ONLY` |
| Evidência local privada | `SAD_M3_TOTAL_COM_PROBE_73d410d12aa54f1492f68f52d9c7a736/M3_TOTAL_ONLY_SYNTHETIC.qvw` |

**Conclusão restrita:** o índice `Expressions.Item(0).Item(0)` e a atribuição/leitura `ExpressionData.UsePartialSum=$false` funcionaram **em uma tabela sintética com uma expressão**, no QlikView Desktop instalado. Nenhum QVD SUS e nenhum QVW canônico foram carregados ou gravados por esse probe. Não confundir `UsePartialSum=False` com a validação visual efetiva de `M3-03` no Data Mart completo, nem com isolamento de filtros POP.

**Decisão operacional:** `M3_COM_PROBE=PASS_LOCAL_OPERATOR_REPORTED_SYNTHETIC_ONLY`; encerrar o probe — **não repetir**. A correção do builder já está versionada, usando os mesmos acessos e sem alteração das fontes. Autorizar **uma** execução controlada do builder no QlikView 12, novamente a partir do QVW M1 imutável, para tentar produzir três folhas e nove objetos em novo diretório de evidência, exigindo especificamente `M3_03_TOTAL_MODE=NO_TOTALS_PERSISTED_IN_COM_CANDIDATE`, os dois oráculos de fluxo, nove `M2_CREATED`, e hashes protegidos intactos. Se falhar, STOP e usar o log da nova tentativa; se passar, STOP de recarga e inspeção GUI da terceira folha. `C2/C3/C4/P5/IX/PRODUCTION=NOT_APPROVED`, PR #226 permanece Draft; nenhuma alteração em `main`.


## 9. M3-03 COM readback aprovado; bloqueio de múltiplas saídas da função Chart

**Execução local reportada (07/11/2026):** operador executou no Windows QlikView 12 em `HEAD=e58a79353f026d602b7bd9da9e7965990271a11a`, worktree limpa e origem M1 inalterada (SHA-256 `F55FB113D5E03DB1E7A746F665277E5F84AD5BECBE25D6FD1C85DDED0C2BEC60`). Nova tentativa em pasta externa `SAD_M2_MVP_TEMP_73606530ff4f45e8b332a5a8349dc80d` somente; **nenhum** QVW canônico foi aberto para gravação.

**PASS numérico reportado:** RD=555.089; M3-01 `RES_EQ_SERV=294635`, `RES_NE_SERV=260454`, unmatched=0, categories=2; LT/201912=7.140; POP/2019=4.018.127; P23=8.028 com 4.467 ausentes, 97 zeros observados e 3.464 positivos. `PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED=True`.

**Falha exata reportada:** M2 criou oito objetos (`M1-01..03`, `M2-01..03`, `M3-01`, `M3-02`) e parou ao montar M3-03: `M2_FAILED_STAGE=CREATE_OBJECT_M3-03`, `M2_FAILED_LINE=254`, `Falha na invocação do método porque [System.String] não contém um método denominado 'GetProperties'`.

**Causa raiz de PowerShell identificada estaticamente, sustentada pelo estágio da falha:** a função `Chart` tinha `Write-Output 'M3_03_TOTAL_MODE=NO_TOTALS_PERSISTED_IN_COM_CANDIDATE'` **antes** de `return $o`, emitindo **dois valores no pipeline de saída** (texto + objeto COM). O chamador guardava essa emissão em `$chart=Chart ...` e tentava `$chart.GetProperties()` na linha 254. A mensagem mostrada é compatível com o PowerShell tentar o método no elemento `String`. O teste COM de uma linha sintética já tinha demonstrado `UsePartialSum=False`. Na execução integrada, chegar ao `Write-Output` de `Chart` implica que a verificação COM `$verify.UsePartialSum` não havia lançado erro; ainda não é **verificação visual, persistida em QVW concluído**, nem prova de filtros POP.

**Patch mínimo em `tools/Build-SadMvpThreeSheetsTemp.ps1`, apenas no PR Draft:** remover `Write-Output` de dentro de `Chart`; manter `return $o` como **única saída normal** da função; emitir o mesmo marcador `M3_03_TOTAL_MODE=NO_TOTALS_PERSISTED_IN_COM_CANDIDATE` **no loop chamador**, depois de criar/posicionar o objeto e de `M2_CREATED=M3-03`. Nenhum QVS, dado, oráculo, relação ou propriedade COM alterada. Revisão estática confirmou `Chart` sem `Write-Output` e exatamente um marcador no chamador; o patch ainda **não foi executado no Windows**.

**STOP e próximo gate:** não reutilizar o QVW incompleto dessa tentativa nem repetir probes sintéticos. Uma tentativa de build em **nova cópia TEMP de M1** é o máximo permitido por esta correção pontual; exigir os **nove** `M2_CREATED`, `M3_03_TOTAL_MODE`, `M2_VERDICT=BUILT_CANDIDATE_ONLY_NOT_HOMOLOGATED` e hash dos 25 canônicos + origem M1 preservados. No primeiro novo erro, interromper e inspecionar; não iniciar mais ciclos de reload por tentativa. Após sucesso, inspecionar somente a folha 3 no QVW de inspeção, sem Reload/Save, antes de qualquer promoção de C2/C3/C4/P5/IX/produção.


## 10. M3 corrigido: três folhas e nove objetos construídos — PASS restrito local

**Data:** 07/11/2026. **Fonte:** stdout completo fornecido pelo operador de uma execução Windows PowerShell/QlikView 12; **não** houve conferência independente de binário QVW, screenshots desta versão ou log nativo pelo agente. O operador confirmou `git status --short` sem alterações, `git pull --ff-only` e `HEAD=049663d19c87fc629e81ee6127868ccf1c9643e3`. O script versionado `tools/Build-SadMvpThreeSheetsTemp.ps1` foi executado uma vez em QVW TEMP externo, a partir do QVW M1 com SHA-256 `F55FB113D5E03DB1E7A746F665277E5F84AD5BECBE25D6FD1C85DDED0C2BEC60`, sem recarregar os canônicos.

**QVW TEMP final do ensaio:** diretório externo `SAD_M2_MVP_TEMP_0f6b3b19ce714295ba80e5c27856c08e`, arquivo `SAD_MVP_THREE_SHEETS_CANDIDATE.qvw`. Script de classificação M3 com `FLOW_QVS_SHA256=284CE442A0F5C4D28D976F4B89375DC930AD34B5CC1D73602083E820A81A3203`. Não versionar o QVW/log/CSV.

| Verificação do stdout | Resultado |
|---|---|
| `CHECK_RD_ALL` | 555089 |
| `CHECK_M3_01_RES_EQ_SERV` | 294635 |
| `CHECK_M3_01_RES_NE_SERV` | 260454 |
| `CHECK_M3_01_UNMATCHED_FI_RECORDS` | 0 |
| `CHECK_M3_01_CATEGORIES` | 2 |
| `CHECK_LT_201912` | 7140 |
| `CHECK_POP_2019` | 4018127 |
| `CHECK_P23_CELLS` | 8028 |
| `CHECK_P23_ABSENT` | 4467 |
| `CHECK_P23_ZERO_OBS` | 97 |
| `CHECK_P23_POSITIVE` | 3464 |
| `M2_SOURCE_SHEET_COUNT` | 1 |
| `M2_CREATED` | M1-01, M1-02, M1-03, M2-01, M2-02, M2-03, M3-01, M3-02, M3-03 (nove eventos) |
| `M3_03_TOTAL_MODE` | `NO_TOTALS_PERSISTED_IN_COM_CANDIDATE` |
| `M2_NATIVE_CANDIDATE` | `3_SHEETS_9_OBJECTS_BUILT_PENDING_GUI_AND_FILTER_VALIDATION` |
| `PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED` | `True` |
| `M2_VERDICT` | `BUILT_CANDIDATE_ONLY_NOT_HOMOLOGATED` |

**Gate concluído restritamente:** `M3_TEMP_BUILD=PASS_LOCAL_OPERATOR_REPORTED`; `M3_FLOW_ORACLES=PASS_LOCAL_OPERATOR_REPORTED`; `M3_POP_NO_TOTALS_COM_READBACK=PASS_LOCAL_OPERATOR_REPORTED`; `M2_THREE_SHEETS_NINE_NATIVE_OBJECTS=PASS_LOCAL_OPERATOR_REPORTED`; `PROTECTED_FILES=UNCHANGED_REPORTED`. A revisão estática da versão anterior já verificara que `Chart` não emite texto no pipeline de retorno COM; a execução confirmou que o nono objeto agora é criado e o QVW de teste recebe o veredito final.

**Limite epistêmico:** essa saída demonstra que o runner completou a montagem e `Save()` sem lançar erro e registrou verificação COM da propriedade de No Totals. **Não prova** que a cópia reabre com duas barras RES/SERV visualmente legíveis, que o rodapé de total POP está ausente, que a tabela municipal contém as células certas, nem que filtros nativos não produzam resultados sem contexto. Também não comprova C2/C3/C4/P5/IX, Link Key global ou produção.

### Próximo gate único — inspeção GUI read-only da folha 3

1. Encerrar o construtor M2/M3: **nenhuma nova recarga ou teste COM**.
2. Em `EvidenceRoot`, copiar `SAD_MVP_THREE_SHEETS_CANDIDATE.qvw` para `SAD_MVP_THREE_SHEETS_CANDIDATE_INSPECAO.qvw` dentro da mesma pasta, usando `Copy-Item` com guard `Test-Path` para não sobrescrever inspeção anterior. Preservar hash da fonte opcionalmente para controle read-only.
3. Abrir **somente a cópia de inspeção** no QlikView Desktop 12; não executar `Reload`, não salvar alterações e não abrir `PAINEL/PAINEL.qvw`.
4. Capturar **somente folha 3** (`Fluxos e Contexto Territorial`), com M3-01 exibindo duas barras `RES_EQ_SERV` e `RES_NE_SERV` e tabela M3-03 sem linha de total agregado, preservando municípios e anos. Eventuais totais legíveis devem corresponder apenas a contexto por ano/município.
5. Classificar `GUI_PASS_RESTRICTED` somente após screenshots da versão **corrigida**; se faltar barra, houver total trianual ou população afetada inadequadamente, `BLOCKED_VISUAL_OR_SEMANTIC`, STOP e análise sem reconstrução indiscriminada.

**Estado final após este registro:** `M3_GUI_VISUAL_REVIEW=PENDING`; `FILTERS_NATIVE_AND_ROLE_PLAYING=PENDING`; `MVP_USER_READY=NO`; `C2/C3/C4/P5/IX/PRODUCTION=NOT_APPROVED`. O PR #226 continua Draft, sem merge e sem modificação de `main` ou dados canônicos.
