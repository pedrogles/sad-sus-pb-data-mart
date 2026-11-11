# SAD — VIS-02 | Execução controlada da identidade visual (09/11/2026)

**Natureza:** runbook de implantação visual acadêmica em QVW TEMP, com preflight de cópia isolada. **Não é execução Windows nem homologação.**
**Autorização:** responsável aprovou VIS-01 e pediu continuidade da VIS-02. Sem merge, sem alterações em QVW/QVD canônicos ou mudanças semânticas.

## 1. Fontes e escopo

- Fonte de verdade: main:AGENTS.md → main:docs/project/current-state.md → main:docs/academic/requirements.md.
- VIS-01 aprovado: PR #230 Draft, arquivo docs/project/sad-vis-01-approved-vis-02-handoff-2026-11-09.md; especificação externa VIS01_design_system_qlikview12.md.
- Objetos: M1-01..03, M2-01..03, M3-01..03 **existentes na QVW C4**; nenhuma dimensão, expressão, filtro, ilha A1, set analysis ou guarda alterada.
- A main conserva o blueprint formal 14 visuais; 3×3 é protótipo acadêmico Draft #226, não Fase IX.
- Original C4: C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw
- Hash original esperado, fornecido pelo operador: 27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13.

## 2. Por que existe um preflight mínimo

O executor existente tools/Build-SadMvpThreeSheetsTemp.ps1 executa Reload() e Save() e reconstrói objetos TEMP; **não deve** ser usado para remodelar o visual da C4 aprovada. O diagnóstico read-only CH09 também não cria cópia. A necessidade concreta é apenas preparar QVW e três fundos com SHA; para isso foi criado um auxiliar delimitado: tools/Prepare-SadVis02WorkCopy.ps1. Ele **não chama QlikView, COM, Reload, Save nem escreve QVD/QVS**.

## 3. Preflight no Windows PowerShell 5.1

Condições: máquina do operador, QVW de origem no caminho acima, pacote VIS01_design_system_pacote_aprovado.zip previamente baixado para Downloads, repositório Git local e pasta privada de evidências. **Não executar em outro SO/VM como prova do Windows.**

1. Conferir se não há mudanças locais importantes e mudar somente para a branch VIS-02; o comando git switch não deve apagar alterações.
2. Executar os comandos abaixo, linha a linha, no PowerShell iniciado na raiz do repositório. Alterar apenas o caminho do ZIP se ele estiver em outra pasta.

    git fetch origin
    git switch feature/sad-vis02-controlled-copy-2026-11-09
    git pull --ff-only origin feature/sad-vis02-controlled-copy-2026-11-09
    New-Item -ItemType Directory -Path 'C:\Users\pedro\SAD_VIS02_EVIDENCIAS' -Force
    $commit = (git rev-parse HEAD).Trim()
    & .\tools\Prepare-SadVis02WorkCopy.ps1 -SourceQvw 'C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw' -AssetsZip 'C:\Users\pedro\Downloads\VIS01_design_system_pacote_aprovado.zip' -EvidenceRoot 'C:\Users\pedro\SAD_VIS02_EVIDENCIAS' -ExpectedCommit $commit

3. Esperado somente se comprovado localmente: VERDICT=PASS_COPY_AND_ASSET_HASHES_ONLY, SOURCE_UNCHANGED=True, WORK_QVW e MANIFEST. Em qualquer BLOCKED, **não abrir, editar nem recarregar QVW**; conservar logs/pasta parcial.
4. O script imprime pasta privada única. Só a QVW de trabalho localizada em WORK_QVW poderá ser aberta para edição; não usar o original. O SHA do arquivo de trabalho começa igual ao original e mudará legitimamente apenas após Save na cópia.

**Limitação:** validação estática da fonte feita nesta sessão, sem PowerShell 5.1; parser e execução Windows ainda NOT_RUN. Não atribuir PASS com base no script versionado.

## 4. Aplicação visual por interface nativa

Com preflight PASS, abrir exclusivamente a cópia WORK_QVW no QlikView Desktop 12, e conferir visualmente as três folhas e os nove objetos. Se surgir prompt de recuperação inesperado, STOP.

- Folhas: Settings → Sheet Properties → General → Background → Image → Change; importar o PNG correspondente em WORK_DIR\assets. O suporte a imagem, preenchimento Keep Aspect/Fill e cor sólida é documentado. Evitar 'Fill' se houver distorção; usar Keep Aspect e verificar corte/área não preenchida. Se o fundo prejudicar o layout, usar cor #F4F7F8.
- A faixa de cabeçalho dos fundos tem cerca de 100 px; a antiga posição superior dos gráficos começa perto de 90 px. **Antes de salvar, reposicionar/redimensionar os objetos existentes** para evitar que o cabeçalho cubra títulos ou gráficos. Não criar objetos nem mudar medidas para obter o alinhamento.
- Configurar estilos em Chart Properties → Colors, Font, Layout, Caption, Presentation, conforme o tipo nativo. Segoe UI se disponível; fallback Arial. Títulos #103D4B, destaque #087F87, fundo claro. Não alterar propriedades Dimensions, Expressions, Calculation Condition, Alternate State, Show Conditional ou set analysis.
- Folha 1: M1-01 barras anuais, M1-03 ranking SERV, M1-02 série com as 36 competências. A orientação horizontal é opcional e só se a propriedade do objeto atual permitir sem trocar dimensões, ordenação ou universo.
- Folha 2: M2-01 duas séries de snapshots mensais, M2-02 leitos SUS municipais **fixos em 201912** com aviso contextual existente, M2-03 ilha A1 de observabilidade sem filtros globais (4.467 ausentes, 97 zeros observados, 3.464 positivos). Não confundir soma de snapshots com capacidade anual.
- Folha 3: M3-01 duas classes RES=SERV/RES≠SERV, M3-02 pares dirigidos RES→SERV, M3-03 POP por município×ano, com No Totals e aviso de seleção mensal intactos. Ampliar visualmente as duas tabelas; não alterar associação RES/SERV.
- Mensagens de indisponibilidade: preservar todas as expressões/condições e conteúdo existente, principalmente CH09; mockup âmbar é apenas referência gráfica, não autorização de editar a guarda.
- Registrar captura antes/depois de cada folha, descrição da propriedade alterada e, após revisão, Save **somente na cópia WORK_QVW**. Nunca executar Reload.

**Observação:** as capturas/posições de mockup 1600×900 e fundos 1920×1080 não provam responsividade na janela QlikView. Um fundo pode aparecer cortado, sem que isso seja erro do dado. Fallback institucional simples é preferível à sobreposição.

## 5. Saída, evidência e STOP

- Preflight: manifest com fonte/cópia/assets SHA; output PASS somente de bytes, não da interface.
- VIS-02 físico: fotos/capturas reais das 3 folhas, lista de propriedades visuais ajustadas, hash da origem **depois** do Save na cópia, hash da cópia, registro do QlikView Desktop; confirmar visualmente nove objetos e preservação da legenda/guardas.
- PASS_LOCAL_RESTRICTED exige prova Windows de QVW cópia editada e preservação da origem; sem evidência, INCONCLUSIVE. Qualquer quebra semântica/objeto perdido/aviso ausente: BLOCKED e rollback para a fonte preservada, sem sobrescrever.
- VIS-03, DOC-R3 e avaliação C2/C3/C4 são gates distintos. Nenhuma atualização em main nem merge é autorizada.

**Estado no momento do commit:** VIS01_OWNER_APPROVED; VIS02_PREFLIGHT_SCRIPT_VERSIONED_NOT_RUN_WINDOWS; VIS02_QVW_EDIT_NOT_EXECUTED; QVW_C4_ORIGINAL_NOT_TOUCHED_BY_THIS_SESSION; PR226/PR230 Draft; PRODUCTION_APPROVED=False.

Referência QlikView: https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Sheet_Properties_General.htm
Referência gráficos: https://help.qlik.com/en-US/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/Bar_Chart.htm