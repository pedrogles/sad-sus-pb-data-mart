# Fase III-C2 — CID-10 / DIAG_PRINC — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-C2 — CID-10  
**Status:** C2.1 PERFIL BRUTO PASS; C2.2 DIAGNÓSTICO DE PADDING IMPLEMENTADO

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

## Gate C2.2

A execução local deve preservar:

- `RD_FILES=36`;
- `RD_ROWS=566672`;
- `WHITESPACE_ROWS=60423`;
- `WHITESPACE_DISTINCT_CODES=526`;
- `VERDICT=PASS`.

Os resultados de posição e colisão decidirão se `Trim()` pode ser tratado apenas como remoção de padding técnico ou se a chave precisa de outra regra.

## Próximas etapas

Após o C2.2:

1. inspecionar/materializar um pacote oficial SIGTAP que contenha `tb_cid.txt` e seu layout;
2. identificar fisicamente encoding, largura e chave da referência;
3. comparar a referência contra `DIAG_PRINC` bruto e contra candidatos de normalização sustentados pelo C2.2;
4. aprovar a regra que maximize cobertura sem colisão ou fabricação de código;
5. somente então gerar `REF_CID10.qvd` e checkpoint parcial no `EXT.qvw`.

Não iniciar fatos, dimensões, Link Table ou indicadores neste checkpoint.
