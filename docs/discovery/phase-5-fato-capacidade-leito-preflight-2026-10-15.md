# Fase V — Gate isolado da FATO_CAPACIDADE_LEITO (CNES/LT)

**Data:** 15/10/2026. **Base:** `main` no squash do PR #88 (`7abd1dc50c092e4235fc811fa63e4dd3a30344ac`). **Branch:** `feat/phase-v-capacidade-leito-preflight-20261015`.

**Estado atualizado após evidência local:** `CAPACIDADE_PREFLIGHT=PASS_LOCAL_QV_READ_ONLY_REPORTED`; `FATO_CAPACIDADE_LEITO.qvd=NOT_GENERATED`. O PR permanece Draft, sem merge. **Este gate não implementa a fato** e não aprova `%LINK_KEY`, Link Table, indicadores ou produção.

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

**Execução concluída no Windows, segundo saída e log nativo apresentados pelo responsável:** `VERDICT=PASS_LOCAL_QV_CAPACIDADE_LT_PREFLIGHT_ONLY_NOT_QVD_APPROVAL` em 15/10/2026, 21:50:58–21:50:59. Não executar novamente o mesmo comando nem excluir QVW/log. A prova é **reportada**, não auditoria independente dos arquivos binários locais.

**STOP/FAIL CLOSED:** diante de falha de script, contagem, papéis, medidas, domínio, SHA, log ou COM, interromper e enviar stdout/log. Não repetir, limpar arquivos, sobrescrever fontes, gerar `FATO_CAPACIDADE_LEITO.qvd` nem iniciar Link Table. O gate termina com um resultado PASS ou BLOCKED documentado. Depois de PASS, o contrato de grão/medidas pode ser usado como insumo de proposta da implementação factual **em PR próprio e mediante autorização específica**.

**Separação:** atualização do estado pós-PR #88 está em outro PR documental (não será acoplada a este preflight).


## Evidência local recebida — gate PRE-FLIGHT encerrado (15/10/2026)

**Proveniência:** transcrição integral de stdout PowerShell e linhas de log nativo fornecidas pelo responsável no chat após execução em Windows/QlikView Desktop 12. Não houve acesso independente pelo agente aos QVDs, ao QVW ou ao log completo do disco local. A validade é restrita aos QVDs existentes naquele ambiente/snapshot; não equivale a aceite físico do QVD da fato (não criado).

| Controle | Resultado reportado |
| --- | --- |
| Branch | `feat/phase-v-capacidade-leito-preflight-20261015` (atualizada) |
| Runner | `tools/validar_fato_capacidade_leito_preflight_qlik.ps1` |
| Modo | `PHASE_V_CAPACIDADE_LT_READ_ONLY_PREFLIGHT` |
| SHA-256 QVS | `0E879AFB0DC2D6D487D17E8540106F89AF3AD6FA678A3BA6F70A5F5DD3ADA82E` |
| QVDs no inventário antes/depois | `QVD_INVENTORY_BEFORE=19`; `ALL_EXISTING_QVDS_SHA256_UNCHANGED=True COUNT=19` (reportado duas vezes: execução e finalização) |
| Recarga isolada | `TRANSF_MAIN_NOT_EXECUTED=True`; `RELOAD_STARTED=True`; `RELOAD_RETURNED=True`; `RELOAD_API_RETURN=` (COM vazio; log nativo contemporâneo presente) |
| Grão, tempo, domínio | `ROWS=35518 UNIQUE_GRAIN=35518 MONTHS=36 FILES=36 PAIRS=57 PAIR_MONTHS=2021 TYPE3_BED66=1480 TYPE7_BED70=5 DOMAIN_BAD=0` |
| Medidas | `MEASURE_BAD=0`: validações Qlik numéricas, não-negativas, inteiras, `QT_SUS<=QT_EXIST` e `QT_NSUS=QT_EXIST-QT_SUS` |
| Cinco papéis dimensionais | `COMP=0 ANO=0 MUNICIPIO_SERVICO=0 ESTABELECIMENTO=0 TIPO_LEITO=0` órfãos |
| Agregados diagnósticos dos 36 snapshots | `EXIST=337147 SUS=270076 NSUS=67071` (`337147-270076=67071`); **não** interpretar como leitos de uma competência ou capacidade anual |
| Log Qlik, 21:50:59 | `VERDICT=PASS_QV_CNES_LT_READ_ONLY_PREFLIGHT_CANDIDATE_ONLY` |
| Runner PowerShell | `VERDICT=PASS_LOCAL_QV_CAPACIDADE_LT_PREFLIGHT_ONLY_NOT_QVD_APPROVAL` |
| Fora do escopo | `FACT_CAPACIDADE_QVD_GENERATED=False`; `LINK_TABLE_NOT_TESTED=True`; `PRODUCTION_APPROVED=False` |

**FATO VERIFICADO pela transcrição e verificações implementadas no executor:** o QlikView carregou o QVD CNES/LT e as quatro dimensões existentes; o runner recebeu marcadores nativos exatos para as cardinalidades, medidas, cinco papéis e status; calculou hashes do inventário dos 19 QVDs antes/depois, sem observar criação ou mudança; não houve `STORE` no QVS.

**Condição de parada atingida:** `CAPACIDADE_PREFLIGHT=PASS_LOCAL_REPORTED`. Não repetir o gate. O próximo passo, **ainda dependente de autorização distinta**, é propor o QVS da segunda fato e um novo `PREFLIGHT` de implementação isolado com critérios próprios, sem materializar QVD de capacidade antes de aprovação explícita do gate CREATE. Não alterar `transf_main.qvs` em modo automático; preservar `FATO_INTERNACAO.qvd`, os 19 QVDs atuais, `T29_HISTORICAL=NOT_APPROVED` e os contratos semânticos/associativos ainda pendentes.

**PR de pré-validação:** #90 permanece Draft, não integrado à `main`. Revisão para eventual merge e autorização específica ficam para etapa separada. **`PR_MERGED=False`; `PROD_APPROVED=False`.**
