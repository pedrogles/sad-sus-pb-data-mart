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

## Sequência operacional (usar o procedimento executável da documentação C3-B1)

1. Confirmar Git `main` e estado da branch `test/phase-viii-c3b1-asymmetric-roles-20261019` no clone real. **Não rodar `git reset --hard`, `git clean`, `git pull` indiscriminado, squash, rebase, merge, force push ou alterar a `main`.** Se o checkout estiver diferente, verificar alterações locais e parar antes de forçar qualquer mudança.
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
