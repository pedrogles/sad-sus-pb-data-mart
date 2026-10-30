# SAD C2 — inventário de compatibilidade visual em duas QVWs descartáveis

**Gate único:** `SAD-C2-VISUAL-COMPATIBILITY-01`, etapa delimitada da [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196).  
**Baseline:** `main@7827300c8772a1cdebef2238a7dd8064c13592d2`, com [PR #195](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/195) integrado.  
**Estado de entrada:** preflight anterior **PASS restrito e documentado** na Issue #196; `PR #197` ainda **Draft/sem merge**; seus scripts **não serão reexecutados**.  
**Estado desta etapa:** `SCRIPT_VERSIONED_CANDIDATE / WINDOWS_NOT_RUN / VISUAL_NOT_OBSERVED`.  
**Agente/modelo:** ChatGPT GPT-6 + conector GitHub apenas para preparação e inspeção estática; esforço efetivo indisponível. No Windows, executor primário Codex Local com acesso demonstrado, fallback pessoa operadora em PowerShell 5.1/QlikView 12; somente com permissão de trabalhar nas cópias temporárias.

## 1. Por que este gate é distinto

As evidências entregues no preflight anterior conferem **dois QVWs distintos**:
- `SAD_P11P12_VISUAL_POLISH_COPY.qvw`, SHA-256 `B3BEDCD6F07D11456383F4C6996992804BFFDDCCA52E7B80C50344AB9FE9454C`, previamente demonstrou 4 KPIs P1.1 e série de **36 competências** P1.2 em prova restrita.
- `SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw`, SHA-256 `9896D55ED7F98CFA480A0626484A04C3A937E2F64EBF238011D3CDEF4E1E21FA`, previamente demonstrou **navegação anual/evolução** por variável/campo real em piloto limitado, **não** série de 12 pontos.

O `preflight_manifest.json` fornecido pelo operador identificou QlikView `12.0.20000.0` e integridade reportada de **10+12 QVDs e 3 QVWs**. Essa evidência não responde se o mesmo QVW já contém **ambos** os componentes. A próxima prova necessária é apenas **inventário de presença e compatibilidade de objetos**, *não* repetir os pilotos, recalcular números ou tentar executar o modo `EVOLUCAO/2019`.

**Objetivo:** uma inspeção visual de presença de **objetos existentes**, em cópias de cada QVW. Ao final, concluir `CANDIDATE_SINGLE_QVW_IDENTIFIED`, `NO_SINGLE_QVW_FOUND` ou `INCONCLUSIVE`, sempre com revisão humana de capturas; nenhum desses estados equivale a homologação temporal.

## 2. Contrato do runner protegido

**Script versionado:** [`tools/Invoke-SadC2VisualCompatibilityCopy01.ps1`](../../tools/Invoke-SadC2VisualCompatibilityCopy01.ps1). Reusa a estratégia `-Prepare/-Verify` do runner C2-K, com **fontes/pins atualizados apenas neste novo runner**, sem alterar C2-K e sem repetir seus testes. O runner NÃO chama COM, não abre GUI, não carrega QVD, não recarrega documento, não modifica QVS e não salva QVW.

- **Entrada:** `-Root`, `-P11P12Qvw`, `-C2kQvw`, `-RuntimeRoot` e `-EvidenceRoot` (todos caminhos absolutos). Ambos os últimos diretórios devem existir, separados e fora do repo/Git; as fontes também fora de ambos.
- **Guardas:** branch versionada correta, checkout limpo, ancestralidade do baseline, hash fixo das duas origens, QlikView **fechado** nos modos Prepare/Verify, contagem exata **10 QVDs de extração + 12 de transformação + 3 QVWs canônicos**.
- **`-Prepare`:** uma única chamada para criar **duas cópias em nova pasta** e manifesto de hash `compat_manifest.json` em evidência externa. **Não abrir** as origens: só abrir os caminhos `RUNTIME_P11_COPY`/`RUNTIME_C2K_COPY` reportados.
- **`-Verify -RunDir`:** somente após fechar ambos os documentos sem salvar, compara inventário protegido pré/pós, hashes das origens e confirma que **ambas as cópias continuam byte a byte idênticas** às origens. Gera `compat_verify.json`. Veredito máximo automatizado `PASS_COPY_INTEGRITY_ONLY_NOT_UI`.

**Proteções:** nunca copiar para dentro do repositório, nunca aplicar Save/Reload no QlikView, nunca editar objetos, expressões, variáveis, botões, bookmarks, listas, propriedades nem escolher filtros. Abrir/inspecionar e **fechar sem salvar**. Caso a Personal Edition peça restauração/licença, mude seleção automaticamente, ou a aplicação tente modificar origens, **STOP**, preservar evidência e não avançar. O script não pode atestar a qualidade da inspeção visual.

## 3. Inspeção GUI — uma passagem em cada cópia

**PASS mínimo de inventário:** screenshot(s) inequívocas + notas de observação, sem clicar em ações de seleção. Operador examina somente **objetos existentes**, sem criar outros:

| Cópia | O que localizar e registrar | O que NÃO inferir |
| --- | --- | --- |
| `RUNTIME_P11_COPY` | Folhas; IDs/títulos de **quatro cartões P1.1** e gráfico P1.2; se há botões `MENSAL`, `ANUAL`, `EVOLUCAO` já presentes; se existem referências visíveis a `PERIODO_ANO`/`PERIODO_COMPETENCIA` ou diagnósticos de campo real | Quatro cartões e linha 36 meses **não** demonstram controles guiados integrados; não repetir valores 4/4 nem export 36/36 |
| `RUNTIME_C2K_COPY` | Folhas; controles guiados existentes, diagnóstico do **ano/competência reais**, qualquer gráfico de linha P1.2 existente **com dimensão `PERIODO_COMPETENCIA` e medida `QTD_INTERNACAO`**, e cartões P1.1 se presentes | Controles de navegação não demonstram série de 12 meses, nem diagnóstico textual P5 autoriza KPI |

Se propriedades de objeto forem abertas **somente para leitura**, registrar o ID e expressão visível e **cancelar**, não confirmar qualquer alteração. Se os objetos não estiverem visíveis em uma folha, inspecionar as folhas já existentes e, se necessário, listas de objetos disponíveis, sem editar. **Não declarar ausência definitiva** só porque não apareceu na primeira folha; usar `INCONCLUSIVE` se não for possível inspecionar todas as folhas/objetos com segurança.

**Evidências persistentes, fora do Git:** `p11p12_objects.png`, `c2k_objects.png`, imagens adicionais de propriedades quando necessário, e `compatibility_notes.txt` com campos: `COPY`, `OBJECT_IDS`, `GUI_MODES_PRESENT`, `REAL_TIME_FIELDS_PRESENT`, `P11_CARDS_PRESENT`, `P12_CHART_PRESENT`, `P12_DIMENSION`, `P12_MEASURE`, `SINGLE_QVW_CANDIDATE` e `UNCERTAINTY`. Use `UNKNOWN` quando não inspecionado, nunca inferir por nomes do arquivo.

**Sem testes de seleção, 12 meses, oráculo ou comportamento D2/P5 nesta etapa.** Não repetir C2-J/K, 36/36 de P1.2, 25/25 do preflight antigo nem AE01/A0 R1.

## 4. Roteiro PowerShell 5.1 nativo (a executar só no Windows)

Na raiz do clone, primeiro confirmar worktree limpa e HEAD da branch versionada **exato do PR vigente**. Não aplicar `reset`/`clean`/`stash` se houver arquivos não rastreados. As duas origens já foram **localizadas pelo operador** no preflight anterior; utilizar caminhos existentes, não procurar outras cópias.

~~~powershell
# Com a branch de compatibilidade selecionada e HEAD remoto conferido
$repo = (Get-Location).Path
$p11 = Join-Path $env:USERPROFILE 'Documents\SAD_P11P12_VISUAL_POLISH_RUNTIME\SAD_P11P12_VISUAL_f673cac03dea40f292fb202ff903521a\SAD_P11P12_VISUAL_POLISH_COPY.qvw'
$c2k = Join-Path $env:USERPROFILE 'Documents\SAD_C2K_ANNUAL_RUNTIME\SAD_VIII_C2K_ANNUAL_47f2ae84abd747cb963f1cb8baad41a4\SAD_C2K_ANNUAL_EVOLUTION_COPY.qvw'
$runtime = Join-Path $env:USERPROFILE 'Documents\SAD_C2_COMPAT_RUNTIME'
$evidence = Join-Path $env:USERPROFILE 'Documents\SAD_C2_COMPAT_EVIDENCIAS'
New-Item -ItemType Directory -Path $runtime,$evidence -Force | Out-Null

$runner = Join-Path $repo 'tools\Invoke-SadC2VisualCompatibilityCopy01.ps1'
$tokens = $null; $errors = $null
[void][Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
if ($errors.Count -gt 0) { $errors | ForEach-Object {$_.ToString()}; throw 'BLOCKED_PARSER' }

powershell.exe -NoProfile -File $runner -Root $repo -P11P12Qvw $p11 -C2kQvw $c2k -RuntimeRoot $runtime -EvidenceRoot $evidence -Prepare
~~~

Após `-Prepare` bem-sucedido, abrir **apenas os dois caminhos RUNTIME** indicados, um de cada vez, inspecionar sem editar e **fechar sem salvar**. Depois, executar **uma vez** o `-Verify` no **mesmo checkout**, substituindo somente o valor de `-RunDir` pelo `EVIDENCE_DIR` realmente emitido:

~~~powershell
powershell.exe -NoProfile -File $runner -Root $repo -P11P12Qvw $p11 -C2kQvw $c2k -RuntimeRoot $runtime -EvidenceRoot $evidence -Verify -RunDir 'COLE_O_EVIDENCE_DIR_REPORTADO_NO_PREPARE'
~~~

**Comandos acima não foram executados nesta sessão.** Não prosseguir se `-Prepare` não emitir `PASS_COPIES_PREPARED_ONLY_GUI_NOT_TESTED` ou se alguma fonte/protegido divergir.

## 5. Critérios de encerramento e decisão posterior

| Veredito | Quando pode ser atribuído |
| --- | --- |
| `PASS_COPIES_PREPARED_ONLY_GUI_NOT_TESTED` | Runner criou duas cópias idênticas com manifesto e preservou 25 protegidos durante Prepare |
| `PASS_COPY_INTEGRITY_ONLY_NOT_UI` | Verify registrou 25 protegidos, duas origens e duas cópias sem alterações |
| `CANDIDATE_SINGLE_QVW_IDENTIFIED` | Evidência visual revisada confirma **no mesmo QVW** controles temporais reais + gráfico P1.2; valores/seleções ainda não testados |
| `NO_SINGLE_QVW_FOUND` | Inspeção abrangente e documentada de ambas as QVWs não encontrou a superfície conjunta; somente proposta de **outro gate** para integração em nova cópia |
| `INCONCLUSIVE` | Folhas/objetos impossíveis de inspecionar, capturas ou notes insuficientes |
| `BLOCKED` / `HARD_STOP` | SHA divergente, QlikView fechado incorretamente, worktree alterada, parser falhou ou cópia modificada indevidamente |

**STOP:** uma preparação, uma inspeção read-only de cada cópia e uma verificação. Mesmo em `CANDIDATE_SINGLE_QVW_IDENTIFIED`, não iniciar teste `EVOLUCAO/2019` de 12 competências automaticamente; requer protocolo físico distinto usando o oráculo já arquivado, sem repetição de C2-J/K.

**Fronteiras:** `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED` e `PRODUCTION_APPROVED=False`.
