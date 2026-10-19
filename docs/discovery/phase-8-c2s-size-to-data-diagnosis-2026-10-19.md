# Fase VIII — C2-S: diagnóstico READ-ONLY do encolhimento S0 da Straight Table (19/10/2026)

**Status:** `C2S_ROOT_CAUSE=STRONG_SIZE_TO_DATA_HYPOTHESIS_NOT_CONFIRMED_IN_QVW`; `C2S_REVIEW=READONLY_COMPLETED`; `C2V_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION`; `C2_FULL=NOT_APPROVED`; `PRODUCTION_APPROVED=False`. PR **somente documental/Draft**, sem merge e sem QVD/QVW modificado.

## 1. Objetivo, fontes e condição de parada

**Objetivo único:** investigar por que o `CH01` da **Straight Table** T26 no QVW descartável ocupa aproximadamente 195 px de largura quando a condição de cálculo é verdadeira (S0), mas aproximadamente 760 px quando é falsa (S1–S4); identificar a propriedade nativa mais plausível **antes de outro runner, correção COM ou teste Windows**.

**Fonte canônica verificada:** `main@337943d5c5b77067f842902fc679dbb68db87020`, lida na ordem `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md`; depois `docs/discovery/phase-8-c2v-t26-visual-reflow-2026-10-19.md` e `tools/Invoke-SadPhaseViiiC2vT26VisualReflow.ps1` no PR #118 Draft, baseline documental `f41ed86f51bc74f12f9863dfe20b32ac0d76606c`. Sem tratar PR Draft como estado aprovado da main.

**Fonte empírica inspecionada diretamente:** os cinco PNGs do ZIP `C2V_VISUAL_EVIDENCE.zip`, 1260×731 pixels, hashes SHA-256 checados em bytes e coincidentes com os hashes do runner. `S0_ALLOWED.png` = `2B1FC055F25D589EE1BEE1ACDB2DD2BAB180FC722E5ED227A381FE4A2566AFC2`; `S1_BLOCK_PROCEDURE.png` = `4A36DE0A78A6D4E4A8599CB81EF360136128D0615965BA12F06D1CE8CB9814B1`. Os outros três hashes estão documentados no PR #118. Não foram abertos os binários QVW, QVD ou a folha de propriedades do objeto **no Windows**.

**Documentação oficial QlikView:**
- [QlikView Straight Table — Chart Properties: Layout / Size to Data](https://help.qlik.com/en-US/qlikview/May2024/Subsystems/Client/Content/QV_QlikView/Straight_Table.htm): descreve que, quando habilitada, a configuração `Size to Data` reduz as **bordas do objeto de tabela** em seleções com poucos dados; desmarcar mantém a área configurada com sobra em branco. A mesma página distingue `Fit Columns to Data`, que calcula largura das **colunas**, e o ajuste manual de colunas — propriedades separadas.
- [Straight Table — AJAX/WebView, edição 2026, Options](https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Ajax/WebView_StraightTable.htm): confirma semanticamente `Size Object to Data` como redução automática das bordas em função de dados. Atenção: esta segunda página descreve AJAX/WebView, enquanto as capturas são do QlikView 12 Desktop; a primeira página documenta a interface Windows de Straight Table.

## 2. Diferenciar fatos visuais, fatos de código e hipótese

| Evidência | FATO VERIFICADO / nível | O que NÃO demonstra |
| --- | --- | --- |
| S0 renderizado: tabela de 2018, 31,21; retângulo visível aproximadamente `x=198..392` | Fato observado na captura; cabeçalhos `PERIODO...` e `Internacoes...` truncados | Não revela o valor da checkbox `Size to Data` |
| S1–S4 renderizados: `Condição de cálculo não satisfeita`; frame gráfico aproximadamente `x=198..958` | Fato observado em PNGs: mesmo objeto `CH01`, frame visual grande nas mensagens de bloqueio | Não comprova uma alteração do frame persistido pelo COM entre cenários |
| Runner C2-V: `CreateStraightTable()`, `AddDimension('PERIODO_ANO')`, `AddExpression(...)`, `SetProperties`, `SetFrame(frame,true,'')`; readback `TARGET_PIXELS=235,116,950,320`, `QLIK_RECT=588,290,2375,800` | Fato do código versionado e do stdout Windows reportado | Readback COM **não** é tamanho renderizado em pixels |
| Runner C2-V **não contém configuração explícita de `Size to Data` / `Size Object to Data`** | Fato de inspeção estática dos comandos do runner | Não prova se a propriedade está habilitada por padrão, herdada de tema ou alterada manualmente |
| Documentação oficial descreve contração de Straight Table com pouco conteúdo quando `Size to Data` ativa | Fato documental sobre comportamento do produto | Não é inspeção direta da checkbox em `CH01` |

**HIPÓTESE TÉCNICA PRINCIPAL (não homologada):** `Size to Data` está ativa no `CH01`. No cenário S0 a tabela retorna uma única linha e duas colunas estreitas, e QlikView reduz o frame à largura do conteúdo. Nos estados S1–S4, a mensagem de cálculo indisponível mantém o frame maior. Esta hipótese é **causalmente consistente** com screenshots + documentação e mais específica que a suposição anterior de falha genérica do `SetFrame`; **não foi confirmada na interface QlikView 12 local**.

**ISSUE VISUAL INDEPENDENTE:** mesmo se `Size to Data` for desligada, os cabeçalhos das duas colunas (`PERIODO_ANO` e expressão T26) poderão continuar estreitos. Ajustar `Fit Columns to Data` ou larguras específicas é uma **segunda intervenção**, condicionada a prova de que o primeiro bloqueio foi resolvido. As listboxes `SERV_COD_DA...` e `COD_PROCEDI...` também têm cabeçalhos encurtados e requerem ajuste separado; não confundir com causa da contração de `CH01`.

## 3. Próximo diagnóstico mínimo, SEM runner novo

**Proposta restrita — confirmação da checkbox por GUI, ainda NÃO EXECUTADA:**
1. **Não abrir para gravação o QVW evidencial** do gate C2-V. No Explorador de Arquivos, copiar `%TEMP%\SAD_VIII_C2V_83cc8d984d9e438eb76a71d1ff8f6d0f\SAD_C2V_T26_DISPOSABLE.qvw` para novo nome sob outra pasta TEMP, sem sobrescrever QVW existente. Se a pasta TEMP original não existir, **STOP**; não reconstruir nem recarregar dados para este diagnóstico.
2. Abrir **somente a cópia** no QlikView 12 Desktop, com ano 2018 e serviço João Pessoa `250750`. No gráfico `CH01`, botão direito → **Properties/Propriedades → Layout → Options → Size to Data** (a localização pode variar com o idioma); registrar o valor atual por screenshot **antes de alterar qualquer coisa**.
3. **Se marcada**, desmarcar apenas `Size to Data` na cópia em memória e verificar visualmente se o gráfico continua com frame largo enquanto exibe a linha 2018/31,21. Registrar um segundo screenshot do cenário permitido, com o gráfico inteiro; não mexer ainda nos filtros P5, não editar colunas, não salvar QVW evidencial. Fechar a cópia **sem salvar**.
4. **Se não marcada**, registrar screenshot da propriedade e **STOP**: a hipótese não explica diretamente o comportamento atual; investigar outra opção sem presumir causa. Não criar patches em cascata.
5. **Conclusão admissível:** `C2S_SIZE_TO_DATA=CONFIRMED_ON_DISPOSABLE_COPY` somente se estado originalmente marcado e alteração isolada eliminar o encolhimento visual. Caso contrário, `NOT_CONFIRMED` ou `INCONCLUSIVE`. A confirmação GUI é `EXPERIMENTAL_NOT_GATE_EVIDENCE` até gerar prova versionada/validada da eventual configuração permanente num novo QVW temporário.

**Critério de parada da presente Discovery READ-ONLY:** inferência tecnicamente rastreável, documentação oficial citada e **um único diagnóstico proposto**, sem alterar script da branch #118, sem abrir QVD/QVW original, sem executar Windows QlikView e sem aprovar interface. Não propor iterativamente R3/R4 de layout sem evidência da checkbox.

## 4. Decisão pendente após o diagnóstico

Somente se a checkbox estiver **confirmadamente marcada**, definir o menor gate subsequente: **configurar `Size to Data=False` em QVW temporário** via COM **apenas depois de obter o nome de propriedade real por inspeção segura** ou via GUI manual com prova explícita, e conferir uma captura do S0 + uma de S1. Não inventar nomes como `p.Layout.SizeToData`, `p.SizeToData` sem introspecção do objeto real no QlikView 12. Se o modo COM não permitir atribuição, registrar limitação em vez de forçar.

**Demais gates inalterados:** `C2V_COM_GEOMETRY_LABEL_FORMAT_AND_CAPTURE=PASS_LOCAL_CANDIDATE_ONLY`; `C2V_VISUAL_ACCEPTANCE=BLOCKED_PRESENTATION`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `T26_GENERAL=NOT_APPROVED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. PR Draft, `main` não alterada.