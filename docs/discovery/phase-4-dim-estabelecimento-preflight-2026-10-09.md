# Fase IV — DIM_ESTABELECIMENTO — preflight histórico

**Data:** 09/10/2026  
**Branch:** `feat/phase-4-dim-estabelecimento`  
**Estado:** `READ_ONLY_SOURCE_PREFLIGHT_PENDING` — sem novo script de transformação, QVD ou PR.

## Estado de entrada verificado

- [PR #75](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/75) (DIM_MUNICIPIO) integrado na `main` via squash `7f796bed9aa3c41e8bf80fe0d24d493b8e66a1d9`.
- IV-MUNICIPIO obteve `PASS_LOCAL_QVD_HEADER_CHECKPOINT_RECONCILED`: 937 registros, 8 campos, 223 municípios PB, 714 códigos externos distintos, 5.202 RD externos preservados, 937 SK distintas, zero invalidos/sem correspondência; QVD SHA-256 `e6e347a1c88f7508ddc26b181342430bec6318bb03818c195a9b4707b8b0b49f`; CSV SHA-256 `9b8f987ea8b6133d7939e09d0b43a9b859b4b948ec15a3fa9ba4d9bde9074b49`.
- Fase IV: 2 dimensões integradas (Tempo, Município) e 6 pendentes. Fatos, Link Table e PAINEL não iniciados. `T29_HISTORICAL=NOT_APPROVED`.

## Contrato já aprovado (não alterar)

`docs/discovery/boundary-5-historization-role-playing.md`:
- `DIM_ESTABELECIMENTO` histórica mensal, **1 linha por CNES × competência**; `CNES` é identidade cadastral; versão é `CNES + competência`.
- **Não** aplicar estado cadastral posterior retroativamente; não comprimir intervalos (SCD2) na V1.
- Se nomes históricos não tiverem fonte comprovada na competência: **`NULL`**, sem backfill, forward fill ou substituição por nome corrente. Ausência documentada 201701–201705 não bloqueia a dimensão.

`docs/discovery/boundary-7-implementation-plan.md`:
- `%SK_ESTABELECIMENTO = Hash128('ESTAB', CNES, COMPETENCIA)`;
- fatos só relacionarão a versão de CNES correspondente à competência; T16 deve impedir join de versão futura.

**FATO VERIFICADO NO SCRIPT DO REPOSITÓRIO:** `EXTRACAO/ext_main.qvs` atualmente grava `SRC_CNES_ST.qvd` com `CNES`, `CODUFMUN`, `COD_CEP`, `CNPJ_MAN`, `VINC_SUS`, `TPGESTAO`, `TP_UNID`, `NATUREZA`, `NAT_JUR`, `COMPETEN` e metadados de origem, **não** carrega `NOME_FANTASIA`/`RAZAO_SOCIAL`. Testes Boundary 3 já documentaram 220.390 linhas, 6.822 CNES distintos, 36 competências e `CNES × competência` único no universo observado. Não inferir que nomes ausentes do staging também estejam necessariamente ausentes dos CSV brutos.

## Gate de origem dos atributos históricos — somente leitura

Antes de elaborar o include de `DIM_ESTABELECIMENTO`, inspecionar os **cabeçalhos reais** dos 36 `BASE/CONVERTIDA/ST/STPB*.csv`, sem ler dados sensíveis, para determinar se há nome/razão social e variações de esquema. Confrontar o achado com o staging QVD atual. Se existir fonte histórica oficial de nomes fora do staging, identificá-la e validar competência/proveniência antes de usar; não preencher silenciosamente.

Uma inspeção de cabeçalhos pode ser executada com Python padrão na raiz do projeto:
```powershell
@'
from pathlib import Path
import csv
from collections import Counter

arquivos = sorted(Path("BASE/CONVERTIDA/ST").glob("STPB*.csv"))
if len(arquivos) != 36:
    raise RuntimeError(f"Esperados 36 ST; encontrados {len(arquivos)}")

assinaturas = Counter()
for p in arquivos:
    with p.open("r", encoding="utf-8-sig", newline="") as f:
        cabecalho = next(csv.reader(f, delimiter=";"))
    assinatura = tuple(cabecalho)
    assinaturas[assinatura] += 1
    provaveis_nomes = [
        x for x in cabecalho
        if any(t in x.upper() for t in ("NOME", "FANT", "RAZAO", "RAZÃO", "RSOC"))
    ]
    print(p.name, "COLUNAS=", len(cabecalho), "CAMPOS_NOME=", provaveis_nomes)
    if p.name.startswith(("STPB1701", "STPB1705", "STPB1706", "STPB1912")):
        print("EXEMPLO_CABECALHO=", cabecalho)

print("ARQUIVOS=", len(arquivos))
print("SCHEMAS_DISTINTOS=", len(assinaturas))
for cab, qtd in assinaturas.items():
    print("SCHEMA_OCORRENCIAS=", qtd, "COLUNAS=", len(cab))
print("PREFLIGHT_HEADERS_READ_ONLY_CONCLUIDO")
'@ | .\.venv\Scripts\python.exe -
```

**Próxima decisão:** conferir saída real do preflight, localizar fontes aprovadas de nome histórico se existirem e então preparar o menor script `TRANSFORMACAO/transf_dim_estabelecimento.qvs`, com gate `CNES × competência=220390`, 36 competências e nenhuma versão futura aplicada. Nenhum código implementado neste documento.

## Resultado do preflight read-only dos cabeçalhos CNES/ST — 09/10/2026

**FATO VERIFICADO — saída local do responsável:**

- `git status --short` vazio, `git fetch origin` e checkout da branch `feat/phase-4-dim-estabelecimento` concluídos.
- Python 3 percorreu os **36** `BASE/CONVERTIDA/ST/STPB*.csv` de `STPB1701.csv` a `STPB1912.csv`. Resultado `PREFLIGHT_HEADERS_READ_ONLY_CONCLUIDO`; **2 schemas distintos**.
- De **201701 a 201911**, **35 arquivos com 201 colunas**. O arquivo **`STPB1912.csv` tem 208 colunas**.
- Na competência 201912, as sete colunas novas são `AP01CV07`, `AP02CV07`, `AP03CV07`, `AP04CV07`, `AP05CV07`, `AP06CV07`, `AP07CV07`; outras colunas `APxxCVyy` também tiveram a ordem alterada. Nenhuma delas faz parte do contrato atual de staging da dimensão.
- A busca por `NOME`, `FANT`, `RAZAO`, `RAZÃO` e `RSOC` retornou `CAMPOS_NOME=[]` para **todos os 36 cabeçalhos**; especificamente não existem campos `NOME_FANTASIA` nem `RAZAO_SOCIAL` nos ST inspecionados.
- Os campos **realmente presentes no cabeçalho bruto e no staging QVD vigente** são `CNES`, `CODUFMUN`, `COD_CEP`, `CNPJ_MAN`, `VINC_SUS`, `TPGESTAO`, `TP_UNID`, `NATUREZA`, `NAT_JUR`, `COMPETEN`. O staging também preserva `_META_SOURCE_COMPETENCE`, `_META_SOURCE_FILE` e outros metadados.
- A inspeção analisou **somente cabeçalhos**, não comparou valores registro por registro nem buscou outra fonte de nomes. Não afirmar que nome não existe em todo CNES oficial; o escopo da constatação são os **36 ST concretamente analisados**.

**Decisão de execução compatível com Boundaries 5 e 7:** `DIM_ESTABELECIMENTO` seguirá com uma versão mensal por `CNES × COMPETENCIA`, chave `Hash128('ESTAB', CNES, COMPETENCIA)` e atributos históricos obtidos apenas do próprio snapshot. Na ausência de fonte comprovada de nomes para a mesma competência, `NOME_FANTASIA` e `RAZAO_SOCIAL` ficarão `NULL` (nenhum forward fill/backfill). Isso **não** autoriza usar nome de 2019 para dados de 2017; uma futura referência nominal exigirá validação própria por competência.

**Gate seguinte, ainda não atestado:** materializar `DIM_ESTABELECIMENTO.qvd` a partir de `SRC_CNES_ST.qvd`, cobrindo o staging validado (**220.390 registros, 6.822 CNES distintos e 36 competências, sem duplicidades CNES×competência**) e executando controles `T16` contra versão histórica futura. A prova dos totais no QlikView local e a leitura do cabeçalho QVD ainda serão exigidas. `PHASE_IV=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.

## Implementação de checkpoint IV-ESTABELECIMENTO — CODE READY, GATE LOCAL PENDENTE

**Após o preflight**, implementou-se `TRANSFORMACAO/transf_dim_estabelecimento.qvs` (include versionável) e chamada ao final de `TRANSFORMACAO/transf_main.qvs`, **após** os checkpoints de `DIM_TEMPO` e `DIM_MUNICIPIO`. Nenhuma modificação em `EXTRACAO`, dados de staging, 3 fatos, Link Table ou modelo acadêmico.

### Saída física planejada

`TRANSFORMACAO/QVD/DIM_ESTABELECIMENTO.qvd`, com 14 campos:
1. `%SK_ESTABELECIMENTO`: `Hash128('ESTAB', CNES, COMPETENCIA)` dos valores mensais do próprio ST;
2. `CNES` e `COMPETENCIA` (código mensal `AAAAMM`);
3. atributos ST da mesma linha/competência: `CODUFMUN`, `COD_CEP`, `CNPJ_MAN`, `VINC_SUS`, `TPGESTAO`, `TP_UNID`, `NATUREZA`, `NAT_JUR`;
4. `NOME_FANTASIA` e `RAZAO_SOCIAL`: ambos **`NULL`**, pois nenhuma coluna de nomes foi observada em todos os 36 ST; `NOME_HISTORICO_STATUS='SEM_NOME_HISTORICO_ST_VALIDADO'` como metadado explícito de lacuna, não dado clínico/cadastral.

`TRANSFORMACAO/QVD/_CHECKPOINT_DIM_ESTABELECIMENTO.csv` com **19 campos** e status `PASS_PARTIAL_DIM_ESTABELECIMENTO_ONLY` somente depois de todas as verificações passarem.

### Gates fail-closed do novo script

- Pré-condição: IV-MUNICIPIO carregado e íntegro.
- Leitura somente do `SRC_CNES_ST.qvd` de staging aprovado.
- Staging: **220.390** versões de `CNES × COMPETEN`, **6.822** CNES distintos, **36** competências; códigos não vazios/não alfanuméricos, competência AAAAMM 201701–201912 e `_META_SOURCE_COMPETENCE` fiel ao campo. Duplicidade da combinação CNES×mês → **falha**.
- QVD esperado com **220.390 linhas, 14 campos, 220.390 SK distintas e versões distintas**, 0 inválidas e 0 nomes sem fonte preenchidos.
- Para contornar potencial comparação numérica/textual dual observada em IV-MUNICIPIO, somente o mapa de cobertura **interno** usa chave prefixada `E|CNES|AAAAMM`, valor constante `1`. Primeiro self-check de todas as 220.390 versões, depois testes de cobertura exata com **566.672 RD** e **35.518 LT** na respectiva competência, com **0 unmatched**. Um registro de competência posterior não satisfaz o teste da competência antiga (**T16**).
- A SK física **não** incorpora o prefixo de mapa, preservando o contrato `Hash128('ESTAB', CNES, COMPETENCIA)`. Nenhuma agregação de atributos através dos meses e nenhum nome retroativo.
- Na falha, `EXIT SCRIPT` antes do `STORE`; **não** gerar `_SUCCESS_TRANSFORMACAO.csv`.

**Aviso:** são validações **implementadas em código, não verificadas localmente**. Os 220.390/6.822/36/566.672/35.518 são expectativas de origem do staging já aprovado; os atributos físicos e a contagem 14/19 só serão fatos após a execução Qlik e auditoria dos artefatos.

### Próxima execução no Windows — QlikView 12

Na raiz do repo, após `git fetch origin` e atualização da branch, com QlikView fechado:

```powershell
$inicio = Get-Date
$exe = "$env:ProgramFiles\QlikView\Qv.exe"
$qvw = (Resolve-Path .\TRANSFORMACAO\TRANSF.qvw).Path

Remove-Item .\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_ESTABELECIMENTO.csv -ErrorAction SilentlyContinue

$p = Start-Process -FilePath $exe -ArgumentList @('/r', ('"' + $qvw + '"')) -WorkingDirectory (Split-Path $qvw -Parent) -PassThru -Wait
"QLIK_EXIT=$($p.ExitCode)"

$log = Get-ChildItem .\TRANSFORMACAO -Filter 'TRANSF.qvw*.log' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $log -or $log.LastWriteTime -lt $inicio) { throw "Log contemporaneo ausente" }

Select-String -Path $log.FullName -Pattern '\[IV-ESTABELECIMENTO\]|FAIL|Execution finished'
Get-Content $log.FullName -Tail 50

$cp = '.\TRANSFORMACAO\QVD\_CHECKPOINT_DIM_ESTABELECIMENTO.csv'
if (Test-Path $cp) { Import-Csv $cp -Delimiter ';' | Format-List } else { 'CHECKPOINT_ESTABELECIMENTO_AUSENTE' }
Get-Item .\TRANSFORMACAO\QVD\DIM_ESTABELECIMENTO.qvd -ErrorAction SilentlyContinue | Select-Object Name,Length,LastWriteTime
```

**Critério de aceite:** log novo, `SELF_CHECK Rows=220390 Missing=0`, `COVER RD=566672 RD_UNMATCHED=0 LT=35518 LT_UNMATCHED=0`, checkpoint novo `PASS_PARTIAL_DIM_ESTABELECIMENTO_ONLY` com 220390×14, e QVD físico lido posteriormente (cabeçalho, 14 campos, hash e timestamp). **Não aprovar pelo `QLIK_EXIT=0` isolado.**

**Estado:** `IV-TEMPO=MERGED_PASS`; `IV-MUNICIPIO=MERGED_PASS`; `IV-ESTABELECIMENTO=CODE_READY_QV_LOCAL_PENDING`; `PHASE_IV=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.

## Primeiro reload físico IV-ESTABELECIMENTO — PASS local Qlik/CSV (09/10/2026 00:24:41)

**FATO VERIFICADO — execução PowerShell enviada pelo responsável do projeto:**

- `git status --short` vazio, `git pull --ff-only` atualizou a branch até `ab86c11` com `transf_dim_estabelecimento.qvs` e o include. Processo QlikView fechado antes da execução.
- `Qv.exe /r` executado com `Start-Process -Wait`: `QLIK_EXIT=0`, log **novo** `TRANSF.qvw.2026_10_09_00_24_32.log`; `Execution finished` às **00:24:41**.
- O script realmente alcançou `[TRANSFORMACAO][IV-ESTABELECIMENTO] START`, `SELF_CHECK Rows=220390 Missing=0`, `COVER RD=566672 RD_UNMATCHED=0 LT=35518 LT_UNMATCHED=0`, `DIM_ESTABELECIMENTO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN` e `PHASE_IV_PARTIAL_ONLY`.
- O `_CHECKPOINT_DIM_ESTABELECIMENTO.csv` **novo** (`CHECKPOINT_NOVO=True`) foi lido por `Import-Csv`, com `generated_at=09/10/2026 00:24:41`, `stage=TRANSFORMACAO_DIM_ESTABELECIMENTO` e `status=PASS_PARTIAL_DIM_ESTABELECIMENTO_ONLY`.
- Campos do checkpoint: `dimension_rows=220390`, `dimension_fields=14`, `distinct_cnes=6822`, `distinct_competences=36`, `unique_versions=220390`, `unique_surrogate_keys=220390`, `invalid_dimension_rows=0`, `self_unmatched=0`, `rd_rows=566672`, `rd_monthly_version_unmatched=0`, `lt_rows=35518`, `lt_monthly_version_unmatched=0`. O log indica **19 campos** do checkpoint e 1 linha.
- Metadados no CSV: `historical_name_source=ST_2017_2019_HEADERS_WITHOUT_NAME_FIELDS`, `historical_names_policy=NULL_NO_FUTURE_BACKFILL`, `t29_historical=NOT_APPROVED` e `facts_and_link_table=NOT_STARTED`.
- `TRANSFORMACAO/QVD/DIM_ESTABELECIMENTO.qvd` existe, tamanho **7.580.750 bytes**, `LastWriteTime=09/10/2026 00:24:41`.

**Conclusão limitada:** o QlikView executou e passou no gate T16 de associação exata por `CNES × competência`, inclusive nas 566.672 linhas RD e 35.518 LT; o QVD e o CSV parcial foram gravados na execução correspondente. A cardinalidade 220390, os 14 campos e a unicidade vieram de asserts do script Qlik, **ainda não do cabeçalho QVD lido independentemente**. A política de nomes nulos é verificada no script e corroborada pela ausência de campos nominais nos 36 cabeçalhos; a auditoria XML do QVD não decodifica cada linha binária.

**PENDÊNCIA ANTES DE MERGE DO PR #76:** auditar read-only os 14 nomes de campo e `NoOfRecords=220390` no `QvdTableHeader` real, compará-los ao checkpoint de 19 campos, obter SHA-256 do QVD e do CSV e conferir timestamps. Nenhum novo reload necessário. Manter `PR_76=DRAFT`, `IV-ESTABELECIMENTO=PASS_LOCAL_QV_CHECKPOINT_PHYSICAL_HEADER_HASH_PENDING`, `PHASE_IV=IN_PROGRESS` e `T29_HISTORICAL=NOT_APPROVED`.

### Gate físico (read-only, sem Qlik reload)

Na raiz do repositório local, Python 3 deve analisar `TRANSFORMACAO/QVD/DIM_ESTABELECIMENTO.qvd` até `</QvdTableHeader>`, validar `NoOfRecords=220390`, 14 `FieldName` esperados (`%SK_ESTABELECIMENTO`, `CNES`, `COMPETENCIA`, `CODUFMUN`, `COD_CEP`, `CNPJ_MAN`, `VINC_SUS`, `TPGESTAO`, `TP_UNID`, `NATUREZA`, `NAT_JUR`, `NOME_FANTASIA`, `RAZAO_SOCIAL`, `NOME_HISTORICO_STATUS`), SHA-256, checkpoint de 19 campos/uma linha e todos os controles acima. Não converter `QLIK_EXIT=0` sozinho em PASS físico.
