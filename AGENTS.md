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

## Próxima fase

Próxima etapa planejada:

**FASE II — CONVERSÃO**

A Fase I — Infraestrutura mínima foi concluída. A Fase II deve seguir o Boundary 7: validar primeiro 1 RD, 1 LT e `STPB1912.dbc`; somente depois executar a conversão integral 108/108.

Estado atual da Discovery de implementação:

1. aquisição/organização dos 36 meses de 2017–2019: concluída;
2. validação integral dos dados: concluída no Boundary 3;
3. referências auxiliares: concluídas no Boundary 4, com ajustes de materialização ainda pendentes;
4. historização física de `DIM_ESTABELECIMENTO` e role-playing: concluídos no Boundary 5;
5. arquitetura física do QlikView 12: concluída no Boundary 6;
6. plano de implementação: concluído no Boundary 7;
7. Boundary 8 — Readiness: **CONCLUÍDO — GO PARA IMPLEMENTAÇÃO**;
8. Fase I — Infraestrutura mínima: **CONCLUÍDA**; próxima etapa autorizada: **FASE II — CONVERSÃO**.

Documentos canônicos adicionais:

- `docs/discovery/boundary-4-auxiliary-references.md`;
- `docs/discovery/boundary-5-historization-role-playing.md`;
- `docs/discovery/boundary-6-qlikview-physical-architecture.md`;
- `docs/discovery/boundary-7-implementation-plan.md`;
- `docs/discovery/boundary-8-readiness.md`.

Estado do readiness:

- preflight local: **PASS**, sem blockers automáticos;
- Python 3.14.8, `.venv`, `dbc-to-dbf==1.0.1` e `dbfread==2.0.7`: comprovados;
- QlikView localizado em `C:\Program Files\QlikView\Qv.exe`;
- BASE local: 36 RD + 36 LT + 36 ST e IBGE 2017–2019 comprovados;
- smoke DBC → DBF → CSV UTF-8: **PASS**;
- checkpoints reproduzidos: RD 2017-02 = 13.912/113; LT 2017-12 = 1.033/28; ST 2017-01 = 5.692/201; ST 2019-12 = 6.438/208;
- `tools/readiness_check.ps1`, `tools/readiness_dbc_smoke.py`, `tools/readiness_smoke.qvs` e `tools/readiness_link_table_smoke.qvs` compõem a suíte de readiness;
- o `.gitignore` está alinhado à estrutura física planejada;
- política de batch: `ErrorMode=0` + checagem explícita de erros;
- smoke QlikView: **PASS** para CSV → QlikView, `Must_Include`, include aninhado, QVD STORE e `Qv.exe /r`;
- protótipo mínimo da Link Table: **PASS**, sem `$Syn` ou circular reference visível no Table Viewer;
- QlikView major version: **PASS — 12.0.20000.0**;
- manifesto final de aquisição confirmado: `manifesto-execucao.json` possui `size_bytes` e `sha256` por DBC;
- `tools/readiness_reconcile_hashes.py` foi adicionado para o gate 108/108;
- reconciliação integral de hashes/tamanhos: **PASS — 108/108**;
- caminho de falha do batch com `ErrorMode=0` + `ScriptErrorCount`: **PASS**;
- referências auxiliares: tratamento explícito aprovado para o GO; materialização/cobertura permanecem na implementação;
- T27–T29 permanecem gates de implementação para SIGTAP, CID-10 e CNES leitos;
- Boundary 8: **CONCLUÍDO — GO PARA IMPLEMENTAÇÃO**.

A **FASE I — INFRAESTRUTURA MÍNIMA** está **CONCLUÍDA**. A infraestrutura versionável foi materializada no repositório e os três QVWs mínimos foram criados e recarregados com sucesso no QlikView 12 usando seus respectivos `Must_Include`. Dashboards continuam fora de escopo até as fases posteriores previstas no Boundary 7.

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

- Feasibility Discovery: concluída;
- Dataset Validation / Modeling Discovery: concluída;
- Modelagem acadêmica dos Capítulos 1 e 2: concluída;
- Primeira entrega: fechada e pronta para impressão/entrega;
- Boundary 3 — Full Dataset Validation: concluído;
- Boundary 4 — Referências Auxiliares: concluído com ajustes;
- Boundary 5 — Historização / Role-playing: concluído;
- Boundary 6 — Arquitetura física QlikView: concluído;
- Boundary 7 — Plano de implementação: concluído;
- Boundary 8 — Readiness: **CONCLUÍDO — GO PARA IMPLEMENTAÇÃO**;
- discovery de implementação: **CONCLUÍDA COM GO**;
- Fase I — Infraestrutura mínima: **CONCLUÍDA**;
- infraestrutura versionável: scripts `.qvs`, conversor DBC, dependências e diretórios QVD materializados;
- QVWs mínimos locais: **PASS** para `EXT.qvw`, `TRANSF.qvw` e `PAINEL.qvw`;
- próxima ação: iniciar **FASE II — CONVERSÃO** com 1 RD + 1 LT + `STPB1912.dbc`;
- implementação: **LIBERADA PARA A FASE II — CONVERSÃO**, sem antecipar Extração/Transformação.
