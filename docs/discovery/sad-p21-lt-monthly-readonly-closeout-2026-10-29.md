# SAD — P2.1 CNES/LT mensal observacional: fechamento numérico E4

**Gate:** `SAD-P21-LT-MONTHLY-OBSERVED-READONLY-01`  
**Data:** 29/10/2026  
**Estado restrito:** `PASS_E4_P21_MONTHLY_RECONCILED_RESTRICTED` (E4 + confronto entre duas implementações versionadas no **mesmo E4**).  
**Baseline verificada:** `main@63a5ace632c639b45881cd27f0fe738a816d41cb`, após integração dos PRs #183 e #184.  
**Autorização:** responsável solicitou “prossiga” para revisar/integrar #183/#184 e executar gate P2.1. Sem autorização para merge deste novo PR, QlikView/COM, alteração de QVD/QVW/QVS ou produção.

## 1. Fontes e executores

- E4 fornecido: `lt_cnes_leito_competencia(1).csv`, **1.301.572 bytes**, SHA-256 **antes/depois** `BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88` (MATCH AE01).
- E1 fornecido usado **apenas pelo oráculo A0 versionado**, não como associação analítica entre fatos: `sih_fluxo_competencia(2).csv`, SHA `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`.
- Novo validador `tools/validate_sad_p21_lt_monthly01.py`, **commitado ANTES da execução**: `0a2019a0f11dd1f118ef9b82b57774338d2c362a`. Git blob efetivamente executado `ec257966ecedb67e8bb4ed05410ff61f8a1fb658`; SHA-256 `F92CD192B59EBAC139296BD5D24FBD974B2EDF49DBCC8274CC70775B95FF4FDC`.
- Oracle A0 reutilizado da `main`: `tools/prepare_sad_a0_consumption_oracle01.py`, Git blob `c6d46c2ca17d3084858e8b667e49dfe3908865ac`, SHA-256 da cópia executada `A7333014297D3FF79791B1148B5369E27279F49EBA2E7E7BE0A37F9614FC62F0`. Este executor foi previamente versionado e a cópia local foi conferida por **Git blob idêntico**.
- Os dois CSVs foram copiados para diretório temporário fora do Git para satisfazer o contrato de nomes do A0. Os **originais permaneceram intactos**. A0 retornou `ORACLE_READY_NOT_QLIK_PASS`, com oracle JSON fora do Git, SHA-256 `15DCABEA82C63294C33A24F98613DCEEA348B7670479EC65BF89613FD17DC0C9`.
- O P2.1 executado em contêiner Python no commit indicado acima retornou `exit=0`, `PASS_E4_P21_MONTHLY_RECONCILED_RESTRICTED`; timestamp UTC `2026-10-29T16:39:55.069959+00:00`.

## 2. Reconciliação física do E4

| Controle do extrato | Observado | Desvio |
|---|---:|---:|
| Linhas / grão competência × SERV × CNES × TP_LEITO × CODLEITO | 35.518 únicas | 0 |
| Competências válidas 201701–201912 | 36/36 | 0 |
| Soma de `linhas_lt` apenas para reconciliação de linhas | 35.518 | 0 |
| Soma de `qt_exist` em todas as linhas/competências | 337.147 | 0 |
| Soma de `qt_sus` em todas as linhas/competências | 270.076 | 0 |
| Soma de `qt_nsus` em todas as linhas/competências | 67.071 | 0 |
| Identidade `qt_exist = qt_sus + qt_nsus` | 35.518/35.518 linhas | 0 |
| Códigos SERV distintos com linha | 105 | — |
| CNES distintos nos 36 meses | 233 | — |
| Pares SERV × mês com linha observada | 3.561 | 0 |
| Pares observados com `qt_sus > 0` | 3.464 | 0 |
| Pares observados com `qt_sus = 0` | 97 | 0 |

**Advertência metodológica obrigatória:** os somatórios de 337.147/270.076/67.071 acima são **somente controles aritméticos para verificar todas as linhas exportadas**, e NÃO são estoques anuais ou totais de leitos disponíveis num instante. As medidas de consumo aprovadas são somas **dentro de cada competência**, sem aditividade no tempo. As 4.467 células sem linha são um cálculo da grade **histórica** 223×36 documentada, **não** nova revalidação física do crosswalk C5.2 nesta execução. Não equiparar ausência de linha a `qt_sus=0`.

## 3. Série mensal e segundo cálculo versionado

- 36 registros únicos `competencia;linhas_lt;qt_exist;qt_sus;qt_nsus` materializados apenas como CSV derivado fora do Git.
- E4 `201701`: `linhas_lt=1.003`, `qt_exist=9.597`, `qt_sus=7.772`, `qt_nsus=1.825`.
- E4 `201912`: `linhas_lt=964`, `qt_exist=9.065`, `qt_sus=7.140`, `qt_nsus=1.925`.
- **108/108 concordantes** entre `validate_sad_p21_lt_monthly01.py` e `prepare_sad_a0_consumption_oracle01.py` (36 meses × 3 indicadores). **Ambos os algoritmos usam o mesmo E4; isso NÃO equivale a 108/108 exportados ou lidos do QlikView nesta execução.** O A0 tem alias histórico P2.2; este gate corresponde a **P2.1** do escopo de 14 visuais. P2.2 atual (composição SUS/não-SUS) **não** foi executado aqui.

## 4. Negativos e hash dos artefatos externos

- **Negativo 1 — E4 alterado em cópia:** execução do mesmo script commitado retornou `exit=2` e `VERDICT=FAIL_HARD_STOP: E4 SHA-256 differs from pinned AE01 input`. SHA E4 original inalterado.
- **Negativo 2 — oracle A0 alterado em cópia:** execução do mesmo script commitado com E4 original retornou `exit=2`, detectando diferença deliberada de `qt_sus` em `201701`: esperado modificado 7.773, observado 7.772.
- Tentativa inicial de negativos com `--output-dir` já ocupado retornou `FAIL_HARD_STOP: output evidence already exists; refuse overwrite` (controle de não sobrescrita), **não** foi contabilizada como prova da detecção de dados alterados. Os negativos válidos acima usaram diretórios vazios separados.

| Evidência (fora do Git) | SHA-256 |
|---|---|
| `p21_lt_monthly.csv` | `570D418BA0D05C6B5730FFE5A650863C5D7D4BB23A3EF35F512D47D0BAFCE761` |
| `p21_lt_audit.json` | `F432117C8498F2DECB4E98ACE5A9D628DF42B06C23F608C2DD2FF06020BB3BE6` |
| `p21_execution_stdout.txt` | `CA179EDEAFA73EB14E7FD549998E4C78E35D94F3C82D3D9BA3977F144E05A1BD` |
| `p21_a0_stdout.txt` | `6CCFE6F2348DE3A419385DB2B72A8CDE6F0D130A31F9155AC0157F7169CADD46` |
| `p21_negative_sha.txt` | `AA8B07F9B18F1273732C5F5D13488745507B3F3FC22AB6B48692973BE415D838` |
| `p21_negative_oracle.txt` | `1497A564F6500CFF9BA0C7A1A69C897F6F5C845896F3B4ED1D4326B51663BCD5` |
| `p21_a0_oracle.json` (temporário) | `15DCABEA82C63294C33A24F98613DCEEA348B7670479EC65BF89613FD17DC0C9` |

## 5. Parecer, pendências e STOP

**FATO VERIFICADO:** E4 original com hash pinado, 35.518 grupos únicos, 36 meses, 108 valores mensais reproduzidos pelo segundo código versionado, integridade da decomposição e negativos de SHA/oráculo. A0 histórico é **mesmo insumo**, não um readback independente de dashboard.

**HIPÓTESE DE MODELAGEM:** nenhuma nova. E4 é dado LT observado, sem recorte hospital-only aprovado, sem interpretação de leitos ocupados ou taxa de ocupação. Contagem zero em par com linha ≠ ausência de linha. A classificação CNES histórica T29 segue não aprovada.

**DECISÃO PENDENTE:** confirmação separada de UI/gráficos/filtros QlikView, validade histórica hospitalar/legendas, crosswalk 223 no gate de grade completa, Fase IX e produção. `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**STOP:** fim da análise descritiva **P2.1**. Nenhum merge automático, P2.2 ou outros visuais iniciados; nenhum QVD/QVW/QVS alterado. Próximo passo: revisão do PR P2.1 e decisão de integração, depois gate distinto P2.2 com competência explícita caso autorizado.
