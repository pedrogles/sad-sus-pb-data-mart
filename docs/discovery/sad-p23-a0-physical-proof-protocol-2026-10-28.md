# SAD-P2.3-A0-PHYSICAL-PROOF-01 — protocolo controlado

**Status:** PREPARED_ON_BRANCH / QLIK_NOT_RUN / VISUAL_NOT_TESTED.
**Permissão:** o responsável autorizou o próximo gate em 28/10/2026; **não** autorizou merge, produção, Fase IX, A1, QVD novo ou alteração da constelação.
**Origem:** `main@762d7503d222e10fff0bebce08ad1adf74fcbc89`; branch `feat/sad-p23-a0-physical-proof-01`.
**Ambiente físico:** Windows com QlikView Desktop 12/COM e interface interativa; não está disponível no ChatGPT remoto.

## Objetivo e invariantes

Provar por **uma tentativa física** se um objeto Pivot Table sobre A0/16 tabelas representa o universo 223 municípios PB × 36 competências com ausências, zeros e positivos corretos. Reutilizar VI-P4/C4-F; não carregar `P4_MATRIX` no modelo, não criar fato/dimensão/QVD, não alterar Link Table, RN21/V2, QVWs originais nem outros 13 visuais. Permanecem independentes G1/#157, C2, P5/D2, T29, Link Key global, Fase IX e produção.

Fontes: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → `docs/project/analytical-consumption-architecture-approval-2026-10-27.md` → `docs/project/agent-model-routing.md` → `PAINEL/phase_vii_technical_model.qvs` → `TRANSFORMACAO/vi_p4_municipal_coverage.qvs` → `docs/discovery/phase-8-c4f-vi-p4-export-readback-2026-10-21.md` → V2 §62 e Boundary 7.

## 1. Preparo único do QVW descartável

Utilizar checkout da branch em commit fixado, com 22 QVDs, três QVWs canônicos e crosswalk nos caminhos reais. EvidenceRoot deve ser pasta **nova**, filha de diretório persistente previamente existente fora de repositório e TEMP. O executor é novo porque o runner da Fase VII é pinado à branch histórica e A0 R1 não pode ser repetido por inferência.

~~~powershell
$Root = (Get-Location).Path
$Head = (git rev-parse HEAD).Trim()
$EvidenceRoot = '<DIRETORIO_PERSISTENTE_FORA_REPO_E_TEMP>\P23_A0_R1'
powershell.exe -NoProfile -File tools\Invoke-SadP23A0PhysicalProof01.ps1 -Root $Root -ExpectedCommit $Head -EvidenceRoot $EvidenceRoot -ExecutionAuthorizationRef 'chat-2026-10-28-p23-a0' -Prepare
~~~

O executor carrega o modelo técnico VII **sem alterações**, produz QVW apenas em TEMP, preserva log nativo e hashes de entradas em EvidenceRoot. Saída de preparo: `TEMP_MODEL_PREPARED_P23_VISUAL_NOT_TESTED`. O preparo **não cria objeto gráfico nem comprova P2.3**. Em falha de preflight/log/hash, STOP sem retry.

Abrir no QlikView 12 apenas o `TEMP_QVW` reportado; **nunca** salvar `PAINEL/PAINEL.qvw` nem qualquer QVW canônico.

## 2. Ensaio manual A0 (um único objeto)

Criar uma **Pivot Table** temporária com:
- dimensão de linha: campo existente `SERV_COD_DATASUS_6` (serviço/localização);
- dimensão de coluna: `PERIODO_COMPETENCIA` (mensal `201701` a `201912`);
- recorte dos **223 municípios PB** confirmado contra universo de C5.2/VI-P4, não presumido pela existência de `SERV_UF` ou `Show All Values`;
- seleções neutras no cenário N0; sem resolver uma falta de par por associação adicional.

Testar e fotografar opções QlikView 12 `Populate Missing Cells`, `Show All Values`, `Suppress Zero-Values` e `Suppress Missing`. A documentação oficial do QlikView confirma que `Populate Missing Cells` pode mapear combinações faltantes para NULL e que `Show All Values` pode mostrar valores excluídos. Isso **não garante** 8.028 células no modelo atual nem prova ausência da fonte. Fonte: https://help.qlik.com/en-US/qlikview/September2025/Subsystems/Client/Content/QV_QlikView/Pivot_Table.htm (descrições de Presentation e Dimensions, conferidas em 28/10/2026).

Expressões de **ensaio**, não aprovadas como medidas oficiais:
1. linhas: `Count(SK_REGISTRO_CAPACIDADE_LEITO)`;
2. SUS: `If(Count(SK_REGISTRO_CAPACIDADE_LEITO)=0,Null(),Sum(QTD_LEITOS_SUS))`;
3. existentes: `If(Count(SK_REGISTRO_CAPACIDADE_LEITO)=0,Null(),Sum(QTD_LEITOS_EXISTENTES))`;
4. estado: `If(Count(SK_REGISTRO_CAPACIDADE_LEITO)=0,'ABSENT_NOT_ZERO_PROVEN',If(Sum(QTD_LEITOS_SUS)=0,'OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED','OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED'))`.

Estas expressões só são semanticamente defensáveis em contexto neutro ou sob seleção controlada/reconciliada de município SERV e competência. Em filtro incompatível, um `Count=0` **não comprova ausência de LT na fonte**. Se o QlikView não avaliar a expressão na célula faltante, esse comportamento é evidência de limite A0, não motivo para imputar zero.

## 3. Cenários obrigatórios

| Caso | Contexto | Resultado exigido |
| --- | --- | --- |
| N0 | Sem seleções | 223 municípios PB × 36 competências = **8.028 pares únicos**; nenhuma linha ou competência fora do universo |
| N1 | SERV `251740`, mês `201701` | Linha LT ausente; `ABSENT_NOT_ZERO_PROVEN`, medidas NULL (nunca zero) |
| N2 | SERV `250460`, mês `201701` | 1 LT, SUS=0, existentes=40; zero SUS **observado** |
| N3 | SERV `250010`, mês `201701` | 3 LT, SUS=20, existentes=20; positivo observado |
| F1 | Município SERV e competência válidos | Recorte correto; sem perda de significado de zero/ausência |
| F2 | Seleções RES, procedimento, diagnóstico ou campo exclusivo de outra fato | Não converter exclusão associativa em ausência LT; bloquear, isolar explicitamente ou indicar indisponibilidade **com prova** |
| F3 | Ano e competência contraditórios | Não descartar intenção silenciosamente; registrar limite V2/D2 sem alegar C2 global |

`ZERO_REAL_COMPROVADO=NOT_PROVEN` e `COBERTURA_HOSPITALAR=NOT_VERIFIED` em todo universo. Não somar snapshots mensais como capacidade anual.

## 4. Reconciliação e evidências

Usar o **TXT histórico** `municipio_mes_observabilidade.txt` de VI-P4/C4-F como oráculo, sem regenerá-lo. A exportação do objeto deve permitir conferência de **cada par município×competência**, classe e NULL. Se exportação de Pivot Table eliminar células, não declarar PASS; registrar `INCONCLUSIVE_EXPORT`.

Controles obrigatórios: 8.028 pares (223×36); 4.467 ausentes; 97 zeros SUS observados; 3.464 positivos; 3.561 pares com linha; soma das linhas LT 35.518. Somas dos snapshots observados somente para reconciliação: SUS 270.076, existentes 337.147. C4-F traz 669 municípios×ano e 36/36 agregações mensais reconciliadas; não precisam ser reexecutados.

Gravar em EvidenceRoot, **fora do Git**: propriedades do pivot, screenshots com seleções visíveis N0/N1/N2/N3/F1/F2/F3, exportação completa quando disponível, reconciliação exportação×C4-F (todos os pares, não só amostras), diagnóstico de inconsistência, versão do QlikView, caminhos, hashes e observação de revisão humana. PNG isolado não homologa semântica nem UX.

Após fechar QVW de ensaio, no **mesmo commit**:

~~~powershell
powershell.exe -NoProfile -File tools\Invoke-SadP23A0PhysicalProof01.ps1 -Root $Root -ExpectedCommit $Head -EvidenceRoot $EvidenceRoot -ExecutionAuthorizationRef 'chat-2026-10-28-p23-a0' -Verify
~~~

`-Verify` somente confere os SHA dos QVDs/QVWs/crosswalk e registra o SHA final do QVW descartável em `temp_qvw_at_verification.json`, vinculando-o ao manifesto da preparação. Exige que o QVW TEMP ainda exista e não sobrescreve evidência anterior. **Não** aprova exportação, expressões ou gráficos.

### Critérios de parada

- **PASS_LOCAL_A0_P23_CANDIDATE_ONLY**: preparo QVW técnico comprovado sem alerta associativo; 8.028 pares exportados e reconciliados, incluindo três classes e três casos; comportamento F1–F3 documentado e sem falsas ausências; hashes preservados e revisão das provas. PASS de candidato, não produção.
- **BLOCKED**: células ausentes, classe incorreta, seleção global mascarada como ausência, impossibilidade de delimitar os 223 PB ou divergência de oráculo.
- **INCONCLUSIVE**: Windows/Qlik indisponível, ausência de exportação fiel, evidência visual insuficiente.
- **HARD_STOP**: escrita em artefatos protegidos, SHA divergente, necessidade de alterar arquitetura/semântica ou falta de permissão.

**STOP:** se A0 falhar por evidência concreta, apenas recomendar novo gate separado A1 lógica. Não implementar A1 por decorrência, não publicar novo QVD, não iniciar Fase IX, não declarar G1/C2/Link Key aprovados, não fazer merge automaticamente.
