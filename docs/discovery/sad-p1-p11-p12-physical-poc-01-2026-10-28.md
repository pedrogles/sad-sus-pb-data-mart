# SAD — Protocolo de PoC física restrita P1.1/P1.2

**Gate:** SAD-P1-P11-P12-PHYSICAL-POC-01  
**Data:** 28/10/2026  
**Baseline:** main@9070806f26a1568948b0ce2b87c597beb7ec2d9e, PR #171 integrado  
**Autorização do responsável:** "autorizado, prossiga" após proposta de PoC mínima em um QVW descartável; não autoriza merge, Fase IX, produção ou recarga.  
**Preparação:** ChatGPT GPT-6 + conector GitHub, ambiente cloud; esforço de modelo não exposto.  
**Execução física:** Codex Local no Windows ou operador humano, PowerShell 5.1 nativo e QlikView Desktop 12, modelo/esforço do executor a registrar.  
**Status atual:** PREPARED_IN_BRANCH / WINDOWS_NOT_RUN / NO_VISUAL_PASS.

## 1. Objetivo e condição de parada

Preparar uma cópia QVW previamente carregada e observar, em uma única folha experimental, **P1.1: três cartões anuais mais total do triênio** e **P1.2: série mensal de 36 competências administrativas, 201701–201912**.

**Proibido neste gate:** recarregar, STORE, alterar QVD/QVW original, mudar esquema, modificar Link Key, alterar QVS, criar painel definitivo, repetir A0 R1, C2-J/C2-K, validar filtros globais ou testar P5/D2. Usar arquitetura A0 e fatos/dimensões aprovados. A PoC envolve exclusivamente leitura e edição da nova cópia de teste.

**STOP:** uma preparação, uma rodada visual e uma verificação. Falha de fonte, hash, modelo ou evidência encerra o gate, sem seleção automática de outra origem.

## 2. Base e proveniência

Lidos em ordem: AGENTS.md; docs/project/current-state.md; docs/academic/requirements.md; contrato UX P1.1/P1.2 integrado pelo PR #171. Complementos: documentação da arquitetura A0; Boundary 7; automação PowerShell; fechamento C2-K e seu executor já versionado.

- E1 SIH: sih_fluxo_competencia.csv, SHA-256 F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615. E1 é oráculo agregado, não tabela QVW.
- A0 R1 conciliou 36/36 competências em PR #164. **Não reexecutar o validador A0.**
- FATO_INTERNACAO.QTD_INTERNACAO contabiliza IDENT=1; IDENT=5 representa continuidade e conta zero na medida.
- Aliases do painel técnico: PERIODO_ANO e PERIODO_COMPETENCIA. A associação global com Link Key não está aprovada.

**Fonte QVW candidata estritamente pinada** (cópia de saída C2-K registrada anteriormente):

    C:\Users\pedro\Documents\SAD_C2K_ANNUAL_RUNTIME\SAD_VIII_C2K_ANNUAL_47f2ae84abd747cb963f1cb8baad41a4\SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw

SHA-256 **historicamente reportado pelo operador**:

    9896D55ED7F98CFA480A0626484A04C3A937E2F64EBF238011D3CDEF4E1E21FA

A presença do QVW, seu SHA atual e as tabelas internas **não são acessíveis neste ambiente cloud**. O QVW C2-K preservou seleção de ano 2019 e município SERV 250750; **não presumir estado neutro**.

## 3. Preparar uma cópia protegida, sem QlikView

Executor: tools/Invoke-SadP11P12VisualCopy01.ps1. Adaptação restrita do padrão de cópia/hash já usado em tools/Invoke-SadPhaseViiiC2kAnnualEvolutionPilot.ps1. Não usa COM, GUI, reload nem STORE; nunca altera a origem. O novo arquivo precisa estar commitado no Git e a branch precisa estar no HEAD exato do PR deste gate antes da execução.

No **PowerShell 5.1 nativo** com checkout limpo na branch e commit aprovado:

    $root=(Resolve-Path '.').Path
    $runner=(Resolve-Path '.\tools\Invoke-SadP11P12VisualCopy01.ps1').Path
    $tokens=$null; $errors=$null
    [System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors) | Out-Null
    if ($errors.Count -gt 0) { $errors; throw 'BLOCKED_POWERSHELL_NATIVE_PARSER' }

    $source='C:\Users\pedro\Documents\SAD_C2K_ANNUAL_RUNTIME\SAD_VIII_C2K_ANNUAL_47f2ae84abd747cb963f1cb8baad41a4\SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw'
    $runtime=Join-Path $env:USERPROFILE 'Documents\SAD_P11P12_POC_RUNTIME'
    $evidence=Join-Path $env:USERPROFILE 'Documents\SAD_P11P12_POC_EVIDENCIAS'
    New-Item -ItemType Directory -Path $runtime,$evidence -Force | Out-Null
    $expected='SUBSTITUIR_COM_SHA40_EXATO_DO_COMMIT_DA_BRANCH'
    powershell.exe -NoProfile -File $runner -Root $root -SourceQvw $source -RuntimeRoot $runtime -EvidenceRoot $evidence -ExpectedCommit $expected -Prepare

**Registrar:** VERSIONED_GIT_HEAD, RUNNER_SHA256, SOURCE_SHA256, RUNTIME_COPY, EVIDENCE_DIR e PROTECTED_AND_SOURCE_UNCHANGED=True. O único resultado positivo possível até aqui é PASS_COPY_PREPARATION_ONLY_UI_NOT_TESTED.

Se faltarem QVW, 22 QVDs (10+12), três QVWs canônicos, hash ou branch; se os diretórios de saída estiverem dentro do repositório; se a origem estiver aberta: STOP com evidências. Não trocar fonte silenciosamente.

## 4. Uma rodada GUI controlada, somente na cópia

1. Abrir **somente RUNTIME_COPY** no QlikView Desktop 12. Registrar capturas do estado **antes** de qualquer operação.
2. Conferir modelo carregado: FATO_INTERNACAO, 566.672 registros administrativos e existência de QTD_INTERNACAO, PERIODO_ANO e PERIODO_COMPETENCIA. Se faltar, STOP; **não fazer reload**.
3. Inspecionar **todas** as seleções reais. C2-K tinha ano e município de serviço ativos: valores dessa seleção não representam produção global. Registrar captura. Aplicar uma única limpeza de seleções **apenas na cópia**, e registrar captura da ausência de filtros ativos. Se não conseguir comprovar estado neutro, INCONCLUSIVE e STOP.
4. Criar nova folha experimental P1.1/P1.2, sem modificar outros objetos. Três cartões de contagem usando Sum(QTD_INTERNACAO) com ano administrativo de cada cartão; quarto cartão com total fixado/explicitado como **Total do triênio**, nunca chamado anual. Expressões físicas são candidatas, não homologadas; inspecionar propriedades e número real exibido.
5. Um gráfico de linha, dimensão PERIODO_COMPETENCIA, medida Sum(QTD_INTERNACAO), ordenação cronológica ascendente, 36 competências, sem suavizar, interpolar, imputar zero ou usar data clínica DT_INTER. Aviso metodológico visível: "Internações novas por competência administrativa SIH/RD; IDENT=5 excluído. Não equivalem a pacientes únicos ou demanda reprimida."
6. Salvar **apenas a cópia de teste**. Capturar estado de seleções, quatro cartões, linha e propriedades das expressões/ordenação. Exportar a tabela completa com 36 competências e contagens para pasta de evidências; comparar a cada valor do oráculo A0 R1 já arquivado. Captura isolada não substitui confronto dos 36 valores.
7. Revisar legibilidade e interpretação em QlikView real. Não atribuir resultado a outros filtros, modos C2, relatórios ou painel final.

### Oráculos obrigatórios

| Prova | Valor esperado |
|---|---:|
| P1.1 2017 | 183.532 |
| P1.1 2018 | 183.311 |
| P1.1 2019 | 188.246 |
| P1.1 Total do triênio | 555.089 |
| P1.2 quantidade | 36 competências únicas de 201701 a 201912 |
| P1.2 total 2017 | 183.532 |
| P1.2 total 2018 | 183.311 |
| P1.2 total 2019 | 188.246 |
| P1.2 soma global | 555.089 |
| P1.2 máximo / mínimo do histórico | 201905=17.292 / 201702=13.586 |
| P1.2 confronto completo | 36/36 pontos iguais ao A0 R1 já arquivado |

Os dois pontos máximo/mínimo são controles auxiliares, **não** substitutos da reconciliação integral.

## 5. Verificação final de integridade

Após salvar e fechar a cópia no QlikView, executar no **mesmo** checkout/runner, substituindo RunDir pelo EVIDENCE_DIR efetivamente retornado:

    powershell.exe -NoProfile -File $runner -Root $root -SourceQvw $source -RuntimeRoot $runtime -EvidenceRoot $evidence -ExpectedCommit $expected -Verify -RunDir 'EVIDENCE_DIR_EXATO_DO_PREPARE'

Verificação de hashes esperada: PROTECTED_25_UNCHANGED=True, SOURCE_UNCHANGED=True, COPY_CHANGED=True. O script escreve p11p12_hash_verify.json e **não comprova o gráfico**, apenas integridade das entradas.

Evidência persistente fora do Git: stdout completo; p11p12_manifest.json; p11p12_hash_verify.json; capturas pré/pós seleção, KPIs, gráfico e suas propriedades; exportação dos 36 pontos; comparação com **oráculo arquivado real**; revisão visual humana.

## 6. PASS / BLOCKED / STOP

- **PASS_LOCAL_P11_P12_VISUAL_CANDIDATE_ONLY:** quatro KPIs corretos, 36/36 valores reconciliados, seleção neutra real verificada, imagens inspecionadas e hashes protegidos intactos.
- **RECOVERABLE_BLOCK:** QVW pinado/Windows/PowerShell/QlikView inacessível, pasta ausente; sem substituição de origem automática.
- **INCONCLUSIVE:** estado associativo incerto, export incompleto, oráculo ausente, tela ou propriedades não verificadas.
- **HARD_STOP:** hash divergente, original editado, modelo inesperado, reload/STORE, alterações fora da cópia.
- **NOT_EXECUTED:** o roteiro foi apenas preparado/versionado, sem Windows acessado.

**STOP obrigatório após uma tentativa.** Não fazer R2, reexecutar A0 R1, modificar pipeline ou criar outro objeto para corrigir erro. O resultado **nunca** equivale a aprovação global de interface, medidas cross-fact, C2/D2/P5, Link Key ou Fase IX.

Status globais preservados: LINK_KEY_CONTRACT=NOT_APPROVED; MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; C2_FULL=NO_GO_NOT_APPROVED; P5_D2_UI=NOT_TESTED_GLOBAL; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False. Nenhum merge autorizado automaticamente.
