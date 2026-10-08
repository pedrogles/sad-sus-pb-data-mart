# Fase III-C3 — SIGTAP / PROC_REA — 08/10/2026

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** III — Extração / staging  
**Checkpoint:** III-C3 — Referência oficial de procedimentos  
**Status:** C3.1 PERFIL IMPLEMENTADO, EXECUÇÃO LOCAL PENDENTE; T27 NÃO AVALIADO

## 1. Contrato aprovado

Fontes canônicas: [Boundary 4](boundary-4-auxiliary-references.md), [Boundary 7](boundary-7-implementation-plan.md) e [Current State](../project/current-state.md).

**FATO VERIFICADO NA DOCUMENTAÇÃO DO PROJETO:**

- procedimento realizado: campo SIH/RD `PROC_REA`;
- códigos de procedimento observados na Discovery: largura de 10 dígitos;
- referência oficial: SIGTAP (Tabela de Procedimentos, Medicamentos e OPM do SUS);
- lookup deve respeitar **mesma competência** do RD: `PROC_REA + competência` contra SIGTAP;
- `DIM_PROCEDIMENTO` acadêmica mantém código, nome, descrição oficial, grupo, subgrupo e forma de organização;
- a arquitetura dimensional e a chave técnica previstas no Boundary 7 permanecem inalteradas;
- o inventário SIGTAP existente já encontrou **36/36 pacotes oficiais** `TabelaUnificada_YYYYMM*.zip` para 2017–2019, sem competências faltantes ou duplicadas.

Os resultados do inventário não provam a existência nem a estrutura dos TXT de procedimento dentro de cada pacote. Essas características dependem de inspeção física.

**DECISÃO PENDENTE:** nomes de membros ZIP, nomes de campos, layout posicional, regras de vigência, versões do procedimento, cobertura e exceções de `PROC_REA`. Nenhuma delas deve ser presumida pelo nome do ZIP.

## 2. C3.1 — perfil empírico dos códigos RD (READ-ONLY)

Implementação: `tools/profile_proc_rea.py`.

Entrada: **36 CSVs locais** `BASE/CONVERTIDA/RD/RDPBYYMM.csv`, competências 201701–201912.

O script:

1. valida quantidade de arquivos, formato de nomes, exclusividade e cobertura das 36 competências;
2. exige o total RD já reconciliado de **566.672 linhas**;
3. lê `PROC_REA` **como texto do CSV**, sem converter em número e sem remover zeros, espaços ou outro caractere;
4. mede códigos brutos distintos, ocorrências, comprimento, caracteres, vazios, zeros à esquerda, primeira/última competência e meses observados;
5. registra volumes e códigos distintos por competência mensal;
6. gera SHA-256 das saídas do perfil e um manifesto JSON para reconciliação posterior.

Classificações do perfil:

- `TEN_ASCII_DIGITS`: exatamente 10 dígitos ASCII;
- `OTHER_LENGTH_ASCII_DIGITS`: apenas dígitos ASCII, com comprimento diferente de 10;
- `HAS_WHITESPACE`;
- `ASCII_ALPHANUMERIC`;
- `OTHER`;
- `EMPTY`.

O script não aplica normalização nem faz lookup. Se encontrar códigos fora do padrão de 10 dígitos, preserva o perfil completo e retorna **REVIEW**, sem concluir falsamente a integridade de formato.

Saídas **locais/ignoradas pelo Git**:

- `BASE/REFERENCIAS/proc_rea_raw_profile.csv`;
- `BASE/REFERENCIAS/proc_rea_monthly_profile.csv`;
- `BASE/REFERENCIAS/proc_rea_profile_summary.json`.

### Execução local

Na raiz do repositório:

~~~powershell
git pull origin main
.\.venv\Scripts\python.exe .\tools\profile_proc_rea.py
~~~

Depois:

~~~powershell
Get-Content .\BASE\REFERENCIAS\proc_rea_profile_summary.json -Encoding UTF8
~~~

Reconciliação dos hashes:

~~~powershell
$m = Get-Content .\BASE\REFERENCIAS\proc_rea_profile_summary.json -Raw -Encoding UTF8 | ConvertFrom-Json
$paths = @($m.outputs.raw_profile, $m.outputs.monthly_profile)
$paths | ForEach-Object {
    $actual = (Get-FileHash $_.path -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{
        Path = $_.path
        Rows = $_.rows
        HashMatch = ($actual -eq $_.sha256.ToLowerInvariant())
    }
}
~~~

### Gate C3.1

**Esperado conforme a fase anterior:** `RD_FILES=36`, `RD_ROWS=566672`, `RD_COMPETENCES=36` e hashes das duas saídas com `HashMatch=True`.

**A verificar a partir dos dados reais:** quantidade de códigos distintos, comprimento/caracteres, presença de zeros à esquerda, vazios, variação mensal e `VERDICT`. Não registrar `PASS` antes da execução local.

O status C3.1 **não é** o status T27: `T27_COVERAGE=NOT_EVALUATED` até o lookup oficial por competência.

## 3. Sequência prevista depois do C3.1

### C3.2 — inspeção controlada dos pacotes SIGTAP

Reutilizar `BASE/REFERENCIAS/sigtap_package_inventory_2017_2019.csv`, já materializado no III-C2. Inspecionar **amostra pequena e representativa** do conteúdo dos ZIPs para identificar os arquivos reais do procedimento e respectivos layouts. Não supor que `tb_cid` sirva como referência de procedimento e não baixar 36 pacotes sem a inspeção prévia.

### C3.3 — materialização histórica e validação de cobertura

Depois de confirmar fisicamente os membros/layouts, materializar referências por competência; medir códigos `PROC_REA` válidos/não encontrados para cada mês e produzir lista de exceções. Preservar o código real se não houver descrição ou correspondência, sem fabricar valores.

### C3.4 — staging QlikView 12

Somente após o gate de referência e cobertura: integrar carga aos scripts externos do `EXT.qvw`, produzir `REF_SIGTAP.qvd` e checkpoint parcial sem construir fatos/dimensões no estágio de Extração.

## 4. Limites

- Não alterar C2/T28, já fechados como **PASS**.
- Não reconstruir nem modificar os QVDs de RD/LT/ST/IBGE.
- Não versionar CSVs do perfil, ZIPs oficiais, TXT extraídos nem QVDs.
- Não encerrar a Fase III apenas com C3.1.
- Não alterar as decisões acadêmicas da primeira entrega.
