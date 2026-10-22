# Fase VIII — Discovery e testes do piloto de interface guiada híbrida (22/10/2026)

**Gate:** \`VIII-C2-GUIDED-HYBRID-UI-DISCOVERY-LOGIC\`  
**Base canônica conferida:** \`main@a16539e10499d0346bf5574f3142f568a5073d02\` (PR #151 integrado).  
**Modalidade:** Discovery documental + teste de contrato puro em Python, **sem execução QlikView/COM/GUI**.  
**Decisão do usuário:** explorar interface simples com botões de análise e de contexto temporal, filtros contextuais agrupados/pesquisáveis, listas extensas ocultas. Não exige blindagem de todas as rotas nativas.
**Status:** \`GUIDED_UI_LOGIC=PASS_LOCAL_PURE_MODEL_ONLY\`; \`GUIDED_UI_QLIKVIEW_PHYSICAL=NOT_TESTED_ENVIRONMENT_UNAVAILABLE\`; \`GUIDED_UI_ARCHITECTURE=RECOMMENDED_CANDIDATE_NOT_PHYSICALLY_APPROVED\`.

## 1. Limite contratado e fontes

**Objetivo único:** avaliar viabilidade da hipótese de UI e testar coerência de transições/compatibilidade de filtros sem alterar dados, contratos ou QVW canônico.

**Leitura obrigatória:** \`AGENTS.md\` → \`docs/project/current-state.md\` → \`docs/academic/requirements.md\` → Boundary 7 → V2 §62.3/62.6/62.7 → C2-E/F/G/H/I → \`docs/project/qlikview-powershell-automation.md\` → política de roteamento. Fontes oficiais QlikView 12 September 2026 listadas ao final.

**Preservar:** QlikView 12; BASE→EXTRACAO→QVD→TRANSFORMACAO→QVD→PAINEL; 3 fatos, 8 dimensões, estrelas com Link Table; grãos; conceito de média mensal de LT; RN21; observação de cobertura CNES/LT; não confundir RES/SERV; decisões V2 aprovadas **somente semanticamente**.

**Escopo autorizado nesta execução:** nova branch com um teste Python stdlib e um relatório; execução Python local do **blob Git idêntico**; revisão da documentação técnica. Sem modificação de QVW/QVD ou scripts de pipeline, sem commit em main, sem merge, sem Fase IX.

**STOP:** após matriz de viabilidade + teste lógico + roteamento da prova física. Não expandir para criação de dashboard.

## 2. Viabilidade técnica fundamentada

| Função desejada | Recurso QlikView documentado | Grau de prova |
|---|---|---|
| Botões para RES/LEI/REL/FLU e três modos temporais | Objetos Button/ações/condições de habilitação | **Capacidade oficial**; nenhum botão novo foi construído ou inspecionado no QVW |
| Ano, competência ou contexto de proposta sem lista extensa permanente | Input Box com variáveis e valores predefinidos, restrições de entrada | **Capacidade oficial**; não demonstra a integração às expressões/seleções |
| Filtros contextuais de município/procedimento | Multi Box com vários campos e listas suspensas | **Capacidade oficial**; filtro real sob papel territorial não testado |
| Filtros avançados recolhidos / indicação de contexto | Condição de exibição e objeto de seleções correntes | **Capacidade oficial**; efeito de esconder não impede seleção nativa |
| Aplicar novo período com estado temporal consistente | Hipótese: validar proposta antes de qualquer seleção real | **Ainda não provada fisicamente**. Ações Qlik não equivalem a transação; ações em cascata são desaconselhadas |
| Triggers para corrigir depois | OnAnySelect/OnSelect disparam após selecionar | **Não atende D2 pré-despacho** como controle primário |
| Separar estados alternativos | Alternate States isolam parte das seleções, mas complicam Clear/Back/indicadores | **Não adotado**; sem justificativa para nova complexidade neste piloto |

## 3. Desenho de UX proposto, sem modificar a V2

A barra principal escolhe um indicador: **RES**, **LEI**, **REL** ou **FLU**. O seletor temporal expõe modos **MENSAL (ano+mês)**, **ANUAL (ano)** e **EVOLUCAO (12 competências no ano)**. Abaixo, um painel compacto de filtros relevantes/avançados, preferencialmente pesquisável, exibe campos conforme a análise. No topo ficam **contexto aplicado**, **filtros ativos** e **motivo de indisponibilidade**.

Usar botões para *navegação e troca de modo*, mas **não um botão por município/procedimento**. A troca de análise **não elimina filtros silenciosamente**: filtros não compatíveis continuam identificáveis e o KPI fica indisponível com motivo, ou a interface propõe limpeza explícita e confirmada em contrato futuro. **Não aprovar automaticamente a segunda opção**.

Temporalidade: MENSAL = uma competência; ANUAL = um ano único, medidas conforme V2; EVOLUCAO = série mensal dentro de um ano, sem somar snapshots LT como estoque anual. Períodos parciais/descontínuos, se adicionados, precisam de rótulo e regra próprios; não incluídos no piloto lógico atual.

**P5:** a matriz 12×4 C/R/I/B da V2 foi transcrita no script de teste. C não dispensa verificação de cobertura/denominador; B impede indicador geral; R exige contrato de recorte específico, e I requer isolamento explícito fisicamente comprovado. No piloto lógico, R/I ficam **indisponíveis por prudência**, não são ignorados.

## 4. Teste lógico realmente executado

**Script versionado ANTES da execução:** \`tools/validate_sad_guided_hybrid_ui_contract.py\`, commit \`b85342600b44f308678b51a4d492a3c0d55ee8b6\` na branch deste gate. **Git blob:** \`3273c247e251248aab582acd1d9f9a7f4054368a\`. Uma cópia executada no ambiente isolado Linux foi comparada por **Git blob SHA idêntico**; SHA-256 da cópia: \`dcfb97b47659049466611c459b9c27b8f74d5fe4ebe246660fe50b7b29aa01db\`.

**Comando:** \`python tools/validate_sad_guided_hybrid_ui_contract.py\` (executado na cópia byte a byte idêntica). **Resultado:** \`Ran 18 tests ... OK\`; código de saída \`0\`; sem COM, acesso de rede, gravação de dados, QVW ou QVD.

Cobertura dos 18 casos automatizados: 36 competências de 2017–2019; MENSAL→ANUAL→EVOLUCAO; rejeição pré-despacho de ano incompatível, mês inválido e modo fora do recorte; exigência de mês explícito no MENSAL; alteração de análise mantendo filtros rastreáveis; quatro categorias P5 C/R/I/B e combinações; tabela de 12 filtros; rejeição de filtros desconhecidos. Teste de modelo **não** valida QlikView, semântica final das expressões, nem cobertura CNES.

| Critério | Resultado |
|---|---|
| \`LOGIC_TESTS=18/18\` | **PASS no modelo Python puro** |
| \`GIT_VERSION_MATCH\` | **PASS Git blob idêntico** |
| \`QLIK_BUTTONS_ACTUAL\` | **NOT_TESTED** |
| \`QLIK_INPUT_BOX_AND_MULTI_BOX\` | **NOT_TESTED** |
| \`QLIK_TEMPORAL_FIELD_SELECTIONS\` | **NOT_TESTED** |
| \`QLIK_P5_KPI_VISIBILITY\` | **NOT_TESTED** |
| \`SANDBOX_WINDOWS_NATIVE_QVW\` | **NOT_TESTED nesta rodada** |
| \`C2_FULL\`, \`P5_D2_UI\`, \`F4_P5_PHYSICAL_FILTERS\` | **NO_GO / NOT_TESTED / NOT_TESTED_FULLY** |

## 5. Sandbox Codex Windows — decisão operacional

**Fato histórico:** o C2-H encontrou \`$env:TEMP\` redirecionado dentro do sandbox de Codex (local \`Packages\\sandbox.{...}\\AC\\Temp\`), diferente da origem real \`AppData\\Local\\Temp\`. Reproduzir \`Join-Path $env:TEMP\` não identifica corretamente um QVW originalmente criado em outro ambiente. **Não alterar scripts/hashes de gates anteriores para contornar.**

**Plano seguro para próximo gate, não executado:** agente Codex Local no Windows prepara código versionado, revisa sintaxe com PowerShell Parser e emite um *contrato de invocação* com caminhos absolutos **somente após conferir existência + SHA na sessão nativa**. Para COM/GUI, usar PowerShell 5.1 nativo em sessão Windows interativa autorizada, com permissão definida e cópia QVW descartável sob diretório de runtime exclusivo. Nunca assumir acesso pelo sandbox: se negado, **RECOVERABLE_BLOCK**, não desabilitar sandbox, não forçar checkout, não buscar cópias aleatórias. Fallback: operador humano inicia o script versionado no PowerShell nativo.

**Insumos reais (não adivinhar):** extrair \`SourceQvw\` e \`RUNTIME_TEMP_COPY\` do manifesto C2-H efetivo ou registrar nova fonte de teste via inventário somente leitura; conferir SHA e identidade. Não reutilizar nomes antigos de diretório com GUID como se fossem invariantes. **EVIDENCE_ROOT** persistente fora de \`%TEMP%\` e fora do Git; conferir capacidade de gravação apenas no gate físico autorizado. Antes/depois, proteger os 22 QVDs e 3 QVWs canônicos por hash, sem \`Reload()\` ou \`Save()\` na origem.

Work Cloud não possui automaticamente o executável QlikView nem COM/arquivos locais. Work Local só pode fazer inspeção de GUI se capacidade/permissão forem verificadas. Agente principal: **Codex Local no Windows**; revisão: ChatGPT+GitHub; esforço/modelo a registrar pelo executor, não presumidos.

## 6. Um único gate físico subsequente (proposto, sem execução)

**ID:** \`VIII-C2-GUIDED-HYBRID-UI-POC-PHYSICAL\`. Autorização separada necessária para editar **somente a nova cópia QVW experimental**.

**Objetivo:** demonstrar em **uma única folha/cópia QVW**, sem criar dashboards, três modos de contexto temporal e filtro municipal contextual, com exibição legível de contexto e indisponibilidade.

**Cenários mínimos, sem repetir C2-D3/C2-H:**

1. RES → MENSAL 201801: aplicar e ler estado real de Qlik, capturando pré/pós.
2. MENSAL 201801 → ANUAL 2019: não manter 201801 incompatível; validar ausência de seleção residual e contexto 2019.
3. ANUAL 2019 → EVOLUCAO 2018: série de 12 meses de 2018, **não prova que os 12 meses de cada município tenham LT válido**; ano do contexto deve permanecer explícito.
4. RES com município de residência → mudar para LEI: não apagar o filtro silenciosamente; KPI LEI deve ficar indisponível por P5=B ou solicitar decisão explícita de remoção antes de calcular.
5. Seleção de município de serviço em LEI: avaliar apenas se as propriedades reais dos objetos suportarem o filtro; observar o estado. **Não certificar medida real nem P5 global**.
6. Verificar \`GetFieldSelections\`, propriedades, capturas PNG antes/depois e hashes protegidos, revisando o conteúdo e não somente o status emitido.

**Decisão pendente de implementação:** a sincronização entre variáveis de proposta e \`PERIODO_ANO\`/\`PERIODO_COMPETENCIA\` real ainda deve ser demonstrada sem depender de ações Qlik em cascata. Se duas seleções sequenciais implicarem estado intermediário incompatível e não houver mecanismo comprovado de preservação, **STOP**; não substituir silenciosamente D2=B por rollback pós-seleção.

**PASS físico mínimo:** contexto temporal, filtro e aviso de indisponibilidade coerentes em estados reais + integridade dos 25 protegidos + pares de capturas/seleções + COM/UI acessível. **BLOCKED:** fonte/COM/QVW inacessível, sandbox divergente sem fallback autorizado, mudança inesperada em protegido, transição inválida em botão suportado. **INCONCLUSIVE:** capturas ou leitura de seleção insuficientes. **STOP:** uma preparação e uma rodada autorizada, sem retries especulativos.

O PASS deste próximo gate aprovaria **somente a experiência guiada na cópia**; jamais \`C2_FULL\`, \`LINK_KEY_CONTRACT\`, \`MEASURES_AND_DENOMINATOR_CONTRACT\`, \`PHASE_IX\` ou produção.

## 7. Decisão de encerramento

**FATO VERIFICADO:** recursos nativos necessários existem na documentação oficial, os testes puros de lógica passaram, e a limitação real do sandbox já ocorreu em C2-H. **HIPÓTESE:** os recursos poderão funcionar juntos no QVW com fluxo guiado suficientemente legível. **PENDENTE:** prova real Windows/QlikView e aceite arquitetural do responsável.

\`GUIDED_HYBRID_LOGIC_GATE=PASS_PURE_MODEL_ONLY\`  
\`GUIDED_HYBRID_PHYSICAL_GATE=NOT_TESTED\`  
\`MERGE_AUTHORIZED=FALSE\`; \`PHASE_IX=NOT_AUTHORIZED\`; \`PRODUCTION_APPROVED=False\`.  
**STOP do presente gate:** atingido; nenhuma execução física iniciada.

## 8. Referências

- [V2 semântica aprovada](phase-6-semantic-v2-approved-2026-10-14.md), [C2-I](phase-8-c2i-residual-temporal-selection-closure-2026-10-21.md), [C2-H](phase-8-c2h-readonly-listbox-physical-pilot-2026-10-21.md), [Boundary 7](boundary-7-implementation-plan.md), [Automação](../project/qlikview-powershell-automation.md).
- [QlikView September 2026 — Input Box](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Input_Box.htm).
- [QlikView September 2026 — Multi Box](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Ajax/WebView_MultiBox.htm).
- [QlikView September 2026 — Button](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm).
- [QlikView September 2026 — Triggers](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Document_Properties_Triggers.htm).
- [QlikView September 2026 — Alternate States](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Alternate%20States.htm).
