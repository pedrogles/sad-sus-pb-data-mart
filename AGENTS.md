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

**FASE III — EXTRAÇÃO**

As Fases I e II estão concluídas. A conversão integral reconciliou os 108 DBCs e T01–T06 estão PASS. A Fase III deve implementar somente a camada de extração/staging prevista no Boundary 7: RD, LT, ST, IBGE e referências auxiliares, com reconciliação obrigatória antes de qualquer transformação dimensional.

Estado atual da Discovery de implementação:

1. aquisição/organização dos 36 meses de 2017–2019: concluída;
2. validação integral dos dados: concluída no Boundary 3;
3. referências auxiliares: concluídas no Boundary 4, com ajustes de materialização ainda pendentes;
4. historização física de `DIM_ESTABELECIMENTO` e role-playing: concluídos no Boundary 5;
5. arquitetura física do QlikView 12: concluída no Boundary 6;
6. plano de implementação: concluído no Boundary 7;
7. Boundary 8 — Readiness: **CONCLUÍDO — GO PARA IMPLEMENTAÇÃO**;
8. Fase I — Infraestrutura mínima: **CONCLUÍDA**;
9. Fase II — Conversão: **CONCLUÍDA — T01–T06 PASS**;
10. próxima etapa autorizada: **FASE III — EXTRAÇÃO**.

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
- Fase II — smoke controlado: **PASS** para `RDPB1702.dbc`, `LTPB1712.dbc` e `STPB1912.dbc`;
- Fase II — conversão integral: **108/108 PASS**;
- T01–T06: **PASS**, incluindo T02 com 108/108 hashes/tamanhos reconciliados, 0 ausentes, 0 duplicados, 0 divergências e 0 extras;
- Fase II — Conversão: **CONCLUÍDA**;
- Fase III — Checkpoint III-A: staging SIH/RD + CNES/LT + CNES/ST implementado em `EXTRACAO/ext_main.qvs`;
- primeira execução local: RD 36/36 e 566.672 registros carregados; falha técnica identificada na comparação de competência por `Num(...)` sobre campos preservados com `Text(...)`;
- correção: competências comparadas como texto normalizado, sem alterar dados ou modelagem;
- segunda execução local: **CHECKPOINT III-A PASS**; três QVDs de saúde gerados e checkpoint `PASS_PARTIAL` com RD=566.672, LT=35.518 e ST=220.390;
- inspeção física IBGE: concluída para 2017–2019; planilha `Municípios`, título na linha 1 e cabeçalho na linha 2 confirmados;
- Fase III — Checkpoint III-B: `SRC_IBGE_POPULACAO.qvd` implementado com gates de 669 linhas, 223 municípios por ano e totais anuais validados;
- primeiro reload III-B: falhou controladamente em `Table Not Found`; o log mostrou `MunicÃ­pios$` no lugar da planilha real `Municípios`;
- correção: nome de planilha e cabeçalhos acentuados usados pelo BIFF/schema são construídos em runtime com `Chr(...)`, evitando dependência da codificação do include `.qvs`;
- segundo reload III-B: BIFF abriu e 223 PB foram carregados; total 2017 divergente por notas numéricas em `7386(4)` e `15276(5)`;
- correção: população é normalizada somente a partir do trecho anterior ao primeiro parêntese; diagnóstico local reconciliou 2017 em 4.025.558;
- terceiro reload III-B: **CHECKPOINT III-B PASS**; `SRC_IBGE_POPULACAO.qvd` e `_CHECKPOINT_EXTRACAO_IBGE.csv` gerados com 669 linhas, 223 municípios por ano e totais 4.025.558 / 3.996.496 / 4.018.127;
- inventário de `BASE/REFERENCIAS`: diretório inicialmente vazio;
- Fase III — Checkpoint III-C1: primeira materialização local 6/21 passou em integridade, mas o primeiro reload Qlik provou que a referência de Motivo estava semanticamente incompleta;
- Caráter de Atendimento: **PASS**, 6 códigos, 566.672/566.672 RD cobertos e `REF_CARATER_ATENDIMENTO.qvd` gerado;
- Motivo de Saída/Permanência: primeira referência 21 linhas deixou 124.233 RD unmatched; inspeção real encontrou 26 códigos observados;
- correção normativa: Portaria SAS/MS nº 384/2010 exclui 13/17, confirma 19, altera internação domiciliar para 32 e inclui 61–67; domínio oficial materializado passa a 28 códigos, incluindo 32/67 não observados;
- rematerialização corrigida: **PASS**, Caráter=6, Motivo=28, hashes 2/2 `MATCH=True`;
- segundo reload III-C1: **CHECKPOINT III-C1 PASS**; `REF_CARATER_ATENDIMENTO.qvd`, `REF_MOTIVO_SAIDA.qvd` e `_CHECKPOINT_EXTRACAO_REFERENCIAS_NORMATIVAS.csv` gerados com 0 unmatched em ambas as referências;
- Fase III — Checkpoint III-C2 CID-10: C2.1 **PASS** em 36 RD / 566.672 linhas; 5.480 códigos brutos distintos, 0 vazios e comprimento 4 em 100% das linhas;
- formato observado: 506.249 linhas / 4.954 códigos distintos `UPPER_ALNUM`; 60.423 linhas / 526 códigos distintos com whitespace;
- C2.2 **PASS**: 60.423 linhas / 526 códigos com whitespace usam somente espaço ASCII à direita; `strip()` preserva 5.480 códigos distintos e gera 0 colisões;
- `Trim(DIAG_PRINC)` é candidato fortemente sustentado para remover padding técnico, mas decisão final depende do lookup oficial;
- C2.3 **PASS**: 36/36 pacotes oficiais SIGTAP encontrados para 2017-01–2019-12, sem lacunas e sem múltiplas versões por competência;
- C2.4 **PASS**: layout idêntico nas quatro competências; `tb_cid.txt` 201701/201801/201901 idêntico (12.450 linhas) e 201912 divergente (14.230 linhas), comprovando mudança de conteúdo dentro de 2019;
- C2.5 implementado em `tools/inspect_cid10_sigtap_sample.py` para revelar encoding, layout real e diff 201901→201912 sem parsing antecipado;
- próxima ação: executar C2.5; não decidir referência única nem normalização final antes dessa inspeção;
- implementação: **LIBERADA SOMENTE PARA A FASE III — EXTRAÇÃO/STAGING**; não emitir conclusão final da fase antes de IBGE + referências + reconciliação.
