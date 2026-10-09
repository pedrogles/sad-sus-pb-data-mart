# Fase IV — DIM_MOTIVO_SAIDA_PERMANENCIA — Discovery / preflight (09/10/2026)

## Objetivo e escopo

**Estado canônico:** Fase III extração/staging PASS FINAL. Fase IV **6/8 dimensões integradas à `main`** após squash merge autorizado do PR [#79](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/79) (`70fa608eb2a6e49c1450268e6706ceaa99177da1`). Próxima dimensão: `DIM_MOTIVO_SAIDA_PERMANENCIA`. Capítulos 1 e 2 acadêmicos fechados, sem modificação. Sem fatos, Link Table ou painel. `T29_HISTORICAL=NOT_APPROVED` para classificação histórica de leitos.

**Fontes canônicas lidas:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/academic/chapter-1-2-modeling.md`, `docs/discovery/boundary-7-implementation-plan.md`, `docs/discovery/phase-3-normative-references-implementation-2026-10-07.md`, `tools/materialize_normative_references.py`, `EXTRACAO/ext_main.qvs` e `docs/discovery/dataset-validation.md`.

## Fatos já documentados

1. **Contrato acadêmico:** `DIM_MOTIVO_SAIDA_PERMANENCIA` deve possuir SK, código, descrição oficial e categoria de encerramento. A dimensão está ligada ao registro de internação, não à capacidade CNES.
2. **Chave candidata já decidida no Boundary 7:** `%SK_MOTIVO_SAIDA=Hash128('MOT', COBRANCA)`, onde `COBRANCA` é a chave de fonte **textual**, sem ponto. No relatório acadêmico, `11`↔`1.1`, `41`↔`4.1`, `61`↔`6.1`; Boundary 7 fixa explicitamente `24`↔`2.4`. O código normativo **com ponto** será atributo de exibição, não SK adicional nem substituição silenciosa da chave de fonte.
3. **Material normativo oficial já trabalhado no projeto:** Portaria SAS/MS **719/2007** e atualização **384/2010**. `tools/materialize_normative_references.py` contém **28** tuplas `(codigo_fonte, codigo_normativo, descricao, grupo, fonte_oficial_base, fonte_oficial_atualizacao)`. São excluídos os códigos revogados `13`/`17`, enquanto a lista validada incorpora `19`, `32` e `61`–`67`.
4. **Falha histórica registrada e resolvida na Fase III-C1:** materialização inicial de apenas 21 linhas cobriu mal o RD (**124.233** linhas sem referência); com domínio oficial atualizado de 28 códigos, o checkpoint III-C1 concluiu `PASS_PARTIAL`, `motivo_rows=28`, `motivo_unmatched_rd_rows=0`, RD 566.672. **Não reaproveitar o hash da materialização antiga de 21 códigos** como valor esperado do CSV corrigido.
5. **Arquivos locais versionados apenas como contratos, não como dados:** `BASE/REFERENCIAS/motivo_saida_permanencia.csv` e `manifesto_referencias_normativas.json` (SHA e integridade da origem normativa C1), `EXTRACAO/QVD/REF_MOTIVO_SAIDA.qvd` e `SRC_SIH_RD.qvd`, `EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_REFERENCIAS_NORMATIVAS.csv`. A referência QVD tem **9 campos físicos**: `COBRANCA`, `MOTIVO_CODIGO_NORMATIVO`, `MOTIVO_DESCRICAO`, `MOTIVO_GRUPO`, `MOTIVO_FONTE_OFICIAL_BASE`, `MOTIVO_FONTE_OFICIAL_ATUALIZACAO`, e três metadados `_META_*`.
6. **Normalização já presente na extração:** `Right('00' & KeepChar(Text(COBRANCA),'0123456789'),2)`. Na Fase IV, **não** permitir que `KeepChar` oculte caracteres brutos inválidos: inspecionar as 36 fontes reais primeiro, preservar códigos fonte e testar a correspondência sem ponto. No checkpoint SIH/RD anteriormente observado, havia **26 códigos distintos**: `11,12,14,15,16,18,19,21,22,23,24,25,26,27,28,31,41,42,43,51,61,62,63,64,65,66`; os códigos oficiais `32` e `67` devem permanecer na dimensão, embora não observados no recorte. **Confirmar esse perfil novamente localmente**, pois o estado anterior não autoriza supor frequências por código.
7. **Limite histórico explícito:** o dicionário corrigido representa o conjunto normativo aplicado no recorte 2017–2019 conforme C1, mas o preflight de chave/cobertura **não comprova a vigência individual mensal** de cada código nem a equivalência de todos os cenários clínicos.

## Novo gate físico READ-ONLY

Ferramenta versionada na branch `feat/phase-4-dim-motivo-saida-permanencia`: **`tools/preflight_dim_motivo_saida_permanencia.py`**.

- Revalida os dois arquivos normativos C1 e manifesto por **SHA-256**, estágio, status `PASS`, referências de Portarias 719/2007 e 384/2010; não congela o SHA **antigo** do domínio incompleto 21 registros.
- Compara **campo por campo** as 28 linhas CSV UTF-8 contra as 28 tuplas já aprovadas no materializador C1: códigos fonte únicos, códigos normativos únicos, descrição, grupo, proveniência base/atualização, `24`↔`2.4` e ausência dos códigos revogados `13`/`17`.
- Verifica **somente o cabeçalho XML** do QVD de referência (28 linhas/9 campos na ordem documentada), do QVD SIH/RD (566672 linhas e campo `COBRANCA`) e a linha do checkpoint `PASS_PARTIAL` C1 (28 códigos e zero RD unmatched).
- Relê os **36 arquivos físicos** `BASE/CONVERTIDA/RD/RDPB*.csv`, competência 201701–201912; cada `COBRANCA` deve conter um ou dois dígitos após remover exclusivamente espaços ASCII exteriores, normalizado com zero à esquerda. Exige **566672 registros**, 0 unmatched, 26 códigos RD documentados, 32/67 ausentes e 13/17 revogados ausentes. Imprime distribuição **real** dos códigos por fonte e ano para comparação posterior com o QlikView.
- **Não escreve nada**, não gera QVD, não baixa dados e não executa Reload; o QVD binário não é decodificado pelo auditor. Qualquer desvio de SHA, chave, código, domínio ou cobertura interrompe a execução.

**Estado: `IV-MOTIVO_SAIDA_PERMANENCIA=READ_ONLY_PREFLIGHT_CODE_READY_NOT_RUN`.** A execução real local está pendente.

### Comando PowerShell, raiz do repositório

```powershell
git fetch origin
git switch feat/phase-4-dim-motivo-saida-permanencia
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar branch de motivo" }

.\.venv\Scripts\python.exe .\tools\preflight_dim_motivo_saida_permanencia.py
if ($LASTEXITCODE -ne 0) { throw "Preflight DIM_MOTIVO_SAIDA_PERMANENCIA falhou" }
```

**Se aprovado**, o preflight retornará `REFERENCE_ROWS=28`, `REFERENCE_DISTINCT_SOURCE_CODES=28`, `REFERENCE_CODE_24=2.4`, `REFERENCE_QVD_ROWS=28`, `RD_FILES=36`, `RD_ROWS=566672`, `RD_UNMATCHED=0`, `QVD_GENERATED=False`, `OUTPUT_FILES_WRITTEN=0`, terminando com `VERDICT=PASS_MOTIVO_28_CODE_REFERENCE_AND_RD_PREFLIGHT_ONLY`.

## Hipótese de implementação — ainda não aprovada para Reload

**HIPÓTESE DE MODELAGEM:** uma linha por **código fonte `COBRANCA`** normativo (28 linhas), chave `Hash128('MOT', codigo_fonte)`, atributos físicos de código fonte sem ponto, código normativo pontuado, descrição oficial, grupo/categoria de encerramento e rastreabilidade às portarias. Definir nomes físicos somente depois da inspeção e do preflight PASS; não criar include, QVD dimensional, checkpoint, PR ou fatos antecipadamente.

**DECISÕES PENDENTES:** compatibilidade completa físico-textual entre RD/SIH, CSV corrigido e QVD C1, distribuição real por código, regra de forma textual efetiva no QlikView 12 e campos físicos definitivos. Preservar `T29_HISTORICAL=NOT_APPROVED` e o relatório acadêmico impresso intacto.

**Estado final deste checkpoint de Discovery:** `main=6/8 DIMENSOES INTEGRADAS`; `MOTIVO=READ_ONLY_PREFLIGHT_CODE_READY_NOT_RUN`.

## Gate IV-MOTIVO — preflight físico PASS local (09/10/2026)

**FATO VERIFICADO — PowerShell fornecido pelo responsável**, após atualizar `main` e entrar na branch de `DIM_MOTIVO_SAIDA_PERMANENCIA`, executando `tools/preflight_dim_motivo_saida_permanencia.py`:

```text
MODE=IV_DIM_MOTIVO_SAIDA_READ_ONLY_PREFLIGHT
OUTPUT_FILES_WRITTEN=0
QVD_GENERATED=False
REFERENCE_CSV_SHA256=dea572f8b04acd06ea214711ac1c56d5f494e2fa7e0713883881c65fa850bdac
REFERENCE_C1_MANIFEST=PASS
REFERENCE_ROWS=28
REFERENCE_DISTINCT_SOURCE_CODES=28
REFERENCE_DISTINCT_NORMATIVE_CODES=28
REFERENCE_CODE_24=2.4
REFERENCE_REVOKED_13_17=ABSENT
REFERENCE_GROUP_ROWS=[('POR ALTA', 7), ('POR OUTROS MOTIVOS', 1), ('POR PERMANÊNCIA', 8), ('POR PROCEDIMENTO DE PARTO', 7), ('POR TRANSFERÊNCIA', 2), ('POR ÓBITO', 3)]
REFERENCE_SOURCE_LABELS=EXACT_MATCH_C1_MATERIALIZER
REFERENCE_QVD_ROWS=28
REFERENCE_QVD_FIELDS=9
RD_QVD_ROWS=566672
CHECKPOINT_C1=PASS_PARTIAL_ZERO_UNMATCHED
RD_FILES=36
RD_MONTHS=36
RD_ROWS=566672
RD_RAW_DISTINCT=26
RD_NORMALIZED_DISTINCT=26
RD_ABSENT_OFFICIAL_CODES=32,67
RD_REVOKED_13_17=ABSENT
RD_CODE_24_ROWS=6
RD_SOURCE_COUNTS=[('11', 14134), ('12', 333271), ('14', 10447), ('15', 6699), ('16', 2870), ('18', 1101), ('19', 45), ('21', 11901), ('22', 13209), ('23', 3369), ('24', 6), ('25', 279), ('26', 1751), ('27', 1860), ('28', 311), ('31', 13066), ('41', 22596), ('42', 576), ('43', 3408), ('51', 1585), ('61', 120725), ('62', 2130), ('63', 234), ('64', 1068), ('65', 11), ('66', 20)]
RD_NORMALIZED_COUNTS=[('11', 14134), ('12', 333271), ('14', 10447), ('15', 6699), ('16', 2870), ('18', 1101), ('19', 45), ('21', 11901), ('22', 13209), ('23', 3369), ('24', 6), ('25', 279), ('26', 1751), ('27', 1860), ('28', 311), ('31', 13066), ('41', 22596), ('42', 576), ('43', 3408), ('51', 1585), ('61', 120725), ('62', 2130), ('63', 234), ('64', 1068), ('65', 11), ('66', 20)]
RD_YEAR_COUNTS=[('2017', 187726), ('2018', 187293), ('2019', 191653)]
RD_UNMATCHED=0
SK_RULE_CANDIDATE=Hash128_MOT_AND_COBRANCA_TEXTUAL
SOURCE_DOMAIN_POLICY=FULL_UPDATED_28_CODES
HISTORICAL_INDIVIDUAL_VALIDITY=NOT_ESTABLISHED_BY_THIS_TEST
VERDICT=PASS_MOTIVO_28_CODE_REFERENCE_AND_RD_PREFLIGHT_ONLY
```

**Interpretação:** o CSV corrigido da Fase III-C1 tem **28 linhas únicas**, SHA acima; o QVD da referência tem **28 linhas/9 campos**; o checkpoint C1 permanece `PASS_PARTIAL`. O código fonte SIH `COBRANCA` está presente nos **36 CSVs RD (566672 linhas)**, com **26 códigos distintos efetivos**, todos de dois dígitos (sem mudança pela normalização), zero sem referência; `32` e `67` são códigos normativos sem registros no recorte, e **continuam na DIM**. O mapeamento `24` → `2.4` possui **6 registros RD**. As seis categorias são comprovadas pelos rótulos de `grupo` e contagens `7,1,8,7,2,3`, respectivamente. Não se observou código revogado `13`/`17`.

**VEREDITO:** `IV-MOTIVO=PHYSICAL_PREFLIGHT_PASS`. Aprova avançar para **implementação QlikView isolada**, mas **não** comprova vigência normativa individual em cada competência (apenas chave e cobertura estática). A referência tem conteúdo e rótulos reconciliados ao materializador C1, não constitui inspeção independente da íntegra das portarias. Nenhum arquivo físico novo foi criado nesse preflight.

## Sétimo checkpoint — código QlikView/auditor preparado, execução pendente

**Implementação candidata já versionada na branch** `feat/phase-4-dim-motivo-saida-permanencia`:

- Novo `TRANSFORMACAO/transf_dim_motivo_saida_permanencia.qvs` referenciado após `transf_dim_carater_atendimento.qvs` em `TRANSFORMACAO/transf_main.qvs`. O sétimo script só prossegue se a sexta dimensão mantiver `6 SK, 566672 RD e 0 unmatched`.
- Lê `EXTRACAO/QVD/REF_MOTIVO_SAIDA.qvd` (códigos `COBRANCA`, códigos normativos pontuados, descrição, categoria e duas fontes oficiais C1), exigindo **28 linhas, 28 códigos fonte únicos, 28 normativos distintos, 6 categorias, ausência de 13/17 e equivalência 24→2.4**. Não regrava a referência QVD.
- Dimensão proposta: **28 linhas e sete atributos físicos** — `%SK_MOTIVO_SAIDA` (a **SK exata aprovada em Boundary 7**, `Hash128('MOT', codigo_fonte)`), `COD_MOTIVO_SAIDA_FONTE`, `COD_MOTIVO_SAIDA_NORMATIVO`, `DESCRICAO_OFICIAL_MOTIVO_SAIDA`, `CATEGORIA_ENCERRAMENTO`, `MOTIVO_FONTE_OFICIAL_BASE`, `MOTIVO_FONTE_OFICIAL_ATUALIZACAO`. As duas URLs são **metadados de rastreabilidade** e não novas entidades. Campos nomeados especificamente para impedir associações não intencionais com outras dimensões.
- Reconciliação `COBRANCA` em `EXTRACAO/QVD/SRC_SIH_RD.qvd` usando **normalização do III-C1** (`Right('00' & KeepChar(Text(COBRANCA),'0123456789'),2)`), exigindo **566672 linhas/26 códigos efetivos/0 inválidos/0 unmatched**, 6 registros para `24`, e **zero diferenças em relação às 26 frequências** verificadas independentemente nos CSVs pelo Python. A tabela temporária de mapeamento das frequências documentadas só é usada para **controle de qualidade**; nenhum fato ou relacionamento é construído.
- Após todos os gates, produzir exclusivamente `TRANSFORMACAO/QVD/DIM_MOTIVO_SAIDA_PERMANENCIA.qvd` e `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_MOTIVO_SAIDA_PERMANENCIA.csv`, contendo `PASS_PARTIAL_DIM_MOTIVO_SAIDA_ONLY`, 28 SK únicas e zero diferenças de frequência. Não criar marcador global de transformação, fatos, Link Table ou painel.
- Auditor independente **READ-ONLY** `tools/audit_dim_motivo_saida_permanencia_qvd.py` criado (não executado), repetirá validação do manifesto, CSV e 36 RD e verificará **header XML QVD 28×7**, SHA-256 QVD/checkpoint, valores esperados e frescor. Usa o SHA da referência corrigida `dea572f8b04acd06ea214711ac1c56d5f494e2fa7e0713883881c65fa850bdac`. **Não decodifica o corpo binário do QVD**; confirmar integridade da carga também pelo log real do QlikView.

### Gate QlikView 12 local — pendente

1. Atualizar `feat/phase-4-dim-motivo-saida-permanencia` com `git pull --ff-only`, conferir a presença do novo include e do auditor, e abrir `TRANSFORMACAO/TRANSF.qvw` no QlikView 12.
2. Executar **Reload** e exigir na **mesma execução**:
   ```text
   [TRANSFORMACAO][IV-MOTIVO] SOURCE Rows=28 Fields=7 Codes=28 NormCodes=28 Groups=6 Invalid=0 Map24=1
   [TRANSFORMACAO][IV-MOTIVO] COVER RD=566672 Distinct=26 UNMATCHED=0 Invalid=0 Code24=6
   [TRANSFORMACAO][IV-MOTIVO] DISTRIBUTION Groups=26 Mismatches=0 Absent32_67=True
   [TRANSFORMACAO][IV-MOTIVO] DIM_MOTIVO_SAIDA_PERMANENCIA_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN
   ```
   Verificar `Execução concluída.`, sem erros de execução, timestamps condizentes com QVD/checkpoint gerados.
3. Somente depois de reload concluído rodar `tools/audit_dim_motivo_saida_permanencia_qvd.py` e esperar (se passar) `VERDICT=PASS_LOCAL_DIM_MOTIVO_QVD_HEADER_CHECKPOINT_RECONCILED`.
4. Trazer **trechos do log e saída do auditor** para decisão da revisão/PR. **O novo QlikView ainda NÃO foi executado**; toda a evidência operacional é do preflight Python anterior, não do QVD dimensional.

**Estado:** `IV-MOTIVO=PHYSICAL_PREFLIGHT_PASS_QLIK_CODE_AND_AUDITOR_READY_NOT_RUN`; `main=6/8` dimensões; `T29_HISTORICAL=NOT_APPROVED`. A primeira entrega impressa (Capítulos 1–2) continua fechada.

## Sétimo checkpoint — QVD e checkpoint físicos PASS local, log QlikView pendente (09/10/2026)

**FATO VERIFICADO — saída PowerShell fornecida pelo responsável**, executando `tools/audit_dim_motivo_saida_permanencia_qvd.py` na branch `feat/phase-4-dim-motivo-saida-permanencia`. A auditoria concluiu sem exceção nem falha de `$LASTEXITCODE`.

- Revalidou os **36 arquivos CSV RD**, **566672 registros SIH/RD**, **26 códigos efetivos sem alteração na normalização**, ausência dos oficiais não observados `32`/`67` e dos revogados `13`/`17`, **0 unmatched** e zero diferenças entre distribuição RD e referência do preflight. Código fonte `24` foi observado em **6 registros** e corresponde ao código normativo `2.4`.
- Revalidou a referência normativa C1 de **28 códigos fonte e 28 códigos normativos**, distribuídos em **6 categorias**, CSV original SHA-256 **`dea572f8b04acd06ea214711ac1c56d5f494e2fa7e0713883881c65fa850bdac`**, manifesto C1 `PASS`, referência QVD `REF_MOTIVO_SAIDA` **28 linhas/9 campos**, QVD RD 566672 linhas e checkpoint III-C1 `PASS_PARTIAL_ZERO_UNMATCHED`.
- O QVD local `TRANSFORMACAO/QVD/DIM_MOTIVO_SAIDA_PERMANENCIA.qvd` foi detectado com **28 linhas / 7 campos no cabeçalho XML**, tamanho **7062 bytes**, SHA-256 **`7306b75e1c29005d1ea50d16e4f67db330360fbcb46bb711ab3b0aee82c25e57`**.
- O checkpoint local `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_MOTIVO_SAIDA_PERMANENCIA.csv` foi detectado com **705 bytes**, SHA-256 **`69d22d1a982d58ef2d3d85aa92f0861052c932dc68a557487c26b6775ae0d30c`**. O auditor conferiu `PASS_PARTIAL_DIM_MOTIVO_SAIDA_ONLY`, **28 SK distintas declaradas pelo próprio QlikView**, 28 códigos da referência, grupo 6, correspondência 24→2.4, RD 566672/26 códigos distintos/0 unmatched/0 inválidos, 6 RD de código 24 e 0 divergências de frequência, com `T29_HISTORICAL=NOT_APPROVED` e `FACTS_AND_LINK_TABLE=NOT_STARTED`.
- **`VERDICT=PASS_LOCAL_DIM_MOTIVO_QVD_HEADER_CHECKPOINT_RECONCILED`** e **`LIMIT=QVD_BINARY_BODY_NOT_INDEPENDENTLY_DECODED`**. O auditor confronta cabeçalho, hashes, frescor e valores do checkpoint Qlik, **não** decodifica por conta própria os dados binários nem comprova o encerramento normal da execução Qlik.

**LIMITE PENDENTE:** O responsável **ainda não forneceu o log real do novo reload QlikView 12**. Os controles `SOURCE`, `COVER`, `DISTRIBUTION`, `DIM_MOTIVO_SAIDA_PERMANENCIA_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN` e `Execução concluída.` **não foram ainda observados diretamente** no log desta execução, nem seus timestamps comparados aos QVD/checkpoint. A existência dos arquivos e o PASS do auditor não substituem essa evidência. Nenhum CI ou leitura completa do corpo binário foi comprovado.

**Estado correto:** `IV-MOTIVO_SAIDA_PERMANENCIA=LOCAL_QVD_HEADER_CHECKPOINT_PASS_RELOAD_LOG_PENDING`; `MAIN_INTEGRATED_DIMENSIONS=6/8`; `T29_HISTORICAL=NOT_APPROVED`; fatos/Link Table/painéis `NOT_STARTED`. **Não abrir PR/realizar merge nem afirmar 7/8 até validação do log e decisão posterior.**

**Próximo gate:** localizar o arquivo `TRANSFORMACAO/TRANSF.qvw*.log` da execução que gerou o QVD; conferir **na mesma execução** `SOURCE Rows=28 Fields=7 Codes=28 NormCodes=28 Groups=6 Invalid=0 Map24=1`, `COVER RD=566672 Distinct=26 UNMATCHED=0 Invalid=0 Code24=6`, `DISTRIBUTION Groups=26 Mismatches=0 Absent32_67=True`, `DIM_MOTIVO_SAIDA_PERMANENCIA_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`, encerramento normal e timestamps compatíveis. As linhas impressas de `IF ScriptErrorCount > ... THEN` são guardas de script e não evidenciam falha por si só.

## Gate QlikView 12 — reload local PASS confirmado (09/10/2026)

**FATO VERIFICADO — trecho real de log e horários dos arquivos fornecidos pelo responsável:**

- Log: `TRANSFORMACAO/TRANSF.qvw.2026_10_09_11_30_27.log`, **104.872 bytes**, com `LastWriteTime=09/10/2026 11:30:40`. O arquivo foi lido por `Select-String` e pelas últimas 35 linhas; **o conteúdo integral não foi fornecido**.
- Linhas 1278–1279: `[TRANSFORMACAO][IV-MOTIVO] START`.
- Linhas 1343–1344, às **11:30:39**: `SOURCE Rows=28 Fields=7 Codes=28 NormCodes=28 Groups=6 Invalid=0 Map24=1`.
- Linhas 1483–1484, às **11:30:40**: `COVER RD=566672 Distinct=26 UNMATCHED=0 Invalid=0 Code24=6`.
- Linhas 1486–1487: `DISTRIBUTION Groups=26 Mismatches=0 Absent32_67=True`. A string `Absent32_67=True` é um **TRACE literal** do include, enquanto a prova física da ausência dos códigos `32` e `67` é o preflight dos 36 CSVs SIH/RD.
- Linhas 1529–1530: `DIM_MOTIVO_SAIDA_PERMANENCIA_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`. Linhas 1532–1533 mantêm `PHASE_IV_PARTIAL_ONLY T29_HISTORICAL_NOT_APPROVED`. Linha 1535: **`Execução concluída.` às 11:30:40**.
- O final do log mostra os campos calculados do checkpoint parcial: 28 códigos, 28 normativos, 6 grupos, equivalência `24→2.4`, 28 linhas dimensionais, 7 campos, **28 SK únicas declaradas**, RD 566672/26 códigos/0 unmatched/0 inválidos, 6 RD com `24`, 26 frequências e 0 divergências. O Qlik registrou uma linha de checkpoint, seu `STORE`, e terminou normalmente.
- QVD `TRANSFORMACAO/QVD/DIM_MOTIVO_SAIDA_PERMANENCIA.qvd`: **7062 bytes**, `LastWriteTime=09/10/2026 11:30:40`. Checkpoint `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_MOTIVO_SAIDA_PERMANENCIA.csv`: **705 bytes**, mesmo horário. Arquivos contemporâneos ao `STORE` e encerramento dessa execução.
- **Auditoria física Python local previamente PASS:** `VERDICT=PASS_LOCAL_DIM_MOTIVO_QVD_HEADER_CHECKPOINT_RECONCILED`, QVD SHA-256 `7306b75e1c29005d1ea50d16e4f67db330360fbcb46bb711ab3b0aee82c25e57`, checkpoint SHA-256 `69d22d1a982d58ef2d3d85aa92f0861052c932dc68a557487c26b6775ae0d30c`, referência C1 SHA `dea572f8b04acd06ea214711ac1c56d5f494e2fa7e0713883881c65fa850bdac`.
- Na busca por `Error: Unknown statement` e `Syntax Error` nenhuma ocorrência foi exibida. Linhas `IF ScriptErrorCount > 0 THEN` impressas no log são guardas do script, **não mensagens de erro ocorrido**. O relatório registra apenas excertos e a cauda, não certifica inspeção integral nem execução de CI.

**Conclusão do gate:** `IV-MOTIVO_SAIDA_PERMANENCIA=LOCAL_QLIK_RELOAD_AND_QVD_CHECKPOINT_PASS_REVIEW_NEXT`. Os controles SOURCE/COVER/DISTRIBUTION/STORE e `Execução concluída.` foram observados **na mesma execução**, junto a arquivos locais com horário compatível e auditoria física aprovada. A validação do auditor cobre cabeçalho QVD, hashes e valores do checkpoint, **não** a decodificação independente de cada registro binário. A equivalência e cobertura normativa estática **não** comprovam vigência histórica mensal individual de cada código.

**Próximo gate:** revisar diff do PR contra `main` e abrir **Draft PR**, sem squash merge automático. A `main` permanece com **6 de 8 dimensões integradas** até eventual merge explícito. `T29_HISTORICAL=NOT_APPROVED`; fatos/Link Table/painéis `NOT_STARTED`. Os registros acima supersedem o status cronológico `RELOAD_LOG_PENDING` das seções anteriores.

## Revisão de integração — PR #80 criado em Draft (09/10/2026)

**FATO VERIFICADO NO GITHUB:** PR [#80](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/80), `feat/phase-4-dim-motivo-saida-permanencia` → `main`, **`open`, `draft=true`, `merged=false`**, com `mergeable=true` confirmado em consulta posterior à criação (na resposta inicial o cálculo transitório retornou `false`). Branch `behind_by=0`; **sete arquivos** no diff, conferidos também pelo `fetch_pr_patch`: `AGENTS.md`, `TRANSFORMACAO/transf_dim_motivo_saida_permanencia.qvs`, `TRANSFORMACAO/transf_main.qvs`, este relatório, `docs/project/current-state.md`, `tools/preflight_dim_motivo_saida_permanencia.py` e `tools/audit_dim_motivo_saida_permanencia_qvd.py`.

**Revisão estática de escopo:** PASS — a alteração mantém as seis dimensões anteriores, não modifica extração, QVDs/datasets versionados, capítulos acadêmicos, fatos, Link Table, painéis ou marcador global. Gates físicos Python e reload real QlikView 12 passaram **localmente**, com limites de auditoria já documentados. Não afirmar CI ou revisão formal de terceiros como PASS sem evidência adicional.

**DECISÃO PENDENTE:** concluir a revisão do PR #80 e promover de Draft para Ready for review; **squash merge requer autorização específica separada**. Até merge efetivo, `main` permanece **6/8 dimensões integradas**. `T29_HISTORICAL=NOT_APPROVED` e fatos/Link Table/PAINEL `NOT_STARTED`.

## PR #80 — Ready for review (09/10/2026)

**FATO VERIFICADO NO GITHUB:** após solicitação de prosseguimento do responsável, PR [#80](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/80) promovido de Draft para **Ready for review**. `state=open`, `draft=false`, `merged=false`, `mergeable=true` confirmado em consulta após a promoção (o cálculo de mergeabilidade retornou `false` transitoriamente antes da atualização; não comprova conflito persistente).

**Conferência final de escopo:** diff `feat/phase-4-dim-motivo-saida-permanencia` vs `main` com `behind_by=0` e somente **7 arquivos** QlikView/Python/documentação. Revisão estática da SK `Hash128('MOT', COBRANCA normalizado)`, domínio C1 28 códigos/6 grupos, equivalência `24→2.4`, preservação dos seis checkpoints anteriores, cobertura 566672 RD/0 unmatched, frequência dos 26 códigos e gravação exclusivamente de QVD/checkpoint **parciais**: PASS. Não houve alteração de fatos, Link Table, painel, extração ou capítulos acadêmicos.

**Verificações de colaboração/CI:** consulta remota para commit `52febcb1135b11604b1afa3fe49f8a2229db8350` retornou **status checks e workflow runs vazios**; até a promoção, a API também não mostrou revisões formais ou threads. Isso **não** significa CI PASS ou aprovação por terceiros. Os testes QlikView e auditoria física foram **locais**, log recebido em trechos e QVD binário sem decodificação externa independente.

**DECISÃO PENDENTE:** autorização específica do responsável para eventual **squash merge do PR #80**, após nova checagem de `mergeable`, head SHA e escopo. Não executar merge sem autorização. A `main` permanece **6/8 dimensões integradas**. Depois do merge, a próxima fase dimensional é a Discovery de `DIM_TIPO_LEITO`, sujeita à pendência `T29_HISTORICAL=NOT_APPROVED` (vigência histórica CNES); não inferir aprovação ou começar implementação sem resolução do gate.
