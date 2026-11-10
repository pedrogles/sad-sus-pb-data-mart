# SAD — VIS-02-P1 | Correção mínima de legibilidade CH06/M2-03 (10/11/2026)

**Natureza:** especificação + runbook de aplicação GUI nativa, SEM execução Windows nesta preparação. **Objetivo único:** remover a sobreposição dos códigos técnicos do eixo no gráfico `CH06` (M2-03) e exibir explicações curtas e legíveis, sem alterar categoria, dimensão, medida, dados ou associação. Origem do bloqueio: evidência direta de oito PNGs no [VIS-03 Draft #232](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/232), seção 6 de `docs/project/sad-vis-03-documentary-audit-and-pending-gui-2026-11-10.md`.

## 1. Autoridade e evidência já existente

Fontes lidas nesta ordem em `main`: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md`. Depois: [Draft #226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226) (script `tools/Build-SadMvpThreeSheetsTemp.ps1`, QVS `PAINEL/sad_p23_a1_island_physical_gate.qvs`, consolidação C3/C4), [#230](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/230) (VIS-01 aprovado), [#231](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/231) (VIS-02 closeout) e [#232](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/232) (VIS-03 bloqueio visual).

Fontes externas oficiais consultadas: [QlikView 12 — propriedades do gráfico de barras (pt-BR, documentação September 2026)](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Bar_Chart.htm) e [versão em inglês](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Bar_Chart.htm). Estas descrevem:
- **Dimensões → Mostrar legenda**: exibe/oculta nomes dos valores da dimensão no eixo. **Dimensões → Rótulo** altera o nome do campo, não os valores técnicos; não usar como solução falsa.
- **Apresentação → Textos do gráfico (Text in Chart)**: adicionar texto livre dentro do gráfico, ajustar fonte/fundo e reposicionar no layout. Não acrescenta um novo objeto de folha.
- **Eixos** permitem orientar rótulos, mas girar 40+ caracteres pode apenas criar outro tipo de sobreposição.
- O suporte nativo documentado não constitui prova de persistência/posição na versão e resolução efetivamente instaladas: exigir screenshot da cópia.

**Estado de execução desta preparação:** `SCRIPT_NOT_CREATED`, `WINDOWS_NOT_ACCESSED`, `QVW_EDIT_NOT_RUN`, `RELOAD_NOT_RUN`, `MAIN_UNCHANGED`.

## 2. Contrato físico/semântico intocado

Objeto físico: `CH06`, visual `M2-03`, aba **Leitos Cadastrais Observados**; ilha `P23_A1_ISLAND`.

A documentação/script do Draft #226 define:
- **Dimensão exata**: `P23_ESTADO_OBSERVADO`.
- **Medida exata**: `Count(P23_MUNICIPIO_6)`.
- **Título vigente**: `Observabilidade LT | PB 2017–19 | sem filtros globais`.
- **Três códigos originais, todos preservados**:
  - `ABSENT_NOT_ZERO_PROVEN` — ausência de linha LT no universo observado; **não significa zero**.
  - `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED` — registro LT observado com `QT_SUS>0`; **não certifica recorte hospitalar**.
  - `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` — registro LT observado com `QT_SUS=0`; **não prova cobertura integral de leitos**.
- **Oráculos anteriores, não recalculados nesta correção**: respectivamente **4.467 / 3.464 / 97** células município × competência no período 2017–2019; universo 8.028. Não traduzir como municípios únicos nem capacidade hospitalar operacional.

**Não tocar** `Dimensions` (campo/expressão), `Expressions`, `Calculation Condition`, `Show Conditional`, `Alternate State`, `Sort`, `Dimension Limits`, `QVS`, `QVD`, quaisquer outros 8 objetos, `CH05`/`CH09` ou condições de seleção. Proibido recalcular ou renomear dados, criar categorias, usar `Pick()`/`Match()`/`Dual()`, executar builder/Reload/COM, fazer merge ou publicar produto.

A main ainda tem 14 visuais no blueprint e C2/C3/C4/IX não aprovados. A mudança é **somente no MVP acadêmico TEMP do Draft #226**.

## 3. Solução preferencial (GUI-only, sem semântica)

**Estratégia:** ocultar apenas o texto longo dos valores no eixo de `CH06` e substituir por um **texto explicativo dentro do mesmo gráfico**, com correspondência inequívoca entre cor observada e classificação. Não esconder o valor pelo qual o QlikView agrupa os registros.

Legenda compacta **candidata**, a conferir contra cores reais da cópia:

```text
Âmbar — Sem linha LT (não significa zero)
Verde-azulado — SUS positivo observado
Cinza — SUS zero observado
Escopo hospitalar não verificado
```

Os rótulos de cor devem corresponder às três barras exibidas em **estado neutro** na captura aprovada. Texto livre é legenda descritiva da apresentação, não valor de campo nem resultado de expressão. Se as cores mudarem em função de seleção na própria ilha, e a correspondência deixar de ser inequívoca, **BLOCKED**: não aceitar legenda estática enganosa. Não confiar em cor como único canal de informação; manter o texto completo visível.

**Trade-off:** configuração estática exige ajuste de posição e pode ocupar parte da área útil. Se não houver espaço suficiente sem cobrir barras, optar por **não salvar**, preservar a cópia e abrir decisão separada para dimensão de exibição derivada (mapeamento 1:1 com contrato/oráculos), em vez de alterar silenciosamente a dimensão.

## 4. Preparação segura da cópia no Windows

**Esta etapa ainda não foi executada nesta sessão.** O operador realiza localmente no QlikView Desktop 12 x64 Personal Edition e no Explorador do Windows. **Não há runner novo.** Comandos `Get-FileHash` isolados são verificação manual de integridade; nenhum script novo está sendo distribuído para fundamentar PASS.

1. Se a QVW de trabalho ainda estiver aberta com `*` na barra de título (observado nos prints de VIS-03 sob seleção mensal), **fechar sem salvar**, descartando modificações de estado. A existência do `*` não comprova edição persistida.
2. A QVW-fonte **VIS-02** a preservar é:
   `C:\Users\pedro\SAD_VIS02_EVIDENCIAS\VIS02_20261109_230246_40a7da274f784973ab11175e4387a736\SAD_MVP_C4_VIS02_WORK.qvw`
3. Confirmar no PowerShell, somente leitura:
   `Get-FileHash -LiteralPath 'C:\Users\pedro\SAD_VIS02_EVIDENCIAS\VIS02_20261109_230246_40a7da274f784973ab11175e4387a736\SAD_MVP_C4_VIS02_WORK.qvw' -Algorithm SHA256`
   SHA-256 **histórico no closeout VIS-02**: `C564C7020D4F7377A541427B197E38726C47370385C14FE6446E7BA098158619`. **Atualização operacional de 10/11:** o operador reportou um Save de ajuste de layout; hash atual `BA0A7DDCF3F064D3EDC38AD5B0F4D7A79A00CEA0841234D21C0EA4D127C8C704`. O antigo hash não é mais o valor esperado para esse arquivo; registrar ambos. **Só aceitar BA0A… como baseline candidata de trabalho após conferência visual restrita da QVW reaberta, sem presumir que apenas o card mudou.** Se aparecer outro hash, STOP.
4. Via Explorador, **copiar** (não mover) a QVW VIS-02 para uma pasta privada **nova**, fora do repositório e das cópias protegidas, por exemplo `%USERPROFILE%\SAD_VIS02_P1_EVIDENCIAS\CH06_LABELS_20261110`. Renomear **somente a cópia** para `SAD_MVP_CH06_LABEL_FIX_TEMP.qvw`. Em caso de nome existente, criar diretório único, nunca substituir.
5. Recalcular por `Get-FileHash -LiteralPath '<CAMINHO_DA_NOVA_COPIA>' -Algorithm SHA256` e confirmar igualdade exata com a **fonte efetivamente escolhida e documentada (BA0A… apenas se verificação visual da QVW reaberta não trouxer regressão)** antes de abrir no QlikView. Registrar os dois hashes e caminho local em evidência privada. Não colocar QVW no Git.

## 5. Aplicação GUI única

No QlikView Desktop, abrir **somente** `SAD_MVP_CH06_LABEL_FIX_TEMP.qvw`, limpar as seleções e abrir a folha **Leitos Cadastrais Observados**.

1. Identificar o objeto `CH06` / M2-03 pelo título `Observabilidade LT | PB 2017–19 | sem filtros globais`. Em **Propriedades → Dimensões**, apenas verificar que a dimensão é `P23_ESTADO_OBSERVADO`. Desativar a exibição dos **valores da dimensão no eixo** por **Mostrar legenda** na configuração da dimensão. **Não** modificar a dimensão, seu rótulo, filtros ou demais propriedades. O nome exato dos controles pode variar na instalação em português.
2. Em **Propriedades → Apresentação → Textos do gráfico (Text in Chart)**, adicionar texto livre com as quatro linhas da seção 3, em tamanho legível, preferencialmente 10–11 pt ou superior na captura final. Configurar fundo neutro e mover o texto para a área disponível do **mesmo CH06**, sem cobrir as barras ou qualquer legenda útil. **Não** criar um novo objeto de folha.
3. Antes de salvar, conferir que há **três barras** visíveis, associadas às **mesmas cores e categorias** da visualização anterior. A legenda deve permitir identificação inequívoca sem hover e sem truncamento. Se precisar, reposicionar apenas texto e limites de área de apresentação do gráfico; não reordenar categorias ou trocar gráfico.
4. Se a solução ficar clara, salvar **somente a nova cópia**; registrar SHA-256 da fonte VIS-02 ainda igual ao esperado e SHA-256 novo da cópia modificada. Fechar, reabrir **a cópia** e obter **uma screenshot da folha 2 em estado neutro**, sem `*` e mostrando os três significados legíveis.
5. Encerrar. **Não** repetir testes de rolagem M1-03/M2-02, mês `201801`, F01–F05, C3/C4, nem carregar dados. Um único screenshot pós-reabertura e dois hashes bastam para verificar a finalidade visual deste gate.

**Se a instalação não oferecer a propriedade ou o texto não couber com clareza**, sair **sem salvar**, registrar `BLOCKED_NO_GUI_ONLY_SOLUTION` e informar exatamente qual propriedade faltou. A alternativa com `Dual()`/dimensão calculada requer autorização própria, implementação versionada e verificação semântica; não é fallback automático.

## 6. Critérios objetivos e STOP

`PASS_LOCAL_VISUAL_RESTRICTED` somente se:
- arquivo original VIS-02 com SHA-256 esperado preservado;
- cópia inicialmente com hash igual e após Save hash novo registrado;
- `CH06` mantém os três códigos de origem, `Count(P23_MUNICIPIO_6)`, universo, ordenação e ilha independente; não alterar medida/dimensão;
- três barras e legenda curta, completa e não sobreposta, coerente com as cores observadas; sem informação metodológica enganosa;
- screenshot **após reabertura** confirma legibilidade, persistência e ausência de `*` no documento;
- nenhuma outra propriedade/folha alterada.

`BLOCKED`: divergência de hash da origem, mudança de categorias/medida, legenda potencialmente falsa, barras cobertas/cortadas, objeto extra, ou fonte substituída. `INCONCLUSIVE`: falta prova de persistência ou da cor/categoria. **Parar após a primeira tentativa**, sem novas variações em cascata.

**Não homologar:** `C2_GUIDED_R2`, Link Key, medidas globais, escopo hospitalar histórico, Fase IX ou produção. `PRODUCTION_APPROVED=False`.

## 7. Handoff

Com screenshot e dois hashes de retorno, registrar **somente o fechamento localizado do M2-03** no escopo deste gate e atualizar a VIS-03/#232 por referência, com `VIS03_CH06_LABELS=PASS_GUI_RESTRICTED` se sustentado. O teste de apresentação compartilhada real continua `INCONCLUSIVE` até captura da transmissão; não confundir com screenshot local. O passo DOC-R3 pode começar somente após encerrar ou aceitar formalmente esse resíduo visual e preservar como fallback o relatório R2. **Nenhum merge automático.**

**Controle desta preparação:** `CH06_LABEL_FIX_RUNBOOK=READY_DOCUMENTAL`, `CH06_LABEL_FIX_GUI=NOT_RUN`, `VIS03_GATE=BLOCKED_FOR_PRESENTATION_P1_CH06_LABELS`, `MAIN=UNCHANGED`, `C2_C3_C4_GLOBAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.


## 8. Retorno do operador — salvamento intencional da VIS-02 e rebaseline condicionada (10/11/2026)

**Evidência recebida:** saída do PowerShell reproduzida pelo operador no chat, não inspeção independente de bytes QVW. O operador informou que salvou a QVW VIS-02 após corrigir um card/aviso que extrapolava a tela, causa **plausível**, não comprovada exclusivamente pelo hash.

| Artefato | SHA-256 reportado | LastWriteTime local | Tamanho |
|---|---|---|---:|
| C4 original `SAD_MVP_C4_PRESENTATION_TEMP.qvw` | `27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13` | 09/11/2026 13:37:26 | 32.598.016 bytes |
| VIS-02 de trabalho atual `SAD_MVP_C4_VIS02_WORK.qvw` | `BA0A7DDCF3F064D3EDC38AD5B0F4D7A79A00CEA0841234D21C0EA4D127C8C704` | 10/11/2026 12:11:06 | 32.649.728 bytes |

**Comparação:** C4 original corresponde exatamente ao valor canônico anteriormente reportado e permanece preservada no instante da verificação. A VIS-02 difere do hash anterior `C564C7020D4F7377A541427B197E38726C47370385C14FE6446E7BA098158619`; essa diferença é compatível com Save informado. **Não prova** que a única alteração foi visual, nem que os avisos/expressões continuam iguais. A divergência deixa de ser suspeita inexplicada, mas não constitui PASS de conteúdo.

**Ação mínima, sem repetir testes encerrados:** manter intacta a VIS-02 atual; abrir/reabrir esse arquivo sem Reload, capturar apenas a folha/cartão cujo overflow foi corrigido em estado neutro e fechar sem salvar. Se legível, com as nove visualizações e sem nova regressão evidente, registrar `VIS02_WORK_BA0A_CANDIDATE_ACCEPTED_FOR_P1_SOURCE=VISUAL_RESTRICTED`, documentando que é rebaseline de uma **QVW TEMP acadêmica** e não rehomologação C2/C3/C4. Só então produzir **nova cópia** com hash inicial BA0A…, para realizar a alteração gráfica CH06. Preservar a VIS-02 atual como fallback.

**Status desta atualização:** `C4_ORIGINAL_HASH=PASS_LOCAL_OPERATOR_REPORTED`; `VIS02_WORK_HASH_CHANGED_AFTER_OPERATOR_REPORTED_SAVE`; `VIS02_WORK_NEW_BASELINE=CONDITIONAL_PENDING_VISUAL_REVIEW`; `P1_COPY_AND_GUI=NOT_EXECUTED`; `VIS03_LABEL_FIX=BLOCKED_PENDING_P1`; `PRODUCTION_APPROVED=False`.

**STOP:** não sobrescrever a C4 original nem descartar a VIS-02 atual; não reexecutar rolamentos, F01–F05 ou seleção 201801 sem novo desvio concreto. Nenhum merge, alteração de main ou script físico decorre deste retorno.

## 9. Evidência GUI adicional da correção de overflow CH09/M3-03 (10/11/2026)

**Origem:** screenshot enviado pelo operador neste chat, `image(20261110-175604).png`, 1670×1030 pixels, SHA-256 do **PNG recebido** `D1434CC24AB6A845E7565612D64394E09311B15C3B81C1E17F3F143462A5E129`. A janela informa a QVW VIS-02 de trabalho `SAD_MVP_C4_VIS02_WORK.qvw` (não a C4 protegida). O operador informa que corrigiu o overflow que ocorria ao selecionar ano 2018 e competência 2018.1/201801, e salvou a QVW em 10/11/2026 12:11:06. A screenshot não exibe painel de seleções atuais, então o exato estado dos filtros não foi confirmado independentemente.

**Inspeção visual direta do PNG:** aba `Fluxos e Contexto Territorial`, três objetos presentes; o card de população por ano (CH09/M3-03) exibe mensagem de indisponibilidade da consulta anual sob filtro mensal, **inteiramente dentro da área do objeto**. Nenhum overflow textual para fora do CH09 aparece na captura. O `*` na barra do documento indica sessão com estado não salvo e **não** prova alteração persistente posterior ao hash BA0A. Os dois outros objetos são visíveis, mas não foram revalidados numericamente neste gate.

**Decisão restrita:** há evidência suficiente para tratar o hash atual **BA0A7DDCF3F064D3EDC38AD5B0F4D7A79A00CEA0841234D21C0EA4D127C8C704** como **baseline candidata da QVW VIS-02 exclusivamente para preparar uma nova cópia P1**, porque a divergência tem Save explicado pelo operador e o overflow relatado está visualmente contido na cópia aberta. Não é comparação byte-a-byte de propriedades, nem homologação integral de todos os nove objetos. Nenhuma necessidade de repetir seleção 201801, rankings ou C2/C3/C4.

**Próxima execução mínima:** fechar a VIS-02 atual sem salvar o estado de seleção; conferir que o hash BA0A permanece; criar uma **cópia nova em pasta única**, verificar hash idêntico BA0A antes de abrir; aplicar exclusivamente a solução de legibilidade CH06/M2-03 na nova cópia, conforme §5, fotografar após Save/close/reopen e registrar hashes. **Não sobrescrever** a VIS-02 atual.

`VIS02_CH09_OVERFLOW_SCREENSHOT=PASS_GUI_CONTAINMENT_RESTRICTED`  
`VIS02_WORK_BA0A_CANDIDATE_ACCEPTED_FOR_P1_SOURCE=VISUAL_RESTRICTED`  
`VIS02_WORK_BYTES_SEMANTIC_REVALIDATION=NOT_TESTED`  
`CH06_LABEL_FIX_GUI=NOT_RUN`  
`VIS03_CH06_LABELS=BLOCKED_PENDING_P1`  
`C2_C3_C4_GLOBAL=NOT_APPROVED`  
`PRODUCTION_APPROVED=False`


## 10. Automação PowerShell versionada (solicitação do responsável em 10/11/2026)

O responsável solicitou automatizar por Shell as operações de proteção, preparação e coleta de evidências. **Esta seção substitui o procedimento manual de criação de pasta/cópia dos §§4–5, mas NÃO a edição visual de CH06.** Executor commitado no repositório antes de qualquer execução:

- [`tools/Invoke-SadVis02P1Ch06.ps1`](../../tools/Invoke-SadVis02P1Ch06.ps1), script introduzido no commit `8ac816ec2bb65871de05b00b6c7e784d5ecdc5e5` desta branch.
- PowerShell 5.1+ em Windows, QVW `BA0A7DDC...` de VIS-02, C4 `27ADABC3...` e associação `.qvw` com QlikView 12 local.
- **Prepare:** bloqueia se processo `Qv` está aberto, confere ambos os SHA-256, cria subdiretório único fora das origens, copia QVW **sem sobrescrever** e verifica hashes da cópia/fonte/original. Gera manifesto JSON com hash do script, abre **somente a cópia** por `Invoke-Item`. Zero COM/Reload/Save automático.
- **Verify:** recebe caminho exato do manifesto para evitar trocar artefatos, verifica ambos arquivos originais, compara hash da QVW editada com o inicial, gera JSON separado; opção `-Capture` espera 6 s para focar no QlikView, confirma que a janela ativa tem o nome da **cópia** e não contém `*.qvw*`, captura a janela em PNG e calcula seu SHA-256. **Não** inspeciona propriedades nem aprova layout por algoritmo; encaminhar PNG para análise visual humana/agente.
- **Proteção adicional:** se não houver fonte/hash esperado, se C4/Vis02 tiver drift, se o executável ou manifesto divergirem, se o diretório já existir ou janela ativa for diferente, retorna `VERDICT=BLOCKED` / código 2. A pasta incompleta de uma falha deve ser preservada para diagnóstico, sem reusar/sobrescrever.
- **Limite comprovado:** revisão estática de presença dos controles em código versionado; **não executado/testado no Windows/QlikView** nesta sessão. `AUTOMATION_WINDOWS_SMOKE=NOT_TESTED`. A chamada a `GetForegroundWindow`/captura depende de desktop interativo e foco correto. Não equivaler `PASS_COPY_HASHES_ONLY` ou `PASS_HASH_PROVENANCE_ONLY` a `PASS_GUI_VISUAL_RESTRICTED`.

### Invocação sem alterar a branch atual

Primeiro **fechar QlikView sem salvar**. Em PowerShell, baixar o **commit pinado** para arquivo fora do repo (este comando somente obtém um script UTF-8 previamente commitado):

```powershell
$commit = '8ac816ec2bb65871de05b00b6c7e784d5ecdc5e5'
$folder = Join-Path $env:USERPROFILE 'SAD_VIS02_P1_EVIDENCIAS'
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$script = Join-Path $folder 'Invoke-SadVis02P1Ch06.ps1'
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pedrogles/sad-sus-pb-data-mart/$commit/tools/Invoke-SadVis02P1Ch06.ps1" -OutFile $script
Get-FileHash -LiteralPath $script -Algorithm SHA256
& $script -Mode Prepare
```

Registrar `SCRIPT_SHA256` e `MANIFEST` impressos. A primeira execução gera `WORK_QVW` e abre a cópia. O operador **edita apenas a apresentação do CH06/M2-03, salva e reabre a cópia** para prova de persistência. Não usar PowerShell para simular teclado/cliques sem garantia.

Após reabrir a cópia e posicionar a folha 2, em nova linha PowerShell:

```powershell
& $script -Mode Verify -ManifestPath '<CAMINHO_MANIFEST_IMPRESSO_NO_PREPARE>' -Capture
```

Quando aparecer `FOCUS_QLIKVIEW_NOW`, colocar a janela QlikView com a **cópia** em primeiro plano antes do término da contagem. Se `ExecutionPolicy` local impedir execução, tratar como bloqueio de ambiente e autorizar explicitamente a liberação do arquivo de origem verificada; não mudar política de máquina silenciosamente.

O script produz `SCREENSHOT`, `REPORT` e `WORK_SHA256`; preservar fora do Git e fornecer para fechamento. `PASS_HASH_PROVENANCE_ONLY` significa **apenas** que os hashes das fontes permanecem e a cópia mudou — não comprova a alteração correta dos rótulos, nem reabertura. A confirmação visual exige inspeção da captura.

**Status atualizado:** `CH06_P1_SHELL_SCRIPT=VERSIONED`, `CH06_P1_SHELL_STATIC_CHECK=PASS_RESTRICTED`, `CH06_P1_WINDOWS_EXECUTION=NOT_RUN`, `CH06_P1_GUI_FIX=NOT_RUN`, `VIS03_GATE=BLOCKED_FOR_PRESENTATION_P1_CH06_LABELS`; sem merge, sem edição QVW/QVD/QVS pela automação, sem aprovação C2/C3/C4/IX/produção.

## 11. Pré-save — legibilidade e mapeamento corrigidos na cópia CH06 (10/11/2026)

**Fonte visual:** screenshot `image(20261110-194919).png` enviado pelo operador, janela `SAD_MVP_CH06_LABEL_FIX_TEMP.qvw*`, pasta privada local `CH06_20261110_163018_870df719340c`. Inspeção direta de screenshot; **sem acesso ao arquivo QVW, aos bytes da cópia, a propriedades COM ou a estados internos**.

**Resultado observacional localizado:** o gráfico M2-03 na folha 2 apresenta três barras com os textos alinhados à categoria correta: âmbar = "Sem linha LT / Não significa zero"; verde-azulada = "SUS positivo / Observado"; cinza = "SUS zero / Observado". Códigos técnicos longos do eixo não aparecem; os textos não se sobrepõem nem cobrem as barras na captura. Título do gráfico continua indicando PB 2017–19 e independência de filtros globais. A ressalva metodológica sobre escopo hospitalar não verificado continua sendo necessária na documentação/apresentação, mas não se presume inserida no gráfico.

**Proveniência e limite:** `CH06_LABEL_MAPPING_PRE_SAVE=PASS_GUI_VISUAL_RESTRICTED`; `CH06_LABELS_VISUAL_OVERLAP=NO_CRITICAL_OVERLAP_IN_CAPTURE`. A janela contém `*`, então o Save, o fechamento/reabertura, o SHA pós-save e a estabilidade das fontes **ainda não foram conferidos**. **Não atribuir PASS de persistência ou integridade ao screenshot.** Não repetir seleção 201801, rankings, C2/C3/C4 ou alterar novas propriedades.

**Próxima ação única:** salvar **somente a cópia**; fechar; reabrir **a cópia**; posicionar folha 2; executar o modo `Verify -ManifestPath ... -Capture` do script commitado; fornecer os campos `VERDICT`, `SOURCE_UNCHANGED`, `PROTECTED_C4_UNCHANGED`, `WORK_SHA256` e a captura. `VIS03_GATE=BLOCKED_PENDING_PERSISTENCE_EVIDENCE` até essa verificação.


## 12. Incidente no Verify -Capture: resultado agregado no pipeline (10/11/2026)

**Saída real fornecida pelo operador** na pasta privada `CH06_20261110_163018_870df719340c`:

```text
VERDICT=PASS_HASH_PROVENANCE_ONLY
SOURCE_UNCHANGED=True
PROTECTED_C4_UNCHANGED=True
WORK_SHA256=6ED9CC1FAA5AFD592D1D4CECC8D6FC5DE2AB84D4DCE2D4E6D3E6A25E59D7BE37
REPORT=...\vis02_p1_verify_20261110_170554_3809a412.json
VERDICT=BLOCKED
DETAIL=A propriedade 'Path' não foi encontrada neste objeto. Verifique se a propriedade existe.
```

**Diagnóstico no script versionado:** `CaptureForeground` emitia a linha `FOCUS_QLIKVIEW_NOW seconds=6` com `Write-Output`, que entra no **pipeline de retorno** da função, seguida da hashtable de metadados do PNG. Assim, `$screen` se torna um array contendo o aviso e os dados da captura. O relatório JSON foi escrito e seu caminho impresso antes da tentativa de `$screen.Path`, que falhou. **O erro é do relatório de saída da automação, não demonstra corrupção de QVW.** Pode existir PNG já salvo; seu conteúdo não foi visto neste gate.

**Correção mínima versionada:** no commit `f4ea7beb9addda53006f15acc2cb3aabbebd5161`, somente a mensagem de foco dentro de `CaptureForeground` passou de `Write-Output` para `Write-Host`. A função passa a entregar apenas a hashtable no pipeline de resultado. **Correção inspecionada estaticamente; reexecução no Windows ainda não feita.**

**Recuperação não destrutiva da sessão já concluída:** ler o relatório JSON existente, extrair o elemento de `Screenshot` que contém `Path` e conferir hash do PNG. Não executar `Prepare` nem outro `Verify`; não regravar QVW:

```powershell
$reportPath = 'C:\Users\pedro\SAD_VIS02_P1_EVIDENCIAS\CH06_20261110_163018_870df719340c\vis02_p1_verify_20261110_170554_3809a412.json'
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
$imagem = @($report.Screenshot) |
    Where-Object { $_.PSObject.Properties.Name -contains 'Path' } |
    Select-Object -Last 1
if ($null -eq $imagem) { throw 'SCREENSHOT_NOT_FOUND_IN_REPORT' }
$imagem.Path
Get-FileHash -LiteralPath $imagem.Path -Algorithm SHA256
Invoke-Item -LiteralPath $imagem.Path
```

**Imutabilidade operacional:** o manifesto `vis02_p1_manifest.json` guarda SHA-256 da **versão original** do script; a versão corrigida tem outro hash. O verificador rejeita a mistura de versões (`SCRIPT_HASH_CHANGED`) intencionalmente. Portanto, **não substituir o script antigo usado por esse manifesto para repetir a sessão**; recuperar diretamente pelo JSON. O script corrigido é destinado a **novas preparações**, se realmente necessárias, e deve ser distribuído somente por commit versionado.

`P1_HASH_PROVENANCE=PASS_LOCAL_OPERATOR_REPORTED`; `P1_CAPTURE_METADATA_REPORT=CREATED_REPORTED`; `P1_CAPTURE_PNG=RECOVERY_PENDING_INSPECTION`; `P1_GUI_PERSISTENCE=INCONCLUSIVE_PENDING_PNG`; `P1_SCRIPT_CAPTURE_BUG=FIX_COMMITTED_NOT_WINDOWS_RETESTED`; `VIS03_GATE=INCONCLUSIVE_PENDING_PERSISTENCE_VISUAL_P1`; `PRODUCTION_APPROVED=False`.


## 13. Closeout VIS-02-P1 — persistência visual pós-save e screenshot recuperada (10/11/2026)

**Proveniência:** saída PowerShell do operador para `-Mode Verify -Capture`; `REPORT` criado com hash e objeto de captura, seguida de erro conhecido de pipeline (seção 12); operador recuperou o PNG sem executar novamente `Prepare`, `Verify`, Reload ou Save. Captura recebida neste chat: `image(20261110-200952).png`, resolução **1907×1068** e SHA-256 **deste upload** `4F6C97711EAE18492CCF8281FD9F27A3291D45EDAFA8282847A61B02FBED35F4`. Arquivo local recuperado e hash **reportado pelo operador**, distinto porque o upload pode ser reprocessado: `C:\Users\pedro\SAD_VIS02_P1_EVIDENCIAS\CH06_20261110_163018_870df719340c\ch06_post_reopen_20261110_170554_ddc7074c.png` com SHA-256 `4EAD80B8C9DAD4A884F8AE0032803933F2A53D2FC5051013F0BA97A01C40BE0E`. Não equiparar os dois hashes a bytes idênticos.

**Evidência de integridade local reportada:** `SOURCE_UNCHANGED=True`; `PROTECTED_C4_UNCHANGED=True`; `WORK_SHA256=6ED9CC1FAA5AFD592D1D4CECC8D6FC5DE2AB84D4DCE2D4E6D3E6A25E59D7BE37`. O script registrou `VERDICT=PASS_HASH_PROVENANCE_ONLY` antes de falhar no último print; esse rótulo **não é PASS de GUI**. O relatório de auditoria está em `...\vis02_p1_verify_20261110_170554_3809a412.json` no Windows do operador. Nada foi enviado ao Git como arquivo binário.

**Avaliação direta da imagem posterior à reabertura relatada:** QlikView Desktop 12 x64 Personal Edition, janela com `SAD_MVP_CH06_LABEL_FIX_TEMP.qvw` **sem `*`**, folha 2 com M2-01/M2-02/M2-03 visíveis. CH06 permanece com título `Observabilidade LT | PB 2017–19 | sem filtros globais`; são visíveis três barras e três textos legíveis, sem sobreposição crítica: âmbar = `Sem linha LT / Não significa zero`; verde-azulada = `SUS positivo / Observado`; cinza = `SUS zero / Observado`. Códigos técnicos longos não poluem o eixo. Portanto há evidência visual de **persistência da apresentação corrigida** na cópia, em conjunto com relato de Save/close/reopen e hash pós-save. Ausência de `*` sozinha não certifica propriedades internas nem histórico de edição.

| Critério | Estado |
|---|---|
| Proteção C4/VIS-02 | `PASS_HASH_LOCAL_OPERATOR_REPORTED` |
| Proveniência de cópia alterada | `PASS_HASH_PROVENANCE_ONLY` |
| Mapeamento cor/categoria e legibilidade CH06 | `PASS_GUI_VISUAL_RESTRICTED` |
| Persistência após Save/close/reopen informado | `PASS_VISUAL_PERSISTENCE_RESTRICTED_WITH_OPERATOR_EVIDENCE` |
| Novo ensaio do script corrigido de captura | `NOT_TESTED_WINDOWS` (desnecessário para o gate; recuperar PNG bastou) |
| Auditoria interna das expressões e associações | `NOT_AUDITED` |
| Compartilhamento real online | `INCONCLUSIVE_NOT_CAPTURED` |
| Produção / C2-C3-C4 / Fase IX | `NOT_APPROVED` |

**Veredito local:** `VIS02_P1_CH06_GATE=PASS_LOCAL_VISUAL_RESTRICTED_CLOSED`. A falha de automação é registrada e a correção está versionada, mas nenhuma nova rodada de teste é necessária para aprovar o layout observado. STOP: não repetir seleções 201801, rankings, reconstruções, COM ou Reload; não editar mais a cópia. Passar o fechamento para a VIS-03/#232 sem merge, preservando arquivo, captura e manifesto locais. A ressalva de cobertura hospitalar não verificada permanece necessária no relatório/apresentação.
