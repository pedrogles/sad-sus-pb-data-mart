# SAD — VIS-05 | Fechamento documental restrito (15/11/2026)

**Gate:** substituição das Figuras 7–9 do relatório acadêmico DOC-R3 e auditoria documental, **sem alterar QVW/QVD/QVS/modelagem**.
**Status:** `VIS05_DOCUMENTARY_PDF=PASS_RESTRICTED_PDF_INTEGRITY`; `DOC_PR_MERGED=False`; `PRODUCTION_APPROVED=False`.
**Fonte de verdade consultada:** `main@5486ad9f50744769e85107132eae009529ac75cc`: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → `docs/academic/final-delivery-record-2026-11-10.md`; depois VIS-04 e scripts DOC-R3 versionados.

## 1. Proveniência e integridade

O responsável disponibilizou, em 15/11/2026, ZIP `PDF acadêmico com as três capturas finais do VIS-05.zip`, com CRC íntegro, quatro arquivos reais, SHA-256 do ZIP `0F48C22BFC30E8384EEE1703EB96C723114839EF2A880FF3BCF270C821739F95`.

| Insumo | SHA-256 verificado diretamente |
|---|---|
| `SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS04_2026.pdf` | `BB7A6A6D7C2ADC3BE80831F4F8E98642D7CE9D07A25B7F03000A9DF2E8071302` |
| `image(20261115-125358).png` (Fig. 7, folha 1) | `144F0CBCED0AFD20E6FC921EDA21617D6BB6A5C949615DB6E69FCDE0A3E05B71` |
| `image(20261115-125414).png` (Fig. 8, folha 2) | `01970300310460CC5CE6F00A88903F267CDDE3DE435DB5A56168A2714CE294E1` |
| `image(20261115-125441).png` (Fig. 9, folha 3) | `96C539895F6C88345EFFDCE68DE685DC7CBD2A8683ECEAB8EF7E2125EE3EA802` |

As capturas foram examinadas visualmente em estado neutro, com janela QlikView sem asterisco; a confirmação de Save/close/reopen do QVW e a preservação do original VIS-04 são **resultados reportados pelo operador**, não inspeção independente do binário.

**QVW VIS-05 reportado:** `C:\Users\pedro\SAD_VIS05_EVIDENCIAS\VIS05_20261112_171721_950990d1\SAD_MVP_VIS05_UX_WORK_TEMP.qvw`.
**SHA-256 QVW reportado (não revalidado):** `B56D0A8550AB7EEE68D45DB0249F273DED05C4ADEE88DBE3FC7A20B162084DBB`.

## 2. Script versionado antes da execução

`tools/patch_sad_doc_r3_vis05_figures.py`, branch `docs/sad-vis05-pdf-figures-2026-11-15`, commit de origem `33a916819173f99694f8af57363411b03e6385ac`, Git blob `36f65658e78977e0d7766902cf3ac387fedd4365`. A cópia executada apresentou o mesmo Git blob SHA; nenhuma alteração posterior do script foi usada. Os valores SHA-256 dos insumos estavam fixados no código.

Não foi executado QlikView/COM/Reload; nenhum QVW/QVD/QVS foi editado. Os arquivos binários são mantidos fora do Git.

## 3. Artefato de saída e auditoria

**Novo PDF, fora do Git:** `SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS05_2026.pdf`.
**SHA-256 independente da saída:** `4C6033F3131F4B05105BBFCD992A2A6E7896CD5A2D424BF0BEA513430D0ED9F3`; tamanho **2.712.727 bytes**.

- **98/98** páginas; **apenas páginas físicas 22–24** editadas, figuras 7, 8 e 9 e suas legendas VIS-04 → VIS-05.
- **95/95** páginas restantes iguais à origem em texto, geometria, contagem de imagens e rasterização RGB a 0,7×; a comparação **não alega bytes PDF internamente idênticos**, pois a gravação altera a estrutura do arquivo.
- Nas páginas modificadas, texto fora das legendas preservado, retângulos e posições das imagens mantidos e rasterização confirmada diferente.
- Capturas novas recortadas para retirar a moldura do aplicativo/barra de tarefas, preservar os 3 objetos por folha e caber nos retângulos já reservados.
- As três páginas foram renderizadas a 1,8× e inspecionadas visualmente: figuras e legendas sem corte ou sobreposição crítica.
- **Fonte PDF e PNGs intactos**, comprovados por leitura/hash dos bytes; não houve sobrescrita.

**Manifesto da execução (fora do Git):** `SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS05_2026.pdf.audit.json`. Armazenar o PDF e o manifesto de modo persistente; links de sessão não são storage permanente.

## 4. Limitações e gates separados

- Residência externa à PB pode aparecer com código sem descrição nominal; **não imputar nomes sem fonte oficial**.
- `P23_A1_ISLAND` é auxiliar desconectada e não constitui quarta fato; ausência de LT ≠ zero; ranking M2-02 em `201912`.
- M3-01: apresentação e rótulos de estado neutro não homologam comportamento dinâmico sob qualquer seleção.
- Indicadores cruzados e os contratos `C2_C3_C4_GLOBAL=NOT_APPROVED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`.
- `ONLINE_REHEARSAL=NOT_RUN`, `TEACHER_THREE_SHEETS_AS_THREE_PANELS=UNVERIFIED`, `CLASSROOM_SUBMISSION=NOT_SUBMITTED`; segunda avaliação em **08/12/2026** informada pelo operador, não confirmada independentemente.

**Aceite do gate:** `VIS05_PDF_FIGURE_PATCH_QA=PASS_RESTRICTED` em auditoria de arquivos; `VIS05_QVW_LOCAL_GUI=PASS_RESTRICTED_WITH_OPERATOR_EVIDENCE`, sem homologação semântica/produção. A integração desta documentação em `main` exige aprovação e merge separados.

**STOP:** encerrar a edição documental; próximo gate separado é ensaio online, confirmação docente, conferência final de cópia persistente e submissão no Classroom.