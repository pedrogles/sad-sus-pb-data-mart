# Fase III-C2 — Diagnóstico dual de DIAG_PRINC no QVD — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-C2 / C2.8b  
**Status:** diagnóstico implementado; reload local pendente

## Contexto

O C2.8 carregou corretamente a referência CID-10 final e passou os gates estruturais, mas encontrou 9.093 linhas RD sem match em `SRC_SIH_RD.qvd`.

O C2.6, executado diretamente sobre os CSVs convertidos, havia obtido cobertura de 566.672/566.672 linhas contra a referência 201912. Portanto, a divergência ocorre entre a representação disponível no CSV e a representação persistida no QVD.

## Fatos verificados

O diagnóstico C2.8a encontrou:

- 9.093 ocorrências sem match;
- 128 valores distintos;
- todos os valores distintos iniciados por `R`;
- `Upper(RTrim())` não resolve o match.

Exemplos observados no QVD incluem:

- `R042` exibido como `R42`;
- `R72␠` exibido como `R072`.

A inspeção local dos CSVs convertidos confirmou que os pares permanecem distintos na origem:

- `R042`: 14 ocorrências;
- `R42␠`: 2 ocorrências;
- `R072`: 12 ocorrências;
- `R72␠`: 10 ocorrências.

A cultura do Windows é `pt-BR`, com símbolo monetário `R$`. Isso não comprova que `MoneyFormat` seja o gatilho específico.

## Hipótese técnica atual

A evidência é compatível com comportamento dual do QlikView: valores com representações textuais diferentes, mas a mesma representação numérica válida, podem compartilhar a primeira representação textual carregada.

A causa ainda não é considerada confirmada porque o componente numérico do valor no QVD não foi medido diretamente.

## C2.8b — diagnóstico do componente dual

O `EXTRACAO/ext_main.qvs` foi ampliado para registrar, no arquivo já existente:

`QVD/_DIAGNOSTIC_CID10_QVD_UNMATCHED.csv`

as colunas adicionais:

- `is_num` — resultado de `IsNum(DIAG_PRINC)`;
- `is_text` — resultado de `IsText(DIAG_PRINC)`;
- `numeric_value` — componente numérico formatado quando `IsNum()` for verdadeiro.

Nenhuma normalização nova foi aprovada e nenhuma correção foi aplicada ao staging RD.

## Próximo gate

Reexecutar `EXTRACAO/EXT.qvw` e inspecionar:

- `is_num`;
- `is_text`;
- `numeric_value`;

especialmente para pares equivalentes como `R042` / `R42␠` e `R072` / `R72␠`.

Somente após essa evidência será decidida a correção da carga RD.
