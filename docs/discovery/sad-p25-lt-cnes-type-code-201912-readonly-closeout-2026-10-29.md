# SAD — P2.5 | CNES × tipo × código LT em 201912 — fechamento numérico restrito

**Gate:** `SAD-P25-LT-CNES-TYPE-CODE-201912-READONLY-01`  
**Baseline verificada:** `main@9c7b2a1ae23ad63100273d04804889b958fb51cc` após [PR #188](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/188) integrado.  
**Modalidade:** READ-ONLY / execução Python sobre E4 integral, controle P2.4 original e uma competência explícita.  
**Veredito:** `PASS_RESTRICTED_E4_P25_CNES_TYPE_CODE_201912` — **numérico/observacional apenas**, sem QlikView/COM, QVD/QVW/QVS, novas recargas ou produção.

## 1. Escopo aprovado e critérios

Conforme `docs/discovery/sad-analytical-scope-acceptance-01-2026-10-27.md`, P2.5 deve agrupar `cnes,tp_leito,codleito` **em uma competência**, calculando `sum(qt_exist)`, `sum(qt_sus)` e `sum(qt_nsus)`. Seleção: `201912`. Usam-se **somente códigos brutos**, sem nomes de tipo retroativamente preenchidos, contagem de hospitais operantes ou classificação hospital-only.

**Critérios de aceite numérico (todos satisfeitos):** SHA-256 de E4 e ranking P2.4 pinados antes/depois; esquema real compatível; unicidade do grão `cnes×tp_leito×codleito` no mês; `qt_exist=qt_sus+qt_nsus` em cada linha; 964 registros e totais 9.065/7.140/1.925; fechamento de todas as partições por código e tipo; reconciliação dos 95 municípios observados contra o ranking P2.4; executor versionado antes da execução, logs e negativos documentados.

## 2. Proveniência rastreável

| Recurso | SHA-256 / identificação |
|---|---|
| E4 original `lt_cnes_leito_competencia(2).csv` | 1.301.572 bytes, `BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88` |
| Ranking P2.4 `p24_ranking_201912.csv` | 1.784 bytes, `90058AEAD055B0C7ECF60594E731AB390B5DB609F42FF7A7C62FED4EF95964D7` |
| Executor `tools/validate_sad_p25_lt_cnes_type_code01.py` | **commit pré-execução `0f19fa85367dc11919a524705fbf12af8c72cc23`**, Git blob `4ece6cc6bb34446a235a724a4fac62b65e75c130`, script SHA-256 `BE81FFAC08BBDA0FBE343078AE00674B0BCDBFFCBFF20E0BDAA83EE746C3CBFC` |
| Execução positiva | `2026-10-29T17:40:41.485560+00:00`, `exit=0` |
| `p25_audit.json` | `505433D2C3842DD54F4BBA59811A9CA23FCC4CC1C7EA423E828A52F22E17C501` |
| `p25_grain_201912.csv` | `544C5B5C19190CD9402BADA4FB32C4A50B77372320AD8A1A04254CA04837637D` |
| `p25_type_201912.csv` | `AA1AB4868428B025273851114AA1DEFB80BC19A2E82EC3F74F1B18460216F68C` |
| `p25_type_code_201912.csv` | `A51FFC63ABB10C9D46336F9C160BCE69B006A348FD73DA460A11359F5C1BFF23` |
| `p25_manifest.json` | `91DE9D1C0C134CE9FD6C02D68980D15976C37AF66FAC36E3134AE3B80F1008E9` |
| Pacote externo `sad-p25-201912-evidence.zip` | 11.002 bytes, SHA-256 `79F28481EEB6FC5254A43E621EA103C8D2E0AB2E97E11724DE5CFD134867F411` |

O ZIP de evidências mantém artefatos derivados/logs/manifests **fora do Git**; não inclui os datasets originais. A comparação E4×P2.4 confronta a mesma linhagem CNES/LT, não uma segunda fonte oficial independente.

## 3. Resultado e reconciliação

**Recorte 201912:** 964 linhas LT e **964 chaves únicas** `cnes×tp_leito×codleito`; **204 identificadores CNES distintos**, **7 códigos brutos `tp_leito`**, **56 pares `tp_leito×codleito`**, e 95 municípios com LT. `qt_exist=qt_sus+qt_nsus` em **964/964 registros**.

| Código bruto `tp_leito` | Linhas LT | `qt_exist` | `qt_sus` | `qt_nsus` |
|---|---:|---:|---:|---:|
| `1` | 241 | 1.962 | 1.422 | 540 |
| `2` | 235 | 2.986 | 2.424 | 562 |
| `3` | 142 | 948 | 673 | 275 |
| `4` | 144 | 1.183 | 1.030 | 153 |
| `5` | 130 | 1.220 | 1.055 | 165 |
| `6` | 46 | 643 | 474 | 169 |
| `7` | 26 | 123 | 62 | 61 |
| **TOTAL** | **964** | **9.065** | **7.140** | **1.925** |

Todas as 56 partições `tp_leito×codleito` somadas fecham nos mesmos quatro totais, assim como as partições por tipo. Os **95/95 municípios** observados coincidem, campo a campo (quantidades e linhas), com o ranking P2.4 hash-pinado, sem divergência. **Não há imputação de linhas não observadas**, nem inferência sobre o número real de hospitais.

## 4. Negativos e alcance do PASS

- E4 alterado **em cópia isolada**: `exit=2`, `HARD_STOP_VALIDATION_DIVERGENCE: E4 SHA-256 mismatch`.
- P2.4 ranking alterado **em cópia isolada**: `exit=2`, `HARD_STOP_VALIDATION_DIVERGENCE: P2.4 ranking SHA-256 mismatch`.
- SHA-256 dos dois originais foi conferido novamente após a execução positiva e os negativos, sem alterações.
- Controle de integridade da evidência: manifesto e ZIP sem arquivos de produção ou originais.

**FATO VERIFICADO:** resultado numérico reprodutível com código commitado antes de rodar, logs e hashes, nos limites exatos de uma competência. **Não verificado:** funcionamento visual do objeto P2.5, QlikView/COM atual, ocupação, disponibilidade real, cobertura de estabelecimentos hospitalares ou legitimidade histórica de descrições T29.

**DECISÕES PENDENTES:** `T29_HISTORICAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `ZERO_REAL_COMPROVADO=NOT_PROVEN`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP:** P2.5 **numérico** encerrado. Somente código, documentação e proposta `current-state.md` em branch/PR Draft. Não realizar merge automático, não iniciar P3.1 ou QlikView/COM, não alterar QVD/QVW/QVS e não promover aprovação de produção.
