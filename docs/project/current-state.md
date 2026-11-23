# Current State — SAD Data Mart SUS PB

## Estado operacional — 23/11/2026 | correções concluídas, submissão pendente

**Escopo acadêmico final:** QlikView 12, três folhas/nove visualizações, três fatos e oito dimensões. A auditoria G0–G5 e a revisão visual focalizada estão encerradas com as limitações registradas. Não ampliar indicadores ou repetir os testes já concluídos.

| Frente | Estado atual e origem da evidência |
| --- | --- |
| Requisitos docentes | O responsável confirmou o aceite das fontes em arquivos e das três folhas como três painéis. Prazo mantido. Confirmação registrada a partir da comunicação do responsável, sem alegar leitura independente de manifestação docente. |
| PDF final | `SAD_Data_Mart_SUS_PB_Relatorio_Uniformizado_2026-11-23.pdf`, **86 páginas**. Layout, redação, sumário e comentários dos anexos revisados. Três indicadores não implementados tachados e justificados. SHA-256 `C74342B1B5A19885D5F406E71A5D7C443292F016048E57E2FFE1D747DA9DF1CB`. |
| QVW corrigido | Cópia `C:\Users\pedro\SAD_FINAL_EVIDENCIAS\M1_ROTULO_20261123_163651_83e0481074\SAD_PB_ANO_COMPETENCIA_CONFERIR.qvw`. M1-01/CH01 exibe **Ano de competência**; Save e persistência após reabertura confirmados no relatório local, com captura correspondente revisada. SHA local reportado `C78E6DD568ECE7360E985DE2D63D42D70F2EF47D73EA72A555DB3F622F2C0695`; bytes do QVW não recebidos no cloud. |
| Preservação | Relatório final da correção reconciliado independentemente: **26 caminhos únicos antes/depois, hashes e tamanhos idênticos**, cleanup sem erros. Nenhuma chamada Reload. Comparação detalhada de propriedades reportada pelo executor; snapshots não recebidos no cloud. |
| Rótulos e avisos | AUD-03/AUD-04 resolvidos nos estados contratados: EQ, NE, inversão de ordenação observada, CH05/2018 e CH09/SERV 250750. Não generaliza a todas as seleções ou propriedades. |
| Filtro de fluxo | AUD-10 tratado por comunicação e regra de uso: filtro restrito à análise de fluxo; limpar seleções antes de leitos/população. Vazio/zero nesses estados não prova zero real ou erro cadastral. |
| Apresentação e ensaio online | **Suspensos até segunda ordem do responsável. Não são pré-requisitos ativos da submissão documental.** |
| Entrega | Revisão e correções concluídas; submissão e comprovante ainda não registrados. |
| Integração documental | Material organizado nas PRs #243 (inspeção), #244 (correção QVW) e #242 (relatório e estado final). Conferir no GitHub o estado de integração: PR Draft não integra a main. Merge exige autorização específica do responsável. |

## Fontes vigentes e limites

- [Requisitos acadêmicos](../academic/requirements.md), [registro final de entrega](../academic/final-delivery-record-2026-11-10.md) e [closeout editorial](../academic/vis05-unified-report-closeout-2026-11-23.md).
- [Inspeção VIS-05](sad-vis05-readonly-inspection-gate-2026-11-15.md): preservação e evidências visuais delimitadas, incluindo a interrupção histórica não certificada. Não repetir os comandos de coleta.
- [Correção M1-01](sad-m1-temporal-label-automation-2026-11-23.md): execução Windows do responsável, relatório final e captura; não repetir o pacote nem substituir automaticamente o QVW original.
- O [roteiro de apresentação](../academic/vis05-presentation-script-2026-11-23.md) permanece como referência arquivada, sem retomada automática da apresentação.
- Modelo Star por processo factual/constelação, fluxo BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL, medidas e originais preservados.
- Indicadores cruzados não implementados; cobertura estritamente hospitalar histórica CNES não comprovada para todo o período; T29 e contratos globais C2/C3/C4 não recebem aprovação implícita. Ausência LT não equivale a zero; leitos/população são semi-aditivos e RES/SERV são papéis distintos.
- Sem Fase IX ou aprovação de produção. O encerramento acadêmico não elimina limitações metodológicas.
- Higiene conservadora do repositório já encerrada; inventários e execuções antigos não devem ser repetidos. [Closeout histórico](repository-conservative-branch-cleanup-closeout-2026-11-12.md). PR #240 e outras frentes independentes não integram este fechamento.

## Próximos passos e STOP

1. Responsável: guardar o PDF final, o QVW corrigido e as evidências; conferir os arquivos exigidos para o envio.
2. Repositório: concluir a revisão da consolidação documental; integrar somente mediante autorização específica, conferindo os HEADs e o estado da main.
3. Responsável: submeter no prazo mantido e guardar o recibo/protocolo.
4. Registrar a submissão comprovada e encerrar a entrega. Até esse registro, não declarar o trabalho submetido.

**STOP:** não iniciar novos indicadores, testes numéricos, sessão QlikView, alteração de modelo ou correção automática. Retomar apresentação/ensaio somente por nova instrução do responsável. Histórico, tentativas e hashes intermediários permanecem nos closeouts e no Git, sem reproduzir toda a cronologia neste snapshot.
