# Fase VIII — C2-F | Inventário físico READ-ONLY das rotas de seleção

**Data da preparação:** 21/10/2026. **Baseline:** \`main@9dbdef8e3f20b076cc1a07d0c273a981b3ac45e1\`.  
**Autorização:** responsável autorizou iniciar o C2-F após o C2-E. **Estado atual:** \`C2F_PREPARATION=VERSIONED_NOT_EXECUTED_WINDOWS\`, \`C2F_PHYSICAL_INVENTORY=NOT_RUN\`. Sem PASS físico até evidência local real.

## 1. Objetivo, fonte, limites e STOP

Identificar, em **uma** cópia descartável do QVW experimental C2-D1, as rotas de seleção realmente expostas no QlikView 12: objetos de lista de ano/competência, botões BU01/BU02, suas ações e condições, outros objetos de seleção, buscas, bookmarks e triggers. Diferenciar PRESENT, NOT_FOUND_IN_SCOPE e UNKNOWN sem interpretar ausência de identificador UIA/Win32 como ausência de objeto. **Não clicar para selecionar, disparar bookmark, executar ação, avaliar novos KPI, recarregar ou salvar QVW.** Navegação de menus e janelas de propriedades é permitida somente para leitura; sair por Cancelar.

Fonte de verdade lida: AGENTS → current-state → requirements → Boundary 7 → C2-E → C2 closeout → C2-D/D3 → automação QlikView; material histórico do PR #122 em sua branch preservada. QlikView 12 e a semântica V2 §62 permanecem obrigatórios. Não iniciar C3/C4, Fase IX ou alterar 3 fatos/8 dimensões.

**Níveis:** preparação local não é inventário físico. Inspeção humana de propriedades/PNG não equivale a interceptação comprovada de todas as seleções. Os testes C2-D1 (D2-1 e D2-3 pares pré/pós; D2-2/D2-4 imagem única mais relato) e o NO-GO da sonda C2-D3 ficam preservados, sem reexecução.

## 2. Insumos concretos da estação Windows

- **QVW de origem comprovado historicamente:** \`%TEMP%\SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw\`.
- **Hash SHA-256 da origem no C2-D3:** \`31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087\`.
- **Script novo versionado antes de qualquer execução Windows:** \`tools/Prepare-SadPhaseViiiC2fReadonlyRoutes.ps1\`; a versão exata executada será identificada por \`VERSIONED_GIT_HEAD\` e \`RUNNER_SHA256\`.
- O arquivo deve ser encontrado **pelo caminho e hash**, não reconstruído por recarga ou por cópia aleatória. Hash diferente ou origem ausente = STOP e coleta de informação, sem ignorar o pin.
- **Proteção:** os 22 QVDs locais e \`EXTRACAO/EXT.qvw\`, \`TRANSFORMACAO/TRANSF.qvw\`, \`PAINEL/PAINEL.qvw\` são hashados antes/depois. O script só cria cópia em novo \`%TEMP%\SAD_VIII_C2F_<GUID>\` e manifesto em diretório persistente \`EVIDENCE_ROOT\` fora do Git.
- A cópia temporária se destina a inspeção humana; não é arquivo canônico, não altera dados/fatos nem contrato da Link Table.

## 3. Roteamento operacional

- **Agente primário:** Codex Local no Windows autorizado, para versão, parser e preflight; **fallback:** responsável em PowerShell 5.1 e QlikView Desktop 12; ChatGPT revisa os arquivos exportados.
- **Modelo/esforço local:** não observado nesta sessão; registrar o nome e esforço efetivamente selecionados no Codex se usado. Aqui, ChatGPT GPT-6 e GitHub para revisão/commit.
- **Ambiente acessível nesta preparação:** GitHub e sistema Linux de auditoria; **sem acesso ao computador Windows/QlikView do responsável**. Não declarar \`PARSER=PASS\` ou resultado COM local sem retorno do executor.
- **Permissões:** documentar/versionar preparo; executar no Windows somente em cópia, sem COM nem seleções via script; criar manifesto e PNGs fora do Git.
- **Proibidos:** \`git clean\`, \`reset --hard\`, checkout com descarte de mudanças, sobrescrita QVD/QVW, recarga, SAVE, UIA/Win32 reexploratório, clique por coordenadas, merge automático.
- **Orçamento:** um preflight e uma preparação/cópia; uma revisão humana controlada de menus/objetos. Primeira falha = STOP.
- **Saídas:** stdout, manifesto JSON e capturas das propriedades; eventual \`COM_ONLY_NOT_UI_CLICK\` é **novo subescopo**, não implementado neste runner.
- **PASS limitado:** origem pinada, 22 QVDs/3 QVWs antes-depois preservados, cópia íntegra, manifesto e objeto(s) observados com evidência.
- **BLOCKED:** SHA divergente, QVW ausente, gate sem ambiente, parser falhou, escrita em artefato protegido.
- **INCONCLUSIVE:** UI não abre, propriedades inacessíveis, ausência de captura, superfície não enumerável.
- **STOP:** evidência do inventário produzida ou primeiro bloqueio; não extrapolar a \`P5_D2_UI=APPROVED\`.

## 4. Procedimento local — Codex/PowerShell

Na raiz do clone Windows, sem apagar QVW/QVD ou arquivos não rastreados:

\`\`\`powershell
git fetch origin
git status --short
git switch --track origin/test/phase-viii-c2f-readonly-route-inventory-20261021
git pull --ff-only

$script = (Resolve-Path .\tools\Prepare-SadPhaseViiiC2fReadonlyRoutes.ps1).Path
$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $script, [ref]$tokens, [ref]$errors
)
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { $_.ToString() }
    throw "PARSER=BLOCKED"
}
"PARSER=PASS"

$source = Join-Path $env:TEMP "SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw"
$evidenceRoot = Join-Path $env:USERPROFILE "Documents\SAD_C2F_EVIDENCIAS"

powershell.exe -NoProfile -File $script -Root (Get-Location).Path -SourceQvw $source -EvidenceRoot $evidenceRoot -Prepare
\`\`\`

**Segurança:** se a branch local já existir, usar \`git switch test/phase-viii-c2f-readonly-route-inventory-20261021\` em vez de \`--track\`; confirmar \`git status\` e parar diante de colisões, sem usar limpeza forçada. Não imprimir \`PARSER=PASS\` depois de uma falha. Não alterar o script local para contornar hash ou checagem.

**Uma execução bem-sucedida retorna** \`VERDICT=PASS_LOCAL_PREPARATION_ONLY_NOT_C2F_PHYSICAL_INVENTORY\`, \`RUNTIME_TEMP_COPY\` e \`EVIDENCE_ROOT\`; **não significa que o C2-F tenha PASS**.

## 5. Roteiro de inspeção visual sem modificar o estado de seleção

Abrir **somente** \`RUNTIME_TEMP_COPY\` no QlikView Desktop 12, sem recarga/salvamento. No menu, acessar **Propriedades do Documento → Folhas** (lista de folhas/objetos) e **Propriedades da Folha → Objetos**. Para cada folha, capturar a lista de IDs, tipos, títulos e condição de exibição, inclusive objetos ocultos quando listados. Em seguida, apenas **inspecionar propriedades** (fechar com Cancelar) de:
1. \`BU01\` e \`BU02\`: condição para habilitar, ações/Select in Field, campo de destino e possível condição de exibição;
2. listboxes/multiboxes de \`PERIODO_ANO\` e \`PERIODO_COMPETENCIA\`: ID, campo, \`Read Only\`, busca e visibilidade;
3. outros objetos/botões que possam selecionar, limpar, restaurar ou trocar contexto temporal;
4. **Propriedades do Documento → Triggers** e menus de bookmarks/busca: documentar apenas sua presença/configuração; **não executar** bookmarks ou pesquisas que alterem seleção.

Registrar imagens com janela e contexto visíveis no \`EVIDENCE_ROOT\`. Um clique apenas para abrir uma janela de **propriedades** é navegação, não a ação de seleção que este gate proíbe. Se o QVW apresentar macro de abertura, diálogo incerto, asterisco de alteração não esperada ou ação involuntária, fechar a cópia sem salvar, registrar \`INCONCLUSIVE\` e STOP.

| Rota | Valor a registrar |
| --- | --- |
| Folha/objeto | \`SheetID\`, \`ObjectID\`, tipo/título, visível/oculto |
| BU01/BU02 | campo selecionado, condição de habilitação, ações configuradas |
| Listas ano/competência | presente/ausente no escopo, \`Read Only\`, busca, outros pontos de entrada |
| Bookmarks e busca | existe, acesso efetivamente exposto, nenhuma ação disparada |
| Triggers e ações alternativas | nome/tipo/configuração observável, sem inferir execução |
| Resultados não inventariáveis | \`UNKNOWN\` e motivo, sem substituir por \`ABSENT\` |

## 6. Critério de aceite e encerramento

O pacote de prova física só poderá ser classificado \`C2F_ROUTE_INVENTORY=PASS_READONLY_BOUNDED\` após conferência do stdout, SHA e screenshots/propriedades correspondentes às rotas **efetivamente vistas**. Caso não haja cobertura de todos os pontos da interface, concluir \`COMPLETED_WITH_UNKNOWN_ROUTES\` e propor decisão mínima, não executar sondagens adicionais neste gate.

**Estados inalterados independentemente do preparo:** \`C2_FULL=NO_GO_NOT_APPROVED\`, \`P5_D2_UI=NOT_TESTED\`, \`F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY\`, \`LINK_KEY_CONTRACT=NOT_APPROVED\`, \`MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED\`, \`CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED\`, \`T29_HISTORICAL=NOT_APPROVED\`, \`PHASE_IX=NOT_AUTHORIZED\`, \`PRODUCTION_APPROVED=False\`. **A integração desta branch/PR exige revisão separada após o resultado físico.**
