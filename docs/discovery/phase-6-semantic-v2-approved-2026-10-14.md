# Fase VI — Contrato semântico V2 dos indicadores (aprovado em 14/10/2026)

> **Transcrição auditável de decisão semântica, não aceite físico.** Conteúdo da §62 do [documento de Discovery no PR #83](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/26369052bd3f96de5f3eccf873c390053c20b561/docs/discovery/phase-6-link-key-cross-fact-discovery-2026-10-10.md), extraído integralmente do commit `26369052bd3f96de5f3eccf873c390053c20b561`, sem reinterpretação de D1–D8, P1–P5, indicadores, matriz de filtros ou limitações. As referências à branch e a não autorização de merge no texto abaixo descrevem o estado em 14/10/2026; a integração **deste novo documento** depende de revisão e aprovação próprias.

## 62. Decisao aprovada pelo responsavel — contrato semantico V2 (14/10/2026)

**FATO DE DECISAO:** em 14/10/2026 o responsavel autorizou expressamente a **aprovacao exclusivamente semantica da minuta V2**, apos revisao critica de compatibilidade com o roteiro oficial do professor, as RN01–RN21, os Boundaries 6/7 e a Discovery VI. Esta secao registra a decisao sem mudar a natureza dos testes ja executados nem sobrescrever os checkpoints cronologicos anteriores.

**ESCOPO DO ACEITE:** significados analiticos, referencias temporais, medidas e denominadores candidatos, papeis municipais, tratamento de indisponibilidade, criterios de cobertura, agregacao e politica semantica de filtros. **Nao e aceite de expressao QlikView, compatibilidade numerica final, modelo associativo materializado ou implementacao.**

### 62.1 Escolhas semanticamente aprovadas

| Escolha | Alternativa | Escopo aprovado |
|---|---|---|
| D1 | B | Anual e competencias parciais distinguidos; nenhuma anualizacao automatica |
| D2 | B | Prevenir conflito ano/competencia antes de descartar a intencao de selecao |
| D3 | B | Denominador POP por residencia para demanda de residentes; por servico para oferta |
| D4 | B | Distinguir zero comprovado, ausencia, nulo, cobertura nao comprovada e indisponibilidade |
| D5 | B | Somar capacidade no municipio por competencia e calcular media de snapshots; 12 competencias validas para ano completo |
| D6 | B | Agregar componentes territoriais compativeis antes de calcular razoes; POP municipal contada uma unica vez por municipio/ano |
| D7 | B | Filtros exclusivos ou cruzados nao redefinem silenciosamente indicadores gerais |
| D8 | B | Gates semantico, de medidas, link key e associativo fisico separados |
| P1 | A | Competencia administrativa SIH/RD como referencia principal; DT_INTER e DT_SAIDA sao papeis exclusivos distintos |
| P2 | B | Indicadores anuais principais; razoes parciais identificadas pelo periodo e pela POP anual |
| P3 | B | QTD_LEITOS_SUS media como denominador principal de internacoes/leito |
| P4 | B | Integridade global da competencia e cobertura interpretavel no recorte analisado |
| P5 | B | Contrato de filtros por indicador, sem efeito silencioso sobre significado ou denominador |

**Nao altera:** 3 fatos, seus graos, 8 dimensoes, a arquitetura Star/constelacao com Link Table fisica, as chaves de papeis/conformadas ja aprovadas, capitulos academicos fechados, RN21 e regra historica T29.

### 62.2 Indicadores principais e delimitacao da fonte

| Indicador | Numerador | Denominador | Eixo territorial | Unidade/interpretacao |
|---|---|---|---|---|
| Internacoes de residentes por 1.000 habitantes | SUM(QTD_INTERNACAO) de residentes no universo SIH/RD de atendimentos processados na PB | POPULACAO_ESTIMADA do municipio de residencia no ano | Residencia | Internacoes processadas por 1.000 habitantes de referencia |
| Leitos SUS por 1.000 habitantes | Media dos totais por competencia de QTD_LEITOS_SUS | POPULACAO_ESTIMADA no ano | Servico/localizacao | Leitos SUS medios por 1.000 habitantes de referencia |
| Internacoes por leito SUS medio | SUM(QTD_INTERNACAO) de atendimentos realizados no periodo | Media dos totais mensais de QTD_LEITOS_SUS no mesmo municipio e periodo | Servico | Internacoes processadas no periodo / leito SUS medio do periodo; **nao taxa de ocupacao** |
| Fluxo residencia para servico | SUM(QTD_INTERNACAO) por par residencia/servico | Nenhum denominador POP implicito | Ambos os papeis | Contagem/distribuicao de fluxo |

**RN02/RN03:** internacoes de residentes neste Data Mart nao sao todas as internacoes ocorridas em qualquer UF, mas as identificadas no SIH/RD de atendimentos realizados na PB. Um registro RD e uma observacao administrativa, nao prova de paciente ou episodio clinico unico. **RN04:** IDENT=5 corresponde a continuidade, logo QTD_INTERNACAO=0; nao substituir por QTD_REGISTRO_AIH. Residentes externos podem integrar fluxo e totais elegiveis sem receber POP municipal PB.

### 62.3 Contrato temporal explicito — ajustes AC-02 e AC-05

| Contexto | Resultado semantico |
|---|---|
| Ano analitico unico com cobertura valida | Indicador anual |
| Competencias selecionadas dentro de um ano | Razao parcial, identificando competencias e populacao anual de referencia |
| Meses nao consecutivos | Identificar quais competencias foram usadas, sem apresentar intervalo continuo |
| Dois ou mais anos como serie separada por ano | Calculos independentes por ano, sem somar POP de anos diferentes |
| Varios anos num unico KPI dito anual | Indisponivel por ausencia de ano unico |
| Sem periodo, num KPI pontual | Indisponivel ate haver referencia temporal inequivoca |
| Sem selecao temporal, grafico dimensionado por ano | Serie anual separada por ano permitida, sujeita a validacao de medidas e cobertura |

O eixo principal e a **competencia administrativa SIH/RD** (P1=A). As datas clinicas de entrada e saida nao sao sinonimos e exigem rotulos proprios para analises especificas. Periodos parciais **nao sao taxa anual, incidencia clinica comprovada nem extrapolacao anual**. O mesmo valor de internacoes/leito em janelas temporais distintas nao demonstra intensidade equivalente.

**D2 exige prevencao antes da alteracao de selecoes.** E14/E15 demonstraram risco de intencao descartada; nenhuma solucao de interface foi aqui aprovada ou implementada.

### 62.4 Integridade e cobertura CNES — ajuste AC-03

A disponibilidade do arquivo mensal, a integridade global CNES/LT e a **cobertura do indicador por municipio/competencia/escopo** sao conceitos distintos. Os 36/36 arquivos LT e seus controles tecnicos globais **nao comprovam** cobertura integral em todo recorte.

Classificar separadamente: (a) medida observada/reconciliada; (b) zero quantitativo comprovado; (c) ausencia de linhas sem evidencia de zero; (d) inconsistencia tecnica; (e) exclusao associativa por filtro incompatível. Nem (c), nem (d), nem (e) podem virar zero por padrao.

Para media anual completa exigir 12 competencias validas do universo apresentado. Para periodo parcial exigir cada competencia selecionada valida. **Nao exigir permanencia dos mesmos estabelecimentos nas 12 competencias**: alteracoes legitimas no tempo nao invalidam isoladamente o mes. Para regiao, agregar totais por municipio dentro de cada competencia antes de media e razao; ausencia de municipio/mes requerido impede rotular resultado como regional completo.

**LIMITE PROBATÓRIO:** o criterio observavel que sustenta zero real ou cobertura suficiente para um municipio/competencia sem linhas LT ainda depende de validacao nos dados. Ate la, marcar indisponibilidade, sem inventar completude.

### 62.5 Universo e classificacao de estabelecimentos — ajuste AC-04

A RN21 preserva **todos os registros CNES/LT validos na fato**. Recorte estritamente hospitalar e analise derivada por classificacao do estabelecimento aplicavel historicamente; nao e exclusao fisica antecipada.

Cada indicador deve declarar explicitamente: fonte/medida, municipio/papel, competencia/ano, universo de estabelecimentos, regra de recorte hospitalar quando aplicavel, compatibilidade historica do atributo e interpretacao da comparacao SIH/RD × CNES/LT. Nao presumir classificacao historica nem equivalencia de universos nao validada. Para internacoes/leito o alinhamento de periodo e territorio e necessario, mas nao prova uso clinico efetivo do leito SUS.

### 62.6 Matriz de filtros P5 — ajuste AC-01

**RES:** internacoes de residentes/1.000 habitantes. **LEI:** leitos SUS/1.000 habitantes. **REL:** internacoes por leito SUS medio. **FLU:** fluxo residencia para servico.

| Filtro | RES | LEI | REL | FLU |
|---|:---:|:---:|:---:|:---:|
| Ano analitico | C | C | C | C |
| Competencia mensal | C | C | C | C |
| Municipio de residencia | C | B | B | C |
| Municipio de servico | B | C | C | C |
| Estabelecimento CNES | R | R | R | R |
| Procedimento realizado PROC_REA | R | I | B | R |
| Diagnostico principal DIAG_PRINC | R | I | B | R |
| Carater do atendimento | R | I | B | R |
| Motivo de saida/permanencia | R | I | B | R |
| Tipo/codigo de leito | I | R | B | I |
| Data clinica de internacao | R | I | B | R |
| Data clinica de saida | R | I | B | R |

**C (compativel):** sujeito a tempo, territorio, escopo, medidas e cobertura validos. **R (recorte especifico):** requer indicador/analise separada com contrato proprio aprovado; na ausencia deste, nao apresentar como indicador geral. **I (filtro nao aplicavel):** somente isolar explicitamente e com aviso/validacao fisica; caso contrario, indisponivel. **B (bloqueio):** indicador geral indisponivel no contexto.

Filtros simultaneos nao transformam uma incompatibilidade em permissao. Nao ignorar filtros silenciosamente, nao propagar medidas de fatos exclusivas como se fossem compartilhas, nem aprovar automaticamente novas taxas por procedimento, diagnostico, estabelecimento ou tipo de leito. Fluxo RES→SERV nao possui POP implicita.

### 62.7 Zero e indisponibilidade — ajuste AC-06

Numerador comprovadamente zero com cobertura valida e denominador **positivo** pode produzir indicador zero. Para razoes, denominador ausente, nulo, zero, negativo ou nao validado torna o calculo indisponivel. Para capacidade quantitativa, zero legitimo exige comprovacao no escopo; ausencia de registro sem demonstracao nao equivale a zero.

A interface futura devera diferenciar motivo de indisponibilidade: periodo/ano ambiguo, filtro incompatível, POP ausente ou externa, capacidade sem cobertura, medida invalida ou zero no denominador. Esses sao significados para interface, nao um novo schema ou autorizacao de implementar o PAINEL.

### 62.8 Ressalva historica CNES preservada

**T29_HISTORICAL=NOT_APPROVED.** A referencia descritiva de setembro/2019 nao tem vigencia historica demonstrada em 2017–2019. As 1.965/2.021 combinacoes codigo de tipo × codigo de leito × competencia (97,2%) sem nome historico comprovado **nao representam percentual de leitos**. Preservar os avisos visiveis e regras de filtros do Boundary 7, sem preencher NULL como zero nem generalizar nome set/2019.

### 62.9 Condicoes e limites da aprovacao

**APROVADO SOMENTE NO NIVEL SEMANTICO:** definicoes, papeis, politica temporal, filtros e criterios de indisponibilidade acima. **NAO APROVADO FISICAMENTE:** expressoes oficiais QlikView 12, reconciliação real das razoes, Set Analysis sob todos os filtros, mecanismo de prevencao ano/competencia, cobertura por municipio/mes, contrato definitivo SAD-LINK-V1/%LINK_KEY, materializacao da LINK_ANALISE, fatos/QVDs e PAINEL.

Gates independentes seguintes devem preservar os testes T24–T26 de reconciliacao de indicadores, controle de grão/medidas, nulos nao aplicaveis, associacoes role-playing, ausencia de $Syn/loops indevidos e correspondencia exata das chaves. A aprovacao semantica **nao autoriza** testes mutantes, geracao de dados, implementacao, modificacao dos Boundaries 6/7, abertura de novas estruturas, merge ou publicacao.

**MANTER OS STATUS FISICOS ATUAIS:** MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; LINK_KEY_CONTRACT=NOT_APPROVED; FACT_QVDS=NOT_STARTED; LINK_ANALISE_QVD=NOT_STARTED; PAINEL=NOT_STARTED; T29_HISTORICAL=NOT_APPROVED. Os registros de §61 e checkpoints anteriores sao historicos de testes e nao devem ser reclassificados retroativamente.

**PROVENIENCIA DO ACEITE:** aprovacao expressa do responsavel, comunicada no projeto em 14/10/2026 apos minuta V2, auditoria AC-01 a AC-06 e confirmacao de que nao ha conflito semantico impeditivo. Registro documental nesta branch de Discovery; **nenhum merge autorizado**.

---
