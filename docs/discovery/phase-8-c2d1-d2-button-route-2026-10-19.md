# Fase VIII — C2-D1: prova controlada de pré-seleção D2 por botões QlikView 12

**Estado atual:** `C2D1_QVW_COPY=PASS_LOCAL_PREPARATION_REPORTED`; `C2D1_BUTTONS_CONFIGURATION=VISIBLE_IN_GUI_CANDIDATE_ONLY` (seção 7); `C2D1_D2_1_BUTTON_ROUTE=PASS_VISUAL_RESTRICTED` (seções 8–9); `C2D1_D2_2=OBSERVED_DISABLED_POSTCLICK_OPERATOR_REPORTED_SINGLE_IMAGE` (seção 10); `C2D1_FOUR_CASES=IN_PROGRESS_2_COMPLETE_1_PARTIAL_OF_4`; `D2_3_BUTTON_ROUTE=PASS_VISUAL_RESTRICTED`; `D2_4=OBSERVED_BOTH_SELECTED_ORIGIN_UNCONFIRMED`; `P5_D2_UI=NOT_TESTED`; `C2_FULL=NOT_APPROVED`; `PRODUCTION_APPROVED=False`. PR Draft originado de `main@337943d5c5b77067f842902fc679dbb68db87020`, sem merge.

## 1. Contrato de objetivo único e fontes

**Objetivo delimitado:** testar, em **caminho de interface controlado por dois botões**, se uma proposta de período conflitante é recusada **antes** de qualquer ação de seleção e se duas propostas compatíveis são aplicadas sem perder o período já selecionado. Não é teste de política P5 global, de bloqueio de todo o campo ou do painel final.

**Fontes verificadas:** em ordem, `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` da `main`. Específicas: `docs/discovery/boundary-7-implementation-plan.md`, contrato semântico V2 `62 (D2 e P5), `docs/project/qlikview-powershell-automation.md`, diagnóstico C2-D [PR #121](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/121), evidência visual C2-W [PR #120](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/120), pré-despacho wrapper D2 [PR #111](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/111). PRs Draft não representam integração na `main`.

**FATO DOCUMENTADO em fonte oficial QlikView:**
- [Botão — Condição para Habilitar](https://help.qlik.com/pt-BR/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Button2.htm): resultado `0` desabilita, resultado `1` habilita o botão.
- A mesma página descreve a ação **Selecionar no Campo**: recebe campo e caracteres de busca, podendo selecionar valores numéricos sem aspas.
- [Seleção de valores nos campos](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Select_field_values.htm) explica que clicar um valor excluído pode cancelar seleção conflitante. Portanto, acionar diretamente listboxes/buscas **não garante D2**.
- Triggers `OnSelect` e `OnAnySelect` são pós-seleção: **não aprovados como guarda pré-despacho**, conforme PR #121.

**HIPÓTESE FÍSICA:** dois botões nativos poderão usar `Condição para Habilitar` com `GetSelectedCount` e `GetFieldSelections`, oferecendo apenas **uma ação única de Selecionar no Campo** por botão. Sua eficácia nesta instalação QlikView 12 Personal Edition **ainda não foi medida**. Expressões a seguir são **candidatas**; são avaliadas na GUI, não inventadas como membro de automação COM.

## 2. Limites e preparação segura

**Executor versionado antes do teste:** `tools/Prepare-SadPhaseViiiC2d1D2ButtonRoute.ps1`. Exclusivamente cria **uma cópia** do QVW de prova:
- Origem TEMP existente: `%TEMP%\SAD_VIII_C2W_04f58b85152b4794b0bf4809b4e10f3c\SAD_C2W_T26_COLUNAS_AJUSTADAS_WRAP.qvw`.
- Saída nova em `%TEMP%\SAD_VIII_C2D1_<GUID>\SAD_C2D1_D2_BUTTON_TEST.qvw`, registrada como `COPY_FOR_GUI` no stdout. Manifesto `prepare_manifest.json` com HEAD/sha de script e arquivo/oráculos de integridade.
- **Pré-condição:** fechar a origem C2-W na UI antes de rodar. O script recusa fonte ausente ou janela da origem aberta; exige branch, HEAD versionado e script limpo.
- Exige inventário **10 QVDs de extração + 12 de transformação** e registra SHA-256 antes/depois; compara também QVWs canônicos encontrados e QVW TEMP de origem. Em caso de divergência, lançar erro crítico. **Sem COM, Reload, STORE, escrita de dados, PDF ou dashboard canônico.**
- Resultado `PASS_LOCAL_C2D1_QVW_COPY_ONLY_UI_BUTTONS_NOT_CONFIGURED` atesta **somente a preparação da cópia**; não configura botões e **não** é prova D2.

**Confirmação de interface obrigatória:** a cópia deve abrir na própria estação sem reload, com os campos já observados `PERIODO_ANO` e `PERIODO_COMPETENCIA` disponíveis. Se `PERIODO_COMPETENCIA` não puder ser exibido como listbox para montar estado inicial, **STOP**. Não modificar QVW de origem.

## 3. Dois botões candidatos (configuração manual somente na cópia C2-D1)

Criar no QlikView Desktop via **Objeto/Novo Objeto de Pasta → Botão** (nome/posição do menu podem variar) os objetos:

### BU — Propor competência 201801

- Texto do botão: **Propor competência 201801**.
- `Condição para Habilitar`, expressão proposta:

~~~qlik
=If(
  GetSelectedCount(PERIODO_ANO)=0,
  1,
  If(
    GetSelectedCount(PERIODO_ANO)=1
    and GetFieldSelections(PERIODO_ANO)='2018',
    1, 0
  )
)
~~~

- Aba **Ações → Adicionar → Seleção → Selecionar no Campo**. Campo: `PERIODO_COMPETENCIA`; caracteres de busca: `201801`. **Somente essa ação.** Não adicionar `Limpar Campo`, `Limpar Tudo`, triggers, macros nem ações de exportação.
- A condição esperada é `0` sob ano `2019`, `1` sob ano `2018`, e `0` com múltiplos anos selecionados.

### BU — Propor ano 2019

- Texto do botão: **Propor ano 2019**.
- `Condição para Habilitar`, expressão proposta:

~~~qlik
=If(
  GetSelectedCount(PERIODO_COMPETENCIA)=0,
  1,
  If(
    GetSelectedCount(PERIODO_COMPETENCIA)=1
    and Left(GetFieldSelections(PERIODO_COMPETENCIA),4)='2019',
    1, 0
  )
)
~~~

- **Uma ação:** `Seleção → Selecionar no Campo`. Campo: `PERIODO_ANO`; busca: `2019`.
- Condição esperada `0` sob competência `201801`, `1` sob `201901`, `0` se múltiplas competências selecionadas.

**Atenção:** essas condições são candidatas. Se ao abrir a interface o valor da condição não resultar no estado habilitado/desabilitado esperado, **BLOCKED**, não supor que o controle funcione. O separador de argumentos na instalação anterior do QlikView foi vírgula nas expressões testadas; não converter sintaxe sem inspeção. Antes de clicar em um botão **desabilitado**, registrar screenshot; não tentar forçar execução por macro/COM.

## 4. Matriz de quatro casos — uma tentativa controlada

Apenas na cópia C2-D1: adicionar **uma lista de teste** para `PERIODO_COMPETENCIA` se necessário e um objeto **Seleções Atuais** para documentar ambas as seleções. A lista nativa é **instrumento de montagem do estado**, não rota D2 aprovada. Em cada caso, **Limpar** e montar estado inicial diretamente nos campos, antes de avaliar os botões. Para valores excluídos ou configurações de seleção inconsistentes na montagem, STOP; não inferir que os botões consertaram conflitos.

| Caso | Estado inicial | Proposta via botão | Esperado ANTES e DEPOIS do clique |
| --- | --- | --- | --- |
| **D2-1** | `PERIODO_ANO=2019`; competência não selecionada | Botão mês `201801` | **Desabilitado**; ano 2019 preservado; mês continua sem seleção; clicar no botão desabilitado não aplica ação |
| **D2-2** | `PERIODO_COMPETENCIA=201801`; ano não selecionado | Botão ano `2019` | **Desabilitado**; mês 201801 preservado; ano continua sem seleção |
| **D2-3** | `PERIODO_ANO=2018`; mês não selecionado | Botão mês `201801` | **Habilitado**; após clicar, mês 201801 e ano 2018 permanecem selecionados |
| **D2-4** | `PERIODO_COMPETENCIA=201901`; ano não selecionado | Botão ano `2019` | **Habilitado**; após clicar, ano 2019 e mês 201901 permanecem selecionados |

**Capturas exigidas:** uma imagem **antes** e outra **depois** para cada caso, com ambos os botões e seleções atuais visíveis (**8 PNGs no máximo**), mais uma imagem da configuração de condição/ação de **cada botão** (seis imagens adicionais no máximo quando úteis). O QlikView pode alterar/descartar seleção ao clicar em valor excluído diretamente na listbox; evitar esse clique durante a proposta. Provar que o **botão** recusou a proposta, não que uma lista excluiu valores por associação.

**Evidência de ação despachada ou não:** capturas devem demonstrar que o botão já aparecia desabilitado **antes do clique** e que as seleções preservaram seus valores **depois do clique**. Isso é evidência visual e de estado, não telemetria de despacho interno; não declarar `DISPATCHED=False` medido por interceptação quando houve apenas screenshot. Se não houver prova objetiva de dispatch, registrar `DISPATCH_INFERRED_ONLY_NOT_INSTRUMENTED`.

**Critério PASS estritamente candidato:** todos os 4 estados esperados no caminho do botão, com legibilidade e seleção preservada onde exigida, sem ação secundária inesperada; conferir screenshots independentemente antes de fechar `C2D1_BUTTON_ROUTE=PASS_VISUAL_RESTRICTED`. Caso falhe o primeiro, **STOP** sem repetir variações nem permitir que trigger pós-seleção substitua controle.

## 5. Limitações, guardas e STOP

1. A interface permite escolhas fora dos botões por listas, buscas, bookmarks e outros objetos. Portanto, mesmo 4/4 PASS **não demonstram proteção D2 para o campo inteiro**. O caminho do botão pode ser comprovado, mas `C2D_COMPLETE_UI=NOT_APPROVED`.
2. Botões só propõem ano 2019 e mês 201801. Não existe seletor dinâmico homologado de quaisquer anos/meses; rejeitar generalização para 2017–2019, períodos múltiplos ou todos os filtros P5.
3. O gráfico T26 continua contendo ressalva CNES/LT (cobertura hospitalar histórica não verificada e **não é taxa de ocupação**); isso não é validação de novos indicadores.
4. **Parada desta execução:** após script de cópia versionado + uma configuração manual dos dois botões + **quatro cenários ou primeira falha**. Não implementar novos scripts por falha de COM, não repetir T24–T26, C2-W, C1, C3, C4, nem promover Fase IX.
5. Nenhum merge ou modificação na `main` sem autorização. Não salvar a origem C2-W; qualquer alteração visual para o experimento deve ficar **somente na cópia C2-D1**.

**Gates preservados:** `C2_FULL=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## 6. Execução local reportada — PASS apenas da cópia temporária (19/10/2026)

**Proveniência:** stdout Windows PowerShell fornecido pelo responsável; **não foi aberta nem conferida independentemente** a cópia de QVW nem o manifesto local. O wrapper executou `git fetch origin`, criou a branch local rastreando `origin/test/phase-viii-c2d1-d2-button-route-20261019`, confirmou o HEAD e emitiu `PARSER=PASS` antes do `-Prepare`.

**Commit que foi realmente executado:** `f578106467ed01856425b496f777d520c88e6762`. **Script SHA-256 do stdout:** `463B9ED3DA6F045552A9F24E8AF1BD931C3C4F6B297AEE5304F1DC15B365AE02`. **QVW de origem, SHA-256 preflight:** `4B17498BB506273E3BABF211E96B3FDBE833D5F3365479971CCD3FA68DD89A8C`.

**Diretório somente Windows, não acessado pelo agente:** `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe`. **Nova cópia exclusivamente temporária:** `C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw`.

O executor indicou:
- `MODE=TEMP_COPY_NO_COM_NO_RELOAD_NO_QVD_WRITE`;
- `SOURCE_WRAP_QVW_SHA256_UNCHANGED=True`;
- `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`;
- `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`;
- `VERDICT=PASS_LOCAL_C2D1_QVW_COPY_ONLY_UI_BUTTONS_NOT_CONFIGURED`.

**Interpretação estrita:** o resultado reporta cópia com SHA conferido e preservação das fontes antes/depois no Windows. **Nenhum botão foi criado, nenhuma ação foi testada, nenhuma seleção conflitante foi proposta via UI e nenhum screenshot D2 foi recebido**. O runner não abriu QlikView e não aferiu propriedades COM de Button nem configuração de `Enable Condition`. `C2D1_QVW_COPY=PASS_LOCAL_PREPARATION_REPORTED` não significa `C2D1_BUTTON_ROUTE=PASS`.

**Próximo passo, sem rerun PowerShell:** abrir **somente a nova cópia QVW**, não a origem `WRAP`; no QlikView Desktop 12 testar inicialmente se os controles **Condição para Habilitar** e **Selecionar no Campo** estão disponíveis. Configurar somente os dois botões documentados na seção 3, com as expressões e **uma ação cada**, e montar um objeto observacional de seleções para confirmar estados. Se indisponíveis ou se o botão não respeitar condição, **STOP**. Capturar configuração dos botões e depois, se validada, os quatro casos da seção 4. O `PR #122` permanece Draft; o comando de preparação **não precisa ser repetido**.

**Gates inalterados:** `C2D1_BUTTON_UI=NOT_CONFIGURED`, `C2D1_FOUR_CASES=NOT_TESTED`, `C2D_COMPLETE_UI=NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `T26_GENERAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. `main` não alterada.


## 7. Conferência independente de seis capturas GUI — dois botões configurados, D2 não testado

**Fonte e qualificação:** seis PNGs enviados diretamente nesta conversa e inspecionados visualmente; resoluções e hashes SHA-256 calculados **sobre os arquivos anexados**, não os screenshots C2-W anteriores. Não houve abertura independente do QVW binário nem leitura COM das propriedades persistidas. A barra do QlikView identifica a cópia `SAD_C2D1_D2_BUTTON_TEST.qvw` em `%TEMP%/SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe`, com `*` visível no título, indicando trabalho ainda não salvo na captura.

| PNG anexado | Dimensões | SHA-256 calculado | Evidência limitada |
| --- | --- | --- | --- |
| `image(20261019-162331).png` | 1670×1041 | `9C72D22469D07E7E4A5ADD707ED8A691AB239C81ADC989D69033C1419B535BB0` | Propriedades gerais de `BU01`, campo `Condição para Habilitar` preenchido |
| `image(20261019-162348).png` | 1665×1021 | `2D9744B8AD3E684300B4E14A44844861171C5D5F9B7967CBCFBBF41423E555DB` | Editor da condição BU01: `GetSelectedCount(PERIODO_ANO)=0` ou um ano selecionado igual a `2018`; editor indica `Expression OK` |
| `image(20261019-162401).png` | 1667×995 | `E06D23EE8E276408B1FC6B9B53A5BE23A6FD56E7A26A897B59B7A5EB669D61FF` | BU01, única ação `Selecionar no Campo` com `PERIODO_COMPETENCIA` e `Pesquisar Caracteres=201801` |
| `image(20261019-162413).png` | 1666×1017 | `718303AC6AB5BA9501B757AA1E737E07FFD193CF7FF1E1F26E16A61662A42347` | Propriedades gerais de `BU02`, campo `Condição para Habilitar` preenchido |
| `image(20261019-162531).png` | 1668×1041 | `C5762DCEE056CEE2D129DF3DF0D4DD4368289E8B62F95EC64E5770D286754E85` | Editor da condição BU02: `GetSelectedCount(PERIODO_COMPETENCIA)=0` ou uma competência cujo ano é `2019`; editor indica `Expression OK` |
| `image(20261019-162559).png` | 1667×1036 | `D809A626F8A4EA5EF8F28DE90C74880D57EBAEC5A565A6367C141B0B7E87A216` | BU02, única ação `Selecionar no Campo` com `PERIODO_ANO` e `Pesquisar Caracteres=2019` |

**Constatação visual:** configuração das duas ações e expressões **consistente com a proposta da seção 3**; as propriedades do editor indicam apenas **validade sintática**, não valor 0/1 avaliado, interceptação da seleção, execução ou persistência final. Há listbox `PERIODO_COMPETENCIA` visível, assim como `PERIODO_ANO`. **O BU02 está visualmente sobreposto à lista de anos**, então recomenda-se reposicioná-lo em área livre **somente na cópia C2-D1**, sem alterar expressão ou ação, para possibilitar montar o estado inicial. O componente `Seleções Atuais` não está visível; usar listboxes ou adicioná-lo no protótipo antes de fotografar os estados.

**Classificação:** `C2D1_BUTTONS_CONFIGURATION=VISIBLE_IN_GUI_CANDIDATE_ONLY`; `C2D1_BUTTON_ACTIONS=VISUALLY_CONFIGURED_NOT_TRIGGERED`; `C2D1_FOUR_CASES=NOT_TESTED`; `C2D1_PRESELECT_DISPATCH=NOT_INSTRUMENTED`; `P5_D2_UI=NOT_TESTED`. `C2D_COMPLETE_UI=NOT_APPROVED` e `PRODUCTION_APPROVED=False`; PR #122 Draft, nenhum merge ou alteração de `main`.

**Próximo passo único (sem PowerShell):** fechar as propriedades confirmando em OK, mover BU02 para não bloquear a listbox de ano, salvar **somente** a cópia C2-D1 e iniciar D2-1: `Limpar` → selecionar **exclusivamente** `PERIODO_ANO=2019`, sem competência → obter um PNG com botão de competência `201801` visualmente desabilitado e ano preservado. Antes de avançar, enviar screenshot para revisão. **Se o botão não ficar desabilitado, STOP**; não clicar nem iterar outros casos. Em eventual confirmação de estado desabilitado, a segunda captura (depois de tentativa normal de clique, sem forçar) deverá mostrar ano 2019 ainda selecionado e nenhuma competência; isso não é instrumentação interna de `DISPATCHED=False`. Não reexecutar D2 wrapper nem outros gates.


## 8. Pré-clique D2-1 — botão de competência 201801 desabilitado sob ano 2019 (19/10/2026)

**Evidência visual diretamente inspecionada:** screenshot anexado `image(20261019-174343).png`, **1907×1068 pixels, RGBA**, SHA-256 **`808F196450E93078B26FA8CBBCF6C63B6B3007143216F9448997ED0A77751050`**, calculado independentemente sobre os bytes da imagem recebida. Não houve acesso ao binário QVW nem leitura COM dos campos pelo agente.

**Fatos no quadro:** `PERIODO_ANO=2019` em verde, `PERIODO_COMPETENCIA` sem seleção verde visível, lista de meses com valores de 2019 possíveis; `BU01 — Propor competência 201801` aparece **cinza/desabilitado antes de qualquer clique**; `BU02 — Propor ano 2019` aparece azul/habilitado. Botão 2 agora está em área livre e não sobrepõe a lista de ano. O gráfico T26 está `Condição de cálculo não satisfeita` nesta seleção; isso **não representa falha D2**, pois não houve seleção de serviço neste recorte e o T26 tem sua própria condição de cálculo.

**Conclusão restrita:** o estado **anterior** à proposta incompatível corresponde a D2-1: `C2D1_D2_1_PRECLICK=PASS_VISUAL_RESTRICTED`. A imagem demonstra desabilitação visual preventiva do **botão específico**, não comprova que o evento de clique seja ignorado, não instrumenta `DISPATCHED=False`, não mostra a preservação de seleção após tentativa e não impede mudanças por listbox/busca/bookmark. Portanto `C2D1_D2_1_POSTCLICK=NOT_TESTED` e nenhum dos quatro casos está totalmente concluído.

**Único próximo passo, sem PowerShell:** na mesma cópia TEMP e mantendo 2019 selecionado, tentar um clique **normal** no botão cinza BU01 (sem invocar macro ou outra rota); capturar a folha inteira após, mostrando ano 2019 ainda selecionado, nenhuma competência selecionada e BU01 ainda cinza. Se qualquer seleção mudar, **STOP**; não executar D2-2/3/4. Se permanecer estável, a observação sustentará no máximo `D2_1_BUTTON_ROUTE_PRESELECT=PASS_VISUAL_RESTRICTED` após auditoria da nova imagem, sem afirmar telemetria interna de dispatch. **PR Draft, nenhum merge,** `P5_D2_UI=NOT_TESTED`, `PRODUCTION_APPROVED=False`.


## 9. Pós-tentativa D2-1 — ano preservado e competência não selecionada

**Evidência independente da imagem:** `image(20261019-175726).png`, resolução **1907×1068 RGBA**, SHA-256 **`1CDAAE9353BE93FEE277194D8376B47048D705439771D5DFF7771BB6174A3433`**, calculado sobre o arquivo recebido. Captura enviada pelo responsável **em resposta ao procedimento de clicar normalmente uma vez no BU01 desabilitado**. A imagem, por si, não grava o evento físico de clique; a tentativa é **relato contextual do operador**.

**Comparação visual com o pré-clique, seção 8:**
- `PERIODO_ANO=2019` continua selecionado em verde na lista.
- `PERIODO_COMPETENCIA` continua sem destaque verde/seleção explícita; os meses de 2019 são possíveis, 200801 permanece excluído/cinza.
- `BU01 — Propor competência 201801` continua cinza/desabilitado; `BU02 — Propor ano 2019` permanece azul/habilitado.
- Não se observa efeito da proposta incompatível nem descarte de ano. A mensagem T26 `Condição de cálculo não satisfeita` já existia antes, sem relação demonstrada com dispatch D2.

**Veredito restrito:** `C2D1_D2_1_PRECLICK=PASS_VISUAL_RESTRICTED` e `C2D1_D2_1_POSTCLICK=PASS_VISUAL_RESTRICTED`. Assim, **`C2D1_D2_1_BUTTON_ROUTE=PASS_VISUAL_RESTRICTED`**, exclusivamente para o BU01 controlado 201801 × ano 2019. O agente não fez medição COM de disparo de ação; **`DISPATCH_INFERRED_ONLY_NOT_INSTRUMENTED`**. Não inferir bloqueio em outras seleções diretas, bookmarks, buscas ou todo o período 2017–2019.

**Próximo caso, sem alterar script/SQL/QVD/QVW canônico:** na **mesma cópia C2-D1**, `Limpar` todas as seleções, escolher **apenas `PERIODO_COMPETENCIA=201801`** na listbox, deixando `PERIODO_ANO` sem seleção explicitamente verde. Antes de qualquer clique, capturar estado com `BU02 — Propor ano 2019` desabilitado/cinza. **Se BU02 permanecer habilitado, STOP** e não testar botão. Somente após a inspeção da imagem pré-clique haverá autorização sequencial para a tentativa. `C2D1_D2_2=NOT_TESTED`; `C2D1_FOUR_CASES=IN_PROGRESS_1_OF_4_COMPLETE`, `P5_D2_UI=NOT_TESTED`, `PRODUCTION_APPROVED=False`. PR #122 Draft, `main` inalterada.


## 10. D2-2 — mês 201801 selecionado e proposta de ano 2019 bloqueada (19/10/2026)

**Fonte primária e qualificação:** `image(20261019-184806).png` recebida diretamente nesta conversa, inspeção visual; resolução **1904×1066, RGBA**, SHA-256 **`177DF017AA4690F6CF4335C6D2E9EACFDFE363EEF66F6E50331A5474BE92EAEF`** calculado independentemente sobre o PNG recebido. O responsável declarou na mesma mensagem: **“o clique tbm nao acontece”**, referindo-se à tentativa no botão cinza. É um relato de interação feito pelo operador, não telemetria de ação. A imagem isolada não distingue estado antes/depois.

**FATOS VISUAIS OBSERVADOS:** `PERIODO_COMPETENCIA=201801` aparece verde; `PERIODO_ANO` não tem nenhum valor verde selecionado, embora `2018` esteja branco/possível por associação; `BU02 — Propor ano 2019` está cinza, desabilitado; `BU01 — Propor competência 201801` está azul, habilitado. Não se vê ano 2019 selecionado nem perda de competência 201801. O gráfico T26 apresenta `Condição de cálculo não satisfeita` e texto metodológico de período parcial; isso não é prova de falha de D2, pois gráfico é condicionado separadamente. O título superior 2018 João Pessoa é estático no protótipo e não deve ser usado como prova de seleções.

**Interpretação estrita:** `D2_2_DISABLED_STATE=PASS_VISUAL_RESTRICTED`; `D2_2_POSTCLICK_NO_EFFECT=OPERATOR_REPORTED_SINGLE_FRAME_CONSISTENT`. A condição D2-2 é **visualmente consistente** com o comportamento exigido, sem indício de modificação indevida. Entretanto, o protocolo da seção 4 prevê duas capturas separadas, antes e depois, e aqui foi fornecida **uma única imagem com relato**. Assim, `C2D1_D2_2=OBSERVED_DISABLED_POSTCLICK_OPERATOR_REPORTED_SINGLE_IMAGE` e **não** `D2_2=PASS_TWO_FRAME_AUDITED`. Não alterar a contagem de casos plenamente documentados: `C2D1_FOUR_CASES=IN_PROGRESS_1_COMPLETE_1_PARTIAL_OF_4`.

**Encaminhamento delimitado:** sem repetir automatização C2-D2/C2-D3 (ambos encerrados com NO-GO), iniciar D2-3 na **mesma cópia QVW**: `Limpar`, escolher **somente `PERIODO_ANO=2018`**, deixar competência sem seleção verde, conferir `BU01` habilitado/azul; obter screenshot **antes de clicar**, para validação; só depois testar proposta compatível `201801`. Se BU01 não ficar habilitado, **STOP**. A conclusão dos quatro cenários e D2 global permanecem pendentes.

**Gates preservados:** `P5_D2_UI=NOT_TESTED`, `C2_FULL=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `PRODUCTION_APPROVED=False`. PR #122 Draft; `main` inalterada; sem merge.


## 11. D2-3 — pré-clique de ano 2018 com proposta de competência 201801 (19/10/2026)

**Evidência visual inspecionada:** `image(20261019-185133).png`, **1907×1068 RGBA**, SHA-256 **`ADF6F7E7B4F4C2C90D1EA7D25D777DF8A58E5176A5855511FCB9D84A1AB8E3C0`**, obtido com `sha256sum` sobre o arquivo PNG anexado. Esta é a **captura anterior ao clique**; nenhuma tentativa no BU01 foi reportada para este estado.

**FATOS VISUAIS:** `PERIODO_ANO=2018` aparece verde/selecionado; `PERIODO_COMPETENCIA` apresenta `201801` como valor possível, **sem competência explicitamente verde**; `BU01 — Propor competência 201801` aparece azul/habilitado; `BU02 — Propor ano 2019` também azul/habilitado, coerente com a condição de BU02 que depende da seleção de competência, ainda vazia. `Condição de cálculo não satisfeita` permanece no gráfico T26, que possui gate próprio e não serve como oráculo D2. O título T26 é estático e não prova seleções.

**Veredito estrito:** `D2_3_PRECLICK=PASS_VISUAL_RESTRICTED`. O botão estava disponível sob proposta compatível antes de aplicar a ação. **Ainda não há evidência de que um clique em BU01 selecione efetivamente `201801` preservando `PERIODO_ANO=2018`**, nem de que o botão exerça sua única ação sem efeitos colaterais: `D2_3_POSTCLICK=NOT_TESTED`; `D2_3_FULL=NOT_APPROVED`.

**Próximo passo único:** sem limpar ou modificar outras seleções, clicar **uma vez normalmente** em `Botão 1 — Propor competência 201801`. Tirar captura da folha completa **depois do clique**, com `PERIODO_ANO=2018` e `PERIODO_COMPETENCIA=201801` em verde; se algum desses valores não for preservado, **STOP** e não iniciar D2-4. Sem automação UIA, COM, reload, scripts nem QVW/QVD canônico alterados.

**Gates:** `P5_D2_UI=NOT_TESTED`, `C2_FULL=NOT_APPROVED`, `PRODUCTION_APPROVED=False`, PR #122 Draft e `main` inalterada.


## 12. D2-3 — pós-clique compatível: ano 2018 preservado e competência 201801 selecionada (19/10/2026)

**Evidência anexa conferida:** `image(20261019-185338).png`, **1907×1060 pixels, RGBA**, SHA-256 **`972D66582EFF3A252AC8521E73DF14765058768F24DB1019F253F8E2F3B977FD`** calculado independentemente com `sha256sum` no arquivo PNG fornecido. Trata-se da captura enviada em resposta à instrução de clicar **uma vez normalmente no BU01**. Essa correspondência de ação é proveniente do fluxo contextual do operador; uma imagem estática não instrumenta o evento físico nem a ordem de despacho.

**FATOS VISUAIS do pós-clique comparados à captura anterior (§11):** `PERIODO_ANO=2018` aparece verde e continua selecionado; `PERIODO_COMPETENCIA=201801` passou a verde; `BU01` continua azul/habilitado e `BU02 — Propor ano 2019` passou a cinza/desabilitado, consistente com a nova seleção de competência de 2018. A mensagem `Condição de cálculo não satisfeita` e o aviso de período parcial pertencem ao objeto T26 e não mudam o veredito de seleção D2.

**Veredito restrito:** `D2_3_PRECLICK=PASS_VISUAL_RESTRICTED`, `D2_3_POSTCLICK=PASS_VISUAL_RESTRICTED`, portanto **`D2_3_BUTTON_ROUTE=PASS_VISUAL_RESTRICTED`**, somente para o percurso controlado `ano 2018 → proposta de competência 201801`. **Sem instrumentação interna de despacho**, sem aprovação global da UI e sem teste do indicador T26. Na matriz atualmente há **2 casos com pré/pós capturas auditadas restritamente (D2-1 e D2-3), 1 com captura única mais relato de clique (D2-2) e 1 não iniciado (D2-4)**; não tratar D2-2 como 2-frame auditado.

**Próximo teste isolado D2-4:** na cópia QVW C2-D1, `Limpar` e selecionar **apenas `PERIODO_COMPETENCIA=201901`**; `PERIODO_ANO` sem seleção explícita. Antes de qualquer clique, capturar folha mostrando `BU02 — Propor ano 2019` **azul/habilitado**. Não executar o botão até revisar a captura. Se BU02 ficar desabilitado, STOP. Preservar PR Draft e fontes imutáveis; `D2_4=NOT_TESTED`, `P5_D2_UI=NOT_TESTED`, `PRODUCTION_APPROVED=False`.


## 13. D2-4 — captura mostra ambas as seleções; origem da ação não confirmada (19/10/2026)

**Evidência visual diretamente inspecionada:** `image(20261019-185639).png`, **1905×1068 pixels, RGBA**, SHA-256 **`3A50095F9A8E5F57E0AA43818A9A9E9EC80B1B5729840C5EC809B26055B9C1B3`**, calculado localmente a partir do anexo recebido. A captura veio em resposta ao pedido de **imagem pré-clique**. Não há, na mensagem, declaração de que o operador clicou em BU02, nem imagem anterior com apenas a competência selecionada.

**FATO VISUAL VERIFICADO:** `PERIODO_COMPETENCIA=201901` aparece verde e `PERIODO_ANO=2019` também aparece verde, simultaneamente; `BU02 — Propor ano 2019` está azul/habilitado e `BU01 — Propor competência 201801` cinza/desabilitado. O estado é **consistente com um resultado pós-clique de BU02**, mas também poderia resultar de seleção direta do ano na listbox. O título T26 de 2018/João Pessoa e o aviso de período parcial 201801 são conteúdos fixos/condicionados independentes das seleções e não validam D2-4.

**DECISÃO DE EVIDÊNCIA:** `D2_4_BOTH_SELECTED=PASS_VISUAL_STATE_ONLY`; `D2_4_BUTTON_CLICK=NOT_CONFIRMED`; `D2_4_PRECLICK=NOT_CAPTURED`; **`D2_4=OBSERVED_BOTH_SELECTED_ORIGIN_UNCONFIRMED`**, sem emitir PASS de rota ou de despacho. Manter contador anterior de casos encerrados (D2-1/D2-3 PASS visual restrito; D2-2 parcial). `P5_D2_UI=NOT_TESTED`, `PRODUCTION_APPROVED=False`.

**Única pendência necessária:** perguntar ao responsável **como 2019 ficou verde**: se clicou em BU02 depois de selecionar 201901 ou selecionou manualmente 2019 pela lista. Se foi BU02, a imagem pode ser qualificada como pós-clique relatado, ainda sem captura pré-clique; se foi lista, não serve como evidência da execução de BU02 e requer retomar o teste controlado. Não repetir outras Discovery/COM/UIA, sem merge na `main`.
