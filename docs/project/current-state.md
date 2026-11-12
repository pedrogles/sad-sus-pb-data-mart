# Current State — SAD Data Mart SUS PB

## Estado operacional — 12/11/2026 | higiene conservadora encerrada, entrega acadêmica pendente

**Proveniência:** PRs [#237](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/237), [#238](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/238) e [#239](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/239) integradas; a execução de higiene foi conferida sobre a `main@dc05bf1fb5fa22b837777565d06506001c6eddf7`. Os registros de implementação acadêmica continuam delimitados às evidências locais reportadas, **sem conceder novos aceites físicos ou docentes**. Os inventários GitHub são snapshots pinados, não contadores sempre atualizados.

**Fontes obrigatórias:** `AGENTS.md` → este documento → [requisitos acadêmicos](../academic/requirements.md) → [registro final](../academic/final-delivery-record-2026-11-10.md) → [auditoria dos oito PRs](academic-pr-coverage-audit-2026-11-11.md) → [inventário histórico de 161 refs](repository-branch-inventory-2026-11-11.json), [runbook de backup](repository-branch-backup-runbook-2026-11-11.md) e [closeout da limpeza](repository-conservative-branch-cleanup-closeout-2026-11-12.md).

### O que foi concluído e o que não foi

| Camada | Estado atual, com qualificação da evidência |
| --- | --- |
| Primeira entrega | Capítulos 1–2 entregues impressos em **13/10/2026**, segundo o responsável; avaliação docente não confirmada. Modelagem canônica Star/constelação com **três fatos, oito dimensões e granularidades aprovadas**, preservada. |
| Dados/ETL | 108 DBC, 10 QVDs de extração, 12 de transformação e 3 QVWs canônicos conforme **inventários locais históricos reportados**; nenhuma nova auditoria física de dados realizada nesta reconciliação. Fluxo `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL` preservado, QlikView 12 obrigatório. |
| Proposta formal de consumo | A `main` contém blueprint aprovado **de layout** para 3 folhas / 14 visuais pela PR #209. **Não** implica implementação física final nem contrato C2/C3/C4 aprovado. |
| Implementação acadêmica escolhida | O responsável aprovou escopo alternativo **3 folhas / 9 objetos** em 07/11/2026 ([PR #226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226)), para finalizar a segunda entrega. QVW local TEMP **não integrada como binário no Git**; a decisão não altera retroativamente os capítulos acadêmicos. Sem novas implementações planejadas após a segunda entrega. |
| Aceite visual | O QVW VIS-04 corrigido foi salvo e reaberto, três capturas apresentaram 9 objetos e cabeçalhos uniformes sem cortes críticos: **`VIS04_LOCAL_GUI_PRESENTATION=PASS_RESTRICTED`** e **`VIS04_POST_REOPEN_PERSISTENCE=PASS_RESTRICTED_WITH_OPERATOR_EVIDENCE`**. SHA pós-save local reportado `BE8CB39B59F92F2F173DB309A60EA5FF373CDF87CBFCBC333F5583A21FF539C6`. Três origens protegidas com hashes preservados conforme PowerShell local. Não é aprovação visual sob transmissão online nem certificação de expressões/associações globais. |
| Relatório final | `SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS04_2026.pdf` de **98 páginas**, SHA `BB7A6A6D7C2ADC3BE80831F4F8E98642D7CE9D07A25B7F03000A9DF2E8071302`, **gerado e auditado na conversa**. Figuras 7–9 substituídas nas páginas 22–24; outras **95/95** páginas iguais em texto/renderização ao PDF imediatamente anterior. Capítulos 1–2, anexos e justificativa dos indicadores não apresentados preservados. PDF binário **fora do Git**; exigir backup persistente após download. |
| Entrega ao professor | Ensaio de compartilhamento online **não realizado**; PDF **não submetido**; equivalência 3 folhas = 3 painéis não confirmada formalmente pelo professor. Segunda avaliação em **08/12/2026** informada pelo operador, sem confirmação independente no Classroom. |
| GitHub | **PR #239 MERGED** e **limpeza conservadora concluída** em 12/11/2026. A execução local reportou `PASS_DELETE_LEASED`, 102 refs apagadas; a inspeção independente no GitHub confirmou **102/102 candidatas ausentes**, **58/58 refs históricas preservadas com SHA inalterado**, `main@dc05bf1`, branch #239 e branch da [PR #240](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/240) intactas. **61 refs remotas** no instante da conferência, antes da criação de uma branch documental separada. O responsável aceitou o risco de guardar um único bundle local. Relatórios CSV/JSON locais não foram inspecionados independentemente. Ver [closeout](repository-conservative-branch-cleanup-closeout-2026-11-12.md). A PR #240 continua **Draft/OPEN**, sem migração de scripts/arquivos finalizada. |

### Limites, decisões e bloqueios

- **C2 guiado/full, C3 Link Key, C4 medidas/denominadores/P5:** nenhum aceite global implícito pelo QVW final acadêmico ou pelas evidências restritas de telas. `C2_C3_C4_GLOBAL=NOT_APPROVED`.
- **CNES/LT histórico T25/T26:** ausência de linha ≠ zero; cobertura estritamente hospitalar histórica não homologada. `T29_HISTORICAL=NOT_APPROVED`, e a legenda CNES de 09/2019 não se aplica retroativamente sem justificativa. `P23_A1_ISLAND` é auxiliar observacional desconectada, não quarta fato.
- **Categorias manuais M3-01:** legíveis em estado sem filtros; mudança dinâmica sob seleção/ordenação **não validada**. Ranking M2-02 é fixo em `201912`; inconsistências temporais devem ser explicadas, não escondidas.
- **Sem Fase IX de produção.** `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
- **Escopo acadêmico final:** não estão previstos novos KPIs nem retomada do roadmap de 14 objetos; indicadores não apresentados estão justificados no §3.7/§4.1 do DOC-R3. A conclusão acadêmica não converte lacunas em PASS científico.

### Próximas ações com condição de parada

1. **GitHub:** gate de exclusão conservadora de 102 refs **ENCERRADO** após verificação remota independente. **Não repetir o executor** contra o inventário antigo nem remover as 58 refs históricas protegidas. Consolidar apenas este [closeout](repository-conservative-branch-cleanup-closeout-2026-11-12.md) por PR documental sob aprovação de merge separada; a [PR #240](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/240) segue Draft e é um escopo distinto, ainda apenas inventário/decisão. Guardar bundle único, manifestos e logs fora do Git conforme o risco já aceito.
2. **Acadêmico:** garantir cópia persistente e hash do PDF/QVW; realizar uma sessão de ensaio online, confirmar aceitação das três folhas pelo professor e submeter PDF no Classroom. Registrar protocolo de entrega se houver.
3. **STOP:** quando GitHub estiver reconciliado e entrega submetida, encerrar projeto acadêmico. Sem novos testes QlikView ou mudanças na arquitetura por consequência automática de limpeza.

### Status canônico acadêmico preservado (independente da higiene do GitHub)

`ACADEMIC_IMPLEMENTATION_SCOPE=FINAL_3_SHEETS_9_VISUALS`  
`VIS04_LOCAL_GUI=PASS_RESTRICTED`  
`DOC_R3_FINAL_PDF=GENERATED_QA_PASS_NOT_SUBMITTED`  
`ONLINE_REHEARSAL=NOT_RUN`  
`TEACHER_ACCEPTANCE=UNVERIFIED`  
`C2_C3_C4_GLOBAL=NOT_APPROVED`  
`PHASE_IX=NOT_AUTHORIZED`  
`PRODUCTION_APPROVED=False`

Detalhes históricos, commits, logs, hashes completos e resultados experimentais permanecem nos documentos de Discovery e PRs correspondentes; **não** reproduzir a cronologia inteira aqui.
