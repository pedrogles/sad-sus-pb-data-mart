# SAD — Desenvolvimento restrito dos executores A0 (27/10/2026)

**Gate:** SAD-A0-CONSUMPTION-EXECUTORS-DEV-01  
**Status:** DEVELOPMENT_VERSIONED_STATIC_REVIEW_ONLY / PHYSICAL_NOT_RUN / EXECUTION_NOT_AUTHORIZED.  
**Autorização:** em 27/10/2026, o responsável encerrou a revisão do PR #163 e autorizou apenas o desenvolvimento e versionamento de executores para P1.2, P2.2 e P3.1; execução Windows/QlikView 12/COM e merge dependem de novas decisões expressas.  
**Baseline da main:** db5d6e6e23371422ca1d2d77a8576150aaf63d03. PR #163 OPEN/DRAFT não modificado nem integrado. PR #162 (discovery A0) e PR #160 (AE01) igualmente Draft na entrada.

## 1. Objetivo, fontes e encerramento

Desenvolver sem executar a preparação de três provas numéricas sobre a arquitetura A0, reutilizando PAINEL/phase_vii_technical_model.qvs da main e extratos E1/E4 auditados na Issue #161.

- **P1.2:** 36 somas mensais da medida QTD_INTERNACAO da FATO_INTERNACAO versus E1; competência administrativa de 201701 a 201912, IDENT=5 excluído como nova internação.
- **P2.2:** 36 competências × 3 medidas da FATO_CAPACIDADE_LEITO (existentes/SUS/não SUS), comparadas com E4. Três medidas do **mesmo snapshot mensal por competência**; não acumular snapshots em uma capacidade anual nem imputar ausência como zero.
- **P3.1:** dois pares da matriz administrativa RES→SERV para 2018, contra E1 e C3-B1/B2: (250180,250750)=3.806 e (250750,250750)=39.060. **Somente amostras**, não prova da matriz global.

Fontes verificadas em ordem: AGENTS.md; docs/project/current-state.md; docs/academic/requirements.md; docs/project/agent-model-routing.md. Complementos: Boundaries 5/6/7; V2 §62; automação PowerShell; QVS das duas fatos e técnico da Fase VII; PR #163 contrato documental; PR #160 E1/E4 e Issue #161; C3-B1/B2; G1/Issue #157.

**Invariantes:** Star/constelação e três fatos/oito dimensões; 22 QVDs (10+12), três QVWs canônicos e crosswalk C5.2 protegidos; nenhuma nova fato, QVD, join, campo associativo, alteração de RN21/V2, capítulos 1–2, Link Key, T24/T25/T26, Fase IX ou produção. POP não compõe nenhuma das três medidas. G1 #157 permanece independente e aberto.

**STOP:** somente código, testes sintéticos e documentação versionados em PR Draft próprio; não executar QlikView ou criar QVW neste gate.

## 2. Artefatos entregues

| Arquivo | Papel |
| --- | --- |
| tools/prepare_sad_a0_consumption_oracle01.py | Lê E1/E4 somente com SHA-256 e schemas pinados do AE01; valida períodos, unicidade de agregados e controles globais; prepara **um JSON novo** com 36 + 108 + 2 expectativas, sem tocar QVD/QVW. |
| tools/Invoke-SadA0ConsumptionValidation01.ps1 | Orquestrador **de execução futura ainda não autorizada**: exige -RunQlik, -ExpectedCommit SHA40 em branch não-main e -ExecutionAuthorizationRef, scripts rastreados/limpos, hashes da fonte; reutiliza QVS técnico Fase VII, cria QVW descartável, recarrega e compara 146 valores via Evaluate; nunca grava QVD/canônico. |
| tools/test_sad_a0_consumption_oracle01.py | Testes unitários sintéticos offline para domínio, inteiros, BOM/header e rejeição de hash divergente; versionados, **não executados nesta sessão**. |
| Este documento | Fronteira das permissões, critérios e handoff. |

As colunas E1/E4 são **oráculos externos**, nunca tabelas adicionais carregadas no modelo. O QVS Fase VII permanece inalterado e suas coordenadas por papel passam pela LINK_ANALISE. As expressões usam seleção neutra de QVW novo; para P3.1 os recortes de 2018/RES/SERV são condições Set Analysis, não prova de UI, D2/P5 ou contrato global da Link Key.

## 3. Proteções e evidência futura (não executada)

Para uma **execução física posteriormente autorizada**, o executor requer checkout no commit aprovado, Windows/QlikView Desktop 12, Python 3, arquivos QVD/QVW/crosswalk e os E1/E4 físicos da tentativa AE01 02. EvidenceRoot será pasta ainda inexistente sob diretório persistente **fora** de repo/TEMP/AE01; QVW descartável fica em TEMP. -ExecutionAuthorizationRef apenas identifica a aprovação humana: **não valida permissão automaticamente**.

Preflight proposto: 10+12 QVDs, três QVWs canônicos, crosswalk e E1/E4; SHA E1 F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615; E4 BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88; Link QVD com SHA congelado. Todos os artefatos protegidos têm inventário SHA-256 pré/pós. O runner somente escreve arquivos de evidência novos (a0_oracle.json, qlik_reload.log, qlik_evaluations.json, execution_metadata.json, protected_before.json e protected_after.json) e QVW TEMP.

Uma futura validação poderá gerar PASS_LOCAL_CANDIDATE_ONLY **apenas se**: recarga técnica Fase VII reconciliada, 36 P1.2, 108 P2.2 e dois pares P3.1 iguais a E1/E4, logs contemporâneos, SHA pré/pós invariantes, commit/identidade rastreáveis. Isso **não** é homologação de visual, filtros globais, G1 ou produção.

Qualquer desvio de fontes, scripts, hashes, QlikView/COM, saída inesperada, ausência de oráculo ou log encerra em BLOCKED/INCONCLUSIVE/HARD_STOP, sem retries automáticos. Um resultado de COM/Evaluate não prova o comportamento de seleção interativa nem apresentação dos 15 visuais.

## 4. Estado e handoff

- DEVELOPMENT_VERSIONED_STATIC_REVIEW_ONLY: scripts e contrato em PR; inspeção estática, **sem alegar testes locais executados**.
- STATIC_TEST_PASS: **não declarado** até executar e registrar testes offline no commit efetivo.
- PHYSICAL_NOT_RUN / QLIKVIEW_NOT_TESTED; LINK_KEY_CONTRACT=NOT_APPROVED; MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; P5_D2_UI=NOT_TESTED_GLOBAL; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False.
- Issue #157 / G1 T25/T26 permanece aberta, separada e necessária.

**Próxima decisão do responsável:** revisão do PR de executores e eventuais correções versionadas. Aprovação documental/do desenvolvimento, commit ou merge **não autorizam** executar QlikView. A execução física exigirá aprovação independente, com commit, host, escopo e pasta de evidências definidos. Nenhum trabalho de Fase IX começa por decorrência.
