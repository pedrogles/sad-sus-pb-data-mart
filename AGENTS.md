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
- C3.3a **PASS** em 08/10/2026: referência `tb_procedimento` com 4.542/4.587/4.609/4.624 linhas nas competências 201701/201801/201901/201912; 16 campos, 330 bytes/registro, 0 chaves inválidas/comprimentos inválidos/duplicações, `LAYOUT_DISTINCT_HASHES=1`, manifesto local PASS;
- layout físico confirmado: `CO_PROCEDIMENTO` 1–10, `NO_PROCEDIMENTO` 11–260, `DT_COMPETENCIA` 325–330; descrições de grupo/subgrupo/forma de organização ainda exigem fonte/relacionamento oficial verificado;
- C3.3a.1 **PASS** em 08/10/2026: piloto `PROC_REA + competência` contra SIGTAP para 201701/201801/201901/201912 = **59.365/59.365 RD cobertos**, 0 unmatched e 0 pares código/competência sem match; RD mensais 14.726 / 14.501 / 15.155 / 14.983;
- C3.3b.1 **PASS em 08/10/2026**: 36/36 competências históricas, 4 amostras reutilizadas e 32 pacotes novos, 165.203 linhas de referências mensais, layout de 16 campos/330 bytes uniforme (`sha256=75641d897c8205d3d2e94ddb96431d51bf7a9ed5871ba0645484715cffffb88a`), inventário histórico hash `23eb6942d69c8c81f30bde5eded896cad2881b64c77cacd1b80b3bb57ad2af8a` conferido;
- C3.3b.2 **PASS** em 08/10/2026: todas as 36 competências reconciliadas; 566.672/566.672 registros SIH/RD cobertos, 0 unmatched, 0 pares código/mês sem correspondência; 21.031 pares distintos código+competência observados nos RD; relatórios de cobertura (36 linhas) e unmatched (0 linhas) com SHA-256 conferidos;
- T27 **CONCLUÍDO — PASS**: `(RD.competência, PROC_REA)` ↔ `(SIGTAP.DT_COMPETENCIA, CO_PROCEDIMENTO)`, sem exceções; QVD/extração Qlik foram confirmados posteriormente em C3.4b;
- C3.4a **ESTRUTURA/HASH PASS** em 08/10/2026: materializados 165.203 registros/pares código+competência únicos em 36 meses; CSV SHA-256 `75237997a26bea243b101af1bd19e04e3f4905fb237ac9d227db860cbd14b482` com `CSV_SHA_MATCH=True`; 48.749 descrições com caracteres não ASCII; manifesto original `STRUCTURE_PASS_ENCODING_REVIEW`, encoding `cp1252` aprovado operacionalmente na etapa C3.4a.1 posterior;
- C3.4a.1 **PASS em 08/10/2026**: auditoria read-only de 165.203 descrições/referências em 36 competências, 48.749 descrições não ASCII, 16 amostras variadas de acentos legíveis, `SUSPECT_MOJIBAKE_MARKERS=0` e hash do CSV conferido; `cp1252` aprovado apenas como **interpretação operacional**, não como encoding oficialmente declarado;
- C3.4b **PASS EM RELOAD QLIK LOCAL — 08/10/2026 12:44:24**: após C3.4b.1 corrigir `IF` multilinha, foram gerados `EXTRACAO/QVD/REF_SIGTAP.qvd` (4.606.958 bytes) e `_CHECKPOINT_EXTRACAO_SIGTAP.csv` (202 bytes). Checkpoint: `EXTRACAO_SIGTAP;PASS_PARTIAL;165203;165203;36;566672;0` após timestamp, com 0 RD unmatched;
- III-C3 / SIGTAP **CONCLUÍDO — PASS**, mantendo T27 PASS e encoding `cp1252` aprovado operacionalmente; artefatos QVD/CSV locais ignorados pelo Git;
- III-C4.1 **PASS em 08/10/2026**: perfil read-only de 36 CNES/LT / 35.518 linhas; 7 valores brutos de `TP_LEITO`, 57 de `CODLEITO`, 57 pares, 0 campos exatamente vazios e 0 competências divergentes. `CODLEITO` contém dois dígitos ASCII em todos os registros; `TP_LEITO` possui 2 caracteres e contém whitespace em todas as linhas (preenchimento não classificado como inicial/final ainda); não normalizar sem evidência;
- C4.1 HASHES CONFERIDOS: perfis mensais 36 linhas SHA-256 `73ddcfd5cc73342f7c2d75d4565f798b95c92e2fec0edb3f92b5d225fd698c34` e pares 57 linhas SHA-256 `4afe0741b1bf43434192e467a043a0bcb7f2a96e25214f92f47557531e238449`; ambos `HashMatch=True`; 57 códigos distintos por mês em janeiro–maio de 2018 (56 nos demais meses), sem identificação ainda do código responsável;
- C4.1a **PASS (08/10/2026) na inspeção física restrita**: `TP_LEITO` bruto exatamente `"1 "` … `"7 "`, byte/caractere final ASCII 32; pares `TP_LEITO`→contagem de `CODLEITO` 15/13/16/2/2/5/4. Nas diferenças 201712→201801, apareceu somente `CODLEITO=70`; 201805→201806 desapareceu somente `70`. Não atribuir descrição ou vigência normativa ao código;
- C4.2a **REFERÊNCIA PONTUAL DO CÓDIGO 70 COMPROVADA**: perfil PB confirmou `TP_LEITO="7 "`, `CODLEITO="70"`, 5 ocorrências em 5 competências (201801–201805), uma por mês. Consulta primária DATASUS/CNES de 201712 (UF 35, São Paulo) registra código `70` como `FIBROSE CISTICA` dentro de `HOSPITAL DIA` (`TP_LEITO=7`); existência oficial pré-2018 não permite afirmar criação do código em jan/2018;
- C4.2b.1 **5/5 HTMLs HISTÓRICOS CAPTURADOS / COMPETÊNCIA NÃO COMPROVADA (08/10/2026)**: 201712/201801/201805/201806/201912 (UF=00) retornaram 53.009/53.008/53.007/53.006/53.008 bytes, cp1252, sinais CNES/leitos/Hospital Dia/código 70 presentes; `COMPETENCE_SELECTED=False` em 5/5; `SOURCE_INSPECTION_REQUIRED`. Não concluir que parâmetros foram ignorados nem que representam meses diferentes;
- C4.2b.2 **INTEGRIDADE PASS / HISTÓRICO REVIEW (08/10/2026)**: auditoria offline de 5/5 HTMLs, 0 falhas de hash/tamanho, 5 hashes HTML diferentes, 5 hashes do texto visível e 5 hashes do trecho de leitos diferentes; `EXPLICIT_COMPETENCES=0`. As diferenças não comprovam versão/competência normativa nem que parâmetros foram ignorados;
- C4.2b.3 **EXECUTADO / ESTRUTURA PASS, SEMÂNTICA REVIEW (08/10/2026)**: cinco HTMLs íntegros, 77 linhas de tabela e uma linha do código `70` em cada; transições 201712→201801 / 201801→201805 / 201805→201806 / 201806→201912 tiveram 65/67/61/68 linhas diferentes, inclusive após neutralização de eco dos meses. Exemplos exibiram mesmos códigos/descrições com contagens de leitos diferentes; isso não comprova validade histórica, competência selecionada nem catálogo oficial;
- C4.2b.3a **PASS AMOSTRAL DE RÓTULOS (08/10/2026)**: reexecução local verificou 5/5 HTMLs íntegros, 77 linhas de tabela por captura e 65 pares distintos `(código, descrição)` em cada; em quatro transições, `LABEL_ADD=0`/`LABEL_REMOVE=0`, enquanto 61/63/58/64 linhas com os mesmos rótulos mudaram em outras células, compatíveis com quantidades. Competências efetivas não confirmadas (0/5) e cabeçalhos de tipo não preservados pelo parser; nenhuma prova de domínio completo ou estabilidade normativa;
- C4.2c **DOCUMENTOS CNES RECEBIDOS / ESTRUTURA VERIFICADA (08/10/2026)**: `SCNES_DOMINIOS.XLS` (OOXML apesar extensão XLS, SHA-256 `ae3f678f1f2307d759412c735f79bf1ace5a91410261f4050dc6e86c671c2af4`, criado internamente em 15/10/2019) contém 56 abas; `LEITOS` tem 66 códigos de 2 dígitos/descrições únicos e `TIPOS DE LEITOS` tem 7 tipos/descrições únicos. Código `70 = FIBROSE CISTICA`; tipo `7 = HOSPITAL DIA`; listas **NÃO** associam cada leito ao tipo;
- C4.2c dicionário `DICIONARIO_DE_DADOS.docx` (SHA-256 `086bfcbdbf47ea13d89542a21128c691367c0560a9f6bf8a2319e8a6eadb973b`, modificado internamente em 15/01/2026) identifica `LFCES002/RL_ESTAB_COMPLEMENTAR` com códigos/totais; `NFCES001/TB_LEITO` contém `CO_LEITO`, `DS_LEITO` e `TP_LEITO` (IND_LEITO); `NFCES028/TB_ATRIBUTO` usa indicador `006` para tipos. Datas internas de arquivo NÃO certificam vigência 2017–2019; URLs diretas/versões oficiais não comprovadas;
- C4.2c.1 **AUDITORIA LOCAL IMPLEMENTADA / EXECUÇÃO PENDENTE**: `tools/audit_cnes_official_domains.py` mede correspondência INDEPENDENTE dos códigos e tipos observados nos 57 pares/35.518 linhas LT com as duas abas, preservando espaço ASCII final do campo de origem e sem assumir relação tipo↔código. Colocar XLS original em `BASE/REFERENCIAS` ignorado pelo Git antes de executar; mesmo cobertura total será apenas PROVISÓRIA;
- C4.2c.2 **DECISÃO PENDENTE**: obter a associação oficial de `TB_LEITO` (`CO_LEITO`, `DS_LEITO`, `TP_LEITO`) e evidência histórica por competência. Não declarar T29 nem `REF_TIPO_LEITO.qvd` PASS com listas independentes;
- descoberta: indicador oficial CNES lista códigos/descrições por competência mas não precisa exibir códigos sem leitos; portal CNES anuncia tabelas de domínio por JavaScript sem URL histórica comprovada; CONASS secundário contém `codleito` repetido sob tipos diferentes, portanto não assumir `CODLEITO` globalmente único (embora local PB tenha 57 códigos/57 pares);
- C4.2b **DOMÍNIO HISTÓRICO COMPLETO PENDENTE**: identificar referência oficial para 57 códigos e 7 tipos, validar versão temporal e chave `TP_LEITO+CODLEITO` antes de qualquer enriquecimento; `TP_LEITO` bruto mantém espaço ASCII final;
- T29 `CODLEITO ↔ referência oficial CNES` **NÃO AVALIADO**: nenhum QVD de referência leito criado ou cobertura 35.518 LT medida; Fase III parcial;
- implementação: **LIBERADA SOMENTE PARA A FASE III — EXTRAÇÃO/STAGING**; não emitir conclusão final da fase antes de IBGE + referências + reconciliação.
