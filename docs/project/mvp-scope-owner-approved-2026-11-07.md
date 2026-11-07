# SAD — M0 B1: aceite de escopo do responsável e adendo candidato de implementação

**Decisão do responsável:** 07/11/2026 — “Sim, prossiga, aprovado”, em resposta explícita à aprovação da opção B (três fatos, oito dimensões, três folhas/nove análises, filtros nativos simples, contratos revisados apenas no escopo utilizado), sem merge nem mutação dos artefatos canônicos. A pergunta e a resposta constam da conversa do projeto; não foi alegada aprovação docente ou de produção.

**Estado neste PR #226:** `OWNER_MVP_SCOPE_APPROVED=YES`; `OWNER_AUTHORIZED_TEMP_IMPLEMENTATION=YES`; `MAIN_EFFECTIVE_CONTRACT=UNCHANGED_UNTIL_SEPARATE_MERGE`; `PHASE_IX=NOT_AUTHORIZED`; `C2_C3_C4_MVP=NOT_PHYSICALLY_APPROVED`; `PRODUCTION_APPROVED=False`.

**Base da main:** `0549e1dba71aaa8bbab9d6755aecb8465f8bea83`. Este adendo **não substitui automaticamente** documentos integrados à main, nem concede GO a Fase IX. Resguarda o texto histórico de Boundary 7, V2 §62, V3 D2-R2 e blueprint de 14 visuais; a redução aprovada vale para o **MVP em branch**, até revisão/integração formal.

## 1. Produto aprovado e seus nove objetos analíticos

| Folha | Visual ID | Objeto candidato | Fonte e período | Condição de aceite |
|---|---|---|---|---|
| 1 — Produção Hospitalar | M1-01 | Barra: novas internações por ano | SIH/RD `QTD_INTERNACAO`, `PERIODO_ANO` 2017–19 | Respeitar `IDENT=5→0`, comparando 183.532/183.311/188.246; não chamar pacientes |
| 1 — Produção Hospitalar | M1-02 | Linha: 36 competências | SIH/RD `PERIODO_COMPETENCIA`, `QTD_INTERNACAO` | Não confundir 36 meses históricos e série guiada de 12 meses |
| 1 — Produção Hospitalar | M1-03 | Barras: município de atendimento | SIH/RD papel `SERV_COD_DATASUS_6` | Testar associação FI→Link→SERV e ranking P1.3 antes de usar como indicador válido |
| 2 — Leitos Cadastrais Observados | M2-01 | Linhas: snapshots existentes/SUS | CNES/LT `PERIODO_COMPETENCIA`; `QTD_LEITOS_EXISTENTES`, `QTD_LEITOS_SUS` | Nunca somar meses para obter capacidade anual |
| 2 — Leitos Cadastrais Observados | M2-02 | Barras: distribuição municipal no mês | CNES/LT município SERV, **201912 fixado no título/expressão candidata** | Zero observado ≠ ausência de linha; não afirmar cobertura hospitalar completa |
| 2 — Leitos Cadastrais Observados | M2-03 | Barras: células de observabilidade | Ilha `P23_A1_ISLAND` com `P23_ESTADO_OBSERVADO`, por município×competência | 3.464 positivos, 97 zeros **observados**, 4.467 ausências, somando 8.028 células; ilha não filtra fatos globais |
| 3 — Fluxos e Contexto Territorial | M3-01 | Barras: residência igual/diferente serviço | SIH/RD via RES/SERV (null distinto) | Testar classificação, nunca reclassificar município externo como PB |
| 3 — Fluxos e Contexto Territorial | M3-02 | Tabela: pares RES→SERV | SIH/RD, `RES_COD_DATASUS_6` + `SERV_COD_DATASUS_6` | Contagem de novas internações por par; comparação com P3.1/P3.3 e universo |
| 3 — Fluxos e Contexto Territorial | M3-03 | Tabela: população município×ano | IBGE/SIDRA, `RES_COD_DATASUS_6` + `PERIODO_ANO` | População 669 células ano×município; provar associação; não inferir base populacional externa nem aplicar filtro FI silencioso |

**Fonte materializada:** modelo técnico `PAINEL/phase_vii_technical_model.qvs`, já testado em TEMP com três fatos e 10/10 oráculos; ilha de observabilidade `PAINEL/sad_p23_a1_island_physical_gate.qvs` (17ª tabela isolada), cuja projeção precisa ser carregada/testada especificamente na cópia de consumo. Não inventar P23 a partir de simples contagem de linhas LT.

## 2. Delta de contratos aprovado para o MVP

- **Boundary 7:** preservar a ordem lógica **C2 temporal → C3 associação → C4 medidas/filtros → GO formal IX**. Aprovação limita o **universo de prova** de cada etapa ao que os nove visuais realmente apresentam; não declara C2/C3/C4 concluídos retroativamente. Preparar e testar protótipo em QVW TEMP é execução experimental autorizada, **não implementação definitiva da IX**.
- **D2-R2 V3:** eliminar os controles **guiados** de proposta ANUAL/MENSAL/EVOLUCAO da superfície MVP, **sem apagar sua evidência anterior** e sem prometer bloqueio de todas as rotas nativas; os visuais devem interpretar período real aplicado, com indisponibilidade explícita quando incompatível. Qualquer novo controle guiado continua sujeito à prevenção antes do despacho.
- **P5 V2:** manter matriz indicador×filtros e evitar influência silenciosa. Filtro nativo é escolha de UI, não licença para associação cruzada sem prova. Se um objeto não puder suprimir resultado enganoso sob seleção potencial, permanece **BLOCKED_FOR_USER_USE** até validação/guarda implementada.
- **Arquitetura B1:** três fatos, oito dimensões, Link e role-playing preservados; ilha adicional P23 é **projeção analítica de observabilidade**, não nona dimensão acadêmica nem substituta da Link. B2 com modelo fisicamente isolado **não foi aprovada**; se B1 falhar, STOP e decisão nova.
- **T24/T25/T26:** taxas/cruzamentos e denominadores não fazem parte destes nove objetos; POP é descritiva. `T29_HISTORICAL=NOT_APPROVED`, `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`.

## 3. Implementação e prova em ambientes separados

**Objetivo do próximo gate M2-PROTOTYPE:** gerar um QVW TEMP derivado de `SAD_M1_INTEGRATED_TEMP.qvw` (a carga M1 já passou e está preservada), adicionar a ilha P23 **sem STORE**, construir três folhas e nove objetos COM nativos, salvar somente cópia e registrar provas/hashes. A versão física dos objetos só é aceita após execução real no Windows/QlikView 12 e inspeção das propriedades/seleções/visuais.

**Pré-aceite verificável:** `M1_SOURCE_QVW=EXISTS`; script versionado no commit esperado; 22 QVDs + três QVWs canônicos hash pre/post; carga e P23 PASS; três folhas com nove objetos rastreados; leitura sem seleção; nenhum `$Syn` ou loop indevido; a condição POP não pode ser declarada segura por mera renderização.

**STOP prioritário:** qualquer campo inexistente, erro de reload, associação inesperada, falta de zero/ausente, risco de resultado enganoso, erro COM, hash drift ou falha de prova → `BLOCKED`. Não repetir o teste automaticamente, nem modificar/abrir `PAINEL/PAINEL.qvw` como destino.

**Não autorizados por esta decisão:** merge do PR #226, descarte de branches, alteração estrutural do modelo acadêmico, substituição ou SAVE/STORE nos arquivos canônicos, publicação/produção e apresentação como homologados.
