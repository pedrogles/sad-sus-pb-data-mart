# Automação de validação QlikView 12 com PowerShell — inventário e contrato operacional candidato

**Situação em 15/10/2026:** documentação de Discovery, **sem novo executor** e **sem novos testes**. Escopo: automação de testes e obtenção de evidências; não altera o fluxo acadêmico QlikView `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`. Preservar a ordem de implementação do [Boundary 7](../discovery/boundary-7-implementation-plan.md).

**Origem:** código `main`, [PR #83 encerrado sem merge](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/83) e [HEAD histórico congelado](https://github.com/pedrogles/sad-sus-pb-data-mart/commit/26369052bd3f96de5f3eccf873c390053c20b561). Os executores que permanecem nessa branch **não são ferramentas adotadas em produção**. A aprovação semântica V2 está em [documento integrado](../discovery/phase-6-semantic-v2-approved-2026-10-14.md) e **não** libera indicadores ou filtros físicos.

## 1. Resultado do inventário — o que existe

O diff original do PR #83 contém **25 PowerShell (`.ps1`), 10 QVS (`.qvs`), 6 Python (`.py`), 3 Markdown e 1 arquivo de dependências**. A integração seletiva do [PR #84](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/84) trouxe **2 PowerShell, 2 QVS e 1 Python**, preservando evidências da Fase V; o sexto arquivo é documento de Discovery. **23 PowerShell e 8 QVS daquele diff permanecem apenas no commit histórico**, salvo eventual integração futura específica.

| Frente / executor | Local de consulta | Operação realmente implementada | Evidência e limite |
| --- | --- | --- | --- |
| `tools/validar_fato_internacao_medidas_qlik.ps1` | **main**, PR #84 | QVW isolado R3, `Reload()`, log, SHA do staging, cinco medidas | PASS local de medidas, sem QVD factual |
| `tools/validar_fato_internacao_dim_roles_r3_qlik.ps1` | **main**, PR #84 | QVW isolado R3, 11 papéis/SKs, oito QVDs com SHA antes/depois | Duas recargas R3 PASS locais, sem modelo associativo final |
| `tools/validar_estabilidade_sk_fato_internacao.ps1` | **main**, PR #82 | Duas recargas e comparação exata do conjunto de SK da fonte congelada | PASS local histórico; não testa identidade após correções |
| `tools/criar_v5_rd_sk_preflight.ps1` | **main**, PR #82 | Criação de QVW a partir de QVS; `-Reload` opcional | **Versão refatorada ainda não reexecutada no Windows** |
| `tools/validar_link_key_cross_fact_qlik.ps1` e `validar_link_associativo_qlik.ps1` | **Somente HEAD #83** | QVW descartável, key serializada e projeção associativa em memória | PASS experimental restrito; `LINK_KEY_CONTRACT=NOT_APPROVED` |
| `tools/validar_qlik_com_e13_smoke.ps1` | **Somente HEAD #83** | Cópia descartável, seleções COM, `Evaluate()`, denominador por ano/papel | E13–E21 restritos; não aprova Set Analysis final |
| `tools/validar_f4_p5_catalogo_com.ps1` | **Somente HEAD #83** | Testes de 48 seleções simples e 8 pares contra política C/R/I/B em wrapper | PASS local restrito; **não testa KPI ou aplicação nos objetos** |
| `tools/validar_f4_p5_associacoes_com.ps1` / `validar_f4_p5_recuperacao_componentes_com.ps1` | **Somente HEAD #83** | Seleções COM e observação de componentes sob filtros | PASS observacional/wrapper; não aplica política final de filtros |
| `tools/preparar_f4_p5_ui_guardas_qlik.ps1` | **Somente HEAD #83** | Guarda de origem TEMP, cópia descartável e verificação de hashes/artefatos | Prepara/verifica; **não faz avaliação visual** |
| `tools/validar_f4_p5_ui_visual_com.ps1` | **Somente HEAD #83** | Cria listas/textos/condições em cópia QVW, compara propriedades e captura PNG | PASS COM/visual restrito reportado; ainda não é aprovação de indicador |
| `tools/validar_f4_p5_chart_calc_condition_visual_com.ps1` | **Somente HEAD #83** | Cria objeto de gráfico neutro, testa condição de cálculo, captura PNG | PASS experimental restrito; revisão visual e KPI físico separados |
| `tools/inspecionar_cnes_st_lt_tp_pareado_qlik.ps1` | **Somente HEAD #83** | Perfil ST/LT/TP_UNID em QVW temporário, log nativo, hashes | R3 PASS local reportado, logs/stdout ainda sem auditoria independente |

**Outros auxiliares históricos** (sem adoção automática): `validar_f4_p5_projecao_qlik.ps1`, `validar_f4_preselecao_d2_qlik.ps1`, `validar_denominador_populacional_e5_qlik.ps1`, `validar_estabilidade_link_key_cross_fact.ps1`, `validar_estabilidade_link_key_pares_r2.ps1`, `diagnosticar_link_key_txt_export_qlik.ps1`, `inspecionar_qlik_com_e12_readonly.ps1`, `inspecionar_f4_p5_calc_condition_com.ps1`, `inventariar_cnes_st_lt_qvd_headers.ps1`, `inspecionar_cnes_st_lt_corpo_qlik.ps1` e `reconciliar_cnes_st_lt_r2_logs.ps1`. Há ainda diagnósticos R1/R2 da Fase V, superados por gates R3, que devem permanecer **como histórico**, não como execução padrão.

**Arquitetura física:** `EXTRACAO/ext_main.qvs` é o script de staging; `TRANSFORMACAO/transf_main.qvs` ainda é parcial/dimensional; `PAINEL/painel_main.qvs` permanece inicial. Não tratar a automação de QVWs temporários como existência de fatos, Link Table ou PAINEL finais.

## 2. Fluxo efetivamente observado e modelo de automação

Os scripts existentes usam, conforme o caso:

1. **Preflight de execução:** resolver caminhos, exigir arquivos/QVDs esperados, comparar integridade/hash, conferir presença de `AGENTS.md`, estado do projeto e parâmetros, validar que a fonte é QVW descartável.
2. **Preparação do ensaio:** ler o `.qvs` versionado, ou copiar um QVW experimental para novo subdiretório de `%TEMP%`; nunca editar QVW de origem/produção para testes F4/P5.
3. **QlikView Desktop 12 via COM:** `New-Object -ComObject 'QlikTech.QlikView'`, `CreateDoc()` ou `OpenDoc()`, `SaveAs()` **apenas do QVW de teste** quando necessário; `Reload()` quando o gate inclui recarga.
4. **Asserções reproduzíveis:** log de carga fresco, marcadores de resultado e totais, `GetProperties()`/objetos, seleção de campos, `Evaluate()` e verificação de estados esperados. Inspecionar conflitos ano/competência antes de generalizar.
5. **Evidências:** saída de console, logs nativos Qlik, vereditos, hashes SHA-256 e, quando aplicável, captura PNG de janela real do QlikView com manifesto. Preservar artefatos no caminho local correto; QVD/QVW binário e capturas não são versionados automaticamente.
6. **Encerramento:** `PASS` apenas do teste que efetivamente rodou; `BLOCKED` em divergência; `INCONCLUSIVE` se não houver log contemporâneo, ambiente adequado ou prova suficiente. Não avançar automaticamente para outro gate.

**Observação crítica:** o pipeline acima é uma *composição recomendada dos executores existentes*, **não existe neste momento um único runner principal end-to-end aprovado**. A eliminação de etapas manuais depende de uma Discovery/implementação delimitada de orquestração, sem duplicar todos os scripts do #83.

## 3. Uso reprodutível dos dois executores Fase V disponíveis na main

Pré-requisitos concretos: Windows com QlikView Desktop 12 e COM `QlikTech.QlikView` disponível, repositório e QVDs locais necessários, PowerShell, QVS versionado e permissão de criar **QVW de teste**. Os scripts verificam presença das entradas e hashes QVD; um QVW de teste preexistente deve corresponder ao QVS, sob pena de bloqueio.

Exemplos de invocação **somente quando o gate de teste for solicitado** (em um PowerShell iniciado na raiz do repositório):

```powershell
powershell.exe -NoProfile -File tools\validar_fato_internacao_medidas_qlik.ps1 -Root (Get-Location).Path
powershell.exe -NoProfile -File tools\validar_fato_internacao_dim_roles_r3_qlik.ps1 -Root (Get-Location).Path
```

**Efeitos previstos:** criam/salvam `TRANSFORMACAO/V5_RD_MEASURE_PREFLIGHT_R3.qvw` ou `TRANSFORMACAO/V5_RD_DIM_ROLES_PREFLIGHT_R3.qvw` **se inexistentes**, ou reabrem o QVW de teste compatível; executam `Reload()`, geram/consultam log e verificam SHA-256 das fontes. Esses comandos **não são modo sem escrita em disco**; não executá-los sobre dados/QVW cuja preservação não foi confirmada. Não geram QVD factual.

A validação local original de medidas e 11 papéis foi documentada nos PRs #83/#84; **nenhum comando acima foi executado nesta Discovery**.

## 4. Validação de dashboards e gráficos: níveis de garantia

| Nível de teste | O que pode ser automatizado | O que NÃO fica demonstrado |
| --- | --- | --- |
| **A. Estrutura/associação** | Número e campos de tabelas, integridade de chaves, ausência de `$Syn` esperados, QVD SHA, seleção/estado COM | Correção semântica de toda associação e resultado final |
| **B. Medidas/expressões** | Resultado de expressões numéricas para filtros e anos predeterminados, comparação com oráculo Python, `Evaluate()` | Generalização a todos os filtros, dados ou universos não testados |
| **C. Objetos** | Criação de gráficos/textos/listas em **cópia** QVW; leitura de propriedades; `Calculation Condition`, `Show Conditional`; cenários de filtro | Que todos os objetos de um painel real estão corretos |
| **D. Captura visual** | Janela em foreground, cinco PNGs/cenários e hashes/manifesto, se ambiente estável | Legibilidade, truncamento, cores, escala, alinhamento, mensagens ausentes; PNG sozinho não aprova UX |
| **E. Aprovação final** | Só após casos representativos + reconciliações T24–T26 + evidência visual auditada + escopo/tempo/território corretos | Não é alcançada pelos protótipos atuais do PR #83 |

**Limites físicos registrados:** a automação visual utiliza janela do QlikView Desktop e captura via API gráfica Windows. Portanto, **não é comprovadamente headless**: uma sessão Windows interativa, foco/visibilidade corretos, resolução, ausência de pop-ups e condições de renderização afetam o teste. Falhar fechado se não houver janela correta, captura válida, arquivo fonte inalterado ou comparação de resultados. Não assumir que CI genérico ou execução em segundo plano têm acesso a desktop interativo.

O comportamento `Show Conditional` e `Calculation Condition` foi testado **restritamente em QVW descartável com expressão neutra**, não em KPI real. A política C/R/I/B da V2 é semântica, não uma proteção automática contra seleção de filtros pelo usuário final. Revisão de PNG automatizada e aprovação visual integral **ainda não foram implementadas/validadas**.

## 5. Segurança operacional e critérios de parada

- **Nunca** substituir QVDs, QVWs originais ou scripts de produção em um ensaio de Discovery. Preservar original, fazer cópia descartável e verificar hash antes/depois; gravar somente artefatos locais de teste. Guardar SHA de script e fontes para reproduzir.
- Nenhum script de UI pode considerar `COM_SELECT=PASS` autorização de indicador; nenhuma expressão neutra `=1` se torna KPI aprovado. Denominador de população deve respeitar município de residência/serviço, ano e semântica V2; não replicar POP anual em meses.
- Em ausência de evidência: `INCONCLUSIVE` ou `BLOCKED`, não `PASS`. `PASS_LOCAL`, `PASS_ARTIFACT_REVIEW`, `PASS_VISUAL_RESTRICTED` e `PRODUCTION_APPROVED` são estados distintos.
- Ao concluir a validação solicitada, **parar**; se detectar falha em outro domínio (CNES, interface, Link Table), registrar um único bloqueio com evidência e propor próximo escopo. Não gerar novos testes E22/R4/UI apenas por curiosidade.
- Não criar um novo mecanismo de governança, pasta ou orquestrador sem demonstrar necessidade. Reusar `tools/`, `TRANSFORMACAO/` e documentos canônicos.

## 6. Decisões pendentes e próxima implementação mínima proposta

**DECISÃO PENDENTE — automação ponta a ponta sem intervenções manuais:** verificar em Windows real a robustez de inicialização COM, `Reload()`, sincronização de logs, objetos e capturas em QVW de teste, e definir quando uma captura requer auditoria visual. Não afirmar que já existe operação 100% autônoma.

**HIPÓTESE OPERACIONAL — menor próximo passo:** escolher **um único gate aprovado da main**, por exemplo medidas Fase V, e padronizar a saída do executor como `VERDICT` + `SOURCE_SHA256_UNCHANGED` + `SCRIPT_SHA256` + localização de log + códigos de saída, **sem reescrever o executor ou a arquitetura de QlikView**. Somente se este padrão for insuficiente, propor orquestração simples PowerShell em PR separado com testes locais controlados.

**Gate futuro para objetos/gráficos:** após existir um PAINEL técnico e medidas autorizadas, testar **um objeto de cada vez** por três vias: propriedade COM, expressão reconciliada para seleção de referência, e screenshot/renderização auditada. A automação de captura ajuda a reduzir trabalho manual, mas não substitui aprovação visual até haver validador de imagem demonstrado.

**Fronteiras ainda fechadas:** `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, fatos/Link Table/PAINEL finais **NOT_STARTED**. Nenhum teste novo de QlikView/PowerShell foi executado para redigir este documento.
