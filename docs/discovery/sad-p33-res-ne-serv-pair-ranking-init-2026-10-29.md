# P3.3 — Ranking de pares RES≠SERV observados (2017–2019)

**Gate:** `SAD-P33-SIH-RES-NE-SERV-PAIR-RANKING-READONLY-01`  
**Estado inicial (histórico):** `SCRIPT_VERSIONED / NOT_RUN / READY_FOR_LOCAL_E1`, 29/10/2026. O fechamento local posterior está descrito no adendo e no [closeout P3.3](sad-p33-res-ne-serv-pair-ranking-closeout-2026-10-29.md).  
**Baseline:** `main@ce9a1f5ee1f3221a3b64c93b692402d768396148`, PR #191 (P3.2) **merged**.  
**Roteamento:** ChatGPT GPT-6 + GitHub (preparação; esforço não exposto); operador/PowerShell/Python local para execução. Escalonar a Codex Local apenas se houver erro concreto. QlikView/COM não aplicáveis.

## Contrato delimitado e controles

- **Objetivo:** ranking decrescente de `sum(qtd_internacao)` por par direcionado **observado** de municípios RES≠SERV no triênio 2017–2019, com detalhe anual de pares-ano observados. Empates por código RES e depois SERV em ordem lexical.
- **Origem:** E1 `C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv`, imutável; SHA-256 `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`. Schema `competencia;ano;municipio_res;municipio_serv;qtd_registro_aih;qtd_internacao;qtd_continuidade`. Grão agregado E1: competência × ano × RES × SERV.
- **Reuso:** `tools/validate_sad_p13_serv_ranking01.py` para pins/primitivas, P3.1 e P3.2 somente como controles encerrados, **sem reexecutar seus validadores**. Executor P3.3 `tools/validate_sad_p33_res_ne_serv_pairs01.py` commitado **antes** da execução em `bd4454c5ff088c9d41873de8c7211987f73d322a`.
- **Oráculos restritos:** E1 de 36 competências, 30.255 grupos únicos, totais de novas por ano `2017=183532`, `2018=183311`, `2019=188246`, triênio `555089`. P3.2: `sum(qtd_internacao)` RES≠SERV = **260.454**. Testemunho exploratório da direção `251370→250750` = **12.176** no triênio, **a conferir pelo gate**. Quantidades distintas de pares e Top 10 **não são previamente conhecidas** e não devem ser inventadas.
- **Semântica:** preservar pares com linha mesmo que novas internações somem zero (continuidades positivas). Ausência de par/ano não é zero comprovado; detalhe anual contém **somente** combinações observadas. `IDENT=5` é continuidade, não nova. RES≠SERV não demonstra viagem de paciente, distância, pessoas únicas ou fluxo causal; externos à PB podem estar na fonte sem receber denominador populacional PB.
- **Invariantes:** QlikView 12; BASE→EXTRACAO→QVD→TRANSFORMACAO→QVD→PAINEL; três fatos, oito dimensões e Boundary 7 inalterados. Nenhuma escrita em E1, QVD/QVW/QVS, modelo, chaves ou `main`.
- **Escopo tocável:** apenas script, este protocolo e atualização factual compacta do `current-state.md` na branch de P3.3. **RUNTIME_TEMP:** não aplicável. **EVIDENCE_ROOT:** `C:/Users/pedro/SAD_EVIDENCIAS/P33_20261029_01/`, novo, persistente, fora da fonte e do Git.
- **Orçamento:** uma execução local, uma cópia E1 com LF adicional para negativo integrado, readback integral, SHA pré/pós, manifesto. Sem reexecutar gates anteriores ou entrar em P3.4.

**PASS_RESTRICTED:** pin E1, schema, 36 competências e 30.255 grãos únicos; decomposição AIH e totais E1; exclusivamente RES≠SERV em pares observados; soma dos pares=260.454; testemunho=12.176; reconciliações mensais/anuais/triênio nas três medidas; Top10+demais; ordenação determinística; zeros observados mantidos e ausências não imputadas; dois CSVs completos com readback; negativa em cópia rejeitada; original preservado.

**BLOCKED:** ausência do E1, branch suja/divergente, diretório de evidência ocupado, script diferente do commit ou incapacidade de coletar evidências. **INCONCLUSIVE_HARD_STOP:** divergência SHA, schema, universo, total, testemunho, classificação ou readback. Não alterar fonte ou oráculos para forçar PASS.

Arquivos fora do Git esperados: `p33_ranking_res_ne_serv_trienio.csv`, `p33_pairs_annual_observed.csv`, `p33_audit.json`, `execution.log`, `negative_e1_altered.csv`, `sha256_manifest.json`. A negativa é integrada no processo de execução positiva, não um processo separado com exit=2.

## PowerShell — executar somente uma vez após preflight

```powershell
$ErrorActionPreference = "Stop"
$repo = "C:\Users\pedro\Documents\programming\sad-sus-pb-data-mart"
$branch = "test/sad-p33-sih-res-ne-serv-pair-ranking-readonly-01"
$e1 = "C:\Users\pedro\SAD_EVIDENCIAS\AE01_20261027_02\sih_fluxo_competencia.csv"
$out = "C:\Users\pedro\SAD_EVIDENCIAS\P33_20261029_01"
$pin = "F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615"
$codeCommit = "bd4454c5ff088c9d41873de8c7211987f73d322a"
if (-not (Test-Path -LiteralPath $repo -PathType Container)) { throw "REPO_MISSING" }
$status = @(git -C $repo status --porcelain)
if ($LASTEXITCODE -ne 0) { throw "STATUS_FAILED" }
if ($status.Count -gt 0) { throw "WORKTREE_NOT_CLEAN" }
git -C $repo fetch origin
if ($LASTEXITCODE -ne 0) { throw "FETCH_FAILED" }
git -C $repo show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) {
    git -C $repo switch $branch
} else {
    git -C $repo switch --track "origin/$branch"
}
if ($LASTEXITCODE -ne 0) { throw "SWITCH_FAILED" }
git -C $repo pull --ff-only origin $branch
if ($LASTEXITCODE -ne 0) { throw "PULL_FF_FAILED" }
git -C $repo merge-base --is-ancestor origin/main HEAD
if ($LASTEXITCODE -ne 0) { throw "BRANCH_BASE_DRIFT" }
if (-not (Test-Path -LiteralPath $e1 -PathType Leaf)) { throw "E1_MISSING" }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $e1).Hash -ne $pin) { throw "E1_SHA_MISMATCH" }
if (Test-Path -LiteralPath $out) { throw "EVIDENCE_DIR_ALREADY_EXISTS" }
python -B "$repo\tools\validate_sad_p33_res_ne_serv_pairs01.py" `
    --e1 "$e1" `
    --output-dir "$out" `
    --source-commit $codeCommit
if ($LASTEXITCODE -ne 0) { throw "P33_VALIDATOR_NONZERO" }
```

**Atenção ao PowerShell:** As três linhas finais usam o caractere de continuação de linha PowerShell (acento grave), representado acima por `; após publicação esse caractere é o próprio `. Não usar `git clean`, `reset --hard`, `stash -u`, force push, nem apagar evidências para repetir o gate.

## Handoff e STOP

**Estado do protocolo antes da execução:** `GATE_PASS=False (NOT_RUN)`; após execução, ver adendo abaixo. Não repetir o gate. P3.4 é somente candidato futuro.
## Adendo pós-execução — 29/10/2026

Execução local única reportada em `2026-10-29T20:44:44.730818+00:00`: `PASS_RESTRICTED`, `exit_code=0`, 3.108 pares observados, 260.454 internações novas RES≠SERV, Top 10 de 55.353 e testemunho 12.176 reconciliado. O transcript apresenta SHA de E1 preservado, readbacks e negativo integrado em cópia; **não houve auditoria remota dos arquivos Windows**. A documentação de prova e limites está no [closeout P3.3](sad-p33-res-ne-serv-pair-ranking-closeout-2026-10-29.md). `GATE_PASS=True` local/restrito; `PR_MERGED=False`, `PRODUCTION_APPROVED=False`. **STOP P3.3 cumprido**: o bloco de PowerShell acima passa a ser histórico/reprodutivo, não uma solicitação de reexecução.
