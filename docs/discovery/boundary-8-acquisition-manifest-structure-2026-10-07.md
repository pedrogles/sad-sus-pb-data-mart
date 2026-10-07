# Boundary 8 — Estrutura do manifesto de aquisição — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Boundary:** 8 — Readiness  
**Status:** ESTRUTURA CONFIRMADA

## Artefato

Arquivo externo de evidência:

`C:\Users\pedro\Documents\SAD-SUS-PB-dados\resultado-aquisicao.zip`

Entrada usada:

`manifesto-execucao.json`

O ZIP não será versionado.

## FATO VERIFICADO

`manifesto-execucao.json` contém:

- propriedades de execução;
- `items` como objeto indexado pelo nome do DBC;
- 1 objeto por arquivo;
- campos de rastreabilidade por item.

Exemplos inspecionados:

- `RDPB1701.dbc` — checkpoint local;
- `RDPB1702.dbc` — adquirido;
- `STPB1912.dbc` — adquirido.

Campos observados em cada item:

- `fonte`;
- `competencia`;
- `url`;
- `path`;
- `status`;
- `size_bytes`;
- `sha256`;
- `remote.size`;
- `remote.modified`;
- `recorded_at_utc`;
- `content_validation`;
- `remote_checksum`.

O checksum remoto permanece `null`; o `sha256` registrado é local e serve para rastreabilidade e detecção de mudança.

## Exemplos confirmados

`RDPB1701.dbc`:

- status: `CHECKPOINT_LOCAL_TAMANHO_COMPATIVEL`;
- size: 1.078.607 bytes;
- SHA-256: `9b2a0efe5548dd80961be46daed8b69efc247780ee7478c3b387e02e8d415cec`.

`RDPB1702.dbc`:

- status: `ADQUIRIDO`;
- size: 1.017.238 bytes;
- SHA-256: `8519c3c498f451d00ec5fe1e24c669d49e8cede1763517beae54d030832aa07f`.

`STPB1912.dbc`:

- status: `ADQUIRIDO`;
- size: 249.073 bytes;
- SHA-256: `1fbb7c604d763acbe59ad31f1fb8969a2aeeaeb4579641d48ccec16441dc884c`.

## Consequência

A estrutura necessária para reconciliar os 108 arquivos está comprovada.

Foi adicionado:

`tools/readiness_reconcile_hashes.py`

O utilitário:

1. lê `manifesto-execucao.json` diretamente do ZIP;
2. exige 108 itens válidos;
3. localiza os 108 DBCs atuais na BASE;
4. recalcula SHA-256;
5. compara tamanho;
6. identifica ausentes, duplicados, divergentes e extras;
7. emite `PASS` somente com 108/108 matches.

Os relatórios são gravados em `BASE\CONVERTIDA` e permanecem fora do Git.

## Próxima ação

Executar o reconciliador no ambiente local real.
