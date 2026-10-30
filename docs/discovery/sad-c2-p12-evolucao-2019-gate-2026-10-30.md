# SAD C2 — gate físico mínimo P1.2 EVOLUCAO/2019

**Gate:** `SAD-C2-P12-EVOLUTION-2019-01` (dependente da [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196)).  
**Baseline:** `main@843e8f4fea74a8d8ab60ebbab2033c4d181dd961`, após integração sequencial [#197](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/197) → [#198](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/198) por squash.  
**Status:** `RUNNER_VERSIONED / WINDOWS_NOT_RUN / GUI_2019_NOT_TESTED`. Preparação por ChatGPT GPT-6 + GitHub, sem acesso ao Windows. Executar via Codex Local Windows autorizado (modelo/esforço a registrar no ambiente real); fallback operador humano; não requer Work, Deep Research ou nova investigação de dados.

## 1. Escopo, premissas e risco previamente observado

**Objetivo único:** comprovar ou refutar, em **uma cópia TEMP da QVW P1.1/P1.2**, que uma única interação guiada para `EVOLUCAO/2019` efetivamente resulta em `PERIODO_ANO=2019` (um ano real), **zero `PERIODO_COMPETENCIA` explicitamente selecionadas**, e gráfico P1.2 com **12 competências 201901–201912** comparáveis ao oráculo de 36 meses já existente. Separar `MODE_PROPOSED` de `YEAR_ACTUALLY_SELECTED`. Não compor duas QVWs, não validar C2 inteiro e não estender a outros anos, filtros, livros de marcação ou painéis.

**Fatos existentes:** o preflight de duas origens e inventário visual encerraram com PASS restrito em Windows reportado; a QVW P1.1/P1.2 contém os quatro cartões e o gráfico de 36 meses em uma aba e os botões `Mensal`, `Anual`, `Evolução` em outra. **Captura anterior:** proposta `EVOLUCAO/2019`, mas `ANO REAL: SEM SELECAO`; portando presença conjunta ≠ funcionamento integrado. Os 25 binários canônicos e ambas as origens foram reportados intactos após inspeção. **Não repetir** os gates anteriores.

**Risco objetivo a testar, sem alterar antecipadamente:** no [closeout P1.1/P1.2](sad-p11-p12-physical-closeout-2026-10-29.md), a expressão existente no CH02 foi documentada como:

```qlik
=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)
```

Esse *set modifier* inclui explicitamente 2017–2019 e **pode** neutralizar o recorte anual pretendido, dependendo de dimensão/estado/associações. Isto é **hipótese de bloqueio funcional**, não resultado físico; nenhum ajuste de expressão ou criação de outro gráfico está autorizado neste gate. Se o gráfico mantiver 36 pontos, classificar `BLOCKED_EXISTING_CHART_DOES_NOT_APPLY_YEAR` e STOP.

**Contrato de UX:** [P1.1/P1.2](sad-p1-p11-p12-ux-contract-2026-10-28.md) diferencia história completa de 36 pontos da `EVOLUCAO` guiada de 12 pontos; o mesmo histórico não pode ser renomeado "Evolução 2019" se continuar trienal.

## 2. Artefatos e permissões

- **Runner versionado:** [`tools/Invoke-SadC2P12Evolution2019Copy01.ps1`](../../tools/Invoke-SadC2P12Evolution2019Copy01.ps1), PowerShell 5.1 com modos `-Prepare/-Verify`. Reusa padrão protegido de #198, **não** seu script histórico preso à outra branch. **Sem COM, QlikView launch, reload, salvar ou seleção automática**.
- **Fonte única pinada:** `SAD_P11P12_VISUAL_POLISH_COPY.qvw` fora de Git, SHA-256 `B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C`.
- **Protegidos:** 10 QVDs extração +12 QVDs transformação + 3 QVWs canônicos. QlikView 12 localizado como `Qv.exe`; requer Windows, branch exata/HEAD e checkout limpo.
- **Escritas permitidas:** nova cópia QVW em `RUNTIME_ROOT` externo ao Git e manifestos/capturas/logs em `EVIDENCE_ROOT` persistente, independente de `RUNTIME_ROOT`. Não criar dados QVD, QVS, alterá-los, nem tocar QVWs originais.
- **Proibições:** merge automático, nova modelagem, alterações em CH02/expressões, filtros em outras fatos, C3/C4, P5/D2, Link Key, Fase IX e produção.
- **STOP:** uma preparação, uma inspeção/botão guiado já existente, um levantamento da reação do gráfico e uma verificação final de hash. Não insistir por tentativa/erro.

## 3. Protocolo Windows — preparar exatamente uma cópia

**Pré-requisitos manuais:** branch do PR deste gate já selecionada em checkout limpo, sem atualizar durante a execução; HEAD confirmado contra o commit versionado remoto, QlikView fechado, pasta de runtime e evidências externas **existentes**, caminhos absolutos. Não usar `git clean`, `reset --hard` ou `stash -u`. Não executar o runner na `main`, porque o código do teste exige a branch versionada.

```powershell
$ErrorActionPreference='Stop'
$repo=(Get-Location).Path
$source=Join-Path $env:USERPROFILE 'Documents\SAD_P11P12_VISUAL_POLISH_RUNTIME\SAD_P11P12_VISUAL_f673cac03dea40f292fb202ff903521a\SAD_P11P12_VISUAL_POLISH_COPY.qvw'
$qlik='C:\Program Files\QlikView\Qv.exe'
$runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_2019_RUNTIME'
$evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_2019_EVIDENCIAS'
New-Item -ItemType Directory -Path $runtime,$evidence -Force | Out-Null
$runner=Join-Path $repo 'tools\Invoke-SadC2P12Evolution2019Copy01.ps1'
$tokens=$null; $errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
if ($errors.Count -gt 0) {$errors | ForEach-Object {$_.ToString()}; throw 'BLOCKED_PS_PARSER'}
$prior=$ErrorActionPreference
try {
 $ErrorActionPreference='Continue'
 & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source `
    -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare 2>&1 |
    Tee-Object -FilePath (Join-Path $evidence 'prepare_stdout.txt')
 $exit=$LASTEXITCODE
} finally {$ErrorActionPreference=$prior}
if ($exit -ne 0) {throw 'BLOCKED_PREPARE_READ_STDOUT_AND_STOP'}
```

**Somente depois de `PASS_PROTECTED_COPY_PREPARED_ONLY_NO_GUI`** abrir no QlikView 12 o caminho literal `RUNTIME_COPY` retornado. **Nunca abrir** o `$source` para este gate.

## 4. Um cenário GUI, com prova do estado real

1. **Antes:** documentar em PNG a folha `POC - Interface Guiada`, texto de modo/ano/mês propostos e indicadores `ANO REAL` e `COMPETENCIA REAL`. Não considerar proposta igual a seleção.
2. **Ação delimitada:** se o modo ainda não for `Evolução`, acioná-lo **uma única vez**, apenas como alteração de modo. Aplicar `Ano 2019` **uma única vez**, pelo controle guiado existente **se habilitado**. **Se a ação de aplicar ano estiver indisponível**, STOP com `BLOCKED_GUIDED_ACTION_UNAVAILABLE`; não selecionar ano via lista manual como atalho, não reconfigurar botões/variáveis, não usar macro alternativo.
3. **Depois:** capturar indicadores reais `ANO REAL: 2019 / Qtd 1` e `COMPETENCIA REAL: SEM SELECAO / Qtd 0`. Se os valores diferirem ou houver filtro residual incompatível, `BLOCKED_APPLIED_TIME_CONTEXT`. Não aceitar valor antigo como se estivesse filtrado.
4. Na folha `POC P1.1-P1.2 - Internações`, capturar gráfico P1.2 sob estado real 2019. Exportar tabela subjacente **somente se o gráfico mostrar exatamente 12 competências** em ordem `201901`–`201912`. Se mantiver 36 meses, STOP com `BLOCKED_EXISTING_CHART_DOES_NOT_APPLY_YEAR`, sem editar a fórmula. Se não houver leitura confiável de pontos, `INCONCLUSIVE_CHART_SERIES`.
5. **Oráculo sem reprocessamento:** conferir os 12 valores da exportação nova (se produzida) contra o *subconjunto de 2019* do TSV histórico já existente (o closeout do P1.2 registra SHA `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`). **Não presumir o caminho desse TSV nem alterar seus bytes.** Enviar ambos os TSV/CSV para comparação se não houver verificador versionado apropriado. Controle agregado secundário 2019: `188246` novas; máximo histórico `201905=17292`. Sem oráculo completo de 12 linhas, `INCONCLUSIVE_ORACLE_NOT_AVAILABLE`, nunca PASS.
6. Fechar a cópia **sem salvar**, sem Reload, sem mudar parâmetros/objetos ou mexer nas originais. Se QlikView Personal Edition solicitar conversão ou restauração, STOP e registrar.

**Evidências persistentes:** `gui_before.png`, `gui_after.png`, `p12_2019_chart.png` (quando aplicável), `p12_2019_export.tsv` (se possível), `gui_notes.txt` com ações realmente executadas, `prepare_stdout.txt`, `p12_2019_prepare.json`, `verify_stdout.txt`, `p12_2019_verify.json`, hashes e HEAD. Evidências não devem ir para Git.

## 4.1. Resultado físico observado e recuperação restrita (30/10/2026)

**Fonte:** captura do QlikView x64 Personal Edition na QVW TEMP, e transcrições PowerShell completas coladas pelo operador. Não foi realizada leitura independente dos binários QVD/QVW ou do JSON de evidência.

- `Prepare` original em `9bae813940fa85bcd01cfbdf8519bb5802253d18`, runner SHA `239532A9190DC5C8018FCF809A93DE4F3BF638CE69FC9D0812B2D40BA567BC2F`: `PASS_PROTECTED_COPY_PREPARED_ONLY_NO_GUI`. Diretório único: `SAD_C2_P12_2019_d1b3fe5814c34094861366e33b6bfd7c`.
- **GUI:** proposta `EVOLUCAO/2019`, `ANO REAL: SEM SELECAO | Qtd 0`, `COMPETENCIA REAL: SEM SELECAO | Qtd 0`, botão `Aplicar Ano 2019` desabilitado. **`GUI_2019=BLOCKED_GUIDED_ACTION_UNAVAILABLE`**; não houve prova de 12 pontos, nem edição do gráfico, nem autorização para contornar a ação pela lista manual.
- **Primeiro Verify:** `BLOCKED_CLOSE_QLIKVIEW_FIRST`, porque a aplicação estava aberta. Guarda correta, sem auditoria de hashes; não considerar corrupção.
- **Segundo Verify:** após fechar o QlikView, com HEAD original, reportou `PROTECTED_25_UNCHANGED=True`, `SOURCE_UNCHANGED=True`, `COPY_NOT_SAVED=True`, SHA da cópia `B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C` idêntico à origem. **Mas `VERIFY_EXIT_CODE=1`** antes do JSON final: mensagem `Não é possível converter ... System.String ... System.Management.Automation.SwitchParameter`.
- **Defeito real de código:** `[switch]$Verify` é parâmetro do script; próximo da gravação, a antiga atribuição `$verify=Join-Path ...` reutilizava **o mesmo nome insensível à caixa** e tentava converter string em SwitchParameter. Isso explica a falha **depois** dos hashes `True`. Nenhum `p12_2019_verify.json` foi confirmado como criado por essa tentativa.

**Patch versionado, ainda NÃO executado no Windows:** renomeou o destino de JSON para `$verifyEvidencePath` e manteve `-Prepare` e as verificações de hash inalteradas. Como os hashes do runner e HEAD mudaram no patch, `-Verify` admite **somente** o manifesto original (HEAD `9bae813...`, SHA de runner `239532...`) associado ao **runDir exato `SAD_C2_P12_2019_d1b3fe5814c34094861366e33b6bfd7c`**, sob `VERIFY_PREPARE_PROVENANCE=PATCHED_LEGACY_PREPARE` e ancestralidade Git. A exceção não alcança outras preparações, fontes, paths ou hashes; o objetivo é **concluir a integridade desta mesma execução sem repetir GUI ou Prepare**.

**Próxima e última ação física desta subetapa:** atualizar a mesma branch por fast-forward com worktree limpo, confirmar HEAD exato do patch, parser PowerShell 5.1 e Qlik fechado. Rodar uma única verificação `-Verify` apontando para o manifesto anterior, gravando a nova saída em `verify_patched_stdout.txt` (não sobrescrever `verify_stdout.txt` ou `verify_after_close_stdout.txt`). Se `p12_2019_verify.json` já existir, STOP e conferir antes de qualquer tentativa. Conferir `PROTECTED_25_UNCHANGED=True`, `SOURCE_UNCHANGED=True`, `COPY_NOT_SAVED=True` e `VERDICT=PASS_PROTECTED_COPY_INTEGRITY_ONLY_NOT_GUI`. Se falhar, **STOP**, sem retries adicionais.

**Estados até a nova prova:** `GUI_2019=BLOCKED_GUIDED_ACTION_UNAVAILABLE`, `P12_EVOLUTION_12_MONTHS=NOT_TESTED`, `INTEGRITY_HASHES=PASS_LOCAL_REPORTED`, `VERIFY_JSON_CLOSEOUT=BLOCKED_RUNNER_NAME_COLLISION`, `C2_FULL=NO_GO_NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## 5. Verificar integridade após fechar QlikView

No **mesmo commit e branch**, `RunDir` deve ser exatamente `EVIDENCE_DIR` emitido no Prepare:

```powershell
$runDir='COLE_O_EVIDENCE_DIR_EXATO'
$prior=$ErrorActionPreference
try {
 $ErrorActionPreference='Continue'
 & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source `
    -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify `
    -RunDir $runDir 2>&1 | Tee-Object -FilePath (Join-Path $runDir 'verify_stdout.txt')
 $exit=$LASTEXITCODE
} finally {$ErrorActionPreference=$prior}
if ($exit -ne 0) {throw 'BLOCKED_VERIFY_READ_STDOUT_AND_STOP'}
```

Veredito máximo **do script**: `PASS_PROTECTED_COPY_INTEGRITY_ONLY_NOT_GUI`. Ele **não verifica** visual, seleção, gráfico ou oráculo. A classificação `PASS_VISUAL_2019_12_OF_12_RESTRICTED` só pode ser emitida após capturas, estado real e export/oráculo reconciliados no escopo.

| Estado | Condição de parada |
| --- | --- |
| `PASS_VISUAL_2019_12_OF_12_RESTRICTED` | Ano real 2019 aplicado, competência real sem seleção, gráfico 12 pontos e export integral reconciliado a 2019 do TSV histórico; 25 protegidos e fonte íntegros |
| `BLOCKED_GUIDED_ACTION_UNAVAILABLE` / `BLOCKED_APPLIED_TIME_CONTEXT` | Ação desabilitada ou proposta difere da seleção real; não corrigir UI nesta execução |
| `BLOCKED_EXISTING_CHART_DOES_NOT_APPLY_YEAR` | Gráfico continua histórico trienal após ano 2019 real aplicado |
| `INCONCLUSIVE` | Captura, série, tabela exportada ou TSV histórico indisponíveis |
| `HARD_STOP` | Fonte/protegidos modificados, checkout errôneo ou necessidade de alterar semântica |

**Fronteiras invariantes:** `C2_FULL=NO_GO_NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Mesmo PASS restrito aqui **não** libera C3, C4, merge ou painéis definitivos automaticamente.
