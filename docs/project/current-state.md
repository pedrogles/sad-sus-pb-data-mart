# Current State — SAD Data Mart SUS PB

**Snapshot:** 16/10/2026. **`main` conferida:** `f8215fb9c3f851ae5a0b9ac7c268e59afbe16022`, após squash merge do [PR #96](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/96).

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
| Inventário | **21 QVDs locais reportados**: 10 extração/referência, 8 dimensões, 3 fatos; os 20 anteriores mantiveram SHA-256 após CREATE e READBACK segundo o executor | Artefatos físicos somente no Windows; não versionados |
| CNES/LT complementar | Preflight PASS local reportado, PR #90 ainda Draft e não integrado | [PR #90](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/90) |
| Fase VI — Link Table | **PENDENTE**; `LINK_KEY_CONTRACT=NOT_APPROVED`, `LINK_ANALISE.qvd` não criado | [Boundary 7](../discovery/boundary-7-implementation-plan.md) |
| Fases VII–IX | Painel técnico, indicadores e dashboards físicos pendentes; semântica V2 aprovada apenas semanticamente | [Contrato V2](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) |

**Qualificação:** PASS significa **execução QlikView local reportada pelo responsável**, com stdout e marcadores de log confrontados com o código; os QVDs/QVWs binários não foram auditados independentemente. **Não é aprovação de produção**: `PRODUCTION_APPROVED=False`. A implementação de três fatos físicas não comprova associação completa da constelação ou execução do fluxo geral `TRANSF.qvw → PAINEL.qvw`.

## Bloqueios e invariantes

- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED`: não antecipar integração física, denominadores ou dashboards.
- População anual e leitos mensais são **semi-aditivos no tempo**; não multiplicar população por competências nem somar snapshots de anos diferentes como população total. `internações/leito` não equivale automaticamente a taxa de ocupação.
- `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`: evitar legenda CNES retroativa e exclusão de LT válido por escopo não comprovado.
- SIH/RD: `IDENT=1` (555.089) e `IDENT=5` (11.583) não significam o mesmo; `IDENT=5` não é internação nova. Há 5.202 residentes fora da PB sem denominador municipal PB apropriado. Ponte IBGE7↔DATASUS6 comprovada somente no escopo da PB.
- **Preservar os 21 QVDs, QVWs e logs locais.** Não reexecutar CREATE anteriores, não sobrescrever dados e não mudar a modelagem entregue sem autorização.

## Próximo gate — decisão pendente

**Fase VI: preflight READ-ONLY do contrato de associação entre as três fatos.** Inspecionar os QVDs físicos e as coordenadas de tempo, município de residência, município de atendimento e estabelecimento; analisar valores inaplicáveis/nulos, cardinalidades, regras de serialização e riscos antes de aprovar qualquer `%LINK_KEY`. Reutilizar evidências já produzidas. **Sem geração de `LINK_ANALISE.qvd`, recarga de `TRANSF.qvw`, implementação de painéis ou alteração de fatos.** Requer autorização específica.

**Limite desta atualização:** alterar somente este Markdown em branch de documentação, abrir PR Draft e **não realizar merge**.
