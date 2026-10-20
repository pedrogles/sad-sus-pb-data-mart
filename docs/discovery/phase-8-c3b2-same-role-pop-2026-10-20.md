# Fase VIII — C3-B2 | Fluxo R=S e POP anual alcançável — preparação controlada

**Data:** 20/10/2026. **Status:** `C3B2_SCRIPT=VERSIONED_STATIC_REVIEW_ONLY`; `C3B2_PARSER_WINDOWS=NOT_RUN`; `C3B2_REFERENCE_PREFLIGHT=NOT_RUN`; `C3B2_QV_COM=NOT_RUN`; `C3_B2_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `LINK_KEY_CONTRACT=NOT_APPROVED`.

**Branch de trabalho:** `test/phase-viii-c3b2-same-role-pop-20261020`, aberta de `main@d09f33c1f6c83341eb346bc4d984fd11746285fc`, após #135, #125 e #136 integrados. PR Draft separado; sem merge ou mudança na `main`. **Este documento não autoriza execução COM, alteração estrutural, C4, Fase IX ou produção.**

## 1. Fonte de verdade, escopo e hipótese

Leitura em `main`: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, [Boundary 7](boundary-7-implementation-plan.md), [VI-P5](phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md), [V2 §62.6](phase-6-semantic-v2-approved-2026-10-14.md), [Fase VII](phase-7-technical-panel-controlled-gate-2026-10-18.md), [C3-remaining-gap review](phase-8-c3-remaining-gap-review-2026-10-20.md) e [C3-B1 closeout](phase-8-c3b1-physical-closeout-2026-10-20.md). O código do gerador histórico foi inspecionado no commit `26369052bd3f96de5f3eccf873c390053c20b561`.

**Objetivo único:** sob seleção simultânea no QVW TEMP de `PERIODO_ANO=2018` e **município de residência igual ao de serviço**, reconciliar um fluxo SIH/RD independente (F1) e comprovar uma única linha POP anual alcançável, com `Sum(POPULACAO_ESTIMADA)` idêntica ao F3 e nenhuma linha LT alcançável. Assim complementa a prova assimétrica C3-B1 sem repetir aquele teste. **É verificação associativa de papéis, não KPI RES/LEI/REL nem aval da matriz P5.** A V2 classifica município de serviço como bloqueio `B` para o KPI RES e residência como `B` para LEI/REL; combinar papéis aqui somente examina FLU e alcance de fatos.

**Hipótese candidata — ainda NÃO testada no QlikView:** na Link Table, POP tem R=S no mesmo município/ano e competência inaplicável (NULL); LT tem R fisicamente NULL, portanto, com residência selecionada, POP deve ser alcançável e LT não. Sob `R=S`, `Count(POPULACAO_ESTIMADA)=1` e soma positiva no ano significariam ausência de multiplicação **neste caso**, não contrato geral de denominadores. `Count(QTD_LEITOS_SUS)=0` significa LT não alcançável neste contexto, **não** capacidade ou disponibilidade reais iguais a zero.

## 2. Oráculos e seleção determinística

Arquivos de referência **preexistentes**, sem regeneração:

- `F1_fluxo_ano.csv` + `manifest_F1_F2.json`: campos reais do gerador `ano`, `municipio_residencia`, `municipio_servico`, `registros_rd`, `internacoes_elegiveis`, `continuidades_ident5`. SHA congelado verificado no C3-B1: `203DF1D1CE5B4325F0F9E8F590850D3EEF18D62EBDECF34400959A6267349F3B`.
- `F3_pop_municipio_ano.csv` + `manifest_F3.json`: campos reais do gerador `ano`, `cod_datasus_6`, `cod_ibge_7`, `populacao_estimada`. A F3 histórica produz 669 pares município×ano e 223 municípios PB em 2018. Hash **ainda precisa ser conferido diretamente no arquivo local** com o manifesto, antes de usar seu conteúdo como evidência; nenhum valor F3 foi antecipado.

O executor seleciona, em F1, somente 2018, códigos PB de seis dígitos iguais `R=S` e `internacoes_elegiveis>0`, escolhendo deterministicamente o maior valor elegível e, em empate, o menor código. Exige `registros_rd=internacoes_elegiveis+continuidades_ident5` e **exatamente um** par município/ano compatível em F3, com `populacao_estimada>0`. Nenhum município, contagem ou população foi inventado ou fixado previamente. Se faltar combinação ou houver duplicação/integridade inválida: `BLOCKED`.

Após confirmação de F1/F3, o teste pretendido seleciona **somente** `PERIODO_ANO=2018`, `RES_COD_DATASUS_6=R`, `SERV_COD_DATASUS_6=R` no QVW TEMP. `PERIODO_COMPETENCIA` deve continuar sem seleção. Ler de volta valores de cada seleção via COM. Comparar exatamente `Sum(QTD_REGISTRO_AIH)`, `Sum(QTD_INTERNACAO)`, sua diferença IDENT5, `Count(POPULACAO_ESTIMADA)=1`, `Sum(POPULACAO_ESTIMADA)=F3`, `Count(QTD_LEITOS_SUS)=0`. Somente igualdade exata e ausência de vazamentos resultam em PASS candidato.

## 3. Implementação versionada e limites

**Único executor preparado:** `tools/Invoke-SadPhaseViiiC3b2SameRolePop.ps1`, adaptado estritamente do [C3-B1 versionado](../../tools/Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1), sem alterar a fonte anterior. Parâmetros: `-Root`, `-SourceQvw`, `-F1F2Dir`, `-F3Dir` e **switch `-RunQlik`, proibido sem autorização específica futura**.

Salvaguardas estáticas conferidas: branch correta, script rastreado e limpo, fonte TEMP T24 sob `%TEMP%/SAD_VIII_T24_<GUID>/SAD_VIII_T24_ANNUAL_TEST.qvw`, SHA-256 congelado `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`; exatamente 10 QVDs extração + 12 transformação; `LINK_ANALISE.qvd` SHA-256 `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB`; exatamente três QVWs canônicos; snapshots SHA antes/depois, sem STORE/Reload/Save dos originais. Executor imprime commit e SHA de script ao rodar; gera pasta isolada `%TEMP%/SAD_VIII_C3B2_<GUID>`.

**Modo referência (sem `-RunQlik`):** confere SHA F1/F3, lê as colunas reais, escolhe o par determinístico e escreve `c3b2_oracle_pair.csv`, inventários `qvd_before.csv`, `qvd_after.csv`, `canonical_qvw_before.csv`, `canonical_qvw_after.csv`; veredito previsto `VERDICT=PASS_REFERENCE_PRECHECK_ONLY_C3B2_QV_NOT_RUN`. **Ainda não executado no Windows**, portanto nenhum PASS declarado.

**Modo físico (futuro e separado):** após parser Windows PASS, preflight referência auditado e autorização expressa, executor somente copia QVW T24 validado para uma pasta TEMP nova, abre cópia pelo COM QlikView, não recarrega nem salva canônicos; emite `c3b2_reconciliation.csv` com todas as comparações e, **somente após preservação dos hashes**, `VERDICT=PASS_LOCAL_C3B2_SAME_ROLE_POP_CANDIDATE_ONLY` ou `BLOCKED_OR_INCONCLUSIVE`. Não há execução física neste PR.

## 4. Preflight operacional futuro — sem execução automática

**Ambiente:** PowerShell real no Windows do responsável com QlikView 12; Codex Local somente com acesso efetivo ao mesmo filesystem. **Não presumir** que Work em nuvem tem o TEMP persistente do Windows.

1. Confirmar `main` atual e revisar o PR Draft; o clone local pode estar na branch histórica C3-B1, com **dez QVWs não rastreados**. Preservar o inventário CKO anterior, revalidar checkout e comparar **árvore de caminhos de destino contra todos os arquivos não rastreados**, não somente 10 QVWs; confirmar HEAD remoto e ausência de alterações rastreadas. Não usar `-f`, `git clean`, reset, rebase, pull automático ou sobrescrever binários.
2. Somente depois de guardas/colisões PASS, obter novo checkout da branch exata de C3-B2 sem forçar, revalidar hashes dos QVWs/QVDs ante os anteriores e preservar o resultado de forma persistente. **Um checkout não é evidência de parser nem do QlikView**.
3. Rodar `[System.Management.Automation.Language.Parser]::ParseFile(...)` sobre o script versionado no commit efetivamente selecionado. Se erro, STOP sem `-RunQlik`.
4. Localizar **sem recriar** T24 pelo SHA, F1/F2 pelo manifesto e F3 pelo manifesto; o diretório F3 **ainda não foi identificado neste gate**. Confirmar hashes de F1/F3 sem reprocessar CSVs originais nem recarregar QVD.
5. Revalidar persistência TEMP entre **dois processos PowerShell independentes** para logs/inventários do runner; execução do modo referência requer autorização de preflight operacional, mas **não** COM. Se qualquer condição falhar, STOP preservando logs; não repetir por tentativa e erro.
6. Preparação e revisão encerram aqui. Solicitar **autorização explícita e posterior para uma única execução `-RunQlik`**, após conhecer par e POP reais e os estados do preflight. Não iniciar C4/P5/IX.

**PASS preparatório deste PR:** os campos F1/F3 rastreados ao gerador histórico, runner/versionamento e contrato de evidências publicados em Draft, e revisão estática de source. **Não** parser Windows, existência atual dos binários e oráculos, execução COM ou validação física.

**Fronteiras:** `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP:** ao publicar script + documento em PR Draft com fonte/salvaguardas delimitadas; nenhum merge, execução física ou alteração de artefatos nesta etapa.
