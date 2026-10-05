# BOUNDARY 3 — Full Dataset Validation — SAD SUS PB

**Modo:** READ-ONLY / LOCAL ANALYSIS  
**Período:** 2017-01 a 2019-12  
**Fontes:** SIH/SUS RD, CNES LT, CNES ST

## 1. Preflight

| Item | Resultado |
|---|---|
| Repositório canônico | PASS |
| `BASE.zip` | PASS — ZIP íntegro e extraído em área temporária |
| `resultado-aquisicao.zip` | PASS — ZIP íntegro e evidências legíveis |
| DBC encontrados | 108 / 108 |
| RD | 36 / 36 |
| LT | 36 / 36 |
| ST | 36 / 36 |
| Cobertura temporal | PASS — 2017-01 a 2019-12 sem lacunas |
| Leitura DBC | PASS — 108/108 descompactados e percorridos integralmente |
| Evidência de aquisição reconciliável | PASS — 108/108 nomes, tamanhos e SHA-256 coincidem com o manifesto |
| Blocker imediato | NÃO |

### Ferramenta temporária de leitura DBC

Foi usado um decoder local temporário, sem alterar os arquivos originais, baseado no algoritmo PKWARE DCL/`blast` utilizado pelo ecossistema `read.dbc` (`blast.c` v1.3, 20/07/2025). A implementação foi usada somente em área temporária. Todos os 108 arquivos foram descompactados e lidos até o último registro declarado no cabeçalho DBF.

## 2. Cobertura e volume

| Fonte | Arquivos | Registros totais | Menor competência (registros) | Maior competência (registros) | Schemas |
|---|---:|---:|---|---|---:|
| RD | 36 | 566.672 | 2017-02 (13.912) | 2019-05 (17.594) | 1 |
| LT | 36 | 35.518 | 2018-02 (951) | 2017-12 (1.033) | 1 |
| ST | 36 | 220.390 | 2017-01 (5.692) | 2019-10 (6.496) | 2 |

**FATO VERIFICADO:** os 108 DBC esperados estão presentes, cobrem todas as 36 competências e são estruturalmente legíveis. Não foram encontrados arquivos ausentes, hashes divergentes ou tamanhos divergentes em relação ao manifesto de aquisição.

## 3. Matriz de schemas e drifts

- **RD:** 1 schema em 36/36 competências, com 113 campos.
- **LT:** 1 schema em 36/36 competências, com 28 campos.
- **ST:** schema predominante de 201 campos em 35/36 competências; `STPB1912.dbc` possui 208 campos.

### `STPB1912.dbc`

**FATO VERIFICADO:** o drift é real e localizado em dezembro/2019.

Campos adicionados: `AP01CV07`, `AP02CV07`, `AP03CV07`, `AP04CV07`, `AP05CV07`, `AP06CV07`, `AP07CV07` (todos `C(1)`).

Larguras alteradas: `QTLEITP1`, `QTLEITP2`, `QTLEITP3` mudam de `N(3,0)` para `N(4,0)`. A inserção dos sete campos desloca a posição ordinal de 42 campos posteriores.

Os campos usados pela modelagem atual de estabelecimento permanecem presentes e com o mesmo tipo/largura (`CNES`, `CODUFMUN`, `COD_CEP`, `CNPJ_MAN`, `VINC_SUS`, `TPGESTAO`, `TP_UNID`, `NATUREZA`, `NAT_JUR`, `COMPETEN`). `COMPETEN` e `NAT_JUR` apenas mudam de posição ordinal.

**IMPACTO:** não há evidência de mudança necessária em fato, dimensão, granularidade ou Star Schema. A extração futura deve ser tolerante a schema e selecionar campos por nome, não por posição fixa ou record length.

**STATUS:** ajuste técnico de implementação; não é Decision Gate estrutural.

## 4. Granularidades e chaves

### SIH/RD — `FATO_INTERNACAO`

**DECISÃO CONFIRMADA:** 1 linha física continua representando 1 registro administrativo RD / AIH processada.

- 566.672 registros no período; nenhum registro duplicado byte a byte.
- `N_AIH` não é único em **36/36 competências**.
- Somatório mensal: 832 chaves `N_AIH` duplicadas e 880 linhas excedentes por repetição.
- Todos os 832 grupos duplicados mensais contêm `IDENT=5`; nenhum grupo duplicado mensal sem `IDENT=5` foi observado.
- `IDENT=5`: 11.583 registros no período; domínio integral de `IDENT`: 1, 5.

**DECISÃO CONFIRMADA:** `N_AIH` não deve ser usado como PK da fato e `IDENT=5` continua representando continuidade, não nova internação.

### CNES/LT — `FATO_CAPACIDADE_LEITO`

**DECISÃO CONFIRMADA:** a chave de grão `CNES + COMPETEN + CODLEITO` é única em 36/36 competências.

- 35.518 registros; 0 chaves duplicadas; 0 duplicatas exatas.
- 0 divergências de competência em relação ao nome do arquivo.
- 0 valores não numéricos/negativos em `QT_EXIST`, `QT_SUS`, `QT_NSUS`.
- 0 violações de `QT_NSUS = QT_EXIST - QT_SUS`.

**DECISÃO CONFIRMADA:** snapshots mensais de capacidade permanecem sustentados pelos dados integrais.

### CNES/ST — estabelecimento por competência

**DECISÃO CONFIRMADA:** `CNES` é único dentro de cada competência em 36/36 meses.

- 220.390 registros; 0 duplicidades de CNES por competência; 0 duplicatas exatas.
- Foram observados 6.822 CNES distintos no período; 746 tiveram mudança em pelo menos um dos atributos históricos monitorados.
- Mudanças por atributo: `TPGESTAO`=18, `TP_UNID`=210, `NATUREZA`=0, `NAT_JUR`=134, `VINC_SUS`=105, `CNPJ_MAN`=33, `COD_CEP`=337.

**DECISÃO CONFIRMADA:** `DIM_ESTABELECIMENTO` precisa preservar contexto temporal; não há evidência para tratar seus atributos como invariáveis.

## 5. Controles de qualidade — RD

- 0 divergências de `ANO_CMPT`/`MES_CMPT` contra a competência do arquivo.
- 0 campos obrigatórios vazios entre os campos auditados.
- 0 datas inválidas em `DT_INTER` e `DT_SAIDA`; 0 casos com `DT_SAIDA < DT_INTER`.
- 0 valores não numéricos ou negativos em `DIAS_PERM` e `VAL_TOT`.
- 0 violações de formato de 10 dígitos em `PROC_SOLIC` e `PROC_REA`.
- 0 `DIAG_PRINC` vazios.
- domínio de `MORTE` permaneceu `{0,1}`.
- domínio de `CAR_INT` permaneceu `01, 02, 05, 06`, sem valores novos fora dos checkpoints.

### Domínio novo observado fora dos checkpoints

**FATO VERIFICADO:** `COBRANCA` apresentou o código `24`, ausente nos checkpoints de janeiro, mas presente em `2017-09`, `2018-08`, `2018-11`, `2019-03`, `2019-04` e `2019-07`.

**IMPACTO:** não altera a estrutura da `DIM_MOTIVO_SAIDA_PERMANENCIA`, que já foi desenhada para usar domínio oficial completo. A descrição oficial do código deve ser fechada junto às referências auxiliares do Boundary 4, sem inferência local.

## 6. Integrações SIH ↔ CNES

| Integração | Cobertura global | Menor cobertura mensal | Meses < 100% |
|---|---:|---:|---:|
| SIH.CNES ↔ ST.CNES — registros RD | 100.00% | 100.00% | 0 |
| SIH.CNES ↔ ST.CNES — CNES distintos | 100.00% | 100.00% | 0 |
| SIH.CNES ↔ LT.CNES — registros RD | 100.00% | 100.00% | 0 |
| SIH.CNES ↔ LT.CNES — CNES distintos | 100.00% | 100.00% | 0 |
| LT.CNES ↔ ST.CNES — CNES distintos | 100.00% | 100.00% | 0 |
| SIH.MUNIC_MOV ↔ ST.CODUFMUN | 100.00% | 100.00% | 0 |

**FATO VERIFICADO:** todas as integrações acima atingiram 100% em todas as 36 competências. Não houve exceção mensal.

## 7. Integração municipal e residência

- Os 223 códigos de município da Paraíba observados em `MUNIC_RES` estão todos contidos no universo municipal de 223 códigos observado em CNES/ST.
- Foram observados 561.470 registros RD com residência na Paraíba e 5.202 registros com residência fora da Paraíba.
- Há 714 códigos distintos de residência fora da Paraíba.

**DECISÃO CONFIRMADA:** residência e atendimento devem permanecer papéis municipais distintos. Residência fora da Paraíba é ocorrência real, não anomalia a excluir.

**RESSALVA:** os três arquivos anuais do IBGE não estavam dentro dos dois ZIPs desta execução; portanto, o relacionamento DATASUS ↔ IBGE já validado anteriormente não foi refeito byte a byte aqui. O Boundary 3 confirmou integralmente o lado DATASUS/CNES e não encontrou evidência que contradiga a compatibilidade previamente estabelecida.

## 8. Checkpoints x conjunto integral

**FATO VERIFICADO:** os checkpoints acertaram as principais propriedades estruturais. O conjunto integral acrescentou duas evidências relevantes:

1. drift de schema isolado em `STPB1912.dbc`;
2. código `COBRANCA=24`, não observado nos três checkpoints de janeiro.

Não surgiram novos valores de `IDENT`, `CAR_INT`, `MORTE`, `TP_LEITO` ou `CODLEITO` fora dos domínios já observados nos checkpoints.

## 9. Impacto na modelagem aprovada

### DECISÃO CONFIRMADA

Os 36 meses sustentam as três fatos, oito dimensões e granularidades aprovadas. Não foi encontrada evidência que exija revisar:

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`;
- Star Schema por processo factual / constelação de estrelas;
- `PROC_REA` como procedimento principal da versão inicial;
- `DIAG_PRINC` como diagnóstico principal da versão inicial;
- separação residência/atendimento;
- snapshots mensais de leitos;
- semi-aditividade de leitos e população;

### Ajustes necessários antes da implementação

1. Tornar a extração de ST tolerante ao drift de `2019-12`, selecionando campos por nome e aceitando as larguras ampliadas.
2. No Boundary 4, materializar a referência oficial que dê significado a `COBRANCA=24` e demais domínios auxiliares por competência.
3. Manter o teste de schema como controle de regressão para a implementação QlikView/QVD.

Nenhum desses pontos exige Decision Gate estrutural neste momento.

## 10. Blockers

**FATO VERIFICADO:** não há blocker de dataset para prosseguir com a Discovery.

Persistem apenas pendências já previstas para boundaries posteriores: referências auxiliares, historização física/role-playing e arquitetura física QlikView.

## 11. Veredito

### `APROVADO PARA PROSSEGUIR COM AJUSTES`

Os 36 meses sustentam a arquitetura conceitual/dimensional atual. Os ajustes identificados são técnicos/documentais — tratamento do schema drift de ST em 2019-12 e fechamento do domínio auxiliar `COBRANCA=24` — e não exigem alterar fatos, dimensões, granularidades ou o Star Schema.

**Próxima etapa prevista:** `BOUNDARY 4 — Referências auxiliares`. Não iniciar implementação definitiva antes dos boundaries subsequentes e do readiness gate.

## 12. Arquivos de evidência gerados

- `boundary3-physical-inventory.csv` — inventário físico, SHA-256 e reconciliação com o manifesto.
- `boundary3-schema-matrix.csv` — fonte × competência × quantidade de campos/variante.
- `boundary3-source-qc-by-month.csv` — volume e QC estrutural por competência.
- `boundary3-integration-by-month.csv` — cobertura de integrações por competência.
- `boundary3-results.json` — resultado estruturado integral da execução.
