# Boundary 8 — Evidência do Preflight Local — 07/10/2026

O preflight local foi executado no workspace Windows do projeto.

Resultado:

- `LOCAL_PREFLIGHT_PASS`;
- `blocking_count = 0`.

## FATO VERIFICADO

Passaram:

- Windows host;
- Python **3.14.8**;
- `.venv`;
- `dbc-to-dbf==1.0.1`;
- `dbfread==2.0.7`;
- imports Python;
- QlikView encontrado em `C:\Program Files\QlikView\Qv.exe`;
- diretório `BASE`;
- RD **36/36**;
- LT **36/36**;
- ST **36/36**;
- IBGE 2017, 2018 e 2019: **1 arquivo por ano**;
- proteção de dados/QVD no `.gitignore`.

Espaço livre observado:

**74,07 GB** em `C:\`.

## Impacto

O blocker R07 foi resolvido.

O Boundary 8 permanece aberto porque ainda precisam ser validados:

- DBC → DBF/CSV com a toolchain planejada;
- reconciliação de contagem/schema em smoke test;
- leitura CSV no QlikView;
- `Must_Include`;
- `Qv.exe /r`;
- tratamento de erro em batch;
- protótipo mínimo da Link Table;
- materializações auxiliares necessárias.

## Próximo teste

Executar:

```powershell
.\.venv\Scripts\python.exe .\tools\readiness_dbc_smoke.py
```

O teste utiliza checkpoints documentados no Boundary 3:

- `RDPB1702.dbc`: 13.912 registros / 113 campos;
- `LTPB1712.dbc`: 1.033 registros / 28 campos;
- `STPB1701.dbc`: 5.692 registros / 201 campos;
- `STPB1912.dbc`: 208 campos.
