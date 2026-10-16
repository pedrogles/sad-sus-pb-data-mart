# Fase V — gate fisico one-shot FATO_CAPACIDADE_LEITO.qvd

**Data:** 15/10/2026. **Branch:** feat/phase-v-capacidade-qvd-materialization, criada a partir do HEAD d80849293c957166336528d4d8699349399edb2f do PR #91. **Main:** 7abd1dc50c092e4235fc811fa63e4dd3a30344ac, sem alteracoes por este gate.

**Autorizacao:** o responsavel autorizou especificamente a criacao de um unico QVD de capacidade no Windows com QlikView 12, seguido por auditoria fisica em segundo QVW isolado. Nao autorizou merge, alteracao academica ou outras fatos. **Estado antes de executar:** CAPACIDADE_QVD_CREATE=AUTHORIZED_NOT_EXECUTED, READBACK=NOT_EXECUTED.

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

**Veredito final esperado, ainda NAO EXECUTADO:** VERDICT=PASS_QV_CAPACIDADE_QVD_MATERIALIZED_AND_REOPENED_CANDIDATE_ONLY. Sem aprovacao global de LINK_ANALISE, T29_HISTORICAL, escopo hospitalar por TP_UNID, indicadores, denominadores ou producao. Totais acima sao somas dos snapshots e nao capacidade anual/simultanea.

## Execucao local Windows (uma vez), na raiz do repositorio

    git fetch origin
    git switch feat/phase-v-capacidade-qvd-materialization
    git pull --ff-only
    powershell.exe -NoProfile -File .\tools\materializar_fato_capacidade_leito_qlik.ps1 -Root (Get-Location).Path

Se houver BLOCKED: nao repetir, nao deletar ou corrigir o QVD parcial/QVW/log automaticamente; enviar stdout completo e logs para analise. Se PASS: preservar SHA, QVD, dois QVWs e logs e encerrar o gate.

**Dependencia:** este PR eh stacked e usa como base o PR #91, que permanece Draft e nao integrado a main. Qualquer merge exigira autorizacao separada e verificacao de ordem. Nao iniciar FATO_POPULACAO, Link Table ou painel em decorrencia.

**Estado:** SCRIPTS_READY_FOR_ONE_SHOT_CREATE_AND_READBACK, PR_MERGED=False, PRODUCTION_APPROVED=False.
