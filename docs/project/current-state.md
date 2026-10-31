# Current State — SAD Data Mart SUS PB

## Estado operacional — 31/10/2026 | C2 despacho restrito encerrado

**Baseline de elaboração:** `main@238d4f70c5cf4576808fdd43af4a3d72b4e0b7cc`, após integração do desenho temporal [PR #200](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/200). O teste físico ocorreu anteriormente na branch do [PR #201](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201), no commit original pinado; o merge documental posterior não altera sua proveniência, nem o transforma em homologação global. O `current-state.md` anterior e a cronologia permanecem consultáveis [no commit-base](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/238d4f70c5cf4576808fdd43af4a3d72b4e0b7cc/docs/project/current-state.md). Revalidar sempre o HEAD atual e a situação dos PRs.

### Situação por camada de evidência

| Camada | Estado atual e evidência |
| --- | --- |
| Acadêmico | Capítulos 1–2 entregues conforme relato em 13/10/2026; avaliação do professor ainda não confirmada. [Requisitos](../academic/requirements.md), [modelagem](../academic/chapter-1-2-modeling.md). |
| ETL/QVD | 108/108 DBC convertidos e 10 QVDs de extração, oito dimensões, três fatos; 22 QVDs e três QVWs canônicos inventariados em execuções locais, sem auditoria independente de todos os binários. [Gate da extração](../discovery/phase-3-final-extraction-gate-2026-10-08.md), [fatos](../discovery/phase-5-fato-internacao-implementation-2026-10-15.md), [leitos](../discovery/phase-5-fato-capacidade-leito-qvd-materialization-2026-10-15.md), [população](../discovery/phase-5-fato-populacao-qvd-materialization-2026-10-16.md). |
| Consumo independente | P1.1/P1.2 PoCs visuais restritas; P1.3–P1.5, P2.1–P2.5, P3.1–P3.4 validados numericamente/observacionalmente em recortes restritos; **sem aceite global de painel**. [Matriz dos 14 visuais](../discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md), integrada em [PR #195](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/195), com 4 sustentados por evidência existente e 10 condicionais para consumo físico. |
| Consumo A0/A1 | A0 é padrão documental; A1 isolada condicionalmente para P2.3. [Decisão](analytical-consumption-architecture-approval-2026-10-27.md); [PR #167](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/167) permanece Draft (A0 R1 não validada **apenas P2.3**). R2 A1 tem `PASS_LOCAL_A1_P23_CANDIDATE_ONLY`, não aceite visual/global. |
| C2 — despacho temporal | [Contrato de desenho](../discovery/sad-c2-guided-dynamic-control-design-2026-10-30.md) integrado na `main` via PR #200; [PR #201](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201) documenta `PASS_VISUAL_RESTRICTED_SINGLE_NO_SELECTION_TO_EVOLUTION_2019`. Execução QlikView local em `31564de14417fd25d666ea49f743ad1c6bdd1a15`: novo botão `BU15`, ano real 2019 aplicado (1), competência sem seleção explícita (0), serviço sem seleção (0); `-Verify` reportou fonte+25 protegidos preservados, TEMP modificada, arquivos GUI presentes e exit 0. [Runbook e closeout](../discovery/sad-c2-guided-dynamic-dispatch-poc-2026-10-31.md), [comentário de prova](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201#issuecomment-6549181674). **Sem inspeção direta dos binários/JSON locais pelo agente.** |
| C2 — evolução de 12 meses | Ainda **não testada** após despacho. PR [#199](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/199) Draft documenta bloqueio do botão anterior e `Verify` restrito, não prova série de 12 competências nem substitui #201. |
| Fases seguintes | Link Key, contratos globais de medidas, UX D2/P5, cobertura hospitalar CNES e Fase IX **não aprovados**. [Caminho crítico](final-delivery-critical-path.md); [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) permanece aberta para suficiência científica T25/T26. |

### Próximo trabalho delimitado

1. **C2 despacho temporal restrito:** closeout documentado no PR #201. Não confundir `GATE_PASS_RESTRICTED`, integração do PR e aprovação de produção; o runner do gate não está homologado para uso genérico e não deve ser reexecutado.
2. **Gate físico separado a preparar, não executar automaticamente:** comprovar série guiada P1.2 com exatamente `201901–201912` sob ano realmente selecionado, usando o oráculo já arquivado sem recalcular os 36 meses nem repetir o despacho. O gráfico `CH02` histórico de 36 meses não demonstra sozinho a série guiada de 12.
3. **Governança documental em PR autônomo**: consultar o [PR #202](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/202) para README/caminho crítico/inventário de higiene; sua integração deve ser conferida separadamente. Não misturar exclusão de branches com conclusão C2. Manter ordem física `C2 → C3 → C4 → IX` do [Boundary 7](../discovery/boundary-7-implementation-plan.md), com gates condicionais/decisão acadêmica próprios.
4. Confirmar com o professor data da segunda avaliação e eventual aceitação metodológica dos recortes CNES antes da entrega acadêmica final. Não alterar os capítulos entregues silenciosamente.

### Invariantes e STOP

- QlikView 12; `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`; três fatos e oito dimensões Star/constelação; papéis RES/SERV, `IDENT=5`, snapshots semi-aditivos, `T29_HISTORICAL=NOT_APPROVED` e aviso CNES.
- `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
- **STOP do gate físico #201:** não repetir `Prepare`, GUI, `Verify`, alterar QVW/QVD/QVS canônicos ou executar novo piloto automaticamente. Evidências físicas e SHA permanecem fora do Git; histórico detalhado nos closeouts, comentários e commits.
