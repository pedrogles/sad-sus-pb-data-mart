# Fase VIII — C3-B2 | Closeout físico restrito (20/10/2026)

**Veredito auditável:** `C3B2_CLOSEOUT=COMPLETED_WITH_LIMITS`; `C3B2_PHYSICAL=PASS_LOCAL_C3B2_SAME_ROLE_POP_CANDIDATE_ONLY`; `C3B2_EXPORTED_EVIDENCE_AUDIT=PASS_CONSISTENCY_ONLY`. O gate de **um** cenário R=S terminou. **Não equivale** a `LINK_KEY_CONTRACT=APPROVED`, validação física global, aceite de medidas/denominadores, interface P5, painel, produção ou Fase IX.

## Proveniência e limites de execução

- **Branch PR Draft:** `test/phase-viii-c3b2-same-role-pop-20261020`, [PR #137](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/137), aberto e não integrado no momento da auditoria.
- **Commit efetivamente executado no Windows/QlikView 12 (reportado):** `ceb6c8b74b960e7e30b9dd4ada027e218da92712`; executor `tools/Invoke-SadPhaseViiiC3b2SameRolePop.ps1` SHA-256 `A2CBD4EC235EAFA7ACDC2C2DF6EF47CD3AAB2E026B869F4A32A017ABD51DE163`.
- **QVW TEMP T24 fonte:** `SAD_VIII_T24_ANNUAL_TEST.qvw` SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`; versão experimental foi aberta em cópia descartável no modo `-RunQlik` segundo log do executor. Nenhum `Reload/Save/STORE` canônico foi solicitado no runner.
- **Referências independentes:** F1 `F1_fluxo_ano.csv` SHA-256 `203DF1D1CE5B4325F0F9E8F590850D3EEF18D62EBDECF34400959A6267349F3B`, manifesto F1/F2 `926D5EE06373D6B30C3617501A9E81F2F0E6C16CFEF98A9EF1AAF25113EF025B`; F3 `F3_pop_municipio_ano.csv` SHA-256 `4AC341479A63EEA3FAA1FC2C20A3C2447C94294B940BDAFDFD9799BD555A7699`, manifesto F3 `9FE3543374870878915A2ABAE6A88DFDB07778FDDA9D506A3B87A2DD2D98DA08`. A própria F3 declara como insumos o SHA do F1 e do manifesto F1/F2, verificados no pacote.
- **Execução Windows reportada:** uma sessão física; PowerShell indicou `C3B2_PHYSICAL_EXIT_CODE=0` e `C3B2_PHYSICAL=PASS_LOCAL_CANDIDATE_PENDING_EVIDENCE_REVIEW`. Uma sessão foi demonstrada no log fornecido, não reproduzida remotamente.
- **Evidência exportada conferida fora do Windows:** `c3b2_physical_evidence_review.zip`, tamanho 47.576 bytes, SHA-256 `0CEEBAFD3A632C8F04DC992D7C6438E0271668A974B73CB91D2E80FCD5166264`, 12 membros, teste de integridade ZIP sem erro. Pacote permanece como artefato local/anexo da conversa, **não versionado** no repositório conforme `AGENTS.md`. Os dois `stdout.txt` vieram em UTF-16LE; os CSVs de saída PowerShell em UTF-8 BOM.
- **Diretório de evidência da sessão física (conforme stdout, não acessível diretamente por esta auditoria):** `%TEMP%\SAD_VIII_C3B2_77f2918d27ff4bba972ddbd98036573a`. O stdout físico foi conservado em `%TEMP%\SAD_C3B2_REFERENCE_LOG_5035d17ee32d4db0a970900b566f101b\c3b2_physical_stdout.txt`.

## Reconciliação independente dos CSVs do ZIP

Foram relidos e comparados diretamente `F1_fluxo_ano.csv`, `F3_pop_municipio_ano.csv`, `c3b2_oracle_pair.csv`, `c3b2_reconciliation.csv`, manifestos e os dois stdout. A auditoria refez seleção determinística a partir dos grupos reais do F1, não do `c3b2_oracle_pair.csv`:

| Controle | Oráculo independente | Exportação QlikView |
|---|---:|---:|
| Ano, residência e serviço | 2018 / `250750` / `250750` | Mesma seleção, segundo log |
| `QTD_REGISTRO_AIH` | 40.033 | 40.033 |
| `QTD_INTERNACAO` | 39.060 | 39.060 |
| Continuidades `IDENT=5` (diferença) | 973 | 973 |
| POP anual 2018 (F3) | 800.323 | 800.323 |
| `Count(POPULACAO_ESTIMADA)` | Esperado 1 | 1 |
| `Count(QTD_LEITOS_SUS)` | Esperado 0 sob residência selecionada | 0 |

O F1 contém uma única linha do fluxo `2018/250750/250750` e os totais cumprem `40.033=39.060+973`. Entre os fluxos `R=S` PB elegíveis em 2018, esse par é o maior, comprovando a escolha determinística do executor. O F3 contém uma única linha anual correspondente (`cod_ibge_7=2507507`) com 800.323 habitantes; 669 pares município×ano, 223 para cada ano 2017–2019, sem duplicidade. Os totais anuais PB recalculados do F3 coincidiram com os controles do gerador (2017: 4.025.558; 2018: 3.996.496; 2019: 4.018.127).

`c3b2_reconciliation.csv` reporta `PASS_CANDIDATE`, com `ReachablePOPRows=1`, `QlikPOP=800323` e `ReachableLTRows=0`; o stdout físico reporta os mesmos valores e `VERDICT=PASS_LOCAL_C3B2_SAME_ROLE_POP_CANDIDATE_ONLY`.

**Interpretação científica:** o teste demonstra **alcançabilidade associativa candidata** de **uma** linha POP anual sob a dupla seleção do mesmo município, não aprovação do denominador RES com filtro de serviço (matriz V2 classifica serviço como `B` para RES). O LT com zero linhas **alcançáveis** sob residência não afirma zero capacidade real, nem valida escopo hospitalar histórico.

## Auditoria dos inventários e restrições

- `qvd_before.csv` e `qvd_after.csv`: **22/22 entradas**, caminhos distintos, tamanhos e SHA-256 idênticos por arquivo, incluindo 10 QVDs de EXTRACAO e 12 de TRANSFORMACAO; `LINK_ANALISE.qvd` no hash congelado `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB`.
- `canonical_qvw_before.csv` e `canonical_qvw_after.csv`: **3/3 entradas**, arquivos `EXT.qvw`, `TRANSF.qvw`, `PAINEL.qvw`, tamanhos e hashes byte-identificados nos inventários.
- O stdout informa `ORIGINAL_22_QVD_SHA256_UNCHANGED=True`, `ORIGINAL_CANONICAL_QVWS_UNCHANGED=True` e `SOURCE_T24_QVW_SHA256_UNCHANGED=True`, no preflight e na sessão COM.
- **39 verificações de consistência dos artefatos exportados passaram**, incluindo integridade SHA dos CSVs F1/F3 contra os manifestos, dependência F3→F1, identificadores/códigos e reconciliação exata. Os **binários originais QVD/QVW não integram o ZIP**; portanto, não houve recálculo independente dos respectivos hashes físicos nem reprodução direta do COM neste ambiente. A classificação é `EXPORTED_EVIDENCE_AUDIT=CONSISTENT_WITH_REPORTED_COM`, não verificação independente do ambiente Windows.

## STOP e handoff

**Gate único C3-B2 encerrado com limites.** Não repetir `-RunQlik`, não estender o executor para outros municípios/anos, não regenerar QVD/Link nem iniciar C4 automaticamente.

A sequência vinculante do Boundary 7 permanece C3 → C4. Após avaliação formal independente do aceite físico associativo, **propor** novo gate C4 para contrato físico de medidas e denominadores. Não inferir que C3-B1 + C3-B2 homologaram o contrato global de chaves ou a matriz P5.

**Bloqueios preservados:** `C2_FULL=NO_GO_NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Nenhum merge ou alteração da `main` foi autorizado por esta auditoria.** O PR #137 deve permanecer Draft até decisão explícita sobre integração.
