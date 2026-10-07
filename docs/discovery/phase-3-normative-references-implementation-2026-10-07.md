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

Gate revisado após evidência empírica:

- 28 linhas;
- 28 códigos fonte únicos;
- códigos `13` e `17` não materializados, pois foram excluídos pela Portaria SAS/MS nº 384/2010;
- códigos `19`, `32` e `61`–`67` incluídos conforme atualização normativa.

## Evidência de materialização local

Execução local do materializador:

- `CARATER_ROWS=6`;
- `MOTIVO_ROWS=21` na primeira materialização, antes da correção normativa;
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

## Evidência de primeiro reload Qlik do III-C1

O primeiro reload da integração confirmou:

- Caráter de Atendimento: **PASS**;
- 6 códigos de caráter;
- 566.672 linhas RD reconciliadas;
- 0 linhas RD sem referência;
- `REF_CARATER_ATENDIMENTO.qvd` gerado.

Para Motivo de Saída/Permanência:

- 21 linhas da referência foram carregadas;
- `COBRANCA=24 → 2.4` passou;
- 566.672 linhas RD foram reconciliadas;
- **124.233 linhas RD ficaram sem referência**;
- o script interrompeu controladamente antes de gerar `REF_MOTIVO_SAIDA.qvd`.

A inspeção dos 566.672 registros RD encontrou 26 códigos distintos:

`11,12,14,15,16,18,19,21,22,23,24,25,26,27,28,31,41,42,43,51,61,62,63,64,65,66`.

A Portaria SAS/MS nº 384/2010 comprova que:

- `1.3` e `1.7` foram excluídos;
- `1.9` foi mantido/renomeado como Alta de Paciente Agudo em Psiquiatria;
- transferência para internação domiciliar passou a `3.2`;
- foram incluídos `6.1`–`6.7`.

Portanto, a primeira referência de 21 linhas estava incompleta para 2017–2019. O domínio materializado passa a representar o conjunto oficial aplicável de **28 códigos**, incluindo `32` e `67` mesmo sem ocorrência nos dados atuais, preservando o princípio já aprovado de materializar o domínio oficial completo.

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

- 28 linhas;
- 28 códigos distintos;
- somente o conjunto oficial aplicável após a Portaria SAS/MS nº 384/2010;
- ausência de códigos revogados `13` e `17`;
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
- `motivo_rows=28`;
- `motivo_unmatched_rd_rows=0`.

SIGTAP, CID-10, CNES tipo/leito, ponte DATASUS ↔ IBGE e estabelecimento histórico permanecem checkpoints posteriores da Fase III.
