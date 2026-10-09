# Fase IV — DIM_MOTIVO_SAIDA_PERMANENCIA — Discovery / preflight (09/10/2026)

## Objetivo e escopo

**Estado canônico:** Fase III extração/staging PASS FINAL. Fase IV **6/8 dimensões integradas à `main`** após squash merge autorizado do PR [#79](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/79) (`70fa608eb2a6e49c1450268e6706ceaa99177da1`). Próxima dimensão: `DIM_MOTIVO_SAIDA_PERMANENCIA`. Capítulos 1 e 2 acadêmicos fechados, sem modificação. Sem fatos, Link Table ou painel. `T29_HISTORICAL=NOT_APPROVED` para classificação histórica de leitos.

**Fontes canônicas lidas:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, `docs/academic/chapter-1-2-modeling.md`, `docs/discovery/boundary-7-implementation-plan.md`, `docs/discovery/phase-3-normative-references-implementation-2026-10-07.md`, `tools/materialize_normative_references.py`, `EXTRACAO/ext_main.qvs` e `docs/discovery/dataset-validation.md`.

## Fatos já documentados

1. **Contrato acadêmico:** `DIM_MOTIVO_SAIDA_PERMANENCIA` deve possuir SK, código, descrição oficial e categoria de encerramento. A dimensão está ligada ao registro de internação, não à capacidade CNES.
2. **Chave candidata já decidida no Boundary 7:** `%SK_MOTIVO_SAIDA=Hash128('MOT', COBRANCA)`, onde `COBRANCA` é a chave de fonte **textual**, sem ponto. No relatório acadêmico, `11`↔`1.1`, `41`↔`4.1`, `61`↔`6.1`; Boundary 7 fixa explicitamente `24`↔`2.4`. O código normativo **com ponto** será atributo de exibição, não SK adicional nem substituição silenciosa da chave de fonte.
3. **Material normativo oficial já trabalhado no projeto:** Portaria SAS/MS **719/2007** e atualização **384/2010**. `tools/materialize_normative_references.py` contém **28** tuplas `(codigo_fonte, codigo_normativo, descricao, grupo, fonte_oficial_base, fonte_oficial_atualizacao)`. São excluídos os códigos revogados `13`/`17`, enquanto a lista validada incorpora `19`, `32` e `61`–`67`.
4. **Falha histórica registrada e resolvida na Fase III-C1:** materialização inicial de apenas 21 linhas cobriu mal o RD (**124.233** linhas sem referência); com domínio oficial atualizado de 28 códigos, o checkpoint III-C1 concluiu `PASS_PARTIAL`, `motivo_rows=28`, `motivo_unmatched_rd_rows=0`, RD 566.672. **Não reaproveitar o hash da materialização antiga de 21 códigos** como valor esperado do CSV corrigido.
5. **Arquivos locais versionados apenas como contratos, não como dados:** `BASE/REFERENCIAS/motivo_saida_permanencia.csv` e `manifesto_referencias_normativas.json` (SHA e integridade da origem normativa C1), `EXTRACAO/QVD/REF_MOTIVO_SAIDA.qvd` e `SRC_SIH_RD.qvd`, `EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_REFERENCIAS_NORMATIVAS.csv`. A referência QVD tem **9 campos físicos**: `COBRANCA`, `MOTIVO_CODIGO_NORMATIVO`, `MOTIVO_DESCRICAO`, `MOTIVO_GRUPO`, `MOTIVO_FONTE_OFICIAL_BASE`, `MOTIVO_FONTE_OFICIAL_ATUALIZACAO`, e três metadados `_META_*`.
6. **Normalização já presente na extração:** `Right('00' & KeepChar(Text(COBRANCA),'0123456789'),2)`. Na Fase IV, **não** permitir que `KeepChar` oculte caracteres brutos inválidos: inspecionar as 36 fontes reais primeiro, preservar códigos fonte e testar a correspondência sem ponto. No checkpoint SIH/RD anteriormente observado, havia **26 códigos distintos**: `11,12,14,15,16,18,19,21,22,23,24,25,26,27,28,31,41,42,43,51,61,62,63,64,65,66`; os códigos oficiais `32` e `67` devem permanecer na dimensão, embora não observados no recorte. **Confirmar esse perfil novamente localmente**, pois o estado anterior não autoriza supor frequências por código.
7. **Limite histórico explícito:** o dicionário corrigido representa o conjunto normativo aplicado no recorte 2017–2019 conforme C1, mas o preflight de chave/cobertura **não comprova a vigência individual mensal** de cada código nem a equivalência de todos os cenários clínicos.

## Novo gate físico READ-ONLY

Ferramenta versionada na branch `feat/phase-4-dim-motivo-saida-permanencia`: **`tools/preflight_dim_motivo_saida_permanencia.py`**.

- Revalida os dois arquivos normativos C1 e manifesto por **SHA-256**, estágio, status `PASS`, referências de Portarias 719/2007 e 384/2010; não congela o SHA **antigo** do domínio incompleto 21 registros.
- Compara **campo por campo** as 28 linhas CSV UTF-8 contra as 28 tuplas já aprovadas no materializador C1: códigos fonte únicos, códigos normativos únicos, descrição, grupo, proveniência base/atualização, `24`↔`2.4` e ausência dos códigos revogados `13`/`17`.
- Verifica **somente o cabeçalho XML** do QVD de referência (28 linhas/9 campos na ordem documentada), do QVD SIH/RD (566672 linhas e campo `COBRANCA`) e a linha do checkpoint `PASS_PARTIAL` C1 (28 códigos e zero RD unmatched).
- Relê os **36 arquivos físicos** `BASE/CONVERTIDA/RD/RDPB*.csv`, competência 201701–201912; cada `COBRANCA` deve conter um ou dois dígitos após remover exclusivamente espaços ASCII exteriores, normalizado com zero à esquerda. Exige **566672 registros**, 0 unmatched, 26 códigos RD documentados, 32/67 ausentes e 13/17 revogados ausentes. Imprime distribuição **real** dos códigos por fonte e ano para comparação posterior com o QlikView.
- **Não escreve nada**, não gera QVD, não baixa dados e não executa Reload; o QVD binário não é decodificado pelo auditor. Qualquer desvio de SHA, chave, código, domínio ou cobertura interrompe a execução.

**Estado: `IV-MOTIVO_SAIDA_PERMANENCIA=READ_ONLY_PREFLIGHT_CODE_READY_NOT_RUN`.** A execução real local está pendente.

### Comando PowerShell, raiz do repositório

```powershell
git fetch origin
git switch feat/phase-4-dim-motivo-saida-permanencia
git pull --ff-only
if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar branch de motivo" }

.\.venv\Scripts\python.exe .\tools\preflight_dim_motivo_saida_permanencia.py
if ($LASTEXITCODE -ne 0) { throw "Preflight DIM_MOTIVO_SAIDA_PERMANENCIA falhou" }
```

**Se aprovado**, o preflight retornará `REFERENCE_ROWS=28`, `REFERENCE_DISTINCT_SOURCE_CODES=28`, `REFERENCE_CODE_24=2.4`, `REFERENCE_QVD_ROWS=28`, `RD_FILES=36`, `RD_ROWS=566672`, `RD_UNMATCHED=0`, `QVD_GENERATED=False`, `OUTPUT_FILES_WRITTEN=0`, terminando com `VERDICT=PASS_MOTIVO_28_CODE_REFERENCE_AND_RD_PREFLIGHT_ONLY`.

## Hipótese de implementação — ainda não aprovada para Reload

**HIPÓTESE DE MODELAGEM:** uma linha por **código fonte `COBRANCA`** normativo (28 linhas), chave `Hash128('MOT', codigo_fonte)`, atributos físicos de código fonte sem ponto, código normativo pontuado, descrição oficial, grupo/categoria de encerramento e rastreabilidade às portarias. Definir nomes físicos somente depois da inspeção e do preflight PASS; não criar include, QVD dimensional, checkpoint, PR ou fatos antecipadamente.

**DECISÕES PENDENTES:** compatibilidade completa físico-textual entre RD/SIH, CSV corrigido e QVD C1, distribuição real por código, regra de forma textual efetiva no QlikView 12 e campos físicos definitivos. Preservar `T29_HISTORICAL=NOT_APPROVED` e o relatório acadêmico impresso intacto.

**Estado final deste checkpoint de Discovery:** `main=6/8 DIMENSOES INTEGRADAS`; `MOTIVO=READ_ONLY_PREFLIGHT_CODE_READY_NOT_RUN`.
