# P3.2 — RES=SERV versus RES≠SERV anual (2017–2019) | Protocolo READ-ONLY

**Gate:** `SAD-P32-SIH-RES-SERV-EQUALITY-ANNUAL-READONLY-01`  
**Estado de preparação original (histórico):** `SCRIPT_VERSIONED / EXECUTION_NOT_RUN / READY_FOR_LOCAL_E1` (29/10/2026). Naquele momento **não era PASS**; a execução posterior está no adendo e no closeout.  
**Proveniência Git:** criada a partir de `main@6f35f86b1d672949d9921cb948463000e02aacdd`. O [PR #190 (P3.1)](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/190) foi integrado por squash em `main@8a3144263e424078dbab6038d8a8b7089e3a40b2`; P3.2 foi sincronizada por merge commit `cd648d7ec52244ada62408031f12f7ee3b71f1d7`, sem force push e sem alterar `main`. A árvore de P3.2 conserva exclusivamente os dois arquivos novos na comparação com a `main`.

## Roteamento e contrato de execução

- **Objetivo único:** classificar cada linha agregada SIH/RD E1 pelo teste textual `municipio_res == municipio_serv`, agregar `SUM(qtd_internacao)` por **ano de competência × classe** e reconciliar o triênio. Não estimar deslocamento individual.
- **Fontes superiores consultadas na `main`, em ordem:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, escopo analítico aceito D1–D3, matriz de fontes e política de roteamento. Boundary 7 preservado. P3.1 local e P1.3 são evidências reutilizadas, não gates a repetir.
- **Agente da preparação:** ChatGPT + GitHub, GPT-6; esforço exato da sessão não exposto. **Executor proposto:** Python no Windows local, operador/ Codex Local somente se necessário; modelo/esforço efetivos a registrar na execução. Não pressupor acesso do ChatGPT ao filesystem Windows.
- **Fonte de entrada imutável:** `C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv` (E1), SHA-256 esperado `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`, grão `competencia × ano × municipio_res × municipio_serv`, 30.255 registros. Nome do arquivo e pin são do gate E1 previamente validado, **não bytes verificados nesta preparação remota**.
- **Schema fechado:** `competencia;ano;municipio_res;municipio_serv;qtd_registro_aih;qtd_internacao;qtd_continuidade`. Controle: `qtd_registro_aih = qtd_internacao + qtd_continuidade`; `IDENT=5` não é internação nova.
- **Validador versionado antes de qualquer execução:** `tools/validate_sad_p32_res_serv_equality01.py`, commit inicial `d0437284dbf709efffa6def5051f4fb37b5d9651` e correção de classe mensal ausente `7cab8c12eaf2d6424dceb52f64aafaf50d623d2c` (**revisão executável proposta**). Reutiliza as constantes/funções do `tools/validate_sad_p13_serv_ranking01.py` na `main`; sem reexecutar o ranking P1.3.
- **Escopo tocável:** script, este protocolo e snapshot operacional na branch P3.2. E1, QVD, QVW, QVS, modelo acadêmico e `main` **somente leitura**. Atualização documental não constitui execução.
- **RUNTIME_TEMP:** não aplicável. **EVIDENCE_ROOT candidato:** `C:/Users/pedro/SAD_EVIDENCIAS/P32_20261029_01/` (novo e persistente, separado da pasta original E1 e fora do Git). Confirmar inexistência e espaço antes de executar.
- **Orçamento:** uma execução positiva, uma cópia E1 alterada (LF anexado) para negativa integrada, readback CSV e hashes; investigar falha concreta antes de propor segunda tentativa. Nenhuma chamada QlikView/COM ou P3.3/P3.4.

## Oráculos, PASS e STOP

- **PASS_RESTRICTED (somente numérico):** arquivo E1 pinado; schema, 36 competências, unicidade e decomposição corretos; seis linhas (três anos × duas classes), sem pares descartados; somas anuais 2017 `183532`, 2018 `183311`, 2019 `188246`; total `555089`; classes do triênio `RES_EQ_SERV=294635` e `RES_NE_SERV=260454` (46,92% para a segunda classe, arredondado); reconciliação mensal/anual/triênio nas três medidas; CSV readback; cópia negativa rejeitada; fonte preservada. Esses valores são **controles históricos exploratórios a confrontar**, não novo resultado validado nesta preparação.
- **BLOCKED:** E1 original inacessível no Windows local, checkout divergente, erro de ambiente ou evidência essencial ausente. A dependência de integração do P3.1 está resolvida. **HARD_STOP/INCONCLUSIVE:** SHA, schema, soma, grão, medida, período ou classe divergente. Nunca corrigir dados para forçar PASS.
- **Entregáveis derivados fora do Git:** `p32_res_serv_annual.csv` (6 linhas), `p32_audit.json`, `execution.log`, `negative_e1_altered.csv`, `sha256_manifest.json`. O negativo é uma rejeição de cópia **dentro do processo**, não um segundo processo independente com `exit=2`.
- **Estado anterior à execução:** `GATE_PASS=False (NOT_RUN)`, `PR_MERGED=False`, `PRODUCTION_APPROVED=False`. Critério do protocolo histórico, superado somente pelo resultado local restrito registrado no closeout.

## Execução local — checkout seguro e um único gate

A integração P3.1 e a sincronização remota P3.2 foram verificadas. No Windows, conferir primeiro o estado local limpo, o commit remoto, o pin E1 e a inexistência do diretório de evidências. O script recusa divergência de seus arquivos versionados contra o commit informado. **Não executar se qualquer preflight falhar.**

```powershell
$ErrorActionPreference = "Stop"
$repo = "C:\Users\pedro\Documents\programming\sad-sus-pb-data-mart"
$branch = "test/sad-p32-sih-res-serv-equality-annual-readonly-01"
$e1 = "C:\Users\pedro\SAD_EVIDENCIAS\AE01_20261027_02\sih_fluxo_competencia.csv"
$out = "C:\Users\pedro\SAD_EVIDENCIAS\P32_20261029_01"
$expectedSource = "F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615"
$codeCommit = "7cab8c12eaf2d6424dceb52f64aafaf50d623d2c"
if ((git -C $repo status --porcelain) -ne $null) { throw "WORKTREE_NOT_CLEAN" }
git -C $repo fetch origin
if ($LASTEXITCODE -ne 0) { throw "FETCH_FAILED" }
git -C $repo switch $branch
if ($LASTEXITCODE -ne 0) { throw "SWITCH_FAILED" }
git -C $repo pull --ff-only origin $branch
if ($LASTEXITCODE -ne 0) { throw "FF_ONLY_FAILED" }
git -C $repo merge-base --is-ancestor origin/main HEAD
if ($LASTEXITCODE -ne 0) { throw "P32_NOT_BASED_ON_CURRENT_MAIN" }
if (-not (Test-Path -LiteralPath $e1 -PathType Leaf)) { throw "E1_NOT_FOUND" }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $e1).Hash -ne $expectedSource) { throw "E1_SHA_MISMATCH" }
if (Test-Path -LiteralPath $out) { throw "EVIDENCE_DIR_ALREADY_EXISTS" }
python -B "$repo\tools\validate_sad_p32_res_serv_equality01.py" `
    --e1 "$e1" `
    --output-dir "$out" `
    --source-commit $codeCommit
if ($LASTEXITCODE -ne 0) { throw "P32_VALIDATOR_NONZERO" }
```

**Atenção:** `git switch` deve ser usado somente se `git status --short` estiver limpo e a branch local não contiver trabalho divergente; caso contrário, STOP e resolver a divergência sem `reset --hard`, `git clean`, `stash -u` ou descarte de artefatos. Os arquivos CSV/JSON gerados **não devem entrar no Git**.

## Handoff

1. **Pré-requisito Git concluído:** PR #190 integrado e branch P3.2 sincronizada com `main@8a3144263e424078dbab6038d8a8b7089e3a40b2`; confirmar HEAD antes da execução.
2. Executar uma vez o validador **já versionado**, preservando logs e hashes fora do Git; inspecionar `p32_audit.json` e reportar resultado sem chamar a preparação de PASS.
3. Somente com provas válidas, adicionar closeout e atualizar o `current-state.md` na branch P3.2, abrir/revisar PR Draft separado, sem merge automático.
4. **STOP do P3.2:** PASS_RESTRICTED documentado ou BLOCKED/HARD_STOP explícito. P3.3 é apenas candidato futuro.

## Adendo pós-execução — 29/10/2026

A execução única no Windows local reportou `PASS_RESTRICTED`, `exit_code=0`, com os totais e controles esperados reconciliados; transcript e JSON completo inspecionados nesta sessão. **Fonte de prova e limites:** [closeout P3.2](sad-p32-res-serv-equality-annual-closeout-2026-10-29.md). O script previamente versionado foi executado a partir de `7cab8c12eaf2d6424dceb52f64aafaf50d623d2c`, sem reexecução das demais etapas. `GATE_PASS=True` exclusivamente numérico/local; `PR_MERGED=False`; `PRODUCTION_APPROVED=False`. STOP do gate cumprido. O bloco PowerShell acima é **histórico/reprodutivo**, não instrução para reexecutar automaticamente.
