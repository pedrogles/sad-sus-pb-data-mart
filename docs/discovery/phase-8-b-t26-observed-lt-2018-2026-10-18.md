# Fase VIII-B — piloto experimental T26 2018: internações por leito SUS médio observado

**Estado:** `VIII_B_T26_OBSERVED_2018=VERSIONED_NOT_EXECUTED`. Branch separada, originada de `main@337943d5c5b77067f842902fc679dbb68db87020`, sem merge e sem modificação na `main`.

## 1. Escopo, fonte de verdade e condição de parada

**Objetivo único:** reconciliar o candidato **T26**, internações processadas por leito SUS médio mensal no papel territorial **município de serviço**, para **João Pessoa (250750)** e **Campina Grande (250400)** em **2018**, e uma janela parcial **João Pessoa, competência 201801**. Nunca denominar T26 de taxa de ocupação hospitalar, incidência clínica ou pacientes únicos. `IDENT=5` (continuidade) não acrescenta internação.

Contrato V2 aprovado **somente semanticamente**, §62.1–62.9: `T26_anual = internações RD elegíveis no serviço em 2018 / (soma dos 12 snapshots LT observados QT_SUS / 12)`; `T26_parcial_jan = internações elegíveis na competência 201801 / snapshot LT QT_SUS de 201801`. Todos os componentes se referem ao mesmo município de serviço e à competência administrativa de RD/LT. Não anualizar janeiro; não usar POP em T26; não somar capacidade mensal como estoque anual.

**Fatos verificados em repositório:** o piloto T25 no PR #113 Draft terminou com `PASS_LOCAL_T25_OBSERVED_LT_2_ANNUAL_24_MONTHS_1_PARTIAL_CANDIDATE_ONLY`, segundo stdout Windows relatado e documentação da branch; F2/LT 2018 tinha doze meses observados nesses dois municípios. Isso **não** valida o numerador de internações no papel serviço para T26, nem um escopo estritamente hospitalar. A `main` contém QVS técnico de constelação e `current-state.md` ainda registra o estado anterior; resultados de PR Draft são evidência **da branch**, não decisões integradas à `main`.

## 2. Oráculos independentes — não regenerar

A partir do pré-processamento histórico congelado no PR #83, e de manifestos já criados fora do Git:

| Fonte de referência | Arquivo | Uso |
| --- | --- | --- |
| SIH/RD F1 | `F1_servico_ano.csv` e `F1_servico_competencia.csv` | 2018 internações elegíveis com `MUNIC_MOV` por município de **serviço**, `IDENT=1`; conferência dos 12 componentes mensais contra ano e continuidade `IDENT=5` |
| CNES/LT F2 | `F2_lt_municipio_competencia_observado.csv` e `F2_lt_municipio_ano_cobertura_candidata.csv` | Verificar 12 competências `201801..201812` com linhas observadas, `QT_SUS` e `universo=LT_TODOS_REGISTROS_VALIDOS_RN21`; somar somente para obter a **média /12** |
| Controle cruzado F3 | `F3_componentes_servico_ano.csv` | Corroborar os componentes de internação do papel serviço, soma auditável LT, estado de cobertura e divisor candidato 12; **POP não entra no denominador T26** |

Todos os cinco CSVs são somente lidos e seus SHA-256 verificados contra `manifest_F1_F2.json` ou `manifest_F3.json`. O F1 é independente do Qlik (RD original), e o F2 é independente do Qlik (LT original); F3 é cruzamento de controle derivado desses oráculos, não uma segunda prova totalmente independente.

**Fail-closed:** exigir 12 meses distintos com linhas F1 e F2; `registros_rd = internacoes_elegiveis + continuidades_ident5` no F1; `linhas_lt > 0` e `qt_sus >= 0` no F2 mensal; 12/12, situação `12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED`, escopo `LT_TODOS_REGISTROS_VALIDOS_RN21`, `hospitalar_historico_validado=NAO`, F3 `12_MESES_LINHAS_ESCOPO_NAO_VERIFICADO`; soma anual F1 = 12 meses F1 = F3 serviço; soma mensal F2 = controle anual F2 = auditoria F3; denominador médio total positivo. Mês sem linha LT **não é zero demonstrado**.

Nenhuma quantidade T26 foi presumida; o executor lê os valores reais dos cinco arquivos no Windows.

## 3. Matriz experimental e interpretação

| Caso | Seleção QlikView 12 (somente QVW descartável) | Critério |
| --- | --- | --- |
| `T26_ANNUAL_SERVICE_2018` João Pessoa | `PERIODO_ANO=2018`, `SERV_COD_DATASUS_6=250750`, competência livre | `Sum(QTD_INTERNACAO)` exatamente F1 elegível; `Sum(QTD_LEITOS_SUS)` exatamente soma auditável F2 (não leitos anuais); razão `12×N/SomaSnapshot` = F1/F2 com tolerância absoluta ≤ 1e-6 |
| `T26_ANNUAL_SERVICE_2018` Campina Grande | Idem com `SERV_COD_DATASUS_6=250400` | Mesmos testes |
| `T26_JP_201801_PARTIAL` João Pessoa | Ano 2018, competência `201801`, serviço `250750` | Internações F1 de janeiro e snapshot F2 de janeiro exatos; razão `N_jan/QT_SUS_jan` com tolerância ≤ 1e-6; rótulo `MONTH_201801_NOT_ANNUAL` |

Os testes são apenas para `LT_TODOS_REGISTROS_VALIDOS_RN21`, com cobertura de **linhas observadas**, não aceitação de cobertura dos hospitais nem pareamento clínico entre internação e leito. Cenários de filtros P5 **B/R/I**, escopo hospitalar histórico, 2017/2019, outras cidades, ocupação real, KPI temporal ambíguo e validação visual permanecem fora deste gate. Filtros incompatíveis selecionados são rejeitados apenas em contexto experimental; isso **não aprova mecanismos de proteção do painel**.

## 4. Executor, integridade e procedimento Windows

**Único script novo:** `tools/Invoke-SadPhaseViiiT26ObservedLt2018.ps1`. Adaptação focalizada dos guardrails já existentes do T25. A origem é **o mesmo QVW experimental anual T24** sob `%TEMP%`, SHA-256 obrigatório `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`. Somente uma cópia nova desse QVW é aberta via COM; não executar `Reload`, `Save`, `Store` nem alterar arquivos originais. Hash dos 22 QVDs (10/12), QVWs canônicos disponíveis e QVW TEMP de origem antes/depois; CSVs de prova apenas em novo diretório `%TEMP%`.

**Critério de STOP:** um único teste local `-RunQlik` depois de parser real `PASS`, sem repetição automática. `VERDICT=PASS_LOCAL_T26_OBSERVED_LT_2_ANNUAL_1_PARTIAL_CANDIDATE_ONLY` **somente após** dois anuais, um parcial e hashes finais inalterados. Em erro de parser, F1/F2/F3, seleção COM, denominador, cálculo ou integridade física: `BLOCKED_OR_INCONCLUSIVE`, preservar saída/CSV e encerrar sem T26 geral.

### Inicialização e validação de parser (um só bloco fail-closed)

```powershell
git fetch origin
git switch --track origin/test/phase-viii-b-t26-observed-lt-2018-20261018
git rev-parse HEAD

& {
    $ErrorActionPreference='Stop'
    $p=(Resolve-Path .\tools\Invoke-SadPhaseViiiT26ObservedLt2018.ps1).Path
    $tokens=$null; $errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $p,[ref]$tokens,[ref]$errors
    )
    if($errors.Count -gt 0){
        $errors | ForEach-Object { Write-Output $_.ToString() }
        throw 'PARSER=BLOCKED'
    }
    Write-Output 'PARSER=PASS'
}
```

**Se e somente se o parser acima concluir sem erro e o HEAD corresponder ao PR Draft**, executar uma única tentativa com:

```powershell
$source=Join-Path $env:TEMP 'SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac\SAD_VIII_T24_ANNUAL_TEST.qvw'
$f1=Join-Path $env:TEMP 'sad-f1-f2-20261014-191743'
$f3=Join-Path $env:TEMP 'sad-f3-20261014-194242'

powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiT26ObservedLt2018.ps1 `
    -Root (Get-Location).Path -SourceQvw $source -F1F2Dir $f1 -F3Dir $f3 -RunQlik
```

**Não declarar parser/QlikView PASS antes da execução real no Windows.** Não reutilizar a validação do T25 como prova de T26.

## 5. Estados preservados

`T26_GENERAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `PRODUCTION_APPROVED=False`. O T25 anterior segue PASS **local candidato restrito**, T24 não é aprovado globalmente, Fase IX não foi iniciada. Sem merge/deleção de branches nem mudança estrutural sem autorização.
