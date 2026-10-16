# Fase V — FATO_CAPACIDADE_LEITO: implementação candidata em memória (15/10/2026)

**Repositório:** `pedrogles/sad-sus-pb-data-mart`. **Base canônica desta implementação:** `main` em `7abd1dc50c092e4235fc811fa63e4dd3a30344ac`. **Branch separada:** `feat/phase-v-fato-capacidade-implementation`.

**Estado:** `FATO_CAPACIDADE_LEITO_CODE=CANDIDATE_WRITTEN_STATIC_ONLY`; `FATO_CAPACIDADE_LEITO_NATIVE_QV_PREFLIGHT=NOT_RUN`; `FATO_CAPACIDADE_LEITO_QVD=NOT_GENERATED`; `PR_MERGED=False`; `PRODUCTION_APPROVED=False`. O responsável autorizou implementar **somente candidato e teste isolado em memória**; não autorizou escrita de QVD ou merge.

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

**Validações implementadas no QVS candidato:** 35.518 linhas/35.518 `SK_REGISTRO_CAPACIDADE_LEITO` distintas, 36 competências/36 arquivos, 57 pares, 2.021 par-mês, regressões `3/66=1480` e `7/70=5`; zero chaves nulas/órfãs em `COMP`, `ANO`, `MUNICIPIO_SERVICO`, `ESTABELECIMENTO`, `TIPO_LEITO`; três medidas inteiras não negativas e saldo igual; três anos de 12 competências; a projeção de 11 colunas reconcilia novamente totais e unicidade, com `%LINK_KEY` não nula e distinta em algum número **ainda não medido**. Totais `337147,270076,67071` são **somatórios de snapshots** para diagnóstico, não oferta total de leitos ou denominador de indicador.

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

**Esperado, não executado:** `VERDICT=PASS_ISOLATED_CAPACIDADE_FACT_PREFLIGHT_CANDIDATE_ONLY`; marcadores `SOURCE`, `ROLES`, `SNAPSHOT_SUMS_UNSAFE_AS_PERIOD_TOTAL`, `YEARS=3 YEAR_BAD=0`, `OUTPUT ROWS=35518 UNIQUE=35518 LINKS=<medido pelo Qlik> NULL=0 EXIST=337147 SUS=270076 NSUS=67071 INVALID=0`; `ALL_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_RELOAD`; `FACT_CAPACIDADE_LEITO_QVD_GENERATED=False`. **Não antecipar PASS antes de log local.**

**Fail-closed:** ao detectar QVD de entrada ausente/alterado, QVW/log anterior, QVD de destino, branch errada, erro Qlik ou marcador inválido, parar e preservar evidências. Não repetir comando, corrigir hashes/limpar arquivos por automatismo, nem executar `TRANSF.qvw` ou `STORE` para superar uma falha. Veredito `BLOCKED` exige análise do log antes de qualquer nova proposta de teste.

## Estado final do escopo e gates seguintes

**Entrega atual:** código de candidato + runner + documentação submetidos como PR Draft, aguardando **uma recarga nativa isolada** no QlikView 12. A revisão estática não valida funcionamento nativo, cardinalidade de links entre as três fatos, filtros, indicadores ou QVD persistido. Depois de PASS local, haverá revisão separada do contrato de SK/Link candidato. A geração física de `FATO_CAPACIDADE_LEITO.qvd` é **outro gate, com autorização específica** e auditoria independente do QVD já persistido. Não integrar `main` nem iniciar `FATO_POPULACAO` por consequência desta execução.

**Condição de parada deste trabalho de autoria:** preparar candidata testável e entregar instrução de execução, preservando `main`. `FATO_CAPACIDADE_LEITO_CODE=READY_FOR_NATIVE_PREFLIGHT`, `FATO_CAPACIDADE_LEITO_QVD=NOT_GENERATED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `PRODUCTION_APPROVED=False`.
