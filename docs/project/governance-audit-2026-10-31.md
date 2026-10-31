# SAD — Auditoria incremental de governança e higiene (31/10/2026)

**Gate:** `SAD-PROJECT-GOVERNANCE-AUDIT-01`  
**Resultado:** `READONLY_AUDIT_DOCUMENTED / HYGIENE_NOT_APPLIED`.  
**Baseline:** `main@238d4f70c5cf4576808fdd43af4a3d72b4e0b7cc`; PR #200 integrado.  
**Fontes:** [AGENTS](../../AGENTS.md) → [current-state](current-state.md) → [requisitos](../academic/requirements.md) → [Boundary 7](../discovery/boundary-7-implementation-plan.md) → [política de agentes](agent-model-routing.md) → GitHub (PRs, issues, heads, árvores) e [auditoria anterior de drift](../discovery/sad-operational-documentation-drift-audit-2026-10-29.md).  
**Ambiente:** ChatGPT/GitHub; READ-ONLY sobre código, QVD/QVW e execução; **somente documentação em branch separada**. Sem QlikView/Windows/COM, download de dados, script novo, merge, exclusões ou limpeza remota.  
**Regra de uso:** este relatório e o inventário CSV são **snapshot histórico**, não fonte operacional viva. Revalidar branch heads, PRs e `main` antes de qualquer APPLY futuro.

## 1. Conclusões e evidências

| Tema | Achado verificável | Impacto e ação |
| --- | --- | --- |
| Fase real | Fases III–V: ETL/QVD materializados segundo evidências locais; Fase VIII em testes físicos/analíticos restritos. [Matriz 14/14](../discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md) integrada por [PR #195](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/195); Fase IX não liberada. | Não tratar PASS numérico como homologação visual. |
| C2 | [PR #200](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/200) integrado; [PR #201](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201) Draft (HEAD da captura atualizado no CSV). [Closeout reportado](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201#issuecomment-6549181674): botão BU15 aplicou ano 2019 em uma rota, `-Verify` local exit 0. | PASS visual restrito para **um** despacho, sem série de 12 meses, D2/P5 global ou C2 full. A atualização do estado na branch #201 **não é main**. |
| Current state | `docs/project/current-state.md` em main ainda usa snapshot 29/10 e aponta gate C2 anterior à execução. | Correção proposta **dentro do PR #201**, para evitar PRs simultâneos concorrentes no mesmo arquivo. |
| README | Estado de 27/10 trata `EXTRATOS-ANALITICOS-READONLY-01` como próximo, apesar de execução e fechamentos posteriores. | Substituir o handoff por um snapshot com links à evidência, sem duplicar cronologia. |
| Caminho crítico | Texto histórico manda iniciar extratos e auditoria 14 visuais já encerrados. | Inserir **ponteiro vigente** no topo; preservar corpo histórico para rastreabilidade, sem reabrir etapas. |
| Política de agentes | `agent-model-routing.md` estava no `main`, pois [PR #126](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/126) foi integrado, mas cabeçalho ainda usa status condicional pré-merge. | Marcar vigente, sem alterar as decisões de arquitetura ou modelos. |
| Issues | [#157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) permanece aberta para escopo científico CNES/LT; [#161](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/161) mantém título `[BLOCKED]` embora comentário final documente `AE01 PASS RESTRICTED`. | #157 continua bloqueio/decisão independente. #161 exige **reconciliação de status**, não nova execução AE01; nenhuma issue editada neste gate. |

### Limite da auditoria

Esta revisão verifica refs e contratos documentais. Não executa smoke/QlikView nem atesta cada link âncora, cada script ou byte local. Dados/fatos e decisões semânticas mantêm evidência própria. O `README`, a política de agentes e o caminho crítico recebem apenas correções de roteamento; nenhum arquivo `QVS`, `QVW`, `QVD`, PowerShell ou Python foi tocado.

## 2. Branches — inventário rastreável (sem exclusões)

**Base do inventário GitHub:** 125 branches remotas no instante da coleta, incluindo `main` e a branch documental desta auditoria. [Snapshot CSV de 123 branches anteriores à presente branch](branch-hygiene-snapshot-2026-10-31.csv) registra **nome, SHA exato, classe e PR associado**, sem executar exclusão.

| Classe no snapshot | Quantidade | Decisão |
| --- | ---: | --- |
| `MERGED_PR_HEAD_MATCH_REVIEW_ONLY` | 94 | **CANDIDATE_ONLY** — HEAD coincidia com PR integrado; não é autorização para apagar |
| `CLOSED_UNMERGED_HOLD` | 21 | **HOLD** — comparar implementação, evidências e substituição |
| `OPEN_DRAFT_HOLD` | 3 | **HOLD ABSOLUTO** — PRs #167, #199 e #201 |
| `NO_ASSOCIATED_PR_HOLD` | 5 | **HOLD** — CID10 v1–v3, IBGE population notes e PS5.1 hash fix |
| **Subtotal de branches auditadas** | **123** | + `main` + a branch desta auditoria = 125 |

O snapshot cobre 195 PRs fechados e três PRs abertos no momento da consulta; a classificação não prova que uma branch integrada não serve como âncora de evidência local. Os HEADs podem mudar depois da captura. **Não executar o script antigo de 08/10/2026**, pois já aplicou sua limpeza histórica e contém predicados para inventário daquela data; a [revisão histórica](repository-hygiene-review-2026-10-08.md) permanece arquivo de evidência.

**Precondições antes de qualquer limpeza futura, mediante autorização própria:** novo inventário remoto + SHA; conferir estado de PR, refs em uso, commits relevantes não integrados, QVW/QVD/evidência externa dependente, estratégia de recuperação/restauração por SHA, dry-run sem efeitos e confirmação explícita do responsável. **Nenhum DELETE/force push/merge autorizado aqui**.

## 3. Otimização de agentes sem novos agentes

**Fluxo padrão recomendado:** 1 gate por agente/contexto → leitura obrigatória `AGENTS → current-state → requirements → docs do gate` → SHA `main` + HEAD Draft separado → objetivo/limites/STOP → reutilização de oráculos e scripts → evidência persistente → closeout curto → handoff. Usar [política canônica de agentes](agent-model-routing.md).

- **ChatGPT + GitHub:** triagem, documentação, revisão de PR e estratégia; não simular COM/GUI ou acesso aos QVDs do Windows.
- **Codex Local/operador no Windows:** quando a lacuna exigir QlikView 12/PowerShell, usar versão pinada do script e artefato TEMP, com hashes de protegidos e resultado de uma tentativa. **Evitar novos runners** quando já há executores e oráculos suficientes.
- **Aceite humano:** inspeção visual/metodológica do painel, método de indicadores, liberação explícita de merges/produção. Distinguir `SCRIPT_VERSIONED` → `PASS_LOCAL_REPORTED` → `VISUAL_REVIEWED` → `ACCEPTED`.

**Índice de navegação em vez de cronologia no prompt:** `README` aponta `current-state`, Boundary 7, matriz 14 visuais, caminhos e decisões. `current-state` permanece curto (na branch #201); Discovery preserva logs, hashes e resultados. Nenhum histórico apagado.

## 4. Caminho para terminar a entrega

1. **Revisão do PR #201** e, se aprovado, integração documental independente (sem reexecução). **Nenhum gate novo até avaliar a necessidade.**
2. **Próximo gate físico C2 separado e ainda não autorizado:** série `201901..201912` em `EVOLUCAO/2019` com seleção de ano real, 12 pontos e comparação com oráculo mensal já arquivado. Não repetir o piloto do botão nem os 36 pontos históricos.
3. Fechar apenas os contratos de **associação RES/SERV e dimensões exclusivas** necessários aos 14 visuais realmente selecionados, em C3/C4 conforme [Boundary 7](../discovery/boundary-7-implementation-plan.md). Para indicadores entre fatos, encaminhar antes a decisão científica [#157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157), Link Key e medidas/denominadores; `T29_HISTORICAL` e notas CNES permanecem restritos.
4. Somente após GO de aceite, Fase IX: 3 painéis QlikView 12 reais com medidas, filtros, avisos metodológicos e evidência de renderização/reconciliação.
5. Entrega acadêmica: relatório Capítulos 3–5, prints/comentários, Referências, Anexos I/II, revisão do professor/avaliação e confirmação da segunda data de entrega. Não reescrever a primeira entrega sem decisão expressa.

## 5. Fechamento da auditoria

`AUDIT_READONLY=COMPLETE`; `DOC_CHANGES=PROPOSED_IN_PR`; `BRANCH_HYGIENE_APPLY=NOT_RUN`; `C2_FULL=NO_GO_NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Critério de parada:** inventário, diagnóstico e roteamento documentados; nenhuma fusão de PRs, exclusão, nova execução física, alteração da modelagem ou limpeza não auditada. Revisão e merge exigem decisão independente.
