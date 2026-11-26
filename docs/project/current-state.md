# Current State — SAD Data Mart SUS PB

## Estado operacional — 26/11/2026 | implementação acadêmica encerrada, submissão sem comprovante

**Escopo final:** QlikView 12, três folhas/nove visualizações, três fatos e oito dimensões. Auditoria G0–G5 e revisão visual focalizada encerradas nos limites registrados. Não ampliar indicadores nem repetir testes concluídos.

| Frente | Estado vigente e evidência |
| --- | --- |
| Requisitos docentes | Aceite das fontes em arquivos e das três folhas como três painéis informado pelo responsável em 23/11; prazo mantido, sem confirmação docente independente. |
| PDF de entrega | `SAD_Data_Mart_SUS_PB_Relatorio_Final_2026-11-26.pdf`, 86 páginas, SHA-256 `6EAE35E3B366E6FECA65582F4819E0C2F9D356CFD1D2AFB239E51AC1E916389A`, conferido em bytes. Inclui §3.1.1 sobre reprodutibilidade e link ao GitHub. Substitui a versão de 23/11. [Registro da revisão](../academic/vis05-report-reproducibility-addendum-2026-11-26.md). |
| QVW de entrega | `SAD_PB_ANO_COMPETENCIA_CONFERIR.qvw`, SHA-256 local reportado `C78E6DD568ECE7360E985DE2D63D42D70F2EF47D73EA72A555DB3F622F2C0695`. M1-01/CH01 corrigido para Ano de competência; Save e persistência após reabertura reportados, captura revisada. Bytes do QVW não conferidos nesta auditoria. |
| Preservação e filtros | 26 caminhos protegidos antes/depois com hashes e tamanhos idênticos na reconciliação de 23/11; sem Reload. AUD-03/AUD-04 resolvidos nos estados contratados. AUD-10 tratado por regra de uso: limpar seleção de fluxo antes de consultar capacidade/população; vazio/zero não prova zero real. |
| Integração anterior | PRs #243, #244 e #242 integradas em 23/11, verificadas na API do GitHub. |
| Reorganização física | Não necessária à entrega; PR #240 é proposta histórica com inventário de 329 arquivos de 12/11. Não mover scripts nem reabrir a limpeza de branches. |
| Apresentação/ensaio online | Suspensos até nova instrução do responsável. Não são pré-requisitos ativos da submissão documental. |
| Submissão | Não há comprovante registrado. Não declarar entrega efetuada. |

## Referências e limites

- [Registro da entrega](../academic/final-delivery-record-2026-11-10.md), [requisitos](../academic/requirements.md) e [revisão editorial de 23/11](../academic/vis05-unified-report-closeout-2026-11-23.md) (histórico).
- [Auditoria de alinhamento do repositório](repository-final-alignment-2026-11-26.md), [inspeção VIS-05](sad-vis05-readonly-inspection-gate-2026-11-15.md), [correção M1-01](sad-m1-temporal-label-automation-2026-11-23.md) e [política de artefatos](artifact-recovery-policy.md).
- Modelo, originais, medidas e arquitetura preservados. Indicadores cruzados não implementados; cobertura hospitalar histórica CNES/LT não comprovada para todo o período. T29, C2/C3/C4 globais, Fase IX e produção não aprovados/autorizados. Ausência LT não equivale a zero; leitos/população são semi-aditivos e RES/SERV são papéis distintos.

## Próximos passos e STOP

1. Guardar a versão do PDF de 26/11, o QVW corrigido e as evidências em armazenamento persistente; conferir hashes e os arquivos exigidos.
2. Integrar a consolidação documental somente após autorização específica e conferência da branch/PR.
3. Submeter pelo meio e prazo acordados; guardar comprovante e registrar a submissão para encerramento definitivo.

**STOP:** não iniciar novos indicadores, testes numéricos, recarga, sessão QlikView, mudança de modelo ou limpeza física. Não reativar apresentação/ensaio sem nova instrução. O histórico permanece nos registros datados; este snapshot governa o estado vigente.
