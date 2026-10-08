# Fase III-C3 — SIGTAP / PROC_REA — 08/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração / staging  
**Checkpoint:** III-C3 — Referência oficial de procedimentos  
**Status:** C3.1 PASS; C3.2 PASS; C3.3a MATERIALIZAÇÃO AMOSTRAL DE PROCEDIMENTO IMPLEMENTADA / EXECUÇÃO LOCAL PENDENTE; T27 NÃO AVALIADO

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

### C3.3 — materialização histórica e validação de cobertura

### C3.3 — materialização histórica e validação de cobertura

Depois de confirmar fisicamente os membros/layouts, materializar referências por competência; medir códigos `PROC_REA` válidos/não encontrados para cada mês e produzir lista de exceções. Preservar o código real se não houver descrição ou correspondência, sem fabricar valores.

### C3.4 — staging QlikView 12

Somente após o gate de referência e cobertura: integrar carga aos scripts externos do `EXT.qvw`, produzir `REF_SIGTAP.qvd` e checkpoint parcial sem construir fatos/dimensões no estágio de Extração.

## 4. Limites

- Não alterar C2/T28, já fechados como **PASS**.
- Não reconstruir nem modificar os QVDs de RD/LT/ST/IBGE.
- Não versionar CSVs do perfil, ZIPs oficiais, TXT extraídos nem QVDs.
- Não encerrar a Fase III apenas com C3.1.
- Não alterar as decisões acadêmicas da primeira entrega.
