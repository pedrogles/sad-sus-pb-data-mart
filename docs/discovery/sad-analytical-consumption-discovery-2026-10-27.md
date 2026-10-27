# SAD — Gate proposto: CONSUMPTION-ARCH-DISCOVERY-01 (READ-ONLY)

**Identificador:** SAD-ANALYTICAL-CONSUMPTION-DISCOVERY-01
**Estado:** PREPARADO_NAO_EXECUTADO; **a autorização de documentar e preparar não autoriza uma implementação**. 
**Baseline da preparação:** main@db5d6e6e23371422ca1d2d77a8576150aaf63d03 em 27/10/2026. A branch Draft precisa ser inspecionada novamente no novo chat; somente a main integrada governa o projeto.
**Agente/ambiente recomendado:** ChatGPT + GitHub READ-ONLY (esforço Medium quando disponível). Para muitos arquivos, Work Cloud apenas se o acesso contribuir; para COM/QlikView seria Codex Local Windows **somente em gate próprio autorizado**. Escalar para High apenas se houver contradição semântica real que demande raciocínio especializado; não é requisito prévio.

## 1. Pergunta de decisão delimitada

**Qual a menor camada de consumo para sustentar os três painéis descritivos sem mudar a constelação acadêmica, sem duplicar medidas ou mascarar contratos de integração ainda pendentes?**

Comparar exclusivamente A0 (consumo atual de fatos/dimensões com roteamento de filtros por processo) e A1 (projeções/agrupamentos de consumo **candidatos**, sem materialização) usando as 12 perguntas do inventário e os extratos AE01. A2 (remodelagem) só pode ser recomendada se a evidência demonstrar necessidade estrutural, com DECISAO_PENDENTE distinta; não implementar nem aprovar.

## 2. Permissões e invariantes

**PERMITIDO:** leitura dos arquivos/PRs/issues canônicos; inspeção textual QVS, schemas e logs já existentes; comparação lógica de dependências; escrita de um parecer/contrato documental para revisão somente se escopo documental explicitamente autorizado. Análise nova de CSVs anexados pode ser exploratória READ-ONLY, qualificada como EXPERIMENTAL_NOT_GATE_EVIDENCE; não repetir provas fechadas por curiosidade.

**PROIBIDO:** executar QlikView 12/COM/GUI, scripts de produção, reload/STORE, modificar ou salvar QVD/QVW, fundir fatos, mexer em dimensões/grãos/Link Key, reabrir Capítulos 1–2, alterar V2/RN21, baixar bases externas, implementar painéis, criar PR de código, fazer merge, editar dados ou declarar Fase IX/produção. Não criar perfis clínicos ou inferências causais.

**Permanecem:** 3 fatos, 8 dimensões, 22 QVDs e 3 QVWs preservados, tempo mensal/ano sem somas indevidas, RES vs SERV, IDENT=5 não internação, cobertura LT, T29 histórico limitado, contrato P5/D2 e ordem Boundary 7.

## 3. Entradas em ordem

1. main atual: AGENTS.md → docs/project/current-state.md → docs/academic/requirements.md → docs/project/agent-model-routing.md; registrar SHA.
2. [Decisão de racionalização](../project/analytical-source-and-architecture-decision-2026-10-27.md), [matriz de fontes](sad-analytical-consumption-source-matrix-2026-10-27.md), [inventário 12 perguntas](analytical-question-inventory-2026-10-27.md), [plano de suficiência](analytical-sufficiency-plan-2026-10-27.md) e direcionamento de 27/10; conferir main versus PR Draft.
3. [Modelo acadêmico](../academic/chapter-1-2-modeling.md), [Boundary 5](boundary-5-historization-role-playing.md), [Boundary 6](boundary-6-qlikview-physical-architecture.md), [Boundary 7](boundary-7-implementation-plan.md), [V2 §62](phase-6-semantic-v2-approved-2026-10-14.md).
4. Scripts QVS **já versionados** de staging, transformação, dimensões, fatos, LINK_ANALISE e painel; observar campos reais em vez de projetar staging na fato.
5. PR #160 (AE01 Draft), Issue #161 (PASS restrito e limites), Issue #157 (T25/T26/cobertura aberta), evidências F5/C3/C4. Manifesto AE01 SHA-256 0B1AA7DA6EF10A08B0F698250F199666525672DC763D6774CA4498B2A3C488D2.
6. Quatro CSVs AE01 anexados da tentativa 02 ou seus hashes/manifesto; sem novos downloads. Se indisponíveis, limitar-se às provas existentes, marcando NOT_REOPENED.

## 4. Procedimento de Discovery (um ciclo, sem expansão)

**A. Conferência de proveniência:** comparar estado atual main/PR/issues, status do AE01, 9 perguntas respondidas diretamente, I06/I07 históricas e I12 condicionado; identificar drift documental sem reclassificar a produção.

**B. Matriz fonte→pergunta→visual:** para I01–I12 classificar: fonte quantitativa obrigatória, referência de significado opcional/necessária, fato e campo físico confirmado (staging, SK ou %LINK_KEY), grão, medida aditiva/semia, papel RES/SERV, domínio do filtro, cobertura e nível de prova. Usar matriz proposta como rascunho, corrigir apenas com evidência.

**C. Mapear os 3 painéis (3–5 visuais cada):** por objeto, declarar fato única ou múltiplas, grão, expressão conceitual sem pseudocódigo homologado, filtro e incompatibilidades, data/ano, rótulos/códigos, fallback sem linha versus zero e texto de aviso científico. Classificar SUSTENTADA_DESCRITIVA / CONDICIONADA / NAO_SUSTENTADA.

**D. Comparar A0 versus A1:** para cada visual, testar documentalmente duplicação de fatos, grão, linhagem, associatividade e possibilidade de manter contrato acadêmico. Informar custo e riscos; exigir prova de ganho claro para A1. Não propor nova dimensão/fato/Link Key como concluída.

**E. Decisão e STOP:** entregar proposta de arquitetura de consumo mínima, dependências por fonte e até três blockers materiais. Se evidência insuficiente, registrar EXACT_MISSING_EVIDENCE e STOP; não inaugurar R2/R3 de testes.

## 5. Entregáveis e critérios de aceite

1. **Matriz 12×** com I01–I12, origem física real, fonte mandatória/facultativa, grão, medidas, filtros, joins e status de prova; toda coluna física citada localizada em QVS/QVD ou marcada NAO_VERIFICADA.
2. **Três especificações de painel** de 3–5 visuais cada, com guardas de tempo/RES/SERV/ausência e classificação; nenhuma tela implementada.
3. **Comparativo A0 × A1**, decisão recomendada **não vinculante** com evidência de custo/benefício e risco de duplicação; A2 somente hipótese fundamentada.
4. **Lista de até três bloqueios** que dependam de novos contratos/fontes/aceites, diferenciando a trilha analítica independente e G1–G7 da finalização acadêmica.
5. **Handoff** solicitando autorização formal para o próximo gate **específico** (enriquecimento, integração, ou implementação, conforme o resultado). Não confundir aceite do relatório com autorização de Qlik.

**Veredito:** DISCOVERY_DOCUMENTED_READONLY se todos os cinco entregáveis forem produzidos com proveniência; BLOCKED_MISSING_EVIDENCE se faltar uma confirmação material; ESCALATE_ARCH_DECISION somente com conflito real demonstrado. **Jamais** usar PASS_QV / PROD_APPROVED.

## 6. Condição de parada

Encerrar ao entregar os cinco itens. Não modificar arquivos físicos, fechar #157/#161, fazer merge #160, nem iniciar novo gate por decorrência. A nova etapa começa somente em novo chat mediante comando do responsável.