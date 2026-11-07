# SAD MVP — F02: residência 251370 → atendimento 250750 (GUI native, sem Reload/Save)

**Data:** 07/11/2026. **Gate:** `MVP-F02-RES-251370-TRIENIO-GUI-READONLY-01`. **Status:** `PROTOCOL_VERSIONED_NOT_EXECUTED`. **Fronteira:** somente seleção nativa de **um** campo de residência no QVW de inspeção, sem COM, Reload, Save, alteração de scripts/dados, criação de objetos ou merge. Não é aprovação do C3 global, da LINK_ANALISE ou de regras cross-fact.

## 1. Fontes/decisão

- Ordem de leitura na `main`: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md`.
- [P3.3 numérico](../discovery/sad-p33-res-ne-serv-pair-ranking-closeout-2026-10-29.md): par **dirigido** `RES_COD_DATASUS_6=251370 → SERV_COD_DATASUS_6=250750` corresponde a **12.176 novas internações no triênio 2017–2019**; não reexecutar E1/CSV e não inventar qualquer total por residência.
- [V2 §62.6](../discovery/phase-6-semantic-v2-approved-2026-10-14.md): filtro RES para FLU = C; filtro RES para indicadores gerais de leitos = B; não transformar ausência de associação em leitos reais zero. [V3 D2-R2](../discovery/phase-6-semantic-v3-d2-r2-addendum-2026-11-03.md): registrar o estado **efetivo** das seleções nativas, não assumir prevenção global nem ignorar valores incompatíveis.
- [MVP B1 aprovado](mvp-scope-owner-approved-2026-11-07.md): população continua **descritiva município×ano**, sem taxa/denominador; a seleção de residência por tabela municipal não aprova projeções cruzadas com oferta nem tabelas sem avisos.
- [F01](mvp-native-filter-smoke-protocol-2026-11-07.md): 2019 em GUI = PASS restrito de propagação, **não** reaproveitar 2019 neste F02; F02 precisa de **nenhum ano selecionado** para coincidir com P3.3 triênio.
- [Ajuda QlikView September 2026 — seleção em tabelas](https://help.qlik.com/en-US/qlikview/September2025/Subsystems/Client/Content/QV_QlikView/SelectionsOtherObjects.htm): clique em **célula de dimensão** da tabela simples seleciona o valor do campo; não clicar na medida, que pode selecionar a combinação de dimensões.

## 2. Fonte da QVW e escopo operacional

**Somente este arquivo já existente:** `%USERPROFILE%\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_0f6b3b19ce714295ba80e5c27856c08e\SAD_MVP_THREE_SHEETS_CANDIDATE_INSPECAO.qvw`.

Preservar `SAD_MVP_THREE_SHEETS_CANDIDATE.qvw`, `SAD_M1_INTEGRATED_TEMP.qvw`, 22 QVDs/3 QVWs canônicos e todo o trabalho em `main`. **Não editar propriedade, criar filtro/objeto, nem salvar mesmo a cópia de inspeção.** Se o objeto não permitir selecionar o valor com segurança, STOP `F02_INCONCLUSIVE_SELECTION_ROUTE` e registrar isso; não trocar de rota por tentativa.

## 3. Passos executáveis no QlikView 12 pelo responsável

1. Na cópia de inspeção já aberta, `Seleções → Limpar` (soltar explicitamente o 2019 do F01). Manter `Exibir → Seleções Atuais`. Verificar nenhum ano, competência, RES ou SERV selecionado. Se seleção persistir/estiver bloqueada, **STOP**.
2. Ir a **Fluxos e Contexto Territorial**. Na tabela **M3-03 — População municipal por ano**, rolar **dentro da tabela** até encontrar `251370` na **primeira coluna `RES_COD_DATASUS_6`**. Clicar **uma única vez na célula do código**, nunca em célula de `PERIODO_ANO` nem `Sum(POPULACAO_ESTIMADA)`. A posição no scrollbar é secundária; não presumir código por ordinal. A busca nativa por dropdown de dimensão também é possível **somente se já estiver habilitada**, sem alterar propriedades.
3. Verificar em `Seleções Atuais`: **somente `RES_COD_DATASUS_6=251370`**, com **nenhuma seleção em `PERIODO_ANO` ou `SERV_COD_DATASUS_6`**. Se clicar selecionou ano/serviço, ou não consta RES exato, **STOP** e capturar o estado, sem substituí-lo silenciosamente.
4. Na tabela **M3-02 — Pares residência → atendimento**, localizar (rolagem na tabela, sem novas seleções) a linha de **RES 251370 / SERV 250750**; a medida deve ser **12176** para 2017–19. Se não encontrar a linha após rolagem razoável, classificar **INCONCLUSIVE_PAIR_NOT_VISIBLE**, não zero; não induzir outra seleção.
5. Observar: (a) M3-02 não pode exibir outro código RES como se fosse parte do recorte; (b) M3-01 mantém classificação RES=SERV ou RES≠SERV segundo pares elegíveis, sem assumir que as duas barras precisam ser positivas; (c) M3-03 mostra residência `251370` e anos individualizados, não denominador de oferta nem total trianual. As alturas das barras não são prova numérica sem rótulos.
6. Capturar **uma imagem da folha 3** com `Seleções Atuais`, M3-02 (preferencialmente linha 251370→250750) e M3-03 visíveis; **se necessário uma segunda captura apenas rolando M3-02**, sem alterar seleção. Depois `Seleções → Limpar`, não salvar.
7. Enviar imagem(s) ao agente; **não selecionar município SERV adicional nem testar P23** neste gate.

## 4. PASS / BLOCKED / INCONCLUSIVE e STOP

| Controle | PASS restrito | BLOCKED / INCONCLUSIVE |
|---|---|---|
| Seleção real aplicada | `RES_COD_DATASUS_6=251370` **sozinho** em Seleções Atuais | Ano/SERV selecionado por engano = INCONCLUSIVE e STOP; seleção sem RES exato = BLOCKED |
| Par assimétrico SIH/RD | Uma linha **251370→250750** com **12.176 novas internações** | Valor diverso = BLOCKED; linha não visível/rolagem incompleta = INCONCLUSIVE |
| Direção do filtro | Linhas M3-02 exclusivamente RES=251370; SERV pode variar | Outras RES apresentadas como ativas, ou SERV travado silenciosamente em 251370 = investigar/BLOCKED se incompatível |
| POP descritiva | M3-03 mostra somente RES 251370 × anos individuais, sem total trianual | Município/ano de outra residência ativo, total sem sentido, interpretação de POP como oferta = BLOCKED |
| Segurança | Nenhuma gravação, recarga, script, seleção cumulativa ou alteração de modelo | Primeiro desvio crítico → STOP; preservar screenshot |

**Veredito possível:** `MVP_F02=PASS_RESTRICTED_RES_ROLE_GUI`, `BLOCKED` ou `INCONCLUSIVE`. Não atribuir PASS a filtros SERV, leitos, ilha P23, C2/C3/C4/P5 ou produção. O valor 12.176 é de **uma única combinação dirigida no triênio**, **não** total das internações de moradores do município. Se o QVW projetar resultados de oferta sob seleção RES incompatível, assinalar falta de guarda/aviso P5, mas não reinterpretar ausência como capacidade zero.

**Condição de parada:** terminar após um único recorte e captura; nenhuma nova recarga nem iteração de testes automática.
