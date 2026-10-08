# Fase III-C4 — Referência CNES tipo/leito (T29)

**Projeto:** SAD — Data Mart SUS PB  
**Data de abertura:** 08/10/2026  
**Fase:** III — Extração / staging  
**Status:** C4.1/C4.1a PASS; C4.2a código 70 validado; C4.2b.1–3a PASS amostral com ressalvas; C4.2c DOCUMENTOS CNES RECEBIDOS / ESTRUTURAS E HASHES VERIFICADOS; C4.2c.1 COBERTURA INDEPENDENTE PASS PROVISÓRIO (57/57 pares, 35.518/35.518 registros); C4.2c.2e PASS DE COBERTURA DO RETRATO NORMATIVO SET/2019 (57/57 PARES, 35.518/35.518 LINHAS); VIGÊNCIA HISTÓRICA 2017–2019 PENDENTE; T29 INTEGRAL NÃO APROVADO

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

### C4.2b.3a — resultado executado: estabilidade amostral de pares código/descrição (08/10/2026)

**FATO VERIFICADO (execução local apresentada pelo usuário):** depois de `git pull origin main`, o script `tools/compare_cnes_leito_html_table_rows.py` confirmou integridade dos cinco HTMLs, **77 linhas de tabela e uma linha de código 70 por página**. Para cada uma das cinco competências **solicitadas**, extraiu **65 pares distintos `(código, descrição)`**, sem valores de código repetidos **nessas linhas filtradas**.

| Transição solicitada | Pares adicionados | Pares removidos | Linhas com o mesmo rótulo em mesma posição | Outras células diferentes nesses rótulos |
|---|---:|---:|---:|---:|
| 201712 → 201801 | 0 | 0 | 73 | 61 |
| 201801 → 201805 | 0 | 0 | 73 | 63 |
| 201805 → 201806 | 0 | 0 | 74 | 58 |
| 201806 → 201912 | 0 | 0 | 73 | 64 |

**PASS AMOSTRAL DE ESTABILIDADE DOS RÓTULOS:** as quatro diferenças de multiconjuntos de `(código, descrição)` foram nulas entre capturas. Entretanto, **não** significa validação de competência selecionada (0/5 controles anteriormente confirmados), de hierarquia `TP_LEITO`, de chave global de descrição, nem de domínio exaustivo para 2017–2019. O filtro estrutural usa apenas primeira célula com dois dígitos e segunda célula textual, descartando contexto de grupo/tipo. O HTML mostra indicadores e contagens, não tabela oficial de domínio com versionamento demonstrado.

**T29: NÃO AVALIADO**, pois falta reconciliar cada um dos **57 pares `TP_LEITO/CODLEITO` observados** nos 35.518 registros CNES/LT contra fonte oficial aprovada. Não materializar `REF_TIPO_LEITO.qvd` nesta etapa.

### C4.2c — aquisição assistida do documento oficial CNES (próximo gate)

A [documentação do Portal CNES](https://cnes.datasus.gov.br/pages/downloads/documentacao.jsp) anuncia **`Dicionário de Dados do SCNES`** e **`Tabelas de Domínio`**, mas seu HTML público apresenta placeholders como `{{scnesTabelasDominio.dtAtualizacao}}`; portanto **nenhum link direto ou versão de 2017–2019 foi comprovado nesta descoberta**. O [guia oficial do CNES sobre conceitos de leitos](https://wiki.saude.gov.br/cnes/index.php/Principais_Conceitos) explicita a separação tipo/detalhamento e existente/SUS. A tabela [CONASS — domínio CNES leito](https://wiki.conass.org.br/index.php?title=Tabela_de_dom%C3%ADnio_CNES_leito) é candidata a comparação **secundária** e inclui códigos reaproveitados entre tipos; **não substituir a referência primária pela secundária**.

**Ação local solicitada, sem alterar o repositório:** no navegador, acessar o Portal CNES → Downloads → Documentação e tentar baixar o arquivo disponível sob **Tabelas de Domínio**. Idealmente baixar também o **Dicionário de Dados do SCNES**. Preservar nome original, formato, data/versão informada e URL concreta de cada arquivo, sem alterar conteúdo ou atribuir competência histórica. Disponibilizar o(s) arquivo(s) para inspeção. Se o portal falhar ou mostrar apenas versão atual, registrar esse bloqueio em vez de inferir URLs.

**Gate seguinte após arquivo real:** identificar dentro do documento uma tabela de leitos com os quatro atributos efetivamente existentes (nome do tipo, código do tipo, código do leito e descrição conforme a fonte), inspecionar data/versão, provar cardinalidade e existência dos 57 pares observados, investigar o código `70`, **antes** de definir estratégia de temporalidade ou executar T29. Se só houver documento atual, a aplicabilidade retroativa a 2017–2019 continua uma **DECISÃO PENDENTE**.

**Sem mudanças em** `EXTRACAO/ext_main.qvs`, QVDs, arquivos de origem, modelos dimensional/normalizado ou requisitos acadêmicos nesta rodada.

### C4.2c — dois artefatos CNES fornecidos pelo usuário e inspecionados (08/10/2026)

**FATO VERIFICADO — fonte recebida:** os anexos foram fornecidos pelo usuário após solicitação do Portal CNES. Não foi documentada uma URL direta dos arquivos nem um número formal de versão normativa. **Não versionar os binários recebidos**, nem considerar seus metadados de criação/edição como vigência dos códigos.

| Original | Tamanho | SHA-256 | Metadados internos |
|---|---:|---|---|
| `SCNES_DOMINIOS.XLS` | 1.339.918 bytes | `ae3f678f1f2307d759412c735f79bf1ace5a91410261f4050dc6e86c671c2af4` | formato interno OOXML ZIP/Excel 2007+ apesar da extensão `.XLS`; criado `2019-10-15T20:05:02Z`, modificado `2019-10-15T20:06:58Z` |
| `DICIONARIO_DE_DADOS.docx` | 611.303 bytes | `086bfcbdbf47ea13d89542a21128c691367c0560a9f6bf8a2319e8a6eadb973b` | criado `2013-10-10T20:23:00Z`, modificado `2026-01-15T14:20:00Z`; **não implica** versão histórica aplicável a 2017–2019 |

**FATO VERIFICADO — planilha `SCNES_DOMINIOS.XLS`:**

- possui **56 abas**; as relevantes ao recorte são `LEITOS` e `TIPOS DE LEITOS`;
- aba `LEITOS`: colunas **`LEITO`**, **`DESCRIÇÃO`**; **66 códigos de dois dígitos**, únicos, sem descrições vazias. Exemplo: `70 → FIBROSE CISTICA`;
- aba `TIPOS DE LEITOS`: colunas **`TIPO DE LEITO`**, **`DESCRIÇÃO`**; **7 tipos de um dígito**, únicos, sem descrições vazias. Exemplo: `7 → HOSPITAL DIA`;
- **as duas abas NÃO fornecem uma coluna de associação `TP_LEITO` para cada `LEITO`**; não é possível inferir o tipo do código `70` exclusivamente a partir da planilha. O tipo `7` para `70` foi comprovado previamente por fonte oficial histórica pontual e nos arquivos PB, não pela associação física nessa planilha.

**FATO VERIFICADO — dicionário de dados CNES:**

- `LFCES002 / RL_ESTAB_COMPLEMENTAR` registra `COD_LEITO → CO_LEITO`, `CODTPLEITO → CO_TIPO_LEITO`, `QTDE_EXIST → QT_EXIST` e `QTDE_SUS → QT_SUS`, com referências aos cadastros `NFCES001` e `NFCES028` (tabela de leitos hospitalares, página 6);
- `NFCES001 / TB_LEITO` contém `CO_LEITO` (código), `DS_LEITO` (descrição) e `TP_LEITO` (tipo via `IND_LEITO`, referenciando `NFCES028` com `COD_IND='006'`);
- `NFCES028 / TB_ATRIBUTO` caracteriza códigos `CO_INDICADOR`, `CO_ATRIBUTO`, `DS_ATRIBUTO`, com `006 = Tipos de Leitos`.

**Interpretação restrita:** o dicionário documenta uma relação de tipo de leito no esquema federal, mas o arquivo tabular de domínio recebido expõe **listas independentes** de leitos e tipos. Consequentemente, uma simples correspondência de código e de tipo em abas separadas **não valida a relação `TP_LEITO+CODLEITO`**, não comprova estabilidade de descrição em 2017–2019 nem aprova a dimensão.

### C4.2c.1 — auditoria local dos 57 pares CNES/LT contra listas oficiais recebidas (IMPLEMENTADA / EXECUÇÃO PENDENTE)

Script novo: `tools/audit_cnes_official_domains.py`. Somente biblioteca padrão Python, leitura **read-only** do arquivo OOXML com extensão `.XLS` e do perfil já validado `cnes_lt_bed_code_pair_profile.csv`.

O script compara os códigos observados com a aba `LEITOS`, e os tipos observados com a aba `TIPOS DE LEITOS`, **em avaliações independentes**. Na comparação de tipos, remove **somente o espaço ASCII final** dos códigos brutos `"1 "`…`"7 "`, preservando-os no relatório e nos CSVs de origem. Exige estrutura esperada **66 códigos / 7 tipos** e confronta **57 pares / 35.518 ocorrências**, registrando exceções e hash SHA-256.

A saída `BASE/REFERENCIAS/cnes_domain_code_coverage_audit.json` é apenas **auditoria de cobertura de listas** e nunca contém associação oficial código-tipo já aprovada, tampouco referência histórica por competência. Mesmo um resultado `CODE_AND_TYPE_COVERAGE_PROVISIONAL` **NÃO equivale a T29 PASS**.

Execução no PowerShell, na raiz do repositório, depois de colocar **uma cópia sem editar** da planilha original em `BASE/REFERENCIAS/SCNES_DOMINIOS.XLS` (pasta já ignorada pelo Git):

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\audit_cnes_official_domains.py
```

```powershell
$m = Get-Content .\BASE\REFERENCIAS\cnes_domain_code_coverage_audit.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.status
$m.domain_source | Select-Object sha256,leitos_codes,tipos_codes,code_70_label,type_7_label
$m.observed_profile | Select-Object pairs,occurrences_total,distinct_codleito,distinct_tp_leito
$m.coverage_observed_against_uploaded_current_domains | Select-Object matched_pairs_code_and_type_independently,matched_source_rows,unmatched_pairs,unmatched_source_rows
$m.coverage_observed_against_uploaded_current_domains.exceptions
```

**Gate C4.2c.1**: comprovar quantitativamente presença dos códigos e tipos observados nas listas recebidas, sem declarar vínculo oficial ou período de vigência.

**DECISÃO PENDENTE subsequente:** obter fonte de `NFCES001/TB_LEITO` contendo **`CO_LEITO`, `DS_LEITO`, `TP_LEITO` por registro**, idealmente com versão histórica 2017–2019, ou evidência oficial equivalente. Só com essa correspondência comprovada será possível avaliar integralmente T29 e decidir o tratamento temporal, sem alterar `DIM_TIPO_LEITO` já aprovada.


### C4.2c.1 — execução local e gate de cobertura independente (08/10/2026)

**FATO VERIFICADO — evidência de execução PowerShell enviada pelo usuário:** após `git pull --ff-only origin main` (fast-forward `43f2baf..5fdcf13`), os arquivos originais em `BASE/REFERENCIAS` foram verificados localmente, antes da auditoria:

| Artefato | SHA-256 confrontado | Resultado |
|---|---|---|
| `SCNES_DOMINIOS.XLS` | `ae3f678f1f2307d759412c735f79bf1ace5a91410261f4050dc6e86c671c2af4` | `HASH PASS` |
| `DICIONARIO_DE_DADOS.docx` | `086bfcbdbf47ea13d89542a21128c691367c0560a9f6bf8a2319e8a6eadb973b` | `HASH PASS` |
| `cnes_lt_bed_code_pair_profile.csv` | `4afe0741b1bf43434192e467a043a0bcb7f2a96e25214f92f47557531e238449` | `HASH PASS` |

`tools/audit_cnes_official_domains.py` retornou `AUDIT_EXIT_CODE=0` e `VERDICT=CODE_AND_TYPE_COVERAGE_PROVISIONAL`. A inspeção do JSON `BASE/REFERENCIAS/cnes_domain_code_coverage_audit.json` confirmou:

- listas oficiais independentes: **66 códigos de leito** e **7 tipos**;
- perfil CNES/LT: **57 pares**, **57 `CODLEITO` distintos**, **7 `TP_LEITO` distintos**, **35.518 ocorrências**;
- códigos e tipos cobertos **independentemente**: **57/57 pares** e **35.518/35.518 ocorrências**, com **0 pares e 0 linhas sem cobertura**;
- nenhum `CODLEITO` observado associado a mais de um tipo bruto **no recorte PB**, o que não prova unicidade normativa nacional;
- `TP_LEITO` bruto preservado como um dígito seguido de espaço ASCII; listas independentes, sem relacionamento par-a-par;
- limites do JSON: `association_of_tp_leito_with_codleito_officially_verified=false`, `effective_normative_validity_2017_2019_verified=false`, `full_T29_approved=false`, `new_qvd_created=false`, `source_files_modified=false`.

**RESULTADO DO GATE C4.2c.1: PASS apenas para cobertura independente nas listas do arquivo recebido.** O status `PROVISIONAL` deve permanecer explícito; **não foi executado nem aprovado o T29**, não foi materializada referência oficial `(tipo, código, descrição)` e não foi demonstrada vigência histórica em 2017–2019.

**Próximo checkpoint C4.2c.2 — DECISÃO PENDENTE:** localizar e verificar evidência oficial que traga, **na mesma linha**, `CO_LEITO`, `DS_LEITO` e `TP_LEITO` (tabela `NFCES001/TB_LEITO` citada no dicionário ou equivalente), incluindo prova de aplicabilidade temporal para as 36 competências. Não alterar `REF_TIPO_LEITO.qvd`, QVDs existentes, dimensão aprovada, arquivos originais, nem modelagem nesta fase.



### C4.2c.2a — descoberta restrita de fonte oficial para associação tipo × leito (08/10/2026)

**Modo: READ-ONLY / SOURCE DISCOVERY.** Nenhum download em massa, transformação, QVD, materialização normativa ou teste T29 foi executado.

**FATOS VERIFICADOS EM DOCUMENTAÇÃO E PÁGINAS OFICIAIS:**

1. O dicionário SCNES já recebido especifica a tabela federal `NFCES001 / TB_LEITO` com `CO_LEITO`, `DS_LEITO` e `TP_LEITO` no mesmo registro. Existe também cópia pública de documentação DATASUS hospedada no governo do RJ: https://www.rio.rj.gov.br/dlstatic/10112/957482/DLFE-200518.pdf/DICIONARIO_DE_DADOS.pdf . **Isto descreve a estrutura, não fornece os registros nem versões históricas.**
2. A documentação oficial do CNESNet informa que o relatório público de Leitos permite selecionar Estado, Município e **Competência**, apresentando **Tipo de Leitos**, **Código**, **Descrição**, **Existentes** e **SUS**: https://wiki.saude.gov.br/cnes/index.php/CNESNet .
3. Uma consulta pública ao relatório do CNESNet, https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VEstado=00 , exibiu **sete agrupamentos textuais** (CIRÚRGICO, CLÍNICO, OBSTÉTRICO, PEDIÁTRICO, OUTRAS ESPECIALIDADES, HOSPITAL DIA e COMPLEMENTAR) com códigos e descrições abaixo de cada cabeçalho. Exemplo explícito: `HOSPITAL DIA → 70 FIBROSE CISTICA`. É evidência de agrupamento operacional exibido na consulta, **não certificado de vigência normativa por competência nem prova de domínio exaustivo**.
4. A documentação oficial do Portal CNES afirma que os downloads de Base de Dados por competência estão disponíveis **a partir de 06/2017**: https://wiki.saude.gov.br/cnes/index.php/Categoria:Consumo_de_informa%C3%A7%C3%B5es_da_Base_Nacional_do_CNES_via_webservice_e_Download_da_Base_de_Dados . Não foi comprovado se os pacotes oferecem a tabela de domínio `TB_LEITO`, nem uma versão aplicável a `201701–201705`.
5. O painel oficial ElastiCNES documenta campos de competência, tipo de leito, código e leito, mas não estabelece, pela documentação consultada, uma tabela normativa histórica de relação por competência: https://wiki.saude.gov.br/cnes/index.php/Pain%C3%A9is_ElastiCNES .

**AVALIAÇÃO DE EVIDÊNCIA:** o caminho mais econômico é aproveitar **os cinco HTMLs oficiais locais já capturados** em C4.2b e fazer uma inspeção de sua estrutura de **cabeçalhos de grupo + linhas de código/descrição**, que o comparador anterior deliberadamente descartou ao extrair somente duas células por linha. Essa nova pergunta (associação grupo/código) **não repete** a comparação já concluída de rótulos e quantitativos.

**DECISÕES PENDENTES ANTES DE ALTERAR CÓDIGO:**

- conferir em um HTML original a posição e a estrutura física dos sete cabeçalhos, sua associação inequívoca às linhas e a competência efetivamente selecionada (0/5 confirmações nos detectores anteriores);
- provar os 57 pares `(TP_LEITO,CODLEITO)` no(s) relatório(s) e registrar exceções, usando a aba oficial `TIPOS DE LEITOS` apenas para identificar o número do grupo por nome;
- se o relatório não provar competência/vigência, manter o resultado como **corroboração operacional parcial**, sem promover para T29;
- caso o agrupamento não possa ser extraído de forma reproduzível, investigar amostra de pacote público CNES (não download em massa), verificando primeiro manifesto/estrutura e existência de `NFCES001 / TB_LEITO`;
- preservar explicitamente a lacuna `201701–201705` se o único caminho histórico público iniciar em `201706`.

**GATE ATUAL:** `C4.2c.1=PASS_PROVISIONAL_INDEPENDENT_LISTS`; `C4.2c.2=OFFICIAL_GROUPED_SOURCE_LOCATED_STRUCTURE_NOT_YET_VERIFIED_LOCALLY`; `T29=NOT_APPROVED`. Necessária inspeção de ao menos um dos HTMLs locais antes de desenvolver ou validar um parser adicional; nenhuma alteração do modelo, do Qlik ou dos arquivos de origem autorizada.



### C4.2c.2b — inspeção física do HTML oficial 201712 e auditor de vínculos (08/10/2026)

**FATO VERIFICADO — arquivo fornecido pelo usuário:** `CNES_Leitos_Indicadores_201712_UF00.html`, **53.009 bytes**, SHA-256 `bc674e4e244701aa0f919ddac889290d937767cf10c7a1f58e40577134a62617`. Inspeção local em bytes, decodificação `cp1252`, sem consultar rede ou modificar o arquivo.

A estrutura do HTML revela informações que o extrator anterior (C4.2b.3a) não preservava:

- **7 cabeçalhos de grupo**: CIRÚRGICO, CLÍNICO, OBSTÉTRICO, PEDIATRICO, OUTRAS ESPECIALIDADES, HOSPITAL DIA e COMPLEMENTAR;
- **65 links de detalhe**, cada um com os parâmetros `VCod_Leito`, `VTipo_Leito` e `VComp`, contendo **65 pares únicos (tipo, código)**;
- distribuição por grupo (tipo): **1/17**, **2/16**, **4/2**, **5/2**, **6/5**, **7/6**, **3/17**;
- em **65/65** links `VComp=201712`, em **65/65** o código no texto da tabela confere com `VCod_Leito`, sem pares duplicados no HTML;
- exemplo pontual: cabeçalho `HOSPITAL DIA`, código `70`, descrição `FIBROSE CISTICA`, `VTipo_Leito=7`, `VComp=201712`;
- **limite persistente:** o `<select name="cboCompetencia">` só exibe a opção `00` e não possui `201712 selected`. A presença do parâmetro em links internos **não comprova** a competência efetivamente aplicada pelo servidor, nem vigência normativa.

**VALOR DA NOVA EVIDÊNCIA:** a associação `tipo + código + descrição` está explicitamente materializada no HTML oficial de indicador, não apenas em listas independentes. É uma **corroboração operacional estrutural**, ainda não um catálogo normativo histórico ou um T29 aprovado. Os 65 pares de uma captura **não foram comparados neste ambiente com o CSV local dos 57 pares PB**; esse teste depende da execução local.

**IMPLEMENTAÇÃO REPRODUZÍVEL:** adicionado `tools/audit_cnes_grouped_leito_links.py` em `main` para realizar uma auditoria **offline** restrita aos cinco HTMLs já capturados e seus hashes em `probe_summary.json`, usando o perfil `cnes_lt_bed_code_pair_profile.csv` e as listas de códigos/tipos de `SCNES_DOMINIOS.XLS`. O script:

1. valida 5/5 hashes e tamanhos antes de interpretar os HTMLs;
2. extrai links com código, tipo, competência e descrição; verifica o código da célula e o grupo pelo cabeçalho usando descrições da lista `TIPOS DE LEITOS`;
3. compara os pares extraídos com os 57 pares observados PB **separadamente por captura**;
4. compara conjuntos comuns/união e eventuais divergências de descrição entre as cinco capturas;
5. gera apenas o relatório local `BASE/REFERENCIAS/cnes_leito_history_probe/grouped_type_code_audit.json`, sem modificar entradas ou QVD;
6. registra, em qualquer resultado, `competence_selection_actually_applied_verified=false`, `normative_historical_validity_2017_2019_verified=false` e `t29_approved=false`.

**STATUS C4.2c.2b: SCRIPT IMPLEMENTADO / EXECUÇÃO DOS 5 HTMLs LOCAIS PENDENTE.** A prova de associação operacional desta amostra **não fecha** a vigência histórica 2017–2019. Se a auditoria local demonstrar cobertura integral e estabilidade, será apenas suporte provisório para decisão fundamentada sobre tratamento descritivo; `T29` continua bloqueado até gate específico posterior. Não gerar `REF_TIPO_LEITO.qvd` ou alterar o modelo.

**Execução local prevista (PowerShell na raiz, após `git pull --ff-only origin main`):**

```powershell
.\.venv\Scripts\python.exe -B .\tools\audit_cnes_grouped_leito_links.py
$LASTEXITCODE
$m = Get-Content .\BASE\REFERENCIAS\cnes_leito_history_probe\grouped_type_code_audit.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.status
$m.records | Select-Object requested_competence, links, distinct_pairs, observed_pb_pairs_matched, issues
$m | Select-Object common_pairs_across_captures, union_pairs_across_captures, missing_pb_pairs_in_all_captures, pairs_with_different_descriptions, issues_total
$m.limits
```



### C4.2c.2b — execução local: REVIEW_REQUIRED, discrepância tipo/código 3/66 (08/10/2026)

**FATO VERIFICADO — saída do PowerShell/JSON apresentada pelo usuário:** após `git pull --ff-only origin main`, executou `tools/audit_cnes_grouped_leito_links.py` contra cinco HTMLs já capturados. Resultado `AUDIT_EXIT_CODE=2`, `VERDICT=REVIEW_REQUIRED`, com **5 HTMLs**, **65 links / 65 pares distintos por arquivo** e **56 dos 57 pares CNES/LT da PB encontrados em cada HTML**. Interseção e união entre as capturas são ambas **65 pares**; nenhuma divergência textual de descrição foi reportada entre capturas. O mesmo par `TP_LEITO=3, CODLEITO=66` ficou ausente **nas cinco capturas**. Resultado JSON: `issues_total=25`, sendo **cinco problemas apontados por captura** (um `HEADERS_MISMATCH`, quatro `LINK_OR_GROUP_MISMATCH` dos grupos OBSTÉTRICO e PEDIATRICO). Estes **25 apontamentos não são 25 códigos divergentes**: as ocorrências repetem os mesmos problemas entre as cinco amostras.

**EVIDÊNCIA PRIMÁRIA MATERIALIZADA NO HTML:** `CNES_Leitos_Indicadores_201712_UF00.html` (SHA-256 `bc674e4e244701aa0f919ddac889290d937767cf10c7a1f58e40577134a62617`) inclui, sob o cabeçalho **CLÍNICO**, o registro `66 — UNIDADE ISOLAMENTO` com link `VCod_Leito=66&VTipo_Leito=2&...&VComp=201712`. Os dados LT da PB, conforme perfil validado, contêm `TP_LEITO="3 "` + `CODLEITO="66"`. Logo, é uma **divergência efetiva entre a classificação do indicador CNESNet e o par observado nos arquivos LT**, não um simples código ausente de ambos os domínios.

**CORROBORAÇÃO SECUNDÁRIA CONTRÁRIA AO INDICADOR:** a tabela de domínio publicada pelo CONASS em https://wiki.conass.org.br/index.php?title=Tabela_de_dom%C3%ADnio_CNES_leito traz `tp_leito=3 / complementar / codleito=66 / unidade isolamento`, compatível com o LT da PB. Documentos institucionais de hospitais também posicionam 66 em COMPLEMENTAR, mas não são tabela normativa versionada para 2017–2019. **Não declarar que a discrepância implica erro factual do SIH/CNES original, troca histórica ou bug CNESNet sem validação normativa adicional.**

**HIPÓTESE DE IMPLEMENTAÇÃO DO AUDITOR A INVESTIGAR:** os quatro `LINK_OR_GROUP_MISMATCH` por amostra concentram-se nos códigos 10/43 (OBSTÉTRICO) e 45/68 (PEDIATRICO). Os links possuem números de tipo `4` e `5` e códigos visíveis consistentes, segundo a saída; a verificação por **igualdade textual** do cabeçalho com a descrição da planilha `TIPOS DE LEITOS` pode ser mais estrita do que o necessário. Os valores **exatos** das duas nomenclaturas, ainda não exibidos pelo auditor, precisam ser inspecionados antes de classificar essas quatro ocorrências como falso positivo ou mudar o código. Não ocultar divergências por equivalência arbitrária.

**GATE: C4.2c.2b = REVIEW_REQUIRED. T29 = NOT_APPROVED.** Nenhuma correção dos dados brutos, nenhuma atribuição automática de tipo 2↔3, nenhuma inferência de vigência normativa, nenhum QVD gerado. O próximo passo é **diagnóstico local read-only da nomenclatura exata dos sete tipos oficiais**, contagens/competências reais do par `3/66` no `cnes_lt_bed_code_pair_profile.csv` e inspeção da referência oficial `TB_LEITO` ou documento histórico equivalente. Preservar explicitamente a discrepância se não houver fonte conclusiva.



### C4.2c.2c — diagnóstico de nomes, impacto e correção restrita do auditor (08/10/2026)

**FATO VERIFICADO — saída do diagnóstico local enviada pelo usuário:**

- `TIPOS DE LEITOS` (SCNES): `4 = OBSTETRICOS` e `5 = PEDIATRICOS`, sem correspondência literal aos cabeçalhos do relatório;
- HTML CNESNet: `OBSTETRICO` e `PEDIATRICO`; os outros **5/7 tipos** têm correspondência exata após remoção de acentos para comparação;
- o par **`TP_LEITO="3 "` + `CODLEITO="66"`** aparece em **1.480 registros LT** da Paraíba, de `201701` a `201912`, em **36/36 competências**, com espaços brutos preservados;
- com isso, os 25 `issues` prévios do auditor representam apenas problemas de igualdade textual de grupo repetidos cinco vezes; são **dois pares de nomenclatura** diferentes, não 25 divergências semânticas.

**FATO VERIFICADO — fontes oficiais com agrupamento divergente:**

- relatório agregado CNESNet (HTML local 201712): `66 — UNIDADE ISOLAMENTO` aparece em **CLÍNICO / VTipo_Leito=2**;
- páginas de estabelecimento no **próprio CNESNet** apresentam `66 — UNIDADE ISOLAMENTO` sob **COMPLEMENTAR**, por exemplo https://cnes2.datasus.gov.br/Cabecalho_Reduzido_Competencia.asp?VCod_Unidade=3143902195453 e https://cnes2.datasus.gov.br/cabecalho_reduzido.asp?VCod_Unidade=3205300011746 .
- fonte secundária CONASS também registra `tp_leito=3`, `codleito=66`, `COMPLEMENTAR`: https://wiki.conass.org.br/index.php?title=Tabela_de_dom%C3%ADnio_CNES_leito .

**INTERPRETAÇÃO RESTRITA:** há **inconsistência de classificação entre visões oficiais acessadas do CNESNet** e discrepância com os dados observados da PB. A correspondência de páginas de estabelecimento e fonte secundária fortalece a classificação `3/66` no contexto operacional, mas ainda **não demonstra regra normativa e vigência exata para 2017–2019**. Não inferir defeito da base LT, migração de tipo ou revisão temporal sem prova.

**Correção implementada no script, execução local pendente:**

- `tools/audit_cnes_grouped_leito_links.py` recebeu **apenas duas equivalências explícitas e condicionadas à combinação exata (tipo, rótulo oficial)**: `("4", "OBSTETRICOS") → "OBSTETRICO"` e `("5", "PEDIATRICOS") → "PEDIATRICO"`;
- a comparação continua **estrita** para os outros cinco tipos e exige equivalência literal do código numérico do link e da célula, sem permitir associação arbitrária de códigos;
- inclusão em `grouped_type_code_audit.json` do manifesto `accepted_group_label_aliases` e da cobertura **ponderada pelos `occurrences` do perfil PB**, com `observed_pb_rows_matched_by_pair`, `observed_pb_rows_missing_by_pair` e ocorrências dos pares ausentes;
- o par `3/66` permanece **obrigatoriamente incompatível** com o par `2/66` do HTML; mesmo `issues_total=0` não pode produzir `PASS` se persistir `56/57`;
- não foram alterados CSVs LT, XLS/DOCX recebidos, HTMLs, QVDs, `DIM_TIPO_LEITO` nem requisitos acadêmicos.

**GATE:** C4.2c.2c `CODE_PATCH_IMPLEMENTED_LOCAL_AUDIT_PENDING`; C4.2c.2 `REVIEW_REQUIRED`; T29 `NOT_APPROVED`. Para reexecutar:

```powershell
git pull --ff-only origin main
.\.venv\Scripts\python.exe -B .\tools\audit_cnes_grouped_leito_links.py
Write-Host "AUDIT_EXIT_CODE=$LASTEXITCODE"
$m = Get-Content .\BASE\REFERENCIAS\cnes_leito_history_probe\grouped_type_code_audit.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.records | Select-Object requested_competence,observed_pb_pairs_matched,observed_pb_rows_missing_by_pair,issues
$m.accepted_group_label_aliases
$m.missing_pb_pairs_in_all_captures
$m.status
$m.limits
```



### C4.2c.2c — reexecução local após equivalências nominais (08/10/2026)

**FATO VERIFICADO — saída do PowerShell e relatório JSON fornecidos pelo usuário:** `git pull --ff-only origin main` atualizou `de632c0..973ab11` e a execução local de `tools/audit_cnes_grouped_leito_links.py` retornou `AUDIT_EXIT_CODE=2`, `VERDICT=REVIEW_REQUIRED`. Em cada uma das cinco capturas `201712, 201801, 201805, 201806, 201912`:

- `LINKS=65`, `PAIRS=65`;
- `PB_MATCHED=56/57`, `PB_ROWS_UNMATCHED=1480` (**ocorrências acumuladas do perfil PB das 36 competências**, não 1.480 por captura);
- `ISSUES=0`: a equivalência nominal exata `OBSTETRICOS → OBSTETRICO` e `PEDIATRICOS → PEDIATRICO` removeu os 25 apontamentos textuais anteriores;
- `missing_pb_pairs_in_all_captures = [{type:3, code:66, occurrences_in_pb_profile:1480}]`.
  
Assim, **34.038/35.518 linhas PB** estão associadas a 56 pares identificados nesses HTMLs. O par PB `3/66` permanece divergente do par exibido pelo CNESNet agregado `2/66`. O indicador não demonstra competência selecionada; o confronto dos cinco HTMLs continua **operacional/provisório**, não temporal normativo.

### C4.2c.2d — evidência documental primária histórica para código 66 (08/10/2026)

**FATO VERIFICADO — fontes oficiais externas consultadas, sem baixar arquivos para o projeto:**

1. **SCNES 2017 em documento de secretaria municipal:** o [Plano Municipal de Saúde 2018–2021 de Barra Mansa/RJ](https://portaltransparencia.barramansa.rj.gov.br/wp-content/uploads/2024/02/Plano-Municipal-de-saude-2018-a-2021.pdf), páginas impressas 83 e 85 (índices PDF 82 e 84), inclui relatórios de estabelecimentos com `COMPLEMENTAR → 66-UNIDADE ISOLAMENTO`, citando `Fonte: SCNES, 2017`. É fonte **governamental contextual de 2017**, não uma tabela normativa versionada mês a mês.
2. **Nota Técnica do próprio Ministério da Saúde com data impressa de 02/12/2019:** [SEI/MS 0012300247, hospedada em rts.saude.gov.br](https://rts.saude.gov.br/portal/documento/441/arquivo) está indexada com uma tabela de classificação que traz **`66 | UNIDADE ISOLAMENTO | Complementar | Portaria nº 511/SAS/MS, de 29 de dezembro de 2000 (republicada em 19/06/2001) | Ativo`**. **A URL e o trecho indexado foram identificados, mas a abertura/obtenção integral do documento não foi concluída (timeout); preservar ressalva de inspeção de original e integridade.**
3. **Documento legislativo originário:** [Portaria SAS/MS nº 511/2000, cópia no portal da Secretaria de Saúde do Amazonas](https://www.saude.am.gov.br/wp-content/uploads/2025/01/PT-CNES-PORTARIA-No-511-DE29-DE-DEZEMBRO-DE-2000.pdf) aprova a FCES/Manual, mas seu texto principal consultado **não identifica diretamente a associação `3/66`**. Não promover essa Portaria isoladamente como prova da classificação.
4. **Outra consulta DATASUS/CNESNet:** o [módulo de estabelecimento `Mod_Hospitalar.asp`](https://cnes2.datasus.gov.br/Mod_Hospitalar.asp?VCo_Unidade=2919554644360) exibe `66-UNIDADE ISOLAMENTO` no grupo `COMPLEMENTAR`; a [consulta detalhada do indicador com `VTipo_Leito=3`](https://cnes2.datasus.gov.br/Mod_Ind_Leitos_Listar.asp?VCod_Leito=66&VComp=&VEstado=33&VListar=1&VMun=330330&VTipo_Leito=3) é indexada como `Tipo Leito - Complementar - UNIDADE ISOLAMENTO`. Contrasta com os cinco HTMLs do indicador agregado (`VTipo_Leito=2`). Consulta atual não é prova isolada de vigência retroativa.
5. A [tabela auxiliar CONASS](https://wiki.conass.org.br/index.php?title=Tabela_de_dom%C3%ADnio_CNES_leito) também registra `3/66`, mas é **secundária**, com outras possíveis inconsistências de nomenclatura.

**Interpretação:** fontes governamentais contextualizadas em **2017** e **2019**, além do LT local em 36 competências, convergem para `3/66 — COMPLEMENTAR`. Há evidência de uma classificação divergente **na apresentação agregada CNESNet**; **não alterar a fonte CNES/LT para 2/66** nem tratar a divergência como erro provado do dado PB. Ainda não há prova completa de vigência normativa **de todos os 57 pares em todas as 36 competências**. A Nota Técnica de 2019 merece obtenção e inspeção integral, com URL, hash, tabela completa e eventuais alterações históricas, antes de decidir T29.

**GATE ATUAL:** `III-C4.2c.2c=PASS_STRUCTURE_ONLY`; `III-C4.2c.2d=PRIMARY_HISTORICAL_CORROBORATION_PENDING_SOURCE_BYTES`; `T29=NOT_APPROVED`; `FASE_III=IN_PROGRESS`. Nenhuma referência QVD, nenhum mapeamento compensatório `2/66 → 3/66`, nenhum dado original ou modelo alterado.



### C4.2c.2e — Nota Técnica nº 32/2019 integral recebida e tabela estruturada (08/10/2026)

**FATO VERIFICADO — arquivo PDF disponibilizado pelo usuário e inspecionado integralmente, 8 páginas:**

- `Nota Técnica  32-2019 Leitos.pdf`, **193.268 bytes**, SHA-256 `43de32e91b9ed2611bacde8f4cea60576cb162017fa4db69797dd177c4f7632e`; PDF v1.4, metadata de criação `2019-12-02 12:25:31 UTC` (não é prova independente da autenticidade normativa);
- cabeçalho `NOTA TÉCNICA Nº 32/2019-CGSI/DRAC/SAES/MS`, SEI/MS `0012300247`; item 2 descreve objetivo de relacionar nomenclatura de leitos à legislação; anexo intitulado **`Tabela de Leitos Setembro/2019`** (p. 1);
- página 8: declaração de assinatura eletrônica por **Leandro Manassi Panitz**, em **29/11/2019 às 11:45**, código verificador **0012300247**, CRC **25B0C110**, processo **25000.192815/2019-55**. **O documento contém dados de autenticação SEI, mas a validação online destes códigos não foi efetuada nesta rodada**;
- 65 linhas código/nome/tipo/legislação/status extraídas das páginas 2–7, **65 códigos distintos**, todos `Ativo`; número de linhas por página `2:9, 3:10, 4:10, 5:11, 6:14, 7:11`;
- classificação de 65 registros por grupo `1 CIRÚRGICO:17`, `2 CLÍNICO:15`, `3 COMPLEMENTAR:18`, `4 OBSTÉTRICO:2`, `5 PEDIÁTRICO:2`, `6 OUTRAS ESPECIALIDADES:5`, `7 HOSPITAL-DIA:6`. Os códigos numéricos `1..7` decorrem do cruzamento dos nomes com a aba `TIPOS DE LEITOS` do arquivo SCNES já verificado; a Nota Técnica apresenta **nomes dos tipos**, não o número do tipo;
- **página 5:** `66 | UNIDADE ISOLAMENTO | Complementar | Portaria nº 511/SAS/MS de 29/12/2000 (republicada 19/06/2001) | Ativo`; `70 | FIBROSE CISTICA | Hospital-Dia | Portaria nº 44/GM/MS de 10/01/2001 | Ativo`;
- comparação exata dos **65 pares código/tipo** da Nota Técnica com os **65 links da captura CNESNet 201712**: são conjuntos iguais exceto **`(3,66)` presente apenas na Nota Técnica** e **`(2,66)` presente apenas no indicador CNESNet**. Todos os 65 **códigos** estão presentes nos dois conjuntos. Isso identifica de maneira precisa a divergência entre fontes.

**AVALIAÇÃO DE COBERTURA (ainda inferência, não execução real local):** na rodada anterior, o auditor do indicador exibiu `56/57` pares CNES/LT da Paraíba presentes, com único par ausente `3/66`. Como o conjunto transcrito da Nota Técnica difere do indicador *exatamente* por substituir `2/66` por `3/66`, **é esperado que a Nota Técnica cubra 57/57 pares PB (35.518 linhas)**. Isto precisa de **execução independente** contra o CSV real antes de declarar qualquer cobertura aferida.

**ARTEFATOS TEXTUAIS REPRODUZÍVEIS (não são dados normativos originais):**

- `docs/discovery/cnes-nt32-2019-codigos-leito.csv`: **transcrição derivada** de 65 linhas, UTF-8, `;` delimitado, campos `codleito,tp_leito,nome_cnes,tipo_cnes,status,pdf_page`; SHA-256 `c44d1075ed4b628106587f11cb38eab794d3573986e2079844738ad8c4b3f2c6`. Cada linha aponta para a página do PDF; a transcrição não é um arquivo oficial de domínio CNES independente do PDF;
- `tools/audit_cnes_nt32_2019_pairs.py`: Python stdlib somente; exige SHA-256 exato do PDF original, da transcrição versionada e do perfil PB (`4afe0741...`); valida `65` registros/regras da Nota Técnica, `57` pares/`35.518` ocorrências do perfil, compara as **associações compostas** `TP_LEITO + CODLEITO`, discrimina exceções e quantifica ocorrências. Gera somente `BASE/REFERENCIAS/cnes_nt32_201909_pair_audit.json`, não QVD nem alteração das fontes;
- PDF original, grande e binário, **permanece fora do Git**, no `BASE/REFERENCIAS` ignorado. Copiar sem editar para `BASE/REFERENCIAS/Nota Técnica  32-2019 Leitos.pdf` antes de executar (ou usar `--pdf caminho` para apontar ao original).

**LIMITES TEMPORAIS INEGOCIÁVEIS:** o documento é anexo da **Tabela de Leitos Setembro/2019**, não um conjunto de 36 versões mensais nem uma demonstração de estabilidade contínua de nomes/tipos. Status `Ativo` e indicação de portaria de inclusão anterior a 2017 **não** provam ausência de alteração normativa posterior. Mesmo que haja `PASS_201909_SNAPSHOT_PAIR_COVERAGE_ONLY` no teste local, **T29 integral 2017–2019 fica NOT_APPROVED**, sem `REF_TIPO_LEITO.qvd` ou mudança de `DIM_TIPO_LEITO`.

**Gate C4.2c.2e:** `PDF_RECEIVED_AND_65_ROWS_INSPECTED / SOURCE_PAIR_AUDIT_IMPLEMENTED / LOCAL_EXECUTION_PENDING`. O próximo passo é testar a cobertura sobre os 57 pares/35.518 ocorrências efetivos e, depois, decidir separadamente o grau de validade temporal aceitável conforme os requisitos do projeto, priorizando evidência normativa ou de bases versionadas.

**Execução local (sem download de dados ou modificação dos originais):**

```powershell
git pull --ff-only origin main
.\.venv\Scripts\python.exe -B .\tools\audit_cnes_nt32_2019_pairs.py
Write-Host "AUDIT_EXIT_CODE=$LASTEXITCODE"
$m = Get-Content .\BASE\REFERENCIAS\cnes_nt32_201909_pair_audit.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m | Select-Object status,pb_matched_pairs,pb_matched_lt_rows,pb_unmatched_lt_rows,unmatched_pairs
$m.limits
```



### C4.2c.2e.1 — diagnóstico de incompatibilidade de quebra de linha do CSV (08/10/2026)

**FATO VERIFICADO — execução PowerShell recebida do usuário:** o PDF original foi encontrado em `BASE/REFERENCIAS/Nota Técnica  32-2019 Leitos.pdf` e passou no gate de SHA-256 `43de32e91b9ed2611bacde8f4cea60576cb162017fa4db69797dd177c4f7632e`. Contudo, `tools/audit_cnes_nt32_2019_pairs.py` retornou `AUDIT_EXIT_CODE=2` e `AUDIT_INPUT_ERROR` na transcrição versionada, antes de ler o perfil LT ou comparar pares; o JSON `cnes_nt32_201909_pair_audit.json` **não foi criado**. A consulta posterior a `$m` no PowerShell não é resultado de auditoria (variável nula ou estado anterior).

**CAUSA IDENTIFICADA DE FORMA REPRODUZÍVEL:** o SHA-256 do CSV versionado `docs/discovery/cnes-nt32-2019-codigos-leito.csv`, tal como publicado no GitHub com LF, é `c44d1075ed4b628106587f11cb38eab794d3573986e2079844738ad8c4b3f2c6`. O **mesmo conteúdo** com LF substituído exclusivamente por CRLF tem SHA-256 `f9cc289b0a27557dd92b04bcfb558ac33d528900e6937549e71b373f36ccc363`, **exatamente o valor obtido pelo usuário** no checkout Windows. Ausência de `.gitattributes` específica para este CSV; a diferença pode resultar da conversão padrão de final de linha no checkout. Nenhuma hipótese de alteração de códigos, tipos, nomes ou status é necessária para explicar os hashes.

**CORREÇÃO ESTRITAMENTE TÉCNICA implementada:** `tools/audit_cnes_nt32_2019_pairs.py` foi ajustado para aceitar **somente os dois hashes exatos previamente verificados** (LF e CRLF) **exclusivamente para o CSV de transcrição**. PDF e perfil LT continuam exigindo seus hashes originais únicos; não houve flexibilização genérica de integridade nem modificação de arquivos de origem. O relatório agora diferencia hash real do arquivo de checkout, hash canônico LF da transcrição no Git e convenção de final de linha.

**Gate atual:** `C4.2c.2e.1=HASH_ROOT_CAUSE_CONFIRMED_AND_PATCHED`; `C4.2c.2e=LOCAL_REEXECUTION_PENDING`; `T29=NOT_APPROVED`. O resultado anterior **não informa cobertura** da Nota Técnica sobre os 57 pares/35.518 registros LT, e a referência continua sendo o retrato de `Setembro/2019`, sem atribuição de vigência integral em 2017–2019.

**Ação local (sem recópia do PDF ou edição do CSV):**

```powershell
git pull --ff-only origin main
.\.venv\Scripts\python.exe -B .\tools\audit_cnes_nt32_2019_pairs.py
Write-Host "AUDIT_EXIT_CODE=$LASTEXITCODE"
if ($LASTEXITCODE -eq 0 -and (Test-Path .\BASE\REFERENCIAS\cnes_nt32_201909_pair_audit.json)) {
    $m = Get-Content .\BASE\REFERENCIAS\cnes_nt32_201909_pair_audit.json -Raw -Encoding UTF8 | ConvertFrom-Json
    $m | Select-Object status,pb_matched_pairs,pb_matched_lt_rows,pb_unmatched_lt_rows,unmatched_pairs
    $m | Select-Object derived_transcription_sha256,derived_transcription_git_lf_sha256,derived_transcription_checkout_line_endings
    $m.limits
}
```



### C4.2c.2e.2 — execução local aprovada: cobertura da Nota Técnica Setembro/2019 (08/10/2026)

**FATO VERIFICADO — execução PowerShell e consulta ao JSON enviadas pelo usuário após `git pull --ff-only origin main` (fast-forward `8efb009..ef471c2`):**

- script executado: `tools/audit_cnes_nt32_2019_pairs.py`; `AUDIT_EXIT_CODE=0`;
- `PDF_INTEGRITY=PASS`, `TRANSCRIPTION_INTEGRITY=PASS`, `PROFILE_INTEGRITY=PASS`;
- `NOTE_SNAPSHOT_PAIRS=65` (tabela derivada do anexo `Tabela de Leitos Setembro/2019`);
- `PB_MATCHED_PAIRS=57/57`, `PB_MATCHED_ROWS=35518/35518`, `UNMATCHED_PAIRS=0`;
- saída local: `BASE/REFERENCIAS/cnes_nt32_201909_pair_audit.json`; `status=PASS_201909_SNAPSHOT_PAIR_COVERAGE_ONLY`;
- SHA-256 efetivo do CSV derivado no checkout Windows (CRLF) `f9cc289b0a27557dd92b04bcfb558ac33d528900e6937549e71b373f36ccc363`, reconhecido com hash canônico LF também aprovado; integridade dos arquivos originais preservada;
- limites registrados pelo próprio JSON: `this_is_a_transcription_not_original_normative_dataset=true`, `reference_is_snapshot_201909=true`, `complete_validity_across_201701_201912_verified=false`, `t29_full_approved=false`, `new_qvd_created=false`, `source_files_modified=false`.

**RESULTADO DO GATE C4.2c.2e — PASS apenas para cobertura de pares compostos da amostra de referência oficial Setembro/2019.** A transcrição derivada, com campo `pdf_page`, permitiu reconciliar todos os pares `TP_LEITO + CODLEITO` efetivamente observados nas 35.518 linhas LT da PB. O par `3/66 — UNIDADE ISOLAMENTO / COMPLEMENTAR` é coberto pela Nota Técnica, sem substituí-lo pelo `2/66` do indicador agregado CNESNet, que permanece documentado como conflito entre fontes.

**Interpretação temporal restrita:** todas as 36 competências locais **usam pares que constam no catálogo de setembro/2019**, mas esse confronto não prova que o catálogo (nomes, classificação, status) era **normativamente válido sem mudança em cada mês** de 201701 a 201912. Também não prova se um código foi efetivo em toda a série; ocorrência física e vigência normativa não são intercambiáveis.

**Próximo checkpoint proposto — C4.2c.3, DESCOBERTA HISTÓRICA RESTRITA / READ-ONLY:** verificar se há fonte oficial versionada por competência ou atos normativos de alteração que possam sustentar o uso retrospectivo da tabela de setembro/2019. Priorizar (i) versões/alterações normativas das 65 linhas do anexo, com destaque ao par `3/66`, (ii) fonte primária de domínio `NFCES001/TB_LEITO`, se disponível por período, (iii) lacuna de downloads públicos antes de 06/2017. **Não solicitar novas cargas massivas, não reprocessar os 35.518 registros e não emitir T29 integral enquanto a vigência histórica não for fundamentada ou a limitação temporal não for explicitamente aceita como decisão de modelagem.**

**Decisão operacional preservada:** Fase III `IN_PROGRESS`; `T29_FULL=NOT_APPROVED`; sem `REF_TIPO_LEITO.qvd`, sem alteração da `DIM_TIPO_LEITO`, CSVs LT, QVDs ou relatório acadêmico aprovado.



### C4.2c.3 — triagem de vias de versionamento histórico (READ-ONLY / 08/10/2026)

**FATOS VERIFICADOS — documentação pública oficial consultada, sem aquisição de arquivos novos:**

- [Portal CNES — Base de Dados](https://wiki.saude.gov.br/cnes/index.php/Portal_CNES) e [Categoria Downloads Base Nacional](https://wiki.saude.gov.br/cnes/index.php/Categoria:Consumo_de_informa%C3%A7%C3%B5es_da_Base_Nacional_do_CNES_via_webservice_e_Download_da_Base_de_Dados): informam disponibilização de downloads **por competência a partir de 06/2017**. A presença, granularidade, conteúdo e versionamento da tabela `NFCES001/TB_LEITO` **nesses pacotes não foram verificadas**.
- [Wiki CNES — Cronograma](https://wiki.saude.gov.br/cnes/index.php/Cronograma) e [Cronogramas dos Anos Anteriores](https://wiki.saude.gov.br/cnes/index.php/Cronogramas_dos_Anos_Anteriores): documentam **disponibilização por competência do RTS** e de versões do CNES Desktop; entretanto, a existência de downloads históricos utilizáveis das tabelas de leitos em 2017–2019 **não foi comprovada**. Uma competência pode ter mais de uma versão publicada, portanto o mês sozinho não identifica inequivocamente a versão de software/referência.
- [Guia oficial de instalação SCNES](https://wiki.saude.gov.br/cnes/index.php/Guia_de_Instala%C3%A7%C3%A3o_dos_Sistemas): distingue `SCNES Completo` e `SCNES Atualização`; o aplicativo completo instala tabelas de base e atualizações geralmente refletem novas regras. Não foi demonstrado acesso a uma sequência auditável das tabelas `TB_LEITO` com hashes/versões históricas.
- [Documentação do CNESNet](https://wiki.saude.gov.br/cnes/index.php/CNESNet) e [Painéis ElastiCNES](https://wiki.saude.gov.br/cnes/index.php/Pain%C3%A9is_ElastiCNES): suportam consulta operacional com tipo/código/competência. **Não são substitutos automaticamente equivalentes ao catálogo normativo versionado**; preserva-se a divergência conhecida `2/66` vs `3/66`.

**RESULTADO DA TRIAGEM:** rotas oficiais de acesso **identificadas**, mas **nenhum arquivo normativo histórico `TB_LEITO` foi obtido ou identificado com versão/competência demonstradas**. **Não declarar C4.2c.3 PASS** nem preencher lacunas temporais de 201701–201705 por imputação. Próximo gate deve ser uma inspeção de metadados e estrutura de **amostra mínima** de versão histórica se acessível, ou uma decisão acadêmica documentada que aceite explicitamente a referência set/2019 como classificação descritiva com suas limitações temporais. Qualquer aceitação assim **não modifica retroativamente os dados oficiais**, não valida vigência não comprovada, nem aprova silenciosamente T29 pleno.


## 4. Gate seguinte — C4.2 referência oficial

Somente **após avaliar o resultado real de C4.1**:

1. confirmar as fontes oficiais aplicáveis de `TP_LEITO`/`CODLEITO`, seu esquema de arquivo e disponibilidade histórica 2017–2019;
2. identificar códigos/descrições reais e potencial mudança de classificação por competência;
3. materializar ou validar amostra controlada da referência, com fonte, versão, campos e hashes comprovados;
4. medir T29 sobre 35.518 linhas CNES/LT **por competência quando a referência assim exigir**, documentando exceções;
5. só então avaliar `REF_TIPO_LEITO.qvd` na extração QlikView 12.

A Fase III permanece `IN PROGRESS`. Não modificar os fatos/dimensões, arquivos acadêmicos aprovados ou dados de origem nesta etapa.
