# Fase III-C3 — SIGTAP / PROC_REA — 08/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração / staging  
**Checkpoint:** III-C3 — Referência oficial de procedimentos  
**Status:** C3.1/C3.2/C3.3a/C3.3a.1/C3.3b.1/C3.3b.2 PASS; T27 PASS; C3.4a CSV DE STAGING IMPLEMENTADO / EXECUÇÃO LOCAL E REVISÃO DE ENCODING PENDENTES; C3.4b QLIK PENDENTE

## 1. Contrato aprovado

Fontes canônicas: [Boundary 4](boundary-4-auxiliary-references.md), [Boundary 7](boundary-7-implementation-plan.md) e [Current State](../project/current-state.md).

**FATO VERIFICADO NA DOCUMENTAÇÃO DO PROJETO:**

- procedimento realizado: campo SIH/RD `PROC_REA`;
- códigos de procedimento observados na Discovery: largura de 10 dígitos;
- referência oficial: SIGTAP (Tabela de Procedimentos, Medicamentos e OPM do SUS);
- lookup deve respeitar **mesma competência** do RD: `PROC_REA + competência` contra SIGTAP;
- `DIM_PROCEDIMENTO` acadêmica mantém código, nome, descrição oficial, grupo, subgrupo e forma de organização;
- a arquitetura dimensional e a chave técnica previstas no Boundary 7 permanecem inalteradas;
- o inventário SIGTAP existente já encontrou **36/36 pacotes oficiais** `TabelaUnificada_YYYYMM*.zip` para 2017–2019, sem competências faltantes ou duplicadas.

Os resultados do inventário não provam a existência nem a estrutura dos TXT de procedimento dentro de cada pacote. Essas características dependem de inspeção física.

**DECISÃO PENDENTE:** nomes de membros ZIP, nomes de campos, layout posicional, regras de vigência, versões do procedimento, cobertura e exceções de `PROC_REA`. Nenhuma delas deve ser presumida pelo nome do ZIP.

## 2. C3.1 — perfil empírico dos códigos RD (READ-ONLY)

Implementação: `tools/profile_proc_rea.py`.

Entrada: **36 CSVs locais** `BASE/CONVERTIDA/RD/RDPBYYMM.csv`, competências 201701–201912.

O script:

1. valida quantidade de arquivos, formato de nomes, exclusividade e cobertura das 36 competências;
2. exige o total RD já reconciliado de **566.672 linhas**;
3. lê `PROC_REA` **como texto do CSV**, sem converter em número e sem remover zeros, espaços ou outro caractere;
4. mede códigos brutos distintos, ocorrências, comprimento, caracteres, vazios, zeros à esquerda, primeira/última competência e meses observados;
5. registra volumes e códigos distintos por competência mensal;
6. gera SHA-256 das saídas do perfil e um manifesto JSON para reconciliação posterior.

Classificações do perfil:

- `TEN_ASCII_DIGITS`: exatamente 10 dígitos ASCII;
- `OTHER_LENGTH_ASCII_DIGITS`: apenas dígitos ASCII, com comprimento diferente de 10;
- `HAS_WHITESPACE`;
- `ASCII_ALPHANUMERIC`;
- `OTHER`;
- `EMPTY`.

O script não aplica normalização nem faz lookup. Se encontrar códigos fora do padrão de 10 dígitos, preserva o perfil completo e retorna **REVIEW**, sem concluir falsamente a integridade de formato.

Saídas **locais/ignoradas pelo Git**:

- `BASE/REFERENCIAS/proc_rea_raw_profile.csv`;
- `BASE/REFERENCIAS/proc_rea_monthly_profile.csv`;
- `BASE/REFERENCIAS/proc_rea_profile_summary.json`.

### Execução local

Na raiz do repositório:

~~~powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\profile_proc_rea.py
~~~

Depois:

~~~powershell
Get-Content .\BASE\REFERENCIAS\proc_rea_profile_summary.json -Encoding UTF8
~~~

Reconciliação dos hashes:

~~~powershell
$m = Get-Content .\BASE\REFERENCIAS\proc_rea_profile_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
$paths = @($m.outputs.raw_profile, $m.outputs.monthly_profile)
$paths | ForEach-Object {
    $actual = (Get-FileHash $_.path -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{
        Path = $_.path
        Rows = $_.rows
        HashMatch = ($actual -eq $_.sha256.ToLowerInvariant())
    }
}
~~~

### Gate C3.1

**Esperado conforme a fase anterior:** `RD_FILES=36`, `RD_ROWS=566672`, `RD_COMPETENCES=36` e hashes das duas saídas com `HashMatch=True`.

**FATO VERIFICADO — C3.1 PASS (08/10/2026):** a execução local retornou:

```text
MODE=READ_ONLY_INPUT_PROFILING
RD_FILES=36
RD_ROWS=566672
RD_COMPETENCES=36
PROC_REA_DISTINCT_RAW=1249
PROC_REA_BLANK_ROWS=0
PROC_REA_TEN_DIGIT_ROWS=566672
PROC_REA_NONCONFORMING_ROWS=0
PROC_REA_LEADING_ZERO_ROWS=566672
PROC_REA_LENGTH_COUNTS={"10": 566672}
PROC_REA_SHAPE_COUNTS={"TEN_ASCII_DIGITS": 566672}
T27_COVERAGE=NOT_EVALUATED
VERDICT=PASS
```

Foram reconciliados dois arquivos locais:

- `proc_rea_raw_profile.csv`: **1.249 linhas**, SHA-256 `24b41c3819e1eb704eeb03d54f882879190fe64886a9f1088de99279c61dac80`, `HashMatch=True`;
- `proc_rea_monthly_profile.csv`: **36 linhas**, SHA-256 `1ba3ced5c99b185bdf3c70d3eb5f64c08214a9e623487923b157d8856170572d`, `HashMatch=True`.

**Veredito C3.1: PASS.** Os 566.672 códigos brutos têm exatamente 10 dígitos ASCII e começam com zero. Isso descreve a **forma observada**, não a existência de cada código no SIGTAP na sua competência.

O status C3.1 **não é** o status T27: `T27_COVERAGE=NOT_EVALUATED` até o lookup oficial por competência.

## 3. Sequência prevista depois do C3.1

### C3.2 — inspeção controlada dos pacotes SIGTAP

Implementação: `tools/inspect_sigtap_procedure_sample.py`, usando o mesmo inventário validado no C2.3.

**Amostra padrão controlada:** 201701, 201801, 201901, 201912 (**4 de 36 pacotes**). A seleção é restrita a essas quatro competências (pode-se escolher subconjuntos com `--competences`). O script:

- usa FTP oficial já identificado em C2.3, com limite de 250 MiB **por ZIP** e checagem ZIP/CRC;
- baixa cada ZIP apenas em diretório temporário e o descarta após a inspeção;
- registra o nome de **todos** os membros, tamanhos e CRCs;
- seleciona para análise preliminar os nomes contendo `proced`, classificando `LAYOUT` se também contiverem `layout` ou `DATA` nos demais casos;
- registra uma prévia limitada a 3 linhas de até 250 bytes por arquivo candidato (decodificação `cp1252` apenas para visualização, **não** para afirmar encoding definitivo);
- gera manifesto de proveniência (SHA-256 de cada ZIP) e hashes dos dois CSVs produzidos;
- retorna `REVIEW` se a amostra não apresentar simultaneamente candidatos de dados e de layout.

**Não valida automaticamente campos, posições, granularidade, vigência ou cobertura.** A classificação por nome de arquivo é hipótese de busca e precisa ser confrontada com o conteúdo real inspecionado.

Arquivos **locais/ignorados pelo Git**:

- `BASE/REFERENCIAS/sigtap_procedure_sample_members.csv` — inventário de membros de todos os ZIPs selecionados;
- `BASE/REFERENCIAS/sigtap_procedure_sample_candidates.csv` — candidatos a procedimento e prévias;
- `BASE/REFERENCIAS/sigtap_procedure_sample_summary.json` — arquivos, hashes, competências, veredito.

Execução local (na raiz do repositório):

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\inspect_sigtap_procedure_sample.py
```

Inspeção dos resultados:

```powershell
Get-Content .\BASE\REFERENCIAS\sigtap_procedure_sample_summary.json -Encoding UTF8
Import-Csv .\BASE\REFERENCIAS\sigtap_procedure_sample_candidates.csv -Delimiter ';' |
  Select-Object competence, basename, role, uncompressed_size, preview_1_cp1252, preview_2_cp1252 |
  Format-List
```

**FATO VERIFICADO — C3.2 PASS (08/10/2026):** os quatro ZIPs oficiais foram baixados somente para inspeção controlada e lidos com integridade ZIP/CRC. Cada ZIP contém **87 membros**, com **18 candidatos DATA** e **17 candidatos LAYOUT** por critério nominal, totalizando **348 membros** e **140 candidatos**. O `VERDICT=PASS` refere-se somente ao gate de inventário da amostra; não confirma cobertura T27, nem campos/layouts completos.

Os quatro ZIPs encontrados (nomes e bytes efetivamente observados) são:

| Competência | Arquivo | Bytes |
|---|---|---:|
| 201701 | `TabelaUnificada_201701_v1702061521.zip` | 1.734.340 |
| 201801 | `TabelaUnificada_201801_v1801051551.zip` | 1.775.727 |
| 201901 | `TabelaUnificada_201901_v1901041617.zip` | 1.861.290 |
| 201912 | `TabelaUnificada_201912_v1912021555.zip` | 1.912.985 |

Em **todas** as competências a inspeção local identificou exatamente os dois arquivos principais candidatos à referência descritiva de procedimentos:

- `tb_procedimento.txt` — tabela física, com prévia de chave de 10 dígitos seguida de descrição (linha truncada no C3.2, portanto largura/colunas ainda não definidas);
- `tb_procedimento_layout.txt` — arquivo de posições com cabeçalho `Coluna,Tamanho,Inicio,Fim,Tipo`; a prévia confirma `CO_PROCEDIMENTO,10,1,10,VARCHAR2`.

**FATO VERIFICADO:** o arquivo `rl_procedimento_tuss.txt` está vazio nas quatro competências; `DATASUS - Tabela de Procedimentos - Lay-out.xls` foi classificado como candidato apenas pelo nome, mas é binário XLS, não um TXT posicional a ser interpretado como texto. Essas ocorrências não devem contaminar o parser principal.

Hash SHA-256 registrado pelo próprio materializador C3.2 nos dois CSVs locais:

- `sigtap_procedure_sample_members.csv`: 348 linhas, `110e9c22ed79cbab47e5c7726b9d19f9f2fe7117f7519e81d1319fca5583d0ad`;
- `sigtap_procedure_sample_candidates.csv`: 140 linhas, `c6702dd45e2258ee9dfe6ed532e67fe9da4f7e1b6816dba6c2e9046ee77ad02e`.

Os hashes foram registrados no resumo C3.2; a checagem independente dos hashes dos CSVs ainda não foi apresentada. O C3.3a irá comparar o hash de **cada pacote baixado** contra o manifesto C3.2 antes de extrair os arquivos.

### C3.3a — materialização controlada dos arquivos exatos da amostra

Implementação: `tools/materialize_sigtap_procedure_sample.py`.

O script recebe somente a seleção fechada (201701, 201801, 201901, 201912), reutiliza o inventário C2.3 e o resumo C3.2, recarrega apenas ZIPs temporários e **rejeita** divergências de hash SHA-256 ou tamanho frente aos quatro ZIPs já inspecionados.

Para cada competência, materializa somente:

- `BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM/tb_procedimento.txt`;
- `BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM/tb_procedimento_layout.txt`.

Valida a integridade física do ZIP, exige exatamente um arquivo de cada nome, interpreta o layout posicional de forma dinâmica, valida contiguidade/intervalos/nomes únicos de campos e chave `CO_PROCEDIMENTO` nas posições 1–10 (observada no C3.2). Conta registros, comprimentos físicos das linhas, códigos distintos, formatos e possíveis duplicidades por competência. Descobre nomes e posições adicionais **a partir do arquivo real**; nenhum outro campo é inventado. Preserva os bytes originais e registra SHA-256 de arquivos e pacotes.

Outputs locais ignorados:

- `BASE/REFERENCIAS/sigtap_procedure_sample_layout_fields.csv` — todas as colunas oficiais observadas por competência;
- `BASE/REFERENCIAS/sigtap_procedure_sample_manifest.json` — proveniência e diagnóstico físico, com amostra de registros.

Execução:

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\materialize_sigtap_procedure_sample.py
```

Visualização do layout real:

```powershell
Import-Csv .\BASE\REFERENCIAS\sigtap_procedure_sample_layout_fields.csv -Delimiter ';' |
  Select-Object competence, field, width, start, end, type |
  Format-Table -AutoSize
```

Verificação do manifesto e SHA-256 do CSV:

```powershell
$m = Get-Content .\BASE\REFERENCIAS\sigtap_procedure_sample_manifest.json -Raw -Encoding UTF8 | ConvertFrom-Json
Get-Content .\BASE\REFERENCIAS\sigtap_procedure_sample_manifest.json -Encoding UTF8
$actual = (Get-FileHash $m.outputs.layout_fields.path -Algorithm SHA256).Hash.ToLowerInvariant()
"LAYOUT_FIELDS_SHA_MATCH=$($actual -eq $m.outputs.layout_fields.sha256.ToLowerInvariant())"
```

**Gate C3.3a:** amostra de quatro competências com pacotes iguais aos do C3.2, dois membros exatos por competência, layout posicional válido, comprimentos das linhas compatíveis, chave de 10 dígitos/linha e ausência de duplicidade inesperada. **Ainda não** é cobertura do `PROC_REA` por competência nem fechamento T27.

Não baixar 36 competências ou gerar `REF_SIGTAP.qvd` antes da análise dos resultados.

### Evidência C3.3a — PASS na amostra (08/10/2026)

**FATO VERIFICADO:** os quatro pacotes SIGTAP foram novamente obtidos, com conferência do hash/tamanho de cada ZIP contra o C3.2, e os arquivos exatos `tb_procedimento.txt` e `tb_procedimento_layout.txt` foram materializados localmente.

A execução retornou:

| Competência | Registros | Códigos distintos | Colunas | Largura física | Chaves inválidas | Larguras inválidas | Duplicidades |
|---|---:|---:|---:|---:|---:|---:|---:|
| 201701 | 4.542 | 4.542 | 16 | 330 bytes | 0 | 0 | 0 |
| 201801 | 4.587 | 4.587 | 16 | 330 bytes | 0 | 0 | 0 |
| 201901 | 4.609 | 4.609 | 16 | 330 bytes | 0 | 0 | 0 |
| 201912 | 4.624 | 4.624 | 16 | 330 bytes | 0 | 0 | 0 |

`LAYOUT_DISTINCT_HASHES=1`, `LAYOUT_IDENTICAL_IN_SAMPLE=True`, `VERDICT=PASS`. O CSV local de 64 linhas de campos de layout foi gerado com SHA-256 `bd49b1e73afed898b04505c724613264b4e81dc183a2975dcaac681995a69118` registrado pelo script (reconciliação externa desse hash ainda não apresentada).

**Layout físico confirmado na competência 201701** (mesmo hash de layout nas outras três):

| Campo | Posições | Tipo |
|---|---|---|
| `CO_PROCEDIMENTO` | 1–10 | VARCHAR2 |
| `NO_PROCEDIMENTO` | 11–260 | VARCHAR2 |
| `TP_COMPLEXIDADE` | 261 | VARCHAR2 |
| `TP_SEXO` | 262 | VARCHAR2 |
| `QT_MAXIMA_EXECUCAO` | 263–266 | NUMBER |
| `QT_DIAS_PERMANENCIA` | 267–270 | NUMBER |
| `QT_PONTOS` | 271–274 | NUMBER |
| `VL_IDADE_MINIMA` | 275–278 | NUMBER |
| `VL_IDADE_MAXIMA` | 279–282 | NUMBER |
| `VL_SH` | 283–292 | NUMBER |
| `VL_SA` | 293–302 | NUMBER |
| `VL_SP` | 303–312 | NUMBER |
| `CO_FINANCIAMENTO` | 313–314 | VARCHAR2 |
| `CO_RUBRICA` | 315–320 | VARCHAR2 |
| `QT_TEMPO_PERMANENCIA` | 321–324 | NUMBER |
| `DT_COMPETENCIA` | 325–330 | CHAR |

**Controle de escopo:** o layout observado não contém campos explícitos de nome de grupo, subgrupo ou forma de organização. A estrutura acadêmica de `DIM_PROCEDIMENTO` continua aprovada, porém as descrições desses níveis exigem confirmação de fontes/arquivos oficiais e regras de relacionamento antes da materialização dimensional. Não inferir essas descrições a partir da tabela física de procedimentos.

### C3.3a.1 — piloto de correspondência temporal sobre quatro competências

Implementação: `tools/profile_sigtap_procedure_pilot.py`, **sem download**. Consome as quatro tabelas materializadas em C3.3a e os quatro CSVs RD correspondentes (201701, 201801, 201901, 201912).

O script:

- exige manifestos locais C3.1 e C3.3a em `PASS`;
- confere hash SHA-256 dos dois TXT físicos em cada competência contra o manifesto C3.3a;
- interpreta `CO_PROCEDIMENTO` e `DT_COMPETENCIA` pelas posições efetivas do layout e valida os códigos de 10 dígitos/competência em cada linha;
- confere as quantidades de linhas RD contra o perfil C3.1;
- compara somente **`PROC_REA + competência RD` com `CO_PROCEDIMENTO + DT_COMPETENCIA SIGTAP`**;
- calcula cobertura em linhas e códigos distintos por mês, preserva os códigos não encontrados em CSV separado e gera SHA-256 das saídas;
- retorna `REVIEW` se existir qualquer código não encontrado, sem ocultar exceções e sem assumir correção automática.

Saídas locais ignoradas pelo Git:

- `BASE/REFERENCIAS/sigtap_procedure_pilot_coverage.csv`;
- `BASE/REFERENCIAS/sigtap_procedure_pilot_unmatched.csv`;
- `BASE/REFERENCIAS/sigtap_procedure_pilot_summary.json`.

Execução:

~~~powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\profile_sigtap_procedure_pilot.py
~~~

Leitura resumida:

~~~powershell
Import-Csv .\BASE\REFERENCIAS\sigtap_procedure_pilot_coverage.csv -Delimiter ';' |
    Format-Table -AutoSize
Get-Content .\BASE\REFERENCIAS\sigtap_procedure_pilot_summary.json -Raw -Encoding UTF8
~~~

**Gate C3.3a.1:** reconciliação física e de competências, contagens mensais RD confirmadas e exceções integralmente registradas. Este gate foi **atingido com PASS** na execução local detalhada abaixo. O resultado **não conclui T27**, pois 32 competências ainda precisam de referência e lookup mensal. O T27 integral somente poderá ser decidido após C3.3b.1 e C3.3b.2.

### Evidência de C3.3a.1 — piloto PASS (08/10/2026)

**FATO VERIFICADO — `VERDICT=PASS` em execução local:** cruzamento `PROC_REA + competência` SIH/RD contra `CO_PROCEDIMENTO + DT_COMPETENCIA` SIGTAP, restrito aos quatro meses já materializados.

| Competência | RD | Códigos distintos RD | Match RD | Unmatched |
|---|---:|---:|---:|---:|
| 201701 | 14.726 | 552 | 14.726 | 0 |
| 201801 | 14.501 | 534 | 14.501 | 0 |
| 201901 | 15.155 | 614 | 15.155 | 0 |
| 201912 | 14.983 | 617 | 14.983 | 0 |
| **Total** | **59.365** | — | **59.365** | **0** |

O CSV local de exceções não apresentou registros, e o perfil mensal mostrou `coverage_pct=100.000000` para os quatro meses. O manifesto local gerado foi `BASE/REFERENCIAS/sigtap_procedure_pilot_summary.json`.

**Veredito C3.3a.1: PASS.** A evidência sustenta expandir a aquisição histórica, **mas não conclui T27**: 32 competências ainda não tiveram sua referência materializada/validada. As saídas dos arquivos da amostra não devem ser confundidas com resultado global.

### C3.3b.1 — aquisição histórica controlada (36 competências)

Implementação: `tools/materialize_sigtap_procedure_history.py` — **implementado, aguardando execução local**.

**Condições de entrada:** C3.1, C3.3a e C3.3a.1 em PASS e inventário oficial SIGTAP com 36 competências únicas. O script verifica os manifestos, as saídas do piloto e a integridade dos quatro arquivos de referência amostrais anteriores.

- **Reutiliza** os quatro meses materializados em `BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO`.
- Baixa **apenas 32 novos pacotes ZIP oficiais** do inventário C2.3, com limite de 250 MiB por pacote e checagem ZIP/CRC.
- Extrai exclusivamente `tb_procedimento.txt` e `tb_procedimento_layout.txt` por competência, descartando os ZIPs temporários.
- Exige `CO_PROCEDIMENTO` de 10 posições e `DT_COMPETENCIA` igual ao mês do pacote em cada registro.
- Confere linhas de 330 bytes, chaves distintas, ausência de duplicidade e conformidade do layout com as 16 colunas do C3.3a; **uma mudança oficial no layout gera bloqueio para inspeção, não adaptação silenciosa**.
- Nunca substitui um TXT local preexistente se os bytes forem diferentes.
- Registra SHA-256 dos ZIPs baixados, dos dois TXT por mês e do inventário consolidado.

Saídas ignoradas pelo Git:

- `BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM/tb_procedimento.txt` e `tb_procedimento_layout.txt` para as competências faltantes;
- `BASE/REFERENCIAS/sigtap_procedure_history_inventory.csv` (36 linhas);
- `BASE/REFERENCIAS/sigtap_procedure_history_manifest.json` (proveniência e métricas por competência).

Na raiz do repositório:

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\materialize_sigtap_procedure_history.py
```

Valide o manifesto e o hash do CSV:

```powershell
$m = Get-Content .\BASE\REFERENCIAS\sigtap_procedure_history_manifest.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.counts
$m.layout
$actual = (Get-FileHash $m.outputs.inventory.path -Algorithm SHA256).Hash.ToLowerInvariant()
"HISTORY_INVENTORY_SHA_MATCH=$($actual -eq $m.outputs.inventory.sha256.ToLowerInvariant())"
```

**Gate C3.3b.1 — PASS (08/10/2026):** a execução local confirmou 36 meses materializados (quatro já validados e 32 pacotes adicionais), com estrutura, chaves e competências internas válidas. O inventário histórico foi reconciliado por SHA-256; ver a evidência detalhada abaixo.

**Não é T27 PASS.** O cruzamento dos 566.672 RD só poderá ser executado no **C3.3b.2 — cobertura histórica**, depois da validação deste manifesto. Se algum mês tiver layout diferente, registrar evidência e resolver a compatibilidade antes de prosseguir.

### Evidência C3.3b.1 — PASS (08/10/2026)

**FATO VERIFICADO:** a execução local de `tools/materialize_sigtap_procedure_history.py` retornou:

```text
COMPETENCES_VALIDATED=36
SAMPLE_MONTHS_REUSED=4
NEW_PACKAGES_DOWNLOADED=32
TOTAL_PROCEDURE_ROWS=165203
T27_COVERAGE=NOT_EVALUATED
VERDICT=PASS
```

O manifesto `BASE/REFERENCIAS/sigtap_procedure_history_manifest.json` apresenta `status=PASS`, `competences=36`, `sample_months_reused=4`, `new_packages_downloaded=32` e `total_procedure_rows=165203`. Os 36 `tb_procedimento.txt` possuem códigos únicos e competência interna válida, sem erros reportados. O layout de 16 campos, largura de 330 bytes, permaneceu idêntico nos 36 meses, com SHA-256:

`75641d897c8205d3d2e94ddb96431d51bf7a9ed5871ba0645484715cffffb88a`

O arquivo `sigtap_procedure_history_inventory.csv` foi reconciliado externamente (`HISTORY_INVENTORY_SHA_MATCH=True`), com SHA-256:

`23eb6942d69c8c81f30bde5eded896cad2881b64c77cacd1b80b3bb57ad2af8a`

**Interpretação:** 165.203 é a soma das linhas das 36 referências mensais, não o número de procedimentos distintos em três anos. Nenhum join integral com SIH/RD foi executado nesta etapa.

### C3.3b.2 — cobertura histórica e exceções (IMPLEMENTADO / EXECUÇÃO LOCAL PENDENTE)

Script: `tools/profile_sigtap_procedure_full_coverage.py`. O código opera **somente sobre arquivos locais**, sem acesso à rede. Lê `proc_rea_profile_summary.json`, `sigtap_procedure_pilot_summary.json`, `sigtap_procedure_history_manifest.json` e valida hashes dos CSVs de entrada e dos TXT históricos. Reconcilia o manifesto histórico com o inventário de 36 competências e compara os códigos como **texto de 10 dígitos ASCII**, sem converter para número nem substituir valores.

Regra preservada (Boundary 4 e 7):

```text
(RD.Competência, RD.PROC_REA)
    =
(SIGTAP.DT_COMPETENCIA, SIGTAP.CO_PROCEDIMENTO)
```

Gates do script: 36 competências; 566.672 linhas RD; 165.203 linhas SIGTAP somadas por competência; integridade de cada `CO_PROCEDIMENTO`; igualdade de `DT_COMPETENCIA` ao mês do RD; hashes dos arquivos de referência; validação das linhas e códigos distintos RD contra o perfil C3.1; comparação das quatro competências do piloto para evitar regressão; somas globais dos pares cobertos/não cobertos.

Saídas locais e ignoradas pelo Git:

- `BASE/REFERENCIAS/sigtap_procedure_full_coverage.csv` — resumo de 36 linhas, uma por competência;
- `BASE/REFERENCIAS/sigtap_procedure_full_unmatched.csv` — exceções como `competence;proc_rea_raw;unmatched_occurrences`;
- `BASE/REFERENCIAS/sigtap_procedure_full_coverage_summary.json` — síntese, competência, checksums e gate T27.

Execução (raiz do repositório):

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\profile_sigtap_procedure_full_coverage.py
```

Validação independente de hashes:

```powershell
$m = Get-Content .\BASE\REFERENCIAS\sigtap_procedure_full_coverage_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
@($m.outputs.coverage, $m.outputs.unmatched) | ForEach-Object {
    $hash = (Get-FileHash $_.path -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{ Path = $_.path; Rows = $_.rows; HashMatch = ($hash -eq $_.sha256.ToLowerInvariant()) }
}
$m.totals
$m.t27
```

**Gate T27 — PASS em 08/10/2026:** execução local completa apresentada e reconciliada, com 36 competências, 566.672 RD cobertos, 0 unmatched e hashes 2/2 conferidos. O estado da Fase III continua parcial e o QVD de procedimentos ainda não foi gerado.

### Evidência C3.3b.2 — PASS e fechamento T27 (08/10/2026)

**FATO VERIFICADO:** o script `tools/profile_sigtap_procedure_full_coverage.py` executou integralmente as 36 competências, confrontando `PROC_REA` com `CO_PROCEDIMENTO` do SIGTAP na **mesma competência**. A saída e o manifesto registraram:

- `RD_ROWS=566672` e `MATCHED_RD_ROWS=566672`;
- `UNMATCHED_RD_ROWS=0` e `UNMATCHED_CODE_COMPETENCE_PAIRS=0`;
- `REFERENCE_PROCEDURE_MONTH_ROWS=165203`;
- `rd_code_competence_pairs=21031` (pares distintos de código + competência observados nos RD; não são procedimentos globalmente distintos);
- `coverage_pct=100.000000`;
- `T27_GATE=PASS`, `VERDICT=PASS`;
- CSV cobertura: 36 linhas e `HashMatch=True`;
- CSV unmatched: 0 linhas e `HashMatch=True`.

O manifesto `sigtap_procedure_full_coverage_summary.json` registrou `status=PASS` e `t27.gate=PASS`. Portanto **C3.3b.2 e T27 PASS**, sem exceções. O SIGTAP histórico comprovou existência do procedimento por competência, **não** ainda as descrições textuais de grupo/subgrupo/forma de organização nem a conversão Qlik.

### C3.4a — CSV candidato de referência por competência (IMPLEMENTADO / EXECUÇÃO LOCAL PENDENTE)

Implementação: `tools/materialize_sigtap_staging_candidate.py`. Pré-requisitos obrigatórios: manifestos C3.3b.1 e C3.3b.2 PASS, hashes do inventário, CSVs de cobertura e todos os TXT históricos validados.

O script prepara **CSV local intermediário**, sem criar QVD e sem modificar SIH/RD, com campos baseados nas evidências físicas do layout:

- `SIGTAP_COMPETENCIA` ← `DT_COMPETENCIA` (6 caracteres, mês);
- `SIGTAP_CO_PROCEDIMENTO` ← `CO_PROCEDIMENTO` (10 caracteres, preservando zeros à esquerda);
- `SIGTAP_NO_PROCEDIMENTO` ← `NO_PROCEDIMENTO` (posição 11–260, removendo apenas o preenchimento ASCII à direita);
- `SIGTAP_COMPETENCIA_CODIGO` ← `YYYYMM|CO_PROCEDIMENTO` (chave **operacional derivada**, alfanumérica, para evitar coerção numérica no Qlik).

Exige 165.203 pares únicos código/competência, 36 meses, contagens mensais de referência reconciliadas e hashes SHA-256 dos TXT antes de gravar CSV. A chave derivada não altera a chave de negócio aprovada nem antecipa a dimensão acadêmica.

**DECISÃO PENDENTE — encoding descritivo:** `NO_PROCEDIMENTO` é decodificado como **candidato cp1252**, seguindo hipótese técnica ainda não aprovada para esta tabela. O script rejeita bytes incompatíveis e caracteres de controle, produz amostras com acentos no manifesto e emite explicitamente `STRUCTURE_PASS_ENCODING_REVIEW`; não declara o staging Qlik aprovado sem avaliação visual dos nomes por competência.

Saídas locais ignoradas pelo Git:

- `BASE/REFERENCIAS/sigtap_procedimento_staging_candidate.csv`;
- `BASE/REFERENCIAS/sigtap_procedimento_staging_candidate_manifest.json`.

Execução na raiz do repositório:

~~~powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\materialize_sigtap_staging_candidate.py
~~~

Confira contagem, integridade e amostras de descrições:

~~~powershell
$m = Get-Content .\BASE\REFERENCIAS\sigtap_procedimento_staging_candidate_manifest.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.status
$m.rows
$m.distinct_code_month_keys
$m.description_encoding
$h = (Get-FileHash $m.outputs.csv -Algorithm SHA256).Hash.ToLowerInvariant()
"CSV_SHA_MATCH=$($h -eq $m.outputs.sha256.ToLowerInvariant())"
~~~

**Gate C3.4a:** estrutura e hashes PASS + avaliação explícita do texto/acentos da referência. Não confundir o `STRUCTURE_PASS_ENCODING_REVIEW` com PASS definitivo da camada Qlik.

### C3.4b — staging QlikView 12 (PENDENTE)

Somente após C3.4a ser validado, implementar a carga via script externo versionável no `EXTRACAO/EXT.qvw` e produzir `REF_SIGTAP.qvd` e checkpoint `PASS_PARTIAL`. Revalidar **no QlikView** 165.203 pares distintos (código + competência) e match dos 566.672 RD; impedir conversão dos códigos para números. Não criar fatos, dimensões, painel ou status final da Fase III.

## 4. Limites

- Não alterar C2/T28, já fechados como **PASS**.
- Não reconstruir nem modificar os QVDs de RD/LT/ST/IBGE.
- Não versionar CSVs do perfil, ZIPs oficiais, TXT extraídos nem QVDs.
- Não encerrar a Fase III apenas com C3.1.
- Não alterar as decisões acadêmicas da primeira entrega.
