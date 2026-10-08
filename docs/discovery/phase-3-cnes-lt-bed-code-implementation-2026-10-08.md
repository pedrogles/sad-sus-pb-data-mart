# Fase III-C4 — Referência CNES tipo/leito (T29)

**Projeto:** SAD — Data Mart SUS PB  
**Data de abertura:** 08/10/2026  
**Fase:** III — Extração / staging  
**Status:** C4.1/C4.1a PASS; C4.2a código 70 validado; C4.2b.1 capturas 5/5; C4.2b.2 integridade PASS; C4.2b.3 comparação de 77 linhas/competência PASS estrutural e diferenças quantitativas observadas; C4.2b.3a isolamento de código/descrição IMPLEMENTADO / EXECUÇÃO LOCAL PENDENTE; domínio histórico NÃO VALIDADO; T29 NÃO AVALIADO

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

**DECISÃO PENDENTE C4.2:** localizar e inspecionar a **tabela de domínio oficial do CNES**, com código, descrição, grupo e versão/data aplicável. O mapeamento pontual `CODLEITO=70` → `FIBROSE CISTICA` / `HOSPITAL DIA` foi agora confirmado em consulta oficial com competência 201712 e confrontado com o par observado no LT (`TP_LEITO="7 "`). Isso **não** fecha a aquisição normativa dos 57 códigos nem autoriza atribuir versões mensais inexistentes; conferir o gate C4.2b acima.

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

### Evidência complementar C4.2a — código `70` e fonte oficial de 2017

**FATO VERIFICADO — perfil CNES/LT da Paraíba fornecido pelo usuário em 08/10/2026:** a linha filtrada do `cnes_lt_bed_code_pair_profile.csv` para `CODLEITO=70` trouxe `tp_leito_raw="7 "`, `first_competence=201801`, `last_competence=201805`, `competences_observed=5` e `occurrences=5`. Associada à variação mensal previamente inspecionada (57 códigos de janeiro a maio, 56 nos outros meses), sustenta que o par apareceu uma vez em cada mês de janeiro–maio de 2018. Não identifica, por si, quantidades de leitos SUS nem a vigência da classificação normativa.

**FATO VERIFICADO — fonte primária DATASUS/CNES:** a própria consulta oficial de indicadores do CNES apresenta o código `70` com a descrição **`FIBROSE CISTICA`** dentro do grupo **`HOSPITAL DIA`**; o grupo corresponde ao `TP_LEITO=7` na nomenclatura CNES. Foram encontradas consultas oficiais indexadas com competências **201512** e **201712**, ambas para **São Paulo (UF 35)**, contendo esse par:

- [CNES oficial — indicadores de leitos, competência 201712, UF 35](https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VComp=201712&VEstado=35&VMun=);
- [CNES oficial — indicadores de leitos, competência 201512, UF 35](https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VComp=201512&VEstado=35&VMun=);
- [CNES oficial — consulta de leitos (visão atual)](https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VEstado=00).

**INTERPRETAÇÃO CONTROLADA:** a presença de `70 / FIBROSE CISTICA / HOSPITAL DIA` na consulta CNES da competência **201712 em outra UF** comprova que esse código/descritivo já era utilizado pelo CNES antes da primeira ocorrência no recorte **PB em 201801**. **Não** interpretar entrada/saída do recorte PB como criação ou extinção oficial do domínio. A consulta comprova a nomenclatura oficial do código na competência exibida, mas **não** constitui extração/versão consolidada de tabela de domínio para as 36 competências e 57 códigos do projeto.

O material secundário do [CONASS — Tabela de domínio CNES leito](https://wiki.conass.org.br/index.php?title=Tabela_de_dom%C3%ADnio_CNES_leito) também contém `tp_leito=7`, `codleito=70` e `no_leito=fibrose cistica`. Serve como confirmação cruzada, **não substitui** a fonte primária ou versão histórica para T29.

**C4.2a — referência pontual `70`: COMPROVADA** quanto à descrição/grupo oficial e à existência pré-2018 em consulta oficial. **C4.2b — domínio completo e histórico: PENDENTE. T29: NÃO AVALIADO.**

### Próximo gate C4.2b — domínio histórico de leitos, sem inferir vigência

1. Identificar arquivo ou consulta oficial com os códigos/descrições de todos os **57 `CODLEITO`** e correspondentes sete tipos, contendo evidência de versão/competência utilizável em 2017–2019;
2. inspecionar fisicamente colunas/formatos e provar unicidade do par de código/tipo em cada referência, preservando os códigos de dois caracteres e o espaço de preenchimento de `TP_LEITO` na origem;
3. conferir alterações de descrição ou classificação entre competências; na ausência de arquivo normativo versionado, documentar explicitamente a limitação temporal e evitar supor um catálogo mensal;
4. somente após montar e provar a referência oficial, medir a cobertura T29 de **35.518 linhas CNES/LT**, registrar exceções e então considerar `REF_TIPO_LEITO.qvd`.

### C4.2b.1 — sondagem controlada dos indicadores históricos oficiais (IMPLEMENTADA / LOCAL PENDENTE)

**FATOS VERIFICADOS NA DESCOBERTA WEB:**

- O [CNES oficial — consulta nacional de leitos](https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VEstado=00) lista grupos, códigos, descrições e totais existentes/SUS, mas só expõe especialidades com valores registrados na consulta selecionada; **não é catálogo normativo exaustivo**.
- A [consulta oficial CNES de 201712 / SP](https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VComp=201712&VEstado=35&VMun=) e a [consulta de 201910 / CE](https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VComp=201910&VEstado=23&VMun=) demonstram existência de **páginas de indicadores por competência**, mas **não demonstram que o servidor atualmente responda a qualquer competência solicitada**; a execução local precisa testar HTTP, conteúdo e eventual seleção de competência.
- A [tabela de domínio CNES leito do CONASS](https://wiki.conass.org.br/index.php?title=Tabela_de_dom%C3%ADnio_CNES_leito) apresenta pares repetidos de `codleito` em diferentes `tp_leito` (ex.: `01` e `02` aparecem associados a tipos diferentes). **É evidência secundária de risco de colisão**, mas não equivale à prova de chaves/cardinalidades do domínio oficial de 2017–2019. Consequentemente, **não aprovar `CODLEITO` isolado como chave universal de descrição**.
- O [portal oficial de documentação CNES](https://cnes.datasus.gov.br/pages/downloads/documentacao.jsp) anuncia `Tabelas de Domínio` e `Dicionário de Dados do SCNES`; o HTML público observado contém templates JavaScript e não disponibiliza URL do arquivo ou versão histórica verificável em leitura simples.

**Implementação de discovery:** `tools/probe_cnes_leito_historical_indicators.py`, sem dependências além da biblioteca padrão Python.

A sonda consulta **somente cinco** combinações `VComp` (`201712`, `201801`, `201805`, `201806`, `201912`) com `VEstado=00` e `VMun` vazio no domínio oficial `cnes2.datasus.gov.br`. Em cada requisição, limite 2 MB / timeout 18 s, redirecionamento restrito ao host, tipo de conteúdo HTML e HTTP 200. Grava **apenas cópias brutas desses cinco HTMLs oficiais, se acessíveis**, e manifest JSON com SHA-256, tamanho, URL, charset e sinais de página; tudo em `BASE/REFERENCIAS/cnes_leito_history_probe/` (ignorado pelo Git).

A inspeção da página é **heurística/não normativa**: presença de indicadores/leitos, grupo `HOSPITAL DIA`, código `70 FIBROSE CISTICA` e `VComp` possivelmente selecionada. Se a página não expuser competência selecionada, esse atributo será marcado falso — **não assumir que o retorno é realmente daquela competência**. O script não extrai a tabela como verdade dimensional, não converte códigos e não calcula T29. Um HTTP 200 isolado não aprova a validade histórica.

**Executar no PowerShell**, a partir da raiz do repositório:

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\probe_cnes_leito_historical_indicators.py
```

Conferência read-only dos artefatos locais:

```powershell
$m = Get-Content .\BASE\REFERENCIAS\cnes_leito_history_probe\probe_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.sources | Select-Object requested_competence, status, bytes, decoded_using,
    @{Name='SelectedCompetence';Expression={$_.inspection.page_signals.requested_competence_selected}},
    @{Name='HospitalDia';Expression={$_.inspection.page_signals.grupo_hospital_dia}},
    @{Name='Error';Expression={$_.error}} | Format-Table -AutoSize
```

**Critério de interpretação:** respostas confiáveis somente após inspecionar conteúdo original/seleção de competência. Ainda que todos os cinco HTMLs sejam válidos, o resultado será apenas um **piloto de fontes históricas**, e não catálogo oficial de 57 códigos ou série de 36 meses.

**DECISÕES PENDENTES PARA C4.2b:** encontrar tabela de domínio oficial versionada ou estabelecer alternativa transparente se ela não existir; definir tratamento de histórico e chave descritiva com evidência de pares `TP_LEITO+CODLEITO`; medir T29 sobre os 35.518 LT apenas após validação oficial do domínio.

### C4.2b.1 — execução local em 08/10/2026: 5 HTMLs capturados, competência não comprovada

**FATO VERIFICADO:** o usuário executou `tools/probe_cnes_leito_historical_indicators.py` após atualização de `main`. Foram capturados **5/5 HTMLs** oficiais (competências solicitadas 201712, 201801, 201805, 201806, 201912), com as seguintes saídas:

| Solicitada | Bytes capturados | Decodificação | Indicadores/leitos | Hospital Dia | Código 70 | Competência selecionada |
|---|---:|---|---|---|---|---|
| 201712 | 53.009 | cp1252 | Sim | Sim | Sim | **Não confirmada** |
| 201801 | 53.008 | cp1252 | Sim | Sim | Sim | **Não confirmada** |
| 201805 | 53.007 | cp1252 | Sim | Sim | Sim | **Não confirmada** |
| 201806 | 53.006 | cp1252 | Sim | Sim | Sim | **Não confirmada** |
| 201912 | 53.008 | cp1252 | Sim | Sim | Sim | **Não confirmada** |

O manifesto declarou `HISTORICAL_DOMAIN_REFERENCE=NOT_APPROVED`, `T29_COVERAGE=NOT_EVALUATED`, `VERDICT=SOURCE_INSPECTION_REQUIRED`. O marcador `COMPETENCE_SELECTED=False` em 5/5 pode decorrer da forma como a página expõe controles ou do retorno de competência padrão. **Não permite afirmar** que o portal ignora os parâmetros; tampouco permite afirmar que as cinco páginas representam períodos históricos corretos. As diferenças de **1–3 bytes** não provam alteração de classificação ou conteúdo.

**C4.2b.1: CAPTURA CONCLUÍDA, INTERPRETAÇÃO HISTÓRICA AINDA EM REVIEW.** É inadequado criar `REF_TIPO_LEITO`, atribuir validade mensal ou executar T29 com base nos cinco HTMLs apenas.

### C4.2b.2 — auditoria diferencial offline (IMPLEMENTADA / EXECUÇÃO LOCAL PENDENTE)

Para isolar variação de template/HTML de alteração real do conteúdo, foi adicionado `tools/audit_cnes_leito_historical_html.py`. O script **não usa rede**: relê os cinco HTMLs existentes e o manifesto, confere hashes/tamanhos, decodifica com o encoding registrado, procura `<select>`/`<input>` de competência e compara três assinaturas SHA-256 distintas:

- **bytes HTML** (inclui template, seleção, códigos, formatação etc.);
- **texto visível normalizado** (pode incluir listas de meses ou cabeçalhos);
- **conteúdo textual a partir do grupo CIRÚRGICO** (aproximação de corpo de indicadores; não é extração normativa validada).

Os três fingerprints serão interpretados em conjunto. `HTML_SHA` diferente com `BED_SHA` idêntico é evidência de **diferença fora do corpo indicado**, mas não demonstra validade histórica. `BED_SHA` diferente exige comparação semântica dos grupos/linhas e prova da competência. Em qualquer cenário, `COMPETENCE_SELECTED` não identificado **não é prova automática** de parâmetro ignorado.

Comando (raiz do repositório):

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\audit_cnes_leito_historical_html.py
```

Resumo local não versionado: `BASE/REFERENCIAS/cnes_leito_history_probe/html_diff_audit_summary.json`. Para inspecionar os sinais:

```powershell
$m = Get-Content .\BASE\REFERENCIAS\cnes_leito_history_probe\html_diff_audit_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m | Select-Object status, captured_samples_verified, integrity_failures, distinct_html_hashes, distinct_visible_text_hashes, distinct_bed_content_hashes, competences_explicitly_confirmed
$m.records | Select-Object competence, manifest_hash_match, requested_competence_present_in_html, competence_explicitly_confirmed, selected_competence_values, competence_input_values, bed_content_start_found, bed_content_sha256 | Format-Table -AutoSize
```

**DECISÃO PENDENTE:** após essa conferência, determinar se a fonte é confiável para uma descrição histórica amostral ou se precisamos localizar a versão oficial do **Dicionário de Dados/Tabelas de Domínio** por outra rota. **Não** presumir que consultas de indicador componham domínio completo de 57 códigos nem que `CODLEITO` isolado seja chave normativa.

### C4.2b.2 — auditoria diferencial executada: integridade PASS / interpretação histórica REVIEW (08/10/2026)

**FATO VERIFICADO — execução Python local:** cinco HTMLs foram reabertos e seus hashes/tamanhos reconciliados com o manifesto original (`VERIFIED_HTML=5`, `INTEGRITY_FAILURES=0`, `manifest_hash_match=True` para os cinco arquivos). A auditoria obteve:

```text
DISTINCT_HTML_HASHES=5
DISTINCT_VISIBLE_TEXT_HASHES=5
DISTINCT_BED_CONTENT_HASHES=5
EXPLICIT_COMPETENCES=0
VERDICT=HTML_COMPARISON_REVIEW_REQUIRED
T29_COVERAGE=NOT_EVALUATED
```

Cada HTML contém o valor `YYYYMM` solicitado em algum ponto (`requested_competence_present_in_html=True`), mas **nenhum** o comprovou como seleção efetiva nos controles `<select>`/`<input>`. Cinco hashes de corpo diferentes comprovam apenas diferenças no trecho textual adotado pela heurística que começa em `CIRÚRGICO`. Esse trecho **não foi demonstrado ser exclusivamente uma tabela de domínio** e pode conter competência solicitada, contagens operacionais ou elementos do template.

**Gate de integridade da captura: PASS. Gate de interpretação temporal/normativa: REVIEW.** Não há base para declarar cinco versões de domínio distintas, nem para concluir que o portal ignorou `VComp`.

### C4.2b.3 — comparador offline de linhas de tabelas HTML (IMPLEMENTADO / EXECUÇÃO LOCAL PENDENTE)

Script: `tools/compare_cnes_leito_html_table_rows.py`. Lê somente os cinco HTMLs já capturados e revalida integridade de bytes/tamanho contra `probe_summary.json`. Por competência, enumera linhas HTML `<tr>` e células `<td>`/`<th>`, com texto normalizado para fins de comparação (sem gerar referência nem reformatar arquivos originais). Registra:

- quantidade de linhas de tabela capturadas por página e SHA-256 derivado dessas linhas;
- ocorrências da competência solicitada e das outras quatro competências no HTML bruto (um eco do parâmetro sozinho não confirma filtro aplicado);
- exemplos pontuais de linha do código `70`, quando puder identificá-la na estrutura;
- comparação diferencial dos pares 201712→201801, 201801→201805, 201805→201806 e 201806→201912, mostrando linhas iguais/alteradas e até 12 exemplos de grupos de alteração;
- comparação **exploratória** que substitui somente os cinco valores `YYYYMM` solicitados por marcador comum, para testar se as diferenças são explicadas por ecos explícitos dos meses. Isso **não** prova equivalência semântica nem identifica automaticamente vigência histórica.

Saída JSON local (ignorada no Git): `BASE/REFERENCIAS/cnes_leito_history_probe/table_row_diff_summary.json`.

Execução:

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\compare_cnes_leito_html_table_rows.py
```

Consulta resumida:

```powershell
$m = Get-Content .\BASE\REFERENCIAS\cnes_leito_history_probe\table_row_diff_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.captured_htmls | Select-Object competence_requested, table_rows, code70_row_count
$m.comparisons | ForEach-Object {
    [pscustomobject]@{
        Transicao = "$($_.from_competence_requested)->$($_.to_competence_requested)"
        Iguais = $_.raw_table_diff.equal_rows
        Alteradas = $_.raw_table_diff.replace_rows + $_.raw_table_diff.insert_rows + $_.raw_table_diff.delete_rows
        AlteradasSemEcoMes = $_.month_echo_neutralized_exploratory_diff.replace_rows + $_.month_echo_neutralized_exploratory_diff.insert_rows + $_.month_echo_neutralized_exploratory_diff.delete_rows
    }
} | Format-Table -AutoSize
$m.comparisons[0].raw_table_diff.diff_examples | ConvertTo-Json -Depth 6
```

**Limites:** o extrator HTML é uma sonda estrutural, não um parser oficial de domínios; diferenças em linhas podem ser apenas de indicadores quantitativos por competência. A prova de `VComp` e o catálogo normativo completo continuam pendentes. **T29 não executado.**

### C4.2b.3 — resultado local: linhas comparadas, interpretação normativa ainda REVIEW (08/10/2026)

**FATO VERIFICADO:** o usuário atualizou `main` e executou `tools/compare_cnes_leito_html_table_rows.py` com êxito. O script reconferiu a integridade das **cinco capturas** e extraiu **77 linhas de tabela por HTML**, identificando **uma linha de `70 FIBROSE CISTICA` em cada**. Contagens das diferenças entre linhas HTML:

| Transição solicitada | Linhas iguais | Linhas diferentes | Linhas diferentes após neutralizar eco YYYYMM |
|---|---:|---:|---:|
| 201712→201801 | 12 | 65 | 65 |
| 201801→201805 | 10 | 67 | 67 |
| 201805→201806 | 16 | 61 | 61 |
| 201806→201912 | 9 | 68 | 68 |

A diferença persistiu após neutralização limitada de textos `YYYYMM`. Nos **exemplos** inspecionados, as duas primeiras células contêm mesmo código e descrição entre consultas, enquanto as células seguintes exibem números diferentes. Exemplos entre 201712 e 201801: `01 BUCO MAXILO FACIAL 1176/722 → 1167/718`, `02 CARDIOLOGIA 5260/3042 → 5279/3051`, `10 OBSTETRICIA CIRURGICA 27793/19373 → 27741/19354`.

**Limite:** os exemplos não provam estabilidade de código/descrição nas **77 linhas** ou associação com os sete tipos, pois o comparador anterior tratava cada `<tr>` inteiro como uma unidade. As mudanças numéricas são **compatíveis com variações operacionais dos indicadores**, mas a seleção explícita de `VComp` não foi demonstrada (`EXPLICIT_COMPETENCES=0` anteriormente). Não concluir que cinco versões normativas diferem nem que não há mudanças de catálogo em outros meses.

O script original registrou `VERDICT=SEMANTIC_INSPECTION_REQUIRED`, `OFFICIAL_DOMAIN=NOT_APPROVED` e `T29_COVERAGE=NOT_EVALUATED`. **C4.2b.3: análise estrutural executada com integridade PASS; evidência semântica insuficiente para aprovar domínio histórico.**

### C4.2b.3a — separar código/descrição de valores numéricos (IMPLEMENTADO / REEXECUÇÃO PENDENTE)

Foi estendido o script **existente** `tools/compare_cnes_leito_html_table_rows.py`, sem nova aquisição, novo diretório ou nova fonte. Ele continua auditando os SHA-256 de todos os HTMLs antes da leitura e agora:

- seleciona apenas linhas com **primeira célula contendo exatamente dois dígitos** e segunda célula não vazia, mantendo `(código, descrição)` sem presumir que seja uma chave normativa;
- calcula o SHA-256 do **multiconjunto ordenado** dos pares por HTML, preservando repetições;
- compara a quantidade de pares adicionados/removidos entre competências solicitadas; registra até doze exemplos de cada;
- distingue linhas com os **mesmos código/descrição nas duas primeiras células** nas quais **outras células** variaram (prováveis valores numéricos);
- registra também se um código aparece mais de uma vez na mesma página.

**Limitação crítica:** cabeçalhos de grupo/tipo com apenas uma célula não são preservados no extrator atual. Portanto, identidade `(código, descrição)` estável **não comprova tipo de leito, chave composta, vigência normativa, nem cobertura dos 57 códigos observados na PB**. A consulta é um indicador, não o catálogo oficial completo.

Comandos locais, na raiz do repositório:

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\compare_cnes_leito_html_table_rows.py
```

```powershell
$m = Get-Content .\BASE\REFERENCIAS\cnes_leito_history_probe\table_row_diff_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.captured_htmls | Select-Object competence_requested,table_rows,code_description_candidates,code_description_distinct_pairs,duplicate_code_values_in_table,code_description_multiset_sha256 | Format-Table -AutoSize
$m.comparisons | ForEach-Object {
    $d = $_.classification_code_description_diff
    [pscustomobject]@{
        Transicao = "$($_.from_competence_requested)->$($_.to_competence_requested)"
        ParesAdicionados = $d.added_occurrences
        ParesRemovidos = $d.removed_occurrences
        MesmoRotuloNaPosicao = $d.same_labels_at_same_row_positions
        AlteracoesOutrasCelulasMesmoRotulo = $d.numeric_or_other_cells_changed_at_same_label_positions
    }
} | Format-Table -AutoSize
```

**Gate:** decidir apenas se os pares `código/descrição` exibidos no **indicador oficial** permaneceram estáveis nas cinco capturas. A futura origem normativa (Tabelas de Domínio SCNES) e T29 permanecem **PENDENTES**; nenhuma alteração do QlikView/CSV LT foi autorizada.

## 4. Gate seguinte — C4.2 referência oficial

Somente **após avaliar o resultado real de C4.1**:

1. confirmar as fontes oficiais aplicáveis de `TP_LEITO`/`CODLEITO`, seu esquema de arquivo e disponibilidade histórica 2017–2019;
2. identificar códigos/descrições reais e potencial mudança de classificação por competência;
3. materializar ou validar amostra controlada da referência, com fonte, versão, campos e hashes comprovados;
4. medir T29 sobre 35.518 linhas CNES/LT **por competência quando a referência assim exigir**, documentando exceções;
5. só então avaliar `REF_TIPO_LEITO.qvd` na extração QlikView 12.

A Fase III permanece `IN PROGRESS`. Não modificar os fatos/dimensões, arquivos acadêmicos aprovados ou dados de origem nesta etapa.
