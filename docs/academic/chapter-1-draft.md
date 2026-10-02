# Capítulo 1 — Regras de Negócio

## 1.1 Contextualização do problema

Este projeto propõe a construção de um Data Mart para apoiar a análise descritiva e comparativa da demanda hospitalar, da capacidade hospitalar e da população relacionada ao Sistema Único de Saúde (SUS) na Paraíba.

O escopo analítico considera o período de **2017 a 2019** e integra três conjuntos principais de informação:

A janela de 2017 a 2019 foi escolhida por reunir **três anos completos e consecutivos**, suficientes para comparação temporal sem ampliar desnecessariamente o volume do projeto. A validação confirmou disponibilidade e compatibilidade estrutural entre SIH/SUS, CNES e IBGE nos três anos. Além disso, o recorte antecede a pandemia de COVID-19, evitando que a ruptura excepcional observada a partir de 2020 domine a primeira modelagem do Data Mart. A comparação populacional entre 2017 e 2018 continua sujeita à ressalva metodológica do IBGE descrita adiante.

Os três conjuntos principais de informação são:

- internações hospitalares processadas pelo SIH/SUS;
- capacidade de leitos e características dos estabelecimentos cadastrados no CNES;
- estimativas populacionais municipais publicadas pelo IBGE.

A proposta busca permitir análises como:

- volume de internações ao longo do tempo;
- internações segundo município de residência e município de atendimento;
- distribuição da capacidade de leitos por município e estabelecimento;
- leitos SUS por habitante;
- internações por habitante;
- relação descritiva entre demanda hospitalar e capacidade cadastrada;
- fluxos de residentes entre municípios de origem e atendimento.

Neste projeto, o termo **demanda hospitalar** é utilizado em sentido operacional para representar o volume de internações registrado e processado no SIH/SUS. Ele não representa toda a necessidade de atenção hospitalar da população, procura potencial ou demanda reprimida.

Da mesma forma, **capacidade hospitalar** corresponde à capacidade de leitos cadastrada no CNES para cada competência. Esses valores representam capacidade cadastral e não disponibilidade operacional instantânea de leitos em determinado dia.

As relações observadas no Data Mart possuem caráter descritivo. O projeto não pretende estabelecer causalidade entre disponibilidade de leitos, população e volume de internações.

---

## 1.2 Fontes de dados

**Estratégia de validação dos dados.** Para a etapa de modelagem foram utilizados checkpoints de janeiro de 2017, 2018 e 2019 nas fontes mensais do SIH e do CNES. Essa amostragem não foi utilizada para produzir resultados estatísticos dos anos completos. Seu objetivo foi verificar, em pontos distribuídos pela janela temporal, a estabilidade dos schemas, granularidades, chaves e possibilidades de integração. A carga e a validação dos 36 meses completos serão realizadas na etapa de implementação, repetindo os controles definidos nesta Discovery.

### 1.2.1 SIH/SUS

O Sistema de Informações Hospitalares do SUS é utilizado como fonte da demanda hospitalar. Para o projeto são considerados os arquivos **RD — AIH Reduzida**.

A inspeção dos arquivos de janeiro de 2017, 2018 e 2019 confirmou estabilidade estrutural e a presença dos campos necessários para identificar, entre outros elementos:

- competência;
- estabelecimento;
- município de residência;
- município de atendimento;
- procedimento realizado;
- diagnóstico principal;
- caráter do atendimento;
- motivo de saída ou permanência;
- datas de internação e saída;
- dias de permanência;
- valor total;
- ocorrência de óbito.

A unidade física observada no arquivo RD corresponde a um **registro administrativo de AIH processada**. Esse registro não deve ser interpretado automaticamente como paciente único ou episódio clínico único.

### 1.2.2 CNES

O Cadastro Nacional de Estabelecimentos de Saúde é utilizado em duas frentes.

Os arquivos **LT — Leitos** representam a capacidade cadastrada por estabelecimento, competência e código de leito. Os arquivos **ST — Estabelecimentos** fornecem os atributos cadastrais históricos dos estabelecimentos.

A inspeção dos checkpoints de 2017, 2018 e 2019 confirmou que os atributos cadastrais de um mesmo estabelecimento podem mudar ao longo do tempo. Por esse motivo, a modelagem preserva o contexto da competência do cadastro, em vez de considerar que todos os atributos de um CNES são invariáveis.

### 1.2.3 IBGE

As estimativas populacionais municipais do IBGE são utilizadas como referência de população residente.

A granularidade validada é:

**município × ano**.

As estimativas de 2017, 2018 e 2019 abrangem os 223 municípios da Paraíba. Existe uma ressalva metodológica entre as publicações de 2017 e 2018 devido à revisão das projeções populacionais. Assim, a estimativa de cada ano pode ser utilizada como denominador daquele ano, mas a diferença entre 2017 e 2018 não deve ser interpretada automaticamente como crescimento ou redução demográfica observada.

---

## 1.3 Regras de negócio

As regras abaixo foram definidas a partir do material da disciplina, da documentação oficial das fontes e da inspeção dos dados reais utilizados na Discovery.

### RN01 — Período analítico

O período analisado pelo Data Mart será de **2017 a 2019**.

A escolha utiliza três anos completos e consecutivos, com compatibilidade estrutural validada entre as fontes, volume adequado ao escopo acadêmico e recorte anterior à pandemia de COVID-19.

### RN02 — Escopo geográfico da demanda

A demanda hospitalar será representada pelos registros SIH/RD referentes a atendimentos processados na Paraíba.

### RN03 — Unidade administrativa da demanda

Cada linha do SIH/RD representa um registro administrativo de AIH processada.

Uma linha não deve ser interpretada automaticamente como paciente único, pessoa única ou episódio clínico único.

### RN04 — Continuidade de longa permanência

Registros com `IDENT=5` representam continuidade e não serão contados como uma nova internação.

### RN05 — Identificação técnica do registro

O campo `N_AIH` não é suficiente para identificar unicamente uma linha do RD.

O modelo utilizará uma chave técnica própria para o registro e preservará os identificadores de origem necessários à rastreabilidade.

### RN06 — Município de residência e município de atendimento

Município de residência e município de atendimento representam papéis diferentes.

O município de residência indica a origem declarada do usuário, enquanto o município de atendimento corresponde à localização do estabelecimento no qual o atendimento foi realizado.

### RN07 — Correspondência municipal

Os códigos municipais utilizados pelo DATASUS serão relacionados aos códigos oficiais do IBGE por meio de correspondência validada.

O sétimo dígito do código IBGE não será criado artificialmente por regra de cálculo.

### RN08 — Identidade e histórico do estabelecimento

O estabelecimento é identificado pelo código CNES.

Seus atributos cadastrais podem mudar ao longo do tempo. Portanto, os atributos utilizados em uma análise devem corresponder ao contexto temporal da competência analisada.

### RN09 — Granularidade da capacidade de leitos

A capacidade será armazenada no nível:

**estabelecimento × competência mensal × código de leito**.

### RN10 — Medidas de capacidade

As medidas principais de capacidade serão:

- quantidade de leitos existentes;
- quantidade de leitos SUS.

A quantidade de leitos não SUS poderá ser derivada quando necessário.

### RN11 — Semi-aditividade dos leitos

Os quantitativos de leitos representam snapshots mensais.

A soma da capacidade de meses consecutivos não representa a capacidade física acumulada do período.

Para os indicadores anuais definidos neste projeto, será utilizada a **média dos doze snapshots mensais disponíveis do ano**, evitando a soma indevida de estoques mensais.

### RN12 — Granularidade da população

A população será armazenada no nível:

**município × ano**.

### RN13 — Semi-aditividade da população

Populações de anos diferentes não devem ser somadas.

Cada valor representa uma estimativa referente ao período correspondente.

### RN14 — Internações por 1.000 habitantes

O indicador de internações por 1.000 habitantes deverá utilizar:

- internações de residentes no município;
- população estimada do mesmo município;
- mesmo ano de referência.

### RN15 — Leitos SUS por 1.000 habitantes

O indicador deverá relacionar:

- capacidade SUS cadastrada nos estabelecimentos localizados no município;
- população do município;
- período temporal compatível.

### RN16 — Relação entre internações e leitos

Poderá ser calculada uma relação descritiva entre internações e capacidade média de leitos.

Essa relação **não será denominada taxa de ocupação**, pois as fontes utilizadas não fornecem, por si só, todos os elementos necessários para calcular uma taxa de ocupação hospitalar metodologicamente adequada.

### RN17 — Procedimento

O procedimento principal da primeira versão do modelo será o procedimento realizado, representado pelo campo `PROC_REA`.

O procedimento solicitado será preservado na origem e poderá ser incorporado posteriormente caso exista necessidade analítica.

A escolha de `PROC_REA` ocorre porque o objetivo da dimensão é caracterizar a produção efetivamente realizada. Os dados inspecionados também mostraram que procedimento solicitado e realizado nem sempre são iguais, razão pela qual os dois conceitos não devem ser tratados como equivalentes.

### RN18 — Diagnóstico

A primeira versão utilizará o diagnóstico principal, representado pelo campo `DIAG_PRINC`.

Diagnósticos secundários ficam fora do escopo inicial.

Essa decisão reduz complexidade na primeira versão porque os diagnósticos secundários podem ocorrer de forma multivalorada para um mesmo registro, o que exigiria estrutura adicional de relacionamento, como uma tabela ponte, sem necessidade demonstrada para os objetivos atuais.

### RN19 — Papéis temporais

Competência, data de internação e data de saída são referências temporais distintas e não devem ser tratadas como a mesma data no modelo analítico.

### RN20 — Residentes de outros estados

Registros de residentes de outros estados poderão participar da análise de fluxo para a Paraíba.

Esses registros não serão associados automaticamente à população municipal da Paraíba.

### RN21 — Preservação dos registros de leitos

Todos os registros válidos do CNES/LT serão preservados no processo de capacidade.

O recorte de estabelecimentos estritamente hospitalares será representado por atributos de classificação, evitando a eliminação antecipada de outros estabelecimentos que possuam capacidade de leitos cadastrada.

Essa abordagem preserva a informação original do CNES/LT e permite aplicar o recorte hospitalar de forma analítica, sem excluir antecipadamente registros válidos que podem ser necessários em comparações ou auditorias posteriores.

---

## 1.4 Entidades do modelo conceitual

A partir das regras de negócio foram identificadas as seguintes entidades:

| Entidade | Finalidade |
|---|---|
| `UF` | Representar a unidade federativa do município |
| `MUNICIPIO` | Representar residência, localização, atendimento e referência populacional |
| `ESTABELECIMENTO` | Representar a identidade do estabelecimento pelo CNES |
| `ESTABELECIMENTO_COMPETENCIA` | Representar o estado histórico do estabelecimento em determinada competência |
| `REGISTRO_AIH` | Representar um registro administrativo processado no SIH/RD |
| `PROCEDIMENTO` | Representar o procedimento realizado |
| `DIAGNOSTICO` | Representar o diagnóstico principal |
| `CARATER_ATENDIMENTO` | Representar o caráter do atendimento |
| `MOTIVO_SAIDA_PERMANENCIA` | Representar o encerramento ou permanência associado ao registro |
| `TIPO_LEITO` | Representar a classificação superior dos leitos |
| `LEITO` | Representar o detalhamento/código específico do leito |
| `CAPACIDADE_LEITO` | Representar os quantitativos de leitos por estabelecimento, competência e código |
| `POPULACAO_MUNICIPAL` | Representar a estimativa populacional de um município em um ano |

A entidade `ESTABELECIMENTO_COMPETENCIA` foi necessária porque os dados reais do CNES mostraram alterações históricas em atributos do estabelecimento. Essa separação permite representar a identidade permanente do CNES e, ao mesmo tempo, seus estados cadastrais ao longo do período.

---

## 1.5 Relacionamentos e cardinalidades

A cardinalidade mínima indica se a participação de uma entidade no relacionamento é opcional ou obrigatória, enquanto a cardinalidade máxima indica se uma ocorrência pode estar associada a uma ou a várias ocorrências da entidade relacionada.

As cardinalidades adotadas são:

| Relacionamento | Cardinalidade |
|---|---|
| UF — MUNICIPIO | UF (1,n) ↔ MUNICIPIO (1,1) |
| MUNICIPIO — ESTABELECIMENTO_COMPETENCIA | MUNICIPIO (0,n) ↔ ESTABELECIMENTO_COMPETENCIA (1,1) |
| ESTABELECIMENTO — ESTABELECIMENTO_COMPETENCIA | ESTABELECIMENTO (1,n) ↔ ESTABELECIMENTO_COMPETENCIA (1,1) |
| ESTABELECIMENTO_COMPETENCIA — REGISTRO_AIH | ESTABELECIMENTO_COMPETENCIA (0,n) ↔ REGISTRO_AIH (1,1) |
| MUNICIPIO — REGISTRO_AIH, papel residência | MUNICIPIO (0,n) ↔ REGISTRO_AIH (1,1) |
| PROCEDIMENTO — REGISTRO_AIH | PROCEDIMENTO (0,n) ↔ REGISTRO_AIH (1,1) |
| DIAGNOSTICO — REGISTRO_AIH | DIAGNOSTICO (0,n) ↔ REGISTRO_AIH (1,1) |
| CARATER_ATENDIMENTO — REGISTRO_AIH | CARATER_ATENDIMENTO (0,n) ↔ REGISTRO_AIH (1,1) |
| MOTIVO_SAIDA_PERMANENCIA — REGISTRO_AIH | MOTIVO (0,n) ↔ REGISTRO_AIH (1,1) |
| TIPO_LEITO — LEITO | TIPO_LEITO (1,n) ↔ LEITO (1,1) |
| LEITO — CAPACIDADE_LEITO | LEITO (0,n) ↔ CAPACIDADE_LEITO (1,1) |
| ESTABELECIMENTO_COMPETENCIA — CAPACIDADE_LEITO | ESTABELECIMENTO_COMPETENCIA (0,n) ↔ CAPACIDADE_LEITO (1,1) |
| MUNICIPIO — POPULACAO_MUNICIPAL | MUNICIPIO (0,n) ↔ POPULACAO_MUNICIPAL (1,1) |

O município de atendimento de um registro de AIH é obtido a partir do estabelecimento correspondente à competência. No modelo lógico normalizado, evita-se duplicar esse atributo quando ele pode ser derivado da relação com `ESTABELECIMENTO_COMPETENCIA`.

---

## 1.6 Modelo conceitual

O modelo conceitual representa as entidades do domínio e os relacionamentos necessários para integrar demanda, capacidade e população.

**[Inserir Figura 1 — Modelo Conceitual (DER), com cardinalidades mínima e máxima.]**

O `REGISTRO_AIH` ocupa o papel central no processo de demanda hospitalar. Ele se relaciona obrigatoriamente com o estabelecimento correspondente à competência, com o município de residência, com o procedimento realizado, com o diagnóstico principal, com o caráter do atendimento e com o motivo de saída ou permanência.

A capacidade de leitos é representada separadamente por `CAPACIDADE_LEITO`, associada ao estabelecimento em determinada competência e ao detalhamento de leito correspondente.

A população permanece em processo próprio por meio de `POPULACAO_MUNICIPAL`, relacionada ao município e ao ano de referência.

---

## 1.7 Modelo lógico relacional normalizado

O modelo lógico traduz as entidades conceituais para relações com chaves primárias e estrangeiras, preservando a normalização exigida para este capítulo.

**[Inserir Figura 2 — Modelo Lógico Relacional Normalizado, com PKs, FKs e cardinalidades mínima e máxima.]**

### 1.7.1 Relações principais

#### UF

- `cod_uf` — chave primária;
- `sigla_uf`;
- `nome_uf`.

#### MUNICIPIO

- `cod_ibge_7` — chave primária;
- `cod_datasus_6` — chave alternativa;
- `nome_municipio`;
- `cod_uf` — chave estrangeira para `UF`.

#### ESTABELECIMENTO

- `cnes` — chave primária.

#### ESTABELECIMENTO_COMPETENCIA

Chave primária composta por:

- `cnes`;
- `competencia`.

Também contém:

- `cod_ibge_7` — chave estrangeira para `MUNICIPIO`;
- tipo de unidade;
- tipo de gestão;
- natureza jurídica;
- vínculo SUS;
- CNPJ mantenedora;
- CEP.

#### REGISTRO_AIH

Possui uma chave técnica própria, `id_registro_aih`.

Relaciona-se ao estado histórico do estabelecimento pela combinação `cnes + competencia` e possui referências para:

- município de residência;
- procedimento;
- diagnóstico;
- caráter do atendimento;
- motivo de saída/permanência.

Também preserva atributos operacionais necessários ao processo, incluindo número da AIH, tipo de identificação, datas, dias de permanência, valor total e indicador de óbito.

#### PROCEDIMENTO

- `cod_procedimento` — chave primária;
- nome e descrição oficial.

#### DIAGNOSTICO

- `cod_diagnostico` — chave primária;
- descrição oficial.

#### CARATER_ATENDIMENTO

- `cod_carater` — chave primária;
- descrição oficial.

#### MOTIVO_SAIDA_PERMANENCIA

- `cod_motivo` — chave primária;
- descrição oficial.

#### TIPO_LEITO

- `cod_tipo_leito` — chave primária;
- descrição oficial.

#### LEITO

- `cod_leito` — chave primária;
- `cod_tipo_leito` — chave estrangeira;
- descrição do leito.

#### CAPACIDADE_LEITO

Chave primária composta por:

- `cnes`;
- `competencia`;
- `cod_leito`.

Possui as medidas:

- `qt_exist`;
- `qt_sus`.

#### POPULACAO_MUNICIPAL

Chave primária composta por:

- `cod_ibge_7`;
- `ano`.

Possui como medida:

- `populacao`.

---

## 1.8 Considerações do capítulo

A modelagem conceitual e lógica mantém separados processos com granularidades diferentes e evita a criação de relacionamentos artificiais apenas para unir as fontes.

O SIH/RD representa demanda hospitalar em nível de registro administrativo processado, o CNES/LT representa snapshots mensais de capacidade e o IBGE representa estimativas populacionais anuais. Essas diferenças serão preservadas no modelo dimensional apresentado no Capítulo 2.

