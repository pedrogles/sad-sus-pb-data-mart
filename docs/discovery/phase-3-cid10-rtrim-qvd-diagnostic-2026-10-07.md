# Fase III-C2 — Diagnóstico da expressão RTrim no lookup CID-10 — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-C2 / C2.8c  
**Status:** diagnóstico implementado; reload local pendente

## Evidência de entrada

O diagnóstico C2.8b mostrou, para os 128 valores distintos sem match:

- `IsNum(DIAG_PRINC)=0`;
- `IsText(DIAG_PRINC)=-1`;
- `numeric_value` vazio em 100% dos casos.

**FATO VERIFICADO:** o campo `DIAG_PRINC` persistido em `SRC_SIH_RD.qvd` não possui componente numérico. Portanto, a hipótese de colisão dual no campo armazenado foi refutada.

Ao mesmo tempo, o diagnóstico anterior mostrou casos como:

- `diag_princ_qvd=R042`;
- `diag_princ_rtrim=R42`;
- `qvd_length=4`;
- `rtrim_length=4`.

Esse comportamento indica que a divergência pode estar sendo introduzida pela expressão usada no lookup, e não pelo valor armazenado no QVD.

## C2.8c — comparação direta de chaves

O diagnóstico foi ampliado para comparar:

- `Text(DIAG_PRINC)` diretamente;
- `Text(RTrim(Text(DIAG_PRINC)))`;
- `Upper(RTrim(Text(DIAG_PRINC)))`.

Novas colunas:

- `diag_princ_text_after_rtrim`;
- `text_after_rtrim_length`;
- `direct_text_match`;
- `text_after_rtrim_match`;
- `upper_rtrim_match`.

Nenhuma regra de produção foi alterada. O gate principal continua usando a expressão atual e permanece fail-closed.

## Próximo gate

Reexecutar `EXTRACAO/EXT.qvw` e verificar se `direct_text_match=1` para todos os 128 valores distintos / 9.093 ocorrências.

Se isso ocorrer, a causa estará localizada na aplicação de `RTrim()` sobre o campo já persistido como texto no QVD, e a correção poderá ser feita removendo essa transformação do lookup CID-10.
