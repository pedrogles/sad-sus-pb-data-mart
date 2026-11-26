# Adendo editorial — disponibilidade e reprodutibilidade (26/11/2026)

## Identificação e escopo

- Entrada: `SAD_Data_Mart_SUS_PB_Relatorio_Uniformizado_2026-11-23.pdf`, 86 páginas, SHA-256 `C74342B1B5A19885D5F406E71A5D7C443292F016048E57E2FFE1D747DA9DF1CB`.
- Saída vigente: `SAD_Data_Mart_SUS_PB_Relatorio_Final_2026-11-26.pdf`, 86 páginas, 2.448.964 bytes, SHA-256 `6EAE35E3B366E6FECA65582F4819E0C2F9D356CFD1D2AFB239E51AC1E916389A`.
- Os dois arquivos foram conferidos diretamente em bytes durante a auditoria de 26/11. A comparação por rasterização PyMuPDF (matriz 1×1) identificou diferenças somente nas páginas físicas 2 (sumário) e 25 (página numerada 23). As outras 84 páginas foram iguais nessa renderização. A extração confirmou §3.1.1 e o destino do hyperlink do repositório. A ordem visual coloca a nota antes de §3.2.
- Não houve alteração dos QVS, QVW, QVDs, dados, medidas, modelagem, gráficos ou resultados. Não houve Reload, execução de QlikView ou nova homologação.

## Delta editorial sobre a fonte de 23/11

A fonte [vis05-unified-report-content-2026-11-23.md](vis05-unified-report-content-2026-11-23.md) e o gerador original permanecem históricos e preservados. Inserir, na seção 3.1 e antes de 3.2, o texto abaixo, com a entrada 3.1.1 correspondente no sumário (página 23). Este registro documenta o delta da revisão realizada no PDF; não é um novo gerador nem comprova que o gerador anterior reproduza byte a byte a versão de 26/11.

### 3.1.1 Disponibilidade e reprodutibilidade do projeto

Os scripts apresentados nos Anexos I e II correspondem às rotinas de transformação das dimensões e tabelas fato do Data Mart. Sua execução depende da estrutura de diretórios, dos arquivos de origem, dos arquivos QVD intermediários, dos marcadores de controle e dos modos de execução previstos. Os anexos, isoladamente, não permitem reconstruir integralmente a solução, incluindo a camada associativa e as configurações dos painéis no QlikView 12.

O código-fonte versionável, os scripts auxiliares, as rotinas de automação e a documentação técnica são mantidos no repositório GitHub do projeto. Os arquivos de dados e os artefatos binários do QlikView devem ser preservados separadamente. A reprodução do ambiente depende da disponibilidade dessas dependências e das instruções de execução.

Repositório: https://github.com/pedrogles/sad-sus-pb-data-mart

## Guarda e STOP

Preservar o PDF vigente e o QVW corrigido externamente, com cópia persistente e hash. O repositório é público conforme metadados GitHub, mas não se comprova aqui acesso de pessoa específica ou submissão acadêmica. A revisão editorial não autoriza alterações físicas nem amplia o escopo de implementação.
