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
- C2.5 **PASS**: `tb_cid.txt` em cp1252, 111 bytes/linha; `CO_CID` posições 1–4 e `NO_CID` 5–104; 201901→201912 adiciona 1.780 linhas e remove 0;
- as adições observadas incluem categorias CID de 3 caracteres com espaço ASCII de padding na quarta posição, alinhadas ao padrão já observado em `DIAG_PRINC`;
- C2.6 **PASS**: 201912 adiciona 1.780 chaves, remove 0, altera 0 descrições/payload compartilhados e cobre 566.672/566.672 RD; 201901 deixa 1.901 linhas / 349 códigos de 3 caracteres sem cobertura, todos presentes em 201912;
- decisão CID-10 confirmada para o Data Mart inicial: usar 201912 como referência descritiva estática/superset; não interpretar como vigência mensal; normalização = remover somente espaço ASCII à direita;
- C2.7 primeira execução: bloqueio controlado no gate de distribuição; resultado real 2.042 códigos de comprimento 3 + 12.188 de comprimento 4;
- causa: o gate confundia as 1.780 novas categorias de 3 caracteres de 201912 com o total de categorias de 3 caracteres; as 12.450 chaves anteriores já possuem 262;
- C2.7 corrigido e reexecutado: **PASS**, 14.230 códigos únicos, distribuição 2.042/12.188, decisão `STATIC_DESCRIPTIVE_SUPERSET`, hash do CSV reconciliado com `MATCH=True`;
- C2.8 primeiro reload: referência CID passou os gates estruturais, mas 9.093/566.672 linhas RD ficaram unmatched no QVD; reload interrompido controladamente;
- C2.8a/b: 9.093 linhas RD unmatched, 128 códigos distintos; todos são texto no QVD (`IsNum=0`, `IsText=-1`);
- C2.8c **PASS**: os 128 códigos / 9.093 ocorrências têm `direct_text_match=1` e `text_after_rtrim_match=1`; o lookup antigo com `RTrim(Text(DIAG_PRINC))` falhou;
- C2.8d **PASS** em 08/10/2026 10:44:15: após `Text(RTrim(Text(DIAG_PRINC)))`, `REF_CID10.qvd` gerado e `_CHECKPOINT_EXTRACAO_CID10.csv` validado (`PASS_PARTIAL`; 14.230 códigos únicos; distribuição 2.042/12.188; 566.672 RD; **0 unmatched**);
- III-C2 — CID-10 **CONCLUÍDO — PASS**, T28 cobertura `DIAG_PRINC↔CID-10` **PASS**; decisão de referência `201912` descritiva/superset preservada, sem vigência mensal inferida;
- Fase III-C3 — SIGTAP / `PROC_REA`: iniciado C3.1 em `tools/profile_proc_rea.py` para perfil read-only dos 36 CSVs RD; valida contagens, competências e formato bruto textual, gerando perfis mensal/por código e hashes locais;
- C3.1 **PASS em 08/10/2026**: 36 RD, 566.672 linhas, 1.249 códigos `PROC_REA` distintos, 0 vazios, 100% com 10 dígitos ASCII e zero inicial; perfis código/mês com 1.249/36 linhas e SHA-256 reconciliados (`HashMatch=True`);
- C3.2 **PASS** em 08/10/2026: 4 ZIPs oficiais temporários (201701/201801/201901/201912), 87 membros por pacote, 18 DATA e 17 LAYOUT candidatos por pacote, 140 candidatos; identificado `tb_procedimento.txt` e `tb_procedimento_layout.txt` nos quatro meses; prévia confirma `CO_PROCEDIMENTO` (10 posições, início 1), ainda sem layout completo validado;
- C3.3a **IMPLEMENTADO / EXECUÇÃO LOCAL PENDENTE**: `tools/materialize_sigtap_procedure_sample.py`, materialização somente dos dois arquivos físicos em cada um dos quatro ZIPs já comprovados; hashes ZIP comparados com C3.2, layout posicional e linhas inspecionados dinamicamente;
- T27 cobertura `PROC_REA↔SIGTAP` **NÃO AVALIADA**; 36/36 pacotes disponíveis no inventário C2.3 mas aquisição histórica integral bloqueada até evidência C3.3a;
- próxima ação: executar C3.3a localmente, analisar colunas, tamanhos, chaves, hashes e estabilidade do layout nos 4 meses antes de implementar o histórico por competência;
- implementação: **LIBERADA SOMENTE PARA A FASE III — EXTRAÇÃO/STAGING**; não emitir conclusão final da fase antes de IBGE + referências + reconciliação.
