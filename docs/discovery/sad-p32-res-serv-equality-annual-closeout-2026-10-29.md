# P3.2 — RES=SERV × RES≠SERV anual (2017–2019) | Closeout numérico restrito

**Gate:** `SAD-P32-SIH-RES-SERV-EQUALITY-ANNUAL-READONLY-01`  
**Veredito:** `PASS_RESTRICTED` **em execução local Windows/Python reportada pelo responsável**, com stdout e JSON colado inspecionados nesta sessão; **não** é execução independente/CI, aceite visual, associação cross-fact ou homologação de produção.  
**Data:** 29/10/2026, execução registrada em `2026-10-29T20:15:49.771299+00:00` (17:15:49 UTC−03).  
**Git:** baseline integrada `main@8a3144263e424078dbab6038d8a8b7089e3a40b2` ([PR #190](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/190) MERGED); gate P3.2 na branch `test/sad-p32-sih-res-serv-equality-annual-readonly-01`, [PR #191](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/191) Draft **não integrado**. Fonte do script executado: `7cab8c12eaf2d6424dceb52f64aafaf50d623d2c`, previamente versionado; correções documentais posteriores não representam nova execução.

## Evidência recebida e controles

- **Entrada E1 somente leitura:** `C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv`. O log registra `1.016.979` bytes; SHA antes/depois: `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615` (igual ao pin). Schema de sete campos conforme [protocolo](sad-p32-res-serv-equality-annual-init-2026-10-29.md), **30.255 grãos únicos**, nenhuma duplicação, 36 competências.
- **Executores:** `tools/validate_sad_p32_res_serv_equality01.py` SHA-256 local reportado `A46FAE5838D132A38C7F2A497B05592A7E46936CD50A3BBCCFE221E21D4D3CCB`; módulo P1.3 reusado `80B18B9C58EB1AB8DF3EDFD651A78D0DFB90934082281E33CE754CDB300C9CD5`. Python local `3.14.8`; pré-verificações de árvore Git limpa, fetch/ff-only, ancestralidade da `main` e SHA E1 passaram no transcript.
- **Reconciliação de novas internações (competência):** 2017 = **183.532**, 2018 = **183.311**, 2019 = **188.246**; **555.089** no triênio. Classificação textual dos códigos RES/SERV: **294.635** em `RES_EQ_SERV`, **260.454** em `RES_NE_SERV`; participação `RES_NE_SERV` **46,9211%** (46,92%, duas casas). Ambos os recortes somam 555.089.
- **Decomposição AIH:** `qtd_registro_aih=566672` = `qtd_internacao=555089` + `qtd_continuidade=11583`. Saída reportada: **6 linhas** (3 anos × 2 classes); `divergences=[]`; `exit_code=0`, `GATE_PASS=True`.
- **Integridade negativa:** uma cópia do E1 recebeu LF adicional e foi rejeitada pela validação pinada com `E1_SHA256_MISMATCH`; `negative_test.rejected=true`; hash da cópia: `A09E49472C4A42D8E41DEE264EBD9C201575B69EB82E6C1DCAE4163F74906514`. Trata-se de **negativo integrado no processo positivo**, não de outra execução independente com `exit=2`.
- **CSV derivado:** `p32_res_serv_annual.csv` SHA-256 reportado `013E1ACF82D04F069A4067528F26DA840F033A9A74E2FF2B9FF9DE11453AD664`. O código contempla readback e reconciliações mês/ano/classe, mas os bytes do CSV e do manifesto **não** foram recebidos para auditoria independente.
- **Evidência persistente declarada no Windows:** `C:/Users/pedro/SAD_EVIDENCIAS/P32_20261029_01/` contendo, segundo o protocolo/runner, `p32_res_serv_annual.csv`, `p32_audit.json`, `execution.log`, `negative_e1_altered.csv` e `sha256_manifest.json`; **não adicionar ao Git**. Fonte nesta revisão: transcript PowerShell e JSON completo colado, com duas exibições do mesmo JSON (não duas execuções). O texto compartilhado no chat foi inspecionado e apresentou SHA-256 `2265978E0D90EAB742055AD9F9F5D4F7A0AF95AAEFB6FEB9989051AC3DDEC2B3`; esse hash identifica **somente o texto colado**, não prova o hash dos logs/artefatos Windows.

## Interpretação e limites

**FATO REPORTADO VALIDADO ARITMETICAMENTE NO TRANSCRIPT:** os três totais anuais e as duas classes somam 555.089, e novas + continuidades somam 566.672; sem divergência emitida pelo runner. A conferência desta sessão não leu o E1 original nem os derivados locais. A validação é **numérica/observacional**; `RES!=SERV` compara códigos, **não** comprova viagem individual; casos de residência externa à PB continuam no universo e não recebem denominador populacional artificial. `IDENT=5` não é internação nova; SIH/RD não mede pacientes únicos ou demanda reprimida. Não atesta filtros globais, UI, QlikView, `%LINK_KEY`, contratos de medidas/denominadores ou produção.

## Fechamento e próxima decisão

- `GATE_PASS=True` **somente no escopo local restrito**; `PR_MERGED=False` para o PR #191 neste fechamento; `VISUAL_ACCEPTED_GLOBAL=False`; `PRODUCTION_APPROVED=False`.
- **STOP P3.2 cumprido:** não executar novamente o E1/P3.2 para confirmar o mesmo resultado sem divergência concreta; não abrir múltiplas iterações por conveniência. Nenhum QVD, QVW, QVS, dado original, esquema acadêmico ou contrato físico alterado.
- **Próximo passo:** revisar o diff completo do [PR #191](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/191) e decidir integração separadamente. Próximo candidato analítico após fechamento de integração: **P3.3 — ranking dos pares observados `RES!=SERV`**, gate próprio e reuso do E1, sem iniciar automaticamente. Fase IX não autorizada.
