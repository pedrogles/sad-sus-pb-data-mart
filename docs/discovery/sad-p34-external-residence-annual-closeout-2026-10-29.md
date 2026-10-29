# P3.4 — Residência fora da referência C5.2 PB × ano | Fechamento numérico restrito (29/10/2026)

**Gate:** `SAD-P34-SIH-EXTERNAL-RESIDENCE-ANNUAL-READONLY-01`  
**Veredito:** `PASS_RESTRICTED` **em execução local Windows/Python reportada pelo operador e conferida diretamente nos três anexos recebidos**. `GATE_PASS=True` (somente numérico/local), `PR_MERGED=False` no fechamento, `VISUAL_ACCEPTED_GLOBAL=False`, `PRODUCTION_APPROVED=False`. **Sem leitura independente dos arquivos E1/C5.2 originais ou validação QlikView/COM.**  
**Execução local reportada:** `2026-10-29T21:41:12.132945+00:00` (18:41:12 em UTC−03); Python 3.14.8; `exit_code=0`; `divergences=[]`.  
**Git:** baseline `main@ab76cb24f27fb3521ad30c3118c04e0fc93ec91c`, após [PR #192 — P3.3](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/192) MERGED. [PR #193 — P3.4](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/193) Draft/sem merge. Script versionado **antes** do gate em `c16ddbc0dcc6b6ed955fb35370c50e27220481aa`; atualizações apenas documentais posteriores **não** reexecutam o script.

## Fontes e preservação reportadas

- **E1 agregado SIH/RD**: `C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv`, 1.016.979 bytes, SHA-256 antes/depois `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`; 30.255 grãos distintos, 36 competências, registros AIH=566.672, novas=555.089, continuidades=11.583.
- **C5.2 referência municipal PB**: `EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.csv`, 31.322 bytes, SHA-256 antes/depois `FDF016E4EAF7A7B8B396D3908DA2EC6737944BC9AAF3E6018BADB763725C257D`; **223 pares DATASUS6↔IBGE7** distintos. Referência **derivada pelo projeto de dados IBGE oficiais**, não tabela nacional de equivalências publicadas. A classificação externa corresponde à **ausência na C5.2 PB**, não a um cadastro oficial nacional de residência.
- **Scripts e SHA-256 reportados no audit local:** P3.4 `A715AD61AB3D48A15181E186EC68DC10B1F6AF4C0E7E6AA2D93CB8AD6E0C244B`; C5.2 auditor `A67F54C08D8306149BB6636A0D65BD3E35C3C3405B0B086C199E7A5C8A57FEB7`; P1.3 reusado `80B18B9C58EB1AB8DF3EDFD651A78D0DFB90934082281E33CE754CDB300C9CD5`.
- **Negativos integrados em cópias:** E1 e C5.2 com LF adicional foram rejeitados (`e1_rejected=true`, `c52_rejected=true`) por SHA, sem processo de teste separado. Fontes originais com hashes pré/pós iguais no log local.

## Resultado anual — valores calculados no runner e recontados nos CSVs anexados

| Ano | Registros AIH externos | Novas externas | Continuidades externas | % externas das novas no ano |
| --- | ---: | ---: | ---: | ---: |
| 2017 | 1.491 | 1.463 | 28 | 0,7971% |
| 2018 | 1.665 | 1.638 | 27 | 0,8936% |
| 2019 | 2.046 | 1.966 | 80 | 1,0444% |
| **Triênio** | **5.202** | **5.067** | **135** | — |

- **PB incluída na C5.2:** 561.470 registros AIH, 550.022 novas internações, 11.448 continuidades. **Conferência das duas classes:** 561.470+5.202=566.672; 550.022+5.067=555.089; 11.448+135=11.583.
- **Grãos agregados E1 por classe, reportados no JSON:** 27.023 com residência na C5.2 PB + 3.232 fora = 30.255; **714 códigos distintos** de residência fora da C5.2, apenas no nível de código observado.
- **Saídas reportadas:** 6 linhas ano×classe, 3 linhas de residentes externos por ano. Nenhum denominador populacional PB associado a externos.

## Inspeção independente dos três anexos recebidos nesta conversa

Os **bytes dos anexos** foram lidos diretamente, com parse JSON/CSV e reconciliação das colunas e totais sem reexecutar o validador E1. Resultados:

| Anexo | Bytes inspecionados | SHA-256 dos bytes recebidos |
| --- | ---: | --- |
| `p34_audit.json` | 3.440 | `08105164B28379A54D070313807DCA5D67136176CFC566FBCF78E1BF840C7934` |
| `p34_residence_class_annual.csv` | 367 | `DB03F583C2406BD92860DB1DA8C818D0D57E9A28039005AB72F38A11305CD7DA` |
| `p34_external_residents_annual.csv` | 169 | `70DD1B424026360013F9F0465B2114C8A28085F5BCB611AD9F4F6A75485CB136` |

**Verificações independentes concluídas:** JSON parse válido, gate/commit e `PASS_RESTRICTED` coerentes com o transcript; 6 combinações únicas (3 anos × 2 classes) e 3 anos externos únicos; hashes dos dois CSVs **idênticos** aos campos correspondentes do JSON; decomposição `registros=novas+continuidades` em **todas as 9 linhas** dos dois CSVs; correspondência integral das linhas externas em ambos; totais anuais e trienais reconciliados com o JSON e com E1 global declarado; percentuais com arredondamento decimal a quatro casas conferidos contra as novas anuais do próprio JSON; duas classes reconciliadas nas três medidas. **Nenhuma divergência nos anexos.**

**Fronteira de independência:** os hashes conferem os **arquivos compartilhados no chat**, não provam que são byte a byte idênticos aos arquivos presentes no Windows. Não foram recebidos os bytes originais do E1, C5.2 QVD/CSV de entrada, manifesto, logs brutos ou QlikView. Os totais de 714 códigos e 3.232 linhas externas são declarações do runner, não dados brutos recontados de forma independente neste ambiente.

## Limites semânticos e STOP

`qtd_registro_aih` não é sinônimo de `qtd_internacao`: a diferença é continuidade administrativa. E1 não contém identificadores de pacientes únicos. **Residência fora da referência municipal PB não comprova deslocamento físico, cobertura nacional ou vínculo a população de outra UF**; não usar população PB como denominador dos externos. O recorte não valida internações por 1.000 habitantes, ocupação de leitos, filtros associativos, UI, Link Key, descrições históricas ou produção.

**STOP P3.4 cumprido:** não reexecutar P3.1–P3.4 sem divergência concreta. Preservar dados brutos, QVD/QVW/QVS e relatórios locais `C:/Users/pedro/SAD_EVIDENCIAS/P34_20261029_01/` fora do Git. **Próxima decisão**: revisão e eventual integração **com autorização distinta** do PR #193; após isso, avaliação separada das lacunas restantes e dos gates de implementação/consumo autorizados. `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.
