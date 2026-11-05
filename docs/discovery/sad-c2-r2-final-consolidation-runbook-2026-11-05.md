# SAD — C2-R2 | Consolidação física final (F1/F2)

**Gate:** `SAD-C2-R2-FINAL-CONSOLIDATION-01`
**Baseline confirmado no GitHub (05/11/2026):** `main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83`.
**Contrato:** D2-R2/V3 somente para D2; V2 preservada no restante.
**Status deste pacote:** `DRAFT_NOT_COMMITTED_NOT_RUN`. Arquivos preparados fora do repositório; **não executá-los como evidência do gate até commit em branch**.
**Executor preferido:** operador Windows PowerShell 5.1 + QlikView Desktop 12.0.20000.0. Codex Local é alternativa se tiver acesso real ao Windows.
**Permissões:** preparação e revisão do runner; QVW TEMP isolada somente mediante autorização específica para edição; execução física somente quando autorizada. Não criar merge nem mudar `main` ou QVD/QVW canônicos.

## 1. Fonte e proteção

| Elemento | Referência |
|---|---|
| TEMP #222, origem candidata | `C:\Users\pedro\Documents\SAD_C2_P12_CH03_H1_RUNTIME\SAD_C2_P12_CH03_H1_c70f6c392ca44f53900a92c0cc601073\SAD_C2_R2_P12_CH03_NATIVE_H1_TEMP.qvw` |
| SHA-256 obrigatório da TEMP origem | `C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D` |
| Provas prévias | #220 (CH02), #221 (TX10/TX11/TX12/TX13), #222 (CH03/TX17 e auditoria) |
| Invariantes | 10 QVDs extração + 12 QVDs transformação + 3 QVWs canônicos; nenhuma modificação |
| Runtime | `C:\Users\pedro\Documents\SAD_C2_FINAL_RUNTIME_20261105` (fora do Git) |
| Evidências persistentes | `C:\Users\pedro\Documents\SAD_C2_FINAL_EVIDENCE_20261105` (fora do Git) |

**Antes de qualquer mudança:** conferir que a TEMP existe, corresponde ao SHA, e que os objetos listados no #222 estão presentes e no estado esperado. Não presumir que o estado persistido tenha seleções prontas. Se nome/hash, árvore Git ou QlikView divergirem, STOP. A integridade `25/25` no runner é conferida por SHA-256 antes/depois.

## 2. Versionamento obrigatório ANTES de executar

O repositório exige scripts usados como evidência **commitados previamente**. Esta etapa requer decisão/autorização da classe `CREATE_BRANCH_AND_COMMIT`; não está implícita na preparação deste arquivo. Após autorização, no checkout Windows limpo, confirmar `git status`, atualizar/revalidar `main`, criar branch específica `test/sad-c2-r2-final-consolidation-20261105`, copiar os dois arquivos fornecidos para:

- `tools/Invoke-SadC2R2FinalConsolidation01.ps1`
- `docs/discovery/sad-c2-r2-final-consolidation-runbook-2026-11-05.md`

Conferir o diff e commit **antes do Prepare**, sem merge. O próprio runner exige nome de branch, script rastreado/commitado, worktree limpa e ancestralidade da baseline. Se houver branch existente, conflitos ou drift, STOP: não usar `reset --hard`, `clean`, `stash` ou substituição forçada.

PowerShell 5.1, desde a raiz do repositório (consulta apenas, antes da decisão de branch):

```powershell
$ErrorActionPreference = 'Stop'
git status --short
git rev-parse HEAD
git branch --show-current
$source = 'C:\Users\pedro\Documents\SAD_C2_P12_CH03_H1_RUNTIME\SAD_C2_P12_CH03_H1_c70f6c392ca44f53900a92c0cc601073\SAD_C2_R2_P12_CH03_NATIVE_H1_TEMP.qvw'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw 'BLOCKED_SOURCE_NOT_FOUND' }
(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
```

Não corrigir silenciosamente um SHA divergente alterando o valor fixo do runner.

## 3. Prepare — somente depois de commit e autorização de execução

QlikView fechado. Criar as duas raízes externas se ainda **não existirem**. Não reutilizar raízes contendo execuções anteriores.

```powershell
$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$runner = Join-Path $repo 'tools\Invoke-SadC2R2FinalConsolidation01.ps1'
$source = 'C:\Users\pedro\Documents\SAD_C2_P12_CH03_H1_RUNTIME\SAD_C2_P12_CH03_H1_c70f6c392ca44f53900a92c0cc601073\SAD_C2_R2_P12_CH03_NATIVE_H1_TEMP.qvw'
$qvExe = 'C:\Program Files\QlikView\Qv.exe'
$runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_FINAL_RUNTIME_20261105'
$evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_FINAL_EVIDENCE_20261105'
if ((Test-Path $runtime) -or (Test-Path $evidence)) { throw 'BLOCKED_OUTPUT_ROOT_EXISTS' }
$tokens=$null; $parseErrors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$parseErrors)
if (@($parseErrors).Count -gt 0) { $parseErrors; throw 'BLOCKED_POWERSHELL_PARSER' }
New-Item -ItemType Directory -Path $runtime,$evidence -ErrorAction Stop | Out-Null
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_PREPARE' }
```

Exigir `VERDICT=PASS_COPY_PREPARED_ONLY_NO_GUI`, `RUNTIME_COPY`, `EVIDENCE_DIR`, `GIT_HEAD`, `RUNNER_SHA256`, SHA da fonte exato e QlikView `12.0.20000.0`. **Anotar `EVIDENCE_DIR` e `RUNTIME_COPY` impressos**, sem inventar caminhos por concatenação manual.

## 4. Procedimento QlikView manual — uma TEMP e F1/F2

### Antes de testar

Abrir **somente `RUNTIME_COPY`** no QlikView 12. Não abrir a origem #222 para editar. Registrar em `gui_notes.txt` os IDs originais de `CH02`, `CH03`, `TX17`, `TX10–TX13` e o estado de seleções observado ao abrir. O runner não inspeciona essas propriedades. Não executar reload, não acionar botões antigos para reconstruir experimentos já encerrados. **Não salvar durante F1 ou F2**; permitir no máximo um Save final depois de validar os dois cenários.

### F1 — seleção nativa mensal incompatível com CH03

1. Na TEMP, usando caixas de lista **temporárias**, aplicar a seleção real `PERIODO_ANO=2019`, `PERIODO_COMPETENCIA=201901`, sem outros filtros. Se a QVW abrir em H2, retirar somente o filtro `SERV_COD_DATASUS_6=250750`. Não usar `Clear All` indiscriminado. Proposta guiada `vSAD_POC_Mode=EVOLUCAO`, `vSAD_POC_Year=2019`, sem confundi-la com seleção real.
2. Capturar diretamente no `EVIDENCE_DIR` **`f1_real_state.png`** com estado real/proposto. As seleções reais devem mostrar contagem 1 para ano e competência.
3. Conferir os quatro cartões em P1.1: **183.532 / 183.311 / 188.246 / 555.089**. **Não editar TX10–TX13**. O CH02 da TEMP #222 foi observado truncado; confirmar Object ID e expressão original antes de alterar.
4. Só se corresponder à expressão original esperada, substituir **apenas a medida de CH02**, preservando dimensão, título e formatação, por:

   ```qlik
   =Sum({$<PERIODO_ANO={2017,2018,2019},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)
   ```

   Exigir `Expressão OK`, 36 competências distintas `201701` a `201912`, e os totais históricos comprovados. Se não recuperar o eixo, STOP (`BLOCKED_HISTORICAL_AXIS`), sem segunda hipótese. Capturar **`f1_cards_ch02.png`** e uma visualização do conjunto de dados do próprio gráfico, preferencialmente com todos os 36 períodos, em **`f1_ch02_36_points.png`**. Não recalcular o oráculo.
5. CH03 não deve publicar série obsoleta como válida. TX17 deve mostrar especificamente **“Indisponível nesta evolução guiada — existe seleção mensal aplicada.”** Capturar **`f1_ch03_tx17.png`**. Se houver série stale ou mensagem insuficiente, STOP; uma alteração alternativa de TX17 só pode ser proposta e revisada separadamente antes de salvar.

### F2 — contexto anual válido com 2018

6. Na mesma TEMP, sem salvar, **limpar apenas a seleção explícita de `PERIODO_COMPETENCIA`** e então mudar `PERIODO_ANO` para `2018` pela interface nativa. Evitar estados associativos impossíveis. Confirmar 2018 como ano real único, zero competências explicitamente selecionadas, ausência de SERV e proposta `EVOLUCAO/2018`. Capturar **`f2_real_state.png`**.
7. CH03 deve ter título correspondente ao **ano real 2018**, exibir somente `201801..201812` e total de referência **183.311**, com valores reconciliados contra o oráculo histórico já arquivado. Capturar **`f2_ch03_year_title.png`** e **`f2_ch03_12_points.png`** (tabela de dados/exportação do próprio gráfico quando possível). Se o título for literal de 2019, registrar expressão/propriedade exata: alteração mínima só após revisão explícita da fórmula candidata, sem editar medida, condição de cálculo ou outras propriedades. A revisão de TX17 deve distinguir contexto válido de indisponibilidade, sem alegar cobertura global de estados não testados.
8. CH02 continua com 36 meses históricos e valores corretos. Capturar **`f2_ch02.png`**. Um erro funcional ou seleção real incompatível => STOP; se F2 não puder ser comprovado na interface existente, `INCONCLUSIVE_F2`, sem terceiro cenário automático.

### Save único e inspeção visual pós-save

9. Remover **somente** as caixas de lista transitórias criadas nesta rodada, sem alterar inadvertidamente as seleções. Comparar inventário visível de objetos com a auditoria do #222: 38 objetos (37 históricos + TX17), sem objeto novo não autorizado. Documentar alterações efetivas em CH02 e, somente se previamente validadas, no título/diagnóstico CH03/TX17. Registrar em `gui_notes.txt` IDs, expressões antes/depois, cenário, resultados, screenshots, contagem de Saves e razão de cada edição.
10. **Somente se F1/F2 materiais satisfatórios e nenhum blocker de integridade**, salvar a QVW TEMP **uma vez**. Fechar e reabrir a **mesma TEMP** para conferência visual de apresentação e Z-order, sem novo Save. Capturar **`post_save_sh02.png`** e **`post_save_sh03.png`** diretamente no `EVIDENCE_DIR`. Se o QlikView pedir para salvar ao sair novamente, recusar. Se não ocorrer Save, registrar o motivo e NÃO fabricar capturas pós-save.

## 5. Verify único — depois de fechar QlikView

Na mesma sessão PowerShell do Prepare e sem QlikView rodando:

```powershell
$runDir = Read-Host 'Cole o EVIDENCE_DIR informado pelo Prepare'
if (-not (Test-Path -LiteralPath (Join-Path $runDir 'c2_r2_final_prepare.json'))) { throw 'BLOCKED_WRONG_RUN_DIR' }
if (Test-Path -LiteralPath (Join-Path $runDir 'c2_r2_final_verify.json')) { throw 'BLOCKED_ALREADY_VERIFIED' }
& powershell.exe -NoProfile -File $runner -Root $repo -SourceQvw $source -QlikExe $qvExe -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir $runDir
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_VERIFY' }
```

O runner gera `c2_r2_final_verify.json` com hashes de origem, TEMP, 25 protegidos e capturas. `MtimeAfterPrepare` é **indício temporal de arquivo**, não prova de autoria da captura; a auditoria visual e a declaração contemporânea em `gui_notes.txt` são necessárias. `VERDICT=PASS_PROTECTED_INTEGRITY_ONLY_NOT_GUI` **não equivale** a PASS de F1/F2 ou de C2.

## 6. Veredito e STOP

- **PASS:** F1/F2 comprovados, histórico correto, indisponibilidade contextual correta, título/competências reais, salvamento/reabertura com apresentação íntegra, origem e 25 protegidos preservados, screenshots contemporâneos e diff restrito. `C2_GUIDED_R2=PASS` somente no recorte D2-R2/V3 e quando a matriz C2-A/B/C estiver integralmente classificada.
- **BLOCKED:** série inválida apresentada como válida, CH02 truncado com rótulo histórico integral, valor/oráculo divergente, alteração de objeto não autorizada ou integridade comprometida.
- **INCONCLUSIVE:** fonte/estado/screenshot/contagem insuficiente, título ou escopo não demonstrado, falta de ambiente ou Save/reabertura não comprovados.
- **STOP:** um Prepare, uma TEMP, F1/F2, um Save máximo e um Verify; não repetir H0/H1/H2 antigos, BU15/BU16 ou oráculos. Não avançar automaticamente a C3/C4, Fase IX ou produção.

**Handoff:** evidências e `gui_notes.txt` revisáveis fora do Git; um único closeout versionável em branch depois de autorização específica. Preservar `READY_FOR_C3=NO` até aceite físico do gate. Sem merge automático.
