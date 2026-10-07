# Boundary 8 — Evidência de versão do QlikView — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Boundary:** 8 — Readiness  
**Status:** PASS

## Comando

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\tools\readiness_check.ps1 `
  -OutputPath ".\readiness-report.json"
```

## Resultado

O checker retornou:

- `LOCAL_PREFLIGHT_PASS`;
- `blocking_count = 0`;
- `R15 — QlikView major version: PASS`;
- versão observada: **12.0.20000.0**.

Executável:

`C:\Program Files\QlikView\Qv.exe`

## FATO VERIFICADO

O ambiente local está usando **QlikView major version 12**.

Esse item deixa de ser blocker do Boundary 8.

## Estado após R15

Já comprovados:

- Windows;
- Python 3.14.8;
- virtualenv;
- bibliotecas DBC/DBF;
- 108 DBCs;
- IBGE 2017–2019;
- QlikView 12;
- DBC → DBF → CSV UTF-8;
- CSV → QlikView;
- `Must_Include`;
- include aninhado;
- QVD STORE;
- `Qv.exe /r`;
- protótipo Link Table sem synthetic key/circular reference visível.

Ainda pendentes antes do GO:

- reconciliar os hashes locais dos 108 DBCs com a evidência de aquisição;
- validar explicitamente o caminho de falha do batch, se mantido como gate;
- materializar/tratar explicitamente as referências auxiliares necessárias.

## Próxima ação

Localizar e inspecionar o artefato de aquisição que contém o manifesto final dos 108 DBCs, sem reconstruir hashes a partir de chat ou memória.
