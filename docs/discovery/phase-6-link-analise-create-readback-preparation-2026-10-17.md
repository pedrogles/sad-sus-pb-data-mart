# Fase VI — Preparação CREATE + READBACK da LINK_ANALISE (sem execução)

**Data:** 17/10/2026. **Base:** main@573405e3e66079a092607a4d24d3789f46da11f4 (#99).  
**Gate:** VI-LINK-PREP. **Estado:** CÓDIGO CANDIDATO VERSIONADO, REVISÃO ESTÁTICA; não executado no Windows/QlikView.  
**Autorização recebida:** preparar próximo gate após integração documental VI-P5, preservando QVDs originais. **Não autoriza** criar QVD, executar COM, recarregar TRANSF.qvw ou merge do PR.

## Objetivo único e fontes

Preparar scripts versionáveis para **um único** futuro CREATE de TRANSFORMACAO/QVD/LINK_ANALISE.qvd, com verificação anterior e READBACK independente, sem alterar o contrato aprovado nem copiar o preflight VI-P1. Preservar a sequência Fase VI → VII → VIII → IX.

Fontes na main consultadas na ordem: AGENTS.md; docs/project/current-state.md; docs/academic/requirements.md; docs/discovery/boundary-7-implementation-plan.md; docs/discovery/boundary-6-qlikview-physical-architecture.md; docs/discovery/phase-6-vi-p5-sad-link-v1-physical-contract-2026-10-17.md; docs/discovery/phase-6-vi-p1-p4-script-versioning-2026-10-16.md; docs/project/qlikview-powershell-automation.md; scripts V5 e VI-P1.

## Arquivos e responsabilidade

- TRANSFORMACAO/vi_p1_readonly.qvs: **sem modificação**. Reconstrói e confronta coordenadas e %LINK_KEY de SIH/RD, LT e POP; monta P1_LINK_SIMULADA (85.705 combinações candidatas). O marcador de QVD não criado é verdadeiro *no encerramento do preflight*, antes do tail.
- TRANSFORMACAO/vi_link_analise_create_tail.qvs: acrescentado ao P1 unicamente pelo executor. Confirma seis campos, chave única, três categorias de nulidade (77.550 RD, 7.486 LT, 669 POP), papéis, destino inexistente; um único STORE permitido, no QVD novo.
- TRANSFORMACAO/vi_link_analise_readback.qvs: segundo QVW descartável; reabre **o QVD físico já criado**, verifica seis campos exatos, 85.705 chaves únicas, classes de nulos e 100% de cobertura das 566.672 + 35.518 + 669 linhas factuais (POP projetada em memória). Nenhum STORE.
- tools/Invoke-SadViLinkAnalise.ps1: executor Git-versionado, preflight de headers/hashes dos 21 QVDs, verificação de QVS fonte SHA256 congelado, SHA256 dos quatro scripts, HEAD/limpeza, snapshots antes/depois, QVW e logs em TEMP, ausência de sobrescrita e leitura QlikView COM em dois documentos independentes.

**Atenção:** %LINK_KEY de população nesta Fase VI é calculada *somente para construir e conferir as coordenadas da Link Table*. A projeção factual da POP para associação no PAINEL continuará reservada à Fase VII; FATO_POPULACAO.qvd não é modificado.

## Modos previstos, ambos NÃO executados nesta entrega

### Inventário não mutante

Ao obter o branch versionado **no computador Windows** e após revisar o commit:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Invoke-SadViLinkAnalise.ps1 -Root .

Sem -ExecutePhysical o executor apenas valida scripts/cabeçalhos/hash, podendo gerar relatórios de evidência em %TEMP%. Não recarrega QVW nem escreve QVD. O presente PR **não** afirma PASS desse modo.

### CREATE físico (exemplo de formato, não ordem de execução)

**NÃO EXECUTAR sem aprovação separada e específica do gate físico**; a autorização do chat atual cobre apenas preparação e versionamento. Em eventual execução, confirmar branch/HEAD revisado e um único commit aprovado:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\Invoke-SadViLinkAnalise.ps1 -Root . -ExecutePhysical -ConfirmPhysicalWrite -AuthorizedCommit <SHA40_APROVADO>

O runner falha se falta confirmação/commit, scripts dirty, 21 originais não reconciliados, destino existente, QVS de criação diferente de STORE único autorizado, erro de Qlik, log não contemporâneo, readback divergente ou hashes originais alterados. Logs e QVWs temporários são mantidos. **Não** há exclusão, overwrite, rollback automático, repetição automática nem aprovação de produção. Se Qlik falhar durante STORE, preservar possível QVD parcial para auditoria e **parar**.

## Evidências mínimas para PASS físico futuro

- HEAD de execução e SHA-256 de runner + 3 QVS; SHA-256 da fonte VI-P1 igual ao publicado.
- Antes/depois: 10 QVDs extracao + 11 transformação originais, mesmos hashes, linhas e cabeçalhos.
- Alvo inicialmente inexistente; único STORE permitido no arquivo novo.
- Preflight P1 PASS com 85.705 tuplas; classe RD 77.550, LT 7.486 e POP 669, sem duplicidade de %LINK_KEY.
- CREATE PASS no log nativo e QVD com **exatamente seis campos**.
- READBACK em QVW distinto: 85.705 keys únicas, sem órfãs em cada fato, nulos de papéis corretos.
- Gate PASS restrito apenas se os marcadores de ambos os QVWs, headers, SHA256 e reconciliação concordarem. Falha/ausência de evidência = BLOCKED/INCONCLUSIVE e STOP.

Números são referências **reportadas** de VI-P1–P4 nos arquivos atualmente conhecidos; qualquer drift na execução deve bloquear, ser diagnosticado e encaminhado a escopo próprio. Verificação estática não demonstra a sintaxe/compatibilidade final de QlikView 12 nem ausência de loops no painel completo.

## Não objetivos e estado

Não recriar fatos/dimensões, não modificar EXT.qvw/TRANSF.qvw/PAINEL.qvw, não antecipar projeção POP no PAINEL, não testar indicadores, C/R/I/B, escopo hospitalar, zero quantitativo CNES, ocupação, legendas históricas T29 ou validação visual.

- VI_LINK_PREP=STATIC_ONLY_PENDING_REVIEW
- LINK_ANALISE_QVD=NOT_CREATED
- LINK_KEY_CONTRACT=NOT_APPROVED
- VI_PHYSICAL_GATE=NOT_AUTHORIZED_TO_EXECUTE
- FASE_VII_PANEL=NOT_STARTED
- MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED
- CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED
- PRODUCTION_APPROVED=False

**Stop:** encerrar esta preparação após scripts/documento versionados e PR Draft conferido. Não executar, não mesclar, não prolongar para PAINEL.
