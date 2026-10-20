# Fase VIII — C2: encerramento de evidências existentes (READ-ONLY)

**Data:** 20/10/2026  
**Baseline:** `main@256c4b098962398f2c7231e8437c4732c09bcf27` ([PR #134](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/134) integrado).  
**Estado deste gate:** `C2_EXISTING_EVIDENCE_READONLY_REVIEW=COMPLETED_WITH_LIMITS`.  
**Decisão restrita:** `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_FULLY` (preservar também o status canônico `P5_D2_UI=NOT_TESTED`).  
**Origem das provas:** documentos integrados na `main` e arquivos Markdown de branches de PRs históricos fechados sem merge; onde citada execução local Windows, os binários QVW/QVD e os logs integrais não foram reabertos neste gate.

## 1. Objetivo, fontes, autorização e condição de parada

**Objetivo único:** reconciliar os resultados já documentados de C2 (objetos, filtros P5, regra D2 e interface QlikView 12), **sem** executar novos testes, sem repetir sondagens/prints e sem converter protótipos em aprovação final. A autorização para prosseguir à próxima prioridade foi recebida em 20/10/2026; esta revisão documental **não autoriza C3 físico, mudanças na V2 ou Fase IX**.

Fontes lidas em sequência: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, [Boundary 7](boundary-7-implementation-plan.md), [V2 §62](phase-6-semantic-v2-approved-2026-10-14.md), [C1](phase-8-c1-cnes-coverage-readonly-2026-10-18.md), [escopo CNES/LT já integrado](phase-8-cnes-presentation-scope-decision-2026-10-20.md), [C2-D](phase-8-c2d-d2-ui-predispatch-feasibility-2026-10-19.md), [C2-D3](phase-8-c2d3-rawview-win32-discovery-2026-10-19.md), [automação QlikView](../project/qlikview-powershell-automation.md) e relatórios dos PRs #117–#120 e #122–#124 lidos diretamente de suas branches preservadas.

Escopo tocável: este Markdown em branch separada. Proibidos clique, PowerShell, COM, reload, criação/alteração de QVW ou QVD, reexecução de T24–T26, alteração de scripts, modelagem, exclusão de branches e merge não autorizado.

**STOP:** registrar matriz de evidências, veredito restrito e próximo bloqueio mínimo, depois encerrar C2 READ-ONLY.

## 2. Matriz de reconciliação

| Subgate / evidência | Resultado sustentado | Não sustentado |
| --- | --- | --- |
| [C2-A, PR #117](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/117) | `C2A_COM_AND_SCREENSHOTS=PASS_LOCAL_CANDIDATE_ONLY`; teste de condição de cálculo T26 e casos P5 B (procedimento, residência combinada e tipo de leito); 5 PNGs auditados; bloqueio visível | `C2A_VISUAL_AUDIT=BLOCKED_PRESENTATION`: cabeçalhos, avisos e/ou número truncados; nenhuma proteção pré-seleção D2 na UI |
| [C2-V, PR #118](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/118) | Cálculo/condições e avisos de bloqueio em 4/4 estados visualmente restritos; número 31,21 legível | `C2V_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION` por encolhimento da tabela em S0 e cabeçalhos truncados |
| [C2-S, PR #119](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/119) | Diagnóstico experimental do efeito de “Ajustar tamanho aos dados” | Não homologa visual do protótipo, nem autoriza edição da cópia evidencial original |
| [C2-W, PR #120](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/120) | Após ajustes manuais, `C2W_S0_VISUAL_ACCEPTANCE=PASS_RESTRICTED_AFTER_MANUAL_ADJUSTMENTS`; S1 bloqueado na cópia anterior tem PASS restrito | `C2W_S1_WRAP_COPY=NOT_TESTED`; sem aprovação do C2 completo, dos demais filtros ou da interface final |
| [C2-D1, PR #122](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/122), §14 | D2-1 e D2-3 `PASS_VISUAL_RESTRICTED` (pares pré/pós); D2-2 e D2-4 têm captura única e relato de clique compatíveis com o esperado | `C2D1_EXPERIMENTAL_COLLECTION=CLOSED_PARTIAL_EVIDENCE`; `C2D1_FOUR_CASE_GATE=NOT_FULLY_APPROVED`; nenhuma instrumentação interna de despacho, controle de todas as rotas de seleção ou cobertura geral |
| [C2-D2, PR #123](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/123) e [C2-D3, PR #124](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/124) | Sondas Windows reportadas em status restritos `BLOCKED_UIA_EXACT_BUTTONS_NOT_EXPOSED_FOUND_0` e `NO_GO_STABLE_BU01_BU02_IDENTIFIERS_NOT_FOUND_IN_THIS_PROBE` | Não demonstram impossibilidade universal de automação; não autorizaram `Pilot`/`Complete`, cliques estimados ou a proteção D2 geral |

**Qualificação de evidência:** inspeção desta sessão foi **estática dos documentos e metadados Git**, não auditoria física independente nem nova inspeção visual dos PNGs. PASS local, PASS visual restrito e aceitação geral são níveis distintos. PRs #117–#124 estão fechados **sem merge**; sua documentação original é evidência preservada nas branches, não implementação integrada na `main`. C2-D e C2-D3 foram incorporados como documentos históricos na `main`, mas não os seus scripts.

## 3. Decisão técnica restrita

**GO apenas como evidência experimental:** manter os PASS locais e visuais qualificados acima. A cópia C2-W mostra apresentação restrita de T26 em S0, com aviso de escopo CNES/LT; C2-A/C2-V demonstram determinados bloqueios `Calculation Condition` e avisos P5, mas **bloqueiam cálculo/exibição sob uma seleção já existente**, não impedem que a seleção incompatível ocorra.

**NO-GO para homologação global de C2 neste momento:**
- D2 exige, pela V2, evitar conflito **antes do despacho**. Triggers `OnSelect`/`OnAnySelect` são pós-seleção; a rota de dois botões não protege outras listas, buscas, bookmarks ou ações. O projeto não pode declarar `P5_D2_UI=APPROVED`.
- O ensaio P5 cobre subconjuntos B de T26, inclusive dois filtros B simultâneos, **não** todos os indicadores e todas as classes `C/R/I/B` da matriz sob filtros simultâneos. `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`.
- O alinhamento territorial e a cobertura CNES/LT observada não autorizam afirmar universo hospitalar comprovado, ocupação de leitos ou resultados gerais de T26.

**DECISÃO PENDENTE, sem alteração silenciosa da V2:** optar entre especificar uma superfície de seleção totalmente controlada (com prova de bloqueio de rotas alternativas) ou manter a guarda D2 de interface como bloqueio formal até existir evidência física suficiente. Não usar apenas duas capturas extras de D2-2/D2-4 como suposta solução universal; isso aumentaria evidência do caminho por botão, não da interface inteira.

## 4. Encaminhamento, gates e STOP

**C2 READ-ONLY:** `COMPLETED_WITH_LIMITS`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`. Manter testes físicos e implementação global de C2 **bloqueados até delimitação de caso, rota e autorização**. Não repetir sondagem UIAutomation/Win32, reexecutar C2-W, T24/T25/T26 ou iniciar nova cadeia de runners sem causa objetiva.

**Próxima prioridade admissível:** triagem **C3 READ-ONLY** sobre o [PR #125](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/125), preservando a ordem C2 documentado/bloqueado → C3 → C4 do [estado operacional](../project/current-state.md). O runner C3-B1 está versionado na branch Draft, mas `C3B1_PHYSICAL=NOT_RUN`; nenhum PASS físico pode ser inferido. Uma execução no Windows/QlikView 12 exige autorização separada, commit/SHA, origens QVW/F1 verificadas e evidência persistente fora de Git.

**Estados não promovidos:** `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Agente/ambiente:** ChatGPT GPT-6 com conector GitHub em READ-ONLY para fontes, escrita restrita deste documento versionado; modelo/esforço não selecionados explicitamente; Windows/COM/GUI não acessados. Fallback físico, se autorizado: Codex Local em Windows ou operação humana, sem utilização de Work/Codex nesta revisão. `RUNTIME_TEMP`/`EVIDENCE_ROOT`: não aplicáveis. Critério de `BLOCKED`: fonte ou evidência incompatível/inacessível, sem inferência positiva; `PASS`: matriz rastreável, estados preservados, diff só Markdown; `STOP`: documento revisado e PR Draft para aprovação documental, sem merge implícito.
