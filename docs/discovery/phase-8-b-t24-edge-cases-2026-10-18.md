# Fase VIII-B — T24, exceções temporais, residentes externos e agregação regional

**Estado:** `VERSIONED_NOT_RUN`; PR Draft independente, partindo de `main@337943d5c5b77067f842902fc679dbb68db87020`. **Sem validação Windows/QlikView deste script até o momento.**

## Objetivo fechado e evidências reutilizadas

Verificar **um único recorte regional anual**, usando o QVW TEMP reconciliado do PR #110 (`SAD_VIII_T24_ANNUAL_TEST.qvw`) e **três resultados de indisponibilidade** para T24 pontual. Reutilizar os resultados anteriores sem repetição: PR #110 T24 anual 5/5 candidato; PR #111 T24 parcial 3/3 e guardas pré-dispatch D2/P5 4/4, todos **PASS locais reportados**, sem homologação geral. Nenhum merge é implícito por este histórico.

Oráculos independentes **F3 gerados em etapa anterior**, sem regenerar CSVs: `F3_componentes_residencia_ano.csv`, `F3_cenarios_multimunicipais.csv`, `F3_residentes_externos_ano.csv`, com SHA-256 individual conferido em `manifest_F3.json`. Os campos foram confirmados no gerador histórico `tools/preflight_f3_denominadores_ibge.py` (commit congelado PR #83). O sucesso exige que o QVW TEMP de origem mantenha o SHA-256 **`7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`**, reportado no PR #111. O QVW não é fonte dos valores de referência independentes.

Contrato semântico V2: T24 = 1.000 × internações elegíveis por município de **residência** / população anual **uma vez por município×ano**; fonte SIH/RD de atendimentos processados na PB. KPI pontual sem ano, ou misturando dois anos, é indisponível. Residentes externos não recebem POP PB inventada. Dois municípios formam um agregado pela soma de componentes antes da razão, nunca média simples das taxas.

## Escopo, oráculos, limites

| Caso | Contrato de teste | Critério restrito |
| --- | --- | --- |
| `JP_CG_RES_2018` | Seleção COM `PERIODO_ANO=2018` e `RES_COD_DATASUS_6` em `250400,250750`; F3 componentes + F3 cenário `JP_CG_2` | 61.616 internações e 1.207.795 residentes anuais nos oráculos; componentes Qlik exatamente iguais e taxa com erro absoluto até 1e-6 por mil |
| `NO_PERIOD_POINT_KPI` | `ClearAll()`, sem ano/competência selecionados | Motivo `UNAVAILABLE_NO_REFERENCE_PERIOD`; **não executar KPI** |
| `MULTI_YEAR_POINT_KPI` | Selecionar anos 2018 e 2019 no QVW TEMP | Motivo `UNAVAILABLE_MULTI_YEAR`; **não somar população nem executar KPI** |
| `EXTERNAL_RESIDENT_F3` | F3 externo: 5.067 internações elegíveis em 2017–2019 com `denominador_populacao` vazio e status `FORA_DA_REFERENCIA_PB_INDISPONIVEL` | Motivo `UNAVAILABLE_POP_EXTERNAL_PB`; **teste de oráculo/contrato apenas, sem seleção COM externa** |

As linhas de residentes externos não equivalem a zero de demanda ou POP zero: representam numeradores existentes **sem denominador estadual PB apropriado**. A dimensão municipal do painel técnico contém a referência PB; este subgate **não prova uma seleção externa na interface**.

**Limites importantes:** as duas indisponibilidades temporais são decisões do wrapper de teste baseadas em `GetSelectedCount`/estado COM; não existem ainda objetos de KPI com `Calculation Condition`/avisos de indisponibilidade homologados. Não testar/aprovar P5 completo, D2 UI, filtragem combinada, universo fora da PB em objeto final, séries anuais, T25/T26, cobertura CNES/LT, Fase IX ou produção. Os testes rejeitam cálculo de KPI nas condições indisponíveis, mas **não** validam automaticamente toda a lógica de apresentação do PAINEL.

## Invariantes físicos e artefatos

**Único script versionado novo:** `tools/Invoke-SadPhaseViiiT24EdgeCases.ps1`. Reusa proteção SHA do executor do PR #111, conferindo os 22 QVDs (10 + 12), os QVWs canônicos opcionais existentes e o QVW TEMP de origem antes/depois. Executa apenas `OpenDoc` em uma **cópia em pasta nova de %TEMP%**, seleções COM, `Evaluate`, leituras de três CSV F3 e exportação de CSVs de evidência temporários. **Não há `Reload`, `Save`, `Store`, QVD novo, script QVS novo ou modificação em QVW canônico.**

**STOP contratual:** `PASS_LOCAL_T24_EDGE_REGION_1_AND_UNAVAILABLE_3_CANDIDATE_ONLY` exige 1 reconciliação regional, 3 guardas restritas, hashes QVD/QVW/QVW de origem preservados e ausência de exceções. Se parser, referência, seleção, razão ou SHA falhar, classificar `BLOCKED_OR_INCONCLUSIVE` e parar com os logs/csv sob TEMP. A prova na máquina do responsável deve informar commit e SHA do executor. Não replicar teste anual ou mensal sem drift.

## Instruções Windows — somente após verificação do parser

A partir da raiz do clone local, em branch sem mudanças nos artefatos versionados:

```powershell
git fetch origin
git switch --track origin/test/phase-viii-t24-edge-cases-20261018
git rev-parse HEAD

$tokens=$null; $parseErrors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path .\tools\Invoke-SadPhaseViiiT24EdgeCases.ps1).Path,
    [ref]$tokens,
    [ref]$parseErrors
)
if($parseErrors.Count -gt 0){
    $parseErrors | ForEach-Object {$_.ToString()}
    throw "PARSER=BLOCKED"
}
"PARSER=PASS"
```

Se o parser passar, garantir a presença das fontes históricas sem regenerar os arquivos:

```powershell
$source=Join-Path $env:TEMP "SAD_VIII_T24_75a70372567b46bc9bd9cb070e6c4bac\SAD_VIII_T24_ANNUAL_TEST.qvw"
$f3=Join-Path $env:TEMP "sad-f3-20261014-194242"

powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiT24EdgeCases.ps1 `
    -Root (Get-Location).Path -SourceQvw $source -F3Dir $f3 -RunQlik
```

**Não há PASS até receber execução real Windows**; após qualquer falha, STOP e diagnóstico. Não usar `git clean` sobre os QVWs históricos locais não rastreados.

**Pendências inalteradas:** `T24_GENERAL=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T25_T26=NOT_TESTED`; `PRODUCTION_APPROVED=False`. PR permanece Draft; sem merge, Fase IX fechada.
