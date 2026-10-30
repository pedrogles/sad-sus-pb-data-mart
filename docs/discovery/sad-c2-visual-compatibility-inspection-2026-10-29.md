# SAD C2 — inventário de compatibilidade visual em duas QVWs descartáveis

**Gate único:** `SAD-C2-VISUAL-COMPATIBILITY-01`, etapa delimitada da [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196).  
**Baseline:** `main@7827300c8772a1cdebef2238a7dd8064c13592d2`, com [PR #195](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/195) integrado.  
**Estado de entrada:** preflight anterior **PASS restrito e documentado** na Issue #196; `PR #197` ainda **Draft/sem merge**; seus scripts **não serão reexecutados**.  
**Estado desta etapa:** `SCRIPT_VERSIONED_CANDIDATE / WINDOWS_NOT_RUN / VISUAL_NOT_OBSERVED`.  
**Agente/modelo:** ChatGPT GPT-6 + conector GitHub apenas para preparação e inspeção estática; esforço efetivo indisponível. No Windows, executor primário Codex Local com acesso demonstrado, fallback pessoa operadora em PowerShell 5.1/QlikView 12; somente com permissão de trabalhar nas cópias temporárias.

## 1. Por que este gate é distinto

As evidências entregues no preflight anterior conferem **dois QVWs distintos**:
- `SAD_P11P12_VISUAL_POLISH_COPY.qvw`, SHA-256 `B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C`, previamente demonstrou 4 KPIs P1.1 e série de **36 competências** P1.2 em prova restrita.
- `SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw`, SHA-256 `9896D55ED7F98CFA480A0626484A04C3A937E2F64EBF238011D3CDEF4E1E21FA`, previamente demonstrou **navegação anual/evolução** por variável/campo real em piloto limitado, **não** série de 12 pontos.

O `preflight_manifest.json` fornecido pelo operador identificou QlikView `12.0.20000.0` e integridade reportada de **10+12 QVDs e 3 QVWs**. Essa evidência não responde se o mesmo QVW já contém **ambos** os componentes. A próxima prova necessária é apenas **inventário de presença e compatibilidade de objetos**, *não* repetir os pilotos, recalcular números ou tentar executar o modo `EVOLUCAO/2019`.

**Objetivo:** uma inspeção visual de presença de **objetos existentes**, em cópias de cada QVW. Ao final, concluir `CANDIDATE_SINGLE_QVW_IDENTIFIED`, `NO_SINGLE_QVW_FOUND` ou `INCONCLUSIVE`, sempre com revisão humana de capturas; nenhum desses estados equivale a homologação temporal.

## 2. Contrato do runner protegido

**Script versionado:** [`tools/Invoke-SadC2VisualCompatibilityCopy01.ps1`](../../tools/Invoke-SadC2VisualCompatibilityCopy01.ps1). Reusa a estratégia `-Prepare/-Verify` do runner C2-K, com **fontes/pins atualizados apenas neste novo runner**, sem alterar C2-K e sem repetir seus testes. O runner NÃO chama COM, não abre GUI, não carrega QVD, não recarrega documento, não modifica QVS e não salva QVW.

- **Entrada:** `-Root`, `-P11P12Qvw`, `-C2kQvw`, `-RuntimeRoot` e `-EvidenceRoot` (todos caminhos absolutos). Ambos os últimos diretórios devem existir, separados e fora do repo/Git; as fontes também fora de ambos.
- **Guardas:** branch versionada correta, checkout limpo, ancestralidade do baseline, hash fixo das duas origens, QlikView **fechado** nos modos Prepare/Verify, contagem exata **10 QVDs de extração + 12 de transformação + 3 QVWs canônicos**.
- **`-Prepare`:** uma única chamada para criar **duas cópias em nova pasta** e manifesto de hash `compat_manifest.json` em evidência externa. **Não abrir** as origens: só abrir os caminhos `RUNTIME_P11_COPY`/`RUNTIME_C2K_COPY` reportados.
- **`-Verify -RunDir`:** somente após fechar ambos os documentos sem salvar, compara inventário protegido pré/pós, hashes das origens e confirma que **ambas as cópias continuam byte a byte idênticas** às origens. Gera `compat_verify.json`. Veredito máximo automatizado `PASS_COPY_INTEGRITY_ONLY_NOT_UI`.

**Proteções:** nunca copiar para dentro do repositório, nunca aplicar Save/Reload no QlikView, nunca editar objetos, expressões, variáveis, botões, bookmarks, listas, propriedades nem escolher filtros. Abrir/inspecionar e **fechar sem salvar**. Caso a Personal Edition peça restauração/licença, mude seleção automaticamente, ou a aplicação tente modificar origens, **STOP**, preservar evidência e não avançar. O script não pode atestar a qualidade da inspeção visual.

## 3. Inspeção GUI — uma passagem em cada cópia

**PASS mínimo de inventário:** screenshot(s) inequívocas + notas de observação, sem clicar em ações de seleção. Operador examina somente **objetos existentes**, sem criar outros:

| Cópia | O que localizar e registrar | O que NÃO inferir |
| --- | --- | --- |
| `RUNTIME_P11_COPY` | Folhas; IDs/títulos de **quatro cartões P1.1** e gráfico P1.2; se há botões `MENSAL`, `ANUAL`, `EVOLUCAO` já presentes; se existem referências visíveis a `PERIODO_ANO`/`PERIODO_COMPETENCIA` ou diagnósticos de campo real | Quatro cartões e linha 36 meses **não** demonstram controles guiados integrados; não repetir valores 4/4 nem export 36/36 |
| `RUNTIME_C2K_COPY` | Folhas; controles guiados existentes, diagnóstico do **ano/competência reais**, qualquer gráfico de linha P1.2 existente **com dimensão `PERIODO_COMPETENCIA` e medida `QTD_INTERNACAO`**, e cartões P1.1 se presentes | Controles de navegação não demonstram série de 12 meses, nem diagnóstico textual P5 autoriza KPI |

Se propriedades de objeto forem abertas **somente para leitura**, registrar o ID e expressão visível e **cancelar**, não confirmar qualquer alteração. Se os objetos não estiverem visíveis em uma folha, inspecionar as folhas já existentes e, se necessário, listas de objetos disponíveis, sem editar. **Não declarar ausência definitiva** só porque não apareceu na primeira folha; usar `INCONCLUSIVE` se não for possível inspecionar todas as folhas/objetos com segurança.

**Evidências persistentes, fora do Git:** `p11p12_objects.png`, `c2k_objects.png`, imagens adicionais de propriedades quando necessário, e `compatibility_notes.txt` com campos: `COPY`, `OBJECT_IDS`, `GUI_MODES_PRESENT`, `REAL_TIME_FIELDS_PRESENT`, `P11_CARDS_PRESENT`, `P12_CHART_PRESENT`, `P12_DIMENSION`, `P12_MEASURE`, `SINGLE_QVW_CANDIDATE` e `UNCERTAINTY`. Use `UNKNOWN` quando não inspecionado, nunca inferir por nomes do arquivo.

**Sem testes de seleção, 12 meses, oráculo ou comportamento D2/P5 nesta etapa.** Não repetir C2-J/K, 36/36 de P1.2, 25/25 do preflight antigo nem AE01/A0 R1.

## 4. Roteiro PowerShell 5.1 nativo (a executar só no Windows)

Na raiz do clone, primeiro confirmar worktree limpa e HEAD da branch versionada **exato do PR vigente**. Não aplicar `reset`/`clean`/`stash` se houver arquivos não rastreados. As duas origens já foram **localizadas pelo operador** no preflight anterior; utilizar caminhos existentes, não procurar outras cópias.

~~~powershell
# Com a branch de compatibilidade selecionada e HEAD remoto conferido
$repo = (Get-Location).Path
$p11 = Join-Path $env:USERPROFILE 'Documents\SAD_P11P12_VISUAL_POLISH_RUNTIME\SAD_P11P12_VISUAL_f673cac03dea40f292fb202ff903521a\SAD_P11P12_VISUAL_POLISH_COPY.qvw'
$c2k = Join-Path $env:USERPROFILE 'Documents\SAD_C2K_ANNUAL_RUNTIME\SAD_VIII_C2K_ANNUAL_47f2ae84abd747cb963f1cb8baad41a4\SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw'
$runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_COMPAT_RUNTIME'
$evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_COMPAT_EVIDENCIAS'
New-Item -ItemType Directory -Path $runtime,$evidence -Force | Out-Null

$runner = Join-Path $repo 'tools\Invoke-SadC2VisualCompatibilityCopy01.ps1'
$tokens = $null; $errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
if ($errors.Count -gt 0) { $errors | ForEach-Object {$_.ToString()}; throw 'BLOCKED_PARSER' }

powershell.exe -NoProfile -File $runner -Root $repo -P11P12Qvw $p11 -C2kQvw $c2k -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
~~~

Após `-Prepare` bem-sucedido, abrir **apenas os dois caminhos RUNTIME** indicados, um de cada vez, inspecionar sem editar e **fechar sem salvar**. Depois, executar **uma vez** o `-Verify` no **mesmo checkout**, substituindo somente o valor de `-RunDir` pelo `EVIDENCE_DIR` realmente emitido:

~~~powershell
powershell.exe -NoProfile -File $runner -Root $repo -P11P12Qvw $p11 -C2kQvw $c2k -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir 'COLE_O_EVIDENCE_DIR_REPORTADO_NO_PREPARE'
~~~

**Comandos acima não foram executados nesta sessão.** Não prosseguir se `-Prepare` não emitir `PASS_COPIES_PREPARED_ONLY_GUI_NOT_TESTED` ou se alguma fonte/protegido divergir.

## 4.1. Bloqueio observado no primeiro Prepare e correção versionada

**Evidência do operador:** checkout em `347e350f487d2656b0802aadd9cb569803c68902` e parser PowerShell 5.1 `PARSER=PASS`. O primeiro `-Prepare` terminou `BLOCKED_PREPARE_EXECUTION` com erro de comando nativo encapsulado em `NativeCommandError`; a saída original do filho não foi capturada por `Tee-Object`, `prepare_stdout.txt` não existe e nenhum subdiretório foi exibido em `EVIDENCE_ROOT`. Não há PASS de Prepare/GUI/Verify.

**Defeito estático identificado no runner original:** `function H` (cálculo SHA) colidia com o alias nativo PowerShell `h` → `Get-History`. Aliases têm precedência sobre funções; portanto chamadas `H $p11` etc. não referiam o helper SHA de forma segura. Essa colisão é **causa técnica demonstrável no código, compatível com a parada antes do primeiro Write-Output**, mas a mensagem nativa original não foi recuperada. Não atribuir a causa de modo exclusivo sem um log conclusivo. Corrigido **na mesma branch** alterando exclusivamente o nome do helper para `Get-SadC2FileSha256` em todos os pontos de chamada, por commit adicional; o resultado físico dessa correção ainda depende de nova execução versionada.

**Protocolo para obter log em eventual tentativa após aprovação do patch:** o pai PowerShell tinha `$ErrorActionPreference='Stop'`; em Windows PowerShell 5.1, `2>&1 | Tee-Object` pode transformar o stderr de `powershell.exe` em `NativeCommandError` antes de gravar o log. Temporariamente usar `Continue` **somente ao redor da chamada nativa**, restaurar a preferência e conferir `$LASTEXITCODE` imediatamente:

~~~powershell
$previousPreference = $ErrorActionPreference
$childExit = $null
try {
    $ErrorActionPreference = 'Continue'
    & powershell.exe -NoProfile -File $runner -Root $repo `
        -P11P12Qvw $p11 -C2kQvw $c2k `
        -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare 2>&1 |
        Tee-Object -FilePath (Join-Path $evidence 'prepare_stdout.txt')
    $childExit = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $previousPreference
}
if ($childExit -ne 0) {
    throw ('BLOCKED_PREPARE_EXIT_' + $childExit + '_READ_STDOUT_BEFORE_RETRY')
}
~~~

**Não executar este bloco com o HEAD antigo.** Conferir branch/commit remoto efetivo do PR após o patch, `git status` limpo, `git fetch` e atualização não destrutiva do checkout. Os scripts antigos versionados permanecem no histórico. A nova tentativa física, se efetuada, inicia **um novo resultado vinculado ao SHA corrigido**; não herdar PASS. Não insistir após nova falha, preservar stderr e stdout; não abrir QVW enquanto `-Prepare` estiver bloqueado.

## 4.2. Inspeção GUI recebida e bloqueio de Verify (29–30/10/2026)

**Fontes verificadas nesta conversa:** cinco capturas PNG do QlikView x64 Personal Edition nas duas **cópias TEMP** e transcrição textual integral do PowerShell `-Verify`; nenhum QVW/QVD original foi lido diretamente por este agente. **Imagens não versionadas no Git.**

**Observação visual efetiva (sem extrapolar comportamento):**

| Cópia | Captura observada | Limite |
| --- | --- | --- |
| `SAD_C2_COMPAT_P11P12_COPY.qvw` | Folhas `Principal`, `POC - Interface Guiada` e `POC P1.1-P1.2 - Internações`. Quatro KPIs `183.532`, `183.311`, `188.246`, `555.089`; gráfico de evolução mensal 2017–2019; na aba guiada, botões `Mensal`, `Anual`, `Evolução` e diagnóstico de seleção real | A interface mostra proposta `Modo: EVOLUCAO | Ano: 2019 | Mês: 1`, mas `ANO REAL: SEM SELECAO | Qtd: 0` e `COMPETENCIA REAL: SEM SELECAO | Qtd: 0`. Portanto, presença conjunta de controles+objetos **não** prova filtro efetivamente aplicado ou gráfico de 12 competências |
| `SAD_C2_COMPAT_C2K_COPY.qvw` | Folhas `Principal` e `POC - Interface Guiada`; controles guiados, ano real `2019`, município SERV `250750`, `P5: B - INDICADOR RES INDISPONIVEL` | Sem folha P1.1/P1.2 visível nas capturas; não há prova do gráfico P1.2 nessa QVW. O estado do filtro é apenas o observado, não homologação de P5 |

**Decisão restrita sobre presença:** `CANDIDATE_SINGLE_QVW_IDENTIFIED=P11P12_COPY` **com confiança visual limitada a existência conjunta, em abas diferentes**. IDs e expressões físicos dos objetos não foram inspecionados; `P12_DIMENSION=NOT_READ_FROM_PROPERTIES`, `P12_MEASURE=NOT_READ_FROM_PROPERTIES`. **Nenhum teste novo `EVOLUCAO/2019` ou contagem de 12 pontos foi realizado.**

**Verify realizado pelo operador após GUI:** `VERSIONED_GIT_HEAD=378f32883b9ab51b42eec52107eddb5e78e2377e`, `RUNNER_SHA256=277B6C3CFDEB51B8D6A258AEAF82D1A5B02C2229BDF347051CBD287745CC0FD0`, `VERIFY_EXIT_CODE=1`; `PROTECTED_25_UNCHANGED=True`, `BOTH_SOURCES_UNCHANGED=False`, `BOTH_COPIES_UNSAVED=False`, e hashes das duas cópias **iguais exatamente** aos hashes fixos históricos. O runner encerrou com `HARD_STOP_INTEGRITY` e **não** produziu `compat_verify.json`. Esse texto é **resultado reportado, não evidência de corrupção**.

**Bug real identificado no código versionado de Verify:** havia `-cne` (diferença) na definição de `$sourcesOk` e `$copiesOk`, mas a variável significava `UNCHANGED`. Isso devolvia `False` quando os dois hashes eram **iguais** ao esperado. Corrigido para `-ceq` nos dois checks, e acrescentada saída explícita de hashes das origens. O `-Prepare`, que usava `-cne` corretamente como guardião de desvio, **não** foi modificado.

**Proveniência entre commits:** o manifesto foi produzido no `Prepare` original (`GitHead=378f328...`, `RunnerSha256=277B6C...`). O patch altera o hash do runner e o HEAD, portanto um Verify normal rejeitaria o manifesto por proveniência. O novo `-Verify` aceita **somente** a tupla já observada `378f328...` + `277B6C...` **e** o diretório `SAD_C2_COMPAT_309e2bb9c3da41b1a9ea28c0a1a30b40`, exige ancestralidade do antigo commit e conserva todas as demais verificações (duas origens/hashes, estrutura, cópias, 25 protegidos, branch limpa). Emitirá `VERIFY_PREPARE_PROVENANCE=PATCHED_LEGACY_RUN`; isso não autoriza uso genérico de manifestos antigos ou montagem de novos QVWs.

**Próximo comando físico permitido após revisão e atualização da branch:** `-Verify -RunDir` *uma única vez*, sem `-Prepare` e sem reabrir QlikView, com stdout **em novo arquivo** `verify_patch_stdout.txt` para não sobrescrever o erro anterior. Depois anexar `compat_verify.json` e ambos os logs para conciliação.

**Estado enquanto Verify corrigido não executado:** `PREPARE=PASS_LOCAL_REPORTED`, `GUI_OBJECT_INVENTORY=CANDIDATE_P11P12_IDENTIFIED_LIMITED`, `VERIFY=BLOCKED_RUNNER_LOGIC_BUG`, `COPY_INTEGRITY_PASS=NOT_GRANTED`, `C2_FULL=NO_GO_NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## 5. Critérios de encerramento e decisão posterior

| Veredito | Quando pode ser atribuído |
| --- | --- |
| `PASS_COPIES_PREPARED_ONLY_GUI_NOT_TESTED` | Runner criou duas cópias idênticas com manifesto e preservou 25 protegidos durante Prepare |
| `PASS_COPY_INTEGRITY_ONLY_NOT_UI` | Verify registrou 25 protegidos, duas origens e duas cópias sem alterações |
| `CANDIDATE_SINGLE_QVW_IDENTIFIED` | Evidência visual revisada confirma **no mesmo QVW** controles temporais reais + gráfico P1.2; valores/seleções ainda não testados |
| `NO_SINGLE_QVW_FOUND` | Inspeção abrangente e documentada de ambas as QVWs não encontrou a superfície conjunta; somente proposta de **outro gate** para integração em nova cópia |
| `INCONCLUSIVE` | Folhas/objetos impossíveis de inspecionar, capturas ou notes insuficientes |
| `BLOCKED` / `HARD_STOP` | SHA divergente, QlikView fechado incorretamente, worktree alterada, parser falhou ou cópia modificada indevidamente |

**STOP:** uma preparação, uma inspeção read-only de cada cópia e uma verificação. Mesmo em `CANDIDATE_SINGLE_QVW_IDENTIFIED`, não iniciar teste `EVOLUCAO/2019` de 12 competências automaticamente; requer protocolo físico distinto usando o oráculo já arquivado, sem repetição de C2-J/K.

**Fronteiras:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED` e `PRODUCTION_APPROVED=False`.
