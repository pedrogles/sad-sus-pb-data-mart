# SAD VIS-05 — P2 | Leitos Cadastrais Observados — aplicação visual controlada

**Tipo:** runbook de apresentação acadêmica. **Estado:** PNG de fundo preparado e instalador versionado; aplicação na GUI, salvamento e aceite ainda não executados nesta conversa.

## Evidência e fronteira

- Fonte: `main:AGENTS.md` → `main:docs/project/current-state.md` → `main:docs/academic/requirements.md` → `main:docs/project/qlikview-powershell-automation.md` → `main:docs/project/sad-vis-04-final-presentation-polish-runbook-2026-11-10.md`.
- Print-base real da folha 2 fornecido em 12/11/2026: `image(20261112-190706).png` (M2-01 no topo; M2-02 e M2-03 lado a lado abaixo).
- Mockup folha 2 aprovado pelo usuário; para compatibilidade com o acabamento da folha 1, reutilizar o fundo R2 aprovado (sem selo, tipografia reduzida) e trocar apenas o subtítulo para `Leitos Cadastrais Observados • PB / 2017–2019`.
- Vis04 intocável: `C:\Users\pedro\SAD_VIS04_EVIDENCIAS\VIS04_20261110_201240_0d9818e4ab0c\SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw`. SHA esperado: `BE8CB39B59F92F2F173DB309A60EA5FF373CDF87CBFCBC333F5583A21FF539C6`.
- Única cópia tocável: `C:\Users\pedro\SAD_VIS05_EVIDENCIAS\VIS05_20261112_171721_950990d1\SAD_MVP_VIS05_UX_WORK_TEMP.qvw`.
- Não exigir hash inicial da cópia VIS-05: a folha 1 já recebeu edições legítimas. O instalador registra SHA antes/depois e falha se a cópia mudar durante o processo.
- Capturas são manuais pelo operador. O instalador **não** modifica QVW, scripts, QVDs ou PDF; **não** usa COM, Reload, Save ou screenshot automático.

## Gate P2.1: fundo estático

- Pacote externo: `SAD_VIS05_P2_FUNDO_LEITOS.zip` SHA-256 `72BD7968842464EC028DDFC777CCED864ABC85C80451E8B05E94DDC0FF25ED3F`.
- Instalador versionado: `tools/Install-SadVis05LeitosAssets.ps1`, branch `proposal/sad-vis-05-shell-evidences-2026-11-12`, commit de origem informado ao operador.
- Asset de fundo: `assets/vis05_sheet02_leitos_fundo_r2_1920x1080.png`, SHA-256 `2FF32A171CA6EA69F5DAD5E56EED1B85EF857DBB1EE03C7D64701747C5A43787`.
- Após `VERDICT=PASS_FILES_INSTALLED_ONLY`, aplicar manualmente em Propriedades da Folha → Geral → Plano de fundo → Imagem → Preencher.
- **STOP/Review:** print manual sem salvar a nova imagem; conferir título, proporção e posição dos três objetos. A existência do PNG não prova o estado GUI.

## Gate P2.2: acabamento dos objetos nativos (somente depois de aprovação P2.1)

- M2-01: título `Leitos cadastrados por competência — snapshots`; 2 séries `Leitos SUS` e `Leitos existentes`. **Não** somar períodos e não alterar séries.
- M2-02: título `Leitos SUS observados — município, 201912`; recorte temporal **fixo 201912**; preservar ranking e rótulo de município DATASUS.
- M2-03: `Observabilidade LT | PB 2017–19 | sem filtros globais` continua ilha observacional; não confundir ausência de linha com zero. Cores semânticas âmbar/turquesa/cinza e três classes inalteradas.
- Replicar o piloto M1 com título ativo/inativo fundo RGB(220,239,242), texto RGB(23,49,61), Segoe UI 11pt (10pt apenas se título cortar), sombra `Sem Sombra`, borda `1 pt` no modo simplificado. Não executar `Aplicar A...` indiscriminadamente.
- Preservar disposição dos três objetos (linha em largura total acima, ranking e observabilidade abaixo) e layout-base da folha; não implementar gráficos descritos apenas em renders de IA, que não representam os dados físicos.

## Aceite e pendências

- `P2_ASSET=READY`, `P2_INSTALL=NOT_EXECUTED`, `P2_GUI=NOT_REVIEWED`.
- `P1_1366x768=INCONCLUSIVE` e `P1_POST_REOPEN=INCONCLUSIVE`; essas pendências permanecem separadas e não são promovidas a PASS pela continuidade.
- Nenhum merge, nova recarga, homologação científica ou alteração da entrega final é autorizado pelo gate.
