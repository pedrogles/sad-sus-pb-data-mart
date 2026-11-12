# Current State — SAD Data Mart SUS PB

## Estado operacional — 11/11/2026 | entrega final delimitada, higiene GitHub em lotes

**Proveniência:** [PR #237](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/237) e [PR #238](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/238) foram integradas à `main@e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9`. Os registros de implementação acadêmica continuam delimitados às evidências locais reportadas, **sem conceder novos aceites físicos ou docentes**. Os inventários GitHub são snapshots pinados, não contadores sempre atualizados.

**Fontes obrigatórias:** `AGENTS.md` → este documento → [requisitos acadêmicos](../academic/requirements.md) → [registro final](../academic/final-delivery-record-2026-11-10.md) → [auditoria dos oito PRs](academic-pr-coverage-audit-2026-11-11.md) → [inventário GitHub atual, snapshot de 161 refs](repository-branch-inventory-2026-11-11.json) e [runbook de backup](repository-branch-backup-runbook-2026-11-11.md).

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
| GitHub | **PRs #237/#238 MERGED**; **32 PRs históricos/acadêmicos CLOSED_NOT_MERGED** com justificativas individuais; **0 PRs abertos**. Issues #157/#196 **CLOSED_NOT_PLANNED**, ambas sem aceitar seus gates; **0 issues abertas**. Snapshot de 11/11/2026 antes da nova branch: **161 refs** (102 de PRs merged, 53 de PRs fechados sem merge, 5 órfãs, main). **Nenhuma branch excluída.** Dos 47 arquivos dos oito PRs acadêmicos, 23 estão copiados na main (16 pela #237 e 7 pela #238); **24 exclusivos históricos** requerem retenção/backup. Scripts de dry-run e backup nesta **PR de preparação**, ainda não integrados na main. O operador reportou **PASS local** no Windows para backup/restauração de **162/162 refs**, sem drift e sem mutações remotas; apenas **4/102** branches associadas a PRs merged são ancestrais da main (**98/102 HOLD**). Os manifestos e o bundle permanecem locais, sem inspeção independente nem prova de cópia externa redundante. Ver [closeout do backup](repository-branch-backup-operator-result-2026-11-11.md). A branch de preparação também contém **executor final SHA-leased em modo Preview**, ainda não executado e sem autorização de exclusão. Sua opção de arquivamento integral removeria 53 PRs closed-unmerged e 5 órfãs **com commits não integrados** (retidos no bundle), além de 102 merged e da #239 após merge; consulte o [runbook](repository-branch-backup-runbook-2026-11-11.md). |

### Limites, decisões e bloqueios

- **C2 guiado/full, C3 Link Key, C4 medidas/denominadores/P5:** nenhum aceite global implícito pelo QVW final acadêmico ou pelas evidências restritas de telas. `C2_C3_C4_GLOBAL=NOT_APPROVED`.
- **CNES/LT histórico T25/T26:** ausência de linha ≠ zero; cobertura estritamente hospitalar histórica não homologada. `T29_HISTORICAL=NOT_APPROVED`, e a legenda CNES de 09/2019 não se aplica retroativamente sem justificativa. `P23_A1_ISLAND` é auxiliar observacional desconectada, não quarta fato.
- **Categorias manuais M3-01:** legíveis em estado sem filtros; mudança dinâmica sob seleção/ordenação **não validada**. Ranking M2-02 é fixo em `201912`; inconsistências temporais devem ser explicadas, não escondidas.
- **Sem Fase IX de produção.** `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
- **Escopo acadêmico final:** não estão previstos novos KPIs nem retomada do roadmap de 14 objetos; indicadores não apresentados estão justificados no §3.7/§4.1 do DOC-R3. A conclusão acadêmica não converte lacunas em PASS científico.

### Próximas ações com condição de parada

1. **GitHub:** revisão da [PR #239](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/239) para um lote final de higiene. O backup/restauração de 162 refs recebeu PASS local reportado. O snapshot identifica **102 branches de PRs merged**, 53 closed-unmerged e 5 órfãs; as 58 não integradas somente podem ser **arquivadas intencionalmente**, nunca tratadas como merged. **Decisão de 12/11/2026:** o responsável escolheu somente a **limpeza conservadora das 102 branches de PRs merged**. O executor na PR #239 foi restringido a `Preview`/`DeleteMerged102` e agora protege também a branch da [PR #240](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/240). As 58 refs históricas não integradas permanecem `HOLD`; nenhuma exclusão foi executada. Backup local restaurado foi reportado, mas falta cópia redundante verificada fora do dispositivo, Preview Windows do executor revisado e autorização separada de merge da #239. A exclusão, quando liberada, ocorrerá no Windows sob `--force-with-lease` SHA a SHA, sem modificar `main`.
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
