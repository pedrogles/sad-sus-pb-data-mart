# Boundary 8 — Evidência de QlikView Smoke — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Boundary:** 8 — Readiness  
**Status do teste:** PASS COM UMA PENDÊNCIA DE VERSÃO

## Execução observada

O smoke foi executado por linha de comando com:

```powershell
Start-Process `
  -FilePath $env:QLIKVIEW_EXE `
  -ArgumentList @(
    "/r",
    "$PWD\tools\READINESS.qvw"
  ) `
  -Wait
```

Após o reload, foram produzidos:

```text
readiness_smoke.qvd                 1764 bytes
readiness_smoke_success.csv           87 bytes
readiness_link_table_success.csv      80 bytes
```

Conteúdo do marcador principal:

```text
generated_at;stage;status;csv_rows
07/10/2026 13:04:58;READINESS_SMOKE;PASS;13912
```

Conteúdo do marcador da Link Table:

```text
generated_at;stage;status
07/10/2026 13:04:58;LINK_TABLE_SMOKE;SCRIPT_PASS
```

## FATO VERIFICADO — CSV → QlikView

O `READINESS.qvw` carregou o CSV produzido a partir de `RDPB1702.dbc` e confirmou:

**13.912 linhas**

Esse valor coincide com o checkpoint do Boundary 3 e com o smoke DBC.

Status:

**PASS**

## FATO VERIFICADO — Must_Include

O `READINESS.qvw` usa:

```text
$(Must_Include=readiness_smoke.qvs);
```

O script `readiness_smoke.qvs` inclui, por sua vez:

```text
$(Must_Include=readiness_link_table_smoke.qvs);
```

Como os marcadores dos dois scripts foram emitidos, tanto o include principal quanto o include aninhado foram executados com sucesso.

Status:

**PASS**

## FATO VERIFICADO — QVD STORE

O arquivo:

`tools\readiness_smoke.qvd`

foi gerado com 1.764 bytes durante o reload.

Status:

**PASS**

## FATO VERIFICADO — Qv.exe /r

O reload por `Qv.exe /r` concluiu e retornou ao PowerShell, produzindo os artefatos esperados.

Status:

**PASS**

A execução observada não apresentou falha de script que impedisse a emissão dos marcadores de sucesso.

## FATO VERIFICADO — protótipo da Link Table

O Table Viewer apresentado após o smoke mostra:

- `FATO_INTERNACAO_SMOKE`;
- `FATO_CAPACIDADE_SMOKE`;
- `FATO_POPULACAO_SMOKE`;
- `LINK_ANALISE_SMOKE`;
- dimensão de estabelecimento;
- dimensão de ano;
- dimensão municipal de residência;
- dimensão municipal de serviço.

As três fatos se associam através de `%LINK_KEY` ao eixo físico representado por `LINK_ANALISE_SMOKE`.

As dimensões compartilhadas se associam à Link Table pelas chaves técnicas correspondentes.

### Synthetic keys

Nenhuma tabela `$Syn` está visível no Table Viewer.

Status:

**PASS no protótipo mínimo.**

### Circular references

O grafo exibido é acíclico e não mostra loop entre as tabelas do protótipo.

Status:

**PASS no protótipo mínimo.**

## FATO VERIFICADO — separação de papéis municipais

O Table Viewer mostra duas tabelas municipais distintas:

- residência;
- serviço.

Os campos descritivos aparecem separados por papel e não geram associação descritiva adicional.

Status:

**PASS no protótipo mínimo.**

## PENDÊNCIA

A execução comprova que um QlikView funcional está presente e que o reload funciona.

Ainda é necessário registrar explicitamente a versão principal do executável como **12.x** através do checker atualizado (`R15`).

Não inferir a versão apenas pelo sucesso do smoke.

## Impacto

Deixam de ser blockers:

- CSV → QlikView;
- `Must_Include`;
- include aninhado;
- QVD STORE;
- `Qv.exe /r`;
- protótipo mínimo da Link Table;
- synthetic keys no protótipo;
- circular references no protótipo.

Ainda permanecem para o GO:

- R15 — confirmar QlikView 12.x;
- reconciliar hashes locais com o manifesto de aquisição;
- materializar/tratar explicitamente as referências auxiliares necessárias;
- fechar qualquer teste de erro em batch que o readiness considerar obrigatório.

## Veredito desta evidência

**PASS COM UMA PENDÊNCIA DE VERSÃO**
