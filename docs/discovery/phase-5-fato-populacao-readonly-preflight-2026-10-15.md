# Fase V — FATO_POPULACAO: Discovery / preflight READ-ONLY

**Data da preparação:** 15/10/2026. **Branch:** `feat/phase-v-fato-populacao-readonly-preflight-20261015`, criada da `main` `60effcfe957a9c484006cad0f2f772179b74a6de`. **Autorização:** responsável autorizou começar a Discovery/PREFLIGHT READ-ONLY da terceira fato, em branch isolada, sem merge automático.

**Estado pós-R1:** `POPULATION_PREFLIGHT_R1=BLOCKED_QVS_SCRIPT_SYNTAX`, com os quatro QVDs lidos e nenhum QVD alterado, conforme log/stdout reportado. `POPULATION_PREFLIGHT_R2=PASS_LOCAL_REPORTED_SOURCE_AND_ROLES_ONLY` após execução Windows/QlikView 12 reportada às 23:15:15; R1 permanece BLOCKED em registro histórico. Isto não aprova a FATO_POPULACAO física. **Objetivo fechado:** verificar dados e papéis já aprovados município × ano, com QlikView 12 em QVW diagnóstico, **sem criar** `FATO_POPULACAO.qvd`, `LINK_ANALISE.qvd`, fatos em memória, nem executar `TRANSF.qvw`/`transf_main.qvs`.

## Fontes versionadas e realidade conhecida

- [AGENTS.md](../../AGENTS.md), [estado](../project/current-state.md), [requisitos](../academic/requirements.md), [Boundary 7](boundary-7-implementation-plan.md), [modelagem acadêmica](../academic/chapter-1-2-modeling.md), [dataset validation](dataset-validation.md) e [guia de automação](../project/qlikview-powershell-automation.md).
- `EXTRACAO/QVD/SRC_IBGE_POPULACAO.qvd`: schema do `EXTRACAO/ext_main.qvs` com `COD_IBGE_7`, `ANO_REFERENCIA`, `UF`, `COD_UF_IBGE_2`, `COD_MUNIC_IBGE_5`, `POPULACAO_ESTIMADA`, `_META_SOURCE_FILE`, `_META_SOURCE_FAMILY`, `_META_SOURCE_YEAR`. **669 linhas esperadas** (223 municípios × 3 anos, 2017–2019).
- Totais estaduais por ano **extraídos do contrato já aplicado na extração**, não inventados: **2017 = 4.025.558**, **2018 = 3.996.496**, **2019 = 4.018.127**. Não somar anos para gerar população de período.
- `EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.qvd`: referência de **223 pares IBGE7 ↔ DATASUS6** criada/validada na Fase III-C5.2. É **derivada do projeto com apoio de dados oficiais**, não uma tabela de correspondência nacional normativa. Não reconstruir códigos no preflight.
- `TRANSFORMACAO/QVD/DIM_MUNICIPIO.qvd`: a dimensão conformada usa **`Hash128('MUN', COD_DATASUS_6)`**, com `COD_IBGE_7` associado para municípios PB, preservando residentes externos sem correspondência IBGE.
- `TRANSFORMACAO/QVD/DIM_TEMPO.qvd`: `Hash128('ANO',TEMPO_ANO)` e os anos 2017–2019. O preflight verifica SKs e associações **somente como teste em memória**, não persiste a terceira fato ou Link Table.

## Implementação autorizada e arquivos

| Arquivo novo/modificado | Papel |
| --- | --- |
| `TRANSFORMACAO/phase_v_fato_populacao_readonly_preflight.qvs` | Lê **exatamente os quatro QVDs** acima, controla códigos/domínio, origem, integridade das referências 223/223, papéis municipais/ano, SKs por recomputação, unicidade do grão, medida inteira positiva, três totais anuais e 3 arquivos fontes. Emite marcadores `[V5-POP-PREFLIGHT]`; **zero STORE** |
| `tools/validar_fato_populacao_readonly_qlik.ps1` | Na R1 criou `TRANSFORMACAO/V5_IBGE_FATO_POP_READONLY_PREFLIGHT.qvw` e log, ambos preservados. O executor corrigido exige esses artefatos e, se autorizado, cria somente `TRANSFORMACAO/V5_IBGE_FATO_POP_READONLY_PREFLIGHT_R2.qvw` e respectivo log; exige branch limpa tracked e **não** sobrescreve QVW/log; congela e compara SHA-256 de **todos os 20 QVDs** existentes, antes/depois; recusa `FATO_POPULACAO.qvd` ou `LINK_ANALISE.qvd` presentes |
| `.gitignore` | Preserva os QVWs diagnósticos R1 e R2 fora do Git; logs e QVDs já seguem política de ignore |

**Verificações condicionadas ao resultado nativo:** `SOURCE ROWS=669 GRAIN=669 IBGE7=223 YEARS=3 FILES=3 BAD_DOMAIN=0 BAD_MEASURE=0`, `REFERENCES BRIDGE=223 ... DIM_MUN=223 ... YEAR=3`, `ROLES BRIDGE_MISS=0 DIM6_MISS=0 DIM7_MISS=0 YEAR_MISS=0 SK_BAD=0`, `ANNUAL GROUPS=3 BAD=0`. Se algo divergir, marcar **BLOCKED** e preservar log/arquivo, sem tentar corrigir silenciosamente mapeamento, medida, grão ou origem.

Os marcadores Qlik **efetivamente reportados na R2** são `VERDICT=PASS_SOURCE_ROLES_ONLY_NOT_FACT_APPROVAL` e o veredito final do executor `VERDICT=PASS_LOCAL_POPULATION_SOURCE_ROLES_READ_ONLY_PREFLIGHT_ONLY`. São **PASS restritos à integridade do staging e das dimensões**, não aprovação de SK factual definitiva, `%LINK_KEY`, QVD persistido, Link Table, filtros ou indicadores.

## Execução Windows (uma única vez, após revisão)

Na raiz do repositório:

```powershell
git fetch origin
git switch feat/phase-v-fato-populacao-readonly-preflight-20261015
git pull --ff-only

powershell.exe -NoProfile -File .\tools\validar_fato_populacao_readonly_qlik.ps1 -Root (Get-Location).Path
```

**STOP ATUAL (pós-R2):** a R1 falhou no parser, a R2 foi autorizada e **executada uma única vez com PASS local reportado**. **Não reexecutar nenhum dos dois comandos**; preservar os dois QVWs e seus logs e todos os QVDs. Copiar stdout completo, preservar ambos os QVWs/logs (inclusive em falha). O runner recusa destinos preexistentes. Os 10 QVWs untracked reportados na `main` são **artefatos prévios preservados**, não candidatos a limpeza. Este gate não mexe neles.

**Decisões ainda pendentes:** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED`; não gerar `FATO_POPULACAO.qvd` nem construir a `LINK_ANALISE` sem gates e autorizações específicos. População é **snapshot anual**, nunca replicação automática mensal nem soma de anos. Respeitar DATASUS6/IBGE7 com ponte validada e sem imputar população PB a residentes externos.

**Condição de parada do gate atingida:** três condições `IF ... THEN` foram corrigidas, e a R2 teve **PASS de fonte, grão, ponte, dimensão e medida em execução local reportada**. **PR permanece Draft e não integrado**. O PASS não equivale à aprovação de `FATO_POPULACAO.qvd`, Link Table ou produção; parar e exigir novo escopo/autorização para projeção factual candidata.


## 15/10/2026 23:05:55 — Falha nativa R1, causa identificada

**Proveniência:** PowerShell e tail do log original do QlikView Desktop **12.0.20000.0** fornecidos pelo responsável após uma única execução de `tools/validar_fato_populacao_readonly_qlik.ps1`. **Não** foi recebido o QVW binário, o QVD nem o arquivo completo do log original para conferência independente.

**Resultado confirmado no stdout/log:**
- Executada a branch `feat/phase-v-fato-populacao-readonly-preflight-20261015`; QVS R1 SHA-256 `D1E77753E7F8ABFF4FC9DF76F996066E0E26AB35EDD31ACAFF2ADA4C8418C505`; `QVD_INVENTORY_BEFORE=20`.
- `SRC_IBGE_POPULACAO.qvd` carregou 669 registros; `REF_MUNICIPIO_PB_DERIVADA.qvd` carregou 223; `DIM_MUNICIPIO.qvd` com filtro PB carregou 223; `DIM_TEMPO.qvd` distinta por ano carregou 3. **Esses LOADs não validam ainda a compatibilidade das SKs, os totais anuais ou as regras de grão**.
- O Qlik retornou **erro de parser no `IF` após o quarto LOAD**, linhas QVW 0055–0059: `IF ScriptErrorCount > 0 OR` (quebra de linha) seguido por `NoOfRows('P5P_BRIDGE')<>223 OR ...` e `Erro: Comando desconhecido`. Logo: **causa de sintaxe QVS, não prova de erro de dados**.
- O runner marcou `RUNNER_FAILURE=VERDICT=BLOCKED_EXPECTED_NATIVE_MARKER_MISSING_OR_DUPLICATED` porque a execução nunca chegou ao TRACE `REFERENCES ...`.
- Proteção: `ALL_4_SOURCE_QVD_SHA256_UNCHANGED=AFTER_RELOAD/AT_END`, `ALL_20_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_RELOAD/AT_END`, `NO_NEW_QVD_GENERATED=AFTER_RELOAD/AT_END`. Nenhum `FATO_POPULACAO.qvd` ou `LINK_ANALISE.qvd` criado.
- **`R1_VERDICT=BLOCKED_QVS_SCRIPT_SYNTAX`; não PASS; produção não aprovada.**

**Correção estática estritamente delimitada, NÃO executada nativamente:** os **três IF de nível de script** que atravessavam várias linhas foram unidos em instruções individuais `IF ... THEN` (a função `If(...)` de expressões `LOAD` permanece inalterada); nenhum `STORE`, hash de SK, medida, fonte ou papel foi modificado. O executor passou a:
1. exigir a presença do QVW e log **R1 originais**, com marcadores do erro de parser reportado, sem sobrescrevê-los;
2. exigir a ausência de `IF` de nível de script quebrado entre linhas;
3. utilizar um **único caminho novo** `TRANSFORMACAO/V5_IBGE_FATO_POP_READONLY_PREFLIGHT_R2.qvw` e log correspondente;
4. preservar todas as 20 QVDs originais (SHA-256) e impedir geração de novos QVDs, identicamente à R1.

**DECISÃO PENDENTE:** autorização específica de **uma execução R2** em Windows/QlikView 12 para o mesmo gate READ-ONLY, depois de `git fetch`, `git switch` na mesma branch e `git pull --ff-only`. Não executar automaticamente; em qualquer nova falha, parar e analisar o primeiro erro real antes de alterar novamente o QVS. Nenhum merge ou implementação da fato autorizados por esta correção.


## 15/10/2026 23:15:15 — Evidência nativa R2: PASS local reportado

**Origem e nível de evidência:** saída completa do PowerShell e marcadores do log QlikView 12 fornecidos pelo responsável após `git fetch`, troca para a branch deste PR e `git pull --ff-only` (de `5ec7b87` para `ddaa12d`). O agente confrontou os marcadores com o QVS e o runner versionados, mas **não obteve acesso independente** aos binários QVW/QVD locais, logs brutos completos nem à sessão QlikView. Logo: `GATE_PASS_LOCAL_REPORTED`, **não** `PASS_INDEPENDENT_ARTIFACT_AUDIT`, **não** `PRODUCTION_APPROVED`.

| Controle | Resultado reportado |
| --- | --- |
| Execução e branch | `MODE=PHASE_V_POPULATION_READ_ONLY_PREFLIGHT_R2_PARSER_REPAIR`, `feat/phase-v-fato-populacao-readonly-preflight-20261015` |
| Evidência R1 preservada | `R1_PARSER_ERROR=CONFIRMED_R1_DIAGNOSTICS_PRESERVED` |
| QVS R2 SHA-256 | `E9E7CE1FCB612B05918A95A112AF37F4A8440B88772505ACE595E9ADAC70312F` |
| QVDs prévios | `QVD_INVENTORY_BEFORE=20` |
| QVW R2 e log | `TRANSFORMACAO/V5_IBGE_FATO_POP_READONLY_PREFLIGHT_R2.qvw` e `.qvw.log`; QVW/log R1 separados e preservados |
| Leitura/transformação | `TRANSF_MAIN_NOT_EXECUTED=True`, `FACT_POP_QVD_STORE_REQUESTED=False`, `RELOAD_STARTED=True`, `RELOAD_RETURNED=True` |
| Ponte + dimensões | `REFERENCES BRIDGE=223 BRIDGE_U7=223 BRIDGE_U6=223 BRIDGE_BAD=0 DIM_MUN=223 DIM_U7=223 DIM_U6=223 DIM_USK=223 DIM_BAD=0 YEAR=3 YEAR_U=3 YEAR_SK=3 YEAR_BAD=0` |
| Fonte e grão | `SOURCE ROWS=669 GRAIN=669 IBGE7=223 YEARS=3 FILES=3 BAD_DOMAIN=0 BAD_MEASURE=0` |
| Cobertura de papéis e SKs | `ROLES BRIDGE_MISS=0 DIM6_MISS=0 DIM7_MISS=0 YEAR_MISS=0 SK_BAD=0` |
| Anos e somas de controle | `ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127` |
| Qlik nativo | `VERDICT=PASS_SOURCE_ROLES_ONLY_NOT_FACT_APPROVAL` |
| PowerShell | `VERDICT=PASS_LOCAL_POPULATION_SOURCE_ROLES_READ_ONLY_PREFLIGHT_ONLY` |
| Integridade após reload | `ALL_4_SOURCE_QVD_SHA256_UNCHANGED=AFTER_RELOAD`, `ALL_20_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_RELOAD`, `NO_NEW_QVD_GENERATED=AFTER_RELOAD` |
| Integridade no encerramento | `ALL_4_SOURCE_QVD_SHA256_UNCHANGED=AT_END`, `ALL_20_PREEXISTING_QVD_SHA256_UNCHANGED=AT_END`, `NO_NEW_QVD_GENERATED=AT_END` |
| Proibições confirmadas | `FACT_POPULACAO_QVD_GENERATED=False`, `LINK_ANALISE_QVD_GENERATED=False`, `PRODUCTION_APPROVED=False` |

**Interpretação:** o teste reportou 669 combinações únicas município × ano, 223 municípios distintos e cobertura de 2017, 2018, 2019, com três origens anuais. As 223 correspondências **derivadas e validadas para PB** resolveram os papéis municipais por códigos IBGE7 e DATASUS6, sem fabricação de dígito, e houve compatibilidade das SKs de ano e município. `POPULACAO_ESTIMADA` foi validada em domínio/inteireza e reconciliada contra cada soma anual fixada na extração. Não foi gerada tabela fato, nem `%LINK_KEY` física, nem associação inter-fatos. Os totais anuais são snapshots; não somá-los como população de um período.

**Estado final deste gate:** `POPULATION_PREFLIGHT_R1=BLOCKED_QVS_SCRIPT_SYNTAX` (histórico), `POPULATION_PREFLIGHT_R2=PASS_LOCAL_REPORTED_SOURCE_AND_ROLES_ONLY`, `PR93_MERGED=False`, `PRODUCTION_APPROVED=False`. **STOP: não executar R1 ou R2 novamente, não apagar artefatos locais e não iniciar `FATO_POPULACAO.qvd`/Link Table automaticamente.** Eventual implementação isolada em memória da terceira fato será objeto de um **novo gate e autorização específica**, preservando o grão, a semiaditividade temporal e os contratos em aberto.
