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

