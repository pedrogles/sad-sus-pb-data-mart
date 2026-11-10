# SAD — Plano acadêmico de entrega e refinamento visual (09/11/2026)

**Natureza:** planejamento e handoff DOCUMENTAL proposto, sem mudança de arquitetura, sem novos testes ou edição QlikView, sem merge. **Branch proposta:** `docs/sad-academic-visual-readiness-2026-11-09`. **Autoridade operacional:** consultar **na main**, nesta ordem: `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → documentação específica. Este documento não altera a main, o Boundary 7, o contrato D2-R2, o blueprint de 14 visuais da main nem as pendências C2/C3/C4. O MVP de nove visuais permanece experimental e documentado no Draft [#226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226).

## 1. Fatos, evidências e limites (fonte explicitada)

| Item | Estado qualificado em 09/11 | Fonte / limite |
|---|---|---|
| Primeira entrega: capítulos 1–2 | Entregue impressa em 13/10 conforme operador; texto e diagramas aprovados para a entrega, avaliação docente não verificada | `main:docs/academic/chapter-1-2-modeling.md`, `main:docs/academic/requirements.md`; não alterar silenciosamente |
| A1: capítulo 3–5 | Word recuperado pelo operador e conteúdo revisado | Evidência local e revisão no chat; não há Word/PDF versionado no Git |
| A2: anexos integrais | Gerador local reportou 13/13 arquivos QVS verificados do commit `0549e1dba71aaa8bbab9d6755aecb8465f8bea83`; anexos materializados; gate **formal de executor pendente** | `SAD_Anexos_I_II_QVS_Originais.zip` e relatório local. Execução de gerador não versionado **não** é PASS formal por `AGENTS.md` |
| A3: captura e substituição folha 1 | Evidência visual e PDF inspecionados; SHA-256 da QVW reportado e conferido pelo operador | `SAD_MVP_C4_PRESENTATION_TEMP.qvw` e PDF A3; PASS visual restrito, não aceite de QVW de produção |
| A4: relatório consolidado | PDF candidato com 98 páginas, capítulos 1–5 e anexos; R2 editorial revisada visualmente | `SAD_A4_Relatorio_Consolidado_R2_Editorial.pdf` e `SAD_A4_R2_Editorial_Auditoria_2026-11-09.md` gerados fora do Git; aceite acadêmico **não** confirmado |
| Avaliação 2 | **08/12/2026**, apresentação **online via Google Classroom**, entrega do documento **em PDF** | **Confirmado pelo operador em 09/11**; data/formato não foram checados diretamente no Classroom |
| Três painéis | O operador confirmou que **três folhas da QVW atendem ao requisito docente** | Confirmação do operador, não validação física global ou aprovação de produção |

**QVW C4 de origem a proteger (Windows):**
`C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw`
SHA-256 **reportado pelo operador**: `27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13`.

**R2 documental de recuperação:** `SAD_A4_Relatorio_Consolidado_R2_Editorial.pdf` (98 páginas), conservada localmente; hash de bytes ainda não registrado neste documento. Não commitar PDF, QVD, QVW, ZIP ou dados brutos. Caso os arquivos não estejam acessíveis no novo chat, pedir somente o artefato indispensável, não alegar acesso ao Windows.

## 2. Decisão de priorização

**Prazo acadêmico primeiro:** concluir refinamento visual seguro e atualizar o relatório uma única vez, antes de submissão. **Frente formal de produto separada:** C2 → C3 → C4 → autorização Fase IX (Boundary 7). O aceite docente de três folhas não converte MVP B1 3×3 em baseline de 14 visuais e não autoriza Fase IX.

Nomear refinamento como **VIS-01, VIS-02, VIS-03**; não usar `D1`, já empregado no handoff #226 para reconciliação futura.

## 3. Roadmap acadêmico por gates (metas internas, não prazos do professor)

| Ordem / janela sugerida | Gate | Entrada | Saída + critério de STOP |
|---|---|---|---|
| P0 · 09–11/11 | Preservação e registro documental | `main`, #226, QVW C4, PDF R2, logs A2–A4 | Inventário de caminhos e hashes; condições acadêmicas registradas; cópias de recuperação; encerrar sem reexecutar extrações/geradores por hábito |
| **VIS-01** · 12–15/11 | **Discovery e aprovação de identidade visual** | Capturas das 3 folhas C4 e objetos existentes | Mini design system: paleta/tipografia, grid, proporções de 3 folhas, fundo proposto/exportável, regras de cards/KPIs *existentes*, tabelas, gráficos, estados de indisponibilidade, mockups; **aprovação visual do responsável antes de aplicar** |
| **VIS-02** · 16–25/11 | Aplicação de design na apresentação | VIS-01 aprovado, **cópia controlada** da QVW | Alterações exclusivamente de aparência de fundo, contornos, títulos, tipografia, cores, alinhamento e tabelas/gráficos existentes; preservar 9 objetos e expressões; **nova autorização para edição física da cópia** |
| **VIS-03** · 26–28/11 | Verificação visual e de integridade | QVW visual de trabalho, hashes, capturas | 3 folhas sem cortes/overlaps, legíveis em compartilhamento de tela, sem regressões observadas em seleções do escopo; hash da QVW original preservado; status **restrito** e com limitações registradas; sem homologação C2/C3/C4 |
| DOC-R3 · 29/11–03/12 | Uma atualização final do PDF | R2 congelado e screenshots pós-VIS-03 | Troca apenas das capturas/legendas afetadas no Cap. 3, conferir sumário/paginação e anexos; Cap. 1–2 e QVS integrais intocados; se design não ficar pronto, **submeter R2 revisada** |
| PRES · 04–06/12 | Ensaio remoto | QVW visual, PDF e roteiro ~5 min | Cronometrar 5 min, alternância das 3 folhas, testar compartilhamento, resolução e plano B estático; não alterar dados |
| SUB · idealmente 06–07/12 | Entrega acadêmica | PDF final aceito, Classroom acessível | Upload de PDF no Google Classroom, abrir e conferir anexo e confirmação de envio; antecipação recomendada, **prazo exato da atividade no Classroom não verificado** |
| AVAL · **08/12/2026** | Segunda avaliação | Material já submetido e apresentação preparada | Apresentação online, QVW e PDF como backup; não prometer homologação de produção |

**Dependências:** P0 → VIS-01 aprovado → VIS-02 autorizado/executado → VIS-03 → DOC-R3 → PRES → SUB. Planejamento/roteiro da apresentação podem ocorrer em paralelo. Se VIS-02 ou VIS-03 falhar, fazer rollback para QVW C4 original e PDF R2, não refazer M1–M3.

## 4. Contrato VIS-01 (próximo chat)

**Objetivo delimitado:** projetar identidade visual para as 3 folhas do **MVP acadêmico 9 visuais**, sem reabrir semântica.

**Entrada visual:** capturas A3 (Produção Hospitalar, Leitos Cadastrais Observados, Fluxos e Contexto Territorial) e observações do QlikView Desktop 12. Não pressupor que capacidades de background, imagens, bordas, transparência e tabelas em QlikView sejam equivalentes a CSS: verificar suporte real antes da implementação.

**Entregáveis:** uma proposta principal (institucional limpa, alto contraste, fundo claro, destaque azul petróleo/teal) com principal trade-off, 1–3 mockups das folhas, guia de tokens de cor/tipografia/spacing, fundo(s) estático(s) preparado(s) se aprovado e plano de aplicação por objeto/folha. Os mockups são **propostas**, não screenshots do QVW real nem evidência de implementação.

**Regras:** somente formatar/organizar os **9 objetos existentes**; novos cards com novas medidas, filtros, alterações de expressões, associação ou conteúdo semântico são **nova decisão de escopo**, não VIS-01. Estados de seleção incompatível devem continuar visíveis e corretos.

**PASS VIS-01:** três telas coerentes, visual aprovado pelo responsável, especificação executável no QlikView 12 ou limitações explícitas e workaround; sem qualquer escrita QVW/QVD. **STOP** ao aprovar a direção visual; abrir VIS-02 em escopo próprio. **BLOCKED:** faltam capturas/especificação necessária. **INCONCLUSIVE:** compatibilidade QlikView ainda não verificada.

## 5. Proteção e rastreabilidade

- `main` permanece fonte operacional; #226 contém evidências candidatas, sem merge.
- Alterar QVW exige escopo e autorização específica, **cópia de trabalho, hashes antes/depois, sem Reload** e rollback identificado. Não tocar originais.
- Geradores A2/A4 locais: **regularização prospectiva**, com commit em branch antes de *nova execução*; não atribuir PASS retroativo. Não reexecutar rotinas apenas para preencher burocracia; decidir se gate formal precisa disso.
- **Não alterar** 3 fatos/8 dimensões, granularidades, RN de `IDENT=5`, papéis RES/SERV, snapshots semi-aditivos, `T29_HISTORICAL=NOT_APPROVED`, Links, P5, contratos C2/C3/C4 nem Fase IX.
- Não fazer merge, apagar branch ou alterar documentação operacional da main por arrasto. Propor atualização de `current-state.md` **separadamente** quando houver decisão de integração.

## 6. Handoff / próximo passo inequívoco

Abrir **novo chat no mesmo Project**, com assunto `SAD | VIS-01 — Design System QlikView 12`. Iniciar somente VIS-01, usando o [bootstrap documental](sad-vis-01-bootstrap-2026-11-09.md). O primeiro resultado deve ser direção visual e mockups; **não executar edição de QVW** no início.

**Status de encerramento documental:** plano registrado em branch e proposta de PR Draft; `VIS-01=NOT_STARTED`; `A4_R2=REVIEWED_EDITORIAL_CANDIDATE`; `C2_C3_C4_GLOBAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.