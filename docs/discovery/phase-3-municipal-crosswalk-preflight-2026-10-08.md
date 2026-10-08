# Fase III-C5 — Discovery de correspondência municipal DATASUS ↔ IBGE

**Data:** 08/10/2026  
**Status:** `PILOT_CODE_PREPARED / LOCAL_QLIK_RELOAD_PENDING`  
**Ferramenta de validação:** QlikView 12; scripts externos versionáveis no repositório.

## 1. Contexto e evidência anterior

**FATO VERIFICADO:**

- O usuário executou `git pull --ff-only origin main` até `8b6c7ce` e listou `BASE/REFERENCIAS` filtrando por `municip|ibge|datasus|cod`. **Nenhum nome listado correspondeu a uma tabela de ponte municipal**. A consulta por nome **não é uma auditoria exaustiva do diretório ou de outros locais**.
- III-B IBGE já carregou **três XLS oficiais** (`estimativa_dou_2017.xls`, `estimativa_dou_2018_20181019.xls`, `estimativa_dou_2019.xls`) no QVD `SRC_IBGE_POPULACAO.qvd`, com **669 linhas, 223 municípios PB × 3 anos**, fonte documentada em `docs/discovery/phase-3-ibge-staging-implementation-2026-10-07.md`.
- `COD_IBGE_7` no staging foi formado por **componentes explícitos** `COD. UF` (2) + `COD. MUNIC` (5) dos próprios XLS oficiais, e **não** pelo cálculo do último algarismo a partir do DATASUS.
- O Ministério da Saúde documenta uso de códigos IBGE de **6 dígitos** em mapas DATASUS/TabWin (Série Geoprocessamento, v.1, cap. 3, `https://bvsms.saude.gov.br/bvs/publicacoes/serie_geoproc_vol_1.pdf`).
- O IBGE especifica códigos de municípios de **7 dígitos** e divulga listas oficiais: `https://www.ibge.gov.br/explica/codigos-dos-municipios.php`. A versão 2019 dos códigos municipais também está documentada em `https://www.ibge.gov.br/geociencias/organizacao-do-territorio/malhas-territoriais/15774-malhas.html?edicao=27733`.
- Boundary 7 exige chave municipal canônica `COD_DATASUS_6` e correspondência a `COD_IBGE_7` **a partir de referência validada**, sem fabricar o sétimo dígito. Boundary 3 registra cobertura interna SIH↔CNES, mas sua checagem não substitui auditoria byte a byte DATASUS↔IBGE.

## 2. HIPÓTESE DE MODELAGEM / PROPOSTA DE TESTE

Testar se **os primeiros seis caracteres dos códigos oficiais completos IBGE de 7 dígitos** correspondem aos códigos DATASUS de 6 dígitos já observados nos QVDs SIH e CNES. Essa operação **não gera nem adivinha o sétimo dígito**: mantém o IBGE7 oficial recebido de fonte primária, e utiliza seu prefixo 6 **apenas como chave candidata**, condicionada a prova empírica de unicidade e cobertura.

**Não declarar equivalência oficial já aprovada** simplesmente por semelhança de dígitos. Verificar:

1. QVD IBGE: 669 municípios×ano únicos; 3 anos; 223 códigos completos únicos; prefixos de 6 caracteres também 223 únicos e sem ambiguidades;
2. CNES/ST: 220.390 linhas e 223 códigos distintos `CODUFMUN`, todos com seis dígitos e presentes entre os 223 prefixos oficiais;
3. CNES/LT: 35.518 linhas, códigos `CODUFMUN` de seis dígitos, zero sem correspondência;
4. SIH/RD: 566.672 linhas, `MUNIC_MOV` seis dígitos e todos correspondentes ao universo PB;
5. SIH/RD residência: municípios de PB (`MUNIC_RES` iniciando em `25`) devem todos corresponder; municípios de **fora da PB** devem ser contados separadamente, **não ligados à população PB** ou classificados como erro por não pertencerem aos 223 códigos;
6. em caso de qualquer falha, manter C5 `REVIEW_REQUIRED`, sem produzir ponte QVD, fatos, dimensão ou ligações artificiais.

**DECISÃO PENDENTE:** após resultados locais, decidir se essa correspondência de fonte IBGE oficial + campo DATASUS real, validada 1:1 e 100% no universo PB, atende à exigência documental do Boundary 7 para materializar a referência, ou se ainda é necessária uma tabela oficial de equivalências explicitamente pareadas. Não alterar a modelagem acadêmica sem decisão.

## 3. Implementação de piloto controlado

- `EXTRACAO/ext_c5_municipal_preflight.qvs`: inclusão no fim de `EXTRACAO/ext_main.qvs`.
- Entradas: **somente QVDs existentes**, `SRC_IBGE_POPULACAO.qvd`, `SRC_CNES_ST.qvd`, `SRC_CNES_LT.qvd`, `SRC_SIH_RD.qvd`; não adquire dados externos nem altera QVDs `SRC_*`.
- Processamento: ler apenas os códigos oficiais IBGE7; testar candidatos seis dígitos e a cobertura real das fontes, inclusive a separação PB versus residência externa.
- Saída de auditoria **somente se PASS**: `EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_MUNICIPAL_PREFLIGHT.csv`; campo `official_bridge_status=NOT_YET_MATERIALIZED`. Falha deve abortar o reload sem emitir o checkpoint.
- Não materializar uma referência municipal oficial antes dos testes; não construir `DIM_MUNICIPIO`, `FATO_POPULACAO`, `LINK_ANALISE` nem alterar chaves dos fatos.

## 4. Evidência local aguardada

No Windows, em `main` limpa, obter a branch do PR e recarregar `EXTRACAO/EXT.qvw`. Inspecionar:

```powershell
Get-Content .\EXTRACAO\QVD\_CHECKPOINT_EXTRACAO_MUNICIPAL_PREFLIGHT.csv
```

**Esperado, ainda NÃO observado**: `PASS_CANDIDATE_MAPPING_ONLY`, 223 IBGE7 únicos/223 prefixos6 únicos, ST distinct=223, 0 unmatched nas três famílias PB e nas residências PB, residentes externos mantidos separados. Se a saída falhar, obter diagnóstico do log QlikView 12. **Não declarar III-C5 PASS antes da evidência real**.

## 5. Limites e sequência

O C5 não reabre III-A/B/C1/C2/C3/C4 já aprovados. `T29_HISTORICAL=NOT_APPROVED` permanece. Após o piloto C5, submeter o resultado de correspondência municipal à decisão de aceitação, materializar ponte somente se aprovada e inspecionar o gate histórico de estabelecimentos conforme Boundary 5. A Fase III permanece `IN_PROGRESS` até reconciliação final do Boundary 7.
