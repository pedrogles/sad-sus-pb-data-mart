# Current State — SAD Data Mart SUS PB

**Snapshot operacional: 15/10/2026, após os squash merges dos PRs #91 e #92.** Este arquivo registra **estado vigente, bloqueios e próximo gate**, não substitui a evidência de Discovery nem aprova produção. Versão atual da `main` verificada: `155435efbc3f50729d345a766182cb298951b7b4`. Este texto está **proposto no PR #89 Draft** até eventual integração.

## 1. Escopo acadêmico preservado

Data Mart 2017–2019 para demanda hospitalar SIH/SUS (RD), capacidade CNES/LT e população IBGE/SIDRA da Paraíba, com **QlikView 12 obrigatório** e fluxo `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`.

**Capítulos 1–2:** relatório impresso informado como entregue em 13/10/2026, avaliação do professor pendente. **Sem mudança** no Star Schema por processo factual/constelação, granularidades, regras de negócio, três fatos e oito dimensões: `DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`, `DIM_DIAGNOSTICO`, `DIM_CARATER_ATENDIMENTO`, `DIM_MOTIVO_SAIDA_PERMANENCIA`, `DIM_TIPO_LEITO`. [Requisitos](../academic/requirements.md), [modelagem entregue](../academic/chapter-1-2-modeling.md), [Boundary 7](../discovery/boundary-7-implementation-plan.md).

## 2. Status operacional dos gates

| Processo/gate | Estado em 15/10/2026 | Evidência |
| --- | --- | --- |
| Boundaries 3–8 | **Concluídos; Boundary 8 GO**, com restrições documentadas | `docs/discovery/` |
| Fases I–II: infraestrutura/conversão | **PASS local 108/108 DBC** | [Boundary 8](../discovery/boundary-8-readiness.md) |
| Fase III: extração/staging | **PASS FINAL RECONCILED local**; 10 QVDs de entrada, 107 campos verificados | [Gate final da extração](../discovery/phase-3-final-extraction-gate-2026-10-08.md) |
| Fase IV: dimensões | **8/8 com código integrado à `main` e evidência local QlikView** | [DIM_TIPO_LEITO](../discovery/phase-4-dim-tipo-leito-discovery-2026-10-09.md) |
| Fase V: `FATO_INTERNACAO` | **PR #88 MERGED** (`7abd1dc50c092e4235fc811fa63e4dd3a30344ac`); CREATE + READBACK físico em dois QVWs **PASS LOCAL REPORTADO**: 566.672 registros/SKs, 17 colunas, 36 competências, 77.550 links distintos **apenas RD**. QVD existe somente no Windows do responsável. Execução opt-in `OFF` por padrão em `transf_main.qvs` | [PR #88](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/88), [prova detalhada](../discovery/phase-5-fato-internacao-implementation-2026-10-15.md) |
| Fase V: pré-teste CNES/LT | **PASS local reportado**, 35.518 linhas, 36 competências e 5 papéis sem órfãos; **PR #90 ainda Draft e NÃO integrado**. Não repetir o gate | [PR #90 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90) |
| Fase V: `FATO_CAPACIDADE_LEITO` | **PRs #91 e #92 MERGED por squash**, `306fd87ec07049ddff724d5282deec7f484802d9` e `155435efbc3f50729d345a766182cb298951b7b4`. CREATE + READBACK **PASS FÍSICO LOCAL REPORTADO**: 35.518 linhas/SKs, 11 colunas, 36 competências, 7.486 links distintos **apenas LT**, 0 divergências de chaves/domínio/medidas. QVD físico no Windows, não no Git | [PR #91](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/91), [PR #92](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/92), [prova detalhada](../discovery/phase-5-fato-capacidade-leito-qvd-materialization-2026-10-15.md) |
| Fase V: `FATO_POPULACAO` | **AINDA NÃO IMPLEMENTADA**. Staging IBGE: `EXTRACAO/QVD/SRC_IBGE_POPULACAO.qvd`, 669 linhas de município × ano (223 por ano, 2017–2019). Nenhum `FATO_POPULACAO.qvd` aprovado/gerado | [Extração](../discovery/phase-3-final-extraction-gate-2026-10-08.md), [Boundary 7](../discovery/boundary-7-implementation-plan.md) |
| Fase VI: `LINK_ANALISE` | **NÃO IMPLEMENTADA**; `SAD-LINK-V1` tem somente PASS experimental restrito. **Contrato físico inter-fatos não aprovado** | [Discovery anterior](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/26369052bd3f96de5f3eccf873c390053c20b561/docs/discovery/phase-6-link-key-cross-fact-discovery-2026-10-10.md) |
| Semântica V2 dos indicadores | **Aprovada apenas semanticamente, PR #85 integrado**; expressões, denominadores físicos, filtros e painéis continuam sem aprovação | [Semântica V2](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) |
| Fases VII–IX: PAINEL técnico, indicadores e dashboards | **PENDENTES** | [Boundary 7](../discovery/boundary-7-implementation-plan.md) |

**Nível de evidência das duas fatos:** resultados QlikView/PowerShell e logs transcritos pelo responsável; CREATE e reabertura em QVWs isolados, com hashes QVD invariantes e preservação dos QVDs anteriores **segundo os executores locais**. Não houve auditoria externa dos binários pelo agente, validação integrada das três fatos, aprovação de produção ou inclusão de QVD/QVW binário no repositório. **Nunca reexecutar os runners one-shot**: os dois QVDs factuais já existem localmente.

## 3. Regras e bloqueios ainda abertos

- `LINK_KEY_CONTRACT=NOT_APPROVED`; 77.550 links da internação e 7.486 da capacidade são **contagens internas separadas**, não prova de cardinalidade ou compatibilidade física inter-fatos. Nenhuma `LINK_ANALISE.qvd` produzida.
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED`. Aprovação semântica V2 não habilita KPI/dashboard físico.
- `T29_HISTORICAL=NOT_APPROVED`; nomes CNES referentes a 09/2019 não são retroativamente válidos para todas as competências. `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; não eliminar registros LT válidos por classificação hospitalar não demonstrada.
- Leitos e população são **semi-aditivos no tempo**. Somatórios LT das 36 competências (`QT_EXIST=337147`, `QT_SUS=270076`, `QT_NSUS=67071`) servem somente à reconciliação de snapshots, **não** significam capacidade anual ou simultânea.
- SIH/RD tem 555.089 registros `IDENT=1` e 11.583 `IDENT=5` dentro das 566.672 linhas, não equivalentes à mesma medida de novas internações; 5.202 residentes fora da PB permanecem sem população PB inventada.
- Compatibilidade de códigos municipais DATASUS (6 dígitos) e IBGE (7 dígitos) depende de ponte validada; não fabricar o sétimo dígito. População anual não deve ser repetida artificialmente por mês.
- **PR #89** (este snapshot) e **PR #90** (preflight LT já cumprido) permanecem **Draft, sem merge**, exigindo deliberação separada. Artefatos `.qvw` de diagnóstico não rastreados no Windows devem ser preservados; `git status` sem alterações rastreadas foi reportado após sincronização local com `origin/main`.

## 4. Próximo gate delimitado

**Fase V, terceira fato: `FATO_POPULACAO` — somente DISCOVERY / PREFLIGHT READ-ONLY, sob autorização separada.** Reutilizar `SRC_IBGE_POPULACAO.qvd` e as dimensões/ponte municipal já existentes; conferir grão município × ano, 669 linhas/223 municípios por ano, cobertura 2017–2019, chave municipal validada, SKs de ano e município, domínio/nulidade/medida `POPULACAO_ESTIMADA`, papéis residência/serviço e semiaditividade temporal. **Não inventar a relação 6↔7 dígitos, nem aprovar antecipadamente `%LINK_KEY`.** Fato QVS candidato e CREATE de QVD terão gates posteriores distintos.

**Sequência aprovada:** `FATO_POPULACAO` → Fase VI Link Table → Fase VII painel técnico → Fase VIII indicadores → Fase IX dashboards. Não iniciar automaticamente outras frentes, regravar QVDs, gerar `LINK_ANALISE.qvd`/`PAINEL.qvw`, alterar `transf_main.qvs`, apagar branches, ou realizar merges sem autorização específica.

**Condição de parada desta atualização:** registrar apenas o estado operacional correto e o próximo gate; **nenhum QVD/QVW local ou script de transformação alterado por este PR**.
