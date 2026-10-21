# Fase VIII — C4-B1 | Preparação do executor regional T25 SERV (20/10/2026)

**Estado:** `C4_B1_RUNNER=VERSIONED_NOT_RUN`; `C4_B1_PARSER_WINDOWS=NOT_RUN`; `C4_B1_REFERENCE_LOCAL_PREFLIGHT=NOT_RUN`; `C4_B1_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`. O aceite é **somente de preparação/versionamento**, sem QlikView/COM, merge, execução local no Windows nem aprovação de KPI.

**Main verificada antes da preparação:** `949e6e96b6e0f4e530672d52808ad178080bce28`. Esta branch foi criada desse commit. O executor é um desenvolvimento novo baseado em padrões do T25 experimental [PR #113](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/113) e T24 regional [PR #112](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/112); **não** herda o PASS físico de nenhum deles. O fechamento C3-B2 [PR #137](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/137) está integrado; os passos C4 [#139](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/139), [#140](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/140) e preflight F2/F3 [#141](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/141) ainda estavam **Draft e fora da main** durante esta preparação.

## Objetivo único e fonte das medidas

Preparar **uma** prova futura de T25 regional no QlikView 12 para `PERIODO_ANO=2018` e `SERV_COD_DATASUS_6={250400,250750}` (Campina Grande e João Pessoa), com competência inicialmente não selecionada; sem `RES_COD_DATASUS_6`, procedimento ou outro filtro incompatível. Universo observacional `LT_TODOS_REGISTROS_VALIDOS_RN21`, **sem escopo hospitalar historicamente validado**.

**Referência conferida independentemente nos CSVs anexados ao gate anterior** ([#141](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/141)): 24/24 pares F2 município×competência (12 por município) e dois F2 controles anuais; `QT_SUS` acumulado entre snapshots apenas para auditoria: Campina Grande 16.592; João Pessoa 28.106; total 44.698. Denominador de POP anual F3 somado uma única vez por município: 1.207.795. Média de capacidade observada candidata `44.698/12`; indicador T25 candidato `1000×(44.698/12)/1.207.795≈3,083994662449615` por 1.000. **44.698 não são leitos simultâneos/anuais**. A F3 também contém 119.857 internações elegíveis de serviço no cenário, controle auxiliar **não usado** na razão T25.

## Executor preparado

`tools/Invoke-SadPhaseViiiC4b1RegionalT25.ps1` (versionado nesta branch antes de qualquer execução no Windows). Parametrização: `-Root`, `-SourceQvw`, `-F1F2Dir`, `-F3Dir`, `-ExpectedHead`; os parâmetros opcionais `-RunQlik` e `-PhysicalAuthorization` só podem ser usados **após outra autorização expressa**, independente da preparação.

**Gate padrão, sem `-RunQlik`:** confere branch e HEAD literalmente contra `-ExpectedHead`, valida que o próprio script corresponde ao blob versionado, confere que o QVW T24 original reside sob `%TEMP%` e possui SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`; inventaria 22 QVDs e três QVWs canônicos, incluindo pin físico `LINK_ANALISE.qvd`; verifica manifests congelados F1/F2 e F3; hashes e cabeçalhos previamente documentados dos oráculos F2 mensal, F2 anual, F3 multimunicipal e F3 POP; reconcilia 24 competências municipais, dois controles anuais, 12 competências regionais, F3 cenário e POP de ambos os municípios; salva saídas CSV apenas em diretório novo de evidência no TEMP. Emite `VERDICT=PASS_REFERENCE_ONLY_C4B1_COM_NOT_RUN` **somente se executar e verificar essas condições**. A preparação não executou esse gate.

**Gate físico possível, mas NÃO AUTORIZADO:** exige `-RunQlik`, `-PhysicalAuthorization` específico e commit exato esperado. Cria uma cópia descartável SHA-idêntica do QVW T24 no TEMP, usa COM `QlikTech.QlikView`/ `OpenDoc` nessa cópia, sem `Reload`, `Save`, `STORE` ou modificação dos QVWs canônicos. Verifica uma seleção anual simultânea de dois municípios de **serviço**, com município de residência e competência sem seleção, e reconcilia: `Sum(QTD_LEITOS_SUS)=44698`, `Count(POPULACAO_ESTIMADA)=2`, `Sum(POPULACAO_ESTIMADA)=1207795`, taxa candidata até erro absoluto `0.000001` por mil. Revalida **12 componentes mensais regionais** por seleção de competência individual, para provar que a média anual usa os snapshots correspondentes, sem duplicação da população. Exporta resultados da reconciliação para CSV no TEMP. Após fechar COM, reconfere os hashes dos 22 QVDs, três QVWs e QVW T24 de origem. Sem STOP por divergência, veredito **somente candidato:** `PASS_LOCAL_C4B1_REGIONAL_SERVICE_T25_OBSERVED_CANDIDATE_ONLY`.

## Fontes congeladas e proteções

| Artefato | SHA-256 |
| --- | --- |
| `manifest_F1_F2.json` | `926D5EE06373D6B30C3617501A9E81F2F0E6C16CFEF98A9EF1AAF25113EF025B` |
| `manifest_F3.json` | `9FE3543374870878915A2ABAE6A88DFDB07778FDDA9D506A3B87A2DD2D98DA08` |
| `F2_lt_municipio_competencia_observado.csv` | `DC0FAE8646F6570F5DEEAF8A1597EA5ED90A5BD9A881A40B4DCA0E30380E953D` |
| `F2_lt_municipio_ano_cobertura_candidata.csv` | `97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D` |
| `F3_cenarios_multimunicipais.csv` | `3B7315A564666D43A43E60700B5ACC4E255FEF6535F53219EC3D8A08C74CBFF9` |
| `F3_pop_municipio_ano.csv` | `4AC341479A63EEA3FAA1FC2C20A3C2447C94294B940BDAFDFD9799BD555A7699` |
| `LINK_ANALISE.qvd` | `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB` |

Não copiar ZIPs, QVDs, QVWs, oráculos e relatórios brutos para o repositório. Não inferir que apenas a presença de 12 competências prova cobertura hospitalar.

## Verificação estática realizada e validações pendentes

- **FATO INSPECIONADO NO GITHUB:** script criado na branch própria, estrutura de código contém verificação de branch/commit/blobs, pins, modo sem COM por padrão, controle `-RunQlik` separado, seleção R/S pertinente, reconciliação anual e mensal, proteção de hashes no `finally` e ausência de chamadas explícitas de `Reload`/`Save`/`STORE` no runner.
- **NÃO VERIFICADO:** parser PowerShell 5.1 em Windows, compatibilidade real de propriedades/métodos COM, comportamento da seleção dupla de serviço, leitura dos quatro CSVs/manifestos no PC neste novo gate e persistência de saída do runner local.
- **Necessário antes de qualquer autorização física:** inspecionar diff do PR, fazer checkout protegido preservando QVWs/QVDs, confirmar SHA de HEAD e do executor, rodar parser em Windows **sem COM**, e executar **uma única vez** o preflight padrão SEM `-RunQlik`. Só então solicitar outra autorização para execução física, com plano de proteção do ambiente, limites e STOP.

**Critério de BLOCKED/INCONCLUSIVE:** arquivo/oráculo ausente ou alterado, parser inválido, HEAD divergente, QVW fora do TEMP/hash conhecido, quantidades/grãos/seleções diferentes, erro COM, indicador não reconciliado ou inventários SHA alterados. Interromper sem retentativa automática; preservar evidências e pedir revisão de causa. **Não considerar** os PASS da #113 ou #141 como PASS físico deste novo executor.


### Errata de revisão estática pré-checkout (20/10/2026)

A primeira versão do executor no commit `bf9c4af706cac3c1a14e0bfa9e380e58b258c1fa` continha **erro de montagem textual no bloco de HEAD Git**, com duplicação do cabeçalho e condição `-notmatch` malformada. Detectado por inspeção do arquivo no GitHub **antes de qualquer checkout, parser Windows, preflight local ou COM**. A correção foi commitada separadamente em `1840ed9f7e2f627cf72eaa0d78a0d26e622a8702`, reconstruindo o bloco a partir do executor T25 histórico e reutilizando apenas o corpo C4-B1. Foi também trocado o comando de comparação do blob do executor para `git hash-object --path=$selfRel -- $self`, respeitando filtros de checkout Windows. A revisão estática da versão corrigida encontrou blocos `()[]{ }` balanceados, marcadores de segurança preservados e um único bloco de parâmetros; **não equivale a parser PowerShell**. **A versão original NÃO deve ser executada.** Ao realizar checkout, fixar o HEAD **final deste PR**, não o SHA antigo: o documento pode receber commits adicionais de rastreabilidade.

## Handoff e governança

**Ponto de parada deste PR:** runner e protocolo versionados, sem execução. Próximo objetivo admissível é revisar o PR Draft e validar o **parser Windows** + preflight de referência, em gate próprio sem COM. **Nenhum merge foi autorizado nesta preparação.** Não iniciar execução física, novo município, T26 regional, QVS de indicador final, C2/P5/D2/UI, alteração dos Boundaries 6/7 ou Fase IX.

**Bloqueios vigentes:** `C4_B1_RUNNER=VERSIONED_NOT_RUN`; `C4_B1_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
