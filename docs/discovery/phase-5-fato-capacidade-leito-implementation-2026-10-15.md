# Fase V — FATO_CAPACIDADE_LEITO: implementação candidata em memória (15/10/2026)

**Repositório:** `pedrogles/sad-sus-pb-data-mart`. **Base canônica desta implementação:** `main` em `7abd1dc50c092e4235fc811fa63e4dd3a30344ac`. **Branch separada:** `feat/phase-v-fato-capacidade-implementation`.

**Estado após saída local do responsável:** `FATO_CAPACIDADE_LEITO_CODE=CANDIDATE_QVS_VERSIONED`; `FATO_CAPACIDADE_LEITO_NATIVE_QV_PREFLIGHT=PASS_LOCAL_REPORTED`; `FATO_CAPACIDADE_LEITO_QVD=NOT_GENERATED`; `PR_MERGED=False`; `PRODUCTION_APPROVED=False`. O responsável autorizou implementar **somente candidato e teste isolado em memória**; não autorizou escrita de QVD ou merge.

## Delimitação da execução

**Objetivo:** obter uma projeção factual em QlikView 12 a partir de `EXTRACAO/QVD/SRC_CNES_LT.qvd` e validar em memória uma linha por `(CNES,COMPETEN,CODLEITO)`, medidas e chaves dimensionais. Encerrar ao receber PASS/BLOCKED do executor isolado, sem criar QVD factual.

**Fontes consultadas na ordem de governança:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/academic/chapter-1-2-modeling.md`, `docs/discovery/boundary-6-qlikview-physical-architecture.md`, `docs/discovery/boundary-7-implementation-plan.md`, `docs/discovery/dataset-validation.md`, `docs/discovery/boundary-3-full-dataset-validation.md`, `docs/discovery/phase-4-dim-tipo-leito-discovery-2026-10-09.md`, `docs/project/qlikview-powershell-automation.md`, a implementação `TRANSFORMACAO/transf_fato_internacao.qvs` já integrada, e a saída/report `FATO_CAPACIDADE_LEITO` do [PR #90 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90).

**Gates anteriores reutilizados (não repetir):** preflight CNES/LT `PASS_LOCAL_QV_CAPACIDADE_LT_PREFLIGHT_ONLY_NOT_QVD_APPROVAL` conforme saída local do responsável (21:50:58–21:50:59), com 35.518/35.518 grãos, 36 competências, 36 arquivos, cinco papéis sem órfãos, medidas consistentes, agregados diagnósticos `337147/270076/67071`, 19 QVDs imutáveis. O PR #90 **não** está integrado à `main` e a verificação prévia não prova a presente projeção.

**Invariantes:** não alterar capítulos acadêmicos, grão, dimensão `DIM_TIPO_LEITO`, QVDs, `FATO_INTERNACAO.qvd`, QVWs originais, contratos semânticos nem `TRANSFORMACAO/transf_main.qvs`. Capacidade é **semi-aditiva no tempo**; nada de classificar hospitais por `TP_UNID` sem vigência demonstrada. `T29_HISTORICAL=NOT_APPROVED`; 1.965/2.021 combinações código×competência não têm descrição histórica comprovada, e isso **não** é porcentagem de leitos físicos.

## Interface da fato candidata (não é contrato físico homologado)

A projeção mantém **11 colunas** nesta ordem, sujeitas ao resultado Qlik e à revisão formal antes de qualquer `STORE`:

| Coluna candidata | Origem e significado |
| --- | --- |
| `SK_REGISTRO_CAPACIDADE_LEITO` | Impressão digital proposta `Hash128('LT', Trim(Text(CNES)), Text(COMPETEN), Text(CODLEITO))`, única no snapshot histórico; **expressão candidata, não política de SK formalmente aprovada** |
| `%LINK_KEY` | Coordenadas propostas `SAD-LINK-V1`: `C` competência, `Y` ano, `R=N` residência não aplicável, `S` município de serviço, `E` estabelecimento histórico; mesma serialização do QVS RD integrado; **não comprova compatibilidade inter-fatos nem contrato Link Table** |
| `%SK_TIPO_LEITO` | Chave exclusiva `Hash128('LEITO', TP_LEITO_normalizado, CODLEITO_textual, COMPETEN)`, contrato A2 |
| `QTD_LEITOS_EXISTENTES` | `QT_EXIST` do LT |
| `QTD_LEITOS_SUS` | `QT_SUS` do LT |
| `QTD_LEITOS_NAO_SUS` | `QT_NSUS` do LT, conferido linha a linha contra `QT_EXIST-QT_SUS` |
| `FATO_LT_CNES_ORIGEM` | CNES técnico da linha, para auditoria; não destinado a associação automática por homonímia |
| `FATO_LT_CODLEITO_ORIGEM` | `CODLEITO` textual de dois dígitos, não é SK de leito isolada |
| `FATO_LT_TIPO_TEXTO_STAGING` | `TP_LEITO` textual **como recebido do QVD**, sem alegar preservação do espaço ASCII dos CSVs de origem |
| `FATO_LT_COMPETENCIA_ORIGEM` | `COMPETEN` mensal observada |
| `FATO_LT_ARQUIVO_ORIGEM` | `_META_SOURCE_FILE` |

**Regra de associação:** competência, ano, município de serviço e estabelecimento aparecem na projeção apenas embutidos na `%LINK_KEY` candidata, não como quatro chaves compartilhadas adicionais na fato. As dimensões conformadas serão associadas pela Link Table em fase própria, não neste gate. **É proposição explícita, não contrato físico aprovado.**

**Validações implementadas no QVS candidato:** 35.518 linhas/35.518 `SK_REGISTRO_CAPACIDADE_LEITO` distintas, 36 competências/36 arquivos, 57 pares, 2.021 par-mês, regressões `3/66=1480` e `7/70=5`; zero chaves nulas/órfãs em `COMP`, `ANO`, `MUNICIPIO_SERVICO`, `ESTABELECIMENTO`, `TIPO_LEITO`; três medidas inteiras não negativas e saldo igual; três anos de 12 competências; a projeção de 11 colunas reconcilia novamente totais e unicidade, com `%LINK_KEY` não nula e **7.486 valores distintos na própria capacidade**, segundo a execução local reportada (sem validar associação entre fatos). Totais `337147,270076,67071` são **somatórios de snapshots** para diagnóstico, não oferta total de leitos ou denominador de indicador.

## Scripts e proteção operacional

- `TRANSFORMACAO/transf_fato_capacidade_leito.qvs` — somente modo `PREFLIGHT`; **não contém `STORE`, `CREATE` ou carga de Link Table**. Não está conectado ao `transf_main.qvs`.
- `tools/validar_fato_capacidade_impl_qlik.ps1` — baseado no padrão COM/PowerShell já comprovado no PR #88 e pré-teste #90, executa QVW descartável, exige log nativo novo, confere contagens e cada veredito, recalcula SHA-256 de **todos os QVDs existentes** em EXTRACAO/QVD e TRANSFORMACAO/QVD antes/depois. Recusa QVW/log ou alvo factual preexistentes.
- `.gitignore` — exclui o QVW de diagnóstico. `*.qvd` e `*.log` já estão ignorados. Binários **não** serão publicados.

**Único comando de teste previsto no Windows (somente quando a branch estiver disponível):**

```powershell
git fetch origin
git switch feat/phase-v-fato-capacidade-implementation
git pull --ff-only
powershell.exe -NoProfile -File .\tools\validar_fato_capacidade_impl_qlik.ps1 -Root (Get-Location).Path
```

**Executado e reportado pelo responsável (15/10/2026, 22:04):** `VERDICT=PASS_ISOLATED_CAPACIDADE_FACT_PREFLIGHT_CANDIDATE_ONLY`; marcadores `SOURCE`, `ROLES`, `SNAPSHOT_SUMS_UNSAFE_AS_PERIOD_TOTAL`, `YEARS=3 YEAR_BAD=0`, `OUTPUT ROWS=35518 UNIQUE=35518 LINKS=7486 NULL=0 EXIST=337147 SUS=270076 NSUS=67071 INVALID=0`; `ALL_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_RELOAD`; `FACT_CAPACIDADE_LEITO_QVD_GENERATED=False`. **PASS restrito à transcrição de stdout e marcadores de log local fornecida no chat; o agente não examinou os QVDs/QVW/log completos do computador.**

**Fail-closed:** ao detectar QVD de entrada ausente/alterado, QVW/log anterior, QVD de destino, branch errada, erro Qlik ou marcador inválido, parar e preservar evidências. Não repetir comando, corrigir hashes/limpar arquivos por automatismo, nem executar `TRANSF.qvw` ou `STORE` para superar uma falha. Veredito `BLOCKED` exige análise do log antes de qualquer nova proposta de teste.

## Estado final do escopo e gates seguintes

**Entrega atual:** código de candidato + runner + documentação submetidos como PR Draft; **uma recarga nativa isolada passou localmente e foi reportada pelo responsável**. Isso não valida cardinalidade/associações da Link Table entre fatos, estabilidade futura da SK, filtros, indicadores ou QVD persistido. A revisão separada do contrato de SK/Link candidato continua necessária. A geração física de `FATO_CAPACIDADE_LEITO.qvd` é **outro gate, com autorização específica** e auditoria independente do QVD já persistido. Não integrar `main` nem iniciar `FATO_POPULACAO` por consequência desta execução.

**Condição de parada do gate em memória:** script candidato validado em QlikView 12 **com PASS local reportado**, `FATO_CAPACIDADE_LEITO_NATIVE_QV_PREFLIGHT=PASS_LOCAL_REPORTED`, `FATO_CAPACIDADE_LEITO_QVD=NOT_GENERATED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `PRODUCTION_APPROVED=False`. Não repetir o runner: o QVW diagnóstico/log já existem no computador do responsável.


## Evidência de QlikView 12 recebida — teste da implementação (15/10/2026)

**Fonte da evidência:** stdout integral do runner e marcadores contemporâneos do log nativo colados pelo responsável. **Nível de prova:** `PASS_LOCAL_REPORTED`; os binários QVW/QVD e o log original não foram materializados ou inspecionados pelo agente. Inspeção estática e conferência de consistência com as regras do QVS versionado são complementares, não CI.

| Controle | Evidência do Windows/QlikView |
| --- | --- |
| Branch | `feat/phase-v-fato-capacidade-implementation`, `git pull --ff-only`: atualizada |
| Modo/isolamento | `PHASE_V_FATO_CAPACIDADE_LEITO_ISOLATED_IN_MEMORY_PREFLIGHT`, `START MODE=PREFLIGHT`, `TRANSF_MAIN_NOT_EXECUTED=True`, `FACT_QVD_STORE_REQUESTED=False` |
| QVS SHA-256 | `134BBD4E290FA22F6F5D728D4C080EDDF9C1C3FDE3D38448FD47FE5A0B1174D0` |
| QVW diagnóstico | `TRANSFORMACAO/V5_LT_FATO_CAPACIDADE_IMPL_PREFLIGHT.qvw` (local, não versionado) |
| Execução Qlik | `RELOAD_STARTED=True`, `RELOAD_RETURNED=True`, `RELOAD_API_RETURN=` vazio; log com resultados específicos às 22:04:17–22:04:18 |
| QVDs existentes | `QVD_INVENTORY_BEFORE=19`; `ALL_5_INPUT_QVD_SHA256_UNCHANGED=AFTER_RELOAD/AT_END`; `ALL_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_RELOAD/AT_END COUNT=19`; `NO_NEW_QVD_GENERATED=AFTER_RELOAD/AT_END` |
| Fonte/validade | `ROWS=35518 UNIQUE=35518 MONTHS=36 FILES=36 PAIRS=57 PAIR_MONTHS=2021 TYPE3_BED66=1480 TYPE7_BED70=5 NULL=0 BAD_DOMAIN=0 BAD_MEASURE=0` |
| Papéis dimensionais | `COMP=0 ANO=0 MUNICIPIO_SERVICO=0 ESTABELECIMENTO=0 TIPO_LEITO=0` |
| Medidas diagnósticas dos 36 snapshots | `EXIST=337147 SUS=270076 NSUS=67071`; não constituem capacidade simultânea, anual ou indicador temporal |
| Anos | `YEARS=3 YEAR_BAD=0` |
| Projeção da fato | `OUTPUT ROWS=35518 UNIQUE=35518 LINKS=7486 NULL=0 EXIST=337147 SUS=270076 NSUS=67071 INVALID=0` |
| Veredito Qlik | `VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_PHYSICAL_APPROVAL` |
| Veredito PowerShell | `VERDICT=PASS_ISOLATED_CAPACIDADE_FACT_PREFLIGHT_CANDIDATE_ONLY` |
| Limites explícitos | `FACT_QVD_GENERATED=False`; `LINK_TABLE_NOT_TESTED=True`; `PRODUCTION_APPROVED=False` |

**Conferência da coerência:** o PASS foi produzido pelo executor versionado após comparar os marcadores Qlik esperados com o log contemporâneo e as invariantes de preservação do inventário de QVDs. As 7.486 chaves `%LINK_KEY` são distintas **dentro desta fato apenas**; não provam cobertura, unicidade global, interseção ou cardinalidade entre `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO` e `FATO_POPULACAO`. A candidata tem 11 campos de saída, cuja aprovação física depende de persistência e auditoria QVD em gate separado.

**Revisão pós-execução sem editar scripts testados:** QVS factual com um único modo permitido `PREFLIGHT`, 0 `STORE`, 11 nomes/campos na projeção, 5 papéis dimensionais conferidos, medidas/saldo e os três grupos anuais reconciliados. PowerShell protege entradas com SHA-256 de todos os 19 QVDs, recusa QVW/log e destino factual preexistentes. `transf_main.qvs` e `FATO_INTERNACAO.qvd` intocados. Não há execução independente no ambiente do agente; `PROD_APPROVED=False`.

**Condição de parada atingida:** gate em memória encerrado com `PASS_LOCAL_REPORTED`. **Não reexecutar** `validar_fato_capacidade_impl_qlik.ps1` nem apagar QVW/log de evidência. Eventual preparação de `STORE` para `FATO_CAPACIDADE_LEITO.qvd`, segundo QVW de leitura física e autorização de escrita constituem **novo gate com escopo, contrato e aprovação específicos**. Preservar todos os registros LT, política histórica A2/T29, semi-aditividade temporal e `LINK_KEY_CONTRACT=NOT_APPROVED`. **PR #91 permanece Draft, sem merge.**
