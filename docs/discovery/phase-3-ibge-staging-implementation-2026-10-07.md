# Fase III — Extração — Checkpoint de staging IBGE — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-B — IBGE População 2017–2019  
**Status:** CORREÇÃO DE NORMALIZAÇÃO POPULACIONAL IMPLEMENTADA; NOVO RELOAD LOCAL PENDENTE

## FATO VERIFICADO — inspeção física dos arquivos

Arquivos localizados em `BASE/IBGE`:

- `estimativa_dou_2017.xls`;
- `estimativa_dou_2018_20181019.xls`;
- `estimativa_dou_2019.xls`.

Os três arquivos possuem a planilha:

`Municípios`

Estrutura observada:

- linha 1: título da publicação;
- linha 2: cabeçalho;
- dados municipais a partir da linha 3;
- cinco primeiras colunas úteis:
  - `UF`;
  - `COD. UF`;
  - `COD. MUNIC`;
  - `NOME DO MUNICÍPIO`;
  - `POPULAÇÃO ESTIMADA`.

Os arquivos 2018 e 2019 possuem colunas adicionais vazias/irrelevantes no UsedRange. Elas não fazem parte do contrato de staging.

## FATO VERIFICADO — universo PB já validado

O projeto já havia validado:

| Ano | Municípios PB | População estimada PB |
|---|---:|---:|
| 2017 | 223 | 4.025.558 |
| 2018 | 223 | 3.996.496 |
| 2019 | 223 | 4.018.127 |

Esses valores são usados como checkpoints obrigatórios do staging.

## Implementação

O `EXTRACAO/ext_main.qvs` foi ampliado para carregar diretamente os três XLS no QlikView.

Formato:

- `biff`;
- `table is [Municípios$]`;
- `header is 1 lines`;
- `embedded labels`.

A implementação:

1. carrega cada arquivo anual;
2. descobre os cinco primeiros nomes de campo da planilha;
3. valida os nomes esperados após `Trim()`;
4. filtra somente `UF='PB'`;
5. normaliza códigos preservando zeros à esquerda;
6. forma `COD_IBGE_7` pela concatenação dos dois componentes oficiais presentes no próprio arquivo: `COD. UF` + `COD. MUNIC`;
7. normaliza a população removendo caracteres não numéricos de apresentação;
8. preserva metadados de origem;
9. reconcilia contagens e totais anuais;
10. armazena `SRC_IBGE_POPULACAO.qvd`.

## Campos de staging

- `ANO_REFERENCIA`;
- `UF`;
- `COD_UF_IBGE_2`;
- `COD_MUNIC_IBGE_5`;
- `COD_IBGE_7`;
- `NOME_MUNICIPIO`;
- `POPULACAO_ESTIMADA`;
- `_META_SOURCE_FILE`;
- `_META_SOURCE_FAMILY`;
- `_META_SOURCE_YEAR`;
- `_META_SOURCE_PATH`.

A formação de `COD_IBGE_7` não deriva nenhum dígito a partir do código DATASUS. Ela concatena os dois componentes oficiais fornecidos pelo próprio arquivo IBGE.

## Gates embutidos

Por ano:

- 223 linhas PB;
- 223 códigos municipais distintos;
- total populacional igual ao valor validado.

No conjunto:

- 669 linhas;
- 669 combinações únicas `COD_IBGE_7 × ANO_REFERENCIA`;
- 3 anos distintos.

Saída:

`EXTRACAO/QVD/SRC_IBGE_POPULACAO.qvd`

Checkpoint parcial:

`EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_IBGE.csv`

Status esperado:

`PASS_PARTIAL`

## Evidência de primeira execução local

O primeiro reload do Checkpoint III-B confirmou novamente o PASS integral do Checkpoint III-A.

Ao iniciar o IBGE 2017, o log registrou:

- o caminho do XLS corretamente;
- a tabela BIFF como `MunicÃ­pios$`;
- erro `Cannot locate table in BIFF file`;
- `ScriptErrorList=Table Not Found`;
- interrupção controlada antes de qualquer QVD IBGE.

A inspeção física havia confirmado que a planilha real é `Municípios`. Portanto, a falha foi isolada na interpretação do literal UTF-8 acentuado do include `.qvs` pelo QlikView 12.

### Correção

Os identificadores acentuados usados pelo carregamento BIFF e pela validação dos cabeçalhos passam a ser construídos em runtime com `Chr(...)`:

- `Municípios$` → `Chr(237)`;
- `NOME DO MUNICÍPIO` → `Chr(205)`;
- `POPULAÇÃO ESTIMADA` → `Chr(199)` e `Chr(195)`.

A correção não altera arquivos fonte, campos de staging, totais esperados, granularidade ou modelagem.

## Evidência de segunda execução local

A correção de encoding BIFF funcionou: o QlikView localizou `Municípios# Fase III — Extração — Checkpoint de staging IBGE — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-B — IBGE População 2017–2019  
**Status:** CORREÇÃO DE NORMALIZAÇÃO POPULACIONAL IMPLEMENTADA; NOVO RELOAD LOCAL PENDENTE

## FATO VERIFICADO — inspeção física dos arquivos

Arquivos localizados em `BASE/IBGE`:

- `estimativa_dou_2017.xls`;
- `estimativa_dou_2018_20181019.xls`;
- `estimativa_dou_2019.xls`.

Os três arquivos possuem a planilha:

`Municípios`

Estrutura observada:

- linha 1: título da publicação;
- linha 2: cabeçalho;
- dados municipais a partir da linha 3;
- cinco primeiras colunas úteis:
  - `UF`;
  - `COD. UF`;
  - `COD. MUNIC`;
  - `NOME DO MUNICÍPIO`;
  - `POPULAÇÃO ESTIMADA`.

Os arquivos 2018 e 2019 possuem colunas adicionais vazias/irrelevantes no UsedRange. Elas não fazem parte do contrato de staging.

## FATO VERIFICADO — universo PB já validado

O projeto já havia validado:

| Ano | Municípios PB | População estimada PB |
|---|---:|---:|
| 2017 | 223 | 4.025.558 |
| 2018 | 223 | 3.996.496 |
| 2019 | 223 | 4.018.127 |

Esses valores são usados como checkpoints obrigatórios do staging.

## Implementação

O `EXTRACAO/ext_main.qvs` foi ampliado para carregar diretamente os três XLS no QlikView.

Formato:

- `biff`;
- `table is [Municípios$]`;
- `header is 1 lines`;
- `embedded labels`.

A implementação:

1. carrega cada arquivo anual;
2. descobre os cinco primeiros nomes de campo da planilha;
3. valida os nomes esperados após `Trim()`;
4. filtra somente `UF='PB'`;
5. normaliza códigos preservando zeros à esquerda;
6. forma `COD_IBGE_7` pela concatenação dos dois componentes oficiais presentes no próprio arquivo: `COD. UF` + `COD. MUNIC`;
7. normaliza a população removendo caracteres não numéricos de apresentação;
8. preserva metadados de origem;
9. reconcilia contagens e totais anuais;
10. armazena `SRC_IBGE_POPULACAO.qvd`.

## Campos de staging

- `ANO_REFERENCIA`;
- `UF`;
- `COD_UF_IBGE_2`;
- `COD_MUNIC_IBGE_5`;
- `COD_IBGE_7`;
- `NOME_MUNICIPIO`;
- `POPULACAO_ESTIMADA`;
- `_META_SOURCE_FILE`;
- `_META_SOURCE_FAMILY`;
- `_META_SOURCE_YEAR`;
- `_META_SOURCE_PATH`.

A formação de `COD_IBGE_7` não deriva nenhum dígito a partir do código DATASUS. Ela concatena os dois componentes oficiais fornecidos pelo próprio arquivo IBGE.

## Gates embutidos

Por ano:

- 223 linhas PB;
- 223 códigos municipais distintos;
- total populacional igual ao valor validado.

No conjunto:

- 669 linhas;
- 669 combinações únicas `COD_IBGE_7 × ANO_REFERENCIA`;
- 3 anos distintos.

Saída:

`EXTRACAO/QVD/SRC_IBGE_POPULACAO.qvd`

Checkpoint parcial:

`EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_IBGE.csv`

Status esperado:

`PASS_PARTIAL`

## Evidência de primeira execução local

O primeiro reload do Checkpoint III-B confirmou novamente o PASS integral do Checkpoint III-A.

Ao iniciar o IBGE 2017, o log registrou:

- o caminho do XLS corretamente;
- a tabela BIFF como `MunicÃ­pios$`;
- erro `Cannot locate table in BIFF file`;
- `ScriptErrorList=Table Not Found`;
- interrupção controlada antes de qualquer QVD IBGE.

A inspeção física havia confirmado que a planilha real é `Municípios`. Portanto, a falha foi isolada na interpretação do literal UTF-8 acentuado do include `.qvs` pelo QlikView 12.

### Correção

Os identificadores acentuados usados pelo carregamento BIFF e pela validação dos cabeçalhos passam a ser construídos em runtime com `Chr(...)`:

- `Municípios$` → `Chr(237)`;
- `NOME DO MUNICÍPIO` → `Chr(205)`;
- `POPULAÇÃO ESTIMADA` → `Chr(199)` e `Chr(195)`.

A correção não altera arquivos fonte, campos de staging, totais esperados, granularidade ou modelagem.

, reconheceu os cinco campos esperados e carregou **223 registros PB** para 2017.

O gate populacional, porém, produziu **4.229.525**, acima do valor validado **4.025.558**.

Uma inspeção direta do XLS identificou duas células PB com notas numéricas anexadas ao valor populacional:

- Livramento: `7386(4)`;
- Taperoá: `15276(5)`.

O diagnóstico que considerou somente o número anterior ao primeiro parêntese reconciliou exatamente:

`TOTAL_REGEX=4025558`

### Causa identificada

A expressão anterior:

`KeepChar(Text([POPULAÇÃO ESTIMADA]), '0123456789')`

mantinha também os dígitos das notas parentéticas, transformando, por exemplo:

- `7386(4)` em `73864`;
- `15276(5)` em `152765`.

### Correção

A normalização passa a considerar somente o trecho anterior ao primeiro `(` antes de remover caracteres não numéricos:

`KeepChar(SubField(Text([POPULAÇÃO ESTIMADA]), '(', 1), '0123456789')`

A regra é aplicada uniformemente aos três anos e preserva o número principal da publicação, descartando apenas a anotação parentética.

## Próximo gate

Executar localmente `EXTRACAO/EXT.qvw` após sincronizar a branch/PR mergeada e exigir:

- `SRC_IBGE_POPULACAO.qvd` gerado;
- 669 linhas;
- 223 municípios em cada ano;
- totais 4.025.558 / 3.996.496 / 4.018.127;
- `_CHECKPOINT_EXTRACAO_IBGE.csv` com `PASS_PARTIAL`.

A Fase III permanece aberta porque as referências auxiliares ainda precisam ser materializadas/reconciliadas.

## Fora de escopo

Este checkpoint não implementa:

- mapeamento DATASUS ↔ IBGE;
- SIGTAP;
- CID-10;
- caráter de atendimento;
- motivo de saída;
- referência de tipo/leito;
- fatos;
- dimensões;
- `LINK_ANALISE`;
- indicadores;
- dashboards.
