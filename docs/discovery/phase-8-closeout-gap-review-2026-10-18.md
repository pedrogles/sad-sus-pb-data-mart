# Fase VIII — revisão READ-ONLY de pendências e condição de fechamento (18/10/2026)

**Estado:** `VIII_CLOSEOUT_REVIEW=STATIC_COMPLETED_WITH_GAPS`; `VIII_GENERAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`. Documento de governança na branch Draft; **não executa QlikView**, não lê arquivos QVD/QVW binários, não altera scripts de produção, contratos, modelagem acadêmica ou `main`.

## 1. Limites, hierarquia e baseline

Revisão feita a partir de `main@337943d5c5b77067f842902fc679dbb68db87020`, consultando nesta ordem `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md` e, em seguida, Boundary 7, V2 §62, VI-P5, VIII-A, automação QlikView e documentos de evidência dos PRs #110–#114. Hierarquia preservada: professor > fontes oficiais DATASUS/CNES/IBGE > dados reais inspecionados > documentação canônica > memória/chats. **A presente análise não inspecionou novos dados brutos nem comprovou cobertura em bases externas.**

**Distinção de evidência:**
- **Fato de Git verificado:** PR #106 e #107 MERGED; PRs **#90, #108, #109 e #110–#114 OPEN/DRAFT**, não integrados na `main`, na verificação desta revisão.
- **Fato de documentação inspecionada:** cada PR #110–#114 registra stdout de ensaios Windows/QlikView 12 reportados pelo responsável e compromissos de SHA. Os QVDs, QVWs, logs nativos e CSVs de evidência locais **não foram abertos nesta revisão**, portanto seus PASS são **locais reportados e candidatos**, não reproduções independentes.
- **Drift documental:** `docs/project/current-state.md` na `main` ainda descreve a Fase VIII como próximo gate e cita o HEAD pós-#106, enquanto a `main` verificada é `337943d5...` e a execução VIII está documentada em **PRs Draft**. É um **descompasso de snapshot/integração**, não prova de regressão de modelo nem autorização para editar `main`.

Arquitetura intocável: QlikView 12; BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL; constelação Star por processo factual, três fatos e oito dimensões acadêmicas; material 2017–2019; 22 QVDs originais (21 anteriores + `LINK_ANALISE.qvd`), QVWs canônicos e arquivos de evidência preservados. Não realizar merges, edição de `main`, sobrescrita de QVD/QVW ou higienização de branches.

## 2. Evidências experimentais da Fase VIII — sem transferência de aceite

| PR / evidência | Resultado documentado | Evidência autorizada a concluir | Não autoriza |
| --- | --- | --- | --- |
| [#110](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/110) T24 anual | 5/5 cenários PB 2017–2019, JP 2018, CG 2018, PASS local candidato | Igualdade de internações, POP anual e razão dentro da tolerância nesses recortes | T24 geral, políticas mensais/filtros |
| [#111](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/111) T24 parcial/D2/P5 | T24 parcial 3/3 e pré-dispatch wrapper 4/4 PASS locais restritos | POP anual recuperada na razão mensal em recortes JP/PB; wrapper rejeitou propostas conflitantes/incompatíveis | D2/P5 implementados **na UI**, matriz C/R/I/B completa |
| [#112](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/112) T24 exceções | Região JP+CG 2018 1/1 e guardas indisponibilidade 3/3 | Razão regional com componentes agregados; não avaliar KPI sem ano único ou POP externa (oráculo) | Seleção COM de residente externo ou indisponibilidade **incorporada a objetos finais** |
| [#113](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/113) T25 | 2 anuais, 24 meses de componente e 1 parcial, PASS locais candidatos | Média de 12 snapshots do LT observado 2018 por município de serviço, POP anual e taxa nesses recortes | Cobertura hospitalar histórica, escopo estadual, T25 final |
| [#114](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/114) T26 | 2 anuais + 1 parcial, PASS locais candidatos | RD elegível `IDENT=1` no município de serviço / média dos snapshots LT do mesmo recorte; janeiro não anualizado | Taxa de ocupação, vínculo clínico leito-internação, T26 final |

**Integridade:** os executores documentam preservação dos 22 QVDs, QVWs canônicos e QVW experimental de origem por SHA-256 em cada tentativa bem-sucedida; isso é **evidência local reportada**, não auditoria independente nesta revisão. Os commits realmente executados estão nos documentos de cada PR; os HEADs posteriores podem conter somente commits documentais. Os PRs #110–#114 continuam independentes entre si e da `main`, logo não compõem um único PAINEL final.

## 3. Matriz de bloqueios reais, decisão e mínima próxima prova

| Bloqueio canônico | Prova efetivamente existente | Lacuna para aceite | Próxima ação delimitada |
| --- | --- | --- | --- |
| `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED` | 36 arquivos LT e oráculos F2; 12 competências com linhas em JP/CG 2018 no universo `LT_TODOS_REGISTROS_VALIDOS_RN21`; PR #90 CNES preflight Draft | Presença de linha **não prova** cobertura hospitalar, elegibilidade histórica dos estabelecimentos, zero real sem linha nem suficiência do denominador de T25/T26 | **Gate C1 READ-ONLY de escopo/cobertura CNES** por município×competência e classificação histórica `TP_UNID`, sem excluir linhas LT da fato e sem presumir legenda 201909 |
| `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY` / `P5_D2_UI=NOT_TESTED` | Pré-dispatch D2/P5 no wrapper do PR #111; no #112 indisponibilidade em wrapper/oráculo; referência experimental histórica PR #83 | Falta comprovação de `Calculation Condition`/mensagens, aplicação real dos filtros **C/R/I/B** isolados e combinados nos objetos, bloqueio **antes** de seleção conflitante | **Gate C2 isolado QVW descartável** de objetos/condições e pares de filtros usando semântica V2, com capturas e verificação numérica; sem alegar aprovação por COM/screenshot sozinho |
| `LINK_KEY_CONTRACT=NOT_APPROVED` | VI R2 e Fase VII, T17–T23 candidatos; modelo 16 tabelas/15 relações sem `$Syn`/loops visíveis; T24–T26 por seleções restritas | Associação semântica entre papéis/fatos e filtros incompatíveis, chaves e contagens sob **todos** contextos exigidos, além de aceitação formal | **Gate C3 contratual** revisar provas existentes e somente testar casos faltantes identificados de D2/P5/link; não refazer CREATE/READBACK nem T17–T23 |
| `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED` / `T24_T25_T26_GENERAL=NOT_APPROVED` | F1/F2/F3 e reconciliação numérica restrita nos #110–#114 | Cobertura contextual, comportamento sob filtros simultâneos, nulo/zero/ausência, multi-ano série, regiões para T25/T26, denominações e advertências no objeto final | **Gate C4 medidas/semântica física**, revisar C1–C3 e matriz V2, comparar oráculos apenas em recortes faltantes relevantes; aprovação formal separada |
| `T29_HISTORICAL=NOT_APPROVED` | V2 registra descrições sem vigência comprovada em parcela majoritária das combinações código×competência; Boundary 5 exige atributos históricos coerentes | Não há prova de vigência de nomes de leito para todos os períodos 2017–2019 | **Gate C1 conexo**: manter códigos e nulos/avisos, pesquisar vigência nas fontes oficiais apenas se indispensável; sem retroatividade de legenda set/2019 |
| `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False` | Requisitos acadêmicos ≥3 painéis, QlikView 12; VII painel **técnico** sem objetos finais | C1–C4 ainda sem aceite físico/semântico de integração; dashboard não é simples colagem de três expressões | Somente após gates e autorização específica, planejar fase IX com três painéis, filtros, explicações de indisponibilidade e aprovação visual |

**Dados consolidados, mas não globalizados:** F2 anterior identificou 4.467 pares município×competência sem linhas LT e 97 com QT_SUS=0 observado. **Nem ausência = zero, nem mês com linha = completude hospitalar**. `T29` mantém 2019-09 como legenda descritiva datada. Residentes externos à PB têm internações elegíveis, mas não recebem população PB artificial. `IDENT=5` nunca entra como nova internação. Capacidade mensal é semi-aditiva; T26 **não é taxa de ocupação**.

## 4. Sequência recomendada, sem execução automática

**C1 — Próximo gate único recomendado: CNES/LT escopo e cobertura em modo READ-ONLY, sem nova carga.**

1. Ler a documentação de validação CNES/ST-LT do PR #90 e as evidências históricas ST/LT/`TP_UNID` existentes; não repetir seus testes já aprovados. Examinar a possibilidade de estabelecer classificação histórica defensável por **competência** de estabelecimentos CNES e a diferença entre `LT_TODOS_REGISTROS_VALIDOS_RN21` e universo hospitalar. Usar documentação oficial quando for necessário comprovar vigência, sem inventar tipo, código ou data.
2. Definir uma **matriz de cobertura** com o menor recorte necessário: municípios JP/CG 2018 × 12 competências, junto com exceções documentadas de ausência de linha e zero observado. Identificar explicitamente o que cada evidência permite concluir; não inferir zero real por ausência nem validar cobertura estadual a partir de dois municípios.
3. **STOP C1** em uma matriz rastreável `município×competência→universo observado→linha LT/estado→classificação histórica comprovada ou não→status`, mais decisão **GO restrito/NO-GO** para uso de escopo hospitalar nas medidas. Se faltar fonte histórica, manter `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED` e T25/T26 somente como observacionais; **não abrir coleta ou testes ilimitados**.

**C2 — Após C1 ou independentemente como ensaio claramente observado**, propor gate físico D2/P5 em *cópia* do QVW, usando a matriz V2 e evidências F1/F2/F3. Condições de cálculo de objeto, estados de indisponibilidade, filtros simultâneos e verificação visual real são critérios obrigatórios; preservar QVD/QVW original.

**C3 — Revisão dos contratos link e medidas** após C2: separar casos já comprovados de casos ausentes. Nunca transferir PASS de wrapper ou seleção limitada para `LINK_KEY_CONTRACT=APPROVED`; nenhum merge implícito das branches Draft.

**C4 — Readiness de homologação dos indicadores e fase IX**: com C1–C3 documentados e aceitos por responsável, avaliar `MEASURES_AND_DENOMINATOR_CONTRACT`; somente depois considerar autorização de fase IX. Tratar requisitos acadêmicos dos **três painéis** e avaliação da primeira entrega sem alterar modelagem entregue.

**Condição de parada desta revisão:** inventário dos PRs + matriz de bloqueios + próximo gate C1 documentados. `VIII_CLOSEOUT_REVIEW=STATIC_COMPLETED_WITH_GAPS`; **nenhum executor criado**, nenhum ensaio Windows disparado, `MAIN_UNCHANGED=True` em relação a este trabalho. Sem apagar branches Draft, sem merge, sem QVD/QVW atualizado, sem aprovação de produção.
