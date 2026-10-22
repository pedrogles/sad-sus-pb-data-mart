# VIII-C2-J — Seleção temporal real + P5: roteiro delimitado

Data: 22/10/2026. Base main: a16539e10499d0346bf5574f3142f568a5073d02.

Gate PREP: roteiro e script versionados; QlikView Windows NÃO foi executado nesta sessão.

## Fontes canônicas e dependências

Ordem: AGENTS.md, docs/project/current-state.md, docs/academic/requirements.md, docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md (§62.3, §62.6, §62.7), docs/project/qlikview-powershell-automation.md, PRs #152 e #153, este roteiro.

O PR #153 comprovou navegação por variáveis em cinco imagens QlikView, propriedade do botão Mensal e hashes protegidos via stdout Windows. Não repetir. A fonte deste novo teste é a cópia final cuja integridade foi relatada.

## Objetivo e limites

(1) Aplicar UMA competência 201801 a PERIODO_COMPETENCIA, de preferência por valor calculado das variáveis já presentes, sem cadeias de limpar/selecionar. Observar estado associativo real antes/depois.

(2) Verificar P5 quando município de serviço está selecionado e análise RES; se houver guarda de cálculo real do KPI, inspecionar bloqueio; caso contrário, documentar apenas diagnóstico, não inventar indicador.

Preservar 22 QVDs, 3 QVWs canônicos e cópia fonte; nenhuma recarga, COM ou alteração de dados, fatos, Link Table, dimensões, scripts QVS ou QVW canônico. Sem Fase IX, merges, refazer C2-H/C2-I ou testes Python prévios. QlikView Desktop 12 obrigatório. Codex Local pode apoiar revisão, mas executar com PowerShell 5.1 nativo se sandbox não tiver os arquivos Windows.

## Origem pinada e preflight

Fonte exata:

C:\Users\pedro\Documents\SAD_C2_GUIDED_RUNTIME\SAD_VIII_C2_GUIDED_2574d7e1b90b4edbb6e17edd9322e501\SAD_C2_GUIDED_HYBRID_POC_COPY.qvw

SHA-256 exigido: 3BD19C6D7AE64A258094FA53233D9542E5203189369EA8C1460BF4A447857774.

Script: tools/Invoke-SadPhaseViiiC2jRealSelectP5Pilot.ps1.

O script é SOMENTE -Prepare/-Verify: copia para local de runtime separado e compara origem + 25 protegidos; não chama COM, não modifica QlikView, não recarrega. Script versionado ANTES da execução; confirmar HEAD remoto e seu SHA depois da criação deste documento.

No Windows PowerShell nativo, a partir da raiz do repositório; nunca forçar checkout, reset, clean ou excluir branch:

~~~~powershell
$ErrorActionPreference='Stop'
$branch='test/phase-viii-c2j-guided-real-selection-p5-20261022'
$expected='INSERIR_HEAD_FIXO_CONFIRMANDO_GITHUB'
$dirty=@(git status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {throw 'BLOCKED_DIRTY_WORKTREE'}
git fetch origin "refs/heads/test/phase-viii-c2j-guided-real-selection-p5-20261022:refs/remotes/origin/test/phase-viii-c2j-guided-real-selection-p5-20261022"
if ($LASTEXITCODE -ne 0) {throw 'BLOCKED_FETCH'}
if ((git rev-parse "refs/remotes/origin/$branch").Trim() -ne $expected) {throw 'BLOCKED_REMOTE_SHA_DRIFT'}
git show-ref --verify --quiet "refs/heads/$branch"
if ($LASTEXITCODE -eq 0) {git switch $branch} else {git switch --track "origin/$branch"}
if ($LASTEXITCODE -ne 0 -or (git rev-parse HEAD).Trim() -ne $expected) {throw 'BLOCKED_WRONG_CHECKOUT'}
$root=(Get-Location).Path

$source='C:\Users\pedro\Documents\SAD_C2_GUIDED_RUNTIME\SAD_VIII_C2_GUIDED_2574d7e1b90b4edbb6e17edd9322e501\SAD_C2_GUIDED_HYBRID_POC_COPY.qvw'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {throw 'BLOCKED_SOURCE_MISSING'}
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne '3BD19C6D7AE64A258094FA53233D9542E5203189369EA8C1460BF4A447857774') {throw 'HARD_STOP_SOURCE_SHA_DRIFT'}

$runtime=Join-Path $env:USERPROFILE 'Documents\SAD_C2J_REAL_RUNTIME'
$evidence=Join-Path $env:USERPROFILE 'Documents\SAD_C2J_REAL_EVIDENCIAS'
New-Item -ItemType Directory -Path $runtime,$evidence -Force | Out-Null
$runner=(Resolve-Path '.\tools\Invoke-SadPhaseViiiC2jRealSelectP5Pilot.ps1').Path
$tokens=$null; $errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
if ($errors.Count -gt 0) {$errors | ForEach-Object {$_.ToString()};throw 'PARSER_BLOCKED'}
'PARSER=PASS'
powershell.exe -NoProfile -File $runner -Root $root -SourceQvw $source -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
~~~~

Uma preparação somente. Guardar RUNTIME_COPY, EVIDENCE_DIR, VERSIONED_GIT_HEAD e SHA. Em BLOCKED/HARD_STOP, encerrar, não substituir a origem e não repetir automaticamente. Não abrir a cópia antes de PREPARE=PASS.

## GUI — duas provas pequenas, ambas somente na NOVA cópia C2J

### A. Uma seleção real mensal

1. Abrir SOMENTE RUNTIME_COPY indicado na saída. Confirmar título SAD_C2J_GUIDED_REAL_SELECTION_COPY.qvw.
2. Na folha experimental, adicionar um objeto de texto de diagnóstico de seleções reais com GetFieldSelections(PERIODO_ANO), GetFieldSelections(PERIODO_COMPETENCIA), GetSelectedCount(PERIODO_ANO), GetSelectedCount(PERIODO_COMPETENCIA). Registrar captura ANTES. Não confundir as variáveis de proposta com as seleções reais.
3. Se ano real estiver selecionado como 2019 ou competência real incompatível com 201801, STOP sem limpar campos. Somente prosseguir se não houver seleção ou seleção temporal já coerente com 2018/201801.
4. Usar valores de proposta Ano=2018, Mês=1, modo=MENSAL. Criar UM botão NOVO Aplicar competência proposta, sem modificar os cinco botões prévios, com única ação Seleção > Selecionar no Campo, Campo = PERIODO_COMPETENCIA. Testar com texto de pesquisa calculado =Num($(vSAD_POC_Year))*100+Num($(vSAD_POC_Month)) no editor de expressão (...), somente se a instância confirmar avaliação 201801. A Qlik permite fórmulas em campos com ... mas não há PASS antecipado para esta fórmula.
5. No botão, configurar Enable Condition/Condição de habilitação restrita a vSAD_POC_Mode = MENSAL, vSAD_POC_Year = 2018 e vSAD_POC_Month = 1, se a propriedade estiver disponível. Guardar a prévia. Se a expressão ou a ação não puderem ser confirmadas sem ambiguidades, INCONCLUSIVE e STOP.
6. Clicar UMA vez; capturar a seleção real 201801 e confirmar inexistência de ano 2019 residual. Não encadear Clear Field, Reload ou macros. Não inferir que modos ANUAL e EVOLUCAO reais passaram deste teste.

### B. Diagnóstico P5 com campo municipal REAL

1. Na Multi Box verificar o nome físico COMPLETO do campo antes visto truncado como SERV_COD_DA... e provar que é município de SERVIÇO, não residência. A seleção 250750 pode ser o contexto inicial, mas não considerá-la sem inspecionar o campo.
2. Mudar somente a análise proposta para RES, observar que a seleção real de SERVIÇO permanece ativa; a V2 §62.6 classifica SERV→RES como B.
3. Construir objeto de texto diagnóstico baseado em GetSelectedCount(NOME_FISICO_CONFIRMADO). Registrar B/indisponível se RES + serviço selecionado; nunca apresentar número de RES como indicador válido nesse contexto.
4. Somente classificar KPI P5 como bloqueado se um objeto de indicador REAL possuir sua própria Calculation Condition e não calcular quando B; simples texto de status não comprova o bloqueio do KPI. Não criar medidas sintéticas ou alterar denominadores.

Uma rodada; salvar SOMENTE a cópia nova após testes permitidos e fechar QlikView. Sem segunda execução de Prepare.

## Verify (após fechar o QlikView)

~~~~powershell
powershell.exe -NoProfile -File $runner -Root $root -SourceQvw $source -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir 'COLE_EVIDENCE_DIR_REAL_REPORTADO_NO_PREPARE'
~~~~

Esperados, NÃO executados nesta sessão: PROTECTED_25_UNCHANGED=True, SOURCE_UNCHANGED=True, COPY_CHANGED=True; VERDICT=PASS_HASH_INTEGRITY_ONLY_UI_NOT_PROVEN. Manter mesmo checkout e runner. PASS de hash não aprova D2/P5.

## Provas e veredito

- SCRIPT_VERSIONED: controle de versão sim; Parser no Windows ainda NOT_RUN.
- TEMPORAL_REAL_SELECTION=PASS somente se PERIODO_COMPETENCIA=201801 real, com pré/pós e sem conflito.
- P5_DIAGNOSTIC=PASS parcial somente com campo SERV real validado, seleção ativa, análise RES e aviso coerente.
- P5_KPI_GUARD=NOT_TESTED até comprovação em objeto KPI real com condição de cálculo.
- D2_GLOBAL e P5_GLOBAL permanecem NO_GO/NOT_TESTED, assim como medidas/Link Table, T29 histórico, produção e Fase IX.

STOP após uma rodada ou primeira falha; manter QVW/prints/logs fora do Git. No retorno enviar stdout, título/capturas do QVW e hashes; não usar o PASS anterior da navegação para preencher lacunas atuais.

## Documentação oficial

- https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Button2.htm
- https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/ChartFunctions/FieldFunctions/field-functions-charts.htm
- https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Ajax/WebView_StraightTable.htm
