# SAD — Revisão visual e metodológica restrita de P1.1/P1.2

**Gate:** `SAD-P11-P12-VISUAL-METHOD-REVIEW-01`  
**Data:** 29/10/2026  
**Base de código:** `main@9070806f26a1568948b0ce2b87c597beb7ec2d9e`  
**Modalidade:** revisão READ-ONLY de capturas, exportação e documentação; PR documental Draft em branch própria. **Sem abrir/salvar QVW, COM, reload, STORE, scripts, QVD, merge ou ajustes na folha experimental.**  
**Agente:** ChatGPT GPT-6, GitHub e inspeção de arquivos da conversa; esforço real da sessão não exposto; QlikView Windows local não acessível.  
**Autorização:** responsável respondeu 'prossiga' após recomendação de revisão visual e metodológica P1.1/P1.2; não autorizou merge, produção nem nova intervenção física no QlikView.

## 1. Objetivo, fontes e critério de parada

Objetivo único: avaliar **a apresentação da folha experimental já existente** e especificar ações mínimas de clareza, legibilidade e comunicação semântica, **sem recalcular medidas** nem reabrir contratos globais C2/P5/Link Key.

Fontes verificadas: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` na `main`; contrato [P1.1/P1.2 UX](sad-p1-p11-p12-ux-contract-2026-10-28.md) integrado na `main`; protocolos e evidências dos PRs #172, #173, #174, #175, capturas de tela e exportação do QlikView enviadas pelo operador. O estado de `current-state.md` ainda contém snapshot antigo de P2.3; para este recorte prevalecem os PRs/evidências posteriores **como fatos de branch, não como merge na main**.

Critério de parada: registrar os achados observáveis, a distinção fato/hipótese/pendência e uma sequência **única** de correções candidatas com aceite objetivo. Não continuar com implementação física, C2, P5, Fase IX, mudanças de modelo, novo cálculo ou novos gates espontâneos.

## 2. Evidência e escopo efetivamente observado

| Evidência | Material e limite |
| --- | --- |
| Estado inicial | `image(20261029-022401).png` (SHA-256 `29471257DE0412FFCC0349D932DFF1D1E96B501C8E28BCF637C7C176B5BF56A0`): janela Seleções Atuais vazia, 4 KPIs corretos e gráfico originalmente sem dados. |
| Expressão do CH02 | `image(20261029-022507).png` (SHA-256 `C80A2BD2A62C22101AED8EBE0DBF5A2EA816236BB54840B15547BB92EE9FAB97`): editor reporta Expressão OK para `=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)`. Não prova isoladamente o comportamento sob seleções futuras. |
| Propriedades de apresentação | `image(20261029-022537).png` (SHA-256 `7C85E7DFFDA4FBA22E3E9AEC9DEF044CEF488A17B43969B05196AA6D820D3257`): `Ocultar Zeros` e `Ocultar Faltantes` visivelmente marcados e `Rótulos Pop-up` marcado. Não há captura de tooltip funcional. |
| Folha renderizada | `image(20261029-022622).png` (SHA-256 `3EAA97CF84D99804EF474F9F5DE2756BEE8E570712B6C14AB2CBC2B4A32604C8`): quatro cartões, linha de 201701 a 201912, todos os rótulos do eixo X exibidos de forma apertada e número isolado `555089` sobre a curva. **A origem do número isolado não foi inspecionada nas propriedades.** |
| Exportação P1.2 | `P12_CORRECTIVE_36_MESES.tsv.txt.txt` (SHA-256 `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F`): 36 pares competência×contagem, 201701..201912. Confronto por competência anterior: 36/36 valores iguais ao E1 agregado, zero divergências, total 555.089, máximo 201905=17.292 e mínimo 201702=13.586. |
| Closeout de integridade | [PR #175](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/175), stdout do auditor versionado `5de5ac4c84396728ed09f46b0b00f2fba5cefe21`: 10/10 fixtures sintéticos PASS, 25/25 protegidos sem divergência de conteúdo; fonte intacta e cópia salva alterada (SHA-256 `8E2096D42602D7B84239AE30498EE45FA3ED6B060B9EEC6A4C003B0B3A2B7DE4`). PASS de integridade **atual**, não de UX nem retroativo aos HARD_STOP dos PRs antigos. |

Todas as capturas/exportações permanecem **fora do Git**. Seus nomes e SHA-256 apenas permitem identificar as evidências enviadas; não se presume que os bytes estejam anexados ao PR.

## 3. Parecer visual — fatos, hipóteses e ações candidatas

| Prioridade | Fato visível / lacuna observada | Correção candidata em cópia QVW (ainda NÃO executada) | Prova de aceite futuro |
| --- | --- | --- | --- |
| P0 | Eixo X exibe 36 rótulos AAAAMM em dois níveis, com leitura densa. Linha 36/36 já comprovada pelo export. | Reduzir **apenas a quantidade de rótulos mostrados**, por exemplo um rótulo a cada 3 meses (jan/abr/jul/out) ou, se a ferramenta não oferecer essa separação sem suprimir pontos, adotar solução nativa demonstrada. Não reduzir dimensões, pontos nem somas. | Captura com marcações legíveis + export pós-ajuste contendo **36/36** valores idênticos aos já reconciliados; se recurso não disponível, registrar INCONCLUSIVE, sem improvisar dimensão nova. |
| P0 | Número solto `555089` aparece acima da curva e reproduz total já apresentado no cartão do triênio; origem da anotação não visível. | Inspecionar propriedades de expressão/título/rótulo do CH02 **antes de qualquer remoção**; se for rótulo decorativo/redundante, ocultá-lo. Não alterar medida, total, card ou fonte. | Número isolado ausente na nova captura, quatro KPIs/36 pontos intactos e título compreensível. Se a origem não for identificada, STOP nessa alteração específica. |
| P0 | Não se vê aviso metodológico na folha renderizada. | Incluir texto persistente e legível: **'Internações novas contabilizadas por competência administrativa SIH/RD; continuidades (IDENT=5) excluídas. Não representam pacientes únicos nem demanda reprimida.'**; não chamar métrica de pacientes únicos, internações clínicas por DT_INTER ou ocupação. | Aviso visível sem hover; captura verificável, em contexto fixo histórico 2017–2019. |
| P1 | Os quatro cartões apresentam muito espaço vazio, números relativamente pequenos e nomenclatura anual não homogênea (2017 primeiro, 2018/2019 em ordem invertida). | Uniformizar títulos como **'Internações novas — 2017/2018/2019'** e **'Total do triênio — 2017 a 2019'**, realçar valores e explicitar unidade 'internações novas (SIH/RD)'. Manter último cartão separado de KPI anual. | Captura legível sem truncamento; valores **183.532 / 183.311 / 188.246 / 555.089** inalterados, sem seleção temporal ativa. |
| P1 | Título temporal do gráfico já identifica 2017–2019, mas rótulo do eixo é `PERIODO_COMPETENCIA` (nome físico). | Exibir rótulo voltado ao usuário como **'Mês de competência (SIH/RD)'** e eixo Y **'Internações novas (quantidade)'**, sem alterar o campo da dimensão. | Captura com linguagem de negócio; valores por competência preservados. |
| P2 | Popup está habilitado em propriedades, mas a captura não mostra conteúdo efetivo; folha final não mostra painel de seleções ativas. | Em futuro gate físico próprio, conferir tooltip com mês/ano, competência AAAAMM e contagem exata, e estado de seleções aplicado. **Não presumir aprovação de qualquer filtro global.** | Evidência real do popup de ao menos meses de controle e estado neutro; verificações pontuais não homologam todas as interações. |

**Nota sobre a escala:** o eixo vertical parte de zero na captura; nenhuma mudança de escala é necessária para que a linha esteja numericamente correta. Não escolher escala recortada apenas para ampliar visualmente oscilações. A classificação por texto AAAAMM de largura fixa permanece compatível com ordem cronológica, comprovada pela exportação ordenada.

## 4. Contrato temporal e semântico — limites da revisão

- A folha experimental **histórica completa** mostra 36 competências 2017–2019. Ela **não é** o modo global C2 `EVOLUCAO`, que prevê 12 competências do ano aplicado. Não mudar a navegação C2 nem acoplar os quatro cartões ao fluxo ANUAL/MENSAL/EVOLUCAO sem contrato e teste próprios.
- A expressão física corrigida substitui o filtro de ano do set, porém usa o estado `$` para as demais seleções; sua segurança sob seleção externa contraditória/municípios/bookmarks **não foi demonstrada**. Não publicar como visão global imune a filtros; não presumir LINK_KEY aprovado.
- `PERIODO_COMPETENCIA` é competência **administrativa** dos registros SIH/RD e não data clínica de admissão (`DT_INTER`). `QTD_INTERNACAO` exclui continuidades (`IDENT=5`). A série não mede pacientes únicos, demanda reprimida nem ocupação.
- A prova da janela Seleções Atuais vazia foi feita na captura inicial; a captura final mostra apenas a folha, de modo que a invariância de ausência de seleção **na captura final isoladamente não é revalidada**.
- O aviso persistente não deve ser substituído por legenda/tooltip. Valores sem dado ou filtros contraditórios não devem ser transformados em zeros artificiais.

## 5. Classificação de saída e STOP

| Dimensão | Estado delimitado |
| --- | --- |
| P1.1 valores candidatos | `PASS_SCREENSHOT_VALUE_MATCH_RESTRICTED` (4/4), não aprovação de resposta a filtros. |
| P1.2 série mensal | `PASS_EXPORT_36_OF_36_E1_RECONCILED_RESTRICTED`; a renderização da linha está demonstrada na captura. |
| Integridade física da cópia | `PASS_LOCAL_READONLY_HASH_CLOSEOUT_RESTRICTED` no #175; não validar retroativamente os runners bloqueados. |
| Apresentação/legibilidade | `REVIEWED_GAPS_IDENTIFIED_NOT_VISUAL_ACCEPTED`. |
| Alterações ao QVW | `NOT_PERFORMED` — não há novo commit de QVW, QVD, QVS ou script. |
| Aprovação global | `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`. |

**Condição de parada cumprida:** revisão com lista fechada de correções candidatas e critérios de aceite, sem repetir auditorias, série mensal ou A0 R1. **Próximo trabalho possível, não automaticamente autorizado:** uma intervenção **apenas de apresentação** na cópia descartável corrigida, separada e versionada no protocolo, com captura e prova de 36/36 antes/depois; autorização específica antes de abrir/editar/salvar a cópia Windows. A integração documental e fechamento administrativo dos Draft #172–#175 são decisões independentes; não fazer merge por decorrência deste parecer.
