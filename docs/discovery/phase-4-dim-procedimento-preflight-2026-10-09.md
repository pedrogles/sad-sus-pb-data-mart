# Fase IV — DIM_PROCEDIMENTO — preflight da hierarquia SIGTAP

**Data:** 09/10/2026  
**Branch:** `feat/phase-4-dim-procedimento`  
**Estado:** `READ_ONLY_HIERARCHY_PREFLIGHT_PENDING` — sem novos scripts de transformação, QVD ou PR.

## Contratos e entradas verificados

- `main` contém a integração PR #76 (squash `4f52bd7349819532cf73dfe36e3ead219614f338`). O usuário confirmou localmente `git switch main` seguido de `git pull --ff-only` até `4f52bd7`.
- Fase IV: **três** dimensões construídas, fisicamente auditadas e integradas: `DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`. Outras cinco pendentes. Primeira entrega acadêmica Capítulos 1–2 permanece fechada.
- `docs/academic/chapter-1-2-modeling.md` define `DIM_PROCEDIMENTO` com chave, **código, nome, descrição oficial, grupo, subgrupo e forma de organização**, preservando validade por competência. Não eliminar esses atributos silenciosamente para caber no staging atual.
- `docs/discovery/boundary-7-implementation-plan.md`: referência **competência-aware**, `%SK_PROCEDIMENTO = Hash128('PROC', PROC_REA, COMPETENCIA_REFERENCIA)`; relacionar `PROC_REA + competência RD` contra procedimento oficial da **mesma competência**. Preservar exceções, não filtrar códigos sem referência.
- `docs/discovery/phase-3-sigtap-proc-rea-implementation-2026-10-08.md`: **T27 PASS** empiricamente, 36 competências entre 201701–201912, 165.203 pares únicos `procedimento × mês` no SIGTAP, 566.672 RD cobertos, 0 unmatched; CSV candidato `cp1252` validado operacionalmente. Os atributos hierárquicos descritivos **não foram extraídos** no C3.4a/b.
- `EXTRACAO/ext_main.qvs` gera `EXTRACAO/QVD/REF_SIGTAP.qvd` com os campos de origem reais `SIGTAP_COMPETENCIA`, `SIGTAP_CO_PROCEDIMENTO`, `SIGTAP_NO_PROCEDIMENTO`, `SIGTAP_COMPETENCIA_CODIGO` e metadados; **não há nome oficial do grupo/subgrupo/forma de organização na carga atual**.

## Ponto de validação antes da dimensão

**FATO VERIFICADO EM DOCUMENTAÇÃO CANÔNICA:** a Discovery III-C3.2 já inspecionou quatro pacotes oficiais SIGTAP — `201701`, `201801`, `201901` e `201912` — e materializou inventário completo de seus membros `BASE/REFERENCIAS/sigtap_procedure_sample_members.csv`, total 348 linhas (87 arquivos em cada pacote), SHA-256 `110e9c22ed79cbab47e5c7726b9d19f9f2fe7117f7519e81d1319fca5583d0ad`. O inventário local contém `competence`, `zip_member`, `basename` e metadados do pacote. **Ainda não foi consultado nesta etapa para localizar as fontes hierárquicas.**

**HIPÓTESE DE MODELAGEM:** os pacotes podem conter tabelas oficiais de grupo/subgrupo/forma de organização e relacionamentos por competência. Os nomes dos arquivos, campos, layouts, cardinalidades e vínculos permanecem **a verificar**, e não devem ser inferidos de sufixos `_grupo` nem deduzidos apenas dos dígitos do `CO_PROCEDIMENTO`.

**DECISÃO PENDENTE:** identificar, inspecionar e validar fisicamente essas referências/relacionamentos nas competências requeridas, ou documentar uma solução parcial explicitamente aceita para atributos hierárquicos sem fonte. Não inventar valores nem preencher campos sem acordo explícito.

## Gate local — inventário SIGTAP, READ-ONLY / NO DOWNLOAD

Executar a partir da raiz do repositório no Windows, com Python 3 do venv. O script abaixo só lê o inventário local anterior e o cabeçalho de `REF_SIGTAP.qvd`; não abre ZIP, não descarrega dados, não escreve arquivos.

```powershell
@'
from pathlib import Path
import csv
import hashlib
import xml.etree.ElementTree as ET
from collections import Counter

p = Path("BASE/REFERENCIAS/sigtap_procedure_sample_members.csv")
expected_sha = "110e9c22ed79cbab47e5c7726b9d19f9f2fe7117f7519e81d1319fca5583d0ad"

if not p.is_file():
    raise RuntimeError("Inventario C3.2 local ausente; sem download nesta etapa")

raw = p.read_bytes()
sha = hashlib.sha256(raw).hexdigest()
print("INVENTARIO_SHA256=", sha)
if sha != expected_sha:
    raise RuntimeError("Hash C3.2 divergente; investigar antes de usar")

with p.open(encoding="utf-8-sig", newline="") as f:
    reader = csv.DictReader(f, delimiter=";")
    required = {"competence", "basename", "zip_member"}
    if not required.issubset(reader.fieldnames or []):
        raise RuntimeError(f"Colunas inesperadas: {reader.fieldnames}")
    rows = list(reader)

contagens = Counter(r["competence"] for r in rows)
print("TOTAL_MEMBROS=", len(rows))
print("MEMBROS_POR_COMPETENCIA=", dict(sorted(contagens.items())))
if len(rows) != 348 or contagens != Counter({
    "201701": 87, "201801": 87, "201901": 87, "201912": 87
}):
    raise RuntimeError("Contagens C3.2 nao reconciliadas")

for mes in sorted(contagens):
    nomes = sorted({
        r["basename"] for r in rows
        if r["competence"] == mes
        and any(padrao in r["basename"].lower() for padrao in (
            "grupo", "subgr", "forma", "organiz", "procedimento"
        ))
    })
    print("COMPETENCIA=", mes)
    print("CANDIDATOS_HIERARQUIA_E_PROCEDIMENTO=", nomes)
    print("CANDIDATOS_QTD=", len(nomes))

qvd = Path("EXTRACAO/QVD/REF_SIGTAP.qvd")
if not qvd.is_file():
    raise RuntimeError("REF_SIGTAP.qvd local ausente")

dados = qvd.read_bytes()
end_tag = b"</QvdTableHeader>"
if end_tag not in dados:
    raise RuntimeError("Cabecalho QVD SIGTAP ausente")

header = ET.fromstring(dados.split(end_tag, 1)[0] + end_tag)
def tags(nome):
    return [e.text for e in header.iter()
            if e.tag.rsplit("}", 1)[-1] == nome]

print("QVD_SIGTAP_REGISTROS=", tags("NoOfRecords"))
print("QVD_SIGTAP_CAMPOS=", tags("FieldName"))
print("QVD_SIGTAP_BYTES=", qvd.stat().st_size)
print("PREFLIGHT_SIGTAP_INVENTARIO_READ_ONLY_PASS")
'@ | .\.venv\Scripts\python.exe -
```

## Critério de continuidade

1. Confirmar hash e competência do inventário, registrar **nomes reais** dos arquivos candidatos, sem interpretar apenas pela nomenclatura.
2. Validar estrutura/linhas/layouts/referências por competência antes de extrair atributos de grupo/subgrupo/forma de organização; reusar scripts/padrões C3.2–C3.4, sem download em massa antes de uma discovery pontual.
3. Só depois especificar a materialização mínima de `DIM_PROCEDIMENTO` e testar sua cardinalidade/chave com as 165.203 linhas de referência e os 566.672 RD, preservando 0 unmatched T27.
4. Não implementar fatos, Link Table, PAINEL, nem reabrir Capítulos 1–2; `T29_HISTORICAL=NOT_APPROVED`.

**Status:** `IV-PROCEDIMENTO=PRECONDITION_SOURCE_DISCOVERY`; `PHASE_IV=IN_PROGRESS`; `PR=NONE`; `T27=PASS`.
