# C2-R2 — runbook de execução física T0/T1/T2 (nova TEMP)

**Gate:** SAD-C2-GUIDED-R2-PHYSICAL-ACCEPTANCE-01. **Autorizado:** usuário aprovou explicitamente em 03/11/2026 a execução T0/T1/T2 em uma nova cópia TEMP, com até dois objetos diagnósticos e uma operação nativa. **Baseline:** main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83 (após #214). Contrato semântico: V3 D2-R2 (PR #213). Especificação: PR #215 Draft.

**Status inicial:** RUNNER_VERSIONED_IN_DRAFT; PHYSICAL_EXECUTION=NOT_RUN; WINDOWS_PARSER=NOT_RUN; PREPARE=NOT_RUN; T0=NOT_RUN; T1=NOT_RUN; T2=NOT_RUN; VERIFY=NOT_RUN; C2_GUIDED_R2=NOT_TESTED.

## 1. Origem e proteção

- Origem intocável: C:\Users\pedro\Documents\SAD_C2_PREDISPATCH_RUNTIME\SAD_C2_PREDISPATCH_d6f8664aac094bbe9e13a85ca79367c4\SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw
- SHA-256 esperado da origem: A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517 (evidência local anterior #208/#210, não conferida nesta execução remota).
- Protegidos: 10 QVDs EXTRACAO/QVD, 12 QVDs TRANSFORMACAO/QVD, EXTRACAO/EXT.qvw, TRANSFORMACAO/TRANSF.qvw, PAINEL/PAINEL.qvw.
- QlikView Desktop observado e exigido: 12.0.20000.0; Windows PowerShell 5.1. O conector GitHub não controla a GUI Windows nem lê a origem QVW. **Não abrir/salvar a origem; modificar somente a nova RUNTIME_COPY.**
- Provas anteriores a reutilizar, sem repetição: #201 BU15/2019, #205 2019 12/12 FI total 188246, #208 guarda BU16 inconclusiva para 0→1→0 e sem UX de motivo, #210 inventário nativo sem execução de seleção e Verify de integridade.

## 2. Preflight no Windows, na raiz local do repo

No PowerShell 5.1, fechar QlikView, assegurar worktree limpa e executar:

    $ErrorActionPreference='Stop'
    if (@(git status --porcelain --untracked-files=all).Count -gt 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
    git fetch origin test/sad-c2-guided-r2-physical-acceptance-20261103
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_FETCH' }
    git switch --create test/sad-c2-guided-r2-physical-acceptance-20261103 --track origin/test/sad-c2-guided-r2-physical-acceptance-20261103
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_SWITCH' }
    $repo=(Get-Location).Path
    $runner=Join-Path $repo 'tools\Invoke-SadC2GuidedR2PhysicalAcceptance01.ps1'
    $tokens=$null; $parseErrors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
    if (@($parseErrors).Count -gt 0) { $parseErrors; throw 'BLOCKED_PARSER' }
    Write-Host 'PARSER=PASS'
    git rev-parse HEAD
    git status --short

Se branch já existir ou parser falhar, STOP, sem force/merge/edição local. O runner verifica branch/ancestralidade, script commitado e worktree limpa.

## 3. Prepare — cria nova cópia, não executa QlikView

    $repo=(Get-Location).Path
    $runner=Join-Path $repo 'tools\Invoke-SadC2GuidedR2PhysicalAcceptance01.ps1'
    $source='C:\Users\pedro\Documents\SAD_C2_PREDISPATCH_RUNTIME\SAD_C2_PREDISPATCH_d6f8664aac094bbe9e13a85ca79367c4\SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw'
    $qlik='C:\Program Files\QlikView\Qv.exe'
    $runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2_R2_RUNTIME'
    $evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2_R2_EVIDENCE'
    New-Item -ItemType Directory -Force -Path $runtime,$evidence | Out-Null
    & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
    Write-Host "PREPARE_EXIT_CODE=$LASTEXITCODE"

Aceite exclusivo do Prepare: PREPARE_EXIT_CODE=0, GIT_HEAD, RUNNER_SHA256, SOURCE_SHA256, QV_PRODUCT_VERSION=12.0.20000.0, RUNTIME_COPY, EVIDENCE_DIR, VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI. Todos os caminhos vêm da saída, nunca são inventados. Prepare NÃO utiliza COM, Reload, GUI, seleções ou Save.

## 4. GUI — no máximo dois Text Objects, um T1 e um T2

Abrir SOMENTE a nova RUNTIME_COPY impressa. **T0:** confirmar realmente PERIODO_ANO 2019 com uma seleção explícita, PERIODO_COMPETENCIA sem seleção explícita, outros filtros neutros, BU15/BU16 presentes. Divergência = INCONCLUSIVE_BASE_STATE, STOP sem tentar limpar ou reconstruir o estado.

Adicionar, **apenas na cópia**, dois Text Objects diagnósticos. Seus IDs reais devem ser documentados e não presumidos. Expressões candidatas no editor QlikView, a validar como Expressão OK; falha = BLOCKED_EXPRESSION_OR_UI, sem novos objetos/truques:

**R2_STATUS_GUIDED** — texto do motivo:

    =If('$(vSAD_POC_Mode)'='MENSAL'
        and GetSelectedCount(PERIODO_ANO)=1
        and Num(Only(PERIODO_ANO))<>Num($(vSAD_POC_Year)),
        'Não aplicado: ano proposto difere do ano real',
        'Sem conflito desta classe')

**R2_KPI_ANUAL_CANARY** — KPI de internações FI com ano selecionado explicitamente:

    =If(GetSelectedCount(PERIODO_ANO)=1
        and GetSelectedCount(PERIODO_COMPETENCIA)=0,
        Num(Sum(QTD_INTERNACAO),'#,##0'),
        'Indisponível: ano não selecionado ou contexto temporal inválido')

A condição do canário NÃO valida P5, multi-anos por série, snapshots, outros fatos ou todos os 14 visuais. Para T0 com ano real 2019 e filtros neutros, conferir valor numérico 188246; divergência = STOP. Não corrigir com Set Analysis que ignore filtros. Salvar a cópia UMA vez após criar os objetos, antes de T1/T2. Salvar screenshots t0_state.png e objects_properties.png no EVIDENCE_DIR.

**T1, guiado negativo:** mudar SOMENTE variáveis propostas para MENSAL/2018/01. Registrar t1_before.png (BU16 desabilitado, motivo visível, ano real 2019 e competência real sem seleção). Se BU16 estiver de fato desabilitado, fazer no máximo uma tentativa de clique inerte, registrar t1_after.png; nenhuma seleção pode mudar. Se habilitar, disparar ou faltar motivo => BLOCKED_GUIDED_PRE_DISPATCH, STOP sem T2.

**T2, pós-seleção nativa:** mudar SOMENTE variáveis de proposta para ANUAL/2019 (não clicar em botões). Confirmar ano real selecionado 2019, competência sem seleção, canário 188246. Registrar t2_valid_2019.png. Executar UMA vez Seleções > Limpar. Registrar t2_after_clear.png contendo o estado real de PERIODO_ANO e canário na mesma sessão. Se ano real ficar sem seleção explícita e competência sem seleção, o canário deve exibir Indisponível, não 188246 anual válido. Se o menu não alterar o ano, INCONCLUSIVE_NATIVE_ACTION_NOT_APPLIED (não substituir por Limpar tudo); se alterar e o canário continuar numérico válido, BLOCKED_POST_NATIVE_PRESENTATION. STOP.

Produzir gui_notes.txt no EVIDENCE_DIR com RunId, HEAD, IDs, expressões aceitas, estado antes/depois, prints, motivo visível, etapas não executadas e causa da falha. Se STOP antes do fim, NÃO fabricar PNGs. Fechar QlikView completamente sem salvar estados de T1/T2; nunca salvar origem ou 25 canônicos.

## 5. Verify, uma vez, após fechar QlikView

Reutilizar variáveis da etapa Prepare ($repo, $runner, $source, $qlik, $runtime, $evidence); substituir com o EVIDENCE_DIR real:

    $runDir='<EVIDENCE_DIR_REAL_IMPRESSO>'
    & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
    Write-Host "VERIFY_EXIT_CODE=$LASTEXITCODE"

Verify compara hashes de fonte e 25 protegidos, reporta COPY_CHANGED_FROM_SOURCE, GUI_EVIDENCE_MISSING e cria c2_r2_verify.json uma única vez. PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI é SOMENTE integridade: não prova objetos, conteúdo de screenshots nem comportamento da interface. Se hash divergir, HARD_STOP_INTEGRITY, preservar saída e não repetir.

## 6. Veredito, STOP e governança

- PASS_RESTRICTED_R2_T1_T2_SAME_TEMP exige T0+T1+T2 realmente observados, motivo, seleção preservada, indisponibilidade após Limpar, canário 188246 prévio, documentação visual e Verify de integridade local.
- BLOCKED_GUIDED_PRE_DISPATCH: conflito indevidamente aceito, botão habilitado ou motivo ausente; não executar T2.
- BLOCKED_POST_NATIVE_PRESENTATION: ano efetivamente limpo com KPI anual indevidamente numérico/válido.
- INCONCLUSIVE: baseline incorreta, fonte/build ausente, expressão não comprovada, Limpar sem efeito esperado ou provas insuficientes.
- HARD_STOP_INTEGRITY: alteração de origem/25 protegidos, script/HEAD/branch inesperados.

O canário FI e um comando nativo NÃO comprovam cobertura de 14 indicadores nem homologam C2 completo. Invariantes: C2_GUIDED_R2=NOT_APPROVED_GLOBAL; P5_D2_UI=NOT_TESTED_GLOBAL; LINK_KEY_CONTRACT=NOT_APPROVED; MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False. **STOP** após uma execução delimitada; não fazer merge de PRs experimentais, C3/C4, Fase IX ou produção.