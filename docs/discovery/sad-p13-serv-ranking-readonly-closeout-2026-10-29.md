# SAD P1.3 — ranking SERV read-only (29/10/2026)

**Gate:** SAD-P13-SERV-RANKING-READONLY-01
**Estado:** PASS_E1_P13_RECONCILED_RESTRICTED (agregação numérica E1, não QlikView/produção)
**Main base verificada:** 2d56a6de8b980d6b729f34c16fedb23915dd7be9
**Permissão:** autorização do responsável para criar validador em branch e executar em read-only; nenhuma autorização de merge.

## Fonte, executor e evidência

- Extrato E1 sih_fluxo_competencia.csv, enviado à sessão como sih_fluxo_competencia(1).csv, 1.016.979 bytes.
- SHA-256 fonte antes/depois: F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615.
- Schema: competencia;ano;municipio_res;municipio_serv;qtd_registro_aih;qtd_internacao;qtd_continuidade.
- Script: tools/validate_sad_p13_serv_ranking01.py, commit **anterior à execução** 63359e9e07106446984e99937750cffcf2ec92b6.
- SHA-256 script executado: 76DA8EB5BEE42DF947D3F42B23D0297D9FAEEC1B153D906769A679DB0590AAF4.
- Git blob do script e cópia local concordaram: 8cf8020bcd277a24d53d8734fcd1f3ecc55b39e9.
- Ambiente: contêiner Python sem Windows/QlikView/COM. Execução em 2026-10-29T15:03:12.259975+00:00, código 0, veredito PASS_E1_P13_RECONCILED_RESTRICTED.
- Evidências derivadas mantidas **fora do Git**: p13_serv_ranking.csv, 65 posições, SHA-256 A8162AFBD55D494D6A86C94C1DDBEA2FC248DB9697C7C5E80229A13D6B3736E4; p13_serv_audit.json, SHA-256 EE5D94CEF5F3902B7FF7DAB23A13EA827C2F6AA70BB1677E02474E444D2AB22F; stdout e negativo de integridade.
- Teste negativo: cópia corrompida recusada pelo script commitado, exit=2, FAIL_HARD_STOP por hash; fonte E1 intacta.

## Reconciliação

| Controle | Observado | Delta |
|---|---:|---:|
| Grupos únicos competência × RES × SERV | 30.255 | 0 |
| Competências 201701–201912 | 36/36 | 0 |
| Internações 2017 | 183.532 | 0 |
| Internações 2018 | 183.311 | 0 |
| Internações 2019 | 188.246 | 0 |
| Internações novas no triênio | 555.089 | 0 |
| Registros AIH | 566.672 | 0 |
| Continuidades | 11.583 | 0 |
| Grãos duplicados / códigos SERV vazios ou malformados | 0 / 0 | 0 |

A decomposição registro=internaçao nova+continuidade foi conferida em todas as linhas.
O código valida sintaxe de SERV 25xxxx e RES de seis dígitos. A correspondência C5.2 de 223 municípios foi atestada historicamente no AE01; **a auditoria do crosswalk físico não foi repetida**.

## Top 10 códigos SERV

| Posição | Código | Internações novas |
|---:|---|---:|
| 1 | 250750 | 225.785 |
| 2 | 250400 | 137.396 |
| 3 | 251080 | 18.944 |
| 4 | 251370 | 18.033 |
| 5 | 250630 | 17.323 |
| 6 | 250370 | 16.509 |
| 7 | 251600 | 10.092 |
| 8 | 250890 | 9.274 |
| 9 | 251620 | 5.818 |
| 10 | 251140 | 5.788 |
| **Top 10** | | **464.962 (83,7635%)** |
| **Demais 55** | | **90.127 (16,2365%)** |
| **Total, 65 SERV** | | **555.089 (100% exato)** |

Os controles exploratórios secundários 250750=225.785 e 250400=137.396 foram reproduzidos, não presumidos. Todos os 65 códigos SERV estão no CSV integral de evidência. Sem atribuição de nomes geográficos.

## Parecer e STOP

**FATO VERIFICADO:** E1 com hash fixado, 36 competências, 30.255 grupos únicos, total/anual reconciliado, ranking completo 65 SERV com top 10 e demais e nenhuma omissão; execução por script commitado e hash validado.

**HIPÓTESE DE MODELAGEM:** nenhuma nova. Medida é soma de qtd_internacao por municipio_serv, e não agrupamento por residencia. IDENT=5 não incrementa internações novas.

**DECISÃO PENDENTE:** rótulos municipais geográficos/históricos dependem de conferência própria; comportamento visual, filtros, Link Key, medidas globais, Fase IX e produção continuam não aprovados.

**STOP:** P1.3 numérico encerrado. Sem alterar main, QlikView, QVD/QVW/QVS, modelos, P1.1/P1.2 ou iniciar P1.4.

**Nível de evidência:** arquivo real anexado validado por SHA, execução no contêiner com script commitado e artefatos de auditoria fora do Git. Não representa validação física QlikView, CI, avaliação do professor ou aprovação de produção.
