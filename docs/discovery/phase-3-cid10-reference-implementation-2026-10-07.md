# Fase III-C2 — CID-10 / DIAG_PRINC — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-C2 — CID-10  
**Status:** C2.1 PASS; C2.2 PASS; C2.3 INVENTÁRIO OFICIAL SIGTAP IMPLEMENTADO

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

## Gate C2.3

Esperado:

- `FOUND_COMPETENCES=36`;
- `MISSING_COMPETENCES=NONE`;
- `DUPLICATE_COMPETENCES=NONE` ou revisão explícita caso o FTP mantenha múltiplas versões;
- `VERDICT=PASS` quando houver exatamente uma versão utilizável por competência.

Nenhum pacote é baixado nesta etapa.

## Próximas etapas

Após o inventário:

1. selecionar estratégia mínima de materialização CID-10 com base no inventário oficial;
2. baixar apenas os pacotes necessários para provar a estabilidade/cobertura da `tb_cid.txt`;
3. inspecionar fisicamente `tb_cid.txt` e `tb_cid_layout.txt`;
4. comparar a referência contra `DIAG_PRINC` bruto e contra `Trim(DIAG_PRINC)`;
5. aprovar a regra somente pela cobertura observada e ausência de colisões;
6. gerar `REF_CID10.qvd` e checkpoint parcial no `EXT.qvw`.

Não iniciar fatos, dimensões, Link Table ou indicadores neste checkpoint.
