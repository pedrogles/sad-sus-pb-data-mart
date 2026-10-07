# BOUNDARY 5 — Historização / Role-playing

**Fase:** SAD — SUS PB — DATA ACQUISITION / QLIKVIEW IMPLEMENTATION DISCOVERY  
**Data de fechamento:** 07/10/2026  
**Status:** CONCLUÍDO

## 1. Objetivo

Definir a estratégia física de historização de `DIM_ESTABELECIMENTO` e a representação de dimensões role-playing, preservando a modelagem acadêmica aprovada e sem iniciar ainda a implementação definitiva no QlikView.

## 2. Evidência de entrada

O Boundary 3 demonstrou:

- `CNES` único por competência em 36/36 meses;
- 220.390 registros CNES/ST;
- 6.822 CNES distintos;
- 746 estabelecimentos com mudança em pelo menos um atributo histórico monitorado;
- cobertura de 100% nas integrações SIH ↔ ST e LT ↔ ST em todas as 36 competências.

A modelagem acadêmica já determinava que atributos de estabelecimento fossem interpretados no contexto temporal correspondente.

O Boundary 4 confirmou que nomes históricos não podem ser preenchidos retroativamente sem fonte oficial.

## 3. Historização de `DIM_ESTABELECIMENTO`

### DECISÃO CONFIRMADA

Na V1, `DIM_ESTABELECIMENTO` será uma dimensão histórica **versionada por competência mensal**.

Grão físico:

`1 linha = CNES × competência mensal`

Identidade natural:

`CNES`

Identidade da versão:

`CNES + competência → SK_ESTABELECIMENTO`

`SK_ESTABELECIMENTO` identifica uma versão histórica do estabelecimento; `CNES` continua representando a identidade cadastral.

### SCD Type 1

**REJEITADO.**

Substituir o estado anterior pelo atual aplicaria atributos posteriores retroativamente e destruiria o histórico.

### SCD Type 3

**REJEITADO.**

Não é adequado para até 36 snapshots mensais e vários atributos mutáveis.

### SCD Type 2 comprimido por intervalos

**NÃO ADOTADO NA V1.**

É tecnicamente possível representar intervalos de validade, mas a fonte CNES/ST já fornece snapshots mensais. Comprimir snapshots em intervalos e depois reconstruir associação temporal introduziria complexidade desnecessária neste escopo.

### Estratégia escolhida

Preservar snapshots mensais:

| SK_ESTABELECIMENTO | CNES | COMPETENCIA | atributos históricos |
|---|---|---|---|
| ... | ... | 2017-01 | ... |
| ... | ... | 2017-02 | ... |
| ... | ... | 2017-03 | ... |

A associação futura deve utilizar CNES + competência correspondente.

## 4. Nomes históricos

### DECISÃO CONFIRMADA

Quando houver nome histórico comprovado para a competência, utilizá-lo.

Quando não houver fonte comprovada:

- manter `NULL` / não informado;
- registrar a lacuna;
- não fazer forward fill;
- não fazer backfill;
- não aplicar nome atual retroativamente.

A lacuna documentada para 2017-01 a 2017-05 não bloqueia a dimensão.

## 5. Role-playing de `DIM_TEMPO`

A dimensão conceitual permanece única e conformada:

`DIM_TEMPO`

Papéis aprovados:

- competência da internação;
- data de internação;
- data de saída;
- competência CNES;
- ano da população.

### DECISÃO CONFIRMADA

No modelo associativo do QlikView, esses papéis poderão ser materializados como instâncias lógicas/aliases distintos, por exemplo:

- `DIM_TEMPO_COMPETENCIA`;
- `DIM_TEMPO_INTERNACAO`;
- `DIM_TEMPO_SAIDA`;
- `DIM_TEMPO_ANO`.

Esses nomes representam papéis físicos da mesma dimensão conformada, não novas dimensões de negócio.

## 6. Role-playing de `DIM_MUNICIPIO`

A dimensão conceitual permanece:

`DIM_MUNICIPIO`

Papéis:

- município de residência;
- município de atendimento;
- município de localização do estabelecimento;
- município da população.

### DECISÃO CONFIRMADA

No QlikView poderão existir aliases específicos, por exemplo:

- `DIM_MUNICIPIO_RESIDENCIA`;
- `DIM_MUNICIPIO_ATENDIMENTO`;
- `DIM_MUNICIPIO_LOCALIZACAO`;
- `DIM_MUNICIPIO_POPULACAO`.

Isso evita interpretar automaticamente um município selecionado como todos os papéis simultaneamente.

## 7. Fonte física canônica

### DECISÃO CONFIRMADA

Não duplicar fisicamente a lógica de construção de Tempo ou Município por papel.

Estratégia:

`uma fonte física canônica → múltiplos LOADs/aliases associativos`

Exemplo conceitual:

`DIM_TEMPO.qvd → competência / internação / saída / ano`

`DIM_MUNICIPIO.qvd → residência / atendimento / localização / população`

A implementação concreta de `LOAD`, nomes de campos e QVDs pertence ao Boundary 6.

## 8. Restrição do modelo associativo QlikView

### FATO VERIFICADO

O modelo acadêmico possui três fatos com dimensões conformadas compartilhadas:

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`.

Ao transportar isso diretamente para o modelo associativo do QlikView, múltiplos campos compartilhados entre duas tabelas podem gerar synthetic keys; caminhos circulares também podem gerar ambiguidade.

### CONSEQUÊNCIA

A constelação acadêmica permanece válida, mas sua representação física no QlikView precisa de uma estratégia específica.

Essa decisão foi deliberadamente encaminhada ao Boundary 6.

## 9. Alternativas encaminhadas ao Boundary 6

Comparar formalmente:

1. **Link Table**;
2. **fato física concatenada no modelo associativo**, preservando QVDs factuais separados.

Hipótese inicial para teste:

fato concatenada pode ser adequada ao volume do projeto, mas **não está aprovada** até que sejam testadas:

- semântica de residência × atendimento;
- capacidade;
- população;
- indicadores cruzados;
- synthetic keys;
- circular references;
- rastreabilidade das três granularidades.

## 10. Matriz de decisões

| Questão | Decisão |
|---|---|
| Historização estabelecimento | snapshot mensal versionado |
| Grão histórico | CNES × competência |
| `SK_ESTABELECIMENTO` | identifica a versão histórica |
| `CNES` | identidade natural |
| SCD Type 1 | não |
| SCD Type 3 | não |
| SCD2 comprimido por intervalos | não na V1 |
| aplicar atributos atuais ao passado | proibido |
| preencher nome histórico sem fonte | proibido |
| `DIM_TEMPO` | dimensão conformada única |
| Tempo no QlikView | aliases por papel |
| `DIM_MUNICIPIO` | dimensão conformada única |
| Município no QlikView | aliases por papel |
| duplicar QVD por papel | não |
| estratégia multi-fato | Boundary 6 |

## 11. Impacto na primeira entrega

Nenhuma alteração é necessária em:

- fatos;
- dimensões;
- granularidades;
- Star Schema;
- constelação dimensional;
- DER;
- modelo lógico;
- relatório dos Capítulos 1 e 2.

As decisões deste boundary são físicas/de implementação.

## 12. Próximo boundary

**BOUNDARY 6 — Arquitetura física QlikView**

Deve fechar:

- fato concatenada vs Link Table;
- convenções de chaves e nomes;
- prevenção de synthetic keys e circular references;
- organização de QVD/QVW;
- separação BASE → EXTRAÇÃO → TRANSFORMAÇÃO → PAINEL;
- tratamento do drift de schema CNES/ST;
- testes de reconciliação necessários antes da implementação.

## 13. Veredito

### `APROVADO PARA PROSSEGUIR`

A historização e o role-playing estão suficientemente definidos para avançar ao desenho físico do QlikView.
