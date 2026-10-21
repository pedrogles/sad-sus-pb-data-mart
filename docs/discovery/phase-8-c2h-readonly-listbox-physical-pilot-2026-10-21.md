# Fase VIII — C2-H | Piloto físico restrito de duas listboxes temporais

**Preparação documental:** 21/10/2026. **Baseline:** `main@3ca9c50a98c429ddb880ad6ea877fdf89a33a3fa`.  
**Autorização explícita:** responsável confirmou "sim, prossiga" para modificar **somente LB01 e LB04 em NOVA cópia temporária**, preservar QVWs originais e 22 QVDs. A autorização não abrange o painel canônico, produção, Fase IX, merges ou alteração semântica.  
**Status de saída desta preparação no Git:** `C2H_RUNNER=VERSIONED_NOT_EXECUTED_WINDOWS`; `C2H_PREPARE=NOT_RUN`; `C2H_PHYSICAL_LISTBOX_TEST=NOT_RUN`; `P5_D2_UI=NOT_TESTED`; `C2_FULL=NO_GO_NOT_APPROVED`.

## 1. Objetivo único e escopo

Aferir, no **QVW temporário experimental do C2-H**, se marcar `Apenas leitura` nas listas `LB01/PERIODO_ANO` e `LB04/PERIODO_COMPETENCIA` impede **seleção direta por aquelas listas**, sem eliminar o funcionamento básico do botão controlado BU01. É um teste da **mitigação local**, não da interface inteira: pesquisas, bookmarks, menus, triggers e rotas programáticas continuam fora do contrato e portanto desconhecidas.

**Fonte de verdade consultada em ordem:** `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → Boundary 7 → V2 §62 → C2-F (#146) → C2-G (#147) → inventário de automação e script C2-F. C2-D1 já provou parcialmente D2-1/D2-3, sem aprovação global. Não repetir C2-D3 UIA/Win32 nem os testes T24/T25/T26.

**Roteamento:** Codex Local no Windows para parser e execução dos scripts versionados; operador QlikView 12 para **inspeção e dois checkboxes** na cópia; ChatGPT/GitHub para revisão independente dos stdout/PNG/manifestos. Modelo/esforço do Codex local devem ser registrados efetivamente, não presumidos; nesta preparação somente GPT-6/ChatGPT+GitHub acessível, sem Windows/COM. `RUNTIME_TEMP`: cópia C2-H sob `%TEMP%`. `EVIDENCE_ROOT`: `%USERPROFILE%\Documents\SAD_C2H_EVIDENCIAS`, fora de Git e do TEMP volátil.

## 2. Entradas, preflight e proteção

**Arquivo de origem protegido:** o **C2-F temporário já preparado** no Windows em
`%TEMP%\SAD_VIII_C2F_ed031b28b1564486af78785e53a01886\SAD_C2F_ROUTE_INVENTORY_COPY.qvw`.

**SHA-256 obrigatório da origem:** `31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087`. Se o hash atual divergir (por exemplo, alteração acidental na inspeção anterior), **STOP e diagnóstico; não salvar de volta, não selecionar outra origem sem decisão explícita**.

**Executor único:** `tools/Invoke-SadPhaseViiiC2hReadonlyListboxPilot.ps1`, versão commitada nesta branch antes do uso. Este script tem exatamente dois modos: `-Prepare` = validar git/hash, gerar **uma** nova cópia em TEMP e manifesto em evidência persistente; `-Verify -RunDir` = ler o manifesto e comparar hashes de origem, 22 QVDs, 3 QVWs canônicos e cópia **depois de o QlikView estar fechado**. **Não usa COM/GUI, não altera flags e não executa Reload/Save.**

**Pré-condições STOP:** fechar QVW original C2-F, não alterar nem remover QVDs/QVWs originais; branch versionada correta, script limpo, parser real Windows PowerShell 5.1 PASS; 10 QVDs de Extração + 12 de Transformação e 3 QVWs canônicos presentes; evidência fora do repositório. Em ausência de qualquer requisito, parar sem corrigir por tentativa e erro.

## 3. Execução do preflight em Windows / Codex local

Na raiz do clone Windows (verificar `git status --short` antes de qualquer troca de branch, sem `reset --hard`, limpeza forçada ou `stash -u`):

```powershell
git fetch origin
git status --short
git switch --track origin/test/phase-viii-c2h-listbox-readonly-pilot-20261021
git rev-parse HEAD

$script = (Resolve-Path .\tools\Invoke-SadPhaseViiiC2hReadonlyListboxPilot.ps1).Path
$tok = $null; $err = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tok, [ref]$err)
if ($err.Count -gt 0) { $err | ForEach-Object { $_.ToString() }; throw 'PARSER=BLOCKED' }
'PARSER=PASS'

$src = Join-Path $env:TEMP 'SAD_VIII_C2F_ed031b28b1564486af78785e53a01886\SAD_C2F_ROUTE_INVENTORY_COPY.qvw'
$ev = Join-Path $env:USERPROFILE 'Documents\SAD_C2H_EVIDENCIAS'
powershell.exe -NoProfile -File $script -Root (Get-Location).Path -SourceQvw $src -EvidenceRoot $ev -Prepare
```

Se a branch já existir localmente, verificar o HEAD e trocar para `git switch test/phase-viii-c2h-listbox-readonly-pilot-20261021` em vez de `--track`. **Não forçar checkout.** Não rodar o preflight duas vezes: uma execução gera **uma** nova cópia. Guardar `RUNTIME_TEMP_COPY`, `EVIDENCE_DIR` e SHA original retornados pelo script.

**Veredito máximo do primeiro comando:** `PASS_LOCAL_PREPARATION_ONLY_C2H_UI_NOT_EXECUTED`; não presumir TEST PASS e não fazer merge.

## 4. Interação física autorizada — somente NOVA cópia C2-H

Abrir **somente** `RUNTIME_TEMP_COPY` no QlikView 12; confirmar no título da janela o nome `SAD_C2H_READONLY_PILOT_COPY.qvw`. **Nunca editar `SAD_C2F_ROUTE_INVENTORY_COPY.qvw`, `SAD_C2D1_D2_BUTTON_TEST.qvw`, `PAINEL.qvw` ou qualquer outro QVW original.**

1. **Antes:** capturar janela principal e propriedades `LB01` e `LB04` mostrando `Apenas leitura` **desmarcado**. Se estado inicial diferente, **STOP**.
2. **Alteração autorizada:** na nova cópia, usar `Propriedades do Documento → Pastas → LB01 → Propriedades → Geral` e **marcar `Apenas leitura`**. Confirmar em OK; repetir exclusivamente `LB04 → Apenas leitura`. Não alterar `Sempre um valor selecionado`, habilitação/ações de BU01/BU02, ShowMode, Trigger, outros filtros, QVS, dados ou indicadores. Salvar **somente a cópia C2-H** uma vez. Capturar propriedades pós-salvamento com ambas as flags marcadas e fechar diálogos com Cancelar.
3. **Teste mínimo das duas rotas:** capturar estado de seleções antes; usar `Limpar` uma única vez **na cópia C2-H** se necessário para disponibilizar valores brancos possíveis. Tentar selecionar um valor **possível** em `LB01` diretamente; registrar pré e pós (ano não deve tornar-se selecionado). Tentar selecionar `201801` ou outro mês **possível** em `LB04` diretamente; registrar pré e pós (competência não deve tornar-se selecionada). Se qualquer seleção mudar via essas listboxes, **STOP: BLOCKED_LISTBOX_MITIGATION**. Não usar valor excluído/cinza como oráculo. Se não for possível identificar um valor possível, `INCONCLUSIVE` sem repetição.
4. **Regressão mínima do controle**: no estado em que BU01 está visivelmente habilitado e sem mês selecionado, clicar **uma vez** em `BU01` para propor `201801`; deve selecionar essa competência e a lista LB04 somente refletir esse estado. Capturar antes e depois. Se BU01 indisponível/inconsistente, **STOP** sem alterar condição. Esse teste não mede isolamento global ou dispatch interno e não repete toda a suíte C2-D1.
5. Fechar a cópia QVW. Se for solicitado salvar por mudanças de seleção não planejadas, evitar um segundo salvamento; documentar o diálogo e não modificar a fonte. Logs/capturas em `EVIDENCE_DIR` fora do Git. Nada de macro, UIA, mouse por coordenada, bookmark, busca global, outros cenários ou reexecuções automáticas.

**Critério visual restrito:** flags LB01/LB04 marcadas e persistidas + seleções diretas efetivamente bloqueadas para valores possíveis + uma proposta BU01 funcional, com pares pré/pós e seleções legíveis. A **mera presença das flags** é prova de configuração, não de comportamento.

## 5. Verificação de hashes depois de fechar QlikView

Após uma única rodada, voltar ao mesmo script **sem -Prepare**, usando o `EVIDENCE_DIR` retornado pelo primeiro comando:

```powershell
powershell.exe -NoProfile -File $script -Root (Get-Location).Path -SourceQvw $src -EvidenceRoot $ev -Verify -RunDir 'COLE_AQUI_EVIDENCE_DIR_REAL'
```

Esperado: `PROTECTED_25_FILES_UNCHANGED=True`, `SOURCE_QVW_UNCHANGED=True`, `TEST_COPY_CHANGED_FROM_BASELINE=True` e `VERDICT=PASS_HASH_INTEGRITY_ONLY_UI_VISUAL_REVIEW_PENDING`. A alteração da cópia não prova por si só que só as flags foram modificadas; essa distinção depende das capturas e revisão de propriedades. Divergência de hash protegido = `HARD_STOP`, não PASS.

## 6. Fechamento, critérios e limites

- **`PASS_LOCAL_LISTBOX_MITIGATION_CANDIDATE_ONLY`:** primeira preparação PASS, fonte/protegidos preservados, propriedade LB01/LB04 pós-salvamento visualmente marcada, tentativas em ambas as listas não alteraram seleção possível, BU01 continuou funcional, pacote de imagens e stdout revisados. Ainda **não** é prova de C2/P5 global.
- **`BLOCKED`:** integridade inesperada, efeito direto de clique apesar do modo somente leitura, propriedade não persistida, ações alteradas ou desvio de escopo; registrar primeira falha e STOP.
- **`INCONCLUSIVE`:** QVW inacessível, imagem não legível, botão sem estado inicial utilizável, sem oráculo de valor possível, fonte com SHA incompatível ou execução não verificável.
- **`STOP`:** uma preparação e uma rodada limitada no QVW temporário; nenhuma exploração adicional ou tentativa de restaurar dados/modelo.
- **Manter mesmo com PASS restrito:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**Estado até execução Windows reportada:** `C2H_RUNNER=VERSIONED_NOT_EXECUTED_WINDOWS`; `C2H_PREPARE=NOT_RUN`; `C2H_PHYSICAL_LISTBOX_TEST=NOT_RUN`. Ação seguinte: Codex Local executa parser/preparação e fornece stdout; depois iniciar GUI só na nova cópia. Não existe autorização de merge automático por esta permissão.

## 7. BLOQUEIO de ambiente Codex antes de parser/preparação (21/10/2026)

**Proveniência:** relato textual e stderr informados diretamente pelo responsável; nenhum arquivo do Windows foi inspecionado pelo agente neste registro. **Tentativas executadas de `-Prepare`: zero.** Preflight interrompido na primeira falha; não houve criação de cópia nem pasta C2-H, nem GUI/COM/Reload/Save/merge.

**Contexto relatado:** branch `test/phase-viii-c2h-listbox-readonly-pilot-20261021`, HEAD `fd563c2a582fd787c469991195bb3d347763d2c2` e checkout limpo. `RUNNER_SHA256=9A70C54DA53BC8DFCC92ED9CE8D6493F0711854583F84AB8D9B600A5F4D0F32C` informado, sem revalidação dos bytes pela auditoria.

**Erro recebido, literalmente:**

```text
Could not find a part of the path 'C:\Users\pedro\AppData\Local\Packages\sandbox.{122f7a09-f8ab-46e7-88dd-691d15499a88}\AC\Temp\SAD_VIII_C2F_ed031b28b1564486af78785e53a01886\SAD_C2F_ROUTE_INVENTORY_COPY.qvw'.
```

A cópia C2-F foi originalmente reportada em outro diretório, fora do sandbox:
`C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2F_ed031b28b1564486af78785e53a01886\SAD_C2F_ROUTE_INVENTORY_COPY.qvw`.

**Diagnóstico documentado:** `$env:TEMP` no executor Codex resolveu para o TEMP isolado do sandbox, e o pré-check externo tentou acessar um caminho derivado dali. Isto é `RECOVERABLE_BLOCK_ENVIRONMENT_PATH_SCOPE`, **não** `SOURCE_FILE_PROVEN_MISSING`. O executor C2-H versionado também ancora a origem ao `[IO.Path]::GetTempPath()` corrente, de forma que apenas passar caminho absoluto sob um TEMP diferente não removeria a incompatibilidade de contrato, mesmo se o arquivo for acessível. Não editar proteções de caminho nem contornar pin SHA sem nova decisão.

**Status fiel:** `PARSER=NOT_RUN`, `PREPARE=NOT_RUN`, `SOURCE_C2F_QVW_SHA256=NOT_VERIFIED`, `RUNTIME_TEMP_COPY=NOT_CREATED`, `EVIDENCE_DIR=NOT_CREATED`; `C2H_PHYSICAL_LISTBOX_TEST=NOT_RUN`. Nenhuma execução local foi apresentada como PASS.

**Uma verificação ambiental mínima proposta, sem escrever arquivos:** em **Windows PowerShell 5.1 normal na sessão do usuário (fora do sandbox)**, ler `$env:TEMP`, `[IO.Path]::GetTempPath()`, `Test-Path -LiteralPath` do caminho C2-F literal e `Get-FileHash -Algorithm SHA256` **somente se existir**. Se o arquivo estiver presente com SHA esperado `31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087`, preferir execução futura do runner **sem modificá-lo no Windows PowerShell nativo** (contrato de TEMP original). Se a origem não existir nesse ambiente, ou hash for diferente, STOP e decisão específica; não copiar de arquivos arbitrários, desabilitar sandbox ou flexibilizar validações.

**STOP:** não repetir `-Prepare`, não rodar parser no Codex isolado nem alterar runner enquanto a hipótese de escopo/permite-acesso não for checada; nova execução física após o diagnóstico exige decisão/autorização correspondente. PR #148 continua Draft sem merge. `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## 8. Verificação PowerShell nativo — origem recuperável no contexto correto (21/10/2026)

**Fonte e nível probatório:** retorno textual do responsável, executado no prompt `PS C:\Users\pedro>` em PowerShell normal do Windows. Arquivos físicos não foram abertos independentemente pelo agente. Classificar como **PASS_USER_REPORTED**, não auditoria binária externa.

| Controle | Resultado reportado |
| --- | --- |
| `$env:TEMP` | `C:\Users\pedro\AppData\Local\Temp` |
| `[IO.Path]::GetTempPath()` | `C:\Users\pedro\AppData\Local\Temp\` |
| `SOURCE_EXISTS` | `True` |
| `SOURCE_SHA256` | `31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087` |

**Diagnóstico atualizado:** `C2H_NATIVE_TEMP_SOURCE_PATH_AND_SHA=PASS_USER_REPORTED`; o mesmo QVW C2-F pinado está acessível no TEMP original do usuário. O bloqueio anterior refere-se ao caminho TEMP do sandbox Codex, **não comprova perda da fonte**. `-Prepare` continua **não executado**, nenhuma cópia de teste C2-H foi criada.

**Recuperação delimitada dentro do C2-H autorizado:** fechar o QVW C2-F sem salvar; abrir PowerShell 5.1 **nativo**, na raiz do clone, atualizar a branch #148 por fast-forward se o checkout estiver limpo, validar parser real do script versionado e executar **uma única vez** `-Prepare` com `-SourceQvw` igual ao caminho literal já validado. Não executar no sandbox, alterar variável de TEMP ou relaxar verificações de SHA. Enviar stdout, `RUNTIME_TEMP_COPY`, `EVIDENCE_DIR` e veredito **antes de abrir o novo QVW na interface**.

**Estados:** `C2H_ENV_BLOCK=RESOLVED_FOR_NATIVE_POWERSHELL_SOURCE_CHECK_USER_REPORTED`; `C2H_NATIVE_PARSER=NOT_RUN`; `C2H_PREPARE=NOT_RUN`; `C2H_PHYSICAL_LISTBOX_TEST=NOT_RUN`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. PR #148 Draft, sem merge. **STOP** na primeira falha ou após preparar a cópia; nenhum avanço automático à GUI.

## 9. Falha da primeira execução nativa - SwitchParameter (21/10/2026)

**Proveniência:** transcrição integral do terminal PowerShell nativo compartilhada pelo responsável. Branch limpa, `git fetch` e `git pull --ff-only` atualizados para `da0a713ea8936035950b08d6ab063955125f4ecb`; parser real PowerShell 5.1 retornou **PASS**. Em seguida, **uma chamada** com `-Prepare` foi realizada e terminou em erro de tipo **antes** da leitura da origem, dos snapshots de QVD/QVW e da criação de qualquer cópia/manifestações.

**Erro reportado:** `Não é possível converter o valor "True" do tipo "System.Management.Automation.SwitchParameter" no tipo "System.Int32"` (`ConvertToFinalInvalidCastException`). O retorno fornecido não continha linhas de saída de preparação ou PASS de integridade. A falha é atribuível à validação de exclusividade dos modos na linha inicial do executor:

```powershell
if ([int]$Prepare + [int]$Verify -ne 1) {throw 'BLOCKED_CHOOSE_EXACTLY_ONE_MODE'}
```

**Correção mínima versionada (commit `b01abff525e0861cb1a14398bce5eb90bc5e13c0`):** substituir **somente** a linha acima por:

```powershell
if ($Prepare.IsPresent -eq $Verify.IsPresent) {throw 'BLOCKED_CHOOSE_EXACTLY_ONE_MODE'}
```

**Justificativa estática:** `SwitchParameter.IsPresent` fornece um valor lógico sem cast numérico. Quando apenas `-Prepare` ou apenas `-Verify` está presente, os booleanos diferem e a validação permite prosseguir; quando nenhum ou ambos estão presentes, a igualdade gera `BLOCKED_CHOOSE_EXACTLY_ONE_MODE`. Esta análise de uma linha **não substitui novo parser/execução física Windows**, não qualifica os demais ramos do script como aprovados e não autoriza contornar falhas posteriores.

**Estados reais até nova evidência:** `C2H_NATIVE_PARSER_PRIOR_VERSION=PASS_REPORTED`; `C2H_PREPARE_ATTEMPT_1=FAILED_FAST_SWITCHPARAMETER_CAST`; `C2H_RUNNER_FIX=VERSIONED_UNTESTED_WINDOWS`; `C2H_PREPARE_PASS=NOT_ACHIEVED`; `C2H_TEST_COPY=NOT_CREATED`; `C2H_HASH_VERIFICATION=NOT_RUN`; `C2H_PHYSICAL_LISTBOX_TEST=NOT_RUN`. De acordo com relato do responsável, QVW/QVD não foram alterados; os 25 hashes não foram computados por esta tentativa falha. PR #148 continua Draft, sem merge, nenhuma aprovação de C2/D2/P5 ou Fase IX.

**Próximo passo sujeito a autorização específica de reexecução:** somente se o responsável autorizar, usar o **mesmo PowerShell nativo** (não sandbox), `git pull --ff-only` com checkout limpo do PR #148, conferir o novo HEAD, parser PowerShell 5.1 PASS e executar **uma única segunda chamada `-Prepare`** na origem C2-F pinada. **STOP na primeira falha**; não iniciar GUI antes de evidência de preparação íntegra. Não alterar QVW/arquivos protegidos nem executar ou modificar scripts fora do commit versionado.
