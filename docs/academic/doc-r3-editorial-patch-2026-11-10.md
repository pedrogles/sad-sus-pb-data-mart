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
