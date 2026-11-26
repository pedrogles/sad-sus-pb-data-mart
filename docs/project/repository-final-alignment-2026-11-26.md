# Auditoria de alinhamento documental do repositório — 26/11/2026

## Contrato

Objetivo: reconciliar README, estado operacional, identidade da entrega e situação dos PRs/issues; mapear diretórios sem migração. Base: `main@8bace492ef352b64afb8036a1437b8e8d3100e03`. Fontes consultadas na ordem AGENTS.md, current-state.md, requirements.md, seguidas de README, .gitignore, registros acadêmicos, política de artefatos, fonte editorial, integração de 23/11, inventário Git e PR #240. Ambiente: ChatGPT com conector GitHub e inspeção local somente leitura dos dois PDFs. Sem execução QlikView, alteração de QVS/arquitetura, publicação de binários, merge ou exclusão de branches.

## Inventário e estado verificado

Árvore recursiva Git não truncada: 362 blobs na baseline. 182 em docs, 135 em tools, 27 em TRANSFORMACAO, 8 em PAINEL, 6 em EXTRACAO e 4 na raiz. Sem arquivos rastreados com extensões QVW, QVD, PDF, ZIP, DBC, DBF ou XLSX na árvore consultada. BASE é local, não uma pasta rastreada nessa árvore.

66 branches remotas na coleta anterior à consolidação. Zero issues abertas independentes; uma PR aberta (#240, Draft). A listagem de issues inclui a PR. PRs #243, #244 e #242 fechadas com merge confirmado em 23/11, respectivamente em `f0068b1d480570a19a01bab0f9dd614ae1412f01`, `1c98309a3a0af39c720430fe033fb8aee591f045` e `8bace492ef352b64afb8036a1437b8e8d3100e03`. Nenhum status de commit reportado na consulta; isso não é PASS de CI. Não há workflow versionado na árvore consultada; a consulta direta da lista de workflows não foi suportada pelo conector. Não se auditou a configuração administrativa de segurança nem o conteúdo semântico integral de todos os 362 blobs.

## Achados e tratamento

| Achado | Tratamento |
| --- | --- |
| README antigo de 98 páginas, pendências docentes e ensaio obsoletos | Substituição por mapa enxuto: objetivo, arquitetura, diretórios, resultado e links canônicos. |
| current-state.md com PDF de 23/11 e merges pendentes | Atualização para PDF de 26/11 e merges efetivamente realizados, sem declarar submissão. |
| Registro de entrega com estados históricos contraditórios | Adendo vigente no topo; histórico preservado. |
| Fonte editorial de 23/11 sem §3.1.1 | Novo adendo de 26/11 com delta textual exato, identidade e QA; não reescrever fonte histórica nem alegar reprodução byte a byte. |
| Política de não versionar PDF de entrega sem regra específica de ignore | Acrescentar padrões restritos aos nomes de relatórios e pasta de entrega, mantendo demais regras. |
| #240 inventário desatualizado | Compare remoto: 2 commits à frente, 71 atrás; dois documentos novos, nenhuma movimentação. Inventário 329 vs 362 atuais. Proposta histórica não necessária ao fechamento acadêmico. Recomendada sua retirada do backlog, preservando branch e histórico, sem merge. |

## Critérios de encerramento

PASS documental se o diff da consolidação for limitado ao README, estado, registro de entrega, adendo editorial, este registro e ignore específico de artefatos; os demais blobs permanecem idênticos. Confirmar PR e sua base/head e deixar integração para autorização específica. A auditoria não equivale a nova aprovação física, científica, de produção ou submissão. Os arquivos e branches históricos não são lixo comprovado por seu nome; manter o fechamento conservador anterior. Não iniciar migração estrutural ou investigação adicional sem objetivo independente.
