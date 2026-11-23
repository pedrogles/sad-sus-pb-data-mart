# VIS-05 — fechamento editorial e roteiro (23/11/2026)

## Contrato e autorização
O responsável autorizou prosseguir com a nova cópia do PDF e o roteiro após concluir a revisão focalizada. Objetivo: AUD-01 na página física 22 (20 impressa) e comunicação operacional AUD-10. Nenhuma alteração de QVW/QVD/QVS/modelo/medida/agregação/associação; nenhuma sessão QlikView, merge ou submissão. Main revalidada em 5486ad9f50744769e85107132eae009529ac75cc. Esta atualização fica somente na Draft #242; revisão visual encerrada na Draft #243, registro 493cb27cb0c9b3472c452214885fb400a9a142ab.

Leituras: AGENTS → current-state → requirements → final-delivery-record → automação; pacote mínimo de apresentação e fontes/figura VIS-05 identificados pelos pins. Ambiente efetivo: Work com GitHub/arquivos/shell Linux; runtime Codex, modelo/esforço exatos não verificáveis, sem subagentes ou escalonamento. PASS da entrega: documento novo, fonte preservada, 98 páginas, 97/97 páginas fora do escopo iguais, figura intacta e QA visual. STOP alcançado com arquivos preparados para ensaio/revisão.

## Código versionado antes da execução
- Roteiro: docs/academic/vis05-presentation-script-2026-11-23.md, publicado em 5a78b277e5e9e3df8bff3b62ba4b965e31e90067.
- Executor: tools/patch_sad_vis05_editorial_2026_11_23.py, publicado e executado no commit 67abf4ef5678c926d56855def2f230a1861ffbf3.
- Entrada: SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS05_2026.pdf, SHA-256 4C6033F3131F4B05105BBFCD992A2A6E7896CD5A2D424BF0BEA513430D0ED9F3. Hash da fonte conferido antes/depois; arquivo original não substituído.
- Saídas locais: output/editorial_final sob o workspace da conversa, entregues como cópias novas; binários fora do Git.

## Tratamentos aplicados

**AUD-01:** abertura do §3.2, legenda da Figura 7 e comentário M1-01 agora explicitam competência administrativa. Nota junto à figura esclarece que “Ano da Internação” na captura deve ser lido como “Ano de competência”, associado a PERIODO_ANO, e não ao ano da data clínica de admissão. Medida, agregação, valores e imagem não foram alterados. Os comentários M1-02/M1-03 foram reposicionados para acomodar a nota, com conteúdo preservado. O eixo no QVW e na captura continua histórico; não declarar correção da interface.

**AUD-10:** roteiro adotado como tratamento operacional: filtro EQ/NE restrito à análise de fluxo, limpeza de todas as seleções antes de leitos/população e comunicação explícita de que vazio/zero sob fluxo não representa população/capacidade real zero. Não há nova guarda automática ou aprovação associativa global.

**AUD-03/04:** revisão focalizada já encerrada na #243: EQ/NE e inversão de ordem, CH05 em 2018 e CH09 em SERV=250750. Nenhum cenário, teste numérico, hash de dataset ou sessão QlikView foi repetido nesta edição.

## Resultado e QA

| Arquivo novo | Páginas | SHA-256 |
|---|---:|---|
| SAD_Data_Mart_SUS_PB_DOC_R3_VIS05_Revisado_2026-11-23.pdf | 98 | F3F1F5C9F677D6F39C1BA7B24A12E4E1A38C33F1736D381B8173BE32CDF43DB3 |
| SAD_VIS05_Roteiro_Apresentacao_2026-11-23.pdf | 2 | C5D844540AB84F1D871F0CBCD4DC537A90A428F7438814150CFECAF2DC5D8383 |

A comparação executada contra o PDF VIS-05 pinado confirmou **97/97 páginas fora do escopo idênticas em texto, geometria e renderização a 72 DPI**. Somente página 22 modificada. Bytes da imagem embutida da Figura 7 e retângulo preservados; cabeçalho, título da seção e rodapé da página 22 inalterados. Valores 183.532, 183.311, 188.246 e 555.089 preservados. Capítulos 1–2, anexos, §§3.7/4.1 e demais páginas não alterados.

Página 22 renderizada a 2000px e inspecionada visualmente: nota legível, legenda em duas linhas, textos e figura sem cortes/sobreposição. Roteiro renderizado a 1500px nas duas páginas, ambas inspecionadas: títulos, parágrafos e rodapés legíveis, sem overflow. Resultado **EDITORIAL_ARTIFACT_QA=PASS_RESTRICTED**. O JSON técnico SAD_VIS05_Revisao_Editorial_2026-11-23.audit.json mantém o resultado automático de preservação com revisão visual pendente; o aceite visual humano está neste registro, sem reescrever a prova bruta.

## Estado final delimitado
AUD-01 tratado no material/roteiro, sem edição QVW; AUD-10 tratado por roteiro de uso, sem alteração de modelo. Pendências de apresentação focalizadas tratadas no alcance contratado. **READY_FOR_REHEARSAL_WITH_DOCUMENTED_LIMITS**; não declarar aprovação docente, submissão ou produção.

Pendentes: leitura final do responsável; ensaio online real; confirmação docente de fontes em arquivos e três folhas como três painéis; conferir prazo/atividade e submeter pelo responsável, guardando protocolo. C2/C3/C4, T29, Fase IX e produção continuam sem aprovação global.

Main continua descrevendo o snapshot anterior enquanto #242/#243 são Draft. Usar nomes e hashes explícitos desta revisão; não tratar Draft como integrada. Sem atualizar main ou fazer merge automaticamente.

**STOP:** correção editorial, roteiro, preservação e QA concluídos; sem novas frentes/testes QlikView ou alterações dos nove objetos.
