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


## 6. Resultado local de reabertura — hash íntegro, guarda temporal não confirmada

**Recebido em 07/11/2026:** stdout integral dos estágios `Before` e `After` do script versionado `tools/Test-SadMvpF04TempPersistence.ps1` executado pelo operador no Windows, pinado em `GIT_HEAD=6fb978909798617bd2a4412d8c9cbdd9649e41e4`, e três capturas diretas da janela QlikView x64 Personal Edition do documento F04 TEMP. As imagens foram inspecionadas diretamente pelo agente; a execução do QlikView/PowerShell no Windows continua evidência **reportada pelo operador**. Nenhum COM/Reload/Save foi executado pelo agente.

**Hash de integridade (reportado):**
- `STAGE=Before`, `PERSISTENCE_VERDICT=BASELINE_CAPTURED_REOPEN_PENDING`.
- `STAGE=After`, `PERSISTENCE_VERDICT=HASH_UNCHANGED_GUI_REVIEW_PENDING`.
- Mesmo `F04_TEMP_QVW`: `C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1\SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw`.
- Mesmo SHA-256 dos bytes QVW nos dois estágios: `6310321DB30C1065843B6BFF1A400D2C29D235D4B7C79372453366454EB1B1BD`.
- O `-Stage After` não constatou alteração de bytes **entre os dois testes**, mas **não** valida que a mensagem temporal já estivesse gravada **antes** do Before; o teste de GUI é necessário separadamente.

| Captura GUI no chat | Dimensão e bytes | SHA-256 real do PNG | Verificação |
|---|---|---|---|
| `image(20261107-194133).png` — `S_TIME_REOPEN` | 1907×1068, 220420 | `F97A72B301CCCB0EF10DA44F20A8A4D90E3062451BBB27FCED7CF4DBF7BCC887` | `Seleções Atuais` valor **2018** para campo temporal; CH04 duas séries `201801..201812`; CH05 exibe **“Não há dados para mostrar”**, **NÃO** o aviso de incompatibilidade `201912`; P23 com três barras |
| `image(20261107-194216).png` — `S_RES_REOPEN` | 1907×1068, 216714 | `87EBCAF9D5529CA4D03541C33FD5D68D4B5A64A711E768B078ED4DA219A5F597` | `Seleções Atuais` RES **251370**; CH04 e CH05 exibem o aviso original de residência; P23 mantém três barras |
| `image(20261107-194231).png` — `S_OK_REOPEN` | 1907×1068, 268799 | `656F7FB851F9D1947E2F517AB781BEEAF6C65263DF2AD71C5782726A257F440B` | `Seleções Atuais` vazia; CH04 séries e CH05 barras normais; P23 três barras |

**FATOS VISUAIS:** a mensagem temporal que havia sido renderizada no F04-U1 antes do fechamento **não apareceu nesta reabertura**. O aviso de residência **permaneceu**, e o estado neutro recuperou os gráficos. O título do QVW reaberto aparece sem `*` nas capturas — isso não comprova a persistência histórica das últimas propriedades CH05.

**HIPÓTESE A INVESTIGAR:** a edição temporal CH05 feita no F04-U1 pode não ter sido salva efetivamente antes do `Before` (o operador levantou essa possibilidade). Outras causas localizadas não estão eliminadas: condição combinada não persistida, mensagem dinâmica não persistida ou avaliação diferente após reabrir. **Não afirmar a causa sem ler as propriedades atuais de CH05**, e não repetir automaticamente toda a bateria de testes.

**Classificação:**
- `F04_U1_QVW_SHA_BEFORE_AFTER=PASS_LOCAL_REPORTED_INTEGRITY_ONLY`;
- `F04_U1_REOPEN_S_OK=PASS_GUI_RESTRICTED`;
- `F04_U1_REOPEN_S_RES=PASS_GUI_RESTRICTED`;
- `F04_U1_REOPEN_S_TIME=BLOCKED_GENERIC_NO_DATA`;
- `F04_U1_REOPEN_PERSISTENCE=BLOCKED_TEMPORAL_GUARD`;
- `F04_U1_TEMPORAL_GUARD_ROOT_CAUSE=UNDETERMINED`;
- `F04_U1_FIRST_SESSION=PASS_GUI_RESTRICTED_NOT_REVOKED` (mas não transferível à versão persistida);
- `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`;
- `C2_GUIDED_R2/C3/C4/P5_GLOBAL/LINK_KEY_CONTRACT/PHASE_IX/PRODUCTION=NOT_APPROVED`.

**STOP do gate P1:** encerrado com `BLOCKED` específico, não repetir `Before → reabrir → 3 capturas → After` sem correção causal identificada. **Próximo diagnóstico mínimo, em leitura GUI somente:** abrir o QVW F04 TEMP já identificado, ir à folha 2 → **CH05** → `Propriedades → Geral`, fotografar o conteúdo atual da **Condição de cálculo** e, em `Mensagens de erro`, o campo da categoria **Condição de cálculo não satisfeita**; **não editar nada, não aplicar nem salvar**. Se condição antiga RES e mensagem estática estiverem presentes, favorece causa **edição temporal não persistida**; se condição combinada e mensagem dinâmica estiverem presentes, investigar estado de seleção/evaluação antes de qualquer correção. Registrar só essas duas propriedades, sem executar outra bateria. Nova edição/salvamento exige gate separado com baseline SHA e confirmação pós-fechamento. Não tocar QVD/QVW canônicos ou `main`; PR #226 permanece Draft.


## 7. Causa do bloqueio P1 esclarecida — estado CH05 salvo sem regra temporal

**Data:** 07/11/2026. Recebidas duas capturas de **inspeção somente leitura** das propriedades do mesmo `CH05` na QVW TEMP F04 reaberta, após o bloqueio temporal. O usuário não reportou nova edição/aplicação/salvamento. Hashes dos PNGs calculados a partir dos bytes montados localmente pelo agente.

| Captura | Dimensão | Bytes | SHA-256 | Evidência |
|---|---|---:|---|---|
| `image(20261107-194930).png` | 1901×1068 | 351340 | `0FCAD875968DA5643A6E66B57370C7B614DB5E074EE33B501A4264DE8DFE4C33` | Propriedades → Geral `CH05`: **Condição de cálculo** igual somente a `=GetSelectedCount(RES_COD_DATASUS_6,True())=0`; não há checagem `PERIODO_ANO` nem `PERIODO_COMPETENCIA` |
| `image(20261107-194946).png` | 1904×1068 | 330939 | `8FE27790B251D01949786BF69CD3A311C2A30F344114AB7E22C64DA0421C6CAC` | Mensagens de erro → `Condição de cálculo não satisfeita` `CH05`: aviso **estático** apenas de residência; não há expressão dinâmica `=If(...)` nem aviso temporal |

**FATO VERIFICADO pela GUI pós-reabertura:** o `CH05` salvo/aberto **mantém o F03-U1** (guarda de RES e mensagem estática), mas **não contém** nem a condição temporal combinada nem a mensagem dinâmica da sessão F04-U1. Isso explica diretamente `S_TIME_REOPEN` mostrar `Não há dados para mostrar` sob 2018. **Não** há necessidade de atribuir a falha a Qlik `GetSelectedCount`, Set Analysis 201912 ou Link Table. A versão em disco pode não ter recebido o salvamento da edição F04-U1, como o operador suspeitou; o ato específico que impediu persistência (Save omitido, Cancel no diálogo, etc.) **não foi observado**.

**Atualização causal:** `F04_U1_TEMPORAL_GUARD_ROOT_CAUSE=TEMP_QVW_SAVED_STATE_MISSING_CH05_TEMPORAL_PROPERTIES_CONFIRMED`; `F04_U1_SAVE_MECHANISM=NOT_OBSERVED`; `F04_U1_REOPEN_PERSISTENCE=BLOCKED_TEMPORAL_GUARD` mantém-se até correção com nova evidência. `F03_RES_GUARD=PHYSICALLY_PRESENT_GUI` na versão anterior e `F04_U1_FIRST_SESSION=PASS_GUI_RESTRICTED` permanecem fatos distintos.

**STOP do diagnóstico cumprido:** **não repetir** os três estados F04-U1, não alterar QVW nesta análise, não recarregar e não abrir novas frentes. Próximo gate separado `F04-U1/P2`: **reaplicar exclusivamente as duas propriedades de CH05 na mesma QVW TEMP F04**, salvar explicitamente com seleção neutra, confirmar hash pós-salvamento **diferente** da baseline P1, fechar e reabrir; conferir as duas propriedades persistidas e **um único** cenário temporal `PERIODO_ANO=2018`. Sem reconstruir, sem novos scripts COM e sem reexecutar cenário RES ou neutro como bateria completa. Critérios e STOP serão versionados separadamente, antes de executar. Nenhuma alteração na `main`, QVDs, QVWs canônicos ou builder; PR #226 continua Draft.
