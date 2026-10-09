# Fase IV — DIM_DIAGNOSTICO — preflight CID-10 (09/10/2026)

## Escopo e fonte de verdade

**FATO VERIFICADO NO REPOSITÓRIO:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/discovery/phase-3-cid10-reference-implementation-2026-10-07.md`, `docs/discovery/boundary-7-implementation-plan.md`, `docs/academic/chapter-1-2-modeling.md` e o Qlik `EXTRACAO/ext_main.qvs` foram consultados.

- **Estado:** Fase IV `IN_PROGRESS`; 4/8 dimensões integradas à `main`, incluindo `DIM_PROCEDIMENTO` (PR #77, squash `4ecd27fc3cfa96ffd8c784128650323b197d5892`). Capítulos 1 e 2 acadêmicos fechados.
- **DIM_DIAGNOSTICO acadêmica:** SK, código CID-10, descrição oficial do diagnóstico; a primeira versão considera **somente `DIAG_PRINC`** e não diagnósticos secundários (capítulo 2).
- **Grão proposto para validação:** 1 linha por **código CID-10 normalizado**; **sem competência na SK**, porque a Fase III aprovou referência **descritiva estática/superset** da competência `201912`. Boundary 7 define `%SK_DIAGNOSTICO=Hash128('CID10', DIAG_PRINC_NORMALIZADO)`. Não inferir vigência mensal da CID pelo superset.
- **Fase III-C2 / T28:** CID-10 `201912`, `tb_cid.txt` e layout físico inspecionados; campos `CO_CID` de largura 4 e `NO_CID` largura 100. `BASE/REFERENCIAS/cid10_referencia.csv` com **14.230 códigos** únicos (2.042 de 3 caracteres, 12.188 de 4), SHA-256 `da541adc1efbdb4ac04c555cf1e008967fd053fb6368ff443fb10a476757025f`. `EXTRACAO/QVD/REF_CID10.qvd` e `_CHECKPOINT_EXTRACAO_CID10.csv` foram carregados no QlikView 12 (III-C2.8d PASS), 566.672 RD e zero unmatched.
- **Normalização confirmada:** 60.423 registros RD têm **somente um espaço ASCII U+0020 no final** de `DIAG_PRINC` físico de 4 caracteres; demais 506.249 registros têm quatro caracteres alfanuméricos. 5.480 códigos brutos distintos e 5.480 normalizados distintos, sem colisões. **Remover apenas espaços ASCII à direita**, sem `Upper()`, exclusão de pontos ou outras transformações. No QlikView, T28 identificou risco de dual value: `Text(RTrim(Text(DIAG_PRINC)))` preserva código textual (ex.: `R042`), enquanto `RTrim(Text(DIAG_PRINC))` pode alterar a interpretação textual (ex.: `R42`). Esta decisão **não pode ser regredida**.

## Contrato do gate físico read-only

Script versionado: **`tools/preflight_dim_diagnostico_cid10.py`**, na branch `feat/phase-4-dim-diagnostico`.

- Confere hash do CSV e SHA do `tb_cid.txt` e layout contra o manifesto C2.7 e amostra C2.4; confronta **linha a linha** texto `cp1252` original com CSV UTF-8 de quatro campos, código original normalizado só com `rstrip(' ')`, competência `201912` e `NO_CID` efetivo; exige 14.230 pares únicos e distribuição 2.042/12.188.
- Confere os **cabeçalhos XML**, sem descompactar corpos binários, de `REF_CID10.qvd` (14.230 linhas, sete campos Qlik de staging) e `SRC_SIH_RD.qvd` (566.672, `DIAG_PRINC` presente), mais valores do checkpoint C2.8d `PASS_PARTIAL` / T28 0 unmatched.
- Lê **36 CSVs RD já convertidos** (`BASE/CONVERTIDA/RD/RDPB*.csv`) somente leitura. Exige 566.672 registros e 36 competências, `DIAG_PRINC` físico de quatro caracteres, 60.423 com espaço ASCII no fim, 5.480 códigos distintos (sem colisões) e **cobertura 566.672/566.672 contra o mesmo dicionário 201912**, sem confundir validação estática com vigência histórica.
- **Nenhum download ou escrita**. Não altera QVDs, ETL, Capítulos 1–2, fatos ou Link Table, nem executa o Qlik. Resultados reais só serão registrados após execução local.

### Comando de execução inicial — Windows, raiz do repositório

```powershell
git fetch origin
git switch feat/phase-4-dim-diagnostico
git pull --ff-only
.\.venv\Scripts\python.exe .\tools\preflight_dim_diagnostico_cid10.py
if ($LASTEXITCODE -ne 0) { throw "Preflight DIM_DIAGNOSTICO CID10 falhou" }
```

Esperado **SE** os dados permanecerem idênticos: `CID_REFERENCE_ROWS=14230`, `CID_DISTINCT_CODES=14230`, `REF_CID10_QVD_ROWS=14230`, `RD_FILES=36`, `RD_ROWS=566672`, `RD_UNMATCHED=0`, `PERSISTENT_OUTPUTS=NONE`, `VERDICT=PASS_CID10_DIM_DIAGNOSTICO_PHYSICAL_PREFLIGHT_ONLY`.

## Hipóteses de modelagem e decisões pendentes

- **HIPÓTESE DE IMPLEMENTAÇÃO:** gerar `DIM_DIAGNOSTICO` com 14.230 linhas de lookup descritivo, código normalizado, descrição `NO_CID`, SK `Hash128('CID10', código)` e rastreabilidade da referência 201912. Revisar os nomes físicos e testes em preflight antes de criar include QlikView; não introduzir historização não comprovada.
- **DECISÃO PENDENTE:** validar em QlikView os tipos, campos de saída, cardinalidade e os 566.672 joins sem regressão da regra `Text(RTrim(Text(DIAG_PRINC)))`; executar reload real e auditoria SHA QVD/checkpoint. Não declarar `DIM_DIAGNOSTICO.qvd` criado nem alterar integração da `main` antes desse gate e PR.
- A interpretação `201912` é **superset descritivo**, não evidência de vigência normativa individual em cada mês. `T29_HISTORICAL=NOT_APPROVED` diz respeito à referência histórica de leitos e permanece inalterado.
- Não iniciar fatos, Link Table, painel nem marcador global de sucesso da transformação enquanto a Fase IV não estiver concluída.

**Estado deste documento:** `IV-DIAGNOSTICO=PREFLIGHT_CODE_READY_NOT_RUN`, `MAIN_INTEGRATED_DIMENSIONS=4/8`, `PHASE_IV=IN_PROGRESS`.

## Gate IV-DIAGNOSTICO — preflight físico read-only PASS local (09/10/2026)

**FATO VERIFICADO — PowerShell do responsável**, após `git fetch origin`, `git switch feat/phase-4-dim-diagnostico`, `git pull --ff-only` e execução do script da branch:

```text
MODE=IV_DIM_DIAGNOSTICO_CID10_READ_ONLY_PREFLIGHT
PERSISTENT_OUTPUTS=NONE
QVD_CREATED=False
CID_REFERENCE_ROWS=14230
CID_DISTINCT_CODES=14230
CID_CODE_LENGTH_3=2042
CID_CODE_LENGTH_4=12188
CID_SOURCE_CSV_SHA256=da541adc1efbdb4ac04c555cf1e008967fd053fb6368ff443fb10a476757025f
REF_CID10_QVD_ROWS=14230
REF_CID10_QVD_FIELDS=7
SRC_SIH_RD_QVD_ROWS=566672
CHECKPOINT_C2_8D=PASS_PARTIAL_0_UNMATCHED
RD_FILES=36
RD_ROWS=566672
RD_RAW_DISTINCT=5480
RD_NORM_DISTINCT=5480
TRAILING_SPACE_ROWS=60423
RD_MATCHED=566672
RD_UNMATCHED=0
REFERENCE_POLICY=STATIC_DESCRIPTIVE_SUPERSET_201912_NO_MONTHLY_VALIDITY
NORMALIZATION=ASCII_TRAILING_SPACE_REMOVAL_ONLY
SK_RULE_CANDIDATE=Hash128_CID10_NORMALIZED_CODE
VERDICT=PASS_CID10_DIM_DIAGNOSTICO_PHYSICAL_PREFLIGHT_ONLY
```

O script comparou SHA de `tb_cid.txt` e layout com manifestos C2.4/C2.7, **14.230 linhas do CSV físico com as respectivas linhas do arquivo CID original**, esquema e contagens de cabeçalhos QVD de origem e checkpoint C2.8d, e **36 arquivos RD locais, 566.672 linhas**, aplicando apenas `rstrip(' ')`. Constatou zero CID sem match no dicionário estático 201912, preservando os **60.423** valores com padding. Nenhum arquivo foi modificado e não houve criação de QVD.

**VEREDITO:** `IV-DIAGNOSTICO=CID10_PHYSICAL_PREFLIGHT_PASS`; a aquisição/normalização de código e a viabilidade de enriquecimento descritivo da DIM_DIAGNOSTICO estão aprovadas para **implementação QlikView isolada**. Isso **não** valida ainda a QVD dimensional; T28 tem PASS anterior da EXTRAÇÃO, enquanto novos checks da Fase IV precisam de reload real.

**Próximo gate:** preparar `TRANSFORMACAO/transf_dim_diagnostico.qvs` após os quatro includes dimensionais, com `%SK_DIAGNOSTICO=Hash128('CID10', codigo normalizado)` e **uma linha por código CID-10 estático** (14230). Exigir 14230 SK únicas, 2042 categorias de três caracteres + 12188 subcategorias de quatro, origem 201912, descrição presente, RD 566672/0 unmatched aplicando **`Text(RTrim(Text(DIAG_PRINC)))`** conforme a correção comprovada do T28. Validar depois QVD físico/checkpoint de etapa parcial; não afirmar vigência histórica mensal e não criar fatos/Link Table/painel.


## IV-DIAGNOSTICO — transformação e auditor de QVD preparados (CODE READY, NÃO EXECUTADO)

**Implementação candidata versionável:**

- `TRANSFORMACAO/transf_dim_diagnostico.qvs` foi acrescentado e incluído em `TRANSFORMACAO/transf_main.qvs` **após** a quarta dimensão `DIM_PROCEDIMENTO`. O include exige que os valores do checkpoint anterior mantenham 165203 versões SIGTAP/165203 SK, 566672 RD e 0 unmatched antes de prosseguir.
- O script lê `EXTRACAO/QVD/REF_CID10.qvd` com os 4 campos físicos já comprovados no estágio C2.8d: `CID10_CODIGO`, `CID10_DESCRICAO`, `CID10_COMPETENCIA_REFERENCIA`, `CID10_FONTE_ARQUIVO`. A carga restringe o dicionário a **14230 códigos únicos**, distribuição 2042 de 3 caracteres e 12188 de 4, descrição não vazia, competência descritiva fixa `201912`, origem `tb_cid.txt`. Sem QVD novo de extração e sem regravar a referência.
- **Modelo dimensional proposto de 5 campos físicos:** `%SK_DIAGNOSTICO=Hash128('CID10', COD_DIAGNOSTICO)`, `COD_DIAGNOSTICO`, `DESCRICAO_OFICIAL_DIAGNOSTICO` (conteúdo `NO_CID`/CID10_DESCRICAO oficial), `CID10_REFERENCIA_COMPETENCIA` (`201912`, só proveniência), `CID10_FONTE_ARQUIVO` (`tb_cid.txt`, só proveniência). Os nomes de descrição e competência são **específicos** para impedir associações artificiais com `DIM_PROCEDIMENTO`; os três primeiros são os atributos acadêmicos SK/CID/descrição, complementados por dois metadados de origem.
- **Grão** 1 linha por código CID-10 normalizado, **sem competência mensal na SK**, conforme Boundary 7 e escolha da fonte estática descritiva (não usar `201912` como validade histórica). Exigir 14230 linhas, 5 campos, 14230 SK distintas, 14230 códigos distintos, 0 inválidos.
- **T28:** testa as 566672 linhas em `EXTRACAO/QVD/SRC_SIH_RD.qvd`, com `DIAG_PRINC` e expressão **literal `Text(RTrim(Text(DIAG_PRINC)))`** para lookup, preservando os zeros internos/valor textual comprovados na correção III-C2.8d. Exigir 5480 códigos RD distintos, 0 sem correspondência, 0 inválidos. A verificação em Python do CSV convertido de 60423 valores com ASCII U+0020 trailing já passou; não assumir esse número no QVD, em que o Qlik pode representar o valor fisicamente de modo diverso.
- Persistir **somente depois dos checks**: `TRANSFORMACAO/QVD/DIM_DIAGNOSTICO.qvd` e `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_DIAGNOSTICO.csv` com `PASS_PARTIAL_DIM_DIAGNOSTICO_ONLY`. **Nenhum** sucesso global de transformação, fato, Link Table ou PAINEL.

**Auditor físico versionado**: `tools/audit_dim_diagnostico_qvd.py` (**ainda não executado**), read-only. Ele exige integridade original C2.4/C2.7/T28 novamente (14.230 códigos, 36 RD/566672, 0 unmatched), confirma cabeçalho XML QVD **14230 linhas e 5 campos em ordem**, compara os contadores/políticas do CSV checkpoint parcial, SHA-256 e frescor relativo. **Limitação declarada:** não decodifica independentemente os registros binários do QVD. A prova de conteúdo da dimensão vem da transformação e do log real QlikView combinado com os arquivos CID originais auditados.

### Gate de execução local QlikView 12 — pendente

1. Atualizar a branch:
   ```powershell
   git pull --ff-only
   if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar o repositorio" }
   ```
2. No QlikView 12 abrir `TRANSFORMACAO/TRANSF.qvw` e executar **Reload**. Exigir log fresco com:
   ```text
   [TRANSFORMACAO][IV-DIAGNOSTICO] SOURCE Rows=14230 Fields=4 Keys=14230 Len3=2042 Len4=12188 Invalid=0
   [TRANSFORMACAO][IV-DIAGNOSTICO] COVER RD=566672 Distinct=5480 UNMATCHED=0 Invalid=0
   [TRANSFORMACAO][IV-DIAGNOSTICO] DIM_DIAGNOSTICO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN
   ```
   Também exigir encerramento normal do reload sem FAIL real. O reload executará os quatro includes anteriores, mas não mudará suas regras de negócio.
3. Somente com o reload bem-sucedido, executar:
   ```powershell
   .\.venv\Scripts\python.exe .\tools\audit_dim_diagnostico_qvd.py
   if ($LASTEXITCODE -ne 0) { throw "Auditoria fisica da DIM_DIAGNOSTICO falhou" }
   ```
4. Enviar **log do QlikView e saída do auditor**. O veredito `PASS_LOCAL_DIM_DIAGNOSTICO_QVD_HEADER_CHECKPOINT_RECONCILED` é **esperado, não observado**; sem ele, não criar PR de integração, não atualizar `main` e não avançar fatos/Link Table.

**Estado:** `IV-DIAGNOSTICO=CID10_PREFLIGHT_PASS_QV_CODE_READY_NOT_RUN`; **4/8 dimensões integradas na `main`**, `T29_HISTORICAL=NOT_APPROVED`; fatos, Link Table e PAINEL `NOT_STARTED`. Preservar a referência CID `201912` **como superset descritivo**, sem inferir sua validade normativa histórica mensal.

## IV-DIAGNOSTICO — auditoria física de QVD/checkpoint PASS local, reload log pendente (09/10/2026)

**FATO VERIFICADO — duas execuções locais PowerShell fornecidas pelo responsável:**

1. Após `git pull --ff-only` até `777d352`, a **primeira execução** de `tools/audit_dim_diagnostico_qvd.py` falhou com `RuntimeError: Dimensao/checkpoint ainda nao existe: TRANSFORMACAO\QVD\DIM_DIAGNOSTICO.qvd`. Isso demonstra apenas que o arquivo físico não existia naquele momento; **não** indica falha da fonte CID-10 nem da qualidade de dados.
2. Na execução **posterior**, `Test-Path .\TRANSFORMACAO\QVD\DIM_DIAGNOSTICO.qvd` e `Test-Path .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_DIAGNOSTICO.csv` retornaram `True`. A nova auditoria concluiu com:
   - `CID_REFERENCE_ROWS=14230`; `CID_DISTINCT_CODES=14230`; distribuição `CID_CODE_LENGTH_3=2042` e `CID_CODE_LENGTH_4=12188`; SHA fonte `da541adc1efbdb4ac04c555cf1e008967fd053fb6368ff443fb10a476757025f`;
   - `REF_CID10_QVD_ROWS=14230`, `REF_CID10_QVD_FIELDS=7`, `SRC_SIH_RD_QVD_ROWS=566672`, `CHECKPOINT_C2_8D=PASS_PARTIAL_0_UNMATCHED`;
   - `RD_FILES=36`, `RD_ROWS=566672`, `RD_RAW_DISTINCT=5480`, `RD_NORM_DISTINCT=5480`, `TRAILING_SPACE_ROWS=60423`, `RD_MATCHED=566672`, `RD_UNMATCHED=0`;
   - `DIM_DIAGNOSTICO_QVD_SHA256=5d5912c12023c33ad85f93070e7d1ccf55e0d333686d8625c9804a76c06ef1d8`, `DIM_DIAGNOSTICO_QVD_BYTES=1314463`;
   - `DIM_DIAGNOSTICO_CHECKPOINT_SHA256=e608153559e07282ceb2dc914f636c06c565f8d3d7df8fe2472e5f1340485a94`;
   - `DIM_ROWS=14230`, `DIM_FIELDS=5`, `DIM_UNIQUE_SK_CHECKPOINT=14230`, `RD_DISTINCT_NORMALIZED=5480`, `RD_UNMATCHED=0`;
   - `CID_REFERENCE_COMPETENCE=201912`, `CID_POLICY=STATIC_DESCRIPTIVE_SUPERSET_NOT_MONTHLY_VALIDITY`, `T29_HISTORICAL=NOT_APPROVED`, `FACTS_AND_LINK_TABLE=NOT_STARTED`;
   - **`VERDICT=PASS_LOCAL_DIM_DIAGNOSTICO_QVD_HEADER_CHECKPOINT_RECONCILED`**, com limite `LIMIT=QVD_BINARY_BODY_NOT_INDEPENDENTLY_DECODED`.
3. O auditor reexecuta os controles de arquivos originais e os 36 RD locais, confronta os hashes e metadados físicos do QVD e os contadores apresentados no checkpoint. **O QVD existe localmente e teve cabeçalho/checkpoint reconciliados.** A auditoria não decodifica cada registro do corpo binário e os números de SK únicas são valores do checkpoint produzidos pelo QlikView.
4. **Ainda não foi fornecido o log real do novo reload do `TRANSFORMACAO/TRANSF.qvw`**, com traces IV-DIAGNOSTICO de fonte, T28 e STORE, nem comprovado seu encerramento normal. A existência do QVD e o PASS do auditor não substituem essa evidência. Não promover PR ou declarar a quinta dimensão integrada antes do log.

**Estado atual:** `IV-DIAGNOSTICO=LOCAL_QVD_HEADER_CHECKPOINT_PASS_RELOAD_LOG_PENDING`; `DIM_DIAGNOSTICO.qvd=LOCAL_MATERIALIZED_AUDITED_HEADER`; **`MAIN_INTEGRATED_DIMENSIONS=4/8`**; `PHASE_IV=IN_PROGRESS`, `T29_HISTORICAL=NOT_APPROVED`.

### Gate final de validação QlikView 12

Localizar o log mais recente `TRANSF.qvw*.log` com execução correspondente à materialização acima e exigir, na **mesma execução**:

- `[TRANSFORMACAO][IV-DIAGNOSTICO] SOURCE Rows=14230 Fields=4 Keys=14230 Len3=2042 Len4=12188 Invalid=0`;
- `[TRANSFORMACAO][IV-DIAGNOSTICO] COVER RD=566672 Distinct=5480 UNMATCHED=0 Invalid=0`;
- `[TRANSFORMACAO][IV-DIAGNOSTICO] DIM_DIAGNOSTICO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`;
- encerramento normal da execução, sem `FAIL` efetivamente emitido ou erro de script; distinguir guardas `ScriptErrorCount` impressas no script do erro ocorrido;
- tempos do log compatíveis com QVD/checkpoint físicos; nenhuma implementação de fatos, Link Table ou marcador global.

Somente após analisar as linhas reais de log: revisar diff do PR, abrir PR de integração sem merge automático, e preservar a `main` em 4/8 dimensões até merge autorizado. O rótulo CID da competência 201912 permanece **superset descritivo**, não atestado de vigência histórica mensal.

## IV-DIAGNOSTICO — execução QlikView 12 concluída, evidência de log confirmada (09/10/2026)

**FATO VERIFICADO — PowerShell fornecido pelo responsável após `git pull --ff-only` para `afa6486`:**

- Último log encontrado: `TRANSFORMACAO/TRANSF.qvw.2026_10_09_10_04_43.log`; a execução registrou o quinto checkpoint e **`Execução concluída.` às 10:04:55** de 09/10/2026.
- No mesmo log, linhas 908–909, `[TRANSFORMACAO][IV-DIAGNOSTICO] START`; linhas 951–952: **`SOURCE Rows=14230 Fields=4 Keys=14230 Len3=2042 Len4=12188 Invalid=0`**.
- Linhas 1033–1034: **`COVER RD=566672 Distinct=5480 UNMATCHED=0 Invalid=0`**.
- Linhas 1072–1073: **`DIM_DIAGNOSTICO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`** e linhas 1075–1076 preservam `PHASE_IV_PARTIAL_ONLY T29_HISTORICAL_NOT_APPROVED`.
- O trecho final contém `P4D_DIM_CHECKPOINT` com valores expandidos: 14230 referência/dimensão/códigos/SK únicas, 4 campos de referência, 5 campos dimensionais, 0 inválidos, códigos de comprimento 3/4: 2042/12188, 566672 RD, 5480 códigos distintos normalizados, 0 unmatched, origem `201912` e política `STATIC_DESCRIPTIVE_SUPERSET_NO_MONTHLY_VALIDITY`, `T29=NOT_APPROVED`, `facts_and_link_table=NOT_STARTED`. Mostra `STORE P4D_DIM_CHECKPOINT` e `1 registros lidos`.
- O QVD `TRANSFORMACAO/QVD/DIM_DIAGNOSTICO.qvd` e o checkpoint `_CHECKPOINT_DIM_DIAGNOSTICO.csv` possuem `LastWriteTime=09/10/2026 10:04:55`, mesmo instante dos traces de STORE; tamanhos **1.314.463** e **594** bytes.
- Busca de `Script Error` e `Unknown statement` na amostra de `Select-String` fornecida não retornou falha. Linhas `IF ScriptErrorCount > 0 THEN` do trecho final são guardas impressas no log e **não** uma mensagem de erro executado.
- Evidência prévia **física e independente de cabeçalho/checkpoint** já apresentada: `VERDICT=PASS_LOCAL_DIM_DIAGNOSTICO_QVD_HEADER_CHECKPOINT_RECONCILED`, QVD SHA-256 **`5d5912c12023c33ad85f93070e7d1ccf55e0d333686d8625c9804a76c06ef1d8`**, checkpoint SHA-256 **`e608153559e07282ceb2dc914f636c06c565f8d3d7df8fe2472e5f1340485a94`**. O conteúdo binário de cada linha de QVD **não** foi decodificado por auditor externo; log do Qlik e auditoria física do CID-10/CSV sustentam o controle de conteúdo.
- **Limite do material disponível:** usuário compartilhou **trechos selecionados e últimas 40 linhas** do log, não a cópia integral. Os trechos observados suportam SOURCE, COVER, STORE, checkpoint e término normal da mesma execução; não se deve afirmar inspeção do arquivo integral nem execução automatizada de testes GitHub/CI.

**Veredito do checkpoint local:** `IV-DIAGNOSTICO=PASS_LOCAL_QLIK_RELOAD_AND_QVD_CHECKPOINT_RECONCILED`. A quinta dimensão tem implementação QlikView e QVD local **aprovados para revisão de integração**, porém **a `main` ainda mantém 4/8 dimensões integradas**; não alterar contagem até o PR merged.

**Próximo gate:** revisão de diff contra `main`, abrir PR de revisão **sem auto-merge** e obter aprovação específica antes de integração. Preservar `Text(RTrim(Text(DIAG_PRINC)))` e referência CID 201912 somente como superset descritivo, sem alegação de vigência normativa mensal. `T29_HISTORICAL=NOT_APPROVED`; fatos, Link Table, PAINEL e marcador global permanecem não iniciados.


## Revisão de integração — PR #78 criado em Draft (09/10/2026)

**FATO VERIFICADO NO GITHUB:** PR **[#78](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/78)**, `feat/phase-4-dim-diagnostico` → `main`, estado `open`, **`draft=true`**, **`merged=false`**, `mergeable=true` após atualização de metadados; `behind_by=0`. São **sete arquivos** no diff: `AGENTS.md`, `TRANSFORMACAO/transf_dim_diagnostico.qvs`, `TRANSFORMACAO/transf_main.qvs`, este relatório, `docs/project/current-state.md`, `tools/preflight_dim_diagnostico_cid10.py` e `tools/audit_dim_diagnostico_qvd.py`. Não houve alteração em fatos, Link Table, painel, extração, arquivos de dados, Capítulos 1–2 ou QVDs versionados.

**Resultado da revisão de escopo:** PASS estático; mudanças restritas à quinta dimensão, seus testes físicos e documentação. A execução QlikView 12 e a auditoria física do QVD/checkpoint passaram **localmente** conforme seções anteriores. **Não atribuir aprovação de CI**, não alegar que o corpo binário do QVD foi reprocessado independentemente, nem afirmar log integral examinado.

**DECISÃO PENDENTE:** promover o PR #78 de Draft para `Ready for review` após revisão final e **obter autorização explícita separada** para qualquer squash merge. A `main` continua **4/8 dimensões integradas** até o merge efetivo. Sem fatos, Link Table ou painel.

## PR #78 — promovido para Ready for review (09/10/2026)

**FATO VERIFICADO NO GITHUB:** o responsável solicitou prosseguimento após a criação do PR em Draft. Foi executada a promoção do [PR #78](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/78) de `Draft` para **`Ready for review`**; a resposta do GitHub confirmou `state=open`, `draft=false`, `merged=false`, `mergeable=true`. Referência do `head` no instante da promoção: `6af1b9134b31a671e71494c619020af09b047722`. Nenhum merge foi solicitado ou executado.

**Revisão estática e escopo:**

- Comparação com `main`: `behind_by=0`, **sete arquivos** estritamente relacionados ao include QlikView `DIM_DIAGNOSTICO`, sua chamada em `transf_main.qvs`, scripts Python de preflight/auditoria e documentação; nenhum fato, Link Table, painel, nova extração ou mudança nos capítulos acadêmicos.
- O include contém `Hash128('CID10', _P4D_CODE)`, valida 14.230 linhas/códigos/SK únicas e 2.042/12.188 comprimentos, preserva `Text(RTrim(Text(DIAG_PRINC)))` do T28 e exige `566672 RD / 0 unmatched`. `REF_CID10.qvd` permanece origem de consulta, sem `STORE` que o substitua.
- Relatório de log QlikView **local** de 09/10/2026 às 10:04:55 e auditoria física read-only já documentados como PASS; nenhuma decodificação independente do corpo binário do QVD. A busca no GitHub por **status checks e workflow runs do commit `6af1b913...` retornou listas vazias**; isso **não** constitui CI PASS. Consulta anterior não mostrou revisões nem threads registradas no PR.
- Limitações de fonte e modelagem intactas: `201912` é **superset descritivo sem validade mensal dos CID**, `T29_HISTORICAL=NOT_APPROVED`, somente diagnóstico principal; sem fatos, Link Table ou painel.

**DECISÃO PENDENTE:** obter autorização específica do responsável **antes do squash merge** do PR #78. Até a confirmação de merge, a `main` mantém **4/8 dimensões integradas**; a quinta está validada **localmente** e submetida a revisão, não integrada. Não antecipar desenvolvimento de fatos ou alterar a primeira entrega acadêmica.

## Integração concluída — PR #78 (09/10/2026)

**FATO VERIFICADO no GitHub após autorização explícita do responsável:**

- [PR #78](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/78), `feat/phase-4-dim-diagnostico` → `main`: **MERGED via squash**, commit **`6f565e8832521935f0ffb0c752c9c3cb5d2f72db`**. O merge foi feito com proteção `expected_head_sha=c03ad3cd9f8a26f4c715bb30e9b786afa7483134` e o GitHub retornou `merged=true`. Revisão anterior: `draft=false`, `mergeable=true`, `behind_by=0` e 7 arquivos estritamente em QlikView/Python/docs.
- Conteúdo QlikView e ferramentas foram integrados à `main`, mas os QVDs físicos de dados permanecem no ambiente local, não versionados no Git.
- Evidência local do quinto checkpoint: SOURCE 14230 chaves CID201912, DIM_DIAGNOSTICO com 14230 linhas/5 campos, 14230 SK distintas, RD 566672/5480 distintos/0 unmatched; log parcial de 09/10/2026 10:04:55 indica `Execução concluída.`. Auditor read-only local `PASS_LOCAL_DIM_DIAGNOSTICO_QVD_HEADER_CHECKPOINT_RECONCILED`, QVD SHA `5d5912c12023c33ad85f93070e7d1ccf55e0d333686d8625c9804a76c06ef1d8`, checkpoint SHA `e608153559e07282ceb2dc914f636c06c565f8d3d7df8fe2472e5f1340485a94`. Não há inspeção independente de corpo binário QVD nem CI automatizado comprovado.
- **Estado após integração: Fase IV `IN_PROGRESS`, 5/8 dimensões integradas**: TEMPO, MUNICIPIO, ESTABELECIMENTO, PROCEDIMENTO, DIAGNOSTICO. A próxima dimensão é `DIM_CARATER_ATENDIMENTO`, iniciando por Discovery READ-ONLY de campo SIH/RD, códigos, domínio e fonte oficial para descrições.
- **Restrições persistentes**: CID201912 é referência de consulta **descritiva estática** (sem vigência normativa mensal comprovada), `Text(RTrim(Text(DIAG_PRINC)))` é regra preservada, `T29_HISTORICAL=NOT_APPROVED`, nenhuma tabela fato/Link Table/painel foi implementada, e os Capítulos 1–2 acadêmicos continuam fechados.

Seções anteriores deste documento refletem estados cronológicos anteriores do PR (Draft/Ready for review) e não seu estado atual, que é MERGED.
