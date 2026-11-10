# SAD — VIS-03 | Auditoria documental e verificação GUI pendente (10/11/2026)

**Gate:** VIS-03 — verificação visual, persistência e integridade restrita do MVP acadêmico QlikView 12.
**Modalidade desta execução:** leitura de GitHub e reaproveitamento de evidências anteriores; **sem acesso ao QlikView Desktop/Windows do operador, à QVW binária ou aos PNGs originais neste ambiente**. Nenhum script executado, QVW/QVD/QVS modificado, Reload, Save, COM ou merge.

## 1. Fonte, baseline, autoridade

Lida em ordem na `main`: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`. HEAD da `main` consultado: `0549e1dba71aaa8bbab9d6755aecb8465f8bea83`. O `current-state.md` é um snapshot operacional de 03/11/2026; não foi reescrito nesta execução.

Documentação específica consultada:
- [PR #231 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/231): `docs/project/sad-vis-02-closeout-local-restricted-2026-11-10.md`, runbook e preflight versionado.
- [PR #230 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/230): plano acadêmico, VIS-01 e aprovação visual do responsável.
- [PR #226 Draft](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226): implementação e consolidação de evidências das nove visualizações, incluindo F01–F05, C3 restrito, C4/CH06/CH09 e os avisos já demonstrados.

As PRs Draft não alteram automaticamente a `main`. A `main` mantém blueprint formal de 14 visuais, contratos globais C2/C3/C4 pendentes e Fase IX não autorizada. O MVP acadêmico B1 de **3 folhas × 3 objetos** permanece escopo experimental.

## 2. Artefatos de referência sem acesso direto aos bytes

- Original protegido: `SAD_MVP_C4_PRESENTATION_TEMP.qvw`; SHA-256 originalmente reportado e novamente reportado pelo operador após VIS-02: `27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13`.
- Trabalho refinado VIS-02: `SAD_MVP_C4_VIS02_WORK.qvw`; SHA-256 reportado após Save: `C564C7020D4F7377A541427B197E38726C47370385C14FE6446E7BA098158619`.
- Caminhos Windows e manifesto preflight: registrados no closeout #231, sem duplicação desnecessária aqui.
- Capturas VIS-02 após salvar/reabrir, descritas no closeout #231: `image(20261110-143005).png` (folha 1), `image(20261110-143012).png` (folha 2), `image(20261110-143019).png` (folha 3). **Os PNGs não foram recuperados para inspeção visual independente nesta sessão.**
- `SAD_A4_Relatorio_Consolidado_R2_Editorial.pdf` (98 páginas), fallback acadêmico; não alterado.

`PASS_HASH_LOCAL_REPORTED` é a classificação da conferência Windows do operador, não um novo hash recalculado neste ambiente. A avaliação de persistência das três imagens é **evidência reaproveitada VIS-02**, não um teste VIS-03 adicional.

## 3. Matriz por folha: provas reaproveitadas e pendências

| Folha / objetos | Evidência anterior reutilizável | VIS-03 ainda inconclusiva |
|---|---|---|
| **Produção Hospitalar** M1-01/M1-02/M1-03 | 3 objetos visíveis pós-reabertura; barras anuais, linha mensal, ranking SERV horizontal, scroll e ordenação Valor-Y decrescente (exceção explicitamente autorizada), fundo/cores/títulos documentados | Rótulos de 36 competências em compartilhamento; leitura da escala/título; rolagem interativa efetiva do ranking |
| **Leitos Cadastrais Observados** M2-01/M2-02/M2-03 | 3 objetos pós-reabertura; 2 séries de snapshots com legendas, ranking horizontal fixo `201912`, 3 categorias qualitativas da ilha P23 âmbar/teal/cinza; título CH06 explicita panorama PB 2017–19 sem filtros globais | Densidade dos rótulos M2-01, nomes técnicos extensos das categorias M2-03, rolagem interativa M2-02, avisos da cópia VIS-02 |
| **Fluxos e Contexto Territorial** M3-01/M3-02/M3-03 | 3 objetos pós-reabertura; RES=SERV vs RES≠SERV, tabela RES→SERV, tabela POP município×ano sem total trianual visível | Legibilidade de códigos/cabeçalhos durante compartilhamento; aviso CH09 na cópia VIS-02 |
| **Integridade arquivo** | Origem preservada e hash da cópia reportados no closeout VIS-02 | Nenhuma auditoria independente dos bytes QVW/propriedades; não equivaler hash do arquivo a semântica |
| **Layout em resolução de apresentação** | PASS VIS-02 no viewport das imagens previamente analisadas | Resolução, escala e visibilidade no compartilhamento online **não documentadas** |
| **Ausência de regressão semântica interna** | CH05/CH06/CH09 e avisos possuem evidência C4/F03 anteriores no #226; VIS-02 aplicou mudança visual sem declaração de alteração de expressões | Não há readback novo de dimensões, associações, filtros ou guardas internos; `NOT_TESTED` nesta VIS-03 |

Classificações dos resultados herdados: `PASS_GUI_VISUAL_RESTRICTED` e `PASS_HASH_LOCAL_REPORTED`, **com a origem VIS-02/PR #231 explicitada**. Para novos critérios ainda não observados: `INCONCLUSIVE` ou `NOT_TESTED`, não PASS.

Números analíticos preexistentes, **não recalculados nesta VIS-03**: M2-03 4.467 células sem linha LT, 3.464 observadas positivas e 97 observadas com zero (células município×competência, não municípios); M3-01 RES=SERV 294.635 e RES≠SERV 260.454, total 555.089. Não apresentá-los como ensaios novos.

## 4. Menor verificação realmente necessária — sessão GUI única, sem reconstrução

**Pré-condição:** operador abre somente `SAD_MVP_C4_VIS02_WORK.qvw` na estação Windows com QlikView Desktop 12, sem Reload ou Save, preferencialmente a partir de cópia/estado já salvo. Se houver prompt inesperado de recuperação ou documento original aberto para edição, STOP.

1. **Compartilhamento real:** usar a resolução/escala efetiva da apresentação online (registrar pixels da área exibida e zoom/escala). Navegar uma vez pelas **3 folhas**, sem seleção, e registrar capturas somente quando necessárias para provar que os 9 objetos e cabeçalhos/eixos são legíveis ao público, sem overlap ou cortes relevantes. Não repetir prints só por terem outra data; esta prova cobre especificamente a resolução de transmissão, que não consta das capturas VIS-02.
2. **Rankings:** em M1-03 e M2-02, confirmar que a rolagem permite ler itens fora do primeiro viewport e que não há inversão inadvertida de ordenação em M1-03. Uma captura ou registro curto da porção rolada por ranking basta; não fazer auditoria numérica de todos os municípios nem criar Top N.
3. **Avisos de indisponibilidade da cópia refinada:** se o item permanecer inconclusivo após inspeção dos registros existentes, executar somente o cenário único `PERIODO_COMPETENCIA=201801` nativo (estado inicial neutro), verificando visualmente na mesma sessão o aviso contextual de M2-02/CH05, o aviso mensal de M3-03/CH09 e a preservação das 3 categorias fixas M2-03/CH06. Capturar folhas 2 e 3 com **Seleções Atuais** visível; limpar o filtro e confirmar retorno visual. **É teste limitado de preservação da apresentação VIS-02, não repetição da bateria C4.** Não executar 2018 vs M2-02, não reabrir C2/C3/C4, nem alterar propriedades/expressões.
4. **Encerramento físico:** fechar sem salvar. Nenhum novo hash do original é necessário somente para repetir a prova VIS-02 já existente; se houver suspeita concreta de modificação, interromper e exigir comparação read-only com o SHA esperado antes de prosseguir.

Se não for possível apresentar evidência de viewport/resolução e do comportamento interativo com os arquivos existentes, manter `INCONCLUSIVE`; **não inventar PASS**.

### Critérios de STOP

- Qualquer aviso ausente ou valor apresentado como válido sob seleção incompatível → `BLOCKED`, registrar imagem e cenário, não editar neste gate.
- Qualquer QVW original modificada, divergência de SHA reportado, prompt inesperado de recuperação, desaparecimento de objeto ou sobreposição crítica → `BLOCKED`, preservar evidência e encerrar sem tentar correção.
- Legibilidade inadequada em compartilhamento → registrar objeto/problema P1 e `BLOCKED_FOR_PRESENTATION`; qualquer ajuste dependerá de autorização separada na cópia, sem mudança semântica.
- Sem sessão GUI/resolução/evidência de rolagem → `INCONCLUSIVE`; STOP da parte executável nesta sessão.

**Exclusões:** nenhuma edição QVW/QVD/QVS, nenhum novo script ou runner, nenhum Reload, nenhuma reconstrução, nenhum F01–F05/C2/C3/C4, nenhum cenário temporal 2018×M2-02, nenhuma autorização de Fase IX, nenhum DOC-R3, nenhum merge.

## 5. Riscos e registro do gate

| Risco | Severidade | Situação atual |
|---|---|---|
| Legendas técnicas de M2-03 e códigos municipais pouco amigáveis | P1 — legibilidade | Detectado anteriormente; ainda não avaliado no compartilhamento |
| Rótulos mensais densos em M1-02/M2-01 e potenciais cortes por compartilhamento | P1 — legibilidade | Inconclusivo em resolução de transmissão |
| Avisos de contexto M2-02 e M3-03 na QVW refinada | P2 — integridade restrita | Evidência funcional anterior reutilizável; comportamento da cópia atual não revalidado nesta sessão |
| `M2-02` fixo em `201912` sob seleção de 2018 | Lacuna contratual conhecida | **Decisão pendente** fora de VIS-03; não executar teste físico nem classificar como PASS |
| Divergência `main` 14 visuais vs Draft #226 9 visuais | Governança de produto | Delta preservado; integração depende de decisão separada |

`VIS03_DOCUMENTARY_AUDIT=COMPLETE`  
`VIS03_GUI_PRESENTATION_RESOLUTION=INCONCLUSIVE`  
`VIS03_RANKING_SCROLL=INCONCLUSIVE`  
`VIS03_POST_VIS02_GUARDS=NOT_TESTED`  
`VIS03_ORIGINAL_HASH=PASS_HASH_LOCAL_REPORTED_FROM_VIS02`  
`VIS03_GATE=INCONCLUSIVE_PENDING_GUI_EVIDENCE`  
`C2_C3_C4_GLOBAL=NOT_APPROVED`  
`PHASE_IX=NOT_AUTHORIZED`  
`PRODUCTION_APPROVED=False`

**STOP desta execução:** auditoria documental encerrada. Não declarar VIS-03 aprovada enquanto persistirem lacunas de transmissão/rolagem. Após evidência GUI mínima, revisar *somente* as linhas pendentes e emitir closeout definitivo em branch documental, sem merge automático.

**Handoff reservado:** `DOC-R3` somente após conclusão/decisão explícita da VIS-03, com atualização das capturas/legendas afetadas do Capítulo 3 e preservação dos Capítulos 1–2 e anexos. Avaliação acadêmica informada pelo operador para **08/12/2026**, apresentação online via Google Classroom e relatório PDF; não confundir esse relato com horário/atividade comprovados no Classroom.


---

## 6. VIS-03 — avaliação GUI de oito capturas reais recebidas em 10/11/2026

**Esta seção substitui os estados de 'pendente' dos §§3–5 somente para os critérios efetivamente evidenciados.** Os relatos de status antes das capturas são preservados historicamente. Modalidade: oito PNGs de captura de tela **inspecionados diretamente neste chat** e SHA-256 **calculado sobre os PNGs anexados**. A análise não teve acesso aos bytes QVW/QVD, nem ao stream real do Classroom, nem ao estado persistido pós-fechamento desta sessão. O título das janelas identifica a QVW de trabalho VIS-02; o estado de seleção foi fotografado na interface.

**Resolução de todos os PNGs:** 1907×1068 px. Esta é a resolução do arquivo da screenshot, **não** uma medição da resolução/compressão do compartilhamento remoto ao público.

| Arquivo de captura | SHA-256 do PNG recebido | Evidência principal |
| --- | --- | --- |
| \`image(20261110-150448).png\` | \`184A59550221DE1A79823E388F76D36DB6790562DA0645E8DC9EED91A20832A3\` | Folha 1 neutra; M1-01 anual, M1-02 série 36 competências, ranking SERV M1-03 inicialmente ordenado |
| \`image(20261110-150455).png\` | \`263FC6DB708EC1E9C0A828A0C2219BFD1D5AC2210DB8B403E4DEC6B87D8699F3\` | Folha 2 neutra; CH04 duas séries, CH05 ranking, CH06 três categorias com rótulos técnicos sobrepostos/truncados |
| \`image(20261110-150502).png\` | \`BD901C53D990B14010086035B7F72AA95E3AA3B4D127A488F6AFDD84EE1F9887\` | Folha 3 neutra; M3-03 população anual sem total trianual, M3-01 duas classes, M3-02 total 555089 na seleção exibida |
| \`image(20261110-150536).png\` | \`754F48AD7978CF6AC4C2C506A8EE54D6CD9FB0DD6E0BC85207105CEE24E8A27A\` | Ranking M1-03 rolado para posições inferiores, sem desaparecimento de barras |
| \`image(20261110-150550).png\` | \`B3EC123361B652D16C1B0A08498242394201A9B3A1C81C9FBC8F061FA124FB92\` | Ranking M2-02 rolado para posições inferiores, sem desaparecimento de barras |
| \`image(20261110-151011).png\` | \`C3B6D7DC77BE106A325CF9726D142F97A9935823192E14C2389CF293B591A91A\` | M1-02 exibe somente competência 201801 e M1-01 barra 2018 reduzida pelo contexto; título da janela apresenta \`*\` |
| \`image(20261110-151027).png\` | \`24C93BDAB3B347FB12B740E6D091623A611999DC28BA2D509F057CC4DFECAC55\` | Folha 2 sob 201801: CH05 exibe aviso de que a referência é 201912 e seleção é incompatível; CH04 mostra ponto 201801, CH06 mantém três barras |
| \`image(20261110-151037).png\` | \`98D2E409A7B9833C00F56CCA86F400C8FF03C52E3AFF4E67DDBCCCD75C77D83A\` | Folha 3 sob 201801: CH09 mostra aviso de que população é anual e competência mensal incompatível; M3-01 e M3-02 permanecem visíveis |

### 6.1 Resultado por critério

| Critério | Veredito estrito | Justificativa |
| --- | --- | --- |
| Nove objetos distribuídos em três folhas | \`PASS_GUI_RENDER_RESTRICTED\` | 3×3 fotografados em captura nova da QVW de trabalho |
| Identidade, cabeçalhos, áreas e ausência de sobreposição crítica de **objetos** | \`PASS_SINGLE_CAPTURE_VIEWPORT_RESTRICTED\` | Estrutura visível sem gráfico coberto por outro; **não** implica que textos internos tenham passado |
| Rolagem nativa M1-03 e M2-02 | \`PASS_GUI_SCROLL_RESTRICTED\` | Antes/depois de ambos os rankings; não garante auditoria numérica de todas as linhas |
| Avisos CH05 e CH09 sob competência 201801 | \`PASS_GUI_CONTEXT_MONTH_RESTRICTED\` | Ambos os textos corretos aparecem na cópia refinada, em folhas distintas, sem dados incompatíveis mostrados nesses objetos |
| Ilha A1 / CH06 visual sob competência 201801 | \`PASS_GUI_ISLAND_PRESENCE_RESTRICTED\` | Três categorias mantidas; ausência de \`Seleções Atuais\` impede comprovação de que 201801 foi a única seleção |
| Rótulos de categorias CH06/M2-03 | \`BLOCKED_FOR_PRESENTATION\` | \`ABSENT_NOT_ZERO_PROVEN\`, \`OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED\` e terceira categoria aparecem em posições colidentes, cortadas ou truncadas; identificação inequívoca não é possível na captura |
| Compartilhamento efetivo de tela online | \`INCONCLUSIVE\` | Capturas da tela local não demonstram legibilidade após redução/compressão da transmissão |
| Novo SHA-256 da QVW fonte e cópia no encerramento VIS-03 | \`NOT_RECHECKED\` | Só há hashes reportados na VIS-02, não foi feito novo cálculo de QVW |
| Releitura de expressões/estado interno e C2/C3/C4 globais | \`NOT_AUDITED\` | Somente inspeção visual; sem COM/Reload/propriedades internas |

**Achado P1 — bloqueio localizado:** mesmo na captura de 1907 px, a legenda/eixo de categorias do CH06/M2-03 é ilegível. Esta é uma falha de **apresentação**, não de contagem, observabilidade, associação nem integridade de arquivo. Os números antigos (4.467/3.464/97) não foram recalculados nem conferidos por tooltip.

**Achados P2 não bloqueantes por si mesmos:** rótulos técnicos \`RES_EQ_SERV\`/\`RES_NE_SERV\` em M3-01 e códigos de município sem tradução descritiva dificultam explicação ao público; rótulos de competências em M1-02/M2-01 são densos; a expressão 'por ano' em M1-01 sob filtro mensal requer contextualização explícita durante a apresentação. **Não são autorização para editar dimensões ou acrescentar indicadores.**

**Nota operacional de Save:** os PNGs após a seleção mensal mostram um \`*\` no título do QVW de trabalho. Isso não prova Save nem violação de hash, mas **impede afirmar que a sessão foi fechada sem salvar**. Fechar sem salvar e manter o SHA anterior como referência até qualquer nova auditoria de bytes; não sobrescrever a fonte C4.

### 6.2 Decisão de fechamento e ação mínima proposta

\`VIS03_NINE_OBJECTS=PASS_GUI_RENDER_RESTRICTED\`  
\`VIS03_RANKING_SCROLL=PASS_GUI_SCROLL_RESTRICTED\`  
\`VIS03_MONTH_CONTEXT_CH05_CH09=PASS_GUI_CONTEXT_MONTH_RESTRICTED\`  
\`VIS03_CH06_ISLAND=PASS_GUI_PRESENCE_RESTRICTED\`  
\`VIS03_LABELS_CH06=BLOCKED_FOR_PRESENTATION\`  
\`VIS03_STREAMING_VIEW=INCONCLUSIVE_NOT_CAPTURED\`  
\`VIS03_QVW_BYTES_POST_SESSION=NOT_AUDITED\`  
\`VIS03_GATE=BLOCKED_FOR_PRESENTATION_P1_CH06_LABELS\`  
\`C2_C3_C4_GLOBAL=NOT_APPROVED\`  
\`PHASE_IX=NOT_AUTHORIZED\`  
\`PRODUCTION_APPROVED=False\`

**STOP VIS-03:** não repetir os cenários de rolagem ou 201801. Não executar ajustes de GUI dentro da VIS-03. Propor escopo independente **VIS-02-P1-LABEL-FIX**: somente apresentação legível das três categorias CH06/M2-03, preservando classificação/códigos, contagens, ilha A1, título de panorama fixo, paleta, nove objetos e todas as expressões/guardas de outros objetos. Avaliar primeiro se há solução puramente visual (tamanho, eixo, legenda, tooltip, texto de apoio sem novo KPI) no QlikView 12; alteração de \`Dimensions\`/\`Expressions\`, \`Dual()\` ou renomeação de dados é mudança semântica/técnica e requer aprovação separada. Qualquer edição física deve ocorrer apenas em nova cópia controlada, autorizada, com hash original preservado; **sem Reload/Save da fonte**. Depois, apenas reavaliar legibilidade de CH06 em captura e, se pertinente, transmissão real. Não iniciar DOC-R3 nem merge automaticamente por este achado.
