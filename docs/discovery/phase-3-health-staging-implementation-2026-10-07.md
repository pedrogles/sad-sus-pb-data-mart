# Fase III — Extração — Checkpoint de staging de saúde — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-A — SIH/RD + CNES/LT + CNES/ST  
**Status:** IMPLEMENTADO NO REPOSITÓRIO; VALIDAÇÃO LOCAL PENDENTE

## Base de evidência

O checkpoint usa somente contratos já confirmados por inspeção dos dados e pelo Boundary 7.

### SIH/RD

Campos carregados:

- `ANO_CMPT`;
- `MES_CMPT`;
- `N_AIH`;
- `IDENT`;
- `MUNIC_RES`;
- `MUNIC_MOV`;
- `CNES`;
- `PROC_SOLIC`;
- `PROC_REA`;
- `DIAG_PRINC`;
- `CAR_INT`;
- `COBRANCA`;
- `DT_INTER`;
- `DT_SAIDA`;
- `DIAS_PERM`;
- `VAL_TOT`;
- `MORTE`.

Controles:

- 36 arquivos;
- 566.672 registros;
- 36 competências distintas;
- competência interna `ANO_CMPT + MES_CMPT` igual à competência derivada do nome do arquivo.

Saída:

`EXTRACAO/QVD/SRC_SIH_RD.qvd`

### CNES/LT

Campos carregados:

- `CNES`;
- `CODUFMUN`;
- `TP_LEITO`;
- `CODLEITO`;
- `QT_EXIST`;
- `QT_SUS`;
- `QT_NSUS`;
- `COMPETEN`.

Controles:

- 36 arquivos;
- 35.518 registros;
- 36 competências distintas;
- `COMPETEN` igual à competência derivada do nome do arquivo.

Saída:

`EXTRACAO/QVD/SRC_CNES_LT.qvd`

### CNES/ST

Campos carregados explicitamente por nome:

- `CNES`;
- `CODUFMUN`;
- `COD_CEP`;
- `CNPJ_MAN`;
- `VINC_SUS`;
- `TPGESTAO`;
- `TP_UNID`;
- `NATUREZA`;
- `NAT_JUR`;
- `COMPETEN`.

Controles:

- 36 arquivos;
- 220.390 registros;
- 36 competências distintas;
- `COMPETEN` igual à competência derivada do nome do arquivo.

O carregamento explícito por nome preserva a decisão de não depender da posição ordinal e tolera o drift de `STPB1912.dbc`.

Saída:

`EXTRACAO/QVD/SRC_CNES_ST.qvd`

## Metadados de staging

Cada linha recebe:

- `_META_SOURCE_FILE`;
- `_META_SOURCE_FAMILY`;
- `_META_SOURCE_COMPETENCE`;
- `_META_SOURCE_PATH`.

Esses campos são metadados técnicos de rastreabilidade da camada de staging e não alteram a modelagem acadêmica.

## Tratamento de erro

O script mantém o baseline aprovado:

`SET ErrorMode=0;`

Após operações críticas, `ScriptErrorCount` é verificado explicitamente. Em divergência de arquivo, contagem, competência ou STORE, o script executa `EXIT SCRIPT` e não emite checkpoint de sucesso parcial.

## Checkpoint parcial

Somente depois do PASS de RD, LT e ST é emitido:

`EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_SAUDE.csv`

Status esperado:

`PASS_PARTIAL`

Esse arquivo **não** representa conclusão da Fase III e não substitui o futuro marcador final `_SUCCESS_EXTRACAO.csv`.

## DECISÃO PENDENTE / gate de implementação

A Fase III permanece aberta porque ainda é necessário fechar a carga física de:

- IBGE 2017–2019;
- referência municipal DATASUS ↔ IBGE;
- SIGTAP por competência;
- CID-10;
- domínio de caráter;
- motivo de saída/permanência;
- referência CNES de tipo/leito;
- referência histórica adicional de estabelecimento, quando aplicável.

Os arquivos anuais do IBGE foram validados conceitualmente, mas os nomes físicos de planilha/cabeçalho necessários ao script QlikView ainda não estão documentados com evidência suficiente no repositório. Eles não serão inventados.

## Fora de escopo

Este checkpoint não implementa:

- dimensões;
- fatos;
- `LINK_ANALISE`;
- transformação dimensional;
- indicadores;
- dashboards.

## Próximo gate

Executar localmente `EXTRACAO/EXT.qvw` e exigir:

- RD = 566.672;
- LT = 35.518;
- ST = 220.390;
- 36 competências por família;
- 0 divergências entre competência interna e nome do arquivo;
- três QVDs gerados;
- `_CHECKPOINT_EXTRACAO_SAUDE.csv` com `PASS_PARTIAL`.

Somente depois dessa validação o projeto deve avançar para a inspeção física do IBGE e das referências auxiliares.
