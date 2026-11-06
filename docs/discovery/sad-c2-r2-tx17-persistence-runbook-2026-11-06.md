# SAD C2-R2 — Persistência isolada de TX17 (sem novo Limpar)

**Gate:** \`SAD-C2-R2-TX17-PERSISTENCE-01\`
**Data:** 06/11/2026
**Estado:** PREPARED / WINDOWS_NOT_RUN
**Contrato:** D2-R2/V3 integrado; \`main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83\`; Issue #196; PR #223 e PR #224 permanecem Draft.
**Agente primário:** GPT-6 para especificação e revisão estática; execução no Windows PowerShell 5.1/QlikView 12.0.20000.0 pelo operador. Fallback: execução manual documentada. Não existe acesso remoto ao QlikView neste fluxo.

## 1. Motivo e evidência herdada

No PR #224, Prepare criou cópia com SHA-256 \`6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58\`. Capturas de chat pré/pós-\`Seleções → Limpar\` mostram CH03 indisponível, TX17 com causa específica e histórico/cartões preservados. Entretanto, na retomada o arquivo TEMP tinha **o mesmo SHA-256 da origem** e QlikView estava fechado. Não há evidência de persistência da edição; nenhum \`c2_r2_native_clear_verify.json\` foi produzido. Estado do microgate anterior: \`INCONCLUSIVE_NOT_PERSISTED\`, sem apagar o \`PASS_VISUAL_RESTRICTED\` anterior. [Issue #196 — diagnóstico](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6687026502).

**O que é novo:** testar somente a **persistência do texto de TX17** numa nova TEMP. **Não repetir** \`Limpar\`, F1/F2, canário TX16, oráculos, ações de seleção nativas, nem Verify do PR #224. O pacote de imagens anterior fica como evidência histórica, não pode ser reutilizado para simular uma nova captura.

## 2. Fonte, escopo tocável e invariantes

Fonte imutável: \`C:\Users\pedro\Documents\SAD_C2_FINAL_RUNTIME_20261105\SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321\SAD_C2_R2_FINAL_CONSOLIDATION_TEMP.qvw\` (SHA-256 **obrigatório** \`6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58\`).

Escopo: criar uma cópia isolada \`SAD_C2_R2_TX17_PERSISTENCE_TEMP.qvw\`; editar **somente** a expressão de texto de TX17; **um** Save manual; fechar/reabrir; conferir texto salvo; capturar três PNGs e registrar notas; Verify único do runner versionado.

Não editar CH02/CH03, cartões TX10–TX13, rótulos, coordenadas, filtros, botões, variáveis, dados ou modelo. Sem Reload, Clear, seleções, COM, automação da GUI, outras folhas além da inspeção, ou QVW/QVD canônicos. Proteção dos 10 QVDs de extração, 12 de transformação e 3 QVWs canônicos, mais origem. **Nenhum merge ou mudança na main.**

## 3. Prepare — uma execução somente

Com QlikView totalmente fechado e worktree limpa, a partir da raiz do repositório no Windows:

~~~powershell
& {
    $ErrorActionPreference='Stop'
    $branch='test/sad-c2-r2-tx17-persistence-20261106'
    if (@(git status --porcelain --untracked-files=all).Count -ne 0) { throw 'BLOCKED_DIRTY_WORKTREE' }
    git fetch origin main $branch
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_FETCH' }
    git switch --track "origin/$branch"
    if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_SWITCH' }

    $repo=(git rev-parse --show-toplevel).Trim()
    $runner=Join-Path $repo 'tools\Invoke-SadC2R2TX17Persistence01.ps1'
    $tokens=$null; $errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
    if (@($errors).Count -ne 0) { $errors; throw 'BLOCKED_PARSER' }
    if (@(git status --porcelain --untracked-files=all).Count -ne 0) { throw 'BLOCKED_DIRTY_WORKTREE' }

    $source=Join-Path $env:USERPROFILE 'Documents\SAD_C2_FINAL_RUNTIME_20261105\SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321\SAD_C2_R2_FINAL_CONSOLIDATION_TEMP.qvw'
    $qvExe='C:\Program Files\QlikView\Qv.exe'
    $runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2_TX17_PERSIST_RUNTIME_20261106'
    $evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2_TX17_PERSIST_EVIDENCE_20261106'

    if ((Test-Path -LiteralPath $runtime) -or (Test-Path -LiteralPath $evidence)) { throw 'BLOCKED_OUTPUT_ROOT_EXISTS' }
    if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw 'BLOCKED_SOURCE_MISSING' }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne '6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58') { throw 'BLOCKED_SOURCE_HASH_DRIFT' }
    New-Item -ItemType Directory -Path $runtime,$evidence -ErrorAction Stop | Out-Null

    & powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
    $exit=$LASTEXITCODE
    Write-Host "PREPARE_EXIT_CODE=$exit"
    if ($exit -ne 0) { throw 'BLOCKED_PREPARE' }
}
~~~

**STOP após Prepare:** copiar stdout com \`GIT_HEAD\`, \`RUNNER_SHA256\`, \`RUNTIME_COPY\`, \`EVIDENCE_DIR\`, \`VERDICT\`. Não fazer mais nada caso bloqueie. A ausência do QlikView local impede execução pelo agente.

## 4. Edição e persistência manual — após Prepare validado

1. Abrir **somente** a nova \`RUNTIME_COPY\`, não a QVW de origem ou a TEMP #224.
2. Em SH03 localizar e confirmar **ID TX17**. Comparar texto atual com a versão salva do PR #223 (aviso quando há competência mensal; diagnóstico genérico para estados fora do F1/F2). Se divergir, **STOP**.
3. Alterar **somente o texto de TX17** para a expressão candidata já inspecionada visualmente no PR #224:

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

4. Confirmar \`Expression OK\` e **capturar diretamente na nova EVIDENCE_DIR** o arquivo \`tx17_before_save.png\`, exibindo ID e expressão.
5. Aplicar no objeto, **Ctrl+S exatamente uma vez** na nova TEMP. Se aparecer \`Salvar como\`, caminho inesperado, erro ou confirmação de substituição de outra QVW, **CANCELAR e STOP**. Fechar o QlikView, sem Reload.
6. Reabrir a **mesma nova TEMP**, inspecionar novamente propriedades de TX17, conferir a expressão acima **sem editá-la**, capturar \`tx17_after_reopen.png\`. Fechar editor sem aplicar mudanças; capturar \`sh03_after_reopen.png\` (apresentação efetivamente visível; não presumir que seleções são mantidas entre sessões). Fechar QlikView **sem segundo Save**.
7. Criar \`gui_notes.txt\` na EVIDENCE_DIR, identificando caminhos, antes/depois, confirmação humana de Save, estado real efetivamente visto após reabertura, horário aproximado, nomes das 3 capturas e anomalias. Evidências precisam ser contemporâneas desta nova TEMP; nunca copiar capturas do PR #224 para esta rodada.

**Não executar Clear** para forçar uma mensagem visual. A verificação aqui é de persistência da expressão em TX17; o comportamento funcional pós-Limpar já possui evidência visual **restrita** da rodada passada, mas não deve ser herdado como teste pós-save desta nova cópia.

## 5. Verify — somente com QlikView fechado

Usar o \`EVIDENCE_DIR\` **exato** impresso pelo Prepare e o mesmo HEAD. No PowerShell, se as variáveis acima não persistiram, reconstituí-las conforme etapa 3, sem executar Prepare novamente.

~~~powershell
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -RunDir '<EVIDENCE_DIR_EXATO_DO_PREPARE>' -Verify
$exitCode=$LASTEXITCODE
Write-Host "VERIFY_EXIT_CODE=$exitCode"
if ($exitCode -ne 0) { throw 'BLOCKED_VERIFY' }
~~~

**Esta revisão do runner torna bloqueantes**: \`COPY_CHANGED_FROM_SOURCE=False\` (ausência de mudança de bytes), origem ou qualquer dos 25 protegidos modificados, e inventário incompleto/arquivo vazio/data anterior ao Prepare. A existência dos arquivos não certifica a qualidade ou momento exato das capturas; o runner não valida semanticamente o objeto TX17 nem prova que somente ele mudou. Verify executado **uma vez**, sem repetir em caso de erro. Revisão manual posterior pode qualificar o resultado.

## 6. Critérios, conclusão e STOP

- **PASS_RESTRICTED_PERSISTENCE_EVIDENCE** exige Verify íntegro + cópia com SHA diferente + capturas genuínas de TX17 antes e depois do Save/reabertura mostrando expressão igual. Sem outras alterações visíveis esperadas, mas identidade de todos os demais objetos **não comprovada** por este gate.
- **BLOCKED** se hash da origem/protegidos mudar, sem Save válido, cópia byte-identical, TX17 divergente após reabrir ou screenshot essencial ausente.
- **INCONCLUSIVE** se alguma informação depender apenas de memória, sem inspeção de expressão pós-reabertura ou com proveniência insuficiente.
- **STOP** depois de um Prepare, um Save, uma reabertura e um Verify. PR #224 continua histórico; não promover \`POST_CLEAR_VISUAL\` anterior a PASS físico global, nem abrir outra PoC automática.

\`C2_GUIDED_R2=PARTIALLY_TESTED_NOT_APPROVED_GLOBAL\` · \`READY_FOR_C3=NO\` · \`PHASE_IX=NOT_AUTHORIZED\` · \`PRODUCTION_APPROVED=False\`.
