# SAD — VIS-05 | P1.2 Acabamento nativo, folha Produção Hospitalar

**Gate:** piloto reversível M1-01 para fonte, cabeçalho e borda nativos no QlikView 12. **Não** implica PASS em 1366×768, não altera modelagem, medidas, expressões, filtros, QVS, QVD, PDFs ou QVW original. Mockups VIS-05 e fundo R2 aprovados pelo responsável; capturas de 2 janelas distintas mostram composição 3 objetos, mas **menor viewport 1366×768 ainda INCONCLUSIVE**.

## Fonte e limite físico

- Protegido VIS-04: `C:\Users\pedro\SAD_VIS04_EVIDENCIAS\VIS04_20261110_201240_0d9818e4ab0c\SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw` (SHA inicial documentado `BE8CB39B59F92F2F173DB309A60EA5FF373CDF87CBFCBC333F5583A21FF539C6`).
- Único tocável: `C:\Users\pedro\SAD_VIS05_EVIDENCIAS\VIS05_20261112_171721_950990d1\SAD_MVP_VIS05_UX_WORK_TEMP.qvw`.
- Operador captura screenshots manualmente e envia ao chat; não usar `CaptureAll` nem `CaptureHover`. Sem COM / Reload / reexecução do builder.
- Antes de novo ajuste, desativar grade e salvar exclusivamente a cópia VIS-05 como checkpoint; reabrir apenas se necessário para sanear dúvida de persistência.

## Proposta de piloto (M1-01 somente)

1. Em `Propriedades do Gráfico → Título`, manter texto exato `Novas internações por ano (SIH/RD)`, opção `Mostrar Título` habilitada, alinhamento à esquerda e posicionamento normal.
2. Botão `Fonte...` do título: **Segoe UI Bold 11 pt** (valor inicial candidato; em resolução menor, revisar antes de generalizar).
3. `Título Inativo` e `Ativar Título` (ambos): fundo **#DCEFF2 / RGB 220,239,242** e texto **#17313D / RGB 23,49,61**. Se o seletor não aceitar hexadecimal, usar RGB. Não personalizar hover ou outros controles agora.
4. Em `Layout`, somente se opção equivalente estiver visível: ativar borda discreta **1 px #BDD3DA / RGB 189,211,218**. Não ativar `Advanced Styling Mode` global nem forçar cantos arredondados; são condicionados ao modo avançado.
5. Na aba `Fonte` do gráfico, **não alterar por enquanto**. Texto dos eixos/códigos e eixo de competência será avaliado visualmente antes da padronização, pois 36 meses/10 municípios cabem em áreas limitadas.
6. Não modificar X/Y/Largura/Altura, estilo das barras, legenda, ordenação, dimensões ou expressões.
7. Aplicar M1-01, desligar grade e capturar print manual sem salvar; comparar fundo, título e linhas com mockup e avaliar se há clipping.

## Critérios

- **PILOT_REVIEW_OK** se M1-01 permanece legível, sem perda de dados/cabeçalho, e o estilo se aproxima da referência.
- **PILOT_NEEDS_TUNING** se a fonte 11 pt ou borda prejudica o gráfico; reverter somente a propriedade causadora.
- **1366x768_SCREEN_READABILITY=INCONCLUSIVE** até captura real de resolução equivalente sem recorte e sem excesso de zoom.
- Para expandir a M1-02 e M1-03, exigir review do piloto; verificar que título do ranking não corta.
- **STOP** após o print piloto e avaliação. Não começar os dois outros objetos antes disso.

## Referências

- QlikView 12 — `Bar_Chart.htm` e `Line_Chart.htm` da documentação September2026 (Propriedades de Gráfico: Fonte/Layout/Título).
- QlikView 12 — `Ajax/WebView_ComboChart.htm` September2026: estilos de título ativo/inativo, borda e restrição de cantos arredondados.
- `docs/project/sad-vis-04-final-presentation-polish-runbook-2026-11-10.md`.
