# Fase VIII-B — piloto experimental T26 2018: internações por leito SUS médio observado

**Estado:** `VIII_B_T26_OBSERVED_2018=BLOCKED_RUNTIME_RESERVED_ERROR_VARIABLE; FIX_VERSIONED_PENDING_WINDOWS_RETEST`. Branch separada, originada de `main@337943d5c5b77067f842902fc679dbb68db87020`, sem merge e sem modificação na `main`.

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

## 6. Primeira execução local: bloqueio PowerShell após oráculos F1/F2/F3 (18/10/2026)

**Evidência reportada pelo responsável:** Windows PowerShell e QlikView 12, branch `test/phase-viii-b-t26-observed-lt-2018-20261018`, **HEAD efetivamente executado** `2469fe8083b1a39b170743e9b4bd703cdf9eb39a`. No mesmo bloco fail-closed, após `git fetch` e `git switch --track`, `PARSER=PASS` foi realmente emitido. Executor: SHA-256 `669C3C5663218F3A57E36BC4F4E54C9979FD9FCC005B9A42CDCC0EF71D9A1970`. Fonte QVW T24 TEMP: SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`. Evidências locais somente no PC (não reabertas aqui): `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_T26_OBS_52f9d052927e44e1981462b13fc5429e`.

**Oráculos F1/F2/F3, hashes declarados no stdout do runner:**
- `F1_servico_competencia.csv`: `A08A0812EC7E30D46014423C3C85B5B2846BD4E3451859D10FA6945D8E7763D1`.
- `F1_servico_ano.csv`: `EDE0F700887262B47A510D931A459C6B712AC6B8464C777C387029FDABC12A00`.
- `F2_lt_municipio_competencia_observado.csv`: `DC0FAE8646F6570F5DEEAF8A1597EA5ED90A5BD9A881A40B4DCA0E30380E953D`.
- `F2_lt_municipio_ano_cobertura_candidata.csv`: `97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D`.
- `F3_componentes_servico_ano.csv`: `6AE088266F4CCABC885FE04E890FD99921A8076BAEB930AA6FF518816137257D`.

**Referências confirmadas no preflight, não nos KPIs:**

| Município de serviço, ano 2018 | F1 internações elegíveis | F2 soma de 12 snapshots para cálculo da média | Escopo |
|---|---:|---:|---|
| João Pessoa (`250750`) | 73.105 | 28.106 | `HOSPITAL_SCOPE=NOT_VERIFIED` |
| Campina Grande (`250400`) | 46.752 | 16.592 | `HOSPITAL_SCOPE=NOT_VERIFIED` |

**Bloqueio:** `VERDICT=BLOCKED_OR_INCONCLUSIVE Não é possível substituir a variável Error porque ela é somente leitura ou constante.` O erro é apontado na linha 228 do runner: `$error=[Math]::Abs([decimal]($actualRatio-$expectRatio))`. PowerShell interpreta `$error` como a variável automática reservada `$Error`, independentemente da capitalização. A tentativa falhou após conferir F1/F2/F3 e antes de reconciliar o primeiro caso anual e o caso parcial. **Não atribuir PASS às taxas T26**; `T26_ANNUAL_2_CASES=NOT_PASSED`; `T26_PARTIAL_1_CASE=NOT_RUN`.

**Integridade reportada após bloqueio:** `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`; `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`; `SOURCE_T24_QVW_SHA256_UNCHANGED=True`; `MODE=TEMP_COPY_NO_RELOAD QVD_WRITES=0 CANONICAL_QVW_WRITES=0`. O wrapper do usuário emitiu `T26_EXECUTION=BLOCKED` após falha do executor. CSVs e QVW binário de teste não foram inspecionados independentemente neste ambiente.

**Correção pontual versionada:** commit `de26240ade3ec1b2a713842b1348fb21d6f06440`, substitui exclusivamente as **três referências** PowerShell `$error` por `$ratioError` (atribuição do erro absoluto; comparação de tolerância `1e-6`; campo de evidência `AbsoluteError`). Fórmulas T26, oráculos, janelas e hashes de QVD/QVW não foram alterados. A correção foi inspecionada no Git, **ainda não foi testada no Windows**.

**Próximo passo delimitado:** conferir novo HEAD da mesma branch, validar parser real e tentar `-RunQlik` **uma vez** com o mesmo QVW TEMP original e os manifestos locais F1/F2/F3. Se outra falha ocorrer, preservar stdout/CSV e interromper antes de novo ajuste. Não repetir T24 ou T25, nem avançar para outro gate.

**Estado após documentação:** `VIII_B_T26_OBSERVED_2018=FIX_VERSIONED_PENDING_WINDOWS_RETEST`; `T26_GENERAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `T29_HISTORICAL=NOT_APPROVED`; `PRODUCTION_APPROVED=False`; PR #114 permanece Draft, sem merge e sem Fase IX.
