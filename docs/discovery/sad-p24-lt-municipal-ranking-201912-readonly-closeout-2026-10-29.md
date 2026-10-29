# SAD — P2.4 | Ranking municipal CNES/LT 201912 — fechamento numérico E4 × A1 R2

**Gate:** `SAD-P24-LT-MUNICIPAL-RANKING-201912-READONLY-01`  
**Data:** 29/10/2026  
**Veredito:** `PASS_RESTRICTED_E4_R2_201912_RANKING` — restrito à agregação de leitos SUS observados por `municipio_serv` **na competência 201912**.  
**Git baseline:** `main@9a2b6b68869279ac40002c4670ebeab0c74ff114`, PR #187 integrado; alterações de P2.4 apenas em branch `test/sad-p24-lt-municipal-ranking-201912-readonly-01` e [PR #188](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/188) **Draft não integrado**.  
**Modalidade:** READ-ONLY / execução Python do validador versionado; sem QlikView/COM, QVD/QVW/QVS, novas recargas ou produção.

## 1. Fontes originais e cadeia de proveniência

| Artefato recebido | Bytes | SHA-256 verificado antes/depois |
|---|---:|---|
| `lt_cnes_leito_competencia(2).csv` — E4 original pinado P2.1 | 1.301.572 | `BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88` |
| `P23_A1_R2_export.tsv(1).txt` — A1 R2 original pinado P2.3 | 414.780 | `593B8812EAED2DF9C3E6CA49F84B8C750A133966AF36724963D8DE2815636C42` |

**Executor:** `tools/validate_sad_p24_lt_municipal_ranking01.py`; correção mínima versionada **ANTES** da execução positiva no commit `22f8bb898b5daaaef3aa3a0ece5a9425e412e46b`. Git blob `2c36fcd0f7143a9a9ffe2310d5e0db6677114cf5`, reproduzido a partir dos bytes do script executado; SHA-256 `995963E69AD453038599C1DE7AB95C09915AD4C70A1F101C8232C9CDF7FED35F`. `--source-commit` e `--script-sha256` passados ao script. A execução positiva retornou **exit code 0** em `2026-10-29T17:30:58.498803+00:00`.

**Histórico de correção restrita:** a tentativa inicial com script anteriormente commitado (`e59f1ad9f30eea6dbd74f34801bfe0b3a487dfc1`) foi rejeitada pelo próprio validador devido a diferença de **caixa hexadecimal**: calculava R2 SHA em maiúsculas, comparava com constante em minúsculas. Os bytes originais já correspondiam ao hash pinado, confirmado independentemente. Corrigida **somente a grafia** da constante SHA no commit `22f8bb8`, sem mudar campos, lógica, quantidades ou semântica. A falha inicial foi registrada como defeito do validador, **não** como divergência da fonte; o stdout/stderr inicial foram substituídos pelos artefatos da execução positiva, e **não** são alegados como log persistente da falha inicial.

## 2. Resultado por competência e reconciliação integral

| Controle | Apurado | Contrato |
|---|---:|---:|
| Competência | 201912 | recorte explícito único |
| Grãos E4 distintos no recorte | **964** | 964 |
| `SUM(qt_exist)` | **9.065** | 9.065 |
| `SUM(qt_sus)` | **7.140** | 7.140 |
| `SUM(qt_nsus)` | **1.925** | 1.925 |
| Identidade `qt_exist=qt_sus+qt_nsus` | 964/964 | nenhuma divergência |
| Grade R2 em 201912 | **223** pares distintos | 223 |
| Municípios com linha LT | **95** | 95 |
| Municípios com SUS positivo | **93** | 93 |
| Municípios com SUS zero observado e linha | **2** | 2 |
| Municípios sem linha LT | **128** | 128, **NULL ≠ 0** |
| Confronto municipal E4×R2 | **95 pares presentes + 128 ausentes preservados** | nenhuma divergência nas quantidades/estado |

**Ranking Top 10 SUS observado (201912; códigos DATASUS6):**

| Ordem | `municipio_serv` | `qt_sus` |
|---:|---|---:|
| 1 | `250750` | 2.159 |
| 2 | `250400` | 1.386 |
| 3 | `251080` | 308 |
| 4 | `251370` | 199 |
| 5 | `250370` | 171 |
| 6 | `251620` | 144 |
| 7 | `250630` | 119 |
| 8 | `250890` | 114 |
| 9 | `251130` | 112 |
| 10 | `251140` | 100 |

**Top 10:** 4.812 / 7.140 = **67,3950%**. Ranking inclui 95 municípios observados com linhas LT, inclusive dois com `qt_sus=0`; os 128 sem linha permanecem fora do ranking observado e não são tratados como zero. Ordenação por `qt_sus` decrescente, desempate crescente do código DATASUS6.

## 3. Negativos controlados e integridade

**Duas cópias corrompidas**, preparadas separadamente dos originais; scripts, fontes e dados originais não modificados:

| Teste | Exit | Saída esperada/obtida |
|---|---:|---|
| E4 modificado em cópia | 2 | `HARD_STOP_VALIDATION_DIVERGENCE: E4 SHA-256 differs from pinned source` |
| R2 modificado em cópia | 2 | `HARD_STOP_VALIDATION_DIVERGENCE: A1 R2 export SHA-256 differs from pinned source` |

Os dois testes falharam antes de criar a saída de evidência da execução negativa. Os SHA-256 originais foram recalculados após a execução positiva e os negativos e permaneceram idênticos aos pins.

**Evidências de execução fora do Git (arquivos originais e derivados preservados no ambiente de execução):**

| Evidência | SHA-256 |
|---|---|
| `p24_audit.json` | `7B577C9DCC02FB3FA92A4BEBF7CFE73EC8EE19BB1E14E2C48ECA37209DBB47A2` |
| `p24_ranking_201912.csv` | `90058AEAD055B0C7ECF60594E731AB390B5DB609F42FF7A7C62FED4EF95964D7` |
| `p24_execution_stdout.txt` | `5F40BDEBA711D47C47B40BFB10CD511AEE3D80D3F3998CDC8E714545B5B37EA8` |
| `p24_negative_e4_stderr.txt` | `85DB9374AAC649343598F0DBD18302FF03C4AA70D2924E240A0D21CEAE1C16A8` |
| `p24_negative_r2_stderr.txt` | `98795D0138450C42F150B6B284331DB04B43CA7DF22B75A4FB9BE8275C2FFE39` |
| `sad-p24-201912-evidence.zip` | `8EDB6EDF64FE76D22B65A08DDFC9C74BA036B3CA3AD52FA353BBC048ADB14EC7` |

O ZIP inclui CSV, auditoria JSON, stdout/stderr, dois negativos e manifesto de evidências; **não** inclui os datasets originais nem QVD/QVW. O ZIP é disponibilizado como evidência de sessão, não commitado no Git.

## 4. Parecer restrito e STOP

**FATO VERIFICADO:** integridade pinada dos dois originais, executor idêntico ao Git blob do commit anterior à execução, `exit 0`, todos os controles do recorte 201912 reconciliados, confronto completo de todos os 223 municípios e negativos de SHA com `exit 2`.

**Parecer:** `PASS_RESTRICTED_E4_R2_201912_RANKING` **somente** para ranking municipal de quantidade de leitos SUS do snapshot cadastral CNES/LT em dezembro/2019. O E4 e R2 compartilham linhagem CNES/LT; confrontá-los não constitui validação de duas fontes externas independentes. Sem prova de disponibilidade operacional, ocupação, categoria hospital-only histórica ou integridade de UI QlikView.

**DECISÕES PENDENTES/INVARIANTES:** `ZERO_REAL_COMPROVADO=NOT_PROVEN`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**STOP:** gate P2.4 numérico encerrado. Proposta de documentação/código em PR #188 **Draft**, sem merge neste turno. Não iniciar P2.5, QlikView/COM, alterações em QVD/QVW/QVS ou produção. Próximo gate P2.5 somente após revisão/integração autorizada e contrato próprio.
