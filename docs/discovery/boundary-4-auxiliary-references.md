# BOUNDARY 4 — Referências Auxiliares

**Fase:** SAD — SUS PB — DATA ACQUISITION / QLIKVIEW IMPLEMENTATION DISCOVERY  
**Modo:** READ-ONLY / OFFICIAL SOURCE DISCOVERY  
**Data de fechamento:** 07/10/2026  
**Status:** CONCLUÍDO

## 1. Objetivo

Fechar, com evidência oficial suficiente para implementação futura, as referências auxiliares necessárias para interpretar códigos presentes nas fontes SIH/SUS e CNES, sem implementar ainda as dimensões.

Escopo:

- `PROC_REA` → SIGTAP;
- `DIAG_PRINC` → CID-10;
- domínio de `CAR_INT`;
- domínio de `COBRANCA`, incluindo o valor `24`;
- referências de `TP_LEITO` e `CODLEITO`;
- fonte histórica de nome fantasia / razão social de estabelecimento;
- temporalidade e estratégia futura de materialização.

## 2. Estado de entrada

O Boundary 3 havia validado integralmente 2017-01 a 2019-12:

- 36/36 arquivos SIH/RD;
- 36/36 arquivos CNES/LT;
- 36/36 arquivos CNES/ST;
- 108/108 DBCs esperados.

O Boundary 3 também havia identificado `COBRANCA=24` em seis competências e determinado que sua descrição oficial deveria ser fechada neste boundary.

Documento de entrada:

`docs/discovery/boundary-3-full-dataset-validation.md`

## 3. Procedimento — `PROC_REA`

### FATO VERIFICADO

A referência oficial adequada é a **Tabela de Procedimentos, Medicamentos e OPM do SUS — SIGTAP**.

A referência é organizada por competência e contempla a hierarquia:

`Grupo → Subgrupo → Forma de Organização → Procedimento`.

O código de procedimento utilizado no projeto possui 10 dígitos, compatível com os valores observados no SIH/RD.

### DECISÃO CONFIRMADA

O lookup futuro deve ser sensível à competência:

`competência RD + PROC_REA → referência SIGTAP da mesma competência`.

A estrutura aprovada de `DIM_PROCEDIMENTO` permanece:

- código;
- nome;
- descrição oficial;
- grupo;
- subgrupo;
- forma de organização.

### Fonte oficial

- https://wiki.saude.gov.br/sigtap/index.php/P%C3%A1gina_principal
- https://wiki.saude.gov.br/sigtap/index.php/Download

### Ajuste pendente de implementação

Materializar as competências históricas e medir cobertura real dos códigos `PROC_REA` observados.

## 4. Diagnóstico — `DIAG_PRINC`

### FATO VERIFICADO

`DIAG_PRINC` representa o diagnóstico principal e utiliza referência CID-10.

A estrutura acadêmica permanece:

- código CID-10;
- descrição oficial.

Diagnósticos secundários continuam fora do escopo inicial.

### DECISÃO CONFIRMADA DE IMPLEMENTAÇÃO — 07/10/2026

A validação física e empírica da Fase III demonstrou:

- 566.672 registros RD analisados;
- 5.480 códigos `DIAG_PRINC` distintos;
- 60.423 linhas com espaço ASCII à direita, sem colisões após remoção do padding;
- `tb_cid.txt` 201901 com 12.450 códigos;
- `tb_cid.txt` 201912 com 14.230 códigos;
- 201912 acrescenta 1.780 chaves e remove 0;
- 0 alterações de descrição/payload nas 12.450 chaves compartilhadas;
- 201912 cobre 566.672/566.672 registros RD;
- os 349 códigos normalizados não cobertos por 201901 estão todos presentes em 201912.

Para o Data Mart inicial, `DIM_DIAGNOSTICO` usará a referência oficial SIGTAP/CID-10 da competência **201912 como dicionário descritivo estático/superset**.

A normalização de chave aprovada é somente remover o padding ASCII `U+0020` à direita de `CO_CID`/`DIAG_PRINC`.

Essa decisão não representa vigência histórica mensal. Se a análise futura exigir validade do CID por competência, a modelagem deverá ser reavaliada.

### Fonte oficial relacionada

- https://wiki.saude.gov.br/sigtap/index.php/Gerais

## 5. Caráter de atendimento — `CAR_INT`

### FATO VERIFICADO

O domínio oficial aplicável contém seis códigos:

| Código | Descrição |
|---|---|
| 01 | Eletivo |
| 02 | Urgência |
| 03 | Acidente no local de trabalho ou a serviço da empresa |
| 04 | Acidente no trajeto para o trabalho |
| 05 | Outros tipos de acidente de trânsito |
| 06 | Outros tipos de lesões e envenenamentos por agentes químicos ou físicos |

Os dados integrais do Boundary 3 apresentaram `01`, `02`, `05` e `06`.

### DECISÃO CONFIRMADA

`DIM_CARATER_ATENDIMENTO` deve representar o domínio oficial completo, e não somente os valores observados.

### Fonte oficial

- Portaria SAS/MS nº 719/2007:
  https://bvsms.saude.gov.br/bvs/saudelegis/sas/2007/prt0719_28_12_2007.html

## 6. Motivo de saída/permanência — `COBRANCA`

### FATO VERIFICADO

A Portaria SAS/MS nº 719/2007 alterou a antiga denominação “Motivo de Cobrança” para “Motivo de Saída/Permanência”.

O código normativo `2.4` possui a descrição:

**Por Processo de doação de órgãos, tecidos e células — doador vivo.**

No arquivo RD, o domínio é armazenado sem o ponto. Portanto:

`COBRANCA=24 → código normativo 2.4`.

O valor `24` havia sido observado no Boundary 3 em:

- 2017-09;
- 2018-08;
- 2018-11;
- 2019-03;
- 2019-04;
- 2019-07.

### DECISÃO CONFIRMADA

`COBRANCA=24` está semanticamente resolvido e não exige alteração de `DIM_MOTIVO_SAIDA_PERMANENCIA`.

No staging futuro devem ser preservados:

- código fonte, por exemplo `24`;
- equivalência normativa, por exemplo `2.4`;
- descrição oficial.

### Fontes oficiais

- Portaria SAS/MS nº 719/2007:
  https://bvsms.saude.gov.br/bvs/saudelegis/sas/2007/prt0719_28_12_2007.html
- Portaria SAS nº 384/2010:
  https://bvsms.saude.gov.br/bvs/sas/Links%20finalizados%20SAS%202010/prt0384_12_08_2010.html

### Adendo de implementação — 07/10/2026

**FATO VERIFICADO:** o primeiro teste empírico de cobertura na Fase III mostrou que materializar somente os 21 códigos originalmente transcritos da Portaria 719/2007 era insuficiente: 124.233 das 566.672 linhas RD ficaram sem referência.

Os dados reais de 2017–2019 possuem 26 códigos `COBRANCA` distintos. A leitura da Portaria SAS/MS nº 384/2010 confirmou que, para o período do projeto:

- `1.3` e `1.7` foram excluídos;
- `1.9` permanece com denominação atualizada;
- internação domiciliar foi recodificada para `3.2`;
- `6.1`–`6.7` foram incluídos.

**DECISÃO CONFIRMADA:** a referência de implementação deve materializar o domínio oficial completo pós-2010 com 28 códigos, preservando também `3.2` e `6.7` mesmo sem ocorrência no conjunto atual. Não limitar a dimensão aos 26 códigos observados.

## 7. CNES — `TP_LEITO` e `CODLEITO`

### FATO VERIFICADO

As referências oficiais do CNES distinguem:

- tipo de leito;
- código/detalhamento de leito;
- descrição/especialidade;
- quantidade existente;
- quantidade SUS.

A fonte é orientada por competência, compatível com a natureza mensal do CNES/LT.

### DECISÃO CONFIRMADA

A decisão já aprovada de desnormalizar Tipo de Leito → Leito dentro de `DIM_TIPO_LEITO` permanece válida.

### DECISÃO PENDENTE DE IMPLEMENTAÇÃO

Ainda deve ser materializada e comparada a série histórica de referência para provar se descrições/classificações de `TP_LEITO` ou `CODLEITO` mudaram entre 2017 e 2019.

### Fontes oficiais relacionadas

- https://wiki.saude.gov.br/cnes/index.php/Pain%C3%A9is_ElastiCNES
- https://wiki.saude.gov.br/sigtap/index.php/Menu_Tabelas

### Adendo aprovado em 08/10/2026 — legenda datada, sem vigência histórica presumida

**FATO VERIFICADO:** a transcrição controlada da Nota Técnica MS nº 32/2019, anexo *Tabela de Leitos Setembro/2019*, contém 65 pares `TP_LEITO + CODLEITO`. Sua comparação com os 36 arquivos CNES/LT PB encontrou **57/57 pares e 35.518/35.518 ocorrências** com correspondência, sem exceções. O ensaio RTS não comprovou versões anteriores a 10/2019.

**DECISÃO APROVADA PELO RESPONSÁVEL DO PROJETO:** permitir a **legenda descritiva datada em 201909**, sem afirmar que nomes, tipos ou status dessa fonte estavam normativamente válidos em cada competência entre 201701 e 201912. Preservar os códigos e quantidades dos arquivos LT sem reclassificação. A legenda é **auxiliar independente**, não uma tabela mensal de versões nem autorização de aplicar `201909` a outras competências por join. O grão da fato e `DIM_TIPO_LEITO` acadêmica permanecem inalterados.

**DECISÃO PENDENTE HISTÓRICA PRESERVADA:** demonstrar ou não a vigência mensal continua sem evidência. A versão inicial pode avançar nas análises quantitativas independentes de rótulos, mas `T29_HISTORICAL` **não é PASS**. O contrato do Boundary 7 continua competência-aware enquanto não houver prova de invariância, evitando retroprojeção de descrições.

**Implementação proposta, ainda sem reload local:** `tools/materialize_cnes_201909_legend.py` valida o PDF, o CSV transcrito e o perfil antes de materializar `BASE/REFERENCIAS/cnes_leitos_legenda_201909.csv`. O `EXTRACAO/ext_c4_cnes_leitos.qvs` gera `REF_TIPO_LEITO.qvd` somente como **snapshot descritivo de 201909**, calcula cobertura sem enriquecer os LT, e gera checkpoint parcial, sem conclusão da Fase III. Exige evidência de teste no QlikView 12.

## 8. Estabelecimento — nome histórico

### FATO VERIFICADO

O CNES diferencia atributos cadastrais como nome empresarial e nome fantasia e possui fontes orientadas por competência.

Foi localizada rota oficial documentada para bases históricas do CNES a partir de 06/2017.

### DECISÃO PENDENTE

Não ficou comprovada, neste boundary, uma fonte histórica completa para nome fantasia / razão social entre 2017-01 e 2017-05.

É proibido aplicar retroativamente o nome atual ou o primeiro nome posterior disponível a essas competências sem evidência.

### Fontes oficiais relacionadas

- https://wiki.saude.gov.br/cnes/index.php/Categoria%3ASCNES_Simplificado/_Instru%C3%A7%C3%B5es_para_preenchimento
- https://wiki.saude.gov.br/cnes/index.php/Categoria%3AConsumo_de_informa%C3%A7%C3%B5es_da_Base_Nacional_do_CNES_via_webservice_e_Download_da_Base_de_Dados
- https://wiki.saude.gov.br/cnes/index.php/Pain%C3%A9is_ElastiCNES

## 9. Matriz de referências

| Referência | Campo origem | Fonte oficial | Chave | Temporal? | Competência necessária? | Cobertura 2017–2019 | Status |
|---|---|---|---|---|---|---|---|
| Procedimento | `PROC_REA` | SIGTAP | código 10 dígitos | Sim | Sim | série mensal disponível | FECHADA COM TESTE EMPÍRICO PENDENTE |
| Diagnóstico | `DIAG_PRINC` | CID-10 | código CID-10 | versionada | não demonstrada mensal | referência oficial localizada | FECHADA COM AJUSTE |
| Caráter | `CAR_INT` | Portaria 719/2007 | 01–06 | não evidenciado no período | não | completa | FECHADA |
| Motivo saída | `COBRANCA` | Portarias 719/2007 e 384/2010 | forma armazenada sem ponto | histórico normativo | não mensal em 2017–2019 | suficiente para o domínio investigado | FECHADA |
| Tipo de leito | `TP_LEITO` | CNES | código tipo | potencialmente | sim, por segurança | fonte por competência | PARCIAL |
| Leito | `CODLEITO` | CNES | código leito | potencialmente | sim, por segurança | fonte por competência | PARCIAL |
| Estabelecimento | `CNES` | CNES por competência | CNES + competência | Sim | Sim | nome histórico comprovado a partir de 06/2017 | PARCIAL |

## 10. Cobertura contra os dados reais

Nesta execução não foram rematerializados os ZIPs integrais para executar novamente todos os lookups.

Evidências preservadas do Boundary 3:

- `PROC_REA`: formato de 10 dígitos validado;
- `DIAG_PRINC`: 0 vazios;
- `CAR_INT`: domínio observado `01,02,05,06`, todos pertencentes ao domínio oficial;
- `COBRANCA=24`: oficialmente resolvido;
- nenhum novo domínio de `TP_LEITO` ou `CODLEITO` fora dos checkpoints havia surgido na carga integral.

Coberturas `PROC_REA × SIGTAP`, `DIAG_PRINC × CID-10` e `CODLEITO × referência oficial` permanecem como testes de implementação e não devem ser inventadas.

## 11. Estratégia futura de materialização

Preferir artefatos reproduzíveis:

- scripts de aquisição;
- URLs oficiais;
- competência/vigência;
- metadados;
- checksums;
- regras de transformação.

Não versionar bases auxiliares grandes quando puderem ser reproduzidas.

Estratégia por referência:

1. SIGTAP por competência;
2. CID-10 oficial com normalização de chave validada contra os dados;
3. `CAR_INT` e `COBRANCA` como pequenos domínios normativos;
4. CNES leitos por competência;
5. estabelecimento por competência, sem backfill de nomes não comprovados.

## 12. Impacto na arquitetura

Nenhuma evidência exigiu alterar:

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`;
- as oito dimensões;
- `PROC_REA`;
- `DIAG_PRINC`;
- Star Schema por processo factual;
- constelação dimensional;
- desnormalização de `DIM_TIPO_LEITO`.

Não houve Decision Gate estrutural.

## 13. Ajustes que seguem adiante

- medir cobertura real `PROC_REA × SIGTAP`;
- medir cobertura real `DIAG_PRINC × CID-10`;
- materializar/comparar a referência histórica de `TP_LEITO/CODLEITO`;
- manter explícita a lacuna de nome histórico para 2017-01 a 2017-05;
- definir a técnica física de historização e role-playing no Boundary 5.

## 14. Veredito

### `APROVADO PARA PROSSEGUIR COM AJUSTES`

As referências principais estão suficientemente fechadas para avançar. Permanecem lacunas de materialização e cobertura que devem ser tratadas durante a implementação sem modificar silenciosamente a modelagem acadêmica.
