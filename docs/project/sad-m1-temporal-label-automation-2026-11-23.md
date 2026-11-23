# Correção automatizada do rótulo temporal M1-01 — 23/11/2026

## Escopo autorizado

O responsável solicitou automatizar a alteração pendente no QVW e receber um arquivo para abrir e conferir. A execução física deve ocorrer no Windows do responsável: o ambiente de preparação é Linux e não tem acesso ao QVW local ou ao QlikView instalado. Não se promete um QVW já editado no cloud.

Alteração única atribuída: `CH01` / `M1-01`, folha Produção Hospitalar, `Dimensions.Item(0).Title.v`: `Ano da Internação` → `Ano de competência`. O acesso a essa propriedade exige confirmação em tempo de execução: exatamente uma dimensão, rótulo anterior esperado, leitura posterior e persistência após salvar/reabrir. API/propriedade incompatível deve bloquear; a execução física ainda não ocorreu.

## Reuso e limites

O adaptador reutiliza os padrões dos executores canônicos `Build-SadMvpThreeSheetsTemp.ps1` e `Inspect-SadVis05ReadOnly.ps1` (PR #243): cópia com pin, enumeração de três folhas/nove gráficos, GetProperties/SetProperties, fechamento, hashes e bloqueios dos 26 arquivos. O executor de inspeção não pode ser invocado para esta alteração porque seu contrato proíbe SetProperties/Save. Por isso foi criado um adaptador de objetivo único, sem mecanismo novo de captura ou cenários numéricos.

Código da distribuição: commit `942e9f905023febdda8c50cb06a25966e525a166`, `tools/Set-SadM1CompetenceLabel.ps1` e `tools/ABRIR_CORRECAO.cmd`, publicados antes dos testes. O ZIP contém cópias desses arquivos e um manifesto de versão/hash. Não exige atualizar o checkout Windows para esta branch; a identidade do executável é conferida pelo manifesto distribuído.

Origem pinada: `SAD_VIS05_EVIDENCIAS/VIS05_20261112_171721_950990d1/SAD_MVP_VIS05_UX_WORK_TEMP.qvw`, SHA-256 `B56D0A8550AB7EEE68D45DB0249F273DED05C4ADEE88DBE3FC7A20B162084DBB`. O original não é aberto pelo QlikView. A cópia nova fica em `SAD_FINAL_EVIDENCIAS/M1_ROTULO_<data>_<id>/SAD_PB_ANO_COMPETENCIA_CONFERIR.qvw`. A cópia é a única autorizada a receber SetProperties e Save; nenhuma chamada Reload.

O script exige QlikView fechado, pin da origem e 10 QVDs de extração/12 de transformação/3 QVWs canônicos mais a origem. Abre bloqueios de leitura nos 26 arquivos e confere hashes/tamanhos antes/depois. Salva, fecha e reabre a cópia, lê o rótulo e compara as propriedades capturadas de dimensão, expressões, título de janela, condição e folha dos nove gráficos. Somente o rótulo autorizado é normalizado na comparação. Metadados não legíveis ou acima dos limites bloqueiam a execução antes da alteração. Não é auditoria integral do formato binário ou de todas as propriedades visuais. Selecionar a folha inicial é apenas navegação de interface.

## Evidência disponível

Teste executado em Linux com PowerShell 7.4.6, código versionado: `-SelfTest -ArtifactRoot /tmp/sad-mock -SourceQvw /tmp/sad-mock/source.qvw`. Resultado `SELF_TEST=PASS_MOCK_ONLY_NO_WINDOWS_OR_QLIKVIEW_EXECUTION`: escrita única esperada; definição da dimensão preservada; rótulo inesperado e dimensão adicional bloqueiam sem escrita. Os argumentos explícitos evitam usar USERPROFILE, ausente no Linux. Isso não certifica COM, PowerShell 5.1 real, gravação do QVW, leitura de todos os metadados ou aparência na tela.

## Próximo passo e STOP

O usuário extrai o pacote e executa o CMD. Após sucesso, o QVW corrigido é aberto para inspeção. `alteracao.json` e uma captura da folha Produção Hospitalar devem ser recebidos para conferir persistência, propriedades e apresentação, mantendo esses níveis de evidência separados. Não repetir o executor após bloqueio sem examinar a mensagem. Não substituir o original, fazer merge, submeter, executar ensaio online ou alterar outros objetos. Apresentação e ensaio continuam fora do planejamento ativo; a abertura solicitada é apenas conferência focalizada desta correção.

Estado da execução física: **PENDENTE**. Aceite visual: **PENDENTE**. Main preservada. Fontes oficiais de suporte à escolha de automação COM: https://help.qlik.com/en-US/qlikview-developer/September2026/Content/QV_HelpSites/APIsAndSDKs.htm e documentação de automação referenciada no manual canônico. A existência da API não substitui o teste da propriedade no QVW pinado.
