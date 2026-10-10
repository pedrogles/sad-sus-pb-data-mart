# Fase VI — Discovery READ-ONLY do contrato `%LINK_KEY` multífato

**Data:** 10/10/2026  
**Escopo:** SIH/RD + CNES/LT + IBGE/população para PB, 2017–2019  
**Situação:** `R1_DATA_PROFILE_VERIFIED_SCRIPT_BLOCKED_R2_PREPARED_NOT_RUN`  
**Trilha:** Draft PR #83 / `feat/phase-5-fato-internacao-contract-discovery`

Nenhum QVD factual, `LINK_ANALISE.qvd`, `PAINEL.qvw` ou contrato final foi criado ou aprovado por este documento.

## 1. Fontes verificadas e decisões preservadas

**FATO VERIFICADO (repositório canônico):**

- `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`; Capítulos 1–2 acadêmicos permanecem fechados.
- `docs/discovery/boundary-6-qlikview-physical-architecture.md`, §§5–10, 13 e 22.5–22.6: as três fatos se conectam à `LINK_ANALISE` exclusivamente por `%LINK_KEY`; cinco coordenadas; aliases role-playing e ausência de $Syn/loops serão testados depois.
- `docs/discovery/boundary-7-implementation-plan.md`, §22: origem de cada coordenada, residência nula na capacidade, competência e estabelecimento nulos na população, deduplicação de combinações.
- `EXTRACAO/ext_main.qvs`: `EXTRACAO/QVD/SRC_SIH_RD.qvd`, `SRC_CNES_LT.qvd`, `SRC_IBGE_POPULACAO.qvd`. **O nome correto é `SRC_IBGE_POPULACAO.qvd`.**
- `TRANSFORMACAO/transf_dim_municipio.qvs`: `DIM_MUNICIPIO` contém `COD_IBGE_7`, `COD_DATASUS_6` e `%SK_MUNICIPIO`; apenas 223 municípios PB recebem o `COD_IBGE_7`, derivado dos dados oficiais com a regra validada no projeto. Os 714 códigos externos da RD não recebem associação IBGE7 inventada.
- `TRANSFORMACAO/transf_dim_estabelecimento.qvs`: `%SK_ESTABELECIMENTO = Hash128('ESTAB', CNES, COMPETENCIA)` por versão mensal.
- Resultado anterior: `FATO_INTERNACAO` — chave técnica de registro aprovada com restrições; cinco medidas CSV/QVD reconciliadas; 11 papéis dimensionais sem órfãos em duas recargas R3. Não inferir disso aprovação da Link Table.

## 2. Matriz física de coordenadas (contrato aprovado; serialização candidata)

| Coordenada em LINK_ANALISE | RD (566.672) | LT (35.518) | IBGE POP (669) |
| --- | --- | --- | --- |
| `%SK_TEMPO_COMPETENCIA` | `_META_SOURCE_COMPETENCE` → `Hash128('MES', Text(Date(Date#(...,'YYYYMM'),'YYYYMM')))` | mesmo campo e expressão, com `COMPETEN` inspecionado na extração | **Null()** (não aplicável) |
| `%SK_TEMPO_ANO` | `ANO_CMPT` → `Hash128('ANO',Num#(...))` | ano de `_META_SOURCE_COMPETENCE` → `Hash128('ANO',Num#(...))` | `ANO_REFERENCIA` → `Hash128('ANO',Num#(...))` |
| `%SK_MUNICIPIO_RESIDENCIA` | `MUNIC_RES` → `Hash128('MUN', DATASUS6)` | **Null()** (não aplicável) | `COD_IBGE_7` → `DIM_MUNICIPIO.%SK_MUNICIPIO` |
| `%SK_MUNICIPIO_SERVICO` | `MUNIC_MOV` → `Hash128('MUN', DATASUS6)` | `CODUFMUN` do **próprio LT** → `Hash128('MUN',DATASUS6)` | mesma SK da população no papel serviço |
| `%SK_ESTABELECIMENTO` | `CNES` + `_META_SOURCE_COMPETENCE` | `CNES` + `_META_SOURCE_COMPETENCE` | **Null()** (não aplicável) |

**FATO VERIFICADO:** o LT de extração possui `CODUFMUN`, portanto não é necessário adotar join ST→LT para descobrir o município de serviço nesta etapa. As 35.518 linhas LT e as 669 linhas populacionais são expectativas de staging documentadas, **não novas inspeções binárias QVD nesta execução**. A granularidade do LT continua `CNES × COMPETEN × CODLEITO`; a tabela população é `COD_IBGE_7 × ANO_REFERENCIA`.

**DECISÃO PENDENTE:** compatibilidade exata das cinco SKs para **todos** os registros LT/POP — ainda não há reload físico da candidata. A ponte de código de população usa `DIM_MUNICIPIO` versionada; **não** truncar o código IBGE7 diretamente como regra nova de fato.

## 3. HIPÓTESE DE IMPLEMENTAÇÃO — serializador versionado `SAD-LINK-V1`

O Boundary 7 traz um **exemplo conceitual**, não a fórmula final. O preflight desta Discovery avalia um candidato determinístico e tipado com a ordem fixa:

```text
COMP, ANO, MUN_RES, MUN_SERV, ESTAB
```

Cada coordenada já é uma SK de dimensão. Antes de aplicar `Hash128`:

- `Null()` verdadeiro é serializado como token `N` **somente para o papel não aplicável**;
- uma SK presente é serializada como `V` + comprimento do texto + `:` + `Text(SK)`, por exemplo, uma SK de 32 caracteres terá token `V32:<hash>`;
- cada token possui etiqueta de coordenada `C=`, `Y=`, `R=`, `S=`, `E=`; os argumentos do `Hash128` são separados, em ordem fixa, com primeiro argumento `SAD-LINK-V1`.

Assim, nulo e texto vazio não se confundem **dentro da hipótese de serialização**. A versão `V1` define apenas *candidato*. Alterar a ordem, os prefixos, a conversão de SKs ou os nulos altera todas as chaves; antes de qualquer produção, o contrato deve ser aprovado para os **três processos**.

A tag de processo (`RD`, `LT`, `POP`) serve apenas para diagnóstico por origem, **não** faz parte do hash compartilhado. Não incluir medidas nem dimensões exclusivas na chave. Eventuais colisões de hashes são detectáveis nos valores realmente observados comparando `Count(DISTINCT SERIAL)` com `Count(DISTINCT HASH)` (não é prova matemática absoluta para todos os dados futuros).

## 4. Preflight QlikView 12 somente leitura — preparado, NÃO EXECUTADO

**Arquivos versionados no Draft PR #83:**

- `TRANSFORMACAO/phase_vi_link_key_cross_fact_preflight.qvs` — leitura de **seis** QVDs, mapas em memória, união **temporária** das três fontes para conferir os 602.859 registros originais, serialização em memória (não publicada), contagens individuais e distintas. `CONCATENATE` aqui é exclusivamente o método de construir a população de teste, **não a arquitetura da Data Mart**.
- `tools/validar_link_key_cross_fact_qlik.ps1` — executor COM que cria somente `TRANSFORMACAO/P6_LINK_KEY_CROSS_FACT_PREFLIGHT.qvw`; confere os SHA-256 dos seis QVDs de entrada antes/depois, log nativo e totais por processo; não sobrescreve `TRANSF.qvw` nem escreve CSV/QVD.

**Gates objetivos de teste (hipóteses a validar):**

1. `RD=566672`, `LT=35518`, `POP=669`, total `602859`: nenhuma linha duplicada, eliminada ou descartada pela serialização;
2. todas as cinco coordenadas obrigatórias de cada processo não nulas, suas SKs existentes nos mapas dimensionais, e **null real somente nos papéis não aplicáveis**;
3. `BAD_COORD=0`, `NULL_KEY=0`, `DISTINCT_SERIAL=DISTINCT_HASH` e ao menos uma combinação distinta; se não passar, **BLOCKED**, não corrigir fonte/dimensão silenciosamente;
4. hashes SHA-256 dos seis QVDs de entrada inalterados, `FACT_QVD_GENERATED=False`, `LINK_ANALISE_QVD_GENERATED=False`;
5. veredito do script `PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED`, mesmo quando passar, **não** aprova serialização final, a Link Table nem as análises associativas do painel.

**Riscos e escopo não coberto:** não testa persistência/reload independente da `%LINK_KEY` entre fatos/QVDs, tabela `LINK_ANALISE` final deduplicada, relações role-playing em painéis, circular references ou $Syn. Também não valida agregação cruzada com leitos/população nem o problema semântico de usar simultaneamente eixos de residência e serviço. Tudo isso permanece um gate posterior.

## 5. Próxima decisão após a execução

Se houver **PASS experimental**, revisar a evidência linha a linha, decidir se a serialização candidata precisa de teste de estabilidade entre reloads (como feito com a SK RD), e submeter aprovação física explícita antes de qualquer script factual. Se houver `BLOCKED`, diagnosticar a fonte, o papel ou o token sem descartar linhas e sem substituir nulos reais por sentinelas nos campos dimensionais.

**Estado final desta Discovery:** `LINK_KEY_SERIALIZER=HYPOTHESIS_PREPARED_NOT_RUN`; `THREE_FACT_STAGING_COMPATIBILITY=NOT_TESTED`; `LINK_ANALISE=NOT_STARTED`; `FACT_QVDS=NOT_STARTED`; `PAINEL=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. A Discovery e scripts ainda pertencem a PR **Draft / sem merge**.

## 6. Primeiro teste físico R1 — números OK, Qlik parser e $Syn bloqueados (10/10/2026 00:36:40)

**FATO VERIFICADO a partir da saída nativa QlikView 12 entregue pelo responsável:** depois de `git pull --ff-only` até `3f47d04`, criou-se `TRANSFORMACAO/P6_LINK_KEY_CROSS_FACT_PREFLIGHT.qvw` (`DOCUMENT_REUSED=False`) a partir do script SHA-256 `A53796B65EF75C1219EE95543F4FA193411760BA91A1FCB08BD45EC2F0FFD42A`. O Qlik carregou os seis QVDs e calculou, em 00:36:40:

```text
PROCESS=RD ROWS=566672 BAD_COORD=0
PROCESS=LT ROWS=35518 BAD_COORD=0
PROCESS=POP ROWS=669 BAD_COORD=0
TOTAL ROWS=602859 RD=566672 LT=35518 POP=669 BAD_COORD=0 NULL_KEY=0 DISTINCT_SERIAL=85705 DISTINCT_HASH=85705
ALL_6_INPUT_QVD_SHA256_UNCHANGED=True
FACT_QVD_GENERATED=False
OUTPUT_DATA_FILES_WRITTEN=0
```

**Os controles quantitativos e os dados foram lidos corretamente, MAS R1 não recebeu PASS.** O QlikView emitiu dois problemas de script, demonstrados no log nativo:

```text
0182 IF 602859<>602859 OR 566672<>566672 OR 35518<>35518
0183 Erro: Erro na linha do script:
0183 OR 669<>669 OR 0<>0 OR 0<>0
0184 OR 0<>0 OR 85705<>85705 THEN
0185 TRACE [P6-LINK] VERDICT=BLOCKED_CROSS_FACT_LINK_CONTRACT
Erro: Comando desconhecido
$Syn 1 = _P6_PROC+_P6_BAD_COORD
```

**Causas técnicas comprovadas nos arquivos versionados:**

1. A cláusula `IF` do gate final estava quebrada em três linhas de comando, inválida para o parser de script QlikView Desktop 12.0.20000.0.
2. `P6_TYPED` e `P6_LINK_TEST` compartilhavam **dois** nomes de campos, `_P6_PROC` e `_P6_BAD_COORD`, provocando a synthetic key `$Syn 1`. A chave sintética foi gerada **no modelo temporário do preflight**, não na Link Table final (ainda inexistente).

**Correção mínima R2 versionada exclusivamente na branch do PR #83, ainda NÃO EXECUTADA:**

- Em `TRANSFORMACAO/phase_vi_link_key_cross_fact_preflight.qvs`, o `P6_LINK_TEST` passa a projetar `_P6_LINK_PROC` e `_P6_LINK_BAD_COORD` (aliases exclusivos), com agregações redirecionadas aos novos nomes; a semântica das cinco coordenadas, dos nulos tipados e do `Hash128('SAD-LINK-V1',...)` foi **preservada sem mudança**.
- O `IF` de aceite passou a ser uma única linha de script, mantendo **todos** os critérios e seus valores originais.
- Um gate adicional examina as tabelas do QlikView por `$Syn*`, imprime `[P6-LINK] SYNTHETIC_TABLES=N` e **bloqueia** quando `N > 0`. Portanto, não basta a igualdade dos 85.705 valores distintos nem os seis QVDs imutáveis.
- `tools/validar_link_key_cross_fact_qlik.ps1` agora cria somente `TRANSFORMACAO/P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw`, preservando QVW e log R1. O runner exige `SYNTHETIC_TABLES=0` antes de aceitar o veredito experimental; continua sem gravar QVDs, CSVs ou fatos.

**DECISÃO PENDENTE:** executar fisicamente o R2 e inspecionar `VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED`, `SYNTHETIC_TABLES=0`, `BAD_COORD=NULL_KEY=0`, cobertura total RD/LT/POP e `DISTINCT_SERIAL=DISTINCT_HASH`. Até lá: `LINK_KEY_R1=SCRIPT_BLOCKED`, `LINK_KEY_R2=PREPARED_NOT_RUN`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED`, `FACT_QVD=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`.

O resultado `85.705` é o número de coordenadas compartilhadas distintas observado em memória na R1; **não** representa 85.705 internações, leitos ou municípios e ainda não equivale a cardinalidade física validada em uma `LINK_ANALISE` persistida.

## 7. R2 — PASS experimental físico das três fontes (10/10/2026 00:41:26)

**FATO VERIFICADO (saída real de PowerShell e QlikView Desktop 12 fornecida pelo responsável):** após `git pull --ff-only` que avançou a branch de `3f47d04` para `36ec322`, o executor `tools/validar_link_key_cross_fact_qlik.ps1` criou o QVW isolado `TRANSFORMACAO/P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw` (`DOCUMENT_REUSED=False`) com o script SHA-256 `41A54899536494CC08B7C3B170344D09D86E30D4C182E7D59B6F9CD7CFACC859`.

```text
MODE=PHASE_VI_LINK_KEY_CROSS_FACT_READ_ONLY
RELOAD_STARTED=True
RELOAD_RETURNED=True
ALL_6_INPUT_QVD_SHA256_UNCHANGED=True
[P6-LINK] PROCESS=RD ROWS=566672 BAD_COORD=0
[P6-LINK] PROCESS=LT ROWS=35518 BAD_COORD=0
[P6-LINK] PROCESS=POP ROWS=669 BAD_COORD=0
[P6-LINK] TOTAL ROWS=602859 RD=566672 LT=35518 POP=669 BAD_COORD=0 NULL_KEY=0 DISTINCT_SERIAL=85705 DISTINCT_HASH=85705
[P6-LINK] SYNTHETIC_TABLES=0
[P6-LINK] VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED
[P6-LINK] FACT_QVD_GENERATED=False LINK_ANALISE_QVD_GENERATED=False OUTPUT_DATA_FILES_WRITTEN=0
[P6-LINK] PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED LINK_KEY_CONTRACT=NOT_APPROVED
VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED
LINK_KEY_CONTRACT=NOT_APPROVED
PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED
FACT_QVD_GENERATED=False
LINK_ANALISE_QVD_GENERATED=False
```

**Conclusão estrita de R2:** os três processos mantiveram o grão original e tiveram cobertura completa das coordenadas obrigatórias no teste em memória (`BAD_COORD=0`); o serializador candidato `SAD-LINK-V1` gerou chaves não nulas em todas as **602.859 linhas**; foram observadas **85.705 serializações distintas e 85.705 hashes distintos** no snapshot validado. Essa igualdade é evidência favorável de ausência de colisões **detectáveis no conjunto examinado**, não garantia matemática para dados futuros. O QlikView apresentou `SYNTHETIC_TABLES=0` no documento isolado e os seis QVDs de entrada não tiveram mudança de SHA-256. **Nenhuma Link Table física, fato ou painel foi criado.**

**O defeito QVS R1 foi corrigido no ambiente de preflight:** condição `IF` passou a ser executada integralmente, e os aliases de `P6_LINK_TEST` evitaram a chave sintética anterior. A contagem de `85.705` representa **combinações distintas de coordenadas**, não 85.705 municípios, internações, pacientes, hospitais, leitos ou linhas de uma Link Table física.

**DECISÃO PENDENTE:** a saída não estabelece ainda determinismo de identidade de todas as 85.705 chaves em recargas independentes. A próxima reprodução segura é recarregar o **mesmo QVW R2 já criado**, sem alterar QVS, exigindo `DOCUMENT_REUSED=True`, seis hashes SHA-256 preservados, todos os contadores e `SYNTHETIC_TABLES=0`, e o mesmo veredito. Mesmo duas recargas com os mesmos totais **não provam igualdade exata dos conjuntos de chaves**: eventual teste posterior de conjuntos/fingerprints ordenados deverá ser desenhado explicitamente, se o contrato for promovido. `LINK_KEY_CONTRACT=NOT_APPROVED`; `ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED`; `FACT_QVD=NOT_STARTED`; `LINK_ANALISE=NOT_STARTED`; `PAINEL=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. Draft PR #83 permanece sem merge.

## 8. R2 — segunda recarga: perfil reproduzido em 10/10/2026 00:44:00

**FATO VERIFICADO pela nova execução QlikView Desktop 12 enviada pelo responsável:** depois de `git pull --ff-only` da branch do Draft PR #83 até `33e8608`, o mesmo runner `tools/validar_link_key_cross_fact_qlik.ps1` reutilizou o mesmo `TRANSFORMACAO/P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw` (`DOCUMENT_REUSED=True`) e mesmo QVS de SHA-256 `41A54899536494CC08B7C3B170344D09D86E30D4C182E7D59B6F9CD7CFACC859`, mantendo os seis QVDs SHA-256 inalterados.

```text
2026-10-10 00:44:00 [P6-LINK] PROCESS=RD ROWS=566672 BAD_COORD=0
2026-10-10 00:44:00 [P6-LINK] PROCESS=LT ROWS=35518 BAD_COORD=0
2026-10-10 00:44:00 [P6-LINK] PROCESS=POP ROWS=669 BAD_COORD=0
2026-10-10 00:44:00 [P6-LINK] TOTAL ROWS=602859 RD=566672 LT=35518 POP=669 BAD_COORD=0 NULL_KEY=0 DISTINCT_SERIAL=85705 DISTINCT_HASH=85705
2026-10-10 00:44:00 [P6-LINK] SYNTHETIC_TABLES=0
2026-10-10 00:44:00 [P6-LINK] VERDICT=PASS_EXPERIMENTAL_LINK_SERIALIZATION_COVERAGE_NOT_APPROVED
2026-10-10 00:44:00 [P6-LINK] FACT_QVD_GENERATED=False LINK_ANALISE_QVD_GENERATED=False OUTPUT_DATA_FILES_WRITTEN=0
2026-10-10 00:44:00 [P6-LINK] PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED LINK_KEY_CONTRACT=NOT_APPROVED
```

**Interpretação:** perfis, hashes SHA-256 de entradas, total de 602.859 linhas, 85.705 combinações únicas e ausência de synthetic keys no **preflight isolado** foram reproduzidos em duas recargas sucessivas (00:41:26 e 00:44:00). Não houve criação de `LINK_ANALISE.qvd`, fato, painel ou associação física das três fatos. Igualdade entre quantidades distintas **não** prova igualdade exata entre **conjuntos de 85.705 valores de chave**.

## 9. Próximo gate preparado — igualdade exata do conjunto de hashes entre duas recargas

**HIPÓTESE DE IMPLEMENTAÇÃO para diagnóstico read-only (sem aprovação de contrato):**

- `tools/validar_estabilidade_link_key_cross_fact.ps1`: reutiliza a metodologia de `tools/validar_estabilidade_sk_fato_internacao.ps1` aprovada anteriormente na Fase V. Compara primeiro a identidade exata do QVS versionado com o QVW original R2 já validado; computa SHA-256 dos seis QVDs e arquivos versionados.
- Cria **um QVW isolado sob `%TEMP%`** e adapta somente os seis caminhos dos QVDs para endereços absolutos, porque um QVW temporário não reside na pasta `TRANSFORMACAO`.
- Injeta **apenas no QVW temporário** a instrução `STORE _P6_HASH FROM P6_LINK_TEST INTO [arquivo-txt-temporário] (txt)`, depois dos gates existentes (coordenadas, valores nulos, 85.705 distintos e zero `$Syn`). Esta exportação de **hashes não identificáveis diretamente** é temporária e não grava QVD nem altera o QVS versionado ou o QVW R2 original.
- Executa **duas recargas independentes**, fechando/reabrindo o QVW de teste e exigindo em ambas os mesmos controles validados do R2, `[P6-EXACT] EXPORT_COMPLETE` e arquivo exportado contemporâneo.
- `tools/comparar_conjuntos_link_key_qlik.py` usa exclusivamente Python 3 stdlib e compara **conjuntos completos** das chaves Qlik exportadas; valida 602.859 linhas/85.705 chaves distintas por arquivo, calcula SHA-256 canônico dos 85.705 hashes ordenados, e apresenta `ONLY_A_KEYS` e `ONLY_B_KEYS`.
- No PASS, o PowerShell confere novamente todos os SHA-256 do QVW R2, QVS original, comparador Python e seis QVDs, anuncia `VERDICT=PASS_2_RELOADS_EXACT_85705_LINK_KEY_SET_MATCH_NOT_APPROVED` e **remove os arquivos temporários**. Em falha, retém o diretório em `%TEMP%` para diagnóstico, sem tocar fontes. O runner requer `.venv\\Scripts\\python.exe`, padrão já utilizado no gate de estabilidade da SK do registro.

**Restrições do gate:** comparação exata de **hashes existentes**, não de todas as coordenadas/serializações textuais; preservação dos seis QVDs é condição necessária. O resultado não valida sozinho uma `LINK_ANALISE` persistida, aliases role-playing ou ausência de loops no modelo final, tampouco elimina a necessidade de aprovar o contrato `SAD-LINK-V1` para os três processos conjuntamente.

**Estado:** `LINK_KEY_EXPERIMENTAL_R2_PROFILE=PASS_REPRODUCED`, `LINK_KEY_EXACT_SET_AUDIT=PREPARED_NOT_EXECUTED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED`, `FACT_QVDS=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`. Sem merge do PR #83.

