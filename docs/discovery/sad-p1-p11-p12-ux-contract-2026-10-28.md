# SAD — Contrato documental de apresentação e UX de P1.1/P1.2

**Gate:** `SAD-P1-P11-P12-UX-CONTRACT-01`  
**Data:** 28/10/2026  
**Modalidade:** READ-ONLY / DOCUMENTAL; sem QlikView/COM/reload/STORE e sem alterações de Git  
**Repositório:** `pedrogles/sad-sus-pb-data-mart`  
**Baseline inspecionada:** `main@fba0fe1c1521731b6eb59a9e943ceb16365ff1d9` (igual à baseline fornecida no gate anterior; 0 commits de diferença)  
**PR aberto:** #167 (Draft P2.3 R1, sem pertencimento à main)  
**Agente:** ChatGPT + GitHub; **modelo:** GPT-6; **esforço efetivo:** não exposto pela sessão, Medium não confirmável.  
**Estado:** `PASS_DOCUMENTAL_UX_CONTRACT_READY`; especificação candidata, **não** `VISUAL_ACCEPTED`.

## 1. Escopo e evidências reutilizadas

**Objetivo único:** estabelecer um contrato de apresentação para P1.1 (KPIs anuais) e P1.2 (série mensal 2017–2019), com estados temporais, filtros, rótulos, critérios de prova futura e STOP, sem criar gráficos ou executores.

**Fatos documentados:** `FATO_INTERNACAO.QTD_INTERNACAO` conta uma nova internação administrativa por registro RD válido com `IDENT=1`; `IDENT=5` é continuidade e conta zero na medida de internação. AE01 E1 fornece `qtd_internacao` agregado por `competencia × ano × municipio_res × municipio_serv`. Os controles históricos são:

| Ano | `qtd_registro_aih` | `qtd_continuidade` | `qtd_internacao` |
| --- | ---: | ---: | ---: |
| 2017 | 187.726 | 4.194 | 183.532 |
| 2018 | 187.293 | 3.982 | 183.311 |
| 2019 | 191.653 | 3.407 | 188.246 |
| **Total 2017–2019** | **566.672** | **11.583** | **555.089** |

O A0 R1 já reconciliou P1.2 em **36/36 competências** e controles anuais, dentro do escopo restrito; nenhuma reexecução. E1 não é o schema físico da fato. O painel técnico versionado contém os aliases `PERIODO_ANO`, `PERIODO_COMPETENCIA` da `DIM_TEMPO` e a medida `QTD_INTERNACAO` na fato; não inferir associação global homologada. Proveniência: [aceite dos 14 visuais](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/sad-analytical-scope-acceptance-01-2026-10-27.md), [decisão A0](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/project/analytical-consumption-architecture-approval-2026-10-27.md), [Fase V](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-5-fato-internacao-implementation-2026-10-15.md), [PR #164](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/164).

**Invariantes:** QlikView 12; três fatos; oito dimensões; Star por fato/constelação; Boundary 7; RN21/V2; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

## 2. Matriz de especificação visual candidata

| Propriedade | P1.1 | P1.2 |
| --- | --- | --- |
| Objeto proposto | Três cartões KPI por ano + um cartão separado **Total do triênio** (não intitular o último como KPI *anual*) | Gráfico de linha com 36 pontos (histórico completo) |
| Título | **Internações novas registradas no SIH/SUS — ano de competência** | **Evolução mensal de internações novas — competências 2017–2019** |
| Medida semântica | `Sum(QTD_INTERNACAO)` na fato / `sum(qtd_internacao)` no E1, por ano | Mesma soma, por competência administrativa |
| Grão do registro original | Um registro administrativo RD | Um registro administrativo RD |
| Grão visual | Ano `2017`, `2018`, `2019`; cartão de total explicitamente agregado 2017–2019 | Uma competência por ponto (`AAAAMM`), ordenada cronologicamente |
| Fonte de reconciliação | E1, Fase V e auditoria A0 R1 | E1 e A0 R1 36/36 |
| Filtros comprovados no oráculo | Ano/competência; outros apenas quando coexistentes e compatíveis | Ano/competência; outros apenas quando coexistentes e compatíveis |
| Apresentação | Inteiros sem casas decimais, separador de milhar `pt-BR`; rótulo do período sempre explícito | Y = quantidade inteira de novas internações; X = mês/ano, em ordem cronológica; tooltip com `AAAAMM` e contagem exata; sem suavização/interpolação |
| Limitações | Não confundir total trienal com indicador anual, pacientes únicos ou demanda reprimida | Competência administrativa ≠ data de internação `DT_INTER`; ponto isolado não é tendência; lacuna não deve virar zero inventado |

**Decisão de UX proposta:** P1.1 permanece baseado em cartões, conforme o candidato aprovado; P1.2 usa linha, pois a comparação de 36 competências é temporal. Não anexar I06/I07 (óbitos, dias, valores) aos cartões sem gate próprio. As expressões acima são **semânticas**, não expressão Qlik de produção homologada.

## 3. Contrato de contexto e navegação — sem alterar C2

Há duas superfícies de apresentação distintas: **histórico completo P1.2** (36 pontos, sem modo temporal guiado aplicado) e **modos guiados C2**, cuja definição já existente é `MENSAL=1 competência`, `ANUAL=1 ano` e `EVOLUCAO=12 competências de um ano`. O histórico de 36 meses **não deve ser renomeado** como o modo global `EVOLUCAO`, pois isso alteraria o contrato C2.

| Contexto desejado | Estado temporal esperado | Apresentação proposta |
| --- | --- | --- |
| **Histórico 2017–2019**, sem seleção temporal aplicada | Referência fixa declarada 2017–2019; ausência de seleções temporais conflitantes | P1.1 com 3 cartões anuais + total trienal; P1.2 com 36 pontos. Esta superfície é candidata e sua segurança sob filtros deve ser validada futuramente. |
| **ANUAL / ano escolhido** | Um `PERIODO_ANO`, sem `PERIODO_COMPETENCIA` explicitamente selecionada | P1.1 com **um** KPI anual do ano aplicado. Não exibir triênio como se fosse anual. P1.2 não é objeto principal neste modo. |
| **EVOLUCAO / ano escolhido** | Um `PERIODO_ANO`, sem competência explícita | P1.2 com os **12 meses** do ano aplicado; eventual referência P1.1 deve deixar claro o ano. |
| **MENSAL / ano e mês** | Um `PERIODO_COMPETENCIA` coerente com o ano escolhido | Apresentar valor da competência e rótulo `Mês/AAAA`; não denominar ponto único de "evolução". |
| Período contraditório, ambíguo ou sem cobertura adequada | Proposta diferente do estado aplicado, seleção residual incompatível ou recorte não reconciliado | Exibir estado **pendente/incompatível/indisponível** e motivo; não exibir número antigo como se a alteração estivesse aplicada. |

**Conservadorismo temporal:** a POC C2-J demonstrou um caso de seleção `201801`; C2-K demonstrou apenas a transição `201801→ANUAL/2019` e alternância `EVOLUCAO/2019`. Não estender esses resultados a todos os anos, caminhos de seleção, bookmarks ou menus. Diferenciar claramente **proposta de seleção** e **seleção realmente aplicada**. Evitar ações em cascata de limpeza/seleção não comprovadas.

## 4. Filtros, mensagens e acessibilidade

- **Filtro do próprio visual comprovado:** apenas tempo/competência no escopo da prova E1/A0 R1. O E1 possui colunas `municipio_res` e `municipio_serv`, porém filtros associativos globais em `FATO_INTERNACAO.qvd`/Link Key/aliases e interações com outros fatos **não** estão aceitos. Não oferecê-los como homologados por este contrato.
- O usuário deve perceber quais filtros/seleções **reais** estão ativos. Variáveis de proposta não podem ser apresentadas como estado aplicado. Se houver filtro incompatível, não ignorá-lo silenciosamente.
- P1.1 e P1.2 são contagens administrativas de produção; a matriz de P5 §62.6 é contrato dos indicadores RES/LEI/REL/FLU e não homologa automaticamente filtros destes visuais. Se o painel compartilhar superfície/navegação com os indicadores, respeitar avisos, indisponibilidades e guardas aplicáveis sem declarar `P5_D2_UI` aprovado.
- Rótulo metodológico sempre visível: **“Internações novas contabilizadas por competência administrativa SIH/RD; continuidades (`IDENT=5`) excluídas. Não representam pacientes únicos nem demanda reprimida.”**
- Casos sem valores, seleção temporal ambígua ou filtros incompatíveis devem apresentar aviso textual (não zero por ausência). Unidade sempre explícita. Não usar cor como único codificador de estado.

## 5. Critérios objetivos para gate físico futuro — NÃO executados

1. **P1.1:** quatro valores iniciais exatos: `183.532`, `183.311`, `188.246`, `555.089`; o último rotulado **Total do triênio**. Em contexto `ANUAL/2018`, valor anual `183.311` sem competência residual selecionada.
2. **P1.2 histórico:** exatamente 36 competências distintas e ordenadas de `201701` a `201912`; a soma por ano = `183.532/183.311/188.246` e total de pontos = `555.089`; conferir oráculo inteiro já existente sem reexecutar o gate A0.
3. **P1.2 por ano:** `EVOLUCAO/2019` mostra 12 competências de 2019; sem mês explicitamente selecionado. Conferir cada ponto contra oráculo já arquivado.
4. **P1.2 mensal:** `MENSAL/201801` apresenta uma competência e não a denomina tendência. A proposta Ano/Mês deve corresponder ao estado real selecionado.
5. **Estados:** ano/competência contraditórios, filtro incompatível, ano/competência ausente e ausência de dado são visivelmente distinguíveis; nenhum total/valor stale é apresentado como válido.
6. **Seleções:** uma mudança de período não deixa mês residual incompatível; atestar somente transições que forem efetivamente observadas. `C2_FULL` e `P5_D2_UI` continuam não aprovados globalmente.
7. **Integridade/proveniência:** em futura cópia QVW TEMP autorizada, evidência de origem e de hashes dos 22 QVDs/3 QVWs, captura dos objetos + leitura do estado real + comparação com oráculos; nenhum QVD/QVW canônico escrito ou reload sem autorização própria.

**Controles auxiliares do histórico E1, não substitutos da série integral:** máximo `201905=17.292`; mínimo `201702=13.586`. Não são metas ou medidas novas.

## 6. Parecer e STOP

**Veredito:** `PASS_DOCUMENTAL_UX_CONTRACT_READY` — contrato descritivo proposto e verificável, com decisões de composição, rotulagem, modos, limites de interação e critérios de aceite físico futuro. **Grau de evidência:** inspeção documental e estática, reuso de PASS restrito AE01/A0 R1/C2-J/K; **sem validação de UI ou cálculo real dos objetos P1.1/P1.2** nesta execução.

**Pendências de implementação:** fechar expressões físicas de cada objeto (inclusive a preservação do escopo anual em cartões e os efeitos de seleções), apresentar estado atual real, demonstrar 36/36 pontos e 12 meses por ano, testar resposta a filtros relevantes e revisar visualmente. Não pressupor que `Sum(QTD_INTERNACAO)` resulte correto em toda seleção com Link Key ainda não homologada.

**Handoff recomendado:** autorização específica para **versionar este contrato em PR documental isolado**, sem merge automático, se o responsável quiser persisti-lo no repositório; depois, quando houver gate físico próprio autorizado, uma PoC pequena em QVW descartável para P1.1/P1.2. Nenhum teste/implementação/PR/merge foi iniciado aqui.

**Status preservados:** `VISUAL_ACCEPTED=False`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`; Boundary 7, QlikView 12, três fatos e oito dimensões intactos.