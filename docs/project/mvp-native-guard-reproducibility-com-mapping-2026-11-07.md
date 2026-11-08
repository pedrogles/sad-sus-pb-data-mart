# SAD MVP — F05/R1 | reprodutibilidade das guardas CH04/CH05: contrato e mapeamento COM seguro

**Data:** 07/11/2026. **Natureza:** implementação preparatória **somente declarativa + probe read-only**, sem aplicação de guardas no builder e sem teste físico realizado por este agente. **Escopo de controle:** PR [#226 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226), branch `proposal/sad-mvp-rebaseline-2026-11-07`. **Motivação:** [F03-U1](mvp-f03-lt-guard-ui-temp-2026-11-07.md) e [F04-U1/P2](mvp-f04-u1-p2-targeted-save-reopen-correction-2026-11-07.md) provaram manualmente guardas de residência/tempo em QVW TEMP; o [construtor](../../tools/Build-SadMvpThreeSheetsTemp.ps1) ainda cria nove objetos sem configurar mensagens e condições, portanto **um novo build perde as guardas**.

## 1. Fonte de verdade e autorização delimitada

Reconsultados na `main`, na ordem, `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`; depois [Boundary 7](../discovery/boundary-7-implementation-plan.md), [V3 D2-R2](../discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md), [automação QlikView/PowerShell](qlikview-powershell-automation.md) e evidências F03/F04 do #226. **Os valores/modelo canônicos seguem na `main`.** O usuário solicitou prosseguir **com a reprodutibilidade versionada** após o PASS restrito de persistência F04-U1/P2. Não autoriza merge, alterar QVW/QVD canônicos, mudar semântica, nem promover C2 físico.

**Propriedades de construção diretamente comprovadas:** o script existente `Build-SadMvpThreeSheetsTemp.ps1` chama `CreateLineChart` (M2-01) e `CreateBarChart` (M2-02), adiciona as dimensões/expressões e ajusta `GraphLayout.WindowTitle.v`, mas **não** configura `Calculation Condition` nem `Custom Error Message`. As duas guardas foram produzidas via QlikView GUI e persistiram somente em QVW TEMP.

**Referências oficiais úteis:** [QlikView — Chart Properties](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartProperties.htm) documenta Calculation Condition, e [Custom Error Messages](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Custom_Error_Messages.htm) permite mensagem calculada, mas **a documentação não comprova qual caminho COM do retorno de `GetProperties()` edita esses elementos na instalação local**. O uso de `GetSheetObject` está documentado na Automation API (e exemplificado na comunidade); seu comportamento com CH04/CH05 exige execução local.

## 2. Artefatos versionados e invariantes

1. `PAINEL/sad_mvp_native_guard_contract.json`: manifesto UTF-8 (versão 1, `status=DRAFT_COM_MAPPING_UNVERIFIED`) com apenas `CH04/M2-01` e `CH05/M2-02`. Armazena **identidade/título, expressão da condição, mensagem de erro** e `measureMustRemain` de CH05 = `Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)`. É **a definição para implementação futura**, **não** configuração aplicada ao QVW.
2. `tools/Inspect-SadMvpGuardComReadOnly.ps1`: probe Windows/PowerShell 5.1 de leitura para identificar objetos e propriedades. Exige branch e SHA, worktree limpa, paths externos, manifesto rastreado, **exatamente o QVW TEMP F04 já validado** com SHA fixo `4AF2C4BE17336AB729CF0CD70D75B7481B41AC003958EDB543584A1484047F92`. Requer `-Probe` explícito; recusa QlikView Desktop previamente aberto. Usa `GetSheetObject('CH04'/'CH05')`, `GetProperties()`, títulos e enumeração limitada de membros/paths de interesse. Saída apenas STDOUT.
3. Nenhuma alteração em `Build-SadMvpThreeSheetsTemp.ps1`, `PAINEL/PAINEL.qvw`, QVDs, QVW TEMP, `main` ou expressões de nove visuais; **não** usa `Save`, `Reload`, `SetProperties` ou seleção/edição por COM. A abertura em COM para inspeção está limitada à mesma QVW externa, com SHA antes/depois e STOP se o arquivo mudar.

**Observação de segurança:** uma sessão COM pode iniciar processo QlikView e apresentar diálogos/licenciamento; não é execução headless garantida. Fechar o QVW no Desktop antes do probe e **não executar simultaneamente** outra automação. Se QlikView impedir a leitura ou alterar o arquivo de modo inesperado, parar com erro, registrar stdout e preservar o estado.

## 3. Gate único — F05/R1 COM discovery

**Objetivo de aceitação do gate:** identificar **caminhos COM legíveis e tipados** que exponham (a) a condição de cálculo e (b) a mensagem de cálculo não satisfeita de ambos os objetos, confrontando-as com o manifesto. Não editar nenhum campo.

**Pré-condições:** `git status --short` vazio, `git pull --ff-only`, `git rev-parse HEAD` pinado ao commit do probe; QVW F04 TEMP fechado em todas as janelas, com SHA acima. Validar parser PowerShell local antes de executar.

**Comando Windows (na raiz do repositório):**

```powershell
$commit = 'REPLACE_WITH_PR_HEAD_40_CHAR_SHA'
powershell.exe -NoProfile -File .\tools\Inspect-SadMvpGuardComReadOnly.ps1 `
  -Root (Get-Location).Path `
  -ExpectedCommit $commit `
  -EvidenceRoot "$env:USERPROFILE\SAD_M1_EVIDENCIAS" `
  -Probe
```

**Critérios:**
- `PASS_DISCOVERY_ONLY`: `CHART=CH04` e `CHART=CH05` com título correto, COM membro/caminho legível de **ambas** as propriedades, identidade textual reconciliável com contrato declarativo, SHA `SOURCE_TEMP_QVW_SHA256_UNCHANGED=True`. Não confundir com implementação ou com aceite de UI.
- `INCONCLUSIVE`: membros/paths COM não expõem texto nem estrutura suficiente; projeto segue com guardas manuais preservadas; não inventar caminho de escrita.
- `BLOCKED`: SHA difere, chart ausente/título incorreto, COM falha, popup inesperado, processo Qlik aberto, alteração do arquivo; **STOP no primeiro desvio** e não reexecutar em loop.

**Evidência a retornar:** stdout completo do probe. Não há screenshot obrigatório nesta fase porque a fonte e as duas propriedades **já têm prova GUI** em F04/P2. Não repetir oráculos RD/LT/POP nem filtros do F03/F04.

## 4. Critério para edição futura do builder — NÃO realizado nesta entrega

Só após um `PASS_DISCOVERY_ONLY` conclusivo:
1. Criar atualização restrita ao builder em novo commit, consumindo o manifesto explicitamente em UTF-8, aplicando guardas **somente** nos objetos `M2-01/M2-02`, e verificando as **duas propriedades por readback COM** após `SetProperties`, sem alterar título, expressão da medida ou posição;
2. Construir **nova QVW TEMP** via fluxo protegido (originais/M1 com SHA), nunca editar o QVW já homologado; exigir nove objetos, hashes canônicos iguais, oráculos M1/M2 existentes e no máximo **três cenários de UI não repetidos** para verificar aplicação automática (neutro, RES, ano incompatível), depois parar;
3. Um possível `PASS_COM` não equivale a PASS visual nem ao aceite C2/C3/C4, nem libera GO IX ou produção. Se não houver API COM adequada, alternativa de implementação é **documentar aplicação manual reproduzível** como etapa formal e auditável, sem afirmar automação.

## 5. Estado e condição de parada

`F05_R1_GUARD_CONTRACT=VERSIONED_STATIC_CHECKED`; `F05_R1_COM_PROBE=VERSIONED_NOT_EXECUTED`; `F05_R2_BUILDER_APPLICATION=NOT_IMPLEMENTED`; `F04_U1_P2_REOPEN=PASS_GUI_RESTRICTED_WITH_LOCAL_SHA`; `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`; `C2_GUIDED_R2/C3/C4/LINK_KEY_CONTRACT/P5_GLOBAL/PHASE_IX/PRODUCTION=NOT_APPROVED`.

**STOP desta execução:** documentos + manifesto + probe de leitura versionados e PR atualizado. Nenhuma chamada COM executada aqui. A continuidade depende exclusivamente do stdout do **único probe** no Windows; não tentar aplicar/descobrir valores por adivinhação. Sem merge, sem mudança da `main` e sem nova recarga/QVD/QVW canônico.


## 6. Resultado R1 no Windows e delimitação R1B — inspeção focada

**Evidência local reportada em 08/11/2026:** o responsável executou o script versionado do commit `711e1ac555f7c8d205c62ada976666ea5f675ffb`, depois de `git status --short` limpo, `git pull --ff-only`, verificação de HEAD e parser PowerShell sem erros. O stdout veio do QlikView/COM instalado no Windows e foi **fornecido diretamente pelo operador**; não foi executado independentemente pelo agente.

```text
GIT_HEAD=711e1ac555f7c8d205c62ada976666ea5f675ffb
CONTRACT_SHA256=79E6CAC1F5AB34BE128BC53DB50C9431078091EBA6CA6B9E670FE54FD044D6E1
SOURCE_QVW_SHA256=4AF2C4BE17336AB729CF0CD70D75B7481B41AC003958EDB543584A1484047F92
NO_QVD_ACCESS=True NO_RELOAD=True NO_SETPROPERTIES=True NO_SAVE=True
CHART=CH04 VIEW=M2-01 TITLE_MATCH=True
MEMBERS_CH04_PROPERTIES_COUNT=19
MEMBERS_CH04_PROPERTIES_RELEVANT=Default|EvaluationCondition|Expressions|GraphLayout|ShowNumbersOnBarsZeroValues
MEMBERS_CH04_GRAPHLAYOUT_COUNT=9
MEMBERS_CH04_GRAPHLAYOUT_RELEVANT=Default|ErrorMessageOverrides|Frame|GraphMode|WindowTitle
CHART=CH05 VIEW=M2-02 TITLE_MATCH=True
MEMBERS_CH05_PROPERTIES_COUNT=19
MEMBERS_CH05_PROPERTIES_RELEVANT=Default|EvaluationCondition|Expressions|GraphLayout|ShowNumbersOnBarsZeroValues
MEMBERS_CH05_GRAPHLAYOUT_COUNT=9
MEMBERS_CH05_GRAPHLAYOUT_RELEVANT=Default|ErrorMessageOverrides|Frame|GraphMode|WindowTitle
COM_MAPPING_PROBE=INSPECTED_READ_ONLY_NOT_IMPLEMENTED
SOURCE_TEMP_QVW_SHA256_UNCHANGED=True
```

**FATO observado no readback COM:** ambos os IDs e títulos coincidem com o manifesto; a fonte QVW TEMP teve SHA-256 idêntico antes/depois. Foram encontrados os dois membros estruturais concretos **`EvaluationCondition`** (diretamente nas propriedades do gráfico) e **`GraphLayout.ErrorMessageOverrides`** (aninhado). As tentativas iniciais de acessar `CalcCondition` ou `GraphLayout.CalcCondition` não trouxeram texto. **Ainda não se sabe** tipo, estrutura, conteúdo nem editabilidade das duas propriedades. Não atribuir `PASS` de persistência COM ou builder. A evidência de persistência manual GUI F04-U1/P2 continua válida e separada.

**Veredito:** `F05_R1_CHART_IDENTITY=PASS_LOCAL_REPORTED`, `F05_R1_PROPERTY_MEMBER_DISCOVERY=PASS_LOCAL_REPORTED`, `F05_R1_SOURCE_HASH=PASS_LOCAL_REPORTED`, `F05_R1_EXACT_FIELD_MAPPING=INCONCLUSIVE`. O gate geral de identificação ficou encerrado: não repetir o R1 amplo.

### F05/R1B — única inspeção de valores internos sem escrita

O commit subsequente atualizou **o mesmo** `tools/Inspect-SadMvpGuardComReadOnly.ps1`, sem alterar o manifesto, para chamar `ShowTargetValue` **somente** em:
- `GetSheetObject('CH04'/'CH05').GetProperties().EvaluationCondition`;
- `GetSheetObject('CH04'/'CH05').GetProperties().GraphLayout.ErrorMessageOverrides`.

O escopo adicional enumera propriedades/metadados de tipos de retorno e tenta ler apenas campos conhecidos nominalmente (`v`, `text`, `Value`, `Expression`, `Message`, etc.) até profundidade 2; só itera `Item(0..n-1)` **se** houver propriedade `Count` e método `Item`, com teto **24**. É uma tentativa controlada de **readback**, não um contrato de escrita. Continua sem `Save`, `Reload`, `SetProperties`, exportação, novas seleções ou QVD. Mesma QVW TEMP com hash fixo `4AF2C4BE...4047F92`; se diferir, STOP.

**Comando após atualização e fecho do QlikView Desktop:**

```powershell
git status --short
git pull --ff-only
git rev-parse HEAD

$tokens=$null; $errors=$null
[System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path .\tools\Inspect-SadMvpGuardComReadOnly.ps1).Path,
  [ref]$tokens, [ref]$errors
) | Out-Null
$errors

powershell.exe -NoProfile -File .\tools\Inspect-SadMvpGuardComReadOnly.ps1 `
  -Root (Get-Location).Path `
  -ExpectedCommit 'REPLACE_WITH_PR_HEAD_40_CHAR_SHA' `
  -EvidenceRoot "$env:USERPROFILE\SAD_M1_EVIDENCIAS" `
  -Probe
```

**Critérios e STOP R1B:** ao fim do único probe, parar. `PASS_MAPPING_READ_ONLY` **somente** se stdout apresentar valores de condição e mensagens para os dois gráficos reconciliáveis com o manifesto e SHA protegido; `PARTIAL/INCONCLUSIVE` se apenas membros/estruturas, sem textos; `BLOCKED` se falha COM, hash ou ID. Não repetir R1B automaticamente ou tentar escrita no builder por suposição. Se o stdout mostrar elementos com índices desconhecidos, registrar a lacuna e decidir separadamente entre documentação oficial Automation API ou workaround manual reproduzível, antes de outro experimento.

**Estado após a publicação deste protocolo:** `F05_R1=PASS_MEMBER_DISCOVERY_LOCAL_REPORTED`; `F05_R1B=VERSIONED_NOT_EXECUTED`; `F05_BUILDER_AUTO_APPLY=NOT_IMPLEMENTED`; `F04_U1_P2=PASS_GUI_RESTRICTED_WITH_LOCAL_SHA`. `C2_GUIDED_R2/C3/C4/P5_GLOBAL/LINK_KEY_CONTRACT/PHASE_IX/PRODUCTION=NOT_APPROVED`; PR #226 Draft, `main` e QVD/QVW canônicos intocados.


## 7. R1B bloqueado no parser — causa localizada e correção única

**Execução reportada pelo operador em 08/11/2026 no Windows:** `git status --short` vazio; `git pull --ff-only`; `HEAD=7061da3b46fd9ec3581780072f6648560acdb61a`. A chamada explícita de `System.Management.Automation.Language.Parser.ParseFile` retornou **5 erros**; a tentativa seguinte de execução do mesmo script abortou **no parser**, com `UnexpectedToken`, `TerminatorExpectedAtEndOfString`, `ExpressionsMustBeFirstInPipeline`, `MissingEndCurlyBrace`, `MissingEndParenthesisInSubexpression`. Não houve qualquer saída `GIT_HEAD=`/`SOURCE_QVW_SHA256=` do runner, portanto **nenhuma abertura COM nem leitura da QVW por este script aconteceu nesta execução**.

**Causa diretamente comprovada pelo arquivo versionado:** o script no commit `7061da3` estava fisicamente corrompido: a linha do `Write-Output` dos métodos COM `TARGET_*_METHODS` foi truncada após o regex `'^(Item|GetItem|Count|GetCount)`, seguida indevidamente por um bloco `}catch{ ... }finally{ ... }` de término do script; a linha de interpolação `}) -join '|')"` foi deslocada para depois desse bloco e outro finalizador ficou duplicado. É **defeito na edição/versionamento do script**, não falha de sintaxe introduzida pelo operador nem prova de bug da API COM.

**Correção versionada em `aac9021bbf753a445ef06359b9ffc8f05eca1acb`:** removeu o bloco finalizador duplicado e substituiu a linha quebrada por duas instruções simples:

```powershell
$interestingMethods=@($methodNames | Where-Object { $_ -match '^(Item|GetItem|Count|GetCount)$' })
Write-Output ("TARGET_{0}_METHODS={1}" -f $label, ($interestingMethods -join '|'))
```

**Inspeção estática independente da correção:** o GitHub devolveu a versão corrigida com **um único** finalizador de hash, um único `TARGETED_MAPPING_VERDICT` e delimitadores `{[()]}`/aspas balanceados em verificador estático simples; **isso NÃO equivale a `Parser.ParseFile` do Windows nem a PASS COM**.

**Veredito:** `F05_R1B_ATTEMPT_7061da3=BLOCKED_POWERSHELL_PARSER`; `F05_R1B_COM_EXECUTED=False`; `F05_R1B_PARSER_ROOT_CAUSE=VERSIONED_SCRIPT_TRUNCATION_AND_DUPLICATE_FINALIZER`; `F05_R1B_FIX=aac9021bbf753a445ef06359b9ffc8f05eca1acb`; `F05_R1B_FIXED_PARSER=NOT_YET_EXECUTED_ON_WINDOWS`. R1 anterior, com identificação de membros COM, permanece `PASS_MEMBER_DISCOVERY_LOCAL_REPORTED` e não deve ser repetido. O QVW F04 TEMP validado permanece como fonte protegida SHA `4AF2C4BE17336AB729CF0CD70D75B7481B41AC003958EDB543584A1484047F92`, mas essa execução bloqueada **não trouxe nova medição do hash**.

**STOP obrigatório:** antes de tentar o probe corrigido, executar `git pull --ff-only`, verificar worktree limpa e o commit mais recente; rodar `Parser.ParseFile` sobre o script atualizado. Se retornar **qualquer** erro, **não executar o probe** e reportar a mensagem. Se estiver vazio, executar **uma única tentativa** `-Probe` com `-ExpectedCommit` igual ao HEAD atualizado. Sem Qlik aberto, sem COM `SetProperties`/`Save`/`Reload`, sem builder ou merge. Se o R1B continuar inconclusivo após uma execução sintaticamente válida, encerrar a sondagem e decidir a estratégia de implementação por outra frente.
