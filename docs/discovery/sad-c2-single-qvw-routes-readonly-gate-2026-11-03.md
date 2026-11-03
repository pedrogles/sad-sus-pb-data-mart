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

## 4. Closeout da rodada física — 03/11/2026 (evidência restrita)

**Registro de prova:** capturas da QVW TEMP apresentadas e inspecionadas visualmente na conversa, com stdout Windows PowerShell 5.1 fornecido pelo operador. **Não foram disponibilizados os bytes do QVW nem do manifesto JSON para auditoria independente**; o hash é verificação local reportada, não inspeção binária do agente. Nenhum COM/reload/seleção ou runner adicional foi executado neste closeout documental.

### Identidade e integridade — mesma execução versionada

- Branch executado: `test/sad-c2-single-qvw-routes-readonly-20261103`.
- `GIT_HEAD=71d41a5771143d146e1c4eff808dccc2585cc464`.
- `RUNNER_SHA256=1D9F59FE9341F39CBF0333CB430A34CC1E6834638EAFEB19C01A790614441789`; parser reportado `PARSER=PASS`.
- QlikView Desktop reportado: `12.0.20000.0`.
- Fonte: `SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw` do #208, **SHA esperado/validado localmente** `A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517`.
- Cópia: `C:\Users\pedro\Documents\SAD_C2_ROUTE_INVENTORY_RUNTIME\SAD_C2_ROUTES_946423ca3eb84b1994426ff3fd9aea7b\SAD_C2_ROUTE_INVENTORY_COPY.qvw`.
- Manifesto: `C:\Users\pedro\Documents\SAD_C2_ROUTE_INVENTORY_EVIDENCE\SAD_C2_ROUTES_946423ca3eb84b1994426ff3fd9aea7b\c2_route_inventory_manifest.json`.
- `Prepare`: `SOURCE_UNCHANGED=True`; `PROTECTED_25_UNCHANGED=True`; `VERDICT=PASS_COPY_AND_INTEGRITY_ONLY_NOT_ROUTE_INVENTORY`.
- `Verify` **após inspeção e fechamento do QlikView sem salvar**: `COPY_SHA256=A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517`; `SOURCE_AND_PROTECTED_25_UNCHANGED=True`; `VERDICT=PASS_HASH_INTEGRITY_ONLY_NOT_UI_ROUTES`; `VERIFY_EXIT_CODE=0`. **Não converter esse PASS de integridade em PASS de UI.**

### Matriz de rotas — observação na cópia de inspeção

| Rota | Evidência da mesma QVW #208 (capturas ou relato explícito) | Status e limite para D2 |
|---|---|---|
| Folhas e objetos | Três folhas: `SH01 Principal` (13 objetos); `POC - Interface Guiada` (15); `POC P1.1-P1.2 - Internações` (7). A folha guiada inclui `BU15/BU16`, `IB01/MB01`; a analítica contém `CH02/CH03`. | `EXISTS_WITH_VISUAL_EVIDENCE`; **não é inventário automatizado nem prova de ausência de outras ações** |
| `LB01` | Lista associada a `PERIODO_ANO`, caixa `Apenas leitura` **marcada**, captura da aba Geral | `LOCAL_READ_ONLY_CONFIGURATION_CONFIRMED`; seleção direta não clicada; campo ainda pode mudar por outra rota |
| `LB04` | Lista associada a `PERIODO_COMPETENCIA`, `Apenas leitura` **marcada**, captura da aba Geral | `LOCAL_READ_ONLY_CONFIGURATION_CONFIRMED`; seleção direta não clicada; campo ainda pode mudar por outra rota |
| `BU15` | `ANUAL/EVOLUCAO`, ano em 2017–2019, `GetSelectedCount(PERIODO_ANO)=0` e competência `=0` para habilitar; única ação `Selecionar no Campo(PERIODO_ANO)`, `=Num($(vSAD_POC_Year))` | `CONFIGURATION_CONFIRMED`; despacho positivo 2019 é prova separada #201, não foi repetido; substituição de período já selecionado não é demonstrada |
| `BU16` | `MENSAL`, ano real único igual à proposta, competência real sem seleção, ano 2017–2019, mês 1–12; única ação `Selecionar no Campo(PERIODO_COMPETENCIA)`, `=Num($(vSAD_POC_Year))*100+Num($(vSAD_POC_Month))` | `CONFIGURATION_CONFIRMED`; guarda observada previamente #208 (1→0, estrito 0→1→0 inconclusivo); operador atestou **não clicar**; sem dispatch validado |
| Disparador de documento `Ao Fazer Qualquer Seleção` | Evento selecionado, **nenhuma ação vinculada visível** | `NO_ACTION_VISIBLE_IN_INSPECTED_EVENT`; não extrapolar a todo documento |
| Disparadores de campo `PERIODO_ANO` e `PERIODO_COMPETENCIA` | Eventos `Ao Selecionar`, `Ao Mudar`, `Ao Travar`, `Ao Destravar` sem ações vinculadas visíveis nas capturas | `NO_ACTION_VISIBLE_IN_INSPECTED_EVENTS`; outros campos/variáveis podem possuir configuração `UNKNOWN` |
| Menu Seleções | Operador enumerou `Voltar`, `Adiante`, `Travar`, `Destravar`, `Limpar`, `Limpar tudo`, `Destravar e limpar tudo`, `Configurar o estado de seleção`, `Reconfigurar o estado de seleção` | `NATIVE_SURFACE_ACCESSIBLE_NOT_PROVEN_CONTROLLED`; nenhuma operação executada, nenhum bypass funcional demonstrado |
| Busca | Controles/lupas e configurações herdadas visíveis em listas temporais; não foram realizadas buscas | `CAPABILITY_VISIBLE_EFFECT_UNKNOWN`; `Read Only` local não garante bloqueio da busca por outras superfícies |
| Marcadores do documento | Aba `Marcadores do Documento` vazia em captura; opção Importar visível | `NO_SAVED_BOOKMARK_VISIBLE_IN_INSPECTED_TAB`; importar/restaurar não testado |
| Marcadores do usuário | Aba `Marcadores do Usuário` vazia em captura; opção Importar visível | `NO_SAVED_BOOKMARK_VISIBLE_IN_INSPECTED_TAB`; mecanismo nativo não desabilitado por esse achado |
| `CH02` / `CH03` e outros gráficos/tabelas | Objetos visíveis no inventário; `CH03` exibia condição de cálculo não satisfeita no estado observado | `OBJECTS_EXIST_SELECTION_BEHAVIOR_UNKNOWN`; expressão/objeto exibido não prova bloqueio de seleção via gráfico |
| Disparadores de variáveis e outros objetos/ações | Lista de variáveis aparece na tela; sem inventário completo de suas configurações nem todos os objetos de interação | `UNKNOWN`; não preencher com `NOT_EXPOSED` |

**Síntese probatória:** lista temporal local somente leitura (duas configurações), ações/guardas de dois botões e ausência de ações visíveis em eventos temporais específicos **não** demonstram prevenção pré-despacho D2 em menus, restauro de seleções, busca, bookmarks importáveis ou seleção indireta. Também **não existe prova de bypass real executado**. A inspeção da TEMP do PR #208 não homologa a QVW final com P1/P2/P3.

### Resultado e decisão

- `C2_ROUTE_INVENTORY=PASS_READONLY_BOUNDED_WITH_UNKNOWN_NATIVE_ROUTES`: **PASS do inventário restrito visual**, não da contenção temporal.
- `WINDOWS_COPY_INTEGRITY=PASS_LOCAL_REPORTED`: origem, cópia e 25 protegidos preservados segundo o runner local; screenshots revisados separadamente.
- `D2_GLOBAL=BLOCKED_ROUTE_COVERAGE` e `C2_FULL=NO_GO_NOT_APPROVED`.
- `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Próxima decisão necessária, NÃO um novo teste automático:** responsável avaliar arquitetura de seleção temporal e o contexto de uso real do QlikView Desktop 12 para **todas** as rotas nativas acessíveis. Escolher mecanismo de contenção demonstrável e critérios de aceitação sob V2 §62.3; se não demonstrável, manter `BLOCKED_ROUTE_COVERAGE` e não ampliar a Fase IX. Não prescrever a ocultação de menus ou o uso exclusivo de botões como equivalente de proteção global. Essa deliberação deve ser independente deste gate de inventário.

**STOP deste gate:** uma rodada de inspeção física read-only encerrada e Verify íntegro; **nenhuma outra PoC**, seleção de valores, execução de UIA/Win32, alteração QVW/QVD/QVS, merge ou promoção C2/C3/C4. A branch/PR permanece Draft para revisão; este commit documental **não altera a identidade física da execução** no commit `71d41a5771143d146e1c4eff808dccc2585cc464`.
