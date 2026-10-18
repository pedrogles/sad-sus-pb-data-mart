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
