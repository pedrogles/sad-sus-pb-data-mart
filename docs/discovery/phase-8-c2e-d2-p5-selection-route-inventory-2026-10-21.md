# Fase VIII — C2-E | Inventário e decisão de rotas de seleção D2/P5 (READ-ONLY)

**Data:** 21/10/2026. **Fonte operacional:** `main@28e70fee75035a86b52ea9bf0fd6a836be1ce5ca`, após merges #110–#114 e reconciliação #144.  
**Veredito do gate:** `C2E_ROUTE_INVENTORY=COMPLETED_READONLY_WITH_LIMITS`. **Decisão:** `C2E_GLOBAL_UI=NO_GO_NOT_PROVEN`; próxima investigação proposta `C2F_PHYSICAL_ROUTE_INVENTORY=PROPOSED_NOT_AUTHORIZED`.

## 1. Objetivo, escopo e nível probatório

Objetivo único: identificar **rotas candidatas de modificação** de `PERIODO_ANO` e `PERIODO_COMPETENCIA`, separar as que foram testadas das apenas possíveis, registrar as consequências da política P5, e decidir **um único gate subsequente** antes de buscar qualquer aceite global D2. Não há nesta sessão QlikView Desktop, COM/Win32 ou QVW original aberto: **é inventário documental**, não enumeração física da interface vigente.

Fontes lidas: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → `boundary-7-implementation-plan.md` → V2 §62 → `phase-8-c2-evidence-closeout-readonly-2026-10-20.md` → `phase-8-c2d-d2-ui-predispatch-feasibility-2026-10-19.md` → `phase-8-c2d3-rawview-win32-discovery-2026-10-19.md` → `docs/project/qlikview-powershell-automation.md`; PRs históricos #117–#124 como fontes de evidência e pilotos #110–#114 **integrados**, não como validação de UI.

**Permissões neste gate:** leitura do Git e documentação deste estudo; nenhuma ação Windows/COM/GUI, clique, disparo de seleção, atualização de script, QVD, QVW, dado, painel ou modelagem. `RUNTIME_TEMP` e `EVIDENCE_ROOT`: não aplicáveis. Agente primário ChatGPT/GitHub; modelo GPT-6, nível de esforço não selecionado pelo executor; fallback para operação local Windows **somente em gate distinto autorizado**. STOP ao documentar a matriz e a decisão.

## 2. Contrato de referência que não pode ser degradado

- **V2 D2=B (§62.1/62.3):** impedir incompatibilidade ano×competência **antes de despachar a proposta** e de descartar a seleção válida/intenção do usuário. Restaurar depois via trigger não é prova de D2.
- **V2 P5=B (§62.6):** por indicador `RES/LEI/REL/FLU`, `C` só com tempo/território/cobertura válidos, `R` exige análise de recorte própria, `I` exige isolamento explícito e fisicamente validado (senão indisponível), `B` bloqueia o indicador geral. **Filtros simultâneos não anulam classes B/I/R**.
- **P5 observado parcialmente:** testes de C2-A/V/W demonstraram alguns bloqueios visuais sob seleção já existente; #111 passou quatro guardas **somente no wrapper**, com `DISPATCHED=False`; #110/#112–#114 reconciliam subconjuntos numéricos sem provar proteção D2 em UI.
- **Controle de fonte:** V2 é aprovação **semântica**, não um contrato QlikView de eventos, seleção, configuração ou painel completo.

## 3. Inventário de rotas — observado versus potencial

| Superfície/rota | O que a evidência de fato prova | Status para D2/P5 | Observação e possível bypass |
| --- | --- | --- | --- |
| **Wrapper PowerShell antes do COM** | PR #111: dois conflitos D2 e duas guardas P5 bloqueados antes do despacho; status `PASS_LOCAL_WRAPPER_ONLY_NOT_UI` | **PASS restrito fora da UI** | Não intercepta cliques humanos, busca, outros objetos ou bookmark |
| **Botões BU01/BU02 em QVW experimental** | C2-D1: D2-1 e D2-3 com pares de imagens e `PASS_VISUAL_RESTRICTED`; D2-2/D2-4 têm apenas captura única e relato compatível | **CANDIDATE_PARTIAL_ONLY** | Sem prova íntegra de pré-despacho para quatro casos nem de todas as rotas |
| **Listbox nativa ano/competência** | C2-D: propriedade `Read Only` atua naquele objeto; falta inventário de todos os objetos/campos expostos | **POTENTIAL_BYPASS_NOT_VERIFIED_EXPOSED** | Pode permitir seleção direta se não estiver restrita; não afirmar que está exposta no painel final |
| **Busca, bookmarks, menus e outras ações de seleção** | Mecanismos de seleção citados em C2-D, mas presença efetiva no QVW a homologar **não foi enumerada** | **UNINVENTORIED** | Ausência de inventário não significa ausência da rota; não declarar bloqueio universal |
| **Ações/objetos adicionais ou seleção programática COM** | Há seleção COM nos ensaios e ações `Select in Field` na documentação Qlik | **CAPABILITY_EXISTS; UI_REACHABILITY_UNPROVEN** | Prova de wrapper não garante aplicação da política em outros chamadores |
| **Triggers `OnSelect`, `OnAnySelect`, `OnChange` e macro de rollback** | C2-D documenta eventos após seleção; rollback não preserva prova de bloqueio anterior | **NO_GO_FOR_PREDISPATCH** | Não usar para afirmar D2; não alterar semântica V2 |
| **Calculation Condition / Set Analysis e aviso visual** | C2-A/V/W provaram alguns bloqueios de cálculo/apresentação restritos para T26 sob filtros | **POST_SELECTION_DISPLAY_GUARD_ONLY** | Não impede que seleção incompatível tenha sido feita |
| **Identificação automática de BU01/BU02 pela RawView/Win32** | C2-D3: RawView 1 elemento por leitura; Win32 45 HWNDs; 0 correspondências BU01/02 nos dois percursos | **NO_GO_ID_BY_NAME_IN_THIS_PROBE** | Não prova impossibilidade absoluta de automação nem habilita clique geométrico |

**Distinção obrigatória:** "possível mecanismo Qlik" não é "rota efetivamente exposta". Essa classificação evita inventar objetos que não foram inventariados fisicamente e impede aprovar D2 por ausência de evidência contrária.

## 4. Cobertura P5 de filtros simultâneos

A política V2 tem **12 linhas de filtro para quatro indicadores** e exige avaliar combinações sem propagar medidas ou denominadores de fatos incompatíveis. A tabela seguinte é **inventário de lacunas**, não resultado de reexecução:

| Família do cenário | Evidência existente | Pendência decisiva |
| --- | --- | --- |
| Temporal (`PERIODO_ANO`/competência) | Wrapper D2 em #111 e ensaios parciais C2-D1 | Bloqueio **antes da seleção real** em toda rota disponibilizada |
| `RES` × município residência/serviço | T24 para residência; C3-B1/B2 fluxos role-playing restritos; P5 B para serviço no wrapper | Resultado/aviso sob filtros cruzados na UI, sem confundir papel e POP |
| `LEI` e `REL` × procedimento/diagnóstico/caráter/motivo | V2 os trata `I` para LEI e `B` para REL; poucos B de T26 em C2-A | Comprovar bloqueio ou isolamento explícito sem recalcular silenciosamente |
| Tipo de leito, estabelecimento e datas clínicas | Matriz V2 contém `I/R/B` conforme indicador | Não criar KPI geral sob `R`, nem interpretar `I` ignorado como permissão |
| Vários filtros simultâneos | C2-A documenta subconjunto de dois B e avisos restritos | Sem prova global de 12×4 ou de todas as interações; não inferir PASS |

**Regra de desenho de teste futuro (hipótese operacional, não decisão de modelagem):** classificar primeiro a seleção proposta como `C/R/I/B` para cada indicador e contexto, depois verificar ano/competência e só então permitir uma ação específica; o cálculo deve continuar indisponível quando o denominador/escopo não for validado. Isso **não** implementa automaticamente a V2.

## 5. Decisão de arquitetura de interação — delimitada

**DECISÃO PENDENTE do responsável, sem aprovação física:** há duas saídas defensáveis: (A) projetar uma **superfície de seleção controlada** para ano/competência e comprovar que todos os caminhos alternativos expostos foram bloqueados ou não existem naquele QVW; (B) manter o bloqueio formal da UI D2 e não apresentar o aplicativo como homologado. A prova atual sustenta apenas `C2E_GLOBAL_UI=NO_GO_NOT_PROVEN`; não sustenta escolher/implementar A silenciosamente.

**Um próximo gate proposto: `C2-F — inventário físico READ-ONLY das rotas efetivamente expostas`**, sem clique e sem mutação. Pré-condições: identificar **uma** cópia QVW de evidência C2-W/D1 por caminho e SHA, confirmar versão QlikView 12/Desktop Windows, poder ler propriedades de objetos/ações/campos; proteger 22 QVDs e três QVWs canônicos. Uma inspeção local controlada (COM read-only/propriedades, quando suportado, e revisão humana da interface) deve entregar: ID/tipo da folha, listboxes ano/competência, botões BU01/BU02, condições de habilitação, ações ligadas, triggers, buscas/bookmarks e rotas alternas **efetivamente observadas**, indicando `PRESENT`, `NOT_FOUND_IN_SCOPE` ou `UNKNOWN`; registrar stdout e imagem sob evidência persistente, sem tentar automatizar clique por Win32/UIA e sem assumir que ausência de ID é ausência da rota. Critério de STOP: uma rodada documentada ou `BLOCKED` por fonte/capacidade não disponível. **C2-F exige autorização própria e script versionado se houver automação**; não reexecutar C2-D3 ou C2-W.

**Não iniciar ainda teste de mutação de seleção nem dashboard.** Só depois do inventário será possível definir o menor cenário de pré-despacho com rota/ator e critérios inequívocos.

## 6. Closeout C2-E

`C2E_ROUTE_INVENTORY=COMPLETED_READONLY_WITH_LIMITS`; `C2E_GLOBAL_UI=NO_GO_NOT_PROVEN`; `C2F_PHYSICAL_ROUTE_INVENTORY=PROPOSED_NOT_AUTHORIZED`. Preservar: `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**STOP:** documento de inventário e decisão produzido; não converter este estudo em prova física, nem iniciar C2-F, C3/C4 globais ou Fase IX automaticamente.