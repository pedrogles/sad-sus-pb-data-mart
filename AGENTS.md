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
- **FASE III — EXTRAÇÃO/STAGING: IN PROGRESS.** Saúde RD/LT/ST, IBGE, referências normativas, CID-10/T28 e SIGTAP/T27 já passaram seus gates locais; C4/CNES leitos possui cobertura **57/57 pares e 35.518/35.518 LT** contra o retrato **setembro/2019**, mas **validade temporal integral 2017–2019/T29 continua não aprovada**.
- A trilha RTS investigada mostrou primeiro resultado na consulta `10/2019A` do usuário; não inferir que os códigos surgiram nesse mês. Preservar `TP_LEITO="3 "` e `CODLEITO="66"` da PB: não substituir silenciosamente por `2/66` do indicador agregado CNESNet.
- Não aprofundar portarias/versionamento histórico apenas para acumular evidências. Qualquer classificação descritiva estática de setembro/2019 usada sobre a série completa exige **decisão explícita documentada e ressalva de temporalidade**; não marcar T29 integral como PASS por conveniência.
- Não iniciar TRANSFORMAÇÃO, LINK_ANALISE, dimensões, fatos ou painéis antes de encerramento verificável da extração/staging, seguindo o Boundary 7.
- Arquivos e testes locais permanecem fora do Git; revalidar os gates afetados quando scripts forem alterados.
- Higiene de branches não autoriza deletar referências: inventário e dry-run antes, aprovação específica, verificação de HEAD/PR e rollback rastreável.

Documentos de evidência:
- `docs/discovery/boundary-7-implementation-plan.md` e `docs/discovery/boundary-8-readiness.md`;
- `docs/discovery/phase-3-health-staging-implementation-2026-10-07.md`;
- `docs/discovery/phase-3-ibge-staging-implementation-2026-10-07.md`;
- `docs/discovery/phase-3-normative-references-implementation-2026-10-07.md`;
- `docs/discovery/phase-3-cid10-reference-implementation-2026-10-07.md`;
- `docs/discovery/phase-3-sigtap-proc-rea-implementation-2026-10-08.md`;
- `docs/discovery/phase-3-cnes-lt-bed-code-implementation-2026-10-08.md`.

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
- **Implementação:** somente **FASE III — EXTRAÇÃO/STAGING** até gate final; a história de cada passo está nos documentos `docs/discovery/phase-3-*.md`.
- **Referências:** T27 SIGTAP e T28 CID-10 PASS. T29 **PASS apenas de cobertura do snapshot setembro/2019**; associação por competência/vigência histórica integral não validada.
- **Decisões pendentes relevantes:** limites de utilização descritiva do snapshot CNES set/2019; gate de fechamento da Fase III; lacunas históricas de nomes de estabelecimentos onde não houver fonte.
- **Não alterar** fontes brutas, relatórios acadêmicos encerrados, arquitetura QlikView 12 ou modelo dimensional sem análise explícita e aprovação.

A cronologia anterior do projeto permanece em `docs/project/current-state-chronology-2026-10-08.md` para auditoria, e o histórico Git conserva as versões anteriores de `AGENTS.md`. Não carregar essa cronologia por padrão.
