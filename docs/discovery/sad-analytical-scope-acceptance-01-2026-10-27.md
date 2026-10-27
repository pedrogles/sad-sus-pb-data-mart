# SAD SUS PB — Escopo analítico restrito aprovado pelo responsável (2017–2019)

**Gate:** `SAD-ANALYTICAL-SCOPE-ACCEPTANCE-01`  
**Estado:** `SCOPE_ACCEPTED_RESTRICTED_BY_OWNER_IN_CHAT` / `PR_DRAFT_NOT_MERGED` — aceite **exclusivamente do escopo analítico D1–D3** em 27/10/2026; não homologa consumo QlikView global, filtros, KPI transversal, painel físico, Fase IX nem produção.  
**Base Git:** `main@db5d6e6e23371422ca1d2d77a8576150aaf63d03`, lida em 27/10/2026.  
**Modo:** revisão documental READ-ONLY das evidências existentes; criação desta proposta em branch isolada. Nenhum QVD/QVW, script de transformação ou contrato acadêmico alterado.

## 1. Objetivo, autoridade e limites

Decidir **quais análises já demonstradas** entram no escopo candidato de três painéis acadêmicos, registrar os seus contratos mínimos de consumo, e separar fatos reconciliados de hipóteses e aprovações futuras. O aceite D1–D3 foi **expresso pelo responsável em chat**, após a proposta do PR #165. Não altera automaticamente o objetivo dos Capítulos 1–2 entregues nem substitui parecer do professor; a aprovação da documentação na `main` permanece separada.

Fontes: roteiro oficial do professor (`DescricaoProjetoSAD.pdf`; ao menos três painéis e implementação BI), `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/project/analytical-direction-2026-10-27.md`, `docs/discovery/analytical-question-inventory-2026-10-27.md`, `docs/discovery/analytical-sufficiency-plan-2026-10-27.md`, V2 §62 e Boundary 7. Respeitar a hierarquia de fontes do AGENTS.

**Invariantes:** QlikView 12 e fluxo BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL; `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`; oito dimensões aprovadas; Star por processo/constelação; grãos e RN21; RES e SERV em papéis distintos. `IDENT=5` não conta internação nova; leitos/população são semi-aditivos no tempo. Nenhuma soma de snapshots como capacidade anual e nenhuma razão internações/leito nomeada “taxa de ocupação”.

**Fora deste gate:** merge, QlikView/COM, novas recargas, criação de QVW, edição de QVD/QVW, gráficos de produção, nova associação física, indicadores globais T24/T25/T26, aceite de escopo hospitalar CNES, alteração V2 ou Capítulos 1–2, aprovação IX/produção. O gate documental não destrava o Boundary 7.

## 2. Cadeia de evidências e qualidade

- **AE01:** [PR #160](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/160), Draft; QVS/runner versionados no commit `8633f12a910f422f6b2e9af5e0d06d622ff13497`. Os CSVs/manifesto e relatórios de auditoria foram fornecidos fora do Git, com manifesto SHA-256 `0B1AA7DA6EF10A08B0F698250F199666525672DC763D6774CA4498B2A3C488D2`. Auditoria prévia: `EXPORTED_AND_RECONCILED_RESTRICTED`; sem acesso nesta sessão aos bytes dos QVDs/QVWs originais.
- **E1** `sih_fluxo_competencia.csv`: 30.255 grupos; SHA-256 `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`; campos `competencia, ano, municipio_res, municipio_serv, qtd_registro_aih, qtd_internacao, qtd_continuidade`.
- **E2** `sih_procedimento_competencia.csv`: 21.031 grupos; SHA-256 `81FCBD576EFE48560EE1666A443E3E73158179972E38241A48928C904D03B6A2`; `competencia, ano, proc_rea, qtd_registro_aih, qtd_internacao, qtd_continuidade`.
- **E3** `sih_diagnostico_competencia.csv`: 56.703 grupos; SHA-256 `3FC6C78746D74F815EBED62F1AF88D950F6BFB303343FBD199AA436E2AE7D230`; `competencia, ano, diag_princ, qtd_registro_aih, qtd_internacao, qtd_continuidade`.
- **E4** `lt_cnes_leito_competencia.csv`: 35.518 linhas; SHA-256 `BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88`; `competencia, municipio_serv, cnes, tp_leito, codleito, linhas_lt, qt_exist, qt_sus, qt_nsus`.
- **A0 R1:** [PR #164, parecer de auditoria #6451787982](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/164#issuecomment-6451787982), execução local reportada a partir do commit `7760c3079f998243e5bf72c44747aac60e2b76e0`. Arquivo `A0_20261027_R1_audit_bundle.zip` SHA-256 `e5eff236031b5c41d72deabaecefbef7ac4bf40ea248ef8e05fbfb30b6f53604`. Auditoria do pacote: **146/146** valores coincidentes com o oráculo (**P1.2 36; P2.2 *histórico do A0* 108; P3.1 apenas dois pares**). A série mensal denominada P2.2 no A0 corresponde ao **P2.1** deste escopo de 14 visuais; ver mapa de aliases abaixo. **Não** homologou toda a matriz RES→SERV, filtros globais ou aprovação visual.
- **Cálculos detalhados I02–I05/I08–I11:** relatório exploratório fornecido na Library, `SAD_suficiencia_analitica_12_perguntas_2026-10-27.md`. O processamento exploratório foi identificado como `EXPERIMENTAL_NOT_GATE_EVIDENCE`; seus rankings e percentuais NÃO foram reexecutados independentemente nesta revisão. Números abaixo são evidência derivada **restrita**, subordinada à trilha AE01 e à limitação de cálculo experimental.
- **F5-RD:** [documentação da fato de internação](phase-5-fato-internacao-implementation-2026-10-15.md). I06/I07 são relatos históricos de execução local; não há medidas correspondentes em E1–E4.
- **C4-F / C4-D:** [observabilidade](phase-8-c4f-vi-p4-export-readback-2026-10-21.md) e [piloto T24](phase-8-c4d-global-indicator-gaps-readonly-2026-10-21.md), respectivamente. O crosswalk de 223 municípios foi conferido pelo validador local de AE01, não reaberto nesta revisão.

**Reconciliação AE01 reportada:** cada um E1/E2/E3 representa 566.672 registros, 555.089 internações novas, 11.583 continuidades em 36 competências. E4: 35.518 linhas LT, 36 competências e 8.028 pares município×mês de observabilidade. Os campos acima são **campos dos extratos**, e não supostas colunas diretas das fatos QVD.

## 3. Matriz de decisão I01–I12

S = sustentada **nos extratos/limites indicados**, H = evidência histórica sem nova auditoria AE01; D = condicionada/não aprovada. “S” nunca significa consumo QlikView global homologado.

| ID | Fato/grão e universo | Resultado rastreado | Regra, evidência e limitações | Proposta |
|---|---|---|---|---|
| I01 | SIH/RD; ano da competência; atendimentos PB | 2017 **183.532**, 2018 **183.311**, 2019 **188.246**; soma **555.089** | `sum(qtd_internacao)` E1; A0 R1 P1.2 confirma 36 competências. Não pacientes únicos ou demanda reprimida | **S — P1** |
| I02 | SIH/RD; competência 201701–201912 | máximo `201905=17.292`, mínimo `201702=13.586` | `sum(qtd_internacao)` por competência E1; série R1 36/36. Competência administrativa ≠ data clínica | **S — P1** |
| I03 | SIH/RD; SERV×competência/ano | `250750=225.785`, `250400=137.396`; juntos 65,43% | E1 `sum(qtd_internacao)` por `municipio_serv`; resultado derivado exploratório. Código não é RES; nomes históricos a validar | **S por código — P1** |
| I04 | SIH/RD; PROC_REA×competência | `0310010039=55.157`; top 10 40,65% | E2 `sum(qtd_internacao)` por `proc_rea`. Sem descrição/hierarquia SIGTAP historizada | **S por código — P1** |
| I05 | SIH/RD; DIAG_PRINC×competência | `O800=28.747`, `O809=21.530` | E3 `sum(qtd_internacao)` por `diag_princ`. Sem inferência de prevalência ou diagnóstico clínico validado | **S por código — P1** |
| I06 | SIH/RD; registros do triênio, incluindo continuidades | **3.133.578** dias e **R$ 659.384.649,05** | F5-RD: `sum(DIAS_PERMANENCIA)` e `sum(VALOR_TOTAL)` conforme contrato histórico, sem nova auditoria AE01; não custo econômico | **H; opcional P1** |
| I07 | SIH/RD; óbito administrativo por ano | 2017 **8.626**, 2018 **8.649**, 2019 **9.336**; total **26.611** | F5-RD: `sum(INDICADOR_OBITO)`; sem E1–E4 e sem nova auditoria; não taxa de mortalidade | **H; opcional P1** |
| I08 | SIH/RD; RES versus SERV; internações novas PB | R=S **294.635**; R≠S **260.454** (46,92%) | E1, classificação por igualdade `municipio_res=municipio_serv` com `qtd_internacao`; extração global, não prova de deslocamento físico ou UI completa | **S — P3** |
| I09 | SIH/RD; RES×SERV×competência | maior par R≠S `251370→250750=12.176`; externos **5.202** registros, **5.067** novas internações | E1 soma por par; distinguir `qtd_registro_aih` e `qtd_internacao`; externo significa residência fora crosswalk PB, sem POP PB | **S por código — P3** |
| I10 | CNES/LT; grade 223×36 município×mês | **3.464** positivos, **97** zeros observados, **4.467** sem linha | C4-F + AE01 E4/manifesto e referência municipal. Ausência de linha ≠ zero; zero observado ≠ capacidade real nula | **S observacional — P2** |
| I11 | CNES/LT; snapshot por mês×município×CNES×tipo×código | `201701 QT_SUS=7.772`; `201912 QT_SUS=7.140` | E4 e A0 R1 **P2.2 histórico (aqui P2.1)**: `sum(qt_exist/qt_sus/qt_nsus)` no **mês**. Não somar meses como estoque; escopo hospital-only/T29 não aprovados | **S observacional — P2** |
| I12 | SIH/RD RES×ano / IBGE município×ano | piloto 2018 JP+CG: **61.616/1.207.795**, sem aprovação global | C4-D; candidato `1000 × internações RES / população do mesmo território/ano`. E1–E4 não contêm POP nem contrato Link Key/filtro/denominador global | **D; fora do núcleo dos painéis** |

**Síntese proposta:** 9 perguntas S (I01–I05, I08–I11), 2 H (I06–I07), 1 D (I12). Nenhuma pergunta é elevada a `PROD_APPROVED`. Os 669 município×ano de `FATO_POPULACAO` ficam preservados na modelagem acadêmica, ainda que T24 seja adiado.


**Mapa de IDs de testes anteriores para os 14 visuais aprovados:** `A0 P1.2` → `P1.2` (36 competências); `A0 P2.2` **série LT** → `P2.1` (108 medidas); `A0 P3.1` → `P3.1` (**somente dois pares**). O `P2.2` da especificação atual é **outro visual**, de composição SUS/não-SUS em competência isolada. Os mesmos totais mensais lhe servem de referência numérica, sem constituírem prova de objeto gráfico/UX. Nenhum novo teste foi executado para fazer esta correspondência.

## 4. Contrato mínimo de consumo — 14 visuais candidatos

**Regras comuns:** (a) identificar fonte física do painel e reconciliação posterior com o extrato-oráculo; (b) aplicar apenas filtros que coexistem **no mesmo extrato** ou cuja associação seja comprovada separadamente; (c) nunca tratar E1/E2/E3 como factos automaticamente ligados por SERV/PROC/CID; (d) validar níveis de grão, temporalidade, títulos, estado sem dados e notas metodológicas; (e) toda evidência de UI/Qlik final requer gate físico com autorização própria. As expressões abaixo são **contratos conceituais**, não Qlik expressions aprovadas.

| Visual | Fonte/grão, cálculo e filtros admissíveis pelo extrato | Evidência disponível e critério de aceite futuro | Status da proposta |
|---|---|---|---|
| **P1.1** KPIs anuais | E1 ano: `sum(qtd_internacao)`; filtro ano; I06/I07 apenas **complementos opcionais** F5-RD fora dos E1–E4 | Confrontar 183.532/183.311/188.246, total 555.089; excluir continuidades. Nunca anexar dias/óbito/valor sem auditoria específica | Base sustentada; complementos condicionados |
| **P1.2** série de 36 competências | E1 `competencia`: `sum(qtd_internacao)`; filtros competência/ano | A0 R1 **36/36**; gráfico deve conter sequência temporal íntegra 201701–201912 sem usar `DT_INTER` | Sustentada no oráculo; UI pendente |
| **P1.3** ranking serviço | E1 `municipio_serv` por ano/competência, opcional RES **do próprio E1** | Confrontar totais e top códigos; não usar rótulos geográficos sem crosswalk/temporalidade | Sustentada por código |
| **P1.4** top procedimentos realizados | E2 `proc_rea` × ano/competência: `sum(qtd_internacao)` | Confrontar ranking; filtros RES/SERV **não disponíveis em E2**; sem `PROC_SOLIC`/descrição histórica presumida | Sustentada por código |
| **P1.5** top diagnósticos principais | E3 `diag_princ` × ano/competência: `sum(qtd_internacao)` | Confrontar ranking; filtros RES/SERV/procedimento não coexistem no E3; não chamar incidência/prevalência | Sustentada por código |
| **P2.1** série de snapshots LT | E4 `competencia`; por ponto mensal `sum(qt_exist)`, `sum(qt_sus)`, `sum(qt_nsus)` | A0 R1 rotulada **P2.2 histórico**: 108/108 oráculos numéricos mensais; nunca somar valores da curva para “estoque de 2017/2018/2019”. Nenhum aceite visual. | Sustentada observacional |
| **P2.2** composição SUS/não SUS | E4 **uma competência explícita**; `sum(qt_sus)` e `sum(qt_nsus)` | Reutilizar 108 oráculos mensais A0 R1 de base numérica, **sem declarar que esse objeto de composição foi validado como P2.2 no A0**; exigir `qt_exist=qt_sus+qt_nsus` na competência | Sustentada observacional; UI condicionada |
| **P2.3** matriz observabilidade | E4 + grade municipal C4-F/crosswalk 223×36; positivo/zero com linha/sem linha | Conferir 3.464/97/4.467 e **8.028** pares; E4 sozinho não contém linhas ausentes, exige a grade comprovada | Sustentada no recorte C4-F; consumo físico condicionado à grade |
| **P2.4** ranking de leitos SUS municipais | E4 `municipio_serv` e **uma competência**: `sum(qt_sus)` | Confrontar `201912` top códigos; não interpretar cobertura/hospitalidade como completa | Sustentada observacional por código |
| **P2.5** CNES×tipo×código | E4 `cnes,tp_leito,codleito` × uma competência: `sum(qt_exist/qt_sus/qt_nsus)` | Grão e ausência explicitados; descrições `T29_HISTORICAL=NOT_APPROVED`. Sem contagem de hospitais operantes | Sustentada observacional por código |
| **P3.1** matriz RES→SERV | E1 pares `municipio_res,municipio_serv`, `sum(qtd_internacao)` por ano/competência | E1 contém agregação ampla; A0 R1 prova **somente** `250180→250750=3.806` e `250750→250750=39.060` em 2018, não toda a UI | Sustentada nos dados; validação visual/global pendente |
| **P3.2** R=S × R≠S anual | E1 comparação textual de RES/SERV, soma internações novas | Confrontar 294.635/260.454/46,92% e por ano; distinguir R≠S de viagem individual | Sustentada por E1 |
| **P3.3** ranking de pares R≠S | E1 pares com `municipio_res<>municipio_serv`, por ano/competência | Confrontar `251370→250750=12.176` triênio; não adicionar distâncias inexistentes | Sustentada por código |
| **P3.4** residentes externos | E1 residência fora da referência C5.2 × ano; mostrar `sum(qtd_registro_aih)` **e** `sum(qtd_internacao)` | Confrontar 5.202/5.067; não calcular taxa por população PB | Sustentada, conceito externo delimitado |

**Filtros e interfaces:** seleção mensal/anual/evolução e preservação de estado RES/SERV devem respeitar C2/P5/D2; isso permanece `C2_FULL=NO_GO_NOT_APPROVED` e `P5_D2_UI=NOT_TESTED_GLOBAL`. Validar futuramente qualquer interação entre fatos/SKs/`%LINK_KEY` antes de apresentá-la como funcional. O candidato P1.1 pode ter apenas o KPI de internações, tornando I06/I07 não bloqueantes. O candidato P2.3 exige construção verificável de grade, sem imputar zero.

## 5. Decisões D1–D3 — aceite restrito do responsável

**D1 — APROVADA:** **P1 5, P2 5, P3 4 visuais** como escopo analítico candidato, exclusivamente nos recortes/filtros descritivos documentados. Não inclui aprovação de implementação final nem prova de interação dinâmica entre campos ausentes dos extratos.

**D2 — APROVADA:** I06/I07 são **opcionais** e **não bloqueiam P1**; sua incorporação posterior requer evidência de consumo e apresentação própria. Continuam reportadas historicamente em F5-RD, não reavaliadas em AE01.

**D3 — APROVADA:** manter `FATO_POPULACAO`, três fatos/oito dimensões e a promessa acadêmica entregue, mas **não incluir I12/T24 no núcleo inicial dos visuais** até aceites de contrato. Confirmar alinhamento com o objetivo dos Capítulos 1–2; qualquer mudança material exige aprovação própria e, quando necessário, consulta ao professor.

**Evidência do aceite:** em 27/10/2026, após o assistente apresentar o PR #165 e perguntar expressamente “Você aprova D1–D3 nesses termos?”, o responsável respondeu **“aprovado prossiga”**. Esta resposta aceita **D1, D2 e D3 nos termos exibidos acima**. É autoridade de escopo do responsável, não aceite docente, merge, execução física ou liberação da Fase IX. O registro nesta branch documenta a aprovação; somente um merge futuro e especificamente autorizado tornará este texto vigente na `main`.

## 6. Três lacunas prioritárias e handoff

1. **Legendas e escopo histórico:** confirmar, somente para os códigos exibidos, crosswalk e descrições oficiais municipais/SIGTAP/CID/CNES; sem nomes históricos não validados, usar códigos. T29 e escopo hospitalar LT permanecem pendentes, sem afetar contagens observacionais.
2. **Evidência I06/I07:** métricas somente em F5-RD; não chamar de nova auditoria AE01. Se incorporadas ao painel definitivo, exigir prova de consumo/reconciliação delimitada, sem executar automaticamente.
3. **Indicadores inter-fatos e filtros globais:** T24 precisa de POP anual territorial/temporal e contrato de medidas/Link Key; T25/T26 dependem de G1/[Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157). Em casos aplicáveis, preservar a ordem C2→C3→C4 do Boundary 7 e aprovações separadas G1–G5 antes da Fase IX.

**Próximo passo após D1–D3 aprovadas:** preparar **outro gate delimitado** de revisão estática/READ-ONLY das lacunas de consumo, associações e UX **apenas para os 14 visuais**, confrontando o [PR #162](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/162) sem presumir A1/A2 nem reformular a constelação. A definição documental não antecipa qualquer passo C2→C3→C4, não reexecuta os 146 testes e não autoriza implementação. Concluir/reconciliar o estado documental do PR #162 antes de integrar alterações concorrentes em `current-state.md`. Preparação do Capítulo 3 pode iniciar sem prints falsos; entrega física de painéis depende de autorização `PHASE_IX` distinta.

## 7. Critérios e condição de parada

- `PROPOSAL_READY_FOR_OWNER_REVIEW`: **etapa anterior concluída** com matriz 12/12, contratos 14/14, fontes/evidências e três lacunas.
- `SCOPE_ACCEPTED_RESTRICTED_BY_OWNER_IN_CHAT`: **SIM, nesta branch**. D1–D3 aprovadas expressamente e registradas; alinhamento docente/Capítulos 1–2 continua condicionado caso uma alteração material se mostre necessária. **Não** é `PR_MERGED`, `PHASE_IX_GO` nem `PROD_APPROVED`.
- `BLOCKED_EXTERNAL`: quando a decisão depender de fonte oficial ou docente; registrar questão e não inferir resposta.
- **STOP nesta execução:** registro documental da aprovação D1–D3 na branch/PR Draft e encaminhamento do próximo gate, sem COM/reload/testes físicos, merge ou Fase IX. **Status encerrável agora:** `SCOPE_ACCEPTED_RESTRICTED_BY_OWNER_IN_CHAT` / `PR_DRAFT_NOT_MERGED`; nunca `PROD_APPROVED`.

Fontes de estado: [current-state](../project/current-state.md), [Boundary 7](boundary-7-implementation-plan.md), [direção](../project/analytical-direction-2026-10-27.md), [inventário](analytical-question-inventory-2026-10-27.md), [plano de suficiência](analytical-sufficiency-plan-2026-10-27.md), [caminho crítico](../project/final-delivery-critical-path.md), [PR #160](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/160), [PR #164](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/164).

## Adendo de integração dos cinco PRs (27/10/2026)

- Escopo D1–D3 **aprovado expressamente pelo responsável**; 14 visuais permanecem **candidatos** do ponto de vista da implementação física. `SCOPE_ACCEPTED_RESTRICTED_BY_OWNER_IN_CHAT` não implica `PHASE_IX` nem aprovação de dashboards.
- **Histórico preservado:** exportação AE01 do [PR #160](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/160) integrada após registrar tentativa 02 (código efetivamente usado `8633f12a910f422f6b2e9af5e0d06d622ff13497`); preparação A0 do [PR #163](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/163) e executores do [PR #164](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/164), execução efetiva R1 em `7760c3079f998243e5bf72c44747aac60e2b76e0`, 146/146 somente nos recortes testados.
- **PR #162** integrou a [matriz de fontes](sad-analytical-consumption-source-matrix-2026-10-27.md), a comparação candidata **A0 × A1** e o direcionamento de arquitetura. **A0 versus A1 segue decisão aberta**: a aprovação D1–D3 decide *o que analisar*, não materialização de camada A1. **A2/remodelagem não autorizada.** O próximo gate deve reutilizar a evidência A0 R1 ao avaliar o custo/benefício mínimo de A1, sem repetir os 146 testes.
- Os rótulos e contratos de consumo permanecem sujeitos à evidência histórica, à grade municipal LT, aos filtros físicos e à semântica aprovada em V2/Boundary 7. G1/[Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) continua aberta. Nenhum merge confirma aceitação de produção ou permissão de COM.

**STOP deste documento:** registrar especificação e aliases com rastreabilidade; nenhuma implementação ou terceiro teste de consumo por decorrência.
