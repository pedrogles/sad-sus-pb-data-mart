# Fase IV — DIM_ESTABELECIMENTO — preflight histórico

**Data:** 09/10/2026  
**Branch:** `feat/phase-4-dim-estabelecimento`  
**Estado:** `READ_ONLY_SOURCE_PREFLIGHT_PENDING` — sem novo script de transformação, QVD ou PR.

## Estado de entrada verificado

- [PR #75](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/75) (DIM_MUNICIPIO) integrado na `main` via squash `7f796bed9aa3c41e8bf80fe0d24d493b8e66a1d9`.
- IV-MUNICIPIO obteve `PASS_LOCAL_QVD_HEADER_CHECKPOINT_RECONCILED`: 937 registros, 8 campos, 223 municípios PB, 714 códigos externos distintos, 5.202 RD externos preservados, 937 SK distintas, zero invalidos/sem correspondência; QVD SHA-256 `e6e347a1c88f7508ddc26b181342430bec6318bb03818c195a9b4707b8b0b49f`; CSV SHA-256 `9b8f987ea8b6133d7939e09d0b43a9b859b4b948ec15a3fa9ba4d9bde9074b49`.
- Fase IV: 2 dimensões integradas (Tempo, Município) e 6 pendentes. Fatos, Link Table e PAINEL não iniciados. `T29_HISTORICAL=NOT_APPROVED`.

## Contrato já aprovado (não alterar)

`docs/discovery/boundary-5-historization-role-playing.md`:
- `DIM_ESTABELECIMENTO` histórica mensal, **1 linha por CNES × competência**; `CNES` é identidade cadastral; versão é `CNES + competência`.
- **Não** aplicar estado cadastral posterior retroativamente; não comprimir intervalos (SCD2) na V1.
- Se nomes históricos não tiverem fonte comprovada na competência: **`NULL`**, sem backfill, forward fill ou substituição por nome corrente. Ausência documentada 201701–201705 não bloqueia a dimensão.

`docs/discovery/boundary-7-implementation-plan.md`:
- `%SK_ESTABELECIMENTO = Hash128('ESTAB', CNES, COMPETENCIA)`;
- fatos só relacionarão a versão de CNES correspondente à competência; T16 deve impedir join de versão futura.

**FATO VERIFICADO NO SCRIPT DO REPOSITÓRIO:** `EXTRACAO/ext_main.qvs` atualmente grava `SRC_CNES_ST.qvd` com `CNES`, `CODUFMUN`, `COD_CEP`, `CNPJ_MAN`, `VINC_SUS`, `TPGESTAO`, `TP_UNID`, `NATUREZA`, `NAT_JUR`, `COMPETEN` e metadados de origem, **não** carrega `NOME_FANTASIA`/`RAZAO_SOCIAL`. Testes Boundary 3 já documentaram 220.390 linhas, 6.822 CNES distintos, 36 competências e `CNES × competência` único no universo observado. Não inferir que nomes ausentes do staging também estejam necessariamente ausentes dos CSV brutos.

## Gate de origem dos atributos históricos — somente leitura

Antes de elaborar o include de `DIM_ESTABELECIMENTO`, inspecionar os **cabeçalhos reais** dos 36 `BASE/CONVERTIDA/ST/STPB*.csv`, sem ler dados sensíveis, para determinar se há nome/razão social e variações de esquema. Confrontar o achado com o staging QVD atual. Se existir fonte histórica oficial de nomes fora do staging, identificá-la e validar competência/proveniência antes de usar; não preencher silenciosamente.

Uma inspeção de cabeçalhos pode ser executada com Python padrão na raiz do projeto:
```powershell
@'
from pathlib import Path
import csv
from collections import Counter

arquivos = sorted(Path("BASE/CONVERTIDA/ST").glob("STPB*.csv"))
if len(arquivos) != 36:
    raise RuntimeError(f"Esperados 36 ST; encontrados {len(arquivos)}")

assinaturas = Counter()
for p in arquivos:
    with p.open("r", encoding="utf-8-sig", newline="") as f:
        cabecalho = next(csv.reader(f, delimiter=";"))
    assinatura = tuple(cabecalho)
    assinaturas[assinatura] += 1
    provaveis_nomes = [
        x for x in cabecalho
        if any(t in x.upper() for t in ("NOME", "FANT", "RAZAO", "RAZÃO", "RSOC"))
    ]
    print(p.name, "COLUNAS=", len(cabecalho), "CAMPOS_NOME=", provaveis_nomes)
    if p.name.startswith(("STPB1701", "STPB1705", "STPB1706", "STPB1912")):
        print("EXEMPLO_CABECALHO=", cabecalho)

print("ARQUIVOS=", len(arquivos))
print("SCHEMAS_DISTINTOS=", len(assinaturas))
for cab, qtd in assinaturas.items():
    print("SCHEMA_OCORRENCIAS=", qtd, "COLUNAS=", len(cab))
print("PREFLIGHT_HEADERS_READ_ONLY_CONCLUIDO")
'@ | .\.venv\Scripts\python.exe -
```

**Próxima decisão:** conferir saída real do preflight, localizar fontes aprovadas de nome histórico se existirem e então preparar o menor script `TRANSFORMACAO/transf_dim_estabelecimento.qvs`, com gate `CNES × competência=220390`, 36 competências e nenhuma versão futura aplicada. Nenhum código implementado neste documento.
