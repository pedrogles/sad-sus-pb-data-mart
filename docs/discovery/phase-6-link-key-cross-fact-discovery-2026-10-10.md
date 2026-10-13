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

