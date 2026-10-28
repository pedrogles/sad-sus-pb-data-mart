# SAD-P2.3-A1-PHYSICAL-GATE-01 — implementação candidata

**Estado:** `IMPLEMENTATION_VERSIONED / PHYSICAL_NOT_RUN / VISUAL_NOT_TESTED`.  
**Autorização:** conversa com responsável em 28/10/2026 autorizou corrigir drift e implementar A1. Merge, atualização dos QVD/QVW canônicos, Fase IX e homologação não foram autorizados.  
**Baseline:** `main@cdb6810c1e89b0fa86954f6478aaf9c49f2018ce` após PR #168. Documentação canônica: [contrato A1](sad-p23-a1-logical-design-2026-10-28.md), [VI-P4](../../TRANSFORMACAO/vi_p4_municipal_coverage.qvs), [C4-F](phase-8-c4f-vi-p4-export-readback-2026-10-21.md). PR #167 permanece Draft com `A0_NOT_VALIDATED` apenas para R1.

## Escopo tocável e artefatos

- `PAINEL/sad_p23_a1_island_physical_gate.qvs`: anexa uma tabela em memória `P23_A1_ISLAND`, derivada dos cálculos já existentes da `P4_MATRIX` e da reconciliação LT/fato. Não faz STORE, não cria QVD nem altera fatos/dimensões ou Link Key.
- `tools/Invoke-SadP23A1PhysicalGate01.ps1`: usa `PAINEL/phase_vii_technical_model.qvs` (16 tabelas) + ilha A1 (17ª tabela) apenas em QVW descartável em TEMP. Faz preflight de commit/branch, QVDs, log e hashes de **26 arquivos protegidos** (22 QVD, três QVW, um CSV). `-Prepare` cria cópia temporária e realiza checks do modelo; `-Verify` compara `path,bytes,sha256` por linha, prevenindo o falso positivo de serialização da R1.
- Este documento: execução manual e evidências, **não** teste executado.

Os seis únicos campos finais, todos exclusivos e propostos, são `P23_MUNICIPIO_6`, `P23_COMPETENCIA`, `P23_LINHAS_LT`, `P23_QT_SUS_OBSERVADO`, `P23_QT_EXIST_OBSERVADO` e `P23_ESTADO_OBSERVADO`. Seletor de município/competência local ao P2.3, **sem sincronização presumida** com seleções SERV/RES/tempo globais. A ausência LT mantém medidas NULL; jamais zero imputado. `ZERO_REAL_COMPROVADO=NOT_PROVEN`; `COBERTURA_HOSPITALAR=NOT_VERIFIED`.

## Uma única execução futura no Windows/QlikView 12

A execução deve partir da branch `feat/sad-p23-a1-physical-gate-01` em commit previamente conferido, com scripts versionados e limpos. Exigir Windows interativo, QlikView Desktop 12 e diretório de evidências **novo**, persistente, fora do Git e TEMP. O executor não é headless comprovado.

```powershell
$Root = (Get-Location).Path
$Head = (git rev-parse HEAD).Trim()
$EvidenceRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'SAD-EVIDENCIAS\P23_A1_R1'
$Auth = 'chat-2026-10-28-p23-a1-implementation'
powershell.exe -NoProfile -File tools\Invoke-SadP23A1PhysicalGate01.ps1 -Root $Root -ExpectedCommit $Head -EvidenceRoot $EvidenceRoot -ExecutionAuthorizationRef $Auth -Prepare
```

Antes da execução conferir o `HEAD` do PR, parser PowerShell no Windows, SHA-256 dos dois QVS e runner, 22 QVDs e três QVWs originais. O script falha fechado se o pin de Link QVD divergir, se houver campo inválido ou se a carga física não reconciliar.

**Oráculo obrigatório:** 223 municípios × 36 competências = **8.028 pares**, com **4.467** `ABSENT_NOT_ZERO_PROVEN`, **97** `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` e **3.464** `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED`. São 3.561 pares com linha, soma `LINHAS_LT=35.518`, soma observacional SUS=270.076 e existentes=337.147 (apenas reconciliação de snapshots, **não** capacidade anual).

O resultado máximo da preparação é `A1_TEMP_MODEL_PREPARED_VISUAL_NOT_TESTED`, nunca homologação de UX.

## Prova manual em um QVW temporário

Abrir apenas o caminho `TEMP_QVW` reportado. Em um único objeto de teste, apresentar campos próprios `P23_MUNICIPIO_6`, `P23_COMPETENCIA`, `P23_ESTADO_OBSERVADO`, as linhas e medidas observadas, conservando NULL nas ausências. Preferir tabela reta inicialmente para não ocultar combinações. Exibir o aviso: **“Filtros próprios de P2.3 — não sincronizados com filtros globais. Observabilidade CNES/LT sem comprovação de zero real ou cobertura hospitalar.”**

**Amostras C4-F em competência `201701`:**

| Município | Classe | Linhas LT | SUS | Existentes |
| --- | --- | ---: | ---: | ---: |
| `251740` | `ABSENT_NOT_ZERO_PROVEN` | NULL | NULL | NULL |
| `250460` | `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` | 1 | 0 | 40 |
| `250010` | `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED` | 3 | 20 | 20 |

Capturar estado neutro, três amostras, seleção municipal e temporal **locais** e conflito intencional em filtro **global** (SERV/tempo). A1 não pode mudar por seleção global e a seleção local A1 não deve alterar fatos. Se a interface suprimir NULL/células ou trocar ausência por zero, `BLOCKED`. Conferir Table Viewer: 17 tabelas, A1 sem vínculo, nenhuma `$Syn` ou loop. Exportar pares completos da ilha (preservando NULL) e comparar contra o TXT **histórico** C4-F; **não** reexecutar VI-P4.

Salvar prints, propriedades, log, exportação, manifesto e evidências humanas fora do Git. PNG/propriedade COM isolados não provam semântica/UX.

## Integridade e STOP

Após encerrar edição do QVW temporário e na mesma branch/commit/evidência, executar exatamente uma vez:

```powershell
powershell.exe -NoProfile -File tools\Invoke-SadP23A1PhysicalGate01.ps1 -Root $Root -ExpectedCommit $Head -EvidenceRoot $EvidenceRoot -ExecutionAuthorizationRef $Auth -Verify
```

`-Verify` checa hashes dos 26 artefatos e registra SHA do QVW temporário, **não** declara visual aprovado. A decisão após revisão das evidências será `PASS_LOCAL_A1_P23_CANDIDATE_ONLY`, `BLOCKED` ou `INCONCLUSIVE`; nenhum destes é `PRODUCTION_APPROVED`.

**STOP:** não abrir R2, repetir R1 A0, mesclar automaticamente, sobrescrever QVD/QVW, iniciar Fase IX/G1/T24–T26, alterar RN21/V2, Link Key ou modelo acadêmico. **Esta sessão criou apenas código e documentação no GitHub; Windows/QlikView/COM não foram executados.**


## Adendo — R1 bloqueada por sintaxe QVS (28/10/2026)

**EVIDÊNCIA DE OPERADOR (Windows/QlikView 12, console + trechos de log fornecidos na conversa):** execução `-Prepare` no commit `82ab0d644822134add964e61a1a168fa3329ede5`, diretório de evidências `SAD-EVIDENCIAS/P23_A1_R1`. `PARSER=PASS` do PowerShell; o log retornou `VII_PASS=1`, `A1_PASS=0`, `BLOCKED=0`, `ASSOCIATION_WARNING=0`. O modelo VII marcou `MODEL_TABLES=16 SYN_TABLES=0`. A ilha iniciou e passou a construção da população 669/223/669 e carregamento de 35.518 LT. No ponto `P23_LT_AUDIT`, o log exibiu `35.518=35.518`, `36=36`, `270076=270076`, `337147=337147`, `67071=67071`, `0=0`, mas interrompeu **antes de avaliar o IF completo**, apontando `Erro: Comando desconhecido` ao encontrar o `OR` na linha seguinte. Não houve `P23_A1_ISLAND` final provada.

**CAUSA RAIZ DELIMITADA:** no QVS da R1, **três comandos IF de controle** ultrapassavam a linha física de script (LT/fato, prejoin, oráculo final). A regra oficial de `if..then` no QlikView exige a cláusula `IF condição THEN` em uma só linha; quebras dentro de funções `If(...)` usadas em LOAD não se confundem com comandos de controle. Corrigidas as três condições em linha única na branch de implementação, **sem modificar operadores, números, campos ou oráculos**, conforme diff do PR #170.

**VEREDITO:** `R1=BLOCKED_QVS_IF_SYNTAX`; a contagem de LT e suas somas até o erro **não** são `PHYSICAL_PASS` da A1. `R1_PROTECTED_HASHES=NEEDS_MANIFEST_COMPARISON`: os arquivos `protected_before.json` e `protected_after_preparation.json` foram gerados, mas a integridade precisa ser comparada a partir dos manifestos originais; tamanhos de arquivos iguais não bastam. Não repetir `-Prepare` nem executar `-Verify` contra `P23_A1_R1`.

**UM único reteste candidato, se executado:** antes, comparar os 26 registros `path,bytes,sha256` do R1 e bloquear divergências; após `git fetch` e checkout do **novo HEAD revisado**, usar **pasta de evidências NOVA**, por exemplo `P23_A1_R2` (não reutilizar a R1), e repetir um único `-Prepare`. Se houver novo bloqueio, preservar log, classificar causa e STOP; não encadear R3 automático. Esta correção em Git é revisão estática, **não reexecução QlikView**. PR permanece Draft, sem merge.
