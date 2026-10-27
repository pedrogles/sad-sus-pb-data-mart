# SAD SUS PB — Inventário de perguntas e três painéis candidatos (27/10/2026)

**Gate encerrado:** `INVENTARIO-ANALITICO-READONLY-01` — inventário documental, **não** extração física, homologação de filtros/QlikView ou aceite da Fase IX. `main@9f4fc0ea43dfe8b6f20f7b6254bc7f965f6a9c04` no levantamento. Números abaixo são resultados de execuções locais reportadas e documentação reconciliada; QVDs/QVWs não foram reabertos no ambiente deste inventário.

## Critérios e legenda

- `RESULTADO_JA_RECONCILIADO` (R): valor e regra presentes em evidência rastreável, com nível de prova indicado.
- `CALCULAVEL_SEM_DADO_NOVO` (C): medida/grão/regra comprovados, mas agregado específico ainda não exportado/reconciliado.
- `CONDICIONADO_A_CONTRATO` (D): análise exige também contrato físico, cobertura ou filtro não aceito.
- `NAO_SUSTENTADO` (N): pergunta que a base não pode responder defensavelmente.
- P0 = primeira prioridade analítica; P1 = complementar; P2 = indicador transversal condicionado. Prioridade **não autoriza implementação**.

## Proveniência e compatibilidade física dos campos

As colunas de negócio descritas na matriz podem estar disponíveis **na origem/staging** e não como campos diretos da fato. O QVS versionado `TRANSFORMACAO/transf_fato_internacao.qvs` projeta `FATO_INTERNACAO.qvd` com `%SK_PROCEDIMENTO`, `%SK_DIAGNOSTICO` e `%LINK_KEY`; ele **não expõe diretamente** `PROC_REA`, `DIAG_PRINC`, município de residência ou município de serviço. Já `TRANSFORMACAO/transf_fato_capacidade_leito.qvs` expõe `FATO_LT_CNES_ORIGEM`, `FATO_LT_CODLEITO_ORIGEM` e `FATO_LT_COMPETENCIA_ORIGEM`, mas o município de localização está na coordenada de `%LINK_KEY`, não como campo municipal direto. Para obter agregações por município/papel, procedimento ou diagnóstico **sem presumir aceite associativo global**, começar por extratos de `EXTRACAO/QVD/SRC_SIH_RD.qvd` ou `SRC_CNES_LT.qvd` com regras validadas e oráculos; joins por SK/dimensões e ligação por `%LINK_KEY` só quando a estrutura/compatibilidade estiver comprovada no recorte. A menção a campo de origem nesta matriz **não afirma que existe na fato**.

## Matriz (12 perguntas)

| ID | Pergunta de negócio | Fonte e medidas | Recorte/regra | Número ou evidência | Estado | Ressalva e dependência mínima | Painel/prioridade |
|---|---|---|---|---|---|---|---|
| I01 | Como evoluiu a produção de internações processadas por ano? | SIH/RD `QTD_INTERNACAO` | Ano da competência, `IDENT=5` vale zero | 2017=183.532; 2018=183.311; 2019=188.246; **local reportado** [F5-RD] | R | Não pacientes únicos; verificar exibição no Qlik posteriormente | P1/P0 |
| I02 | Como variam internações por competência mensal? | SIH/RD `QTD_INTERNACAO` | 36 competências, soma por mês | — Agregado mensal não exportado | C | Extrato mensal, sem usar `DT_INTER` como competência | P1/P0 |
| I03 | Onde se concentram internações por município de serviço? | SIH/RD `QTD_INTERNACAO`, SERV | Município SERV × ano; participação no total de atendimento PB | — Ranking não exportado | C | Extrato SERV×ano; não interpretar residência | P1/P0 |
| I04 | Quais procedimentos realizados concentram mais produção? | SIH/RD `PROC_REA`, `QTD_INTERNACAO` | Código de procedimento × competência/ano | — Ranking não exportado | C | Extrato e descrição/hierarquia oficial compatível; não `PROC_SOLIC` | P1/P0 |
| I05 | Quais diagnósticos principais são mais registrados? | SIH/RD `DIAG_PRINC`, `QTD_INTERNACAO` | CID principal × ano | — Ranking não exportado | C | Extrato; não prevalência clínica populacional | P1/P1 |
| I06 | Quantos dias de permanência e valores administrativos foram registrados? | SIH/RD `DIAS_PERMANENCIA`, `VALOR_TOTAL` | Soma dos registros administrativos 2017–2019 | 3.133.578 dias; R$ 659.384.649,05; **local reportado** [F5-RD] | R | Inclui continuidades; valores registrados não são custo econômico total | P1/P1 |
| I07 | Como evoluíram óbitos administrativos registrados? | SIH/RD `INDICADOR_OBITO` | Ano da competência | 2017=8.626; 2018=8.649; 2019=9.336; total=26.611; **local reportado** [F5-RD] | R | Não taxa clínica ou pacientes distintos | P1/P1 |
| I08 | Que fração da produção envolve R=S versus R≠S? | SIH/RD `QTD_INTERNACAO`, RES/SERV | Agrupar igualdade/desigualdade no universo PB | Pilotos 2018: 39.060 R=S JP→JP; 3.806 R≠S 250180→JP [C3]; **não totais globais** | C | Exportar e reconciliar todos os pares; pilotos não provam % global | P3/P0 |
| I09 | Quais origens→destinos concentram fluxos e quantos registros têm residência externa? | SIH/RD `QTD_INTERNACAO`, RES/SERV | Ranking de pares; externos separados | 5.202 **registros RD** externos [F5-RD], não 5.202 novas internações; ranking — | C | Extrato por par com `QTD_REGISTRO_AIH` e `QTD_INTERNACAO`; sem POP PB artificial | P3/P0 |
| I10 | Onde há LT positivo, zero observado e falta de linha? | CNES/LT `QT_SUS`, VI-P4 | Município×competência (223×36) | Positivos=3.464, zeros observados=97, sem linha=4.467, total=8.028 [C4-F] | R | Zero observado não comprova zero real; ausência não é zero | P2/P0 |
| I11 | Como se distribuem e evoluem leitos registrados por território/CNES/código? | CNES/LT `QT_EXIST`, `QT_SUS`, `QT_NSUS`, `CNES`, `CODLEITO` | Snapshot por competência e município/estabelecimento/código | Exemplos 201701: 250010=20/20; 250460=40/0 [C4-F]; ranking — | C | Extratos mensais; média só sob meses válidos; T29 e escopo hospitalar não aprovados | P2/P0 |
| I12 | Qual a razão de internações de residentes por 1.000 habitantes? | SIH/RD `QTD_INTERNACAO`, IBGE `POPULACAO_ESTIMADA` | T24 RES/POP mesmo território/ano ×1.000 | Piloto 2018 JP+CG: 61.616/1.207.795 [C4-D]; caso candidato | D | V2 e filtro/Link Key/denominador físico não aceitos globalmente | P1/P2 |

**Nenhum ranking novo foi inventado**. O próximo gate deve deixar números indisponíveis quando não houver exportação real.

## Três painéis candidatos e testes mínimos

| Painel | 3–5 visualizações sugeridas | Filtros/grão | Dados suficientes para começar? | Limites |
|---|---|---|---|---|
| **P1 — Produção Hospitalar** | KPIs anuais I01/I06/I07; série mensal I02; ranking SERV I03; ranking PROC_REA I04; ranking DIAG_PRINC I05 | Ano/competência; SERV; procedimento/diagnóstico em análises específicas | Sim, medidas SIH/RD materializadas conforme PASS local; faltam extratos detalhados | Matriz P5 se misturar filtros; data clínica ≠ competência |
| **P2 — Distribuição Observada de Leitos** | ranking municipal mensal; linha mensal SUS/existentes; matriz observabilidade; composição SUS/não-SUS; tabela CNES×código | Município SERV/localização, competência, CNES, código | Sim para observação descritiva de LT; faltam agregados | Não somar snapshots anuais; não atestar hospitalidade nem nomes T29 |
| **P3 — Fluxos Territoriais** | matriz RES→SERV; R=S/R≠S; ranking destinos; ranking origens; série de fluxos | Ano/competência e papéis RES/SERV separados | Sim em SIH/RD, com duas provas de pares; falta agregação global | Não imputar saída de PB nem POP para externos; Link global ainda não aceito para consultas inter-fatos |

## Fontes e nível de prova

- [F5-RD — FATO_INTERNACAO](phase-5-fato-internacao-implementation-2026-10-15.md): 566.672 registros, 555.089 internações, 11.583 continuidades, 36 competências, valores anuais, óbitos, dias e centavos — **PASS local reportado**, sem auditoria contemporânea dos binários.
- [F5-LT — FATO_CAPACIDADE_LEITO](phase-5-fato-capacidade-leito-qvd-materialization-2026-10-15.md): 35.518 linhas; `QT_EXIST` e `QT_SUS` observados em 36 meses — PASS local reportado.
- [F5-POP — FATO_POPULACAO](phase-5-fato-populacao-qvd-materialization-2026-10-16.md): 669 município×ano, 223 municípios×3 anos — PASS local reportado.
- [C3-B1](phase-8-c3b1-physical-closeout-2026-10-20.md) / [C3-B2](phase-8-c3b2-physical-closeout-2026-10-20.md): dois pares RES/SERV reconciliados em pilotos, **não** contrato associativo global.
- [C4-D](phase-8-c4d-global-indicator-gaps-readonly-2026-10-21.md): pilotos de T24/T25/T26 e lacunas físicas.
- [C4-F](phase-8-c4f-vi-p4-export-readback-2026-10-21.md): auditoria de exportações e classes de observabilidade, não certificação de zero real.
- [V2 §62](phase-6-semantic-v2-approved-2026-10-14.md) e [Boundary 7](boundary-7-implementation-plan.md): semântica e ordem obrigatórias.

**Resultado:** `INVENTORY_DOCUMENTED_READONLY`. A meta seguinte é produzir agregados, qualificar validade de cada visual e concluir a especificação revisada, **sem** executar a Fase IX.
