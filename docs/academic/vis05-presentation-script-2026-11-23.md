# SAD — roteiro final de apresentação
**Versão:** 23/11/2026 | três folhas, nove objetos | preparado para ensaio

## Antes de começar
Abra o QVW VIS-05 de apresentação preservado e mantenha o PDF revisado disponível como apoio. Não recarregue dados. Limpe todas as seleções e confira a janela Seleções Atuais. Este roteiro restringe o uso dos filtros; não acrescenta bloqueios automáticos ao aplicativo.

## Abertura
“Este Data Mart apresenta análises descritivas de internações administrativas do SIH/SUS, leitos cadastrais observados no CNES e população municipal do IBGE, na Paraíba, entre 2017 e 2019. São três processos com granularidades e referências temporais próprias.”

## Folha 1 — Produção Hospitalar
“No primeiro gráfico, ‘ano’ significa **ano de competência administrativa**, e não o ano da data clínica de admissão. O rótulo ‘Ano da Internação’ da captura deve ser lido como ‘Ano de competência’.”

“Os resultados são 183.532 em 2017, 183.311 em 2018 e 188.246 em 2019, totalizando 555.089 novas internações administrativas. Não são pacientes únicos; as AIHs de continuidade, IDENT=5, não entram como novas internações.”

Apresente a série de 36 competências e o ranking por município de atendimento, SERV. Não confunda atendimento com residência, RES.

## Folha 2 — Leitos Cadastrais Observados
**Antes de apresentar: limpe todas as seleções e confirme o estado vazio.**

“A série mostra fotografias mensais do cadastro. Não somamos os meses para obter capacidade anual, nem interpretamos esses números como disponibilidade operacional diária. O ranking municipal é fixo em **dezembro de 2019**, com 7.140 leitos SUS observados.”

“O quadro de observabilidade é independente dos filtros globais. Distingue ausência de linha LT, SUS positivo observado e SUS zero observado. Ausência de registro não significa zero leitos.”

Não selecione 2018 para interpretar o ranking fixo. Se surgir conflito temporal, explique que é necessário limpar o ano; o aviso do gráfico explicita o limite.

---
## Folha 3 — Fluxos e Contexto Territorial
“RES é município de residência; SERV é município de atendimento. Há 294.635 novas internações no mesmo município e 260.454 em município diferente.”

A demonstração mínima começa sem filtros. Se optar por interação, use somente as classes EQ/NE já revisadas, uma de cada vez. Não altere a ordenação durante a apresentação; a inversão foi uma verificação, não uma etapa do roteiro.

**Comunicação obrigatória do limite do filtro:**
“O filtro ‘mesmo município/município diferente’ classifica as internações segundo residência e atendimento. Neste MVP, seu uso fica restrito à análise de fluxo. Antes de consultar leitos ou população, limpo a seleção de fluxo e os demais filtros. Resultados vazios ou zero sob esse filtro não representam capacidade ou população real zero.”

## População — ainda na terceira folha
**Limpe todas as seleções antes de interpretar a tabela de população**, inclusive classe de fluxo, SERV e competência mensal. Confirme isso em Seleções Atuais.

“A tabela apresenta população municipal por ano. Não somamos 2017, 2018 e 2019 como se fossem habitantes distintos. Selecionar município de atendimento não define a população dos municípios de residência dos pacientes atendidos.”

Se houver aviso de SERV, limpe SERV; se houver contexto duvidoso, limpe tudo e retome a leitura do estado neutro. Não apresente a tabela vazia sob EQ/NE como população zero.

## Encerramento
“O trabalho demonstra um protótipo acadêmico descritivo, com três folhas e nove objetos. Indicadores cruzados não apresentados estão justificados no relatório. Os resultados não constituem taxa de ocupação, inferência causal ou homologação de produção.”

## Pendências externas
Este documento não comprova ensaio online ou submissão. Confirmar com o professor a aceitação das fontes em arquivos e de três folhas como três painéis. Conferir a atividade e o prazo no Classroom; após o envio pelo responsável, guardar o comprovante. Não atribuir aceite docente antecipado.
