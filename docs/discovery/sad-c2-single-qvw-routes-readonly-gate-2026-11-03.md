# SAD — C2 single-QVW: inventário de rotas temporais em modo READ-ONLY

**Gate:** `SAD-C2-SINGLE-QVW-ACCESSIBLE-ROUTES-READONLY-01`  
**Baseline:** `main@59dc80a4db24f8ada257e9354e464f3393bfcab6` (PR #209 integrado).  
**Estado inicial:** preflight local reportado em 03/11/2026: `PREFLIGHT_QVW=PASS_READ_ONLY`, fonte QVW SHA-256 `A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517`, QlikView `12.0.20000.0`.  
**Artefato de código:** [`Invoke-SadC2SingleQvwRoutesReadonly01.ps1`](../../tools/Invoke-SadC2SingleQvwRoutesReadonly01.ps1) — **versão do branch do PR, não integrada à main** até decisão específica.

## Objetivo, escopo e evidência

Inventariar na **mesma QVW TEMP salva pelo PR #208** os caminhos efetivamente acessíveis para alteração de `PERIODO_ANO` e `PERIODO_COMPETENCIA`, sem selecionar valores. Incluir objetos BU15/BU16, listas, gráficos/tabelas, menus nativos, busca, bookmarks e eventuais triggers/macros, cada um marcado como observado, ausente com evidência, ou desconhecido.

O runner **não** abre QlikView, COM, GUI, nem aciona seleção, `Reload`, `Save` ou `Store`; apenas cria cópia imutável com manifesto fora do repositório e oferece `-Mode Verify` para conferir hashes do arquivo de origem, cópia e 25 protegidos (22 QVD + 3 QVW). **Não é um runner de inventário automático de objetos**; não confundir preparo com PASS do gate. O executor C2-F anterior pinava **outra** QVW/branch/hash e não deve ser adaptado silenciosamente.

**Condição de entrada:** Windows PowerShell 5.1, QlikView Desktop 12 no caminho padrão, branch/HEAD do PR versionado e worktree limpa, Qlik fechado, QVW fonte presente no caminho verificado, 25 canônicos presentes e nenhum hash alterado. Worktree suja, versão Qlik divergente, hash divergente ou arquivos ausentes: STOP sem correção automática.

## 1. Preflight de código e execução local

Na raiz do clone, antes de trocar branch, conferir `git status --porcelain --untracked-files=all`: **se houver saída, parar; não usar reset/clean/force**. Buscar branch remota deste PR e fazer checkout não destrutivo. Confirmar o HEAD e que `tools/Invoke-SadC2SingleQvwRoutesReadonly01.ps1` está efetivamente versionado no HEAD. Validar o parser PowerShell 5.1 antes de executar; qualquer erro de parser: STOP.

Fonte absoluta **confirmada pelo operador** (não reconstruída por inferência):
```text
C:\Users\pedro\Documents\SAD_C2_PREDISPATCH_RUNTIME\SAD_C2_PREDISPATCH_d6f8664aac094bbe9e13a85ca79367c4\SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw
```

Exemplo `-Mode Prepare` (substituir Root se necessário):
```powershell
$repo=(Get-Location).Path
$source='C:\Users\pedro\Documents\SAD_C2_PREDISPATCH_RUNTIME\SAD_C2_PREDISPATCH_d6f8664aac094bbe9e13a85ca79367c4\SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw'
$runner=Join-Path $repo 'tools\Invoke-SadC2SingleQvwRoutesReadonly01.ps1'
powershell.exe -NoProfile -File $runner -Root $repo -Mode Prepare -SourceQvw $source
```

**Aceite exclusivo do preparo:** `SOURCE_UNCHANGED=True`, `PROTECTED_25_UNCHANGED=True`, `VERDICT=PASS_COPY_AND_INTEGRITY_ONLY_NOT_ROUTE_INVENTORY`. Anotar exatamente `RUNTIME_COPY`, `MANIFEST`, `GIT_HEAD` e `RUNNER_SHA256` impressos; se falha, STOP, não reexecutar automaticamente.

## 2. Inventário humano da cópia

Abrir **apenas `RUNTIME_COPY`**, nunca QVW origem, no QlikView Desktop 12. Não usar cliques em valores, botões, seleções, bookmarks, busca que selecione, menus de limpar/desbloquear/restaurar, ou automação COM. Abertura de janela de Propriedades é permitida para leitura, fechando sempre por **Cancelar**; **não salvar** ao sair. 

Inspecionar: Propriedades do Documento → Folhas e Triggers; Propriedades da Folha → Objetos; BU15/BU16 — condições e ações `Select in Field`; campos ano/competência em List/Multi Box; gráficos/tabelas com seleção temporal; `Current Selections`; menus/atalhos de Seleções; presença/conteúdo de bookmarks e busca **somente por inventário de interface/propriedades sem acioná-los**. Objeto/ação não inspecionável = `UNKNOWN`; não afirmar que não existe apenas porque não aparece.

| Rota | Objeto/folha, configuração e captura | Estado da rota na QVW #208 | Controle D2 |
|---|---|---|---|
| BU15 e BU16 | Object ID, campo, expressão, condição, ação | `EXISTS/ACCESSIBLE/UNKNOWN` | `CONTROLLED_WITH_EVIDENCE/ACCESSIBLE_NOT_PROVEN_CONTROLLED/UNKNOWN` |
| List/Multi Box temporal | ID, campo, Read Only, search | igual | igual |
| Gráficos e tabelas | dimensão/seleção temporal possível | igual | igual |
| Menus/atalhos Seleções | presença real, ações disponíveis | igual | igual |
| Busca e bookmarks | existência e configuração, sem ativar | igual | igual |
| Triggers e macros | configuração efetivamente inventariada | igual | igual |

A prova de configuração ou de menu visível **não demonstra contenção preventiva D2**. Não promover `CONTROLLED_WITH_EVIDENCE` sem evidência do mecanismo de prevenção. Não extrapolar da QVW TEMP #208 ao futuro `PAINEL.qvw` com os três painéis, ainda inexistentes.

## 3. Verificação posterior (somente depois de fechar QlikView)

Em **mesma revisão do runner e mesmo checkout**, executar:

```powershell
$runner=Join-Path (Get-Location).Path 'tools\Invoke-SadC2SingleQvwRoutesReadonly01.ps1'
powershell.exe -NoProfile -File $runner -Root (Get-Location).Path -Mode Verify -ManifestPath '<MANIFEST_IMPRESSO_NO_PREPARE>'
```

Resultado aceitável: `VERDICT=PASS_HASH_INTEGRITY_ONLY_NOT_UI_ROUTES`. Se a cópia mudar: `BLOCKED_INSPECTION_COPY_CHANGED`; se QVW origem ou qualquer protegido mudar: HARD STOP e preservar prova, sem retentar.

## Veredito e STOP

- `PASS_READONLY_BOUNDED` do inventário **apenas** se matriz respaldada por inspeção efetiva da QVW correta, identidade e integridade mantidas.
- `INCONCLUSIVE` para rota não acessível/propriedade oculta; `BLOCKED` para ausência de fonte, permissões ou hash divergente.
- `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED` e `PRODUCTION_APPROVED=False` preservados em todos os casos.

**STOP:** uma rodada com matriz compacta na Issue #196; nenhuma PoC, QVW física dos três painéis, mudança de semântica, merge, execução adicional ou criação de novos runners em sequência. Seguir o Boundary 7: C2 → C3 → C4 → GO IX → painéis.
