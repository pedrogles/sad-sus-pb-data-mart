# C2-R2 — índice auditável de capturas (09/11/2026)

**Gate:** `SAD-C2-GUIDED-PREDISPATCH-REASON-01` • **PR:** #229 • **Origem:** nove capturas PNG fornecidas pelo operador em conversa, observadas pelo agente, copiadas byte a byte para uma galeria HTML autossuficiente e um pacote ZIP. **Os arquivos binários não estão armazenados neste repositório**: a interface de escrita GitHub conectada aceita texto UTF-8, não imagens. Não criar links Markdown que aparentem conter anexos GitHub não existentes.

## Conclusão visual restrita

- **Configuração:** BU16 existe com condição `Expression OK`, compara ano realmente selecionado com o proposto e tem uma ação `Selecionar no Campo(PERIODO_COMPETENCIA)`; capturas 01/02.
- **Coexistência:** BU15, TX17, CH02, CH03 aparecem nas capturas 03–06. TX18 novo está identificado e sua expressão indica `Expression OK` na captura 07.
- **Estado negativo na folha guiada:** captura 08 mostra `PERIODO_ANO=2019` na janela Seleções Atuais, `PERIODO_COMPETENCIA` sem seleção no próprio texto da folha, proposta `MENSAL/2018/01`, TX18 explicando a incompatibilidade e o BU16 visualmente desabilitado. Nenhuma captura demonstra clique/acionamento de BU16 e **não é possível concluir ausência absoluta de dispatch somente da imagem**.
- **Limite:** a captura 09 mostra CH03 em contexto de ano selecionado; ela **não** é `reason_after_reopen.png`. Não foi enviada comprovação de salvamento único, persistência do TX18 após reabertura, Verify do runner ou arquivo `gui_notes.txt` final.

**Veredito de imagem:** `NEGATIVE_GUI_OBSERVATION=PASS_RESTRICTED`, `SAVE=NOT_EVIDENCED`, `REOPEN=NOT_EVIDENCED`, `VERIFY=NOT_RUN`, `C2_GUIDED_R2=PARTIALLY_TESTED_NOT_APPROVED_GLOBAL`.

## Manifesto das capturas

Os SHA-256 foram calculados dos **bytes PNG recebidos**, não do QVW. `alias` é o nome utilizado no pacote de evidências entregue ao operador, **não um arquivo atualmente presente na branch**.

| # | Nome original | Alias no pacote | Evidência observada | SHA-256 PNG |
|---|---|---|---|---|
| 01 | `image(20261109-172729).png` | `bu16_enable.png` | BU16 — habilitação; Expression OK | `37F5AB9DE475CBC25EF8C7BE05C584FED66FCD5033298C99F704FAE584DD3572` |
| 02 | `image(20261109-172802).png` | `bu16_action.png` | BU16 — única ação, PERIODO_COMPETENCIA | `7ACE35DEAEBF539D56A6BE31DF96CE523A6AADC438A5DB99A0C2E5DB291B9D08` |
| 03 | `image(20261109-173326).png` | `bu15_properties.png` | BU15 — interface de ano 2019 | `F323B748BDC02152B18493ECAFA75EC10A7ED38D650CA946069F8EAB3D1113ED` |
| 04 | `image(20261109-173358).png` | `tx17_properties.png` | TX17 — texto anterior, identidade confirmada | `5BB3EE0B960B9BCE34A6A3B9F9FA33A4EFB665EBC309F854A6C5FA81C7798A2D` |
| 05 | `image(20261109-173413).png` | `ch02_properties.png` | CH02 — gráfico histórico | `A2C7B69199121F7BA40F7C9714EF8D5F300275E679405D649AA3C93D4E8A498B` |
| 06 | `image(20261109-173424).png` | `ch03_properties.png` | CH03 — gráfico guiado | `AB69B6D950C88ADE44816EED16387889F357C37882B15C172FCF831588A190F7` |
| 07 | `image(20261109-173740).png` | `reason_expression.png` | TX18 — nova expressão, Expression OK | `9033D234AC60F86C8632C1C22A74DCD3075A0F9E1AE1CAE234B9BAA5149941B2` |
| 08 | `image(20261109-173805).png` | `blocked_2018.png` | Ano real 2019 / proposta MENSAL 2018/01 / aviso / botão desabilitado | `2A6D60F0553E5467678448BDD4B0E76FCA65AC02DBED4A58153270965F34AF5C` |
| 09 | `image(20261109-173821).png` | `sh03_context.png` | Folha de evolução; não é screenshot de persistência | `5C6DFFE22B757DCD34F8099F66B7B8E3C46A956BBCBAF7CEAA4F5E1F182C2299` |

## Entrega dos anexos

O agente produziu uma página HTML autossuficiente com os nove PNGs embutidos e um ZIP com:
- `pagina_evidencias.html` (galeria autossuficiente);
- `README.md`, `manifest.json` (legendas, proveniência e hashes);
- nove PNGs íntegros com os aliases acima;
- `gui_notes_TEMPLATE.txt` (template **incompleto**, não substituir notas do operador sem conferência).

Esses artefatos foram entregues **nesta conversa**, e não anexados ao GitHub nem à máquina Windows do operador. URLs transitórias do chat não são URLs públicas ou persistentes da branch. A verificação do executor **ainda exige** `reason_after_reopen.png` e `gui_notes.txt` final no diretório EVIDENCE_DIR local.

## Proteções e STOP

A QVW atual é `SAD_C2_GUIDED_REASON_TEMP.qvw` gerada pelo runner do PR #229 a partir do SHA pinado do PR #225. Não houve neste registro Save/Reload/COM, alteração de QVW/QVD, merge, modificação da main ou liberação de Fase IX. **A próxima observação relevante é somente a persistência após único Save e reabertura da TX18**, mantendo o gate restrito e sem repetir F1/F2, 0→1→0 e os testes anteriores.
