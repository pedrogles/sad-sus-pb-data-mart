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
