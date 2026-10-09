# BOUNDARY 7 — Plano de Implementação

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** DATA ACQUISITION / QLIKVIEW IMPLEMENTATION DISCOVERY  
**Ferramenta obrigatória:** QlikView 12  
**Data de fechamento:** 07/10/2026  
**Status:** CONCLUÍDO

## 1. Objetivo

Transformar a arquitetura física aprovada no Boundary 6 em um plano executável de implementação, sem iniciar ainda a implementação definitiva.

Este boundary fecha:

1. estrutura de diretórios e artefatos;
2. ferramenta e fluxo de conversão DBC;
3. sequência de execução;
4. contratos de entrada e saída;
5. regras de chave;
6. construção da `LINK_ANALISE`;
7. ordem de geração das dimensões e fatos;
8. tratamento de erro;
9. logging e rastreabilidade;
10. estratégia de reexecução;
11. matriz de reconciliação;
12. checklist objetivo para o Boundary 8 — Readiness.

Não altera os Capítulos 1 e 2 nem a arquitetura dimensional aprovada.

---

## 2. Fontes de verdade consultadas

### Repositório

- `AGENTS.md`;
- `docs/project/current-state.md`;
- `docs/academic/requirements.md`;
- `docs/discovery/boundary-3-full-dataset-validation.md`;
- `docs/discovery/boundary-4-auxiliary-references.md`;
- `docs/discovery/boundary-5-historization-role-playing.md`;
- `docs/discovery/boundary-6-qlikview-physical-architecture.md`.

### Material da disciplina

Permanece obrigatório o fluxo:

```text
BASE
  ↓
EXTRACAO / EXT.qvw
  ↓
QVD
  ↓
TRANSFORMACAO / TRANSF.qvw
  ↓
QVD
  ↓
PAINEL / PAINEL.qvw
```

### Referências técnicas adicionais

QlikView:

- execução em linha de comando:  
  https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Starting_QlikView.htm
- execução em lote:  
  https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/BatchExecution.htm
- ErrorMode:  
  https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/ErrorVariables/ErrorMode.htm
- ScriptError / ScriptErrorCount:  
  https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Scripting/ErrorVariables/ErrorVariables.htm
- FileList / For Each:  
  https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Scripting/ScriptControlStatements/For%20Each.htm

DBC:

- `dbc-to-dbf` 1.0.1 — implementação Python pura baseada no algoritmo BLAST:  
  https://pypi.org/project/dbc-to-dbf/
- `dbfread` 2.0.7 — leitura DBF em Python:  
  https://pypi.org/project/dbfread/

---

# 3. Estado de entrada

### FATO VERIFICADO

O projeto já possui:

- 36 competências RD;
- 36 competências LT;
- 36 competências ST;
- 108/108 DBCs validados;
- arquitetura dimensional fechada;
- Link Table aprovada;
- historização mensal de estabelecimento aprovada;
- papéis de Tempo e Município aprovados;
- referências auxiliares principais identificadas.

### Restrições preservadas

Não:

- fundir academicamente as três fatos;
- mudar granularidades;
- substituir Star Schema;
- aplicar atributos atuais ao passado;
- fabricar código IBGE;
- usar `N_AIH` como PK;
- somar snapshots de leito/população como medidas aditivas;
- chamar internações/leito de taxa de ocupação.

---

# 4. Estrutura física planejada

A implementação local seguirá a estrutura didática do professor.

```text
BASE/
    DBC/
        RD/
        LT/
        ST/
    IBGE/
    REFERENCIAS/
    CONVERTIDA/
        RD/
        LT/
        ST/
        manifest/

EXTRACAO/
    EXT.qvw
    ext_main.qvs
    QVD/

TRANSFORMACAO/
    TRANSF.qvw
    transf_main.qvs
    QVD/

PAINEL/
    PAINEL.qvw
    painel_main.qvs

tools/
    dbc_to_csv.py
    requirements-tools.txt
    run_pipeline.cmd
```

### Classificação

- `BASE/DBC`: fonte bruta imutável;
- `BASE/IBGE`: arquivos anuais oficiais;
- `BASE/REFERENCIAS`: SIGTAP/CID/CNES/domínios oficiais;
- `BASE/CONVERTIDA`: artefato derivado, regenerável;
- `EXTRACAO/QVD`: staging;
- `TRANSFORMACAO/QVD`: Data Mart físico;
- `PAINEL`: apresentação;
- `tools`: somente utilitários técnicos necessários para reprodução.

### Git

Dados brutos, CSVs derivados e QVDs não serão versionados.

Scripts e documentação serão versionados.

Os QVW não serão a única fonte de verdade. A decisão sobre versionar ou entregar os binários QVW será tomada após medir tamanho e necessidade acadêmica; seus scripts permanecerão em `.qvs`.

### Drift conhecido de `.gitignore`

O `.gitignore` atual contém caminhos `data/raw`, `data/staging` e `data/qvd` herdados de uma organização anterior.

A implementação deverá alinhar o `.gitignore` à estrutura BASE/EXTRACAO/TRANSFORMACAO sem manter duas arquiteturas paralelas.

Esse ajuste deverá ocorrer somente quando os diretórios forem realmente materializados.

---

# 5. Conversão DBC — decisão concreta

## 5.1 Problema

QlikView lê diretamente formatos de tabela como texto delimitado, Excel, XML, QVD/QVX etc., mas DBC não é um formato de tabela nativo do LOAD.

A simples descompressão DBC → DBF não resolve sozinha o carregamento por arquivo de tabela.

## 5.2 Decisão

O pré-processamento será:

```text
DBC
 ↓
DBF temporário
 ↓
CSV UTF-8
 ↓
EXT.qvw
```

### Ferramentas planejadas

`requirements-tools.txt`:

```text
dbc-to-dbf==1.0.1
dbfread==2.0.7
```

### Motivo da escolha

- Python puro;
- compatível com o algoritmo BLAST usado pelo ecossistema DATASUS;
- evita introduzir R apenas para a conversão;
- evita depender de driver ODBC dBase;
- gera formato texto diretamente legível pelo QlikView;
- comportamento pode ser testado contra os 108 DBCs já validados no Boundary 3.

### Gate

A escolha só se torna operacionalmente aprovada após o Boundary 8 reproduzir, em área temporária, os controles do Boundary 3.

Se houver divergência de registros/schema, a implementação não começa.

---

# 6. Contrato do conversor `tools/dbc_to_csv.py`

## Entrada

- diretório com DBCs;
- diretório de saída;
- fonte esperada: RD, LT ou ST.

## Saída por arquivo

Para cada:

`RDPB1701.dbc`

gerar:

`RDPB1701.csv`

O CSV será:

- UTF-8;
- delimitador `;`;
- cabeçalho obrigatório;
- quoting padrão CSV;
- sem formatação dependente da localidade do Windows.

## Manifesto

Gerar:

`BASE/CONVERTIDA/manifest/dbc-conversion-manifest.csv`

Campos mínimos:

- `source_family`;
- `input_file`;
- `input_sha256`;
- `input_size_bytes`;
- `output_file`;
- `output_sha256`;
- `record_count`;
- `field_count`;
- `field_names_signature`;
- `converted_at`;
- `status`.

### Regra

O manifesto é artefato operacional derivado, não fonte de verdade acadêmica.

---

# 7. Regras de conversão

### Fail-fast

A conversão deve retornar código diferente de zero quando:

- DBC não puder ser descompactado;
- DBF temporário não puder ser lido;
- quantidade de registros não puder ser obtida;
- arquivo CSV não puder ser gravado;
- schema estiver vazio;
- ocorrer erro de encoding não tratado.

### Imutabilidade

Nunca modificar o DBC de entrada.

### Temporário

O DBF intermediário poderá ser removido após a geração e validação do CSV.

### Rastreabilidade

Preservar:

- nome original;
- SHA-256 de entrada;
- família RD/LT/ST;
- competência derivada do nome;
- contagem;
- schema.

### Idempotência

Uma reexecução deve produzir o mesmo conteúdo lógico a partir do mesmo DBC e da mesma versão das dependências.

Nenhum arquivo existente será tratado como válido apenas por existir; o manifesto/hash deve corresponder.

---

# 8. Gate de conversão integral

Antes de `EXT.qvw`, o pré-processamento deve reconciliar:

| Fonte | Arquivos | Registros esperados |
|---|---:|---:|
| RD | 36 | 566.672 |
| LT | 36 | 35.518 |
| ST | 36 | 220.390 |

Schemas esperados:

- RD: 113 campos em 36/36;
- LT: 28 campos em 36/36;
- ST: 201 campos em 35/36;
- ST 2019-12: 208 campos.

Se não reconciliar, parar.

---

# 9. EXTRAÇÃO — `EXT.qvw`

## Arquivos

- `EXTRACAO/EXT.qvw`;
- `EXTRACAO/ext_main.qvs`.

O QVW terá como script mínimo:

```text
$(Must_Include=ext_main.qvs);
```

O caminho final será validado em Windows/QlikView no Boundary 8.

## Responsabilidades

`EXT.qvw` deve:

1. carregar CSVs RD;
2. carregar CSVs LT;
3. carregar CSVs ST;
4. carregar arquivos IBGE;
5. carregar referências auxiliares materializadas;
6. aplicar somente normalizações de staging;
7. adicionar metadados de origem;
8. armazenar QVDs de staging.

Não construir fatos/dimensões nesta etapa.

---

# 10. QVDs de staging planejados

Obrigatórios:

- `SRC_SIH_RD.qvd`;
- `SRC_CNES_LT.qvd`;
- `SRC_CNES_ST.qvd`;
- `SRC_IBGE_POPULACAO.qvd`.

Auxiliares quando materializados:

- `REF_SIGTAP.qvd`;
- `REF_CID10.qvd`;
- `REF_CARATER_ATENDIMENTO.qvd`;
- `REF_MOTIVO_SAIDA.qvd`;
- `REF_TIPO_LEITO.qvd`;
- referência municipal oficial DATASUS ↔ IBGE;
- referência histórica adicional de estabelecimento, quando aplicável.

Nomes de campos das referências auxiliares não serão inventados neste plano; serão definidos a partir dos arquivos oficiais efetivamente materializados.

---

# 11. Metadados mínimos de staging

Cada linha carregada de arquivo deverá preservar quando aplicável:

- arquivo de origem;
- família de origem;
- competência de origem;
- caminho lógico/origem de lote quando útil à auditoria.

QlikView dispõe de funções como `FileName()`, `FileBaseName()`, `FilePath()`, `FileSize()` e `FileTime()`.

A competência deve ser validada contra os campos internos quando eles existirem; o nome do arquivo não substitui a validação.

---

# 12. Contratos de schema na extração

## RD

Usar os campos aprovados e necessários à implementação, incluindo os já validados no projeto.

Não depender de posição ordinal.

## LT

Selecionar explicitamente os campos aprovados, incluindo:

- `CNES`;
- `CODUFMUN`;
- `TP_LEITO`;
- `CODLEITO`;
- `QT_EXIST`;
- `QT_SUS`;
- `QT_NSUS`;
- `COMPETEN`.

## ST

Selecionar explicitamente:

- `CNES`;
- `CODUFMUN`;
- `COD_CEP`;
- `CNPJ_MAN`;
- `VINC_SUS`;
- `TPGESTAO`;
- `TP_UNID`;
- `NATUREZA`;
- `NAT_JUR`;
- `COMPETEN`.

### Regra

Não usar `LOAD *` como contrato de schema para ST.

Campos adicionais de `STPB1912` devem ser ignorados até decisão explícita.

Campo obrigatório ausente = falha de carga.

---

# 13. TRANSFORMAÇÃO — `TRANSF.qvw`

## Arquivos

- `TRANSFORMACAO/TRANSF.qvw`;
- `TRANSFORMACAO/transf_main.qvs`.

## Ordem lógica

1. carregar staging;
2. construir referências e mapeamentos;
3. construir `DIM_TEMPO`;
4. construir `DIM_MUNICIPIO`;
5. construir `DIM_ESTABELECIMENTO`;
6. construir dimensões de domínio;
7. construir `FATO_INTERNACAO`;
8. construir `FATO_CAPACIDADE_LEITO`;
9. construir `FATO_POPULACAO`;
10. construir `LINK_ANALISE`;
11. executar controles de reconciliação;
12. armazenar QVDs finais;
13. remover tabelas temporárias da memória.

---

# 14. Convenção de chave determinística

Campos técnicos persistidos usam `Hash128`.

## Município

Base canônica:

`COD_DATASUS_6`

Regra conceitual:

`%SK_MUNICIPIO = Hash128('MUN', COD_DATASUS_6)`

Para população IBGE, o código IBGE deve primeiro ser relacionado ao código DATASUS por referência oficial validada.

Não derivar o sétimo dígito.

## Estabelecimento

`%SK_ESTABELECIMENTO = Hash128('ESTAB', CNES, COMPETENCIA)`

## Tempo — competência

`%SK_TEMPO_COMPETENCIA = Hash128('MES', AAAAMM)`

## Tempo — ano

`%SK_TEMPO_ANO = Hash128('ANO', AAAA)`

## Tempo — data

`%SK_TEMPO_DATA = Hash128('DATA', AAAAMMDD)`

As aliases de internação e saída usarão a mesma base de data, mas nomes físicos de chave distintos no painel.

## Procedimento

Como a referência SIGTAP é competência-aware:

`%SK_PROCEDIMENTO = Hash128('PROC', PROC_REA, COMPETENCIA_REFERENCIA)`

Isso preserva a versão histórica da referência sem alterar a dimensão acadêmica.

## Diagnóstico

`%SK_DIAGNOSTICO = Hash128('CID10', DIAG_PRINC_NORMALIZADO)`

A regra exata de normalização será fechada somente depois do teste empírico contra a referência oficial.

## Caráter

`%SK_CARATER_ATENDIMENTO = Hash128('CAR', CAR_INT)`

## Motivo de saída

`%SK_MOTIVO_SAIDA = Hash128('MOT', COBRANCA)`

## Tipo/leito

Enquanto a invariância histórica não estiver comprovada:

`%SK_TIPO_LEITO = Hash128('LEITO', TP_LEITO, CODLEITO, COMPETENCIA_REFERENCIA)`

Isso impede aplicar classificação posterior retroativamente.

### Adendo A2 — decisão explícita aprovada em 09/10/2026 (não implementada)

**Mudança semântica autorizada pelo responsável:** exclusivamente para a geração de `%SK_TIPO_LEITO`, o argumento `COMPETENCIA_REFERENCIA` significa **competência da observação no CNES/LT (`COMPETEN`)**, e NÃO competência do catálogo de descrições. A expressão `Hash128('LEITO', TP_LEITO, CODLEITO, COMPETENCIA_REFERENCIA)` é **preservada literalmente**, com sensibilidade temporal. Não reinterpretar `COMPETENCIA_REFERENCIA` de `DIM_PROCEDIMENTO` ou outras tabelas.

**Grão aprovado:** uma ocorrência de `(TP_LEITO_normalizado, CODLEITO_textual, COMPETEN)` por competência observada (A1: 2.021 combinações distintas; 36 competências). O argumento `TP_LEITO` passado ao Hash128 deverá ser uma versão **textual normalizada pela remoção somente de espaços ASCII finais** do campo fonte `"N "`; conservar o valor bruto para auditoria. O código `CODLEITO` deve permanecer textual de dois dígitos e a competência da chave deve ser `COMPETEN` do próprio LT; não converter numericamente, não corrigir `3/66` para `2/66`, nem realizar `Trim` genérico silencioso.

**Política temporal de rótulos aprovada:** `201909` é proveniência **apenas da legenda descritiva** `REF_TIPO_LEITO`, independente da competência da SK. Somente combinações com `COMPETEN=201909` e cobertura confirmada do par `TP_LEITO+CODLEITO` poderão receber descrições da legenda daquele mês. As demais competências **não** herdam descrições: atributos de nome do tipo e descrição/especialidade de leito ficam `NULL` quando não há fonte mensal aplicável, sem preencher valor falso nem confundir `NULL` com categoria inexistente. Preservar colunas de códigos para análises e rastrear o escopo de validade do rótulo sem criar associação Qlik indevida pelo nome dos campos.

**Relação com o fato:** `FATO_CAPACIDADE_LEITO` mantém o grão `(CNES, COMPETEN, CODLEITO)`; cada uma das 35.518 linhas LT terá exatamente uma chave dimensional por `(TP_LEITO_normalizado, CODLEITO_textual, COMPETEN)` quando a dimensão for implementada. O preflight A1 verificou grão/cobertura naturais e zero duplicatas na chave candidata de fato, **não** executou `Hash128` nem gerou QVD. A legenda `201909` e `SCNES_DOMINIOS.ZIP` **não** provam validade normativa de 2017–2019; o ZIP possui códigos/tipos separados, sem associação oficial no mesmo registro.

**Gate de implementação separado:** antes de PASS físico QlikView 12, verificar coerência do mapeamento de campos de staging, diferença bruto/normalizado, 2.021 SK distintas/0 colisões e duplicatas, 35.518/35.518 linhas LT com uma SK/0 unmatched/sem multiplicação, 56 combinações `201909` com rótulos daquele snapshot e 1.965 combinações de outros meses sem descrição histórica comprovada e mantidas `NULL`; regressão de `3/66` (1.480) e `7/70` (5). Submeter resultado a revisão antes de integrar `main`. Não implementar automaticamente fato, Link Table ou painel.

**Limite acadêmico:** atributos de descrição permanecem no modelo aprovado dos Capítulos 1–2, fechado para impressão. Aceitação acadêmica de rótulos ausentes em parte da série não foi demonstrada; registrar a ressalva e consultar o professor se exigida completude. **`T29_HISTORICAL=NOT_APPROVED`**, **`A2_CONTRACT=APPROVED_DOCUMENTED_NOT_IMPLEMENTED`**, **`IV_TIPO_LEITO_QV_PHYSICAL_GATE=NOT_RUN`**. Evidência: `docs/discovery/phase-4-dim-tipo-leito-discovery-2026-10-09.md`.


---

# 15. DIM_TEMPO

## Fonte física

Um único:

`DIM_TEMPO.qvd`

### Conteúdo

A dimensão deverá cobrir as datas necessárias ao período e permitir derivar:

- data;
- ano;
- mês;
- competência AAAAMM;
- atributos de calendário realmente utilizados.

Não criar hierarquias sem uso analítico demonstrado.

### Painel

A partir do mesmo QVD serão carregadas projeções:

- `DIM_TEMPO_COMPETENCIA`;
- `DIM_TEMPO_ANO`;
- `DIM_TEMPO_INTERNACAO`;
- `DIM_TEMPO_SAIDA`.

Para competência e ano, usar projeção distinta na granularidade correspondente, evitando múltiplas linhas da dimensão diária para a mesma chave mensal/anual.

---

# 16. DIM_MUNICIPIO

## Base física

Um único:

`DIM_MUNICIPIO.qvd`

A dimensão deve manter:

- chave técnica;
- código DATASUS de 6 dígitos;
- código IBGE de 7 dígitos quando oficialmente mapeado;
- nome;
- UF.

### Residentes externos

Municípios de residência fora da Paraíba permanecem válidos.

A ausência de população PB para esses municípios não autoriza excluí-los da internação.

### Painel

Aliases:

- `DIM_MUNICIPIO_RESIDENCIA`;
- `DIM_MUNICIPIO_SERVICO`.

---

# 17. DIM_ESTABELECIMENTO

Grão:

`CNES × competência`

Chave:

`%SK_ESTABELECIMENTO`

Atributos históricos aprovados devem vir da competência correspondente.

Nome fantasia/razão social:

- usar quando comprovado para a competência;
- deixar ausente quando não comprovado;
- não fazer forward fill/backfill.

---

# 18. Dimensões de domínio

## DIM_PROCEDIMENTO

Lookup por:

`PROC_REA + competência SIGTAP`

Cobertura não encontrada deve gerar exceção de qualidade, não exclusão silenciosa.

## DIM_DIAGNOSTICO

Lookup CID-10.

A normalização da chave só será aprovada depois do teste de cobertura.

## DIM_CARATER_ATENDIMENTO

Materializar domínio oficial completo `01`–`06`.

## DIM_MOTIVO_SAIDA_PERMANENCIA

Preservar código fonte e descrição oficial.

`24` deve corresponder ao código normativo `2.4`.

## DIM_TIPO_LEITO

Desnormalizar Tipo de Leito → Leito conforme modelagem acadêmica.

Enquanto não houver prova de invariância, a versão física permanece competência-aware.

---

# 19. FATO_INTERNACAO

Grão preservado:

**1 registro administrativo RD / AIH processada.**

Gerar:

- `SK_REGISTRO_INTERNACAO`;
- `%LINK_KEY`;
- chaves exclusivas;
- `N_AIH`;
- `IDENT`;
- medidas aprovadas.

### QTD_REGISTRO_AIH

Sempre 1.

### QTD_INTERNACAO

- `IDENT=5` → 0;
- demais registros válidos que contam como nova internação → 1.

Não alterar a regra sem evidência.

---

# 20. FATO_CAPACIDADE_LEITO

Grão:

`CNES × COMPETEN × CODLEITO`

Preservar:

- leitos existentes;
- leitos SUS;
- leitos não SUS quando derivado.

Chave de tipo/leito exclusiva permanece na fato.

Não somar snapshots sucessivos como capacidade de período.

---

# 21. FATO_POPULACAO

Grão:

`município × ano`

Medida:

`POPULACAO_ESTIMADA`

A população será ligada tanto ao eixo municipal de residência quanto ao eixo municipal de serviço por meio da `LINK_ANALISE`, sem duplicar a linha factual.

---

# 22. Construção da `LINK_ANALISE`

## Campos

- `%LINK_KEY`;
- `%SK_TEMPO_COMPETENCIA`;
- `%SK_TEMPO_ANO`;
- `%SK_MUNICIPIO_RESIDENCIA`;
- `%SK_MUNICIPIO_SERVICO`;
- `%SK_ESTABELECIMENTO`.

## Regra

Cada fato calcula a mesma `%LINK_KEY` a partir das coordenadas compartilhadas aplicáveis.

Valores não aplicáveis permanecem nulos.

### Internação

Usa:

- competência;
- ano;
- município residência;
- município serviço;
- estabelecimento.

### Capacidade

Usa:

- competência;
- ano;
- município serviço;
- estabelecimento;
- município residência = nulo.

### População

Usa:

- ano;
- município residência = município da população;
- município serviço = município da população;
- competência = nulo;
- estabelecimento = nulo.

### Chave

A forma concreta deverá serializar explicitamente nulos e separadores antes de `Hash128`, para evitar ambiguidades.

Exemplo conceitual:

```text
Hash128(
  'LINK',
  COMPETENCIA|<NULL>,
  ANO|<NULL>,
  MUN_RES|<NULL>,
  MUN_SERV|<NULL>,
  ESTAB|<NULL>
)
```

Não incluir medidas ou dimensões exclusivas na `%LINK_KEY`.

### Deduplicação

`LINK_ANALISE` deve conter somente combinações distintas de coordenadas compartilhadas.

---

# 23. PAINEL — `PAINEL.qvw`

## Arquivos

- `PAINEL/PAINEL.qvw`;
- `PAINEL/painel_main.qvs`.

## Responsabilidade

Carregar apenas QVDs transformados e criar as aliases role-playing.

Não repetir regras complexas de transformação que pertencem ao `TRANSF.qvw`.

### Ordem

1. carregar `LINK_ANALISE`;
2. carregar fatos;
3. carregar dimensões compartilhadas;
4. carregar dimensões exclusivas;
5. validar modelo associativo;
6. somente depois construir objetos visuais.

---

# 24. Expressões analíticas — regra

Expressões oficiais do painel devem ser documentadas em texto versionável antes de serem tratadas como definitivas.

Mínimos previstos:

- internações;
- internações por 1.000 habitantes;
- leitos SUS;
- leitos SUS por 1.000 habitantes;
- relação internações/leito;
- fluxo residência → atendimento.

Capacidade anual deve usar média dos snapshots mensais.

População anual não deve ser somada entre anos.

---

# 25. Error handling QlikView

### Ajuste confirmado no Boundary 8

Para execução automatizada com `Qv.exe /r`, a documentação oficial do QlikView recomenda `ErrorMode=0` para evitar diálogos de erro em batch.

Portanto, o baseline operacional passa a ser:

`SET ErrorMode=0;`

com checagem explícita após operações críticas usando:

- `ScriptError`;
- `ScriptErrorCount`;
- `ScriptErrorList`.

Quando uma etapa crítica falhar, o script deve:

1. emitir `TRACE` com o erro;
2. não emitir o marcador de sucesso;
3. interromper o fluxo por `EXIT SCRIPT` ou mecanismo equivalente validado;
4. impedir o runner de avançar ao estágio seguinte.

`ErrorMode=2` poderá ser usado em execução interativa/manual quando o objetivo for interromper imediatamente e exibir a mensagem de erro, mas não é o baseline de batch.

### Regra

`ErrorMode=0` não significa ignorar erro operacionalmente. Toda falha crítica deve ser inspecionada explicitamente antes de continuar.

Fonte oficial:

- https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Starting_QlikView.htm
- https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Scripting/ErrorVariables/ErrorMode.htm

---

# 26. Logging

## Python

O conversor deve registrar:

- início/fim;
- arquivo;
- hash;
- contagem;
- schema;
- erro.

## QlikView

Usar:

- log de reload do QlikView;
- `TRACE` para milestones;
- contagens de tabelas em pontos críticos;
- mensagens explícitas antes de STORE.

O log não substitui a matriz de reconciliação.

---

# 27. Execução automatizada local

Será criado:

`tools/run_pipeline.cmd`

### Objetivo

Padronizar a ordem local:

```text
1. Python — DBC → CSV
2. Qv.exe /r EXTRACAO/EXT.qvw
3. Qv.exe /r TRANSFORMACAO/TRANSF.qvw
4. Qv.exe /r PAINEL/PAINEL.qvw
```

A documentação oficial do QlikView define `/r` como abrir, recarregar e fechar o documento.

### Configuração

Não hardcodear o caminho do QlikView no script.

Usar variável de ambiente, por exemplo:

`QLIKVIEW_EXE`

### Gate

O runner não deve iniciar a próxima etapa se a etapa anterior não tiver sinal de sucesso verificável.

A forma final de detecção de sucesso será testada no Boundary 8.

---

# 28. Marcadores de sucesso

Cada estágio deverá produzir somente ao final um pequeno artefato de status operacional, por exemplo:

- `EXTRACAO/QVD/_SUCCESS_EXTRACAO.csv`;
- `TRANSFORMACAO/QVD/_SUCCESS_TRANSFORMACAO.csv`.

Conteúdo mínimo:

- timestamp;
- estágio;
- status;
- contagens críticas;
- versão lógica do pipeline quando aplicável.

O runner deverá remover o marcador anterior antes de executar o estágio.

Se o reload falhar antes da emissão do marcador, o estágio é considerado inválido.

O marcador é artefato derivado e não será versionado.

---

# 29. Estratégia de reexecução / rollback

A V1 será **full rebuild**.

Não implementar carga incremental nesta etapa.

### Motivo

- período histórico fechado;
- volume compatível;
- maior simplicidade;
- reconciliação determinística;
- menor risco de resíduos de carga parcial.

### Reexecução

Em falha:

1. preservar os dados brutos;
2. remover artefatos derivados incompletos do estágio;
3. corrigir a causa;
4. executar novamente o estágio desde sua entrada canônica.

### Rollback

Não existe rollback transacional dos QVDs.

O rollback operacional é:

- descartar o conjunto derivado inválido;
- reconstruir a partir da camada anterior validada.

---

# 30. Contratos de saída

## EXTRAÇÃO — sucesso

Deve produzir QVDs staging e reconciliar contagens.

## TRANSFORMAÇÃO — sucesso

Deve produzir:

- 3 fatos;
- 8 dimensões;
- `LINK_ANALISE.qvd`;
- relatório/controles de reconciliação.

## PAINEL — sucesso

Deve carregar todo o modelo:

- sem synthetic key não justificada;
- sem circular reference;
- sem tabela loosely coupled usada para corrigir loop;
- com contagens reconciliadas.

---

# 31. Matriz mínima de testes

| ID | Camada | Teste | Critério |
|---|---|---|---|
| T01 | DBC | 108 arquivos | 108/108 |
| T02 | DBC | hashes de entrada | iguais ao inventário validado |
| T03 | DBC | registros RD | 566.672 |
| T04 | DBC | registros LT | 35.518 |
| T05 | DBC | registros ST | 220.390 |
| T06 | DBC | schema ST 2019-12 | 208 campos |
| T07 | EXTRAÇÃO | competências RD/LT/ST | 36/36 cada |
| T08 | EXTRAÇÃO | campos obrigatórios | 100% presentes |
| T09 | TRANSF | grão Internação | chave técnica única |
| T10 | TRANSF | `N_AIH` | não tratado como PK |
| T11 | TRANSF | `IDENT=5` | `QTD_INTERNACAO=0` |
| T12 | TRANSF | grão capacidade | CNES+COMPETEN+CODLEITO único |
| T13 | TRANSF | capacidade | sem valores negativos |
| T14 | TRANSF | população | município×ano único |
| T15 | TRANSF | municípios PB população | 223 por ano |
| T16 | TRANSF | estabelecimento histórico | nenhuma versão futura aplicada |
| T17 | TRANSF | Link key factual | 100% presente |
| T18 | TRANSF | Link coverage | 100% das link keys encontradas |
| T19 | TRANSF | órfãos obrigatórios | 0 |
| T20 | Qlik | synthetic keys | 0 não justificadas |
| T21 | Qlik | circular references | 0 |
| T22 | Qlik | RD↔ST | cobertura preservada |
| T23 | Qlik | LT↔ST | cobertura preservada |
| T24 | Indicador | internações/1.000 | igual ao controle |
| T25 | Indicador | leitos/1.000 | igual ao controle |
| T26 | Indicador | internações/leito | igual ao controle |
| T27 | Auxiliar | PROC_REA↔SIGTAP | cobertura medida e exceções registradas |
| T28 | Auxiliar | DIAG_PRINC↔CID | cobertura medida e exceções registradas |
| T29 | Auxiliar | CODLEITO↔referência | cobertura medida e exceções registradas |

---

# 32. Tratamento de referências não resolvidas

### Regra

Não descartar a linha factual.

Quando referência auxiliar não for resolvida:

- preservar código fonte;
- registrar exceção;
- usar membro físico de “não resolvido” somente se necessário ao modelo associativo e de forma explícita;
- não inventar descrição.

A decisão sobre um membro “Não resolvido” deve ser implementada apenas se o Qlik exigir chave não nula para aquela dimensão.

Caso a relação não seja obrigatória tecnicamente, manter nulo + relatório de exceção.

---

# 33. Ordem de implementação proposta

## Fase I — Infraestrutura mínima

Criar:

- diretórios;
- `.gitignore` alinhado;
- `requirements-tools.txt`;
- `dbc_to_csv.py`;
- QVWs vazios;
- `.qvs` principais.

## Fase II — Conversão

Validar primeiro:

- 1 RD;
- 1 LT;
- `STPB1912.dbc`.

Depois executar 108/108.

## Fase III — Extração

Implementar:

- RD;
- LT;
- ST;
- IBGE;
- referências auxiliares.

Reconciliação obrigatória antes de transformação.

## Fase IV — Dimensões

Implementar na ordem:

1. Tempo;
2. Município;
3. Estabelecimento;
4. Procedimento;
5. Diagnóstico;
6. Caráter;
7. Motivo;
8. Tipo de Leito.

## Fase V — Fatos

1. Internação;
2. Capacidade;
3. População.

## Fase VI — Link Table

Construir e validar `LINK_ANALISE`.

## Fase VII — Painel técnico

Carregar modelo sem objetos finais e validar Table Viewer.

## Fase VIII — Indicadores

Implementar expressões reconciliadas.

## Fase IX — Dashboards

Somente depois dos indicadores estarem reconciliados.

---

# 34. Boundary 8 — Readiness

Antes de iniciar a Fase I definitiva, o Boundary 8 deverá verificar:

- [ ] QlikView 12 instalado e executável;
- [ ] localização de `Qv.exe` conhecida;
- [ ] Python 3 disponível;
- [ ] ambiente virtual criado;
- [ ] `dbc-to-dbf==1.0.1` instalável;
- [ ] `dbfread==2.0.7` instalável;
- [ ] conversão de smoke test reproduz o DBC;
- [ ] leitura CSV pelo QlikView validada;
- [ ] caminhos relativos / `Must_Include` validados;
- [ ] `/r` validado em QVW mínimo;
- [ ] `ErrorMode=0` + checagem explícita de `ScriptErrorCount` validado em batch;
- [ ] arquivos BASE disponíveis localmente;
- [ ] 108 DBCs reconciliados com o inventário;
- [ ] arquivos IBGE presentes;
- [ ] referências auxiliares necessárias materializadas ou lacunas explicitamente aceitas;
- [ ] estratégia de nome histórico 2017-01 a 2017-05 permanece sem imputação;
- [ ] `.gitignore` planejado sem risco de versionar dados/QVD;
- [ ] espaço em disco suficiente para DBC + CSV + QVD;
- [ ] um protótipo mínimo da Link Table não produz synthetic key/circular reference;
- [ ] critérios T01–T29 classificados entre pré-implementação e pós-implementação;
- [ ] não existe blocker acadêmico novo.

Se algum item obrigatório falhar:

**NO-GO para implementação definitiva.**

---

# 35. Itens deliberadamente não implementados neste boundary

- nenhum QVD;
- nenhum QVW;
- nenhum script Qlik definitivo;
- nenhum conversor Python definitivo;
- nenhum dashboard;
- nenhuma dimensão/fato;
- nenhuma referência auxiliar baixada em massa.

Este documento é somente o plano executável.

---

# 36. Impacto na primeira entrega

Nenhuma alteração em:

- Capítulo 1;
- Capítulo 2;
- DER;
- modelo lógico;
- Star Schema;
- três fatos;
- oito dimensões;
- granularidades;
- regras de negócio.

---

# 37. Veredito

## `APROVADO PARA READINESS`

O plano de implementação está definido.

Próxima etapa:

**BOUNDARY 8 — Readiness**.

A implementação definitiva permanece bloqueada até o Boundary 8 emitir **GO**.

## Adendo de apresentação — aviso metodológico obrigatório CNES/LT (09/10/2026)

**DECISÃO APROVADA PELO RESPONSÁVEL:** as limitações da `DIM_TIPO_LEITO` devem aparecer **de forma visível e explícita nos gráficos de leitos e em suas análises interpretativas**, e não apenas nesta documentação. Esta é uma condição de aceite da futura Fase de PAINEL e de qualquer apresentação/impressão acadêmica com capacidade CNES/LT. Não criar PAINEL/figuras nesta fase IV: documentar o contrato para implementá-lo e testá-lo quando houver fatos/Link Table.

### Mensagem metodológica canônica para a cobertura global de 2017–2019

> **AVISO METODOLÓGICO — Leitos CNES (2017–2019):** 1.965 de 2.021 combinações distintas de código de tipo + código de leito + competência mensal (**97,2%**) não possuem descrição histórica comprovada para seu respectivo mês. O percentual refere-se **às combinações da dimensão**, **não** a leitos, estabelecimentos, internações ou registros de LT. Os códigos e quantitativos mensais CNES/LT permanecem disponíveis para análise; `NULL` de descrição **não** significa leito inexistente. Nomes exibidos em `201909` vêm exclusivamente da legenda datada de setembro/2019 (Nota Técnica 32/2019), sem comprovação de validade retrospectiva ou posterior. `T29_HISTORICAL=NOT_APPROVED`.

**Exibição obrigatória**: em toda visualização que apresente capacidade hospitalar por **nome, tipo/especialidade de leito ou comparação temporal entre tipos**, exibir uma versão legível deste aviso **na própria folha/painel ou ao lado do gráfico**, com referência à fonte. Não basta colocar texto oculto em tooltip, aba de ajuda, documentação de desenvolvimento ou checklist. Manter o aviso nas capturas usadas no relatório, PDFs/exportações e comentários escritos relativos à mesma análise. Para gráficos de capacidade **apenas por código**, exibir ao menos nota concisa junto ao gráfico, indicando códigos sem validação histórica das descrições. Não impor este aviso em gráficos que usem apenas SIH/RD ou IBGE e não dependam de descrição CNES/LT.

**Nota concisa aprovada**: `CNES/LT 2017–2019: descrições históricas não verificadas em 1.965/2.021 pares código×competência (97,2%). Nomes disponíveis apenas para set/2019; dados quantitativos por código mantidos. Fonte: CNES/LT e NT 32/2019. T29 histórico não aprovado.`

**Regras de filtro e denominador**:
- Os valores **1.965/2.021 = 97,2%** são do **universo global de pares-mês da dimensão**, apurados no A1; **não** são proporção ponderada pelo número de leitos nem percentual de registros LT.
- Para filtro de competência, município, estabelecimento ou tipo, **não reapresentar 97,2% como percentual do subconjunto**. Se o painel calcular cobertura no filtro, calcular `combinações sem rótulo / combinações distintas do conjunto filtrado` usando competência+código de tipo+código de leito; rotular claramente **percentual no filtro**. Quando não houver medição filtrada implementada, manter a nota global como global, ou suprimir apenas a porcentagem do filtro não medida.
- Rótulos `NULL` não devem virar `Outros`, `Sem leitos`, `Desconhecido` como categoria de negócio nem receber cor/legenda que sugira zero capacidade. Se for preciso exibir texto de interface, usar `Descrição histórica não verificada` **apenas na camada visual**, mantendo `NULL` no QVD.
- Não agregar ou comparar **nomes de setembro/2019** contra meses sem nomes como se a classificação nominal fosse temporalmente equivalente. Para séries históricas, utilizar **códigos**, exibir a ressalva e registrar que consistência normativa entre competências não foi integralmente comprovada. Leitos são **snapshots semi-aditivos**: análise anual por média mensal, jamais soma de leitos ao longo dos meses.
- Todo texto analítico de capacidade deve citar `CNES/LT`, período/competência, natureza de snapshot, limitação descritiva e não interpretar ausência de nomes como ausência de capacidade.

### Critérios obrigatórios do futuro aceite de PAINEL

1. Cada objeto/gráfico/folha afetado contém aviso persistente e legível; capturas para relatório/exportação retêm o aviso.
2. A nota numérica global 1.965/2.021 (97,2%) está explícita como **pares-mês da dimensão** e não como número/porcentagem de leitos.
3. Filtros não alteram indevidamente o denominador exibido; qualquer estatística dinâmica é calculada com unidades e universo claros.
4. `201909` é a única competência com descrições candidatas pelo snapshot, enquanto competências restantes usam código e `NULL` para descrições não comprovadas.
5. Notas e conclusões não chamam 2017–2019 de série de nomes historicamente validada nem marcam `T29` como PASS.
6. Revisão visual dos 3 painéis exigidos pelo professor e das capturas impressas deve rejeitar `PASS` se faltar a ressalva nas visualizações de leitos.

**Gates**: `PRESENTATION_CNES_HISTORICAL_CAVEAT=REQUIRED_NOT_IMPLEMENTED`; `T29_HISTORICAL=NOT_APPROVED`; `A2_CONTRACT=APPROVED_DOCUMENTED_NOT_IMPLEMENTED` no momento desta decisão. O PAINEL continua não iniciado.
