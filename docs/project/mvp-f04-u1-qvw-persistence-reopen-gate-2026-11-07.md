# SAD MVP — F04-U1/P1: persistência do QVW TEMP após reabertura

**Data:** 07/11/2026. **Gate:** `SAD-MVP-F04-U1-PERSISTENCE-REOPEN-01`. **Estado:** `PROTOCOL_VERSIONED_NOT_EXECUTED`. **Objetivo único:** verificar se a cópia F04-U1 com guardas RES e temporal, validada visualmente antes de fechar, **reabre efetivamente com as mesmas guardas**, sem criar outro QVW, recarregar, salvar ou modificar o arquivo durante a inspeção. Este gate **não** valida reprodutibilidade do construtor, nem C2/C3/C4 globais.

## 1. Fontes de verdade e pré-condição

Lidos na `main`, nessa ordem: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`; complementar `docs/project/qlikview-powershell-automation.md` e [F04-U1](mvp-f04-temporal-context-guard-u1-2026-11-07.md) na branch do PR #226. A aprovação B1 é apenas de escopo, e o PASS GUI do F04-U1 não comprova persistência.

**Arquivo exato:** `%USERPROFILE%\SAD_M1_EVIDENCIAS\SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1\SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw`. Não abrir a QVW M2 de origem, QVW F03 antiga ou `PAINEL/PAINEL.qvw`. Não criar outra cópia e não reexecutar F04.

**Pré-condição operacional:** a configuração F04-U1 foi salva na QVW TEMP no Windows (as capturas anteriores não trazem `*`); é necessário **fechar o documento QVW** antes do primeiro hash. Se surgir aviso de alterações pendentes **por seleções de teste**, descartar as seleções sem salvar; se o operador identificar que a configuração CH05 ainda não estava salva, **STOP** e registrar o fato antes de alterar propriedades. Não abrir o documento em sessão simultânea.

## 2. Verificador estritamente read-only

Script versionado: `tools/Test-SadMvpF04TempPersistence.ps1`; PIN do commit/branch `proposal/sad-mvp-rebaseline-2026-11-07`, worktree limpa, `-Root`, `-EvidenceRoot`, `-ExpectedCommit`, `-Stage Before|After`, `-BaselineSha256` obrigatório em `After`.

O verificador acessa **somente o hash SHA-256 do QVW F04 TEMP exato**. Ele não usa QlikView COM, não inicia GUI, não lê QVDs, não faz Save, não reescreve arquivo, não cria log binário nem altera dataset. O operador deve trazer stdout do `Before` e do `After` para o registro. O resultado `HASH_UNCHANGED_GUI_REVIEW_PENDING` é PASS **de integridade de bytes somente**, não evidência de renderização; `BLOCKED_QVW_HASH_CHANGED` exige STOP, nunca recalcular uma baseline nova para ocultar o desvio.

## 3. Execução delimitada no Windows

1. Fechar o documento QVW F04-U1, sem salvar seleções. Na raiz do repositório, executar `git status --short`, `git pull --ff-only` e confirmar o SHA HEAD do protocolo. Usar `System.Management.Automation.Language.Parser.ParseFile` para validar o verificador antes de executá-lo.
2. Com a QVW fechada, executar `-Stage Before`. Guardar **exatamente** `F04_TEMP_QVW_SHA256` reportado como baseline e o nome de arquivo. Se `BASELINE_CAPTURED_REOPEN_PENDING` não aparecer, STOP.
3. Abrir **exatamente o mesmo QVW F04 TEMP** no QlikView Desktop 12; não fazer Reload e não editar objetos. Conferir três abas e `Seleções Atuais` vazia. **S_OK_REOPEN**: captura da folha 2 com CH04 duas séries, CH05 barras, ilha P23 três categorias e seleções vazias.
4. Na folha 1, clicar uma vez na barra `2018` do gráfico anual M1-01; verificar `Seleções Atuais=PERIODO_ANO: 2018`, navegar à folha 2 e capturar **S_TIME_REOPEN** com CH05 exibindo motivo temporal 201912, CH04 meses 201801..201812, P23 preservada. Limpar filtros.
5. Na folha 3, selecionar somente `RES_COD_DATASUS_6=251370` na primeira coluna POP; navegar à folha 2 e capturar **S_RES_REOPEN** com `Seleções Atuais`, aviso de residência em CH04 e CH05, P23 visível. Limpar filtros novamente.
6. Fechar o QVW **sem salvar nada novamente**. Se perguntar para salvar seleção, responder **Não**. Não usar `Save As` nem criar outro artefato.
7. Executar `-Stage After -BaselineSha256 <hash do Before>` e exigir `PERSISTENCE_VERDICT=HASH_UNCHANGED_GUI_REVIEW_PENDING`. Enviar as **três capturas** e os **dois outputs** do verificador ao agente. Caso haja falha em qualquer passo, STOP e fornecer erro/captura sem repetir a sessão inteira.

**Não usar** comandos `Get-FileHash` avulsos como substituto da ferramenta versionada para sustentar o gate. O script `After` apenas confirma não mutação enquanto o operador observou a GUI; ele **não valida** os hashes dos 25 canônicos (já encerrados em M1).

## 4. Matriz PASS / BLOCKED / INCONCLUSIVE

| Controle | PASS restrito | Falha |
|---|---|---|
| Antes/depois | Mesmo arquivo e SHA-256 igual; `HASH_UNCHANGED_GUI_REVIEW_PENDING` | Hash diferente/erro de arquivo = `BLOCKED_FILE_DRIFT` |
| Reabertura verdadeira | O mesmo QVW fechado antes e reaberto mostra 3 abas e gráficos base; Seleções Atuais vazia | Se não reabrir, ou estiver em outro QVW = `INCONCLUSIVE` |
| Guarda temporal persistida | `2018` selecionado e CH05 exibe motivo **201912 incompatível** | Mensagem genérica, barras de 201912 como 2018, fórmula literal = `BLOCKED` |
| Guarda residência persistida | `251370` selecionado e CH04/CH05 exibem motivo **RES**, mantendo P23 | Um aviso sumir, ser temporal sob RES, ou P23 desaparecer = `BLOCKED` |
| Não regressão no neutro | Após reabertura e sem filtros, CH04/CH05 exibem dados e P23 três classes | Objetos vazios ou condições presas = `BLOCKED` |
| Segurança | Nenhum Reload/Save/alteração de QVW canônico | Qualquer gravação/recarga inesperada = STOP |

**Possíveis vereditos:** `F04_U1_REOPEN_PERSISTENCE=PASS_GUI_RESTRICTED_WITH_HASH_INTEGRITY`, `BLOCKED`, `INCONCLUSIVE`. **Não** promover automaticamente `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL`, `C2_GUIDED_R2`, `C3`, `C4`, `LINK_KEY_CONTRACT`, `P5_GLOBAL`, `PHASE_IX` ou `PRODUCTION_APPROVED`.

## 5. STOP / handoff

Finalizar após uma única sequência de `Before → reabrir → S_OK/S_TIME/S_RES → fechar → After`, sem novos testes, clones, COM ou reconstruções. Se passar, a próxima decisão separada será escolher uma **estratégia reprodutível/versionável de aplicar as guardas de CH04/CH05** em builds futuros; persistência do binário TEMP e reprodutibilidade do builder são gates distintos. A `main` e os contratos V2/V3/Boundary 7 permanecem intactos. PR #226 continua Draft e sem merge.
