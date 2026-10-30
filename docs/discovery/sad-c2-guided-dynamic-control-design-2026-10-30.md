# SAD C2 — contrato candidato de navegação temporal dinâmica (READ-ONLY)

**Gate:** `SAD-C2-GUIDED-DYNAMIC-CONTROL-DESIGN-01`  
**Data:** 30/10/2026  
**Base conferida:** `main@843e8f4fea74a8d8ab60ebbab2033c4d181dd961`  
**Natureza:** documento de desenho e handoff; **não implementado, não homologado fisicamente**.  
**Estado:** `PASS_DOCUMENTAL_RESTRICTED / DESIGN_CANDIDATE_PENDING_APPROVAL`; `NEXT_PHYSICAL_GATE=NOT_RUN_NOT_AUTHORIZED`.

## 1. Objetivo, autoridade, fronteira e fontes

Registrar um desenho candidato para aplicar `MENSAL`, `ANUAL` e `EVOLUCAO` em campos temporais reais do QlikView 12, a partir do diagnóstico de `BU13` e `CH02`, **sem** alterar o modelo acadêmico, o dado, a semântica V2 ou objetos físicos. Este documento não substitui o contrato C2 existente e não autoriza um piloto automaticamente.

Fontes consultadas e precedência operacional:
1. [AGENTS.md](../../AGENTS.md) → [current-state](../project/current-state.md) → [requisitos acadêmicos](../academic/requirements.md), na `main`.
2. [V2 semântica aprovada, §62.3 (D2) e §62.6 (P5)](phase-6-semantic-v2-approved-2026-10-14.md) e [Boundary 7](boundary-7-implementation-plan.md).
3. [C2-G](phase-8-c2g-temporal-selection-design-decision-2026-10-21.md), [C2-I](phase-8-c2i-residual-temporal-selection-closure-2026-10-21.md), [C2-J](phase-8-c2j-guided-real-selection-p5-2026-10-22.md), [C2-K](phase-8-c2k-guided-annual-evolution-pilot-2026-10-22.md), [contrato UX P1.1/P1.2](sad-p1-p11-p12-ux-contract-2026-10-28.md), [closeout P1.1/P1.2](sad-p11-p12-physical-closeout-2026-10-29.md), [inventário de compatibilidade](sad-c2-visual-compatibility-inspection-2026-10-29.md).
4. [PR #199 — ensaio EVOLUCAO/2019](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/199), **Draft e não integrado**; sua evidência pertence à branch até eventual revisão/merge. Imagens adicionais das propriedades QlikView foram fornecidas diretamente pelo operador em conversa de 30/10/2026; **não são anexos GitHub nem inspeção independente do binário QVW**.

**Escopo deste PR:** exclusivamente documentação Markdown. Não editar `QVW`, `QVD`, `QVS`, runner, dados, expressões, objetos, variáveis, código de produção, integração ou qualquer artefato canônico. Nenhum merge neste gate.

## 2. Inventário factual com nível de evidência

| Elemento | Achado e proveniência | Classificação |
| --- | --- | --- |
| `BU13` — `Aplicar Ano 2019` | Capturas QlikView 12 do operador mostram o ID `BU13` e a condição literal abaixo. | `VERIFIED_BY_OPERATOR_SCREENSHOTS`; não leitura do QVW pelo agente GitHub |
| Condição do `BU13` | Exige modo `ANUAL`, ano proposto `2019`, um ano real `2018` e uma competência real `201801`. | `VERIFIED_BY_OPERATOR_SCREENSHOTS`; coincide com C2-K |
| Ação do `BU13` | Uma ação `Selecionar no Campo`: campo `PERIODO_ANO`, pesquisa ``=Num($(vSAD_POC_Year))``. Ordem de uma única ação visível; estado alternativo não demonstrado. | `VERIFIED_BY_OPERATOR_SCREENSHOTS` / estado alternativo `UNKNOWN` |
| Proposta e seleção real | `vSAD_POC_Mode=EVOLUCAO`, `vSAD_POC_Year=2019`, `vSAD_POC_Month=1`, `vSAD_POC_Analysis=RES`; indicadores na folha exibem `ANO REAL: SEM SELECAO` e `COMPETENCIA REAL: SEM SELECAO`. | `VERIFIED_BY_OPERATOR_SCREENSHOTS` |
| Causa local do desabilitamento | O estado observado não satisfaz a guarda do `BU13` (modo incorreto e contagens temporais iguais a zero). | `VERIFIED_FOR_OBSERVED_STATE`; não prova causa de quaisquer outros botões/estados |
| `CH02` histórico | ID `CH02`, linha com dimensão `PERIODO_COMPETENCIA`, expressão abaixo; sem condição de cálculo nem limite de dimensão; ocultar zeros/faltantes habilitado. | `VERIFIED_BY_OPERATOR_SCREENSHOTS`; estado alternativo `UNKNOWN` |
| Evolução 12 pontos sob seleção real | O ensaio do PR #199 parou antes da aplicação do ano; não houve contagem 12/12 nem comparação de pontos. | `NOT_TESTED` |
| Integridade da inspeção adicional | PR #199 reporta Verify local anterior com cópia/fonte e 25 protegidos íntegros; **não há novo SHA final reportado após as capturas adicionais desta Discovery**. | `PR199_PASS_LOCAL_REPORTED_ONLY / NEW_POST_INSPECTION_SHA_PENDING` |

Condição **literal** registrada nas propriedades de `BU13`:

```qlik
=If(
 '$(vSAD_POC_Mode)'='ANUAL'
 and $(vSAD_POC_Year)=2019
 and GetSelectedCount(PERIODO_ANO)=1
 and Only(PERIODO_ANO)=2018
 and GetSelectedCount(PERIODO_COMPETENCIA)=1
 and Only(PERIODO_COMPETENCIA)=201801,
 1,0)
```

Ação literal registrada: `Selecionar no Campo` → `PERIODO_ANO` → ``=Num($(vSAD_POC_Year))``. Essa configuração é **uma prova de conceito de transição específica**; não é uma guarda dinâmica genérica.

`CH02`, expressão física observada:

```qlik
=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)
```

O modificador fixa o conjunto de anos **para a agregação**; ele é risco de incompatibilidade com `EVOLUCAO/ano`, mas **não comprova** se seriam exibidos 36 pontos sob uma seleção anual real, pois dimensão/associações/estado importam. Não modificar o gráfico histórico antes de novo contrato físico e oráculo.

## 3. Contrato semântico preservado versus desenho pendente

**APROVADO anteriormente, exclusivamente no nível semântico:** QlikView 12, `BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL`; três fatos/oito dimensões, Star/constelação e grãos; D2 V2 = prevenir incompatibilidade temporal **antes do despacho**; P5 V2 = filtros `C/R/I/B` por indicador; internações novas `QTD_INTERNACAO` (não `QTD_REGISTRO_AIH`); CNES/LT e POP não aditivos no tempo. Preservar `C2 → C3 → C4` do Boundary 7.

**PROPOSTO, NÃO APROVADO fisicamente:** um único ponto controlado para validar e despachar um contexto temporal. Não presumir transação ou rollback automático no QlikView; não utilizar triggers pós-seleção para declarar conformidade D2.

| Modo de proposta | Validação de entrada | Contrato de seleção real após aplicação |
| --- | --- | --- |
| `MENSAL` | ano inteiro `2017..2019`, mês inteiro `1..12`, competência `AAAAMM` existente no recorte | exatamente uma `PERIODO_COMPETENCIA` explicitamente selecionada, pertencente ao ano proposto; ano associado coerente, sem exigir que `PERIODO_ANO` também esteja explicitamente selecionado |
| `ANUAL` | ano inteiro `2017..2019`, sem mês operacional | `GetSelectedCount(PERIODO_ANO)=1` e valor do ano proposto; `GetSelectedCount(PERIODO_COMPETENCIA)=0` |
| `EVOLUCAO` | mesmas condições temporais de `ANUAL` | mesmo estado real de `ANUAL`; visual candidato deve fornecer 12 competências no ano aplicado, em gate separado |

O valor armazenado em `vSAD_POC_Month` é **inerte** em `ANUAL` e `EVOLUCAO`: não despachar nem apresentá-lo como seleção aplicada. `vSAD_POC_Analysis` define apenas a análise proposta; sua compatibilidade com P5 precisa de prova separada.

### Máquina de estados conceitual (não é script Qlik)

1. `PROPOSED`: ler `vSAD_POC_Mode`, `vSAD_POC_Year`, `vSAD_POC_Month`, `vSAD_POC_Analysis`; não confundir proposta com `GetSelectedCount`/`GetFieldSelections` dos campos reais.
2. `VALIDATE_BEFORE_DISPATCH`: domínio e existência do período; ausência de contradição com seleção temporal real e outras seleções relevantes; regras D2 e P5 aplicáveis à análise. Estado atual ambíguo ou incompatível → `BLOCKED_WITH_REASON` sem despachar.
3. `DISPATCH_CANDIDATE`: somente após autorização de rota controlada; escolher **uma ação temporal** direcionada ao campo real, sem `Clear All`, limpeza silenciosa, bookmark, trigger/rollback, nem cadeia não comprovada de ações. A capacidade de preservar seleção anterior **não é garantida** por esta proposta.
4. `VERIFY_APPLIED_CONTEXT`: ler contagem e valores dos campos reais; qualquer divergência mantém UI `PENDING/INCOMPATIBLE`, sem apresentar número antigo como novo.
5. `PRESENT`: aplicar política do visual somente após confirmar estado real; separar disponibilidade de período de cobertura/escopo/denominador de cada indicador.

**Guarda candidata (pseudológica, NÃO expressão QlikView aprovada):**
`valid_mode && valid_year && (mode != MENSAL || valid_month) && allowed_current_selections && permitted_dispatch_route`. Não depender de `Only()` isolado para provar seleção explícita; usar contagem real e verificar valor. Um predicado true não prova atomicidade, nem bloqueia outras rotas nativas.

### Políticas por tipo de transição (candidatas)

| Origem → destino | Conduta conservadora |
| --- | --- |
| Sem seleção temporal explícita → `EVOLUCAO/2019` | Candidata a uma ação `Select in Field(PERIODO_ANO,2019)` no **próximo gate físico específico**, se não houver outro conflito |
| Sem seleção temporal explícita → `MENSAL/AAAAMM` | Candidata futura, não coberta pelo próximo gate |
| `ANUAL/2019` → `EVOLUCAO/2019` | Reutilizar o mesmo ano real; o modo por variável não deve simular nova seleção |
| Competência explícita de 2018 → `ANUAL/2018` | `BLOCKED` até contrato seguro de remoção explícita da competência, sem supor limpeza |
| `MENSAL/201801` → `ANUAL/2019` | C2-K mostrou um PASS **restrito** dessa transição; não generalizar para demais estados sem prova |
| Proposta inválida, filtros incompatíveis ou estado ambíguo | Bloquear pré-despacho e preservar contexto; indicar motivo |

A solução completa ainda precisa especificar e testar o tratamento das **rotas alternativas** (listas, busca, menus, bookmarks e outros objetos), que C2-I não homologou. Mitigação `Read Only` de uma lista não protege o campo em todos os caminhos; `D2_GLOBAL` permanece `NO_GO`.

## 4. Contrato de consumo P1.1/P1.2 — sem mutação nesta etapa

- **Histórico P1.2:** preservar `CH02` e o oráculo reconciliado de `36 competências 201701..201912` **no estado histórico de referência**. Não prometer que esse objeto permaneça invariável sob quaisquer filtros.
- **EVOLUCAO guiada:** **candidato separado** para `12 competências` do ano real aplicado, com dimensão `PERIODO_COMPETENCIA` e mesma medida semântica `QTD_INTERNACAO`. `Sum(QTD_INTERNACAO)`, sem modificador fixo de ano, é apenas **expressão candidata para estudo**, não homologação, nem implementação neste gate.
- **ANUAL:** um KPI do ano aplicado; não expor `555.089` trienal como um KPI anual. `MENSAL`: valor de uma competência, sem chamá-lo de tendência.
- Prova futura do gráfico `EVOLUCAO` exige 12 pontos e reconciliação linha a linha contra o **subconjunto de 2019** do TSV histórico já arquivado (SHA-256 documentado `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`); não repetir 36/36 nem recalcular a fato.
- Alternativa de estado `CH02` e tratamento sob filtros `UNKNOWN`; se inviabilizarem isolamento entre as duas superfícies, parar antes de redesenhar.

## 5. Decisões ainda pendentes — sem aprovação implícita

| Questão | Recomendação de design / condição para avançar |
| --- | --- |
| Generalizar a condição de `BU13` | **Não substituir o predicado no QVW atual**. Projetar guarda genérica em uma cópia nova e testar somente a rota especificada. |
| Limpar automaticamente ano/competência? | **Não por padrão**; qualquer política de limpeza/confirmation requer decisão e evidência próprias. |
| Reutilizar `CH02` para os dois modos? | **Não inicialmente**; separar a superfície histórica da guiada reduz risco, mas ainda exige validação física e aprovação. |
| Novas variáveis para `applied`? | **Adiar**; ler seleção real como fonte de verdade. Variáveis auxiliares não garantem que campo foi selecionado. |
| Admitir alternativas nativas e declarar D2 global? | **Não** até rotas expostas e pré-despacho comprovados. |
| Confiar em `PASS` do PR #199 como série de 12 meses? | **Não**: PASS de integridade é separado do bloqueio funcional. |
| Declarar integridade da última inspeção de propriedades? | **Pendente de SHA pós-fechamento**; evidência de ensaio anterior não substitui novo hash. |

## 6. Próximo gate proposto — precisa de autorização independente

**ID:** `SAD-C2-GUIDED-DYNAMIC-DISPATCH-POC-01`  
**Estado:** `PROPOSED_NOT_RUN_NOT_AUTHORIZED`.  
**Agente primário:** Codex Local **Windows**, em sessão nativa QlikView 12 com acesso verificado; fallback operador humano; GPT-6/GitHub somente para revisão. Modelo/esforço efetivos do executor local devem ser registrados, não presumidos.

**Objetivo único:** demonstrar, em **nova QVW descartável** de origem e hash previamente validados, que um controle candidato **genérico** habilita e despacha `EVOLUCAO/2019` quando não há seleção temporal explícita, por **uma única ação** `Selecionar no Campo(PERIODO_ANO)`. Não reaproveitar `BU13` de teste para declarar generalização; não alterar a QVW histórica.

**Pré-condições e fronteira de escrita futura:** gate de implementação separado e autorizado, script de preparação versionado antes da execução local se necessário, branch/HEAD pinados, QlikView 12, fonte e 25 protegidos conferidos conforme protocolo, runtime/evidências fora do Git, somente a **nova cópia TEMP** editável. Não usar automaticamente executores de #197–#199 com outras fontes/pins; reusar apenas os padrões apropriados. Não salvar nem recarregar QVD/QVW canônicos. Este documento **não autoriza** criar a cópia ou modificar botão.

**Cenário único do gate seguinte:**
1. Partir de QVW TEMP com `GetSelectedCount(PERIODO_ANO)=0` e `GetSelectedCount(PERIODO_COMPETENCIA)=0` confirmados, sem conflito de outros filtros; registrar estado prévio, ID/condição/ação do controle candidato.
2. Propor `vSAD_POC_Mode=EVOLUCAO` e `vSAD_POC_Year=2019`, documentando os valores.
3. Exigir habilitação por condição genérica não dependente de `201801`/`2018` e disparar **uma vez** uma única seleção do ano real.
4. Ler `GetSelectedCount(PERIODO_ANO)=1` com valor `2019` e `GetSelectedCount(PERIODO_COMPETENCIA)=0`; conferir ausência de conflito/efeito colateral silencioso.
5. Fechar e registrar integridade da fonte/25 protegidos, propriedade do controle e capturas pré/pós; evidências brutas fora do Git.

**Aceite:**
- `PASS_VISUAL_RESTRICTED_SINGLE_NO_SELECTION_TO_EVOLUTION_2019`: guarda e ação observadas, ano real `2019`, competência sem seleção, sem filtro colateral, origem/protegidos preservados; **não** significa que a regra cobre outras transições nem que `CH02` mostra 12 pontos.
- `BLOCKED`: ação indisponível, seleção temporal incompatível, efeito não preservado, recurso não disponível ou risco de mutação em protegido.
- `INCONCLUSIVE`: captura, leitura de propriedades, seleção, proveniência ou hash insuficiente.
- `HARD_STOP`: fonte/protegidos modificados, necessidade de mudar modelo/semântica ou executar ação fora do protocolo.

**STOP:** uma cópia, uma condição/ação candidata, uma interação e uma verificação de integridade. **Sem** repetir C2-J/K, PR #199, 36/36 histórico, avaliar 12 pontos, P5 global, C3/C4, Fase IX ou produção. Um gate **posterior e independente** deverá tratar o gráfico guiado de 12 pontos.

## 7. Resultado desta revisão e governança

`DESIGN_DOCUMENTED_ONLY=True`; `STATIC_REVIEW_REQUIRED_IN_PR=True`; `PHYSICAL_DISPATCH=NOT_TESTED`; `PR_199=OPEN_DRAFT_NOT_MERGED`; `NEW_GATE_AUTHORIZED=False`.

Estados preservados: `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. Nenhum merge/alteração física decorre deste documento.

**STOP do design:** contrato, pendências e próximo gate delimitados. Revisar exclusivamente o diff Markdown; a autorização para o piloto físico e eventual merge exigem decisão posterior.
