# SAD — Registro canônico candidato da segunda entrega acadêmica (2026.2)

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
3. **Ensaio online real** com QVW VIS-04 e PDF como fallback; **não** assumir PASS sem execução.
4. **Submissão pelo responsável**, registrar data e protocolo/recibo, se disponível.
5. **Higiene do GitHub** conforme [plano](../project/repository-final-hygiene-plan-2026-11-10.md), sem novas implementações Qlik/ETL.

**STOP do desenvolvimento acadêmico:** sem novos KPIs, sem modelagem ou QlikView físico adicional; incompatibilidades e insuficiências científicas constam como limites explícitos.
