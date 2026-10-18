# Fase VIII-B — piloto T25 para leitos SUS por 1.000 habitantes no universo CNES/LT observado (2018)

**Estado:** `PARSER_BLOCKED_FIRST_ATTEMPT; SYNTAX_FIX_VERSIONED_PENDING_WINDOWS_PARSER_RECHECK`. Branch independente da `main@337943d5c5b77067f842902fc679dbb68db87020`. Sem merge, sem recarga física nesta etapa.

## 1. Objetivo e decisões preservadas

**Objetivo delimitado:** comparar no QlikView 12 dois resultados anuais candidatos de **T25**, um de João Pessoa (código DATASUS `250750`) e outro de Campina Grande (`250400`) no ano de 2018, e um resultado **parcial** de João Pessoa em janeiro/2018, todos no universo **`LT_TODOS_REGISTROS_VALIDOS_RN21`**. O recorte CNES/LT observado foi autorizado para **investigação experimental** na Discovery VIII-A/PR #108, sem assumir suficiência hospitalar nem classificação `TP_UNID` histórica.

**Regra V2 §62.1–§62.7:** município de **serviço/localização**, não residência; `QTD_LEITOS_SUS` é snapshot mensal semi-aditivo. Com 12 competências distintas de 2018 observadas, `T25_anual_candidato = 1000 × (soma dos 12 totais mensais QT_SUS / 12) / POP_serviço_2018`. Para janela de um mês, `T25_parcial_candidato = 1000 × QT_SUS_da_competência / POP_serviço_2018`, rotulada **não anual**. Nunca chamar a soma dos 12 snapshots de quantidade anual de leitos, e nunca somar a população anual 12 vezes.

**FATO VERIFICADO na documentação e código-fonte:** `FATO_CAPACIDADE_LEITO.qvd` foi reportada com 35.518 linhas; o QVS experimental anual T24 já carrega `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`, a Link Table e os dois papéis municipais. Os CSV históricos F2 são gerados pelo script `preflight_f1_f2_referencias_independentes.py` do commit congelado PR #83; F3 serviços por `preflight_f3_denominadores_ibge.py`. Os formatos e nomes físicos de campos foram inspecionados nesses dois geradores. **Nenhum valor numérico de leitos para os municípios foi antecipado ou inventado**; as quantidades serão lidas dos oráculos F2/F3 devidamente hashados no Windows.

## 2. Matriz de cenários e PASS

| Cenário | Oráculo independente | Condição candidata |
| --- | --- | --- |
| T25-AN-JP-2018 | F2 `F2_lt_municipio_competencia_observado.csv` + `F2_lt_municipio_ano_cobertura_candidata.csv`; F3 `F3_componentes_servico_ano.csv` | 12/12 meses com linhas LT positivas em quantidade de linhas (quantidade de leitos SUS pode ser zero num mês observado); 12 Qlik `Sum(QTD_LEITOS_SUS)` mensais exatos; soma auditável Qlik/F2; média `sum/12`; POP F3×Qlik exata; erro absoluto da taxa até 1e-6 por mil |
| T25-AN-CG-2018 | Idêntico para `250400` | Mesmas condições; sem generalização regional |
| T25-PAR-JP-201801 | F2 mensal de `201801`, F3 POP anual JP 2018 | Qlik `Sum(QTD_LEITOS_SUS)` da competência idêntico a F2; POP anual recuperada sem multiplicação via `Sum({$<PERIODO_COMPETENCIA=>} POPULACAO_ESTIMADA)`; taxa parcial na mesma tolerância e rótulo não anual |

**Pré-aceitação F2/F3 fail-closed:** conferir SHA-256 nos manifestos `manifest_F1_F2.json` e `manifest_F3.json`; exatamente 12 competências distintas `201801..201812` por município; status `LINHAS_OBSERVADAS_NUMEROS_RECONCILIADOS`, universo `LT_TODOS_REGISTROS_VALIDOS_RN21`; inventário F2 anual `12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED`, `hospitalar_historico_validado=NAO`; F3 `12_MESES_LINHAS_ESCOPO_NAO_VERIFICADO`; somas F2 mensais, F2 anual e F3 candidato idênticas; POP anual positiva. Caso faltem linhas em qualquer mês, `BLOCKED/INCONCLUSIVE` no piloto, **nunca converter ausência em QT_SUS=0**.

**Importante:** 12 meses com linhas em dois municípios **não atestam** cobertura de todos os estabelecimentos relevantes, o universo estritamente hospitalar, nem validez de um indicador estadual. O cálculo é **candidato observacional**. Não excluir LT válida nem aplicar retroativamente rótulos da legenda 201909.

## 3. Execução planejada e invariantes

**Executor único versionado:** `tools/Invoke-SadPhaseViiiT25ObservedLt2018.ps1`. Reutiliza partes do padrão do executor #112, mas seu gate não reaproveita o PASS daquele teste. Usa somente uma **cópia nova** do QVW anual T24 em `%TEMP%`, exige o SHA já reportado `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`, confere `LINK_ANALISE.qvd` contra o baseline histórico, hashes de todos os **22 QVDs** (10+12), QVWs canônicos presentes e QVW TEMP de origem antes e depois. Sem `Reload`, `Save`, `Store` ou alterações de esquema/dados/arquivos de produção; os únicos CSVs novos são de evidência em `%TEMP%`.

**Critério de parada:** se houver parser error, divergência de oráculo/manifesto, mês ausente, componente mensal/POP divergente, exceção COM ou drift em hashes protegidos, **parar**, preservar stdout e diretório TEMP e classificar `BLOCKED_OR_INCONCLUSIVE`. Somente resultado `VERDICT=PASS_LOCAL_T25_OBSERVED_LT_2_ANNUAL_24_MONTHS_1_PARTIAL_CANDIDATE_ONLY` **após hashes finais** encerra este subgate como candidato. Nenhuma repetição automática nem execução antecipada de T26.

### Procedimento local (após publicação desta branch)

```powershell
git fetch origin
git switch --track origin/test/phase-viii-b-t25-observed-lt-2018-20261018
git rev-parse HEAD

$tokens=$null; $parseErrors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path .\tools\Invoke-SadPhaseViiiT25ObservedLt2018.ps1).Path,
    [ref]$tokens, [ref]$parseErrors
)
if($parseErrors.Count -gt 0){
    $parseErrors | ForEach-Object {$_.ToString()}
    throw 'PARSER=BLOCKED'
}
'PARSER=PASS'
```

Com `PARSER=PASS` e arquivos TEMP históricos ainda presentes:

```powershell
$source=Join-Path $env:TEMP 'SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac\SAD_VIII_T24_ANNUAL_TEST.qvw'
$f1=Join-Path $env:TEMP 'sad-f1-f2-20261014-191743'
$f3=Join-Path $env:TEMP 'sad-f3-20261014-194242'

powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiT25ObservedLt2018.ps1 `
    -Root (Get-Location).Path `
    -SourceQvw $source `
    -F1F2Dir $f1 `
    -F3Dir $f3 `
    -RunQlik
```

**T25 será testado apenas no Windows do responsável.** Os QVW, CSVs originais e logs não foram recebidos em anexo nem inspecionados fisicamente neste ambiente. `PARSER=PASS` é uma validação a realizar no Windows — inspeção do código no GitHub não substitui.

## 4. Limitações e gates não promovidos

`T25_GENERAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `T26=NOT_TESTED`; `PRODUCTION_APPROVED=False`. Não comprova `Calculation Condition` visual, políticas de filtro P5 em objeto final, cobertura estadual nem interface completa. Fase IX permanece fechada. Não efetuar merge ou editar `main` sem autorização.

## 5. Bloqueio de parser reportado e correção de sintaxe (18/10/2026)

**Resultado observado no console Windows do responsável:** a branch `test/phase-viii-b-t25-observed-lt-2018-20261018` estava no HEAD `a27486d48dd2099f7d899af98414fe19e11f074a` quando `[System.Management.Automation.Language.Parser]::ParseFile(...)` devolveu erros, principalmente `É necessário fornecer uma expressão de valor após o operador '+'`, com token `mun+'/'+$period` inesperado nas linhas 236, 246 e 247. Foi emitido `PARSER=BLOCKED` por `throw`. A posterior linha `PARSER=PASS` foi executada manualmente, separada do bloco anterior, **sem executar outro parser**; não representa êxito. **Estado inequívoco do teste:** `PARSER=BLOCKED`; `T25_QV_COM=NOT_RUN`; `T25_ANNUAL_2_CASES=NOT_RUN`; `T25_MONTHLY_24_COMPONENTS=NOT_RUN`; `T25_PARTIAL_1_CASE=NOT_RUN`.

**Causa identificada diretamente no script versão testada:** três concatenações PowerShell usam o texto `'+mun+'/'+$period` em vez de `'+$mun+'/'+$period`. As mensagens de falta de `}`, `catch` e `finally` são erros de recuperação do parser após os tokens inválidos, sem evidência de que esses blocos estejam realmente ausentes.

**Correção mínima versionada** no commit `0e6db80441098f3990ca906a6c36067986ee6170`: substituídas as **3 ocorrências**, sem alterar os oráculos, a definição de T25, a seleção municipal, a taxa, a regra de 12 competências, o tratamento de zero/ausência, o inventário físico ou os guardrails SHA. O novo commit foi apenas inspecionado estaticamente, **não há `PARSER=PASS` real confirmado para ele**. O PowerShell 5.1/Windows QlikView não está disponível neste ambiente de revisão.

**Integridade e escopo:** o script foi interrompido antes de iniciar; como só ocorreu validação sintática, `QVD_QVW_WRITE_BY_T25=False`. Nenhum SHA pós-execução foi produzido por este novo gate, portanto não registrar falsamente `ORIGINAL_22_QVD_SHA256_UNCHANGED=True` como resultado desta tentativa. Os testes anteriores são evidências históricas independentes.

**Próximo passo único:** `git pull --ff-only` na mesma branch, confirmar HEAD e rodar novamente o **parser real**. Imprimir `PARSER=PASS` **apenas dentro do ramo de sucesso** e só então permitir exatamente uma execução `-RunQlik` usando os mesmos oráculos F2/F3 e QVW TEMP de origem. Se qualquer erro de parser reaparecer, STOP antes do QlikView. Se houver divergência em runtime, registrar stdout/evidências e parar, sem repetir automaticamente.

**Gates preservados:** `T25_GENERAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `T26=NOT_TESTED`, `PRODUCTION_APPROVED=False`. PR #113 Draft, sem merge, Fase IX fechada.
