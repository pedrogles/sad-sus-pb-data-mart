# SAD — VIS-02 | Closeout restrito de aplicação visual (10/11/2026)

**Escopo:** MVP acadêmico TEMP de três folhas e nove objetos. A aplicação foi feita no QlikView Desktop 12 x64 Personal Edition pelo operador, exclusivamente em QVW de trabalho; este agente analisou os prints e saídas fornecidos, sem acesso independente aos bytes da QVW.

## Autoridade e limites

Fontes reconsultadas em 10/11/2026: main:AGENTS.md → main:docs/project/current-state.md → main:docs/academic/requirements.md. Referências: runbook VIS-02 nesta branch; aprovação VIS-01 no Draft #230; objetos MVP do Draft #226. A main mantém o blueprint formal de 14 visuais, C2/C3/C4 pendentes e Fase IX não autorizada.

**Aprovação do responsável:** VIS-01 aprovada no chat, VIS-02 autorizada. Exceção expressamente aprovada durante a edição: ordenação decrescente por Valor-Y para M1-03, com navegação pelas categorias, sem Top N. Essa autorização não se estende aos demais objetos.

## Evidências físicas reportadas

**Origem protegida:** C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw

**SHA-256 origem esperado e reportado novamente após edição:** 27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13

**Saída do operador:** ORIGINAL_PRESERVED=True.

**Cópia VIS-02:** C:\Users\pedro\SAD_VIS02_EVIDENCIAS\VIS02_20261109_230246_40a7da274f784973ab11175e4387a736\SAD_MVP_C4_VIS02_WORK.qvw

**Saída do operador:** WORK_QVW_EXISTS=True.

**SHA-256 da cópia após aplicação e Save, reportado:** C564C7020D4F7377A541427B197E38726C47370385C14FE6446E7BA098158619

**Manifesto preflight:** C:\Users\pedro\SAD_VIS02_EVIDENCIAS\VIS02_20261109_230246_40a7da274f784973ab11175e4387a736\vis02_preflight_manifest.json

Preflight anterior: VERDICT=PASS_COPY_AND_ASSET_HASHES_ONLY e SOURCE_UNCHANGED=True, via tools/Prepare-SadVis02WorkCopy.ps1 versionado nesta branch. Manifesto e QVW binária não foram auditados neste ambiente.

## Persistência visual pós-salvamento e reabertura

Três capturas reais fornecidas no chat, no fechamento em 10/11/2026:

- image(20261110-143005).png: Folha 1 — Produção Hospitalar. M1-01 barras anuais, M1-02 série mensal, M1-03 ranking SERV horizontal/rolagem/Valor-Y decrescente, identidade institucional.
- image(20261110-143012).png: Folha 2 — Leitos Cadastrais Observados. M2-01 duas séries com legenda descritiva; M2-02 ranking municipal de 201912; M2-03 três categorias com âmbar/teal/cinza. Rótulos técnicos de M2-03 permanecem extensos.
- image(20261110-143019).png: Folha 3 — Fluxos e Contexto Territorial. M3-01 RES=SERV vs RES≠SERV, M3-02 tabela de pares RES→SERV com total 555089 no estado exibido, M3-03 população municipal×ano sem total trianual visível.

O título da janela QlikView mostra a QVW de trabalho, sem asterisco de edições não salvas. Associado ao relato de fechamento/reabertura, isso sustenta persistência **visual restrita**, não auditoria independente de expressões, estados associativos ou guardas.

## Resultado por gate

| Critério | Status |
|---|---|
| Preflight e cópia isolada | PASS_LOCAL_REPORTED |
| Fonte original íntegra por hash | PASS_HASH_LOCAL_REPORTED |
| 3 folhas × 3 objetos visíveis | PASS_GUI_VISUAL_RESTRICTED |
| Estilo persistiu após reabertura | PASS_VISUAL_PERSISTENCE_RESTRICTED |
| Sem cortes importantes no viewport capturado | PASS_SINGLE_VIEWPORT_RESTRICTED |
| Auditoria independente de expressões/dimensões/guardas | NOT_AUDITED |
| Semântica de seleção nativa, indisponibilidade e regressões | NOT_TESTED_IN_VIS02 |
| C2/C3/C4 e produto final | NOT_APPROVED |

**VIS02_GATE=PASS_LOCAL_RESTRICTED_CLOSED**; **PR_MERGED=False**; **PRODUCTION_APPROVED=False**; **PHASE_IX=NOT_AUTHORIZED**.

## STOP e handoff separado

Encerrar VIS-02 sem novos ajustes, Reload, COM, QVS, QVD, merge, alterações de main ou DOC-R3. Manter a QVW TEMP original e a cópia hashada, preservar prints e saída de hashes em evidências privadas, fora do Git.

VIS-03, em execução própria a autorizar, poderá usar as capturas existentes e se concentrar apenas na legibilidade em compartilhamento, rótulos técnicos residuais, persistência em resolução de apresentação e avisos de incompatibilidade — **sem repetir** os gates F01/F02/F03, nem inferir PASS C2/C3/C4. Se falhar, STOP sem substituir a origem.

O atual docs/project/current-state.md na main ainda reflete snapshot de 03/11; esta evidência acadêmica de 10/11 permanece em branch Draft, não altera o estado operacional canônico sem integração autorizada.