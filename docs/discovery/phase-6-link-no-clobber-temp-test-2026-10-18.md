# Fase VI — teste versionado de File.Move sem sobrescrita em %TEMP%

**Data:** 18/10/2026. **Base confirmada:** `main@1ef2e271fd10cd005748fe2084791f2eb30209fc`, PR #101 integrado.  
**Objetivo:** validar em Windows/.NET a operação de publicação sem sobrescrita utilizada no executor da Link Table **sem gerar QVDs, sem QlikView COM e sem acessar QVDs/QVWs do projeto**.  
**Estado atualizado com evidência local informada em 18/10/2026:** `VI_LINK_MOVE_TEST=PASS_LOCAL_REPORTED` para os três cenários em arquivos TXT temporários. O script já estava commitado antes de sua execução. Não é uma execução conduzida ou auditada diretamente pelo agente; stdout fornecido pelo responsável, sem inspeção independente do arquivo bruto no Windows.

## Entradas e escopo

- `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md` inspecionados nessa ordem.
- `docs/discovery/boundary-7-implementation-plan.md` (§ fase VI); `docs/discovery/phase-6-link-atomic-publication-review-2026-10-18.md`; executor `tools/Invoke-SadViLinkAnalise.ps1`.
- **Único novo script:** `tools/Test-SadViLinkNoClobber.ps1`. Exige execução a partir do próprio caminho rastreado, Git HEAD válido e ausência de modificações locais neste script.
- **Arquivos escritos pelo teste:** somente `stage.txt` e `final.txt` em três subpastas de um diretório exclusivo `%TEMP%/SAD_VI_MOVE_NO_CLOBBER_<GUID>`; nenhum `.qvd`/`.qvw`, arquivo do repositório, dataset, banco ou script existente é tocado.
- **Evidência:** console (redirecionável para TXT no `%TEMP%`), caminho da pasta, HEAD/sha256 do script e hashes verificados em memória. A pasta temporária é intencionalmente preservada para conferência; não há limpeza automática.

## Matriz de teste controlada

| Caso | Preparação no diretório temporário | Critério PASS |
| --- | --- | --- |
| `EXISTING_DESTINATION` | `stage.txt` e `final.txt` preexistentes com conteúdos diferentes; `File.Move(stage,final)` | Exceção `IOException`; hash de **ambos** preservado |
| `CREATED_AFTER_CHECK` | `final.txt` ausente na checagem inicial, criado propositalmente antes do move (simulação determinística de TOCTOU) | Exceção `IOException`; hashes de origem/destino preservados |
| `EMPTY_DESTINATION` | `stage.txt` presente, `final.txt` ausente | Move bem-sucedido, stage deixa de existir, hash do destino igual ao da origem |

**Limite da prova:** a simulação de criação após a checagem não é teste de concorrência real entre processos, mas confirma que a proteção relevante reside no `[IO.File]::Move(source,destination)`, não em `Test-Path`. Não testa QlikView 12, escrita de QVD, unicidade de `%LINK_KEY`, modelo associativo ou CREATE real.

## Execução autorizada apenas para o teste descartável

Após inspecionar a branch e confirmar que o script está commitado, em **Windows PowerShell**, na raiz de uma cópia do repositório na branch correspondente:

```powershell
git rev-parse HEAD
git status --short
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\Test-SadViLinkNoClobber.ps1 `
  -Root (Get-Location).Path 2>&1 |
  Tee-Object -FilePath "$env:TEMP\SAD_VI_LINK_MOVE_TEST.txt"
```

A execução deve produzir `CASE=...` para três casos e **somente em sucesso completo** `VERDICT=PASS_VI_LINK_FILE_MOVE_TEMP_ONLY_NOT_QVD_APPROVAL`. Caso contrário, `BLOCKED`, preservar o diretório temporário e parar, sem rodar outro teste automático. O arquivo do teste precisa ter a revisão/commit inspecionados; não executar cópias avulsas sem rastreabilidade.

## Gates separados e condição de parada

- `VI_LINK_INVENTORY=PASS_LOCAL_REPORTED` no stdout de 18/10/2026 do responsável: `PASS_INVENTORY_ONLY_NOT_PHYSICAL`, `ORIGINAL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True`, HEAD `1ef2e271...`. Evidência local reportada, não inspeção independente dos 21 binários.
- `VI_LINK_MOVE_TEST=PASS_LOCAL_REPORTED` conforme stdout Windows recebido em 18/10/2026, detalhado na seção de evidência abaixo. Aprovado somente para a semântica de `File.Move` em arquivos TXT temporários; não é PASS da Link Table física.
- `LINK_ANALISE_QVD=NOT_CREATED` conforme evidência de inventário; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PRODUCTION_APPROVED=False`.
- O teste isolado requer **apenas** autorização para executar arquivos TXT descartáveis em `%TEMP%`. **Não** autoriza `Invoke-SadViLinkAnalise.ps1 -ExecutePhysical`, nenhuma criação/publicação física de `LINK_ANALISE.qvd`, merge de PR, recarga de QVW ou avanço à Fase VII.
- **STOP:** gate de teste descartável encerrado com PASS local reportado. Manter PR #102 Draft até revisão e autorização específica de merge; a materialização de `LINK_ANALISE.qvd` requer autorização nova. Em caso de regressão futura, exigir novo commit e nova evidência.

## Evidência Windows recebida — execução única do teste

**Origem:** saída de PowerShell colada pelo responsável nesta conversa em 18/10/2026, referente ao teste em worktree descartável. **Nível de prova:** execução local reportada + confronto estático com o código commitado; não foram abertos os arquivos originais de `%TEMP%` nesta revisão.

- **Worktree:** `git worktree add --detach` com HEAD `6742e94e6e48770d5619768e46581b4a67f346e2` (mesmo HEAD inicial do PR #102, anterior a esta atualização exclusivamente documental).
- **SHA-256 informado pelo PowerShell:** `68CC8473C814A019BE4AF3415C00028AD404AAE89DCB8CEDE923F49EF44C4FD2`. O conteúdo Git com `LF` produz `8FFF52D316FC87A87912BDCDD00E9B6D68C957D6D5248146F903C8290637AACE`; ao converter **somente LF→CRLF**, o SHA-256 recalculado coincide com o hash do Windows. Isso é compatível com checkout Git com finais de linha CRLF, **não demonstra auditoria de bytes do computador**.
- **Pasta de evidência informada (nome relativo em TEMP):** `SAD_VI_MOVE_NO_CLOBBER_ebbcb2f0f6cb4cdc88996cb5b60bf4f1`.
- **Arquivo de stdout informado:** `%TEMP%\SAD_VI_LINK_MOVE_TEST.txt`. Conteúdo reproduzido abaixo nos trechos decisivos, sem incorporar artefatos locais binários no Git.

```text
MODE=TEMP_TXT_ONLY NO_QLIK=True NO_QVD_ACCESS=True
LINK_ANALISE_QVD_GENERATED=False PRODUCTION_APPROVED=False
SCRATCH_FILES_PRESERVED=True
EXPECTED_EXCEPTION=EXISTING_DESTINATION|System.IO.IOException|HResult=-2147024713
CASE=EXISTING_DESTINATION RESULT=PASS_DESTINATION_PROTECTED_SOURCE_PRESERVED
EXPECTED_EXCEPTION=CREATED_AFTER_CHECK|System.IO.IOException|HResult=-2147024713
CASE=CREATED_AFTER_CHECK RESULT=PASS_DESTINATION_PROTECTED_SOURCE_PRESERVED
CASE=EMPTY_DESTINATION RESULT=PASS_STAGE_MOVED_CONTENT_IDENTICAL
VERDICT=PASS_VI_LINK_FILE_MOVE_TEMP_ONLY_NOT_QVD_APPROVAL
```

**Veredito limitado:** `GATE_VI_FILE_MOVE_TEMP=PASS_LOCAL_REPORTED`. O teste indicou rejeição de `Move` com destino preexistente, inclusive após checagem inicial de ausência, com origem e destino preservados; o cenário sem destino indicou publicação bem-sucedida e SHA preservado. O script contém as asserções de hash que precedem os marcadores PASS.

**Não comprovado neste gate:** corrida efetiva entre processos, execução QlikView/COM, geração/READBACK de `LINK_ANALISE.qvd`, integridade binária independente dos 21 QVDs na data desta prova, contrato físico da Link Table, ausência de synthetic keys no painel, aprovação de indicadores ou de produção.

**Próxima decisão pendente:** revisar/autorizar merge do PR #102 (documento e script). Somente em gate físico futuro, com autorização específica, considerar o CREATE/READBACK de `LINK_ANALISE.qvd` em Windows, preservando 21 QVDs e registrando evidências nativas. `LINK_KEY_CONTRACT=NOT_APPROVED`; `PRODUCTION_APPROVED=False`.
