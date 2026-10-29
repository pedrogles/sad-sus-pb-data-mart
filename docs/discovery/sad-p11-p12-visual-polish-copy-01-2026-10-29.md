# SAD — Gate físico de refinamento visual P1.1/P1.2 em cópia descartável

**Gate:** `SAD-P11-P12-VISUAL-POLISH-COPY-01`  
**Data:** 29/10/2026  
**Baseline:** `main@9070806f26a1568948b0ce2b87c597beb7ec2d9e`  
**Execução:** operador em Windows PowerShell 5.1 + QlikView Desktop 12, roteiro manual e executor versionado em branch própria Draft.  
**Agente:** ChatGPT GPT-6 + GitHub cloud, esforço não exposto, sem acesso ao Windows/QVW binário.  
**Autorização explícita:** responsável respondeu 'autorizado, prossiga' ao plano de **intervenção exclusivamente de apresentação** na cópia QVW já corrigida, mantendo 36/36 e sem mexer em cálculos. A fonte é preservada; cria-se cópia adicional. Não permite merge nem alteração de originais.

## Objetivo e fonte de verdade

**Objetivo único:** melhorar legibilidade de quatro cartões P1.1 e série CH02 P1.2, com nota metodológica persistente, sem mudança semântica ou recarga. Antes do escopo: ler AGENTS.md → current-state.md → requirements.md na main; contrato UX integrado em `docs/discovery/sad-p1-p11-p12-ux-contract-2026-10-28.md`, revisão visual no [PR #176](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/176), histórico da correção [PR #174](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/174) e auditoria [PR #175](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/175). PRs Draft não fazem parte da main.

**Fonte física aprovada restritamente pelo #175:** cópia QVW do gate #174, guardada em `C:\Users\pedro\Documents\SAD_P12_CORRECTIVE_RUNTIME\SAD_P12_CORRECTIVE_96a3d4d13e8644d38cf686516c0c1247\SAD_P12_CORRECTIVE_COPY.qvw`, SHA-256 **pino** `8E2096D42602D7B84239AE30498EE45FA3ED6B060B9EEC6A4C003B0B3A2B7DE4`. O caminho efetivo deve ser **lido do manifesto**, nunca presumido por aproximação. Manifesto pai já existente em `C:\Users\pedro\Documents\SAD_P12_CORRECTIVE_EVIDENCIAS\SAD_P12_CORRECTIVE_96a3d4d13e8644d38cf686516c0c1247\p12_corrective_manifest.json`, gerado no gate #174 commit `d2bd31f0959db76156bc4dcaa50d525df2371db4`, runner SHA-256 `5C3F6263A82BDC05AC79DDF432C4ABAC1DC80BDBB04F275DFD2BD883EA7B1C86`.

## Invariantes e fronteiras

- Não editar ou recarregar fonte QVW, 22 QVDs e três QVWs canônicos; não executar QlikView COM, STORE, scripts QVS, A0 R1, C2/P5, Phase IX, nem gerar novo dado.
- Não alterar as expressões dos quatro KPIs e de CH02; a expressão CH02 deve permanecer exatamente como testada: `=Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)`. Manter dimensão `PERIODO_COMPETENCIA`, 36 pontos, classificação AAAAMM crescente, ocultar faltantes/zeros sem inventar zeros.
- Não criar cópia no repositório nem salvar os arquivos fonte. Usar apenas nova cópia com nome `SAD_P11P12_VISUAL_POLISH_COPY.qvw`, criada por `tools/Invoke-SadP11P12VisualPolishCopy01.ps1` com `-Prepare` e `-Verify`, 1 vez cada; o runner só escreve arquivos na pasta runtime/evidência da rodada, ambas fora do Git.
- Preservar histórico de 36 meses como **folha experimental independente**, sem alterar os modos C2: MENSAL=1 competência, ANUAL=1 ano, EVOLUCAO=12 competências do ano.
- `LINK_KEY_CONTRACT=NOT_APPROVED`, `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`, `C2_FULL=NO_GO_NOT_APPROVED`, `P5_D2_UI=NOT_TESTED_GLOBAL`, `PHASE_IX=NOT_AUTHORIZED`, `PRODUCTION_APPROVED=False`.

## Preparação física — uma rodada

1. Preflight: worktree limpo, checkout branch/commit exatos do PR Draft (SHA completo emitido na abertura do PR), sem arquivos locais colidentes. Parser nativo PowerShell 5.1 do script versionado = 0 erros. Sem parse PASS, STOP.
2. Criar apenas as raízes de saída `C:\Users\pedro\Documents\SAD_P11P12_VISUAL_POLISH_RUNTIME` e `C:\Users\pedro\Documents\SAD_P11P12_VISUAL_POLISH_EVIDENCIAS`. Exigir QlikView fechado.
3. Uma chamada `-Prepare` com Root (caminho obtido do Git), ExpectedCommit, ParentManifestPath, RuntimeRoot e EvidenceRoot. O script exige manifesto #174, SHA da fonte, inventário 10 QVD extração + 12 transformação + 3 QVWs, e compara SHA/tamanho de cada um em Windows com identidade de caminho **case-insensitive**, sem relaxar hash. Cria nova pasta runtime e evidência, copia o QVW fonte e registra manifesto na evidência.
4. Somente `VERDICT=PASS_PREPARE_COPY_ONLY_UI_NOT_TESTED`, `RUNTIME_COPY` e `EVIDENCE_DIR` permitem prosseguir. Enviar stdout antes de abrir o QlikView. Não repetir Prepare se foi criado.

## Intervenção visual manual — somente a cópia nova

Registrar captura inicial na folha `POC P1.1-P1.2 - Internações` com janela Seleções Atuais **vazia** e quatro KPIs `183.532 / 183.311 / 188.246 / 555.089`; CH02 já exibindo a curva `201701..201912`. Não limpar seleção automaticamente caso não esteja vazia: STOP.

Sequência **limitada às propriedades de apresentação**:

1. **Títulos e tamanhos dos cartões:** padronizar como `Internações novas — 2017`, `Internações novas — 2018`, `Internações novas — 2019`, `Total do triênio — 2017 a 2019`, valores pt-BR, fonte maior e mais espaço para o aviso/metadados. Não alterar nenhuma expressão nem objeto alheio à folha.
2. **CH02 — valor isolado 555089:** inspecionar antes a origem do número em propriedades de título/legenda/expressão/apresentação. Se for texto/rótulo decorativo ou total redundante, removê-lo apenas da exibição; se não identificar origem, registrar captura e **não remover**.
3. **CH02 — eixo temporal:** manter 36 dimensões AAAAMM. Diminuir **somente a densidade visual dos rótulos** para leitura trimestral ou semestral quando existir configuração nativa que preserve 36 valores; não substituir `PERIODO_COMPETENCIA` por expressão de trimestre, não fazer agregação, não usar eixo contínuo sem prova, não ocultar pontos. Se a ferramenta não oferecer configuração segura, deixar rótulos originais e registrar `AXIS_LABEL_DENSITY=NOT_RESOLVED`.
4. **Unidades:** X=`Mês de competência (SIH/RD)`, Y=`Internações novas (quantidade)`, preservando a dimensão real e valores numéricos.
5. **Aviso metodológico persistente:** incluir texto legível na folha, não tooltip: `Internações novas contabilizadas por competência administrativa SIH/RD; continuidades (IDENT=5) excluídas. Não representam pacientes únicos nem demanda reprimida.`
6. **Tooltip:** quando possível mostrar um mês/AAAAMM e seu valor exato, sem interpretar popup habilitado como popup testado. Não alterar seleções ou navegar para modos C2.

Após aplicar alterações na cópia, registrar captura de janela Seleções Atuais vazia e layout; exportar de CH02 novamente o conjunto de 36 pares competências/valores. Confrontar com a exportação já reconciliada SHA `800B73A234C607604A69CD0EF4CBC7C4BB7D744D020CC159EA38C0DC0FC2899F` **por conteúdo**, não por aparência. Controles: 2017=183.532; 2018=183.311; 2019=188.246; triênio=555.089; máximo 201905=17.292; mínimo 201702=13.586. Não repetir oráculo E1/A0 R1 original.

Salvar **somente** a cópia nova, fechar QlikView e executar **uma** chamada `-Verify` deste novo runner com RunDir devolvido; exigir 25/25 protegidos, fonte intacta e SHA da cópia diferente do SHA inicial. `-Verify` não prova estética nem 36/36 — capturas e exportação pós-ajuste são provas separadas. Guardar tudo fora do Git.

## PASS, BLOCKED, STOP

- `PASS_PREPARE_COPY_ONLY_UI_NOT_TESTED`: somente cópia guardada por hashes, sem autorizar ainda declaração de sucesso visual.
- `PASS_VISUAL_CANDIDATE_RESTRICTED`: exige capturas da folha (incluindo seleções), texto visível, títulos/eixos legíveis e valores 4/4 preservados; ressalvas marcadas para qualquer item não demonstrado.
- `PASS_36_OF_36_UNCHANGED`: somente após comparação linha a linha da **nova exportação** com a anterior; não atribuir pelo gráfico desenhado.
- `PASS_HASH_INTEGRITY_ONLY_VISUAL_REQUIRES_REVIEW`: somente após Verify do runner para nova cópia, 25 originais e fonte preservados.
- `HARD_STOP`: divergência de fonte/protegido, erro de parser, QVW diferente, campos/valores alterados, mês faltante, alteração fora da cópia ou tentativa de reload; encerrar sem segunda tentativa.
- `INCONCLUSIVE`: configuração nativa de eixo ou origem da etiqueta não comprovada; registrar e deixar objeto inalterado, sem forçar solução.
- `STOP`: uma preparação, uma rodada manual de apresentação e um Verify; documento e binários em evidência local, nenhuma integração automática. Gate de UX global e `PRODUCTION_APPROVED` permanecem pendentes.
