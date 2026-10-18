# Fase VI — Auditoria estática do runner e proteção da publicação da Link Table

**Data:** 18/10/2026. **Base inspecionada:** `main@b1b0c200e5ce75670ea5d9c656ec94761fc0a37b` (PR #100 integrado).
**Gate nesta execução:** `VI_LINK_PUBLISH_GUARD_REVIEW=STATIC_CANDIDATE_ONLY`.
**Natureza:** revisão estática e proposta de correção versionada em PR Draft, **sem Windows/QlikView 12, sem recarga, sem CREATE de QVD, sem merge**.

## Objetivo delimitado

Revisar o executor versionado `tools/Invoke-SadViLinkAnalise.ps1`, confirmar integridade da fonte VI-P1 e fechar o risco de corrida entre `Test-Path` e `STORE` direto no destino definitivo. Não alterar o `SAD-LINK-V1`, as cinco coordenadas, as três fatos, oito dimensões, POP em memória, granularidades, medidas ou arquitetura acadêmica.

## Fontes e fatos verificados

1. `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md` da `main`, nessa ordem.
2. `docs/discovery/boundary-7-implementation-plan.md`, `boundary-6-qlikview-physical-architecture.md`, `phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md` e `docs/project/qlikview-powershell-automation.md`.
3. `TRANSFORMACAO/vi_p1_readonly.qvs`, `TRANSFORMACAO/vi_link_analise_create_tail.qvs`, `TRANSFORMACAO/vi_link_analise_readback.qvs`, `tools/Invoke-SadViLinkAnalise.ps1`.

**FATO VERIFICADO — hash:** foi recalculado o SHA-256 do texto de `vi_p1_readonly.qvs` obtido diretamente pelo conector GitHub (UTF-8 preservado); resultado `80E80770C59FBCC48142DA8E4CE6BF87D3CD6113FCACE977E0DACEA0CA78558B`, **igual** ao esperado no executor. Isso não equivale à checagem dos bytes/QVDs locais do Windows.

**FATO VERIFICADO — risco:** o código do PR #100 usava o mesmo caminho de destino `TRANSFORMACAO/QVD/LINK_ANALISE.qvd` no `STORE` Qlik. A sequência `Test-Path` + `FileSize` antes do `STORE` **não impede sobrescrita concorrente** se o destino surgir entre a verificação e a gravação. **Não é seguro afirmar proteção contra overwrite com a versão anterior.**

## Correção proposta neste PR

1. Gerar um **nome aleatório exclusivo de staging** `TRANSFORMACAO/QVD/VI_LINK_STAGE_<GUID>.qvd` no mesmo diretório do QVD final.
2. O único `STORE` QlikView grava **somente no staging**, nunca em `LINK_ANALISE.qvd`.
3. Conferir cabeçalho e SHA-256 do staging; executar o READBACK em outro QVW descartável apontando para o staging, exigindo 85.705 chaves/tuplas únicas e cobertura das três fatos.
4. Reconferir hashes e cabeçalhos dos **21 QVDs de origem** imediatamente antes da publicação. `SnapshotOriginals` ignora apenas o arquivo de staging desta execução e o destino reservado `LINK_ANALISE.qvd`, mas continua rejeitando outros QVDs desconhecidos, inclusive staging órfão de execução anterior.
5. Realizar a publicação com `[IO.File]::Move($stage,$dest)` **sem opção de overwrite**, ambos no mesmo diretório. Se o destino aparecer por concorrência, `Move` deve falhar, deixando staging/evidências preservados; não remover nem renomear destino alheio.
6. Após a publicação, conferir cabeçalho e SHA-256 contra o staging aprovado. Mantém-se a comparação final dos 21 QVDs no `finally`, sem exclusões/rollback automático.

**Decisão técnica candidata, não testada fisicamente:** esse desenho troca a checagem não atômica `Test-Path → STORE final` por `STORE estágio único → READBACK → File.Move não sobrescrevente` no mesmo volume. Requer confirmação da semântica de `File.Move` e do comportamento do QlikView 12 **no Windows do projeto** antes de liberar o modo físico. Staging parcial deve permanecer para auditoria em caso de falha e **impedir repetição automática**.

## Critérios do próximo gate (ainda não executado)

- **Modo seguro de inventário:** rodar o executor versionado **sem** `-ExecutePhysical` em Windows com o repositório atualizado, confirmar HEAD, 21 schemas/hashes, SHA-256 do VI-P1, ausência de `LINK_ANALISE.qvd`/artefatos estranhos e `VERDICT=PASS_INVENTORY_ONLY_NOT_PHYSICAL`.
- **Verificação adicional da proteção:** em ensaio descartável e sem Qlik, provar `File.Move` sem overwrite diante de destino pré-existente/concorrente no mesmo volume, sem acessar arquivos de produção. Pode ser feita separadamente sob escopo autorizado; não considerar esta revisão como PASS.
- **Gate físico posterior:** exige autorização específica distinta; só então permitir `-ExecutePhysical -ConfirmPhysicalWrite -AuthorizedCommit <SHA40_APROVADO>`. Executar única criação controlada, READBACK independente, publish fail-closed, logs e manifesto. Na primeira divergência, BLOCKED e STOP.
- **Fase VII:** nenhum painel, filtros, KPI, `$Syn` ou loops do modelo completo homologado.

## Governança e estados

- `PR_100=MERGED` — código original preparado, **não executado**.
- `VI_LINK_PUBLISH_GUARD_REVIEW=STATIC_CANDIDATE_ONLY` — este PR precisa de revisão e autorização de merge.
- `VI_LINK_WINDOWS_INVENTORY=NOT_RUN` — ambiente Windows/QlikView e QVDs locais indisponíveis nesta execução.
- `VI_LINK_PHYSICAL_CREATE=NOT_AUTHORIZED_NOT_RUN`.
- `LINK_ANALISE_QVD=NOT_CREATED`.
- `LINK_KEY_CONTRACT=NOT_APPROVED`.
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`.
- `PRODUCTION_APPROVED=False`.

**STOP:** concluir revisão/PR Draft, sem merge/recarga/criação, sem expandir para modelos ou indicadores.
