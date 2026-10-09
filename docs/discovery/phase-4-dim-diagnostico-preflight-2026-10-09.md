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

