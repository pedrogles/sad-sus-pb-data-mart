# SAD — P2.2 | Composição SUS × não SUS em 201912 (CNES/LT)

**Gate:** `SAD-P22-LT-COMPOSITION-201912-READONLY-01`  
**Data:** 29/10/2026  
**Parecer:** `PASS_RESTRICTED` — **derivação aritmética restrita dos controles E4 já reconciliados no P2.1**, sem novo processamento do E4 ou validação de UI/QlikView.  
**Baseline Git conferida:** `main@9d1fa99a76bc5fa40a417fed06db61760c5deaad`, após merge squash do [PR #185](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/185).  
**Escopo:** uma competência (201912), leitos *cadastrais observados*, base E4; nenhum outro visual ou gate.

## 1. Fonte de verdade e cadeia de evidências

- Contrato: [escopo analítico aceito D1–D3](sad-analytical-scope-acceptance-01-2026-10-27.md), P2.2 **atual**, diferente do antigo alias A0 “P2.2” (série mensal agora P2.1).
- E4 original do P2.1: `lt_cnes_leito_competencia(1).csv` (nome do arquivo fornecido; artefato lógico `lt_cnes_leito_competencia.csv`), **1.301.572 bytes**, SHA-256 **`BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88`**.
- Integridade **reaproveitada**, não reexecutada neste gate: [closeout P2.1](sad-p21-lt-monthly-readonly-closeout-2026-10-29.md) registrou SHA-256 do E4 antes/depois da execução, 35.518 grãos LT distintos e identidade `qt_exist=qt_sus+qt_nsus` em todas as 35.518 linhas. Executou em `2026-10-29T16:39:55.069959+00:00`; validador `tools/validate_sad_p21_lt_monthly01.py` foi versionado **antes** no commit `0a2019a0f11dd1f118ef9b82b57774338d2c362a`, Git blob `ec257966ecedb67e8bb4ed05410ff61f8a1fb658`, SHA-256 `F92CD192B59EBAC139296BD5D24FBD974B2EDF49DBCC8274CC70775B95FF4FDC`.
- Evidências P2.1 externas preservadas: `p21_lt_monthly.csv` SHA-256 `570D418BA0D05C6B5730FFE5A650863C5D7D4BB23A3EF35F512D47D0BAFCE761`; `p21_lt_audit.json` SHA-256 `F432117C8498F2DECB4E98ACE5A9D628DF42B06C23F608C2DD2FF06020BB3BE6`; `p21_execution_stdout.txt` SHA-256 `CA179EDEAFA73EB14E7FD549998E4C78E35D94F3C82D3D9BA3977F144E05A1BD`. Estes hashes são **reportados pelo P2.1**, sem recálculo local dos arquivos nesta execução.
- P2.1 confrontou **108/108 valores** (36 competências × 3 medidas) com `tools/prepare_sad_a0_consumption_oracle01.py`, **ambas as implementações consumindo o mesmo E4**. Não é evidência independente de exportação/visual QlikView.
- O E4 foi acessível para leitura de seu cabeçalho/linhas pelo acervo do Projeto, mas a cópia binária para este ambiente de execução foi recusada. Portanto, **não houve nova conferência direta do SHA do E4 neste P2.2**. Este resultado se ancora na integridade previamente estabelecida e documentada do P2.1, não em uma suposta nova leitura integral.
- Nenhum script novo foi necessário: a competência já foi agregada pelo **validador versionado e executado em P2.1**, e este P2.2 aplica apenas as fórmulas explícitas de proporção. Não se afirma nova execução Python de gate.

## 2. Recorte único e resultado numérico

**Linha reconciliada P2.1:** `competencia=201912;linhas_lt=964;qt_exist=9065;qt_sus=7140;qt_nsus=1925`.

| Medida | Total LT observado | Fórmula de participação sobre `qt_exist` | Participação |
|---|---:|---|---:|
| `SUM(qt_sus)` | 7.140 | `100 * 7140 / 9065` | **78,76%** |
| `SUM(qt_nsus)` | 1.925 | `100 * 1925 / 9065` | **21,24%** |
| **`SUM(qt_exist)`** | **9.065** | `100 * 9065 / 9065` | **100,00%** |

**Identidade exata:** `9065 - (7140 + 1925) = 0` leitos; **fechamento das parcelas:** `(7140 + 1925) / 9065 = 1` → **100% exatos**, antes do arredondamento.  
Valores sem arredondar: `78,764478764478…%` SUS e `21,235521235521…%` não SUS. Arredondar a 2 casas produz `78,76% + 21,24% = 100,00%`.

**Reprodutibilidade documental:** selecionar unicamente `competencia == '201912'` em `monthly` do `p21_lt_audit.json` ou no CSV mensal derivado P2.1, confirmar os quatro campos e aplicar as frações acima. Se for necessária reprodução a partir do E4 bruto, reutilizar `tools/validate_sad_p21_lt_monthly01.py` **exatamente na versão identificada acima** e os insumos pinados do P2.1; não é necessário inventar um novo contrato ou somar competências. A verificação dos negativos de SHA e oráculo também consta do closeout P2.1.

## 3. Alcance, suficiência e veredito

**FATO VERIFICADO (por reuso P2.1):** a competência `201912` existe, seu vetor de quantidades é `9065/7140/1925`, a identidade entre as três medidas fecha em zero e as participações fecham em 100%; há executor P2.1 versionado e registro de execução com hash do E4 antes/depois. O P2.2 não amplia a prova além da derivação aritmética.

**Parecer de suficiência:** `PASS_RESTRICTED` **exclusivamente para composição descritiva por competência**, mediante reuso das evidências numéricas e de integridade já aprovadas no P2.1. Sem segundo cálculo de E4 neste gate e sem rechecagem binária independente nesta sessão; essas duas ausências estão expressas para não simular uma execução nova. O PASS não testa gráfico, expressão Qlik, filtros, associação entre fatos ou produção.

**Limitações obrigatórias:** snapshot cadastral CNES/LT; não comprova leitos ocupados/disponibilidade operacional; sem classificação `hospital-only` historicamente validada; `T29_HISTORICAL=NOT_APPROVED`; ausência de linha ≠ zero observado; não somar competências como estoque anual; `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**STOP:** P2.2 **numérico** encerrado no recorte 201912. Somente este documento novo foi proposto em branch/PR Draft; não houve alteração de E4, QVD, QVW, QVS, modelo, `current-state.md` ou dados de produção. **Nenhum merge autorizado ou executado.** Não iniciar P2.3, recargas ou execução física por consequência deste resultado.
