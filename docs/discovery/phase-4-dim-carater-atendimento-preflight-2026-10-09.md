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

