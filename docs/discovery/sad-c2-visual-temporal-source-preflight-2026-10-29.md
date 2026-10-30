# SAD C2 — preflight mínimo de origem e integridade (somente preparação)

**Gate:** `SAD-C2-VISUAL-TEMPORAL-CONSUMPTION-01`, [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196).
**Subetapa:** `SAD-C2-SOURCE-PREFLIGHT-01`.
**Baseline:** `main@7827300c8772a1cdebef2238a7dd8064c13592d2`.
**Estado:** `PREFLIGHT_SCRIPT_VERSIONED_NOT_EXECUTED`; Windows/QlikView/PowerShell 5.1 locais não disponíveis para execução por este agente. **Não existe PASS físico novo.**
**Escopo tocável:** somente arquivos texto em branch e, numa futura execução Windows, leitura dos dois QVWs experimentais + 25 arquivos canônicos, com manifesto JSON isolado fora do Git. Não iniciar QlikView, COM, recarga, alterações canônicas, merge automático, modelos ou Fase IX.

## Contrato de reutilização

Foram inspecionados `tools/Invoke-SadPhaseViiiC2kAnnualEvolutionPilot.ps1` e `tools/Invoke-SadPhaseViiiC2GuidedUiPilot.ps1`. Os dois fixam branch/hash da fonte histórica; não é correto executá-los para este novo gate trocando os insumos. `Invoke-SadViP1Readonly.ps1` usa inventário legado de 21 QVDs e pode disparar COM com `-RunQlik`; também não deve ser reutilizado aqui.

O novo arquivo `tools/Invoke-SadC2VisualTemporalPreflight01.ps1` **reusa a estratégia de hash e fail-closed**, não os executores históricos. Somente inventário: **não cria cópia QVW, não abre QlikView e não valida UI**. Requer PowerShell 5.1 nativo, Windows, clone limpo e branch versionada.

| Insumo experimental | SHA-256 documentado | Evidência |
| --- | --- | --- |
| `SAD_P11P12_VISUAL_POLISH_COPY.qvw` | `B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C` | [PR #177](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/177), [closeout P1.1/P1.2](sad-p11-p12-physical-closeout-2026-10-29.md): 4 KPIs e 36 meses |
| `SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw` | `9896D55ED7F98CFA480A0626484A04C3A937E2F64EBF238011D3CDEF4E1E21FA` | [C2-K](phase-8-c2k-guided-annual-evolution-pilot-2026-10-22.md): seleção anual/evolução, sem gráfico validado |

**Fato verificado no GitHub:** fontes descritas separadamente, com hashes diferentes. **Hipótese pendente:** existir uma QVW com seleção guiada *e* objetos P1.1/P1.2. Hash idêntico ao histórico não comprova essa compatibilidade; abrir o QlikView requer etapa distinta.

**Protegidos:** 10 QVDs em EXTRACAO/QVD, 12 em TRANSFORMACAO/QVD e os QVWs canônicos EXTRACAO/EXT.qvw, TRANSFORMACAO/TRANSF.qvw, PAINEL/PAINEL.qvw. SHA/length antes e depois do preflight, com veredito restrito.

## Entradas e execução futura pelo operador Windows

- `-Root`: diretório absoluto do clone canônico na branch versionada.
- `-P11P12Qvw`: **caminho real**, sem suposição, da cópia final P1.1/P1.2.
- `-C2kQvw`: **caminho real** da cópia C2-K.
- `-QlikExe`: caminho de `Qv.exe`, cuja ProductVersion deve começar por 12.
- `-EvidenceRoot`: pasta externa ao Git, existente antes da execução; **nenhuma origem** dentro dela.

Para localizar P1.1/P1.2, procurar o nome `SAD_P11P12_VISUAL_POLISH_COPY.qvw` dentro das pastas de runtime do operador. O PR #177 documentou o caminho de evidências `Documents\SAD_P11P12_VISUAL_POLISH_EVIDENCIAS`, **não** o caminho definitivo de origem. Não converter evidência em origem por presunção.

O C2-K registrou o caminho histórico sob:
`Documents\SAD_C2K_ANNUAL_RUNTIME\SAD_VIII_C2K_ANNUAL_47f2ae84abd747cb963f1cb8baad41a4\SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw`.
Sua existência **hoje** não foi verificada. Se ausente, `BLOCKED_SOURCE_MISSING`, sem reconstrução silenciosa.

Antes de executar, conferir HEAD da branch remota e status limpo, confirmar assinatura SHA do script versionado, fechar QlikView e fazer o parser do PowerShell 5.1:

~~~powershell
# Na raiz do clone, branch test/sad-c2-visual-temporal-preflight-20261029
git status --porcelain --untracked-files=all
git rev-parse HEAD

$root = (Get-Location).Path
$p11 = 'INSERIR_CAMINHO_ABSOLUTO_REAL_P11_P12_QVW'
$c2k = 'INSERIR_CAMINHO_ABSOLUTO_REAL_C2K_QVW'
$qlik = 'INSERIR_CAMINHO_ABSOLUTO_REAL_Qv.exe'
$evidence = 'INSERIR_CAMINHO_ABSOLUTO_REAL_EVIDENCE_ROOT'

$runner = Join-Path $root 'tools\Invoke-SadC2VisualTemporalPreflight01.ps1'
$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner, [ref]$tokens, [ref]$errors)
if ($errors.Count -ne 0) { $errors | ForEach-Object { $_.ToString() }; throw 'BLOCKED_POWERSHELL_PARSER' }

powershell.exe -NoProfile -File $runner -Root $root -P11P12Qvw $p11 -C2kQvw $c2k -QlikExe $qlik -EvidenceRoot $evidence
~~~

Esses comandos são **instruções para execução nativa futura**, não resultados deste agente. A pasta de evidência precisa existir fora do Git antes da chamada. O script recusa checkout sujo, branch errada, fonte ausente, SHA divergente, Qv.exe não 12.x, QlikView aberto e inventário fora de 10+12+3.

## Aceite e STOP

- `PASS_IDENTITY_AND_HASH_INVENTORY_ONLY_NOT_UI`: dois hashes de origem iguais aos documentados, Qv.exe 12.x, 25 protegidos íntegros durante duas leituras, manifesto persistido. **Não** prova mesmo modelo nem gráfico.
- `BLOCKED`: arquivo/ambiente/checkout ausente, QlikView aberto, rótulo ou versão divergente.
- `HARD_STOP`: mudança SHA de fonte ou protegido.
- `INCONCLUSIVE`: saída incompleta ou teste GUI não realizado; jamais preencher com PASS histórico.
- **STOP:** uma única execução desse preflight no Windows e retorno de stdout + manifesto. Não abrir/modificar QVW nesta subetapa. Após inspecionar a compatibilidade em gate distinto, decidir se um único QVW suporta `EVOLUCAO/2019` com 12 competências da P1.2.

**Fronteiras inalteradas:** `C2_FULL=NO_GO_NOT_APPROVED`; `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Handoff de evidência:** [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196); anexar os valores de saída e caminhos (sem subir QVW/QVD/dados), classe final e eventual causa objetiva de bloqueio. Não repetir C2-J, C2-K, AE01, A0 R1, P1.1/P1.2 ou P2.3 R2.

## Closeout — execução Windows comprovada por anexos do operador (30/10/2026)

**Este adendo atualiza o estado inicial “não executado” acima, que permanece como histórico da preparação.** O responsável executou o runner versionado no PowerShell 5.1 e entregou três anexos para análise: transcrição PowerShell, `preflight_stdout.txt` e `preflight_manifest.json`. Os **arquivos de evidência** foram reconciliados quanto a HEAD, hashes e veredito; os binários locais originais **não** foram lidos independentemente pelo agente.

- Branch/HEAD executado: `test/sad-c2-visual-temporal-preflight-20261029@ea8c659a157fbf8548e024a933478d4a85dad537`; parser `PASS` reportado.
- Runner `SHA256=2D5141A790B7F14594548AEE0F31B36C549B29716CCCA9619DEFA15C877B8F81`; QlikView 12 `ProductVersion=12.0.20000.0` detectado, sem invocá-lo.
- P1.1/P1.2 QVW `B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C`; C2-K QVW `9896D55ED7F98CFA480A0626484A04C3A937E2F64EBF238011D3CDEF4E1E21FA`.
- Manifesto enumera **25 entradas** (10 QVD extração +12 QVD transformação + 3 QVWs canônicos) com hashes SHA-256; `PROTECTED_25_UNCHANGED_DURING_PREFLIGHT=True` reportado.
- `QLIK_COM_CALLS=0 RELOAD_CALLS=0 QVW_COPIES=0`; `COMBINED_QVW_COMPATIBILITY=NOT_TESTED`.
- **STOP atingido:** `SAD-C2-SOURCE-PREFLIGHT-01=PASS_IDENTITY_AND_HASH_INVENTORY_ONLY_NOT_UI` (prova restrita local, com auditoria dos três anexos). Sem nova execução deste subgate.

**Rastreabilidade:** [Issue #196 — closeout de evidência](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6512555071), [PR #197](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/197). **Aprovação de UI/seleção/produção não decorre deste PASS.** `C2_FULL=NO_GO_NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.
