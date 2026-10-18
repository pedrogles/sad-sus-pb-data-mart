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
