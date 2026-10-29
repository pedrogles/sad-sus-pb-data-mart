# P3.2 — RES=SERV versus RES≠SERV anual (2017–2019) | Protocolo READ-ONLY

**Gate:** `SAD-P32-SIH-RES-SERV-EQUALITY-ANNUAL-READONLY-01`  
**Estado de preparação:** `SCRIPT_VERSIONED / EXECUTION_NOT_RUN / DEPENDENCY_BLOCKED` (29/10/2026). **Não é PASS.**  
**Baseline de criação:** `main@6f35f86b1d672949d9921cb948463000e02aacdd`. O [PR #190 (P3.1)](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/190) estava **aberto, Ready for review e sem merge** na consulta. O merge autorizado foi tentado via conector, mas a ação foi recusada pelas permissões da sessão. A branch P3.2 foi criada independentemente da `main`, **sem trazer commits P3.1 não integrados**.

## Roteamento e contrato de execução

- **Objetivo único:** classificar cada linha agregada SIH/RD E1 pelo teste textual `municipio_res == municipio_serv`, agregar `SUM(qtd_internacao)` por **ano de competência × classe** e reconciliar o triênio. Não estimar deslocamento individual.
- **Fontes superiores consultadas na `main`, em ordem:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, escopo analítico aceito D1–D3, matriz de fontes e política de roteamento. Boundary 7 preservado. P3.1 local e P1.3 são evidências reutilizadas, não gates a repetir.
- **Agente da preparação:** ChatGPT + GitHub, GPT-6; esforço exato da sessão não exposto. **Executor proposto:** Python no Windows local, operador/ Codex Local somente se necessário; modelo/esforço efetivos a registrar na execução. Não pressupor acesso do ChatGPT ao filesystem Windows.
- **Fonte de entrada imutável:** `C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv` (E1), SHA-256 esperado `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`, grão `competencia × ano × municipio_res × municipio_serv`, 30.255 registros. Nome do arquivo e pin são do gate E1 previamente validado, **não bytes verificados nesta preparação remota**.
- **Schema fechado:** `competencia;ano;municipio_res;municipio_serv;qtd_registro_aih;qtd_internacao;qtd_continuidade`. Controle: `qtd_registro_aih = qtd_internacao + qtd_continuidade`; `IDENT=5` não é internação nova.
- **Validador versionado antes de qualquer execução:** `tools/validate_sad_p32_res_serv_equality01.py`, commit `d0437284dbf709efffa6def5051f4fb37b5d9651`. Reutiliza as constantes/funções do `tools/validate_sad_p13_serv_ranking01.py` na `main`; sem reexecutar o ranking P1.3.
- **Escopo tocável:** script e este protocolo em branch isolada. E1, QVD, QVW, QVS, modelo acadêmico e `main` **somente leitura**. Não alterar `current-state.md` da `main` antes do resultado da execução e da integração de P3.1.
- **RUNTIME_TEMP:** não aplicável. **EVIDENCE_ROOT candidato:** `C:/Users/pedro/SAD_EVIDENCIAS/P32_20261029_01/` (novo e persistente, separado da pasta original E1 e fora do Git). Confirmar inexistência e espaço antes de executar.
- **Orçamento:** uma execução positiva, uma cópia E1 alterada (LF anexado) para negativa integrada, readback CSV e hashes; investigar falha concreta antes de propor segunda tentativa. Nenhuma chamada QlikView/COM ou P3.3/P3.4.

## Oráculos, PASS e STOP

- **PASS_RESTRICTED (somente numérico):** arquivo E1 pinado; schema, 36 competências, unicidade e decomposição corretos; seis linhas (três anos × duas classes), sem pares descartados; somas anuais 2017 `183532`, 2018 `183311`, 2019 `188246`; total `555089`; classes do triênio `RES_EQ_SERV=294635` e `RES_NE_SERV=260454` (46,92% para a segunda classe, arredondado); reconciliação mensal/anual/triênio nas três medidas; CSV readback; cópia negativa rejeitada; fonte preservada. Esses valores são **controles históricos exploratórios a confrontar**, não novo resultado validado nesta preparação.
- **BLOCKED:** P3.1 sem integração necessária ao encadeamento operacional, E1 original inacessível, erro de ambiente ou evidência essencial ausente. **HARD_STOP/INCONCLUSIVE:** SHA, schema, soma, grão, medida, período ou classe divergente. Nunca corrigir dados para forçar PASS.
- **Entregáveis derivados fora do Git:** `p32_res_serv_annual.csv` (6 linhas), `p32_audit.json`, `execution.log`, `negative_e1_altered.csv`, `sha256_manifest.json`. O negativo é uma rejeição de cópia **dentro do processo**, não um segundo processo independente com `exit=2`.
- **Status atual:** `GATE_PASS=False (NOT_RUN)`, `PR_MERGED=False`, `PRODUCTION_APPROVED=False`. Sem aprovação visual, científica inter-fatos ou de produção.

## Execução local — somente após integração P3.1 e sincronização segura

Confirmar `main` remota e o [PR #190](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/190) como MERGED, e assegurar que não haja mudanças locais a sobrescrever. Depois, fazer checkout da branch P3.2 e obter o commit versionado. **Não executar o código antes de confirmar que os arquivos versionados coincidem com o commit.**

```powershell
$repo = "C:\Users\pedro\Documents\programming\sad-sus-pb-data-mart"
git -C $repo status --short
git -C $repo fetch origin
git -C $repo switch test/sad-p32-sih-res-serv-equality-annual-readonly-01
git -C $repo pull --ff-only origin test/sad-p32-sih-res-serv-equality-annual-readonly-01
python -B "$repo\tools\validate_sad_p32_res_serv_equality01.py" `
    --e1 "C:\Users\pedro\SAD_EVIDENCIAS\AE01_20261027_02\sih_fluxo_competencia.csv" `
    --output-dir "C:\Users\pedro\SAD_EVIDENCIAS\P32_20261029_01" `
    --source-commit d0437284dbf709efffa6def5051f4fb37b5d9651
```

**Atenção:** `git switch` deve ser usado somente se `git status --short` estiver limpo e a branch local não contiver trabalho divergente; caso contrário, STOP e resolver a divergência sem `reset --hard`, `git clean`, `stash -u` ou descarte de artefatos. Os arquivos CSV/JSON gerados **não devem entrar no Git**.

## Handoff

1. **Primeiro desbloqueio mínimo:** integrar PR #190 por processo autorizado e conferir `main@SHA` real.
2. Executar uma vez o validador **já versionado**, preservando logs e hashes fora do Git; inspecionar `p32_audit.json` e reportar resultado sem chamar a preparação de PASS.
3. Somente com provas válidas, adicionar closeout e atualizar o `current-state.md` na branch P3.2, abrir/revisar PR Draft separado, sem merge automático.
4. **STOP do P3.2:** PASS_RESTRICTED documentado ou BLOCKED/HARD_STOP explícito. P3.3 é apenas candidato futuro.
