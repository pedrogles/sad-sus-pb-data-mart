# SAD MVP — F04-U1/P2 | correção localizada de salvamento e persistência CH05

**Data de preparação:** 07/11/2026. **Estado:** `PROTOCOL_VERSIONED_NOT_EXECUTED`. **Motivo comprovado em P1:** após reabertura, `CH05` ainda usa exclusivamente `=GetSelectedCount(RES_COD_DATASUS_6,True())=0` e mensagem fixa de residência; a guarda temporal e mensagem `If(...)` apresentadas na sessão anterior **não constam nas propriedades salvas**. Evidências e SHA dos dois PNGs em [P1, seção 7](mvp-f04-u1-qvw-persistence-reopen-gate-2026-11-07.md).

## 1. Objetivo, autoridade, escopo e segurança

Registrar a **persistência real de apenas duas propriedades** do gráfico `CH05 / M2-02` depois de salvamento explícito e reabertura, e executar **somente um cenário temporal 2018** após a reabertura. Não alterar código, scripts, fatos, QVS, 22 QVDs, 3 QVWs canônicos, `main`, `CH04`, P23 ou expressão de soma fixada em `201912`. Não há revalidação global C2/C3/C4/P5 nem GO IX.

A hierarquia na `main` permanece `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md`; contrato V2/V3 D2-R2 e decisão [C2-MVP nativo B1](mvp-c2-native-acceptance-owner-approved-2026-11-07.md) preservados. A fonte a editar continua **somente a QVW TEMP externa**:

```text
C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1\SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw
```

**Baseline de integridade já reportada no P1:** SHA-256 `6310321DB30C1065843B6BFF1A400D2C29D235D4B7C79372453366454EB1B1BD`. É esperado que **mude** após salvar a configuração nova; é esperado que **permaneça igual** entre o fechamento após salvar e o fechamento após a inspeção sem gravação.

**STOP preliminar:** se abrir outro QVW, houver nova recarga, dados ausentes fora do escopo, outra edição em progresso ou a versão de propriedades for diferente do estado antigo documentado, não continuar; capturar o problema.

## 2. Correção única na interface QlikView Desktop 12

1. No arquivo TEMP acima, executar **Limpar** e manter a janela `Seleções Atuais` **vazia**. Abrir `CH05` (gráfico inferior esquerdo, folha Leitos Cadastrais Observados) → **Propriedades → Geral**.
2. Substituir **somente a Condição de cálculo**, que agora contém apenas RES, pelo texto combinado abaixo. Confirmar `Expressão OK` no editor e sair via `OK`:

   ```qlik
   =GetSelectedCount(RES_COD_DATASUS_6,True())=0 And (GetSelectedCount(PERIODO_ANO,True())=0 Or (GetSelectedCount(PERIODO_ANO,True())=1 And Only(PERIODO_ANO)=2019)) And (GetSelectedCount(PERIODO_COMPETENCIA,True())=0 Or (GetSelectedCount(PERIODO_COMPETENCIA,True())=1 And Only(PERIODO_COMPETENCIA)=201912))
   ```

3. Na mesma aba, **Mensagens de erro → Condição de cálculo não satisfeita**. Substituir **só** a mensagem estática pelo texto calculado, iniciado por `=`:

   ```qlik
   =If(GetSelectedCount(RES_COD_DATASUS_6,True())>0,'Indisponível nesta seleção: o filtro de residência não define a localização dos leitos. Ausência de dados associados não significa zero leitos.','Indisponível nesta seleção: este gráfico mostra somente dezembro de 2019 (201912). O período selecionado é incompatível. A ausência de dados não significa zero leitos.')
   ```

   Confirmar `Expressão OK` se abrir o editor. Clicar **OK** no diálogo de mensagens, depois **OK** nas propriedades do gráfico. **Não** usar `Aplicar a Tudo`, `Limpar Todas` nem alterar dimensão, expressão, título, a mensagem de outros objetos ou o script.
4. Com a caixa **Seleções Atuais vazia**, pressionar **Ctrl+S** ou `Arquivo → Salvar` para salvar **a própria QVW F04 TEMP**. Confirmar que o título não apresenta `*`. **Fechar o QVW** sem novas seleções nem novo salvamento.
5. Já com a QVW fechada, calcular o SHA **da mesma QVW TEMP** usando o PowerShell somente leitura:

   ```powershell
   $qvw = "$env:USERPROFILE\SAD_M1_EVIDENCIAS\SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1\SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw"
   $baseline = "6310321DB30C1065843B6BFF1A400D2C29D235D4B7C79372453366454EB1B1BD"
   $savedSha = (Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
   "F04_P2_SAVED_SHA256=$savedSha"
   if ($savedSha -eq $baseline) { throw "STOP: QVW ainda tem o SHA antigo; salvamento temporal não comprovado" }
   ```

   Uma diferença SHA comprova **mudança do binário TEMP** no salvamento; **não** prova por si só que as duas propriedades foram persistidas.

## 3. Prova de reabertura e STOP

6. Reabrir **o mesmo QVW F04 TEMP**. Antes de qualquer seleção, abrir `CH05 → Propriedades → Geral`: registrar captura mostrando **Condição de cálculo com RES + ano + competência**. Abrir `Mensagens de erro → Condição de cálculo não satisfeita`: capturar **expressão dinâmica `If()`**. **Cancelar** todos os diálogos sem tocar no conteúdo. Se a regra tiver voltado ao formato RES-only ou a mensagem ao texto fixo, classificar `BLOCKED_PERSISTENCE` e **STOP** sem repetir.
7. Sem outras seleções, na folha `Produção Hospitalar`, selecionar **apenas** `PERIODO_ANO=2018` no M1-01, mudar para `Leitos Cadastrais Observados`, capturar **uma screenshot** com `Seleções Atuais=2018` e texto **temporal** em CH05; o CH04 deve continuar mostrando meses de 2018 e P23 as três categorias. Se o aviso não aparecer, `BLOCKED_GUI_POST_REOPEN` e STOP.
8. Limpar seleções e fechar o QVW **sem salvar**. Calcular SHA novamente:

   ```powershell
   $afterSha = (Get-FileHash -LiteralPath $qvw -Algorithm SHA256).Hash
   "F04_P2_AFTER_REOPEN_SHA256=$afterSha"
   if ($afterSha -ne $savedSha) { throw "STOP: QVW foi alterado durante a inspeção pós-reabertura" }
   "F04_P2_SHA_UNCHANGED_DURING_REOPEN=True"
   ```

   Enviar **dois hashes** (`F04_P2_SAVED_SHA256` e `F04_P2_AFTER_REOPEN_SHA256`) e as **três capturas** (condição persistida, mensagem persistida, estado 2018 com aviso). Não repetir `S_OK`/RES/2018 da sessão anterior em bateria integral.

**PASS restrito obrigatório:** `savedSha != baseline`, `afterSha == savedSha`, as duas propriedades CH05 preservadas **após reabrir** e `PERIODO_ANO=2018` renderizando aviso temporal explícito. Se faltar qualquer elemento, `BLOCKED` ou `INCONCLUSIVE`, não aprovar persistência.

**Encerramento:** `F04_U1_P2=PREPARED_NOT_EXECUTED`; `F04_U1_REOPEN_PERSISTENCE=BLOCKED` até validação nova; `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`; `C2_GUIDED_R2/C3/C4/P5_GLOBAL/LINK_KEY_CONTRACT/IX/PRODUCTION=NOT_APPROVED`. PR #226 Draft, sem merge. O processo de reprodutibilidade no builder é um próximo objetivo diferente deste gate.


## 4. Evidência recebida após reaplicação CH05 — pré-reabertura

**Recebimento:** 07/11/2026. Cinco capturas reais do QlikView x64 Personal Edition, apresentadas pelo responsável na conversa depois de reaplicar as duas propriedades no arquivo F04 TEMP (`SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1/SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE`). Os hashes abaixo foram calculados dos **PNGs montados**, não de binário QVW. **NÃO há evidência de fechamento e reabertura posterior ao novo salvamento nestas capturas.**

| PNG | Resolução | Bytes | SHA-256 | Fato diretamente visível |
|---|---|---:|---|---|
| `image(20261107-195910).png` | 1907×1068 | 270250 | `3CA273431B8BEF87F88C2184C3D9E87C08CB7210A353F4F58559F4A1C5F6FA60` | Editor CH05 apresenta **`Expressão OK`** e condição de cálculo combinada, testando RES, `PERIODO_ANO` e `PERIODO_COMPETENCIA` |
| `image(20261107-200015).png` | 1904×1068 | 262557 | `1B779E68FE1F81D33BA34EF0066C20AAB8817ED54B8BF57F07780BD8289FCA48` | Editor CH05 apresenta **`Expressão OK`** para `If(GetSelectedCount(RES...), texto de RES, texto de incompatibilidade temporal 201912)` |
| `image(20261107-200040).png` | 1907×1068 | 268287 | `7F917155B27BACF7C1D02688B87A801693982ABB7880F91B231FEDB5BCE77212` | `Seleções Atuais` vazia; CH04 exibe duas séries, CH05 barras, P23 três barras |
| `image(20261107-200053).png` | 1907×1068 | 235180 | `DC5CF66B395ADD2A3FBE15C60DFA8BBF1E301CD7B4A88FDBE9B448E77140CB2C` | `Seleções Atuais` mostra ano **2018**; CH04 meses 201801–201812; CH05 exibe **aviso temporal com 201912**, sem publicar barras 2019 |
| `image(20261107-200120).png` | 1907×1067 | 215857 | `C474C34E46EA5809C2794BC395614680819620ABB794BBCE5BCBFFCD6BD7A80B` | `Seleções Atuais` mostra RES **251370**; CH04 e CH05 preservam aviso de residência; P23 mantém três barras |

**Resultado parcial do P2:** `F04_U1_P2_CH05_PROPERTIES=CONFIGURED_GUI_CONFIRMED`, `F04_U1_P2_S_OK=PASS_GUI`, `F04_U1_P2_S_TIME_2018=PASS_GUI`, `F04_U1_P2_S_RES_251370=PASS_GUI` **apenas na sessão apresentada**. O título da QVW **sem `*`** nas telas de gráficos é compatível com ausência de alterações pendentes, mas **não confirma reabertura após salvar**. O usuário ainda **não informou** novo hash SHA-256 da QVW após o salvamento nem hash após fechar e reabrir. Não inferir `savedSha != baseline` nem `afterSha == savedSha` sem stdout.

**Pendência única para concluir o gate:** preservar a QVW temporária e fechar a sessão atual com seleções limpas **sem salvar novamente** se a configuração já foi salva; obter SHA do QVW fechado (comparar com a baseline P1 `6310321DB30C1065843B6BFF1A400D2C29D235D4B7C79372453366454EB1B1BD`), reabrir o **mesmo arquivo**, conferir somente a presença das duas propriedades de CH05 e o cenário **2018** (não repetir o cenário RES nem a bateria completa), fechar sem salvar, verificar que o hash permaneceu igual. Se o hash ainda for igual à baseline antiga, **STOP**: não presumir que o novo Save foi realizado. Caso as propriedades não persistam, **STOP** para diagnóstico de Save. Não alterar `main`, QVD/QVW canônicos, scripts ou builder.

**Estado após esta evidência:** `F04_U1_P2=PARTIAL_GUI_PASS_PENDING_REOPEN_AND_HASH`; `F04_U1_REOPEN_PERSISTENCE=NOT_YET_PROVEN_AFTER_CORRECTION`; `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.


## 5. Resultado do salvamento e reabertura F04/P2 — SHA íntegro e aviso temporal visível

**Data de recebimento:** 07/11/2026. O operador enviou stdout de dois `Get-FileHash -Algorithm SHA256` executados no Windows na **mesma QVW TEMP F04** e uma screenshot real após reabertura. A captura foi conferida diretamente; os hashes do QVW são **evidência reportada pelo operador**, pois não há acesso do agente ao binário QVW do Windows. Nenhum script executável novo, COM, QlikView reload, QVD ou QVW canônico foi alterado aqui.

**Arquivo:** `C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_F04_TEMPORAL_GUARD_9a792ff10d694d15b50588bea940bbd1\SAD_MVP_F04_TEMPORAL_GUARD_CANDIDATE.qvw`.

| Checagem | Saída / evidência | Resultado |
|---|---|---|
| `F04_P2_SAVED_SHA256` | `4AF2C4BE17336AB729CF0CD70D75B7481B41AC003958EDB543584A1484047F92` | **Diferente** da baseline pré-correção `6310321DB30C1065843B6BFF1A400D2C29D235D4B7C79372453366454EB1B1BD`; o binário TEMP foi alterado no processo de salvamento |
| `F04_P2_AFTER_REOPEN_SHA256` | `4AF2C4BE17336AB729CF0CD70D75B7481B41AC003958EDB543584A1484047F92` | **Igual** ao SHA do arquivo salvo; nenhuma mudança de bytes entre as duas leituras do operador |
| Screenshot `image(20261107-200949).png` | PNG 1907 × 1068, 235329 bytes; SHA-256 **`024B63E6A1C742C5ECCB1B928AA1185B2D107FBAAAADE2BD79FA672543D8AE5C`** calculado sobre anexo efetivamente montado | `Seleções Atuais` mostra ano **2018**; CH04 mostra `201801..201812`; CH05 mostra a mensagem específica de incompatibilidade com **201912**, sem barras 201912 publicadas; P23 três barras |

**FATO VERIFICADO (evidência mista):** o QVW temporário salvo tem SHA distinto da versão P1, voltou a apresentar o aviso temporal 201912 sob o filtro nativo 2018 após sua reabertura, e seu SHA não mudou durante a inspeção reportada. Isto sustenta `F04_U1_P2_TEMPORAL_GUARD_REOPEN_FUNCTIONAL=PASS_GUI_RESTRICTED_WITH_LOCAL_SHA` e `F04_U1_P2_BINARY_INTEGRITY=PASS_LOCAL_REPORTED`.

**LIMITE DO GATE:** o protocolo P2 exige **duas capturas das propriedades de CH05 após reabrir** — condição de cálculo incluindo RES/ano/competência e mensagem de erro calculada `If(...)`. Elas **ainda não foram recebidas** nesta etapa; não é válido converter a demonstração funcional em leitura independente de cada propriedade, nem dizer que o QVW está homologado ou que os hashes provam semanticamente o conteúdo do CH05. A screenshot 2018 prova o texto exibido, não a expressão interna exata que o gera. O fato de o SHA permanecer igual após uma sessão é indício de não gravação, não um restore test de todos os objetos.

**Veredito formal atual:**
- `F04_U1_P2_TEMPORAL_GUARD_REOPEN_FUNCTIONAL=PASS_GUI_RESTRICTED_WITH_LOCAL_SHA`;
- `F04_U1_P2_SAVED_SHA_CHANGED=PASS_LOCAL_REPORTED`;
- `F04_U1_P2_SHA_AFTER_REOPEN_UNCHANGED=PASS_LOCAL_REPORTED`;
- `F04_U1_P2_CH05_POST_REOPEN_PROPERTY_READBACK=PENDING`;
- `F04_U1_P2_OVERALL=PARTIAL_PASS_PENDING_PROPERTY_READBACK`;
- `C2_MVP_NATIVE_POST_SELECTION_PHYSICAL=INCOMPLETE`;
- `C2_GUIDED_R2/C3/C4/LINK_KEY_CONTRACT/P5_GLOBAL/PHASE_IX/PRODUCTION=NOT_APPROVED`.

**Última evidência solicitável neste gate:** se o responsável ainda mantém a QVW fechada, basta abrir **somente** o mesmo QVW F04 TEMP, ir a `CH05 → Propriedades → Geral` e capturar a condição de cálculo completa, depois `Mensagens de erro → Condição de cálculo não satisfeita` e capturar a expressão `If(...)`. **Não editar, não aplicar, não executar filtros novamente, não recarregar, não salvar.** Se a configuração estiver íntegra, encerrar P2 sem repetir ano 2018. Se houver divergência, STOP e registrar. Nenhum merge, alteração de `main`, novo QVW ou expansão automática do escopo.
