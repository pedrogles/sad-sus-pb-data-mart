# Fase VIII — C2-H | Piloto físico restrito de duas listboxes temporais

> **Atualização Git (21/10/2026):** o closeout restrito C2-H foi integrado à `main` por [PR #148](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/148), squash `cb2bcc5f5212165cef905f23d81bf688fa33dd2a`. As seções de tentativas/erros e menções a `Draft`, `NOT_RUN` e 'sem merge' reproduzem o estado quando registradas. Integração não altera o veredito local limitado, não executa novamente o teste e não aprova D2/P5 globais.

**Preparação documental:** 21/10/2026. **Baseline:** `main@3ca9c50a98c429ddb880ad6ea877fdf89a33a3fa`.  
**Autorização explícita:** responsável confirmou "sim, prossiga" para modificar **somente LB01 e LB04 em NOVA cópia temporária**, preservar QVWs originais e 22 QVDs. A autorização não abrange o painel canônico, produção, Fase IX, merges ou alteração semântica.  
**Estado final deste gate (após evidência local reportada em 21/10/2026):** `C2H_CLOSEOUT=COMPLETED_WITH_LIMITS`; `C2H_PREPARE=PASS_LOCAL_REPORTED`; `C2H_POST_GUI_HASH_VERIFY=PASS_LOCAL_REPORTED_INTEGRITY_ONLY`; `C2H_LISTBOX_MITIGATION=SUPPORTED_OPERATOR_REPORTED_WITH_SCREENSHOT_LIMIT`; `C2H_BU01_REGRESSION=PASS_VISUAL_RESTRICTED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED`. Os estados intermediários das seções históricas abaixo permanecem classificados segundo o momento em que foram registrados.

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

## 10. Segunda execução nativa autorizada: preparação concluída (21/10/2026)

**Proveniência da evidência:** transcrição completa da sessão PowerShell 5.1 nativa fornecida diretamente pelo responsável. Valores de hash e integridade foram emitidos pelo script local; os 25 arquivos físicos protegidos e o manifesto ainda não foram reabertos para auditoria externa nesta etapa. Logo, classificar como `PASS_LOCAL_PREPARATION_REPORTED_ONLY`, nunca `PASS_PHYSICAL_LISTBOX_TEST`.

**Pré-condições reportadas:** branch `test/phase-viii-c2h-listbox-readonly-pilot-20261021`, `git status --short` vazio, fast-forward até `58aaebc3146cc89010a5d06084089488a21d3ae1`, parser real `PARSER=PASS`, `-Prepare` invocado **uma única vez nesta segunda tentativa**. Não houve erro ou throw do wrapper após a chamada.

| Saída exata do runner | Valor reportado |
| --- | --- |
| VERSIONED_GIT_HEAD | `58aaebc3146cc89010a5d06084089488a21d3ae1` |
| SCRIPT_SHA256 | `EAA0086C8806EE179D241AEB3239A7E35FFBF0CF68615B61AFD792EC3412F2B7` |
| SOURCE_C2F_QVW_SHA256 | `31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087` |
| INPUT_EVENTS | `0` |
| QLIK_COM_CALLS | `0` |
| AUTOMATED_QVW_MODIFICATIONS | `0` |
| ORIGINAL_22_QVD_3_QVW_AND_SOURCE_UNCHANGED | `True` |
| BEFORE_TEST_COPY_SHA256 | `31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087` |
| VERDICT | `PASS_LOCAL_PREPARATION_ONLY_C2H_UI_NOT_EXECUTED` |

**Cópia TEMP C2-H criada e reportada:**

```text
C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2H_ee31c0f9a9da40cda0d94fe791b6ec32\SAD_C2H_READONLY_PILOT_COPY.qvw
```

**Diretório persistente de evidência reportado:**

```text
C:\Users\pedro\Documents\SAD_C2H_EVIDENCIAS\SAD_VIII_C2H_ee31c0f9a9da40cda0d94fe791b6ec32
```

**Classificação do subgate:** `C2H_PARSER=PASS_USER_REPORTED_POWERSHELL_5_1`, `C2H_PREPARE=PASS_LOCAL_PREPARATION_REPORTED_ONLY`, `C2H_TEST_COPY=CREATED_SHA_MATCH_REPORTED`, `C2H_PHYSICAL_LISTBOX_TEST=NOT_RUN`, `C2H_POST_GUI_VERIFY=NOT_RUN`.

**Próxima etapa autorizada:** abrir **somente** a cópia TEMP C2-H indicada acima em QlikView 12; capturar a barra de título e propriedades `LB01` e `LB04` **antes** da modificação, verificando que ambas mostram `Apenas leitura` desmarcado. Em seguida, sob roteiro da seção 4, alterar apenas essas duas flags na cópia nova, salvar unicamente a cópia e registrar pós-configuração. Não executar `-Prepare` novamente, não reabrir fontes originais para edição, não realizar recarga. A revisão humana de imagens será diferenciada da verificação binária posterior `-Verify`.

**Estados ainda não promovidos:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. PR #148 permanece Draft e `main` não alterada pelo relato. O SUCCESS do runner somente prova a preparação restrita conforme seu próprio código e stdout, não a configuração futura da interface.

## 11. Capturas pré-mudança da nova cópia C2-H (21/10/2026)

**Proveniência:** duas capturas PNG enviadas diretamente pelo responsável e inspecionadas visualmente; SHA-256 dos bytes anexados calculado neste ambiente. As capturas exibem no título da janela de propriedades o caminho da cópia C2-H `SAD_VIII_C2H_ee31c0f9a9da40cda0d94fe791b6ec32`, não a origem C2-F nem o painel canônico. Não foi executada nenhuma chamada QlikView/COM neste ambiente.

| Captura | Dimensões | SHA-256 da imagem recebida | Evidência visual |
| --- | --- | --- | --- |
| `image(20261021-155937).png` | `747×607` | `AAF9FD32970B611C73D584A7DAFB412C1F5994AFBAD17799B28DD8162739E1C5` | `Propriedades da Lista [PERIODO_ANO]`, `LB01`, campo `PERIODO_ANO`, `Apenas leitura` desmarcado |
| `image(20261021-160002).png` | `741×604` | `1C6313C82B20DD4F31F58D74C8078E2A548CC19950CA6C655D5D053D3834184C` | `Propriedades da Lista [PERIODO_COMPETENCIA]`, `LB04`, campo `PERIODO_COMPETENCIA`, `Apenas leitura` desmarcado |

**Classificação restrita:** `C2H_PRECHANGE_LISTBOX_CONFIG=PASS_VISUAL_BASELINE_TWO_OBJECTS`; `C2H_PHYSICAL_LISTBOX_MITIGATION=NOT_TESTED`; `C2H_AFTER_SAVE_PROPERTIES=NOT_CAPTURED`; `C2H_POST_GUI_VERIFY=NOT_RUN`. As capturas provam propriedades pré-mudança da **cópia** preparada, mas não provam configuração posterior, persistência ao salvar ou bloqueio funcional de seleção.

**Próximo passo manual já autorizado e delimitado:** nesta mesma cópia C2-H, marcar exclusivamente `Apenas leitura` em `LB01` e `LB04`, confirmar apenas essas alterações via OK de cada objeto e do diálogo principal, salvar **uma única vez somente o QVW C2-H**, reabrir propriedades somente para captura posterior e encerrar cada leitura com Cancelar. Em caso de qualquer outra alteração ou mensagem inesperada, STOP e registrar antes de prosseguir. Não testar ainda seleções/bookmarks/busca; subgate funcional aguarda conferência das duas capturas pós-salvamento. Não reexecutar `-Prepare`, não alterar originais.

## 12. Capturas pós-alteração de LB01/LB04 no QVW C2-H (21/10/2026)

**Proveniência:** duas imagens PNG anexadas pelo responsável e auditadas visualmente nesta sessão, hashes calculados dos bytes efetivamente anexados. A barra de título de ambas identifica a cópia temporal C2-H e não os QVWs canônicos. O operador enviou estas capturas em resposta ao pedido de reabertura de propriedades **depois do salvamento orientado**, mas o ato de salvar e o conteúdo binário do QVW não foram observados diretamente neste ambiente. A verificação de integridade `-Verify` continua pendente.

| Objeto / arquivo recebido | Dimensão | SHA-256 do PNG recebido | Estado observado |
| --- | --- | --- | --- |
| `LB01/PERIODO_ANO` — `image(20261021-160612).png` | 746 × 606 | `DFAE26E647ED5B527059E52492F9B679CE602E35493576791645527C6DD3ECCC` | checkbox `Apenas leitura` **marcado** |
| `LB04/PERIODO_COMPETENCIA` — `image(20261021-160622).png` | 736 × 620 | `D20062D172E569F546252D50D0F1450604215CF501128AC41382A2F8F0F1EA21` | checkbox `Apenas leitura` **marcado** |

**Comparação com §11:** ambas tinham `Apenas leitura` desmarcado antes da alteração, e ambas aparecem marcadas agora. Sem outro campo visivelmente modificado nesta comparação, mas **isso não é auditoria de todas as propriedades QVW**.

**Veredito restrito:** `C2H_POSTCHANGE_CONFIG=PASS_VISUAL_FLAGS_CHECKED_TWO_OBJECTS`; `C2H_SAVED_TO_DISK=REPORTED_NOT_BINARY_VERIFIED`; `C2H_DIRECT_LISTBOX_SELECTION_BEHAVIOR=NOT_TESTED`; `C2H_BU01_REGRESSION=NOT_TESTED`; `C2H_VERIFY=NOT_RUN`; `C2_FULL=NO_GO_NOT_APPROVED` e `P5_D2_UI=NOT_TESTED` mantidos. Não declarar aprovação de prevenção global ou bypass funcional.

**Próximo teste delimitado:** fechar janelas de propriedades com Cancelar e mostrar a folha atual; testar **uma rodada** conforme §4, tomando um valor que esteja **possível** (não cinza/excluído) em cada listbox, com capturas antes/depois, seguido do único clique BU01 já contratado, se estiver habilitado. Caso nenhuma alternativa possível esteja disponível sem limpeza, o §4 permite **um único Limpar na cópia C2-H**, que deve ser registrado como alteração de seleção **de teste**, não reconfiguração de propriedades. Se qualquer listbox admitir seleção direta, STOP e classificar `BLOCKED_LISTBOX_MITIGATION`; se não houver estado comparável, `INCONCLUSIVE`. Não repetir `-Prepare`, não usar search/bookmarks/triggers, não salvar novamente após testes de seleção. Depois fechar a cópia e executar uma vez `-Verify`, com hash da origem e dos 25 artefatos protegidos.

## 13. Tentativas de seleção direta em listas somente leitura (21/10/2026)

**Evidência fornecida:** o responsável declarou literalmente: **“não foi possivel mudar as seleções de ambos”** (LB01/ano e LB04/competência), após o procedimento de clicar uma vez em valores possíveis previsto no §4. Foi enviada **uma** captura final da folha Principal, com o arquivo `SAD_C2H_READONLY_PILOT_COPY.qvw` identificado na barra de título, sem valores destacados em verde nas listas temporais visíveis. O estado apresentado é compatível com seleção direta impedida, e a tela de KPI indica `Condição de cálculo não satisfeita` no contexto sem seleção temporal. Isto não é um par pré/pós para cada tentativa, nem comprova que todos os valores clicados eram possíveis ou a ausência de rotas alternativas.

| Arquivo/imagem | Prova observada |
| --- | --- |
| `image(20261021-184521).png` — 1248 × 722 px | SHA-256 `055B3747CCBD2C8AF9A2467DF893C2E85CCF726582FAAA165128F8D2934ED0B2`; cópia C2-H, listas temporais sem destaque verde em estado final e botões BU01/BU02 visíveis |

**Qualificação:** `C2H_LB01_LB04_DIRECT_SELECTION=PASS_OPERATOR_REPORTED_WITH_SINGLE_FINAL_SCREENSHOT_LIMIT`; não declarar `PASS_INDEPENDENT_PAIRED_STATE_COMPARISON`. Os PNGs anteriores provam configuração visual marcada nas duas propriedades; esta imagem final é coerente com o relato de bloqueio local, mas não documenta o dispatch, as tentativas individuais ou o estado imediatamente anterior. Nenhuma reprodução COM ou UIA foi realizada.

**Próxima ação mínima e única ainda prevista no §4:** testar regressão do **botão BU01** na mesma cópia C2-H, uma única vez, somente se visivelmente habilitado e sem competência selecionada, para propor `201801`. A captura atual pode servir como estado pré-clique se não houver ação intermediária; solicitar captura pós-clique com competência 201801 selecionada/refletida em LB04. Se BU01 não estiver habilitado, não mudar propriedades; `INCONCLUSIVE`. Se o clique falhar ou alterar outra propriedade, STOP. **Não testar BU02, menus, bookmarks ou buscas.** Não salvar novamente após teste; encerrar QlikView e executar uma única vez `-Verify` para checar 25 hashes protegidos, fonte e cópia.

**Estados:** `C2H_POSTCHANGE_CONFIG=PASS_VISUAL_FLAGS_CHECKED_TWO_OBJECTS`; `C2H_DIRECT_LISTBOX_BLOCK=REPORTED_BOUNDED_NOT_FULLY_INDEPENDENTLY_PAIRED`; `C2H_BU01_REGRESSION=NOT_RUN`; `C2H_POST_GUI_HASH_VERIFY=NOT_RUN`; `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. PR #148 permanece Draft e não deve ser integrado automaticamente.

## 14. BU01 — seleção de competência via botão após listas Read Only (21/10/2026)

**Fonte material examinada:** `image(20261021-184859).png` enviada pelo responsável, 1246 × 720 pixels, SHA-256 `D15C9DF9D2B499CC21E8D9328299391B1EF8ABE8319623A939E76F1DD6BE8077` (bytes inspecionados neste ambiente). O usuário reportou explicitamente **“cliquei no botão 1”**. A barra de título confirma `SAD_C2H_READONLY_PILOT_COPY.qvw`, dentro de TEMP C2-H, não o QVW de origem/canônico.

**Estado pós-clique legível:** `PERIODO_COMPETENCIA=201801` aparece destacado **em verde** em LB04; `BU01 — Propor competência 201801` permanece visível e `BU02 — Propor ano 2019` aparece cinza/desabilitado. O aviso de período parcial `201801` aparece no rodapé do objeto; o indicador T26 registra `Condição de cálculo não satisfeita` nesse contexto. A seleção do ano analítico não foi atestada por destaque verde nesta captura; não inferir uma segunda seleção de campo.

**Reconciliação com evidências anteriores:** os PNGs da seção 12 mostraram `Apenas leitura` marcado em LB01 e LB04; o usuário relatou que cliques diretos nas duas listas não alteraram seleção (§13). Na captura anterior `image(20261021-184521).png`, não havia competência destacada. Na nova captura, após clique BU01 reportado, `201801` ficou selecionado e refletido na listbox que estava somente leitura. Há **par visual de estado inicial/final para a regressão do botão**; não há observação interna do dispatch/action, do clique capturado em vídeo nem pares para cada tentativa direta na lista.

**Classificações restritas:** `C2H_BU01_REGRESSION=PASS_REPORTED_ACTION_WITH_PRE_POST_VISUAL_CANDIDATE_ONLY`; `C2H_LB01_LB04_DIRECT_SELECTION=PASS_OPERATOR_REPORTED_WITH_SINGLE_FINAL_SCREENSHOT_LIMIT`; `C2H_LISTBOX_LOCAL_MITIGATION=SUPPORTED_BOUNDED_NOT_FULL_UI`; `C2H_POST_GUI_HASH_VERIFY=NOT_RUN`. A mensagem `Condição de cálculo não satisfeita` não é aprovação de T26 nem de P5. Não afirmar guarda para bookmarks/busca/menus/COM ou prevenção global antes da seleção.

**STOP da GUI:** ensaio físico restrito concluído; **não executar BU02 ou novos cliques**. Fechar a cópia C2-H sem salvar novamente (se QlikView perguntar, escolher Não salvar; mudanças da propriedade já foram salvas uma vez antes dos cliques). Em PowerShell 5.1 nativo, usar **o mesmo checkout local em `58aaebc3146cc89010a5d06084089488a21d3ae1` da preparação**, sem `git pull`: o script `-Verify` compara exatamente `VersionedGitHead` do manifesto com `git rev-parse HEAD` e também o SHA do script. Executar **uma vez `-Verify`**, sem `-Prepare`, indicando `-RunDir` do manifesto reportado na seção 10. Enviar stdout e, se possível, `c2h_hash_verification.json` para revisão. Se PR tiver sido atualizado remotamente apenas com documentação, não fazer fast-forward antes de verificar; não alterar script, hashes, TEMP ou manifesto para contornar guardas.

**Status ainda pendente:** `C2H_VERIFY=NOT_RUN`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. O PR #148 segue Draft, sem merge.

## 15. C2-H — verificação final, reconciliação e STOP (21/10/2026)

**Origem desta rodada:** stdout completo de `powershell.exe -NoProfile ... -Verify -RunDir` fornecido pelo responsável no Windows PowerShell nativo. Não foram disponibilizados os bytes do manifesto `c2h_manifest.json`, do relatório `c2h_hash_verification.json` ou dos QVDs/QVWs para inspeção física externa; **as verificações são emitidas pelo runner local e reportadas**, não reproduzidas neste ambiente.

**Identidade do executor efetivamente utilizado:** `VERSIONED_GIT_HEAD=58aaebc3146cc89010a5d06084089488a21d3ae1`; `SCRIPT_SHA256=EAA0086C8806EE179D241AEB3239A7E35FFBF0CF68615B61AFD792EC3412F2B7`. A identidade corresponde à preparação C2-H previamente relatada na seção 10, sem mudança do runner. O script registrou `INPUT_EVENTS=0 QLIK_COM_CALLS=0 AUTOMATED_QVW_MODIFICATIONS=0` em sua própria execução; não implica ausência de interações humanas de teste na interface, previamente documentadas.

| Chave textual do stdout | Saída |
| --- | --- |
| `SOURCE_C2F_QVW_SHA256` | `31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087` |
| `PROTECTED_25_FILES_UNCHANGED` | `True` |
| `SOURCE_QVW_UNCHANGED` | `True` |
| `TEST_COPY_CHANGED_FROM_BASELINE` | `True` |
| `AFTER_TEST_COPY_SHA256` | `1724C785442F4FBA8C59E4D908C711AADC546C3AEB958208EA3FDC0F35CF180B` |
| `VERDICT` | `PASS_HASH_INTEGRITY_ONLY_UI_VISUAL_REVIEW_PENDING` |
| `C2_FULL` / `P5_D2_UI` / `PRODUCTION_APPROVED` | `NO_GO_NOT_APPROVED` / `NOT_TESTED` / `False` |

**Evidência fora do Git informada:** `C:\Users\pedro\Documents\SAD_C2H_EVIDENCIAS\SAD_VIII_C2H_ee31c0f9a9da40cda0d94fe791b6ec32`. O script procura manifesto nessa pasta e, em execução exitosa, grava `c2h_hash_verification.json`. Não se afirma leitura independente desse JSON.

**Reconciliação de todos os subpassos do gate:** (a) preparação em uma nova cópia TEMP, hashes de origem idênticos e 25 artefatos preservados conforme stdout; (b) imagens pré/pós das propriedades de LB01 e LB04 com opção `Apenas leitura` desmarcada/marcada, respectivamente; (c) operador afirmou não conseguir mudar diretamente o estado das duas listas, com **apenas uma captura final sem seleção** — evidência incompleta para atestar de modo independente cada clique individual ou confirmação de valor possível; (d) o relato de um clique BU01 é coerente com um **par visual antes/depois** demonstrando competência 201801 selecionada em LB04, mesmo marcada somente leitura; (e) após fechar a cópia, `-Verify` reportou preservação de fonte e 25 protegidos, e hash novo apenas na cópia de teste.

**Veredito proporcional à prova:**

- `C2H_CLOSEOUT=COMPLETED_WITH_LIMITS` — gate encerrado após a rodada autorizada, sem exploração adicional.
- `C2H_PREPARE=PASS_LOCAL_REPORTED`, `C2H_HASH_VERIFY=PASS_LOCAL_REPORTED_INTEGRITY_ONLY`.
- `C2H_CONFIG=PASS_VISUAL_TWO_LISTBOXES_READ_ONLY`; `C2H_DIRECT_SELECTION=SUPPORTED_OPERATOR_REPORT_SINGLE_FINAL_PNG_LIMIT`; `C2H_BU01_REGRESSION=PASS_VISUAL_RESTRICTED_AFTER_REPORTED_CLICK`.
- **NÃO** classificar `PASS_INDEPENDENT_PAIRED_STATE_COMPARISON` nem `P5_D2_UI=APPROVED`; a configuração `Read Only` limita aquelas listboxes, mas não estabelece intercepção de busca, bookmark, menu ou seleção programática em todo o documento.
- `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False` inalterados.

**STOP e decisão posterior:** nenhum novo clique, recarga, execução, reedição ou rodada de captura é necessário dentro de C2-H. Não executar `-Prepare` ou `-Verify` novamente para aumentar o nível de prova. O QVW temporário permanece evidência local fora do Git, sem promoção a painel canônico. A integração documental de PR #148, se desejada, depende de autorização independente; não ocorreu durante este closeout. Para progredir de D2 local a global, é necessária decisão futura separada sobre busca/bookmarks/menus/ações alternativas; não transformar automaticamente essa pendência em novo gate de testes.
