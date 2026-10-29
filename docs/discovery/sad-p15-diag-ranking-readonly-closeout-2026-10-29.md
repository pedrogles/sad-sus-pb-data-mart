# SAD P1.5 — Ranking por diagnóstico principal E3, 2017–2019

**Gate:** `SAD-P15-DIAG-RANKING-READONLY-01`  
**Status:** `PASS_E3_P15_RECONCILED_RESTRICTED` exclusivamente numérico/read-only; sem QlikView, CID histórica, UI ou produção.  
**Data:** 29/10/2026; **baseline main:** `b644f70686ee825ae5356456cf3744f288407ad7`, após merge do PR #182.  
**Execução autorizada:** solicitação do responsável “prossiga” após planejamento P1.4→P1.5→início P2. Branch isolada e nenhum merge implícito.

## 1. Arquivo, código e rastreabilidade

- E3 anexado `sih_diagnostico_competencia(1).csv`, 1.378.839 bytes, SHA-256 `3FC6C78746D74F815EBED62F1AF88D950F6BFB303343FBD199AA436E2AE7D230`, igual à referência AE01.
- Esquema exato: `competencia;ano;diag_princ;qtd_registro_aih;qtd_internacao;qtd_continuidade`.
- Executor `tools/validate_sad_p15_diag_ranking01.py` **commitado antes de executar** no commit `b86ff8a985ad2c233ce33733a473130fdcd3dc33`; SHA-256 `8E7889C7529C6CF13C517D621DB74DAC5F900B0914B04DED90C2A8AFC7D2AFC2`; blob Git do código executado `aa9e34109812cf33a39cd1c82f0483805da34ffa`.
- Execução em contêiner Python, com `--e3`, `--source-commit`, `--script-sha256`, `--output-dir`. Resultado positivo `exit=0` e `PASS_E3_P15_RECONCILED_RESTRICTED`. Fonte protegida por hash antes/depois, saídas apenas fora do Git.
- Teste negativo sobre **cópia** alterada: `exit=2`, `VERDICT=FAIL_HARD_STOP: E3 SHA-256 does not match the pinned AE01 export`. Nenhum E3 original foi modificado. Evidência negativa não comprova todos os tipos possíveis de mutação.

## 2. Controles físicos E3

| Controle | E3 observado | Divergência esperada |
|---|---:|---:|
| Grupos únicos competência × DIAG_PRINC | 56.703 | 0 |
| Competências 201701–201912 | 36/36 | 0 |
| Internações novas 2017 | 183.532 | 0 |
| Internações novas 2018 | 183.311 | 0 |
| Internações novas 2019 | 188.246 | 0 |
| Total internações novas | 555.089 | 0 |
| Total registros AIH | 566.672 | 0 |
| Continuidades | 11.583 | 0 |
| Grão duplicado / código diagnóstico vazio ou malformado | 0/0 | 0 |

Validação de inteiros não negativos, registro AIH = internações novas + continuidade para cada linha, ano coerente com competência e códigos alfanuméricos CID representados por três ou quatro caracteres (`[A-Z][0-9]{2}[A-Z0-9]?`). Esta é somente sintaxe observada; **não** certifica vigência CID por competência.

## 3. Ranking por código DIAG_PRINC

| Posição | DIAG_PRINC | Internações novas | Participação exata arredondada (%) |
|---:|---|---:|---:|
| 1 | O800 | 28.747 | 5,1788 |
| 2 | O809 | 21.530 | 3,8787 |
| 3 | J189 | 17.985 | 3,2400 |
| 4 | O829 | 14.216 | 2,5610 |
| 5 | A09 | 9.959 | 1,7941 |
| 6 | O034 | 9.473 | 1,7066 |
| 7 | O820 | 8.910 | 1,6051 |
| 8 | N390 | 8.888 | 1,6012 |
| 9 | O828 | 6.977 | 1,2569 |
| 10 | J128 | 6.366 | 1,1468 |
| **Top 10** | | **133.051** | **23,9693** |
| **Demais 5.463 códigos** | | **422.038** | **76,0307** |
| **Total 5.473 códigos** | | **555.089** | **100,0000** |

A soma fecha **pelas contagens**, não por somar percentuais individuais já arredondados. Controles exploratórios históricos `O800=28.747` e `O809=21.530` foram **confirmados novamente** e não presumidos.

## 4. Evidências locais fora do Git

| Artefato | SHA-256 |
|---|---|
| `p15_diag_ranking.csv` — 5.473 posições | `3D3CA5EA4D58CBFA276EAC53E02476077A2F141175D40B9FB8B7BDF4649C0BDD` |
| `p15_diag_audit.json` | `9372300671048091085D0059D4CA3DC19CBA5B033F1B24C1423545CA23B4EB82` |
| `p15_execution_stdout.txt` | `7D981922A519C5459657DF8C775C2D14829F35A987667C3DBC20E0F1C083B0FD` |
| `p15_negative_sha.txt` | `7E90BE8605F1C0CA7A35BD39927EC28B2134A99B064FCD2F13B5F517EE46B2AF` |

## 5. Conclusão e limites

**FATO VERIFICADO:** E3 pinado reconcilia total/período e ranking por código, sem duplicatas e com decomposição coerente, com código versionado executado e hashes conferidos.

**HIPÓTESE DE MODELAGEM:** nenhuma alteração. Agrupamento por `diag_princ` corresponde à medida administrativa `sum(qtd_internacao)` do próprio E3. Não é incidência, prevalência, mortalidade ou pacientes distintos.

**DECISÃO PENDENTE:** associação histórica dos rótulos CID, cross-filter por RES/SERV/procedimentos não presentes em E3, validação de interface e aprovação acadêmica/produção. Manter QlikView 12 e arquitetura do Boundary 7. O P2 é outro gate, com E4 e medidas de snapshots sem aditividade no tempo.

**STOP P1.5:** somente closeout numérico E3. Não fazer merge sem revisão e autorização, não tocar QVD/QVW/QVS, não executar P2 por decorrência do PASS P1.5.
