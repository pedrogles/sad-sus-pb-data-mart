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


## 6. Inspeção dos logs apresentados — evidência NÃO correspondente à tentativa atual

**FATO VERIFICADO:** o usuário listou os logs `EXTRACAO/*.log` recursivamente. O mais recente retornado foi `EXT.qvw.2026_10_08_12_44_07.log`, com `LastWriteTime=08/10/2026 12:44:24` **horário local**, anterior em aproximadamente 8h34 à execução final `RELOAD_STARTED_UTC=2026-10-09T00:18:48Z` (**21:18:48 em UTC-03:00, em 08/10**). Nenhum log referente à falha atual apareceu na listagem.

O log antigo termina com:
```text
TRACE [EXTRACAO] PARTIAL ONLY â€” CNES tipo/leito, municipal reference and establishment history remain pending
no final extraction success marker emitted.
Erro: Comando desconhecido
```
Esse `Comando desconhecido` pertence ao **script antigo antes de C4/C5**, cujo `TRACE` foi fragmentado. **Não constitui diagnóstico do exit code 3 da execução atual**; a instrução não está mais presente na versão atual de `ext_main.qvs`.

**PENDÊNCIA:** localizar ou produzir log da execução de 21:18, sem alterar os contratos. Primeiro observar `LastWriteTime` dos QVDs/checkpoints posteriores à tentativa e confirmar em QlikView Desktop `Configurações → Propriedades do Documento → Geral → Gerar Arquivo Log` e `Timestamp no nome do arquivo de log`. A [orientação de suporte oficial Qlik](https://community.qlik.com/t5/Official-Support-Articles/How-To-Enable-QlikView-Document-Reload-Log/ta-p/1710459) indica que logs de reload do QlikView Desktop são gerados junto do `.qvw` quando essa opção está habilitada. Se necessário, executar **nova tentativa controlada somente após ativar logging e garantir o arquivo salvo**, usando o runner existente. **Nenhuma alteração no gate Qlik nem merge até obter o primeiro erro real.**

**Estado preservado:** `III_FINAL=FAIL_CLOSED_UNDIAGNOSED`; `PHASE_III=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.


## 7. Segunda tentativa e QVDs da primeira tentativa — 08/10/2026

**FATO VERIFICADO — saída PowerShell local adicional do usuário:**

1. A seleção por `LastWriteTime >= 08/10/2026 21:17:48` no diretório `EXTRACAO/QVD` mostrou todos os QVDs principais atualizados na **primeira tentativa** `21:18:48`–`21:19:08`. O último artefato identificado foi `_CHECKPOINT_EXTRACAO_C5_2_MUNICIPIO_PB.csv` às **21:19:08**, acompanhado de `REF_MUNICIPIO_PB_DERIVADA.qvd`, `REF_MUNICIPIO_PB_DERIVADA.csv` e `_CHECKPOINT_EXTRACAO_MUNICIPAL_PREFLIGHT.csv`. Isso indica que a execução progrediu **até C5.2**, sem evidência de conclusão do include final.
2. Nova execução do runner:

```text
RELOAD_STARTED_UTC=2026-10-09T00:27:45.387985+00:00
OLD_SUCCESS_MARKER=INVALIDATED
QLIK_RELOAD_STAGE=EXTRACAO_ONLY
VERDICT=FAIL_CLOSED ERROR=QlikView retornou codigo de erro 3
PHASE_III=IN_PROGRESS
RUNNER_EXIT=3
```

3. Depois dessa segunda tentativa, o log mais recente listado continua `EXT.qvw.2026_10_08_12_44_07.log` (`LastWriteTime 08/10/2026 12:44:24`). Portanto, não há **log contemporâneo** ao reload atual na seleção enviada; a mensagem `Comando desconhecido` do log antigo não demonstra a falha de III-FINAL.

**Diagnóstico controlado adicionado (sem reload):** `tools/diagnose_phase3_qvd_headers.py` lê **somente os cabeçalhos XML** dos 10 QVDs e os contratos já versionados em `EXTRACAO/ext_phase3_final_gate.qvs`, reportando contagens, campos exigidos T08 ausentes e ausência/corrupção de QVD. Não altera nem cria arquivos. **Se passar, não equivale à prova de sucesso T07/T08**; o log Qlik ainda será necessário. Requer nova evidência de execução local:

```powershell
git pull --ff-only origin feat/phase-3-final-extraction-gate
.\.venv\Scripts\python.exe tools\diagnose_phase3_qvd_headers.py
"DIAGNOSTIC_EXIT=$LASTEXITCODE"
```

**Estado:** `III_FINAL=FAIL_CLOSED`, causa ainda **não provada**. PR #73 **Draft, sem merge**, Fase III `IN_PROGRESS`, `T29_HISTORICAL=NOT_APPROVED`. Não corrigir esquema nem campos esperados por suposição.


## 8. Diagnóstico físico QVD read-only — 10/10 contratos compatíveis

**FATO VERIFICADO — execução local do usuário na branch atualizada `feat/phase-3-final-extraction-gate`:** `.\\.venv\\Scripts\\python.exe tools\\diagnose_phase3_qvd_headers.py` retornou **exit code 0**, seguido por:

```text
QVD=SRC_SIH_RD HEADER_OK rows=566672 physical_fields=21 required_fields=21
QVD=SRC_CNES_LT HEADER_OK rows=35518 physical_fields=12 required_fields=12
QVD=SRC_CNES_ST HEADER_OK rows=220390 physical_fields=14 required_fields=14
QVD=SRC_IBGE_POPULACAO HEADER_OK rows=669 physical_fields=11 required_fields=11
QVD=REF_CARATER_ATENDIMENTO HEADER_OK rows=6 physical_fields=6 required_fields=6
QVD=REF_MOTIVO_SAIDA HEADER_OK rows=28 physical_fields=9 required_fields=9
QVD=REF_CID10 HEADER_OK rows=14230 physical_fields=7 required_fields=7
QVD=REF_SIGTAP HEADER_OK rows=165203 physical_fields=7 required_fields=7
QVD=REF_TIPO_LEITO HEADER_OK rows=65 physical_fields=13 required_fields=13
QVD=REF_MUNICIPIO_PB_DERIVADA HEADER_OK rows=223 physical_fields=7 required_fields=7
HEADER_CONTRACTS=10 PROBLEM_QVDS=0 FIELDS_IN_MATCHING_QVDS=107
VERDICT=QVD_HEADERS_MATCH_EXPECTATIONS_ONLY
DIAGNOSTIC_EXIT=0
```

**Interpretação limitada:** os **dez QVDs existentes** possuem os **107 campos exigidos T08** e as quantidades físicas contratadas. Essa evidência exclui **divergências detectáveis nos cabeçalhos XML QVD** como explicação suficiente, mas **NÃO comprova o gate de execução QlikView**, `T07=PASS` ou `T08=PASS` no script, nem esclarece o exit code 3 de `Qv.exe`. Não mudar contratos para contornar erro não demonstrado.

**Fundamentação complementar oficial:** QlikView `QvdFieldName(filename,fieldno)` tem índice **começando em 1**, consistente com o laço do gate: <https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Scripting/FileFunctions/QvdFieldName.htm>. A sintaxe continua dependente de teste no QlikView 12 local.

**Próximo diagnóstico obrigatório:** verificar nas propriedades do **mesmo arquivo `EXTRACAO/EXT.qvw`** as opções `Generate Logfile` e `Timestamp in Logfile Name`, habilitar e **salvar o QVW**, fechar QlikView Desktop. Documentação Qlik: <https://community.qlik.com/t5/Official-Support-Articles/How-To-Enable-QlikView-Document-Reload-Log/ta-p/1710459>. Somente então executar **uma vez** via `tools/run_phase3_extraction.py` e buscar o **novo** `EXT.qvw*.log` cujo `LastWriteTime` seja posterior ao reload. Inspecionar primeiro `Erro:` e `[EXTRACAO][FINAL]`, não reutilizar o log antigo das 12:44. Sem registro novo, investigar por que o QVW não está persistindo a opção de logging, sem alterar scripts/dados.

**Estado:** `III-FINAL=FAIL_CLOSED_2X`; `QVD_HEADER_CONTRACT=PASS_READ_ONLY`; `PHASE_III=IN_PROGRESS`; `PR_73=DRAFT`; `T29_HISTORICAL=NOT_APPROVED`.


## 9. Terceira tentativa — log Qlik contemporâneo e raiz do bloqueio

**FATO VERIFICADO — log `EXTRACAO/EXT.qvw.2026_10_08_21_36_53.log`, gerado em 08/10/2026 21:36:53 e atualizado às 21:37:14 local, fornecido pelo usuário (últimas 120 linhas).**

- `RELOAD_STARTED_UTC=2026-10-09T00:36:53.100327+00:00`, `Qv.exe exit=3`, `FAIL_CLOSED` e marcador final invalidado.
- Gate `QVD_CONTRACT_PASS REF_MUNICIPIO_PB_DERIVADA records=223 required_fields=7`, último contrato do conjunto de dez; antes, o índice `vP3ValidatedFields` já atingia `106+1`, portanto 107 campos foram inspecionados pelo Qlik.
- T07 **rodou em Qlik** para `SRC_SIH_RD`, `SRC_CNES_LT`, `SRC_CNES_ST`: cada LOAD DISTINCT capturou 36 competências; cada agregado produziu `IF 36 <> 36 OR 0 <> 0 THEN`; três `TRACE [EXTRACAO][FINAL] T07_PASS` confirmam aprovação operacional das três famílias.
- A reconciliação das referências C1–C5 produziu `IF 3 <> 3 OR 107 <= 0 OR 0 <> 0 ... OR 57 <> 57 ... OR 5202 <> 5202 ... OR 223 <> 223 ... THEN`; o caminho de erro não foi acionado.
- **Bloqueio real:** `IF ScriptErrorCount > 0 THEN` acionou `TRACE [EXTRACAO][FINAL] Script errors found after reconciliation. Errors=Syntax Error\nSyntax Error\nSyntax Error`, seguido por `EXIT SCRIPT`. A linha do log `IF ScriptErrorCount > 3 THEN` durante T07 mostra que **três erros de sintaxe já estavam acumulados antes do T07**. Não atribuir erro sem localizar as primeiras ocorrências no log completo.
- Esta evidência prova sucesso dos contratos QVD/T07 dentro do script, **mas não justifica `PHASE_III=PASS`** enquanto `ScriptErrorCount > 0`. Sem `_SUCCESS_EXTRACAO.csv`, manifesto SHA ou integração.

**DECISÃO OPERACIONAL:** manter `III_FINAL=FAIL_CLOSED` e PR #73 **Draft/sem merge**. **Não suprimir `ScriptErrorCount`, zerar artificialmente contador nem emitir marcador ignorando três erros.** Solicitar **primeiras ocorrências** de `Syntax Error`/ `Erro:` e contexto das linhas de origem no **log completo novo**, não apenas as últimas 120 linhas. Exemplo, em PowerShell:

```powershell
$log = Get-ChildItem .\\EXTRACAO -Filter "EXT.qvw*.log" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Select-String -LiteralPath $log.FullName -Pattern 'Syntax Error','Erro:', 'Error:' -Context 10,5 | Select-Object -First 12
```

A coleta de log integral é preferível se houver erros distribuídos ao longo do processamento. Depois de identificar causa e linha efetivas, corrigir o mínimo necessário no script fonte versionado e reexecutar pelo runner, preservando T29 não aprovado.


## 10. Causa-raiz demonstrada e correção mínima — log completo 08/10/2026 21:36:53

**FATO VERIFICADO — inspeção das 12.748 linhas do log completo enviado pelo responsável:** `EXT.qvw.2026_10_08_21_36_53.log` contém **exatamente três** linhas `Error: Unknown statement`, nas posições de arquivo **4199, 4361 e 4364**. O `ScriptErrorList` ao final lista três `Syntax Error`. Esses são os erros acumulados que fizeram a guarda global abortar corretamente a extração.

**Relação direta entre erros e fontes versionadas:**

1. **Log linha 4199 — `EXTRACAO/ext_main.qvs:1330`:** a mensagem `TRACE [EXTRACAO] PARTIAL STAGING: ... a seguir; historico ...` usou **`;` interno**, finalizando o `TRACE` prematuramente. O restante virou comando solto e a próxima mensagem foi associada a `Error: Unknown statement`.
2. **Log linhas 4361 e 4364 — `EXTRACAO/ext_c5_municipal_preflight.qvs:201`:** a mensagem `TRACE ... C5.1 preflight only; C5.2 may materialize ...; external residence ...` continha **dois `;` internos**. O Qlik interpretou os dois trechos residuais como comandos independentes, produzindo dois erros adicionais.
3. Como evidência de ausência de divergência de dados no gate, o mesmo log confirmou **dez contratos QVD, 107 campos físicos T08, T07 36/36 para RD/LT/ST**, e todas as condições C1–C5 atendidas, antes do bloqueio global `IF ScriptErrorCount > 0`.

**CORREÇÃO IMPLEMENTADA NA BRANCH DO PR #73 (NÃO VALIDADA AINDA NO WINDOWS):**

- `EXTRACAO/ext_main.qvs`: substituída somente a linha de `TRACE` intermediária por mensagem operacional sem `;` interno e com terminador final `;`.
- `EXTRACAO/ext_c5_municipal_preflight.qvs`: substituída somente a última mensagem de `TRACE`, sem `;` interno e mantendo os avisos de preflight e residência externa.
- `EXTRACAO/ext_c5_2_municipio_pb.qvs`: proteção preventiva da mensagem `TRACE` **executada apenas se o preflight falhar**, que também tinha `;` interno; a condição de falha, `EXIT SCRIPT`, dados, campos e saída QVD permanecem inalterados.

**Controles NÃO relaxados:** não remover ou zerar `ScriptErrorCount`; não alterar `LOAD`, `STORE`, `IF` de integridade, 107 campos T08, 3×36 competências T07, contratos municipais ou regra histórica CNES. Não fechar Fase III antecipadamente.

**Novo gate local necessário:** em branch `feat/phase-3-final-extraction-gate` limpa e atualizada, rodar `tools/run_phase3_extraction.py` uma vez com logging Qlik ativo. **Só declarar sucesso** mediante `VERDICT=PASS_LOCAL_QV_AND_SHA_RECONCILIATION`, emissão fresca de `_SUCCESS_EXTRACAO.csv`, e log novo sem `Unknown statement`/`Syntax Error`. Caso contrário, manter `PHASE_III=IN_PROGRESS` e inspecionar novo log.

**Estado:** `III_FINAL=ROOT_CAUSE_IDENTIFIED_TRACE_DELIMITERS`, `FIX_COMMITTED_TEST_PENDING`, `PR_73=DRAFT`, `T29_HISTORICAL=NOT_APPROVED`.
