# Fase V — FATO_POPULACAO: implementação candidata exclusivamente em memória

**Preparação:** 15/10/2026. **Main de origem:** `ff161025773798d893e7c02c60631e4059d0b234`. **Branch:** `feat/phase-v-fato-populacao-inmemory-20261015`.

**Estado após execução:** `POP_FACT_INMEMORY=PASS_LOCAL_REPORTED_IN_MEMORY_CANDIDATE_ONLY`; PR Draft sem merge. Autorização do responsável: próximo gate Fase V, construir/testar a candidata em memória no QlikView 12, **sem QVD, sem Link Table, sem alteração da main nem merge automático**. Este documento reúne preparação e evidência de **PASS local reportado** pelo responsável, sem auditoria independente dos arquivos binários.

## Contratos, fontes e invariantes

1. Autoridade: [AGENTS.md](../../AGENTS.md) → [current-state](../project/current-state.md) → [requisitos](../academic/requirements.md) → [Boundary 7](boundary-7-implementation-plan.md), [modelagem entregue](../academic/chapter-1-2-modeling.md) e [preflight populacional R2 integrado (#93)](phase-5-fato-populacao-readonly-preflight-2026-10-15.md).
2. O **PASS local reportado** da R2/#93 verificou fonte IBGE 669 linhas, 223 municípios, 3 anos (2017–2019), ponte projeto IBGE7↔DATASUS6 com 223 pares, SK de município `Hash128('MUN', DATASUS6)`, SK anual `Hash128('ANO',ano)`, ausência de órfãos, população inteira positiva e totais estaduais anuais. **Não refazer R1/R2**.
3. A candidata é **uma linha por município da PB × ano**, sem replicação por mês: `POPULACAO_ESTIMADA` é snapshot anual semiaditivo. Não somar 2017+2018+2019 como população do período. Não imputar residentes externos à população da PB.
4. Fontes reais QVD existentes, **somente leitura**: `EXTRACAO/QVD/SRC_IBGE_POPULACAO.qvd`, `EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.qvd`, `TRANSFORMACAO/QVD/DIM_MUNICIPIO.qvd`, `TRANSFORMACAO/QVD/DIM_TEMPO.qvd`. A ponte foi derivada **apenas** do projeto PB em III-C5.2; nenhum dígito de IBGE7 é inventado por este gate.
5. Preservar os **20 QVDs existentes** (10 staging/referência, 8 dimensões, 2 fatos), todos os QVWs/logs diagnósticos prévios e `TRANSFORMACAO/TRANSF.qvw`. Não executar `transf_main.qvs`. Não executar `STORE`, gerar `FATO_POPULACAO.qvd`, `LINK_ANALISE.qvd`, `PAINEL.qvw`, nem aprovar contrato `%LINK_KEY`.

## Projeção candidata testada em memória (QVD físico NÃO aprovado)

O script `TRANSFORMACAO/transf_fato_populacao_inmemory.qvs` cria **somente tabela residente temporária no QVW diagnóstico**, nome `FATO_POPULACAO`, com **sete colunas candidatas**:

| Campo candidato | Origem e papel |
| --- | --- |
| `[%SK_MUNICIPIO]` | lookup do `DIM_MUNICIPIO.qvd` pelo código DATASUS6 resolvido pela ponte PB (não inferido) |
| `[%SK_TEMPO_ANO]` | lookup de `DIM_TEMPO.qvd` pelo ano, sem granularidade mensal |
| `POPULACAO_ESTIMADA` | medida observada em `SRC_IBGE_POPULACAO.qvd`; sem agregação na linha |
| `FATO_POP_IBGE7_ORIGEM` | código IBGE7 observado no staging (rastreabilidade) |
| `FATO_POP_DATASUS6_REFERENCIA_PB` | código DATASUS6 vindo da referência derivada PB (rastreabilidade) |
| `FATO_POP_ANO_ORIGEM` | ano observado na linha original |
| `FATO_POP_ARQUIVO_ORIGEM` | arquivo-fonte do staging |

Os quatro últimos campos são **auxiliares candidatos de auditoria**, não alteração aprovada da modelagem acadêmica nem proposta de nova dimensão ou grão. `[%SK_MUNICIPIO]` e `[%SK_TEMPO_ANO]` são apenas validação de papel dentro deste QVW isolado. A Fase VI exigirá decisão separada sobre a representação via `%LINK_KEY` e `LINK_ANALISE`; **não foi criada serialização/hashing de link cross-fact**.

## Execução física local autorizada — realizada uma única vez

`tools/validar_fato_populacao_inmemory_qlik.ps1` reutiliza o padrão comprovado de executor COM do PR #93, com **novo QVW diagnóstico** `TRANSFORMACAO/V5_IBGE_FATO_POP_IMPL_PREFLIGHT.qvw` e `.qvw.log`, ignorados no Git. Recusa QVW/log já existentes, branch divergente, arquivos rastreados modificados, fonte ausente, QVD factual populacional/Link Table preexistente, sintaxe de IF multiline, `STORE`, carga fora dos quatro QVDs, includes, `JOIN`, BINARY/EXECUTE ou `%LINK_KEY` candidata, com inventário congelado/SHAs dos 20 QVDs antes/depois/encerramento.

**Critério estrito para `PASS_LOCAL_REPORTED` (atingido no stdout informado):**
- QlikView 12 faz `Reload()` de QVW diagnóstico isolado e gera log contemporâneo com marcadores `[V5-POP-FACT]`, sem erros, em modo `PREFLIGHT`.
- `SOURCE ROWS=669 GRAIN=669 MUNICIPIOS=223 YEARS=3 FILES=3 MISS=0 BAD_DOMAIN=0 BAD_MEASURE=0 BAD_SK=0`.
- `OUTPUT ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 FIELDS=7`.
- `ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127` (totais já reconciliados na extração e no preflight).
- `VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_QVD_APPROVED` no log e `VERDICT=PASS_LOCAL_POPULATION_IN_MEMORY_CANDIDATE_ONLY` no console, **apenas quando efetivamente executados**.
- `ALL_20_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_RELOAD/AT_END`, `NO_NEW_QVD_GENERATED=AFTER_RELOAD/AT_END`, `FACT_POPULACAO_QVD_GENERATED=False` e `LINK_ANALISE_QVD_GENERATED=False`.

**Critério BLOCKED:** qualquer divergência, ausência de log fresco, diferença de SHA/contagem/medidas/chaves ou QVW já existente. Preservar arquivos/logs, não repetir automaticamente nem alterar dados. Revisão de binários independente não foi realizada nesta etapa.

**Comando histórico já executado** na raiz do repositório, preservado abaixo apenas para rastreabilidade (**NÃO reexecutar**):

```powershell
git fetch origin
git switch feat/phase-v-fato-populacao-inmemory-20261015
git pull --ff-only
git status

powershell.exe -NoProfile -File .\tools\validar_fato_populacao_inmemory_qlik.ps1 -Root (Get-Location).Path
```

**Parada atingida:** stdout do primeiro teste local foi recebido, reconciliado com os marcadores versionados e qualificado como `PASS_LOCAL_REPORTED_IN_MEMORY_CANDIDATE_ONLY`. **Não reexecutar esse runner** nem fazer recargas R2/R3, materialização QVD ou limpeza de artefatos. Próxima etapa requer novo escopo e autorização expressa. `LINK_KEY_CONTRACT=NOT_APPROVED`, `PRODUCTION_APPROVED=False`. A `main` e o `current-state.md` não são alterados neste PR.


## Evidência nativa reportada — 15/10/2026, 23:43:18–23:43:19

**Origem da evidência:** stdout completo do PowerShell e marcadores provenientes do log do QlikView Desktop local, enviados pelo responsável nesta execução. O script e o runner foram examinados no GitHub, mas **não houve inspeção independente** do `.qvw`, do `.qvd` nem do log bruto do computador Windows. O veredito abaixo é **PASS LOCAL REPORTADO**, não auditoria física independente nem homologação de produção.

| Controle | Evidência reportada |
| --- | --- |
| Branch sincronizada | `feat/phase-v-fato-populacao-inmemory-20261015`, `git pull --ff-only` atualizado; `git status` sem alterações rastreadas (10 QVWs diagnósticos anteriores não rastreados e preservados) |
| Modalidade | `MODE=PHASE_V_POPULATION_IN_MEMORY_FACT_CANDIDATE_PREFLIGHT` |
| SHA-256 QVS da execução Windows | `3E28DECB7539E90E5314A77E7DD4E2057FDE499899AB0B943A432F117D885ADE` |
| Inventário antes do teste | `QVD_INVENTORY_BEFORE=20` |
| Escopo de recarga | `TRANSF_MAIN_NOT_EXECUTED=True`; `FACT_POP_QVD_STORE_REQUESTED=False`; `CANDIDATE_FACT_IN_MEMORY_ONLY=True`; `RELOAD_STARTED=True`; `RELOAD_RETURNED=True` |
| Artefatos diagnósticos criados | `TRANSFORMACAO/V5_IBGE_FATO_POP_IMPL_PREFLIGHT.qvw` e `TRANSFORMACAO/V5_IBGE_FATO_POP_IMPL_PREFLIGHT.qvw.log` (somente no Windows; preservar) |
| Reconciliação origem/ponte | `SOURCE ROWS=669 GRAIN=669 MUNICIPIOS=223 YEARS=3 FILES=3 MISS=0 BAD_DOMAIN=0 BAD_MEASURE=0 BAD_SK=0` |
| Reconciliação da fato residente | `OUTPUT ROWS=669 GRAIN=669 SK_PAIRS=669 MUNICIPIOS=223 YEARS=3 FILES=3 NULL=0 BAD_SK=0 FIELDS=7` |
| Totais anuais de controle | `ANNUAL GROUPS=3 BAD=0 POP2017=4025558 POP2018=3996496 POP2019=4018127` |
| Veredito Qlik | `VERDICT=PASS_IN_MEMORY_CANDIDATE_ONLY_NOT_QVD_APPROVED` |
| Veredito PowerShell | `VERDICT=PASS_LOCAL_POPULATION_IN_MEMORY_CANDIDATE_ONLY` |
| Proteção após recarga | `ALL_4_SOURCE_QVD_SHA256_UNCHANGED=AFTER_RELOAD`; `ALL_20_PREEXISTING_QVD_SHA256_UNCHANGED=AFTER_RELOAD`; `NO_NEW_QVD_GENERATED=AFTER_RELOAD` |
| Proteção final | `ALL_4_SOURCE_QVD_SHA256_UNCHANGED=AT_END`; `ALL_20_PREEXISTING_QVD_SHA256_UNCHANGED=AT_END`; `NO_NEW_QVD_GENERATED=AT_END` |
| Limite físico explícito | `FACT_POPULACAO_QVD_GENERATED=False`; `LINK_ANALISE_QVD_GENERATED=False`; `PRODUCTION_APPROVED=False` |

**Conclusão restrita:** a candidata `FATO_POPULACAO` foi construída **em memória do QVW diagnóstico**, com 669 linhas e 7 campos. A combinação município × ano e o par das duas SKs apresentaram 669 valores distintos; não houve nulidade de saída nem divergência das SKs computadas. Os 223 municípios PB e os três anos foram cobertos; os três totais populacionais de referência conferiram. Não foi comprovada persistência `FATO_POPULACAO.qvd`, nem construção/aprovação da `LINK_ANALISE`, `%LINK_KEY`, política definitiva de denominadores, filtros, painéis ou produção.

**Estado do gate:** `POP_FACT_INMEMORY=PASS_LOCAL_REPORTED_IN_MEMORY_CANDIDATE_ONLY`. **Condição de parada cumprida**; não reexecutar `validar_fato_populacao_inmemory_qlik.ps1`, não apagar os QVWs/logs locais, não regravar os 20 QVDs. O PR #94 permanece **Draft e não integrado** até deliberação de merge específica. Qualquer `FATO_POPULACAO.qvd` persistida e sua validação de reabertura requerem **gate próprio e autorização explícita**, sem antecipar o contrato cross-fact `LINK_KEY_CONTRACT=NOT_APPROVED`.
