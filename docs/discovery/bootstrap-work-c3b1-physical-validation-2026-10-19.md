# Bootstrap de execução Work — SAD C3-B1 (19/10/2026)

## Missão estritamente delimitada

Você está trabalhando no projeto acadêmico **SAD — Data Mart SUS PB**. Repositório canônico `pedrogles/sad-sus-pb-data-mart`, QlikView **12** obrigatório. Esta execução é **C3-B1**: aferir **um** fluxo assimétrico SIH/RD `residencia != servico` com ano 2018, usando o oráculo independente F1 e a **cópia descartável** de um QVW TEMP T24 previamente validado. Não iniciar C3-B2, C4, P5 UI, Fase IX, dashboards, nova extração ou novo teste de T24–T26.

A `main` estava em `337943d5c5b77067f842902fc679dbb68db87020` na revisão documental de 19/10/2026. **Verifique HEAD atual em vez de assumir que não mudou.** O desenvolvimento do C3-B1 está no **PR Draft #125**: https://github.com/pedrogles/sad-sus-pb-data-mart/pull/125 , branch `test/phase-viii-c3b1-asymmetric-roles-20261019`.

## Condição ambiental — obrigatória antes de qualquer execução

1. Determine se esta sessão do Work tem **acesso real autorizado ao filesystem do Windows do usuário**, à raiz do clone local, ao `powershell.exe`, ao **QlikView 12 instalado nesse Windows** e ao objeto COM `QlikTech.QlikView`. Work com navegador/computador apenas em nuvem não deve ser tratado como acesso ao Windows local.
2. Se não houver acesso físico, retorne `BLOCKED_NO_LOCAL_WINDOWS_ACCESS` com instrução exata para executar os comandos localmente e preservar saídas. **Não simule PowerShell/COM nem apresente PASS**.
3. Não solicitar usuário/senha, abrir RDP, instalar agente remoto, expor portas, copiar dados hospitalares ou executar software não necessário.

## Fontes de verdade e ordem

Antes de iniciar qualquer trabalho estrutural, conferir na **`main`**:

1. `AGENTS.md`;
2. `docs/project/current-state.md`;
3. `docs/academic/requirements.md`;
4. `docs/discovery/phase-8-c3b1-asymmetric-role-flow-2026-10-19.md` **na branch do PR #125**;
5. `tools/Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1` **nessa mesma branch**;
6. `docs/project/qlikview-powershell-automation.md` e, somente se necessário, QVS técnico `PAINEL/phase_vii_technical_model.qvs`.

Não tratar PR Draft como `main` e não converter PASS local em aprovação de produção.

## Objetivo e critérios PASS/BLOCKED

**Objetivo:** a partir de `manifest_F1_F2.json` e `F1_fluxo_ano.csv` históricos, selecionar o par real de municípios PB `R ≠ S` em 2018 com internações elegíveis `> 0` e maior contagem do oráculo F1. Selecionar `PERIODO_ANO`, `RES_COD_DATASUS_6`, `SERV_COD_DATASUS_6` em QVW TEMP, comparar exatamente três contagens: `QTD_REGISTRO_AIH`, `QTD_INTERNACAO` e continuidades `IDENT=5`. Para o mesmo contexto assimétrico, `Count(POPULACAO_ESTIMADA)=0` e `Count(QTD_LEITOS_SUS)=0` indicam inexistência de registros factuais **alcançáveis nesse contexto**, nunca população ou leitos reais zero.

**PASS candidato:** parser PowerShell local válido; script e fonte versionados/conferidos; CSV F1 e manifesto SHA válidos; origem QVW TEMP com SHA fixado no contrato; reprodução COM do par F1 sem diferença; nenhuma linha POP/LT espúria nesse contexto; hashes dos 22 QVDs e dos QVWs canônicos antes/depois idênticos; stdout e CSVs íntegros, sob o mesmo commit.

**BLOCKED/INCONCLUSIVE:** falta de acesso local, múltiplas fontes sem identificação inequívoca, fonte antiga ausente, SHA divergente, parser inválido, erro de COM, seleção alterada, contagem divergente, hashes não preservados ou evidências insuficientes. **STOP imediato, sem corrigir à força e sem segunda tentativa automática.** Reportar primeiro a causa e os logs.

## C3-B1-CKO-PERSIST — falha de persistência do sandbox (19/10/2026)

**Resultado relatado pelo Work (não auditado neste ambiente):** CKO parou antes de checkout; inventário de 10 QVWs e 22 QVDs teria sido calculado e gravado, mas o diretório de evidência criado no `%TEMP%` contextual do sandbox desapareceu entre chamadas, inclusive quando consultado fora dele. Logo: `CKO_INVENTORY_PRESERVED=NOT_VERIFIED`; `CKO_SWITCH=NOT_RUN`; `C3B1_PHYSICAL=NOT_RUN`. O estado do Git e os QVWs continuam preservados segundo o relato. **Não repetir o inventário até confirmar persistência.**

**Única tentativa de recuperação permitida:** executar apenas um probe de persistência em **duas chamadas PowerShell independentes** na sessão **Windows real**, sem tocar no repositório ou em QVD/QVW. O LocalApplicationData real precisa existir e não ser um redirecionamento efêmero do sandbox. Não fixar o nome do usuário no código.

**Chamada 1 — criar token exclusivamente no Temp do Windows:**

```powershell
$ErrorActionPreference='Stop'
$localAppData=[Environment]::GetFolderPath('LocalApplicationData')
$hostTemp=Join-Path $localAppData 'Temp'
if(-not (Test-Path -LiteralPath $hostTemp -PathType Container)){
  throw 'BLOCKED: Windows LocalAppData Temp not accessible'
}
$root=Join-Path $hostTemp ('SAD_C3B1_CKO_'+[guid]::NewGuid().ToString('N'))
New-Item -Path $root -ItemType Directory -ErrorAction Stop | Out-Null
$token=[guid]::NewGuid().ToString('N')
$probe=Join-Path $root 'persistence_probe.txt'
[IO.File]::WriteAllText($probe,$token,([System.Text.UTF8Encoding]::new($false)))
$sha=(Get-FileHash -LiteralPath $probe -Algorithm SHA256).Hash
if(-not (Test-Path -LiteralPath $probe -PathType Leaf)){throw 'BLOCKED: probe did not persist even in same process'}
Write-Output "CKO_HOST_LOCALAPPDATA=$localAppData"
Write-Output "CKO_HOST_TEMP=$hostTemp"
Write-Output "CKO_EVIDENCE_DIR=$root"
Write-Output "CKO_PROBE_SHA256=$sha"
Write-Output 'CKO_PROBE_STAGE=WRITTEN_NOT_YET_VERIFIED_ACROSS_CALLS'
```

**Chamada 2 — novo processo PowerShell separado (idealmente fora do sandbox), não recriar arquivo:** usar **somente** o caminho `CKO_EVIDENCE_DIR` e SHA impressos na chamada 1, passados explicitamente, sem depender de variáveis de sessão anteriores.

```powershell
$ErrorActionPreference='Stop'
$root='COLE_AQUI_O_CKO_EVIDENCE_DIR_EXATO_DA_CHAMADA_1'
$expectedSha='COLE_AQUI_O_CKO_PROBE_SHA256_EXATO_DA_CHAMADA_1'
$probe=Join-Path $root 'persistence_probe.txt'
if(-not (Test-Path -LiteralPath $probe -PathType Leaf)){
  throw 'BLOCKED_EVIDENCE_PERSISTENCE: probe absent on independent process'
}
$observed=(Get-FileHash -LiteralPath $probe -Algorithm SHA256).Hash
if($observed -cne $expectedSha){throw 'BLOCKED_EVIDENCE_PERSISTENCE: SHA mismatch'}
Write-Output "CKO_EVIDENCE_DIR=$root"
Write-Output "CKO_PROBE_SHA256=$observed"
Write-Output 'CKO_PERSISTENCE=PASS_INDEPENDENT_PROCESS_ONLY'
```

**Se qualquer chamada falhar**, se não executar de fato no Windows local, se o token desaparecer ou se o SHA divergir: **STOP `BLOCKED_EVIDENCE_PERSISTENCE`**. Não fazer novo retry automático, não trocar branch, não repetir QVD/QVW inventário e não produzir PASS CKO. Informar ao responsável que será necessário executar no terminal Windows real, com acesso direto à mesma pasta.

**Somente após `CKO_PERSISTENCE=PASS_INDEPENDENT_PROCESS_ONLY`:** usar **o mesmo** `CKO_EVIDENCE_DIR` persistente para salvar `qvw_before.csv`, `qvd_before.csv`, estado de Git e inventário de paths; conferir que os arquivos estão acessíveis em uma segunda leitura independente **antes** de prosseguir ao controle de colisões. Se não conseguir reabrir qualquer inventário: STOP. Verificar colisões no **tree completo da branch destino**, não só diff do PR. A troca `git switch --track` sem força permanece condicionada ao CKO original, e os arquivos terão novo inventário/hashes pós-switch. **O sucesso do probe não prova automaticamente persistência dos arquivos que o runner C3-B1 gravará mais tarde via `[IO.Path]::GetTempPath()`; antes do gate COM, verificar o destino efetivo `EVIDENCE_DIR` do runner.**

Este probe é preparação de ambiente `EXPERIMENTAL_NOT_GATE_EVIDENCE`; o único executor para PASS físico permanece o PowerShell versionado do PR #125. Não versionar o token, os inventários ou arquivos de prova no Git.

---

## C3-B1-CKO — retomada controlada após bloqueio de checkout

**Relato local fornecido pelo operador, ainda não auditado independentemente:** às 22:27 de 19/10/2026, o Work encontrou o checkout `docs/phase-viii-c2d3-rawview-win32-discovery-20261019` no commit `314205733af067013fe19017a9e15c971d114ebf`, com **10 QVWs não rastreados em `TRANSFORMACAO/`**, sem outras alterações listadas. Windows PowerShell 5.1 e QlikView 12 foram encontrados, mas parser, F1 e COM **não executados**. A proteção de STOP foi correta.

**Correção de processo, sem relaxar invariantes:** estar em outra branch não é, isoladamente, evidência de alteração perigosa. O Work poderá prosseguir com uma **única troca de branch não forçada** após realizar os guardas abaixo. Este gate de preparação **não altera scripts, QVDs, QVWs, `main` ou PR**, nem autoriza por si só executar COM. Não criar clone novo, pois ele não carregaria automaticamente os QVDs locais.

1. Dentro do **checkout Windows original**, coletar `git status --porcelain=v1 --untracked-files=all`, `git rev-parse HEAD`, `git branch --show-current` e os caminhos completos dos QVWs não rastreados. O estado rastreado precisa estar limpo; `git diff --quiet` e `git diff --cached --quiet` não devem apontar mudanças. Exigir exclusivamente os dez QVWs em `TRANSFORMACAO/` reportados; mudança adicional = STOP. Não usar `git clean`, `git reset`, `git stash -u`, `git checkout -f`, `git switch -f` nem mover arquivos.
2. Calcular SHA-256 e tamanho dos **dez QVWs antes** do checkout e registrar esse inventário fora da árvore Git (por exemplo, `%TEMP%`). Também registrar, sem modificar, o número e hash dos 22 QVDs existentes conforme script de gate, se acessíveis.
3. Executar apenas `git fetch origin test/phase-viii-c3b1-asymmetric-roles-20261019`, verificar HEAD do remote tracking e que o PR #125 continua Draft. Verificar via `git ls-tree -r --name-only origin/test/phase-viii-c3b1-asymmetric-roles-20261019` se qualquer um dos caminhos não rastreados colide com arquivo rastreado da branch destino. Se houver interseção: **STOP**. Não confiar apenas no diff do PR.
4. Se não houver colisão e a branch local destino ainda não existir, executar **uma vez, sem força**: `git switch --track origin/test/phase-viii-c3b1-asymmetric-roles-20261019`. Em caso de conflito/erro: **STOP**, sem contornar a proteção do Git. Se a branch local já existir, parar para conferir seu HEAD/upstream antes de escolher um comando; não substituí-la silenciosamente.
5. Verificar a branch e HEAD após a troca, inventariar novamente os dez QVWs (mesmos nomes, tamanho e SHA-256) e os QVDs existentes; se algum hash divergir, **STOP_CRITICAL_PRESERVATION**. Conferir que o runner C3-B1 agora existe e está commitado e limpo. Somente então seguir ao parser e ao preflight já contratados.

**Classificação:** `C3B1_CHECKOUT_PREPARATION=PROPOSED_CONTROLLED_RESUME`; `C3B1_PARSER=NOT_RUN`; `C3B1_PHYSICAL=NOT_RUN` até evidências locais. Ao retomar, registrar SHA real do PR em vez de presumir o commit histórico `7a816d85b32cb48ee7c9460eb0692df3a7662616`. Nenhum merge, reset, criação ou exclusão de branch remota está autorizado.

---

## Sequência operacional (usar o procedimento executável da documentação C3-B1)

1. Confirmar Git `main` e estado da branch `test/phase-viii-c3b1-asymmetric-roles-20261019` no clone real. **Não rodar `git reset --hard`, `git clean`, `git pull` indiscriminado, squash, rebase, merge, force push ou alterar a `main`.** Se o checkout estiver diferente, seguir apenas o gate controlado `C3-B1-CKO` anterior; se seus critérios não forem atendidos, STOP.
2. Verificar que o executor `tools/Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1` está commitado, sem alterações locais, e registrar `git rev-parse HEAD`, status e SHA do script. Fazer apenas **parse estático** via `System.Management.Automation.Language.Parser`; isto ainda não é PASS físico.
3. Procurar em `%TEMP%` candidatos reais a `SAD_VIII_T24_ANNUAL_TEST.qvw` e diretório histórico contendo ambos `manifest_F1_F2.json` e `F1_fluxo_ano.csv`. **Não usar caminhos inventados ou fixos de exemplos.** Conferir a origem QVW SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E` e assinatura do `LINK_ANALISE.qvd` conforme runner, sem copiar nem recriar os QVDs.
4. Executar **apenas o modo preflight, sem `-RunQlik`**, do executor do PR #125, com `-Root`, `-SourceQvw` e `-F1F2Dir` identificados. Registrar stdout e `$LASTEXITCODE`. Esse modo pode criar arquivos de evidência em `%TEMP%` mas não abre COM nem recarrega QVD.
5. Se e somente se preflight retornar `VERDICT=PASS_REFERENCE_PRECHECK_ONLY_C3B1_QV_NOT_RUN`, fonte e SHA forem verificados, e o Windows/QlikView real estiver acessível, **executar uma única vez** o mesmo runner com `-RunQlik`, abrindo **somente cópia descartável**. Não abrir/alterar `PAINEL/PAINEL.qvw`, `EXTRACAO/EXT.qvw`, `TRANSFORMACAO/TRANSF.qvw` para gravação.
6. Conferir a saída `EVIDENCE_DIR`, `c3b1_oracle_pair.csv`, `c3b1_reconciliation.csv`, `qvd_before.csv`/`qvd_after.csv`, `canonical_qvw_before.csv`/`canonical_qvw_after.csv`, script/source SHA, stdout bruto, `VERDICT`. Se possível, apontar exatamente arquivos/trechos, sem versionar binários, datasets, CSVs individuais e logs no Git.

## O que entregar neste chat depois de executar

Relatório pequeno, com:
- ambientação: `LOCAL_WINDOWS_COM_AVAILABLE=True/False`, Git HEAD/branch/estado, QlikView 12 verificado ou não;
- origem e SHA da fonte QVW, hash do F1 e do `LINK_ANALISE.qvd`;
- par R/S e ano **lidos dos arquivos reais**, numeradores independentes F1 e obtidos Qlik;
- resultados de `Count(POPULACAO_ESTIMADA)` e `Count(QTD_LEITOS_SUS)` como **associações**, não taxas nem ausência de leitos/população;
- preservação SHA 22 QVDs + QVWs canônicos, caminhos de evidência e stdout/CSV (ou impedimentos concretos);
- classificação `PASS_LOCAL_CANDIDATE_ONLY`, `BLOCKED` ou `INCONCLUSIVE`, com uma única decisão de STOP.

**Gates inalterados:** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**Sem autorização para merge, exclusão de branch, alteração de dados estruturais ou homologação de produção.** Encerrar ao obter o único veredito C3-B1.
