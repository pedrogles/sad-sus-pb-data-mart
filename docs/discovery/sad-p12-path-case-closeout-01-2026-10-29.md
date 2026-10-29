# SAD — Closeout read-only de integridade P1.2 e caminhos Windows

**Gate:** SAD-P12-PATH-CASE-CLOSEOUT-01
**Data:** 29/10/2026
**Baseline:** main@9070806f26a1568948b0ce2b87c597beb7ec2d9e
**PRs de origem:** #172, #173 e #174 (todos Draft na inspeção inicial).
**Autorização:** o responsável respondeu "prossiga" à proposta específica de corrigir o comparador e auditar a cópia já salva. Não autorizou merge nem alterações em QVD/QVW.
**Preparação:** ChatGPT GPT-6 com GitHub (cloud, esforço não exposto).
**Execução física:** operador humano / Codex Local se disponível, Windows PowerShell 5.1; modelo/esforço efetivos a registrar. QlikView fechado.
**Estado:** EXECUTOR_VERSIONED / PARSER_NATIVE_NOT_RUN / WINDOWS_NOT_RUN / NO_PRODUCTION_APPROVAL.

## Objetivo único

Validar **a integridade atual** dos 25 arquivos protegidos, da fonte e da cópia descartável P1.2 já salva no gate #174, sem reexecutar a PoC, o pipeline ou o antigo -Verify. A identidade de caminhos no Windows é comparada com StringComparison.OrdinalIgnoreCase; bytes, tamanho e SHA-256 continuam obrigatoriamente idênticos.

O inspetor versionado deste gate é tools/Inspect-SadP12PathCaseCloseout01.ps1, independente do executável que gerou o HARD_STOP, com lógica reaproveitada conceitualmente do auditor read-only de #173. Não modificar os executores de #172, #173 ou #174.

## Evidências preservadas

- P1.1: quatro cartões com 183.532 / 183.311 / 188.246 / 555.089 nas capturas, sem homologar propriedades/globals.
- P1.2: CH02 renderizado após remoção da pesquisa numérica sobre competência textual. Arquivo exportado P12_CORRECTIVE_36_MESES.tsv.txt.txt, 36 competências de 201701 a 201912.
- Confronto independente restrito: agregação read-only das 30.255 linhas do arquivo E1 SIH/fluxo e comparação com a exportação do QlikView resultou 36/36 valores idênticos, zero extras e faltas e total 555.089. SHA-256 da exportação: 800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F. Não declarar validação byte a byte do SHA original E1.
- Gate #174: -Prepare com 25 protegidos preservados e fonte SHA-256 603464EB5AD5696DA001D5431194EF37D509448695DBBBB9EA1B7252F96EC791. -Verify relatou 25 avisos PATH_TEXT_CHANGED e zero avisos LENGTH_CHANGED ou SHA256_CHANGED, terminando em HARD_STOP_PROTECTED_BASELINE_DRIFT sem produzir aprovação final.
- Causa técnica reproduzível por leitura estática: comparação sensível a maiúsculas em Assert-Protected com operador -cne. A chamada usou root contendo "documents" enquanto o manifesto registrava "Documents". Isso pode explicar as 25 divergências textuais; a identidade exata dos pares será testada pelo novo auditor. A causa do HARD_STOP mais antigo de #172 permanece não demonstrada.

## Critérios operacionais e prevenção

O script deve:
1. Exigir versão Windows PowerShell 5.1, branch e commit exatos e worktree limpo.
2. Executar dez fixtures em memória no modo SelfTest, incluindo equivalência somente de capitalização e recusa quando há simultaneamente diferença de capitalização e hash.
3. Ler os manifestos de #174 e #172 e comprovar proveniência, SHA do runner anterior, mesmo baseline, caminhos esperados e cópias fora do Git.
4. Enumerar exatamente 10 QVDs EXTRACAO, 12 QVDs TRANSFORMACAO e três QVWs originais; verificar SHA-256, tamanho e estabilidade antes/depois da leitura de cada arquivo. Nenhuma divergência de conteúdo pode ser ignorada.
5. Conferir SHA-256 da fonte QVW anterior e que a cópia salva mudou em relação ao seu SHA inicial.
6. Imprimir stdout integral, sem gravar qualquer relatório ou tocar em dados.

A única entrada do gate é o manifesto existente em:

    C:\Users\pedro\Documents\SAD_P12_CORRECTIVE_EVIDENCIAS\SAD_P12_CORRECTIVE_96a3d4d13e8644d38cf686516c0c1247\p12_corrective_manifest.json

Reutilizar a cópia já salva. Não há nova preparação, novo QVW, reload, COM, A0 R1, exportação ou edição de gráfico.

## PASS / STOP

- PASS_10_SYNTHETIC_CASES_ONLY: fixtures executados com êxito em PowerShell 5.1.
- PASS_READ_ONLY_CURRENT_HASH_CLOSEOUT_ONLY_UI_NOT_RETESTED: 25/25 conteúdos idênticos aos baselines, fonte intacta, cópia realmente salva/diferente e caminhos com mesma identidade Windows; evidência restrita à integridade observada.
- BLOCKED: manifestos, proveniência, branch, permissão, parser ou localização inválidos.
- HARD_STOP: divergência de SHA/bytes/tamanho, arquivo extra/ausente, instabilidade, fonte alterada ou tentativa de escrita indevida.
- STOP após parser, uma rodada sintética e uma leitura real. Preservar stdout e todos os artefatos; não executar novamente o -Verify de #174 nem reclassificar retroativamente os HARD_STOPs anteriores.

Status de alcance: LINK_KEY_CONTRACT=NOT_APPROVED; MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; C2_FULL=NO_GO_NOT_APPROVED; P5_D2_UI=NOT_TESTED_GLOBAL; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False. Revisão de UX/legibilidade e eventual merge são decisões separadas.
