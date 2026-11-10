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
   SHA-256 **esperado (reportado na VIS-02)**: `C564C7020D4F7377A541427B197E38726C47370385C14FE6446E7BA098158619`. Se diferente, **STOP** e investigar a origem; não sobrescrever.
4. Via Explorador, **copiar** (não mover) a QVW VIS-02 para uma pasta privada **nova**, fora do repositório e das cópias protegidas, por exemplo `%USERPROFILE%\SAD_VIS02_P1_EVIDENCIAS\CH06_LABELS_20261110`. Renomear **somente a cópia** para `SAD_MVP_CH06_LABEL_FIX_TEMP.qvw`. Em caso de nome existente, criar diretório único, nunca substituir.
5. Recalcular por `Get-FileHash -LiteralPath '<CAMINHO_DA_NOVA_COPIA>' -Algorithm SHA256` e confirmar igualdade exata com a fonte antes de abrir no QlikView. Registrar os dois hashes e caminho local em evidência privada. Não colocar QVW no Git.

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
