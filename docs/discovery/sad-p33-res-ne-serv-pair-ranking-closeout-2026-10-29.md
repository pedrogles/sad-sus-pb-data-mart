# P3.3 — Ranking de pares observados RES≠SERV | Closeout restrito (29/10/2026)

**Gate:** `SAD-P33-SIH-RES-NE-SERV-PAIR-RANKING-READONLY-01`  
**Estado:** `PASS_RESTRICTED` **reportado pelo operador em Windows/Python e conferido aritmeticamente no transcript**; `GATE_PASS=True`, `PR_MERGED=False`, `PRODUCTION_APPROVED=False`. Sem leitura independente dos bytes E1/CSVs/manifesto ou teste QlikView.  
**Base Git:** `main@ce9a1f5ee1f3221a3b64c93b692402d768396148` ([PR #191](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/191) integrado); [PR #192](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/192) permanece Draft/não integrado neste fechamento.  
**Script versionado antes do teste:** `tools/validate_sad_p33_res_ne_serv_pairs01.py` no commit executado `bd4454c5ff088c9d41873de8c7211987f73d322a`. Execução reportada: `2026-10-29T20:44:44.730818+00:00`, Python 3.14.8, `exit_code=0`.

## Fonte e integridade reportada

- E1 read-only: `C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv` (1.016.979 bytes); SHA-256 **antes/depois** `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615` (pin aprovado).
- Script P3.3 SHA-256 local reportado: `C472D921FC628B9264689AB4A1EFD8D1EAE1D06F5E5B9385B8740D3AF971B9FC`; script de apoio P1.3 SHA-256 `80B18B9C58EB1AB8DF3EDFD651A78D0DFB90934082281E33CE754CDB300C9CD5`. Conferidos estaticamente caminhos e commit Git, não o binário Python executado no Windows.
- Schema E1 com sete campos documentados no [protocolo P3.3](sad-p33-res-ne-serv-pair-ranking-init-2026-10-29.md); **30.255 grupos únicos** de E1, **36 competências**, nenhuma duplicidade; controles globais `qtd_registro_aih=566672`, `qtd_internacao=555089`, `qtd_continuidade=11583` reconciliados no runner. Novas anuais E1 183.532/183.311/188.246 (2017/18/19).

## Resultado P3.3 — E1 RES≠SERV

| Indicador | Resultado reportado |
| --- | ---: |
| Linhas E1 classificadas RES≠SERV | 28.189 |
| Pares direcionados RES≠SERV distintos e observados | **3.108** |
| Pares × ano com observação | **5.715** |
| Internações novas em 2017 / 2018 / 2019 | **84.949 / 86.250 / 89.255** |
| Internações novas RES≠SERV no triênio | **260.454** |
| Top 10 pares no triênio | **55.353** |
| Demais pares | **205.101** |
| Participação Top 10 entre RES≠SERV | **21,2525%** |
| Pares triênio observados com zero novas | **0** |
| Testemunho direcionado `251370→250750` | **12.176**, igual ao esperado |

Reconciliações visíveis no transcript: `84949+86250+89255=260454`, `55353+205101=260454`, `12176=12176`; `divergences=[]`. O runner também informa reconciliações por mês, ano e par nas três medidas, ordenação determinística e readback dos dois CSVs; **os próprios CSVs ainda não foram inspecionados nesta sessão**.

- CSV ranking `p33_ranking_res_ne_serv_trienio.csv`, SHA-256 reportado `9163AE95EEF5226D026D22120F4F95D1D4805D5EF47F2099ED55D11AF1598DEA`.
- CSV pares × ano `p33_pairs_annual_observed.csv`, SHA-256 reportado `9CE2A2C26C3EBEC2B7B3C6807B1B5E0DDDEB06D4E5E6397C8DB572C81E358D16`.
- Teste negativo em **cópia E1** com LF adicional rejeitado por `E1_SHA256_MISMATCH` (`negative_test.rejected=true`), cópia SHA-256 `A09E49472C4A42D8E41DEE264EBD9C201575B69EB82E6C1DCAE4163F74906514`; não representa processo negativo independente com exit=2.
- Evidências persistentes **declaradas** em `C:/Users/pedro/SAD_EVIDENCIAS/P33_20261029_01/`, fora do Git: `p33_audit.json`, `execution.log`, `sha256_manifest.json`, dois CSVs e cópia negativa. **Até este fechamento, foi recebido o transcript colado, não esses arquivos brutos**.

## Limites semânticos e STOP

O ranking cobre **pares direcionados com observação**, inclusive linhas com eventuais continuidades; ausência de linha para par/ano **não equivale a zero comprovado**. O resultado de zero pares observados sem novas internações no triênio não autoriza imputar zeros. `RES!=SERV` compara códigos, **não** comprova deslocamento individual, distância, pacientes únicos ou demanda reprimida; residentes externos à PB permanecem sem denominador populacional PB artificial. Não houve crosswalk/legenda municipal histórica verificada, validação física associativa, UI/COM QlikView 12, `%LINK_KEY`, alterações QVD/QVW/QVS ou aprovação de produção.

**STOP P3.3 cumprido no escopo numérico local reportado.** Não reexecutar sem divergência concreta; não iniciar automaticamente P3.4. Próxima ação: revisão do [PR #192](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/192), conferência opcional do `p33_audit.json` original e **autorização separada** para eventual merge. `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.
