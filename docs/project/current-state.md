# Current State — SAD Data Mart SUS PB

**Snapshot:** 18/10/2026. **`main` de código conferida:** `9c2905c0e67e2bfde9a0db941e35ffd2ed75289a`, após integração do [PR #103](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/103). A materialização candidata de `LINK_ANALISE.qvd` alcançou **PASS físico local reportado** de CREATE + READBACK + publicação sem sobrescrita; o QVD e os logs nativos completos da execução R2 não foram auditados independentemente. [Evidência Fase VI](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md).

## Contrato acadêmico preservado

Data Mart SUS Paraíba, 2017–2019, com SIH/SUS RD, CNES/LT e IBGE/SIDRA; **QlikView 12 obrigatório**. Fluxo: `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`. **Star Schema por processo factual**, constelação com três fatos e oito dimensões aprovadas. Capítulos 1 e 2 entregues conforme relato de 13/10/2026; avaliação do professor pendente. Ver [requisitos](../academic/requirements.md), [modelagem](../academic/chapter-1-2-modeling.md) e [Boundary 7](../discovery/boundary-7-implementation-plan.md).

## Estado dos gates

| Etapa | Estado | Evidência |
| --- | --- | --- |
| Extração | 108/108 DBC convertidos, 10 QVDs de extração/referência, **PASS local reportado** | [Extração](../discovery/phase-3-final-extraction-gate-2026-10-08.md) |
| Oito dimensões | 8 scripts na `main`, com testes locais reportados | [Dimensões](../discovery/phase-4-dim-tipo-leito-discovery-2026-10-09.md) |
| `FATO_INTERNACAO` | QVD físico, CREATE + READBACK **PASS local reportado**: 566.672 linhas, 17 campos, 36 competências; código MERGED #88 | [Evidência](../discovery/phase-5-fato-internacao-implementation-2026-10-15.md) |
| `FATO_CAPACIDADE_LEITO` | QVD físico, CREATE + READBACK **PASS local reportado**: 35.518 linhas, 11 campos, 36 competências; código MERGED #91/#92 | [Evidência](../discovery/phase-5-fato-capacidade-leito-qvd-materialization-2026-10-15.md) |
| `FATO_POPULACAO` | **QVD físico criado e reaberto**, CREATE + READBACK **PASS local reportado**: 669 linhas, 7 campos, 223 municípios × 3 anos, 669 pares SK distintos, zero erros. Código **MERGED #96**; preflight e RAM nos #93/#94 | [Evidência física](../discovery/phase-5-fato-populacao-qvd-materialization-2026-10-16.md) |
| Inventário | **21 QVDs originais preservados** segundo os manifestos/hashes do executor na execução R2; `LINK_ANALISE.qvd` é artefato adicional candidato, não contabilizado entre os 21 originais | [Evidência Fase VI](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md); artefatos físicos locais não versionados |
| CNES/LT complementar | Preflight PASS local reportado, PR #90 ainda Draft e não integrado | [PR #90](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90) |
| Fase VI — Link Table | **`PASS_LOCAL_CREATE_READBACK_AND_ATOMIC_PUBLISH_CANDIDATE_ONLY`** na tentativa R2 do QlikView 12, conforme stdout local reportado; revisão de publicação via #101/#102 e correção QVS R1 via [PR #103](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/103), todos integrados. Verificações físicas T17–T19 realizadas pelo runner em READBACK candidato, sem aceite independente do modelo final. **`LINK_KEY_CONTRACT=NOT_APPROVED`**, `PANEL_NOT_TESTED=True`, `PRODUCTION_APPROVED=False`. | [Evidência física R1/R2](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md) |
| Fases VII–IX | Painel técnico, indicadores e dashboards físicos pendentes; semântica V2 aprovada apenas semanticamente | [Contrato V2](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) |

**Qualificação:** PASS significa **execução local QlikView/Windows reportada pelo responsável**. No gate VI, o stdout R2 contém os marcadores de CREATE, READBACK, SHA-256 e publicação compatíveis com o runner versionado; os logs nativos R2 completos, QVDs e QVWs binários não foram inspecionados independentemente nesta revisão documental. **Não é aprovação semântica nem de produção**: `PRODUCTION_APPROVED=False`. Não comprova a associação final `TRANSF.qvw → PAINEL.qvw`.

## Bloqueios e invariantes

- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`: não antecipar integração física, denominadores ou dashboards. VI-P5 aprovou apenas o *modo de projeção POP em memória*, sem aceite do contrato físico final.
- População anual e leitos mensais são **semi-aditivos no tempo**; não multiplicar população por competências nem somar snapshots de anos diferentes como população total. `internações/leito` não equivale automaticamente a taxa de ocupação.
- `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`: evitar legenda CNES retroativa e exclusão de LT válido por escopo não comprovado.
- SIH/RD: `IDENT=1` (555.089) e `IDENT=5` (11.583) não significam o mesmo; `IDENT=5` não é internação nova. Há 5.202 residentes fora da PB sem denominador municipal PB apropriado. Ponte IBGE7↔DATASUS6 comprovada somente no escopo da PB.
- **Preservar os 21 QVDs originais, o novo `LINK_ANALISE.qvd`, QVWs e logs locais R1/R2.** Não reexecutar CREATE, não sobrescrever dados e não mudar a modelagem entregue sem autorização.

## Próximo gate — decisão pendente

**Fase VI — gate físico candidato encerrado com PASS local reportado.** Preservar `LINK_ANALISE.qvd`, o SHA-256 registrado e as evidências locais [R1/R2](../discovery/phase-6-link-analise-physical-r2-2026-10-18.md); não repetir CREATE. Esta atualização documental exige revisão e merge próprios, sem novas execuções.

**Próxima decisão independente:** após a integração documental, avaliar autorização específica para iniciar a **Fase VII — painel técnico**, respeitando Boundary 7, a projeção POP em memória e as pendências `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`. Não iniciar Fase VII, recarregar `TRANSF.qvw`/`PAINEL.qvw` ou aprovar produção nesta atualização.
