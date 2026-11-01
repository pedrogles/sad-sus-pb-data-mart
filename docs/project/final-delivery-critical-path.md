# SAD — Caminho crítico para a entrega acadêmica final

**Estado:** roteiro de priorização DOCUMENTAL; a publicação na `main` não altera Boundaries, não homologa indicadores nem autoriza a execução física dos gates.  
**Preparado em:** 22/10/2026 sobre `main@9a4ed359ea8f5337aaecc5fe2487aca9ffb17acd`.  
**Primeiro item rastreável da trilha condicionada T25/T26 (não da trilha analítica independente):** [Issue #157 — suficiência CNES/LT T25/T26](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157).  
**Autoridade:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/project/agent-model-routing.md`, [Boundary 7](../discovery/boundary-7-implementation-plan.md), [V2 §62](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) e `DescricaoProjetoSAD.pdf` (roteiro oficial do professor, inspecionado na revisão). Estes documentos prevalecem; este plano **não** substitui requisitos, semântica ou a ordem física aprovada.

## Handoff após C2 P1.2 guiado — 31/10/2026 (vigente após integração documental)

**Fonte:** [current-state](current-state.md), [revisão de governança C2 P1.2](governance-c2-p12-consolidation-2026-10-31.md) e [PR #205 — closeout restrito](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205), sob baseline `main@2d205d52ab96eca565e85a9db5cfde14d9d3025c`. **Até o merge especificamente autorizado, este handoff está apenas em branch/PR documental.**

**Prova reutilizável, sem reexecução:** PR #201 já demonstrou despacho de ano em uma rota; PR #203 constatou persistência de 2017–2019 em CH02 histórico; PR #204 propôs gráfico novo; PR #205 obteve em QVW TEMP **12 competências 201901–201912, 12/12 valores idênticos ao oráculo, total 188.246**, e integridade de origem + 25 protegidos conforme Verify local de saída 0. **Não** significa controle temporal global nem integração do gráfico ao PAINEL.qvw.

**Sequência física preservada:** fechar a **decisão residual C2** (estados negativos, rotas alternativas relevantes, cobertura pré-despacho D2) com o menor conjunto de provas que ainda falta ou formalizar `BLOCKED` se não for possível; só então deliberar gates C3 (Link Key, papéis RES/SERV necessários) → C4 (medidas/denominadores necessários), respeitando Boundary 7. Não atribuir GO físico a C3/C4 por este texto. A [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) restringe indicadores CNES/LT T25/T26 condicionados, **não** as séries independentes de FI ou LT. Indicadores cruzados e população IBGE/SIDRA exigem ainda prova de associação/denominador. Não excluir essa parte da promessa inicial sem decisão expressa.

**Aceleração sem relaxar aceite:** reutilizar matriz 14/14 e oráculos AE01/P1–P3; **matriz de lacunas por indicador** separando dado, associação, visual/seleção e aceite. Não repetir P1.2, 36/36, AE01, nem criar um runner novo para cada investigação sem uma necessidade verificável. Concentrar evidências em um dossiê por gate e usar um PR documental de consolidação em vez de integrar runners de uso único.

**Trabalho paralelo permitido, só documental:** preparar capítulos 3–5, legendas/ressalvas, referências, Anexos I/II e selecionar os três painéis **candidatos** pela matriz, para revisar com o responsável/professor. Implementação definitiva em Fase IX requer **GO formal e autorização específica**. Confirmar data exata da segunda avaliação (a fonte oficial diz apenas "Dia da 2ª Avaliação").

**Estados:** `C2_GUIDED_2019_12_OF_12=PASS_RESTRICTED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**A seção "Handoff operacional atualizado" e o restante abaixo são registros históricos de 22–31/10 anteriores ao PASS de #205; não devem ser usados para iniciar novamente a série de 12 meses.**

---

## Handoff operacional atualizado — 31/10/2026 (prioritário sobre as seções históricas abaixo)

**Fonte:** baseline `main@238d4f70c5cf4576808fdd43af4a3d72b4e0b7cc` mais evidência local do [PR #201](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201#issuecomment-6549181674), **integrado** via squash `0095318bb0f1b2392cd8e3f085630c3c80b3a3f9` com [estado operacional atualizado](current-state.md). [Auditoria de governança](governance-audit-2026-10-31.md).

**Já encerrado em escopo restrito:** `EXTRATOS-ANALITICOS-READONLY-01`/AE01 (oráculos) e [auditoria documental 14/14](../discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md). Não os reiniciar como primeiro gate. No C2, PR #200 integrou somente desenho; o BU15 do PR #201 aplicou `PERIODO_ANO=2019` numa única rota, com `-Verify` local de integridade PASS reportado. **Não** homologou a série de 12 pontos, C2 global, D2/P5 ou o painel.

**Próxima sequência curta:** (1) somente mediante autorização separada, gate físico da evolução guiada de 12 competências de 2019 com o oráculo anterior, sem repetir o despacho já encerrado no PR #201; (2) gates C3 e C4 **necessários aos indicadores aprovados**, mantendo a ordem física do Boundary 7; (3) GO formal antes de IX; (4) três painéis QlikView 12 + relatório e submissão acadêmica. A [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) segue decisão científica pendente para indicadores condicionados T25/T26, não bloqueio universal das análises independentes.

**Classificação:** `PR_201=MERGED`; `C2_DISPATCH=PASS_VISUAL_RESTRICTED_LOCAL_REPORTED`; `C2_P12_2019_12_POINTS=NOT_VALIDATED`; `C2_FULL=NO_GO_NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. Nenhuma permissão física, merge ou limpeza de branches decorre desta atualização.

**As seções com datas 22–29/10 abaixo são histórico de decisões e dependências**, não ordens para repetir as tarefas concluídas.

---

## Atualização estratégica — 27/10/2026 | Dois fluxos, sem alterar contratos

**Nova prioridade escolhida pelo responsável em conversa e registrada no PR #159 (verificar integração na `main`):** validar primeiro se os dados já existentes sustentam **12 perguntas e três painéis candidatos**, por meio do gate independente `EXTRATOS-ANALITICOS-READONLY-01`, descrito em [direcionamento](analytical-direction-2026-10-27.md), [inventário](../discovery/analytical-question-inventory-2026-10-27.md) e [plano](../discovery/analytical-sufficiency-plan-2026-10-27.md). Isso antecede a implementação visual, **não** antecipa G6/Fase IX.

**Fluxo A — valor analítico independente:** séries/rankings SIH/RD, observabilidade CNES/LT e fluxos RES→SERV **dentro de uma fato**, com números e ressalvas; não exigem G1 T25/T26, Link Key global ou cobertura hospitalar integral. Não transformar essa suficiência em homologação física de visual/filtro.

**Fluxo B — integração e indicadores condicionados:** a cadeia G1→G7 histórica abaixo continua relevante **para T25/T26 e painéis finais que dependam de indicadores cruzados**, com aprovações e dependências próprias. G1/#157 **permanece aberto**; T24 condicionado à V2/Link Key/contrato de medidas. A ordem física C2→C3→C4 do Boundary 7 não foi alterada.

**Decisão de produto pendente:** após a matriz de suficiência, aprovar a especificação dos painéis/objetivo eventualmente refinado; alterações materiais na promessa acadêmica exigem decisão expressa e, quando necessário, professor. Nenhum merge, COM, QVD/QVW, Fase IX ou produção autorizado por esta atualização.

## Resultado final exigido (e não apenas a quantidade de testes)

Entregar um **Data Mart reproduzível em QlikView 12**, com as três fatos e oito dimensões da modelagem aprovada, **pelo menos três painéis** com indicadores numericamente defensáveis, comportamento de filtros demonstrado e notas metodológicas visíveis. Concluir o relatório acadêmico com Capítulos 3–5, capturas e comentários das análises, Referências, Anexo I (scripts de transformação das dimensões) e Anexo II (scripts de transformação das fatos, respeitando a constelação aprovada); preservar Capítulos 1–2 já entregues. Confirmar no calendário/professor a **data da segunda avaliação**, quando vence a segunda entrega via Google Classroom. O roteiro oficial prevê ≥6 dimensões, ≥1 fato e ≥3 painéis; o projeto aprovado tem 8 dimensões e 3 fatos.

**Não usar a porcentagem de tarefas, número de PRs, número de execuções ou um PASS local como evidência substitutiva de aceitação científica e entrega funcional.** Conclusão requer integridade de dados, medidas válidas, navegação segura, QlikView real, documentação e aceite do responsável. Não atribuir taxa de ocupação a `internações/leito`, não somar snapshots LT em anos e não chamar o universo CNES/LT observado de oferta hospitalar integral.

## Ordem dos gates para indicadores condicionados (registro do caminho G1–G7 de 22/10)

A sequência abaixo **não é mais prioridade universal da validação analítica independente**. Continua aplicável quando um indicador ou painel precisa dessas associações, denominadores, cobertura e UX. Os trabalhos sobre uma só fato devem seguir o plano de suficiência e não saltar para a Fase IX.



**Interpretação obrigatória:** a enumeração G1–G7 é um caminho de **decisões e dependências de aceitação acadêmica**, não uma autorização para reordenar gates de **execução física** aprovados pelo Boundary 7. A avaliação metodológica G1 é READ-ONLY e pode anteceder implementação; o fechamento físico de C2, C3 e C4 continua sujeito à respectiva ordem, aos bloqueios e a autorizações independentes. A especificação documental de UX pode avançar isoladamente, mas a guarda P5 do KPI só pode ser homologada depois do contrato físico de medidas relevante. 

| Gate | Problema real a resolver | Evidência mínima para `RESOLVED_ACCEPTED` | Dependência de liberação |
|---|---|---|---|
| **G1 — VIII-C4-SCIENTIFIC-SUFFICIENCY** | Escopo científico de T25/T26: matriz de recortes CNES/LT observados válidos, cobertura, ausência versus zero, universo hospitalar e necessidade de aval do professor | Matriz por indicador×recorte; fonte/oráculo, território/papel, competências e denominador; indisponibilidades explícitas; decisão do responsável e consulta ao professor se alterar a promessa do trabalho; Issue [#157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) aceita | **Primeiro somente na trilha T25/T26**, READ-ONLY; não é pré-condição para agregação descritiva independente da própria fato |
| **G2 — VIII-C3-LINK-CONTRACT** | Fechar o contrato global de associações e Link Key; não generalizar C3-B1/B2 | Confrontação dos cenários faltantes realmente necessários; inventário QlikView, cardinalidade, nulos não aplicáveis, papeis RES/SERV, ausência de `$Syn`/loops indevidos; decisão explícita global ou bloqueio | Para indicadores cross-fact, G1 define escopo; preservar ordem física aprovada e pendências C2/C3 antes do aceite C4 |
| **G3 — VIII-C4-MEASURES-CONTRACT** | Aprovar numeradores, denominadores, agregação temporal/territorial e expressões físicas T24/T25/T26/FLU | Expressões versionadas, oráculos independentes em recortes autorizados, cobertura/zeros/ausências e filtros; `MEASURES_AND_DENOMINATOR_CONTRACT` decidido explicitamente | Para indicadores cross-fact dependentes: G1 e G2; não duplicar pilotos |
| **G4 — VIII-C2-GUIDED-UX-P5-D2** | Completar política temporal da navegação guiada Mensal/Anual/Evolução e proteção efetiva P5/D2, não apenas textos | Contrato mínimo UX, estados proposta/aplicada, cenários físicos de transição necessários; bloqueio real de KPI incompatível; rotas de seleção relevantes auditadas ou limitação formal decidida sem declarar cobertura global inexistente | UX documental pode ser elaborado independentemente; **aprovação física de KPI** depende do contrato G3 |
| **G5 — VIII-CLOSEOUT-ACCEPTANCE** | Reconciliar os gates do indicador, fluxo ETL, associação, filtro, cobertura e limitações; GO/NO-GO formal | Matriz de aceite do responsável com links a logs, SHA, QVS/QVW, screenshots e oráculos; pendências externas discriminadas; decisão explícita `PHASE_IX` | G1–G4 resolvidos **onde aplicáveis ao escopo aprovado**, com decisão explícita para exclusões; nenhuma autorização automática |
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

**Prioridade histórica definida em 27/10: `EXTRATOS-ANALITICOS-READONLY-01` (independente; agora superada pelos fechamentos P1–P3 integrados).** O gate G1 / Issue #157 continua recomendado **apenas na trilha de suficiência T25/T26** em Discovery READ-ONLY. Reusar [#133](../discovery/phase-8-cnes-presentation-scope-decision-2026-10-20.md) e [C4-D](../discovery/phase-8-c4d-global-indicator-gaps-readonly-2026-10-21.md), [C4-E](../discovery/phase-8-c4e-cnes-coverage-unavailability-readonly-2026-10-21.md), [C4-F](../discovery/phase-8-c4f-vi-p4-export-readback-2026-10-21.md), [C4-G](../discovery/phase-8-c4g-cnesnet-201801-screenshot-closeout-2026-10-21.md). O agente deve produzir matriz e uma **decisão objetiva**, não nova discovery exploratória. Se prova suficiente: propor aceite explícito para `RESOLVED_ACCEPTED`; se não: classificar `BLOCKED_EXTERNAL` com pergunta/prova concreta e manter o item aberto. **Não** abrir G2 da trilha dependente sem G1 aceito; a trilha analítica independente não libera G2 nem precisa aguardar resolução universal de T25/T26.

## Atualização de handoff — 29/10/2026 (após P3.4)

**FATO VERIFICADO NO GIT:** PRs [#190](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/190)–[#193](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/193) integrados, sem aprovação científica global ou de produção; a trilha P1–P3 tem oráculos numéricos restritos. [#166](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/166) definiu **A0 padrão**, A1 condicional **somente** P2.3; [#168](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/168), [#170](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/170) e [#169](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/169) registram A1 P2.3 R2 PASS **candidato restrito**, não UI. [#167](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/167) segue Draft com A0 R1 não validada **para P2.3**, sem invalidação dos demais 13 visuais.

**Próximo gate recomendado, não executado:** revisão **incremental READ-ONLY** do consumo dos 14 visuais, exclusivamente para lacunas restantes de fonte física, dimensões/filtros, roles RES/SERV, competência/ano, observabilidade, UX e evidências; **não** repetir AE01, A0 R1, P2.3 R2, P1–P3 nem a decisão documental A0×A1. Entregar matriz 14/14 referenciando oráculos anteriores, até três bloqueios de alto impacto e handoff por gate autônomo. Essa revisão **não** concede implementação física, autorização de COM ou Fase IX, nem reordena C2→C3→C4. G1/[Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) continua aberta **somente** para indicadores T25/T26 condicionados. Ver [current-state](current-state.md) e [auditoria documental](../discovery/sad-operational-documentation-drift-audit-2026-10-29.md).
