# P3.4 — Residentes fora da referência municipal PB por ano (2017–2019) | READ-ONLY

**Gate:** `SAD-P34-SIH-EXTERNAL-RESIDENCE-ANNUAL-READONLY-01`  
**Estado:** `SCRIPT_VERSIONED / NOT_RUN / READY_FOR_LOCAL_INPUTS` — não é PASS.  
**Baseline:** `main@ab76cb24f27fb3521ad30c3118c04e0fc93ec91c`, após integração por squash do [PR #192](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/192) (P3.3).  
**Agente primário:** ChatGPT GPT-6 + GitHub para preparação documental e script; esforço exato indisponível. **Execução planejada:** operador Windows PowerShell + Python. Escalonar a Codex Local apenas diante de erro real. Sem QlikView/COM/GUI e sem alteração de dado.

## Objetivo, fontes e fronteira

Medir, **por ano de competência**, `SUM(qtd_registro_aih)`, `SUM(qtd_internacao)` e `SUM(qtd_continuidade)` dos registros administrativos SIH/RD agregados por competência × RES × SERV, separando os códigos de residência **presentes** dos **ausentes** na referência C5.2 de 223 municípios PB. A categoria externa significa **fora da referência municipal PB derivada e validada**: não significa residência nacional identificada, paciente único nem deslocamento físico individual.

- **E1 (obrigatório):** `C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv`; SHA-256 `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`. Campos exatos: `competencia;ano;municipio_res;municipio_serv;qtd_registro_aih;qtd_internacao;qtd_continuidade`. 30.255 grãos observados, 36 competências. E1 é extrato **agregado**, não linhas individuais.
- **Referência C5.2 (obrigatória):** `EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.csv` no repo Windows, derivada pelo projeto dos três XLS IBGE oficiais, validada localmente em III-C5.2. SHA-256 histórico documentado `FDF016E4EAF7A7B8B396D3908DA2EC6737944BC9AAF3E6018BADB763725C257D`. Exigir 223 pares únicos `COD_DATASUS_6↔COD_IBGE_7`, colunas e metadados exatos de `tools/audit_municipal_pb_crosswalk.py`; não inventar IBGE7 nem adicionar códigos de outros estados. A referência é derivada, **não tabela externa oficial**.
- **Histórico validado a confrontar:** `qtd_registro_aih externo = 5.202`, `qtd_internacao externo = 5.067`, portanto `qtd_continuidade externo = 135` (subtração da decomposição AIH). Totais E1 de 566.672 registros, 555.089 novas e 11.583 continuidades; novas por ano 183.532, 183.311, 188.246. **Contagens anuais externas são desconhecidas** até a execução e não podem ser inferidas. O conceito *fora de C5.2* segue `docs/discovery/phase-3-municipal-crosswalk-materialization-2026-10-08.md` e `docs/discovery/sad-analytical-scope-acceptance-01-2026-10-27.md` (P3.4).
- **Scripts reutilizados:** `tools/audit_municipal_pb_crosswalk.py` (schema, metadados e unicidade C5.2), `tools/validate_sad_p13_serv_ranking01.py` (schema/pins E1, período/medidas/validação numérica). **Script novo P3.4 foi versionado ANTES de qualquer execução:** `tools/validate_sad_p34_external_residence01.py` no commit `c16ddbc0dcc6b6ed955fb35370c50e27220481aa`. Não repetir executores P1/P2/P3.1/P3.2/P3.3.
- **Escopo tocável:** somente script, este protocolo e snapshot operacional P3.4 em branch própria. E1, C5.2 CSV/QVD, fontes oficiais, QVD/QVW/QVS e `main` **somente leitura**. Nenhuma alteração dimensional, Link Key, métrica populacional, painéis ou Fase IX. Preservar QlikView 12, 3 fatos, 8 dimensões, Boundary 7 e o fluxo BASE→EXTRACAO→QVD→TRANSFORMACAO→QVD→PAINEL.
- **Saídas de evidência:** diretório novo e persistente `C:/Users/pedro/SAD_EVIDENCIAS/P34_20261029_01/`, externo ao Git e às duas fontes. `RUNTIME_TEMP`: não aplicável. CSV de 6 linhas (3 anos × PB/externo), CSV de 3 linhas só externos, auditoria JSON, log, cópias negativas de E1/C5.2 e manifesto SHA. **Não colocar saídas no Git.**

## PASS, bloqueios e STOP

**PASS_RESTRICTED numérico/local:** SHA dos dois inputs conforme pins; validação de 223 códigos PB únicos com código IBGE7 integral oficial e metadados corretos; E1 com schema, 30.255 grãos, 36 meses, totalizações anuais/trienais e decomposição AIH; códigos PB (prefixo 25) devem todos constar na C5.2, caso contrário `HARD_STOP`; classificação por *pertencimento exato ao conjunto validado*, sem nomes ou denominadores externos; externas = 5.202 AIH, 5.067 novas, 135 continuidades; reconciliação por ano, classe e triênio nas três medidas; CSVs e readback; duas cópias alteradas (E1 e C5.2) rejeitadas por hash; originals SHA preservados; `exit_code=0` e `divergences=[]`.

**BLOCKED:** fonte indisponível, hash alterado, ambiente não pronto, checkout sujo/divergente ou diretório de evidências pré-existente (não sobrescrever). **INCONCLUSIVE_HARD_STOP:** campos/digitos/integração C5.2 divergentes, decomposição, totais, datas ou reconciliação incorretos. **Não corrigir dados/inputs/constantes para forçar PASS.**

**STOP:** após uma execução válida ou um bloqueio documentado, sem testes repetidos e sem iniciar outra frente. Aprovação de produção/visual/semântica inter-fatos segue **não** concedida; `PHASE_IX=NOT_AUTHORIZED`.

## Comando PowerShell — preflight obrigatório antes de executar uma única vez

```powershell
$ErrorActionPreference = "Stop"
$repo = "C:\Users\pedro\Documents\programming\sad-sus-pb-data-mart"
$branch = "test/sad-p34-sih-external-residence-annual-readonly-01"
$e1 = "C:\Users\pedro\SAD_EVIDENCIAS\AE01_20261027_02\sih_fluxo_competencia.csv"
$c52 = "$repo\EXTRACAO\QVD\REF_MUNICIPIO_PB_DERIVADA.csv"
$out = "C:\Users\pedro\SAD_EVIDENCIAS\P34_20261029_01"
$e1Pin = "F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615"
$c52Pin = "FDF016E4EAF7A7B8B396D3908DA2EC6737944BC9AAF3E6018BADB763725C257D"
$sourceCommit = "c16ddbc0dcc6b6ed955fb35370c50e27220481aa"

if (-not (Test-Path -LiteralPath $repo -PathType Container)) { throw "REPO_NOT_FOUND" }
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
if ($LASTEXITCODE -ne 0) { throw "FF_ONLY_FAILED" }
git -C $repo merge-base --is-ancestor origin/main HEAD
if ($LASTEXITCODE -ne 0) { throw "BRANCH_NOT_AT_CURRENT_MAIN" }

if (-not (Test-Path -LiteralPath $e1 -PathType Leaf)) { throw "E1_NOT_FOUND" }
if (-not (Test-Path -LiteralPath $c52 -PathType Leaf)) { throw "C52_CSV_NOT_FOUND" }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $e1).Hash -ne $e1Pin) { throw "E1_SHA_MISMATCH" }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $c52).Hash -ne $c52Pin) { throw "C52_SHA_MISMATCH" }
if (Test-Path -LiteralPath $out) { throw "EVIDENCE_DIR_ALREADY_EXISTS" }

python -B "$repo\tools\validate_sad_p34_external_residence01.py" `
    --e1 "$e1" `
    --c52 "$c52" `
    --output-dir "$out" `
    --source-commit $sourceCommit
if ($LASTEXITCODE -ne 0) { throw "P34_VALIDATOR_NONZERO" }
Write-Host "P3.4 concluido com exit code 0."
```

Se qualquer pré-verificação falhar, **parar** e compartilhar apenas o erro/diagnóstico. Não usar `reset --hard`, `git clean`, `stash -u`, nem recarregar QlikView para recriar/regravar a C5.2 silenciosamente.

## Handoff

Enviar `p34_audit.json` e, se possível, `p34_residence_class_annual.csv` e `p34_external_residents_annual.csv`. Conferir hashes, números e limitações; preparar closeout no PR Draft e uma revisão de integração **separada**, sem merge automático. Estado de preparação: `GATE_PASS=False (NOT_RUN)` · `PR_MERGED=False` · `PRODUCTION_APPROVED=False`. O P3.4 conclui o escopo analítico P3 delimitado; qualquer próximo gate precisa de nova decisão.
