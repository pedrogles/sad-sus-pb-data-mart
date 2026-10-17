# Fase VI — VI-P5: contrato físico candidato SAD-LINK-V1 e projeção da população

**Data:** 17/10/2026  
**Fonte de verdade:** `main@834f8c0a5f7b35890c524a6a243dabd674af6924`  
**Estado:** `VI_P5_STATIC_REVIEW=PASS_CANDIDATE_ONLY`; `POPULATION_LINK_PROJECTION=APPROVED_FOR_CONTRACT`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `PRODUCTION_APPROVED=False`.  
**Natureza:** registro de decisão arquitetural e de revisão estática. **Não** é implementação, prova física independente, aceite de produção, autorização de merge ou autorização de criar `LINK_ANALISE.qvd`.

## 1. Objetivo e autorização restrita

Consolidar o menor contrato técnico para a futura Link Table da Fase VI, reaproveitando a revisão VI-P5 e os preflights VI-P1–P4 integrados na `main`. Após apresentação da alternativa, o responsável autorizou em 17/10/2026 **prosseguir com a projeção da `%LINK_KEY` de população em memória no carregamento associativo**, mantendo `FATO_POPULACAO.qvd` intacto. A autorização alcança a **formalização documental dessa escolha**, não homologa toda a arquitetura associativa fisicamente nem libera execução QlikView.

Escopo deste PR: **somente este Markdown**. Nenhuma alteração dos Boundaries 6/7, modelagem acadêmica, scripts, QVDs, QVWs, `TRANSF.qvw` ou `PAINEL.qvw`. Sem testes, sem merge.

## 2. Fontes verificadas na main, em precedência

1. `AGENTS.md`;
2. `docs/project/current-state.md` (snapshot 16/10 anterior ao PR #98; usar junto com o HEAD real);
3. `docs/academic/requirements.md`;
4. `docs/discovery/boundary-7-implementation-plan.md` (§§ 13, 22, 31, 33);
5. `docs/discovery/boundary-6-qlikview-physical-architecture.md` (§§ 5–13, 16–17, 22);
6. `docs/discovery/phase-6-semantic-v2-approved-2026-10-14.md`;
7. `docs/discovery/phase-6-vi-p1-p4-script-versioning-2026-10-16.md`;
8. `docs/project/qlikview-powershell-automation.md`;
9. `TRANSFORMACAO/transf_fato_internacao.qvs`, `transf_fato_capacidade_leito.qvs`, `transf_fato_populacao_inmemory.qvs`, `vi_p1_readonly.qvs`; `TRANSFORMACAO/phase_v_populacao_qvd_readback.qvs`; `tools/Invoke-SadViP2Readonly.ps1`; `PAINEL/painel_main.qvs`.

**Hierarquia:** roteiro oficial do professor > documentação oficial das fontes > evidências reais > repositório > chats. O contexto do chat apenas documenta a autorização e não substitui os contratos da `main`.

## 3. Estado e nível de prova

| Aspecto | Fato verificável / origem | Limite |
| --- | --- | --- |
| `main` | HEAD `834f8c0a5f7b35890c524a6a243dabd674af6924`, PR #98 integrado | Não valida artefatos Windows |
| Três fatos físicas | 566.672 internação; 35.518 capacidade; 669 população, com CREATE/READBACK locais reportados na documentação Fase V | QVDs binários não inspecionados independentemente nesta revisão |
| Chaves persistidas | Internação e capacidade armazenam `%LINK_KEY`; `FATO_POPULACAO.qvd` tem sete campos, incluindo `%SK_MUNICIPIO` e `%SK_TEMPO_ANO`, **não** `%LINK_KEY` | Verificação estática de QVS/schema documentado |
| VI-P1 | 77.550 links RD, 7.486 LT, 669 POP projetados; 85.705 combinações no modelo temporário; nove tabelas/zero `$Syn` detectadas, PASS local restrito reportado | Nem QVD `LINK_ANALISE` nem modelo final |
| VI-P2 | Recuperação candidata de POP anual sob competência por Set Analysis; filtro direto de competência deixou POP sem linha associada, conforme teste local restrito | Expressões definitivas, P5 e KPIs **não aprovados** |
| VI-P3 | T24–T26 candidatos em recorte João Pessoa/2018 e 2018-09; PASS restrito | Sem generalização |
| VI-P4 | 8.028 município×competência; 4.467 sem LT; 97 com soma SUS observada zero; 3.464 positiva; 35.518 linhas reconciliadas, PASS local restrito | Não prova zero real nem cobertura hospitalar |
| Integridade | 21 QVDs locais reportados, SHA-256 preservado no VI-P4 | Sem nova verificação no Windows |

Não converter PASS local reportado, revisão estática, evidência histórica em PR #83 ou protótipo em aprovação física/semântica completa.

## 4. Esquema aprovado e contrato candidato de coordenadas

O Boundary 6 **já aprovou** Link Table como ponte física, três fatos separadas, dimensões conformadas e aliases de papéis. O Boundary 7 determina construir a Link Table **depois** das fatos e **antes** do painel técnico. A Link Table não é uma nona dimensão ou quarta fato acadêmica.

Campos físicos planejados de `LINK_ANALISE`:

- `%LINK_KEY`;
- `%SK_TEMPO_COMPETENCIA`;
- `%SK_TEMPO_ANO`;
- `%SK_MUNICIPIO_RESIDENCIA`;
- `%SK_MUNICIPIO_SERVICO`;
- `%SK_ESTABELECIMENTO`.

| Coordenada | FATO_INTERNACAO | FATO_CAPACIDADE_LEITO | FATO_POPULACAO |
| --- | --- | --- | --- |
| Competência | Competência administrativa SIH/RD | `COMPETEN` LT | `NULL` |
| Ano | Ano administrativo | Ano da competência LT | Ano IBGE |
| Município residência | `MUNIC_RES` | `NULL` | Município PB mapeado |
| Município serviço | `MUNIC_MOV` | `CODUFMUN` | Mesmo município PB mapeado |
| Estabelecimento | CNES × competência | CNES × competência | `NULL` |

As coordenadas não aplicáveis ficam **fisicamente nulas** na Link Table; nunca preencher com `0`, `N`, município fictício ou estabelecimento artificial. A marca `N` é usada **somente no argumento serializado do hash**. População usa a mesma SK municipal nos dois papéis sem duplicar sua linha. Município de residência externo à PB permanece válido na internação, sem população PB artificial.

As SKs são as já definidas nos scripts e Boundaries: município `Hash128('MUN', DATASUS6)`, estabelecimento `Hash128('ESTAB', CNES, COMPETENCIA)`, competência `Hash128('MES', AAAAMM)`, ano `Hash128('ANO', AAAA)` com conversões e tipos efetivamente validados. Não substituir a definição física por concatenação textual de códigos naturais nem assumir equivalência automática de representações dual/text do QlikView.

## 5. Identidade `SAD-LINK-V1`: especificação candidata sem mudanças

Ordem e domínio invariantes: `Hash128('SAD-LINK-V1', C, Y, R, S, E)`, onde os **cinco argumentos** são strings distintas prefixadas por `C=`, `Y=`, `R=`, `S=`, `E=`. Para cada SK, aplicar a serialização observada nos scripts da `main`:

- SK realmente `NULL`: `'N'`;
- SK presente: `'V' & Len(Text(SK)) & ':' & Text(SK)`;
- prefixo da coordenada aplicado **antes** de passar o argumento ao `Hash128`.

Assim, para população, os argumentos extremos são `C=N` e `E=N`, enquanto `R` e `S` codificam a **mesma** SK municipal; `Y` codifica a SK anual. Para capacidade, `R=N`; na internação, as cinco coordenadas devem estar presentes. Um valor vazio não pode ser tratado silenciosamente como `NULL`; onde a coordenada é obrigatória, vazio/inválido deve bloquear a validação.

**Decisão:** reutilizar literalmente a convenção candidata já persistida nas duas fatos. Qualquer alteração de `Hash128`, ordem, `Text`, normalização, comprimento, delimitadores, domínio ou regra de `NULL` exige análise explícita de compatibilidade com QVDs existentes e autorização separada. Não transformar esta especificação em declaração de `LINK_KEY_CONTRACT=APPROVED` antes das evidências físicas pertinentes.

## 6. Decisão aprovada: projeção da população na camada associativa

**Escolha:** manter os sete campos físicos de `FATO_POPULACAO.qvd` inalterados; derivar `%LINK_KEY` apenas na carga associativa em memória do futuro painel técnico, a partir das SKs persistidas `%SK_MUNICIPIO` e `%SK_TEMPO_ANO`. A expressão deve ser exatamente equivalente à `_POP_EXPECT` do `TRANSFORMACAO/vi_p1_readonly.qvs`.

**Divisão de responsabilidade:**

1. **Fase VI / transformação:** construir `LINK_ANALISE.qvd` em gate separado e autorizado, usando fontes/QVDs existentes, com as três projeções de coordenadas e deduplicação estrita por `%LINK_KEY` + coerência de tupla. Esse QVD conterá as seis colunas previstas e não medidas.
2. **Fase VII / carga associativa do painel:** ler `FATO_POPULACAO.qvd` sem sobrescrevê-lo; derivar a única `%LINK_KEY` de ligação a partir de suas duas SKs; conservar `POPULACAO_ESTIMADA` e metadados de origem necessários, mas **não** carregar `%SK_MUNICIPIO` e `%SK_TEMPO_ANO` sob os nomes compartilhados originais nessa fato final. Se for necessário retê-las para auditoria, usar nomes de campo exclusivos e explicitamente não associativos.
3. **Internação e capacidade no painel:** consumir suas `%LINK_KEY` persistidas sem reconstruí-las, mantendo na fato apenas as dimensões exclusivas e campos factuais previstos.
4. **Dimensões:** associar as compartilhadas somente pela Link Table e criar aliases role-playing com nomes não colidentes. Datas clínicas e demais dimensões exclusivas permanecem diretamente nas respectivas fatos.

Essa pequena projeção em memória é **exceção técnica pontual e documentada** à preferência por LOAD otimizado e scripts simples do PAINEL (Boundary 6), não mudança no processo ETL ou no Data Mart acadêmico. O desempenho e a ausência de campos duplicados devem ser examinados no gate físico correspondente; **nenhum QVS de implementação é autorizado por este documento**.

Rejeitadas neste escopo: recriar `FATO_POPULACAO.qvd` e introduzir QVD intermediário de população. São alternativas que exigiriam escopo de escrita adicional sem benefício demonstrado.

## 7. Integridade, cardinalidades e invariantes de aceitação futura

- Toda linha factual possui **exatamente uma** `%LINK_KEY`; todas as chaves factuais têm correspondência em `LINK_ANALISE`.
- `LINK_ANALISE` tem `%LINK_KEY` única, sem colisão de tuplas diferentes; cada chave aponta para exatamente uma combinação de coordenadas.
- Pode haver **múltiplas linhas factuais para a mesma chave** (associação N:1 fato→Link); isso não duplica a fato. **Não exigir a mesma chave em fatos diferentes**: os papéis e nulos podem distinguir as combinações.
- Ao carregar as três fatos, nenhuma delas deve compartilhar com outra ou com `LINK_ANALISE` um segundo campo homônimo de associação. Nomes descritivos não devem criar joins acidentais.
- Qualquer projeção/concatenação precisa preservar contagens de 566.672, 35.518 e 669 linhas, grãos e medidas, sem multiplicação após associação.
- Preservar nulos inaplicáveis; impedir nulos/vazios em coordenadas **obrigatórias**; rejeitar órfãos obrigatórios e chave ambígua.
- `$Syn` injustificadas = 0; circular references = 0; nenhum recurso a loosely coupled tables para mascarar loop (validação física do modelo completo continua na Fase VII).
- Manter os 21 QVDs originais, QVWs e dados brutos imutáveis; exigir manifesto SHA-256 antes/depois quando execução física for autorizada.

**Baseline apenas experimental:** VI-P1 calculou 85.705 combinações distintas a partir de 77.550 RD + 7.486 LT + 669 POP e registrou nove tabelas temporárias sem `$Syn`. O número deve ser utilizado como referência de reconciliação sob os mesmos artefatos, não como prova independente de produção nem como cardinalidade acadêmica nova. Testes T17–T19 são pré-requisitos da materialização; T20–T21 e a confirmação visual do Table Viewer pertencem ao painel técnico posterior.

## 8. Não objetivos e dependências semânticas separadas

**Não** aprovar neste contrato:

- materialização ou READBACK de `LINK_ANALISE.qvd`; nova recarga de `TRANSF.qvw` ou alterações nas fatos;
- expressões QlikView finais T24–T26, denominadores gerais ou aprovação de `MEASURES_AND_DENOMINATOR_CONTRACT`;
- recuperação de POP anual após filtro mensal como solução geral: VI-P2 observou `POP` diretamente inacessível com competência selecionada e exercitou `Set Analysis` apenas como candidata; o gate de medidas deverá respeitar a V2, prevenção de conflito ano/competência e a política de filtros P5;
- prova de cobertura hospitalar CNES/LT, zero real em município×competência ou aplicação retroativa da legenda T29;
- Set Analysis de objetos finais, dashboard, testes COM/visuais ou homologação de produção.

A V2 permanece semanticamente aprovada com população anual, leitos como snapshots semi-aditivos, capacidade média do período validado e indisponibilidade em vez de zero inventado. Os 4.467 pares sem LT e 97 pares de zero observado do VI-P4 **não** certificam capacidade zero ou completude.

## 9. Contrato do próximo gate físico (proposta, sem autorização de executar)

**Objetivo único:** materializar e auditar `TRANSFORMACAO/QVD/LINK_ANALISE.qvd` conforme esta especificação, somente após autorização independente.

**Entradas:** três fatos existentes, QVDs dimensionais/staging necessários e QVS versionados; catálogo de hashes dos 21 QVDs locais, guardas de destino inexistente, Windows/QlikView 12. Implementação e executor PowerShell/QVS devem ser **commitados em branch antes da execução** (AGENTS.md).

**PASS físico limitado:** uma única Link Table em destino novo; chave única↔tupla única; 100% de cobertura das linhas das três fatos sem mudanças; coordenadas inválidas ou inaplicáveis tratadas corretamente; comparação com baseline VI-P1 justificada; QVD reaberto em QVW auditor distinto; 21 hashes inalterados; logs brutos frescos/TRACE/código da execução rastreados. Não aprova painel nem KPIs.

**BLOCKED/INCONCLUSIVE:** alteração ou ausência de QVD, colisão de tuplas, órfãos, desvio não explicado de contagens, problema de serialização/dual, erro de recarga, evidência incompleta ou tentativa de sobrescrever `LINK_ANALISE.qvd`. Preservar evidências e **parar**, sem R2 automático ou rollback destrutivo.

**Condição de parada:** encerrar quando materialização e READBACK do único QVD contratado obtiverem PASS restrito ou BLOCKED documentado. Não avançar automaticamente à Fase VII.

## 10. Governança e próximos estados

- `VI_P5_STATIC_REVIEW=PASS_CANDIDATE_ONLY`
- `POPULATION_LINK_PROJECTION=APPROVED_FOR_CONTRACT`
- `LINK_KEY_CONTRACT=NOT_APPROVED`
- `LINK_ANALISE_QVD=NOT_CREATED`
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`
- `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`
- `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`
- `T29_HISTORICAL=NOT_APPROVED`
- `PRODUCTION_APPROVED=False`

Este PR de documentação deve permanecer **Draft e sem merge** até revisão e aprovação específica. O snapshot de `docs/project/current-state.md` anterior ao PR #98 merece atualização operacional futura, mas está deliberadamente **fora deste PR de objetivo único**.
