# SAD — M2: implementação candidata de três folhas / nove visuais (QlikView 12)

**Data:** 07/11/2026. **Estado:** `SCRIPT_VERSIONED_PROTOTYPE_ONLY / WINDOWS_NOT_RUN / PHASE_IX_NOT_AUTHORIZED`. Autorização: escopo B1 + implementação TEMP aprovados pelo responsável; registro normativo no [adendo M0 B1](mvp-scope-owner-approved-2026-11-07.md).

## Objetivo, limites e fonte de verdade

Implementar, apenas em uma **nova cópia de QVW TEMP**, as três folhas e nove análises aprovadas, reaproveitando a carga M1 de três fatos (`M1_FACT_ORACLES=10/10 PASS` reportado pelo operador), o QVS físico de Fase VII e o QVS P23 A1 de observabilidade. Nenhum `STORE`, `Reload` de QVW canônico ou edição de QVD. Este protótipo é **anterior** a C2/C3/C4/IX e não equivale a dashboard final/homologado.

**Fontes versionadas reutilizadas sem modificação:**
- `PAINEL/phase_vii_technical_model.qvs`: script já persistido na QVW de M1, base de 16 tabelas e 15 ligações (não é recarregado como uma *segunda* cópia);
- `PAINEL/sad_p23_a1_island_physical_gate.qvs`: append controlado à **cópia** do script para projetar a 17ª tabela `P23_A1_ISLAND` com campos exclusivos e três classes de observação;
- `tools/Build-SadMvpThreeSheetsTemp.ps1`: executor único de cópia, reload técnico + P23, materialização de folhas e objetos COM, validação restrita e hash before/after;
- `tools/Invoke-SadM1IntegratedTempQvw.ps1`: gerou o QVW local de origem com 10 oráculos reportados PASS, **não reexecutar** para este M2.

## Objetos nativos do protótipo

| ID | Folha | Objeto COM | Dimensão(ões) / expressão(ões) candidata(s) | Principal risco não homologado |
|---|---|---|---|---|
| M1-01 | Produção Hospitalar | `CreateBarChart` | `PERIODO_ANO` → `Sum(QTD_INTERNACAO)` | Ano real selecionado e histórico 2017–19 |
| M1-02 | Produção Hospitalar | `CreateLineChart` | `PERIODO_COMPETENCIA` → `Sum(QTD_INTERNACAO)` | Competências parciais e filtro anual nativo |
| M1-03 | Produção Hospitalar | `CreateBarChart` | `SERV_COD_DATASUS_6` → `Sum(QTD_INTERNACAO)` | Associação FI/Link/papel SERV e ordenação |
| M2-01 | Leitos Cadastrais Observados | `CreateLineChart` | `PERIODO_COMPETENCIA` → `Sum(QTD_LEITOS_SUS)`, `Sum(QTD_LEITOS_EXISTENTES)` | Interpretar cada ponto como snapshot, não total anual |
| M2-02 | Leitos Cadastrais Observados | `CreateBarChart` | `SERV_COD_DATASUS_6` → `Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)` | Recorte fixo/legível 201912, ausência ≠ zero; filtros de outros meses |
| M2-03 | Leitos Cadastrais Observados | `CreateBarChart` | `P23_ESTADO_OBSERVADO` → `Count(P23_MUNICIPIO_6)` | Ilha A1 independente; 3.464/97/4.467 células, não municípios únicos |
| M3-01 | Fluxos e Contexto Territorial | `CreateBarChart` | Dimensão calculada RES=SERV / RES≠SERV / indeterminado → `Sum(QTD_INTERNACAO)` | Campo em papel RES/SERV, nulos e seleção associativa |
| M3-02 | Fluxos e Contexto Territorial | `CreateStraightTable` | `RES_COD_DATASUS_6`, `SERV_COD_DATASUS_6` → `Sum(QTD_INTERNACAO)` | Direção RES→SERV e tratamento dos residentes externos |
| M3-03 | Fluxos e Contexto Territorial | `CreateStraightTable` | `RES_COD_DATASUS_6`, `PERIODO_ANO` → `Sum(POPULACAO_ESTIMADA)` | **BLOQUEADO PARA USO FUNCIONAL** até demonstrar isolamento de filtros FI/FL e ano×município; não é T24 |

**As expressões são candidatas físicas, não homologadas.** Ainda faltam prova de seleção/guards D2-R2/P5 e review visual do layout, legendas de zero/ausência, ranking e POP. A existência dos nove objetos não lhes confere compatibilidade funcional.

## Execução local, uma única tentativa

A branch `proposal/sad-mvp-rebaseline-2026-11-07` deve estar limpa. O runner exige `-ExpectedCommit` igual ao SHA Git local, `-Build` explícito, `EvidenceRoot` preexistente fora do repositório e `M1SourceQvw` com nome exato `SAD_M1_INTEGRATED_TEMP.qvw` **dentro** da pasta de evidências. O QVW de origem será somente **lido e copiado**, jamais alterado. O novo QVW é criado em um diretório único `SAD_M2_MVP_TEMP_<id>` dentro do `EvidenceRoot`.

```powershell
git status --short
git pull --ff-only
$head = (git rev-parse HEAD).Trim()

$source = Join-Path $env:USERPROFILE 'SAD_M1_EVIDENCIAS\SAD_M1_INTEGRATED_bd4a10730a57403787c3d4ac13a7b240\SAD_M1_INTEGRATED_TEMP.qvw'

powershell.exe -NoProfile -File .\tools\Build-SadMvpThreeSheetsTemp.ps1 `
  -Root (Get-Location).Path `
  -ExpectedCommit $head `
  -EvidenceRoot (Join-Path $env:USERPROFILE 'SAD_M1_EVIDENCIAS') `
  -M1SourceQvw $source `
  -Build
```

**Caminho `$source`:** o diretório de M1 foi fornecido no stdout da execução anterior; confirmar `Test-Path $source` antes. `git status --short` deve estar vazio; não executar após alteração local não commitada de scripts críticos.

**Padrão de preservação:** snapshot SHA-256 de 22 QVDs, três QVWs canônicos e da QVW M1 de origem. A nova QVW + log + manifestos CSV ficam somente fora do Git. Não copiar QVDs, nem arquivos gerados, para o repositório. No Windows, abrir em QlikView **somente a QVW candidata retornada em `CANDIDATE_QVW`** para inspeção; não abrir/salvar `PAINEL/PAINEL.qvw`.

## Saídas, classificação e STOP

O executor deve registrar `CHECK_RD_ALL=555089`, `CHECK_LT_201912=7140`, `CHECK_POP_2019=4018127`, `CHECK_P23_CELLS=8028`, `CHECK_P23_ABSENT=4467`, `CHECK_P23_ZERO_OBS=97` e `CHECK_P23_POSITIVE=3464`. Após materializar, emitir **nove** linhas `M2_CREATED=<id>`, `M2_NATIVE_CANDIDATE=3_SHEETS_9_OBJECTS_BUILT_PENDING_GUI_AND_FILTER_VALIDATION`, hashes de protegidos intactos e `M2_VERDICT=BUILT_CANDIDATE_ONLY_NOT_HOMOLOGATED`.

- `BUILT_CANDIDATE_ONLY`: parser/reload/COM num Windows real conseguiram gerar os nove objetos e salvá-los apenas em cópia; **ainda não é PASS visual ou semântico**.
- `BLOCKED`: erro COM, sintaxe, ilha P23, diferença de oráculo, 17ª tabela/associação inesperada, hash drift, GUI ilegível, seleção enganosa ou objeto ausente; preservar evidências e STOP.
- `INCONCLUSIVE`: objeto criado mas sem prova de persistência/visibilidade ou log completo; não forçar PASS.
- `USER_READY=NO` até aceites de filtros, role-playing RES/SERV, POP e indisponibilidades; `C2/C3/C4=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Próxima revisão após a execução:** ler somente o stdout e manifestos/logs necessários; abrir o QVW TEMP e inspecionar três folhas com capturas reais, labels/legendas e três cenários representativos de filtro. Após qualquer falha, **não reexecutar** sem investigar a causa. Nenhum merge segue desta execução.


## Resultado da tentativa M2 e correção direcionada — 07/11/2026

**Evidência primária:** stdout integral de execução pelo operador no Windows PowerShell 5.1/QlikView 12 (relatado no chat; os binários e log não foram reinspecionados independentemente). Na branch e commit `8c9426b0dabeb6a1e134d36d79444533e1096bfb`, o parser PowerShell não apontou erros; o QVW M1 prévio existia. O runner criou **apenas** uma nova cópia `SAD_MVP_THREE_SHEETS_CANDIDATE.qvw` sob a pasta `SAD_M2_MVP_TEMP_cab310edba234c85bceedcecb81f9f33` no EvidenceRoot privado.

**Controles físicos reportados como positivos antes da falha:** `CHECK_RD_ALL=555089`, `CHECK_LT_201912=7140`, `CHECK_POP_2019=4018127`, `CHECK_P23_CELLS=8028`, `CHECK_P23_ABSENT=4467`, `CHECK_P23_ZERO_OBS=97`, `CHECK_P23_POSITIVE=3464`; `PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED=True`.

**Bloqueio observado:** `M2_VERDICT=BLOCKED_OR_INCONCLUSIVE A propriedade 'Count' não foi encontrada neste objeto`, antes de qualquer `M2_CREATED` ou `CANDIDATE_QVW` final. Inspeção do script pinado localizou `$doc.Sheets.Count` no gate da contagem de folhas (duas ocorrências, antes e depois de criá-las). Referências da API clássica de automação QlikView usam `ActiveDocument.NoOfSheets` e `GetSheet(i)`; evidências: [Qlik Community: GetSheet(j)](https://community.qlik.com/t5/QlikView/How-to-see-newly-created-sheets-with-GetSheet-j/m-p/300780/highlight/true), [exemplo legado de automação](https://github.com/inqlik/inqlik.github.io/blob/master/_posts/2014-07-19-qlikview-automation-by-scripts.md). **Causa imediata identificada por análise estática**, ainda sem verificação da correção no QlikView 12 desta instalação.

**Correção única no mesmo runner:** substituição das duas leituras `$doc.Sheets.Count` por `$doc.NoOfSheets`; rastreamento `M2_SOURCE_SHEET_COUNT`, `M2_FAILED_STAGE` e `M2_FAILED_LINE` para diagnóstico preciso sem novas rodadas exploratórias. Demais oráculos/expressões, proteção de originais, fontes QVS e modelo permanecem idênticos. **Não** reaproveitar nem abrir/salvar sobre o QVW parcial; nova tentativa usa pasta GUID nova, copiando o M1 original preservado.

**Autorização e STOP:** o responsável autorizou a implementação TEMP do MVP, e esta correção responde exclusivamente à falha real. Uma tentativa corretiva deliberada após `git pull --ff-only` e validação de parser é permitida no escopo já autorizado; **não repetir automaticamente** diante de outro erro. Se `M2_FAILED_STAGE` identificar novo método/propriedade COM incompatível, preservar pasta e reportar erro para revisão específica, sem adivinhar outra API ou aprovar painéis.

**Veredictos:** `M2_P23_AND_THREE_FACT_ORACLES=PASS_LOCAL_REPORTED_RESTRICTED`; `M2_THREE_SHEETS=BLOCKED_BEFORE_CREATION`; `M2_CORRECTED_SCRIPT=STATIC_ONLY_NOT_RUN`; `C2/C3/C4/IX=NOT_APPROVED`. `main` e QVD/QVW canônicos não foram alterados.
