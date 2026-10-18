# Current State — SAD Data Mart SUS PB

**Snapshot:** 18/10/2026. **`main` conferida:** `b1b0c200e5ce75670ea5d9c656ec94761fc0a37b`, após squash merge do [PR #100](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/100). O código de preparação está na `main`, porém nenhuma execução física QlikView/Windows foi demonstrada nesta etapa; revisão do risco de publicação é proposta em PR Draft separado.

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
| Fase VI — Link Table | VI-P1–P4 versionados na `main` via [PR #98](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/98), VI-P4 PASS local restrito; VI-P5 estático via [PR #99](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/99); scripts CREATE/READBACK e executor preparados via [PR #100](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/100), **sem execução física**. Revisão da publicação não sobrescrevente em PR Draft. **`LINK_KEY_CONTRACT=NOT_APPROVED`**; `LINK_ANALISE.qvd` não criado conforme último estado reportado. | [Preparação](../discovery/phase-6-link-analise-create-readback-preparation-2026-10-17.md) |
| Fases VII–IX | Painel técnico, indicadores e dashboards físicos pendentes; semântica V2 aprovada apenas semanticamente | [Contrato V2](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) |

**Qualificação:** PASS significa **execução QlikView local reportada pelo responsável**, com stdout e marcadores de log confrontados com o código; os QVDs/QVWs binários não foram auditados independentemente. **Não é aprovação de produção**: `PRODUCTION_APPROVED=False`. A implementação de três fatos físicas não comprova associação completa da constelação ou execução do fluxo geral `TRANSF.qvw → PAINEL.qvw`.

## Bloqueios e invariantes

- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`: não antecipar integração física, denominadores ou dashboards. VI-P5 aprovou apenas o *modo de projeção POP em memória*, sem aceite do contrato físico final.
- População anual e leitos mensais são **semi-aditivos no tempo**; não multiplicar população por competências nem somar snapshots de anos diferentes como população total. `internações/leito` não equivale automaticamente a taxa de ocupação.
- `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`: evitar legenda CNES retroativa e exclusão de LT válido por escopo não comprovado.
- SIH/RD: `IDENT=1` (555.089) e `IDENT=5` (11.583) não significam o mesmo; `IDENT=5` não é internação nova. Há 5.202 residentes fora da PB sem denominador municipal PB apropriado. Ponte IBGE7↔DATASUS6 comprovada somente no escopo da PB.
- **Preservar os 21 QVDs, QVWs e logs locais.** Não reexecutar CREATE anteriores, não sobrescrever dados e não mudar a modelagem entregue sem autorização.

## Próximo gate — decisão pendente

**Fase VI: verificação local não mutante do executor e fechamento da publicação sem sobrescrita.** O PR #100 já integrou os scripts de preparação. O executor da `main` ainda contém risco de concorrência entre checagem de destino e `STORE` diretamente no arquivo final; a proposta em PR Draft grava em staging exclusivo, confirma READBACK/hashes e usa `File.Move` sem overwrite no mesmo diretório. **Aguardar revisão/merge separado dessa correção e execução de inventário no Windows, inicialmente sem `-ExecutePhysical`.** Sem CREATE físico, alterações nos 21 QVDs, recarga de `TRANSF.qvw` ou Fase VII até autorização separada.

**Limite desta atualização:** apenas roteamento do gate e referência de código candidato, sem declarar teste local, homologação QlikView ou produção.
