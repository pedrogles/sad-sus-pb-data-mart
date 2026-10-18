# Fase VIII-B — T24 anual, ensaio isolado

**Estado:** `VERSIONED_NOT_RUN`. Nenhum resultado QlikView do piloto foi executado ou validado neste registro.

## Objetivo e limites

Testar T24 — internações de residentes por 1.000 habitantes — em cinco recortes anuais, usando a fato `QTD_INTERNACAO`, a população anual IBGE e o papel municipal de residência. Numerador e denominador serão comparados com os componentes independentes `F3_componentes_residencia_ano.csv` e `manifest_F3.json`. Preservar o universo SIH/RD processado na PB, sem confundir `IDENT=5` com internação nova.

| Caso | Filtro de ano | Filtro territorial | Referência |
|---|---|---|---|
| PB_2017 | 2017 | RES_UF=PB | 182.069 / 4.025.558 |
| PB_2018 | 2018 | RES_UF=PB | 181.673 / 3.996.496 |
| PB_2019 | 2019 | RES_UF=PB | 186.280 / 4.018.127 |
| JP_2018 | 2018 | RES_COD_DATASUS_6=250750 | Componentes F3 originais |
| CG_2018 | 2018 | RES_COD_DATASUS_6=250400 | Componentes F3 originais |

Aceitação experimental: 12 competências possíveis, nenhuma competência mensal selecionada, numerador e população iguais aos F3 como inteiros; taxa Qlik com erro absoluto máximo de 0,000001 por mil. Esse valor é uma **tolerância candidata apenas para o piloto**.

## Artefatos versionados

- `PAINEL/phase_viii_t24_annual_pilot.qvs`: 16 tabelas do painel técnico VII, chaves e projeção POP em memória, sem STORE ou mudança dimensional.
- `tools/Invoke-SadPhaseViiiT24AnnualPilot.ps1`: carrega um **novo QVW temporário**, lê os oráculos F3, avalia T24 via COM, captura log e hashes dos 22 QVDs e dos QVWs canônicos antes/depois. Reutiliza o executor VII já integrado como base.

O runner exige branch própria e ambos os scripts versionados. Antes da execução, validar sua sintaxe com `System.Management.Automation.Language.Parser.ParseFile`; se houver erros, **STOP** sem tentar o QlikView. Após parser PASS, executar somente sob Windows e QlikView 12 com `-RunQlik`. Os binários e logs derivados devem permanecer em `%TEMP%`, fora do Git. A branch de teste parte do commit `main@337943d5c5b77067f842902fc679dbb68db87020`.

## Condição de parada

`PASS_LOCAL_T24_ANNUAL_5_CASES_CANDIDATE_ONLY` requer cinco reconciliações, log nativo coerente, 16 tabelas sem synthetic keys/loops, e hashes QVD/QVW preservados. Qualquer divergência bloqueia o gate; não corrigir as fórmulas por conveniência nem repetir automaticamente.

**Fora do escopo:** T24 geral (mês parcial, multiano, seleção contraditória D2, P5 R/I/B, agregação regional), T25/T26, CNES histórico, Fase IX, homologação e produção. Estados preservados: `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `PRODUCTION_APPROVED=False`.

Não modificar nem recarregar QVD/QVW original, realizar merge ou iniciar dashboards.


## Tentativa local 1 — BLOCKED_RUNTIME_DECIMAL_ABS

**Fonte:** stdout Windows PowerShell encaminhado pelo responsável. Teste executado da branch `feat/phase-viii-b-t24-annual-pilot-20261018`, commit `da3d5cf28f51fe4648df162e2e28822341353d90`; runner SHA-256 `939E11FD5C9F0CF74274819E08DFC2523B358893421307C6D61416A9D446C213`; QVS SHA-256 `DF9F35D5CB02D3192D60CEB832AA7177087813ED14DD0CD0BA203A116907CF1E`.

**Parser:** `PARSER=PASS` reportado em sessão anterior à execução. **Evidência local:** `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_T24_c1bd6fa732604437b10383c71cfcece8`.

**Resultado local reportado:** `INVENTORY_22_QVD=PASS_READ_ONLY`; `F3_ORACLE_SHA256=8B9AF93015D3B2574A2424D9241FDC42FB56E86CAFA52963811BCE9D485AF622`; `VERDICT=BLOCKED_OR_INCONCLUSIVE` por `System.Decimal` sem método estático `Abs`, erro na linha 282 em `$delta=[decimal]::Abs($actualRate-$expectedRate)`. Após a falha, `ORIGINAL_22_QVD_SHA256_AND_HEADERS_UNCHANGED=True` e `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`.

**Diagnóstico restrito:** a implementação do piloto atingiu a etapa de comparação de taxa depois de criar/carregar o modelo Qlik em QVW temporário; a saída não comprova ainda reconciliação numérica de nenhum dos cinco casos. `Decimal.Abs` não é disponível no .NET Framework usado com Windows PowerShell 5.1. Não presumir erro na semântica Qlik, denominador F3, dados ou `LINK_ANALISE`. Não houve evidência de escrita nos arquivos de produção. Os arquivos temporários e logs devem permanecer preservados para auditoria se necessário.

**Correção pontual versionada** nesta mesma branch: `$delta=[Math]::Abs([decimal]($actualRate-$expectedRate))` substitui unicamente a chamada incompatível, preservando o tipo decimal, fórmula candidata, tolerância `0.000001`, oráculos, seleção e integridade. Commit de correção: `ef3041a47ba7bc1c56131a26dd334318f0a44cfd`. Este commit é **somente revisão de código**, sem PASS de parser Windows ou execução numérica nova.

**Próxima ação única:** `git pull --ff-only` na branch correta; verificar novo commit; rodar parser real do PowerShell, e **somente em `PARSER=PASS`** realizar **uma nova tentativa controlada** com `-F3Dir` e `-RunQlik`. Verificar os cinco registros e `t24_reconciliation.csv`, hash de 22 QVDs/QVWs e stdout/log nativo. Se houver nova falha, STOP, recuperar motivo e relatório; nenhuma repetição automática.

**Estado:** `VIII_B_T24_ANNUAL_PILOT=BLOCKED_FIRST_RUNTIME_ATTEMPT_NEW_FIX_UNTESTED`; `T24_5_CASES=NOT_RECONCILED`; `T25_T26=NOT_TESTED`; `P5_D2=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `PRODUCTION_APPROVED=False`. PR #110 Draft, sem merge, sem fase IX.
