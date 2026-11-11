# SAD — Cobertura e retenção dos oito PRs acadêmicos ainda Draft

**Data da auditoria:** 11/11/2026.  
**Baseline inspecionada:** `main@6a5ab443cb3ed89e51ed2f8d955d47c5272e4411` (PR #237 já integrada).  
**PRs examinados:** [#226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226), [#230](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/230), [#231](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/231), [#232](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/232), [#233](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/233), [#234](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/234), [#235](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/235), [#236](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/236).  
**Fonte do inventário:** [arquivo JSON dos 47 blobs](academic-pr-coverage-audit-2026-11-11.json), obtidos por GitHub `GET /pulls/{n}/files` comparados ao Git tree da `main` por caminho e Git blob SHA. Não comparar apenas títulos ou resumos de conversa.

## 1. Matriz de cobertura efetivamente comprovada

| PR | Arquivos no PR | Já idênticos na main | Preservação adicional nesta PR Draft | Exclusivos históricos que continuam apenas no PR |
| --- | ---: | ---: | ---: | ---: |
| #226 — MVP B1 e evidências de construção | 31 | 5 | 5 | 21 |
| #230 — identidade visual VIS-01 | 3 | 0 | 1 | 2 |
| #231 — aplicação visual VIS-02 | 3 | 2 | 1 | 0 |
| #232 — auditoria VIS-03 | 1 | 1 | 0 | 0 |
| #233 — correção CH06 | 2 | 2 | 0 | 0 |
| #234 — DOC-R3 editorial e geradores | 4 | 3 | 0 | 1 |
| #235 — auditoria de indicadores | 1 | 1 | 0 | 0 |
| #236 — VIS-04 final | 2 | 2 | 0 | 0 |
| **Total** | **47** | **16** | **7** | **24** |

**Leitura correta:** a PR #237 reuniu 16 arquivos idênticos ao HEAD dos PRs originais; **não 47**. Esta PR Draft acrescenta sete arquivos sem modificá-los, e preserva uma **matriz por arquivo e SHA** dos demais 24. Antes da integração desta PR, a `main` continua tendo apenas os 16 arquivos copiados; nenhuma aprovação nova de execução/produção é inferida.

## 2. Sete fontes selecionadas para inclusão canônica

| PR | Caminho original preservado nesta branch | Razão para retenção |
| --- | --- | --- |
| #226 | `PAINEL/sad_mvp_m303_serv_guard_contract.json` | Contrato declarativo restrito da guarda de população M3-03, com limites de persistência/COM; não é aplicação automática nem contrato C3 aprovado |
| #226 | `docs/project/mvp-c2-native-acceptance-owner-approved-2026-11-07.md` | Decisão aprovada **somente de escopo** sobre testes de filtros nativos; evita confundir aceite de critérios com PASS físico |
| #226 | `docs/project/mvp-f04-2018-versus-fixed-lt-201912-gui-protocol-2026-11-07.md` | Evidência do conflito entre seleção anual 2018 e indicador de leitos fixo em dezembro de 2019; não ocultar blocker histórico |
| #226 | `docs/project/mvp-three-sheets-implementation-2026-11-07.md` | Documenta materialização experimental dos três painéis/nove objetos e os limites do builder |
| #226 | `docs/project/mvp-three-sheets-visual-review-2026-11-07.md` | Contém diagnósticos técnicos de M3-01/M3-03 e das correções na construção; complementa o closeout final |
| #230 | `docs/project/sad-vis-01-approved-vis-02-handoff-2026-11-09.md` | Prova documental da aprovação inicial do design visual, sem extrapolar para produção |
| #231 | `docs/project/sad-vis-02-controlled-application-runbook-2026-11-09.md` | Instruções efetivas de aplicação do fundo e da apresentação em cópia protegida |

**Verificação:** 7/7 desses arquivos foram copiados **byte a byte no sentido do Git blob SHA**: os SHA dos blobs lidos na nova branch são exatamente os SHA dos respectivos PRs de origem. O verificador de links relativos deste conjunto constatou **10/10 referências internas resolvidas** dentro da branch candidata. As alterações não introduzem QVW, QVD, PDF, dados nem código novo de produção.

**Qualificação:** são **documentos históricos e contratos de protótipo**. Nenhum deles sobrepõe a decisão acadêmica final, o `current-state.md`, a semântica da primeira entrega ou transforma `PASS_RESTRICTED` em `PROD_APPROVED`.

## 3. Vinte e quatro arquivos históricos que NÃO serão incorporados automaticamente

- **PR #226 (21 arquivos):** propostas iniciais já superadas, protocolos F01/F02/F03/F04 e persistência, mapeamento COM não homologado, contrato nativo `DRAFT_COM_MAPPING_UNVERIFIED` e executores de ensaios específicos (`Inspect-*`, `Invoke-SadM1IntegratedTempQvw.ps1`, `New-*`, `Test-*` e inventário M1). A documentação de evidências e os critérios finais essenciais estão preservados; os testes não serão reiniciados para a segunda entrega.
- **PR #230 (2 arquivos):** plano visual inicial e bootstrap VIS-01, ambos de natureza histórica/de handoff, superados pelo aceite e pela VIS-04.
- **PR #234 (1 arquivo):** `tools/build_sad_doc_r3_replacement_pages.py`, gerador da prévia de oito páginas **sem teste de execução a partir do commit original**. O PDF final de 98 páginas e seus scripts aplicados foram registrados na `main` pela #237; não apresentar o gerador antigo como reprodução homologada.

**Os 24 arquivos NÃO foram apagados.** Permanecem no histórico dos PRs e nas branches remotas identificadas por SHA no inventário JSON. Um fechamento de PR **não é merge** e tampouco exclui a branch. **Não autorizar a exclusão dessas refs antes de criar/verificar backup Git que retenha os commits exclusivos e de decidir se algum script histórico deve receber arquivamento adicional.** O presente gate não atesta retenção permanente dos 24 blobs após uma futura limpeza de refs; o inventário aponta as fontes imutáveis para esse procedimento.

### Risco importante de reprodutibilidade

O script `tools/Build-SadMvpThreeSheetsTemp.ps1` presente na `main` reproduz somente uma etapa experimental anterior. **Não foi comprovado que, executado isoladamente, recrie a QVW VIS-04 final**, incluindo guardas configuradas manualmente, revisões de layout e backgrounds. A cópia QVW final deve ser preservada **fora do Git**, com SHA-256 e backups verificados, conforme [registro da entrega](../academic/final-delivery-record-2026-11-10.md). Não tratar scripts antigos como garantia de reconstrução integral ou como backlog obrigatório.

## 4. Links quebrados identificados e reparados nesta PR Draft

Foi encontrado um problema real na `main`: o documento `docs/project/mvp-evidence-and-contract-gates-consolidation-2026-11-07.md`, incorporado pela #237, referenciava por caminhos relativos cinco documentos que permanecem exclusivos na #226. Nesta branch, alteramos **somente os cinco destinos dos links** para URLs com o SHA fixo do HEAD da PR #226 (`0e7eb3c12c04bbdaf3708e3f3998f7dd94d4c0b6`):

1. `mvp-contract-deltas-and-m1-readiness-2026-11-07.md`
2. `mvp-native-filter-smoke-protocol-2026-11-07.md`
3. `mvp-native-filter-residence-f02-protocol-2026-11-07.md`
4. `mvp-native-filter-residence-leitos-f03-protocol-2026-11-07.md`
5. `mvp-f03-lt-guard-ui-temp-2026-11-07.md`

O documento alterado **não deve mais ser descrito como Git-blob-idêntico** à cópia de #226; antes da correção era `c09314b080d405dc6dd5581170cea533fdf109b5`, depois do ajuste exclusivamente dos links ficou `16e7788782a6d864d39ac2b4813699c078a88e41`. Não foram editados oráculos, medidas, granularidades ou vereditos. Essas URLs apontam para commit específico; **backup de refs continua obrigatório** antes de qualquer exclusão de branches históricas.

## 5. Decisão sobre cada PR e autorização pendente

| PR | Status após a integração desta PR candidata | Fechamento sem merge recomendado? |
| --- | --- | --- |
| #232, #233, #235, #236 | 100% dos arquivos já na main | Sim, **após autorização explícita** |
| #231 | 3/3 presentes após copiar runbook | Sim, **após merge desta PR e autorização** |
| #230 | decisão VIS-01 consolidada; plano/bootstrap históricos mantidos na referência antiga | Sim, **após merge desta PR e autorização**, com nota de preservação histórica |
| #234 | versão final e dois patches preservados; gerador experimental histórico não integrado | Sim, **após autorização** e sem alegar execução desse gerador |
| #226 | documentação decisiva e contrato específico incorporados; 21 arquivos experimentais não integrados | **Condicional:** fechar apenas explicitando 21 arquivos históricos e **manter a branch até backup de retenção** |

**Nenhuma PR foi fechada nesta execução.** A ausência de um arquivo na `main` não implica inutilidade; indica que não integra a documentação canônica ativa e que requer uma decisão de retenção antes de exclusões.

## 6. Próximo passo e condição de parada

1. Revisar esta PR Draft, conferir o conjunto **7 arquivos + auditoria JSON/Markdown + 5 destinos de links reparados** e autorizar ou não **somente seu merge**.
2. Após merge, conferir HEAD/paths/blobs. Só com **autorização separada** encerrar os oito PRs, comentando decisão individual e limites.
3. Antes de excluir qualquer branch desses PRs, executar `Get-SadBranchCleanupDryRun.ps1` em clone local atualizado e produzir um backup verificável de commits/refs (inclusive dos arquivos exclusivos); exclusão nominal em lote distinto, nunca agora.

**STOP:** esta auditoria não executa QlikView, não reabre C2/C3/C4, não cria indicadores, não altera QVD/QVW ou PDF, não faz merge, fechamento ou exclusão.
