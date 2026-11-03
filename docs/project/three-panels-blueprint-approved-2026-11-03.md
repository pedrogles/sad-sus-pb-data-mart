# SAD — Blueprint visual de três painéis QlikView 12

**Versão aprovada do layout:** `SAD-3-PANELS-BLUEPRINT-APPROVED-01 / v1.0`  
**Data:** 03/11/2026  
**Repositório de referência:** `pedrogles/sad-sus-pb-data-mart`  
**Baseline da `main` verificada:** `2cc197d5310f5fbd65585df9084346fcd4f402a0`  
**Natureza:** **layout visual aprovado pelo responsável em 03/11/2026**, para servir de referência de implementação futura. **Não é aprovação física, semântica adicional, Fase IX ou produção.**

## 1. Finalidade e limites

Definir a **composição visual candidata** dos três painéis requeridos pela disciplina usando objetos **documentados do QlikView 12**, consolidando os **14 visuais D1–D3** já aceitos documentalmente: P1 (5), P2 (5), P3 (4). A prévia é HTML/CSS para revisão visual, **não** implementação QlikView, nem imagem de uma QVW real. Nenhuma QVW/QVD/QVS foi criada, aberta ou alterada. A elaboração do blueprint não envolveu COM, PowerShell, recarga, teste físico, PoC ou alteração de QVW/QVD/QVS. Sua integração Git constitui apenas registro documental.

**Prévia visual aprovada:** [abrir HTML autocontido](three-panels-blueprint-preview-2026-11-03.html) (baixar e abrir em navegador; não é QVW). **Screenshots derivados não são versionados.**

**Fontes de verdade lidas:** `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → `docs/discovery/sad-analytical-scope-acceptance-01-2026-10-27.md` → `docs/discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md` → `PAINEL/phase_vii_technical_model.qvs` → `PAINEL/painel_main.qvs`; evidências restritas C2 em Issue #196 e PRs #201/#205/#208, sem reconciliação numérica repetida.

**Matriz de situação:** `N` número/oráculo, `F` fonte/campo/expressão Qlik física, `A` associação/seleção, `V` visual/UX. Ter evidência em N ou em um teste restrito de F/V não concede PASS global de A, V ou produção.

### Decisões de apresentação aprovadas (não implementação)

- Três **folhas/painéis** em um futuro QVW final: *Produção Hospitalar*, *Leitos Cadastrais Observados*, *Fluxos RES→SERV*. Esta organização preserva D1–D3; **nenhuma alteração da constelação**.
- Faixa superior comum com **contexto aplicado real** e **proposta temporal separada**, sem declarar que ambos são controlados atualmente; o sistema de seleção temporal ainda está bloqueado por `BLOCKED_ROUTE_COVERAGE`.
- Camada de acessibilidade: cores redundantes com rótulos; títulos com fonte, tempo e natureza da medida; avisos de indisponibilidade e observabilidade.
- Separar **histórico de 36 competências** de **EVOLUÇÃO guiada com 12 competências**, como o contrato P1.1/P1.2 exige; não trocar de modo apenas rebatizando gráfico ou substituindo sua dimensão silenciosamente.
- População/IBGE-SIDRA continua no modelo; **T24 e razões por 1.000 ficam fora dos 14 visuais centrais** por falta de contrato C3/C4 global. Há lacuna entre promessa acadêmica da análise populacional e visuais iniciais; isso exige deliberação futura, não exclusão implícita.

## 2. Objetos QlikView 12: funcionamento e decisão de uso

| Objeto nativo | Como funciona | Uso recomendado | Regra de segurança/limitação |
|---|---|---|---|
| **Text Object** | Exibe texto/expressão em uma folha | KPIs, títulos, avisos, rótulos metodológicos e contexto de proposta/aplicação | Expressões e valor em QVW real precisam de validação; aviso pós-seleção não substitui prevenção D2 |
| **Line Chart** | Dimensão no eixo X e expressão quantitativa no eixo Y | P1.2 e P2.1: evolução mensal | `PERIODO_COMPETENCIA`, competência administrativa e snapshot mensal; **não** somar estoques entre meses |
| **Bar Chart** | Compara grupos; permite ordenação por expressão | P1.3–P1.5, P2.2/P2.4, P3.2/P3.3 | Para rankings, preferir barras horizontais com códigos e valores; controlar seleção por clique no gráfico |
| **Straight Table** | Tabela com uma linha por combinação de dimensões e medidas, sem subtotais de pivot | P2.5 detalhe CNES×tipo×código; P3.4 externos | Não apresentar `—` como zero; validação de chaves, ordenação e exportação |
| **Pivot Table** | Cruza dimensões em linhas/colunas, pode expandir e mostrar subtotal | P2.3 município×competência, P3.1 RES×SERV | Usar recorte/rolagem, não renderizar 223×36 nem milhares de pares de uma vez; cores por expressão são uma **possibilidade documental**, não prova física da ilha P2.3 |
| **Input Box** | Lê/escreve valores de **variáveis**, não seleciona campos de dados por si só | Propostas `vSAD_POC_Mode/Year/Month` **se aprovadas** | Editor de variável ≠ aplicação ao campo real; validação pré-despacho necessária |
| **Button** | Executa ações, `Enable Condition` 0/1 desabilita/habilita | Aplicar proposta de ano/mês **somente após contrato C2** | BU15 positivo e BU16 guarda parcial; rotas alternativas ainda não controladas. Não usar ação Clear+Select em cadeia presumidamente atômica |
| **Current Selections Box** | Exibe seleções **reais** e campos selecionados | Transparência do estado aplicado na faixa superior | Pode também expor ações de mudança/limpeza conforme opções; não presumir superfície somente de leitura. Avaliar opções em C2 |
| **List Box / Multi Box** | Seleciona valores de um ou múltiplos campos | Filtros **não temporais** quando aprovados; possível exibição temporal com `Read Only` | `Read Only` da lista não é bloqueio universal de campo. Nomes/campos da QVW candidata e acessos externos precisam inventário |
| **Container Object** | Agrupa outros objetos numa mesma área | Alternativa a duas visões P1.2 na mesma folha, sem repetir gráficos lado a lado | Candidato de UX, não mecanismo de proteção temporal ou prova de alternância segura |

**Não recomendar como padrão neste escopo:** gauge para contagem absoluta sem meta; funil para fluxo RES→SERV (não representa processo sequencial); mapa geográfico ou extensão sem contrato de coordenadas/compatibilidade; pizza para rankings de dezenas/centenas de categorias. Um gráfico de pizza poderia compor P2.2, mas barras empilhadas são mais comparáveis e economizam espaço.

**Referências oficiais QlikView September 2026:**

- [Tipos de gráficos](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Chart_types.htm)
- [Objetos de folha](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/SheetObjects.htm)
- [Button — ações e condição de habilitação](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm)
- [Input Box](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Input_Box.htm)
- [Seleções atuais](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Current_Selections_Box.htm)
- [Tabela dinâmica — formatação por expressão](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Pivot_Table.htm)
- [Table/Chart Read Only/Calculation Condition](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Straight_Table.htm)

## 3. Matriz de rastreabilidade: proposta por objeto

**IDs Pn.n são os IDs analíticos aprovados, e não os Object IDs físicos `CHxx/TXxx/BUxx` da QVW futura.** Essa associação deve ser registrada durante implementação futura autorizada. Na prévia há objetos sem IDs Qlik porque nenhum foi criado no QlikView.

| Visual | Objeto QlikView proposto | Fonte e medida / papel | Evidência reutilizável | Falta para aceite físico |
|---|---|---|---|---|
| **P1.1** KPIs ano/triênio | 4 × Text Object | `FATO_INTERNACAO.QTD_INTERNACAO`; `PERIODO_ANO` | N e F/V **restritos**: 183.532, 183.311, 188.246; triênio 555.089 | V global e transição temporal C2; não confundir triênio com ano |
| **P1.2** histórico e guiado | Line Charts distintos; Container opcional | FI, `QTD_INTERNACAO` × `PERIODO_COMPETENCIA` | N 36/36 e guiado 12/12 em QVW TEMP; BU15 seleção 2019 restrita | Integração real, alternância e cobertura C2/D2; não repetir oráculos |
| **P1.3** ranking SERV | Bar Chart horizontal | FI; `SERV_COD_DATASUS_6` pelo papel SERV | N ranking 65 códigos, triênio; provas de fonte e aliases | A/V FI→Link→SERV, comparar ao oráculo P1.3 |
| **P1.4** PROC_REA | Bar Chart horizontal | FI `%SK_PROCEDIMENTO` → `COD_PROCEDIMENTO` | N ranking E2; valor de destaque 0310010039 = 55.157 | A/V, filtro específico PROC, títulos históricos SIGTAP não presumidos |
| **P1.5** DIAG_PRINC | Bar Chart horizontal | FI `%SK_DIAGNOSTICO` → `COD_DIAGNOSTICO` | N ranking E3; O800=28.747, O809=21.530 | A/V, não inferir prevalência, títulos CID históricos condicionados |
| **P2.1** snapshots mensais | Line Chart, 3 séries | FL; `QTD_LEITOS_EXISTENTES`, `QTD_LEITOS_SUS`, `QTD_LEITOS_NAO_SUS` | N 108/108 em oráculo mensal; campos em QVS | F/V em QVW e comportamento temporal; sem soma anual de estoque |
| **P2.2** composição | Bar Chart empilhado + textos | FL medidas acima; competência única | N 201912: 7.140 SUS, 1.925 não SUS, 9.065 existentes | F/V para composição e seleção de competência |
| **P2.3** observabilidade | Pivot Table com cor/status + filtros locais A1 | Ilha `P23_A1_ISLAND`, município×competência | N 8.028 células: 3.464 positivas / 97 zero com linha / 4.467 sem linha; F A1 R2 **restrita** | A/V da ilha, legenda/status e separação de seleção global; nenhuma linha ausente vira zero |
| **P2.4** ranking municipal SUS | Bar Chart horizontal | FL; SERV/localização × 201912 | N 95 municípios com linha; 7.140 SUS | A/V papel SERV e ordenação; 128 sem linha permanecem indisponíveis |
| **P2.5** detalhe leito | Straight Table | FL, CNES × tipo × código × 201912 | N 964 linhas, 56 pares tipo×código | A/V das SK e rótulos; códigos sem nome histórico T29 |
| **P3.1** matriz fluxo | Pivot Table | FI; `RES_COD_DATASUS_6` → `SERV_COD_DATASUS_6` | N 1.944 pares observados e 183.311 novas em 2018 | A/V papéis e direção do par; sem inventar células vazias como zero |
| **P3.2** RES=SERV vs ≠ | Bar Chart empilhado / Text Objects | FI, comparação no mesmo registro | N 294.635 iguais / 260.454 diferentes; 46,92% diferentes | Expressão/classificação física e filtros por papel |
| **P3.3** ranking pares distintos | Bar Chart horizontal | FI, par dirigido, RES≠SERV | N 3.108 pares distintos; top 10=55.353; destaque 251370→250750=12.176 | A/V, ordenação e filtro desigualdade |
| **P3.4** externos à referência C5.2 PB | Straight Table + Text Object | FI; `QTD_REGISTRO_AIH`, `QTD_INTERNACAO`, cobertura RES | N 5.202 registros, 5.067 novas, 135 continuidades | A/V da classe C5.2 vs campo RES_COBERTURA; sem POP municipal PB |

**Atenção aos campos:** `PAINEL/phase_vii_technical_model.qvs` é um **modelo técnico isolado**, não um painel final. Ele prova a presença de aliases e nomes no script, **não** a compatibilidade de todas as seleções na QVW de produção. `PAINEL/painel_main.qvs` permanece esqueleto de infraestrutura; nenhuma QVW final dos três painéis foi auditada/criada neste gate.

## 4. Controles e tratamento de seleção

1. **Fonte única de tempo lógico:** competência administrativa SIH/RD é o eixo principal; P2.1 é snapshot cadastral mensal; quando cruzamentos forem contratados, nunca assumir mesmo significado clínico.
2. **Proposta ≠ aplicado:** `Input Box` de variáveis mostra a proposta; `Current Selections Box` deve informar seleção real; `Text Objects` explicam incompatibilidade. Não simular botão como prova de aplicação.
3. **D2 preventivo:** `Enable Condition` desabilitar antes de `Select in Field` é candidato de uma rota; não resolve menu Seleções, busca, bookmarks, outras listas ou cliques em gráficos/tabelas. Na Issue #196 consta `BLOCKED_ROUTE_COVERAGE`.
4. **Seleções indiretas:** alguns gráficos/tabelas/listas nativos também permitem seleção; são **rotas** a inventariar na QVW candidata. Configurar `Read Only` em objetos de apresentação, se aprovado, é mitigação local, não universal.
5. **P5:** filtros cruzados RES/LEI/REL/FLU continuam regidos pela V2 §62.6 com classes C/R/I/B. Os 14 visuais **descritivos de fato única** não autorizam adicionar razões cruzadas ou menus globais que ignorem filtros silenciosamente.
6. **Contexto nulo/incompatível:** avisos com distinção entre período ambíguo, filtro incompatível, sem linha observada, medida não válida e denominador não aceito. Não exibir valor anterior como resposta à proposta atual.
7. **P2.3:** filtros `P23_MUNICIPIO_6` e `P23_COMPETENCIA` são ilhados; não sincronizar com `PERIODO_COMPETENCIA` ou SERV automaticamente.

## 5. Aceite e condições de implantação

**ACEITE DE LAYOUT CONCEDIDO PELO RESPONSÁVEL em 03/11/2026:** três folhas com P1 (5 visuais), P2 (5) e P3 (4), hierarquia de cartões/gráficos/tabelas, objetos nativos listados no §2 e composição descrita no §3. O HTML vinculado conserva exatamente a organização visual revisada. O aceite **não** valida valores novos, expressões, filtros, objetos físicos nem interações da interface.

**Critérios documentais conferidos:** 14/14 objetos analíticos mapeados; origem, medida e papel indicados; números apresentados com referências a oráculos documentados; série e células fictícias explicitamente marcadas como ilustrativas; distinção temporal, observabilidade e ressalvas históricas preservadas; dependências C2/C3/C4 qualificadas; população IBGE/SIDRA mantida como lacuna pendente, não excluída.

**Decisões que permanecem pendentes antes da implementação física:**

- Definir política D2 de acesso e controle das rotas temporais na **mesma QVW**, sob [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6606199115); veredito `BLOCKED_ROUTE_COVERAGE`.
- Aprovar C3 (associações e papéis RES/SERV) e C4 (medidas/denominadores) por evidência física adequada; P2.3 conserva ilha A1 e filtros locais. Não presumir Link Key global.
- Avaliar a forma final de alternar histórico 36 meses e EVOLUCAO guiada 12 meses e inventariar os Object IDs reais somente em gate físico autorizado.
- Decidir a presença e a abrangência de análises populacionais T24/IBGE-SIDRA com escopo acadêmico explícito, antes de tratar a proposta de Data Mart como coberta pelos três painéis.
- Homologar funcionalidade, filtros, mensagens e revisão visual no QlikView 12 — a aprovação do layout não substitui esses testes.

**Sequência obrigatória inalterada:** C2 → C3 → C4 → GO formal Fase IX → implementar/testar três painéis QlikView 12 → entrega acadêmica. Ver [caminho crítico existente](final-delivery-critical-path.md), sem duplicá-lo.

**STOP do gate documental:** versão de referência do layout aprovada e registrável; nenhuma QVW, QVD, QVS, dataset, runner, PoC, consulta COM, reload, teste Windows, aprovação científica, implementação da Fase IX ou decisão de produção decorre da integração deste documento. Permissões e status continuam: `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.
