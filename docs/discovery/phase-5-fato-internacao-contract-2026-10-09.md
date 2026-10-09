# Fase V — Contrato de medidas e associações da FATO_INTERNACAO — Discovery

**Data:** 09/10/2026  
**Modo:** `DISCOVERY / READ-ONLY CONTRACT / NO FACT IMPLEMENTATION`  
**Branch:** `feat/phase-5-fato-internacao-contract-discovery`  
**Repositório:** `pedrogles/sad-sus-pb-data-mart`  
**Situação:** `CONTRACT_DRAFT_PENDING_PHYSICAL_MEASURE_AND_ASSOCIATION_GATES`

Este documento não modifica o modelo acadêmico nem reabre os Capítulos 1 e 2. Nenhum QVD de fato, Link Table, PAINEL ou sucesso global de transformação foi gerado por esta Discovery.

## 1. Hierarquia e decisões preservadas

- Requisitos e modelagem: `docs/academic/requirements.md`, `docs/academic/chapter-1-2-modeling.md`, especialmente RN03–RN06, RN14, RN17–RN20, capítulos de `FATO_INTERNACAO`.
- Decisão física: `docs/discovery/boundary-5-historization-role-playing.md`, `docs/discovery/boundary-6-qlikview-physical-architecture.md`, `docs/discovery/boundary-7-implementation-plan.md`.
- Fonte: `EXTRACAO/ext_main.qvs` grava `EXTRACAO/QVD/SRC_SIH_RD.qvd` a partir de 36 CSVs RD; 17 campos do registro e quatro campos de proveniência.
- Fase IV: oito dimensões em `TRANSFORMACAO/QVD`. Scripts dimensionais existentes definem as expressões de SK e não devem ser alterados para viabilizar a fato.
- SK da fato já validada no teste local de 2 recargas e aprovada **com restrições**: `docs/discovery/phase-5-fato-internacao-sk-preflight-2026-10-09.md`. PR #82 integrado em `ceacef87a6a5a77299a87743133ec9b86aca9b24`.

## 2. FATO VERIFICADO — grão, volume e identidade

- **Grão:** exatamente uma linha para cada registro administrativo SIH/RD (AIH processada), mesmo quando `IDENT=5` identifica continuidade; não tratar linha como pessoa única ou episódio único.
- **Volume de controle:** 566.672 registros distribuídos em 36 competências (201701–201912): 2017=187.726, 2018=187.293, 2019=191.653.
- **Unicidade SK técnica:** `Hash128('RD', Text(_META_SOURCE_FILE), Text(ANO_CMPT), ..., Text(MORTE))` em ordem integral registrada no preflight versionado; 566.672 distintos/0 nulos em QlikView 12, e **duas recargas com conjuntos exatos idênticos** (`ONLY_A_KEYS=0`, `ONLY_B_KEYS=0`). A identidade técnica é conteúdo+arquivo, **não** identidade permanente perante correção da AIH; exigência de fonte 2017–2019 congelada.
- `N_AIH` não é PK: foram 880 linhas excedentes em grupos de `N_AIH` repetidos dentro das competências.
- `IDENT=5`: 11.583 registros. `IDENT=1`: 555.089 registros. Residência fora da PB: 5.202 registros, preservados sem atribuir população da PB.

## 3. Matriz de medidas (contrato acadêmico aprovado; reconciliação física pendente)

| Campo de saída acadêmico | Fonte RD no staging | Regra aplicável | Teste exigido |
|---|---|---|---|
| `QTD_REGISTRO_AIH` | uma linha física RD | 1 por registro | soma **566.672** |
| `QTD_INTERNACAO` | `IDENT` | 0 quando `IDENT='5'`; 1 para `IDENT='1'` observado | soma **555.089**; `IDENT5` conta somente como registro |
| `DIAS_PERMANENCIA` | `DIAS_PERM` | preservar a medida numérica por linha, sem negativar nem multiplicar em joins | total geral e anual devem coincidir com o **preflight fonte independente** |
| `VALOR_TOTAL` | `VAL_TOT` | preservar valor numérico por linha, sem juntar ou somar campos homônimos de outras fatos | total geral e anual conforme fonte; interpretar decimal/escala no QlikView antes de comparar |
| `INDICADOR_OBITO` | `MORTE` | preservar indicador 0/1 do registro | contagem de linhas `MORTE=1` por ano/total igual ao preflight; **não assumir número de pacientes distintos** |

**DECISÃO PENDENTE:** executar o novo preflight independente para produzir os totais reais e confirmar a leitura numérica `DIAS_PERM`/`VAL_TOT` por QlikView 12. Nenhum total desses três campos foi inventado aqui. Contagens 566.672/555.089 e domínio `MORTE={0,1}` já foram validados no ciclo anterior, mas o gate integral das medidas continua aberto. `VAL_TOT` e `DIAS_PERM` já são carregados como valores numéricos no staging, porém o pipeline pode ter representação distinta da string Decimal da fonte: detectar e reconciliar explicitamente.

**Ferramenta adicionada ao repositório:** `tools/preflight_fato_internacao_medidas.py` — percorre 36 CSVs, compara competências/ano/IDENT/linhas/repetição de N_AIH/residência externa, calcula dias e valores com `decimal.Decimal`, soma flags de morte, apresenta totais anuais e gerais; **não escreve arquivo**. Ainda **NÃO EXECUTADA** no conjunto real nesta branch. Não contém novos campos nem muda as regras acadêmicas.

## 4. Associações previstas — chaves e semânticas

### 4.1 Conformadas que pertencem à LINK_ANALISE (não duplicar no modelo associativo factual final)

| Papel lógico | Fonte da fato | Referência física já versionada | Estado |
|---|---|---|---|
| Tempo competência | `_META_SOURCE_COMPETENCE`/`ANO_CMPT+MES_CMPT` | `DIM_TEMPO`: `Hash128('MES', AAAAMM)` | fórmula de dimensão verificada; associação da fato **a testar** |
| Tempo ano analítico | ano da competência SIH/RD | `DIM_TEMPO`: `Hash128('ANO', Year(...))` | cuidar da representação numérica/dual de Year no Qlik |
| Município residência | `MUNIC_RES` | `DIM_MUNICIPIO`: `Hash128('MUN', COD_DATASUS_6)` | deve abranger inclusive 714 códigos externos, sem IBGE7 imputado |
| Município serviço/atendimento | `MUNIC_MOV` | `DIM_MUNICIPIO`: `Hash128('MUN', COD_DATASUS_6)` | atende à correspondência PB da validação integral |
| Estabelecimento em competência | `CNES` + competência mensal SIH | `DIM_ESTABELECIMENTO`: `Hash128('ESTAB', CNES, COMPETENCIA)` | **não** usar versão de ST posterior |

Essas coordenadas fazem parte da **Link Table aprovada no Boundary 6**; na fato final, compartilhar somente `%LINK_KEY` com `LINK_ANALISE`, sem carregar chaves conformadas homônimas como associações paralelas. Os valores técnicos utilizados para gerar a Link Table podem existir em tabelas de trabalho e controles, mas não podem criar caminhos físicos extras no modelo publicado.

### 4.2 Exclusivas diretamente ligadas à FATO_INTERNACAO

| Papel | Origem RD | Chave prevista, conforme script dimensional |
|---|---|---|
| Data internação | `DT_INTER` | `%SK_TEMPO_INTERNACAO` derivada de `Hash128('DATA', AAAAMMDD)`, validada contra `DIM_TEMPO.qvd` |
| Data saída | `DT_SAIDA` | `%SK_TEMPO_SAIDA` derivada de `Hash128('DATA', AAAAMMDD)` |
| Procedimento realizado | `PROC_REA` + competência | `%SK_PROCEDIMENTO = Hash128('PROC', PROC_REA, COMPETENCIA)`; a mesma competência do SIGTAP |
| Diagnóstico principal | `DIAG_PRINC` | `%SK_DIAGNOSTICO = Hash128('CID10', codigo_normalizado)`; alinhar exatamente normalização da fase IV (`Text(RTrim(Text(DIAG_PRINC)))`) |
| Caráter do atendimento | `CAR_INT` | `%SK_CARATER_ATENDIMENTO = Hash128('CAR', codigo_2_caracteres)`; preservar zeros |
| Motivo de saída | `COBRANCA` | **nome físico já aprovado**: `%SK_MOTIVO_SAIDA = Hash128('MOT', codigo_2_caracteres)`, conforme `transf_dim_motivo_saida_permanencia.qvs`. Não inventar segunda chave física divergente |

**Status da cobertura:** nos Boundaries 3/4 e nos gates das dimensões, foram registrados `0` unmatched para o estabelecimento mensal, município, procedimento realizado, diagnóstico e domínios relevantes. **Não assumir automaticamente** `0` no QVD factual novo: testes devem verificar chaves e mapeamentos após conversões exatas, com 566.672 linhas preservadas.

## 5. Gate de implementação ainda aberto — %LINK_KEY

**FATO VERIFICADO:** Boundary 6 escolheu `LINK_ANALISE`, não fato concatenada. Boundary 7 fixou coordenadas compartilhadas de internação: competência, ano, município de residência, município serviço e versão de estabelecimento.

**DECISÃO PENDENTE:** a serialização física final (ordem, tipagem/texto, nulos explícitos, separadores e prevenção de colisão semântica) de `%LINK_KEY` **ainda é um contrato a validar em conjunto com as outras duas fatos**. Não gerar uma chave isolada que depois mude de sentido para `FATO_CAPACIDADE_LEITO` e `FATO_POPULACAO`. A Link Table será construída na Fase VI; a fato deve seguir o contrato que venha a ser aprovado para todos os processos.

Assim, a sequência segura é: (1) medir e reconciliar a fonte RD; (2) testar fisicamente as chaves dimensionais e cardinalidades em documento Qlik isolado; (3) fechar a serialização canônica da Link Table com as três fatos; (4) somente então implementar/gravar `FATO_INTERNACAO.qvd` em `TRANSF.qvw` sob gate expresso. Não criar sucesso global parcial.

## 6. Gates objetivos antes da implementação factual

- [ ] Executar `tools/preflight_fato_internacao_medidas.py` no Windows e registrar os totais anuais e gerais de `DIAS_PERM`, `VAL_TOT` e mortes, com SHA dos arquivos de origem/manifesto quando pertinente.
- [ ] Validar no QlikView 12 (documento isolado) as cinco medidas contra a fonte, com atenção a zeros, casas decimais e eventuais diferenças de arredondamento.
- [ ] Testar **566.672 linhas** preservadas, 36 competências, **566.672 SK técnicas únicas**, `IDENT5=11583`, `QTD_INTERNACAO=555089`, `QTD_REGISTRO_AIH=566672`, **0 órfãos** em cada dimensão obrigatória, 5.202 residências externas preservadas.
- [ ] Garantir `Hash128('ANO', numeric_year)` idêntico às versões de `DIM_TEMPO`; data (competência, internação e saída) e procedimentos devem usar tipos/normalização da mesma dimensão.
- [ ] Projetar `%LINK_KEY` de modo compatível com as três fatos e sem `$Syn` ou loops; testes T17/T18 dependem do contrato compartilhado e da Fase VI.
- [ ] Não salvar QVD factual, marcador global de transformação, Link Table ou objetos de painel antes de resolver os gates aplicáveis.
- [ ] `T29_HISTORICAL=NOT_APPROVED` preservado; a ausência de nomes CNES históricos não elimina leitos nem dispensa ressalva visível futura (1.965/2.021 **pares-mês** sem rótulo histórico comprovado, não percentual de leitos).

**Veredito desta Discovery:** `FATO_INTERNACAO_CONTRACT=DOCUMENTED_PENDING_PHYSICAL_MEASURES_AND_LINK_KEY_GATES`, `FACT_QVD=NOT_STARTED`.
