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
