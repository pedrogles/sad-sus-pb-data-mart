# SAD — P1.4 | Ranking por procedimento realizado (E2) — início READ-ONLY

**Gate:** `SAD-P14-PROC-RANKING-READONLY-01`  
**Data:** 29/10/2026  
**Estado:** `BLOCKED_SOURCE_NOT_ACCESSIBLE_IN_THIS_SESSION` — início e contrato registrados; **não** significa falha ou ausência do E2 no computador do responsável.  
**Baseline confirmada:** `main@a75de8461ff7d2a7488b9604cdd4394a1e0cd171`, após merge do PR #180.  
**Escopo:** apenas análise numérica descritiva do extrato E2 já materializado, sem novas extrações, sem QlikView/COM/QVD/QVW/QVS, sem merge de implementações ou avanço para P1.5.

## Objetivo e autoridade

Responder quais códigos de **procedimento realizado** (`proc_rea`) concentram as maiores quantidades de **internações administrativas novas** processadas em atendimentos na PB, no período de competências 201701–201912, e qual a participação de cada código no universo de 555.089 internações. Início autorizado pelo responsável depois de revisão e merge do P1.3; a ausência de CSV acessível impede validação numérica nesta sessão.

O contrato acadêmico e a ordem do Boundary 7 não mudam. PRESERVAR: QlikView 12; fluxo BASE→EXTRACAO→QVD→TRANSFORMACAO→QVD→PAINEL; três fatos e oito dimensões; A0 padrão; nenhuma aprovação de Link Key/medidas globais/Fase IX/produção.

## Insumo E2 esperado — somente referência documental

- **Nome:** `sih_procedimento_competencia.csv` (E2).
- **SHA-256 de referência AE01:** `81FCBD576EFE48560EE1666A443E3E73158179972E38241A48928C904D03B6A2`.
- **Grão/documentação:** competência × procedimento realizado (`proc_rea`); `ano` redundante com competência.
- **Schema esperado (ordem):** `competencia;ano;proc_rea;qtd_registro_aih;qtd_internacao;qtd_continuidade`.
- **Grupos documentados:** 21.031; **competências esperadas:** 36, de 201701 a 201912.
- **Controles independentes do ranking (não resultados de P1.4):** 2017=183.532; 2018=183.311; 2019=188.246; total `qtd_internacao`=555.089; registros=566.672; continuidades=11.583.
- **Números exploratórios secundários, ainda NÃO validados nesta execução:** `proc_rea 0310010039 = 55.157` e Top 10 ~40,65%. Não presumir nomes, hierarquias ou vigência SIGTAP.

## Estado de acesso ao dado físico

O E2 **não** está anexado neste contexto, não foi encontrado na Library/arquivos do Projeto, Google Drive conectado nem na árvore da `main` (datasets não são versionados). O E1 havia sido encontrado pelo operador em `C:\Users\pedro\SAD_EVIDENCIAS\AE01_20261027_02\sih_fluxo_competencia.csv`. **Hipótese operacional**, não confirmação: E2 pode estar nessa mesma pasta. Não procurar ou acessar Windows sem ferramenta/permissão; solicitar apenas o E2 físico, sem reextração.

## Execução condicionada à chegada do E2

1. Confirmar existência, tamanho, SHA-256 e esquema exato do arquivo realmente acessível.
2. Validar tipos não negativos, `qtd_registro_aih=qtd_internacao+qtd_continuidade` em cada grupo, unicidade competência×`proc_rea`, `ano` coerente, 36 competências e campos `proc_rea` não vazios.
3. Agrupar `SUM(qtd_internacao)` por `proc_rea` e ordenar contagem desc + código como desempate. Mostrar Top 10, demais códigos, total e participação (denominador 555.089), sem omissão. Se houver códigos vazios/inválidos, documentar e HARD_STOP conforme integridade.
4. Reconciliar anos, registros, continuidades e total; calcular soma das participações a partir de contagens exatas (diferença possível na soma de percentuais arredondados).
5. Confrontar somente como controle secundário os dois números exploratórios; não ajustar dados para coincidir.
6. Se for necessário novo validador para PASS, commitá-lo em branch **antes** de executar, usando o AE01 existente para reaproveitar controles. Evidências CSV/JSON/log/hash permanecem fora do Git. Não usar experimento descartável para homologação.

**PASS restrito:** E2 físico com SHA igual ao AE01, 36 competências, nenhuma duplicidade/omissão/erro, totais e agregação fechados, auditor executado a partir de script versionado; não implica QlikView/UX/produção.  
**BLOCKED:** fonte não acessível/schema incompatível.  
**FAIL/HARD_STOP:** divergência de integridade, período, total, controles ou contagens inexplicada.  
**INCONCLUSIVE:** ranking calculável sem provas suficientes para homologação.  

**STOP atual:** arquivo E2 não acessível nesta sessão. Sem resultado numérico novo nem execução P1.4. Próxima ação única: disponibilizar `sih_procedimento_competencia.csv` original da exportação AE01; retomar o mesmo gate sem gerar dados novos.
