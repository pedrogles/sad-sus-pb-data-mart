# SAD-P2.3-A1-PHYSICAL-GATE-01 — implementação candidata

**Estado vigente em 28/10/2026:** `R2_PHYSICAL_PREPARED_AND_HASH_VERIFIED / VISUAL_SAMPLES_RESTRICTED_PASS / PAIRWISE_EXPLORATORY_PASS / VERSIONED_AUDITOR_EXECUTION_PENDING`. Os parágrafos históricos deste documento descrevem condições anteriores à R2.  
**Autorização:** conversa com responsável em 28/10/2026 autorizou corrigir drift e implementar A1. Merge, atualização dos QVD/QVW canônicos, Fase IX e homologação não foram autorizados.  
**Baseline:** `main@cdb6810c1e89b0fa86954f6478aaf9c49f2018ce` após PR #168. Documentação canônica: [contrato A1](sad-p23-a1-logical-design-2026-10-28.md), [VI-P4](../../TRANSFORMACAO/vi_p4_municipal_coverage.qvs), [C4-F](phase-8-c4f-vi-p4-export-readback-2026-10-21.md). PR #167 permanece Draft com `A0_NOT_VALIDATED` apenas para R1.

## Escopo tocável e artefatos

- `PAINEL/sad_p23_a1_island_physical_gate.qvs`: anexa uma tabela em memória `P23_A1_ISLAND`, derivada dos cálculos já existentes da `P4_MATRIX` e da reconciliação LT/fato. Não faz STORE, não cria QVD nem altera fatos/dimensões ou Link Key.
- `tools/Invoke-SadP23A1PhysicalGate01.ps1`: usa `PAINEL/phase_vii_technical_model.qvs` (16 tabelas) + ilha A1 (17ª tabela) apenas em QVW descartável em TEMP. Faz preflight de commit/branch, QVDs, log e hashes de **26 arquivos protegidos** (22 QVD, três QVW, um CSV). `-Prepare` cria cópia temporária e realiza checks do modelo; `-Verify` compara `path,bytes,sha256` por linha, prevenindo o falso positivo de serialização da R1.
- Este documento: execução manual e evidências, **não** teste executado.

Os seis únicos campos finais, todos exclusivos e propostos, são `P23_MUNICIPIO_6`, `P23_COMPETENCIA`, `P23_LINHAS_LT`, `P23_QT_SUS_OBSERVADO`, `P23_QT_EXIST_OBSERVADO` e `P23_ESTADO_OBSERVADO`. Seletor de município/competência local ao P2.3, **sem sincronização presumida** com seleções SERV/RES/tempo globais. A ausência LT mantém medidas NULL; jamais zero imputado. `ZERO_REAL_COMPROVADO=NOT_PROVEN`; `COBERTURA_HOSPITALAR=NOT_VERIFIED`.

## Uma única execução futura no Windows/QlikView 12

A execução deve partir da branch `feat/sad-p23-a1-physical-gate-01` em commit previamente conferido, com scripts versionados e limpos. Exigir Windows interativo, QlikView Desktop 12 e diretório de evidências **novo**, persistente, fora do Git e TEMP. O executor não é headless comprovado.

```powershell
$Root = (Get-Location).Path
$Head = (git rev-parse HEAD).Trim()
$EvidenceRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'SAD-EVIDENCIAS\P23_A1_R1'
$Auth = 'chat-2026-10-28-p23-a1-implementation'
powershell.exe -NoProfile -File tools\Invoke-SadP23A1PhysicalGate01.ps1 -Root $Root -ExpectedCommit $Head -EvidenceRoot $EvidenceRoot -ExecutionAuthorizationRef $Auth -Prepare
```

Antes da execução conferir o `HEAD` do PR, parser PowerShell no Windows, SHA-256 dos dois QVS e runner, 22 QVDs e três QVWs originais. O script falha fechado se o pin de Link QVD divergir, se houver campo inválido ou se a carga física não reconciliar.

**Oráculo obrigatório:** 223 municípios × 36 competências = **8.028 pares**, com **4.467** `ABSENT_NOT_ZERO_PROVEN`, **97** `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` e **3.464** `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED`. São 3.561 pares com linha, soma `LINHAS_LT=35.518`, soma observacional SUS=270.076 e existentes=337.147 (apenas reconciliação de snapshots, **não** capacidade anual).

O resultado máximo da preparação é `A1_TEMP_MODEL_PREPARED_VISUAL_NOT_TESTED`, nunca homologação de UX.

## Prova manual em um QVW temporário

Abrir apenas o caminho `TEMP_QVW` reportado. Em um único objeto de teste, apresentar campos próprios `P23_MUNICIPIO_6`, `P23_COMPETENCIA`, `P23_ESTADO_OBSERVADO`, as linhas e medidas observadas, conservando NULL nas ausências. Preferir tabela reta inicialmente para não ocultar combinações. Exibir o aviso: **“Filtros próprios de P2.3 — não sincronizados com filtros globais. Observabilidade CNES/LT sem comprovação de zero real ou cobertura hospitalar.”**

**Amostras C4-F em competência `201701`:**

| Município | Classe | Linhas LT | SUS | Existentes |
| --- | --- | ---: | ---: | ---: |
| `251740` | `ABSENT_NOT_ZERO_PROVEN` | NULL | NULL | NULL |
| `250460` | `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` | 1 | 0 | 40 |
| `250010` | `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED` | 3 | 20 | 20 |

Capturar estado neutro, três amostras, seleção municipal e temporal **locais** e conflito intencional em filtro **global** (SERV/tempo). A1 não pode mudar por seleção global e a seleção local A1 não deve alterar fatos. Se a interface suprimir NULL/células ou trocar ausência por zero, `BLOCKED`. Conferir Table Viewer: 17 tabelas, A1 sem vínculo, nenhuma `$Syn` ou loop. Exportar pares completos da ilha (preservando NULL) e comparar contra o TXT **histórico** C4-F; **não** reexecutar VI-P4.

Salvar prints, propriedades, log, exportação, manifesto e evidências humanas fora do Git. PNG/propriedade COM isolados não provam semântica/UX.

## Integridade e STOP

Após encerrar edição do QVW temporário e na mesma branch/commit/evidência, executar exatamente uma vez:

```powershell
powershell.exe -NoProfile -File tools\Invoke-SadP23A1PhysicalGate01.ps1 -Root $Root -ExpectedCommit $Head -EvidenceRoot $EvidenceRoot -ExecutionAuthorizationRef $Auth -Verify
```

`-Verify` checa hashes dos 26 artefatos e registra SHA do QVW temporário, **não** declara visual aprovado. A decisão após revisão das evidências será `PASS_LOCAL_A1_P23_CANDIDATE_ONLY`, `BLOCKED` ou `INCONCLUSIVE`; nenhum destes é `PRODUCTION_APPROVED`.

**STOP:** não abrir R2, repetir R1 A0, mesclar automaticamente, sobrescrever QVD/QVW, iniciar Fase IX/G1/T24–T26, alterar RN21/V2, Link Key ou modelo acadêmico. **Esta sessão criou apenas código e documentação no GitHub; Windows/QlikView/COM não foram executados.**


## Adendo — R1 bloqueada por sintaxe QVS (28/10/2026)

**EVIDÊNCIA DE OPERADOR (Windows/QlikView 12, console + trechos de log fornecidos na conversa):** execução `-Prepare` no commit `82ab0d644822134add964e61a1a168fa3329ede5`, diretório de evidências `SAD-EVIDENCIAS/P23_A1_R1`. `PARSER=PASS` do PowerShell; o log retornou `VII_PASS=1`, `A1_PASS=0`, `BLOCKED=0`, `ASSOCIATION_WARNING=0`. O modelo VII marcou `MODEL_TABLES=16 SYN_TABLES=0`. A ilha iniciou e passou a construção da população 669/223/669 e carregamento de 35.518 LT. No ponto `P23_LT_AUDIT`, o log exibiu `35.518=35.518`, `36=36`, `270076=270076`, `337147=337147`, `67071=67071`, `0=0`, mas interrompeu **antes de avaliar o IF completo**, apontando `Erro: Comando desconhecido` ao encontrar o `OR` na linha seguinte. Não houve `P23_A1_ISLAND` final provada.

**CAUSA RAIZ DELIMITADA:** no QVS da R1, **três comandos IF de controle** ultrapassavam a linha física de script (LT/fato, prejoin, oráculo final). A regra oficial de `if..then` no QlikView exige a cláusula `IF condição THEN` em uma só linha; quebras dentro de funções `If(...)` usadas em LOAD não se confundem com comandos de controle. Corrigidas as três condições em linha única na branch de implementação, **sem modificar operadores, números, campos ou oráculos**, conforme diff do PR #170.

**VEREDITO:** `R1=BLOCKED_QVS_IF_SYNTAX`; a contagem de LT e suas somas até o erro **não** são `PHYSICAL_PASS` da A1. `R1_PROTECTED_HASHES=NEEDS_MANIFEST_COMPARISON`: os arquivos `protected_before.json` e `protected_after_preparation.json` foram gerados, mas a integridade precisa ser comparada a partir dos manifestos originais; tamanhos de arquivos iguais não bastam. Não repetir `-Prepare` nem executar `-Verify` contra `P23_A1_R1`.

**UM único reteste candidato, se executado:** antes, comparar os 26 registros `path,bytes,sha256` do R1 e bloquear divergências; após `git fetch` e checkout do **novo HEAD revisado**, usar **pasta de evidências NOVA**, por exemplo `P23_A1_R2` (não reutilizar a R1), e repetir um único `-Prepare`. Se houver novo bloqueio, preservar log, classificar causa e STOP; não encadear R3 automático. Esta correção em Git é revisão estática, **não reexecução QlikView**. PR permanece Draft, sem merge.


## Adendo — R2 preparada, prova visual restrita e confronto C4-F recuperado (28/10/2026)

**FATOS VERIFICADOS NA CONVERSA — evidência de operador (sem reproduzir COM):** o operador executou `-Prepare` da R2 em Windows/QlikView 12 com `HEAD=b4790eb1ab96385275e9360be96f40b2aab2ce56` e `EvidenceRoot=SAD-EVIDENCIAS/P23_A1_R2`. Saída reportada: `VERDICT=A1_TEMP_MODEL_PREPARED_VISUAL_NOT_TESTED`, QVW `SAD_P23_A1_DISPOSABLE.qvw` apenas em TEMP. Capturas da caixa de tabela demonstraram as amostras `251740` (NULL/ausência), `250460` (LT=1, SUS=0, existentes=40), `250010` (LT=3, SUS=20, existentes=20) na competência `201701`. Capturas com seleção local P23 e filtros globais `PERIODO_COMPETENCIA=201802` e `SERV_COD_DATASUS_6=250010` mantiveram os três resultados em cenários específicos; **não** é prova global de todas as rotas, bookmarks ou estados de UI. Table Viewer exibiu 17 tabelas e `P23_A1_ISLAND` com seis campos sem ligação visível, sem `$Syn` visível. Na mesma R2, o operador executou `-Verify`: `PROTECTED_SOURCES_SHA256_UNCHANGED=True` e `VERDICT=SOURCE_INTEGRITY_CONFIRMED_VISUAL_ACCEPTANCE_PENDING`, com limite de prova reportada pelo operador (os 26 hashes e QVW não foram reabertos remotamente).

**EVIDÊNCIA DOCUMENTAL/ARQUIVOS EXAMINADOS NESTA REVISÃO — readback exploratório, NÃO executor canônico versionado:** arquivo exportado `P23_A1_R2_export.tsv.txt` de 414.780 bytes, SHA-256 `593b8812eaed2df9c3e6ca49f84b8c750a133966af36724963d8de2815636c42` (arquivo anexado pelo operador). ZIP histórico `VI-P4-evidencias.zip` recebido via anexo (31.217 bytes), SHA-256 `f79e66584f1b6bcf146861781b318f36820b62e89c335368a3785411f9a4d527`, **igual** ao C4-F; seus três membros também conferem exatamente com os hashes documentados no C4-F. O TXT `municipio_mes_observabilidade.txt` possui SHA-256 `1cbf654d6fe0cd45e77abb97f1f42f1545a2ca9106eae2cf1a6f3afe42a44796`. Os TXT anuais e por competência têm 669 e 36 linhas, respectivamente.

**Confronto exploratório independente de artefatos (mesma linhagem CNES/LT):** comparar os seis campos equivalentes para cada chave `(MUNICIPIO, COMPETENCIA)` nos 8.028 pares produziu zero pares ausentes/extras, zero pares duplicados e **zero divergências em qualquer um dos seis campos**; oráculos das três classes: 4.467 ausentes, 97 SUS observado zero e 3.464 positivos. Somas iguais no C4-F e R2: `LINHAS_LT=35518`, `QT_SUS=270076`, `QT_EXIST=337147`. Reconciliações dos registros anuais e mensais históricos tiveram zero diferenças. Flags C4-F `ZERO_REAL_COMPROVADO=NOT_PROVEN` e `COBERTURA_HOSPITALAR=NOT_VERIFIED` em todos os 8.028 pares; não são campos físicos da A1 e permanecem limites obrigatórios da apresentação.

**GATE DE AUDITORIA VERSIONADO AINDA PENDENTE:** o exame exploratório acima ocorreu na sessão de ChatGPT antes de existir script de auditoria previamente commitado. Conforme `AGENTS.md`, **não transformar o exame exploratório em `GATE_PASS` formal**. Para regularização, o auditor Python de leitura única `tools/audit_sad_p23_a1_c4f_pairwise.py` foi adicionado ao PR #170 **após** o exame inicial, exigindo execução posterior com arquivos originais, relatório JSON novo fora do repositório e resultado `PASS_PAIRWISE_EXPORT_C4F_R2_CANDIDATE_ONLY` (não alegado nesta documentação). Não reexecutar o QlikView, nem atualizar/reescrever os artefatos originais.

**Decisão atual da R2:** `R2_PHYSICAL_PREPARATION_AND_PROTECTED_SHA=PASS_REPORTED_BY_OPERATOR`; `R2_VISUAL_3_SAMPLES_AND_2_ISOLATION_SCENARIOS=PASS_RESTRICTED_BY_SCREENSHOTS`; `R2_EXPORT_PAIRWISE_EXPLORATORY=PASS_INDEPENDENT_READBACK_OF_TWO_ARCHIVES`; `VERSIONED_AUDITOR_PASS=NOT_YET_EXECUTED`; `PASS_LOCAL_A1_P23_CANDIDATE_ONLY=NOT_YET_GRANTED`. `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Evidências grandes, PNG, TXT, QVD e QVW permanecem fora do Git. Encerrar esta frente após leitura/revisão da auditoria formal, sem novos COM, sem R3 e sem merge automático.
