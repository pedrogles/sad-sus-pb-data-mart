# SAD — Gate VIII-C2 Guided UI físico: roteiro controlado (22/10/2026)

**Base verificada:** `main@a16539e10499d0346bf5574f3142f568a5073d02`.  
**Discovery lógica:** [PR #152](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/152), Draft, 18 testes Python reportados PASS apenas para o modelo isolado.  
**Status inicial (histórico, antes dos testes):** `RUNNER_VERSIONED`; `PARSER_WINDOWS=NOT_RUN`; `PREPARE_WINDOWS=NOT_RUN`; `GUI_QLIKVIEW=NOT_RUN`. **Resultado vigente deste piloto:** consultar §8 (navegação por variáveis `PASS_VISUAL_BOUNDED_PROPOSAL_ONLY`, integridade local reportada; seleção temporal real/P5 ainda fora desse gate).  
**Objetivo único:** preparar 1 QVW descartável para testar os três modos guiados, filtro municipal contextual e comportamento P5. Sem dashboard final e sem merge.

## 1. Contrato e limites

Fontes na ordem: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, Boundary 7, V2 §62.3/62.6/62.7, C2-F/G/H/I, `docs/project/qlikview-powershell-automation.md`, política de agentes e PR #152.

Preservar QlikView 12, BASE→EXTRACAO→QVD→TRANSFORMACAO→QVD→PAINEL, 3 fatos, 8 dimensões, Link Table, escopo CNES/LT observado, RN21 e os contratos semânticos V2. D2 pré-despacho não equivale a guarda de toda a interface; P5 por indicador é independente de D2. Não inventar campo municipal nem mudar grão/denominador.

**Permissão:** scripts e roteiro em branch; um QVW experimental novo fora do Git quando o Windows nativo executar; nenhuma escrita em QVD/3 QVWs canônicos ou origem. Runner não faz COM/GUI/reload nem configura objetos Qlik automaticamente. Criar objetos somente na cópia após preflight PASS, com revisão e uma única rodada; sem exploração de Win32/UIA, bookmarks ou macros.

**Agente:** Codex Local para revisar código/PowerShell parser em Windows se acesso disponível; operador humano PowerShell 5.1 nativo e QlikView 12 para operação na cópia. Work Cloud não tem acesso implícito ao QlikView local; Work Local requer permissão/capacidade comprovada. Modelo/esforço efetivos a registrar pelo executor. ChatGPT/GitHub revisa saídas. STOP ao primeiro bloqueio.

## 2. Risco concreto de sandbox e origem pinada

C2-H comprovou historicamente `$env:TEMP` diferente em sandbox Codex (`Packages\sandbox...\AC\Temp`) versus Windows nativo (`AppData\Local\Temp`). **Não desabilitar sandbox, nem reconstruir outra origem por heurística.**

Fonte obrigatória deste gate: a cópia final `SAD_C2H_READONLY_PILOT_COPY.qvw`, hash SHA-256 **`1724C785442F4FBA8C59E4D908C711AADC546C3AEB958208EA3FDC0F35CF180B`**, indicada pelo manifesto C2-H reportado em `Documents\SAD_C2H_EVIDENCIAS\SAD_VIII_C2H_ee31c0f9a9da40cda0d94fe791b6ec32\c2h_manifest.json`. Essa origem pode não existir mais; ausência/hash divergente = BLOCKED/HARD_STOP, sem procurar arquivo semelhante.

O novo runner recebe `SourceQvw`, `RuntimeRoot` e `EvidenceRoot` **absolutos**. Não usa `$env:TEMP`. Os 22 QVDs e 3 QVWs canônicos terão inventário de hash antes/depois. Raízes de runtime/evidência fora do repositório e uma da outra.

## 3. Comandos — Windows PowerShell 5.1 nativo, não sandbox

Executar no clone Windows após confirmar `git status --short`. Não limpar arquivo não rastreado, não forçar checkout, não alterar dados. Se branch já existir, usar `git switch` para ela; caso contrário:

~~~powershell
git fetch origin
git status --short
git switch --track origin/test/phase-viii-c2-guided-hybrid-ui-physical-prep-20261022
git rev-parse HEAD

$root = (Get-Location).Path
$c2h = Join-Path $env:USERPROFILE 'Documents\SAD_C2H_EVIDENCIAS\SAD_VIII_C2H_ee31c0f9a9da40cda0d94fe791b6ec32\c2h_manifest.json'
$source = [string](Get-Content -LiteralPath $c2h -Raw | ConvertFrom-Json).TestCopy
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_MISSING'}
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne '1724C785442F4FBA8C59E4D908C711AADC546C3AEB958208EA3FDC0F35CF180B') {throw 'HARD_STOP_SOURCE_SHA_DRIFT'}

$runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_GUIDED_RUNTIME'
$evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_GUIDED_EVIDENCIAS'
New-Item -ItemType Directory -Path $runtime,$evidence -Force | Out-Null
$script = (Resolve-Path '.\tools\Invoke-SadPhaseViiiC2GuidedUiPilot.ps1').Path
$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors)
if ($errors.Count -gt 0) { $errors | ForEach-Object { $_.ToString() }; throw 'PARSER=BLOCKED' }
'PARSER=PASS'
powershell.exe -NoProfile -File $script -Root $root -SourceQvw $source -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
~~~

Guardar os valores exatos `RUNTIME_COPY`, `EVIDENCE_DIR`, `VERSIONED_GIT_HEAD`, `RUNNER_SHA256` e `VERDICT` emitidos. Esperado só `PASS_COPY_PREPARATION_ONLY_NOT_PHYSICAL_UI`. Uma única preparação. Se a cópia original no TEMP estiver ausente, encerrar `BLOCKED` e submeter a evidência; não inventar substituição.

## 4. Procedimento da prova GUI em uma cópia

Abrir **somente** a cópia cujo nome termina em `SAD_C2_GUIDED_HYBRID_POC_COPY.qvw`, confirmar na barra de título. Não abrir/modificar C2-H original, C2-F, QVWs canônicos ou QVDs.

**A — Experiência guiada:** numa nova folha experimental, criar *se a instalação suportar* quatro variáveis **somente de proposta** com prefixo de POC: `vSAD_POC_Mode`, `vSAD_POC_Year`, `vSAD_POC_Month`, `vSAD_POC_Analysis`. Modos MENSAL/ANUAL/EVOLUCAO, anos 2017–2019, meses 1–12, indicadores RES/LEI. A entrada de ano/mês pode ser Input Box com valores predefinidos. Criar 3 botões de modo e 2 de indicador com **uma ação Set Variable por botão** caso essa ação esteja efetivamente exposta na instalação; inserir texto/status visível com o estado de proposta. Não editar BU01/BU02 nem LB01/LB04.

**B — Testes de estado proposta:** capturar antes/depois de MENSAL 201801 → ANUAL 2019 → EVOLUCAO 2018. Se o modo altera apenas uma variável, classificar `GUI_NAVIGATION_PROPOSAL_ONLY`, **não** `D2_REAL_FIELD_SELECT_PASS`. Não usar operações encadeadas de limpar/selecionar com ordem assumida. Para testar commit aos campos reais `PERIODO_ANO` e `PERIODO_COMPETENCIA`, primeiro demonstrar que a propriedade/action do QlikView permite uma mudança coerente em uma rota controlada. Se não puder, `TEMPORAL_DISPATCH=NOT_PROVEN` e STOP — sem alterar a semântica V2.

**C — Filtro contextual:** somente após inspecionar o nome e papel dos **campos municipais reais** no QVW, criar um Multi Box de residência/serviço conforme indicador, sem inventar nomes. Registrar as propriedades. Em RES selecionar município de residência; depois alternar para LEI, preservando filtro. Segundo V2 P5, esse filtro é B para LEI: o indicador deve exibir motivo de indisponibilidade, não número. **Se não existir guarda KPI configurada, registrar `P5_DISPLAY=NOT_TESTED`, jamais PASS por etiqueta simulada.**

**Evidências:** uma captura inicial, três estados temporais, propriedades dos botões/variáveis, seleção municipal real, evidência de indisponibilidade KPI quando existente, hashes. Observações parciais ficam NOT_TESTED. Salvar **uma vez somente a cópia** ao concluir as mudanças planejadas; fechar QlikView sem segundo salvamento.

## 5. Verificação posterior, apenas na mesma versão do runner

Após fechar a cópia, manter **mesmo checkout/commit** do preparo:

~~~powershell
powershell.exe -NoProfile -File $script -Root $root -SourceQvw $source -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir 'SUBSTITUIR_PELO_EVIDENCE_DIR_EXATO_DO_PREPARE'
~~~

Esperados `PROTECTED_25_UNCHANGED=True`, `SOURCE_UNCHANGED=True`, `COPY_CHANGED=True`, `VERDICT=PASS_HASH_INTEGRITY_ONLY_UI_NOT_PROVEN`. Estes são resultados **esperados**, não observados nesta sessão.

## 6. Critérios e STOP

- `PASS_SCRIPT_VERSIONED`: script em Git; **não** significa parser/runtime PASS.
- `PASS_PREPARATION_ONLY`: hash pinado, 25 protegidos, cópia/manifesto criada.
- `PASS_GUI_PROPOSAL_BOUNDED`: botões/variáveis reais Qlik demonstrados em estados pré/pós.
- `PASS_D2_GUIDED_REAL_SELECT`: somente se os campos temporais reais e o pré-despacho forem comprovados na cópia.
- `PASS_P5_BOUNDED`: somente se seleção municipal verdadeira e KPI inválido realmente bloqueado.
- `BLOCKED/INCONCLUSIVE`: falta de arquivo, parser, QlikView COM/UI, logs, propriedades, evidência ou comportamento ambíguo; parar após uma tentativa, sem expandir.
- `STOP`: uma cópia + uma rodada. Não aprovar D2 global, P5/UI global, Link Key, contrato das medidas ou Fase IX.

**Flags inalteradas:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## Referências

- [QlikView 12 — Variáveis/restrições](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Document_Properties_Variables.htm).
- [QlikView 12 — Input Box](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Input_Box.htm).
- [QlikView 12 — Button](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm).
- [QlikView 12 — Multi Box](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Multi_Box.htm).
- [V2 aprovada semanticamente](phase-6-semantic-v2-approved-2026-10-14.md), [C2-H](phase-8-c2h-readonly-listbox-physical-pilot-2026-10-21.md), [C2-I](phase-8-c2i-residual-temporal-selection-closure-2026-10-21.md).



## 8. Fechamento experimental com evidências Windows/GUI fornecidas (22/10/2026)

**Gate encerrado no escopo de navegação guiada por variáveis + integridade da cópia.** Este fechamento não modifica o runner, sua identidade, os QVDs ou o QVW; somente registra as evidências transmitidas pelo operador.

### 8.1 Execução Windows — relatada por stdout

A sequência de mensagens PowerShell fornecida pelo operador contém `CHECKOUT=PASS`, `PARSER=PASS` (PowerShell 5.1), uma preparação `-Prepare` e uma verificação final `-Verify`. As saídas textuais do executor local, sem inspeção externa do binário QVW ou dos JSONs de manifesto, registram:

| Atributo | Saída reportada |
|---|---|
| Branch | `test/phase-viii-c2-guided-hybrid-ui-physical-prep-20261022` |
| `VERSIONED_GIT_HEAD` no preparo e verificação | `49c48f3eab40cdd790d7abe78f33c83db49e627a` |
| `RUNNER_SHA256` | `BD124C1E8C33967DD1FDD95586062188B2086EDE995BAA0DAD7ED03DDFDFC146` |
| `SOURCE_SHA256` | `1724C785442F4FBA8C59E4D908C711AADC546C3AEB958208EA3FDC0F35CF180B` |
| `PROTECTED_AND_SOURCE_UNCHANGED` após Prepare | `True` |
| `RUNTIME_COPY` | `C:\Users\pedro\Documents\SAD_C2_GUIDED_RUNTIME\SAD_VIII_C2_GUIDED_2574d7e1b90b4edbb6e17edd9322e501\SAD_C2_GUIDED_HYBRID_POC_COPY.qvw` |
| `EVIDENCE_DIR` | `C:\Users\pedro\Documents\SAD_C2_GUIDED_EVIDENCIAS\SAD_VIII_C2_GUIDED_2574d7e1b90b4edbb6e17edd9322e501` |
| `PROTECTED_25_UNCHANGED` no Verify | `True` |
| `SOURCE_UNCHANGED` no Verify | `True` |
| `COPY_CHANGED` | `True` |
| `COPY_SHA256` após teste GUI | `3BD19C6D7AE64A258094FA53233D9542E5203189369EA8C1460BF4A447857774` |
| `VERDICT` do Verify | `PASS_HASH_INTEGRITY_ONLY_UI_NOT_PROVEN` |
| `QLIK_COM_CALLS / RELOAD_CALLS / AUTOMATED_UI_EDITS` do runner | `0 / 0 / 0` |

**Nível probatório:** `PASS_LOCAL_REPORTED_HASH_INTEGRITY`; logs/manifests de origem não foram abertos independentemente nesta execução remota. O texto comprova o que o runner reportou, **não** funcionamento numérico das medidas nem aprovação visual automática.

### 8.2 Seis imagens QlikView — conteúdo realmente conferido

Cinco capturas visuais de `POC - Interface Guiada` exibem o QVW experimental na barra de título, três botões de modo (`Mensal`, `Anual`, `Evolução`), dois botões de indicador (`Internações (RES)`, `Leitos (LEI)`), caixa de entrada com Ano/Mês, texto de contexto e um objeto compacto de filtros. O texto observável muda:

| Captura fornecida | Contexto visível |
|---|---|
| `image(20261022-153547).png` | `MENSAL / 2018 / mês 1 / LEI` |
| `image(20261022-153610).png` | `ANUAL / 2019 / mês 1 / LEI` |
| `image(20261022-153629).png` | `EVOLUCAO / 2018 / mês 1 / LEI` |
| `image(20261022-153644).png` | `EVOLUCAO / 2018 / mês 1 / RES` |
| `image(20261022-153655).png` | `EVOLUCAO / 2018 / mês 1 / LEI` |

A sexta imagem, `image(20261022-154842).png`, 689 × 526 px, SHA-256 **`7FB707DD549B636D2E74CF0DB1299188A80730DFB48657A03A31401C79419685`**, mostra a caixa `Propriedades do Botão [Mensal]`, aba `Ações`, com uma ação `Definir Variável`, variável `vSAD_POC_Mode` e valor `='MENSAL'`. Isso suporta tanto a configuração declarada quanto sua compatibilidade com as alterações de texto observadas, sem captura interna do evento.

Um seletor compacto mostra visualmente uma escolha verde `250750` na linha cujo rótulo inicia `SERV_COD_DA...`, **sem expansão do nome de campo ou reconciliação do papel por metadados**. A seleção continua visível nas imagens de RES e LEI. A P5 afirma que município de serviço é B para RES, mas **não houve teste de guarda real do KPI**, e o campo exato precisa ser confirmado se for objeto de um novo gate.

**Precisão temporal:** o texto `Mês: 1` continua visível no estado ANUAL/EVOLUCAO. Isso é aceitável *somente como estado de proposta* e deve ser ocultado/interpretado corretamente na UI futura; não é evidência de que o Qlik filtrou fisicamente 201801 ou limpou competência anterior.

### 8.3 Resultado proporcional

| Contrato/gate | Fechamento |
|---|---|
| `GUIDED_UI_BUTTON_VARIABLE_ACTION` | `SUPPORTED_BY_REAL_QV_PROPERTY_SCREENSHOT` |
| `GUIDED_UI_THREE_MODES_PROPOSAL` | `PASS_VISUAL_BOUNDED_PROPOSAL_ONLY` |
| `GUIDED_UI_RES_LEI_NAVIGATION` | `PASS_VISUAL_BOUNDED_PROPOSAL_ONLY` |
| `GUIDED_UI_MULTIBOX_PRESENT` | `PASS_VISUAL_PRESENT_SELECTION_LABEL_TRUNCATED` |
| `GUIDED_UI_HASH_VERIFY` | `PASS_LOCAL_REPORTED_HASH_INTEGRITY_ONLY` |
| `GUIDED_UI_TEMPORAL_REAL_FIELD_DISPATCH` | `NOT_TESTED` |
| `GUIDED_UI_P5_INDICATOR_GUARD` | `NOT_TESTED` |
| `GUIDED_UI_END_TO_END_D2_P5` | `NOT_APPROVED` |
| `C2_FULL` / `P5_D2_UI` | `NO_GO_NOT_APPROVED` / `NOT_TESTED` |
| `F4_P5_PHYSICAL_FILTERS` / `PHASE_IX` / `PRODUCTION_APPROVED` | `NOT_TESTED_FULLY` / `NOT_AUTHORIZED` / `False` |

**STOP:** piloto já executado e encerrado no limite de navegação/variáveis. Não pedir novamente as cinco capturas, reproduzir a sequência GUI, reexecutar `-Prepare`/`-Verify` nem mexer no QVW originário para aumentar o nível de prova. PNGs e artefatos binários não foram incluídos no Git, e o SHA de verificação diz respeito ao **runner no HEAD executado** `49c48f3e...`, não ao HEAD documental atualizado por este registro.

**Nova frente independente, ainda não autorizada por este fechamento:** projetar e testar em gate próprio a tradução segura do contexto proposto em `PERIODO_ANO` / `PERIODO_COMPETENCIA` reais e a guarda P5 de um KPI sob seleção territorial simultânea. Reutilizar esta cópia e evidências somente após revalidar sua proveniência, sem reabrir C2-H/C2-I, alterar V2 ou permitir números sem cobertura CNES/LT comprovada.
