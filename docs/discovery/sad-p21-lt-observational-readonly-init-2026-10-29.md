# SAD — P2.1 CNES/LT observacional — início do gate read-only

**Gate candidato:** `SAD-P21-LT-MONTHLY-OBSERVED-READONLY-01`  
**Data:** 29/10/2026  
**Estado:** `INIT_SOURCE_PROFILED_NO_GATE_EXECUTION`; os números de inspeção abaixo são `EXPERIMENTAL_NOT_GATE_EVIDENCE` até confronto por validador commitado e execução versionada.  
**Baseline:** `main@b644f70686ee825ae5356456cf3744f288407ad7` (merge confirmado de P1.4/PR #182); P1.5/E3 foi executado em branch separada e está em PR Draft #183, **não integrado** até comprovação Git.  
**Autoridade:** responsável solicitou prosseguir na sequência P1.4 → P1.5 → início de P2; restrito a inventário do insumo, perfil diagnóstico read-only e contrato do gate. Nenhuma carga, publicação, QVW/QVD/QVS, alteração acadêmica ou produção.

## 1. Objetivo delimitado

Iniciar **P2.1** conforme mapa vigente dos 14 visuais: série mensal observada CNES/LT de `qt_exist`, `qt_sus`, `qt_nsus`, por **competência** 201701–201912. Esse é o gráfico denominado `P2.2` **no histórico A0 R1**; `P2.2` atual é **outro visual**, de composição SUS/não SUS em uma competência explícita. Não somar os 36 pontos de snapshot como estoque de 2017–2019.

Sem autorização para chamar o recorte de **hospital-only**: `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; legenda de leitos `T29_HISTORICAL=NOT_APPROVED`. Não chamar `internações/leito` de ocupação ou deduzir taxas operacionais com E4.

## 2. Fonte real recebida e inspeção exploratória

- CSV anexado `lt_cnes_leito_competencia(1).csv`; 1.301.572 bytes; SHA-256 **MATCH AE01**: `BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88`.
- Campos exatos: `competencia;municipio_serv;cnes;tp_leito;codleito;linhas_lt;qt_exist;qt_sus;qt_nsus`.
- 35.518 linhas, 36 competências entre `201701` e `201912`; 35.518 combinações distintas de `competencia × municipio_serv × cnes × tp_leito × codleito` (0 duplicadas) na leitura exploratória do CSV.
- 105 códigos `municipio_serv` **observados no E4** e 233 códigos CNES distintos no intervalo. **Não** são um censo de todos os 223 municípios nem necessariamente estabelecimentos hospitalares.
- `qt_exist=qt_sus+qt_nsus` confirmado nas 35.518 linhas do arquivo.
- 3.561 pares `municipio_serv × competencia` com linha LT; desses, **3.464 pares `qt_sus>0`** e **97 pares `qt_sus=0` observados**. Referência histórica C4-F compreende grade 223×36=8.028 pares e 4.467 sem linha (`8028-3561`); **a grade de 223 municípios não foi novamente materializada/validada a partir do crosswalk nesta sessão**.
- Pontos mensais de controle exploratório: `201701`: `linhas_lt=1003`, `qt_exist=9597`, `qt_sus=7772`, `qt_nsus=1825`; `201912`: `linhas_lt=964`, `qt_exist=9065`, `qt_sus=7140`, `qt_nsus=1925`.
- Origem das contagens desta seção: inspeção Python ad hoc do **E4 original por SHA**, sem validador P2.1 versionado. Consequentemente não promover esses achados a `GATE_PASS`.

## 3. Contrato para execução P2.1 posterior

**Fonte única:** E4/AE01, SHA pinado. **Grão no extrato:** competência × município de atendimento × CNES × tipo × código de leito. **Medidas:** soma de `qt_exist`, `qt_sus` e `qt_nsus` **dentro de cada mês**; `linhas_lt` serve como volume de registros, não unidade de leito. A medida é snapshot de cadastro, e não leitos efetivamente ocupados/operantes.

**PASS restrito exige:** 
1. script validador commitado na branch **antes** de executar, com commit exato e hash de script; E4 presente, SHA idêntico, fonte original inalterada;
2. verificação de esquema, campos obrigatórios, tipos, competências 36/36, unicidade de grão, campos `qt_` não negativos, decomposição `qt_exist=qt_sus+qt_nsus` em todas as linhas, total de 35.518 linhas;
3. agregação de 36 linhas mês×`qt_exist/qt_sus/qt_nsus`; comparação contra série A0 R1 documentada, quando seus 108 oráculos ou arquivo de referência independente forem acessíveis; nunca tratar números citados isoladamente como confronto 108/108;
4. diferença entre **zero observado** (`qt_sus=0` para par com linha) e **sem linha LT** (ausência de par), usando o crosswalk 223 PB fisicamente verificado se for validar grade completa; sem materializar grade não afirmar cobertura física 8.028/8.028;
5. tabela e parecer numérico do P2.1 com competências explícitas, limites metodológicos, negativos para mutação de SHA, CSV/JSON/log apenas fora do Git e documentação de evidência em Discovery.

**BLOCKED:** insumo ausente/alterado, referência mensal indispensável inacessível ou crosswalk físico indispensável ausente para um teste que o exija.  
**HARD_STOP:** inconsistência material de medidas, grão, período ou total.  
**INCONCLUSIVE:** agregação possível sem comparação independente suficiente.  
**STOP:** após tabela dos 36 meses e decisão de suficiência P2.1. Não antecipar P2.2/P2.3/P2.4/P2.5, QlikView/COM, Fase IX, integração P1.5 nem painel final.

## 4. Estado dos gates e invariantes

- P1.3/E1: integrado anteriormente, PASS numérico restrito.
- P1.4/E2: integrado PR #182, PASS numérico restrito.
- P1.5/E3: PASS numérico restrito **em PR Draft #183**, sujeito a revisão/integração separada.
- **P2.1/E4: apenas iniciado/perfilado, sem gate PASS.**
- QlikView 12, três fatos, oito dimensões, esquema Star por processo/constelação e fluxo acadêmico obrigatórios.
- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `C2_FULL=NO_GO_NOT_APPROVED`, `T29_HISTORICAL=NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False` inalterados.
