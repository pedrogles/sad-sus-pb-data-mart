# Fase VIII — C3-B1 | Encerramento físico restrito (20/10/2026)

**Estado:** `C3B1_PHYSICAL=PASS_LOCAL_C3B1_ASYMMETRIC_ROLE_FLOW_CANDIDATE_ONLY` (conforme execução Windows/QlikView 12 reportada pelo operador); `C3B1_EVIDENCE_REVIEW=EXPORTED_EVIDENCE_CONSISTENT`. **Este é um PASS candidato restrito, não homologação geral ou de produção.**

## 1. Fontes e proveniência

- Protocolo: [C3-B1](phase-8-c3b1-asymmetric-role-flow-2026-10-19.md), [bootstrap](bootstrap-work-c3b1-physical-validation-2026-10-19.md); PR [#125](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/125), branch `test/phase-viii-c3b1-asymmetric-roles-20261019` (Draft, **não integrado à main** no momento da revisão).
- **Commit executado e impresso no stdout físico:** `91679378c507e2208e284e973bf8249036c0bb72`. Qualquer commit posterior que apenas registre este documento **não foi executado** no QlikView.
- Executor versionado: `tools/Invoke-SadPhaseViiiC3b1AsymmetricRoles.ps1`, SHA-256 reportado `EAA47EE8D261FF854F9E001F47AEB825C5F668AA1A9A7B410FA5BC61388B7164`.
- Origem T24 TEMP validada por SHA-256 reportado `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`; a execução COM utilizou somente cópia descartável, de acordo com o runner e stdout.
- Oráculo F1: o manifesto do pacote e os dois stdout concordam no SHA-256 de `F1_fluxo_ano.csv`: `203DF1D1CE5B4325F0F9E8F590850D3EEF18D62EBDECF34400959A6267349F3B`. **O F1 CSV original não está no ZIP auditado.**
- Pacote de evidências fornecido para auditoria: `c3b1_physical_evidence_review.zip`, **9 arquivos**, 11.505 bytes, SHA-256 `D1CB78ED6B28A652158655ADC3C5F9CEE29D2DBA4FD8FFC1B4CF16BEE151156E`. Manifesto incluído com SHA-256 `926D5EE06373D6B30C3617501A9E81F2F0E6C16CFEF98A9EF1AAF25113EF025B`. **Não versionar** ZIP, stdout, CSVs, QVDs ou QVWs no Git; preservar original local fora da árvore.
- Execução relatada no Windows real: persistência independente do token e dos inventários CKO validada em dois processos, checkout não forçado com 10 QVWs não rastreados e 22 QVDs preservados, parser local PASS, preflight sem COM PASS, **uma** sessão `-RunQlik` com exit code `0`, sem recarga/STORE/salvamento de binários canônicos conforme runner.
- Inspeção independente nesta conversa foi **dos nove arquivos exportados**, e não dos binários originais ou da sessão COM remota.

## 2. Prova realizada: somente um fluxo assimétrico

**Filtro COM reportado:** `PERIODO_ANO=2018`; `RES_COD_DATASUS_6=250180`; `SERV_COD_DATASUS_6=250750` (`R != S`); `PERIODO_COMPETENCIA` sem seleção.

| Verificação | F1 esperado | QlikView reportado | Resultado |
| --- | ---: | ---: | --- |
| Registros RD / `Sum(QTD_REGISTRO_AIH)` | 4.027 | 4.027 | `PASS_CANDIDATE` |
| Internações elegíveis / `Sum(QTD_INTERNACAO)` | 3.806 | 3.806 | `PASS_CANDIDATE` |
| Continuidades `IDENT=5` (= diferença) | 221 | 221 | `PASS_CANDIDATE` |
| `Count(POPULACAO_ESTIMADA)` alcançável | 0 | 0 | `PASS_CANDIDATE` |
| `Count(QTD_LEITOS_SUS)` alcançável | 0 | 0 | `PASS_CANDIDATE` |

`3806 + 221 = 4027`. `IDENT=5` não é uma internação nova. **Zero de registros POP/LT alcançáveis nesse contexto associativo não significa população municipal zero, leitos reais zero, cobertura validada ou denominador aprovado.** Os CSVs `c3b1_oracle_pair.csv`, `c3b1_reconciliation.csv` e o stdout físico convergem nos valores.

## 3. Integridade e nível da auditoria

- `qvd_before.csv` versus `qvd_after.csv`: **22 linhas** (10 extração + 12 transformação), campos `Path`, `Length`, `SHA256`, arquivos **byte a byte idênticos**. O inventário registra `LINK_ANALISE.qvd` SHA-256 `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB`.
- `canonical_qvw_before.csv` versus `canonical_qvw_after.csv`: **3 linhas**, igualmente **byte a byte idênticos**.
- Stdout físico inclui `C3B1_RESULT=PASS_CANDIDATE`, `VERDICT=PASS_LOCAL_C3B1_ASYMMETRIC_ROLE_FLOW_CANDIDATE_ONLY`, `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`, `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True` e `SOURCE_T24_QVW_SHA256_UNCHANGED=True`.
- O ZIP tem nove membros e passou pela verificação estrutural de integridade; logs físico e de referência, inventários, manifesto e CSVs foram inspecionados. **Os binários QVD/QVW, o F1 CSV original e a sessão COM não foram reabertos/auditados de forma independente.** Assim, não converter a consistência das saídas em certificação física independente dos artefatos.

**Resultado aceito apenas no limite contratado:** um fluxo SIH/RD 2018 com papéis R/S assimétricos e ausência de POP/LT alcançáveis sob esse filtro; `C3B1_CLOSEOUT=COMPLETED_WITH_LIMITS`. **STOP**: não repetir C3-B1, não alterar runner, não reexecutar T24–T26, não fazer merge, não modificar QVD/QVW original.

## 4. Handoff proposto — fora deste gate

O próximo passo **proposto, não executado**, é uma revisão C3 **READ-ONLY** e de escopo único: confrontar testes de associações/chaves já existentes com a matriz de papéis e filtros da [V2 §62.6](phase-6-semantic-v2-approved-2026-10-14.md), identificar as lacunas factuais remanescentes e determinar se há **um** teste físico adicional que agregue prova realmente necessária. Critério de encerramento: matriz com `NO_ADDITIONAL_PHYSICAL_TEST_NEEDED` justificado ou hipótese e critérios de aceite de um C3-B2 **pendente de autorização separada**. Depois, respeitar a sequência C3 → C4 (contrato físico de medidas/denominadores), sem iniciar dashboards/Fase IX.

**Fronteiras não alteradas:** `C2_FULL=NO_GO_NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`, `P5_D2_UI=NOT_TESTED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. A decisão restrita de C2 está documentada no [PR #135](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/135), também Draft.

**Nenhuma mudança estrutural ou semântica é autorizada por este documento.**
