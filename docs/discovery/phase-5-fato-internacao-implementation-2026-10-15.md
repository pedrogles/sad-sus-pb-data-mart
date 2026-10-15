# Fase V — implementação controlada de FATO_INTERNACAO (candidata)

**Data:** 15/10/2026  
**Base revisada:** `main` no commit `d9cdf3eb81ad393b1ceaeb817152a94cc0ac13d0`.  
**Branch:** `feat/phase-5-fato-internacao-implementation`.  
**Gate:** `FATO_INTERNACAO_CODE=IMPLEMENTED_NOT_QV_VALIDATED`; `FATO_INTERNACAO_QVD=NOT_GENERATED`.  
**Não afirmar:** `PHYSICAL_GATE_PASS`, `PROD_APPROVED` ou `PR_MERGED`.

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

`VAL_TOT` exige `Num#(Trim(Text(VAL_TOT)),'#','.',',')`: a conversão foi provada em pré-validação isolada R3, e seu uso dentro da transformação final **ainda exige validação nativa**. Dinheiro é reconciliado em centavos inteiros pela soma de `Round(VALOR_TOTAL*100,1)`; `VALOR_TOTAL` armazena reais.

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

**Sequência mínima:** (1) assegurar árvore de trabalho limpa e identidade da branch/inputs; (2) revisar o QVS e executar primeiro o modo `PREFLIGHT` somente no ambiente QlikView 12 controlado, guardando log contemporâneo; (3) confirmar resultados e preservação; (4) deliberar sobre `CREATE` e, se autorizado, executar contra destino vazio; (5) auditar `FATO_INTERNACAO.qvd` gerado e registrar o resultado do gate sem declarar aprovação da Link Table. Em erro de parser, ScriptErrorCount, recarga, comparação ou SHA, interromper: **não** editar a fonte, ignorar linha ou executar o próximo modo.

## Limites e condição de parada

- `LINK_KEY_CONTRACT=NOT_APPROVED` formalmente até aceite restrito separado do responsável; o script incorpora a candidata já revisada, mas não constitui aprovação unilateral.
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED`, `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`.
- `LINK_ANALISE_QVD=NOT_STARTED`, `PAINEL=NOT_STARTED`; nenhuma lógica dos indicadores V2 foi implementada.
- Encerrar este PR assim que o script da **primeira fato** e seu gate QVD estiverem revisados. Fatos CNES/IBGE, Link Table e painel são gates separados, obedecendo o Boundary 7.
