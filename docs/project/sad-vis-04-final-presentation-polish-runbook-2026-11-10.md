# SAD — VIS-04 | Acabamento de eixos, textos e cabeçalhos (10/11/2026)

**Gate único, apresentação acadêmica:** quatro correções visuais delimitadas nas três folhas do QVW TEMP após VIS-03. Solicitação expressa do responsável: corrigir a inconsistência da faixa turquesa no cabeçalho da folha 3, despoluir rótulos temporais e apresentar títulos/dimensões de modo inteligível. **Não iniciar novas implementações analíticas**, pois a segunda entrega é final para a disciplina.

## Fontes, autoridade e dependências

Lidas em \`main\`, na ordem obrigatória: \`AGENTS.md\` → \`docs/project/current-state.md\` → \`docs/academic/requirements.md\` → \`docs/project/qlikview-powershell-automation.md\`; consultada a aplicação VIS-02 Draft #231 (runbook que define imagens de fundo por folha), VIS-03 Draft #232, fix CH06 Draft #233 e R3 Draft #234. O blueprint 14 da \`main\` permanece distinto do MVP TEMP nove visuais. Fotos fornecidas pelo operador em 10/11/2026 mostram as marcações vermelhas: borda esquerda ausente na folha 3, duas linhas temporais poluídas, campo \`SERV_COD_DATASUS_6\`, título e categorias \`MVP_FI_RES_SERV_CLASS\`.

Documentação oficial QlikView 12 consultada:
- [Gráfico de barras, eixos, legendas, dimensões](https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Bar_Chart.htm).
- [Dimensionar/mover componentes com Ctrl+Shift](https://help.qlik.com/pt-BR/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Sizing_and_moving_chart_components.htm).
- [Textos do gráfico](https://help.qlik.com/pt-BR/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Chart_texts.htm).

**Fatos estáticos do construtor Draft #226**:
- M1-02, M2-01 têm dimensão \`PERIODO_COMPETENCIA\`. M1-03 e M2-02: \`SERV_COD_DATASUS_6\`. M3-01: \`MVP_FI_RES_SERV_CLASS\` e medida \`Sum(QTD_INTERNACAO)\`; classes físicas \`RES_EQ_SERV\`, \`RES_NE_SERV\`.
- VIS-02 aplicou **fundos de imagem PNG distintos por folha** por \`Sheet Properties → General → Background → Image\`. Não presumir que a faixa turquesa seja um objeto independente no Qlik. A faixa visual existente nas folhas 1/2 e ausente na 3 pode ser diferença do PNG ou de escala/corte; **a causa ainda não foi auditada nos bytes dos PNG**.

## Contrato físico imutável

**Fonte de trabalho protegida** (único arquivo aceito para iniciar): 
\`C:\Users\pedro\SAD_VIS02_P1_EVIDENCIAS\CH06_20261110_163018_870df719340c\SAD_MVP_CH06_LABEL_FIX_TEMP.qvw\`
SHA-256 **reportado após Save e reabertura em VIS-03**:
\`6ED9CC1FAA5AFD592D1D4CECC8D6FC5DE2AB84D4DCE2D4E6D3E6A25E59D7BE37\`.

Outras origens protegidas: VIS-02 SHA \`BA0A7DDCF3F064D3EDC38AD5B0F4D7A79A00CEA0841234D21C0EA4D127C8C704\` e C4 SHA \`27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13\`.

Nunca executar \`Reload()\`, builder \`Build-SadMvpThreeSheetsTemp.ps1\`, COM, reconfigurar expressões, dimensões calculadas, \`Set Analysis\`, filtros, associações, QVS/QVD ou edição de cópias anteriores. Preservar as nove visualizações e M2-03 (cores, valores, ilha, contagens); não gerar novos objetos analíticos. Não modificar o PDF R3 até ter evidência de screenshots finais aprovada e, se necessário, autorização de revisão de figuras.

## Preparação/validacão pelo Shell (sem automação cega GUI)

Executor versionado nesta branch: \`tools/Invoke-SadVis04FinalPolish.ps1\`; PowerShell 5.1 no Windows. \`Prepare\`: QlikView fechado sem salvar estado \`*\`; confere SHA-256 dos três QVWs; cria pasta privada **única** em \`%USERPROFILE%\SAD_VIS04_EVIDENCIAS\VIS04_...\`, copia apenas o último QVW com nome \`SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw\`, registra manifesto e abre somente a cópia. Não altera originais, gráficos ou dados. \`Verify\`: recebe manifesto, verifica proteção dos três arquivos, grava o hash pós-Save da cópia e relatório JSON; **não aprova** GUI nem prova persistência. Capturas são entregues pelo operador como imagens (sem outro runner).

O executor foi inspecionado estaticamente nesta preparação, **não testado no Windows real**. Não usar versão do script diferente da informada no manifesto, nem substituir script pinado depois da preparação. Ao retornar \`VERDICT=BLOCKED\`, **STOP** sem sobrescrever arquivos ou construir de novo.

## Checklist GUI: alterar somente a nova cópia

### 1 — Folha Produção Hospitalar

- **M1-03** ranking SERV: clique direito → Propriedades → **Dimensões** → selecionar a dimensão \`SERV_COD_DATASUS_6\` e mudar apenas \`Rótulo\`/texto exibido para **\`Município de atendimento (cód. DATASUS)\`**. Não mudar o campo da dimensão ou seus valores. Se o texto ficar comprido, usar \`Atendimento (cód. DATASUS)\`.
- **M1-02** série 36 meses: Propriedades → **Eixos → Eixo de Dimensão** → \`Rótulos de Dimensão Primária = Horizontal\`; **desmarcar \`Rótulos Empilhados\`**, se estiver marcado; manter o campo \`PERIODO_COMPETENCIA\`, as 36 categorias e todos os pontos. **Não** impor \`Incremento Estático\`, \`Contínuo\`, limites ou modificar \`Dimensões\`. Se permanecer apertado, ajustar a largura/altura da **área do eixo** por Ctrl+Shift sem recobrir gráfico. O Qlik poderá mostrar menos textos, não menos dados.

### 2 — Folha Leitos Cadastrais Observados

- **M2-01** série temporal: mesma sequência de \`Eixos\` de M1-02; preservar duas séries \`QTD_LEITOS_SUS\` e \`QTD_LEITOS_EXISTENTES\`. Não somar snapshots por período.
- **M2-02** ranking SERV: alterar somente \`Rótulo\` da dimensão \`SERV_COD_DATASUS_6\` para **\`Município de atendimento (cód. DATASUS)\`** (ou forma curta se necessário), preservando a medida fixa em **201912**, ordenação e avisos CH05. Não alterar posição/título do CH06 de observabilidade corrigida.

### 3 — Folha Fluxos e Contexto Territorial

- **M3-01 / CH07**: em \`Geral → Título da Janela\`, substituir apenas o título por **\`Internações: mesmo município × município diferente\`** (se comprimento excessivo, \`Internações: município igual × diferente\`). Usar \`Dimensões → Rótulo\` para substituir o texto de cabeçalho \`MVP_FI_RES_SERV_CLASS\` por **\`Relação residência × atendimento\`**, ou desmarcar a exibição do **nome do campo** se ocupar área inadequada. **Não** modificar \`MVP_FI_RES_SERV_CLASS\`.
- Os valores de classe \`RES_EQ_SERV\` e \`RES_NE_SERV\` são **valores da dimensão**, não o texto do campo. O controle \`Rótulo\` **não** renomeia valores; **não usar \`If\`, \`Pick\`, \`Match\` ou \`Dual\` em dimensão calculada** nesta correção de estilo. Alternativa segura: em \`Apresentação → Texto no Gráfico\`, inserir **um único texto de equivalência**, preferivelmente com fundo transparente, até 10–11pt:
  \`RES_EQ_SERV = Mesmo município   |   RES_NE_SERV = Município diferente\`
  Colocar em área vazia sem cobrir barras; usar Ctrl+Shift para movê-lo e ajustar seu contorno. **Manter os dois códigos visíveis no eixo**, para evitar legenda fixa errada se a ordenação mudar sob seleção. Essa solução permite explicar as categorias independentemente da ordem e não altera as duas medidas.
- **Faixa turquesa ausente à esquerda do cabeçalho**: nas propriedades da **folha 3 → Geral → Plano de fundo/Imagem**, conferir se há imagem VIS01 \`VIS01_fundo_3_fluxos_1920x1080.png\` e comparar modo de escala/posição com folhas 1/2. Se a faixa não existe nos pixels do PNG original, gerar **novo fundo em cópia isolada do PNG**, preservando título/subtítulo, e associar somente à nova cópia QVW — **não duplicar painel/cabeçalho nem criar um décimo gráfico**. A edição desse PNG precisa de inspeção visual do asset e de definição exata da faixa para evitar deslocamento. **Se não puder identificar a causa, marcar \`HEADER_LEFT_STRIPE=INCONCLUSIVE\` e STOP somente desta correção**, sem bloquear os demais ajustes GUI.

## Critérios de aceite e STOP

1. **Antes do Save**, enviar três screenshots neutras, uma por folha; avaliar rótulos de dimensão, legibilidade das competências e M3-01. Confirmar três abas e nove gráficos, sem dimensão/medida alterada. Para a faixa, comparar o PNG de fundo das três folhas; não homologar o detalhe por presunção.
2. Quando visualmente coerente, **Save apenas na cópia**, fechar/reabrir **a cópia** e tirar uma captura por folha sem \`*\`, sem filtros; executar \`Verify -ManifestPath ...\` para conferir os três originais e registrar SHA pós-save.
3. \`VIS04_PREPARE=PASS_COPY_HASHES_ONLY\` se os três originais mantêm hashes e a cópia nasce idêntica.
4. \`VIS04_LOCAL_VISUAL=PASS_RESTRICTED\` somente mediante capturas inspecionadas com textos claros, 36 pontos de cada gráfico temporal preservados e nenhuma legenda enganosa; \`VIS04_PERSISTENCE=PASS_RESTRICTED\` só após Save/close/reopen e hash.
5. \`INCONCLUSIVE\` para aspecto não comprovado (ex.: asset do cabeçalho); \`BLOCKED\` para hash divergente, mudança de categoria/medida, desaparecimento dos objetos, recorte de barra ou legendas incompatíveis. Em caso de \`BLOCKED\`, sair **sem salvar** e preservar nova cópia para diagnóstico.

**Não repetir** os testes 201801, oráculos de contagens, scroll e F01–F05, C2/C3/C4; não modificar a \`main\` nem fazer merge. O projeto acadêmico encerra-se com a segunda entrega: estas são **últimas correções cosméticas**, não início de nova implementação de indicadores.

**Status na elaboração:** \`VIS04_RUNBOOK=READY_DOCUMENTAL\`; \`VIS04_GUI_APPLICATION=NOT_RUN\`; \`VIS04_SHELL_WINDOWS=NOT_RUN\`; \`VIS04_LOCAL_VISUAL=NOT_TESTED\`; \`VIS04_PDF_R3=UNCHANGED\`; \`PRODUCTION_APPROVED=False\`.


## Capturas do operador — revisão pré-save (10/11/2026, 20:17–20:30)

**Origem e escopo:** três PNGs reais enviados em chat após `Prepare` do PowerShell. Sessão mostra a QVW nova `C:\Users\pedro\SAD_VIS04_EVIDENCIAS\VIS04_20261110_201240_0d9818e4ab0c\SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw*`, com asterisco, portanto **ainda não há prova de persistência pós-save**. Saída do operador: `VERDICT=PASS_COPY_HASHES_ONLY`, origem SHA `6ED9CC1FAA5AFD592D1D4CECC8D6FC5DE2AB84D4DCE2D4E6D3E6A25E59D7BE37`, `SCRIPT_SHA256=BD169B58F36B43A97794D6E2CFC2DF4CD9AA72C0567B1754064E48C8EB9C3C1A` e manifesto local `...\VIS04_20261110_201240_0d9818e4ab0c\vis04_manifest.json`.

| Captura | Observação da folha | Resultado limitado |
| --- | --- | --- |
| `image(20261110-231756).png` | M1-02: um rótulo de competência a cada dois meses aproximadamente, série de linha intacta visualmente; M1-03 cabeçalho `Município de atendimento (cód. DATASUS)` em duas linhas | `PASS_GUI_PRE_SAVE_RESTRICTED` |
| `image(20261110-232156).png` | M2-01: duas linhas de leitos, competências despoluídas; M2-02 novo rótulo descritivo; M2-03 mantém as três classificações e cores legíveis | `PASS_GUI_PRE_SAVE_RESTRICTED` |
| `image(20261110-233103).png` | M3-01: título acadêmico legível; texto `Mesmo município` e `Município diferente` acima das barras, sem códigos técnicos no eixo; demais objetos presentes | `PASS_GUI_NEUTRAL_PRE_SAVE_WITH_STATIC_LABEL_CAUTION` |

**Inspeção comparativa das cores da faixa esquerda:** nas imagens (1907×1068) a faixa possui aproximadamente **11 pixels** (`x=0..10`) para as três folhas, com amostra em `y=150`: folha 1 RGB `(8,127,135)` (`#087F87`), folha 2 RGB `(22,166,164)` (`#16A6A4`), folha 3 RGB `(16,61,75)` (`#103D4B`). Fundo adjacente `(10,50,63)`, similar na terceira folha. **Não falta a faixa: o problema é o baixo contraste da imagem de fundo 3.** Não copiar cabeçalho/objeto de outra folha; apenas ajustar a cor da faixa no fundo 3 após preservar cópia do PNG e conferir área original e modo de escala.

**Risco específico M3-01:** os novos nomes parecem ser textos livres posicionados manualmente sobre as barras. A captura neutra está correta para apresentação, mas **não demonstra que os textos acompanham categorias e ordenação sob filtros**. Não assumir vínculo dos textos aos valores da dimensão; se não há associação nativa, exibir a equivalência em uma legenda única independente da posição (`RES_EQ_SERV = Mesmo município | RES_NE_SERV = Município diferente`) e/ou manter códigos do eixo visíveis, sem dimensão calculada. Aceite de apresentação neutra não autoriza alegar fidelidade em todas as seleções.

**Próximo passo único:** verificar a cópia local de `VIS01_fundo_3_fluxos_1920x1080.png` e o estilo de fundo da terceira folha (não foi recuperado em bytes nesta sessão); corrigir somente a faixa de contraste no PNG **copiado**, reimportar na nova QVW, e conferir o mapeamento M3-01. Após capturas neutras coerentes, salvar só a nova cópia, fechar/reabrir e executar `Verify` usando o manifesto já criado. Não repetir preflight ou testes antigos.

**Estado:** `VIS04_PREPARE=PASS_HASH_COPY_LOCAL_REPORTED`; `VIS04_GUI_PRE_SAVE=PASS_WITH_2_LOCALIZED_CAUTIONS`; `VIS04_HEADER_STRIPE_3=LOW_CONTRAST_PENDING`; `VIS04_M3_STATIC_TEXT_BINDING=UNVERIFIED`; `VIS04_PERSISTENCE=NOT_TESTED`; `VIS04_ORIGINAL_SOURCES=PREPARE_HASH_PASS_ONLY`; `PRODUCTION_APPROVED=False`.
