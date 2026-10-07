# Fase II — Conversão — Evidência integral — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** II — Conversão  
**Status:** CONCLUÍDA — T01–T06 PASS

## FATO VERIFICADO

A conversão integral DBC → DBF temporário → CSV UTF-8 foi executada localmente com `tools/dbc_to_csv.py`.

Resultados:

- RD: 36/36 arquivos convertidos, 566.672 registros, 113 campos em 36/36;
- LT: 36/36 arquivos convertidos, 35.518 registros, 28 campos em 36/36;
- ST: 36/36 arquivos convertidos, 220.390 registros;
- ST: 201 campos em 35/36;
- `STPB1912.dbc`: 208 campos, único arquivo com esse schema;
- manifesto de conversão: 108 linhas, 108 com `status=PASS`.

## Matriz de gates

- T01 — 108 arquivos: **PASS**;
- T03 — registros RD = 566.672: **PASS**;
- T04 — registros LT = 35.518: **PASS**;
- T05 — registros ST = 220.390: **PASS**;
- T06 — schema ST 2019-12 = 208 campos: **PASS**;
- T02 — hashes de entrada iguais ao inventário validado: **PASS**.

## Evidência final de T02

`tools/readiness_reconcile_hashes.py` foi executado contra o `resultado-aquisicao.zip` validado no Boundary 8 e retornou:

- itens no manifesto: **108**;
- DBCs locais: **108**;
- matches: **108**;
- ausentes: **0**;
- duplicados: **0**;
- divergências de hash: **0**;
- divergências de tamanho: **0**;
- extras: **0**;
- problemas no manifesto: **0**;
- veredito: **PASS**.

## Veredito

**FASE II — CONVERSÃO CONCLUÍDA.**

Os gates T01–T06 estão reconciliados. A próxima etapa autorizada é a **FASE III — EXTRAÇÃO**, conforme o Boundary 7. Nenhuma transformação dimensional, Link Table, indicador ou dashboard foi antecipado.
