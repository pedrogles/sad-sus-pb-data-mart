# SAD SUS PB — M0 complementar: deltas contratuais e readiness M1

**Data:** 07/11/2026  
**Estado:** CANDIDATE_CHANGE_CONTROL_NOT_APPROVED / M1_NOT_EXECUTED  
**Baseline de referência:** `main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83`  
**Vinculação:** [M0 — proposta principal](mvp-rebaseline-proposal-2026-11-07.md), [PR #226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226).  
**Escopo deste documento:** descrever mudanças propostas e definir a menor verificação física futura possível. **Não modifica** AGENTS, Boundary 7, D2-R2 V3, P5, blueprint, QVS, QVD ou QVW. A solicitação de “prosseguir” autoriza avançar na preparação documental; não é homologação de um novo contrato físico nem consentimento para merge.

## 1. Decisão técnica recomendada

**Rota-padrão B1:** preservar as três fatos e oito dimensões da primeira entrega e os QVDs reportados; utilizar o modelo técnico e a Link Table *somente nos percursos que forem de fato demonstrados no QlikView* para os indicadores de uma única fato. Não descartar, recalcular ou reimportar toda a BASE.

As três folhas podem conter dados SIH/RD, CNES/LT e IBGE/POP, mas **folhas do QlikView não são isolamento físico de associações**. Filtros de tempo, município e papéis precisam ser validados por medida; não inferir independência pelo layout. Se os percursos de B1 falharem, concluir `BLOCKED_B1` e submeter proposta alternativa B2 (projeções isoladas por nomes/estados distintos), sem troca automática de arquitetura.

**Produto pretendido:** três folhas com nove visuais centrais, como na proposta M0; no P3, a visualização de população é descritiva por município×ano e não tem ligação automática com SIH/RD. Não apresentar T24/T25/T26 no MVP.

## 2. Matriz de deltas contratuais explícitos

| Contrato atual na main | Situação vigente | Substituição candidata para MVP | Nova aprovação obrigatória | Prova mínima exigida |
|---|---|---|---|---|
| Boundary 7 / IX | C2→C3→C4→GO IX antes do painel final | Redefinir apenas o **escopo de aceite** de C2/C3/C4 para as nove análises expostas, conservando a ordem de dependência entre os subtestes aplicáveis. Sem GO antecipado para o QVW final. | Responsável, adendo escrito e merge específico | Matriz de uso da dimensão/fato/filtro; nenhuma associação indevida nas nove expressões |
| D2-R2 V3 | Prevenção para fluxo temporal guiado, revalidação nativa após alterações | Não oferecer os modos guiados MENSAL/ANUAL/EVOLUCAO no MVP **se removidos de todos os objetos expostos**; usar filtros nativos explícitos e gráficos rotulados por tempo real. D2-R2 continua vigente para qualquer controle guiado remanescente. | Responsável, revisão semântica limitada à superfície do MVP | Um estado válido e um inválido/ambíguo por **tipo** de visual/seleção relevante; indicadores não mostram número obsoleto |
| V2 §62.6 P5 | Compatibilidade C/R/I/B por indicador, sem ignorar filtro silencioso | Restringir superfícies de filtro aos campos usados em cada visual, manter seleção efetiva visível e indisponibilidade onde houver conflito. **Não remover P5 dos indicadores existentes**; propor `NOT_APPLICABLE_TO_MVP` somente para razões cross-fact não expostas | Responsável, matriz explícita indicador×filtros | Confronto de valores com oráculos sob os filtros realmente disponibilizados |
| Blueprint PR #209 | Três folhas/14 visuais e faixa guiada | Três folhas/nove visuais; suprimir objetos candidatos redundantes, conservar notas de cobertura; contexto temporal aplicado legível | Responsável, novo blueprint aprovado | Revisão das nove posições de objetos e de suas fontes sem expressões fictícias |
| Boundary 6 Link Table | LINK_ANALISE/%LINK_KEY e dimensões conformadas como arquitetura principal | Preservar B1 até teste. Se modelo associativo causar seleção enganosa, apresentar B2 em adendo separado; não criar associações cruzadas sem prova | Responsável **se** alterar Link/aliases | Inspeção de $Syn/loops e reconciliação por FI, FL e POP nos recortes do MVP |
| Capítulos 1–2 impressos | Três fatos e oito dimensões já entregues 13/10 | Nenhuma mudança na modelagem nesta opção | Parecer docente **se** escopo narrativo final conflitar com promessa inicial | Matriz entre modelos acadêmicos, QVDs reais e três folhas finais |
| CNES histórico / T29 | Histórico de rótulos não aprovado; ausência LT ≠ zero | Exibir códigos e avisos em recortes sem rótulo válido. Observabilidade separa positivo, zero com linha e ausência | Aprovação nova apenas se mudar universo/interpretação | Contagem por classes e título correto do indicador |
| T24/T25/T26 | Sem contrato global de Link/denominadores, #157 pendente T25/T26 | Adiados e fora dos nove visuais; população anual continua na modelagem e tem apresentação independente | Decisão explícita sobre escopo acadêmico e eventual professor | Nenhuma razão por 1.000 ou taxa de ocupação sem contrato |

**Semânticas invioláveis:** `IDENT=5` não é internação nova; `N_AIH` não é PK; residência≠serviço; datas clínicas ≠ competência; FP município×ano; leitos e população semi-aditivos temporalmente; não inferir zero real nem abrangência hospitalar integral da ausência LT; `T29_HISTORICAL=NOT_APPROVED`.

## 3. Risco de implementação que domina a recuperação

Inspeção estática da main:
- `EXTRACAO/ext_main.qvs` é um entrypoint de staging existente.
- `TRANSFORMACAO/transf_main.qvs` orquestra as dimensões, mas geração de `FATO_INTERNACAO` segue `OFF` por padrão e as três fatos/Link não têm um entrypoint final integrado em `transf_main.qvs`.
- `PAINEL/painel_main.qvs` possui somente infraestrutura/TRACE; `PAINEL/phase_vii_technical_model.qvs` contém modelo técnico de **teste** com placeholders `__LINK__`, `__POP__` etc., não é carregamento final parametrizado.
- O modelo VII projeta POP numa Link derivada por hash em memória; isso **não** demonstra que seleção compartilhada FI↔POP corresponde ao uso acadêmico, nem isolamento do P3.
- A quantidade 22 QVDs/3 QVWs provém de relatos locais referenciados por current-state, não de bytes aqui inspecionados.

Portanto **não** começar por recriar dados nem por novos C2/TX17. Primeiro conferir *quais artefatos estão acessíveis no Windows*; depois escolher o menor ponto de consolidação do consumo.

## 4. M1 — pré-flight físico mínimo, ainda sem execução

**Objetivo único M1-READONLY:** confirmar existência, procedência e integridade das entradas para um único QVW TEMP futuro, e descobrir se o modelo técnico atual pode ser consumido sem modificar QVDs.

**Ambiente exigido:** Windows do operador com QlikView 12 Desktop e repositório no commit identificado. O conector GitHub **não** acessa automaticamente arquivos locais do Windows.

**Escopo READ-ONLY para M1-READONLY:**
1. Verificar `BASE`, `EXTRACAO/QVD`, `TRANSFORMACAO/QVD`, `EXTRACAO/EXT.qvw`, `TRANSFORMACAO/TRANSF.qvw`, `PAINEL/PAINEL.qvw` e o diretório de evidências. Não tocar conteúdo.
2. Inventariar nomes, tamanhos, timestamp, SHA-256 e commit de origem dos scripts. Confrontar inventário **reportado** de 10+12 QVDs e três QVWs canônicos; não aceitar apenas contagem de arquivos como PASS sem reconhecer nomes. Usar a política `docs/project/artifact-recovery-policy.md`.
3. Confirmar disponibilidade dos QVDs `SRC_SIH_RD`, `SRC_CNES_LT`, `SRC_CNES_ST`, `SRC_IBGE_POPULACAO`, `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`, `LINK_ANALISE` e das oito dimensões — os nomes esperados não confirmam bytes físicos.
4. Inspecionar somente scripts/manifestos/logs existentes para resolver as ligações entre QVDs e o QVS técnico. Se houver necessidade de executar uma auditoria Qlik, seu executor deve estar previamente versionado na branch, com SHA e autorização específica.
5. Registrar divergências em uma **única matriz**: artefato, caminho real, existe?, SHA, origem, uso no MVP, bloqueio concreto. Não inventar resultado de carga ou valor de painel.

**M1-READONLY PASS:** matriz dos 25 artefatos com proveniência suficiente, sem modificações, identificando um conjunto de insumos compatível para QVW TEMP; este PASS **não aprova** o modelo associativo.

**M1-READONLY BLOCKED:** artefato ausente, hash divergente ou acesso Windows indisponível. Encerrar com evidência e menor requisito de recuperação; não reconverter os 108 DBCs por padrão.

**M1-READONLY INCONCLUSIVE:** existe arquivo, mas não há vínculo confiável com o script/commit/manifesto. Não inferir PASS de volume.

**STOP:** uma única rodada de inventário. Sem GUI, COM, Reload, Save, STORE, geração de QVDs, testes de seleção, atualização de PAINEL, nova série de TX17, merge ou IX.

**M1-CONSUMPTION (etapa distinta e condicionada):** depois de M1-READONLY, decidir um QVW TEMP isolado, roteiro de construção e teste do modelo de consumo com 3 fatos em recortes representativos. Só então autorizar script versão/Windows QlikView. A prova deve distinguir base íntegra, associação correta, expressão correta e painel apresentado — sem declarar os quatro níveis ao provar apenas um.

## 5. Inventário preliminar dos 21 PRs anteriores (somente READ-ONLY)

Classificação inicial pelos títulos, corpos e estados do GitHub em 07/11/2026. **Não efetua fechamento, merge, supersedência formal ou exclusão; nenhuma categoria equivale a aprovação física.**

| Grupo | PRs | Motivo |
|---|---|---|
| `REUSE_EVIDENCE_REVIEW` | #223, #210, #208, #205, #203, #167 | Evidências/experimentos úteis para comparar resultados e mapear a superfície. Incluem passes restritos ou preparações; revisar a prova de cada um, não herdar PASS global. |
| `DEFERRED_C2_PENDING_REBASELINE` | #225, #224, #222, #221, #220, #219, #218, #217, #216, #215, #211, #207 | Investigações de UI, runners ou escolhas temporais que não devem continuar consumindo execução antes de M0. Não interpretar `NOT_RUN` do corpo como diagnóstico atual de comentários não lidos. |
| `SUPERSEDED_CANDIDATE_REVIEW` | #212, #204, #199 | Minuta D2 anterior ao adendo integrado #213, desenho anterior ao experimento #205 e preparação de prova mensal agora substituída por evidência mais recente. Revisar dependências antes de qualquer decisão de fechamento. |

Issue [#196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196): C2 permanece aberto e não homologado globalmente. Issue [#157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157): pendência restrita a suficiência de T25/T26, não bloqueio de gráficos descritivos FI/FL.

## 6. Condições para considerar a simplificação adotada

**DECISÃO PENDENTE DO RESPONSÁVEL:** aceitar formalmente (i) os nove visuais, (ii) a retirada dos controles guiados do MVP quando substituídos por filtros nativos e (iii) a revisão **delimitada** dos critérios C2/C3/C4 e do blueprint, preservando o comportamento seguro por indicador.

Após a decisão, redigir o texto normativo do adendo e requerer autorização de merge **separada**, com revisão dos conflitos entre documentos. **O PR #226 é um pacote de proposta**, não a alteração vigente da main. Não alterar `current-state.md` até que exista decisão material e atualização coerente.

**Próxima operação permitida sem nova decisão:** revisão documental da proposta e dos PRs; **não** M1 físico em Windows nem criação/edição de QVW/QVD/QVS. A instrução genérica “prossiga” neste contexto não autoriza essas ações de forma implícita.

**M0_DELTA_PREPARED=YES; M0_OWNER_CONTRACT_APPROVAL=PENDING; M1_READONLY=NOT_RUN; C2/C3/C4=UNAPPROVED_FOR_MVP; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False.**

## 7. Ferramenta única de inventário M1 preparada (não executada)

**Justificativa excepcional para um script novo:** as rotinas anteriores de C2 são específicas de QVW TEMP, e os executores `materializar_*` podem criar dados; usá-los apenas para inventariar os 25 arquivos implicaria risco e retrabalho. Foi preparado **um único script genérico reutilizável**, `tools/m1-inventario-artefatos-readonly.ps1`, estritamente sem COM/QlikView, Reload, Save, STORE, cópia/restauração de origem ou exclusão. A ferramenta não expande a sequência de gates C2.

Inventário nominal das 25 entradas conforme `ext_main.qvs`, includes da extração, oito dimensões, três fatos, Link e três QVWs canônicos. O script **lê** nomes/tamanhos/hashes SHA-256 e, opcionalmente, compara contra a pasta `backup` documentada em `docs/project/artifact-recovery-policy.md`. Apenas o relatório CSV/TXT é escrito no `EvidenceRoot` informado, que deve ficar **fora** da árvore do Git e do backup.

### Execução futura opcional, somente no Windows pelo operador e após autorização do inventário físico

```powershell
# Partindo da raiz do clone local, com a branch/commit aprovado para M1:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\m1-inventario-artefatos-readonly.ps1 `
  -RepoRoot (Get-Location).Path `
  -EvidenceRoot "D:\SAD_EVIDENCIAS" `
  -BackupRoot "D:\SAD_STABILIZATION_01_20261020\backup"
```

Os caminhos `D:\...` são exemplos, **não** localizações reais conhecidas. Resolver no Windows a pasta `backup` efetiva e protegida. Se a cópia não estiver disponível, omitir `-BackupRoot`, mas o resultado será **PRESENT_25_NOT_COMPARED_TO_BACKUP**, jamais PASS de integridade.

Códigos de saída:
- `0`: `MATCHED_25_BACKUP_BYTES_NOT_QVD_SEMANTIC`; as 25 origens correspondem byte a byte às 25 cópias locais **no instante do teste**, sem comprovar integridade histórica da cópia, associação ou funcionamento Qlik;
- `2`: arquivo ausente, erro de leitura ou hash divergente;
- `3`: todos presentes mas não comparados ao backup;
- `4`: comparação incompleta/não concluída;
- erro PowerShell: pré-condição inválida, nenhuma conclusão de gate.

**Evidência disponível na main:** a política de recuperação de 20/10/2026 registrou 25 cópias e um manifesto local `artifact-manifest-2026-10-20.csv`, com 96.708.026 bytes, mas apenas prova de cópia no mesmo disco, não backup independente. Confrontar com esse manifesto de outubro caso disponível **sem assumir seu schema**; o script compara bytes com a pasta de cópias, e não interpreta o manifesto anterior.

**Teste e aprovação:** fonte versionada no Draft #226, porém sem PowerShell 5.1/Windows nesta sessão. `SCRIPT_STATIC_ONLY`, `PARSER_WINDOWS=NOT_RUN`, `M1_WINDOWS=NOT_RUN`. Antes de sustentar um gate, operador deve conferir commit e SHA-256 efetivo do script, executar uma vez em modo somente leitura e devolver o resumo CSV/TXT, omitindo caminhos pessoais em relatórios públicos. Mesmo código 0 não substitui prova de carga de QVD/seleções/visuais.

**STOP:** nenhum teste C2, nenhum novo QVW, nenhum merge ou regeneração de QVD é autorizado por esta preparação.

## 8. Evidência operacional M1 — retorno do operador em 07/11/2026

**Fonte:** saída do PowerShell 5.1 reproduzida pelo responsável na conversa. **Classe de evidência:** `LOCAL_OPERATOR_REPORTED`; o CSV, os QVDs e os QVWs binários **não foram anexados nem conferidos independentemente** neste registro. Nenhum caminho pessoal foi versionado.

| Campo | Valor reportado |
|---|---|
| `VERDICT` | `MATCHED_25_BACKUP_BYTES_NOT_QVD_SEMANTIC` |
| `EXPECTED` / `PRESENT` | `25 / 25` |
| `MATCHING_BACKUP_BYTES` | `25` |
| `ISSUES` | `0` |
| `BACKUP_COMPARISON` | `True` |
| `GIT_HEAD` | `148c0a3fd44bd3d4c79f0db400531be432c25a37` |
| `SCRIPT_SHA256` | `54AEEB12A2E0EA5EA4CBBC112687A451380CC0B35AC89E9907B5D151AC3E2B18` |
| `LIMITATION` | `FILE_PRESENCE_AND_HASHES_ONLY_NOT_QVD_RELOAD_ASSOCIATIONS_OR_UI` |

**Interpretação limitada:** 10 QVDs de extração, 12 QVDs de transformação e 3 QVWs canônicos estavam presentes e coincidiram byte a byte com a pasta de cópias no momento da execução reportada. O backup de 20/10/2026 é `LOCAL_COPY_ONLY`, no mesmo disco de origem conforme a política: **comparação positiva não prova recuperação de desastre nem funcionamento semântico no QlikView**. Não usar `M1_INVENTORY=PASS` como sinônimo de `M1_DATA_MART_FUNCTIONAL=PASS`.

**Próximo trabalho sob decisão própria:** preparar o **único QVW TEMP de consumo** usando os QVDs existentes, não os canônicos como destinos de Save/Reload. Conferir, por evidência real, (i) os três fatos/carregamento, (ii) associações efetivamente necessárias, (iii) totais/oráculos existentes, (iv) efeito de ano/competência/território nos visuais expostos. Não inferir viabilidade física da Link Table pela existência do QVD. Não executar C2/TX17 nem reconstruir QVDs.

**STOP M1-INVENTORY:** concluído por evidência local reportada; não executar o mesmo inventário repetidamente sem mudança factual. **M1_CONSUMPTION=NOT_RUN; OWNER_MVP_SCOPE_APPROVAL=PENDING; TEMP_QVW_AUTHORIZATION=PENDING; C2/C3/C4/IX=NOT_APPROVED.** Este registro é apenas um acréscimo documental na branch Draft #226, sem alteração dos contratos vigentes.

## 9. M1 Integrated TEMP — execução física autorizada pelo responsável

**Autorização explícita recebida nesta conversa:** “autorizo, prossiga”, após a pergunta específica sobre **criar e testar um QVW temporário no Windows preservando QVD/QVW canônicos**. Esta autorização cobre somente a tentativa física M1, não altera contratos aprovados, não autoriza merge, IX, ou painel final.

**Objetivo e ganho líquido frente à Fase VII de 18/10:** o modelo técnico com 3 fatos + Link e 16 tabelas **já** teve `PASS_LOCAL_REPORTED_AND_VISUAL_ASSOCIATIVE_CANDIDATE_ONLY` e captura de Table Viewer. **Não reabrir essa decisão**. Usar suas verificações apenas como preflight defensivo e acrescentar **10 comparações numéricas independentes por fato** no mesmo modelo associativo. A execução não pretende redemonstrar todas as 146 verificações do A0 nem um sistema global de filtros.

**Ferramenta versionada:** `tools/Invoke-SadM1IntegratedTempQvw.ps1`, adaptada de `tools/Invoke-SadPhaseViiTechnicalPanel.ps1` da main. Script de modelo QlikView reaproveitado **sem edição**: `PAINEL/phase_vii_technical_model.qvs`. O runner exige branch `proposal/sad-mvp-rebaseline-2026-11-07`, HEAD SHA completo e fontes Git rastreadas e limpas.

**Entradas somente leitura:** 10 QVDs da extração, 12 QVDs da transformação (incluindo Link), 3 QVWs canônicos para hash pre/post. **Única escrita QlikView:** novo `SAD_M1_INTEGRATED_TEMP.qvw` e log em diretório novo dentro do `EvidenceRoot` privado fora do Git; saída `m1_fact_oracle_checks.csv` e CSVs de hashes também somente nessa pasta. Nenhum STORE, reload de QVW canônico, mutação de QVD ou sobrescrita de backup.

### Oráculos reutilizados (não foram recalculados)

| Caso | Esperado | Fonte de evidência |
|---|---:|---|
| RD_ALL | 555.089 | F5-RD / inventário analítico |
| RD_2017 | 183.532 | F5-RD |
| RD_2018 | 183.311 | F5-RD |
| RD_2019 | 188.246 | F5-RD |
| LT_SUS_201912 | 7.140 | P2.2 composição, closeout 29/10 |
| LT_NSUS_201912 | 1.925 | P2.2 composição, closeout 29/10 |
| LT_EXIST_201912 | 9.065 | P2.2 composição, closeout 29/10 |
| POP_2017 | 4.025.558 | F5-POP / readback |
| POP_2018 | 3.996.496 | F5-POP / readback |
| POP_2019 | 4.018.127 | F5-POP / readback |

**Garantia semântica restrita:** cada expressão é de *uma fato*, com Set Analysis de ano/competência somente para demonstrar acesso ao campo, e não prova navegação do usuário nem tratamento nativo D2/P5. Leitos mensais não são somados entre competências; população anual não é repetida pelos doze meses. Não testar cross-fact T24/T25/T26, ocupação ou cálculo per capita.

### Handoff Windows para execução uma única vez

No clone local, com `git status --short` vazio, atualizar apenas a branch já selecionada com `git pull --ff-only`. Confirmar `git branch --show-current` e `git rev-parse HEAD`.

```powershell
powershell.exe -NoProfile -File .\tools\Invoke-SadM1IntegratedTempQvw.ps1 `
  -Root (Get-Location).Path `
  -ExpectedCommit (git rev-parse HEAD) `
  -EvidenceRoot "$env:USERPROFILE\SAD_M1_EVIDENCIAS" `
  -RunQlik
```

O diretório de evidência já foi criado no inventário anterior. O caminho do QVW TEMP e do log é retornado em `EVIDENCE_DIR`, `TEMP_QVW` e `NATIVE_LOG`. Não abrir nem salvar `PAINEL/PAINEL.qvw`.

**PASS M1 restrito:** exatamente dez `M1_ORACLE ... Pass=True`, `M1_FACT_ORACLES=10_OF_10_PASS_LOCAL_CANDIDATE_ONLY`, `VERDICT=PASS_LOCAL_M1_TEMP_MODEL_ONLY_PENDING_TABLE_VIEWER_AND_INDICATORS`, `ORIGINAL_22_QVD_SHA256_AND_HEADERS_UNCHANGED=True` e `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True`. Esse resultado **não é** aceite visual de três painéis nem do Link Key/filtros globais.

**BLOCKED:** erro de COM, log nativo, qualquer um dos dez números, falta/deriva de arquivo/coluna/link, erro Qlik ou hash de arquivo protegido alterado. Preservar pasta de evidência e reportar o primeiro erro; **não repetir automaticamente** ou refazer dados. Se os números não baterem, comparar regra/expressão/escopo e solicitar nova decisão específica.

**INCONCLUSIVE:** o runner não completar a verificação, sem evidência suficiente para decidir se o QVW carrega corretamente.

**STOP:** uma tentativa física autorizada; aguardar stdout e CSV para análise independente. `M1_INTEGRATED_TEMP=NOT_RUN` enquanto o operador não executar. `C2/C3/C4`, `LINK_KEY_CONTRACT`, `PHASE_IX` e produção permanecem não aprovados.
