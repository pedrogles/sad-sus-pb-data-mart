# Fase V — implementação controlada de FATO_INTERNACAO (candidata)

**Data:** 15/10/2026  
**Base revisada:** `main` no commit `d9cdf3eb81ad393b1ceaeb817152a94cc0ac13d0`.  
**Branch:** `feat/phase-5-fato-internacao-implementation`.  
**Gate:** `FATO_INTERNACAO_CODE=IMPLEMENTED`; `FATO_INTERNACAO_PREFLIGHT=PASS_LOCAL_REPORTED`; `FATO_INTERNACAO_QVD_CREATE_AND_READBACK=PASS_LOCAL_REPORTED` (somente artefato local; evidência reportada).  
**Não afirmar:** aprovação física independente dos arquivos pelo agente, `PROD_APPROVED`, `LINK_KEY_CONTRACT=APPROVED` ou `PR_MERGED`. O gate físico controlado tem **PASS local reportado**, não uma homologação de produção.

## Contrato do objetivo

**Objetivo único:** implementar o script versionável `TRANSFORMACAO/transf_fato_internacao.qvs` e sua chamada opt-in em `transf_main.qvs`, sem gerar fatos das outras fontes, `LINK_ANALISE.qvd`, painel, indicadores ou alterações das dimensões/modelo acadêmico.

**Fontes de verdade:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, Boundaries 6/7, `phase-5-fato-internacao-sk-preflight-2026-10-09.md`, `phase-5-fato-internacao-contract-2026-10-09.md` e o commit histórico `26369052bd3f96de5f3eccf873c390053c20b561` (serializador/projeção associativa SAD-LINK-V1). O contrato semântico V2 em `main` é **somente semântico**.

**Limites:** histórico SIH/RD PB 2017–2019 congelado; `SK_REGISTRO_INTERNACAO` é assinatura de arquivo+conteúdo, não identificador estável depois de correções. `N_AIH` não é PK. `IDENT=5` é continuidade e `QTD_INTERNACAO=0`. Manter os 5.202 residentes externos sem atribuição artificial de população PB.

## Schema pretendido da fato

| Grupo | Campos físicos |
| --- | --- |
| Identidade técnica | `SK_REGISTRO_INTERNACAO`, `%LINK_KEY` |
| Papéis exclusivos | `%SK_TEMPO_INTERNACAO`, `%SK_TEMPO_SAIDA`, `%SK_PROCEDIMENTO`, `%SK_DIAGNOSTICO`, `%SK_CARATER_ATENDIMENTO`, `%SK_MOTIVO_SAIDA` |
| Rastreabilidade | `N_AIH`, `IDENT`, `FATO_RD_ARQUIVO_ORIGEM`, `FATO_RD_COMPETENCIA_ORIGEM` |
| Cinco medidas | `QTD_REGISTRO_AIH`, `QTD_INTERNACAO`, `DIAS_PERMANENCIA`, `VALOR_TOTAL`, `INDICADOR_OBITO` |

As cinco coordenadas de competência, ano, residência, serviço e estabelecimento **não** são expostas como campos compartilhados adicionais na fato; somente formam `%LINK_KEY`. O hash usa literalmente `Hash128('SAD-LINK-V1', 'C=' & ..., 'Y=' & ..., 'R=' & ..., 'S=' & ..., 'E=' & ...)` e os tokens `N` ou `V<comprimento>:<Text(SK)>`. O contrato do algoritmo é restrito ao snapshot e não implica aprovação da Link Table. Os campos de proveniência são aliases de metadados existentes no staging, não novas entidades de negócio.

`VAL_TOT` exige `Num#(Trim(Text(VAL_TOT)),'#','.',',')`: a conversão foi provada em pré-validação isolada R3, e seu uso dentro da transformação final **ainda exige validação nativa**. Dinheiro é reconciliado em centavos inteiros pela soma de `Round(VALOR_TOTAL*100,1)`; `VALOR_TOTAL` armazena reais. **Atualização de evidência:** a execução local relatada em 15/10/2026 confirmou essa conversão no QVS factual em memória e, posteriormente, no QVD reaberto (ver gate de criação física).

## Modo de execução e segurança

A última seção de `transf_main.qvs` define `SET vP5FatoInternacaoMode=OFF;`. O include somente executa quando essa configuração é deliberadamente alterada:

- `OFF`: padrão, preserva o comportamento de Fase IV na `main`.
- `PREFLIGHT`: valida em memória a projeção factual e emite `PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_PHYSICAL_APPROVAL`; não faz `STORE` da fato.
- `CREATE`: depois dos gates, recusa QVD factual preexistente, revalida e grava apenas `QVD/FATO_INTERNACAO.qvd`, terminando com `WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT`.

**Atenção operacional:** um reload de `TRANSF.qvw` também executa os scripts da Fase IV ANTES do bloco opt-in, que **gravam QVDs dimensionais e checkpoints**. Portanto, o modo `PREFLIGHT` não deve ser anunciado como reload global READ-ONLY. Usar cópia/ambiente de teste ou preservar hashes e backups apropriados para esses QVDs antes de qualquer reload. A ferramenta COM disponível aqui não executou QlikView 12 nesta implementação. O `STORE` de QVD não é transação atômica; não sobrescrever arquivos existentes.

## Critérios de validação local exigidos

| Verificação | Resultado necessário |
| --- | --- |
| Contagem e grão | 566.672 linhas, 566.672 `SK_REGISTRO_INTERNACAO` distintas, 0 SKs nulas |
| Fonte congelada | 36 competências e 36 arquivos RD, 5.202 residentes externos |
| Internações | `QTD_REGISTRO_AIH=566672`, `QTD_INTERNACAO=555089`, `IDENT=5: 11583` |
| Óbitos / dias / monetário | 26.611 óbitos; 3.133.578 dias; 65.938.464.905 centavos |
| Dimensional | 11/11 papéis com zero órfãos; não relaxar o alerta histórico `MOT` R1 |
| Ano 2017 | 187.726 linhas; 183.532 novas; 4.194 continuações; 8.626 óbitos; 1.039.396 dias; R$ 208.882.120,74 |
| Ano 2018 | 187.293 linhas; 183.311 novas; 3.982 continuações; 8.649 óbitos; 1.038.921 dias; R$ 218.267.536,76 |
| Ano 2019 | 191.653 linhas; 188.246 novas; 3.407 continuações; 9.336 óbitos; 1.055.261 dias; R$ 232.234.991,55 |
| `%LINK_KEY` | 1 chave não nula por fato, SAD-LINK-V1, sem exposição das cinco SKs compartilhadas como colunas de fato |
| Preservação | SHA dos QVDs de staging inalterado; verificação de arquivos de destino e QVDs dimensionais executados conforme modo |
| QVD materializado | após `CREATE`, reabrir e auditar QVD independentemente; verificação em memória não basta |

**Executor de gate isolado executado uma vez no Windows, conforme transcrição do responsável:** `tools/validar_fato_internacao_impl_qlik.ps1`, baseado nos dois validadores QlikView R3 já integrados. Cria/reutiliza exclusivamente `TRANSFORMACAO/V5_RD_FATO_INTERNACAO_PREFLIGHT.qvw` e seu log, sem abrir `TRANSF.qvw` nem invocar `transf_main.qvs`. Injeta em memória os comandos `SET ErrorMode=0;` e `SET vP5FatoInternacaoMode=PREFLIGHT;`, mantendo integralmente o QVS factual versionado. O executor exige branch correta, arquivos de origem, script QVW compatível, hashes SHA-256 dos oito QVDs (staging + sete dimensões), integridade do possível QVD factual preexistente e marcadores QlikView nativos exatos. Não edita arquivos do repositório, nem gera qualquer QVD; apenas o QVW e log diagnósticos locais são escritos.

No Windows/PowerShell, a partir da raiz da branch `feat/phase-5-fato-internacao-implementation` com working tree rastreada limpa:

```powershell
git switch feat/phase-5-fato-internacao-implementation
git pull --ff-only
powershell.exe -NoProfile -File .\tools\validar_fato_internacao_impl_qlik.ps1 -Root (Get-Location).Path
```

**Execução encerrada com PASS local reportado em 15/10/2026.** Não repetir o mesmo reload para ampliar escopo. Este comando fica documentado para rastreabilidade, não é uma instrução para executá-lo novamente.

## Resultado do gate isolado — 15/10/2026 (evidência local reportada)

**Proveniência:** saída de PowerShell e trechos do log nativo QlikView 12 **fornecidos pelo responsável no chat** após `git fetch`, `git switch` e `git pull --ff-only`. O arquivo `.qvw.log` binário/textual original e os oito QVDs locais **não foram coletados nem verificados independentemente** nesta revisão GitHub. Não equivale a CI.

- **Runner:** `tools/validar_fato_internacao_impl_qlik.ps1`, QVW isolado **novo** (`DOCUMENT_REUSED=False`).
- **SHA-256 QVS informado:** `5C599F1FCBF54E823A3FF82FAF14EA2176EE2BFAC7D5ABE33743CB4CEC9CC65D`.
- **Log relatado:** `TRANSFORMACAO/V5_RD_FATO_INTERNACAO_PREFLIGHT.qvw.log`, eventos entre `2026-10-15 21:14:42` e `21:14:53` (horário de impressão local, sem metadado de fuso no trecho).
- **Execução COM:** `RELOAD_STARTED=True`, `RELOAD_RETURNED=True`, `RELOAD_API_RETURN=` vazio. O resultado foi confirmado pelos TRACE contemporâneos e pelo veredito do runner, **não** pelo retorno COM.
- **Integridade:** `ALL_8_INPUT_QVD_SHA256_UNCHANGED=True`, `FACT_QVD_UNCHANGED_OR_ABSENT=True`, `TRANSF_MAIN_NOT_EXECUTED=True`, `NO_FACT_QVD_STORE_REQUESTED=True`.
- **Onze papéis:** `COMP=0 ANO=0 INTER=0 SAIDA=0 RES=0 SERV=0 EST=0 PROC=0 DIAG=0 CAR=0 MOT=0`.
- **Fonte:** `ROWS=566672 UNIQUE=566672 MONTHS=36 FILES=36 EXTERNAL=5202 NULL=0 REG=566672 NEW=555089 CONT=11583 DAYS=3133578 DEATHS=26611 CENTS=65938464905 INVALID=0`.
- **Ano:** `YEARS=3 YEAR_BAD=0`.
- **Projeção em memória:** `OUTPUT UNIQUE=566672 NULL=0 LINKS=77550 ROWS=566672 NEW=555089 DAYS=3133578 DEATHS=26611 CENTS=65938464905`.
- **Veredito emitido:** `VERDICT=PASS_ISOLATED_FACT_PREFLIGHT_NOT_QVD_APPROVAL`, `FACT_QVD_GENERATED=False`, `LINK_ANALISE_QVD_GENERATED=False`.

**Interpretação:** `77.550` é a cardinalidade distinta de `%LINK_KEY` **dentro da FATO_INTERNACAO** testada; não é a cardinalidade da constelação de três fatos (`85.705` pares no ensaio histórico) nem evidência de aceitação definitiva da `LINK_ANALISE`. A pré-validação passou para o snapshot local informado. A presença de 11/11 SKs sem órfãos continua distinta da validação de associações físicas no painel.

**Gate de pré-validação encerrado:** `FATO_INTERNACAO_PREFLIGHT=PASS_LOCAL_REPORTED` (ainda sem QVD naquele momento). **Gate seguinte, autorizado e executado localmente:** materializar `FATO_INTERNACAO.qvd` **em destino novo**, sem executar `transf_main.qvs` ou regravar as dimensões, depois auditar o QVD lido de volta, sua cardinalidade, schema, medidas, SKs, `%LINK_KEY` e SHA dos oito QVDs de entrada. Não usar `PREFLIGHT` como prova de `QVD_PHYSICAL_PASS` nem de `PROD_APPROVED`.

**Sequência mínima:** (1) assegurar árvore de trabalho limpa e identidade da branch/inputs; (2) revisar o QVS e executar primeiro o modo `PREFLIGHT` somente no ambiente QlikView 12 controlado, guardando log contemporâneo; (3) confirmar resultados e preservação; (4) deliberar sobre `CREATE` e, se autorizado, executar contra destino vazio; (5) auditar `FATO_INTERNACAO.qvd` gerado e registrar o resultado do gate sem declarar aprovação da Link Table. Em erro de parser, ScriptErrorCount, recarga, comparação ou SHA, interromper: **não** editar a fonte, ignorar linha ou executar o próximo modo.

## Limites e condição de parada

- `LINK_KEY_CONTRACT=NOT_APPROVED` formalmente até aceite restrito separado do responsável; o script incorpora a candidata já revisada, mas não constitui aprovação unilateral.
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED`, `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`.
- `LINK_ANALISE_QVD=NOT_STARTED`, `PAINEL=NOT_STARTED`; nenhuma lógica dos indicadores V2 foi implementada.
- Encerrar este PR assim que o script da **primeira fato** e seu gate QVD estiverem revisados. Fatos CNES/IBGE, Link Table e painel são gates separados, obedecendo o Boundary 7.

## Gate de criação física — PASS local reportado em 15/10/2026

O responsável autorizou a materialização controlada e uma auditoria independente do QVD da primeira fato. A autorização não cobre merge, demais fatos, Link Table ou painel.

- Executor: `tools/materializar_fato_internacao_qlik.ps1`.
- Auditor independente: `TRANSFORMACAO/phase_v_fato_internacao_qvd_readback.qvs`.
- Destino exclusivo: `TRANSFORMACAO/QVD/FATO_INTERNACAO.qvd`, obrigatoriamente ausente antes da execução.
- Pré-condições: branch correta, worktree rastreada limpa, pré-validação documentada, mesmo SHA-256 do QVS factual, QVWs/logs de CREATE e auditoria novos.
- Proteção: inventário e SHA-256 de todos os QVDs existentes de extração e transformação; somente um novo QVD permitido.
- Auditoria: segunda recarga QlikView, lendo o QVD físico, 17 campos exatos, 566.672 linhas e SKs únicas, 77.550 chaves de ligação, medidas anuais e gerais reconciliadas.
- Veredito **recebido na transcrição local**: `PASS_QV_FACT_QVD_MATERIALIZED_AND_REOPENED_CANDIDATE_ONLY`. A inspeção independente dos arquivos binários e dos logs completos não foi realizada nesta sessão.

Execução única no PowerShell (na raiz da branch):

```powershell
git fetch origin
git switch feat/phase-5-fato-internacao-implementation
git pull --ff-only
powershell.exe -NoProfile -File .\tools\materializar_fato_internacao_qlik.ps1 -Root (Get-Location).Path
```

**Não executar duas vezes.** Se ocorrer bloqueio, preservar o QVD eventual e os logs. Não apagar, substituir, reexecutar automaticamente ou chamar `TRANSF.qvw` para corrigir. Submeter a saída para revisão antes de qualquer merge.

**Status:** `CREATE_AND_READBACK=PASS_LOCAL_REPORTED`, `QVD_PHYSICAL_GATE=PASS_LOCAL_REPORTED_SCOPE_ONLY`, `PR_MERGED=False`, `PROD_APPROVED=False`. Não repetir `CREATE`, pois o destino existe.

### Evidência de execução da criação e leitura posterior — relato do responsável (15/10/2026)

**Origem e abrangência:** saída integral de PowerShell e trechos dos dois logs nativos apresentados pelo responsável no chat, executados no Windows com QlikView Desktop 12. O agente conferiu coerência com os marcadores exigidos pelo executor versionado, mas **não obteve o QVD local nem os logs originais para auditoria independente fora do ambiente reportado**. Trata-se de PASS de execução física **local reportada**, não CI ou homologação de produção.

| Controle | Evidência reportada |
| --- | --- |
| Branch carregada | `feat/phase-5-fato-internacao-implementation`, fast-forward até `6ade958` |
| Inventário inicial | 18 QVDs existentes |
| Modo | `PHASE_V_FATO_INTERNACAO_ONE_SHOT_CREATE_AND_READBACK` |
| QVS factual SHA-256 | `5C599F1FCBF54E823A3FF82FAF14EA2176EE2BFAC7D5ABE33743CB4CEC9CC65D` (mesmo preflight) |
| QVS de auditoria SHA-256 | `81C582F7C37C6E93487C555A97BAABD6045DF0EFAFD11C9B7E89CB1779125436` |
| Destino gerado | `TRANSFORMACAO/QVD/FATO_INTERNACAO.qvd` |
| Tamanho | 37.619.782 bytes |
| SHA-256 do QVD físico antes e depois do readback | `A5D300F259FFC9A4E6835DB8E9E4664700EFAE46FB09D452C5DAE684376DF5B2` |
| Proteção de entrada e do inventário | `ALL_8_INPUT_QVD_SHA256_UNCHANGED=AFTER_CREATE/AFTER_AUDIT`; `ALL_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_CREATE/AFTER_AUDIT`; `ONLY_NEW_QVD_IS_FATO_INTERNACAO=AFTER_CREATE/AFTER_AUDIT` |
| Integridade de papeis dimensionais | onze papéis com `0` órfãos |
| QVD reaberto | `HEADER ROWS=566672 FIELDS=17`; `SCHEMA_EXACT_17=True` |
| Dados lidos do QVD | `ROWS=566672 UNIQUE=566672 LINKS=77550 MONTHS=36 FILES=36 NULL=0 REG=566672 NEW=555089 CONT=11583 DEATHS=26611 DAYS=3133578 CENTS=65938464905 INVALID=0` |
| Anual | `ANNUAL YEARS=3 BAD=0` |
| CREATE (21:27:13) | `VERDICT=WRITTEN_PENDING_INDEPENDENT_QVD_AUDIT` |
| READBACK (21:27:18) | `VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY` |
| Runner | `VERDICT=PASS_QV_FACT_QVD_MATERIALIZED_AND_REOPENED_CANDIDATE_ONLY` |
| Escopo não realizado | `LINK_ANALISE_QVD_GENERATED=False`; `PRODUCTION_APPROVED=False` |

**Interpretação do resultado:** o segundo QVW abriu o QVD efetivamente escrito pelo primeiro, confirmou 17 colunas em ordem e reconciliou registros, unicidade, `%LINK_KEY` da própria fato, medidas e totais por ano. O hash antes/depois da segunda leitura coincidiu. O retorno COM `CREATE_RELOAD_API_RETURN=` e `AUDIT_RELOAD_API_RETURN=` ficou vazio, mas o runner observou logs contemporâneos e emitidos pelos QVWs de cada etapa. Os 18 QVDs prévios foram preservados segundo o inventário/hash feito no Windows.

**Condição de parada atingida:** a primeira materialização factual está **fisicamente criada e reaberta no ambiente local reportado**; o objetivo do gate CREATE+READBACK foi alcançado. Não executar novamente o mesmo `STORE`, pois o script falha fechado se o arquivo de destino já existir. Não avançar automaticamente para `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`, `LINK_ANALISE` ou painel. O PR #88 permanece Draft e não integrado à `main`; revisar a evidência e solicitar autorização específica antes de merge. `LINK_KEY_CONTRACT=NOT_APPROVED` e indicadores/denominadores/filtros continuam fora do gate.
