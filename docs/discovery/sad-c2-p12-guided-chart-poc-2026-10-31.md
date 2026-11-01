# SAD C2 — PoC física restrita: novo gráfico P1.2 guiado (2019)

**Gate:** `SAD-C2-P12-GUIDED-CHART-POC-01`.  
**Baseline:** `main@2d205d52ab96eca565e85a9db5cfde14d9d3025c`.  
**Autorização:** responsável, em 31/10/2026, respondeu **"prossiga"** à proposta de implementar experimentalmente a **alternativa A**, em nova QVW TEMP. A autorização cobre **um** objeto de gráfico na nova TEMP, **não** merge, produção, PAINEL canônico, alteração semântica ou novo gate.
**Estado de fechamento (31/10/2026):** `GATE_CLOSED_PASS_RESTRICTED_GUIDED_CHART_2019_12_OF_12`; preservação de fonte e 25 canônicos por `Verify` **reportado localmente**. O roteiro de execução abaixo é histórico e **não deve ser reexecutado**.
**Destino:** operador humano no Windows/QlikView Desktop 12/PowerShell 5.1, ou Codex Local sob a mesma fronteira; ChatGPT/GitHub não executa COM nem GUI Windows.

## 1. Entrada e fontes obrigatórias

Leitura realizada em ordem: [AGENTS](../../AGENTS.md) → [current-state](../project/current-state.md) → [requisitos](../academic/requirements.md) → [Boundary 7](boundary-7-implementation-plan.md) → [contrato UX P1.1/P1.2](sad-p1-p11-p12-ux-contract-2026-10-28.md) → [desenho candidato da alternativa A, PR #204 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/204) → [closeout #203 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/203) e [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196). PRs Draft não são parte da `main`.

**Fonte física pinada (da PoC de BU15):**
- `C:\Users\pedro\Documents\SAD_C2_DYNAMIC_RUNTIME\SAD_C2_DYNAMIC_e474426fc30c473c83019c4cdfaad080\SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw`
- SHA-256 **reportado e já conferido no Windows em #203**: `D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B`. Revalidar novamente antes de qualquer cópia; nenhuma divergência será corrigida artificialmente.
- A fonte já persistia `ANO REAL=2019`, `COMPETENCIA REAL` sem seleção explícita, modo `EVOLUCAO`. Isso foi observado na cópia #203, **não autoriza presumir** o estado na nova TEMP sem abrir e conferir.
- **25 protegidos:** 10 QVDs extração + 12 QVDs transformação + três QVWs canônicos. Nunca salvar esses arquivos nem a fonte TEMP de #201. Preservar manifests de #201/#203 e seus HEADs históricos.

**Risco conhecido:** `CH02` histórico usa `=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)` e exibe 2017–2019 quando 2019 real está selecionado. Não mexer no CH02, KPIs, BU15 ou variáveis. O novo gráfico deve usar somente campos existentes `PERIODO_COMPETENCIA` e `QTD_INTERNACAO`.

## 2. Objetivo único, critério de parada

Criar **um** gráfico de linha *novo* na folha `POC P1.1-P1.2 - Internações` da **nova TEMP**, com dimensão `PERIODO_COMPETENCIA` e expressão candidata `=Sum(QTD_INTERNACAO)`; ativar uma condição candidata de cálculo/exibição para modo `EVOLUCAO` e seleção temporal real consistente, se a propriedade estiver disponível no QlikView 12. Observar 2019 com **exatamente 12 competências** e, se possível, exportar seus valores para reconciliar ao oráculo sem recalcular fatos. O objeto deve receber **novo ID** definido pela aplicação; não reutilizar `CH02`.

**STOP:** uma nova cópia, uma criação de objeto, um único salvamento da nova TEMP quando a configuração estiver completa, uma inspeção do gráfico, exportação de série somente se houver 12 competências, e um `-Verify`. Se houver erro, não mudar expressão, Set Analysis, estado alternativo, botões, modelo, dimensões ou scripts neste gate. Não reabrir pilotos de 36 meses, AE01, C2-J/K, #199, #201 ou #203. Sem reload/COM.

## 3. Preflight PowerShell 5.1 — somente leitura, antes do Prepare

Usar PowerShell **na raiz do repositório**, com QlikView fechado e worktree limpa:

~~~powershell
& {
    $ErrorActionPreference='Stop'
    $branch='test/sad-c2-p12-guided-chart-poc-20261031'
    $current=([string](git branch --show-current)).Trim()
    $head=([string](git rev-parse HEAD)).Trim()
    if ($current -cne $branch) {throw 'BLOCKED_WRONG_BRANCH'}
    if (@(git status --porcelain --untracked-files=all).Count -gt 0) {throw 'BLOCKED_DIRTY_WORKTREE'}
    if (@(Get-Process -Name qv,qlikview -ErrorAction SilentlyContinue).Count -gt 0) {throw 'BLOCKED_CLOSE_QLIKVIEW'}
    $repo=(Get-Location).Path
    $source=Join-Path $env:USERPROFILE 'Documents\SAD_C2_DYNAMIC_RUNTIME\SAD_C2_DYNAMIC_e474426fc30c473c83019c4cdfaad080\SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw'
    $sourcePin='D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B'
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_MISSING'}
    if ((Get-FileHash $source -Algorithm SHA256).Hash -cne $sourcePin) {throw 'HARD_STOP_SOURCE_SHA_DRIFT'}
    $qlik='C:\Program Files\QlikView\Qv.exe'
    $runner=Join-Path $repo 'tools\Invoke-SadC2P12GuidedChartPoc01.ps1'
    if (-not (Test-Path -LiteralPath $qlik -PathType Leaf)) {throw 'BLOCKED_QV_EXE'}
    if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {throw 'BLOCKED_RUNNER'}
    $tok=$null; $parseErrors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tok,[ref]$parseErrors)
    if (@($parseErrors).Count -gt 0) {$parseErrors;throw 'BLOCKED_PS51_PARSER'}
    Write-Host "PREFLIGHT=PASS_READONLY HEAD=$head SOURCE_SHA256=$sourcePin"
}
~~~

**Atenção:** a checagem de HEAD precisa corresponder ao **SHA final do PR versionado** publicado no handoff, além de ser verificada pelo manifesto do runner. Não copiar `HEAD` de PR antigo. Se um check falhar, STOP sem `Prepare`; não fazer `git reset --hard`/force checkout/clean para contornar.

## 4. Prepare protegido — única tentativa após preflight

~~~powershell
$repo=(Get-Location).Path
$source=Join-Path $env:USERPROFILE 'Documents\SAD_C2_DYNAMIC_RUNTIME\SAD_C2_DYNAMIC_e474426fc30c473c83019c4cdfaad080\SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw'
$qlik='C:\Program Files\QlikView\Qv.exe'
$runner=Join-Path $repo 'tools\Invoke-SadC2P12GuidedChartPoc01.ps1'
$runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_CHART_RUNTIME'
$evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2_P12_CHART_EVIDENCIAS'
New-Item -ItemType Directory -Force -Path $runtime,$evidence | Out-Null
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
$prepareExit=$LASTEXITCODE
Write-Host "PREPARE_EXIT_CODE=$prepareExit"
if ($prepareExit -ne 0) {throw 'BLOCKED_PREPARE_STOP_NO_RETRY'}
~~~

Saída esperada: `PASS_COPY_PREPARED_ONLY_NO_GUI` + **`RUNTIME_COPY` e `EVIDENCE_DIR` gerados dinamicamente**; nunca adivinhar paths ou usar arquivo de outra tentativa. Copiar esses dois caminhos literais; não abrir QlikView antes do PASS.

## 5. QlikView 12 — um novo gráfico na TEMP

1. Abrir **somente o `RUNTIME_COPY`** reportado; nunca `SourceQvw`. Se licença/restore ou modelo físico diferir, STOP. Na folha `POC - Interface Guiada`, capturar `gui_before.png` no `EVIDENCE_DIR`, com `EVOLUCAO`, `Ano=2019`, `ANO REAL: 2019 / Qtd 1`, `COMPETENCIA REAL: SEM SELECAO / Qtd 0`, serviço sem seleção. O ano pode já estar selecionado ao abrir; **não clicar BU15**, não limpar seleção. Se estado diferente/incompatível, STOP e fechar sem salvar.
2. Ir à folha `POC P1.1-P1.2 - Internações`. Capturar a tela histórica para referência se útil, sem alterar CH02. Em área vazia, criar **novo objeto de gráfico de linha** pela interface (clique direito → Novo objeto de planilha → Gráfico → tipo Linha). Texto: `Evolução mensal guiada — 2019 (PoC)`. Escolher campo de dimensão **existente** `PERIODO_COMPETENCIA` e **uma expressão**:
   ~~~qlik
   =Sum(QTD_INTERNACAO)
   ~~~
   Não aplicar Set Analysis fixo/dinâmico, não acrescentar dimensão, tabela ou campo novo. Ordenar `AAAAMM` crescente de modo comprovável, sem forçar `Mostrar todos os valores` nem eixos artificiais para criar 12 pontos. Se não houver dimensão/medida disponíveis, STOP e registrar `BLOCKED_FIELDS_OR_EXPRESSION`.
3. **Condição candidata, não homologada:** localizar propriedade de cálculo (`Calculation Condition`) do **novo** objeto. Se estiver disponível, usar somente:
   ~~~qlik
   =If(
     '$(vSAD_POC_Mode)'='EVOLUCAO'
     and GetSelectedCount(PERIODO_ANO)=1
     and GetSelectedCount(PERIODO_COMPETENCIA)=0
     and Only(PERIODO_ANO)=Num($(vSAD_POC_Year)),
     1,0)
   ~~~
   Conferir indicador da interface `Expressão OK` **quando disponível**; registrar `new_chart_properties.png` com novo ID, dimensão, medida e condição. Se a propriedade não existir, for incompatível ou causar erro, **não substituir por truque em outro objeto; STOP com INCONCLUSIVE/ BLOCKED**, documentando a possibilidade de não ter sido salvo nenhum gráfico novo.
4. Confirmar propriedades e **salvar somente a NOVA TEMP uma vez**, antes de comparar a série. Não salvar nenhuma outra QVW. Capturar `guided_chart_after.png` com ambos `CH02` histórico e **novo gráfico** visíveis, além do ano real aplicado. Se o novo gráfico ficar vazio, mantiver 36 meses, mostrar outra dimensão, travar, ou exibir valores inconsistentes: STOP funcional; não alterar a expressão/condição para tentar consertar.
5. **Somente se houver exatamente 12 competências `201901..201912`**: exportar a tabela subjacente do **novo gráfico**, não CH02, a arquivo `guided_chart_2019_export.tsv` no `EVIDENCE_DIR`. Não modificar o QVW para exportar. Oráculo preexistente P1.2: SHA-256 `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`. Comparar as 12 linhas sem recalcular SIH/QVD. Controles secundários: total 2019 **188.246**, `201905=17.292`. A igualdade do total não substitui 12/12 ponto a ponto. Se o oráculo não puder ser localizado e inspecionado, o veredito funcional será `INCONCLUSIVE_ORACLE_UNAVAILABLE`.
6. Escrever `gui_notes.txt` fiel aos acontecimentos, no `EVIDENCE_DIR`: RunId, HEAD, ID novo do gráfico, ação, estado real antes/depois, condição e seu resultado, propriedades realmente configuradas, pontos visíveis, export/oráculo e qualquer bloqueio. Evidências de estados não executados **não** devem ser fabricadas. **Fechar o QlikView sem salvar novamente.** Se surgir pedido de salvamento após já ter salvo as propriedades, escolher **Não**.

## 6. Verify único — após fechar QlikView

Apenas com `EVIDENCE_DIR` retornado no Prepare e **mesmo checkout/HEAD/runner**, sem QlikView aberto:

~~~powershell
$runDir='<COLE_EVIDENCE_DIR_EXATO_DO_PREPARE>'
if (@(Get-Process -Name qv,qlikview -ErrorAction SilentlyContinue).Count -gt 0) {throw 'BLOCKED_CLOSE_QLIKVIEW_FIRST'}
if (Test-Path (Join-Path $runDir 'guided_chart_verify.json')) {throw 'BLOCKED_VERIFY_ALREADY_EXISTS'}
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qlik -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
$verifyExit=$LASTEXITCODE
Write-Host "VERIFY_EXIT_CODE=$verifyExit"
if ($verifyExit -ne 0) {throw 'BLOCKED_VERIFY_STOP_NO_RETRY'}
~~~

O runner reporta `PROTECTED_25_UNCHANGED`, `SOURCE_UNCHANGED`, `COPY_CHANGED_FROM_SOURCE`, `GUI_EVIDENCE_MISSING` e código de saída, mas `VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI` **não valida expressão, gráficos nem mudanças específicas no objeto**. `COPY_CHANGED_FROM_SOURCE=True` só prova que a cópia mudou binariamente, e não que o novo gráfico foi criado corretamente. `False` não bloqueia auditoria de origem mas impede declarar implementação confirmada.

## 7. Critérios de aceite e saída

| Estado | Prova exigida |
| --- | --- |
| `PASS_RESTRICTED_GUIDED_CHART_2019_12_OF_12` | novo objeto separado de CH02, condição/medida e contexto reais legíveis, 12 competências `201901..201912`, 12 valores iguais ao oráculo histórico (SHA conferido), fonte+25 protegidos intactos, TEMP modificada somente pelo objeto observável e evidências suficientes |
| `BLOCKED_CHART_ASSOCIATION_OR_EXPRESSION` | gráfico sem dados, 36 meses, erro de condição/medida, seleção ignorada ou valor discordante; documentar STOP, sem correção automática |
| `INCONCLUSIVE_ORACLE_OR_GUI` | export, oráculo, capturas ou propriedades não disponíveis; não promover a PASS |
| `HARD_STOP_INTEGRITY` | fonte/25 protegidos divergentes, arquivo fora do escopo alterado, runner/commit divergente |
| `NOT_RUN` | versão documental e script preparados, sem execução física no Windows |

**Não autorizados:** merge #204/novo PR, modificação de CH02/BU15/filtros, regeneração de dados, script QVS, COM, reload, alteração de C3/C4 ou IX. Manter `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED` e `PRODUCTION_APPROVED=False`. A Issue #196 permanece aberta até prova de 12 meses e decisão global própria.

---

## 8. Closeout — uma execução física da PoC concluída em 31/10/2026

**Veredito restrito:** `PASS_RESTRICTED_GUIDED_CHART_2019_12_OF_12`. Refere-se **exclusivamente** à nova QVW TEMP, ao cenário `EVOLUCAO/2019`, aos 12 valores SIH/RD reconciliados com o oráculo histórico e à integridade reportada. **Não equivale** a C2 completo, D2/P5 global, painel final ou aprovação de produção.

### 8.1 Identidade e prova física

- **Commit efetivamente executado no Windows/QlikView:** `test/sad-c2-p12-guided-chart-poc-20261031@dfeb4089bb3bd6c35161e669ddb65013028c5492`. Qualquer edição documental posterior muda o HEAD da branch **sem transferir o PASS para outro executor**.
- **Runner SHA-256 reportado no Prepare e no Verify:** `9DAD558200B2CC2A0417B151C5D571380D291494E19EFC2477E4F6B6DD27D67D`.
- **QlikView:** `12.0.20000.0`; `QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0`.
- **RunId:** `SAD_C2_P12_CHART_4d1f6da0544749b5bb92b4346300c025`.
- **Origem TEMP protegida:** `SAD_C2_DYNAMIC_DISPATCH_TEMP.qvw`, SHA-256 reportado `D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B`.
- **Nova TEMP salva:** `SAD_C2_P12_GUIDED_CHART_TEMP.qvw`, SHA-256 final **reportado no Windows** `C8C3F24DAB56ABEEC0ABD0194A691FD78536BF8F550410E3C609262141A5B917`.
- **Evidências locais fora do Git:** `C:\Users\pedro\Documents\SAD_C2_P12_CHART_EVIDENCIAS\SAD_C2_P12_CHART_4d1f6da0544749b5bb92b4346300c025` e runtime de mesmo RunId sob `Documents\SAD_C2_P12_CHART_RUNTIME`.

### 8.2 GUI revisada e oráculo independente

**Capturas do operador revisadas na conversa:**
1. A QVW TEMP abriu com modo `EVOLUCAO`, proposta 2019, `ANO REAL=2019` explicitamente selecionado (Qtd 1), `COMPETENCIA REAL=SEM SELECAO` (Qtd 0), serviço sem seleção; **sem novo clique em BU15**.
2. No novo objeto de linha, dimensão `PERIODO_COMPETENCIA`, medida `=Sum(QTD_INTERNACAO)`; editor da condição candidata apresentou `Expressão OK`. A captura da folha mostra **dois gráficos distintos**, o `CH02` histórico 2017–2019 acima e o novo gráfico guiado abaixo com 12 competências `201901..201912`. Valores/condição não foram auditados diretamente no binário.
3. ID físico do objeto novo e propriedades completas depois de salvar: **não verificados independentemente** na inspeção de binário (`OBJECT_ID=UNKNOWN`). O screenshot comprova separação visual, mas hash diferente da TEMP **não prova sozinho** que somente um objeto mudou internamente.

**Arquivos enviados e inspecionados diretamente pelo agente:** `guided_chart_2019_export.tsv`, SHA-256 `CBC9368DB129F0BB19A1A1316EE5AA185CBE85E5D42CCD21DF798080CF9707E5`, **12 linhas**; e `P11P12_VISUAL_POLISH_36_MESES.tsv.txt(1).txt`, SHA-256 `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`, **36 linhas**. A sequência de 2019 do oráculo foi confrontada byte a byte com o TSV da PoC: **12/12 linhas idênticas**, 0 faltantes/duplicatas/divergências, `201901..201912`, total `188246`, testemunha `201905=17292`. **Não houve recarga, recomputação dos fatos ou reconstrução do oráculo.**

### 8.3 Verify único — transcript final do operador

O operador executou o `-Verify` com QlikView fechado, no commit/runner originais, após instalar evidências no diretório externo; transcrição reportada:

~~~text
PREFLIGHT_VERIFY=PASS
GATE=SAD-C2-P12-GUIDED-CHART-POC-01
GIT_HEAD=dfeb4089bb3bd6c35161e669ddb65013028c5492
RUNNER_SHA256=9DAD558200B2CC2A0417B151C5D571380D291494E19EFC2477E4F6B6DD27D67D
SOURCE_SHA256=D5E427E8DCB040647E9879E97A0926793F18E14B09BF0831562632ED4CF0904B
QV_PRODUCT_VERSION=12.0.20000.0
QLIK_COM_CALLS=0 RELOAD_CALLS=0 AUTOMATED_GUI_ACTIONS=0
PROTECTED_25_UNCHANGED=True
SOURCE_UNCHANGED=True
COPY_CHANGED_FROM_SOURCE=True
COPY_SHA256=C8C3F24DAB56ABEEC0ABD0194A691FD78536BF8F550410E3C609262141A5B917
GUI_EVIDENCE_MISSING=
EVIDENCE_DIR=C:\Users\pedro\Documents\SAD_C2_P12_CHART_EVIDENCIAS\SAD_C2_P12_CHART_4d1f6da0544749b5bb92b4346300c025
VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI
VERIFY_EXIT_CODE=0
~~~

**Nível de garantia:** logs/hash de binários e 25 protegidos **reportados pelo runner no ambiente Windows**; o agente não leu o `guided_chart_verify.json` nem os bytes QVW/QVD diretamente. O runner testa presença de capturas, **não** seu conteúdo. Os TSVs e imagens enviados pelo operador foram analisados na conversa. Nenhum certificado de CI ou aceite visual global foi emitido.

### 8.4 Encerramento e handoff mínimo

- `GUI_2019_12_MONTHS=PASS_SCREENSHOT_RESTRICTED`
- `TSV_2019_12_OF_12=PASS_INDEPENDENT_FILE_RECONCILIATION`
- `INTEGRITY_SOURCE_25=PASS_LOCAL_REPORTED`
- `NEW_TEMP_CHANGED_AND_SAVED=PASS_LOCAL_REPORTED`
- `OBJECT_ONLY_DIFF=NOT_INDEPENDENTLY_AUDITED`, `OBJECT_ID=UNKNOWN`.
- `GATE_C2_P12_GUIDED_CHART_POC_01=CLOSED_PASS_RESTRICTED`.
- `PR_205=DRAFT_NOT_MERGED`; `ISSUE_196=OPEN_PENDING_C2_GLOBAL_DECISION`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP efetivo:** não repetir Prepare/GUI/Verify, BU15, export/oráculo, não editar CH02, não criar segundo objeto nem rodar automaticamente teste de outros anos/seleções. Preservar binários/evidências locais com seus hashes, manter PR Draft sem merge ou exclusão de branch. Próximo trabalho possível é **revisão de governança e decisão de integração documental**, com atualização do `current-state.md` apenas quando autorizada; contratos globais C2/D2/P5 e sequência C3→C4 são gates próprios e não ficam implicitamente aprovados.
