# Fase IV — DIM_CARATER_ATENDIMENTO — Discovery e preflight (09/10/2026)

## Contrato acadêmico e decisões anteriores

**FATO VERIFICADO EM DOCUMENTAÇÃO CANÔNICA:**

- O PR [#78](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/78) da `DIM_DIAGNOSTICO` foi integrado à `main` por squash `6f565e8832521935f0ffb0c752c9c3cb5d2f72db`. A Fase IV prossegue **5/8 dimensões integradas**. Capítulos 1 e 2 da primeira entrega estão fechados e prontos para impressão.
- O capítulo 2 em `docs/academic/chapter-1-2-modeling.md` aprova `DIM_CARATER_ATENDIMENTO` com **SK, código e descrição oficial**, relacionada ao registro administrativo de internação. A dimensão representa o **domínio oficial completo**: `01` a `06`, e não apenas códigos observados nos RD.
- `docs/discovery/boundary-7-implementation-plan.md` define a SK determinística **`%SK_CARATER_ATENDIMENTO = Hash128('CAR', CAR_INT)`**; um registro por código normativo, não por competência.
- `docs/discovery/phase-3-normative-references-implementation-2026-10-07.md` e `tools/materialize_normative_references.py` confirmam a referência materializada na Fase III-C1 com **6 códigos** `01`–`06`, descrições e `fonte_oficial` com Portaria SAS/MS 719/2007. Arquivos locais: `BASE/REFERENCIAS/carater_atendimento.csv` e `manifesto_referencias_normativas.json`.
- O script `EXTRACAO/ext_main.qvs` já criou `EXTRACAO/QVD/REF_CARATER_ATENDIMENTO.qvd`, com campos físicos `CAR_INT`, `CARATER_DESCRICAO`, `CARATER_FONTE_OFICIAL` e três metadados, além do checkpoint `_CHECKPOINT_EXTRACAO_REFERENCIAS_NORMATIVAS.csv`: III-C1 **PASS**, 6 linhas distintas, **566.672 RD/0 unmatched**.
- **Chave RD real:** `CAR_INT`, validada em `docs/discovery/dataset-validation.md`. O código Qlik de III-C1 usa `Right('00' & KeepChar(Text(CAR_INT), '0123456789'), 2)` para normalizar a chave. A dimensão pode utilizar o código normativo textual de 2 caracteres. O conteúdo físico bruto e a distribuição de códigos RD **precisam ser reconfirmados localmente** antes do novo include.

### Ressalva textual explícita

O material acadêmico preserva as descrições de `05` e `06` com substantivos em minúsculas (por exemplo, `Outros tipos de acidente de trânsito`), enquanto `tools/materialize_normative_references.py` mantém capitalização diferente (`Outros tipos de Acidente de Trânsito` e `Outros tipos de Lesões e Envenenamentos...`). Não inventar novos rótulos nem alterar o relatório acadêmico fechado. O preflight abaixo atesta **correspondência literal do CSV local com o materializador normativo aprovado**; isso não substitui uma checagem editorial independente contra a portaria e o texto do professor. Se necessário para a descrição final, documentar a decisão de apresentação do rótulo sem modificar a chave ou a semântica.

## Gate IV-CAR — preflight físico READ-ONLY

Novo script versionado: **`tools/preflight_dim_carater_atendimento.py`**, na branch `feat/phase-4-dim-carater-atendimento`.

Sem criar arquivos, o script:

- confere manifesto normativo C1 `PHASE_III_C1_NORMATIVE_REFERENCES/PASS` e integridade dos dois CSVs por SHA; para a referência de caráter exige SHA `3e40a9b2a4d0e1e65df8a9000f55af6fd24880468c12faaa24384f4722330ea8` documentado no C1;
- valida as **6 linhas de caráter com código, descrição e URL** contra o materializador canônico, sem normalizar o texto ou perder o zero à esquerda;
- verifica somente os **cabeçalhos XML** de `REF_CARATER_ATENDIMENTO.qvd` (6 linhas, 6 campos) e `SRC_SIH_RD.qvd` (566.672 linhas com `CAR_INT`), e o checkpoint parcial III-C1 (6 caráter/28 motivo e 0 unmatched); **não decodifica corpo binário QVD**;
- relê os **36 arquivos SIH/RD CSV** `BASE/CONVERTIDA/RD/RDPB*.csv`, exige `CAR_INT` numérico estrito de um ou dois caracteres após remover apenas espaços ASCII nas bordas, normaliza por `zfill(2)` para os valores admitidos, compara contra as 6 chaves normativas, comprova 36 competências e **566.672 registros/0 unmatched**, e apresenta contagem de códigos por ano e em bruto/normalizado;
- **não assume** que todos os 6 códigos precisem aparecer nos registros SIH/RD (a dimensão representa a referência oficial completa). Códigos fora do domínio, arquivos faltantes, chaves estruturalmente inválidas ou desvio de hash interrompem o preflight.

**Estado: `IV-CARATER_ATENDIMENTO=PREFLIGHT_SCRIPT_READY_NOT_RUN`.** O script foi revisado estaticamente, **não executado sobre os dados locais**, de modo que nenhuma contagem de frequência por código é declarada como observada nesta etapa.

### Comando Windows, na raiz do repositório

```powershell
git fetch origin
git switch feat/phase-4-dim-carater-atendimento
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar a branch" }

.\.venv\Scripts\python.exe .\tools\preflight_dim_carater_atendimento.py
if ($LASTEXITCODE -ne 0) { throw "Falha no preflight da DIM_CARATER_ATENDIMENTO" }
```

Caso todos os critérios sejam atendidos, esperar `REFERENCE_ROWS=6`, `REFERENCE_QVD_ROWS=6`, `RD_MONTHS=36`, `RD_ROWS=566672`, `RD_UNMATCHED=0`, `OUTPUT_FILES_WRITTEN=0`, `QVD_GENERATED=False` e **`VERDICT=PASS_CARATER_6_CODE_REFERENCE_AND_RD_PREFLIGHT_ONLY`**. A frequência exata dos códigos somente será conhecida quando o script rodar.

## Próxima hipótese técnica (não implementada)

**HIPÓTESE DE MODELAGEM:** `DIM_CARATER_ATENDIMENTO` com seis linhas, uma para cada código textual `01`–`06`, `%SK_CARATER_ATENDIMENTO=Hash128('CAR', COD_CARATER_ATENDIMENTO)`, descrição extraída de `REF_CARATER_ATENDIMENTO.qvd` e proveniência normativa. Depois do preflight PASS, definir nomes físicos, script QlikView 12 `TRANSFORMACAO/transf_dim_carater_atendimento.qvs`, qualidade de SK e `566672 RD/0 unmatched`, QVD/checkpoint parcial, reload e auditoria independente local.

**DECISÃO PENDENTE:** fechamento do contrato físico e da grafia de descrição com base na referência aprovada e nos dados físicos observados. Não editar Capítulos 1 e 2, mudar normalização previamente aprovada, construir fatos/Link Table/PAINEL ou emitir marcador global de transformação. `T29_HISTORICAL=NOT_APPROVED` permanece válido para leitos, sem relação com este preflight.

**Estado da `main`: 5/8 dimensões integradas.**

## Gate IV-CAR — preflight físico PASS (09/10/2026)

**FATO VERIFICADO — execução PowerShell do responsável** na branch `feat/phase-4-dim-carater-atendimento`, após `git fetch origin`, `git switch` e `git pull --ff-only`:

```text
MODE=IV_DIM_CARATER_READ_ONLY_PREFLIGHT
OUTPUT_FILES_WRITTEN=0
QVD_GENERATED=False
REFERENCE_ROWS=6
REFERENCE_DISTINCT_CODES=6
REFERENCE_CODES=01,02,03,04,05,06
REFERENCE_SHA256=3e40a9b2a4d0e1e65df8a9000f55af6fd24880468c12faaa24384f4722330ea8
REFERENCE_LABELS=EXACT_MATCH_TO_APPROVED_NORMATIVE_MATERIALIZER
REFERENCE_QVD_ROWS=6
REFERENCE_QVD_FIELDS=6
RD_QVD_ROWS=566672
CHECKPOINT_C1=PASS_PARTIAL_ZERO_UNMATCHED
RD_FILES=36
RD_MONTHS=36
RD_ROWS=566672
RD_RAW_DISTINCT=4
RD_NORMALIZED_DISTINCT=4
RD_RAW_VALUES=[('01', 80167), ('02', 470512), ('05', 1670), ('06', 14323)]
RD_NORMALIZED_COUNTS=[('01', 80167), ('02', 470512), ('05', 1670), ('06', 14323)]
RD_YEAR_COUNTS=[('2017', 187726), ('2018', 187293), ('2019', 191653)]
RD_UNMATCHED=0
SK_RULE_CANDIDATE=Hash128_CAR_AND_NORMALIZED_CODE
SOURCE_DOMAIN_POLICY=FULL_OFFICIAL_01_TO_06
VERDICT=PASS_CARATER_6_CODE_REFERENCE_AND_RD_PREFLIGHT_ONLY
```

Os 36 CSVs SIH/RD físicos têm `CAR_INT` **textual com exatamente dois dígitos nos valores observados**; não houve mudança pela normalização permitida. O conjunto observado foi somente `01`, `02`, `05`, `06`; **`03` e `04` têm zero registros no recorte e permanecem no domínio oficial da dimensão**. Os resultados somam 566.672 RD de 2017–2019 e 0 sem referência. O SHA do CSV oficial materializado bate com o manifesto C1. Os cabeçalhos QVD da extração e o checkpoint C1 foram inspecionados. Nenhum artefato foi criado ou alterado.

**Veredito:** `IV-CARATER_ATENDIMENTO=PREFLIGHT_PHYSICAL_PASS`, aprova implementação isolada QlikView 12 sobre a **referência normativa C1 completa**, sem derivar descrição do código RD. `SK=Hash128('CAR', codigo textual de dois dígitos)`, granularidade um código (seis registros), e cobertura RD completa são critérios já respaldados pelo projeto. A discrepância de maiúsculas/minúsculas das descrições 05/06 continua como ressalva textual: **conservar o texto literal de `CARATER_DESCRICAO` do QVD III-C1**, rastreado à Portaria SAS/MS 719/2007, sem reescrever o relatório acadêmico. Isso não implica validar editorialmente diferenças de caixa com a portaria.

**Próximo gate:** criar include QlikView **somente da DIM_CARATER_ATENDIMENTO** após a quinta dimensão, exigir seis SK/códigos únicos, descrições não vazias, 0 invalidos, 566672/0 RD unmatched (contagens por código `01=80167`, `02=470512`, `03=0`, `04=0`, `05=1670`, `06=14323`), persistir **apenas** `TRANSFORMACAO/QVD/DIM_CARATER_ATENDIMENTO.qvd` e checkpoint parcial. Depois executar Reload real no QlikView 12 e auditor Python read-only. Nenhum fato, Link Table, painel ou sucesso global até concluir Fase IV.


## Sexto checkpoint — implementação QlikView e auditor de QVD preparados (não executados)

**FATO VERIFICADO NO REPOSITÓRIO — código versionado:**

- `TRANSFORMACAO/transf_dim_carater_atendimento.qvs` é incluído por `TRANSFORMACAO/transf_main.qvs` **depois** de `transf_dim_diagnostico.qvs`, mantendo as cinco dimensões anteriores e exigindo valores do último gate Qlik de diagnóstico (`vP4DDimensionRows=14230`, `vP4DUniqueSK=14230`, `vP4DRDRows=566672`, `vP4DRDUnmatched=0`). **A inclusão ainda não foi executada localmente em Reload.**
- O include lê **somente** `EXTRACAO/QVD/REF_CARATER_ATENDIMENTO.qvd`, referindo os campos físicos `CAR_INT`, `CARATER_DESCRICAO`, `CARATER_FONTE_OFICIAL` comprovados na extração C1. Exige **6 linhas/6 códigos únicos**, contendo exatamente um dos códigos `01`–`06` de cada; verifica descrição e URL de fonte não vazias. Não reescreve a capitalização dos rótulos do QVD.
- `DIM_CARATER_ATENDIMENTO` **proposta** com **4 campos físicos**: `%SK_CARATER_ATENDIMENTO` = `Hash128('CAR', código normalizado)`, `COD_CARATER_ATENDIMENTO` (dois caracteres), `DESCRICAO_OFICIAL_CARATER_ATENDIMENTO` (do QVD, grafia literal C1), `CARATER_ATENDIMENTO_FONTE_OFICIAL`. O quarto é metadado de proveniência, sem modificar os três atributos acadêmicos aprovados. Os nomes são exclusivos e evitam associações não intencionais com outras dimensões.
- Cobertura `CAR_INT` em `EXTRACAO/QVD/SRC_SIH_RD.qvd` usa a **mesma expressão de normalização C1** (`Right('00' & KeepChar(Text(CAR_INT),'0123456789'),2)` com `Text()` para o resultado), mais validação de formato de chave. Exige `RD=566672`, **4 códigos efetivos**, `0 unmatched`, `0 inválidos` e distribuição conferida com os 36 CSVs físicos: `01=80167`, `02=470512`, `03=0`, `04=0`, `05=1670`, `06=14323`.
- Somente depois de todos os gates escreve `TRANSFORMACAO/QVD/DIM_CARATER_ATENDIMENTO.qvd` e `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_CARATER_ATENDIMENTO.csv`, este com `status=PASS_PARTIAL_DIM_CARATER_ATENDIMENTO_ONLY`. Sem alteração em `EXTRACAO`, nas outras dimensões, em fatos, Link Table, painel ou marcador global de sucesso.
- Auditor físico read-only `tools/audit_dim_carater_atendimento_qvd.py` criado: reexecuta o preflight (CSV + manifesto SHA, labels C1, 36 RD e cabeçalhos QVD anteriores), verifica **cabeçalho XML** do novo QVD (6 linhas e 4 campos na ordem esperada), checkpoint parcial, contagens e distribuição por código, SHA-256 do QVD/checkpoint e frescor. **Não decodifica registros binários**; dependerá do log real Qlik para avaliar os joins e as SK geradas.

**Gate de execução local — pendente:**

1. Estando na branch `feat/phase-4-dim-carater-atendimento`, `git pull --ff-only` e conferir que `TRANSFORMACAO/transf_dim_carater_atendimento.qvs` foi atualizado.
2. Abrir `TRANSFORMACAO/TRANSF.qvw` no **QlikView 12** e executar **Reload**. Exigir na mesma execução:
   ```text
   [TRANSFORMACAO][IV-CARATER] SOURCE Rows=6 Fields=4 Codes=6 Invalid=0
   [TRANSFORMACAO][IV-CARATER] COVER RD=566672 Distinct=4 UNMATCHED=0 Invalid=0
   [TRANSFORMACAO][IV-CARATER] COUNTS 01=80167 02=470512 03=0 04=0 05=1670 06=14323
   [TRANSFORMACAO][IV-CARATER] DIM_CARATER_ATENDIMENTO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN
   ```
   E confirmar `Execução concluída.` sem FAIL real ou erros no log, com timestamp compatível com QVD/checkpoint produzidos.
3. Só depois rodar `tools/audit_dim_carater_atendimento_qvd.py`, que deve retornar (se dados físicos baterem) `VERDICT=PASS_LOCAL_DIM_CARATER_QVD_HEADER_CHECKPOINT_RECONCILED`. **Esse PASS é esperado, NÃO observado ainda.**
4. Enviar **o log QlikView e a saída do auditor**, sem assumir aprovação da transformação a partir do preflight somente. Nenhum PR/merge sem esses gates.

**Estado:** `IV-CARATER_ATENDIMENTO=PHYSICAL_PREFLIGHT_PASS_QLIK_SCRIPT_AUDITOR_READY_NOT_RUN`, `MAIN_INTEGRATED_DIMENSIONS=5/8`, `T29_HISTORICAL=NOT_APPROVED`, `FACTS_AND_LINK_TABLE=NOT_STARTED`. As descrições 05/06 são preservadas literalmente conforme C1, e diferenças gráficas do documento acadêmico fechado continuam registradas.

## Sexto checkpoint — QVD e checkpoint físicos reconciliados (09/10/2026); log do reload pendente

**FATO VERIFICADO — saída PowerShell fornecida pelo responsável**, após fast-forward da branch `99f6751..c495b58` e execução local de `tools/audit_dim_carater_atendimento_qvd.py`:

- Preflight do auditor **reexecutou** verificações do manifesto/CSV normativos e dos 36 CSV SIH/RD: `REFERENCE_ROWS=6`, `REFERENCE_DISTINCT_CODES=6`, `REFERENCE_CODES=01,02,03,04,05,06`, SHA CSV `3e40a9b2a4d0e1e65df8a9000f55af6fd24880468c12faaa24384f4722330ea8`, `REFERENCE_LABELS=EXACT_MATCH_TO_APPROVED_NORMATIVE_MATERIALIZER`.
- QVD da extração `REF_CARATER_ATENDIMENTO.qvd`: **6 linhas e 6 campos** de cabeçalho; QVD `SRC_SIH_RD.qvd`: **566672 linhas**. `CHECKPOINT_C1=PASS_PARTIAL_ZERO_UNMATCHED`.
- Os 36 CSVs originais têm 566672 linhas, 4 códigos observados sem alteração de normalização e **0 sem correspondência**: `01=80167`, `02=470512`, `05=1670`, `06=14323`; `03=0`, `04=0`. Totais anuais: `2017=187726`, `2018=187293`, `2019=191653`.
- O arquivo **local** `TRANSFORMACAO/QVD/DIM_CARATER_ATENDIMENTO.qvd` agora existe com cabeçalho **6 linhas e 4 campos**, tamanho **3383 bytes**, SHA-256 **`b43851e7c57e33804ddde812ff47959510c07950a8db54d8aa9406dfa01861b4`**.
- O checkpoint local `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_CARATER_ATENDIMENTO.csv` existe com **535 bytes**, SHA-256 **`97fffb687609c6566fac39da97b4a9e059c32efae5ee7144f1ebc5cc5dba87a0`**. O auditor conferiu `PASS_PARTIAL_DIM_CARATER_ATENDIMENTO_ONLY`, 6 chaves substitutas únicas **declaradas pelo checkpoint Qlik**, 0 inválidos, RD 566672/0 unmatched, distribuição por código e `facts_and_link_table=NOT_STARTED`.
- `VERDICT=PASS_LOCAL_DIM_CARATER_QVD_HEADER_CHECKPOINT_RECONCILED` e `LIMIT=QVD_BINARY_BODY_NOT_INDEPENDENTLY_DECODED`. Esta auditoria usa SHA, cabeçalho QVD e **valores gravados pelo próprio Qlik no CSV**, mas **não** decodifica independentemente cada registro da dimensão ou comprova a conclusão do reload.
- **O log do reload QlikView 12 NÃO foi enviado nesta execução.** Portanto, os traces `SOURCE`, `COVER`, `COUNTS`, `STORE`, encerramento normal sem erros e horário contemporâneo dos dois arquivos **ainda exigem confirmação por log**.

**Estado atual:** `IV-CARATER_ATENDIMENTO=LOCAL_QVD_HEADER_CHECKPOINT_PASS_RELOAD_LOG_PENDING`. Há QVD/checkpoint locais inspecionados; **a sexta dimensão ainda NÃO está integrada à main**, que permanece em **5/8 dimensões**. `T29_HISTORICAL=NOT_APPROVED` e fatos/Link Table/PAINEL `NOT_STARTED` permanecem.

**Próximo gate:** localizar `TRANSFORMACAO/TRANSF.qvw*.log` mais recente, correlacionar seu horário com o QVD/checkpoint e comprovar **na mesma execução** `[IV-CARATER] SOURCE Rows=6 Fields=4 Codes=6 Invalid=0`, `COVER RD=566672 Distinct=4 UNMATCHED=0 Invalid=0`, `COUNTS 01=80167 02=470512 03=0 04=0 05=1670 06=14323`, `DIM_CARATER_ATENDIMENTO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN` e finalização normal. Guardas impressas `IF ScriptErrorCount > 0 THEN` **não** constituem erros de execução. Somente após essa evidência e revisão do diff encaminhar PR, sem executar merge automático.

## Gate QlikView 12 — reload local PASS confirmado (09/10/2026)

**FATO VERIFICADO — trechos do log real fornecidos pelo responsável em PowerShell:**

- Arquivo `TRANSFORMACAO/TRANSF.qvw.2026_10_09_10_50_54.log`, tamanho **87.265 bytes**, com `LastWriteTime=09/10/2026 10:51:08`; registros Qlik da mesma execução às **10:51:07–10:51:08**.
- Linhas 1079–1080: `[TRANSFORMACAO][IV-CARATER] START`.
- Linhas 1131–1132: **`SOURCE Rows=6 Fields=4 Codes=6 Invalid=0`**.
- Linhas 1226–1227: **`COVER RD=566672 Distinct=4 UNMATCHED=0 Invalid=0`**.
- Linhas 1229–1230: **`COUNTS 01=80167 02=470512 03=0 04=0 05=1670 06=14323`**.
- Linhas 1271–1272: **`DIM_CARATER_ATENDIMENTO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`**.
- Linhas 1274–1275: `PHASE_IV_PARTIAL_ONLY T29_HISTORICAL_NOT_APPROVED`; linha 1277: **`Execução concluída.`**
- O trecho `Get-Content -Tail 40` mostra `P4C_DIM_CHECKPOINT` com `status=PASS_PARTIAL_DIM_CARATER_ATENDIMENTO_ONLY`, 6 linhas/4 campos, 6 chaves substitutas únicas, 0 linhas inválidas, RD 566672/4 códigos, sem unmatched/invalid, distribuição 01–06 exata, `domain_policy=COMPLETE_01_TO_06`, `label_policy=EXACT_SOURCE_C1_LABELS`, `t29_historical=NOT_APPROVED`, `facts_and_link_table=NOT_STARTED`. Houve `STORE` do checkpoint, 24 campos de checkpoint e 1 linha, antes de `Execução concluída.`
- Metadados físicos informados: `TRANSFORMACAO/QVD/DIM_CARATER_ATENDIMENTO.qvd` **3383 bytes** e `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_CARATER_ATENDIMENTO.csv` **535 bytes**, ambos com `LastWriteTime=09/10/2026 10:51:08`, simultâneos à gravação e ao término do log.
- A busca `Select-String -SimpleMatch` apresentada não retornou `Error: Unknown statement` ou `Syntax Error`. Linhas impressas `IF ScriptErrorCount > 0 THEN` são **guardas de código**, não erros observados. O log fornecido contém **ocorrências filtradas e últimas 40 linhas**, não o arquivo de 87.265 bytes integral; nenhuma inspeção integral é reivindicada.

**Auditoria física read-only anteriormente aprovada:** `PASS_LOCAL_DIM_CARATER_QVD_HEADER_CHECKPOINT_RECONCILED`; SHA-256 QVD `b43851e7c57e33804ddde812ff47959510c07950a8db54d8aa9406dfa01861b4`, SHA-256 checkpoint `97fffb687609c6566fac39da97b4a9e059c32efae5ee7144f1ebc5cc5dba87a0`. O auditor validou hashes/cabeçalho/campos/contagens da linha de checkpoint, **não decodificou os registros binários QVD**; evidência de qualidade é a combinação dos controles físicos, CSV RD e execução QlikView real. Não tratar como CI automatizada.

**Resultado:** `IV-CARATER_ATENDIMENTO=LOCAL_QLIK_RELOAD_QVD_CHECKPOINT_PASS_REVIEW_PENDING`. A sexta dimensão tem **PASS local** de carga QlikView e auditoria QVD/checkpoint; está **apta a revisão/PR**, não integrada à `main` sem merge. `MAIN_INTEGRATED_DIMENSIONS=5/8`.

**Próximo gate:** revisar diff `main` vs branch `feat/phase-4-dim-carater-atendimento`, abrir PR de revisão **sem merge**, e obter autorização específica antes do squash. Não criar tabelas fato, Link Table ou painel nem revisar capítulos acadêmicos fechados. `T29_HISTORICAL=NOT_APPROVED` permanece.

## Revisão de integração — PR #79 aberto em Draft (09/10/2026)

**FATO VERIFICADO NO GITHUB:** [PR #79](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/79), `feat/phase-4-dim-carater-atendimento` → `main`, **`state=open`, `draft=true`, `merged=false`**, `mergeable=true` na consulta posterior à criação (na resposta inicial de criação o valor transitório era `false`). Branch `behind_by=0`; diff limitado a **7 arquivos**: `AGENTS.md`, `TRANSFORMACAO/transf_dim_carater_atendimento.qvs`, `TRANSFORMACAO/transf_main.qvs`, esta documentação, `docs/project/current-state.md`, `tools/audit_dim_carater_atendimento_qvd.py` e `tools/preflight_dim_carater_atendimento.py`. `fetch_pr_patch` confirmou os mesmos 7 arquivos.

**Revisão estática de escopo:** PASS — nenhuma alteração em extração, QVDs versionados, modelo acadêmico encerrado, fatos, Link Table ou painel. Checkpoints locais QlikView 12 e auditor físico QVD/CSV foram recebidos e documentados; o log foi fornecido em trechos e a auditoria independente **não decodifica o corpo binário do QVD**. Não há justificativa para afirmar CI automatizado PASS.

**DECISÃO PENDENTE:** promover o PR #79 a `Ready for review` após revisão final e, em decisão **separada**, autorizar eventual squash merge; **nenhum merge automático**. A `main` ainda possui **5/8 dimensões integradas**. `T29_HISTORICAL=NOT_APPROVED` e `FACTS_AND_LINK_TABLE=NOT_STARTED` permanecem.

## PR #79 — Ready for review (09/10/2026)

**FATO VERIFICADO NO GITHUB:** após solicitação de prosseguimento do responsável, PR [#79](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/79) foi **promovido de Draft para Ready for review**. O GitHub retornou `state=open`, `draft=false`, `merged=false`, `mergeable=true`. Head antes da atualização documental: `95a112f477cfdd76f004e5321b17d03c1f9f80af`.

**Revisão de escopo:** comparação `feat/phase-4-dim-carater-atendimento` versus `main` com `behind_by=0` e exatamente **7 arquivos** (QlikView include e entrypoint, preflight Python, auditor Python e três documentos); `fetch_pr_patch` conferiu o mesmo conjunto. Revisão estática de invariantes da sexta dimensão: domínio completo 01–06, SK `Hash128('CAR', codigo)`, seis códigos e seis SK únicas, normalização C1, RD 566672/0 unmatched, distribuição real 01=80167, 02=470512, 03=0, 04=0, 05=1670, 06=14323, QVD/checkpoint exclusivos e parciais; as cinco dimensões anteriores permanecem intactas.

**Limites:** checks de status e workflows GitHub consultados para o head da promoção retornaram **listas vazias** — **não há CI PASS comprovado**. A auditoria QVD/Python e o reload QlikView passaram **localmente**, com log fornecido em excertos; auditor externo não decodifica corpo binário do QVD. Consultas ao PR não mostraram revisões formais de terceiros nem threads.

**DECISÃO PENDENTE:** autorização **específica** para executar o **squash merge do PR #79**. Não integrar automaticamente. Até merge confirmado, `main` segue **5/8 dimensões integradas**. Próximo checkpoint após integração é `DIM_MOTIVO_SAIDA_PERMANENCIA`, sujeito a Discovery/preflight próprio. `T29_HISTORICAL=NOT_APPROVED`, fatos/Link Table/PAINEL `NOT_STARTED`.
