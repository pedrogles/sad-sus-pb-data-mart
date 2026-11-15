# VIS-05 — Gate de inspeção física sem recarga

**Data:** 15/11/2026. **Gate:** `SAD_VIS05_READONLY_INSPECTION_01`.

**Estado inicial:** `PREPARED_NOT_RUN_WINDOWS`. Não altera o parecer anterior nem concede novos PASS físicos antes da execução real. Este é um gate novo autorizado pelo responsável ao solicitar prosseguir com o formato de inspeção em bytes, filtros e rótulos; não reabre a auditoria documental G0–G5 nem a implementação acadêmica.

## Problemas, evidências e pergunta delimitada

| Referência da auditoria | Evidência anterior | Pergunta deste gate |
|---|---|---|
| AUD-03 | QVW VIS-05 com SHA apenas reportado; ZIP sem QVW, propriedades atuais ou logs | Os bytes locais correspondem ao pin? Os nove objetos e suas propriedades podem ser lidos na cópia? |
| AUD-04 | Bloqueio histórico de M2-02 sob ano 2018; prova posterior de aviso sob mês 201801 | A condição efetiva de CH05 no VIS-05 bloqueia 2018? A imagem mostra motivo contextual? |
| AUD-03 / M3-01 | Textos livres conferidos apenas em estado neutro; dinamismo não certificado | Sob uma única classe e, opcionalmente, ordem invertida, o texto visível continua associado à categoria/valor correto? |
| AUD-05 | Reconstrução integral VIS-05 não comprovada | Inspecionar o artefato existente, sem rebuild; proteger e identificar os originais |

Escopo: nove objetos, cinco estados da QVW final. Não testar T24–T26, novo indicador, classificação hospitalar histórica, performance ou homologação global. Um desvio interrompe a execução e preserva a evidência; sem correção automática.

## Fontes e estado Git

Leitura obrigatória feita na ordem `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md`. Depois: política de agentes, `qlikview-powershell-automation.md`, Boundaries 5–7 e modelagem (reutilizados da auditoria), contratos do MVP, consolidação de evidências e scripts existentes.

- Main de referência: `5486ad9f50744769e85107132eae009529ac75cc`, revalidada no GitHub.
- PR documental [#242](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/242): Draft/OPEN; HEAD `9f3bd1b0d510f93fa139d747d46a2c160e6a3363`. Seu hash QVW é insumo reportado, não conclusão deste gate.
- Branch deste gate: `test/sad-vis05-readonly-inspection-2026-11-15`, separada da PR #242.
- Arquivos novos: runner `tools/Inspect-SadVis05ReadOnly.ps1`, contrato `PAINEL/sad_vis05_readonly_inspection_contract.json`, revisor `tools/review_sad_vis05_inspection.py`, testes sintéticos e este runbook.
- Reuso de padrões: locks/cópia/hash de VIS-04 e runners C3; `GetSheet()/GetSheetObjects()` do inspetor histórico; caminho `EvaluationCondition.v` já lido no Windows. Não se copiam executores de recarga.
- Fonte histórica de inspeção: [Inspect-SadMvpC4CustomMessageCom.ps1](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/0e7eb3c12c04bbdaf3708e3f3998f7dd94d4c0b6/tools/Inspect-SadMvpC4CustomMessageCom.ps1), blob `c96fe852213d0f496ed978d3f306e7e98626cc9d`; metadados de overrides limitados a Count, sem mapeamento Item aprovado. Não repetir sondagens especulativas dessa coleção.

## Roteamento operacional

- Agente preparador: ChatGPT Work, runtime identificado como Codex; modelo/esforço exatos não selecionáveis/verificáveis. Não houve subagente.
- Execução física: operador humano ou Codex Local no Windows com QlikView Desktop 12, PowerShell 5.1 e Python 3. Cloud não tem acesso ao Windows do responsável.
- Permissões: criar fonte nesta branch/PR; abrir somente cópia de inspeção, mudar seleções/aba em memória, exportar JSON/CSV/PNG de evidência. Ordenação manual opcional apenas nessa cópia, sem salvar.
- Invariantes: não chamar Reload, Save, SaveAs, SetProperties, CreateDoc ou STORE; não mudar QVS, QVD, modelos, PDF ou QVW original. Nenhum merge autorizado por este gate.
- Evidências: pasta persistente externa ao Git e ao TEMP, criada sob `%USERPROFILE%\SAD_VIS05_INSPECTION_EVIDENCIAS`; nomes únicos por execução. A cópia QVW fica read-only e com hash igual ao pin. Não a enviar nem versionar.
- Fallback: retorno INCONCLUSIVE com erro/metadados, sem tentar outra assinatura COM ou outra API automaticamente.
- Orçamento: uma execução Inventory; após revisão dos resultados, uma execução Scenarios. Falha técnica ou semântica encerra a tentativa; correção requer novo commit e decisão delimitada.
- STOP: entregar evidência do modo executado; não partir para correções, novo build, merges, T24–T26 ou produção.

## Artefato aceito e proteção

Origem padrão:

`%USERPROFILE%\SAD_VIS05_EVIDENCIAS\VIS05_20261112_171721_950990d1\SAD_MVP_VIS05_UX_WORK_TEMP.qvw`

Pin SHA-256: `B56D0A8550AB7EEE68D45DB0249F273DED05C4ADEE88DBE3FC7A20B162084DBB`.

É possível informar `-SourceQvw` se o arquivo foi movido; nome final e hash precisam permanecer os mesmos. Não trocar o pin para fazer passar outro arquivo. Com QlikView fechado, o runner confere identidade e obtém locks de leitura sobre o QVW fonte, 22 QVDs (10 extração+12 transformação) e três QVWs canônicos. São 26 arquivos protegidos. Locks impedem gravação concorrente nesses arquivos durante a sessão; hashes antes/depois comprovam preservação no escopo local.

Cria uma cópia byte a byte em pasta única e marca-a read-only antes de OpenDoc. Não usa os scripts internos para recarregar. QlikView deve estar fechado antes de iniciar; licenciamento/popup/erro COM são impedimentos reais, não indicação para nova tentativa automática. Se houver diálogo de gravação ao fechar, não salvar. A execução não é garantida headless. Capturas exigem sessão Windows visível e janela QlikView sem outra janela sobreposta.

Preservar os QVDs disponíveis no disco não prova que foram precisamente aqueles bytes usados na última carga do QVW. A linhagem completa dessa carga continua dependente de seus logs/manifestos originais. O gate demonstra identidade do QVW atual e resultados sob seleções, sem reconstruir retrospectivamente uma proveniência que não tenha evidência.

## Dois modos, com fronteiras de prova

### Inventory — executar primeiro

Confere bytes/Git e enumera objetos por folha; lê propriedades com profundidade e orçamento limitados, títulos, condição e primeira expressão pelo caminho COM já utilizado no builder. O mapeamento de todos os membros de dimensões/mensagens não é presumido. Guarda os nomes e campos efetivamente legíveis. Não aplica seleções nem modifica propriedades. Com `-Capture`, registra uma imagem por folha.

Não invoca `NoOfTables()`/`TableName()` como se fossem funções de gráfico. A enumeração física completa de tabelas/campos fica INCONCLUSIVE neste executor porque não há enumerador COM comprovado no projeto. Não converter presença de declarações no script em prova de tabelas carregadas.

Resultado máximo: `INVENTORY_COLLECTED_NOT_FUNCTIONAL_PASS`. Antes do modo Scenarios, revisar o inventário, identidade/hash, cleanup e compatibilidade das propriedades lidas. Não avançar diante de falha.

### Scenarios — somente após revisar Inventory

Cada cenário começa com ClearAll e comprovação de ausência de seleções residuais. Aplica somente campos autorizados e confere valor e cardinalidade selecionados. Em cada estado registra probes de motor, condições de CH04/CH05/CH09 e capturas de folhas pertinentes.

| Estado | Seleção | Comparação principal |
|---|---|---|
| BASELINE | nenhuma | FI 555.089; 566.672 SKs FI; EQ 294.635; NE 260.454; LT 201912 7.140; POP 2019 4.018.127; P23 8.028/4.467/3.464/97 |
| YEAR_2018 | PERIODO_ANO=2018 | FI 183.311; CH05 condição falsa; CH09 condição verdadeira; ilha P23 invariável |
| FLOW_NE_ONLY | MVP_FI_RES_SERV_CLASS=RES_NE_SERV | FI 260.454; EQ 0; NE 260.454; conferir rótulo visível de município diferente |
| FLOW_EQ_ONLY | MVP_FI_RES_SERV_CLASS=RES_EQ_SERV | FI 294.635; EQ 294.635; NE 0; conferir rótulo de mesmo município |
| SERV_250750 | SERV_COD_DATASUS_6=250750 | FI 225.785; LT 201912 2.159; CH09 condição falsa; ilha P23 invariável |

As referências numéricas são as já documentadas nos closeouts P3.2/P2.4 e consolidação MVP; o gate não reprocessa os datasets. Repetir valores neutros e SERV no novo binário é necessário para vinculá-los ao hash VIS-05, ainda não inspecionado fisicamente. Não constitui reabertura dos gates anteriores.

Os filtros por classe são sondagens técnicas deliberadas no novo artefato; seu efeito sobre leitos/POP é registrado apenas observacionalmente. Não se aprova o uso desses subconjuntos em indicadores cross-fact. `Evaluate()` executa a expressão registrada no contrato, não lê as células do gráfico. O relatório distingue os dois níveis; propriedades/figura precisam continuar coerentes com os probes.

O erro numérico ou condição divergente é FAIL restrito e interrompe o runner. Resultado vazio nos probes sem contrato naquele estado não vira zero real de capacidade/população nem FAIL inventado. Mensagem efetivamente visível exige imagem: ler condição falsa não prova que existe aviso legível.

## Rótulos e ordenação

FLOW_NE_ONLY e FLOW_EQ_ONLY geram imagens nas quais resta uma única classe. Isso permite detectar texto manual preso à posição errada, mesmo quando o total numérico está correto. Captura e propriedades não são aprovadas pelo script; retornar para revisão da relação categoria→texto→valor.

`-ManualSortReview`, opcional com Scenarios+Capture, limpa seleções, captura antes e pede ao operador que inverta a ordenação de CH07 **pela GUI na cópia**, sem mudar dimensão, expressão ou textos. Após digitar `SORT_CHANGED`, captura depois e lê propriedades; caso contrário, registra SKIPPED. O script não chama setter COM para ordenar nem presume que a ordem realmente mudou só porque o operador digitou a confirmação. Verificação visual da inversão e dos rótulos continua pendente.

## Comandos Windows

Usar worktree isolada para os scripts desta branch. `-Root` aponta para essa worktree; `-ArtifactRoot` aponta para o clone existente que contém seus QVDs/QVWs. O diretório original não muda de branch, e seus binários são apenas lidos/protegidos. Se ArtifactRoot for omitido, o padrão é Root; não é a opção recomendada para a primeira execução.

Na raiz do clone SAD existente, com QlikView fechado:

```powershell
git status --short
$artifacts = (Get-Location).Path
$code = Join-Path (Split-Path $artifacts -Parent) 'sad-vis05-inspection-2026-11-15'
git fetch origin test/sad-vis05-readonly-inspection-2026-11-15
if ($LASTEXITCODE -ne 0) { throw 'STOP: fetch falhou' }
git worktree add -b test/sad-vis05-readonly-inspection-2026-11-15 $code origin/test/sad-vis05-readonly-inspection-2026-11-15
if ($LASTEXITCODE -ne 0) { throw 'STOP: worktree já existe ou há colisão; inspecionar git worktree list' }
Set-Location $code

$head = (git rev-parse HEAD).Trim()
$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path .\tools\Inspect-SadVis05ReadOnly.ps1).Path,
  [ref]$tokens, [ref]$parseErrors
) | Out-Null
if (@($parseErrors).Count -gt 0) { $parseErrors; throw 'STOP: erro de parser' }

powershell.exe -NoProfile -File .\tools\Inspect-SadVis05ReadOnly.ps1 `
  -Root $code -ArtifactRoot $artifacts -ExpectedCommit $head -Mode Inventory -Capture -Inspect
```

O commit deve coincidir com o SHA publicado da PR; não selecionar automaticamente um HEAD novo não revisado. `-ExpectedCommit` verifica o checkout e os arquivos executáveis/contrato são comparados aos blobs do HEAD. A próxima execução usa Scenarios **após revisão do Inventory**, mantendo o mesmo commit:

```powershell
powershell.exe -NoProfile -File .\tools\Inspect-SadVis05ReadOnly.ps1 `
  -Root $code -ArtifactRoot $artifacts -ExpectedCommit $head -Mode Scenarios -Capture -Inspect
# Acrescentar -ManualSortReview somente para executar também a etapa assistida de ordenação.
```

O caminho `REPORT=` aparece na saída. A análise independente do JSON, sem QlikView, pode ser feita uma vez:

```powershell
python .\tools\review_sad_vis05_inspection.py --report 'CAMINHO_REPORT_INSPECTION_JSON'
```

O revisor usa o contrato versionado da branch e confere seu SHA contra o relatório. Cria `assessment.json` com modo exclusivo, sem sobrescrever análises anteriores. Executar uma segunda análise sobre o mesmo diretório é recusado; não é falha do QVW.

## Evidências e critérios

Saídas: `inspection.json`, cópia exata do contrato, `scenario_summary.csv`, capturas PNG quando solicitadas e `sha256_manifest.json`. A pasta também contém a cópia QVW read-only, que **não deve ser enviada ou commitada**. Para revisão aqui, retornar somente JSONs, CSV e PNGs pertinentes. Não enviar QVDs nem dados brutos.

- Identidade/preservação: PASS apenas com pin correto e 26/26 arquivos iguais antes/depois; cleanup precisa estar confirmado.
- Propriedade: READ_BACK apenas para valor realmente lido; ausente/coleção sem interface comprovada = INCONCLUSIVE.
- Motor: reconciliação restrita aos valores e estados da matriz. Primeiro valor/seleção/guarda divergente ⇒ STOP.
- Rótulo/aviso: PNG_CAPTURED não é VISUAL_ACCEPTED; um revisor deve conferir categoria/texto/valor e mensagem contextual.
- Estrutura física inteira, segunda expressão CH04, todas as dimensões e rotas nativas não são certificados automaticamente por este executor.
- Maior conclusão automática possível: `ENGINE_CHECKS_RECONCILED_OTHER_PROOFS_PENDING`, nunca global, científico, docente ou produção.

## Validação e STOP da preparação

Os scripts devem estar commitados no repositório canônico **antes** de qualquer execução, inclusive testes sintéticos locais. `tools/test_review_sad_vis05_inspection.py` testa evidências sintéticas: bytes alterados apesar de flags positivas, seleção errada, guarda falsa/verdadeira, expressão alterada, objetos duplicados, caso ausente e distinção entre dados numéricos e aprovação visual. Isso valida o revisor, não o QlikView.

O parser PowerShell 5.1, COM e GUI precisam ser validados no Windows; a execução física não ocorreu no ambiente cloud. Resultados efetivos de testes e commit de publicação serão registrados em adendo próprio, sem inventar PASS antecipado.

**STOP da preparação:** fontes versionadas e Draft PR disponível; primeiro retorno necessário é a saída Inventory. Sem merge, nova recarga, mudança no PDF ou avanço automático para correção.

## Verificações da preparação cloud

Fontes publicadas no repositório canônico antes da execução de testes: commit `3543c0c4852f2a7f1ccbb209d52188fcc19023e8`. Sobre cópia Git desse commit, `python -m unittest discover -s tools -p test_review_sad_vis05_inspection.py -v` retornou **10/10 OK**, e `git diff --check` não apontou erro. São testes de evidência sintética; não executam QlikView ou os dados reais.

O parser oficial PowerShell **7.4.6 em Linux** leu o runner desse commit sem erro. Isso é evidência sintática do parser disponível, não execução do PowerShell 5.1/COM/GUI no Windows. A revisão posterior acrescenta apenas detecção de gráficos extras e registro progressivo de objetos/cenário ativo, além desta documentação; o HEAD final deve passar novamente no parser antes da publicação para execução pelo operador.

**Status físico preservado:** `WINDOWS_POWERSHELL_51=NOT_RUN`, `QVW_BYTES_LOCAL_READBACK=NOT_RUN`, `COM_INSPECTION=NOT_RUN`, `SCENARIOS=NOT_RUN`, `VISUAL_LABEL_SORT_REVIEW=NOT_RUN`, `PRODUCTION_APPROVED=False`. Nenhum PASS sintético é herdado como PASS de dashboard.
