# SAD SUS PB — Closeout P1.1/P1.2 e revisão de PRs #172–#177

**Gate:** `SAD-P11-P12-PR-CONSOLIDATION-2026-10-29`  
**Data:** 29/10/2026  
**Base verificada:** `main@92403e1a1d26137c773e994c79155c6c538778ca`, após squash do PR #176.  
**Autoridade:** responsável solicitou “faça uma revisão dos PR's e os integre caso necessario e me diga os proximos passos”. Autoriza revisão e integração seletiva; **não** altera autorização de Fase IX/produção, modelos, dados, scripts QVS ou QVW/QVD canônicos.  
**Ambiente:** ChatGPT GPT-6 + conector GitHub, sem Windows/QlikView local; esforço exato da sessão não exposto.  
**Fontes consultadas, na ordem requerida:** `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` na `main`; depois contrato UX integrado `docs/discovery/sad-p1-p11-p12-ux-contract-2026-10-28.md`, PRs/patches #172–#177, documentação de fechamento, escopo aprovado de 14 visuais e Boundary 7.

## 1. Decisão de integração — auditoria de patches

| PR | Evidência operacional e limite | Decisão |
|---|---|---|
| [#172](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/172) — PoC inicial | 4/4 KPIs visualmente corretos; gráfico P1.2 sem dados; `-Verify` terminou em `HARD_STOP` com diagnóstico histórico pendente. Contém executor `-Prepare/-Verify` e protocolo. | **NÃO integrar executor**; preservar tentativa e fonte no HEAD original. |
| [#173](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/173) — comparator forensic | PowerShell 5.1 9/9 testes sintéticos PASS e 25/25 protegidos iguais na leitura atual; não resolve causa passada de #172; script fixado a branch/manifesto antigos. | **NÃO integrar script de diagnóstico histórico**; preservar o PASS restrito e evidência no PR. |
| [#174](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/174) — correção P1.2 | Gráfico passou a renderizar com `=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)`; 36/36 exportados e reconciliados com E1; o `-Verify` original parou em 25× `PATH_TEXT_CHANGED` porque seu comparador usa `-cne`. | **NÃO integrar runner com bug de capitalização**; aproveitar resultado de série e manter o `HARD_STOP`. |
| [#175](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/175) — closeout read-only | Primeiro SelfTest falhou devido a colisão da função `Compare` com alias PowerShell; corrigido em commit posterior; 10/10 sintéticos PASS; nova leitura real 25/25 protegidos com zero divergências, origem intacta e cópia P1.2 salva. Não retroaprova verificadores antigos. | **NÃO integrar runner de auditoria pontual**, específico a caminho/hash/branch histórica; reter evidência versionada e comentário de resultado. |
| [#176](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/176) — revisão documental visual | Apenas um arquivo Markdown, com diagnóstico de rótulos, eixo e aviso metodológico. É revisão **pré-polimento**, não a aceitação final. | **INTEGRADO por squash em `main@92403e1a1d26137c773e994c79155c6c538778ca`**, como histórico de requisitos de UX. |
| [#177](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/177) — polimento visual em QVW TEMP | QVW de cópia, 4 cartões, nota metodológica, rótulos trimestrais; export pós-ajuste 36/36 **idêntica byte a byte** à anterior; `-Verify` 25/25 protegidos + origem intacta + cópia alterada, PASS restrito. Script fixa branch, hashes e diretórios da PoC e não é entrypoint de produção. | **NÃO integrar runner ad hoc**, preservar origens/referências e **integrar fechamento documental neste registro**. |

**Critério de seleção:** preservação de prova e rastreabilidade versus risco de acrescentar executores temporários que validam somente caminhos do operador, antigas branches e SHA fixados. Os executores permanecem commitados em seus respectivos PRs, recuperáveis por HEAD. Não tratar o código em `main` como requisito para validar a execução passada; `AGENTS.md` exige commit prévio, não merge obrigatório. Nenhuma branch deve ser excluída automaticamente.

## 2. Fechamento material da PoC (origem explícita da evidência)

**Fatos verificados nas evidências do operador e confrontos documentados:**

- Dados SIH/RD: 2017=**183.532**, 2018=**183.311**, 2019=**188.246**, triênio=**555.089** internações **novas administrativas**. Contar `QTD_INTERNACAO`; `IDENT=5` é continuidade e não incrementa essa medida. Não interpretar como pacientes distintos, demanda reprimida ou data clínica.
- P1.1: quatro objetos de KPI exibiram esses valores na captura final; títulos padronizados e tipografia maior. Essa prova é **visual dos quatro valores**, não teste de resposta a todos os filtros.
- P1.2: dimensão `PERIODO_COMPETENCIA` textual `AAAAMM`, linha histórica de **36 meses** (201701–201912) e expressão física do CH02 preservada:
  ```qlik
  =Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)
  ```
- Export pós-polimento `P11P12_VISUAL_POLISH_36_MESES.tsv.txt.txt` foi comparada ao arquivo pré-polimento `P12_CORRECTIVE_36_MESES.tsv.txt.txt`: **byte a byte idênticas**; SHA-256 das duas `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`. 36/36 linhas, 0 ausências/extras/duplicações/divergências; 2017/2018/2019 como acima, máximo `201905=17.292` e mínimo `201702=13.586`. Confronto ao E1 executado no gate anterior, **não repetido** para polimento. Consulta dos bytes TSV e screenshot não é recarga Qlik nem garantia de filtro global.
- Auditor do PR #175: `PROTECTED_FILES_CHECKED=25`, `PROTECTED_BLOCKING_ISSUES=0`, `PROTECTED_PATH_CASE_ONLY=0`, `PROTECTED_25_CONTENT_UNCHANGED=True`, `SOURCE_UNCHANGED=True`, `COPY_CHANGED=True`. Houve diferença de capitalização relatada no antigo `-Verify` #174, mas **não** reproduzida na leitura atual #175 (0 variações).
- Executor `-Verify` do PR #177, commit `0ec8b97168e5ca75d192a6c422285085ca14f6dc`, runner SHA `A6A755809383CBAFF8F5ACF55DE56C9A0AF96F90E5441566CFE2AA56DD595165`: 25/25 arquivos canônicos preservados em inventário reportado, origem do polimento SHA `8E2096D42602D7B84239AE30498EE45FA3ED6B060B9EEC6A4C003B0B3A2B7DE4` intacta; cópia final salva SHA `B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C`, `COPY_CHANGED=True`; veredito literal `PASS_HASH_INTEGRITY_ONLY_VISUAL_REQUIRES_REVIEW`.
- Capturas do operador mostram o número isolado `555089` substituído por rótulo de expressão em linguagem de negócio, marcações de X trimestrais sem perda dos 36 valores pela exportação, eixo X `Mês de competência (SIH/RD)`, aviso metodológico persistente e cartões legíveis. Cartões ainda contíguos; **não** justifica reabrir ciclo estético. Seleções Atuais vazias foram demonstradas no início; transições C2/P5 e comportamento sob filtros não foram homologados.

**Natureza das provas:** stdout Windows/Qlik **reportado pelo operador**; arquivos TSV e capturas **fornecidos e inspecionados**; scripts e diffs no GitHub inspecionados estaticamente. Não declarar execução por ChatGPT no Windows, validação visual humana formal da produção nem CI inexistente. Os QVWs e TSVs permanecem fora do Git em evidência local.

## 3. Estados de aceite, separados

- `P11_KPI_VALUES=PASS_SCREENSHOT_RESTRICTED_4_OF_4`.
- `P12_MONTHLY=PASS_FILE_36_OF_36_NO_REGRESSION` e `P12_PHYSICAL_CH02=PASS_VISUAL_CANDIDATE_RESTRICTED`.
- `P11_P12_FINAL_COPY_INTEGRITY=PASS_LOCAL_RESTRICTED`.
- `P11_P12_EXPERIMENTAL_GATE=CLOSED_PASS_RESTRICTED` — **não** implica `PR_MERGED`, `VISUAL_ACCEPTED_GLOBAL` ou `PROD_APPROVED`.
- `P11_P12_ORIGINAL_172_VERIFY=HARD_STOP_UNCHANGED`; `P12_174_VERIFY=HARD_STOP_UNCHANGED`.
- `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `ZERO_REAL_COMPROVADO=NOT_PROVEN`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Nada foi incorporado ao `PAINEL.qvw` final**. QlikView 12 e fluxo BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL, esquema Star/constelação, três fatos e oito dimensões continuam preservados. A primeira entrega de 13/10/2026 não foi reaberta; avaliação do professor pendente.

## 4. Próxima execução recomendada — um gate apenas

**Próximo objetivo delimitado:** `P1.3 – ranking de municípios de serviço (SERV) por internações novas, 2017–2019`, **READ-ONLY primeiro**, reusando o extrato E1 `sih_fluxo_competencia.csv` já reconciliado e o escopo aprovado de I03. Este é o próximo visual de P1 e não altera a ordem de implementação física C2 → C3 → C4 do Boundary 7.

**Critérios para a Discovery P1.3:** determinar competência/ano e universo de **atendimentos na PB**; agrupar por `municipio_serv`, nunca por `municipio_res`; usar apenas `qtd_internacao` (continuidades `IDENT=5` excluídas); reconciliar ranking/soma/participação contra total de 555.089 sem inferir nomes municipais históricos quando não validados; distinguir valores do relatório exploratório de 27/10/2026 de PASS de gate. Entregar tabela de ranking com códigos rastreáveis, proporções apenas com denominador explicitado, limitações e critério de exibição; STOP após uma tabela e decisão de suficiência. **Não** construir/alterar QVW, COM, novos QVD/QVS ou ampliar escopo para P1.4 sem outra decisão.

**Sequência analítica posterior, cada qual com gate próprio:** P1.4 procedimentos `PROC_REA` (E2 e SIGTAP temporal), P1.5 diagnósticos `DIAG_PRINC` (E3/CID), depois visuais observacionais P2 e fluxos RES→SERV P3, com P2.3 A1 restrito preservado. A obrigatoriedade acadêmica de três painéis existe, mas **eles ainda não estão aprovados/finalizados**. T24/T25/T26 e Fase IX seguem caminho crítico independente; não fabricar taxa de ocupação ou população para RES externo.

**STOP desta revisão:** integrar apenas o histórico documental útil e este closeout, registrar destinação dos PRs e encerrar. Não refazer 36/36, hashes, C2, P2.3, exportações, nem iniciar novo gate físico automaticamente.