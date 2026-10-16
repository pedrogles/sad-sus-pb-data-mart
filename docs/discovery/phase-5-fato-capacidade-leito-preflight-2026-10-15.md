# Fase V — Gate isolado da FATO_CAPACIDADE_LEITO (CNES/LT)

**Data:** 15/10/2026. **Base:** `main` no squash do PR #88 (`7abd1dc50c092e4235fc811fa63e4dd3a30344ac`). **Branch:** `feat/phase-v-capacidade-leito-preflight-20261015`.

**Estado:** `CAPACIDADE_PREFLIGHT=SCRIPT_READY_NOT_EXECUTED`; `FATO_CAPACIDADE_LEITO.qvd=NOT_GENERATED`. O PR desta etapa será Draft. **Este gate não implementa a fato** e não aprova `%LINK_KEY`, Link Table ou medidas para indicadores.

## Objetivo e escopo fechado

Realizar **uma única pré-validação técnica isolada, somente leitura de QVDs**, antes de implementar `FATO_CAPACIDADE_LEITO`. Reutiliza 1 QVD de staging LT e 4 dimensões da Fase IV. Cria apenas um QVW descartável e seu log; não executa `TRANSF.qvw`, `transf_main.qvs`, `STORE`, atualização da extração ou outro processo.

**Fonte hierárquica consultada:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, material acadêmico `chapter-1-2-modeling.md`, `boundary-6-qlikview-physical-architecture.md`, `boundary-7-implementation-plan.md`, `dataset-validation.md`, `boundary-3-full-dataset-validation.md`, `phase-4-dim-tipo-leito-discovery-2026-10-09.md`, `EXTRACAO/ext_main.qvs`, `TRANSFORMACAO/transf_dim_tipo_leito.qvs` e `transf_dim_estabelecimento.qvs` em `main`. Os resultados anteriores são evidência de CSV e/ou QVD de dimensões, **não** desta execução nova.

**Campos físicos comprovados em `SRC_CNES_LT.qvd`:** `CNES`, `CODUFMUN`, `TP_LEITO`, `CODLEITO`, `COMPETEN`, `QT_EXIST`, `QT_SUS`, `QT_NSUS`, `_META_SOURCE_FILE`, `_META_SOURCE_COMPETENCE`. Não há suposição de coluna adicional. A origem possui 35.518 linhas e 36 competências 201701–201912; preserva todos os registros válidos.

## Contrato da pré-validação

| Eixo | Critério mensurável no QlikView |
| --- | --- |
| Grão LT | 35.518 linhas e 35.518 valores distintos do hash técnico **temporário de pré-validação** para `(CNES,COMPETEN,CODLEITO)`; nenhuma SK da fato aprovada neste teste |
| Período/proveniência | 36 competências; 36 arquivos; competência da linha corresponde ao metadado do arquivo |
| Domínio de tipo e leito | `TP_LEITO` QVD somente `N` ou `N ` com `N=1..7`, `CODLEITO` textual de 2 dígitos; 57 pares globais e 2.021 pares por competência |
| Regressões A2 | `3/66=1480`, `7/70=5`; sem converter `3/66` em `2/66` |
| Cinco papéis | 0 órfãos de `%SK_TEMPO_COMPETENCIA`, `%SK_TEMPO_ANO`, `%SK_MUNICIPIO_SERVICO`, `%SK_ESTABELECIMENTO`, `%SK_TIPO_LEITO` nas dimensões QVD existentes |
| Medidas | `QT_EXIST`, `QT_SUS`, `QT_NSUS` numéricos inteiros não negativos; `QT_SUS<=QT_EXIST`; `QT_NSUS=QT_EXIST-QT_SUS`; 0 inconsistências |
| Integridade de arquivos | SHA-256 de **todos** os QVDs preexistentes em `EXTRACAO/QVD` e `TRANSFORMACAO/QVD` inalterado; nenhum QVD novo |
| Fonte de evidência | Log nativo do QlikView 12 e saída do runner com `SCRIPT_SHA256`, totais e `VERDICT` |

**Medidas:** o script imprime os somatórios de todos os snapshots no TRACE `SNAPSHOT_SUMS_UNSAFE_AS_PERIOD_TOTAL` somente para conciliação/diagnóstico; **não** são a oferta de leitos do período nem uma medida anual válida. A média dos totais mensais por competência e as regras de denominador da V2 pertencem a gates posteriores, não a este. Não inventar totais esperados antes da execução real.

**Papéis:** os hashes são calculados conforme scripts dimensionais existentes: `MES` e `ANO` via DIM_TEMPO, `MUN` para serviço, `ESTAB` em `CNES+COMPETEN`, `LEITO` com tipo textual normalizado, código textual e competência observada do LT (A2). A pré-validação confere domínio/cobertura sem materializar associações ou `%LINK_KEY`.

**Restrições vigentes:** `T29_HISTORICAL=NOT_APPROVED`: legenda 201909 apenas para aquele mês; 1.965/2.021 pares-mês sem descrição histórica comprovada **não** representam percentagem de leitos físicos. `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`: não descartar LT por tipo de estabelecimento nem inferir hospitais de `TP_UNID` sem validação histórica. `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`.

## Implementação preparatória versionada

- `TRANSFORMACAO/phase_v_capacidade_leito_preflight.qvs` — somente LOAD/MAPPING/RESIDENT e TRACE; **zero STORE**.
- `tools/validar_fato_capacidade_leito_preflight_qlik.ps1` — cria QVW novo isolado, preserva inventário/hashes dos QVDs, verifica o log contemporâneo e resultado exato; recusa QVW/log/destino factual existentes.
- `.gitignore` — ignora QVW de diagnóstico; nenhum QVD/QVW será enviado ao Git.

**Execução única proposta no Windows, com QlikView Desktop 12 e QVDs locais disponíveis:**

```powershell
git fetch origin
git switch feat/phase-v-capacidade-leito-preflight-20261015
git pull --ff-only
powershell.exe -NoProfile -File .\tools\validar_fato_capacidade_leito_preflight_qlik.ps1 -Root (Get-Location).Path
```

**Somente após execução e log nativo:** `VERDICT=PASS_LOCAL_QV_CAPACIDADE_LT_PREFLIGHT_ONLY_NOT_QVD_APPROVAL`. O script **ainda não foi executado**; até lá, o estado é `PENDING_NATIVE_QV12`.

**STOP/FAIL CLOSED:** diante de falha de script, contagem, papéis, medidas, domínio, SHA, log ou COM, interromper e enviar stdout/log. Não repetir, limpar arquivos, sobrescrever fontes, gerar `FATO_CAPACIDADE_LEITO.qvd` nem iniciar Link Table. O gate termina com um resultado PASS ou BLOCKED documentado. Depois de PASS, o contrato de grão/medidas pode ser usado como insumo de proposta da implementação factual **em PR próprio e mediante autorização específica**.

**Separação:** atualização do estado pós-PR #88 está em outro PR documental (não será acoplada a este preflight).
