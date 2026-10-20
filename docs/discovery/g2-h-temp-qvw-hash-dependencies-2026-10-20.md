# G2-H — SHA-256 e dependências indicativas de 14 QVWs no TEMP

**Data:** 20/10/2026. **Estado:** G2_H_VERSIONED_NOT_EXECUTED.  
**Base canônica:** main@e4fdba706a2e22420e9c52d3ea62280461291734.  
**Fonte privada:** G2_INVENTORY_20261020_131259_.../file_inventory.csv, manifest.json e relatório G2 de triagem. Nenhum arquivo local foi reaberto no Windows nesta preparação.  
**Runner:** tools/Invoke-SadG2HReadonlyQvwHashes.ps1 no commit 4e70fd6544eee484a591e09cf5190212dca8dfc7 (Git blob 4bb3b7bf9b04ce52746caf69dd39aedf0fe1c619).

## Objetivo contratual e condição de parada

**Objetivo único:** obter SHA-256 dos **14 QVWs exatos** priorizados no G2: dez pastas SAD_P6_E13_COM_* e quatro SAD_F4_P5_UI_GUARD_*. Não examinar outros QVWs, não repetir a enumeração do G2 e não realizar exclusões. O conjunto esperado soma **126.871.296 bytes** de QVWs, valor observado no CSV G2 (não economia liberável). Os acessórios das quatro pastas F4/P5 constam separadamente e devem continuar preservados.

O runner compara os caminhos, tamanhos e horários dos 14 arquivos à coleta do G2 (manifest e file_inventory originais em diretório persistente), confere roots e verifica se algum alvo pertence a worktree Git registrado. Se um alvo mudar, desaparecer, virar junction/reparse point ou pertencer a worktree, **STOP**.

O script deve rodar apenas com QlikView Desktop fechado; nenhuma instância Qv.exe, COM, recarga ou abertura de QVW faz parte do teste. Ele calcula hashes de arquivos, observa o estado da árvore de código (sem checkout) e faz busca por **referências literais** em arquivos pequenos de documentação/código de docs, tools, PAINEL, TRANSFORMACAO e EXTRACAO. Essa busca não identifica necessariamente dependências dinâmicas, referências externas ou outros worktrees. Ausência de ocorrências não é prova de descarte seguro.

## Permissões e invariantes

- **READ-ONLY:** RepoRoot, TempRoot, os 14 QVWs, os 21 arquivos acessórios F4/P5 do inventário G2, Git e CSV/manifesto G2 de origem.
- **Única escrita permitida:** criação de uma nova pasta G2_H_HASH_* sob EvidenceRoot **existente**, privado e persistente, fora de RepoRoot e TempRoot.
- **Preservar:** BASE, 22 QVDs, 3 QVWs canônicos, oráculos F1/F2/F3, evidências únicas, backups, bundles B1, 10 QVWs untracked de TRANSFORMACAO, origens T24/C2-W/C2-D1 e worktrees. Não copiar, mover, deletar ou salvar dados de origem.
- **Sem Git mutation:** nenhum fetch, checkout, branch delete, clean, reset, worktree prune, merge ou commit local. Não reabrir a investigação UIA/Win32.
- **Evidência:** G2-H produz qvw_hashes.csv, identical_sha_groups.csv, static_references.csv, static_scan_skipped.csv, f4_sidecars_preserve.csv, manifest.json.
- **Aceite candidato:** parser Windows PowerShell 5.1 PASS e execução sobre os 14 arquivos conforme o manifesto, com evidência persistida em EvidenceRoot.
- **Bloqueios:** erro no parser, arquivo alterado, origem inconsistente, Qv.exe aberto, worktree colidindo ou leitura falha => STOP/INCONCLUSIVE. Não modificar runner ou repetir automaticamente.
- **Resultado máximo:** G2_H_HASHES_COMPLETE_DEPENDENCIES_NOT_PROVEN. Mesmo hashes repetidos **não autorizam exclusões**; exige prova da preservação de evidências e recuperação + aprovação específica por caminho.
- **Modelos/ambientes:** ChatGPT GPT-6 com GitHub para revisão estática; operador Windows PowerShell 5.1 para execução física, dado o limite informado de Codex. QlikView, COM e GUI não aplicáveis. Esforço de modelo não selecionável nesta revisão; nenhuma capacidade Windows foi presumida.

## Execução pelo PowerShell no Windows — somente após revisar o PR

Pasta principal do projeto: Documents/programming/sad-sus-pb-data-mart. Pasta privada G2: Documents/SAD_G2_EVIDENCE. O script G2-H **não precisa de checkout de branch**, pois é baixado por SHA de commit imutável, com integridade conferida por Git blob.

~~~powershell
$ErrorActionPreference = 'Stop'
$repo = Join-Path $HOME 'Documents\programming\sad-sus-pb-data-mart'
$evidence = Join-Path $HOME 'Documents\SAD_G2_EVIDENCE'
$g2Folder = Join-Path $evidence 'G2_INVENTORY_20261020_131259_c6b3607f40f2460998f93e062d83b22f'
$g2Csv = Join-Path $g2Folder 'file_inventory.csv'
$runner = Join-Path $evidence 'Invoke-SadG2HReadonlyQvwHashes.ps1'

$url = 'https://raw.githubusercontent.com/pedrogles/sad-sus-pb-data-mart/4e70fd6544eee484a591e09cf5190212dca8dfc7/tools/Invoke-SadG2HReadonlyQvwHashes.ps1'
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $runner

$expected = '4bb3b7bf9b04ce52746caf69dd39aedf0fe1c619'
$actual = (& git -C $repo hash-object -- $runner).Trim()
if ($LASTEXITCODE -ne 0 -or $actual -ne $expected) {
    throw 'STOP: script diferente do blob Git versionado.'
}
'SCRIPT_INTEGRITY=PASS'

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    $runner, [ref]$tokens, [ref]$parseErrors
) | Out-Null
if ($parseErrors.Count -gt 0) {
    $parseErrors | Format-List
    throw 'STOP: parser Windows PowerShell falhou.'
}
'PARSER=PASS'

powershell.exe -NoProfile -File $runner -RepoRoot $repo -TempRoot $env:TEMP -G2InventoryCsv $g2Csv -EvidenceRoot $evidence
if ($LASTEXITCODE -ne 0) {
    throw "STOP: G2-H encerrou com exit code $LASTEXITCODE"
}
~~~

Não iniciar a limpeza do %TEMP% e não alterar worktrees para contornar bloqueio. Se a pasta G2 original não existir, declarar INCONCLUSIVE e **não** refazer automaticamente o G2 inteiro.

## Regras para revisão do resultado

1. **SHA igual**: identidade byte a byte para os arquivos lidos naquele instante; ainda não demonstra que há cópia independente, evidência substituta ou possibilidade de remoção.
2. **SHA diferente**: não há duplicação byte a byte, ainda que tamanho e timestamps coincidam.
3. **Referência literal encontrada**: indício de uso por script/documentação que requer exame contextual; não afirma dependência ativa.
4. **Nenhuma referência encontrada**: dependência dinâmica/externa/COM pode existir; não autoriza remoção.
5. **Sidecars F4/P5**: relatórios, PNGs, ZIPs e JSONs aparecem como PRESERVE_UNTIL_REVIEW; o runner não exclui nem move esses artefatos.

STOP no primeiro inventário bem-sucedido. Encerrar o gate G2-H e preparar, em outra autorização, uma **lista nominal** de candidatos, SHA, evidências de retenção, plano de reversão e estimativa condicional de recuperação. Sem merge automático; código e documentação em PR Draft não aprovam APPLY nem produção.
