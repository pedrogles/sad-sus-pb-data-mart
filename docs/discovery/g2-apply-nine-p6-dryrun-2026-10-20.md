# G2-APPLY — Dry-run de nove QVWs P6 E13 (SEM exclusão)

**Data:** 20/10/2026. **Estado:** G2_APPLY_DRYRUN_SCRIPT_VERSIONED_NOT_EXECUTED.  
**main consultada:** e4fdba706a2e22420e9c52d3ea62280461291734.  
**Provas de origem:** G2 + G2-H (relatórios privados fornecidos pelo responsável), PR #131 Draft e PR #83 histórico.
**Executor:** tools/Invoke-SadG2ApplyNineP6Dryrun.ps1, commit ba4cdf65caff87bab5b4ff1f833e9bc0a803b1ce, Git blob 78582317b193f216e08bf41739db6e50bc69e095.

## Escopo autorizado

O responsável autorizou preparar **somente** o dry-run com verificações de integridade e plano de reversão exclusivamente para nove QVWs. Nenhuma autorização foi dada para excluir, renomear, mover, copiar para backup, restaurar, alterar worktrees ou abrir o QlikView. O script **não contém** modo APPLY.

**Nove candidatos nominais (pastas do primeiro nível de %TEMP%; dentro de cada uma, arquivo P6_E13_DISPOSABLE.qvw):**

1. SAD_P6_E13_COM_236f13c6364a4efab1d73f5b4817022e
2. SAD_P6_E13_COM_23a408983dde4074921fe1f0279d6a74
3. SAD_P6_E13_COM_3d98811e808d4fddaf703573d9aba70e
4. SAD_P6_E13_COM_a27cb0583df444f6aa49da9b36c78827
5. SAD_P6_E13_COM_a4478dcfd1134998acd9f02c35aa9d08
6. SAD_P6_E13_COM_cf9a00663fa240ef888f68fd6926cc59
7. SAD_P6_E13_COM_d3d0060b3f9542598d61567cb89b4395
8. SAD_P6_E13_COM_da1fa322ccd04b1ca807e16bc5748d45
9. SAD_P6_E13_COM_dac7d57791524a44a49bde1e32a63f19

**Exemplar retido obrigatório:** SAD_P6_E13_COM_2263693f848c4d24a4ac287f28d2b849 / P6_E13_DISPOSABLE.qvw. Hash SHA-256 comum dos dez P6: F75786A88E7563B739492F2D2BC7C5CEA50D8C7F8E73F36770AA76960FB668C6. Nove candidatos somam **77.485.824 bytes**, estimativa nominal antes de qualquer remoção e não espaço garantido.

Preservar todos os demais TEMP, QVWs F4/P5, sidecars, 22 QVDs, 3 QVWs canônicos, BASE, oráculos, worktrees, documentação, evidências, B1 bundle e backups.

## Verificações e condição de parada

- Confirmar raízes REPO/TEMP/EVIDENCE diferentes e manifest G2-H original válido, com 14 QVWs e nenhum APPLY autorizado.
- Confirmar caminhos exatos, SHA-256 fresco e tamanho de cada um dos dez P6; conferir tamanho e timestamp estáveis durante o hashing.
- STOP em Qv.exe aberto, reparse point, worktree Git relacionado, pasta candidata com qualquer arquivo ou diretório adicional, SHA divergente, arquivo faltante ou nome não listado.
- RecoveryCopyPath é um parâmetro opcional de **leitura/verificação de cópia já existente** e privada, fora do REPO/TEMP. Se omitido, BACKUP_NOT_SUPPLIED e o futuro APPLY fica **bloqueado**. O script nunca cria a cópia.
- Saídas são exclusivamente nova subpasta privada sob EvidenceRoot: manifest.json, preflight_10_qvws.csv e rollback_plan.csv. O plano de rollback lista os nove destinos originais e deixa a fonte de recuperação como pendente quando não há cópia previamente validada.
- O script não resolve vínculos dinâmicos/externos e não confirma liberação física de espaço. Nenhuma aprovação de descarte decorre de hashes iguais.
- **STOP após uma execução.** Sem repetir G2/G2-H, fazer backup, merge ou qualquer exclusão automaticamente.

## Roteamento operacional

Agente primário: ChatGPT GPT-6 + GitHub, preparando o código e revisão estática; execução posterior por operador Windows PowerShell 5.1 enquanto Codex Local estiver indisponível. Esforço de raciocínio da sessão não é inferido. Ambiente Windows e QlikView não acessados nesta preparação. Fontes: main, AGENTS, current-state, requirements, artifact-recovery-policy, G2-H, G2 histórico.

PASS da preparação: script/contrato versionados e PR Draft, sem alteração da main e sem operações destrutivas. PASS local máximo: G2_APPLY_DRYRUN_VERIFIED_NO_DELETION_APPROVAL; não corresponde a G2_APPLY_READY nem G2_APPLY_VERIFIED. FALHA: bloqueio e preservação dos arquivos; enviar a primeira causa. Fase VIII/IX e aprovação de produção inalteradas.

## Comando futuro Windows — somente dry-run

A execução lê o G2-H original e grava relatórios em pasta persistente existente. Não exige checkout de branch e deve usar o commit exato versionado:

~~~powershell
& {
    $ErrorActionPreference = 'Stop'
    $repo = Join-Path $HOME 'Documents\programming\sad-sus-pb-data-mart'
    $evidence = Join-Path $HOME 'Documents\SAD_G2_EVIDENCE'
    $g2h = Join-Path $evidence 'G2_H_HASH_20261020_134701_8e30c72f1cce40879f2c0f571147012a'
    $runner = Join-Path $evidence 'Invoke-SadG2ApplyNineP6Dryrun.ps1'

    if (-not (Test-Path -LiteralPath (Join-Path $g2h 'qvw_hashes.csv') -PathType Leaf)) {
        throw 'STOP: evidências G2-H ausentes.'
    }
    if (Test-Path -LiteralPath $runner) {
        throw 'STOP: arquivo do runner já existe; não sobrescrever.'
    }
    $url = 'https://raw.githubusercontent.com/pedrogles/sad-sus-pb-data-mart/ba4cdf65caff87bab5b4ff1f833e9bc0a803b1ce/tools/Invoke-SadG2ApplyNineP6Dryrun.ps1'
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $runner
    $expected = '78582317b193f216e08bf41739db6e50bc69e095'
    $actual = (& git -C $repo hash-object -- $runner).Trim()
    if ($LASTEXITCODE -ne 0 -or $actual -ne $expected) {
        throw 'STOP: versão do script diverge do commit Git.'
    }
    'SCRIPT_INTEGRITY=PASS'
    $tokens = $null
    $parserErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($runner, [ref]$tokens, [ref]$parserErrors) | Out-Null
    if ($parserErrors.Count -gt 0) {
        $parserErrors | Format-List
        throw 'STOP: parser PowerShell não passou.'
    }
    'PARSER=PASS'

    & powershell.exe -NoProfile -File $runner -RepoRoot $repo -TempRoot $env:TEMP -G2HEvidenceDir $g2h -EvidenceRoot $evidence
    if ($LASTEXITCODE -ne 0) { throw "STOP: dry-run falhou com código $LASTEXITCODE" }
}
~~~

**Resultado:** VERDICT=G2_APPLY_DRYRUN_VERIFIED_NO_DELETION_APPROVAL, CANDIDATES_VERIFIED=9 RETAINED_VERIFIED=1 e BACKUP_STATUS=BACKUP_NOT_SUPPLIED se a cópia não existir. Não executar APPLY. Os relatórios locais permanecem fora do GitHub. Compartilhar apenas stdout e três saídas da nova pasta privada.

**Próxima decisão independente:** autorizar ou não uma cópia de recuperação efetiva; depois de validar sua integridade e dependências, discutir autorização específica para os nove arquivos. Nenhum merge ou exclusão implícitos.
