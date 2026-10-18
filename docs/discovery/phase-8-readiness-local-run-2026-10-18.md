# Fase VIII — Readiness READ-ONLY: primeira execução reportada e revisão do executor (18/10/2026)

**Objetivo:** verificar o baseline de 22 QVDs, QVWs canônicos, QlikView Desktop e disponibilidade das referências independentes F1/F2/F3, sem recarga de Qlik, escrituras em dados ou indicadores. **Não** é execução da VIII-B.

## 1. Execução reportada pelo responsável

- Branch local: `feat/phase-viii-readiness-20261018`, HEAD `e3e40cd1af6b69cc2ae350e8b3375425da24eb13`.
- Executado: `powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiReadiness.ps1 -Root (Get-Location).Path`.
- Runner SHA-256: `51D4A537B79672BDA1D0C90AC0BBBDEB7B43924BC7089B7DABAF55CD28B459FB`.
- EVIDENCE_DIR: `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_READINESS_d978b8fd0b4346099438530dcf4ea0c7`.
- Console: `INVENTORY_22_QVD=PASS_READ_ONLY_HEADERS_AND_HASHES`; `ORIGINAL_22_QVD_SHA256_AND_HEADERS_UNCHANGED=True`; `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`.
- Plataforma: `WINDOWS=True`, `QLIKVIEW_EXE_PRESENT=True`, versão `12.0.20000.0`, `QLIKVIEW_COM_REGISTERED=True`. **COM não foi instanciado; Reload não executado.**
- Referências: `F1F2=NOT_PROVIDED`, `F3=NOT_PROVIDED`.
- Veredito: `BLOCKED_READONLY_PREFLIGHT READINESS_ENVIRONMENT_OR_REFERENCES_NOT_READY` e exceção de parada prevista. Sem evidência de falha dos QVDs. Sem PASS de T24–T26.
- `git status --short` reporta dez QVWs históricos **não rastreados**, todos sob `TRANSFORMACAO/`; preservar e **não** usar `git clean`/exclusões para repetir o teste.

**Qualificação:** stdout copiado pelo responsável e correlacionado ao código/commit versionados. Manifestos de `EVIDENCE_DIR`, binários e log completo não foram anexados para auditoria independente. Preservar a tentativa e o seu estado `BLOCKED`; uma nova revisão de código exige outra execução antes de qualquer PASS de readiness.

## 2. Fortalecimento da revisão seguinte — não executado

Depois da primeira tentativa, o runner foi revisado na branch para validar **8/8 CSV F1/F2** contra `manifest_F1_F2.json`, **5/5 CSV F3** contra `manifest_F3.json` e **9/9 vínculos F3→F1/F2** pelas declarações de SHA de entrada. As mudanças do runner **não receberam nova execução Windows** até o momento deste registro; nenhuma aprovação do commit anterior transfere PASS automaticamente.

Regras: leituras de QVD/QVW/CSV/JSON e hashes; somente manifestos `*.csv` derivados no diretório novo `%TEMP%\SAD_VIII_READINESS_...`. Nenhum `STORE`, `Reload`, QVW de ensaio, cálculo numérico de KPI ou tratamento novo de CNES por código. Os diretórios de evidências devem existir no Windows local e ser informados como parâmetros; não há auto-download nem regeneração de F1/F2/F3.

### Próximo procedimento seguro

1. Identificar a pasta que contém `manifest_F1_F2.json` e os oito CSV `F1_*.csv`/`F2_*.csv` e a que contém `manifest_F3.json` e os cinco CSV `F3_*.csv`. Não confundir ZIP compactado com diretório extraído.
2. Na branch correta, fazer `git fetch origin`, `git pull --ff-only`, `git status --short`. Os QVWs históricos untracked não devem ser apagados.
3. Rodar **uma** verificação: `powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiiReadiness.ps1 -Root (Get-Location).Path -F1F2Dir '<pasta-F1F2>' -F3Dir '<pasta-F3>'`.
4. Conferir marcadores `F1F2=PASS_MANIFEST_SHA256_MATCH_8_OF_8`, `F3=PASS_MANIFEST_SHA256_MATCH_5_OF_5`, `F3_F1F2_CROSS_MANIFEST_LINK=PASS_9_OF_9`, `VERDICT=PASS_READONLY_ENTRY_INVENTORY_CANDIDATE_ONLY_NOT_INDICATOR_APPROVAL`, hashes QVD/QVW preservados e commit exato. Entregar stdout e manifestos sem incluir os QVDs/QVWs.
5. Se falhar, manter `BLOCKED` e diagnosticar a causa, sem reexecutar automaticamente. Mesmo PASS de readiness não implementa T24–T26.

## 3. Autorização observacional CNES/LT

O responsável aprovou nesta sequência a análise de T25/T26 **somente no universo CNES/LT observado**, sob ressalva explícita de cobertura histórica, sem afirmar conjunto hospitalar completo ou validar valores de indicador em município sem evidência suficiente. A decisão foi documentada no PR #108 (VIII-A) e não muda o objetivo restrito deste PR de readiness.

**Estado:** `VIII_READINESS_QVD_BASELINE=PASS_LOCAL_REPORTED_READ_ONLY`; `VIII_READINESS_F1F2_F3=BLOCKED_PATHS_MISSING_AT_FIRST_RUN`; `VIII_READINESS_CURRENT_RUNNER_REVISION=VERSIONED_NOT_RUN`; `VIII_B=NOT_EXECUTED`; `PRODUCTION_APPROVED=False`.

**Governança:** nenhum merge automático; `current-state.md` em main não deve ser alterado antes de revisão e integração documental autorizada.


## 4. Falha de parser na segunda tentativa e correção delimitada (18/10/2026)

**Fonte:** saída PowerShell apresentada pelo responsável após `git pull --ff-only` até o commit `6a9a1e4401d6f85aab68da5e9b090393fe79c675`. Os dois caminhos históricos `%TEMP%\sad-f1-f2-20261014-191743\manifest_F1_F2.json` e `%TEMP%\sad-f3-20261014-194242\manifest_F3.json` retornaram `True` em `Test-Path`.

A chamada ao preflight retornou `ParserError` na **análise sintática**, antes do início do corpo do script. O erro localizado na branch era a condição de SHA-256 da linha 239 truncada em `'^[A-Fa-f0-9]{64}`, com o restante do programa inserido equivocadamente nesse ponto e um segundo bloco duplicado após `finally`. O apontamento do PowerShell na linha 244 (`Get-Command 'Qv.exe'`) era efeito colateral dessa string não terminada; **não** comprova erro do QlikView ou das evidências F1/F2/F3. Nenhuma linha de output operacional `EVIDENCE_DIR=` foi emitida na segunda tentativa, portanto **nenhum inventário, validação de hashes ou escrita do próprio runner ocorreu nessa tentativa**.

**Correção delimitada:** commit `f3358188398c69457b1079e517f15aa4d801e180` na mesma branch/PR #109, reconstitui integralmente o bloco de vínculo F3↔F1/F2 e remove a duplicação; preserva as verificações anteriores e invariantes de READ-ONLY. Inspeção estática do texto corrigido: 301 linhas, zero desequilíbrios brutos de parênteses/chaves, presença única de `F3_F1F2_CROSS_MANIFEST_LINK` e do veredito de sucesso. **Isso ainda não é validação de parser PowerShell nem execução no Windows.**

**Próximo gate único:**
1. `git pull --ff-only` na branch `feat/phase-viii-readiness-20261018`.
2. Usar `[System.Management.Automation.Language.Parser]::ParseFile()` no arquivo versionado, sem executar a rotina. `PARSER=PASS` exige lista de erros vazia; se houver erro, parar e compartilhar linhas do erro.
3. **Somente com parser PASS**, executar uma vez o preflight READ-ONLY com `-F1F2Dir` e `-F3Dir` já localizados.
4. Registrar stdout, commit, novo hash do runner, hashes antes/depois, manifesto de evidência. Se qualquer vínculo/arquivo não satisfizer o contrato, `BLOCKED` e investigar sem recriar os oráculos.

**Estado após a correção:** `VIII_READINESS_PARSER=UNTESTED_NEW_COMMIT`; `VIII_READINESS_MANIFESTS=UNTESTED_NEW_COMMIT`; `VIII_B_QLIK_INDICATORS=NOT_EXECUTED`; `PRODUCTION_APPROVED=False`. Nenhum merge, QVD/QVW original modificado, nem Fase IX.


## 5. Gate de prontidão local concluído (18/10/2026)

**Origem da evidência:** stdout transmitido pelo responsável após execução real no Windows PowerShell. **Script executado:** `tools/Invoke-SadPhaseViiiReadiness.ps1` na branch `feat/phase-viii-readiness-20261018` no commit `0dbb23f29673f6ea0d4965905397ba3800c840c6`. **Hash SHA-256 reportado do script:** `02CFADBE68AED611E15B59850166726820C49821978685E938FB72A32ED7F2C4`.

**Parser independente pré-execução (reportado):** `[System.Management.Automation.Language.Parser]::ParseFile()` sem erros, `PARSER=PASS`. O runner de readiness foi executado **uma vez após essa validação**, com diretórios de F1/F2 e F3.

**Manifestos e baseline reportados:**
- `INVENTORY_22_QVD=PASS_READ_ONLY_HEADERS_AND_HASHES`.
- `F1F2=PASS_MANIFEST_SHA256_MATCH_8_OF_8`.
- `F3=PASS_MANIFEST_SHA256_MATCH_5_OF_5`.
- `F3_F1F2_CROSS_MANIFEST_LINK=PASS_9_OF_9`.
- `WINDOWS=True`, `QLIKVIEW_EXE_PRESENT=True`, `QLIKVIEW_EXE_VERSION=12.0.20000.0`, `QLIKVIEW_COM_REGISTERED=True`.
- `ORIGINAL_22_QVD_SHA256_AND_HEADERS_UNCHANGED=True` e `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`.
- `QLIKVIEW_RELOAD=False COM_INSTANTIATION=False QVD_WRITES=0 QVW_WRITES=0`.
- **Veredito emitido:** `VERDICT=PASS_READONLY_ENTRY_INVENTORY_CANDIDATE_ONLY_NOT_INDICATOR_APPROVAL`.

**Artefatos reportados, não anexados nesta revisão:** `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_READINESS_a3be084f2a0741c3847334f8e1484d62`. O conteúdo real dos manifestos CSV em disco não foi revisado independentemente nesta sessão. O sucesso é **PASS de execução local reportada** para a verificação READ-ONLY de entrada, não homologação do código em CI, não revalidação física de F1/F2/F3 por ferramenta independente e não PASS do QVW experimental.

**Critério de encerramento do subgate:** a prontidão da entrada **atingiu o PASS local candidato**, com referência explícita à revisão executada. Não repetir esse preflight sem gatilho de integridade; se houver outra revisão de script, ela exigirá nova prova. O erro `ParserError` na revisão anterior permanece registrado como tentativa falha, não foi apagado retrospectivamente.

**Próxima etapa separada:** Fase VIII-B, sob **branch independente**, QVS/runner commitados antes de executar, QVW descartável apenas em `%TEMP%`, oráculos independentes F1/F2/F3 e cenários T24–T26, preservando decisões de escopo LT observado e indisponibilidade. Não usar estes PASS para afirmar denominador final, cobertura hospitalar, comportamento P5/D2 ou aprovação da produção.

**Estados:**
- `VIII_READINESS_PARSER=PASS_LOCAL_REPORTED`.
- `VIII_READINESS_QVD_AND_REFERENCE_MANIFESTS=PASS_LOCAL_CANDIDATE_ONLY`.
- `VIII_B_INDICATORS=NOT_EXECUTED`.
- `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`.
- `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `T29_HISTORICAL=NOT_APPROVED`; `PRODUCTION_APPROVED=False`.

**Governança:** PR #109 continua Draft, `main` não alterada por esta escrita documental, merge não autorizado, Fase IX não iniciada.
