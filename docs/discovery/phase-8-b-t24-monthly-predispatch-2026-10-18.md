# Fase VIII-B — T24 em competências parciais + guardas pré-dispatch D2/P5

**Estado:** `VERSIONED_NOT_EXECUTED`. Ensaio em branch independente da `main@337943d5c5b77067f842902fc679dbb68db87020`, sem merge. Nenhum PASS físico deste novo subgate.

## 1. Baseline, fontes e finalidade

A execução **T24 anual** no PR #110 (`c35302aec6a4a5e91d1837dc9aac0e0cd626c2d7`) terminou com `VERDICT=PASS_LOCAL_T24_ANNUAL_5_CASES_CANDIDATE_ONLY`, conforme stdout apresentado pelo responsável; cinco recortes reconciliados com F3 e 22 QVDs/QVWs canônicos preservados. Esse PASS permanece **restrito ao piloto anual**, sem generalização aos meses nem à política D2/P5. O PR #110 continua Draft. O QVW temporário dessa execução é uma entrada **reutilizável somente em cópia descartável**, sem recarga: `%TEMP%\SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac\SAD_VIII_T24_ANNUAL_TEST.qvw`. Seu SHA é aferido antes/depois no PC; seus bytes não foram inspecionados nesta sessão.

Fontes do contrato: `AGENTS.md`, `current-state.md`, `requirements.md`, Boundary 7, V2 §62.1–62.9, VI-P5 e Fase VIII-A (PR #108 Draft). Oráculos históricos: `F1_residencia_competencia.csv` e `F3_componentes_residencia_ano.csv`, produzidos por `preflight_f1_f2_referencias_independentes.py` e `preflight_f3_denominadores_ibge.py`; nomes de campos extraídos do código histórico congelado do PR #83, **não inventados**. Hashes dos dois CSVs devem corresponder aos manifestos próprios; as cadeias completas já passaram o readiness local do PR #109. Não reexecutar a geração de F1/F3.

**Objetivo único:** avaliar T24 **em janelas mensais parciais de 2018** com POP anual por residência e exercitar **somente guardas de pré-despacho** para conflitos D2 e incompatibilidades P5, sem claim de enforcement na interface. Usar a competência administrativa SIH/RD, não datas clínicas.

## 2. Matriz experimental e oráculos

| ID | Contexto Qlik em QVW TEMP | Oráculo independente | Critério candidato |
|---|---|---|---|
| M01 | João Pessoa/2018, competência `201801` | F1 RES mensal `250750,201801` + POP F3 2018 `800323` | Numerador e POP exatos; taxa tolerância até `0,000001` |
| M02 | João Pessoa/2018, competências `201801` e `201803` | Soma dos dois F1 RES mensais; **POP F3 uma vez** | Mesmo aceite, período etiquetado descontínuo |
| M03 | PB/2018, competência `201801` | Soma dos F1 RES mensais apenas para códigos dos 223 municípios F3; POP F3 PB `3996496` | Mesmo aceite, sem incluir residentes externos |
| D2-A | Ano `2019` pré-selecionado; propor competência `201809` | Política V2 D2 | Proposta bloqueada **antes** de ser enviada a COM; ano preservado |
| D2-B | Competência `201809` pré-selecionada; propor ano `2019` | Política V2 D2 | Proposta bloqueada **antes** de ser enviada a COM; competência preservada |
| P5-B | T24 RES, ano/residência; propor filtro `SERV_COD_DATASUS_6` | V2: município de serviço = **B** para RES | Não enviar seleção; indisponibilidade do KPI geral neste contexto |
| P5-R | T24 RES, ano/residência; propor filtro `COD_PROCEDIMENTO` | V2: procedimento = **R** para RES | Não enviar seleção; contrato de recorte específico ainda ausente |

A recuperação POP sob competência será sondada somente como candidata pela expressão Qlik `Sum({$<PERIODO_COMPETENCIA=>} POPULACAO_ESTIMADA)`. A remoção da **seleção de competência para a medida POP anual** não autoriza ignorar filtros no numerador nem resolver D2 por supressão silenciosa. Numerador `Sum(QTD_INTERNACAO)` permanece no conjunto selecionado; razão parcial `1000 × numerador do mês / POP anual`, sem anualização. A diferença numérica até 1e-6 por 1.000 mantém a tolerância usada no piloto anual, sem promovê-la a padrão geral.

**Limitações explícitas:** D2 é testada como decisão lógica **pré-dispatch de um wrapper COM**, não como guarda de objeto/painel visual. P5 B/R é avaliada somente como política do wrapper com ausência de despacho, não como `Calculation Condition` nem filtro global homologado. O ensaio não abrange automaticamente todos os 12 filtros, filtros simultâneos C/R/I/B, residentes externos, mês sozinho sem ano, multi-ano, agregado regional, zero observado ou histórico CNES; nenhum deles ganha PASS por aproximação.

## 3. Arquivo e execução

`tools/Invoke-SadPhaseViiiT24MonthlyPredispatch.ps1` é o único script novo. Não copia o QVS para uma nova implementação; usa `OpenDoc` em cópia de QVW **sob pasta nova de %TEMP%**, com `ClearAll`/seleções COM e `Evaluate` para leitura numérica. O QVW anual original e os 22 QVDs são lidos e aferidos por SHA, assim como os QVWs canônicos; não há chamada `Reload`, `Store` ou `Save` sobre o modelo.

### Comandos Windows — somente após revisar a branch e o parser

```powershell
git fetch origin
git switch --track origin/test/phase-viii-t24-monthly-predispatch-20261018
git rev-parse HEAD
git status --short

$source = Join-Path $env:TEMP 'SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac\SAD_VIII_T24_ANNUAL_TEST.qvw'
$f1 = Join-Path $env:TEMP 'sad-f1-f2-20261014-191743'
$f3 = Join-Path $env:TEMP 'sad-f3-20261014-194242'

$tok=$null; $err=$null
[void][System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path .\tools\Invoke-SadPhaseViiiT24MonthlyPredispatch.ps1).Path,
  [ref]$tok, [ref]$err)
if($err.Count -gt 0){$err | ForEach-Object {$_.ToString()}; throw 'PARSER=BLOCKED'}
'PARSER=PASS'
```

Se o parser passar e os três caminhos existirem, executar **uma tentativa**:

```powershell
powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiT24MonthlyPredispatch.ps1 `
  -Root (Get-Location).Path -SourceQvw $source -F1F2Dir $f1 -F3Dir $f3 -RunQlik
```

> Na inicialização, se o arquivo TEMP anual estiver ausente, **não reexecutar o piloto anual automaticamente**. Registrar bloqueio e revisar o contrato do teste. Se há erros de parser, **não executar**. Se o script falhar em Qlik, manter o CSV parcial e stdout, não tentar variantes automaticamente.

## 4. Critério de parada e governança

Somente `VERDICT=PASS_LOCAL_T24_PARTIAL_3_AND_WRAPPER_GUARDS_4_CANDIDATE_ONLY` emitido após **3 casos numéricos reconciliados, 4 guardas restritas de wrapper e SHA de 22 QVDs, QVWs canônicos e QVW T24 fonte preservados** autoriza encerrar o piloto delimitado como PASS candidato. Falha de Set Analysis mensal ou seleção incompatível = `BLOCKED_OR_INCONCLUSIVE`, sem apagar evidências.

Não iniciar T25/T26; não tratar política D2/P5 visual como aprovada; não promover `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED` ou `PRODUCTION_APPROVED=False`. Nenhum merge sem autorização específica, nem alteração na `main` ou nos dados.
