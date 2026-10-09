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
- **Implementação:** Fase III EXTRAÇÃO/STAGING PASS FINAL. Fase IV DIMENSÕES IN PROGRESS: **4/8 integradas na `main`** (`DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`). PR **#77** da DIM_PROCEDIMENTO **MERGED por squash** mediante autorização explícita em 09/10/2026, commit **`4ecd27fc3cfa96ffd8c784128650323b197d5892`**. Reload local QlikView 12 `TRANSF.qvw.2026_10_09_09_24_36.log` concluiu 09:24:48: SIGTAP 165203 procedimentos×competência (36 meses, origem 10 campos, 0 inválidos), RD 566672/0 unmatched, DIM_PROCEDIMENTO QVD 165203 linhas/12 campos SHA-256 `620b3f9d4d1babdf25b2d1f2f5653ad7089e4003986048bdb746b5662f2de56b`, checkpoint parcial SHA `b6180cecb7b91b93d2fd5906ed7034549ce38105cde4d6d0eb0f03b4a7639543`. Auditor Python do QVD/checkpoint e staging CSV SIGTAP/216 arquivos originais PASS local; QVD binário não decodificado independentemente, e nenhuma execução CI GitHub foi identificada para PR #77. DESCRICAO_OFICIAL detalhada sem fonte: NULL/status. Encoding cp1252 operacional igual a ISO-8859-1 nos bytes observados; ZIP 201808 tem versão retrospectiva e `T29_HISTORICAL=NOT_APPROVED`. Fatos/Link Table/PAINEL NOT_STARTED. Evidências em `docs/discovery/phase-4-dim-procedimento-preflight-2026-10-09.md`.
- **Referências:** T27 SIGTAP e T28 CID-10 PASS. T29 **PASS apenas de cobertura do snapshot setembro/2019**; associação por competência/vigência histórica integral não validada.
- **Checkpoint III-C5.1 municipal:** QlikView 12 PASS local em 08/10/2026: 223 códigos IBGE7 e 223 prefixos6 únicos, zero unmatched nos municípios PB das fontes, 5.202 RD com residência fora da PB separados; o código oficial completo vem dos XLS IBGE. Isso valida o **candidato PB**, sem materializar ponte. Detalhes: `docs/discovery/phase-3-municipal-crosswalk-preflight-2026-10-08.md`.
- **III-C5.2 municipal (PASS LOCAL em 08/10/2026):** referência **derivada pelo projeto** com 223 pares PB DATASUS6↔IBGE7 validada em QlikView 12 e auditoria Python SHA-256, veredito `PASS_LOCAL_REFERENCE_AUDIT`. `REF_MUNICIPIO_PB_DERIVADA.qvd` e CSV locais, SHA dos três XLS IBGE registrado no manifesto local. Não rotular como equivalência oficial externa publicada; preservar 5.202 RD não-PB sem população PB. Documento: `docs/discovery/phase-3-municipal-crosswalk-materialization-2026-10-08.md`.
- **III-FINAL (PASS LOCAL em 08/10/2026 às 21:46:48):** após corrigir três erros de sintaxe por `;` internos nas mensagens `TRACE`, o runner Qlik retornou `RUNNER_EXIT=0`, `PASS_LOCAL_QV_AND_SHA_RECONCILIATION` e `_SUCCESS_EXTRACAO.csv` com `PASS_FINAL_RECONCILED`; log `EXT.qvw.2026_10_08_21_46_26.log` exibiu `SUCCESS_MARKER_WRITTEN` e ausência de `Unknown statement`/`Syntax Error` na busca informada. **10 QVDs, 107 campos T08, T07 RD/LT/ST 3×36 PASS**, C1–C5 preservados. Manifesto local não versionado. PR #73 integrado à `main`; evidência da Fase III preservada. Documento: `docs/discovery/phase-3-final-extraction-gate-2026-10-08.md`.
- **Próximos gates:** Fase IV 4/8 dimensões integradas na `main` (TEMPO, MUNICIPIO, ESTABELECIMENTO, PROCEDIMENTO, PR #77). **IV-DIAGNOSTICO:** preflight físico CID-10/T28 PASS local (14230 códigos 201912, 566672 RD/0 unmatched, 60423 valores com espaço ASCII trailing). Novo QVD local `DIM_DIAGNOSTICO.qvd` **materializado e auditado por cabeçalho/checkpoint**: 14230 linhas/5 campos, QVD SHA-256 `5d5912c12023c33ad85f93070e7d1ccf55e0d333686d8625c9804a76c06ef1d8` (1314463 bytes), checkpoint SHA-256 `e608153559e07282ceb2dc914f636c06c565f8d3d7df8fe2472e5f1340485a94`, 14230 SK distintas e RD 566672/0 unmatched registrados, `PASS_LOCAL_DIM_DIAGNOSTICO_QVD_HEADER_CHECKPOINT_RECONCILED`. Primeira tentativa de auditoria falhou por QVD inexistente, segunda passou após arquivo surgir. **FALTA LOG REAL DO RELOAD QLIKVIEW 12** (SOURCE 14230×4, T28 566672/0, STORE, encerramento normal); não abrir PR de integração antes desse log. O auditor não decompõe corpo binário do QVD. `Text(RTrim(Text(DIAG_PRINC)))` obrigatória; CID201912 é superset descritivo, nunca prova de vigência mensal. T29 histórico NOT_APPROVED, Capítulos 1–2 fechados, fatos/Link Table/PAINEL NOT_STARTED. Evidência: `docs/discovery/phase-4-dim-diagnostico-preflight-2026-10-09.md`.
- **Não alterar** fontes brutas, relatórios acadêmicos encerrados, arquitetura QlikView 12 ou modelo dimensional sem análise explícita e aprovação.

A cronologia anterior do projeto permanece em `docs/project/current-state-chronology-2026-10-08.md` para auditoria, e o histórico Git conserva as versões anteriores de `AGENTS.md`. Não carregar essa cronologia por padrão.
