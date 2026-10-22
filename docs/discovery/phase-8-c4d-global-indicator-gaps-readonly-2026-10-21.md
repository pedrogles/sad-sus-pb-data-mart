# SAD — Data Mart SUS PB | C4-D — Matriz READ-ONLY das lacunas globais dos indicadores

> **Nota de integração documental (21/10/2026; origem: relatório local/Library):** Este documento preserva o texto, os resultados e as condições de prova do closeout original. Baseline vigente na preparação deste PR: `main@4b2d062536c42fe718fc622adc66f55e6d44e3a1` (C2-I #150 já integrado). Afirmações abaixo como “ainda Draft”, “fora da main” ou “próximo gate” são fotografias da data da revisão, não instruções operacionais atuais. A recomendação posterior C4-E foi executada somente como revisão local; no momento da incorporação, C4-E/F/G também possuem closeouts locais. Referências a PRs #110–#114 como Draft refletem a data do relatório; foram posteriormente integrados à main. A publicação não inclui TXT/PNG/ZIP/QVD/QVW de origem nem reproduz COM, e **não aprova** cobertura hospitalar, zero real, Link Key, medidas, P5/D2, dashboards ou produção.

**Data da revisão:** 20/10/2026 (horário de João Pessoa; documentação C4-B1 datada de 21/10 UTC/registro).  
**Repositório:** `pedrogles/sad-sus-pb-data-mart`  
**Branch/HEAD confirmado:** `main@a3e904e32b71858cd4d7fba3c027845cfc8fe8d7` (PR #143).  
**Resultado do gate:** `C4D_READONLY_REVIEW=COMPLETED_WITH_LIMITS` (conclusão desta revisão, **não** estado integrado à `main`).  
**Execução:** GitHub READ-ONLY; sem COM, QlikView, PowerShell, novos testes, alterações de dados, commits, PR ou merge.

## 1. Contrato da revisão

**Objetivo:** confrontar evidências já registradas de T24/RES, T25/LEI, T26/REL e FLU com a semântica V2 §62 e a ordem do Boundary 7 para qualificar suficiência, lacunas, bloqueios e propor **um único próximo gate**.  
**Fontes verificadas na ordem obrigatória:** `AGENTS.md`; `docs/project/current-state.md`; `docs/academic/requirements.md`; `docs/discovery/boundary-7-implementation-plan.md`; `docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md`; depois closeouts C2/C3/C4, C1, decisão CNES e relatórios históricos dos PRs #110–#114.  
**Invariantes:** três fatos/oito dimensões; Star/constelação; grãos acadêmicos; `IDENT=5` não é nova internação; POP e LT semi-aditivos no tempo; papéis RES/SERV distintos; nenhum zero presumido; nenhum rótulo CNES set/2019 retroativo; QlikView 12; sem Fase IX.  
**PASS documental:** matriz rastreável por evidência, lacunas separadas por natureza, um gate mínimo motivado e STOP. **BLOCKED:** tentar certificar cobertura física não demonstrada, atribuir aprovação global a PASS restrito ou derivar fatos dos oráculos sem inspeção. **STOP:** publicação local desta matriz, sem novo trabalho.

## 2. Qualificação de evidência

- **S — semântica:** V2 §62 aprovada exclusivamente nos significados, filtros, papéis, agregações e indisponibilidade; não aprova expressão física Qlik.
- **L — execução local reportada:** Windows/QlikView 12, script/commit e resultado descritos em relatórios; não é auditoria autônoma do COM e dos binários.
- **E — artefatos exportados auditados:** confronto independente de CSVs, manifestos, hashes reportados e resultados; não reproduz o COM nem abre QVD/QVW originais.
- **D — documental/estático:** documentação canônica e scripts inspecionados sem execução física adicional.
- **A — aceite formal:** não existe aprovação global das medidas, Link Key, Fase IX ou produção.

## 3. Matriz C4-D

| Frente / indicador | Evidências suficientes, no limite contratado | Lacuna específica ainda aberta | Natureza e dependências | Decisão atual |
|---|---|---|---|---|
| **T24 / RES — anual** | **L:** PR #110, 5 cenários (PB 2017–2019, João Pessoa e Campina Grande 2018) com QTD_INTERNACAO e POP RES reconciliados; `IDENT=5` excluído da contagem de novas internações | Não cobre indisponibilidade aplicada no objeto final, matriz integral P5, anos/filtros não testados ou contrato global | Física + integração; C2/P5 e D2 | **Suficiente só para cinco contextos candidatos. Não repetir.** |
| **T24 / RES — parcial, regional e indisponibilidade** | **L:** PR #111, 3 parciais (inclui competências 201801 e 201803 descontínuas), POP anual uma vez; PR #112, RES JP+CG/2018: 61.616 internações e POP 1.207.795; guardas de ausência/multi-ano no wrapper; ausência de POP PB para residentes externos no oráculo | Prevenção D2 no painel antes de qualquer seleção não demonstrada; seleção externa não executada via COM; série multi-ano segmentada não homologada; P5 simultâneo incompleto | Física/interface + semântica V2 já definida; C2/D2 e P5 | **PASS local restrito de componentes e wrapper; interface NO-GO.** |
| **T25 / LEI — município isolado** | **L:** PR #113, JP e CG 2018, 12/12 competências em cada município, 24 totais mensais, um parcial 201801; somas diagnósticas LT de 28.106 e 16.592, POP 800.323 e 407.472 (SERV) | 12 meses com linhas não atestam cobertura hospitalar nem zero nos municípios/meses sem registro; outros períodos, filtro P5 e anualidade global não homologados | Cobertura e físico; C1/CNES, P5 | **Apenas RN21 observado, por município/ano/casos ensaiados.** |
| **T25 / LEI — regional simultâneo** | **E + L:** C4-B1, SERV JP+CG 2018; 24/24 pares, 12/12 totais regionais; 44.698 é **soma de snapshots exclusivamente para média /12**; POP anual de duas linhas 1.207.795; taxa candidata 3,083994662449615... leitos SUS médios observados/1.000. 17 artefatos exportados e 215 verificações consistentes; execução COM local reportada | Não prova múltiplos anos, regiões arbitrárias, cobertura hospitalar, filtros concomitantes, denominadores com meses ausentes, COM/binaries auditados independentemente ou expressão oficial | Física restrita, cobertura e aceites formais | **`C4B1_CLOSEOUT=COMPLETED_WITH_LIMITS`. Não repetir.** |
| **T26 / REL — individual** | **L:** PR #114: JP e CG 2018 com 73.105/46.752 internações de serviço e os mesmos 28.106/16.592 snapshots acumulados exclusivamente para obter média; parcial JP/201801 com 5.741 internações e 2.386 leitos SUS observados | Relação **regional simultânea** RD×LT ainda não ensaiada; zero/ausência de leitos no denominador e cobertura por escopo não homologados; filtro RES é B; sem equivalência clínica de leito e internação | Física + cobertura; P5, C1/CNES | **Candidato apenas nos três recortes. Não é taxa de ocupação.** |
| **FLU — papéis de residência/serviço** | **E + L:** C3-B1 R≠S (2018, 4.027 RD, 3.806 elegíveis, 221 continuidade) e C3-B2 R=S (2018, 40.033 RD, 39.060 elegíveis, 973 continuidade, 1 linha POP=800.323 alcançável); artefatos exportados consistentes | Não autoriza reinterpretar seleção conjunta RES+SERV como RES/LEI/REL válido quando V2 marca filtro B; testes de dois pares não aprovam `%LINK_KEY` global nem todos os fluxos | Associativa; C3/Link Key + P5 | **FLU não implica POP no denominador; dois casos associativos candidatos fechados.** |
| **Contrato temporal geral** | **S + L:** V2 diferencia ano único, parcial, descontinuidade, múltiplos anos e KPI sem tempo; wrappers T24 e pilotos parciais demonstram subconjuntos | Série multi-ano separada por ano; transição ano↔competência em todas as rotas; períodos sem cobertura; regras de apresentação efetiva | Física/UI; D2 + P5 | **Não aprovado globalmente.** |
| **Filtros e contexto associativo (P5)** | **S + D/L:** matriz C/R/I/B aprovada; C2 comprova determinados bloqueios pós-seleção em objetos experimentais e guarda de wrapper; C3 demonstra comportamentos de alcançabilidade | Classes **C/R/I/B sob filtros simultâneos** para quatro indicadores; não ignorar seleção incompatível silenciosamente; bloqueio pré-seleção por toda a UI não comprovado | Física/UI; `C2_FULL=NO_GO`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY` | **NO-GO para filtro/UI geral.** |
| **Cobertura mensal CNES/LT e zero/ausência** | **D + E:** C1 documenta 24 pares observados de JP+CG 2018; C4-B1 audita diretamente 24 componentes F2. VI-P4/C1 identificaram **4.467 pares município×mês sem LT** e **97 pares com QT_SUS=0 observado** no universo PB 2017–2019 | Falta critério observável que converta ausência em zero comprovado; linha com zero não comprova cobertura completa; 36/36 arquivos não provam elegibilidade por recorte; incompletude fora de JP/CG | **Cobertura/semântica aplicada a dados**; C1/CNES + decisão externa metodológica | **Bloqueia generalização T25/T26.** |
| **Universo hospitalar, ST/TP_UNID e nomenclaturas T29** | **D:** LT válida preservada pela RN21; ST↔LT pareado observado, decisão #133 permite rótulo **CNES/LT observado** nos recortes reconciliados; T29 1.965/2.021 combinações código×competência sem descrição histórica comprovada | Não há regra oficial vigente e testada de classificação estritamente hospitalar por competência; não se pode herdar descrição de 201909; não há aceite professor/prod | Cobertura histórica + dependência normativa/externa; `C1_HOSPITAL_SCOPE=NO_GO`; `T29_HISTORICAL=NOT_APPROVED` | **Somente universo RN21 observacional autorizado para apresentação restrita.** |
| **Controle global das chaves, medidas e produção** | **D + L/E:** Fases V–VII e C3 preservam fatos e Link candidato; C4-B1 inventários exportados reportam 22 QVDs + 25 QVWs inalterados em sua janela; `main` atual conferida | Auditoria das exportações não equivale à certificação de binários/COM; `%LINK_KEY`, medidas e denominadores globais não aprovados; dashboards finais não testados | Governança/validação separada; C2, C3, C4 e Fase IX | **`LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.** |

### Decisões pendentes de autorização, não implementações

1. **Cobertura/denominador:** qual evidência oficial e datada define cobertura suficiente e zero real de LT no recorte município×competência×universo? Enquanto não houver, usar indisponibilidade, sem inventar zeros.
2. **Escopo hospitalar histórico:** se/quando uma regra externa de `TP_UNID` ou equivalente vier comprovada, sua validade histórica, efeito e aceite devem ser avaliados separadamente; não substituir automaticamente o universo RN21 observado.
3. **C2/D2/P5:** escolher superfície controlada de seleção com prova de rotas alternativas, ou manter bloqueio formal; nenhuma alteração na V2 sem aprovação.
4. **Contratos físicos finais:** aprovação explícita posterior de medidas/denominadores e `%LINK_KEY` após evidências pertinentes; testes restritos não promovem esses estados.

## 4. Conclusões

**FATOS VERIFICADOS NAS FONTES:** (i) `main` está no SHA informado; (ii) C4-B1 encerrou um caso T25 regional simultâneo de serviço e reconciliou numerador de leitos médios com POP anual; (iii) T24, T25, T26 e FLU dispõem de provas **locais/candidatas** em casos específicos; (iv) C2 não demonstrou D2 em toda a interface, P5 simultâneo integral nem cobertura CNES histórica; (v) a maioria dos casos matemáticos isolados já foi executada e não deve ser repetida.

**INTERPRETAÇÃO:** A principal barreira à validade global não é uma divergência numérica encontrada em C4-B1. É a falta de um contrato verificável de **elegibilidade/cobertura e indisponibilidade** ao sair dos recortes com linhas LT observadas, agravada pelos bloqueios independentes C2/D2/P5 e Link Key. Um novo COM de T26 regional poderia provar outra seleção restrita, mas, sem resolver cobertura, não liberaria o contrato geral. **Não é proposta de abandonar T26 regional:** apenas de não priorizá-lo como próximo gate.

**NENHUMA NOVA DECISÃO SEMÂNTICA:** o universo RN21 continua preservado, assim como V2 §62 e Boundary 7. Uso dos rótulos experimentais T25/T26 segue decisão documental de apresentação #133, não aceitação hospitalar final.

## 5. Recomendação de um único próximo gate — NÃO AUTORIZADO

**`C4-E — CRITÉRIO DE SUFICIÊNCIA DE COBERTURA E INDISPONIBILIDADE CNES/LT (READ-ONLY)`**.

- **Objetivo único:** especificar, com material **já existente e fontes oficiais datadas**, se há evidência suficiente para classificar o universo `LT_TODOS_REGISTROS_VALIDOS_RN21` por município×competência×escopo como `OBSERVADO_COM_COBERTURA_DEFENSAVEL`, `ZERO_COMPROVADO`, `AUSENCIA_NAO_ZERO`, `INCONSISTENTE` ou `INDETERMINADO`, **sem inventar método que a V2 não autorizou**. Tentar identificar o critério científico faltante; não certificar o Estado só porque os 36 arquivos existem.
- **Novidade versus C1/C4-B1:** C1 encerrou presença observada dos 24 pares JP/CG e identificou as lacunas de ausência/zero; C4-B1 provou o cálculo regional com linha observada. C4-E abordaria **somente a regra de elegibilidade de denominador fora desse caso**, sob ausência/zero e escopo, e produziria um contrato mínimo de indisponibilidade aplicável a T25/T26, não mais 24 reconciliações.
- **Entradas:** C1, VI-P4/VI-P5, F2 já congelado, ST↔LT existente, V2 §§62.4–62.7, decisão de apresentação #133 e documentação oficial CNES aplicável ao período. Não gerar dados, nem executar COM/Qlik, nem recarregar CSV/QVD.
- **PASS documental:** regra e proveniência suficientes **ou** decisão motivada de que nenhuma prova disponível permite certificar cobertura/zero, com marcações `BLOCKED_EXTERNAL` e critérios de evidência futura. Não converter a própria ausência de prova em aprovação de cobertura.
- **STOP:** uma única matriz de classificação de evidências, lista objetiva de bloqueios e eventual decisão para aprovação separada. **Não iniciar** classificação física, coleta ilimitada, T26 regional, UI, merges ou Fase IX nesta frente.
- **Trade-off:** menor ganho imediato de cobertura numérica de novos testes que um T26 regional físico, mas maior ganho metodológico para determinar **quais razões poderão ser publicadas** com validade e por que certas razões permanecerão indisponíveis.

**Gates preservados no encerramento desta revisão:**

`C4D_READONLY_REVIEW=COMPLETED_WITH_LIMITS` (desta revisão, ainda fora da main); `C2_FULL=NO_GO_NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

## 6. Fontes canônicas e histórico probatório

- [`AGENTS.md`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/AGENTS.md)
- [`current-state.md`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/project/current-state.md)
- [`requirements.md`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/academic/requirements.md)
- [`Boundary 7`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/boundary-7-implementation-plan.md)
- [`Semântica V2 §62`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md)
- [`C1 — cobertura CNES`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-c1-cnes-coverage-readonly-2026-10-18.md)
- [`C2 — closeout`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-c2-evidence-closeout-readonly-2026-10-20.md)
- [`C3-B1`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-c3b1-physical-closeout-2026-10-20.md) / [`C3-B2`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-c3b2-physical-closeout-2026-10-20.md)
- [`C4-A`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-c4a-measures-evidence-triage-2026-10-20.md) / [`C4-B1 F2/F3`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-c4b1-f2f3-regional-reference-readback-2026-10-20.md) / [`C4-B1 físico`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-c4b1-regional-t25-physical-closeout-2026-10-21.md)
- [`Escopo de apresentação CNES/LT observado`](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-cnes-presentation-scope-decision-2026-10-20.md)
- Pilotos históricos, **não integrados à main:** [PR #110](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/110), [#111](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/111), [#112](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/112), [#113](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/113), [#114](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/114).

**STOP C4-D:** revisão encerrada. Arquivo gerado apenas como artefato local exportável, não integrado ao repositório.