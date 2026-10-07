# Boundary 8 — Batch failure path — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Boundary:** 8 — Readiness  
**Status:** PASS

## FATO VERIFICADO

O caminho de falha controlada foi executado localmente com QlikView 12 via `Qv.exe /r`.

A falha proposital foi provocada pela leitura de um CSV inexistente com `SET ErrorMode=0;`.

Marcador gerado:

```text
generated_at;stage;status;errors_before;errors_after
07/10/2026 14:02:21;FAILURE_PATH;PASS_EXPECTED_ERROR_CAUGHT;0;1
```

O marcador de falha inesperada não foi criado:

```text
NOT_FOUND
```

## Resultado

- execução batch sem interação: PASS;
- erro proposital detectado: PASS;
- `ScriptErrorCount`: 0 → 1;
- fluxo controlado alcançado: PASS;
- marcador de erro não detectado: ausente, conforme esperado.

O requisito `ErrorMode=0` + checagem explícita de `ScriptErrorCount` está validado no ambiente local.

## Impacto no Boundary 8

O caminho de falha de batch deixa de ser blocker.

Após esta evidência, permanece como pendência de readiness o fechamento da disponibilidade ou do tratamento explícito das referências auxiliares necessárias para a primeira implementação.
