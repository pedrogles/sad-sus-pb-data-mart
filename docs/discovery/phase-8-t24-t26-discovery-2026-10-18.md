# Fase VIII-A — Discovery READ-ONLY dos indicadores T24–T26 (18/10/2026)

**Estado:** `VIII_A=DISCOVERY_STATIC_COMPLETED_WITH_GAPS`; `VIII_B=BLOCKED_PENDING_BASELINE_AND_DECISIONS`; `T24_T26=NOT_PHYSICALLY_RECONCILED`; `PRODUCTION_APPROVED=False`.
**Fonte de verdade de entrada:** `main@337943d5c5b77067f842902fc679dbb68db87020` (PR #107 integrado). Este documento foi produzido em branch **exclusivamente documental**, sem execução QlikView, alteração de QVD/QVW, scripts de produção, merge ou abertura da Fase IX.

## 1. Fontes e níveis de prova

Consultados na `main`, em ordem: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, [bootstrap VIII](bootstrap-phase-8-indicators-2026-10-18.md), [Boundary 7](boundary-7-implementation-plan.md), [Boundary 6](boundary-6-qlikview-physical-architecture.md), [V2](phase-6-semantic-v2-approved-2026-10-14.md), [VI-P5](phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md), [gate VII](phase-7-technical-panel-controlled-gate-2026-10-18.md), `docs/project/qlikview-powershell-automation.md` e scripts `PAINEL/phase_vii_technical_model.qvs`, `tools/Invoke-SadPhaseViiTechnicalPanel.ps1`, além dos QVS factuais na `main`.

Referência auxiliar **histórica, não código aprovado da main**: PR #83, commit `26369052bd3f96de5f3eccf873c390053c20b561`, especialmente os experimentos E5–E21/F1/F2/F3/F4 e CNES. Evidências F1/F2/F3 foram executadas no Windows e seus artefatos/manifestos foram revisados anteriormente; **não** foram reexecutados ou reabertos nesta sessão. Material oficial do professor continua prevalecendo para requisitos acadêmicos.

**Estado GitHub verificado:** PR #106 MERGED; #107 MERGED; #90 OPEN/DRAFT. `main` não foi alterada por esta Discovery. `current-state.md` registra como referência de conferência o HEAD logo após #106 (`875a7b7...`), anterior ao atual #107: drift **apenas de metadado temporal**, sem evidência de desvio da modelagem.

**Evidências anteriores qualificadas:** Fase VII reportou 22 QVDs (10 extração + 12 transformação) preservados por SHA-256, 16 tabelas/15 associações no Table Viewer e ausência visual de `$Syn`/loops. `LINK_ANALISE.qvd` reportou 85.705 chaves/6 campos, SHA-256 histórico `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB`. Não houve acesso nesta sessão aos 22 binários, QVW temporário, fonte bruta ou QlikView 12 Windows; **não existe nova prova física**.

## 2. Contratos preservados

- QlikView 12 e cadeia `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`; Star Schema por processo, constelação com 3 fatos e 8 dimensões.
- `FATO_INTERNACAO` (566.672 linhas reportadas): `QTD_INTERNACAO` segue `IDENT=1 → 1`, `IDENT=5 → 0`; `QTD_REGISTRO_AIH` não substitui a medida. Eixo principal temporal: competência administrativa RD.
- `FATO_CAPACIDADE_LEITO` (35.518 linhas reportadas): `QTD_LEITOS_SUS` é snapshot mensal semi-aditivo; nunca somar meses para declarar leitos anuais.
- `FATO_POPULACAO` (669 linhas reportadas): `POPULACAO_ESTIMADA` uma vez por município×ano; `%LINK_KEY` projetada somente em memória no carregamento associativo.
- `LINK_ANALISE` mantém seis campos aprovados. `SAD-LINK-V1` usa literalmente `Hash128('SAD-LINK-V1', C,Y,R,S,E)` com prefíxos/representação de nulos da VI-P5. A revisão VII estrutural não aprova semântica/filtragem de indicadores.
- Papéis municipais: **T24 residência**; **T25/T26 serviço**. Demanda SIH/RD refere-se a atendimentos processados na PB. 5.202 registros administrativos de residentes externos, 5.067 internações elegíveis, não têm denominador populacional municipal PB.
- `T29_HISTORICAL=NOT_APPROVED`. Preservar todos os LT válidos; nomes de setembro/2019 não são históricos para 2017–2019. Não chamar T26 de taxa de ocupação.

## 3. Oráculos independentes candidatos

**O24 — T24:** RD CSV por competência, `IDENT=1` e `MUNIC_RES` no recorte; população IBGE/XLS com ponte municipal PB validada, uma ocorrência município×ano. `T24 = 1000 × N_RES / POP_RES_ANUAL`. Sem POP apropriada → indisponível.

**O25 — T25:** LT CSV por `CODUFMUN × COMPETEN`, `QT_SUS` agregado primeiro no território para **cada mês**. Com `k` competências exigidas e cobertura/escopo válidos, `T25 = 1000 × [sum_m(SUS_m) / k] / POP_SERV_ANUAL`. Ano completo requer 12 competências válidas. Meses parciais e descontínuos são identificados, sem anualização. Linha LT ausente não é zero comprovado.

**O26 — T26:** RD CSV no papel `MUNIC_MOV` e mesma janela do denominador LT: `T26 = N_SERV / [sum_m(SUS_m) / k]`. Não é ocupação; territórios, períodos e universo observacional precisam coincidir. Denominador ausente, nulo, negativo, zero ou sem validação → indisponível.

Os três oráculos devem usar **fontes originais e agregações independentes**, reutilizando F1/F2/F3 com manifestos verificados, e não a avaliação da própria expressão Qlik duas vezes. A tolerância candidata para razões é erro absoluto até `1e-6` na unidade exibida, sujeito a fixação formal antes de qualquer execução, com verificação exata dos componentes inteiros.

| Ano | Internações elegíveis, residentes PB | Internações elegíveis no serviço PB | POP PB anual | T24 PB de referência (por 1.000, estático) |
|---|---:|---:|---:|---:|
| 2017 | 182.069 | 183.532 | 4.025.558 | 45,22826401 |
| 2018 | 181.673 | 183.311 | 3.996.496 | 45,45807127 |
| 2019 | 186.280 | 188.246 | 4.018.127 | 46,35990848 |

**Regional, João Pessoa + Campina Grande:** F3 reporta POP 1.221.930/1.207.795/1.218.746 e numeradores RES 62.624/61.616/63.279 (2017–2019). Somar componentes e depois dividir; nunca média simples de taxas municipais. **Estes são oráculos estáticos**, não resultados de T24 no QlikView.

**Cobertura LT observada:** F2 reporta 3.561 município×competência com linha, 4.467 ausentes da grade 223×36, 97 com `QT_SUS=0` observado; ter 36 arquivos não prova cobertura no recorte. Entre pares município de serviço×ano com internações elegíveis, 184/184 têm 12 meses LT com linha, **sem provar cobertura hospitalar ou zero real**. O universo estritamente hospitalar requer decisão e documentação CNES por competência.

## 4. Matriz mínima VIII-A: cenário → oráculo → expressão/guarda candidata → expectativa

`CALC_CAND` = candidato quando as outras guardas passam; `COND` = falta evidência de cobertura/escopo ou contrato de recorte; `UNAVAILABLE` = não renderizar taxa; `BLOCKED` = gate físico ou prevenção não demonstrados. Não há PASS físico.

| ID | Cenário | Oráculo e expressão/guarda candidata | Expectativa |
|---|---|---|---|
| S01 | T24 PB 2017, ano único | F1 RES + F3 POP; E24 | CALC_CAND |
| S02 | T24 PB 2018/2019 em linhas separadas | F1/F3 por ano; nunca somar POP entre anos | CALC_CAND |
| S03 | T24 João Pessoa+Campina Grande 2018 | F3 componentes somados antes da razão | CALC_CAND |
| S04 | T24 residente fora da PB | F1 externo, sem POP PB; `POP_MISSING` | UNAVAILABLE |
| S05 | T25 município×ano com 12 meses LT com linhas | F2 mensal + F3 POP; média mensal primeiro | COND, cobertura não provada |
| S06 | T26 município×ano com RD e LT observados | F1 SERV + F2 mensal; janelas iguais | COND, escopo não provado |
| S07 | Mês único no ano | F1/F2 mês, F3 POP anual; `PARTIAL_WINDOW` | T24 candidato; T25/26 COND |
| S08 | Dois meses descontínuos do mesmo ano | F1/F2 apenas meses escolhidos; listar competências | T24 candidato; T25/26 COND |
| S09 | KPI único, anos múltiplos | `MULTI_YEAR` | UNAVAILABLE |
| S10 | KPI sem ano/competência inequívoca | `NO_REFERENCE_PERIOD` | UNAVAILABLE |
| S11 | Ano 2019 selecionado com competência 201809 | `D2_PRE_DISPATCH_CONFLICT` antes de alterar seleção | BLOCKED até mecanismo físico |
| S12 | Série dimensionada por ano sem seleção explícita | Oráculos ano a ano separados | T24 candidato; T25/26 COND |
| S13 | LT presente, quantidade SUS observada zero | F2 zero observado; exigir `ZERO_COVERAGE_VERIFIED` | COND |
| S14 | Município×mês sem linha LT | F2 grade municipal; `LT_ABSENT` | UNAVAILABLE |
| S15 | POP/denominador nulo, zero, negativo ou inválido | Guarda de domínio; sem `RangeSum` ocultando nulo | UNAVAILABLE |
| S16 | Município de serviço selecionado em T24 | P5 RES × serviço = B | UNAVAILABLE |
| S17 | Município de residência em T25/T26 | P5 LEI/REL × residência = B | UNAVAILABLE |
| S18 | Procedimento/diagnóstico/caráter/motivo em T26 | P5 REL = B | UNAVAILABLE |
| S19 | Tipo/código de leito em T26 | P5 REL = B | UNAVAILABLE |
| S20 | Tipo de leito em T24/T25 | P5 I em RES, R em LEI | COND: isolamento/recorte próprio, não KPI geral |
| S21 | CNES, PROC, diagnóstico, datas clínicas em KPIs gerais | P5 R/I/B segundo indicador; avisos e contrato específico | UNAVAILABLE no KPI geral sem contrato |
| S22 | Combinações C+B, R+I e C+C | F4 P5: 8 pares históricos (wrapper, não objeto) | BLOCKED até enforcement real |
| S23 | T25/T26 para região PB inteira | F2 223×36; faltas municipais | UNAVAILABLE como cobertura completa |
| S24 | Integridade física do ensaio | Manifestos dos 22 QVDs e QVWs; 16 tabelas; SHA pré/pós | BLOCKED: sem Windows/Qlik/baseline na sessão |

A política P5 integral deve ser consumida **diretamente** de [V2 §62.6](phase-6-semantic-v2-approved-2026-10-14.md). Estados: C = compatível condicionado; R = exige análise distinta contratada; I = isolamento explícito e aviso com prova física, senão indisponível; B = bloquear KPI. Seleções simultâneas não revogam bloqueios. F4 histórico verificou 48 singles e 8 pares **no wrapper**, sem enforcement de objeto final.

## 5. Gates, riscos e drifts

| Bloqueio/risco | Evidência atual | Próxima prova/decisão |
|---|---|---|
| Ambiente físico indisponível nesta sessão | Sem Windows/QlikView 12 e sem acesso aos 22 binários locais | Responsável executar preflight local após scripts versionados |
| Escopo T25/T26 não homologado | `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; R3 encontrou tipos TP_UNID entre LT, mas não vigência/classificação aprovada | Decidir se ensaio pode rotular `universo CNES/LT observado, sem suficiência hospitalar`, mantendo KPI geral indisponível quando cobertura não comprovada, **ou** aguardar classificação histórica |
| `LINK_KEY_CONTRACT=NOT_APPROVED` | Fase VII prova associação estrutural, não seleção e valores sob todos os papéis | Comparação Qlik por seleção contra F1/F2/F3 |
| `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED` | Nenhum T24–T26 fisicamente reconciliado | Oráculos, unidades e tolerância fixada antes da recarga |
| `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY` | Regras somente wrapper COM em provas anteriores | Condições de cálculo, estados de indisponibilidade e filtros combinados reais |
| D2 ano×competência | E14/E15 observaram seleção contraditória descartada | Prevenir antes do despacho, e não simplesmente limpar por Set Analysis |
| POP sob seleção mensal | VI-P2 reportou perda associativa | Recuperação física testada sem multiplicar população/descartar intenção |
| `T29_HISTORICAL=NOT_APPROVED` | Legendas históricas ausentes para maioria dos pares-mês | Não usar descrição como validade histórica |
| Metadado `current-state.md` | SHA pós-#106 enquanto HEAD contém #107 | Atualizar somente após eventual merge documental autorizado |

**Não há drift estrutural comprovado no código revisado**, o que não equivale a auditoria dos QVDs físicos. PR #90 permanece independente e Draft; não é motivo para repetir preflight concluído.

## 6. Encerramento, STOP e próxima sequência mínima

1. **VIII-A concluída em revisão estática**: matriz S01–S24 e oráculos O24–O26 são candidatos documentados; nenhum KPI foi executado no QlikView.
2. **STOP antes de VIII-B:** fechar a decisão sobre apresentação/escopo LT de T25/T26, confirmar acesso no Windows ao clone atualizado, 22 QVDs, QlikView Desktop 12/COM e manifestos F1/F2/F3. Sem isso, manter `BLOCKED`; não simular PASS remoto.
3. Após gate liberado e autorização delimitada, criar **branch de implementação separada** e commitar QVS/PS1/Python previamente à execução. Preferir adaptações mínimas do carregador e executor VII. Não copiar automaticamente o PR #83.
4. Executar uma única sessão controlada: SHA dos 22 QVDs e QVWs canônicos; QVW novo em `%TEMP%`; QlikView 12 com log nativo; guardas P5/D2 e cálculos por seleção; reconciliação independente; SHA pré/pós, 16 tabelas, zero `$Syn`/loops. Sem `STORE` ou CREATE, sem sobrescrever `LINK_ANALISE.qvd`.
5. **STOP em `PASS_LOCAL_CANDIDATE_ONLY` para cenários comprovados ou `BLOCKED/INCONCLUSIVE`**, com hashes, logs e matriz. Não promover contratos globais, nem atualizar `current-state.md` na main sem integração documental específica. Não mergear automaticamente nem iniciar Fase IX.

**Veredito persistido:** `VIII_A=DISCOVERY_STATIC_COMPLETED_WITH_GAPS`; `VIII_B=BLOCKED`; `T24_T26=NOT_RECONCILED`; `PRODUCTION_APPROVED=False`.
