# Fase VIII — C4-B1 | Closeout físico limitado e auditoria de evidências exportadas (21/10/2026)

**Resultado:** `C4B1_CLOSEOUT=COMPLETED_WITH_LIMITS`; `C4B1_PHYSICAL=PASS_LOCAL_C4B1_REGIONAL_SERVICE_T25_OBSERVED_CANDIDATE_ONLY` **segundo execução reportada no Windows/QlikView 12**; `C4B1_EXPORTED_EVIDENCE_AUDIT=PASS_CONSISTENCY_WITH_REPORTED_COM`. O único caso contratado foi encerrado. **Não** aprova `MEASURES_AND_DENOMINATOR_CONTRACT`, `LINK_KEY_CONTRACT`, escopo hospitalar histórico, P5/D2, interface ou produção.

## 1. Proveniência exata

- **PR:** [#142](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/142), mantido **Draft e sem merge** na hora do fechamento. Branch `test/phase-viii-c4b1-regional-t25-runner-20261020`. **Commit realmente executado:** `d0522d3c1048a858864ce0f16c9134dcb5693f7c`, anterior a este documento. **Runner:** `tools/Invoke-SadPhaseViiiC4b1RegionalT25.ps1`, Git blob `5ae827df755551a6698579d3a309b2db666f752a`, SHA-256 Windows `A7E7299AB5CAF7B24DB70B58BE8CDD16302968CD664128A53B31731A2775828E`.
- **Fonte física de teste:** cópia descartável do `SAD_VIII_T24_ANNUAL_TEST.qvw`, cuja origem foi checada com SHA-256 `7B2D92FD476CA7F64999C79DC55A510AFB811513BC1A60CACCC7586478C70C5E`. O executor não solicita `Reload`, `Save` ou `STORE` dos artefatos originais. **Uma única execução física autorizada** foi reportada, com `C4B1_PHYSICAL_EXIT_CODE=0` e `C4B1_PHYSICAL=PASS_LOCAL_CANDIDATE_PENDING_INDEPENDENT_REVIEW` antes da auditoria do ZIP.
- **Arquivos locais originais da tentativa** (conforme stdout, não acessados fisicamente nesta auditoria): `%TEMP%\SAD_VIII_C4B1_T25_b4832ad454954d4f97dda2e5c4176bb3` (internos); `%TEMP%\SAD_C4B1_PHYSICAL_D0522D3C_SINGLE_ATTEMPT` (inventários externos e stdout).
- **ZIP recebido na conversa e lido independentemente em ambiente Linux/Python**: `c4b1_physical_evidence_review.zip`, **17 membros**, tamanho **41.303 bytes**, SHA-256 `597E15897E50A2717CA26489EA0E5D9AC08FB797F99974885B07E19A1C4C0D7A`, todos acessíveis e `testzip()` sem erro. O ZIP não é versionado no Git.
- **Manifestos congelados:** `manifest_F1_F2.json` SHA-256 `926D5EE06373D6B30C3617501A9E81F2F0E6C16CFEF98A9EF1AAF25113EF025B`; `manifest_F3.json` SHA-256 `9FE3543374870878915A2ABAE6A88DFDB07778FDDA9D506A3B87A2DD2D98DA08`. Oráculos F2 mensal `DC0FAE8646F6570F5DEEAF8A1597EA5ED90A5BD9A881A40B4DCA0E30380E953D`, F2 anual `97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D`, F3 cenários `3B7315A564666D43A43E60700B5ACC4E255FEF6535F53219EC3D8A08C74CBFF9`, F3 POP `4AC341479A63EEA3FAA1FC2C20A3C2447C94294B940BDAFDFD9799BD555A7699`. Os SHA reais dos quatro CSVs coincidiram com os próprios manifestos e os pins do executor; a dependência F3 → manifesto F1/F2 confere.

## 2. Reconciliação independente do caso delimitado

**Contexto:** `PERIODO_ANO=2018`, papel `SERV`, municípios `250400` (Campina Grande) e `250750` (João Pessoa) **simultaneamente**, nenhuma seleção de residência/competência anual/procedimento. Cenário F3 `2018/SERV/JP_CG_2`, único, com escopo `CANDIDATO_RN21_SEM_ESCOPO_HOSPITALAR`.

| Medida auditada | Referência CSV F2/F3 recalculada | QlikView no CSV exportado |
| --- | ---: | ---: |
| Campina Grande: soma de 12 snapshots `QTD_LEITOS_SUS` para auditoria | 16.592 | incluída no total |
| João Pessoa: soma de 12 snapshots `QTD_LEITOS_SUS` para auditoria | 28.106 | incluída no total |
| **Região: soma dos 12 snapshots, não leitos simultâneos** | **44.698** | **44.698** |
| Média mensal dos 12 totais regionais observados | 44.698 / 12 = 3.724,833333… | implícita na razão |
| **População anual somada uma vez por município** | **1.207.795** | **1.207.795** |
| Linhas de POP anual alcançáveis | 2 esperadas | **2** |
| **T25 candidato/1.000 habitantes** | **3,0839946624496154838638455477…** | **3,0839946624496** |

A taxa foi refeita por `1000 × (44.698/12) / 1.207.795` usando aritmética decimal; erro absoluto exportado `0,0000000000000154838638455477`, abaixo do limite `0,000001`. Os **24 pares municipais** (12 por município) foram relidos e conferidos por competência com `F2_lt_municipio_competencia_observado.csv`, inclusive `QT_EXIST = QT_SUS + QT_NSUS`, contagem LT positiva e sem duplicações. A referência observada soma **5.299 linhas LT**, não leitos. Os controles F2 anuais de ambas as cidades declararam `12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED` e `hospitalar_historico_validado=NAO`.

**Componentes Qlik × F2 regionais conferidos um a um:** 201801=3.750; 201802=3.752; 201803=3.705; 201804=3.702; 201805=3.681; 201806=3.707; 201807=3.710; 201808=3.710; 201809=3.735; 201810=3.761; 201811=3.743; 201812=3.742. **12/12 iguais** e total anual 44.698. `F3_cenarios_multimunicipais.csv` também indica 119.857 internações elegíveis de serviço para o cenário; **esse dado não participa de T25**.

## 3. Integridade de inventários e nível de prova

- Inventários externos `inventory_before.csv` e `inventory_after.csv`: **47/47 linhas**, compostas por 22 QVDs e 25 QVWs atuais, com caminhos sem duplicações, tamanhos e SHA-256 idênticos nos dois arquivos. Ambos os CSVs são **byte-identificados** (SHA-256 `85D6B1E7DC6E45DDB03B47959ECD8F5F280F19143E28F2A5BDF4A8F4A66B9FAD`).
- Inventários internos `qvd_before.csv`/`qvd_after.csv`: **22/22**, conteúdo byte-idêntico, SHA-256 `14B9CFAA069FC7BD3A87E388C0589AA9874481D563ED5F8AAC85AF0800642948`; `LINK_ANALISE.qvd` mantém o pin `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB`.
- Inventários internos `canonical_qvw_before.csv`/`canonical_qvw_after.csv`: **3/3**, byte-idênticos, SHA-256 `1A648FC9114F0F76E5CB1AA59527F0F329984E88514D001ED809936D5A8524DC`. Cada registro interno também corresponde a um registro do inventário externo.
- O `c4b1_physical_stdout.txt` foi relido em **UTF-16**, SHA-256 `F175E9008BED4049C0757B0188F867D42CA98E4DFC2D68423A7BF79942DAA949`, e confirma o HEAD, script, QVW origem, quatro pins de oráculos, reconciliação anual, resultados locais e sinalizadores de preservação informados pelo runner.
- Uma inspeção independente do ZIP realizou **215 verificações de consistência**, sem divergências, abrangendo integridade do pacote, hashes/manifests, grãos, chaves, 24 parcelas F2, 12 meses do Qlik, cálculo decimal e três pares de inventários. **Alcance da auditoria:** os CSVs e logs exportados; **não** os bytes reais dos 22 QVDs/25 QVWs originais, que não fazem parte do pacote. A execução COM foi **reportada no Windows** e **não foi reproduzida** no ambiente de auditoria. Logo o status é consistência independente de evidência **exportada**, não verificação independente de QlikView/produção.

O inventário auxiliar histórico com 10 QVWs teve caminhos fora da raiz atual; 10/10 corresponderam por SHA aos atuais antes deste gate. O inventário de 47 itens **cobre integralmente a janela desta execução física**, mas não reconstitui o passado dos outros 15 QVWs antes do checkout anterior. Não apagar nem normalizar esses arquivos.

## 4. STOP / limites de decisão

**`C4B1_CLOSEOUT=COMPLETED_WITH_LIMITS`** exclusivamente para **um** cenário T25 regional de serviço sob universo observacional RN21. **Não executar `-RunQlik` novamente**, não ampliar municípios/anos, não iniciar T26 regional, não declarar capacidade hospitalar validada, não converter `Sum(QTD_LEITOS_SUS)` de 12 meses em estoque anual, não criar expressões globais de KPI com filtros `B`, não extrapolar P5/D2/UI ou Fase IX.

Estados **não promovidos**: `C2_FULL=NO_GO_NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Gate fechado:** nenhum merge, alteração da `main`, mudança de modelagem ou deleção de branches foi autorizado pelo envio do ZIP. O [PR #142](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/142) deve ficar Draft até uma decisão explícita posterior de integração. Os PRs preparatórios #139–#141 também não foram integrados por esta ação.
