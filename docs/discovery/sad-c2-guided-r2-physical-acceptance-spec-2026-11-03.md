# SAD — C2 guiado R2 | Especificação mínima de aceite físico (SEM EXECUÇÃO)

**Gate de design:** `SAD-C2-GUIDED-R2-PHYSICAL-ACCEPTANCE-SPEC-01`  
**Gate físico futuro, ainda não autorizado:** `SAD-C2-GUIDED-R2-PHYSICAL-ACCEPTANCE-01`  
**Data:** 03/11/2026  
**Fonte de verdade inspecionada:** `main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83`, após PR #214.  
**Estado:** `SPEC_REVIEW=DOCUMENTAL_ONLY`; `PHYSICAL_EXECUTION=NOT_AUTHORIZED`; `C2_GUIDED_R2=NOT_TESTED`; `PHASE_IX=NOT_AUTHORIZED`.

## 1. Objetivo único, evidências e permissões

Projetar **um ensaio físico mínimo e protegido** de dois aspectos do [D2-R2 V3 semanticamente vigente](phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md): **(a)** bloquear proposta temporal incompatível **antes** de despachar por controle guiado e comunicar causa; **(b)** depois de **uma** operação de seleção nativa, um **KPI anual específico** deve ler o contexto **real**, não publicar número obsoleto/semanticamente inválido e exibir motivo de indisponibilidade. Isto não substitui a validação de todos os indicadores/rotas.

**Não executar nesta PR:** nenhum PowerShell, COM, QlikView, ação de menu, seleção, alteração de QVW/QVD/QVS ou criação de dados. O objetivo atual é apenas fixar **contrato, fonte candidata, critérios falsificáveis, evidências e STOP**. A autorização recente do responsável foi “prossiga” após recomendação de **especificar** o gate; **não** confundi-la com autorização para mutar o QVW experimental.

**Hierarquia inspecionada:** `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → [V3 D2-R2](phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md) → [V2 §62.3/62.6](phase-6-semantic-v2-approved-2026-10-14.md) → [Boundary 7](boundary-7-implementation-plan.md) → [automação QlikView](../project/qlikview-powershell-automation.md) → [desenho de interface temporal](sad-c2-guided-dynamic-control-design-2026-10-30.md) → [#208/negative TEMP](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/208) → [#210/inventário](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/210) → [#205/oráculo 2019](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205) → [blueprint #209](../project/three-panels-blueprint-approved-2026-11-03.md) → [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196).

**Invariantes:** 3 fatos, 8 dimensões, grãos, Link Table/roles, D1 e D3–D8, P1–P5, não aditividade de POP/LEI, 14 visuais aprovados somente em layout; QlikView Desktop 12. Nenhuma mudança acadêmica ou global de associação. A transcrição da V2 não será reescrita; V3 muda somente a garantia de D2.

## 2. Fontes físicas C2 e limites da prova reutilizável

| Fonte | Evidência já existente, NÃO repetir | Limite exato |
|---|---|---|
| [PR #201](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/201) | `BU15` aplicou `PERIODO_ANO=2019`, `PERIODO_COMPETENCIA` sem seleção explícita em um cenário | Um despacho positivo; não prova bloqueio de conflito em rotas nativas |
| [PR #205](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/205) | Gráfico P1.2 guiado 2019 de `201901..201912` com 12/12 linhas = oráculo; total FI `188246`; controle `201905=17292` | Restringe-se a gráfico 2019, não KPI D2 pós-seleção; QVW TEMP não é painel final |
| [PR #208](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/208) | `BU16` com ação `Select in Field(PERIODO_COMPETENCIA)` **configurada, nunca acionada segundo operador**; guarda 1→0 observada; 0→1→0 estrito inconclusivo; motivo UX não comprovado | Sem prova de clique conflituoso inerte nem mensagem de bloqueio. Evidência local/hash restringem-se àquela TEMP |
| [PR #210](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/210) | QVW de #208 inspecionada: 3 folhas (13/15/7 objetos); `LB01/LB04` Read Only, botões `BU15/BU16`; menu nativo Seleções disponível, bookmarks usuário/documento vazios com opção Importar; Verify local reportado fonte/cópia+25 protegidos íntegros | Não houve ações nativas executadas; nenhuma mitigação global comprovada; `PASS_HASH_INTEGRITY_ONLY_NOT_UI_ROUTES` não é PASS de interface |

### Fonte QVW candidata, ainda sujeita a preflight local

- **Origem experimental** (não QVW canônico): `C:\Users\pedro\Documents\SAD_C2_PREDISPATCH_RUNTIME\SAD_C2_PREDISPATCH_d6f8664aac094bbe9e13a85ca79367c4\SAD_C2_PREDISPATCH_NEGATIVE_TEMP.qvw`.
- **SHA-256 esperado**, observado no Verify de #208/#210: `A11D6F44175847A305DE74C2A12FEECF7412B1D45A699BBAE396FCE71BDFE517`. **Arquivo não está no GitHub**; preflight no Windows deve conferir bytes novamente. Não presumir disponibilidade do caminho nem restaurar arquivo silenciosamente.
- **Programa observado:** QlikView Desktop `12.0.20000.0`; recursos exibidos em documentação de versões mais novas não comprovam compatibilidade específica desta build.
- **Estado-base que a GUI deverá verificar antes do teste:** `GetSelectedCount(PERIODO_ANO)=1`, `Only(PERIODO_ANO)=2019`, `GetSelectedCount(PERIODO_COMPETENCIA)=0` e ausência de filtros adicionais que modifiquem o indicador FI. **Se não for exatamente esse estado, STOP `INCONCLUSIVE_BASE_STATE`**; não limpar/aplicar seleções silenciosamente para construir o estado desejado.
- Manter fonte `#208`, cópia de inventário `#210`, 22 QVDs (10 extração + 12 transformação) e 3 QVWs canônicos **intocados**. A execução futura deve criar **uma nova cópia TEMP com novo RunId**, sem sobrescrever QVW ou evidências anteriores.

**Nota de proveniência:** QVW/hash/estados são resultados reportados pelo operador e capturas já revisadas, não leitura binária independente deste agente. Identidade da nova execução exigirá `GIT_HEAD`, hash de runner, hash fonte, novo caminho real de TEMP e manifesto com os 25 hashes de proteção.

## 3. Design físico candidato mínimo — 1 QVW TEMP, 2 objetos auxiliares

**FATOS de configuração:** a QVW anterior já contém `BU15/BU16`, `LB01/LB04`, `vSAD_POC_Mode`, `vSAD_POC_Year`, `vSAD_POC_Month`, `PERIODO_ANO`, `PERIODO_COMPETENCIA`, `QTD_INTERNACAO`, três folhas e gráficos P1.1/P1.2 segundo provas visuais. **Nenhuma propriedade funcional adicional foi confirmada.**

**Hipótese para futura implementação sob autorização específica:** acrescentar na **nova TEMP** até **dois Text Objects diagnósticos** na folha de POC, sem editar `BU15/BU16`, `CH02/CH03`, listas, QVS, fatos ou outros objetos:

1. **`R2_STATUS_GUIDED` (ID a atribuir/inspecionar no Windows, NÃO ID existente afirmado):** motivo legível de incompatibilidade entre `MENSAL/2018/01` proposto e `PERIODO_ANO=2019` aplicado, enquanto o botão guiado de competência permanece bloqueado. A lógica deve ler *proposta* e *estado real*, não presumir que `Only(PERIODO_ANO)` prova seleção explícita (usar contagem). Exemplo conceitual: `mode=MENSAL && realAnoSelecionadoUnico=2019 && proposedAno=2018 => "Não aplicado: proposta conflita com ano 2019 selecionado"`. Mensagem **não** substitui guarda de botão nem é sinal de dispatch.
2. **`R2_KPI_ANUAL_CANARY` (ID futuro):** KPI **diagnóstico de internações FI** com referência **anual pontual**. Mostrar `Sum(QTD_INTERNACAO)` **somente** quando houver referência anual explícita única, nenhuma competência explicitamente selecionada e o contexto for compatível com o escopo FI deste ensaio; caso contrário, renderizar **“Indisponível: ano analítico ausente ou ambíguo”** ou motivo aplicável, **sem continuar mostrando o número anterior**. Com ano aplicado 2019, sem outros filtros, o oráculo numérico candidato é `188246` (#205). Esta condição simplificada é deliberadamente válida **somente para o KPI anual FI canário**, não uma regra universal de bloqueio de períodos parciais, múltiplos anos em séries ou indicadores com P5.
   
**Pseudológica, NÃO expressão QlikView validada:**

```text
state = { realSelectedYearCount, realYearValue, realSelectedCompetenceCount, realFieldFilters }
proposal = { mode, proposedYear, proposedMonth }
guidedReason = (proposal.mode == MENSAL && state.realSelectedYearCount == 1
                && state.realYearValue != proposal.proposedYear)
               ? "Não aplicado: ano proposto diverge do ano real"
               : "Sem conflito desta classe"
annualCanary = (state.realSelectedYearCount == 1
                && state.realSelectedCompetenceCount == 0
                && independentSourceAndFilterChecksPass)
               ? FI_sum_for_applied_annual_context
               : "Indisponível: período anual pontual inválido"
```

**Não** transformar `GetSelectedCount`, `Only` e `Sum` em uma expressão oficial sem testar editor, modo texto/número, comportamento ao limpar e dependência de estado/seleção. Se os dois objetos não conseguirem representar essas regras na versão instalada, **STOP / `BLOCKED_EXPRESSION_OR_UI`**; não adicionar terceiros, set analysis que ignore seleção nem event triggers para remediar no mesmo gate. Não tocar o `CH02` histórico de 36 meses. O canário não homologa P1.1 real, P5, medidas cross-fact ou todos os visuais do blueprint.

## 4. Protocolo físico futuro — máximo duas transições novas, uma rodada

A implementação abaixo é **um plano condicionado à autorização física própria**, **não um comando para executar agora**.

| Ordem | Estado/ação única pretendida | Aceite visível exigido | Regra STOP |
|---|---|---|---|
| **T0 — Baseline** | Na nova TEMP, verificar `PERIODO_ANO=2019` único, `PERIODO_COMPETENCIA` sem seleção explícita, demais filtros neutros; registrar `BU16` e objetos existentes | Captura com ano real, competência real, modo/proposta e ID dos objetos. Fonte/hash coincidem. | Divergência → `INCONCLUSIVE_BASE_STATE`; não forçar seleção |
| **T1 — Guided negative** | Só nas variáveis de proposta: `MENSAL/2018/01`, mantendo ano real 2019; tentar acionar **uma vez** o `BU16` **somente se estiver visivelmente desabilitado**, sem comandos nativos | Antes: condição `0`, motivo de bloqueio em `R2_STATUS_GUIDED`, ano real 2019 e competência sem seleção. Depois: **mesmo estado real**, sem descarte da intenção; screenshots pré/pós e relato do operador. | Se botão habilitar, selecionar competência, perder estado real, não mostrar motivo ou resultar em ação inesperada: `BLOCKED_GUIDED_PRE_DISPATCH` e **não executar T2** |
| **T2 — Native negative** | Na mesma TEMP, alterar somente a **proposta por variável** para `ANUAL/2019`, sem acionar botões; registrar canário anual 2019 e valor candidato `188246`. Executar **uma vez** o comando nativo **Seleções → Limpar** no QlikView Desktop. | Capturas de (a) KPI canário válido e seleção real anual 2019 e (b) seleção real **após** o menu. **Somente se** `GetSelectedCount(PERIODO_ANO)=0` e competência sem seleção, o canário deve passar a **“Indisponível”**, com motivo, **sem número antigo como válido**. | Comando não altera ano → `INCONCLUSIVE_NATIVE_ACTION_NOT_APPLIED`; estado ficou diferente do previsto → `INCONCLUSIVE_NATIVE_STATE`; KPI continua exibindo 188246 como anual válido, valor obsoleto, ou ignora filtro → `BLOCKED_POST_NATIVE_PRESENTATION` |

**Limite temporal:** não há requisito de milissegundos inventado; a atualização deve ser observável após conclusão da operação e estabilização da UI, **sem exibir estado obsoleto como válido na captura de aceite**. Captura não prova ausência de toda transição visual intermediária. Não alegar garantia de atualização instantânea ou ausência de corrida sem instrumentação específica.

**Importante sobre resultados antigos:** a QVW TEMP pode conter **outros KPIs e gráficos não protegidos**. Registrar qualquer apresentação contraditória que estiver visível; não ignorá-la. Mesmo que o canário passe, se os demais visuais de mesma semântica continuarem mostrando número obsoleto como anual, `C2_GUIDED_R2` global **permanece sem aceite** e a lacuna desses visuais deve ser explicitada. Não usar um objeto novo para mascarar dívida existente.

**Sem ampliar:** nenhuma importação de bookmark, segundo menu, busca global, multisseleção de anos, troca de modo com seleção real, teste do gráfico histórico, tela P2/P3, P5 ou C3/C4. A matriz V3 de outras rotas permanece para **gates específicos posteriores** se os testes realmente forem necessários; **um menu não representa todos os menus**.

## 5. Proteção, versionamento e evidências — contrato de um runner futuro

**Agente de especificação:** ChatGPT GPT-6 + conector GitHub, ambiente remoto, somente texto/documento; esforço configurado não verificado. **Executor físico futuro:** Codex Local Windows se disponível e autorizado, senão operador humano com PowerShell 5.1 + QlikView Desktop 12. Não alegar acesso deste agente à pasta `C:\Users\pedro`.

**Antes de executar T0/T1/T2** (somente depois da autorização explícita):
- Criar em **novo gate/branch** um único runner protegido `-Mode Prepare/-Mode Verify`, aproveitando padrão de #208/#210 **sem reutilizar executores pinados a outros HEADs como se fossem genéricos**. Versionar o runner antes da execução e registrar commit SHA + hash SHA-256. Parser PowerShell 5.1 PASS não é PASS de GUI.
- Verificar `main@SHA` atualizado, branch/HEAD exatos e worktree limpa; fechar QlikView; confirmar QlikView `12.0.20000.0` ou documentar drift para STOP e nova decisão. Verificar a **existência e SHA** da fonte TEMP do #208, e os hashes de **10+12 QVD + 3 QVW canônicos** pré/pós.
- Preparar **uma nova cópia QVW única** com RunId e diretórios novos, fora do Git. Não executar COM, reload, Store, SaveAs em origem, nem abrir a origem protegida para edição.
- Na **cópia apenas**, implementar os **dois** objetos diagnósticos e documentar ID, expressão/condição/posição; salvar a cópia **uma única vez antes das ações T1/T2**, nunca salvar estados experimentais após `Limpar`. Se o QlikView perguntar ao fechar, escolher **Não salvar**.
- Evidências locais sob `EVIDENCE_DIR` resolvido pelo Prepare: `manifest.json`, `preflight.txt`, `t0_state.png`, `objects_properties.png`, `t1_before.png`, `t1_after.png`, `t2_valid_2019.png`, `t2_after_clear.png`, `gui_notes.txt` e stdout de Verify. **Não** afirmar que presença de PNG comprova conteúdo. Captura de seleção real + canário deve aparecer na mesma folha/sessão, com timestamps/notas de ações.
- Após fechar completamente o QlikView, rodar **uma** verificação de hash em fonte, TEMP e 25 protegidos; reportar `SOURCE_UNCHANGED`, `PROTECTED_25_UNCHANGED`, `COPY_CHANGED_FROM_SOURCE`, `VERIFY_EXIT_CODE`, commit, hash runner, RunId. Evidência de integridade é **separada** da visual/semântica; hashes não comprovam que somente dois objetos mudaram.
- Não repetir Prepare/Verify para “obter PASS” se falhar; preservar logs brutos e produzir closeout restrito com causa. Não fazer merge de runner apenas porque o Verify passou. Nunca commitar QVW/QVD/datasets/screenshots binários sem política de artefatos.

## 6. Vereditos e fronteira máxima de aceitação

| Veredito | Condição necessária | Pode concluir |
|---|---|---|
| `PASS_RESTRICTED_R2_T1_T2_SAME_TEMP` | Uma QVW TEMP corretamente pinada; **T1** botão bloqueado + motivo e seleção real preservada; **T2** após `Limpar` ano explicitamente sem seleção e canário anual indisponível + motivo; capturas/expressões inspecionadas; Verify fonte+25 intactos | **Somente** prevenção guiada nesse conflito e validação de um KPI anual FI após **um comando** nativo. **Nunca `C2_GUIDED_R2=APPROVED` global** |
| `BLOCKED_GUIDED_PRE_DISPATCH` | Botão muda a seleção ao aceitar proposta incompatível, habilita contra condição ou não explica bloqueio | STOP, preservar evidências; não executar T2 |
| `BLOCKED_POST_NATIVE_PRESENTATION` | Depois de mutação nativa comprovada, canário/visual rotulado anual continua mostrando valor semanticamente inválido, ultrapassa guarda ou não explica indisponibilidade | STOP; não mascarar problema com novo Set Analysis |
| `INCONCLUSIVE` | Fonte/estado inicial não correspondem, UI/expressão indisponível, `Limpar` não produz estado esperado, prints/relatos ausentes ou integridade não demonstrada | Não atribuir PASS; não repetir sem novo critério |
| `HARD_STOP_INTEGRITY` | Fonte ou qualquer dos 25 protegidos mudou, parser/runner/branch não correspondem, tentativa de escrita fora da cópia ou QVW origem ausente/hash incompatível | Não tocar outros arquivos; preservar dados e interromper |

**Estado após qualquer resultado deste ensaio:** `MAIN_EFFECTIVE_D2_SEMANTICS=D2_R2_V3`; `C2_FULL_V2=NO_GO_NOT_APPROVED` histórico; `C2_GUIDED_R2=NOT_APPROVED_GLOBAL` até conjunto de provas em **todos os indicadores relevantes** e aceite separado. `P5_D2_UI=NOT_TESTED_GLOBAL`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**Risco de lacuna:** a exigência V3 “revalidar **cada indicador**” não pode ser satisfeita por um canário; portanto o gate físico `SAD-C2-GUIDED-R2-PHYSICAL-ACCEPTANCE-01` deverá separar **PASS restrito de T1/T2** de um eventual aceite global futuro. Não expandir a rodada T1/T2 automaticamente para os 14 visuais; o próximo escopo somente após revisão do primeiro resultado e autorização específica.

## 7. Decisão pendente e STOP da presente especificação

**FATO VERIFICADO:** D2-R2 V3 aprovada semanticamente/merge #213, `current-state.md` corrigido no #214; propriedades de `BU16` e rotas nativas inventariadas com evidência visual; preservação local fonte/25 no Verify #210; oráculo anual FI 2019 de 188246 em #205. O repositório GitHub não armazena a QVW TEMP nem as capturas nativas dessa nova rodada.

**HIPÓTESE DE IMPLEMENTAÇÃO:** até dois novos Text Objects na cópia podem demonstrar motivo de bloqueio guiado e indisponibilidade de **um** KPI anual depois de `Limpar`. Compatibilidade QlikView, efeito real de `Limpar` e funcionamento das expressões **ainda não testados**.

**DECISÃO PENDENTE DO RESPONSÁVEL:** autorizar **separadamente** o preparo de runner versionado, nova QVW TEMP e **uma** execução T0/T1/T2, com dois objetos auxiliares e uma operação nativa, **sem alteração de quaisquer fontes/canônicos**. Este documento/PR não constitui tal autorização.

**STOP deste gate documental:** um Markdown novo com contrato falsificável e fonte SHA pinada, PR Draft e anotação na Issue #196. Sem merge, testes locais, QVW, COM, novas seleções, C3/C4 ou Fase IX. Se fonte física ausente/hash diferente, não recriar e não desviar escopo.
