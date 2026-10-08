# Fase III-C2 — CID-10 / DIAG_PRINC — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-C2 — CID-10  
**Status:** C2.1–C2.7/C2.8c PASS; C2.8d CORREÇÃO DO LOOKUP IMPLEMENTADA, RELOAD QLIK PENDENTE

## Objetivo

Materializar uma referência oficial CID-10 e medir cobertura real contra `DIAG_PRINC`, sem definir antecipadamente a normalização da chave.

## FATO VERIFICADO — estado de entrada

- `DIAG_PRINC` é o diagnóstico principal usado pela versão inicial do Data Mart;
- o Boundary 3 encontrou 0 `DIAG_PRINC` vazios nos 566.672 registros RD;
- o Boundary 4 determinou que a referência deve ser CID-10 oficial;
- não foi demonstrada necessidade de historização mensal da referência;
- a regra exata de normalização permanece pendente até o teste empírico.

## Fonte oficial

A documentação oficial do SIGTAP define CID Principal como código da Classificação Estatística Internacional de Doenças e Problemas Relacionados à Saúde — CID-10.

A área oficial de download do SIGTAP disponibiliza arquivos TXT por competência da Tabela de Procedimentos do SUS. A competência concreta a ser usada para materializar `tb_cid` será confirmada na inspeção física do pacote oficial; nomes de campos/layout não serão assumidos antes dessa inspeção.

## Etapa C2.1 — perfil bruto de DIAG_PRINC

Foi adicionado:

`tools/profile_cid10_diag_princ.py`

O script:

- lê os 36 CSVs RD já convertidos;
- exige exatamente 566.672 registros;
- exige a presença de `DIAG_PRINC`;
- preserva o valor bruto, sem remoção de ponto, upper-case, padding ou outra normalização;
- conta códigos distintos, comprimentos e formatos observados;
- registra primeira/última competência e quantidade de arquivos por código;
- gera somente artefatos locais ignorados pelo Git.

Saídas:

- `BASE/REFERENCIAS/cid10_diag_princ_profile.csv`;
- `BASE/REFERENCIAS/cid10_diag_princ_summary.json`.

## Evidência C2.1 — perfil bruto

Execução local:

- `RD_FILES=36`;
- `RD_ROWS=566672`;
- `DIAG_PRINC_DISTINCT_RAW=5480`;
- `DIAG_PRINC_BLANK_ROWS=0`;
- comprimento bruto: 566.672/566.672 linhas com 4 caracteres;
- formato por linha:
  - `UPPER_ALNUM=506249`;
  - `HAS_WHITESPACE=60423`;
- códigos distintos:
  - 4.954 `UPPER_ALNUM`;
  - 526 `HAS_WHITESPACE`;
- SHA-256 do perfil:
  `1d185cd4780d4c688a8ceeaf8b14cdaa359f040a1590b710a8d9daeaf4870dbc`;
- `VERDICT=PASS`.

**FATO VERIFICADO:** o C2.1 está PASS. Todos os valores físicos de `DIAG_PRINC` têm largura 4, mas 60.423 linhas — distribuídas em 526 códigos distintos — contêm whitespace.

## Evidência oficial complementar

A documentação oficial do CMD/DATASUS descreve o campo `CO_DIAGNOSTICO` da terminologia CID-10 como alfanumérico de tamanho 4 e validado no SIGTAP/RTS.

Fonte:

- https://wiki.saude.gov.br/cmd/index.php/ETL_e_suas_regras

Essa evidência é compatível com a largura física observada, mas ainda não prova se os 526 códigos com whitespace usam exclusivamente padding à direita nem se remover esse padding é uma normalização sem colisão.

## Etapa C2.2 — diagnóstico de whitespace/padding

Foi adicionado:

`tools/inspect_cid10_diag_princ_padding.py`

O script mede, sem alterar a fonte:

- posição do whitespace: início, meio ou fim;
- caractere de whitespace observado;
- comprimento após `strip()`;
- quantidade de códigos distintos após `strip()`;
- colisões em que dois valores brutos diferentes passariam a representar a mesma chave;
- arquivo de detalhe com representação visível do espaço.

Saídas locais:

- `BASE/REFERENCIAS/cid10_diag_princ_padding.csv`;
- `BASE/REFERENCIAS/cid10_diag_princ_padding_summary.json`.

## Evidência C2.2 — whitespace/padding

Execução local:

- `RD_FILES=36`;
- `RD_ROWS=566672`;
- `RAW_DISTINCT_CODES=5480`;
- `WHITESPACE_ROWS=60423`;
- `WHITESPACE_DISTINCT_CODES=526`;
- posição do whitespace:
  - `NONE=506249`;
  - `TRAILING=60423`;
- caractere observado:
  - `SPACE_U+0020=60423`;
- após `strip()`:
  - 5.480 códigos distintos — nenhuma redução;
  - 60.423 linhas passam de largura 4 para 3;
  - 506.249 permanecem com largura 4;
  - `TRIM_COLLISION_COUNT=0`;
- SHA-256 do detalhe:
  `6859c39e8a6b1690c6b94e5be5d615f3330c628f6510a5e1ea9a6bcc4a8a875b`;
- `VERDICT=PASS`.

**FATO VERIFICADO:** todo whitespace observado é um único espaço ASCII à direita. Não há espaço inicial ou interno, não há outro caractere de whitespace e remover o padding com `strip()` não cria colisões nem altera a cardinalidade de 5.480 códigos distintos.

**HIPÓTESE DE IMPLEMENTAÇÃO FORTEMENTE SUSTENTADA:** `Trim(DIAG_PRINC)` pode representar remoção de padding técnico. A regra ainda não é considerada fechada até ser comparada com a chave física da referência oficial `tb_cid.txt`.

## Evidência oficial para aquisição

A documentação oficial do SIGTAP informa que cada competência está disponível para download em arquivo ZIP contendo os TXT da Tabela de Procedimentos do SUS.

Uma publicação oficial do Ministério da Saúde/DATASUS registra a origem histórica dos pacotes SIGTAP em:

`ftp://ftp2.datasus.gov.br/pub/sistemas/tup/downloads/TabelaUnificada_*`

## Etapa C2.3 — inventário oficial SIGTAP

Foi adicionado:

`tools/enumerate_sigtap_packages.py`

O script:

- conecta em modo anônimo/read-only ao FTP oficial;
- não baixa nenhum ZIP;
- enumera somente `TabelaUnificada_*.zip` entre 2017-01 e 2019-12;
- mede cobertura das 36 competências;
- registra múltiplas versões por competência, se existirem;
- tenta registrar tamanho remoto quando o servidor permitir.

Saídas locais:

- `BASE/REFERENCIAS/sigtap_package_inventory_2017_2019.csv`;
- `BASE/REFERENCIAS/sigtap_package_inventory_2017_2019.json`.

## Evidência C2.3 — inventário oficial SIGTAP

Execução local:

- `MATCHED_FILES=36`;
- `FOUND_COMPETENCES=36`;
- `MISSING_COMPETENCES=NONE`;
- `DUPLICATE_COMPETENCES=NONE`;
- 2017-01 a 2019-12 cobertos sem lacunas;
- `VERDICT=PASS`.

**FATO VERIFICADO:** existe exatamente um pacote oficial `TabelaUnificada_*.zip` para cada uma das 36 competências do período.

## Evidência oficial complementar sobre temporalidade CID-10

A documentação oficial do CMD informa que, para CID-10, a versão da terminologia aceita é a versão 2008. Ao mesmo tempo, o serviço de validação CID consulta o repositório SIGTAP considerando a competência.

Isso sustenta uma estratégia em duas etapas:

1. testar empiricamente se o arquivo físico `tb_cid.txt` permanece idêntico em pontos estratégicos de 2017–2019;
2. se permanecer idêntico e a cobertura dos 5.480 códigos for total, evitar materialização mensal redundante; se houver divergência, ampliar a amostragem ou materializar por competência.

## Etapa C2.4 — materialização controlada da amostra CID-10

Foi adicionado:

`tools/materialize_cid10_sigtap_sample.py`

Seleção padrão:

- `201701`;
- `201801`;
- `201901`;
- `201912`.

Racional:

- primeira competência de cada ano;
- última competência do período;
- comparação entre anos e extremos temporais antes de baixar 36 ZIPs.

O script:

- consome o inventário C2.3;
- baixa somente os quatro ZIPs selecionados do FTP oficial;
- valida integridade ZIP;
- procura fisicamente `tb_cid.txt` e `tb_cid_layout.txt`;
- extrai somente esses dois arquivos;
- descarta o ZIP temporário;
- registra tamanho, contagem bruta de linhas e SHA-256;
- compara hashes entre as quatro competências.

Saídas locais:

- `BASE/REFERENCIAS/SIGTAP/CID10/<competencia>/tb_cid.txt`;
- `BASE/REFERENCIAS/SIGTAP/CID10/<competencia>/tb_cid_layout.txt`;
- `BASE/REFERENCIAS/cid10_sigtap_sample_manifest.json`.

## Evidência C2.4 — materialização controlada

Execução local:

- `MATERIALIZED_COMPETENCES=4`;
- competências materializadas: `201701`, `201801`, `201901`, `201912`;
- `tb_cid_layout.txt`: mesmo SHA-256 nas quatro competências, 7 linhas;
- `tb_cid.txt`:
  - 201701/201801/201901: SHA-256 `4a1e77eb817e0c45e08418d2212a73d1eed73dd12e705071cbc791b245363c41`, 12.450 linhas;
  - 201912: SHA-256 `cee83290ee6c390038204ec6a0bfed7f8b92cbac5942a85a970d263edf0adfe8`, 14.230 linhas;
- `TB_CID_DISTINCT_HASHES=2`;
- `TB_CID_IDENTICAL_ACROSS_SAMPLE=False`;
- `TB_CID_LAYOUT_DISTINCT_HASHES=1`;
- `TB_CID_LAYOUT_IDENTICAL_ACROSS_SAMPLE=True`;
- `VERDICT=PASS`.

**FATO VERIFICADO:** a estrutura física do layout permaneceu estável na amostra, mas o conteúdo de `tb_cid.txt` mudou dentro de 2019. Portanto, a hipótese de uma referência física única para todo 2017–2019 não pode ser aprovada neste momento.

**DECISÃO PENDENTE:** localizar e caracterizar a mudança antes de decidir entre referência única por versão, referência sensível à competência ou outra estratégia suportada por evidência.

## Etapa C2.5 — inspeção estrutural e diff

Foi adicionado:

`tools/inspect_cid10_sigtap_sample.py`

O script é read-only e usa somente os quatro arquivos já materializados. Ele:

- testa decodificação estrita em `utf-8`, `cp1252` e `latin-1`;
- registra distribuição de comprimento físico das linhas;
- expõe o conteúdo de `tb_cid_layout.txt` sem interpretar campos antecipadamente;
- compara linha a linha `201701→201801`, `201801→201901` e `201901→201912`;
- contabiliza linhas adicionadas/removidas;
- mostra amostras escapadas das diferenças;
- não aplica `Trim()`, parsing de chave ou qualquer transformação sem o layout real.

Saída local:

- `BASE/REFERENCIAS/cid10_sigtap_structure_diff.json`.

## Evidência C2.5 — estrutura física e diff

Execução local confirmou:

- `tb_cid.txt` usa `cp1252`/Latin-1 compatível; UTF-8 estrito não é válido;
- todas as linhas físicas possuem 111 bytes;
- o layout é estável e define:
  - `CO_CID`: posições 1–4;
  - `NO_CID`: posições 5–104;
  - `TP_AGRAVO`: posição 105;
  - `TP_SEXO`: posição 106;
  - `TP_ESTADIO`: posição 107;
  - `VL_CAMPOS_IRRADIADOS`: posições 108–111;
- 201701→201801: 0 linhas adicionadas/removidas;
- 201801→201901: 0 linhas adicionadas/removidas;
- 201901→201912:
  - 1.780 linhas adicionadas;
  - 0 removidas;
  - 1.780 adicionadas distintas;
- exemplos das linhas adicionadas mostram códigos de 3 caracteres preenchidos com espaço na quarta posição, como `A00␠`, `A01␠`, `A02␠`, coexistindo com subcategorias de 4 caracteres como `A000`, `A001`.

**FATO VERIFICADO:** 201912 é um superset físico de 201901 na amostra: nenhuma linha antiga foi removida e 1.780 linhas foram acrescentadas. A mudança observada introduz, entre outros registros, categorias CID de 3 caracteres preenchidas com espaço na chave fixa de 4 posições.

Isso se conecta diretamente ao C2.2: os 60.423 registros RD com whitespace também possuem um espaço ASCII à direita e passam de 4 para 3 caracteres após remoção do padding.

## Etapa C2.6 — cobertura empírica da chave CID

Foi adicionado:

`tools/analyze_cid10_reference_coverage.py`

O script:

- lê o layout real já comprovado;
- interpreta `tb_cid.txt` em `cp1252`;
- extrai `CO_CID` e `NO_CID` pelas posições oficiais do layout;
- valida unicidade das chaves;
- compara 201901 e 201912 por chave e payload;
- mede se as 1.780 adições são exclusivamente chaves preenchidas/padrões de comprimento;
- lê os 36 RD / 566.672 registros;
- mede cobertura contra 201901 e 201912:
  - por código bruto de 4 posições;
  - por código com somente padding ASCII à direita removido via `rstrip(' ')`;
- mede cobertura geral, por ano e por competência;
- verifica colisões de normalização;
- gera CSV dos códigos RD não cobertos por 201901 com indicação de presença/descrição em 201912.

Saídas locais:

- `BASE/REFERENCIAS/cid10_coverage_analysis.json`;
- `BASE/REFERENCIAS/cid10_coverage_unmatched.csv`.

## Evidência C2.6 — cobertura empírica

Execução local:

- `REF_201901_ROWS=12450`;
- `REF_201912_ROWS=14230`;
- `REF_ADDED_RAW_KEYS=1780`;
- `REF_REMOVED_RAW_KEYS=0`;
- `REF_SHARED_CHANGED_DESCRIPTION=0`;
- `REF_SHARED_CHANGED_PAYLOAD=0`;
- todas as 1.780 chaves adicionadas normalizam para comprimento 3;
- `RD_ROWS=566672`;
- contra 201901:
  - 564.771 linhas cobertas;
  - 1.901 linhas não cobertas;
  - 349 códigos normalizados distintos não cobertos;
  - os 349 têm comprimento 3;
- contra 201912:
  - 566.672/566.672 linhas cobertas;
  - 0 linhas não cobertas;
- `UNMATCHED_NORM_ALL_PRESENT_201912=True`;
- a divergência de cobertura ocorre somente em 2019, começando em 201904;
- `VERDICT=PASS`.

**FATO VERIFICADO:** a referência 201912 é um superset descritivo da referência 201901 para o escopo observado. Ela preserva sem alteração as 12.450 chaves anteriores e acrescenta 1.780 categorias de 3 caracteres; todos os 349 códigos de `DIAG_PRINC` que não existiam em 201901 estão presentes em 201912.

**DECISÃO CONFIRMADA DE IMPLEMENTAÇÃO:** para o Data Mart inicial 2017–2019, usar a competência 201912 como **referência CID-10 descritiva estática/superset** para código e descrição de `DIAG_PRINC`.

Limite da decisão:

- a referência serve para lookup descritivo;
- não afirma que cada um dos 14.230 códigos esteve vigente em todas as competências de 2017–2019;
- não deve ser usada para inferir início/fim de vigência;
- se o projeto passar a analisar validade histórica do CID por competência, a decisão deve ser reaberta;
- a normalização aprovada da chave é somente remoção de espaço ASCII `U+0020` à direita do código fixo de 4 posições.

## Etapa C2.7 — materialização final da referência CID-10

Foi adicionado:

`tools/materialize_cid10_reference.py`

O script:

- exige as evidências C2.4 e C2.6 previamente materializadas;
- bloqueia execução se 201912 deixar de cobrir as 566.672 linhas RD;
- bloqueia execução se houver remoção de chave ou alteração de descrição/payload compartilhado;
- valida os hashes locais de `tb_cid.txt` e `tb_cid_layout.txt` contra o manifesto C2.4;
- interpreta o layout oficial;
- materializa 14.230 códigos únicos;
- normaliza `CO_CID` apenas com remoção de espaço ASCII à direita;
- materializa `NO_CID` como descrição;
- exige distribuição empiricamente confirmada da referência 201912:
  - 2.042 códigos de comprimento 3;
  - 12.188 códigos de comprimento 4;
- gera CSV UTF-8 e manifesto com SHA-256.

Saídas locais:

- `BASE/REFERENCIAS/cid10_referencia.csv`;
- `BASE/REFERENCIAS/cid10_referencia_manifest.json`.

## Evidência da primeira execução C2.7

A primeira execução chegou até o gate final de distribuição e foi interrompida com:

`{"3": 2042, "4": 12188}`

Isso prova que:

- as 14.230 linhas foram lidas;
- a normalização produziu somente códigos de tamanho 3 ou 4;
- o gate anterior estava incorreto.

O erro foi conceitual: o C2.6 havia demonstrado que **as 1.780 chaves adicionadas em 201912** têm comprimento 3 após remoção do padding, mas isso não significa que somente essas 1.780 chaves tenham comprimento 3 na referência completa. O conjunto anterior de 12.450 chaves já contém 262 categorias de 3 caracteres.

Assim, a distribuição completa de 201912 é:

- 2.042 códigos de comprimento 3;
- 12.188 códigos de comprimento 4;
- total 14.230.

**FATO VERIFICADO:** o bloqueio foi um gate incorreto no materializador, não uma inconsistência da fonte CID-10.

## Evidência C2.7 — materialização final

A reexecução local após a correção retornou:

- `REFERENCE_COMPETENCE=201912`;
- `CID_ROWS=14230`;
- `CID_DISTINCT_CODES=14230`;
- `CID_CODE_LENGTH_COUNTS={"3": 2042, "4": 12188}`;
- `RD_COVERAGE_EVIDENCE_ROWS=566672`;
- `SHARED_CHANGED_DESCRIPTION=0`;
- `SHARED_CHANGED_PAYLOAD=0`;
- `DECISION=STATIC_DESCRIPTIVE_SUPERSET`;
- `VERDICT=PASS`.

O CSV final foi gerado com SHA-256:

`da541adc1efbdb4ac04c555cf1e008967fd053fb6368ff443fb10a476757025f`

A reconciliação local do manifesto retornou:

`cid10_referencia.csv => ROWS=14230 MATCH=True`

**FATO VERIFICADO:** C2.7 está PASS.

## Etapa C2.8 — integração QlikView

O `EXTRACAO/ext_main.qvs` foi ampliado para:

- carregar `BASE/REFERENCIAS/cid10_referencia.csv`;
- gerar `REF_CID10.qvd`;
- validar 14.230 linhas e 14.230 códigos distintos;
- validar 2.042 códigos de comprimento 3 e 12.188 de comprimento 4;
- exigir competência de referência `201912`;
- exigir 0 descrições vazias;
- mapear `DIAG_PRINC` usando `RTrim(Text(DIAG_PRINC))`, removendo somente o padding técnico à direita;
- reconciliar as 566.672 linhas RD e exigir 0 unmatched;
- gerar `_CHECKPOINT_EXTRACAO_CID10.csv` com status `PASS_PARTIAL`.

## Gate C2.8

Executar novo reload local de `EXTRACAO/EXT.qvw` e exigir:

- `REF_CID10.qvd` gerado;
- `_CHECKPOINT_EXTRACAO_CID10.csv` gerado;
- `cid10_rows=14230`;
- `cid10_distinct_codes=14230`;
- `cid10_length_3=2042`;
- `cid10_length_4=12188`;
- `rd_rows=566672`;
- `cid10_unmatched_rd_rows=0`.

Não iniciar fatos, dimensões, Link Table ou indicadores neste checkpoint.


## Evidência do primeiro reload C2.8

O primeiro reload Qlik carregou corretamente a referência CID-10 e passou todos os gates estruturais:

- 14.230 linhas;
- 14.230 códigos distintos;
- 2.042 códigos de comprimento 3;
- 12.188 códigos de comprimento 4;
- competência de referência 201912;
- 0 descrições vazias.

Na reconciliação contra `SRC_SIH_RD.qvd`, porém:

- `rd_rows=566672`;
- `cid10_unmatched_rd_rows=9093`.

O reload foi interrompido controladamente antes de gerar `REF_CID10.qvd`.

Esse resultado diverge da análise Python C2.6 sobre os CSVs convertidos, que obteve cobertura 100% contra 201912. Portanto, a hipótese atual é de diferença de representação entre o valor disponível no QVD e o valor bruto dos CSVs; a causa ainda não está confirmada.

A documentação oficial do QlikView informa que, por padrão, espaços e tabs nas extremidades são removidos ao carregar valores para o banco associativo, salvo uso de `SET Verbatim=1`. Isso reforça a necessidade de observar os valores efetivamente presentes em `SRC_SIH_RD.qvd`, em vez de assumir equivalência byte a byte com os CSVs.

## Diagnóstico C2.8a

O `EXTRACAO/ext_main.qvs` foi ampliado de forma fail-closed. Quando houver unmatched CID-10, antes de `EXIT SCRIPT` ele passa a gerar:

`QVD/_DIAGNOSTIC_CID10_QVD_UNMATCHED.csv`

Para cada valor distinto não coberto, o diagnóstico registra:

- valor lido do QVD;
- resultado de `RTrim()`;
- resultado de `Upper(RTrim())`;
- comprimentos antes/depois;
- códigos ordinais dos quatro caracteres;
- número de ocorrências;
- se `Upper(RTrim())` resolveria o match.

Nenhuma regra de normalização nova foi aprovada.

## Evidência final C2.8c — 08/10/2026

O diagnóstico atualizado confirmou, nos 128 códigos distintos que representam 9.093 linhas RD sem match no gate original:

- `direct_text_match=1`: 128 códigos / 9.093 registros;
- `text_after_rtrim_match=1`: 128 códigos / 9.093 registros;
- `upper_rtrim_match=0`: 128 códigos / 9.093 registros;
- `IsNum(DIAG_PRINC)=0` e `IsText(DIAG_PRINC)=-1` no QVD.

A comparação mostrou `RTrim(Text(DIAG_PRINC))` exibindo `R42` para `R042` e `R072` para `R72`, enquanto `Text(RTrim(Text(DIAG_PRINC)))` preserva a chave textual original e encontra a referência. A hipótese de alteração dos CSVs ou do valor armazenado no QVD não é sustentada.

## Correção C2.8d — implementada, ainda não validada por reload

No `EXTRACAO/ext_main.qvs`, o lookup de cobertura foi alterado de `RTrim(Text(DIAG_PRINC))` para `Text(RTrim(Text(DIAG_PRINC)))`.

Permanecem: fonte oficial CID 201912, 14.230 códigos únicos, normalização com remoção de padding à direita, 566.672 RD obrigatórios, 0 unmatched obrigatório e `PASS_PARTIAL` apenas após os STOREs concluídos.

## Próximo gate

Atualizar `main`, recarregar `EXTRACAO/EXT.qvw` e verificar `REF_CID10.qvd` com `_CHECKPOINT_EXTRACAO_CID10.csv` contendo `cid10_rows=14230`, `rd_rows=566672` e `cid10_unmatched_rd_rows=0`. Não encerrar a Fase III neste checkpoint.
