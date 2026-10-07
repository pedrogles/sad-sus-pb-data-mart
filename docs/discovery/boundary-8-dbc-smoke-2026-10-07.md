# Boundary 8 — Evidência de DBC Smoke — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Boundary:** 8 — Readiness  
**Status do teste:** PASS

## Comando executado

```powershell
.\.venv\Scripts\python.exe .\tools\readiness_dbc_smoke.py
```

## Resultado observado

```text
RDPB1702.dbc: PASS records=13912 fields=113
LTPB1712.dbc: PASS records=1033 fields=28
STPB1701.dbc: PASS records=5692 fields=201
STPB1912.dbc: PASS records=6438 fields=208
VERDICT=PASS
```

Relatório local gerado em:

`BASE\CONVERTIDA\readiness-smoke\readiness-dbc-smoke-report.json`

O relatório e os arquivos convertidos são artefatos derivados locais e não devem ser versionados.

## FATO VERIFICADO

A toolchain planejada:

```text
DBC
 ↓
DBF
 ↓
CSV UTF-8
```

funcionou no ambiente local real usando:

- Python 3.14.8;
- `dbc-to-dbf==1.0.1`;
- `dbfread==2.0.7`.

Os checkpoints reproduziram as evidências do Boundary 3:

| Arquivo | Registros observados | Campos observados | Resultado |
|---|---:|---:|---|
| `RDPB1702.dbc` | 13.912 | 113 | PASS |
| `LTPB1712.dbc` | 1.033 | 28 | PASS |
| `STPB1701.dbc` | 5.692 | 201 | PASS |
| `STPB1912.dbc` | 6.438 | 208 | PASS |

Para `STPB1912.dbc`, o smoke confirma novamente o schema especial de 208 campos.

O valor de 6.438 registros para `STPB1912.dbc` passa a ser um checkpoint operacional observado nesta execução de readiness.

## Consequência

Os seguintes itens deixam de ser blockers:

- funcionamento da biblioteca DBC;
- leitura DBF;
- geração de CSV UTF-8;
- reprodução de contagens/schema nos arquivos de smoke.

Ainda não está comprovado:

- reconciliação dos hashes locais com o manifesto de aquisição;
- leitura do CSV pelo QlikView;
- `Must_Include`;
- execução `Qv.exe /r`;
- comportamento de erro em batch;
- ausência de synthetic keys/circular references no protótipo Link Table.

## Próxima ação

Executar o smoke QlikView e inspecionar o Table Viewer.
