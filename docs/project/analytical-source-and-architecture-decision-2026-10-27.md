# SAD — Decisão de racionalização das fontes e camada analítica (27/10/2026)

**Estado na elaboração de 27/10 (histórico):** DIRECIONAMENTO_APROVADO_EM_CHAT_PARA_DOCUMENTAR_E_PREPARAR_DISCOVERY; **SEM MUDANÇA FÍSICA APROVADA**. O texto original foi proposto como Draft, mas sua integração posterior à `main` ocorreu por [PR #162](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/162) **MERGED**. A aprovação documental subsequente A0-base/A1 condicional consta no [PR #166](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/166) e substitui a expressão histórica “decisão A0×A1 pendente”; não homologa QlikView nem A2.
**Baseline inspecionada:** main@db5d6e6e23371422ca1d2d77a8576150aaf63d03; fontes obrigatórias AGENTS.md, docs/project/current-state.md, docs/academic/requirements.md.
**Objetivo:** decidir o próximo trabalho mínimo após AE01 e a análise exploratória das 12 perguntas, sem reconstruir a modelagem acadêmica.

**Estado operacional confirmado em 29/10:** A0 é o padrão para os 14 visuais, com exceção lógica A1 **somente se necessária em P2.3**; o piloto A1 R2 obteve PASS físico restrito candidato (PRs #168, #169, #170 integrados), sem UI ou produção. Nenhuma redecisão A0×A1 é necessária na próxima revisão incremental. Ver [current-state](current-state.md) e [decisão de arquitetura de consumo](analytical-consumption-architecture-approval-2026-10-27.md).

## 1. Decisão e fundamentação

**DECISÃO DE DIRECIONAMENTO:** manter como baseline a constelação Star de três fatos (FATO_INTERNACAO, FATO_CAPACIDADE_LEITO, FATO_POPULACAO), oito dimensões conformadas/específicas e a implementação obrigatória QlikView 12 no fluxo BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw. Preservar a ordem do Boundary 7, a V2 §62 aprovada apenas semanticamente, RN21, papéis RES/SERV e os Capítulos 1–2 entregues em 13/10/2026.

**PROPOSTA DE TRABALHO, NÃO APROVAÇÃO FÍSICA:** distinguir a persistência dos fatos/dimensões da camada de consumo. Para perguntas independentes, avaliar projeções/agrupamentos por processo factual que não dependam de Link Key inter-fatos. Para T24/T25/T26, preservar os cruzamentos governados pelos contratos e filtros específicos. Não promover os CSVs de AE01 a uma nova arquitetura de produção nem substituí-los aos QVDs da constelação.

### Alternativas a comparar, sem implementação neste documento

| Alternativa | Regra | Ganho potencial | Limite/decisão |
|---|---|---|---|
| A0 — preservar somente o modelo atual | Reutilizar fatos/dimensões/Link Table e configurar visualizações independentes onde comprovadas | Menor divergência acadêmica | Requer verificar comportamento associativo real nos contextos selecionados; não assumir PASS global |
| A1 — preservar o Data Mart e usar camada derivada de consumo **candidata** | Agregações/visões por processo, com linhagem, grão e filtros próprios; não constituem nova fato acadêmica automaticamente | Simplifica consultas exclusivamente SIH ou LT | Exige desenho documental, prova de não duplicação e gate físico separado antes de criar qualquer QVD/QVW |
| A2 — remodelagem dimensional completa | Alteração de fatos, dimensões, grãos ou estratégia estrutural | Nenhum benefício comprovado por AE01 | **Não recomendada/não autorizada**; demandaria evidência concreta de inviabilidade e nova aprovação acadêmica/semântica |

**Recomendação provisória:** avaliar A0 e A1 no próximo gate READ-ONLY; manter A2 somente como hipótese de escalonamento formal se houver defeito estrutural demonstrado, não por preferência estética.

## 2. Evidência e níveis de prova

- AE01: [PR #160](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/160) OPEN/Draft, commit executado 8633f12a910f422f6b2e9af5e0d06d622ff13497; [Issue #161](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/161) registra a segunda tentativa e auditoria dos **quatro CSVs anexados**. Manifesto SHA-256 0B1AA7DA6EF10A08B0F698250F199666525672DC763D6774CA4498B2A3C488D2. A exportação/reconciliação é **PASS RESTRITO** para SIH/RD e CNES/LT observados, não para a Link Key nem para painéis QlikView.
- Resultados exploratórios derivados dos CSVs anexados, 27/10/2026: **9 das 12 perguntas com evidência quantitativa descritiva direta** (I01–I05, I08–I11); I06/I07 disponíveis na documentação histórica F5-RD, **não reaudidadas com AE01**; I12 condicionado à população e ao contrato T24. Análise exploratória local **EXPERIMENTAL_NOT_GATE_EVIDENCE**, não homologada como novo gate versionado. Referência de perguntas: [inventário](../discovery/analytical-question-inventory-2026-10-27.md) e [matriz de dependências proposta](../discovery/sad-analytical-consumption-source-matrix-2026-10-27.md).
- Evidências quantitativas somente de SIH: 566.672 RD, 555.089 internações novas, 11.583 continuidades, 36 competências. Concentração dos códigos SERV 250750 e 250400: 65,43% (exploratório); R≠S: 46,92% (exploratório). Não inferir viagens individuais, doença, demanda reprimida, causalidade ou pacientes únicos.
- CNES/LT: 35.518 linhas, 3.561 pares município×mês com linha, 97 zero SUS observado, 3.464 SUS positivo e 4.467 sem linha na grade 223×36. Ausência não é zero nem prova de ausência real de leitos; snapshots não se somam para estoque anual.
- Proteção reportada e auditada nos anexos AE01: inventários pré/pós coincidentes para 22 QVDs, 3 QVWs canônicos e crosswalk; não é auditoria direta dos binários.
- FATO_POPULACAO (669 município×ano) e referências ST/SIGTAP/CID vêm de documentação/materialização anterior, não integram os quatro CSVs AE01.

## 3. Necessidade distinta por fonte

| Fonte | Perguntas descritivas independentes | Integração / contratos avançados | Política |
|---|---|---|---|
| SIH/SUS RD | Essencial para I01–I09, exceto limitações de I06/I07 no AE01 | T24, T26, FLU | Preservar universo RD, IDENT=5 não gera nova internação |
| CNES LT | Essencial para I10/I11 | T25/T26 sob cobertura municipal×competência | Preservar todos LT válidos RN21, sem imputação de ausências |
| IBGE/SIDRA | Não é requisito para os três painéis estritamente descritivos | Essencial ao denominador T24/T25; FATO_POPULACAO permanece | Não multiplicar por mês nem aplicar POP PB a residente externo |
| CNES ST | Não é requisito para totais brutos LT ou SIH independentes | Atributos históricos de estabelecimento e eventual escopo hospitalar | Classificação histórica ainda não comprovada globalmente |
| SIGTAP/CID-10 | Não para ranking **por código** | Nomes/hierarquia/rótulos qualificados de PROC_REA/DIAG_PRINC | Conferir competência/vigência e cobertura; não inventar descrições |
| Município DATASUS↔IBGE | Códigos podem ser apresentados sem rótulos quando proveniência clara | Essencial a integração municipal/POP e rotulagem confiável | Não inventar equivalências; crosswalk AE01 não foi reaberto linha a linha na auditoria citada |
| Demais referências de domínio | Somente visualizações que usem seus atributos | Mantidas para fatos e dimensões aprovados | Não excluir por não aparecer em E1–E4 |

## 4. Riscos, não decisões novas

1. **Cobertura/hospitalidade LT:** T25/T26 não aprovados globalmente; [Issue #157](https://github.com/pedrogles/sad-sus-pb-data-mart/issues/157) permanece fonte própria. Ausência LT e classificação histórica de hospitais exigem solução científica, não mudança dimensional por si.
2. **Contrato de integração e UI:** LINK_KEY_CONTRACT, MEASURES_AND_DENOMINATOR_CONTRACT, C2_FULL, P5/D2 permanecem não aprovados. O PASS AE01 não homologa seleção simultânea nem relações entre fatos.
3. **Linhagem de consumo:** projeções só podem ser candidatas com grão explícito, medidas, origem staging/fato, filtros permitidos, oráculos, temporalidade, responsabilidade por código e regra de indisponibilidade.

## 5. Decisões futuras e STOP

- **FATO DOCUMENTADO:** a arquitetura aprovada atende aos processos factual SIH, LT e POP; os três grãos diferem e não devem ser fundidos para facilitar visualização.
- **HIPÓTESE A AVALIAR:** A1 pode tornar painéis descritivos mais simples, sem substituir A0 ou reabrir o modelo acadêmico.
- **DECISÃO PENDENTE:** selecionar A0/A1 para implementação após Discovery e aprovação; A2 só se falha concreta fundamentar revisão formal. Selecionar as especificações finais dos três painéis também requer aceite.
- **Sem autorização:** merge, alteração da main, Capítulos 1–2, V2/RN21, schema/QVD/QVW, QlikView COM/GUI, novos downloads, testes físicos, Fase IX ou produção.

**Próximo gate proposto:** [SAD-ANALYTICAL-CONSUMPTION-DISCOVERY-01](../discovery/sad-analytical-consumption-discovery-2026-10-27.md), apenas READ-ONLY, com bootstrap em documento próprio.

## Atualização de integração — decisão D1–D3 posterior (27/10/2026)

O responsável **aprovou no PR #165** o escopo de **14 visuais candidatos**: P1=5, P2=5, P3=4; I06/I07 opcionais, I12/T24 adiado do núcleo inicial sem retirar `FATO_POPULACAO` nem alterar três fatos/oito dimensões. A aprovação de **quais análises apresentar** é distinta da escolha **A0 versus A1 para consumo físico**, que permanece decisão pendente e exige uma Discovery mínima justificada, sem duplicar o trabalho de AE01 ou A0 R1.

**Reuso de evidências posterior:** os executores do PR #164 e auditoria independente A0 R1 já demonstraram igualdade numérica **36 SIH mensais + 108 LT mensais + dois pares RES/SERV**, total **146/146**, **apenas no recorte delimitado** ([parecer](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/164#issuecomment-6451787982)). A matriz global, UI/UX, T24/T25/T26 e Link Key global seguem não homologadas. O escopo aprovado fica em [contrato dos 14 visuais](../discovery/sad-analytical-scope-acceptance-01-2026-10-27.md).

**Atenção à numeração:** `P2.2` do A0 R1 era **série mensal LT** (equivale a `P2.1` no contrato dos 14 visuais); o novo `P2.2` é composição SUS/não-SUS mensal **sem homologação de objeto visual**. Não atribuir a mesma prova de interface a ambos.

**Nenhuma decisão A1/A2, código físico, merge de implementação, T29, Fase IX ou produção é autorizada por este adendo.**
