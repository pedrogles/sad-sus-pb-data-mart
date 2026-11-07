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
