# Fase III-C4 — Referência CNES tipo/leito (T29)

**Projeto:** SAD — Data Mart SUS PB  
**Data de abertura:** 08/10/2026  
**Fase:** III — Extração / staging  
**Status:** C4.1 PERFIL CNES/LT IMPLEMENTADO / EXECUÇÃO LOCAL PENDENTE; T29 NÃO AVALIADO

## 1. Fontes e decisões preservadas

Conforme `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/discovery/boundary-4-auxiliary-references.md` e `docs/discovery/boundary-7-implementation-plan.md`:

- **FATO VERIFICADO (staging anterior):** 36 competências de CNES/LT em 2017–2019, com 35.518 registros, disponíveis como `BASE/CONVERTIDA/LT/LTPBYYMM.csv` e `SRC_CNES_LT.qvd`.
- **DECISÃO CONFIRMADA:** a dimensão `DIM_TIPO_LEITO` desnormalizará Tipo de Leito → Leito, sem antecipar a construção dimensional na Extração.
- **DECISÃO PENDENTE:** materializar e comparar referências **oficiais e históricas** de `TP_LEITO` e `CODLEITO` e verificar se descrições/classificações mudaram entre 2017 e 2019.
- **T29:** correspondência `CODLEITO` ↔ referência oficial, com cobertura efetivamente medida e exceções registradas. **Não foi avaliado** nesta etapa.
- A investigação não deve inventar mapeamento, classe, descrição, vigência temporal, chave candidata de dimensão ou relacionamento sem evidência física/oficial.

## 2. C4.1 — Perfil read-only dos códigos reais do CNES/LT

Script implementado: `tools/profile_cnes_lt_bed_codes.py`.

Lê somente os **36 CSVs locais** `BASE/CONVERTIDA/LT/LTPBYYMM.csv`, exige contagem total de **35.518 linhas**, preserva `TP_LEITO` e `CODLEITO` **literalmente como strings** e inspeciona `COMPETEN` em relação à competência do arquivo, sem modificar os valores originais.

Mede, sem deduzir significados ou hierarquias oficiais:

- valores distintos, comprimentos e formatos brutos de `TP_LEITO` e `CODLEITO`;
- pares de códigos observados, ocorrências, primeiro/último mês e competências em que aparecem;
- cardinalidade observada `CODLEITO` → valores `TP_LEITO` (apenas indício empírico de possível ambiguidade, **não** regra de negócio);
- totais e anomalias mensais, códigos vazios e eventuais divergências físicas da competência.

Saídas **locais e ignoradas pelo Git**:

- `BASE/REFERENCIAS/cnes_lt_bed_code_monthly_profile.csv`;
- `BASE/REFERENCIAS/cnes_lt_bed_code_pair_profile.csv`;
- `BASE/REFERENCIAS/cnes_lt_bed_code_profile_summary.json`.

O JSON registra métricas agregadas e SHA-256 dos dois CSVs. O script retorna `VERDICT=PASS` para perfil fisicamente íntegro e `VERDICT=REVIEW` se houver códigos vazios ou competência divergente. **C4.1 PASS não significa T29 PASS.**

### Execução

Na raiz do repositório:

```powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\profile_cnes_lt_bed_codes.py
```

Conferência de saídas:

```powershell
$m = Get-Content .\BASE\REFERENCIAS\cnes_lt_bed_code_profile_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
$m.status
$m.input
$m.observed_codes
@($m.outputs.monthly, $m.outputs.pairs) | ForEach-Object {
    $actual = (Get-FileHash $_.path -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{
        Path = $_.path
        Rows = $_.rows
        HashMatch = ($actual -eq $_.sha256.ToLowerInvariant())
    }
}
```

## 3. Gate seguinte — C4.2 referência oficial

Somente **após avaliar o resultado real de C4.1**:

1. confirmar as fontes oficiais aplicáveis de `TP_LEITO`/`CODLEITO`, seu esquema de arquivo e disponibilidade histórica 2017–2019;
2. identificar códigos/descrições reais e potencial mudança de classificação por competência;
3. materializar ou validar amostra controlada da referência, com fonte, versão, campos e hashes comprovados;
4. medir T29 sobre 35.518 linhas CNES/LT **por competência quando a referência assim exigir**, documentando exceções;
5. só então avaliar `REF_TIPO_LEITO.qvd` na extração QlikView 12.

A Fase III permanece `IN PROGRESS`. Não modificar os fatos/dimensões, arquivos acadêmicos aprovados ou dados de origem nesta etapa.
