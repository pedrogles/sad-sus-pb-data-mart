# SAD — Plano de reconciliação e higiene final do GitHub

**Data do inventário:** 10/11/2026 (America/Fortaleza; consultas GitHub UTC já em 11/11).  
**Repositório:** `pedrogles/sad-sus-pb-data-mart`, `main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83`.  
**Fonte bruta:** [inventário JSON](repository-final-hygiene-inventory-2026-11-10.json), com **159** branches registradas *antes* da criação da branch de consolidação, respectivos commits, PRs associados e conferência de HEAD.  
**Esta PR é uma área de preparação:** não equivale a merge, aceite docente, homologação física ou exclusão.

## 1. Objetivo, invariantes e STOP

**Objetivo:** reconciliar a documentação e o roteamento da `main` com a entrega acadêmica efetivamente construída, preservar scripts e evidências relevantes dispersos nos Drafts, encerrar trabalho histórico sem falsear seus resultados e obter lotes seguros de exclusão de branches após aprovação.

**Invariantes:**
- Ferramenta QlikView 12, 3 fatos, 8 dimensões, Star/constelação e granularidades da primeira entrega inalterados;
- No segundo trabalho acadêmico, **três folhas com nove objetos** foram implementadas como MVP temporário, em cópias locais, sem substituição silenciosa do blueprint de 14 visuais aprovado em `main`;
- `VIS04_LOCAL_GUI_PRESENTATION=PASS_RESTRICTED` e `DOC_R3_98_PAGE_PDF=QA_PASS` **não** homologam C2/C3/C4, Fase IX, cobertura científica integral CNES nem produção;
- QVDs, QVWs e PDFs binários permanecem fora do Git; fontes/cópias locais protegidas por SHA; submissão docente ainda não verificada;
- Segunda entrega **encerra o desenvolvimento acadêmico planejado**; pendências científicas permanecem como limitações, não backlog prometido.
- **Nenhum merge, fechamento de PR/issue, exclusão remota de branch, force push ou alteração da `main` nesta fase.** Todo lote futuro exige autorização nominal do responsável, rechecagem de HEAD e evidência de execução.

**PASS desta PR documental:** inventário reproduzível; fontes finais seletivas preservadas em arquivos canônicos; `README.md` e `current-state.md` propostos coerentes; sem mudança semântica/arquitetural. **STOP:** após abrir PR Draft de consolidação, aguardar a autorização de integração e limpeza em lotes.

## 2. Inventário remoto

| Tipo | Quantidade | Evidência |
| --- | ---: | --- |
| Branches antes da nova branch de higiene | **159** | GitHub `GET /branches` páginas 1–2 |
| PRs abertos | **32**, todos Draft | `GET /pulls?state=open` |
| PRs fechados | **201** | `GET /pulls?state=closed` |
| Desses, integrados | **177** | Campo `merged_at` |
| Desses, fechados sem merge | **24** | `merged_at=null` |
| Issues abertas que não são PRs | **2** | #157, #196 |

**Relação branch↔PR dos 159 refs:** 100 refs pertencem a **PRs integrados**, 32 a PRs abertos, 21 a PRs **fechados sem merge**, 5 não possuem PR encontrado e 1 é `main`. Os **100 HEADs de refs já integradas** e os **21 HEADs de refs fechadas** coincidem exatamente com o HEAD atual registrado pelo respectivo PR; não se observou commit posterior ao PR nesse teste. **Isso não demonstra que todo conteúdo de uma branch fechada sem merge está preservado na main.** Exige-se conferência imediatamente antes de cada lote.

## 3. Estratégia para as 32 PRs ainda Draft

| Agrupamento | PRs | Decisão proposta após a consolidação |
| --- | --- | --- |
| Histórico C2/CI/guardas, não adotado como entrega final | **#167, #199, #203–#205, #207–#208, #210–#212, #215–#225, #227–#229** (24) | Fechar como **SUPERSEDED_BY_FINAL_ACADEMIC_SCOPE** ou **NOT_MERGED_NO_C2_PASS**; preservar links, registros de falha e histórico. Não dar PASS retroativo nem integrar scripts experimentais indiscriminadamente |
| Base experimental do MVP | **#226** | Integrar somente decisão de escopo, evidência restrita, contrato de guarda de apresentação, QVS de fluxo e builder TEMP versionado para rastreabilidade; **não** aprovar a arquitetura física como produção |
| Planejamento da entrega | **#230** | Incorporar o estado final, prazo comunicado pelo operador e referência ao roteiro no closeout, sem necessidade de preservar drafts de bootstrap repetidos |
| Evidências de GUI e correção | **#231–#233, #236** | Integrar os closeouts decisivos e executores pinados usados; manter a prova de persistência e hashes |
| Relatório acadêmico e auditoria | **#234–#235** | Integrar manifesto do DOC-R3, justificativa dos indicadores ausentes, auditoria dos nove objetos, roteiro de apresentação e os scripts efetivamente usados na revisão final do PDF |

**Importante:** esses PRs não devem receber 32 merges independentes. Esta PR única de consolidação contém uma **seleção documentada e SHA-identical** dos artefatos essenciais, além de um novo roteador operacional. Após sua integração autorizada, fechar os Drafts antigos com comentário contendo link para esta PR e motivo específico (não fingir que foram todos merged). Materiais não selecionados continuam consultáveis no diff histórico dos PRs fechados.

## 4. Issues

- **[#157 — suficiência científica T25/T26](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157):** a matriz científica geral não recebeu `RESOLVED_ACCEPTED` conforme critérios originais; parte do CNES/LT pode ser apresentada **observacionalmente com ressalvas**. Se o responsável optar por encerrar o projeto acadêmico sem nova implementação, fechar a issue com razão **NOT_PLANNED / ACADEMIC_SCOPE_ENDED**, link para os limites do DOC-R3 e sem chamar `AUSENCIA_DE_LINHA` de zero.
- **[#196 — aceite C2 físico](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196):** testes guiados possuem PASS restritos, mas **C2 global não foi aprovado**. Fechar por **NOT_PLANNED / ACADEMIC_SCOPE_ENDED**, após evidência canônica da entrega, não como `completed` ou `GATE_PASS`. Não reexecutar 69 comentários/testes históricos.

**Estado atual destas issues:** `OPEN`, sem modificação nesta PR.

## 5. Branches: lotes separados e preservação

**Lote A — primeira limpeza, 100 refs de PRs integrados:** elegíveis **apenas após** revalidar branch HEAD, PR `merged_at`, ausência de commits posteriores ao HEAD do PR, arquivar o inventário e obter aprovação nominal para o lote exato. GitHub mantém PR/commit diff; a limpeza remove refs antigas, não a `main`. O executor de remoção rodará **localmente pelo responsável**, pois esta conexão GitHub não fornece ação remota de excluir branches. Preferir comandos idempotentes com lease SHA e relatório.

**Lote B — 32 refs de PRs abertos:** fechar PRs um a um **após** integrar esta consolidação, e então revalidar seus HEADs. Não eliminar refs antes de consolidar documentos/código essenciais.

**Lote C — 21 refs de PRs já fechados sem merge:** NÃO incluir na primeira exclusão. Algumas apresentam diffs documentais e/ou executores nunca integrados; revisar propósito, resultado de cada PR e se o commit possui arquivo exclusivo de valor permanente. Somente após classificação `DISCARD_INTENTIONAL` / `ARCHIVED` e autorização, remover em lote próprio.

**Lote D — 5 branches órfãs (sem PR):** manter até decisão específica. Inventário:
- `fix/phase-3-cid10-dual-diagnostic`
- `fix/phase-3-cid10-dual-diagnostic-v2`
- `fix/phase-3-cid10-dual-diagnostic-v3`
- `fix/phase-3-ibge-population-notes`
- `fix/readiness-hash-ps51-compat`

As cinco estão **divergentes com commits à frente da main** em comparação estática. Podem conter correções superadas, mas não há prova suficiente de equivalência de conteúdo final. **NÃO apagar apenas por ausência de PR.**

**Backup antes de exclusão (operação futura):** exportar/validar refs do Git e gerar `git bundle --all` em pasta privada fora do repositório; registrar SHA do bundle e contagem de refs. `--all` deve ser verificado no runtime local antes de depender dele como backup. Validar se todas as refs candidatas estão realmente presentes no clone. Só então montar comandos de remoção com proteção contra drift. **Nenhum backup foi criado nesta fase.**

## 6. Entregável final e nova fonte de verdade proposta

- `README.md` reorientado à entrega final e aos limites.
- `docs/project/current-state.md` curto: **implementação acadêmica encerrada em escopo**, QVW TEMP VIS-04 validada localmente, PDF DOC-R3 98 páginas QA, ensaio e submissão pendentes, contratos globais não aprovados.
- `docs/academic/final-delivery-record-2026-11-10.md`: artefatos, SHA dos arquivos, provas de escopo, links às evidências principais e ressalvas.
- Documentos/executores únicos dos PRs #226, #231–#236 selecionados para inclusão na `main`, **sem execução ou homologação adicional**.
- `docs/project/repository-final-hygiene-inventory-2026-11-10.json`: snapshot machine-readable de todos os 159 refs e PRs.
- `tools/Get-SadBranchCleanupDryRun.ps1`: verifica estado remoto do Git por SHA e gera CSV; **não deleta branches**.

**Critérios PASS desta consolidação:** nenhuma modificação dos scripts já existentes em `main`, nenhuma alteração de modelos, nenhuma reescrita do DOC-R3/QVD/QVW. Material selecionado preserva Git blob SHA dos PRs de origem; hashes relevantes documentados. **Nenhuma exclusão está autorizada por esta PR.**

## 7. Checkpoints de aprovação do responsável (separados)

1. **APROVAR_MERGE_CONSOLIDACAO**: revisão da PR e autorização de merge apenas dela, sem integrar Drafts experimentais.
2. **APROVAR_FECHAMENTO_PRS_ISSUES**: lista explícita #167...#236 e issues #157/#196, com reason por item.
3. **APROVAR_DELETE_MERGED_100**: snapshot atualizado dos 100 branches, SHA e backup validado.
4. **APROVAR_DELETE_OUTROS**: somente lotes B/C/D depois de avaliação de conteúdo único.

Esse desenho evita novos ciclos de Discovery, mantém os resultados investigáveis e deixa a `main` com um **estado acadêmico final defensável**.

## 8. Atualização de execução — 11/11/2026 (snapshot superveniente)

**As seções 1–7 são o plano histórico antes do merge #237.** O responsável aprovou o merge da [PR #237](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/237), concluído na `main@6a5ab443cb3ed89e51ed2f8d955d47c5272e4411`. Em autorização seguinte, foram fechados **24 PRs históricos C2 sem merge** (#167, #199, #203–#205, #207–#208, #210–#212, #215–#225, #227–#229), cada qual com comentário e preservação de veredito (PASS restrito, blocker ou NOT_RUN).

**Após esses fechamentos:** oito PRs acadêmicos continuaram Draft: #226, #230–#236. As issues #157/#196 permaneceram OPEN, sem exclusão de branches. A contagem de branches foi **160 refs** na verificação pós-fechamentos; a criação da nova branch documental aumenta esse número, portanto o inventário de 159 refs continua **snapshot histórico**.

**Segundo gate — cobertura de arquivos dos oito PRs:** auditoria detalhada em [academic-pr-coverage-audit-2026-11-11.md](academic-pr-coverage-audit-2026-11-11.md) e [JSON auditável](academic-pr-coverage-audit-2026-11-11.json). Foram identificados **47 arquivos**: 16 já idênticos na `main`, 7 copiados com Git blob SHA idêntico para uma **nova proposta Draft**, 24 ainda exclusivos dos PRs/branches históricos. Cinco links relativos quebrados no documento central do MVP foram corrigidos na nova proposta para apontarem a commit SHA imutável da #226, sem modificar os resultados de teste.

**Gates separados:** (i) revisar e aprovar merge da proposta de preservação dos sete arquivos + correção dos links; (ii) em nova autorização, fechar os oito PRs com motivo e conteúdo exclusivo explicitados; (iii) depois de dry-run/backup verificável e decisão nominal, excluir refs. Não inferir que aprovação deste documento autorize fechamento, merge ou exclusão.

**STOP:** este addendum de controle não modifica dados, modelo, QVD/QVW, PDF DOC-R3 nem gates C2/C3/C4.
