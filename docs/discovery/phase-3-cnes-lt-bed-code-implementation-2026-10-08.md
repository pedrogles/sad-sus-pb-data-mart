# Fase III-C4 — Referência CNES tipo/leito (T29)

**Projeto:** SAD — Data Mart SUS PB  
**Data de abertura:** 08/10/2026  
**Fase:** III — Extração / staging  
**Status:** C4.1/C4.1a PASS (evidência física); C4.2 DISCOVERY DE REFERÊNCIA OFICIAL INICIADA / ARTEFATO HISTÓRICO AINDA NÃO VALIDADO; T29 NÃO AVALIADO

## 1. Fontes e decisões preservadas

Conforme `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/discovery/boundary-4-auxiliary-references.md` e `docs/discovery/boundary-7-implementation-plan.md`:

- **FATO VERIFICADO (staging anterior):** 36 competências de CNES/LT em 2017–2019, com 35.518 registros, disponíveis como `BASE/CONVERTIDA/LT/LTPBYYMM.csv` e `SRC_CNES_LT.qvd`.
- **DECISÃO CONFIRMADA:** a dimensão `DIM_TIPO_LEITO` desnormalizará Tipo de Leito → Leito, sem antecipar a construção dimensional na Extração.
- **DECISÃO PENDENTE:** materializar e comparar referências **oficiais e históricas** de `TP_LEITO` e `CODLEITO` e verificar se descrições/classificações mudaram entre 2017 e 2019.
- **T29:** correspondência `CODLEITO` ↔ referência oficial, com cobertura efetivamente medida e exceções registradas. **Não foi avaliado** nesta etapa.
- A investigação não deve inventar mapeamento, classe, descrição, vigência temporal, chave candidata de dimensão ou relacionamento sem evidência física/oficial.

## 2. C4.1 — Perfil read-only dos códigos reais do CNES/LT

Script implementado: `tools/profile_cnes_lt_bed_codes.py`.

Lê somente os **36 CSVs locais** `BASE/CONVERTIDA/LT/LTPBYYMM.csv`, exige contagem total de **35.518 linhas**, preserva `TP_LEITO` e `CODLEITO` **literalmente como strings** e inspeciona `COMPETEN` em relação à competência do arquivo, sem modificar os valores originais.

Mede, sem deduzir significados ou hierarquias oficiais:

- valores distintos, comprimentos e formatos brutos de `TP_LEITO` e `CODLEITO`;
- pares de códigos observados, ocorrências, primeiro/último mês e competências em que aparecem;
- cardinalidade observada `CODLEITO` → valores `TP_LEITO` (apenas indício empírico de possível ambiguidade, **não** regra de negócio);
- totais e anomalias mensais, códigos vazios e eventuais divergências físicas da competência.

Saídas **locais e ignoradas pelo Git**:

- `BASE/REFERENCIAS/cnes_lt_bed_code_monthly_profile.csv`;
- `BASE/REFERENCIAS/cnes_lt_bed_code_pair_profile.csv`;
- `BASE/REFERENCIAS/cnes_lt_bed_code_profile_summary.json`.

O JSON registra métricas agregadas e SHA-256 dos dois CSVs. O script retorna `VERDICT=PASS` para perfil fisicamente íntegro e `VERDICT=REVIEW` se houver códigos vazios ou competência divergente. **C4.1 PASS não significa T29 PASS.**

### Execução

Na raiz do repositório:

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\profile_cnes_lt_bed_codes.py
```

Conferência de saídas:

```powershell
$m = Get-Content .\BASE\REFERENCIAS\cnes_lt_bed_code_profile_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.status
$m.input
$m.observed_codes
@($m.outputs.monthly, $m.outputs.pairs) | ForEach-Object {
    $actual = (Get-FileHash $_.path -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{
        Path = $_.path
        Rows = $_.rows
        HashMatch = ($actual -eq $_.sha256.ToLowerInvariant())
    }
}
```

## 3. Evidência C4.1 — PASS (08/10/2026)

**FATO VERIFICADO:** a execução real do perfil CNES/LT em 36 competências retornou `VERDICT=PASS`, com **35.518 linhas**, **7 valores brutos distintos de `TP_LEITO`**, **57 valores brutos distintos de `CODLEITO`** e **57 pares brutos distintos**. Não houve `TP_LEITO`/ `CODLEITO` exatamente vazios (`""`) ou registros com competência divergente (`COMPETENCE_MISMATCH_ROWS=0`).

O valor `CODLEITO` possui comprimento 2 e `ASCII_DIGITS` em todos os 35.518 registros. O valor `TP_LEITO` tem comprimento 2 e foi classificado como **`WHITESPACE` em todas as 35.518 linhas**. A categoria `WHITESPACE` no script significa presença de ao menos um caractere de espaço em um valor que não é totalmente numérico/alfanumérico; **não significa que o campo inteiro está em branco**. Ainda não foi demonstrado se há espaço inicial, final ou interno nem se a retirada de preenchimento preserva unicidade.

Não há `CODLEITO` observado associado a dois `TP_LEITO` diferentes (`CODLEITO_MULTIPLE_TP_LEITO=0`), mas isso comprova apenas o comportamento nos arquivos inspecionados, **não a hierarquia normativa nem a chave oficial**.

Padrão mensal: de 201701 a 201712, 56 códigos distintos por mês; de **201801 a 201805, 57**; de 201806 a 201912, 56. O perfil de 57 códigos no total **não demonstra qual código aparece/desaparece, nem se houve mudança oficial de classificação**. Esse dado será inspecionado explicitamente antes da aquisição da referência.

Arquivos locais e hashes SHA-256, verificados pelo usuário (`HashMatch=True`):

| Saída | Registros | SHA-256 |
|---|---:|---|
| `cnes_lt_bed_code_monthly_profile.csv` | 36 | `73ddcfd5cc73342f7c2d75d4565f798b95c92e2fec0edb3f92b5d225fd698c34` |
| `cnes_lt_bed_code_pair_profile.csv` | 57 | `4afe0741b1bf43434192e467a043a0bcb7f2a96e25214f92f47557531e238449` |

### C4.1a — inspeção restrita de espaços, valores e presença histórica (READ-ONLY)

Sem alterar código, dados, chaves ou QVDs, examinar os **57 pares observados** no `cnes_lt_bed_code_pair_profile.csv`. O objetivo é registrar os sete valores brutos de `TP_LEITO`, posições/códigos Unicode de eventuais espaços e as competências do código adicional de 2018.

PowerShell (na raiz do repositório):

```powershell
$p = Import-Csv .\BASE\REFERENCIAS\cnes_lt_bed_code_pair_profile.csv -Delimiter ';'
$p | Group-Object tp_leito_raw | ForEach-Object {
    $raw = $_.Name
    [pscustomobject]@{
        TP_Leito_Visivel = "[$raw]"
        CodigoUnicodePorCaractere = (([char[]]$raw | ForEach-Object { [int][char]$_ }) -join ',')
        CodleitosAssociados = $_.Count
        LinhasLT = ($_.Group | Measure-Object -Property occurrences -Sum).Sum
    }
} | Format-Table -AutoSize

$p | Where-Object { [int]$_.competences_observed -lt 36 } |
Select-Object tp_leito_raw, codleito_raw, first_competence,
    last_competence, competences_observed, occurrences |
Format-Table -AutoSize
```

A lista de pares com menos de 36 competências **não prova isoladamente** qual par foi exclusivo de janeiro–maio de 2018, pois podem existir lacunas intermediárias. Se necessário, comparar o conjunto de códigos dos CSVs `LTPB1712.csv`, `LTPB1801.csv`, `LTPB1805.csv` e `LTPB1806.csv` para apontar o código exato antes de formular hipóteses de vigência.

**Gate C4.1a:** obter caracteres físicos e códigos reais sem normalização, além das diferenças efetivas entre competências relevantes. Nenhuma decisão de `Trim()`, `Text()`, `Num()` ou chave oficial está autorizada por este perfil.

### Resultado C4.1a — PASS na inspeção física restrita (08/10/2026)

**FATO VERIFICADO (PowerShell sobre os arquivos locais):** os sete valores brutos de `TP_LEITO` são `"1 "`, `"2 "`, `"3 "`, `"4 "`, `"5 "`, `"6 "`, `"7 "`. Em todos, os códigos Unicode são respectivamente **49–55 no primeiro caractere e 32 (espaço ASCII) no segundo**. O espaço é **trailing**, não inicial nem interno. A distribuição observada de códigos `CODLEITO` associados a esses tipos no perfil de 57 pares foi:

| `TP_LEITO` bruto | Códigos `CODLEITO` associados |
|---|---:|
| `"1 "` | 15 |
| `"2 "` | 13 |
| `"3 "` | 16 |
| `"4 "` | 2 |
| `"5 "` | 2 |
| `"6 "` | 5 |
| `"7 "` | 4 |
| **Total** | **57** |

**FATO VERIFICADO:** comparação dos conjuntos de `CODLEITO` entre dezembro/2017 e janeiro/2018 apresentou apenas `70` do lado de **janeiro/2018** (`=>`). Entre maio/2018 e junho/2018, apresentou apenas `70` do lado de **maio/2018** (`<=`). Isso explica as transições de 56 para 57 e de 57 para 56 códigos.

**Limite da evidência:** as duas comparações não comprovam, por si só, presença/ausência de `70` em **cada um** dos 36 meses, nem seu `TP_LEITO` específico, descrição oficial ou data normativa de inclusão/exclusão. Essas informações continuam pendentes de verificação. Não normalizar o campo no CSV original; qualquer `RTrim()` em futuras chaves deverá ser documentado e testado explicitamente.

**C4.1a: PASS** quanto à posição dos espaços e às duas transições comparadas. **T29 continua NÃO AVALIADO.**

### Fontes públicas oficiais localizadas para C4.2 (apenas descoberta)

- [Portal CNES — Downloads > Documentação](https://cnes.datasus.gov.br/pages/downloads/documentacao.jsp): seção **Dicionário de Dados do SCNES** e **Tabelas de Domínio**, candidatas prioritárias à identificação oficial de códigos, tipos e descrições. A listagem HTML pública usa dados carregados dinamicamente; não foi possível validar pelo texto disponível uma URL estática e uma versão histórica exata dos anexos.
- [Wiki CNES — Portal CNES](https://wiki.saude.gov.br/cnes/index.php/Portal_CNES): informa que o download da base CNES por competência está disponível a partir de **06/2017**. A disponibilidade da base mensal **não comprova**, isoladamente, a existência de tabelas de domínio versionadas para cada competência.
- [ElastiCNES — Leitos](https://wiki.datasus.gov.br/cnes/index.php/Pain%C3%A9is_ElastiCNES): documentação oficial distingue **tipo de leito**, **código de leito**, **leito/especialidade**, leitos existentes e leitos SUS, e apresenta filtros por ano/competência.
- [OpenDataSUS — Hospitais e Leitos](https://opendatasus.saude.gov.br/pt_BR/dataset/hospitais-e-leitos): catálogo público indexado com recursos CSV anuais para **2017, 2018 e 2019**. É fonte de dados operacionais candidata à **checagem cruzada**, mas **não foi validada como tabela normativa histórica de domínio**. O portal antigo atualmente redireciona para nova plataforma, exigindo descoberta do recurso atual.

**DECISÃO PENDENTE C4.2:** localizar e inspecionar a **tabela de domínio oficial do CNES**, com código, descrição, grupo e versão/data aplicável. Atribuir `CODLEITO=70` a uma descrição, especialidade ou `TP_LEITO` exige confrontar o par observado no LT e a fonte oficial (possivelmente histórica). Não converter uma publicação atual ou secundária automaticamente em versão 2017–2019.

**Próxima inspeção read-only opcional, sem scripts adicionais:**

```powershell
$p = Import-Csv .\BASE\REFERENCIAS\cnes_lt_bed_code_pair_profile.csv -Delimiter ';'
$p | Where-Object { $_.codleito_raw -eq '70' } |
    Select-Object tp_leito_raw,codleito_raw,first_competence,last_competence,competences_observed,occurrences |
    Format-Table -AutoSize

2017..2019 | ForEach-Object {
    $y = $_
    1..12 | ForEach-Object {
        $m = '{0:D2}' -f $_
        $ym = '{0}{1}' -f $y,$m
        $csv = ".\BASE\CONVERTIDA\LT\LTPB$($y.ToString().Substring(2))$m.csv"
        $matches = @(Import-Csv $csv -Delimiter ';' | Where-Object { $_.CODLEITO -eq '70' })
        if($matches.Count -gt 0) {
            [pscustomobject]@{
                Competencia=$ym; Linhas70=$matches.Count;
                Tipos=($matches | Select-Object -ExpandProperty TP_LEITO -Unique) -join ','
            }
        }
    }
} | Format-Table -AutoSize
```

## 4. Gate seguinte — C4.2 referência oficial

Somente **após avaliar o resultado real de C4.1**:

1. confirmar as fontes oficiais aplicáveis de `TP_LEITO`/`CODLEITO`, seu esquema de arquivo e disponibilidade histórica 2017–2019;
2. identificar códigos/descrições reais e potencial mudança de classificação por competência;
3. materializar ou validar amostra controlada da referência, com fonte, versão, campos e hashes comprovados;
4. medir T29 sobre 35.518 linhas CNES/LT **por competência quando a referência assim exigir**, documentando exceções;
5. só então avaliar `REF_TIPO_LEITO.qvd` na extração QlikView 12.

A Fase III permanece `IN PROGRESS`. Não modificar os fatos/dimensões, arquivos acadêmicos aprovados ou dados de origem nesta etapa.
