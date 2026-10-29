# SAD — Diagnóstico do comparador de integridade P1.1/P1.2

**Gate proposto:** SAD-P11-P12-INTEGRITY-COMPARATOR-01
**Data:** 28/10/2026
**Baseline consultada:** main@9070806f26a1568948b0ce2b87c597beb7ec2d9e
**PR de origem:** #172, Draft; executor de origem e manifesto no commit d901df16ae78dc0c7ff2a2d05c439353e7219793
**Autorização:** responsável respondeu "certo, prossiga" à recomendação de priorizar a investigação do comparador; somente desenvolvimento/diagnóstico próprio, não merge, recarga nem retomada física da PoC.
**Agente:** ChatGPT GPT-6 + GitHub para preparação e revisão; esforço não exposto.
**Executor recomendado:** Codex Local / operador Windows PowerShell 5.1, registrando modelo/esforço realmente usados.
**Estado na elaboração:** SCRIPT_VERSIONED / WINDOWS_NOT_RUN / NATIVE_PARSER_NOT_RUN / CAUSE_UNDETERMINED.

## Objetivo único

Investigar a diferença observada entre o -Verify original, que mostrou PROTECTED_25_UNCHANGED=False, e a triagem manual posterior, que reportou 25/25 entradas com bytes/hash/caminhos correspondentes ao manifesto e STRICT_SNAPSHOT_EQUAL=True.

Sem causa contemporânea reproduzida, **não** classificar o -Verify como falso positivo e **não** promover a PoC original a PASS. Este gate faz uma leitura atual delimitada, não reconstrução de eventos passados.

## Fonte e escopo tocável

1. AGENTS.md; docs/project/current-state.md; docs/academic/requirements.md.
2. docs/project/agent-model-routing.md e docs/project/qlikview-powershell-automation.md.
3. Contrato de P1.1/P1.2 integrado via #171 e protocolo em #172.
4. Executor original tools/Invoke-SadP11P12VisualCopy01.ps1 na branch Draft do #172; o script original NÃO é alterado neste gate.
5. Manifesto já existente, fora do Git:
   C:\Users\pedro\Documents\SAD_P11P12_POC_EVIDENCIAS\SAD_P11P12_0fdafff22e86404284f66180214c2e74\p11p12_manifest.json

Protegidos: exatamente 10 QVDs EXTRACAO, 12 QVDs TRANSFORMACAO, três QVWs canônicos. **Nenhum binário é escrito ou aberto no QlikView.** O único artefato executável deste gate é tools/Inspect-SadP11P12IntegrityComparator01.ps1, commitado nesta branch.

O inspetor:
- recusa executar fora da branch/commit exatos informados, em versão local não rastreada/suja ou fora do Windows PowerShell 5.1;
- exige manifesto com proveniência, 25 entradas únicas dentro da raiz canônica e 10+12+3 caminhos permitidos;
- compara cada caminho sem depender da posição no array; compara tamanho/hash e sinaliza diferença literal de caminho;
- marca arquivo ausente/ilegível e possíveis alterações ocorridas enquanto calcula o SHA-256, via metadados pré/pós;
- também reproduz a igualdade textual do comparador original para distinguir divergência de conteúdo de ordenação/representação;
- não invoca COM, QlikView, Reload, STORE, Copy, SaveAs, Set-Content nem modifica QVD, QVW, manifesto ou evidência.

## Execução única no Windows nativo

Checkout limpo em branch própria, sem merge. Conferir previamente quaisquer arquivos locais não rastreados que possam colidir ao trocar branch. Não executar no GitHub cloud como se fosse o Windows local.

No PowerShell 5.1, estando na raiz do repositório e após sincronizar a branch do PR, preparar as variáveis:

    $root = (& git rev-parse --show-toplevel).Trim()
    $expected = 'INSERIR_SHA40_FINAL_PUBLICADO_NO_PR'
    $runner = Join-Path $root 'tools\Inspect-SadP11P12IntegrityComparator01.ps1'
    $manifest = 'C:\Users\pedro\Documents\SAD_P11P12_POC_EVIDENCIAS\SAD_P11P12_0fdafff22e86404284f66180214c2e74\p11p12_manifest.json'

Primeiro parser nativo, sem executar o script:

    $tok=$null; $err=$null
    [System.Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tok,[ref]$err) | Out-Null
    if ($err.Count -gt 0) { $err; throw 'BLOCKED_PS51_PARSER' }

Executar **uma** vez os testes sintéticos in-memory, sem insumos locais:

    & $runner -Root $root -ExpectedCommit $expected -SelfTest

As nove expectativas são: snapshot idêntico, reordenação sem alteração, hash diferente, tamanho diferente, arquivo ausente, entrada extra, diferença textual de maiúsculas/minúsculas no caminho, arquivo instável durante leitura e arquivo ilegível. PASS significa somente que o comparador classifica os fixtures.

Se todos passarem, executar **uma** leitura dos 25 arquivos, sem -Prepare/-Verify:

    & $runner -Root $root -ExpectedCommit $expected -ManifestPath $manifest

Não usar redirecionamento, Tee-Object, Out-File ou transcript nesta rodada; colar o stdout integral no chat. O comando é READ-ONLY, inclusive em relação à pasta de evidências.

## PASS/BLOCKED/STOP

**PASS_SYNTHETIC:** nove casos in-memory passam no PowerShell 5.1. **CURRENT_SNAPSHOT_MATCH:** 25 registros idênticos no momento da leitura e igualdade textual reproduzida. Ambos são observações deste novo gate, **nunca** PASS retroativo do #172.

**ROOT_CAUSE_REPRODUCED:** somente se houver diferença causal concreta identificada com artefato específico ou cenário reprodutível. Não deduzir a causa só porque outra leitura atual foi PASS.

**INCONCLUSIVE:** 25/25 atuais iguais, sem explicação do falso original; ou divergência entre status que não pode ser atribuída a fonte verificável.

**HARD_STOP:** hash/tamanho protegido diferente, arquivo ilegível/ausente, mudança durante hash, manifesto inesperado, branch/commit divergente ou qualquer escrita indevida. Encerrar e preservar evidências sem repetir a operação.

**STOP:** após parser, uma rodada de SelfTest e uma leitura real; sem reexecutar a PoC, sem alterar o runner original, sem R2/R3, sem merge. O próximo gate corretivo P1.2 (gráfico temporal) é separado e permanece não autorizado. LINK_KEY_CONTRACT=NOT_APPROVED, MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED, C2_FULL=NO_GO_NOT_APPROVED, P5_D2_UI=NOT_TESTED_GLOBAL, PHASE_IX=NOT_AUTHORIZED, PRODUCTION_APPROVED=False.
