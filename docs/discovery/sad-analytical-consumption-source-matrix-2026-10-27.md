# SAD — Matriz de necessidade de fontes e contratos (27/10/2026)

**Estado:** MATRIZ_DOCUMENTAL_CANDIDATA; READ-ONLY; não implica aceite de reengenharia ou compatibilidade global de dados. 
**Baseline:** main@db5d6e6e23371422ca1d2d77a8576150aaf63d03; [inventário acadêmico das 12 perguntas](analytical-question-inventory-2026-10-27.md); [V2 §62](phase-6-semantic-v2-approved-2026-10-14.md).
**Prova de arquivo:** AE01 [PR #160](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/160) @8633f12a910f422f6b2e9af5e0d06d622ff13497, [Issue #161](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/161), manifesto SHA-256 0B1AA7DA6EF10A08B0F698250F199666525672DC763D6774CA4498B2A3C488D2; estado restrito. **Análise das respostas** = cálculo exploratório fora do Git, NÃO novo PASS de gate.

## 1. Arquivos físicos AE01 e grão confirmado do extrato

| Código | CSV e grão de saída | Colunas efetivamente exportadas | Relação com fatos |
|---|---|---|---|
| E1 | sih_fluxo_competencia.csv: competência × ano × município RES × município SERV | competencia, ano, municipio_res, municipio_serv, qtd_registro_aih, qtd_internacao, qtd_continuidade | Agregação de SRC_SIH_RD.qvd; não é estrutura de FATO_INTERNACAO.qvd |
| E2 | sih_procedimento_competencia.csv: competência × ano × PROC_REA | competencia, ano, proc_rea, qtd_registro_aih, qtd_internacao, qtd_continuidade | Agregação de staging RD, não implica PROC_REA físico na fato |
| E3 | sih_diagnostico_competencia.csv: competência × ano × DIAG_PRINC | competencia, ano, diag_princ, qtd_registro_aih, qtd_internacao, qtd_continuidade | Agregação de staging RD, não implica DIAG_PRINC físico na fato |
| E4 | lt_cnes_leito_competencia.csv: competência × município SERV/localização × CNES × TP_LEITO × CODLEITO | competencia, municipio_serv, cnes, tp_leito, codleito, linhas_lt, qt_exist, qt_sus, qt_nsus | Agregação de SRC_CNES_LT.qvd; não equivale à FATO_CAPACIDADE_LEITO.qvd nem atesta recorte hospitalar |

As fatos materializadas possuem chaves SK e/ou %LINK_KEY com significado próprio. O vínculo RES/SERV, procedimento, diagnóstico e município de localização nas fatos depende dos contratos de dimensões/Link Table quando consultadas no QlikView, não pode ser inferido só pelos nomes nos CSVs.

## 2. Matriz completa das 12 perguntas

**Classes:** D = diretamente suficiente no extrato para pergunta delimitada; H = documentação histórica fora dos 4 CSV; C = depende de referência/contrato; A = dado auxiliar facultativo para nomes. "Sustentada" refere-se à **resposta descritiva por extrato**, não UI ou modelo associativo em QlikView.

| ID | Fato/processo, fonte e medida | Eixo/grão, extrato e regra | Dimensão/referência adicional | Resultado e estado; ressalva |
|---|---|---|---|---|
| I01 | Internação / RD; qtd_internacao | E1: ano de competência; IDENT=5 vale 0 | DIM_TEMPO no modelo; não precisa POP/LT no cálculo | D: 183.532 / 183.311 / 188.246 em 2017/18/19; não pessoas únicas |
| I02 | Internação / RD; qtd_internacao | E1: cada uma das 36 competências | DIM_TEMPO; não usar DT_INTER como competência | D: série de 36 meses; sem inferir sazonalidade causal |
| I03 | Internação / RD; qtd_internacao | E1: município SERV e ano | DIM_MUNICIPIO papel SERV; crosswalk para rótulo, não para somar código | D/A: códigos 250750+250400 = 65,43% exploratório; não residência |
| I04 | Internação / RD; qtd_internacao | E2: proc_rea realizado por competência | DIM_PROCEDIMENTO + SIGTAP por competência para descrição/hierarquia | D/A: 1.249 códigos, top 10 = 40,65% exploratório; nomes não auditados no AE01 |
| I05 | Internação / RD; qtd_internacao | E3: diag_princ por competência | DIM_DIAGNOSTICO + CID-10 para descrição | D/A: 5.473 códigos, top 10 = 23,97% exploratório; não prevalência |
| I06 | Internação / RD ou FATO_INTERNACAO; DIAS_PERM/VAL_TOT de staging; DIAS_PERMANENCIA/VALOR_TOTAL na fato | Soma administrativa 2017–2019; **ausente de E1–E4** | DIM_TEMPO; sem LT/POP | H: 3.133.578 dias, R$ 659.384.649,05 do F5-RD, **não reauditorado no AE01** |
| I07 | Internação / RD ou FATO_INTERNACAO; indicador de óbito da fato | Ano de competência; **ausente de E1–E4** | DIM_TEMPO | H: 8.626 / 8.649 / 9.336 do F5-RD, **não reauditorado no AE01** |
| I08 | Internação / RD; qtd_internacao | E1: RES=SERV / RES≠SERV por ano | Papéis de DIM_MUNICIPIO; não depende POP/LT | D: 294.635 iguais, 260.454 diferentes (46,92%) exploratório; não viagem individual |
| I09 | Internação / RD; qtd_registro_aih, qtd_internacao | E1: pares RES→SERV, externos separados; cruzamento por código | Crosswalk C5.2 dos 223 PB para classificar externo; não imputar POP aos externos | D/C: 5.202 RD externos, 5.067 novas; rótulo externo conforme lista de referência |
| I10 | Capacidade LT; qt_sus, presença de linhas | E4 + grade 223 municípios × 36 competências, distinguir positivo/zero/sem linha | Crosswalk municipal de referência necessário para montar grade; DIM_TEMPO/MUNICIPIO no modelo | D/C: 3.464 positivos, 97 zeros observados, 4.467 sem linha; ausência ≠ 0 |
| I11 | Capacidade LT; qt_exist/qt_sus/qt_nsus | E4: snapshot por competência, território, CNES, código | DIM_TIPO_LEITO; DIM_ESTABELECIMENTO/ST só para classificação/atributos; T29 pendente | D/A: distribuição observada; não somar meses como estoque anual, nem afirmar leito operativo/hospitalar |
| I12 | Internação RD + FATO_POPULACAO IBGE; numerador qtd_internacao, denominador populacao_estimada | RES por município×ano (E1) + POP município×ano **não presente no AE01**; ×1.000 | DIM_MUNICIPIO e DIM_TEMPO conformadas e contrato T24 temporal/territorial/filtros | C: não calculado globalmente nem homologado; não contar POP por mês; sem POP PB externo |

**I01–I05/I08–I11:** 9 perguntas com suporte descritivo dos extratos; I06/I07 prova histórica relatada; I12 condicionado. Não reclassificar como 12/12 "PASS".

## 3. Dependências dos indicadores avançados

| Indicador (V2 §62) | Fontes indispensáveis aos operandos | Território/tempo/denominador | Dependências abertas |
|---|---|---|---|
| T24 / RES por 1.000 | RD + IBGE/POP; crosswalk municipal | RES, ano da competência, POP do mesmo município/ano uma única vez | Link Key e filtros/indisponibilidade físicos, população para externos não aplicável |
| T25 / LEI por 1.000 | LT + IBGE/POP; crosswalk municipal | SERV/localização; média de **totais por competência válida** / POP anual | suficiência LT por município×competência, universo e filtros; #157 |
| T26 / REL internações/leito médio | RD + LT; compatibilidade municipal e temporal | Internações de SERV no período / média dos totais mensais de leitos SUS em SERV no mesmo recorte | suficiência LT, critérios de universo hospitalar quando aplicável, Link Key/medidas/filtros; #157 |
| FLU fluxo territorial | RD; nenhuma POP implícita | Pares RES→SERV; qtd_internacao no universo dos serviços PB | não provar associação global entre fatos só com E1; filtros de FLU têm contrato próprio |

**Fontes auxiliares:** ST apoia atributos e eventual recorte hospitalar, não substitui LT para QT_SUS; SIGTAP e CID para rótulos, não para contagem de códigos; POP é desnecessária para FLU e I01–I11 descritivas, mas continua obrigatória na terceira fato do projeto acadêmico.

## 4. Necessidade lógica ≠ necessidade de armazenamento

1. Não remover nenhuma origem, fato, dimensão ou referência por não participar de uma visualização; a constelação aprovada é parte do escopo acadêmico.
2. Não modificar fatos para expor campos staging por suposição. Consultas em fatos com SK/%LINK_KEY exigem compatibilidade e mapeamento aprovados no recorte.
3. Não criar 12 fatos derivadas nem fundir fatos de grãos distintos; possíveis projeções de consumo são candidatas, não novas tabelas físicas autorizadas.
4. Quando uma coluna é ausente do AE01 (I06/I07/POP), registrar ausência e apontar documentação original, em vez de atribuir valor revalidado.
5. Fonte quantitativa → referência de nomenclatura → integração de taxa são três níveis diferentes, com aceite independente.

**Pendente para o próximo gate:** prova de necessidade de cada dimensão/filtro no QlikView, topologia associativa por rota, custo/benefício A0 versus A1, sem executar COM.