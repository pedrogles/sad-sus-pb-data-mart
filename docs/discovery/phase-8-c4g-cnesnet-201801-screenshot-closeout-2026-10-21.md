# SAD — Data Mart SUS PB | C4-G — Closeout do confronto CNESNet × VI-P4 (201801)

> **Nota de integração documental (21/10/2026; origem: relatório local/Library):** Este documento preserva o texto, os resultados e as condições de prova do closeout original. Baseline vigente na preparação deste PR: `main@4b2d062536c42fe718fc622adc66f55e6d44e3a1` (C2-I #150 já integrado). Afirmações abaixo como “ainda Draft”, “fora da main” ou “próximo gate” são fotografias da data da revisão, não instruções operacionais atuais. O bloqueio anterior de acesso remoto descrito no documento C4-G de viabilidade foi superado somente pelas três capturas manuais deste relatório. Isso não prova cobertura hospitalar, zero real ou equivalência de todos os universos. A publicação não inclui TXT/PNG/ZIP/QVD/QVW de origem nem reproduz COM, e **não aprova** cobertura hospitalar, zero real, Link Key, medidas, P5/D2, dashboards ou produção.

**Data:** 21/10/2026  
**Contrato:** continuação autorizada de C4-G, estritamente `READ-ONLY`; três municípios PB, competência `201801`.  
**Repositório canônico:** `pedrogles/sad-sus-pb-data-mart`, `main@a3e904e32b71858cd4d7fba3c027845cfc8fe8d7` conferida nesta revisão.  
**Status local proposto:** `C4G_OFFICIAL_SCREENSHOT_READBACK=COMPLETED_WITH_LIMITS` — **2/2 comparações numéricas concordantes; 1/1 ausências visuais compatíveis, sem zero comprovado**. Não é `GATE_PASS` de cobertura/hospitalização, contrato físico, produção ou UI. Este relatório **não** foi publicado no Git.

## 1. Objetivo e fontes de prova

Confrontar o `municipio_mes_observabilidade.txt` exportado pelo VI-P4 (já encerrado, execução Windows/QlikView reportada) com três capturas manuais da consulta pública **CNESNet — Leitos**, mostrando município/UF, competência e totais Existente/SUS. A resposta oficial filtrada anteriormente inacessível no ambiente remoto passou a estar documentada pelas capturas entregues pelo responsável. Não se consultaram novos municípios, meses, estabelecimentos nem se obteve HTML/JSON bruto do CNESNet.

Hierarquia reconsultada nesta execução: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → Boundary 7 → contrato semântico V2 §62 → C1 CNES/LT → VI-P4. Fonte de comparação é a exportação recebida `VI-P4-evidencias.zip`; as capturas são **evidências manuais de apresentação oficial**, não cópia independentemente auditada do banco CNES nem atestado de integralidade.

### 1.1 Identificadores dos arquivos recebidos

| Evidência | SHA-256 | Papel |
|---|---|---|
| `VI-P4-evidencias.zip` | `f79e66584f1b6bcf146861781b318f36820b62e89c335368a3785411f9a4d527` | Pacote original exportado e trazido pelo operador |
| `municipio_mes_observabilidade.txt` dentro do ZIP | `1cbf654d6fe0cd45e77abb97f1f42f1545a2ca9106eae2cf1a6f3afe42a44796` | Matriz VI-P4 com 8.028 pares município×competência |
| `image(20261021-121510).png` | `a9d962e39f1a0f5d1eedc822b5686eefcc9c52054994c608d75da163418db62d` | Água Branca, tela oficial para 01/2018 |
| `image(20261021-121520).png` | `10c6ac9650578aad2fc700834c994f3ccb1b9920698493ba62387fa59353a65a` | Conde, tela oficial para 01/2018 |
| `image(20261021-121528).png` | `678d264f8fb13548bd5ddb1d846c62a9e5a038ecda8f08ec7a3dcc76bf1f1c00` | Zabelê, tela oficial para 01/2018 |

Hashes identificam bytes disponibilizados nesta conversa; não demonstram integridade de backups originais do Windows. Leitura auxiliar de dados nesta sessão foi exploratória; **nenhum novo runner de gate nem auditoria física versionada foi executado**.

## 2. Matriz reconciliada visualmente

Cada captura exibe `Estado: PARAIBA`, a seleção do município, `Competência: 01/2018`, URL com `VEstado=25`, `VMun=<DATASUS6>` e `VComp=201801`. Os dois recortes numéricos têm resumo `TOTAL GERAL`. Para Zabelê, após os seletores, nenhuma tabela aparece na área visível; isso não comprova zero, ausência de estabelecimento ou completude.

| Município de serviço | DATASUS6 | VI-P4: linhas LT | VI-P4: existentes/SUS | CNESNet exibido: existentes/SUS | Resultado permitido |
|---|---|---:|---|---|---|
| Água Branca | `250010` | 3 | **20 / 20** | **20 / 20** | `MATCH_NUMERIC_OBSERVED_SCOPE` |
| Conde | `250460` | 1 | **40 / 0** | **40 / 0** | `MATCH_NUMERIC_OBSERVED_SCOPE` |
| Zabelê | `251740` | célula vazia | **células vazias**, não zeros | **sem tabela exibida** | `CONSISTENT_NO_DISPLAYED_ROWS_NOT_ZERO_PROOF` |

**Detalhes verificáveis nas telas:**

- **Água Branca:** `CLÍNICA GERAL` 10 existentes/10 SUS (`33`); `OBSTETRÍCIA CLÍNICA` 4/4 (`43`); `PEDIATRIA CLÍNICA` 6/6 (`45`). `TOTAL GERAL`: **20 existentes, 20 SUS**. A apresentação mostra categorias resumidas, não chaves de todas as linhas LT nem prova da vigência histórica dos rótulos.
- **Conde:** `PSIQUIATRIA` (`47`), **40 existentes, 0 SUS**, também no `TOTAL GERAL`. **Zero SUS observado** não significa ausência de leitos existentes, leitos hospitalares com cobertura integral, nem zero real comprovado no recorte.
- **Zabelê:** município `ZABELE` e `01/2018` visíveis, mas nenhuma tabela numérica exibida na captura. Comportamento **compatível** com ausência de linha no VI-P4; causas alternativas de ausência de tabela (por exemplo, comportamento da interface) não foram excluídas.

**Contagem estrita de comparações:** 2/2 casos com total numérico oficial visível = concordância; 1/1 caso sem tabela visível = compatibilidade observacional, **não** `MATCH_ZERO`.

## 3. Interpretação e limites obrigatórios

1. **FATO VERIFICADO nas evidências fornecidas:** dois totais CNESNet observados correspondem exatamente aos dois totais do VI-P4 para município/competência; não existe contradição numérica nesses casos. O terceiro não mostra dados na tela. Não há prova de que os dois canais sejam datasets estatisticamente independentes, pois ambos remetem ao CNES.
2. **NÃO DEMONSTRADO:** integralidade dos estabelecimentos CNES/LT, filtro estritamente hospitalar historicamente vigente, cobertura estadual/2017–2019, completude de qualquer município nas 12 competências, elegibilidade para indicadores gerais ou zero quantitativo real na ausência de linhas. As capturas agregadas não expõem todos os registros CNES×tipo de leito para comparação de grão.
3. **Não promover T29:** nomes mostrados pelo CNESNet em `01/2018` são descrições visíveis no relatório consultado; sem documento de vigência aplicável, não tornam os rótulos historicamente comprovados para a dimensão nem substituem `T29_HISTORICAL=NOT_APPROVED`.
4. **Contrato V2 preservado:** RN21 mantém todas as linhas LT válidas; para a oferta, eixo `SERV`; para médias anuais, 12 competências válidas por município e média de snapshots; ausência não se transforma em zero; não equiparar internações/leito à ocupação. A prova é mensal de três recortes e não homologa T25/T26 globais.
5. **Nível de validação:** revisão manual de capturas oficiais fornecidas pelo operador + comparação documental com TXT já exportado. Não houve consulta HTTP adicional, reprodução das cargas, inspeção dos QVDs binários, teste COM, aprovação visual do painel ou teste de filtros.

## 4. Fechamento, bloqueios e próximo objetivo único

**C4-G concluiu o confronto observacional exatamente no escopo de três municípios e uma competência.** Os retornos manuais resolvem o impedimento `NO_FILTERED_OFFICIAL_RESPONSE` registrado na primeira tentativa, **apenas para estes recortes**. O relatório anterior de viabilidade permanece histórico, mas seu veredito de inacessibilidade não descreve mais o estado da comparação visual agora efetuada.

**Estados sem alteração:**

- `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `ZERO_PROOF=NOT_PROVEN`; `T29_HISTORICAL=NOT_APPROVED`;
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`;
- `C2_FULL=NO_GO_NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`;
- `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Próximo gate recomendado, sujeito a autorização separada:** um **closeout de decisão de suficiência acadêmica/operacional da Fase VIII**, apenas documental, reunindo C4-D/C4-E/C4-F/C4-G, sem repetir VI-P4/C4-B1 ou solicitar mais municípios automaticamente. Seu objetivo é separar o que já é apresentável como `CNES/LT observado` sob o aceite limitado do PR #133 das lacunas que de fato impedem contratos globais, C2/P5/D2 e início da Fase IX; propor a menor decisão de aceite de escopo, sem mudar a modelagem sem aprovação. Evitar continuar investigações históricas indefinidamente sem critério de ganho.

**STOP:** nenhum QVD/QVW/script, base, `current-state.md`, PR, branch ou merge alterado; nenhuma recarga QlikView/COM; relatório e capturas somente em pacote externo ao Git. Os estados do repositório não foram atualizados por este documento local.

## 5. Referências canônicas e consulta apresentada

- `https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/AGENTS.md`
- `https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/project/current-state.md`
- `https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md`
- `https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-6-vi-p1-p4-script-versioning-2026-10-16.md`
- `https://github.com/pedrogles/sad-sus-pb-data-mart/blob/main/docs/discovery/phase-8-c1-cnes-coverage-readonly-2026-10-18.md`
- Água Branca: `https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VEstado=25&VMun=250010&VComp=201801`
- Conde: `https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VEstado=25&VMun=250460&VComp=201801`
- Zabelê: `https://cnes2.datasus.gov.br/Mod_Ind_Tipo_Leito.asp?VEstado=25&VMun=251740&VComp=201801`