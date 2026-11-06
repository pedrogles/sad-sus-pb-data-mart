# SAD — Revisão independente offline do XML forense C2-R2 F1/F2

**Data da análise:** 05/11/2026 (registro da execução reportada em UTC: 2026-11-06 02:17:32)
**Natureza:** análise estática independente de ZIP/CSV/JSON/XML enviado pelo operador; **não é execução COM, aceite visual novo ou decisão de produção**.
**Gate de origem:** `SAD-C2-R2-FINAL-QVW-FORENSIC-READONLY-01`
**RunId:** `SAD_C2_FINAL_8150831b62bd47a5b0c18cae8f5e6321`
**Git HEAD reportado:** `c821e92bb5dd95d97e5b708a251b82b39679f256` (commit local; integração em `main` não verificada).
**Fontes lidas:** ZIP fornecido pelo operador contendo `source_objects.csv`, `target_objects.csv`, `final_forensic_report.json`, `source_layout.xml`, `target_layout.xml`; capturas pós-reabertura de SH02/SH03 fornecidas nesta conversa; contrato D2-R2/V3, `AGENTS.md` e status operacional de `main@0549e1d...` consultados anteriormente.

## 1. Integridade da evidência

| Checagem | Evidência | Resultado |
|---|---|---|
| ZIP SHA-256 | `3B713B71F6FC214A4BBADD3BF3626ED7026BD320DCD5E88886D3268B7CE5F335` | Corresponde ao hash reportado pelo Windows |
| Teste CRC | `zipfile.testzip() = None` | PASS |
| Layout de origem | SHA-256 `885AB1AB8E443C5405CB9D9BDB32E5800115C4F3700415829561B01A13CB741C` | Corresponde ao `final_forensic_report.json` |
| Layout final | SHA-256 `89C01A78A4C4EEA231E0CA7FD933050E189202556063DB35134930884254CD38` | Corresponde ao relatório |
| QVW origem | SHA reportado `C1EA8F471C5FCA0412FDDBC92597FD06982BC4CD35099554CE51F92C573A7F1D` | Integridade de bytes **local reportada**, não releitura do QVW nesta análise |
| QVW final | SHA reportado `6CD9A8E2177CF1446EB4FAEA9842451FA9273F8832DBAFD1D73E23A2619B3A58` | Integridade de bytes **local reportada**, não releitura do QVW nesta análise |
| 25 protegidos | `Protected25Unchanged=true` no runner | PASS local reportado; bytes não disponíveis neste ZIP |

## 2. Inventário e delta de propriedades por Object ID

- Origem: **38 objetos**; destino: **38 objetos**.
- Não há objetos adicionados, removidos ou com tipo alterado.
- **35 de 38 objetos mantêm a árvore de propriedades intrínsecas idêntica** após normalização de whitespace XML estrutural.
- Os **3 objetos modificados** são exatamente `CH02`, `CH03` e `TX17`:

| Objeto | Delta confirmado no XML | Classificação |
|---|---|---|
| `CH02` | Definição da medida em dois pontos do XML passou de `=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)` para `=Sum({$<PERIODO_ANO={2017,2018,2019},PERIODO_COMPETENCIA=>} QTD_INTERNACAO)`; `ActivePropertyPage: 1 → 3`. | **Mudança funcional esperada**, com estado de editor não semântico |
| `CH03` | `GraphLayout/Frame/Name` e `GraphLayout/WindowTitle` passaram de texto fixo **2019** à expressão que usa `GetSelectedCount(PERIODO_ANO)` e `Num(Only(PERIODO_ANO),'0000')`; `ActivePropertyPage: 12 → 0`. | **Mudança funcional esperada**, com estado de editor não semântico |
| `CH03` | `GraphLayout/Frame/Color/PrimaryCol`: RGB **(4,108,193) → (232,232,232)**; `SecondaryCol`: RGB **(0,0,0) → (200,200,200)**. | **Mudança visual adicional não descrita como requisito da correção do título**. Requer decisão explícita de aceitar ou corrigir; pode ser alteração de metadado sem efeito renderizado na configuração corrente, não inferir sem verificar. |
| `TX17` | Expressão de indisponibilidade tornou-se condicional: contexto `EVOLUCAO`, ano real/proposto compatível e seleção mensal levam ao aviso; sem mês, retorna texto vazio; contexto fora do microteste retorna `CH03: contexto fora da validação F1/F2.` | **Mudança funcional esperada** |

Não foram encontradas outras alterações no `DocInternals/ObjectPool` nem nas seções `VariableProperties`, `FieldProperties`, `DocUserPermissions`, `BinaryAlternateStateStates` ou `TextualAlternateStateStates` exportadas. `DocProperties/FileName` difere apenas pelos nomes das **cópias forenses** `source_audit_copy_readonly.qvw` e `target_audit_copy_readonly.qvw`.

## 3. Geometria, ordem de apresentação e risco residual

As três folhas contêm, respectivamente, **13, 17 e 8 frames**. O conjunto de IDs por folha é idêntico entre origem e destino. Ao comparar cada frame por **ObjectId**, ignorando somente `InternalCtlNo`, **todos os 38 frames são idênticos**, incluindo `Rect` (posição, largura, altura) e `ZedLevel`.

| Folha | Ordem `LegacyObjectZOrder` | Inversões de pares na ordem | Pares com interseção geométrica e ordem invertida | `InternalCtlNo` alterados |
|---|---|---:|---:|---:|
| SH01 (índice 0) | Idêntica | 0 | 0 | 0 |
| SH02 (índice 1) | Reordenada | 66 | **9** | 15 |
| SH03 (índice 2) | Reordenada | 10 | **7** | 6 |
| **Total** | | **76** | **16** | **21** |

Pares com ordem invertida e retângulos intersectados:
- **SH02:** `TX16–TX15`, `TX16–TX09`, `TX16–TX08`, `TX15–TX07`, `TX15–TX08`, `TX07–TX08`, `TX09–TX08`, `BU16–MB01`, `MB01–BU03`.
- **SH03:** `TX14–TX13`, `TX14–TX11`, `TX14–TX12`, `TX14–TX10`, `TX13–TX11`, `TX11–TX12`, `TX12–TX10`.

**Interpretação:** os números acima são *deltas de serialização de ordem*, não prova de que 16 pares estão visualmente sobrepostos de forma errada: `ZedLevel` é idêntico por objeto, e as capturas SH02/SH03 após reabertura não evidenciam falha grosseira. Ainda assim, como há interseções reais de retângulos e inversões de ordem, **não é defensável declarar identidade integral do layout ou ausência garantida de efeito visual** sem aceite explícito da diferença.

## 4. Resultado por camada

| Dimensão | Veredito |
|---|---|
| Integridade ZIP, CRC e hashes de XML | `PASS_OFFLINE_INDEPENDENT` |
| Inventário por ID/tipo | `PASS_38_OF_38_NO_ADDED_REMOVED` |
| Preservação das 35 propriedades intrínsecas de objetos fora do escopo | `PASS_STATIC_OBJECT_POOL` |
| Delta funcional CH02, CH03, TX17 | `MATCHES_EXPECTED_CANDIDATE_CHANGES` (sem validação numérica nova) |
| Geometria e `ZedLevel` por ObjectId | `PASS_38_FRAMES_UNCHANGED` |
| Frame colors CH03 | `PRESENTATION_DRIFT_REVIEW_REQUIRED` |
| `LegacyObjectZOrder` SH02/SH03 | `REORDERED_16_OVERLAPPING_PAIR_INVERSIONS_REVIEW_REQUIRED` |
| Evidência pós-reabertura | `PASS_VISUAL_RESTRICTED_CHAT_EVIDENCE` (não atesta todos os estados/rotas nativas) |
| Contagem de Saves | `UNVERIFIED` |
| Reconciliação tabular mensal (36/12 competências) da TEMP final | `NOT_PERFORMED_IN_THIS_REVIEW` |
| Gate forense estrito | **`INCONCLUSIVE_PRESENTATION_DELTA_PENDING_EXPLICIT_ACCEPTANCE`** |
| C2-R2 integral, C3, C4, produção | **Não aprovados** |

## 5. Ação mínima recomendada e STOP

1. **Não repetir Prepare, Verify, recarga ou os ensaios F1/F2** já concluídos; não editar QVW no próximo passo.
2. Formalizar decisão específica sobre **mudança de cor do frame CH03** e **reordenação de empilhamento** nas SH02/SH03, apoiada nas capturas pós-save existentes. Uma inspeção visual adicional somente se o responsável considerar a prova insuficiente; delimitá-la a pares sobrepostos identificados e não fazer Save.
3. Se aceitas como metadados de apresentação sem regressão perceptível, registrar o aceite **restrito** do delta forense, preservando as limitações (Save count e reconciliação mensal). Se não aceitas, abrir correção **separada** versionada e protegida, sem sobrescrever a TEMP já auditada.
4. Versionar este relatório como complemento documental do closeout na branch de teste após revisão do responsável. Não promover automaticamente a `main`; não liberar C3 pela conclusão de um microgate F1/F2.
5. Para aceite C2-R2 global, a matriz residual da Issue #196 ainda demanda evidências proporcionais de prevenção guiada e revalidação pós-seleção nativa **por indicador**; não antecipar C3/C4, nem confundir variáveis propostas com seleção real.

**Condição de parada desta análise:** auditoria independente offline concluída. Nenhum QVW, QVD, Git remoto ou runner foi alterado. A comparação foi feita diretamente com o pacote XML/CSV/JSON e os screenshots enviados; não foi realizada execução física adicional ou reconciliação de dados brutos.
