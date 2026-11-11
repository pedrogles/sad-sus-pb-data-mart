# SAD — Auditoria final de indicadores, redundância, PDF DOC-R3 e ensaio online

**Data:** 10/11/2026. **Gate:** `SAD-FINAL-ACADEMIC-AUDIT-01`. **Natureza:** inspeção estática/documental e visual do PDF, com roteiro de ensaio **não executado**. Sem QlikView COM, Reload, alteração de QVD/QVW/QVS, edição ou regeneração do PDF de 98 páginas, merge ou submissão ao Classroom.

## 1. Contrato e fontes

**Objetivo:** mapear indicadores efetivamente exibidos, campos/dimensões presentes mas não consumidos pelos nove objetos do MVP, sobreposições legítimas e riscos de inconsistência; revisar o DOC-R3 na leitura final e definir **um ensaio online** limitado à apresentação acadêmica.

**Fonte de verdade:** `main:AGENTS.md` → `main:docs/project/current-state.md` → `main:docs/academic/requirements.md` → `main:docs/discovery/sad-consumption-14-delta-readonly-closeout-2026-10-29.md`; depois construtor MVP `tools/Build-SadMvpThreeSheetsTemp.ps1` em Draft #226, scripts factuais da `main` e DOC-R3 de 98 páginas gerado e validado editorialmente na conversa. PRs #232/#233/#234 são Drafts e **não** integram a `main`.

**Arquivo analisado:** `SAD_Data_Mart_SUS_PB_Relatorio_DOC_R3_Consolidado_2026.pdf`, 98 páginas, SHA-256 `DA04BB440DC57DDD9DFB20331AFB548EDC3142143E82A0C92605EC8B7904CB01`. O R2 original foi recebido em bytes e preservado na composição DOC-R3. Auditoria anterior comparou 90/90 páginas preservadas (texto, geometria, imagens, anotações e renderização), e 8/8 substituídas com o caderno final. Esta etapa **não reexecuta** os mesmos diffs.

**Critério de encerramento deste gate:** matriz de uso 9/9, relação com o blueprint 14, riscos de interpretação/UX e inspeção das seções do PDF; roteiro de ensaio online pronto. **Não** declarar o ensaio efetivamente aprovado sem vídeo/captura/observação da transmissão pelo operador. STOP depois da identificação dos problemas, sem remediação automática.

## 2. Inventário efetivamente apresentado — 9/9 objetos

**Evidência de fonte:** especificações de dimensão/expressão nos itens 205–213 do `tools/Build-SadMvpThreeSheetsTemp.ps1` do Draft #226, cotejadas com três folhas da VIS-03 e capítulos 3.2–3.4 do DOC-R3. A captura física demonstra os objetos existentes, mas a inspeção não reabre as propriedades COM da cópia final.

| Objeto / folha | Dimensão(s) exibida(s) | Expressão/medida especificada | Uso | Risco residual |
| --- | --- | --- | --- | --- |
| M1-01 / Produção | `PERIODO_ANO` | `Sum(QTD_INTERNACAO)` | Volume anual SIH | ano administrativo ≠ data clínica |
| M1-02 / Produção | `PERIODO_COMPETENCIA` | `Sum(QTD_INTERNACAO)` | 36 competências | não inferir causalidade |
| M1-03 / Produção | `SERV_COD_DATASUS_6` | `Sum(QTD_INTERNACAO)` | ranking atendimento SERV | códigos, não nomes |
| M2-01 / Leitos | `PERIODO_COMPETENCIA` | `Sum(QTD_LEITOS_SUS)`, `Sum(QTD_LEITOS_EXISTENTES)` | snapshots mensais | leitos semi-aditivos, não somar meses |
| M2-02 / Leitos | `SERV_COD_DATASUS_6` | `Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)` | ranking fixo 201912 | conflito anual 2018 ainda não aprovado globalmente |
| M2-03 / Leitos | `P23_ESTADO_OBSERVADO` | `Count(P23_MUNICIPIO_6)` | observabilidade de 8.028 células em ilha A1 | não interpretar células como municípios, ausência ≠ zero |
| M3-01 / Fluxos | `MVP_FI_RES_SERV_CLASS` | `Sum(QTD_INTERNACAO)` | RES=SERV/RES≠SERV | ausência de rótulos numéricos impressos nas barras |
| M3-02 / Fluxos | `RES_COD_DATASUS_6`, `SERV_COD_DATASUS_6` | `Sum(QTD_INTERNACAO)` | pares dirigidos | tabela extensa/códigos e cabeçalhos compactos |
| M3-03 / Fluxos | `RES_COD_DATASUS_6`, `PERIODO_ANO` | `Sum(POPULACAO_ESTIMADA)` | POP município × ano | filtro SERV/mensal exige indisponibilidade; não somar anos |

**Conclusão:** os nove objetos têm finalidades analíticas distintas. A repetição de `QTD_INTERNACAO` entre séries, ranking e fluxo é por diferentes dimensões/grãos; a repetição de `QTD_LEITOS_SUS` é entre série temporal e ranking territorial de competência fixa. Isso **não configura redundância comprovada** que autorize exclusão.

## 3. Cobertura em relação ao blueprint de 14 (NÃO equivale ao MVP)

Blueprint na `main`: P1.1–P1.5 (5), P2.1–P2.5 (5), P3.1–P3.4 (4). O MVP apresenta **oito correspondências funcionais aproximadas** com P1.1/P1.2/P1.3, P2.1/P2.3/P2.4, P3.1/P3.2, e **uma visualização adicional de população** (M3-03), que não ocupa posição equivalente na lista central de 14. A correspondência P3.1 é parcial: pares dirigidos na tabela de todos os anos, não a matriz 2018 certificada do blueprint.

| Visual formal sem correspondente no MVP | Informação já prevista/validada documentalmente | Classificação |
| --- | --- | --- |
| P1.4 — Top procedimentos realizados | SIH/RD com chave de procedimento; oráculo E2 | **Não exibido**, não comprova campo ocioso |
| P1.5 — Top diagnósticos | SIH/RD com CID principal; oráculo E3 | **Não exibido**, não comprova campo ocioso |
| P2.2 — Composição SUS × não SUS | `QTD_LEITOS_NAO_SUS` + SUS/existentes, fotografia 201912 | **Não exibido**; P2.1 mostra SUS e existentes, mas não a composição explícita |
| P2.5 — CNES × tipo × código | estabelecimento e tipo de leito | **Não exibido**; ressalva histórica T29 |
| P3.3 — Ranking de pares RES≠SERV | apenas pares não coincidentes | **Não exibido**; M3-02 lista pares de ambos os grupos |
| P3.4 — Residentes externos | `QTD_REGISTRO_AIH` / `QTD_INTERNACAO` por cobertura externa | **Não exibido**; sem imputar POP PB |

**Não criar os seis agora por automatismo.** Trata-se de diferença entre dois escopos (blueprint formal vs. MVP TEMP). Decisão acadêmica separada é verificar se três folhas contendo nove visuais satisfazem o requisito de **três painéis** segundo o professor — equivalência reportada pelo operador, sem aceite docente documental disponível.

## 4. Indicadores e campos disponíveis, mas ausentes da apresentação

**Indicadores calculados/propostos nos Capítulos 1–2 e não exibidos nos nove objetos:** internações por 1.000 habitantes, leitos SUS por 1.000 habitantes e relação descritiva internações/leitos. Sua formulação exige compatibilidade ano, município, papel RES/SERV, denominador e cobertura hospitalar apropriada; C2/C3/C4/P5 e T25/T26 não estão integralmente aprovados. **Não** apresentar essas razões como resultado concluído, nem chamar razão internações/leito de ocupação.

**Medidas das fatos versionadas, mas não selecionadas diretamente nas expressões dos nove gráficos (inspeção estática):**
- `FATO_INTERNACAO`: `QTD_REGISTRO_AIH`, `DIAS_PERMANENCIA`, `VALOR_TOTAL`, `INDICADOR_OBITO`.
- `FATO_CAPACIDADE_LEITO`: `QTD_LEITOS_NAO_SUS`; os outros dois estoques aparecem em M2-01/M2-02.
- Não foi obtido inventário de todas as medidas do QVD físico nem do consumo por outros documentos/cenários. **Não classificar medidas como mortas/inúteis** só porque não aparecem nesse MVP.

**Dimensões aprovadas que não aparecem diretamente como eixo/tabela nos nove objetos:** Estabelecimento, Procedimento, Diagnóstico, Caráter de Atendimento, Motivo de Saída e Tipo de Leito. Podem atuar como estruturas físicas e chaves, embora não sejam eixos dos nove objetos apresentados. `DIM_TEMPO` e `DIM_MUNICIPIO` aparecem no consumo por suas projeções de papel/período. Não contar aliases de tempo ou município como dimensões acadêmicas novas; não excluir tabelas ou chaves para reduzir a tela.

**`P23_A1_ISLAND`: não é fato redundante, nem quarta fato formal.** A ilha intencional desacoplada fornece o gráfico M2-03 sem interferência dos filtros globais. Ela é usada; não remover nem conectá-la à `%LINK_KEY` sem mudança semântica aprovada.

## 5. Achados priorizados: defeito, risco e não-problema

| ID/prioridade | Observação e evidência | Classificação | Ação segura |
| --- | --- | --- | --- |
| A1 / alta acadêmica | O roteiro oficial exige `>= 3 painéis`; o MVP apresenta 3 folhas de uma QVW; equivalência foi reportada pelo operador e **não verificada com o professor** | **Decisão pendente**; não presumir reprovação | confirmar critério docente antes de submission; fallback relatório/3 folhas claramente separadas |
| A2 / alta de comunicação | Três indicadores derivados do Cap. 2 são propostos, mas não estão no MVP; não autorizar cálculo cruzado sem contratos | **Diferença entre proposta e demonstrado**, não resultado incorreto | explicitar no texto oral e, se necessário, nota editorial sem alterar modelo |
| A3 / média de visualização | R3 figuras 7–9 são capturas integrais compactadas em A4; rótulos/códigos e figuras 10–11 têm tipografia muito pequena em leitura a 100%; Figura 11 ocupa espaço mas aviso ocupa área pequena | **Risco de legibilidade** na apresentação do PDF (visual observado em páginas físicas 22–25) | priorizar QVW em tela compartilhada; usar zoom 150–200% para explicar figuras; eventual novo PDF só se autorizado |
| A4 / média semântica | M2-02 fixa 201912; seleção nativa de `PERIODO_ANO=2018` está explicitamente fora da prova restrita anterior; sob `201801` CH05 foi demonstrado | **Risco contextual residual conhecido**, não afirmar bug comprovado em 2018 anual | não usar filtro conflitante no ensaio; registrar como limitação da entrega acadêmica; não iniciar nova implementação nem refazer testes |
| A5 / média UX | M1-03/M2-02/M3-02/M3-03 exibem códigos de municípios em vez de nomes; tabela de pares é extensa, e M3-01 não imprime valores sobre as barras | **Limitação de comunicação**; nomes históricos não podem ser inventados | explicar RES/SERV e ler totais do roteiro; não alterar dimensões por cosmética |
| A6 / baixa | `QTD_INTERNACAO` e `QTD_LEITOS_SUS` reaparecem em objetos de grão diferente | **Não-problema:** comparação temporal/territorial complementar | manter |
| A7 / baixa | `P23_A1_ISLAND` desconectada do modelo principal | **Não-problema intencional** | manter justificativa da seção 3.3 |
| A8 / estrutural fora deste gate | C2 guiado, C3/C4, T29, T25/T26, Fase IX, 14 visuais físicos finais seguem pendentes | **Não aprovado**, não erro de PDF | preservar boundaries; não fazer implementação por arrasto |
| A9 / baixa documental | O PDF DOC-R3 consta de 98 páginas, sumário e referências; Figuras 7–11 presentes, 90 páginas preservadas segundo QA anterior | **PASS estrutural/editorial restrito** | não reconstruir PDF ou anexos sem defeito novo |

**FATO VERIFICADO:** nove dimensões/expressões no construtor, campos acima nos QVS de fatos, documento PDF renderizado e seus textos; **HIPÓTESE A CONFIRMAR:** impacto do tamanho dos rótulos no compartilhamento real; **DECISÃO PENDENTE:** equivalência folha/painel, e extensão de indicadores além do MVP. Nenhum campo foi demonstrado redundante no armazenamento físico ou com dependência zero; a análise é de **uso pelo MVP**, não profiling completo de memória/linhagem Qlik em execução.

## 6. Revisão final de leitura DOC-R3 (leitura técnica, não nova publicação)

**QA executado nesta etapa:** aberto o PDF completo de 98 páginas com PyMuPDF, conferido o SHA-256 acima; páginas físicas 21–28 contêm títulos 3/3.2/3.3/3.4/3.5/3.6/4/5; gráficos 7–11 presentes (1/1/1/2 imagens em páginas 22–25). Não se encontrou bloco de texto com coordenada externa aos limites das páginas 21–28. Foram renderizadas e inspecionadas as páginas 22, 23, 24 e 25 (figuras). O texto da página 23 explica `P23_A1_ISLAND`, `%LINK_KEY`, 8.028 células e três classificações. As legendas técnicas não foram auditadas semanticamente em Qlik nesta execução, somente a apresentação do PDF.

**QA ainda não executado fisicamente:** checagem de leitura humana em tela compartilhada real, gravação do ensaio, confirmação do Classroom e aceite do professor. As verificações anteriores de 90/90 páginas preservadas continuam válidas documentalmente e não foram repetidas.

## 7. Ensaio online recomendado — uma sessão controlada (a executar pelo operador)

**Condição de entrada:** usar a **cópia QVW CH06 corrigida**, SHA-256 pós-save reportado `6ED9CC1FAA5AFD592D1D4CECC8D6FC5DE2AB84D4DCE2D4E6D3E6A25E59D7BE37`; QlikView Desktop 12 carregado, sem Reload, folha 1 em estado neutro. PDF R3 de 98 páginas aberto como fallback, sem usar as capturas pequenas como material principal. Compartilhar **a janela do QlikView** na ferramenta real de reunião/sala, depois PDF se necessário.

**Roteiro de ~5 minutos para uma demonstração descritiva:**
- **00:00–00:40 — Objetivo e fontes:** “Construímos um Data Mart para analisar internações processadas pelo SIH/SUS, leitos cadastrados no CNES e estimativas anuais do IBGE na Paraíba, entre 2017 e 2019. Não é uma taxa de ocupação, nem um sistema de decisão clínica.”
- **00:40–01:20 — Modelo:** três fatos de grãos distintos, oito dimensões conformadas, Star por processo/constelação; QVD intermediário e QlikView 12. Explicar RES (município de residência) versus SERV (município de atendimento).
- **01:20–02:10 — Folha 1:** demonstrar 183.532, 183.311 e 188.246 novas internações por ano (total 555.089); série de 36 meses; ranking por SERV. Continuidade IDENT=5 não representa nova internação.
- **02:10–03:15 — Folha 2:** duas séries de snapshots SUS/existentes; ranking municipal de dezembro de 2019; ilha M2-03 com 4.467 ausentes, 3.464 positivos e 97 zeros observados. Ressaltar **8.028 células município×competência**, ausência ≠ zero e ilha independente.
- **03:15–04:20 — Folha 3:** 294.635 internações RES=SERV contra 260.454 RES≠SERV; pares dirigidos; população município×ano, não somar anos. Não inferir qualidade/acesso.
- **04:20–05:00 — Limitações e encerramento:** ausência de certificação hospitalar histórica T25/T26, indicadores por mil habitantes não homologados e seleção incompatível sinalizada por avisos; MVP experimental, não produto operacional. Apontar capítulos 3–5 do PDF e anexos QVS se perguntado.

**Checklist da sessão (uma única rodada):** texto de M2-03 legível na transmissão e cor/categoria inequívoca; 3 abas reconhecíveis; cortes/escala de janela; som/áudio e troca de abas; tempo total e perguntas; apresentação do PDF como fallback. Se houver corte crítico, registrar uma captura do fluxo transmitido e **STOP** para decisão específica de UX; não redesenhar QVW nem criar testes C2/C3/C4 como reflexo automático. Não efetuar filtros conflitantes para “demonstrar” guardas cuja prova já é restrita; explicá-las com as figuras do relatório se necessário.

**Critérios:** `ONLINE_REHEARSAL=PASS_LOCAL_OPERATOR_REPORTED` somente após realização de uma sessão real, confirmação de leitura dos três painéis e ausência de cortes; `INCONCLUSIVE` sem evidência. Esta revisão documental **não** executa reunião nem compartilhamento e, portanto, declara `ONLINE_REHEARSAL=NOT_RUN`.

## 8. Status e STOP

`INDICATOR_USAGE_AUDIT=PASS_STATIC_9_OF_9`  
`BLUEPRINT_COVERAGE=8_MAPPINGS_PLUS_1_POP_NOT_FORMAL_14`  
`MISSING_BLUEPRINT_VISUALS=6_NOT_IN_MVP`  
`UNUSED_PHYSICAL_FIELDS=NOT_PROVEN`  
`DOC_R3_FINAL_READING=PASS_EDITORIAL_RESTRICTED_WITH_LEGIBILITY_NOTES`  
`DOC_R3_PDF_CHANGES_THIS_GATE=NONE`  
`ONLINE_REHEARSAL=NOT_RUN`  
`TEACHER_THREE_PANELS_EQUIVALENCE=UNVERIFIED`  
`C2_C3_C4_GLOBAL=NOT_APPROVED`  
`PHASE_IX=NOT_AUTHORIZED`  
`PRODUCTION_APPROVED=False`

**STOP:** encerrar auditoria estática e entregar roteiro de ensaio; não fazer merges, eliminar dados/objetos ou reabrir C2/C3/C4. Novo trabalho somente para um achado material com autorização delimitada e evidência.


## 9. Adendo de decisão — segunda entrega encerra o projeto acadêmico (10/11/2026)

O responsável esclareceu que **não haverá implementação posterior** à segunda entrega da disciplina. Portanto:
- As seis visualizações do blueprint formal sem equivalente no MVP não constituem um backlog previsto para execução após a submissão; a lista de 14 visuais era uma proposta técnica mais ampla, enquanto a **entrega efetiva é de três folhas/nove objetos**.
- Os indicadores derivados da Seção 2.9 do Capítulo 2 foram tratados na revisão final do PDF: os itens 2.9.1–2.9.3 não foram exibidos por ausência de evidência global suficiente de compatibilidade dos fatos, período, município, denominador e, no CNES, abrangência hospitalar histórica; o item 2.9.4 (fluxo RES→SERV) foi demonstrado descritivamente.
- As medidas ainda não utilizadas diretamente em gráficos permanecem no modelo, sem constituir trabalho pendente obrigatório nem promessa de novos gráficos.
- Os gates científicos/operacionais C2/C3/C4 e Fase IX que não foram homologados devem ser **ressalvas de alcance** da entrega concluída, não um cronograma assumido de produção.

**Artefato atualizado e auditado:** `SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_2026.pdf` (98 páginas, SHA-256 `D5FC55797DA939C2E2815B66309A05953B4E5D9C1927DC1E7D74A9879658D44D`). Na PR #234 estão o executor versionado e o documento de governança da revisão. O ensaio online permanece **não executado**; a próxima ação é apenas apresentação/submissão, não extensão da implementação.

**Status:** `ACADEMIC_SCOPE=FINAL_AT_SECOND_DELIVERY`, `FUTURE_IMPLEMENTATIONS_PLANNED=False`, `DOC_R3_SCOPE_RATIONALE=INCORPORATED`, `PRODUCTION_APPROVED=False`. Nenhum merge, QVW/QVD/QVS ou script ETL foi alterado neste adendo.
