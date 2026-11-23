# Correção automatizada do rótulo temporal M1-01 — 23/11/2026

## Correção física e visual concluída — 23/11/2026

A execução Windows do responsável terminou de 16:36:45 a 16:44:28 (UTC-03), com o executável do commit `942e9f905023febdda8c50cb06a25966e525a166`, SHA-256 `503C16E234DA476AED1245CEC8460EBC7014C550120A2FA353293D76C0AC7A47`. O relatório final recebido `alteracao(1).json` tem SHA-256 `CA3740152406387D4DDDE5E40173CB27A5E02950F21475B210709DCF30F41822`. Identifica a propriedade `CH01.Dimensions.Item(0).Title.v`, de `Ano da Internação` para `Ano de competência`, com `save_called=true`, `reload_called=false`, `reopened_label_verified=true`, `checked_chart_properties_preserved=true`, `integrity_verified=true` e `cleanup_errors=[]`.

Foram reconciliadas independentemente as duas listas do JSON: **26 caminhos únicos antes e depois, com 26/26 hashes e tamanhos idênticos**. Nenhuma ausência ou divergência. A comparação de dimensões/expressões/condições/títulos/folhas é conclusão do executor registrada no JSON; os arquivos detalhados de propriedades não foram recebidos, portanto não se alega comparação independente dessas listagens no cloud.

A captura posterior `image(20261123-194546).png`, SHA-256 `63D716DA17ECCB1BC7757F630AE908B84563FADC7A6C24A62FCA47AE953D77FD`, mostra o caminho da cópia correspondente ao relatório e o eixo do gráfico anual com **Ano de competência**, legível e sem truncamento aparente. Essa é a prova visual recebida, distinta da leitura COM. O campo bruto `visual_review=PENDING_USER` não foi reescrito: esta revisão da captura é registrada separadamente. A primeira captura tinha o rótulo antigo e o primeiro `alteracao.json` estava em PREPARING; eram registros anteriores à conclusão, não evidência de falha final.

Cópia concluída: `C:\Users\pedro\SAD_FINAL_EVIDENCIAS\M1_ROTULO_20261123_163651_83e0481074\SAD_PB_ANO_COMPETENCIA_CONFERIR.qvw`. SHA-256 da cópia, **informado pelo relatório local**: `C78E6DD568ECE7360E985DE2D63D42D70F2EF47D73EA72A555DB3F622F2C0695`. Os bytes desse QVW não foram recebidos no cloud. Origem pinada e 25 demais artefatos protegidos preservados conforme reconciliação dos registros de hashes.

**STOP: correção de nomenclatura encerrada na cópia. Não repetir o pacote e não substituir o original automaticamente.** Sem novo teste numérico, mudança de medida/modelo/guarda, merge ou submissão. Fontes e três folhas como três painéis foram aceitas conforme confirmação do responsável; prazo mantido. Apresentação e ensaio online permanecem suspensos. Restam guarda/aprovação do pacote final, integração documental sob autorização e submissão/recibo. Os comandos e estados de preparação abaixo são históricos, superados por este encerramento.

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
