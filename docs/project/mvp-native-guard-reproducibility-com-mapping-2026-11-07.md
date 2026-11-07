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
