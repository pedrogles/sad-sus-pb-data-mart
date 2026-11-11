# Current State — SAD Data Mart SUS PB

## Estado proposto em 10/11/2026 — entrega acadêmica final, revisão e higiene do GitHub

**Proveniência:** este documento foi preparado sobre `main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83` (HEAD da auditoria anterior à consolidação). Torna-se fonte operacional da `main` **somente depois de merge expressamente autorizado**. Reconcilia evidências locais reportadas e documentos antes mantidos em Drafts, **sem conceder novos aceites físicos ou docentes**.

**Fontes obrigatórias:** `AGENTS.md` → este documento → [requisitos acadêmicos](../academic/requirements.md) → [registro final](../academic/final-delivery-record-2026-11-10.md) → [inventário de higiene](repository-final-hygiene-inventory-2026-11-10.json) e [plano de limpeza](repository-final-hygiene-plan-2026-11-10.md).

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
| GitHub | No snapshot remoto anterior à branch de higiene: **159 branches** (100 associadas a PRs merged, 32 Draft, 21 de PRs fechados sem merge, 5 sem PR e `main`), **32 PRs Draft abertos**, **2 issues** (#157, #196). Há trabalho acadêmico final disperso em #226, #230–#236 e scripts de evidência em branches. O inventário e a convergência estão nesta PR Draft, **nenhuma exclusão/fechamento/merge foi feito**. |

### Limites, decisões e bloqueios

- **C2 guiado/full, C3 Link Key, C4 medidas/denominadores/P5:** nenhum aceite global implícito pelo QVW final acadêmico ou pelas evidências restritas de telas. `C2_C3_C4_GLOBAL=NOT_APPROVED`.
- **CNES/LT histórico T25/T26:** ausência de linha ≠ zero; cobertura estritamente hospitalar histórica não homologada. `T29_HISTORICAL=NOT_APPROVED`, e a legenda CNES de 09/2019 não se aplica retroativamente sem justificativa. `P23_A1_ISLAND` é auxiliar observacional desconectada, não quarta fato.
- **Categorias manuais M3-01:** legíveis em estado sem filtros; mudança dinâmica sob seleção/ordenação **não validada**. Ranking M2-02 é fixo em `201912`; inconsistências temporais devem ser explicadas, não escondidas.
- **Sem Fase IX de produção.** `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
- **Escopo acadêmico final:** não estão previstos novos KPIs nem retomada do roadmap de 14 objetos; indicadores não apresentados estão justificados no §3.7/§4.1 do DOC-R3. A conclusão acadêmica não converte lacunas em PASS científico.

### Próximas ações com condição de parada

1. **GitHub:** revisar esta consolidação e selecionar o lote para **aprovar merge específico**, preservando provas. Depois, com **nova autorização explícita**, fechar PRs Draft antigos e issues por motivo verdadeiro `not planned / encerramento do escopo acadêmico`. Em seguida validar SHAs/backup antes de excluir branches; a conexão usada não oferece exclusão de refs remotas.
2. **Acadêmico:** garantir cópia persistente e hash do PDF/QVW; realizar uma sessão de ensaio online, confirmar aceitação das três folhas pelo professor e submeter PDF no Classroom. Registrar protocolo de entrega se houver.
3. **STOP:** quando GitHub estiver reconciliado e entrega submetida, encerrar projeto acadêmico. Sem novos testes QlikView ou mudanças na arquitetura por consequência automática de limpeza.

### Status canônico resumido, após integração autorizada

`ACADEMIC_IMPLEMENTATION_SCOPE=FINAL_3_SHEETS_9_VISUALS`  
`VIS04_LOCAL_GUI=PASS_RESTRICTED`  
`DOC_R3_FINAL_PDF=GENERATED_QA_PASS_NOT_SUBMITTED`  
`ONLINE_REHEARSAL=NOT_RUN`  
`TEACHER_ACCEPTANCE=UNVERIFIED`  
`C2_C3_C4_GLOBAL=NOT_APPROVED`  
`PHASE_IX=NOT_AUTHORIZED`  
`PRODUCTION_APPROVED=False`

Detalhes históricos, commits, logs, hashes completos e resultados experimentais permanecem nos documentos de Discovery e PRs correspondentes; **não** reproduzir a cronologia inteira aqui.
