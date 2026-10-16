# Fase V — gate fisico one-shot FATO_CAPACIDADE_LEITO.qvd

**Data:** 15/10/2026. **Branch:** feat/phase-v-capacidade-qvd-materialization, criada a partir do HEAD d80849293c957166336528d4d8699349399edb2f do PR #91. **Main:** 7abd1dc50c092e4235fc811fa63e4dd3a30344ac, sem alteracoes por este gate.

**Autorizacao:** o responsavel autorizou especificamente a criacao de um unico QVD de capacidade no Windows com QlikView 12, seguido por auditoria fisica em segundo QVW isolado. Nao autorizou merge, alteracao academica ou outras fatos. **Estado atualizado após execução local reportada:** CAPACIDADE_QVD_CREATE=PASS_LOCAL_REPORTED, READBACK=PASS_LOCAL_REPORTED; PR #92 permanece Draft, sem merge.

## Objetivo fechado e evidencias

Criar somente TRANSFORMACAO/QVD/FATO_CAPACIDADE_LEITO.qvd **se o destino nao existir**, a partir do **mesmo QVS candidato com PASS local**; abrir o QVD em um segundo QVW de auditoria independente. Encerrar com PASS local fisico candidato ou BLOCKED preservando artefatos. **Nao repetir CREATE**, mesmo se o primeiro Reload falhar depois do STORE.

Fontes: AGENTS.md, docs/project/current-state.md, docs/academic/requirements.md, docs/academic/chapter-1-2-modeling.md, Boundaries 6/7, docs/project/qlikview-powershell-automation.md e evidencias documentadas no PR #91. Preflight da candidata reportado em 15/10/2026 22:04 no QlikView 12, SHA-256 de TRANSFORMACAO/transf_fato_capacidade_leito.qvs = 134BBD4E290FA22F6F5D728D4C080EDDF9C1C3FDE3D38448FD47FE5A0B1174D0. Incluiu 35.518 linhas e SKs unicas, 7.486 links distintos somente nesta fato, 36 competencias, cinco papeis sem orfaos, medidas reconciliadas e 19 QVDs intactos, conforme saida local fornecida.

## Implementacao isolada

- TRANSFORMACAO/phase_v_capacidade_leito_qvd_create.qvs: sufixo de criacao com **exatamente um STORE**, guardas de autorizacao, destino inexistente, grão/medidas e 11 campos.
- TRANSFORMACAO/phase_v_capacidade_leito_qvd_readback.qvs: auditor somente leitura, **zero STORE**; reabre o QVD persistido em segundo QVW e testa esquema de 11 campos em ordem, SKs recomputadas, medidas, dominios e cobertura temporal.
- tools/materializar_fato_capacidade_leito_qlik.ps1: executor COM versionavel e fail-closed com dois QVWs novos, logs contemporaneos, SHA-256 dos cinco insumos e **todos os 19 QVDs preexistentes**; exige unico novo QVD e hash estavel do QVD criado apos readback.
- .gitignore: nao publicar QVWs diagnosticos; logs, QVDs e base bruta permanecem locais.

**QVS candidato preservado:** o runner compoe SET ErrorMode=0, SET vP5CapacidadeMode=PREFLIGHT, autorizacao one-shot, conteudo exato do script candidato fixado por SHA e o sufixo STORE. O candidato conclui suas validacoes em memoria antes do STORE. Sua mensagem FACT_QVD_GENERATED=False refere-se ao instante anterior a gravacao; o resultado final provem do sufixo WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT seguido pelo segundo QVW.

**Protecoes:** a branch de trabalho deve ser a esperada, sem modificacoes tracked. O executor exige log nativo da candidata que passou anteriormente e ausencia previa do destino, dos dois QVWs e de seus logs. Nao roda TRANSF.qvw nem transf_main.qvs, nao regrava FATO_INTERNACAO.qvd, dimensoes ou staging, nao produz LINK_ANALISE.qvd. Nada eh excluido nem sobrescrito. Nao versionar binarios no Git.

## Criterios de aceite nativo

**CREATE:** QVD novo nao vazio, gerado nesta recarga, unico arquivo QVD novo. 19 QVDs anteriores com SHA igual antes/depois. Confirma novamente 35.518 registros, 35.518 SKs, 7.486 links somente nesta fato, 36 meses e arquivos, 57 pares, 2.021 pares-mes, 3/66=1.480, 7/70=5, cinco papeis dimensionais sem orfaos, zero invalido ou nulo, tres anos sem problemas e medidas diagnosticas EXIST=337147, SUS=270076, NSUS=67071. O Qlik emite WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT.

**READBACK:** um segundo QVW reabre somente o QVD persistido, verifica 11 colunas com ordem exata, contagens, hashes de chaves recomputados, medidas, 3 anos, dominios, regressões e valores de origem; emite PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY. O runner verifica SHA do QVD recem-criado antes/depois da leitura.

**Veredito final atingido no Windows em 15/10/2026, segundo stdout e linhas do log nativo fornecidos pelo responsável:** VERDICT=PASS_QV_CAPACIDADE_QVD_MATERIALIZED_AND_REOPENED_CANDIDATE_ONLY. Sem aprovacao global de LINK_ANALISE, T29_HISTORICAL, escopo hospitalar por TP_UNID, indicadores, denominadores ou producao. Totais acima sao somas dos snapshots e nao capacidade anual/simultanea.

## Execucao local Windows (uma vez), na raiz do repositorio

    git fetch origin
    git switch feat/phase-v-capacidade-qvd-materialization
    git pull --ff-only
    powershell.exe -NoProfile -File .\tools\materializar_fato_capacidade_leito_qlik.ps1 -Root (Get-Location).Path

Se houver BLOCKED: nao repetir, nao deletar ou corrigir o QVD parcial/QVW/log automaticamente; enviar stdout completo e logs para analise. Se PASS: preservar SHA, QVD, dois QVWs e logs e encerrar o gate.

**Dependencia:** este PR eh stacked e usa como base o PR #91, que permanece Draft e nao integrado a main. Qualquer merge exigira autorizacao separada e verificacao de ordem. Nao iniciar FATO_POPULACAO, Link Table ou painel em decorrencia.

**Estado pós-gate:** CAPACIDADE_QVD_CREATE_READBACK=PASS_LOCAL_REPORTED, PR_MERGED=False, PRODUCTION_APPROVED=False. O QVD já existe localmente; não reexecutar CREATE nem iniciar outra fase automaticamente.


## Evidência recebida — QVD criado e reaberto (15/10/2026)

**Origem:** saída integral do PowerShell e marcadores do log QlikView 12 fornecidos pelo responsável após execução local. Esta evidência comprova **PASS físico local reportado**, mas o agente não teve acesso direto ao QVD binário, QVWs ou aos logs originais para validação independente externa.

| Controle | Resultado reportado |
| --- | --- |
| Branch executada | `feat/phase-v-capacidade-qvd-materialization`, atualizada com `git pull --ff-only` |
| Executor | `tools/materializar_fato_capacidade_leito_qlik.ps1` |
| Modo | `PHASE_V_CAPACIDADE_ONE_SHOT_CREATE_AND_READBACK` |
| SHA-256 QVS factual **preservado** | `134BBD4E290FA22F6F5D728D4C080EDDF9C1C3FDE3D38448FD47FE5A0B1174D0` |
| SHA-256 QVS STORE | `369052D225D949FB00AB2A6BD5F937F8947843EDFE07528B2BD199182A02638E` |
| SHA-256 QVS auditor | `54B8D2A8FCDBC7405E727DE5741C3333A10BEBC1DD38DCE8B81FAF845A8DD844` |
| QVD materializado | `TRANSFORMACAO/QVD/FATO_CAPACIDADE_LEITO.qvd` |
| Tamanho físico | `1519007` bytes |
| SHA-256 do QVD antes/depois do readback | `A6349BFBE5655579347DE7B554294A7EC694FBC98FAE9A77FF871062AED6E840` (**idêntico**) |
| Inventário inicial | `EXISTING_QVD_INVENTORY_COUNT=19` |
| Integridade no CREATE | `ALL_5_INPUT_QVD_SHA256_UNCHANGED=AFTER_CREATE`, `ALL_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_CREATE`, `ONLY_NEW_QVD_IS_FATO_CAPACIDADE_LEITO=AFTER_CREATE` |
| Integridade após auditoria | `ALL_5_INPUT_QVD_SHA256_UNCHANGED=AFTER_AUDIT`, `ALL_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_AUDIT`, `ONLY_NEW_QVD_IS_FATO_CAPACIDADE_LEITO=AFTER_AUDIT` |
| Qlik CREATE | `VERDICT=WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT` às 22:18:16 |
| Qlik readback | `HEADER ROWS=35518 FIELDS=11`; `SCHEMA_EXACT_11=True` às 22:18:17 |
| Corpo persistido e reconciliado | `ROWS=35518 UNIQUE=35518 LINKS=7486 MONTHS=36 FILES=36 PAIRS=57 PAIR_MONTHS=2021 TYPE3_BED66=1480 TYPE7_BED70=5 NULL=0 SK_MISMATCH=0 DOMAIN_BAD=0 EXIST=337147 SUS=270076 NSUS=67071 INVALID=0` |
| Auditoria anual | `ANNUAL YEARS=3 BAD=0` |
| Qlik readback | `VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY` às 22:18:18 |
| Runner final | `VERDICT=PASS_QV_CAPACIDADE_QVD_MATERIALIZED_AND_REOPENED_CANDIDATE_ONLY` |
| Restrições explícitas | `LINK_ANALISE_QVD_GENERATED=False`; `PRODUCTION_APPROVED=False` |

**Reconciliação:** os 35.518 registros físicos têm 35.518 identificadores únicos e 7.486 `%LINK_KEY` distintas **internamente à capacidade**. A auditoria recomputou as duas SKs persistidas (factual e tipo de leito), com `SK_MISMATCH=0`; validou 11 nomes de campos na ordem exata; preservou 36 competências/36 arquivos e as regressões históricas `3/66` e `7/70`. `337147`, `270076` e `67071` são **somatórios ao longo dos snapshots**, não quantidade de leitos simultâneos nem capacidade anual. Não foi testada a associação entre fatos, nem a aplicação temporal dos rótulos T29.

**Conclusão do gate:** `CAPACIDADE_QVD_CREATE_READBACK=PASS_LOCAL_REPORTED`, `PRODUCTION_APPROVED=False`. As validações executadas num **segundo QVW** são independentes da projeção em memória do primeiro QVW; não representam auditoria externa dos binários pelo agente. O QVD e ambos os QVWs/logs continuam **exclusivamente no computador do responsável**.

**STOP:** o executor `materializar_fato_capacidade_leito_qlik.ps1` é **one-shot e não deve ser executado novamente**. Preservar arquivo, hashes e logs. PR #92 continua Draft e empilhado sobre o PR #91, ambos não integrados. Próximo ato potencial: **revisão pré-merge dos PRs #91/#92 e autorização específica de integração**, mantendo contrato físico Link Table, escopo hospitalar e homologação de produção pendentes. Não iniciar `FATO_POPULACAO` automaticamente.
