# Fase VIII — C2-F | Inventário físico READ-ONLY das rotas de seleção

**Data da preparação:** 21/10/2026. **Baseline:** `main@9dbdef8e3f20b076cc1a07d0c273a981b3ac45e1`.  
**Autorização:** responsável autorizou iniciar o C2-F após o C2-E. **Estado atualizado após stdout do responsável (21/10):** `C2F_PREPARATION=PASS_LOCAL_REPORTED_ONLY`, `C2F_PHYSICAL_INVENTORY=NOT_RUN`. Sem PASS físico até evidência local real.

## 1. Objetivo, fonte, limites e STOP

Identificar, em **uma** cópia descartável do QVW experimental C2-D1, as rotas de seleção realmente expostas no QlikView 12: objetos de lista de ano/competência, botões BU01/BU02, suas ações e condições, outros objetos de seleção, buscas, bookmarks e triggers. Diferenciar PRESENT, NOT_FOUND_IN_SCOPE e UNKNOWN sem interpretar ausência de identificador UIA/Win32 como ausência de objeto. **Não clicar para selecionar, disparar bookmark, executar ação, avaliar novos KPI, recarregar ou salvar QVW.** Navegação de menus e janelas de propriedades é permitida somente para leitura; sair por Cancelar.

Fonte de verdade lida: AGENTS → current-state → requirements → Boundary 7 → C2-E → C2 closeout → C2-D/D3 → automação QlikView; material histórico do PR #122 em sua branch preservada. QlikView 12 e a semântica V2 §62 permanecem obrigatórios. Não iniciar C3/C4, Fase IX ou alterar 3 fatos/8 dimensões.

**Níveis:** preparação local não é inventário físico. Inspeção humana de propriedades/PNG não equivale a interceptação comprovada de todas as seleções. Os testes C2-D1 (D2-1 e D2-3 pares pré/pós; D2-2/D2-4 imagem única mais relato) e o NO-GO da sonda C2-D3 ficam preservados, sem reexecução.

## 2. Insumos concretos da estação Windows

- **QVW de origem comprovado historicamente:** `%TEMP%\SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw`.
- **Hash SHA-256 da origem no C2-D3:** `31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087`.
- **Script novo versionado antes de qualquer execução Windows:** `tools/Prepare-SadPhaseViiiC2fReadonlyRoutes.ps1`; a versão exata executada será identificada por `VERSIONED_GIT_HEAD` e `RUNNER_SHA256`.
- O arquivo deve ser encontrado **pelo caminho e hash**, não reconstruído por recarga ou por cópia aleatória. Hash diferente ou origem ausente = STOP e coleta de informação, sem ignorar o pin.
- **Proteção:** os 22 QVDs locais e `EXTRACAO/EXT.qvw`, `TRANSFORMACAO/TRANSF.qvw`, `PAINEL/PAINEL.qvw` são hashados antes/depois. O script só cria cópia em novo `%TEMP%\SAD_VIII_C2F_<GUID>` e manifesto em diretório persistente `EVIDENCE_ROOT` fora do Git.
- A cópia temporária se destina a inspeção humana; não é arquivo canônico, não altera dados/fatos nem contrato da Link Table.

## 3. Roteamento operacional

- **Agente primário:** Codex Local no Windows autorizado, para versão, parser e preflight; **fallback:** responsável em PowerShell 5.1 e QlikView Desktop 12; ChatGPT revisa os arquivos exportados.
- **Modelo/esforço local:** não observado nesta sessão; registrar o nome e esforço efetivamente selecionados no Codex se usado. Aqui, ChatGPT GPT-6 e GitHub para revisão/commit.
- **Ambiente acessível nesta preparação:** GitHub e sistema Linux de auditoria; **sem acesso ao computador Windows/QlikView do responsável**. Não declarar `PARSER=PASS` ou resultado COM local sem retorno do executor.
- **Permissões:** documentar/versionar preparo; executar no Windows somente em cópia, sem COM nem seleções via script; criar manifesto e PNGs fora do Git.
- **Proibidos:** `git clean`, `reset --hard`, checkout com descarte de mudanças, sobrescrita QVD/QVW, recarga, SAVE, UIA/Win32 reexploratório, clique por coordenadas, merge automático.
- **Orçamento:** um preflight e uma preparação/cópia; uma revisão humana controlada de menus/objetos. Primeira falha = STOP.
- **Saídas:** stdout, manifesto JSON e capturas das propriedades; eventual `COM_ONLY_NOT_UI_CLICK` é **novo subescopo**, não implementado neste runner.
- **PASS limitado:** origem pinada, 22 QVDs/3 QVWs antes-depois preservados, cópia íntegra, manifesto e objeto(s) observados com evidência.
- **BLOCKED:** SHA divergente, QVW ausente, gate sem ambiente, parser falhou, escrita em artefato protegido.
- **INCONCLUSIVE:** UI não abre, propriedades inacessíveis, ausência de captura, superfície não enumerável.
- **STOP:** evidência do inventário produzida ou primeiro bloqueio; não extrapolar a `P5_D2_UI=APPROVED`.

## 4. Procedimento local — Codex/PowerShell

Na raiz do clone Windows, sem apagar QVW/QVD ou arquivos não rastreados:

```powershell
git fetch origin
git status --short
git switch --track origin/test/phase-viii-c2f-readonly-route-inventory-20261021
git pull --ff-only

$script = (Resolve-Path .\tools\Prepare-SadPhaseViiiC2fReadonlyRoutes.ps1).Path
$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $script, [ref]$tokens, [ref]$errors
)
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { $_.ToString() }
    throw "PARSER=BLOCKED"
}
"PARSER=PASS"

$source = Join-Path $env:TEMP "SAD_VIII_C2D1_a3f6cfc1aab84e8c8f2a4e0681e21dfe\SAD_C2D1_D2_BUTTON_TEST.qvw"
$evidenceRoot = Join-Path $env:USERPROFILE "Documents\SAD_C2F_EVIDENCIAS"

powershell.exe -NoProfile -File $script -Root (Get-Location).Path -SourceQvw $source -EvidenceRoot $evidenceRoot -Prepare
```

**Segurança:** se a branch local já existir, usar `git switch test/phase-viii-c2f-readonly-route-inventory-20261021` em vez de `--track`; confirmar `git status` e parar diante de colisões, sem usar limpeza forçada. Não imprimir `PARSER=PASS` depois de uma falha. Não alterar o script local para contornar hash ou checagem.

**Uma execução bem-sucedida retorna** `VERDICT=PASS_LOCAL_PREPARATION_ONLY_NOT_C2F_PHYSICAL_INVENTORY`, `RUNTIME_TEMP_COPY` e `EVIDENCE_ROOT`; **não significa que o C2-F tenha PASS**.

## 5. Roteiro de inspeção visual sem modificar o estado de seleção

Abrir **somente** `RUNTIME_TEMP_COPY` no QlikView Desktop 12, sem recarga/salvamento. No menu, acessar **Propriedades do Documento → Folhas** (lista de folhas/objetos) e **Propriedades da Folha → Objetos**. Para cada folha, capturar a lista de IDs, tipos, títulos e condição de exibição, inclusive objetos ocultos quando listados. Em seguida, apenas **inspecionar propriedades** (fechar com Cancelar) de:
1. `BU01` e `BU02`: condição para habilitar, ações/Select in Field, campo de destino e possível condição de exibição;
2. listboxes/multiboxes de `PERIODO_ANO` e `PERIODO_COMPETENCIA`: ID, campo, `Read Only`, busca e visibilidade;
3. outros objetos/botões que possam selecionar, limpar, restaurar ou trocar contexto temporal;
4. **Propriedades do Documento → Triggers** e menus de bookmarks/busca: documentar apenas sua presença/configuração; **não executar** bookmarks ou pesquisas que alterem seleção.

Registrar imagens com janela e contexto visíveis no `EVIDENCE_ROOT`. Um clique apenas para abrir uma janela de **propriedades** é navegação, não a ação de seleção que este gate proíbe. Se o QVW apresentar macro de abertura, diálogo incerto, asterisco de alteração não esperada ou ação involuntária, fechar a cópia sem salvar, registrar `INCONCLUSIVE` e STOP.

| Rota | Valor a registrar |
| --- | --- |
| Folha/objeto | `SheetID`, `ObjectID`, tipo/título, visível/oculto |
| BU01/BU02 | campo selecionado, condição de habilitação, ações configuradas |
| Listas ano/competência | presente/ausente no escopo, `Read Only`, busca, outros pontos de entrada |
| Bookmarks e busca | existe, acesso efetivamente exposto, nenhuma ação disparada |
| Triggers e ações alternativas | nome/tipo/configuração observável, sem inferir execução |
| Resultados não inventariáveis | `UNKNOWN` e motivo, sem substituir por `ABSENT` |

## 6. Critério de aceite e encerramento

O pacote de prova física só poderá ser classificado `C2F_ROUTE_INVENTORY=PASS_READONLY_BOUNDED` após conferência do stdout, SHA e screenshots/propriedades correspondentes às rotas **efetivamente vistas**. Caso não haja cobertura de todos os pontos da interface, concluir `COMPLETED_WITH_UNKNOWN_ROUTES` e propor decisão mínima, não executar sondagens adicionais neste gate.

**Estados inalterados independentemente do preparo:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. **A integração desta branch/PR exige revisão separada após o resultado físico.**

## 7. Preparo Windows reportado pelo responsável — uma execução (21/10/2026)

**Proveniência:** stdout textual copiado pelo responsável nesta conversa, juntamente com relato de que conferiu o manifesto local. **Os bytes do manifesto, o conteúdo do QVW e os 25 arquivos protegidos não foram enviados para auditoria independente neste gate.** Portanto, os resultados descritos abaixo são `PASS_LOCAL_REPORTED_ONLY` e não `INDEPENDENT_ARTIFACT_AUDIT`.

| Item reportado | Valor |
| --- | --- |
| Branch | `test/phase-viii-c2f-readonly-route-inventory-20261021` (declarada limpa) |
| HEAD realmente executado | `19828e38d8c8d50970f2ba245706cbb01514e703` |
| Parser real Windows PowerShell 5.1 | `PARSER=PASS` (relato fora do stdout integral do runner) |
| Executor SHA-256 | `EFF03F1DF5B7EEB51845B28142133FE52135124F3BD7D15EE842E06731DF7F49` |
| QVW de origem SHA-256 | `31B1DD3FD3D5D100104D5B3F80118B7725E16CB76F13676A6678E5E9B31AF087` |
| Inventário protegido | `PASS_22_QVD_3_CANONICAL_QVW` |
| Política de execução | `INPUT_EVENTS=0 QLIK_COM_CALLS=0 NO_RELOAD_NO_SAVE_NO_STORE=True` |
| Integridade final reportada | `ORIGINAL_22_QVD_3_CANONICAL_QVW_AND_SOURCE_SHA256_UNCHANGED=True` |
| Processo de preparação | Uma execução `-Prepare`, exit code `0` |
| Veredito literal | `PASS_LOCAL_PREPARATION_ONLY_NOT_C2F_PHYSICAL_INVENTORY` |

**QVW temporário preparado (saída textual):**
`C:\Users\pedro\AppData\Local\Temp\SAD_VIII_C2F_ed031b28b1564486af78785e53a01886\SAD_C2F_ROUTE_INVENTORY_COPY.qvw`.

**Evidência persistente informada:**
`C:\Users\pedro\Documents\SAD_C2F_EVIDENCIAS\SAD_VIII_C2F_ed031b28b1564486af78785e53a01886`.
Manifesto informado: `c2f_prepare_manifest.json`, com 25 arquivos e hash da cópia igual ao de origem, segundo conferência do responsável. Arquivos não abertos neste ambiente.

**Decisão documental restrita:** `C2F_PREPARATION=PASS_LOCAL_REPORTED_ONLY`; `C2F_PHYSICAL_INVENTORY=NOT_RUN`. A preparação está encerrada, **não reexecutar** `-Prepare` para repetir o PASS. O próximo passo **dentro do mesmo gate autorizado** é abrir **somente a cópia temporária** para inspeção humana *sem seleção*, observar propriedades e registrar screenshots. Sem COM, sem nova automação de acessibilidade, sem reload/save. A inspeção deve permitir classificar cada rota em `PRESENT`, `NOT_FOUND_IN_SCOPE` ou `UNKNOWN`, sem extrapolar para aprovação geral de D2/P5.

**Invariantes após o relato:** PR #146 continua Draft e não integrado; `P5_D2_UI=NOT_TESTED`, `C2_FULL=NO_GO_NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED` e `PRODUCTION_APPROVED=False`. Encerrar o gate após o inventário real ou o primeiro bloqueio fundamentado.

## 8. Evidência exportada da estrutura QlikView (21/10/2026)

**Origem:** dois arquivos tabulares exportados pelo QlikView, recebidos e lidos independentemente como UTF-8 com BOM e colunas separadas por TAB, mais duas capturas PNG fornecidas pelo responsável e inspecionadas visualmente neste gate. Nível: auditoria de metadados e imagem, **não** COM/seleção/aceite D2.

| Arquivo recebido | SHA-256 apurado sobre os bytes | Conferência |
| --- | --- | --- |
| SAD_C2F_ROUTE_INVENTORY_COPY.qvw.Sheets.tab | BE7DD528EA00A3C3F1DC8A24176D58D4D06C8FF478344F817C500DBA1CF47378 | Uma folha, SH01 / Principal / Visible / 13 objetos |
| SAD_C2F_ROUTE_INVENTORY_COPY.qvw.Objects.tab | 732CD225ED7F41B19A836E83B55C19D77FA21204C043BD470852FB5AA421B555 | 13 objetos de SH01; IDs sem duplicatas |
| image(20261021-132221).png | 2195DFA62E5E42CD73D318C2DF997C878F6434D4B3ED392E8BECDC36F7F961AD | QVW temporário C2-F aberto em QlikView x64 Personal Edition; folha Principal visível |
| image(20261021-132641).png | 2433C1AB3D5E3CB9166422B817E2620CDE0A9F3462205A2F9D9CC481CC4B8BD4 | Propriedades do documento na aba Pastas, lista parcial e contagem 13 |

**Reconciliação física documental:** 2 botões BU01/BU02, 4 listboxes LB01-LB04, 1 tabela simples CH01 e 6 textos TX01-TX06: total 13. Dois textos em modo Normal (TX01/02), quatro com ShowMode Condicional: Oculto (TX03-TX06). Nove objetos com ShowMode Normal. A folha SH01 é a única exportada.

**Rotas visivelmente existentes:** lista LB01 de PERIODO_ANO e lista LB04 de PERIODO_COMPETENCIA, bem como os botões BU01 (proposta de competência 201801) e BU02 (proposta de ano 2019). A listbox LB02 é SERV_COD_DATASUS_6; a LB03 é COD_PROCEDIMENTO. A tabela CH01 tem caption Internacoes por leito SUS medio. O PNG mostra ano 2018 e serviço 250750 destacados em verde, mas isso é estado carregado, não seleção disparada neste gate.

**Limite indispensável:** objetos de lista visíveis são **candidatos a bypass** das rotas por botão, mas o TSV não exporta Read Only, ações, condições ou triggers. Nenhuma prova de clique na lista ou seleção é autorizada/realizada. A ação dos botões e o escopo de bookmarks/buscas também permanecem não inspecionados. Quatro textos condicionalmente ocultos não foram interpretados como aviso efetivo em qualquer estado.

**Status:** C2F_OBJECT_STRUCTURE=PASS_INDEPENDENT_EXPORT_RECONCILIATION; C2F_LISTBOX_YEAR_AND_MONTH=VISIBLE_WITH_READ_ONLY_UNKNOWN; C2F_ACTIONS_TRIGGERS_BOOKMARKS=UNKNOWN; C2F_FULL_PHYSICAL_ROUTE_INVENTORY=IN_PROGRESS_NOT_PASSED. Não há revalidação pós-abertura dos hashes físicos nesta sessão. Preservar P5_D2_UI=NOT_TESTED, C2_FULL=NO_GO_NOT_APPROVED, F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY.

**Próximo passo restrito:** abrir somente as propriedades dos objetos LB01 e LB04 da cópia temporária; registrar campo, Read Only/Somente Leitura, busca e ações se existentes; sair com Cancelar e enviar capturas. Depois, inspecionar BU01/BU02 e triggers/bookmarks sem executar seleções, não repetir UIA/Win32 ou Qlik Reload. O resultado final deste gate dependerá do restante das propriedades observáveis e dos limites explícitos.

## 9. LB01 — propriedade Apenas leitura (captura enviada em 21/10/2026)

**Fonte:** captura original `image(20261021-133440).png`, recebida do responsável e inspecionada visualmente. SHA-256 dos bytes recebidos: `6AD54EBB02EE6418CC2F7C722E460913A8DF340BC712DAEB0D540F3CBDB4FC0E`; dimensões: 794 × 634 pixels. O diálogo é **Propriedades da Lista [PERIODO_ANO]**, aba **Geral**, sobre a janela **Propriedades do Documento** do QVW temporário C2-F.

**Propriedades diretamente visíveis:**
- **ID do objeto:** `LB01`; **Campo:** `PERIODO_ANO`.
- A opção **Apenas leitura** está **desmarcada** (`ReadOnly=False` na configuração visual observada da listbox). `Sempre Um Valor Selecionado` também está desmarcada.
- A seção **Pesquisar** mostra **Modo de Pesquisa Padrão = <usar padrão>** e **Incluir Valores Excluídos na Pesquisa = <usar padrão>**; a captura **não confirma a configuração efetiva de pesquisa herdada nem execução por busca**.
- `Mostrar Alternativas`, `Ocultar Excluídos` e `Modo AND` aparecem desmarcados.

**Interpretação restrita:** a listbox `LB01` é uma **superfície alternativa visível e não configurada como somente leitura** para `PERIODO_ANO`, fora dos botões D2 BU01/BU02. Isto é evidência concreta de um **controle potencialmente editável**, não observação de clique, despacho, seleção efetivamente realizada, nem prova de bypass funcional. O estado carregado mostrado em captura anterior não serve como evento de seleção neste gate.

**Classificação:** `C2F_LB01_YEAR_LISTBOX=PRESENT_READ_ONLY_UNCHECKED_VISUAL`; `C2F_D2_UNCONTROLLED_YEAR_ROUTE=RISK_CONFIRMED_CONFIGURATION_ONLY`; `C2F_LB01_SELECTION_DISPATCH=NOT_TESTED`. O aceite `C2_FULL` e `P5_D2_UI` permanecem NO-GO/NOT_TESTED. **Próximo passo:** sair com **Cancelar**, inspecionar apenas as propriedades `LB04 — PERIODO_COMPETENCIA` sem alterar campos, botões ou seleções; capturar a aba Geral com o estado de `Apenas leitura`. Não executar seleção direta, busca, bookmark, script, COM, reload ou save.
