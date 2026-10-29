# SAD — Auditoria documental operacional e correção de handoff (29/10/2026)

**Objetivo único:** confrontar o estado operacional documentado com os PRs efetivamente integrados à `main`, localizar drifts que induzam reexecução/redecisão e produzir handoff documental **incremental** dos 14 visuais, sem implementar o próximo gate.  
**Preflight Git:** `main@f8f79674b3eba429c6af89f9be154e0e0185eee0`, após [PR #193](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/193) integrado.  
**Método/abrangência:** inspeção estática via conector GitHub de `AGENTS.md`, `docs/project/current-state.md`, requisitos, Boundary 7, escopo D1–D3, decisões A0/A1, plano de suficiência, caminho crítico, protocolos P2.3/P3 e snapshots dos PRs pertinentes. Árvore `main` enumerada (295 itens, 136 `.md` sob `docs/{project,discovery,academic}` mais `AGENTS.md`). **Não** leitura/validação individual de todos os 136 documentos nem auditoria de todos os bytes de QVD/QVW; a conclusão de ausência de drift é **restrita aos contratos e arquivos inspecionados**.  
**Agente/ambiente:** ChatGPT GPT-6 + GitHub; análise documental e commits em branch autorizados pelo responsável. Não há execução local Windows/COM/QlikView, CI, correções físicas nem dados brutos.  
**Fonte prioritária:** estados de PR/commits Git reais prevalecem sobre descrições históricas de preparação; não reinterpretar PASS numérico de Python como aceite global da UI.

## Drifts confirmados no preflight e tratamento

| ID | Documento/superfície | Conflito factual identificado | Tratamento sem mudar decisão |
| --- | --- | --- | --- |
| D01 | `docs/project/current-state.md` | PR #193/P3.4 descrito como Draft e `PR_MERGED=False`, apesar de `MERGED` com squash `f8f79674` | Corrigir topo, estados P3.1–P3.4 e próximo gate; preservar resultados locais restritos |
| D02 | `docs/project/analytical-source-and-architecture-decision-2026-10-27.md` | A proposta continua descrita como Draft/não vigente e comparação A0×A1 pendente; PR #162 e decisão #166 já integrados | Rotular status como histórico; apontar decisão A0 padrão e A1 somente condicional P2.3 |
| D03 | `docs/project/analytical-consumption-architecture-approval-2026-10-27.md` | Handoff P2.3 de 27/10 ainda figura como próximo; não distingue a execução A1 R2 restrita posterior | Preservar decisão original e registrar #168/#170/#169 integrados com PASS candidato e limites |
| D04 | `docs/discovery/sad-analytical-consumption-discovery-2026-10-27.md` | O cabeçalho `PREPARADO_NAO_EXECUTADO` pode ser tomado como estado vigente, apesar da decisão documental A0×A1 em #166 | Tornar explícito `estado da preparação histórica`; não iniciar Discovery antiga novamente |
| D05 | `docs/project/final-delivery-critical-path.md` | Handoff prioritário ainda solicita `EXTRATOS-ANALITICOS-READONLY-01` como próximo passo, após conclusão restrita P1–P3 | Marcar proposta histórica; recomendar gate **delta dos 14 visuais**, sem alterar G1–G7 |
| D06 | `docs/discovery/analytical-sufficiency-plan-2026-10-27.md` | `EXECUTION_NOT_RUN` da preparação de 27/10 pode ser interpretado como execução atual ausente | Qualificar marcador como histórico e redirecionar à evidência/estado atuais |

**Fatos Git confirmados:** [#126](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/126) integrado (política de agentes); [#159](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/159), [#160](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/160), [#162](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/162), [#165](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/165), [#166](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/166), [#168](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/168), [#169](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/169), [#170](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/170) integrados; [#167](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/167) **OPEN/Draft**, não integrado; PRs [#190](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/190)–[#193](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/193) **MERGED**. O `merge_commit_sha` exibido por API para PR Draft não é substituto de `merged=true`.

## Decisões válidas e **não** reabertas

- **Escopo D1–D3:** 14 visuais candidatos (P1=5, P2=5, P3=4), 3 painéis descritivos, I06/I07 opcionais, I12/T24 fora do núcleo inicial; 3 fatos/8 dimensões preservados.
- **Arquitetura de consumo:** A0 como **padrão dos 14 visuais**; **A1 apenas condicional para P2.3** na representação da grade município PB×competência. Não converter A1 ilhada em quarta fato, dimensão, QVD, Link Key global ou remodelagem A2.
- **P2.3:** [#167](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/167) guarda R1 `A0_NOT_VALIDATED` restrito (não significa impossibilidade universal); R2 A1 em [protocolo físico](sad-p23-a1-physical-gate-protocol-2026-10-28.md) registra `PASS_LOCAL_A1_P23_CANDIDATE_ONLY`, com readback restrito; **não** aceite visual, global, produção ou autorização para sincronização de filtros.
- **Resultados P1–P3:** testes/reconciliadores locais de uma única fato com status numérico restrito, inclusive P3.1–P3.4 integrados. **Não** repetir AE01/A0 R1, P1/P2/P3, VI-P4/C4-F ou P2.3 R2 para validar os mesmos números.
- **Pendências verdadeiras (não são drift):** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `ZERO_REAL_COMPROVADO=NOT_PROVEN`, [G1 Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) aberta para T25/T26, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Ordem física C2→C3→C4 do Boundary 7 inalterada.

## Registros intencionalmente históricos / fora deste ajuste

Os logs, hashes, commits executados e estados `NOT_RUN` **rotulados como fase de preparação** permanecem intactos nas provas de P1–P3; não substituir cronologia real por status retrospectivos. O bootstrap original de 27/10 `docs/discovery/bootstrap-sad-analytical-consumption-discovery-2026-10-27.md` e a proposta I01–I12 são **artefatos históricos**, não roteadores atuais. O [escopo aprovado](sad-analytical-scope-acceptance-01-2026-10-27.md) conserva sua seção de handoff **histórico após D1–D3**, sem apagar a aprovação posterior #166. PR #167 segue Draft, mas sua existência não autoriza merge/fechamento/deleção de branch. Outros arquivos de `docs/discovery/` não foram alterados por simples ocorrência de SHA antigo: citar base histórica não constitui drift automaticamente.

## Handoff explícito — novo gate recomendado, **NÃO INICIADO**

**Gate proposto:** `SAD-CONSUMPTION-14-DELTA-READONLY-01` — inspeção estática de **somente lacunas residuais** dos 14 visuais candidatos do contrato D1–D3, com zero execução física.

**Entradas já aprovadas:** [matriz de 14 visuais](sad-analytical-scope-acceptance-01-2026-10-27.md), [matriz de fontes](sad-analytical-consumption-source-matrix-2026-10-27.md), [decisão A0/A1](../project/analytical-consumption-architecture-approval-2026-10-27.md), [P2.3 R2](sad-p23-a1-physical-gate-protocol-2026-10-28.md), closeouts P1/P2/P3, modelo QVS VII, V2 e Boundary 7. Não abrir novos scripts de extração ou pilotos sem **bloqueio real e permissão própria**.

**Objetivo e aceite:** matriz **14/14** com ID, contrato já decidido, fonte/fato/medida/campo versionado, filtros e papéis de tempo/município, evidência reutilizada, lacuna **nova** específica, estado `SUPPORTED_BY_EXISTING_EVIDENCE` / `CONDITIONAL` / `BLOCKED`, necessidade mínima de prova física futura e owner/decisor; priorização de **até 3 lacunas reais**; indicar um **único próximo gate**, sem criar script/PR de implementação. Não exigir teste físico para comprovar uma inferência documental, nem afirmar UI validada a partir de números.

**STOP:** encerramento ao produzir matriz 14/14 + ≤3 lacunas + próximo handoff com evidência. Sem redecidir A0×A1, executar COM, tocar QVD/QVW/QVS, começar P2.3 R3, avançar G2–G7, alterar modelo acadêmico, fazer merge ou liberar IX. Estados possíveis `DELTA_AUDIT_DOCUMENTED_READONLY`, `BLOCKED_MISSING_SPECIFIC_EVIDENCE` ou `ESCALATE_OWNER_DECISION`. Handoff/aceite de execução física posterior requer permissão **separada**.

## Revisão de integração deste PR documental

**Critérios de aceite:** somente arquivos Markdown operacionais/relatório; sem alteração de `AGENTS.md`, `docs/academic`, QVS, QVD/QVW, Python, PowerShell, branches anteriores ou dados; corrigir estados contraditórios sem apagar histórico; PR separado e diff inspecionado; CI não presumido; `PR_MERGED` confirmado exclusivamente após retorno real do GitHub. **Condição de parada:** merge deste PR de drift (se revisão satisfatória) e entrega de **bootstrap textual** do próximo gate ao usuário, **sem executar o gate**.
