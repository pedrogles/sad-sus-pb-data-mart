# SAD — Caminho crítico para a entrega acadêmica final

**Estado:** proposta operacional DOCUMENTAL, sujeito à revisão/integração; não altera Boundaries nem homologa indicadores.  
**Preparado em:** 22/10/2026 sobre `main@9a4ed359ea8f5337aaecc5fe2487aca9ffb17acd`.  
**Primeiro item rastreável:** [Issue #157 — suficiência CNES/LT T25/T26](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157).  
**Autoridade:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/project/agent-model-routing.md`, [Boundary 7](../discovery/boundary-7-implementation-plan.md), [V2 §62](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) e `DescricaoProjetoSAD.pdf` (material oficial do professor). Estes documentos prevalecem; este plano **não** substitui requisitos, semântica ou a ordem física aprovada.

## Resultado final exigido (e não apenas a quantidade de testes)

Entregar um **Data Mart reproduzível em QlikView 12**, com as três fatos e oito dimensões da modelagem aprovada, **pelo menos três painéis** com indicadores numericamente defensáveis, comportamento de filtros demonstrado e notas metodológicas visíveis. Concluir o relatório acadêmico com Capítulos 3–5, capturas e comentários das análises, Referências, Anexo I (scripts de transformação das dimensões) e Anexo II (scripts de transformação das fatos, respeitando a constelação aprovada); preservar Capítulos 1–2 já entregues. Confirmar no calendário/professor a **data da segunda avaliação**, quando vence a segunda entrega via Google Classroom. O roteiro oficial prevê ≥6 dimensões, ≥1 fato e ≥3 painéis; o projeto aprovado tem 8 dimensões e 3 fatos.

**Não usar a porcentagem de tarefas, número de PRs, número de execuções ou um PASS local como evidência substitutiva de aceitação científica e entrega funcional.** Conclusão requer integridade de dados, medidas válidas, navegação segura, QlikView real, documentação e aceite do responsável. Não atribuir taxa de ocupação a `internações/leito`, não somar snapshots LT em anos e não chamar o universo CNES/LT observado de oferta hospitalar integral.

## Ordem de resolução e dependências

| Gate | Problema real a resolver | Evidência mínima para `RESOLVED_ACCEPTED` | Dependência de liberação |
|---|---|---|---|
| **G1 — VIII-C4-SCIENTIFIC-SUFFICIENCY** | Escopo científico de T25/T26: matriz de recortes CNES/LT observados válidos, cobertura, ausência versus zero, universo hospitalar e necessidade de aval do professor | Matriz por indicador×recorte; fonte/oráculo, território/papel, competências e denominador; indisponibilidades explícitas; decisão do responsável e consulta ao professor se alterar a promessa do trabalho; Issue [#157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) aceita | **Primeiro**, READ-ONLY; a decisão metodológica não muda a ordem de implementação física do Boundary 7 |
| **G2 — VIII-C3-LINK-CONTRACT** | Fechar o contrato global de associações e Link Key; não generalizar C3-B1/B2 | Confrontação dos cenários faltantes realmente necessários; inventário QlikView, cardinalidade, nulos não aplicáveis, papeis RES/SERV, ausência de `$Syn`/loops indevidos; decisão explícita global ou bloqueio | G1 define o escopo a exibir; preservar sequência técnica C3 → C4 |
| **G3 — VIII-C4-MEASURES-CONTRACT** | Aprovar numeradores, denominadores, agregação temporal/territorial e expressões físicas T24/T25/T26/FLU | Expressões versionadas, oráculos independentes em recortes autorizados, cobertura/zeros/ausências e filtros; `MEASURES_AND_DENOMINATOR_CONTRACT` decidido explicitamente | G1 e G2; não duplicar testes pilotos já encerrados |
| **G4 — VIII-C2-GUIDED-UX-P5-D2** | Completar política temporal da navegação guiada Mensal/Anual/Evolução e proteção efetiva P5/D2, não apenas textos | Contrato mínimo UX, estados proposta/aplicada, cenários físicos de transição necessários; bloqueio real de KPI incompatível; rotas de seleção relevantes auditadas ou limitação formal decidida sem declarar cobertura global inexistente | UX documental pode ser elaborado independentemente; **aprovação física de KPI** depende do contrato G3 |
| **G5 — VIII-CLOSEOUT-ACCEPTANCE** | Reconciliar os gates do indicador, fluxo ETL, associação, filtro, cobertura e limitações; GO/NO-GO formal | Matriz de aceite do responsável com links a logs, SHA, QVS/QVW, screenshots e oráculos; pendências externas discriminadas; decisão explícita `PHASE_IX` | G1–G4 resolvidos para o escopo acadêmico aceito; nenhuma autorização automática |
| **G6 — IX-DASHBOARDS** | Implementar e testar os painéis definitivos em QlikView 12 | Pelo menos 3 painéis reais, recarga verificável, números reconciliados por análise, UX e filtros revisados, avisos CNES/T29 junto aos gráficos, exportações/capturas legíveis, aprovação visual/funcional | G5 = GO para IX, autorização específica, sem mutar dados canônicos silenciosamente |
| **G7 — ENTREGA ACADÊMICA** | Documentar e submeter todo o trabalho | Cap. 3 com prints/comentários, Cap. 4, Cap. 5, Anexos I/II das transformações, revisão de coerência, pacote QlikView e evidência de submissão no Classroom; confirmação da data da segunda avaliação e avaliação do professor da primeira entrega se disponível | G6 aprovado; escrita preparatória do relatório pode acontecer antes, sem fingir que a implementação terminou |

**Pergunta que desbloqueia G1:** nos dados já observados e reconciliados, *quais combinações indicador × município/região × período × universo podem ser publicadas com rótulo explícito CNES/LT observado, quais devem ficar indisponíveis e quais exigem comprovação histórica adicional ou aceitação acadêmica?* Não exigir cobertura universal de 223 municípios quando escopo restrito é defensável e aceito; **não** escolher uma redução material do tema sem aprovação.

## Regra de continuidade: não avançar sobre problema não resolvido

Cada gate deve possuir **um item GitHub persistente** (issue ou PR vinculado), com identificador, dono/decisor, estado, evidência e critério de liberação. Estados permitidos:

- `OPEN_UNRESOLVED` / `IN_PROGRESS`: ainda não resolvido.
- `BLOCKED_EXTERNAL` ou `INCONCLUSIVE`: **continua aberto**; documentar a evidência faltante, pergunta específica, decisor (professor/responsável/fonte) e como desbloquear. Não fechar como PASS, não passar a etapa dependente.
- `READY_FOR_ACCEPTANCE`: evidência e proposta estão completas, mas **ainda não há aceite formal**.
- `RESOLVED_ACCEPTED`: critério atendido com evidência e aceite rastreável; **só aqui** avançar ao gate dependente.
- Se houver mudança de escopo aceita expressamente, registrar o recorte e a restrição como **resolução limitada aprovada**, nunca como comprovação global. Qualquer parte não resolvida permanece documentada/bloqueada, sem ser apagada.

**Sem ciclos intermináveis:** em uma execução, examinar fontes já versionadas, testar apenas lacuna estritamente necessária, produzir decisão/matriz e resolver o que for resolúvel. Se for impossível concluir sem evidência externa, **encerrar apenas a tentativa atual**, mantendo o **problema aberto** e o gate seguinte bloqueado. Não afirmar que um agente continuará rodando sozinho; retomada ocorre em novo atendimento ou com automação explicitamente criada. Trabalho independente pode progredir em trilha separada mediante autorização sem mascarar a dependência crítica.

**Anti-repetição:** não refazer VI-P4, C4-B1 ou pilotos C2-J/K; não criar T26 regional, novo COM, download em massa nem novas consultas sem uma lacuna objetiva e benefício claro. Preferir reaproveitar evidência, declarar `BLOCKED` quando não há oráculo e encaminhar uma pergunta fechada ao professor/responsável.

## Fronteiras preservadas

- Modelo acadêmico entregue: três fatos, oito dimensões, Star/constelação e Link Table; QlikView 12 e pipeline BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL.
- `LT_TODOS_REGISTROS_VALIDOS_RN21`; cenário histórico de nomes de leitos `T29_HISTORICAL=NOT_APPROVED`; distinção RES/SERV e população municipal correspondente.
- Status de entrada: `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_KPI_CALC_GUARD=NOT_TESTED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
- O plano orienta priorização, **não autoriza** merge, alteração física, nova implementação, edição de QVW/QVD, execução no Windows, publicação ou mudança semântica. O próximo gate tem autorização/escopo próprios.

## Primeiro handoff e condição de parada

**Gate ativo recomendado:** **G1 / Issue #157** em Discovery READ-ONLY. Reusar [#133](../discovery/phase-8-cnes-presentation-scope-decision-2026-10-20.md) e [C4-D](../discovery/phase-8-c4d-global-indicator-gaps-readonly-2026-10-21.md), [C4-E](../discovery/phase-8-c4e-cnes-coverage-unavailability-readonly-2026-10-21.md), [C4-F](../discovery/phase-8-c4f-vi-p4-export-readback-2026-10-21.md), [C4-G](../discovery/phase-8-c4g-cnesnet-201801-screenshot-closeout-2026-10-21.md). O agente deve produzir matriz e uma **decisão objetiva**, não nova discovery exploratória. Se prova suficiente: propor aceite explícito para `RESOLVED_ACCEPTED`; se não: classificar `BLOCKED_EXTERNAL` com pergunta/prova concreta e manter o item aberto. **Não** abrir G2 enquanto G1 não estiver aceito, exceto atividade documental comprovadamente independente e autorizada.
