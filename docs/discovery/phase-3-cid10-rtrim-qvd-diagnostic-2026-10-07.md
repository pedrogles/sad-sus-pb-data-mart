# Fase III-C2 — Diagnóstico da expressão RTrim no lookup CID-10 — 07/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração  
**Checkpoint:** III-C2 / C2.8c  
**Status:** C2.8c PASS; C2.8d PASS no QlikView em 08/10/2026

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

## Evidência local — C2.8c PASS (08/10/2026)

Arquivo `_DIAGNOSTIC_CID10_QVD_UNMATCHED.csv` gerado novamente às 10:38:35, com as novas colunas confirmadas no cabeçalho.

O agrupamento dos 128 códigos distintos, totalizando 9.093 ocorrências, retornou exclusivamente:

```text
direct_text_match=1
text_after_rtrim_match=1
upper_rtrim_match=0
distinct=128
occurrences=9093
```

Os pares observados reforçam a diferença entre representação intermediária e chave textual final:

- `R042`: `RTrim(Text(DIAG_PRINC))` exibiu `R42`, mas `Text(RTrim(Text(DIAG_PRINC)))` exibiu `R042` e encontrou a referência;
- `R72`: `RTrim(Text(DIAG_PRINC))` exibiu `R072`, mas `Text(RTrim(Text(DIAG_PRINC)))` exibiu `R72` e encontrou a referência.

**FATO VERIFICADO:** a referência e o campo QVD possuem correspondência textual nos 9.093 casos; a forma usada diretamente em `ApplyMap` foi a causa operacional do gate incorreto. Não há evidência para reconstruir `SRC_SIH_RD.qvd` nem para alterar as origens.

## Correção C2.8d — lookup textual com padding removido

Foi substituída somente a expressão da reconciliação no `EXTRACAO/ext_main.qvs`:

```qvs
// Antes (9.093 unmatched)
RTrim(Text(DIAG_PRINC))

// Depois (validado no diagnóstico C2.8c)
Text(RTrim(Text(DIAG_PRINC)))
```

A remoção de padding à direita continua preservada. Permanecem os gates de cardinalidade, 566.672 linhas RD, zero unmatched e escrita do QVD e checkpoint parcial.

**DECISÃO DE IMPLEMENTAÇÃO:** usar a expressão aprovada por cobertura empírica dentro do lookup Qlik; não ampliar a normalização nem usar inferência monetária/numérica para corrigir códigos.

## Próximo gate

Executar `EXTRACAO/EXT.qvw` após atualizar `main`; exigir:

- `[EXTRACAO][REF_CID10] PASS rows=14230 unmatched_rd=0`;
- `REF_CID10.qvd` gerado;
- `_CHECKPOINT_EXTRACAO_CID10.csv` com 14.230 linhas CID, 566.672 RD e 0 unmatched;
- status do checkpoint `PASS_PARTIAL`, sem liberar ainda a extração completa.

## Resultado da validação local — C2.8d PASS

O reload de 08/10/2026 10:44:15 confirmou a correção sem exigir mudança na lógica de carga do QVD de origem. `REF_CID10.qvd` (945.638 bytes) e `_CHECKPOINT_EXTRACAO_CID10.csv` (205 bytes) foram gerados. O checkpoint registrou `EXTRACAO_CID10;PASS_PARTIAL;14230;14230;2042;12188;566672;0`.

O gate C2.8d está **PASS**. O III-C2 está **CONCLUÍDO**, mas a Fase III continua parcial.
