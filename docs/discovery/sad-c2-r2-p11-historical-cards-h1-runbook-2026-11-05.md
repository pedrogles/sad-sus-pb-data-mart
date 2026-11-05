# SAD C2 D2-R2 — Gate P1.1 H0/H1/H2, cartões históricos

Gate ID: SAD-C2-R2-P11-HISTORICAL-CARDS-H1-01
Status deste documento: RUNBOOK_PREPARED_PHYSICAL_NOT_RUN.
Baseline: main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83.
V3 D2-R2 rege D2; V2 rege os demais contratos. Sem autorização de merge, C2/P5 global, C3/C4, Fase IX ou produção.

## Fonte, escopo e decisão

PR #219 contém aprovação expressa (04/11/2026) da alternativa A: cartões históricos mantêm anos fixos, preservando filtros não temporais compatíveis. PR #220 reportou CH02 H1 PASS restrito e, fora do seu escopo, os quatro cartões retornando 0 / 0 / 14.820 / 14.820 quando ano=2019 e competência=201901. Este gate limita-se a TX13, TX11, TX12, TX10. Não tocar CH02, CH03, BU16, ETL, dimensões, fatos ou QVD.

A rotina PowerShell foi adaptada do Prepare/Verify protegido do PR #220, que é expressamente restrito a CH02 e não poderia ser reutilizado sem adaptação. Não existe automação de GUI, COM ou recarga nesta rotina. Dois scripts versionados:
- tools/derive_sad_p11_h2_oracle01.py: oráculo independente E1, somente leitura, antes do QlikView.
- tools/Invoke-SadC2R2P11HistoricalCardsH101.ps1: proteção dos 10 QVD de extração, 12 QVD de transformação e 3 QVW canônicos; uma TEMP; Prepare e Verify único.

QVW original de experimentação, protegida por hash:
C:\Users\pedro\Documents\SAD_C2_R2_RUNTIME\SAD_C2_R2_8dd311086a7a436f8545c8b867d5884b\SAD_C2_GUIDED_R2_TEMP.qvw
SHA-256 esperado: 648107FB45E61C6D5AA16EBA0959C58FAD579529DEC93CF42F74A9C9D957F9DD

E1 original, protegido por hash:
C:\Users\pedro\SAD_EVIDENCIAS\AE01_20261027_02\sih_fluxo_competencia.csv
SHA-256 esperado: F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615

## Matriz esperada

| Cenário | TX13 (2017) | TX11 (2018) | TX12 (2019) | TX10 (triênio) |
|---|---:|---:|---:|---:|
| H0: sem seleção | 183.532 | 183.311 | 188.246 | 555.089 |
| H1: seleção real 2019 + 201901 | 183.532 | 183.311 | 188.246 | 555.089 |
| H2: H1 + filtro real SERV_COD_DATASUS_6=250750 | Ler JSON expected.TX13 | Ler JSON expected.TX11 | Ler JSON expected.TX12 | 225.785 |

A origem do oráculo H2 é exclusivamente E1 agregado por ano e município de serviço, após validar SHA, 30.255 linhas, 36 competências, todos os totais globais e o total 225.785 do código 250750 publicado em P1.3. O vetor anual será obtido somente na execução local do preflight. O script não consulta QlikView. H2 comprova compatibilidade física apenas se as três seleções reais e os quatro valores forem observados. Não promover esta prova a P5/C3 global.

Hipótese única, somente o corpo numérico das quatro expressões:

    TX13: Sum({$<PERIODO_ANO={2017},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)
    TX11: Sum({$<PERIODO_ANO={2018},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)
    TX12: Sum({$<PERIODO_ANO={2019},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)
    TX10: Sum({$<PERIODO_ANO={2017,2018,2019},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)

Conservar qualquer wrapper de formatação original, somente inserir a limpeza de PERIODO_COMPETENCIA na expressão existente. Se a expressão original divergir, parar como INCONCLUSIVE_SOURCE_EXPRESSION. Não substituir o identificador $ por 1 e não criar hipótese alternativa.

## Comandos Windows PowerShell 5.1 — sessão única, antes da QVW

QlikView fechado. Executar na raiz local do repositório existente. Não prosseguir se algum comando falhar ou se a árvore estiver suja.

    $ErrorActionPreference = 'Stop'
    $branch = 'test/sad-c2-r2-p11-historical-cards-h1-20261105'
    if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
    git fetch origin "refs/heads/$($branch):refs/remotes/origin/$branch"
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_FETCH' }
    git show-ref --verify --quiet "refs/heads/$branch"
    if ($LASTEXITCODE -eq 0) { git switch $branch } else { git switch --track "origin/$branch" }
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_SWITCH' }
    $head = ([string](git rev-parse HEAD)).Trim()
    $remote = ([string](git rev-parse "origin/$branch")).Trim()
    if ($head -cne $remote) { throw 'BLOCKED_HEAD_DRIFT' }
    if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_AFTER_SWITCH' }
    $repo = (Get-Location).Path
    $runner = Join-Path $repo 'tools\Invoke-SadC2R2P11HistoricalCardsH101.ps1'
    $oracleScript = Join-Path $repo 'tools\derive_sad_p11_h2_oracle01.py'
    $tokens=$null; $parseErrors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
    if (@($parseErrors).Count -gt 0) { $parseErrors; throw 'BLOCKED_POWERSHELL_PARSER' }
    python -B -c "import ast,sys; ast.parse(open(sys.argv[1], encoding='utf-8').read())" $oracleScript
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_PYTHON_SYNTAX' }
    Write-Host "GIT_HEAD=$head"
    Write-Host "RUNNER_SHA256=$((Get-FileHash -LiteralPath $runner -Algorithm SHA256).Hash)"
    Write-Host "ORACLE_SCRIPT_SHA256=$((Get-FileHash -LiteralPath $oracleScript -Algorithm SHA256).Hash)"

    $source = Join-Path $env:USERPROFILE 'Documents\SAD_C2_R2_RUNTIME\SAD_C2_R2_8dd311086a7a436f8545c8b867d5884b\SAD_C2_GUIDED_R2_TEMP.qvw'
    $e1 = Join-Path $env:USERPROFILE 'SAD_EVIDENCIAS\AE01_20261027_02\sih_fluxo_competencia.csv'
    $qvExe = 'C:\Program Files\QlikView\Qv.exe'
    $runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_P11_H1_RUNTIME'
    $evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_P11_H1_EVIDENCE'
    $h2root = Join-Path $env:USERPROFILE 'Documents\SAD_C2_P11_H2_ORACLE_20261105'
    foreach ($p in @($runtime,$evidence,$h2root)) {
        if (Test-Path -LiteralPath $p) { throw "BLOCKED_EXISTING_ROOT: $p" }
        New-Item -ItemType Directory -Path $p | Out-Null
    }
    $h2file = Join-Path $h2root 'h2_oracle.json'
    python -B $oracleScript --repo-root $repo --e1 $e1 --output $h2file
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_H2_ORACLE_PREFLIGHT' }
    Write-Host "H2_ORACLE_SHA256=$((Get-FileHash -LiteralPath $h2file -Algorithm SHA256).Hash)"
    Get-Content -LiteralPath $h2file -Raw
    & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -H2OracleFile $h2file -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
    Write-Host "PREPARE_EXIT_CODE=$LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_PREPARE' }

Somente continuar se PREPARE_EXIT_CODE=0, VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI, SHA fonte correto e H2 oracle já fixado. Guardar exatamente RUNTIME_COPY e EVIDENCE_DIR impressos.

## Procedimento GUI — apenas RUNTIME_COPY

1. H0: abrir exclusivamente a cópia TEMP criada. Confirmar ano e competência sem seleção (Qtd 0) e nenhum filtro não temporal. P1.1: observar os quatro números H0; capturar h0_cards.png. Se divergência, STOP.
2. H1: criar listboxes temporárias apenas dos campos existentes PERIODO_ANO e PERIODO_COMPETENCIA; selecionar 2019 e 201901. Comprovar Qtd 1/1 e ausência de filtro de serviço; capturar h1_real_state.png. Remover somente as listboxes recém-criadas, sem limpar as seleções. Em P1.1 capturar os quatro valores anteriores, h1_cards_before.png.
3. Em cada TX13, TX11, TX12, TX10, confirmar o Object ID nas Propriedades e a expressão original. Se os quatro valores H1 já coincidirem com H0, NÃO editar; registrar NO_EDIT_REQUIRED. Caso contrário, alterar no máximo uma vez o modificador de conjunto da medida para a hipótese acima, preservando wrapper de formatação; nenhum outro objeto pode ser editado. Após a hipótese, os quatro valores H1 devem ser 183.532 / 183.311 / 188.246 / 555.089; capturar h1_cards_after.png quando houver edição. Primeiro número errado => BLOCKED e STOP, sem segunda hipótese.
4. H2: manter seleções reais 2019 + 201901; adicionar uma lista temporária SERV_COD_DATASUS_6 e selecionar 250750. Comprovar 1/1/1 de seleção real e ausência de outros filtros, capturar h2_real_state.png. Comparar quatro valores com o arquivo h2_oracle.json gerado antes de abrir QVW. Capturar h2_cards.png. Qualquer diferença => BLOCKED; ausência de confirmação da compatibilidade => INCONCLUSIVE_H2 e STOP.
5. Após h2_real_state.png e h2_cards.png, remover SOMENTE a listbox SERV criada em H2; comprovar que a seleção real SERV ainda permanece. As listboxes temporárias criadas para ano/competência já devem ter sido removidas. As três listboxes NÃO podem ficar na QVW salva. Registrar gui_notes.txt em EVIDENCE_DIR: RunId, HEAD, hashes, expressões originais/candidatas, estados H0/H1/H2, valores esperados/observados por TX, evidências visuais, outros filtros, remoção das três listboxes, status e decisão SAVE.
6. Salvar uma única vez a QVW TEMP somente se H0/H1/H2 corretos e comprovados, listboxes transitórias removidas e alterações restritas às expressões dos quatro cartões. Em caso NO_EDIT_REQUIRED, não salvar; apenas Verify. Em BLOCKED/INCONCLUSIVE, fechar sem salvar. Não salvar QVW origem ou QVD.

## Verify único após fechamento de QlikView

Na mesma sessão PowerShell, com QlikView fechado: executar um único Verify após o cenário positivo OU após interrupção funcional recuperável, sem refazer H0/H1/H2. Uma violação crítica de integridade exige STOP imediato e preservação dos artefatos existentes, sem novas mutações.

    $runDir = Read-Host 'Cole EVIDENCE_DIR informado no Prepare'
    if (-not (Test-Path (Join-Path $runDir 'c2_p11_h1_prepare.json'))) { throw 'BLOCKED_WRONG_RUN_DIR' }
    if (Test-Path (Join-Path $runDir 'c2_p11_h1_verify.json')) { throw 'BLOCKED_VERIFY_ALREADY_RECORDED' }
    & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -H2OracleFile $h2file -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
    Write-Host "VERIFY_EXIT_CODE=$LASTEXITCODE"

Esperado para PASS: VERIFY_EXIT_CODE=0, PROTECTED_25_UNCHANGED=True, SOURCE_UNCHANGED=True, mesmo SHA do oráculo H2 e GUI_EVIDENCE_MISSING vazio, inclusive os dois PNGs H2 exigidos independentemente de Save. Em STOP antecipado, o Verify pode relatar GUI_EVIDENCE_MISSING sem que isso permita retomar testes ou apresentar PASS. COPY_CHANGED_FROM_SOURCE=True é permitido apenas após Save experimental. Verify de hash não prova conteúdo GUI nem diff dos quatro IDs. A inspeção das capturas é obrigatória.

## Veredito e STOP

PASS_RESTRICTED_P11_H0_H1_H2 somente com os 12 valores corretos (quatro em cada cenário), H2 previamente ancorado, seleção real comprovada, três listboxes transitórias removidas antes de qualquer Save, 25 protegidos e fonte inalterados, TEMP identificada e capturas examinadas.

BLOCKED: número falso apresentado como histórico, hipótese não funciona, filtro não temporal ignorado ou integridade violada. STOP imediato, sem outras expressões e sem nova TEMP.

INCONCLUSIVE: oráculo H2 ausente, compatibilidade não observável, seleção não comprovada, imagem insuficiente ou execução física não realizada.

STOP após único Prepare/uma TEMP/uma hipótese por cartão/um Save e um Verify, ou imediatamente em bloqueio crítico. Não abrir CH02, CH03, BU16, C3/C4/IX, produção nem outro gate.

Estados globais inalterados: C2_GUIDED_R2=NOT_APPROVED_GLOBAL; P5_D2_UI=NOT_TESTED_GLOBAL; C3/C4=NOT_APPROVED; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False.
