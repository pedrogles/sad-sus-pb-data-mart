# SAD — Adendo semântico V3 | D2-R2: prevenção guiada e validação de rotas nativas

**Data da decisão:** 03/11/2026  
**Gate:** `SAD-D2-R2-V3-SEMANTIC-ADDENDUM-01`  
**Natureza:** decisão **semântica do responsável, expressamente aprovada**; registro documental ainda dependente de integração na `main`.  
**Baseline documental:** `main@59dc80a4db24f8ada257e9354e464f3393bfcab6` (antes deste adendo).  
**Status enquanto o PR não for integrado:** `OWNER_SEMANTIC_APPROVAL=GRANTED`; `V3_ADDENDUM_MAIN_INTEGRATION=PENDING`; **a `main` ainda contém a V2 como contrato operacional**, sem substituição documental silenciosa.  
**Após merge autorizado do adendo:** `D2_V2_GLOBAL=SUPERSEDED_BY_OWNER_APPROVED_D2_R2` no nível **semântico**; `C2_GUIDED_R2=NOT_TESTED` e `PRODUCTION_APPROVED=False` permanecem.

## 1. Proveniência, fonte de verdade e escopo

O responsável foi perguntado expressamente: **“Você aprova formalmente R2-A como substituição semântica do D2=B original, reconhecendo que as rotas nativas não terão prevenção global garantida?”** Respondeu **“aprovado, prossiga”** na conversa do projeto em 03/11/2026. É autorização da **revisão semântica descrita na pergunta e na [minuta R2 do PR #212](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/212)**; **não** é autorização para execução física, alteração estrutural de dados, aprovação de produção ou merge automático.

Foram revalidados na `main`, nesta ordem: [AGENTS.md](../../AGENTS.md) → [current-state.md](../project/current-state.md) → [requirements.md](../academic/requirements.md) → [transcrição semântica V2](phase-6-semantic-v2-approved-2026-10-14.md); em seguida, a minuta [R2 #212](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/12dfa6d3ea02e7a13ca89994203ba68e7ad28d0d/docs/discovery/sad-c2-d2-r2-semantic-review-2026-11-03.md), o [B2 #211](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/211), as evidências de [Issue #196](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/196#issuecomment-6609988083), os [Boundaries 6/7](boundary-7-implementation-plan.md) e o [blueprint visual aprovado](../project/three-panels-blueprint-approved-2026-11-03.md).

**Precedência:** este adendo, **somente quando integrado**, altera **exclusivamente D2** da V2 §62.1/§62.3 no aspecto descrito abaixo. A V2 de 14/10/2026 **não será editada** e continua sendo evidência histórica da aprovação original, inclusive de seu `NO_GO` físico. Não alterar D1, D3–D8, P1–P5, RN01–RN21, números, expressões ou regras de negócio.

## 2. Texto normativo V3 — alteração restrita a D2

### 2.1 D2-R2 aprovado semanticamente

**Identificador:** `D2-R2=GUIDED_PREVENTION_PLUS_NATIVE_VALIDATION`.

**Regra 1 — aplicação guiada (prevenção anterior à mutação).** Quando o usuário formular uma proposta temporal por controles guiados aprovados, a aplicação **deverá verificar antes de qualquer despacho** a validade da proposta (modo, ano, competência, domínio, cobertura conhecida), a compatibilidade com o estado real e o tratamento do indicador/filtros permitido por P5. Se houver conflito, ambiguidade ou pré-condição não demonstrada, **não aplicar ação de seleção**, não apagar ou substituir silenciosamente a seleção vigente e apresentar o motivo ao usuário. Proposta em variável **não é** seleção aplicada.

**Regra 2 — operações nativas fora do fluxo guiado (validação após a mutação).** Em rotas nativas do QlikView Desktop que não passam pela guarda guiada (menu/atalhos, Voltar/Adiante, Limpar, Destravar, configurações de estado, busca, seleção em gráficos/tabelas/listas, marcadores importados ou restaurados, seleções atuais e outras ações acessíveis), **não existe compromisso de prevenção anterior à alteração**. A interface deverá interpretar o **estado efetivamente aplicado**, não um período proposto ou resultado anterior, e revalidar **cada indicador**. Contexto ambíguo, insuficiente, incompatível com o indicador ou filtros não autorizados deverá ser explicitamente **Indisponível**, com o motivo relevante e **sem publicar indicador incorreto ou desatualizado como válido**. A própria transição da UI/expressões exige prova física; este adendo não a presume.

**Regra 3 — seleção nativa semanticamente válida.** Seleções nativas **não são automaticamente inválidas**: a análise deve reconhecer contextos permitidos pela V2 (competências parciais; meses não consecutivos enumerados; séries anuais separadas; série anual dimensionada por ano sem seleção pontual). A disponibilidade depende **do indicador**. Por exemplo, vários anos podem ser válidos para série anual por ano, mas tornam indisponível um **KPI pontual denominado anual**.

**Regra 4 — comunicação do escopo da garantia.** A aplicação e a documentação devem distinguir: (i) `GUIDED_PRE_DISPATCH_PREVENTION`, (ii) `NATIVE_POST_SELECTION_VALIDATION`, (iii) `D2_V2_GLOBAL_PREVENTION=NOT_DEMONSTRATED`. **É proibido declarar D2-R2 equivalente a D2=B da V2 ou reutilizar o rótulo `C2_FULL=PASS` para encobrir a redução de garantia.**

### 2.2 Delta explícito em relação à V2

| Local na V2 imutável | Garantia original aprovada (14/10) | Adendo V3 autorizado semanticamente (03/11) |
|---|---|---|
| §62.1, D2=B | Prevenir conflito ano/competência antes de descartar a intenção de seleção | **Prevenção obrigatória apenas no fluxo guiado oficial; reconhecimento e revalidação do contexto efetivo após operações nativas não abrangidas pela guarda**, com indisponibilidade dos indicadores incorretos |
| §62.3, frase “D2 exige prevenção antes da alteração de seleções” | Prevenção anterior para as seleções em geral | **Prevenção antes do despacho guiado**, com **limitação expressa** de não garantia anterior em rotas nativas; avaliação e supressão contextual depois delas |
| Gate de validação | `C2_FULL_V2` demandava cobertura de rotas globais | `C2_GUIDED_R2` é **gate novo, distinto e ainda não aprovado fisicamente**; o `NO_GO` global histórico permanece auditável |

**Linguagem exigida nas apresentações:** “Controle temporal guiado validado” só após teste e aceite físico correspondente. **Não** declarar “todas as seleções do QlikView são preventivamente protegidas”. Avisos de indisponibilidade e seletor real/proposto devem constar dos três painéis quando implementados.

## 3. Semânticas e arquitetura preservadas

1. **D1 e tempo analítico (§62.3):** competência administrativa SIH/RD permanece o eixo de demanda; `DT_INTER`/`DT_SAIDA` são papéis distintos. Um ano válido e completo, competências parciais, meses não consecutivos e séries multi-ano conservam os significados já aprovados. Não anualizar períodos parciais.
2. **D3–D8 e P1–P5:** nenhum ajuste em papéis territoriais RES/SERV, indicadores, denominadores, zero/ausência, cobertura CNES, regra de agregação, filtro `C/R/I/B` (§62.6), gates independentes ou inaditividade de POP/leitos. Não ignorar filtro conflitante com Set Analysis sem contrato.
3. **Modelo acadêmico:** as três fatos `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`, seus grãos, oito dimensões, `DIM_TEMPO` e projeções role-playing, Star/constelação e `LINK_ANALISE`/%LINK_KEY permanecem intactos; nenhum token, ponte ou chave temporal nova está autorizado.
4. **Fronteira populacional:** POP continua município × ano, sem duplicação por competência. Média de snapshots CNES/LT não vira soma anual. Indisponibilidade por cobertura não comprovada ou denominador inválido não vira zero.
5. **Blueprint:** três folhas e 14 análises aceitas no PR #209 permanecem referência. `CH02` histórico 36 competências e gráfico guiado de 12 competências continuam superfícies distintas. `P23_MUNICIPIO_6`/`P23_COMPETENCIA` permanecem filtros locais da ilha A1, não convertidos silenciosamente em filtro global.
6. **Material do professor:** [requirements.md](../academic/requirements.md) não classifica D2 como requisito explícito independente do professor. Isso não prova ausência de exigência externa; caso o professor requeira prevenção global, esta decisão interna não substitui esse requisito.

## 4. Contrato candidato de implementação e testes — ainda SEM GO

### 4.1 Fluxo guiado pretendido, sem presumir Qlik script aprovado

`PROPOSED` (variáveis `MENSAL/ANUAL/EVOLUCAO` + ano/mês) → `VALIDATE_BEFORE_DISPATCH` → `DISPATCH_IF_VALID` → `VERIFY_APPLIED_REAL_SELECTION` → `PRESENT_IF_VALID`.

Se a proposta for inválida, não se despacha. Não adotar limpeza automática `Clear All`, substituição silenciosa, trigger de rollback ou cadeia de ações como transação sem validação e autorização específicas. Transições de período já aplicado para outro período **ainda carecem de contrato físico**. O modo `EVOLUCAO` não altera o valor real do ano só porque a variável de modo mudou.

### 4.2 Matriz mínima de verificação posterior, sem repetir PoCs concluídas

| Cenário | Expectativa R2 | Evidência atual / lacuna |
|---|---|---|
| Proposta anual válida com nenhuma seleção temporal | Aplicar ano real explicitamente | `BU15` positivo 2019 PASS restrito em PR #201; outros contextos não generalizados |
| Proposta mensal conflitante com ano real | Bloquear **antes** de `Select in Field`, preservar contexto e comunicar motivo | Guarda `BU16` parcialmente observada em #208/#210; nenhum dispatch conflitante nesta inspeção |
| Proposta inválida: mês fora do domínio/competência ausente/escopo P5 incompatível | Bloquear e mostrar causa, sem descartar intenção | `NOT_TESTED` global |
| Alternar anual ↔ evolução do mesmo ano | Não criar falsa mudança de seleção; gráfico de 12 meses e histórico 36 são distintos | `CH02` 36/36 e `CH03` 12/12 restritos, sem integração final |
| Operação nativa deixa KPI pontual sem ano válido ou com vários anos | Indicador indisponível, motivado; não publicar número obsoleto | `NOT_TESTED` na interface final |
| Meses não consecutivos ou série com vários anos selecionados nativamente | Período parcial identificado; série válida separada por ano; KPI anual pontual indisponível se ambíguo | `NOT_TESTED` |
| `Clear`/`Back`/`Forward`, buscar, importar/restaurar bookmark, gráfico/tabela | Reavaliar todos os visuais afetados no estado real, sem mascarar filtros; ausência de atualização correta = BLOCKED | Superfícies observadas; comportamento não executado |
| Restrições P5, POP e leitos | Matriz de compatibilidade, denominadores e cobertura com critérios da V2 | `P5_D2_UI=NOT_TESTED_GLOBAL`; `C3/C4` pendentes |
| Ilha P2.3 e três painéis | Filtros locais separados e aviso sobre seleção global; layout preservado | Blueprint aprovado; física não iniciada |

**Gate físico futuro (proposto, não autorizado):** `SAD-C2-GUIDED-R2-PHYSICAL-ACCEPTANCE-01`, com contrato de objeto/expressão e mecanismo de revalidação, uma QVW TEMP sob hash, versão QlikView 12.0.20000.0, executor versionado antes de executar, casos mínimos ainda sem evidência, oráculos e matriz `PASS/BLOCKED/INCONCLUSIVE`. **Não** exigir provar prevenção nativa global como requisito da nova garantia, mas exigir que erros de apresentação após rota nativa sejam **detectados e impedidos de aparecer como válidos**. A propriedade `Read Only` local não é garantia de segurança do campo; `Enable Condition` de BU15/BU16 não prova proteção de outras rotas.

**STOP no primeiro cenário crítico de apresentação inválida**; não abrir automaticamente novas PoCs nem repetir C2-D/C2-F/#201/#205/#208/#210 sem necessidade de regressão diretamente justificada.

## 5. Estado, governança e ativação documental

**Aprovação semântica do responsável:** `D2_R2_OWNER_APPROVED=True`, com redução da garantia explicitamente reconhecida. **Aprovação física:** `C2_GUIDED_R2=NOT_TESTED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `C2_FULL_V2=NO_GO_NOT_APPROVED`. O gate da versão V2 **não passou retroativamente**.

**Antes de integração na `main`:** `D2_R2_V3_DOC=PR_PENDING_MERGE`; `MAIN_EFFECTIVE_DOCUMENT=V2`. Apenas esta branch contém o adendo, e os PRs de evidência #210, #211 e #212 permanecem históricos Draft. A aprovação do conteúdo pelo responsável não efetua merge nem altera código.

**Somente após merge documental autorizado:** `MAIN_EFFECTIVE_D2_SEMANTICS=D2_R2_V3`; `D2_V2_GLOBAL=SUPERSEDED_BY_OWNER_APPROVED_D2_R2`, preservando a V2 imutável. A integração **não** eleva `C2_GUIDED_R2`, P5, C3, C4, Link Key ou produção. `docs/project/current-state.md` (snapshot de 31/10) tem drift operacional; atualização consolidada deve ocorrer em **escopo documental independente** depois da integração, sem duplicar cronologia.

**Demais estados preservados:** `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. A ordem do Boundary 7 é **C2 guiado R2 → C3 → C4 → GO formal Fase IX → implementar/testar três painéis QlikView 12**.

**Critério de PASS deste gate:** texto V3 limitado a D2, aceite humano explícito rastreado, V2 intacta, arquivo único Markdown, matriz de critérios para futura implementação e riscos nativos declarados. **Não é critério de PASS físico.**

**STOP:** registrar adendo em PR revisável, sem merge, sem QVW/QVD/QVS/PowerShell/COM, alterações de seleção ou recargas. Mudanças no contrato acadêmico, no modelo, na política P5 e nos indicadores permanecem fora deste gate.
