# Fase III-C1 — Referências normativas pequenas — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-C1 — Caráter de Atendimento + Motivo de Saída/Permanência  
**Status:** MATERIALIZAÇÃO LOCAL PASS; INTEGRAÇÃO QLIK IMPLEMENTADA; RELOAD LOCAL PENDENTE

## Estado de entrada

Após os Checkpoints III-A e III-B:

- SIH/RD, CNES/LT e CNES/ST: PASS;
- IBGE população 2017–2019: PASS;
- `BASE/REFERENCIAS`: diretório existente e sem arquivos.

## FATO VERIFICADO — fontes oficiais

A Portaria SAS/MS nº 719/2007 define:

- a tabela auxiliar completa de Caráter de Atendimento, códigos `01`–`06`;
- a tabela auxiliar de Motivo de Saída/Permanência.

A Portaria SAS/MS nº 384/2010 é mantida como referência normativa complementar para o domínio de motivo de saída/permanência.

Estas referências já estavam fechadas no Boundary 4.

## Implementação

Foi adicionado:

`tools/materialize_normative_references.py`

O script não baixa bases externas. Ele materializa somente os pequenos domínios normativos já aprovados, em UTF-8 com separador `;`.

Saídas locais, ignoradas pelo Git:

- `BASE/REFERENCIAS/carater_atendimento.csv`;
- `BASE/REFERENCIAS/motivo_saida_permanencia.csv`;
- `BASE/REFERENCIAS/manifesto_referencias_normativas.json`.

## Contratos locais

### Caráter de atendimento

Campos:

- `codigo_fonte`;
- `descricao`;
- `fonte_oficial`.

Gate:

- 6 linhas;
- 6 códigos únicos;
- códigos `01`–`06`.

### Motivo de saída/permanência

Campos:

- `codigo_fonte`;
- `codigo_normativo`;
- `descricao`;
- `grupo`;
- `fonte_oficial_719`;
- `fonte_oficial_384`.

O `codigo_fonte` preserva a forma usada no SIH/RD sem ponto, por exemplo `24`.  
O `codigo_normativo` preserva a forma normativa, por exemplo `2.4`.

Gate:

- 21 linhas;
- 21 códigos fonte únicos.

## Evidência de materialização local

Execução local do materializador:

- `CARATER_ROWS=6`;
- `MOTIVO_ROWS=21`;
- `VERDICT=PASS`.

A inspeção com leitura UTF-8 confirmou descrições e acentuação corretas.

Hashes do manifesto reconciliados localmente:

- `carater_atendimento.csv`  
  `3e40a9b2a4d0e1e65df8a9000f55af6fd24880468c12faaa24384f4722330ea8`  
  `MATCH=True`;
- `motivo_saida_permanencia.csv`  
  `887e2faee8bd820dc5c4e82c81560ecba04b939c32b848baa77be3020d0a1761`  
  `MATCH=True`.

**FATO VERIFICADO:** a materialização local do III-C1 está PASS.

## Integração QlikView implementada

O `EXTRACAO/ext_main.qvs` foi ampliado para gerar:

- `REF_CARATER_ATENDIMENTO.qvd`;
- `REF_MOTIVO_SAIDA.qvd`;
- `_CHECKPOINT_EXTRACAO_REFERENCIAS_NORMATIVAS.csv`.

Gates embutidos:

### Caráter de atendimento

- 6 linhas;
- 6 códigos distintos;
- somente `01`–`06`;
- reconciliação contra as 566.672 linhas do SIH/RD;
- 0 linhas RD sem referência.

### Motivo de saída/permanência

- 21 linhas;
- 21 códigos distintos;
- `COBRANCA=24` mapeado exatamente uma vez para `2.4`;
- reconciliação contra as 566.672 linhas do SIH/RD;
- 0 linhas RD sem referência.

O checkpoint continua `PASS_PARTIAL`, pois outras referências auxiliares ainda permanecem pendentes.

## Próximo gate

Executar novo reload local de `EXTRACAO/EXT.qvw` e exigir:

- os dois QVDs normativos gerados;
- checkpoint normativo gerado;
- `carater_rows=6`;
- `carater_unmatched_rd_rows=0`;
- `motivo_rows=21`;
- `motivo_unmatched_rd_rows=0`.

SIGTAP, CID-10, CNES tipo/leito, ponte DATASUS ↔ IBGE e estabelecimento histórico permanecem checkpoints posteriores da Fase III.
