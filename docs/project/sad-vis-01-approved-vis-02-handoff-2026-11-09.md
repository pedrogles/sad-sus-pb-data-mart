# SAD — VIS-01 aprovado; handoff seguro VIS-02 (09/11/2026)

**Decisão do responsável no chat:** “aprovado, prossiga”. **Escopo do aceite:** identidade visual “Institucional Analítico — SUS PB” para as três folhas e nove objetos existentes do MVP B1 da PR #226. Este registro documenta o aceite visual; não é homologação física, semântica ou autorização de merge.

**Fontes lidas na ordem obrigatória:** `main:AGENTS.md`, `main:docs/project/current-state.md`, `main:docs/academic/requirements.md`; depois `docs/sad-academic-visual-readiness-2026-11-09:docs/project/sad-academic-visual-delivery-plan-2026-11-09.md` e `sad-vis-01-bootstrap-2026-11-09.md`; em seguida automação QlikView, política de recuperação, Boundary 7 e documentação/scripts do Draft #226.

## Resultado e limites

- `VIS01_OWNER_APPROVAL=APPROVED`; `VIS01=STOP_CLOSED`.
- `VIS02=READY_FOR_WINDOWS_PREFLIGHT`; `VIS02_QVW_SAVE=NOT_EXECUTED`; `VIS02_GUI=NOT_TESTED`.
- `C2/C3/C4_GLOBAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.
- PR #230 e PR #226 permanecem Draft; a `main` conserva seu blueprint formal de 14 visuais e a ordem de gates, até decisão de integração separada.
- A proposta aprovada utiliza fundo #F4F7F8, cabeçalho #0A323F, títulos #103D4B, teal #087F87 e #16A6A4, fonte Segoe UI (fallback Arial). Cards são **apenas molduras dos nove gráficos/tabelas existentes**, sem KPI novo.
- Ativos da VIS-01 mantidos em pacote local fora do Git: `VIS01_fundo_{1_producao,2_leitos,3_fluxos}_1920x1080.png`; `VIS01_mockup_folha_{1_producao,2_leitos,3_fluxos}.png`; `VIS01_estados_indisponibilidade.png`; `VIS01_design_system_qlikview12.md`. Os mockups contêm séries/posições ilustrativas, não dados para importar à QVW.

## Preservação obrigatória

- Origem Windows: `C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw`.
- SHA-256 **registrado anteriormente pelo operador**, não recalculado neste chat: `27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13`.
- PDF R2 editorial (98 páginas) permanece fallback; sem alteração do relatório até DOC-R3.

## VIS-02 — sequência de execução segura

1. **Somente no Windows do operador**: conferir hash da QVW original e criar diretório novo/vazio de evidências; se houver divergência, STOP/BLOCKED.
2. Copiar, nunca mover ou sobrescrever, a C4 para `SAD_MVP_C4_VIS02_WORK.qvw` no novo diretório; hash inicial da cópia deve igualar o original; capturar baseline de folhas/objetos.
3. Extrair os **fundos aprovados**, verificar arquivos/escala na janela real. Fallback se houver corte/distorção: cor sólida #F4F7F8 e cabeçalhos nativos.
4. Aplicar propriedades **de aparência somente** via GUI nativa QlikView Desktop 12 na cópia: títulos, fontes, cores, bordas, alinhamento, larguras e orientação de barras se possível **sem trocar objetos, dimensões ou expressões**. Não adicionar KPIs nem Top N.
5. Invariantes por objeto: M1-01 anual; M1-02 série 36 competências; M1-03 papel SERV; M2-01 snapshots não aditivos; M2-02 referência fixa **201912** e guarda; M2-03 ilha A1 e três estados (4467 ausentes, 3464 positivos, 97 zeros); M3-01 RES=SERV/RES≠SERV; M3-02 pares dirigidos RES→SERV; M3-03 POP anual **No Totals** e guarda de competência.
6. Salvar **somente** na QVW de trabalho; jamais Reload, Save na fonte, QVD STORE ou COM novo por inércia. Comparar hash da fonte pós-edição; documentar versão, operação, caminho de cópia, hashes, capturas e resultado. Se falhar, voltar ao original intacto, sem sobrescrever.
7. VIS-03 é gate separado para reabertura, screenshots legíveis e regressões do escopo; nenhum PASS da VIS-02 torna a QVW homologada.

**Executores existentes:** `tools/Build-SadMvpThreeSheetsTemp.ps1` da PR #226 cria objetos e executa `Reload()/Save()`, portanto **não deve ser usado para aplicar o design**. `tools/Inspect-SadMvpC4CustomMessageCom.ps1` já cumpriu inspeção read-only CH09; não repetir por hábito. Não existe runner de redesign homologado. Preferir edição GUI manual delimitada. Se um novo script executor se tornar indispensável, versionar em branch antes da execução conforme `AGENTS.md`.

**Estado de capacidade desta sessão:** somente GitHub/documentos/arquivos de proposta; **sem acesso ao Windows do responsável**. Nenhuma QVW/QVD foi aberta, editada, salva ou recarregada, e nenhuma ação COM/merge ocorreu. `VIS02_LOCAL_EXECUTION=INCONCLUSIVE_NOT_RUN_ENVIRONMENT`.

**STOP:** aguardar a execução do preflight na estação Windows ou ferramenta autorizada que possa operar na cópia; não inventar sucesso físico nem ampliar escopo.