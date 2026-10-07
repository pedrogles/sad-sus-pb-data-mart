# Fase III — Extração — Checkpoint de staging de saúde — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-A — SIH/RD + CNES/LT + CNES/ST  
**Status:** CHECKPOINT III-A PASS

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


## Evidência de primeira execução local

A primeira execução integral do `EXT.qvw` carregou os 36 arquivos RD e atingiu exatamente **566.672 registros**, mas parou antes do primeiro `STORE`.

O log mostrou:

- `vRDFiles = 36`;
- `vRDRows = 566672`;
- `vRDDistinctCompetences = 36`;
- `vRDCompetenceMismatch = 566672`;
- interrupção em `EXIT SCRIPT` antes da geração de `SRC_SIH_RD.qvd`.

### Causa identificada

Os campos `ANO_CMPT`, `MES_CMPT` e `COMPETEN` são deliberadamente carregados com `Text(...)` para preservar o código fonte. A primeira versão da checagem tentou reconvertê-los com `Num(...)` para comparar a competência.

No QlikView local, essa combinação não preservou a representação numérica necessária à checagem e todos os registros RD foram classificados como divergentes, apesar de a carga, a quantidade de arquivos e as competências distintas estarem corretas.

### Correção

A validação passou a comparar competências como texto normalizado:

- RD: `Right('0000' & Trim(ANO_CMPT), 4) & Right('00' & Trim(MES_CMPT), 2)`;
- LT/ST: `Right('000000' & Trim(COMPETEN), 6)`;
- comparação direta com `_META_SOURCE_COMPETENCE`.

A correção preserva os campos de código como texto e altera somente o controle técnico de reconciliação.

## Evidência de segunda execução local

Após a correção e novo reload de `EXTRACAO/EXT.qvw`, os artefatos foram gerados com sucesso:

- `SRC_SIH_RD.qvd`;
- `SRC_CNES_LT.qvd`;
- `SRC_CNES_ST.qvd`;
- `_CHECKPOINT_EXTRACAO_SAUDE.csv`.

Checkpoint observado:

- `status=PASS_PARTIAL`;
- RD: **36 arquivos / 566.672 registros**;
- LT: **36 arquivos / 35.518 registros**;
- ST: **36 arquivos / 220.390 registros**.

O resultado confirma o **PASS do Checkpoint III-A** para as três fontes de saúde. O status permanece parcial porque IBGE e referências auxiliares ainda não integram o staging final da Fase III.

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

O Checkpoint III-A está concluído. A próxima ação é inspecionar fisicamente os arquivos IBGE 2017–2019 para determinar, com evidência:

- caminhos e nomes reais dos arquivos;
- extensão/formato;
- nomes das planilhas;
- linha de cabeçalho;
- nomes efetivos das colunas usadas para UF, município e população;
- tratamento necessário para linhas de notas/rodapés.

Depois disso, implementar `SRC_IBGE_POPULACAO.qvd` sem inventar nomes de planilha ou cabeçalho.

As referências auxiliares permanecem como gates posteriores da própria Fase III.
