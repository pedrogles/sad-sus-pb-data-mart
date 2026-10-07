# Fase III-C2 — CID-10 / DIAG_PRINC — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-C2 — CID-10  
**Status:** PERFIL DE ENTRADA IMPLEMENTADO; MATERIALIZAÇÃO OFICIAL PENDENTE

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

## Gate C2.1

Execução local deve retornar:

- `RD_FILES=36`;
- `RD_ROWS=566672`;
- `DIAG_PRINC_BLANK_ROWS=0`;
- `VERDICT=PASS`.

As distribuições de comprimento e formato serão usadas para decidir como comparar os códigos com a referência oficial.

## Próximas etapas

Após o PASS do perfil:

1. inspecionar/materializar o pacote oficial CID-10;
2. identificar fisicamente arquivo, encoding e layout;
3. comparar primeiro por código bruto;
4. somente se houver divergência, testar normalizações candidatas e medir o efeito;
5. aprovar a regra de chave apenas com evidência;
6. gerar `REF_CID10.qvd` e checkpoint parcial no `EXT.qvw`.

Não iniciar fatos, dimensões, Link Table ou indicadores neste checkpoint.
