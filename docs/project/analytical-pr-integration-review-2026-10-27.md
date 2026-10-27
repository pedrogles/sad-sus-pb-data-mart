# SAD SUS PB — Parecer de integração dos PRs #160, #162, #163, #164 e #165

**Data:** 27/10/2026. **Autorização do responsável:** “realize uma revisão para não perder nada entre esses PRs e integre”. **Natureza:** revisão de integridade de documentação/código versionados, **não** teste QlikView nem homologação científica global.

## 1. Objetivo e limites

Assegurar que as cinco propostas da fase analítica permaneçam auditáveis após merges sequenciais, sem deletar, sobrescrever ou reexecutar dados existentes. Preservados: QlikView 12, fluxo acadêmico BASE→EXTRACAO→QVD→TRANSFORMACAO→QVD→PAINEL, três fatos, oito dimensões, V2 §62, RN21, Boundary 7 e Capítulos 1–2 entregues. **Nenhum QVD, QVW binário ou dataset foi incluído.**

## 2. Inventário e decisão de integração

| PR | Natureza | Origem efetivamente testada/autoridade | Resultado de integração |
|---|---|---|---|
| [#160](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/160) | QVS/PowerShell/Python e documentação AE01 | Execução AE01 tentativa 02 reportada em `8633f12a910f422f6b2e9af5e0d06d622ff13497`; 4 CSVs + manifesto/arquivo/log auditados restritamente na [Issue #161](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/161#issuecomment-6446935266) | Squash na `main`: `e9a36316693ec2994699067945af9b6be2a4704f`; adendo após execução sem alterar scripts testados |
| [#163](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/163) | Dois documentos de preparação A0 | Gate DOCUMENTATION_PREPARED_ONLY, posterior desenvolvimento R1 em PR próprio | Squash na `main`: `6eb5d7adbe92d19f9203c211a163b457ac4a321b` |
| [#164](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/164) | Runner/oráculo/testes A0 + documento | R1 Windows reportada sobre `7760c3079f998243e5bf72c44747aac60e2b76e0`; [auditoria](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/164#issuecomment-6451787982) 146/146 **somente** 36 SIH + 108 LT + 2 pares | Squash na `main`: `c0e63a902b38c3794f7d7330d3be44b68def702b`; adendo posterior de rastreabilidade |
| [#162](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/162) | Decisão de fontes, matriz I01–I12, Discovery e bootstrap A0×A1 | Preparação documental; não escolhe A1 nem autoriza A2/remodelagem | Squash na `main`: `50a92a9fd77445bf8212f78f340ba54f5e259039`; título `current-state.md` normalizado |
| [#165](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/165) | Escopo D1–D3, contrato de 14 visuais e estado operacional reconciliado | Aceite expresso em conversa: 5 P1 + 5 P2 + 4 P3; I06/I07 opcionais, T24/I12 condicionado | Integração por squash sob autorização expressa, verificar SHA efetivo no [PR #165](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/165); não confundir SHA de merge com código da execução A0/AE01 |

**Verificação de sobreposições:** #162 e #165 modificam `docs/project/current-state.md`. O estado recomposto toma a `main` após #162 como base textual, preserva a seção documental anterior como **histórico**, adiciona um único estado operacional vigente D1–D3 e elimina delimitadores duplicados. Os demais PRs adicionam arquivos próprios, sem exclusões ou sobreposição física.

## 3. Alias de prova A0 × contrato de 14 visuais

| Prova anterior | Objeto novo | Nível real |
|---|---|---|
| A0 `P1.2` | P1.2 série SIH mensal | 36/36 valores, sem homologação de UI |
| A0 `P2.2` série LT mensal | **P2.1** série LT mensal | 108/108 medidas mensais; capacidade semi-aditiva |
| A0 `P3.1` | P3.1 fluxo RES→SERV | Apenas 2/2 pares, não matriz completa |
| Nenhum objeto visual equivalente comprovado | **P2.2** composição SUS/não SUS | Totais mensais de P2.1 servem de oráculo **numérico**; visual/composição não homologados |

A prova de `P2.2` histórico **não** deve ser transferida como aceite gráfico do `P2.2` novo. As 146 verificações são evidências de resultado local reconciliado com pacote arquivado, não reprodução independente do COM nem aprovação de interface.

## 4. Estado semântico preservado e próximos bloqueios

- AE01: `EXPORTED_AND_RECONCILED_RESTRICTED`; análise exploratória das perguntas não é novo gate PASS. I01–I05 e I08–I11 sustentadas **nos extratos**; I06/I07 não reauditadas com E1–E4; I12 sem contrato global T24.
- A0 R1: `A0_R1_RESTRICTED_ORACLE_RECONCILED_WITH_ARCHIVED_EVIDENCE`. A origem de execução **não** é o SHA squash da `main`.
- Decisão de produto D1–D3: `SCOPE_ACCEPTED_RESTRICTED_BY_OWNER_IN_CHAT`; não aprova A1, Link Key global, medidas globais, UX, Fase IX ou produção. Não altera a modelagem acadêmica.
- Pendências: `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`, G1/[Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) aberta para T25/T26.
- **Próximo gate candidato:** READ-ONLY A0×A1 limitado aos 14 visuais e aos contratos faltantes. Preservar a ordem física C2→C3→C4, sem reexecutar AE01/A0 por decorrência.

## 5. Condição de parada

Após merge do PR #165, verificar **todos os cinco PRs MERGED**, presença dos arquivos adicionados, título único e ambas as seções (#162 histórico e #165 vigente) em `current-state.md`, matriz 12/12, contrato 14/14, nenhum QVD/QVW/dado introduzido, issue #157 aberta e nenhum gate promovido. Se não for possível verificar, registrar item faltante e interromper integrações adicionais, sem afirmar sucesso total.
