# SAD — P2.4 ranking municipal de leitos SUS, competência 201912

**Gate:** `SAD-P24-LT-MUNICIPAL-RANKING-201912-READONLY-01`  
**Modo:** READ-ONLY / SINGLE-COMPETENCY NUMERIC VALIDATION  
**Baseline:** `main@9a2b6b68869279ac40002c4670ebeab0c74ff114` (PR #187 integrado).  
**Estado desta execução:** `BLOCKED_VERSIONED_EXECUTION_INPUT_BYTES_UNAVAILABLE`, com **leitura exploratória reconciliada** e validador commitado antes de qualquer execução de gate. **Não houve PASS numérico P2.4 formal.**

## 1. Contrato único

Validar `SUM(qt_sus)` por `municipio_serv` na competência **201912**, ordenar por contagem descendente e código DATASUS6 crescente em empates, sem atribuir nomes geográficos sem crosswalk/temporalidade comprovados. Preservar ausência de linha LT como não observado, e zero SUS observado com linha como classe distinta.

**Fontes físicas obrigatórias:**
- E4 original `lt_cnes_leito_competencia(1).csv`, SHA-256 `BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88` (P2.1).
- Exportação A1 R2 original `P23_A1_R2_export.tsv.txt`, SHA-256 `593b8812eaed2df9c3e6ca49f84b8c750a133966af36724963d8de2815636c42` (P2.3 histórico).
- Validador **previamente commitado na branch do gate:** `tools/validate_sad_p24_lt_municipal_ranking01.py`, commit `d47b4adbf43c25050fb98e77797986e648b7a9c2`. Nenhuma execução deste script contra fontes originais ocorreu nesta sessão.

**Critério do gate:** SHA de ambos os arquivos MATCH; esquema exato; 964 grãos E4 em 201912; 9.065 existentes/7.140 SUS/1.925 não SUS; 223 municípios na grade R2 (95 com LT, 128 sem linha; 93 positivos e 2 zeros observados); comparação **municipal integral** E4×R2, sem divergência; ranking reproduzível em CSV + auditoria JSON fora do Git, registrando commit/hash do validador e integridade dos insumos; teste de rejeição de fonte alterada. `PASS_RESTRICTED` só após essa execução rastreável. Falha de SHA ou medida = `HARD_STOP`. Falta de fonte = `BLOCKED`.

## 2. Resultado exploratório — não promove PASS

Uma leitura textual do intervalo **201912** da exportação A1 R2 preservada no acervo do Projeto forneceu 223 registros desse mês. A agregação exploratória conferiu, nesse intervalo, 95 pares municipais com LT (93 SUS positivo, 2 SUS zero), 128 sem LT, 964 linhas, 9.065 existentes e **7.140 SUS**; esses números coincidem com a série P2.1 e com o contrato P2.3.

**Top 10 preliminar (SUS observado, apenas códigos):**

| Posição | Município DATASUS6 | `qt_sus` |
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

Soma preliminar Top 10: **4.812** (67,3950% de 7.140). Os dois maiores códigos somam 3.545 (49,6499%). Esses percentuais caracterizam **somente uma competência** e **não são** cobertura hospitalar, taxa de ocupação ou estoque anual. Os números não constituem prova executada pelo novo validador versionado.

## 3. Restrição operacional real e handoff

O arquivo E4 e a exportação A1 R2 são **visíveis como conteúdo textual no acervo do Projeto**, mas suas **cópias originais em bytes** não puderam ser materializadas para Python: a tentativa de materialização `raw_file` de ambos retornou `This Project file does not have an authorized raw-byte materialization path`. A materialização `text` só disponibilizou extratos parciais (35.691 bytes para E4 de 1.301.572 bytes; 49.981 bytes para R2 de 414.780 bytes), inadequados para validar os SHA pinados. Não reconstruir bytes ou declarar uma execução com esses extratos. O runner commitado permanece **NOT_EXECUTED**.

**Reprodução autorizada com originais locais:** obter cópias integrais dos mesmos E4/R2 preservados, em diretório de entrada somente leitura fora do Git. Executar o validador a partir do commit de branch indicado acima, conferindo SHA-256 do arquivo Python, com saída em novo diretório externo e sem sobrescrita:

```powershell
git checkout test/sad-p24-lt-municipal-ranking-201912-readonly-01
$commit = git rev-parse HEAD
$script = ".\tools\validate_sad_p24_lt_municipal_ranking01.py"
$scriptSha = (Get-FileHash $script -Algorithm SHA256).Hash
python $script --e4 "CAMINHO\lt_cnes_leito_competencia(1).csv" `
  --r2-export "CAMINHO\P23_A1_R2_export.tsv.txt" `
  --source-commit $commit --script-sha256 $scriptSha `
  --output-dir "CAMINHO_EXTERNO\SAD-P24-201912-EVIDENCIAS"
if ($LASTEXITCODE -ne 0) { throw "P2.4 não passou: conferir erro/insumos" }
```

O relatório/CSV produzidos deverão ser conferidos e seus hashes registrados em closeout separado na mesma branch **antes** de reivindicar PASS. Conferir rejeição com **cópia corrompida**, nunca modificando os originais. Não repetir validação de 36 meses, COM ou QlikView.

**Invariantes:** `ZERO_REAL_COMPROVADO=NOT_PROVEN`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

**STOP:** P2.4 permanece `BLOCKED` para PASS formal até os bytes originais chegarem ao executor. Nenhum merge P2.4, P2.5, QVD/QVW/QVS ou produção por consequência.
