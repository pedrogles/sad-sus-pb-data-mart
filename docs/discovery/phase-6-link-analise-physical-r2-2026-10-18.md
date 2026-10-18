# Fase VI — LINK_ANALISE: evidência local R1/R2, CREATE + READBACK e publicação candidata

**Data:** 18/10/2026. **Gate:** VI-LINK-PHYSICAL. **Estado:** `PASS_LOCAL_CREATE_READBACK_AND_ATOMIC_PUBLISH_CANDIDATE_ONLY` **reportado localmente**.  
**Commit QlikView/Windows R2:** `9c2905c0e67e2bfde9a0db941e35ffd2ed75289a` ([PR #103](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/103) integrado).  
**Contrato físico:** [VI-P5 SAD-LINK-V1](phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md); [preparação](phase-6-link-analise-create-readback-preparation-2026-10-17.md); [Boundary 7](boundary-7-implementation-plan.md), testes T17–T19.

## Escopo e limites da evidência

O objetivo contratado foi **uma** criação física candidata de `TRANSFORMACAO/QVD/LINK_ANALISE.qvd`, seguida de READBACK em QVW descartável independente e publicação por movimentação sem sobrescrita. Não inclui painel final, carga de `TRANSF.qvw`/`PAINEL.qvw`, aprovação semântica de `%LINK_KEY`, métricas, produção ou Fase VII.

**Origem das evidências:**
- **Execução local reportada pelo responsável:** stdout PowerShell do inventário, tentativa R1 e tentativa R2 fornecidos na conversa em 18/10/2026. Não foram executados remotamente neste repositório, em CI ou pelo agente.
- **Log nativo R1:** trecho de `VI_LINK_CREATE.qvw.log` compartilhado pelo responsável e analisado; a falha de sintaxe foi localizada no bloco `IF` anterior a `STORE`.
- **Código conferido no GitHub:** runner `tools/Invoke-SadViLinkAnalise.ps1` e três QVS na `main` após #103.
- **Limitação:** os arquivos binários QVD/QVW, o log nativo R2 completo e os CSVs originais dos manifestos não foram copiados/inspecionados independentemente. O PASS é **local reportado, não homologação de produção**.

## Tentativa R1 — BLOCKED, sem publicação

- **Commit:** `eeea5c0f19476359d1e3f2b933b1f1ef369fd3d0`.
- **Diretório de evidência reportado:** `%TEMP%\SAD_VI_LINK_2594739de87d43859eb88f4ae85a4111`.
- VI-P1 concluiu com `P1 LINK_SIMULADA_ROWS=85705`; antes do STORE, `PRESTORE ROWS=85705 KEYS=85705 RD=77550 LT=7486 POP=669 BAD=0 POP_ROLE_BAD=0`.
- O log mostrou erro na condição `IF` repartida em linhas independentes (linha `OR 77550<>77550...`, seguida de `Comando desconhecido`); o executor registrou `VERDICT=BLOCKED_OR_INCONCLUSIVE` por ausência de marcador único de sucesso/bloqueio.
- Inspeção local de diretório reportou **nenhum** `VI_LINK_STAGE_*.qvd` nem `LINK_ANALISE.qvd`; o stdout informou `ORIGINAL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True`. READBACK não ocorreu.
- **Correção:** [PR #103](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/103) tornou unilinha o `IF ... THEN` do CREATE e, preventivamente, duas cláusulas do READBACK. Squash merge `9c2905c0e67e2bfde9a0db941e35ffd2ed75289a`; sem mudança das comparações, fórmula de hash, cardinalidades ou regras de negócio.

## Inventário e tentativa R2 — PASS físico local reportado

Após `git fetch` e fast-forward para `9c2905c0e67e2bfde9a0db941e35ffd2ed75289a`, o inventário R2 concluiu com:
- `STATIC_PRECHECK=PASS`
- `VERDICT=PASS_INVENTORY_ONLY_NOT_PHYSICAL`
- `LINK_ANALISE_QVD_GENERATED=False`
- `ORIGINAL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True`

**Uma única tentativa R2 foi explicitamente autorizada pelo responsável e executada localmente.**

| Verificação reportada | Marcador/resultados do stdout |
| --- | --- |
| Preflight e modo | `R2_PREFLIGHT=PASS`; `MODE=PHYSICAL_EXPLICIT`; `STATIC_PRECHECK=PASS` |
| Commit | `VERSIONED_GIT_HEAD=9c2905c0e67e2bfde9a0db941e35ffd2ed75289a` |
| CREATE | `NATIVE_PASS_VI_LINK_CREATE=[VI-LINK] VERDICT=PASS_STORE_ONLY_READBACK_REQUIRED` |
| SHA do staging | `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB` |
| READBACK em QVW distinto | `NATIVE_PASS_VI_LINK_READBACK=[VI-LINK-RB] VERDICT=PASS_PHYSICAL_QVD_READBACK_CANDIDATE_ONLY` |
| SHA final | `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB` |
| Publicação | `PUBLISH_METHOD=SAME_DIRECTORY_NON_OVERWRITING_FILE_MOVE` |
| Integridade de origem | `ORIGINAL_21_QVD_SHA256_AND_HEADERS_UNCHANGED=True` |
| Veredito e encerramento | `VERDICT=PASS_LOCAL_CREATE_READBACK_AND_ATOMIC_PUBLISH_CANDIDATE_ONLY`; `R2_PROCESS_EXIT=SUCCESS` |

**Caminhos locais reportados (preservar; não versionar binários/logs):**
- Stdout R2: `C:\Users\pedro\AppData\Local\Temp\SAD_VI_LINK_PHYSICAL_R2_4eb38df0992141aab754f4a65949a919.txt`
- Evidências R2: `C:\Users\pedro\AppData\Local\Temp\SAD_VI_LINK_53de908f5d58428e82e71385f4ff28a8`
- Destino candidato: `TRANSFORMACAO/QVD/LINK_ANALISE.qvd` (novo; adicional aos 21 QVDs originais).

**SHA-256 dos scripts reportados na execução R2:**

| Arquivo | SHA-256 |
| --- | --- |
| `tools/Invoke-SadViLinkAnalise.ps1` | `A7ED83CAC24BA1A3529C1C6B7CF6584B5D3D8604A48F49592BF27662F682930E` |
| `TRANSFORMACAO/vi_p1_readonly.qvs` | `80E80770C59FBCC48142DA8E4CE6BF87D3CD6113FCACEA0CA78558B` |
| `TRANSFORMACAO/vi_link_analise_create_tail.qvs` | `2FF5D9637EE07812886AA70463EFE00B0A588E1050CD4EE46E866D8BFEC48068` |
| `TRANSFORMACAO/vi_link_analise_readback.qvs` | `B658A4DC6F47455F6FE4F1553DB604E9DAA73E35AC14923C7CA79E9675A7C309` |

## Contrato verificado pelo runner (qualificação: PASS local reportado)

O código R2 do runner confere o cabeçalho físico com **85.705 registros e seis campos nesta ordem**:

1. `%LINK_KEY`
2. `%SK_TEMPO_COMPETENCIA`
3. `%SK_TEMPO_ANO`
4. `%SK_MUNICIPIO_RESIDENCIA`
5. `%SK_MUNICIPIO_SERVICO`
6. `%SK_ESTABELECIMENTO`

O QVS de READBACK confere 85.705 `%LINK_KEY` distintas, 77.550 tuplas RD + 7.486 LT + 669 POP, nulos/papéis e zero divergências de `Hash128('SAD-LINK-V1', ...)`. Confere a cobertura de **566.672** registros FI, **35.518** LT e **669** POP projetados em memória, exigindo **zero** chaves ausentes. O runner só publica depois do segundo QVW e da comparação de hashes/cabeçalhos dos 21 QVDs; compara SHA-256 do staging e destino após `File.Move`.

**T17 (chave factual presente), T18 (cobertura), T19 (órfãos obrigatórios)**: controles cobertos pelo READBACK candidato e **reportados PASS pelos marcadores do executor**; não são uma aprovação independente da associação do painel, de loops ou de synthetic keys da constelação final. `FATO_POPULACAO.qvd` permanece com suas sete colunas originais, com projeção de chave apenas em memória; Fase VII ainda pendente.

## Gate e condição de parada

- `VI_LINK_PHYSICAL_GATE=PASS_LOCAL_REPORTED_CANDIDATE_ONLY`
- `LINK_ANALISE_QVD=CREATED_AND_READBACK_LOCAL_REPORTED`
- `LINK_KEY_CONTRACT=NOT_APPROVED`
- `PANEL_NOT_TESTED=True`
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`
- `PRODUCTION_APPROVED=False`

**STOP:** encerrar a tentativa R2 e não reexecutar CREATE/READBACK. Preservar o novo QVD, 21 QVDs originais, logs e manifestos R1/R2. Próxima ação separada é revisão/merge documental; somente autorização específica posterior pode iniciar Fase VII, sem alterar a modelagem acadêmica aprovada.
