# Revisão Final da Primeira Entrega — Capítulos 1 e 2

## Status

**FECHADA — PRONTA PARA IMPRESSÃO/ENTREGA**

Data da revisão final: **02/10/2026**

A revisão foi executada contra:

- roteiro oficial do professor;
- material de DER/cardinalidades;
- material de Modelagem Dimensional;
- material Star x Snowflake;
- documentação canônica do projeto;
- relatório final em DOCX/PDF;
- diagramas conceitual, lógico e dimensional.

Artefato final revisado externamente ao Git:

`Relatorio_Primeira_Entrega_SAD_SUS_PB_final.pdf`

O PDF possui 20 páginas físicas, incluindo capa e sumário, e 18 páginas numeradas de conteúdo.

---

## 1. Checklist obrigatório da primeira entrega

| Requisito do roteiro | Status | Verificação |
|---|---|---|
| Capa | **OK** | título no formato solicitado |
| Nome do integrante | **OK** | Pedro Gabriel Lima e Silva |
| Sumário | **OK** | capítulos e subseções presentes, com paginação revisada |
| Cap. 1 — Regras de Negócio | **OK** | 21 regras consolidadas e justificadas |
| Entidades | **OK** | 13 entidades conceituais documentadas |
| Relacionamentos | **OK** | relacionamentos descritos e tabelados |
| Cardinalidade mínima | **OK** | 0/1 explicitados conforme cada relacionamento |
| Cardinalidade máxima | **OK** | 1/n explicitados conforme cada relacionamento |
| Modelo conceitual / DER | **OK** | Figura 1, diagramada digitalmente |
| DER com cardinalidades mínima e máxima | **OK** | cardinalidades explícitas nas ligações |
| Modelo lógico relacional normalizado | **OK** | Figura 2 |
| PKs e FKs no modelo lógico | **OK** | explicitadas no diagrama e na síntese textual |
| Cardinalidades no modelo lógico | **OK** | mínima e máxima explicitadas |
| Cap. 2 — estrutura escolhida | **OK** | Star Schema |
| Justificativa Star x Snowflake | **OK** | baseada em desnormalização, simplicidade e joins |
| Modelo dimensional | **OK** | três estrelas + constelação |
| Mínimo de 6 dimensões | **OK** | 8 dimensões |
| Mínimo de 1 tabela fato | **OK** | 3 fatos |
| Primeira entrega até Capítulo 2 | **OK** | documento encerra em 2.10 |
| Formato impresso | **OK PARA IMPRESSÃO** | PDF A4, com duas páginas paisagem para diagramas |

**Resultado do checklist obrigatório: 100% dos itens exigidos para a primeira entrega estão representados.**

---

## 2. Consistência da modelagem

### Modelo conceitual

**OK**

O DER contém as entidades e relacionamentos necessários para representar:

- internações;
- estabelecimento e seu estado histórico por competência;
- município;
- procedimento;
- diagnóstico;
- caráter do atendimento;
- motivo de saída/permanência;
- leitos;
- capacidade;
- população.

Não foram identificados relacionamentos sem justificativa nas regras de negócio.

### Cardinalidades

**OK**

A notação utilizada respeita as combinações ensinadas na disciplina:

- `(0,1)`;
- `(1,1)`;
- `(0,n)`;
- `(1,n)`.

O modelo atual utiliza apenas as combinações necessárias ao domínio.

### Modelo lógico relacional

**OK**

O modelo:

- preserva separação entre identidade do estabelecimento e estado por competência;
- mantém população separada de município;
- mantém capacidade na granularidade estabelecimento × competência × leito;
- evita usar `N_AIH` como chave única;
- explicita PKs e FKs;
- evita duplicar município de atendimento quando derivável do estado do estabelecimento.

### Modelo dimensional

**OK**

A opção aprovada é Star Schema em cada processo factual.

O conjunto completo é uma constelação de estrelas porque possui:

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`;

compartilhando dimensões conformadas.

A presença de três fatos não transforma o modelo em Snowflake.

---

## 3. Justificativas metodológicas

**OK**

O relatório explica:

- por que 2017–2019 foi escolhido;
- por que janeiro de cada ano foi usado como checkpoint estrutural;
- por que os checkpoints não representam amostra estatística dos anos completos;
- o significado operacional de demanda hospitalar;
- o significado cadastral de capacidade hospitalar;
- por que existem três tabelas fato;
- por que população é uma fato;
- por que leitos e população são semi-aditivos;
- por que indicadores anuais de capacidade usam média de snapshots;
- por que `PROC_REA` foi priorizado;
- por que diagnóstico principal foi priorizado;
- por que diagnósticos secundários ficaram fora do escopo inicial;
- por que os registros válidos do CNES/LT são preservados;
- por que internações/leito não deve ser chamada de taxa de ocupação.

---

## 4. Revisão do artefato final

### Capa

**OK**

- instituição;
- curso;
- disciplina;
- professor;
- título;
- subtítulo;
- integrante: **Pedro Gabriel Lima e Silva**;
- local: **João Pessoa - PB**;
- ano: **2026**.

Não existem placeholders `[PREENCHER ...]` no artefato final.

### Sumário

**OK**

A paginação foi conferida contra o conteúdo renderizado.

### Figuras

**OK**

Foram inseridas:

1. Figura 1 — Modelo Conceitual (DER);
2. Figura 2 — Modelo Lógico Relacional Normalizado;
3. Figura 3 — Estrela de Internação;
4. Figura 4 — Estrela de Capacidade de Leitos;
5. Figura 5 — Estrela de População;
6. Figura 6 — Constelação Dimensional.

Todas possuem identificação e fonte.

### Tabelas

**OK**

Foram verificadas as tabelas de:

- entidades;
- relacionamentos/cardinalidades;
- síntese do modelo lógico;
- fatos/granularidades;
- matriz fato × dimensão.

### Preflight e legibilidade

**OK**

- PDF abre normalmente;
- 20 páginas;
- sem criptografia;
- sem conteúdo escaneado como única representação;
- páginas de DER e modelo lógico em orientação paisagem;
- demais páginas em orientação retrato;
- sem clipping ou sobreposição visual identificada;
- fontes incorporadas no PDF;
- DOCX sem comentários e sem placeholders pendentes.

---

## 5. Itens do projeto que não pertencem à primeira entrega

O roteiro oficial posiciona os itens abaixo depois do Capítulo 2. Portanto, sua ausência no relatório desta etapa **não constitui falta da primeira entrega**:

- Capítulo 3 — Implementação;
- prints e comentários das visões no QlikView;
- Capítulo 4 — Considerações Finais;
- Capítulo 5 — Referências Bibliográficas;
- Anexo I — Scripts das Dimensões;
- Anexo II — Script(s) da(s) Fato(s);
- mínimo de 3 painéis OLAP.

### Referências bibliográficas

A primeira entrega termina no Capítulo 2, enquanto o roteiro posiciona as referências no Capítulo 5.

Portanto, a ausência de um Capítulo 5 no artefato atual é coerente com o corte solicitado. Entretanto, as referências oficiais já utilizadas devem ser consolidadas obrigatoriamente na versão final do trabalho.

---

## 6. Ponto acadêmico a acompanhar

### Origem baseada em arquivos

O roteiro estabelece:

- mínimo de 10 tabelas populadas quando a origem for um banco de dados;
- **análise caso a caso quando a origem for composta por arquivos**.

Este projeto utiliza arquivos públicos SIH/CNES/IBGE, e não um banco relacional de origem com 10 tabelas.

Classificação:

**NÃO BLOQUEIA A PRIMEIRA ENTREGA, MAS DEPENDE DA AVALIAÇÃO ACADÊMICA PREVISTA NO PRÓPRIO ROTEIRO.**

Durante a próxima fase, a origem e a organização dos arquivos deverão continuar claramente documentadas para facilitar essa avaliação.

---

## 7. Itens deliberadamente adiados para implementação

Não bloqueiam os Capítulos 1 e 2:

- aquisição e validação dos 36 meses completos;
- materialização das tabelas de referência por competência;
- fonte histórica definitiva para nome fantasia/razão social;
- técnica física de historização de `DIM_ESTABELECIMENTO`;
- representação física das dimensões role-playing no QlikView;
- scripts de extração e transformação;
- QVDs;
- QVWs;
- painéis;
- reconciliação integral dos indicadores.

Essas pendências devem ser resolvidas na próxima fase sem modificar silenciosamente a modelagem aprovada.

---

## 8. Veredito final

### FATO VERIFICADO

O relatório final contém todos os componentes explicitamente exigidos pelo professor para a **primeira entrega até o Capítulo 2**.

### FATO VERIFICADO

DER, modelo lógico e modelo dimensional estão coerentes com a documentação canônica atual e com as regras de negócio aprovadas.

### FATO VERIFICADO

O artefato final está tecnicamente apto para impressão.

### DECISÃO PENDENTE EXTERNA

A única dependência acadêmica relevante não resolvível pelo projeto é a avaliação caso a caso da origem baseada em arquivos, exatamente como previsto no roteiro do professor.

## Resultado

**PRIMEIRA ENTREGA: CLOSED / READY FOR PRINT**

Não foi identificado item obrigatório faltante para o escopo da primeira entrega.
