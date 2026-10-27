# BOOTSTRAP — SAD SUS PB | EXTRATOS-ANALITICOS-READONLY-01

Você está no projeto acadêmico **SAD — Data Mart SUS PB**, repositório canônico `pedrogles/sad-sus-pb-data-mart`. Implementação acadêmica **obrigatória no QlikView 12**.

## 0. Autoridade e baseline

**Direcionamento aprovado pelo responsável em 27/10/2026:** começar pela suficiência de análises reais dos datasets já disponíveis para três painéis candidatos; T25/T26/escopo hospitalar deixam de ser dependência *universal* para análises SIH/RD e CNES/LT observacionais independentes.

**Baseline anterior:** `main@9f4fc0ea43dfe8b6f20f7b6254bc7f965f6a9c04`. **Revalidar HEAD** e conferir se o PR documental da branch `docs/analytical-sufficiency-direction-20261027` foi integrado. Se ainda Draft, tratar documentos da branch como proposta e a decisão aprovada no chat como orientação, **sem presumir alteração na main**.

**Leitura obrigatória, nesta ordem, na `main`:**
1. `AGENTS.md`
2. `docs/project/current-state.md`
3. `docs/academic/requirements.md`
4. `docs/project/agent-model-routing.md`
5. `docs/academic/chapter-1-2-modeling.md`
6. `docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md`
7. `docs/discovery/boundary-7-implementation-plan.md`
8. `docs/project/final-delivery-critical-path.md`
9. Quando integrados, ou **na branch proposta com status expresso**:
   - `docs/project/analytical-direction-2026-10-27.md`
   - `docs/discovery/analytical-question-inventory-2026-10-27.md`
   - `docs/discovery/analytical-sufficiency-plan-2026-10-27.md`
10. Evidências físicas históricas: FATO_INTERNACAO, FATO_CAPACIDADE_LEITO, FATO_POPULACAO Fase V; C3-B1/C3-B2 e C4-F somente conforme a necessidade.

## 1. Objetivo único

Executar a **primeira avaliação de suficiência analítica dos dados existentes**, sem implementar dashboards: determinar, com evidência real ou ausência expressa dela, quais das 12 perguntas do inventário sustentam os 3 painéis propostos (P1 produção hospitalar, P2 leitos observados, P3 fluxos territoriais).

**STOP:** entregar 12 resultados classificados, 3 especificações revisadas (3–5 visuais por painel), até 3 lacunas prioritárias e um handoff de extrato somente leitura se algum dado físico for inacessível.

## 2. Invariantes

- 2017–2019; QlikView 12; `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`.
- Star Schema por fato/constelação; três fatos e oito dimensões aprovadas; Capítulos 1–2 entregues em 13/10/2026 sem reabertura.
- `IDENT=5`: continuidade, `QTD_INTERNACAO=0`; `N_AIH` não é PK; papéis RES/SERV distintos; pacientes/episódios únicos não comprovados.
- Leitos e população semi-aditivos no tempo; ausência LT ≠ zero; média de leitos requer competência/cobertura apropriada; `internações/leito` não é taxa de ocupação.
- RN21 `LT_TODOS_REGISTROS_VALIDOS_RN21`; `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`.
- `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
- G1/Issue #157 continua aberta para **T25/T26 dependentes**, não confundir com aprovação dos painéis ou bloqueio universal para agregações de uma única fato.

## 3. O que já foi documentado (não repetir testes)

- SIH/RD: 566.672 registros, `QTD_INTERNACAO` 555.089, 11.583 continuidades; 2017=183.532; 2018=183.311; 2019=188.246; 3.133.578 dias; R$ 659.384.649,05 em valores administrativos; 26.611 óbitos — **PASS local reportado**, não auditoria atual do binário.
- CNES/LT: 35.518 registros em 36 competências; exportação C4-F `223×36=8.028` pares: 3.464 positivos, 97 zeros observados, 4.467 sem linha; **290/669** município×ano com 12 linhas mensais, não cobertura certificada.
- IBGE: 669 pares `223 municípios×3 anos`; população não somável entre anos.
- C3-B1/C3-B2: dois pilotos por pares R≠S e R=S (não aprovação global de Link Key); C4-B1 T25 restrito (não cobertura hospitalar).
- Origem: documentos canônicos indicados acima. **Não recalcular agregados globais já reconciliados apenas para gastar gate.**

## 4. Perguntas de avaliação e ordem de prioridade

**P1 Produção:** I01 evolução anual; I02 série mensal; I03 ranking SERV; I04 `PROC_REA`; I05 `DIAG_PRINC`; I06 permanência/valores; I07 óbitos.
**P2 Leitos observados:** I10 classe presença/zero/ausência por município×competência; I11 distribuição por competência, município, CNES e código.
**P3 Fluxos:** I08 R=S versus R≠S; I09 pares RES→SERV e residentes externos.
**Transversal condicionado:** I12 T24 RES por 1.000 habitantes, com POP anual e controles V2/associativos.

Para cada pergunta separar: `RESULTADO_JA_RECONCILIADO`, `CALCULAVEL_SEM_DADO_NOVO`, `CONDICIONADO_A_CONTRATO` ou `NAO_SUSTENTADO`; após análise numérica classificar **cada visual** como `SUSTENTADA`/`CONDICIONADA`/`NAO_SUSTENTADA`.

## 5. Procedimento de execução

1. Confirmar `main`, branch/PR e invariantes; obter e ler os documentos específicos. Não reconstruir cronologia.
2. Enumerar arquivos **de fato acessíveis** (QVDs, CSV/TXT de exportação, manifestos, evidência), hashes/schemas/grãos/escopo. Não presumir Windows local, Qlik COM ou QVDs por referência em docs.
3. Reusar imediatamente os valores comprovados nos casos documentados e apontar as diferenças de nível de prova.
4. Se houver exportações/QVDs legíveis em modo read-only já fornecidos, apurar I02–I05, I08–I09 e I11 com agregação, oráculos e rastreabilidade. `QT_SUS` nulo/sem linha nunca vira zero por padrão. Não criar ranking sem dados.
5. Se os dados não estiverem fisicamente acessíveis, **NÃO** baixar em massa nem rodar COM: definir **apenas uma especificação mínima** de exportação local das agregações em modo leitura, com script/commit necessários; classificar não extraído e encerrar.
6. Produzir matriz final, proposta revisada dos três painéis e handoff com divergências/bloqueios, sem implementação de QVW.

Não executar ou recriar VI-P4, C4-B1, C4-G, C2-J/K, T24/T25/T26 pilotos; não rodar scripts one-shot de materialização nem modificar `TRANSF.qvw`, `PAINEL.qvw`, os 22 QVDs ou a `main`. Todo script de gate eventualmente usado no Windows precisa ser **versionado antes** e ter autorização própria de execução; este bootstrap **não autoriza** COM/Reload/STORE.

## 6. Saída exigida

| ID | Pergunta | Fato/grão/recorte | Medidas e regra | Valor real (ou pendente) | Fonte/prova | Suficiência | Limitação | Visual/painel |
|---|---|---|---|---|---|---|---|---|

- Exatamente as 12 perguntas do inventário; se uma não puder ser medida, **deixar valor não extraído com razão concreta**.
- Para cada painel: objetivo; 3–5 visuais; filtros V2 compatíveis; resultados demonstrados; bloqueios de integração e interpretação.
- Até 3 obstáculos; exportação mínima necessária com fontes, schema e critério de aceitação se bloqueado; decisão de produto/escopo posterior.
- Estados finais: `ANALYTICAL_EVIDENCE_RECONCILED_RESTRICTED`, `DOCUMENTED_READONLY` ou `INCONCLUSIVE_WITH_LIMITS`. **Proibido** `G1_RESOLVED`, `GATE_PASS_GLOBAL`, `PHASE_IX_APPROVED` ou `PRODUCTION_APPROVED`.

## 7. Roteamento operacional do gate

- **ID / objetivo / STOP:** `EXTRATOS-ANALITICOS-READONLY-01`; 12 perguntas + 3 especificações + até 3 lacunas, sem extensão automática.
- **Fonte:** `main@SHA` revalidada; `AGENTS`, current-state, requirements, V2, Boundary 7; três docs novos em `main` se integrados ou branch/PR devidamente rotulada.
- **Integração:** verificar PR e commit reais; Draft ≠ main; nenhum código de execução presumido.
- **Agente primário:** ChatGPT + GitHub (revisão documental). Para dados locais autorizados, **Codex Local no Windows** ou operador humano, em gate separado.
- **Modelo/esforço efetivos:** registrar o rótulo mostrado no novo ambiente; preferência Medium quando disponível, sem inventar seletores/entitlements.
- **Fallback/escalonamento:** faltando dado físico, extrato mínimo e STOP; High/Work somente se divergência factual complexa realmente justificar; não usar Work só para inventário.
- **Ambiente:** cloud com acesso a conectores; **Windows/QlikView COM não presumidos**.
- **Permissões:** somente leitura de GitHub, documentos e arquivos anexados; cálculos independentes em cópias permitidas. **Zero escrita externa, alteração de branch, merge, QVD/QVW, COM, reload ou downloads em massa**.
- **Insumos:** 22 QVDs e 3 QVWs canônicos preservados localmente segundo relatos; não assumir que presentes no novo chat. Oráculos/exports indicados por documentação.
- **RUNTIME_TEMP / EVIDENCE_ROOT:** não aplicável ao gate documental; definir diretório persistente externo ao Git somente em futura execução local autorizada.
- **Orçamento:** 12 perguntas, 3 painéis, evidências selecionadas, zero COM, uma única proposta de extração local se necessária.
- **PASS documental:** matriz rastreável e declaração honesta de números não extraídos; **HARD_STOP:** mutação indevida/invariante violado; **RECOVERABLE_BLOCK:** extratos ausentes; **INCONCLUSIVE:** evidência ou binários insuficientes.
- **Prova:** inspeção estática e números reportados ≠ auditoria binária contemporânea; separar CI, execução local, reconciliação e aceite humano.
- **Handoff:** proposta para novo gate de exportação controlada se preciso, jamais aprovação silenciosa de G1/G2–G6.

**Princípio:** obter conhecimento descritivo confiável com os dados que já temos sem sacrificar rigor metodológico e sem transformar T25/T26 em bloqueio universal.
