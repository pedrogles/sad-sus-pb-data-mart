# VIS-05 — Gate de inspeção física sem recarga

## Handoff vigente — revisão manual focalizada preparada em 15/11/2026

Este adendo prevalece sobre comandos históricos de Inventory/Scenarios/WindowDiagnostic abaixo. Auditoria G0–G5 encerrada com ressalvas; correções de PDF/QVW ficam para depois da revisão. Main revalidada em `5486ad9f50744769e85107132eae009529ac75cc`; esta preparação permanece na Draft #243, sem merge. A sequência de pedido do responsável foi terminar a revisão antes das correções e prosseguir com sua preparação. **A execução Windows deste modo novo ainda não ocorreu.**

### Contrato do próximo passo

- ID: `SAD_VIS05_MANUAL_VISUAL_01`. Objetivo: categoria/rótulo/valor de CH07 sob seleção/ordem e texto visível dos avisos CH05/CH09. STOP após uma coleta ou primeira falha; sem correções automáticas.
- Evidência reutilizada: `inspection(3).json`, commit `13f903e53f024e3be4d518d09b88933ecc125985`, pasta `220640_be726f799fa5`: nove primeiras expressões, 23 oráculos e cinco condições reconciliados. Não repetir esses gates. As verificações de seleção/reset abaixo identificam o contexto da nova imagem, sem revalidar medidas.
- Diagnóstico encerrado: `inspection(4).json` / `225216_a659fc4a9353`, commit `73b7e95`: GetWindowRect `-8,-8,1696,1018`, VirtualScreen `-1920,0,3600,1050`, DWM visível `0,0,1680,1002`; bloqueio bruto OUTSIDE_VIRTUAL_SCREEN. Não reiniciar foco/DPI, não chamar captura automática nem homologá-la por esta rota.
- Agente preparador: ChatGPT Work, runtime Codex; identificador exato do modelo/esforço não verificável. Linux/Git disponíveis; nenhum subagente, modelo alternativo ou execução QlikView cloud. Destino: operador no Windows com QlikView 12, execução física a registrar.
- Escopo: modo `ManualVisual` no executor existente, com pin/locks/cópia read-only/26 hashes/cleanup preservados. Nenhuma nova API de captura, inventário dos gráficos ou probes de medidas/guardas. Não há nova pergunta de arquitetura ou modelagem.
- Permissões deste modo: selecionar/limpar os estados delimitados em memória, ativar folhas e reverter uma vez a ordem do CH07 pela GUI da cópia. Capturas manuais para evidência. Proibidos Reload, Save/SaveAs, renomear textos, mudar dimensões/expressões/guardas/associações, alterar originais/PDF ou fazer merge. Usar `-Inspect` explicitamente.
- EVIDENCE_ROOT: `%USERPROFILE%\SAD_VIS05_INSPECTION_EVIDENCIAS`, pasta única criada pelo runner fora do Git/TEMP. Cópia descartável read-only dentro dessa pasta, para manter a proteção/cleanup já implementados. Não enviar ou versionar QVW/QVD.
- PASS da preparação: fonte commitada, parser e teste sintético do protocolo; não equivale a PASS visual/COM. HARD_STOP: pin/seleção/hash divergente, escrita indevida ou problema informado pelo operador. INCONCLUSIVE: PNG ausente, categoria/valor ilegível, ordem não demonstrada ou mensagem sem prova. Captura coletada nunca aprova pixels automaticamente.

### Modo ManualVisual — uma sessão, cinco casos / seis PNGs

Não usar `-Capture` nem `-ManualSortReview`: são recusados neste modo. O runner não chama CaptureSheet, Win32/DWM ou mecanismo alternativo de screenshot. Reutiliza SelectState somente para reset/identificação da seleção, abre a aba e aguarda o operador salvar um PNG com nome exato na pasta indicada. Após a resposta, confere existência, assinatura/IHDR e hash do arquivo e se a seleção continua igual. Esses controles não provam conteúdo visual ou identidade da janela nos pixels: o revisor deve conferi-los.

| Etapa / arquivo | Ação e prova humana necessária | Resposta ao terminal |
|---|---|---|
| `V1_BASELINE.png` | Sem filtros; CH07 na ordem original. Código/categoria, rótulo e valor devem ser inequívocos: EQ/mesmo município/294.635, NE/município diferente/260.454. | `CAPTURED` |
| `V1_SORT.png` | Inverter somente a ordem do CH07 na GUI da cópia; provar que as barras realmente trocaram de posição e se os textos acompanharam as categorias. Não editar os rótulos. | `SORT_CHANGED` |
| `V2_EQ.png` | Runner seleciona somente EQ; restaurar a ordenação original antes da captura. Provar categoria, rótulo e valor 294.635. Não interpretar leitos/população. | `ORDER_RESTORED` |
| `V3_NE.png` | Somente NE; conferir categoria, rótulo e valor 260.454. | `CAPTURED` |
| `V4_YEAR_2018.png` | Somente ano 2018; mostrar CH05 completo e seleção. Transcrever aviso que deve explicar ranking fixo dezembro/2019 versus 2018; genérico sem dados não basta. | `CAPTURED` |
| `V5_SERV_250750.png` | Somente SERV 250750; mostrar CH09 completo e seleção. Transcrever aviso de incompatibilidade SERV/população e orientação de limpar SERV. | `CAPTURED` |

Antes de cada etapa o runner limpa e confirma as seleções. Abra a janela Seleções Atuais para incluí-la nas capturas, junto ao objeto inteiro e identificação da cópia. Use captura manual do Windows, salvando **PNG** no caminho exibido. Tooltip legível pode demonstrar o valor; não deduzir valor pela altura/cor da barra. Se o detalhe não couber, manter o frame de contexto e adicionar PNG de detalhe na mesma pasta, identificado pela etapa.

`CAPTURED`, `SORT_CHANGED` e `ORDER_RESTORED` são relatos de ação, não PASS. Se vir rótulo errado, mensagem genérica/truncada, ordenação que não muda ou qualquer incerteza, salvar a imagem do problema e responder `STOP`. A primeira divergência encerra a tentativa; não corrigir na sessão. O JSON preserva a etapa e a imagem existente. Ao terminar, o runner fecha sem salvar, verifica os 26 protegidos/cópia e cleanup. Não executar novamente se houver bloqueio; devolver a evidência.

### Comando após conferir o commit publicado

Na cópia de código de inspeção já usada pelo operador (não na clone com QVDs), atualizar sem descartar alterações locais. Fechar QlikView antes de começar. O hash exato da preparação será fornecido no handoff; não usar outro HEAD silenciosamente.

```powershell
git pull --ff-only origin test/sad-vis05-readonly-inspection-2026-11-15
$code = (Get-Location).Path
$artifacts = Join-Path $env:USERPROFILE 'documents\programming\sad-sus-pb-data-mart'
$head = (git rev-parse HEAD).Trim()
# Conferir $head com o commit publicado no handoff antes de executar.
powershell.exe -NoProfile -File .\tools\Inspect-SadVis05ReadOnly.ps1 `
  -Root $code -ArtifactRoot $artifacts -ExpectedCommit $head -Mode ManualVisual -Inspect
```

Não executar o revisor numérico existente sobre esse retorno: ele valida Inventory/Scenarios e não foi adaptado para aprovar ManualVisual. Devolver `inspection.json`, `sha256_manifest.json` e os PNGs manuais pertinentes; sem binários QVW/QVD. Somente revisão humana pode atribuir PASS_VISUAL_RESTRICTED por caso. Ordenação/categoria/valor ou texto não verificável mantém INCONCLUSIVE; divergência material mantém BLOCKED. A partir do relatório consolidar as correções, sem aplicá-las automaticamente.

Auditoria/prontidão preservadas: `AUDIT_COMPLETE_WITH_RESERVATIONS=True`, `SUBMISSION_APPROVED=False`, `MANUAL_VISUAL_WINDOWS=NOT_RUN`, `VISUAL_DYNAMIC_LABELS=INCONCLUSIVE`, `PRODUCTION_APPROVED=False`. Confirmações docentes sobre arquivos e três folhas/painéis, ensaio online e submissão continuam pendentes.

### Validação efetivamente realizada após publicação

Publicação explicitamente autorizada pelo responsável. O push via terminal falhou por ausência de credencial; os mesmos três arquivos foram publicados pelo conector GitHub. A árvore remota `dea72ba5f1c663de4b0e310828f389349819bf59` é idêntica à do commit local `d92ddb6`; o commit publicado é `2c6a7525e0923b62fa25ac7c43c3f19b6de64cb3` (metadados de commit diferentes, conteúdo igual).

Sobre checkout desse commit publicado, PowerShell **7.4.6/Linux** executou `tools/Test-SadVis05ManualVisual.ps1 -RunnerPath tools/Inspect-SadVis05ReadOnly.ps1`: **PASS** para parser, plano delimitado, isolamento estático do modo manual, identificação/rejeição de arquivos PNG e quatro casos sintéticos do protocolo (coleta, imagem ausente, seleção alterada, STOP do operador com evidência preservada). `git diff --check` sem erro. O teste extrai funções do AST; não executa o corpo do runner, COM, Win32, QlikView ou dados reais.

Blobs publicados conferidos no checkout: runner `538ab602db64a489db6da7175acc0c58cc23e779`; teste `863b2b78e61c55306f09ef7254b508d97d2cdccd`. Este registro altera somente documentação; não requer repetir os testes das mesmas fontes. Windows PowerShell 5.1, comportamento COM das pausas e revisão de pixels continuam **NOT_RUN**. Próximo retorno: uma coleta ManualVisual pelo operador, sem Capture/ManualSortReview, ou o primeiro erro com JSON/cleanup. Nenhum teste numérico antigo foi reexecutado.

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

**Conferência final efetivamente executada:** runner do commit `21f9f7322b88934ecca69b5ba600c766c91bd2f0`, Git blob `7186983bc2184296db1d26e15fe3ca12ba7c3a5a`, comparado entre bytes locais e GitHub, retornou `FINAL_PARSER_PASS=True PowerShell=7.4.6`. O commit que registra esta frase altera somente documentação; esse blob do runner e os arquivos do revisor/testes permanecem os mesmos. Preparação disponível para **Inventory local**, sem declaração de compatibilidade física 5.1/COM.

**Status físico preservado:** `WINDOWS_POWERSHELL_51=NOT_RUN`, `QVW_BYTES_LOCAL_READBACK=NOT_RUN`, `COM_INSPECTION=NOT_RUN`, `SCENARIOS=NOT_RUN`, `VISUAL_LABEL_SORT_REVIEW=NOT_RUN`, `PRODUCTION_APPROVED=False`. Nenhum PASS sintético é herdado como PASS de dashboard.

## Retorno local Inventory — bloqueio na segunda captura (15/11/2026)

**Fonte recebida:** `inspection.json`, 2.922.890 bytes; SHA-256 conferido dos bytes anexados `7C75B53E4008E9D5DCFCEB4E9157EA4C750A0BEEECBE7825B215CCB52680AA8F`. Execução Windows reportada no commit `f8c19c5b6b138fa9920488b322e6159b5b1261e7`, entre `18:06:00` e `18:07:44` UTC−03, modo Inventory. Parser sem erros no transcript; a versão exata do PowerShell não foi impressa. As evidências são readback de relatório local, não abertura independente do QVW no cloud.

### Resultados reaproveitados — não refazer Inventory

- Fonte e cópia final reportam o pin QVW `B56D0A85...084DBB`.
- Antes/depois: **26/26** paths, tamanhos e hashes correspondentes; `integrity_verified=true`, `cleanup_ok=true`, `cleanup_errors=[]`.
- **9/9** objetos CH01–CH09 encontrados nas três folhas; **9/9 primeiras expressões** efetivamente lidas e correspondentes ao contrato.
- CH09: `UsePartialSum=false`, coerente com No Totals.
- CH04: guarda RES lida; CH05: guarda RES + ano compatível com 2019 + competência compatível com 201912 lida; CH09: guarda SERV + competência mensal lida. Isso prova presença da condição, não seu comportamento em cenário nem legibilidade da mensagem.
- `INVENTORY_sheet0.png` foi registrado com SHA `CF92FCD890E84B43E75C117DC4524A10BD0B219CAA9D12A85E5CE72333EE947A`; os pixels não vieram no anexo e não recebem aprovação visual.
- `scenarios=[]`: nenhuma seleção de teste foi executada. Tabelas físicas, mensagens de override e rótulos dinâmicos continuam sem certificação.

Os pins do script/contrato constantes do JSON conferem com as respectivas fontes Git após checkout CRLF: script `0538215DB5BEA297F649B3459EA1FB8518971BCC7485060A983412D38EFED9BC`; contrato `177C70EBF2730BAD4E56A7ECE2EAC34ECBBC00389FE60E1B1C1A713046E6BDF2`. Os hashes LF do cloud diferem, como esperado; não há evidência de edição indevida. A avaliação pelo revisor versionado, usando os bytes CRLF correspondentes, encontrou **somente** `RUNNER_BLOCKED:Foreground is not the inspection window`, além dos limites já previstos; não apontou divergência de expressão ou integridade.

### Causa delimitada e correção do executor

Falha observada: depois da primeira captura, a checagem de primeiro plano falhou. O executor anterior descartava o retorno de SetForegroundWindow e exigia igualdade entre o handle ativo e MainWindowHandle após 800 ms. Não registrava o handle/processo observado naquele ponto; portanto, não se identifica retrospectivamente qual janela estava ativa nem a causa OS exata.

Fonte primária: [Microsoft — SetForegroundWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setforegroundwindow) documenta retorno falso e restrições de mudança de foco; [GetForegroundWindow](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getforegroundwindow) pode retornar outro handle ou zero durante transição. Essas possibilidades explicam o limite do mecanismo, sem provar qual delas ocorreu nesta máquina.

Correção única, somente em CaptureSheet: registrar retorno da solicitação de foco, verificar o **PID da janela realmente ativa e o caminho completo da cópia dessa execução**, e, se não corresponderem, oferecer **uma espera de 8 segundos** para o operador clicar na janela correta. `-CaptureFocusSeconds` permite 2–30 segundos. Depois da espera, falhar se PID+cópia não forem ambos confirmados. Permanecem a exigência de um processo Qv, janela visível/grande, retângulo dentro da tela e proibição de captura de outra janela. Não usar bypass de identidade, AttachThreadInput, teclas artificiais, loops de foco ou nova API COM.

Novo teste sintético `tools/Test-SadVis05CaptureIdentity.ps1` extrai somente a função pura de identidade via AST; não executa o runner nem user32/COM. Casos: PID+path válidos, outro PID com mesmo título, outro diretório de execução com mesmo basename, título vazio, PID zero, path esperado vazio e diferença de caixa no path Windows. Deve ser commitado antes de executar; resultado sintético não é teste de foco real.

### Próximo passo autorizado e condição de parada

O inventário de propriedades e integridade recebido é suficiente para **não repetir Inventory**. Após publicação da correção e parser Windows sem erro, executar **uma tentativa Scenarios**, com captura e foco assistido. O preflight e a releitura breve no início continuam necessários para vincular a sessão ao mesmo arquivo/novo executor, sem repetir a tentativa Inventory separadamente.

Quando aparecer `FOCUS_REQUIRED`, clicar na janela QlikView da cópia e aguardar sem voltar ao terminal. Não clicar nos gráficos durante as capturas automáticas. A revisão manual de ordenação é opcional; para este próximo retorno, priorizar os cinco cenários automáticos.

Se ocorrer novo bloqueio, preservar `inspection.json` e os diagnósticos `capture_focus_events`, sem repetir o comando. Não declarar o foco corrigido em Windows antecipadamente. **Sem Reload, Save, correção de dashboard, merge ou mudança na main.**

Atualização qualificada: `VIS05_LOCAL_INVENTORY=PARTIAL_PASS_PROPERTIES_AND_INTEGRITY_REPORT_REVIEWED`, `WINDOWS_PARSER_INITIAL=PASS_OPERATOR_REPORTED`, `CAPTURE=PARTIAL_ONE_RECORDED_IMAGE_NOT_REVIEWED`, `SCENARIOS=NOT_RUN`, `VISUAL_DYNAMIC_LABELS=NOT_APPROVED`, `PRODUCTION_APPROVED=False`. O status bruto da tentativa antiga permanece BLOCKED_OR_INCONCLUSIVE; não foi reescrito nem sobrescrito.

**Validação da correção, após publicação:** commit `27044fad0cefc2986e63b95096b0c860f590f375`. Runner Git blob `f68e769c6faac592e34fbf88950b45ee208d4bcc` e teste `44855d6137be0130d5eeffd4b4823e063cc96cb4` conferidos entre arquivo local e GitHub. O teste versionado executado com PowerShell 7.4.6/Linux retornou **7/7 casos sintéticos PASS**, incluindo parser sem erros. Não chamou COM/user32. A revisão que registra este resultado é somente documental; nenhum PASS de foco/captura Windows é concedido antecipadamente. Os dez testes do revisor Python permanecem referentes às mesmas fontes inalteradas, sem reexecução desnecessária.

## Segundo retorno — checagem textual de ClearAll bloqueada (15/11/2026)

Transcript do operador: checkout `601b097a1159726ca29cb310dd90ae98b42787a3`, parser sem erro, modo Scenarios. Nova pasta reportada `VIS05_INSPECT_20261115_183733_3c5b97c11720`; resultado `DETAIL=ClearAll left selections: -`, `VERDICT=BLOCKED_OR_INCONCLUSIVE`. O JSON desta segunda tentativa ainda precisa ser recebido para confirmar integridade e cleanup, independentemente da tentativa anterior. Não herdar o PASS de preservação do primeiro relatório para o segundo.

**Defeito localizado no executor:** SelectState tratava qualquer texto não vazio de `Evaluate(GetCurrentSelections(...))` como seleção residual. O retorno `-` observado foi suficiente para bloqueá-lo, sem uma checagem numérica independente. O transcript não prova por si só se havia ou não uma seleção real. A falha ocorreu antes dos probes do primeiro cenário, portanto o foco corrigido ainda não foi exercitado em Scenarios.

Correção exclusiva do preflight de seleções: registrar o resumo bruto, contar numericamente registros do resumo pelo separador de tag explícito `=`, e consultar `GetSelectedCount(campo,True())` para os cinco campos autorizados. Só aceitar vazio/traço quando a contagem global de registros for exatamente `0` **e** os cinco contadores estiverem presentes e iguais a `0`. Traço em um contador numérico, campo não lido ou seleção residual continuam bloqueando. Nenhum dado, condição de gráfico ou oráculo é alterado.

Fontes primárias: [QlikView GetCurrentSelections](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/ChartFunctions/FieldFunctions/getcurrentselections.htm) define saída textual e tag_sep; [GetSelectedCount](https://help.qlik.com/en-US/qlikview/September2025/Subsystems/Client/Content/QV_QlikView/ChartFunctions/FieldFunctions/getselectedcount.htm) define contagem e include_excluded. Não se toma a documentação como prova de que o traço no ambiente local representa estado vazio; a decisão fica condicionada aos novos contadores.

Novo teste `tools/Test-SadVis05SelectionReset.ps1`: oito casos sintéticos para vazio válido, traço confirmado numericamente e rejeição de traço com registro/filtro residual, contagem ilegível, campo ausente ou resumo com seleção. Extrai somente a função pura do AST; não executa corpo do runner/COM. Deve ser commitado antes da execução. Testes de revisor e identidade de janela não são repetidos, pois suas fontes não mudam.

**STOP antes de novo teste físico:** receber `inspection.json` da pasta `183733_3c5b97c11720`, conferir a preservação/cleanup da tentativa bloqueada e revisar o novo commit. Não prescrever nova repetição de Scenarios apenas com base no traço. Nenhuma conclusão sobre filtros ou rótulos foi aprovada por essa tentativa.

## Discovery delimitada de geometria e fechamento dos cenários (15/11/2026)

**Baseline canônica reconsultada:** `main@5486ad9f50744769e85107132eae009529ac75cc`. Esta seção e o executor permanecem na branch Draft #243; não integram a main.

### Evidência recebida e reconciliada

- Segunda tentativa `183733_3c5b97c11720`: JSON SHA-256 `272B4F320E59ED26B4AE172AD3AE8966DEB17B0789B3EDCC3B276364D62C4D20`. 26/26 arquivos preservados, cleanup correto. Checagem textual bloqueou antes de cenários. O STOP anterior foi atendido.
- Terceira tentativa `213945_da92173b1e5a`, commit `13f903e`: fonte/cópia no pin, 26/26 arquivos preservados e cleanup correto. Reset numericamente vazio comprovado; PID e caminho completo da cópia confirmados. Falha `Window minimized, clipped or too small`, sem coordenadas registradas. **Causa geométrica exata não determinada**; maximização/bordas/DPI são hipóteses, não fatos.
- Quarta tentativa `220640_be726f799fa5`, commit `13f903e`, sem Capture: JSON SHA-256 `52E46EAA0CEB5B6EF5F561C184B3886752906B6FC01B68D449B794C2AEBC3019`. Revisor Python existente reconciliou 9 primeiras expressões, 23 oráculos numéricos e 5 condições contratadas, sem falhas. Cinco cenários e resets comprovados. Hashes CRLF do runner/contrato correspondem ao JSON; 26/26 arquivos preservados, cleanup sem erros, fonte/cópia no pin. `ENGINE_CHECKS_RECONCILED_OTHER_PROOFS_PENDING`. Não repetir estes cenários para diagnosticar a captura.

**Limite semântico real:** nos estados FLOW_NE_ONLY e FLOW_EQ_ONLY, probes `lt_fixed=0` e `pop_2019=0`, com condições CH04/05/09 verdadeiras. São observações fora dos oráculos exigidos nesses estados; não aprovam a compatibilidade do filtro de fluxo com capacidade/população. Não são prova de célula desenhada nem de valor populacional zero. Manter pendência de revisão visual/semântica, sem corrigir modelo, condição ou expressão nesta PR.

### Problema, objetivo e fronteira

Problema técnico: CaptureSheet colapsava largura, altura e contenção em uma única mensagem; não guardava retângulos ou estado da janela. Além disso, em Scenarios, o cenário era anexado ao relatório somente após a captura, perdendo sua evidência quando a captura lançava exceção. Arquivo: `tools/Inspect-SadVis05ReadOnly.ps1`. Objetivo delimitado: colher diagnóstico suficiente em **uma execução sem cenários**, preservar checkpoints e encerrar em handoff do JSON.

Modo novo **WindowDiagnostic**, no runner existente: reutiliza pin, locks, cópia somente leitura, hashes e cleanup; abre a cópia, ativa apenas a primeira folha e consulta a janela. Não enumera novamente os nove objetos, não seleciona/limpa filtros, não avalia probes, não altera ordenação e não gera PNG. `-Capture` é recusado neste modo. Registra posição/tamanho, estado minimizado/maximizado, VirtualScreen, bounds/working area das telas, DPI efetivo disponível e DWM visible frame opcional. Guarda motivo separado para largura <700, altura <500, minimização e retângulo fora do VirtualScreen. Nenhuma redução de limites, recorte automático ou mudança de DPI/posição é realizada.

**Fonte técnica primária:** [Microsoft GetWindowRect](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-getwindowrect) documenta virtualização DPI e bordas invisíveis; DWM extended frame não é ajustado para DPI. [GetDpiForWindow](https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-getdpiforwindow) depende da awareness da janela. Por isso os valores são observacionais, não substituídos automaticamente entre APIs nem convertidos em diagnóstico conclusivo de escala. VirtualScreen é um bounding box e não certifica ausência de lacunas entre monitores, oclusão ou legibilidade.

Persistência em Scenarios: anexar/gravar probes e condições antes de CaptureSheet. Falha posterior ainda resulta em BLOCKED_OR_INCONCLUSIVE, preservando os resultados anteriores sem aprovação visual.

### Critérios e parada

1. Teste sintético versionado antes de executar: `tools/Test-SadVis05WindowGeometry.ps1`; oito casos de fronteira (dimensões mínimas, tela exata, largura/altura insuficiente, borda negativa, excesso à direita, monitor negativo válido e minimização), parser e verificações estáticas do ramo sem seleção/checkpoint. Não substitui Win32/COM real.
2. Windows: executar **somente WindowDiagnostic** no commit fornecido; fechar QlikView previamente. Se houver FOCUS_REQUIRED, ativar a cópia. Não restaurar/mover/redimensionar durante esta primeira observação; queremos registrar o estado que o runner produz.
3. Sucesso de coleta = identidade confirmada, observação de janela registrada, 26 arquivos preservados e cleanup correto. Status `WINDOW_DIAGNOSTIC_COLLECTED_NOT_CAPTURE_APPROVAL` é coleta, não captura homologada; consultar `window_diagnostics[].geometry` mesmo com exit 0.
4. Se APIs opcionais de DPI/DWM estiverem indisponíveis, registrar UNAVAILABLE; não inferir escala. Falha de foco continua bloqueando sem capturar outra janela. Sem recuperação ou retentativa automática.
5. **STOP:** devolver inspection.json. Diagnosticar causa com os valores; somente então definir uma intervenção mínima ou encaminhar captura manual. Sem repetir testes numéricos, ampliar objetos, recarregar/salvar QVW, merge ou alterar main.

### Revisão visual que permanece pendente

Após resolver a coleta: relacionar categoria/rótulo/valor do CH07 nas duas seleções de fluxo e após inversão de ordenação somente na cópia; verificar mensagens efetivamente visíveis em YEAR_2018/CH05 e SERV_250750/CH09; observar apresentação de capacidade/população sob filtro de fluxo. Não presumir rótulos dinâmicos porque o motor respondeu. Asserções numéricas existentes são reutilizadas, não refeitas. Ainda não há modo novo para essas capturas nem aprovação para correções do dashboard.


## Interrupção da sessão manual — conferência posterior preparada em 17/11/2026

**ID:** SAD_VIS05_INTERRUPTED_HASH_CLOSEOUT_01. Main revalidada em 5486ad9f50744769e85107132eae009529ac75cc; preparação na Draft #243. O responsável solicitou prosseguir com a conferência read-only após relatar fechamento do terminal. Não é nova sessão QlikView, auditoria numérica ou correção de produto.

**Evidência recebida:** inspection(5).json, SHA-256 370C8F65AD42934DCB2A8E0385C075AEF439CA35E7A571DB10FB334F0CC63427. Sessão VIS05_INSPECT_20261115_235407_3c3df8cbbcc6, executada em fb1799a340c383b592ba331467eae9daca8a27fc. V1_BASELINE coletada, resumo de seleção vazio antes/depois; V1_SORT aguardando captura. Inventário inicial possui 26 paths; sem protected_after, finished ou copy_sha256_after. Flags false são estado ainda não certificado, não prova de adulteração. O status inicial BLOCKED_PRECHECK permaneceu no checkpoint; não interpretar como falha de preflight, pois as etapas manuais foram alcançadas.

**Visual recebido, separado do checkpoint:** tooltips baseline EQ=294635/NE=260454; após Valor-Y ascendente, NE na esquerda=260454 e EQ na direita=294635. As capturas mostram correspondência restrita na inversão; não certificam seleções EQ/NE nem avisos de V2–V5. Imagens recebidas foram importadas pelo operador com script d1017f0; saída confirma preservação do V1_BASELINE.png original e cópia recebida com sufixo. O JSON interrompido continua sem registrar conclusão de V1_SORT.

**Esperado versus observado:** esperado finally com hashes e cleanup; observado terminal encerrado antes desse registro. Arquivo de origem tools/Inspect-SadVis05ReadOnly.ps1@fb1799a. Pergunta fechada agora: os 26 arquivos protegidos e a cópia permanecem idênticos ao checkpoint, com Qv ausente na observação posterior? Não diagnosticar processo antigo, foco/DPI ou recalcular medidas.

**Executor novo mínimo:** tools/Verify-SadVis05InterruptedSession.ps1. Usa o inventário/pin da sessão; não duplica COM/captura. Leitura de hashes/tamanhos com locks temporários, contagem de 26 paths únicos e 22 QVDs/4 QVWs, comparação da cópia com o pin VIS-05, confirmação do PNG baseline original e hash imutável do JSON. Não encerra processos nem abre QlikView; exige que o operador feche a cópia sem salvar. Grava somente interruption_closeout_DATA_GUID.json novo na pasta da sessão; nunca sobrescreve inspection.json ou hashes anteriores.

**Contrato:** uma execução de conferência Windows, STOP no primeiro retorno. PASS_CURRENT_HASHES_HISTORICAL_CLEANUP_UNVERIFIED significa somente integridade atual verificada e Qv ausente no instante da checagem; historical_cleanup_certified permanece false. Ausência, diferença, erro de leitura/lock ou Qv aberto = BLOCKED_OR_INCONCLUSIVE_POST_INTERRUPTION; não tentar nova sessão QlikView ou retentativa automática. Retornar o novo JSON e console. Reaproveitar capturas válidas; retomada de V2–V5 depende da revisão do closeout, sem repetir V1 ou os cenários numéricos.

**Validação após versionamento:** código publicado antes dos testes; commit 0c1e3e7834728ce16f2be07eebf8716bf2d5a325. PowerShell 7.4.6/Linux: parser, inspeção estática sem operações QlikView/mutação e quatro fixtures de comparação (igual, bytes alterados de mesmo tamanho, tamanho alterado e arquivo ausente) PASS. O teste extrai somente Get-SadSha/Get-SadFileComparison via AST; não roda o corpo do verificador nem acessa Windows/QVD/QVW. A conferência dos 26 arquivos reais, processo Windows e cópia ainda NOT_RUN. Registro documental posterior não altera as fontes testadas.

Ambiente: ChatGPT Work/Linux/GitHub, runtime Codex; modelo/esforço exatos não verificáveis, sem subagente ou escalonamento. Execução local pelo responsável. RUNTIME_TEMP não aplicável ao closeout; EVIDENCE_ROOT é a pasta persistente desta sessão. Sem mudanças de QVW/QVD/QVS/modelo/PDF, merge ou main. Auditoria com ressalvas, produção/submissão não aprovadas e decisões docentes continuam pendentes.


## Closeout recebido e retomada delimitada — 23/11/2026

**Evidência conferida:** interruption_closeout_20261123_111053_774d3fe6.json, SHA-256 9D14608EB57F181DDAF6E2DD9171BE671D4672866FBA3E2140D0ACFA36228293; verificador executado em 3d2531ede24e60e115a7626335cdafc824b7181e, Windows PowerShell 5.1 reportado no console. Reconciliação independente do JSON: 26/26 paths, hashes e tamanhos coincidem com protected_before do inspection(5).json pinado; nenhuma diferença. Cópia no pin B56D0A85…084DBB, 36.238.848 bytes; input_report_unchanged e baseline_capture_matches_checkpoint verdadeiros. Qv ausente na observação posterior, locks desta conferência liberados. Verdict PASS_CURRENT_HASHES_HISTORICAL_CLEANUP_UNVERIFIED. **Não** converte o cleanup não registrado da sessão antiga em PASS retroativo.

As nove imagens na pasta foram inventariadas, incluindo V1_BASELINE original, cópia recebida com sufixo e V1_SORT com dois detalhes. Provas de categoria/rótulo/valor sem filtros e sob inversão permanecem reaproveitadas. Nenhum cenário numérico ou sessão QlikView foi reexecutado pelo verificador. A pendência pós-interrupção de integridade atual está encerrada com esse alcance.

**Próxima execução delimitada:** ManualVisual com StartVisualStep V2_EQ e ResumeCloseout apontando para esse JSON exato. Cria pasta/cópia nova pinada com os controles existentes. V1_BASELINE e V1_SORT não são repetidos. No preflight, o SHA do closeout deve corresponder ao pin acima, com estado aceito; os 26 arquivos são novamente lidos/lockados e comparados com o closeout antes de abrir QlikView. Diferença ou prova ausente bloqueia; não trocar o pin. Os controles de preservação são da nova sessão, não um gate numérico independente.

A cópia nova inicia na ordenação original do QVW fonte, que não foi salva na inversão. Em V2_EQ, **não alterar a ordenação**: observar a classe EQ selecionada automaticamente e capturar categoria/rótulo/valor e Seleções Atuais. A resposta desse caso retomado é CAPTURED (não ORDER_RESTORED). Seguem apenas V3_NE, V4_YEAR_2018/CH05 e V5_SERV_250750/CH09. Primeira divergência ou interrupção: STOP e evidência, sem retentativa automática. Manter o terminal aberto até o relatório final e não salvar/recarregar QVW. Ao terminar, retornar JSON/manifesto/PNGs da pasta nova. Não misturar os relatórios das duas sessões ou reexecutar o revisor numérico para este modo.

**Código/testes:** runner publicado no commit 8fb77ea9265d46c4c49a0c27a92c5da6d51c0586; teste atualizado em a1b4607942b779e7e71781007d5ad9121374d650, antes de executar. PowerShell 7.4.6/Linux: parser, plano padrão e retomado restrito a quatro casos, checks estáticos de validação antes de OpenDoc/comparação com closeout e quatro fixtures do protocolo PASS. A primeira execução do teste estendido detectou falta do parâmetro StartVisualStep no harness de funções extraídas; corrigido somente o teste e reexecutado do commit publicado. Nenhuma falha Windows/COM foi inferida dessa fixture. Resultado sintético não homologa execução Windows da retomada; esta continua NOT_RUN.

Sem novas medidas, guardas, associações, QVS, PDF, merge, main ou correções aplicadas. Auditoria G0–G5 encerrada com ressalvas; coleta visual remanescente e correções finais não confundidas com produção, ensaio, aceite docente ou submissão.
