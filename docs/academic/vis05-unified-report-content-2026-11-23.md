# 3 IMPLEMENTAÇÃO

## 3.1 Solução de BI e organização dos dados

O projeto foi implementado no QlikView 12, com dados do SIH/SUS, do CNES e do IBGE/SIDRA. A organização segue o fluxo BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL. Os arquivos QVD armazenam os dados extraídos e transformados antes de sua utilização na interface de análise.

O modelo reúne três tabelas fato: FATO_INTERNACAO, FATO_CAPACIDADE_LEITO e FATO_POPULACAO. As oito dimensões apresentadas no Capítulo 2 fornecem o contexto das consultas. Cada fato mantém sua granularidade, e os municípios de residência e de atendimento são tratados como papéis distintos.

A interface acadêmica foi organizada em três folhas, com nove visualizações. Os resultados apresentados descrevem os registros disponíveis entre 2017 e 2019 e devem ser interpretados de acordo com a origem, o período e a unidade de cada informação.

| Folha | Visualizações | Fonte |
|---|---|---|
| Produção Hospitalar | M1-01 a M1-03 | SIH/SUS - RD |
| Leitos Cadastrais Observados | M2-01 a M2-03 | CNES - LT |
| Fluxos e Contexto Territorial | M3-01 a M3-03 | SIH/SUS - RD e IBGE |

## 3.2 Produção Hospitalar

A primeira folha apresenta o volume de novas internações administrativas por competência. Registros de continuidade, identificados por IDENT=5, não são contados como novas internações. A medida não representa pacientes únicos nem toda a necessidade de atendimento da população.

@FIGURE:7

**M1-01 - Novas internações por ano de competência.** Foram registradas 183.532 novas internações em 2017, 183.311 em 2018 e 188.246 em 2019, totalizando 555.089 no triênio. A referência temporal é a competência administrativa do SIH/RD, representada por PERIODO_ANO.

**Nota sobre o eixo da Figura 7.** O rótulo “Ano da Internação”, presente na captura, deve ser lido como “Ano de competência”. A imagem foi preservada como registro da interface utilizada; essa correção de nomenclatura não modifica os valores ou a agregação.

**M1-02 - Evolução mensal.** A série reúne 36 competências, de janeiro de 2017 a dezembro de 2019. As oscilações descrevem o volume registrado, sem estabelecer suas causas.

**M1-03 - Distribuição por município de atendimento.** O ranking utiliza o município em que o atendimento ocorreu (SERV). Esse recorte é diferente do município de residência do paciente (RES).

## 3.3 Leitos Cadastrais Observados

A segunda folha apresenta a capacidade registrada no CNES/LT e a presença de observações por município e competência. Esses dados representam o cadastro mensal de leitos, e não sua disponibilidade operacional em tempo real.

@FIGURE:8

**M2-01 - Leitos cadastrados por competência.** As séries distinguem leitos SUS e leitos existentes. Como se trata de estoque mensal, os valores de meses consecutivos não devem ser somados para obter a capacidade anual.

**M2-02 - Leitos SUS por município.** O ranking utiliza a competência fixa de dezembro de 2019 (201912), na qual foram observados 7.140 leitos SUS. Uma seleção temporal incompatível impede a apresentação do ranking e exibe uma mensagem explicativa. A ausência de registro não significa quantidade real de leitos igual a zero.

**M2-03 - Presença de registros por município e competência.** O gráfico reúne 8.028 combinações de município e mês: 4.467 sem registro LT, 3.464 com quantidade SUS positiva e 97 com quantidade SUS igual a zero. Essas contagens se referem a combinações de município e competência, e não a municípios distintos.

O M2-03 utiliza uma tabela auxiliar independente dos filtros globais, mantendo uma visão fixa da Paraíba entre 2017 e 2019. Essa tabela não acrescenta um quarto processo factual ao modelo. A ausência de linha LT e a existência de uma linha com zero leitos SUS são situações diferentes.

O cadastro LT pode conter estabelecimentos com leitos que não pertencem a uma classificação estritamente hospitalar. A aplicação dessa classificação a todo o período exigiria comprovação histórica que não foi concluída neste trabalho. Por isso, os resultados são apresentados como capacidade cadastral observada.

## 3.4 Fluxos e Contexto Territorial

A terceira folha relaciona o município de residência ao município de atendimento e apresenta, separadamente, as estimativas populacionais municipais.

@FIGURE:9

**M3-01 - Residência e atendimento.** No período analisado, 294.635 novas internações ocorreram no mesmo município de residência e 260.454 em município diferente. A soma corresponde às 555.089 novas internações do triênio. A comparação descreve deslocamentos registrados, sem medir a qualidade da assistência ou comprovar acesso adequado aos serviços.

Na revisão da interface, a correspondência entre categoria, rótulo e valor foi observada nas seleções de mesmo município e município diferente e após a inversão da ordenação. Essa conferência se refere às situações examinadas.

**M3-02 - Pares residência → atendimento.** A tabela mantém a direção entre a origem residencial e o local do atendimento. Registros de residentes de outros estados são preservados e não recebem, artificialmente, população de municípios paraibanos.

**M3-03 - População municipal por ano.** A tabela apresenta estimativas anuais do IBGE. Para 2019, a soma das estimativas dos municípios paraibanos é de 4.018.127 habitantes. Valores de anos diferentes não devem ser somados como se representassem pessoas distintas.

## 3.5 Seleções e cuidados de interpretação

Os filtros precisam respeitar o período e o significado territorial de cada informação. O ranking de leitos de dezembro de 2019 não descreve outro ano, e o município de atendimento não substitui o município de residência em uma análise populacional.

@FIGURE:10

A mensagem do M2-02 esclarece a referência fixa do ranking e informa que a ausência de dados na seleção não corresponde a zero leitos. A mesma incompatibilidade foi observada com o ano de 2018 selecionado.

@FIGURE:11

O M3-03 informa a incompatibilidade entre população anual e seleção de competência mensal. Com SERV_COD_DATASUS_6=250750, a interface também orienta limpar o filtro de atendimento para consultar a população municipal, pois o local do serviço não representa a residência de todos os pacientes atendidos.

**Uso do filtro de fluxo.** As opções “Mesmo Município” e “Município Diferente” devem ser usadas na análise das internações e dos pares de fluxo. Nessas seleções, a tabela de população pode ficar vazia e a consulta de capacidade pode retornar zero em razão do efeito do filtro sobre os diferentes fatos. Esses resultados não demonstram ausência real de população ou de leitos, nem comprovam erro cadastral.

Antes de apresentar leitos ou população, deve-se limpar a seleção de fluxo e conferir as seleções atuais. Para a população, também é necessário retirar o filtro SERV; para o ranking de leitos, deve-se respeitar a referência de dezembro de 2019. O M2-03 permanece independente dos filtros globais.

## 3.6 Síntese da implementação

As nove visualizações permitem descrever a produção hospitalar, a capacidade cadastral de leitos, os registros disponíveis no CNES, os fluxos entre municípios e a população estimada. As conferências de valores e de apresentação foram realizadas em situações definidas de seleção. Elas não permitem afirmar que todas as combinações possíveis de filtros produzam análises equivalentes entre os três fatos.

A solução apresentada tem finalidade acadêmica e descritiva. Não calcula ocupação hospitalar, não estima demanda reprimida e não demonstra relação causal entre população, leitos e internações.

## 3.7 Indicadores previstos e não implementados

Os três indicadores abaixo foram previstos na modelagem, mas não integram as visualizações finais. O tachado identifica essa diferença entre o planejamento e o resultado implementado. As razões envolvem a compatibilidade entre fontes e a comprovação das associações necessárias; não se trata de inexistência de todos os dados ou de impossibilidade matemática de calcular as razões.

**~~Internações por 1.000 habitantes~~.** O cálculo depende de relacionar as internações de residentes à população do mesmo município e ano. A correspondência entre fatos e o comportamento dos filtros não foram verificados de forma suficiente para apresentar esse indicador.

**~~Leitos SUS por 1.000 habitantes~~.** O cálculo exige capacidade média mensal e população anual compatíveis no mesmo município. Também depende de uma delimitação histórica da cobertura hospitalar do CNES/LT, ainda não estabelecida para todo o período.

**~~Relação entre internações e leitos~~.** A comparação reúne um fluxo de registros administrativos e um estoque cadastral. A compatibilidade do período, do papel municipal e do denominador não foi demonstrada de forma suficiente. Mesmo calculada, essa razão não corresponderia à taxa de ocupação hospitalar.

Os indicadores permanecem descritos no Capítulo 2, com tachado, para registrar o que foi proposto e o que não foi implementado. O fluxo entre residência e atendimento foi implementado nos objetos M3-01 e M3-02 e não recebe essa marcação.

# 4 CONSIDERAÇÕES FINAIS

O trabalho desenvolveu uma proposta de Data Mart para análise da demanda hospitalar, da capacidade cadastral de leitos e da população do SUS na Paraíba, no período de 2017 a 2019. A modelagem foi organizada em três tabelas fato e oito dimensões, respeitando as diferentes granularidades e os papéis dos municípios de residência e de atendimento.

A implementação no QlikView 12 resultou em três folhas e nove visualizações. Foram apresentados o volume de novas internações, a evolução mensal dos registros, a distribuição por município de atendimento, os leitos cadastrados, a presença de observações no CNES, os fluxos territoriais e as estimativas populacionais anuais.

Entre os resultados apresentados estão 555.089 novas internações administrativas no triênio, 7.140 leitos SUS observados em dezembro de 2019 e 4.018.127 habitantes na soma das estimativas municipais de 2019. Cada valor se refere ao seu próprio período e universo; eles não constituem, isoladamente, indicadores de suficiência da rede assistencial.

A análise exige alguns cuidados. Uma AIH não representa necessariamente um paciente único. Leitos e população não devem ser acumulados entre períodos como medidas de fluxo. A ausência de registro não equivale a zero, e residência e atendimento não são recortes intercambiáveis. Além disso, os indicadores que cruzariam os três processos não foram implementados, pelas limitações descritas na seção 3.7.

O projeto demonstra a aplicação da modelagem dimensional e de uma ferramenta de BI a dados públicos de saúde. Sua contribuição está na organização das fontes e na apresentação de informações descritivas com recortes explícitos, preservando os limites de interpretação dos dados.

## 4.1 Delimitação dos resultados

As tabelas fato também contêm medidas como quantidade de registros AIH, dias de permanência, valor total, indicador de óbito e leitos não SUS, que não foram escolhidas como medidas diretas das nove visualizações. Essa escolha de escopo não significa que esses campos sejam inválidos ou que tenham sido retirados do modelo.

Também não foram apresentados rankings específicos de procedimentos e diagnósticos, composição SUS/não SUS ou detalhamento de leitos por estabelecimento e tipo. Essas ausências decorrem do recorte de apresentação e não são marcadas como falhas de dados. A interface final se limita às três folhas descritas neste relatório.

# 5 REFERÊNCIAS BIBLIOGRÁFICAS

BRASIL. Ministério da Saúde. Departamento de Informação e Informática do SUS (DATASUS). Informações de Saúde (TABNET). Disponível em: https://datasus.saude.gov.br/informacoes-de-saude-tabnet/. Acesso em: 9 nov. 2026.

BRASIL. Ministério da Saúde. Departamento de Informação e Informática do SUS. Sistema de Informações Hospitalares do SUS (SIH/SUS): documentação. Disponível em: https://wiki.saude.gov.br/sih/index.php/P%C3%A1gina_principal. Acesso em: 9 nov. 2026.

BRASIL. Ministério da Saúde. Como acessar o Cadastro Nacional de Estabelecimentos de Saúde (CNES)? 2021. Disponível em: https://www.gov.br/saude/pt-br/acesso-a-informacao/faq/estabelecimentos-de-saude/como-acessar-o-cadastro-nacional. Acesso em: 9 nov. 2026.

IBGE. Instituto Brasileiro de Geografia e Estatística. Estimativas da população residente para os municípios e para as unidades da federação. Disponível em: https://www.ibge.gov.br/estatisticas/sociais/populacao/9103. Acesso em: 9 nov. 2026.

IBGE. Instituto Brasileiro de Geografia e Estatística. IBGE divulga as estimativas da população dos municípios para 2019. 28 ago. 2019. Disponível em: https://agenciadenoticias.ibge.gov.br/agencia-sala-de-imprensa/2013-agencia-de-noticias/releases/25278-ibge-divulga-as-estimativas-da-populacao-dos-municipios-para-2019. Acesso em: 9 nov. 2026.

QLIK. Arquivos QVD. Ajuda do QlikView, versão setembro de 2026. Disponível em: https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/QVD_files.htm. Acesso em: 9 nov. 2026.

UNIESP. MEDEIROS, Fábio Nicácio de. Roteiro para o projeto: Sistemas de Apoio à Decisão. Sistemas de Informação, semestre 2026.2. Material didático fornecido aos estudantes.
