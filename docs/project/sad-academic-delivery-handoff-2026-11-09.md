# SAD — handoff da entrega acadêmica após o MVP C4 (09/11/2026)

**Natureza:** plano operacional de continuidade **proposto para novo chat**, com objetivo acadêmico limitado; não é homologação, alteração semântica ou autorização para merge/produção. **Autoridade:** `main:AGENTS.md` → `main:docs/project/current-state.md` → `main:docs/academic/requirements.md` → documentação do professor → evidências específicas versionadas na branch Draft `proposal/sad-mvp-rebaseline-2026-11-07` ([PR #226](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/226)). Respeitar sempre material oficial do professor. A `main` mantém o blueprint de 14 visuais e o snapshot operacional de 03/11; não converter o escopo experimental B1 de 9 visuais em baseline formal sem decisão própria.

## Contexto que NÃO precisa ser reconstruído

- **Primeira entrega:** Capítulos 1–2 entregues em 13/10/2026 segundo o operador; avaliação do professor ainda não confirmada. **Segunda avaliação:** data exata não verificada; confirmar com o professor.
- **B1 MVP autorizado para prototipação em branch:** 3 fatos, 8 dimensões, 3 folhas, 9 visuais e filtros nativos simples. Modelagem acadêmica e arquitetura QlikView 12 preservadas; ver `docs/project/mvp-scope-owner-approved-2026-11-07.md`.
- **Artefato de demonstração a preservar, não reconstruir:** `C:\Users\pedro\SAD_M1_EVIDENCIAS\SAD_M2_MVP_TEMP_4aee47d0ab074ab5b3a004eb0845efa3\SAD_MVP_C4_PRESENTATION_TEMP.qvw`; SHA-256 **reportado pelo operador após persistência** `27ADABC3CB5DBC3598F2FDB3CD6FDC82E7193B18E92D253D1186B94075BB5A13`. Não editar, recarregar nem sobrescrever; para apresentação, usar cópia controlada se necessário.
- **C4 CH06/CH09:** screenshot e persistência após Save/reopen **PASS restrito**, descritos em `docs/project/mvp-evidence-and-contract-gates-consolidation-2026-11-07.md`. O diagnóstico COM apenas leitura terminou; personalização da mensagem de CH09 permanece **manual e somente na QVW C4 existente**. Não repetir introspecções/builds por inércia.
- **C2 guiado separado:** `#229` gate TX18 negativo encerrado restritamente; não faz parte dos nove visuais do B1, não autoriza C2 global. PRs #226/#229 continuam Draft sem merge.
- **Relatório já gerado na conversa, fora do Git e não confirmado baixado pelo operador:** `Relatorio_SAD.docx`, `Relatorio_SAD.pdf` e `SAD_Arquivos.zip`, com rascunho de Capítulos 3–5 e inventário de anexos; também gerador `Gerar_Anexos_SAD.py`. **Não presumir que os anexos integrais foram gerados**; não presumir que esses arquivos atravessam chats ou foram salvos em Downloads. Solicitar upload do arquivo **somente se a edição depender dos bytes e não houver acesso por Files**.
- **Fonte do código para anexos:** verificar GitHub `main` antes de exportar. `DIM_TEMPO` está em `TRANSFORMACAO/transf_main.qvs` (extrair apenas segmento pertinente ou anexar script integral explicitando os includes); outras 7 DIMs e 3 fatos estão em QVS próprios, com materialização por scripts adicionais. Confirmar cada caminho e revisão; não inventar inclusão automática ou afirmar que código incompleto é Anexo I/II completo. O gerador não foi validado na máquina Windows.
- **Referências:** `docs/academic/requirements.md`, `docs/academic/chapter-1-2-modeling.md`, material `DescricaoProjetoSAD.pdf` do professor e originais DATASUS/CNES/IBGE. Referências bibliográficas do rascunho precisam revisão final conforme fonte efetivamente citada.
- **Lacuna de imagem:** falta **captura da folha 1 Produção Hospitalar da própria QVW C4**. A imagem da PoC SIH inserida no rascunho é apenas ilustração identificada, nunca evidência da folha 1 do B1.

## Sequência de execução — um gate por vez

| Ordem | Objetivo estrito | Entrada reutilizada | Entrega/critério de aceitação | STOP / limite |
|---|---|---|---|---|
| **A1** | Recuperar e revisar o relatório acadêmico Cap. 3–5 | Word/PDF já gerados no chat anterior; requisitos do professor; docs do repo | Arquivo editável **efetivamente acessível ao operador**, comentários/análises com limites corretos, referências verificadas | Se falhar download, resolver canal de entrega; não recriar conteúdo cegamente |
| **A2** | Fechar Anexos I e II com código integral | QVS rastreáveis da `main`, commits e gerador candidato | Anexos integrais de 8 dimensões + 3 fatos e complementos indispensáveis, com proveniência de versão, sem dados binários | Gerador deve ter validação real; nenhum QVD/QVW alterado; não confundir segmentação de `transf_main.qvs` com 8 DIMs separadas |
| **A3** | Capturar somente folha 1 na **QVW C4** e substituir figura provisória | Cópia TEMP com SHA pinado e documentado | Um print com legenda e nome da QVW correto, 3 folhas representadas coerentemente no relatório | Read-only da cópia se possível; não executar novos testes C2/C3/C4, Save, Reload ou rebuild |
| **A4** | Consolidar relatório acadêmico e ensaio de demonstração | A1–A3 + Capítulos 1–2 já entregues | Documento único revisado com legendas/referências/anexos, roteiro de ~5 min e pacote abrível no Windows; data da avaliação confirmada externamente | Não chamar protótipo de homologado; não alegar dados não auditados; não usar medidas temporais incompatíveis |
| **D1 futuro, SEPARADO** | Reconciliar escopo e gates formais | #226, #229, `main` e Boundary 7 | Proposta de decisão sobre delta 14→9, matriz C2 nativo B1, C3 associação e C4 medidas antes de IX | **Não fazer merge/alterar main sem autorização**, nem assumir GO IX ou produção |

**Prioridade padrão:** A1 → A2 → A3 → A4. A3 pode ser adiantado se o operador estiver com QlikView aberto, **sem transformar a captura em reteste**. D1 não deve bloquear a redação acadêmica; a documentação deve declarar pendências honestamente.

## Primeiro passo no novo chat

Ler os três arquivos obrigatórios da `main`, depois este handoff na branch #226 e `docs/project/mvp-evidence-and-contract-gates-consolidation-2026-11-07.md`. **Começar apenas por A1: confirmar que o operador consegue acessar o Word do relatório e revisar o conteúdo existente contra os requisitos**, sem abrir ainda C2, novos códigos COM, reconstrução de QVW ou discussão de merge. Caso os documentos gerados no chat anterior não estejam acessíveis automaticamente, recuperar com Files/Library ou solicitar upload, sem inventar caminho sandbox.

**Fronteiras finais:** `ACADEMIC_DELIVERY=IN_PROGRESS`; `MVP_GUI_C4=PASS_RESTRICTED`; `C2_C3_C4_GLOBAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`; `PR226=OPEN_DRAFT_NOT_MERGED`. Nenhum novo gate acadêmico deve alterar a modelagem aprovada, `main` ou os artefatos originais.
