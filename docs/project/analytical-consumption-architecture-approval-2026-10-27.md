# SAD — Decisão mínima de arquitetura de consumo A0/A1 (27/10/2026)

**Gate:** `SAD-ANALYTICAL-CONSUMPTION-ARCH-DECISION-01`  
**Estado da decisão em 27/10 (histórico):** `ARCH_DIRECTION_APPROVED_BY_OWNER_IN_CHAT_DOCUMENTATION_ONLY` / `P2_3_A1_LOGICAL_CANDIDATE_APPROVED_IN_PRINCIPLE` / `PHYSICAL_VALIDATION_PENDING` / `MERGE_AUTHORIZED_SEPARATELY`  
**Preflight:** `main@9b47abcc08e9765b8a50945d30babd82bb5d3021`, revalidada em 27/10/2026; nenhum PR aberto no instante do preflight.  
**Agente/ambiente:** ChatGPT GPT-6 + GitHub, inspeção estática; esforço efetivo não exposto pelo ambiente; Windows, QlikView, COM e GUI não acessados.  
**Autorização:** após o parecer da Discovery READ-ONLY e a explicação de que A0 deve ser mantida, com possível preparação derivada somente para P2.3, o responsável respondeu “autorizado, prossiga”. A primeira autorização é aqui interpretada **estritamente como aceite da direção arquitetural e avanço documental**. Posteriormente, o responsável solicitou expressamente “revise e realize as integrações”, autorizando **a revisão e o merge do PR #166** se não houver bloqueios documentais. **Nenhuma das duas autorizações** libera materialização, novo script, QVD/QVW, COM, reload, interface, Fase IX, produção ou aprovação científica.


**Atualização factual de 29/10/2026 — NÃO altera a decisão:** [PR #166](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/166) **MERGED**, A0 permanece padrão documental para **os 14 visuais**, com A1 **condicional e exclusiva** a P2.3. O [desenho lógico #168](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/168) e as integrações [#170](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/170) e [#169](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/169) registram **P2.3 A1 R2 com PASS físico candidato restrito e auditoria de readback**, não aceite de UI/produção. O [PR #167](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/167) permanece **OPEN/Draft** (`A0_NOT_VALIDATED` somente em R1 P2.3). O **próximo gate antigo abaixo era uma proposta de 27/10** e não deve ser reexecutado como Discovery A0×A1: seguir o [current-state](current-state.md) para o delta READ-ONLY dos 14 visuais.

## 1. Decisão vigente e alcance

**DECISÃO DE PRODUTO/ARQUITETURA:** escolher **A0 como padrão de consumo dos 14 visuais candidatos D1–D3**. Para P2.3, **admitir somente uma A1 lógica e restrita à grade observacional município PB × competência**, caso não seja possível obter, na camada de consumo A0, as células ausentes sem confundir ausência de linha com zero. A1 significa uma **projeção de apresentação/consulta**, não nova fato, nova dimensão acadêmica nem QVD materializado automaticamente. Se A0 puder exibir a mesma grade de forma correta e controlada, manter A0 também em P2.3: não há obrigação de introduzir A1.

**Evidência que fundamenta a exceção:** o registro factual CNES/LT contém observações, mas não linhas para todos os pares da grade 223 × 36; o QVS `TRANSFORMACAO/vi_p4_municipal_coverage.qvs` já demonstra, em ambiente de evidência VI-P4, o procedimento de construir grade completa, juntar pares com linha e classificar estados. O QVS `PAINEL/phase_vii_technical_model.qvs` apresenta fatos/dimensões/Link Table e **não carrega P4_MATRIX como superfície de consumo**. Logo, a necessidade é **representação de ausência**, não remodelagem dimensional. Não se afirma que A0 foi experimentalmente incapaz de exibir o gráfico.

**NÃO DECIDIDO:** implementação exata no QlikView, possibilidade de usar somente expressões de apresentação, estrutura e associação da projeção em memória, comportamento de seleções, performance e aceite visual. A1 física, A2/remodelagem, Link Key global, medidas/denominadores globais, C2 completo, P5/D2, T29 histórico, T24–T26 e Fase IX continuam sem aprovação.

## 2. Matriz consolidada — 14 visuais, fontes e status de consumo

**FI:** `FATO_INTERNACAO`, grão registro administrativo RD; **FL:** `FATO_CAPACIDADE_LEITO`, grão CNES × competência × código leito; **E1–E4:** CSVs AE01 como oráculos agregados, **não** colunas diretas da fato. “A0-base” não significa `VISUAL_ACCEPTED`. Campos abaixo são os confirmados **nos QVS versionados**.

| Visual | Origem física / campos da arquitetura atual | Grão e filtro crítico | Arquitetura sugerida / prova existente |
| --- | --- | --- | --- |
| P1.1 | FI.`QTD_INTERNACAO` | Ano administrativo via Link→`PERIODO_ANO` | **A0-base**; E1 anual, sem I06/I07 obrigatórios |
| P1.2 | FI.`QTD_INTERNACAO` | 36 competências; `PERIODO_COMPETENCIA` | **A0-base**; A0 R1 36/36 valores, sem UX |
| P1.3 | FI.`QTD_INTERNACAO` + `DIM_MUNICIPIO_SERVICO` | SERV×período; RES opcional requer prova de filtro | **A0-base**; E1 por código |
| P1.4 | FI.`QTD_INTERNACAO`, `[%SK_PROCEDIMENTO]` → `COD_PROCEDIMENTO` | PROC_REA×competência; filtros municipais além de E2 condicionados | **A0-base**; E2 por código |
| P1.5 | FI.`QTD_INTERNACAO`, `[%SK_DIAGNOSTICO]` → `COD_DIAGNOSTICO` | DIAG_PRINC×competência; filtros cruzados não demonstrados em E3 | **A0-base**; E3 por código |
| P2.1 | FL.`QTD_LEITOS_EXISTENTES`, `QTD_LEITOS_SUS`, `QTD_LEITOS_NAO_SUS` | Snapshot por competência, não somar meses | **A0-base**; A0 R1 108/108 (ID antigo P2.2), sem UX |
| P2.2 | Mesmas três medidas FL | Uma competência explícita; SUS + não-SUS = existentes | **A0-base**; base numérica disponível, composição visual não validada |
| P2.3 | FL + grade de referência municipal/competência; `P4_MATRIX` apenas em QVS VI-P4 | 223 municípios PB × 36 meses; ausente/zero observado/positivo | **A1 lógica apenas se necessária**, sem materializar; C4-F 8.028 células |
| P2.4 | FL.`QTD_LEITOS_SUS` + SERV via Link | Município SERV × competência explícita | **A0-base**; E4, cobertura hospitalar não verificada |
| P2.5 | FL.`FATO_LT_CNES_ORIGEM`, `[%SK_TIPO_LEITO]` + `DIM_TIPO_LEITO` | CNES×tipo×código×competência; rótulos históricos restritos | **A0-base**; E4, T29 pendente |
| P3.1 | FI.`QTD_INTERNACAO` + papéis RES/SERV via Link | RES×SERV×período | **A0-base**; E1 amplo, A0 R1 só dois pares |
| P3.2 | FI.`QTD_INTERNACAO` + códigos RES/SERV na Link/dimensões | R=S versus R≠S por ano; classificação a validar | **A0-base**; E1 reconciliado em recorte |
| P3.3 | FI.`QTD_INTERNACAO` + RES/SERV na Link/dimensões | R≠S, ranking de pares | **A0-base**; E1 por código |
| P3.4 | FI.`QTD_REGISTRO_AIH`, `QTD_INTERNACAO` + `RES_COBERTURA` | RES externo por ano, sem POP PB artificial | **A0-base**; E1/C5.2, filtro físico ainda não homologado |

**Preservar o mapa de aliases:** A0 R1 P1.2 = P1.2 atual; A0 R1 P2.2 (série LT) = P2.1 atual; A0 R1 P3.1 = somente 2 pares. P2.2 atual é composição e não teve aceite de visualização.

**Cobertura das perguntas:** I01–I05/I08–I11 (9) sustentadas **descritivamente no escopo dos extratos**; I06/I07 históricas opcionais, sem reauditoria AE01; I12/T24 condicionado e fora dos 14 visuais centrais, preservando `FATO_POPULACAO`.

## 3. Contrato restrito candidato para P2.3 (sem script novo)

1. **Universo territorial:** exatamente os 223 municípios PB identificados na referência C5.2/VI-P4. VI-P4 utiliza os códigos presentes em `FATO_POPULACAO` como *referência de universo*, **sem consumir `POPULACAO_ESTIMADA` como medida**. Não admitir por inferência os residentes externos PB no eixo de leitos.
2. **Universo temporal:** 36 competências `201701…201912`, explicitamente administrativas CNES/LT. Cada célula tem grão **município SERV/localização × competência**, com chave auxiliar isolada usada no VI-P4 `Hash128('P4-OBS',Trim(Text(MUNICIPIO)),Trim(Text(COMPETENCIA)))` (usando os eixos correspondentes do LOAD); isso **não é `%LINK_KEY`**.
3. **Origem observada:** por município×competência, contar linhas LT e somar QT_SUS/QT_EXIST; preferir a reconciliação da FL com LT feita no VI-P4, sem presumir que E4 contém as ausências.
4. **Três classes:** sem linha LT → `ABSENT_NOT_ZERO_PROVEN` com medidas **NULL**; linha LT e `QT_SUS=0` → `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED`; linha e `QT_SUS>0` → `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED`. `ZERO_REAL_COMPROVADO=NOT_PROVEN` e `COBERTURA_HOSPITALAR=NOT_VERIFIED` em todo o universo C4-F. Ausência associativa por filtro incompatível é classe distinta e **não** vira ausência de LT.
5. **Controles existentes:** `223×36=8.028` células únicas; 3.561 pares com linha (3.464 positivos + 97 zeros observados); 4.467 sem linha; 35.518 linhas LT no subconjunto observado. Esses são **oráculos históricos C4-F/AE01**, não resultados de execução deste gate.
6. **Apresentação:** declarar “observabilidade dos registros CNES/LT, 2017–2019”, não taxa de ocupação, cobertura hospitalar completa, ausência real de leitos nem zero imputado. Exibir ressalva T29 na presença de nomes/especialidades ou leitura histórica de tipo; preferir códigos sem extrapolação retroativa. Valores de snapshot são semi-aditivos no tempo.
7. **Associações:** a projeção não pode automaticamente adicionar campos associativos compartilhados às 16 tabelas do modelo técnico. Modo ilhado/sem associação ou associação explicitamente aprovada **é decisão física futura**; nenhuma solução presume integração funcional com filtros globais.
8. **Critério de rejeição:** qualquer multiplicação de medidas, linha sem origem transformada em zero, perda de célula, `$Syn`/loop novo, atribuição de descrição T29 não verificada ou divergência dos oráculos bloqueia uso no painel.

## 4. Evidência, status e risco

- **FATO VERIFICADO POR INSPEÇÃO ESTÁTICA:** QVS FI e FL têm as medidas acima; `PAINEL/phase_vii_technical_model.qvs` expõe aliases de tempo e RES/SERV via Link; `TRANSFORMACAO/vi_p4_municipal_coverage.qvs` possui lógica de grade, merge observacional e estados.
- **EVIDÊNCIA HISTÓRICA REPORTADA/ARQUIVADA:** AE01 quatro extratos reconciliados; A0 R1 **146/146 somente** 36 SIH + 108 LT + dois pares; C4-F 8.028 pares com classificação observacional. Não rodados/revalidados fisicamente neste gate.
- **HIPÓTESE DE CONSUMO:** os 13 visuais A0-base poderão funcionar sem A1; a grade P2.3 pode necessitar projeção lógica de apresentação. Nenhuma dessas proposições equivale a validação global de QlikView.
- **DECISÃO PENDENTE:** expressão/renderização, escolha ilhada/associativa de P2.3, controles de filtro/tempo/UX, orçamento de consumo e aprovação de visual. A1 não está habilitada para materialização.
- **Bloqueios preservados:** `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; G1/[Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) aberta; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

## 5. Handoff mínimo e STOP

**Próximo gate candidato:** `SAD-P2.3-CONSUMPTION-READINESS-01`, **READ-ONLY de desenho/critério**, restrito a decidir se a superfície P2.3 será uma projeção ilhada ou se A0 consegue fornecer a grade completa com segurança. Reutilizar `P4_MATRIX`, C4-F e oráculos; documentar impactos de filtros por papel e temporalidade sem implementar. Se futuramente for indispensável QVW temporário/QlikView, exigir autorização física **separada**, commit de script versionado, ambiente Windows autorizado, oráculo e invariantes SHA pré/pós. Não desenvolver R2/recarregar por decorrência.

**Critério do gate documental atual:** decisão A0-base, exceção P2.3 condicional, limites e handoff formalizados sem mudança física. **Resultado após revisão:** `ARCH_DIRECTION_APPROVED_DOCUMENTED_REVIEWED`, com autorização de merge independente; não `PHYSICAL_PASS`. O status Git de integração deve ser comprovado pelo PR e pela `main`, não inferido deste registro.

**STOP (escopo deste gate):** nenhum QVS/PowerShell/Python criado ou executado; nenhum QVD/QVW, script de produção, dado bruto, capítulo acadêmico ou ambiente local modificado. A integração Git documental foi autorizada separadamente e não corresponde a execução QlikView ou aceite físico. Não iniciar outro gate por decorrência.

## Referências canônicas

- [Escopo aprovado D1–D3](../discovery/sad-analytical-scope-acceptance-01-2026-10-27.md)
- [Matriz de fontes I01–I12](../discovery/sad-analytical-consumption-source-matrix-2026-10-27.md)
- [Discovery A0×A1 preparada](../discovery/sad-analytical-consumption-discovery-2026-10-27.md)
- [Estado operacional](current-state.md)
- [Evidence C4-F](../discovery/phase-8-c4f-vi-p4-export-readback-2026-10-21.md)
- [V2 §62](../discovery/phase-6-semantic-v2-approved-2026-10-14.md)
- [Boundary 7](../discovery/boundary-7-implementation-plan.md)
- [Modelo técnico VII](../../PAINEL/phase_vii_technical_model.qvs)
- [Grade observacional VI-P4](../../TRANSFORMACAO/vi_p4_municipal_coverage.qvs)
- [Execução A0 R1](../discovery/sad-a0-consumption-executors-dev01-2026-10-27.md)
