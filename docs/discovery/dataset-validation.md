# Dataset Validation / Modeling Discovery — SUS PB

## Status

**Concluída**

## Veredito

**APROVADO PARA MODELAGEM ACADÊMICA, COM RESSALVAS DOCUMENTADAS**

Esta Discovery validou amostras reais das três fontes do projeto e confirmou a viabilidade estrutural da modelagem para a primeira entrega acadêmica.

A validação utilizou checkpoints de janeiro de 2017, 2018 e 2019 para SIH/RD, CNES/LT e CNES/ST, além das estimativas populacionais anuais do IBGE para 2017–2019.

A carga integral dos 36 meses permanece como atividade futura de aquisição/implementação e deverá repetir os controles de qualidade definidos aqui.

---

# 1. Escopo validado

Tema:

**Data Mart para análise descritiva e comparativa da demanda hospitalar, capacidade hospitalar e população do SUS na Paraíba.**

Período aprovado:

**2017–2019**

Fontes aprovadas:

- SIH/SUS — arquivos RD / AIH Reduzida;
- CNES — arquivos LT / Leitos;
- CNES — arquivos ST / Estabelecimentos;
- IBGE — estimativas populacionais municipais anuais.

A implementação continua obrigatoriamente destinada ao QlikView 12, mas não deve começar antes do fechamento dos modelos acadêmicos dos Capítulos 1 e 2.

---

# 2. Evidências inspecionadas

## 2.1 SIH/RD

Arquivos:

- `RDPB1701.dbc`;
- `RDPB1801.dbc`;
- `RDPB1901.dbc`.

| Verificação | 2017-01 | 2018-01 | 2019-01 |
|---|---:|---:|---:|
| Registros | 14.726 | 14.501 | 15.155 |
| Campos | 113 | 113 | 113 |
| `IDENT=1` | 14.424 | 14.188 | 14.820 |
| `IDENT=5` | 302 | 313 | 335 |
| CNES distintos | 97 | 96 | 96 |

### FATO VERIFICADO

O schema permaneceu estável nos três checkpoints.

### FATO VERIFICADO

`N_AIH` não é chave única do registro RD.

Foram observadas repetições de `N_AIH` associadas, entre outros casos, a registros de continuidade `IDENT=5`.

### FATO VERIFICADO

A granularidade física observada é:

**1 linha = 1 registro administrativo de AIH processada presente no arquivo RD.**

Uma linha não deve ser interpretada automaticamente como:

- paciente único;
- pessoa única;
- episódio clínico único.

### FATO VERIFICADO

Para a contagem operacional de internações, registros de continuidade `IDENT=5` não devem ser tratados como nova internação.

### FATO VERIFICADO

Campos relevantes confirmados:

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

### FATO VERIFICADO

Competência, data de internação e data de saída são conceitos temporais distintos.

---

## 2.2 CNES/LT — Leitos

Arquivos:

- `LTPB1701.dbc`;
- `LTPB1801.dbc`;
- `LTPB1901.dbc`.

| Verificação | 2017-01 | 2018-01 | 2019-01 |
|---|---:|---:|---:|
| Registros | 1.003 | 955 | 955 |
| Campos | 28 | 28 | 28 |
| CNES distintos | 209 | 210 | 202 |
| Tipos de leito | 7 | 7 | 7 |
| Códigos de leito | 56 | 57 | 56 |
| Leitos existentes | 9.597 | 9.372 | 9.182 |
| Leitos SUS | 7.772 | 7.457 | 7.489 |

### FATO VERIFICADO

O schema permaneceu estável nos três checkpoints.

### FATO VERIFICADO

A combinação:

`CNES + COMPETEN + CODLEITO`

é única nos três checkpoints.

Granularidade aprovada:

**1 linha = estabelecimento × competência mensal × código/detalhamento de leito.**

### FATO VERIFICADO

Campos relevantes confirmados:

- `CNES`;
- `CODUFMUN`;
- `TP_LEITO`;
- `CODLEITO`;
- `QT_EXIST`;
- `QT_SUS`;
- `QT_NSUS`;
- `COMPETEN`.

Nos checkpoints analisados:

`QT_NSUS = QT_EXIST - QT_SUS`.

### REGRA ANALÍTICA

Quantidades de leitos são snapshots mensais e são **semi-aditivas no tempo**.

Somar a capacidade de meses sucessivos não representa a capacidade do período.

---

## 2.3 CNES/ST — Estabelecimentos

Arquivos:

- `STPB1701.dbc`;
- `STPB1801.dbc`;
- `STPB1901.dbc`.

| Verificação | 2017-01 | 2018-01 | 2019-01 |
|---|---:|---:|---:|
| Registros | 5.692 | 6.039 | 6.242 |
| Campos | 201 | 201 | 201 |
| CNES distintos | 5.692 | 6.039 | 6.242 |
| Municípios PB | 223 | 223 | 223 |

### FATO VERIFICADO

O schema permaneceu estável nos três checkpoints e `CNES` é único dentro de cada competência analisada.

Granularidade observada:

**1 linha = 1 estabelecimento CNES em uma competência mensal.**

### FATO VERIFICADO

Foram observadas mudanças históricas em atributos de estabelecimentos ao longo dos checkpoints, incluindo:

- tipo de gestão;
- tipo de unidade;
- natureza jurídica;
- vínculo SUS;
- CNPJ mantenedora;
- CEP.

Portanto, atributos de estabelecimento não devem ser tratados como necessariamente invariáveis durante 2017–2019.

### DECISÃO DE MODELAGEM

A dimensão de estabelecimento deverá preservar o contexto temporal dos atributos relevantes. A técnica concreta de historização será definida no modelo dimensional/lógico, evitando aplicar retroativamente atributos de uma competência posterior.

---

## 2.4 IBGE — População municipal

Arquivos:

- `estimativa_dou_2017.xls`;
- `estimativa_dou_2018_20181019.xls`;
- `estimativa_dou_2019.xls`.

| Ano | Municípios PB | População estimada PB |
|---|---:|---:|
| 2017 | 223 | 4.025.558 |
| 2018 | 223 | 3.996.496 |
| 2019 | 223 | 4.018.127 |

### FATO VERIFICADO

Granularidade aprovada:

**1 registro = município × ano de referência.**

### REGRA ANALÍTICA

População é tratada como medida **semi-aditiva no tempo**.

Valores de anos diferentes não devem ser somados como se representassem pessoas adicionais.

### RESSALVA METODOLÓGICA

Há revisão metodológica/projecional entre as publicações de 2017 e 2018. Indicadores anuais podem utilizar a estimativa publicada de cada ano, mas a variação 2017→2018 não deve ser interpretada automaticamente como crescimento ou redução demográfica observada.

---

# 3. Integração entre as fontes

## 3.1 Estabelecimento

Chave validada:

`SIH.CNES ↔ CNES/ST.CNES ↔ CNES/LT.CNES`

Cobertura nos checkpoints:

| Ano | CNES SIH encontrados no LT | CNES LT encontrados no ST |
|---|---:|---:|
| 2017 | 97/97 | 209/209 |
| 2018 | 96/96 | 210/210 |
| 2019 | 96/96 | 202/202 |

### FATO VERIFICADO

A cobertura observada foi de **100%** nos três checkpoints.

---

## 3.2 Município de atendimento/localização

Chaves observadas:

- `SIH.MUNIC_MOV`;
- `CNES.CODUFMUN`.

### FATO VERIFICADO

Nos estabelecimentos cruzados, os códigos municipais de atendimento/localização foram compatíveis nos checkpoints analisados.

---

## 3.3 Município de residência

`SIH.MUNIC_RES` pode apontar para municípios fora da Paraíba.

Foram observados registros de residentes externos à PB nos três checkpoints:

| Ano | Registros de residentes fora da PB |
|---|---:|
| 2017 | 131 |
| 2018 | 119 |
| 2019 | 162 |

### DECISÃO DE MODELAGEM

A dimensão Município não será limitada fisicamente aos municípios da Paraíba quando usada no papel de residência.

A fato de população e os indicadores populacionais principais continuarão restritos ao universo populacional aprovado para a Paraíba.

---

## 3.4 Correspondência DATASUS ↔ IBGE

### FATO VERIFICADO

Os códigos municipais DATASUS utilizados nas fontes de saúde podem ser relacionados aos códigos oficiais de município do IBGE.

### REGRA DE NEGÓCIO

A correspondência entre código DATASUS de 6 dígitos e código IBGE de 7 dígitos deve ser armazenada/derivada a partir de referência oficial validada.

Não gerar artificialmente o sétimo dígito.

---

# 4. Dicionário preliminar das fontes

| Processo | Fonte | Campos principais validados |
|---|---|---|
| Demanda hospitalar | SIH/RD | `N_AIH`, `IDENT`, `CNES`, `MUNIC_RES`, `MUNIC_MOV`, `ANO_CMPT`, `MES_CMPT`, `PROC_REA`, `PROC_SOLIC`, `DIAG_PRINC`, `CAR_INT`, `COBRANCA`, `DT_INTER`, `DT_SAIDA`, `DIAS_PERM`, `VAL_TOT`, `MORTE` |
| Capacidade | CNES/LT | `CNES`, `CODUFMUN`, `COMPETEN`, `TP_LEITO`, `CODLEITO`, `QT_EXIST`, `QT_SUS`, `QT_NSUS` |
| Estabelecimentos | CNES/ST | `CNES`, `CODUFMUN`, `COMPETEN`, `TP_UNID`, `TPGESTAO`, `NAT_JUR`, `VINC_SUS`, `CNPJ_MAN`, `COD_CEP` |
| População | IBGE | código UF, código município, nome do município, população estimada |

Descrições de domínio para procedimentos, diagnósticos, caráter, motivo de saída/permanência e leitos deverão vir das referências oficiais correspondentes e não serão inventadas a partir dos códigos.

---

# 5. Tabelas fato aprovadas

## 5.1 FATO_INTERNACAO

Granularidade:

**1 registro RD/AIH processada.**

Medidas/indicadores de linha candidatos:

- contador de registro RD;
- indicador de nova internação;
- dias de permanência;
- valor total;
- indicador de óbito.

### REGRA

`IDENT=5` não conta como nova internação.

### RESSALVA

Médias de valor/permanência por internação exigem cuidado com registros de continuidade e deverão ser validadas na carga integral antes de serem tratadas como indicadores finais.

---

## 5.2 FATO_CAPACIDADE_LEITO

Granularidade:

**estabelecimento × competência × código de leito.**

Medidas:

- leitos existentes;
- leitos SUS;
- leitos não SUS, derivável quando apropriado.

### DECISÃO

Todos os registros LT válidos serão preservados na fato.

O recorte estritamente hospitalar será representado por classificação do estabelecimento, permitindo reproduzir o universo do produto oficial sem eliminar outros registros válidos do CNES/LT.

---

## 5.3 FATO_POPULACAO

Granularidade:

**município × ano.**

Medida:

- população estimada.

---

# 6. Dimensões aprovadas para o desenho acadêmico

1. `DIM_TEMPO`;
2. `DIM_MUNICIPIO`;
3. `DIM_ESTABELECIMENTO`;
4. `DIM_PROCEDIMENTO`;
5. `DIM_DIAGNOSTICO`;
6. `DIM_CARATER_ATENDIMENTO`;
7. `DIM_MOTIVO_SAIDA_PERMANENCIA`;
8. `DIM_TIPO_LEITO`.

Essas dimensões são justificadas pelo processo e pelos campos reais inspecionados; não foram criadas apenas para satisfazer o mínimo acadêmico de seis dimensões.

---

# 7. Matriz fato × dimensão

| Dimensão | Internação | Capacidade | População |
|---|:---:|:---:|:---:|
| `DIM_TEMPO` | ✓ múltiplos papéis | ✓ | ✓ |
| `DIM_MUNICIPIO` | ✓ residência + atendimento | ✓ localização | ✓ |
| `DIM_ESTABELECIMENTO` | ✓ | ✓ | — |
| `DIM_PROCEDIMENTO` | ✓ | — | — |
| `DIM_DIAGNOSTICO` | ✓ | — | — |
| `DIM_CARATER_ATENDIMENTO` | ✓ | — | — |
| `DIM_MOTIVO_SAIDA_PERMANENCIA` | ✓ | — | — |
| `DIM_TIPO_LEITO` | — | ✓ | — |

---

# 8. Regras de negócio consolidadas

## RN01 — Período

O Data Mart terá como período analítico **2017–2019**.

## RN02 — Demanda

A demanda hospitalar será representada pelos registros SIH/RD de atendimento processado na Paraíba.

## RN03 — AIH não equivale a paciente

Uma AIH ou linha do RD não representa necessariamente uma pessoa única ou episódio clínico único.

## RN04 — Continuidade

Registros `IDENT=5` representam continuidade e não serão contados como nova internação.

## RN05 — Identificação técnica

`N_AIH` não será usado isoladamente como chave primária da linha da fato.

A transformação deverá criar uma chave técnica preservando a rastreabilidade do registro de origem.

## RN06 — Município em papéis distintos

Município de residência e município de atendimento/localização são conceitos diferentes.

## RN07 — Código municipal

A integração DATASUS ↔ IBGE será feita por correspondência validada, sem fabricação de dígito municipal.

## RN08 — Estabelecimento histórico

O CNES identifica o estabelecimento, mas atributos descritivos podem variar por competência.

## RN09 — Capacidade de leitos

A capacidade será registrada no nível de estabelecimento × competência × código de leito.

## RN10 — Leitos no tempo

Leitos são snapshots e não devem ser somados entre competências como se fossem capacidade acumulada.

## RN11 — População no tempo

População é um snapshot anual e não deve ser somada entre anos.

## RN12 — Internações por 1.000 habitantes

O indicador deverá relacionar internações de residentes ao município e à população correspondente ao mesmo ano.

## RN13 — Leitos por 1.000 habitantes

O indicador deverá relacionar a capacidade dos estabelecimentos ao município de localização e à população correspondente.

Para análise anual, a capacidade deverá utilizar uma regra temporal compatível com snapshots, preferencialmente a média dos 12 valores mensais.

## RN14 — Internações por leito

A relação entre internações e leitos poderá ser usada como indicador descritivo de demanda/capacidade.

Não será denominada taxa de ocupação.

## RN15 — Procedimento

`PROC_REA` será o procedimento principal de análise na primeira versão.

`PROC_SOLIC` permanecerá disponível na origem e poderá ser incorporado posteriormente se houver necessidade analítica.

## RN16 — Diagnóstico

A primeira versão utilizará o diagnóstico principal `DIAG_PRINC`.

Diagnósticos secundários ficam fora do escopo inicial.

## RN17 — Tempo

Competência, data de internação e data de saída utilizarão papéis temporais distintos.

## RN18 — Residentes externos

Internações de residentes de outros estados poderão participar de análises de fluxo para a Paraíba, mas não serão automaticamente associadas à população municipal da PB.

---

# 9. Modelo conceitual candidato

Entidades sustentadas:

- UF;
- MUNICIPIO;
- ESTABELECIMENTO;
- ESTABELECIMENTO_COMPETENCIA;
- REGISTRO_AIH;
- PROCEDIMENTO;
- DIAGNOSTICO;
- CARATER_ATENDIMENTO;
- MOTIVO_SAIDA_PERMANENCIA;
- TIPO_LEITO;
- LEITO;
- CAPACIDADE_LEITO;
- POPULACAO_MUNICIPAL.

`ESTABELECIMENTO_COMPETENCIA` representa o estado histórico do cadastro do estabelecimento na competência.

---

# 10. Relacionamentos e cardinalidades candidatas

| Relacionamento | Lado A | Lado B |
|---|---|---|
| UF — Município | UF (1,n) | Município (1,1) |
| Município — Estabelecimento/Competência | Município (0,n) | Estado do estabelecimento (1,1) |
| Estabelecimento — Estabelecimento/Competência | Estabelecimento (1,n) | Estado histórico (1,1) |
| Estabelecimento/Competência — Registro AIH | Estado (0,n) | AIH (1,1) |
| Município — Registro AIH como residência | Município (0,n) | AIH (1,1) |
| Procedimento — Registro AIH | Procedimento (0,n) | AIH (1,1) |
| Diagnóstico — Registro AIH | Diagnóstico (0,n) | AIH (1,1) |
| Caráter — Registro AIH | Caráter (0,n) | AIH (1,1) |
| Motivo saída/permanência — Registro AIH | Motivo (0,n) | AIH (0,1) |
| Tipo Leito — Leito | Tipo (1,n) | Leito (1,1) |
| Leito — Capacidade Leito | Leito (0,n) | Capacidade (1,1) |
| Estabelecimento/Competência — Capacidade Leito | Estado (0,n) | Capacidade (1,1) |
| Município — População Municipal | Município (0,n) | População (1,1) |

A opcionalidade de motivo de saída/permanência permanece conservadora até a validação da carga integral dos 36 meses.

---

# 11. Modelo lógico normalizado candidato

## UF

- `cod_uf` — PK;
- `sigla_uf`;
- `nome_uf`.

## MUNICIPIO

- `cod_ibge_7` — PK;
- `cod_datasus_6` — chave alternativa;
- `nome_municipio`;
- `cod_uf` — FK.

## ESTABELECIMENTO

- `cnes` — PK.

## ESTABELECIMENTO_COMPETENCIA

- `cnes` — PK/FK;
- `competencia` — PK;
- `cod_ibge_7` — FK;
- `tp_unid`;
- `tp_gestao`;
- `nat_jur`;
- `vinc_sus`;
- `cnpj_mantenedora`;
- `cep`.

Nome fantasia/razão social permanece como enriquecimento descritivo pendente porque não está no ST inspecionado.

## PROCEDIMENTO

- `cod_procedimento` — PK;
- atributos descritivos a partir da referência oficial do SIGTAP.

## DIAGNOSTICO

- `cod_diagnostico` — PK;
- atributos descritivos a partir da referência oficial CID utilizada pelo SIH.

## CARATER_ATENDIMENTO

- `cod_carater` — PK;
- descrição oficial.

## MOTIVO_SAIDA_PERMANENCIA

- `cod_motivo` — PK;
- descrição oficial.

## TIPO_LEITO

- `cod_tipo_leito` — PK;
- descrição oficial.

## LEITO

- `cod_leito` — PK;
- `cod_tipo_leito` — FK;
- descrição/especialidade oficial.

## REGISTRO_AIH

- `id_registro_aih` — PK técnica;
- referência ao arquivo/remessa/sequência de origem;
- `n_aih`;
- `ident`;
- competência;
- estabelecimento;
- município de residência;
- município de atendimento;
- procedimento realizado;
- diagnóstico principal;
- caráter;
- motivo de saída/permanência;
- data de internação;
- data de saída;
- dias de permanência;
- valor total;
- indicador de óbito.

## CAPACIDADE_LEITO

PK composta candidata:

- `cnes`;
- `competencia`;
- `cod_leito`.

Medidas:

- `qt_exist`;
- `qt_sus`.

## POPULACAO_MUNICIPAL

PK composta:

- `cod_ibge_7`;
- `ano`.

Medida:

- `populacao`.

---

# 12. Decisão Star Schema x Snowflake Schema

## DECISÃO APROVADA

**Star Schema por processo, com dimensões conformadas compartilhadas.**

Motivação:

- dimensões são pequenas em relação às fatos;
- hierarquias como Município → UF e Leito → Tipo podem ser desnormalizadas no modelo dimensional;
- Snowflake acrescentaria joins e complexidade sem benefício demonstrado para o escopo atual;
- o modelo dimensional deve ser simples de compreender e adequado ao uso no QlikView;
- a normalização necessária para o Capítulo 1 permanece no modelo lógico de origem, sem obrigar a mesma forma no Data Mart.

Arquitetura dimensional aprovada:

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`;
- dimensões conformadas compartilhadas quando aplicável.

---

# 13. Indicadores aprovados em princípio

## Internações por 1.000 habitantes

`internações de residentes no ano / população estimada do município no ano × 1.000`

## Leitos SUS por 1.000 habitantes

Para análise anual:

`média mensal de leitos SUS / população estimada × 1.000`

## Relação internações por leito

`internações realizadas no período / capacidade média de leitos no período`

Este indicador é uma relação descritiva de demanda/capacidade e **não** deve ser apresentado como taxa de ocupação.

## Fluxo residência → atendimento

Comparação entre município de residência e município de atendimento para analisar concentração e deslocamento da demanda hospitalar.

---

# 14. Riscos e controles remanescentes

| Risco | Controle |
|---|---|
| Interpretar AIH como paciente único | Documentar granularidade e regra de continuidade |
| Duplicidade de `N_AIH` | Chave técnica de registro |
| Somar snapshots de leitos | Medida semi-aditiva; média/valor de referência |
| Somar população entre anos | Medida semi-aditiva |
| Confundir residência e atendimento | Papéis separados de Município |
| Atributos históricos de estabelecimento | Preservar competência/historização |
| Descrições de domínio incorretas | Utilizar referências oficiais SIGTAP/CID/CNES |
| Nome do estabelecimento ausente no ST | Enriquecimento oficial posterior |
| Comparar população 2017→2018 sem ressalva | Documentar revisão metodológica |
| Chamar internações/leito de ocupação | Proibir essa nomenclatura |
| Carga integral divergir dos checkpoints | Reexecutar controles nos 36 meses |

---

# 15. Pendências que não bloqueiam a primeira modelagem

- adquirir/validar os 36 meses completos na etapa de implementação;
- obter as descrições oficiais dos domínios;
- definir a fonte histórica de nome fantasia/razão social do estabelecimento;
- definir tecnicamente a historização de `DIM_ESTABELECIMENTO`;
- validar médias/razões que dependem da consolidação de registros de continuidade na carga integral;
- definir a estrutura concreta de scripts/QVD/QVW somente na etapa QlikView.

---

# 16. Readiness para Capítulos 1 e 2

## Capítulo 1 — Regras de Negócio

**PRONTO PARA MODELAGEM ACADÊMICA**

Já há evidência suficiente para:

- regras de negócio;
- entidades;
- relacionamentos;
- cardinalidades preliminares;
- modelo conceitual;
- DER;
- modelo lógico normalizado.

## Capítulo 2 — Modelagem Dimensional

**PRONTO PARA MODELAGEM ACADÊMICA**

Já há evidência suficiente para:

- três processos factuais;
- granularidade das fatos;
- dimensões;
- medidas principais;
- matriz fato × dimensão;
- decisão Star Schema;
- desenho do modelo dimensional.

---

# 17. Próxima etapa

**SAD — SUS PB — ACADEMIC MODELING / CHAPTERS 1–2**

Objetivos:

1. consolidar o DER conceitual;
2. consolidar o modelo lógico normalizado;
3. consolidar o modelo dimensional Star Schema;
4. preparar o texto acadêmico dos Capítulos 1 e 2;
5. revisar consistência entre regras, cardinalidades, modelos e terminologia;
6. somente depois preparar a implementação no QlikView 12.
