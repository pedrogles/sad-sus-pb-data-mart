# BOUNDARY 6 — Arquitetura Física QlikView

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** DATA ACQUISITION / QLIKVIEW IMPLEMENTATION DISCOVERY  
**Ferramenta obrigatória:** QlikView 12  
**Data de fechamento:** 07/10/2026  
**Status:** CONCLUÍDO

## 1. Objetivo

Definir a arquitetura física de implementação no QlikView 12 sem iniciar ainda a implementação definitiva.

Este boundary deve:

1. comparar fato concatenada vs Link Table;
2. definir como representar fisicamente as três fatos aprovadas;
3. preservar as dimensões conformadas e os papéis de Tempo/Município;
4. definir convenções de associação e chaves;
5. evitar synthetic keys e circular references;
6. preservar o fluxo didático BASE → EXTRAÇÃO → TRANSFORMAÇÃO → PAINEL;
7. fechar a estratégia para o drift de schema CNES/ST em 2019-12;
8. definir os controles de reconciliação para o próximo readiness gate.

Não altera a modelagem acadêmica dos Capítulos 1 e 2.

---

## 2. Fontes de verdade consultadas

### Repositório

- `AGENTS.md`;
- `docs/project/current-state.md`;
- `docs/academic/requirements.md`;
- `docs/academic/chapter-1-2-modeling.md`;
- `docs/discovery/boundary-3-full-dataset-validation.md`;
- `docs/discovery/boundary-4-auxiliary-references.md`;
- `docs/discovery/boundary-5-historization-role-playing.md`.

### Material da disciplina

A referência didática do professor estabelece a organização:

```text
BASE
  ↓
EXTRACAO
  ├── EXT.qvw
  └── QVD
  ↓
TRANSFORMACAO
  ├── QVW
  └── QVD
  ↓
PAINEL
  └── QVW
```

Essa separação será preservada.

### Documentação Qlik oficial

Referências técnicas consultadas:

- QlikView — Concatenating tables:
  https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/LoadData/concatenate-tables.htm
- QlikView — Synthetic keys:
  https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/synthetic-keys.htm
- QlikView — Circular references:
  https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/LoadData/understand-circular-references.htm
- QlikView — QVD files:
  https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/QVD_files.htm
- QlikView — Include / Must_Include:
  https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Scripting/SystemVariables/Include.htm
- QlikView — Hash128:
  https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Scripting/StringFunctions/Hash128.htm

---

## 3. Restrições arquiteturais herdadas

### FATO VERIFICADO

A modelagem acadêmica aprovada possui três fatos separadas:

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`.

A documentação acadêmica afirma explicitamente que as três fatos não serão fundidas em uma única tabela dimensional.

### FATO VERIFICADO

As granularidades são distintas:

- Internação: 1 registro administrativo RD / AIH processada;
- Capacidade: estabelecimento × competência × código de leito;
- População: município × ano.

### FATO VERIFICADO

O Boundary 5 definiu:

- `DIM_ESTABELECIMENTO` versionada por snapshot mensal;
- `DIM_TEMPO` conformada com múltiplos papéis;
- `DIM_MUNICIPIO` conformada com múltiplos papéis;
- aliases físicos permitidos no QlikView;
- estratégia multi-fato ainda pendente.

---

# 4. Comparação — fato concatenada vs Link Table

## 4.1 Alternativa A — fato concatenada

O QlikView permite concatenar tabelas mesmo com conjuntos diferentes de campos. Os campos inexistentes em uma origem tornam-se NULL nas linhas provenientes das demais origens.

### Vantagens

- modelo associativo central simples;
- elimina associações diretas entre várias fatos;
- reduz risco de synthetic keys entre fatos;
- implementação relativamente curta;
- adequada em muitos cenários Qlik multi-evento.

### Desvantagens neste projeto

1. as três fatos possuem granularidades e semânticas diferentes;
2. as medidas são distintas e parcialmente semi-aditivas;
3. o modelo acadêmico aprovado afirma que as três fatos não serão fundidas;
4. uma tabela física única poderia dificultar a rastreabilidade didática entre modelo acadêmico e implementação;
5. o tratamento dos múltiplos papéis municipais e temporais exigiria campos esparsos e regras adicionais;
6. expressões poderiam somar medidas incompatíveis caso o tipo de registro não fosse filtrado corretamente.

### VEREDITO

**NÃO ADOTADA COMO ARQUITETURA PRINCIPAL.**

A alternativa é tecnicamente viável no QlikView, mas introduziria divergência desnecessária entre a representação física e a modelagem acadêmica já fechada.

Não há evidência de benefício suficiente que justifique essa divergência.

---

## 4.2 Alternativa B — Link Table

A Link Table funciona como ponte física entre múltiplas fatos e dimensões compartilhadas.

As fatos permanecem separadas e passam a associar-se às dimensões conformadas através de uma chave técnica única de ligação.

### Vantagens neste projeto

- preserva as três fatos aprovadas;
- preserva granularidades distintas;
- centraliza dimensões compartilhadas;
- evita múltiplos campos iguais diretamente entre fatos;
- permite controlar explicitamente papéis de Tempo, Município e Estabelecimento;
- reduz risco de synthetic keys;
- mantém rastreabilidade entre modelo acadêmico e implementação;
- permite manter dimensões exclusivas diretamente ligadas à fato correspondente.

### Custos

- mais uma estrutura física;
- exige disciplina na geração da chave de ligação;
- exige testes de associação e cobertura;
- aumenta a complexidade do script comparada à simples concatenação.

### DECISÃO CONFIRMADA

**A arquitetura física principal usará Link Table.**

A Link Table é uma construção física do QlikView e **não constitui uma nova entidade, dimensão ou fato de negócio**.

As três fatos acadêmicas permanecem inalteradas.

---

# 5. Arquitetura associativa aprovada

Visão lógica:

```text
                        DIM_TEMPO_COMPETENCIA
                                 |
DIM_MUNICIPIO_RESIDENCIA -- LINK_ANALISE -- DIM_MUNICIPIO_SERVICO
                                 |
                         DIM_TEMPO_ANO
                                 |
                       DIM_ESTABELECIMENTO
                                 |
             +-------------------+-------------------+
             |                   |                   |
     FATO_INTERNACAO   FATO_CAPACIDADE_LEITO  FATO_POPULACAO
             |                   |
     dimensões exclusivas   DIM_TIPO_LEITO
```

A representação acima é conceitual. No QlikView, as três fatos compartilham somente `%LINK_KEY` com `LINK_ANALISE`.

---

# 6. LINK_ANALISE

## 6.1 Objetivo

Concentrar as chaves das dimensões conformadas compartilhadas entre os processos factuais.

Campos físicos planejados:

- `%LINK_KEY`;
- `%SK_TEMPO_COMPETENCIA`;
- `%SK_TEMPO_ANO`;
- `%SK_MUNICIPIO_RESIDENCIA`;
- `%SK_MUNICIPIO_SERVICO`;
- `%SK_ESTABELECIMENTO`;
- campo técnico de processo/origem quando necessário para auditoria.

Nem todos os campos estarão preenchidos em todos os tipos de combinação.

---

## 6.2 Município — eixos físicos

### Residência

`%SK_MUNICIPIO_RESIDENCIA`

Usado por:

- `FATO_INTERNACAO` → município de residência;
- `FATO_POPULACAO` → município da população.

Objetivo analítico principal:

`internações de residentes / população`.

### Serviço

`%SK_MUNICIPIO_SERVICO`

Usado por:

- `FATO_INTERNACAO` → município de atendimento;
- `FATO_CAPACIDADE_LEITO` → município de localização do estabelecimento;
- `FATO_POPULACAO` → município da população.

O Boundary 3 validou `SIH.MUNIC_MOV ↔ CNES/ST.CODUFMUN` com 100% de cobertura nas 36 competências, sustentando o eixo comum atendimento/localização.

Objetivos analíticos:

- leitos por habitante;
- internações realizadas por leito;
- distribuição territorial da oferta/demanda processada.

### Regra para população

Uma ocorrência de `FATO_POPULACAO` poderá fornecer a mesma chave municipal aos dois eixos físicos:

- residência;
- serviço.

Isso não duplica a fato; apenas permite que a mesma população anual participe de análises com semânticas municipais diferentes.

Em objetos que combinem simultaneamente residência e serviço, expressões populacionais devem declarar explicitamente qual papel municipal constitui o denominador.

---

# 7. Tempo — eixos físicos

## 7.1 Competência

`%SK_TEMPO_COMPETENCIA`

Usado por:

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`.

Permite comparação mensal entre demanda processada e capacidade.

## 7.2 Ano analítico

`%SK_TEMPO_ANO`

Usado por:

- `FATO_INTERNACAO`, derivado da competência;
- `FATO_CAPACIDADE_LEITO`, derivado da competência;
- `FATO_POPULACAO`, ano de referência.

Esse eixo sustenta os indicadores anuais comparativos.

## 7.3 Papéis exclusivos de internação

Continuam fora da Link Table:

- `%SK_TEMPO_INTERNACAO`;
- `%SK_TEMPO_SAIDA`.

Eles se ligam diretamente às aliases de `DIM_TEMPO` correspondentes porque não são compartilhados pelas demais fatos.

---

# 8. Estabelecimento

`%SK_ESTABELECIMENTO` permanece na Link Table para:

- internação;
- capacidade.

### DECISÃO CONFIRMADA

A chave representa a **versão histórica por competência**, conforme Boundary 5.

A identidade natural continua sendo o CNES, mas a associação analítica usa a versão histórica apropriada.

---

# 9. Dimensões exclusivas

Permanecem ligadas diretamente à respectiva fato porque não são compartilhadas entre processos.

## FATO_INTERNACAO

- `DIM_PROCEDIMENTO`;
- `DIM_DIAGNOSTICO`;
- `DIM_CARATER_ATENDIMENTO`;
- `DIM_MOTIVO_SAIDA_PERMANENCIA`;
- `DIM_TEMPO_INTERNACAO`;
- `DIM_TEMPO_SAIDA`.

## FATO_CAPACIDADE_LEITO

- `DIM_TIPO_LEITO`.

## FATO_POPULACAO

Não possui dimensão exclusiva adicional na V1.

---

# 10. Regra de associação QlikView

### DECISÃO CONFIRMADA

Somente campos destinados intencionalmente a relacionar tabelas podem possuir o mesmo nome em tabelas diferentes.

O QlikView associa tabelas pelo nome do campo.

Campos descritivos pertencentes a papéis diferentes devem ser renomeados.

Exemplos:

```text
Residencia_Municipio
Residencia_UF

Servico_Municipio
Servico_UF

Competencia_Ano
Competencia_Mes

Internacao_Data
Saida_Data
```

Não usar genericamente `Municipio`, `UF`, `Ano` ou `Data` em várias aliases se isso criar associações não desejadas.

---

# 11. Synthetic keys

### REGRA DE IMPLEMENTAÇÃO

O modelo final não deve possuir synthetic key gerada por erro de modelagem.

Critério de aceite:

```text
$Syn*: 0 estruturas não justificadas
```

No desenho aprovado:

- cada fato compartilha apenas `%LINK_KEY` com `LINK_ANALISE`;
- cada dimensão deve compartilhar apenas sua chave técnica correspondente;
- aliases role-playing devem possuir campos descritivos renomeados.

A documentação oficial do QlikView informa que synthetic keys surgem quando duas ou mais tabelas possuem dois ou mais campos em comum e recomenda revisar esses casos.

---

# 12. Circular references

### REGRA DE IMPLEMENTAÇÃO

O painel não poderá depender de QlikView resolver loops automaticamente por loosely coupled tables.

Critério de aceite:

- nenhuma circular reference;
- nenhuma tabela tornada loosely coupled como correção automática do modelo.

Loops devem ser corrigidos no script/modelo antes do readiness gate.

---

# 13. Convenção de chaves

## 13.1 Prefixo

Campos técnicos de associação usarão prefixo:

`%`

Exemplos:

- `%LINK_KEY`;
- `%SK_ESTABELECIMENTO`;
- `%SK_MUNICIPIO_RESIDENCIA`.

### Motivo

Distinguir campos técnicos dos campos analíticos e permitir ocultá-los da interface por `HidePrefix`, se desejado.

---

## 13.2 Persistência

### DECISÃO CONFIRMADA

Chaves persistidas em QVD que precisem ser reproduzíveis entre reloads devem usar representação determinística.

Preferência:

`Hash128(...)`

O QlikView documenta que `AutoNumberHash128` gera inteiros dependentes da ordem dentro do mesmo data load e não deve ser usado quando a chave precisa permanecer estável entre cargas independentes.

### Uso permitido de AutoNumber

Pode ser avaliado dentro do `PAINEL.qvw` para otimização estritamente interna, desde que todas as tabelas relacionadas sejam geradas no mesmo reload.

Não será usado como chave canônica persistida em QVD.

---

# 14. Organização física

A estrutura seguirá o modelo ensinado pelo professor sem criar uma arquitetura paralela.

```text
BASE/
    dados originais / arquivos auxiliares

EXTRACAO/
    EXT.qvw
    ext_main.qvs
    QVD/
        SRC_SIH_RD.qvd
        SRC_CNES_LT.qvd
        SRC_CNES_ST.qvd
        SRC_IBGE_POPULACAO.qvd
        referências auxiliares quando aplicável

TRANSFORMACAO/
    TRANSF.qvw
    transf_main.qvs
    QVD/
        FATO_INTERNACAO.qvd
        FATO_CAPACIDADE_LEITO.qvd
        FATO_POPULACAO.qvd
        DIM_TEMPO.qvd
        DIM_MUNICIPIO.qvd
        DIM_ESTABELECIMENTO.qvd
        DIM_PROCEDIMENTO.qvd
        DIM_DIAGNOSTICO.qvd
        DIM_CARATER_ATENDIMENTO.qvd
        DIM_MOTIVO_SAIDA_PERMANENCIA.qvd
        DIM_TIPO_LEITO.qvd
        LINK_ANALISE.qvd

PAINEL/
    PAINEL.qvw
    painel_main.qvs
```

Os nomes acima são a convenção inicial aprovada para o plano de implementação. Ajustes puramente mecânicos de nome podem ser feitos no Boundary 7 desde que não mudem a arquitetura.

---

# 15. Scripts externos versionáveis

### DECISÃO CONFIRMADA

O código relevante não ficará apenas dentro dos arquivos binários `.qvw`.

Cada QVW utilizará script textual externo versionável, inicialmente:

- `EXTRACAO/ext_main.qvs`;
- `TRANSFORMACAO/transf_main.qvs`;
- `PAINEL/painel_main.qvs`.

O QVW chamará esses scripts por `$(Must_Include=...)`.

### Motivo

- revisão por diff;
- auditabilidade;
- recuperação independente do binário;
- preservação das regras de transformação no Git.

`Must_Include` é preferido a `Include` porque falha explicitamente se o arquivo estiver ausente.

Não subdividir os scripts em dezenas de includes antes de existir necessidade concreta.

---

# 16. Estratégia de QVD

## EXTRAÇÃO

### DECISÃO CONFIRMADA

Consolidar cada família principal em um QVD de staging, mantendo campos de rastreabilidade como arquivo/competência de origem.

Motivo:

- período histórico fechado;
- transformação simplificada;
- menos artefatos que 108 QVDs mensais;
- origem mensal ainda auditável por metadados dentro da tabela.

## TRANSFORMAÇÃO

Gerar os três QVDs factuais, oito QVDs dimensionais e a Link Table.

## PAINEL

Carregar prioritariamente os QVDs transformados.

A documentação oficial informa que QVD é formato nativo otimizado do QlikView e que cargas QVD podem ser significativamente mais rápidas que fontes comuns.

Renomear campos durante a leitura de QVD é compatível com carga otimizada; transformações adicionais podem desabilitá-la.

### Consequência

Aliases role-playing devem ser preferencialmente criados apenas por renomeação no LOAD do QVD, mantendo o painel simples.

---

# 17. Role-playing no painel

## DIM_TEMPO

Uma única fonte física:

`DIM_TEMPO.qvd`

Aliases físicos:

- `DIM_TEMPO_COMPETENCIA`;
- `DIM_TEMPO_ANO`;
- `DIM_TEMPO_INTERNACAO`;
- `DIM_TEMPO_SAIDA`.

Cada alias deve renomear a chave e os atributos descritivos.

## DIM_MUNICIPIO

Uma única fonte física:

`DIM_MUNICIPIO.qvd`

Aliases:

- `DIM_MUNICIPIO_RESIDENCIA`;
- `DIM_MUNICIPIO_SERVICO`.

`DIM_MUNICIPIO_SERVICO` representa, conforme o fato:

- atendimento da internação;
- localização da capacidade;
- município da população usado nos indicadores de oferta/serviço.

A distinção acadêmica entre residência e atendimento permanece preservada.

---

# 18. Estratégia para CNES/ST 2019-12

O Boundary 3 identificou:

- 201 campos em 35/36 competências;
- 208 campos em `STPB1912.dbc`;
- sete campos adicionais;
- alteração de largura de três campos;
- deslocamento ordinal de campos posteriores;
- nenhum dos campos usados atualmente pela dimensão de estabelecimento mudou nome/tipo relevante.

### DECISÃO CONFIRMADA

A extração de ST será **por nome explícito de campo**, nunca por posição ordinal.

Campos aprovados atualmente:

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

### Regra

Não usar `LOAD *` como contrato de schema para CNES/ST.

Campos adicionais desconhecidos não entram automaticamente no Data Mart.

Se um campo obrigatório aprovado estiver ausente, a carga deve falhar ou registrar erro explícito; não preencher silenciosamente.

---

# 19. Pré-processamento DBC

### FATO VERIFICADO

O Boundary 3 precisou de decoder local para os arquivos DBC.

### DECISÃO ARQUITETURAL

A conversão DBC → formato legível pelo QlikView será tratada como etapa técnica de aquisição/extração, anterior ao LOAD principal do `EXT.qvw`.

Ela poderá utilizar utilitário externo versionável, desde que:

- os DBC originais permaneçam imutáveis;
- a transformação seja reproduzível;
- hashes/nome de origem sejam preservados;
- o QlikView continue responsável pela extração para QVD, transformação dimensional e apresentação;
- a ferramenta externa não se torne fonte de verdade das regras de negócio.

A implementação concreta do conversor e sua forma de chamada será fechada no Boundary 7.

---

# 20. Medidas e aditividade

### FATO_INTERNACAO

Medidas mantidas separadamente:

- `QTD_REGISTRO_AIH`;
- `QTD_INTERNACAO`;
- `DIAS_PERMANENCIA`;
- `VALOR_TOTAL`;
- `INDICADOR_OBITO`.

### FATO_CAPACIDADE_LEITO

- `QTD_LEITOS_EXISTENTES`;
- `QTD_LEITOS_SUS`;
- derivável: `QTD_LEITOS_NAO_SUS`.

Capacidade permanece semi-aditiva no tempo.

### FATO_POPULACAO

- `POPULACAO_ESTIMADA`.

População permanece semi-aditiva no tempo.

### REGRA

Não criar campo genérico `VALOR` comum entre fatos.

Isso evita agregação acidental de medidas de naturezas incompatíveis.

---

# 21. Indicadores cruzados e papéis

## Internações por 1.000 habitantes

Eixos:

- município residência;
- ano analítico.

```text
SUM(QTD_INTERNACAO)
/
POPULACAO_ESTIMADA
× 1.000
```

O denominador usa população do município de residência.

## Leitos SUS por 1.000 habitantes

Eixos:

- município serviço;
- ano analítico.

```text
média mensal de QTD_LEITOS_SUS
/
POPULACAO_ESTIMADA
× 1.000
```

## Internações por leito

Eixos:

- município serviço;
- período compatível.

```text
internações realizadas
/
capacidade média
```

Não denominar taxa de ocupação.

## Fluxo residência → serviço

Usa simultaneamente:

- município residência;
- município serviço.

Nesse tipo de análise, população não deve ser incluída sem expressão que explicite qual papel municipal constitui o denominador.

---

# 22. Controles de reconciliação obrigatórios

## 22.1 Cobertura física

- RD: 36/36;
- LT: 36/36;
- ST: 36/36;
- período: 2017-01 a 2019-12.

## 22.2 Contagens de staging

Devem reconciliar com o Boundary 3:

- RD: **566.672** registros;
- LT: **35.518** registros;
- ST: **220.390** registros.

IBGE deve manter 223 municípios por ano no recorte PB.

## 22.3 Grãos

### Internação

- `SK_REGISTRO_INTERNACAO` único;
- `N_AIH` não deve ser testado como PK;
- domínio de `IDENT` preservado;
- `IDENT=5` não conta como nova internação.

### Capacidade

- `CNES + COMPETEN + CODLEITO` único;
- 0 medidas negativas;
- validar `QT_NSUS = QT_EXIST - QT_SUS` quando utilizado.

### População

- município × ano único;
- 223 municípios PB por ano.

## 22.4 Dimensões

- 0 chaves obrigatórias órfãs;
- cobertura de estabelecimento preservada;
- `DIM_ESTABELECIMENTO` não pode usar versão de competência posterior;
- referências auxiliares não resolvidas devem ser registradas e não descartadas silenciosamente.

## 22.5 Link Table

- toda linha factual deve possuir exatamente uma `%LINK_KEY`;
- toda `%LINK_KEY` factual deve existir em `LINK_ANALISE`;
- nenhuma combinação da Link Table deve alterar a quantidade de registros das fatos;
- chaves de dimensão não aplicáveis devem permanecer nulas, não receber valores artificiais.

## 22.6 Modelo Qlik

- 0 circular references;
- 0 synthetic keys não justificadas;
- nenhuma associação por campos descritivos homônimos;
- Table Viewer deve mostrar o caminho esperado.

## 22.7 Indicadores

Reconciliar, fora das visualizações:

- internações por ano/município de residência;
- internações por ano/município de serviço;
- média mensal de leitos SUS por município/ano;
- população por município/ano;
- internações por 1.000 habitantes;
- leitos SUS por 1.000 habitantes;
- relação internações/leito.

O valor calculado no painel deve coincidir com agregação de controle produzida a partir dos QVDs transformados.

---

# 23. Gates de implementação

O Boundary 7 deverá transformar esta arquitetura em plano executável.

A implementação definitiva somente poderá iniciar após Boundary 8 — Readiness.

Antes do readiness, deve existir:

1. estrutura de diretórios definida;
2. scripts planejados;
3. mecanismo DBC definido;
4. fontes auxiliares materializáveis;
5. contratos de schema;
6. matriz de testes;
7. regra de geração das chaves;
8. estratégia de erro/log;
9. critério objetivo de sucesso da carga;
10. estratégia de rollback/reexecução.

---

# 24. Decisões finais do Boundary 6

| Tema | Decisão |
|---|---|
| Fato concatenada | rejeitada como arquitetura principal |
| Link Table | **aprovada** |
| Três fatos acadêmicas | preservadas |
| `LINK_ANALISE` | ponte física, não entidade de negócio |
| Município residência | eixo compartilhado Internação + População |
| Município serviço | eixo compartilhado Internação + Capacidade + População |
| Tempo competência | compartilhado Internação + Capacidade |
| Tempo ano | compartilhado pelas três fatos |
| Tempo internação/saída | direto na FATO_INTERNACAO |
| Estabelecimento | compartilhado Internação + Capacidade via Link Table |
| Chaves QVD persistentes | determinísticas, preferencialmente `Hash128` |
| Prefixo de chave | `%` |
| Scripts canônicos | `.qvs` externos + `Must_Include` |
| QVDs de staging | consolidados por família de fonte |
| QVDs transformados | 3 fatos + 8 dimensões + Link Table |
| CNES/ST drift | seleção explícita por nome de campo |
| `LOAD *` em ST | não usar como contrato de schema |
| Synthetic keys | 0 não justificadas |
| Circular references | 0 |
| Próxima etapa | Boundary 7 — Plano de implementação |

---

# 25. Impacto na arquitetura acadêmica

### DECISÃO CONFIRMADA

Nenhuma alteração foi feita em:

- Capítulo 1;
- Capítulo 2;
- DER;
- modelo lógico;
- Star Schema;
- constelação dimensional;
- três fatos;
- oito dimensões;
- granularidades;
- regras analíticas.

A Link Table existe exclusivamente para adaptar a constelação ao modelo associativo do QlikView.

---

# 26. Veredito

## `APROVADO PARA PLANO DE IMPLEMENTAÇÃO`

A arquitetura física do QlikView está suficientemente definida.

Próxima etapa:

**BOUNDARY 7 — Plano de implementação**.
