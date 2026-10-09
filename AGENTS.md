# AGENTS.md

## Objetivo

Este arquivo é o ponto de entrada obrigatório para agentes que trabalhem no projeto **SAD — Data Mart SUS PB**.

## Ordem de leitura

Antes de executar tarefas estruturais:

1. `AGENTS.md`;
2. `docs/project/current-state.md`;
3. `docs/academic/requirements.md`;
4. documentação específica da tarefa.

## Fontes de verdade

Ordem de autoridade:

1. material oficial da disciplina e instruções do professor;
2. documentação oficial das fontes de dados, especialmente Ministério da Saúde/DATASUS/CNES e IBGE;
3. dados reais inspecionados;
4. documentação versionada neste repositório;
5. chats e memória do ChatGPT como contexto auxiliar.

Chats não substituem documentação persistente.

## Regras de evidência

Separar sempre:

### FATO VERIFICADO

Informação confirmada por material acadêmico, documentação oficial ou inspeção dos dados.

### HIPÓTESE DE MODELAGEM

Interpretação candidata que ainda depende de validação.

### DECISÃO PENDENTE

Questão que ainda não possui evidência suficiente para definição.

Não inventar:

- campos;
- granularidades;
- chaves;
- cardinalidades;
- medidas;
- dimensões;
- regras de negócio;
- relacionamentos entre fontes.

## Preservação de decisões

Antes de propor mudança significativa:

1. verificar `docs/project/current-state.md`;
2. verificar se já existe decisão documentada;
3. preservar as decisões aprovadas da primeira entrega;
4. evitar regressões ou alterações silenciosas de arquitetura;
5. registrar mudanças relevantes em documentação persistente.

## Primeira entrega acadêmica

Status:

**FECHADA — PRONTA PARA IMPRESSÃO/ENTREGA**

Escopo concluído:

- Capítulo 1 — Regras de Negócio;
- modelo conceitual / DER;
- modelo lógico relacional normalizado;
- cardinalidades mínima e máxima;
- Capítulo 2 — Modelagem Dimensional;
- escolha e justificativa Star x Snowflake;
- modelo dimensional.

Revisão canônica:

`docs/academic/first-delivery-review.md`

A primeira entrega não deve ser reaberta ou remodelada silenciosamente durante a implementação. Qualquer descoberta estrutural posterior deve ser registrada como revisão explícita.

## Modelagem dimensional — decisão confirmada

A decisão acadêmica é:

**Star Schema em cada processo factual, com dimensões conformadas compartilhadas.**

O conjunto completo possui três fatos e pode ser descrito tecnicamente como uma **constelação de esquemas estrela**.

Dimensões permanecem desnormalizadas na camada dimensional; não foi adotado Snowflake Schema.

Fatos aprovadas:

- `FATO_INTERNACAO`;
- `FATO_CAPACIDADE_LEITO`;
- `FATO_POPULACAO`.

Dimensões aprovadas:

- `DIM_TEMPO`;
- `DIM_MUNICIPIO`;
- `DIM_ESTABELECIMENTO`;
- `DIM_PROCEDIMENTO`;
- `DIM_DIAGNOSTICO`;
- `DIM_CARATER_ATENDIMENTO`;
- `DIM_MOTIVO_SAIDA_PERMANENCIA`;
- `DIM_TIPO_LEITO`.

## Etapa atual e roteamento

O estado operacional confiável está em **`docs/project/current-state.md`**. Consultar esse arquivo antes de propor implementação ou reabrir um checkpoint. Não reconstruir a situação a partir da cronologia de chats, PRs ou testes antigos.

- **Primeira entrega acadêmica (Capítulos 1 e 2): FECHADA / PRONTA PARA IMPRESSÃO**; prazo do professor: **13/10/2026**. Não reabrir regras de negócio, DER, lógico ou dimensional sem nova evidência/exigência acadêmica.
- **Boundaries 3–8: concluídos; Boundary 8 GO.** Fase I de infraestrutura e Fase II de conversão: **PASS**, com 108/108 DBCs conferidos.
- **FASE III — EXTRAÇÃO/STAGING: PASS LOCAL / FINAL RECONCILED em 08/10/2026 21:46:48 (UTC-03).** QlikView 12: 10 QVDs frescos, 107 campos T08, T07 36/36 competências RD/LT/ST, C1–C5 e checkpoint `_SUCCESS_EXTRACAO.csv` novo com `PASS_FINAL_RECONCILED`. Runner Python retornou exit 0, `PASS_LOCAL_QV_AND_SHA_RECONCILIATION`, manifesto SHA-256 local. A legenda CNES set/2019 é exclusivamente snapshot descritivo, sem inferir vigência; **T29 histórico 2017–2019 permanece NÃO APROVADO**. PR #73 integrado na `main` (squash `5644bdafa5fe4e437ce3417b5368113639468267`); Fase IV iniciada na branch `feat/phase-4-dim-tempo`; IV-TEMPO obteve PASS físico local, demais dimensoes pendentes.
- A trilha RTS investigada mostrou primeiro resultado na consulta `10/2019A` do usuário; não inferir que os códigos surgiram nesse mês. Preservar `TP_LEITO="3 "` e `CODLEITO="66"` da PB: não substituir silenciosamente por `2/66` do indicador agregado CNESNet.
- **Decisão aprovada em 08/10/2026:** materializar referência CNES de setembro/2019 **somente como legenda datada, sem join sobre o LT histórico ou atribuição de vigência retroativa**. Preservar a chave competência-aware do Boundary 7 e preservar os testes **III-C4.3 PASS local** da carga de `REF_TIPO_LEITO.qvd` no QlikView 12, mantendo `T29_HISTORICAL=NOT_APPROVED`. Não aprofundar portarias/versionamento sem nova necessidade acadêmica/analítica; nunca marcar T29 histórico como PASS por conveniência.
- O gate físico da EXTRAÇÃO foi aprovado; PR #73 e PR #74 já estão integrados na `main`. Na Fase IV, `DIM_TEMPO` está integrada e `DIM_MUNICIPIO` passou no QlikView 12 local e na auditoria física QVD/CSV em 09/10/2026 00:10:51. A DIM municipal possui 937 linhas (223 municípios PB + 714 códigos externos distintos), 8 campos, 937 SK distintas, 0 inválidos, zero unmatched RD/ST/LT; preserva 5.202 registros RD externos sem inferir IBGE7/nome/UF. A evidência está em `docs/discovery/phase-4-dim-municipio-implementation-2026-10-08.md`. PR #75 integrado na `main` por squash `7f796bed9aa3c41e8bf80fe0d24d493b8e66a1d9`; não iniciar fatos, Link Table nem painéis antecipadamente.
- Arquivos e testes locais permanecem fora do Git; revalidar os gates afetados quando scripts forem alterados.
- Higiene de branches não autoriza deletar referências: inventário e dry-run antes, aprovação específica, verificação de HEAD/PR e rollback rastreável.

Documentos de evidência:
- `docs/discovery/boundary-7-implementation-plan.md` e `docs/discovery/boundary-8-readiness.md`;
- `docs/discovery/phase-3-health-staging-implementation-2026-10-07.md`;
- `docs/discovery/phase-3-ibge-staging-implementation-2026-10-07.md`;
- `docs/discovery/phase-3-normative-references-implementation-2026-10-07.md`;
- `docs/discovery/phase-3-cid10-reference-implementation-2026-10-07.md`;
- `docs/discovery/phase-3-sigtap-proc-rea-implementation-2026-10-08.md`;
- `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`;
- `docs/discovery/phase-3-municipal-crosswalk-materialization-2026-10-08.md`;
- `docs/discovery/phase-3-final-extraction-gate-2026-10-08.md`.

## QlikView

Ferramenta obrigatória:

**QlikView 12**

O fluxo ensinado pelo professor permanece como referência inicial:

```text
BASE
  ↓
EXTRACAO
  ├── EXT.qvw
  └── QVD
  ↓
TRANSFORMACAO
  ├── QVW de transformação
  └── QVD
  ↓
PAINEL
  └── QVW de apresentação/análise
```

Conceitos presentes no material da disciplina:

- processamento in-memory;
- AQL / linguagem associativa;
- QVW;
- QVD;
- consolidação de múltiplas fontes;
- análise associativa.

Não substituir silenciosamente esse fluxo por outra arquitetura.

Scripts externos ou outros mecanismos versionáveis podem ser avaliados como complemento quando tecnicamente úteis e compatíveis com o processo ensinado.

O arquivo `.qvw` não deve ser a única fonte persistente de decisões de modelagem ou regras de negócio.

## Dados

Dados brutos e artefatos derivados não devem ser versionados automaticamente.

Antes de adicionar datasets ao Git:

1. avaliar tamanho;
2. avaliar licença/redistribuição;
3. distinguir fonte original de artefato derivado;
4. preferir versionar scripts, metadados e documentação de aquisição.

## Escopo atual

- **Modelagem:** 3 fatos, 8 dimensões, Star Schema por processo, constelação com dimensões conformadas. Granularidades, chaves, regras e limitações acadêmicas aprovadas estão em `docs/academic/chapter-1-2-modeling.md` e `docs/project/current-state.md`.
- **Implementação:** Fase III aquisição/extração/staging **PASS FINAL**. Fase IV **IN PROGRESS — 7/8 dimensões integradas na `main`**: `DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`, `DIM_DIAGNOSTICO`, `DIM_CARATER_ATENDIMENTO`, `DIM_MOTIVO_SAIDA_PERMANENCIA`. PR [#80](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/80) **MERGED via squash autorizado** em 09/10/2026, commit `14bea0336d79a015ecd11127d98a00db31a55dfe`, com guarda `expected_head_sha=f0f9711a39e016044972861189804f262ba901a2` e `mergeable=true` confirmado antes do merge. Sétima dimensão QlikView 12 local PASS: referência normativa C1 28 códigos/6 categorias, `COBRANCA` fonte 24→normativo 2.4, 36 SIH/RD/566672 registros, 26 códigos observados, 0 unmatched/0 diferenças de frequência; QVD dimensional **28×7** SHA `7306b75e1c29005d1ea50d16e4f67db330360fbcb46bb711ab3b0aee82c25e57` (7062 bytes), checkpoint parcial SHA `69d22d1a982d58ef2d3d85aa92f0861052c932dc68a557487c26b6775ae0d30c` (705 bytes). Reload finalizado 09/10/2026 às 11:30:40 (log em trechos; auditor independente só cabeçalho/checkpoint, não QVD binário completo; sem CI demonstrado). PR #79 CARATER, #78 DIAGNOSTICO e #77 PROCEDIMENTO já integrados. CID201912 é superset descritivo sem vigência normativa individual mensal. `T29_HISTORICAL=NOT_APPROVED`; Capítulos 1–2 fechados; fatos/Link Table/PAINEL NOT_STARTED.
- **Referências:** T27 SIGTAP e T28 CID-10 PASS. T29 **PASS apenas de cobertura do snapshot setembro/2019**; associação por competência/vigência histórica integral não validada.
- **Checkpoint III-C5.1 municipal:** QlikView 12 PASS local em 08/10/2026: 223 códigos IBGE7 e 223 prefixos6 únicos, zero unmatched nos municípios PB das fontes, 5.202 RD com residência fora da PB separados; o código oficial completo vem dos XLS IBGE. Isso valida o **candidato PB**, sem materializar ponte. Detalhes: `docs/discovery/phase-3-municipal-crosswalk-preflight-2026-10-08.md`.
- **III-C5.2 municipal (PASS LOCAL em 08/10/2026):** referência **derivada pelo projeto** com 223 pares PB DATASUS6↔IBGE7 validada em QlikView 12 e auditoria Python SHA-256, veredito `PASS_LOCAL_REFERENCE_AUDIT`. `REF_MUNICIPIO_PB_DERIVADA.qvd` e CSV locais, SHA dos três XLS IBGE registrado no manifesto local. Não rotular como equivalência oficial externa publicada; preservar 5.202 RD não-PB sem população PB. Documento: `docs/discovery/phase-3-municipal-crosswalk-materialization-2026-10-08.md`.
- **III-FINAL (PASS LOCAL em 08/10/2026 às 21:46:48):** após corrigir três erros de sintaxe por `;` internos nas mensagens `TRACE`, o runner Qlik retornou `RUNNER_EXIT=0`, `PASS_LOCAL_QV_AND_SHA_RECONCILIATION` e `_SUCCESS_EXTRACAO.csv` com `PASS_FINAL_RECONCILED`; log `EXT.qvw.2026_10_08_21_46_26.log` exibiu `SUCCESS_MARKER_WRITTEN` e ausência de `Unknown statement`/`Syntax Error` na busca informada. **10 QVDs, 107 campos T08, T07 RD/LT/ST 3×36 PASS**, C1–C5 preservados. Manifesto local não versionado. PR #73 integrado à `main`; evidência da Fase III preservada. Documento: `docs/discovery/phase-3-final-extraction-gate-2026-10-08.md`.
- **Próximos gates (atualizado em 09/10/2026):** Fase IV **7/8 dimensões integradas na `main`**, `DIM_TIPO_LEITO` em Discovery READ-ONLY na branch `feat/phase-4-dim-tipo-leito-discovery`. A1: 36 LT/35.518 linhas, 57 pares, 2.021 pares-mês, 0 duplicatas de chave candidata de fato, 56 pares-mês em 201909 e 1.965 sem descrição histórica comprovada; triagem C4.2c.4a: 74=208, 77=158, 94=0, 95=220 linhas LT, sem inferir mudança normativa por presença. C4.2c.4b identificou canais oficiais e releases históricos de SCNES. **Evidência superveniente C4.2c.4c:** capturas do navegador enumeram visualmente versões SCNES anteriores e **36 nomes de ZIPs CNES `201701–201912`**, inclusive `201701–201705`; a Wiki descreve canal de bases por competência a partir de 06/2017, divergência ainda não reconciliada quanto à acessibilidade. **C4.2c.4d:** a captura [Documentação CNES](https://cnes.datasus.gov.br/pages/downloads/documentacao.jsp) mostra `Tabelas de Domínio` com última atualização **18/10/2019** e [link fornecido do item `SCNES_DOMINIOS.ZIP`](https://cnes.datasus.gov.br/EstatisticasServlet?path=SCNES_DOMINIOS.ZIP); dados binários e versão interna **não inspecionados**. Próximo gate: **aprovação específica** antes de adquirir/inspecionar apenas esse artefato mínimo, se necessário. `C4.2c.4c=PASS_METADATA_INVENTORY_ONLY`; `A2=DECISION_PENDING`; `T29_HISTORICAL=NOT_APPROVED`. **Não** inferir datas de vigência de `NFCES001/TB_LEITO` ou `NFCES028/TB_ATRIBUTO` pela atualização de 2019; não criar SK alterada, QVD dimensional, fatos, Link Table ou PAINEL nem editar os capítulos acadêmicos fechados. Fonte detalhada: `docs/discovery/phase-4-dim-tipo-leito-discovery-2026-10-09.md` e resumo `docs/project/current-state.md`.
- **Não alterar** fontes brutas, relatórios acadêmicos encerrados, arquitetura QlikView 12 ou modelo dimensional sem análise explícita e aprovação.

A cronologia anterior do projeto permanece em `docs/project/current-state-chronology-2026-10-08.md` para auditoria, e o histórico Git conserva as versões anteriores de `AGENTS.md`. Não carregar essa cronologia por padrão.
