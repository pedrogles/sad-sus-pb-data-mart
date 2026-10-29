# SAD — P1.4: Ranking por procedimento realizado (E2) — closeout read-only

**Gate:** `SAD-P14-PROC-RANKING-READONLY-01`
**Data da execução:** 29/10/2026
**Resultado:** `PASS_E2_P14_RECONCILED_RESTRICTED`, exclusivamente contagens e agregação de E2.
**Main de partida:** `c4bf982c82e62841455b8f5bde2e1df8144234db` (após merge dos PRs #180 e #181).
**Autorização:** retomar o gate P1.4 já iniciado ao receber o E2 enviado pelo responsável. Não inclui merge, QlikView, Fase IX ou início automático de P1.5/P2.

## Insumo e executor realmente verificados

- Arquivo E2 original anexado: `sih_procedimento_competencia(1).csv`, 646.155 bytes.
- SHA-256 antes e depois: `81FCBD576EFE48560EE1666A443E3E73158179972E38241A48928C904D03B6A2`, exato pin de AE01.
- Esquema: `competencia;ano;proc_rea;qtd_registro_aih;qtd_internacao;qtd_continuidade`.
- Executor Python: `tools/validate_sad_p14_proc_ranking01.py`, **commitado antes de executar** no commit `f1459268046c0df1c3a2691338af5f25597f44e2`.
- SHA-256 do script executado: `E5654F003476848CBCCBECDF12864B6F709F36DCEDEE7443C2FA367870F12511`.
- Git blob SHA-1 do arquivo versionado e do arquivo executado: `c2d688c3647f34724e3f594618d86587a0c302cf`.
- Execução positiva no contêiner Python com `--e2`, `--source-commit`, `--script-sha256`, `--output-dir` (saídas derivadas **fora do Git**). UTC `2026-10-29T15:47:44.649333+00:00`, exit code 0. Não houve QlikView, COM, Windows local, QVD/QVW/QVS.
- Controle negativo: cópia do E2 com código alterado em uma linha foi rejeitada pelo MESMO script commitado, exit code 2 e texto `VERDICT=FAIL_HARD_STOP: E2 SHA-256 does not match the pinned AE01 export`. Hash original permaneceu idêntico.

## Reconciliação com E2 real

| Controle | Observado | Esperado | Delta |
|---|---:|---:|---:|
| Grupos competência × proc_rea | 21.031 únicos | 21.031 | 0 |
| Competências 201701–201912 | 36 | 36 | 0 |
| Internações novas 2017 | 183.532 | 183.532 | 0 |
| Internações novas 2018 | 183.311 | 183.311 | 0 |
| Internações novas 2019 | 188.246 | 188.246 | 0 |
| Total novas | 555.089 | 555.089 | 0 |
| Total registros AIH | 566.672 | 566.672 | 0 |
| Total continuidades | 11.583 | 11.583 | 0 |
| Chaves duplicadas | 0 | 0 | 0 |
| Codificação de procedimento inválida/vazia | 0 | 0 | 0 |

O script validou linha a linha: período e ano, código `proc_rea` numérico de 10 posições, campos inteiros não negativos, `qtd_registro_aih=qtd_internacao+qtd_continuidade` e unicidade do grão. `IDENT=5` está na medida de continuidade e não incrementa `qtd_internacao`.

## Resultado de ranking (códigos, sem descrição histórica SIGTAP)

| Ordem | PROC_REA | Internações novas | Participação (%) |
|---:|---|---:|---:|
| 1 | 0310010039 | 55.157 | 9,9366 |
| 2 | 0411010034 | 47.879 | 8,6255 |
| 3 | 0303140151 | 39.035 | 7,0322 |
| 4 | 0303010061 | 17.121 | 3,0844 |
| 5 | 0411010026 | 14.532 | 2,6180 |
| 6 | 0303010037 | 11.284 | 2,0328 |
| 7 | 0303140046 | 11.199 | 2,0175 |
| 8 | 0411020013 | 10.733 | 1,9336 |
| 9 | 0407030026 | 9.352 | 1,6848 |
| 10 | 0310010047 | 9.344 | 1,6833 |
| **Top 10** | | **225.636** | **40,6486** |
| **Demais 1.239 códigos** | | **329.453** | **59,3514** |
| **Total 1.249 códigos** | | **555.089** | **100 exatos** |

Ordem decrescente pela medida, desempate por código. Percentuais arredondados a quatro casas, **não** usar soma de parcelas já arredondadas como prova do fechamento. O valor exploratório anterior do procedimento `0310010039=55.157` **coincidiu**, assim como o Top 10 exploratório ~40,65%, sem serem presumidos para PASS.

## Artefatos fora do Git

- CSV integral `p14_proc_ranking.csv`: 1.249 linhas de códigos + cabeçalho; SHA-256 `333F69899B3C2E3204187AB029C2703B4A7C4338E919C6D25DDF06EA6AB50E9D`.
- JSON `p14_proc_audit.json`: SHA-256 `A86A1AF5BE64358DAA8FD00C81C2A6AC5B1A88D37DBC93FCAD5AA36223942207`.
- Stdout `p14_execution_stdout.txt`: SHA-256 `BFD377A9354B08B29DC65EF3F162EF7017E9CF39890EAC5F2C329581DD0AF8BE`.
- Negativo `p14_negative_sha.txt`: SHA-256 `8B3B29B40C1449ED3A63D0592772A441A8E01F34802933DB6D893521597217CE`.

## Inventário de insumos recebidos para gates futuros

Todos os hashes foram conferidos **apenas como disponibilidade e identidade de arquivo**, sem executar P1.5/P2:
- E1 `sih_fluxo_competencia(2).csv`: `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`.
- E3 `sih_diagnostico_competencia(1).csv`: `3FC6C78746D74F815EBED62F1AF88D950F6BFB303343FBD199AA436E2AE7D230`.
- E4 `lt_cnes_leito_competencia(1).csv`: `BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88`.

## Parecer

**FATO VERIFICADO:** PASS restrito numérico P1.4, com entrada pinada, validador versionado antes da execução, total e distribuição dos 1.249 códigos reconciliados, e controle negativo por cópia alterada.

**HIPÓTESE DE MODELAGEM:** nenhuma. E2 não tem dimensões RES/SERV e não permite sua filtragem sem integração adicional comprovada. Nomes, categoria ou hierarquia SIGTAP historizada **não** foram auditados, portanto não foram inventados.

**DECISÃO PENDENTE:** revisão e integração separadas deste PR; P1.5/E3 é candidato seguinte, exigindo autorização/gate próprios. QlikView 12, Boundary 7, três fatos/oito dimensões, demais contratos, UI, Fase IX e produção não alterados nem aprovados.

**STOP:** análise P1.4 encerrada no E2, sem P1.5, P2, QlikView nem publicação de dados de produção.
