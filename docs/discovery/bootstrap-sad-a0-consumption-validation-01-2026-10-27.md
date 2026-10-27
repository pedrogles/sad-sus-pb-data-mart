# Bootstrap — SAD-A0-CONSUMPTION-VALIDATION-01 (apenas handoff documental)

**Estado:** DOCUMENTATION_PREPARED_ONLY; EXECUTION_NOT_AUTHORIZED; NO_CODE_AUTHORIZATION.  
**Preparação aprovada:** 27/10/2026, somente documentação de P1.2, P2.2 e P3.1. A utilização deste bootstrap **não** equivale a autorização para implementar scripts, executar QlikView/COM, criar QVW, recarregar dados, editar QVD/QVW ou fazer merge.  
**Contrato principal:** [sad-a0-consumption-validation-01-preparation-2026-10-27.md](sad-a0-consumption-validation-01-preparation-2026-10-27.md).  
**Baseline da preparação:** main@db5d6e6e23371422ca1d2d77a8576150aaf63d03. A branch/PR de preparação é Draft e precisa ser inspecionada novamente antes de qualquer passo futuro.

## Roteamento do gate

- **Agente primário atual:** ChatGPT GPT-6 + GitHub; esforço sem seleção explícita; ambiente remoto documental.
- **Fallback futuro de execução:** Codex Local/operador no Windows com QlikView 12, **somente depois de autorização adicional e evidência ambiental verificável**. Work Cloud não implica acesso ao host local.
- **Fonte de verdade:** na main, consultar nesta ordem AGENTS.md → docs/project/current-state.md → docs/academic/requirements.md → docs/project/agent-model-routing.md; então Boundary 5, Boundary 6, Boundary 7, V2 §62, Fase VII, PR #160/Issue #161 (AE01) e PR #162 (Draft), Issue #157 e contrato principal deste bootstrap.
- **Ambiente atual:** GitHub documental. Windows/QlikView/COM/GUI não acessados; RUNTIME_TEMP e EVIDENCE_ROOT: não aplicáveis à preparação.
- **Permissão atual:** consulta a fontes e preparação/revisão apenas dos dois documentos Markdown na branch separada. Não há autorização de alteração de main, scripts, QVD, QVW, modelo, PRs alheios ou evidência física.
- **Escopo candidato exclusivo:** P1.2 série mensal de novas internações SIH; P2.2 snapshots mensais CNES/LT observados; P3.1 matriz de novas internações RES→SERV no SIH.
- **STOP do preparo:** PR Draft só Markdown, contrato e bootstrap completos; nenhum teste físico.
- **Escalonamento:** se fontes, hashes ou associações forem divergentes, registrar BLOCKED/INCONCLUSIVE e pedir decisão restrita; não ajustar modelagem nem repetir testes por inferência.

## Contrato de leitura e aceite documental

| Caso | Fonte do valor Qlik (futura) | Oráculo independente já obtido | Verificações futuras estritas |
| --- | --- | --- | --- |
| P1.2 | FATO_INTERNACAO.QTD_INTERNACAO por PERIODO_COMPETENCIA | E1 de AE01, 36 competências | igualdade mês a mês; IDENT=5 não cria nova internação; 555.089 total apenas checksum |
| P2.2 | FATO_CAPACIDADE_LEITO.QTD_LEITOS_EXISTENTES, QTD_LEITOS_SUS e QTD_LEITOS_NAO_SUS por PERIODO_COMPETENCIA | E4 de AE01, 36 competências | igualdade mês a mês; snapshot, não soma anual; ausência distinta de zero; somente CNES/LT observado |
| P3.1 | FATO_INTERNACAO.QTD_INTERNACAO por RES_COD_DATASUS_6 × SERV_COD_DATASUS_6, em 2018 | E1 de AE01; pilotos C3-B1 e C3-B2 restritos | pares e filtros corretos; sem fan-out, POP/LT denominador, taxa ou inferência de viagem |

**Fato conferido:** o QVS técnico Fase VII usa LINK_ANALISE, aliases por papéis e 3 fatos, com %LINK_KEY entre fatos e Link. Os campos naturais dos CSVs AE01 não podem ser presumidos nas fatos materializadas. Um piloto P3.1 não homologa LINK_KEY_CONTRACT global.

## Próximas ações possíveis — exigem decisões distintas

1. **Revisão deste PR documental Draft** por responsável, sem merge automático.
2. Se houver intenção de executar os três casos: solicitar **autorização específica de desenvolvimento/versionamento** do executor e especificar oráculos selecionados, branch/commit, pré-condições e testes estáticos. Nenhum script foi preparado aqui.
3. Após revisão de código e ambiente: obter **autorização física expressa separada** para uma tentativa em Windows/QlikView 12, com QVW descartável, logs contemporâneos, SHA-256 dos 22 QVDs, três QVWs e crosswalk antes/depois, EVIDENCE_ROOT persistente fora de Git/TEMP e STOP sem retry automático.
4. Com PASS restrito, ainda não promover contratos globais nem avançar à Fase IX. G1/Issue #157 continua independente e necessário a T25/T26.

**Saídas válidas agora:** DOCUMENTATION_PREPARED_ONLY / BLOCKED_DOCUMENTATION / INCONCLUSIVE_DOCUMENTATION.  
**Não declarar:** PASS_QV, LINK_KEY_APPROVED, MEASURES_APPROVED, P5_D2_APPROVED, G1_RESOLVED, PHASE_IX_AUTHORIZED ou PROD_APPROVED.
