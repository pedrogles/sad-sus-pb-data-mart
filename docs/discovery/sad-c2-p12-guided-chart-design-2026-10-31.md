# SAD C2 — Discovery READ-ONLY: gráfico guiado de evolução P1.2

**Gate:** `SAD-C2-P12-GUIDED-CHART-DESIGN-01`  
**Estado:** `DISCOVERY_READONLY_COMPLETE / DESIGN_CANDIDATE_READY / PHYSICAL_NOT_RUN / DECISION_PENDING`.  
**Baseline imutável de leitura:** `main@2d205d52ab96eca565e85a9db5cfde14d9d3025c`, após PRs #201 e #202 integrados.  
**Dependência observacional:** [PR #203 — Draft, NÃO integrado](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/203) e [Issue #196 — ainda aberta](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196).  
**Agente / ambiente:** ChatGPT GPT-6 com GitHub e consulta à ajuda pública QlikView; somente documentação e leitura, sem Windows, QlikView/COM, QVD/QVW, dados externos, automação ou mutação de gráficos.  
**Autorização:** responsável solicitou prosseguir para a Discovery recomendada; NÃO autoriza implementar um objeto, recarregar, mudar QVW canônico, alterar a modelagem, fazer merge ou aprovar produção.

## 1. Pergunta única, limite e STOP

**Objetivo:** especificar um **novo gráfico candidato, separado de CH02**, que apresente `201901..201912` para P1.2 quando o modo proposto for `EVOLUCAO` e o **ano real** selecionado for 2019, preservando sem alteração o histórico CH02 de 36 competências e seus quatro KPIs. Identificar condições, expressão candidata, riscos de associação e a menor prova física necessária.

**Fora de escopo:** implementação da visualização, alteração de CH02, testes de botões, revisões AE01/P1.2 36/36, reprocessamento do oráculo, geração de QVD/QVW, C2 completo, P5/D2 global, C3/C4, CNES/T25/T26, Fase IX ou limpeza de PR/branch.

O STOP desta Discovery é a **proposta documental delimitada com critérios de decisão e evidência**, mesmo que a prova física e contratos transversais continuem pendentes.

## 2. Fontes e hierarquia verificadas

1. [AGENTS.md](../../AGENTS.md) → [current-state na main](../project/current-state.md) → [requisitos acadêmicos](../academic/requirements.md), nessa ordem.
2. [Boundary 7](boundary-7-implementation-plan.md): painel usa dimensões/fatos QVD transformados; expressões oficiais em texto versionável antes de definitivá-las; etapas C2→C3→C4.
3. [Modelo técnico Fase VII](../../PAINEL/phase_vii_technical_model.qvs): `DIM_TEMPO_COMPETENCIA` expõe `PERIODO_COMPETENCIA`, `DIM_TEMPO_ANO` expõe `PERIODO_ANO`; modelo associativo candidato, não prova de associação física global aprovada. `PAINEL/painel_main.qvs` permanece esqueleto — o gráfico real está em **QVW TEMP local, não em QVS versionado**.
4. [Contrato UX P1.1/P1.2](sad-p1-p11-p12-ux-contract-2026-10-28.md), [closeout de 36 meses](sad-p11-p12-physical-closeout-2026-10-29.md), [desenho temporal C2](sad-c2-guided-dynamic-control-design-2026-10-30.md).
5. [Runbook e closeout de #203](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/test/sad-c2-p12-2019-chart-observation-20261031/docs/discovery/sad-c2-p12-2019-chart-observation-2026-10-31.md), [comentário com transcript e capturas revisadas](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6549685191).
6. **QlikView oficial (mecanismo geral, não prova do QVW):** [Set modifiers — Setembro/2026](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-modifiers.htm) e [Set analysis e expressões](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-analysis-expressions.htm); [GetSelectedCount](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/FieldFunctions/getselectedcount.htm). Modificadores substituem/adicionam seleção para a agregação de um campo; funções de seleção distinguem valores efetivamente selecionados de variáveis de proposta.

## 3. Fatos verificados versus hipóteses

| Tipo de evidência | Observação | Limite |
| --- | --- | --- |
| **FATO DOCUMENTAL** | CH02 histórico é gráfico de linha com dimensão `PERIODO_COMPETENCIA` (texto `AAAAMM`) e expressão observada `=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)`. | Expressão foi capturada anteriormente na GUI e reportada na documentação; não lida de binário nesta Discovery. |
| **FATO RECONCILIADO EM GATE ANTERIOR** | Histórico P1.2: 36 competências `201701..201912`; totais 2017=183.532, 2018=183.311, 2019=188.246, triênio=555.089. TSV histórico SHA-256 `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`. | Não reexecutar 36/36 nem publicar TSV no Git. |
| **EVIDÊNCIA VISUAL LOCAL DE #203** | Nova TEMP abriu **já com** `PERIODO_ANO=2019` selecionado (Qtd 1), `PERIODO_COMPETENCIA` sem seleção (Qtd 0), modo `EVOLUCAO`, serviço sem seleção. **Não houve novo clique em BU15**. CH02 continuou exibindo curva e rótulos cobrindo 2017–2019 e KPIs históricos. | Imagem não enumera formalmente todos os pontos; não confundir com export 36/36 neste estado. |
| **RELATO LOCAL DE VERIFY #203** | `PROTECTED_25_UNCHANGED=True`, `SOURCE_UNCHANGED=True`, `COPY_UNCHANGED=True`, exit 0; dois PNGs da transição ausentes justificadamente. | Hashes transcritos; nenhum JSON/QVW/QVD local lido independentemente pelo agente. |
| **HIPÓTESE H1 — principal** | O modificador fixo `PERIODO_ANO={2017,2018,2019}` do CH02 pode sobrepor a seleção 2019 para a agregação, mantendo histórico em vez do recorte guiado. | Mecanismo compatível com Qlik oficial e observação, mas **causa isolada não confirmada**. |
| **HIPÓTESE H2 — também relevante** | Propriedades de dimensão, seleção/estado alternativo ou ligações associativas podem interferir no conjunto de competências exibidas. | Estado alternativo/propriedades detalhadas e cardinalidades do QVW experimental **não inspecionadas** nesta Discovery. |
| **DECISÃO PENDENTE** | Autorizar um **novo objeto guiado** exclusivamente numa QVW TEMP e selecionar a expressão/condição após prova empírica. | A expressão abaixo é candidata, não decisão física nem homologação. |

**Consequência:** o histórico CH02 é **válido como gráfico histórico restrito**, e **não é** uma implementação homologada de `EVOLUCAO/2019`. O teste #203 é finalizado como bloqueio funcional; não repetir o BU15 nem testes que já atingiram STOP.

## 4. Alternativas e recomendação de desenho

| Alternativa | Ganho | Principal trade-off | Decisão desta Discovery |
| --- | --- | --- | --- |
| **A — novo gráfico guiado independente** | Preserva integralmente CH02/36 meses e evita misturar duas semânticas; torna resultado/UX verificável de forma isolada | Mais um objeto e necessidade de controlar visibilidade/estado | **RECOMENDADA COMO PROPOSTA — aprovação física pendente** |
| B — substituir expressão e reutilizar CH02 | Menos objetos | Regressão do histórico 36/36 já reconciliado, conflito de títulos e de intenção | **NÃO adotar** sem decisão material separada |
| C — novo gráfico com Set Analysis explicitamente dinâmico | Pode contornar associação incompleta, se comprovada | Pode mascarar seleção real, ignorar filtros e reintroduzir bypass de ano | **Fallback somente após diagnóstico**, não testar automaticamente |
| D — estados alternativos/novos campos | Isola estado/visuais | Introduz nova semântica e risco de drift da modelagem | **Fora de escopo / não autorizado** |

**Desenho candidato A (sem criar objeto neste gate):**

- **Superfícies distintas:** CH02 histórico continua com título `Evolução mensal de internações novas — 2017 a 2019`, 36 competências, mesma expressão e mesmos rótulos/avisos. O novo gráfico deve ter **novo ID atribuído pelo QlikView**, nunca reaproveitar CH02, com título condicionado ao ano *real* `Evolução mensal de internações novas — 2019` apenas enquanto o contexto válido for 2019.
- **Dimensão candidata:** campo existente `PERIODO_COMPETENCIA`, uma competência administrativa SIH/RD por ponto, ordenada pelo valor `AAAAMM` crescente. Nenhum campo derivado novo. `Mostrar todos os valores`, estados alternativos, limites de dimensão e supressão de zeros/nulos devem ser **inspecionados e registrados**, não assumidos; não mostrar competências excluídas como válidas.
- **Medida candidata A1 (expressão de estudo):**

~~~qlik
=Sum(QTD_INTERNACAO)
~~~

  Sem `{$<PERIODO_ANO={2017,2018,2019}>}`, sem `{1}`, sem seleção por variável embutida. A hipótese testada é que o *estado corrente real* restringe fatos e competência. **Importante:** o gráfico histórico precisou do modificador fixo para renderizar em outro ensaio; portanto A1 **pode resultar em vazio, 36 meses ou valores incorretos**. Não promover sem prova na QVW TEMP e oráculo. Se falhar, STOP e diagnosticar associação/estado em gate separado, não trocar para expressão B automaticamente.
- **Condição de exibição/cálculo candidata (não confirmada em propriedades QlikView):**

~~~qlik
=If(
  '$(vSAD_POC_Mode)'='EVOLUCAO'
  and GetSelectedCount(PERIODO_ANO)=1
  and GetSelectedCount(PERIODO_COMPETENCIA)=0
  and Only(PERIODO_ANO)=Num($(vSAD_POC_Year)),
  1,0)
~~~

  Verificar sintaxe real em QlikView 12, formato numérico/textual e localidade, separando **habilitação de exibição** de **Calculation Condition**; a condição não deve limpar, aplicar ou recuperar seleções. **P5 e D2 globais continuam pendentes**: a condição de cálculo protege apenas visualização já selecionada, não previne seleção conflitante por outra rota.
- **Estado indisponível:** se proposta ≠ ano real, ano ausente/múltiplo, competência residual, modo diferente ou filtro incompatível comprovado, apresentar indicador/aviso `Período não aplicado ou incompatível` em vez de série antiga ou número zero fabricado. Não transformar `Null`/ausência de ponto em zero por conveniência.
- **Série desejada:** `201901,201902,...,201912` com exatamente **12** linhas em ordem e valores do recorte 2019 do oráculo (mesmo grão/medida `QTD_INTERNACAO`); soma **188.246** apenas como controle secundário, mês testemunha `201905=17.292`. **Somente totais anuais não provam os 12 valores**.

**Observação de implementação futura:** a cópia #201 e a cópia #203 persistem `ANO REAL=2019` no documento. O próximo gate físico deve **observar primeiro o estado ao abrir**, não exigir `0→1` nem clicar BU15 novamente, pois a seleção já persistida é um pré-requisito válido **somente se a proveniência e demais filtros forem verificados**. Criar gráfico exclusivamente em **nova TEMP**, preservar originais/25 canônicos por hashes; salvar somente a nova TEMP depois de editar o objeto autorizado.

## 5. Menor gate físico posterior — proposto, NÃO AUTORIZADO por este documento

**ID sugerido:** `SAD-C2-P12-GUIDED-CHART-POC-01` (separado da Discovery e de #203).

**Preflight:** verificar `main@SHA` atual, especificação/PR desta Discovery, aprovação explícita da alternativa A; escolher uma **única QVW TEMP fonte** já inspecionada contendo o diagnóstico e a P1.2 histórica, checar hash/estado atual, QlikView 12, 22 QVDs+3 QVWs protegidos, checkout e origem. Não assumir que HEAD de branch posterior altera o hash do runner anterior. Não reusar `-Prepare/-Verify` do #203 em outro cenário com pins incompatíveis. Reaproveitar **mecanismo de proteção**, não reenviar tarefas antigas.

**Uma única mutação permitida em nova TEMP (somente se autorizada):** adicionar **um gráfico novo**, dimensão `PERIODO_COMPETENCIA`, medida candidata A1, condição candidata, título claro. **CH02/BU15, KPIs históricos, variáveis, seleções e QVS/QVD/QVW canônicos intocados**. Não mover/copiar objetos para o documento canônico.

**Inspeção/aceite:** registrar seleção real 2019/competência Qtd 0, condição avaliada, IDs e propriedades do novo gráfico, screenshot antes/depois, export da tabela subjacente e comparação linha a linha com **12 linhas 201901..201912** extraídas do oráculo TSV histórico com SHA pinado. Guardar TSV/PNG/manifestos/log fora do Git, hashes da fonte e 25 protegidos. Verificação de integridade + GUI/oráculo são provas distintas.

| Veredito futuro | Critério |
| --- | --- |
| `PASS_RESTRICTED_GUIDED_CHART_2019_12_OF_12` | novo gráfico com exatamente 12 competências distintas em ordem, 12 valores reconciliados 1:1, total 188246, rótulos e estado real coerentes, fonte+25 canônicos intactos, TEMP alterada somente pelo novo objeto, evidência completa |
| `BLOCKED_CHART_ASSOCIATION_OR_EXPRESSION` | 0 ou 36 competências, valores incorretos, filtro desconsiderado, expressão/calculation condition com erro; STOP sem patch automático |
| `INCONCLUSIVE_ORACLE_OR_GUI` | ausência de TSV, screenshot, propriedade ou comparação integral; não aprovar por contagem de pontos ou total |
| `HARD_STOP_INTEGRITY` | hash/proveniência divergente, QVW canônico escrito, alterações além do objeto ou ausência de autorização |
| `NOT_RUN` | somente documentação; não herdar PASS de #201/#203 |

**Condição de parada:** uma nova cópia, um gráfico novo, uma inspeção, uma exportação (se disponível), um Verify. Não executar automaticamente R2/R3, alternar para Set Analysis dinâmico, corrigir modelo, testar outros anos/filtros/D2/P5, iniciar C3/C4 ou Fase IX.

## 6. Decisões restantes e handoff

1. **Decisão de produto/UX:** aprovar ou rejeitar a alternativa A como **padrão experimental** e manter CH02 histórico separado. Sua adoção definitiva como visual de painel requer aceite físico e decisão de composição posterior.
2. **Gate físico independente:** após autorização, preparar protocolo/runner mínimo pinado para criar apenas o gráfico novo na TEMP; operador humano/Codex Local Windows executa. Não realizar quando fonte, oráculo, UI ou autorização faltarem.
3. **Contratos transversais:** cobertura de filtros P5/D2, associação Link Key, medidas/denominadores, C3/C4 e suficiência científica CNES/T25/T26 são gates próprios; nenhum deles foi resolvido por esta Discovery.
4. **Integridade acadêmica:** QlikView 12 obrigatório, três fatos/oito dimensões e workflow do Boundary 7 preservados. Os painéis finais ainda dependem da Fase IX formal.

**Veredito documental:** `DESIGN_CANDIDATE_READY_PENDING_APPROVAL`. **Não equivale** a `VISUAL_ACCEPTED` ou `PRODUCTION_APPROVED`.

**Estados finais:** `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
