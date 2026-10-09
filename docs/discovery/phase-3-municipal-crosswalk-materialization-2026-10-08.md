# Fase III-C5.2 — Referência municipal PB derivada (DATASUS6 ↔ IBGE7)

**Data:** 08/10/2026  
**Status:** `IMPLEMENTATION_READY / LOCAL_QV_RELOAD_AND_SHA_AUDIT_PENDING`  
**Branch:** `feat/phase-3-c5-2-municipal-pb-reference`  
**Aprovação:** registrada no checkpoint III-C5.1 do documento `phase-3-municipal-crosswalk-preflight-2026-10-08.md`.  
**Ferramenta obrigatória:** QlikView 12.

## 1. Fonte de verdade e escopo

**FATO VERIFICADO:** o preflight III-C5.1 foi executado no QlikView 12 em 08/10/2026 20:46:59 e confirmou:

- 223 municípios IBGE/PB com código completo oficial de 7 dígitos;
- 223 prefixos de 6 dígitos únicos, sem colisão;
- CNES/ST, CNES/LT, SIH/RD atendimento e SIH/RD residência na PB: **0 unmatched**;
- **5.202** registros RD com residência fora da PB, preservados sem população estadual atribuída;
- origem IBGE: três arquivos `BASE/IBGE/estimativa_dou_2017.xls`, `estimativa_dou_2018_20181019.xls`, `estimativa_dou_2019.xls`, lidos e versionados em `SRC_IBGE_POPULACAO.qvd` com 669 registros.

**DECISÃO APROVADA PELO RESPONSÁVEL:** a V1 pode materializar **somente os 223 pares municipais PB**, preservando o `COD_IBGE_7` extraído do arquivo oficial e usando o prefixo de seis dígitos como correspondente `COD_DATASUS_6` já testado em dados reais. **Não é uma tabela externa de equivalência publicada pelo IBGE/MS**, mas uma referência derivada pelo projeto sob fontes oficiais e controle de cobertura.

**Referência técnica IBGE:** <https://www.ibge.gov.br/explica/codigos-dos-municipios.php> e <https://www.ibge.gov.br/biblioteca/visualizacao/livros/liv101575.pdf>. As séries oficiais de XLS e o contrato de QVD estão em `phase-3-ibge-staging-implementation-2026-10-07.md`.

## 2. Implementação da Fase III (somente extração / staging)

`EXTRACAO/ext_main.qvs` inclui, **após `ext_c5_municipal_preflight.qvs`**, o novo `ext_c5_2_municipio_pb.qvs`.

Este script:

1. **Exige C5.1 PASS no mesmo reload**, 223↔223, zero unmatched PB nas fontes e 5.202 externos separados;
2. Recarrega do QVD IBGE oficial 669 linhas e confirma **3 anos e 3 fontes distintas por município**; recusa códigos que não sejam sete dígitos, PB `25`, ou pares 6↔7 que não sejam unívocos;
3. Gera uma linha por par `COD_DATASUS_6`, `COD_IBGE_7` com `UF=PB`, `FONTE_IBGE`, `ANOS_FONTE_IBGE`, `NATUREZA_REFERENCIA`, `METODO_CORRESPONDENCIA`;
4. Grava em `EXTRACAO/QVD/` dois artefatos locais: `REF_MUNICIPIO_PB_DERIVADA.qvd` e `REF_MUNICIPIO_PB_DERIVADA.csv`; não sobrescreve nenhum `SRC_*`;
5. Emite **apenas depois dos STOREs sem erro** o checkpoint parcial `_CHECKPOINT_EXTRACAO_C5_2_MUNICIPIO_PB.csv`, com 223 pares, 0 inválidos/sem cobertura, 5.202 residências externas preservadas e `phase_iii_status=IN_PROGRESS`.

`tools/audit_municipal_pb_crosswalk.py` (biblioteca padrão Python) audita os 223 pares, unicidade dos dois códigos, as colunas e os metadados, o checkpoint C5.1 e o C5.2, rejeitando arquivos anteriores à hora UTC registrada **antes do reload**. Calcula SHA-256 dos três arquivos XLS IBGE, `SRC_IBGE_POPULACAO.qvd`, QVD e CSV derivados e dois checkpoints; grava manifesto JSON local `BASE/REFERENCIAS/c5_2_municipio_pb_manifest.json`.

Os arquivos QVD/CSV derivados e manifesto local ficam fora do Git; scripts e esta documentação são versionados. Não implementar `DIM_MUNICIPIO`, `FATO_POPULACAO`, `LINK_ANALISE`, painéis ou referência nacional de moradores externos.

## 3. Gate local, pendente

Na raiz do repositório em uma árvore limpa, após atualizar main e obter a branch do PR:

```powershell
$reloadStartedUtc = (Get-Date).ToUniversalTime().ToString("o")
& "C:\Program Files\QlikView\Qv.exe" /r "$((Get-Location).Path)\EXTRACAO\EXT.qvw"
Get-Content .\EXTRACAO\QVD\_CHECKPOINT_EXTRACAO_C5_2_MUNICIPIO_PB.csv
.\.venv\Scripts\python.exe tools\audit_municipal_pb_crosswalk.py --since-utc $reloadStartedUtc
if ($LASTEXITCODE -ne 0) { throw "Auditoria municipal C5.2 falhou" }
```

**Critérios de sucesso exigidos, não declarados antecipadamente:**

- `PASS_PARTIAL_REFERENCE_PB_ONLY`: 669 linhas de fonte, 223 pares, 223 COD_DATASUS_6 e 223 COD_IBGE_7 únicos, 0 inválidos e 0 unmatched PB;
- `rd_residence_outside_pb_rows=5202`; nenhuma população PB imputada aos residentes externos;
- `PASS_LOCAL_REFERENCE_AUDIT` e manifesto com SHA-256 e caminho completo dos três XLS IBGE e QVDs;
- QVD `REF_MUNICIPIO_PB_DERIVADA.qvd` local presente, posterior ao início do reload, e checkpoint consistente.

**Falha:** interromper e analisar o erro; não fazer merge com testes pendentes/falhos nem assumir que um checkpoint antigo representa o novo reload.

## 4. Limites e próximos gates

- `III-C5.1=PASS_LOCAL_CANDIDATE_MAPPING`;
- `III-C5.2=IMPLEMENTED_CODE_LOCAL_TEST_PENDING`;
- `MUNICIPAL_PB_CROSSWALK_MATERIALIZATION=APPROVED_NOT_YET_VALIDATED`;
- `T29_HISTORICAL=NOT_APPROVED`;
- `PHASE_III=IN_PROGRESS`.

Após PASS real e merge: revisar lacuna de nomes históricos `201701–201705` conforme Boundary 5; reconciliar extração/QVDs T07/T08 e dependências efetivas de referências; somente após gate final da Fase III começar transformação dimensional. A primeira entrega acadêmica (Capítulos 1 e 2) permanece intocada.


## 5. III-C5.2 — resultado real da execução local (08/10/2026)

**FATO VERIFICADO — saída PowerShell enviada pelo responsável do projeto:** após checkout da branch `feat/phase-3-c5-2-municipal-pb-reference`, a variável `$reloadStartedUtc` foi registrada antes da execução de `Qv.exe /r .../EXTRACAO/EXT.qvw`. O comando `Get-Content .\\EXTRACAO\\QVD\\_CHECKPOINT_EXTRACAO_C5_2_MUNICIPIO_PB.csv` retornou:

```text
generated_at;stage;status;ibge_source_rows;bridge_pairs;distinct_datasus6;distinct_ibge7;invalid_pair_rows;st_unmatched_rows;lt_unmatched_rows;rd_attendance_unmatched_rows;rd_residence_pb_unmatched_rows;rd_residence_outside_pb_rows;reference_nature;phase_iii_status
08/10/2026 21:03:53;EXTRACAO_C5_2_MUNICIPIO_PB;PASS_PARTIAL_REFERENCE_PB_ONLY;669;223;223;223;0;0;0;0;0;5202;DERIVED_PB_REFERENCE_NOT_OFFICIAL_STANDALONE_TABLE;IN_PROGRESS
```

A auditoria real executada no Python 3 do ambiente `.venv`, com `--since-utc $reloadStartedUtc`, retornou **código de saída zero** (bloco PowerShell posterior de checagem de `$LASTEXITCODE` não gerou exceção) e:

```text
IBGE_OFFICIAL_XLS=3 HASHED
IBGE_STAGING_QVD_SHA256=252f7dfce384206751261b564d3b8111a79613d5b95501f9c34b6d0fe2cce70b
DERIVED_QVD_SHA256=93143c1124eac4dbab0822db610f9de86448752fb7994c8402b3e001849ae38e
DERIVED_CSV_SHA256=fdf016e4eaf7a7b8b396d3908da2ec6737944bc9aaf3e6018badb763725c257d
CROSSWALK_PAIRS=223 DISTINCT_DATASUS6=223 DISTINCT_IBGE7=223
PB_UNMATCHED=0 RD_RESIDENCE_EXTERNAL_PRESERVED=5202
REFERENCE_NATURE=DERIVED_FROM_OFFICIAL_IBGE_SOURCE_NOT_EXTERNAL_STANDALONE
PHASE_III=IN_PROGRESS T29_HISTORICAL=NOT_APPROVED
MANIFEST=BASE\\REFERENCIAS\\c5_2_municipio_pb_manifest.json
VERDICT=PASS_LOCAL_REFERENCE_AUDIT
```

**CONCLUSÃO DO GATE:** `III-C5.2=PASS_LOCAL_QV_AND_SHA_AUDIT`. Os 223 pares derivados `COD_DATASUS_6 ↔ COD_IBGE_7`, a unicidade, cobertura PB e metadados passaram na carga e no verificador local. A saída `REF_MUNICIPIO_PB_DERIVADA.qvd` e o CSV auxiliar tiveram a existência e integridade hash verificadas pela auditoria; esta verificação é baseada na **saída local fornecida pelo usuário**. Os hashes individuais dos 3 XLS foram **gravados no manifesto local**, mas seus valores não foram transcritos na saída enviada, e os arquivos binários não foram inspecionados independentemente neste chat.

**LIMITES:** a referência é **derivada pelo projeto**, não uma tabela oficial externa publicada; o recorte de cobertura é PB, não nacional. Os **5.202 registros de residência codificados como não-PB** permanecem fora da vinculação com população municipal PB, não são erros excluídos nem prova de cobertura nacional. Nenhum fato/dimensão/Link Table implementado. `PHASE_III=IN_PROGRESS`; `T29_HISTORICAL=NOT_APPROVED`.

**Próximo gate:** após revisão de escopo e merge do PR #72, avaliar documentalmente o tratamento de atributos históricos dos estabelecimentos conforme Boundary 5 (sem backfill de 201701–201705) e reconciliar os QVDs/checkpoints da Fase III. Não repetir a investigação de normas CNES para bloquear análises quantitativas independentes.
