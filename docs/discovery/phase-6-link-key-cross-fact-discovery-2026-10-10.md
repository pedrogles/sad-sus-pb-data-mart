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

## 10. Auditoria de conjunto exato — duas recargas Qlik PASS, exportação/comparador BLOCKED (13/10/2026)

**FATO VERIFICADO (stdout de execução entregue pelo responsável, 13/10/2026):** `tools/validar_estabilidade_link_key_cross_fact.ps1` usando os scripts versionados gerou **somente artefatos em `%TEMP%`**, abriu o QVW isolado e completou **duas recargas independentes** com `RUN_1_PROFILE_PASS=True`, `RUN_2_PROFILE_PASS=True`. Cada `STORE _P6_HASH ... (txt)` temporário produziu **16.277.206 bytes** e foi preservado em `run_a.txt` e `run_b.txt`.

```text
MODE=PHASE_VI_LINK_KEY_EXACT_SET_TWO_INDEPENDENT_RELOADS
ORIGINAL_QVW_MODIFIED=False
ONLY_TEMPORARY_HASH_EXPORTS=True
FACT_QVD_GENERATED=False
LINK_ANALISE_QVD_GENERATED=False
RUN_1_RELOAD_STARTED=True
RUN_1_RELOAD_RETURNED=True
RUN_1_PROFILE_PASS=True
RUN_1_EXPORTED_HASH_BYTES=16277206
RUN_2_RELOAD_STARTED=True
RUN_2_RELOAD_RETURNED=True
RUN_2_PROFILE_PASS=True
RUN_2_EXPORTED_HASH_BYTES=16277206
VERDICT=BLOCKED_LINK_KEY_COMPARATOR_ValueError: run_a.txt: rows=602859 unique=1; expected=602859/85705
VERDICT=FAIL_CLOSED_Comparacao exata Python bloqueou
TEMP_DIAGNOSTIC_DIR_RETAINED=C:\Users\pedro\AppData\Local\Temp\SAD_P6_LINK_EXACT_542214a38f724297a3f7193578c0b454
```

**Significado estrito da divergência:** no QlikView nativo, o perfil de `P6_LINK_TEST` durante cada recarga passou no gate que exige `DISTINCT_SERIAL=85705` e `DISTINCT_HASH=85705`. Entretanto, o comparador Python decodificou **602.859 linhas válidas quanto ao formato, mas apenas um valor distinto** no **arquivo A exportado em TXT**. Portanto, **não** afirmar que houve colisão das 85.705 chaves Qlik nem declarar PASS de conjunto exato. Precisamos verificar se o conteúdo bruto do TXT já contém um único hash, ou se a discrepância é de formatação/serialização/leitura. O erro `unique=1` aponta para a etapa de **exportação ou leitura**, não determina qual componente a causou.

**Qualidade do gate:** o PowerShell iniciou a proteção SHA-256 dos seis QVDs, do QVW R2 e dos scripts antes das recargas, mas o erro no comparador interrompeu a execução **antes da verificação posterior de hashes**; logo, a execução atual **não** confirmou `ALL_6_INPUT_QVD_SHA256_UNCHANGED=True`. Esta verificação passou em duas recargas R2 anteriores, mas não deve ser atribuída silenciosamente ao gate que falhou. Nenhum QVD factual ou `LINK_ANALISE.qvd` foi gerado segundo o executor.

**Próximo passo estritamente READ-ONLY:** inspecionar as primeiras linhas de `run_a.txt` e `run_b.txt`, quantidades distintas no texto bruto (sem transformação), tamanhos de linha e possíveis aspas/caracteres delimitadores, e comparar os dois arquivos sob o diretório temporário retido. **Não alterar `Hash128('SAD-LINK-V1',...)`, regra de nulos, QVDs, QVW R2 ou comparador para forçar PASS sem a evidência de TXT.** Em seguida, isolar e versionar uma correção mínima se necessário, repetindo a auditoria em novo diretório temporário. O registro operacional é `EXACT_KEY_SET_AUDIT=BLOCKED_EXPORT_OR_PARSE_UNDER_INVESTIGATION`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED`, `FACT_QVD=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`. PR #83 mantém Draft e `main` intocada.

## 11. Inspeção direta de TXT retidos — valores realmente repetidos (13/10/2026)

**FATO VERIFICADO** pela inspeção local read-only entregue pelo responsável usando Python 3 `Counter` sobre as duas exportações temporárias retidas. Após a remoção apenas de terminadores de linha e cabeçalho, os dois arquivos apresentaram **exatamente o mesmo valor textual bruto repetido 602.859 vezes**:

```text
ARQUIVO=run_a.txt
LINHAS=602859
VALORES_BRUTOS_DISTINTOS=1
TAMANHOS=[(25, 602859)]
PRIMEIRAS_3=['\'"HC.(+#&,>/;""QU[6LNCG`+"\'', ...]  # amostra anonimizada por conveniência
SHA256_ARQUIVO=3431afdaf4e1b241f8a3d4d6ec05df7d4c60009e784fec058aa1b1ac647175ef

ARQUIVO=run_b.txt
LINHAS=602859
VALORES_BRUTOS_DISTINTOS=1
TAMANHOS=[(25, 602859)]
SHA256_ARQUIVO=3431afdaf4e1b241f8a3d4d6ec05df7d4c60009e784fec058aa1b1ac647175ef
```

O mesmo conteúdo está presente na primeira linha, na linha central e em todas as outras; as aspas internas aparecem duplicadas, conforme escape habitual de CSV. **Esta evidência elimina a hipótese de que o comparador Python tenha transformado 85.705 valores textuais distintos em um único valor por erro de parsing.** O arquivo TXT, tal como escrito, contém somente um valor textual. O QlikView, entretanto, reportou **85.705 `Count(DISTINCT _P6_HASH)`** em cada recarga antes de `STORE`. A causa técnica desta divergência **continua não demonstrada**: pode envolver como valores de `Hash128` são representados/convertidos na exportação `STORE ... (txt)`, mas não há prova suficiente para afirmar um bug específico do QlikView.

**Referência de documentação oficial QlikView:** `Hash128()` deve produzir texto de 22 caracteres; `STORE ... (txt)` produz CSV com caracteres escapados (fonte: QlikView Help, função Hash128 e comando STORE). A amostra bruta de 25 caracteres inclui aspas externas e escape de aspas internas; o fato crítico é **a repetição de um único valor**, não o comprimento bruto da linha. A equalidade de SHA-256 dos arquivos demonstra identidade dos **TXT incorretamente empobrecidos**, não identidade das 85.705 chaves em memória.

**DECISÃO PENDENTE / próximo diagnóstico:** sem tocar `SAD-LINK-V1` nem nos QVDs, executar um **probe Qlik isolado** que meça `Count(DISTINCT _P6_HASH)`, `Count(DISTINCT Text(_P6_HASH))` e `Count(DISTINCT _P6_SERIAL)` no mesmo subconjunto, exportando lado a lado hash original, `Text(hash)` e serialização bruta em TXT temporário. Se houver divergência entre campos antes da exportação, separar problema de conversão/dualidade de eventual problema no `STORE`. **Nenhuma substituição de algoritmo ou normalização do hash será aprovada com base apenas na amostra.** O comparador original permanece fail-closed e os antigos `run_a.txt`/`run_b.txt` não devem ser apagados enquanto a causa é investigada.

**Estado:** `RAW_TXT_DISTINCT=1` **confirmado**, `QV_IN_MEMORY_DISTINCT=85705` confirmado em gate do preflight, `EXACT_KEY_SET_AUDIT=BLOCKED_OUTPUT_REPRESENTATION`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED`, `FACT_QVD=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`.

## 12. Probe Qlik isolado de tipagem/STORE TXT — preparado, NÃO EXECUTADO (13/10/2026)

**Script de observabilidade versionado:** `tools/diagnosticar_link_key_txt_export_qlik.ps1` — **não modifica** `TRANSFORMACAO/phase_vi_link_key_cross_fact_preflight.qvs`, `TRANSFORMACAO/P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw`, nenhum dos **seis** QVDs existentes, fatos ou `LINK_ANALISE`. Segue o mesmo padrão QlikView COM + `%TEMP%`: confere identidade do QVS e QVW R2, cria um QVW isolado, substitui as seis referências de leitura por caminhos absolutos temporariamente e injeta um bloco diagnóstico exclusivamente antes dos `DROP TABLE` no documento temporário.

**Medições previstas em uma única recarga física:**

1. Sobre **todas as 602.859 linhas em memória**: `Count(DISTINCT _P6_HASH)`, `Count(DISTINCT Text(_P6_HASH))` e `Count(DISTINCT _P6_SERIAL)`. Exigir linha-base Qlik `602859 / 85705 / 85705` para total/hash/serial; registrar separadamente o total do cast textual sem presumir resultado.
2. Sobre uma amostra de **até 5.000 registros** via `FIRST 5000 LOAD ... RESIDENT P6_LINK_TEST`: medir distintas de hash direto, `Text(hash)` e serialização; exportar em TXT temporário **três colunas distintas** (`_P6_TXT_DIRECT`, `_P6_TXT_CAST`, `_P6_TXT_SERIAL`) lado a lado.
3. Interpretar somente o **TXT de amostra** com Python 3 `csv.reader`, reportando contagem de linhas e valores distintos de cada coluna, comprimentos, pequenas amostras de hashes, SHA-256 do TXT, sem publicar serializações individuais com códigos pessoais.
4. Guardar no log Qlik os contadores nativos antes da exportação, exigir conclusão do `STORE`, preservar SHA-256 do QVW R2, QVS e seis QVDs; excluir o probe temporário após captura bem-sucedida e **reter o arquivo temporário em caso de erro**.

**Motivação:** os TXT originais `run_a.txt`/`run_b.txt` têm somente um valor literal repetido, mas os perfis Qlik de `P6_LINK_TEST` afirmam 85.705 valores distintos. A comparação em paralelo permitirá diferenciar a representação `Text(_P6_HASH)` da leitura do mesmo campo pelo `STORE`, antes de decidir a correção mínima. Se `Text(_P6_HASH)` já tiver apenas um valor no Qlik, o foco será **dualidade/representação**; se `Text(_P6_HASH)` mantiver 85.705, mas a coluna TXT for constante, o foco será a **projeção/escrita CSV**. Trata-se apenas de plano condicional, **não de causa demonstrada**.

**Status:** `TXT_EXPORT_ROOT_CAUSE=NOT_CONFIRMED`, `P6_TEXT_PROBE=PREPARED_NOT_RUN`, `EXACT_KEY_SET_AUDIT=BLOCKED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `ROLEPLAY_ASSOCIATIVE_MODEL=NOT_TESTED`, `FACT_QVDS=NOT_STARTED`, `LINK_ANALISE=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`. Preservar arquivos retidos da falha anterior até a revisão do diagnóstico. A instrução `STORE` do novo probe é exclusivamente **temporária e amostral**, e não representa implementação do Data Mart.

## 13. Probe nativo/TXT concluído — 5.000 linhas e 801 valores distintos (13/10/2026 09:30:43)

**FATO VERIFICADO — QlikView Desktop 12 / PowerShell local**, após `git pull --ff-only` até `e3f4918`. O diagnóstico `tools/diagnosticar_link_key_txt_export_qlik.ps1` executou em QVW sob `%TEMP%`, sem alterar o QVS nem o QVW original:

```text
MODE=PHASE_VI_HASH128_TXT_STORE_DIAGNOSTIC_READ_ONLY
[P6-TXT] IN_MEMORY ROWS=602859 DISTINCT_HASH=85705 DISTINCT_TEXT_CAST=85705 DISTINCT_SERIAL=85705
[P6-TXT] SAMPLE ROWS=5000 DISTINCT_HASH=801 DISTINCT_TEXT_CAST=801 DISTINCT_SERIAL=801
[P6-TXT] TXT_SAMPLE_EXPORT_COMPLETE
TXT_SAMPLE_SHA256=ed9ca47582953f6678562f4f0f419ffe93acefd7f5c323c97181aa97f022c7a5
TXT_HEADER=['_P6_TXT_DIRECT', '_P6_TXT_CAST', '_P6_TXT_SERIAL']
TXT_ROWS=5000
TXT_DIRECT_HASH_UNIQUE=801
TXT_DIRECT_HASH_LENGTHS=[(22, 5000)]
TXT_TEXT_CAST_UNIQUE=801
TXT_TEXT_CAST_LENGTHS=[(22, 5000)]
TXT_SERIAL_UNIQUE=801
TXT_SERIAL_LENGTHS=[(156, 5000)]
ALL_6_INPUT_QVD_SHA256_UNCHANGED=True
SOURCE_R2_QVW_SHA256_UNCHANGED=True
SOURCE_QVS_SHA256_UNCHANGED=True
VERDICT=DIAGNOSTIC_CAPTURED_EXPORT_HASH_BEHAVIOR_NOT_LINK_APPROVED
LINK_KEY_CONTRACT=NOT_APPROVED
TEMPORARY_SAMPLE_REMOVED=True
```

**Conclusão estrita:** `Hash128('SAD-LINK-V1',...)` retornou 85.705 hashes distintos em memória; `Text(_P6_HASH)` também teve 85.705, logo não houve colapso de diversidade pela função `Text()` nesta execução. A amostra `FIRST 5000` possuía 801 valores distintos tanto em QlikView quanto nas **três colunas exportadas** `STORE ... (txt)`, validando esta projeção amostral e a leitura CSV para hashes de 22 caracteres. O teste isolado foi concluído sem erro de script e SHA dos oito arquivos (seis QVDs, QVW R2, QVS) inalterados.

**Falha anterior preservada e causa exata ainda pendente:** a exportação de **coluna única** de 602.859 linhas continha **um hash textual repetido** em cada TXT, apesar de 85.705 hashes distintos antes de STORE. O probe amostral de três colunas **não demonstra** se a causa depende da quantidade de colunas, da materialização de tabela `LOAD DISTINCT`, do volume, de dualidade em outro contexto ou de algum outro detalhe. Não atribuir bug ao QlikView sem prova, nem corrigir o serializer `SAD-LINK-V1` por hipótese.

**Próximo gate proposto:** no mesmo padrão de QVW temporário, materializar `LOAD DISTINCT` das **85.705 combinações hash+serial** sob três campos auxiliares com nomes únicos: `Text(_P6_HASH)`, `_P6_SERIAL`, `Len(Text(_P6_HASH))`; confirmar contagens de hash, serial e par distintos **85.705** em memória, `STORE` temporário **com três colunas**, e comparar pares completos `(hash,serial)` entre duas recargas independentes via Python `csv.reader`. Guardar logs e CSV em `%TEMP%`, auditar seis SHA QVD + QVW R2 + QVS após o Python. Somente um novo teste físico pode produzir PASS; a proposta segue hipótese antes da execução.

**Estado:** `HASH_TEXT_CAST=PASS_QV_COUNT`; `THREE_COLUMN_SAMPLE_STORE=PASS_5000_ROWS`; `EXACT_KEY_SET_AUDIT=BLOCKED_PENDING_FULL_DISTINCT_EXPORT`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED`; `FACT_QVD=NOT_STARTED`; `LINK_ANALISE=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`; PR #83 Draft.

## 14. Gate de pares exatos R2 preparado — exportação integral de três colunas (13/10/2026)

**HIPÓTESE DE IMPLEMENTAÇÃO / test gate READ-ONLY ainda NÃO EXECUTADO:**

Foram versionados **sem modificar scripts de produção ou evidências anteriores**:

- `tools/validar_estabilidade_link_key_pares_r2.ps1`: preserva `P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw` e `phase_vi_link_key_cross_fact_preflight.qvs`. Cria exclusivamente sob `%TEMP%` um novo QVW para duas recargas independentes e deriva, **após os gates R2 existentes**, uma tabela temporária `P6_EXACT_PAIRS_R2` com `NOCONCATENATE LOAD DISTINCT` sobre `Text(_P6_HASH)`, `_P6_SERIAL` e `Len(Text(_P6_HASH))`. Confere `ROWS=85705 DISTINCT_HASH=85705 DISTINCT_SERIAL=85705 BAD_HASH_LEN=0` no Qlik antes de exportar **três** colunas de texto para CSV temporário.
- `tools/comparar_pares_link_key_qlik.py`: interpreta CSV com `csv.reader` respeitando aspas/delimitadores; exige 85.705 linhas, hashes de 22 caracteres, prefixo `SAD-LINK-V1|C=`, `LEN=22`, 85.705 hashes, 85.705 serializações e **mapeamento biunívoco** hash↔serial. Compara os **pares completos** entre as duas recargas, informa `ONLY_A_PAIRS`, `ONLY_B_PAIRS` e SHA-256 ordenado dos pares. Não exibe a serialização individual no console.
- O PowerShell não emitirá PASS se o Python ou os gates Qlik falharem; somente após todos passarem revalida os **seis QVDs** e o **QVW R2/QVS/comparador** por SHA-256 e remove os artefatos temporários. Na falha conserva apenas o diagnóstico sob `%TEMP%`, isolado de qualquer dataset produtivo.

**Motivação vinculada à evidência:** o probe amostral Qlik de **três** colunas produziu `801/801` hashes/serializações distintas entre 5.000 linhas, ao passo que a primeira tentativa com uma única coluna e 602.859 linhas exportou um hash repetido. Uma projeção `LOAD DISTINCT` de 85.705 pares reduz volume e oferece rastreabilidade hash↔coordenadas sem alterar a função candidata. **Não se sabe ainda** se esta exportação integral passará, nem se a diferença anterior decorreu do número de colunas, tamanho da tabela, ou outra particularidade do `STORE`.

**Resultado esperado somente após execução física:** `RUN_A_ROWS=85705`, `RUN_B_ROWS=85705`, `ONLY_A_PAIRS=0`, `ONLY_B_PAIRS=0`, `COMPARISON=EXACT_85705_HASH_SERIAL_PAIRS_MATCH`, `ALL_6_INPUT_QVD_SHA256_UNCHANGED=True`, `VERDICT=PASS_2_RELOADS_EXACT_85705_LINK_PAIRS_MATCH_NOT_APPROVED`. Mesmo um PASS não aprova `%LINK_KEY` definitiva, `LINK_ANALISE` ou modelo role-playing. `LINK_KEY_CONTRACT=NOT_APPROVED`; `EXACT_KEY_SET_R2=PREPARED_NOT_RUN`; `PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED`; `FACT_QVD=NOT_STARTED`; `LINK_ANALISE=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`.

## 15. PASS físico — igualdade exata de 85.705 pares em duas recargas independentes (13/10/2026)

**FATO VERIFICADO — execução local Windows / QlikView Desktop 12 + Python 3 fornecida pelo responsável:** após `git pull --ff-only` da branch do PR #83 até `86dca7b`, o runner versionado `tools/validar_estabilidade_link_key_pares_r2.ps1` criou um QVW **somente em `%TEMP%`**, manteve o `SAD-LINK-V1` original e executou **duas recargas independentes**. Ambos os perfis QlikView passaram e ambos os CSVs de três colunas exportaram 16.083.119 bytes. O comparador `tools/comparar_pares_link_key_qlik.py` analisou **todos** os registros deduplicados de cada exportação:

```text
MODE=PHASE_VI_LINK_KEY_EXACT_PAIRS_R2_TWO_INDEPENDENT_RELOADS
ORIGINAL_QVW_MODIFIED=False
ONLY_TEMPORARY_HASH_SERIAL_PAIR_EXPORTS=True
FACT_QVD_GENERATED=False
LINK_ANALISE_QVD_GENERATED=False
RUN_1_RELOAD_RETURNED=True
RUN_1_PROFILE_PASS=True
RUN_1_EXPORTED_PAIR_BYTES=16083119
RUN_2_RELOAD_RETURNED=True
RUN_2_PROFILE_PASS=True
RUN_2_EXPORTED_PAIR_BYTES=16083119
RUN_A_ROWS=85705
RUN_A_DISTINCT_HASH=85705
RUN_A_DISTINCT_SERIAL=85705
RUN_B_ROWS=85705
RUN_B_DISTINCT_HASH=85705
RUN_B_DISTINCT_SERIAL=85705
MODE=PHASE_VI_LINK_KEY_EXACT_HASH_SERIAL_PAIR_COMPARE
RUN_A_SORTED_PAIR_SHA256=468057c560318ec15a9552e24434330da90e6c63929269f42c604c0d4085040e
RUN_B_SORTED_PAIR_SHA256=468057c560318ec15a9552e24434330da90e6c63929269f42c604c0d4085040e
ONLY_A_PAIRS=0 ONLY_B_PAIRS=0
COMPARISON=EXACT_85705_HASH_SERIAL_PAIRS_MATCH
SOURCE_R2_QVW_SHA256_UNCHANGED=True
VERSIONED_QVS_SHA256_UNCHANGED=True
ALL_6_INPUT_QVD_SHA256_UNCHANGED=True
VERDICT=PASS_2_RELOADS_EXACT_85705_LINK_PAIRS_MATCH_NOT_APPROVED
LINK_KEY_CONTRACT=NOT_APPROVED
PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED
TEMPORARY_PAIR_EXPORTS_REMOVED=True
```

**Interpretação do PASS (escopo estrito):** o comparador validou 85.705 pares `(Text(_P6_HASH),_P6_SERIAL)` **distintos** por recarga, 85.705 hashes e 85.705 serializações, correspondência biunívoca de hash↔serial em cada conjunto, comprimento de hash de 22 caracteres e igualdade **exata de conjuntos completos**, `ONLY_A_PAIRS=ONLY_B_PAIRS=0`. O SHA-256 dos pares ordenados coincide nas duas recargas. Seis QVDs, QVS versionado e QVW R2 original foram novamente verificados por SHA-256 e permaneceram inalterados. Arquivos temporários da auditoria **bem-sucedida** foram removidos.

**Distinção importante em relação ao incidente anterior:** a primeira exportação `STORE _P6_HASH ... (txt)` de coluna única permanece com `602859` linhas e `1` valor textual bruto em seus dois diagnósticos retidos; **causa raiz técnica não comprovada**. A nova exportação temporária `LOAD DISTINCT` **de três colunas** foi bem-sucedida; não declarar que a falha anterior foi necessariamente causada por CSV de coluna única, Qlik bug ou conversão `Text()` sem experimento causal. Os TXT antigos não participam do PASS novo e podem permanecer retidos para auditoria.

**Estado de gate verificado:** `CROSS_FACT_FIVE_COORDINATES=PASS_EXPERIMENTAL_R2`, `PAIR_EXACT_SET_TWO_RELOADS=PASS`, `SAD_LINK_V1_IDENTICAL_HASH_SERIAL_MAPPING=PASS_OBSERVED_SNAPSHOT_2017_2019`, `INPUT_QVD_AND_QVW_SHA256_UNCHANGED=PASS`. Esses resultados não afirmam nem aprovam a `%LINK_KEY` como contrato materializado para QVDs factuais nem demonstram o diagrama de associações QlikView final.

## 16. Próximo gate contratual — LINK_ANALISE distinta e integridade associativa (READ-ONLY, NÃO EXECUTADO)

**FATO DOCUMENTAL (Boundaries 6 §§22.5–22.6 e 7 §22):** a `LINK_ANALISE` materializada deverá conter somente **combinações distintas** das cinco coordenadas conformadas e a `%LINK_KEY`, com as três fatos ligando-se **somente pela `%LINK_KEY`**. Toda linha factual terá exatamente uma chave, todas deverão encontrar correspondência na Link Table, nenhum processo factual perderá ou ganhará registros, e os campos de papéis de residência e serviço deverão ser associáveis sem nomes homônimos espúrios, loops ou `$Syn` não justificadas. Os campos não aplicáveis continuam nulos. Grãos e agregações de capacidade/população permanecem protegidos, sem somar snapshots de leitos ou anos populacionais.

**DECISÕES PENDENTES / sequência de validação para a próxima Discovery:**

1. Projetar em memória, a partir das fontes validadas, uma `LINK_ANALISE` **simulada e distinta**, com cinco SKs coordenadas e hash candidato sem gravar `LINK_ANALISE.qvd`.
2. Conferir cardinalidades **factual→chave→link**, cobertura de 100% para RD (566.672), LT (35.518) e IBGE (669), todos os 85.705 pares distintos, ausência de NULLs inesperados e preservação dos grãos/métricas; distinguir relação muitos-para-um válida de multiplicação indevida das linhas.
3. Ensaiar **aliases role-playing** e nomeações associativas no Table Viewer do QlikView: papéis residência e serviço mantidos sem associação acidental por campo descritivo, nenhum loop, nenhuma `$Syn` injustificada; verificar filtros representativos do tempo/município/estabelecimento, **sem pressupor equivalência analítica entre residência e atendimento**.
4. Reconciliar posteriormente indicadores conforme Boundary 6 §22.7, preservando fatos com aditividades diferentes, sem interpretar `internações/leito` como ocupação real.

**HIPÓTESE DE MODELAGEM:** reutilizar `SAD-LINK-V1` é tecnicamente promissor para este snapshot após PASS exato, mas **aprovação do contrato final** requer o teste associativo multi-fato e revisão explícita. O teste R2 exitoso não transforma a Link Table em entidade acadêmica adicional nem modifica o Star Schema aprovado.

**Estado:** `PAIR_EXACT_SET_R2=PASS`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `LINK_ANALISE_ASSOCIATIVE_PREFLIGHT=NOT_STARTED`; `PHYSICAL_ASSOCIATIVE_MODEL=NOT_TESTED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `PAINEL=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`; PR #83 mantém estado **Draft sem merge**.

## 17. Preflight associativo multífato — QVW isolado preparado, NÃO EXECUTADO (13/10/2026)

**Objetivo:** obter evidência QlikView 12 da construção da `LINK_ANALISE` **somente em memória** e das associações de **três projeções técnicas de fatos**, sem materializar QVD factual, `LINK_ANALISE.qvd` ou `PAINEL.qvw`. Preserva Boundaries 6 §§5–6, 22.5–22.6 e 7 §22, sem modificar o projeto acadêmico dos Capítulos 1–2.

**Arquivos novos, apenas no Draft PR #83:**

- `TRANSFORMACAO/phase_vi_link_associative_projection_preflight.qvs` — bloco Qlik aditivo para **QVW temporário**, sem `STORE` nem `JOIN`: lê `P6_COORDS` do preflight canônico, **recalcula de modo independente** `Hash128('SAD-LINK-V1',...)` com os cinco SKs e nulos tipados, e executa `NOCONCATENATE LOAD DISTINCT` criando `P6_LINK_SIMULADA` com **seis campos**: `%LINK_KEY`, competência, ano, município residência, município serviço, estabelecimento. Expectativa de **85.705 linhas, 85.705 hashes únicos**.
- `tools/validar_link_associativo_qlik.ps1` — abre **somente para conferência** o QVW R2 já testado, compara QVS/QVW canônicos e SHA-256 dos **seis QVDs**, cria **um novo QVW ignorável sob `%TEMP%`** e injeta o QVS associativo dentro do script-base, antes do cleanup de P6. Não escreve datasets, fatos ou QVD; depois da recarga examina marcadores nativos e SHA-256 das entradas. Em FAIL, mantém QVW/log temporários para diagnóstico; em PASS, remove o QVW/log descartáveis.

**Modelo exclusivamente diagnóstico projetado:**

```text
                  P6_DIM_COMP_SIMULADA
                          |
P6_DIM_RES_SIMULADA -- P6_LINK_SIMULADA -- P6_DIM_SERV_SIMULADA
                          |               |
                  P6_DIM_ANO_SIMULADA   (papéis nomeados)
                          |
                   P6_DIM_EST_SIMULADA
                          |
               [%LINK_KEY] comum às 3:
           P6_FATO_RD_SIMULADA   (566672 linhas)
           P6_FATO_LT_SIMULADA   (35518 linhas)
           P6_FATO_POP_SIMULADA  (669 linhas)
```

A topologia acima é **conceitual**. Cada projeção de fato terá **somente** `%LINK_KEY` e um ordinal diagnóstico para contar suas linhas. Dimensões conformadas são carregadas com **aliases role-playing com campos descritivos distintos**: tempo competência, tempo ano, município residência, município serviço, estabelecimento. A `DIM_TEMPO.qvd` possui grão diário, portanto as duas aliases temporais são `LOAD DISTINCT` no papel mensal e anual para não multiplicar SKs. Residência nula de capacidade, competência/estabelecimento nulos de população, e residentes externos permanecem como aprovados; não entram sentinelas artificiais nas SKs.

**Gates implementados no QVS/runner (somente esperados, ainda NÃO medidos):**

1. `P6_LINK_SIMULADA=85705` linhas distintas e `COUNT(DISTINCT %LINK_KEY)=85705`, zero chaves link nulas, zero ano/município serviço inesperadamente nulos;
2. Zero chaves da Link Table fora do conjunto original validado, com mapa `P6_ASSOC_BASE_HASH_MAP` criado do resultado anterior; **100% cobertura** fato→Link via `P6_ASSOC_LINK_KEY_MAP`;
3. **RD=566672, LT=35518, POP=669**, zero orphans e zero `%LINK_KEY` nula em cada projeção, sem perder/duplicar registros no estágio dos fatos técnicos;
4. Após remover as tabelas diagnósticas do preflight-base, exigir **exatamente 9 tabelas**, 0 `$Syn` no TableName, número previsto de campos por alias/fato/link, alias de município residência/serviço com **937 linhas cada**, estabelecimento com **220.390 versões**, pelo menos 36 competências e 3 anos, e ausência de warning de circular reference detectável no log nativo;
5. Exigir todos os marcadores estritos do QlikView, os seis QVDs, QVS-base, QVS-projeção e QVW R2 **SHA-256 inalterados**. Documento temporário será removido apenas após PASS.

**Ressalvas obrigatórias:** este é um ensaio de **esquema mínimo de associação**, **não** uma implementação completa de `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO` nem do `PAINEL`. Não inclui as chaves exclusivas/medidas factuais e **não comprova filtros role-playing operados na interface**, Table Viewer visual nem reconciliação de indicadores do Boundary 6 §22.7. A ausência de `$Syn` e as contagens isoladas não substituem a inspeção de associações e loops na interface, quando essa etapa for efetivamente feita. Em nenhuma hipótese um PASS deste teste autoriza materialização sem revisão.

**Estado:** `LINK_ASSOC_MINIMAL_9_TABLE_PREFLIGHT=PREPARED_NOT_RUN`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `LINK_ANALISE_QVD=NOT_STARTED`, `FACT_QVDS=NOT_STARTED`, `PAINEL=NOT_STARTED`, `TABLE_VIEWER_ROLE_SELECTION=NOT_TESTED`, `T29_HISTORICAL=NOT_APPROVED`. O PR #83 continua **Draft** e a `main` permanece intocada.

## 18. PASS físico do preflight associativo de 9 tabelas — 13/10/2026 10:20:35

**FATO VERIFICADO (stdout da execução QlikView 12 enviada pelo responsável):** após `git pull --ff-only` da branch do Draft PR #83 até `660c44e`, o executor versionado `tools/validar_link_associativo_qlik.ps1` executou integralmente o QVW temporário `P6_ASSOC_LINK_IN_MEMORY.qvw` em `%TEMP%`. Os logs nativos e o executor retornaram:

```text
MODE=PHASE_VI_ASSOCIATIVE_LINK_TABLE_PREFLIGHT_READ_ONLY
FACT_QVD_GENERATED=False
LINK_ANALISE_QVD_GENERATED=False
OUTPUT_DATA_FILES_WRITTEN=0
RELOAD_STARTED=True
RELOAD_RETURNED=True
2026-10-13 10:20:35 [P6-ASSOC] LINK_ROWS=85705 LINK_DISTINCT=85705 LINK_ORPHAN_BASE=0 REQUIRED_NULL=0
2026-10-13 10:20:35 [P6-ASSOC] FACT_ROWS RD=566672 LT=35518 POP=669
2026-10-13 10:20:35 [P6-ASSOC] FACT_ORPHANS RD=0 LT=0 POP=0
2026-10-13 10:20:35 [P6-ASSOC] FACT_NULL RD=0 LT=0 POP=0
2026-10-13 10:20:35 [P6-ASSOC] FINAL_MODEL TABLES=9 SYNTHETIC=0 COMP_ALIAS=144 ANO_ALIAS=12 RES_ALIAS=937 SERV_ALIAS=937 EST_ALIAS=220390
2026-10-13 10:20:35 [P6-ASSOC] VERDICT=PASS_IN_MEMORY_85705_LINK_AND_3_FACT_COVERAGE_NOT_FINAL
2026-10-13 10:20:35 [P6-ASSOC] TABLE_VIEWER_ROLE_SELECTION=NOT_TESTED CIRCULAR_LINKS_VISUAL_REVIEW=REQUIRED
ALL_6_INPUT_QVD_SHA256_UNCHANGED=True
SOURCE_R2_QVW_SHA256_UNCHANGED=True
BASE_AND_PROJECTION_QVS_SHA256_UNCHANGED=True
VERDICT=PASS_IN_MEMORY_LINK_COVERAGE_9_TABLE_PROJECTION_NOT_FINAL
TABLE_VIEWER_ROLE_SELECTION=NOT_TESTED
PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY
LINK_KEY_CONTRACT=NOT_APPROVED
TEMPORARY_ASSOC_QVW_REMOVED=True
```

**Interpretação estrita:** a Link Table candidata foi recomposta **somente em memória**, possui 85.705 `%LINK_KEY` distintas e zero valores obrigatórios nulos, e cobre 100% das 566.672 linhas RD, 35.518 LT e 669 IBGE das **projeções técnicas**. Zero `$Syn` identificadas e exatamente nove tabelas com os nomes/contagens esperados. Os seis QVDs e os três arquivos canônicos base QVS, projeção QVS e QVW R2 permaneceram com SHA-256 preservados; nenhum dado/QVD factual/Link Table foi materializado. O QVW descartável foi **removido**, logo não há documento deste ensaio disponível para abertura direta no Table Viewer.

**Observação temporal importante:** `COMP_ALIAS=144` e `ANO_ALIAS=12` refletem os anos e competências presentes na `DIM_TEMPO.qvd` **diária** (2008–2019) e NÃO indicam 144 competências factuais nem 12 anos factuais no estudo. O recorte das três fontes continua **36 competências de 2017 a 2019** e população de **3 anos**; projeções de tempo a partir da dimensão preservam o calendário estendido por datas de internação/saída. Não converter silenciosamente a dimensão calendário para apenas três anos sem decisão.

**Limites expressamente não testados:** nenhuma seleção visual de município residência/serviço, mês/ano ou estabelecimento; nenhuma validação no Table Viewer de arestas/loops; nenhum real QVD factual com medidas e chaves exclusivas; nenhuma reconciliação dos indicadores de Boundary 6 §22.7. O PASS verifica a **topologia mínima e integridade técnica das chaves**, mas não garante que filtros simultâneos e razões cruzadas (internações/população, leitos/população) selecionem os três processos com a semântica esperada. Em especial, população **não possui competência mensal**, capacidade **não possui residência** e as três serializações completas das coordenadas diferem; os seus caminhos via dimensões não devem ser tratados como equivalentes a um join de fatos.

**Estado de gate:** `LINK_ASSOC_MINIMAL_9_TABLE_PREFLIGHT=PASS_QV_NATIVE`; `LINK_KEY_EXACT_PAIRS=PASS_2_RELOADS`; `TABLE_VIEWER_ROLE_SELECTION=NOT_TESTED`; `CIRCULAR_LINKS_VISUAL_REVIEW=REQUIRED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `PAINEL=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. Draft PR #83 continua sem merge.

## 19. Próximo gate de interpretação associativa — inspeção visual e filtros de papéis

**DECISÃO PENDENTE:** produzir um documento QVW temporário **retido com dados de recarga salvos** apenas para conferência no Table Viewer do QlikView 12 e executar verificações dirigidas de seleção, ainda sem QVD factual. A documentação oficial QlikView indica `Ctrl+T` ou File → Table Viewer para analisar arestas, visualizar estrutura interna/source e identificar chaves sintéticas. Inspecionar 9 tabelas, cinco aliases e três fatos técnicos; exigir 0 loops, 0 `$Syn` e nenhuma aresta via nome descritivo homônimo.

**Ponto de risco semântico ainda aberto:** as diferenças de coordenadas são intencionais, mas a igualdade de hashes apenas quando **as cinco coordenadas completas** coincidem não significa que selecionar mês de internações seja compatível com o registro de população **sem mês**. A validação de eixos por município e ano precisa testar a seleção simultânea e seus efeitos sobre disponibilidade de cada processo antes de aprovar o modelo ou indicadores. Se houver conflito, classificar como **hipótese de modelagem a revisar**, sem modificar retroativamente o Boundary 6/7 nem a primeira entrega acadêmica.

**Não executar QVDs factuais ou Link Table definitiva neste gate.** Se houver relatório de filtros/arestas a partir do visualizador, documentar a evidência com suas limitações sem alegar aprovação irrestrita. `ASSOCIATIVE_ROLE_SELECTION=NOT_TESTED`; `LINK_KEY_CONTRACT=NOT_APPROVED`.

## 20. Table Viewer — retenção opcional de QVW temporário preparada, NÃO EXECUTADA

**Implementação mínima somente na branch Draft PR #83:** `tools/validar_link_associativo_qlik.ps1` agora aceita o **switch opcional** `-RetainForVisualReview`. Não modifica o QVS associativo nem as seis entradas, a fórmula `SAD-LINK-V1`, os gates existentes ou o comportamento sem switch. Com switch o runner executa de novo a projeção, salva com `doc.Save()` **somente o QVW criado sob `%TEMP%`** (com o modelo carregado), verifica o timestamp, exige os gates e SHA-256 pré-existentes, e **não remove** o QVW temporário após PASS. O caminho real será impresso em `VISUAL_REVIEW_QVW=...`. Se ocorrer FAIL, o diagnóstico continua fail-closed/retido para inspeção. **Esta execução com retenção ainda NÃO ocorreu no QlikView do usuário.**

**Sequência de inspeção manual posterior, sem criar tabelas de negócio:**

1. Executar `tools/validar_link_associativo_qlik.ps1 -Root (Get-Location).Path -RetainForVisualReview`, após `git pull --ff-only`; exigir os mesmos números R2 e o marcador `VISUAL_REVIEW_QVW`. Se o método COM de salvar o documento falhar em alguma versão de QlikView 12, bloquear e não presumir arquivo utilizável.
2. Abrir **somente o caminho temporário `VISUAL_REVIEW_QVW`** no QlikView Desktop 12. Pressionar `Ctrl+T` (File → Table Viewer; procedimento descrito oficialmente em [QlikView Help — Table Viewer](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Table_Viewer.htm)). Conferir tanto *Internal Table View* quanto *Source Table View*, se disponível.
3. Verificar `P6_LINK_SIMULADA` central com `%LINK_KEY` e cinco campos SK, três projeções de fatos com exclusivamente `%LINK_KEY` como campo compartilhado, e cinco aliases `P6_DIM_COMP_SIMULADA`, `P6_DIM_ANO_SIMULADA`, `P6_DIM_RES_SIMULADA`, `P6_DIM_SERV_SIMULADA`, `P6_DIM_EST_SIMULADA`, **sem `$Syn`**, campos descritivos homônimos ou arestas adicionais indevidas.
4. Registrar captura (somente da estrutura) ou descrição fiel das arestas **antes** de criar seleções. Após isso, planejar testes de seleção por ano, competência e papéis municipais. **Hipótese sob teste:** seleção de competência pode excluir população anual (competência nula); seleção de município de residência pode excluir capacidade (residência nula). Não inferir que anos/população leitos/internações podem ser agregados corretamente sem observar essas seleções.
5. Apagar o **QVW temporário** manualmente somente após documentar a verificação, se não houver pendência diagnóstica; nunca apagar `TRANSFORMACAO/P6_LINK_KEY_CROSS_FACT_PREFLIGHT_R2.qvw`, seis QVDs ou QVSs versionados.

**DECISÃO PENDENTE:** o save/reopen do QVW temporário com dados, o Table Viewer e os filtros permanecem **NOT_TESTED**. Uma captura de nove tabelas não é aprovação automática de denominadores entre competências mensais e população anual; medidas factuais e indicadores reais continuam ausentes. `LINK_ASSOC_MINIMAL_9_TABLE_PREFLIGHT=PASS_QV_NATIVE`, `TABLE_VIEWER=PREPARED_NOT_RUN`, `SELECTION_SEMANTICS=NOT_TESTED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`, `FACT_QVD=NOT_STARTED`, `LINK_ANALISE_QVD=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`.

## 21. Table Viewer — PASS visual da topologia mínima, filtros ainda NÃO TESTADOS (13/10/2026 10:30:33)

**FATO VERIFICADO** — o responsável executou fisicamente `tools/validar_link_associativo_qlik.ps1 -RetainForVisualReview` após fast-forward da branch Draft PR #83 até `55a0e36`, obteve `TEMPORARY_ASSOC_QVW_SAVED_WITH_LOADED_DATA=True`, log de preflight **PASS** às 10:30:33 e apresentou captura real do **Table Viewer do QlikView 12**. O QVW foi salvo exclusivamente em:

`C:\Users\pedro\AppData\Local\Temp\SAD_P6_ASSOC_PREFLIGHT_07355503816541ddbed257b795d42ea2\P6_ASSOC_LINK_IN_MEMORY.qvw`

**Nativo na recarga com retenção:**

```text
[P6-ASSOC] LINK_ROWS=85705 LINK_DISTINCT=85705 LINK_ORPHAN_BASE=0 REQUIRED_NULL=0
[P6-ASSOC] FACT_ROWS RD=566672 LT=35518 POP=669
[P6-ASSOC] FACT_ORPHANS RD=0 LT=0 POP=0
[P6-ASSOC] FACT_NULL RD=0 LT=0 POP=0
[P6-ASSOC] FINAL_MODEL TABLES=9 SYNTHETIC=0 COMP_ALIAS=144 ANO_ALIAS=12 RES_ALIAS=937 SERV_ALIAS=937 EST_ALIAS=220390
[P6-ASSOC] VERDICT=PASS_IN_MEMORY_85705_LINK_AND_3_FACT_COVERAGE_NOT_FINAL
ALL_6_INPUT_QVD_SHA256_UNCHANGED=True
SOURCE_R2_QVW_SHA256_UNCHANGED=True
BASE_AND_PROJECTION_QVS_SHA256_UNCHANGED=True
VERDICT=PASS_IN_MEMORY_LINK_COVERAGE_9_TABLE_PROJECTION_NOT_FINAL
VISUAL_REVIEW_QVW=C:\Users\pedro\AppData\Local\Temp\SAD_P6_ASSOC_PREFLIGHT_07355503816541ddbed257b795d42ea2\P6_ASSOC_LINK_IN_MEMORY.qvw
VISUAL_REVIEW_TABLE_VIEWER=NOT_TESTED
VISUAL_REVIEW_FILTER_SEMANTICS=NOT_TESTED
TEMPORARY_ASSOC_QVW_REMOVED=False
```

**Inspeção da captura de Table Viewer fornecida pelo responsável (não anexada ao Git nesta Discovery):**

- Uma única `P6_LINK_SIMULADA` central apresenta seis campos: `%LINK_KEY`, `%SK_ESTABELECIMENTO`, `%SK_MUNICIPIO_SERVICO`, `%SK_TEMPO_COMPETENCIA`, `%SK_TEMPO_ANO` e `%SK_MUNICIPIO_RESIDENCIA`.
- As três projeções `P6_FATO_RD_SIMULADA`, `P6_FATO_LT_SIMULADA`, `P6_FATO_POP_SIMULADA` possuem cada uma apenas **dois campos**: a mesma `%LINK_KEY` e seu `P6_*_ROW_DEBUG` exclusivo. A única associação desenhada entre essas projeções e a ponte é `%LINK_KEY`.
- Cinco dimensões/papéis `P6_DIM_COMP_SIMULADA`, `P6_DIM_ANO_SIMULADA`, `P6_DIM_RES_SIMULADA`, `P6_DIM_SERV_SIMULADA`, `P6_DIM_EST_SIMULADA` ligam-se à ponte exclusivamente pela SK de seu papel, com atributos descritivos prefixados.
- **Nove tabelas visíveis; nenhuma tabela `$Syn`, arco por campo descritivo homônimo, ligação extra ou ciclo aparente na imagem.** Esse é um **PASS visual da topologia mínima representada**, em conjunto com o PASS nativo e zero `$Syn`, mas a captura não comprova que os modos *Internal Table View* e *Source Table View* tenham sido conferidos separadamente.

**Cautela operacional:** o runner imprime `VISUAL_REVIEW_TABLE_VIEWER=NOT_TESTED` por contrato, pois não controla a UI. A captura recebida agora permite atualizar **a avaliação humana visual** para `TABLE_VIEWER_TOPOLOGY=PASS_ONE_SCREENSHOT`; não alterar nem apagar retroativamente a saída do runner. `TEMPORARY_ASSOC_QVW_REMOVED=False` é esperado para a revisão visual; preservar este arquivo até terminar as seleções. Sem geração de QVDs factuais ou Link Table.

## 22. Próximo gate: seleções e preservação de fatos por papéis (não executado)

**DECISÃO PENDENTE / PROTOCOLO MANUAL READ-ONLY:** usar **somente o QVW temporário retido** e construir no próprio documento de diagnóstico caixas de lista para `P6_ANO_ANO`, `P6_COMP_COMPETENCIA`, `P6_RES_DATASUS_6` e `P6_SERV_DATASUS_6`, mais três objetos de texto com expressões `Count(P6_RD_ROW_DEBUG)`, `Count(P6_LT_ROW_DEBUG)`, `Count(P6_POP_ROW_DEBUG)`. Estes ordinais existem **apenas nas projeções técnicas**, portanto não são as medidas clínicas nem populacionais e só servem para observar presença de linhas associadas.

**Executar isoladamente, limpando todas as seleções antes de cada cenário, e registrar as três contagens:**

| Cenário | Seleção | Objetivo | Interpretação esperada, ainda HIPÓTESE |
| --- | --- | --- | --- |
| S0 | Nenhuma | referência de 566672 / 35518 / 669 | os 3 processos disponíveis |
| S1 | `P6_ANO_ANO = 2019` | eixo anual comum | os 3 processos presentes, valores não inventados |
| S2 | `P6_COMP_COMPETENCIA = 201909` | eixo mensal | RD e LT presentes; população **pode** ficar excluída pela competência `NULL` |
| S3 | `P6_RES_DATASUS_6` de município PB com RD/POP | município residência | RD/POP presentes; LT **pode** ficar excluída pela residência `NULL` |
| S4 | `P6_SERV_DATASUS_6` de município PB com atendimento/leitos/população | município serviço | verificar presença de RD/LT/POP, sem presumir contagens |
| S5 | `P6_ANO_ANO=2019` + um município de serviço PB | comparação anual territorial | verificar se o denominador populacional permanece disponível |

**Não selecionar ano e competência simultaneamente no primeiro teste**; deixar combinações para último passo. Se S2 ou S3 esvaziar um processo que deveria fornecer denominador em indicador, registrar como **limitação semântica do caminho de seleção**, não corrigir alterando arbitrariamente nulos, serializador, Boundary 6/7 ou capítulos impressos. Análises mensais/população anual podem exigir desenho explícito de agregação ou caminho de seleção alternativo **em decisão separada**.

**Estado depois da captura:** `QVW_TEMP_SAVE_REOPEN=PASS_USER_SCREENSHOT`, `TABLE_VIEWER_TOPOLOGY=PASS_ONE_SCREENSHOT`, `ROLE_SELECTIONS=NOT_TESTED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`, `FACT_QVDS=NOT_STARTED`, `LINK_ANALISE_QVD=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`, PR #83 Draft sem merge.

## 23. Seleções temporais no QlikView — S0/S1 PASS e S1+201909 exclui POP (13/10/2026)

**FATO VERIFICADO (três capturas reais do mesmo QVW associativo temporário fornecidas pelo responsável):** foram adicionadas caixas de lista `P6_ANO_ANO`, `P6_COMP_COMPETENCIA` e objeto de texto com `Count(P6_RD_ROW_DEBUG)`, `Count(P6_LT_ROW_DEBUG)`, `Count(P6_POP_ROW_DEBUG)`. Os números registrados são **contagens de linhas administrativas/técnicas**, não `QTD_INTERNACAO`, número de leitos efetivos, população em pessoas nem indicadores finais.

| Captura / cenário observado | Seleções visíveis | RD (linhas) | LT (linhas) | POP (linhas) | Leitura |
| --- | --- | ---: | ---: | ---: | --- |
| 1 — S0 | nenhuma (ano e competência sem seleção verde) | 566672 | 35518 | 669 | PASS da referência total |
| 2 — S1 | `P6_ANO_ANO=2019` (verde), competências de 2019 possíveis | 191653 | 11648 | 223 | PASS da presença dos três processos no eixo anual |
| 3 — S1+M09 | **`P6_ANO_ANO=2019` e `P6_COMP_COMPETENCIA=201909` ambos verdes** | 16489 | 978 | **0** | População anual excluída pela seleção mensal combinada |

**Precisão de cenário obrigatória:** a captura 3 **NÃO** executou S2 no protocolo original (competência 201909 isolada após `Clear All`): o ano 2019 **permanece selecionado em verde**. O valor `POP=0` é, entretanto, evidência física inequívoca de ausência de registros da FATO_POPULACAO técnica com **2019 + competência 201909 selecionados**. Não renomear silenciosamente S1+M09 para S2.

**Limitação associativa verificada:** no modelo com cinco coordenadas e nulo real para a competência da população anual, um filtro mensal combinado pode retirar completamente a disponibilidade do denominador populacional, apesar de existir `POP=223` ao filtrar apenas 2019. Uma contagem técnica `POP=223` representa **223 linhas município-ano**, não 223 habitantes. `RD=191653` é **registro administrativo RD**, não quantidade de novas admissões (o indicador `QTD_INTERNACAO` exclui `IDENT=5`). A queda `POP=223 → 0` não deve ser 'corrigida' duplicando população em 12 meses ou introduzindo sentinelas como se fossem competências reais.

**HIPÓTESE DE MODELAGEM:** será necessário um mecanismo de seleção/expressão que mantenha coerência anual nos denominadores durante análises mensais (por exemplo, avaliar set analysis em ensaio separado), sem aprovar sua fórmula, efeitos de seleção, duplicações ou denominações por antecipação. A evidência não demonstra que uma estratégia específica resolva todos os cruzamentos RD/LT/POP. A conveniência de preservar a Link Table com seus cinco campos deve ser reconsiderada apenas após os demais testes e uma decisão documentada, sem alterar Boundaries 6/7 ou a entrega acadêmica por iniciativa implícita.

**PRÓXIMOS TESTES READ-ONLY no QVW retido:**

1. S2 isolado — limpar **todas** as seleções antes de marcar apenas `P6_COMP_COMPETENCIA=201909`; anotar RD/LT/POP. Não presumir a mesma contagem da captura S1+M09.
2. S3 residência — limpar tudo, criar caixa `P6_RES_DATASUS_6`, selecionar um município PB com presença RD+POP e registrar **código realmente selecionado** e RD/LT/POP; capacidade tem residência nula, então `LT=0` é hipótese física a verificar.
3. S4 serviço — limpar tudo, criar caixa `P6_SERV_DATASUS_6`, selecionar município PB com RD/LT/POP e registrar código e três contagens. Preferir o mesmo município de S3 para comparação, **sem supor valores**.
4. S5 serviço+ano — limpar tudo e selecionar `P6_ANO_ANO=2019` e o município de serviço de S4, verificando se a população de 2019 continua associada.

**DECISÃO PENDENTE:** `YEAR_FILTER_ASSOCIATION=PASS_ON_2019`; `MONTH_AND_YEAR_POPULATION_ASSOCIATION=FAIL_FOR_SHARED_FILTERING`; `MONTH_ONLY_ASSOCIATION=NOT_TESTED`; `RESIDENCE_FILTER_ASSOCIATION=NOT_TESTED`; `SERVICE_FILTER_ASSOCIATION=NOT_TESTED`; `ANNUAL_SERVICE_FILTER_ASSOCIATION=NOT_TESTED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. A evidência está nas capturas enviadas nesta conversa, não versionadas como imagem no Git. Preservar o QVW temporário para os testes seguintes.

## 24. Seleção S2 isolada — competência 201909 exclui POP mesmo sem ano selecionado (13/10/2026)

**FATO VERIFICADO — captura física do QlikView 12 fornecida pelo responsável:** o campo `P6_COMP_COMPETENCIA` aparece **com `201909` em verde**, ao passo que **nenhum valor de `P6_ANO_ANO` está em verde**; `2019` está visível como valor possível, sem seleção explícita. O objeto técnico mostra:

```text
S2_SELECTION: P6_COMP_COMPETENCIA=201909 ONLY
P6_ANO_ANO=NOT_EXPLICITLY_SELECTED
RD=16489
LT=978
POP=0
```

**Conclusão de S2 independente:** a ausência de linhas POP sob filtro mensal não depende de o usuário ter selecionado explicitamente o ano junto com o mês, pois o mesmo comportamento ocorreu com **201909 isolado**. O cenário combinado anterior (`P6_ANO_ANO=2019` + `201909`) fica **corroborado**, não é substituído retrospectivamente. `POP=0` é contagem de **linhas técnicas município×ano em estado de seleção**, não prova de ausência de população na fonte IBGE ou de habitantes reais iguais a zero. `RD=16489` conta registros RD, não `QTD_INTERNACAO`; `LT=978` conta linhas de leitos por CNES/competência/código, não o total de leitos existentes.

**Limitação semântica CONFIRMADA (escopo do protótipo):** o modelo atual associa a população anual a uma `%LINK_KEY` cuja competência é `Null()`; o eixo `P6_COMP_COMPETENCIA` filtra as combinações com competência mensal, deixando sem correspondência os registros anuais de população. **DECISÃO PENDENTE:** mecanismo de denominador anual para indicadores mensais deverá ser testado em separado sem expandir a população mês a mês, preencher NULL não aplicável nem alterar silenciosamente as cinco coordenadas aprovadas. Não implementar `FATO_POPULACAO.qvd` ou `LINK_ANALISE.qvd` com base no gate de seleção parcial.

**Próximo gate ainda NÃO TESTADO:** S3 município residência (limpar TODAS seleções, selecionar um `P6_RES_DATASUS_6` presente e anotar o código), seguido por S4 município serviço `P6_SERV_DATASUS_6` e S5 município serviço+ano. Se a LT desaparecer em S3, classificar como incompatibilidade com filtro de residência decorrente da coordenada não aplicável, não como falta de leitos. Preservar o QVW temporário de visualização até encerrar as seleções.

**Estado:** `MONTH_ONLY_ASSOCIATION=CONFIRMED_POP_EXCLUDED`; `MONTH_AND_YEAR_POPULATION_ASSOCIATION=CONFIRMED_POP_EXCLUDED`; `YEAR_FILTER_ASSOCIATION=PASS_ON_2019`; `RESIDENCE_FILTER_ASSOCIATION=NOT_TESTED`; `SERVICE_FILTER_ASSOCIATION=NOT_TESTED`; `ANNUAL_SERVICE_FILTER_ASSOCIATION=NOT_TESTED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. A captura S2 fornecida pelo usuário não foi adicionada ao Git como binário.

## 25. S3 — João Pessoa 250750 no papel residência (13/10/2026)

**FATO VERIFICADO — captura QlikView 12:** `P6_RES_DATASUS_6=250750` selecionado (verde); ano e competência sem seleção verde. Contagens dos registros técnicos: **RD=125200; LT=0; POP=3**.

Interpretação: RD é registro administrativo, não `QTD_INTERNACAO`; POP são as três linhas município×ano 2017–2019, não três habitantes. O filtro por residência exclui as linhas da projeção LT, pois a coordenada de residência não se aplica ao CNES/LT e permanece nula. **LT=0 não significa que João Pessoa não tenha leitos.**

**Próximo gate S4, NÃO EXECUTADO:** limpar todas as seleções no mesmo QVW temporário, marcar `P6_SERV_DATASUS_6=250750` (município de serviço) e registrar RD/LT/POP. S5 também pendente: limpar tudo e filtrar serviço `250750` + ano `2019`. Não pressupor contagens.

**Estado:** `RESIDENCE_FILTER_ASSOCIATION=CONFIRMED_LT_EXCLUDED`; `SERVICE_FILTER_ASSOCIATION=NOT_TESTED`; `ANNUAL_SERVICE_FILTER_ASSOCIATION=NOT_TESTED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`.

## 26. S4 — João Pessoa no papel serviço, três processos presentes (13/10/2026)

**FATO VERIFICADO — captura QlikView 12 fornecida pelo responsável:** caixa `P6_SERV_DATASUS_6` apresenta `250750` (João Pessoa/PB) em verde; caixas de município residência, competência e ano não apresentam valores selecionados em verde.

| Cenário | Campo selecionado | RD — registros técnicos | LT — registros técnicos | POP — registros técnicos |
| --- | --- | ---: | ---: | ---: |
| S3 — residência | `P6_RES_DATASUS_6=250750` | 125200 | 0 | 3 |
| **S4 — serviço** | **`P6_SERV_DATASUS_6=250750`** | **233133** | **10072** | **3** |

**Interpretação restrita:** o mesmo código municipal sob o papel de **serviço** mantém as três projeções disponíveis. Sob o papel de residência (S3), a capacidade hospitalar fica excluída porque a residência é `Null()` no CNES/LT. A diferença de registros SIH/RD entre os papéis é coerente com seus significados (residência dos pacientes versus localização do atendimento), mas estas contagens não medem novas admissões nem fluxo líquido de pacientes. `LT=10072` significa **linhas técnicas CNES/LT**, não 10.072 leitos físicos, e `POP=3` significa três registros município×ano, não habitantes.

**Hipótese de modelagem ainda pendente:** a possibilidade de ver RD/LT/POP sob um filtro comum de município de serviço é condição necessária, **não suficiente**, para validar razões por habitante ou capacidade, sobretudo com granularidades diferentes e o desaparecimento de POP sob competência mensal. Não corrigir automaticamente filtros por residência, nem preencher dimensões não aplicáveis.

**Próximo teste S5 — NÃO EXECUTADO:** limpar **todas** as seleções, escolher `P6_SERV_DATASUS_6=250750` e `P6_ANO_ANO=2019` (ambos verdes), manter residência e competência **sem seleção explícita**. Registrar três contagens e capturar os campos para verificar se os três processos permanecem associados no eixo anual de João Pessoa.

**Estado:** `SERVICE_FILTER_ASSOCIATION=CONFIRMED_THREE_PROCESSES_S4_250750`; `RESIDENCE_FILTER_ASSOCIATION=CONFIRMED_LT_EXCLUDED_S3_250750`; `ANNUAL_SERVICE_FILTER_ASSOCIATION=NOT_TESTED`; `MONTH_ONLY_ASSOCIATION=CONFIRMED_POP_EXCLUDED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. A captura S4 está nesta conversa; não foi versionada como binário no Git.

## 27. S5 — município de serviço João Pessoa + ano 2019: os três processos continuam presentes (13/10/2026)

**FATO VERIFICADO — captura do QlikView Desktop 12 enviada pelo responsável:** as caixas `P6_SERV_DATASUS_6` e `P6_ANO_ANO` mostram, respectivamente, `250750` (João Pessoa/PB) e `2019` **selecionados em verde**. As caixas `P6_COMP_COMPETENCIA` e `P6_RES_DATASUS_6` não apresentam valores selecionados em verde. O objeto de texto com as três contagens técnicas mostra:

```text
S5_SELECTED_SERVICE=250750
S5_SELECTED_YEAR=2019
S5_MONTH_AND_RESIDENCE=NOT_EXPLICITLY_SELECTED
RD=79166
LT=3412
POP=1
```

**Interpretação estrita:** o eixo conjunto **município de serviço + ano** preservou **linhas das três projeções técnicas** e não fez a população anual desaparecer. `POP=1` significa **uma linha município×ano de João Pessoa em 2019**, não um habitante. `LT=3412` são **registros CNES/LT** no recorte, não o número de leitos disponíveis. `RD=79166` são **linhas administrativas RD**, não `QTD_INTERNACAO` após regra `IDENT=5`. Os resultados não validam automaticamente agregações aditivas de snapshots LT nem indicadores clínicos.

### Síntese da primeira bateria de seleções S0–S5

| Cenário físico | Seleção | RD (registros técnicos) | LT (registros técnicos) | POP (registros técnicos) | Resultado comprovado |
| --- | --- | ---: | ---: | ---: | --- |
| S0 | nenhuma | 566672 | 35518 | 669 | três fontes disponíveis |
| S1 | ano `2019` | 191653 | 11648 | 223 | três fontes disponíveis por ano |
| S1+M09 | ano `2019` e competência `201909` | 16489 | 978 | **0** | população anual excluída por filtro mensal |
| S2 | somente competência `201909` | 16489 | 978 | **0** | exclusão de população independe de ano explicitamente escolhido |
| S3 | residência `250750` | 125200 | **0** | 3 | CNES/LT excluído pelo papel residência não aplicável |
| S4 | serviço `250750` | 233133 | 10072 | 3 | três fontes disponíveis no papel serviço |
| **S5** | **serviço `250750` e ano `2019`** | **79166** | **3412** | **1** | **três fontes disponíveis no recorte anual territorial** |

**Gate concluído:** `ROLE_SELECTIONS_S0_S5=COMPLETE_WITH_CONFIRMED_SEMANTIC_LIMITATIONS`; `SERVICE_YEAR_FILTER_S5=PASS_THREE_FACT_PROJECTIONS`. A integridade estrutural verificada anteriormente — 85.705 chaves distintas, nove tabelas sem `$Syn`, cobertura factual completa no preflight — **não foi refutada** pelos cenários, mas **não garante** medidas analíticas corretas. Foram demonstrados dois problemas de semântica de filtro no modelo atual: `MONTH_FILTER_EXCLUDES_ANNUAL_POP=CONFIRMED` e `RESIDENCE_FILTER_EXCLUDES_LT=CONFIRMED`. Isso não demonstra incorreção dos registros ou ausência de população/leitos na fonte; são coordenadas **fisicamente não aplicáveis** mantidas como `Null()`.

### Próximo gate — seleção analítica e medidas sob granularidades diferentes (PLANEJADO, NÃO EXECUTADO)

**DECISÃO PENDENTE:** como expressar indicadores por habitante e comparações demanda×capacidade sem eliminar fatos cujos papéis são não aplicáveis? Antes de construir QVDs definitivos, discutir e ensaiar, em **QVW isolado**, um contrato explícito por indicador e por papel geográfico:

1. **Ano × município de residência:** internações (numerador ligado à residência) e população do **mesmo município e ano** (denominador); CNES/LT não compartilha a residência e não deve ser chamado de zero leitos.
2. **Ano × município de serviço:** internações ocorridas no município, capacidade dos estabelecimentos no município e população municipal anual (quando desejado); diferenciar **pressão sobre serviço/território** de **taxa de internação dos residentes**. O mesmo denominador populacional não torna essas duas medidas epidemiologicamente equivalentes.
3. **Competência × município:** preservar internações e snapshot de leitos mensais, mas buscar **população anual correspondente ao mesmo ano e município** por estratégia que será testada (e.g., set analysis ou eixo anual independente), sem distribuir nem duplicar as 223 linhas de população por mês, sem inventar competência populacional e sem preencher residência da capacidade.
4. **Reconciliar medidas reais** só após contrato e dados finais: `QTD_INTERNACAO` respeita `IDENT=5`; população mede pessoas, e LT mede leitos disponíveis segundo regra de competência/tipo CNES aprovada, **não a contagem técnica de linhas nem soma indevida de snapshots**. Não calcular ocupação hospitalar presumida a partir destes testes de chaves.

**Não aprovar ainda uma implementação `Set Analysis` específica:** seleções Qlik podem propagar-se por `%LINK_KEY`; limpar apenas um campo não garante, sem evidência, a reintrodução das linhas POP excluídas por outro caminho. Qualquer candidata deve passar com valores e totais reconciliados nos mesmos cenários S0–S5 e ser documentada como decisão separada, preservando os Boundaries 6/7 e capítulos acadêmicos fechados.

**Estado consolidado:** `S0_S5_SEMANTIC_DISCOVERY=COMPLETED`; `LINK_KEY_HASH_STABILITY=PASS_85705_PAIRS`; `LINK_ASSOC_MINIMAL_9_TABLE_PREFLIGHT=PASS`; `TABLE_VIEWER_TOPOLOGY=PASS_ONE_SCREENSHOT`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_TESTED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `PAINEL=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. Draft PR #83 permanece aberto, sem merge. Preservar o QVW temporário de diagnóstico até decisão explícita sobre essa fase; a captura S5 não foi versionada como binário no Git.

## 28. Experimento semântico controlado — denominador anual sob filtro mensal (PREPARADO, NÃO EXECUTADO)

**FATO DOCUMENTAL / contrato de origem:** o Boundary 6 §§20–22 estabelece indicadores em eixos municipais/temporais com grãos e papéis distintos; Boundary 7 §§20–22 mantém população em `município×ano` e capacidade como `CNES×COMPETEN×CODLEITO`, com `Null()` em coordenadas não aplicáveis. A bateria física S0–S5 confirmou que a população anual desaparece sob seleção de competência mensal e que LT desaparece sob filtro de município de residência. Não reabrir a primeira entrega acadêmica, não replicar população 12 vezes nem substituir NULL por chave artificial.

**FATO TÉCNICO OFICIAL — QlikView Set Analysis:** um modificador `{$<CAMPO=>}` limpa a seleção somente do campo nomeado, preservando as demais seleções do estado `$`; um modificador `CAMPO={2019}` impõe o ano 2019 nesse cálculo. Documentação QlikView: https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-modifiers.htm e https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/ChartFunctions/SetAnalysis/set-analysis-expressions.htm .

**HIPÓTESE DE MODELAGEM (não aprovada e sem execução no QlikView):** a seleção mensal que excluiu `P6_POP_ROW_DEBUG` pode permitir uma **expressão de contagem anual** independente apenas do mês, preservando o município de serviço:

```qlik
Count({$<P6_COMP_COMPETENCIA=, P6_ANO_ANO={2019}>} P6_POP_ROW_DEBUG)
```

**Esta expressão só testa a presença de uma linha técnica POP**; NÃO lê `POPULACAO_ESTIMADA`, não calcula pessoas nem é um denominador já aprovado. O `2019` **é literal de teste**, intencionalmente fixo; em produção o ano teria de derivar de maneira validada das seleções com casos de zero, um ou múltiplos anos. A expressão deve usar `$`, não `{1}`, pois o conjunto universal ignoraria também o município escolhido.

**PROTOCOLO DE VERIFICAÇÃO READ-ONLY no mesmo QVW temporário retido:** adicionar um **novo objeto Text Object** no QlikView Desktop, com a seguinte expressão, sem editar script de carga e sem recarregar dados:

```qlik
='RD=' & Count(P6_RD_ROW_DEBUG)
 & ' | LT=' & Count(P6_LT_ROW_DEBUG)
 & ' | POP_NORMAL=' & Count(P6_POP_ROW_DEBUG)
 & ' | POP_SEM_MES_ANO2019=' & Count({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={2019}>} P6_POP_ROW_DEBUG)
```

Antes de cada cenário, limpar todas as seleções no próprio QVW. **Expectativas são apenas hipóteses até saída observada:**

| Cenário | Seleções explícitas | POP_NORMAL já observado | POP_SEM_MES_ANO2019 — hipótese |
| --- | --- | ---: | ---: |
| E0 | nenhuma | 669 | 223 (uma linha por município em 2019) |
| E1 | competência `201909` apenas | 0 | 223 (ano 2019 imposto, competência ignorada apenas no objeto) |
| E2 | serviço `250750` e ano `2019` | 1 | 1 |
| E3 | serviço `250750`, competência `201909` e ano `2019` | ainda não medido nesta combinação | 1 |

**Fail closed:** não declarar `SET_ANALYSIS_DENOMINATOR=PASS` antes de receber as quatro saídas/capturas. Se `POP_SEM_MES_ANO2019` for 0, 669 ou outro valor inesperado, investigar a propagação associativa e o estado efetivo das seleções. Não inferir que remover a competência sempre recupera o denominador correto; a estratégia NÃO define filtros de residência versus serviço, estrutura de medidas populacionais, casos múltiplos municípios/anos ou comparação com snapshots LT.

**Próximos contratos depois desse experimento técnico:** (a) fontes reais de `POPULACAO_ESTIMADA` com ano×município; (b) `QTD_INTERNACAO` já reconciliada em staging, respeitando `IDENT=5`, mas ainda sem QVD de fato; (c) `QT_SUS`/`QT_EXIST` a partir da fonte LT, preservando competência, CNES, tipo e regras de semi-aditividade. Somente então testar numeradores/denominadores reais no mesmo escopo territorial, com resultados anuais independentes por município e limites de T29 expostos.

**DECISÃO PENDENTE:** `S0_S5_FILTER_GATE=COMPLETE_WITH_LIMITATIONS`; `SET_ANALYSIS_2019_POP_DEBUG_TEST=PREPARED_NOT_RUN`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PHYSICAL_ASSOCIATIVE_MODEL=PARTIAL_PREFLIGHT_ONLY`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. Draft PR #83 permanece sem merge.

---

## 29. E5 — validação física de população real no modelo associativo (14/10/2026)

**FATO VERIFICADO — saída do executor PowerShell e log nativo QlikView 12 fornecidos pelo responsável (14/10/2026, 12:06:57 em UTC-03).**

Branch de teste: `feat/phase-5-fato-internacao-contract-discovery`, PR #83 Draft, sem merge. O responsável executou `git pull --ff-only` até `2839d35` e rodou:

```powershell
$assoc = 'C:\Users\pedro\AppData\Local\Temp\SAD_P6_ASSOC_PREFLIGHT_07355503816541ddbed257b795d42ea2\P6_ASSOC_LINK_IN_MEMORY.qvw'
& .\tools\validar_denominador_populacional_e5_qlik.ps1 -AssocQvw $assoc
```

O runner versionado (`tools/validar_denominador_populacional_e5_qlik.ps1`) injeta `TRANSFORMACAO/phase_vi_e5_population_denominator_preflight.qvs` em QVW descartável, usando `BINARY` sobre o QVW associativo de nove tabelas e fazendo `LEFT JOIN` exclusivamente em memória na projeção de 669 linhas POP. **Não gera QVDs, não altera os QVDs de staging, não constrói fatos definitivos, não aprova o contrato de `%LINK_KEY`.**

Saída apresentada:

```text
MODE=PHASE_VI_POP_DENOMINATOR_READ_ONLY_PREFLIGHT
SOURCE_ASSOC_QVW_SHA256=9854A42B70EBB75F2256F44CB97CC1B2601DF9F334CB93530DABE01D28B5CDCF
RELOAD_STARTED=True
RELOAD_RETURNED=True
ALL_INPUT_SHA256_UNCHANGED=True
[P6-E5] ROWS=669 KEYS=669 INVALID=0
[P6-E5] PB_2017=4025558 PB_2018=3996496 PB_2019=4018127
[P6-E5] JP_2017=811598 JP_2018=800323 JP_2019=809015
[P6-E5] TABLES=9 SYNTHETIC=0
[P6-E5] VERDICT=PASS_IN_MEMORY_POP_VALUES_PRESELECTION_NOT_APPROVED
[P6-E5] MONTHLY_DENOMINATOR_SELECTION=NOT_TESTED
OUTPUT_QVDS_WRITTEN=0
FACT_QVDS_GENERATED=False
LINK_ANALISE_QVD_GENERATED=False
LINK_KEY_CONTRACT=NOT_APPROVED
VERDICT=PASS_IN_MEMORY_POP_VALUES_PRESELECTION_NOT_APPROVED
```

O QVW retido para inspeção visual pelo executor foi:

```text
C:\Users\pedro\AppData\Local\Temp\SAD_P6_E5_DENOMINATOR_e3448ab42006474f86325b9d25935d19\P6_E5_POP_DENOMINATOR_IN_MEMORY.qvw
```

Este caminho em `%TEMP%` é transitório, não arquivo canônico. A saída é evidência local reportada pelo responsável; não equivale a execução independente do agente. O teste físico de **presença e valores anuais reais** passou em memória, inclusive a reconciliação dos totais PB e das estimativas de João Pessoa, mas **nenhum filtro mensal foi executado neste QVW E5**.

**Próximo gate — E5 SELECTION, NÃO EXECUTADO:** no QVW retido, limpar seleções e testar `P6_SERV_DATASUS_6=250750`, `P6_ANO_ANO=2018` e `P6_COMP_COMPETENCIA=201809`, comparando `RangeSum(Sum(P6_POP_HABITANTES_E5))` contra `RangeSum(Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5))` e `RangeSum(Sum({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={2019}>} P6_POP_HABITANTES_E5))`. Referências anuais para a cidade: 2018 = 800323 e 2019 = 809015; expectativas após filtros são **hipóteses**, não resultados. Exigir captura dos filtros e valores retornados; repetir para 2019 somente se primeiro caso estiver coerente. Não extrapolar para residência, múltiplos municípios/anos ou medidas SIH/CNES sem baterias próprias.

**Estado:** `E5_POP_REAL_PRESELECTION=PASS_LOCAL_LOG_REPORTED`; `E5_MONTHLY_SELECTION=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`.

---

## 30. E5 — filtro mensal 201809, João Pessoa/serviço (14/10/2026)

**FATO VERIFICADO — captura fornecida pelo responsável do QVW E5 aberto no QlikView 12.** Os três campos abaixo aparecem com seleção verde simultânea:

- `P6_SERV_DATASUS_6=250750` — município de serviço João Pessoa;
- `P6_ANO_ANO=2018`;
- `P6_COMP_COMPETENCIA=201809`.

O objeto de texto calculado apresentou:

```text
NORMAL=0 | ANUAL=800323 | FIXO_2019=809015
```

As fórmulas solicitadas e observadas eram, respectivamente:

```qlik
RangeSum(Sum(P6_POP_HABITANTES_E5))
RangeSum(Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5))
RangeSum(Sum({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={2019}>} P6_POP_HABITANTES_E5))
```

**Interpretação estrita:** o filtro mensal retirou a população anual do cálculo associativo normal; o modificador que limpa somente a competência recuperou **800.323 habitantes do mesmo município/ano selecionados** neste cenário; o modificador que impõe literalmente 2019 retornou **809.015 habitantes**, valor do ano incorreto para uma seleção de 2018. Resultado coerente com o staging IBGE e com o gate E5 de medidas reais em memória (§29).

**Gate parcial:** `E5_MONTHLY_SELECTION_JP_2018_201809=PASS_VISUAL`. A observação **não** aprova um denominador genérico, seleção dinâmica sem ano explícito, múltiplos municípios/anos, município de residência, números de internações ou snapshots de leitos. A regra `SAD-LINK-V1`, os fatos definitivos e a Link Table persistida permanecem **não aprovados/não implementados**.

**Próximo ensaio manual, ainda não executado:** limpar todas as seleções, escolher município serviço `250750`, ano `2019` e competência `201909` e verificar `NORMAL=0`, `ANUAL=809015`, `FIXO_2019=809015`. Esses valores são **expectativas** até receber a captura. Não recarregar nem alterar script/QVD para esse ensaio.

**Estado:** `E5_POP_REAL_PRESELECTION=PASS_LOCAL_LOG_REPORTED`; `E5_MONTHLY_SELECTION_JP_2018_201809=PASS_VISUAL`; `E5_MONTHLY_SELECTION_JP_2019_201909=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `T29_HISTORICAL=NOT_APPROVED`.


---

## 31. E5 — filtro mensal 201909, João Pessoa/serviço (14/10/2026)

**FATO VERIFICADO — captura do QlikView Desktop 12 fornecida pelo responsável.** No mesmo QVW experimental E5 utilizado para 2018, três seleções aparecem simultaneamente em verde:

- `P6_SERV_DATASUS_6=250750` — município de serviço João Pessoa;
- `P6_ANO_ANO=2019`;
- `P6_COMP_COMPETENCIA=201909`.

O objeto de texto retornou:

```text
NORMAL=0 | ANUAL=809015 | FIXO_2019=809015
```

A expressão `ANUAL` era `RangeSum(Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5))`. `FIXO_2019` usava `RangeSum(Sum({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={2019}>} P6_POP_HABITANTES_E5))`. O `NORMAL=0` é a apresentação numérica por `RangeSum` de uma soma sem população disponível após selecionar a competência; **não** afirma que a população real do município seja zero.

A soma anual recuperada (**809.015 habitantes**) reconcilia com a referência IBGE 2019 já verificada na carga E5 (ver §29). Em conjunto com o caso 2018 `250750+2018+201809` (§30: `NORMAL=0`, `ANUAL=800323`, `FIXO_2019=809015`), confirma que a candidata `CAMPO_COMPETENCIA=` recupera a população do **mesmo município e ano explicitamente selecionados** em dois cenários mensais distintos.

**Gate de observação:** `E5_MONTHLY_SELECTION_JP_2019_201909=PASS_VISUAL`. **Ainda não aprovado:** contrato de denominador genérico, ano inferido de mês sem seleção explícita, múltiplos anos/municípios, papel de residência, demais indicadores SIH/CNES, modelo físico definitivo ou `SAD-LINK-V1`. O PR #83 permanece Draft. Nenhum QVD factual ou Link Table QVD foi produzido nesta etapa.

**Próximo teste mínimo recomendado, NÃO EXECUTADO:** limpar seleções e testar município de serviço `250750` + ano `2017` + competência `201709`, esperando apenas hipoteticamente `NORMAL=0`, `ANUAL=811598`, `FIXO_2019=809015`. Após ele, priorizar seleção sem ano explícito e um segundo município antes de discutir qualquer contrato reutilizável. Não modificar fontes, script QVS ou snapshots LT.

**Estado:** `E5_POP_REAL_PRESELECTION=PASS_LOCAL_LOG_REPORTED`; `E5_MONTHLY_SELECTION_JP_2018_201809=PASS_VISUAL`; `E5_MONTHLY_SELECTION_JP_2019_201909=PASS_VISUAL`; `E5_MONTHLY_SELECTION_JP_2017_201709=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `T29_HISTORICAL=NOT_APPROVED`.

---

## 32. E5 — filtro mensal 201709, João Pessoa/serviço (14/10/2026)

**FATO VERIFICADO — captura do QlikView Desktop 12 fornecida pelo responsável.** Estão simultaneamente selecionados em verde:

- `P6_SERV_DATASUS_6=250750` (município de serviço João Pessoa);
- `P6_ANO_ANO=2017`;
- `P6_COMP_COMPETENCIA=201709`.

O objeto de texto do teste E5 apresentou:

```text
NORMAL=0 | ANUAL=811598 | FIXO_2019=809015
```

O valor `ANUAL=811598` corresponde exatamente à população municipal de João Pessoa para 2017, já reconciliada diretamente com o QVD de staging no §29. O comparativo `FIXO_2019=809015` reforça que fixar o ano de 2019 não é solução genérica. O valor `NORMAL=0` decorre do recorte associativo mensal em que a fato POP não possui competência aplicável; não significa ausência de população.

**Três ensaios manuais com ano explicitamente selecionado concluídos com PASS VISUAL:** 2017/201709 `ANUAL=811598` (§32), 2018/201809 `ANUAL=800323` (§30) e 2019/201909 `ANUAL=809015` (§31). Os três testes usam **somente município de serviço João Pessoa**. A recuperação pela expressão de Set Analysis que remove a seleção de `P6_COMP_COMPETENCIA` é comprovada para estes três recortes, não para o conjunto completo de cenários de uso.

**Próximo gate, NÃO EXECUTADO:** limpar todas as seleções; selecionar **somente** `P6_SERV_DATASUS_6=250750` e `P6_COMP_COMPETENCIA=201809`, deixando `P6_ANO_ANO` **sem seleção explícita**. Observar `NORMAL`, `ANUAL`, `FIXO_2019`, além do estado de seleção do ano. O resultado de `ANUAL` é intencionalmente tratado como desconhecido até captura. A finalidade é verificar se limpar a competência ainda preserva o ano analítico quando este não foi explicitamente selecionado. Não presumir que o resultado seja 800323. Reconciliar com staging e registrar implicações antes de considerar derivação de ano ou fórmula genérica.

**Estado:** `E5_MONTHLY_SELECTION_JP_2017_201709=PASS_VISUAL`; `E5_MONTHLY_SELECTION_JP_2018_201809=PASS_VISUAL`; `E5_MONTHLY_SELECTION_JP_2019_201909=PASS_VISUAL`; `E5_MONTH_ONLY_WITHOUT_EXPLICIT_YEAR=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 continua Draft, sem merge.

---

## 33. E5 — competência mensal sem ano explícito, João Pessoa/serviço (14/10/2026)

**FATO VERIFICADO — captura do QlikView Desktop 12 fornecida pelo responsável:** em QVW temporário E5 com valores populacionais reais, apenas `P6_SERV_DATASUS_6=250750` (João Pessoa/serviço) e `P6_COMP_COMPETENCIA=201809` aparecem em verde. O objeto `P6_ANO_ANO` não apresenta ano selecionado explicitamente (nenhum valor em verde).

O texto calculado apresenta:

```text
NORMAL=0 | ANUAL=2420936 | FIXO_2019=809015
```

O valor `ANUAL=2420936` é precisamente `811598 (2017) + 800323 (2018) + 809015 (2019)`: após limpar apenas a competência no Set Analysis, o modelo recupera **todos os três anos** da população municipal, não somente o ano 2018 implícito na competência `201809`. `NORMAL=0` decorre da ausência de competência mensal na população anual; `FIXO_2019=809015` confirma a fixação indevida em outro ano.

**CONCLUSÃO SEMÂNTICA / CONTRAEXEMPLO FÍSICO:** a expressão candidata `Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5)` **não é um denominador genérico correto** quando uma competência é selecionada sem ano explícito. Os PASSs dos §§30–32 continuam válidos apenas sob seleção explícita do ano. Não corrigir ampliando o grão da população ou multiplicando linhas em 12 competências.

**Próximo teste mínimo — diagnóstico de ano derivado do filtro mensal, NÃO EXECUTADO:** manter `P6_SERV_DATASUS_6=250750` e `P6_COMP_COMPETENCIA=201809` sem escolher ano. Em objeto novo, examinar `Only(P6_COMP_COMPETENCIA)`, `Left(Text(Only(P6_COMP_COMPETENCIA)),4)` e `GetSelectedCount(P6_COMP_COMPETENCIA)`, sem alterar script ou dados. Se for possível derivar o ano univocamente, avaliar **separadamente** uma expressão experimental cujo `P6_ANO_ANO` corresponda ao ano derivado, e exigir o total 800323 em João Pessoa/2018. Exigir recusa explícita de filtros de competências múltiplos, competências incompatíveis, ano conflitante e ausência de seleção antes de aprovar. Essa candidata não é ainda decisão arquitetural.

**Estado:** `E5_MONTH_ONLY_WITHOUT_EXPLICIT_YEAR=FAIL_SEMANTIC_OBSERVED`; `E5_SINGLE_MONTH_YEAR_DERIVATION=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 mantém Draft sem merge.

---

## 34. E6 — derivação do ano a partir de competência única (14/10/2026)

**FATO VERIFICADO — captura do QlikView Desktop 12 enviada pelo responsável.** No mesmo QVW experimental E5, sem alteração ou recarga, foram mantidas somente as seleções `P6_SERV_DATASUS_6=250750` e `P6_COMP_COMPETENCIA=201809`, sem seleção explícita em `P6_ANO_ANO`.

Novo objeto de texto calculado:

```qlik
='QTD_COMP=' & GetSelectedCount(P6_COMP_COMPETENCIA)
& ' | COMP=' & Only(P6_COMP_COMPETENCIA)
& ' | ANO_DERIVADO=' & Left(Text(Only(P6_COMP_COMPETENCIA)),4)
```

Resultado observado no objeto:

```text
QTD_COMP=1 | COMP=201809 | ANO_DERIVADO=2018
```

**Gate de diagnóstico `E6_SINGLE_COMPETENCE_YEAR_DERIVATION=PASS_VISUAL`.** Foi demonstrado que a seleção explícita de uma competência admite ano textual inequívoco nesse caso. Isso ainda não verifica aplicação do ano como modificador do conjunto POP; o contraexemplo E5 (`ANUAL=2420936`) permanece válido para a expressão que apenas limpa competência.

**Candidata para próximo ensaio manual (NÃO EXECUTADA, sem produção):** com as mesmas seleções e apenas um objeto de texto, comparar `ANUAL=2420936` com a expressão experimental de Set Analysis `RangeSum(Sum({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={$(=Left(Text(Only(P6_COMP_COMPETENCIA)),4))}>} P6_POP_HABITANTES_E5))`. Hipótese para `DINAMICO`: 800323; verificar se a expansão de dólar entrega 2018 no QlikView 12 real. Preservar `ANUAL` para o diagnóstico e reportar qualquer erro de sintaxe em vez de corrigir sem evidência.

**LIMITES / DECISÕES PENDENTES:** uma competência selecionada por vez; nenhum ano explicitamente selecionado; nenhum suporte comprovado a seleção de meses múltiplos (mesmo ano ou anos distintos), filtros municipais múltiplos, residência, conflitos ano×mês ou medidas SIH/CNES. Qualquer regra genérica precisa de testes fail-closed adicionais. Não alterar granularidade de POP nem `SAD-LINK-V1`, não gerar QVD factual, não fazer merge do PR #83. `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `T29_HISTORICAL=NOT_APPROVED`.

---

## 35. E7 — denominador dinâmico de competência única sem ano selecionado (14/10/2026)

**FATO VERIFICADO — captura de QlikView Desktop 12 fornecida pelo responsável.** No QVW descartável E5 (mesmo modelo associativo em memória) estão selecionados em verde somente `P6_SERV_DATASUS_6=250750` (município de serviço de João Pessoa) e `P6_COMP_COMPETENCIA=201809`; nenhum valor de `P6_ANO_ANO` está selecionado em verde.

O objeto experimental de Set Analysis com *dollar-sign expansion*:

```qlik
='DINAMICO=' &
RangeSum(
    Sum({
        $<
            P6_COMP_COMPETENCIA=,
            P6_ANO_ANO={$(=Left(Text(Only(P6_COMP_COMPETENCIA)),4))}
        >
    } P6_POP_HABITANTES_E5)
)
```

retornou **`DINAMICO=800323`**, exatamente o valor de habitantes de João Pessoa/2018 reconciliado no staging. Simultaneamente, os objetos anteriores permaneceram com `NORMAL=0`, `ANUAL=2420936`, `FIXO_2019=809015`, e o diagnóstico E6 mostrava `QTD_COMP=1`, `COMP=201809`, `ANO_DERIVADO=2018`.

**Gate:** `E7_DYNAMIC_POP_JP_SERVICE_201809_SINGLE_COMP=PASS_VISUAL`. A observação comprova somente que uma competência explicitamente selecionada, sem filtro explícito de ano, pode determinar por expressão o denominador correto **neste recorte**. O Set Analysis sem derivação de ano continua semanticamente incorreto neste mesmo recorte.

**Limitação — não generalizar:** não há validação para nenhum/múltiplos meses, múltiplos anos, outros municípios, filtros de residência, conflito de ano versus competência nem composição com medidas RD/LT. Além disso, `RangeSum` pode exibir `0` quando não há soma válida; uma expressão definitiva deverá retornar estado sem denominador/erro controlado em seleções inválidas, não confundir isso com zero habitantes.

**Próximo ensaio físico mínimo (NÃO EXECUTADO):** limpar tudo, selecionar município de serviço `250750`, e selecionar simultaneamente duas competências de **mesmo ano** (`201808` e `201809`), deixando `P6_ANO_ANO` sem seleção explícita. Registrar `GetSelectedCount(P6_COMP_COMPETENCIA)`, `Only(P6_COMP_COMPETENCIA)`, ano derivado e o objeto `DINAMICO` atual, sem modificar script. Não antecipar resultado do objeto: a finalidade é caracterizar como o mecanismo lida com seleção mensal múltipla. Uma política de aceitar/rejeitar seleção de múltiplos meses requer decisão explícita, distinguindo meses no mesmo ano de meses em anos diferentes.

**Estado:** `E7_DYNAMIC_POP_JP_SERVICE_201809_SINGLE_COMP=PASS_VISUAL`; `E7_MULTIPLE_COMPETENCES=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 segue Draft, sem merge.

---

## 36. E8 — duas competências do mesmo ano sem ano explícito (14/10/2026)

**FATO VERIFICADO — captura QlikView Desktop 12 fornecida pelo responsável:** município de serviço `P6_SERV_DATASUS_6=250750`, competências `201808` e `201809` simultaneamente selecionadas (ambas verdes), sem seleção explícita de `P6_ANO_ANO`. Mesmo QVW em memória; sem recarga de fonte.

Resultados observados:

~~~text
NORMAL=0 | ANUAL=2420936 | FIXO_2019=809015
QTD_COMP=2 | COMP= | ANO_DERIVADO=
DINAMICO=0
~~~

**Interpretação:** `Only(P6_COMP_COMPETENCIA)` deixa de retornar uma competência única quando dois meses estão selecionados. Consequentemente, o ano derivado da expressão E7 desaparece e `DINAMICO=0` aparece porque o objeto experimental envolve a soma em `RangeSum()`. Esse zero **não equivale a zero habitantes**. O resultado `ANUAL=2420936` permanece a soma populacional indevida de João Pessoa dos anos 2017–2019. A população de referência de 2018 para o município é 800323.

**Gate:** `E8_SAME_YEAR_TWO_COMPETENCES_201808_201809=FAIL_SEMANTIC_OBSERVED` **para a candidata E7 dependente de `Only(COMPETENCIA)`**, e não para qualquer alternativa ainda não testada. Manter a população no grão município×ano; não replicar por competência.

**Próximo teste mínimo, diagnóstico NÃO EXECUTADO:** com as mesmas seleções, criar um único objeto Text Object:

~~~qlik
='QTD_COMP=' & GetSelectedCount(P6_COMP_COMPETENCIA)
& ' | MES_MIN=' & MinString(P6_COMP_COMPETENCIA)
& ' | MES_MAX=' & MaxString(P6_COMP_COMPETENCIA)
& ' | ANO_MIN=' & Left(Text(MinString(P6_COMP_COMPETENCIA)),4)
& ' | ANO_MAX=' & Left(Text(MaxString(P6_COMP_COMPETENCIA)),4)
~~~

A expectativa **hipotética** é identificar `QTD_COMP=2` e um ano comum `2018`; deve ser confirmada fisicamente. Depois, antes de generalizar, testar o conflito `201809` + `201909`, ano explícito incompatível e ausência de seleções, com tratamento fail-closed. Não aprovar denominador genérico nem alterar contrato físico nesta etapa.

**Estado:** `E8_SAME_YEAR_TWO_COMPETENCES=FAIL_SEMANTIC_E7`; `E8_MIN_MAX_YEAR_DIAGNOSTIC=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft, sem merge.

---

## 37. E9 — ano comum detectado em duas competências de 2018 (14/10/2026)

**FATO VERIFICADO — captura QlikView Desktop 12 fornecida pelo responsável:** seleção de município de serviço `P6_SERV_DATASUS_6=250750`, duas competências `201808` e `201809` (ambas em verde) e **nenhum ano explicitamente selecionado em `P6_ANO_ANO`**. O objeto experimental E9, com `MinString(P6_COMP_COMPETENCIA)` e `MaxString(P6_COMP_COMPETENCIA)`, apresentou:

~~~text
QTD_COMP=2 | MES_MIN=201808 | MES_MAX=201809 | ANO_MIN=2018 | ANO_MAX=2018
~~~

Os objetos prévios continuaram mostrando `NORMAL=0`, `ANUAL=2420936`, `FIXO_2019=809015` e `DINAMICO=0` (este último não representa zero habitantes).

**Interpretação estrita:** para essas duas competências distintas, a comparação dos quatro primeiros dígitos dos extremos detectou ano comum `2018`. `E9_SAME_YEAR_MIN_MAX_DIAGNOSTIC=PASS_VISUAL`. **Não** foi testado ainda um denominador que use o ano comum, nem o caso de competência cruzando anos. O fato de extrema lexical funcionar para seis dígitos `YYYYMM` no recorte inspecionado não elimina a necessidade de validar formato/seleções conflitantes antes do contrato genérico.

**Próximo ensaio físico isolado — NÃO EXECUTADO (candidata com recusa de ano ambíguo):** mantendo as mesmas seleções, adicionar objeto de texto calculado contendo:

~~~qlik
='E10_POP=' &
If(
    GetSelectedCount(P6_COMP_COMPETENCIA) > 0
    and Left(Text(MinString(P6_COMP_COMPETENCIA)),4)
        = Left(Text(MaxString(P6_COMP_COMPETENCIA)),4),
    Sum({$<
        P6_COMP_COMPETENCIA=,
        P6_ANO_ANO={$(=Left(Text(MinString(P6_COMP_COMPETENCIA)),4))}
    >} P6_POP_HABITANTES_E5),
    'SEM_ANO_UNICO'
)
~~~

**Hipótese E10 sob serviço `250750` + meses `201808`/`201809`:** `E10_POP=800323` (valor de João Pessoa em 2018), sem repetir a população para cada mês. A recusa textual é proposta experimental e não constitui ainda contrato de erro do painel. Após confirmar E10, testar seleções de anos distintos (`201809` e `201909`) para exigir `SEM_ANO_UNICO` e nenhum valor populacional agregado. Também são pendentes validações de ausência de seleção, ano explícito conflitante, residência, múltiplos municípios e generalidade da expressão. Evitar `RangeSum` que mascararia nulos como zero.

**Estado:** `E9_SAME_YEAR_MIN_MAX_DIAGNOSTIC=PASS_VISUAL`; `E10_MULTI_MONTH_SAME_YEAR_DENOMINATOR=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft, sem merge.

---

## 38. E10 — denominador anual com duas competências do mesmo ano (14/10/2026)

**FATO VERIFICADO — captura do QlikView Desktop 12 fornecida pelo responsável.** O mesmo QVW de diagnóstico E5 mantém município de serviço `P6_SERV_DATASUS_6=250750` (João Pessoa) e duas competências selecionadas em verde, `201808` e `201809`, sem seleção explícita do campo `P6_ANO_ANO`.

O objeto E9 confirma `QTD_COMP=2`, `MES_MIN=201808`, `MES_MAX=201809`, `ANO_MIN=2018` e `ANO_MAX=2018`. O novo objeto E10, previamente especificado no §37 para só calcular quando houver competência selecionada e anos extremos iguais, retornou:

~~~text
E10_POP=800323
~~~

O resultado coincide com a população estimada de João Pessoa para 2018, reconciliada previamente com `SRC_IBGE_POPULACAO.qvd`. Os controles mantiveram `NORMAL=0`, `ANUAL=2420936`, `FIXO_2019=809015` e `DINAMICO=0`; o último é apenas efeito da candidata E7 baseada em `Only(COMPETENCIA)` e não representa zero habitantes.

**Gate restrito:** `E10_TWO_MONTH_SAME_YEAR_JP_SERVICE=PASS_VISUAL`. Foi demonstrada recuperação do denominador município×ano com dois meses de 2018 **sem duplicar população**, somente neste município/papel e sem filtro explícito de ano. Isso **não prova** a validade genérica nem um modelo físico definitivo.

**Próxima ação mínima, NÃO EXECUTADA:** sem mudar a fórmula E10, limpar todas as seleções; selecionar município de serviço `250750` e competências de **anos diferentes** (`201809` e `201909`); deixar ano sem seleção explícita. Observar se o E9 revela `ANO_MIN=2018` e `ANO_MAX=2019` e, sobretudo, se **E10_POP=SEM_ANO_UNICO**, recusando o cálculo de população. Não presumir um resultado antes da captura.

**Limitações ainda pendentes:** sem competências selecionadas, mês×ano explicitamente incompatíveis, outros municípios/seleções territoriais, filtros de residência, totais de múltiplos municípios, valor nulo ou inexistente de população, medidas SIH/RD (respeitar `IDENT=5`) e snapshots CNES/LT (semi-aditividade e `T29_HISTORICAL=NOT_APPROVED`). Recomenda-se consolidar os testes restantes em **matriz automatizada e versionada PowerShell/QlikView 12** após validar a recusa entre anos, evitando repetir manualmente as 223 localidades sem critérios. Os Capítulos 1–2 e arquitetura previamente aprovada permanecem intactos.

**Estado:** `E10_TWO_MONTH_SAME_YEAR_JP_SERVICE=PASS_VISUAL`; `E10_CROSS_YEAR_SELECTION=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft sem merge.

---

## 39. E11 — bloqueio de seleção de competências em anos distintos (14/10/2026)

**FATO VERIFICADO — captura QlikView Desktop 12 fornecida pelo responsável.** Mesmo QVW experimental E5, somente município de serviço `P6_SERV_DATASUS_6=250750` e competências `201809` e `201909` selecionadas em verde. Não há ano explicitamente selecionado em `P6_ANO_ANO`.

Objetos exibem:

~~~text
QTD_COMP=2 | MES_MIN=201809 | MES_MAX=201909 | ANO_MIN=2018 | ANO_MAX=2019
E10_POP=SEM_ANO_UNICO
NORMAL=0 | ANUAL=2420936 | FIXO_2019=809015
DINAMICO=0
~~~

**FATO VERIFICADO / E11:** a expressão E10 validada anteriormente em mesmo ano (§38) recusou calcular população para competências que cruzam 2018/2019, retornando literalmente `SEM_ANO_UNICO`. Isto é comportamento de bloqueio semântico adequado ao teste, **não aprovação definitiva** de tratamento de filtros inválidos na apresentação. Os valores `ANUAL=2420936` e `FIXO_2019=809015` seguem apenas como contraexemplos diagnósticos, não denominadores permitidos neste cenário.

**Gates restritos:** `E10_TWO_MONTH_SAME_YEAR_JP_SERVICE=PASS_VISUAL`; `E11_CROSS_YEAR_COMPETENCE_GUARD=PASS_VISUAL`. A lógica de `MinString`/`MaxString` com verificação de ano igual atende os dois recortes observados, mas faltam verificações de nulos, formato, seleção ano×competência conflitante, comportamento sem mês, municípios diferentes ou múltiplos, papéis residência/serviço e significado de inexistência de população.

**Próxima etapa recomendada (NÃO EXECUTADA):** substituir o ciclo repetitivo de objetos manuais por uma **matriz de regressão versionada**, usando a ferramenta QlikView 12 e o runner PowerShell existente como base, sem modificar fontes ou gerar QVD. Antes de automatizar seleções associativas COM, fazer Discovery dos métodos realmente acessíveis no Windows/QlikView 12. A matriz deve incluir: (a) sem seleção; (b) uma competência; (c) duas competências mesmo ano; (d) duas competências anos diferentes; (e) seleção explícita de ano compatível; (f) ano explícito incompatível; (g) município de serviço diferente e conjuntos múltiplos; (h) município de residência; (i) população ausente/nula e situações sem denominador. **Falhar fechado** onde houver ambiguidade e evitar tratar `RangeSum=0` como zero habitantes. Não aprovar física `SAD-LINK-V1`, fatos, ou indicador por habitante antes dos respectivos gates.

**Estado:** `E11_CROSS_YEAR_COMPETENCE_GUARD=PASS_VISUAL`; `E5_TO_E11_SELECTION_MATRIX=PARTIAL_VISUAL_ONLY`; `AUTOMATED_SEMANTIC_REGRESSION=NOT_STARTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. Draft PR #83 sem merge.

---

## 40. E12 — inspeção automatizável da interface QlikView COM (PREPARADA)

A inspeção de capacidades de seleções associativas por QlikView COM foi preparada, mas ainda **NÃO EXECUTADA** em Windows/QlikView 12.

**Script experimental versionado:** `tools/inspecionar_qlik_com_e12_readonly.ps1`. Este executor recebe o caminho de uma **cópia salva do QVW E5 fora de `%TEMP%` e do repositório**, abre-a pelo objeto COM `QlikTech.QlikView` e enumera métodos/propriedades do aplicativo, do documento e dos campos `P6_COMP_COMPETENCIA`, `P6_ANO_ANO`, `P6_SERV_DATASUS_6`, `P6_RES_DATASUS_6`. Não chama métodos de seleção, recarga, Save nem STORE; compara SHA-256 do QVW antes e depois e falha se mudar. Como a abertura de documento Qlik pode envolver comportamento de instalação/segurança, preferir documento já salvo/fechado e usar cópia descartável. O script ainda não teve execução física e sua utilidade diagnóstica depende dos membros realmente expostos.

**Execução futura em PowerShell (somente após salvar a cópia):**

~~~powershell
& .\tools\inspecionar_qlik_com_e12_readonly.ps1 -Qvw 'C:\Users\pedro\Documents\SAD_P6_E5_POP_SEMANTICS_COPY.qvw'
~~~

**Objetivo:** descobrir métodos COM reais para criar posteriormente a matriz E12+ de seleções e avaliações, sem inventar contrato de API nem modificar o QVW experimental usado no E5–E11. Não criar ainda runner de automação de seleções não verificadas.

**Estado:** `E11_CROSS_YEAR_COMPETENCE_GUARD=PASS_VISUAL`; `E12_COM_CAPABILITY_DISCOVERY=PREPARED_NOT_RUN`; `AUTOMATED_SEMANTIC_REGRESSION=NOT_STARTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft sem merge.

---

## 41. E12 — automação da cópia QVW para inspeção COM (14/10/2026)

**FATO VERIFICADO — saída PowerShell fornecida pelo responsável:** o primeiro E12 foi bloqueado antes da inspeção por `QVW_NOT_FOUND` em `C:\Users\pedro\Documents\SAD_P6_E5_POP_SEMANTICS_COPY.qvw`. O `git pull --ff-only` anterior foi concluído por fast-forward até `b360980`. Isso **não** é falha de Set Analysis, QlikView COM ou dados; o arquivo de destino ainda não existia.

**Implementação versionada de conveniência / NÃO EXECUTADA no Windows:** foi ampliado o próprio `tools/inspecionar_qlik_com_e12_readonly.ps1`, preservando o modo antigo `-Qvw` e adicionando `-SourceQvw`. Este último exige o nome original `P6_E5_POP_DENOMINATOR_IN_MEMORY.qvw`, valida existência/tamanho, copia o QVW salvo em disco para um arquivo único `SAD_P6_E5_POP_SEMANTICS_COPY_<GUID>.qvw` dentro da pasta Documentos do Windows (respeitando o redirecionamento do perfil), verifica SHA-256 do original e da cópia, e só então prossegue à introspecção COM existente. O arquivo fonte não recebe Save, Reload ou seleção; a cópia é o único QVW deliberadamente criado fora da pasta TEMP. Os QVDs, scripts externos e repositório locais não sofrem escrita pelo runner.

Comando a executar na branch do PR #83, após `git pull --ff-only`:

~~~powershell
& .\tools\inspecionar_qlik_com_e12_readonly.ps1 -SourceQvw 'C:\Users\pedro\AppData\Local\Temp\SAD_P6_E5_DENOMINATOR_e3448ab42006474f86325b9d25935d19\P6_E5_POP_DENOMINATOR_IN_MEMORY.qvw'
~~~

**Limitação de salvamento:** PowerShell copia o estado persistido no arquivo de origem, **não** objetos de texto, filtros ou propriedades ainda não salvos na sessão gráfica (asterisco no título). A descoberta E12 exige somente o modelo de dados já salvo pelo preflight e os nomes dos campos; preservar os objetos visuais E5–E11 requer salvar a sessão explicitamente antes de copiá-la. A cópia automática é insumo **diagnóstico**, não artefato canônico de produção.

**Gate:** `E12_AUTOCOPY_SCRIPT=VERSIONED_STATIC_ONLY`; `E12_COM_CAPABILITY_DISCOVERY=NOT_EXECUTED`; `AUTOMATED_SEMANTIC_REGRESSION=NOT_STARTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 Draft sem merge.

---

## 42. E12 COM PASS local e E13 smoke PREPARADO

**FATO VERIFICADO (saida PowerShell do responsavel, 14/10/2026):** o executor E12 com -SourceQvw criou uma copia automatica do QVW de diagnostico na pasta Documentos redirecionada ao OneDrive; hashes SHA-256 da copia/origem verificados e documento fonte inalterado. A COM confirmou os quatro campos requeridos e disponibilidade dos metodos ClearAll, Evaluate, GetField, Select, SelectValues, ToggleSelect e GetSelectedValues. Nao houve selecao, recarga, Save ou escrita de QVD durante E12. Gate E12: PASS_LOCAL_REPORTED.

**PENDENCIA:** COM GetTableCount retornou 12, mas o preflight Qlik Script NoOfTables havia conferido 9. A origem dessa diferenca deve ser investigada por inventario de nomes antes de fazer qualquer afirmacao sobre mudanca do modelo.

**NOVO E13:** o script versionado tools/validar_qlik_com_e13_smoke.ps1 foi preparado para criar uma copia descartavel do QVW E5, validar SHA-256 e executar em COM os tres casos anteriormente observados manualmente: 201809 sozinho (esperado 800323), 201808+201809 (esperado 800323) e 201809+201909 (esperado SEM_ANO_UNICO). O script tambem tenta enumerar nomes de tabelas COM. Uso somente de memoria: sem Save, Reload ou QVD gerado. **NAO EXECUTADO no Windows; nenhuma selecao automatizada aprovada.**

**Estado:** E12_COM_ENUMERATION=PASS_LOCAL_REPORTED; E12_TABLE_COUNT_DISCREPANCY=OPEN; E13_COM_SMOKE=VERSIONED_NOT_RUN; MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; LINK_KEY_CONTRACT=NOT_APPROVED; T29_HISTORICAL=NOT_APPROVED. PR #83 segue Draft.

---

## 43. E13 — falha inicial de baseline COM, diagnostico preparado

**FATO VERIFICADO — saida PowerShell do responsavel (14/10/2026):** apos git pull --ff-only ate 43f6091, foi executado o runner E13 na fonte P6_E5_POP_DENOMINATOR_IN_MEMORY.qvw (SHA-256 inicial F75786A88E7563B739492F2D2BC7C5CEA50D8C7F8E73F36770AA76960FB668C6). Foi criada a copia descartavel no diretório SAD_P6_E13_COM_a4478dcfd1134998acd9f02c35aa9d08 em TEMP. A primeira condicao combinada de baseline retornou E13_BASELINE=FAIL; o runner interrompeu em FAIL_CLOSED_BLOCKED_BASELINE_EXPECTED_PASS_GOT_FAIL.

**Importante:** nao ha evidencias de erros de selecao COM, nem regressao de denominador neste teste: o runner bloqueou **antes da primeira selecao**. A origem permanece SHA-256 intacta, sem Save, Reload ou escrita de QVD. A condicao de baseline exigia simultaneamente Count(P6_POP_ROW_DEBUG)=669 e Sum(P6_POP_HABITANTES_E5)=12040181; a saida nao apresentou as duas parcelas individualmente nem confirmou se havia selecao persistida no QVW copiado. **Causa raiz em aberto.**

**Mudanca de diagnostico versionada, NAO EXECUTADA no Windows:** o mesmo tools/validar_qlik_com_e13_smoke.ps1 agora lista nomes de tabelas COM antes do baseline, coleta contagens de selecoes carregadas, executa ClearAll somente na **copia descartavel**, confirma que selecoes de mes/ano/servico estao zeradas e registra, individualmente, Count, Sum e as comparacoes booleanas antes de reaplicar a mesma regra estrita do baseline. Qualquer divergencia bloqueia o smoke antes dos testes de selecao. Nao houve relaxamento dos valores esperados, nem alteracao nos QVDs ou no modelo aprovado.

**Estado:** E13_COM_BASELINE=FAIL_CLOSED_LOCAL_REPORTED; E13_BASELINE_ROOT_CAUSE=UNKNOWN; E13_DIAGNOSTIC_REVISION=VERSIONED_NOT_RUN; E13_SELECTION_SMOKE=NOT_TESTED; MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; LINK_KEY_CONTRACT=NOT_APPROVED; T29_HISTORICAL=NOT_APPROVED. PR #83 continua Draft sem merge.

---

## 44. E13 — smoke COM automatizado PASS local

**FATO VERIFICADO — saída PowerShell/QlikView 12 enviada pelo responsável, 14/10/2026.** Após `git pull --ff-only` até `30de18b`, o responsável executou `tools/validar_qlik_com_e13_smoke.ps1 -SourceQvw <P6_E5_POP_DENOMINATOR_IN_MEMORY.qvw>`. O executor criou somente uma cópia descartável `P6_E13_DISPOSABLE.qvw` em `%TEMP%` e interagiu com ela pela interface COM. A origem manteve o hash SHA-256 `F75786A88E7563B739492F2D2BC7C5CEA50D8C7F8E73F36770AA76960FB668C6`.

**Causa do bloqueio anterior (§43) identificada pelo ensaio:** o QVW original estava gravado com `GetSelectedCount(P6_COMP_COMPETENCIA)=2` e `GetSelectedCount(P6_SERV_DATASUS_6)=1` (ano/residência sem seleções). A condição inicial de E13 era avaliada sob essas seleções. `ClearAll()` somente na cópia descartável deixou contagens de competência, ano e município serviço em zero e restabeleceu o baseline: `Count(P6_POP_ROW_DEBUG)=669`, `Sum(P6_POP_HABITANTES_E5)=12040181`. Comparações booleanas retornaram `-1` (verdadeiro na representação numérica do Qlik) e a expressão combinada retornou `PASS`. Não houve relaxamento da expectativa.

**Três cenários automatizados concluídos (todos PASS):**

| Cenário COM (serviço João Pessoa) | Seleções | Resultado E10 | Gate |
|---|---|---:|---|
| Competência única | `201809`; sem seleção explícita do ano | `800323` | `E13_SINGLE_MONTH=PASS` |
| Competências do mesmo ano | `201808` e `201809`; ano sem seleção explícita | `800323` | `E13_SAME_YEAR=PASS` |
| Competências entre anos | `201809` e `201909`; ano sem seleção explícita | `SEM_ANO_UNICO` | `E13_CROSS_YEAR=PASS` |

A interface COM efetivamente executou `GetField().Select()`, `ToggleSelect()`, `ClearAll()` e `Document.Evaluate()`, conferindo `GetSelectedCount` em cada teste. Resultado final reportado: `VERDICT=PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED`; `SOURCE_SHA256_UNCHANGED=True`; `SAVE_EXECUTED=False`; `RELOAD_EXECUTED=False`; `QVD_WRITES=0`.

**Reconciliada a aparente discrepância de tabelas:** `GetTableCount()=12` listou as nove tabelas experimentais nomeadas `P6_LINK_SIMULADA`, `P6_DIM_COMP_SIMULADA`, `P6_DIM_ANO_SIMULADA`, `P6_DIM_RES_SIMULADA`, `P6_DIM_SERV_SIMULADA`, `P6_DIM_EST_SIMULADA`, `P6_FATO_RD_SIMULADA`, `P6_FATO_LT_SIMULADA`, `P6_FATO_POP_SIMULADA` e três entradas `$$SysTable 9`, `$$SysTable 10`, `$$SysTable 11`. Portanto, **não surgiram novas tabelas de negócio**; as três entradas adicionais possuem nome de tabela de sistema. A diferença de contagem COM vs. `NoOfTables()` não sustenta mudança da arquitetura. Sua natureza exata não foi investigada além do nome.

**Próximo gate sugerido, ainda NÃO EXECUTADO:** ampliar a matriz automatizada, com cópia descartável e verificação de origem, para (1) sem competência; (2) ano explícito compatível; (3) ano explícito incompatível com competência; (4) segundo município de serviço e múltiplos municípios; (5) filtro de residência, isolado e combinado; (6) seleções sem população aplicável. Separar indicadores de internação por residência e atividade hospitalar por serviço antes de decidir qualquer contrato universal. Manter tratamento fail-closed de vazio/ambiguidade, sem converter nulos em zero habitantes.

**Estado:** `E13_COM_SMOKE=PASS_LOCAL_REPORTED`; `E13_BASELINE_PRIOR_FAIL=RESOLVED_BY_CLEARALL`; `E13_COM_12_TABLES=9_BUSINESS_PLUS_3_SYS`; `E14_EXPANDED_SEMANTIC_REGRESSION=NOT_STARTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft sem merge.

---

## 45. E14 — matriz temporal COM opcional preparada

**HIPÓTESE / ENSAIO FUTURO (NÃO EXECUTADO no Windows):** sem introduzir outro runner, foi adicionada a flag PowerShell `-TemporalDiscovery` ao executor versionado `tools/validar_qlik_com_e13_smoke.ps1`. O modo padrão, com três cenários E13, permanece disponível e foi anteriormente validado (ver §44). O modo opcional executa esses mesmos gates e, somente após PASS, acrescenta quatro probes na **cópia descartável** do QVW, sempre limpando seleções entre casos: sem competência; somente ano 2018 com serviço 250750; ano 2018 + competência 201809 coerentes; ano 2019 + competência 201809 potencialmente incompatíveis.

A prova temporal diferencia **observação de seleção/resultado** de aprovação semântica. O último caso registra os valores efetivamente selecionados e o valor E10 sem presumir se a seleção conflitante será aceita, desfeita, rejeitada ou retornará um número incorreto. O caso de ano selecionado sem competência avalia a expressão E10, mas não decide que ela é o denominador correto de um indicador anual. Os testes conhecidos continuam fail-closed e `ClearAll()` opera somente na cópia descartável. Nenhum QVD é gravado; não há `Save` nem `Reload` no código.

**Comando experimental futuro, para execução local somente após atualizar a branch:**

```powershell
& .\tools\validar_qlik_com_e13_smoke.ps1 -SourceQvw '<CAMINHO_QVW_E5_JA_VERIFICADO>' -TemporalDiscovery
```

**Estado:** `E13_COM_SMOKE=PASS_LOCAL_REPORTED`; `E14_TEMPORAL_DISCOVERY=PREPARED_NOT_EXECUTED`; `E14_YEAR_MONTH_CONFLICT_BEHAVIOR=UNKNOWN`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `T29_HISTORICAL=NOT_APPROVED`. O PR #83 segue Draft sem merge.

---

## 46. E14 — matriz temporal automatizada e risco de perda de ano explícito

**FATO VERIFICADO — log PowerShell/QlikView 12 entregue pelo responsável (14/10/2026):** após fast-forward da branch até `3b6d7fd`, foi executado o mesmo runner `tools/validar_qlik_com_e13_smoke.ps1 -TemporalDiscovery` sobre uma cópia descartável da fonte E5. O baseline E13 foi novamente `PASS`: `Count(P6_POP_ROW_DEBUG)=669`, `Sum(P6_POP_HABITANTES_E5)=12040181`; cenários E13 de um mês, dois meses em 2018 e competências entre 2018/2019 reproduziram 800323, 800323 e `SEM_ANO_UNICO`, respectivamente.

**Matriz E14 realmente observada:**

| Cenário | Filtros explícitos aplicados em ordem | Observação E10 |
|---|---|---|
| Nenhuma competência | ClearAll; sem mês ou ano | `SEM_ANO_UNICO` |
| Somente ano | município serviço 250750, ano 2018, nenhuma competência | `SEM_ANO_UNICO` |
| Ano e mês compatíveis | serviço 250750, ano 2018, competência 201809 | `800323` |
| Ano/mês originalmente incompatíveis | serviço 250750, ano 2019, depois competência 201809 | `800323` **após Qlik limpar a seleção de 2019** |

**Contraexemplo E14 de preservação de intenção:** imediatamente após selecionar ano 2019, a COM registrou `E14_CONFLICT_PRE_MONTH_SELECTED_YEAR=1`. Depois de selecionar 201809, registrou `E14_CONFLICT_YEAR_COUNT=0`, `E14_CONFLICT_YEAR_VALUES=-`, `E14_CONFLICT_COMP_COUNT=1`, `E14_CONFLICT_COMP_VALUES=201809` e `E14_CONFLICT_E10=800323`. **O valor POP 800323 é coerente com o estado final efetivo (setembro/2018), mas não preserva a intenção de ano 2019 inicialmente escolhida.** O QlikView normalizou o estado associativo descartando o filtro anterior; a expressão E10 avalia o estado resultante e não tem evidência da escolha descartada.

**Conclusão semântica:** a expressão E10 **não pode, por si só, detectar conflito já apagado do estado de seleção**. Isto bloqueia aprovação de um contrato que prometa manter simultaneamente ano 2019 e competência 201809. Uma futura regra de apresentação deverá explicitar qual filtro prevalece, impedir combinações incompatíveis, ou obter intenção independente do estado associativo (proposta, não decisão). Além disso, `SEM_ANO_UNICO` sob seleção isolada de ano mostra que a fórmula E10 é propositalmente dependente de competência; não é ainda denominador anual genérico. Não redefinir a granularidade da população.

**Gate técnico observado:** `E14_TEMPORAL_DISCOVERY=OBSERVED_PENDING_SEMANTIC_REVIEW`; `SOURCE_SHA256_UNCHANGED=True`, `SAVE_EXECUTED=False`, `RELOAD_EXECUTED=False`, `QVD_WRITES=0`; `VERDICT=PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED`. Esse veredito é do smoke conhecido E13 e **não aprova** o cenário temporal conflitante E14.

**E15 — experimento de ordem inversa preparado, NÃO EXECUTADO:** o mesmo runner, sob `-TemporalDiscovery`, passará a testar competência 201809 selecionada **antes** do ano explícito 2019. Registrará seleções resultantes para competência/ano/município e o E10, sem antecipar se o QlikView manterá o mês, descartará o mês ou reagirá de outra forma. Também imprimirá risco E14 quando confirmar ano descartado. Nenhuma modificação foi feita nos dados de origem; o ensaio opera somente sobre a cópia descartável.

**Estado:** `E14_TEMPORAL_DISCOVERY=PASS_EXECUTION_WITH_SEMANTIC_RISK`; `E14_YEAR_MONTH_INTENT_PRESERVATION=FAIL_OBSERVED`; `E14_YEAR_ONLY_E10=SEM_ANO_UNICO_OBSERVED`; `E15_REVERSE_ORDER=PREPARED_NOT_EXECUTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft / não integrar.

---

## 47. E15 — seleção temporal na ordem inversa executada no QlikView 12

**FATO VERIFICADO — log PowerShell/QlikView 12 enviado pelo responsável (14/10/2026).** A branch foi atualizada via `git pull --ff-only` até `117a8c3`. O executor experimental `tools/validar_qlik_com_e13_smoke.ps1 -TemporalDiscovery` trabalhou em `P6_E13_DISPOSABLE.qvw` sob pasta temporária, sem alterar o QVW fonte. `SOURCE_SHA256_UNCHANGED=True`, `SAVE_EXECUTED=False`, `RELOAD_EXECUTED=False` e `QVD_WRITES=0`.

**Regressão preservada:** baseline de `669` linhas POP e `12040181` habitantes; E13 três cenários `PASS` (uma competência `201809→800323`, duas do mesmo ano `201808+201809→800323`, duas de anos diferentes `201809+201909→SEM_ANO_UNICO`). E14 repetiu o comportamento de ano 2019 selecionado antes da competência 201809 e indicou `E14_CONFLICT_SAFETY=ORIGINAL_2019_SELECTION_DROPPED_NOT_APPROVED`.

**E15 — ordem inversa com resultado físico observado:** selecionar serviço `250750`, competência `201809` e depois o ano explícito `2019` produziu:

```text
E13_E15_PRE_YEAR_COMP_COUNT=1
E15_PRE_YEAR_COMP_VALUES=201809
E15_REVERSE_YEAR_COUNT=1
E15_REVERSE_YEAR_VALUES=2019
E15_REVERSE_COMP_COUNT=0
E15_REVERSE_COMP_VALUES=-
E15_REVERSE_SERV_COUNT=1
E15_REVERSE_E10=SEM_ANO_UNICO
E15_REVERSE_ORDER=OBSERVED_NOT_APPROVED
```

**Conclusão baseada na evidência:** nos dois testes contraditórios específicos, a seleção posterior prevalece no estado associativo final, e a anterior é descartada. Ano `2019` depois de `201809` elimina o mês; mês `201809` depois do ano `2019` elimina o ano. A expressão E10 não detecta o conflito **já removido do estado**. Quando somente o ano `2019` permanece, E10 retorna `SEM_ANO_UNICO` porque sua regra atual exige alguma competência explícita. Este comportamento não prova uma política universal do QlikView para todos os campos ou combinações; resulta das seleções observadas nesta projeção experimental.

**Gate:** `E15_REVERSE_ORDER=PASS_EXECUTION_BEHAVIOR_OBSERVED`; `E14_E15_SELECTION_INTENT_PRESERVED=FALSE_OBSERVED`; `E10_GENERIC_TEMPORAL_DENOMINATOR=NOT_APPROVED`.

**DECISÃO PENDENTE / HYPÓTESE DE MODELAGEM:** definir separadamente como o painel tratará: (a) população por município×ano quando só ano é escolhido (sem obrigatoriedade de mês); (b) população anual por município×ano para seleção de competências dentro de ano único; (c) conjunto multianual de competências (não somar população inadvertidamente; explicitar como indicador será calculado); (d) conflito de escolhas já descartadas pelo motor associativo, que exige comportamento de filtro/apresentação ou captura independente da intenção, não somente ajuste de Set Analysis. Preservar eixo municipal de residência versus serviço definido no Boundary 6; não transformar evidência de João Pessoa/serviço em regra universal. Priorizar agora verificação do cenário anual isolado e dos papéis territoriais, em vez de mais permutações do mesmo conflito.

**Estado:** `E15_REVERSE_ORDER=PASS_LOCAL_REPORTED`; `E14_CONFLICT_SAFETY=RISK_CONFIRMED`; `E16_YEAR_ONLY_AND_GEO_CONTRACT=NOT_STARTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 segue Draft e sem merge.

---

## 48. E16 — descoberta de população anual isolada por papel municipal (PREPARADA)

**HIPÓTESE DE MODELAGEM, NÃO EXECUTADA no Windows:** o runner versionado `tools/validar_qlik_com_e13_smoke.ps1` foi ampliado, sem criar novo mecanismo de governança, com a flag opcional `-AnnualRoleDiscovery`. Após reproduzir obrigatoriamente os três gates E13 conhecidos, roda quatro cenários independentes no **QVW descartável**: ano 2018 ou 2019, município `250750` explicitamente selecionado no papel serviço (`P6_SERV_DATASUS_6`) ou residência (`P6_RES_DATASUS_6`), **sem seleção de competência mensal**. A função `ClearAll()` restabelece o estado a cada caso, e as contagens de seleção são verificadas.

Cada combinação registra `Count(P6_POP_ROW_DEBUG)`, `Sum(P6_POP_HABITANTES_E5)` (normal), `Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5)` (candidata anual que limpa competência), e E10 (dependente de mês). Não há pressuposição de igualdade entre os papéis municipais até observar saídas reais. Os valores anuais de referência já reconciliados para João Pessoa são 2018=800323 e 2019=809015, mas **nenhum E16 foi marcado como PASS sem execução física**.

**Objetivo:** decidir como apresentar população município×ano quando **somente o ano** está selecionado, sem converter `SEM_ANO_UNICO` em zero, sem repetir POP em meses e sem impor um único papel municipal indevidamente. A escolha final de população por serviço ou por residência depende da definição de cada medida/indicador e do contexto de filtro; Boundary 6 já distingue os papéis. E16 não investiga nem corrige seleção incompatível apagada pelo motor associativo (E14/E15), assunto separado da política de UI.

**Comando posterior:**

```powershell
& .\tools\validar_qlik_com_e13_smoke.ps1 -SourceQvw '<CAMINHO_QVW_E5_VERIFICADO>' -AnnualRoleDiscovery
```

**Estado:** `E16_ANNUAL_ROLE_DISCOVERY=VERSIONED_NOT_RUN`; `E15_REVERSE_ORDER=PASS_LOCAL_REPORTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft, sem merge.

---

## 49. E16 — população anual município×ano por papel de serviço/residência (PASS local)

**FATO VERIFICADO — saída PowerShell/QlikView 12 entregue pelo responsável, 14/10/2026.** Após fast-forward da branch até `fc92d8d`, executou-se `tools/validar_qlik_com_e13_smoke.ps1 -AnnualRoleDiscovery` em QVW descartável criado do E5. O baseline E13 e seus três cenários anteriores permaneceram PASS. O código E16 aplicou `ClearAll()` antes de cada caso, selecionou *apenas* o papel municipal correspondente e um ano, deixando `GetSelectedCount(P6_COMP_COMPETENCIA)=0`. Ano e papel selecionados foram confirmados como 1 cada.

| E16 papel/ano | `Count(P6_POP_ROW_DEBUG)` | `Sum(P6_POP_HABITANTES_E5)` | `Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5)` | E10 |
|---|---:|---:|---:|---|
| Serviço 250750, 2018 | 1 | 800323 | 800323 | `SEM_ANO_UNICO` |
| Serviço 250750, 2019 | 1 | 809015 | 809015 | `SEM_ANO_UNICO` |
| Residência 250750, 2018 | 1 | 800323 | 800323 | `SEM_ANO_UNICO` |
| Residência 250750, 2019 | 1 | 809015 | 809015 | `SEM_ANO_UNICO` |

**Gate restrito:** `E16_ANNUAL_ONLY_SERVICE_RESIDENCE_JP_2018_2019=PASS_LOCAL_REPORTED`. O resultado demonstra uma única linha de população município×ano nesse recorte sob **qualquer um dos papéis selecionado isoladamente**, com valores reconciliados no E5. Não permite concluir que internacões/capacidade/POP tenham semântica idêntica, nem que filtros simultâneos de residência e serviço devam ter a mesma população.

**Limitação da candidata E10:** exige uma competência explicitamente selecionada; logo `E10=SEM_ANO_UNICO` mesmo para ano 2018/2019 inequívoco. Em um painel anual isolado, `Sum(POP)` sem filtro mensal já forneceu o denominador correto no recorte. **HIPÓTESE DE MODELAGEM, não aprovação:** tratar seleção exclusivamente anual e seleção por competência de forma distinta, com seleção de papel municipal explicitamente vinculada ao indicador, sem somar diferentes anos de população automaticamente e sem tentar inferir seleção descartada (E14/E15).

**Integridade:** `SOURCE_SHA256_UNCHANGED=True`; `SAVE_EXECUTED=False`; `RELOAD_EXECUTED=False`; `QVD_WRITES=0`; `VERDICT=PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED`. Este veredito final aprova somente o smoke E13, enquanto E16 fornece evidência visual/logada restrita e não aprova contrato genérico.

**Próximo gate proposto:** ensaio E17 em COM sobre cópia descartável combinando o filtro territorial de serviço/residência com uma competência mensal; examinar a perda de população em medida normal, sua recuperação candidata no E10 e o efeito de filtros simultâneos de papéis diferentes, sem interpretação automática de "zero habitantes". Conferir também a manutenção de cada seleção pela interface COM. **Não alterar Link Table, grão da POP ou fatos.**

**Estado:** `E16_ANNUAL_ROLE_JP_2018_2019=PASS_LOCAL_REPORTED`; `E16_GENERIC_MUNICIPAL_ROLE=NOT_APPROVED`; `E17_GEO_ROLE_MONTH_ASSOCIATION=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft, sem merge.

---

## 50. E17 — descoberta COM de papéis municipais com competência (PREPARADA)

**EXPERIMENTO VERSIONADO, AINDA NÃO EXECUTADO no Windows:** para verificar o efeito de uma competência mensal sobre o denominador populacional por papel territorial, `tools/validar_qlik_com_e13_smoke.ps1` ganhou a opção `-GeographicDiscovery`. O modo existente E13 continua executado primeiro e com seus valores esperados preservados; a nova opção só prossegue após o baseline e os três cenários regressivos.

E17 usa o QVW E5 copiado para diretório único em `%TEMP%`, aplica `ClearAll()` entre testes e agora também verifica que a seleção explícita de residência foi limpa. Projeta três recortes experimentais com João Pessoa (`250750`) e competência `201809`, sem seleção explícita do ano:

1. Somente município de **serviço** `P6_SERV_DATASUS_6=250750`;
2. Somente município de **residência** `P6_RES_DATASUS_6=250750`;
3. **Ambos os papéis** com o **mesmo município** `250750` — não é ainda o fluxo residência→serviço com municípios diferentes.

Para cada caso registra as contagens de seleções, número de linhas POP disponíveis, soma normal `Sum(P6_POP_HABITANTES_E5)`, candidata anual que limpa competência `Sum({$<P6_COMP_COMPETENCIA=>} P6_POP_HABITANTES_E5)` e candidata E10, sem presumir os resultados dos novos recortes. Quando houver `Count(POP)=0` sob competência mensal, isso é sinal de exclusão associativa, não medição de população zero. Nenhuma medida universal será aprovada por coincidência de um resultado.

**Comando local futuro:**

```powershell
& .\tools\validar_qlik_com_e13_smoke.ps1 -SourceQvw '<CAMINHO_QVW_E5_JA_VERIFICADO>' -GeographicDiscovery
```

**Gate:** `E16_ANNUAL_ROLE_JP_2018_2019=PASS_LOCAL_REPORTED`; `E17_GEO_ROLE_MONTH_ASSOCIATION=PREPARED_NOT_EXECUTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 continua Draft, sem merge.

---

## 51. E17 — três filtros municipais e competência mensal: confirmação local

**FATO VERIFICADO — saída PowerShell/QlikView 12 fornecida pelo responsável em 14/10/2026.** Após `git pull --ff-only` da branch do PR #83 até `74b123c`, a opção `-GeographicDiscovery` do runner E13 executou em QVW descartável, somente em memória. Baseline E13 de 669 registros POP e soma 12040181 reconfirmado; smoke de um mês/mesmo ano/anos distintos mantido `PASS`. Os 3 recortes E17 selecionaram competência `201809`, sem seleção explícita de `P6_ANO_ANO`, e cada papel geográfico foi validado via `GetSelectedCount` e `GetFieldSelections`.

| Caso E17 | Seleções municipais | `Count(POP)` | `Sum(POP)` | `Sum({$<COMP=>} POP)` | E10 |
|---|---|---:|---:|---:|---:|
| SERV | serviço=250750 | 0 | 0 | 2420936 | 800323 |
| RES | residência=250750 | 0 | 0 | 2420936 | 800323 |
| BOTH_JP | serviço=250750; residência=250750 | 0 | 0 | 2420936 | 800323 |

**Interpretação rigorosa:** a projeção factual POP está no grão anual, com competência mensal nula. A seleção `201809` faz a contagem e soma normais aparecerem como 0 por exclusão associativa; isso **não equivale a zero habitantes**. Limpar *somente* competência reexpõe os três anos de João Pessoa `811598+800323+809015=2420936`; esse agregado é inválido como denominador de 2018. O E10 derivou o ano pela competência e retornou `800323` nos três recortes para o mesmo município, coerente com as verificações E5/E13. Resultado restrito: `E17_JP_SERVICE_RESIDENCE_SAME_MUNICIPALITY_201809=PASS_LOCAL_REPORTED`.

**Limite de generalização:** os três casos usam o **mesmo** município `250750` nos papéis; não provam comportamento de municípios distintos, nem denominador correto para fluxo residência→serviço quando cada papel aponta para local diferente. O Boundary 6 já diferencia internações por residência e oferta por serviço, e a população materializada usa a mesma coordenada municipal em ambos os papéis sem duplicação da fato. Qualquer medida para filtros simultâneos necessita escolha analítica explícita de papel. O contrato de indicadores e o ajuste de filtros para conflitos temporais E14/E15 seguem pendentes; não mudar grão nem Link Table.

**Integridade verificada no log:** `SOURCE_SHA256_UNCHANGED=True` (mesma origem); `SAVE_EXECUTED=False`; `RELOAD_EXECUTED=False`; `QVD_WRITES=0`; `VERDICT=PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED`. O veredito automático refere-se ao smoke E13 conhecido, enquanto E17 é descoberta observacional, não aprovação genérica.

**Próximo gate E18 (NÃO EXECUTADO):** testar seleção combinada **residência≠serviço**, com dois códigos municipais distintos cuja presença seja validada no QVW antes de qualquer expectativa, registrando quais seleções sobrevivem à associação e como cada medida responde. Manter semântica de população por papel explicitamente identificada e fail-closed quando a combinação não permite denominador.

**Estado:** `E17_GEO_ROLE_MONTH_ASSOCIATION=PASS_LOCAL_REPORTED_RESTRICTED`; `E18_DIFFERENT_ROLE_MUNICIPALITIES=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 continua Draft sem merge.

---

## 52. E18 — municípios diferentes por papel residencial/serviço (PREPARADO)

**HIPÓTESE / EXECUTOR EXPERIMENTAL VERSIONADO, NÃO EXECUTADO no Windows.** Após a evidência E17 (§51), o executor já existente `tools/validar_qlik_com_e13_smoke.ps1` ganhou modo opcional `-CrossRoleDiscovery`, com opção `-OtherMunicipality` cujo valor candidato inicial é `250400`. O código não é declarado aqui como POP/fluxo comprovado até passar a verificação COM. Antes dos ensaios, verifica que o código candidato tem exatamente seis dígitos, é distinto de `250750` e aparece em **cada um dos dois campos reais** `P6_RES_DATASUS_6` / `P6_SERV_DATASUS_6` do QVW, usando `Count({1<...>} DISTINCT campo)=1` e gate fail-closed. Essas verificações de domínio NÃO demonstram, por si só, existência de fluxo RD entre os municípios.

**Cenários (todos somente observacionais):** usar serviço `250750` e residência `250400`, competência `201809` ou ano `2018`, em três execuções independentes com `ClearAll()`:
- `SERV_FIRST_MONTH`: selecionar serviço, depois residência, depois competência;
- `RES_FIRST_MONTH`: selecionar residência, depois serviço, depois competência;
- `SERV_FIRST_YEAR`: selecionar serviço, depois residência, depois ano 2018 (sem competência).

Registrar `GetSelectedCount` e `GetFieldSelections` de ambos os papéis, competência e ano; `Count(POP)`, `Sum(POP)`, candidata `Sum({$<COMP=>} POP)` e E10. Registrar explicitamente se **ambas as seleções municipais pretendidas sobreviveram**; a associação poderá descartar um filtro anterior. **Não presumir** que E10 retorna a população do serviço, da residência, ou zero. Nenhum desses resultados é denominador aprovado para o fluxo residência→serviço: o Boundary 6 exige que cada indicador explicite seu papel populacional. A ausência de fato POP sob filtros cruzados **não significa zero habitantes**.

O runner preserva todos os gates E13 conhecidos e opera somente sobre cópia descartável do QVW E5; não executa Reload/Save/STORE e compara SHA-256 da origem após execução.

**Comando futuro:**

```powershell
& .\\tools\\validar_qlik_com_e13_smoke.ps1 -SourceQvw '<CAMINHO_QVW_E5_VERIFICADO>' -CrossRoleDiscovery -OtherMunicipality '250400'
```

**Estado:** `E17_JP_SERVICE_RESIDENCE_SAME_MUNICIPALITY_201809=PASS_LOCAL_REPORTED_RESTRICTED`; `E18_CROSS_ROLE_MUNICIPALITIES=PREPARED_NOT_EXECUTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft, sem merge.

---

## 53. E18 — erro de parser na primeira execução e correção mínima

**FATO VERIFICADO — saída local do responsável, 14/10/2026:** após `git pull --ff-only` até `b5d12b7`, a execução de `tools/validar_qlik_com_e13_smoke.ps1 -CrossRoleDiscovery -OtherMunicipality '250400'` foi interrompida durante a fase de análise sintática do PowerShell: `ParserError`, incluindo `UnexpectedToken`, terminador de aspas ausente e blocos `try`/`if` aparentemente não fechados. **Nenhuma instrução do script chegou a ser executada**: E13–E17 não foram reexecutados e E18 não testou COM, QVW, domínios municipais, fluxo ou denominadores. Não marcar E18 como PASS, FAIL de dados ou qualquer conclusão analítica.

**Causa raiz identificada ao inspecionar o arquivo versionado:** no bloco E18, uma expressão regular PowerShell `'^[0-9]{6}$'` foi quebrada e uma duplicação prematura do bloco final (`catch`/`finally`/`VERDICT`) foi inserida entre essa expressão e o operador `-or`, corrompendo a estrutura do arquivo. A falha ocorreu **na montagem da alteração de código**, não na QlikView COM nem nos datasets. Foi realizada correção cirúrgica removendo o trecho duplicado e recompondo a expressão `if ($OtherMunicipality -notmatch '^[0-9]{6}$' -or $OtherMunicipality -ceq '250750')`, mantendo intactas a matriz E13–E17 e a proposta observacional E18.

**Validação disponível após o ajuste:** inspeção estática do texto remoto confirmou apenas um `catch`/`finally` de nível superior, único `VERDICT` final e delimitadores equilibrados fora de strings/comentários, além da permanência dos gates E13/E17 e ausência de chamadas `Save`/`Reload`. **Ainda não houve validação com parser nativo PowerShell nem execução QlikView 12 no Windows.** Não declarar `PARSER_PASS` antes dessa prova.

**Preflight obrigatório antes da próxima execução (Windows):**

```powershell
$ps1 = (Resolve-Path .\tools\validar_qlik_com_e13_smoke.ps1).Path
$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($ps1, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) {
    $parseErrors | Format-List Message, Extent
    throw 'E18_SCRIPT_PARSE_FAILED'
}
'PARSER_PASS'
```

Se o parser retornar PASS, somente então executar o runner E18 sobre a origem E5 validada. Caso contrário, interromper e enviar mensagens do parser. E18 continua sujeito à validação de existência de `250400` em ambos os campos COM e aos resultados dos filtros; nenhum resultado é presumido.

**Estado:** `E18_POWERSHELL_PARSE=FAIL_LOCAL_REPORTED_BEFORE_FIX`; `E18_PARSER_FIX=VERSIONED_STATIC_CHECK_ONLY`; `E18_COM_EXECUTION=NOT_TESTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 continua Draft, sem merge.

---

## 54. E18 — municipios distintos, filtros preservados e POP excluida

**FATO VERIFICADO — log do responsável, QlikView 12/PowerShell COM (14/10/2026).** Após `git pull --ff-only` da branch do PR #83 até `6bec6fa`, o parser nativo do Windows executou `[System.Management.Automation.Language.Parser]::ParseFile` sem erros e confirmou `PARSER_PASS`. O runner `tools/validar_qlik_com_e13_smoke.ps1 -CrossRoleDiscovery -OtherMunicipality '250400'` abriu apenas QVW descartável e reproduziu baseline e três cenários E13 PASS (`669` POP municipio-ano; soma `12040181`; E10 = 800323 com competência única; 800323 com dois meses de 2018; `SEM_ANO_UNICO` entre anos). Preflight E18 `E13_E18_OTHER_IN_P6_RES_DATASUS_6=1` e `E13_E18_OTHER_IN_P6_SERV_DATASUS_6=1` provou que o código `250400` existe em ambos os campos de papel **isoladamente**, não prova contagem de fluxos RD entre os municipios.

| E18 cenário | Filtros efetivos preservados | POP linhas | POP normal | POP limpando competência | E10 |
|---|---|---:|---:|---:|---:|
| `SERV_FIRST_MONTH` | Serviço 250750; residência 250400; competência 201809; `YEAR_COUNT=0` | 0 | 0 | 0 | `0` |
| `RES_FIRST_MONTH` | Serviço 250750; residência 250400; competência 201809; `YEAR_COUNT=0` | 0 | 0 | 0 | `0` |
| `SERV_FIRST_YEAR` | Serviço 250750; residência 250400; ano 2018; `COMP_COUNT=0` | 0 | 0 | 0 | `SEM_ANO_UNICO` |

Para todos os três: `BOTH_INTENDED_ROLE_FILTERS_SURVIVED=True`. Portanto o motor associativo **não apagou** nenhum dos dois municípios nestes testes; a ausência de população é causada pela **interseção territorial não compatível com a projeção POP da Link Table**, na qual cada município da POP tem a mesma coordenada nos dois papéis. Quando `SERV` difere de `RES`, não há linha POP que satisfaça simultaneamente os dois filtros. Limpar somente competência e/ou selecionar explicitamente o ano não recupera POP. A ausência/zero nas expressões **não equivale a zero habitantes**.

**CONTRAEXEMPLO SEMÂNTICO CRÍTICO:** a fórmula E10 que parecia adequada a um município e competência únicos em E13–E17 retornou **zero** quando ambos os papéis municipais divergiram (inclusive com competência 201809 de ano único). Assim `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED` fica reforçado. Não usar E10 como denominador universal, nem interpretar ausência de POP como indicador zero. A seleção de papel municipal precisa ser declarada em cada indicador (Boundary 6), especialmente para fluxo residência→serviço. Não alterar dados, granularidade anual da população ou Link Table física baseada neste ensaio.

**Integridade:** `SOURCE_SHA256_UNCHANGED=True`, `SAVE_EXECUTED=False`, `RELOAD_EXECUTED=False`, `QVD_WRITES=0`; `VERDICT=PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED` ainda refere-se à regressão E13, e E18 é descoberta observacional (não aprovação de contrato ou integridade de fluxo RD).

**HIPÓTESE DE MODELAGEM PARA PRÓXIMA DISCOVERY:** numa medida cujo denominador seja a população do município **de serviço**, limpar exclusivamente o papel de **residência** além do filtro mensal e restringir o ano pode reabilitar a linha POP; na medida por **residência**, limpar exclusivamente o papel **de serviço**. Isso precisa ser testado contra duas referências anuais independentes obtidas separadamente de `serviço=250750, ano=2018` e `residência=250400, ano=2018` antes de qualquer aprovação; não presumir que basta aplicar Set Analysis nem que preservar ambos os filtros de fluxo sobre os fatos implique preservar ambos no denominador.

**Estado:** `E18_PARSER_PASS=LOCAL_REPORTED`; `E18_DIFFERENT_ROLE_MONTH_AND_YEAR_FILTERS_SURVIVED=PASS_RESTRICTED`; `E18_POP_UNDER_CROSS_ROLE=EXCLUDED_ALL_THREE_SCENARIOS`; `E18_E10_CROSS_ROLE_ZERO=SEMANTIC_FAILURE`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 segue Draft e sem merge.

---

## 55. E19 — denominador especifico por papel municipal (PREPARADO)

**HIPÓTESE DE MODELAGEM / DISCOVERY VERSIONADA, AINDA NÃO EXECUTADA NO WINDOWS.** O ensaio E18 (§54) confirmou que POP desaparece do estado associativo com filtros `SERV=250750` e `RES=250400`, mantendo ambos os filtros; E10 retornou `0` nos recortes com competência `201809`. O Boundary 6 já exige denominador explicitamente definido pelo papel municipal em indicadores de fluxo. Antes de aprovar qualquer medida, o executor existente `tools/validar_qlik_com_e13_smoke.ps1` ganhou `-RoleDenominatorDiscovery` como submodo optativo de `-CrossRoleDiscovery`.

**Gate de referência independente:** E19 limpa seleções apenas na cópia descartável, seleciona `P6_SERV_DATASUS_6=250750` + ano 2018 para obter população serviço em uma linha POP, depois `P6_RES_DATASUS_6=250400` + ano 2018 para obter população residência em outra linha POP. Verifica `GetSelectedCount`, ausência de competência selecionada e `Count(P6_POP_ROW_DEBUG)=1` em ambos os recortes, e **mede** as referências sem inventar a população de `250400`.

**Duas expressões experimentais E19:** sob *ambos* os filtros municipais distintos, derivar o denominador do serviço limpando o filtro residencial e a competência e fixando ano 2018; simetricamente para residência limpando o filtro de serviço. As expressões Set Analysis são **candidatas**, não contrato aprovado:

```qlik
Sum({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={2018},P6_RES_DATASUS_6=>} P6_POP_HABITANTES_E5)
Sum({$<P6_COMP_COMPETENCIA=,P6_ANO_ANO={2018},P6_SERV_DATASUS_6=>} P6_POP_HABITANTES_E5)
```

O script reproduz dois contextos (`MONTH_201809`, `YEAR_2018`), valida que os dois filtros municipais pretendidos permanecem ativos, registra `SERVICE_CANDIDATE`/`RESIDENCE_CANDIDATE`, compara literalmente cada resultado à referência isolada (`SERVICE_MATCH`/`RESIDENCE_MATCH`), e **não** transforma coincidência em aprovação semântica automática. O ano `2018` é literal **apenas neste ensaio controlado**, e não solução genérica do painel. Se alguma referência de POP estiver ausente, o teste bloqueia com `Count(POP)` diferente de 1. Nenhum QVD factual ou Link Table é produzido.

**Comando planejado após `git pull --ff-only` e validação com parser nativo PowerShell:**

```powershell
& .\tools\validar_qlik_com_e13_smoke.ps1 -SourceQvw '<CAMINHO_QVW_E5>' -CrossRoleDiscovery -RoleDenominatorDiscovery -OtherMunicipality '250400'
```

**Limites metodológicos:** a evidência é do modelo associado em memória, não prova existência de internações de residentes de `250400` atendidos em `250750`, nem regularidade de todos os 223 municípios/anos, nem o correto denominador de todo indicador. A política UI de filtro temporal conflitante (E14/E15) e o contrato da `%LINK_KEY` continuam pendentes. O arquivo usa QVW descartável, não faz Save/Reload e preserva a fonte.

**Estado:** `E18_CROSS_ROLE=PASS_LOCAL_OBSERVED_WITH_ZERO_POP_EXCLUSION`; `E19_ROLE_DENOMINATOR=VERSIONED_STATIC_ONLY_NOT_EXECUTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft sem merge.

---

## 56. E19 — validacao local de denominadores separados por papel municipal

**FATO VERIFICADO — saida PowerShell/QlikView 12 encaminhada pelo responsavel em 14/10/2026:** apos `git pull --ff-only` ate `ca1865a`, o parser nativo PowerShell confirmou `PARSER_PASS`; `tools/validar_qlik_com_e13_smoke.ps1 -CrossRoleDiscovery -RoleDenominatorDiscovery -OtherMunicipality '250400'` executou apenas sobre copia descartavel. E13 permaneceu PASS (669 POP municipio×ano, soma PB 2017–2019 12040181; tres cenarios temporais anteriores). O E18 repetiu tres recortes com servico `250750` e residencia `250400`: filtros de ambos os papeis preservados; POP excluida por intersecao territorial (0 linhas), E10=0 nos contextos mensais e `SEM_ANO_UNICO` no anual; **zero de expressao nao representa zero habitantes**.

**Referencias anuais independentes E19, ano 2018 e sem competencia selecionada:**

| Eixo municipal isolado | Selecoes | Linhas POP | Populacao IBGE |
|---|---|---:|---:|
| Servico `P6_SERV_DATASUS_6` | `250750`, `P6_ANO_ANO=2018` | 1 | `800323` |
| Residencia `P6_RES_DATASUS_6` | `250400`, `P6_ANO_ANO=2018` | 1 | `407472` |

**E19 comparacao de duas candidatas especificas por papel (sem alterar filtros ativos das medidas hospitalares):**

| Contexto com `SERV=250750` e `RES=250400` | Denom. servico — limpa residencia e competencia, fixa 2018 | Denom. residencia — limpa servico e competencia, fixa 2018 | Igualdade com referencia |
|---|---:|---:|---|
| Competencia `201809` | `800323` | `407472` | `SERVICE_MATCH=True`, `RESIDENCE_MATCH=True` |
| Ano explicito `2018` | `800323` | `407472` | `SERVICE_MATCH=True`, `RESIDENCE_MATCH=True` |

Nos dois contextos `BOTH_ROLE_FILTERS_INTACT=True`. O Set Analysis do denominador de **servico** removeu apenas o filtro explicito de residencia; o denominador de **residencia** removeu apenas o de servico. A competencia e o ano sao tratados como recortes do denominador, e a escolha de papel deve seguir a finalidade de cada indicador (Boundary 6); as selecoes hospitalares nao foram limpas no estado global.

**Veredito restrito:** `E19_ROLE_SPECIFIC_POP_2018_CANDIDATES=PASS_LOCAL_REPORTED_RESTRICTED`. Este resultado confirma **a igualdade numerica com duas referencias anuais isoladas dentro dos contextos medidos**, nao valida o contrato completo de indicadores, nao prova fluxo real de internacao 250400→250750 e nao autoriza generalizacao para outros municipios, multiplos anos ou ano dinamico. A expressao E19 permanece **candidata**; `P6_ANO_ANO={2018}` foi fixado deliberadamente no ensaio. Nao interpretar `VERDICT=PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED` como PASS contratual, porque este veredito pertence ao gate E13.

**Integridade no log:** `SOURCE_SHA256_UNCHANGED=True`; `SAVE_EXECUTED=False`; `RELOAD_EXECUTED=False`; `QVD_WRITES=0`.

**DECISAO PENDENTE / proxima fronteira:** especificar politica de ano selecionado isoladamente versus ano derivado de uma unica competencia (ou diversas competencias no mesmo ano), proteger ambiguidade multianual e ausencia de ano sem somar POP entre anos; distinguir denominadores por residencia/servico no contrato de cada indicador. Os casos E14/E15 ja demonstraram que a selecao temporal anterior pode ser perdida no motor associativo e nao pode ser reconstruida pela expressao com apenas estado final. Validar a futura expressao dinamica contra as referencias isoladas de **mais de um ano**, com um gate que rejeite ambiguidades antes de aprovar. Nao alterar fatos, grão populacional, %LINK_KEY, modelo dimensional nem paineis enquanto o contrato estiver pendente.

**Estado:** `E19_PARSER_PASS=LOCAL_REPORTED`; `E19_ROLE_POP_SERVICE_RESIDENCE_2018=PASS_LOCAL_REPORTED_RESTRICTED`; `E19_GENERIC_YEAR_OR_MULTIMUNICIPALITY=NOT_APPROVED`; `E20_TEMPORAL_ROLE_DENOMINATOR=NOT_STARTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 segue Draft e sem merge.

---

## 57. E20 — tentativa de ano dinamico com denominadores por papel (PREPARADA)

**EXPERIMENTO DE MODELAGEM PREPARADO, NAO EXECUTADO no QlikView 12/Windows.** O E19 (§56) comprovou igualdade numerica de dois denominadores por papel municipal para 2018 fixo, com filtros cruzados distintos. O runner versionado `tools/validar_qlik_com_e13_smoke.ps1` ganhou flag optativa `-DynamicRoleDiscovery` dependente de `-CrossRoleDiscovery`. Nao muda fatos, medidas definitivas, Link Table, arquitetura nem QVDs; trabalha em QVW descartavel e preserva regressao E13.

**HIPOTESE DE MODELAGEM E20:** sob residencia e servico diferentes, o denominador por servico limpa o filtro de residencia apenas na expressao; o por residencia limpa o filtro de servico apenas na expressao. Se houver uma ou mais competencias selecionadas **todas de um unico ano**, o calculo derivara esse ano das competencias; na ausencia de competencia, **um unico ano explicitamente selecionado** devera definir o denominador. Se competencias abrangerem varios anos, ou nao existir mes nem ano univoco selecionado, deve retornar `SEM_ANO_UNICO`, nao zero/populacao somada. Esta proposta **nao resolve** conflitos cuja primeira selecao ja foi descartada pela associatividade QlikView (E14/E15).

**Metodo de teste:** medir novamente as referencias por municipio e por ano sob selecoes **isoladas** (`SERV=250750` ou `RES=250400`, anos 2018 e 2019, `Count(POP)=1`). Depois testar ambas as selecoes territoriais aplicadas simultaneamente e seis recortes temporais: `MONTH_201809`, `MONTH_201909`, `YEAR_2018`, `YEAR_2019`, `TWO_MONTHS_2018` (`201808`, `201809`) e `CROSS_YEAR_MONTHS` (`201809`, `201909`). Registrar se as selecoes dos dois municipios sobreviveram, quantidade de competencias, ano selecionado, cada candidato dinamico e comparacao com referencias mensuradas. No caso entre anos, registrar explicitamente se ambos recusaram calculo. **Nenhum PASS contratual sera inferido da simples emissao de valores**; se a associacao descartar alguma selecao, o log revelara a discrepancia.

**Preflight necessario no Windows antes de executar qualquer COM:** chamar `[System.Management.Automation.Language.Parser]::ParseFile` no script atualizado e interromper se `$parseErrors.Count -gt 0`. Houve somente verificacao estatica no repositorio (aspas e delimitadores equilibrados, bloco final unico, ausencia de Save/Reload); parser real E20 ainda pendente. O codigo E20 nao deve ser chamado de aprovado ate executar e comparar com os controles independentes.

**Comando planejado em branch Draft, depois de git pull e parser PASS:**

```powershell
& .\tools\validar_qlik_com_e13_smoke.ps1 -SourceQvw '<QVW_E5_VERIFICADO>' -CrossRoleDiscovery -DynamicRoleDiscovery -OtherMunicipality '250400'
```

**Estado:** `E19_ROLE_DENOMINATOR_2018=PASS_LOCAL_REPORTED_RESTRICTED`; `E20_DYNAMIC_ROLE_YEAR=VERSIONED_NOT_EXECUTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 permanece Draft sem merge.

---

## 58. E20 — ano dinamico com dois papeis municipais: PASS restrito local

**FATO VERIFICADO — log PowerShell/QlikView 12 enviado pelo responsavel em 14/10/2026:** após `git pull --ff-only` até `ecad825`, `[System.Management.Automation.Language.Parser]::ParseFile` retornou `PARSER_PASS`. Executado `tools/validar_qlik_com_e13_smoke.ps1 -CrossRoleDiscovery -DynamicRoleDiscovery -OtherMunicipality '250400'` sobre QVW E5 descartavel. O preflight E13 repetiu PASS (669 registros POP municipio×ano; soma 12040181; um mes, dois do mesmo ano e dois de anos diferentes); E18 repetiu os filtros cruzados serviço 250750 e residência 250400 com zero linhas POP diretamente associadas. O teste E20 não aprovou mudança fisica nem gerou QVD.

**Referencias POP independentes anuais observadas (cada recorte isolado `Count(POP)=1`):**

| Ano | Municipio servico `250750` | Municipio residencia `250400` |
|---|---:|---:|
| 2018 | `800323` | `407472` |
| 2019 | `809015` | `409731` |

**Matriz E20 observada com ambos os papeis simultaneamente selecionados:**

| Selecao temporal | Candidata SERV | Candidata RES | Validacao contra referencias |
|---|---:|---:|---|
| Competencia `201809` | `800323` | `407472` | SERV=True; RES=True |
| Competencia `201909` | `809015` | `409731` | SERV=True; RES=True |
| Ano `2018` isolado | `800323` | `407472` | SERV=True; RES=True |
| Ano `2019` isolado | `809015` | `409731` | SERV=True; RES=True |
| Duas competencias do mesmo ano `201808+201809` | `800323` | `407472` | SERV=True; RES=True |
| Competencias entre anos `201809+201909` | `SEM_ANO_UNICO` | `SEM_ANO_UNICO` | `BOTH_REFUSED=True` |

Em **todos os seis casos**, `ROLE_SELECTION_INTACT=True`: os filtros municipio serviço 250750 e residencia 250400 permaneceram. Em **cinco casos**, ambos os resultados coincidiram com a referencia correspondente (10/10 comparacoes numericas `True`). Na selecao multianual de competencias houve recusa de ambas as expressoes, em vez de somar populacoes de anos distintos. O ano no denominador foi derivado da(s) competencia(s) de um unico ano ou de um ano explicitamente escolhido. As medidas Set Analysis limparam apenas o papel municipal oposto **dentro do denominador**, sem retirar as duas selecoes territoriais no estado global.

**INTEGRIDADE NO LOG:** `SOURCE_SHA256_BEFORE=F75786A88E7563B739492F2D2BC7C5CEA50D8C7F8E73F36770AA76960FB668C6`; `SOURCE_SHA256_UNCHANGED=True`; `SAVE_EXECUTED=False`; `RELOAD_EXECUTED=False`; `QVD_WRITES=0`. O `VERDICT=PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED` continua referindo-se ao smoke E13; E20 é **PASS restrito de igualdade numerica e recusa multianual observadas**, e nao aprovação de contrato.

**LIMITES / DECISAO PENDENTE:** este ensaio utilizou apenas dois codigos municipais e anos 2018–2019 num QVW experimental. Não testou ausência de **ambas** selecoes temporais nem dois **anos explicitos** simultaneos; tampouco generalizou para demais municipios/anos, filtros por estabelecimento/procedimento, outros contextos municipais ou soma de multiplos municipios. Os conflitos de intenção perdidos por associatividade em E14/E15 nao podem ser reconstruidos por estas expressoes. A finalidade analitica de cada denominador (residencia para internacoes de residentes; servico para oferta/capacidade) depende de contrato por indicador, nao de coincidencia numerica. Preservar grão `municipio × ano`, modelagem academica aprovada e `FATO_POPULACAO` sem duplicacao.

**PROXIMO GATE RECOMENDADO (ainda nao executado):** validar guardas temporais sem competencia nem ano e com dois anos explicitamente selecionados, ambos sob papeis distintos; em paralelo preparar uma **tabela de contrato de indicadores por papel** (demanda de residentes/populacao residente; leitos por habitante/populacao do municipio de servico; indicadores sem denominador populacional), sem aprovar fatos, Link Table nem paineis nesta Discovery.

**Estado:** `E20_PARSER_PASS=LOCAL_REPORTED`; `E20_DYNAMIC_ROLE_JP_CG_2018_2019=PASS_LOCAL_REPORTED_RESTRICTED`; `E20_NUMERIC_MATCH=10_OF_10`; `E20_CROSS_YEAR_COMPETENCE_REFUSAL=PASS_LOCAL_REPORTED`; `E21_MISSING_TEMPORAL_GUARDS=NOT_STARTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 segue Draft sem merge.

---

## 59. E21 — guardas de ausencia de tempo, dois anos explicitos e cobertura 2017 (PREPARADO)

**HIPOTESE / SCRIPT EXPERIMENTAL VERSIONADO, NAO EXECUTADO NO WINDOWS.** E20 (§58) validou 10/10 resultados numericos de dois papeis municipais com ano 2018/2019 e recusou selecao de competencias entre anos. Permanecem ausentes no ensaio o ano 2017 e dois limites temporais relevantes: **nenhuma selecao de competencia nem ano**; **dois anos explicitamente selecionados sem competencia**.

O mesmo runner `tools/validar_qlik_com_e13_smoke.ps1` agora aceita a opcao `-TemporalGuardDiscovery`, exigindo as flags existentes `-CrossRoleDiscovery -DynamicRoleDiscovery` para reutilizar as expressoes observacionais E20. Os gates E13, E18 e E20 sao executados antes de E21. O QVW original e protegido por copia descartavel/checagem de hash, sem Save/Reload ou QVD.

**Matriz planejada E21 (cada caso com SERV=250750 e RES=250400):**

| Caso | Selecao temporal | Expectativa e gate |
|---|---|---|
| `NO_PERIOD` | Sem competencia e sem ano explicito | Duas expressoes devem retornar `SEM_ANO_UNICO`, caso contrario `FAIL_CLOSED` |
| `TWO_EXPLICIT_YEARS` | Anos 2018 e 2019 simultaneos, sem competencia | Confirmar `GetSelectedCount(ANO)=2`; ambas expressoes devem recusar |
| `MONTH_201709` | Competencia unica `201709`, sem ano explicito | Comparar servico/residencia contra duas referencias POP anuais independentes do ano 2017 |
| `YEAR_2017` | Ano explicito 2017, sem competencia | Comparar servico/residencia contra as mesmas referencias POP anuais isoladas |

**Regra de referencia:** antes de testar os quatro casos, E21 mede a POP 2017 separadamente por municipio (servico 250750 e residencia 250400), confirmando `Count(POP)=1`; **nao possui valor de populacao 2017 codificado no script**. Cada caso valida preservacao dos filtros territoriais e falha de forma fechada se uma referencia divergir ou um caso ambiguo retornar denominador numerico. Aderencia a um numero nao aprova automaticamente a semantica geral.

**Verificacoes ja realizadas:** exame **estatico** do arquivo versionado confirmou apenas um bloco `catch/finally` de topo, um veredito final, aspas/delimitadores equilibrados, presenca dos gates E13 e E21, e ausencia de comandos explicitos `Save`/`Reload`. Houve erro de parser ao criar E18 anteriormente; portanto **parser nativo PowerShell E21 e COM nao foram testados** e devem ser exigidos antes da primeira execucao.

**Proxima execucao Windows planejada:** `git pull --ff-only`, `[System.Management.Automation.Language.Parser]::ParseFile` e, somente com parser PASS:

```powershell
& .\tools\validar_qlik_com_e13_smoke.ps1 -SourceQvw '<QVW_E5_JA_VERIFICADO>' -CrossRoleDiscovery -DynamicRoleDiscovery -TemporalGuardDiscovery -OtherMunicipality '250400'
```

**Limites e decisoes:** nao testa populacao de outros municipios, fluxo SIH/RD observado, validade generica da %LINK_KEY, politica de UI para perda de intencao temporal (E14/E15) nem medidas hospitalares finais. Apos E21, focar **contrato de indicadores por papel municipal e grão temporal**, nao expandir indefinidamente os cenarios isolados. Permanecem `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `FACT_QVDS=NOT_STARTED`, `LINK_ANALISE_QVD=NOT_STARTED`, `T29_HISTORICAL=NOT_APPROVED`. PR #83 continua Draft sem merge.

---

## 60. E21 — guardas temporais e referencia populacional de 2017

**FATO VERIFICADO (saida PowerShell/QlikView 12 enviada pelo responsavel, 14/10/2026):** a branch do PR #83 foi atualizada ate `672d8c4` e `[System.Management.Automation.Language.Parser]::ParseFile` confirmou `PARSER_PASS`. Foi executado `tools/validar_qlik_com_e13_smoke.ps1 -CrossRoleDiscovery -DynamicRoleDiscovery -TemporalGuardDiscovery -OtherMunicipality '250400'` contra **copia descartavel** do QVW E5 em memoria. O baseline E13 repetiu `Count(POP)=669`, `Sum(POP)=12040181` e tres cenarios temporais PASS; E18 repetiu a exclusao da POP sob filtros de municipio de servico 250750 e residencia 250400, e E20 repetiu os 10/10 matches numericos 2018/2019 e a recusa de competencias multianuais. O veredito final do script `PASS_COM_SMOKE_ONLY_DENOMINATOR_CONTRACT_NOT_APPROVED` permanece pertencente ao smoke E13, enquanto os gates E21 especificos foram executados e registrados separadamente.

**E21 — referencias anuais de 2017 efetivamente medidas (cada municipio com `Count(POP)=1`, ano selecionado=1):**

| Municipio/papel no experimento | Referencia de 2017 |
|---|---:|
| SERV `250750` | `811598` |
| RES `250400` | `410332` |

**Matriz E21 executada, com `BOTH_ROLE_FILTERS_INTACT=True` nos quatro casos:**

| Cenario | Selecao temporal real observada | Candidata SERV | Candidata RES | Gate |
|---|---|---|---|---|
| `NO_PERIOD` | `GetSelectedCount(ANO)=0`; `GetSelectedCount(COMP)=0` | `SEM_ANO_UNICO` | `SEM_ANO_UNICO` | `BOTH_REFUSED=True` |
| `TWO_EXPLICIT_YEARS` | `GetSelectedCount(ANO)=2` (2018 e 2019) | `SEM_ANO_UNICO` | `SEM_ANO_UNICO` | `BOTH_REFUSED=True` |
| `MONTH_201709` | `GetSelectedCount(COMP)=1` | `811598` | `410332` | `SERVICE_MATCH=True`, `RESIDENCE_MATCH=True` |
| `YEAR_2017` | `GetSelectedCount(ANO)=1` | `811598` | `410332` | `SERVICE_MATCH=True`, `RESIDENCE_MATCH=True` |

Todos os quatro casos retornaram `PASS_RESTRICTED_NOT_CONTRACT` e o bloco E21 encerrou com `E21_TEMPORAL_GUARD_DISCOVERY=PASS_RESTRICTED_NOT_CONTRACT`. **FATO VERIFICADO:** com estes municipios e no QVW experimental, a derivacao anual funciona para 2017 e os dois estados temporais ambiguos sao rejeitados, sem somar automaticamente populacao entre anos.

**Integridade do ensaio:** `SOURCE_SHA256_BEFORE=F75786A88E7563B739492F2D2BC7C5CEA50D8C7F8E73F36770AA76960FB668C6`, `SOURCE_SHA256_UNCHANGED=True`, `SAVE_EXECUTED=False`, `RELOAD_EXECUTED=False`, `QVD_WRITES=0`. As verificacoes do log sao referentes ao QVW experimental; nao demonstram recarga completa de fatos fisicos ou PAINEL.

**Limites:** a coincidencia dos resultados de E13–E21 nao prova generalidade de todos os municipios, combinacoes de filtros externos ou medidas cruzadas reais. E14/E15 ja demonstraram a perda da intencao inicial quando o QlikView remove selecao temporal incompatível; a candidata E20/E21 conhece apenas o estado associativo final, sem reconstruir o historico da selecao. Nao interpretar POP nula/excluida como habitantes=0 e nao calcular razoes com denominador zero/ambíguo. A aprovacao do **contrato semantico global** permanece pendente.

**Estado:** `E21_PARSER=PASS_LOCAL_REPORTED`; `E21_2017_REFERENCE=PASS_LOCAL_REPORTED_RESTRICTED`; `E21_NO_PERIOD_REFUSAL=PASS_LOCAL_REPORTED`; `E21_TWO_EXPLICIT_YEARS_REFUSAL=PASS_LOCAL_REPORTED`; `E21_TEMPORAL_GUARD=PASS_LOCAL_REPORTED_RESTRICTED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 continua Draft sem merge.

---

## 61. Contrato de indicadores por papel municipal e periodo — matriz de revisao, NAO APROVADA

**Fonte de verdade para indicadores:** decisoes ja **aprovadas academicamente**, sem nova modelagem, em `docs/academic/chapter-1-2-modeling.md` (RN09–RN16 e §13), `docs/discovery/boundary-6-qlikview-physical-architecture.md` (§§20–21) e `docs/discovery/boundary-7-implementation-plan.md` (§24). A matriz abaixo registra o significado dessas regras e os **gates de implementacao ainda em aberto**; nao altera definicao de fatos, medidas, granularidade, dimensoes ou politica CNES/LT.

| Indicador/analise previstos | Numerador | Denominador | Papel territorial e tempo ja definidos | Status de implementacao |
|---|---|---|---|---|
| Internacoes por 1.000 habitantes | `QTD_INTERNACAO` de **residentes** | `POPULACAO_ESTIMADA` | Municipio **residencia**, mesmo **ano**; multiplicar por 1.000 | **Regra academica definida; expressao fisica final NOT_APPROVED** |
| Leitos SUS por 1.000 habitantes | **Media mensal** de `QTD_LEITOS_SUS` no ano | `POPULACAO_ESTIMADA` | Municipio **servico/localizacao** do estabelecimento, ano compativel; multiplicar por 1.000 | **Regra academica definida; contrato fisico/numerador snapshot NOT_APPROVED** |
| Relacao internacoes/leito | Internacoes **realizadas** no municipio e periodo | Capacidade **media** de leitos no mesmo municipio/periodo | Municipio **servico**, periodo compativel; **nao denominar taxa de ocupacao** | **Regra academica definida; validacao das duas fatos ainda pendente** |
| Fluxo residencia → servico | Distribuicao/contagem de internacoes por par de municipios | **Sem POP implicita** | Dois papeis territoriais simultaneos, com dimensao de tempo do evento definida | **Analise academica definida; medidas/associacoes fisicas nao reconciliadas** |

**HIPOTESE DE IMPLEMENTACAO RESTRITA (nao decisao final):** as candidatas E20/E21 sugerem estrategia viavel para o **denominador POP**, caso o objeto ja tenha escolhido explicitamente o papel do indicador:
- escolher apenas um ano analitico: **ano explicito unico**, ou **competencias todas no mesmo ano**;
- para POP por residencia, limpar no **denominador** somente o filtro de municipio **servico** e a selecao de competencia mensal, preservando municipio residencia e impondo o ano unico;
- para POP por servico, limpar no **denominador** somente o filtro de municipio **residencia** e a selecao de competencia mensal, preservando municipio servico e impondo o ano unico;
- na ausencia de ano unico, sinalizar indisponibilidade `SEM_ANO_UNICO`; denominador excluido/ausente, nulo ou zero **nao** gera indicador numerico automatico.

A regra POP por papel acima depende dos contextos demonstrados em E19–E21 e **nao autoriza** copiar literalmente as expressoes de ensaio para os objetos do PAINEL. As referencias sao municipais anuais; **leitos sao snapshots mensais** e sua agregacao anual exige politica de cobertura/media mensal aprovada, nao `Sum` entre competencias. Numerador e denominador precisam de reconciliacao separada com as fatos reais, mantendo a semantica de `QTD_INTERNACAO` (nao substituir por `QTD_REGISTRO_AIH`).

**DECISOES PENDENTES para aceite do contrato:**
1. Especificar em texto versionavel a regra de selecao e conflito de **ano/competencia** no PAINEL (inclusive intencao perdida em E14/E15) e se o periodo pode ser multianual com calculo **por ano**, em vez de um unico denominador agregado.
2. Associar cada expressao de indicador a seu numerador verificado, seu papel geográfico e sua unidade (por 1.000, contagem ou relacao); nao usar denominador populacional genericamente em fluxo residencia→servico.
3. Verificar cobertura real de **populacao para municipios externos** e resposta quando referencia anual nao existir, distinguindo **indisponibilidade** de zero.
4. Reconciliar as medidas de `FATO_INTERNACAO` e `FATO_CAPACIDADE_LEITO` antes de validar as razoes; manter `T29_HISTORICAL=NOT_APPROVED` e aviso metodologico CNES previsto na apresentacao.
5. Validar os contratos fisicos da `%LINK_KEY` e da `LINK_ANALISE` separadamente, antes de materializar fatos ou construir painéis.

**Proxima etapa proposta:** revisao de contrato semantico com essas decisoes, usando as evidencias E13–E21; nao criar E22 por padrao, novos QVDs ou objetos de PAINEL como substituto desta aprovacao.

**Estado:** `E21=PASS_LOCAL_REPORTED_RESTRICTED`; `INDICATOR_ROLE_AND_YEAR_MATRIX=DOCUMENTED_FOR_REVIEW_NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 Draft sem merge.

---

## 62. Decisao aprovada pelo responsavel — contrato semantico V2 (14/10/2026)

**FATO DE DECISAO:** em 14/10/2026 o responsavel autorizou expressamente a **aprovacao exclusivamente semantica da minuta V2**, apos revisao critica de compatibilidade com o roteiro oficial do professor, as RN01–RN21, os Boundaries 6/7 e a Discovery VI. Esta secao registra a decisao sem mudar a natureza dos testes ja executados nem sobrescrever os checkpoints cronologicos anteriores.

**ESCOPO DO ACEITE:** significados analiticos, referencias temporais, medidas e denominadores candidatos, papeis municipais, tratamento de indisponibilidade, criterios de cobertura, agregacao e politica semantica de filtros. **Nao e aceite de expressao QlikView, compatibilidade numerica final, modelo associativo materializado ou implementacao.**

### 62.1 Escolhas semanticamente aprovadas

| Escolha | Alternativa | Escopo aprovado |
|---|---|---|
| D1 | B | Anual e competencias parciais distinguidos; nenhuma anualizacao automatica |
| D2 | B | Prevenir conflito ano/competencia antes de descartar a intencao de selecao |
| D3 | B | Denominador POP por residencia para demanda de residentes; por servico para oferta |
| D4 | B | Distinguir zero comprovado, ausencia, nulo, cobertura nao comprovada e indisponibilidade |
| D5 | B | Somar capacidade no municipio por competencia e calcular media de snapshots; 12 competencias validas para ano completo |
| D6 | B | Agregar componentes territoriais compativeis antes de calcular razoes; POP municipal contada uma unica vez por municipio/ano |
| D7 | B | Filtros exclusivos ou cruzados nao redefinem silenciosamente indicadores gerais |
| D8 | B | Gates semantico, de medidas, link key e associativo fisico separados |
| P1 | A | Competencia administrativa SIH/RD como referencia principal; DT_INTER e DT_SAIDA sao papeis exclusivos distintos |
| P2 | B | Indicadores anuais principais; razoes parciais identificadas pelo periodo e pela POP anual |
| P3 | B | QTD_LEITOS_SUS media como denominador principal de internacoes/leito |
| P4 | B | Integridade global da competencia e cobertura interpretavel no recorte analisado |
| P5 | B | Contrato de filtros por indicador, sem efeito silencioso sobre significado ou denominador |

**Nao altera:** 3 fatos, seus graos, 8 dimensoes, a arquitetura Star/constelacao com Link Table fisica, as chaves de papeis/conformadas ja aprovadas, capitulos academicos fechados, RN21 e regra historica T29.

### 62.2 Indicadores principais e delimitacao da fonte

| Indicador | Numerador | Denominador | Eixo territorial | Unidade/interpretacao |
|---|---|---|---|---|
| Internacoes de residentes por 1.000 habitantes | SUM(QTD_INTERNACAO) de residentes no universo SIH/RD de atendimentos processados na PB | POPULACAO_ESTIMADA do municipio de residencia no ano | Residencia | Internacoes processadas por 1.000 habitantes de referencia |
| Leitos SUS por 1.000 habitantes | Media dos totais por competencia de QTD_LEITOS_SUS | POPULACAO_ESTIMADA no ano | Servico/localizacao | Leitos SUS medios por 1.000 habitantes de referencia |
| Internacoes por leito SUS medio | SUM(QTD_INTERNACAO) de atendimentos realizados no periodo | Media dos totais mensais de QTD_LEITOS_SUS no mesmo municipio e periodo | Servico | Internacoes processadas no periodo / leito SUS medio do periodo; **nao taxa de ocupacao** |
| Fluxo residencia para servico | SUM(QTD_INTERNACAO) por par residencia/servico | Nenhum denominador POP implicito | Ambos os papeis | Contagem/distribuicao de fluxo |

**RN02/RN03:** internacoes de residentes neste Data Mart nao sao todas as internacoes ocorridas em qualquer UF, mas as identificadas no SIH/RD de atendimentos realizados na PB. Um registro RD e uma observacao administrativa, nao prova de paciente ou episodio clinico unico. **RN04:** IDENT=5 corresponde a continuidade, logo QTD_INTERNACAO=0; nao substituir por QTD_REGISTRO_AIH. Residentes externos podem integrar fluxo e totais elegiveis sem receber POP municipal PB.

### 62.3 Contrato temporal explicito — ajustes AC-02 e AC-05

| Contexto | Resultado semantico |
|---|---|
| Ano analitico unico com cobertura valida | Indicador anual |
| Competencias selecionadas dentro de um ano | Razao parcial, identificando competencias e populacao anual de referencia |
| Meses nao consecutivos | Identificar quais competencias foram usadas, sem apresentar intervalo continuo |
| Dois ou mais anos como serie separada por ano | Calculos independentes por ano, sem somar POP de anos diferentes |
| Varios anos num unico KPI dito anual | Indisponivel por ausencia de ano unico |
| Sem periodo, num KPI pontual | Indisponivel ate haver referencia temporal inequivoca |
| Sem selecao temporal, grafico dimensionado por ano | Serie anual separada por ano permitida, sujeita a validacao de medidas e cobertura |

O eixo principal e a **competencia administrativa SIH/RD** (P1=A). As datas clinicas de entrada e saida nao sao sinonimos e exigem rotulos proprios para analises especificas. Periodos parciais **nao sao taxa anual, incidencia clinica comprovada nem extrapolacao anual**. O mesmo valor de internacoes/leito em janelas temporais distintas nao demonstra intensidade equivalente.

**D2 exige prevencao antes da alteracao de selecoes.** E14/E15 demonstraram risco de intencao descartada; nenhuma solucao de interface foi aqui aprovada ou implementada.

### 62.4 Integridade e cobertura CNES — ajuste AC-03

A disponibilidade do arquivo mensal, a integridade global CNES/LT e a **cobertura do indicador por municipio/competencia/escopo** sao conceitos distintos. Os 36/36 arquivos LT e seus controles tecnicos globais **nao comprovam** cobertura integral em todo recorte.

Classificar separadamente: (a) medida observada/reconciliada; (b) zero quantitativo comprovado; (c) ausencia de linhas sem evidencia de zero; (d) inconsistencia tecnica; (e) exclusao associativa por filtro incompatível. Nem (c), nem (d), nem (e) podem virar zero por padrao.

Para media anual completa exigir 12 competencias validas do universo apresentado. Para periodo parcial exigir cada competencia selecionada valida. **Nao exigir permanencia dos mesmos estabelecimentos nas 12 competencias**: alteracoes legitimas no tempo nao invalidam isoladamente o mes. Para regiao, agregar totais por municipio dentro de cada competencia antes de media e razao; ausencia de municipio/mes requerido impede rotular resultado como regional completo.

**LIMITE PROBATÓRIO:** o criterio observavel que sustenta zero real ou cobertura suficiente para um municipio/competencia sem linhas LT ainda depende de validacao nos dados. Ate la, marcar indisponibilidade, sem inventar completude.

### 62.5 Universo e classificacao de estabelecimentos — ajuste AC-04

A RN21 preserva **todos os registros CNES/LT validos na fato**. Recorte estritamente hospitalar e analise derivada por classificacao do estabelecimento aplicavel historicamente; nao e exclusao fisica antecipada.

Cada indicador deve declarar explicitamente: fonte/medida, municipio/papel, competencia/ano, universo de estabelecimentos, regra de recorte hospitalar quando aplicavel, compatibilidade historica do atributo e interpretacao da comparacao SIH/RD × CNES/LT. Nao presumir classificacao historica nem equivalencia de universos nao validada. Para internacoes/leito o alinhamento de periodo e territorio e necessario, mas nao prova uso clinico efetivo do leito SUS.

### 62.6 Matriz de filtros P5 — ajuste AC-01

**RES:** internacoes de residentes/1.000 habitantes. **LEI:** leitos SUS/1.000 habitantes. **REL:** internacoes por leito SUS medio. **FLU:** fluxo residencia para servico.

| Filtro | RES | LEI | REL | FLU |
|---|:---:|:---:|:---:|:---:|
| Ano analitico | C | C | C | C |
| Competencia mensal | C | C | C | C |
| Municipio de residencia | C | B | B | C |
| Municipio de servico | B | C | C | C |
| Estabelecimento CNES | R | R | R | R |
| Procedimento realizado PROC_REA | R | I | B | R |
| Diagnostico principal DIAG_PRINC | R | I | B | R |
| Carater do atendimento | R | I | B | R |
| Motivo de saida/permanencia | R | I | B | R |
| Tipo/codigo de leito | I | R | B | I |
| Data clinica de internacao | R | I | B | R |
| Data clinica de saida | R | I | B | R |

**C (compativel):** sujeito a tempo, territorio, escopo, medidas e cobertura validos. **R (recorte especifico):** requer indicador/analise separada com contrato proprio aprovado; na ausencia deste, nao apresentar como indicador geral. **I (filtro nao aplicavel):** somente isolar explicitamente e com aviso/validacao fisica; caso contrario, indisponivel. **B (bloqueio):** indicador geral indisponivel no contexto.

Filtros simultaneos nao transformam uma incompatibilidade em permissao. Nao ignorar filtros silenciosamente, nao propagar medidas de fatos exclusivas como se fossem compartilhas, nem aprovar automaticamente novas taxas por procedimento, diagnostico, estabelecimento ou tipo de leito. Fluxo RES→SERV nao possui POP implicita.

### 62.7 Zero e indisponibilidade — ajuste AC-06

Numerador comprovadamente zero com cobertura valida e denominador **positivo** pode produzir indicador zero. Para razoes, denominador ausente, nulo, zero, negativo ou nao validado torna o calculo indisponivel. Para capacidade quantitativa, zero legitimo exige comprovacao no escopo; ausencia de registro sem demonstracao nao equivale a zero.

A interface futura devera diferenciar motivo de indisponibilidade: periodo/ano ambiguo, filtro incompatível, POP ausente ou externa, capacidade sem cobertura, medida invalida ou zero no denominador. Esses sao significados para interface, nao um novo schema ou autorizacao de implementar o PAINEL.

### 62.8 Ressalva historica CNES preservada

**T29_HISTORICAL=NOT_APPROVED.** A referencia descritiva de setembro/2019 nao tem vigencia historica demonstrada em 2017–2019. As 1.965/2.021 combinacoes codigo de tipo × codigo de leito × competencia (97,2%) sem nome historico comprovado **nao representam percentual de leitos**. Preservar os avisos visiveis e regras de filtros do Boundary 7, sem preencher NULL como zero nem generalizar nome set/2019.

### 62.9 Condicoes e limites da aprovacao

**APROVADO SOMENTE NO NIVEL SEMANTICO:** definicoes, papeis, politica temporal, filtros e criterios de indisponibilidade acima. **NAO APROVADO FISICAMENTE:** expressoes oficiais QlikView 12, reconciliação real das razoes, Set Analysis sob todos os filtros, mecanismo de prevencao ano/competencia, cobertura por municipio/mes, contrato definitivo SAD-LINK-V1/%LINK_KEY, materializacao da LINK_ANALISE, fatos/QVDs e PAINEL.

Gates independentes seguintes devem preservar os testes T24–T26 de reconciliacao de indicadores, controle de grão/medidas, nulos nao aplicaveis, associacoes role-playing, ausencia de $Syn/loops indevidos e correspondencia exata das chaves. A aprovacao semantica **nao autoriza** testes mutantes, geracao de dados, implementacao, modificacao dos Boundaries 6/7, abertura de novas estruturas, merge ou publicacao.

**MANTER OS STATUS FISICOS ATUAIS:** MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; LINK_KEY_CONTRACT=NOT_APPROVED; FACT_QVDS=NOT_STARTED; LINK_ANALISE_QVD=NOT_STARTED; PAINEL=NOT_STARTED; T29_HISTORICAL=NOT_APPROVED. Os registros de §61 e checkpoints anteriores sao historicos de testes e nao devem ser reclassificados retroativamente.

**PROVENIENCIA DO ACEITE:** aprovacao expressa do responsavel, comunicada no projeto em 14/10/2026 apos minuta V2, auditoria AC-01 a AC-06 e confirmacao de que nao ha conflito semantico impeditivo. Registro documental nesta branch de Discovery; **nenhum merge autorizado**.

---

## 63. F1/F2 — referências independentes de internações e capacidade (PREPARADO, NÃO EXECUTADO NOS DADOS REAIS)

**Autorização delimitada em 14/10/2026:** versionar `tools/preflight_f1_f2_referencias_independentes.py` e documentar o ensaio no PR #83 Draft. Não executar Windows/QlikView, criar QVD factual, Link Table ou PAINEL, modificar Boundaries 6/7, abrir E22, aprovar contrato físico ou fazer merge.

**Origem e contrato existente:** 36 CSVs `BASE/CONVERTIDA/RD/RDPB*.csv` e 36 CSVs `BASE/CONVERTIDA/LT/LTPB*.csv`, mais `EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.csv` (223 pares municipais PB derivados de fontes oficiais na III-C5.2). Reutiliza `COLUMNS`, `rows_from_csv` e `validate_pairs` do auditor municipal canônico, e constantes de medidas do preflight SIH/RD. A referência dos municípios do LT não é inferida dos municípios com demanda RD. 5.202 linhas RD de residência externa permanecem preservadas sem população PB atribuída.

**F1 — numeradores:** gerar referências independentes agrupadas por ano/competência, município de residência, município de serviço e par de fluxo. Preservar todo registro administrativo RD e calcular `QTD_INTERNACAO` apenas para `IDENT=1`, `IDENT=5` como continuidade não elegível. Gate: 566.672 linhas, 555.089 elegíveis, 11.583 continuidades, 5.202 residências externas; agrupamentos devem reconstituir totais e anos já verificados, sem criar identidade clínica nova.

**F2 — capacidade:** checar unicidade física de `CNES+COMPETEN+CODLEITO`, 35.518 LT, 36 competências, integridade de `QT_EXIST/QT_SUS/QT_NSUS` não negativos e `QT_NSUS=QT_EXIST-QT_SUS`. Somar `QT_SUS` apenas dentro de município de serviço × competência. Grade anual 223×3 distingue presença de linha, meses sem linha e valores zero observados. Ausência de linha não prova zero; 12 meses com linha permite no máximo **média candidata** sobre snapshots, nunca aprovação da cobertura completa ou do universo hospitalar. RN21 preservada; `T29_HISTORICAL=NOT_APPROVED`.

**Saídas:** seis CSVs F1 (residência/serviço/fluxo × ano/competência), dois CSVs F2 (mensal observado e grade anual candidata), manifesto JSON com hashes SHA-256 de entradas/saídas e hash do próprio script; diretório novo fora do repo, publicação somente após completar staging temporário no mesmo volume. Falhas antes da publicação não deixam resultados parciais. Testes sintéticos locais: compilação Python, nove artefatos em caso positivo, falha forçada de gravação com staging limpo, destino preexistente preservado; a execução real Windows/QlikView NÃO ocorreu.

**Próximos gates separados:** executar referência real e conferir SHA-256 sem alterar fontes; comparar numeradores RD e médias LT contra controles independentes e futura projeção Qlik, validar cobertura municipal/competência, universo de estabelecimentos e filtros P5. O resultado deste script não encerra T24–T26, não valida POP por múltiplos municípios, D2 seleção temporal ou `SAD-LINK-V1`. Qualquer novo experimento mutante continua dependente de autorização própria.

**Estado:** `F1_F2_SOURCE_RECONCILIATION=PREPARED_NOT_EXECUTED`; `SEMANTIC_V2=APPROVED_SEMANTIC_ONLY`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `FACT_QVDS=NOT_STARTED`; `LINK_ANALISE_QVD=NOT_STARTED`; `PAINEL=NOT_STARTED`; `T29_HISTORICAL=NOT_APPROVED`. PR #83 Draft/sem merge.
