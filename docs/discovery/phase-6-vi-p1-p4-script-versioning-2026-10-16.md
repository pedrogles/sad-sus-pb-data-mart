# Fase VI — Regularizacao de versionamento de preflights (PR Draft)

**Objetivo unico:** recuperar rastreabilidade dos executores VI-P1 a VI-P4 no Git, a partir dos pacotes locais efetivamente distribuidos em 16/10/2026. Nao muda a arquitetura, os QVDs, as tres fatos, a semantica V2, a Link Table, os QVWs originais ou os resultados previamente reportados.

## Origem e cadeia de confianca

- Base: `main` `ad37e6f3947208eef5d7f4455b1172ded9999170`, revisao em 16/10/2026.
- VI-P1: pacote final **R2**, PASS local read-only restrito reportado pelo responsavel.
- VI-P2: pacote final original, PASS local read-only restrito reportado.
- VI-P3: pacote final **R4**, PASS local de candidatos numericos T24-T26 limitado a Joao Pessoa/2018 e setembro/2018; previa discrepancia por `Aggr()` detectada e candidata reconciliada, **nao** homologada para cobertura generica.
- VI-P4: executado **uma vez** a partir de 52721d4 no QlikView 12; **BLOCKED_GRID_RECONCILIATION**. A revisao estatica posterior da associacao possui novo commit, ainda sem execucao local. A matriz de 223 municipios × 36 competencias classifica observacoes, nunca comprova zero real ou cobertura hospitalar.
- A auditoria de stdout/log relatada nas conversas precedentes **nao equivale** a auditoria independente dos QVDs binarios, do conjunto de evidencias local ou da aplicacao final.

Os QVS dos pacotes finais foram copiados sem mudanca de conteudo. Os executores PS1 foram adaptados exclusivamente para ler o QVS versionado de `TRANSFORMACAO/`, e um preflight `VI-GOV` garante `HEAD` Git identificavel, dois arquivos tracked e sem alteracoes locais antes de executar; estes PS1 adaptados **nao foram executados em Windows**. Requer smoke de VI-P4 ao retomar; nao repetir VI-P1 a P3 apenas para alterar layout de arquivos.

## Arquivos e execucao

| Gate | Executor em `tools/` | QVS em `TRANSFORMACAO/` | Situacao |
|---|---|---|---|
| VI-P1 | `Invoke-SadViP1Readonly.ps1` | `vi_p1_readonly.qvs` | PASS local do pacote R2; layout Git ainda nao reexecutado |
| VI-P2 | `Invoke-SadViP2Readonly.ps1` | `vi_p1_readonly.qvs` (reutilizado) | PASS local do pacote original; layout Git ainda nao reexecutado |
| VI-P3 | `Invoke-SadViP3Readonly.ps1` | `vi_p3_source_reference.qvs` | PASS local do pacote R4; layout Git ainda nao reexecutado |
| VI-P4 | `Invoke-SadViP4Readonly.ps1` | `vi_p4_municipal_coverage.qvs` | **BLOCKED local** em duas execucoes; ultima correcao tecnica versionada, nao executada |

### SHA-256 exato dos QVS (congelado dos pacotes locais)

- `vi_p1_readonly.qvs`: `80E80770C59FBCC48142DA8E4CE6BF87D3CD6113FCACE977E0DACEA0CA78558B` (P1+P2).
- `vi_p3_source_reference.qvs`: `FA0F0D4E263CC9793AA6ED2403BF3849BE47D8F095A59E3BB9FA234708071BEF`.
- `vi_p4_municipal_coverage.qvs`: original `A2153E27E08CF2F236BCF07F6A7D7D99AE682446D7E37D3F3E5C0D609D734EE5`; **candidato revisado** `DD0DE8742F714AEC0F9F9FB2D5910C17CADD93B374CB316EE4E1C2C00C78C2AB` (ainda nao executado).

### VI-P4 — executar APOS revisar o PR e conferir branch/working-tree

Na raiz local do clone da branch do PR (NAO use ZIP como codigo):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Invoke-SadViP4Readonly.ps1 -Root (Get-Location).Path -RunQlik
```

Precondicoes: Git no PATH, Windows com QlikView 12 COM, 21 QVDs locais previamente protegidos, branch atual confirmada, executores e QVS rastreados/sem alteracoes. Runner cria somente QVW/log, manifests e tres TXT temporarios em `%TEMP%`; 3 `STORE ... (txt)` exclusivos da evidencia, **nenhum STORE QVD**. `TRANSF.qvw` e `PAINEL.qvw` nao sao recarregados. Rodar **uma vez**, anexar stdout/log e PARAR. Em BLOCKED, investigar antes de novo teste.

## Escopo de criterio de aceite e saida

- PASS desta regularizacao: branch + PR Draft com os quatro PS1 e tres QVS textuais; QVS com SHA identico aos pacotes; preflight de Git; nenhuma mudanca em dimensoes/fatos ou QVD; regra de versionamento no `AGENTS.md` proposta; **sem merge**.
- P4 experimental PASS futuro: 8.028 celulas municipio/competencia reconciliadas com staging e fato, observadas/ausentes sem imputacao de zero, 21 QVDs inalterados, tres TXT temporarios; nao certifica cobertura hospitalar.
- P4 BLOCKED se QVD mudou, cardinalidade nao bate, Qlik falha, evidencia nao contemporanea ou reprovacao de semantica; nao repetir automaticamente.
- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PRODUCTION_APPROVED=False`.

**STOP**: encerrar regularizacao ao abrir PR Draft. Rodar VI-P4 somente depois que o responsavel conferir o PR/branch e solicitar expressamente; merge depende de aprovacao separada.

## VI-P4 — bloqueio reproduzido e correcao candidata (16/10/2026)

**Execucao Windows reportada:** VERSIONED_GIT_HEAD=52721d4fc67ddf75a68e5e525be48d1a7fed3b08. O QlikView 12 leu/reconciliou 35.518 linhas LT (35.518 SK unicas), com somas de snapshots SUS=270.076, existentes=337.147 e nao-SUS=67.071, BAD=0. Foram agregados **3.561 pares municipio x competencia realmente observados**; a grade de 223 x 36 teve **8.028 pares**. O LEFT JOIN natural em dois campos nao encontrou nenhuma correspondencia, classificando equivocadamente todos os 8.028 pares como ausentes. A reconciliacao da matriz interrompeu o script antes de qualquer STORE TXT. O executor informou ALL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True, VERDICT=BLOCKED_OR_INCONCLUSIVE. Evidencia local: %TEMP%/SAD_VI_P4_READONLY_20261016T153516141Z_33b344dcabe445f89a5cdaa6f45a900f/SAD_VI_P4_DISPOSABLE.qvw.log. Fonte: stdout/log compartilhado pelo responsavel; nenhum QVD auditado diretamente pelo agente.

**Causa ainda nao comprovada:** incompatibilidade fisica de representacao/associacao entre os pares lidos e a grade; o log original nao mostra o eixo divergente. Nao atribuir 8.028 ausencias a ausencia real de leitos.

**Correcao delimitada proposta, versionada nesta mesma branch:** P4_PAIR_KEY=Hash128('P4-OBS', Trim(Text(MUNICIPIO)), Trim(Text(COMPETENCIA))) tanto para os pares de LT quanto para a grade; a LEFT JOIN passa a compartilhar apenas essa chave temporaria (nao e %LINK_KEY do Data Mart). Novo preflight obrigatorio verifica exatamente 3.561 pares LT distintos, correspondencia individual por municipio/competencia e **3.561 chaves de par presentes na grade**. Em falha, emite PREJOIN ... GRID_SAMPLE ... LT_SAMPLE e BLOCKED_PREJOIN_KEYS_WITH_AXIS_DIAGNOSTICS, antes do join e de qualquer exportacao; o PowerShell passa a mostrar tais mensagens com P4_NATIVE_DIAG. Guardas restantes continuam exigindo grade 8.028, 223/36, reconciliacao integral, tres TXT de evidencia somente em %TEMP% e hashes dos 21 QVDs inalterados. Os zeros continuam **nao comprovados**; a cobertura hospitalar continua **nao verificada**.

**STATUS:** alteracao de QVS/PowerShell revisada estaticamente e commitada; sem recarga QlikView do novo commit. Uma unica nova execucao controlada no Windows e permitida para verificar esta correcao **somente apos git pull --ff-only e confirmacao de SHA-256/HEAD**. Se falhar, preservar logs e **PARAR**, sem novas iteracoes automaticas. Nao efetuar merge, modificar QVDs ou implementar LINK_ANALISE.qvd.

## VI-P4 — diagnostico da segunda execucao versionada (16/10/2026)

**Fonte de evidencia:** stdout da execucao Windows/QlikView 12 fornecido pelo responsavel, commit `7b33308853bf09892eaae059edaeec0d593d3e77`, QVS SHA-256 `DD0DE8742F714AEC0F9F9FB2D5910C17CADD93B374CB316EE4E1C2C00C78C2AB`. Pasta local: `%TEMP%/SAD_VI_P4_READONLY_20261016T154659455Z_e3f4c6049a17498e9bd82b66fabfcb11`. Resultado `VERDICT=BLOCKED_OR_INCONCLUSIVE`, com `BLOCKED_PREJOIN_KEYS_WITH_AXIS_DIAGNOSTICS`.

- `OBS=3561`, `UNIQUE=3561`: observacoes LT agregadas por municipio e competencia, sem duplicatas de par detectadas.
- `MUN_MATCHES=3561`: 100% dos codigos municipais encontraram correspondencia na grade pelo mapeamento individual.
- `COMP_MATCHES=0`: nenhum dos valores de competencia encontrou correspondencia no `ApplyMap` individual da competencia.
- `PAIR_MATCHES=3561`: **todas as chaves compostas** `Hash128('P4-OBS', Trim(Text(MUNICIPIO)), Trim(Text(COMPETENCIA)))` foram encontradas na grade.
- `GRID_SAMPLE=251740|201701`, `LT_SAMPLE=250010|201701`: os exemplos exibem a mesma competencia textual, mas nao comprovam a representacao interna dual/numerica. Possivel incompatibilidade de representacao no mapeamento individual bruto de `COMPETENCIA` e uma **hipotese tecnica**, nao diagnostico de conteudo da fonte.
- `ALL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True`: nenhum QVD modificado segundo auditor local; nenhum TXT final materializado, pois o QVS interrompeu antes dos tres `STORE`.

**Conclusao do gate:** o `COMP_MATCHES=0` e a correspondencia composta de `3561/3561` coexistem; a falha ocorreu no **controle pre-join individual**, antes de testar efetivamente a junção e a classificacao final. Nao inferir que 8.028 pares estao ausentes e nao aprovar observabilidade/cobertura. A hipotese seguinte seria comparar competencias **por normalizacao textual/hashes em ambos os eixos**, em vez de `ApplyMap` de campo dual original; qualquer mudanca de codigo exige **novo escopo delimitado e aprovacao expressa**, commit e um teste posterior independente. Nao fazer terceira recarga automatica.

**Status preservado:** `VI_P4=BLOCKED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `ZERO_PROOF=NOT_PROVEN`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PRODUCTION_APPROVED=False`. PR #98 continua **Draft**, sem merge.

## VI-P4 — ultima correcao autorizada do mapeamento individual (16/10/2026)

**Autorizacao expressa:** o responsavel aprovou uma **ultima correcao delimitada** apenas no controle individual de `COMPETENCIA`, dentro do PR Draft #98 e sem merge. Nao ha autorizacao para expandir a investigacao, modificar fatos/dimensoes, recriar QVDs ou aprovar cobertura e indicadores.

**Evidencia da segunda execucao Windows:** commit `7b33308853bf09892eaae059edaeec0d593d3e77`, QVS SHA-256 `DD0DE8742F714AEC0F9F9FB2D5910C17CADD93B374CB316EE4E1C2C00C78C2AB`; `OBS=3561`, `UNIQUE=3561`, `MUN_MATCHES=3561`, `COMP_MATCHES=0`, `PAIR_MATCHES=3561`. Os hashes/cabecalhos dos 21 QVDs ficaram inalterados segundo o executor. O controle individual reprova; **nao ha PASS da matriz**.

**Mudanca minima:** as duas ocorrencias da chave de `P4_GRID_COMP_MAP` (criacao do mapping e argumento do ApplyMap em `COMP_MATCHES`) passam a usar exatamente `Hash128('P4-COMP',Trim(Text(COMPETENCIA)))` nos dois lados. A chave composta `P4_PAIR_KEY` permanece **identica** a que ja encontrou 3.561/3.561 matches. Mecanismos e criterios fail-closed, tres `STORE TXT` sob %TEMP%, zero imputado proibido, 21 QVDs em modo leitura e criterio `COMP_MATCHES=3561` permanecem inalterados. Trata-se de **hipotese tecnica dirigida pelo log** (sem prova independente do mecanismo dual).

**Novo QVS SHA-256:** `CA3CA2EDA0101D3E09471738B5B1C8281A2E25691B563D44FE157256535C3AC4`, verificado offline com conteudo byte a byte identico ao blob Git `0d60b12d6217e9f86f504827d9df9c777c03235e`. O PowerShell foi atualizado para exigir o novo SHA. **Nao foi executado no Windows nem no QlikView 12 nesta revisao**; inspeção estatica apenas.

**Criterios finais e STOP:** apos `git pull --ff-only`, conferir branch/HEAD, SHA-256 e executar somente uma recarga read-only. PASS somente se `COMP_MATCHES=3561`, `PAIR_MATCHES=3561`, grade 8.028, somatorios intactos, evidencias de tres TXT validadas e hashes de 21 QVDs identicos. Em qualquer BLOCKED/INCONCLUSIVE: **encerrar este ciclo sem novos patches automaticos**, preservar logs e propor revisao independente com escopo/autorizacao separados. Nem PASS restrito demonstra escopo hospitalar/zero real/Link Table/indicadores de producao.

**Status:** `VI_P4=BLOCKED_UNTIL_NEW_LOCAL_VALIDATION`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `ZERO_PROOF=NOT_PROVEN`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PRODUCTION_APPROVED=False`; `PR_MERGED=False`.
