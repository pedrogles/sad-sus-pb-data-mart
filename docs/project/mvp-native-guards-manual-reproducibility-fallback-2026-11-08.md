# SAD MVP — F05/R1B | fallback reprodutível manual de guardas nativas QlikView 12

**Preparado em:** 08/11/2026. **Estado:** `MANUAL_RUNBOOK_VERSIONED_NOT_EXECUTED_FOR_NEW_BUILD`. **Finalidade:** definir o procedimento **versionado** para que um **novo** QVW TEMP candidato, criado por `tools/Build-SadMvpThreeSheetsTemp.ps1`, receba as guardas CH04/CH05 que já passaram em GUI na cópia F04 anterior. Este procedimento não altera nem reexecuta o builder, não demonstra reprodutibilidade automática e não substitui C2 físico global.

## Fonte de verdade e motivação

A `main` fornece os contratos e a ordem de gates `AGENTS.md → docs/project/current-state.md → docs/academic/requirements.md → Boundary 7`. As evidências e o contrato declarativo de F05 ficam **somente na branch Draft do PR #226**:
- [Contrato versionado das duas guardas](../../PAINEL/sad_mvp_native_guard_contract.json): `CH04/M2-01`, `CH05/M2-02`, expressões e mensagens exatas.
- [Revisão F05 e STOP COM](mvp-native-guard-reproducibility-com-mapping-2026-11-07.md): `EvaluationCondition.v` legível; `GraphLayout.ErrorMessageOverrides.Count=14`, **sem leitura mapeada de entradas de mensagem**; não executar SetProperties por suposição.
- [F04-U1/P2](mvp-f04-u1-p2-targeted-save-reopen-correction-2026-11-07.md): guardas **já persistidas manualmente** na QVW TEMP F04, hash fixo `4AF2C4BE17336AB729CF0CD70D75B7481B41AC003958EDB543584A1484047F92`.

Não usar a QVW F04 validada como destino de nova edição nem reconstruí-la. **A QVW temporária F04 é evidência, não template canônico.**

## Pré-condições para aplicar este runbook em futuro build

1. Novo QVW **TEMP** identificado inequivocamente por `CANDIDATE_QVW` do **builder já versionado**, após seus gates de oráculo e integridade terem sido aprovados **naquele build**. Sem `M2_VERDICT=BUILT_CANDIDATE_ONLY_NOT_HOMOLOGATED` e `PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED=True`, STOP.
2. QVW temporário de origem preservado. Criar uma **cópia TEMP para a aplicação GUI** fora do repositório, deixando o candidato de origem intocado; registrar caminho e SHA-256 de ambos. Não criar uma cópia a partir de `PAINEL/PAINEL.qvw` nem substituir os 25 artefatos originais.
3. A cópia a configurar tem **três folhas e nove objetos**, incluindo `CH04` e `CH05`, dimensões e medidas **idênticas** ao MVP. Se faltar objeto, STOP. Não usar este roteiro em QVW de arquitetura diferente.
4. **Mudança permitida somente:** `CH04` e `CH05`, cada um com **Condição de cálculo** e **mensagem personalizada de “Condição de cálculo não satisfeita”**. Mais nenhuma propriedade, expressão de medida ou campo.
5. Preferir ler as expressões literais diretamente do contrato `PAINEL/sad_mvp_native_guard_contract.json` na mesma branch/HEAD do novo build. Não digitar versões improvisadas, traduzir nomes de campos ou trocar mensagens.

## Execução no QlikView Desktop 12 — manual e auditável

Para **CH04 / M2-01**, na folha *Leitos Cadastrais Observados*, gráfico de linhas *Leitos cadastrados por competência — snapshots*:
1. **Propriedades → Geral → Condição de cálculo:** copiar exatamente o valor `objects[0].calcCondition` do JSON versionado (`=GetSelectedCount(RES_COD_DATASUS_6,True())=0`).
2. **Mensagens de Erro → Condição de cálculo não satisfeita:** copiar exatamente `objects[0].calcConditionUnfulfilledMessage` do JSON (aviso estático de residência). **Nunca usar “Aplicar a Tudo”.**

Para **CH05 / M2-02**, gráfico de barras *Leitos SUS observados — município, 201912*:
3. **Propriedades → Geral → Condição de cálculo:** copiar exatamente `objects[1].calcCondition` do JSON (RES sem seleção **e** filtro de ano compatível com 2019 **e** competência compatível com `201912`). Exigir **“Expressão OK”**.
4. **Mensagens de Erro → Condição de cálculo não satisfeita:** copiar exatamente `objects[1].calcConditionUnfulfilledMessage` do JSON, **incluindo o `=` inicial**; exige a expressão calculada `If(...)` alternando razão RES e razão temporal. Exigir **“Expressão OK”**.
5. **Não tocar** na expressão de soma do CH05 (`objects[1].measureMustRemain`): `Sum({<PERIODO_COMPETENCIA={'201912'}>} QTD_LEITOS_SUS)`. Não alterar `CH06`/P23, `M3-01/M3-02/M3-03`, títulos, dimensões, layout, dados ou script.

Depois:
6. Confirmar **OK** em todas as janelas de edição. Limpar filtros; **salvar explicitamente somente a cópia TEMP configurada** e fechá-la.
7. Calcular SHA-256 da QVW TEMP após salvar e registrar junto com o hash de sua cópia de origem. O hash final deve **diferir** do da cópia antes da edição e continuar idêntico depois da próxima reabertura **sem salvar novamente**.
8. Reabrir **essa mesma cópia TEMP**, conferir no editor as duas propriedades de CH04 e CH05 e registrar captura de cada propriedade CH05. Cancelar as janelas sem reaplicar. Capturar **seleções vazias** (CH04/CH05 exibem gráficos, P23 com três categorias), `PERIODO_ANO=2018` (CH05 aviso 201912; CH04 mostrando 2018), `RES_COD_DATASUS_6=251370` (CH04/CH05 aviso RES); limpar filtros entre os estados. **Somente para um candidato novo** que ainda não tem essas provas; não repetir os testes da QVW F04 já fechada.
9. Fechar sem salvar e recalcular SHA do mesmo arquivo; exigir **igual** ao hash salvo do passo 7. Se diferente, STOP e preservar evidências do desvio.

## Aceite restrito e condição de parada

**PASS de reprodutibilidade manual, nunca PASS automático:** contrato versionado corresponde às propriedades reabertas; medidas e nove objetos invariantes; SHA de origem e QVD/QVW canônicos preservados; SHA da cópia editada muda no Save e não muda na inspeção; três cenários GUI com avisos corretos; dados não mascarados como zeros.

**BLOCKED:** qualquer valor diferente do manifesto, aviso literal/genérico, alteração de medidas, QVW fora do escopo, SHA não conforme ou recarga inesperada. **INCONCLUSIVE:** falta de capturas ou hashes. Encerrar após uma única execução do procedimento no novo QVW, sem sequência de tentativas.

**Estado desta entrega documental:** `F05_R1B=PARTIAL_PASS_WITH_STOP`; `F05_MANUAL_GUARD_APPLICATION=RUNBOOK_VERSIONED_NOT_EXECUTED`; `F05_BUILDER_AUTO_APPLY=NOT_IMPLEMENTED`; `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`; `C2_GUIDED_R2/C3/C4/LINK_KEY_CONTRACT/P5_GLOBAL/PHASE_IX/PRODUCTION=NOT_APPROVED`. PR #226 Draft; sem merge, arquivos de dados não versionados e `main` inalterada.

## Resultado físico posterior — guardas CH04/CH05 na nova QVW TEMP (08/11/2026)

**Identificador de evidência:** `F05_MVP_MANUAL_GUARDS_2026_11_08`. Este registro atualiza **somente o estado do ensaio nesta nova TEMP**, sem reescrever o histórico F04/F05 anterior e sem aceitar C2 global.

**Proveniência:** operador executou Windows/QlikView x64 Personal Edition e forneceu stdout PowerShell e capturas GUI na conversa em 08/11/2026. O agente examinou as capturas fornecidas, mas **não teve acesso ao binário QVW**, aos manifestos locais nem fez readback COM independente. A branch local foi atualizada para `d5e862399fd5511925fdd04b856db53f1288a7ec`; a construção relatada da QVW TEMP usou o executor no commit `403929dbb979d88e348204126a8d0dcc234c6ac3`. Os dois commits entre eles modificaram **apenas documentação**, não o builder. O stdout da construção reportou `M2_VERDICT=BUILT_CANDIDATE_ONLY_NOT_HOMOLOGATED`, nove `M2_CREATED` e `PROTECTED_25_CANONICAL_AND_M1_SOURCE_SHA256_UNCHANGED=True`. Esses controles pertencem **à construção**, não a uma auditoria independente posterior dos 25 arquivos.

**Origem preservada:**
- QVW fonte: `C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_THREE_SHEETS_CANDIDATE.qvw`.
- SHA-256 da fonte, novamente checado pelo operador: `EBC9648187FC6449F28B2B037D5A1ED33F1E3ACB5844DDE01B56BF34F39EF28A`; `ORIGINAL_PRESERVED=True`.
- Destino exclusivo da configuração manual: `SAD_MVP_THREE_SHEETS_CANDIDATE_INSPECAO.qvw` **no mesmo diretório externo**. A cópia foi inicialmente confirmada com SHA igual ao da fonte e `VERDICT=COPY_READY_ONLY`.

**Aplicação e comportamento observado (screenshots QlikView fornecidas na conversa):**
- CH04: condição `=GetSelectedCount(RES_COD_DATASUS_6,True())=0` mostrada com `Expression OK`. Sob `RES_COD_DATASUS_6=251370`, gráfico suprimido e mensagem de incompatibilidade do papel RES exibida, com acentuação correta.
- CH05: editor mostrou `Expression OK` para a condição de RES/ano/competência e para o `If(...)` de mensagem. Sem seleção, o gráfico fixo `201912` continuou visível. Sob `PERIODO_ANO=2018`, CH04 mostrou `201801..201812` e CH05 exibiu aviso específico de incompatibilidade com dezembro/2019. Sob `RES_COD_DATASUS_6=251370`, CH04 e CH05 mostraram avisos de residência, em vez de zeros.
- P23: nas telas dos cenários, as três categorias da ilha permaneceram visualmente presentes; **não há nova auditoria numérica ou comprovação global de isolamento**.

**Persistência após Save e reabertura:** o operador limpou seleções, salvou e fechou **apenas a cópia de inspeção**. PowerShell reportou `ORIGINAL_PRESERVED=True`, `COPY_CHANGED=True`, `SAVED_SHA256=F70839792AE5B954989FF39CDC1932C8514806AA4E211187457A56301B9F1EE5`. Em reabertura posterior, screenshot da folha 2 com `PERIODO_ANO=2018` mostrou CH04 com a série de 2018 e CH05 exibindo o aviso temporal específico. Após fechar sem salvar novamente, o PowerShell reportou `POST_REOPEN_SHA256=F70839792AE5B954989FF39CDC1932C8514806AA4E211187457A56301B9F1EE5` e `PERSISTENCE_HASH_UNCHANGED=True`. O código de verificação do operador também constatou ausência do processo `qv` antes de calcular o hash final.

**Classificação e limites:**
- `F05_MVP_MANUAL_GUARD_APPLICATION=PASS_GUI_RESTRICTED`.
- `F05_MVP_GUARD_FUNCTIONAL_PERSISTENCE=PASS_GUI_RESTRICTED_WITH_LOCAL_SHA`.
- `F05_MVP_COPY_INTEGRITY=PASS_LOCAL_OPERATOR_REPORTED`; hash de QVW não atesta quais propriedades internas específicas foram alteradas.
- `F05_MVP_POST_REOPEN_PROPERTY_EDITOR_READBACK=NOT_EVIDENCED`: a captura pós-reabertura prova o aviso **funcional**, não a leitura posterior das expressões no editor. A exatidão das propriedades foi fotografada **antes** da gravação.
- `F05_BUILDER_AUTO_APPLY=NOT_IMPLEMENTED`: as guardas foram aplicadas manualmente e **não** surgem automaticamente em outro build.
- `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=PARTIAL_RESTRICTED_NOT_GLOBAL`; `C2_GUIDED_R2/C3/C4/P5_GLOBAL/LINK_KEY_CONTRACT/PHASE_IX/PRODUCTION=NOT_APPROVED`.

**STOP/encerramento:** o lote funcional de CH04/CH05 **nesta QVW** está encerrado. Não executar novamente F03/F04/F05 nem reconstruir a candidata para demonstrar as mesmas guardas. Próxima prioridade sugerida: **C3/MVP preflight read-only das associações efetivamente utilizadas pelos nove visuais**, especialmente FI→SERV, RES→SERV e POP município×ano, reutilizando oráculos existentes. Não autoriza alteração física do Link, QVS/QVD/QVW canônicos, merge do PR #226 ou mudanças na `main`.
