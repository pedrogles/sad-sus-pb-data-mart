# Fase IV — Checkpoint IV-TEMPO — DIM_TEMPO (QlikView 12)

**Data:** 08/10/2026 (UTC-03)  
**Branch:** `feat/phase-4-dim-tempo`  
**Status:** **QLIKVIEW RELOAD + CHECKPOINT PARCIAL PASS (SAIDA LOCAL DO USUARIO) / AUDITORIA INDEPENDENTE DO QVD E LOG PENDENTE**. Nao declarar aceite fisico integral nem merge ate conferencia.

## 1. Precondicoes comprovadas documentalmente

- PR #73 integrado em `main`: squash SHA `5644bdafa5fe4e437ce3417b5368113639468267`.
- Fase III: `PASS_FINAL_RECONCILED` no QlikView 12 em 08/10/2026 21:46:48, com 10 QVDs, 107 campos exigidos, RD=566672, LT=35518, ST=220390 e IBGE=669.
- Boundary 3: 0 datas invalidas em `DT_INTER`/`DT_SAIDA` e 0 `DT_SAIDA < DT_INTER` nos RD inspecionados. Isto **nao** substitui o teste no QVD do ambiente atual.
- Boundaries 5–7: dimensao Tempo conceitualmente unica, chaves reproduziveis `Hash128` com prefixos DATA/MES/ANO, projecoes role-playing por dia/competencia/ano no painel; 3 fatos e Link Table ficam para fases posteriores.

Referencias:
- `AGENTS.md`; `docs/project/current-state.md`; `docs/academic/requirements.md`
- `docs/discovery/boundary-3-full-dataset-validation.md`
- `docs/discovery/boundary-5-historization-role-playing.md`
- `docs/discovery/boundary-6-qlikview-physical-architecture.md`
- `docs/discovery/boundary-7-implementation-plan.md`
- `docs/discovery/phase-3-final-extraction-gate-2026-10-08.md`

## 2. Escopo implementado (ainda sem teste fisico)

Arquivo externo existente modificado: `TRANSFORMACAO/transf_main.qvs`, carregado por `TRANSFORMACAO/TRANSF.qvw` via `Must_Include` da Fase I.

O script:

1. Le `EXTRACAO/QVD/_SUCCESS_EXTRACAO.csv` e exige uma linha com `EXTRACAO;PASS_FINAL_RECONCILED` e as contagens/contratos da Fase III. Preserva `T29_HISTORICAL=NOT_APPROVED`.
2. Le somente `DT_INTER` e `DT_SAIDA` de `SRC_SIH_RD.qvd`, exigindo 566.672 linhas por papel, formato `YYYYMMDD`, parse valido e roundtrip fiel.
3. Determina dinamicamente limites de dia observados no RD, sempre cobrindo pelo menos `2017-01-01..2019-12-31`. Se limites exigirem mais de 36.525 dias, **para para revisao**; nao exclui silenciosamente datas.
4. Gera `DIM_TEMPO` com um registro por dia, `%SK_TEMPO_DATA`, `%SK_TEMPO_COMPETENCIA` e `%SK_TEMPO_ANO` via `Hash128`, e atributos data, YYYYMMDD, competencia, ano, mes e dia.
5. Valida cardinalidade diaria e chave de dia unica, 36 competencias no periodo 2017–2019, tres anos, zero chaves vazias.
6. Somente depois grava `TRANSFORMACAO/QVD/DIM_TEMPO.qvd` e o marcador `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_TEMPO.csv` com `PASS_PARTIAL_DIM_TEMPO_ONLY`.

**Nao ha** `_SUCCESS_TRANSFORMACAO.csv`, fatos, Link Table, alias de PAINEL, indicadores ou alteracoes nos QVDs de staging. Um QVD de calendario diario tem repeticao intencional das SKs mensais/anuais: no futuro `PAINEL.qvw` deve usar projecoes `LOAD DISTINCT` na granularidade correspondente, conforme Boundary 7.

## 3. Procedimento de teste local (WINDOWS / QlikView 12)

Executar somente com a arvore Git limpa e `EXTRACAO/QVD/_SUCCESS_EXTRACAO.csv` do PASS de 08/10/2026 fisicamente presente:

```powershell
git status --short
git fetch origin
git switch --track origin/feat/phase-4-dim-tempo
# Se branch local ja existir, fazer checkout sem recria-la e atualizar por fast-forward.
git status --short

# Invalidar apenas o checkpoint IV-TEMPO antigo; nao apagar QVDs de staging.
Remove-Item .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_TEMPO.csv -ErrorAction SilentlyContinue

$started = Get-Date
& "$env:ProgramFiles\QlikView\Qv.exe" /r "$((Get-Location).Path)\TRANSFORMACAO\TRANSF.qvw"
$reloadExit = $LASTEXITCODE
"QLIK_EXIT=$reloadExit"

Get-Item .\TRANSFORMACAO\QVD\DIM_TEMPO.qvd, .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_TEMPO.csv | Select-Object Name, Length, LastWriteTime
Get-Content .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_TEMPO.csv
Get-FileHash .\TRANSFORMACAO\QVD\DIM_TEMPO.qvd -Algorithm SHA256
Get-ChildItem .\TRANSFORMACAO -Filter "TRANSF.qvw*.log" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

**Nao interpretar so a existencia de arquivos como PASS.** Exigir:

- `QLIK_EXIT=0` e log do reload contemporaneo encerrado sem erros `Unknown statement`/`Syntax Error` ou `ScriptErrorCount` acumulado.
- `_CHECKPOINT_DIM_TEMPO.csv` criado **depois** do inicio do reload, `stage=TRANSFORMACAO_DIM_TEMPO`, `status=PASS_PARTIAL_DIM_TEMPO_ONLY`, `invalid_date_rows=0`, `rd_inter_rows=566672`, `rd_total_date_rows=1133344`, `months_2017_2019=36`, `years_2017_2019=3`.
- `DIM_TEMPO.qvd` com data de atualizacao posterior ao inicio, cabecalho QVD inspecionado localmente, grão diário e chaves corretas. Registrar SHA-256 e contagem de linhas reais.
- Conferir nas amostras chave/dia e transicoes de mes/ano; cobrir 2017–2019, inclusive o intervalo entre as datas RD observadas e o baseline.
- Confirmar que **nenhum** `_SUCCESS_TRANSFORMACAO.csv` foi criado por este checkpoint e que QVDs da extracao nao foram alterados.

Se `QLIK_EXIT` for diferente de zero, marcador ausente ou campos/contagens divergentes, registrar `IV-TEMPO=FAIL_CLOSED` e investigar o novo log; nao fazer merge ou chamar Fase IV de PASS.

## 4. Pendencias para depois do teste

- Confirmar como o `PAINEL` projetara `DIM_TEMPO.qvd` para `DIM_TEMPO_COMPETENCIA`, `DIM_TEMPO_ANO`, `DIM_TEMPO_INTERNACAO` e `DIM_TEMPO_SAIDA` sem duplicidade de chaves mensais/anuais. Essa montagem pertence a fase posterior do PAINEL.
- Prosseguir, apos gate fisico de IV-TEMPO, para `DIM_MUNICIPIO`, preservando 5.202 RD de residencia externa sem atribuir populacao PB.
- Manter sem mudancas `T29_HISTORICAL=NOT_APPROVED`, legendas CNES exclusivamente 201909 e nomes historicos de estabelecimento nao comprovados como NULL.

## 5. Veredito

**CHECKPOINT IV-TEMPO: CODE READY / LOCAL QLIKVIEW VALIDATION REQUIRED.** Nao ha evidencia nesta execucao remota de que `TRANSF.qvw` tenha rodado no Windows/QlikView 12. A primeira entrega academica permanece fechada e nao foi alterada.

## 6. Primeira execucao local IV-TEMPO — Qlik reload + checkpoint PASS (08/10/2026 22:17:20 UTC-03)

**FATO VERIFICADO — saida PowerShell apresentada pelo responsavel:**

- `git fetch origin` atualizou a branch remota `feat/phase-4-dim-tempo`, e `git switch --track origin/feat/phase-4-dim-tempo` criou o tracking local com sucesso.
- O marcador parcial anterior foi removido antes da execucao.
- `Qv.exe /r .../TRANSFORMACAO/TRANSF.qvw` retornou `QLIK_EXIT=0`.
- O novo checkpoint foi lido em PowerShell com o conteudo:

```csv
generated_at;stage;status;calendar_day_rows;months_2017_2019;years_2017_2019;rd_inter_rows;rd_total_date_rows;invalid_date_rows;t29_historical;facts_and_link_table
08/10/2026 22:17:20;TRANSFORMACAO_DIM_TEMPO;PASS_PARTIAL_DIM_TEMPO_ONLY;4383;36;3;566672;1133344;0;NOT_APPROVED;NOT_STARTED
```

**Interpretacao:** o script QlikView 12 concluiu e o checkpoint parcial da dimensao retornou os controles esperados: 36 competencias (2017–2019), 3 anos, 566.672 datas de admissao, 1.133.344 datas totais, zero invalidas; T29 historico continua NOT_APPROVED e fatos/Link Table nao iniciados. `IV-TEMPO=PASS_LOCAL_RELOAD_AND_CHECKPOINT_ONLY`.

**Atencao ao dominio de datas:** 4.383 dias excedem os 1.095 dias do recorte de competencias 2017–2019. O script expande os limites de calendario para abranger `DT_INTER` e `DT_SAIDA` reais; o valor pode ser legitimo, mas **as datas extremas observadas ainda nao foram fornecidas**. Nao tratar a contagem estendida como erro nem assumir suas causas sem inspecao.

**Evidencias adicionais ainda necessarias antes de merge:**
1. `Get-Item` e SHA-256 de `TRANSFORMACAO/QVD/DIM_TEMPO.qvd`, com LastWriteTime contemporaneo ao reload e `QvdNoOfRecords`/cabecalho reconciliando 4383 linhas.
2. Log contemporaneo de `TRANSF.qvw`, com final normal, sem `Unknown statement`, `Syntax Error` ou erros ocultos.
3. Confirmar min/max reais do calendario ou de `DT_INTER`/`DT_SAIDA`, para explicar os 4.383 dias, preservando historico sem truncamento.
4. Confirmar que `_SUCCESS_TRANSFORMACAO.csv` nao foi gerado e que QVDs da extracao nao foram alterados.

**Veredito vigente:** `IV-TEMPO=PASS_LOCAL_RELOAD_AND_CHECKPOINT_ONLY`, `DIM_TEMPO_QVD_AUDIT=PENDING`, `PR_74=DRAFT`, `PHASE_IV=IN_PROGRESS`. Nenhuma evidencia remota autoriza declarar Fase IV completa.
