# SAD-P2.3-A1-LOGICAL-DESIGN-01 — contrato lógico candidato (28/10/2026)

**Estado documental:** `DESIGN_READY_FOR_PHYSICAL_GATE` — especificação candidata, **não** execução, homologação física, aceite visual ou autorização de implementação.  
**Escopo:** somente P2.3, observabilidade CNES/LT de município PB × competência (2017–2019).  
**Modalidade de origem:** ChatGPT + GitHub, revisão estática/read-only da fonte; este PR publica apenas o documento.  
**Baseline consultado:** `main@762d7503d222e10fff0bebce08ad1adf74fcbc89` (28/10/2026).  
**Relacionamento:** [PR #167](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/167) — R1 A0 encerrada em `A0_NOT_VALIDATED` exclusivamente para P2.3; permanece Draft, sem merge.  
**Autorização:** responsável autorizou seguir com a formalização documental em contexto separado; **não** autorizou teste físico, criação de QVS/runner, QVD/QVW, Fase IX ou merge.

## 1. Objetivo e fronteira

Definir a **menor projeção lógica ilhada, em memória**, capaz de exibir inclusive pares município × competência **sem linha** LT, com as três classes do oráculo C4-F. A1 é uma superfície de apresentação para P2.3, **não** quarta fato, dimensão acadêmica, alteração da constelação, nova Link Key ou QVD materializado.

**Invariantes:** A0 continua padrão para os outros 13 visuais; preservar três fatos/oito dimensões, V2/RN21, Boundary 7, papel municipal SERV, 22 QVDs/3 QVWs canônicos e bloqueios científicos. `A0_NOT_VALIDATED` da R1 não significa impossibilidade universal de A0. Não repetir A0 R1, VI-P4, C4-F nem executar experimentos nesta documentação.

## 2. Base factual e qualificação de evidência

- **FATO VERIFICADO — inspeção estática em `main`:** [VI-P4](../../TRANSFORMACAO/vi_p4_municipal_coverage.qvs) constrói `P4_MUN` a partir dos códigos municipais de referência PB de `FATO_POPULACAO`, gera 36 meses, agrega LT por município/competência (`P4_LT_MONTHLY`), confere o match da chave temporária e produz `P4_MATRIX` com NULLs e três estados. O script VI-P4 inclui três `STORE` TXT para evidência; **não pode ser invocado integralmente como script de produção/consumo sem delimitação explícita**.
- **FATO VERIFICADO — inspeção estática em `main`:** [modelo técnico VII](../../PAINEL/phase_vii_technical_model.qvs) contém a constelação e aliases de papéis SERV/RES e tempo, mas **não** carrega `P4_MATRIX` como superfície de consumo. O modelo técnico tem 16 tabelas no teste histórico, antes da ilha.
- **EVIDÊNCIA HISTÓRICA DOCUMENTADA:** [C4-F](phase-8-c4f-vi-p4-export-readback-2026-10-21.md) reconciliou os TXT recebidos com **223 municípios × 36 competências = 8.028 pares únicos**; 4.467 sem linha LT, 97 com QT_SUS observado igual a zero e 3.464 positivos; 3.561 pares com linha e 35.518 linhas LT. Somas dos snapshots LT ao longo dos meses: QT_SUS=270.076, QT_EXIST=337.147 — **controles de reconciliação, jamais estoques anuais**. Sem auditoria independente dos QVD/QVW brutos nesta sessão.
- **EVIDÊNCIA HISTÓRICA REPORTADA — PR #167:** R1 A0 não apresentou grade/classificação completas; 26 artefatos protegidos reconciliados por hashes **pelo operador**, não auditados independentemente aqui. A correção posterior do executor do PR não foi reexecutada.
- **HIPÓTESE DE MODELAGEM:** uma tabela A1 sem campos associativos comuns pode representar a grade no QlikView 12 sem interferir na constelação. O comportamento concreto de seleção/renderização ainda exige teste físico.
- **DECISÃO PENDENTE:** autorização explícita de um único gate físico A1 e, depois, eventual aceite de apresentação; nenhuma das duas decorre deste documento.

## 3. Contrato candidato de grão, origem e campos

**Grão:** exatamente um registro por `município DATASUS6 PB (SERV/localização do LT) × competência CNES/LT mensal (YYYYMM)`, de `201701` a `201912`, com as duas coordenadas **normalizadas como texto**. Municípios de residência não substituem o papel SERV.

**Fonte do universo municipal:** `FATO_POP_DATASUS6_REFERENCIA_PB` da `FATO_POPULACAO`, deduplicada (`P4_MUN`); `POPULACAO_ESTIMADA` **não é uma medida da A1**. **Fonte temporal:** geração das 36 competências da `P4_MONTH_LIST`. **Observações:** LT staging (`CODUFMUN`, `COMPETEN`, `QT_SUS`, `QT_EXIST`), reconciliadas linha a linha com `FATO_CAPACIDADE_LEITO` pelos controles já existentes no VI-P4; agregação por par da `P4_LT_MONTHLY`.

**Proposta de tabela final:** `P23_A1_ISLAND` (nome **proposto**, inexistente na arquitetura atual). Seis campos finais, todos com alias **proposto** e exclusivo; à direita, os **nomes existentes** somente no procedimento VI-P4:

| Campo A1 proposto — NÃO físico existente | Origem lógica no VI-P4 | Finalidade |
| --- | --- | --- |
| `P23_MUNICIPIO_6` | `P4_MATRIX.MUNICIPIO` | Eixo e filtro local municipal |
| `P23_COMPETENCIA` | `P4_MATRIX.COMPETENCIA` | Eixo e filtro local temporal |
| `P23_LINHAS_LT` | `P4_MATRIX.LINHAS_LT` | Distinguir presença de linha |
| `P23_QT_SUS_OBSERVADO` | `P4_MATRIX.QT_SUS_OBSERVADO` | Valor SUS no recorte observado |
| `P23_QT_EXIST_OBSERVADO` | `P4_MATRIX.QT_EXIST_OBSERVADO` | Contexto de leitos existentes |
| `P23_ESTADO_OBSERVADO` | `P4_MATRIX.ESTADO_OBSERVADO` | Classe explícita por par |

A geração prévia usa `P4_PAIR_KEY = Hash128('P4-OBS',Trim(Text(MUNICIPIO)),Trim(Text(COMPETENCIA)))` como **chave técnica temporária** na junção, seguindo VI-P4. A chave **não integra** a tabela de apresentação, não é `%LINK_KEY` e não cria associação. Reutilizar a lógica, não copiar saídas TXT como verdade física permanente nem criar nova fonte de fatos.

**Semântica literal da classificação:**

| Classe | `LINHAS_LT` | `QT_SUS_OBSERVADO` | `QT_EXIST_OBSERVADO` |
| --- | --- | --- | --- |
| `ABSENT_NOT_ZERO_PROVEN` | NULL | NULL | NULL |
| `OBSERVED_ZERO_QT_SUS_SCOPE_UNVERIFIED` | >=1 | 0 | Valor observado, inclusive 0 se assim constar |
| `OBSERVED_POSITIVE_QT_SUS_SCOPE_UNVERIFIED` | >=1 | >0 | Valor observado |

Para os **8.028/8.028** pares, prevalecem as limitações `ZERO_REAL_COMPROVADO=NOT_PROVEN` e `COBERTURA_HOSPITALAR=NOT_VERIFIED`. São avisos/constantes semânticas exibidos no P2.3; não é necessário materializar dois campos extras repetidos. **Nenhum** NULL da classe ausente pode virar zero por `Alt()`, `RangeSum()`, expressão agregada, formatação ou exportação de tabela.

## 4. Contrato de isolamento e filtros

1. **Uma ilha lógica:** a projeção final usa aliases exclusivos `P23_*`, não carrega `%LINK_KEY`, SKs ou nomes compartilhados com fatos, Link Table, dimensões e campos `PERIODO_*`/`SERV_*`/`RES_*`. Eliminar estruturas intermediárias depois da projeção; `NOCONCATENATE` na eventual implementação para impedir autoconcatenação não intencional.
2. **Nenhuma associação permitida:** não adicionar relacionamento, ponte, dimensão/fato, chave sintética, loop, nem modificar o modelo técnico publicado. A eventual tabela ilhada é apenas uma superfície de leitura do P2.3.
3. **Filtros suportados no desenho:** município via `P23_MUNICIPIO_6` e competência via `P23_COMPETENCIA`, com seletores locais exclusivos da ilha. Seletor de ano, filtro SERV/RES do modelo global, link temporal global ou sincronização A0↔A1 **não fazem parte deste contrato**.
4. **Filtros globais não suportados:** seleções `SERV_COD_DATASUS_6`, `PERIODO_COMPETENCIA` ou outros campos globais **não devem redefinir o universo nem a classificação P23**. A UI deverá rotular a grade como **“filtros próprios de P2.3 — não sincronizados com filtros globais”**. Não inferir ausência de fonte de uma célula excluída pelo estado associativo da aplicação.
5. **Pendente de prova:** demonstrar que o mecanismo real de seleções QlikView 12 preserva essa independência, que todos os pares sem LT permanecem renderizáveis e que seus NULLs/estados aparecem corretamente; não presumir compatibilidade de UX nem seleção universal.
6. **Regra de exibição:** apresentar estado categórico mesmo onde a medida é NULL; evitar depender apenas de valor numérico em gráfico/pivô. Se o objeto escolhido suprimir pares NULL ou mostrar zero visual para uma ausência, ele **não atende ao contrato**. Não apresentar a soma dos 36 snapshots como capacidade anual.

A ausência de linha LT **não prova** ausência real de leitos. A leitura é *“observabilidade de registros CNES/LT, 2017–2019”*, não cobertura hospitalar completa, taxa de ocupação ou zero comprovado. A legenda histórica T29 segue não aprovada.

## 5. Riscos impeditivos e critérios de aceite para UM gate físico futuro

**Conclusão lógica:** nenhuma associação nova, quarta fato, alteração de constelação ou decisão semântica externa é exigida para **especificar** a ilha. Logo, não há bloqueio impeditivo do desenho. A materialização depende de autorização e teste, **não está liberada**.

**Gate futuro proposto (se autorizado separadamente):** `SAD-P2.3-A1-PHYSICAL-GATE-01`. Um único teste físico em QVW de **cópia temporária** no Windows/QlikView 12, com script/runner **previamente versionado e commit de origem fixado**. Não executar o VI-P4 completo indiscriminadamente, nem STORE QVD, reescrever binários canônicos ou repetir a R1. Registrar previamente hashes e preservar inventário protegido (22 QVD + 3 QVW + CSV conforme encerramento #167), com readback/hashes após o teste.

**Critérios `PHYSICAL_PASS` restritos a P2.3:**

- 223 municípios, 36 competências, 8.028 pares únicos sem duplicação/perda; 4.467 ausentes, 97 zeros SUS observados, 3.464 positivos.
- 3.561 pares com linha, soma `P23_LINHAS_LT=35.518`; somas dos snapshots SUS 270.076 e existentes 337.147 exclusivamente como checks de reconciliação (não valores anuais).
- Três amostras C4-F em `201701`: `251740` → ausente e todas as medidas/linhas NULL; `250460` → 1 linha, SUS=0, existentes=40; `250010` → 3 linhas, SUS=20, existentes=20.
- Controles locais município/competência conseguem exibir cada classe, inclusive ausência; o objeto de P2.3 não elimina pares NULL, não apresenta zero imputado e não traz competências externas ao horizonte.
- Seleção conflitante via filtro global SERV/tempo não transforma ausência em estado observacional nem altera números da ilha; seleção local P23 não interfere nas três fatos/demais visuais. Se comportamento não for demonstrável, registrar `BLOCKED`, nunca presumir isolamento visual.
- Table Viewer/inspeção de modelo sem `$Syn`, loops ou novos vínculos; apenas a ilha adicional pode aparecer no modelo de teste. O controle histórico de 16 tabelas de VII **não pode ser reutilizado sem distinguir esse caso experimental**.
- Artefatos protegidos com SHA-256 pré/pós reconciliados, nenhum QVD/QVW canônico sobrescrito. Confrontar resultado exportado da ilha com o oráculo C4-F sem reexecutar VI-P4.

**Falha em qualquer invariante:** `BLOCKED` para o uso do P2.3 nessa superfície; não criar automaticamente R2/R3, mudar a Link Key, alterar RN21/V2 ou remodelar fatos.

## 6. Veredito, pendências e STOP

**Veredito deste desenho documental:** `DESIGN_READY_FOR_PHYSICAL_GATE` — **não** `PHYSICAL_PASS`, `VISUAL_ACCEPTED`, `PRODUCTION_APPROVED` ou autorização física. **A1 permanece `NOT_IMPLEMENTED`**. PR #167 permanece Draft, `A0_NOT_VALIDATED` restrito à R1.

**Pendência decisória única para avançar:** autorização separada do responsável para implementar e executar o único gate físico `SAD-P2.3-A1-PHYSICAL-GATE-01`; aceite visual fica após prova física. `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`, `ZERO_REAL_COMPROVADO=NOT_PROVEN`, `C2_FULL=NO_GO_NOT_APPROVED`, `PHASE_IX=NOT_AUTHORIZED` e `PRODUCTION_APPROVED=False` permanecem inalterados.

**STOP:** encerrar após publicar este único arquivo em PR Draft. Não alterar `AGENTS.md`, `current-state.md`, docs acadêmicos, QVS, QVD, QVW, automações, PR #167 ou `main`; nenhum merge neste gate.

## Referências

1. [AGENTS.md](../../AGENTS.md), [estado atual](../project/current-state.md) e [requisitos](../academic/requirements.md).
2. [Direção A0 + exceção A1 P2.3](../project/analytical-consumption-architecture-approval-2026-10-27.md).
3. [Grade/controle VI-P4](../../TRANSFORMACAO/vi_p4_municipal_coverage.qvs) e [readback C4-F](phase-8-c4f-vi-p4-export-readback-2026-10-21.md).
4. [Modelo técnico VII](../../PAINEL/phase_vii_technical_model.qvs) e [Boundary 7](boundary-7-implementation-plan.md).
5. [PR #167 — encerramento da R1 A0](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/167).
