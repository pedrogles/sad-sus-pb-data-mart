# BOOTSTRAP — SAD SUS PB | Fase VIII — Discovery e execução controlada de indicadores

**Data-base:** 18/10/2026  
**Repositório canônico:** `pedrogles/sad-sus-pb-data-mart`  
**Ponto de partida confirmado:** `main@875a7b72ff1ba87dfc49b55472b8e1e058837cbb` (merge do PR #106; consultar o HEAD real antes de qualquer ação).  
**Novo chat recomendado:** Fase VIII — indicadores QlikView 12, T24–T26.  
**Natureza:** bootstrap operacional, não script executável, homologação ou autorização de produção.

## 0. Instrução de partida no novo chat

Você está trabalhando no projeto acadêmico SAD — Data Mart SUS PB. Execute a **Fase VIII — Indicadores**, na ordem de Boundary 7, começando por **DISCOVERY estritamente READ-ONLY** e continuando, somente após gates explícitos, a uma **implementação e validação isoladas no QlikView 12**. O responsável aprovou a conclusão controlada da Fase VII e solicitou este plano para a Fase VIII; isso **não** promove contratos pendentes a aprovados, não autoriza modificar QVD/QVW original ou iniciar Fase IX. Evite redescoberta extensa e reutilize evidências já obtidas.

Antes de agir, consulte **na `main` vigente**, nesta ordem:
1. `AGENTS.md`;
2. `docs/project/current-state.md`;
3. `docs/academic/requirements.md`;
4. `docs/discovery/boundary-7-implementation-plan.md`;
5. `docs/discovery/boundary-6-qlikview-physical-architecture.md`;
6. `docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md`;
7. `docs/discovery/phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md`;
8. `docs/discovery/phase-7-technical-panel-controlled-gate-2026-10-18.md`;
9. `docs/project/qlikview-powershell-automation.md`, `PAINEL/phase_vii_technical_model.qvs` e demais QVS/PS1 relevantes;
10. materiais oficiais do professor, quando necessário à interpretação dos indicadores.

Em conflito, respeite **material oficial do professor > fontes oficiais DATASUS/CNES/IBGE > dados inspecionados > documentação canônica atual > histórico e chat**. Confirmar branch, SHA, PRs pendentes e drifts antes de propor alterações. Tratar menções antigas a `FACT_QVDS=NOT_STARTED` ou `PAINEL=NOT_STARTED` nos registros cronológicos da V2 como históricos, e não como estado operacional atual.

## 1. Situação herdada, com nível de prova

- **QlikView 12 obrigatório**, cadeia `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`.
- **Modelagem acadêmica imutável:** Star Schema por fato, constelação com `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO` e oito dimensões aprovadas; capítulos 1–2 já entregues (avaliação pendente).
- **Fatos físicos reportados:** 566.672 registros RD; 35.518 LT; 669 POP = 223 municípios PB × três anos, 2017–2019.
- **`LINK_ANALISE.qvd`:** 85.705 links, 6 campos; CREATE/READBACK local reportado na Fase VI, sem homologação semântica definitiva.
- **Fase VII:** PR #106 integrado no commit `875a7b72ff1ba87dfc49b55472b8e1e058837cbb`; script de teste em `PAINEL/phase_vii_technical_model.qvs`, runner `tools/Invoke-SadPhaseViiTechnicalPanel.ps1`. Inventário 22 QVDs e reload isolado foram reportados PASS. Captura do Table Viewer inspecionada: 16 tabelas, 15 associações, sem `$Syn` ou circular reference visível. Estado **`GATE_PASS_CANDIDATE_ONLY`**, sem reexecutar T17–T23 sem gatilho.
- **Preservar como pendente:** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PRODUCTION_APPROVED=False`.
- A aprovação de V2 em 14/10 é **semântica**, não aprovação de fórmulas finais, seleções COM, denominadores físicos, associação sob todos os filtros ou UI.
- **Importante:** `PAINEL/painel_main.qvs` não foi modificado na Fase VII; o QVW testado foi descartável. Ainda não existe dashboard final homologado.

## 2. Objetivo fechado da Fase VIII

Definir, implementar **somente em QVW de teste descartável** e reconciliar **T24–T26** conforme a V2, incluindo regras de temporalidade, território, cobertura, filtros e indisponibilidade; obter evidência numérica independente das expressões QlikView.

Indicadores:
- **T24 — Internações de residentes/1.000 habitantes:** `SUM(QTD_INTERNACAO)` dos atendimentos SIH/RD processados na PB / população anual do **município de residência** × 1.000. `IDENT=5` não conta como internação nova; `QTD_REGISTRO_AIH` não substitui `QTD_INTERNACAO`. Há residentes externos PB que não possuem denominador POP PB.
- **T25 — Leitos SUS/1.000 habitantes:** média, no período compatível, dos **totais mensais** de `QTD_LEITOS_SUS` do **município de serviço** / população anual desse município × 1.000. Nunca usar soma de snapshots como capacidade anual.
- **T26 — Internações/leito SUS médio:** internações processadas no período no município de **serviço** / capacidade SUS média mensal válida no mesmo território e janela. **Não é taxa de ocupação**.
- **Fluxo residência → serviço** é análise de contagens, sem denominador POP implícito. Não fabricar um T24–T26 adicional, se isso exceder objetivo.

A implementação deve preservar **dados, lógica e grãos existentes**, sem transformar fatos ou alterar a arquitetura associativa da Fase VII. Não criar novos QVDs. Não abrir Fase IX nem os três painéis OLAP nesta fase.

## 3. Regras V2 obrigatórias na reconciliação

### Tempo
1. Principal período é a **competência administrativa SIH/RD**, não `DT_INTER` nem `DT_SAIDA`.
2. Indicador anual só com **ano único e cobertura válida**; 12 competências válidas para média anual completa de leitos. Competências parciais devem ser explicitamente apresentadas como razão parcial com **POP anual**, sem anualização. Meses descontínuos devem ser identificados.
3. KPI anual com dois ou mais anos misturados ou ano indefinido é **indisponível**; série por ano pode calcular anos separadamente.
4. Seleções contraditórias de ano/competência devem ser **prevenidas antes** de descartar a intenção do usuário. Um Set Analysis que elimina filtro silenciosamente não resolve automaticamente o contrato.
5. POP anual não deve sumir semanticamente nem ser multiplicada por competência. VI-P2 identificou incompatibilidade de POP diretamente associada ao filtro mensal; qualquer recuperação física deve ser testada com Set Analysis e oráculo independente.

### Município e agregação
- RES usa município de **residência**; LEI e REL, município de **serviço**. A seleção de um papel não é automaticamente compatível com o outro.
- Para região, agregar componentes territoriais compatíveis antes de calcular a razão; contar POP **uma vez por município/ano**.
- As 5.202 linhas de residentes externos PB não recebem população municipal PB inventada.

### Cobertura/indisponibilidade
- Diferenciar: valor observado, **zero comprovado**, ausência de linha sem zero comprovado, erro técnico e exclusão causada por filtro incompatível. Não converter ausências em `0`.
- CNES/LT: 36 arquivos válidos **não demonstram** cobertura por município/competência/escopo. VI-P4 encontrou 4.467 pares município-mês sem linha LT e 97 pares com soma SUS observada zero (resultados históricos locais reportados); não inferir completude.
- Denominador ausente, nulo, zero, negativo, sem evidência ou POP externa → **indisponível**, não divisão por zero nem preenchimento artificial.
- `T29_HISTORICAL=NOT_APPROVED`: rótulos de leito de 2019-09 não têm vigência histórica comprovada nos 36 meses; não aplicar retroativamente.
- Preservar todos os LT válidos; recorte hospitalar exige classificação histórica validada e não deve excluir linhas do QVD original.

### Política P5 — filtros C/R/I/B
Aplicar integralmente a matriz em `phase-6-semantic-v2-approved-2026-10-14.md`:
- **C:** compatível, sob as demais condições.
- **R:** exige indicador/recorte específico com contrato próprio, não altera silenciosamente o KPI geral.
- **I:** não aplicável; isolamento explícito com aviso e validação física ou marcar indisponível.
- **B:** bloquear indicador geral nesse contexto.

Casos críticos: município de serviço **B** em RES; município de residência **B** em LEI/REL; procedimento/diagnóstico/caráter/motivo/datas clínicas **B** em REL; tipo de leito **B** em REL; dimensões exclusivas não redefinem medidas de outras fatos. Testar filtros **simultâneos**, não só isolados.

## 4. Execução por subgates (STOP entre escopos)

### VIII-A — Discovery READ-ONLY / contrato físico candidato
1. Conferir HEAD da `main`, estados do PR #106 e PR #90, `current-state.md`, V2, QVS e evidências da Fase VII. Reaproveitar provas existentes, sem rerun de `LINK_ANALISE`, T17–T23 ou CREATE.
2. Auditar em código os campos físicos, papéis, filtros, temporalidade, `Hash128` e limites existentes. Não inventar equivalências entre referência oficial, QVD e expressão.
3. Reaproveitar do PR #83 **somente como referência histórica** os experimentos VI-P2/P3 e protótipos de filtros/comandos COM. Não copiar scripts históricos para `main` nem promover PASS experimental sem nova revisão.
4. Elaborar um contrato candidato de **oráculos independentes** para T24, T25 e T26, e a menor matriz que cubra: município/ano completo, parcial, descontínuo, multi-ano, sem período, seleção conflitante ano×competência, dois papéis municipais, residentes externos, cobertura LT ausente, zero observado, denominador inválido, P5 C/R/I/B, filtros combinados e agregado regional.
5. Registrar quais cenários são **calculáveis**, quais devem permanecer **indisponíveis** e quais dependem de evidência de cobertura não existente. Não aprovar indicadores gerais em universo incerto.
6. **STOP Discovery:** entregar matriz `CENÁRIO → ORÁCULO → EXPRESSÃO CANDIDATA → STATUS/GAP`, bloqueios reais, sequência experimental mínima, previsão de artefatos. Se houver drift material ou contrato físico impossível, **BLOCKED** e submeter decisão antes da implementação; não reinterpretar V2 por conveniência.

### VIII-B — Implementação de ensaio isolado e controlado
**Após VIII-A** e desde que não exista bloqueio semântico/arquitetural, e respeitando autorização delimitada do responsável:
1. Criar **branch própria de Fase VIII** partindo da `main` congelada; objetivo único, sem merge automático.
2. Versionar **antes de executar** todos os novos QVS/PS1/Python que fundamentarão o gate. Preferir reutilização e pequenas adaptações dos executores da `main`; scripts do PR #83 exigem qualificação explícita.
3. Construir QVW **novo e descartável sob `%TEMP%`**, com modelo de Fase VII e expressões de indicadores testáveis. Não modificar nem recarregar `PAINEL/PAINEL.qvw`, `TRANSFORMACAO/TRANSF.qvw`, `PAINEL/painel_main.qvs`, os 22 QVDs ou brutos. Não sobrescrever evidências históricas.
4. Rodar **primeiro** inventário QVD read-only de 22 arquivos e SHA-256; **depois** uma execução QlikView 12 controlada do teste autorizado. Capturar commit dos scripts, seus SHA-256, comandos, stdout, log nativo, QVW TEMP e manifestos pré/pós.
5. Reconciliar valores QlikView **com oráculos independentes por seleção e granularidade**. O oráculo não pode ser somente a mesma fórmula avaliada duas vezes ou um agregado já produzido pelo KPI. T24/T25/T26 devem coincidir dentro de tolerância previamente especificada, justificando arredondamento/unidades.
6. Verificar que filtros incompatíveis, conflito ano×competência, POP anual e ausência CNES geram o estado aprovado pela V2, sem zero/denominador inventado. Testes COM, propriedades ou screenshots não substituem concordância numérica e interpretação.
7. Revalidar que o modelo técnico ainda possui 16 tabelas, sem synthetic keys/loops, preservando contagens e os hashes QVD/QVW originais.
8. **STOP execução:** `PASS_LOCAL_CANDIDATE_ONLY` ou `BLOCKED/INCONCLUSIVE` documentado, sem repetir automaticamente falhas e sem promover `MEASURES_AND_DENOMINATOR_CONTRACT` a `APPROVED` antes da revisão de evidências.

### VIII-C — Revisão, fechamento documental e próxima decisão
- Conferir código versionado, logs, matriz de resultados, oráculos e evidência visual real se forem criados objetos técnicos. Diferenciar **PASS local reportado** de auditoria independente.
- Fechar somente T24–T26, o subconjunto de filtros/anos/municípios comprovado, e ressalvas. Não afirmar cobertura generalizada a partir de um piloto.
- Documentar em `docs/discovery/` com links/SHAs; atualizar `docs/project/current-state.md` **somente após integração documental/autorização de merge específica**.
- Permanecendo contratos pendentes, manter `NOT_APPROVED` e indicar exatamente o teste ou decisão necessária, sem iniciar Fase IX.
- A **Fase IX — Dashboards** exige gate próprio posterior à reconciliação dos indicadores, conforme Boundary 7.

## 5. Critérios de aceite explícitos

| Teste/Gate | PASS requerido |
| --- | --- |
| Baseline de entrada | 22 QVDs presentes; SHA dos originais preservado; PR #106 merged; modelagem de 3 fatos/8 dimensões intacta |
| T24 | Concordância numérica e semântica (residência, QTD_INTERNACAO, POP anual, 1.000) para cenários contratados |
| T25 | Média de totais mensais válidos/POP anual, com temporalidade e disponibilidade corretas |
| T26 | Internações no serviço/média de leitos SUS do mesmo território/período; legenda **não taxa de ocupação** |
| P5 | C/R/I/B respeitado por indicador sob filtros únicos e combinados; estados indisponíveis explícitos |
| Temporalidade | Ano único, parcial, descontínuo, multi-ano e conflito de seleções tratados conforme V2 |
| Semântica de cobertura | Não converter sem LT/sem POP em zero; relatórios de motivos de indisponibilidade |
| Integridade | Nenhuma escrita a QVD/QVW original, nenhuma nova `$Syn` ou loop; evidência reprodutível por commit/log |
| Encerramento | PASS restrito ou BLOCKED com rastreabilidade; sem merge ou produção automáticos |

## 6. Invariantes e bloqueios de governança

**NÃO:** reabrir Capítulos 1–2, substituir QlikView 12, mudar fatos/grãos/dimensões, gerar leitos/população mensais fictícios, usar `N_AIH` como PK, chamar internações/leito de ocupação, projetar classificação CNES histórica não validada, sobrescrever `LINK_ANALISE.qvd`, atualizar `PAINEL/painel_main.qvs` sem autorização independente, executar scripts não versionados para sustentar PASS, mergear automaticamente, iniciar Fase IX.

**PONTO DE CONTROLE:** o gate VII técnico passou como candidato e **não aprovou fisicamente** o significado e a associação de cada indicador. `LINK_KEY_CONTRACT=NOT_APPROVED` exige teste específico de propagação e valores sob seleção; não presumir `LINK_KEY_CONTRACT=APPROVED` pelo Table Viewer isolado.

## 7. Entrega esperada no novo chat

O assistente deve:
1. identificar o HEAD vigente e eventuais drifts reais, sem redescobrir todo o Data Mart;
2. realizar VIII-A READ-ONLY e produzir contrato físico candidato e matriz de T24–T26;
3. executar VIII-B **somente se** os bloqueios forem resolvidos, com código commitado e QVW temporário, respeitando a autorização correspondente;
4. analisar evidências; parar em PASS restrito ou BLOCKED;
5. documentar os resultados, atualizar a fonte de verdade quando autorizado e **não** iniciar dashboards/Fase IX automaticamente.

**Comando de abertura sugerido do chat:** “Execute a Fase VIII do SAD conforme este bootstrap, começando pela Discovery READ-ONLY, preservando os contratos V2, a Fase VII integrada e os gates de autorização. Não faça merge automático nem altere QVD/QVW original.”
