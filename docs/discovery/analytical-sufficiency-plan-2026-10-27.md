# SAD SUS PB — Plano de suficiência analítica e extratos (27/10/2026)

**Meta:** `SAD-ANALYTICAL-SUFFICIENCY-01`. **Primeiro gate:** `EXTRATOS-ANALITICOS-READONLY-01`.
**Estado deste plano em 27/10 (histórico):** PLAN_APPROVED_DIRECTION_CHAT / EXECUTION_NOT_RUN. O marcador `EXECUTION_NOT_RUN` referia-se **a esta preparação**, não ao estado atual dos gates P1–P3. A integração documental não concede permissão para alterar dados ou executar QlikView.
**Proveniência:** `main@9f4fc0ea43dfe8b6f20f7b6254bc7f965f6a9c04`; revalidar branch/PR/main ao executar.
**Escopo:** 2017–2019; `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`, dimensões e exportações/manifestos já existentes.

**Handoff vigente em 29/10:** as evidências AE01/A0/P1–P3 já disponíveis devem ser **reutilizadas**, não reextraídas. A revisão seguinte é incremental e limitada aos **14 visuais D1–D3**, segundo [current-state](../project/current-state.md) e [auditoria de drifts](sad-operational-documentation-drift-audit-2026-10-29.md). Decisão A0 padrão/A1 condicional P2.3 já documentada; nenhuma reexecução física autorizada.

## 1. Pergunta operacional única

**Os dados reais já disponíveis sustentam, com regras e números rastreáveis, as 12 perguntas do inventário e as visualizações dos três painéis candidatos?**

A análise permite ajustar as **propostas analíticas**, não alterar modelos acadêmicos/contratos semânticos nem construir dashboards finais.

## 2. Pré-condições

1. Ler `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → `docs/project/agent-model-routing.md` → estratégia, inventário e este plano; confirmar `main@SHA` e estado do PR que os propôs.
2. Verificar quais QVDs, extratos F1/F2/F3/VI-P4, manifestos, QVS e logs **estão de fato acessíveis**; não assumir acesso ao Windows local em ChatGPT/Work Cloud.
3. Conferir schemas e grãos com os QVS de origem e os arquivos existentes. **Não pressupor** que `PROC_REA`, `DIAG_PRINC`, RES, SERV ou `CODUFMUN` sejam colunas físicas diretas das fatos: SIH utiliza SKs e `%LINK_KEY`, e a localização de LT também participa da Link Key. Para agregações independentes, preferir `SRC_SIH_RD.qvd` / `SRC_CNES_LT.qvd` ou extratos F1/VI-P4 já autorizados, com regras de medição compatíveis e reconciliação contra os totais das fatos; não declarar homologação global de associações. Em ausência do dado físico, classificar `CALCULAVEL_SEM_DADO_NOVO` e especificar extrato mínimo; **não inventar ranking**.
4. Proteger os 22 QVDs reportados e três QVWs canônicos. Não abrir/editar/salvar QVW canônico, fazer reload, STORE, baixar dados em massa ou rodar COM neste primeiro gate.

## 3. Sequência delimitada de leitura e extração

- **A — Disponibilidade:** inventário READ-ONLY de artefatos físicos fornecidos, proveniência, commit de script, hashes originais/manifestos e cobertura já demonstrada; aproveitar as evidências F5/C3/C4, sem novos testes repetitivos.
- **B — SIH/RD:** conferir os agregados I01/I06/I07; se os dados forem acessíveis, extrair I02 por competência, I03 por município SERV, I04 por `PROC_REA`, I05 por `DIAG_PRINC`, I08 por R=S/R≠S e I09 por par RES/SERV e origem externa **do staging ou extratos já reconciliados**. Quando usar `FATO_INTERNACAO.qvd`, mapear SKs/`%LINK_KEY` por contratos explicitamente verificados; não atribuir nomes de campos de origem à fato. Emitir tanto `QTD_REGISTRO_AIH` quanto `QTD_INTERNACAO` quando relevante para impedir inclusão de continuidade.
- **C — CNES/LT:** reutilizar C4-F para I10; em staging `SRC_CNES_LT.qvd` ou extratos READ-ONLY, agrupar I11 por mês×município×CNES×código. No QVD da fato, usar somente os campos físicos existentes e a associação municipal conforme evidência, não criar `CODUFMUN` por inferência; manter medidas observadas, contagens de linhas, ausência/zero/positivo diferenciados. Não fazer soma de snapshots como leito anual; não aplicar descrições T29 sem validade histórica.
- **D — IBGE/T24:** conferir os 669 pares e POP anual sem somar anos; tratar I12 como condicionado a V2/contrato e não criar novo KPI global sem autorização.
- **E — Reconciliação e decisão:** conferir soma/grão/sinais e compatibilidade de filtros do recorte, confrontar oráculo independente, registrar divergências, confiança, universo e impossibilidades. Julgar **cada visualização** como `SUSTENTADA`, `CONDICIONADA` ou `NAO_SUSTENTADA`.

**Regra de execução:** Python/PowerShell/QVS usado para sustentar gate precisa estar **commitado previamente em branch** com commit de origem e SHA do script. Scripts já existentes devem ser reutilizados; ferramentas experimentais sem versionamento não constituem PASS. Para eventual leitura física que necessite script novo, preparar commit e autorização de execução separada antes do Windows. Este plano por si **não autoriza** essa execução física.

## 4. Matriz de entrega por pergunta

Cada linha deve ter: ID, pergunta, fato(s), grão, universo de atendimento/localização, filtros RES/SERV/tempo, nomes de medidas realmente verificados, regra de agregação, numerador/denominador quando aplicável, **valor real ou “não extraído”**, fonte/arquivo/commit/hash, nível de prova (`FATO_VERIFICADO`, `RELATO_LOCAL`, `HIPOTESE`, `DECISAO_PENDENTE`), estado de suficiência, ressalva e visual proposto.

Não reinterpretar `QTD_INTERNACAO` como pessoas, `INDICADOR_OBITO` como taxa de mortalidade ou `VALOR_TOTAL` como custo econômico. Não declarar relação causal. Sem cobertura necessária, o valor pode ser **indisponível** mesmo quando existe expressão de cálculo.

## 5. Critérios, limites e STOP

- `DOCUMENTED_READONLY`: dados não acessíveis, mas matriz completa indicando **precisamente** os extratos ainda necessários; nenhuma execução externa inventada.
- `ANALYTICAL_EVIDENCE_RECONCILED_RESTRICTED`: agregados efetivamente acessíveis e auditados em recortes definidos, com fontes, regras, totais, avisos e classificação de cada visual; **não** equivale a Qlik aprovado.
- `BLOCKED_INPUT`: QVD/extratos ausentes, esquema inesperado ou hash divergente. Registrar apenas bloqueio/requisito mínimo; nenhuma correção mutante.
- `HARD_STOP`: qualquer tentativa de sobrescrever QVD/QVW, alterar V2/RN21/Capítulos 1–2 sem decisão, fabricar campo ou usar dados sem procedência.
- **STOP:** fechar **uma matriz das 12 perguntas**, uma lista de 3×(3–5) visuais revisados e **até três** lacunas que bloqueiam valor. Não iniciar mais do que um gate de exportação; não expandir pesquisa normativa.
- Fase IX, T25/T26 científicos, Link Key/medidas globais, UX D2/P5 e `PRODUCTION_APPROVED` permanecem em fluxo independente [G1–G7](../project/final-delivery-critical-path.md), com #157 aberto até decisão própria.

## 6. Handoff

Entregar um relatório de suficiência com links/hashes e os três painéis **especificados, não implementados**; depois submeter ao responsável escolha do escopo final antes de planejar a implementação QlikView. Se faltarem QVDs/extratos, definir um único subgate local para exportação somente leitura, com critérios e autorização específica; não executar COM apenas por ter este plano.
