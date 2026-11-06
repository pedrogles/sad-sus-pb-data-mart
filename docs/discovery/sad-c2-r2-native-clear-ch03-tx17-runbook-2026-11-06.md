# SAD C2-R2 — Runbook: CH03/TX17 após Limpar nativo

**Gate:** SAD-C2-R2-NATIVE-CLEAR-CH03-TX17-01.
**Baseline:** main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83.
**Status:** PREPARED_NOT_EXECUTED.
**Executor:** Windows PowerShell 5.1 + QlikView Desktop 12.0.20000.0. O ChatGPT/GitHub não opera o desktop local.
**Escopo:** uma TEMP nova, uma correção candidata exclusiva no texto de TX17, setup de F2, uma ação Seleções → Limpar, screenshots, Save único condicionado a PASS e Verify. Não representa C2 global.

## 1. Fonte protegida e limites

QVW fonte de F1/F2 aceita apenas visualmente:

~~~text
C:\Users\pedro\Documents\SAD_C2_FINAL_RUNTIME_20261105\SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321\SAD_C2_R2_FINAL_CONSOLIDATION_TEMP.qvw
~~~

SHA-256 **exigido**: 6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58.

**Não modificar** a origem, a QVW #222, 22 QVDs ou 3 QVWs canônicos. Não modificar CH02, CH03, cartões TX10–TX13, BU15/BU16, variáveis, associações ou medidas. Não Reload, importar bookmark, acionar Voltar/Adiante, repetir F1/F2/TX16, oráculos ou auditoria #223. Este runner é derivado do Prepare/Verify do PR #223, mas possui pins, branch e evidências próprios.

## 2. Checkout e Prepare — PowerShell

Na raiz do repositório, com QlikView fechado e worktree limpa:

~~~powershell
& {
    $ErrorActionPreference = 'Stop'
    $branch = 'test/sad-c2-r2-native-clear-ch03-tx17-20261106'
    if (@(git status --porcelain --untracked-files=all).Count -ne 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
    git fetch origin main $branch
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_FETCH' }
    git switch --track "origin/$branch"
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_SWITCH' }
    $repo = (git rev-parse --show-toplevel).Trim()
    $runner = Join-Path $repo 'tools\Invoke-SadC2R2NativeClearCH03TX1701.ps1'
    $tokens=$null; $parseErrors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
    if (@($parseErrors).Count -ne 0) { $parseErrors; throw 'BLOCKED_PARSER' }
    if (@(git status --porcelain --untracked-files=all).Count -ne 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
    $source = Join-Path $env:USERPROFILE 'Documents\SAD_C2_FINAL_RUNTIME_20261105\SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321\SAD_C2_R2_FINAL_CONSOLIDATION_TEMP.qvw'
    $qvExe = 'C:\Program Files\QlikView\Qv.exe'
    $runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_NATIVE_CLEAR_RUNTIME_20261106'
    $evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_NATIVE_CLEAR_EVIDENCE_20261106'
    if ((Test-Path $runtime) -or (Test-Path $evidence)) { throw 'BLOCKED_OUTPUT_ROOT_EXISTS' }
    if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw 'BLOCKED_SOURCE_MISSING' }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne '6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58') { throw 'HARD_STOP_SOURCE_HASH_DRIFT' }
    New-Item -ItemType Directory -Path $runtime,$evidence -ErrorAction Stop | Out-Null
    & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_PREPARE' }
    Write-Host 'PREPARE_COMMAND_EXIT=0'
}
~~~

O Prepare exige branch e script versionados, origem SHA correto, QlikView 12, 10 QVDs de extração, 12 de transformação e 3 QVWs canônicos. Cria **apenas** uma cópia chamada SAD_C2_R2_NATIVE_CLEAR_TX17_TEMP.qvw e manifesto JSON em EVIDENCE_DIR. **Registrar a saída RUNTIME_COPY e EVIDENCE_DIR e parar se houver erro.** Não repetir Prepare por tentativa.

## 3. Correção candidata exclusiva de TX17

Abrir a **nova RUNTIME_COPY**, nunca a origem. Conferir o Object ID TX17 e a expressão atual (mensagem mensal na condição F1 e texto genérico para outros contextos); se divergir, STOP. No editor do TX17 substituir somente o texto da expressão:

~~~qlik
=If(
    '$(vSAD_POC_Mode)'<>'EVOLUCAO',
    'CH03 indisponível: modo proposto diferente de EVOLUCAO.',
    If(
        GetSelectedCount(PERIODO_ANO)=0,
        'CH03 indisponível: nenhum ano real selecionado.',
        If(
            GetSelectedCount(PERIODO_ANO)>1,
            'CH03 indisponível: mais de um ano real selecionado.',
            If(
                GetSelectedCount(PERIODO_COMPETENCIA)>0,
                'Indisponível nesta evolução guiada — existe seleção mensal aplicada.',
                If(
                    Only(PERIODO_ANO)=Num($(vSAD_POC_Year)),
                    '',
                    'CH03 indisponível: o ano real difere do ano proposto.'
                )
            )
        )
    )
)
~~~

Exigir Expression OK, mas não classificar isso como PASS visual. Não ajustar fonte, cor, geometria, outras medidas ou condicionais. Não salvar ainda. A expressão é **candidata específica deste microgate**, não aprovada para P5 nem generalização de todas as rotas.

## 4. Uma única ação manual nativa

1. **Setup**: estabelecer estado REAL PERIODO_ANO=2018 (um selecionado explicitamente), PERIODO_COMPETENCIA sem seleção, SERV sem filtro e proposta EVOLUCAO/2018. Verificar em TX08 as seleções reais; CH03 deve mostrar 201801–201812 e total 183.311; CH02 histórico e cartões devem manter 183.532/183.311/188.246/555.089. Não repetir oráculo.
2. **Capturas antes do clique**, salvas diretamente em EVIDENCE_DIR: tx17_expression.png, before_native_clear_sh02.png (estado real e proposta), before_native_clear_sh03.png (cartões, CH02, CH03 e TX17).
3. Executar **uma vez** a opção nativa **Seleções → Limpar**. Não usar botão guiado nem repetir Limpar. Registrar ação no arquivo de notas.
4. **Após o clique**, TX08 deve evidenciar zero anos reais selecionados e zero competências selecionadas; proposta ainda EVOLUCAO/2018. Se variável proposta/seleção real não corresponder, STOP sem editar outros objetos.
5. Confirmar CH03 indisponível sem valor obsoleto; TX17 **CH03 indisponível: nenhum ano real selecionado.**; CH02 histórico preservado e cartões 183.532/183.311/188.246/555.089 se não houver outro filtro. Salvar after_native_clear_sh02.png e after_native_clear_sh03.png no EVIDENCE_DIR.
6. Se ocorrer valor enganoso, aviso genérico, seleção inesperada, gráfico ausente ou dano visual, **STOP sem Save**. Documentar a divergência; não alterar CH03 nem fazer segundo Limpar.
7. **Somente se o cenário passar:** Ctrl+S **uma única vez** na nova TEMP; fechar/reabrir a mesma cópia, sem Reload; inspecionar estado real efetivo após a abertura (não presumir seleção persistida), geometria, empilhamento e cartões em SH02/SH03. Capturar post_save_sh02.png e post_save_sh03.png no EVIDENCE_DIR; fechar sem segundo Save.
8. Registrar em gui_notes.txt o instante da ação nativa, seleções e proposta antes/depois, evidência de TX17/CH03/CH02/cartões, eventual Save (declaração do operador), resultado pós-reabertura, nomes/hashes das capturas e divergências. Não alegar prova independente da quantidade de Saves.

**Inventário exigido pelo runner:** 7 PNGs e gui_notes.txt. Não transferir screenshots de outra rodada como se fossem contemporâneos.

## 5. Verify de integridade

Somente com QlikView fechado, no mesmo Git HEAD. Substituir RunDir **pelo EVIDENCE_DIR exato impresso no Prepare**:

~~~powershell
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -RunDir '<EVIDENCE_DIR_DO_PREPARE>' -Verify
$exitCode = $LASTEXITCODE
Write-Host "VERIFY_EXIT_CODE=$exitCode"
if ($exitCode -ne 0) { throw 'BLOCKED_VERIFY' }
~~~

O runner emite c2_r2_native_clear_verify.json e confere a origem, os 25 protegidos, o SHA da nova TEMP e inventário de evidências. **PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI não é PASS funcional nem prova que apenas TX17 mudou.** Não repetir Verify se o JSON já existir.

## 6. PASS/BLOCKED/INCONCLUSIVE e STOP

- **PASS_VISUAL_RESTRICTED**: estado real antes/depois registrado, único Limpar atestado, CH03 sem série obsoleta, motivo correto TX17, CH02/cartões preservados, screenshots pós-save e hashes invariantes.
- **BLOCKED**: SHA de origem divergente, estado real não esperado, ação nativa não demonstrada, resultado inválido, motivo incorreto ou hash de qualquer protegido alterado.
- **INCONCLUSIVE**: screenshots/estado real insuficientes, persistência incerta ou captura nativa sem prova.
- **STOP**: uma preparação, um Limpar e um Verify; sem reabrir F1/F2, TX16, oráculos, multi-ano ou outros indicadores automaticamente. Nenhum merge, C3/C4, Fase IX ou produção.

C2_GUIDED_R2=PARTIALLY_TESTED_NOT_APPROVED_GLOBAL. READY_FOR_C3=NO. PRODUCTION_APPROVED=False.
