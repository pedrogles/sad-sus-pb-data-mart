# Current State — SAD Data Mart SUS PB

**Snapshot operacional:** 15/10/2026, após squash merges dos PRs #89, #93 e #94. **`main` verificada na preparação:** `56e7185e70085b1deb7101814554a73a5f82a91a`. Esta atualização documental é proposta em **branch isolada, sem merge automático**. O arquivo registra estado, bloqueios e próximo gate; evidências detalhadas permanecem em Discovery e nos PRs.

## 1. Escopo acadêmico e arquitetura preservados

Data Mart do SUS na Paraíba, **2017–2019**, com SIH/SUS RD (demanda), CNES/LT (capacidade) e IBGE/SIDRA (população). **QlikView 12 obrigatório**, fluxo `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`; **Star por processo factual/constelação** com três fatos e oito dimensões conformadas já aprovadas, sem mudança da modelagem entregue.

**Capítulos 1–2:** entrega impressa informada como realizada em 13/10/2026; avaliação do professor pendente. Referências: [requisitos](../academic/requirements.md), [modelagem acadêmica](../academic/chapter-1-2-modeling.md) e [Boundary 7](../discovery/boundary-7-implementation-plan.md).

## 2. Estado dos gates e fontes da evidência

| Componente | Estado operacional verificado | Prova / ressalva |
| --- | --- | --- |
| Boundaries 3–8, infraestrutura e aquisição | Boundary 8 GO restrito; conversão **108/108 DBC PASS local**, extração/staging **10 QVDs e 107 campos, PASS local reconciliado** | [Readiness](../discovery/boundary-8-readiness.md), [extração final](../discovery/phase-3-final-extraction-gate-2026-10-08.md) |
| Fase IV — oito dimensões | **8/8 scripts integrados à `main`**, evidência QlikView local reportada | [DIM_TIPO_LEITO e fase dimensional](../discovery/phase-4-dim-tipo-leito-discovery-2026-10-09.md) |
| Fase V — `FATO_INTERNACAO` | **Código MERGED #88**; QVD físico local com CREATE + READBACK **PASS LOCAL REPORTADO**: 566.672 linhas, 17 campos, 36 competências; 77.550 links distintos **somente RD** | [#88](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/88), [evidência factual](../discovery/phase-5-fato-internacao-implementation-2026-10-15.md). O QVD não está no Git |
| Fase V — `FATO_CAPACIDADE_LEITO` | **Código MERGED #91 e #92**; QVD físico local com CREATE + READBACK **PASS LOCAL REPORTADO**: 35.518 linhas, 11 campos, 36 competências; 7.486 links distintos **somente LT** | [#91](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/91), [#92](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/92), [evidência de QVD](../discovery/phase-5-fato-capacidade-leito-qvd-materialization-2026-10-15.md). O QVD não está no Git |
| Fase V — `FATO_POPULACAO`: staging e papéis | **Preflight READ-ONLY PASS LOCAL REPORTADO (R2), código MERGED #93**; 669 linhas município × ano, 223 municípios, 2017–2019, ponte IBGE7↔DATASUS6 validada no escopo PB, SKs municipal/anual sem órfãos | [#93](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/93), [preflight](../discovery/phase-5-fato-populacao-readonly-preflight-2026-10-15.md). R1 BLOCKED histórico; não repetir |
| Fase V — `FATO_POPULACAO`: candidata em memória | **Código MERGED #94; PASS LOCAL REPORTADO** em QVW isolado: **669 linhas, 7 colunas candidatas, 669 pares de SKs distintos, 0 nulos/divergências**. **`FATO_POPULACAO.qvd` NÃO materializado**, sem `%LINK_KEY` definitiva | [#94](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/94), [evidência in-memory](../discovery/phase-5-fato-populacao-inmemory-2026-10-15.md) |
| Pré-teste CNES/LT complementar | **PASS local reportado**, PR **#90 permanece Draft, não integrado**; não reexecutar | [#90](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90) |
| Fase VI — `LINK_ANALISE` | **NÃO IMPLEMENTADA; `LINK_KEY_CONTRACT=NOT_APPROVED`**. Experimentações não homologam associação inter-fatos | [Boundary 7](../discovery/boundary-7-implementation-plan.md) |
| Indicadores / Fases VII–IX | Semântica V2 aprovada **somente semanticamente** (MERGED #85); painel técnico, expressões físicas, denominadores, filtros, três painéis e dashboards **PENDENTES** | [Semântica V2](../discovery/phase-6-semantic-v2-approved-2026-10-14.md), [Boundary 7](../discovery/boundary-7-implementation-plan.md) |

**Qualificação das provas:** os PASS de QlikView/PowerShell são **execuções locais reportadas pelo responsável** (saídas e trechos de log confrontados com scripts versionados), **não** auditoria independente dos QVDs/QVWs binários, certificação integrada de constelação ou aprovação de produção. No último teste populacional, o executor reportou **20 QVDs locais preexistentes com SHA-256 invariantes e nenhum QVD novo** (10 de extração, 8 dimensões, 2 fatos). Esses arquivos continuam somente no Windows. **Não repetir executores one-shot** nem alterar/excluir os QVWs e logs diagnósticos.

O [PR #89](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/89), que atualizou o snapshot anterior, está **MERGED**; o [#93](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/93) e o [#94](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/94) também estão **MERGED**. Somente **#90** permanece Draft dentre os PRs de Fase V aqui referidos. O `TRANSFORMACAO/transf_main.qvs` mantém a execução da primeira fato **OFF por padrão**; a candidata populacional ainda **não** foi acoplada ao fluxo geral de transformação.

## 3. Bloqueios e regras de negócio ainda abertos

- `LINK_KEY_CONTRACT=NOT_APPROVED`; as contagens de links dentro de RD (77.550) e LT (7.486) **não comprovam** integridade de associações entre processos. `LINK_ANALISE.qvd` não existe no gate aprovado.
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED`; aprovação semântica não equivale a testes ou homologação de indicadores e dashboards.
- `T29_HISTORICAL=NOT_APPROVED` e `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`: descrições CNES de 09/2019 não devem ser aplicadas retroativamente; nenhum LT válido deve ser excluído por escopo hospitalar não comprovado.
- **População e leitos são semi-aditivos no tempo**: não replicar população anual em competências mensais, somar anos como população de período, nem somar leitos de 36 competências como capacidade simultânea. `internações/leito` não é automaticamente taxa de ocupação.
- **SIH/RD:** distinguir `IDENT=1` (555.089) de `IDENT=5` (11.583); 5.202 residentes fora da PB não devem receber população municipal PB artificial. A ponte municipal IBGE7↔DATASUS6 é **derivada/validada para PB**, não substitui uma correspondência normativa nacional.
- `PRODUCTION_APPROVED=False`. Os QVDs físicos existentes (internação/capacidade), dados, modelos binários e evidências locais não foram enviados ao Git.

## 4. Próximo gate único proposto — decisão pendente

**Fase V: materialização controlada de `FATO_POPULACAO.qvd` com CREATE + READBACK em QVWs distintos**, **somente após autorização específica**. Reutilizar o QVS da candidata com PASS em memória, sem alterar a semântica aprovada: 669 linhas (223 municípios × 3 anos), medida `POPULACAO_ESTIMADA`, SKs municipal e anual resolvidas da ponte/dimensões existentes, totais anuais reconciliados. Preservar os **20 QVDs preexistentes** com inventário/hash; criar **um único QVD novo** em destino comprovadamente ausente, depois fazer readback independente de schema/linhas/grão/medidas/SKs e integridade. Nenhum `STORE` ou runner novo está autorizado por esta atualização documental.

**Fronteira:** não executar `TRANSF.qvw`, reprocessar fases anteriores, inventar `%LINK_KEY`, criar `LINK_ANALISE.qvd`, painel ou KPIs, nem fazer merge, deleção de branch ou QVD sem autorização. Após a terceira fato física, seguir a ordem do Boundary 7: **Fase VI Link Table → VII painel técnico → VIII indicadores → IX dashboards**, respeitando novos gates e contratos.

**Condição de parada desta branch documental:** atualizar somente este snapshot na branch de documentação, abrir PR **Draft sem merge**, verificar diff exclusivamente deste Markdown e encerrar. Não executar testes locais nem modificar QVDs, QVWs, scripts ou modelagem acadêmica.
