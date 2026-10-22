# SAD SUS PB — C4-F | Readback das exportações VI-P4 e seleção de casos históricos

> **Nota de integração documental (21/10/2026; origem: relatório local/Library):** Este documento preserva o texto, os resultados e as condições de prova do closeout original. Baseline vigente na preparação deste PR: `main@4b2d062536c42fe718fc622adc66f55e6d44e3a1` (C2-I #150 já integrado). Afirmações abaixo como “ainda Draft”, “fora da main” ou “próximo gate” são fotografias da data da revisão, não instruções operacionais atuais. A comparação oficial sugerida como C4-G foi depois concluída em três recortes, com duas concordâncias numéricas e um resultado visual inconclusivo; ver closeout C4-G deste PR. A publicação não inclui TXT/PNG/ZIP/QVD/QVW de origem nem reproduz COM, e **não aprova** cobertura hospitalar, zero real, Link Key, medidas, P5/D2, dashboards ou produção.

**Data:** 21/10/2026  
**Modalidade:** READ-ONLY; auditoria exploratória do pacote anexado, sem execução QlikView/COM.  
**Repositório:** `pedrogles/sad-sus-pb-data-mart`  
**Baseline `main` confirmado:** `a3e904e32b71858cd4d7fba3c027845cfc8fe8d7`  
**Resultado desta revisão:** `C4F_EXPORTED_EVIDENCE_READBACK=CONSISTENT_WITH_DOCUMENTED_VI_P4`, com limites. **Não** configura aprovação física/global dos indicadores ou auditoria de código versionado.

## 1. Objetivo e fronteiras

Após a recuperação do ZIP de evidências já produzido em 17/10/2026, ler os três TXT originais, verificar integridade interna, reconciliar os controles da `main` e selecionar **um caso real por classe observacional**. Não regenerar dados, não reexecutar VI-P4, não acessar ou escrever QVD/QVW, não aplicar classificação hospitalar retrospectiva, não criar KPI nem iniciar Fase IX.

Fontes consultadas na `main`, na ordem obrigatória: `AGENTS.md`; `docs/project/current-state.md`; `docs/academic/requirements.md`; `docs/discovery/boundary-7-implementation-plan.md`; `docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md`; `docs/discovery/phase-6-vi-p1-p4-script-versioning-2026-10-16.md`. Foram também consultados o QVS e o executor VI-P4 versionados, sem executá-los.

## 2. Proveniência e integridade do pacote recebido

**Arquivo fornecido:** `VI-P4-evidencias.zip`, **31.217 bytes**, SHA-256 `f79e66584f1b6bcf146861781b318f36820b62e89c335368a3785411f9a4d527`.

A estrutura ZIP passou no teste de integridade (CRC), contém **exatamente três membros** e não apresenta erro de descompressão:

| Arquivo exportado | Linhas de dados | SHA-256 dos bytes exportados |
|---|---:|---|
| `municipio_mes_observabilidade.txt` | 8.028 | `1cbf654d6fe0cd45e77abb97f1f42f1545a2ca9106eae2cf1a6f3afe42a44796` |
| `municipio_ano_observabilidade.txt` | 669 | `ac0b9ac42406ea3c59dfb8ba6230de8d3c9f1abafbef2125843a50621fb7c57e` |
| `competencia_observabilidade.txt` | 36 | `564c011ddeb67e2f1d7254029b2b18df74aa984108e58133a323764c8926f93c` |

Arquivos UTF-8 com BOM e delimitador `|`. Os cabeçalhos conferem com o contrato inspecionado no executor `tools/Invoke-SadViP4Readonly.ps1` da `main`. **Limite de proveniência:** não havia manifesto SHA contemporâneo independente dos três TXT da execução de 17/10 acessível nesta sessão. Os hashes acima ancoram *os bytes recebidos agora*, não provam sozinhos que os TXT vieram daquela sessão Windows. O QVW, seus logs completos e os QVDs físicos não foram reabertos.

## 3. Reconciliação do universo

| Controle | Apuração dos TXT | Estado |
|---|---:|---|
| Municípios distintos / competências distintas | 223 / 36 | Coerente |
| Pares município×competência distintos | 8.028 (sem duplicidade) | Coerente |
| `ABSENT_NOT_ZERO_PROVEN` | 4.467 | Coerente |
| `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` | 97 | Coerente |
| `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED` | 3.464 | Coerente |
| Pares com linhas LT | 3.561 | Coerente |
| Soma de `LINHAS_LT` | 35.518 | Coerente |
| Soma observacional de snapshots `QT_SUS` | 270.076 | Coerente; **não** estoque anual |
| Soma observacional de snapshots `QT_EXIST` | 337.147 | Coerente; **não** estoque anual |
| Municípios×ano | 669 | Coerente |
| Município×ano com linhas nos 12 meses | 290/669 | Coerente; não é cobertura hospitalar certificada |
| Agregações mensais de 36 competências × grade original | 36/36 reconciliadas, nenhuma divergência | Coerente |
| Agregações anuais de 669 município×ano × grade original | 669/669 reconciliadas, nenhuma divergência | Coerente |

O campo `ZERO_REAL_COMPROVADO` está `NOT_PROVEN` em **8.028/8.028** pares; `COBERTURA_HOSPITALAR` está `NOT_VERIFIED` em **8.028/8.028**. Na ausência de linha LT, os campos de medidas e contagem são **vazios no TXT**, não zero.

Controle cruzado não redundante com C4-B1: para `2018`, a soma dos 12 snapshots de João Pessoa (`250750`) no TXT é **28.106**, e a de Campina Grande (`250400`) é **16.592**; ambas coincidem com o closeout C4-B1. O TXT municipal não demonstra que cada LT representa estabelecimento hospitalar, nem comprova extensão para outros territórios.

**Nível da conferência:** leitura e recálculo exploratórios com Python local, sem executor de auditoria novo versionado no repositório. Esses cálculos servem a esta triagem e **não serão promovidos a gate físico/automatizado formal** sem regularizar/versionar o auditor e sua evidência conforme `AGENTS.md`. Não houve execução no Windows nesta revisão.

## 4. Três exemplos reais — mesma competência `201701`

| Classe | `MUNICIPIO` DATASUS (6) | `COMPETENCIA` | `LINHAS_LT` | `QT_SUS_OBSERVADO` | `QT_EXIST_OBSERVADO` | Estado literal no TXT |
|---|---|---|---:|---:|---:|---|
| Ausência de registro | `251740` | `201701` | *vazio* | *vazio* | *vazio* | `ABSENT_NOT_ZERO_PROVEN` |
| Zero SUS observado, mas leitos existentes | `250460` | `201701` | 1 | 0 | 40 | `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` |
| Valor positivo observado | `250010` | `201701` | 3 | 20 | 20 | `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED` |

Nos três registros, `ZERO_REAL_COMPROVADO=NOT_PROVEN` e `COBERTURA_HOSPITALAR=NOT_VERIFIED`.

**Interpretação e limites:**

- `251740`: ausência no LT municipal daquele mês, **não prova** município sem leitos ou capacidade igual a zero.
- `250460`: 40 leitos existentes e zero leitos SUS **no recorte observado**; não equivale a ausência de leitos, nem atesta completude do universo de estabelecimentos.
- `250010`: 20 leitos SUS observados em três linhas LT; não demonstra que toda a capacidade hospitalar municipal esteja cadastrada ou validada.

O mesmo trio de códigos apresenta as mesmas três classes, linhas LT e quantitativos também em **`201801`**, verificado nos TXT recuperados. A competência `201801` é uma opção de comparação externa com melhor acessibilidade documental (ver §5), **sem substituir ou apagar a amostra `201701` usada nesta revisão**.

## 5. Evidência externa e pendência histórica

Documentação oficial consultada:

- [Dúvidas frequentes CNES](https://wiki.saude.gov.br/cnes/index.php/D%C3%BAvidas_Frequentes): descreve a manutenção de retratos cadastrais por competência mensal. Não certifica, por si só, que ausência de registro LT significa ausência de leitos.
- [Consumo e download de informações da Base Nacional CNES](https://wiki.saude.gov.br/cnes/index.php/Categoria:Consumo_de_informa%C3%A7%C3%B5es_da_Base_Nacional_do_CNES_via_webservice_e_Download_da_Base_de_Dados): documenta consultas no portal antigo e novo, TabNet/TabWin e disponibilidade da base para download por competência **a partir de 06/2017**. Isso não estabelece acesso ao mesmo formato para janeiro/2017.
- [Nova classificação de tipos de estabelecimento](https://wiki.saude.gov.br/cnes/index.php/Categoria:Nova_Classifica%C3%A7%C3%A3o_de_Tipos_de_Estabelecimento): utiliza atividades principal/secundárias conforme regras da versão 4.0.50. Não estabelece regra histórica validada de `TP_UNID` para todos os meses 2017–2019.

**Nenhum relatório oficial do tipo município×competência para os três municípios foi baixado e confrontado numericamente nesta sessão.** Portanto, a revisão externa não demonstra `ZERO_REAL_COMPROVADO=True`, completude hospitalar ou validade de recorte estritamente hospitalar. Mesmo uma correspondência numérica externa exigirá análise de unidade, origem, universo e classificação para sustentar cobertura integral.

## 6. Resultado, próximos passos e STOP

**Resultado desta revisão documental:** `C4F_EXPORTED_EVIDENCE_READBACK=CONSISTENT_WITH_DOCUMENTED_VI_P4`; `C4F_THREE_REAL_OBSERVATIONAL_CASES=IDENTIFIED`. São **rótulos de triagem local**, não gates canônicos integrados nem `PASS` físico de QlikView.

**Próximo gate mínimo proposto (se autorizado): `C4-G — confronto oficial histórico de três recortes, READ-ONLY`.** Verificar se a fonte oficial permite consultar/exportar `201801` para os **mesmos três códigos DATASUS** (`251740`, `250460`, `250010`), mapear corretamente o identificador territorial para o filtro oficial, conferir competência/medida/universo e comparar com os TXT. O uso de `201801` evita tomar como pressuposto que a base do portal tenha o download de `201701` (cuja disponibilidade oficial documentada começa em junho/2017). **Não** iniciar download em massa, `QlikView`, COM ou criação de nova extração. Se a fonte não fornecer o recorte ou divergir, `BLOCKED` com motivo; não preencher lacunas por inferência. Qualquer regra nova de zero real/hospitalidade exige evidência própria e aprovação específica.

**Bloqueios preservados:** `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `ZERO_PROOF=NOT_PROVEN`; `T29_HISTORICAL=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP:** encerrada a leitura do ZIP e a seleção auditável dos três casos. Sem merge, PR, alterações em `main`, scripts, QVD/QVW ou implementação.