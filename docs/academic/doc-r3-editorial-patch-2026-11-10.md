# DOC-R3 — Revisão editorial localizada do relatório SAD (10/11/2026)

**Modalidade:** proposta de substituição documental, sem alterações físicas no QVW/QVD/QVS ou na `main`. Nova frente autônoma após VIS-03 e VIS-02-P1. **R2 é a fonte textual primária**: `SAD_A4_Relatorio_Consolidado_R2_Editorial.pdf` — 98 páginas, versão de 09/11/2026, localizado no acervo deste Projeto GPT e inspecionado como texto extraído (páginas físicas 18–28). O arquivo PDF binário **não pôde ser materializado** neste ambiente; por isso não se declara a revisão como PDF integral consolidado.

## 1. Fontes e decisões inalteradas

1. `main:AGENTS.md`; 2. `main:docs/project/current-state.md`; 3. `main:docs/academic/requirements.md`; 4. [plano acadêmico Draft #230](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/230); 5. [VIS-02 #231](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/231), [VIS-03 #232](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/232), [P1 CH06 #233](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/233) e imagens reais recebidas em 10/11; 6. documento oficial do professor `DescricaoProjetoSAD.pdf`.

O professor exige Cap. 3 com comentários sobre a ferramenta de BI e prints das visões criadas, Cap. 4 considerações finais, Cap. 5 referências, Anexos I/II com scripts integrais, três painéis, ao menos seis dimensões e uma fato. A primeira entrega com Capítulos 1–2 foi reportada em 13/10/2026; **não alterar Cap. 1–2** nem diagramas ou conceitos. A segunda avaliação foi informada para 08/12/2026, via Classroom, sem verificação direta da atividade.

O relatório R2 já contém três folhas/nove visuais, Capítulos 3–5, referências e 70 páginas de anexos. Trata-se de **revisão do material já existente**, não escrita integral nova. As três folhas foram aceitas pelo operador como satisfação do mínimo de três painéis **para a disciplina**, mas a `main` mantém o blueprint formal de 14 visuais; o MVP é um candidato temporal experimental, não a Fase IX homologada.

## 2. Inventário exato de páginas a substituir

Páginas físicas do PDF R2, contando capa como página 1. As páginas impressas no rodapé de R2 são 19–26.

| Física R2 | Página impressa | Conteúdo | Intervenção DOC-R3 |
| --- | --- | --- | --- |
| 21 | 19 | Cap. 3 e §3.1 | Preservar arquitetura e grãos, atualizar a nota do estado visual |
| 22 | 20 | §3.2/Figura 7: Produção Hospitalar | Atualizar screenshot para VIS-03, preservar 183.532/183.311/188.246, 555.089 e 36 competências como oráculos reportados |
| 23 | 21 | §3.3/Figura 8: Leitos Cadastrais | **Substituir figura por CH06/M2-03 corrigido e persistido**; explicar 4.467, 3.464 e 97 células, não municípios |
| 24 | 22 | §3.4/Figura 9: Fluxos/POP | Atualizar screenshot VIS-03 sem filtros e preservar 294.635/260.454 |
| 25 | 23 | §3.5/Figuras 10–11: guardas | Screenshot restrito de CH05 201912 versus seleção 201801 e aviso de população mensal CH09; não afirmar cobertura global |
| 26 | 24 | §3.6: síntese | Informar VIS-03 PASS GUI local restrito, integridade fonte hash reportada e transmissão online não ensaiada |
| 27 | 25 | Cap. 4 | Atualizar estado de acabamento e ressalvas sem apresentar produção como aprovada |
| 28 | 26 | Cap. 5 | Manter referências da R2 (sem inventar nova consulta) e verificar paginação |
| 1–20 | — | Capa, sumário, Cap. 1–2 | **Preservação integral obrigatória** |
| 29–98 | — | Anexos I/II e scripts QVS originais | **Preservação integral obrigatória** |

**Atenção:** a inclusão do *caderno substitutivo* de oito páginas, isolado, não altera o PDF R2 original. Só depois de acesso ao PDF original **em bytes** se poderá efetivar a troca 21–28 e validar que o PDF final resultante ainda possui 98 páginas, figuras e scripts integrais sem alterações nas demais páginas. Se tal arquivo não estiver disponível, **não** simular sua preservação reconstruindo texto extraído.

## 3. Evidências de figuras (arquivos mantidos fora do Git)

| Figura | Evidência real fornecida pelo operador | Natureza/limite |
| --- | --- | --- |
| 7 — folha 1 | `image(20261110-150448).png` | Screenshot da QVW VIS-02 em estado sem filtros visíveis; M1-01/02/03 |
| 8 — folha 2 | `image(20261110-200952).png` | **Cópia CH06 corrigida** pós-save/close/reopen reportado; sem `*` na janela, três legendas corretas e não sobrepostas |
| 9 — folha 3 | `image(20261110-150502).png` | Screenshot VIS-03 sem seleções visíveis; não é readback de propriedades |
| 10 — aviso CH05 | `image(20261110-151027).png` | Imagem de seleção `201801`, indicador fixo em `201912` indisponível; **recortar apenas CH05** para não mostrar o CH06 anterior com rótulos ilegíveis |
| 11 — aviso CH09 | `image(20261110-175604).png` | Imagem posterior à correção do overflow do aviso; período mensal incompatível com POP anual; não há caixa `Seleções Atuais` para auditar todos os filtros |

**Hash e proveniência da figura 8:** QVW TEMP corrigida pós-save `6ED9CC1FAA5AFD592D1D4CECC8D6FC5DE2AB84D4DCE2D4E6D3E6A25E59D7BE37` conforme PowerShell reportado. `SOURCE_UNCHANGED=True` e `PROTECTED_C4_UNCHANGED=True`. PNG local pós-reabertura `4EAD80B8C9DAD4A884F8AE0032803933F2A53D2FC5051013F0BA97A01C40BE0E` reportado; cópia enviada ao chat pode diferir em bytes. Não transformar hash da QVW em prova semântica global.

**Correção gráfica demonstrada:** âmbar = `ABSENT_NOT_ZERO_PROVEN` (sem linha LT; não significa zero), verde-azulado = `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED` (SUS positivo observado), cinza = `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` (SUS zero observado). As contagens antigas do R2 são referências do oráculo experimental, não conferência independente desta edição GUI.

## 4. Atualização textual por seção

- **§3.1:** manter a descrição do fluxo `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`, três fatos, oito dimensões, papéis RES/SERV, granularidades. Acrescentar que VIS-03 é validação visual local restrita e que R2/Capítulos 1–2 não foram remontados.
- **§3.2:** manter definições e números; atualizar apenas legenda e data de Figura 7.
- **§3.3:** atualizar Figura 8 com a QVW CH06; explicitar categoria AUSENTE ≠ ZERO, ilha independente e escopo hospitalar não verificado. Não apresentar 7.140 leitos de dezembro/2019 como ocupação.
- **§3.4:** manter M3-01, M3-02, M3-03 e legenda da Figura 9. Ressaltar POP anual, sem soma 2017+2018+2019.
- **§3.5:** substituir Figuras 10–11 e descrever que `201801` foi um cenário de verificação restrita; não prometer prevenção em todas as rotas nativas nem anunciar C2 aprovado.
- **§3.6:** o acabamento de CH06, avisos CH05/CH09, rolagem dos rankings e três folhas passaram em visual restrito; falta conferir legibilidade no **compartilhamento online real**. Expressões, associações, C2/C3/C4/P5, cobertura hospitalar histórica e Fase IX continuam pendentes.
- **Cap. 4:** atualizar conclusão com distinção entre viabilidade acadêmica e produto operacional. Preservar oráculos do R2 como dados reportados (555.089 internações, 7.140 leitos SUS em 201912, 4.018.127 pessoas 2019), não confirmar recálculo.
- **Cap. 5:** referências do R2 não alteradas; URL e edição de ajuda Qlik são referências do próprio R2, não pesquisas novas.

## 5. Aprovação e bloqueios

- `DOC_R3_EDITORIAL_SCOPE=DETERMINED`
- `DOC_R3_R2_EXTRACTED_TEXT=INSPECTED`
- `DOC_R3_R2_PDF_ORIGINAL_BYTES=UNAVAILABLE_FOR_EDIT`
- `DOC_R3_REPLACEMENT_PAGES=IN_PREPARATION` até gerar caderno de oito páginas
- `DOC_R3_COMPLETE_98_PAGE_PDF=NOT_CREATED`
- `DOC_R3_MAIN_OR_CHAPTERS_1_2_CHANGED=False`
- `VIS03_LOCAL_GUI_PRESENTATION_GATE=PASS_RESTRICTED_CLOSED`
- `VIS03_ONLINE_STREAMING_LEGIBILITY=INCONCLUSIVE`
- `C2_C3_C4_GLOBAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`

**STOP:** após revisar o caderno de substituição, encerrar este gate documental sem reabrir QVW, pipelines ou testes. Para compor o **PDF final de 98 páginas**, será necessário receber o PDF R2 original acessível em bytes e realizar cópia/edição no contêiner, substituir apenas páginas 21–28 e conferir páginas/figuras/scripts antes de aprovação. Sem merge automático ou alteração do R2 original.


## 6. Prévia editorial gerada e QA (10/11/2026)

**Caderno produzido neste chat, fora do Git:** `SAD_DOC_R3_Paginas_21_a_28_PREVIA.pdf`, **8 páginas A4** (não 98), SHA-256 `711A95561CC7110E756317ABD25C155985D2B3BAA95305B4B47EF1E74952B6BF`. Arquivo manifesto de QA local `SAD_DOC_R3_Paginas_21_a_28_PREVIA.manifest.json`. Renderização `pdftoppm` concluída para todas as páginas, contato visual das oito páginas inspecionado; a Figura 10 foi corrigida na prévia para mostrar **CH05** (e não o antigo CH06) antes da verificação final de renderização. Não registrar este PDF na `main` nem no Git como documento canônico.

**Qualificação importante:** a prévia foi produzida por um script local de composição `EXPERIMENTAL_NOT_GATE_EVIDENCE`, pois não foi possível transferir a versão commitada via rede para o ambiente de execução. O gerador reprodutível proposto está versionado em `tools/build_sad_doc_r3_replacement_pages.py` (commits `eea1eb73cc05b310f88cf2c751a28a4eb390c6c2` e correção de recorte `aca394cd7f11d823bccdf625f1cfcb4799b35924`) mas **não recebeu teste funcional executado a partir do commit**. Portanto: `DOC_R3_PREVIEW_RENDER_QA=PASS_EXPERIMENTAL_EDITORIAL_ONLY` e `DOC_R3_VERSIONED_GENERATOR_WINDOWS_OR_CONTAINER_GATE=NOT_EXECUTED`. Não converter a revisão visual da prévia em homologação de publicação.

**Diferencial em relação ao R2:** na prévia as páginas 21–28 foram recompostas editorialmente com textos equivalentes e figuras atualizadas; isso **não é edição byte-preserving** das páginas 1–20 e 29–98, porque o PDF R2 original não foi materializado. Ao montar a versão final, revisar pontualmente as formulações reescritas para evitar drift e preferir a troca mínima das figuras/legendas sobre mudanças textuais adicionais.

### Critérios faltantes para R3 completo

1. Receber cópia do `SAD_A4_Relatorio_Consolidado_R2_Editorial.pdf` que possa ser realmente aberta em bytes no contêiner (upload explícito ou exportação autorizada). Não reconstruir páginas 1–20 ou anexos de 70 páginas a partir de texto extraído.
2. Compor PDF final de 98 páginas mantendo as páginas **1–20 e 29–98 exatamente do R2**, substituindo as páginas **21–28** conforme revisão aprovada.
3. Conferir numeração das Figuras 7–11, paginação impressa 19–26, sumário, legibilidade da Figura 8 em A4, bibliografia, scripts integrais dos Anexos I/II e total de 98 páginas; comparar renderizações das páginas preservadas. Registro da SHA-256 final e cópia de segurança, sem sobrescrever R2 original.
4. Somente após esses controles: `DOC_R3_FINAL_PDF=READY_FOR_SUBMISSION_REVIEW`. A atividade do Classroom permanece não verificada.

`DOC_R3_SCOPE=8_PAGE_REPLACEMENT_ONLY`; `DOC_R3_PDF_PATCH=PREVIEW_EXPERIMENTAL_GENERATED`; `DOC_R3_FINAL_98_PAGE_PDF=NOT_CREATED`; `CHAPTERS_1_2_AND_APPENDICES_ORIGINAL=NOT_TOUCHED`; `C2_C3_C4_GLOBAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP editorial desta execução:** prévia e documento de revisão preparados, sem editar QVW, QVD, QVS, PDF R2 original, sem merge. A próxima etapa física do PDF depende **somente** do R2 original em bytes, não de novos testes QlikView.


## 7. Justificativa explícita da ilha analítica P23_A1_ISLAND — inclusão editorial solicitada (10/11/2026)

**Dúvida documentada pelo operador:** a tabela `P23_A1_ISLAND` aparece visualmente isolada no visualizador de dados do QlikView 12. A tabela auxilia exclusivamente o **M2-03 (Observabilidade LT)**, não substitui `FATO_CAPACIDADE_LEITO` nem representa uma quarta tabela fato aprovada.

**Verificação estática:** a proposta `PAINEL/sad_p23_a1_island_physical_gate.qvs` na PR #226 cria `P23_A1_ISLAND`, com campos persistidos prefixados `P23_`, sem chave `%LINK_KEY` ou nome associativo compartilhado. O construtor do MVP `tools/Build-SadMvpThreeSheetsTemp.ps1` define dimensão `P23_ESTADO_OBSERVADO` e expressão `Count(P23_MUNICIPIO_6)` para CH06/M2-03. A desconexão é proposital para que seleções globais não alterem a contagem de células município × competência. Contrato experimental em branch Draft, não mudança física na `main`.

**Texto DOC-R3 incorporado ao §3.3:** “A tabela auxiliar `P23_A1_ISLAND` foi criada intencionalmente sem chaves compartilhadas com o modelo associativo principal, como `%LINK_KEY`. Por isso, M2-03 apresenta o panorama fixo da PB em 2017–2019 e não acompanha filtros globais. A ilha não constitui uma quarta tabela fato da constelação acadêmica. Mesmo quando existe linha LT observada, seu campo não comprova o recorte estritamente hospitalar histórico. As legendas passaram por validação visual local restrita, não por certificação científica de CNES.”

**Estado:** `DOC_R3_P23_ISLAND_EXPLICIT_JUSTIFICATION=VERSIONED_IN_GENERATOR`; `DOC_R3_PDF_REGENERATION=NOT_YET_EXECUTED`; `DOC_R3_FINAL_98_PAGE_PDF=NOT_CREATED`. O arquivo R2 foi localizado na Biblioteca de arquivos do ChatGPT pelo nome `SAD_A4_Relatorio_Consolidado_R2_Editorial.pdf`, porém a transferência dos bytes originais para o contêiner retornou indisponibilidade de materialização. A busca PowerShell realizada pelo operador em `$env:USERPROFILE` não encontrou esse nome no Windows. O PDF R2 **não foi apagado** com base nessas buscas; sua presença na Biblioteca permite recuperar via interface, se disponível. Não inventar caminho Windows ou link de download.

## 8. Prévia corrigida com justificativa P23 e inspeção de regressão (10/11/2026)

**Artefato fora do Git:** `SAD_DOC_R3_Paginas_21_a_28_PREVIA_P23.pdf`, SHA-256 `555EE94FCB8ACFBB501FD0A3C621BBBA05567BDCB0019048EB7AA02941CD8904`, **8 páginas A4**. A geração utilizou uma cópia do gerador local anterior ajustada com o texto da seção 7, sem acesso aos bytes do R2; portanto o resultado permanece `EXPERIMENTAL_NOT_GATE_EVIDENCE`, não execução homologada do gerador commitado.

**QA observacional:** documento aberto por PyMuPDF, 8 páginas contadas; texto extraído da página física 3 da prévia contém `P23_A1_ISLAND`, a ausência de ligação com `%LINK_KEY` e a ressalva de que não se trata de quarta fato. O texto normalizado das demais 7 páginas é idêntico ao da prévia anterior `SAD_DOC_R3_Paginas_21_a_28_PREVIA.pdf`. A página 3 foi renderizada e inspecionada visualmente: justificativa legível, imagem da folha 2 presente, sem transbordamento do quadro nem extrapolação de página. Essas verificações **não** provam preservação das páginas 1–20 ou 29–98 do R2 — a composição do PDF final está bloqueada pela ausência de bytes originais.

**Status final deste subgate:** `DOC_R3_P23_DESCRIPTION=PASS_PREVIEW_EDITORIAL_RESTRICTED`; `DOC_R3_PREVIEW_8_PAGES=RENDERED_INSPECTED`; `DOC_R3_UNCHANGED_PREVIEW_PAGES=7_OF_8_TEXT_IDENTICAL`; `DOC_R3_FINAL_98_PAGE_PDF=NOT_CREATED`; `R2_ORIGINAL_BYTES=UNAVAILABLE`. STOP sem novas alterações QlikView e sem merge.


## 9. DOC-R3 integral consolidado — fonte R2 recebida e preservação auditada (10/11/2026)

**Atualização superveniente aos §§1–8:** o responsável anexou neste chat o **arquivo PDF binário original** `SAD_A4_Relatorio_Consolidado_R2_Editorial(1).pdf` (98 páginas) em `/mnt/data/`, SHA-256 `E64A09F34C636A3FFDE2A4D377FCEE9ABA9E08171063178BD87A56518EC9694D`. Assim, **o bloqueio anterior de ausência dos bytes do R2 foi removido** nesta execução. O R2 recebido foi lido e mantido sem escrita.

**Composição física realizada em cópia nova:** substituir as páginas físicas **21–28** (Capítulos 3–5) pelo caderno editorial final de oito páginas; importar intactas as páginas **1–20** (capa, sumário, Capítulos 1–2) e **29–98** (Anexos I/II com scripts). O caderno de substituição foi gerado no contêiner por compositor local adaptado da prévia, com a justificação `P23_A1_ISLAND` no §3.3, títulos, numeração impressa 19–26 e rodapé editorial de QVW TEMP, **sem** a marca `PRÉVIA SUBSTITUTIVA`. Nenhum PDF original foi substituído.

| Artefato PDF | Páginas | SHA-256 |
| --- | ---: | --- |
| R2 original recebido | 98 | `E64A09F34C636A3FFDE2A4D377FCEE9ABA9E08171063178BD87A56518EC9694D` |
| Caderno DOC-R3 final de substituição | 8 | `7E8D035DD5CEAEE0D3734CBDDE343148E138F033A82A8ED88D889B4CE0CDEE4E` |
| **DOC-R3 integral consolidado (candidato acadêmico)** | **98** | **`DA04BB440DC57DDD9DFB20331AFB548EDC3142143E82A0C92605EC8B7904CB01`** |

**Caminho do artefato nesta sessão:** `/mnt/data/SAD_Data_Mart_SUS_PB_Relatorio_DOC_R3_Consolidado_2026.pdf`. Manifesto local de auditoria: `/mnt/data/SAD_DOC_R3_Consolidado_Auditoria.json`. Estes são arquivos da sessão, **não são links permanentes/versionados no GitHub**; o responsável recebeu link de download do ChatGPT. Não adicionar PDFs binários nem dados pessoais ao Git por padrão.

**QA efetivamente realizado, não suposto:**
- Contagem PyMuPDF: exatamente **98 páginas** após montagem; 8 substitutivas A4, com títulos das seções 3, 3.2–3.6, 4 e 5, referências e Figura 7–11.
- Para **todas as 90 páginas preservadas**: comparação página a página de texto extraído, geometria/rotação, quantidade de imagens, quantidade de anotações e renderização RGB a 0,65×; **90/90 idênticas nos cinco controles**, incluindo anexos paisagem. Essa é igualdade visual/estrutural observada no documento resultante, **não identidade byte-a-byte dos objetos PDF** (a composição altera sua estrutura interna).
- Para as **8 páginas substitutivas**: texto extraído e pixels renderizados a 0,65× comparados com o caderno DOC-R3 final: **8/8 idênticas**, com mesmo número de imagens.
- Imagens do capítulo 3 renderizadas do PDF consolidado a **125 dpi** e contato visual das oito páginas inspecionado; nenhuma sobreposição crítica ou corte estrutural identificado. A figura de CH05 usa recorte apenas do aviso, sem incluir o CH06 antigo; a figura da folha 2 inclui CH06 com legendas corrigidas.
- Sumário preservado: capítulos 3–5 seguem nas páginas impressas 19–26; anexos começam nas páginas impressas 27 e 78. O conteúdo do Capítulo 3 inclui justificativa explícita da ilha e a natureza não homologada da QVW TEMP.

**Qualificação e limitações:** `DOC_R3_PDF_ASSEMBLY=PASS_98_PAGES`, `DOC_R3_UNCHANGED_PAGES=PASS_90_OF_90_TEXT_GEOMETRY_IMAGES_ANNOTATIONS_PIXELS`, `DOC_R3_NEW_PAGES=PASS_8_OF_8_TEXT_PIXELS`, `DOC_R3_VISUAL_QA=PASS_EDITORIAL_RESTRICTED`, `DOC_R3_SUBMISSION_STATUS=READY_FOR_ACADEMIC_REVIEW_NOT_SUBMITTED`. As cifras e a semântica QVW dependem de evidências VIS-03/P1 restritas; transmissão online não ensaiada; C2/C3/C4 global, Fase IX e produção permanecem `NOT_APPROVED`.

**Nota de reprodutibilidade:** o PDF final foi materializado por um script compositor **local**, adaptado da prévia experimental e executado nesta sessão. O gerador de páginas commitado nesta branch ainda não teve ensaio de equivalência de saída; **não declarar** que executar apenas `tools/build_sad_doc_r3_replacement_pages.py` recria o mesmo SHA-256. Os SHA acima auditam **estes arquivos efetivamente gerados**. Nenhum merge e nenhuma submissão Classroom foram realizados. Encerra-se este gate editorial com documento integral candidato para leitura e submissão após aceite do responsável.
