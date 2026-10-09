# Fase III — Gate final de reconciliação de extração (T07/T08 e QVDs)

**Data:** 08/10/2026  
**Estado:** `SCRIPT_READY / RELOAD_LOCAL_NOT_YET_VALIDATED`  
**Branch:** `feat/phase-3-final-extraction-gate`  
**Ferramenta:** QlikView 12 e Python 3 (biblioteca padrão).

## 1. Fontes de verdade e decisões preservadas

- `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`;
- `docs/discovery/boundary-7-implementation-plan.md`: fase III de extração com reconciliação obrigatória; T07 = RD/LT/ST 36/36; T08 = campos obrigatórios 100%; marcador `_SUCCESS_EXTRACAO.csv` apenas no fim; antes de cada execução o runner deve eliminar marcador antigo e, na falha, não produzir PASS;
- `docs/discovery/boundary-8-readiness.md`: `ErrorMode=0` com `ScriptErrorCount` verificado e interrupção controlada;
- `docs/discovery/boundary-5-historization-role-playing.md`: estabelecimento `CNES×COMPETENCIA`; lacuna de nomes 201701–201705 pode ficar NULL sem forward/backfill. **T16 pertence à Fase IV**, não à extração;
- evidências III-A/B/C1/C2/C3/C4/C5.1/C5.2 já aprovadas, especialmente o `PASS_LOCAL_REFERENCE_AUDIT` de III-C5.2;
- `T29_HISTORICAL=NOT_APPROVED`: a legenda CNES 201909 é somente referência descritiva datada; cobertura 57/57 pares PB e 35.518/35.518 registros não comprova vigência histórica de 36 meses.

**FATO VERIFICADO:** a `main` foi atualizada localmente pelo usuário até `45f714d`, com árvore limpa após `git pull --ff-only origin main`. Este desenvolvimento parte dessa base, **sem alterações nas fases IV–IX, na modelagem acadêmica ou nos dados brutos**.

## 2. Implementação proposta (ainda sem reload local)

### QlikView — `EXTRACAO/ext_phase3_final_gate.qvs`

Último include de `EXTRACAO/ext_main.qvs`, depois de `ext_c5_2_municipio_pb.qvs`. Usa funções de metadados QVD do próprio QlikView (`QvdNoOfRecords`, `QvdNoOfFields`, `QvdFieldName`) para testar os campos obrigatórios sem construir dimensão.

| QVD final de extração | Registros esperados |
|---|---:|
| `SRC_SIH_RD.qvd` | 566.672 |
| `SRC_CNES_LT.qvd` | 35.518 |
| `SRC_CNES_ST.qvd` | 220.390 |
| `SRC_IBGE_POPULACAO.qvd` | 669 |
| `REF_CARATER_ATENDIMENTO.qvd` | 6 |
| `REF_MOTIVO_SAIDA.qvd` | 28 |
| `REF_CID10.qvd` | 14.230 |
| `REF_SIGTAP.qvd` | 165.203 |
| `REF_TIPO_LEITO.qvd` | 65 — somente setembro/2019 |
| `REF_MUNICIPIO_PB_DERIVADA.qvd` | 223 — somente PB, ponte derivada |

**T08:** valida **107 campos obrigatórios em dez QVDs**; se qualquer campo não existir, interrompe o script sem produzir sucesso.

**T07:** lê `_META_SOURCE_COMPETENCE` em QVD RD/LT/ST e exige a lista completa **201701–201912**, exatamente 36 competências em cada família, nenhum código de competência externo ao período. A fase III-A já confere competência de origem contra nome de arquivo e contagem de 36 arquivos por família.

**Outros gates:** mantém cobertura sem unmatched das referências caráter, motivo, CID-10, SIGTAP, CNES leitos de 201909 (apenas snapshot), município PB; 5.202 registros RD de residência externa permanecem separados. `QvdNoOfRecords` confere contagem de linhas física de cada QVD. `ScriptErrorCount` bloqueia marcador se a carga falhar.

Somente depois de todos os testes: gera `EXTRACAO/QVD/_SUCCESS_EXTRACAO.csv` com `PASS_FINAL_RECONCILED`, timestamp, versão, contagens, T07/T08, `t29_historical_validity=NOT_APPROVED`, `dimensional_transformation=NOT_STARTED`, políticas de estabelecimento e ponte municipal.

### Runner — `tools/run_phase3_extraction.py`

Fluxo local fail-closed:

1. Exige `Qv.exe` configurável com `--qlikview-exe` ou variável `QLIKVIEW_EXE`; **sem caminho hardcoded** no código.
2. Verifica previamente `EXTRACAO/EXT.qvw`. Remove **somente** o marcador final antigo e manifesto final antigo — preserva QVDs e checkpoints parciais para diagnóstico.
3. Registra `RELOAD_STARTED_UTC` e executa `Qv.exe /r` de forma síncrona.
4. Exige código de saída zero **e** novo marcador `PASS_FINAL_RECONCILED` criado depois do início; nunca confia somente no `exit code`.
5. Confere novamente 10 QVDs não vazios, com mtime do mesmo reload, e a linha completa do marcador, incluindo contagem, T07/T08, 223 municípios PB e preservação dos 5.202 RD de residência externa.
6. Calcula SHA-256 dos 10 QVDs e do marcador, grava manifesto **local** `BASE/REFERENCIAS/phase3_extraction_final_manifest.json`.
7. Em erro/timeout, apaga apenas o marcador final/manifesto inválidos e retorna `VERDICT=FAIL_CLOSED`. Não altera QVDs de origem nem inicia transformação.

Documentação técnica das funções Qlik:
- <https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/FileFunctions/QvdNoOfRecords.htm>
- <https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/FileFunctions/QvdFieldName.htm>
- <https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/FileFunctions/QvdNoOfFields.htm>

## 3. Gate local pendente no Windows

Após `git switch main`, `git pull --ff-only origin main`, `git fetch origin` e checkout de **branch nova** `feat/phase-3-final-extraction-gate` (com árvore local limpa), executar **pelo runner**, não `Qv.exe /r` diretamente:

```powershell
.\.venv\Scripts\python.exe tools\run_phase3_extraction.py --qlikview-exe "$env:ProgramFiles\QlikView\Qv.exe"
if ($LASTEXITCODE -ne 0) { throw "Fase III — reconciliacao final falhou" }
Get-Content .\EXTRACAO\QVD\_SUCCESS_EXTRACAO.csv
```

Esperado (**não observado ainda**):

```text
QVD_COUNT=10 FRESH_QVD_FILES=10
T07=PASS_3_FAMILIES_36_MONTHS
T08=PASS_107_REQUIRED_FIELDS
RD=566672 LT=35518 ST=220390 IBGE=669
PB_MUNICIPAL_REFERENCE=223 RD_EXTERNAL_RESIDENCES=5202
T29_HISTORICAL=NOT_APPROVED
TRANSFORMATION=NOT_STARTED
VERDICT=PASS_LOCAL_QV_AND_SHA_RECONCILIATION
```

**Falha:** não chamar Fase III de PASS; reunir log QlikView e `VERDICT=FAIL_CLOSED`. O script não deve ser integrado à `main` antes do teste local.

## 4. Decisão após evidência

Se todos os gates físicos passarem, revisar o PR de extração e registrar `PHASE_III=PASS_EXTRACTION_RECONCILED`, **não** `T29_HISTORICAL=PASS`. A limitação histórica dos rótulos CNES, a lacuna de nomes e a referência municipal derivada seguem documentadas; as dimensões e fatos pertencem a etapas posteriores, conforme Boundary 7.

A primeira entrega acadêmica (Capítulos 1 e 2, impressa em 13/10/2026) permanece **FECHADA — PRONTA PARA IMPRESSÃO** e não é alterada por este checkpoint.


## 5. Primeira tentativa real — FAIL_CLOSED (09/10/2026 UTC)

**FATO VERIFICADO — saída PowerShell fornecida pelo usuário:**

- `git fetch origin`, validação de árvore limpa e `git switch --track origin/feat/phase-3-final-extraction-gate` concluídos;
- comando executado: `.\\.venv\\Scripts\\python.exe tools\\run_phase3_extraction.py --qlikview-exe "$env:ProgramFiles\\QlikView\\Qv.exe"`;
- saída:

```text
RELOAD_STARTED_UTC=2026-10-09T00:18:48.368773+00:00
OLD_SUCCESS_MARKER=INVALIDATED
QLIK_RELOAD_STAGE=EXTRACAO_ONLY
VERDICT=FAIL_CLOSED ERROR=QlikView retornou codigo de erro 3
PHASE_III=IN_PROGRESS
```

- o PowerShell interrompeu a sequência no teste de `$LASTEXITCODE`. Não houve checkpoint `_SUCCESS_EXTRACAO.csv` enviado nem auditoria SHA final.
- código `3` acima corresponde ao **exit code do processo `Qv.exe` retornado a `subprocess.run()`**, não ao número do erro interno `ScriptError` do script Qlik; o motivo interno não é inferível apenas por esse valor.

**STATUS:** `III_FINAL=FAIL_CLOSED_UNDIAGNOSED`, `PHASE_III=IN_PROGRESS`, `T29_HISTORICAL=NOT_APPROVED`. O executor remove marcador final/manifesto no erro, preserva QVDs e checkpoints parciais para diagnóstico; a execução fracassada pode ter regravado QVDs antes de abortar, portanto a data física precisa ser verificada ao revisar evidências. PR #73 deve permanecer em **Draft/sem merge** até identificar a causa, corrigir apenas o que for comprovado e testar novamente.

**Próxima prova requerida — READ-ONLY:** procurar log mais recente de `EXT.qvw` ou `qv.log` no diretório `EXTRACAO`, conferir `LastWriteTime` contra 08/10/2026 ~21:18 horário de João Pessoa e inspecionar final + primeiro erro. Se logs não existirem, habilitar `Configurações > Propriedades do Documento > Geral > Gerar Arquivo Log` no QlikView 12 e executar novamente **somente após** habilitar registro; não alterar scripts/dados por hipótese. Documentação Qlik: <https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Document_Properties_General.htm>.
