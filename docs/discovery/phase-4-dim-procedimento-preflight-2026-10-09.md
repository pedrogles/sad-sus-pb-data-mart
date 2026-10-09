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

## Resultado do inventário C3.2 — execução local 09/10/2026

**FATO VERIFICADO — PowerShell/Python fornecido pelo responsável:**

- Branch local `feat/phase-4-dim-procedimento` criada por checkout de `origin/feat/phase-4-dim-procedimento`, após `git fetch origin`.
- `sigtap_procedure_sample_members.csv` presente, SHA-256 **`110e9c22ed79cbab47e5c7726b9d19f9f2fe7117f7519e81d1319fca5583d0ad`** igual ao registrado na Discovery III-C3.2.
- Inventário tem **348 membros**, exatamente **87 por competência**: `201701`, `201801`, `201901`, `201912`. `PREFLIGHT_SIGTAP_READ_ONLY_PASS` emitido.
- Os quatro meses contêm os mesmos **seis candidatos diretos** à hierarquia (nomes reais, ainda não layout/conteúdo validado):
  - `tb_grupo.txt` / `tb_grupo_layout.txt`;
  - `tb_sub_grupo.txt` / `tb_sub_grupo_layout.txt`;
  - `tb_forma_organizacao.txt` / `tb_forma_organizacao_layout.txt`.
- Também existem `tb_procedimento.txt` / `tb_procedimento_layout.txt` e várias relações `rl_procedimento_*`; a lista de nomes **não** prova os campos, cardinalidades nem a regra de associação ao procedimento.

**Interpretação estrita:** preflight de existência e proveniência dos **candidatos** passou, sem nenhum download na execução, sem análise do interior dos seis arquivos e sem confirmar descrições ou chaves. Não afirmar que a hierarquia SIGTAP foi materializada, nem que a `DIM_PROCEDIMENTO` está pronta.

## Próximo Boundary — inspeção física controlada de seis arquivos em quatro ZIPs

**Implementação preparada, AINDA NÃO EXECUTADA no Windows:** `tools/inspect_sigtap_hierarchy_sample.py`.

- Reutiliza `tools/inspect_sigtap_procedure_sample.py` e `tools/materialize_sigtap_procedure_sample.py` (caminho oficial FTP, `read_inventory`, `load_previous_sample`, `find_exact_member`, `receive_zip`).
- Obtém **apenas os 4 ZIPs anteriores**, cada um em `TemporaryDirectory`; compara SHA-256/tamanho com C3.2 e verifica CRC de ZIP. Eles são baixados novamente apenas porque as cópias da inspeção anterior eram temporárias e foram descartadas. Não baixa 36 pacotes.
- Inspeciona **somente** os seis membros exatos por competência. Cada membro é validado contra `sigtap_procedure_sample_members.csv` (nome, tamanho, CRC); a inspeção lê o layout real e mostra nomes de campos, posição inicial/final, tipo e primeiras duas linhas de cada tabela.
- Faz perfil de número de linhas, larguras físicas e preenchimento de campos `CO_*` observados no layout. O texto `cp1252` é **candidato apenas para prévias**; interpretação histórica e relacionamento oficial continuam pendentes.
- Nenhum CSV/QVD/arquivo derivado persistente é gerado; sem alteração do histórico SIH, do REF_SIGTAP.qvd, da modelagem acadêmica, dos fatos ou do QlikView.
- `VERDICT=PASS_SAMPLE_STRUCTURE_ONLY` **não** aprova joins, encoding final ou 36 competências; exige revisão das saídas reais.

### Execução do teste físico controlado

Na raiz do repositório (branch `feat/phase-4-dim-procedimento`), após `git pull --ff-only`:

```powershell
.\.venv\Scripts\python.exe .\tools\inspect_sigtap_hierarchy_sample.py
```

**Esperado somente se a fonte corresponder à hipótese de layout:** `INVENTORY_SHA_MATCH=True`, `MEMBERS_INSPECTED=24`, `INTEGRITY_ERRORS=0`, `VERDICT=PASS_SAMPLE_STRUCTURE_ONLY`, `RELATIONAL_JOINS_AND_ENCODING=NOT_APPROVED`. Se erro de layout, chave ou ZIP, interromper e inspecionar a mensagem real sem tentar completar/renomear campos.

**DECISÃO PENDENTE após o teste:** definir a identificação da relação `procedimento → grupo → subgrupo → forma de organização` por competência, a partir dos nomes/posições reais observados nas tabelas e nos layouts. Só então expandir a validação às 36 competências e preparar transformação QlikView `DIM_PROCEDIMENTO`. `IV-PROCEDIMENTO=SAMPLE_PHYSICAL_LAYOUT_GATE_PENDING`; `T27=PASS`; `PHASE_IV=IN_PROGRESS`.

## Boundary — inspeção física controlada de 4 competências (PASS da ESTRUTURA)

**FATO VERIFICADO — log local enviado em 09/10/2026** (`git pull --ff-only` até `f6f218c` e execução de `tools/inspect_sigtap_hierarchy_sample.py`):

- `INVENTORY_SHA_MATCH=True`, `INVENTORY_MEMBERS=348`, `SAMPLE_COMPETENCES=201701,201801,201901,201912`.
- Apenas os 4 ZIPs amostrais foram recuperados temporariamente, com SHA-256/tamanho concordantes com C3.2 e CRC validado pelo script; `PERSISTENT_OUTPUTS=NONE`, `FULL_36_PACKAGES_DOWNLOADED=False`.
- `MEMBERS_INSPECTED=24`, `INTEGRITY_ERRORS=0`, `VERDICT=PASS_SAMPLE_STRUCTURE_ONLY`, `RELATIONAL_JOINS_AND_ENCODING=NOT_APPROVED`; `T27_HISTORICAL_GATE=PREVIOUS_PASS_NOT_RETESTED`.
- Layouts idênticos nas 4 competências para cada tabela: `LAYOUT_SIGNATURES=1` para `tb_grupo`, `tb_sub_grupo`, `tb_forma_organizacao`, nenhum comprimento incorreto ou campo `CO_*` vazio.
- **Grupo**: 8 linhas/mês, 108 bytes, campos `CO_GRUPO` (1–2), `NO_GRUPO` (3–102), `DT_COMPETENCIA` (103–108).
- **Subgrupo**: 59 linhas/mês, 110 bytes, campos `CO_GRUPO` (1–2), `CO_SUB_GRUPO` (3–4), `NO_SUB_GRUPO` (5–104), `DT_COMPETENCIA` (105–110).
- **Forma de organização**: 382/384/385/386 linhas em 201701/201801/201901/201912, 112 bytes, campos `CO_GRUPO` (1–2), `CO_SUB_GRUPO` (3–4), `CO_FORMA_ORGANIZACAO` (5–6), `NO_FORMA_ORGANIZACAO` (7–106), `DT_COMPETENCIA` (107–112).
- Exemplos `cp1252` legíveis na amostra incluem `Ações de promoção e prevenção em saúde`, `Consultas / Atendimentos / Acompanhamentos`, `Educação em saúde`; são **prévias**, não uma aprovação de encoding integral.
- SHA-256 dos 3 layouts observados no log, iguais nas quatro competências: grupo `3bf6a61194eedbb404b091ba966e6f6c97fe0c88b78c59b9a867177289e16c07`; subgrupo `3eb16c6563481e9823a8dd1fda30ab1fc0f185d2d91ecfa6a2274eeac5179965`; forma `87e03373d59641ed3814bf81cb315532aa6edb50a30ee2412f2906cbded63ae5`.

**HIPÓTESE DE RELACIONAMENTO A TESTAR:** em `CO_PROCEDIMENTO` (10 posições; fonte física SIGTAP C3.3a), prefixos de 2, 4 e 6 dígitos identificam, respectivamente, grupo, subgrupo e forma. Tal regra **não está provada neste log**. Validar por lookup *na mesma competência*, com chaves inequívocas (`AAAAMM|GG`, `AAAAMM|GGSS`, `AAAAMM|GGSSFF`), unicidade na tabela de destino, cobertura de todos os procedimentos da amostra e consistência pai-filho. Não assumir que a contagem de grupos/subgrupos/formas prova a ligação aos procedimentos.

**DECISÃO PENDENTE:** aprovar ou rejeitar a interpretação `cp1252` para os **três nomes descritivos** depois da inspeção textual diversificada; validar todas as 36 competências e só então criar dimensões/QVDs. `IV-PROCEDIMENTO=SAMPLE_STRUCTURE_PASS_JOIN_PILOT_PENDING`; `T27=PASS_ANTERIOR_SEM_RETESTE`; `PHASE_IV=IN_PROGRESS`.

## Gate relacional amostral SIGTAP — código preparado, execução local pendente

**Implementação preparada (NÃO EXECUTADA):** `tools/validate_sigtap_hierarchy_relational_pilot.py`. Não muda os scripts existentes de extração ou transformação, não grava QVD/CSV e não cria a dimensão.

O script verifica novamente a proveniência do inventário (SHA C3.2, 348 membros), recupera os mesmos **4 ZIPs de referência em arquivos temporários**, confere tamanho, SHA-256 e CRC, e relê os 6 membros oficiais de hierarquia por pacote. Para os 4 meses, confere ainda os SHA-256 dos 3 layouts já observados (grupo/subgrupo/forma), decodifica suas chaves como ASCII e confere `DT_COMPETENCIA` contra o mês do pacote, chaves únicas e descrições não vazias. A conversão `cp1252` de descrições serve apenas à visualização amostral e continua como hipótese.

Em paralelo, lê `BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM/tb_procedimento.txt` **já presente localmente no histórico C3.3b.1**; antes de processar, compara SHA-256 de dado/layout e quantidade de linhas com `sigtap_procedure_history_manifest.json` e verifica `CO_PROCEDIMENTO` ASCII de 10 dígitos, competência do próprio registro e unicidade. Total esperado da amostra segundo C3.3a: 4542 + 4587 + 4609 + 4624 = **18.362** pares procedimento×competência.

**Hipótese específica em teste** (não é regra aprovada): `CO_PROCEDIMENTO[:2]` deve corresponder a `CO_GRUPO`, `[:4]` a `CO_GRUPO + CO_SUB_GRUPO`, `[:6]` a `CO_GRUPO + CO_SUB_GRUPO + CO_FORMA_ORGANIZACAO`. A correspondência sempre é feita **dentro do mesmo mês**, também conferindo a integridade subgrupo→grupo e forma→subgrupo/grupo.

O piloto emite contadores `UNMATCHED_PROCEDURE_GROUP`, `UNMATCHED_PROCEDURE_SUBGROUP`, `UNMATCHED_PROCEDURE_FORM` e `PARENT_MISSING`, além de amostras de exceções (sem exclusão de procedimentos). Saída `PASS_4_MONTH_HIERARCHY_RELATIONAL_PILOT_ONLY` exige **18.362 procedimentos observados e 0 unmatched / órfãos**, sem implicar cobertura de 36 competências ou aprovação de encoding.

### Executar no Windows (sem QlikView; sem saída persistente)

```powershell
git pull --ff-only
.\.venv\Scripts\python.exe .\tools\validate_sigtap_hierarchy_relational_pilot.py
```

**Não iniciar download em massa dos 36 pacotes ainda.** Se houver exceções, conferir os códigos reais, layout e competência antes de alterar a hipótese; não corrigir inventando joins. Se o piloto passar, preparar gate read-only abrangendo os 36 meses e perfis de descrição, e somente depois planejar aquisição/staging dos atributos hierárquicos e a `DIM_PROCEDIMENTO`.

**Estado:** `IV-PROCEDIMENTO=SAMPLE_STRUCTURE_PASS_RELATIONAL_PILOT_CODE_READY_QV_NOT_STARTED`; `T27=PREVIOUS_PASS`; `PHASE_IV=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.

## Gate IV-PROCEDIMENTO — piloto relacional 4 competências PASS (09/10/2026)

**FATO VERIFICADO — execução local informada pelo responsável**, após `git pull --ff-only` da branch até `f72993f`, com `tools/validate_sigtap_hierarchy_relational_pilot.py`:

- `INVENTORY_SHA_MATCH=True`, `INVENTORY_MEMBERS=348`; 4 competências `201701`, `201801`, `201901`, `201912`; `PERSISTENT_OUTPUTS=NONE`.
- Totais por mês: `201701=4542`, `201801=4587`, `201901=4609`, `201912=4624`; `PILOT_PROCEDURES=18362`.
- `UNMATCHED_PROCEDURE_GROUP=0`, `UNMATCHED_PROCEDURE_SUBGROUP=0`, `UNMATCHED_PROCEDURE_FORM=0`, `PARENT_MISSING={}`.
- `VERDICT=PASS_4_MONTH_HIERARCHY_RELATIONAL_PILOT_ONLY`, `FULL_36_MONTH_HIERARCHY_GATE=NOT_EVALUATED`, `DESCRIPTION_ENCODING_APPROVAL=NOT_EVALUATED`.
- Fontes hierárquicas dos mesmos meses: grupo 8/mês, subgrupo 59/mês, formas 382/384/385/386, integridade de código/competência, hash de layout estável da inspeção anterior e nenhuma exceção mostrada.
- Prefixos observados de `CO_PROCEDIMENTO`: os **2**, **4** e **6** dígitos iniciais resolveram respectivamente as chaves `CO_GRUPO`, `CO_GRUPO+CO_SUB_GRUPO` e `CO_GRUPO+CO_SUB_GRUPO+CO_FORMA_ORGANIZACAO` no mesmo mês; sem chaves pai órfãs nesta amostra.

**Conclusão delimitada:** **PASS RELACIONAL AMOSTRAL** dos 18.362 pares procedimento×competência. A interpretação dos prefixos tem agora sustentação empírica nos 4 meses testados, **não é uma regra histórica aprovada para todos os 36**; os nomes `cp1252` apresentados são somente prévias, não prova da codificação de todos os textos. O teste anterior T27 completo SIH/RD×SIGTAP permanece PASS, não foi reexecutado neste piloto. Nenhum dado histórico, QVD, fato, Link Table ou dimensão foi alterado.

**Próximo gate:** adquirir de forma limitada e verificável as **seis tabelas/layouts de hierarquia dos 36 pacotes históricos já enumerados**, usando os hashes e contagens do manifesto C3.3b.1 por competência; confrontar cada pacote, layout, unicidade, competência, pais e todos os 165.203 pares procedimento×competência. Persistir somente os seis membros originais por mês e manifesto local depois de todos os 36 passes; não gerar QVD ou alterar referências existentes. Verificar encoding com amostra diversificada separadamente.

**Status:** `IV-PROCEDIMENTO=FOUR_MONTH_RELATIONAL_PILOT_PASS_FULL_36_PENDING`; `T27=PASS_ANTERIOR`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IV=IN_PROGRESS`.

## Boundary — validação histórica SIGTAP de 36 competências, código preparado

**Entrada:** o piloto 4/36 de hierarquia passou com 18.362 procedimentos e zero ausências nos 3 níveis, conforme seção anterior. Esta evidência sustenta expandir a verificação a todo o período `201701–201912`, mas não prova previamente o resultado dos 32 meses não inspecionados.

**Script versionado, AINDA NÃO EXECUTADO:** `tools/materialize_sigtap_hierarchy_history.py`.

- Modo inicial recomendado **`--validate-only`**: baixa temporariamente os 36 ZIPs oficiais já enumerados no inventário C2.3, **somente para inspecionar** 6 membros hierárquicos exatos por pacote (3 dados e 3 layouts); **não grava TXT/CSV/QVD/manifesto**. Os ZIPs temporários são descartados após cada competência.
- Confere por competência a correspondência exata de nome/tamanho/SHA-256 do ZIP com `sigtap_procedure_history_manifest.json` (C3.3b.1 PASS), CRC do ZIP, ausência de membros homônimos, limite de tamanho por membro, posições/nome dos layouts de grupo, subgrupo e forma contra SHA-256 dos 4 meses já inspecionados. Qualquer drift causa `RuntimeError` e aborta sem escrita.
- Reutiliza os 36 `tb_procedimento.txt` **já materializados** em `BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM`, verifica seus hashes de dados/layout com o manifesto anterior, códigos/competência e unicidade. O total da referência histórica deve ser **165.203 pares procedimento×competência**, não 165.203 procedimentos globalmente distintos.
- Avalia 36× grupo/subgrupo/forma: chaves observadas, `DT_COMPETENCIA` igual ao snapshot, nenhuma chave repetida, descrição não vazia, 0 subgrupos sem grupo, 0 formas sem subgrupo/grupo, e cobertura exata dos 165.203 procedimentos pelos prefixos de 2/4/6 dígitos **no mesmo mês**.
- Quando o `--validate-only` obtiver `VERDICT=PASS_36_MONTH_RELATIONAL_VALIDATION_ONLY` com `MONTHS_VALIDATED=36`, `MEMBERS_VALIDATED=216`, `PROCEDURES_COVERED=165203`, `UNMATCHED_ALL_LEVELS=0`, apresentar saída para revisão. **Não rodar sem a flag ainda**: a opção sem flag repete os controles e, se todos passarem, grava exclusivamente os 216 arquivos brutos de hierarquia ao lado dos procedimentos já versionados localmente (sem sobrescrever conteúdo divergente), mais manifesto `BASE/REFERENCIAS/sigtap_hierarchy_history_manifest.json`; nunca grava QVD nem texto convertido/descrições derivadas.
- O manifesto futuro terá estado `PASS` **apenas para integridade física e relações de 36 meses**; `description_encoding=CP1252_CANDIDATE_AWAITING_DESCRIPTIVE_AUDIT`, `t27_retested=false`, `t29_historical=NOT_APPROVED`, `qvd_generated=false`.
- O uso de `cp1252` nos perfis de descrição é uma interpretação provisória, herdada da leitura candidata dos TXT; **a aprovação textual dos três níveis ainda depende de auditoria de amostras diversificadas e da análise de codificação**, separada da integridade relacional. Não inventar descrições ou relações.

### Comando de próximo gate (Windows, raiz do repo)

```powershell
git pull --ff-only
.\.venv\Scripts\python.exe .\tools\materialize_sigtap_hierarchy_history.py --validate-only
```

**Ponto de decisão:** se houver `RuntimeError` ou `VERDICT` ausente, investigar o mês/arquivo real sem materializar. Se todas as 36 competências passarem, registrar os contadores, hashes relevantes e decidir a materialização controlada. Não iniciar a transformação dimensional/QLIK antes da auditoria da referência hierárquica e do encoding.

**Status:** `IV-PROCEDIMENTO=FOUR_MONTH_RELATIONAL_PASS_FULL_36_VALIDATOR_READY_NOT_RUN`; `DIM_PROCEDIMENTO_QVD=NOT_STARTED`; `PHASE_IV=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.

## Boundary — validação relacional integral de 36 competências PASS / sem persistência (09/10/2026)

**FATO VERIFICADO — log Python local enviado pelo responsável do projeto:**

- `git pull --ff-only` atualizou a branch `feat/phase-4-dim-procedimento` até `d4743c3`, incluindo `tools/materialize_sigtap_hierarchy_history.py`.
- Execução **exclusivamente** com `--validate-only`: `PROCEDURE_HISTORY_SHA_AND_MONTH_CHECK=PASS`, `PROCEDURE_HISTORY_ROWS=165203`, `MODE=CONTROLLED_SIGTAP_HIERARCHY_36_MONTH_HISTORY`, `COMPETENCES=36`, `ONLY_6_FILES_PER_PACKAGE=True`, `VALIDATE_ONLY=True`, `T29_HISTORICAL=NOT_APPROVED`.
- O log contém uma linha de cobertura `[AAAAMM]` para **cada mês de 201701 a 201912**, todas com `UNMATCHED_GROUP=0 UNMATCHED_SUBGROUP=0 UNMATCHED_FORM=0 PARENTS=0`. 8 grupos e 59 subgrupos por mês; formas de organização variaram entre 382–386 nesta série.
- Totais finais: **`MONTHS_VALIDATED=36`**, **`MEMBERS_VALIDATED=216`**, **`PROCEDURES_COVERED=165203`**, **`UNMATCHED_ALL_LEVELS=0`**, **`PERSISTENT_OUTPUTS=NONE`**, **`VERDICT=PASS_36_MONTH_RELATIONAL_VALIDATION_ONLY`**.
- Cada ZIP de fonte foi comparado por hash e tamanho ao manifesto histórico da Fase III (e CRC no ZIP), com leitura dos 6 membros hierárquicos exatos, layout SHA-256 estável, códigos/layouts validados, chave e competência sem duplicação, subgrupo→grupo e forma→subgrupo/grupo sem órfãos. Os 36 `tb_procedimento.txt` preexistentes foram lidos com reconciliação de hash/competência conforme o script. O console comprova o veredito do script, mas não é auditoria independente dos arquivos binários do ZIP.
- **Ressalva importante de proveniência:** para a **competência 201808**, o pacote do inventário e do log é `TabelaUnificada_201808_v2102261143.zip` (sufixo de versão com data em 2021). Esse ZIP tem competência interna compatível e foi validado contra o manifesto, porém a existência de uma versão posterior **não prova que o conteúdo era publicado exatamente assim em 2018**. Preservar nome/hash de proveniência e manter `T29_HISTORICAL=NOT_APPROVED`, sem atribuir validade normativa retroativa.
- Nenhum TXT hierárquico foi materializado ainda; o script `--validate-only` baixou ZIPs apenas temporariamente, sem arquivos persistentes, sem QVD, sem alteração nas dimensões integradas ou nos fatos.

**VEREDITO LIMITADO:** `IV-PROCEDIMENTO=PASS_36_MONTH_RELATIONAL_VALIDATION_ONLY`, correspondência exata 2/4/6 dígitos e integridade pai-filho **demonstradas para o corpus oficial de 36 meses usado no projeto**, sem generalizar para todas as versões normativas possíveis. **Codificação de `NO_GRUPO`, `NO_SUB_GRUPO` e `NO_FORMA_ORGANIZACAO` não foi homologada como texto descritivo oficial**: `cp1252` permanece candidato de decodificação a inspecionar.

**Próximo gate:** reavaliar o script já existente de materialização (`tools/materialize_sigtap_hierarchy_history.py`) e usar a variante com consentimento explícito de escrita SOMENTE para preservar os 216 membros originais em `BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM` e manifesto local, sem sobrescrever divergências. Após confirmação física dos hashes dos 216 membros persistidos, auditar o encoding dos nomes descritivos e preparar atualização controlada do staging de referência SIGTAP/QlikView, mantendo `T27=PASS_ANTERIOR`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IV=IN_PROGRESS`. Não gerar `DIM_PROCEDIMENTO.qvd` antes da prova dos textos.


## Decisão operacional após o PASS 36× — materialização controlada autorizável

**Revisão estática do script após receber o PASS de 36 competências:**

- A opção de gravação foi tornada **explicitamente opt-in**: `tools/materialize_sigtap_hierarchy_history.py` agora exige um dos parâmetros mutuamente exclusivos `--validate-only` ou **`--materialize`**. Sem parâmetro a execução falha sem baixar nem gravar.
- Na opção `--materialize`, **todas as 36 competências/165.203 procedimentos/216 arquivos** são baixados em ZIPs temporários e validados contra C3.3b.1, inclusive CRC/sha/tamanho, layouts e relacionamentos, **antes de qualquer write persistente**. O script também pré-verifica cada destino local contra o hash esperado, recusando sobrescrever conteúdo divergente, e verifica o manifesto existente antes de qualquer escrita.
- Só grava o original de 3 tabelas + 3 layouts por mês em `BASE/REFERENCIAS/SIGTAP/PROCEDIMENTO/YYYYMM` e o manifesto `BASE/REFERENCIAS/sigtap_hierarchy_history_manifest.json` (local/ignorado pelo Git). Não altera `tb_procedimento`, `EXTRACAO/QVD`, `TRANSFORMACAO/QVD`, fatos, Link Table ou modelos acadêmicos.
- Criado `tools/audit_sigtap_hierarchy_history.py`, auditor **independente e somente leitura**: verifica schema do manifesto, 36 meses, 165203 procedimento×mês, 216 nomes/paths únicos, tamanho e **SHA-256 de cada arquivo em disco**, e retorna `VERDICT=PASS_LOCAL_216_HIERARCHY_FILES_SHA_RECONCILED` apenas com todos os gates.
- **Limite conhecido:** erro de sistema de arquivos durante a escrita pode deixar subconjunto dos 216 membros sem manifesto; nesse caso registrar os artefatos presentes e reexecutar após correção, sem apagar ou sobrescrever fontes divergentes. Não declarar PASS sem manifesto e audit read-only posterior.
- Auditoria descritiva de `cp1252`, vigência T29 e transformação QlikView seguem **pendentes**. O pacote histórico de `201808` com sufixo `v2102261143` foi preservado como evidência de versão retrospectiva, não prova de vigência normativa publicada em 2018.

### Próximo comando local — materialização autorizada após validação 36×

Na branch `feat/phase-4-dim-procedimento`, com working tree limpo, aplicar `git pull --ff-only` e depois:

```powershell
.\.venv\Scripts\python.exe .\tools\materialize_sigtap_hierarchy_history.py --materialize
if ($LASTEXITCODE -ne 0) { throw "Materializacao hierarquica falhou" }
.\.venv\Scripts\python.exe .\tools\audit_sigtap_hierarchy_history.py
if ($LASTEXITCODE -ne 0) { throw "Auditoria SHA hierarquica falhou" }
```

**Status até receber essa saída:** `IV-PROCEDIMENTO=FULL_36_RELATIONAL_VALIDATION_ONLY_PASS_MATERIALIZATION_PENDING`; `DIM_PROCEDIMENTO_QVD=NOT_STARTED`; `T27=PASS_ANTERIOR`; `T29=NOT_APPROVED`; `PHASE_IV=IN_PROGRESS`.

## Gate IV-PROCEDIMENTO — 216 membros materializados e auditados (09/10/2026)

**FATO VERIFICADO — log Windows/Python do responsável, após fast-forward `d4743c3..fb81676`:**

1. Executou `tools/materialize_sigtap_hierarchy_history.py --materialize` (opção de escrita explicitamente autorizada). A reconciliação inicial mostrou `PROCEDURE_HISTORY_SHA_AND_MONTH_CHECK=PASS`, `PROCEDURE_HISTORY_ROWS=165203`, `COMPETENCES=36`, `VALIDATE_ONLY=False` e `T29_HISTORICAL=NOT_APPROVED`.
2. Cada uma das **36 competências 201701–201912** mostrou `UNMATCHED_GROUP=0 UNMATCHED_SUBGROUP=0 UNMATCHED_FORM=0 PARENTS=0`; 8 grupos e 59 subgrupos por mês e formas variando de 382 a 386. O código validou o ZIP oficial da competência contra SHA-256 e tamanho de C3.3b.1, CRC, o layout e cobertura por prefixos na **mesma competência** antes da gravação.
3. Saída final da materialização: `MONTHS_VALIDATED=36`, `MEMBERS_VALIDATED=216`, `PROCEDURES_COVERED=165203`, `UNMATCHED_ALL_LEVELS=0`, `NEW_MEMBERS_MATERIALIZED=216`, `MANIFEST=BASE\\REFERENCIAS\\sigtap_hierarchy_history_manifest.json`, `MANIFEST_SHA256=362301077a9823eca5e05362825b31471e0604bc4a9e3d308107252308f09ff5`, `DESCRIPTION_ENCODING=REVIEW_PENDING` e `VERDICT=PASS_36_MONTH_HIERARCHY_PHYSICAL_AND_RELATIONAL`.
4. Em seguida, executou **`tools/audit_sigtap_hierarchy_history.py`**, auditor independente/read-only. Obteve o **mesmo SHA-256 do manifesto** `362301077a9823eca5e05362825b31471e0604bc4a9e3d308107252308f09ff5`, `COMPETENCES_VERIFIED=36`, `FILES_VERIFIED=216`, `PROCEDURES_RECONCILED=165203`, `UNMATCHED_ALL_LEVELS=0`, `FILES_TOTAL_BYTES=1863390`, `DESCRIPTION_ENCODING=NOT_APPROVED`, `T29_HISTORICAL=NOT_APPROVED`, `QVD_GENERATED=False`, `VERDICT=PASS_LOCAL_216_HIERARCHY_FILES_SHA_RECONCILED`. O retorno não acionou o `throw` PowerShell.
5. Os **216 originais** consistem em `tb_grupo[,_layout].txt`, `tb_sub_grupo[,_layout].txt` e `tb_forma_organizacao[,_layout].txt` para 36 competências, ao lado de `tb_procedimento.txt` já existente. Os arquivos e o manifesto de origem são **locais, ignorados pelo Git**; **nenhum QVD/dimensão nova foi produzido**.

**VEREDITO FORMAL:** `IV-PROCEDIMENTO=PASS_36_MONTH_HIERARCHY_PHYSICAL_AND_RELATIONAL_SHA_RECONCILED`. Esta conclusão combina correspondência por competência, 216 membros persistidos, controle de proveniência e hashes independentes. **Não abrange** aprovação do charset das descrições `NO_GRUPO`, `NO_SUB_GRUPO`, `NO_FORMA_ORGANIZACAO`, nem vigência normativa histórica T29. A origem `TabelaUnificada_201808_v2102261143.zip` continua exigindo ressalva de versão retrospectiva.

**Próximo gate:** auditar as descrições **no corpus local de 36 competências já persistido**, com leitura estrita `cp1252` como candidato, inspeção de bytes, caracteres de controle, sequências suspeitas de mojibake, diferenças de grafia/acentos e amostras diversificadas para revisão humana. Não criar conteúdo derivado, QVD ou expandir a aquisição antes dessa validação.

**Estado:** `PHASE_IV=IN_PROGRESS`, 3 de 8 dimensões integradas; `DIM_PROCEDIMENTO=NOT_STARTED`; `T27=PASS_ANTERIOR`; `T29_HISTORICAL=NOT_APPROVED`; `FACTS_AND_LINK_TABLE=NOT_STARTED`.

## Gate textual SIGTAP — auditoria somente leitura preparada, sem execução local

Após a materialização dos 216 membros e a reconciliação SHA integral **PASS**, foi acrescentado o script versionável **`tools/audit_sigtap_hierarchy_descriptions.py`**. **O teste ainda não foi executado** nesta etapa.

**Contrato:**
- Primeiro chama o auditor independente preexistente `audit_sigtap_hierarchy_history.py` para exigir manifesto e **216 SHA-256** íntegros;
- lê de disco os dados e layouts das **36 competências × 3 níveis**, inspeciona `NO_GRUPO`, `NO_SUB_GRUPO`, `NO_FORMA_ORGANIZACAO` nas posições reais de layout verificadas por hash, e reconcilia contagens de cada mês com `records_by_month` do manifesto;
- exige `CO_*` numéricos ASCII, chaves sem duplicação e `DT_COMPETENCIA` do próprio mês, sem usar tabela de 2019 para nome de 2017;
- testa decodificação **estrita `cp1252`**, nomes vazios, caracteres de controle, padrões de *mojibake* e quantidade de registros com bytes acima de 0x7F compatíveis ou incompatíveis com UTF-8 estrito;
- apresenta até 8 amostras acentuadas únicas por nível, distribuídas nos meses `201701`, `201801`, `201901`, `201912`, e quantidade de chaves cujas descrições mudam entre competências, **sem tratar alterações históricas como erros automaticamente**;
- nenhuma escrita de dados, CSV, QVD, manifesto ou modificação no repositório pela execução;
- `VERDICT=PASS_CP1252_TEXT_SANITY_CANDIDATE_ONLY` se houver **0 anomalias estruturais/textuais detectadas**; alternativamente `VERDICT=REVIEW_SIGTAP_DESCRIPTION_ENCODING_ISSUES` com exemplos para investigação; **em qualquer caso**, `DESCRIPTION_ENCODING_APPROVAL=NOT_APPROVED` até revisão humana da saída. O teste textual não concede `T29_HISTORICAL`.

### Execução do gate textual — somente leitura (Windows)

```powershell
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha no git pull" }
.\.venv\Scripts\python.exe .\tools\audit_sigtap_hierarchy_descriptions.py
if ($LASTEXITCODE -ne 0) { throw "Auditoria textual exige investigacao" }
```

**Próxima decisão após receber o log:** avaliar a diversidade de amostras, caracteres anômalos e a compatibilidade UTF-8, determinar se `cp1252` pode ser aprovado **apenas para os textos do corpus histórico auditado**, sem inferir validade normativa retroativa, e em seguida planejar **staging descritivo competência-aware** no QlikView. Antes disso: `DIM_PROCEDIMENTO=NOT_STARTED`; `PHASE_IV=IN_PROGRESS`.

## Resultado da auditoria textual de 36 competências — 09/10/2026

**FATO VERIFICADO — PowerShell enviado pelo responsável**, após `git pull --ff-only` na branch até `faab01c`:

- Novo `tools/audit_sigtap_hierarchy_descriptions.py` foi executado em modo **READ-ONLY** e, antes das descrições, repetiu o gate SHA da fonte: `MANIFEST_SHA256=362301077a9823eca5e05362825b31471e0604bc4a9e3d308107252308f09ff5`, `COMPETENCES_VERIFIED=36`, `FILES_VERIFIED=216`, `PROCEDURES_RECONCILED=165203`, `UNMATCHED_ALL_LEVELS=0`, `FILES_TOTAL_BYTES=1863390`, `VERDICT=PASS_LOCAL_216_HIERARCHY_FILES_SHA_RECONCILED`.
- Leu **16.247 descrições** dos arquivos hierárquicos nas 36 competências: `tb_grupo` **288 registros / 8 descrições distintas**; `tb_sub_grupo` **2.124 / 62**; `tb_forma_organizacao` **13.835 / 382**.
- Linhas contendo ao menos um byte >=128: grupo **252**, subgrupo **1477**, forma **8008** (total **9737**). Para todas essas linhas, tentativa de decodificação **UTF-8 estrita falhou** (UTF8 strict compatible=0; invalid=252/1477/8008).
- **Zero** falhas de decodificação `cp1252` estrita nos três níveis; **zero** campos vazios ou em branco; **zero** caracteres de controle Unicode; **zero** suspeitas pelo detector de *mojibake*. `TEXT_ISSUES_TOTAL=0`; `OUTPUT_FILES_WRITTEN=0`; `VERDICT=PASS_CP1252_TEXT_SANITY_CANDIDATE_ONLY`.
- Amostras legíveis de texto de fonte (preservar grafia original, inclusive `orgãos` e `sangüíneos`, sem correção automática): `Ações de promoção e prevenção em saúde`, `Procedimentos clínicos`, `Transplantes de orgãos, tecidos e células`, `Diagnóstico em laboratório clínico`, `Educação em saúde`, `Exames radiológicos de vasos sangüíneos e linfáticos`.
- Chaves com **mais de uma descrição no período**: `tb_grupo=0`, `tb_sub_grupo=3`, `tb_forma_organizacao=3`. **Não são seis anomalias comprovadas**: podem ser alterações oficiais de denominação, atualização retrospectiva ou variação gráfica. Verificar quais códigos, meses e textos mudaram antes de aceitar os nomes como atributos competência-aware.
- Saída preserva `DESCRIPTION_ENCODING_APPROVAL=NOT_APPROVED`, `T29_HISTORICAL=NOT_APPROVED` e `QVD_GENERATED=False`.

**Conclusão delimitada:** integridade e sanidade da interpretação textual **PASS como candidata**. Como nenhuma linha com acentuação sobrevive à decodificação UTF-8 estrita, `UTF-8` não é compatível com a representação geral desses TXT, mas isto **não identifica univocamente `cp1252` versus `ISO-8859-1`**: inspecionar a presença de bytes `0x80–0x9F` nos textos antes de afirmar distinção. Além disso, nomes divergentes entre competências não devem ser harmonizados automaticamente. `IV-PROCEDIMENTO=TEXT_SANITY_CP1252_CANDIDATE_PASS` e descrição oficial/contrato de versão ainda precisam de fechamento.

**Próximo gate:** inspeção independente read-only dos bytes da faixa `0x80–0x9F`, listagem de códigos e transições mensais das **3 chaves de subgrupo + 3 chaves de forma**. Prosseguir com staging ou QVD somente depois de revisar a evidência; manter `T29_HISTORICAL=NOT_APPROVED`.


## Gate seguinte — transições de nomes e faixa de bytes 0x80–0x9F (CODE READY)

Criado `tools/profile_sigtap_hierarchy_label_versions.py` na mesma branch (**ainda não executado localmente**). É um complemento à auditoria textual de 16.247 registros já aprovada como candidata e não introduz staging/QVD.

O script:

- Reexecuta `audit_sigtap_hierarchy_history.py` e exige manifesto/216 hashes antes da leitura;
- Reanalisa todos os três níveis em 36 competências, usando hash/layout, `CO_*`, `DT_COMPETENCIA` e descrição real. Falha em chave duplicada, competência divergente, erro de `cp1252` estrito, tamanho/contagem não conciliados ou texto vazio/de controle;
- Identifica as **3 chaves de subgrupo** e as **3 de forma de organização** que possuíram mais de um nome no corpus. Exibe o código exato e os nomes conforme a primeira competência observada para cada transição. A multiplicidade histórica não é corrigida ou inferida como erro;
- Conta todos os bytes de descrições na faixa **0x80 a 0x9F** que diferenciam efetivamente `cp1252` de `ISO-8859-1`. Se não ocorrerem, retorna `CP1252_VS_ISO88591=NOT_DISTINGUISHABLE_WITH_OBSERVED_TEXT_BYTES` — nesse caso `cp1252` pode continuar como escolha **operacional candidata compatível**, mas não deve ser afirmado que se identificou univocamente a codificação. Se ocorrerem, relata bytes exatos e os caracteres correspondentes para inspeção humana.
- Produz `VERDICT=PASS_SIGTAP_LABEL_VERSION_AND_BYTE_PROFILE_REVIEW_ONLY` somente com integridade reconciliada, **sem escrita de arquivos** e sem aprovar `T29` ou `DESCRIPTION_ENCODING_APPROVAL`.

### Comando local

```powershell
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar a branch" }
.\.venv\Scripts\python.exe .\tools\profile_sigtap_hierarchy_label_versions.py
if ($LASTEXITCODE -ne 0) { throw "Perfil historico de descricoes exige investigacao" }
```

**Pendente:** interpretar os seis códigos e grafias, distinguir alteração de nome de erro de codificação, decidir a política operacional de `cp1252` limitada ao corpus inspecionado, sem imputaçāo retroativa. Só então habilitar staging competência-aware do SIGTAP com separação do referencial 201808 de versão retrospectiva. `DIM_PROCEDIMENTO.qvd=NOT_STARTED`; `PHASE_IV=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.

## Gate histórico de nomes e byte differential — PASS limitado (09/10/2026)

**FATO VERIFICADO — execução PowerShell `tools/profile_sigtap_hierarchy_label_versions.py`**, após `git pull --ff-only` até `abe1791`:

- Auditor independente prévio repetiu `MANIFEST_SHA256=362301077a9823eca5e05362825b31471e0604bc4a9e3d308107252308f09ff5`, `COMPETENCES_VERIFIED=36`, `FILES_VERIFIED=216`, `PROCEDURES_RECONCILED=165203`, `UNMATCHED_ALL_LEVELS=0` e `VERDICT=PASS_LOCAL_216_HIERARCHY_FILES_SHA_RECONCILED`.
- `MODE=SIGTAP_HIERARCHY_LABEL_TRANSITIONS_AND_BYTE_DIFFERENTIAL`, `COMPETENCES=36`, `FILES_AUDITED=216`, `TOTAL_DESCRIPTION_ROWS=16247`, `STAGING_FILES_WRITTEN=0`, `QVD_GENERATED=False`, `VERDICT=PASS_SIGTAP_LABEL_VERSION_AND_BYTE_PROFILE_REVIEW_ONLY`.
- `tb_grupo`: **288** linhas, **0** códigos com nomes variáveis.
- `tb_sub_grupo`: **2124** linhas, **3** códigos com nomes variáveis:
  - `0205`: `201701` "Diagnóstico por ultra-sonografia" → `201705` "Diagnóstico por ultrasonografia" (essa grafia permanece no histórico mostrado pelo perfil).
  - `0604`: `201701` "Componente Especializado da Assitencia Farmaceutica" → `201808` "Componente especializado da assistência farmacêutica" → `201809` "Componente Especializado da Assitencia Farmaceutica".
  - `0803`: `201701` "Autorização / Regulação" → `201808` "Autorização / regulação" → `201809` "Autorização / Regulação".
- `tb_forma_organizacao`: **13835** linhas, **3** códigos com nomes variáveis:
  - `010105`: `201701` "Praticas Integrativas/Complementares" → `201808` "Praticas integrativas/complementares" → `201809` "Praticas Integrativas/Complementares".
  - `010202`: `201701` "Vigilância em Saúde do Trabalhador" → `201808` "Vigilância em saúde do trabalhador" → `201809` "Vigilância em Saúde do Trabalhador".
  - `070103`: `201701` "OPM auditivas" → `201808` "OPM em Otorrinolaringologia." → `201809` "OPM auditivas" (**mudança semântica de rótulo, não apenas caixa/grafia**).
- Para cada nível: `ROWS_WITH_C1_BYTES=0`; em todas as descrições `C1_0X80_TO_0X9F_BYTE_OCCURRENCES=0`, `CP1252_VS_ISO88591=NOT_DISTINGUISHABLE_WITH_OBSERVED_TEXT_BYTES`, `DESCRIPTION_ENCODING_APPROVAL=NOT_APPROVED`.
- Combinado com o gate textual anterior: 9737 registros continham bytes altos e eram incompatíveis com UTF-8 estrito; `cp1252` estrito decodificou os 16247 sem exceções/caracteres de controle. Como nenhum byte observado diferencia `cp1252` de `ISO-8859-1`, **a origem não comprova exclusivamente qual charset foi empregado**.

**DECISÃO OPERACIONAL LIMITADA / SEM AFIRMAÇÃO NORMATIVA:** usar `cp1252` como *candidato de leitura* dos atributos hierárquicos para o próximo CSV local, seguindo a convenção já aprovada para `NO_PROCEDIMENTO` da Fase III-C3.4a.1. No universo dos bytes aqui verificados, a leitura é idêntica à `ISO-8859-1`. Isso **não** constitui prova do charset declarado pelo DATASUS; não alterar grafia, caixa, nome/competência, nem inferir validade normativa anterior. As seis chaves variáveis serão mantidas com seus rótulos correspondentes **exatamente ao respectivo snapshot** no CSV candidato; os cinco casos específicos de `201808` requerem ressalva de proveniência porque o ZIP `TabelaUnificada_201808_v2102261143.zip` carrega carimbo de versão de 2021. **Não** homogenizar a partir de `201809`.

**Próxima etapa:** preparar arquivo candidato UTF-8 com cabeçalhos explícitos para enriquecer `REF_SIGTAP` por `competência × CO_PROCEDIMENTO` usando os três níveis hierárquicos; preservar todos os **165203** códigos/mês e os nomes originais, validar cobertura 0 unmatched, fonte 216 SHA e CSV anterior hash, **sem substituir** `EXTRACAO/QVD/REF_SIGTAP.qvd` nem materializar `DIM_PROCEDIMENTO.qvd` antes de testes locais. `T29_HISTORICAL=NOT_APPROVED`.

## Preflight do CSV hierárquico SIGTAP por competência — código preparado, execução pendente

**Nova implementação versionada:** `tools/materialize_sigtap_hierarchy_staging_candidate.py`. Esta etapa ainda **NÃO rodou** no Windows; não existe CSV enriquecido aprovado nem alteração em `REF_SIGTAP.qvd`.

### Contrato de enriquecimento proposto e tecnicamente fundamentado

O arquivo candidato parte de `BASE/REFERENCIAS/sigtap_procedimento_staging_candidate.csv` aprovado como staging III-C3.4a.1, sem alterar suas quatro colunas:

- `SIGTAP_COMPETENCIA`, `SIGTAP_CO_PROCEDIMENTO`, `SIGTAP_NO_PROCEDIMENTO`, `SIGTAP_COMPETENCIA_CODIGO`.

Adiciona **somente atributos derivados de campos físicos oficialmente inspecionados**, após lookup exato pela mesma competência:

- `SIGTAP_CO_GRUPO` = `CO_GRUPO` do pacote, extraído dos dígitos 1–2 de `CO_PROCEDIMENTO`; `SIGTAP_NO_GRUPO` = `NO_GRUPO` do mesmo mês;
- `SIGTAP_CO_SUB_GRUPO` = `CO_SUB_GRUPO` (dígitos 3–4); `SIGTAP_NO_SUB_GRUPO` = `NO_SUB_GRUPO` do mesmo mês e grupo;
- `SIGTAP_CO_FORMA_ORGANIZACAO` = `CO_FORMA_ORGANIZACAO` (dígitos 5–6); `SIGTAP_NO_FORMA_ORGANIZACAO` = `NO_FORMA_ORGANIZACAO` do mesmo mês, grupo e subgrupo.

**Grão preservado:** exatamente uma linha por `competência × CO_PROCEDIMENTO`, 165.203 linhas em 36 competências com chave `AAAAMM|XXXXXXXXXX` existente. O arquivo candidato contém **10 campos** e preserva nomes brutos, caixa e grafias observadas. Inclui os cinco rótulos divergentes de `201808` tal como estão no ZIP retrospectivo, sem equiparar isso a validade histórica; o manifesto gerado (se autorizado) registra `201808_source_version_caveat`. Não inventa `DESCRICAO_OFICIAL` separada de `NO_PROCEDIMENTO`: a decisão sobre descrição oficial adicional segue subordinada ao modelo acadêmico e às fontes reais.

**Entrada/qualidade:** o script exige previamente PASS da auditoria de 216 TXT SHA-256; confere SHA-256 do CSV e manifesto III-C3.4a, 36 competências, 165203 chaves únicas de procedimento, valores não vazios e sem ausências na hierarquia; reconcilia número mensal com **ambos** manifestos. `cp1252` é interpretação operacional candidata compatível com ISO-8859-1 em todos os bytes hierárquicos observados. CSV de saída **UTF-8** para leitura QlikView posterior.

**Controles de escrita:** exigir argumento explícito `--validate-only` ou `--materialize`; a opção `--validate-only` executa toda a reconciliação em memória **sem gravar nada** e retorna `VERDICT=PASS_36_MONTH_HIERARCHY_STAGING_CANDIDATE_VALIDATE_ONLY`. A opção de materialização (NÃO autorizar ainda) criará exclusivamente:
- `BASE/REFERENCIAS/sigtap_procedimento_hierarquia_staging_candidate.csv`;
- `BASE/REFERENCIAS/sigtap_procedimento_hierarquia_staging_candidate_manifest.json`.

A opção de materialização recusa sobrescrever saídas existentes, preserva as fontes, e **não gera QVD, não modifica `EXTRACAO/ext_main.qvs` ou `TRANSFORMACAO/transf_main.qvs` e não inicia fatos ou Link Table**.

### Próximo comando local — primeira execução, somente leitura

```powershell
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Git pull falhou" }
.\.venv\Scripts\python.exe .\tools\materialize_sigtap_hierarchy_staging_candidate.py --validate-only
if ($LASTEXITCODE -ne 0) { throw "Preflight do candidato SIGTAP falhou" }
```

**Esperado se passar:** `COMPETENCES=36`, `REFERENCE_ROWS=165203`, `DISTINCT_CODE_MONTH_KEYS=165203`, `FIELDS=10`, `UNMATCHED_GROUP=0 UNMATCHED_SUBGROUP=0 UNMATCHED_FORM=0`, `OUTPUT_FILES_WRITTEN=0`, `QLIK_QVD=NOT_GENERATED`.

**Estado:** `IV-PROCEDIMENTO=HISTORICAL_LABEL_DIFF_REVIEW_PASS_STAGING_CANDIDATE_CODE_READY_NOT_EXECUTED`; `PHASE_IV=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.

## CSV hierárquico de 10 campos — `--validate-only` PASS local (09/10/2026)

**FATO VERIFICADO — console PowerShell fornecido pelo responsável:**

- Branch `feat/phase-4-dim-procedimento` atualizada por `git pull --ff-only` até `c93fed5`. `tools/materialize_sigtap_hierarchy_staging_candidate.py --validate-only` foi executado com sucesso; não acionou o `throw` posterior.
- A auditoria anterior de 216 arquivos foi reexecutada no início: `MANIFEST_SHA256=362301077a9823eca5e05362825b31471e0604bc4a9e3d308107252308f09ff5`, `COMPETENCES_VERIFIED=36`, `FILES_VERIFIED=216`, `PROCEDURES_RECONCILED=165203`, `UNMATCHED_ALL_LEVELS=0`, `VERDICT=PASS_LOCAL_216_HIERARCHY_FILES_SHA_RECONCILED`.
- Candidato enriquecido: `MODE=SIGTAP_HIERARCHY_STAGING_CANDIDATE`, `COMPETENCES=36`, `REFERENCE_ROWS=165203`, `DISTINCT_CODE_MONTH_KEYS=165203`, `FIELDS=10`, `UNMATCHED_GROUP=0 UNMATCHED_SUBGROUP=0 UNMATCHED_FORM=0`.
- SHA-256 do CSV original III-C3.4a: **`75237997a26bea243b101af1bd19e04e3f4905fb237ac9d227db860cbd14b482`**, reconciliado pelo script; SHA-256 do manifesto hierárquico: **`362301077a9823eca5e05362825b31471e0604bc4a9e3d308107252308f09ff5`**.
- `DESCRIPTION_DECODE=CP1252_OPERATIONAL_CANDIDATE_EQUIVALENT_ISO_8859_1`, `T29_HISTORICAL=NOT_APPROVED`, `QLIK_QVD=NOT_GENERATED`, `OUTPUT_FILES_WRITTEN=0`, `VERDICT=PASS_36_MONTH_HIERARCHY_STAGING_CANDIDATE_VALIDATE_ONLY`.

**Interpretação:** a proposta de enriquecimento de **165.203 linhas/10 campos** passou os joins `competência + CO_PROCEDIMENTO` com grupo, subgrupo e forma para **todas as 36 competências**, sem excluir códigos ou reescrever o staging da Fase III. Isto **não** constitui inspeção independente do futuro CSV persistido; foi o teste do próprio construtor em modo read-only. Não declarar arquivo enriquecido existente antes de executar a materialização.

### Gate seguinte — materialização CSV candidato + auditoria física independente

O script já versionado `tools/materialize_sigtap_hierarchy_staging_candidate.py` exige `--materialize` explícito, constrói arquivo temporário UTF-8 e só grava novo CSV local após checar todos os 165203 pares, unicidade, reconciliação por mês e 0 unmatched. Recusa substituir saída já existente; **não escreve QVD**.

Adicionado **`tools/audit_sigtap_hierarchy_staging_candidate.py`** (CODE READY, NÃO EXECUTADO) para, sem escrita:
- auditar novamente SHA-256 e manifesto dos **216** membros de hierarquia;
- exigir SHA-256 do CSV original de 4 campos, manifesto e contagens III-C3.4a, SHA-256 e schema do **novo CSV de 10 campos** e coerência de seu manifesto;
- comparar **cada uma das 165203 linhas** de ambos os CSVs, incluindo **igualdade textual exata dos quatro campos anteriores após leitura CSV UTF-8**, ordem e chave composta (não é comparação binária dos arquivos CSV); conferir por competência a existência/valor exato dos nomes oficiais dos três níveis a partir dos 216 arquivos originais;
- exigir cobertura 36/36, códigos ASCII de dez dígitos, SK operacional textual `AAAAMM|XXXXXXXXXX`, 165203 chaves únicas e 0 unmatched;
- preservar `201808_source_version_caveat=TabelaUnificada_201808_v2102261143.zip`, `T29_HISTORICAL=NOT_APPROVED`, sem QVD ou fatos.

A descrição `cp1252` continua interpretação **operacional** indistinguível de `ISO-8859-1` nos bytes do corpus. O enriquecimento mantém grafia original por competência, inclusive os cinco nomes anômalos de `201808`; **não aprova** seu uso como versão normativamente vigente em agosto de 2018.

**Comandos para execução local sob supervisão:**

```powershell
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha no git pull" }
.\.venv\Scripts\python.exe .\tools\materialize_sigtap_hierarchy_staging_candidate.py --materialize
if ($LASTEXITCODE -ne 0) { throw "Falha na materializacao do CSV SIGTAP hierarquico" }
.\.venv\Scripts\python.exe .\tools\audit_sigtap_hierarchy_staging_candidate.py
if ($LASTEXITCODE -ne 0) { throw "Falha na auditoria independente do CSV SIGTAP" }
```

**Gates esperados, ainda NÃO observados:** `PASS_36_MONTH_HIERARCHY_STAGING_CANDIDATE_MATERIALIZED` e `PASS_LOCAL_SIGTAP_HIERARCHY_STAGING_CSV_SHA_AND_ROW_RECONCILED`. Não ligar `EXTRACAO/ext_main.qvs`, `TRANSFORMACAO/transf_main.qvs`, materializar `DIM_PROCEDIMENTO.qvd` nem construir fatos/Link Table antes de receber o resultado real e revisar contrato dimensional. Estado: `IV-PROCEDIMENTO=STAGING_10_FIELD_VALIDATE_ONLY_PASS_MATERIALIZATION_PENDING`; Fase IV = 3/8 dimensões integradas.

## Resultado C3/IV — materialização e auditoria independente de staging hierárquico 10 campos PASS (09/10/2026)

**FATO VERIFICADO — duas saídas PowerShell/Python do responsável após fast-forward da branch até `cc9fe24`:**

1. `tools/materialize_sigtap_hierarchy_staging_candidate.py --materialize`: `COMPETENCES=36`, `REFERENCE_ROWS=165203`, `DISTINCT_CODE_MONTH_KEYS=165203`, `FIELDS=10`, `UNMATCHED_GROUP=0 UNMATCHED_SUBGROUP=0 UNMATCHED_FORM=0`, `NEW_CSV_SHA256=cf75e51400c09896fe0e296bd3a4d448353de4c196bbb40985a58f24012b6db7`, `NEW_CSV_BYTES=33586769`, `OUTPUT_FILES_WRITTEN=2`, `VERDICT=PASS_36_MONTH_HIERARCHY_STAGING_CANDIDATE_MATERIALIZED`.
2. O auditor externo do candidato `tools/audit_sigtap_hierarchy_staging_candidate.py` leu o CSV de 10 campos, o CSV de 4 campos e as tabelas hierárquicas originais do mesmo mês. Resultado: `CSV_SHA256=cf75e51400c09896fe0e296bd3a4d448353de4c196bbb40985a58f24012b6db7`, `CSV_BYTES=33586769`, `COMPETENCES_VERIFIED=36`, `CSV_FIELDS_VERIFIED=10`, `CSV_ROWS_VERIFIED=165203`, `CSV_DISTINCT_KEYS=165203`, `SOURCE_FIELDS_PRESERVED=True`, `HIERARCHY_NAMES_MATCH_SAME_MONTH=165203`, `UNMATCHED_ALL_LEVELS=0`, `VERDICT=PASS_LOCAL_SIGTAP_HIERARCHY_STAGING_CSV_SHA_AND_ROW_RECONCILED`.
3. Provas de origem reiteradas em **ambas** execuções: SHA-256 manifesto 216 membros `362301077a9823eca5e05362825b31471e0604bc4a9e3d308107252308f09ff5`, 36 competências, `FILES_VERIFIED=216`, `PROCEDURES_RECONCILED=165203`, `UNMATCHED_ALL_LEVELS=0`. O staging básico anterior III-C3.4a mantém SHA-256 `75237997a26bea243b101af1bd19e04e3f4905fb237ac9d227db860cbd14b482`.
4. Artefatos gerados são **locais e ignorados pelo Git**: `BASE/REFERENCIAS/sigtap_procedimento_hierarquia_staging_candidate.csv` (33.586.769 bytes, UTF-8) e `BASE/REFERENCIAS/sigtap_procedimento_hierarquia_staging_candidate_manifest.json`. A auditoria fez igualdade textual exata das quatro colunas originais sob leitura CSV e verificou os três rótulos hierárquicos contra os arquivos físicos de **cada competência**.
5. Saídas mantêm `DESCRIPTION_ENCODING=OPERATIONAL_ONLY`, `T29_HISTORICAL=NOT_APPROVED`, `QVD_GENERATED=False`. Não foi executado o QlikView e nenhuma dimensão/fato/Link Table foi gerada.

**Veredito documental:** `IV-PROCEDIMENTO=PASS_LOCAL_SIGTAP_HIERARCHY_STAGING_CSV_SHA_AND_ROW_RECONCILED` (CSV físico candidato e manifesto íntegros). A denominação “oficial” significa rótulos transcritos da fonte SIGTAP, **não** que se comprovou vigência normativa exata das versões retrospectivas, especialmente `201808` com ZIP `v2102261143`. Codificação hierárquica `cp1252` é interpretação operacional indistinguível de `ISO-8859-1` nos bytes observados, sem afirmação de encoding oficialmente declarado. Não corrigir nomes nem atribuir descrições detalhadas ausentes do layout.

**Próximo gate proposto:** IV-DIM_PROCEDIMENTO — preparar e testar transformação QlikView 12 competência-aware (Hash128 no código+competência), validando unicidade 165203, integridade descritiva de 10 campos, SK 165203, RD 566672 linhas com 0 unmatched e zero regressões das 3 dimensões anteriores. Não atualizar `EXTRACAO/QVD/REF_SIGTAP.qvd` implicitamente; o candidato CSV validado pode ser lido como staging local isolado de transformação até nova decisão de persistência. `DESCRICAO_OFICIAL` separada do nome de procedimento requer campo de origem validado e deve ficar NULL/status não resolvido (não duplicar nome para inventar descrição detalhada). Uma nova dimensão só será PASS após Qlik reload real e auditoria física QVD/CSV. `PHASE_IV=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.

## IV-DIM_PROCEDIMENTO — QlikView 12 checkpoint isolado preparado (SEM reload ainda)

**FATO VERIFICADO EM REPOSITÓRIO:** foram acrescentados os scripts versionáveis `TRANSFORMACAO/transf_dim_procedimento.qvs` e `tools/audit_dim_procedimento_qvd.py`, além da nova chamada `$(Must_Include=transf_dim_procedimento.qvs);` **após** os checkpoints `DIM_TEMPO`, `DIM_MUNICIPIO` e `DIM_ESTABELECIMENTO` em `TRANSFORMACAO/transf_main.qvs`. **Nenhum QlikView reload foi executado nesta tarefa.** São implementações candidatas sujeitas ao QlikView 12 local e à auditoria do QVD físico.

### Contrato da dimensão sob teste

- **Fonte:** CSV `BASE/REFERENCIAS/sigtap_procedimento_hierarquia_staging_candidate.csv`, UTF-8, separador `;`, 10 campos, **165.203 linhas**, SHA-256 `cf75e51400c09896fe0e296bd3a4d448353de4c196bbb40985a58f24012b6db7`, materializado e auditado via Python contra os 216 membros de hierarquia e o CSV anterior. O Qlik deste checkpoint lê o CSV de staging validado *diretamente*, sem criar novo estágio `REF_SIGTAP.qvd` e **sem substituí-lo**. Trata-se de hipótese técnica transitória de consumo de staging por transformação; não alterar a arquitetura aprovada nem os 10 QVDs de extração sem decisão posterior.
- **Grão:** uma versão por `SIGTAP_CO_PROCEDIMENTO` de 10 dígitos e `SIGTAP_COMPETENCIA` `AAAAMM`, 36 competências. **SK:** `%SK_PROCEDIMENTO = Hash128('PROC', COD_PROCEDIMENTO, COMPETENCIA_REFERENCIA)`, conforme Boundary 7. Validar 165203 SK distintas, 165203 pares distintos e 0 linhas inválidas.
- **12 colunas físicas propostas de `DIM_PROCEDIMENTO`:** `%SK_PROCEDIMENTO`, `COD_PROCEDIMENTO`, `COMPETENCIA_REFERENCIA`, `NOME_PROCEDIMENTO`, `DESCRICAO_OFICIAL` (**NULL**, porque o layout inspecionado não fornece *outra* descrição detalhada distinta de `NO_PROCEDIMENTO`), `DESCRICAO_OFICIAL_STATUS` (`SEM_CAMPO_DE_DESCRICAO_DETALHADA_VALIDADO`), `CO_GRUPO`, `NO_GRUPO`, `CO_SUB_GRUPO`, `NO_SUB_GRUPO`, `CO_FORMA_ORGANIZACAO`, `NO_FORMA_ORGANIZACAO`. A `NOME_PROCEDIMENTO` preserva o rótulo `NO_PROCEDIMENTO` da fonte oficial. Não inventar conteúdo de `DESCRICAO_OFICIAL`.
- **Qualidade:** valida origem (36×, 165203 pares, 10 campos, prefixos 2/4/6, campos não vazios); RD↔DIM no mesmo mês via `SRC_SIH_RD.qvd`, `_META_SOURCE_COMPETENCE + PROC_REA`: **566.672 RD esperados e 0 unmatched**; não descartar internações, não construir fato.
- **Proveniência:** preservar nomes do pacote de competência, incluindo 201808 com versão retrospectiva `TabelaUnificada_201808_v2102261143.zip`; `cp1252` é interpretação operacional compatível com ISO-8859-1 nos bytes observados e **não afirmação do charset oficial**; `T29_HISTORICAL=NOT_APPROVED` permanece.
- **Saídas SOMENTE SE PASS Qlik:** `TRANSFORMACAO/QVD/DIM_PROCEDIMENTO.qvd` e `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_PROCEDIMENTO.csv` com status `PASS_PARTIAL_DIM_PROCEDIMENTO_ONLY`. **Proibido** emitir `_SUCCESS_TRANSFORMACAO.csv`, implementar fatos, Link Table ou painel. O reload normal do `TRANSF.qvw` também executará os três includes anteriores e revalidará seus checkpoints.

### Próxima execução — local QlikView 12, ainda pendente

1. Sincronizar `feat/phase-4-dim-procedimento` por `git pull --ff-only`. Exigir árvore Git coerente e arquivo CSV local com o hash acima; se houver dúvida, reexecutar o auditor de origem `tools/audit_sigtap_hierarchy_staging_candidate.py` antes do Qlik.
2. Abrir `TRANSFORMACAO/TRANSF.qvw` no QlikView 12 (o documento usa o include externo `transf_main.qvs`); executar **Reload**. Inspecionar o log fresco `TRANSF.qvw.*.log` ou saída de script e verificar `Execution finished`, sem `ScriptError`, `SOURCE Rows=165203 Fields=10 Keys=165203 Months=36 Invalid=0`, `COVER RD=566672 UNMATCHED=0` e `DIM_PROCEDIMENTO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`. **Não inferir PASS só do QVD presente**.
3. Rodar o auditor independente read-only:
   ```powershell
   .\.venv\Scripts\python.exe .\tools\audit_dim_procedimento_qvd.py
   ```
   Ele compara SHA do CSV de staging, manifesto, cabeçalho XML `QvdTableHeader` (165203 linhas/12 campos), o checkpoint parcial (SK, 36 meses, RD zero unmatched, T29 e fatos não iniciados), e frescor mtime do QVD em relação ao CSV. Emite `PASS_LOCAL_DIM_PROCEDIMENTO_QVD_HEADER_CHECKPOINT_RECONCILED` só se todos os controles de metadados passarem. **Limitação explícita**: não decodifica cada registro do corpo binário QVD; a prova de valores/joins é dos controles do QlikView e da auditoria Python do staging. Nenhuma etapa é sucesso global da Fase IV.
4. Enviar o log real e a saída do auditor para análise antes de criar PR ou considerar a quarta dimensão integrada.

**DECISÃO PENDENTE:** manter `DESCRICAO_OFICIAL` como NULL/status explícito por falta de campo detalhado distinto, até prova de outra fonte SIGTAP; não preencher repetindo `NOME_PROCEDIMENTO` sem decisão consciente. A decisão acadêmica sobre dimensão é preservada, e o atributo está previsto fisicamente mas sem dados. A versão retrospectiva 201808 continua com T29 não aprovado.

**Estado:** `IV-PROCEDIMENTO=STAGING_CSV_AUDIT_PASS_QLIK_CODE_READY_NOT_RUN`; `DIM_PROCEDIMENTO_QVD=NOT_YET_VALIDATED`; `PHASE_IV=IN_PROGRESS`; 3/8 dimensões integradas; `T29_HISTORICAL=NOT_APPROVED`.

## IV-PROCEDIMENTO — QVD e checkpoint físicos reconciliados (09/10/2026), log de reload pendente

**FATO VERIFICADO — PowerShell fornecido pelo responsável:**

- `git pull --ff-only` em `feat/phase-4-dim-procedimento` realizou fast-forward `cc9fe24..83e1b7b` e recebeu `TRANSFORMACAO/transf_dim_procedimento.qvs`, seu `Must_Include` em `transf_main.qvs`, e `tools/audit_dim_procedimento_qvd.py`.
- O responsável executou `.\.venv\Scripts\python.exe .\tools\audit_dim_procedimento_qvd.py` com sucesso. **Não forneceu nesta mensagem o log de execução/reload do QlikView 12 nem seu resumo `Execution finished`/ausência de erros.**
- Auditor read-only do arquivo físico `TRANSFORMACAO/QVD/DIM_PROCEDIMENTO.qvd`: `SOURCE_CSV_SHA256=cf75e51400c09896fe0e296bd3a4d448353de4c196bbb40985a58f24012b6db7`, `QVD_SHA256=620b3f9d4d1babdf25b2d1f2f5653ad7089e4003986048bdb746b5662f2de56b`, `QVD_ROWS=165203`, `QVD_FIELDS=12`.
- Cabeçalho XML físico QVD em ordem: `%SK_PROCEDIMENTO`, `COD_PROCEDIMENTO`, `COMPETENCIA_REFERENCIA`, `NOME_PROCEDIMENTO`, `DESCRICAO_OFICIAL`, `DESCRICAO_OFICIAL_STATUS`, `CO_GRUPO`, `NO_GRUPO`, `CO_SUB_GRUPO`, `NO_SUB_GRUPO`, `CO_FORMA_ORGANIZACAO`, `NO_FORMA_ORGANIZACAO`.
- Auditor do checkpoint `TRANSFORMACAO/QVD/_CHECKPOINT_DIM_PROCEDIMENTO.csv`: `CHECKPOINT_SHA256=b6180cecb7b91b93d2fd5906ed7034549ce38105cde4d6d0eb0f03b4a7639543`, `CHECKPOINT_STATUS=PASS_PARTIAL_DIM_PROCEDIMENTO_ONLY`, `RD_ROWS=566672`, `RD_PROCEDURE_UNMATCHED=0`, `T29_HISTORICAL=NOT_APPROVED`, `FACTS_AND_LINK_TABLE=NOT_STARTED`.
- Resultado do auditor: **`VERDICT=PASS_LOCAL_DIM_PROCEDIMENTO_QVD_HEADER_CHECKPOINT_RECONCILED`**, com limite explícito `LIMIT=QVD_BINARY_ROWS_NOT_INDEPENDENTLY_DECODED`. O auditor verificou também contadores do checkpoint (36 competências, 165203 chaves substitutas únicas, 165203 versões procedimento×competência e 0 registros inválidos), esquema e frescor relativo dos arquivos.
- Isso comprova a existência do QVD, seu tamanho lógico pelo cabeçalho, nomes de campos, SHA-256, reconciliação do checkpoint e dos resultados nele **registrados**. **Não equivale a comprovar a execução sem falhas de todo o reload**, pois não houve log Qlik fornecido nesta rodada; o auditor não decompõe o corpo binário do QVD.

**Estado correto do gate:** `IV-PROCEDIMENTO=LOCAL_QVD_HEADER_AND_PARTIAL_CHECKPOINT_PASS_RELOAD_LOG_PENDING`. O CSV de staging 165203×10 e seus 216 arquivos originais seguem PASS. **Não promover PR/merge ainda**; Fase IV possui **3/8 dimensões integradas na main**, com `DIM_PROCEDIMENTO` materializada/validada fisicamente apenas na estação local e não integrada. `T29_HISTORICAL=NOT_APPROVED`; sem fatos, Link Table, PAINEL nem `_SUCCESS_TRANSFORMACAO.csv`.

### Gate final de evidência do QlikView 12

Identificar o **log mais recente de `TRANSF.qvw` realmente correspondente ao novo QVD** e conferir, na mesma execução:

1. `[TRANSFORMACAO][IV-PROCEDIMENTO] SOURCE Rows=165203 Fields=10 Keys=165203 Months=36 Invalid=0`;
2. `[TRANSFORMACAO][IV-PROCEDIMENTO] COVER RD=566672 UNMATCHED=0`;
3. `[TRANSFORMACAO][IV-PROCEDIMENTO] DIM_PROCEDIMENTO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN`;
4. encerramento normal (`Execution finished` ou marca equivalente no log Qlik), sem falha `ScriptError`/abortos, e timestamps compatíveis com os arquivos auditados;
5. sem evidência de criação de fatos, Link Table ou marcador global `_SUCCESS_TRANSFORMACAO.csv`.

Após receber o log real, revisar o conjunto do PR e somente então classificar esta dimensão como candidata à integração. Não inferir o PASS de reload com base no arquivo QVD isolado.

## IV-PROCEDIMENTO — evidência complementar de Reload QlikView 12 PASS (09/10/2026)

**FATO VERIFICADO — saída do PowerShell e excertos do arquivo de log QlikView enviados pelo responsável:**

- Após `git pull --ff-only`, a branch `feat/phase-4-dim-procedimento` avançou por fast-forward de `83e1b7b` até `dfe3e7c` (somente alterações documentais).
- Log mais recente encontrado em `TRANSFORMACAO/TRANSF.qvw.2026_10_09_09_24_36.log`; execução observada das **09:24:36 às 09:24:48 de 09/10/2026**, inclusive traces IV-PROCEDIMENTO e finalização.
- O mesmo log registra `[TRANSFORMACAO][IV-PROCEDIMENTO] START` às **09:24:45**, `SOURCE Rows=165203 Fields=10 Keys=165203 Months=36 Invalid=0` às **09:24:46**; `COVER RD=566672 UNMATCHED=0` às **09:24:48**; `DIM_PROCEDIMENTO_QVD_AND_PARTIAL_CHECKPOINT_WRITTEN` às **09:24:48**.
- Na seção `P4P_DIM_CHECKPOINT`, o log mostra explicitamente `165203 AS dimension_rows`, `12 AS dimension_fields`, `36 AS distinct_competences`, `165203 AS unique_surrogate_keys`, `165203 AS unique_procedure_month_versions`, `0 AS invalid_dimension_rows`, `566672 AS rd_rows`, `0 AS rd_procedure_unmatched`, `NOT_APPROVED AS t29_historical`, `NOT_STARTED AS facts_and_link_table`; registra `STORE DIM_PROCEDIMENTO`, `STORE P4P_DIM_CHECKPOINT`, e termina com `Execução concluída.` às **09:24:48**.
- A busca PowerShell por `ScriptError` mostra expressões condicionais/guardas `IF ScriptErrorCount > 0 THEN` no texto de script, **não mensagens de erro de execução**. Nos trechos enviados, não se vê mensagem `FAIL`, abortamento ou erro efetivamente emitido.
- Esta evidência se soma à auditoria independente do QVD/checkpoint já executada anteriormente: `QVD_SHA256=620b3f9d4d1babdf25b2d1f2f5653ad7089e4003986048bdb746b5662f2de56b`, `CHECKPOINT_SHA256=b6180cecb7b91b93d2fd5906ed7034549ce38105cde4d6d0eb0f03b4a7639543`, `PASS_LOCAL_DIM_PROCEDIMENTO_QVD_HEADER_CHECKPOINT_RECONCILED`. A auditoria não descompacta as linhas binárias do QVD: a prova da qualidade de carga e dos joins decorre do log/Qlik e do staging Python verificado linha a linha.
- **Limite da evidência:** o responsável compartilhou a seleção de linhas e as últimas 40 linhas, **não o arquivo de log integral**. As evidências fornecidas atendem aos controles exigidos de conclusão e traces do quarto checkpoint; não equivalem a uma auditoria independente do log completo. O include Qlik documentado contém apenas dimensões parciais e não implementa fatos/Link Table, mas esta mensagem não demonstrou por inspeção do diretório a ausência de qualquer marcador global pré-existente.

**Veredito do checkpoint:** `IV-PROCEDIMENTO=PASS_LOCAL_QLIK_RELOAD_AND_QVD_CHECKPOINT_RECONCILED`; quarto checkpoint **validado localmente**. Não declarar `PHASE_IV=PASS_FINAL` nem quarta dimensão **integrada na main** antes do merge do PR. A `main` contém **3/8 dimensões integradas**, com esta quarta pronta para revisão. Preservar fonte SIGTAP de 201808 como versão retrospectiva `v2102261143`, charset `cp1252` operacional indistinguível de ISO-8859-1 nos bytes inspecionados, `DESCRICAO_OFICIAL=NULL` sem campo detalhado oficial validado, e `T29_HISTORICAL=NOT_APPROVED`.

**Próximo gate:** revisar alterações entre `main` e `feat/phase-4-dim-procedimento`, abrir PR de revisão sem auto-merge e decidir sua integração somente com aprovação explícita. Após merge, restarão quatro dimensões ainda não integradas: `DIM_DIAGNOSTICO`, `DIM_CARATER_ATENDIMENTO`, `DIM_MOTIVO_SAIDA_PERMANENCIA` e `DIM_TIPO_LEITO`.
