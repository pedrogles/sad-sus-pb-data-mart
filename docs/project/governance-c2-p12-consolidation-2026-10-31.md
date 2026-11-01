# SAD — revisão de governança após C2 P1.2 e aceleração da entrega

**Gate:** `SAD-GOV-C2-P12-CONSOLIDATION-01`.  
**Data e baseline:** 31/10/2026, `main@2d205d52ab96eca565e85a9db5cfde14d9d3025c`.  
**Estado:** `GOVERNANCE_REVIEW_COMPLETE / DOC_INTEGRATION_RECOMMENDED / MERGE_PENDING_OWNER_APPROVAL`.  
**Ambiente e permissão:** ChatGPT GPT-6 + GitHub, revisão documental e atualização **somente desta branch/PR**; nenhum Windows/QlikView/COM, alteração de QVW/QVD/QVS, novo runner, merge, remoção de branches, mudança semântica, Fase IX ou produção.  
**Fonte primária:** [AGENTS](../../AGENTS.md) → [current-state original na main](current-state.md) → [requisitos](../academic/requirements.md); também [Boundary 7](../discovery/boundary-7-implementation-plan.md), [roteamento](agent-model-routing.md), [matriz 14](../discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md), [caminho crítico](final-delivery-critical-path.md), [auditoria anterior](governance-audit-2026-10-31.md) e PRs/Issue abaixo. O roteiro oficial do professor em `DescricaoProjetoSAD.pdf` foi consultado: Capítulos 3–5, Referências, Anexos I/II, ao menos três painéis, segunda entrega no dia da segunda avaliação **sem data exata indicada**.

## 1. Resultado auditado com graduação de evidência

| Evidência e referencial | O que está comprovado | O que NÃO está comprovado |
| --- | --- | --- |
| [PR #201 MERGED](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201) | BU15 aplicou ano real 2019 em uma rota; Verify de fonte/25 protegidos PASS **reportado pelo operador** | C2 genérico, rotas alternativas, outros períodos, D2/P5 global |
| [PR #203 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/203) | `CH02` histórico manteve 2017–2019 sob seleção real 2019; seleção persistiu da fonte, sem novo clique; integridade local reportada PASS | Nova transição BU15 nesse gate, enumeração 36/36 naquele estado, causa exclusiva da expressão |
| [PR #204 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/204) | **Decisão experimental posterior do responsável:** separar visual histórico de candidato guiado e preservar CH02 | Seu cabeçalho "PHYSICAL_NOT_RUN" era verdadeiro quando redigido; **não** representa o estado atual após #205 |
| [PR #205 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205) | Capturas fornecidas exibem **novo gráfico** com `EVOLUCAO`, `PERIODO_ANO=2019` real (Qtd 1), competência sem seleção explícita (Qtd 0), histórico separado; expressão candidata `=Sum(QTD_INTERNACAO)`, condição com "Expressão OK". Export `guided_chart_2019_export.tsv` (12 linhas, SHA-256 `CBC9368DB129F0BB19A1A1316EE5AA185CBE85E5D42CCD21DF798080CF9707E5`) comparado independentemente com o subconjunto 2019 do oráculo de 36 meses (SHA-256 `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`): **12/12 idênticas byte a byte, 0 divergências, total 188.246**. Verify Windows: fonte e 25 protegidos intactos, TEMP modificada, sem evidências GUI ausentes, exit 0 **reportado localmente**. | Inspeção independente do binário QVW/manifesto JSON; diff interno comprovando que só um objeto mudou, ID físico persistido do novo gráfico, resposta negativa/global do C2, aceite visual/produção |
| [Issue #196 OPEN](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196) | Cenário **positivo** `EVOLUCAO/2019` completado em #205; hoje o título/estado inicial da issue estão defasados | Bloqueio de períodos/propostas incompatíveis **antes** da seleção, rotas nativas relevantes, C2/D2/P5 global. Não fechar silenciosamente |
| [Issue #157 OPEN](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) | Pendência científica própria dos indicadores condicionados T25/T26 e da cobertura CNES/LT | Não é impedimento universal para análises SIH/RD e LT estritamente observacionais |

**Veredito preservado:** `C2_P12_2019_12_OF_12=PASS_RESTRICTED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Identidade exata da prova #205:** execução sobre `dfeb4089bb3bd6c35161e669ddb65013028c5492`, runner SHA-256 `9DAD558200B2CC2A0417B151C5D571380D291494E19EFC2477E4F6B6DD27D67D`, QlikView 12.0.20000.0; TEMP final SHA-256 `C8C3F24DAB56ABEEC0ABD0194A691FD78536BF8F550410E3C609262141A5B917` **reportado**. O HEAD atual do PR #205 inclui commit documental posterior `386c8a7867b46ffc3fd709610d9da7fb71b665b4`, **não executado**. Os dados e 25 artefatos são locais, fora do Git.

## 2. Parecer de integração — selecionar, não integrar tudo

| Superfície | Estado verificado | Parecer | Motivo |
| --- | --- | --- | --- |
| `docs/project/current-state.md` (nesta branch) | Stale em `main`: série 12 ainda "não testada" | **Integrar depois de revisão e autorização de merge** | É a fonte operacional prioritária; sem atualização há risco de repetição e gates errados |
| `README.md` e `final-delivery-critical-path.md` (nesta branch) | Ainda apontam teste 12/12 como próximo | **Integrar no mesmo PR documental** | Alinha handoff, mantém cronologia em documento histórico |
| Este parecer consolidado | Links para PRs, hashes, limites e decisão | **Integrar no mesmo PR documental** | Prova auditável sem materializar script experimental ou binário |
| PR #204 (somente desenho Markdown) | Draft, um documento; propostas anteriores à prova física | **Não merge as-is; reavaliar depois do PR documental** | O desenho já foi testado no recorte, mas status `PHYSICAL_NOT_RUN` e "decisão pendente" precisam de contexto temporal. O núcleo aprovado **para experimento** é descrito aqui e em #205 |
| PR #203 (runbook + runner pinado) | Draft, experimento observacional encerrado com bloqueio funcional | **Preservar Draft/sem merge** | Runner é de uso único, com SHA e branch antigos; não é ferramenta genérica |
| PR #205 (runbook + runner pinado) | Draft, experimento de gráfico novo encerrado PASS restrito | **Preservar Draft/sem merge** | Prova pertence ao commit original; runner contém guardas do experimento e não deve ser promovido à `main` por conveniência |
| PR #199 / #167 | Draft, gates históricos bloqueados/condicionais | **HOLD sem limpeza** | Não misturar higiene de branches com C2; #167 se refere somente a P2.3 |

**Proposta de decisão:** integrar **um único PR documental de quatro arquivos** (estado operacional, README, caminho crítico e este parecer) após conferência `main×branch`. Não fazer merge de #203/#204/#205 por arrasto. PRs antigos permanecem rastreáveis e podem, após decisão própria, ser encerrados mantendo commits/ref para recuperação. Nenhuma exclusão automática. **Esta avaliação NÃO é autorização de merge.**

## 3. Aceleração com critérios, não por quantidade de testes

### Decisão de produto/negócio

A entrega mínima oficial exige **ao menos três painéis**, mas a proposta original do projeto envolve **SIH/RD, capacidade de leitos CNES/LT e população IBGE/SIDRA**. Focar apenas os três painéis candidatos de uma fato (produção SIH/RD, leitos observados, fluxos RES→SERV) **é uma hipótese de redução de risco técnico**, não substituição automaticamente aprovada da promessa de integração/indicadores por habitante. Se a rota de população/indicadores cross-fact for excluída ou adiada, registrar decisão explícita e, conforme impacto, validar com o professor.

### Arquitetura e priorização

1. **Não reconstruir modelagem nem refazer AE01/P1–P3/36 meses.** As 14 visualizações já têm matriz N/F/A/V (número, campo/expressão, associação, visual), com quatro contratos documentais sustentados e dez condicionais. Atualizar **só a coluna de lacuna** que mudou; não transformar 14 visuais em 14 novos runners.
2. **Separar stream de execução e stream de documentação.** Em paralelo à decisão C2: preparar Capítulos 3–5, anexos das **oito dimensões e três fatos** já existentes, notas metodológicas, tabelas de proveniência e estrutura dos três painéis, claramente como **rascunho**. Não capturar screenshots finais nem alegar painel definitivo antes da Fase IX.
3. **Próximo gate físico apenas se necessário:** a lacuna C2 é comportamento incompatível/rotas reais de seleção e proteção D2 pré-despacho, **não** o gráfico 2019. Preferir uma matriz curta de cenários com **somente a menor transição não coberta**, avaliando resultado de pré-condição, estado antes/depois e efeitos colaterais. Se o mecanismo nativo permitir bypass, classificar `BLOCKED` e pedir **decisão de escopo de UX**; não tentar tornar toda a GUI "globalmente segura" por experimentos intermináveis. **Não reduzir a exigência D2 sem aprovação formal.**
4. **Contrato C3/C4 por indicador necessário**, só na ordem aprovada: C3 prova associação/papéis requeridos pelas análises selecionadas, C4 fecha expressões e medidas/denominadores, usando oráculos já salvos. Para T25/T26, Issue #157 condiciona aceitação; não inventar cobertura ou zero. Contratos globais e cruzamentos populacionais permanecem pendentes. Gates físicos só com autorização própria.
5. **Padronizar documentação de evidência, não criar automaticamente novo executor:** um manifesto `gate/HEAD/runnerSHA/sourceSHA/before/after/oracle/GUI/verdict/STOP` fora do Git, citado no closeout; **uma cópia protegida e uma única Verify por gate coerente**, nunca um runner por screenshot ou por mês. Reutilizar executores existentes **somente quando entrada/branch/manifesto forem compatíveis**; se não, abstrair um harness versionável e testado em gate futuro, mediante escopo explícito — não contornar pins nem alegar homologação.
6. **Critério mínimo por etapa:** `PASS_NUMERICAL` somente para export/oráculo; `PASS_LOCAL_INTEGRITY` apenas para hashes; `PASS_GUI_RESTRICTED` com capturas; `ACCEPTED_SCOPED` requer decisão humana; `PRODUCTION_APPROVED` requer gates e GO formais. Uma nota de closeout de até uma página referencia evidências em vez de repetir logs extensos no `current-state`.
7. **Congelamento de escopo por rodada:** exatamente **um problema e um aceite** por gate; após PASS/BLOCKED, STOP e handoff. Nada de repetir pilotos, reenviar capturas se elas já foram recebidas ou expandir para outra fact/competência sem necessidade. Se houver conflito novo real, registrar em issue/decisão independente.

### Trade-off recomendado

**Padrão recomendado:** preparar os três painéis **em nível de especificação e relatório** enquanto se fecha o menor requisito de C2; priorizar P1/P2/P3 de uma fato, **mas reservar explicitamente o caminho populacional T24** e os requisitos cross-fact até decisão de produto e validação científica. Isso evita gastar tempo com cobertura CNES global antes de visuais independentes, mas não autoriza omitir IBGE do objetivo ou pular C3/C4 necessários aos indicadores por habitante.

### Ordem de conclusão — gates, não cronologia de testes

| Ordem | Entregável/decisão | Aceite objetivo | Sem avanço se |
| --- | --- | --- | --- |
| 0 | **Integração documental** (este PR) | HEAD conferido, 4 arquivos somente Markdown, sem script/binário, merge autorizado e evidência preservada | PR com diff fora do escopo ou sem aprovação |
| 1 | **C2 residual** | Matriz estado/rota; cenários negativos necessários comprovados ou bloqueio/escopo formal decidido; `C2_FULL` só após cobertura realmente aceita | Bypass pré-despacho não resolvido; não elevar PASS de 2019 a global |
| 2 | **C3** | Contrato Link Key/papéis RES/SERV com associações necessárias e evidências, sem índices artificiais | C2 sem deliberação e dependências físicas desconhecidas |
| 3 | **C4** | Expressões T24 e indicadores selecionados com oráculo, agregação e papel/tempo; CNES T25/T26 conforme #157 | Link Key e denominadores não aceitos |
| 4 | **GO da Fase IX** | Escopo acadêmico final + matriz de aceite, direitos de acesso, artefatos/restrições aprovados pelo responsável | Sem decisão formal |
| 5 | **Painéis e submissão** | ≥3 painéis reais QlikView 12, prints e comentários, Cap. 3–5, Referências, Anexos I/II, revisão e Classroom | QlikView físico, relatório ou professor pendentes |

**Dependência externa imediata:** confirmar com o professor a data exata da segunda avaliação e qualquer ajuste material na promessa de integração populacional. A pauta pode ser preparada por escrito agora; não pressupor data não publicada.

## 4. Gate documental presente — aceitação e STOP

**PASS desta revisão:** diff de **quatro arquivos exclusivamente documentais**, referências verificáveis, resultados N/F/A/V graduados, estado operacional sem cronologia inchada, nenhum script de teste/binary incorporado e nenhum merge realizado.

**BLOCKED:** fonte `main` mudou e não foi reconciliada, diff inclui QVS/PowerShell/QVW/QVD, progresso anunciado contradiz o closeout da PoC, dependência científica omitida ou merge sem autorização.

**STOP:** parecer e PR Draft prontos para decisão do responsável. **Nenhuma execução Windows/QlikView, nova automação, edição de QVD/QVW, revalidação física, criação de painéis, mudança de arquitetura, merge, fechamento/renomeação de issue ou exclusão de branch** nesta revisão.

**Estados:** `C2_GUIDED_2019_12_OF_12=PASS_RESTRICTED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
