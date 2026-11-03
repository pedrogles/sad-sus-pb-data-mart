# SAD — B2 | Discovery do redesenho físico do contrato temporal

**Gate:** `SAD-C2-TEMPORAL-PHYSICAL-REDESIGN-DISCOVERY-01`  
**Data:** 03/11/2026  
**Baseline revalidada:** `main@59dc80a4db24f8ada257e9354e464f3393bfcab6`  
**Autorização do responsável:** **somente Discovery B2**; sem aprovação de nova arquitetura, sem implementação, sem alteração semântica V2, sem merge e sem liberação da Fase IX.  
**Resultado:** `DISCOVERY_B2=PASS_DOCUMENTAL_WITH_BLOCKERS`; `SINGLE_TEMPORAL_AUTHORITY_IMPLEMENTABILITY=NOT_DEMONSTRATED`; `C2_FULL=NO_GO_NOT_APPROVED`.

## 1. Objetivo e fronteira

**Objetivo delimitado:** projetar e comparar candidatos de **uma autoridade de seleção temporal** que conservem o significado de `PERIODO_ANO` e `PERIODO_COMPETENCIA`, sem multiplicar população, snapshots de leitos ou registros SIH/RD e sem permitir descartar intenção de seleção incompatível antes da validação D2. Produzir **análise de impacto**, critérios falsificáveis e decisão de viabilidade; não executar experimentos.

**Escopo tocável:** apenas este Markdown, em uma branch/PR Draft de objetivo único.  
**Intocáveis:** QVS/QVW/QVD, `LINK_ANALISE`, `%LINK_KEY`, 22 QVDs e três QVWs canônicos, dados, contratos D1–D8/P1–P5, 3 fatos/8 dimensões, modelagem acadêmica entregue, 14 visuais aprovados no PR #209.  
**Fontes na ordem canônica:** `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → [Boundary 6](boundary-6-qlikview-physical-architecture.md) → [Boundary 7](boundary-7-implementation-plan.md) → [V2 §62](phase-6-semantic-v2-approved-2026-10-14.md) → [proposta C2-G](phase-8-c2g-temporal-selection-design-decision-2026-10-21.md) → [controle dinâmico](sad-c2-guided-dynamic-control-design-2026-10-30.md) → [modelo técnico real versionado](../../PAINEL/phase_vii_technical_model.qvs) → [blueprint aprovado](../project/three-panels-blueprint-approved-2026-11-03.md) → [inventário restrito do PR #210](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6609988083) → [gate de viabilidade encerrado](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6610288918).

**Qualidade de evidência:** os campos e LOADs a seguir são fatos **verificados estaticamente na `main`**; o modelo físico é uma QVW experimental isolada e seus contadores são asserções dos scripts/evidências de gate restrito, **não** auditoria binária nova. As capturas QlikView 12.0.20000.0 e stdout PowerShell são evidências visuais e locais reportadas; não se inferem propriedades não mostradas.

## 2. Modelo existente: inventário e dependências obrigatórias

### 2.1 Campos observados em script

O [`PAINEL/phase_vii_technical_model.qvs`](../../PAINEL/phase_vii_technical_model.qvs), que é **modelo técnico de teste** e não painel definitivo, contém:

| Papel | Tabela/carregamento no script | Campo físico observado | Uso |
|---|---|---|---|
| Ponte associativa | `LINK_ANALISE` carregada do QVD `__LINK__` | `%LINK_KEY`, `%SK_TEMPO_COMPETENCIA`, `%SK_TEMPO_ANO`, SKs RES/SERV/estabelecimento | Uma chave da fato para a ponte |
| Competência | `DIM_TEMPO_COMPETENCIA` de `DIM_TEMPO.qvd` | `%SK_TEMPO_COMPETENCIA`, `TEMPO_COMPETENCIA AS PERIODO_COMPETENCIA` | Referência SIH/RD e CNES/LT |
| Ano | `DIM_TEMPO_ANO` de `DIM_TEMPO.qvd` | `%SK_TEMPO_ANO`, `TEMPO_ANO AS PERIODO_ANO` | Referência SIH/RD/CNES e POP anual |
| Datas clínicas | `DIM_TEMPO_INTERNACAO` / `DIM_TEMPO_SAIDA` | `%SK_TEMPO_INTERNACAO` / `%SK_TEMPO_SAIDA` | Papéis exclusivos SIH/RD, **não** eixos administrativos intercambiáveis |
| População | `FATO_POPULACAO` | `%LINK_KEY`, `POPULACAO_ESTIMADA` | Município×ano; competência e estabelecimento nulos na projeção da Link |
| Internação/capacidade | `FATO_INTERNACAO` / `FATO_CAPACIDADE_LEITO` | `%LINK_KEY` | Competência e ano derivados na `LINK_ANALISE` |

**Regra aprovada do Boundary 6/7:** `%SK_TEMPO_COMPETENCIA` é populada para SIH/RD e CNES/LT, e nula para POP; `%SK_TEMPO_ANO` é populada nos três processos. A população não deve ser fisicamente replicada por competência. A ponte concentra papel temporal e municipal; não criar segunda associação entre fatos nem synthetic keys/loops.

**Asserções já codificadas no piloto técnico:** `FATO_INTERNACAO` 566.672; `FATO_CAPACIDADE_LEITO` 35.518; `FATO_POPULACAO` 669; `LINK_ANALISE` 85.705; 16 tabelas (3 fatos + ponte + 12 aliases), sem `$Syn`. São **oráculos restritos daquele modelo técnico**, não metas universais aplicáveis sem qualificação a uma nova projeção/ponte.

### 2.2 Semântica temporal inalterável

[V2 §62.3](phase-6-semantic-v2-approved-2026-10-14.md) exige: prevenção de conflito **antes** da alteração das seleções; competências parciais explicitamente rotuladas; múltiplos meses não consecutivos corretamente identificados; dois ou mais anos apresentados em séries anuais independentes; vários anos em KPI pontual anual = indisponível; sem período em KPI pontual = indisponível. População e capacidade são semi-aditivas no tempo. [V2 §62.6](phase-6-semantic-v2-approved-2026-10-14.md) exige matriz `C/R/I/B` independente por indicador.

**Não reduzir D2** para “apenas clicar no botão” ou “se seleção ficar incompatível, esconder o número”. O segundo é um tratamento de apresentação necessário, porém insuficiente para prevenção de intenção descartada.

## 3. Comparação de arquiteturas B2 — SEM implementação

| Variante candidata | Mecanismo lógico proposto | Potencial benefício | Bloqueio/impacto | Decisão |
|---|---|---|---|---|
| **B2-A — Controle lógico apenas por variáveis** | Proposta/ano/mês em variáveis; botão `Select in Field` e validação prévia nos campos atuais; indicadores por contexto validado | Mantém modelo físico/Link atuais e preserva PoCs existentes | Menus/atalhos, buscas, bookmarks e cliques em objetos podem alterar os campos atuais sem o guarda do botão; ignorar seleções nas expressões pode violar P5. Não atende D2 global | `NOT_SUITABLE_AS_FULL_D2` |
| **B2-B — Um campo selecionável canônico com ponte temporal** | Hipótese de `CONTEXTO_TEMPORAL` único que representa contextos de ano/competência, associado à `LINK_ANALISE` por uma ponte/projeção, mantendo fatos e dimensões de origem | Pode reduzir dualidade selecionável e separar **seleção da UI** dos dois eixos físicos | Mudança **material** de projeção associativa; propagação aos fatos e POP anual precisa prova, não pode criar fan-out com contagem multiplicada. Usuário ainda pode multisselecionar tokens incompatíveis e usar comandos nativos. Não basta esconder campos antigos | `PREFERRED_ONLY_FOR_FURTHER_DESIGN_IF_OWNER_APPROVES_MODEL_DISCOVERY` |
| **B2-C — Documento/estado de seleção isolado por modo** | Superfícies ou estados distintos para histórico, anual e mensal | Pode simplificar semântica visual por modo | `Alternate States` **não** isola `Clear/Back/Forward` nativos; dividir QVW é mudança do blueprint aprovado; fatos e POP precisam reconciliar em cada superfície | `NOT_EVIDENCED_AS_GLOBAL_CONTROL` |
| **B2-D — Manter eixos e suspender C2** | Preservar modelo e documentação, sem despacho novo | Zero regressão, nenhuma alteração acadêmica | C2/D2 continua NO-GO; Fase IX não liberada | `SAFE_DEFAULT` |

**Limite comum:** nenhuma das variantes possui prova de interceptar previamente comandos nativos do QlikView Desktop `12.0.20000.0`. Uma “única variável de período” ou “um único campo” **não** é automaticamente uma **única autoridade de mutação**. A versão instalada e a documentação consultada de QlikView September 2026 não são a mesma build; características não inspecionadas localmente são `UNKNOWN`.

### 3.1 Falha estrutural de um seletor canônico ingênuo

Suponha tokens conceituais **apenas ilustrativos**, não campos aprovados: `Y:2019`, `M:201901`, `M:201801`.

- Um campo que permite **vários valores selecionados** admite `Y:2019` **e** `M:201801`, mantendo uma combinação contraditória se o usuário puder alcançá-la nativamente. O fato de haver um campo em vez de dois **não prova D2**.
- `Always One Selected Value` limita quantidade de valores do campo, mas descartaria necessidades legítimas de meses não consecutivos e séries multi-ano; a própria ajuda Qlik adverte alteração do modelo e incompatibilidade potencial de bookmarks. **Não adotar** como shortcut.
- Uma ponte que associe POP de 2019 a cada `M:2019MM` deve garantir **uma única ocorrência semântica de POP por município×ano**, sem reproduzi-la doze vezes ao agregar medidas; isso é uma hipótese de teste, não ganho comprovado.
- Para SIH/RD e CNES/LT, associar `Y:2019` a todas as competências de 2019 não equivale a somar doze snapshots de leitos como capacidade anual. 
- A seleção de meses e a seleção de anos possuem significados diferentes na V2: a sintaxe de um token não substitui os critérios de disponibilidade do indicador.

**Descartar B2-B de implementação automática.** Ela requer um **contrato físico e associativo separado** antes de qualquer mutação, justamente porque toca uma decisão aprovada no Boundary 6.

## 4. Matriz de impacto obrigatório

| Componente | Preservação requerida | Impacto de B2-A | Impacto potencial de B2-B / decisão |
|---|---|---|---|
| Três fatos e grãos | FI registro SIH/RD, LT CNES×competência×código, POP município×ano | Sem mudança física | Provar não multiplicação/perda; mudança da ponte `REQUIRES_EXPLICIT_MODEL_CHANGE_APPROVAL` |
| Oito dimensões | `DIM_TEMPO` única conformada, aliases por papel | Preservadas | Não fundir nível mensal e anual sem prova da relação semântica; manter datas clínicas distintas |
| `LINK_ANALISE` / `%LINK_KEY` | Cada fato compartilha somente `%LINK_KEY` com ponte; chaves role-playing separadas | Sem mudança | Necessita desenho de nova associação ou projeção com auditoria de cardinalidade, loops e `$Syn=0` |
| População anual | `POPULACAO_ESTIMADA` 1×município×ano | Sem alteração física | POP anual precisa responder a análise de mês usando **ano de referência**, sem fan-out físico/duplicação de denominador |
| Leitos SUS | Estoque por competência, média de snapshots anuais | Sem alteração física | Não converter `Sum(QTD_LEITOS_SUS)` entre competências em capacidade anual |
| P5 filtros | `C/R/I/B` por RES/LEI/REL/FLU | Expressões ainda não aprovadas | Mudança de associação pode alterar compatibilidade, recorte de papéis e denominadores; exigir C3/C4 |
| P2.3 ilha A1 | `P23_MUNICIPIO_6` e `P23_COMPETENCIA` **locais** | Independentes | Não conectar automaticamente à nova autoridade global |
| P1.2 histórico e guiado | 36 competências históricas ≠ 12 guiadas | Dois objetos distintos | Não reabrir oráculos; mostrar status real aplicado, não simular seleção por proposta |
| Três painéis e 14 visuais | Blueprint do PR #209, layout aprovado, sem implementação | Layout preservado | Qualquer mudança de número de documentos/folhas requer novo aceite visual |
| Segurança e Desktop | Comandos de menu e atalhos realmente disponíveis no operador | Rotas externas não controladas | Ocultar campo, Read Only de lista, alternate states e locks **não provam fronteira de autorização** |
| Registro acadêmico | Capítulos 1–2 entregues, Star/constelação | Sem alteração | Mudança de modelo aprovado exige deliberação e possível impacto no relatório, jamais revisão silenciosa |

## 5. Contrato candidato de seleção — invariantes testáveis, não Qlik script

### 5.1 Estados e compatibilidade

`PROPOSED` (variável de intenção) → `VALIDATE_PRE_DISPATCH` (domínio, existência, compatibilidade com estado atual e P5 aplicável) → `DISPATCH_SINGLE_AUTHORITY` (somente se ação realmente contida) → `VERIFY_APPLIED` (estado real, não só variável) → `PRESENT` (medidas válidas); `BLOCKED_WITH_REASON` em qualquer proposta/rota incompatível.

**Contrato de saída já candidato no desenho C2 de 30/10:** `MENSAL` = uma competência explícita do ano coerente (sem exigir seleção explícita adicional de ano); `ANUAL`/`EVOLUCAO` = um ano explícito e competência sem seleção explícita. Isso representa **estados-alvo de uma UI candidata**, não restringe por si só os estados históricos admitidos semanticamente em V2 para múltiplas competências/anos.

### 5.2 Casos de aceitação mínimos de uma futura arquitetura

1. `2019` anual e `201901` mensal são estados com interpretações diferentes, não dois filtros contraditórios a aplicar independentemente.
2. Proposta `M:201801` com ano real `2019` não pode **descartar silenciosamente** seleção anterior; sem transição validada prévia, mostrar bloqueio antes de mutar.
3. Mês inválido, competência ausente, ano ambíguo e filtros P5 incompatíveis bloqueiam pré-despacho com motivo legível.
4. Múltiplos meses não consecutivos não podem ser rotulados como intervalo contínuo; dados de mais de um ano não produzem KPI anual único.
5. Menu `Clear`, `Clear All`, `Unlock and Clear All`, `Back`, `Forward`, `Set/Reset Clear State`, busca, cliques em gráfico, `Current Selections`, importação/restauração de bookmarks, qualquer outro botão/listbox e eventos com ações devem receber, **para cada rota acessível**, classificação `CONTROLLED_WITH_EVIDENCE` ou `NOT_EXPOSED_WITH_EVIDENCE`. `UNKNOWN` → NO-GO. A ausência de bookmark gravado na TEMP #208 não prova desativação de importação.
6. Reconciliação numérica de FI, LT, POP, Link; ausência de fan-out, perda de papel RES/SERV, loops e synthetic keys; POP e snapshots têm aditividade temporal correta.
7. Controles observados em QlikView 12.0.20000.0 na **mesma QVW candidata**. Propriedades documentadas em September 2026 não são substituto de teste de compatibilidade da build instalada.
8. `C2` global não aprova `P5`, `C3`, `C4`, `Fase IX` ou produção; cada um possui gate próprio.

### 5.3 Matriz de evidência/STOP para cada candidata

`PASS` de arquitetura **não** resulta desta Discovery. Para uma futura proposta ser executável, exigir **antes do primeiro script**: especificação de campos reais e papéis, diagrama de associação alvo, invariantes de grão/aditividade, prova de que a UI contém/cobre as rotas nativas, compatibilidade QlikView 12 instalada, oráculos selecionados existentes, runner versionado em branch, hash/cópia TEMP e STOP único. Sem um mecanismo defensável para a rota nativa, `BLOCKED_ROUTE_COVERAGE` permanece sem nova PoC.

## 6. Resultado B2 e decisão pendente

**FATO VERIFICADO:** modelo atual distingue duas chaves temporais, POP anual nulo na competência, `%LINK_KEY` como único vínculo factual na ponte, QlikView Desktop com caminhos nativos fora dos botões; V2 exige prevenção antes de mutação.

**HIPÓTESE DE MODELAGEM:** uma projeção associativa com **um campo de seleção temporal canônico**, sem duplicar fatos, talvez simplifique a coerência entre ano/mês no nível da seleção. Contudo, multisseleção e rotas nativas impedem declarar prevenção global; a ponte também não tem prova de associação correta de POP e LT.

**DECISÃO PENDENTE DO RESPONSÁVEL:** **não** aprovar B2-B como arquitetura implementável. Escolher somente um dos caminhos em **gate independente**:

- **(R1) Discovery de contrato associativo B2-B**, limitado a **diagrama, cardinalidade e matriz de impactos** das tabelas/indicadores, **sem script ou QVW**, para decidir se a ponte é estruturalmente admissível; há risco de consumirmos mais documentação sem resolver controle nativo.
- **(R2) Revisão semântica formal de D2**, justificando e delimitando o modo de navegação de usuário diante dos comandos de Desktop, com apreciação explícita de alteração da V2. Uma revisão pode ser aceitável para a entrega acadêmica, mas **não pode ser chamada de D2=B original**.
- **(R3) Manter o NO-GO e priorizar as atividades acadêmicas/documentais independentes**, sem avançar a Fase IX.

**Recomendação técnica neste estágio:** **R2 como próxima decisão de produto**, sem adotar qualquer alteração de V2 agora. Justificativa: a raiz do bloqueio é **a ausência de controle preventivo demonstrável sobre mutações nativas do cliente Desktop**, algo que B2-B (nova ponte física) não resolve por si só, embora gere riscos a POP anual, CNES/LT e a `LINK_ANALISE`. Prosseguir R1 sem resolver a fronteira de interação repetiria Discovery de baixo retorno. Se o responsável exigir a semântica D2=B integral para **todas** as rotas, preferir R3 até haver prova técnica nova e concreta.

## 7. Referências oficiais e ressalva de compatibilidade

- [QlikView: Selections menu, 2026](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Selections_menu.htm) — histórico, clear, lock/unlock, reset.
- [QlikView: List Box, 2026](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/List_Box.htm) — `Read Only` local; `Always One Selected Value` altera o modelo.
- [QlikView: Selecting Field Values, 2025](https://help.qlik.com/en-US/qlikview/September2025/Subsystems/Client/Content/QV_QlikView/Select_field_values.htm) — seleções em múltiplos objetos e busca.
- [QlikView: Alternate States, 2026](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Alternate%20States.htm) — operações globais de seleção atingem todos os estados.
- [QlikView: Button2 actions, 2026](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm) — guarda de habilitação e ações; parâmetros de cadeia pré-avaliados.
- [QlikView: HidePrefix, 2026](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Scripting/SystemVariables/HidePrefix.htm) — ocultação de nomes, não política ACL.
- [QlikView: Bookmarks, 2026](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Bookmarks.htm) — seleção restaurada de bookmarks.

**Limite documental:** a instalação física inspecionada era `12.0.20000.0`, versão anterior à documentação online citada; não extrapolar suporte de propriedade sem prova na build real.

**Governança/STOP:** `DISCOVERY_B2=PASS_DOCUMENTAL_WITH_BLOCKERS`, `B2_IMPLEMENTATION=NOT_AUTHORIZED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Sem outro runner, sem nova PoC, sem alterações físicas e **sem merge do PR Draft**. Ordem C2 → C3 → C4 → GO Fase IX → três painéis preservada.
