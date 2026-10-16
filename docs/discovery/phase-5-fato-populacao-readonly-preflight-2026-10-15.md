# Fase V — FATO_POPULACAO: Discovery / preflight READ-ONLY

**Data da preparação:** 15/10/2026. **Branch:** `feat/phase-v-fato-populacao-readonly-preflight-20261015`, criada da `main` `60effcfe957a9c484006cad0f2f772179b74a6de`. **Autorização:** responsável autorizou começar a Discovery/PREFLIGHT READ-ONLY da terceira fato, em branch isolada, sem merge automático.

**Estado pós-R1:** `POPULATION_PREFLIGHT_R1=BLOCKED_QVS_SCRIPT_SYNTAX`, com os quatro QVDs lidos e nenhum QVD alterado, conforme log/stdout reportado. `POPULATION_PREFLIGHT_R2=READY_STATIC_ONLY_NOT_EXECUTED`. Não declarar PASS antes de evidência nativa da R2. **Objetivo fechado:** verificar dados e papéis já aprovados município × ano, com QlikView 12 em QVW diagnóstico, **sem criar** `FATO_POPULACAO.qvd`, `LINK_ANALISE.qvd`, fatos em memória, nem executar `TRANSF.qvw`/`transf_main.qvs`.

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

O marcador Qlik esperado, **não executado nesta autoria**, é `VERDICT=PASS_SOURCE_ROLES_ONLY_NOT_FACT_APPROVAL`. O veredito do executor esperado é `VERDICT=PASS_LOCAL_POPULATION_SOURCE_ROLES_READ_ONLY_PREFLIGHT_ONLY`. São **PASS restritos à integridade do staging e das dimensões**, não aprovação de SK factual definitiva, `%LINK_KEY`, QVD persistido, Link Table, filtros ou indicadores.

## Execução Windows (uma única vez, após revisão)

Na raiz do repositório:

```powershell
git fetch origin
git switch feat/phase-v-fato-populacao-readonly-preflight-20261015
git pull --ff-only

powershell.exe -NoProfile -File .\tools\validar_fato_populacao_readonly_qlik.ps1 -Root (Get-Location).Path
```

**STOP:** a R1 já foi executada e falhou com erro do parser. **Não reexecutar o comando até autorização específica da R2**; quando autorizada, usar o mesmo caminho de runner atualizado, que cria destino novo `_R2` e preserva R1. Copiar stdout completo, preservar ambos os QVWs/logs (inclusive em falha). O runner recusa destinos preexistentes. Os 10 QVWs untracked reportados na `main` são **artefatos prévios preservados**, não candidatos a limpeza. Este gate não mexe neles.

**Decisões ainda pendentes:** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED`; não gerar `FATO_POPULACAO.qvd` nem construir a `LINK_ANALISE` sem gates e autorizações específicos. População é **snapshot anual**, nunca replicação automática mensal nem soma de anos. Respeitar DATASUS6/IBGE7 com ponte validada e sem imputar população PB a residentes externos.

**Condição de parada de reparo estático:** três condições `IF ... THEN` corrigidas no QVS para uma instrução por linha; executor R2 preparado, ainda não testado. **PR permanece Draft e não integrado**. A autoria não constitui PASS de QlikView nem aprova QVD factual. Depois de PASS local reportado, documentar evidência e **parar**, antes de eventual autorização separada para projeção factual candidata.


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
