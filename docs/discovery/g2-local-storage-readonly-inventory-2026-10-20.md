# G2 — Auditoria local de armazenamento (somente leitura)

**Data:** 20/10/2026.
**Estado:** G2_SCRIPT_VERSIONED_NOT_EXECUTED.
**Base da proposta:** main e4fdba706a2e22420e9c52d3ea62280461291734.
**Script versionado:** tools/Invoke-SadG2StorageReadonlyInventory.ps1, commit c28ecf7c40d23ee583d76b2fbb85722223e40d96, Git blob af0329a862c7255b142afc3383123d2f71f374da.

## Objetivo, fontes e fronteira

Obter, numa única execução Windows e sem excluir nada, um inventário de arquivos por tamanho, pasta, data e finalidade provável para orientar futura decisão de redução do armazenamento.

- REPO: caminho real fornecido pelo responsável sob Documents/programming/sad-sus-pb-data-mart; enumeração de arquivos excluindo metadados internos .git e sem atravessar symlinks/junctions.
- TEMP: enumeração restrita às entradas de primeiro nível de %TEMP% com prefixos SAD ou SUS-PB e seus descendentes, sem atravessar symlinks/junctions. Entradas com outros nomes não serão inspecionadas; esse limite deve constar do parecer.
- Git: leitura de HEAD, status com arquivos não rastreados e worktree list; GIT_OPTIONAL_LOCKS=0. Sem fetch, checkout, reset, prune, exclusão de branch ou alteração de ref.
- EVIDENCE_ROOT: pasta existente, privada, fora do REPO e do TEMP. Única área de escrita do executável: nova subpasta G2_INVENTORY_... com relatórios. Nunca fazer commit dos relatórios locais.
- Não há acesso ao QlikView Desktop, COM, Reload, Save, STORE, dados de origem ou QVW nesta tarefa.

## Preservação

PRESERVAR: BASE, 22 QVDs inventariados, QVWs canônicos EXT.qvw / TRANSF.qvw / PAINEL.qvw, F1/F2/F3, manifestos, oráculos, logs únicos, evidências VI–VIII, bundles Git/rollback, backups e arquivos com dependências não resolvidas. Preservar qualquer worktree registrado, inclusive TEMP, até revisão Git-aware separada. Os 25 binários de estabilização têm cópia local LOCAL_COPY_ONLY, não DISASTER_RECOVERY_VERIFIED; preservá-los.

REVIEW_TEMP_CANDIDATE_NOT_APPROVED significa apenas que o arquivo temporário pode ser avaliado mais tarde. O indicador ReviewTempBytesNotRecoverableEstimate é o total aparente de bytes em revisão, **não** economia comprovada. Não equiparar QVW TEMP a lixo nem ausência de rastreamento Git a redundância.

## Roteamento do gate

- Gate e STOP: G2, inventário dos dois alvos, encerrar em um manifesto/CSV; não iniciar limpeza no mesmo gate.
- Agente primário: operador Windows com PowerShell 5.1; ChatGPT + GitHub para revisão. Codex Local com limite atingido, sem requisito de seu uso.
- Modelo: GPT-6 no ChatGPT; esforço específico da sessão não confirmado.
- Ambiente: GitHub confirmado; Windows local não acessado; parser e execução reais NÃO executados nesta proposta.
- Permissões: leituras dos dois alvos e Git; escrita apenas em EVIDENCE_ROOT persistente.
- Orçamento: uma execução, máximo padrão de 200.000 arquivos, sem ampliar limite após falha sem revisão.
- PASS: parser real PASS, hash Git do runner igual ao publicado, manifesto G2_INVENTORY_READONLY_COMPLETE_SCOPE_LIMITED, zero erros de varredura.
- INCONCLUSIVE: varredura parcialmente inacessível, enumeração limitada, reparse points potencialmente relevantes, arquivos de prova incompletos.
- HARD_STOP: SHA divergente, pasta incorreta, EVIDENCE_ROOT sobreposto a REPO/TEMP, qualquer escrita nos alvos.
- RUNTIME_TEMP: fonte de inspeção parcial e somente leitura; EVIDENCE_ROOT: local persistente escolhido pelo operador.
- Handoff: compartilhar manifesto e CSVs privados; produzir lista precisa de exclusões e reversão somente depois de analisar dependências; autorização própria para eventual APPLY.

## Como executar no Windows sem Codex

O comando baixa a versão exata previamente commitada, confere seu Git blob e seu parser PowerShell 5.1, e só então executa a varredura. A pasta de evidências é criada pelo operador, não pelo runner fora dela.

~~~powershell
$repo = Join-Path $HOME 'Documents\programming\sad-sus-pb-data-mart'
$evidence = Join-Path $HOME 'Documents\SAD_G2_EVIDENCE'

# Diretório privado e persistente, fora do projeto e do TEMP
New-Item -ItemType Directory -Path $evidence -Force | Out-Null

$runner = Join-Path $evidence 'Invoke-SadG2StorageReadonlyInventory.ps1'
$url = 'https://raw.githubusercontent.com/pedrogles/sad-sus-pb-data-mart/c28ecf7c40d23ee583d76b2fbb85722223e40d96/tools/Invoke-SadG2StorageReadonlyInventory.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $runner

$actualBlob = (& git -C $repo hash-object -- $runner).Trim()
if ($LASTEXITCODE -ne 0 -or $actualBlob -ne 'af0329a862c7255b142afc3383123d2f71f374da') {
    throw 'STOP: arquivo local diferente do script versionado.'
}

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    $runner, [ref]$tokens, [ref]$parseErrors
) | Out-Null
if ($parseErrors.Count -gt 0) {
    $parseErrors | Format-List
    throw 'STOP: parser PowerShell 5.1 falhou.'
}
'PARSER=PASS'

powershell.exe -NoProfile -File $runner -RepoRoot $repo -TempRoot $env:TEMP -EvidenceRoot $evidence -MaxFiles 200000
~~~

Se o checkout estiver em outro caminho, corrigir somente a variável repo antes de executar. Não limpar/alterar worktrees para permitir a auditoria. Não repetir após um erro sem verificar a causa. A execução de um script em PR Draft versionado não implica merge do PR.

## Saídas privadas

Em nova subpasta de EVIDENCE_ROOT:
- manifest.json: data, raízes, HEAD, limites, veredito, número de arquivos e bytes em revisão (não comprovadamente removíveis).
- file_inventory.csv: caminho, bytes, data, classificação e motivo.
- directory_summary.csv: total por raiz e grupo.
- git_status.txt e git_worktrees.txt: estado de worktrees e refs locais.
- skipped_paths.csv e scan_errors.csv: exclusões explícitas e limitações.

Não enviar conteúdo bruto sensível para GitHub. Compartilhar resultados para a análise posterior, ocultando dados pessoais quando necessário. Em caso de arquivo não acessível, reportar INCONCLUSIVE em vez de afirmar varredura completa.

## Ações proibidas nesta etapa

Não usar Remove-Item, Move-Item, git clean, git worktree prune, reset --hard, exclusão de diretórios TEMP, exclusão de branches, limpeza de backups ou qualquer rerun QlikView/COM. Não alterar modelagem acadêmica, contratos de indicadores, Fase IX ou aprovação de produção.

**Veredito deste PR:** somente código e contrato documental preparados; G2_SCRIPT_VERSIONED_NOT_EXECUTED e PRODUCTION_APPROVED=False. A futura limpeza depende de novo plano delimitado e aprovação explícita por lote.
