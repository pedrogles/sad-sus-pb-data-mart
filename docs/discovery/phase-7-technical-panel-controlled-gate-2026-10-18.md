# Fase VII — Gate controlado do painel técnico associativo

**Data de preparação:** 18/10/2026  
**Base congelada:** `main@dfc02527b3791a19bcf9d9db29cb3979061dea81`  
**Branch isolada:** `feat/phase-vii-technical-panel-gate-20261018`  
**Status:** `CODE_COMMITTED_STATIC_REVIEW_ONLY / QLIK_LOCAL_NOT_RUN`. Não afirmar PASS físico.  
**Autorização:** implementar e versionar antes de executar; inventariar 22 QVDs read-only; usar exclusivamente QVW descartável. **Sem merge, QVD/QVW original modificado, Fases VIII–IX ou KPIs.**

## Objetivo, fontes, invariantes e condição de parada

Objetivo único: testar a representação física QlikView 12 das três fatos, `LINK_ANALISE`, oito dimensões conformadas (doze instâncias associativas por role-playing) e controles T17–T23; não habilitar `PAINEL/painel_main.qvs` e não alterar scripts de Fase IV–VI.

Fontes: `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`, Boundaries 5/6/7, VI-P5, decisão semântica V2, execução VI-R2 e QVS versionados. Os 22 QVDs físicos e logs nativos ficam no Windows local, **não no GitHub**.

Invariantes: `FATO_INTERNACAO=566672`, `FATO_CAPACIDADE_LEITO=35518`, `FATO_POPULACAO=669`, `LINK_ANALISE=85705` chaves distintas/6 campos. Preservar 10 QVDs de extração e 12 de transformação, os QVWs canônicos, o hash congelado R2 `78FFA33DE82F5CB00DE1E0D380D96F29245B22801A91376CD61626E7AC8732DB`. Não regenerar `LINK_ANALISE`, não executar `TRANSF.qvw` ou `PAINEL.qvw`.

`STOP`: após inventário e uma tentativa local isolada obter PASS *candidato* ou BLOCKED documentado. Em falha preservar QVW/log/manifests e diagnosticar antes de mudar o código; nenhuma tentativa automática.

## Artefatos novos, somente na branch

- `PAINEL/phase_vii_technical_model.qvs`: modelo de teste, fonte QVD read-only, nenhuma instrução STORE/SQL/EXECUTE; população anual gera `%LINK_KEY` **somente em memória**, usando literalmente `Hash128('SAD-LINK-V1', 'C=N', Y, R, S, 'E=N')` e a serialização da VI-P1. Não carrega as SKs originais POP com nomes associativos.
- `tools/Invoke-SadPhaseViiTechnicalPanel.ps1`: compara os 22 headers/hashes (antes/depois), protege QVWs originais (EXT, TRANSF e PAINEL se presentes), confirma Git branch/HEAD e QVS/runner commitados e limpos. Por padrão apenas inventaria; `-RunQlik` cria QVW e log sob pasta aleatória em `%TEMP%` e executa uma recarga QlikView COM exclusivamente nessa cópia.
- Este documento registra contrato, limites e encaminhamento. `PAINEL/painel_main.qvs` permanece **intocado**.

O grafo alvo é uma árvore com 16 tabelas: 3 fatos + 1 Link + 4 papéis Tempo + 2 papéis Município + Estabelecimento + Procedimento + Diagnóstico + Caráter + Motivo + Tipo Leito. A Link Table relaciona-se às fatos exclusivamente via `%LINK_KEY`; dimensão compartilhada passa exclusivamente pelas cinco SKs da Link. Chaves clínicas exclusivas e `%SK_TIPO_LEITO` permanecem diretamente nas respectivas fatos. Nenhum objeto final.

## Verificações e nível de garantia

| ID | Evidência esperada | Restrição |
| --- | --- | --- |
| Inventário | 10 QVDs extração + 12 transformação, headers coerentes, SHA R2 e manifestos `before/after` iguais | Não prova corpo de QVD, salvo testes Qlik posteriores |
| T17/T18 | 100% de FI/LT com `%LINK_KEY`; POP 669 projeções correspondentes a Link | Não é contrato semântico definitivo |
| T19 | 0 links obrigatórios e dimensões órfãs; campos inaplicáveis nulos | Não generaliza norma CNES |
| T20 | QVS percorre `TableName()`: 16 tabelas, zero `$Syn` | Confirmar no Table Viewer |
| T21 | Runner rejeita avisos de loop/loosely coupled no log | Inspeção do Table Viewer obrigatória |
| T22 | 566.672 RD ↔ ST via `Hash128('ESTAB',CNES,COMPETENCIA)`, 0 unmatched | Histórico por competência, não CNES atual |
| T23 | 35.518 LT ↔ ST via `Hash128('ESTAB',CNES,COMPETEN)`, 0 unmatched | Histórico por competência, não CNES atual |
| Integridade | 22 QVDs e QVWs canônicos com hashes idênticos antes/depois | QVW de teste e log são os únicos artefatos de Qlik alterados |

A execução automatizada pode atingir **`PASS_LOCAL_ASSOCIATIVE_CANDIDATE_PENDING_TABLE_VIEWER`**, nunca `PRODUCTION_APPROVED`. A ausência de mensagem de loop em log não substitui a inspeção manual do Table Viewer. O T21 final exige prova física/visual das associações; o `LINK_KEY_CONTRACT` e o contrato de medidas permanecem `NOT_APPROVED` até aceites separados.

## Procedimento local (Windows, PowerShell e QlikView 12)

Na pasta raiz do clone, obter a branch remota criada no GitHub (não fazer merge):

```powershell
git fetch origin feat/phase-vii-technical-panel-gate-20261018
git switch --track origin/feat/phase-vii-technical-panel-gate-20261018
git status --short
```

Primeiro gate, **somente inventário** (sem iniciar QlikView):

```powershell
powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiTechnicalPanel.ps1 -Root (Get-Location).Path
```

**Somente se** `VERDICT=PASS_INVENTORY_ONLY_NOT_PHYSICAL_MODEL` e o commit versionado estiver confirmado, executar uma única recarga de teste:

```powershell
powershell.exe -NoProfile -File .\tools\Invoke-SadPhaseViiTechnicalPanel.ps1 -Root (Get-Location).Path -RunQlik
```

Coletar todo o stdout, caminho `EVIDENCE_DIR`, `TEMP_QVW`, log nativo, SHA-256 do script/runner e manifestos. Inspecionar em QlikView Desktop o **Table Viewer do arquivo TEMP_QVW**, sem abrir/salvar por cima do `PAINEL.qvw` canônico. Registrar também se o save do QVW de teste persistiu o modelo em memória. Não reenviar QVDs/QVWs originais ao Git.

**Pré-condições**: 22 QVDs nos diretórios aprovados; execução a partir do clone em branch correta, QlikView Desktop 12/COM para `-RunQlik`, Windows interativo quando revisão gráfica for feita. O runner para diante de incompatibilidade, não cria diretórios de produção nem tenta corrigir dados.

## Status do gate

- `BRANCH_CREATED=True`.
- `IMPLEMENTATION_SCRIPTS_VERSIONED=True` (confirmar SHA de commit exato antes da execução local).
- `STATIC_REVIEW=PERFORMED_CANDIDATE_ONLY`.
- `INVENTORY_22_QVD=NOT_RUN_LOCAL`.
- `QLIKVIEW_12_RELOAD=NOT_RUN_LOCAL`.
- `T17_T23_FINAL=NOT_APPROVED`.
- `TABLE_VIEWER_REVIEW=PENDING`.
- `LINK_KEY_CONTRACT=NOT_APPROVED`.
- `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`.
- `PRODUCTION_APPROVED=False`.
- `PR_MERGED=False`.

Nenhuma atualização operacional da `main` é autorizada nesta preparação. Para encerramento físico, o responsável deve fornecer as evidências nativas e decidir separadamente qualquer revisão/merge.
