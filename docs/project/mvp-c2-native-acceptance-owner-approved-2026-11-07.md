# SAD MVP — C2 nativo: decisão aprovada de escopo e critérios de aceite

**Data:** 07/11/2026. **Identificador:** `SAD-MVP-C2-NATIVE-POST-SELECTION-ACCEPTANCE-SCOPE-01`. **Aprovação do responsável:** “aprovado, prossiga” após apresentação de [consolidação do MVP e decisão proposta](mvp-evidence-and-contract-gates-consolidation-2026-11-07.md), para **aceitação limitada aos filtros nativos dos nove objetos B1**, anterior à prova física F04. **Nível:** `OWNER_C2_MVP_ACCEPTANCE_SCOPE=APPROVED_BRANCH_ONLY`, **não** `C2_GUIDED_R2=PASS` ou `C2_MVP_PHYSICAL=PASS`. A decisão consta da conversa do Projeto SAD, não constitui aprovação do professor nem merge.

## 1. Autoridade, fronteira e invariantes

Consultadas na `main`, em ordem, `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`; depois [Boundary 7](../discovery/boundary-7-implementation-plan.md), [V2 §62](../discovery/phase-6-semantic-v2-approved-2026-10-14.md), [V3 D2-R2](../discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md). O contrato semântico D2-R2 V3 **permanece integral e vigente na `main`**; esta decisão define o **subconjunto do MVP B1** a ser demonstrado, sem alterar a política P5 C/R/I/B, os grãos, as três fatos, as oito dimensões, a Link Table, a ilha P23 nem o fluxo acadêmico QlikView 12.

**Escopo aceito:** somente [nove visuais M1-01..M3-03](mvp-scope-owner-approved-2026-11-07.md) em três folhas, com filtros **nativos** do QlikView Desktop. A interface **não contém, neste candidato, os controles guiados oficiais** BU15/BU16/modos ANUAL/MENSAL/EVOLUCAO. Portanto, a cláusula `GUIDED_PRE_DISPATCH_PREVENTION` é `NOT_APPLICABLE_TO_B1_MVP_SURFACE` **apenas onde não houver despacho guiado**: não se está validando o fluxo guiado nem revogando sua obrigação se for futuramente introduzido. Nem o MVP nem o contrato V3 prometem prevenção **antes** de todas as ações nativas.

**Critério aprovado de pós-seleção:** cada indicador exposto precisa reagir ao **estado realmente aplicado**. Somente três classificações são admissíveis:
- `VALID`: medida, papel municipal, competência/ano e legenda continuam coerentes com a seleção e com oráculos documentados;
- `UNAVAILABLE_WITH_REASON`: seleção incompatível, sem cobertura, ambígua ou fora do contrato **oculta o resultado enganoso** e exibe motivo compreensível; jamais converter ausência associativa em zero comprovado;
- `INCONCLUSIVE`: dados/controles legíveis insuficientes para decidir, exigindo investigação localizada, **não** homologação por presunção. Resultado incorreto/obsoleto exibido como válido ⇒ `BLOCKED_FOR_USER_USE`.

**Ordem de gates:** C2-MVP nativo físico restrito **antes de** C3 (keys/associações), antes de C4 (medidas/filtros por indicador), depois **GO IX separado**, sem equivalência a `C2_GUIDED_R2` físico global. Não realizar merge, mudanças em `main`, QVD, QVW canônico ou reconstrução de fatos para registrar esta decisão.

## 2. Matriz de aceitação mínima por visual do MVP B1

| Objeto / medida | Contexto nativo permitido e que exige revalidação | Resultado enganoso ou motivo de indisponibilidade | Evidência atual |
|---|---|---|---|
| **M1-01** novas internações por ano | Série por `PERIODO_ANO`; clique em ano real deve atualizar todas as visualizações FI elegíveis | Ano selecionado diferente do mostrado; exibição de total trianual como ano único | F01 2019/188246 restrito |
| **M1-02** internações por competência | Série `PERIODO_COMPETENCIA` de 36 meses e subconjuntos temporais honestamente rotulados | Mostrar meses fora do recorte como se fossem ativos ou chamar parcial de ano completo | F01 eixo 2019 cortado ⇒ inconclusivo para 12 meses |
| **M1-03** ranking município SERV | Seleção temporal/territorial deve preservar o papel `SERV_COD_DATASUS_6` | Confundir RES com SERV, ranking fora do recorte sem avisar | Renderização, sem prova formal de ranking |
| **M2-01** snapshots LT por competência | Contagens de leitos **mês a mês**, sem soma anual e sem inferência zero de ausência; RES incompatível precisa de aviso | Indisponibilidade silenciosa ou oferta de leitos interpretada como residência | F03-U1 guarda RES testada S_BAD/S_OK na cópia TEMP |
| **M2-02** leitos SUS por SERV em **201912 fixo** | Snapshot 201912 **somente** quando o estado efetivo for compatível ou a independência for formalmente explícita e autorizada | Seleção real de 2018/competência diferente + exibição de 201912 como resultado válido do contexto atual; vazio genérico sem motivo | **F04 2018 ainda NÃO TESTADO**; guarda RES já provada isoladamente |
| **M2-03** observabilidade P23 | Ilha `P23_A1_ISLAND` não deve se associar aos filtros globais; três classes são estado observado, não taxa de cobertura | Interpretar ausência de linha como zero real ou reduzir ilha por filtro global sem prova | F03/F03-U1 três barras sob RES (visual restrito) |
| **M3-01** classificação RES=SERV/diferente | Seleções permitidas devem manter dois papéis distintos e resultados FI reconciliáveis | Reclassificar município fora da PB, inventar POP do externo, exibir partes incoerentes | M3 triênio 294635/260454, F02 restrito |
| **M3-02** pares dirigidos RES→SERV | Tabela por dois papéis e `Sum(QTD_INTERNACAO)` do recorte, sem POP implicada | Total que ignora estado temporal, inversão dos papéis, consumo como taxa | F01 2019=188246; F02 251370→250750=12176 |
| **M3-03** POP município×ano | Células anuais por município; sem soma temporal/população mensal; exibir estado temporal real | Total trianual ou POP extrapolada de residentes externos; associação FI≠POP assumida | F01 2019 e F02 RES; ausência de total visível; demais filtros pendentes |

**Regra transversal:** F01/F02/F03-U1 são **PASS restritos não repetíveis por padrão**; não converter suas capturas em aprovação de C2/C3/C4 de qualquer rota. **Guardas M2-01/M2-02 foram configuradas manualmente e existem apenas em QVW TEMP, não no builder versionado.** Persistência após fechamento/reabertura ainda não demonstrada. A matriz não inclui T24/T25/T26 (fora dos nove visuais) e não legitima denominadores não testados.

## 3. Teste físico F04 delimitado pela decisão

**Um cenário prioritário:** `PERIODO_ANO=2018` aplicado pelo gráfico anual nativo M1-01; sem seleções adicionais; inspeção de M2-02, cujo título e Set Analysis candidato fixam 201912. Não supor que o QlikView mostrará barras, vazio ou mensagem; **a prova deverá distinguir o estado observado**. Regra de aceite: um visual sob 2018 **não pode apresentar a medida de dezembro/2019 como capacidade de 2018 sem uma fronteira/contextualização explicitamente aprovada**. `UNAVAILABLE_WITH_REASON` é permitido; “Não há dados” sem explicação não basta para uso final. O estado de M2-01 é informação secundária; não ampliar o gate.

O teste **não** troca `201912` por uma medida dinâmica, não acrescenta condições antes de observar a execução nativa, não gera nova QVW nem altera dados. Executar no QlikView Desktop Windows **somente** na cópia TEMP manual `SAD_F03_UI_GUARD_TEMP_a3bedd3bf2444d2ab46d890776d3e2b8/SAD_MVP_F03_UI_GUARD_CANDIDATE.qvw`, em sessão GUI sem Reload/Save, com captação de `Seleções Atuais`; ver [roteiro F04](mvp-f04-2018-versus-fixed-lt-201912-gui-protocol-2026-11-07.md).

**PASS/BLOCKED/INCONCLUSIVE da decisão documental:** a definição de escopo está **APROVADA PELO RESPONSÁVEL**, sem transição para `C2_MVP_PHYSICAL=PASS`. A prova F04 produzirá somente `F04=PASS_RESTRICTED`, `BLOCKED` ou `INCONCLUSIVE` após screenshot real. A correção de um bloqueio futuro exige gate próprio, não mudança silenciosa de expressão/arquitetura.

## 4. Encerramento

`OWNER_C2_MVP_ACCEPTANCE_SCOPE=APPROVED_BRANCH_ONLY`; `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`; `GUIDED_PRE_DISPATCH_PREVENTION=NOT_APPLICABLE_TO_B1_MVP_SURFACE`; `C2_GUIDED_R2=NOT_TESTED`; `C3=NOT_APPROVED`; `C4=NOT_APPROVED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `P5_D2_UI=NOT_APPROVED_GLOBAL`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP deste gate:** registrar decisão e um protocolo F04; solicitar **uma prova GUI apenas**, não executar automação, não criar/alterar QVW, não tocar `main` e não inferir diagnóstico antes da captura. A aprovação do escopo não aprova antecipadamente nenhuma combinação de filtros de resultado desconhecido.
