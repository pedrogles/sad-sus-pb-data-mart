# Repository hygiene — SAD SUS PB — 08/10/2026

**Estado: DRY-RUN / REVIEW — SEM EXCLUSÕES, SEM MERGE.**  
**Escopo:** `pedrogles/sad-sus-pb-data-mart`. Inventário remoto feito na `main` antes da criação da branch `chore/repository-hygiene-2026-10-08`.

## 1. Objetivo e limites

Conservar **todas as decisões acadêmicas, o modelo dimensional, a arquitetura QlikView 12, scripts funcionais, dados locais e evidências técnicas**. Eliminar contexto histórico das rotas de leitura dos agentes **sem eliminar o histórico**. Não alterar o T29 para PASS completo nem gerar referência de leitos ou QVD nesta manutenção.

Mudanças da branch de higiene:
- atualização de `README.md` à Fase III real e ao próximo gate;
- `.gitignore`: `__pycache__/`, `*.py[cod]`, `.venv/`, `venv/` e arquivo de inventário temporário `branch-hygiene-preflight-*.txt`;
- `docs/project/current-state-chronology-2026-10-08.md`: **cópia literal da cronologia anterior**, incluindo hashes, resultados de reload e validações; blob de origem `953d49978b2cb920dfc4991481c8be7c6c880ba4`;
- `docs/project/current-state.md`: reduzido a estado operacional e links para provas, sem excluir decisões do arquivo de origem;
- `AGENTS.md`: instruções permanentes e checkpoints atuais; históricos específicos permanecem em `docs/discovery`, cronologia e Git.

**Não mudou:** `EXTRACAO/ext_main.qvs`, `TRANSFORMACAO`, `PAINEL`, `tools/`, datasets, esquema dos fatos/dimensões, `docs/academic/`, `docs/discovery/`, scripts de auditoria ou refs remotas existentes.

## 2. Inventário de branches e PRs — antes da higiene

- **77 branches remotas**: `main` e **76 branches de trabalho antigas**.
- **68 PRs fechados**: **67 integrados**, **1 fechado sem merge (PR #27)**.
- **0 PRs abertos**, **0 issues abertos** no momento da consulta.
- Após criar a branch da presente revisão, passam a existir **78 refs remotas**: 76 antigas + `main` + `chore/repository-hygiene-2026-10-08`. **A branch da própria higiene nunca é candidata no plano corrente.**
- Os **HEADs SHA-1 das 76 refs antigas foram consultados** com `compare_commits(base=branch, head=main)`; como a `main` recebeu squash merges, muitos HEADs mostram `diverged` apesar de um PR correspondente estar `merged`. Isso **não** prova que há trabalho novo pendente.
- A captura de SHAs e a confirmação de igualdade HEAD atual ↔ SHA do PR precisam ser **repetidas e persistidas em manifesto próprio no preflight imediatamente antes da exclusão**, pois refs podem mudar entre a Discovery e a aplicação.

| Grupo | Qtd. | Avaliação antes do APPLY |
|---|---:|---|
| Branch vinculada a PR **integrado** (#1–#68 exceto #27) | 67 | **CANDIDATE_ONLY** — confirmar que HEAD atual é o `head_sha` daquele PR integrado; verificar inexistência de uso ativo/dependência e captura de SHA para rollback |
| Sem PR correspondente, HEAD integralmente contido na `main` | 3 | **CANDIDATE_ONLY** — conferir SHA no momento do APPLY |
| Sem PR, HEAD divergente da `main` | 5 | **HOLD** — investigar se existe trabalho único ou revisão substituída |
| PR #27 fechado **sem merge** (`fix/phase-3-ibge-biff-sheet-encoding`) | 1 | **HOLD** — comparar com PR #28 integrado, sem presumir igualdade de implementação |
| **Total** | **76** | **EXCLUSÕES AUTORIZADAS: 0** |

### Branches sem PR que exigem decisão especial

**Três completamente contidas na main (no dry-run):**

- `readiness/b8-hash-pass` — HEAD `c5e470194cd2f6084f57c68bb24af32c7e3dfa81`;
- `readiness/boundary-8-local-preflight` — HEAD `bff1dba83f0033e3ff5618402a65f7ab9fc8333c`;
- `readiness/boundary-8-qlik-smoke-pass` — HEAD `47c9e678c5b68410a3eb73e2b49226f4528dc8b7`.

**Cinco branches divergentes sem PR identificado, manter em HOLD:**

- `fix/readiness-hash-ps51-compat` — HEAD `9f6d0f1ef6c24b62e9e5c251e72846e818733866`;
- `fix/phase-3-ibge-population-notes` — HEAD `4429ef4a0224fbc9208e6fa62a6a35f686e0c863`;
- `fix/phase-3-cid10-dual-diagnostic` — HEAD `9da0b13a595ac9cf2a2a6d2857a66a9cbf9528f8`;
- `fix/phase-3-cid10-dual-diagnostic-v2` — HEAD `5e4bb966177e350e412dca58e777a4932f74b22f`;
- `fix/phase-3-cid10-dual-diagnostic-v3` — HEAD `2a845251a0235859eaf82d21e5b263bd9574fc7b`.

**Branch PR #27 não integrado:** `fix/phase-3-ibge-biff-sheet-encoding` — HEAD `a80198f894340f4c071165700fbcac269d6681db`; a PR #28 com `fix/phase-3-ibge-biff-sheet-encoding-v2` foi integrada. Substituição plausível, mas precisa comparar o conteúdo/diff antes de decidir exclusão.

## 3. Gate fail-closed antes de apagar qualquer ref remota

1. **Aprovação explícita do usuário** sobre cada classe/manifesto de exclusões. Sem ela, o plano **não** autoriza `git push --delete` nem uso de API de exclusão.
2. Obter novamente `git ls-remote --heads origin` e registrar o **nome + SHA** de todas as 76 refs antigas antes de executar. Confirmar `main` e branch de higiene como exceções absolutas.
3. Para cada uma das 67 branches ligadas a PR integrado: conferir `merged=true`, PR, nome da branch e `head_sha` igual à ref atual. Se divergir, **HOLD**; não confiar em nomes nem apenas em `diverged`.
4. Para as 3 contidas: `merge-base --is-ancestor branch main` após `git fetch --prune`, e conferir SHA da branch.
5. Preservar as 6 refs em HOLD (5 sem PR/divergentes + PR #27) até resolução individual e autorização separada.
6. Aplicar em lotes pequenos, **SHA/HEAD novamente conferido imediatamente antes do delete**; registrar sucesso ou falha por ref. Se alguma verificação divergir, interromper o lote; sem force-push, sem exclusão de `main`, sem alterações aos PRs fechados.
7. Rollback possível com `git push origin <sha>:refs/heads/<branch>`, desde que o SHA original esteja registrado e o objeto continue disponível; se necessário, primeiro recuperar o objeto de clone que contenha o commit ou de ref backup previamente criado.

**Comandos para captura local do manifesto antes de qualquer APPLY** (na raiz do repositório, sem exclusão):

```powershell
git fetch origin --prune
git ls-remote --heads origin |
    Out-File -Encoding utf8 .\branch-hygiene-preflight-2026-10-08.txt
git status --short
```

O arquivo temporário deve ser revisto e **não adicionado ao Git inadvertidamente**. Este documento registra o plano; **nenhuma execução de delete remoto ocorreu**.

## 4. Arquivos e scripts — decisão conservadora

- **Manter operacionais:** `EXTRACAO/ext_main.qvs`, `tools/dbc_to_csv.py`, materializadores e scripts versionáveis de referência; `TRANSFORMACAO/transf_main.qvs`, `PAINEL/painel_main.qvs`.
- **Manter como evidência de investigação (não executar por padrão):** sondas históricas CNES, comparadores HTML, diagnósticos CID-10, perfis pontuais e ferramentas de readiness. Avaliar remoção só se houver duplicação demonstrada e teste de dependência.
- **Não reestruturar diretórios `BASE`, `EXTRACAO`, `TRANSFORMACAO`, `PAINEL`, `docs` ou `tools`.**
- **Não versionar:** DBC, QVD, PDFs grandes de entrada, planilhas locais, datasets e artefatos derivados.

## 5. Retomada da Fase III — após higiene

A primeira entrega impressa permanece prioritária. Os gates já encerrados não devem ser reabertos sem mudança real de fonte/script.

| Gate | Estado | Próxima ação |
|---|---|---|
| III-A Saúde, III-B IBGE, III-C1 normativas, III-C2 CID-10/T28, III-C3 SIGTAP/T27 | **PASS** | Preservar evidência de reload Qlik e QVD |
| III-C4 / leitos | **57/57 pares / 35.518/35.518 LT cobertos** pelo retrato de 09/2019 | Submeter a **decisão explícita** de uso **descritivo** com limitação temporal; nunca afirmar vigência mensal nem T29 integral PASS |
| T29 histórico | **NOT APPROVED** | Manter limitação escrita; aprofundar apenas em caso de impacto analítico ou demanda acadêmica |
| Encerramento da Fase III | **PENDENTE** | Revisar matriz do Boundary 7, particularmente saída de referência CNES, chaves e validações restantes; formalizar autorização de gate antes de transformar |

**A higiene não autoriza criar `REF_TIPO_LEITO.qvd` nem implementar `TRANSFORMACAO`; essas ações exigem decisão de escopo e gate próprios.**

## 6. Critérios de aceitação da higiene

- `main` e documentação acadêmica são preservadas;
- estado operacional acessível rapidamente em `AGENTS.md` e `current-state.md`;
- cronologia anterior preservada integralmente, com SHA de origem e rotas de leitura claras;
- nenhuma exclusão antes de aprovação;
- nenhum script de produção, dado de origem, QVD ou modelagem alterado;
- atualização de `.gitignore` não apaga `__pycache__` local, apenas impede rastreamento futuro;
- próximo checkpoint da Fase III descrito objetivamente.

**STATUS: DRY-RUN DOCUMENTADO / PR DE HIGIENE PARA REVISÃO / DELETE REMOTO NÃO AUTORIZADO.**

**ATUALIZAÇÃO OPERACIONAL DEPOIS DO MERGE — 08/10/2026:** PR #69 de higiene documental foi efetivamente integrado à `main` por squash (`2de6a53725d6b2eb29b847fd0c8318ede8ef3283`). Posteriormente, **o usuário aprovou expressamente a exclusão controlada das 70 candidatas**, desde que os SHAs sejam reconfirmados e as 6 HOLD, `main` e a branch de higiene permaneçam protegidas. Portanto, a linha histórica acima sobre ausência de autorização refere-se **apenas ao dry-run original**, não ao estado atual.

**EXECUÇÃO REMOTA: AINDA NÃO REALIZADA.** O conector GitHub instalado não disponibiliza exclusão de branches; ele permite atualização de refs, que **não deve ser confundida com exclusão**. Foi preparado um script PowerShell local de uso único, com `-Apply` explícito, que: (i) valida `origin` e as 78 refs, (ii) consulta em uma requisição os PRs GitHub #1–69, (iii) exige 67 PRs antigos integrados com HEAD exatamente igual, (iv) prova três ancestrais de `main`, (v) preserva 6 HOLD, `main` e branch de higiene, (vi) salva manifesto e log em `BASE/REFERENCIAS` (ignorado), (vii) utiliza `git push --force-with-lease=<ref>:<sha>` individualmente, interrompendo na primeira divergência, (viii) verifica 8 refs remotas finais.

**Gate de fechamento:** somente após o usuário executar localmente e enviar saída `POSTCHECK=PASS REMOTE_BRANCHES=8 DELETED=70 PROTECTED=8` (ou o inventário real resultante) a limpeza poderá ser marcada como APPLIED. Enquanto isso o status é `DELETE_AUTHORIZED / APPLY_PENDING_LOCAL`. Se houver erro ou mudança de SHAs, interromper e reclassificar, **não forçar**. A execução também precisa de acesso de escrita à `origin` na máquina do usuário; em caso de negação, nenhum sucesso deve ser alegado.

**Fase III:** a execução da higiene não aprova T29 histórico, não reabre os capítulos acadêmicos e não autoriza materialização de `REF_TIPO_LEITO.qvd` antes da decisão de uso descritivo e do gate específico de QlikView. A seguir, retomar apenas os gates restantes da Fase III de acordo com Boundary 7.




### Execução local — primeiro dry-run bloqueado por PowerShell 5.1 (08/10/2026)

**FATO VERIFICADO:** usuário executou `git pull --ff-only origin main` com sucesso até `1e249361`. Ao executar o primeiro script `sad_branch_hygiene_approved_2026-10-08.ps1`, o comando `git fetch origin --prune` retornou mensagem informativa no **stderr** ("From https://github.com/...") e o **Windows PowerShell 5.1**, sob `$ErrorActionPreference='Stop'`, levantou `NativeCommandError` na linha 32. O script interrompeu **antes de consultar PRs, construir manifesto ou executar qualquer exclusão**; nesse ensaio, `DELETED=0` e nenhum resultado `PREFLIGHT=PASS` foi produzido.

**Correção local preparada:** `sad_branch_hygiene_approved_2026-10-08_v2.ps1` executa comandos Git via `Start-Process` com stdout/stderr em arquivos temporários e valida explicitamente `ExitCode`, evitando o erro espúrio do pipeline de stderr no PowerShell 5.1. Os caminhos de `git rev-parse`, `git merge-base` e rechecagem individual `git ls-remote` usam o mesmo mecanismo. **Mantidos**: `-Apply` explícito, inventário/manifesto de SHA antes de exclusão, 67 branches PR integradas, 3 ancestrais, 6 HOLD, `main` e branch de higiene protegidas, comparação `--force-with-lease` a cada ref, abort em qualquer divergência e pós-checagem de 8 refs. **Script v2 não executado no Windows até nova evidência do usuário.**

**Próxima ação:** executar primeiro o novo script **v2 SEM `-Apply`**, verificar `PREFLIGHT=PASS DELETE_CANDIDATES=70 HOLD=6`, somente então executar **v2 `-Apply`** nos termos da aprovação existente. Em falha, enviar a saída; não assumir `DELETED=70` nem reexecutar `-Apply` cegamente.


### Segundo dry-run — resposta de PRs mal interpretada na v2 (08/10/2026)

**FATO VERIFICADO — PowerShell enviado pelo usuário:** após `git pull --ff-only origin main`, a v2 passou do `PRECHECK: fetching origin; no remote changes`, mas interrompeu em sua linha 106: `Expected 69 PRs (#1-#69); got 1. Abort.`. Portanto **não chegou ao plano, ao manifesto de rollback ou ao bloco protegido por `-Apply`; nenhuma exclusão foi feita nesse ensaio**.

**HIPÓTESE TÉCNICA:** `$prs = @(Invoke-RestMethod ...)` pode devolver um único objeto contendo o array em Windows PowerShell 5.1, em vez da coleção de 69 objetos esperada. A mensagem isolada não comprova se o envelope era um array aninhado ou se o servidor de fato devolveu um item.

**Mitigação preparada — script `sad_branch_hygiene_approved_2026-10-08_v3.ps1`:** recuperar resposta por `Invoke-WebRequest -UseBasicParsing`, confirmar que o corpo é uma lista JSON, fazer `ConvertFrom-Json -InputObject` e normalizar explicitamente a coleção, com diagnósticos de contagem e abort sem delete. Mantidos 78 refs pré-higiene, 67 PRs integrados+3 ancestrais, seis HOLD, dois protegidos estruturais, `-Apply` explícito, `--force-with-lease`, manifesto pré-delete e verificação pós. **Ainda não há evidência de dry-run PASS da v3 nem exclusão remota executada.** Pedir ao usuário **somente dry-run da v3** primeiro, depois avaliação do resultado; não instruir `-Apply` diante de falha.
