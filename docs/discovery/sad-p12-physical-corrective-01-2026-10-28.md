# SAD — Gate físico corretivo P1.2 (série mensal), primeira tentativa

**ID:** SAD-P12-PHYSICAL-CORRECTIVE-01
**Data:** 28/10/2026
**Baseline:** main@9070806f26a1568948b0ce2b87c597beb7ec2d9e
**Modo:** script versionado em branch de PR Draft + operador humano em Windows PowerShell 5.1 / QlikView Desktop 12.
**Permissão concedida:** "autorizado" após anúncio de gate corretivo restrito ao gráfico P1.2. Não concede merge, alterações de fatos, QVDs ou QVWs canônicos.
**Agente cloud:** ChatGPT GPT-6 + GitHub; esforço não exposto, sem acesso físico ao Windows.
**Execução nativa:** operador Windows, sem presumir Work Local ou COM habilitado.
**Estado inicial:** PREPARED_IN_BRANCH / WINDOWS_NOT_EXECUTED / VISUAL_NOT_VERIFIED.

## Objetivo e causa candidata

Corrigir **somente** o gráfico CH02 de P1.2 para demonstrar 36 competências administrativas de 201701 a 201912 e comparar 36/36 contagens à prova arquivada E1/A0 R1. O gate original #172 terminou em HARD_STOP e NÃO foi aprovado. O subgate #173 constatou em PowerShell 5.1 nove testes sintéticos PASS e 25/25 arquivos atuais iguais ao manifesto, sem resolver a causa histórica do HARD_STOP.

**Fato de arquivo real:** export de estrutura da cópia anterior, enviado pelo operador, classificou PERIODO_COMPETENCIA como $ascii/$text (144 valores), PERIODO_ANO como $numeric/$integer (12 valores) e QTD_INTERNACAO como numérico. O gráfico CH02 criado em #172 tinha dimensão PERIODO_COMPETENCIA, mas a expressão utilizava busca numérica por intervalo PERIODO_COMPETENCIA={">=201701<=201912"}; QlikView mostrava "Não há dados para mostrar". **Hipótese não provada:** busca numérica sobre campo textual não encontra os 36 valores; não deduzir que existam erros de QVD, Key ou medida.

## Escopo operacional / invariantes

- **Reutilizar o QVW da tentativa anterior, sem alterá-lo** (já contém os quatro KPIs com 4/4 valores visualmente conferidos, mais CH02 sem dados). Usá-lo somente como insumo binário fixado por SHA-256: 603464EB5AD5696DA001D5431194EF37D509448695DBBBB9EA1B7252F96EC791, informado no -Verify original.
- O caminho da fonte não é adivinhado: lê-se a propriedade Copy do manifesto original, na pasta de evidências do gate #172:
  C:\Users\pedro\Documents\SAD_P11P12_POC_EVIDENCIAS\SAD_P11P12_0fdafff22e86404284f66180214c2e74\p11p12_manifest.json
- O novo executor tools/Invoke-SadP12CorrectiveCopy01.ps1 apenas cria **uma nova cópia** de QVW em runtime separado e manifesta a proveniência; -Verify do **novo** gate verifica SHA dos 25 arquivos canônicos, fonte e cópia. Não reutiliza nem reexecuta -Prepare/-Verify de #172.
- O executor tem dois modos mutuamente exclusivos, exige checkout clean da branch exata, commit SHA40, manifesto anterior válido, fonte QVW com SHA fixado, os 25 arquivos protegidos com 10+12 QVDs e três QVWs intactos versus baseline do manifesto, e outputs fora do repo. Falhas encerram a tentativa.
- Não criar/recarregar QVD, não executar COM, QVS, STORE, C2, P5, A0 R1, Fase IX, painel final, nem alterar mais de um objeto CH02 na folha descartável.
- Os quatro cartões P1.1 são evidência anterior e devem permanecer intactos; não reconstruí-los nem presumir aprovação completa do gate antigo.

## Oráculo e expressão candidata

**Medida semântica:** Sum(QTD_INTERNACAO), na FATO_INTERNACAO. Fato com 566.672 registros administrativos, dos quais 11.583 continuidades IDENT=5 contadas como zero em QTD_INTERNACAO. 555.089 novas internações administrativas de 2017–2019.

**Expression candidata única** (editor do gráfico CH02, dimensão PERIODO_COMPETENCIA mantida):

    =Sum({$<PERIODO_ANO={2017,2018,2019}>} QTD_INTERNACAO)

A expressão usa exclusivamente filtro numérico em PERIODO_ANO. Com dimensão PERIODO_COMPETENCIA, suprimir zeros/ausentes deve excluir competências fora da janela, caso só a fato de 2017–2019 tenha contribuição. **Não assumir sem observação real** que a expressão produz 36 pontos, nem que o elo via Link Key é globalmente aprovado.

**Classificação:** desmarcar Estado e manter Texto crescente A-Z. AAAAMM tem largura constante de seis dígitos, de modo que a ordem textual crescente coincide com a cronológica; não forçar eixo contínuo numérico. Confirmar com exportação do gráfico.

**Critérios E1/A0 R1 já arquivados, sem reexecutar validação:** 2017=183.532; 2018=183.311; 2019=188.246; triênio=555.089; 36 pontos em 201701..201912; máximo 201905=17.292, mínimo 201702=13.586. Um ponto mínimo/máximo ou screenshot não substitui confronto completo 36/36.

**Texto metodológico visível no objeto/folha:** "Internações novas por competência administrativa SIH/RD; IDENT=5 excluído. Não equivalem a pacientes únicos nem demanda reprimida."

## Procedimento de execução em uma rodada

1. Preflight Windows PowerShell 5.1: worktree limpo, checkout no commit exato da branch deste PR e parser PowerShell nativo do script versionado. Não executar se scripts não rastreados, status sujo, conflito com QVD/QVW ou origem ainda aberta no QlikView.
2. Uma única chamada -Prepare com parâmetros Root/ExpectedCommit/ParentManifestPath/RuntimeRoot/EvidenceRoot. O script compara 25/25 arquivos protegidos com o baseline anterior, verifica SHA do QVW anterior, copia somente ele para uma pasta runtime nova e registra p12_corrective_manifest.json na pasta EvidenceRoot nova. **Somente** o VERDICT=PASS_PREPARE_ONLY_UI_NOT_TESTED permite continuar.
3. Abrir exclusivamente RUNTIME_COPY retornado, com o nome **SAD_P12_CORRECTIVE_COPY.qvw**. Inspecionar as seleções reais: devem estar vazias. Se houver qualquer seleção, não limpar/reinventar estado sem decisão; STOP. Anotar os quatro KPIs existentes e mensagem inicial de CH02 "Não há dados para mostrar".
4. No CH02, editar somente a expressão acima, salvar propriedade; configurar ordenação Texto A-Z, sem Estado, mantendo **Ocultar Zeros** e **Ocultar Faltantes**. Não adicionar campo/objeto e não modificar outros gráficos.
5. Se CH02 continuar vazio, registrar tela e propriedades, salvar **somente a cópia** e STOP visual; não tentar outra fórmula nesta tentativa. Se renderizar, ampliar CH02 para inspecionar curva inteira, captura GUI e verificar contagem de meses com exportação. **Nenhuma interpolação, imputação, suavização ou preenchimento de zero.** Exportar 36 valores do gráfico para pasta de evidências e confrontar com oráculo já arquivado, sem recomputar A0.
6. Salvar somente nova cópia, fechar o QlikView e executar uma única chamada -Verify do **novo** script usando RunDir retornado. Nenhum -Verify do antigo PR #172.
7. Revisar: 25 canônicos e fonte do gate anterior inalterados, cópia alterada, 36 meses e 36/36 confronto, controles anuais, captura e legibilidade. Separar aprovação científica restrita da aprovação visual e da aprovação de produção.

### Evidência persistente

Manifests e exportação mensal fora do Git, no EvidenceRoot, mais stdout integral, capturas de estado de seleção, propriedades do CH02, curva e resultados numéricos. Enviar as provas ao chat para auditoria. Nunca commitar QVD, QVW, planilhas de resultados, nem hashes novos sem revisão do contrato de evidência.

## Vereditos e condição STOP

- PASS_PREPARE_ONLY_UI_NOT_TESTED: cópia nova, 25 entradas originais e source pinado preservados, sem execução QlikView.
- PASS_LOCAL_P12_CANDIDATE_ONLY: 36 pontos reais, export 36/36 contra oráculo arquivado, seleção neutra, propriedades e captura auditadas, e -Verify do gate novo aprovado. Não depende de o gate #172 ser reclassificado retroativamente.
- INCONCLUSIVE/BLOCKED: gráfico continua vazio; 36 pontos não exportados ou oráculo indisponível; interface não comprovada; mudança de seleção.
- HARD_STOP: hash de fonte ou de qualquer protegido divergente, inconsistência de modelo, saída fora do escopo, reload, modificação indevida de originais.
- **STOP após uma cópia, uma alteração de CH02 e um -Verify**. Não criar R2/R3/R4; tratar outro problema como gate independente se justificado.

**Status globais:** LINK_KEY_CONTRACT=NOT_APPROVED; MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED; C2_FULL=NO_GO_NOT_APPROVED; P5_D2_UI=NOT_TESTED_GLOBAL; T29_HISTORICAL=NOT_APPROVED; PHASE_IX=NOT_AUTHORIZED; PRODUCTION_APPROVED=False; sem merge automático.
