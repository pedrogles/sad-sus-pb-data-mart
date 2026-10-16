# Fase VI — Regularizacao de versionamento de preflights (PR Draft)

**Objetivo unico:** recuperar rastreabilidade dos executores VI-P1 a VI-P4 no Git, a partir dos pacotes locais efetivamente distribuidos em 16/10/2026. Nao muda a arquitetura, os QVDs, as tres fatos, a semantica V2, a Link Table, os QVWs originais ou os resultados previamente reportados.

## Origem e cadeia de confianca

- Base: `main` `ad37e6f3947208eef5d7f4455b1172ded9999170`, revisao em 16/10/2026.
- VI-P1: pacote final **R2**, PASS local read-only restrito reportado pelo responsavel.
- VI-P2: pacote final original, PASS local read-only restrito reportado.
- VI-P3: pacote final **R4**, PASS local de candidatos numericos T24-T26 limitado a Joao Pessoa/2018 e setembro/2018; previa discrepancia por `Aggr()` detectada e candidata reconciliada, **nao** homologada para cobertura generica.
- VI-P4: pacote preparado, **NAO EXECUTADO**; somente revisao estatica e agora versionamento candidato. A matriz de 223 municipios × 36 competencias classifica observacoes, nunca comprova zero real ou cobertura hospitalar.
- A auditoria de stdout/log relatada nas conversas precedentes **nao equivale** a auditoria independente dos QVDs binarios, do conjunto de evidencias local ou da aplicacao final.

Os QVS dos pacotes finais foram copiados sem mudanca de conteudo. Os executores PS1 foram adaptados exclusivamente para ler o QVS versionado de `TRANSFORMACAO/`, e um preflight `VI-GOV` garante `HEAD` Git identificavel, dois arquivos tracked e sem alteracoes locais antes de executar; estes PS1 adaptados **nao foram executados em Windows**. Requer smoke de VI-P4 ao retomar; nao repetir VI-P1 a P3 apenas para alterar layout de arquivos.

## Arquivos e execucao

| Gate | Executor em `tools/` | QVS em `TRANSFORMACAO/` | Situacao |
|---|---|---|---|
| VI-P1 | `Invoke-SadViP1Readonly.ps1` | `vi_p1_readonly.qvs` | PASS local do pacote R2; layout Git ainda nao reexecutado |
| VI-P2 | `Invoke-SadViP2Readonly.ps1` | `vi_p1_readonly.qvs` (reutilizado) | PASS local do pacote original; layout Git ainda nao reexecutado |
| VI-P3 | `Invoke-SadViP3Readonly.ps1` | `vi_p3_source_reference.qvs` | PASS local do pacote R4; layout Git ainda nao reexecutado |
| VI-P4 | `Invoke-SadViP4Readonly.ps1` | `vi_p4_municipal_coverage.qvs` | **NOT_RUN** |

### SHA-256 exato dos QVS (congelado dos pacotes locais)

- `vi_p1_readonly.qvs`: `80E80770C59FBCC48142DA8E4CE6BF87D3CD6113FCACE977E0DACEA0CA78558B` (P1+P2).
- `vi_p3_source_reference.qvs`: `FA0F0D4E263CC9793AA6ED2403BF3849BE47D8F095A59E3BB9FA234708071BEF`.
- `vi_p4_municipal_coverage.qvs`: `A2153E27E08CF2F236BCF07F6A7D7D99AE682446D7E37D3F3E5C0D609D734EE5`.

### VI-P4 — executar APOS revisar o PR e conferir branch/working-tree

Na raiz local do clone da branch do PR (NAO use ZIP como codigo):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Invoke-SadViP4Readonly.ps1 -Root (Get-Location).Path -RunQlik
```

Precondicoes: Git no PATH, Windows com QlikView 12 COM, 21 QVDs locais previamente protegidos, branch atual confirmada, executores e QVS rastreados/sem alteracoes. Runner cria somente QVW/log, manifests e tres TXT temporarios em `%TEMP%`; 3 `STORE ... (txt)` exclusivos da evidencia, **nenhum STORE QVD**. `TRANSF.qvw` e `PAINEL.qvw` nao sao recarregados. Rodar **uma vez**, anexar stdout/log e PARAR. Em BLOCKED, investigar antes de novo teste.

## Escopo de criterio de aceite e saida

- PASS desta regularizacao: branch + PR Draft com os quatro PS1 e tres QVS textuais; QVS com SHA identico aos pacotes; preflight de Git; nenhuma mudanca em dimensoes/fatos ou QVD; regra de versionamento no `AGENTS.md` proposta; **sem merge**.
- P4 experimental PASS futuro: 8.028 celulas municipio/competencia reconciliadas com staging e fato, observadas/ausentes sem imputacao de zero, 21 QVDs inalterados, tres TXT temporarios; nao certifica cobertura hospitalar.
- P4 BLOCKED se QVD mudou, cardinalidade nao bate, Qlik falha, evidencia nao contemporanea ou reprovacao de semantica; nao repetir automaticamente.
- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `T29_HISTORICAL=NOT_APPROVED`, `PRODUCTION_APPROVED=False`.

**STOP**: encerrar regularizacao ao abrir PR Draft. Rodar VI-P4 somente depois que o responsavel conferir o PR/branch e solicitar expressamente; merge depende de aprovacao separada.
