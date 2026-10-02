# Capítulo 2 — Modelagem Dimensional

## Status

**CONTEÚDO FECHADO PARA A PRIMEIRA ENTREGA**

O nome do arquivo é mantido por histórico; o conteúdo abaixo corresponde à versão utilizada na montagem do relatório.

## 2.1 Estrutura dimensional escolhida

Para o Data Mart foi escolhida a estrutura **Star Schema (Modelo Estrela)** em cada processo factual.

O conjunto completo possui três tabelas fato que compartilham dimensões conformadas. Por esse motivo, o modelo completo pode ser descrito tecnicamente como uma **constelação de esquemas estrela**.

A escolha permanece classificada como Modelo Estrela para fins do requisito acadêmico, pois as dimensões do Data Mart serão desnormalizadas. Não será utilizado Snowflake Schema para decompor hierarquias como Município → UF ou Tipo de Leito → Detalhamento de Leito em várias tabelas dimensionais.

---

## 2.2 Justificativa da escolha

O Modelo Estrela foi escolhido porque a estrutura identificada na validação apresenta dimensões relativamente pequenas em comparação às tabelas fato e porque o objetivo do Data Mart é facilitar consultas analíticas no QlikView.

Em comparação ao Snowflake, a alternativa escolhida reduz a quantidade de associações necessárias entre as tabelas e mantém os atributos descritivos próximos ao processo analisado.

Exemplos de desnormalização deliberada são:

- UF armazenada como atributo de `DIM_MUNICIPIO`;
- tipo de leito e detalhamento do leito armazenados na mesma `DIM_TIPO_LEITO`;
- atributos cadastrais analíticos do estabelecimento armazenados em `DIM_ESTABELECIMENTO`;
- hierarquias analíticas do SIGTAP incorporadas em `DIM_PROCEDIMENTO`.

O modelo lógico apresentado no Capítulo 1 continua normalizado. A desnormalização é aplicada somente na camada dimensional destinada à análise.

---

## 2.3 Processos factuais e granularidades

O Data Mart possui três processos factuais distintos.

| Tabela fato | Granularidade |
|---|---|
| `FATO_INTERNACAO` | 1 registro RD / AIH processada |
| `FATO_CAPACIDADE_LEITO` | estabelecimento × competência mensal × código de leito |
| `FATO_POPULACAO` | município × ano |

As três granularidades não são compatíveis com a criação de uma única tabela fato. Se população anual ou capacidade mensal fossem repetidas em cada registro de internação, medidas de estoque seriam duplicadas artificialmente e agregações simples poderiam produzir resultados incorretos. Por isso, internações, capacidade e população permanecem em fatos distintas e compartilham somente dimensões com significado comum.

---

## 2.4 Dimensões conformadas

Foram definidas oito dimensões, todas derivadas de necessidades analíticas identificadas nas fontes e nas regras de negócio. Elas não foram criadas apenas para atingir o mínimo acadêmico de seis dimensões:

1. `DIM_TEMPO`;
2. `DIM_MUNICIPIO`;
3. `DIM_ESTABELECIMENTO`;
4. `DIM_PROCEDIMENTO`;
5. `DIM_DIAGNOSTICO`;
6. `DIM_CARATER_ATENDIMENTO`;
7. `DIM_MOTIVO_SAIDA_PERMANENCIA`;
8. `DIM_TIPO_LEITO`.

### DIM_TEMPO

É utilizada em diferentes papéis:

- competência da internação;
- data de internação;
- data de saída;
- competência da capacidade de leitos;
- ano de referência populacional.

### DIM_MUNICIPIO

Permite representar:

- município de residência;
- município de atendimento;
- município de localização do estabelecimento;
- município da população.

A dimensão conterá, no mínimo:

- chave substituta;
- código IBGE de sete dígitos;
- código DATASUS de seis dígitos;
- nome do município;
- UF.

### DIM_ESTABELECIMENTO

Contém a chave substituta e o código CNES, além dos atributos cadastrais analiticamente relevantes.

Como os checkpoints do CNES mostraram alterações históricas em atributos de um mesmo estabelecimento, a dimensão deverá preservar versões históricas dos atributos relevantes durante a implementação.

### DIM_PROCEDIMENTO

É baseada no procedimento realizado do SIH e será enriquecida pela referência oficial do SIGTAP.

Poderá conter:

- código do procedimento;
- nome;
- grupo;
- subgrupo;
- forma de organização.

### DIM_DIAGNOSTICO

Representa o diagnóstico principal da internação segundo a CID-10.

### DIM_CARATER_ATENDIMENTO

Representa o domínio oficial do caráter do atendimento utilizado pelo SIH.

### DIM_MOTIVO_SAIDA_PERMANENCIA

Representa a classificação oficial de encerramento ou permanência associada ao registro da internação.

### DIM_TIPO_LEITO

Desnormaliza a estrutura de tipo e detalhamento do leito e contém:

- código do tipo;
- descrição do tipo;
- código do leito;
- descrição/especialidade do leito.

---

## 2.5 FATO_INTERNACAO

A granularidade de `FATO_INTERNACAO` é:

**1 linha = 1 registro RD / AIH processada.**

Chaves dimensionais:

- tempo da competência;
- tempo da internação;
- tempo da saída;
- município de residência;
- município de atendimento;
- estabelecimento;
- procedimento;
- diagnóstico;
- caráter do atendimento;
- motivo de saída/permanência.

Medidas e indicadores de linha:

- quantidade de registro AIH;
- quantidade de internação;
- dias de permanência;
- valor total;
- indicador de óbito.

A medida `QTD_INTERNACAO` deverá assumir valor zero para registros de continuidade que não representem nova internação.

**Figura 3 — Esquema Estrela do processo de Internação — inserida no relatório final de impressão.**

---

## 2.6 FATO_CAPACIDADE_LEITO

A granularidade de `FATO_CAPACIDADE_LEITO` é:

**1 linha = estabelecimento × competência × código de leito.**

Dimensões:

- tempo;
- município de localização;
- estabelecimento;
- tipo/detalhamento de leito.

Medidas:

- quantidade de leitos existentes;
- quantidade de leitos SUS.

Essas medidas são semi-aditivas no tempo. Para os indicadores anuais deste projeto, será utilizada a **média dos doze snapshots mensais disponíveis do ano**, e não a soma direta das competências, porque cada mês representa um estoque de capacidade naquele momento.

**Figura 4 — Esquema Estrela do processo de Capacidade de Leitos — inserida no relatório final de impressão.**

---

## 2.7 FATO_POPULACAO

A granularidade de `FATO_POPULACAO` é:

**1 linha = município × ano.**

Dimensões:

- tempo;
- município.

Medida:

- população estimada.

A população também é semi-aditiva no tempo e será utilizada principalmente como denominador de indicadores municipais.

Ela foi modelada como tabela fato, e não como simples atributo de `DIM_MUNICIPIO`, porque é uma **medida quantitativa que varia no tempo** e possui granularidade própria município × ano. Tratá-la como atributo fixo do município eliminaria essa variação temporal e dificultaria o relacionamento correto com os indicadores anuais.

**Figura 5 — Esquema Estrela do processo de População — inserida no relatório final de impressão.**

---

## 2.8 Constelação dimensional

As três estrelas compartilham dimensões conformadas.

| Dimensão | Internação | Capacidade | População |
|---|:---:|:---:|:---:|
| `DIM_TEMPO` | ✓ | ✓ | ✓ |
| `DIM_MUNICIPIO` | ✓ | ✓ | ✓ |
| `DIM_ESTABELECIMENTO` | ✓ | ✓ | — |
| `DIM_PROCEDIMENTO` | ✓ | — | — |
| `DIM_DIAGNOSTICO` | ✓ | — | — |
| `DIM_CARATER_ATENDIMENTO` | ✓ | — | — |
| `DIM_MOTIVO_SAIDA_PERMANENCIA` | ✓ | — | — |
| `DIM_TIPO_LEITO` | — | ✓ | — |

**Figura 6 — Modelo Dimensional completo: constelação de esquemas estrela — inserida no relatório final de impressão.**

---

## 2.9 Indicadores derivados

### Internações por 1.000 habitantes

```text
(Internações de residentes no município e ano / População estimada do município e ano) × 1.000
```

### Leitos SUS por 1.000 habitantes

```text
(Média mensal de leitos SUS no município e ano / População estimada do município e ano) × 1.000
```

### Relação entre internações e leitos

```text
Internações realizadas no município e período / Capacidade média de leitos no mesmo município e período
```

Esse indicador representa uma relação descritiva entre demanda e capacidade e não deve ser denominado taxa de ocupação.

### Fluxo entre município de residência e município de atendimento

A comparação dos dois papéis de `DIM_MUNICIPIO` permitirá analisar deslocamento dos residentes e concentração de atendimentos entre municípios.

---

## 2.10 Considerações do capítulo

A estrutura dimensional escolhida preserva as granularidades próprias das três fontes e permite compartilhar dimensões comuns sem forçar registros de naturezas diferentes para uma mesma tabela fato.

O uso de uma constelação de estrelas mantém a simplicidade das dimensões desnormalizadas e atende às necessidades analíticas identificadas para a demanda hospitalar, a capacidade de leitos e a população.

