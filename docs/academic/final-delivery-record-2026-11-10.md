# SAD — Registro canônico candidato da segunda entrega acadêmica (2026.2)

## Revisão de leitura e consistência — 23/11/2026

PDF vigente: `SAD_Data_Mart_SUS_PB_Relatorio_Uniformizado_2026-11-23.pdf`, **86 páginas**, SHA-256 `C74342B1B5A19885D5F406E71A5D7C443292F016048E57E2FFE1D747DA9DF1CB`. Foram corrigidas concordâncias introduzidas pelas substituições editoriais (amostras/estruturas), uma abertura repetida, a enumeração das oito dimensões e o comentário que descrevia 2.021 combinações de tipo/código de leito e competência como pares por mês. O eixo anual da Figura 7 foi corrigido **na apresentação do PDF**, por sobreposição vetorial limitada ao rótulo: `Ano de competência`. Os valores, barras e imagem embutida foram preservados; a renderização da figura deixa de ser reprodução pixel a pixel da captura nesse rótulo. O QVW continua inalterado e seu eixo não foi corrigido fisicamente. Os 74 blocos de comentários continuam padronizados, e a sequência executável dos 13 scripts foi comparada e preservada. Executor publicado antes da execução: `51b627c1e0d91244d0e3212b718bf54cd1c6aec9`. Documento renderizado e conferido, com atenção ao eixo corrigido e à enumeração; sumário e paginação atualizados. Os registros abaixo são históricos; esta identificação supera a versão anterior de 85 páginas. Nenhum novo teste QlikView, merge, alteração de dados ou submissão. Permanecem os limites metodológicos e as confirmações docentes, o ensaio e a entrega.

## Comentários dos anexos e referência temporal — revisão posterior em 23/11/2026

PDF vigente: `SAD_Data_Mart_SUS_PB_Relatorio_Uniformizado_2026-11-23.pdf`, **85 páginas**, SHA-256 `12744D2312042283CD10A09F651A0D976631E65F80A3170A8FA56AC1ACE738F4`. A pedido do responsável, foram padronizados 74 blocos de comentários nas listagens dos 13 scripts, em português técnico direto. O gerador compara a sequência de todas as linhas executáveis antes/depois e confirma preservação exata. Os QVS de origem continuam intactos; somente a apresentação dos comentários no PDF foi alterada. A explicação de `PERIODO_ANO` foi integrada ao parágrafo de M1-01, removendo a antiga nota editorial sobre a captura. A imagem e o QVW não foram modificados. Executor/conteúdo commitados antes da execução em `90c8fe56d36e65f25de1734823e4a42fd8b86f77`. Conferidos a paginação, os limites do texto, as figuras e as listagens renderizadas. Esta revisão substitui a apresentação de 86 páginas registrada abaixo; não altera os resultados científicos, os tachados, as pendências docentes, o ensaio ou a submissão.

## Revisão editorial integral — 23/11/2026

A versão acadêmica vigente foi uniformizada em **86 páginas**: `SAD_Data_Mart_SUS_PB_Relatorio_Uniformizado_2026-11-23.pdf`, SHA-256 `1519E2B2C665FDFCB3B968A3705363F8901FE89123B27F6473B7DCC2B83F433C`. O sumário, as tabelas, os cabeçalhos e a paginação foram padronizados. Os três indicadores derivados não implementados estão tachados, com justificativas metodológicas; o texto acadêmico substitui jargão operacional sem apagar as limitações científicas. As 11 figuras e 13 listagens foram preservadas em conteúdo. Não houve operação QlikView ou alteração da modelagem/dados. Registro: [closeout editorial integral](vis05-unified-report-closeout-2026-11-23.md). Esta identificação supera apenas a versão de apresentação anterior; os resultados históricos abaixo permanecem registros de suas respectivas revisões. Confirmações docentes, ensaio e submissão continuam pendentes.

> **Revisão de apresentação de 23/11/2026 — candidata na Draft #242:** usar a nova cópia `SAD_Data_Mart_SUS_PB_DOC_R3_VIS05_Revisado_2026-11-23.pdf`, SHA `F3F1F5C9F677D6F39C1BA7B24A12E4E1A38C33F1736D381B8173BE32CDF43DB3`. Somente p.22 alterada (nota de competência e textos); 97/97 páginas preservadas. [Fechamento e QA](vis05-editorial-closeout-2026-11-23.md); [roteiro final](vis05-presentation-script-2026-11-23.md). Sem alteração de QVW/modelo, merge, ensaio, submissão ou aceite docente presumidos. O conteúdo a seguir preserva os registros anteriores.

**Data da consolidação proposta:** 10/11/2026.  
**Status documental:** `CANDIDATE_FOR_MAIN_REVIEW` — existe somente nesta PR até merge autorizado.  
**Escopo do curso:** desenvolvimento acadêmico **encerrado nesta segunda entrega**, conforme decisão do responsável. Isso não implica envio ao professor, aceite docente, homologação de produção, nem autorização para alterar a modelagem já entregue.

## 1. Modelo, fontes e parâmetros preservados

- DATASUS SIH/SUS RD (internações administrativas), CNES/LT (leitos cadastrais observados), IBGE/SIDRA (população municipal anual). Período **2017–2019**, Paraíba.
- QlikView 12 obrigatório; `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`.
- **Três fatos:** `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`; **oito dimensões** conformadas (conforme `AGENTS.md` e Capítulos 1–2). Granularidades distintas, RES≠SERV como papéis territoriais.
- `IDENT=5` não representa internação nova; `N_AIH` não é PK. Leitos e população são semi-aditivos no tempo; sem linha LT ≠ zero, e internações/leito ≠ ocupação.
- Primeira entrega Capítulos 1 e 2 **informada como entregue impressa em 13/10/2026**, parecer do docente não confirmado. Nenhuma revisão silenciosa da modelagem entregue.

## 2. Produto de apresentação efetivamente demonstrado

**Diferenciar:** o blueprint de **14 visuais** foi aprovado como **proposta/layout** na `main` ([PR #209](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/209)), mas a **implementação acadêmica final demonstrada pelo responsável** tem **3 folhas × 3 objetos = 9 visuais** no QlikView, aprovada para o MVP em decisão de 07/11/2026 na [PR #226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226). Nenhuma ampliação posterior será executada para a disciplina.

| Folha | Objetos Qlik | Função |
| --- | --- | --- |
| Produção Hospitalar | M1-01/02/03 | Novas internações por ano, 36 competências, ranking municipal de atendimento SERV |
| Leitos Cadastrais Observados | M2-01/02/03 | Séries de snapshots, ranking SUS fixo em `201912`, observabilidade LT por município×competência |
| Fluxos e Contexto Territorial | M3-01/02/03 | RES=SERV versus RES≠SERV, pares dirigidos, população municipal por ano |

**Ilha de observabilidade:** `P23_A1_ISLAND` é estrutura auxiliar propositalmente desconectada, independente dos filtros globais, **não** quarta fato. Relatório §3.3 documenta esse motivo. As classes do M3-01 possuem textos livres validados visualmente sem filtros; seu acompanhamento dinâmico de mudanças de ordenação **não foi comprovado**.

**Arquivo QVW TEMP experimental final (mantido fora do Git):**  
`C:\Users\pedro\SAD_VIS04_EVIDENCIAS\VIS04_20261110_201240_0d9818e4ab0c\SAD_MVP_VIS04_FINAL_POLISH_TEMP.qvw`

**SHA-256 pós-Save reportado pelo operador:**  
`BE8CB39B59F92F2F173DB309A60EA5FF373CDF87CBFCBC333F5583A21FF539C6`

**Evidência:** `VIS04_LOCAL_GUI_PRESENTATION=PASS_RESTRICTED`; `VIS04_POST_REOPEN_VISUAL_PERSISTENCE=PASS_RESTRICTED_WITH_OPERATOR_EVIDENCE` nas três capturas sem `*` na janela; `SOURCE_UNCHANGED=True`, `PROTECTED_VIS02_UNCHANGED=True`, `PROTECTED_C4_UNCHANGED=True` segundo PowerShell local. Ver [closeout VIS-04](../project/sad-vis-04-final-presentation-polish-runbook-2026-11-10.md) e [registro de provas MVP](../project/mvp-evidence-and-contract-gates-consolidation-2026-11-07.md).

## 3. Relatório acadêmico final

**PDF final produzido em conversa, fora do Git:**  
`SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS04_2026.pdf`

**SHA-256:** `BB7A6A6D7C2ADC3BE80831F4F8E98642D7CE9D07A25B7F03000A9DF2E8071302`

**Inspeção realizada:** **98 páginas**; atualização de Figuras 7–9 (páginas 22–24) a partir de capturas VIS-04; 95/95 páginas restantes com renderização e texto inalterados em relação ao PDF imediatamente anterior. Capítulos 1–2, Anexos I/II e justificativas de indicadores não exibidos (§3.7 e §4.1) preservados.

**Fontes de verdade da revisão:** [DOC-R3 editorial](doc-r3-editorial-patch-2026-11-10.md) e [auditoria de consumo e roteiro](final-coverage-redundancy-review-and-online-rehearsal-2026-11-10.md). Não versionar o binário do PDF no repositório; o responsável precisa manter **cópia persistente de entrega** no seu armazenamento, verificando o SHA após download. O link transitório de sessão do ChatGPT não deve ser tratado como storage permanente.

## 4. Indicadores propostos, porém não apresentados

O Capítulo 2 (§2.9) contempla internações por 1.000 habitantes, leitos SUS por 1.000 habitantes, relação internações/leitos e fluxos RES→SERV. Desses, somente o fluxo é apresentado descritivamente por M3-01/M3-02. Os três indicadores cruzados não foram publicados por falta de suficiência de validação global das associações entre fatos, período, município/papel, denominadores e cobertura histórica CNES/LT; não equivale a afirmar impossibilidade matemática.

Medidas `QTD_REGISTRO_AIH`, `DIAS_PERMANENCIA`, `VALOR_TOTAL`, `INDICADOR_OBITO` e `QTD_LEITOS_NAO_SUS` existem na fonte/fatos versionados, mas não são medidas diretas dos nove visuais. Isso **não prova campo inútil** e não cria compromisso de novas implementações. Os seis visuais não exibidos do blueprint permanecem como diferença documental de escopo, não backlog da disciplina.

## 5. Aceites e limites

| Gate | Estado fundamentado |
| --- | --- |
| `OWNER_MVP_SCOPE_APPROVED` | Sim, **apenas** 3 folhas/9 objetos acadêmicos temporários |
| `VIS04_LOCAL_GUI_PRESENTATION` | `PASS_RESTRICTED` com capturas recebidas |
| `VIS04_ORIGINALS_HASH_PROVENANCE` | `PASS_HASH_LOCAL_OPERATOR_REPORTED` |
| `DOC_R3_98_PAGE_PDF` | `GENERATED_QA_PASS`, ainda **não submetido** |
| `ONLINE_REHEARSAL` | `NOT_RUN` |
| `TEACHER_THREE_SHEETS_AS_THREE_PANELS` | `UNVERIFIED` (operador interpretou como equivalente) |
| `C2_C3_C4_GLOBAL` | `NOT_APPROVED` |
| `T25_T26_HISTORICAL_HOSPITAL_COVERAGE` | `NOT_GLOBALLY_VERIFIED` |
| `PHASE_IX` | `NOT_AUTHORIZED` |
| `PRODUCTION_APPROVED` | `False` |

**Segunda avaliação:** 08/12/2026 foi comunicada pelo operador como previsão acadêmica; **sem confirmação independente de data/ambiente Classroom**. A implementação acadêmica foi concluída no escopo reportado, mas **ensaio online e submissão** não foram executados nesta conversa.

## 6. Reproducibilidade, evidências e arquivos preservados

Nesta consolidação os artefatos essenciais de PRs Draft foram copiados **sem alteração de seus Git blob SHA** para `docs/project`, `docs/academic`, `tools` e `PAINEL`, mantendo links para o histórico:

- [PR #226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226): decisão MVP, builder TEMP e guarda de apresentação (scripts **experimentais**, não homologados de produção);
- [PR #231](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/231), [#232](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/232), [#233](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/233), [#236](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/236): closeouts e hashes visuais restritos, scripts TEMP com proteções de origem;
- [PR #234](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/234): rastreio DOC-R3 e scripts da versão final; o script de substituição de figuras foi arquivado **após** execução, com identidade Git blob verificada, mas não foi novamente executado pós-commit;
- [PR #235](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/235): auditoria dos nove objetos, justificativas de não uso e roteiro para ensaio online.

**A cópia para esta branch da documentação não refaz os testes, não altera nenhuma regra de negócio e não transforma um PASS restrito em aprovação física global.**

## 7. Handoff acadêmico e STOP

1. **Revisão de leitura do PDF final pelo responsável**, incluindo nomes, referências, páginas impressas e figuras.
2. **Confirmar critério docente** de três folhas versus três painéis e data/meio da segunda avaliação.
3. **Ensaio online real** com QVW VIS-05 (hash reportado pelo operador) e PDF VIS-05 como fallback; **não** assumir PASS sem execução.
4. **Submissão pelo responsável**, registrar data e protocolo/recibo, se disponível.
5. **Higiene do GitHub** conforme [plano](../project/repository-final-hygiene-plan-2026-11-10.md), sem novas implementações Qlik/ETL.

**STOP do desenvolvimento acadêmico:** sem novos KPIs, sem modelagem ou QlikView físico adicional; incompatibilidades e insuficiências científicas constam como limites explícitos.


## 8. Atualização superveniente — VIS-05 (15/11/2026)

**Este adendo substitui o apontamento VIS-04 como versão mais recente das três figuras do relatório, sem apagar o histórico e os aceites restritos anteriores.** O documento de entrega acadêmica foi atualizado **apenas nas Figuras 7–9** com capturas VIS-05: páginas físicas 22, 23 e 24. O PDF original VIS-04 (98 páginas) teve hash conferido em bytes: `BB7A6A6D7C2ADC3BE80831F4F8E98642D7CE9D07A25B7F03000A9DF2E8071302`. O novo PDF `SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS05_2026.pdf` tem SHA-256 `4C6033F3131F4B05105BBFCD992A2A6E7896CD5A2D424BF0BEA513430D0ED9F3` e 98 páginas; as outras 95/95 passaram em igualdade textual, geométrica e visual por rasterização. As três páginas modificadas foram inspecionadas e mantêm suas legendas VIS-05 e todo o restante do texto.

**Executor:** `tools/patch_sad_doc_r3_vis05_figures.py` versionado antes da execução no commit `33a916819173f99694f8af57363411b03e6385ac`. Resultado `VIS05_PDF_FIGURE_PATCH_QA=PASS_RESTRICTED`, sem homologação científica. Evidências, três hashes de PNG, arquivo QVW reportado, restrições e STOP: [fechamento documental VIS-05](vis05-documentary-closeout-2026-11-15.md).

O QVW VIS-05, seu hash `B56D0A8550AB7EEE68D45DB0249F273DED05C4ADEE88DBE3FC7A20B162084DBB` e a preservação do original VIS-04 foram **reportados pelo operador**, sem acesso independente ao Windows. Municípios externos à PB podem aparecer sem nomes no fluxo RES→SERV. `ONLINE_REHEARSAL=NOT_RUN`, `TEACHER_ACCEPTANCE=UNVERIFIED`, `CLASSROOM_SUBMISSION=NOT_SUBMITTED`, `C2_C3_C4_GLOBAL=NOT_APPROVED`, `PRODUCTION_APPROVED=False`. O PDF segue fora do Git; guardar cópia persistente e verificar SHA-256 após download.
