# Revisão editorial integral do relatório acadêmico — 23/11/2026

## Comentários dos anexos e referência temporal — revisão posterior em 23/11/2026

PDF vigente: `SAD_Data_Mart_SUS_PB_Relatorio_Uniformizado_2026-11-23.pdf`, **85 páginas**, SHA-256 `12744D2312042283CD10A09F651A0D976631E65F80A3170A8FA56AC1ACE738F4`. A pedido do responsável, foram padronizados 74 blocos de comentários nas listagens dos 13 scripts, em português técnico direto. O gerador compara a sequência de todas as linhas executáveis antes/depois e confirma preservação exata. Os QVS de origem continuam intactos; somente a apresentação dos comentários no PDF foi alterada. A explicação de `PERIODO_ANO` foi integrada ao parágrafo de M1-01, removendo a antiga nota editorial sobre a captura. A imagem e o QVW não foram modificados. Executor/conteúdo commitados antes da execução em `90c8fe56d36e65f25de1734823e4a42fd8b86f77`. Conferidos a paginação, os limites do texto, as figuras e as listagens renderizadas. Esta revisão substitui a apresentação de 86 páginas registrada abaixo; não altera os resultados científicos, os tachados, as pendências docentes, o ensaio ou a submissão.

## Objetivo autorizado

Unificar os três padrões de apresentação do PDF, marcar com tachado os indicadores previstos e não implementados por insuficiência de compatibilidade/verificação dos dados e substituir o vocabulário operacional por redação acadêmica natural. Esta revisão não modifica a modelagem aprovada, o QVW, QVDs, medidas, guardas ou associações.

## Fontes e execução

- Main conferida em `5486ad9f50744769e85107132eae009529ac75cc`; esta proposta continua na PR #242 Draft, sem merge.
- PDF de entrada: `SAD_Data_Mart_SUS_PB_DOC_R3_VIS05_Revisado_2026-11-23.pdf`, 98 páginas, SHA-256 `F3F1F5C9F677D6F39C1BA7B24A12E4E1A38C33F1736D381B8173BE32CDF43DB3`.
- Texto dos Capítulos 1–2: drafts acadêmicos canônicos e síntese das relações do PDF. Escopo e conteúdo substantivo preservados.
- Texto editorial dos Capítulos 3–5: `vis05-unified-report-content-2026-11-23.md`.
- Gerador `tools/build_sad_unified_academic_report.py`, executado após versionamento, commit `bc5cf90b7e2620d269137ad5789b21f203fd195b`.
- Ambiente efetivo: sessão Work/Codex, Linux, Python 3.12, ReportLab e PyMuPDF. Nenhum subagente ou sessão Windows/QlikView utilizado. Não foi solicitada configuração alternativa de modelo/esforço.

## Resultado

`SAD_Data_Mart_SUS_PB_Relatorio_Uniformizado_2026-11-23.pdf`, **86 páginas**, SHA-256 `1519E2B2C665FDFCB3B968A3705363F8901FE89123B27F6473B7DCC2B83F433C`.

- Corpo, títulos, tabelas, cabeçalhos e rodapés padronizados; páginas horizontais para figuras largas com o mesmo padrão gráfico. Código monoespaçado nos anexos para legibilidade.
- Sumário com links, em uma página, e numeração iniciada em 1 no primeiro capítulo.
- Tachado nas referências de planejamento aos três indicadores: internações por 1.000 habitantes, leitos SUS por 1.000 habitantes e relação internações/leitos. As definições propostas permanecem legíveis e as justificativas constam do §3.7.
- Medidas e visualizações excluídas apenas por recorte de apresentação não foram classificadas como falhas de dados. Fluxo RES→SERV permanece implementado e sem tachado.
- Jargão interno de auditoria, agentes e estados de aceite substituído por explicações metodológicas. Não se declarou autoria sem assistência nem foram inventadas validações ou aceitações docentes.
- Limites científicos preservados: AIH não é paciente único; ausência LT não é zero; leitos e população são semi-aditivos; RES/SERV distintos; cobertura hospitalar histórica não comprovada para todo o período; indicadores cruzados não implementados; cuidado com filtro de fluxo sobre leitos/população.
- Os 11 elementos visuais foram extraídos das imagens efetivamente exibidas nas páginas de origem. Os pixels foram preservados. A nota de Ano de competência permanece, pois a captura histórica ainda mostra Ano da Internação.
- As 13 listagens dos anexos reproduzem os mesmos Git blobs identificados no PDF de origem, sem alterar instruções ou comentários. Quebras de linhas e numeração são apenas de apresentação.

## Conferência e condição de parada

Conferências do gerador: identidade do PDF de entrada, checkout commitado, 13 blobs dos anexos, 11 figuras, valores numéricos principais preservados, ausência do vocabulário operacional selecionado no texto final, limites geométricos do texto e sumário em uma página. Todas as 86 páginas foram renderizadas e inspecionadas por contato; tachado e seções principais também conferidos em detalhe. O PDF de origem permanece intacto. Miniaturas auxiliares de leitura não constituem nova validação física do SAD.

**Encerrado o escopo editorial**, sem nova recarga, sessão QlikView, alteração de original ou submissão ao professor. Permanecem a revisão final do responsável, confirmação docente sobre fontes em arquivos e três folhas como três painéis, ensaio e submissão. O PDF binário e as imagens de revisão ficam fora do Git. Os registros históricos de auditoria não foram apagados ou reescritos.
