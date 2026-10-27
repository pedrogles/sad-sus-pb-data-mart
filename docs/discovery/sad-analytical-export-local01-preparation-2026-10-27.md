# SAD-ANALYTICAL-EXPORT-LOCAL-01 — preparação estática

**Estado:** `STATIC_P1_REMEDIATION_CANDIDATE` (PR #160 Draft, branch versionada; sete testes sintéticos locais PASS; **sem Windows/QlikView/COM e sem dados físicos**). Integração e execução permanecem NÃO autorizadas.

## Proveniência e fronteira

- `pedrogles/sad-sus-pb-data-mart`, `main@db5d6e6e23371422ca1d2d77a8576150aaf63d03` revalidada em 27/10/2026; PR #159 integrado.
- Fonte superior: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, V2 §62, Boundary 7, direcionamento/inventário/plano analítico e `docs/project/qlikview-powershell-automation.md`.
- A política do repositório exige que os scripts desta preparação sejam **commitados em branch** antes de qualquer execução física. O pacote entregue fora do Git **não é fonte de verdade operacional**.
- **Nenhuma** execução no Windows, QlikView 12, COM, `Reload`, `STORE` de dados, carga, recarga de pipeline ou modificação QVD/QVW ocorreu nesta preparação.
- A aprovação semântica não aprova `LINK_KEY`, T25/T26, denominadores, telas ou produção.

## Revisão da main e reúso

1. `TRANSFORMACAO/transf_fato_internacao.qvs`: confirma staging `SRC_SIH_RD.qvd`, `_META_SOURCE_COMPETENCE`, `MUNIC_RES`, `MUNIC_MOV`, `PROC_REA`, `DIAG_PRINC`, `IDENT`. Aplica `IDENT='1'` para `QTD_INTERNACAO`, `IDENT='5'` para continuidade e `RTrim(Text(DIAG_PRINC))` para diagnóstico. A fato persistida usa SKs e `%LINK_KEY`; **não** presumir RES/SERV/PROC_REA/DIAG_PRINC como campos da fato.
2. `TRANSFORMACAO/transf_fato_capacidade_leito.qvs`: confirma `SRC_CNES_LT.qvd`, `COMPETEN`, `CODUFMUN`, `CNES`, `TP_LEITO`, `CODLEITO`, `QT_EXIST`, `QT_SUS`, `QT_NSUS`; staging de tipo aceita somente `N` ou `N ` com ASCII final único e tipo 1–7.
3. `TRANSFORMACAO/vi_p3_source_reference.qvs` e `TRANSFORMACAO/vi_p4_municipal_coverage.qvs`: exemplos de leitura independente sem Link Key; VI-P4 expôs grade 223×36, mas grava TXT e depende de demais QVDs.
4. `tools/Invoke-SadViP3Readonly.ps1` e `tools/Invoke-SadViP4Readonly.ps1`: guardas históricas **10+11=21 QVDs**, proibem presença de `LINK_ANALISE.qvd`; estado atual é **10+12=22 QVDs**. Não executá-los nem relaxar as guardas históricas.
5. `tools/validate_sad_c4b1_regional_f2f3.py`: padrão de auditoria com SHA congelado, schema, cardinalidade, grão, quantidades e universo; preservar como script histórico.
6. **Gerador histórico F1**: `tools/preflight_f1_f2_referencias_independentes.py` no commit `26369052bd3f96de5f3eccf873c390053c20b561` gera `F1_fluxo_competencia.csv`, `F1_servico_competencia.csv`, `F1_residencia_competencia.csv` e equivalentes anuais. Seus extratos fluem de CSVs RD originais e **podem** resolver I02/I03/I08/I09 sem novo dado, se arquivos + manifesto e SHA forem efetivamente acessíveis e auditados. **Não foi confirmado acesso físico aos F1 neste ambiente**. Usar F1 como oráculo adicional; não presumir que o artefato esteja disponível.
7. **F2 preexistente**: `F2_lt_municipio_competencia_observado.csv` teve SHA-256 `DC0FAE8646F6570F5DEEAF8A1597EA5ED90A5BD9A881A40B4DCA0E30380E953D` no relatório C4-B1. Se localmente presente e hash coincidir, usar `-F2Reference` na reconciliação dos grupos município×competência.

## Contrato de saída (não constitui fato novo)

| CSV | Grão | Perguntas |
|---|---|---|
| `sih_fluxo_competencia.csv` | competência × residência × serviço | I02/I03/I08/I09 |
| `sih_procedimento_competencia.csv` | competência × PROC_REA | I04 |
| `sih_diagnostico_competencia.csv` | competência × DIAG_PRINC normalizado por `RTrim` | I05 |
| `lt_cnes_leito_competencia.csv` | competência × município × CNES × tipo × código leito | I11 |

- **UTF-8; CSV delimitado por `;`; cabeçalho exato** do bootstrap; exportação em UTF-8 com BOM conforme documentação oficial do QlikView, usando `STORE (txt, delimiter is ';')`; quoting/cabeçalho exatos ainda sujeitos a validação física; códigos municipais e de domínio são textos.
- Medidas E1–E3: três inteiros não negativos `qtd_registro_aih`, `qtd_internacao`, `qtd_continuidade`; a primeira deve ser soma das outras duas. **Contagens administrativas, não indivíduos.**
- E4: `linhas_lt`, `qt_exist`, `qt_sus`, `qt_nsus`; inteiros não negativos, `qt_exist=qt_sus+qt_nsus`. Sem linha LT não produz linha no E4 (ausência não significa zero); um grupo existente pode ter QT_SUS=0 observado.
- Não conter campos monetários. Tratamento de nulos: **fail closed nos códigos e nas medidas da origem**; não produzir chaves sentinela nem transformar ausência em zero. Campo nulo/ambíguo inesperado é bloqueio, não correção silenciosa.
- `TP_LEITO` na saída é o dígito normalizado, guardada a forma física aceita no staging. Não introduz descrição T29.

## Oráculos independentes

| Critério | Esperado |
|---|---|
| RD (cada E1/E2/E3) | 566.672 registros, 555.089 elegíveis, 11.583 continuidades |
| RD 2017/2018/2019 | 183.532 / 183.311 / 188.246 elegíveis |
| RD período | 36 competências, grão exclusivo, sem duplicatas de grupo, E1/E2/E3 com mesmo triplo mensal (`registros`, `internações`, `continuidades`) |
| RD externos E1 | 5.202 linhas administrativas e 5.067 elegíveis (F1/F3 histórico), confrontados com crosswalk C5.2 de 223 códigos PB |
| LT E4 | 35.518 linhas, 337.147 `QT_EXIST`, 270.076 `QT_SUS`, 67.071 `QT_NSUS` (somas **somente de snapshots observados**, controle de auditoria) |
| LT cobertura observada | 36 competências, 3.561 pares com linhas, 3.464 positivos, 97 zeros observados e 4.467 células sem linha na grade 223×36 |
| Integridade | 22 QVDs, três QVWs canônicos e crosswalk C5.2 com hash/tamanho invariáveis antes e depois |

**Níveis de prova:** resultado dos oráculos acima documentado anteriormente = `RELATO_LOCAL_HISTORICO`. A execução futura só alcançará `EXPORTED_AND_RECONCILED_RESTRICTED` quando CSVs, hashes e logs contemporâneos forem produzidos e aprovados pelo validador. Não é prova global da interface Qlik.

## Matriz de proteção

| Classe | Acesso | Política |
|---|---|---|
| `EXTRACAO/QVD/*.qvd` (10) | leitura | hash + cabeçalho antes/depois; sem escrita |
| `TRANSFORMACAO/QVD/*.qvd` (12, `LINK_ANALISE.qvd` inclusive) | leitura | hash + cabeçalho antes/depois; sem escrita |
| `EXTRACAO/EXT.qvw`, `TRANSFORMACAO/TRANSF.qvw`, `PAINEL/PAINEL.qvw` | somente hash | nunca abrir, recarregar nem salvar |
| `EXTRACAO/QVD/REF_MUNICIPIO_PB_DERIVADA.csv` | leitura | 223 códigos e hash antes/depois |
| `RUNTIME_TEMP/AE01_DISPOSABLE.qvw` | gravação isolada | somente QVW descartável COM; não versionar |
| `EVIDENCE_ROOT/*.csv`, `manifest.json` e logs | saída exclusiva | diretório novo, persistente, fora do Git e TEMP, sem sobrescrita |

## Arquitetura do patch candidato

- `TRANSFORMACAO/sad_analytical_export_local01.qvs`: lê apenas dois QVDs de staging, agrupa em `AE_PRE_E1..E4` com aliases exclusivos e materializa sequencialmente cada tabela pública `AE_E1..E4`, com `DROP` entre stores. Antes da primeira exportação, exige quatro tabelas temporárias e zero `$Syn` pela inspeção de `NoOfTables()/TableName()`; executa **quatro** `STORE` somente TXT. Sintaxe QlikView e probe **não testados fisicamente**.
- `tools/Invoke-SadAnalyticalExportLocal01.ps1`: exige `-RunQlik` e `-ExpectedCommit` igual ao HEAD da branch não-main, scripts versionados e sem mudanças; valida inventário 22 QVDs, cabeçalhos RD/LT, script allowlist, cria QVW descartável em TEMP e copia log para evidências; inspeciona hashes antes/depois. Não rodar scripts VI-P3/VI-P4.
- `tools/validate_sad_analytical_export_local01.py`: auditor independente que **não chama Qlik**. Confere esquema, códigos, unicidade, períodos, totais anuais **e igualdade mensal E1=E2=E3 para registros, internações e continuidades**, F2 opcional e escreve `manifest.json` somente após PASS; `run_metadata.json` aceita UTF-8 com/sem BOM emitido pelo Windows PowerShell 5.1.
- A execução será **uma única tentativa**. Falha exige diagnóstico/STOP, sem retry automático.

## Procedimento futuro (não executado)

1. Conferir os três scripts e este documento no **commit da branch do PR Draft**; revisar o diff, sem mudar arquitetura.
2. No host Windows, conferir branch e commit dos scripts; garantir Python 3, QlikView 12 COM e acesso de leitura às fontes. Confirmar os 22 QVDs e três QVWs. Validar espaço/permissões e fixar caminhos persistentes. Se F1/F2 estiverem disponíveis, validar seus manifests/hashes (antes de decidir reuso F1).
3. Obter **nova autorização expressa de execução física**, distinta da autorização do commit. Não usar `main`; executar apenas o commit indicado, em branch do GitHub sincronizada e working tree de scripts limpa.
4. Em PowerShell, `-Root` aponta para a raiz do repositório; `-EvidenceRoot` para **diretório ainda inexistente** em unidade persistente fora do Git e TEMP; `-ExpectedCommit` é SHA **completo e exato** do commit aprovado; `-RunQlik` somente quando expressamente autorizado:

   ```powershell
   & .\tools\Invoke-SadAnalyticalExportLocal01.ps1 `
       -Root (Get-Location).Path `
       -ExpectedCommit '<SHA40_DO_COMMIT_APROVADO>' `
       -EvidenceRoot 'D:\SAD_EVIDENCIAS\AE01_<IDENTIFICADOR_UNICO>' `
       -RunQlik
   ```

   **Esses caminhos são exemplos**, não valores confirmados do host. `-F2Reference '<CAMINHO_DO_F2_VALIDADO>'` opcional quando o arquivo efetivo for encontrado.
5. Preservar íntegros os quatro CSVs, manifesto, stdout/erro, log, hashes de scripts e inventário pré/pós. Acompanhar e auditar **sem nova recarga**.
6. Fechar `EXPORTED_AND_RECONCILED_RESTRICTED` apenas se todos os gates passarem. Em divergência: `BLOCKED_INPUT`, `INCONCLUSIVE_WITH_LIMITS` ou `HARD_STOP`, conforme causa. Sem reexecutar automaticamente.

## Revisão estática desta proposta

- ZIP verificado por CRC e inventário de quatro arquivos.
- `python -m py_compile` do validador: PASS sintático.
- Teste negativo com crosswalk incompleto: BLOCKED conforme esperado, sem criação de manifesto.
- Auditoria textual: quatro `STORE` somente TXT/CSV, sem `STORE` QVD; `-RunQlik` explícito e proteção pré/pós previstas.
- **Não testado:** parser do PowerShell em Windows, execução COM, reload QlikView 12, formato CSV real ou validação com dados físicos.

## Correções P1 — PR #160 (revisão offline de 27/10/2026)

| Bloqueio do review | Correção proposta | Evidência local (somente teste sintético) |
|---|---|---|
| P1 / BOM no metadado do PowerShell 5.1 | `read_metadata()` com `encoding='utf-8-sig'` | JSON com BOM lido pelo código de produção; a leitura com `utf-8` antigo falha no mesmo fixture |
| P1 / totais mensais inconsistentes | Comparação das 36 competências entre E1, E2 e E3 para o triplo `(QTD_REGISTRO_AIH, QTD_INTERNACAO, QTD_CONTINUIDADE)` | Mutações 201701→201702 em E2 (internação) e E3 (continuidade), preservando totais anuais, retornam BLOCKED |
| P1 / `$Syn` em tabelas residentes simultâneas | Alias internos exclusivos por extrato, `STORE` sequencial com `DROP TABLE` após cada CSV, e guarda de zero `$Syn` e exatamente quatro tabelas temporárias antes do STORE | Testes estáticos para nomes internos exclusivos, stores serializados e mutações maliciosas rejeitadas. **Não equivale a ausência física comprovada de `$Syn` no QlikView.** |

**Testes executados no ambiente isolado Python (sem QlikView):** `python -m unittest discover -s tools -p 'test_sad_analytical_export_local01.py' -v` → **7/7 PASS**, Python 3.13.5; `python -m py_compile` para validador e suíte PASS. Fixture inteiramente sintético, descartável e mantido somente durante a execução, sem QVD/QVW/COM. O script de testes integra este mesmo PR; antes de sustentar gate futuro, usar o **commit correspondente** (sem herdar evidência de SHA anterior).

**Ajuste adicional fundamentado na documentação QlikView:** o `STORE` de texto usa `(txt, delimiter is ';')`, sem especificadores exclusivos de `LOAD` (`utf8`/`embedded labels`). A ajuda oficial registra CSV UTF-8 com BOM por padrão. A guarda regex do PowerShell verifica a forma exata. Requer teste físico posterior da saída efetiva: cabeçalho, aspas e separador.

**Limites residuais:** não existe nesta revisão verificação de parser PowerShell 5.1, execução QlikView do QVS, comportamento real `STORE (txt, delimiter is ';')` ou CSVs de produção. A guarda de topologia Qlik e o estado de ausência de `$Syn` devem ser observados em log físico na execução **apenas após autorização**. Adicionais P2 do review podem ser acompanhados separadamente, sem ampliar o gate silenciosamente. Issue #161 deve manter `EXECUTION_NOT_AUTHORIZED` enquanto não houver autorização expressa específica.

## Diagnóstico físico reportado — 27/10/2026, AE01_20261027_01

**Proveniência:** log `qlik_reload.log` e inventários pré/pós **transcritos pelo responsável na conversa**, sem arquivo de evidência anexado ou auditoria de bytes neste agente. A execução física única autorizada utilizou `9aa8eeec46e470627c1b42cfc6bd6fe58b0693f7` no QlikView Desktop 12.0.20000.0 (Windows).

- Leitura inicial: `566672` registros `SRC_SIH_RD.qvd`; `RD MONTHS=36 NEW=555089 CONT=11583 IDENT_BAD=0 DOMAIN_BAD=0`. Essas são as únicas medidas alcançadas.
- Falha real de parser na linha 50 do QVS: a cláusula `IF` começava na linha 49 e continuava com `OR ... THEN` na linha seguinte. A ajuda QlikView determina que `IF condition THEN` não cruze limite de linha.
- Inspeção estática posterior identificou **três** casos idênticos (guardas RD, LT, reconciliação de grupos). Este patch põe toda a cláusula `IF ... THEN` em linha única, sem alterar predicados/oráculos.
- `Compare-Object` dos arquivos `protected_before.json` e `protected_after.json` retornou vazio segundo o operador: conteúdo protegido preservado quanto a caminho, bytes e SHA-256 declarados. Esta afirmação continua `RELATO_LOCAL` até receber os arquivos reais.
- Nenhum CSV foi criado. `AE01=BLOCKED_QVS_SYNTAX`; `EXPORTED_AND_RECONCILED_RESTRICTED` **não atingido**.
- Regressão adicionada em `tools/test_sad_analytical_export_local01.py`: exige `IF ... THEN` em linha única e recusa mutação que introduza `OR` em outra linha. Verificação estática não equivale a reexecução física.
- **A tentativa anterior foi consumida.** Esta correção requer **novo commit**, revisão e **nova autorização expressa** antes de qualquer recarga. Não reutilizar `AE01_20261027_01` nem sobrescrever evidências; manter PR Draft.

## Pendências reais e STOP

- **Versionamento proposto neste PR Draft:** os três scripts e este documento foram preparados para commit em branch de objetivo único; conferir o commit do PR antes de qualquer uso. Execução física exige autorização separada.
- **Pendente:** verificar os headers QVD no Windows, sintaxe/encoding Qlik `STORE` real, permissão COM e hashing. Nenhuma prova física neste ambiente cloud.
- **Pendente:** localizações e hashes dos F1/F2 manifestados precisam de inspeção local; nenhum reuso deve ser presumido.
- **Pendente:** confirmar local persistente para evidência e quantidade/tamanho dos QVDs/QVWs imediatamente antes da execução.
- **Pendente:** antes da execução, garantir autorização específica **separada** do commit/PR.
- **STOP:** este pacote encerra a **preparação estática**. Não iniciar painéis, Fase IX, outras agregações, T24/T25/T26 ou nova Discovery.

**Não alterar:** `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

## Adendo de integração — resultado posterior à preparação estática (27/10/2026)

**Esta seção não altera o relato histórico acima.** As frases de preparação “não executado”, “pendente” e “tentativa 01 bloqueada” descrevem os gates e momentos originais, **não** o resultado final da tentativa 02.

- A tentativa 01, no commit `9aa8eeec46e470627c1b42cfc6bd6fe58b0693f7`, foi bloqueada por sintaxe Qlik `IF ... THEN`, sem exportar CSVs. A correção versionada e efetivamente utilizada depois foi `8633f12a910f422f6b2e9af5e0d06d622ff13497`. Preservar a cronologia de duas tentativas e respectivas autorizações.
- **Tentativa 02 real, relatada pelo responsável em Windows/QlikView 12:** [Issue #161 — parecer AE01](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/161#issuecomment-6446935266). Foram fornecidos quatro CSVs, manifesto, metadados, log QlikView e inventários de proteção; o material foi auditado independentemente no escopo reportado, **sem reexecutar COM nem reabrir bytes de QVD/QVW originais**.
- **Veredito restrito:** `EXPORTED_AND_RECONCILED_RESTRICTED`. E1/E2/E3: 566.672 registros RD, 555.089 internações novas, 11.583 continuidades, 36 competências consistentes; E4: 35.518 linhas LT, 36 snapshots, 3.464 município×mês SUS positivo, 97 zero observado e 4.467 sem linha em grade 223×36. Os snapshots somados sobre o tempo **não** são estoque anual.
- **Proveniência:** manifesto SHA-256 `0B1AA7DA6EF10A08B0F698250F199666525672DC763D6774CA4498B2A3C488D2`; inventários pré/pós idênticos byte a byte no pacote de evidências SHA-256 `2EC2FB3E922623BA808FDEB2C27C25B4ED461BE41A1EB70E9587DBDF238FD78A`. O código deste PR será integrado sem alterar a identidade do commit que foi executado localmente.
- **Limites que sobrevivem à integração:** não demonstra `LINK_KEY_CONTRACT`, medidas/denominadores globais, T24/T25/T26, natureza hospitalar de cada LT, T29 histórico, filtros P5/D2, dashboards ou produção. `PR_MERGED` não significa `PRODUCTION_APPROVED`; nenhuma reexecução autorizada por decorrência.

**Condição de parada:** registrar a evidência posterior como adendo documental e encerrar a revisão de integração; nenhuma terceira tentativa, teste físico, modificação QVD/QVW ou Fase IX.
